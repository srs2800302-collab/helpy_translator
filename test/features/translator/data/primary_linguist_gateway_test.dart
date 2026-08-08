import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_chat_client.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_config.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_gateway.dart';
import 'package:helpy_translator/features/translator/domain/entities/primary_linguist_report.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route_result.dart';
import 'package:helpy_translator/features/translator/domain/errors/translator_exception.dart';

void main() {
  const TyphoonTranslatorConfig config = TyphoonTranslatorConfig();

  test('linguist payload contains original and primary routes only', () async {
    int requestCount = 0;
    late Map<String, dynamic> payload;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;

      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;

      final List<dynamic> messages = body['messages'] as List<dynamic>;

      payload =
          jsonDecode((messages[1] as Map<String, dynamic>)['content'] as String)
              as Map<String, dynamic>;

      return _chatResponse(
        jsonEncode(<String, Object>{
          'assessments': <Object>[
            _compatible('RU_TO_EN', 'EN'),
            _compatible('RU_TO_TH', 'TH'),
          ],
        }),
      );
    });

    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );

    addTearDown(gateway.close);

    final PrimaryLinguistReport report = await gateway
        .evaluatePrimaryTranslations(
          apiKey: 'secret',
          originalSourceText: 'мастер может приехать завтра',
          originalSourceLanguage: TranslationLanguage.russian,
          primaryRoutes: _russianPrimaries,
        );

    expect(requestCount, 1);
    expect(report.assessments, hasLength(2));

    expect(payload.keys.toSet(), <String>{
      'original_source_language',
      'original_source_text',
      'primary_routes',
    });

    final String serialized = jsonEncode(payload);

    expect(serialized, contains('RU_TO_EN'));
    expect(serialized, contains('RU_TO_TH'));

    expect(serialized, isNot(contains('EN_TO_RU')));
    expect(serialized, isNot(contains('EN_TO_TH')));
    expect(serialized, isNot(contains('TH_TO_RU')));
    expect(serialized, isNot(contains('TH_TO_EN')));

    expect(serialized, isNot(contains('observations')));
  });

  test('linguist prompt requires positive semantic equivalence', () async {
    int requestCount = 0;
    late String systemPrompt;

    final MockClient httpClient = MockClient((http.Request request) async {
      requestCount += 1;

      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;

      final List<dynamic> messages = body['messages'] as List<dynamic>;

      systemPrompt = (messages[0] as Map<String, dynamic>)['content'] as String;

      return _chatResponse(
        jsonEncode(<String, Object>{
          'assessments': <Object>[
            _compatible('RU_TO_EN', 'EN'),
            _compatible('RU_TO_TH', 'TH'),
          ],
        }),
      );
    });

    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );

    addTearDown(gateway.close);

    await gateway.evaluatePrimaryTranslations(
      apiKey: 'secret',
      originalSourceText: 'мастер может приехать завтра',
      originalSourceLanguage: TranslationLanguage.russian,
      primaryRoutes: _russianPrimaries,
    );

    expect(requestCount, 1);

    expect(
      systemPrompt,
      contains('COMPATIBLE is a positive equivalence claim'),
    );

    expect(
      systemPrompt,
      contains(
        'different real-world referent, object category, action, participant',
      ),
    );

    expect(systemPrompt, contains('use UNRESOLVED rather than COMPATIBLE'));

    expect(systemPrompt, isNot(contains('cooktop')));
    expect(systemPrompt, isNot(contains('oven')));
    expect(systemPrompt, isNot(contains('варочная панель')));
    expect(systemPrompt, isNot(contains('เตาอบ')));
  });

  test('grounded incompatible evidence is accepted', () async {
    final MockClient httpClient = MockClient((http.Request request) async {
      return _chatResponse(
        jsonEncode(<String, Object>{
          'assessments': <Object>[
            _compatible('RU_TO_EN', 'EN'),
            <String, Object?>{
              'route': 'RU_TO_TH',
              'target_language': 'TH',
              'status': 'INCOMPATIBLE',
              'source_excerpt': 'мастер',
              'target_excerpt': 'ครู',
              'limitations': <Object>[],
            },
          ],
        }),
      );
    });

    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );

    addTearDown(gateway.close);

    final PrimaryLinguistReport report = await gateway
        .evaluatePrimaryTranslations(
          apiKey: 'secret',
          originalSourceText: 'мастер может приехать завтра',
          originalSourceLanguage: TranslationLanguage.russian,
          primaryRoutes: <TranslationRouteResult>[
            _russianPrimaries[0],
            TranslationRouteResult(
              route: _russianPrimaries[1].route,
              sourceText: 'мастер может приехать завтра',
              translatedText: 'ครูสามารถมาได้พรุ่งนี้',
            ),
          ],
        );

    final PrimaryLinguistAssessment assessment = report.assessments[1];

    expect(assessment.status, PrimaryLinguistStatus.incompatible);
    expect(assessment.sourceExcerpt, 'мастер');
    expect(assessment.targetExcerpt, 'ครู');
  });

  test('ungrounded incompatible evidence is rejected', () async {
    final MockClient httpClient = MockClient((http.Request request) async {
      return _chatResponse(
        jsonEncode(<String, Object>{
          'assessments': <Object>[
            _compatible('RU_TO_EN', 'EN'),
            <String, Object?>{
              'route': 'RU_TO_TH',
              'target_language': 'TH',
              'status': 'INCOMPATIBLE',
              'source_excerpt': 'absent-source',
              'target_excerpt': 'ช่าง',
              'limitations': <Object>[],
            },
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
      gateway.evaluatePrimaryTranslations(
        apiKey: 'secret',
        originalSourceText: 'мастер может приехать завтра',
        originalSourceLanguage: TranslationLanguage.russian,
        primaryRoutes: _russianPrimaries,
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

  test('unresolved evidence preserves typed limitation', () async {
    final MockClient httpClient = MockClient((http.Request request) async {
      return _chatResponse(
        jsonEncode(<String, Object>{
          'assessments': <Object>[
            _compatible('RU_TO_EN', 'EN'),
            <String, Object?>{
              'route': 'RU_TO_TH',
              'target_language': 'TH',
              'status': 'UNRESOLVED',
              'source_excerpt': null,
              'target_excerpt': null,
              'limitations': <Object>['CROSS_LANGUAGE_EQUIVALENCE_UNCERTAIN'],
            },
          ],
        }),
      );
    });

    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: TyphoonChatClient(config: config, httpClient: httpClient),
      config: config,
    );

    addTearDown(gateway.close);

    final PrimaryLinguistReport report = await gateway
        .evaluatePrimaryTranslations(
          apiKey: 'secret',
          originalSourceText: 'мастер может приехать завтра',
          originalSourceLanguage: TranslationLanguage.russian,
          primaryRoutes: _russianPrimaries,
        );

    expect(report.assessments[1].status, PrimaryLinguistStatus.unresolved);

    expect(report.limitations, <String>[
      'CROSS_LANGUAGE_EQUIVALENCE_UNCERTAIN',
    ]);
  });
}

const List<TranslationRouteResult> _russianPrimaries = <TranslationRouteResult>[
  TranslationRouteResult(
    route: TranslationRoute(
      source: TranslationLanguage.russian,
      target: TranslationLanguage.english,
      role: TranslationRouteRole.primary,
    ),
    sourceText: 'мастер может приехать завтра',
    translatedText: 'The master can come tomorrow',
  ),
  TranslationRouteResult(
    route: TranslationRoute(
      source: TranslationLanguage.russian,
      target: TranslationLanguage.thai,
      role: TranslationRouteRole.primary,
    ),
    sourceText: 'мастер может приехать завтра',
    translatedText: 'ช่างสามารถมาได้พรุ่งนี้',
  ),
];

Map<String, Object?> _compatible(String route, String targetLanguage) {
  return <String, Object?>{
    'route': route,
    'target_language': targetLanguage,
    'status': 'COMPATIBLE',
    'source_excerpt': null,
    'target_excerpt': null,
    'limitations': <Object>[],
  };
}

http.Response _chatResponse(String content) {
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
