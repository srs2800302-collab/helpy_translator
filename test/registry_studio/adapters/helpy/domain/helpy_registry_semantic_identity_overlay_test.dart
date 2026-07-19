import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_semantic_contract.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_semantic_identity_overlay.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
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
            (sequence: 21, kindId: 'contract', ownsBusinessScope: true),
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

      expect(overlay.identities.length, expectedMappings.length + 4);
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

    test('materializes heterogeneous root-category evidence '
        'without requiring one Markdown form', () {
      final HelpyRegistrySemanticIdentityOverlay overlay =
          HelpyRegistrySemanticIdentityOverlay.v1;

      final Map<
        String,
        ({String nodeId, String title, int startLine, int endLine})
      >
      expected =
          <String, ({String nodeId, String title, int startLine, int endLine})>{
            'helpy.registry.entity.root-category.'
                'appliance-installation-connection': (
              nodeId: 'helpy.registry.node.000021',
              title: 'Appliance Installation & Connection',
              startLine: 526,
              endLine: 536,
            ),
            'helpy.registry.entity.root-category.electrical': (
              nodeId: 'helpy.registry.node.000288',
              title: 'Electrical',
              startLine: 9240,
              endLine: 9249,
            ),
            'helpy.registry.entity.root-category.plumbing': (
              nodeId:
                  'helpy.registry.node.'
                  '000304',
              title: 'Plumbing',
              startLine: 9934,
              endLine: 9934,
            ),
            'helpy.registry.entity.root-category.locks': (
              nodeId: 'helpy.registry.node.000310',
              title: 'Locks',
              startLine: 10929,
              endLine: 10930,
            ),
          };

      final List<HelpyRegistrySemanticIdentity> supplementaryIdentities =
          overlay.identities
              .where(
                (HelpyRegistrySemanticIdentity identity) =>
                    !identity.contributesStructuralKind,
              )
              .toList(growable: false);

      expect(supplementaryIdentities, hasLength(4));

      for (final HelpyRegistrySemanticIdentity identity
          in supplementaryIdentities) {
        final expectedIdentity = expected[identity.entityId.value];

        expect(expectedIdentity, isNotNull);
        expect(identity.nodeId.value, expectedIdentity!.nodeId);
        expect(identity.semanticTitle, expectedIdentity.title);
        expect(identity.evidenceStartLine, expectedIdentity.startLine);
        expect(identity.evidenceEndLine, expectedIdentity.endLine);
        expect(identity.kind, HelpyRegistrySemanticContract.rootCategory);
        expect(identity.ownsBusinessScope, isFalse);

        final RegistryNode sourceNode = RegistryNode(
          id: identity.nodeId,
          kindId: 'helpy.registry.markdown.heading.2',
          path: identity.evidencePath,
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath:
                  HelpyRegistrySemanticIdentityOverlay.sourceDocumentPath,
              sourceSnapshotFingerprint:
                  'git-blob:'
                  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              headingPath: identity.evidencePath.segments,
              startLine: identity.evidenceStartLine! - 1,
              endLine: identity.evidenceEndLine! + 1,
            ),
          ],
          content: 'Exact heterogeneous source content.',
          businessScopeOwnerId: null,
          children: const <RegistryNode>[],
        );

        final entity = identity.materializeEntity(sourceNode);
        final HelpyRegistryEntityPayload payload =
            entity.payload as HelpyRegistryEntityPayload;

        expect(entity.id, identity.entityId);
        expect(entity.path, identity.evidencePath);
        expect(payload.sourceNodeId, identity.nodeId);
        expect(payload.title, expectedIdentity.title);
        expect(
          entity.sourceEvidence.single.startLine,
          expectedIdentity.startLine,
        );
        expect(entity.sourceEvidence.single.endLine, expectedIdentity.endLine);
      }
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

    test(
      'assigns one category owner across heterogeneous structural roots',
      () {
        final HelpyRegistrySemanticIdentityOverlay overlay =
            HelpyRegistrySemanticIdentityOverlay.v1;

        final RegistryNodeId registryRootId = RegistryNodeId(
          'helpy.registry.node.000001',
        );
        final RegistryNodeId applianceArchitectureId = RegistryNodeId(
          'helpy.registry.node.000021',
        );
        final RegistryNodeId applianceMiniTzId = RegistryNodeId(
          'helpy.registry.node.000022',
        );
        final RegistryNodeId applianceScenarioId = RegistryNodeId(
          'helpy.registry.node.000023',
        );
        final RegistryNodeId builtInStandardId = RegistryNodeId(
          'helpy.registry.node.000026',
        );
        final RegistryNodeId builtInEntityId = RegistryNodeId(
          'helpy.registry.node.000027',
        );
        final RegistryNodeId futureUnclassifiedCategoryId = RegistryNodeId(
          'helpy.registry.node.999998',
        );
        final RegistryNodeId futureUnclassifiedChildId = RegistryNodeId(
          'helpy.registry.node.999999',
        );

        final Map<RegistryNodeId, RegistryEntityId?> ownerIds = overlay
            .resolveBusinessScopeOwnerIds(
              activeNodeIds: <RegistryNodeId>[
                registryRootId,
                applianceArchitectureId,
                applianceMiniTzId,
                applianceScenarioId,
                builtInStandardId,
                builtInEntityId,
                futureUnclassifiedCategoryId,
                futureUnclassifiedChildId,
              ],
              parentIdByNodeId: <RegistryNodeId, RegistryNodeId?>{
                registryRootId: null,
                applianceArchitectureId: registryRootId,
                applianceMiniTzId: registryRootId,
                applianceScenarioId: applianceMiniTzId,
                builtInStandardId: registryRootId,
                builtInEntityId: builtInStandardId,
                futureUnclassifiedCategoryId: registryRootId,
                futureUnclassifiedChildId: futureUnclassifiedCategoryId,
              },
            );

        final RegistryEntityId applianceOwnerId = RegistryEntityId(
          'helpy.registry.entity.000021',
        );

        expect(ownerIds[registryRootId], isNull);
        expect(ownerIds[applianceArchitectureId], applianceOwnerId);
        expect(ownerIds[applianceMiniTzId], applianceOwnerId);
        expect(ownerIds[applianceScenarioId], applianceOwnerId);
        expect(ownerIds[builtInStandardId], applianceOwnerId);
        expect(ownerIds[builtInEntityId], applianceOwnerId);

        expect(ownerIds[futureUnclassifiedCategoryId], isNull);
        expect(ownerIds[futureUnclassifiedChildId], isNull);
      },
    );

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
