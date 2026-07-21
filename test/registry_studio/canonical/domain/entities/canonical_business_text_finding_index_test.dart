import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_finding.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_finding_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('CanonicalBusinessTextFindingIndex', () {
    test('derives findings and excludes resolved classifications', () {
      final CanonicalBusinessTextCandidate exactCandidate = _candidate(
        identity: 'candidate-exact',
        nodeId: 'node-exact',
        text: 'Exact phrase.',
      );

      final CanonicalBusinessTextCandidate neutralCandidate = _candidate(
        identity: 'candidate-neutral',
        nodeId: 'node-neutral',
        text: 'Neutral phrase.',
      );

      final CanonicalBusinessTextCandidate reviewCandidate = _candidate(
        identity: 'candidate-review',
        nodeId: 'node-review',
        text: 'Review phrase.',
      );

      final CanonicalBusinessTextClassification
      exact = CanonicalBusinessTextClassification(
        candidate: exactCandidate,
        status: CanonicalBusinessTextClassificationStatus.exact,
        reason:
            CanonicalBusinessTextClassificationReason.singleExactUniversalMatch,
        matchedCanonicalEntries: <CanonicalPhraseEntry>[
          _entry(identity: 'dictionary::exact', phrase: exactCandidate.text),
        ],
      );

      final CanonicalBusinessTextClassification
      neutral = CanonicalBusinessTextClassification(
        candidate: neutralCandidate,
        status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        reason:
            CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
      );

      final CanonicalBusinessTextClassification review =
          CanonicalBusinessTextClassification(
            candidate: reviewCandidate,
            status: CanonicalBusinessTextClassificationStatus.review,
            reason: CanonicalBusinessTextClassificationReason
                .exactTextRequiresApplicabilityReview,
            matchedCanonicalEntries: <CanonicalPhraseEntry>[
              _entry(
                identity: 'dictionary::review',
                phrase: reviewCandidate.text,
                applicability: 'install scenario',
              ),
            ],
          );

      final CanonicalBusinessTextClassificationIndex classifications =
          CanonicalBusinessTextClassificationIndex(
            projectId: 'project',
            candidateSourceDocumentPath: 'registry.md',
            candidateSourceRevision: 'registry-revision',
            candidateSourceSnapshotFingerprint: 'git-blob:registry',
            dictionaryId: 'DICTIONARY',
            dictionaryVersion: '1',
            dictionarySourceRevision: 'dictionary-revision',
            dictionarySourceSnapshotFingerprint: 'sha256:dictionary',
            classifications: <CanonicalBusinessTextClassification>[
              exact,
              neutral,
              review,
            ],
          );

      final CanonicalBusinessTextFindingIndex index =
          CanonicalBusinessTextFindingIndex(classifications: classifications);

      expect(index.findingCount, 2);
      expect(index.informationalCount, 1);
      expect(index.actionRequiredCount, 1);

      expect(
        index.findingsByCandidateIdentity.containsKey(exactCandidate.identity),
        isFalse,
      );

      expect(
        index
            .findingsByCandidateIdentity[neutralCandidate.identity]
            ?.disposition,
        CanonicalBusinessTextFindingDisposition.informational,
      );

      expect(
        index
            .findingsByCandidateIdentity[reviewCandidate.identity]
            ?.disposition,
        CanonicalBusinessTextFindingDisposition.reviewRequired,
      );

      expect(
        index.countForStatus(
          CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        ),
        1,
      );

      expect(
        index.countForStatus(CanonicalBusinessTextClassificationStatus.review),
        1,
      );

      expect(
        index.countForStatus(CanonicalBusinessTextClassificationStatus.exact),
        0,
      );

      expect(() => index.findings.clear(), throwsA(isA<UnsupportedError>()));

      expect(
        () => CanonicalBusinessTextFinding(classification: exact),
        throwsArgumentError,
      );
    });
  });
}

CanonicalBusinessTextCandidate _candidate({
  required String identity,
  required String nodeId,
  required String text,
}) {
  final RegistryPath path = RegistryPath(<String>['Registry', identity]);

  return CanonicalBusinessTextCandidate(
    identity: identity,
    nodeId: RegistryNodeId(nodeId),
    businessScopeOwnerId: RegistryEntityId('owner'),
    path: path,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'git-blob:registry',
        headingPath: path.segments,
        startLine: 10,
        endLine: 10,
      ),
    ],
    kind: CanonicalBusinessTextCandidateKind.paragraph,
    rawText: text,
    text: text,
    directContentLine: 1,
  );
}

CanonicalPhraseEntry _entry({
  required String identity,
  required String phrase,
  String applicability = '',
}) {
  return CanonicalPhraseEntry(
    identity: identity,
    collectionId: 'canonical.phrases',
    phrase: phrase,
    applicability: applicability.isEmpty
        ? const <String>[]
        : <String>[applicability],
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceStartLine: 20,
    sourceEndLine: 20,
  );
}
