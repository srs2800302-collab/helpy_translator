import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_provider.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/typhoon/typhoon_translator_provider.dart';

void main() {
  group('DartIoTyphoonChatTransport', () {
    test('writes multilingual JSON as UTF-8', () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final DartIoTyphoonChatTransport transport = DartIoTyphoonChatTransport();

      try {
        final Map<String, Object?> body = <String, Object?>{
          'model': 'test-model',
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'user',
              'content':
                  'Мастер подтверждает прибытие. ผู้เชี่ยวชาญยืนยันการมาถึง',
            },
          ],
        };

        final Future<String> responseFuture = transport.complete(
          endpoint: Uri.parse(
            'http://${server.address.address}:${server.port}/v1/chat/completions',
          ),
          accessKey: 'test-key',
          body: body,
        );

        final HttpRequest request = await server.first;
        expect(request.headers.contentType?.mimeType, 'application/json');
        expect(request.headers.contentType?.charset, 'utf-8');

        final String encodedBody = await utf8.decoder.bind(request).join();
        expect(jsonDecode(encodedBody), body);

        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{'content': 'transport-ok'},
              },
            ],
          }),
        );
        await request.response.close();

        expect(await responseFuture, 'transport-ok');
      } finally {
        transport.close();
        await server.close(force: true);
      }
    });
  });

  group('TyphoonTranslatorProvider', () {
    test(
      'runs atomic translation bundle and findings audit in order',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _translationResponse(),
          _auditResponse(),
        ]);

        final TyphoonTranslatorProvider provider = TyphoonTranslatorProvider(
          policy: const _TestPolicy(),
          transportFactory: () => transport,
        );

        final TranslatorOperation operation = provider.start(
          request: TranslatorWorkRequest(
            sourceText: 'Фотография установленной варочной панели.',
            sourceLanguageHint: TranslationLanguage.ru,
          ),
          accessKey: 'test-key',
        );

        final List<TranslatorRunStage> stages = <TranslatorRunStage>[];
        final Future<void> progressDone = operation.progress.forEach(
          stages.add,
        );

        final TranslatorRunReport report = await operation.result;
        await progressDone;

        expect(stages, <TranslatorRunStage>[
          TranslatorRunStage.directTranslation,
          TranslatorRunStage.audit,
        ]);
        expect(report.bundle.sourceLanguage, TranslationLanguage.ru);
        expect(report.bundle.en, 'Photo of the installed cooktop.');
        expect(report.bundle.thToEn, 'Photo of the installed cooktop.');
        expect(report.audit.verdict, TranslationVerdict.exact);
        expect(transport.callCount, 2);
        expect(transport.requestBodies, hasLength(2));
        expect(
          transport.requestBodies
              .map((Map<String, Object?> body) => body['max_completion_tokens'])
              .toList(growable: false),
          <Object?>[1400, 500],
        );

        expect(
          transport.requestBodies
              .map((Map<String, Object?> body) => body['temperature'])
              .toList(growable: false),
          <Object?>[0.1, 0.0],
        );

        for (final Map<String, Object?> body in transport.requestBodies) {
          expect(body.containsKey('top_p'), isFalse);
          expect(body['frequency_penalty'], 0.0);
          expect(body.containsKey('max_tokens'), isFalse);
        }
      },
    );

    test('maps style-only finding to equivalent', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _auditResponse(style: '- Формулировка EN менее канонична.'),
      ]);

      final TranslatorRunReport report =
          await TyphoonTranslatorProvider(
                policy: const _TestPolicy(),
                transportFactory: () => transport,
              )
              .start(
                request: TranslatorWorkRequest(
                  sourceText: 'Фотография установленной варочной панели.',
                ),
                accessKey: 'test-key',
              )
              .result;

      expect(report.audit.verdict, TranslationVerdict.equivalent);
    });

    test('maps supplied meaning finding to canonical drift', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _auditResponse(meaning: '- В EN изменено обязательство.'),
      ]);
      final TranslatorRunReport report =
          await TyphoonTranslatorProvider(
                policy: const _TestPolicy(),
                transportFactory: () => transport,
              )
              .start(
                request: TranslatorWorkRequest(
                  sourceText: 'Фотография установленной варочной панели.',
                ),
                accessKey: 'test-key',
              )
              .result;
      expect(report.audit.verdict, TranslationVerdict.canonicalDrift);
    });


    test('maps terminology finding to needs review', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _auditResponse(
          terminology: '- Общая роль заменена конкретной профессией.',
        ),
      ]);
      final TranslatorRunReport report =
          await TyphoonTranslatorProvider(
                policy: const _TestPolicy(),
                transportFactory: () => transport,
              )
              .start(
                request: TranslatorWorkRequest(
                  sourceText: 'Фотография установленной варочной панели.',
                ),
                accessKey: 'test-key',
              )
              .result;
      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(report.audit.meaningPreserved, isTrue);
    });

    test('classifies missing translation section as incomplete', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        '''
SOURCE LANGUAGE:
RU

SOURCE TEXT:
Фотография установленной варочной панели.

RU:
Фотография установленной варочной панели.

EN:
Photo of the installed cooktop.

TH:
ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว

EN_TO_RU:
Фотография установленной варочной панели.

TH_TO_RU:
Фотография установленной варочной панели.

EN_TO_TH:
ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว
''',
      ]);

      final Future<TranslatorRunReport> result =
          TyphoonTranslatorProvider(
                policy: const _TestPolicy(),
                transportFactory: () => transport,
              )
              .start(
                request: TranslatorWorkRequest(
                  sourceText: 'Фотография установленной варочной панели.',
                ),
                accessKey: 'test-key',
              )
              .result;

      await expectLater(
        result,
        throwsA(
          isA<TranslatorProviderException>()
              .having(
                (TranslatorProviderException error) =>
                    error.failure.completeness,
                'completeness',
                TranslationCompleteness.translationIncomplete,
              )
              .having(
                (TranslatorProviderException error) => error.failure.stage,
                'stage',
                TranslatorFailureStage.directTranslation,
              ),
        ),
      );
    });

    test('retries malformed audit once and succeeds', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        '''
MEANING_FINDINGS:
NONE

TERMINOLOGY_FINDINGS:
NONE
''',
        _auditResponse(),
      ]);

      final TranslatorRunReport report =
          await TyphoonTranslatorProvider(
                policy: const _TestPolicy(),
                transportFactory: () => transport,
              )
              .start(
                request: TranslatorWorkRequest(
                  sourceText: 'Фотография установленной варочной панели.',
                ),
                accessKey: 'test-key',
              )
              .result;

      expect(report.audit.verdict, TranslationVerdict.exact);
      expect(transport.callCount, 3);
    });

    test(
      'keeps second invalid audit as technical failure with complete bundle',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _translationResponse(),
          '''
MEANING_FINDINGS:
NONE

TERMINOLOGY_FINDINGS:
NONE
''',
          '''
MEANING_FINDINGS:
NONE

TERMINOLOGY_FINDINGS:
NONE
''',
        ]);

        final Future<TranslatorRunReport> result =
            TyphoonTranslatorProvider(
                  policy: const _TestPolicy(),
                  transportFactory: () => transport,
                )
                .start(
                  request: TranslatorWorkRequest(
                    sourceText: 'Фотография установленной варочной панели.',
                  ),
                  accessKey: 'test-key',
                )
                .result;

        await expectLater(
          result,
          throwsA(
            isA<TranslatorProviderException>()
                .having(
                  (TranslatorProviderException error) =>
                      error.failure.completeness,
                  'completeness',
                  TranslationCompleteness.complete,
                )
                .having(
                  (TranslatorProviderException error) => error.failure.code,
                  'code',
                  TranslatorFailureCode.invalidAuditResponse,
                )
                .having(
                  (TranslatorProviderException error) =>
                      error.failure.partialBundle,
                  'partialBundle',
                  isNotNull,
                )
                .having(
                  (TranslatorProviderException error) => error.failure.message,
                  'message',
                  contains('после повторной попытки'),
                ),
          ),
        );

        expect(transport.callCount, 3);
      },
    );

    test(
      'rejects API key with invisible characters before transport',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _translationResponse(),
        ]);

        final Future<TranslatorRunReport> result =
            TyphoonTranslatorProvider(
                  policy: const _TestPolicy(),
                  transportFactory: () => transport,
                )
                .start(
                  request: TranslatorWorkRequest(sourceText: 'Текст.'),
                  accessKey: 'test\u200B-key',
                )
                .result;

        await expectLater(
          result,
          throwsA(
            isA<TranslatorProviderException>()
                .having(
                  (TranslatorProviderException error) => error.failure.stage,
                  'stage',
                  TranslatorFailureStage.validation,
                )
                .having(
                  (TranslatorProviderException error) => error.failure.code,
                  'code',
                  TranslatorFailureCode.accessKeyInvalidCharacters,
                )
                .having(
                  (TranslatorProviderException error) =>
                      error.failure.completeness,
                  'completeness',
                  isNull,
                ),
          ),
        );

        expect(transport.callCount, 0);
      },
    );

    test('keeps invalid source language as technical failure', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        '''
SOURCE LANGUAGE:
XX

SOURCE TEXT:
Текст.

RU:
Текст.

EN:
Text.

TH:
ข้อความ

EN_TO_RU:
Текст.

TH_TO_RU:
Текст.

EN_TO_TH:
ข้อความ

TH_TO_EN:
Text.
''',
      ]);

      final Future<TranslatorRunReport> result =
          TyphoonTranslatorProvider(
                policy: const _TestPolicy(),
                transportFactory: () => transport,
              )
              .start(
                request: TranslatorWorkRequest(sourceText: 'Текст.'),
                accessKey: 'test-key',
              )
              .result;

      await expectLater(
        result,
        throwsA(
          isA<TranslatorProviderException>()
              .having(
                (TranslatorProviderException error) => error.failure.stage,
                'stage',
                TranslatorFailureStage.directTranslation,
              )
              .having(
                (TranslatorProviderException error) => error.failure.code,
                'code',
                TranslatorFailureCode.invalidSourceLanguage,
              )
              .having(
                (TranslatorProviderException error) =>
                    error.failure.completeness,
                'completeness',
                isNull,
              ),
        ),
      );
    });

    test('keeps provider authorization error technical', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        const TyphoonTransportException.http(
          statusCode: 401,
          responseBody: 'unauthorized',
        ),
      ]);

      final Future<TranslatorRunReport> result =
          TyphoonTranslatorProvider(
                policy: const _TestPolicy(),
                transportFactory: () => transport,
              )
              .start(
                request: TranslatorWorkRequest(sourceText: 'Текст.'),
                accessKey: 'invalid',
              )
              .result;

      await expectLater(
        result,
        throwsA(
          isA<TranslatorProviderException>()
              .having(
                (TranslatorProviderException error) => error.failure.code,
                'code',
                TranslatorFailureCode.unauthorized,
              )
              .having(
                (TranslatorProviderException error) =>
                    error.failure.completeness,
                'completeness',
                isNull,
              ),
        ),
      );
    });
  });
}

