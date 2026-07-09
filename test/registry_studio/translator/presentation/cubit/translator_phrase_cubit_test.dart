import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/cubit/translator_phrase_cubit.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/cubit/translator_phrase_state.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  group('TranslatorPhraseCubit', () {
    test('starts with initial state', () {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider();
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      expect(cubit.state, const TranslatorPhraseState.initial());
    });

    test(
      'emits loading and success when phrase translation succeeds',
      () async {
        final TranslatorPhraseResult expected = TranslatorPhraseResult(
          sourceLanguage: 'en',
          sourceText: 'Check wording.',
          status: TranslatorPhraseStatus.equivalent,
          ru: 'Проверить формулировку.',
        );
        final _FakeTranslatorPhraseProvider provider =
            _FakeTranslatorPhraseProvider(result: expected);
        final TranslatorPhraseCubit cubit = _cubitFor(provider);
        addTearDown(cubit.close);

        final List<TranslatorPhraseState> states = <TranslatorPhraseState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.translatePhrase(
          sourceText: ' Check wording. ',
          sourceLanguageHint: ' en ',
          engineerContext: ' Registry wording review. ',
        );
        await subscription.cancel();

        expect(provider.callCount, 1);
        expect(provider.sourceText, 'Check wording.');
        expect(provider.sourceLanguageHint, 'en');
        expect(provider.engineerContext, 'Registry wording review.');
        expect(states, <TranslatorPhraseState>[
          const TranslatorPhraseState.loading(),
          TranslatorPhraseState.success(result: expected),
        ]);
        expect(cubit.state.result, same(expected));
      },
    );

    test(
      'emits failure when source text is empty before provider call',
      () async {
        final _FakeTranslatorPhraseProvider provider =
            _FakeTranslatorPhraseProvider();
        final TranslatorPhraseCubit cubit = _cubitFor(provider);
        addTearDown(cubit.close);

        final List<TranslatorPhraseState> states = <TranslatorPhraseState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.translatePhrase(sourceText: '   ');
        await subscription.cancel();

        expect(provider.callCount, 0);
        expect(states.first, const TranslatorPhraseState.loading());
        expect(states.last.status, TranslatorPhrasePresentationStatus.failure);
        expect(
          states.last.errorMessage,
          contains('Translator phrase source text must not be empty.'),
        );
      },
    );

    test('emits failure when use case throws unexpected error', () async {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(error: StateError('provider exploded'));
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      final List<TranslatorPhraseState> states = <TranslatorPhraseState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.translatePhrase(sourceText: 'Check wording.');
      await subscription.cancel();

      expect(provider.callCount, 1);
      expect(states.first, const TranslatorPhraseState.loading());
      expect(states.last.status, TranslatorPhrasePresentationStatus.failure);
      expect(states.last.errorMessage, contains('provider exploded'));
    });

    test('clears current phrase result', () async {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider();
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      await cubit.translatePhrase(sourceText: 'Check wording.');
      expect(cubit.state.status, TranslatorPhrasePresentationStatus.success);

      cubit.clear();

      expect(cubit.state, const TranslatorPhraseState.initial());
    });
  });
}

TranslatorPhraseCubit _cubitFor(_FakeTranslatorPhraseProvider provider) {
  return TranslatorPhraseCubit(
    translatePhrase: TranslatePhrase(provider: provider),
  );
}

final class _FakeTranslatorPhraseProvider implements TranslatorPhraseProvider {
  _FakeTranslatorPhraseProvider({TranslatorPhraseResult? result, this.error})
    : result =
          result ??
          TranslatorPhraseResult(
            sourceLanguage: 'en',
            sourceText: 'Check wording.',
            status: TranslatorPhraseStatus.exact,
          );

  final TranslatorPhraseResult result;
  final Object? error;

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

    final Object? error = this.error;
    if (error != null) {
      throw error;
    }

    return result;
  }
}
