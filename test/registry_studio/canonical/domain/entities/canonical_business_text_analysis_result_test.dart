import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_analysis_result.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('CanonicalBusinessTextAnalysisResult', () {
    test('preserves exact sources and immutable aggregates', () {
      final RegistryEntityId firstOwner = RegistryEntityId('owner-1');

      final RegistryEntityId secondOwner = RegistryEntityId('owner-2');

      final CanonicalBusinessTextCandidate first = _candidate(
        identity: 'candidate-1',
        nodeId: 'node-1',
        ownerId: firstOwner,
        text: 'Canonical phrase.',
      );

      final CanonicalBusinessTextCandidate second = _candidate(
        identity: 'candidate-2',
        nodeId: 'node-2',
        ownerId: secondOwner,
        text: 'Unknown phrase.',
      );

      final CanonicalBusinessTextCandidateIndex candidates = _candidateIndex(
        <CanonicalBusinessTextCandidate>[first, second],
      );

      final CanonicalPhraseEntry phrase = _phrase();

      final CanonicalBusinessTextClassification exact =
          CanonicalBusinessTextClassification(
            candidate: first,
            status: CanonicalBusinessTextClassificationStatus.exact,
            reason: CanonicalBusinessTextClassificationReason
                .singleExactUniversalMatch,
            matchedCanonicalEntries: <CanonicalPhraseEntry>[phrase],
          );

      final CanonicalBusinessTextClassification
      neutral = CanonicalBusinessTextClassification(
        candidate: second,
        status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        reason:
            CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
      );

      final CanonicalDictionary dictionary = _dictionary(phrase);

      final CanonicalBusinessTextAnalysisResult result =
          CanonicalBusinessTextAnalysisResult(
            candidates: candidates,
            classifications: _classificationIndex(
              <CanonicalBusinessTextClassification>[exact, neutral],
            ),
            dictionary: dictionary,
          );

      expect(result.totalCandidateCount, 2);

      expect(result.registrySourceRevision, 'registry-revision');

      expect(result.registrySourceSnapshotFingerprint, 'git-blob:registry');

      expect(result.dictionarySourceRevision, 'dictionary-revision');

      expect(result.dictionarySourceSnapshotFingerprint, 'sha256:dictionary');

      expect(
        result.countForStatus(CanonicalBusinessTextClassificationStatus.exact),
        1,
      );

      expect(
        result.countForStatus(
          CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        ),
        1,
      );

      expect(result.countForBusinessScopeOwner(firstOwner), 1);

      expect(result.countForBusinessScopeOwner(secondOwner), 1);

      expect(
        result.countForBusinessScopeOwnerAndStatus(
          firstOwner,
          CanonicalBusinessTextClassificationStatus.exact,
        ),
        1,
      );

      expect(
        result.classificationsByBusinessScopeOwnerId[firstOwner],
        <CanonicalBusinessTextClassification>[exact],
      );

      expect(() => result.countsByStatus.clear(), throwsUnsupportedError);

      expect(
        () => result.classificationsByBusinessScopeOwnerId[firstOwner]?.clear(),
        throwsUnsupportedError,
      );

      expect(
        () => result.countsByBusinessScopeOwnerAndStatus[firstOwner]?.clear(),
        throwsUnsupportedError,
      );
    });

    test('rejects a missing candidate classification', () {
      final CanonicalBusinessTextCandidate first = _candidate(
        identity: 'candidate-1',
        nodeId: 'node-1',
        ownerId: RegistryEntityId('owner-1'),
        text: 'Canonical phrase.',
      );

      final CanonicalBusinessTextCandidate second = _candidate(
        identity: 'candidate-2',
        nodeId: 'node-2',
        ownerId: RegistryEntityId('owner-1'),
        text: 'Unknown phrase.',
      );

      final CanonicalPhraseEntry phrase = _phrase();

      expect(
        () => CanonicalBusinessTextAnalysisResult(
          candidates: _candidateIndex(<CanonicalBusinessTextCandidate>[
            first,
            second,
          ]),
          classifications: _classificationIndex(
            <CanonicalBusinessTextClassification>[
              CanonicalBusinessTextClassification(
                candidate: first,
                status: CanonicalBusinessTextClassificationStatus.exact,
                reason: CanonicalBusinessTextClassificationReason
                    .singleExactUniversalMatch,
                matchedCanonicalEntries: <CanonicalPhraseEntry>[phrase],
              ),
            ],
          ),
          dictionary: _dictionary(phrase),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a mismatched dictionary source revision', () {
      final CanonicalBusinessTextCandidate candidate = _candidate(
        identity: 'candidate-1',
        nodeId: 'node-1',
        ownerId: RegistryEntityId('owner-1'),
        text: 'Unknown phrase.',
      );

      expect(
        () => CanonicalBusinessTextAnalysisResult(
          candidates: _candidateIndex(<CanonicalBusinessTextCandidate>[
            candidate,
          ]),
          classifications: CanonicalBusinessTextClassificationIndex(
            projectId: 'helpy',
            candidateSourceDocumentPath: 'registry.md',
            candidateSourceRevision: 'registry-revision',
            candidateSourceSnapshotFingerprint: 'git-blob:registry',
            dictionaryId: 'DICTIONARY',
            dictionaryVersion: '1',
            dictionarySourceRevision: 'wrong-dictionary-revision',
            dictionarySourceSnapshotFingerprint: 'sha256:dictionary',
            classifications: <CanonicalBusinessTextClassification>[
              CanonicalBusinessTextClassification(
                candidate: candidate,
                status: CanonicalBusinessTextClassificationStatus
                    .unclassifiedNeutral,
                reason: CanonicalBusinessTextClassificationReason
                    .noExactCanonicalTextMatch,
              ),
            ],
          ),
          dictionary: _dictionary(_phrase()),
        ),
        throwsArgumentError,
      );
    });
  });
}

CanonicalBusinessTextCandidateIndex _candidateIndex(
  Iterable<CanonicalBusinessTextCandidate> candidates,
) {
  return CanonicalBusinessTextCandidateIndex(
    projectId: 'helpy',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'registry-revision',
    sourceSnapshotFingerprint: 'git-blob:registry',
    candidates: candidates,
  );
}

CanonicalBusinessTextClassificationIndex _classificationIndex(
  Iterable<CanonicalBusinessTextClassification> classifications,
) {
  return CanonicalBusinessTextClassificationIndex(
    projectId: 'helpy',
    candidateSourceDocumentPath: 'registry.md',
    candidateSourceRevision: 'registry-revision',
    candidateSourceSnapshotFingerprint: 'git-blob:registry',
    dictionaryId: 'DICTIONARY',
    dictionaryVersion: '1',
    dictionarySourceRevision: 'dictionary-revision',
    dictionarySourceSnapshotFingerprint: 'sha256:dictionary',
    classifications: classifications,
  );
}

CanonicalBusinessTextCandidate _candidate({
  required String identity,
  required String nodeId,
  required RegistryEntityId ownerId,
  required String text,
}) {
  final RegistryPath path = RegistryPath(<String>['Registry', nodeId]);

  return CanonicalBusinessTextCandidate(
    identity: identity,
    nodeId: RegistryNodeId(nodeId),
    businessScopeOwnerId: ownerId,
    path: path,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'git-blob:registry',
        headingPath: path.segments,
        startLine: 1,
        endLine: 10,
      ),
    ],
    kind: CanonicalBusinessTextCandidateKind.listItem,
    rawText: '- $text',
    text: text,
    directContentLine: 1,
  );
}

CanonicalDictionary _dictionary(CanonicalPhraseEntry phrase) {
  return CanonicalDictionary(
    dictionaryId: 'DICTIONARY',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceContent: 'dictionary source',
    beginMarkerLine: 1,
    endMarkerLine: 20,
    collections: <CanonicalDictionaryCollection>[
      CanonicalDictionaryCollection(
        id: 'collection',
        entryType: 'phrase',
        status: 'APPROVED / STORED',
        content: '- Canonical phrase.',
        startLine: 2,
        endLine: 19,
        entries: <CanonicalPhraseEntry>[phrase],
      ),
    ],
  );
}

CanonicalPhraseEntry _phrase() {
  return CanonicalPhraseEntry(
    identity: 'collection::canonical-phrase',
    collectionId: 'collection',
    phrase: 'Canonical phrase.',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceStartLine: 5,
    sourceEndLine: 5,
  );
}
