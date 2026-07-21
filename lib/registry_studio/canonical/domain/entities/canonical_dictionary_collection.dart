import 'package:equatable/equatable.dart';

import 'canonical_dictionary_entry.dart';

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
