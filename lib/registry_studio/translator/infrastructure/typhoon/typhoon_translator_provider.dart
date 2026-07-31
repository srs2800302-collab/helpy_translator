import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../application/translator_provider.dart';
import '../../domain/translator_models.dart';
import 'typhoon_semantic_protocol.dart';

final class TyphoonTranslatorProvider implements TranslatorProvider {
  const TyphoonTranslatorProvider({
    required this.policy,
    this.baseUrl = 'https://api.opentyphoon.ai/v1',
    this.model = 'typhoon-v2.5-30b-a3b-instruct',
    this.transportFactory = _defaultTransportFactory,
  });

  final TranslatorPolicy policy;
  final String baseUrl;
  final String model;
  final TyphoonChatTransport Function() transportFactory;

  @override
  TranslatorOperation start({
    required TranslatorWorkRequest request,
    required String accessKey,
  }) {
    return _TyphoonTranslatorOperation(
      request: request,
      accessKey: accessKey,
      policy: policy,
      baseUrl: baseUrl,
      model: model,
      transport: transportFactory(),
    );
  }

  static TyphoonChatTransport _defaultTransportFactory() {
    return DartIoTyphoonChatTransport();
  }
}

abstract interface class TyphoonChatTransport {
  Future<String> complete({
    required Uri endpoint,
    required String accessKey,
    required Map<String, Object?> body,
  });

  void cancel();

  void close();
}

final class DartIoTyphoonChatTransport implements TyphoonChatTransport {
  DartIoTyphoonChatTransport() : _client = HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 30);
  }

  final HttpClient _client;
  bool _cancelled = false;

  @override
  Future<String> complete({
    required Uri endpoint,
    required String accessKey,
    required Map<String, Object?> body,
  }) async {
    if (_cancelled) {
      throw const TyphoonTransportException.cancelled();
    }

    try {
      final HttpClientRequest request = await _client.postUrl(endpoint);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $accessKey')
        ..contentType = ContentType.json;

      request.add(utf8.encode(jsonEncode(body)));

      final HttpClientResponse response = await request.close().timeout(
        const Duration(seconds: 60),
      );

      final String responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 60));

      if (_cancelled) {
        throw const TyphoonTransportException.cancelled();
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TyphoonTransportException.http(
          statusCode: response.statusCode,
          responseBody: responseBody,
        );
      }

      final Object? decoded = jsonDecode(responseBody);
      if (decoded is! Map<Object?, Object?> ||
          decoded.keys.any((Object? key) => key is! String)) {
        throw const TyphoonTransportException.malformed(
          'Typhoon API response must be a JSON object.',
        );
      }

      final Object? choices = decoded.cast<String, Object?>()['choices'];
      if (choices is! List<Object?> || choices.isEmpty) {
        throw const TyphoonTransportException.malformed(
          'Typhoon API response does not contain choices.',
        );
      }

      final Object? choice = choices.first;
      if (choice is! Map<Object?, Object?> ||
          choice.keys.any((Object? key) => key is! String)) {
        throw const TyphoonTransportException.malformed(
          'Typhoon API choice has an invalid format.',
        );
      }

      final Object? message = choice.cast<String, Object?>()['message'];
      if (message is! Map<Object?, Object?> ||
          message.keys.any((Object? key) => key is! String)) {
        throw const TyphoonTransportException.malformed(
          'Typhoon API choice does not contain a valid message.',
        );
      }

      final Object? content = message.cast<String, Object?>()['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const TyphoonTransportException.malformed(
          'Typhoon API returned an empty message.',
        );
      }

      return content.trim();
    } on TimeoutException {
      throw const TyphoonTransportException.timeout();
    } on SocketException catch (error) {
      if (_cancelled) {
        throw const TyphoonTransportException.cancelled();
      }
      throw TyphoonTransportException.network(error.message);
    } on HttpException catch (error) {
      if (_cancelled) {
        throw const TyphoonTransportException.cancelled();
      }
      throw TyphoonTransportException.network(error.message);
    } on ArgumentError catch (error) {
      throw TyphoonTransportException.malformed(
        error.message?.toString() ?? 'Invalid Typhoon request.',
      );
    } on FormatException catch (error) {
      throw TyphoonTransportException.malformed(error.message);
    }
  }

  @override
  void cancel() {
    _cancelled = true;
    _client.close(force: true);
  }

  @override
  void close() {
    _client.close();
  }
}

