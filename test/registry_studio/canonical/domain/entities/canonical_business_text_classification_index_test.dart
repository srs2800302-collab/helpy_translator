import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  test('indexes immutable classifications by candidate and status', () {
    final CanonicalBusinessTextClassification exact = _exactClassification(
      candidateIdentity: 'candidate-1',
    );

    final CanonicalBusinessTextClassification neutral =
        CanonicalBusinessTextClassification(
          candidate: _candidate(
            identity: 'candidate-2',
            text: 'Неизвестная фраза.',
          ),
          status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
          reason: CanonicalBusinessTextClassificationReason
              .noExactCanonicalTextMatch,
        );

    final CanonicalBusinessTextClassificationIndex index =
        CanonicalBusinessTextClassificationIndex(
          projectId: 'helpy',
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
          ],
        );

    expect(index.countFor(CanonicalBusinessTextClassificationStatus.exact), 1);

    expect(
      index.countFor(
        CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
      ),
      1,
    );

    expect(index.countFor(CanonicalBusinessTextClassificationStatus.review), 0);

    expect(index.classificationsByCandidateIdentity['candidate-1'], exact);

    expect(() => index.classifications.clear(), throwsUnsupportedError);
  });

  test('rejects more than one classification per candidate', () {
    final CanonicalBusinessTextClassification first = _exactClassification(
      candidateIdentity: 'candidate-1',
    );

    final CanonicalBusinessTextClassification second = _exactClassification(
      candidateIdentity: 'candidate-1',
    );

    expect(
      () => CanonicalBusinessTextClassificationIndex(
        projectId: 'helpy',
        candidateSourceDocumentPath: 'registry.md',
        candidateSourceRevision: 'registry-revision',
        candidateSourceSnapshotFingerprint: 'git-blob:registry',
        dictionaryId: 'DICTIONARY',
        dictionaryVersion: '1',
        dictionarySourceRevision: 'dictionary-revision',
        dictionarySourceSnapshotFingerprint: 'sha256:dictionary',
        classifications: <CanonicalBusinessTextClassification>[first, second],
      ),
      throwsArgumentError,
    );
  });
}

CanonicalBusinessTextClassification _exactClassification({
  required String candidateIdentity,
}) {
  final CanonicalPhraseEntry entry = CanonicalPhraseEntry(
    identity: 'dictionary::photo',
    collectionId: 'collection',
    phrase: 'Фотография места установки.',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceStartLine: 100,
    sourceEndLine: 100,
  );

  return CanonicalBusinessTextClassification(
    candidate: _candidate(identity: candidateIdentity, text: entry.phrase),
    status: CanonicalBusinessTextClassificationStatus.exact,
    reason: CanonicalBusinessTextClassificationReason.singleExactUniversalMatch,
    matchedCanonicalEntries: <CanonicalPhraseEntry>[entry],
  );
}

CanonicalBusinessTextCandidate _candidate({
  required String identity,
  required String text,
}) {
  final RegistryPath path = RegistryPath(const <String>[
    'Registry',
    'Business Rules',
  ]);

  return CanonicalBusinessTextCandidate(
    identity: identity,
    nodeId: RegistryNodeId('node-$identity'),
    businessScopeOwnerId: RegistryEntityId('owner-1'),
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
