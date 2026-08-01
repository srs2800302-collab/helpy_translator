import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_draft_store.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/json_file_translator_draft_store.dart';

void main() {
  late Directory tempDirectory;
  late JsonFileTranslatorDraftStore store;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'registry-studio-translator-store-',
    );
    store = JsonFileTranslatorDraftStore(
      applicationSupportDirectory: tempDirectory,
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'round-trips v5 semantic exact report without reverse sections',
    () async {
      final TranslatorRunReport report = _report(audit: _exactAudit());
      final TranslatorDraft draft = TranslatorDraft(
        sourceText: report.request.sourceText,
        sourceLanguageHint: TranslationLanguage.ru,
        report: report,
      );

      await store.save(draft);

      final File file = _draftFile(tempDirectory);
      final Map<String, Object?> encoded =
          (jsonDecode(await file.readAsString()) as Map<Object?, Object?>)
              .cast<String, Object?>();
      final Map<String, Object?> encodedReport =
          (encoded['report']! as Map<Object?, Object?>).cast<String, Object?>();
      final Map<String, Object?> encodedBundle =
          (encodedReport['bundle']! as Map<Object?, Object?>)
              .cast<String, Object?>();

      expect(encoded['version'], 'v5');
      expect(encodedBundle.keys, <String>[
        'SOURCE LANGUAGE',
        'SOURCE TEXT',
        'RU',
        'EN',
        'TH',
      ]);

      final TranslatorDraft? restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.report, report);
      expect(restored.report!.audit.verdict, TranslationVerdict.exact);
      expect(restored.report!.bundle.hasReverseDiagnostics, isFalse);
    },
  );

  test('round-trip preserves accepted provider bundle exactly', () async {
    const String source = 'Маркер  RU — №17';
    const String en = 'Provider  EN — #17';
    const String th = 'ผู้ให้บริการ  TH — 17';

    final TranslatorWorkRequest request = TranslatorWorkRequest(
      sourceText: source,
      sourceLanguageHint: TranslationLanguage.ru,
    );

    final TranslatorRunReport report = TranslatorRunReport(
      request: request,
      bundle: TranslationBundle(
        sourceLanguage: TranslationLanguage.ru,
        sourceText: source,
        ru: source,
        en: en,
        th: th,
      ),
      audit: TranslationAudit(protocolFallback: true),
      createdAt: DateTime.utc(2026, 8, 1, 2),
    );

    await store.save(TranslatorDraft(sourceText: source, report: report));

    final TranslatorDraft restored = (await store.load())!;

    expect(restored.report!.bundle.sourceText, source);
    expect(restored.report!.bundle.ru, source);
    expect(restored.report!.bundle.en, en);
    expect(restored.report!.bundle.th, th);
  });

  test('round-trips protocol fallback as needs review', () async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(protocolFallback: true),
    );

    await store.save(
      TranslatorDraft(sourceText: report.request.sourceText, report: report),
    );

    final TranslatorDraft? restored = await store.load();

    expect(restored!.report!.audit.protocolFallback, isTrue);
    expect(restored.report!.audit.verdict, TranslationVerdict.needsReview);
  });

  test(
    'reads v3 reverse report but does not trust empty legacy audit',
    () async {
      final File file = _draftFile(tempDirectory);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v3',
          'sourceText': 'Исходный текст.',
          'sourceLanguageHint': 'RU',
          'report': <String, Object?>{
            'request': <String, Object?>{
              'sourceText': 'Исходный текст.',
              'sourceLanguageHint': 'RU',
              'engineerContext': null,
            },
            'bundle': <String, Object?>{
              'SOURCE LANGUAGE': 'RU',
              'SOURCE TEXT': 'Исходный текст.',
              'RU': 'Исходный текст.',
              'EN': 'Source text.',
              'TH': 'ข้อความต้นฉบับ',
              'EN_TO_RU': 'Исходный текст.',
              'TH_TO_RU': 'Исходный текст.',
              'EN_TO_TH': 'ข้อความต้นฉบับ',
              'TH_TO_EN': 'Source text.',
            },
            'audit': <String, Object?>{'findings': <Object?>[]},
            'createdAt': '2026-07-31T07:00:00.000Z',
          },
        }),
      );

      final TranslatorDraft? restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.report!.bundle.hasReverseDiagnostics, isTrue);
      expect(restored.report!.audit.verdict, TranslationVerdict.needsReview);
    },
  );

  test(
    'rejects and deletes v5 bundle with partial reverse diagnostics',
    () async {
      final TranslatorRunReport report = _report(audit: _exactAudit());
      await store.save(
        TranslatorDraft(sourceText: report.request.sourceText, report: report),
      );

      final File file = _draftFile(tempDirectory);
      final Map<String, Object?> encoded =
          (jsonDecode(await file.readAsString()) as Map<Object?, Object?>)
              .cast<String, Object?>();
      final Map<String, Object?> encodedReport =
          (encoded['report']! as Map<Object?, Object?>).cast<String, Object?>();
      final Map<String, Object?> encodedBundle =
          (encodedReport['bundle']! as Map<Object?, Object?>)
              .cast<String, Object?>();
      encodedBundle['EN_TO_RU'] = 'Исходный текст.';
      await file.writeAsString(jsonEncode(encoded));

      await expectLater(store.load(), throwsFormatException);
      expect(await file.exists(), isFalse);
    },
  );

  test('rejects and deletes corrupt draft', () async {
    final File file = _draftFile(tempDirectory);
    await file.parent.create(recursive: true);
    await file.writeAsString('{broken');

    await expectLater(store.load(), throwsFormatException);
    expect(await file.exists(), isFalse);
  });

  test('returns null when draft file is absent', () async {
    expect(await store.load(), isNull);
  });

  test('loads v1 string findings as legacy evidence', () async {
    await _writeLegacyDraft(
      tempDirectory,
      version: 'v1',
      audit: <String, Object?>{
        'meaningFindings': <String>[],
        'terminologyFindings': <String>['Старое доказательство.'],
        'styleFindings': <String>[],
        'ambiguityFindings': <String>[],
      },
    );

    final TranslatorDraft? restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.report!.bundle.hasReverseDiagnostics, isTrue);
    expect(restored.report!.audit.findings.single.isLegacy, isTrue);
    expect(restored.report!.audit.verdict, TranslationVerdict.needsReview);
  });

  test('loads v2 Russian-only structured evidence', () async {
    await _writeLegacyDraft(
      tempDirectory,
      version: 'v2',
      audit: <String, Object?>{
        'findings': <Object?>[
          <String, Object?>{
            'kind': 'structured',
            'category': 'MEANING',
            'section': 'EN',
            'sourceFragment': 'Исходный',
            'translationFragment': 'Source',
            'reason': 'Изменён объект.',
            'impact': 'Изменилось практическое указание.',
            'correctVariant': 'Source text.',
            'sourceAmbiguity': 'NONE',
          },
        ],
      },
    );

    final TranslatorDraft? restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.report!.audit.findings.single.isRussianOnly, isTrue);
    expect(restored.report!.audit.verdict, TranslationVerdict.canonicalDrift);
  });

  test('loads v3 multilingual structured evidence', () async {
    await _writeLegacyDraft(
      tempDirectory,
      version: 'v3',
      audit: <String, Object?>{
        'findings': <Object?>[
          <String, Object?>{
            'kind': 'multilingual',
            'category': 'STYLE',
            'section': 'EN',
            'sourceFragment': 'Исходный',
            'translationFragment': 'Source',
            'reason': <String, Object?>{
              'ru': 'Русское объяснение.',
              'en': 'English explanation.',
              'th': 'คำอธิบายภาษาไทย',
            },
            'impact': <String, Object?>{
              'ru': 'Русское влияние.',
              'en': 'English impact.',
              'th': 'ผลกระทบภาษาไทย',
            },
            'correctVariant': 'Source text.',
            'sourceAmbiguity': null,
          },
        ],
      },
    );

    final TranslatorDraft? restored = await store.load();

    expect(restored, isNotNull);
    final TranslationFinding finding = restored!.report!.audit.findings.single;
    expect(finding.isMultilingual, isTrue);
    expect(finding.reasonFor(TranslationLanguage.th), 'คำอธิบายภาษาไทย');
    expect(restored.report!.audit.verdict, TranslationVerdict.equivalent);
  });

  test('v5 round-trip preserves detailed challenger evidence', () async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          for (final TranslationPair pair in TranslationPair.values)
            TranslationPairAudit(
              pair: pair,
              result: TranslationPairAuditResult.clear,
            ),
        ],
        exactChallenge: ExactChallenge(
          result: ExactChallengeResult.unproven,
          disqualifiers: <ExactChallengeDisqualifier>[
            ExactChallengeDisqualifier(
              pair: TranslationPair.enTh,
              atom: TranslationSemanticAtom.equipmentIdentity,
              status: TranslationIssueStatus.unknown,
              left: 'Source',
              right: 'ข้อความ',
              reason: 'exact object identity is not proven',
            ),
          ],
        ),
      ),
    );

    await store.save(
      TranslatorDraft(sourceText: report.request.sourceText, report: report),
    );

    final TranslatorDraft restored = (await store.load())!;
    final ExactChallengeDisqualifier evidence =
        restored.report!.audit.exactChallenge!.disqualifiers.single;

    expect(restored.report!.audit.verdict, TranslationVerdict.needsReview);
    expect(evidence.pair, TranslationPair.enTh);
    expect(evidence.left, 'Source');
    expect(evidence.right, 'ข้อความ');
    expect(evidence.reason, 'exact object identity is not proven');
  });

  test('v4 five-call report is migrated fail-closed', () async {
    final File file = _draftFile(tempDirectory);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(<String, Object?>{
        'version': 'v4',
        'sourceText': 'Исходный текст.',
        'sourceLanguageHint': 'RU',
        'report': <String, Object?>{
          'request': <String, Object?>{
            'sourceText': 'Исходный текст.',
            'sourceLanguageHint': 'RU',
            'engineerContext': null,
          },
          'bundle': <String, Object?>{
            'SOURCE LANGUAGE': 'RU',
            'SOURCE TEXT': 'Исходный текст.',
            'RU': 'Исходный текст.',
            'EN': 'Source text.',
            'TH': 'ข้อความต้นฉบับ',
          },
          'audit': <String, Object?>{
            'findings': <Object?>[],
            'pairAudits': <Object?>[],
            'exactCertifications': <Object?>[],
            'protocolFallback': false,
          },
          'createdAt': '2026-07-31T07:00:00.000Z',
        },
      }),
    );

    final TranslatorDraft restored = (await store.load())!;

    expect(restored.report!.audit.protocolFallback, isTrue);
    expect(restored.report!.audit.verdict, TranslationVerdict.needsReview);
  });

  test('rejects oversized stored model reason', () async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          for (final TranslationPair pair in TranslationPair.values)
            TranslationPairAudit(
              pair: pair,
              result: TranslationPairAuditResult.clear,
            ),
        ],
        exactChallenge: ExactChallenge(
          result: ExactChallengeResult.unproven,
          disqualifiers: <ExactChallengeDisqualifier>[
            ExactChallengeDisqualifier(
              pair: TranslationPair.enTh,
              atom: TranslationSemanticAtom.equipmentIdentity,
              status: TranslationIssueStatus.unknown,
              left: 'Source',
              right: 'ข้อความ',
              reason: 'identity is not proven',
            ),
          ],
        ),
      ),
    );
    await store.save(
      TranslatorDraft(sourceText: report.request.sourceText, report: report),
    );

    final File file = _draftFile(tempDirectory);
    final Map<String, Object?> encoded =
        (jsonDecode(await file.readAsString()) as Map<Object?, Object?>)
            .cast<String, Object?>();
    final Map<String, Object?> encodedReport =
        (encoded['report']! as Map<Object?, Object?>).cast<String, Object?>();
    final Map<String, Object?> audit =
        (encodedReport['audit']! as Map<Object?, Object?>)
            .cast<String, Object?>();
    final Map<String, Object?> challenge =
        (audit['exactChallenge']! as Map<Object?, Object?>)
            .cast<String, Object?>();
    final List<Object?> disqualifiers =
        challenge['disqualifiers']! as List<Object?>;
    final Map<String, Object?> item =
        (disqualifiers.single! as Map<Object?, Object?>)
            .cast<String, Object?>();
    item['reason'] = List<String>.filled(19, 'word').join(' ');
    await file.writeAsString(jsonEncode(encoded));

    await expectLater(store.load(), throwsFormatException);
    expect(await file.exists(), isFalse);
  });

  test('clear removes the draft and temporary file', () async {
    final TranslatorRunReport report = _report(audit: _exactAudit());
    await store.save(
      TranslatorDraft(sourceText: report.request.sourceText, report: report),
    );

    final File file = _draftFile(tempDirectory);
    final File temporary = File('${file.path}.tmp');
    await temporary.writeAsString('temporary');

    await store.clear();

    expect(await file.exists(), isFalse);
    expect(await temporary.exists(), isFalse);
  });
}

