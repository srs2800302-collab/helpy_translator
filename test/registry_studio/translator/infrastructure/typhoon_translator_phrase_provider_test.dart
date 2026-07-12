import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/core/config/app_config.dart';
import 'package:helpy_translator/core/network/api_client.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/typhoon_translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  group('TyphoonTranslatorPhraseProvider', () {
    test('performs two requests and maps the validated result', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[_completeTranslationContent, _exactAuditContent],
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
      expect(result.comment, contains('Полное смысловое совпадение.'));

      expect(requests, hasLength(2));
      expect(
        requests.map<String>((RequestOptions request) => request.path),
        everyElement('/chat/completions'),
      );
      expect(
        requests.map<Object?>(
          (RequestOptions request) => _payload(request)['model'],
        ),
        everyElement(_testTyphoonModel),
      );
      expect(
        requests.map<Object?>(
          (RequestOptions request) =>
              _payload(request)['max_completion_tokens'],
        ),
        <Object?>[700, 500],
      );

      for (final RequestOptions request in requests) {
        expect(_payload(request)['temperature'], 0.0);
        expect(_payload(request)['top_p'], 1.0);
        expect(_payload(request)['frequency_penalty'], 0.0);
        _expectNoDirectionSymbols(_systemContent(request));
      }

      final String translationInput = _userContent(requests.first);
      expect(translationInput, contains('Source text:\n"Check wording."'));
      expect(translationInput, contains('SOURCE LANGUAGE HINT:\nen'));
      expect(
        translationInput,
        contains('ENGINEER CONTEXT:\nRegistry wording review.'),
      );

      expect(
        _systemContent(requests.first),
        contains('You are Helpy strict multilingual translator.'),
      );
      expect(
        _systemContent(requests.first),
        contains('Then perform cross-language reverse translations.'),
      );

      expect(_userContent(requests.last), _completeTranslationContent.trim());
      expect(
        _userContent(requests.last),
        isNot(contains('SOURCE LANGUAGE HINT')),
      );
      expect(_userContent(requests.last), isNot(contains('ENGINEER CONTEXT')));
    });

    test(
      'accepts technical preamble before complete translation sections',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[
            '''
Конечно, вот полный перевод.

$_completeTranslationContent
''',
            _exactAuditContent,
          ],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: 'Check wording.',
        );

        expect(result.status, TranslatorPhraseStatus.exact);
        expect(result.sourceLanguage, 'EN');
        expect(result.sourceText, 'Check wording.');
        expect(result.enToRu, 'Проверить формулировку.');
        expect(result.enToTh, 'ตรวจสอบข้อความ');
        expect(result.thToRu, 'Проверить текст.');
        expect(result.thToEn, 'Check the text.');
        expect(
          result.comment,
          contains(
            'Ответ перевода Typhoon содержит технический текст '
            'до первой обязательной секции',
          ),
        );
        expect(result.comment, contains('Конечно, вот полный перевод.'));
        expect(result.comment, contains('Полное смысловое совпадение.'));
        expect(requests, hasLength(2));
      },
    );

    test('maps audit drift to canonicalDrift status', () async {
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[_completeTranslationContent, _driftAuditContent],
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.canonicalDrift);
      expect(result.comment, contains('Смысл изменён.'));
    });

    final Map<String, String> invalidTranslationResponses = <String, String>{
      'rejects a missing translation section': _completeTranslationContent
          .replaceFirst('\n\nTH_TO_EN:\nCheck the text.', ''),
      'rejects an empty translation section': _completeTranslationContent
          .replaceFirst('EN_TO_RU:\nПроверить формулировку.', 'EN_TO_RU:'),
      'rejects a duplicated translation section':
          '$_completeTranslationContent\n\nTH_TO_EN:\nDuplicate.',
      'rejects an unexpected translation section':
          '$_completeTranslationContent\n\nEXTRA:\nUnexpected.',
      'rejects reordered translation sections':
          _reorderedCompleteTranslationContent,
      'rejects a placeholder translation value': _completeTranslationContent
          .replaceFirst('TH_TO_EN:\nCheck the text.', 'TH_TO_EN:\nN/A'),
    };

    for (final MapEntry<String, String> entry
        in invalidTranslationResponses.entries) {
      test(entry.key, () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[entry.value],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: 'Check wording.',
          sourceLanguageHint: 'en',
        );

        expect(result.status, TranslatorPhraseStatus.failed);
        expect(result.comment, isNotEmpty);
        expect(requests, hasLength(1));
      });
    }

    test('rejects an unsupported source language as failed', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[
          _completeTranslationContent.replaceFirst(
            'SOURCE LANGUAGE:\nEN',
            'SOURCE LANGUAGE:\nDE',
          ),
        ],
        requests: requests,
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.failed);
      expect(result.sourceLanguage, 'DE');
      expect(result.sourceText, 'Check wording.');
      expect(result.ru, 'Проверить формулировку.');
      expect(result.en, 'Check wording.');
      expect(result.th, 'ตรวจสอบข้อความ');
      expect(requests, hasLength(1));
    });

    test(
      'preserves changed SOURCE TEXT and classifies it as canonicalDrift',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[
            _completeTranslationContent.replaceFirst(
              'SOURCE TEXT:\nCheck wording.',
              'SOURCE TEXT:\nChanged wording.',
            ),
            _exactAuditContent,
          ],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: 'Check wording.',
        );

        expect(result.status, TranslatorPhraseStatus.canonicalDrift);
        expect(result.sourceLanguage, 'EN');
        expect(result.sourceText, 'Changed wording.');
        expect(result.ru, 'Проверить формулировку.');
        expect(result.en, 'Check wording.');
        expect(result.th, 'ตรวจสอบข้อความ');
        expect(result.enToRu, 'Проверить формулировку.');
        expect(result.thToRu, 'Проверить текст.');
        expect(result.enToTh, 'ตรวจสอบข้อความ');
        expect(result.thToEn, 'Check the text.');
        expect(result.comment, contains('Переданный исходный текст:'));
        expect(result.comment, contains('Check wording.'));
        expect(result.comment, contains('SOURCE TEXT из ответа Typhoon:'));
        expect(result.comment, contains('Changed wording.'));
        expect(result.comment, contains('Полное смысловое совпадение.'));
        expect(requests, hasLength(2));
      },
    );

    test('preserves mismatch evidence when a later audit fails', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[
          _completeTranslationContent.replaceFirst(
            'SOURCE TEXT:\nCheck wording.',
            'SOURCE TEXT:\nChanged wording.',
          ),
          _exactAuditContent.replaceFirst(
            'MEANING_PRESERVED:\nYES',
            'MEANING_PRESERVED:\nMAYBE',
          ),
        ],
        requests: requests,
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.failed);
      expect(result.sourceLanguage, 'EN');
      expect(result.sourceText, 'Changed wording.');
      expect(result.ru, 'Проверить формулировку.');
      expect(result.en, 'Check wording.');
      expect(result.th, 'ตรวจสอบข้อความ');
      expect(result.enToRu, 'Проверить формулировку.');
      expect(result.thToRu, 'Проверить текст.');
      expect(result.enToTh, 'ตรวจสอบข้อความ');
      expect(result.thToEn, 'Check the text.');
      expect(result.comment, contains('Переданный исходный текст:'));
      expect(result.comment, contains('Check wording.'));
      expect(result.comment, contains('SOURCE TEXT из ответа Typhoon:'));
      expect(result.comment, contains('Changed wording.'));
      expect(result.comment, contains('должна содержать только YES или NO'));
      expect(requests, hasLength(2));
    });

    test(
      'preserves changed source-language section and classifies drift',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[
            _completeTranslationContent.replaceFirst(
              'EN:\nCheck wording.',
              'EN:\nChanged wording.',
            ),
            _exactAuditContent,
          ],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: 'Check wording.',
        );

        expect(result.status, TranslatorPhraseStatus.canonicalDrift);
        expect(result.sourceText, 'Check wording.');
        expect(result.en, 'Changed wording.');
        expect(
          result.comment,
          contains('Секция исходного языка EN из ответа Typhoon:'),
        );
        expect(result.comment, contains('Changed wording.'));
        expect(result.comment, contains('Полное смысловое совпадение.'));
        expect(requests, hasLength(2));
      },
    );

    final Map<String, String> invalidAuditResponses = <String, String>{
      'rejects an incomplete audit': _exactAuditContent.replaceFirst(
        '\n\nREASON:\nПолное смысловое совпадение.',
        '',
      ),
      'rejects a non-binary audit decision': _exactAuditContent.replaceFirst(
        'MEANING_PRESERVED:\nYES',
        'MEANING_PRESERVED:\nMAYBE',
      ),
      'rejects a non-Russian audit reason': _exactAuditContent.replaceFirst(
        'Полное смысловое совпадение.',
        'Exact match.',
      ),
    };

    for (final MapEntry<String, String> entry
        in invalidAuditResponses.entries) {
      test(entry.key, () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[_completeTranslationContent, entry.value],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: 'Check wording.',
        );

        expect(result.status, TranslatorPhraseStatus.failed);
        expect(result.sourceLanguage, 'EN');
        expect(result.sourceText, 'Check wording.');
        expect(result.ru, 'Проверить формулировку.');
        expect(result.en, 'Check wording.');
        expect(result.th, 'ตรวจสอบข้อความ');
        expect(result.enToRu, 'Проверить формулировку.');
        expect(result.thToRu, 'Проверить текст.');
        expect(result.enToTh, 'ตรวจสอบข้อความ');
        expect(result.thToEn, 'Check the text.');
        expect(result.comment, isNotEmpty);
        expect(requests, hasLength(2));
      });
    }

    test('preserves user direction symbols in SOURCE TEXT', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[
          _completeTranslationContent
              .replaceFirst(
                'SOURCE TEXT:\nCheck wording.',
                'SOURCE TEXT:\nCheck -> wording.',
              )
              .replaceFirst('EN:\nCheck wording.', 'EN:\nCheck -> wording.'),
          _exactAuditContent,
        ],
        requests: requests,
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check -> wording.',
      );

      expect(result.status, TranslatorPhraseStatus.exact);
      expect(result.sourceText, 'Check -> wording.');
      expect(result.en, 'Check -> wording.');
      expect(requests, hasLength(2));

      expect(
        _userContent(requests.first),
        contains('Source text:\n"Check -> wording."'),
      );
      expect(
        _userContent(requests.last),
        contains('SOURCE TEXT:\nCheck -> wording.'),
      );

      for (final RequestOptions request in requests) {
        _expectNoDirectionSymbols(_systemContent(request));
      }
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

        if (index >= responses.length) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Unexpected request ${index + 1}.',
            ),
          );
          return;
        }

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

