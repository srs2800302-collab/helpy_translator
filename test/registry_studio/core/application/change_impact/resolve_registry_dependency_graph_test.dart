import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/change_impact/registry_dependency_graph.dart';
import 'package:helpy_translator/registry_studio/core/application/change_impact/resolve_registry_dependency_graph.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

void main() {
  group('ResolveRegistryDependencyGraph', () {
    const ResolveRegistryDependencyGraph resolver =
        ResolveRegistryDependencyGraph();

    test('resolves direct and transitive dependencies with paths', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId directId = RegistryEntityId('direct');
      final RegistryEntityId transitiveId = RegistryEntityId('transitive');
      final RegistryEntityId unrelatedId = RegistryEntityId('unrelated');

      final RegistryRelation firstEdge = RegistryRelation(
        sourceEntityId: primaryId,
        targetEntityId: directId,
        meaning: RegistryRelationMeaning('references'),
      );
      final RegistryRelation secondEdge = RegistryRelation(
        sourceEntityId: transitiveId,
        targetEntityId: directId,
        meaning: RegistryRelationMeaning('depends_on'),
      );
      final RegistryRelation unrelatedEdge = RegistryRelation(
        sourceEntityId: unrelatedId,
        targetEntityId: RegistryEntityId('outside'),
        meaning: RegistryRelationMeaning('supports'),
      );

      final RegistryDependencyGraph graph = resolver(
        primaryEntityId: primaryId,
        seedRelatedEntityIds: const <RegistryEntityId>[],
        relations: <RegistryRelation>[firstEdge, secondEdge, unrelatedEdge],
      );

      expect(graph.directDependencyIds, <RegistryEntityId>[directId]);
      expect(graph.transitiveDependencyIds, <RegistryEntityId>[transitiveId]);
      expect(graph.dependencyEdges, <RegistryRelation>[firstEdge, secondEdge]);
      expect(graph.pathTo(directId), <RegistryEntityId>[primaryId, directId]);
      expect(graph.pathTo(transitiveId), <RegistryEntityId>[
        primaryId,
        directId,
        transitiveId,
      ]);
    });

    test('treats explicit seeds as direct and traverses their relations', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId seedId = RegistryEntityId('seed');
      final RegistryEntityId transitiveId = RegistryEntityId('transitive');

      final RegistryDependencyGraph graph = resolver(
        primaryEntityId: primaryId,
        seedRelatedEntityIds: <RegistryEntityId>[seedId, seedId, primaryId],
        relations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: seedId,
            targetEntityId: transitiveId,
            meaning: RegistryRelationMeaning('references'),
          ),
        ],
      );

      expect(graph.directDependencyIds, <RegistryEntityId>[seedId]);
      expect(graph.transitiveDependencyIds, <RegistryEntityId>[transitiveId]);
      expect(graph.pathTo(seedId), <RegistryEntityId>[primaryId, seedId]);
      expect(graph.pathTo(transitiveId), <RegistryEntityId>[
        primaryId,
        seedId,
        transitiveId,
      ]);
    });

    test('terminates cycles and preserves each affected identity once', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId firstId = RegistryEntityId('first');
      final RegistryEntityId secondId = RegistryEntityId('second');

      final RegistryDependencyGraph graph = resolver(
        primaryEntityId: primaryId,
        seedRelatedEntityIds: const <RegistryEntityId>[],
        relations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primaryId,
            targetEntityId: firstId,
            meaning: RegistryRelationMeaning('references'),
          ),
          RegistryRelation(
            sourceEntityId: firstId,
            targetEntityId: secondId,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
          RegistryRelation(
            sourceEntityId: secondId,
            targetEntityId: primaryId,
            meaning: RegistryRelationMeaning('supports'),
          ),
        ],
      );

      expect(graph.directDependencyIds, <RegistryEntityId>[firstId, secondId]);
      expect(graph.transitiveDependencyIds, isEmpty);
      expect(graph.affectedEntityIds.toSet(), <RegistryEntityId>{
        firstId,
        secondId,
      });
      expect(graph.dependencyEdges, hasLength(3));
    });

    test('returns an empty graph when no dependency is reachable', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');

      final RegistryDependencyGraph graph = resolver(
        primaryEntityId: primaryId,
        seedRelatedEntityIds: const <RegistryEntityId>[],
        relations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: RegistryEntityId('outside-a'),
            targetEntityId: RegistryEntityId('outside-b'),
            meaning: RegistryRelationMeaning('references'),
          ),
        ],
      );

      expect(graph.directDependencyIds, isEmpty);
      expect(graph.transitiveDependencyIds, isEmpty);
      expect(graph.affectedEntityIds, isEmpty);
      expect(graph.dependencyEdges, isEmpty);
      expect(graph.dependencyPaths, isEmpty);
    });
  });
}
