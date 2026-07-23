import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/build_canonical_phrase_vocabulary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_ordered_block_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_ordered_block_item.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_vocabulary.dart';

void main() {
  test('BuildCanonicalPhraseVocabulary collects only typed phrase entries', () {
    final CanonicalPhraseEntry phraseEntry = CanonicalPhraseEntry(
      dictionaryId: 'DICTIONARY',
      collectionId: 'collection',
      phrase: 'Canonical phrase.',
      sourceDocumentPath: 'docs/contract.md',
      sourceRevision: 'revision-1',
      sourceSnapshotFingerprint: 'git-blob:source',
      sourceStartLine: 10,
      sourceEndLine: 10,
    );

    final CanonicalOrderedBlockEntry orderedBlock = CanonicalOrderedBlockEntry(
      dictionaryId: 'DICTIONARY',
      collectionId: 'ordered-blocks',
      stableBlockKey: 'Rule Key',
      approvedOrder: 1,
      heading: 'Rule',
      items: <CanonicalOrderedBlockItem>[
        CanonicalOrderedBlockItem(
          approvedOrder: 1,
          text: 'Ordered statement.',
          sourceStartLine: 18,
          sourceEndLine: 18,
        ),
      ],
      sourceDocumentPath: 'docs/contract.md',
      sourceRevision: 'revision-1',
      sourceSnapshotFingerprint: 'git-blob:source',
      sourceStartLine: 17,
      sourceEndLine: 18,
    );

    final CanonicalDictionary dictionary = CanonicalDictionary(
      dictionaryId: 'DICTIONARY',
      version: '1',
      status: 'APPROVED / STORED',
      sourceDocumentPath: 'docs/contract.md',
      sourceRevision: 'revision-1',
      sourceSnapshotFingerprint: 'git-blob:source',
      sourceContent: 'source content',
      beginMarkerLine: 1,
      endMarkerLine: 30,
      collections: <CanonicalDictionaryCollection>[
        CanonicalDictionaryCollection(
          id: 'collection',
          entryType: 'phrase',
          status: 'APPROVED / STORED',
          content: '- Canonical phrase.',
          startLine: 5,
          endLine: 15,
          entries: <CanonicalPhraseEntry>[phraseEntry],
        ),
        CanonicalDictionaryCollection(
          id: 'ordered-blocks',
          entryType: 'ordered_block',
          status: 'APPROVED / STORED',
          content: '1. Block.',
          startLine: 16,
          endLine: 25,
          entries: <CanonicalOrderedBlockEntry>[orderedBlock],
        ),
      ],
    );

    final CanonicalPhraseVocabulary vocabulary =
        const BuildCanonicalPhraseVocabulary().call(dictionary);

    expect(dictionary.collections[1].entries, <CanonicalOrderedBlockEntry>[
      orderedBlock,
    ]);
    expect(vocabulary.entries, <CanonicalPhraseEntry>[phraseEntry]);
    expect(vocabulary.uniquePhraseCount, 1);
  });
}
