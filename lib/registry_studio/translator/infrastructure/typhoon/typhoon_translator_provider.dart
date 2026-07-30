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

      final String translationContent = await _request(
        systemPrompt: policy.buildDirectSystemPrompt(),
        userPrompt: policy.buildDirectUserPrompt(request),
        maxTokens: _translationMaxTokens,
        temperature: _translationTemperature,
      );

      final Map<String, String> translation = _parsePayload(
        content: translationContent,
        labels: _translationLabels,
        stage: TranslatorFailureStage.directTranslation,
        responseName: 'Атомарный перевод',
      );

      final TranslationLanguage sourceLanguage;

      try {
        sourceLanguage = TranslationLanguage.fromCode(
          translation['SOURCE LANGUAGE']!,
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

      if (translation['SOURCE TEXT'] != request.sourceText) {
        throw const _PayloadFailure(
          stage: TranslatorFailureStage.directTranslation,
          code: TranslatorFailureCode.sourceTextMismatch,
          message: 'Typhoon изменил SOURCE TEXT.',
        );
      }

      if (translation[sourceLanguage.code] != request.sourceText) {
        throw const _PayloadFailure(
          stage: TranslatorFailureStage.directTranslation,
          code: TranslatorFailureCode.sourceTextMismatch,
          message: 'Секция исходного языка не совпадает с SOURCE TEXT.',
        );
      }

      final TranslationBundle bundle = TranslationBundle(
        sourceLanguage: sourceLanguage,
        sourceText: translation['SOURCE TEXT']!,
        ru: translation['RU']!,
        en: translation['EN']!,
        th: translation['TH']!,
        enToRu: translation['EN_TO_RU']!,
        thToRu: translation['TH_TO_RU']!,
        enToTh: translation['EN_TO_TH']!,
        thToEn: translation['TH_TO_EN']!,
      );
      partialBundle = bundle;

      _emit(TranslatorRunStage.audit);

      final String auditUserPrompt = policy.buildAuditUserPrompt(bundle);

      TranslationAudit audit;

      try {
        final String auditContent = await _request(
          systemPrompt: policy.buildAuditSystemPrompt(),
          userPrompt: auditUserPrompt,
          maxTokens: _auditMaxTokens,
          temperature: _auditTemperature,
        );

        audit = _parseAudit(auditContent, bundle);
      } on _AuditFailure {
        final String repairedAuditContent = await _request(
          systemPrompt: _buildStrictAuditRetryPrompt(
            policy.buildAuditSystemPrompt(),
          ),
          userPrompt: auditUserPrompt,
          maxTokens: _auditMaxTokens,
          temperature: _auditTemperature,
        );

        try {
          audit = _parseAudit(repairedAuditContent, bundle);
        } on _AuditFailure catch (error) {
          throw _AuditFailure(
            'Ответ аудита остался некорректным после повторной попытки: '
            '${error.message}',
          );
        }
      }

      return TranslatorRunReport(
        request: request,
        bundle: bundle,
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

The previous audit response violated the required JSON protocol.
Run the semantic audit again from the supplied atomic nine-section bundle.

This is the final format attempt:
- output exactly one JSON object;
- the root object must contain only "findings";
- every finding must contain exactly eight required keys and no others;
- reason and impact must be exact ru/en/th objects;
- source_ambiguity must be null or an exact ru/en/th object;
- use only MEANING, TERMINOLOGY, STYLE or AMBIGUITY as category;
- use only RU, EN or TH as section;
- copy exact fragments from SOURCE TEXT and the named direct section;
- output no preamble, Markdown, verdict, summary or commentary.
'''
        .trim();
  }

  Future<String> _request({
    required String systemPrompt,
    required String userPrompt,
    required int maxTokens,
    required double temperature,
  }) {
    return transport.complete(
      endpoint: _endpoint,
      accessKey: accessKey.trim(),
      body: <String, Object?>{
        'model': model,
        'max_completion_tokens': maxTokens,
        'temperature': temperature,
        'frequency_penalty': 0.0,
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

      if (_placeholderValues.contains(value.toUpperCase())) {
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

  static TranslationAudit _parseAudit(
    String content,
    TranslationBundle bundle,
  ) {
    final String normalized = content.trim();

    if (normalized.isEmpty) {
      throw const _AuditFailure('Ответ аудита пуст.');
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(normalized);
    } on FormatException catch (error) {
      throw _AuditFailure('Ответ аудита не является корректным JSON: $error');
    }

    final Map<String, Object?> root = _auditObject(
      decoded,
      'Корень ответа аудита',
    );
    _requireExactAuditKeys(root, _auditRootKeys, 'Корень ответа аудита');

    final Object? rawFindings = root['findings'];

    if (rawFindings is! List<Object?>) {
      throw const _AuditFailure('Поле findings должно быть JSON-массивом.');
    }

    final List<TranslationFinding> findings = <TranslationFinding>[];

    for (int index = 0; index < rawFindings.length; index += 1) {
      findings.add(
        _parseAuditFinding(rawFindings[index], index: index, bundle: bundle),
      );
    }

    try {
      return TranslationAudit(findings: findings);
    } on ArgumentError catch (error) {
      throw _AuditFailure('Ответ аудита содержит дубли: ${error.message}');
    }
  }

  static TranslationFinding _parseAuditFinding(
    Object? value, {
    required int index,
    required TranslationBundle bundle,
  }) {
    final String name = 'findings[$index]';
    final Map<String, Object?> finding = _auditObject(value, name);
    _requireExactAuditKeys(finding, _auditFindingKeys, name);

    final String categoryCode = _auditString(
      finding['category'],
      '$name.category',
    );
    final String sectionCode = _auditString(
      finding['section'],
      '$name.section',
    );

    final TranslationFindingCategory category;
    final TranslationLanguage section;

    try {
      category = TranslationFindingCategory.fromCode(categoryCode);
      section = TranslationLanguage.fromCode(sectionCode);
    } on ArgumentError catch (error) {
      throw _AuditFailure('$name содержит неизвестный код: ${error.message}');
    }

    if (category.code != categoryCode || section.code != sectionCode) {
      throw _AuditFailure(
        '$name должен использовать точные uppercase-коды category и section.',
      );
    }

    final String sourceFragment = _auditString(
      finding['source_fragment'],
      '$name.source_fragment',
    );
    final String translationFragment = _auditString(
      finding['translation_fragment'],
      '$name.translation_fragment',
    );
    final LocalizedEvidenceText reason = _auditLocalizedText(
      finding['reason'],
      '$name.reason',
    );
    final LocalizedEvidenceText impact = _auditLocalizedText(
      finding['impact'],
      '$name.impact',
    );
    final String correctVariant = _auditString(
      finding['correct_variant'],
      '$name.correct_variant',
    );
    final LocalizedEvidenceText? sourceAmbiguity =
        finding['source_ambiguity'] == null
        ? null
        : _auditLocalizedText(
            finding['source_ambiguity'],
            '$name.source_ambiguity',
          );

    if (!bundle.sourceText.contains(sourceFragment)) {
      throw _AuditFailure('$name.source_fragment отсутствует в SOURCE TEXT.');
    }

    final String directText = switch (section) {
      TranslationLanguage.ru => bundle.ru,
      TranslationLanguage.en => bundle.en,
      TranslationLanguage.th => bundle.th,
    };

    if (!directText.contains(translationFragment)) {
      throw _AuditFailure(
        '$name.translation_fragment отсутствует в секции ${section.code}.',
      );
    }

    return TranslationFinding.multilingual(
      category: category,
      section: section,
      sourceFragment: sourceFragment,
      translationFragment: translationFragment,
      reason: reason,
      impact: impact,
      correctVariant: correctVariant,
      sourceAmbiguity: sourceAmbiguity,
    );
  }

  static LocalizedEvidenceText _auditLocalizedText(Object? value, String name) {
    final Map<String, Object?> localized = _auditObject(value, name);
    _requireExactAuditKeys(localized, _auditLocaleKeys, name);

    return LocalizedEvidenceText(
      ru: _auditString(localized['ru'], '$name.ru'),
      en: _auditString(localized['en'], '$name.en'),
      th: _auditString(localized['th'], '$name.th'),
    );
  }

  static Map<String, Object?> _auditObject(Object? value, String name) {
    if (value is! Map<Object?, Object?> ||
        value.keys.any((Object? key) => key is! String)) {
      throw _AuditFailure('$name должен быть JSON-объектом.');
    }

    return value.cast<String, Object?>();
  }

  static void _requireExactAuditKeys(
    Map<String, Object?> value,
    Set<String> expected,
    String name,
  ) {
    final Set<String> actual = value.keys.toSet();

    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw _AuditFailure('$name содержит неверный набор ключей.');
    }
  }

  static String _auditString(Object? value, String name) {
    if (value is! String || value.trim().isEmpty) {
      throw _AuditFailure('$name должен быть непустой строкой.');
    }

    if (value != value.trim()) {
      throw _AuditFailure('$name содержит внешние пробелы.');
    }

    return value;
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

  static const int _translationMaxTokens = 1400;
  static const int _auditMaxTokens = 2200;
  static const double _translationTemperature = 0.1;
  static const double _auditTemperature = 0.0;

  static final RegExp _accessKeyPattern = RegExp(r'^[\x21-\x7E]+$');

  static const List<String> _translationLabels = <String>[
    'SOURCE LANGUAGE',
    'SOURCE TEXT',
    'RU',
    'EN',
    'TH',
    'EN_TO_RU',
    'TH_TO_RU',
    'EN_TO_TH',
    'TH_TO_EN',
  ];

  static const Set<String> _auditRootKeys = <String>{'findings'};

  static const Set<String> _auditFindingKeys = <String>{
    'category',
    'section',
    'source_fragment',
    'translation_fragment',
    'reason',
    'impact',
    'correct_variant',
    'source_ambiguity',
  };

  static const Set<String> _auditLocaleKeys = <String>{'ru', 'en', 'th'};

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
