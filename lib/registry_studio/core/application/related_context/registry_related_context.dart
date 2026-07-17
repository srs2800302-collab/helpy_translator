import 'package:equatable/equatable.dart';

import '../../domain/entities/registry_entity.dart';
import '../../domain/value_objects/registry_entity_id.dart';
import '../../domain/value_objects/registry_relation.dart';

final class RegistryRelatedContext extends Equatable {
  factory RegistryRelatedContext({
    required RegistryEntity primary,
    required Iterable<RegistryRelation> matchedRelations,
  }) {
    final List<RegistryRelation> normalizedRelations = matchedRelations.toList(
      growable: false,
    );

    for (final RegistryRelation relation in normalizedRelations) {
      final bool includesPrimary =
          relation.sourceEntityId == primary.id ||
          relation.targetEntityId == primary.id;

      if (!includesPrimary) {
        throw ArgumentError(
          'Matched relation must include primary registry entity.',
        );
      }
    }

    final Set<RegistryEntityId> relatedEntityIds = <RegistryEntityId>{};

    for (final RegistryRelation relation in normalizedRelations) {
      if (relation.sourceEntityId == primary.id) {
        relatedEntityIds.add(relation.targetEntityId);
      }

      if (relation.targetEntityId == primary.id) {
        relatedEntityIds.add(relation.sourceEntityId);
      }
    }

    relatedEntityIds.remove(primary.id);

    return RegistryRelatedContext._(
      primary: primary,
      matchedRelations: List<RegistryRelation>.unmodifiable(
        normalizedRelations,
      ),
      relatedEntityIds: List<RegistryEntityId>.unmodifiable(relatedEntityIds),
    );
  }

  const RegistryRelatedContext._({
    required this.primary,
    required this.matchedRelations,
    required this.relatedEntityIds,
  });

  final RegistryEntity primary;
  final List<RegistryRelation> matchedRelations;
  final List<RegistryEntityId> relatedEntityIds;

  @override
  List<Object> get props => <Object>[
    primary,
    matchedRelations,
    relatedEntityIds,
  ];
}
