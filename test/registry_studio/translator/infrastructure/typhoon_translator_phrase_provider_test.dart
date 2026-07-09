import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/core/config/app_config.dart';
import 'package:helpy_translator/core/network/api_client.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/typhoon_translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  group('TyphoonTranslatorPhraseProvider', () {
    test(
      'maps Typhoon translation and audit responses to phrase result',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[_translationContent, _exactAuditContent],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: ' Check wording. ',
          sourceLanguageHint: ' en ',
          engineerContext: ' Registry wording review. ',
        );

        expect(result.sourceLanguage, 'EN');
        expect(result.sourceText, 'Check wording.');
        expect(result.status, TranslatorPhraseStatus.exact);
        expect(result.ru, 'Проверить формулировку.');
        expect(result.en, 'Check wording.');
        expect(result.th, 'ตรวจสอบข้อความ');
        expect(result.enToRu, 'Проверить формулировку.');
        expect(result.thToRu, 'Проверить текст.');
        expect(result.enToTh, 'ตรวจสอบข้อความ');
        expect(result.thToEn, 'Check the text.');
        expect(result.comment, contains('Meaning preserved: YES'));
        expect(result.comment, contains('Exact match.'));

        expect(requests, hasLength(2));
        expect(requests.first.path, '/chat/completions');

        final Map<dynamic, dynamic> payload =
            requests.first.data as Map<dynamic, dynamic>;
        expect(payload['model'], _testTyphoonModel);

        final List<dynamic> messages = payload['messages'] as List<dynamic>;
        final Map<dynamic, dynamic> userMessage =
            messages.last as Map<dynamic, dynamic>;

        expect(userMessage['content'], contains('SOURCE LANGUAGE HINT:'));
        expect(userMessage['content'], contains('ENGINEER CONTEXT:'));
      },
    );

    test('maps audit drift to canonicalDrift status', () async {
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[_translationContent, _driftAuditContent],
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.canonicalDrift);
      expect(result.comment, contains('Meaning changed.'));
    });

    test('returns failed result on Typhoon API failure', () async {
      final ApiClient apiClient = ApiClient(_config());
      apiClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 401,
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              },
        ),
      );

      final TyphoonTranslatorPhraseProvider provider =
          TyphoonTranslatorPhraseProvider(
            apiClient: apiClient,
            appConfig: _config(),
          );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
        sourceLanguageHint: 'en',
      );

      expect(result.sourceLanguage, 'en');
      expect(result.sourceText, 'Check wording.');
      expect(result.status, TranslatorPhraseStatus.failed);
      expect(result.comment, contains('Ошибка авторизации Typhoon API'));
    });
  });
}

TyphoonTranslatorPhraseProvider _providerWithResponses({
  required List<String> responses,
  List<RequestOptions>? requests,
}) {
  final ApiClient apiClient = ApiClient(_config());
  int index = 0;

  apiClient.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        requests?.add(options);

        final String content = responses[index];
        index++;

        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{
              'choices': <dynamic>[
                <String, dynamic>{
                  'message': <String, dynamic>{'content': content},
                },
              ],
            },
          ),
        );
      },
    ),
  );

  return TyphoonTranslatorPhraseProvider(
    apiClient: apiClient,
    appConfig: _config(),
  );
}

const String _testTyphoonModel = 'test-model';

AppConfig _config() {
  return const AppConfig(
    typhoonApiKey: 'test-key',
    typhoonBaseUrl: 'https://api.example.test/v1',
    typhoonModel: _testTyphoonModel,
  );
}

const String _translationContent = '''
SOURCE LANGUAGE:
EN

SOURCE TEXT:
Check wording.

RU:
Проверить формулировку.

EN:
Check wording.

TH:
ตรวจสอบข้อความ

EN_TO_RU:
Проверить формулировку.

TH_TO_RU:
Проверить текст.

EN_TO_TH:
ตรวจสอบข้อความ

TH_TO_EN:
Check the text.
''';

const String _exactAuditContent = '''
MEANING_PRESERVED:
YES

TERMINOLOGY_PRESERVED:
YES

CANONICAL_STYLE_PRESERVED:
YES

AMBIGUOUS_WORDING:
NO

REASON:
Exact match.
''';

const String _driftAuditContent = '''
MEANING_PRESERVED:
NO

TERMINOLOGY_PRESERVED:
NO

CANONICAL_STYLE_PRESERVED:
NO

AMBIGUOUS_WORDING:
YES

REASON:
Meaning changed.
''';
