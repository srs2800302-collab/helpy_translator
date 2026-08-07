import '../entities/semantic_audit_report.dart';
import '../entities/translation_batch_request.dart';
import '../entities/translation_language.dart';
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

  Future<SemanticAuditReport> auditMatrix({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRouteResult> routes,
  });

  void close();
}
