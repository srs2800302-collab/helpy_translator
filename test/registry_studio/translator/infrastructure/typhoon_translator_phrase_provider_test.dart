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
      'performs four isolated requests and maps the validated result',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[
            _directTranslationContent,
            _englishLiteralContent,
            _thaiLiteralContent,
            _exactAuditContent,
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

        expect(requests, hasLength(4));
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
          <Object?>[700, 350, 350, 500],
        );

        final String directInput = _userContent(requests[0]);
        expect(directInput, contains('SOURCE TEXT:\nCheck wording.'));
        expect(directInput, contains('SOURCE LANGUAGE HINT:\nen'));
        expect(
          directInput,
          contains('ENGINEER CONTEXT:\nRegistry wording review.'),
        );

        expect(_userContent(requests[1]), 'EN:\nCheck wording.');
        expect(_userContent(requests[2]), 'TH:\nตรวจสอบข้อความ');
        expect(_userContent(requests[3]), _completeTranslationContent.trim());

        expect(_userContent(requests[1]), isNot(contains('SOURCE TEXT')));
        expect(_userContent(requests[1]), isNot(contains('ENGINEER CONTEXT')));
        expect(_userContent(requests[2]), isNot(contains('SOURCE TEXT')));
        expect(_userContent(requests[2]), isNot(contains('ENGINEER CONTEXT')));
        expect(_userContent(requests[3]), isNot(contains('ENGINEER CONTEXT')));

        for (final RequestOptions request in requests) {
          expect(_systemContent(request), contains(RegExp(r'[А-Яа-яЁё]')));
          _expectNoDirectionSymbols(_systemContent(request));
          _expectNoDirectionSymbols(_userContent(request));
        }
      },
    );

    test('maps audit drift to canonicalDrift status', () async {
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[
          _directTranslationContent,
          _englishLiteralContent,
          _thaiLiteralContent,
          _driftAuditContent,
        ],
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.canonicalDrift);
      expect(result.comment, contains('Смысл изменён.'));
    });

    final Map<String, String> invalidDirectResponses = <String, String>{
      'rejects a missing direct section': _directTranslationContent
          .replaceFirst('\n\nTH:\nตรวจสอบข้อความ', ''),
      'rejects an empty direct section': _directTranslationContent.replaceFirst(
        'RU:\nПроверить формулировку.',
        'RU:',
      ),
      'rejects a duplicated direct section':
          '$_directTranslationContent\n\nEN:\nDuplicate.',
      'rejects an unexpected direct section':
          '$_directTranslationContent\n\nEXTRA:\nUnexpected.',
      'rejects reordered direct sections': _reorderedDirectTranslationContent,
      'rejects a placeholder direct value': _directTranslationContent
          .replaceFirst('RU:\nПроверить формулировку.', 'RU:\nN/A'),
    };

    for (final MapEntry<String, String> entry
        in invalidDirectResponses.entries) {
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
          _directTranslationContent.replaceFirst(
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
            _directTranslationContent.replaceFirst(
              'SOURCE TEXT:\nCheck wording.',
              'SOURCE TEXT:\nChanged wording.',
            ),
            _englishLiteralContent,
            _thaiLiteralContent,
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
        expect(requests, hasLength(4));
      },
    );

    test('preserves mismatch evidence when a later audit fails', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[
          _directTranslationContent.replaceFirst(
            'SOURCE TEXT:\nCheck wording.',
            'SOURCE TEXT:\nChanged wording.',
          ),
          _englishLiteralContent,
          _thaiLiteralContent,
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
      expect(requests, hasLength(4));
    });

    test(
      'preserves changed source-language section and classifies drift',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[
            _directTranslationContent.replaceFirst(
              'EN:\nCheck wording.',
              'EN:\nChanged wording.',
            ),
            _englishLiteralContent,
            _thaiLiteralContent,
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
        expect(requests, hasLength(4));
      },
    );

    test(
      'does not request Thai literal translation or audit after English literal failure',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <String>[
            _directTranslationContent,
            'EN_TO_RU:\nПроверить формулировку.',
          ],
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
        expect(result.enToRu, isNull);
        expect(result.enToTh, isNull);
        expect(result.comment, contains('EN_TO_TH'));
        expect(requests, hasLength(2));
      },
    );

    test('does not request audit after Thai literal failure', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[
          _directTranslationContent,
          _englishLiteralContent,
          _thaiLiteralContent.replaceFirst(
            'TH_TO_EN:\nCheck the text.',
            'TH_TO_EN:\nNOT PROVIDED',
          ),
        ],
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
      expect(result.enToTh, 'ตรวจสอบข้อความ');
      expect(result.thToRu, isNull);
      expect(result.thToEn, isNull);
      expect(result.comment, contains('значение-заглушку'));
      expect(requests, hasLength(3));
    });

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
          responses: <String>[
            _directTranslationContent,
            _englishLiteralContent,
            _thaiLiteralContent,
            entry.value,
          ],
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
        expect(requests, hasLength(4));
      });
    }

    test('preserves user direction symbols in SOURCE TEXT', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <String>[
          _directTranslationWithUserDirectionSymbols,
          _englishLiteralWithUserDirectionSymbols,
          _thaiLiteralContent,
          _exactAuditContent,
        ],
        requests: requests,
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check -> wording.',
      );

      expect(result.status, TranslatorPhraseStatus.exact);
      expect(result.sourceText, 'Check -> wording.');
      expect(_userContent(requests.first), contains('Check -> wording.'));

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

const String _directTranslationContent = '''
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
''';

const String _reorderedDirectTranslationContent = '''
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
''';

const String _englishLiteralContent = '''
EN_TO_RU:
Проверить формулировку.

EN_TO_TH:
ตรวจสอบข้อความ
''';

const String _thaiLiteralContent = '''
TH_TO_RU:
Проверить текст.

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

const String _directTranslationWithUserDirectionSymbols = '''
SOURCE LANGUAGE:
EN

SOURCE TEXT:
Check -> wording.

RU:
Проверить формулировку.

EN:
Check -> wording.

TH:
ตรวจสอบข้อความ
''';

const String _englishLiteralWithUserDirectionSymbols = '''
EN_TO_RU:
Проверить формулировку.

EN_TO_TH:
ตรวจสอบข้อความ
''';
