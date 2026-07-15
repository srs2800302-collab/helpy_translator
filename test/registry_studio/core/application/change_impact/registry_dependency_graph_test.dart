import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/change_impact/registry_dependency_graph.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

void main() {
  group('RegistryDependencyGraph', () {
    test('preserves direct transitive paths and relation evidence', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId directId = RegistryEntityId('direct');
      final RegistryEntityId transitiveId = RegistryEntityId('transitive');
      final RegistryRelation directEdge = RegistryRelation(
        sourceEntityId: primaryId,
        targetEntityId: directId,
        meaning: RegistryRelationMeaning('references'),
      );
      final RegistryRelation transitiveEdge = RegistryRelation(
        sourceEntityId: directId,
        targetEntityId: transitiveId,
        meaning: RegistryRelationMeaning('depends_on'),
      );

      final RegistryDependencyGraph graph = RegistryDependencyGraph(
        primaryEntityId: primaryId,
        dependencyEdges: <RegistryRelation>[directEdge, transitiveEdge],
        directDependencyIds: <RegistryEntityId>[directId],
        transitiveDependencyIds: <RegistryEntityId>[transitiveId],
        dependencyPaths: <List<RegistryEntityId>>[
          <RegistryEntityId>[primaryId, directId],
          <RegistryEntityId>[primaryId, directId, transitiveId],
        ],
      );

      expect(graph.primaryEntityId, primaryId);
      expect(graph.dependencyEdges, <RegistryRelation>[
        directEdge,
        transitiveEdge,
      ]);
      expect(graph.directDependencyIds, <RegistryEntityId>[directId]);
      expect(graph.transitiveDependencyIds, <RegistryEntityId>[transitiveId]);
      expect(graph.affectedEntityIds, <RegistryEntityId>[
        directId,
        transitiveId,
      ]);
      expect(graph.pathTo(transitiveId), <RegistryEntityId>[
        primaryId,
        directId,
        transitiveId,
      ]);
    });

    test('rejects overlapping direct and transitive dependency ids', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId dependencyId = RegistryEntityId('dependency');

      expect(
        () => RegistryDependencyGraph(
          primaryEntityId: primaryId,
          dependencyEdges: const <RegistryRelation>[],
          directDependencyIds: <RegistryEntityId>[dependencyId],
          transitiveDependencyIds: <RegistryEntityId>[dependencyId],
          dependencyPaths: <List<RegistryEntityId>>[
            <RegistryEntityId>[primaryId, dependencyId],
            <RegistryEntityId>[primaryId, dependencyId, dependencyId],
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects direct dependency with a transitive path', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId intermediateId = RegistryEntityId('intermediate');
      final RegistryEntityId directId = RegistryEntityId('direct');

      expect(
        () => RegistryDependencyGraph(
          primaryEntityId: primaryId,
          dependencyEdges: const <RegistryRelation>[],
          directDependencyIds: <RegistryEntityId>[directId],
          transitiveDependencyIds: const <RegistryEntityId>[],
          dependencyPaths: <List<RegistryEntityId>>[
            <RegistryEntityId>[primaryId, intermediateId, directId],
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects transitive dependency without a transitive path', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId transitiveId = RegistryEntityId('transitive');

      expect(
        () => RegistryDependencyGraph(
          primaryEntityId: primaryId,
          dependencyEdges: const <RegistryRelation>[],
          directDependencyIds: const <RegistryEntityId>[],
          transitiveDependencyIds: <RegistryEntityId>[transitiveId],
          dependencyPaths: <List<RegistryEntityId>>[
            <RegistryEntityId>[primaryId, transitiveId],
          ],
        ),
        throwsArgumentError,
      );
    });

    test('keeps graph collections and nested paths immutable', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId directId = RegistryEntityId('direct');

      final RegistryDependencyGraph graph = RegistryDependencyGraph(
        primaryEntityId: primaryId,
        dependencyEdges: const <RegistryRelation>[],
        directDependencyIds: <RegistryEntityId>[directId],
        transitiveDependencyIds: const <RegistryEntityId>[],
        dependencyPaths: <List<RegistryEntityId>>[
          <RegistryEntityId>[primaryId, directId],
        ],
      );

      expect(
        () => graph.directDependencyIds.add(RegistryEntityId('other')),
        throwsUnsupportedError,
      );
      expect(
        () => graph.affectedEntityIds.add(RegistryEntityId('other')),
        throwsUnsupportedError,
      );
      expect(
        () => graph.pathTo(directId).add(RegistryEntityId('other')),
        throwsUnsupportedError,
      );
      expect(
        () => graph.pathTo(RegistryEntityId('missing')),
        throwsArgumentError,
      );
    });
  });
}
