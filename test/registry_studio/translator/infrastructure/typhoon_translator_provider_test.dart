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

  group('TyphoonTranslatorProvider', () {
    test('non-exact result uses two calls and no reverse path', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _lexicalGapAuditResponse(),
      ]);
      final TranslatorOperation operation = _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key');
      final List<TranslatorRunStage> stages = <TranslatorRunStage>[];
      final Future<void> progressDone = operation.progress.forEach(stages.add);

      final TranslatorRunReport report = await operation.result;
      await progressDone;

      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(report.bundle.hasReverseDiagnostics, isFalse);
      expect(transport.callCount, 2);
      expect(stages, <TranslatorRunStage>[
        TranslatorRunStage.directTranslation,
        TranslatorRunStage.audit,
      ]);
      _expectLockedSettings(transport.requestBodies);

      final Map<String, Object?> auditUser = _userData(
        transport.requestBodies[1],
      );
      expect(auditUser.keys.toSet(), <String>{'RU', 'EN', 'TH'});
      expect(auditUser.keys, isNot(contains('SOURCE_TEXT')));
      expect(auditUser.keys, isNot(contains('EN_TO_RU')));
    });

    test('exact requires five calls and three isolated challengers', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _clearAuditResponse(),
        _exactClear(),
        _exactClear(),
        _exactClear(),
      ]);
      final TranslatorOperation operation = _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key');
      final List<TranslatorRunStage> stages = <TranslatorRunStage>[];
      final Future<void> progressDone = operation.progress.forEach(stages.add);

      final TranslatorRunReport report = await operation.result;
      await progressDone;

      expect(report.audit.verdict, TranslationVerdict.exact);
      expect(transport.callCount, 5);
      expect(stages, <TranslatorRunStage>[
        TranslatorRunStage.directTranslation,
        TranslatorRunStage.audit,
        TranslatorRunStage.exactCertification,
      ]);
      _expectLockedSettings(transport.requestBodies);

      final Map<String, Object?> ruEn = _userData(transport.requestBodies[2]);
      final Map<String, Object?> ruTh = _userData(transport.requestBodies[3]);
      final Map<String, Object?> enTh = _userData(transport.requestBodies[4]);

      const Set<String> challengerKeys = <String>{
        'PAIR',
        'LEFT_LANGUAGE',
        'LEFT_TEXT',
        'RIGHT_LANGUAGE',
        'RIGHT_TEXT',
      };
      expect(ruEn.keys.toSet(), challengerKeys);
      expect(ruTh.keys.toSet(), challengerKeys);
      expect(enTh.keys.toSet(), challengerKeys);

      expect(ruEn, containsPair('PAIR', 'RU_EN'));
      expect(ruEn, containsPair('LEFT_LANGUAGE', 'RU'));
      expect(ruEn, containsPair('RIGHT_LANGUAGE', 'EN'));
      expect(ruEn.values, isNot(contains('TH')));

      expect(ruTh, containsPair('PAIR', 'RU_TH'));
      expect(ruTh, containsPair('LEFT_LANGUAGE', 'RU'));
      expect(ruTh, containsPair('RIGHT_LANGUAGE', 'TH'));
      expect(ruTh.values, isNot(contains('EN')));

      expect(enTh, containsPair('PAIR', 'EN_TH'));
      expect(enTh, containsPair('LEFT_LANGUAGE', 'EN'));
      expect(enTh, containsPair('RIGHT_LANGUAGE', 'TH'));
      expect(enTh.values, isNot(contains('RU')));
    });

    test('hard mismatch ends after audit with canonical drift', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _blockedAuditResponse(TranslationSemanticAtom.polarity),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.verdict, TranslationVerdict.canonicalDrift);
      expect(transport.callCount, 2);
    });

    test('ambiguity evidence ends after audit with needs review', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _blockedAuditResponse(TranslationSemanticAtom.ambiguity),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(transport.callCount, 2);
    });

    test('style-only mismatch ends after audit with equivalent', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _styleOnlyAuditResponse(),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.verdict, TranslationVerdict.equivalent);
      expect(transport.callCount, 2);
    });

    test('malformed audit retries once and fails closed', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        '{"RU_EN":{}}',
        'not-json',
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.protocolFallback, isTrue);
      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(transport.callCount, 3);
    });

    test('malformed challenger retries once and fails closed', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _translationResponse(),
        _clearAuditResponse(),
        '{"RESULT":"CLEAR"}',
        '{"RESULT":"CLEAR"}',
        _exactClear(),
        _exactClear(),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(
        report.audit.exactCertifications.first.result,
        ExactCertificationResult.protocolFailure,
      );
      expect(transport.callCount, 6);
    });

    test(
      'not-certified challenger blocks exact but all pairs still run',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _translationResponse(),
          _clearAuditResponse(),
          _exactClear(),
          _exactNotCertified(TranslationSemanticAtom.modality),
          _exactClear(),
        ]);

        final TranslatorRunReport report = await _provider(
          transport,
        ).start(request: _request(), accessKey: 'test-key').result;

        expect(report.audit.verdict, TranslationVerdict.needsReview);
        expect(transport.callCount, 5);
        expect(
          report.audit.exactCertifications[1].atom,
          TranslationSemanticAtom.modality,
        );
      },
    );

    test('direct protocol retries once and then succeeds', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        'not-json',
        _translationResponse(),
        _lexicalGapAuditResponse(),
      ]);

      final TranslatorRunReport report = await _provider(
        transport,
      ).start(request: _request(), accessKey: 'test-key').result;

      expect(report.bundle.en, 'install the cooktop');
      expect(report.audit.verdict, TranslationVerdict.needsReview);
      expect(transport.callCount, 3);
    });

    test('direct protocol fails after exactly one retry', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        'not-json',
        '{"SOURCE_LANGUAGE":"RU"}',
      ]);

      await expectLater(
        _provider(
          transport,
        ).start(request: _request(), accessKey: 'test-key').result,
        throwsA(
          isA<TranslatorProviderException>().having(
            (TranslatorProviderException error) => error.failure.code,
            'code',
            TranslatorFailureCode.malformedProviderResponse,
          ),
        ),
      );
      expect(transport.callCount, 2);
    });

    test('recovers a missing Thai source field only', () async {
      final String sourceText = 'อย่าติดตั้งเตาอบ';
      final _QueueTransport transport = _QueueTransport(<Object>[
        jsonEncode(<String, Object?>{
          'SOURCE_LANGUAGE': 'TH',
          'SOURCE_TEXT': sourceText,
          'RU': 'не устанавливать духовку',
          'EN': 'do not install the oven',
        }),
        _lexicalGapAuditResponse(),
      ]);

      final TranslatorRunReport report = await _provider(transport)
          .start(
            request: TranslatorWorkRequest(
              sourceText: sourceText,
              sourceLanguageHint: TranslationLanguage.th,
            ),
            accessKey: 'test-key',
          )
          .result;

      expect(report.bundle.th, sourceText);
      expect(transport.callCount, 2);
    });

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

