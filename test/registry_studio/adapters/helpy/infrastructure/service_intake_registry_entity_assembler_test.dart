import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/payloads/service_intake_payload.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_identity_manifest_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_registry_entity_assembler.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_semantic_manifest_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  const ServiceIntakeRegistryEntityAssembler assembler =
      ServiceIntakeRegistryEntityAssembler();

  group('ServiceIntakeRegistryEntityAssembler', () {
    test('assembles a source-backed RegistryEntity', () {
      final RegistryEntity entity = assembler.assemble(
        sourceBlock: _sourceBlock(),
        manifestEntry: _manifestEntry(),
        sourceDocumentPath:
            'docs/architecture/Helpy_Architecture_Registry_v1.md',
        sourceSnapshotFingerprint: 'fnv1a64:0123456789abcdef',
      );

      expect(entity.id, RegistryEntityId(_entityId));
      expect(
        entity.path,
        RegistryPath(const <String>[
          'helpy',
          'service_intake',
          'plumbing',
          'faucet',
        ]),
      );
      expect(entity.payload, isA<ServiceIntakePayload>());

      final ServiceIntakePayload payload =
          entity.payload as ServiceIntakePayload;
      expect(payload.displayName, 'Plumbing → Кран');

      final SourceEvidence evidence = entity.sourceEvidence.single;
      expect(
        evidence.sourceDocumentPath,
        'docs/architecture/Helpy_Architecture_Registry_v1.md',
      );
      expect(evidence.sourceSnapshotFingerprint, 'fnv1a64:0123456789abcdef');
      expect(evidence.headingPath, <String>['Plumbing', 'Plumbing → Кран']);
      expect(evidence.startLine, 100);
      expect(evidence.endLine, 101);
    });

    test('rejects a semantic manifest entry for another identity', () {
      expect(
        () => assembler.assemble(
          sourceBlock: _sourceBlock(),
          manifestEntry: _manifestEntry(
            entityId: 'helpy.service_intake.plumbing.toilet',
          ),
          sourceDocumentPath: 'docs/registry.md',
          sourceSnapshotFingerprint: 'fnv1a64:0123456789abcdef',
        ),
        throwsFormatException,
      );
    });
  });
}

ServiceIntakeSourceBlock _sourceBlock() {
  return (
    identity: _identity(),
    startLine: 100,
    endLine: 101,
    sourceText:
        '### Plumbing → Кран\n'
        'Описание услуги.\n',
  );
}

ServiceIntakeIdentityManifestEntry _identity() {
  return (
    entityId: RegistryEntityId(_entityId),
    path: RegistryPath(const <String>[
      'helpy',
      'service_intake',
      'plumbing',
      'faucet',
    ]),
    ownerHeadingLevel: 2,
    ownerHeading: 'Plumbing',
    headingLevel: 3,
    heading: 'Plumbing → Кран',
  );
}

ServiceIntakeSemanticManifestEntry _manifestEntry({
  String entityId = _entityId,
}) {
  return (
    entityId: RegistryEntityId(entityId),
    displayNameLocator: (expectedText: '### Plumbing → Кран', occurrence: 1),
    entrySelectors: <ServiceIntakeSemanticEntrySelector>[],
    scenarios: <ServiceIntakeSemanticScenario>[],
  );
}

const String _entityId = 'helpy.service_intake.plumbing.faucet';
