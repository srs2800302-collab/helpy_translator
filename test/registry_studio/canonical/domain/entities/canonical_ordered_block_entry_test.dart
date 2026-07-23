import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_ordered_block_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_ordered_block_item.dart';

void main() {
  group('CanonicalOrderedBlockEntry', () {
    test('preserves stable key, approved order and ordered items', () {
      final List<CanonicalOrderedBlockItem> items = <CanonicalOrderedBlockItem>[
        CanonicalOrderedBlockItem(
          approvedOrder: 1,
          text: ' Ordered statement. ',
          sourceStartLine: 11,
          sourceEndLine: 11,
        ),
      ];

      final CanonicalOrderedBlockEntry entry = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'ordered.blocks',
        stableBlockKey: 'Rule Key',
        approvedOrder: 1,
        heading: ' Rule ',
        items: items,
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 11,
      );

      items.clear();

      expect(entry.dictionaryId, 'DICTIONARY');
      expect(entry.collectionId, 'ordered.blocks');
      expect(entry.stableBlockKey, 'Rule Key');
      expect(entry.approvedOrder, 1);
      expect(entry.heading, 'Rule');

      expect(
        entry.approvedTextHash,
        'sha256:'
        '681e62ac1c4fd1931fe45981044506dbcca7c34f8635c5d3ecfe6d6b5c9a9b50',
      );

      expect(
        entry.identity,
        'DICTIONARY::'
        'ordered.blocks::'
        'sha256:'
        '681e62ac1c4fd1931fe45981044506dbcca7c34f8635c5d3ecfe6d6b5c9a9b50::'
        'Rule Key::'
        'order:1',
      );

      expect(entry.items, hasLength(1));
      expect(entry.items.single.approvedOrder, 1);
      expect(entry.items.single.text, 'Ordered statement.');

      expect(
        () => entry.items.add(
          CanonicalOrderedBlockItem(
            approvedOrder: 2,
            text: 'Other.',
            sourceStartLine: 12,
            sourceEndLine: 12,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('ordered item sequence changes the approved text identity', () {
      final CanonicalOrderedBlockEntry first = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'ordered.blocks',
        stableBlockKey: 'Rule Key',
        approvedOrder: 1,
        heading: 'Rule',
        items: <CanonicalOrderedBlockItem>[
          CanonicalOrderedBlockItem(
            approvedOrder: 1,
            text: 'First.',
            sourceStartLine: 11,
            sourceEndLine: 11,
          ),
          CanonicalOrderedBlockItem(
            approvedOrder: 2,
            text: 'Second.',
            sourceStartLine: 12,
            sourceEndLine: 12,
          ),
        ],
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 12,
      );

      final CanonicalOrderedBlockEntry reversed = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'ordered.blocks',
        stableBlockKey: 'Rule Key',
        approvedOrder: 1,
        heading: 'Rule',
        items: <CanonicalOrderedBlockItem>[
          CanonicalOrderedBlockItem(
            approvedOrder: 1,
            text: 'Second.',
            sourceStartLine: 11,
            sourceEndLine: 11,
          ),
          CanonicalOrderedBlockItem(
            approvedOrder: 2,
            text: 'First.',
            sourceStartLine: 12,
            sourceEndLine: 12,
          ),
        ],
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 12,
      );

      expect(first.approvedTextHash, isNot(reversed.approvedTextHash));

      expect(first.identity, isNot(reversed.identity));
    });

    test('block order participates in identity', () {
      final CanonicalOrderedBlockEntry first = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'ordered.blocks',
        stableBlockKey: 'Rule Key',
        approvedOrder: 1,
        heading: 'Rule',
        items: <CanonicalOrderedBlockItem>[
          CanonicalOrderedBlockItem(
            approvedOrder: 1,
            text: 'Statement.',
            sourceStartLine: 11,
            sourceEndLine: 11,
          ),
        ],
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 11,
      );

      final CanonicalOrderedBlockEntry second = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'ordered.blocks',
        stableBlockKey: 'Rule Key',
        approvedOrder: 2,
        heading: 'Rule',
        items: <CanonicalOrderedBlockItem>[
          CanonicalOrderedBlockItem(
            approvedOrder: 1,
            text: 'Statement.',
            sourceStartLine: 11,
            sourceEndLine: 11,
          ),
        ],
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 11,
      );

      expect(first.approvedTextHash, second.approvedTextHash);

      expect(first.identity, isNot(second.identity));
    });

    test('rejects non-contiguous item order', () {
      expect(
        () => CanonicalOrderedBlockEntry(
          dictionaryId: 'DICTIONARY',
          collectionId: 'ordered.blocks',
          stableBlockKey: 'Rule Key',
          approvedOrder: 1,
          heading: 'Rule',
          items: <CanonicalOrderedBlockItem>[
            CanonicalOrderedBlockItem(
              approvedOrder: 2,
              text: 'Ordered statement.',
              sourceStartLine: 11,
              sourceEndLine: 11,
            ),
          ],
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceStartLine: 10,
          sourceEndLine: 11,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-contiguous ordered collection entries', () {
      final CanonicalOrderedBlockEntry entry = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'ordered.blocks',
        stableBlockKey: 'Rule Key',
        approvedOrder: 2,
        heading: 'Rule',
        items: <CanonicalOrderedBlockItem>[
          CanonicalOrderedBlockItem(
            approvedOrder: 1,
            text: 'Statement.',
            sourceStartLine: 11,
            sourceEndLine: 11,
          ),
        ],
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 11,
      );

      expect(
        () => CanonicalDictionaryCollection(
          id: 'ordered.blocks',
          entryType: 'ordered_block',
          status: 'APPROVED / STORED',
          content: 'ordered content',
          startLine: 5,
          endLine: 15,
          entries: <CanonicalOrderedBlockEntry>[entry],
        ),
        throwsArgumentError,
      );
    });
    test('rejects an empty ordered collection', () {
      expect(
        () => CanonicalDictionaryCollection(
          id: 'ordered.blocks',
          entryType: 'ordered_block',
          status: 'APPROVED / STORED',
          content: 'ordered content',
          startLine: 5,
          endLine: 15,
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate ordered stable block keys', () {
      final CanonicalOrderedBlockEntry first = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'ordered.blocks',
        stableBlockKey: 'Rule Key',
        approvedOrder: 1,
        heading: 'First rule',
        items: <CanonicalOrderedBlockItem>[
          CanonicalOrderedBlockItem(
            approvedOrder: 1,
            text: 'First statement.',
            sourceStartLine: 11,
            sourceEndLine: 11,
          ),
        ],
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 11,
      );

      final CanonicalOrderedBlockEntry second = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'ordered.blocks',
        stableBlockKey: 'Rule Key',
        approvedOrder: 2,
        heading: 'Second rule',
        items: <CanonicalOrderedBlockItem>[
          CanonicalOrderedBlockItem(
            approvedOrder: 1,
            text: 'Second statement.',
            sourceStartLine: 13,
            sourceEndLine: 13,
          ),
        ],
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 12,
        sourceEndLine: 13,
      );

      expect(
        () => CanonicalDictionaryCollection(
          id: 'ordered.blocks',
          entryType: 'ordered_block',
          status: 'APPROVED / STORED',
          content: 'ordered content',
          startLine: 5,
          endLine: 15,
          entries: <CanonicalOrderedBlockEntry>[first, second],
        ),
        throwsArgumentError,
      );
    });

    test('rejects an ordered entry in a non-ordered collection', () {
      final CanonicalOrderedBlockEntry entry = CanonicalOrderedBlockEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'phrases',
        stableBlockKey: 'Rule Key',
        approvedOrder: 1,
        heading: 'Rule',
        items: <CanonicalOrderedBlockItem>[
          CanonicalOrderedBlockItem(
            approvedOrder: 1,
            text: 'Statement.',
            sourceStartLine: 11,
            sourceEndLine: 11,
          ),
        ],
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceStartLine: 10,
        sourceEndLine: 11,
      );

      expect(
        () => CanonicalDictionaryCollection(
          id: 'phrases',
          entryType: 'phrase',
          status: 'APPROVED / STORED',
          content: 'phrase content',
          startLine: 5,
          endLine: 15,
          entries: <CanonicalOrderedBlockEntry>[entry],
        ),
        throwsArgumentError,
      );
    });
  });
}
