import '../../domain/entities/registry_snapshot.dart';

abstract interface class RegistrySnapshotLoader {
  Future<RegistrySnapshot> loadSnapshot();
}
