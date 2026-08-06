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
  test('all blind consensus roles use the live provider model', () {
    const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();

    expect(config.model, 'typhoon-v2.5-30b-a3b-instruct');
  });

  test(
    'blind consensus workflow uses four provider calls for RU EN and TH',
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

        expect(scenario.requestCount, 4);
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
    },
  );

  test(
    'specificity loss is never green for RU EN or TH source language',
    () async {
      const List<_SourceCase> cases = <_SourceCase>[
        _SourceCase(
          text: 'варочная панель',
          selection: SourceLanguageSelection.russian,
        ),
        _SourceCase(
          text: 'cooktop',
          selection: SourceLanguageSelection.english,
        ),
        _SourceCase(text: 'เตาไฟ', selection: SourceLanguageSelection.thai),
      ];

      for (final _SourceCase sourceCase in cases) {
        final _BudgetScenario scenario = await _runScenario(
          sourceText: sourceCase.text,
          sourceLanguageSelection: sourceCase.selection,
          terminologyIssue: true,
        );

        expect(scenario.requestCount, 5);
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
    },
  );
}

Future<_BudgetScenario> _runScenario({
  required String sourceText,
  required SourceLanguageSelection sourceLanguageSelection,
  required bool terminologyIssue,
}) async {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();
  int requestCount = 0;
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

    final String prompt = _systemPrompt(body);
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

    if (prompt.contains('source-side semantic analyst S') ||
        prompt.contains('target-side semantic analyst T')) {
      return _chatResponse(_frameResponse(payload, terminologyIssue));
    }

    if (prompt.contains('blind bilingual pair judge P')) {
      return _chatResponse(_sameMeaningResponse(payload));
    }

    if (prompt.contains('blind conflict judge C')) {
      return _chatResponse(_differentMeaningResponse(payload));
    }

    throw StateError('Unexpected provider payload: ${payload.keys}.');
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

String _frameResponse(Map<String, dynamic> payload, bool terminologyIssue) {
  final List<dynamic> items = payload['items'] as List<dynamic>;

  return jsonEncode(<String, Object>{
    'frames': <Object>[
      for (final dynamic rawItem in items)
        _frame(
          rawItem as Map<String, dynamic>,
          terminologyIssue: terminologyIssue,
        ),
    ],
  });
}

Map<String, Object> _frame(
  Map<String, dynamic> item, {
  required bool terminologyIssue,
}) {
  final String text = item['text'] as String;
  final bool genericStove = terminologyIssue && text == 'เตาไฟ';
  final String concept = terminologyIssue
      ? (genericStove ? 'GENERIC_STOVE' : 'COOKTOP')
      : 'MESSAGE';

  return <String, Object>{
    'route': item['route'] as String,
    'core_concepts': <String>[concept],
    'specificity': terminologyIssue
        ? (genericStove ? 'GENERAL' : 'EXACT_TERM')
        : 'ABSTRACT',
    'attributes': <Object>[],
    'negation': 'NOT_APPLICABLE',
    'modality': 'NOT_APPLICABLE',
    'quantities': <Object>[],
    'time_references': <Object>[],
    'conditions': <Object>[],
    'actors': <Object>[],
    'objects': <String>[concept],
    'directions': <Object>[],
    'causes': <Object>[],
    'restrictions': <Object>[],
    'ambiguities': <Object>[],
  };
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

final class _SourceCase {
  const _SourceCase({required this.text, required this.selection});

  final String text;
  final SourceLanguageSelection selection;
}
