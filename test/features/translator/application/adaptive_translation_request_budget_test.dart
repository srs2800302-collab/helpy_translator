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
import 'package:helpy_translator/features/translator/domain/entities/translation_matrix_result.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/repositories/translator_api_key_store.dart';
import 'package:helpy_translator/features/translator/domain/services/honesty_assessment_policy.dart';
import 'package:helpy_translator/features/translator/domain/services/source_language_detector.dart';
import 'package:helpy_translator/features/translator/domain/services/translation_route_planner.dart';

void main() {
  test(
    'prototype workflow uses exactly two provider calls for RU EN and TH',
    () async {
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

        expect(scenario.requestCount, 2);
        expect(
          scenario.result.auditCoverage,
          TranslationAuditCoverage.prototype,
        );
        expect(scenario.result.routes, hasLength(6));
        expect(
          scenario.result.assessment.verdict,
          MatrixVerdict.acceptableVariation,
        );
      }
    },
  );

  test('prototype terminology warning still uses exactly two calls', () async {
    final _BudgetScenario scenario = await _runScenario(
      sourceText: 'варочная панель',
      sourceLanguageSelection: SourceLanguageSelection.russian,
      terminologyIssue: true,
    );

    expect(scenario.requestCount, 2);
    expect(scenario.result.routes, hasLength(6));
    expect(scenario.result.assessment.verdict, MatrixVerdict.reviewRequired);
  });
}

Future<_BudgetScenario> _runScenario({
  required String sourceText,
  required SourceLanguageSelection sourceLanguageSelection,
  required bool terminologyIssue,
}) async {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();
  int requestCount = 0;

  final MockClient httpClient = MockClient((http.Request request) async {
    final Map<String, dynamic> userData = _userData(request);
    requestCount += 1;

    if (userData.containsKey('required_routes')) {
      final List<dynamic> requiredRoutes =
          userData['required_routes'] as List<dynamic>;
      final Map<String, String> translations = <String, String>{};

      for (final dynamic rawRoute in requiredRoutes) {
        final Map<String, dynamic> route = rawRoute as Map<String, dynamic>;
        final String routeId = route['route'] as String;
        translations[routeId] = '$routeId-result';
      }

      return _chatResponse(
        jsonEncode(<String, Object>{'translations': translations}),
      );
    }

    if (userData.containsKey('routes')) {
      final List<dynamic> routes = userData['routes'] as List<dynamic>;
      final int problemIndex = routes.indexWhere(
        (dynamic rawRoute) =>
            (rawRoute as Map<String, dynamic>)['role'] == 'primary',
      );

      if (problemIndex < 0) {
        throw StateError('Audit payload contains no primary route.');
      }

      return _chatResponse(
        jsonEncode(<String, Object>{
          'route_audits': <Object>[
            for (int index = 0; index < routes.length; index += 1)
              if (terminologyIssue && index == problemIndex)
                <String, Object?>{
                  'route': (routes[index] as Map<String, dynamic>)['route'],
                  'judgment': 'DIFFERENT_MEANING',
                  'difference': <String, Object?>{
                    'difference_type': 'TERMINOLOGY_CHANGE',
                    'source_excerpt':
                        (routes[index] as Map<String, dynamic>)['source_text'],
                    'target_excerpt':
                        (routes[index]
                            as Map<String, dynamic>)['translated_text'],
                    'source_fact': 'The source uses the required term.',
                    'target_fact': 'The translation uses a broader term.',
                  },
                  'limitations': <Object>[],
                }
              else
                <String, Object?>{
                  'route': (routes[index] as Map<String, dynamic>)['route'],
                  'judgment': 'SAME_MEANING',
                  'difference': null,
                  'limitations': <Object>[],
                },
          ],
        }),
      );
    }

    throw StateError('Unexpected provider payload: ${userData.keys}.');
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
      clock: () => DateTime.utc(2026, 8, 5),
    );

    final TranslationMatrixResult result = await useCase(
      sourceText: sourceText,
      sourceLanguageSelection: sourceLanguageSelection,
      cancellationSignal: TranslatorCancellationSignal(),
      onProgress: (_) {},
    );

    return _BudgetScenario(result: result, requestCount: requestCount);
  } finally {
    gateway.close();
  }
}

Map<String, dynamic> _userData(http.Request request) {
  final Map<String, dynamic> body =
      jsonDecode(request.body) as Map<String, dynamic>;
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

final class _BudgetScenario {
  const _BudgetScenario({required this.result, required this.requestCount});

  final TranslationMatrixResult result;
  final int requestCount;
}

final class _SourceCase {
  const _SourceCase({required this.text, required this.selection});

  final String text;
  final SourceLanguageSelection selection;
}
