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
      'performs structured content translation and audit requests',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[
            _contentResponse(_completeTranslationContent),
            _contentResponse(_exactAuditContent),
          ],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: ' Check wording. ',
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
        expect(result.comment, contains('Смысловые различия:\nNO_FINDINGS'));
        expect(
          result.comment,
          contains('Терминологические различия:\nNO_FINDINGS'),
        );

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
          expect(_payload(request).containsKey('tools'), isFalse);
          expect(_messages(request), hasLength(2));
          _expectNoDirectionSymbols(_systemContent(request));
        }

        expect(_userContent(requests.first), 'Source text:\nCheck wording.');
        expect(
          _systemContent(requests.first),
          contains('You are Helpy strict multilingual translator.'),
        );
        expect(
          _systemContent(requests.first),
          contains('You must return exactly 9 sections.'),
        );
        expect(
          _systemContent(requests.first),
          contains(
            'Preserve SOURCE TEXT exactly as provided. '
            'Do not add outer quotes.',
          ),
        );
        expect(
          _systemContent(requests.first),
          contains('Output strictly with these exact ASCII labels:'),
        );
        expect(
          _systemContent(requests.first),
          contains('SOURCE LANGUAGE:\nRU | EN | TH'),
        );

        expect(_userContent(requests.last), _completeTranslationContent.trim());
        expect(
          _systemContent(requests.last),
          contains('Ты сначала фиксируешь фактические различия'),
        );
        expect(
          _systemContent(requests.last),
          contains(
            'Обратные переводы не являются доказательством корректности',
          ),
        );
        expect(
          _systemContent(requests.last),
          contains('Ты не выбираешь статус и не выставляешь бинарные значения'),
        );
      },
    );

    test('rejects translation response without sections', () async {
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
      expect(result.comment, contains('не содержит обязательных секций'));
      expect(requests, hasLength(1));
    });

    test('rejects an unexpected translation section', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _contentResponse(
            '${_completeTranslationContent.trim()}\n\nEXTRA:\nUnexpected',
          ),
        ],
        requests: requests,
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.failed);
      expect(result.comment, contains('неожиданную секцию EXTRA'));
      expect(requests, hasLength(1));
    });

    final Map<String, String> invalidTranslationResponses = <String, String>{
      'rejects a missing translation section': _completeTranslationContent
          .replaceFirst('\n\nTH_TO_EN:\nCheck the text.', ''),
      'rejects an empty translation section': _completeTranslationContent
          .replaceFirst('EN_TO_RU:\nПроверить формулировку.', 'EN_TO_RU:\n'),
      'rejects translation sections in the wrong order':
          _completeTranslationContent.replaceFirst(
            'RU:\nПроверить формулировку.\n\nEN:\nCheck wording.',
            'EN:\nCheck wording.\n\nRU:\nПроверить формулировку.',
          ),
      'rejects a duplicated translation section':
          '${_completeTranslationContent.trim()}'
          '\n\nTH_TO_EN:\nDuplicate',
      'rejects a placeholder translation section': _completeTranslationContent
          .replaceFirst('TH_TO_EN:\nCheck the text.', 'TH_TO_EN:\nN/A'),
    };

    for (final MapEntry<String, String> entry
        in invalidTranslationResponses.entries) {
      test(entry.key, () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[_contentResponse(entry.value)],
          requests: requests,
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: 'Check wording.',
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
          _contentResponse(
            _completeTranslationContent.replaceFirst(
              'SOURCE LANGUAGE:\nEN',
              'SOURCE LANGUAGE:\nDE',
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

    test('silently removes one added outer quote pair', () async {
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _contentResponse(
            _completeTranslationContent
                .replaceFirst(
                  'SOURCE TEXT:\nCheck wording.',
                  'SOURCE TEXT:\n"Check wording."',
                )
                .replaceFirst('EN:\nCheck wording.', 'EN:\n"Check wording."'),
          ),
          _contentResponse(_exactAuditContent),
        ],
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.exact);
      expect(result.sourceText, 'Check wording.');
      expect(result.en, 'Check wording.');
      expect(result.comment, isNot(contains('лишнюю внешнюю пару кавычек')));
      expect(result.comment, isNot(contains('Переданный исходный текст:')));
      expect(result.comment, isNot(contains('Секция исходного языка EN')));
    });

    test(
      'preserves intentional outer quotes from the submitted source text',
      () async {
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[
            _contentResponse(
              _completeTranslationContent
                  .replaceFirst(
                    'SOURCE TEXT:\nCheck wording.',
                    'SOURCE TEXT:\n"Check wording."',
                  )
                  .replaceFirst('EN:\nCheck wording.', 'EN:\n"Check wording."'),
            ),
            _contentResponse(_exactAuditContent),
          ],
        );

        final TranslatorPhraseResult result = await provider.translatePhrase(
          sourceText: '"Check wording."',
        );

        expect(result.status, TranslatorPhraseStatus.exact);
        expect(result.sourceText, '"Check wording."');
        expect(result.comment, isNot(contains('лишнюю внешнюю пару кавычек')));
        expect(result.comment, isNot(contains('Переданный исходный текст:')));
        expect(result.comment, isNot(contains('Секция исходного языка EN')));
      },
    );

    test('maps audit drift to canonicalDrift status', () async {
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _contentResponse(_completeTranslationContent),
          _contentResponse(_driftAuditContent),
        ],
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.canonicalDrift);
      expect(result.comment, contains('Meaning preserved: NO'));
      expect(result.comment, contains('Terminology preserved: NO'));
      expect(
        result.comment,
        contains(
          'Смысловые различия:\n'
          'Одна языковая версия обозначает другой объект.',
        ),
      );
      expect(
        result.comment,
        contains(
          'Терминологические различия:\n'
          'Технический термин обозначает другой тип оборудования.',
        ),
      );
    });

    test('derives needsReview from terminology findings', () async {
      final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
        responses: <Map<String, dynamic>>[
          _contentResponse(_completeTranslationContent),
          _contentResponse(_terminologyFindingAuditContent),
        ],
      );

      final TranslatorPhraseResult result = await provider.translatePhrase(
        sourceText: 'Check wording.',
      );

      expect(result.status, TranslatorPhraseStatus.needsReview);
      expect(result.comment, contains('Meaning preserved: YES'));
      expect(result.comment, contains('Terminology preserved: NO'));
      expect(
        result.comment,
        contains(
          'Терминологические различия:\n'
          'Технический термин стал менее точным.',
        ),
      );
    });

    test(
      'preserves changed SOURCE TEXT and classifies canonicalDrift',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[
            _contentResponse(
              _completeTranslationContent.replaceFirst(
                'SOURCE TEXT:\nCheck wording.',
                'SOURCE TEXT:\nChanged wording.',
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
          _contentResponse(
            _completeTranslationContent.replaceFirst(
              'SOURCE TEXT:\nCheck wording.',
              'SOURCE TEXT:\nChanged wording.',
            ),
          ),
          _contentResponse(
            _exactAuditContent.replaceFirst(
              'MEANING_FINDINGS:\nNO_FINDINGS',
              'MEANING_FINDINGS:\nNo meaning differences.',
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
      expect(result.comment, contains('должна содержать NO_FINDINGS'));
      expect(requests, hasLength(2));
    });

    test(
      'preserves changed source-language value and classifies drift',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[
            _contentResponse(
              _completeTranslationContent.replaceFirst(
                'EN:\nCheck wording.',
                'EN:\nChanged wording.',
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
        '\n\nAMBIGUITY_FINDINGS:\nNO_FINDINGS',
        '',
      ),
      'rejects a non-Russian audit finding': _exactAuditContent.replaceFirst(
        'TERMINOLOGY_FINDINGS:\nNO_FINDINGS',
        'TERMINOLOGY_FINDINGS:\nWrong technical term.',
      ),
      'rejects a model-supplied binary override':
          '${_exactAuditContent.trim()}'
          '\n\nMEANING_PRESERVED:\nYES',
    };

    for (final MapEntry<String, String> entry
        in invalidAuditResponses.entries) {
      test(entry.key, () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final TyphoonTranslatorPhraseProvider provider = _providerWithResponses(
          responses: <Map<String, dynamic>>[
            _contentResponse(_completeTranslationContent),
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
          _contentResponse(
            _completeTranslationContent
                .replaceFirst(
                  'SOURCE TEXT:\nCheck wording.',
                  'SOURCE TEXT:\nCheck -> wording.',
                )
                .replaceFirst('EN:\nCheck wording.', 'EN:\nCheck -> wording.'),
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
        contains('Source text:\nCheck -> wording.'),
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
      );

      expect(result.sourceLanguage, 'unknown');
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
MEANING_FINDINGS:
NO_FINDINGS

TERMINOLOGY_FINDINGS:
NO_FINDINGS

STYLE_FINDINGS:
NO_FINDINGS

AMBIGUITY_FINDINGS:
NO_FINDINGS
''';

const String _terminologyFindingAuditContent = '''
MEANING_FINDINGS:
NO_FINDINGS

TERMINOLOGY_FINDINGS:
Технический термин стал менее точным.

STYLE_FINDINGS:
NO_FINDINGS

AMBIGUITY_FINDINGS:
NO_FINDINGS
''';

const String _driftAuditContent = '''
MEANING_FINDINGS:
Одна языковая версия обозначает другой объект.

TERMINOLOGY_FINDINGS:
Технический термин обозначает другой тип оборудования.

STYLE_FINDINGS:
NO_FINDINGS

AMBIGUITY_FINDINGS:
NO_FINDINGS
''';
