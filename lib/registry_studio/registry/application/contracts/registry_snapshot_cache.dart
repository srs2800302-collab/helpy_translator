import '../../domain/entities/registry_snapshot.dart';

abstract interface class RegistrySnapshotCache {
  Future<RegistrySnapshot?> loadSnapshot(String sourceRevision);

  Future<void> saveSnapshot(RegistrySnapshot snapshot);
}
