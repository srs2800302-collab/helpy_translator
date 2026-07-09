import '../../domain/entities/registry_entity.dart';
import 'registry_related_context.dart';
import 'registry_resolved_related_context.dart';

final class PrepareRegistryResolvedRelatedContext {
  RegistryResolvedRelatedContext call({
    required RegistryRelatedContext base,
    required Iterable<RegistryEntity> availableRelatedEntities,
  }) {
    return RegistryResolvedRelatedContext(
      base: base,
      resolvedRelatedEntities: availableRelatedEntities,
    );
  }
}
