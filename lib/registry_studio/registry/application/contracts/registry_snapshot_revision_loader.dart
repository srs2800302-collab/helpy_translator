import '../../domain/entities/registry_snapshot.dart';

abstract interface class RegistrySnapshotRevisionLoader {
  Future<RegistrySnapshot> loadSnapshotAtRevision(String sourceRevision);
}
