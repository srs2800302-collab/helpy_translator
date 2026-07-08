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
    test('derives related entity ids from matched relations', () {
      final RegistryEntity primary = _entity('primary');
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
        ],
      );

      expect(context.primary, primary);
      expect(context.relatedEntityIds, <RegistryEntityId>[
        firstRelatedId,
        secondRelatedId,
      ]);
      expect(context.matchedRelations.length, 2);
    });

    test('rejects matched relation that does not include primary entity', () {
      final RegistryEntity primary = _entity('primary');

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

    test('keeps result collections immutable', () {
      final RegistryEntity primary = _entity('primary');

      final RegistryRelatedContext context = RegistryRelatedContext(
        primary: primary,
        matchedRelations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: RegistryEntityId('related-001'),
            meaning: RegistryRelationMeaning('depends_on'),
          ),
        ],
      );

      expect(
        () => context.matchedRelations.add(
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: RegistryEntityId('related-002'),
            meaning: RegistryRelationMeaning('supports'),
          ),
        ),
        throwsUnsupportedError,
      );

      expect(
        () => context.relatedEntityIds.add(RegistryEntityId('related-002')),
        throwsUnsupportedError,
      );
    });
  });
}

RegistryEntity _entity(String id) {
  final RegistrySemanticContractIdentity semanticContract =
      RegistrySemanticContractIdentity(
        contractId: 'sample.semantic_contract',
        version: '1',
      );

  return RegistryEntity(
    id: RegistryEntityId(id),
    path: RegistryPath(<String>['sample_scope', id]),
    kind: RegistryEntityKind(
      semanticContract: semanticContract,
      kindId: 'sample.entity',
      schemaVersion: '1',
    ),
    payload: _TestPayload(
      semanticContract: semanticContract,
      entityKindId: 'sample.entity',
      payloadSchemaVersion: '1',
    ),
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'docs/architecture/Registry_Studio_Source_v1.md',
        sourceSnapshotFingerprint: 'sha256:$id',
        headingPath: <String>['Sample', id],
        startLine: 1,
        endLine: 1,
      ),
    ],
  );
}

final class _TestPayload implements RegistryEntityPayload {
  const _TestPayload({
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
