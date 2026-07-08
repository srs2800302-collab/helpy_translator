import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('RegistryEntity', () {
    test('accepts a source-backed payload compatible with its primary kind', () {
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

      final RegistryEntity entity = RegistryEntity(
        id: RegistryEntityId('registry-entity-001'),
        path: RegistryPath(<String>[
          'sample_scope',
          'sample_section',
          'sample_item',
        ]),
        kind: kind,
        payload: _TestPayload(
          semanticContract: semanticContract,
          entityKindId: 'sample.entity',
          payloadSchemaVersion: '1',
        ),
        sourceEvidence: <SourceEvidence>[_sourceEvidence()],
      );

      expect(entity.id.value, 'registry-entity-001');
      expect(entity.kind, kind);
      expect(entity.sourceEvidence, <SourceEvidence>[_sourceEvidence()]);
      expect(
        () => entity.sourceEvidence.add(_sourceEvidence()),
        throwsUnsupportedError,
      );
    });

    test('rejects an entity without source evidence', () {
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

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          kind: kind,
          payload: _TestPayload(
            semanticContract: semanticContract,
            entityKindId: kind.kindId,
            payloadSchemaVersion: kind.schemaVersion,
          ),
          sourceEvidence: const <SourceEvidence>[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a payload from another semantic contract', () {
      final RegistrySemanticContractIdentity sampleSemanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'sample.semantic_contract',
            version: '1',
          );
      final RegistrySemanticContractIdentity anotherSemanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'another.semantic_contract',
            version: '1',
          );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          kind: RegistryEntityKind(
            semanticContract: sampleSemanticContract,
            kindId: 'sample.entity',
            schemaVersion: '1',
          ),
          payload: _TestPayload(
            semanticContract: anotherSemanticContract,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '1',
          ),
          sourceEvidence: <SourceEvidence>[_sourceEvidence()],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a payload for another entity kind or schema', () {
      final RegistrySemanticContractIdentity semanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'sample.semantic_contract',
            version: '1',
          );
      final RegistryEntityKind entityKind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'sample.entity',
        schemaVersion: '1',
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          kind: entityKind,
          payload: _TestPayload(
            semanticContract: semanticContract,
            entityKindId: 'sample.standard',
            payloadSchemaVersion: '1',
          ),
          sourceEvidence: <SourceEvidence>[_sourceEvidence()],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          kind: entityKind,
          payload: _TestPayload(
            semanticContract: semanticContract,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '2',
          ),
          sourceEvidence: <SourceEvidence>[_sourceEvidence()],
        ),
        throwsArgumentError,
      );
    });

    test('uses stable immutable identity for entity equality', () {
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
      final RegistryEntityId id = RegistryEntityId('registry-entity-001');

      final RegistryEntity first = RegistryEntity(
        id: id,
        path: RegistryPath(<String>[
          'sample_scope',
          'sample_section',
          'sample_item',
        ]),
        kind: kind,
        payload: _TestPayload(
          semanticContract: semanticContract,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[_sourceEvidence(startLine: 10)],
      );
      final RegistryEntity second = RegistryEntity(
        id: id,
        path: RegistryPath(<String>[
          'sample_scope',
          'sample_section',
          'sample_variant_item',
        ]),
        kind: kind,
        payload: _TestPayload(
          semanticContract: semanticContract,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[_sourceEvidence(startLine: 20)],
      );

      expect(first, second);
      expect(first.id, second.id);
      expect(first.path, isNot(second.path));
      expect(first.sourceEvidence, isNot(second.sourceEvidence));
    });
  });
}

SourceEvidence _sourceEvidence({int startLine = 100}) {
  return SourceEvidence(
    sourceDocumentPath: 'docs/architecture/Registry_Studio_Source_v1.md',
    sourceSnapshotFingerprint: 'sha256:abc123',
    headingPath: <String>['Sample Domain', 'Sample Entity'],
    startLine: startLine,
    endLine: startLine + 10,
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
