import 'package:flutter_bloc/flutter_bloc.dart';

import '../../maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../maintenance/analysis/domain/entities/registry_snapshot_comparison.dart';
import '../../maintenance/analysis/domain/entities/registry_structural_problem.dart';
import '../application/contracts/registry_revision_state_store.dart';
import '../application/contracts/registry_snapshot_loader.dart';
import '../application/contracts/registry_snapshot_revision_loader.dart';
import '../domain/entities/registry_snapshot.dart';
import '../domain/entities/registry_structural_index.dart';

sealed class RegistryExplorerState {
  const RegistryExplorerState();
}

final class RegistryExplorerLoading extends RegistryExplorerState {
  const RegistryExplorerLoading();
}

final class RegistryExplorerLoaded extends RegistryExplorerState {
  const RegistryExplorerLoaded({
    required this.snapshot,
    required this.index,
    required this.previousSnapshot,
    required this.previousComparison,
    required this.cleanBaselineSnapshot,
    required this.cleanBaselineComparison,
    required this.selectedProblemIndex,
  });

  final RegistrySnapshot snapshot;
  final RegistryStructuralIndex index;
  final RegistrySnapshot? previousSnapshot;
  final RegistrySnapshotComparison? previousComparison;
  final RegistrySnapshot? cleanBaselineSnapshot;
  final RegistrySnapshotComparison? cleanBaselineComparison;
  final int? selectedProblemIndex;

  RegistrySnapshotComparison? get problemComparison =>
      cleanBaselineComparison ?? previousComparison;

  List<RegistryStructuralProblem> get problems =>
      problemComparison?.problems ?? const <RegistryStructuralProblem>[];

  RegistryStructuralProblem? get selectedProblem {
    final int? index = selectedProblemIndex;

    if (index == null || index < 0 || index >= problems.length) {
      return null;
    }

    return problems[index];
  }
}

final class RegistryExplorerFailure extends RegistryExplorerState {
  const RegistryExplorerFailure(this.message);

  final String message;
}

final class RegistryExplorerCubit extends Cubit<RegistryExplorerState> {
  RegistryExplorerCubit({
    required this.snapshotLoader,
    required this.snapshotRevisionLoader,
    required this.revisionStateStore,
    required this.snapshotComparator,
  }) : super(const RegistryExplorerLoading());

  final RegistrySnapshotLoader snapshotLoader;
  final RegistrySnapshotRevisionLoader snapshotRevisionLoader;
  final RegistryRevisionStateStore revisionStateStore;
  final RegistrySnapshotComparator snapshotComparator;

  bool _isLoading = false;
  bool _retryRefresh = false;
  RegistrySnapshot? _currentSnapshot;
  RegistrySnapshot? _previousSnapshot;
  RegistrySnapshot? _cleanBaselineSnapshot;

