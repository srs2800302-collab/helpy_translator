import '../../../../core/domain/value_objects/registry_path.dart';
import '../../../../registry/domain/value_objects/registry_node_id.dart';

abstract interface class HelpyRegistryNodeIdentityStore {
  Future<Map<RegistryPath, RegistryNodeId>> loadIdentities(
    String sourceRevision,
  );

  Future<void> saveIdentities(
    String sourceRevision,
    Map<RegistryPath, RegistryNodeId> identities,
  );
}
