import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/cubit/translator_phrase_cubit.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/screens/translator_phrase_screen.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  group('TranslatorPhraseScreen', () {
    testWidgets('renders isolated phrase translation form', (
      WidgetTester tester,
    ) async {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider();
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      await tester.pumpWidget(_testApp(cubit));

      expect(find.text('Адаптивный переводчик'), findsNothing);
      expect(find.text('Каноническая формулировка'), findsOneWidget);
      expect(find.text('Дополнительные параметры'), findsOneWidget);
      expect(find.text('Перевести'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.text('✅ Exact: 0'), findsOneWidget);
      expect(find.text('🟢 Equivalent: 0'), findsOneWidget);
      expect(find.text('🟡 Review: 0'), findsOneWidget);
      expect(find.text('🔴 Drift: 0'), findsOneWidget);
      expect(find.text('❌ Failed: 0'), findsOneWidget);
      expect(
        find.byKey(const Key('translator_phrase_language_hint_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('translator_phrase_engineer_context_field')),
        findsNothing,
      );

      final Finder languageControl = find.byKey(
        const Key('translator_phrase_language_hint_field'),
      );
      final Finder parametersLabel = find.text('Дополнительные параметры');

      expect(find.byIcon(Icons.translate), findsNothing);
      expect(find.byIcon(Icons.tune), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(
        (tester.getCenter(languageControl).dy -
                tester.getCenter(parametersLabel).dy)
            .abs(),
        lessThan(2),
      );

      await tester.tap(
        find.byKey(const Key('translator_phrase_advanced_options_tile')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Исходный язык — необязательно'), findsNothing);
      expect(
        find.byKey(const Key('translator_phrase_language_hint_field')),
        findsOneWidget,
      );
      expect(find.text('Авто'), findsOneWidget);
      expect(find.text('Контекст инженера'), findsOneWidget);
    });

    testWidgets('submits text through TranslatorPhraseCubit', (
      WidgetTester tester,
    ) async {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider();
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      await tester.pumpWidget(_testApp(cubit));
      await tester.tap(
        find.byKey(const Key('translator_phrase_advanced_options_tile')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('translator_phrase_source_text_field')),
        ' Check wording. ',
      );
      await tester.tap(
        find.byKey(const Key('translator_phrase_language_hint_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('translator_phrase_engineer_context_field')),
        ' Registry wording review. ',
      );

      await tester.tap(
        find.byKey(const Key('translator_phrase_translate_button')),
      );
      await tester.pumpAndSettle();

      expect(provider.callCount, 1);
      expect(provider.sourceText, 'Check wording.');
      expect(provider.sourceLanguageHint, 'en');
      expect(provider.engineerContext, 'Registry wording review.');
      expect(find.text('Точное совпадение'), findsOneWidget);
      expect(find.text('Результаты переводов'), findsOneWidget);
      expect(find.text('Проверить формулировку.'), findsOneWidget);
      expect(find.text('✅ Exact: 1'), findsOneWidget);
    });

    testWidgets('shows verdict, all nine sections, audit criteria and reason', (
      WidgetTester tester,
    ) async {
      final TranslatorPhraseResult result = TranslatorPhraseResult(
        sourceLanguage: 'en',
        sourceText: 'SOURCE TEXT value',
        status: TranslatorPhraseStatus.needsReview,
        ru: 'RU value',
        en: 'EN value',
        th: 'TH value',
        enToRu: 'EN_TO_RU value',
        thToRu: 'TH_TO_RU value',
        enToTh: 'EN_TO_TH value',
        thToEn: 'TH_TO_EN value',
        comment: '''
MEANING_PRESERVED: YES
TERMINOLOGY_PRESERVED: NO
CANONICAL_STYLE_PRESERVED: NO
AMBIGUOUS_WORDING: YES

REASON
Full audit reason.
''',
      );
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(result: result);
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      await tester.pumpWidget(_testApp(cubit));

      await tester.enterText(
        find.byKey(const Key('translator_phrase_source_text_field')),
        'Submitted wording.',
      );
      await tester.tap(
        find.byKey(const Key('translator_phrase_translate_button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Нужна проверка'));
      await tester.pumpAndSettle();

      expect(find.text('Вердикт'), findsOneWidget);
      expect(find.text('Нужна проверка'), findsNWidgets(2));

      for (final String sectionLabel in <String>[
        'SOURCE LANGUAGE',
        'SOURCE TEXT',
        'RU',
        'EN',
        'TH',
        'EN_TO_RU',
        'TH_TO_RU',
        'EN_TO_TH',
        'TH_TO_EN',
      ]) {
        expect(
          find.text(sectionLabel),
          findsOneWidget,
          reason: 'Missing result section: $sectionLabel',
        );
      }

      expect(find.text('en'), findsOneWidget);
      expect(find.text('SOURCE TEXT value'), findsOneWidget);
      expect(find.text('RU value'), findsNWidgets(2));
      expect(find.text('EN value'), findsOneWidget);
      expect(find.text('TH value'), findsOneWidget);
      expect(find.text('EN_TO_RU value'), findsOneWidget);
      expect(find.text('TH_TO_RU value'), findsOneWidget);
      expect(find.text('EN_TO_TH value'), findsOneWidget);
      expect(find.text('TH_TO_EN value'), findsOneWidget);

      expect(find.text('Аудит и диагностика'), findsOneWidget);
      expect(find.textContaining('MEANING_PRESERVED: YES'), findsOneWidget);
      expect(find.textContaining('TERMINOLOGY_PRESERVED: NO'), findsOneWidget);
      expect(
        find.textContaining('CANONICAL_STYLE_PRESERVED: NO'),
        findsOneWidget,
      );
      expect(find.textContaining('AMBIGUOUS_WORDING: YES'), findsOneWidget);
      expect(find.textContaining('REASON\nFull audit reason.'), findsOneWidget);
    });

    testWidgets('shows loading state while translation is pending', (
      WidgetTester tester,
    ) async {
      final Completer<TranslatorPhraseResult> completer =
          Completer<TranslatorPhraseResult>();
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(completer: completer);
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      await tester.pumpWidget(_testApp(cubit));

      await tester.enterText(
        find.byKey(const Key('translator_phrase_source_text_field')),
        'Check wording.',
      );
      await tester.tap(
        find.byKey(const Key('translator_phrase_translate_button')),
      );
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      completer.complete(_defaultResult());
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Точное совпадение'), findsOneWidget);
    });

    testWidgets('shows presentation error message', (
      WidgetTester tester,
    ) async {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider();
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      await tester.pumpWidget(_testApp(cubit));

      await tester.tap(
        find.byKey(const Key('translator_phrase_translate_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Translator phrase source text must not be empty.'),
        findsOneWidget,
      );
      expect(provider.callCount, 0);
    });

    testWidgets('clears text fields and current result', (
      WidgetTester tester,
    ) async {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider();
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      await tester.pumpWidget(_testApp(cubit));
      await tester.tap(
        find.byKey(const Key('translator_phrase_advanced_options_tile')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('translator_phrase_source_text_field')),
        'Check wording.',
      );
      await tester.tap(
        find.byKey(const Key('translator_phrase_language_hint_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('translator_phrase_engineer_context_field')),
        'Registry wording review.',
      );
      await tester.tap(
        find.byKey(const Key('translator_phrase_translate_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Точное совпадение'), findsOneWidget);

      await tester.tap(find.byKey(const Key('translator_phrase_clear_button')));
      await tester.pumpAndSettle();

      expect(find.text('Точное совпадение'), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('translator_phrase_source_text_field')),
            )
            .controller
            ?.text,
        isEmpty,
      );
      expect(find.text('Авто'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('translator_phrase_engineer_context_field')),
            )
            .controller
            ?.text,
        isEmpty,
      );
    });
    testWidgets('requests operation for candidate phrase result', (
      WidgetTester tester,
    ) async {
      final TranslatorPhraseResult result = TranslatorPhraseResult(
        sourceLanguage: 'en',
        sourceText: 'Check wording.',
        status: TranslatorPhraseStatus.canonicalDrift,
        comment: 'Canonical review required.',
        candidateCanonicalPhrase: 'Check canonical wording.',
      );
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(result: result);
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      TranslatorPhraseResult? requestedResult;

      await tester.pumpWidget(
        _testApp(
          cubit,
          onOperationRequested: (TranslatorPhraseResult value) {
            requestedResult = value;
          },
        ),
      );

      await tester.enterText(
        find.byKey(const Key('translator_phrase_source_text_field')),
        result.sourceText,
      );

      await tester.tap(
        find.byKey(const Key('translator_phrase_translate_button')),
      );
      await tester.pumpAndSettle();

      final Finder requestButton = find.byKey(
        const Key('translator_phrase_request_operation_button'),
      );
      final Finder translatorList = find.descendant(
        of: find.byType(TranslatorPhraseScreen),
        matching: find.byType(ListView),
      );

      await tester.dragUntilVisible(
        requestButton,
        translatorList,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(requestButton, findsOneWidget);

      await tester.tap(requestButton);
      await tester.pump();

      expect(requestedResult, same(result));
    });
  });
}

Widget _testApp(
  TranslatorPhraseCubit cubit, {
  ValueChanged<TranslatorPhraseResult>? onOperationRequested,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<TranslatorPhraseCubit>.value(
        value: cubit,
        child: TranslatorPhraseScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          onOperationRequested: onOperationRequested,
        ),
      ),
    ),
  );
}

TranslatorPhraseCubit _cubitFor(_FakeTranslatorPhraseProvider provider) {
  return TranslatorPhraseCubit(
    translatePhrase: TranslatePhrase(provider: provider),
  );
}

TranslatorPhraseResult _defaultResult() {
  return TranslatorPhraseResult(
    sourceLanguage: 'en',
    sourceText: 'Check wording.',
    status: TranslatorPhraseStatus.exact,
    ru: 'Проверить формулировку.',
    en: 'Check wording.',
    th: 'ตรวจสอบข้อความ',
    enToRu: 'Проверить формулировку.',
    thToRu: 'Проверить текст.',
    enToTh: 'ตรวจสอบข้อความ',
    thToEn: 'Check text.',
    comment: 'Формулировка корректна.',
  );
}

final class _FakeTranslatorPhraseProvider implements TranslatorPhraseProvider {
  _FakeTranslatorPhraseProvider({
    TranslatorPhraseResult? result,
    this.completer,
  }) : result = result ?? _defaultResult();

  final TranslatorPhraseResult result;
  final Completer<TranslatorPhraseResult>? completer;

  int callCount = 0;
  String? sourceText;
  String? sourceLanguageHint;
  String? engineerContext;

  @override
  Future<TranslatorPhraseResult> translatePhrase({
    required String sourceText,
    String? sourceLanguageHint,
    String? engineerContext,
  }) async {
    callCount++;
    this.sourceText = sourceText;
    this.sourceLanguageHint = sourceLanguageHint;
    this.engineerContext = engineerContext;

    final Completer<TranslatorPhraseResult>? pending = completer;
    if (pending != null) {
      return pending.future;
    }

    return result;
  }
}
