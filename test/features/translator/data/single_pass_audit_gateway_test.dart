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
    'single Audit A uses one request and marks evidence singlePass',
    () async {
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
