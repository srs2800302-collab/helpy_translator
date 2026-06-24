import '../entities/translation_result.dart';
import '../repositories/translator_repository.dart';

final class TranslateCanonicalPhrase {
  const TranslateCanonicalPhrase(this.repository);

  final TranslatorRepository repository;

  Future<TranslationResult> call(String sentence) {
    return repository.translate(sentence);
  }
}
