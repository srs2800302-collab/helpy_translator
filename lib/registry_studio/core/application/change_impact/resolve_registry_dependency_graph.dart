import '../../domain/value_objects/registry_entity_id.dart';
import '../../domain/value_objects/registry_relation.dart';
import 'registry_dependency_graph.dart';

final class ResolveRegistryDependencyGraph {
  const ResolveRegistryDependencyGraph();

  RegistryDependencyGraph call({
    required RegistryEntityId primaryEntityId,
    required Iterable<RegistryEntityId> seedRelatedEntityIds,
    required Iterable<RegistryRelation> relations,
  }) {
    final List<RegistryRelation> normalizedRelations = relations.toList(
      growable: false,
    );
    final List<RegistryEntityId> directDependencyIds = <RegistryEntityId>[];
    final List<RegistryEntityId> transitiveDependencyIds = <RegistryEntityId>[];
    final Map<RegistryEntityId, List<RegistryEntityId>> paths =
        <RegistryEntityId, List<RegistryEntityId>>{
          primaryEntityId: <RegistryEntityId>[primaryEntityId],
        };
    final List<RegistryEntityId> traversalQueue = <RegistryEntityId>[
      primaryEntityId,
    ];

    void addDirect(RegistryEntityId entityId) {
      if (entityId == primaryEntityId || paths.containsKey(entityId)) {
        return;
      }

      directDependencyIds.add(entityId);
      paths[entityId] = <RegistryEntityId>[primaryEntityId, entityId];
      traversalQueue.add(entityId);
    }

    for (final RegistryEntityId seedId in seedRelatedEntityIds) {
      addDirect(seedId);
    }

    for (final RegistryRelation relation in normalizedRelations) {
      final RegistryEntityId? adjacentId = _adjacentEntityId(
        relation: relation,
        entityId: primaryEntityId,
      );

      if (adjacentId != null) {
        addDirect(adjacentId);
      }
    }

    int queueIndex = 1;

    while (queueIndex < traversalQueue.length) {
      final RegistryEntityId currentEntityId = traversalQueue[queueIndex];
      queueIndex += 1;

      for (final RegistryRelation relation in normalizedRelations) {
        final RegistryEntityId? adjacentId = _adjacentEntityId(
          relation: relation,
          entityId: currentEntityId,
        );

        if (adjacentId == null ||
            adjacentId == primaryEntityId ||
            paths.containsKey(adjacentId)) {
          continue;
        }

        paths[adjacentId] = <RegistryEntityId>[
          ...paths[currentEntityId]!,
          adjacentId,
        ];
        transitiveDependencyIds.add(adjacentId);
        traversalQueue.add(adjacentId);
      }
    }

    final List<RegistryEntityId> affectedEntityIds = <RegistryEntityId>[
      ...directDependencyIds,
      ...transitiveDependencyIds,
    ];
    final Set<RegistryEntityId> graphEntityIds = <RegistryEntityId>{
      primaryEntityId,
      ...affectedEntityIds,
    };
    final List<RegistryRelation> dependencyEdges = <RegistryRelation>[];
    final Set<RegistryRelation> seenEdges = <RegistryRelation>{};

    for (final RegistryRelation relation in normalizedRelations) {
      if (graphEntityIds.contains(relation.sourceEntityId) &&
          graphEntityIds.contains(relation.targetEntityId) &&
          seenEdges.add(relation)) {
        dependencyEdges.add(relation);
      }
    }

    return RegistryDependencyGraph(
      primaryEntityId: primaryEntityId,
      dependencyEdges: dependencyEdges,
      directDependencyIds: directDependencyIds,
      transitiveDependencyIds: transitiveDependencyIds,
      dependencyPaths: affectedEntityIds.map(
        (RegistryEntityId entityId) => paths[entityId]!,
      ),
    );
  }

  static RegistryEntityId? _adjacentEntityId({
    required RegistryRelation relation,
    required RegistryEntityId entityId,
  }) {
    if (relation.sourceEntityId == entityId) {
      return relation.targetEntityId;
    }

    if (relation.targetEntityId == entityId) {
      return relation.sourceEntityId;
    }

    return null;
  }
}
