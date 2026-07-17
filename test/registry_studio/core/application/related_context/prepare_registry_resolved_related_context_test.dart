import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_resolved_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_resolved_related_context.dart';
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
  group('PrepareRegistryResolvedRelatedContext', () {
    test('returns resolved context from available related entities', () {
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
        payload: _PrepareRegistryResolvedRelatedContextTestPayload(
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
      final RegistryEntity related = RegistryEntity(
        id: RegistryEntityId('related-001'),
        path: RegistryPath(const <String>['sample_scope', 'related-001']),
        kind: kind,
        payload: _PrepareRegistryResolvedRelatedContextTestPayload(
          semanticContract: semanticContract,
          entityKindId: 'sample.entity',
          payloadSchemaVersion: '1',
        ),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'sha256:related-001',
            headingPath: const <String>['Registry', 'Related 001'],
            startLine: 21,
            endLine: 30,
          ),
        ],
      );
      final RegistryEntityId missingRelatedId = RegistryEntityId('related-002');
      final RegistryRelatedContext base = RegistryRelatedContext(
        primary: primary,
        matchedRelations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: related.id,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
          RegistryRelation(
            sourceEntityId: missingRelatedId,
            targetEntityId: primary.id,
            meaning: RegistryRelationMeaning('supports'),
          ),
        ],
      );

      final RegistryResolvedRelatedContext context =
          PrepareRegistryResolvedRelatedContext()(
            base: base,
            availableRelatedEntities: <RegistryEntity>[related],
          );

      expect(context.base, base);
      expect(context.resolvedRelatedEntities, <RegistryEntity>[related]);
      expect(context.missingRelatedEntityIds, <RegistryEntityId>[
        missingRelatedId,
      ]);
    });

    test('rejects available entity outside base related ids', () {
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
        payload: _PrepareRegistryResolvedRelatedContextTestPayload(
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
      final RegistryEntity related = RegistryEntity(
        id: RegistryEntityId('related-001'),
        path: RegistryPath(const <String>['sample_scope', 'related-001']),
        kind: kind,
        payload: _PrepareRegistryResolvedRelatedContextTestPayload(
          semanticContract: semanticContract,
          entityKindId: 'sample.entity',
          payloadSchemaVersion: '1',
        ),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'sha256:related-001',
            headingPath: const <String>['Registry', 'Related 001'],
            startLine: 21,
            endLine: 30,
          ),
        ],
      );
      final RegistryEntity outside = RegistryEntity(
        id: RegistryEntityId('outside'),
        path: RegistryPath(const <String>['sample_scope', 'outside']),
        kind: kind,
        payload: _PrepareRegistryResolvedRelatedContextTestPayload(
          semanticContract: semanticContract,
          entityKindId: 'sample.entity',
          payloadSchemaVersion: '1',
        ),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'sha256:outside',
            headingPath: const <String>['Registry', 'Outside'],
            startLine: 31,
            endLine: 40,
          ),
        ],
      );
      final RegistryRelatedContext base = RegistryRelatedContext(
        primary: primary,
        matchedRelations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: related.id,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
        ],
      );

      expect(
        () => PrepareRegistryResolvedRelatedContext()(
          base: base,
          availableRelatedEntities: <RegistryEntity>[outside],
        ),
        throwsArgumentError,
      );
    });
  });
}

final class _PrepareRegistryResolvedRelatedContextTestPayload
    implements RegistryEntityPayload {
  const _PrepareRegistryResolvedRelatedContextTestPayload({
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
