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
              'content': 'Мастер подтверждает прибытие. ช่างยืนยันการมาถึง',
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

  group('TyphoonTranslatorProvider EXACT capability flow', () {
    test('uses exactly four nominal calls and a local EXACT verdict', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _reverseDiagnosticsResponse(),
        _supportedAssessmentResponse(TranslationLanguage.en),
        _supportedAssessmentResponse(TranslationLanguage.th),
      ]);
      final TranslatorOperation operation = _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key');
      final List<TranslatorRunStage> stages = <TranslatorRunStage>[];
      final Future<void> progressDone = operation.progress.forEach(stages.add);

      final TranslatorRunReport report = await operation.result;
      await progressDone;

      expect(report.audit.verdict, TranslationVerdict.exact);
      expect(
        report.audit.exactCapability?.localVerdict,
        ExactCapabilityVerdict.exact,
      );
      expect(report.audit.pairAudits, isEmpty);
      expect(report.audit.exactChallenge, isNull);
      expect(report.bundle.en, 'install the cooktop');
      expect(report.bundle.th, 'ติดตั้งเตาไฟ');
      expect(report.bundle.hasReverseDiagnostics, isFalse);
      expect(transport.callCount, 4);
      expect(stages, <TranslatorRunStage>[
        TranslatorRunStage.directTranslation,
        TranslatorRunStage.reverseTranslation,
        TranslatorRunStage.audit,
      ]);
      _expectLockedSettings(transport.requestBodies);

      expect(_userData(transport.requestBodies[1]), <String, Object?>{
        'EN': 'install the cooktop',
        'TH': 'ติดตั้งเตาไฟ',
      });
      expect(_userData(transport.requestBodies[2]), <String, Object?>{
        'SOURCE_RU': 'установить варочную панель',
        'TARGET_LANGUAGE': 'EN',
        'TARGET_TEXT': 'install the cooktop',
        'REVERSE_DIAGNOSTIC': 'установить варочную панель',
      });
      expect(_userData(transport.requestBodies[3]), <String, Object?>{
        'SOURCE_RU': 'установить варочную панель',
        'TARGET_LANGUAGE': 'TH',
        'TARGET_TEXT': 'ติดตั้งเตาไฟ',
        'REVERSE_DIAGNOSTIC': 'установить варочную панель',
      });
    });

    test('contextual assessment produces local NEEDS_REVIEW', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _reverseDiagnosticsResponse(),
        _supportedAssessmentResponse(TranslationLanguage.en),
        _assessmentResponse(
          language: TranslationLanguage.th,
          equipmentStatus: 'C',
        ),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(
        report.audit.exactCapability?.localVerdict,
        ExactCapabilityVerdict.needsReview,
      );
      expect(transport.callCount, 4);
    });

    test('contradicted assessment produces local BLOCKED', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _reverseDiagnosticsResponse(),
        _assessmentResponse(
          language: TranslationLanguage.en,
          equipmentStatus: 'X',
        ),
        _supportedAssessmentResponse(TranslationLanguage.th),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.verdict, TranslationVerdict.canonicalDrift);
      expect(
        report.audit.exactCapability?.localVerdict,
        ExactCapabilityVerdict.blocked,
      );
      expect(transport.callCount, 4);
    });

    test('malformed reverse diagnostics retries and fails closed', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        'not-json',
        '{"EN_TO_RU":"only one key"}',
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(report.audit.auditProtocolFailed, isTrue);
      expect(report.audit.exactCapability?.protocolFailure, isTrue);
      expect(report.audit.exactCapability?.reverseDiagnostics, isNull);
      expect(transport.callCount, 3);
    });

    test('malformed atom verification preserves reverse diagnostics', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _reverseDiagnosticsResponse(),
        'not-json',
        '{"ASSESSMENTS":[]}',
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.auditProtocolFailed, isTrue);
      expect(
        report.audit.exactCapability?.reverseDiagnostics?.enToRu,
        'установить варочную панель',
      );
      expect(transport.callCount, 4);
    });

    test('different EN and TH atom sets fail closed locally', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _reverseDiagnosticsResponse(),
        _supportedAssessmentResponse(TranslationLanguage.en),
        _singleActionAssessmentResponse(TranslationLanguage.th),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.auditProtocolFailed, isTrue);
      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(transport.callCount, 4);
    });

    test('direct protocol retries once before the four-stage flow', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        'not-json',
        _translationResponse(),
        _reverseDiagnosticsResponse(),
        _supportedAssessmentResponse(TranslationLanguage.en),
        _supportedAssessmentResponse(TranslationLanguage.th),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.verdict, TranslationVerdict.exact);
      expect(transport.callCount, 5);
    });

    test(
      'transport failure after direct translation preserves provider text',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _translationResponse(),
          const TyphoonTransportException.timeout(),
        ]);

        await expectLater(
          _provider(
            transport,
          ).start(request: _request(), accessKey: 'test-key').result,
          throwsA(
            isA<TranslatorProviderException>()
                .having(
                  (TranslatorProviderException error) =>
                      error.failure.partialBundle?.en,
                  'partial EN',
                  'install the cooktop',
                )
                .having(
                  (TranslatorProviderException error) =>
                      error.failure.partialBundle?.th,
                  'partial TH',
                  'ติดตั้งเตาไฟ',
                ),
          ),
        );
      },
    );

    test('rejects empty and whitespace-containing access keys', () async {
      await expectLater(
        _provider(
          _QueueTransport(<Object>[]),
        ).start(request: _request(), accessKey: ' ').result,
        throwsA(
          isA<TranslatorProviderException>().having(
            (TranslatorProviderException error) => error.failure.code,
            'code',
            TranslatorFailureCode.accessKeyEmpty,
          ),
        ),
      );

      await expectLater(
        _provider(
          _QueueTransport(<Object>[]),
        ).start(request: _request(), accessKey: 'bad key').result,
        throwsA(
          isA<TranslatorProviderException>().having(
            (TranslatorProviderException error) => error.failure.code,
            'code',
            TranslatorFailureCode.accessKeyInvalidCharacters,
          ),
        ),
      );
    });
  });
}

