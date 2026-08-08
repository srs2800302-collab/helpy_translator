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
import 'package:helpy_translator/features/translator/domain/services/linguist_constraint_policy.dart';
import 'package:helpy_translator/features/translator/domain/services/source_language_detector.dart';
import 'package:helpy_translator/features/translator/domain/services/translation_route_planner.dart';

typedef _SourceCase = ({String text, SourceLanguageSelection selection});

typedef _Scenario = ({
  TranslationMatrixResult result,
  int requestCount,
  int auditCalls,
  int linguistCalls,
});

void main() {
  test(
    'RU EN TH production runs use exactly six translations one audit and one linguist call',
    () async {
      for (final _SourceCase sourceCase in _cases) {
        final _Scenario scenario = await _run(sourceCase: sourceCase);

        expect(scenario.requestCount, 8, reason: sourceCase.selection.name);
        expect(scenario.auditCalls, 1);
        expect(scenario.linguistCalls, 1);
        expect(scenario.result.routes, hasLength(6));
        expect(scenario.result.linguistReport.assessments, hasLength(2));
      }
    },
  );

  test('single audit failure is not retried and total remains eight', () async {
    final _Scenario scenario = await _run(
      sourceCase: _cases.first,
      failAudit: true,
    );

    expect(scenario.requestCount, 8);
    expect(scenario.auditCalls, 1);
    expect(scenario.linguistCalls, 1);
    expect(scenario.result.assessment.verdict, MatrixVerdict.indeterminate);
    expect(
      scenario.result.assessment.limitations,
      contains('AUDIT_PASS_A_PROVIDER_FAILURE'),
    );
  });

  test('linguist failure is not retried and total remains eight', () async {
    final _Scenario scenario = await _run(
      sourceCase: _cases[1],
      failLinguist: true,
    );

    expect(scenario.requestCount, 8);
    expect(scenario.auditCalls, 1);
    expect(scenario.linguistCalls, 1);
    expect(scenario.result.routes, hasLength(6));
    expect(scenario.result.assessment.verdict, MatrixVerdict.indeterminate);
    expect(
      scenario.result.assessment.limitations,
      contains('LINGUIST_PROVIDER_FAILURE'),
    );
  });

  test('grounded Audit A drift cannot become green', () async {
    final _Scenario scenario = await _run(
      sourceCase: _cases.first,
      auditDrift: true,
    );

    expect(scenario.requestCount, 8);
    expect(scenario.auditCalls, 1);
    expect(scenario.linguistCalls, 1);
    expect(scenario.result.assessment.verdict, MatrixVerdict.reviewRequired);
  });

  test('grounded linguist incompatibility cannot become green', () async {
    final _Scenario scenario = await _run(
      sourceCase: _cases.first,
      linguistDrift: true,
    );

    expect(scenario.requestCount, 8);
    expect(scenario.auditCalls, 1);
    expect(scenario.linguistCalls, 1);
    expect(scenario.result.assessment.verdict, MatrixVerdict.reviewRequired);
  });
}

const List<_SourceCase> _cases = <_SourceCase>[
  (
    text: 'мастер может приехать завтра',
    selection: SourceLanguageSelection.russian,
  ),
  (
    text: 'The technician can come tomorrow',
    selection: SourceLanguageSelection.english,
  ),
  (text: 'ช่างสามารถมาได้พรุ่งนี้', selection: SourceLanguageSelection.thai),
];

