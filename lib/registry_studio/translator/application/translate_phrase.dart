import '../translator_phrase_result.dart';
import 'translator_phrase_provider.dart';

final class TranslatePhrase {
  const TranslatePhrase({required TranslatorPhraseProvider provider})
    : _provider = provider;

  final TranslatorPhraseProvider _provider;

  Future<TranslatorPhraseResult> call({required String sourceText}) {
    return _provider.translatePhrase(
      sourceText: _requiredText(
        sourceText,
        'sourceText',
        'Translator phrase source text must not be empty.',
      ),
    );
  }

  static String _requiredText(String value, String name, String message) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, message);
    }

    return normalized;
  }
}
