import '../domain/entities/language_detection_result.dart';
import '../domain/entities/semantic_audit_report.dart';
import '../domain/entities/semantic_observation.dart';
import '../domain/entities/translation_language.dart';
import '../domain/entities/translation_matrix_result.dart';
import '../domain/entities/translation_route.dart';
import '../domain/entities/translation_route_result.dart';
import '../domain/errors/translator_exception.dart';
import '../domain/repositories/translator_api_key_store.dart';
import '../domain/repositories/translator_gateway.dart';
import '../domain/services/honesty_assessment_policy.dart';
import '../domain/services/source_language_detector.dart';
import '../domain/services/translation_route_planner.dart';
import 'translator_cancellation_signal.dart';
import 'translator_progress.dart';

typedef TranslatorProgressCallback = void Function(TranslatorProgress progress);
typedef TranslatorClock = DateTime Function();

final class RunTranslationMatrix {
  const RunTranslationMatrix({
    required this.apiKeyStore,
    required this.gateway,
    required this.languageDetector,
    required this.routePlanner,
    required this.assessmentPolicy,
    this.clock = DateTime.now,
  });

  static const int _workflowStepCount = 2;

  final TranslatorApiKeyStore apiKeyStore;
  final TranslatorGateway gateway;
  final SourceLanguageDetector languageDetector;
  final TranslationRoutePlanner routePlanner;
  final HonestyAssessmentPolicy assessmentPolicy;
  final TranslatorClock clock;

  Future<TranslationMatrixResult> call({
    required String sourceText,
    required SourceLanguageSelection sourceLanguageSelection,
    required TranslatorCancellationSignal cancellationSignal,
    required TranslatorProgressCallback onProgress,
  }) async {
    onProgress(
      const TranslatorProgress(
        stage: TranslatorProgressStage.validating,
        completedSteps: 0,
        totalSteps: 0,
      ),
    );

    if (sourceText.trim().isEmpty) {
      throw const TranslatorException(
        TranslatorFailureKind.validation,
        'Source text is empty.',
      );
    }

    cancellationSignal.throwIfCancelled();

    final TranslationLanguage sourceLanguage = _resolveSourceLanguage(
      sourceText: sourceText,
      selection: sourceLanguageSelection,
    );

    final String? storedApiKey;

    try {
      storedApiKey = await apiKeyStore.read();
    } on Object {
      throw const TranslatorException(
        TranslatorFailureKind.persistence,
        'The Typhoon API key could not be read from secure storage.',
      );
    }

    final String apiKey = storedApiKey?.trim() ?? '';

    if (apiKey.isEmpty) {
      throw const TranslatorException(
        TranslatorFailureKind.missingApiKey,
        'Typhoon API key is not configured.',
      );
    }

    final List<TranslationRoute> routes = routePlanner.build(sourceLanguage);
    _validateRoutePlan(routes: routes, sourceLanguage: sourceLanguage);

    cancellationSignal.throwIfCancelled();

    final List<TranslationRouteResult> routeResults = await _translateRoutes(
      apiKey: apiKey,
      originalSourceText: sourceText,
      originalSourceLanguage: sourceLanguage,
      routes: routes,
      cancellationSignal: cancellationSignal,
      onProgress: onProgress,
    );

    cancellationSignal.throwIfCancelled();

    _validateMatrixResults(
      originalSourceText: sourceText,
      originalSourceLanguage: sourceLanguage,
      routes: routes,
      results: routeResults,
    );

    onProgress(
      const TranslatorProgress(
        stage: TranslatorProgressStage.auditing,
        completedSteps: 1,
        totalSteps: _workflowStepCount,
      ),
    );

    final SemanticAuditReport auditReport = await gateway.auditMatrix(
      apiKey: apiKey,
      originalSourceText: sourceText,
      originalSourceLanguage: sourceLanguage,
      routes: List<TranslationRouteResult>.unmodifiable(routeResults),
    );

    cancellationSignal.throwIfCancelled();

    _validateAuditReport(routes: routeResults, report: auditReport);

    final assessment = assessmentPolicy.assess(auditReport);

    onProgress(
      const TranslatorProgress(
        stage: TranslatorProgressStage.completed,
        completedSteps: _workflowStepCount,
        totalSteps: _workflowStepCount,
      ),
    );

    return TranslationMatrixResult(
      sourceText: sourceText,
      sourceLanguage: sourceLanguage,
      routes: List<TranslationRouteResult>.unmodifiable(routeResults),
      assessment: assessment,
      createdAt: clock(),
      auditCoverage: TranslationAuditCoverage.expanded,
    );
  }

