import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/localization/registry_studio_localizations.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_access_key_store.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_draft_store.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_history_store.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_provider.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/history/translator_history_card.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/report/translator_system_comment.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/translator_workspace_view.dart';

void main() {
  test('clipboard text contains the complete saved translation', () {
    final TranslatorHistoryEntry entry = TranslatorHistoryEntry(
      id: 'copy',
      report: _report(),
    );
    const RegistryStudioLocalizations l10n = RegistryStudioLocalizations(
      Locale('ru'),
    );

    final String text = buildTranslatorHistoryClipboardText(entry, l10n);

    expect(text, contains('Семантический вердикт: EXACT'));
    expect(text, contains('Исходный текст:'));
    expect(text, contains('RU:'));
    expect(text, contains('EN_TO_RU:'));
    expect(text, contains('Канонический словарь: НЕ ПОДКЛЮЧЁН'));
    expect(text, contains('Комментарий системы:'));
  });

  test('system comment explains ambiguity from actual findings', () {
    const RegistryStudioLocalizations l10n = RegistryStudioLocalizations(
      Locale('ru'),
    );
    final TranslationAudit audit = TranslationAudit(
      ambiguityFindings: const <String>[
        'TH допускает значения «варочная панель» и «печь».',
      ],
    );

    final String comment = buildTranslatorSystemCommentText(l10n, audit);

    expect(comment, contains('требуется решение инженера'));
    expect(comment, contains('варочная панель'));
    expect(comment, contains('печь'));
    expect(comment, contains('не считаются независимым доказательством'));
  });

  testWidgets('shows direct, reverse, and semantic verdict sections', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report();
    final String historyEntryId =
        'translation-${report.createdAt.toUtc().microsecondsSinceEpoch}';
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
    await _scrollToHistory(tester);

    expect(find.byType(TranslatorHistoryCard), findsOneWidget);
    final Text collapsedSource = tester.widget<Text>(
      find.descendant(
        of: find.byType(TranslatorHistoryCard),
        matching: find.text(report.request.sourceText),
      ),
    );
    expect(collapsedSource.maxLines, 2);
    expect(collapsedSource.overflow, TextOverflow.ellipsis);
    expect(find.text('EXACT'), findsOneWidget);
    final Card exactCard = tester.widget<Card>(
      find.byKey(ValueKey<String>('translator-history-card-$historyEntryId')),
    );
    expect(exactCard.color, const Color(0xFFE7F4E8));
    final Text exactStatus = tester.widget<Text>(find.text('EXACT'));
    final BuildContext cardContext = tester.element(
      find.byKey(ValueKey<String>('translator-history-card-$historyEntryId')),
    );
    expect(
      exactStatus.style?.fontSize,
      Theme.of(cardContext).textTheme.titleMedium?.fontSize,
    );
    expect(exactStatus.style?.fontWeight, FontWeight.w700);
    expect(find.text('Прямой перевод'), findsNothing);
    expect(find.text('Обратные переводы для диагностики'), findsNothing);

    await tester.tap(
      find.byKey(ValueKey<String>('translator-history-toggle-$historyEntryId')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Семантический вердикт'), findsOneWidget);
    expect(find.text('Прямой перевод'), findsOneWidget);
    expect(find.text('Обратные переводы для диагностики'), findsOneWidget);
    expect(find.text('Комментарий системы'), findsOneWidget);
    expect(find.text('Аудит и диагностика'), findsNothing);
    expect(find.text('Канонический словарь'), findsOneWidget);
    expect(find.text('НЕ ПОДКЛЮЧЁН'), findsOneWidget);
    expect(find.text('Канонический вердикт недоступен'), findsOneWidget);
  });

  testWidgets('does not show redundant clear or cancel actions', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report();

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(report),
      draftStore: _MemoryDraftStore(
        draft: TranslatorDraft(
          sourceText: report.request.sourceText,
          report: report,
        ),
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    expect(find.text('Очистить Translator'), findsNothing);
    expect(find.text('Отменить'), findsNothing);

    await _scrollToHistory(tester);

    expect(
      find.byKey(const ValueKey<String>('translator-history-clear-all')),
      findsOneWidget,
    );
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

  testWidgets('keeps only one history card expanded', (
    WidgetTester tester,
  ) async {
    final TranslatorHistoryEntry first = TranslatorHistoryEntry(
      id: 'first',
      report: _reportAt(DateTime.utc(2026, 7, 26, 6)),
    );
    final TranslatorHistoryEntry second = TranslatorHistoryEntry(
      id: 'second',
      report: _reportAt(DateTime.utc(2026, 7, 26, 7)),
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(_report()),
      draftStore: _MemoryDraftStore(),
      historyStore: _MemoryHistoryStore(
        entries: <TranslatorHistoryEntry>[second, first],
      ),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );
    await _scrollToHistory(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('translator-history-toggle-first')),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.byKey(const ValueKey<String>('translator-history-toggle-first')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('translator-history-toggle-second')),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('translator-history-toggle-second')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('translator-history-details-second')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('translator-history-details-first')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('translator-history-toggle-first')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('translator-history-toggle-first')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('translator-history-details-second')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('translator-history-details-first')),
      findsOneWidget,
    );
  });

  testWidgets('deletes one entry and all history only by explicit actions', (
    WidgetTester tester,
  ) async {
    final TranslatorHistoryEntry first = TranslatorHistoryEntry(
      id: 'first',
      report: _reportAt(DateTime.utc(2026, 7, 26, 6)),
    );
    final TranslatorHistoryEntry second = TranslatorHistoryEntry(
      id: 'second',
      report: _reportAt(DateTime.utc(2026, 7, 26, 7)),
    );
    final _MemoryHistoryStore historyStore = _MemoryHistoryStore(
      entries: <TranslatorHistoryEntry>[second, first],
    );

    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(_report()),
      draftStore: _MemoryDraftStore(),
      historyStore: historyStore,
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );
    await _scrollToHistory(tester);

    final Finder secondToggle = find.byKey(
      const ValueKey<String>('translator-history-toggle-second'),
    );
    await tester.ensureVisible(secondToggle);
    await tester.pumpAndSettle();
    await tester.tap(secondToggle);
    await tester.pumpAndSettle();

    final Finder deleteSecond = find.byKey(
      const ValueKey<String>('translator-history-delete-second'),
    );
    expect(deleteSecond, findsOneWidget);
    await tester.ensureVisible(deleteSecond);
    await tester.pumpAndSettle();
    await tester.tap(deleteSecond);
    await tester.pumpAndSettle();

    expect(historyStore.entries, <TranslatorHistoryEntry>[first]);
    expect(
      find.byKey(const ValueKey<String>('translator-history-card-second')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('translator-history-card-first')),
      findsOneWidget,
    );

    final Finder clearAll = find.byKey(
      const ValueKey<String>('translator-history-clear-all'),
    );
    await tester.ensureVisible(clearAll);
    await tester.pumpAndSettle();
    await tester.tap(clearAll);
    await tester.pumpAndSettle();

    expect(find.text('Удалить всю историю переводов?'), findsOneWidget);

    final Finder confirmClearAll = find.byKey(
      const ValueKey<String>('translator-history-clear-all-confirm'),
    );
    expect(confirmClearAll, findsOneWidget);
    await tester.tap(confirmClearAll);
    await tester.pumpAndSettle();

    expect(find.byType(TranslatorHistoryCard), findsNothing);
    expect(historyStore.entries, isEmpty);
  });

  testWidgets('uses automatic source detection and text-only run button', (
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
  testWidgets('accepts multilingual keyboard input without a selector', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(
      tester,
      provider: _SuccessProvider(_report()),
      draftStore: _MemoryDraftStore(),
      accessKeyStore: _MemoryAccessKeyStore(value: 'saved-key'),
    );

    const String multilingual = 'Русский English ไทย';
    await tester.enterText(
      find.byKey(const ValueKey<String>('translator-source-text-field')),
      multilingual,
    );
    await tester.pump();

    final TextField field = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('translator-source-text-field')),
    );
    expect(field.controller?.text, multilingual);
    expect(field.minLines, 5);
    expect(field.maxLines, 12);
    expect(
      find.byKey(const ValueKey<String>('translator-source-language-menu')),
      findsNothing,
    );
  });
}

