import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';

void main() {
  group('CanonicalPhraseEntry', () {
    test('derives identity from dictionary, collection and text hash', () {
      final List<String> applicability = <String>['Install only.'];

      final CanonicalPhraseEntry entry = CanonicalPhraseEntry(
        dictionaryId: 'DICTIONARY',
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

      expect(entry.dictionaryId, 'DICTIONARY');
      expect(entry.collectionId, 'collection');
      expect(entry.phrase, 'Canonical phrase.');

      expect(
        entry.approvedTextHash,
        'sha256:'
        '2c4ca2691003c0b247d5db065ffe547c6755d1428cc325ef52ae804be6b037c3',
      );

      expect(
        entry.identity,
        'DICTIONARY::collection::sha256:'
        '2c4ca2691003c0b247d5db065ffe547c6755d1428cc325ef52ae804be6b037c3',
      );

      expect(entry.applicability, <String>['Install only.']);

      expect(() => entry.applicability.add('Other.'), throwsUnsupportedError);

      expect(entry.sourceDocumentPath, 'docs/contract.md');
      expect(entry.sourceRevision, 'revision-1');
      expect(entry.sourceStartLine, 10);
      expect(entry.sourceEndLine, 11);
    });

    test('normalizes technical whitespace without changing case', () {
      final CanonicalPhraseEntry spaced = CanonicalPhraseEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'collection',
        phrase: 'Canonical   phrase.',
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 10,
      );

      final CanonicalPhraseEntry normalized = CanonicalPhraseEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'collection',
        phrase: 'Canonical phrase.',
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 11,
        sourceEndLine: 11,
      );

      final CanonicalPhraseEntry changedCase = CanonicalPhraseEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'collection',
        phrase: 'canonical phrase.',
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 12,
        sourceEndLine: 12,
      );

      expect(spaced.approvedTextHash, normalized.approvedTextHash);

      expect(spaced.identity, normalized.identity);

      expect(spaced.phrase, 'Canonical   phrase.');

      expect(changedCase.approvedTextHash, isNot(normalized.approvedTextHash));

      expect(changedCase.identity, isNot(normalized.identity));
    });

    test('rejects an empty dictionary identity', () {
      expect(
        () => CanonicalPhraseEntry(
          dictionaryId: ' ',
          collectionId: 'collection',
          phrase: 'Canonical phrase.',
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceStartLine: 10,
          sourceEndLine: 10,
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate applicability values', () {
      expect(
        () => CanonicalPhraseEntry(
          dictionaryId: 'DICTIONARY',
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
          dictionaryId: 'DICTIONARY',
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
        dictionaryId: 'DICTIONARY',
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
        dictionaryId: 'DICTIONARY',
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
    test('dictionary rejects an entry owned by another dictionary', () {
      final CanonicalPhraseEntry entry = CanonicalPhraseEntry(
        dictionaryId: 'OTHER_DICTIONARY',
        collectionId: 'collection',
        phrase: 'Canonical phrase.',
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 10,
      );

      final CanonicalDictionaryCollection collection =
          CanonicalDictionaryCollection(
            id: 'collection',
            entryType: 'phrase',
            status: 'APPROVED / STORED',
            content: '- Canonical phrase.',
            startLine: 5,
            endLine: 15,
            entries: <CanonicalPhraseEntry>[entry],
          );

      expect(
        () => CanonicalDictionary(
          dictionaryId: 'DICTIONARY',
          version: '1',
          status: 'APPROVED / STORED',
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceContent: 'dictionary source',
          beginMarkerLine: 1,
          endMarkerLine: 20,
          collections: <CanonicalDictionaryCollection>[collection],
        ),
        throwsArgumentError,
      );
    });
  });
}
