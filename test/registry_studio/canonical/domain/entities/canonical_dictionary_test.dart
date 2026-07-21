import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';

void main() {
  group('CanonicalDictionary', () {
    test('preserves exact source identity and immutable collections', () {
      final List<CanonicalDictionaryCollection> sourceCollections =
          <CanonicalDictionaryCollection>[
            CanonicalDictionaryCollection(
              id: 'sample.canonical.phrases',
              entryType: 'phrase',
              status: 'APPROVED / STORED',
              content: '- Canonical phrase.',
              startLine: 10,
              endLine: 15,
            ),
          ];

      final CanonicalDictionary dictionary = CanonicalDictionary(
        dictionaryId: ' SAMPLE_DICTIONARY ',
        version: ' 1 ',
        status: ' APPROVED / STORED ',
        sourceDocumentPath: ' docs/contract.md ',
        sourceRevision: ' revision-1 ',
        sourceSnapshotFingerprint: ' git-blob:source ',
        sourceContent: 'source content',
        beginMarkerLine: 5,
        endMarkerLine: 20,
        collections: sourceCollections,
      );

      sourceCollections.clear();

      expect(dictionary.dictionaryId, 'SAMPLE_DICTIONARY');
      expect(dictionary.version, '1');
      expect(dictionary.status, 'APPROVED / STORED');
      expect(dictionary.sourceDocumentPath, 'docs/contract.md');
      expect(dictionary.sourceRevision, 'revision-1');
      expect(dictionary.collections, hasLength(1));
      expect(
        dictionary.collectionById('sample.canonical.phrases')?.entryType,
        'phrase',
      );
      expect(
        () => dictionary.collections.add(
          CanonicalDictionaryCollection(
            id: 'other',
            entryType: 'phrase',
            status: 'APPROVED / STORED',
            content: 'Other.',
            startLine: 16,
            endLine: 17,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate collection identities', () {
      final CanonicalDictionaryCollection collection =
          CanonicalDictionaryCollection(
            id: 'sample.canonical.phrases',
            entryType: 'phrase',
            status: 'APPROVED / STORED',
            content: '- Canonical phrase.',
            startLine: 10,
            endLine: 15,
          );

      expect(
        () => CanonicalDictionary(
          dictionaryId: 'SAMPLE_DICTIONARY',
          version: '1',
          status: 'APPROVED / STORED',
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceContent: 'source content',
          beginMarkerLine: 5,
          endMarkerLine: 20,
          collections: <CanonicalDictionaryCollection>[collection, collection],
        ),
        throwsArgumentError,
      );
    });

    test('rejects collections outside stable dictionary markers', () {
      expect(
        () => CanonicalDictionary(
          dictionaryId: 'SAMPLE_DICTIONARY',
          version: '1',
          status: 'APPROVED / STORED',
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceContent: 'source content',
          beginMarkerLine: 5,
          endMarkerLine: 20,
          collections: <CanonicalDictionaryCollection>[
            CanonicalDictionaryCollection(
              id: 'sample.canonical.phrases',
              entryType: 'phrase',
              status: 'APPROVED / STORED',
              content: '- Canonical phrase.',
              startLine: 5,
              endLine: 15,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
