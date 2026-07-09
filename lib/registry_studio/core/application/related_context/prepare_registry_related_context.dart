import '../../domain/entities/registry_entity.dart';
import '../../domain/value_objects/registry_relation.dart';
import 'registry_related_context.dart';

final class PrepareRegistryRelatedContext {
  RegistryRelatedContext call({
    required RegistryEntity primary,
    required Iterable<RegistryRelation> relations,
  }) {
    final Iterable<RegistryRelation> matchedRelations = relations.where(
      (RegistryRelation relation) =>
          relation.sourceEntityId == primary.id ||
          relation.targetEntityId == primary.id,
    );

    return RegistryRelatedContext(
      primary: primary,
      matchedRelations: matchedRelations,
    );
  }
}
