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
      'runs direct translation and independent verification in order',
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
          <Object?>[1400, 2200],
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

        final List<Map<String, String>> verificationMessages =
            (transport.requestBodies[1]['messages']! as List<Object?>)
                .cast<Map<String, String>>();
        expect(verificationMessages.last['content'], contains('SOURCE TEXT'));
        expect(verificationMessages.last['content'], contains('RU'));
        expect(verificationMessages.last['content'], contains('EN'));
        expect(verificationMessages.last['content'], contains('TH'));
        expect(
          verificationMessages.last['content'],
          isNot(contains('EN_TO_RU')),
        );
      },
    );

    test('maps style-only finding to equivalent', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _auditResponse(
          findings: <Map<String, Object?>>[
            _structuredFinding(
              category: 'STYLE',
              reason: 'Формулировка EN менее канонична.',
              impact: 'Смысл сохранён, но стиль менее каноничен.',
              correctVariant: 'Использовать каноничную формулировку.',
            ),
          ],
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

      expect(report.audit.verdict, TranslationVerdict.equivalent);
    });

    test('maps supplied meaning finding to canonical drift', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _auditResponse(
          findings: <Map<String, Object?>>[
            _structuredFinding(
              category: 'MEANING',
              reason: 'В EN изменено обязательство.',
              impact: 'Пользователь получает другое обязательство.',
              correctVariant: 'Сохранить исходное обязательство.',
            ),
          ],
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
      expect(report.audit.verdict, TranslationVerdict.canonicalDrift);
    });

    test('maps terminology finding to needs review', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _auditResponse(
          findings: <Map<String, Object?>>[
            _structuredFinding(
              category: 'TERMINOLOGY',
              reason: 'Общая роль заменена конкретной профессией.',
              impact: 'Роль стала уже исходной.',
              correctVariant: 'Сохранить общую роль.',
            ),
          ],
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

    test('fails after one malformed direct protocol repair', () async {
      final String malformed = '''
SOURCE LANGUAGE:
RU

SOURCE TEXT:
Фотография установленной варочной панели.

RU:
Фотография установленной варочной панели.

EN:
Photo of the installed cooktop.
''';
      final _QueueTransport transport = _QueueTransport(<Object>[
        malformed,
        malformed,
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
              )
              .having(
                (TranslatorProviderException error) => error.failure.code,
                'code',
                TranslatorFailureCode.missingRequiredSection,
              )
              .having(
                (TranslatorProviderException error) => error.failure.message,
                'message',
                contains('после повторной попытки'),
              ),
        ),
      );
      expect(transport.callCount, 2);
    });

    test('repairs malformed direct protocol once and then audits', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(th: ''),
        _translationResponse(),
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
      expect(
        transport.requestBodies
            .map((Map<String, Object?> body) => body['max_completion_tokens'])
            .toList(growable: false),
        <Object?>[1400, 1400, 2200],
      );
      expect(
        transport.requestBodies
            .map((Map<String, Object?> body) => body['temperature'])
            .toList(growable: false),
        <Object?>[0.1, 0.1, 0.0],
      );

      final List<Map<String, String>> firstMessages =
          (transport.requestBodies[0]['messages']! as List<Object?>)
              .cast<Map<String, String>>();
      final List<Map<String, String>> retryMessages =
          (transport.requestBodies[1]['messages']! as List<Object?>)
              .cast<Map<String, String>>();

      expect(retryMessages.first['content'], startsWith('direct'));
      expect(retryMessages.first['content'], contains('final format attempt'));
      expect(retryMessages.last['content'], firstMessages.last['content']);
    });

    test('bounds direct and audit protocol repairs independently', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(th: ''),
        _translationResponse(),
        '{"findings":"invalid"}',
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
      expect(transport.callCount, 4);
    });

    test('retries ungrounded structured audit once and succeeds', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _auditResponse(
          findings: <Map<String, Object?>>[
            _structuredFinding(
              category: 'MEANING',
              reason: 'В EN изменён объект.',
              impact: 'Пользователь получает другое указание.',
              correctVariant: 'Сохранить исходный объект.',
              sourceFragment: 'Фрагмент отсутствует',
            ),
          ],
        ),
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
      'rejects malformed multilingual audit fields after one repair',
      () async {
        final List<Map<String, Object?>> malformedFindings =
            <Map<String, Object?>>[
              <String, Object?>{
                ..._structuredFinding(
                  category: 'MEANING',
                  reason: 'Причина.',
                  impact: 'Влияние.',
                  correctVariant: 'Photo of the installed cooktop.',
                ),
                'reason': 'Причина строкой',
              },
              <String, Object?>{
                ..._structuredFinding(
                  category: 'MEANING',
                  reason: 'Причина.',
                  impact: 'Влияние.',
                  correctVariant: 'Photo of the installed cooktop.',
                ),
                'reason': <String, Object?>{'ru': 'Причина.', 'en': 'Reason.'},
              },
              <String, Object?>{
                ..._structuredFinding(
                  category: 'MEANING',
                  reason: 'Причина.',
                  impact: 'Влияние.',
                  correctVariant: 'Photo of the installed cooktop.',
                ),
                'reason': <String, Object?>{
                  'ru': 'Причина.',
                  'en': 'Reason.',
                  'th': 'เหตุผล',
                  'de': 'Grund',
                },
              },
              <String, Object?>{
                ..._structuredFinding(
                  category: 'MEANING',
                  reason: 'Причина.',
                  impact: 'Влияние.',
                  correctVariant: 'Photo of the installed cooktop.',
                ),
                'reason': <String, Object?>{
                  'ru': 'Причина.',
                  'en': '',
                  'th': 'เหตุผล',
                },
              },
              <String, Object?>{
                ..._structuredFinding(
                  category: 'MEANING',
                  reason: 'Причина.',
                  impact: 'Влияние.',
                  correctVariant: 'Photo of the installed cooktop.',
                ),
                'reason': <String, Object?>{
                  'ru': 'Причина.',
                  'en': ' Reason. ',
                  'th': 'เหตุผล',
                },
              },
              <String, Object?>{
                ..._structuredFinding(
                  category: 'MEANING',
                  reason: 'Причина.',
                  impact: 'Влияние.',
                  correctVariant: 'Photo of the installed cooktop.',
                ),
                'source_ambiguity': 'NONE',
              },
              <String, Object?>{
                ..._structuredFinding(
                  category: 'MEANING',
                  reason: 'Причина.',
                  impact: 'Влияние.',
                  correctVariant: 'Photo of the installed cooktop.',
                ),
                'source_ambiguity': <String, Object?>{
                  'ru': 'Неоднозначность.',
                  'en': 'Ambiguity.',
                },
              },
            ];

        for (final Map<String, Object?> malformedFinding in malformedFindings) {
          final String malformedAudit = _auditResponse(
            findings: <Map<String, Object?>>[malformedFinding],
          );
          final _QueueTransport transport = _QueueTransport(<Object>[
            _translationResponse(),
            malformedAudit,
            malformedAudit,
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
              isA<TranslatorProviderException>().having(
                (TranslatorProviderException error) => error.failure.code,
                'code',
                TranslatorFailureCode.invalidAuditResponse,
              ),
            ),
          );

          expect(transport.callCount, 3);
        }
      },
    );

    test(
      'keeps second invalid audit as technical failure with complete bundle',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _translationResponse(),
          _auditResponse(findings: 'invalid'),
          _auditResponse(
            findings: <Map<String, Object?>>[
              <String, Object?>{'category': 'MEANING', 'unknown': 'value'},
            ],
          ),
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
''';
}

String _auditResponse({
  Object? findings = const <Map<String, Object?>>[],
  String enToRu = 'Фотография установленной варочной панели.',
  String thToRu = 'Фотография установленной варочной панели.',
  String enToTh = 'ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว',
  String thToEn = 'Photo of the installed cooktop.',
}) {
  return jsonEncode(<String, Object?>{
    'EN_TO_RU': enToRu,
    'TH_TO_RU': thToRu,
    'EN_TO_TH': enToTh,
    'TH_TO_EN': thToEn,
    'findings': findings,
  });
}

Map<String, Object?> _structuredFinding({
  required String category,
  required String reason,
  required String impact,
  required String correctVariant,
  String section = 'EN',
  String sourceFragment = 'Фотография',
  String translationFragment = 'Photo',
  String sourceAmbiguity = 'NONE',
}) {
  return <String, Object?>{
    'category': category,
    'section': section,
    'source_fragment': sourceFragment,
    'translation_fragment': translationFragment,
    'reason': _localizedEvidence(reason),
    'impact': _localizedEvidence(impact),
    'correct_variant': correctVariant,
    'source_ambiguity': sourceAmbiguity == 'NONE'
        ? null
        : _localizedEvidence(sourceAmbiguity),
  };
}

Map<String, Object?> _localizedEvidence(String ru) {
  return <String, Object?>{
    'ru': ru,
    'en': 'English explanation for this finding.',
    'th': 'คำอธิบายภาษาไทยสำหรับข้อค้นพบนี้',
  };
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
  String buildAuditUserPrompt({
    required TranslationLanguage sourceLanguage,
    required String sourceText,
    required String ru,
    required String en,
    required String th,
  }) {
    return '''
SOURCE LANGUAGE:
${sourceLanguage.code}

SOURCE TEXT:
$sourceText

RU:
$ru

EN:
$en

TH:
$th
''';
  }
}
