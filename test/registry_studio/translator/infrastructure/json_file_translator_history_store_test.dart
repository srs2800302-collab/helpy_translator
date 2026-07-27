import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/json_file_translator_history_store.dart';

void main() {
  late Directory temporaryDirectory;
  late JsonFileTranslatorHistoryStore store;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'translator_history_store_test_',
    );
    store = JsonFileTranslatorHistoryStore(
      applicationSupportDirectory: temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('saves and restores ordered entries without deduplication', () async {
    final TranslatorHistoryEntry first = TranslatorHistoryEntry(
      id: 'first',
      report: _report(DateTime.utc(2026, 7, 27, 10)),
    );
    final TranslatorHistoryEntry second = TranslatorHistoryEntry(
      id: 'second',
      report: _report(DateTime.utc(2026, 7, 27, 11)),
    );

    await store.save(<TranslatorHistoryEntry>[second, first]);

    final List<TranslatorHistoryEntry> restored = await store.load();

    expect(restored, <TranslatorHistoryEntry>[second, first]);
    expect(restored[0].sourceText, restored[1].sourceText);
  });

  test('writes exact versioned schema atomically', () async {
    final TranslatorHistoryEntry entry = TranslatorHistoryEntry(
      id: 'entry',
      report: _report(DateTime.utc(2026, 7, 27, 12)),
    );

    await store.save(<TranslatorHistoryEntry>[entry]);

    final File file = File(
      '${temporaryDirectory.path}'
      '${Platform.pathSeparator}'
      '${JsonFileTranslatorHistoryStore.directoryName}'
      '${Platform.pathSeparator}'
      '${JsonFileTranslatorHistoryStore.fileName}',
    );
    final Map<String, Object?> decoded =
        (jsonDecode(await file.readAsString()) as Map<Object?, Object?>)
            .cast<String, Object?>();

    expect(decoded.keys.toSet(), <String>{'version', 'entries'});
    expect(decoded['version'], 'v1');
    expect(decoded['entries'], isA<List<Object?>>());
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('rejects duplicate identifiers before writing', () async {
    final TranslatorRunReport report = _report(DateTime.utc(2026, 7, 27, 13));

    await expectLater(
      store.save(<TranslatorHistoryEntry>[
        TranslatorHistoryEntry(id: 'duplicate', report: report),
        TranslatorHistoryEntry(id: 'duplicate', report: report),
      ]),
      throwsArgumentError,
    );
  });

  test('clear removes history and temporary file', () async {
    await store.save(<TranslatorHistoryEntry>[
      TranslatorHistoryEntry(
        id: 'entry',
        report: _report(DateTime.utc(2026, 7, 27, 14)),
      ),
    ]);

    await store.clear();

    expect(await store.load(), isEmpty);
  });

  test('rejects malformed history schema', () async {
    final File file = File(
      '${temporaryDirectory.path}'
      '${Platform.pathSeparator}'
      '${JsonFileTranslatorHistoryStore.directoryName}'
      '${Platform.pathSeparator}'
      '${JsonFileTranslatorHistoryStore.fileName}',
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(<String, Object?>{
        'version': 'v1',
        'entries': <Object?>[
          <String, Object?>{'id': 'broken', 'report': <String, Object?>{}},
        ],
      }),
    );

    expect(store.load(), throwsFormatException);
  });
}

TranslatorRunReport _report(DateTime createdAt) {
  final TranslatorWorkRequest request = TranslatorWorkRequest(
    sourceText: 'Одинаковая фраза.',
  );

  return TranslatorRunReport(
    request: request,
    bundle: TranslationBundle(
      sourceLanguage: TranslationLanguage.ru,
      sourceText: request.sourceText,
      ru: request.sourceText,
      en: 'Same phrase.',
      th: 'วลีเดียวกัน',
      reverseTranslations: ReverseTranslationBundle(
        enToRu: request.sourceText,
        thToRu: request.sourceText,
        enToTh: 'วลีเดียวกัน',
        thToEn: 'Same phrase.',
      ),
    ),
    audit: TranslationAudit(),
    createdAt: createdAt,
  );
}
