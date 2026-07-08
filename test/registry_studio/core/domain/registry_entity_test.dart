import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_adapter_contract_identity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('RegistryEntity', () {
    test('accepts a source-backed payload compatible with its primary kind', () {
      final RegistryAdapterContractIdentity adapter =
          RegistryAdapterContractIdentity(
            adapterId: 'sample_adapter',
            semanticContractVersion: '1',
          );
      final RegistryEntityKind kind = RegistryEntityKind(
        adapterContract: adapter,
        kindId: 'sample.entity',
        schemaVersion: '1',
      );

      final RegistryEntity entity = RegistryEntity(
        id: RegistryEntityId('registry-entity-001'),
        path: RegistryPath(<String>[
          'sample_adapter',
          'sample_domain',
          'sample_entity',
        ]),
        kind: kind,
        payload: _TestPayload(
          adapterContract: adapter,
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
      final RegistryAdapterContractIdentity adapter =
          RegistryAdapterContractIdentity(
            adapterId: 'sample_adapter',
            semanticContractVersion: '1',
          );
      final RegistryEntityKind kind = RegistryEntityKind(
        adapterContract: adapter,
        kindId: 'sample.entity',
        schemaVersion: '1',
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_adapter', 'sample_domain']),
          kind: kind,
          payload: _TestPayload(
            adapterContract: adapter,
            entityKindId: kind.kindId,
            payloadSchemaVersion: kind.schemaVersion,
          ),
          sourceEvidence: const <SourceEvidence>[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a payload from another adapter contract', () {
      final RegistryAdapterContractIdentity sampleAdapter =
          RegistryAdapterContractIdentity(
            adapterId: 'sample_adapter',
            semanticContractVersion: '1',
          );
      final RegistryAdapterContractIdentity anotherAdapter =
          RegistryAdapterContractIdentity(
            adapterId: 'another_adapter',
            semanticContractVersion: '1',
          );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_adapter', 'sample_domain']),
          kind: RegistryEntityKind(
            adapterContract: sampleAdapter,
            kindId: 'sample.entity',
            schemaVersion: '1',
          ),
          payload: _TestPayload(
            adapterContract: anotherAdapter,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '1',
          ),
          sourceEvidence: <SourceEvidence>[_sourceEvidence()],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a payload for another entity kind or schema', () {
      final RegistryAdapterContractIdentity adapter =
          RegistryAdapterContractIdentity(
            adapterId: 'sample_adapter',
            semanticContractVersion: '1',
          );
      final RegistryEntityKind entityKind = RegistryEntityKind(
        adapterContract: adapter,
        kindId: 'sample.entity',
        schemaVersion: '1',
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_adapter', 'sample_domain']),
          kind: entityKind,
          payload: _TestPayload(
            adapterContract: adapter,
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
          path: RegistryPath(<String>['sample_adapter', 'sample_domain']),
          kind: entityKind,
          payload: _TestPayload(
            adapterContract: adapter,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '2',
          ),
          sourceEvidence: <SourceEvidence>[_sourceEvidence()],
        ),
        throwsArgumentError,
      );
    });

    test('uses stable immutable identity for entity equality', () {
      final RegistryAdapterContractIdentity adapter =
          RegistryAdapterContractIdentity(
            adapterId: 'sample_adapter',
            semanticContractVersion: '1',
          );
      final RegistryEntityKind kind = RegistryEntityKind(
        adapterContract: adapter,
        kindId: 'sample.entity',
        schemaVersion: '1',
      );
      final RegistryEntityId id = RegistryEntityId('registry-entity-001');

      final RegistryEntity first = RegistryEntity(
        id: id,
        path: RegistryPath(<String>[
          'sample_adapter',
          'sample_domain',
          'sample_entity',
        ]),
        kind: kind,
        payload: _TestPayload(
          adapterContract: adapter,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[_sourceEvidence(startLine: 10)],
      );
      final RegistryEntity second = RegistryEntity(
        id: id,
        path: RegistryPath(<String>[
          'sample_adapter',
          'sample_domain',
          'sample_variant',
        ]),
        kind: kind,
        payload: _TestPayload(
          adapterContract: adapter,
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
    required this.adapterContract,
    required this.entityKindId,
    required this.payloadSchemaVersion,
  });

  @override
  final RegistryAdapterContractIdentity adapterContract;

  @override
  final String entityKindId;

  @override
  final String payloadSchemaVersion;
}
