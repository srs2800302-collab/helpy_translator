import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_provider.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/typhoon/typhoon_translator_provider.dart';

void main() {
  group('TyphoonTranslatorProvider', () {
    test(
      'runs direct, independent reverse and findings audit in order',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _directResponse(),
          _reverseResponse(),
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
          TranslatorRunStage.reverseTranslation,
          TranslatorRunStage.audit,
        ]);
        expect(report.bundle.sourceLanguage, TranslationLanguage.ru);
        expect(report.bundle.en, 'Photo of the installed cooktop.');
        expect(report.bundle.thToEn, 'Photo of the installed cooktop.');
        expect(report.audit.verdict, TranslationVerdict.exact);
        expect(transport.callCount, 3);
      },
    );

    test('maps style-only finding to equivalent', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _directResponse(),
        _reverseResponse(),
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

    test('maps meaning finding to canonical drift', () async {
      final _QueueTransport transport = _QueueTransport(<Object>[
        _directResponse(),
        _reverseResponse(),
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

    test(
      'keeps invalid audit as technical failure with complete bundle',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _directResponse(),
          _reverseResponse(),
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
                ),
          ),
        );
      },
    );

    test(
      'rejects API key with invisible characters before transport',
      () async {
        final _QueueTransport transport = _QueueTransport(<Object>[
          _directResponse(),
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

String _directResponse() {
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
ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว
''';
}

String _reverseResponse() {
  return '''
EN_TO_RU:
Фотография установленной варочной панели.

TH_TO_RU:
Фотография установленной варочной панели.

EN_TO_TH:
ภาพถ่ายของเตาประกอบอาหารที่ติดตั้งแล้ว

TH_TO_EN:
Photo of the installed cooktop.
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
  int callCount = 0;
  bool cancelled = false;

  @override
  Future<String> complete({
    required Uri endpoint,
    required String accessKey,
    required Map<String, Object?> body,
  }) async {
    callCount += 1;
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
  String buildReverseSystemPrompt() => 'reverse';

  @override
  String buildReverseUserPrompt({required String en, required String th}) =>
      '$en\n$th';

  @override
  String buildAuditSystemPrompt() => 'audit';

  @override
  String buildAuditUserPrompt(TranslationBundle bundle) =>
      bundle.nineSections.toString();
}
