import '../../../core/domain/value_objects/registry_path.dart';
import '../../domain/value_objects/registry_node_id.dart';

final class RegistryRevisionState {
  factory RegistryRevisionState({
    required String projectId,
    required String projectAdapterId,
    required String sourceDocumentPath,
    required String currentRevision,
    String? previousRevision,
    String? cleanBaselineRevision,
    RegistryNodeId? selectedProblemNodeId,
    RegistryPath? selectedProblemPath,
    int? selectedProblemIndex,
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

    final bool hasSelectedProblemContext =
        selectedProblemNodeId != null ||
        selectedProblemPath != null ||
        selectedProblemIndex != null;

    if (hasSelectedProblemContext &&
        (selectedProblemNodeId == null ||
            selectedProblemPath == null ||
            selectedProblemIndex == null)) {
      throw ArgumentError(
        'Registry revision state selected problem context '
        'must be complete or absent.',
      );
    }

    if (selectedProblemIndex != null && selectedProblemIndex < 0) {
      throw RangeError.value(
        selectedProblemIndex,
        'selectedProblemIndex',
        'Registry revision state selected problem position '
            'must not be negative.',
      );
    }

    return RegistryRevisionState._(
      projectId: normalizedProjectId,
      projectAdapterId: normalizedProjectAdapterId,
      sourceDocumentPath: normalizedSourceDocumentPath,
      currentRevision: normalizedCurrentRevision,
      previousRevision: normalizedPreviousRevision,
      cleanBaselineRevision: normalizedCleanBaselineRevision,
      selectedProblemNodeId: selectedProblemNodeId,
      selectedProblemPath: selectedProblemPath,
      selectedProblemIndex: selectedProblemIndex,
    );
  }

  const RegistryRevisionState._({
    required this.projectId,
    required this.projectAdapterId,
    required this.sourceDocumentPath,
    required this.currentRevision,
    required this.previousRevision,
    required this.cleanBaselineRevision,
    required this.selectedProblemNodeId,
    required this.selectedProblemPath,
    required this.selectedProblemIndex,
  });

  final String projectId;
  final String projectAdapterId;
  final String sourceDocumentPath;
  final String currentRevision;
  final String? previousRevision;
  final String? cleanBaselineRevision;
  final RegistryNodeId? selectedProblemNodeId;
  final RegistryPath? selectedProblemPath;
  final int? selectedProblemIndex;
}

abstract interface class RegistryRevisionStateStore {
  Future<RegistryRevisionState?> loadRevisionState();

  Future<void> saveRevisionState(RegistryRevisionState state);
}
