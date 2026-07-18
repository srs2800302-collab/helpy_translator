import 'package:flutter_bloc/flutter_bloc.dart';

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
  });

  final RegistrySnapshot snapshot;
  final RegistryStructuralIndex index;
  final RegistrySnapshot? previousSnapshot;
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
  }) : super(const RegistryExplorerLoading());

  final RegistrySnapshotLoader snapshotLoader;
  final RegistrySnapshotRevisionLoader snapshotRevisionLoader;
  final RegistryRevisionStateStore revisionStateStore;

  bool _isLoading = false;
  bool _retryRefresh = false;
  RegistrySnapshot? _currentSnapshot;
  RegistrySnapshot? _previousSnapshot;

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
      }

      final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

      if (persistedState == null) {
        await revisionStateStore.saveRevisionState(
          RegistryRevisionState(
            projectId: snapshot.projectId,
            projectAdapterId: snapshot.projectAdapterId,
            sourceDocumentPath: snapshot.sourceDocumentPath,
            currentRevision: snapshot.sourceRevision,
            previousRevision: null,
          ),
        );
      }

      _currentSnapshot = snapshot;
      _previousSnapshot = previousSnapshot;

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: snapshot,
            index: index,
            previousSnapshot: previousSnapshot,
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

      final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: snapshot.projectId,
          projectAdapterId: snapshot.projectAdapterId,
          sourceDocumentPath: snapshot.sourceDocumentPath,
          currentRevision: snapshot.sourceRevision,
          previousRevision: previousSnapshot?.sourceRevision,
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

  Future<void> retry() {
    if (_retryRefresh) {
      return refresh();
    }

    return restore();
  }
}
