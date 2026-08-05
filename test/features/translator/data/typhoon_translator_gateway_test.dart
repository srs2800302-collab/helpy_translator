import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_chat_client.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_config.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_gateway.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_audit_report.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_observation.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_batch_request.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route_result.dart';
import 'package:helpy_translator/features/translator/domain/errors/translator_exception.dart';

void main() {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();

  test(
    'single translation preserves source text and parses exact JSON',
    () async {
      const String exactSource = '  Do not change these spaces.  ';
      late Map<String, dynamic> requestBody;

      final MockClient httpClient = MockClient((http.Request request) async {
        expect(request.url, config.chatCompletionsUri);
        expect(request.headers['authorization'], 'Bearer secret');
        expect(request.body, isNot(contains('secret')));

        requestBody = jsonDecode(request.body) as Map<String, dynamic>;

        return _chatResponse('{"translation":"Не меняйте эти пробелы."}');
      });
      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
        config: config,
      );
      addTearDown(gateway.close);

      final String result = await gateway.translate(
        apiKey: 'secret',
        sourceLanguage: TranslationLanguage.english,
        targetLanguage: TranslationLanguage.russian,
        sourceText: exactSource,
      );

      expect(result, 'Не меняйте эти пробелы.');
      expect(requestBody['max_tokens'], config.translationMaxTokens);

      final Map<String, dynamic> userData = _userDataFromBody(requestBody);
      expect(userData['source_language'], 'EN');
      expect(userData['target_language'], 'RU');
      expect(userData['source_text'], exactSource);
    },
  );

  test(
    'translation batch maps ordered strings to local route metadata',
    () async {
      const String source = 'Exact source';
      late Map<String, dynamic> userData;

      final MockClient httpClient = MockClient((http.Request request) async {
        userData = _userData(request);

        return _chatResponse(
          jsonEncode(<String, Object>{
            'translations': <String>['Перевод', 'คำแปล'],
          }),
        );
      });
      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
        config: config,
      );
      addTearDown(gateway.close);

      final List<TranslationRouteResult> results = await gateway.translateBatch(
        apiKey: 'secret',
        requests: const <TranslationBatchRequest>[
          TranslationBatchRequest(
            route: TranslationRoute(
              source: TranslationLanguage.english,
              target: TranslationLanguage.russian,
              role: TranslationRouteRole.primary,
            ),
            sourceText: source,
          ),
          TranslationBatchRequest(
            route: TranslationRoute(
              source: TranslationLanguage.english,
              target: TranslationLanguage.thai,
              role: TranslationRouteRole.primary,
            ),
            sourceText: source,
          ),
        ],
      );

      expect(userData.keys.toSet(), <String>{'requests'});
      expect(
        results.map((TranslationRouteResult result) => result.route.id),
        <String>['EN_TO_RU', 'EN_TO_TH'],
      );
      expect(
        results.map((TranslationRouteResult result) => result.translatedText),
        <String>['Перевод', 'คำแปล'],
      );
    },
  );

  test('translation batch rejects an incomplete ordered response', () async {
    final MockClient httpClient = MockClient((http.Request request) async {
      return _chatResponse(
        jsonEncode(<String, Object>{
          'translations': <String>['Translation'],
        }),
      );
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    await expectLater(
      gateway.translateBatch(
        apiKey: 'secret',
        requests: const <TranslationBatchRequest>[
          TranslationBatchRequest(
            route: TranslationRoute(
              source: TranslationLanguage.russian,
              target: TranslationLanguage.english,
              role: TranslationRouteRole.primary,
            ),
            sourceText: 'Текст',
          ),
          TranslationBatchRequest(
            route: TranslationRoute(
              source: TranslationLanguage.russian,
              target: TranslationLanguage.thai,
              role: TranslationRouteRole.primary,
            ),
            sourceText: 'Текст',
          ),
        ],
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

  test('translation batch rejects route-bearing response objects', () async {
    final MockClient httpClient = MockClient((http.Request request) async {
      return _chatResponse(
        jsonEncode(<String, Object>{
          'translations': <Object>[
            <String, Object>{'route': 'RU_TO_EN', 'translation': 'Translation'},
            <String, Object>{'route': 'RU_TO_TH', 'translation': 'คำแปล'},
          ],
        }),
      );
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    await expectLater(
      gateway.translateBatch(
        apiKey: 'secret',
        requests: const <TranslationBatchRequest>[
          TranslationBatchRequest(
            route: TranslationRoute(
              source: TranslationLanguage.english,
              target: TranslationLanguage.russian,
              role: TranslationRouteRole.primary,
            ),
            sourceText: 'Source',
          ),
          TranslationBatchRequest(
            route: TranslationRoute(
              source: TranslationLanguage.english,
              target: TranslationLanguage.thai,
              role: TranslationRouteRole.primary,
            ),
            sourceText: 'Source',
          ),
        ],
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

  test('same-meaning pair judgment is symmetric for RU EN and TH', () async {
    const List<_LanguageAuditCase> cases = <_LanguageAuditCase>[
      _LanguageAuditCase(
        sourceText: 'Вы должны уведомить клиента.',
        sourceLanguage: TranslationLanguage.russian,
        route: TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.russian,
            target: TranslationLanguage.english,
            role: TranslationRouteRole.primary,
          ),
          sourceText: 'Вы должны уведомить клиента.',
          translatedText: 'You must inform the customer.',
        ),
      ),
      _LanguageAuditCase(
        sourceText: 'You must notify the client.',
        sourceLanguage: TranslationLanguage.english,
        route: TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.english,
            target: TranslationLanguage.thai,
            role: TranslationRouteRole.primary,
          ),
          sourceText: 'You must notify the client.',
          translatedText: 'คุณต้องแจ้งให้ลูกค้าทราบ',
        ),
      ),
      _LanguageAuditCase(
        sourceText: 'คุณต้องแจ้งให้ลูกค้าทราบ',
        sourceLanguage: TranslationLanguage.thai,
        route: TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.thai,
            target: TranslationLanguage.russian,
            role: TranslationRouteRole.primary,
          ),
          sourceText: 'คุณต้องแจ้งให้ลูกค้าทราบ',
          translatedText: 'Вы должны сообщить клиенту.',
        ),
      ),
    ];

    for (final _LanguageAuditCase auditCase in cases) {
      int requestCount = 0;
      final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];
      final MockClient httpClient = MockClient((http.Request request) async {
        requestCount += 1;
        payloads.add(_userData(request));
        return _auditResponse(<Map<String, Object?>>[
          _routeAudit(judgment: 'SAME_MEANING'),
        ]);
      });
      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
        config: config,
      );

      try {
        final SemanticAuditReport report = await gateway.auditMatrix(
          apiKey: 'secret',
          originalSourceText: auditCase.sourceText,
          originalSourceLanguage: auditCase.sourceLanguage,
          routes: <TranslationRouteResult>[auditCase.route],
        );

        expect(requestCount, 2);
        expect(payloads[0], payloads[1]);
        expect(report.observations, isEmpty);
        expect(report.limitations, isEmpty);
      } finally {
        gateway.close();
      }
    }
  });

  test('two matching factual differences confirm altered meaning', () async {
    int requestCount = 0;
    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;
      return _auditResponse(<Map<String, Object?>>[
        _routeAudit(
          judgment: 'DIFFERENT_MEANING',
          difference: _difference(
            differenceType: 'OBJECT_CHANGE',
            sourceExcerpt: 'source-token',
            targetExcerpt: 'target-token',
            sourceFact: 'The source refers to a cooktop.',
            targetFact: 'The translation refers to an oven.',
          ),
        ),
      ]);
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditMatrix(
      apiKey: 'secret',
      originalSourceText: 'source-token',
      originalSourceLanguage: TranslationLanguage.english,
      routes: _singleEnglishToThaiRoute,
    );

    expect(requestCount, 2);
    final SemanticObservation observation = report.observations.single;
    expect(observation.relation, SemanticRelation.substitution);
    expect(observation.dimension, SemanticDimension.object);
    expect(observation.preservation, MeaningPreservation.altered);
    expect(
      observation.verificationStatus,
      ObservationVerificationStatus.confirmed,
    );
    expect(report.limitations, isEmpty);
  });

  test('a difference emitted by only one judge remains unconfirmed', () async {
    int requestIndex = 0;
    final MockClient httpClient = MockClient((http.Request request) async {
      final bool firstPass = requestIndex == 0;
      requestIndex += 1;

      return _auditResponse(<Map<String, Object?>>[
        firstPass
            ? _routeAudit(
                judgment: 'DIFFERENT_MEANING',
                difference: _difference(
                  differenceType: 'OBJECT_CHANGE',
                  sourceExcerpt: 'source-token',
                  targetExcerpt: 'target-token',
                  sourceFact: 'The source refers to a cooktop.',
                  targetFact: 'The translation refers to an oven.',
                ),
              )
            : _routeAudit(judgment: 'SAME_MEANING'),
      ]);
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditMatrix(
      apiKey: 'secret',
      originalSourceText: 'source-token',
      originalSourceLanguage: TranslationLanguage.english,
      routes: _singleEnglishToThaiRoute,
    );

    expect(report.limitations, <String>['AUDIT_PASSES_DISAGREE']);
    final SemanticObservation observation = report.observations.single;
    expect(
      observation.verificationStatus,
      ObservationVerificationStatus.unverifiable,
    );
    expect(observation.preservation, MeaningPreservation.altered);
  });

  test('different factual types remain a visible conflict', () async {
    int requestIndex = 0;
    final MockClient httpClient = MockClient((http.Request request) async {
      final bool firstPass = requestIndex == 0;
      requestIndex += 1;

      return _auditResponse(<Map<String, Object?>>[
        _routeAudit(
          judgment: 'DIFFERENT_MEANING',
          difference: _difference(
            differenceType: firstPass ? 'OBJECT_CHANGE' : 'ACTOR_CHANGE',
            sourceExcerpt: 'source-token',
            targetExcerpt: 'target-token',
            sourceFact: 'The source states one real-world fact.',
            targetFact: 'The translation states another real-world fact.',
          ),
        ),
      ]);
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditMatrix(
      apiKey: 'secret',
      originalSourceText: 'source-token',
      originalSourceLanguage: TranslationLanguage.english,
      routes: _singleEnglishToThaiRoute,
    );

    final SemanticObservation observation = report.observations.single;
    expect(
      observation.verificationStatus,
      ObservationVerificationStatus.conflict,
    );
    expect(observation.dimension, SemanticDimension.object);
    expect(observation.verifierDimension, SemanticDimension.actor);
    expect(report.limitations, <String>['AUDIT_PASSES_DISAGREE']);
  });

  test('different factual proofs cannot confirm the same label', () async {
    int requestIndex = 0;
    final MockClient httpClient = MockClient((http.Request request) async {
      final bool firstPass = requestIndex == 0;
      requestIndex += 1;

      return _auditResponse(<Map<String, Object?>>[
        _routeAudit(
          judgment: 'DIFFERENT_MEANING',
          difference: _difference(
            differenceType: 'OBJECT_CHANGE',
            sourceExcerpt: 'source-token',
            targetExcerpt: 'target-token',
            sourceFact: firstPass
                ? 'The source refers to a cooktop.'
                : 'The source refers to a cooking device.',
            targetFact: firstPass
                ? 'The translation refers to an oven.'
                : 'The translation refers to a different appliance.',
          ),
        ),
      ]);
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditMatrix(
      apiKey: 'secret',
      originalSourceText: 'source-token',
      originalSourceLanguage: TranslationLanguage.english,
      routes: _singleEnglishToThaiRoute,
    );

    expect(report.limitations, <String>['AUDIT_PASSES_DISAGREE']);
    expect(report.observations, hasLength(2));
    expect(
      report.observations.every(
        (SemanticObservation observation) =>
            observation.verificationStatus ==
            ObservationVerificationStatus.unverifiable,
      ),
      isTrue,
    );
  });

  test('UNSURE produces one unverified route result', () async {
    final MockClient httpClient = MockClient((http.Request request) async {
      return _auditResponse(<Map<String, Object?>>[
        _routeAudit(
          judgment: 'UNSURE',
          limitations: <Object>['INSUFFICIENT_CONTEXT'],
        ),
      ]);
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditMatrix(
      apiKey: 'secret',
      originalSourceText: 'source-token',
      originalSourceLanguage: TranslationLanguage.english,
      routes: _singleEnglishToThaiRoute,
    );

    expect(report.limitations, <String>['INSUFFICIENT_CONTEXT']);
    expect(report.observations, hasLength(1));
    expect(
      report.observations.single.verificationStatus,
      ObservationVerificationStatus.unverifiable,
    );
  });

  test(
    'lexical classifications are rejected by the direct pair contract',
    () async {
      final MockClient httpClient = MockClient((http.Request request) async {
        return _auditResponse(<Map<String, Object?>>[
          _routeAudit(
            judgment: 'DIFFERENT_MEANING',
            difference: _difference(
              differenceType: 'LEXICAL_CHOICE',
              sourceExcerpt: 'source-token',
              targetExcerpt: 'target-token',
              sourceFact: 'The source uses one word.',
              targetFact: 'The translation uses another word.',
            ),
          ),
        ]);
      });
      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
        config: config,
      );
      addTearDown(gateway.close);

      final SemanticAuditReport report = await gateway.auditMatrix(
        apiKey: 'secret',
        originalSourceText: 'source-token',
        originalSourceLanguage: TranslationLanguage.english,
        routes: _singleEnglishToThaiRoute,
      );

      expect(report.limitations, <String>['AUDIT_RESPONSE_INVALID']);
      expect(report.observations, hasLength(1));
      expect(
        report.observations.single.verificationStatus,
        ObservationVerificationStatus.unverifiable,
      );
    },
  );

  test(
    'ungrounded difference is quarantined without discarding another route',
    () async {
      final MockClient httpClient = MockClient((http.Request request) async {
        return _auditResponse(<Map<String, Object?>>[
          _routeAudit(
            judgment: 'DIFFERENT_MEANING',
            difference: _difference(
              differenceType: 'OMISSION',
              sourceExcerpt: 'not-present',
              targetExcerpt: null,
              sourceFact: 'A required fact is present in the source.',
              targetFact: null,
            ),
          ),
          _routeAudit(judgment: 'SAME_MEANING'),
        ]);
      });
      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
        config: config,
      );
      addTearDown(gateway.close);

      final SemanticAuditReport report = await gateway.auditMatrix(
        apiKey: 'secret',
        originalSourceText: 'source-a source-b',
        originalSourceLanguage: TranslationLanguage.english,
        routes: _twoPrimaryRoutes,
      );

      expect(report.limitations, <String>['AUDIT_EVIDENCE_NOT_GROUNDED']);
      expect(report.observations, hasLength(1));
      expect(report.observations.single.routeId, 'EN_TO_RU');
      expect(
        report.observations.single.verificationStatus,
        ObservationVerificationStatus.unverifiable,
      );
    },
  );

  test('malformed ordered group affects only its route', () async {
    final MockClient httpClient = MockClient((http.Request request) async {
      return _auditResponse(<Map<String, Object?>>[
        <String, Object?>{
          'judgment': 'SAME_MEANING',
          'difference': null,
          'limitations': 'not-an-array',
        },
        _routeAudit(judgment: 'SAME_MEANING'),
      ]);
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditMatrix(
      apiKey: 'secret',
      originalSourceText: 'source-a source-b',
      originalSourceLanguage: TranslationLanguage.english,
      routes: _twoPrimaryRoutes,
    );

    expect(report.limitations, <String>['AUDIT_RESPONSE_INVALID']);
    expect(report.observations, hasLength(1));
    expect(report.observations.single.routeId, 'EN_TO_RU');
  });

  test('cross-check-only expansion uses two direct pair judgments', () async {
    int requestCount = 0;
    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;
      return _auditResponse(<Map<String, Object?>>[
        _routeAudit(judgment: 'SAME_MEANING'),
        _routeAudit(judgment: 'SAME_MEANING'),
      ]);
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    final SemanticAuditReport report = await gateway.auditMatrix(
      apiKey: 'secret',
      originalSourceText: 'Исходный текст',
      originalSourceLanguage: TranslationLanguage.russian,
      routes: _crossLanguageRoutes,
    );

    expect(requestCount, 2);
    expect(report.observations, isEmpty);
    expect(report.limitations, isEmpty);
  });

  test(
    'provider failure in either judgment marks every route unverified',
    () async {
      int requestCount = 0;
      final MockClient httpClient = MockClient((http.Request request) async {
        requestCount += 1;

        if (requestCount == 1) {
          return _auditResponse(<Map<String, Object?>>[
            _routeAudit(judgment: 'SAME_MEANING'),
            _routeAudit(judgment: 'SAME_MEANING'),
          ]);
        }

        return http.Response(
          'provider failure',
          503,
          headers: const <String, String>{
            'content-type': 'text/plain; charset=utf-8',
          },
        );
      });
      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
        config: config,
      );
      addTearDown(gateway.close);

      final SemanticAuditReport report = await gateway.auditMatrix(
        apiKey: 'secret',
        originalSourceText: 'source-a source-b',
        originalSourceLanguage: TranslationLanguage.english,
        routes: _twoPrimaryRoutes,
      );

      expect(requestCount, 2);
      expect(report.limitations, <String>['AUDIT_PROVIDER_FAILURE']);
      expect(report.observations, hasLength(_twoPrimaryRoutes.length));
      expect(
        report.observations.every(
          (SemanticObservation observation) =>
              observation.verificationStatus ==
              ObservationVerificationStatus.unverifiable,
        ),
        isTrue,
      );
    },
  );

  test('audit prompts request only direct pair meaning judgments', () async {
    final List<String> systemPrompts = <String>[];
    final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];

    final MockClient httpClient = MockClient((http.Request request) async {
      systemPrompts.add(_systemPrompt(request));
      payloads.add(_userData(request));
      return _auditResponse(<Map<String, Object?>>[
        _routeAudit(judgment: 'SAME_MEANING'),
      ]);
    });
    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );
    addTearDown(gateway.close);

    await gateway.auditMatrix(
      apiKey: 'secret',
      originalSourceText: 'source-token',
      originalSourceLanguage: TranslationLanguage.english,
      routes: _singleEnglishToThaiRoute,
    );

    expect(systemPrompts, hasLength(2));
    expect(payloads[0], payloads[1]);

    for (final String prompt in systemPrompts) {
      expect(prompt, contains('source_text'));
      expect(prompt, contains('translated_text'));
      expect(prompt, contains('SAME_MEANING'));
      expect(prompt, contains('DIFFERENT_MEANING'));
      expect(prompt, contains('counterexample'));
      expect(prompt, contains('Different words are not evidence'));
      expect(prompt, contains('one strongest'));
      expect(prompt, contains('Do not invent context, products'));
      expect(prompt, isNot(contains('"observations"')));
      expect(prompt, isNot(contains('LEXICAL_CHOICE')));
      expect(prompt, isNot(contains('TERMINOLOGY')));
      expect(prompt, isNot(contains('UNRELIABLE')));
    }

    expect(systemPrompts[0], contains('judge A'));
    expect(systemPrompts[1], contains('judge B'));
    expect(systemPrompts[1], contains('no findings from another judge'));
  });
}

Map<String, dynamic> _userData(http.Request request) {
  final Map<String, dynamic> requestBody =
      jsonDecode(request.body) as Map<String, dynamic>;

  return _userDataFromBody(requestBody);
}

String _systemPrompt(http.Request request) {
  final Map<String, dynamic> requestBody =
      jsonDecode(request.body) as Map<String, dynamic>;
  final List<dynamic> messages = requestBody['messages'] as List<dynamic>;
  final Map<String, dynamic> systemMessage =
      messages[0] as Map<String, dynamic>;

  return systemMessage['content'] as String;
}

Map<String, dynamic> _userDataFromBody(Map<String, dynamic> requestBody) {
  final List<dynamic> messages = requestBody['messages'] as List<dynamic>;
  final Map<String, dynamic> userMessage = messages[1] as Map<String, dynamic>;

  return jsonDecode(userMessage['content'] as String) as Map<String, dynamic>;
}

Map<String, Object?> _routeAudit({
  required String judgment,
  Map<String, Object?>? difference,
  List<Object> limitations = const <Object>[],
}) {
  return <String, Object?>{
    'judgment': judgment,
    'difference': difference,
    'limitations': limitations,
  };
}

Map<String, Object?> _difference({
  required String differenceType,
  required String? sourceExcerpt,
  required String? targetExcerpt,
  required String? sourceFact,
  required String? targetFact,
}) {
  return <String, Object?>{
    'difference_type': differenceType,
    'source_excerpt': sourceExcerpt,
    'target_excerpt': targetExcerpt,
    'source_fact': sourceFact,
    'target_fact': targetFact,
  };
}

http.Response _auditResponse(List<Map<String, Object?>> routeAudits) {
  return _chatResponse(
    jsonEncode(<String, Object>{'route_audits': routeAudits}),
  );
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

const List<TranslationRouteResult> _singleEnglishToThaiRoute =
    <TranslationRouteResult>[
      TranslationRouteResult(
        route: TranslationRoute(
          source: TranslationLanguage.english,
          target: TranslationLanguage.thai,
          role: TranslationRouteRole.primary,
        ),
        sourceText: 'source-token',
        translatedText: 'target-token',
      ),
    ];

const List<TranslationRouteResult> _twoPrimaryRoutes = <TranslationRouteResult>[
  TranslationRouteResult(
    route: TranslationRoute(
      source: TranslationLanguage.english,
      target: TranslationLanguage.russian,
      role: TranslationRouteRole.primary,
    ),
    sourceText: 'source-a source-b',
    translatedText: 'target-a',
  ),
  TranslationRouteResult(
    route: TranslationRoute(
      source: TranslationLanguage.english,
      target: TranslationLanguage.thai,
      role: TranslationRouteRole.primary,
    ),
    sourceText: 'source-a source-b',
    translatedText: 'target-b',
  ),
];

const List<TranslationRouteResult> _crossLanguageRoutes =
    <TranslationRouteResult>[
      TranslationRouteResult(
        route: TranslationRoute(
          source: TranslationLanguage.english,
          target: TranslationLanguage.thai,
          role: TranslationRouteRole.crossCheck,
        ),
        sourceText: 'English derived text',
        translatedText: 'ข้อความภาษาไทย',
      ),
      TranslationRouteResult(
        route: TranslationRoute(
          source: TranslationLanguage.thai,
          target: TranslationLanguage.english,
          role: TranslationRouteRole.crossCheck,
        ),
        sourceText: 'ข้อความภาษาไทย',
        translatedText: 'English derived text',
      ),
    ];

final class _LanguageAuditCase {
  const _LanguageAuditCase({
    required this.sourceText,
    required this.sourceLanguage,
    required this.route,
  });

  final String sourceText;
  final TranslationLanguage sourceLanguage;
  final TranslationRouteResult route;
}
