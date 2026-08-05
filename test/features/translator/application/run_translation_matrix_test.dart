import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/features/translator/application/run_translation_matrix.dart';
import 'package:helpy_translator/features/translator/application/translator_cancellation_signal.dart';
import 'package:helpy_translator/features/translator/application/translator_progress.dart';
import 'package:helpy_translator/features/translator/domain/entities/matrix_assessment.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_audit_report.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_observation.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_batch_request.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_matrix_result.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route_result.dart';
import 'package:helpy_translator/features/translator/domain/errors/translator_exception.dart';
import 'package:helpy_translator/features/translator/domain/repositories/translator_api_key_store.dart';
import 'package:helpy_translator/features/translator/domain/repositories/translator_gateway.dart';
import 'package:helpy_translator/features/translator/domain/services/honesty_assessment_policy.dart';
import 'package:helpy_translator/features/translator/domain/services/source_language_detector.dart';
import 'package:helpy_translator/features/translator/domain/services/translation_route_planner.dart';

void main() {
  late _MemoryApiKeyStore apiKeyStore;
  late _RecordingGateway gateway;
  late RunTranslationMatrix useCase;

  setUp(() {
    apiKeyStore = _MemoryApiKeyStore('secret');
    gateway = _RecordingGateway();
    useCase = RunTranslationMatrix(
      apiKeyStore: apiKeyStore,
      gateway: gateway,
      languageDetector: const ScriptSourceLanguageDetector(),
      routePlanner: const CompleteThreeLanguageRoutePlanner(),
      assessmentPolicy: const ConservativeHonestyAssessmentPolicy(),
      clock: () => DateTime.utc(2026, 8, 5),
    );
  });

  test('prototype workflow uses one matrix call and one audit call', () async {
    const String exactSource = '  Send it after confirmation.  ';
    final List<TranslatorProgress> progress = <TranslatorProgress>[];

    final TranslationMatrixResult result = await useCase(
      sourceText: exactSource,
      sourceLanguageSelection: SourceLanguageSelection.english,
      cancellationSignal: TranslatorCancellationSignal(),
      onProgress: progress.add,
    );

    expect(result.sourceText, exactSource);
    expect(result.sourceLanguage, TranslationLanguage.english);
    expect(result.auditCoverage, TranslationAuditCoverage.prototype);
    expect(result.routes, hasLength(6));
    expect(
      result.routes.map((TranslationRouteResult result) => result.route.id),
      <String>[
        'EN_TO_RU',
        'EN_TO_TH',
        'RU_TO_EN',
        'RU_TO_TH',
        'TH_TO_RU',
        'TH_TO_EN',
      ],
    );
    expect(gateway.prototypeTranslationCalls, 1);
    expect(gateway.prototypeAuditCalls, 1);
    expect(gateway.batchCalls, 0);
    expect(gateway.regularAuditCalls, 0);
    expect(result.assessment.verdict, MatrixVerdict.acceptableVariation);
    expect(result.toJson()['audit_coverage'], 'prototype');
    expect(progress.last.stage, TranslatorProgressStage.completed);
    expect(progress.last.completedSteps, 2);
    expect(progress.last.totalSteps, 2);
  });

  test('confirmed primary meaning drift remains unreliable', () async {
    gateway.prototypeAuditReports.add(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _preservedObservation(
            routeId: 'RU_TO_EN',
            role: TranslationRouteRole.primary,
          ),
          const SemanticObservation(
            routeId: 'RU_TO_TH',
            routeRole: TranslationRouteRole.primary,
            relation: SemanticRelation.substitution,
            dimension: SemanticDimension.object,
            preservation: MeaningPreservation.altered,
            verificationStatus: ObservationVerificationStatus.confirmed,
            sourceExcerpt: 'панель',
            targetExcerpt: 'เตา',
          ),
          _preservedObservation(
            routeId: 'EN_TO_RU',
            role: TranslationRouteRole.crossCheck,
          ),
          _preservedObservation(
            routeId: 'EN_TO_TH',
            role: TranslationRouteRole.crossCheck,
          ),
          _preservedObservation(
            routeId: 'TH_TO_RU',
            role: TranslationRouteRole.crossCheck,
          ),
          _preservedObservation(
            routeId: 'TH_TO_EN',
            role: TranslationRouteRole.crossCheck,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    final TranslationMatrixResult result = await useCase(
      sourceText: 'варочная панель',
      sourceLanguageSelection: SourceLanguageSelection.russian,
      cancellationSignal: TranslatorCancellationSignal(),
      onProgress: (_) {},
    );

    expect(result.auditCoverage, TranslationAuditCoverage.prototype);
    expect(result.routes, hasLength(6));
    expect(result.assessment.verdict, MatrixVerdict.unreliable);
    expect(gateway.prototypeTranslationCalls, 1);
    expect(gateway.prototypeAuditCalls, 1);
  });

  test('incomplete provider matrix is rejected before audit', () async {
    gateway.returnIncompletePrototypeMatrix = true;

    await expectLater(
      useCase(
        sourceText: 'Source',
        sourceLanguageSelection: SourceLanguageSelection.english,
        cancellationSignal: TranslatorCancellationSignal(),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TranslatorException>().having(
          (TranslatorException error) => error.kind,
          'kind',
          TranslatorFailureKind.invalidResponse,
        ),
      ),
    );

    expect(gateway.prototypeTranslationCalls, 1);
    expect(gateway.prototypeAuditCalls, 0);
  });

  test('incomplete audit coverage is rejected before assessment', () async {
    gateway.prototypeAuditReports.add(
      const SemanticAuditReport(
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
    );

    await expectLater(
      useCase(
        sourceText: 'Source',
        sourceLanguageSelection: SourceLanguageSelection.english,
        cancellationSignal: TranslatorCancellationSignal(),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TranslatorException>().having(
          (TranslatorException error) => error.kind,
          'kind',
          TranslatorFailureKind.invalidResponse,
        ),
      ),
    );

    expect(gateway.prototypeTranslationCalls, 1);
    expect(gateway.prototypeAuditCalls, 1);
  });

  test('duplicate audit route identifiers are rejected', () async {
    gateway.prototypeAuditReports.add(
      SemanticAuditReport(
        observations: List<SemanticObservation>.generate(
          6,
          (_) => const SemanticObservation(
            routeId: 'EN_TO_RU',
            routeRole: TranslationRouteRole.primary,
            relation: SemanticRelation.wordingVariation,
            dimension: SemanticDimension.proposition,
            preservation: MeaningPreservation.preserved,
            verificationStatus: ObservationVerificationStatus.confirmed,
            sourceExcerpt: 'Source',
            targetExcerpt: 'Перевод',
          ),
          growable: false,
        ),
        limitations: const <String>[],
      ),
    );

    await expectLater(
      useCase(
        sourceText: 'Source',
        sourceLanguageSelection: SourceLanguageSelection.english,
        cancellationSignal: TranslatorCancellationSignal(),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TranslatorException>().having(
          (TranslatorException error) => error.kind,
          'kind',
          TranslatorFailureKind.invalidResponse,
        ),
      ),
    );

    expect(gateway.prototypeTranslationCalls, 1);
    expect(gateway.prototypeAuditCalls, 1);
  });

  test('automatic mixed-language input fails without provider calls', () async {
    await expectLater(
      useCase(
        sourceText: 'Hello, отправь это завтра',
        sourceLanguageSelection: SourceLanguageSelection.automatic,
        cancellationSignal: TranslatorCancellationSignal(),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TranslatorException>().having(
          (TranslatorException error) => error.kind,
          'kind',
          TranslatorFailureKind.unsupportedLanguage,
        ),
      ),
    );

    expect(gateway.prototypeTranslationCalls, 0);
    expect(gateway.prototypeAuditCalls, 0);
  });

  test('missing key fails before provider calls', () async {
    apiKeyStore.value = '   ';

    await expectLater(
      useCase(
        sourceText: 'ข้อความต้นฉบับ',
        sourceLanguageSelection: SourceLanguageSelection.thai,
        cancellationSignal: TranslatorCancellationSignal(),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TranslatorException>().having(
          (TranslatorException error) => error.kind,
          'kind',
          TranslatorFailureKind.missingApiKey,
        ),
      ),
    );

    expect(gateway.prototypeTranslationCalls, 0);
    expect(gateway.prototypeAuditCalls, 0);
  });

  test('secure-storage failure is reported before provider calls', () async {
    useCase = RunTranslationMatrix(
      apiKeyStore: const _ThrowingApiKeyStore(),
      gateway: gateway,
      languageDetector: const ScriptSourceLanguageDetector(),
      routePlanner: const CompleteThreeLanguageRoutePlanner(),
      assessmentPolicy: const ConservativeHonestyAssessmentPolicy(),
      clock: () => DateTime.utc(2026, 8, 5),
    );

    await expectLater(
      useCase(
        sourceText: 'Source text',
        sourceLanguageSelection: SourceLanguageSelection.english,
        cancellationSignal: TranslatorCancellationSignal(),
        onProgress: (_) {},
      ),
      throwsA(
        isA<TranslatorException>().having(
          (TranslatorException error) => error.kind,
          'kind',
          TranslatorFailureKind.persistence,
        ),
      ),
    );

    expect(gateway.prototypeTranslationCalls, 0);
    expect(gateway.prototypeAuditCalls, 0);
  });
}

SemanticObservation _preservedObservation({
  required String routeId,
  required TranslationRouteRole role,
}) {
  return SemanticObservation(
    routeId: routeId,
    routeRole: role,
    relation: SemanticRelation.wordingVariation,
    dimension: SemanticDimension.proposition,
    preservation: MeaningPreservation.preserved,
    verificationStatus: ObservationVerificationStatus.confirmed,
    sourceExcerpt: '$routeId-source',
    targetExcerpt: '$routeId-target',
  );
}

final class _ThrowingApiKeyStore implements TranslatorApiKeyStore {
  const _ThrowingApiKeyStore();

  @override
  Future<String?> read() {
    throw StateError('secure storage unavailable');
  }

  @override
  Future<void> write(String apiKey) async {}

  @override
  Future<void> delete() async {}
}

final class _MemoryApiKeyStore implements TranslatorApiKeyStore {
  _MemoryApiKeyStore(this.value);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String apiKey) async {
    value = apiKey;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}

final class _RecordingGateway implements TranslatorGateway {
  int prototypeTranslationCalls = 0;
  int prototypeAuditCalls = 0;
  int batchCalls = 0;
  int regularAuditCalls = 0;
  bool returnIncompletePrototypeMatrix = false;

  final List<SemanticAuditReport> prototypeAuditReports =
      <SemanticAuditReport>[];

  @override
  Future<String> translate({
    required String apiKey,
    required TranslationLanguage sourceLanguage,
    required TranslationLanguage targetLanguage,
    required String sourceText,
  }) async {
    return '${sourceLanguage.code}_TO_${targetLanguage.code}::$sourceText';
  }

  @override
  Future<List<TranslationRouteResult>> translateBatch({
    required String apiKey,
    required List<TranslationBatchRequest> requests,
  }) async {
    batchCalls += 1;
    return <TranslationRouteResult>[
      for (final TranslationBatchRequest request in requests)
        TranslationRouteResult(
          route: request.route,
          sourceText: request.sourceText,
          translatedText: '${request.route.id}::${request.sourceText}',
        ),
    ];
  }

  @override
  Future<List<TranslationRouteResult>> translatePrototypeMatrix({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRoute> routes,
  }) async {
    prototypeTranslationCalls += 1;

    final Map<TranslationLanguage, String> sourceTexts =
        <TranslationLanguage, String>{
          originalSourceLanguage: originalSourceText,
        };
    final Map<String, String> translatedByRoute = <String, String>{};

    for (final TranslationRoute route in routes) {
      if (route.role != TranslationRouteRole.primary) {
        continue;
      }

      final String translatedText = '${route.id}::$originalSourceText';
      translatedByRoute[route.id] = translatedText;
      sourceTexts[route.target] = translatedText;
    }

    final List<TranslationRouteResult> results = <TranslationRouteResult>[];

    for (final TranslationRoute route in routes) {
      final String routeSourceText = sourceTexts[route.source]!;
      final String translatedText =
          translatedByRoute[route.id] ?? '${route.id}::$routeSourceText';

      results.add(
        TranslationRouteResult(
          route: route,
          sourceText: routeSourceText,
          translatedText: translatedText,
        ),
      );
    }

    if (returnIncompletePrototypeMatrix) {
      return results.take(results.length - 1).toList(growable: false);
    }

    return List<TranslationRouteResult>.unmodifiable(results);
  }

  @override
  Future<SemanticAuditReport> auditMatrix({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRouteResult> routes,
  }) async {
    regularAuditCalls += 1;
    return const SemanticAuditReport(
      observations: <SemanticObservation>[],
      limitations: <String>[],
    );
  }

  @override
  Future<SemanticAuditReport> auditPrototypeMatrix({
    required String apiKey,
    required String originalSourceText,
    required TranslationLanguage originalSourceLanguage,
    required List<TranslationRouteResult> routes,
  }) async {
    prototypeAuditCalls += 1;

    if (prototypeAuditReports.isEmpty) {
      return SemanticAuditReport(
        observations: <SemanticObservation>[
          for (final TranslationRouteResult route in routes)
            SemanticObservation(
              routeId: route.route.id,
              routeRole: route.route.role,
              relation: SemanticRelation.wordingVariation,
              dimension: SemanticDimension.proposition,
              preservation: MeaningPreservation.preserved,
              verificationStatus: ObservationVerificationStatus.confirmed,
              sourceExcerpt: route.sourceText,
              targetExcerpt: route.translatedText,
            ),
        ],
        limitations: const <String>[],
      );
    }

    return prototypeAuditReports.removeAt(0);
  }

  @override
  void close() {}
}
