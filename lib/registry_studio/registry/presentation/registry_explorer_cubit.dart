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
  bool _restorationCompleted = false;
  RegistrySnapshot? _currentSnapshot;
  RegistrySnapshot? _previousSnapshot;

  Future<void> load() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    emit(const RegistryExplorerLoading());

    try {
      final RegistrySnapshot snapshot = await snapshotLoader.loadSnapshot();

      RegistrySnapshot? previousSnapshot = _previousSnapshot;

      if (!_restorationCompleted) {
        final RegistryRevisionState? persistedState = await revisionStateStore
            .loadRevisionState();

        final bool belongsToLoadedRegistry =
            persistedState != null &&
            persistedState.projectId == snapshot.projectId &&
            persistedState.projectAdapterId == snapshot.projectAdapterId &&
            persistedState.sourceDocumentPath == snapshot.sourceDocumentPath;

        if (belongsToLoadedRegistry) {
          final String? revisionToRestore =
              persistedState.currentRevision == snapshot.sourceRevision
              ? persistedState.previousRevision
              : persistedState.currentRevision;

          if (revisionToRestore != null) {
            final RegistrySnapshot restoredSnapshot =
                await snapshotRevisionLoader.loadSnapshotAtRevision(
                  revisionToRestore,
                );

            if (restoredSnapshot.projectId != snapshot.projectId ||
                restoredSnapshot.projectAdapterId !=
                    snapshot.projectAdapterId ||
                restoredSnapshot.sourceDocumentPath !=
                    snapshot.sourceDocumentPath ||
                restoredSnapshot.sourceRevision != revisionToRestore) {
              throw StateError(
                'Restored Registry snapshot does not match '
                'the persisted revision coordinates.',
              );
            }

            previousSnapshot = restoredSnapshot;
          } else {
            previousSnapshot = null;
          }
        } else {
          previousSnapshot = null;
        }
      } else {
        final RegistrySnapshot? currentSnapshot = _currentSnapshot;

        if (currentSnapshot != null &&
            currentSnapshot.sourceRevision != snapshot.sourceRevision) {
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
      _restorationCompleted = true;

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
}
