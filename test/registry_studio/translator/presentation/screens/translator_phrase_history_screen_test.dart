import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_history_persistence.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/cubit/translator_phrase_cubit.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/screens/translator_phrase_screen.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  testWidgets('shows newest-first cumulative history and clears it', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final TranslatorPhraseResult first = TranslatorPhraseResult(
      sourceLanguage: 'en',
      sourceText: 'First phrase.',
      status: TranslatorPhraseStatus.exact,
      ru: 'Первый перевод.',
    );
    final TranslatorPhraseResult second = TranslatorPhraseResult(
      sourceLanguage: 'en',
      sourceText: 'Second phrase.',
      status: TranslatorPhraseStatus.equivalent,
      ru: 'Второй перевод.',
    );

    final _QueuedProvider provider = _QueuedProvider(<TranslatorPhraseResult>[
      first,
      second,
    ]);
    final _MemoryHistoryPersistence persistence = _MemoryHistoryPersistence();
    final TranslatorPhraseCubit cubit = TranslatorPhraseCubit(
      translatePhrase: TranslatePhrase(provider: provider),
      historyPersistence: persistence,
    );
    addTearDown(cubit.close);

    await cubit.restore();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<TranslatorPhraseCubit>.value(
            value: cubit,
            child: const TranslatorPhraseScreen(
              uiLanguage: RegistryStudioUiLanguage.ru,
            ),
          ),
        ),
      ),
    );

    final Finder sourceField = find.byKey(
      const Key('translator_phrase_source_text_field'),
    );
    final Finder translateButton = find.byKey(
      const Key('translator_phrase_translate_button'),
    );

    await tester.enterText(sourceField, first.sourceText);
    await tester.tap(translateButton);
    await tester.pumpAndSettle();

    await tester.ensureVisible(sourceField);
    await tester.enterText(sourceField, second.sourceText);
    await tester.tap(translateButton);
    await tester.pumpAndSettle();

    expect(find.text('Первый перевод.'), findsOneWidget);
    expect(find.text('Второй перевод.'), findsOneWidget);
    expect(find.text('✅ Exact: 1'), findsOneWidget);
    expect(find.text('🟢 Equivalent: 1'), findsOneWidget);

    final List<String> visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text widget) => widget.data)
        .whereType<String>()
        .toList(growable: false);

    expect(
      visibleText.indexOf('Второй перевод.'),
      lessThan(visibleText.indexOf('Первый перевод.')),
    );

    await tester.tap(find.byKey(const Key('translator_phrase_clear_button')));
    await tester.pumpAndSettle();

    expect(find.text('Первый перевод.'), findsNothing);
    expect(find.text('Второй перевод.'), findsNothing);
    expect(find.text('✅ Exact: 0'), findsOneWidget);
    expect(find.text('🟢 Equivalent: 0'), findsOneWidget);
    expect(persistence.clearCount, 1);
  });
}

final class _MemoryHistoryPersistence
    implements TranslatorPhraseHistoryPersistence {
  List<TranslatorPhraseResult> history = <TranslatorPhraseResult>[];
  int clearCount = 0;

  @override
  Future<List<TranslatorPhraseResult>> load() async {
    return List<TranslatorPhraseResult>.of(history);
  }

  @override
  Future<void> save(List<TranslatorPhraseResult> history) async {
    this.history = List<TranslatorPhraseResult>.of(history);
  }

  @override
  Future<void> clear() async {
    clearCount++;
    history = <TranslatorPhraseResult>[];
  }
}

final class _QueuedProvider implements TranslatorPhraseProvider {
  _QueuedProvider(this.results);

  final List<TranslatorPhraseResult> results;
  int index = 0;

  @override
  Future<TranslatorPhraseResult> translatePhrase({
    required String sourceText,
  }) async {
    return results[index++];
  }
}
