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

void main() {
  test('the evidence workflow uses only the API-verified model', () {
    const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();

    expect(config.model, 'typhoon-v2.5-30b-a3b-instruct');
    expect(config.model, isNot(contains('v2.1')));
  });

  test('normal RU EN and TH runs use exactly six provider calls', () async {
    const List<_SourceCase> cases = <_SourceCase>[
      _SourceCase(
        text: 'Исходный текст',
        selection: SourceLanguageSelection.russian,
      ),
      _SourceCase(
        text: 'Source text',
        selection: SourceLanguageSelection.english,
      ),
      _SourceCase(
        text: 'ข้อความต้นฉบับ',
        selection: SourceLanguageSelection.thai,
      ),
    ];

    for (final _SourceCase sourceCase in cases) {
      final _BudgetScenario scenario = await _runScenario(
        sourceText: sourceCase.text,
        sourceLanguageSelection: sourceCase.selection,
        terminologyIssue: false,
      );

      expect(scenario.requestCount, 6);
      expect(
        scenario.requestModels,
        everyElement('typhoon-v2.5-30b-a3b-instruct'),
      );
      expect(
        scenario.result.auditCoverage,
        TranslationAuditCoverage.blindConsensus,
      );
      expect(scenario.result.routes, hasLength(6));
      expect(
        scenario.result.assessment.verdict,
        MatrixVerdict.acceptableVariation,
      );
    }
  });

  test('specificity loss is non-green for RU EN and TH source', () async {
    const List<_SourceCase> cases = <_SourceCase>[
      _SourceCase(
        text: 'варочная панель',
        selection: SourceLanguageSelection.russian,
      ),
      _SourceCase(text: 'cooktop', selection: SourceLanguageSelection.english),
      _SourceCase(text: 'เตาไฟ', selection: SourceLanguageSelection.thai),
    ];

    for (final _SourceCase sourceCase in cases) {
      final _BudgetScenario scenario = await _runScenario(
        sourceText: sourceCase.text,
        sourceLanguageSelection: sourceCase.selection,
        terminologyIssue: true,
      );

      expect(scenario.requestCount, 6);
      expect(
        scenario.requestModels,
        everyElement('typhoon-v2.5-30b-a3b-instruct'),
      );
      expect(scenario.result.routes, hasLength(6));
      expect(
        scenario.result.assessment.verdict,
        MatrixVerdict.unreliable,
        reason: sourceCase.selection.name,
      );
    }
  });

  test(
    'one transient retry raises the total to seven and no further',
    () async {
      final _BudgetScenario scenario = await _runScenario(
        sourceText: 'Source text',
        sourceLanguageSelection: SourceLanguageSelection.english,
        terminologyIssue: false,
        failFirstAuditWith503: true,
      );

      expect(scenario.requestCount, 7);
      expect(
        scenario.requestModels,
        everyElement('typhoon-v2.5-30b-a3b-instruct'),
      );
      expect(
        scenario.result.assessment.verdict,
        MatrixVerdict.acceptableVariation,
      );
    },
  );

  test('invalid audit JSON is not retried', () async {
    final _BudgetScenario scenario = await _runScenario(
      sourceText: 'Source text',
      sourceLanguageSelection: SourceLanguageSelection.english,
      terminologyIssue: false,
      malformedFirstAudit: true,
    );

    expect(scenario.requestCount, 2);
    expect(scenario.result.assessment.verdict, MatrixVerdict.indeterminate);
    expect(
      scenario.result.assessment.limitations,
      contains('AUDIT_RESPONSE_INVALID'),
    );
  });
}

Future<_BudgetScenario> _runScenario({
  required String sourceText,
  required SourceLanguageSelection sourceLanguageSelection,
  required bool terminologyIssue,
  bool failFirstAuditWith503 = false,
  bool malformedFirstAudit = false,
}) async {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig(
    auditRetryDelay: Duration.zero,
  );
  int requestCount = 0;
  int auditRequestCount = 0;
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

    final Map<String, dynamic> payload = _userDataFromBody(body);

    if (payload.containsKey('required_routes')) {
      final List<dynamic> requiredRoutes =
          payload['required_routes'] as List<dynamic>;

      return _chatResponse(
        jsonEncode(<String, Object>{
          'translations': terminologyIssue
              ? _cooktopTranslations(requiredRoutes)
              : <String, String>{
                  for (final dynamic rawRoute in requiredRoutes)
                    ((rawRoute as Map<String, dynamic>)['route'] as String):
                        '${rawRoute['route']}-result',
                },
        }),
      );
    }

    auditRequestCount += 1;

    if (failFirstAuditWith503 && auditRequestCount == 1) {
      return http.Response('temporary', 503);
    }

    if (malformedFirstAudit && auditRequestCount == 1) {
      return _chatResponse('{"analyses":[]}');
    }

    return _evidenceResponse(body, terminologyIssue: terminologyIssue);
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
      clock: () => DateTime.utc(2026, 8, 6),
    );

    final TranslationMatrixResult result = await useCase(
      sourceText: sourceText,
      sourceLanguageSelection: sourceLanguageSelection,
      cancellationSignal: TranslatorCancellationSignal(),
      onProgress: (_) {},
    );

    return _BudgetScenario(
      result: result,
      requestCount: requestCount,
      requestModels: List<String>.unmodifiable(requestModels),
    );
  } finally {
    gateway.close();
  }
}

