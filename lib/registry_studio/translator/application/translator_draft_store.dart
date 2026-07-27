import '../domain/translator_models.dart';

abstract interface class TranslatorDraftStore {
  Future<TranslatorDraft?> load();

  Future<void> save(TranslatorDraft draft);

  Future<void> clear();
}

final class TranslatorDraft {
  const TranslatorDraft({
    required this.sourceText,
    this.report,
    this.partialBundle,
  }) : assert(
         report == null || partialBundle == null,
         'A draft cannot contain both a report and a partial bundle.',
       );

  final String sourceText;
  final TranslatorRunReport? report;
  final TranslationBundle? partialBundle;
}