final class _TyphoonTranslatorOperation implements TranslatorOperation {
  _TyphoonTranslatorOperation({
    required this.request,
    required this.accessKey,
    required this.policy,
    required this.baseUrl,
    required this.model,
    required this.transport,
  }) {
    _result = Future<TranslatorRunReport>.microtask(_execute);
  }

  final TranslatorWorkRequest request;
  final String accessKey;
  final TranslatorPolicy policy;
  final String baseUrl;
  final String model;
  final TyphoonChatTransport transport;

  final StreamController<TranslatorRunStage> _progressController =
      StreamController<TranslatorRunStage>.broadcast(sync: true);

  late final Future<TranslatorRunReport> _result;
  bool _cancelled = false;

  @override
  Future<TranslatorRunReport> get result => _result;

  @override
  Stream<TranslatorRunStage> get progress => _progressController.stream;

  @override
  void cancel() {
    if (_cancelled) {
      return;
    }

    _cancelled = true;
    transport.cancel();
  }

  Future<TranslatorRunReport> _execute() async {
    final String normalizedAccessKey = accessKey.trim();

    if (normalizedAccessKey.isEmpty) {
      await _close();
      throw TranslatorProviderException(
        TranslatorFailure(
          stage: TranslatorFailureStage.validation,
          code: TranslatorFailureCode.accessKeyEmpty,
          message: 'Введите API key Typhoon.',
        ),
      );
    }

    if (!_accessKeyPattern.hasMatch(normalizedAccessKey)) {
      await _close();
      throw TranslatorProviderException(
        TranslatorFailure(
          stage: TranslatorFailureStage.validation,
          code: TranslatorFailureCode.accessKeyInvalidCharacters,
          message:
              'API key Typhoon содержит пробелы, переносы строк '
              'или невидимые символы. Вставьте только сам ключ.',
        ),
      );
    }

    TranslationBundle? partialBundle;

    try {
      _emit(TranslatorRunStage.directTranslation);
      final TranslationBundle bundle = await _requestTranslation();
      partialBundle = bundle;

      _emit(TranslatorRunStage.audit);
      final List<TranslationPairAudit>? pairAudits = await _requestGeneralAudit(
        bundle,
      );

      if (pairAudits == null) {
        return _report(
          bundle: bundle,
          audit: TranslationAudit(protocolFallback: true),
        );
      }

      final TranslationAudit auditCandidate = TranslationAudit(
        pairAudits: pairAudits,
      );

      if (!auditCandidate.candidateForExact) {
        return _report(bundle: bundle, audit: auditCandidate);
      }

      _emit(TranslatorRunStage.exactCertification);
      final List<ExactPairCertification> certifications =
          await _requestExactCertifications(bundle);

      return _report(
        bundle: bundle,
        audit: TranslationAudit(
          pairAudits: pairAudits,
          exactCertifications: certifications,
        ),
      );
    } on TranslatorProviderException {
      rethrow;
    } on TyphoonTransportException catch (error) {
      throw TranslatorProviderException(
        _mapTransportFailure(error, partialBundle: partialBundle),
      );
    } finally {
      await _close();
    }
  }

