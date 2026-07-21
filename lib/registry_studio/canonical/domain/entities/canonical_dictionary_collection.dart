import 'package:equatable/equatable.dart';

final class CanonicalDictionaryCollection extends Equatable {
  factory CanonicalDictionaryCollection({
    required String id,
    required String entryType,
    required String status,
    required String content,
    required int startLine,
    required int endLine,
  }) {
    final String normalizedId = id.trim();
    final String normalizedEntryType = entryType.trim();
    final String normalizedStatus = status.trim();
    final String normalizedContent = content.trim();

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
        'Canonical Dictionary collection end line must not precede its '
            'start line.',
      );
    }

    return CanonicalDictionaryCollection._(
      id: normalizedId,
      entryType: normalizedEntryType,
      status: normalizedStatus,
      content: normalizedContent,
      startLine: startLine,
      endLine: endLine,
    );
  }

  const CanonicalDictionaryCollection._({
    required this.id,
    required this.entryType,
    required this.status,
    required this.content,
    required this.startLine,
    required this.endLine,
  });

  final String id;
  final String entryType;
  final String status;
  final String content;
  final int startLine;
  final int endLine;

  @override
  List<Object?> get props => <Object?>[
    id,
    entryType,
    status,
    content,
    startLine,
    endLine,
  ];
}
