import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/localization/registry_studio_localizations.dart';

void main() {
  test('audit coverage is localized for prototype and blind consensus', () {
    const RegistryStudioLocalizations ru = RegistryStudioLocalizations(
      Locale('ru'),
    );
    const RegistryStudioLocalizations en = RegistryStudioLocalizations(
      Locale('en'),
    );
    const RegistryStudioLocalizations th = RegistryStudioLocalizations(
      Locale('th'),
    );

    expect(
      ru.auditCoverageLabel('prototype', 6),
      'Прототипная проверка — 6 маршрутов',
    );
    expect(en.auditCoverageLabel('prototype', 6), 'Prototype audit — 6 routes');
    expect(
      th.auditCoverageLabel('prototype', 6),
      'การตรวจสอบแบบต้นแบบ — 6 เส้นทาง',
    );

    expect(
      ru.auditCoverageLabel('blindConsensus', 6),
      'Слепая согласованная проверка — 6 маршрутов',
    );
    expect(
      en.auditCoverageLabel('blindConsensus', 6),
      'Blind consensus audit — 6 routes',
    );
    expect(
      th.auditCoverageLabel('blindConsensus', 6),
      'การตรวจสอบแบบแยกข้อมูล — 6 เส้นทาง',
    );
  });

  test('expanded coverage describes independent route audits', () {
    const RegistryStudioLocalizations ru = RegistryStudioLocalizations(
      Locale('ru'),
    );
    const RegistryStudioLocalizations en = RegistryStudioLocalizations(
      Locale('en'),
    );
    const RegistryStudioLocalizations th = RegistryStudioLocalizations(
      Locale('th'),
    );

    expect(
      ru.auditCoverageLabel('expanded', 6),
      'Независимая проверка маршрутов — 6 маршрутов',
    );
    expect(
      en.auditCoverageLabel('expanded', 6),
      'Independent route audit — 6 routes',
    );
    expect(
      th.auditCoverageLabel('expanded', 6),
      'การตรวจสอบเส้นทางแบบอิสระ — 6 เส้นทาง',
    );
  });

  test('disclosure states the active thirteen-to-nineteen-call topology', () {
    const RegistryStudioLocalizations ru = RegistryStudioLocalizations(
      Locale('ru'),
    );
    const RegistryStudioLocalizations en = RegistryStudioLocalizations(
      Locale('en'),
    );
    const RegistryStudioLocalizations th = RegistryStudioLocalizations(
      Locale('th'),
    );

    expect(ru.auditPassDisclosure, contains('13 базовых API-вызовов'));
    expect(ru.auditPassDisclosure, contains('максимум — 19 API-вызовов'));
    expect(
      ru.auditPassDisclosure,
      contains('не более одного локального корректирующего повтора'),
    );
    expect(
      ru.auditPassDisclosure,
      contains('Ошибки провайдера автоматически не повторяются'),
    );

    expect(en.auditPassDisclosure, contains('13 base API calls'));
    expect(en.auditPassDisclosure, contains('maximum is 19 API calls'));
    expect(
      en.auditPassDisclosure,
      contains('at most one local corrective retry'),
    );
    expect(
      en.auditPassDisclosure,
      contains('Provider failures are not retried automatically'),
    );

    expect(th.auditPassDisclosure, contains('13 ครั้ง'));
    expect(th.auditPassDisclosure, contains('สูงสุดคือ 19 คำขอ API'));
    expect(th.auditPassDisclosure, contains('ไม่เกินหนึ่งครั้ง'));
  });

  test('new evidence limitations are localized', () {
    const RegistryStudioLocalizations ru = RegistryStudioLocalizations(
      Locale('ru'),
    );
    const RegistryStudioLocalizations en = RegistryStudioLocalizations(
      Locale('en'),
    );
    const RegistryStudioLocalizations th = RegistryStudioLocalizations(
      Locale('th'),
    );

    const List<String> codes = <String>[
      'SEMANTIC_ANALYSIS_UNRESOLVED',
      'AUDIT_EVIDENCE_CONFLICT',
      'AUDIT_VERIFIER_UNRESOLVED',
      'AUDIT_EVIDENCE_CONTRACT_REJECTED',
      'AUDIT_PROVIDER_HTTP_400',
      'AUDIT_PROVIDER_HTTP_503',
    ];

    for (final String code in codes) {
      expect(ru.auditLimitationLabel(code), isNot(contains(code)));
      expect(en.auditLimitationLabel(code), isNot(contains(code)));
      expect(th.auditLimitationLabel(code), isNot(contains(code)));
    }
  });
}
