import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_draft_store.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/json_file_translator_draft_store.dart';

void main() {
  late Directory directory;
  late JsonFileTranslatorDraftStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'translator_draft_store_test_',
    );
    store = JsonFileTranslatorDraftStore(
      applicationSupportDirectory: directory,
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('returns no draft when file is absent', () async {
    expect(await store.load(), isNull);
  });

  test('persists and restores exact direct report', () async {
    final TranslatorRunReport report = _report();

    await store.save(
      TranslatorDraft(sourceText: report.request.sourceText, report: report),
    );

    final TranslatorDraft? restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.sourceText, report.request.sourceText);
    expect(restored.report, report);

    final Map<String, Object?> raw = await _readState(directory);
    expect(raw['sourceLanguageHint'], isNull);
    final Map<String, Object?> persistedReport =
        (raw['report']! as Map<Object?, Object?>).cast<String, Object?>();
    final Map<String, Object?> bundle =
        (persistedReport['bundle']! as Map<Object?, Object?>)
            .cast<String, Object?>();
    expect(bundle.keys, <String>[
      'SOURCE LANGUAGE',
      'SOURCE TEXT',
      'RU',
      'EN',
      'TH',
    ]);
    expect(bundle.containsKey('EN_TO_RU'), isFalse);
  });

  test(
    'migrates legacy manual hint and reverse sections without exposing them',
    () async {
      final File file = await _stateFile(directory);
      await file.parent.create(recursive: true);
      final TranslatorRunReport report = _report();

      await file.writeAsString(
        '${jsonEncode(<String, Object?>{
          'version': 'v1',
          'sourceText': report.request.sourceText,
          'sourceLanguageHint': 'RU',
          'report': <String, Object?>{
            'request': <String, Object?>{'sourceText': report.request.sourceText, 'sourceLanguageHint': 'RU', 'engineerContext': null},
            'bundle': <String, Object?>{...report.bundle.directSections, 'EN_TO_RU': 'Старый обратный текст.', 'TH_TO_RU': 'Старый обратный текст.', 'EN_TO_TH': 'ข้อความย้อนกลับเดิม', 'TH_TO_EN': 'Old reverse text.'},
            'audit': <String, Object?>{'meaningFindings': <String>[], 'terminologyFindings': <String>[], 'styleFindings': <String>[], 'ambiguityFindings': <String>[]},
            'createdAt': report.createdAt.toIso8601String(),
          },
        })}\n',
      );

      final TranslatorDraft? migrated = await store.load();

      expect(migrated, isNotNull);
      expect(migrated!.sourceText, report.request.sourceText);
      expect(
        migrated.report?.bundle.directSections,
        report.bundle.directSections,
      );
    },
  );

  test('clear removes only Translator draft file', () async {
    await store.save(const TranslatorDraft(sourceText: 'Черновик.'));
    final File unrelated = File('${directory.path}/unrelated.txt');
    await unrelated.writeAsString('keep');

    await store.clear();

    expect(await store.load(), isNull);
    expect(await unrelated.readAsString(), 'keep');
  });

  test('rejects malformed persisted state instead of silent reset', () async {
    final File file = await _stateFile(directory);
    await file.parent.create(recursive: true);
    await file.writeAsString('{"version":"v1"}\n');

    await expectLater(store.load(), throwsFormatException);
  });
}

TranslatorRunReport _report() {
  final TranslatorWorkRequest request = TranslatorWorkRequest(
    sourceText: 'Исходный текст.',
  );

  return TranslatorRunReport(
    request: request,
    bundle: TranslationBundle(
      sourceLanguage: TranslationLanguage.ru,
      sourceText: request.sourceText,
      ru: request.sourceText,
      en: 'Provider wording.',
      th: 'ข้อความจากผู้ให้บริการ',
    ),
    audit: TranslationAudit(),
    createdAt: DateTime.utc(2026, 7, 26, 6),
  );
}

Future<File> _stateFile(Directory directory) async {
  return File(
    '${directory.path}${Platform.pathSeparator}'
    '${JsonFileTranslatorDraftStore.directoryName}'
    '${Platform.pathSeparator}'
    '${JsonFileTranslatorDraftStore.fileName}',
  );
}

Future<Map<String, Object?>> _readState(Directory directory) async {
  final File file = await _stateFile(directory);
  return (jsonDecode(await file.readAsString()) as Map<Object?, Object?>)
      .cast<String, Object?>();
}
