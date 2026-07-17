import 'package:flutter_test/flutter_test.dart';
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
  group('RegistryResolvedRelatedContext', () {
    test('derives missing related ids from base context', () {
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
      final RegistryEntity firstRelated = RegistryEntity(
        id: RegistryEntityId('related-001'),
        path: RegistryPath(const <String>['sample_scope', 'related-001']),
        kind: kind,
        payload: _RegistryResolvedRelatedContextTestPayload(
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
      final RegistryEntityId secondRelatedId = RegistryEntityId('related-002');
      final RegistryRelatedContext base = RegistryRelatedContext(
        primary: primary,
        matchedRelations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: firstRelated.id,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
          RegistryRelation(
            sourceEntityId: secondRelatedId,
            targetEntityId: primary.id,
            meaning: RegistryRelationMeaning('supports'),
          ),
        ],
      );

      final RegistryResolvedRelatedContext context =
          RegistryResolvedRelatedContext(
            base: base,
            resolvedRelatedEntities: <RegistryEntity>[firstRelated],
          );

      expect(context.base, base);
      expect(context.resolvedRelatedEntities, <RegistryEntity>[firstRelated]);
      expect(context.missingRelatedEntityIds, <RegistryEntityId>[
        secondRelatedId,
      ]);
    });

    test('rejects resolved entity outside base related ids', () {
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
        () => RegistryResolvedRelatedContext(
          base: base,
          resolvedRelatedEntities: <RegistryEntity>[outside],
        ),
        throwsArgumentError,
      );
    });

    test('rejects primary as resolved related entity', () {
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
        () => RegistryResolvedRelatedContext(
          base: base,
          resolvedRelatedEntities: <RegistryEntity>[primary],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate resolved related entity ids', () {
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
        () => RegistryResolvedRelatedContext(
          base: base,
          resolvedRelatedEntities: <RegistryEntity>[related, related],
        ),
        throwsArgumentError,
      );
    });

    test('owns immutable result collections', () {
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
        payload: _RegistryResolvedRelatedContextTestPayload(
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
      final List<RegistryEntity> suppliedEntities = <RegistryEntity>[related];

      final RegistryResolvedRelatedContext context =
          RegistryResolvedRelatedContext(
            base: base,
            resolvedRelatedEntities: suppliedEntities,
          );

      suppliedEntities.clear();

      expect(context.resolvedRelatedEntities, <RegistryEntity>[related]);
      expect(
        () => context.resolvedRelatedEntities.add(related),
        throwsUnsupportedError,
      );
      expect(
        () => context.missingRelatedEntityIds.add(
          RegistryEntityId('related-002'),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

final class _RegistryResolvedRelatedContextTestPayload
    implements RegistryEntityPayload {
  const _RegistryResolvedRelatedContextTestPayload({
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
