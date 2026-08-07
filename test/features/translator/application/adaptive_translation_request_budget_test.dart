import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helpy_translator/features/translator/application/run_translation_matrix.dart';
import 'package:helpy_translator/features/translator/application/translator_cancellation_signal.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_chat_client.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_config.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_gateway.dart';
import 'package:helpy_translator/features/translator/domain/entities/matrix_assessment.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_matrix_result.dart';
import 'package:helpy_translator/features/translator/domain/repositories/translator_api_key_store.dart';
import 'package:helpy_translator/features/translator/domain/services/honesty_assessment_policy.dart';
import 'package:helpy_translator/features/translator/domain/services/source_language_detector.dart';
import 'package:helpy_translator/features/translator/domain/services/translation_route_planner.dart';

typedef _SourceCase = ({String text, SourceLanguageSelection selection});

typedef _Scenario = ({
  TranslationMatrixResult result,
  int requestCount,
  int auditAttemptCount,
  List<String> requestModels,
});

void main() {
  test('current workflow uses only the API-verified model', () {
    const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();

    expect(config.model, 'typhoon-v2.5-30b-a3b-instruct');
    expect(config.model, isNot(contains('v2.1')));
  });

  test('normal RU EN and TH runs use exactly eight provider calls', () async {
    for (final _SourceCase sourceCase in _normalCases) {
      final _Scenario scenario = await _runScenario(sourceCase: sourceCase);

      expect(scenario.requestCount, 8, reason: sourceCase.selection.name);
      expect(scenario.auditAttemptCount, 2);
      expect(
        scenario.requestModels,
        everyElement('typhoon-v2.5-30b-a3b-instruct'),
      );
      expect(scenario.result.auditCoverage, TranslationAuditCoverage.expanded);
      expect(scenario.result.routes, hasLength(6));
      expect(
        scenario.result.assessment.verdict,
        MatrixVerdict.acceptableVariation,
      );
    }
  });

  test('specificity loss is non-green for RU EN and TH source', () async {
    for (final _SourceCase sourceCase in _specificityCases) {
      final _Scenario scenario = await _runScenario(
        sourceCase: sourceCase,
        terminologyIssue: true,
      );

      expect(scenario.requestCount, 8, reason: sourceCase.selection.name);
      expect(scenario.auditAttemptCount, 2);
      expect(
        scenario.result.assessment.verdict,
        MatrixVerdict.unreliable,
        reason: sourceCase.selection.name,
      );
    }
  });

  test('one shared transient audit retry raises total to nine', () async {
    final _Scenario scenario = await _runScenario(
      sourceCase: _normalCases[1],
      transientAuditFailures: 1,
    );

    expect(scenario.requestCount, 9);
    expect(scenario.auditAttemptCount, 3);
    expect(
      scenario.result.assessment.verdict,
      MatrixVerdict.acceptableVariation,
    );
  });

  test('malformed audit JSON is not retried', () async {
    final _Scenario scenario = await _runScenario(
      sourceCase: _normalCases[1],
      malformedFirstAudit: true,
    );

    expect(scenario.requestCount, 8);
    expect(scenario.auditAttemptCount, 2);
    expect(scenario.result.assessment.verdict, MatrixVerdict.indeterminate);
    expect(
      scenario.result.assessment.limitations,
      contains('AUDIT_PASS_A_RESPONSE_INVALID'),
    );
    expect(
      scenario.result.assessment.limitations,
      contains('AUDIT_PASSES_DISAGREE'),
    );
  });

  test('HTTP 400 audit failure is not retried', () async {
    final _Scenario scenario = await _runScenario(
      sourceCase: _normalCases[1],
      firstAuditHttp400: true,
    );

    expect(scenario.requestCount, 8);
    expect(scenario.auditAttemptCount, 2);
    expect(scenario.result.assessment.verdict, MatrixVerdict.indeterminate);
    expect(
      scenario.result.assessment.limitations,
      anyElement(startsWith('AUDIT_PASS_A_')),
    );
  });

  test('repeated transient failure consumes only one shared retry', () async {
    final _Scenario scenario = await _runScenario(
      sourceCase: _normalCases[1],
      transientAuditFailures: 2,
    );

    expect(scenario.requestCount, 9);
    expect(scenario.auditAttemptCount, 3);
    expect(scenario.result.assessment.verdict, MatrixVerdict.indeterminate);
    expect(
      scenario.result.assessment.limitations,
      anyElement(startsWith('AUDIT_PASS_A_')),
    );
    expect(
      scenario.result.assessment.limitations,
      contains('AUDIT_PASSES_DISAGREE'),
    );
  });
}

const List<_SourceCase> _normalCases = <_SourceCase>[
  (text: 'варочная панель', selection: SourceLanguageSelection.russian),
  (text: 'cooktop', selection: SourceLanguageSelection.english),
  (text: 'เตาปรุงอาหารแบบฝัง', selection: SourceLanguageSelection.thai),
];

const List<_SourceCase> _specificityCases = <_SourceCase>[
  (text: 'варочная панель', selection: SourceLanguageSelection.russian),
  (text: 'cooktop', selection: SourceLanguageSelection.english),
  (text: 'เตาไฟ', selection: SourceLanguageSelection.thai),
];

