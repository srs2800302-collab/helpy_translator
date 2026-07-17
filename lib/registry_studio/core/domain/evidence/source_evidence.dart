import 'package:equatable/equatable.dart';

final class SourceEvidence extends Equatable {
  factory SourceEvidence({
    required String sourceDocumentPath,
    required String sourceSnapshotFingerprint,
    required Iterable<String> headingPath,
    required int startLine,
    required int endLine,
  }) {
    final String normalizedDocumentPath = sourceDocumentPath.trim();
    final String normalizedFingerprint = sourceSnapshotFingerprint.trim();
    final List<String> normalizedHeadingPath = headingPath
        .map((String segment) => segment.trim())
        .toList(growable: false);

    if (normalizedDocumentPath.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentPath,
        'sourceDocumentPath',
        'Source document path must not be empty.',
      );
    }

    if (normalizedFingerprint.isEmpty) {
      throw ArgumentError.value(
        sourceSnapshotFingerprint,
        'sourceSnapshotFingerprint',
        'Source snapshot fingerprint must not be empty.',
      );
    }

    if (normalizedHeadingPath.isEmpty ||
        normalizedHeadingPath.any((String segment) => segment.isEmpty)) {
      throw ArgumentError.value(
        headingPath,
        'headingPath',
        'Source heading path must contain non-empty segments.',
      );
    }

    if (startLine <= 0 || endLine < startLine) {
      throw ArgumentError(
        'Source line range must be positive and end at or after start.',
      );
    }

    return SourceEvidence._(
      sourceDocumentPath: normalizedDocumentPath,
      sourceSnapshotFingerprint: normalizedFingerprint,
      headingPath: List<String>.unmodifiable(normalizedHeadingPath),
      startLine: startLine,
      endLine: endLine,
    );
  }

  const SourceEvidence._({
    required this.sourceDocumentPath,
    required this.sourceSnapshotFingerprint,
    required this.headingPath,
    required this.startLine,
    required this.endLine,
  });

  final String sourceDocumentPath;
  final String sourceSnapshotFingerprint;
  final List<String> headingPath;
  final int startLine;
  final int endLine;

  @override
  List<Object> get props => <Object>[
    sourceDocumentPath,
    sourceSnapshotFingerprint,
    headingPath,
    startLine,
    endLine,
  ];
}
