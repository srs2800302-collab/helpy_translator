import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../application/translator_provider.dart';
import '../../domain/translator_models.dart';

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

      final String directContent = await _request(
        systemPrompt: policy.buildDirectSystemPrompt(),
        userPrompt: policy.buildDirectUserPrompt(request),
        maxTokens: 768,
      );

      final Map<String, String> direct = _parsePayload(
        content: directContent,
        labels: _directLabels,
        stage: TranslatorFailureStage.directTranslation,
        responseName: 'Прямой перевод',
      );

      final TranslationLanguage sourceLanguage;

      try {
        sourceLanguage = TranslationLanguage.fromCode(
          direct['SOURCE LANGUAGE']!,
        );
      } on ArgumentError catch (error) {
        throw TranslatorProviderException(
          TranslatorFailure(
            stage: TranslatorFailureStage.directTranslation,
            code: TranslatorFailureCode.invalidSourceLanguage,
            message: error.message?.toString() ?? 'Invalid source language.',
          ),
        );
      }

      if (direct['SOURCE TEXT'] != request.sourceText) {
        throw const _PayloadFailure(
          stage: TranslatorFailureStage.directTranslation,
          code: TranslatorFailureCode.sourceTextMismatch,
          message: 'Typhoon изменил SOURCE TEXT.',
        );
      }

      if (direct[sourceLanguage.code] != request.sourceText) {
        throw const _PayloadFailure(
          stage: TranslatorFailureStage.directTranslation,
          code: TranslatorFailureCode.sourceTextMismatch,
          message: 'Секция исходного языка не совпадает с SOURCE TEXT.',
        );
      }
      partialBundle = TranslationBundle(
        sourceLanguage: sourceLanguage,
        sourceText: direct['SOURCE TEXT']!,
        ru: direct['RU']!,
        en: direct['EN']!,
        th: direct['TH']!,
      );

      _emit(TranslatorRunStage.audit);

      final String auditUserPrompt = policy.buildAuditUserPrompt(partialBundle);

      TranslationAudit audit;

      try {
        final String auditContent = await _request(
          systemPrompt: policy.buildAuditSystemPrompt(),
          userPrompt: auditUserPrompt,
          maxTokens: 1024,
        );

        audit = _parseAudit(auditContent);
      } on _AuditFailure {
        final String repairedAuditContent = await _request(
          systemPrompt: _buildStrictAuditRetryPrompt(
            policy.buildAuditSystemPrompt(),
          ),
          userPrompt: auditUserPrompt,
          maxTokens: 1024,
        );

        try {
          audit = _parseAudit(repairedAuditContent);
        } on _AuditFailure catch (error) {
          throw _AuditFailure(
            'Ответ аудита остался некорректным после повторной попытки: '
            '${error.message}',
          );
        }
      }

      return TranslatorRunReport(
        request: request,
        bundle: partialBundle,
        audit: audit,
        createdAt: DateTime.now().toUtc(),
      );
    } on TranslatorProviderException {
      rethrow;
    } on _PayloadFailure catch (error) {
      throw TranslatorProviderException(
        TranslatorFailure(
          stage: error.stage,
          code: error.code,
          message: error.message,
          completeness: TranslationCompleteness.translationIncomplete,
          partialBundle: partialBundle,
        ),
      );
    } on _AuditFailure catch (error) {
      throw TranslatorProviderException(
        TranslatorFailure(
          stage: TranslatorFailureStage.audit,
          code: TranslatorFailureCode.invalidAuditResponse,
          message: error.message,
          completeness: TranslationCompleteness.complete,
          partialBundle: partialBundle,
        ),
      );
    } on TyphoonTransportException catch (error) {
      throw TranslatorProviderException(
        _mapTransportFailure(error, partialBundle: partialBundle),
      );
    } finally {
      await _close();
    }
  }

  static String _buildStrictAuditRetryPrompt(String basePrompt) {
    return '''
$basePrompt

The previous audit response violated the required output protocol.
Run the semantic audit again from the supplied five-section direct bundle.

This is the final format attempt:
- output exactly four labels;
- preserve the exact label spelling and order;
- put a colon after every label;
- use only NONE or Russian "- " bullet points as values;
- output no preamble, Markdown, verdict, summary or commentary.
'''
        .trim();
  }

  Future<String> _request({
    required String systemPrompt,
    required String userPrompt,
    required int maxTokens,
  }) {
    return transport.complete(
      endpoint: _endpoint,
      accessKey: accessKey.trim(),
      body: <String, Object?>{
        'model': model,
        'max_tokens': maxTokens,
        'temperature': 0.0,
        'top_p': 1.0,
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

  static Map<String, String> _parsePayload({
    required String content,
    required List<String> labels,
    required TranslatorFailureStage stage,
    required String responseName,
    bool allowNone = false,
  }) {
    final String normalized = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    if (normalized.isEmpty) {
      throw _PayloadFailure(
        stage: stage,
        code: TranslatorFailureCode.emptyRequiredSection,
        message: '$responseName пуст.',
      );
    }

    final List<RegExpMatch> matches = _sectionPattern
        .allMatches(normalized)
        .toList(growable: false);

    if (matches.length != labels.length) {
      throw _PayloadFailure(
        stage: stage,
        code: TranslatorFailureCode.missingRequiredSection,
        message: '$responseName содержит неверное количество секций.',
      );
    }

    final List<String> actualLabels = matches
        .map((RegExpMatch match) => match.group(1)!)
        .toList(growable: false);

    if (actualLabels.toSet().length != actualLabels.length) {
      throw _PayloadFailure(
        stage: stage,
        code: TranslatorFailureCode.unexpectedSection,
        message: '$responseName содержит дублированные секции.',
      );
    }

    for (int index = 0; index < labels.length; index += 1) {
      if (actualLabels[index] != labels[index]) {
        throw _PayloadFailure(
          stage: stage,
          code: TranslatorFailureCode.invalidSectionOrder,
          message: '$responseName содержит секции в неверном порядке.',
        );
      }
    }

    final String preamble = normalized.substring(0, matches.first.start).trim();

    if (preamble.isNotEmpty) {
      throw _PayloadFailure(
        stage: stage,
        code: TranslatorFailureCode.unexpectedSection,
        message: '$responseName содержит текст до первой секции.',
      );
    }

    final Map<String, String> result = <String, String>{};

    for (int index = 0; index < labels.length; index += 1) {
      final int valueStart = matches[index].end;
      final int valueEnd = index + 1 < matches.length
          ? matches[index + 1].start
          : normalized.length;

      final String label = labels[index];
      final String value = normalized.substring(valueStart, valueEnd).trim();

      if (value.isEmpty) {
        throw _PayloadFailure(
          stage: stage,
          code: TranslatorFailureCode.emptyRequiredSection,
          message: 'Секция $label пуста.',
        );
      }

      if (!allowNone && _placeholderValues.contains(value.toUpperCase())) {
        throw _PayloadFailure(
          stage: stage,
          code: TranslatorFailureCode.placeholderValue,
          message: 'Секция $label содержит значение-заглушку.',
        );
      }

      result[label] = value;
    }

    return result;
  }

  static TranslationAudit _parseAudit(String content) {
    final Map<String, String> sections;

    try {
      sections = _parsePayload(
        content: content,
        labels: _auditLabels,
        stage: TranslatorFailureStage.audit,
        responseName: 'Ответ аудита',
        allowNone: true,
      );
    } on _PayloadFailure catch (error) {
      throw _AuditFailure(error.message);
    }

    return TranslationAudit(
      meaningFindings: _parseFindings(
        sections['MEANING_FINDINGS']!,
        'MEANING_FINDINGS',
      ),
      terminologyFindings: _parseFindings(
        sections['TERMINOLOGY_FINDINGS']!,
        'TERMINOLOGY_FINDINGS',
      ),
      styleFindings: _parseFindings(
        sections['STYLE_FINDINGS']!,
        'STYLE_FINDINGS',
      ),
      ambiguityFindings: _parseFindings(
        sections['AMBIGUITY_FINDINGS']!,
        'AMBIGUITY_FINDINGS',
      ),
    );
  }

  static List<String> _parseFindings(String value, String label) {
    if (value.trim().toUpperCase() == 'NONE') {
      return const <String>[];
    }

    final List<String> lines = value
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty || lines.any((String line) => !line.startsWith('- '))) {
      throw _AuditFailure(
        'Секция $label должна содержать NONE или список "- ...".',
      );
    }

    final List<String> findings = lines
        .map((String line) => line.substring(2).trim())
        .toList(growable: false);

    if (findings.any((String finding) => finding.isEmpty)) {
      throw _AuditFailure('Секция $label содержит пустой finding.');
    }

    return findings;
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

  static final RegExp _accessKeyPattern = RegExp(r'^[\x21-\x7E]+$');

  static const List<String> _directLabels = <String>[
    'SOURCE LANGUAGE',
    'SOURCE TEXT',
    'RU',
    'EN',
    'TH',
  ];

  static const List<String> _auditLabels = <String>[
    'MEANING_FINDINGS',
    'TERMINOLOGY_FINDINGS',
    'STYLE_FINDINGS',
    'AMBIGUITY_FINDINGS',
  ];

  static const Set<String> _placeholderValues = <String>{
    '-',
    'N/A',
    'NONE',
    'NULL',
    'UNKNOWN',
    'NOT PROVIDED',
  };

  static final RegExp _sectionPattern = RegExp(
    r'^([A-Z][A-Z0-9 _]*):[ \t]*$',
    multiLine: true,
  );
}

final class _PayloadFailure implements Exception {
  const _PayloadFailure({
    required this.stage,
    required this.code,
    required this.message,
  });

  final TranslatorFailureStage stage;
  final TranslatorFailureCode code;
  final String message;
}

final class _AuditFailure implements Exception {
  const _AuditFailure(this.message);

  final String message;
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