String _translationResponse({
  String th = 'ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว',
  String thToRu = 'Фотография установленной варочной панели.',
  String thToEn = 'Photo of the installed cooktop.',
}) {
  return '''
SOURCE LANGUAGE:
RU

SOURCE TEXT:
Фотография установленной варочной панели.

RU:
Фотография установленной варочной панели.

EN:
Photo of the installed cooktop.

TH:
$th

EN_TO_RU:
Фотография установленной варочной панели.

TH_TO_RU:
$thToRu

EN_TO_TH:
ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว

TH_TO_EN:
$thToEn
''';
}

String _auditResponse({
  String meaning = 'NONE',
  String terminology = 'NONE',
  String style = 'NONE',
  String ambiguity = 'NONE',
}) {
  return '''
MEANING_FINDINGS:
$meaning

TERMINOLOGY_FINDINGS:
$terminology

STYLE_FINDINGS:
$style

AMBIGUITY_FINDINGS:
$ambiguity
''';
}

final class _QueueTransport implements TyphoonChatTransport {
  _QueueTransport(this.responses);

  final List<Object> responses;
  final List<Map<String, Object?>> requestBodies = <Map<String, Object?>>[];
  int callCount = 0;
  bool cancelled = false;

  @override
  Future<String> complete({
    required Uri endpoint,
    required String accessKey,
    required Map<String, Object?> body,
  }) async {
    callCount += 1;
    requestBodies.add(Map<String, Object?>.unmodifiable(body));
    final Object response = responses.removeAt(0);

    if (response is Exception) {
      throw response;
    }

    return response as String;
  }

  @override
  void cancel() {
    cancelled = true;
  }

  @override
  void close() {}
}

final class _TestPolicy implements TranslatorPolicy {
  const _TestPolicy();

  @override
  String buildDirectSystemPrompt() => 'direct';

  @override
  String buildDirectUserPrompt(TranslatorWorkRequest request) =>
      request.sourceText;

  @override
  String buildAuditSystemPrompt() => 'audit';

  @override
  String buildAuditUserPrompt(TranslationBundle bundle) =>
      bundle.nineSections.toString();
}
