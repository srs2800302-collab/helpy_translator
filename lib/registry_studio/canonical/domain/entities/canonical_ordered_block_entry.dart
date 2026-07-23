import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'canonical_dictionary_entry.dart';
import 'canonical_ordered_block_item.dart';

final class CanonicalOrderedBlockEntry extends CanonicalDictionaryEntry {
  factory CanonicalOrderedBlockEntry({
    required String dictionaryId,
    required String collectionId,
    required String stableBlockKey,
    required int approvedOrder,
    required String heading,
    required Iterable<CanonicalOrderedBlockItem> items,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
    required int sourceStartLine,
    required int sourceEndLine,
  }) {
    final String normalizedDictionaryId = dictionaryId.trim();
    final String normalizedCollectionId = collectionId.trim();
    final String normalizedStableBlockKey = stableBlockKey.trim();
    final String normalizedHeading = heading.trim();
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedSourceRevision = sourceRevision.trim();
    final String normalizedSourceSnapshotFingerprint = sourceSnapshotFingerprint
        .trim();

    final List<CanonicalOrderedBlockItem> normalizedItems = items.toList(
      growable: false,
    );

    if (normalizedDictionaryId.isEmpty) {
      throw ArgumentError.value(
        dictionaryId,
        'dictionaryId',
        'Canonical ordered block dictionary identity must not be empty.',
      );
    }

    if (normalizedCollectionId.isEmpty) {
      throw ArgumentError.value(
        collectionId,
        'collectionId',
        'Canonical ordered block collection identity must not be empty.',
      );
    }

    if (normalizedStableBlockKey.isEmpty) {
      throw ArgumentError.value(
        stableBlockKey,
        'stableBlockKey',
        'Canonical ordered block stable key must not be empty.',
      );
    }

    if (approvedOrder < 1) {
      throw ArgumentError.value(
        approvedOrder,
        'approvedOrder',
        'Canonical ordered block order must be positive.',
      );
    }

    if (normalizedHeading.isEmpty) {
      throw ArgumentError.value(
        heading,
        'heading',
        'Canonical ordered block heading must not be empty.',
      );
    }

    if (normalizedItems.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'Canonical ordered block must contain at least one item.',
      );
    }

    if (normalizedSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentPath,
        'sourceDocumentPath',
        'Canonical ordered block source document path must not be empty.',
      );
    }

    if (normalizedSourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Canonical ordered block source revision must not be empty.',
      );
    }

    if (normalizedSourceSnapshotFingerprint.isEmpty) {
      throw ArgumentError.value(
        sourceSnapshotFingerprint,
        'sourceSnapshotFingerprint',
        'Canonical ordered block source fingerprint must not be empty.',
      );
    }

    if (sourceStartLine < 1) {
      throw ArgumentError.value(
        sourceStartLine,
        'sourceStartLine',
        'Canonical ordered block source start line must be positive.',
      );
    }

    if (sourceEndLine < sourceStartLine) {
      throw ArgumentError.value(
        sourceEndLine,
        'sourceEndLine',
        'Canonical ordered block source end line must not precede '
            'its start line.',
      );
    }

    for (int index = 0; index < normalizedItems.length; index += 1) {
      final CanonicalOrderedBlockItem item = normalizedItems[index];
      final int expectedOrder = index + 1;

      if (item.approvedOrder != expectedOrder) {
        throw ArgumentError.value(
          item.approvedOrder,
          'items',
          'Canonical ordered block items must be contiguous and preserve '
              'their approved order.',
        );
      }

      if (item.sourceStartLine < sourceStartLine ||
          item.sourceEndLine > sourceEndLine) {
        throw ArgumentError.value(
          item,
          'items',
          'Canonical ordered block item source range must remain '
              'inside its block.',
        );
      }

      if (index > 0 &&
          item.sourceStartLine <= normalizedItems[index - 1].sourceEndLine) {
        throw ArgumentError.value(
          item,
          'items',
          'Canonical ordered block item source ranges must preserve '
              'their approved order without overlap.',
        );
      }
    }

    final String technicallyNormalizedHeading = normalizedHeading.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    final String approvedText = <String>[
      technicallyNormalizedHeading,
      for (final CanonicalOrderedBlockItem item in normalizedItems)
        item.text.trim().replaceAll(RegExp(r'\s+'), ' '),
    ].join('\n');

    final String approvedTextHash =
        'sha256:${sha256.convert(utf8.encode(approvedText))}';

    final String identity =
        '$normalizedDictionaryId::'
        '$normalizedCollectionId::'
        '$approvedTextHash::'
        '$normalizedStableBlockKey::'
        'order:$approvedOrder';

    return CanonicalOrderedBlockEntry._(
      identity: identity,
      dictionaryId: normalizedDictionaryId,
      collectionId: normalizedCollectionId,
      approvedTextHash: approvedTextHash,
      stableBlockKey: normalizedStableBlockKey,
      approvedOrder: approvedOrder,
      heading: normalizedHeading,
      items: List<CanonicalOrderedBlockItem>.unmodifiable(normalizedItems),
      sourceDocumentPath: normalizedSourceDocumentPath,
      sourceRevision: normalizedSourceRevision,
      sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
      sourceStartLine: sourceStartLine,
      sourceEndLine: sourceEndLine,
    );
  }

  const CanonicalOrderedBlockEntry._({
    required super.identity,
    required super.dictionaryId,
    required super.collectionId,
    required super.approvedTextHash,
    required this.stableBlockKey,
    required this.approvedOrder,
    required this.heading,
    required this.items,
    required super.sourceDocumentPath,
    required super.sourceRevision,
    required super.sourceSnapshotFingerprint,
    required super.sourceStartLine,
    required super.sourceEndLine,
  });

  final String stableBlockKey;
  final int approvedOrder;
  final String heading;
  final List<CanonicalOrderedBlockItem> items;

  @override
  List<Object?> get props => <Object?>[
    identity,
    dictionaryId,
    collectionId,
    approvedTextHash,
    stableBlockKey,
    approvedOrder,
    heading,
    items,
    sourceDocumentPath,
    sourceRevision,
    sourceSnapshotFingerprint,
    sourceStartLine,
    sourceEndLine,
  ];
}
