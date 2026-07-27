import '../domain/translator_models.dart';

abstract interface class TranslatorHistoryStore {
  Future<List<TranslatorHistoryEntry>> load();

  Future<void> save(List<TranslatorHistoryEntry> entries);

  Future<void> clear();
}
