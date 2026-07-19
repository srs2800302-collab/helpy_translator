import 'package:equatable/equatable.dart';

final class RegistryAnalysisHistoryEntry extends Equatable {
  factory RegistryAnalysisHistoryEntry({
    required DateTime loadedAt,
    required String projectId,
    required String projectAdapterId,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
    String? previousRevision,
    String? cleanBaselineRevision,
    int previousAddedCount = 0,
    int previousRemovedCount = 0,
    int previousChangedCount = 0,
    int cleanBaselineAddedCount = 0,
    int cleanBaselineRemovedCount = 0,
    int cleanBaselineChangedCount = 0,
    int problemCount = 0,
  }) {
    final String normalizedProjectId = projectId.trim();
    final String normalizedProjectAdapterId = projectAdapterId.trim();
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedSourceRevision = sourceRevision.trim();
    final String normalizedSourceSnapshotFingerprint = sourceSnapshotFingerprint
        .trim();
    final String? normalizedPreviousRevision = previousRevision?.trim();
    final String? normalizedCleanBaselineRevision = cleanBaselineRevision
        ?.trim();

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError.value(
        projectId,
        'projectId',
        'Registry analysis history project identifier must not be empty.',
      );
    }

    if (normalizedProjectAdapterId.isEmpty) {
      throw ArgumentError.value(
        projectAdapterId,
        'projectAdapterId',
        'Registry analysis history adapter identifier must not be empty.',
      );
    }

    if (normalizedSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentPath,
        'sourceDocumentPath',
        'Registry analysis history source document path must not be empty.',
      );
    }

    if (normalizedSourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Registry analysis history source revision must not be empty.',
      );
    }

    if (normalizedSourceSnapshotFingerprint.isEmpty) {
      throw ArgumentError.value(
        sourceSnapshotFingerprint,
        'sourceSnapshotFingerprint',
        'Registry analysis history source fingerprint must not be empty.',
      );
    }

    if (normalizedPreviousRevision != null &&
        normalizedPreviousRevision.isEmpty) {
      throw ArgumentError.value(
        previousRevision,
        'previousRevision',
        'Registry analysis history previous revision must not be empty.',
      );
    }

    if (normalizedPreviousRevision == normalizedSourceRevision) {
      throw ArgumentError.value(
        previousRevision,
        'previousRevision',
        'Registry analysis history previous revision must differ '
            'from the source revision.',
      );
    }

    if (normalizedCleanBaselineRevision != null &&
        normalizedCleanBaselineRevision.isEmpty) {
      throw ArgumentError.value(
        cleanBaselineRevision,
        'cleanBaselineRevision',
        'Registry analysis history clean baseline revision '
            'must not be empty.',
      );
    }

    final Map<String, int> counts = <String, int>{
      'previousAddedCount': previousAddedCount,
      'previousRemovedCount': previousRemovedCount,
      'previousChangedCount': previousChangedCount,
      'cleanBaselineAddedCount': cleanBaselineAddedCount,
      'cleanBaselineRemovedCount': cleanBaselineRemovedCount,
      'cleanBaselineChangedCount': cleanBaselineChangedCount,
      'problemCount': problemCount,
    };

    for (final MapEntry<String, int> count in counts.entries) {
      if (count.value < 0) {
        throw RangeError.value(
          count.value,
          count.key,
          'Registry analysis history count must not be negative.',
        );
      }
    }

    if (normalizedPreviousRevision == null &&
        (previousAddedCount != 0 ||
            previousRemovedCount != 0 ||
            previousChangedCount != 0)) {
      throw ArgumentError(
        'Registry analysis history previous comparison counts '
        'require a previous revision.',
      );
    }

    if (normalizedCleanBaselineRevision == null &&
        (cleanBaselineAddedCount != 0 ||
            cleanBaselineRemovedCount != 0 ||
            cleanBaselineChangedCount != 0)) {
      throw ArgumentError(
        'Registry analysis history clean baseline comparison counts '
        'require a clean baseline revision.',
      );
    }

    return RegistryAnalysisHistoryEntry._(
      loadedAt: loadedAt.toUtc(),
      projectId: normalizedProjectId,
      projectAdapterId: normalizedProjectAdapterId,
      sourceDocumentPath: normalizedSourceDocumentPath,
      sourceRevision: normalizedSourceRevision,
      sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
      previousRevision: normalizedPreviousRevision,
      cleanBaselineRevision: normalizedCleanBaselineRevision,
      previousAddedCount: previousAddedCount,
      previousRemovedCount: previousRemovedCount,
      previousChangedCount: previousChangedCount,
      cleanBaselineAddedCount: cleanBaselineAddedCount,
      cleanBaselineRemovedCount: cleanBaselineRemovedCount,
      cleanBaselineChangedCount: cleanBaselineChangedCount,
      problemCount: problemCount,
    );
  }

  const RegistryAnalysisHistoryEntry._({
    required this.loadedAt,
    required this.projectId,
    required this.projectAdapterId,
    required this.sourceDocumentPath,
    required this.sourceRevision,
    required this.sourceSnapshotFingerprint,
    required this.previousRevision,
    required this.cleanBaselineRevision,
    required this.previousAddedCount,
    required this.previousRemovedCount,
    required this.previousChangedCount,
    required this.cleanBaselineAddedCount,
    required this.cleanBaselineRemovedCount,
    required this.cleanBaselineChangedCount,
    required this.problemCount,
  });

  final DateTime loadedAt;
  final String projectId;
  final String projectAdapterId;
  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
  final String? previousRevision;
  final String? cleanBaselineRevision;
  final int previousAddedCount;
  final int previousRemovedCount;
  final int previousChangedCount;
  final int cleanBaselineAddedCount;
  final int cleanBaselineRemovedCount;
  final int cleanBaselineChangedCount;
  final int problemCount;

  int get previousChangeCount =>
      previousAddedCount + previousRemovedCount + previousChangedCount;

  int get cleanBaselineChangeCount =>
      cleanBaselineAddedCount +
      cleanBaselineRemovedCount +
      cleanBaselineChangedCount;

  @override
  List<Object?> get props => <Object?>[
    loadedAt,
    projectId,
    projectAdapterId,
    sourceDocumentPath,
    sourceRevision,
    sourceSnapshotFingerprint,
    previousRevision,
    cleanBaselineRevision,
    previousAddedCount,
    previousRemovedCount,
    previousChangedCount,
    cleanBaselineAddedCount,
    cleanBaselineRemovedCount,
    cleanBaselineChangedCount,
    problemCount,
  ];
}
