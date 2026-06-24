import '../entities/translation_result.dart';

abstract interface class TranslatorRepository {
  Future<TranslationResult> translate(String sentence);
}
