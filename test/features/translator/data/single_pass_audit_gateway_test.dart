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

void main() {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();

  test(
    'single Audit A sends one route-local request and marks evidence singlePass',
    () async {
      int calls = 0;

      final MockClient client = MockClient((http.Request request) async {
        calls += 1;

        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;

        final List<dynamic> messages = body['messages'] as List<dynamic>;

        final String systemPrompt =
            (messages.first as Map<String, dynamic>)['content'] as String;

        final Map<String, dynamic> payload =
            jsonDecode(
                  (messages[1] as Map<String, dynamic>)['content'] as String,
                )
                as Map<String, dynamic>;

        final List<dynamic> payloadRoutes = payload['routes'] as List<dynamic>;

        expect(payloadRoutes, hasLength(1));
        expect(payload.containsKey('original_source_text'), isFalse);
        expect(
          systemPrompt,
          contains('exactly one translation route in routes'),
        );
        expect(
          systemPrompt,
          contains(
            "Use only the current route's source_text "
            "and translated_text as semantic evidence",
          ),
        );
        expect(systemPrompt, isNot(contains('sibling primary branches')));

        return _response(
          jsonEncode(<String, Object>{
            'route_audits': <Object>[
              <String, Object?>{
                'judgment': 'SAME_MEANING',
                'difference': null,
                'limitations': <Object>[],
              },
            ],
          }),
        );
      });

      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: client),
        config: config,
      );

      addTearDown(gateway.close);

      final report = await gateway.auditMatrixSinglePass(
        apiKey: 'secret',
        originalSourceText: 'source',
        originalSourceLanguage: TranslationLanguage.english,
        routes: _routes,
      );

      expect(calls, 1);
      expect(report.limitations, isEmpty);
      expect(report.observations, hasLength(1));
      expect(
        report.observations.single.verificationStatus,
        ObservationVerificationStatus.singlePass,
      );
      expect(
        report.observations.single.preservation,
        MeaningPreservation.preserved,
      );
    },
  );

  test(
    'invalid route response is retried once without sharing sibling routes',
    () async {
      int calls = 0;

      final List<String> requestedSources = <String>[];

      final List<TranslationRouteResult> routes = <TranslationRouteResult>[
        const TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.english,
            target: TranslationLanguage.thai,
            role: TranslationRouteRole.primary,
          ),
          sourceText: 'source A',
          translatedText: 'target A',
        ),
        const TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.english,
            target: TranslationLanguage.russian,
            role: TranslationRouteRole.crossCheck,
          ),
          sourceText: 'source B',
          translatedText: 'target B',
        ),
      ];

      final MockClient client = MockClient((http.Request request) async {
        calls += 1;

        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;

        final List<dynamic> messages = body['messages'] as List<dynamic>;

        final Map<String, dynamic> payload =
            jsonDecode(
                  (messages[1] as Map<String, dynamic>)['content'] as String,
                )
                as Map<String, dynamic>;

        final List<dynamic> payloadRoutes = payload['routes'] as List<dynamic>;

        expect(payloadRoutes, hasLength(1));
        expect(payload.containsKey('original_source_text'), isFalse);

        final String sourceText =
            (payloadRoutes.single as Map<String, dynamic>)['source_text']
                as String;

        requestedSources.add(sourceText);

        if (calls == 1) {
          expect(sourceText, 'source A');

          return _response(
            jsonEncode(<String, Object>{
              'route_audits': <Object>[
                <String, Object?>{
                  'judgment': 'SAME_MEANING',
                  'difference': null,
                  'limitations': <Object>[],
                  'unexpected_field': true,
                },
              ],
            }),
          );
        }

        if (calls == 2) {
          expect(sourceText, 'source B');

          return _response(
            jsonEncode(<String, Object>{
              'route_audits': <Object>[
                <String, Object?>{
                  'judgment': 'SAME_MEANING',
                  'difference': null,
                  'limitations': <Object>[],
                },
              ],
            }),
          );
        }

        expect(calls, 3);
        expect(sourceText, 'source A');

        return _response(
          jsonEncode(<String, Object>{
            'route_audits': <Object>[
              <String, Object?>{
                'judgment': 'SAME_MEANING',
                'difference': null,
                'limitations': <Object>[],
              },
            ],
          }),
        );
      });

      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: client),
        config: config,
      );

      addTearDown(gateway.close);

      final report = await gateway.auditMatrixSinglePass(
        apiKey: 'secret',
        originalSourceText: 'source A',
        originalSourceLanguage: TranslationLanguage.english,
        routes: routes,
      );

      expect(calls, 3);

      expect(requestedSources, <String>['source A', 'source B', 'source A']);

      expect(report.limitations, isEmpty);
      expect(report.observations, hasLength(2));

      expect(
        report.observations.every(
          (observation) =>
              observation.verificationStatus ==
              ObservationVerificationStatus.singlePass,
        ),
        isTrue,
      );

      expect(
        report.observations.every(
          (observation) =>
              observation.preservation == MeaningPreservation.preserved,
        ),
        isTrue,
      );
    },
  );

  test(
    'ungrounded evidence is retried once and successful retry clears limitation',
    () async {
      int calls = 0;

      final MockClient client = MockClient((http.Request request) async {
        calls += 1;

        if (calls == 1) {
          return _response(
            jsonEncode(<String, Object>{
              'route_audits': <Object>[
                <String, Object?>{
                  'judgment': 'DIFFERENT_MEANING',
                  'difference': <String, Object?>{
                    'difference_type': 'TERMINOLOGY_CHANGE',
                    'source_excerpt': 'not-in-source',
                    'target_excerpt': 'target',
                  },
                  'limitations': <Object>[],
                },
              ],
            }),
          );
        }

        expect(calls, 2);

        return _response(
          jsonEncode(<String, Object>{
            'route_audits': <Object>[
              <String, Object?>{
                'judgment': 'SAME_MEANING',
                'difference': null,
                'limitations': <Object>[],
              },
            ],
          }),
        );
      });

      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: client),
        config: config,
      );

      addTearDown(gateway.close);

      final report = await gateway.auditMatrixSinglePass(
        apiKey: 'secret',
        originalSourceText: 'source',
        originalSourceLanguage: TranslationLanguage.english,
        routes: _routes,
      );

      expect(calls, 2);
      expect(report.limitations, isEmpty);
      expect(
        report.observations.single.preservation,
        MeaningPreservation.preserved,
      );
      expect(
        report.observations.single.verificationStatus,
        ObservationVerificationStatus.singlePass,
      );
    },
  );

  test('failed corrective retry stops after one additional request', () async {
    int calls = 0;

    final MockClient client = MockClient((http.Request request) async {
      calls += 1;

      return _response(
        jsonEncode(<String, Object>{
          'route_audits': <Object>[
            <String, Object?>{
              'judgment': 'SAME_MEANING',
              'difference': null,
              'limitations': <Object>[],
              'unexpected_field': true,
            },
          ],
        }),
      );
    });

    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: client),
      config: config,
    );

    addTearDown(gateway.close);

    final report = await gateway.auditMatrixSinglePass(
      apiKey: 'secret',
      originalSourceText: 'source',
      originalSourceLanguage: TranslationLanguage.english,
      routes: _routes,
    );

    expect(calls, 2);
    expect(report.limitations, contains('AUDIT_RESPONSE_INVALID'));
    expect(
      report.observations.single.verificationStatus,
      ObservationVerificationStatus.unverifiable,
    );
    expect(
      report.observations.single.preservation,
      MeaningPreservation.unknown,
    );
  });

  test(
    'single Audit A provider failure remains truly unverifiable and is not retried',
    () async {
      int calls = 0;

      final MockClient client = MockClient((http.Request request) async {
        calls += 1;

        return http.Response(
          'provider failure',
          503,
          headers: const <String, String>{
            'content-type': 'text/plain; charset=utf-8',
          },
        );
      });

      final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
        chatClient: TyphoonChatClient(config: config, httpClient: client),
        config: config,
      );

      addTearDown(gateway.close);

      final report = await gateway.auditMatrixSinglePass(
        apiKey: 'secret',
        originalSourceText: 'source',
        originalSourceLanguage: TranslationLanguage.english,
        routes: _routes,
      );

      expect(calls, 1);
      expect(report.limitations, contains('AUDIT_PASS_A_PROVIDER_FAILURE'));
      expect(
        report.observations.single.verificationStatus,
        ObservationVerificationStatus.unverifiable,
      );
      expect(
        report.observations.single.preservation,
        MeaningPreservation.unknown,
      );
    },
  );
}

const List<TranslationRouteResult> _routes = <TranslationRouteResult>[
  TranslationRouteResult(
    route: TranslationRoute(
      source: TranslationLanguage.english,
      target: TranslationLanguage.thai,
      role: TranslationRouteRole.primary,
    ),
    sourceText: 'source',
    translatedText: 'target',
  ),
];

http.Response _response(String content) {
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
