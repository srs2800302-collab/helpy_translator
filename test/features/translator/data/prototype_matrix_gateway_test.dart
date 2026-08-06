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
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();
  const CompleteThreeLanguageRoutePlanner planner =
      CompleteThreeLanguageRoutePlanner();

  test('prototype matrix still returns six named routes in one call', () async {
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
  });

  test(
    'clean matrix requires three isolated audit calls and preserves six routes',
    () async {
      final List<TranslationRouteResult> routes = _cleanMatrix();
      final List<Map<String, dynamic>> requestBodies = <Map<String, dynamic>>[];

      final MockClient httpClient = MockClient((http.Request request) async {
        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        requestBodies.add(body);
        final String prompt = _systemPrompt(body);
        final Map<String, dynamic> payload = _userDataFromBody(body);

        if (prompt.contains('source-side semantic analyst S')) {
          expect(payload.keys.toSet(), <String>{'items'});
          expect(
            (payload['items'] as List<dynamic>).every(
              (dynamic item) =>
                  (item as Map<String, dynamic>).keys.toSet().containsAll(
                    <String>{'route', 'language', 'text'},
                  ) &&
                  !item.containsKey('translated_text'),
            ),
            isTrue,
          );
          return _chatResponse(_frameResponse(payload, _messageFrame));
        }

        if (prompt.contains('target-side semantic analyst T')) {
          expect(payload.keys.toSet(), <String>{'items'});
          expect(
            (payload['items'] as List<dynamic>).every(
              (dynamic item) =>
                  !(item as Map<String, dynamic>).containsKey('source_text'),
            ),
            isTrue,
          );
          return _chatResponse(_frameResponse(payload, _messageFrame));
        }

        if (prompt.contains('blind bilingual pair judge P')) {
          return _chatResponse(_sameMeaningResponse(payload));
        }

        throw StateError('Unexpected prompt: $prompt');
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

      expect(requestBodies, hasLength(3));
      expect(requestBodies[0]['model'], config.model);
      expect(requestBodies[1]['model'], config.model);
      expect(requestBodies[2]['model'], config.model);
      expect(
        requestBodies.map((Map<String, dynamic> body) => body['model']),
        everyElement(config.model),
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
    },
  );

  test(
    'Russian cooktop false-green case is downgraded by blind conflict audit',
    () async {
      final List<TranslationRouteResult> routes = _russianCooktopMatrix();
      int requestCount = 0;

      final MockClient httpClient = MockClient((http.Request request) async {
        requestCount += 1;
        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        final String prompt = _systemPrompt(body);
        final Map<String, dynamic> payload = _userDataFromBody(body);

        if (prompt.contains('source-side semantic analyst S')) {
          return _chatResponse(_frameResponse(payload, _cooktopFrame));
        }

        if (prompt.contains('target-side semantic analyst T')) {
          return _chatResponse(_frameResponse(payload, _cooktopFrame));
        }

        if (prompt.contains('blind bilingual pair judge P')) {
          return _chatResponse(_sameMeaningResponse(payload));
        }

        if (prompt.contains('blind conflict judge C')) {
          return _chatResponse(_differentMeaningResponse(payload));
        }

        throw StateError('Unexpected prompt: $prompt');
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

      expect(requestCount, 4);
      expect(report.observations, hasLength(6));
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
    },
  );

  test('conflict judge cannot upgrade disagreement to green', () async {
    final List<TranslationRouteResult> routes = _russianCooktopMatrix();

    final MockClient httpClient = MockClient((http.Request request) async {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      final String prompt = _systemPrompt(body);
      final Map<String, dynamic> payload = _userDataFromBody(body);

      if (prompt.contains('source-side semantic analyst S') ||
          prompt.contains('target-side semantic analyst T')) {
        return _chatResponse(_frameResponse(payload, _cooktopFrame));
      }

      if (prompt.contains('blind bilingual pair judge P') ||
          prompt.contains('blind conflict judge C')) {
        return _chatResponse(_sameMeaningResponse(payload));
      }

      throw StateError('Unexpected prompt: $prompt');
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
    expect(report.limitations, contains('AUDIT_SIGNALS_DISAGREE'));
    expect(report.limitations, contains('AUDIT_CONFLICT_UNRESOLVED'));
    expect(assessment.verdict, MatrixVerdict.indeterminate);
  });

  test('unknown semantic frame is fail-closed', () async {
    final List<TranslationRouteResult> routes = _cleanMatrix();

    final MockClient httpClient = MockClient((http.Request request) async {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      final String prompt = _systemPrompt(body);
      final Map<String, dynamic> payload = _userDataFromBody(body);

      if (prompt.contains('source-side semantic analyst S')) {
        return _chatResponse(
          _frameResponse(payload, (Map<String, dynamic> item) {
            return _messageFrame(item).withSpecificity('UNKNOWN');
          }),
        );
      }

      if (prompt.contains('target-side semantic analyst T')) {
        return _chatResponse(_frameResponse(payload, _messageFrame));
      }

      if (prompt.contains('blind bilingual pair judge P')) {
        return _chatResponse(_sameMeaningResponse(payload));
      }

      throw StateError('Unexpected prompt: $prompt');
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

    expect(report.limitations, contains('SEMANTIC_FRAME_UNKNOWN'));
    expect(
      report.observations.every(
        (SemanticObservation observation) =>
            observation.verificationStatus ==
            ObservationVerificationStatus.unverifiable,
      ),
      isTrue,
    );
  });

  test(
    'malformed semantic frame response returns six unverifiable routes',
    () async {
      final List<TranslationRouteResult> routes = _cleanMatrix();

      final MockClient httpClient = MockClient((http.Request request) async {
        return _chatResponse('{"frames":[]}');
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

      expect(report.observations, hasLength(6));
      expect(report.limitations, contains('AUDIT_RESPONSE_INVALID'));
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

String _frameResponse(
  Map<String, dynamic> payload,
  _FrameData Function(Map<String, dynamic> item) frameBuilder,
) {
  final List<dynamic> items = payload['items'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'frames': <Object>[
      for (final dynamic rawItem in items)
        frameBuilder(rawItem as Map<String, dynamic>).toJson(),
    ],
  });
}

_FrameData _messageFrame(Map<String, dynamic> item) {
  return _FrameData(
    route: item['route'] as String,
    concepts: const <String>['MESSAGE'],
    specificity: 'ABSTRACT',
  );
}

_FrameData _cooktopFrame(Map<String, dynamic> item) {
  final String text = item['text'] as String;
  final bool genericStove = text == 'เตาไฟ';

  return _FrameData(
    route: item['route'] as String,
    concepts: <String>[genericStove ? 'GENERIC_STOVE' : 'COOKTOP'],
    specificity: genericStove ? 'GENERAL' : 'EXACT_TERM',
  );
}

String _sameMeaningResponse(Map<String, dynamic> payload) {
  final List<dynamic> routes = payload['routes'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'route_audits': <Object>[
      for (final dynamic rawRoute in routes)
        <String, Object?>{
          'route': (rawRoute as Map<String, dynamic>)['route'],
          'judgment': 'SAME_MEANING',
          'difference_type': null,
          'source_excerpt': null,
          'target_excerpt': null,
          'source_fact': null,
          'target_fact': null,
          'limitations': <Object>[],
        },
    ],
  });
}

String _differentMeaningResponse(Map<String, dynamic> payload) {
  final List<dynamic> routes = payload['routes'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'route_audits': <Object>[
      for (final dynamic rawRoute in routes)
        <String, Object?>{
          'route': (rawRoute as Map<String, dynamic>)['route'],
          'judgment': 'DIFFERENT_MEANING',
          'difference_type': 'SPECIFICITY_CHANGE',
          'source_excerpt': rawRoute['source_text'],
          'target_excerpt': rawRoute['translated_text'],
          'source_fact': 'The source names one object class.',
          'target_fact': 'The target names a different object class.',
          'limitations': <Object>[],
        },
    ],
  });
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

final class _FrameData {
  const _FrameData({
    required this.route,
    required this.concepts,
    required this.specificity,
  });

  final String route;
  final List<String> concepts;
  final String specificity;

  _FrameData withSpecificity(String value) {
    return _FrameData(route: route, concepts: concepts, specificity: value);
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'route': route,
      'core_concepts': concepts,
      'specificity': specificity,
      'attributes': <Object>[],
      'negation': 'NOT_APPLICABLE',
      'modality': 'NOT_APPLICABLE',
      'quantities': <Object>[],
      'time_references': <Object>[],
      'conditions': <Object>[],
      'actors': <Object>[],
      'objects': concepts,
      'directions': <Object>[],
      'causes': <Object>[],
      'restrictions': <Object>[],
      'ambiguities': <Object>[],
    };
  }
}
