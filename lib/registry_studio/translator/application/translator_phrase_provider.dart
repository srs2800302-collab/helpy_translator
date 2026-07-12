import '../translator_phrase_result.dart';

abstract interface class TranslatorPhraseProvider {
  Future<TranslatorPhraseResult> translatePhrase({required String sourceText});
}
