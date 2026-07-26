import '../domain/translator_models.dart';

abstract interface class TranslatorDraftStore {
  Future<TranslatorDraft?> load();

  Future<void> save(TranslatorDraft draft);

  Future<void> clear();
}

final class TranslatorDraft {
  const TranslatorDraft({
    required this.sourceText,
    this.sourceLanguageHint,
    this.report,
  });

  final String sourceText;
  final TranslationLanguage? sourceLanguageHint;
  final TranslatorRunReport? report;
}
