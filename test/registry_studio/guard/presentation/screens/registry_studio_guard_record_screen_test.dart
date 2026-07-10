import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/guard/domain/registry_studio_guard_record_payload.dart';
import 'package:helpy_translator/registry_studio/guard/presentation/screens/registry_studio_guard_record_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

import '../../../core/fixtures/registry_entity_fixture.dart';

void main() {
  testWidgets('shows Guard record semantics and source evidence', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegistryStudioGuardRecordScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          entity: _guardRecordEntity(),
        ),
      ),
    );

    expect(
      find.byKey(RegistryStudioGuardRecordScreen.recordCardKey),
      findsOneWidget,
    );
    expect(find.text('Тип записи:\nownershipAudit'), findsOneWidget);
    expect(
      find.text('Заголовок:\nOwnership-аудит Guard record'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Краткое описание:\n'
        'Guard-specific semantic content.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Registry_Studio_Clean_Rebuild_Guard_v1.md'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Fingerprint источника:\n'
        'fnv1a64:0123456789abcdef',
      ),
      findsOneWidget,
    );
    expect(find.text('Диапазон строк:\n4459–4588'), findsOneWidget);
  });

  test('rejects RegistryEntity with another payload contract', () {
    expect(
      () => RegistryStudioGuardRecordScreen(
        uiLanguage: RegistryStudioUiLanguage.ru,
        entity: registryEntityFixture(id: 'non-guard-entity'),
      ),
      throwsArgumentError,
    );
  });
}

RegistryEntity _guardRecordEntity() {
  return RegistryEntity(
    id: RegistryEntityId('registry-studio-guard-record'),
    path: RegistryPath(const <String>[
      'registry_studio',
      'guard',
      'source_contract_foundation',
    ]),
    payload: RegistryStudioGuardRecordPayload(
      recordType: RegistryStudioGuardRecordType.ownershipAudit,
      heading: 'Ownership-аудит Guard record',
      summary: 'Guard-specific semantic content.',
    ),
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath:
            'docs/architecture/registry_studio/'
            'Registry_Studio_Clean_Rebuild_Guard_v1.md',
        sourceSnapshotFingerprint: 'fnv1a64:0123456789abcdef',
        headingPath: const <String>['Ownership-аудит Guard record'],
        startLine: 4459,
        endLine: 4588,
      ),
    ],
  );
}