  Future<TranslationBundle> _requestTranslation() async {
    final String systemPrompt = policy.buildDirectSystemPrompt();
    final String userPrompt = policy.buildDirectUserPrompt(request);

    for (int attempt = 0; attempt <= _protocolRetryMax; attempt += 1) {
      final String content = await _request(
        systemPrompt: attempt == 0
            ? systemPrompt
            : _strictTranslationRetryPrompt(systemPrompt),
        userPrompt: userPrompt,
      );

      try {
        return TyphoonSemanticProtocol.parseTranslation(
          content: content,
          expectedSourceText: request.sourceText,
        );
      } on TyphoonSemanticProtocolException catch (error) {
        if (attempt == _protocolRetryMax) {
          throw TranslatorProviderException(
            TranslatorFailure(
              stage: TranslatorFailureStage.directTranslation,
              code: TranslatorFailureCode.malformedProviderResponse,
              message:
                  'Ответ перевода остался некорректным после повторной '
                  'попытки: ${error.message}',
              completeness: TranslationCompleteness.translationIncomplete,
            ),
          );
        }
      }
    }

    throw StateError('Unreachable translation retry state.');
  }

  Future<List<TranslationPairAudit>?> _requestGeneralAudit(
    TranslationBundle bundle,
  ) async {
    final String systemPrompt = policy.buildAuditSystemPrompt();
    final String userPrompt = policy.buildAuditUserPrompt(
      ru: bundle.ru,
      en: bundle.en,
      th: bundle.th,
    );

    for (int attempt = 0; attempt <= _protocolRetryMax; attempt += 1) {
      final String content = await _request(
        systemPrompt: attempt == 0
            ? systemPrompt
            : _strictAuditRetryPrompt(systemPrompt),
        userPrompt: userPrompt,
      );

      try {
        return TyphoonSemanticProtocol.parseGeneralAudit(content);
      } on TyphoonSemanticProtocolException {
        if (attempt == _protocolRetryMax) {
          return null;
        }
      }
    }

    return null;
  }

  Future<List<ExactPairCertification>> _requestExactCertifications(
    TranslationBundle bundle,
  ) async {
    final List<ExactPairCertification> result = <ExactPairCertification>[];

    for (final TranslationPair pair in TranslationPair.values) {
      final String systemPrompt = policy.buildExactChallengerSystemPrompt(pair);
      final String userPrompt = policy.buildExactChallengerUserPrompt(
        pair: pair,
        leftText: bundle.textFor(pair.leftLanguage),
        rightText: bundle.textFor(pair.rightLanguage),
      );

      ExactPairCertification? certification;

      for (int attempt = 0; attempt <= _protocolRetryMax; attempt += 1) {
        final String content = await _request(
          systemPrompt: attempt == 0
              ? systemPrompt
              : _strictExactRetryPrompt(systemPrompt, pair),
          userPrompt: userPrompt,
        );

        try {
          certification = TyphoonSemanticProtocol.parseExactCertification(
            content: content,
            pair: pair,
          );
          break;
        } on TyphoonSemanticProtocolException {
          if (attempt == _protocolRetryMax) {
            certification = ExactPairCertification(
              pair: pair,
              result: ExactCertificationResult.protocolFailure,
            );
          }
        }
      }

      result.add(certification!);
    }

    return List<ExactPairCertification>.unmodifiable(result);
  }

  TranslatorRunReport _report({
    required TranslationBundle bundle,
    required TranslationAudit audit,
  }) {
    return TranslatorRunReport(
      request: request,
      bundle: bundle,
      audit: audit,
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<String> _request({
    required String systemPrompt,
    required String userPrompt,
  }) {
    return transport.complete(
      endpoint: _endpoint,
      accessKey: accessKey.trim(),
      body: <String, Object?>{
        'model': model,
        'max_completion_tokens': _maxCompletionTokens,
        'temperature': _temperature,
        'top_p': _topP,
        'frequency_penalty': _frequencyPenalty,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'system', 'content': systemPrompt},
          <String, String>{'role': 'user', 'content': userPrompt},
        ],
      },
    );
  }

  Uri get _endpoint {
    final String normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return Uri.parse('$normalized/chat/completions');
  }

  void _emit(TranslatorRunStage stage) {
    if (_cancelled) {
      throw const TyphoonTransportException.cancelled();
    }

    if (!_progressController.isClosed) {
      _progressController.add(stage);
    }
  }

