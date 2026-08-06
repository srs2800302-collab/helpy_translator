import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_chat_client.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_config.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_gateway.dart';
import 'package:helpy_translator/features/translator/domain/entities/matrix_assessment.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_audit_report.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_observation.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route_result.dart';
import 'package:helpy_translator/features/translator/domain/services/honesty_assessment_policy.dart';
import 'package:helpy_translator/features/translator/domain/services/translation_route_planner.dart';

void main() {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig(
    auditRetryDelay: Duration.zero,
  );
  const CompleteThreeLanguageRoutePlanner planner =
      CompleteThreeLanguageRoutePlanner();

  test(
    'prototype matrix returns six named routes in one provider call',
    () async {
      final List<TranslationRoute> routes = planner.build(
        TranslationLanguage.russian,
      );
      int requestCount = 0;

      final MockClient httpClient = MockClient((http.Request request) async {
        requestCount += 1;
        final Map<String, dynamic> payload = _userData(request);
        final List<dynamic> requiredRoutes =
            payload['required_routes'] as List<dynamic>;

        return _chatResponse(
          jsonEncode(<String, Object>{
            'translations': <String, String>{
              for (final dynamic rawRoute in requiredRoutes)
                ((rawRoute as Map<String, dynamic>)['route'] as String):
                    '${rawRoute['route']}-translation',
            },
          }),
        );
      });
      final TyphoonTranslatorGateway gateway = _gateway(
        config: config,
        httpClient: httpClient,
      );
      addTearDown(gateway.close);

      final List<TranslationRouteResult> results = await gateway
          .translatePrototypeMatrix(
            apiKey: 'secret',
            originalSourceText: 'варочная панель',
            originalSourceLanguage: TranslationLanguage.russian,
            routes: routes,
          );

      expect(requestCount, 1);
      expect(results, hasLength(6));
      expect(
        results.map((TranslationRouteResult result) => result.route.id),
        routes.map((TranslationRoute route) => route.id),
      );
    },
  );

  test('clean evidence pipeline uses exactly five audit calls', () async {
    final List<TranslationRouteResult> routes = _cleanMatrix();
    final List<Map<String, dynamic>> requestBodies = <Map<String, dynamic>>[];

    final MockClient httpClient = MockClient((http.Request request) async {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      requestBodies.add(body);
      return _evidenceResponse(body);
    });
    final TyphoonTranslatorGateway gateway = _gateway(
      config: config,
      httpClient: httpClient,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: routes.first.sourceText,
      originalSourceLanguage: TranslationLanguage.english,
      routes: routes,
    );

    expect(requestBodies, hasLength(5));
    expect(
      requestBodies.map((Map<String, dynamic> body) => body['model']),
      everyElement('typhoon-v2.5-30b-a3b-instruct'),
    );
    expect(report.observations, hasLength(6));
    expect(
      report.observations.every(
        (SemanticObservation observation) =>
            observation.preservation == MeaningPreservation.preserved &&
            observation.verificationStatus ==
                ObservationVerificationStatus.confirmed,
      ),
      isTrue,
    );
    expect(report.limitations, isEmpty);
  });

  test('specificity evidence produces a confirmed non-green route', () async {
    final List<TranslationRouteResult> routes = _russianCooktopMatrix();
    int requestCount = 0;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      return _evidenceResponse(body, terminologyIssue: true);
    });
    final TyphoonTranslatorGateway gateway = _gateway(
      config: config,
      httpClient: httpClient,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: 'варочная панель',
      originalSourceLanguage: TranslationLanguage.russian,
      routes: routes,
    );
    final MatrixAssessment assessment =
        const ConservativeHonestyAssessmentPolicy().assess(report);

    expect(requestCount, 5);
    expect(
      report.observations.any(
        (SemanticObservation observation) =>
            observation.routeId == 'RU_TO_TH' &&
            observation.preservation == MeaningPreservation.altered &&
            observation.dimension == SemanticDimension.specificity &&
            observation.verificationStatus ==
                ObservationVerificationStatus.confirmed,
      ),
      isTrue,
    );
    expect(report.limitations, isEmpty);
    expect(assessment.verdict, MatrixVerdict.unreliable);
  });

  test('conflicting evidence is indeterminate rather than selected', () async {
    final List<TranslationRouteResult> routes = _russianCooktopMatrix();

    final MockClient httpClient = MockClient((http.Request request) async {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      return _evidenceResponse(
        body,
        terminologyIssue: true,
        forceVerifierConflict: true,
      );
    });
    final TyphoonTranslatorGateway gateway = _gateway(
      config: config,
      httpClient: httpClient,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: 'варочная панель',
      originalSourceLanguage: TranslationLanguage.russian,
      routes: routes,
    );
    final MatrixAssessment assessment =
        const ConservativeHonestyAssessmentPolicy().assess(report);

    expect(
      report.observations.any(
        (SemanticObservation observation) =>
            observation.verificationStatus ==
            ObservationVerificationStatus.conflict,
      ),
      isTrue,
    );
    expect(report.limitations, contains('AUDIT_EVIDENCE_CONFLICT'));
    expect(assessment.verdict, MatrixVerdict.indeterminate);
  });

  test('malformed JSON is not retried', () async {
    final List<TranslationRouteResult> routes = _cleanMatrix();
    int requestCount = 0;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;
      return _chatResponse('{"analyses":[]}');
    });
    final TyphoonTranslatorGateway gateway = _gateway(
      config: config,
      httpClient: httpClient,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: routes.first.sourceText,
      originalSourceLanguage: TranslationLanguage.english,
      routes: routes,
    );

    expect(requestCount, 1);
    expect(report.limitations, contains('AUDIT_RESPONSE_INVALID'));
    expect(
      report.observations.every(
        (SemanticObservation observation) =>
            observation.verificationStatus ==
            ObservationVerificationStatus.unverifiable,
      ),
      isTrue,
    );
  });

  test('one transient failure consumes the single shared retry', () async {
    final List<TranslationRouteResult> routes = _cleanMatrix();
    int requestCount = 0;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;

      if (requestCount == 1) {
        return http.Response('temporary', 503);
      }

      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      return _evidenceResponse(body);
    });
    final TyphoonTranslatorGateway gateway = _gateway(
      config: config,
      httpClient: httpClient,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: routes.first.sourceText,
      originalSourceLanguage: TranslationLanguage.english,
      routes: routes,
    );

    expect(requestCount, 6);
    expect(report.limitations, isEmpty);
    expect(
      report.observations.every(
        (SemanticObservation observation) =>
            observation.preservation == MeaningPreservation.preserved,
      ),
      isTrue,
    );
  });

  test('non-transient provider failure is not retried', () async {
    final List<TranslationRouteResult> routes = _cleanMatrix();
    int requestCount = 0;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;
      return http.Response('bad request', 400);
    });
    final TyphoonTranslatorGateway gateway = _gateway(
      config: config,
      httpClient: httpClient,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: routes.first.sourceText,
      originalSourceLanguage: TranslationLanguage.english,
      routes: routes,
    );

    expect(requestCount, 1);
    expect(report.limitations, contains('AUDIT_PROVIDER_HTTP_400'));
  });

  test('a repeated transient failure cannot consume a second retry', () async {
    final List<TranslationRouteResult> routes = _cleanMatrix();
    int requestCount = 0;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;
      return http.Response('temporary', 503);
    });
    final TyphoonTranslatorGateway gateway = _gateway(
      config: config,
      httpClient: httpClient,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: routes.first.sourceText,
      originalSourceLanguage: TranslationLanguage.english,
      routes: routes,
    );

    expect(requestCount, 2);
    expect(report.limitations, contains('AUDIT_PROVIDER_HTTP_503'));
    expect(
      report.observations.every(
        (SemanticObservation observation) =>
            observation.verificationStatus ==
            ObservationVerificationStatus.unverifiable,
      ),
      isTrue,
    );
  });
}

