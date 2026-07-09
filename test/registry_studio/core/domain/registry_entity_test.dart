import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

import '../fixtures/registry_entity_fixture.dart';

void main() {
  group('RegistryEntity', () {
    test(
      'accepts a source-backed payload compatible with its primary kind',
      () {
        final RegistrySemanticContractIdentity semanticContract =
            registrySemanticContractFixture();
        final RegistryEntityKind kind = registryEntityKindFixture(
          semanticContract: semanticContract,
        );
        final SourceEvidence evidence = sourceEvidenceFixture();

        final RegistryEntity entity = RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>[
            'sample_scope',
            'sample_section',
            'sample_item',
          ]),
          kind: kind,
          payload: registryEntityPayloadFixture(
            semanticContract: semanticContract,
            entityKindId: kind.kindId,
            payloadSchemaVersion: kind.schemaVersion,
          ),
          sourceEvidence: <SourceEvidence>[evidence],
        );

        expect(entity.id.value, 'registry-entity-001');
        expect(entity.kind, kind);
        expect(entity.sourceEvidence, <SourceEvidence>[evidence]);
        expect(
          () => entity.sourceEvidence.add(evidence),
          throwsUnsupportedError,
        );
      },
    );

    test('rejects an entity without source evidence', () {
      final RegistrySemanticContractIdentity semanticContract =
          registrySemanticContractFixture();
      final RegistryEntityKind kind = registryEntityKindFixture(
        semanticContract: semanticContract,
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          kind: kind,
          payload: registryEntityPayloadFixture(
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
          registrySemanticContractFixture();
      final RegistrySemanticContractIdentity anotherSemanticContract =
          registrySemanticContractFixture(
            contractId: 'another.semantic_contract',
          );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          kind: registryEntityKindFixture(
            semanticContract: sampleSemanticContract,
          ),
          payload: registryEntityPayloadFixture(
            semanticContract: anotherSemanticContract,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '1',
          ),
          sourceEvidence: <SourceEvidence>[sourceEvidenceFixture()],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a payload for another entity kind or schema', () {
      final RegistrySemanticContractIdentity semanticContract =
          registrySemanticContractFixture();
      final RegistryEntityKind entityKind = registryEntityKindFixture(
        semanticContract: semanticContract,
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          kind: entityKind,
          payload: registryEntityPayloadFixture(
            semanticContract: semanticContract,
            entityKindId: 'sample.standard',
            payloadSchemaVersion: '1',
          ),
          sourceEvidence: <SourceEvidence>[sourceEvidenceFixture()],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          kind: entityKind,
          payload: registryEntityPayloadFixture(
            semanticContract: semanticContract,
            entityKindId: 'sample.entity',
            payloadSchemaVersion: '2',
          ),
          sourceEvidence: <SourceEvidence>[sourceEvidenceFixture()],
        ),
        throwsArgumentError,
      );
    });

    test('uses stable immutable identity for entity equality', () {
      final RegistrySemanticContractIdentity semanticContract =
          registrySemanticContractFixture();
      final RegistryEntityKind kind = registryEntityKindFixture(
        semanticContract: semanticContract,
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
        payload: registryEntityPayloadFixture(
          semanticContract: semanticContract,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[sourceEvidenceFixture(startLine: 10)],
      );
      final RegistryEntity second = RegistryEntity(
        id: id,
        path: RegistryPath(<String>[
          'sample_scope',
          'sample_section',
          'sample_variant_item',
        ]),
        kind: kind,
        payload: registryEntityPayloadFixture(
          semanticContract: semanticContract,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[sourceEvidenceFixture(startLine: 20)],
      );

      expect(first, second);
      expect(first.id, second.id);
      expect(first.path, isNot(second.path));
      expect(first.sourceEvidence, isNot(second.sourceEvidence));
    });
  });
}
