import '../translator_phrase_result.dart';

abstract interface class TranslatorPhraseHistoryPersistence {
  Future<List<TranslatorPhraseResult>> load();

  Future<void> save(List<TranslatorPhraseResult> history);

  Future<void> clear();
}