Future<_Scenario> _run({
  required _SourceCase sourceCase,
  bool failAudit = false,
  bool failLinguist = false,
  bool auditDrift = false,
  bool linguistDrift = false,
}) async {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();

  int requestCount = 0;
  int auditCalls = 0;
  int linguistCalls = 0;

  final MockClient httpClient = MockClient((http.Request request) async {
    requestCount += 1;

    final Map<String, dynamic> body =
        jsonDecode(request.body) as Map<String, dynamic>;

    final Map<String, dynamic> payload = _payload(body);

    if (payload.containsKey('source_language') &&
        payload.containsKey('target_language')) {
      return _chat(
        jsonEncode(<String, Object>{
          'translation': 'translation-$requestCount',
        }),
      );
    }

    if (payload.containsKey('routes')) {
      auditCalls += 1;

      if (failAudit) {
        return http.Response(
          'provider failure',
          503,
          headers: const <String, String>{
            'content-type': 'text/plain; charset=utf-8',
          },
        );
      }

      final List<dynamic> routes = payload['routes'] as List<dynamic>;

      return _chat(
        jsonEncode(<String, Object>{
          'route_audits': <Object>[
            for (int index = 0; index < routes.length; index += 1)
              if (auditDrift && index == 0)
                <String, Object?>{
                  'judgment': 'DIFFERENT_MEANING',
                  'difference': <String, Object?>{
                    'difference_type': 'OBJECT_CHANGE',
                    'source_excerpt':
                        (routes[index] as Map<String, dynamic>)['source_text'],
                    'target_excerpt':
                        (routes[index]
                            as Map<String, dynamic>)['translated_text'],
                  },
                  'limitations': <Object>[],
                }
              else
                <String, Object?>{
                  'judgment': 'SAME_MEANING',
                  'difference': null,
                  'limitations': <Object>[],
                },
          ],
        }),
      );
    }

    if (payload.containsKey('primary_routes')) {
      linguistCalls += 1;

      if (failLinguist) {
        return http.Response(
          'provider failure',
          503,
          headers: const <String, String>{
            'content-type': 'text/plain; charset=utf-8',
          },
        );
      }

      final List<dynamic> routes = payload['primary_routes'] as List<dynamic>;

      return _chat(
        jsonEncode(<String, Object>{
          'assessments': <Object>[
            for (int index = 0; index < routes.length; index += 1)
              if (linguistDrift && index == 0)
                <String, Object?>{
                  'route': (routes[index] as Map<String, dynamic>)['route'],
                  'target_language':
                      (routes[index]
                          as Map<String, dynamic>)['target_language'],
                  'status': 'INCOMPATIBLE',
                  'source_excerpt': sourceCase.text.substring(0, 1),
                  'target_excerpt':
                      ((routes[index]
                                  as Map<String, dynamic>)['translated_text']
                              as String)
                          .substring(0, 1),
                  'limitations': <Object>[],
                }
              else
                <String, Object?>{
                  'route': (routes[index] as Map<String, dynamic>)['route'],
                  'target_language':
                      (routes[index]
                          as Map<String, dynamic>)['target_language'],
                  'status': 'COMPATIBLE',
                  'source_excerpt': null,
                  'target_excerpt': null,
                  'limitations': <Object>[],
                },
          ],
        }),
      );
    }

    throw StateError('Unexpected payload');
  });

  final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
    chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
    config: config,
  );

  try {
    final RunTranslationMatrix useCase = RunTranslationMatrix(
      apiKeyStore: const _ApiKeyStore(),
      gateway: gateway,
      primaryLinguistGateway: gateway,
      languageDetector: const ScriptSourceLanguageDetector(),
      routePlanner: const CompleteThreeLanguageRoutePlanner(),
      assessmentPolicy: const ConservativeHonestyAssessmentPolicy(),
      linguistConstraintPolicy: const ConservativeLinguistConstraintPolicy(),
      clock: () => DateTime.utc(2026, 8, 8),
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
      auditCalls: auditCalls,
      linguistCalls: linguistCalls,
    );
  } finally {
    gateway.close();
  }
}

Map<String, dynamic> _payload(Map<String, dynamic> body) {
  final List<dynamic> messages = body['messages'] as List<dynamic>;

  return jsonDecode((messages[1] as Map<String, dynamic>)['content'] as String)
      as Map<String, dynamic>;
}

http.Response _chat(String content) {
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

final class _ApiKeyStore implements TranslatorApiKeyStore {
  const _ApiKeyStore();

  @override
  Future<String?> read() async => 'secret';

  @override
  Future<void> write(String apiKey) async {}

  @override
  Future<void> delete() async {}
}