Future<void> _writeLegacyDraft(
  Directory root, {
  required String version,
  required Map<String, Object?> audit,
}) async {
  final File file = _draftFile(root);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode(<String, Object?>{
      'version': version,
      'sourceText': 'Исходный текст.',
      'sourceLanguageHint': 'RU',
      'report': <String, Object?>{
        'request': <String, Object?>{
          'sourceText': 'Исходный текст.',
          'sourceLanguageHint': 'RU',
          'engineerContext': null,
        },
        'bundle': <String, Object?>{
          'SOURCE LANGUAGE': 'RU',
          'SOURCE TEXT': 'Исходный текст.',
          'RU': 'Исходный текст.',
          'EN': 'Source text.',
          'TH': 'ข้อความต้นฉบับ',
          'EN_TO_RU': 'Исходный текст.',
          'TH_TO_RU': 'Исходный текст.',
          'EN_TO_TH': 'ข้อความต้นฉบับ',
          'TH_TO_EN': 'Source text.',
        },
        'audit': audit,
        'createdAt': '2026-07-31T07:00:00.000Z',
      },
    }),
  );
}

TranslatorRunReport _report({required TranslationAudit audit}) {
  final TranslatorWorkRequest request = TranslatorWorkRequest(
    sourceText: 'Исходный текст.',
    sourceLanguageHint: TranslationLanguage.ru,
  );

  return TranslatorRunReport(
    request: request,
    bundle: TranslationBundle(
      sourceLanguage: TranslationLanguage.ru,
      sourceText: request.sourceText,
      ru: request.sourceText,
      en: 'Source text.',
      th: 'ข้อความต้นฉบับ',
    ),
    audit: audit,
    createdAt: DateTime.utc(2026, 7, 31, 7),
  );
}

TranslationAudit _exactAudit() {
  return TranslationAudit(
    pairAudits: <TranslationPairAudit>[
      for (final TranslationPair pair in TranslationPair.values)
        TranslationPairAudit(
          pair: pair,
          result: TranslationPairAuditResult.clear,
        ),
    ],
    exactChallenge: ExactChallenge(result: ExactChallengeResult.clear),
  );
}

File _draftFile(Directory root) {
  return File(
    '${root.path}${Platform.pathSeparator}'
    '${JsonFileTranslatorDraftStore.directoryName}${Platform.pathSeparator}'
    '${JsonFileTranslatorDraftStore.fileName}',
  );
}