  Future<void> restore() async {
    if (_isLoading) {
      return;
    }

    _retryRefresh = false;
    _isLoading = true;
    emit(const RegistryExplorerLoading());

    try {
      final RegistryRevisionState? persistedState = await revisionStateStore
          .loadRevisionState();

      late final RegistrySnapshot snapshot;
      RegistrySnapshot? previousSnapshot;
      RegistrySnapshot? cleanBaselineSnapshot;

      if (persistedState == null) {
        snapshot = await snapshotLoader.loadSnapshot();
      } else {
        snapshot = await snapshotRevisionLoader.loadSnapshotAtRevision(
          persistedState.currentRevision,
        );

        if (snapshot.projectId != persistedState.projectId ||
            snapshot.projectAdapterId != persistedState.projectAdapterId ||
            snapshot.sourceDocumentPath != persistedState.sourceDocumentPath ||
            snapshot.sourceRevision != persistedState.currentRevision) {
          throw StateError(
            'Restored current Registry snapshot does not match '
            'the persisted revision coordinates.',
          );
        }

        final String? previousRevision = persistedState.previousRevision;

        if (previousRevision != null) {
          previousSnapshot = await snapshotRevisionLoader
              .loadSnapshotAtRevision(previousRevision);

          if (previousSnapshot.projectId != persistedState.projectId ||
              previousSnapshot.projectAdapterId !=
                  persistedState.projectAdapterId ||
              previousSnapshot.sourceDocumentPath !=
                  persistedState.sourceDocumentPath ||
              previousSnapshot.sourceRevision != previousRevision) {
            throw StateError(
              'Restored previous Registry snapshot does not match '
              'the persisted revision coordinates.',
            );
          }
        }

        final String? cleanBaselineRevision =
            persistedState.cleanBaselineRevision;

        if (cleanBaselineRevision != null) {
          if (cleanBaselineRevision == snapshot.sourceRevision) {
            cleanBaselineSnapshot = snapshot;
          } else if (previousSnapshot != null &&
              cleanBaselineRevision == previousSnapshot.sourceRevision) {
            cleanBaselineSnapshot = previousSnapshot;
          } else {
            cleanBaselineSnapshot = await snapshotRevisionLoader
                .loadSnapshotAtRevision(cleanBaselineRevision);
          }

          if (cleanBaselineSnapshot.projectId != persistedState.projectId ||
              cleanBaselineSnapshot.projectAdapterId !=
                  persistedState.projectAdapterId ||
              cleanBaselineSnapshot.sourceDocumentPath !=
                  persistedState.sourceDocumentPath ||
              cleanBaselineSnapshot.sourceRevision != cleanBaselineRevision) {
            throw StateError(
              'Restored clean baseline Registry snapshot '
              'does not match the persisted revision coordinates.',
            );
          }
        }
      }

      final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

      final RegistrySnapshotComparison? previousComparison =
          previousSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(previousSnapshot),
              currentIndex: index,
            );

      final RegistrySnapshotComparison? cleanBaselineComparison =
          cleanBaselineSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(cleanBaselineSnapshot),
              currentIndex: index,
            );

      if (persistedState == null) {
        await revisionStateStore.saveRevisionState(
          RegistryRevisionState(
            projectId: snapshot.projectId,
            projectAdapterId: snapshot.projectAdapterId,
            sourceDocumentPath: snapshot.sourceDocumentPath,
            currentRevision: snapshot.sourceRevision,
            previousRevision: null,
            cleanBaselineRevision: null,
          ),
        );
      }

      _currentSnapshot = snapshot;
      _previousSnapshot = previousSnapshot;
      _cleanBaselineSnapshot = cleanBaselineSnapshot;

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: snapshot,
            index: index,
            previousSnapshot: previousSnapshot,
            previousComparison: previousComparison,
            cleanBaselineSnapshot: cleanBaselineSnapshot,
            cleanBaselineComparison: cleanBaselineComparison,
            selectedProblemIndex: null,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        final String message = error.toString().trim();

