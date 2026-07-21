import '../../../core/domain/entities/registry_entity.dart';
import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_entity_kind.dart';
import '../../../core/domain/value_objects/registry_semantic_contract_identity.dart';
import '../../../registry/application/contracts/registry_business_scope_resolver.dart';
import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';
import '../domain/entities/helpy_business_scope_owner_payload.dart';

final class HelpyRegistryBusinessScopeResolver
    implements RegistryBusinessScopeResolver {
  const HelpyRegistryBusinessScopeResolver();

  static const String serviceCatalogOwnerClassId = 'service_catalog';

  static const String globalBusinessRulesOwnerClassId = 'global_business_rules';

  static final RegExp _serviceCatalogOwnerPattern = RegExp(
    r'^(?:[0-9]+\.\s+)?'
    r'Service Architecture Registry\s+—\s+(.+)$',
  );

  static final RegExp _globalBusinessRulesOwnerPattern = RegExp(
    r'^(?:[0-9]+\.\s+)?Global Platform Rules$',
  );

  static final RegistrySemanticContractIdentity _semanticContract =
      RegistrySemanticContractIdentity(
        contractId: 'helpy.registry.business_scope',
        version: '1',
      );

  static final RegistryEntityKind _ownerKind = RegistryEntityKind(
    semanticContract: _semanticContract,
    kindId: 'helpy.registry.business_scope_owner',
    schemaVersion: '1',
  );

  @override
  RegistrySnapshot resolveBusinessScope(RegistrySnapshot snapshot) {
    final Map<RegistryEntityId, RegistryEntity> entitiesById =
        <RegistryEntityId, RegistryEntity>{
          for (final RegistryEntity entity in snapshot.entities)
            entity.id: entity,
        };

    final List<RegistryEntity> discoveredOwners = <RegistryEntity>[];

    late RegistryNode Function(
      RegistryNode node,
      RegistryEntityId? inheritedOwnerId,
    )
    resolveNode;

    resolveNode = (RegistryNode node, RegistryEntityId? inheritedOwnerId) {
      final ({String ownerClassId, String title})? ownerDescriptor =
          _ownerDescriptor(node);

      RegistryEntityId? resolvedOwnerId = inheritedOwnerId;

      if (ownerDescriptor != null) {
        resolvedOwnerId = RegistryEntityId(
          'helpy.registry.business-scope-owner.'
          '${node.id.value}',
        );

        final RegistryEntity? existingOwner = entitiesById[resolvedOwnerId];

        if (existingOwner == null) {
          final RegistryEntity owner = RegistryEntity(
            id: resolvedOwnerId,
            path: node.path,
            kind: _ownerKind,
            payload: HelpyBusinessScopeOwnerPayload(
              semanticContract: _semanticContract,
              entityKindId: _ownerKind.kindId,
              payloadSchemaVersion: _ownerKind.schemaVersion,
              ownerClassId: ownerDescriptor.ownerClassId,
              title: ownerDescriptor.title,
            ),
            sourceEvidence: node.sourceEvidence,
          );

          entitiesById[resolvedOwnerId] = owner;
          discoveredOwners.add(owner);
        } else {
          if (existingOwner.path != node.path ||
              existingOwner.kind != _ownerKind ||
              existingOwner.payload is! HelpyBusinessScopeOwnerPayload) {
            throw StateError(
              'Helpy Registry business-scope owner '
              '${resolvedOwnerId.value} conflicts with '
              'existing semantic entity evidence.',
            );
          }
        }
      }

      final RegistryEntityId? existingOwnerId = node.businessScopeOwnerId;

      if (existingOwnerId != null && existingOwnerId != resolvedOwnerId) {
        throw StateError(
          'Helpy Registry node '
          '${node.path.segments.join(' → ')} contains '
          'conflicting business-scope ownership.',
        );
      }

      final List<RegistryNode> resolvedChildren = <RegistryNode>[
        for (final RegistryNode child in node.children)
          resolveNode(child, resolvedOwnerId),
      ];

      return RegistryNode(
        id: node.id,
        kindId: node.kindId,
        path: node.path,
        sourceEvidence: node.sourceEvidence,
        content: node.content,
        businessScopeOwnerId: resolvedOwnerId,
        children: resolvedChildren,
      );
    };

    final List<RegistryNode> resolvedRoots = <RegistryNode>[
      for (final RegistryNode root in snapshot.roots) resolveNode(root, null),
    ];

    return RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: snapshot.sourceRevision,
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      sourceContent: snapshot.sourceContent,
      roots: resolvedRoots,
      entities: <RegistryEntity>[...snapshot.entities, ...discoveredOwners],
      relations: snapshot.relations,
    );
  }

  ({String ownerClassId, String title})? _ownerDescriptor(RegistryNode node) {
    final String heading = node.path.segments.last;

    final RegExpMatch? serviceCatalogMatch = _serviceCatalogOwnerPattern
        .firstMatch(heading);

    if (serviceCatalogMatch != null) {
      final String title = serviceCatalogMatch.group(1)!.trim();

      if (title.isEmpty) {
        throw FormatException(
          'Helpy service-catalog business owner at '
          '${node.path.segments.join(' → ')} '
          'must contain a title.',
        );
      }

      return (ownerClassId: serviceCatalogOwnerClassId, title: title);
    }

    if (_globalBusinessRulesOwnerPattern.hasMatch(heading)) {
      return (
        ownerClassId: globalBusinessRulesOwnerClassId,
        title: 'Global Platform Rules',
      );
    }

    return null;
  }
}
