import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_vocabulary.dart';

void main() {
  group('CanonicalPhraseVocabulary', () {
    test('preserves duplicate phrase text from distinct collections', () {
      final CanonicalPhraseVocabulary vocabulary = CanonicalPhraseVocabulary(
        entries: <CanonicalPhraseEntry>[
          _entry(collectionId: 'collection-a', phrase: 'Shared phrase.'),
          _entry(collectionId: 'collection-b', phrase: 'Shared phrase.'),
          _entry(collectionId: 'collection-b', phrase: 'Other phrase.'),
        ],
      );

      expect(vocabulary.entries, hasLength(3));
      expect(vocabulary.uniquePhraseCount, 2);

      expect(vocabulary.entriesForExactPhrase('Shared phrase.'), hasLength(2));

      expect(vocabulary.entriesForCollection('collection-b'), hasLength(2));

      expect(
        () => vocabulary.entries.add(
          _entry(collectionId: 'collection-c', phrase: 'Another phrase.'),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate stable identities', () {
      final CanonicalPhraseEntry entry = _entry(
        collectionId: 'collection',
        phrase: 'Canonical phrase.',
      );

      expect(
        () => CanonicalPhraseVocabulary(
          entries: <CanonicalPhraseEntry>[entry, entry],
        ),
        throwsArgumentError,
      );
    });
  });
}

CanonicalPhraseEntry _entry({
  required String collectionId,
  required String phrase,
}) {
  return CanonicalPhraseEntry(
    dictionaryId: 'DICTIONARY',
    collectionId: collectionId,
    phrase: phrase,
    sourceDocumentPath: 'docs/contract.md',
    sourceRevision: 'revision-1',
    sourceSnapshotFingerprint: 'git-blob:source',
    sourceStartLine: 10,
    sourceEndLine: 10,
  );
}
