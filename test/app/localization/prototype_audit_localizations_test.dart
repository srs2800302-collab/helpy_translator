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

  test('disclosure states the hard eight-call maximum', () {
    const RegistryStudioLocalizations ru = RegistryStudioLocalizations(
      Locale('ru'),
    );
    const RegistryStudioLocalizations en = RegistryStudioLocalizations(
      Locale('en'),
    );
    const RegistryStudioLocalizations th = RegistryStudioLocalizations(
      Locale('th'),
    );

    expect(ru.auditPassDisclosure, contains('максимум восемь API-вызовов'));
    expect(
      ru.auditPassDisclosure,
      contains('Автоматические повторы запросов не выполняются'),
    );
    expect(
      ru.auditPassDisclosure,
      contains('одну модель одного API-провайдера'),
    );
    expect(
      ru.auditPassDisclosure,
      contains('не являются независимой экспертизой'),
    );

    expect(en.auditPassDisclosure, contains('at most eight API calls'));
    expect(en.auditPassDisclosure, contains('never retried automatically'));
    expect(
      en.auditPassDisclosure,
      contains('same model from one API provider'),
    );
    expect(en.auditPassDisclosure, contains('not an independent review'));

    expect(th.auditPassDisclosure, contains('รวมสูงสุดแปดคำขอ API'));
    expect(th.auditPassDisclosure, contains('ไม่ลองคำขอซ้ำโดยอัตโนมัติ'));
    expect(
      th.auditPassDisclosure,
      contains('โมเดลเดียวกันจากผู้ให้บริการ API รายเดียวกัน'),
    );
    expect(th.auditPassDisclosure, contains('ไม่ใช่การตรวจสอบอิสระ'));
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
