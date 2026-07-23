import 'build_canonical_phrase_vocabulary.dart';
import 'contracts/canonical_business_text_classifier.dart';
import 'contracts/canonical_phrase_applicability_resolver.dart';
import '../domain/entities/canonical_approved_equivalent_evidence.dart';
import '../domain/entities/canonical_confirmed_application_evidence.dart';
import '../domain/entities/canonical_business_text_candidate.dart';
import '../domain/entities/canonical_business_text_candidate_index.dart';
import '../domain/entities/canonical_business_text_classification.dart';
import '../domain/entities/canonical_business_text_classification_index.dart';
import '../domain/entities/canonical_business_text_classification_status.dart';
import '../domain/entities/canonical_dictionary.dart';
import '../domain/entities/canonical_phrase_entry.dart';
import '../domain/entities/canonical_phrase_vocabulary.dart';

final class DeterministicCanonicalBusinessTextClassifier
    implements CanonicalBusinessTextClassifier {
  const DeterministicCanonicalBusinessTextClassifier({
    this.applicabilityResolver =
        const _UnresolvedCanonicalPhraseApplicabilityResolver(),
  });

  final CanonicalPhraseApplicabilityResolver applicabilityResolver;

  @override
  CanonicalBusinessTextClassificationIndex classify({
    required CanonicalBusinessTextCandidateIndex candidates,
    required CanonicalDictionary dictionary,
  }) {
    final CanonicalPhraseVocabulary vocabulary =
        const BuildCanonicalPhraseVocabulary().call(dictionary);

    final Map<String, List<CanonicalPhraseEntry>>
    entriesByTechnicallyNormalizedText = <String, List<CanonicalPhraseEntry>>{};

    final Map<String, CanonicalPhraseEntry> entriesByIdentity =
        <String, CanonicalPhraseEntry>{};

    for (final CanonicalPhraseEntry entry in vocabulary.entries) {
      entriesByTechnicallyNormalizedText
          .putIfAbsent(
            _technicallyNormalize(entry.phrase),
            () => <CanonicalPhraseEntry>[],
          )
          .add(entry);

      entriesByIdentity[entry.identity] = entry;
    }

    final Map<String, List<CanonicalApprovedEquivalentEvidence>>
    approvedEquivalentEvidenceByText =
        <String, List<CanonicalApprovedEquivalentEvidence>>{};

    for (final CanonicalApprovedEquivalentEvidence evidence
        in dictionary.approvedEquivalentEvidence) {
      approvedEquivalentEvidenceByText
          .putIfAbsent(
            _technicallyNormalize(evidence.equivalentText),
            () => <CanonicalApprovedEquivalentEvidence>[],
          )
          .add(evidence);
    }

    final List<CanonicalBusinessTextClassification> classifications =
        <CanonicalBusinessTextClassification>[
          for (final CanonicalBusinessTextCandidate candidate
              in candidates.candidates)
            _classifyCandidate(
              candidate: candidate,
              exactTextMatches:
                  entriesByTechnicallyNormalizedText[_technicallyNormalize(
                    candidate.text,
                  )] ??
                  const <CanonicalPhraseEntry>[],
              approvedEquivalentMatches:
                  approvedEquivalentEvidenceByText[_technicallyNormalize(
                    candidate.text,
                  )] ??
                  const <CanonicalApprovedEquivalentEvidence>[],
              entriesByIdentity: entriesByIdentity,
              registrySourceRevision: candidates.sourceRevision,
            ),
        ];

    return CanonicalBusinessTextClassificationIndex(
      projectId: candidates.projectId,
      candidateSourceDocumentPath: candidates.sourceDocumentPath,
      candidateSourceRevision: candidates.sourceRevision,
      candidateSourceSnapshotFingerprint: candidates.sourceSnapshotFingerprint,
      dictionaryId: dictionary.dictionaryId,
      dictionaryVersion: dictionary.version,
      dictionarySourceRevision: dictionary.sourceRevision,
      dictionarySourceSnapshotFingerprint: dictionary.sourceSnapshotFingerprint,
      classifications: classifications,
    );
  }

  CanonicalBusinessTextClassification _classifyCandidate({
    required CanonicalBusinessTextCandidate candidate,
    required List<CanonicalPhraseEntry> exactTextMatches,
    required List<CanonicalApprovedEquivalentEvidence>
    approvedEquivalentMatches,
    required Map<String, CanonicalPhraseEntry> entriesByIdentity,
    required String registrySourceRevision,
  }) {
    if (exactTextMatches.isNotEmpty) {
      final List<CanonicalPhraseEntry> applicable = <CanonicalPhraseEntry>[];
      final List<CanonicalPhraseEntry> unresolved = <CanonicalPhraseEntry>[];
      final Map<String, CanonicalConfirmedApplicationEvidence> evidenceByEntry =
          <String, CanonicalConfirmedApplicationEvidence>{};

      for (final CanonicalPhraseEntry entry in exactTextMatches) {
        if (entry.applicability.isEmpty) {
          applicable.add(entry);
          continue;
        }

        final CanonicalPhraseApplicabilityResolution resolution =
            applicabilityResolver.resolve(
              candidate: candidate,
              entry: entry,
              registrySourceRevision: registrySourceRevision,
            );

        switch (resolution.decision) {
          case CanonicalPhraseApplicabilityDecision.applicable:
            applicable.add(entry);
            evidenceByEntry[entry.identity] = resolution.evidence!;
          case CanonicalPhraseApplicabilityDecision.notApplicable:
            break;
          case CanonicalPhraseApplicabilityDecision.unresolved:
            unresolved.add(entry);
        }
      }

      final List<CanonicalPhraseEntry> review = <CanonicalPhraseEntry>[
        ...applicable,
        ...unresolved,
      ];

      if (review.length > 1) {
        return CanonicalBusinessTextClassification(
          candidate: candidate,
          status: CanonicalBusinessTextClassificationStatus.review,
          reason: CanonicalBusinessTextClassificationReason
              .ambiguousExactCanonicalTextMatch,
          matchedCanonicalEntries: review,
        );
      }

      if (applicable.length == 1 && unresolved.isEmpty) {
        final CanonicalPhraseEntry entry = applicable.single;
        if (entry.applicability.isEmpty) {
          return CanonicalBusinessTextClassification(
            candidate: candidate,
            status: CanonicalBusinessTextClassificationStatus.exact,
            reason: CanonicalBusinessTextClassificationReason
                .singleExactUniversalMatch,
            matchedCanonicalEntries: <CanonicalPhraseEntry>[entry],
          );
        }
        return CanonicalBusinessTextClassification(
          candidate: candidate,
          status: CanonicalBusinessTextClassificationStatus.exact,
          reason: CanonicalBusinessTextClassificationReason
              .singleExactApplicableMatch,
          matchedCanonicalEntries: <CanonicalPhraseEntry>[entry],
          matchedConfirmedApplicationEvidence:
              <CanonicalConfirmedApplicationEvidence>[
                evidenceByEntry[entry.identity]!,
              ],
        );
      }

      if (applicable.isEmpty && unresolved.length == 1) {
        return CanonicalBusinessTextClassification(
          candidate: candidate,
          status: CanonicalBusinessTextClassificationStatus.review,
          reason: CanonicalBusinessTextClassificationReason
              .exactTextRequiresApplicabilityReview,
          matchedCanonicalEntries: unresolved,
        );
      }
    }

    final List<CanonicalApprovedEquivalentEvidence>
    applicableApprovedEquivalentMatches = approvedEquivalentMatches
        .where(
          (CanonicalApprovedEquivalentEvidence evidence) =>
              _isApplicable(evidence, candidate),
        )
        .toList(growable: false);

    if (applicableApprovedEquivalentMatches.length == 1) {
      final CanonicalApprovedEquivalentEvidence approvedEquivalent =
          applicableApprovedEquivalentMatches.single;

      final CanonicalPhraseEntry? canonicalEntry =
          entriesByIdentity[approvedEquivalent.canonicalEntryIdentity];

      if (canonicalEntry == null) {
        throw StateError(
          'Approved-equivalent evidence references a canonical phrase '
          'outside the typed vocabulary.',
        );
      }

      return CanonicalBusinessTextClassification(
        candidate: candidate,
        status: CanonicalBusinessTextClassificationStatus.equivalent,
        reason: CanonicalBusinessTextClassificationReason
            .singleApprovedEquivalentMatch,
        matchedCanonicalEntries: <CanonicalPhraseEntry>[canonicalEntry],
        matchedApprovedEquivalentEvidence:
            <CanonicalApprovedEquivalentEvidence>[approvedEquivalent],
      );
    }

    return CanonicalBusinessTextClassification(
      candidate: candidate,
      status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
      reason:
          CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
    );
  }

  bool _isApplicable(
    CanonicalApprovedEquivalentEvidence evidence,
    CanonicalBusinessTextCandidate candidate,
  ) {
    if (evidence.applicability.isEmpty) {
      return true;
    }

    const String registryPathPrefix = 'RegistryPath: ';

    final String candidatePath = _normalizeRegistryPath(
      candidate.path.segments.join(' -> '),
    );

    return evidence.applicability.every((String applicability) {
      final String normalizedApplicability = _technicallyNormalize(
        applicability,
      );

      if (!normalizedApplicability.startsWith(registryPathPrefix)) {
        return false;
      }

      final String approvedPath = _normalizeRegistryPath(
        normalizedApplicability.substring(registryPathPrefix.length),
      );

      return approvedPath == candidatePath;
    });
  }

  String _normalizeRegistryPath(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s*->\s*'), ' -> ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _technicallyNormalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

final class _UnresolvedCanonicalPhraseApplicabilityResolver
    implements CanonicalPhraseApplicabilityResolver {
  const _UnresolvedCanonicalPhraseApplicabilityResolver();

  @override
  CanonicalPhraseApplicabilityResolution resolve({
    required CanonicalBusinessTextCandidate candidate,
    required CanonicalPhraseEntry entry,
    required String registrySourceRevision,
  }) {
    return const CanonicalPhraseApplicabilityResolution.unresolved();
  }
}