String _clearAuditResponse() {
  return _auditResponse(<TranslationPair, Map<String, Object?>>{
    for (final TranslationPair pair in TranslationPair.values)
      pair: <String, Object?>{'RESULT': 'CLEAR', 'ISSUES': <Object?>[]},
  });
}

String _lexicalGapAuditResponse() {
  return _auditResponse(<TranslationPair, Map<String, Object?>>{
    TranslationPair.ruEn: <String, Object?>{
      'RESULT': 'CLEAR',
      'ISSUES': <Object?>[],
    },
    TranslationPair.ruTh: _unproven(TranslationSemanticAtom.equipmentIdentity),
    TranslationPair.enTh: _unproven(TranslationSemanticAtom.equipmentIdentity),
  });
}

String _blockedAuditResponse(TranslationSemanticAtom atom) {
  return _auditResponse(<TranslationPair, Map<String, Object?>>{
    TranslationPair.ruEn: _blocked(atom),
    TranslationPair.ruTh: _blocked(atom),
    TranslationPair.enTh: <String, Object?>{
      'RESULT': 'CLEAR',
      'ISSUES': <Object?>[],
    },
  });
}

String _styleOnlyAuditResponse() {
  return _auditResponse(<TranslationPair, Map<String, Object?>>{
    TranslationPair.ruEn: _blocked(TranslationSemanticAtom.canonicalStyle),
    TranslationPair.ruTh: <String, Object?>{
      'RESULT': 'CLEAR',
      'ISSUES': <Object?>[],
    },
    TranslationPair.enTh: <String, Object?>{
      'RESULT': 'CLEAR',
      'ISSUES': <Object?>[],
    },
  });
}

Map<String, Object?> _blocked(TranslationSemanticAtom atom) {
  return <String, Object?>{
    'RESULT': 'BLOCKED',
    'ISSUES': <Object?>[
      <String, Object?>{'ATOM': atom.code, 'STATUS': 'X'},
    ],
  };
}

Map<String, Object?> _unproven(TranslationSemanticAtom atom) {
  return <String, Object?>{
    'RESULT': 'UNPROVEN',
    'ISSUES': <Object?>[
      <String, Object?>{'ATOM': atom.code, 'STATUS': 'U'},
    ],
  };
}

String _auditResponse(Map<TranslationPair, Map<String, Object?>> pairs) {
  return jsonEncode(<String, Object?>{
    for (final TranslationPair pair in TranslationPair.values)
      pair.code: pairs[pair],
  });
}

String _exactClear() => '{"RESULT":"CLEAR","ATOM":null}';

String _exactNotCertified(TranslationSemanticAtom atom) {
  return jsonEncode(<String, Object?>{
    'RESULT': 'NOT_CERTIFIED',
    'ATOM': atom.code,
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

final class _TestPolicy implements TranslatorPolicy {
  const _TestPolicy();

  @override
  String buildDirectSystemPrompt() => 'direct';

  @override
  String buildDirectUserPrompt(TranslatorWorkRequest request) {
    return jsonEncode(<String, Object?>{'SOURCE_TEXT': request.sourceText});
  }

  @override
  String buildAuditSystemPrompt() => 'audit';

  @override
  String buildAuditUserPrompt({
    required String ru,
    required String en,
    required String th,
  }) {
    return jsonEncode(<String, String>{'RU': ru, 'EN': en, 'TH': th});
  }

  @override
  String buildExactChallengerSystemPrompt(TranslationPair pair) {
    return 'exact ${pair.code}';
  }

  @override
  String buildExactChallengerUserPrompt({
    required TranslationPair pair,
    required String leftText,
    required String rightText,
  }) {
    return jsonEncode(<String, String>{
      'PAIR': pair.code,
      'LEFT_LANGUAGE': pair.leftLanguage.code,
      'LEFT_TEXT': leftText,
      'RIGHT_LANGUAGE': pair.rightLanguage.code,
      'RIGHT_TEXT': rightText,
    });
  }
}