http.Response _evidenceResponse(
  Map<String, dynamic> body, {
  required bool terminologyIssue,
}) {
  final String prompt = _systemPrompt(body);
  final Map<String, dynamic> payload = _userDataFromBody(body);

  if (prompt.contains('source semantic analyst A') ||
      prompt.contains('target semantic analyst B')) {
    return _chatResponse(
      _analysisResponse(payload, terminologyIssue: terminologyIssue),
    );
  }

  if (prompt.contains('adversarial semantic challenger C')) {
    return _chatResponse(
      _challengeResponse(payload, terminologyIssue: terminologyIssue),
    );
  }

  if (prompt.contains('semantic equivalence defender D')) {
    return _chatResponse(
      _defenseResponse(payload, terminologyIssue: terminologyIssue),
    );
  }

  if (prompt.contains('neutral evidence verifier E')) {
    return _chatResponse(_verificationResponse(payload));
  }

  throw StateError('Unexpected provider prompt.');
}

Map<String, String> _cooktopTranslations(List<dynamic> requiredRoutes) {
  const Map<String, String> values = <String, String>{
    'RU_TO_EN': 'cooktop',
    'RU_TO_TH': 'เตาไฟ',
    'EN_TO_RU': 'варочная панель',
    'EN_TO_TH': 'เตาไฟ',
    'TH_TO_RU': 'варочная панель',
    'TH_TO_EN': 'cooktop',
  };

  return <String, String>{
    for (final dynamic rawRoute in requiredRoutes)
      ((rawRoute as Map<String, dynamic>)['route'] as String):
          values[rawRoute['route']]!,
  };
}

String _analysisResponse(
  Map<String, dynamic> payload, {
  required bool terminologyIssue,
}) {
  final List<dynamic> items = payload['items'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'analyses': <Object>[
      for (final dynamic rawItem in items)
        _analysisForItem(
          rawItem as Map<String, dynamic>,
          terminologyIssue: terminologyIssue,
        ),
    ],
  });
}

Map<String, Object> _analysisForItem(
  Map<String, dynamic> item, {
  required bool terminologyIssue,
}) {
  final String itemId = item['item_id'] as String;
  final String text = item['text'] as String;
  final bool generic = terminologyIssue && text == 'เตาไฟ';

  return <String, Object>{
    'item_id': itemId,
    'atoms': <Object>[
      <String, Object>{
        'atom_id': '${itemId}_A1',
        'dimension': 'OBJECT',
        'excerpt': text,
        'claim': generic ? 'generic cooking device' : 'specific named object',
        'specificity': terminologyIssue
            ? (generic ? 'GENERAL' : 'SPECIFIC')
            : 'EXACT_TERM',
        'qualifiers': terminologyIssue
            ? <String>[generic ? 'GENERIC_DEVICE' : 'SURFACE_ONLY']
            : <String>[],
        'polarity': 'AFFIRMATIVE',
        'modality': 'ASSERTED',
      },
    ],
    'limitations': <Object>[],
  };
}

String _challengeResponse(
  Map<String, dynamic> payload, {
  required bool terminologyIssue,
}) {
  final List<dynamic> routes = payload['routes'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'route_challenges': <Object>[
      for (final dynamic rawRoute in routes)
        _challengeForRoute(
          rawRoute as Map<String, dynamic>,
          terminologyIssue: terminologyIssue,
        ),
    ],
  });
}

Map<String, Object?> _challengeForRoute(
  Map<String, dynamic> route, {
  required bool terminologyIssue,
}) {
  final String source = route['source_text'] as String;
  final String target = route['translated_text'] as String;
  final String? relation = terminologyIssue
      ? _relationForTexts(source: source, target: target)
      : null;

  if (relation == null) {
    return <String, Object?>{
      'route': route['route'],
      'relation': 'NO_PROVEN_DIFFERENCE',
      'dimension': null,
      'source_excerpt': null,
      'target_excerpt': null,
      'source_fact': null,
      'target_fact': null,
      'counterexample': null,
      'limitation': null,
    };
  }

  return <String, Object?>{
    'route': route['route'],
    'relation': relation,
    'dimension': 'SPECIFICITY',
    'source_excerpt': source,
    'target_excerpt': target,
    'source_fact': 'The source has one extension.',
    'target_fact': 'The target has a different extension.',
    'counterexample': 'One expression can be true where the other is false.',
    'limitation': null,
  };
}

