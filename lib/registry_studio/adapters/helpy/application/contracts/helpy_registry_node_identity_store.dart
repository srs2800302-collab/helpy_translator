import '../../../../core/domain/value_objects/registry_path.dart';
import '../../../../registry/domain/value_objects/registry_node_id.dart';

final class HelpyRegistryNodeIdentityState {
  HelpyRegistryNodeIdentityState({
    Map<RegistryPath, RegistryNodeId> localIdentitiesByPath =
        const <RegistryPath, RegistryNodeId>{},
    Set<RegistryNodeId> retiredNodeIds = const <RegistryNodeId>{},
  }) : localIdentitiesByPath = Map<RegistryPath, RegistryNodeId>.unmodifiable(
         localIdentitiesByPath,
       ),
       retiredNodeIds = Set<RegistryNodeId>.unmodifiable(retiredNodeIds);

  final Map<RegistryPath, RegistryNodeId> localIdentitiesByPath;
  final Set<RegistryNodeId> retiredNodeIds;
}

abstract interface class HelpyRegistryNodeIdentityStore {
  Future<HelpyRegistryNodeIdentityState> loadState(String sourceRevision);

  Future<void> saveState(
    String sourceRevision,
    HelpyRegistryNodeIdentityState state,
  );
}
