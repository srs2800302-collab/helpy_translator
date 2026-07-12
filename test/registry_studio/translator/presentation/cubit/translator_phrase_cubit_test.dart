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

        final Future<dynamic> expectation = expectLater(
          cubit.stream,
          emitsInOrder(<TranslatorPhraseState>[
            const TranslatorPhraseState.loading(),
            TranslatorPhraseState.success(result: expected),
          ]),
        );

        await cubit.translatePhrase(sourceText: ' Check wording. ');
        await expectation;

        expect(provider.callCount, 1);
        expect(provider.sourceText, 'Check wording.');
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

        final Future<dynamic> expectation = expectLater(
          cubit.stream,
          emitsInOrder(<Object>[
            const TranslatorPhraseState.loading(),
            isA<TranslatorPhraseState>()
                .having(
                  (TranslatorPhraseState state) => state.status,
                  'status',
                  TranslatorPhrasePresentationStatus.failure,
                )
                .having(
                  (TranslatorPhraseState state) => state.errorMessage,
                  'errorMessage',
                  contains('Translator phrase source text must not be empty.'),
                ),
          ]),
        );

        await cubit.translatePhrase(sourceText: '   ');
        await expectation;

        expect(provider.callCount, 0);
      },
    );

    test('emits failure when use case throws unexpected error', () async {
      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(error: StateError('provider exploded'));
      final TranslatorPhraseCubit cubit = _cubitFor(provider);
      addTearDown(cubit.close);

      final Future<dynamic> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<Object>[
          const TranslatorPhraseState.loading(),
          isA<TranslatorPhraseState>()
              .having(
                (TranslatorPhraseState state) => state.status,
                'status',
                TranslatorPhrasePresentationStatus.failure,
              )
              .having(
                (TranslatorPhraseState state) => state.errorMessage,
                'errorMessage',
                contains('provider exploded'),
              ),
        ]),
      );

      await cubit.translatePhrase(sourceText: 'Check wording.');
      await expectation;

      expect(provider.callCount, 1);
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

  @override
  Future<TranslatorPhraseResult> translatePhrase({
    required String sourceText,
  }) async {
    callCount++;
    this.sourceText = sourceText;

    final Object? error = this.error;
    if (error != null) {
      throw error;
    }

    return result;
  }
}
