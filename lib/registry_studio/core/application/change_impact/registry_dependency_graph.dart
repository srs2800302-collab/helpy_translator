import 'package:equatable/equatable.dart';

import '../../domain/value_objects/registry_entity_id.dart';
import '../../domain/value_objects/registry_relation.dart';

final class RegistryDependencyGraph extends Equatable {
  factory RegistryDependencyGraph({
    required RegistryEntityId primaryEntityId,
    required Iterable<RegistryRelation> dependencyEdges,
    required Iterable<RegistryEntityId> directDependencyIds,
    required Iterable<RegistryEntityId> transitiveDependencyIds,
    required Iterable<Iterable<RegistryEntityId>> dependencyPaths,
  }) {
    final List<RegistryRelation> normalizedEdges = dependencyEdges.toList(
      growable: false,
    );
    final List<RegistryEntityId> normalizedDirectIds = directDependencyIds
        .toList(growable: false);
    final List<RegistryEntityId> normalizedTransitiveIds =
        transitiveDependencyIds.toList(growable: false);
    final List<RegistryEntityId> affectedEntityIds = <RegistryEntityId>[
      ...normalizedDirectIds,
      ...normalizedTransitiveIds,
    ];
    final List<List<RegistryEntityId>> normalizedPaths = dependencyPaths
        .map(
          (Iterable<RegistryEntityId> path) =>
              List<RegistryEntityId>.unmodifiable(path),
        )
        .toList(growable: false);

    _requireUniqueIds(
      normalizedDirectIds,
      'Direct dependency ids must be unique.',
    );
    _requireUniqueIds(
      normalizedTransitiveIds,
      'Transitive dependency ids must be unique.',
    );

    if (affectedEntityIds.contains(primaryEntityId)) {
      throw ArgumentError(
        'Dependency ids must not contain the primary registry entity.',
      );
    }

    final Set<RegistryEntityId> directIdSet = normalizedDirectIds.toSet();

    if (normalizedTransitiveIds.any(directIdSet.contains)) {
      throw ArgumentError(
        'Direct and transitive dependency ids must not overlap.',
      );
    }

    if (normalizedEdges.toSet().length != normalizedEdges.length) {
      throw ArgumentError('Dependency edges must be unique.');
    }

    final Set<RegistryEntityId> graphEntityIds = <RegistryEntityId>{
      primaryEntityId,
      ...affectedEntityIds,
    };

    for (final RegistryRelation edge in normalizedEdges) {
      if (!graphEntityIds.contains(edge.sourceEntityId) ||
          !graphEntityIds.contains(edge.targetEntityId)) {
        throw ArgumentError(
          'Dependency edge endpoints must belong to the dependency graph.',
        );
      }
    }

    if (normalizedPaths.length != affectedEntityIds.length) {
      throw ArgumentError(
        'Every affected registry entity must have one dependency path.',
      );
    }

    for (int index = 0; index < normalizedPaths.length; index += 1) {
      final List<RegistryEntityId> path = normalizedPaths[index];
      final RegistryEntityId affectedEntityId = affectedEntityIds[index];

      if (path.length < 2 ||
          path.first != primaryEntityId ||
          path.last != affectedEntityId) {
        throw ArgumentError(
          'Dependency path must start at primary and end at its affected entity.',
        );
      }

      if (path.toSet().length != path.length) {
        throw ArgumentError('Dependency path must not contain a cycle.');
      }

      final bool isDirect = index < normalizedDirectIds.length;

      if (isDirect && path.length != 2) {
        throw ArgumentError(
          'Direct dependency path must contain exactly one transition.',
        );
      }

      if (!isDirect && path.length <= 2) {
        throw ArgumentError(
          'Transitive dependency path must contain more than one transition.',
        );
      }
    }

    return RegistryDependencyGraph._(
      primaryEntityId: primaryEntityId,
      dependencyEdges: List<RegistryRelation>.unmodifiable(normalizedEdges),
      directDependencyIds: List<RegistryEntityId>.unmodifiable(
        normalizedDirectIds,
      ),
      transitiveDependencyIds: List<RegistryEntityId>.unmodifiable(
        normalizedTransitiveIds,
      ),
      affectedEntityIds: List<RegistryEntityId>.unmodifiable(affectedEntityIds),
      dependencyPaths: List<List<RegistryEntityId>>.unmodifiable(
        normalizedPaths,
      ),
    );
  }

  const RegistryDependencyGraph._({
    required this.primaryEntityId,
    required this.dependencyEdges,
    required this.directDependencyIds,
    required this.transitiveDependencyIds,
    required this.affectedEntityIds,
    required this.dependencyPaths,
  });

  final RegistryEntityId primaryEntityId;
  final List<RegistryRelation> dependencyEdges;
  final List<RegistryEntityId> directDependencyIds;
  final List<RegistryEntityId> transitiveDependencyIds;
  final List<RegistryEntityId> affectedEntityIds;
  final List<List<RegistryEntityId>> dependencyPaths;

  List<RegistryEntityId> pathTo(RegistryEntityId entityId) {
    final int index = affectedEntityIds.indexOf(entityId);

    if (index == -1) {
      throw ArgumentError.value(
        entityId,
        'entityId',
        'Registry entity is not present in the dependency graph.',
      );
    }

    return dependencyPaths[index];
  }

  @override
  List<Object?> get props => <Object?>[
    primaryEntityId,
    dependencyEdges,
    directDependencyIds,
    transitiveDependencyIds,
    affectedEntityIds,
    dependencyPaths,
  ];

  static void _requireUniqueIds(List<RegistryEntityId> ids, String message) {
    if (ids.toSet().length != ids.length) {
      throw ArgumentError(message);
    }
  }
}
