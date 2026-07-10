import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/guard/application/create_registry_studio_guard_record_entity.dart';
import 'package:helpy_translator/registry_studio/guard/domain/registry_studio_guard_record_payload.dart';

void main() {
  group('CreateRegistryStudioGuardRecordEntity', () {
    test('creates a source-backed Registry Studio Guard record entity', () {
      final CreateRegistryStudioGuardRecordEntity createEntity =
          CreateRegistryStudioGuardRecordEntity();

      final entity = createEntity(
        id: 'guard.record.related_context_runtime_connection',
        pathSegments: <String>[
          'registry_studio',
          'guard',
          'related_context_runtime_connection',
        ],
        recordType: RegistryStudioGuardRecordType.ownershipAudit,
        heading: 'Ownership-аудит related context runtime connection',
        summary: 'Direct runtime connection related context отклонён.',
        sourceDocumentPath:
            'docs/architecture/registry_studio/Registry_Studio_Clean_Rebuild_Guard_v1.md',
        sourceSnapshotFingerprint: 'sha256:guard-clean-rebuild',
        sourceHeadingPath: <String>[
          'Registry Studio Clean Rebuild Guard',
          'Ownership-аудит related context runtime connection',
        ],
        sourceStartLine: 4385,
        sourceEndLine: 4410,
      );

      expect(
        entity.id.value,
        'guard.record.related_context_runtime_connection',
      );
      expect(entity.path.segments, <String>[
        'registry_studio',
        'guard',
        'related_context_runtime_connection',
      ]);
      expect(
        entity.kind.semanticContract,
        RegistryStudioGuardRecordPayload.semanticContractIdentity,
      );
      expect(
        entity.kind.kindId,
        RegistryStudioGuardRecordPayload.entityKindIdentifier,
      );
      expect(
        entity.kind.schemaVersion,
        RegistryStudioGuardRecordPayload.schemaVersion,
      );

      expect(entity.payload, isA<RegistryStudioGuardRecordPayload>());

      final RegistryStudioGuardRecordPayload payload =
          entity.payload as RegistryStudioGuardRecordPayload;

      expect(payload.recordType, RegistryStudioGuardRecordType.ownershipAudit);
      expect(
        payload.heading,
        'Ownership-аудит related context runtime connection',
      );
      expect(
        payload.summary,
        'Direct runtime connection related context отклонён.',
      );

      expect(entity.sourceEvidence, hasLength(1));

      final SourceEvidence evidence = entity.sourceEvidence.single;

      expect(
        evidence.sourceDocumentPath,
        'docs/architecture/registry_studio/Registry_Studio_Clean_Rebuild_Guard_v1.md',
      );
      expect(evidence.sourceSnapshotFingerprint, 'sha256:guard-clean-rebuild');
      expect(evidence.headingPath, <String>[
        'Registry Studio Clean Rebuild Guard',
        'Ownership-аудит related context runtime connection',
      ]);
      expect(evidence.startLine, 4385);
      expect(evidence.endLine, 4410);
    });

    test(
      'normalizes explicit input through core value objects and payload',
      () {
        final CreateRegistryStudioGuardRecordEntity createEntity =
            CreateRegistryStudioGuardRecordEntity();

        final entity = createEntity(
          id: '  guard.record.payload_checkpoint  ',
          pathSegments: <String>[
            ' registry_studio ',
            ' guard ',
            ' payload_checkpoint ',
          ],
          recordType: RegistryStudioGuardRecordType.checkpoint,
          heading: '  Guard record payload checkpoint  ',
          summary: '  Payload был подтверждён успешным Build APK.  ',
          sourceDocumentPath: ' docs/architecture/guard.md ',
          sourceSnapshotFingerprint: ' sha256:payload ',
          sourceHeadingPath: <String>[' Guard ', ' Payload checkpoint '],
          sourceStartLine: 10,
          sourceEndLine: 12,
        );

        expect(entity.id.value, 'guard.record.payload_checkpoint');
        expect(entity.path.segments, <String>[
          'registry_studio',
          'guard',
          'payload_checkpoint',
        ]);

        final RegistryStudioGuardRecordPayload payload =
            entity.payload as RegistryStudioGuardRecordPayload;

        expect(payload.heading, 'Guard record payload checkpoint');
        expect(payload.summary, 'Payload был подтверждён успешным Build APK.');

        final SourceEvidence evidence = entity.sourceEvidence.single;

        expect(evidence.sourceDocumentPath, 'docs/architecture/guard.md');
        expect(evidence.sourceSnapshotFingerprint, 'sha256:payload');
        expect(evidence.headingPath, <String>['Guard', 'Payload checkpoint']);
      },
    );

    test('rejects invalid entity identity through core validation', () {
      final CreateRegistryStudioGuardRecordEntity createEntity =
          CreateRegistryStudioGuardRecordEntity();

      expect(
        () => createEntity(
          id: '   ',
          pathSegments: <String>['registry_studio', 'guard'],
          recordType: RegistryStudioGuardRecordType.restriction,
          heading: 'Runtime connection restriction',
          summary: 'Runtime connection запрещён.',
          sourceDocumentPath: 'docs/architecture/guard.md',
          sourceSnapshotFingerprint: 'sha256:guard',
          sourceHeadingPath: <String>['Guard', 'Restriction'],
          sourceStartLine: 1,
          sourceEndLine: 2,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid source evidence through core validation', () {
      final CreateRegistryStudioGuardRecordEntity createEntity =
          CreateRegistryStudioGuardRecordEntity();

      expect(
        () => createEntity(
          id: 'guard.record.invalid_source',
          pathSegments: <String>['registry_studio', 'guard'],
          recordType: RegistryStudioGuardRecordType.restriction,
          heading: 'Invalid source evidence',
          summary: 'Source evidence line range is invalid.',
          sourceDocumentPath: 'docs/architecture/guard.md',
          sourceSnapshotFingerprint: 'sha256:guard',
          sourceHeadingPath: <String>['Guard', 'Restriction'],
          sourceStartLine: 10,
          sourceEndLine: 9,
        ),
        throwsArgumentError,
      );
    });
  });
}
