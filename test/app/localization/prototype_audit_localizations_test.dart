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

  test(
    'blind consensus disclosure states isolation and provider limitation',
    () {
      const RegistryStudioLocalizations ru = RegistryStudioLocalizations(
        Locale('ru'),
      );
      const RegistryStudioLocalizations en = RegistryStudioLocalizations(
        Locale('en'),
      );
      const RegistryStudioLocalizations th = RegistryStudioLocalizations(
        Locale('th'),
      );

      final String ruDisclosure = ru.auditPassDisclosure;
      expect(
        ruDisclosure,
        contains('тремя изолированными автоматическими запросами'),
      );
      expect(ruDisclosure, contains('дополнительная слепая проверка'));
      expect(ruDisclosure, contains('не видят выводы друг друга'));
      expect(ruDisclosure, contains('одного API-провайдера'));
      expect(ruDisclosure, contains('не независимая экспертиза'));

      final String enDisclosure = en.auditPassDisclosure;
      expect(enDisclosure, contains('three isolated automated requests'));
      expect(enDisclosure, contains('an additional blind check'));
      expect(enDisclosure, contains("do not see one another's conclusions"));
      expect(enDisclosure, contains('one API provider'));
      expect(enDisclosure, contains('not an independent review'));

      final String thDisclosure = th.auditPassDisclosure;
      expect(thDisclosure, contains('คำขออัตโนมัติที่แยกจากกันสามรายการ'));
      expect(thDisclosure, contains('ตรวจสอบเฉพาะเส้นทางที่ขัดแย้งเพิ่มเติม'));
      expect(thDisclosure, contains('ผู้ตรวจสอบไม่เห็นผลของกันและกัน'));
      expect(thDisclosure, contains('ผู้ให้บริการ API รายเดียวกัน'));
      expect(thDisclosure, contains('ไม่ใช่การตรวจสอบโดยผู้เชี่ยวชาญอิสระ'));
    },
  );
}
