import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  group('TranslatePhrase', () {
    test('normalizes phrase input before provider call', () async {
      final _CapturingTranslatorPhraseProvider provider =
          _CapturingTranslatorPhraseProvider();
      final TranslatePhrase useCase = TranslatePhrase(provider: provider);

      await useCase(sourceText: ' Check wording. ');

      expect(provider.sourceText, 'Check wording.');
      expect(provider.callCount, 1);
    });

    test('rejects empty source text before provider call', () {
      final _CapturingTranslatorPhraseProvider provider =
          _CapturingTranslatorPhraseProvider();
      final TranslatePhrase useCase = TranslatePhrase(provider: provider);

      expect(() => useCase(sourceText: ''), throwsArgumentError);
      expect(() => useCase(sourceText: '   '), throwsArgumentError);
      expect(provider.callCount, 0);
    });

    test('returns provider phrase result unchanged', () async {
      final TranslatorPhraseResult expected = TranslatorPhraseResult(
        sourceLanguage: 'en',
        sourceText: 'Check wording.',
        status: TranslatorPhraseStatus.equivalent,
        ru: 'Проверить формулировку.',
      );
      final _CapturingTranslatorPhraseProvider provider =
          _CapturingTranslatorPhraseProvider(result: expected);
      final TranslatePhrase useCase = TranslatePhrase(provider: provider);

      final TranslatorPhraseResult actual = await useCase(
        sourceText: 'Check wording.',
      );

      expect(actual, same(expected));
    });
  });
}

final class _CapturingTranslatorPhraseProvider
    implements TranslatorPhraseProvider {
  _CapturingTranslatorPhraseProvider({TranslatorPhraseResult? result})
    : result =
          result ??
          TranslatorPhraseResult(
            sourceLanguage: 'en',
            sourceText: 'Check wording.',
            status: TranslatorPhraseStatus.exact,
          );

  final TranslatorPhraseResult result;
  int callCount = 0;
  String? sourceText;

  @override
  Future<TranslatorPhraseResult> translatePhrase({
    required String sourceText,
  }) async {
    callCount++;
    this.sourceText = sourceText;

    return result;
  }
}
