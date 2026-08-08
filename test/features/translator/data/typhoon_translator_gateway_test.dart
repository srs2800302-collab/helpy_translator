import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_chat_client.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_config.dart';
import 'package:helpy_translator/features/translator/data/network/typhoon_translator_gateway.dart';
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
}

Map<String, dynamic> _userData(http.Request request) {
  final Map<String, dynamic> requestBody =
      jsonDecode(request.body) as Map<String, dynamic>;

  return _userDataFromBody(requestBody);
}

Map<String, dynamic> _userDataFromBody(Map<String, dynamic> requestBody) {
  final List<dynamic> messages = requestBody['messages'] as List<dynamic>;
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