Future<_Scenario> _runScenario({
  required _SourceCase sourceCase,
  bool terminologyIssue = false,
  int transientAuditFailures = 0,
  bool malformedFirstAudit = false,
  bool firstAuditHttp400 = false,
}) async {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig(
    auditRetryDelay: Duration.zero,
  );

  int requestCount = 0;
  int auditAttemptCount = 0;

  final List<String> requestModels = <String>[];

  final MockClient httpClient = MockClient((http.Request request) async {
    requestCount += 1;

    final Map<String, dynamic> body =
        jsonDecode(request.body) as Map<String, dynamic>;

    final Object? rawModel = body['model'];

    if (rawModel is! String || rawModel.isEmpty) {
      throw StateError('Provider request model is missing.');
    }

    requestModels.add(rawModel);

    final Map<String, dynamic> payload = _userPayload(body);

    if (payload.containsKey('source_language') &&
        payload.containsKey('target_language')) {
      final String routeId =
          '${payload['source_language']}_TO_'
          '${payload['target_language']}';

      return _chatResponse(
        jsonEncode(<String, Object>{
          'translation': _translationForRoute(
            routeId,
            terminologyIssue: terminologyIssue,
          ),
        }),
      );
    }

    auditAttemptCount += 1;

    if (auditAttemptCount <= transientAuditFailures) {
      return http.Response(
        'temporary provider failure',
        503,
        headers: const <String, String>{
          'content-type': 'text/plain; charset=utf-8',
        },
      );
    }

    if (malformedFirstAudit && auditAttemptCount == 1) {
      return _chatResponse('{"unexpected":[]}');
    }

    if (firstAuditHttp400 && auditAttemptCount == 1) {
      return http.Response(
        'bad request',
        400,
        headers: const <String, String>{
          'content-type': 'text/plain; charset=utf-8',
        },
      );
    }

    return _chatResponse(
      _auditResponse(payload, terminologyIssue: terminologyIssue),
    );
  });

  final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
    chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
    config: config,
  );

  try {
    final RunTranslationMatrix useCase = RunTranslationMatrix(
      apiKeyStore: const _StaticApiKeyStore(),
      gateway: gateway,
      languageDetector: const ScriptSourceLanguageDetector(),
      routePlanner: const CompleteThreeLanguageRoutePlanner(),
      assessmentPolicy: const ConservativeHonestyAssessmentPolicy(),
      clock: () => DateTime.utc(2026, 8, 7),
    );

    final TranslationMatrixResult result = await useCase(
      sourceText: sourceCase.text,
      sourceLanguageSelection: sourceCase.selection,
      cancellationSignal: TranslatorCancellationSignal(),
      onProgress: (_) {},
    );

    return (
      result: result,
      requestCount: requestCount,
      auditAttemptCount: auditAttemptCount,
      requestModels: List<String>.unmodifiable(requestModels),
    );
  } finally {
    gateway.close();
  }
}

String _translationForRoute(String routeId, {required bool terminologyIssue}) {
  final String thaiTerm = terminologyIssue ? 'เตาไฟ' : 'เตาปรุงอาหารแบบฝัง';

  return <String, String>{
    'RU_TO_EN': 'cooktop',
    'RU_TO_TH': thaiTerm,
    'EN_TO_RU': 'варочная панель',
    'EN_TO_TH': thaiTerm,
    'TH_TO_RU': 'варочная панель',
    'TH_TO_EN': 'cooktop',
  }[routeId]!;
}

String _auditResponse(
  Map<String, dynamic> payload, {
  required bool terminologyIssue,
}) {
  final List<dynamic> routes = payload['routes'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'route_audits': <Object>[
      for (final dynamic rawRoute in routes)
        _routeAudit(
          rawRoute as Map<String, dynamic>,
          terminologyIssue: terminologyIssue,
        ),
    ],
  });
}

Map<String, Object?> _routeAudit(
  Map<String, dynamic> route, {
  required bool terminologyIssue,
}) {
  final String sourceText = route['source_text'] as String;

  final String translatedText = route['translated_text'] as String;

  final bool sourceIsGeneric = sourceText == 'เตาไฟ';

  final bool targetIsGeneric = translatedText == 'เตาไฟ';

  final bool mismatch = terminologyIssue && sourceIsGeneric != targetIsGeneric;

  if (!mismatch) {
    return <String, Object?>{
      'judgment': 'SAME_MEANING',
      'difference': null,
      'limitations': <Object>[],
    };
  }

  return <String, Object?>{
    'judgment': 'DIFFERENT_MEANING',
    'difference': <String, Object?>{
      'difference_type': 'SPECIFICITY_CHANGE',
      'source_excerpt': sourceText,
      'target_excerpt': translatedText,
      'source_fact': sourceIsGeneric
          ? 'The source denotes a broader class '
                'of cooking appliance.'
          : 'The source denotes a specific '
                'built-in cooking surface.',
      'target_fact': targetIsGeneric
          ? 'The target denotes a broader class '
                'of cooking appliance.'
          : 'The target denotes a specific '
                'built-in cooking surface.',
    },
    'limitations': <Object>[],
  };
}

Map<String, dynamic> _userPayload(Map<String, dynamic> body) {
  final List<dynamic> messages = body['messages'] as List<dynamic>;

  final Map<String, dynamic> userMessage = messages[1] as Map<String, dynamic>;

  return jsonDecode(userMessage['content'] as String) as Map<String, dynamic>;
}

http.Response _chatResponse(String content) {
  return http.Response(
    jsonEncode(<String, Object>{
      'choices': <Object>[
        <String, Object>{
          'message': <String, Object>{'content': content},
          'finish_reason': 'stop',
        },
      ],
      'model': 'typhoon-v2.5-30b-a3b-instruct',
    }),
    200,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

final class _StaticApiKeyStore implements TranslatorApiKeyStore {
  const _StaticApiKeyStore();

  @override
  Future<String?> read() async => 'secret';

  @override
  Future<void> write(String apiKey) async {}

  @override
  Future<void> delete() async {}
}
