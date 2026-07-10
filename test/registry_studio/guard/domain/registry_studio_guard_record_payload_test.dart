import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/guard/domain/registry_studio_guard_record_payload.dart';

void main() {
  group('RegistryStudioGuardRecordPayload', () {
    test('exposes RegistryEntityPayload contract values', () {
      final RegistryStudioGuardRecordPayload payload =
          RegistryStudioGuardRecordPayload(
            recordType: RegistryStudioGuardRecordType.decision,
            heading: 'Решение по source ownership для RegistryEntity',
            summary: 'RegistryEntity является source-backed registry unit.',
          );

      expect(
        payload.semanticContract.contractId,
        'registry_studio.guard_record',
      );
      expect(payload.semanticContract.version, '1');
      expect(payload.entityKindId, 'registry_studio.guard_record');
      expect(payload.payloadSchemaVersion, '1');
    });

    test('keeps guard record content as read-only payload fields', () {
      final RegistryStudioGuardRecordPayload payload =
          RegistryStudioGuardRecordPayload(
            recordType: RegistryStudioGuardRecordType.ownershipAudit,
            heading: '  Ownership-аудит related context runtime connection  ',
            summary: '  Direct runtime connection related context отклонён.  ',
          );

      expect(payload.recordType, RegistryStudioGuardRecordType.ownershipAudit);
      expect(
        payload.heading,
        'Ownership-аудит related context runtime connection',
      );
      expect(
        payload.summary,
        'Direct runtime connection related context отклонён.',
      );
    });

    test('supports value equality', () {
      final RegistryStudioGuardRecordPayload first =
          RegistryStudioGuardRecordPayload(
            recordType: RegistryStudioGuardRecordType.checkpoint,
            heading: 'Build APK # related context preparation screen success',
            summary: 'Related context preparation screen закрыт успешным CI.',
          );

      final RegistryStudioGuardRecordPayload second =
          RegistryStudioGuardRecordPayload(
            recordType: RegistryStudioGuardRecordType.checkpoint,
            heading: 'Build APK # related context preparation screen success',
            summary: 'Related context preparation screen закрыт успешным CI.',
          );

      expect(first, second);
    });

    test('rejects empty heading', () {
      expect(
        () => RegistryStudioGuardRecordPayload(
          recordType: RegistryStudioGuardRecordType.restriction,
          heading: '   ',
          summary: 'Runtime connection запрещён.',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty summary', () {
      expect(
        () => RegistryStudioGuardRecordPayload(
          recordType: RegistryStudioGuardRecordType.restriction,
          heading: 'Запрет runtime connection',
          summary: '   ',
        ),
        throwsArgumentError,
      );
    });
  });
}
