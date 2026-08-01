import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/localization/registry_studio_localizations.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_access_key_store.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_draft_store.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_provider.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/translator_workspace_view.dart';

void main() {
  testWidgets('shows exactly eight visible sections and automatic verdict', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report();
    final TranslatorWorkspaceController controller =
        TranslatorWorkspaceController();

    await _pumpTranslator(
      tester,
      controller: controller,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(),
      accessKeyStore: _MemoryAccessKeyStore(),
    );

    controller.openAccessKeyDialog();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('translator-access-key-dialog-field')),
      'test-key',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('translator-access-key-dialog-save')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('translator-source-text-field')),
      report.request.sourceText,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('translator-run-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Автоматический вердикт перевода'), findsOneWidget);
    expect(find.text('EXACT'), findsOneWidget);
    expect(find.text('SOURCE TEXT и прямые секции'), findsOneWidget);
    expect(find.text('Обратные секции перевода'), findsOneWidget);
    for (final String section in <String>[
      'SOURCE TEXT',
      'RU',
      'EN',
      'TH',
      'EN_TO_RU',
      'TH_TO_RU',
      'EN_TO_TH',
      'TH_TO_EN',
    ]) {
      expect(find.text(section), findsOneWidget);
    }
    expect(find.text('RU · SOURCE TEXT'), findsNothing);
    expect(find.textContaining('→'), findsNothing);
    expect(find.text('Аудит и диагностика'), findsOneWidget);
  });

  testWidgets('renders accepted provider bundle without rewriting', (
    WidgetTester tester,
  ) async {
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

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(sourceText: source, report: report),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text(source), findsWidgets);
    expect(find.text(en), findsOneWidget);
    expect(find.text(th), findsOneWidget);
  });

  testWidgets('new semantic report hides legacy reverse diagnostics', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report(withReverse: false);

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          sourceLanguageHint: TranslationLanguage.ru,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('EXACT'), findsOneWidget);
    expect(find.text('Попарный семантический аудит'), findsOneWidget);
    expect(find.text('Независимый challenger EXACT'), findsOneWidget);
    expect(find.text('Обратные секции перевода'), findsNothing);
    expect(find.text('EN_TO_RU'), findsNothing);
  });

  testWidgets(
    'global challenger conflict shows fragments, reason, explanation and impact',
    (WidgetTester tester) async {
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
                left: 'equipment',
                right: 'อุปกรณ์',
                reason: 'exact equipment identity is not proven',
              ),
            ],
          ),
        ),
        withReverse: false,
      );

      await _pumpTranslator(
        tester,
        provider: _SuccessProvider(report),
        draftStore: _MemoryDraftStore(
          draft: TranslatorDraft(
            sourceText: report.request.sourceText,
            sourceLanguageHint: TranslationLanguage.ru,
            report: report,
          ),
        ),
        accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
      );

      expect(find.text('NEEDS REVIEW'), findsOneWidget);
      expect(
        find.textContaining(
          'Общий аудит дал три CLEAR, но независимый challenger',
        ),
        findsOneWidget,
      );
      expect(find.text('EN_TH · U'), findsOneWidget);
      expect(find.text('EN: equipment'), findsOneWidget);
      expect(find.text('TH: อุปกรณ์'), findsOneWidget);
      expect(
        find.textContaining(
          'Краткое обоснование модели: '
          'exact equipment identity is not proven',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Пояснение:'), findsOneWidget);
      expect(find.textContaining('Влияние:'), findsOneWidget);
    },
  );

  testWidgets('clear audit without certification shows fail-closed evidence', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          for (final TranslationPair pair in TranslationPair.values)
            TranslationPairAudit(
              pair: pair,
              result: TranslationPairAuditResult.clear,
            ),
        ],
      ),
      withReverse: false,
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          sourceLanguageHint: TranslationLanguage.ru,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('NEEDS REVIEW'), findsOneWidget);
    expect(find.text('Независимый challenger EXACT'), findsOneWidget);
    expect(
      find.text(
        'Структурированное доказательство не получено. Требуется проверка.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('semantic fallback does not claim preserved evidence', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(protocolFallback: true),
      withReverse: false,
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          sourceLanguageHint: TranslationLanguage.ru,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('NEEDS REVIEW'), findsOneWidget);
    expect(
      find.text(
        'Структурированное доказательство не получено. Требуется проверка.',
      ),
      findsOneWidget,
    );
    expect(find.text('Смысл сохранён'), findsNothing);
    expect(find.text('Терминология сохранена'), findsNothing);
    expect(find.text('Канонический стиль сохранён'), findsNothing);
  });

  testWidgets('legacy empty audit does not claim preserved evidence', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(),
      withReverse: true,
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          sourceLanguageHint: TranslationLanguage.ru,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('NEEDS REVIEW'), findsOneWidget);
    expect(
      find.text(
        'Структурированное доказательство не получено. Требуется проверка.',
      ),
      findsOneWidget,
    );
    expect(find.text('Смысл сохранён'), findsNothing);
    expect(find.text('Терминология сохранена'), findsNothing);
    expect(find.text('Канонический стиль сохранён'), findsNothing);
  });

  testWidgets('style-only semantic issue uses a style-specific explanation', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.blocked,
            issues: <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.canonicalStyle,
                status: TranslationIssueStatus.mismatch,
                left: 'Фотография установленного оборудования.',
                right: 'Photo of the installed equipment.',
                reason: 'noncanonical service wording',
              ),
            ],
          ),
          TranslationPairAudit(
            pair: TranslationPair.ruTh,
            result: TranslationPairAuditResult.clear,
          ),
          TranslationPairAudit(
            pair: TranslationPair.enTh,
            result: TranslationPairAuditResult.clear,
          ),
        ],
      ),
      withReverse: false,
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          sourceLanguageHint: TranslationLanguage.ru,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('EQUIVALENT'), findsOneWidget);
    expect(
      find.textContaining(
        'Практический смысл сохранён, но формулировка не соответствует '
        'каноническому стилю.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'На исполнение задания не влияет; перед публикацией требуется '
        'нормализовать формулировку.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('ambiguity evidence is review-only and shows practical impact', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.unproven,
            issues: <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.ambiguity,
                status: TranslationIssueStatus.unknown,
                left: 'оборудования',
                right: 'equipment',
                reason: 'equipment reference is context-dependent',
              ),
            ],
          ),
          TranslationPairAudit(
            pair: TranslationPair.ruTh,
            result: TranslationPairAuditResult.clear,
          ),
          TranslationPairAudit(
            pair: TranslationPair.enTh,
            result: TranslationPairAuditResult.clear,
          ),
        ],
      ),
      withReverse: false,
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          sourceLanguageHint: TranslationLanguage.ru,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('NEEDS REVIEW'), findsOneWidget);
    expect(
      find.textContaining(
        'Формулировка допускает неоднозначное практическое толкование.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Разные участники могут понять задание по-разному; требуется '
        'ручная проверка контекста.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('needsReview uses yellow verdict card with audit findings', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(
        terminologyFindings: const <String>['Термин X'],
        styleFindings: const <String>['Стиль X'],
      ),
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          sourceLanguageHint: TranslationLanguage.ru,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('NEEDS REVIEW'), findsOneWidget);
    expect(find.text('Аудит и диагностика'), findsOneWidget);

    final Finder verdictCard = find.ancestor(
      of: find.text('NEEDS REVIEW'),
      matching: find.byType(Card),
    );

    expect(verdictCard, findsOneWidget);
    expect(tester.widget<Card>(verdictCard).color, Colors.yellow.shade50);
    expect(
      find.descendant(
        of: verdictCard,
        matching: find.text('Аудит и диагностика'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: verdictCard, matching: find.text('Термин X')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: verdictCard, matching: find.text('Стиль X')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: verdictCard,
        matching: find.textContaining('Устаревшее доказательство'),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('shows every structured evidence field', (
    WidgetTester tester,
  ) async {
    final TranslationFinding finding = TranslationFinding(
      category: TranslationFindingCategory.meaning,
      section: TranslationLanguage.en,
      sourceFragment: 'оборудования',
      translationFragment: 'installed equipment',
      reason: 'Изменён объект.',
      impact: 'Инструкция относится к другому устройству.',
      correctVariant: 'Photo of the installed equipment.',
      sourceAmbiguity: 'NONE',
    );
    final TranslatorRunReport report = _report(
      audit: TranslationAudit(findings: <TranslationFinding>[finding]),
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          sourceLanguageHint: TranslationLanguage.ru,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('MEANING · EN'), findsOneWidget);
    expect(find.text('Затронутая секция'), findsOneWidget);
    expect(find.text('Фрагмент SOURCE TEXT'), findsOneWidget);
    expect(find.text('оборудования'), findsOneWidget);
    expect(find.text('Фрагмент перевода'), findsOneWidget);
    expect(find.text('installed equipment'), findsOneWidget);
    expect(find.text('Обнаруженное различие'), findsOneWidget);
    expect(find.text('Изменён объект.'), findsOneWidget);
    expect(find.text('Влияние'), findsOneWidget);
    expect(
      find.text('Инструкция относится к другому устройству.'),
      findsOneWidget,
    );
    expect(find.text('Корректный вариант'), findsOneWidget);
    expect(find.text('Photo of the installed equipment.'), findsWidgets);
    expect(find.text('Неоднозначность SOURCE TEXT'), findsOneWidget);
    expect(find.text('Не обнаружена'), findsOneWidget);
  });

  for (final ({
        Locale locale,
        String verdictTitle,
        String auditTitle,
        String evidenceSection,
      })
      localeCase
      in <
        ({
          Locale locale,
          String verdictTitle,
          String auditTitle,
          String evidenceSection,
        })
      >[
        (
          locale: RegistryStudioLocalizations.russian,
          verdictTitle: 'Автоматический вердикт перевода',
          auditTitle: 'Аудит и диагностика',
          evidenceSection: 'Затронутая секция',
        ),
        (
          locale: RegistryStudioLocalizations.english,
          verdictTitle: 'Automatic translation verdict',
          auditTitle: 'Audit and diagnostics',
          evidenceSection: 'Affected section',
        ),
        (
          locale: RegistryStudioLocalizations.thai,
          verdictTitle: 'คำตัดสินการแปลอัตโนมัติ',
          auditTitle: 'การตรวจสอบและการวินิจฉัย',
          evidenceSection: 'ส่วนที่ได้รับผลกระทบ',
        ),
      ]) {
    testWidgets(
      'localizes evidence labels for ${localeCase.locale.languageCode}',
      (WidgetTester tester) async {
        final TranslatorRunReport report = _report(
          audit: TranslationAudit(
            findings: <TranslationFinding>[
              TranslationFinding(
                category: TranslationFindingCategory.style,
                section: TranslationLanguage.en,
                sourceFragment: 'Фотография',
                translationFragment: 'Photo',
                reason: 'Формулировка менее канонична.',
                impact: 'Смысл сохранён.',
                correctVariant: 'Use the canonical wording.',
                sourceAmbiguity: 'NONE',
              ),
            ],
          ),
        );

        await _pumpTranslator(
          tester,
          locale: localeCase.locale,
          provider: _SuccessProvider(report),
          draftStore: _MemoryDraftStore(
            draft: TranslatorDraft(
              sourceText: report.request.sourceText,
              sourceLanguageHint: TranslationLanguage.ru,
              report: report,
            ),
          ),
          accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
        );

        expect(find.text(localeCase.verdictTitle), findsOneWidget);
        expect(find.text(localeCase.auditTitle), findsOneWidget);
        expect(find.text(localeCase.evidenceSection), findsOneWidget);
        expect(find.text('EXACT'), findsNothing);
        expect(find.text('EQUIVALENT'), findsOneWidget);
      },
    );
  }

  for (final ({
        Locale locale,
        String reason,
        String impact,
        String sourceAmbiguity,
      })
      localeCase
      in <
        ({Locale locale, String reason, String impact, String sourceAmbiguity})
      >[
        (
          locale: RegistryStudioLocalizations.russian,
          reason: 'Русское объяснение.',
          impact: 'Русское влияние.',
          sourceAmbiguity: 'Русская неоднозначность.',
        ),
        (
          locale: RegistryStudioLocalizations.english,
          reason: 'English reason.',
          impact: 'English impact.',
          sourceAmbiguity: 'English source ambiguity.',
        ),
        (
          locale: RegistryStudioLocalizations.thai,
          reason: 'คำอธิบายภาษาไทย',
          impact: 'ผลกระทบภาษาไทย',
          sourceAmbiguity: 'ความกำกวมของต้นฉบับภาษาไทย',
        ),
      ]) {
    testWidgets(
      'projects multilingual evidence for ${localeCase.locale.languageCode}',
      (WidgetTester tester) async {
        final TranslatorRunReport report = _report(
          audit: TranslationAudit(
            findings: <TranslationFinding>[
              TranslationFinding.multilingual(
                category: TranslationFindingCategory.meaning,
                section: TranslationLanguage.en,
                sourceFragment: 'оборудования',
                translationFragment: 'equipment',
                reason: LocalizedEvidenceText(
                  ru: 'Русское объяснение.',
                  en: 'English reason.',
                  th: 'คำอธิบายภาษาไทย',
                ),
                impact: LocalizedEvidenceText(
                  ru: 'Русское влияние.',
                  en: 'English impact.',
                  th: 'ผลกระทบภาษาไทย',
                ),
                correctVariant: 'installed equipment',
                sourceAmbiguity: LocalizedEvidenceText(
                  ru: 'Русская неоднозначность.',
                  en: 'English source ambiguity.',
                  th: 'ความกำกวมของต้นฉบับภาษาไทย',
                ),
              ),
            ],
          ),
        );

        await _pumpTranslator(
          tester,
          locale: localeCase.locale,
          provider: _SuccessProvider(report),
          draftStore: _MemoryDraftStore(
            draft: TranslatorDraft(
              sourceText: report.request.sourceText,
              sourceLanguageHint: TranslationLanguage.ru,
              report: report,
            ),
          ),
          accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
        );

        expect(find.text(localeCase.reason), findsOneWidget);
        expect(find.text(localeCase.impact), findsOneWidget);
        expect(find.text(localeCase.sourceAmbiguity), findsOneWidget);
        expect(find.text('оборудования'), findsOneWidget);
        expect(find.text('equipment'), findsOneWidget);
        expect(find.text('installed equipment'), findsOneWidget);

        for (final String localizedText in <String>[
          'Русское объяснение.',
          'Русское влияние.',
          'Русская неоднозначность.',
          'English reason.',
          'English impact.',
          'English source ambiguity.',
          'คำอธิบายภาษาไทย',
          'ผลกระทบภาษาไทย',
          'ความกำกวมของต้นฉบับภาษาไทย',
        ]) {
          final bool selected =
              localizedText == localeCase.reason ||
              localizedText == localeCase.impact ||
              localizedText == localeCase.sourceAmbiguity;
          expect(
            find.text(localizedText),
            selected ? findsOneWidget : findsNothing,
          );
        }
      },
    );
  }

  testWidgets(
    'keeps Russian-only evidence compatible under English UI locale',
    (WidgetTester tester) async {
      final TranslatorRunReport report = _report(
        audit: TranslationAudit(
          findings: <TranslationFinding>[
            TranslationFinding(
              category: TranslationFindingCategory.terminology,
              section: TranslationLanguage.en,
              sourceFragment: 'оборудования',
              translationFragment: 'equipment',
              reason: 'Русское объяснение совместимости.',
              impact: 'Русское описание влияния совместимости.',
              correctVariant: 'installed equipment',
              sourceAmbiguity: 'NONE',
            ),
          ],
        ),
      );

      await _pumpTranslator(
        tester,
        locale: RegistryStudioLocalizations.english,
        provider: _SuccessProvider(report),
        draftStore: _MemoryDraftStore(
          draft: TranslatorDraft(
            sourceText: report.request.sourceText,
            sourceLanguageHint: TranslationLanguage.ru,
            report: report,
          ),
        ),
        accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
      );

      expect(find.text('Русское объяснение совместимости.'), findsOneWidget);
      expect(
        find.text('Русское описание влияния совместимости.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('clear removes Translator result only', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report();
    final _MemoryAccessKeyStore accessKeyStore = _MemoryAccessKeyStore(
      value: 'saved-key',
    );
    final _MemoryDraftStore store = _MemoryDraftStore(
      draft: TranslatorDraft(
        sourceText: report.request.sourceText,
        sourceLanguageHint: TranslationLanguage.ru,
        report: report,
      ),
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: store,
      accessKeyStore: accessKeyStore,
    );

    expect(find.text('EXACT'), findsOneWidget);

    await tester.tap(find.text('Очистить Translator'));
    await tester.pumpAndSettle();

    expect(find.text('EXACT'), findsNothing);
    expect(store.clearCount, 1);
    expect(accessKeyStore.value, 'saved-key');
    expect(accessKeyStore.clearCount, 0);
  });

  testWidgets('restores and persists API key through compact dialog', (
    WidgetTester tester,
  ) async {
    final _MemoryAccessKeyStore accessKeyStore = _MemoryAccessKeyStore(
      value: 'saved-key',
    );
    final TranslatorWorkspaceController controller =
        TranslatorWorkspaceController();

    await _pumpTranslator(
      tester,
      controller: controller,
      provider: _SuccessProvider(_report()),
      draftStore: _MemoryDraftStore(),
      accessKeyStore: accessKeyStore,
    );

    expect(find.text('Typhoon API key'), findsNothing);

    controller.openAccessKeyDialog();
    await tester.pumpAndSettle();

    final TextField keyField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('translator-access-key-dialog-field')),
    );

    expect(keyField.controller?.text, 'saved-key');

    await tester.enterText(
      find.byKey(const ValueKey<String>('translator-access-key-dialog-field')),
      'updated-key',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('translator-access-key-dialog-save')),
    );
    await tester.pumpAndSettle();

    expect(accessKeyStore.value, 'updated-key');
  });

  testWidgets('deletes API key only through explicit dialog action', (
    WidgetTester tester,
  ) async {
    final _MemoryAccessKeyStore accessKeyStore = _MemoryAccessKeyStore(
      value: 'saved-key',
    );
    final TranslatorWorkspaceController controller =
        TranslatorWorkspaceController();

    await _pumpTranslator(
      tester,
      controller: controller,
      provider: _SuccessProvider(_report()),
      draftStore: _MemoryDraftStore(),
      accessKeyStore: accessKeyStore,
    );

    controller.openAccessKeyDialog();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('translator-access-key-dialog-delete')),
    );
    await tester.pumpAndSettle();

    expect(accessKeyStore.value, isNull);
    expect(accessKeyStore.clearCount, 1);

    controller.openAccessKeyDialog();
    await tester.pumpAndSettle();

    final TextField keyField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('translator-access-key-dialog-field')),
    );

    expect(keyField.controller?.text, isEmpty);
  });

  testWidgets('shows and clears corrupt draft recovery warning', (
    WidgetTester tester,
  ) async {
    final _MemoryDraftStore store = _MemoryDraftStore(
      loadError: const FormatException('Internal English schema error.'),
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(_report()),
      draftStore: store,
      accessKeyStore: _MemoryAccessKeyStore(),
    );

    expect(find.text('Предупреждение восстановления'), findsOneWidget);
    expect(
      find.text(
        'Сохранённый черновик Translator был повреждён и безопасно удалён.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('schema'), findsNothing);

    await tester.tap(find.text('Очистить Translator'));
    await tester.pumpAndSettle();

    expect(find.text('Предупреждение восстановления'), findsNothing);
    expect(store.clearCount, 1);
  });

  for (final ({Locale locale, String title, String message}) localeCase
      in <({Locale locale, String title, String message})>[
        (
          locale: RegistryStudioLocalizations.english,
          title: 'Restore warning',
          message:
              'The saved Translator draft was corrupt and was safely removed.',
        ),
        (
          locale: RegistryStudioLocalizations.thai,
          title: 'คำเตือนการกู้คืน',
          message:
              'ฉบับร่าง Translator ที่บันทึกไว้เสียหายและถูกลบออกอย่างปลอดภัย',
        ),
      ]) {
    testWidgets(
      'localizes corrupt draft warning for ${localeCase.locale.languageCode}',
      (WidgetTester tester) async {
        await _pumpTranslator(
          tester,
          locale: localeCase.locale,
          provider: _SuccessProvider(_report()),
          draftStore: _MemoryDraftStore(
            loadError: const FormatException('Internal schema detail.'),
          ),
          accessKeyStore: _MemoryAccessKeyStore(),
        );

        expect(find.text(localeCase.title), findsOneWidget);
        expect(find.text(localeCase.message), findsOneWidget);
        expect(find.textContaining('schema'), findsNothing);
      },
    );
  }

  for (final ({Locale locale, String message, String codeLabel}) localeCase
      in <({Locale locale, String message, String codeLabel})>[
        (
          locale: RegistryStudioLocalizations.english,
          message: 'Typhoon rejected the API key. Check the saved key.',
          codeLabel: 'Error code: unauthorized',
        ),
        (
          locale: RegistryStudioLocalizations.thai,
          message: 'Typhoon ปฏิเสธคีย์ API โปรดตรวจสอบคีย์ที่บันทึกไว้',
          codeLabel: 'รหัสข้อผิดพลาด: unauthorized',
        ),
      ]) {
    testWidgets(
      'localizes provider failure for ${localeCase.locale.languageCode}',
      (WidgetTester tester) async {
        await _pumpTranslator(
          tester,
          locale: localeCase.locale,
          provider: _FailureProvider(
            TranslatorFailure(
              stage: TranslatorFailureStage.transport,
              code: TranslatorFailureCode.unauthorized,
              message: 'Внутреннее сообщение provider.',
            ),
          ),
          draftStore: _MemoryDraftStore(),
          accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
        );

        await tester.enterText(
          find.byKey(const ValueKey<String>('translator-source-text-field')),
          'Source text.',
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('translator-run-button')),
        );
        await tester.pumpAndSettle();

        expect(find.text(localeCase.message), findsOneWidget);
        expect(find.text(localeCase.codeLabel), findsOneWidget);
        expect(find.textContaining('Внутреннее сообщение'), findsNothing);
      },
    );
  }

  testWidgets('uses compact source header and text-only run button', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(_report()),
      draftStore: _MemoryDraftStore(),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(
      find.byKey(const ValueKey<String>('translator-source-language-menu')),
      findsNothing,
    );
    expect(find.text('Исходный текст'), findsOneWidget);
    expect(find.text('Язык источника'), findsNothing);
    expect(find.byIcon(Icons.translate), findsNothing);
    expect(find.text('Перевести и проверить'), findsOneWidget);
  });
}

