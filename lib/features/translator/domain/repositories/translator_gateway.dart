import '../entities/semantic_audit_report.dart';
import '../entities/translation_batch_request.dart';
import '../entities/translation_language.dart';
import '../entities/translation_route.dart';
import '../entities/translation_route_result.dart';

abstract interface class TranslatorGateway {
  Future<String> translate({
    required String apiKey,
    required TranslationLanguage sourceLanguage,
    required TranslationLanguage targetLanguage,
    required String sourceText,
  });

  Future<List<TranslationRouteResult>> translateBatch({
    required String apiKey,
    required List<TranslationBatchRequest> requests,
  });

  /// Prototype-compatible one-call matrix generation.
  ///
  /// The provider receives the original text and the complete six-route plan,
  /// then returns one translation value for every route.
  Future<List<TranslationRouteResult>> translatePrototypeMatrix({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRoute> routes,
  });

  Future<SemanticAuditReport> auditMatrix({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRouteResult> routes,
  });

  /// Evidence-based verification of the complete matrix.
  ///
  /// The Typhoon implementation performs five isolated audit calls after the
  /// matrix translation: source analysis, target analysis, adversarial
  /// challenge, equivalence defense, and neutral evidence verification.
  /// One transient retry is shared by the complete audit, so a user run is
  /// bounded to seven provider calls including translation.
  Future<SemanticAuditReport> auditPrototypeMatrix({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRouteResult> routes,
  });

  void close();
}
