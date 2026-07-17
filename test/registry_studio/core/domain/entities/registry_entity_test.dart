import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

void main() {
  group('RegistryEntity', () {
    test('accepts a source-backed payload compatible with its kind', () {
      final RegistrySemanticContractIdentity semanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'sample.semantic_contract',
            version: '1',
          );

      final RegistryEntityKind kind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'sample.entity',
        schemaVersion: '3',
      );

      final RegistryEntityPayload payload = _FixtureRegistryEntityPayload(
        semanticContract: semanticContract,
        entityKindId: 'sample.entity',
        payloadSchemaVersion: '3',
      );

      final SourceEvidence evidence = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'sha256:abc123',
        headingPath: const <String>['Registry', 'Sample Entity'],
        startLine: 10,
        endLine: 20,
      );

      final RegistryEntity entity = RegistryEntity(
        id: RegistryEntityId('sample-entity-001'),
        path: RegistryPath(const <String>[
          'sample_scope',
          'sample_section',
          'sample_entity',
        ]),
        kind: kind,
        payload: payload,
        sourceEvidence: <SourceEvidence>[evidence],
      );

      expect(entity.id.value, 'sample-entity-001');
      expect(entity.kind, same(kind));
      expect(entity.payload, same(payload));
      expect(entity.sourceEvidence, <SourceEvidence>[evidence]);
      expect(() => entity.sourceEvidence.add(evidence), throwsUnsupportedError);
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
          id: RegistryEntityId('sample-entity-001'),
          path: RegistryPath(const <String>['sample_scope', 'sample_entity']),
          kind: kind,
          payload: _FixtureRegistryEntityPayload(
            semanticContract: semanticContract,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '1',
          ),
          sourceEvidence: const <SourceEvidence>[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a payload from another semantic contract', () {
      final RegistrySemanticContractIdentity entitySemanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'sample.semantic_contract',
            version: '1',
          );

      final RegistrySemanticContractIdentity payloadSemanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'another.semantic_contract',
            version: '1',
          );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('sample-entity-001'),
          path: RegistryPath(const <String>['sample_scope', 'sample_entity']),
          kind: RegistryEntityKind(
            semanticContract: entitySemanticContract,
            kindId: 'sample.entity',
            schemaVersion: '1',
          ),
          payload: _FixtureRegistryEntityPayload(
            semanticContract: payloadSemanticContract,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '1',
          ),
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: 'registry.md',
              sourceSnapshotFingerprint: 'sha256:abc123',
              headingPath: const <String>['Registry', 'Sample Entity'],
              startLine: 10,
              endLine: 20,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a payload for another kind or schema version', () {
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

      final SourceEvidence evidence = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'sha256:abc123',
        headingPath: const <String>['Registry', 'Sample Entity'],
        startLine: 10,
        endLine: 20,
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('sample-entity-001'),
          path: RegistryPath(const <String>['sample_scope', 'sample_entity']),
          kind: kind,
          payload: _FixtureRegistryEntityPayload(
            semanticContract: semanticContract,
            entityKindId: 'another.entity',
            payloadSchemaVersion: '1',
          ),
          sourceEvidence: <SourceEvidence>[evidence],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('sample-entity-001'),
          path: RegistryPath(const <String>['sample_scope', 'sample_entity']),
          kind: kind,
          payload: _FixtureRegistryEntityPayload(
            semanticContract: semanticContract,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '2',
          ),
          sourceEvidence: <SourceEvidence>[evidence],
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

      final RegistryEntityId id = RegistryEntityId('sample-entity-001');

      final RegistryEntity first = RegistryEntity(
        id: id,
        path: RegistryPath(const <String>[
          'sample_scope',
          'sample_section',
          'sample_entity',
        ]),
        kind: kind,
        payload: _FixtureRegistryEntityPayload(
          semanticContract: semanticContract,
          entityKindId: 'sample.entity',
          payloadSchemaVersion: '1',
        ),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'sha256:first',
            headingPath: const <String>['Registry', 'First'],
            startLine: 10,
            endLine: 20,
          ),
        ],
      );

      final RegistryEntity second = RegistryEntity(
        id: id,
        path: RegistryPath(const <String>[
          'sample_scope',
          'another_section',
          'sample_entity',
        ]),
        kind: kind,
        payload: _FixtureRegistryEntityPayload(
          semanticContract: semanticContract,
          entityKindId: 'sample.entity',
          payloadSchemaVersion: '1',
        ),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'sha256:second',
            headingPath: const <String>['Registry', 'Second'],
            startLine: 30,
            endLine: 40,
          ),
        ],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.path, isNot(second.path));
      expect(first.sourceEvidence, isNot(second.sourceEvidence));
    });
  });
}

final class _FixtureRegistryEntityPayload implements RegistryEntityPayload {
  const _FixtureRegistryEntityPayload({
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
