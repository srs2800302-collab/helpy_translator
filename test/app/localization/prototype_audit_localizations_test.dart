import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/localization/registry_studio_localizations.dart';

void main() {
  test('prototype audit coverage is localized for all interface languages', () {
    expect(
      const RegistryStudioLocalizations(
        Locale('ru'),
      ).auditCoverageLabel('prototype', 6),
      'Прототипная проверка — 6 маршрутов',
    );
    expect(
      const RegistryStudioLocalizations(
        Locale('en'),
      ).auditCoverageLabel('prototype', 6),
      'Prototype audit — 6 routes',
    );
    expect(
      const RegistryStudioLocalizations(
        Locale('th'),
      ).auditCoverageLabel('prototype', 6),
      'การตรวจสอบแบบต้นแบบ — 6 เส้นทาง',
    );
  });

  test(
    'prototype audit disclosure states retry and non-independent review',
    () {
      final String disclosure = const RegistryStudioLocalizations(
        Locale('ru'),
      ).auditPassDisclosure;

      expect(disclosure, contains('отдельным запросом'));
      expect(disclosure, contains('может быть повторён один раз'));
      expect(disclosure, contains('не независимая экспертиза'));
    },
  );
}