Future<void> _scrollToHistory(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('История переводов'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpTranslator(
  WidgetTester tester, {
  required TranslatorProvider provider,
  required TranslatorDraftStore draftStore,
  required TranslatorAccessKeyStore accessKeyStore,
  TranslatorHistoryStore? historyStore,
  TranslatorWorkspaceController? controller,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TranslatorWorkspaceView(
          provider: provider,
          draftStore: draftStore,
          historyStore: historyStore ?? _MemoryHistoryStore(),
          accessKeyStore: accessKeyStore,
          controller: controller,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

TranslatorRunReport _report() {
  return _reportAt(DateTime.utc(2026, 7, 26, 6));
}

TranslatorRunReport _reportAt(DateTime createdAt) {
  final TranslatorWorkRequest request = TranslatorWorkRequest(
    sourceText: 'Фотография установленной варочной панели.',
  );

  return TranslatorRunReport(
    request: request,
    bundle: TranslationBundle(
      sourceLanguage: TranslationLanguage.ru,
      sourceText: request.sourceText,
      ru: request.sourceText,
      en: 'Photo of the installed cooktop.',
      th: 'ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว',
      reverseTranslations: ReverseTranslationBundle(
        enToRu: 'Фотография установленной варочной панели.',
        thToRu: 'Фотография установленной варочной панели.',
        enToTh: 'ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว',
        thToEn: 'Photo of the installed cooktop.',
      ),
    ),
    audit: TranslationAudit(),
    createdAt: createdAt,
  );
}

final class _MemoryDraftStore implements TranslatorDraftStore {
  _MemoryDraftStore({this.draft});

  TranslatorDraft? draft;

  @override
  Future<TranslatorDraft?> load() async => draft;

  @override
  Future<void> save(TranslatorDraft draft) async {
    this.draft = draft;
  }

  @override
  Future<void> clear() async {
    draft = null;
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

final class _MemoryHistoryStore implements TranslatorHistoryStore {
  _MemoryHistoryStore({
    Iterable<TranslatorHistoryEntry> entries = const <TranslatorHistoryEntry>[],
  }) : entries = List<TranslatorHistoryEntry>.of(entries);

  List<TranslatorHistoryEntry> entries;

  @override
  Future<List<TranslatorHistoryEntry>> load() async {
    return List<TranslatorHistoryEntry>.unmodifiable(entries);
  }

  @override
  Future<void> save(List<TranslatorHistoryEntry> entries) async {
    this.entries = List<TranslatorHistoryEntry>.of(entries);
  }

  @override
  Future<void> clear() async {
    entries = <TranslatorHistoryEntry>[];
  }
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
