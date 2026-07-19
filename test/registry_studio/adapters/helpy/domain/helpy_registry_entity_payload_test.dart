import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_semantic_contract.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_semantic_identity_overlay.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';

void main() {
  group('HelpyRegistryEntityPayload', () {
    test('materializes typed payloads from mapped structural nodes', () {
      final HelpyRegistrySemanticIdentityOverlay overlay =
          HelpyRegistrySemanticIdentityOverlay.v1;

      final expectedPayloadTypes = <int, Type>{
        1: HelpyRegistryContractPayload,
        3: HelpyRegistryArchitectureGroupPayload,
        64: HelpyRegistryPlatformRulePayload,
        173: HelpyRegistryRootCategoryPayload,
      };

      for (final MapEntry<int, Type> expected in expectedPayloadTypes.entries) {
        final String sequence = expected.key.toString().padLeft(6, '0');

        final HelpyRegistrySemanticIdentity identity = overlay
            .identitiesByNodeId
            .values
            .singleWhere(
              (HelpyRegistrySemanticIdentity identity) =>
                  identity.nodeId.value == 'helpy.registry.node.$sequence',
            );

        final RegistryNode node = RegistryNode(
          id: identity.nodeId,
          kindId: 'helpy.registry.markdown.heading.1',
          path: identity.evidencePath,
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath:
                  HelpyRegistrySemanticIdentityOverlay.sourceDocumentPath,
              sourceSnapshotFingerprint:
                  'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              headingPath: identity.evidencePath.segments,
              startLine: 1,
              endLine: 1,
            ),
          ],
          content: 'Semantic source content.',
          businessScopeOwnerId: null,
          children: const <RegistryNode>[],
        );

        final entity = identity.materializeEntity(node);
        final HelpyRegistryEntityPayload payload =
            entity.payload as HelpyRegistryEntityPayload;

        expect(entity.id, identity.entityId);
        expect(entity.kind, identity.kind);
        expect(entity.path, identity.evidencePath);
        expect(payload.runtimeType, expected.value);
        expect(payload.sourceNodeId, identity.nodeId);
        expect(payload.title, identity.evidencePath.segments.last);
        expect(payload.content, 'Semantic source content.');
        expect(payload.ownsBusinessScope, identity.ownsBusinessScope);
        expect(
          payload.semanticContract,
          HelpyRegistrySemanticContract.identity,
        );
        expect(payload.entityKindId, identity.kind.kindId);
        expect(payload.payloadSchemaVersion, identity.kind.schemaVersion);
      }
    });

    test('rejects kinds without an implemented typed payload schema', () {
      expect(
        () => HelpyRegistryEntityPayload(
          kind: HelpyRegistrySemanticContract.category,
          sourceNodeId:
              HelpyRegistrySemanticIdentityOverlay.v1.identities.first.nodeId,
          title: 'Category',
          content: '',
          ownsBusinessScope: false,
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects structural evidence that does not match mapping', () {
      final HelpyRegistrySemanticIdentityOverlay overlay =
          HelpyRegistrySemanticIdentityOverlay.v1;
      final HelpyRegistrySemanticIdentity identity = overlay.identities.first;
      final mismatchedPath = overlay.identities[1].evidencePath;

      final RegistryNode mismatchedNode = RegistryNode(
        id: identity.nodeId,
        kindId: 'helpy.registry.markdown.heading.1',
        path: mismatchedPath,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath:
                HelpyRegistrySemanticIdentityOverlay.sourceDocumentPath,
            sourceSnapshotFingerprint:
                'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            headingPath: mismatchedPath.segments,
            startLine: 1,
            endLine: 1,
          ),
        ],
        content: '',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      expect(
        () => identity.materializeEntity(mismatchedNode),
        throwsStateError,
      );
    });
  });
}
