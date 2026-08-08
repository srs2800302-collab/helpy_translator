import '../entities/primary_linguist_report.dart';
import '../entities/translation_language.dart';
import '../entities/translation_route_result.dart';

abstract interface class PrimaryLinguistGateway {
  Future<PrimaryLinguistReport> evaluatePrimaryTranslations({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRouteResult> primaryRoutes,
  });
}