Future<void> _pumpTranslator(
  WidgetTester tester, {
  required TranslatorProvider provider,
  required TranslatorDraftStore draftStore,
  required TranslatorAccessKeyStore accessKeyStore,
  TranslatorWorkspaceController? controller,
  Locale locale = RegistryStudioLocalizations.russian,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: RegistryStudioLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        RegistryStudioLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: TranslatorWorkspaceView(
          provider: provider,
          draftStore: draftStore,
          accessKeyStore: accessKeyStore,
          controller: controller,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

TranslatorRunReport _report({
  TranslationAudit? audit,
  bool withReverse = true,
}) {
  final TranslatorWorkRequest request = TranslatorWorkRequest(
    sourceText: 'Фотография установленного оборудования.',
    sourceLanguageHint: TranslationLanguage.ru,
  );

  return TranslatorRunReport(
    request: request,
    bundle: TranslationBundle(
      sourceLanguage: TranslationLanguage.ru,
      sourceText: request.sourceText,
      ru: request.sourceText,
      en: 'Photo of the installed equipment.',
      th: 'ภาพถ่ายอุปกรณ์ที่ติดตั้งแล้ว',
      enToRu: withReverse ? request.sourceText : null,
      thToRu: withReverse ? request.sourceText : null,
      enToTh: withReverse ? 'ภาพถ่ายอุปกรณ์ที่ติดตั้งแล้ว' : null,
      thToEn: withReverse ? 'Photo of the installed equipment.' : null,
    ),
    audit: audit ?? _exactAudit(),
    createdAt: DateTime.utc(2026, 7, 26, 6),
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

final class _MemoryDraftStore implements TranslatorDraftStore {
  _MemoryDraftStore({this.draft, this.loadError});

  TranslatorDraft? draft;
  Object? loadError;
  int clearCount = 0;

  @override
  Future<TranslatorDraft?> load() async {
    final Object? error = loadError;

    if (error != null) {
      throw error;
    }

    return draft;
  }

  @override
  Future<void> save(TranslatorDraft draft) async {
    this.draft = draft;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    draft = null;
    loadError = null;
  }
}

final class _SuccessProvider implements TranslatorProvider {
  const _SuccessProvider(this.report);

  final TranslatorRunReport report;

  @override
  TranslatorOperation start({
    required TranslatorWorkRequest request,
    required String accessKey,
  }) {
    return _SuccessOperation(report);
  }
}

final class _SuccessOperation implements TranslatorOperation {
  const _SuccessOperation(this.report);

  final TranslatorRunReport report;

  @override
  Stream<TranslatorRunStage> get progress =>
      Stream<TranslatorRunStage>.fromIterable(TranslatorRunStage.values);

  @override
  Future<TranslatorRunReport> get result async => report;

  @override
  void cancel() {}
}

final class _FailureProvider implements TranslatorProvider {
  const _FailureProvider(this.failure);

  final TranslatorFailure failure;

  @override
  TranslatorOperation start({
    required TranslatorWorkRequest request,
    required String accessKey,
  }) {
    return _FailureOperation(failure);
  }
}

final class _FailureOperation implements TranslatorOperation {
  const _FailureOperation(this.failure);

  final TranslatorFailure failure;

  @override
  Stream<TranslatorRunStage> get progress =>
      const Stream<TranslatorRunStage>.empty();

  @override
  Future<TranslatorRunReport> get result async {
    throw TranslatorProviderException(failure);
  }

  @override
  void cancel() {}
}

final class _MemoryAccessKeyStore implements TranslatorAccessKeyStore {
  _MemoryAccessKeyStore({this.value});

  String? value;
  int clearCount = 0;

  @override
  Future<String?> load() async => value;

  @override
  Future<void> save(String accessKey) async {
    value = accessKey;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    value = null;
  }
}