String _defenseResponse(
  Map<String, dynamic> payload, {
  required bool terminologyIssue,
}) {
  final List<dynamic> routes = payload['routes'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'route_defenses': <Object>[
      for (final dynamic rawRoute in routes)
        _defenseForRoute(
          rawRoute as Map<String, dynamic>,
          terminologyIssue: terminologyIssue,
        ),
    ],
  });
}

Map<String, Object> _defenseForRoute(
  Map<String, dynamic> route, {
  required bool terminologyIssue,
}) {
  final Map<String, dynamic> analysisA =
      route['analysis_a'] as Map<String, dynamic>;
  final Map<String, dynamic> analysisB =
      route['analysis_b'] as Map<String, dynamic>;
  final Map<String, dynamic> atomA =
      (analysisA['atoms'] as List<dynamic>).single as Map<String, dynamic>;
  final Map<String, dynamic> atomB =
      (analysisB['atoms'] as List<dynamic>).single as Map<String, dynamic>;
  final String source = route['source_text'] as String;
  final String target = route['translated_text'] as String;
  final String relation = terminologyIssue
      ? _relationForTexts(source: source, target: target) ?? 'EXACT'
      : 'EXACT';

  return <String, Object>{
    'route': route['route'] as String,
    'mappings': <Object>[
      <String, Object?>{
        'source_atom_id': atomA['atom_id'],
        'target_atom_id': atomB['atom_id'],
        'relation': relation,
        'justification': relation == 'EXACT'
            ? 'The atomic fields correspond.'
            : 'The extensions differ in specificity.',
      },
    ],
    'limitations': <Object>[],
  };
}

String _verificationResponse(Map<String, dynamic> payload) {
  final List<dynamic> routes = payload['routes'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'route_checks': <Object>[
      for (final dynamic rawRoute in routes)
        _verificationForRoute(rawRoute as Map<String, dynamic>),
    ],
  });
}

Map<String, Object?> _verificationForRoute(Map<String, dynamic> route) {
  final Map<String, dynamic> reportA =
      route['report_a'] as Map<String, dynamic>;
  final Map<String, dynamic> reportB =
      route['report_b'] as Map<String, dynamic>;
  final String challengeRelation = reportA['relation'] as String;
  final String defenseRelation =
      ((reportB['mappings'] as List<dynamic>).single
              as Map<String, dynamic>)['relation']
          as String;
  final bool hasChallenge =
      challengeRelation != 'NO_PROVEN_DIFFERENCE' &&
      challengeRelation != 'UNRESOLVED';
  final String acceptedRelation = hasChallenge
      ? challengeRelation
      : defenseRelation;
  final bool exact = acceptedRelation == 'EXACT';

  return <String, Object?>{
    'route': route['route'],
    'analysis_a_status': 'SUPPORTED',
    'analysis_b_status': 'SUPPORTED',
    'report_a_status': hasChallenge ? 'SUPPORTED' : 'NOT_APPLICABLE',
    'report_b_status': 'SUPPORTED',
    'accepted_relation': acceptedRelation,
    'source_excerpt': exact ? null : route['source_text'],
    'target_excerpt': exact ? null : route['translated_text'],
    'reason_code': 'EVIDENCE_SUPPORTED',
  };
}

String? _relationForTexts({required String source, required String target}) {
  final bool sourceGeneric = source == 'เตาไฟ';
  final bool targetGeneric = target == 'เตาไฟ';

  if (sourceGeneric == targetGeneric) {
    return null;
  }

  return targetGeneric ? 'BROADER_TARGET' : 'NARROWER_TARGET';
}

Map<String, dynamic> _userDataFromBody(Map<String, dynamic> body) {
  final List<dynamic> messages = body['messages'] as List<dynamic>;
  final Map<String, dynamic> userMessage = messages[1] as Map<String, dynamic>;
  return jsonDecode(userMessage['content'] as String) as Map<String, dynamic>;
}

String _systemPrompt(Map<String, dynamic> body) {
  final List<dynamic> messages = body['messages'] as List<dynamic>;
  final Map<String, dynamic> systemMessage =
      messages[0] as Map<String, dynamic>;
  return systemMessage['content'] as String;
}

http.Response _chatResponse(String content) {
  return http.Response(
    jsonEncode(<String, Object>{
      'choices': <Object>[
        <String, Object>{
          'message': <String, Object>{'content': content},
        },
      ],
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

final class _SourceCase {
  const _SourceCase({required this.text, required this.selection});

  final String text;
  final SourceLanguageSelection selection;
}

final class _BudgetScenario {
  const _BudgetScenario({
    required this.result,
    required this.requestCount,
    required this.requestModels,
  });

  final TranslationMatrixResult result;
  final int requestCount;
  final List<String> requestModels;
}