TyphoonTranslatorProvider _provider(_QueueTransport transport) {
  return TyphoonTranslatorProvider(
    policy: const _TestPolicy(),
    transportFactory: () => transport,
  );
}

TranslatorWorkRequest _request() {
  return TranslatorWorkRequest(
    sourceText: 'установить варочную панель',
    sourceLanguageHint: TranslationLanguage.ru,
  );
}

String _translationResponse() {
  return jsonEncode(<String, Object?>{
    'SOURCE_LANGUAGE': 'RU',
    'SOURCE_TEXT': 'установить варочную панель',
    'RU': 'установить варочную панель',
    'EN': 'install the cooktop',
    'TH': 'ติดตั้งเตาไฟ',
  });
}

String _reverseDiagnosticsResponse() {
  return jsonEncode(<String, Object?>{
    'EN_TO_RU': 'установить варочную панель',
    'TH_TO_RU': 'установить варочную панель',
  });
}

String _supportedAssessmentResponse(TranslationLanguage language) {
  return _assessmentResponse(language: language, equipmentStatus: 'S');
}

String _assessmentResponse({
  required TranslationLanguage language,
  required String equipmentStatus,
}) {
  final ({String action, String equipment}) fragments = switch (language) {
    TranslationLanguage.en => (action: 'install', equipment: 'cooktop'),
    TranslationLanguage.th => (action: 'ติดตั้ง', equipment: 'เตาไฟ'),
    TranslationLanguage.ru => throw ArgumentError.value(language),
  };

  return jsonEncode(<String, Object?>{
    'ASSESSMENTS': <Object?>[
      <String, Object?>{
        'ATOM': 'action',
        'STATUS': 'S',
        'FRAGMENT': fragments.action,
      },
      <String, Object?>{
        'ATOM': 'equipment_identity',
        'STATUS': equipmentStatus,
        'FRAGMENT': fragments.equipment,
      },
    ],
  });
}

String _singleActionAssessmentResponse(TranslationLanguage language) {
  final String fragment = switch (language) {
    TranslationLanguage.en => 'install',
    TranslationLanguage.th => 'ติดตั้ง',
    TranslationLanguage.ru => throw ArgumentError.value(language),
  };

  return jsonEncode(<String, Object?>{
    'ASSESSMENTS': <Object?>[
      <String, Object?>{'ATOM': 'action', 'STATUS': 'S', 'FRAGMENT': fragment},
    ],
  });
}

Map<String, Object?> _userData(Map<String, Object?> body) {
  final List<Object?> messages = body['messages']! as List<Object?>;
  final String content = (messages.last as Map<String, String>)['content']!;
  return (jsonDecode(content) as Map<Object?, Object?>).cast<String, Object?>();
}

void _expectLockedSettings(List<Map<String, Object?>> bodies) {
  for (final Map<String, Object?> body in bodies) {
    expect(body['max_completion_tokens'], 512);
    expect(body['temperature'], 0.6);
    expect(body['top_p'], 0.6);
    expect(body['frequency_penalty'], 0.0);
    expect(body.containsKey('max_tokens'), isFalse);
  }
}

final class _QueueTransport implements TyphoonChatTransport {
  _QueueTransport(this.responses);

  final List<Object> responses;
  final List<Map<String, Object?>> requestBodies = <Map<String, Object?>>[];
  int callCount = 0;

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
  void cancel() {}

  @override
  void close() {}
}

final class _TestPolicy implements TranslatorPolicy, ExactCapabilityPolicy {
  const _TestPolicy();

  @override
  String buildDirectSystemPrompt() => 'direct';

  @override
  String buildDirectUserPrompt(TranslatorWorkRequest request) {
    return jsonEncode(<String, Object?>{'SOURCE_TEXT': request.sourceText});
  }

  @override
  String buildReverseDiagnosticsSystemPrompt() => 'reverse diagnostics';

  @override
  String buildReverseDiagnosticsUserPrompt({
    required String en,
    required String th,
  }) {
    return jsonEncode(<String, String>{'EN': en, 'TH': th});
  }

  @override
  String buildAtomVerificationSystemPrompt() => 'atom verification';

  @override
  String buildAtomVerificationUserPrompt({
    required String sourceRu,
    required TranslationLanguage targetLanguage,
    required String targetText,
    required String reverseDiagnostic,
  }) {
    return jsonEncode(<String, String>{
      'SOURCE_RU': sourceRu,
      'TARGET_LANGUAGE': targetLanguage.code,
      'TARGET_TEXT': targetText,
      'REVERSE_DIAGNOSTIC': reverseDiagnostic,
    });
  }

  @override
  String buildAuditSystemPrompt() => 'legacy audit';

  @override
  String buildAuditUserPrompt({
    required String ru,
    required String en,
    required String th,
  }) {
    return jsonEncode(<String, String>{'RU': ru, 'EN': en, 'TH': th});
  }

  @override
  String buildExactChallengerSystemPrompt() => 'legacy challenger';

  @override
  String buildExactChallengerUserPrompt({
    required String ru,
    required String en,
    required String th,
  }) {
    return jsonEncode(<String, String>{'RU': ru, 'EN': en, 'TH': th});
  }
}