Map<dynamic, dynamic> _payload(RequestOptions request) {
  return request.data as Map<dynamic, dynamic>;
}

List<dynamic> _messages(RequestOptions request) {
  return _payload(request)['messages'] as List<dynamic>;
}

String _systemContent(RequestOptions request) {
  final Map<dynamic, dynamic> message =
      _messages(request).first as Map<dynamic, dynamic>;
  return message['content'] as String;
}

String _userContent(RequestOptions request) {
  final Map<dynamic, dynamic> message =
      _messages(request).last as Map<dynamic, dynamic>;
  return message['content'] as String;
}

void _expectNoDirectionSymbols(String value) {
  for (final String symbol in <String>[
    '->',
    '<-',
    '→',
    '←',
    '⇒',
    '⇐',
    '↔',
    '⇔',
  ]) {
    expect(value, isNot(contains(symbol)), reason: 'Found $symbol');
  }
}

const String _testTyphoonModel = 'test-model';

AppConfig _config() {
  return const AppConfig(
    typhoonApiKey: 'test-key',
    typhoonBaseUrl: 'https://api.example.test/v1',
    typhoonModel: _testTyphoonModel,
  );
}

const String _reorderedCompleteTranslationContent = '''
SOURCE LANGUAGE:
EN

SOURCE TEXT:
Check wording.

EN:
Check wording.

RU:
Проверить формулировку.

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

const String _completeTranslationContent = '''
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
Полное смысловое совпадение.
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
Смысл изменён.
''';
