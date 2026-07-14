import '../../domain/value_objects/registry_entity_id.dart';
import '../../domain/value_objects/registry_relation.dart';

final class ResolveAffectedRegistryEntityIds {
  const ResolveAffectedRegistryEntityIds();

  List<RegistryEntityId> call({
    required RegistryEntityId primaryEntityId,
    required Iterable<RegistryEntityId> seedRelatedEntityIds,
    required Iterable<RegistryRelation> relations,
  }) {
    final Set<RegistryEntityId> affectedEntityIds = <RegistryEntityId>{};

    for (final RegistryEntityId entityId in seedRelatedEntityIds) {
      if (entityId != primaryEntityId) {
        affectedEntityIds.add(entityId);
      }
    }

    for (final RegistryRelation relation in relations) {
      if (relation.sourceEntityId == primaryEntityId) {
        affectedEntityIds.add(relation.targetEntityId);
      }

      if (relation.targetEntityId == primaryEntityId) {
        affectedEntityIds.add(relation.sourceEntityId);
      }
    }

    affectedEntityIds.remove(primaryEntityId);

    return List<RegistryEntityId>.unmodifiable(affectedEntityIds);
  }
}