        emit(
          RegistryExplorerFailure(
            message.isEmpty ? 'Неизвестная ошибка загрузки Registry.' : message,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    if (_isLoading) {
      return;
    }

    _retryRefresh = true;
    _isLoading = true;
    emit(const RegistryExplorerLoading());

    try {
      final RegistrySnapshot snapshot = await snapshotLoader.loadSnapshot();

      final RegistrySnapshot? currentSnapshot = _currentSnapshot;
      RegistrySnapshot? previousSnapshot = _previousSnapshot;

      if (currentSnapshot != null) {
        if (snapshot.projectId != currentSnapshot.projectId ||
            snapshot.projectAdapterId != currentSnapshot.projectAdapterId ||
            snapshot.sourceDocumentPath != currentSnapshot.sourceDocumentPath) {
          throw StateError(
            'Refreshed Registry snapshot does not match '
            'the current Registry coordinates.',
          );
        }

        if (snapshot.sourceRevision != currentSnapshot.sourceRevision) {
          previousSnapshot = currentSnapshot;
        }
      }

      final RegistrySnapshot? cleanBaselineSnapshot = _cleanBaselineSnapshot;

      final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

      final RegistrySnapshotComparison? previousComparison =
          previousSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(previousSnapshot),
              currentIndex: index,
            );

      final RegistrySnapshotComparison? cleanBaselineComparison =
          cleanBaselineSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(cleanBaselineSnapshot),
              currentIndex: index,
            );

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: snapshot.projectId,
          projectAdapterId: snapshot.projectAdapterId,
          sourceDocumentPath: snapshot.sourceDocumentPath,
          currentRevision: snapshot.sourceRevision,
          previousRevision: previousSnapshot?.sourceRevision,
          cleanBaselineRevision: cleanBaselineSnapshot?.sourceRevision,
        ),
      );

      _currentSnapshot = snapshot;
      _previousSnapshot = previousSnapshot;
      _retryRefresh = false;

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: snapshot,
            index: index,
            previousSnapshot: previousSnapshot,
            previousComparison: previousComparison,
            cleanBaselineSnapshot: cleanBaselineSnapshot,
            cleanBaselineComparison: cleanBaselineComparison,
            selectedProblemIndex: null,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        final String message = error.toString().trim();

        emit(
          RegistryExplorerFailure(
            message.isEmpty ? 'Неизвестная ошибка загрузки Registry.' : message,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> confirmCurrentAsCleanBaseline() async {
    if (_isLoading) {
      return;
    }

    final RegistrySnapshot? currentSnapshot = _currentSnapshot;

    if (currentSnapshot == null) {
      throw StateError('Current Registry snapshot is unavailable.');
    }

    if (_cleanBaselineSnapshot?.sourceRevision ==
        currentSnapshot.sourceRevision) {
      return;
    }

    _isLoading = true;

    try {
      final RegistrySnapshot? previousSnapshot = _previousSnapshot;

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: currentSnapshot.projectId,
          projectAdapterId: currentSnapshot.projectAdapterId,
          sourceDocumentPath: currentSnapshot.sourceDocumentPath,
          currentRevision: currentSnapshot.sourceRevision,
          previousRevision: previousSnapshot?.sourceRevision,
          cleanBaselineRevision: currentSnapshot.sourceRevision,
        ),
      );

      final RegistryStructuralIndex index = RegistryStructuralIndex(
        currentSnapshot,
      );

      final RegistrySnapshotComparison? previousComparison =
          previousSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(previousSnapshot),
              currentIndex: index,
            );

      final RegistrySnapshotComparison cleanBaselineComparison =
          snapshotComparator.compare(previousIndex: index, currentIndex: index);

      _cleanBaselineSnapshot = currentSnapshot;

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: currentSnapshot,
            index: index,
            previousSnapshot: previousSnapshot,
            previousComparison: previousComparison,
            cleanBaselineSnapshot: currentSnapshot,
            cleanBaselineComparison: cleanBaselineComparison,
            selectedProblemIndex: null,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  void selectProblem(int? index) {
    final RegistryExplorerState currentState = state;

    if (currentState is! RegistryExplorerLoaded) {
      throw StateError('Registry problems are unavailable.');
    }

    if (index != null && (index < 0 || index >= currentState.problems.length)) {
      throw RangeError.index(index, currentState.problems, 'index');
    }

    emit(
      RegistryExplorerLoaded(
        snapshot: currentState.snapshot,
        index: currentState.index,
        previousSnapshot: currentState.previousSnapshot,
        previousComparison: currentState.previousComparison,
        cleanBaselineSnapshot: currentState.cleanBaselineSnapshot,
        cleanBaselineComparison: currentState.cleanBaselineComparison,
        selectedProblemIndex: index,
      ),
    );
  }

  Future<void> retry() {
    if (_retryRefresh) {
      return refresh();
    }

    return restore();
  }
}
