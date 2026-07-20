import '../../../../core/domain/value_objects/registry_path.dart';
import '../../../../registry/domain/value_objects/registry_node_id.dart';

abstract interface class HelpyRegistryNodeIdentityStore {
  Future<Map<RegistryPath, RegistryNodeId>> loadIdentities();

  Future<void> saveIdentities(Map<RegistryPath, RegistryNodeId> identities);
}
