import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_classifier.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';

void main() {
  test('CanonicalBusinessTextClassifier exposes one '
      'project-independent classification capability', () {
    final CanonicalBusinessTextClassifier classifier = _EmptyClassifier();

    final CanonicalBusinessTextClassificationIndex index = classifier.classify(
      candidates: CanonicalBusinessTextCandidateIndex(
        projectId: 'project',
        sourceDocumentPath: 'registry.md',
        sourceRevision: 'registry-revision',
        sourceSnapshotFingerprint: 'git-blob:registry',
        candidates: const <Never>[],
      ),
      dictionary: CanonicalDictionary(
        dictionaryId: 'DICTIONARY',
        version: '1',
        status: 'APPROVED / STORED',
        sourceDocumentPath: 'contract.md',
        sourceRevision: 'dictionary-revision',
        sourceSnapshotFingerprint: 'sha256:dictionary',
        sourceContent: 'dictionary source',
        beginMarkerLine: 1,
        endMarkerLine: 10,
        collections: <CanonicalDictionaryCollection>[
          CanonicalDictionaryCollection(
            id: 'canonical.phrases',
            entryType: 'phrase',
            status: 'APPROVED / STORED',
            content: '- Canonical phrase.',
            startLine: 2,
            endLine: 9,
            entries: <CanonicalPhraseEntry>[
              CanonicalPhraseEntry(
                identity:
                    'canonical.phrases::'
                    'phrase::canonical-phrase',
                collectionId: 'canonical.phrases',
                phrase: 'Canonical phrase.',
                sourceDocumentPath: 'contract.md',
                sourceRevision: 'dictionary-revision',
                sourceSnapshotFingerprint: 'sha256:dictionary',
                sourceStartLine: 5,
                sourceEndLine: 5,
              ),
            ],
          ),
        ],
      ),
    );

    expect(index.classifications, isEmpty);
    expect(index.projectId, 'project');
    expect(index.dictionaryId, 'DICTIONARY');
  });
}

final class _EmptyClassifier implements CanonicalBusinessTextClassifier {
  @override
  CanonicalBusinessTextClassificationIndex classify({
    required CanonicalBusinessTextCandidateIndex candidates,
    required CanonicalDictionary dictionary,
  }) {
    return CanonicalBusinessTextClassificationIndex(
      projectId: candidates.projectId,
      candidateSourceDocumentPath: candidates.sourceDocumentPath,
      candidateSourceRevision: candidates.sourceRevision,
      candidateSourceSnapshotFingerprint: candidates.sourceSnapshotFingerprint,
      dictionaryId: dictionary.dictionaryId,
      dictionaryVersion: dictionary.version,
      dictionarySourceRevision: dictionary.sourceRevision,
      dictionarySourceSnapshotFingerprint: dictionary.sourceSnapshotFingerprint,
      classifications: const <Never>[],
    );
  }
}
