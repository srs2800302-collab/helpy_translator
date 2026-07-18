import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/contracts/registry_snapshot_loader.dart';
import '../domain/entities/registry_snapshot.dart';
import '../domain/entities/registry_structural_index.dart';

sealed class RegistryExplorerState {
  const RegistryExplorerState();
}

final class RegistryExplorerLoading extends RegistryExplorerState {
  const RegistryExplorerLoading();
}

final class RegistryExplorerLoaded extends RegistryExplorerState {
  const RegistryExplorerLoaded({required this.snapshot, required this.index});

  final RegistrySnapshot snapshot;
  final RegistryStructuralIndex index;
}

final class RegistryExplorerFailure extends RegistryExplorerState {
  const RegistryExplorerFailure(this.message);

  final String message;
}

final class RegistryExplorerCubit extends Cubit<RegistryExplorerState> {
  RegistryExplorerCubit({required this.snapshotLoader})
    : super(const RegistryExplorerLoading());

  final RegistrySnapshotLoader snapshotLoader;

  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    emit(const RegistryExplorerLoading());

    try {
      final RegistrySnapshot snapshot = await snapshotLoader.loadSnapshot();

      final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

      if (!isClosed) {
        emit(RegistryExplorerLoaded(snapshot: snapshot, index: index));
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