TyphoonTranslatorGateway _gateway({
  required TyphoonTranslatorConfig config,
  required http.Client httpClient,
}) {
  return TyphoonTranslatorGateway(
    chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
    config: config,
  );
}

http.Response _evidenceResponse(
  Map<String, dynamic> body, {
  bool terminologyIssue = false,
  bool forceVerifierConflict = false,
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
      _defenseResponse(
        payload,
        terminologyIssue: terminologyIssue,
        forceExact: forceVerifierConflict,
      ),
    );
  }

  if (prompt.contains('neutral evidence verifier E')) {
    return _chatResponse(
      _verificationResponse(payload, forceConflict: forceVerifierConflict),
    );
  }

  throw StateError('Unexpected prompt: $prompt');
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
  required bool forceExact,
}) {
  final List<dynamic> routes = payload['routes'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'route_defenses': <Object>[
      for (final dynamic rawRoute in routes)
        _defenseForRoute(
          rawRoute as Map<String, dynamic>,
          terminologyIssue: terminologyIssue,
          forceExact: forceExact,
        ),
    ],
  });
}

Map<String, Object> _defenseForRoute(
  Map<String, dynamic> route, {
  required bool terminologyIssue,
  required bool forceExact,
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
  final String relation = forceExact
      ? 'EXACT'
      : terminologyIssue
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
            : 'The target extension differs in specificity.',
      },
    ],
    'limitations': <Object>[],
  };
}

