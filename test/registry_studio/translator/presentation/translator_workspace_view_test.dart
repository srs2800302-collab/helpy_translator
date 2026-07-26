import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_draft_store.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_provider.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/translator_workspace_view.dart';

void main() {
  testWidgets('shows nine sections and automatic verdict', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranslatorWorkspaceView(
            provider: _SuccessProvider(report),
            draftStore: _MemoryDraftStore(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'test-key');
    await tester.enterText(
      find.byType(TextField).at(1),
      report.request.sourceText,
    );

    await tester.tap(find.text('Перевести и проверить'));
    await tester.pumpAndSettle();

    expect(find.text('Автоматический вердикт перевода'), findsOneWidget);
    expect(find.text('EXACT'), findsOneWidget);
    expect(find.text('Прямой перевод'), findsOneWidget);
    expect(find.text('Независимая обратная проверка'), findsOneWidget);
    expect(find.text('EN → RU'), findsOneWidget);
    expect(find.text('TH → EN'), findsOneWidget);
    expect(find.text('Аудит и диагностика'), findsOneWidget);
  });

  testWidgets('clear removes Translator result only', (
    WidgetTester tester,
  ) async {
    final TranslatorRunReport report = _report();
    final _MemoryDraftStore store = _MemoryDraftStore(
      draft: TranslatorDraft(
        sourceText: report.request.sourceText,
        sourceLanguageHint: TranslationLanguage.ru,
        report: report,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranslatorWorkspaceView(
            provider: _SuccessProvider(report),
            draftStore: store,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('EXACT'), findsOneWidget);

    await tester.tap(find.text('Очистить Translator'));
    await tester.pumpAndSettle();

    expect(find.text('EXACT'), findsNothing);
    expect(store.clearCount, 1);
  });
}

TranslatorRunReport _report() {
  final TranslatorWorkRequest request = TranslatorWorkRequest(
    sourceText: 'Фотография установленной варочной панели.',
    sourceLanguageHint: TranslationLanguage.ru,
  );

  return TranslatorRunReport(
    request: request,
    bundle: TranslationBundle(
      sourceLanguage: TranslationLanguage.ru,
      sourceText: request.sourceText,
      ru: request.sourceText,
      en: 'Photo of the installed cooktop.',
      th: 'ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว',
      enToRu: request.sourceText,
      thToRu: request.sourceText,
      enToTh: 'ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว',
      thToEn: 'Photo of the installed cooktop.',
    ),
    audit: TranslationAudit(),
    createdAt: DateTime.utc(2026, 7, 26, 6),
  );
}

final class _MemoryDraftStore implements TranslatorDraftStore {
  _MemoryDraftStore({this.draft});

  TranslatorDraft? draft;
  int clearCount = 0;

  @override
  Future<TranslatorDraft?> load() async => draft;

  @override
  Future<void> save(TranslatorDraft draft) async {
    this.draft = draft;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
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
