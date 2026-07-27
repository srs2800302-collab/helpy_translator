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
            <String, String>{'role': 'user', 'content': 'Русский English ไทย'},
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
    test('runs direct translation and audit only', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _directResponse(),
        _auditResponse(),
      ]);
      final TranslatorRunReport report = await _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: _source),
            accessKey: 'test-key',
          )
          .result;

      expect(report.bundle.sourceLanguage, TranslationLanguage.ru);
      expect(report.bundle.en, _providerEn);
      expect(report.bundle.th, _providerTh);
      expect(report.bundle.reverseTranslations?.enToRu, _reverseRu);
      expect(report.bundle.reverseTranslations?.thToEn, _reverseEn);
      expect(report.audit.verdict, TranslationVerdict.exact);
      expect(transport.callCount, 2);
      expect(transport.bodies, hasLength(2));
    });

    test('emits direct and audit stages in order', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _directResponse(),
        _auditResponse(),
      ]);
      final TranslatorOperation operation = _provider(transport).start(
        request: TranslatorWorkRequest(sourceText: _source),
        accessKey: 'test-key',
      );
      final List<TranslatorRunStage> stages = <TranslatorRunStage>[];
      final Future<void> progressDone = operation.progress.forEach(stages.add);

      await operation.result;
      await progressDone;

      expect(stages, <TranslatorRunStage>[
        TranslatorRunStage.directTranslation,
        TranslatorRunStage.audit,
      ]);
    });

    test(
      'publishes the complete translation bundle before audit ends',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _directResponse(),
          _auditResponse(),
        ]);
        final TranslatorOperation operation = _provider(transport).start(
          request: TranslatorWorkRequest(sourceText: _source),
          accessKey: 'test-key',
        );
        expect(operation, isA<TranslatorPartialBundleOperation>());
        final TranslatorPartialBundleOperation partialOperation =
            operation as TranslatorPartialBundleOperation;
        final List<TranslationBundle> partialBundles = <TranslationBundle>[];
        final Future<void> partialDone = partialOperation.partialBundles
            .forEach(partialBundles.add);

        await operation.result;
        await partialDone;

        expect(partialBundles, hasLength(1));
        expect(partialBundles.single.en, _providerEn);
        expect(partialBundles.single.reverseTranslations, isNotNull);
      },
    );

    test(
      'accepts inline sections and keeps Thai source locally exact',
      () async {
        const String thaiSource =
            'ผู้เชี่ยวชาญต้องยืนยันการมาถึงก่อนเริ่มงานตามคำสั่งซื้อ';
        final _QueueTransport transport = _QueueTransport(<Object>[
          '''
SOURCE LANGUAGE: TH
SOURCE TEXT: ผู้เชี่ยวชาญต้องยืนยันการมาถึงก่อนเริ่มงาน
RU: Специалист должен подтвердить прибытие до начала выполнения заказа.
EN: The professional must confirm arrival before starting the order.
TH: ผู้เชี่ยวชาญต้องยืนยันการมาถึงก่อนเริ่มงาน
EN_TO_RU: Специалист должен подтвердить прибытие до начала заказа.
TH_TO_RU: Специалист должен подтвердить прибытие до начала работы.
EN_TO_TH: ผู้เชี่ยวชาญต้องยืนยันการมาถึงก่อนเริ่มคำสั่งซื้อ
TH_TO_EN: The professional must confirm arrival before starting work.
''',
          _auditResponse(),
        ]);

        final TranslatorRunReport report = await _provider(transport)
            .start(
              request: TranslatorWorkRequest(sourceText: thaiSource),
              accessKey: 'test-key',
            )
            .result;

        expect(report.bundle.sourceLanguage, TranslationLanguage.th);
        expect(report.bundle.sourceText, thaiSource);
        expect(report.bundle.th, thaiSource);
        expect(report.bundle.ru, contains('Специалист'));
        expect(
          report.bundle.reverseTranslations?.thToEn,
          contains('professional'),
        );
        expect(transport.callCount, 2);
      },
    );

    test('keeps provider model and sampling settings unchanged', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _directResponse(),
        _auditResponse(),
      ]);

      await _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: _source),
            accessKey: 'test-key',
          )
          .result;

      expect(transport.bodies.first['model'], 'typhoon-v2.5-30b-a3b-instruct');
      expect(transport.bodies.first['max_tokens'], 1536);
      expect(transport.bodies.last['max_tokens'], 1024);

      for (final Map<String, Object?> body in transport.bodies) {
        expect(body['temperature'], 0.0);
        expect(body['top_p'], 1.0);
      }
    });

    test(
      'preserves direct provider wording without local replacement',
      () async {
        const String unusualEn = 'The master shall acknowledge arrival.';
        const String unusualTh = 'ช่างต้องรับทราบการมาถึง';
        final _QueueTransport transport = _QueueTransport(<Object>[
          _directResponse(en: unusualEn, th: unusualTh),
          _auditResponse(),
        ]);

        final TranslatorRunReport report = await _provider(transport)
            .start(
              request: TranslatorWorkRequest(sourceText: _source),
              accessKey: 'test-key',
            )
            .result;

        expect(report.bundle.en, unusualEn);
        expect(report.bundle.th, unusualTh);
        expect(report.bundle.en, isNot(_providerEn));
      },
    );

    test('maps style-only finding to equivalent', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _directResponse(),
        _auditResponse(style: '- EN читается неестественно.'),
      ]);

      final TranslatorRunReport report = await _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: _source),
            accessKey: 'test-key',
          )
          .result;

      expect(report.audit.verdict, TranslationVerdict.equivalent);
    });

    test(
      'maps terminology finding to needs review before dictionary',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _directResponse(),
          _auditResponse(
            terminology: '- EN необоснованно сужает роль до профессии.',
          ),
        ]);

        final TranslatorRunReport report = await _provider(transport)
            .start(
              request: TranslatorWorkRequest(sourceText: _source),
              accessKey: 'test-key',
            )
            .result;

        expect(report.audit.verdict, TranslationVerdict.needsReview);
        expect(report.audit.verdict, isNot(TranslationVerdict.canonicalDrift));
      },
    );

    test('classifies missing direct section as incomplete', () async {
      const String malformed =
          '''
SOURCE LANGUAGE:
RU

SOURCE TEXT:
$_source

RU:
$_source

EN:
$_providerEn
''';
      final _QueueTransport transport = _QueueTransport(<Object>[
        malformed,
        malformed,
      ]);

      final Future<TranslatorRunReport> result = _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: _source),
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

    test('retries malformed direct response once and succeeds', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        'SOURCE LANGUAGE:\nRU',
        _directResponse(),
        _auditResponse(),
      ]);

      final TranslatorRunReport report = await _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: _source),
            accessKey: 'test-key',
          )
          .result;

      expect(report.bundle.en, _providerEn);
      expect(report.bundle.reverseTranslations, isNotNull);
      expect(transport.callCount, 3);
      expect(transport.bodies.first['max_tokens'], 1536);
      expect(transport.bodies[1]['max_tokens'], 1536);
    });

    test('keeps the local multiline source text authoritative', () async {
      const String exactSource =
          '  Registry:\n'
          '- Preserve the historical order.\n'
          '- Keep SOURCE TEXT: as user content.  ';
      final _QueueTransport transport = _QueueTransport(<Object>[
        '''
SOURCE LANGUAGE:
EN

SOURCE TEXT:
Registry:
RU:
SOURCE TEXT:
- Preserve the historical order.

RU:
Сохраняйте исторический порядок.

EN:
Registry: Preserve the historical order.

TH:
คงลำดับตามประวัติ

EN_TO_RU:
Сохраняйте исторический порядок.

TH_TO_RU:
Сохраняйте исторический порядок.

EN_TO_TH:
คงลำดับตามประวัติ

TH_TO_EN:
Preserve the historical order.
''',
        _auditResponse(),
      ]);

      final TranslatorRunReport report = await _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: exactSource),
            accessKey: 'test-key',
          )
          .result;

      expect(report.request.sourceText, exactSource);
      expect(report.bundle.sourceText, exactSource);
      expect(report.bundle.en, exactSource);
      expect(report.bundle.ru, 'Сохраняйте исторический порядок.');
    });

    test('retries malformed audit once and succeeds', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _directResponse(),
        'MEANING_FINDINGS:\nNONE',
        _auditResponse(),
      ]);

      final TranslatorRunReport report = await _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: _source),
            accessKey: 'test-key',
          )
          .result;

      expect(report.audit.verdict, TranslationVerdict.exact);
      expect(transport.callCount, 3);
      expect(transport.bodies.last['max_tokens'], 1024);
    });

    test(
      'keeps second invalid audit as failure with complete direct bundle',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _directResponse(),
          'MEANING_FINDINGS:\nNONE',
          'MEANING_FINDINGS:\nNONE',
        ]);

        final Future<TranslatorRunReport> result = _provider(transport)
            .start(
              request: TranslatorWorkRequest(sourceText: _source),
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
                  (TranslatorProviderException error) =>
                      error.failure.partialBundle?.en,
                  'direct provider output',
                  _providerEn,
                )
                .having(
                  (TranslatorProviderException error) => error.failure.code,
                  'code',
                  TranslatorFailureCode.invalidAuditResponse,
                ),
          ),
        );
        expect(transport.callCount, 3);
      },
    );

    test('rejects invisible API-key characters before transport', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _directResponse(),
      ]);

      final Future<TranslatorRunReport> result = _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: 'Текст.'),
            accessKey: 'test\u200B-key',
          )
          .result;

      await expectLater(
        result,
        throwsA(
          isA<TranslatorProviderException>().having(
            (TranslatorProviderException error) => error.failure.code,
            'code',
            TranslatorFailureCode.accessKeyInvalidCharacters,
          ),
        ),
      );
      expect(transport.callCount, 0);
    });

    test(
      'keeps invalid detected source language as technical failure',
      () async {
        const String invalidLanguageResponse = '''
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
''';
        final _QueueTransport transport = _QueueTransport(<Object>[
          invalidLanguageResponse,
          invalidLanguageResponse,
        ]);

        final Future<TranslatorRunReport> result = _provider(transport)
            .start(
              request: TranslatorWorkRequest(sourceText: 'Текст.'),
              accessKey: 'test-key',
            )
            .result;

        await expectLater(
          result,
          throwsA(
            isA<TranslatorProviderException>().having(
              (TranslatorProviderException error) => error.failure.code,
              'code',
              TranslatorFailureCode.invalidSourceLanguage,
            ),
          ),
        );
      },
    );

    test('keeps provider authorization error technical', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        const TyphoonTransportException.http(
          statusCode: 401,
          responseBody: '{"error":{"message":"unauthorized"}}',
          responseContentType: 'application/json',
        ),
      ]);

      final Future<TranslatorRunReport> result = _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: 'Текст.'),
            accessKey: 'test-key',
          )
          .result;

      await expectLater(
        result,
        throwsA(
          isA<TranslatorProviderException>().having(
            (TranslatorProviderException error) => error.failure.code,
            'code',
            TranslatorFailureCode.unauthorized,
          ),
        ),
      );
    });

    test('classifies an HTML 403 as a blocked VPN route', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        const TyphoonTransportException.http(
          statusCode: 403,
          responseBody: '<!DOCTYPE html><title>Error 403</title>',
          responseContentType: 'text/html',
        ),
      ]);

      final Future<TranslatorRunReport> result = _provider(transport)
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
                (TranslatorProviderException error) => error.failure.code,
                'code',
                TranslatorFailureCode.networkBlocked,
              )
              .having(
                (TranslatorProviderException error) => error.failure.message,
                'message',
                contains('VPN'),
              ),
        ),
      );
    });

    test('keeps a JSON 403 distinct from an invalid API key', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        const TyphoonTransportException.http(
          statusCode: 403,
          responseBody: '{"error":{"message":"forbidden"}}',
          responseContentType: 'application/json',
        ),
      ]);

      final Future<TranslatorRunReport> result = _provider(transport)
          .start(
            request: TranslatorWorkRequest(sourceText: 'Текст.'),
            accessKey: 'test-key',
          )
          .result;

      await expectLater(
        result,
        throwsA(
          isA<TranslatorProviderException>().having(
            (TranslatorProviderException error) => error.failure.code,
            'code',
            TranslatorFailureCode.accessForbidden,
          ),
        ),
      );
    });

    test(
      'retries semantic audit without repeating direct translation',
      () async {
        final TranslatorWorkRequest request = TranslatorWorkRequest(
          sourceText: _source,
        );
        final _QueueTransport directTransport = _QueueTransport(<Object>[
          _directResponse(),
          _auditResponse(),
        ]);
        final TranslatorRunReport initialReport = await _provider(
          directTransport,
        ).start(request: request, accessKey: 'test-key').result;

        final _QueueTransport auditTransport = _QueueTransport(<Object>[
          _auditResponse(style: '- Требуется инженерная проверка стиля.'),
        ]);
        final TranslatorRunReport retried = await _provider(auditTransport)
            .startAudit(
              request: request,
              bundle: initialReport.bundle,
              accessKey: 'test-key',
            )
            .result;

        expect(auditTransport.callCount, 1);
        expect(auditTransport.bodies.single['max_tokens'], 1024);
        expect(retried.bundle, initialReport.bundle);
        expect(retried.audit.verdict, TranslationVerdict.equivalent);
      },
    );
  });
}

