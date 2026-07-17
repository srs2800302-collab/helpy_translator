import 'package:flutter_test/flutter_test.dart';
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
  group('RegistryRelatedContext', () {
    test('derives unique related entity ids from matched relations', () {
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
        payload: _RegistryRelatedContextTestPayload(
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

      final RegistryRelatedContext context = RegistryRelatedContext(
        primary: primary,
        matchedRelations: <RegistryRelation>[
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
            sourceEntityId: primary.id,
            targetEntityId: firstRelatedId,
            meaning: RegistryRelationMeaning('references'),
          ),
        ],
      );

      expect(context.primary, primary);
      expect(context.matchedRelations.length, 3);
      expect(context.relatedEntityIds, <RegistryEntityId>[
        firstRelatedId,
        secondRelatedId,
      ]);
    });

    test('rejects a matched relation without the primary entity', () {
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
        payload: _RegistryRelatedContextTestPayload(
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

      expect(
        () => RegistryRelatedContext(
          primary: primary,
          matchedRelations: <RegistryRelation>[
            RegistryRelation(
              sourceEntityId: RegistryEntityId('other-source'),
              targetEntityId: RegistryEntityId('other-target'),
              meaning: RegistryRelationMeaning('depends_on'),
            ),
          ],
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
        payload: _RegistryRelatedContextTestPayload(
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
      final List<RegistryRelation> sourceRelations = <RegistryRelation>[
        RegistryRelation(
          sourceEntityId: primary.id,
          targetEntityId: RegistryEntityId('related-001'),
          meaning: RegistryRelationMeaning('depends_on'),
        ),
      ];

      final RegistryRelatedContext context = RegistryRelatedContext(
        primary: primary,
        matchedRelations: sourceRelations,
      );

      sourceRelations.add(
        RegistryRelation(
          sourceEntityId: primary.id,
          targetEntityId: RegistryEntityId('related-002'),
          meaning: RegistryRelationMeaning('supports'),
        ),
      );

      expect(context.matchedRelations.length, 1);
      expect(context.relatedEntityIds, <RegistryEntityId>[
        RegistryEntityId('related-001'),
      ]);
      expect(
        () => context.matchedRelations.add(sourceRelations.last),
        throwsUnsupportedError,
      );
      expect(
        () => context.relatedEntityIds.add(RegistryEntityId('related-002')),
        throwsUnsupportedError,
      );
    });
  });
}

final class _RegistryRelatedContextTestPayload
    implements RegistryEntityPayload {
  const _RegistryRelatedContextTestPayload({
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
