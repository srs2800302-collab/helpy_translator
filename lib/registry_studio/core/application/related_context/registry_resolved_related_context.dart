import 'package:equatable/equatable.dart';

import '../../domain/entities/registry_entity.dart';
import '../../domain/value_objects/registry_entity_id.dart';
import 'registry_related_context.dart';

final class RegistryResolvedRelatedContext extends Equatable {
  factory RegistryResolvedRelatedContext({
    required RegistryRelatedContext base,
    required Iterable<RegistryEntity> resolvedRelatedEntities,
  }) {
    final List<RegistryEntity> normalizedResolvedEntities =
        resolvedRelatedEntities.toList(growable: false);
    final Set<RegistryEntityId> baseRelatedEntityIds = base.relatedEntityIds
        .toSet();
    final Set<RegistryEntityId> seenResolvedEntityIds = <RegistryEntityId>{};

    for (final RegistryEntity entity in normalizedResolvedEntities) {
      if (!seenResolvedEntityIds.add(entity.id)) {
        throw ArgumentError('Resolved related entity ids must be unique.');
      }

      if (entity.id == base.primary.id) {
        throw ArgumentError(
          'Resolved related entity must not be the primary registry entity.',
        );
      }

      if (!baseRelatedEntityIds.contains(entity.id)) {
        throw ArgumentError(
          'Resolved related entity id must be present in base related entity ids.',
        );
      }
    }

    final Set<RegistryEntityId> resolvedEntityIds = normalizedResolvedEntities
        .map((RegistryEntity entity) => entity.id)
        .toSet();

    final List<RegistryEntityId> missingRelatedEntityIds = base.relatedEntityIds
        .where((RegistryEntityId id) => !resolvedEntityIds.contains(id))
        .toList(growable: false);

    return RegistryResolvedRelatedContext._(
      base: base,
      resolvedRelatedEntities: List<RegistryEntity>.unmodifiable(
        normalizedResolvedEntities,
      ),
      missingRelatedEntityIds: List<RegistryEntityId>.unmodifiable(
        missingRelatedEntityIds,
      ),
    );
  }

  const RegistryResolvedRelatedContext._({
    required this.base,
    required this.resolvedRelatedEntities,
    required this.missingRelatedEntityIds,
  });

  final RegistryRelatedContext base;
  final List<RegistryEntity> resolvedRelatedEntities;
  final List<RegistryEntityId> missingRelatedEntityIds;

  @override
  List<Object> get props => <Object>[
    base,
    resolvedRelatedEntities,
    missingRelatedEntityIds,
  ];
}
