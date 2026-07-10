import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

import '../fixtures/registry_entity_fixture.dart';

void main() {
  group('RegistryEntity', () {
    test('derives its kind from a source-backed payload', () {
      final RegistryEntityKind kind = registryEntityKindFixture(
        semanticContract: registrySemanticContractFixture(),
      );
      final payload = registryEntityPayloadFixture(kind: kind);
      final SourceEvidence evidence = sourceEvidenceFixture();

      final RegistryEntity entity = RegistryEntity(
        id: RegistryEntityId('registry-entity-001'),
        path: RegistryPath(<String>[
          'sample_scope',
          'sample_section',
          'sample_item',
        ]),
        payload: payload,
        sourceEvidence: <SourceEvidence>[evidence],
      );

      expect(entity.id.value, 'registry-entity-001');
      expect(entity.kind, same(kind));
      expect(entity.kind, same(payload.kind));
      expect(entity.payload, same(payload));
      expect(entity.sourceEvidence, <SourceEvidence>[evidence]);
      expect(() => entity.sourceEvidence.add(evidence), throwsUnsupportedError);
    });

    test('rejects an entity without source evidence', () {
      final RegistryEntityKind kind = registryEntityKindFixture(
        semanticContract: registrySemanticContractFixture(),
      );

      expect(
        () => RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['sample_scope', 'sample_section']),
          payload: registryEntityPayloadFixture(kind: kind),
          sourceEvidence: const <SourceEvidence>[],
        ),
        throwsArgumentError,
      );
    });

    test('uses stable immutable identity for entity equality', () {
      final RegistryEntityKind kind = registryEntityKindFixture(
        semanticContract: registrySemanticContractFixture(),
      );
      final RegistryEntityId id = RegistryEntityId('registry-entity-001');

      final RegistryEntity first = RegistryEntity(
        id: id,
        path: RegistryPath(<String>[
          'sample_scope',
          'sample_section',
          'sample_item',
        ]),
        payload: registryEntityPayloadFixture(kind: kind),
        sourceEvidence: <SourceEvidence>[sourceEvidenceFixture(startLine: 10)],
      );

      final RegistryEntity second = RegistryEntity(
        id: id,
        path: RegistryPath(<String>[
          'sample_scope',
          'sample_section',
          'sample_variant_item',
        ]),
        payload: registryEntityPayloadFixture(kind: kind),
        sourceEvidence: <SourceEvidence>[sourceEvidenceFixture(startLine: 20)],
      );

      expect(first, second);
      expect(first.id, second.id);
      expect(first.path, isNot(second.path));
      expect(first.sourceEvidence, isNot(second.sourceEvidence));
    });
  });
}