const String _source =
    'Мастер должен подтвердить прибытие до начала выполнения заказа';
const String _providerEn =
    'The service professional must confirm arrival before starting the job';
const String _providerTh = 'ผู้ให้บริการต้องยืนยันการมาถึงก่อนเริ่มงาน';
const String _reverseRu =
    'Специалист по услугам должен подтвердить прибытие до начала работы';
const String _reverseTh = 'ผู้ให้บริการต้องยืนยันการมาถึงก่อนเริ่มงาน';
const String _reverseEn =
    'The service provider must confirm arrival before starting work';

TyphoonTranslatorProvider _provider(_QueueTransport transport) {
  return TyphoonTranslatorProvider(
    policy: const _TestPolicy(),
    transportFactory: () => transport,
  );
}

String _directResponse({String en = _providerEn, String th = _providerTh}) {
  return '''
SOURCE LANGUAGE:
RU

SOURCE TEXT:
$_source

RU:
$_source

EN:
$en

TH:
$th

EN_TO_RU:
$_reverseRu

TH_TO_RU:
$_reverseRu

EN_TO_TH:
$_reverseTh

TH_TO_EN:
$_reverseEn
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
  final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];
  int callCount = 0;

  @override
  Future<String> complete({
    required Uri endpoint,
    required String accessKey,
    required Map<String, Object?> body,
  }) async {
    callCount += 1;
    bodies.add(body);
    final Object response = responses.removeAt(0);

    if (response is Exception) {
      throw response;
    }

    return response as String;
  }

  @override
  void cancel() {}

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
      bundle.directSections.toString();
}
