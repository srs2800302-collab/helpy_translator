import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/core/config/app_config.dart';
import 'package:helpy_translator/core/network/api_client.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/typhoon_translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  group('TyphoonTranslatorPhraseProvider', () {
    test('performs structured translation and audit requests', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _toolResponse(_completeTranslationArguments),
          _contentResponse(_exactAuditContent),
        ],
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

      expect(
        requests.map<Object?>(
          (RequestOptions request) => _payload(request)['temperature'],
        ),
        <Object?>[0.1, 0.1],
      );

      expect(
        requests.map<Object?>(
          (RequestOptions request) => _payload(request)['top_p'],
        ),
        <Object?>[0.7, 0.7],
      );

      for (final RequestOptions request in requests) {
        expect(_payload(request)['frequency_penalty'], 0.0);
        _expectNoDirectionSymbols(_systemContent(request));
      }

      final Map<dynamic, dynamic> translationPayload = _payload(requests.first);
      final List<dynamic> tools = translationPayload['tools'] as List<dynamic>;
      final Map<dynamic, dynamic> tool = tools.single as Map<dynamic, dynamic>;
      final Map<dynamic, dynamic> function =
          tool['function'] as Map<dynamic, dynamic>;
      final Map<dynamic, dynamic> parameters =
          function['parameters'] as Map<dynamic, dynamic>;

      expect(function['name'], 'submit_translation');
      expect(parameters['additionalProperties'], isFalse);
      expect(parameters['required'], <String>[
        'source_language',
        'source_text',
        'ru',
        'en',
        'th',
        'en_to_ru',
        'th_to_ru',
        'en_to_th',
        'th_to_en',
      ]);
      expect(_payload(requests.last).containsKey('tools'), isFalse);

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
      expect(
        _systemContent(requests.first),
        contains('Call submit_translation exactly once'),
      );

      expect(_userContent(requests.last), _completeTranslationContent.trim());
      expect(
        _userContent(requests.last),
        isNot(contains('SOURCE LANGUAGE HINT')),
      );
      expect(_userContent(requests.last), isNot(contains('ENGINEER CONTEXT')));
    });

    test('rejects a missing translation tool call', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _contentResponse('Ordinary text response.'),
        ],
        requests: requests,
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.failed);
      expect(result.comment, contains('translation tool call'));
      expect(requests, hasLength(1));
    });

    test('rejects an unexpected translation function', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _toolResponse(
            _completeTranslationArguments,
            toolName: 'unexpected_function',
          ),
        ],
        requests: requests,
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.failed);
      expect(result.comment, contains('неожиданную translation function'));
      expect(requests, hasLength(1));
    });

    test('rejects malformed translation tool arguments', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _toolResponse('{"source_language":"EN"'),
        ],
        requests: requests,
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.failed);
      expect(result.comment, contains('некорректный JSON'));
      expect(requests, hasLength(1));
    });

    final Map<String, String> invalidTranslationArguments = <String, String>{
      'rejects a missing translation argument': _completeTranslationArguments
          .replaceFirst(',"th_to_en":"Check the text."', ''),
      'rejects an empty translation argument': _completeTranslationArguments
          .replaceFirst(
            '"en_to_ru":"Проверить формулировку."',
            '"en_to_ru":""',
          ),
      'rejects an unexpected translation argument':
          _completeTranslationArguments.replaceFirst(
            '}',
            ',"extra":"Unexpected"}',
          ),
      'rejects a non-string translation argument': _completeTranslationArguments
          .replaceFirst('"th_to_en":"Check the text."', '"th_to_en":7'),
      'rejects a placeholder translation argument':
          _completeTranslationArguments.replaceFirst(
            '"th_to_en":"Check the text."',
            '"th_to_en":"N/A"',
          ),
    };

    for (final MapEntry<String, String> entry
        in invalidTranslationArguments.entries) {
      test(entry.key, () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[_toolResponse(entry.value)],
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
        responses: <Map<String, dynamic>>[
          _toolResponse(
            _completeTranslationArguments.replaceFirst(
              '"source_language":"EN"',
              '"source_language":"DE"',
            ),
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

    test('maps audit drift to canonicalDrift status', () async {
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _toolResponse(_completeTranslationArguments),
          _contentResponse(_driftAuditContent),
        ],
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.canonicalDrift);
      expect(result.comment, contains('Смысл изменён.'));
    });

    test(
      'preserves changed SOURCE TEXT and classifies canonicalDrift',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[
            _toolResponse(
              _completeTranslationArguments.replaceFirst(
                '"source_text":"Check wording."',
                '"source_text":"Changed wording."',
              ),
            ),
            _contentResponse(_exactAuditContent),
          ],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: 'Check wording.',
        );

        expect(result.status, TranslatorPhraseStatus.canonicalDrift);
        expect(result.sourceLanguage, 'EN');
        expect(result.sourceText, 'Changed wording.');
        expect(result.enToRu, 'Проверить формулировку.');
        expect(result.thToRu, 'Проверить текст.');
        expect(result.comment, contains('Переданный исходный текст:'));
        expect(result.comment, contains('SOURCE TEXT из ответа Typhoon:'));
        expect(result.comment, contains('Changed wording.'));
        expect(requests, hasLength(2));
      },
    );

    test('preserves translation when a later audit fails', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _toolResponse(
            _completeTranslationArguments.replaceFirst(
              '"source_text":"Check wording."',
              '"source_text":"Changed wording."',
            ),
          ),
          _contentResponse(
            _exactAuditContent.replaceFirst(
              'MEANING_PRESERVED:\nYES',
              'MEANING_PRESERVED:\nMAYBE',
            ),
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
      expect(result.enToRu, 'Проверить формулировку.');
      expect(result.thToEn, 'Check the text.');
      expect(result.comment, contains('Переданный исходный текст:'));
      expect(result.comment, contains('должна содержать только YES или NO'));
      expect(requests, hasLength(2));
    });

    test(
      'preserves changed source-language value and classifies drift',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[
            _toolResponse(
              _completeTranslationArguments.replaceFirst(
                '"en":"Check wording."',
                '"en":"Changed wording."',
              ),
            ),
            _contentResponse(_exactAuditContent),
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
          responses: <Map<String, dynamic>>[
            _toolResponse(_completeTranslationArguments),
            _contentResponse(entry.value),
          ],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: 'Check wording.',
        );

        expect(result.status, TranslatorPhraseStatus.failed);
        expect(result.sourceLanguage, 'EN');
        expect(result.sourceText, 'Check wording.');
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
        responses: <Map<String, dynamic>>[
          _toolResponse(
            _completeTranslationArguments
                .replaceFirst(
                  '"source_text":"Check wording."',
                  '"source_text":"Check -> wording."',
                )
                .replaceFirst(
                  '"en":"Check wording."',
                  '"en":"Check -> wording."',
                ),
          ),
          _contentResponse(_exactAuditContent),
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
  required List<Map<String, dynamic>> responses,
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

        final Map<String, dynamic> data = responses[index];
        index++;

        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: data,
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

Map<String, dynamic> _toolResponse(
  String arguments, {
  String toolName = 'submit_translation',
}) {
  return <String, dynamic>{
    'choices': <dynamic>[
      <String, dynamic>{
        'message': <String, dynamic>{
          'tool_calls': <dynamic>[
            <String, dynamic>{
              'type': 'function',
              'function': <String, dynamic>{
                'name': toolName,
                'arguments': arguments,
              },
            },
          ],
        },
      },
    ],
  };
}

Map<String, dynamic> _contentResponse(String content) {
  return <String, dynamic>{
    'choices': <dynamic>[
      <String, dynamic>{
        'message': <String, dynamic>{'content': content},
      },
    ],
  };
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

AppConfig _config() {
  return const AppConfig(
    typhoonApiKey: 'test-key',
    typhoonBaseUrl: 'https://api.example.test/v1',
    typhoonModel: _testTyphoonModel,
  );
}

const String _testTyphoonModel = 'test-model';

const String _completeTranslationArguments =
    '{"source_language":"EN","source_text":"Check wording.",'
    '"ru":"Проверить формулировку.","en":"Check wording.",'
    '"th":"ตรวจสอบข้อความ","en_to_ru":"Проверить формулировку.",'
    '"th_to_ru":"Проверить текст.","en_to_th":"ตรวจสอบข้อความ",'
    '"th_to_en":"Check the text."}';

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
