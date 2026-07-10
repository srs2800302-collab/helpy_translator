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

      expect(find.text('Перевод формулировки'), findsOneWidget);
      expect(find.text('Формулировка или текст'), findsOneWidget);
      expect(find.text('Подсказка языка'), findsOneWidget);
      expect(find.text('Контекст инженера'), findsOneWidget);
      expect(find.text('Перевести'), findsOneWidget);
      expect(find.text('Очистить'), findsOneWidget);
    });

    testWidgets('submits text through TranslatorPhraseCubit', (
      WidgetTester tester,
    ) async {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider();
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      await tester.pumpWidget(_testApp(cubit));

      await tester.enterText(
        find.byKey(const Key('translator_phrase_source_text_field')),
        ' Check wording. ',
      );
      await tester.enterText(
        find.byKey(const Key('translator_phrase_language_hint_field')),
        ' en ',
      );
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
      expect(find.text('RU:\nПроверить формулировку.'), findsOneWidget);
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

      await tester.enterText(
        find.byKey(const Key('translator_phrase_source_text_field')),
        'Check wording.',
      );
      await tester.enterText(
        find.byKey(const Key('translator_phrase_language_hint_field')),
        'en',
      );
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
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('translator_phrase_language_hint_field')),
            )
            .controller
            ?.text,
        isEmpty,
      );
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
  });
}

Widget _testApp(TranslatorPhraseCubit cubit) {
  return MaterialApp(
    home: BlocProvider<TranslatorPhraseCubit>.value(
      value: cubit,
      child: const TranslatorPhraseScreen(
        uiLanguage: RegistryStudioUiLanguage.ru,
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
