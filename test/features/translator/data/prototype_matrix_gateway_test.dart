import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_chat_client.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_config.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_gateway.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_observation.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route_result.dart';
import 'package:helpy_translator/features/translator/domain/errors/translator_exception.dart';
import 'package:helpy_translator/features/translator/domain/services/translation_route_planner.dart';

void main() {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();
  const CompleteThreeLanguageRoutePlanner planner =
      CompleteThreeLanguageRoutePlanner();

  test('prototype matrix parses all six named routes in one call', () async {
    const String sourceText = 'варочная панель';
    final List<TranslationRoute> routes = planner.build(
      TranslationLanguage.russian,
    );
    late Map<String, dynamic> userData;
    late String systemPrompt;

    final MockClient httpClient = MockClient((http.Request request) async {
      userData = _userData(request);
      systemPrompt = _systemPrompt(request);

      return _chatResponse(
        jsonEncode(<String, Object>{
          'translations': <String, String>{
            'RU_TO_EN': 'cooktop',
            'RU_TO_TH': 'เตาไฟ',
            'EN_TO_RU': 'варочная поверхность',
            'EN_TO_TH': 'เตาปรุงอาหาร',
            'TH_TO_RU': 'плита',
            'TH_TO_EN': 'stove',
          },
        }),
      );
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final List<TranslationRouteResult> results = await gateway
        .translatePrototypeMatrix(
          apiKey: 'secret',
          originalSourceText: sourceText,
          originalSourceLanguage: TranslationLanguage.russian,
          routes: routes,
        );

    expect(userData['source_language'], 'RU');
    expect(userData['source_text'], sourceText);
    expect(userData['required_routes'], hasLength(6));
    expect(systemPrompt, contains('two-call multilingual prototype'));
    expect(systemPrompt, contains('complete six-route matrix'));
    expect(results, hasLength(6));
    expect(
      results.map((TranslationRouteResult result) => result.route.id),
      routes.map((TranslationRoute route) => route.id),
    );
    expect(
      results
          .singleWhere(
            (TranslationRouteResult result) => result.route.id == 'EN_TO_RU',
          )
          .sourceText,
      'cooktop',
    );
    expect(
      results
          .singleWhere(
            (TranslationRouteResult result) => result.route.id == 'TH_TO_EN',
          )
          .sourceText,
      'เตาไฟ',
    );
  });

  test('prototype matrix rejects a missing route field', () async {
    final List<TranslationRoute> routes = planner.build(
      TranslationLanguage.english,
    );

    final MockClient httpClient = MockClient((http.Request request) async {
      return _chatResponse(
        jsonEncode(<String, Object>{
          'translations': <String, String>{
            for (final TranslationRoute route in routes.take(5))
              route.id: '${route.id}-result',
          },
        }),
      );
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    await expectLater(
      gateway.translatePrototypeMatrix(
        apiKey: 'secret',
        originalSourceText: 'Source',
        originalSourceLanguage: TranslationLanguage.english,
        routes: routes,
      ),
      throwsA(
        isA<TranslatorException>().having(
          (TranslatorException error) => error.kind,
          'kind',
          TranslatorFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test(
    'clean route-by-route prototype audit preserves all six results',
    () async {
      final List<TranslationRouteResult> routes = _matrixResults(
        sourceLanguage: TranslationLanguage.english,
        sourceText: 'Source',
      );
      int requestCount = 0;
      late String systemPrompt;

      final MockClient httpClient = MockClient((http.Request request) async {
        requestCount += 1;
        systemPrompt = _systemPrompt(request);

        return _chatResponse(jsonEncode(_auditResponse(routes)));
      });
      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
        config: config,
      );
      addTearDown(gateway.close);

      final report = await gateway.auditPrototypeMatrix(
        apiKey: 'secret',
        originalSourceText: 'Source',
        originalSourceLanguage: TranslationLanguage.english,
        routes: routes,
      );

      expect(requestCount, 1);
      expect(systemPrompt, contains('compare only that route'));
      expect(systemPrompt, contains('exactly six entries'));
      expect(systemPrompt, contains('"route": "<copy the exact route id>"'));
      expect(systemPrompt, isNot(contains('"judgment": "SAME_MEANING"')));
      expect(report.observations, hasLength(6));
      expect(
        report.observations.map(
          (SemanticObservation observation) => observation.routeId,
        ),
        routes.map((TranslationRouteResult route) => route.route.id),
      );
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
    },
  );

  test('prototype terminology loss becomes a review observation', () async {
    const String sourceText = 'варочная панель';
    final List<TranslationRouteResult> routes = _matrixResults(
      sourceLanguage: TranslationLanguage.russian,
      sourceText: sourceText,
    );
    final int problemIndex = routes.indexWhere(
      (TranslationRouteResult route) => route.route.id == 'RU_TO_TH',
    );
    final TranslationRouteResult problem = routes[problemIndex];

    final MockClient httpClient = MockClient((http.Request request) async {
      return _chatResponse(
        jsonEncode(
          _auditResponse(
            routes,
            replacements: <int, Map<String, Object?>>{
              problemIndex: _differentMeaningAudit(
                differenceType: 'SPECIFICITY_CHANGE',
                sourceExcerpt: problem.sourceText,
                targetExcerpt: problem.translatedText,
                sourceFact: 'The source names a built-in cooktop.',
                targetFact: 'The translation names a generic stove.',
              ),
            },
          ),
        ),
      );
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: sourceText,
      originalSourceLanguage: TranslationLanguage.russian,
      routes: routes,
    );

    expect(report.limitations, isEmpty);
    expect(report.observations, hasLength(6));
    final SemanticObservation problemObservation = report.observations
        .singleWhere(
          (SemanticObservation observation) =>
              observation.routeId == problem.route.id,
        );
    expect(problemObservation.dimension, SemanticDimension.specificity);
    expect(problemObservation.preservation, MeaningPreservation.altered);
    expect(
      problemObservation.verificationStatus,
      ObservationVerificationStatus.confirmed,
    );
    expect(
      report.observations
          .where(
            (SemanticObservation observation) =>
                observation.routeId != problem.route.id,
          )
          .every(
            (SemanticObservation observation) =>
                observation.preservation == MeaningPreservation.preserved,
          ),
      isTrue,
    );
  });

  test(
    'prototype factual object change becomes critical observation',
    () async {
      final List<TranslationRouteResult> routes = _matrixResults(
        sourceLanguage: TranslationLanguage.russian,
        sourceText: 'варочная панель',
      );
      final int problemIndex = routes.indexWhere(
        (TranslationRouteResult route) => route.route.id == 'RU_TO_EN',
      );
      final TranslationRouteResult problem = routes[problemIndex];

      final MockClient httpClient = MockClient((http.Request request) async {
        return _chatResponse(
          jsonEncode(
            _auditResponse(
              routes,
              replacements: <int, Map<String, Object?>>{
                problemIndex: _differentMeaningAudit(
                  differenceType: 'OBJECT_CHANGE',
                  sourceExcerpt: problem.sourceText,
                  targetExcerpt: problem.translatedText,
                  sourceFact: 'The source names a cooktop.',
                  targetFact: 'The translation names an oven.',
                ),
              },
            ),
          ),
        );
      });
      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
        config: config,
      );
      addTearDown(gateway.close);

      final report = await gateway.auditPrototypeMatrix(
        apiKey: 'secret',
        originalSourceText: 'варочная панель',
        originalSourceLanguage: TranslationLanguage.russian,
        routes: routes,
      );

      expect(report.limitations, isEmpty);
      expect(report.observations, hasLength(6));
      final SemanticObservation problemObservation = report.observations
          .singleWhere(
            (SemanticObservation observation) =>
                observation.routeId == problem.route.id,
          );
      expect(problemObservation.dimension, SemanticDimension.object);
      expect(problemObservation.preservation, MeaningPreservation.altered);
    },
  );

  test('invalid prototype audit is retried once and then accepted', () async {
    final List<TranslationRouteResult> routes = _matrixResults(
      sourceLanguage: TranslationLanguage.thai,
      sourceText: 'ข้อความต้นฉบับ',
    );
    int requestCount = 0;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;

      if (requestCount == 1) {
        return _chatResponse(
          jsonEncode(<String, Object>{'route_audits': <Object>[]}),
        );
      }

      return _chatResponse(jsonEncode(_auditResponse(routes)));
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: 'ข้อความต้นฉบับ',
      originalSourceLanguage: TranslationLanguage.thai,
      routes: routes,
    );

    expect(requestCount, 2);
    expect(report.observations, hasLength(6));
    expect(
      report.observations.every(
        (SemanticObservation observation) =>
            observation.preservation == MeaningPreservation.preserved,
      ),
      isTrue,
    );
    expect(report.limitations, isEmpty);
  });

  test('prototype audit route mismatch is never accepted as clean', () async {
    final List<TranslationRouteResult> routes = _matrixResults(
      sourceLanguage: TranslationLanguage.english,
      sourceText: 'Source',
    );
    int requestCount = 0;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;

      return _chatResponse(
        jsonEncode(
          _auditResponse(
            routes,
            replacements: <int, Map<String, Object?>>{
              1: <String, Object?>{
                'route': routes.first.route.id,
                ..._sameMeaningAudit(),
              },
            },
          ),
        ),
      );
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: 'Source',
      originalSourceLanguage: TranslationLanguage.english,
      routes: routes,
    );

    expect(requestCount, 2);
    expect(report.limitations, <String>['AUDIT_RESPONSE_INVALID']);
    expect(report.observations, hasLength(6));
    final SemanticObservation mismatchedRouteObservation = report.observations
        .singleWhere(
          (SemanticObservation observation) =>
              observation.routeId == routes[1].route.id,
        );
    expect(
      mismatchedRouteObservation.verificationStatus,
      ObservationVerificationStatus.unverifiable,
    );
  });

  test('two invalid prototype audits become an indeterminate report', () async {
    final List<TranslationRouteResult> routes = _matrixResults(
      sourceLanguage: TranslationLanguage.thai,
      sourceText: 'ข้อความต้นฉบับ',
    );
    int requestCount = 0;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;

      return _chatResponse(
        jsonEncode(<String, Object>{'route_audits': <Object>[]}),
      );
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: 'ข้อความต้นฉบับ',
      originalSourceLanguage: TranslationLanguage.thai,
      routes: routes,
    );

    expect(requestCount, 2);
    expect(report.limitations, <String>['AUDIT_RESPONSE_INVALID']);
    expect(report.observations, hasLength(6));
    expect(
      report.observations.every(
        (SemanticObservation observation) =>
            observation.verificationStatus ==
            ObservationVerificationStatus.unverifiable,
      ),
      isTrue,
    );
  });

  test('one malformed route stays local after the retry', () async {
    final List<TranslationRouteResult> routes = _matrixResults(
      sourceLanguage: TranslationLanguage.english,
      sourceText: 'Source',
    );
    int requestCount = 0;
    final Map<String, Object?> malformed = <String, Object?>{
      'judgment': 'SAME_MEANING',
      'difference': null,
    };

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;

      return _chatResponse(
        jsonEncode(
          _auditResponse(
            routes,
            replacements: <int, Map<String, Object?>>{2: malformed},
          ),
        ),
      );
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final report = await gateway.auditPrototypeMatrix(
      apiKey: 'secret',
      originalSourceText: 'Source',
      originalSourceLanguage: TranslationLanguage.english,
      routes: routes,
    );

    expect(requestCount, 2);
    expect(report.limitations, <String>['AUDIT_RESPONSE_INVALID']);
    expect(report.observations, hasLength(6));
    final SemanticObservation malformedObservation = report.observations
        .singleWhere(
          (SemanticObservation observation) =>
              observation.routeId == routes[2].route.id,
        );
    expect(
      malformedObservation.verificationStatus,
      ObservationVerificationStatus.unverifiable,
    );
    expect(
      report.observations
          .where(
            (SemanticObservation observation) =>
                observation.routeId != routes[2].route.id,
          )
          .every(
            (SemanticObservation observation) =>
                observation.preservation == MeaningPreservation.preserved,
          ),
      isTrue,
    );
  });
}

Map<String, Object> _auditResponse(
  List<TranslationRouteResult> routes, {
  Map<int, Map<String, Object?>> replacements =
      const <int, Map<String, Object?>>{},
}) {
  return <String, Object>{
    'route_audits': <Object>[
      for (int index = 0; index < routes.length; index += 1)
        <String, Object?>{
          'route': routes[index].route.id,
          ...(replacements[index] ?? _sameMeaningAudit()),
        },
    ],
  };
}

Map<String, Object?> _sameMeaningAudit() {
  return <String, Object?>{
    'judgment': 'SAME_MEANING',
    'difference': null,
    'limitations': <Object>[],
  };
}

Map<String, Object?> _differentMeaningAudit({
  required String differenceType,
  required String sourceExcerpt,
  required String targetExcerpt,
  required String sourceFact,
  required String targetFact,
}) {
  return <String, Object?>{
    'judgment': 'DIFFERENT_MEANING',
    'difference': <String, Object?>{
      'difference_type': differenceType,
      'source_excerpt': sourceExcerpt,
      'target_excerpt': targetExcerpt,
      'source_fact': sourceFact,
      'target_fact': targetFact,
    },
    'limitations': <Object>[],
  };
}

List<TranslationRouteResult> _matrixResults({
  required TranslationLanguage sourceLanguage,
  required String sourceText,
}) {
  const CompleteThreeLanguageRoutePlanner planner =
      CompleteThreeLanguageRoutePlanner();
  final List<TranslationRoute> routes = planner.build(sourceLanguage);
  final Map<TranslationLanguage, String> sourceTexts =
      <TranslationLanguage, String>{sourceLanguage: sourceText};
  final Map<String, String> translations = <String, String>{};

  for (final TranslationRoute route in routes) {
    if (route.role != TranslationRouteRole.primary) {
      continue;
    }

    final String translatedText = '${route.id}-target';
    translations[route.id] = translatedText;
    sourceTexts[route.target] = translatedText;
  }

  return <TranslationRouteResult>[
    for (final TranslationRoute route in routes)
      TranslationRouteResult(
        route: route,
        sourceText: sourceTexts[route.source]!,
        translatedText: translations[route.id] ?? '${route.id}-cross-target',
      ),
  ];
}

Map<String, dynamic> _userData(http.Request request) {
  final Map<String, dynamic> body =
      jsonDecode(request.body) as Map<String, dynamic>;
  final List<dynamic> messages = body['messages'] as List<dynamic>;
  final Map<String, dynamic> userMessage = messages[1] as Map<String, dynamic>;

  return jsonDecode(userMessage['content'] as String) as Map<String, dynamic>;
}

String _systemPrompt(http.Request request) {
  final Map<String, dynamic> body =
      jsonDecode(request.body) as Map<String, dynamic>;
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
