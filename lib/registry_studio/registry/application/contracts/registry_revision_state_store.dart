final class RegistryRevisionState {
  factory RegistryRevisionState({
    required String projectId,
    required String projectAdapterId,
    required String sourceDocumentPath,
    required String currentRevision,
    String? previousRevision,
    String? cleanBaselineRevision,
  }) {
    final String normalizedProjectId = projectId.trim();
    final String normalizedProjectAdapterId = projectAdapterId.trim();
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedCurrentRevision = currentRevision.trim();
    final String? normalizedPreviousRevision = previousRevision?.trim();
    final String? normalizedCleanBaselineRevision = cleanBaselineRevision
        ?.trim();

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError.value(
        projectId,
        'projectId',
        'Registry revision state project identifier must not be empty.',
      );
    }

    if (normalizedProjectAdapterId.isEmpty) {
      throw ArgumentError.value(
        projectAdapterId,
        'projectAdapterId',
        'Registry revision state adapter identifier must not be empty.',
      );
    }

    if (normalizedSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentPath,
        'sourceDocumentPath',
        'Registry revision state document path must not be empty.',
      );
    }

    if (normalizedCurrentRevision.isEmpty) {
      throw ArgumentError.value(
        currentRevision,
        'currentRevision',
        'Registry revision state current revision must not be empty.',
      );
    }

    if (normalizedPreviousRevision != null &&
        normalizedPreviousRevision.isEmpty) {
      throw ArgumentError.value(
        previousRevision,
        'previousRevision',
        'Registry revision state previous revision must not be empty.',
      );
    }

    if (normalizedPreviousRevision == normalizedCurrentRevision) {
      throw ArgumentError.value(
        previousRevision,
        'previousRevision',
        'Registry revision state previous revision must differ '
            'from the current revision.',
      );
    }

    if (normalizedCleanBaselineRevision != null &&
        normalizedCleanBaselineRevision.isEmpty) {
      throw ArgumentError.value(
        cleanBaselineRevision,
        'cleanBaselineRevision',
        'Registry revision state clean baseline revision '
            'must not be empty.',
      );
    }

    return RegistryRevisionState._(
      projectId: normalizedProjectId,
      projectAdapterId: normalizedProjectAdapterId,
      sourceDocumentPath: normalizedSourceDocumentPath,
      currentRevision: normalizedCurrentRevision,
      previousRevision: normalizedPreviousRevision,
      cleanBaselineRevision: normalizedCleanBaselineRevision,
    );
  }

  const RegistryRevisionState._({
    required this.projectId,
    required this.projectAdapterId,
    required this.sourceDocumentPath,
    required this.currentRevision,
    required this.previousRevision,
    required this.cleanBaselineRevision,
  });

  final String projectId;
  final String projectAdapterId;
  final String sourceDocumentPath;
  final String currentRevision;
  final String? previousRevision;
  final String? cleanBaselineRevision;
}

abstract interface class RegistryRevisionStateStore {
  Future<RegistryRevisionState?> loadRevisionState();

  Future<void> saveRevisionState(RegistryRevisionState state);
}
