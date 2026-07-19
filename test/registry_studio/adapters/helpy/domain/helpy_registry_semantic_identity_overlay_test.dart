import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_semantic_contract.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_semantic_identity_overlay.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('HelpyRegistrySemanticIdentityOverlay', () {
    test('preserves exact versioned Helpy source evidence', () {
      final HelpyRegistrySemanticIdentityOverlay overlay =
          HelpyRegistrySemanticIdentityOverlay.v1;

      expect(overlay.version, 'v1');
      expect(
        overlay.evidenceSourceDocumentPath,
        HelpyRegistrySemanticIdentityOverlay.sourceDocumentPath,
      );
      expect(
        overlay.evidenceSourceRevision,
        '64f45059c6043f2e65165a4a8da053cf3a73c107',
      );
      expect(
        overlay.evidenceRegistrySha256,
        'dbe4e4fbaa934e3e48c0190088421ff93190cda65083352df7cd67ff641010b7',
      );
    });

    test('maps only explicitly evidenced stable semantic identities', () {
      final HelpyRegistrySemanticIdentityOverlay overlay =
          HelpyRegistrySemanticIdentityOverlay.v1;

      const expectedMappings =
          <({int sequence, String kindId, bool ownsBusinessScope})>[
            (sequence: 1, kindId: 'contract', ownsBusinessScope: false),
            (
              sequence: 3,
              kindId: 'architectureGroup',
              ownsBusinessScope: false,
            ),
            (
              sequence: 4,
              kindId: 'architectureGroup',
              ownsBusinessScope: false,
            ),
            (
              sequence: 5,
              kindId: 'architectureGroup',
              ownsBusinessScope: false,
            ),
            (
              sequence: 6,
              kindId: 'architectureGroup',
              ownsBusinessScope: false,
            ),
            (
              sequence: 7,
              kindId: 'architectureGroup',
              ownsBusinessScope: false,
            ),
            (
              sequence: 8,
              kindId: 'architectureGroup',
              ownsBusinessScope: false,
            ),
            (
              sequence: 9,
              kindId: 'architectureGroup',
              ownsBusinessScope: false,
            ),
            (sequence: 64, kindId: 'platformRule', ownsBusinessScope: false),
            (sequence: 65, kindId: 'platformRule', ownsBusinessScope: false),
            (sequence: 66, kindId: 'platformRule', ownsBusinessScope: false),
            (sequence: 67, kindId: 'platformRule', ownsBusinessScope: false),
            (sequence: 68, kindId: 'platformRule', ownsBusinessScope: false),
            (sequence: 69, kindId: 'platformRule', ownsBusinessScope: false),
            (sequence: 70, kindId: 'platformRule', ownsBusinessScope: false),
            (sequence: 172, kindId: 'contract', ownsBusinessScope: true),
            (sequence: 173, kindId: 'rootCategory', ownsBusinessScope: false),
            (sequence: 212, kindId: 'contract', ownsBusinessScope: true),
            (sequence: 213, kindId: 'rootCategory', ownsBusinessScope: false),
            (sequence: 219, kindId: 'contract', ownsBusinessScope: true),
            (sequence: 220, kindId: 'rootCategory', ownsBusinessScope: false),
            (sequence: 288, kindId: 'contract', ownsBusinessScope: true),
            (sequence: 303, kindId: 'contract', ownsBusinessScope: true),
            (sequence: 310, kindId: 'contract', ownsBusinessScope: true),
          ];

      expect(overlay.identities.length, expectedMappings.length);
      expect(overlay.identitiesByNodeId.length, expectedMappings.length);

      for (final expected in expectedMappings) {
        final String sequence = expected.sequence.toString().padLeft(6, '0');

        final HelpyRegistrySemanticIdentity? identity =
            overlay.identitiesByNodeId[RegistryNodeId(
              'helpy.registry.node.$sequence',
            )];

        expect(identity, isNotNull);
        expect(
          identity!.entityId,
          RegistryEntityId('helpy.registry.entity.$sequence'),
        );
        expect(identity.kind.kindId, expected.kindId);
        expect(
          identity.kind.semanticContract,
          HelpyRegistrySemanticContract.identity,
        );
        expect(identity.ownsBusinessScope, expected.ownsBusinessScope);
        expect(identity.evidencePath.segments, isNotEmpty);
      }

      expect(
        overlay.identitiesByNodeId[RegistryNodeId(
          'helpy.registry.node.000002',
        )],
        isNull,
      );
    });

    test('resolves recursive business-scope ownership by stable identity', () {
      final HelpyRegistrySemanticIdentityOverlay overlay =
          HelpyRegistrySemanticIdentityOverlay.v1;

      final RegistryNodeId rootId = RegistryNodeId(
        'helpy.registry.node.000001',
      );
      final RegistryNodeId furnitureOwnerId = RegistryNodeId(
        'helpy.registry.node.000172',
      );
      final RegistryNodeId furnitureCategoryId = RegistryNodeId(
        'helpy.registry.node.000173',
      );
      final RegistryNodeId furnitureChildId = RegistryNodeId(
        'helpy.registry.node.999999',
      );
      final RegistryNodeId cleaningOwnerId = RegistryNodeId(
        'helpy.registry.node.000212',
      );
      final RegistryNodeId cleaningCategoryId = RegistryNodeId(
        'helpy.registry.node.000213',
      );

      final Map<RegistryNodeId, RegistryEntityId?> ownerIds = overlay
          .resolveBusinessScopeOwnerIds(
            activeNodeIds: <RegistryNodeId>[
              rootId,
              furnitureOwnerId,
              furnitureCategoryId,
              furnitureChildId,
              cleaningOwnerId,
              cleaningCategoryId,
            ],
            parentIdByNodeId: <RegistryNodeId, RegistryNodeId?>{
              rootId: null,
              furnitureOwnerId: rootId,
              furnitureCategoryId: furnitureOwnerId,
              furnitureChildId: furnitureCategoryId,
              cleaningOwnerId: rootId,
              cleaningCategoryId: cleaningOwnerId,
            },
          );

      expect(ownerIds[rootId], isNull);
      expect(
        ownerIds[furnitureOwnerId],
        RegistryEntityId('helpy.registry.entity.000172'),
      );
      expect(
        ownerIds[furnitureCategoryId],
        RegistryEntityId('helpy.registry.entity.000172'),
      );
      expect(
        ownerIds[furnitureChildId],
        RegistryEntityId('helpy.registry.entity.000172'),
      );
      expect(
        ownerIds[cleaningOwnerId],
        RegistryEntityId('helpy.registry.entity.000212'),
      );
      expect(
        ownerIds[cleaningCategoryId],
        RegistryEntityId('helpy.registry.entity.000212'),
      );
    });

    test('applies only to exact versioned evidence and validates paths', () {
      final HelpyRegistrySemanticIdentityOverlay overlay =
          HelpyRegistrySemanticIdentityOverlay.v1;

      expect(
        overlay.appliesTo(
          sourceDocumentPath:
              HelpyRegistrySemanticIdentityOverlay.sourceDocumentPath,
          sourceRevision: '64f45059c6043f2e65165a4a8da053cf3a73c107',
        ),
        isTrue,
      );
      expect(
        overlay.appliesTo(
          sourceDocumentPath:
              HelpyRegistrySemanticIdentityOverlay.sourceDocumentPath,
          sourceRevision: '0000000000000000000000000000000000000000',
        ),
        isFalse,
      );
      expect(
        overlay.appliesTo(
          sourceDocumentPath: 'other-registry.md',
          sourceRevision: '64f45059c6043f2e65165a4a8da053cf3a73c107',
        ),
        isFalse,
      );

      final Map<RegistryNodeId, RegistryPath> activePathsByNodeId =
          <RegistryNodeId, RegistryPath>{
            for (final HelpyRegistrySemanticIdentity identity
                in overlay.identities)
              identity.nodeId: identity.evidencePath,
          };

      expect(
        () => overlay.validateActiveEvidencePaths(
          activePathsByNodeId: activePathsByNodeId,
        ),
        returnsNormally,
      );

      final HelpyRegistrySemanticIdentity firstIdentity =
          overlay.identities.first;

      activePathsByNodeId[firstIdentity.nodeId] = RegistryPath(const <String>[
        'Different Registry',
      ]);

      expect(
        () => overlay.validateActiveEvidencePaths(
          activePathsByNodeId: activePathsByNodeId,
        ),
        throwsStateError,
      );
    });

    test('does not expose mutable overlay collections', () {
      final HelpyRegistrySemanticIdentityOverlay overlay =
          HelpyRegistrySemanticIdentityOverlay.v1;

      expect(() => overlay.identities.clear(), throwsUnsupportedError);
      expect(() => overlay.identitiesByNodeId.clear(), throwsUnsupportedError);
    });
  });
}
