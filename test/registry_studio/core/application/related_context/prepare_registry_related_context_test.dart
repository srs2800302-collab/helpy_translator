import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

void main() {
  group('PrepareRegistryRelatedContext', () {
    test('keeps only relations that contain the primary entity', () {
      final RegistrySemanticContractIdentity semanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'sample.semantic_contract',
            version: '1',
          );
      final RegistryEntityKind kind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'sample.entity',
        schemaVersion: '1',
      );
      final RegistryEntity primary = RegistryEntity(
        id: RegistryEntityId('primary'),
        path: RegistryPath(const <String>['sample_scope', 'primary']),
        kind: kind,
        payload: _PrepareRegistryRelatedContextTestPayload(
          semanticContract: semanticContract,
          entityKindId: 'sample.entity',
          payloadSchemaVersion: '1',
        ),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'sha256:primary',
            headingPath: const <String>['Registry', 'Primary'],
            startLine: 10,
            endLine: 20,
          ),
        ],
      );
      final RegistryEntityId firstRelatedId = RegistryEntityId('related-001');
      final RegistryEntityId secondRelatedId = RegistryEntityId('related-002');

      final RegistryRelatedContext context = PrepareRegistryRelatedContext()(
        primary: primary,
        relations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: firstRelatedId,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
          RegistryRelation(
            sourceEntityId: secondRelatedId,
            targetEntityId: primary.id,
            meaning: RegistryRelationMeaning('supports'),
          ),
          RegistryRelation(
            sourceEntityId: RegistryEntityId('unrelated-source'),
            targetEntityId: RegistryEntityId('unrelated-target'),
            meaning: RegistryRelationMeaning('references'),
          ),
        ],
      );

      expect(context.primary, primary);
      expect(context.matchedRelations.length, 2);
      expect(context.relatedEntityIds, <RegistryEntityId>[
        firstRelatedId,
        secondRelatedId,
      ]);
    });

    test('returns an empty context when no relation contains primary', () {
      final RegistrySemanticContractIdentity semanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'sample.semantic_contract',
            version: '1',
          );
      final RegistryEntityKind kind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'sample.entity',
        schemaVersion: '1',
      );
      final RegistryEntity primary = RegistryEntity(
        id: RegistryEntityId('primary'),
        path: RegistryPath(const <String>['sample_scope', 'primary']),
        kind: kind,
        payload: _PrepareRegistryRelatedContextTestPayload(
          semanticContract: semanticContract,
          entityKindId: 'sample.entity',
          payloadSchemaVersion: '1',
        ),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'sha256:primary',
            headingPath: const <String>['Registry', 'Primary'],
            startLine: 10,
            endLine: 20,
          ),
        ],
      );

      final RegistryRelatedContext context = PrepareRegistryRelatedContext()(
        primary: primary,
        relations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: RegistryEntityId('unrelated-source'),
            targetEntityId: RegistryEntityId('unrelated-target'),
            meaning: RegistryRelationMeaning('depends_on'),
          ),
        ],
      );

      expect(context.primary, primary);
      expect(context.matchedRelations, isEmpty);
      expect(context.relatedEntityIds, isEmpty);
    });
  });
}

final class _PrepareRegistryRelatedContextTestPayload
    implements RegistryEntityPayload {
  const _PrepareRegistryRelatedContextTestPayload({
    required this.semanticContract,
    required this.entityKindId,
    required this.payloadSchemaVersion,
  });

  @override
  final RegistrySemanticContractIdentity semanticContract;

  @override
  final String entityKindId;

  @override
  final String payloadSchemaVersion;
}
