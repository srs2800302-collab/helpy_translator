import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';

void main() {
  group('CanonicalPhraseEntry', () {
    test('preserves exact phrase, applicability and source evidence', () {
      final List<String> applicability = <String>['Install only.'];

      final CanonicalPhraseEntry entry = CanonicalPhraseEntry(
        identity: ' collection::phrase::entry ',
        collectionId: ' collection ',
        phrase: ' Canonical phrase. ',
        applicability: applicability,
        sourceDocumentPath: ' docs/contract.md ',
        sourceRevision: ' revision-1 ',
        sourceSnapshotFingerprint: ' git-blob:source ',
        sourceStartLine: 10,
        sourceEndLine: 11,
      );

      applicability.clear();

      expect(entry.identity, 'collection::phrase::entry');
      expect(entry.collectionId, 'collection');
      expect(entry.phrase, 'Canonical phrase.');

      expect(entry.applicability, <String>['Install only.']);

      expect(() => entry.applicability.add('Other.'), throwsUnsupportedError);

      expect(entry.sourceDocumentPath, 'docs/contract.md');
      expect(entry.sourceRevision, 'revision-1');
      expect(entry.sourceStartLine, 10);
      expect(entry.sourceEndLine, 11);
    });

    test('rejects duplicate applicability values', () {
      expect(
        () => CanonicalPhraseEntry(
          identity: 'collection::phrase::entry',
          collectionId: 'collection',
          phrase: 'Canonical phrase.',
          applicability: const <String>['Install only.', 'Install only.'],
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceStartLine: 10,
          sourceEndLine: 11,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an invalid source line range', () {
      expect(
        () => CanonicalPhraseEntry(
          identity: 'collection::phrase::entry',
          collectionId: 'collection',
          phrase: 'Canonical phrase.',
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceStartLine: 11,
          sourceEndLine: 10,
        ),
        throwsArgumentError,
      );
    });

    test('collection rejects an entry belonging to another collection', () {
      final CanonicalPhraseEntry entry = CanonicalPhraseEntry(
        identity: 'other::phrase::entry',
        collectionId: 'other',
        phrase: 'Canonical phrase.',
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 10,
      );

      expect(
        () => CanonicalDictionaryCollection(
          id: 'collection',
          entryType: 'phrase',
          status: 'APPROVED / STORED',
          content: '- Canonical phrase.',
          startLine: 5,
          endLine: 15,
          entries: <CanonicalPhraseEntry>[entry],
        ),
        throwsArgumentError,
      );
    });

    test('collection rejects an entry outside its source range', () {
      final CanonicalPhraseEntry entry = CanonicalPhraseEntry(
        identity: 'collection::phrase::entry',
        collectionId: 'collection',
        phrase: 'Canonical phrase.',
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 16,
        sourceEndLine: 16,
      );

      expect(
        () => CanonicalDictionaryCollection(
          id: 'collection',
          entryType: 'phrase',
          status: 'APPROVED / STORED',
          content: '- Canonical phrase.',
          startLine: 5,
          endLine: 15,
          entries: <CanonicalPhraseEntry>[entry],
        ),
        throwsArgumentError,
      );
    });
  });
}