  Future<void> _close() async {
    transport.close();

    if (!_progressController.isClosed) {
      await _progressController.close();
    }
  }

  static String _strictTranslationRetryPrompt(String basePrompt) {
    return '''
$basePrompt

FINAL PROTOCOL RETRY:
Return exactly one JSON object with exactly SOURCE_LANGUAGE, SOURCE_TEXT, RU,
EN, and TH. No Markdown, preamble, commentary, reverse translations, empty
values, placeholders, or unknown keys.
'''
        .trim();
  }

  static String _strictAuditRetryPrompt(String basePrompt) {
    return '''
$basePrompt

FINAL PROTOCOL RETRY:
Return one JSON object with exactly RU_EN, RU_TH, and EN_TH. Every pair must
contain exactly RESULT and ISSUES. ISSUES must be an array of at most two
objects with exactly ATOM and STATUS. Output no other text.
'''
        .trim();
  }

  static String _strictExactRetryPrompt(
    String basePrompt,
    TranslationPair pair,
  ) {
    return '''
$basePrompt

FINAL PROTOCOL RETRY FOR ${pair.code}:
Return exactly {"RESULT":"CLEAR","ATOM":null} or
{"RESULT":"NOT_CERTIFIED","ATOM":"<canonical_atom>"} and no other text.
'''
        .trim();
  }

  static TranslatorFailure _mapTransportFailure(
    TyphoonTransportException error, {
    required TranslationBundle? partialBundle,
  }) {
    final TranslatorFailureCode code;
    final String message;

    if (error.cancelled) {
      code = TranslatorFailureCode.cancelled;
      message = 'Перевод отменён.';
    } else if (error.timeout) {
      code = TranslatorFailureCode.timeout;
      message = 'Typhoon API не ответил вовремя.';
    } else if (error.statusCode == 401 || error.statusCode == 403) {
      code = TranslatorFailureCode.unauthorized;
      message = 'Typhoon API отклонил API key.';
    } else if (error.statusCode == 429) {
      code = TranslatorFailureCode.rateLimited;
      message = 'Превышен лимит запросов Typhoon API.';
    } else if (error.statusCode != null && error.statusCode! >= 500) {
      code = TranslatorFailureCode.serverFailure;
      message = 'Ошибка сервера Typhoon API. Повторите позже.';
    } else if (error.malformed) {
      code = TranslatorFailureCode.malformedProviderResponse;
      message = error.message;
    } else {
      code = TranslatorFailureCode.networkFailure;
      message = 'Ошибка соединения с Typhoon API: ${error.message}';
    }

    return TranslatorFailure(
      stage: TranslatorFailureStage.transport,
      code: code,
      message: message,
      completeness: partialBundle == null
          ? null
          : TranslationCompleteness.complete,
      partialBundle: partialBundle,
    );
  }

  static const int _maxCompletionTokens = 512;
  static const double _temperature = 0.6;
  static const double _topP = 0.6;
  static const double _frequencyPenalty = 0.0;
  static const int _protocolRetryMax = 1;

  static final RegExp _accessKeyPattern = RegExp(r'^[\x21-\x7E]+$');
}

final class TyphoonTransportException implements Exception {
  const TyphoonTransportException._({
    required this.message,
    this.statusCode,
    this.cancelled = false,
    this.timeout = false,
    this.malformed = false,
  });

  const TyphoonTransportException.http({
    required int statusCode,
    required String responseBody,
  }) : this._(message: responseBody, statusCode: statusCode);

  const TyphoonTransportException.cancelled()
    : this._(message: 'Cancelled.', cancelled: true);

  const TyphoonTransportException.timeout()
    : this._(message: 'Timed out.', timeout: true);

  const TyphoonTransportException.network(String message)
    : this._(message: message);

  const TyphoonTransportException.malformed(String message)
    : this._(message: message, malformed: true);

  final String message;
  final int? statusCode;
  final bool cancelled;
  final bool timeout;
  final bool malformed;
}
