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

  test('persists and restores exact draft and report', () async {
    final TranslatorRunReport report = _report();

    await store.save(
      TranslatorDraft(
        sourceText: report.request.sourceText,
        sourceLanguageHint: TranslationLanguage.ru,
        report: report,
      ),
    );

    final TranslatorDraft? restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.sourceText, report.request.sourceText);
    expect(restored.sourceLanguageHint, TranslationLanguage.ru);
    expect(restored.report, report);
  });

  test('clear removes only Translator draft file', () async {
    await store.save(
      const TranslatorDraft(
        sourceText: 'Черновик.',
        sourceLanguageHint: TranslationLanguage.ru,
      ),
    );

    final File unrelated = File('${directory.path}/unrelated.txt');
    await unrelated.writeAsString('keep');

    await store.clear();

    expect(await store.load(), isNull);
    expect(await unrelated.readAsString(), 'keep');
  });

  test('rejects malformed persisted state instead of silent reset', () async {
    final Directory stateDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}'
      '${JsonFileTranslatorDraftStore.directoryName}',
    );
    await stateDirectory.create(recursive: true);

    final File stateFile = File(
      '${stateDirectory.path}${Platform.pathSeparator}'
      '${JsonFileTranslatorDraftStore.fileName}',
    );
    await stateFile.writeAsString('{"version":"v1"}\n');

    await expectLater(store.load(), throwsFormatException);
  });
}

TranslatorRunReport _report() {
  final TranslatorWorkRequest request = TranslatorWorkRequest(
    sourceText: 'Исходный текст.',
    sourceLanguageHint: TranslationLanguage.ru,
  );

  final TranslationBundle bundle = TranslationBundle(
    sourceLanguage: TranslationLanguage.ru,
    sourceText: request.sourceText,
    ru: request.sourceText,
    en: 'Source text.',
    th: 'ข้อความต้นฉบับ',
    enToRu: request.sourceText,
    thToRu: request.sourceText,
    enToTh: 'ข้อความต้นฉบับ',
    thToEn: 'Source text.',
  );

  return TranslatorRunReport(
    request: request,
    bundle: bundle,
    audit: TranslationAudit(),
    createdAt: DateTime.utc(2026, 7, 26, 6),
  );
}
