import 'package:equatable/equatable.dart';

import 'canonical_dictionary_entry.dart';
import 'canonical_ordered_block_entry.dart';

final class CanonicalDictionaryCollection extends Equatable {
  factory CanonicalDictionaryCollection({
    required String id,
    required String entryType,
    required String status,
    required String content,
    required int startLine,
    required int endLine,
    Iterable<CanonicalDictionaryEntry> entries =
        const <CanonicalDictionaryEntry>[],
  }) {
    final String normalizedId = id.trim();
    final String normalizedEntryType = entryType.trim();
    final String normalizedStatus = status.trim();
    final String normalizedContent = content.trim();

    final List<CanonicalDictionaryEntry> normalizedEntries = entries.toList(
      growable: false,
    );

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'Canonical Dictionary collection identifier must not be empty.',
      );
    }

    if (normalizedEntryType.isEmpty) {
      throw ArgumentError.value(
        entryType,
        'entryType',
        'Canonical Dictionary collection entry type must not be empty.',
      );
    }

    if (normalizedStatus.isEmpty) {
      throw ArgumentError.value(
        status,
        'status',
        'Canonical Dictionary collection status must not be empty.',
      );
    }

    if (normalizedContent.isEmpty) {
      throw ArgumentError.value(
        content,
        'content',
        'Canonical Dictionary collection content must not be empty.',
      );
    }

    if (startLine < 1) {
      throw ArgumentError.value(
        startLine,
        'startLine',
        'Canonical Dictionary collection start line must be positive.',
      );
    }

    if (endLine < startLine) {
      throw ArgumentError.value(
        endLine,
        'endLine',
        'Canonical Dictionary collection end line must not precede '
            'its start line.',
      );
    }

    final Set<String> entryIdentities = <String>{};

    for (final CanonicalDictionaryEntry entry in normalizedEntries) {
      if (entry.collectionId != normalizedId) {
        throw ArgumentError.value(
          entry,
          'entries',
          'Canonical Dictionary entry must belong to its collection.',
        );
      }

      if (entry.sourceStartLine < startLine || entry.sourceEndLine > endLine) {
        throw ArgumentError.value(
          entry,
          'entries',
          'Canonical Dictionary entry source range must remain '
              'inside its collection.',
        );
      }

      if (!entryIdentities.add(entry.identity)) {
        throw ArgumentError.value(
          entry.identity,
          'entries',
          'Canonical Dictionary entry identities must be unique '
              'inside one collection.',
        );
      }
    }

    final bool isOrderedCollection =
        normalizedEntryType == 'ordered_block' ||
        normalizedEntryType == 'ordered_rule_block';

    if (isOrderedCollection && normalizedEntries.isEmpty) {
      throw ArgumentError.value(
        entries,
        'entries',
        'Canonical ordered collection must contain at least '
            'one typed ordered block entry.',
      );
    }

    final Set<String> orderedStableBlockKeys = <String>{};

    for (int index = 0; index < normalizedEntries.length; index += 1) {
      final CanonicalDictionaryEntry entry = normalizedEntries[index];

      if (!isOrderedCollection) {
        if (entry is CanonicalOrderedBlockEntry) {
          throw ArgumentError.value(
            entry,
            'entries',
            'Canonical ordered block entry must belong to an '
                'ordered collection.',
          );
        }

        continue;
      }

      if (entry is! CanonicalOrderedBlockEntry) {
        throw ArgumentError.value(
          entry,
          'entries',
          'Canonical ordered collection must contain only '
              'typed ordered block entries.',
        );
      }

      if (!orderedStableBlockKeys.add(entry.stableBlockKey)) {
        throw ArgumentError.value(
          entry.stableBlockKey,
          'entries',
          'Canonical ordered collection stable block keys '
              'must be unique.',
        );
      }

      final int expectedOrder = index + 1;

      if (entry.approvedOrder != expectedOrder) {
        throw ArgumentError.value(
          entry.approvedOrder,
          'entries',
          'Canonical ordered collection entries must be contiguous '
              'and preserve their approved order.',
        );
      }
    }

    return CanonicalDictionaryCollection._(
      id: normalizedId,
      entryType: normalizedEntryType,
      status: normalizedStatus,
      content: normalizedContent,
      startLine: startLine,
      endLine: endLine,
      entries: List<CanonicalDictionaryEntry>.unmodifiable(normalizedEntries),
    );
  }

  const CanonicalDictionaryCollection._({
    required this.id,
    required this.entryType,
    required this.status,
    required this.content,
    required this.startLine,
    required this.endLine,
    required this.entries,
  });

  final String id;
  final String entryType;
  final String status;
  final String content;
  final int startLine;
  final int endLine;
  final List<CanonicalDictionaryEntry> entries;

  @override
  List<Object?> get props => <Object?>[
    id,
    entryType,
    status,
    content,
    startLine,
    endLine,
    entries,
  ];
}