  Future<List<TranslationRouteResult>> _translateRoutes({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRoute> routes,
    required TranslatorCancellationSignal cancellationSignal,
    required TranslatorProgressCallback onProgress,
  }) async {
    final List<TranslationRoute> primaryRoutes = routes
        .where(
          (TranslationRoute route) =>
              route.role == TranslationRouteRole.primary,
        )
        .toList(growable: false);
    final List<TranslationRoute> crossCheckRoutes = routes
        .where(
          (TranslationRoute route) =>
              route.role == TranslationRouteRole.crossCheck,
        )
        .toList(growable: false);

    final Map<TranslationLanguage, String> sourceTexts =
        <TranslationLanguage, String>{
          originalSourceLanguage: originalSourceText,
        };

    final Map<String, TranslationRouteResult> resultsByRouteId =
        <String, TranslationRouteResult>{};

    for (final TranslationRoute route in <TranslationRoute>[
      ...primaryRoutes,
      ...crossCheckRoutes,
    ]) {
      cancellationSignal.throwIfCancelled();

      final String? routeSourceText = sourceTexts[route.source];

      if (routeSourceText == null || routeSourceText.trim().isEmpty) {
        throw TranslatorException(
          TranslatorFailureKind.validation,
          'Route ${route.id} has no completed source translation.',
        );
      }

      onProgress(
        TranslatorProgress(
          stage: TranslatorProgressStage.translating,
          completedSteps: 0,
          totalSteps: _workflowStepCount,
          currentRouteId: route.id,
        ),
      );

      final String translatedText = await gateway.translate(
        apiKey: apiKey,
        sourceLanguage: route.source,
        targetLanguage: route.target,
        sourceText: routeSourceText,
      );

      cancellationSignal.throwIfCancelled();

      if (translatedText.trim().isEmpty) {
        throw TranslatorException(
          TranslatorFailureKind.invalidResponse,
          'Route ${route.id} returned an empty translation.',
        );
      }

      resultsByRouteId[route.id] = TranslationRouteResult(
        route: route,
        sourceText: routeSourceText,
        translatedText: translatedText,
      );

      if (route.role == TranslationRouteRole.primary) {
        sourceTexts[route.target] = translatedText;
      }
    }

    final List<TranslationRouteResult> orderedResults =
        <TranslationRouteResult>[];

    for (final TranslationRoute route in routes) {
      final TranslationRouteResult? result = resultsByRouteId[route.id];

      if (result == null) {
        throw TranslatorException(
          TranslatorFailureKind.invalidResponse,
          'Route ${route.id} has no completed translation result.',
        );
      }

      orderedResults.add(result);
    }

    return List<TranslationRouteResult>.unmodifiable(orderedResults);
  }

  static void _validateRoutePlan({
    required List<TranslationRoute> routes,
    required TranslationLanguage sourceLanguage,
  }) {
    if (routes.length != 6) {
      throw const TranslatorException(
        TranslatorFailureKind.validation,
        'The translation matrix requires exactly six translation routes.',
      );
    }

    final Set<String> routeIds = routes
        .map((TranslationRoute route) => route.id)
        .toSet();

    if (routeIds.length != routes.length) {
      throw const TranslatorException(
        TranslatorFailureKind.validation,
        'The translation route plan contains duplicate routes.',
      );
    }

    final List<TranslationRoute> primaryRoutes = routes
        .where(
          (TranslationRoute route) =>
              route.role == TranslationRouteRole.primary,
        )
        .toList(growable: false);

    if (primaryRoutes.length != 2 ||
        primaryRoutes.any(
          (TranslationRoute route) => route.source != sourceLanguage,
        )) {
      throw const TranslatorException(
        TranslatorFailureKind.validation,
        'The translation matrix requires two source-language primary routes.',
      );
    }

    final Set<TranslationLanguage> derivedLanguages = primaryRoutes
        .map((TranslationRoute route) => route.target)
        .toSet();

    if (derivedLanguages.length != 2) {
      throw const TranslatorException(
        TranslatorFailureKind.validation,
        'The primary routes must target both remaining languages.',
      );
    }

    final List<TranslationRoute> crossCheckRoutes = routes
        .where(
          (TranslationRoute route) =>
              route.role == TranslationRouteRole.crossCheck,
        )
        .toList(growable: false);

    if (crossCheckRoutes.length != 4 ||
        crossCheckRoutes.any(
          (TranslationRoute route) => !derivedLanguages.contains(route.source),
        )) {
      throw const TranslatorException(
        TranslatorFailureKind.validation,
        'The translation matrix requires four cross-check routes derived from '
        'the two primary translations.',
      );
    }
  }

