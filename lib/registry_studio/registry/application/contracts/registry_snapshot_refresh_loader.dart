import '../../domain/entities/registry_snapshot.dart';

abstract interface class RegistrySnapshotRefreshLoader {
  Future<RegistrySnapshot> loadSnapshotAfterRevision(String previousRevision);
}
