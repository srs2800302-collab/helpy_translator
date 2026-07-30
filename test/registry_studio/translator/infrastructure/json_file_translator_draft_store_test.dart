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

  test('writes v3 Russian-only compatibility evidence schema', () async {
    final TranslatorRunReport report = _report();

    await store.save(
      TranslatorDraft(
        sourceText: report.request.sourceText,
        sourceLanguageHint: TranslationLanguage.ru,
        report: report,
      ),
    );

    final Map<String, Object?> state =
        (jsonDecode(await _stateFile(directory).readAsString())
                as Map<Object?, Object?>)
            .cast<String, Object?>();
    final Map<String, Object?> encodedReport =
        (state['report']! as Map<Object?, Object?>).cast<String, Object?>();
    final Map<String, Object?> audit =
        (encodedReport['audit']! as Map<Object?, Object?>)
            .cast<String, Object?>();
    final List<Object?> findings = audit['findings']! as List<Object?>;

    expect(state['version'], 'v3');
    expect(audit.keys.toList(growable: false), <String>['findings']);
    expect(findings, hasLength(1));
    expect((findings.single as Map<Object?, Object?>)['kind'], 'russianOnly');
  });

  test('removes v2 evidence outside the stored bundle', () async {
    final TranslatorRunReport report = _report();
    await store.save(
      TranslatorDraft(
        sourceText: report.request.sourceText,
        sourceLanguageHint: TranslationLanguage.ru,
        report: report,
      ),
    );

    final File file = _stateFile(directory);
    final Map<String, Object?> state =
        (jsonDecode(await file.readAsString()) as Map<Object?, Object?>)
            .cast<String, Object?>();
    final Map<String, Object?> encodedReport =
        (state['report']! as Map<Object?, Object?>).cast<String, Object?>();
    final Map<String, Object?> audit =
        (encodedReport['audit']! as Map<Object?, Object?>)
            .cast<String, Object?>();
    final List<Object?> findings = audit['findings']! as List<Object?>;
    final Map<String, Object?> finding =
        (findings.single as Map<Object?, Object?>).cast<String, Object?>();

    finding['sourceFragment'] = 'Фрагмент отсутствует';
    await file.writeAsString('${jsonEncode(state)}\n');

    await expectLater(store.load(), throwsFormatException);
    expect(await file.exists(), isFalse);
  });

  test('writes and restores v3 multilingual evidence', () async {
    final TranslatorRunReport base = _report();
    final TranslatorRunReport report = TranslatorRunReport(
      request: base.request,
      bundle: base.bundle,
      audit: TranslationAudit(
        findings: <TranslationFinding>[
          TranslationFinding.multilingual(
            category: TranslationFindingCategory.style,
            section: TranslationLanguage.en,
            sourceFragment: 'Исходный',
            translationFragment: 'Source',
            reason: LocalizedEvidenceText(
              ru: 'Русское объяснение.',
              en: 'English explanation.',
              th: 'คำอธิบายภาษาไทย',
            ),
            impact: LocalizedEvidenceText(
              ru: 'Русское влияние.',
              en: 'English impact.',
              th: 'ผลกระทบภาษาไทย',
            ),
            correctVariant: 'Source text.',
            sourceAmbiguity: null,
          ),
        ],
      ),
      createdAt: base.createdAt,
    );

    await store.save(
      TranslatorDraft(sourceText: report.request.sourceText, report: report),
    );

    final File stateFile = _stateFile(directory);
    final Map<String, Object?> state =
        (jsonDecode(await stateFile.readAsString()) as Map<Object?, Object?>)
            .cast<String, Object?>();
    final Map<String, Object?> encodedReport =
        (state['report']! as Map<Object?, Object?>).cast<String, Object?>();
    final Map<String, Object?> audit =
        (encodedReport['audit']! as Map<Object?, Object?>)
            .cast<String, Object?>();
    final Map<String, Object?> finding =
        ((audit['findings']! as List<Object?>).single as Map<Object?, Object?>)
            .cast<String, Object?>();
    final Map<String, Object?> reason =
        (finding['reason']! as Map<Object?, Object?>).cast<String, Object?>();

    expect(state['version'], 'v3');
    expect(finding['kind'], 'multilingual');
    expect(reason.keys.toSet(), <String>{'ru', 'en', 'th'});
    expect(finding['sourceAmbiguity'], isNull);
    expect((await store.load())!.report, report);
  });

  test(
    'loads v2 structured evidence as Russian-only compatibility data',
    () async {
      final TranslatorRunReport report = _report();

      await store.save(
        TranslatorDraft(sourceText: report.request.sourceText, report: report),
      );

      final File stateFile = _stateFile(directory);
      final Map<String, Object?> state =
          (jsonDecode(await stateFile.readAsString()) as Map<Object?, Object?>)
              .cast<String, Object?>();
      final Map<String, Object?> encodedReport =
          (state['report']! as Map<Object?, Object?>).cast<String, Object?>();
      final Map<String, Object?> audit =
          (encodedReport['audit']! as Map<Object?, Object?>)
              .cast<String, Object?>();
      final Map<String, Object?> finding =
          ((audit['findings']! as List<Object?>).single
                  as Map<Object?, Object?>)
              .cast<String, Object?>();

      state['version'] = 'v2';
      finding['kind'] = 'structured';
      await stateFile.writeAsString('${jsonEncode(state)}\n');

      final TranslatorDraft? restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.report!.audit.findings.single.isRussianOnly, isTrue);
      expect(restored.report!.audit.findings.single.isMultilingual, isFalse);
    },
  );

  test('removes malformed v3 localized evidence drafts', () async {
    final File unrelated = File('${directory.path}/unrelated-v3.json');
    await unrelated.writeAsString('keep');

    final List<void Function(Map<String, Object?>)> corruptions =
        <void Function(Map<String, Object?>)>[
          (Map<String, Object?> finding) {
            finding['reason'] = 'Причина строкой';
          },
          (Map<String, Object?> finding) {
            finding['reason'] = <String, Object?>{
              'ru': 'Причина.',
              'en': 'Reason.',
            };
          },
          (Map<String, Object?> finding) {
            finding['reason'] = <String, Object?>{
              'ru': 'Причина.',
              'en': 'Reason.',
              'th': 'เหตุผล',
              'de': 'Grund',
            };
          },
          (Map<String, Object?> finding) {
            finding['reason'] = <String, Object?>{
              'ru': 'Причина.',
              'en': '',
              'th': 'เหตุผล',
            };
          },
          (Map<String, Object?> finding) {
            finding['reason'] = <String, Object?>{
              'ru': 'Причина.',
              'en': ' Reason. ',
              'th': 'เหตุผล',
            };
          },
          (Map<String, Object?> finding) {
            finding['sourceAmbiguity'] = 'NONE';
          },
          (Map<String, Object?> finding) {
            finding['sourceAmbiguity'] = <String, Object?>{
              'ru': 'Неоднозначность.',
              'en': 'Ambiguity.',
            };
          },
        ];

    for (final void Function(Map<String, Object?>) corrupt in corruptions) {
      final TranslatorRunReport report = _report();
      await store.save(
        TranslatorDraft(sourceText: report.request.sourceText, report: report),
      );

      final File stateFile = _stateFile(directory);
      final File temporaryFile = File('${stateFile.path}.tmp');
      final Map<String, Object?> state =
          (jsonDecode(await stateFile.readAsString()) as Map<Object?, Object?>)
              .cast<String, Object?>();
      final Map<String, Object?> encodedReport =
          (state['report']! as Map<Object?, Object?>).cast<String, Object?>();
      final Map<String, Object?> audit =
          (encodedReport['audit']! as Map<Object?, Object?>)
              .cast<String, Object?>();
      final Map<String, Object?> finding =
          ((audit['findings']! as List<Object?>).single
                  as Map<Object?, Object?>)
              .cast<String, Object?>();

      finding['kind'] = 'multilingual';
      finding['reason'] = <String, Object?>{
        'ru': 'Причина.',
        'en': 'Reason.',
        'th': 'เหตุผล',
      };
      finding['impact'] = <String, Object?>{
        'ru': 'Влияние.',
        'en': 'Impact.',
        'th': 'ผลกระทบ',
      };
      finding['sourceAmbiguity'] = null;
      corrupt(finding);

      await stateFile.writeAsString('${jsonEncode(state)}\n');
      await temporaryFile.writeAsString('partial');

      await expectLater(store.load(), throwsFormatException);

      expect(await stateFile.exists(), isFalse);
      expect(await temporaryFile.exists(), isFalse);
      expect(await unrelated.readAsString(), 'keep');
    }
  });

  test('loads valid v1 strings as explicit legacy evidence', () async {
    final TranslatorRunReport report = _report();

    await store.save(
      TranslatorDraft(
        sourceText: report.request.sourceText,
        sourceLanguageHint: TranslationLanguage.ru,
        report: report,
      ),
    );

    final File stateFile = _stateFile(directory);
    final Map<String, Object?> state =
        (jsonDecode(await stateFile.readAsString()) as Map<Object?, Object?>)
            .cast<String, Object?>();
    final Map<String, Object?> encodedReport =
        (state['report']! as Map<Object?, Object?>).cast<String, Object?>();

    state['version'] = 'v1';
    encodedReport['audit'] = <String, Object?>{
      'meaningFindings': <String>[],
      'terminologyFindings': <String>['Старое доказательство.'],
      'styleFindings': <String>[],
      'ambiguityFindings': <String>[],
    };
    await stateFile.writeAsString('${jsonEncode(state)}\n');

    final TranslatorDraft? restored = await store.load();

    expect(restored, isNotNull);
    expect(await stateFile.exists(), isTrue);
    expect(restored!.report!.audit.findings, hasLength(1));
    expect(restored.report!.audit.findings.single.isLegacy, isTrue);
    expect(restored.report!.audit.terminologyFindings, <String>[
      'Старое доказательство.',
    ]);
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

  test('removes corrupt draft and matching temporary file only', () async {
    final Directory stateDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}'
      '${JsonFileTranslatorDraftStore.directoryName}',
    );
    await stateDirectory.create(recursive: true);

    final File stateFile = File(
      '${stateDirectory.path}${Platform.pathSeparator}'
      '${JsonFileTranslatorDraftStore.fileName}',
    );
    final File temporaryFile = File('${stateFile.path}.tmp');
    final File unrelatedFile = File(
      '${stateDirectory.path}${Platform.pathSeparator}unrelated.json',
    );
    await unrelatedFile.writeAsString('keep');

    const List<String> corruptDrafts = <String>[
      '{',
      '{"version":"v1"}',
      '{"version":"v4","sourceText":"Текст.",'
          '"sourceLanguageHint":null,"report":null}',
      '{"version":"v1","sourceText":"Текст.",'
          '"sourceLanguageHint":"DE","report":null}',
      '{"version":"v1","sourceText":"Текст.",'
          '"sourceLanguageHint":null,"report":{"request":{}}}',
    ];

    for (final String corruptDraft in corruptDrafts) {
      await stateFile.writeAsString('$corruptDraft\n');
      await temporaryFile.writeAsString('partial');

      await expectLater(store.load(), throwsFormatException);

      expect(await stateFile.exists(), isFalse);
      expect(await temporaryFile.exists(), isFalse);
      expect(await unrelatedFile.readAsString(), 'keep');
      expect(await store.load(), isNull);
    }
  });
}

File _stateFile(Directory directory) {
  return File(
    '${directory.path}${Platform.pathSeparator}'
    '${JsonFileTranslatorDraftStore.directoryName}'
    '${Platform.pathSeparator}'
    '${JsonFileTranslatorDraftStore.fileName}',
  );
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
    audit: TranslationAudit(
      findings: <TranslationFinding>[
        TranslationFinding(
          category: TranslationFindingCategory.style,
          section: TranslationLanguage.en,
          sourceFragment: 'Исходный текст',
          translationFragment: 'Source text',
          reason: 'Формулировка менее канонична.',
          impact: 'Смысл сохранён.',
          correctVariant: 'Использовать каноничную формулировку.',
          sourceAmbiguity: 'NONE',
        ),
      ],
    ),
    createdAt: DateTime.utc(2026, 7, 26, 6),
  );
}
