import 'build_canonical_phrase_vocabulary.dart';
import 'contracts/canonical_business_text_classifier.dart';
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
  const DeterministicCanonicalBusinessTextClassifier();

  @override
  CanonicalBusinessTextClassificationIndex classify({
    required CanonicalBusinessTextCandidateIndex candidates,
    required CanonicalDictionary dictionary,
  }) {
    final CanonicalPhraseVocabulary vocabulary =
        const BuildCanonicalPhraseVocabulary().call(dictionary);

    final Map<String, List<CanonicalPhraseEntry>>
    entriesByTechnicallyNormalizedText = <String, List<CanonicalPhraseEntry>>{};

    for (final CanonicalPhraseEntry entry in vocabulary.entries) {
      entriesByTechnicallyNormalizedText
          .putIfAbsent(
            _technicallyNormalize(entry.phrase),
            () => <CanonicalPhraseEntry>[],
          )
          .add(entry);
    }

    final List<CanonicalBusinessTextClassification> classifications =
        <CanonicalBusinessTextClassification>[
          for (final CanonicalBusinessTextCandidate candidate
              in candidates.candidates)
            _classifyCandidate(
              candidate,
              entriesByTechnicallyNormalizedText[_technicallyNormalize(
                    candidate.text,
                  )] ??
                  const <CanonicalPhraseEntry>[],
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

  CanonicalBusinessTextClassification _classifyCandidate(
    CanonicalBusinessTextCandidate candidate,
    List<CanonicalPhraseEntry> exactTextMatches,
  ) {
    if (exactTextMatches.isEmpty) {
      return CanonicalBusinessTextClassification(
        candidate: candidate,
        status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        reason:
            CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
      );
    }

    if (exactTextMatches.length > 1) {
      return CanonicalBusinessTextClassification(
        candidate: candidate,
        status: CanonicalBusinessTextClassificationStatus.review,
        reason: CanonicalBusinessTextClassificationReason
            .ambiguousExactCanonicalTextMatch,
        matchedCanonicalEntries: exactTextMatches,
      );
    }

    final CanonicalPhraseEntry exactMatch = exactTextMatches.single;

    if (exactMatch.applicability.isNotEmpty) {
      return CanonicalBusinessTextClassification(
        candidate: candidate,
        status: CanonicalBusinessTextClassificationStatus.review,
        reason: CanonicalBusinessTextClassificationReason
            .exactTextRequiresApplicabilityReview,
        matchedCanonicalEntries: <CanonicalPhraseEntry>[exactMatch],
      );
    }

    return CanonicalBusinessTextClassification(
      candidate: candidate,
      status: CanonicalBusinessTextClassificationStatus.exact,
      reason:
          CanonicalBusinessTextClassificationReason.singleExactUniversalMatch,
      matchedCanonicalEntries: <CanonicalPhraseEntry>[exactMatch],
    );
  }

  String _technicallyNormalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