  static void _validateMatrixResults({
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRoute> routes,
    required List<TranslationRouteResult> results,
  }) {
    if (results.length != routes.length) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'The provider returned an incomplete translation matrix.',
      );
    }

    final Map<String, TranslationRoute> routesById = <String, TranslationRoute>{
      for (final TranslationRoute route in routes) route.id: route,
    };
    final Set<String> seenRouteIds = <String>{};
    final Map<TranslationLanguage, String> sourceTexts =
        <TranslationLanguage, String>{
          originalSourceLanguage: originalSourceText,
        };

    for (final TranslationRouteResult result in results) {
      final TranslationRoute? expectedRoute = routesById[result.route.id];

      if (expectedRoute == null ||
          !seenRouteIds.add(result.route.id) ||
          result.route != expectedRoute ||
          result.translatedText.trim().isEmpty) {
        throw const TranslatorException(
          TranslatorFailureKind.invalidResponse,
          'The provider returned an inconsistent translation matrix.',
        );
      }

      if (result.route.role == TranslationRouteRole.primary) {
        if (result.sourceText != originalSourceText) {
          throw const TranslatorException(
            TranslatorFailureKind.invalidResponse,
            'A primary route does not preserve the original source text.',
          );
        }

        sourceTexts[result.route.target] = result.translatedText;
      }
    }

    for (final TranslationRouteResult result in results) {
      if (result.route.role != TranslationRouteRole.crossCheck) {
        continue;
      }

      final String? expectedSourceText = sourceTexts[result.route.source];

      if (expectedSourceText == null ||
          result.sourceText != expectedSourceText) {
        throw TranslatorException(
          TranslatorFailureKind.invalidResponse,
          'Cross-check route ${result.route.id} does not use the generated '
          'primary translation as its source text.',
        );
      }
    }
  }

  static void _validateAuditReport({
    required List<TranslationRouteResult> routes,
    required SemanticAuditReport report,
  }) {
    final Map<String, TranslationRouteRole> expectedRolesByRouteId =
        <String, TranslationRouteRole>{
          for (final TranslationRouteResult route in routes)
            route.route.id: route.route.role,
        };
    final Set<String> seenRouteIds = <String>{};

    for (final SemanticObservation observation in report.observations) {
      final TranslationRouteRole? expectedRole =
          expectedRolesByRouteId[observation.routeId];

      if (expectedRole == null || observation.routeRole != expectedRole) {
        throw const TranslatorException(
          TranslatorFailureKind.invalidResponse,
          'The audit returned inconsistent translation-route coverage.',
        );
      }

      seenRouteIds.add(observation.routeId);
    }

    if (seenRouteIds.length != expectedRolesByRouteId.length) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'The audit omitted one or more translation routes.',
      );
    }
  }

  TranslationLanguage _resolveSourceLanguage({
    required String sourceText,
    required SourceLanguageSelection selection,
  }) {
    final TranslationLanguage? explicitLanguage = selection.explicitLanguage;

    if (explicitLanguage != null) {
      return explicitLanguage;
    }

    final LanguageDetectionResult detection = languageDetector.detect(
      sourceText,
    );

    if (detection.status == LanguageDetectionStatus.mixed) {
      throw const TranslatorException(
        TranslatorFailureKind.unsupportedLanguage,
        'The source text contains multiple supported writing systems. '
        'Select the source language explicitly.',
      );
    }

    final TranslationLanguage? detectedLanguage = detection.detectedLanguage;

    if (detectedLanguage == null) {
      throw const TranslatorException(
        TranslatorFailureKind.unsupportedLanguage,
        'The source language could not be determined reliably. '
        'Select RU, EN, or TH explicitly.',
      );
    }

    return detectedLanguage;
  }
}