String _verificationResponse(
  Map<String, dynamic> payload, {
  required bool forceConflict,
}) {
  final List<dynamic> routes = payload['routes'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'route_checks': <Object>[
      for (final dynamic rawRoute in routes)
        _verificationForRoute(
          rawRoute as Map<String, dynamic>,
          forceConflict: forceConflict,
        ),
    ],
  });
}

Map<String, Object?> _verificationForRoute(
  Map<String, dynamic> route, {
  required bool forceConflict,
}) {
  final Map<String, dynamic> reportA =
      route['report_a'] as Map<String, dynamic>;
  final Map<String, dynamic> reportB =
      route['report_b'] as Map<String, dynamic>;
  final String challengeRelation = reportA['relation'] as String;
  final List<dynamic> mappings = reportB['mappings'] as List<dynamic>;
  final String defenseRelation =
      (mappings.single as Map<String, dynamic>)['relation'] as String;
  final bool hasChallenge =
      challengeRelation != 'NO_PROVEN_DIFFERENCE' &&
      challengeRelation != 'UNRESOLVED';
  final String acceptedRelation = forceConflict && hasChallenge
      ? 'EXACT'
      : hasChallenge
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
    'reason_code': forceConflict && hasChallenge
        ? 'REPORTS_CONFLICT'
        : 'EVIDENCE_SUPPORTED',
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

List<TranslationRouteResult> _cleanMatrix() {
  const CompleteThreeLanguageRoutePlanner planner =
      CompleteThreeLanguageRoutePlanner();
  final List<TranslationRoute> routes = planner.build(
    TranslationLanguage.english,
  );
  const Map<String, String> translatedByRoute = <String, String>{
    'EN_TO_RU': 'Сообщение',
    'EN_TO_TH': 'ข้อความ',
    'RU_TO_EN': 'Message',
    'RU_TO_TH': 'ข้อความ',
    'TH_TO_RU': 'Сообщение',
    'TH_TO_EN': 'Message',
  };
  const Map<TranslationLanguage, String> sources =
      <TranslationLanguage, String>{
        TranslationLanguage.english: 'Message',
        TranslationLanguage.russian: 'Сообщение',
        TranslationLanguage.thai: 'ข้อความ',
      };

  return <TranslationRouteResult>[
    for (final TranslationRoute route in routes)
      TranslationRouteResult(
        route: route,
        sourceText: sources[route.source]!,
        translatedText: translatedByRoute[route.id]!,
      ),
  ];
}

List<TranslationRouteResult> _russianCooktopMatrix() {
  const CompleteThreeLanguageRoutePlanner planner =
      CompleteThreeLanguageRoutePlanner();
  final List<TranslationRoute> routes = planner.build(
    TranslationLanguage.russian,
  );
  const Map<String, String> translatedByRoute = <String, String>{
    'RU_TO_EN': 'cooktop',
    'RU_TO_TH': 'เตาไฟ',
    'EN_TO_RU': 'варочная панель',
    'EN_TO_TH': 'เตาไฟ',
    'TH_TO_RU': 'варочная панель',
    'TH_TO_EN': 'cooktop',
  };
  const Map<TranslationLanguage, String> sources =
      <TranslationLanguage, String>{
        TranslationLanguage.russian: 'варочная панель',
        TranslationLanguage.english: 'cooktop',
        TranslationLanguage.thai: 'เตาไฟ',
      };

  return <TranslationRouteResult>[
    for (final TranslationRoute route in routes)
      TranslationRouteResult(
        route: route,
        sourceText: sources[route.source]!,
        translatedText: translatedByRoute[route.id]!,
      ),
  ];
}

Map<String, dynamic> _userData(http.Request request) {
  final Map<String, dynamic> body =
      jsonDecode(request.body) as Map<String, dynamic>;
  return _userDataFromBody(body);
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
