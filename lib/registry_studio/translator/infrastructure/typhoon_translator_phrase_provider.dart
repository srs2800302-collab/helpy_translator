import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../application/translator_phrase_provider.dart';
import '../translator_phrase_result.dart';
import '../translator_phrase_status.dart';

final class TyphoonTranslatorPhraseProvider
    implements TranslatorPhraseProvider {
  const TyphoonTranslatorPhraseProvider({
    required this.apiClient,
    required this.appConfig,
  });

  final ApiClient apiClient;
  final AppConfig appConfig;

  @override
  Future<TranslatorPhraseResult> translatePhrase({
    required String sourceText,
    String? sourceLanguageHint,
    String? engineerContext,
  }) async {
    final String normalizedSourceText = _requiredText(
      sourceText,
      'sourceText',
      'Translator phrase source text must not be empty.',
    );
    final String? normalizedSourceLanguageHint = _optionalText(
      sourceLanguageHint,
    );
    final String? normalizedEngineerContext = _optionalText(engineerContext);

    try {
      final String translationContent = await _request(
        systemPrompt: _translationPrompt,
        userContent: _buildTranslationInput(
          sourceText: normalizedSourceText,
          sourceLanguageHint: normalizedSourceLanguageHint,
          engineerContext: normalizedEngineerContext,
        ),
        maxTokens: 700,
      );

      final Map<String, String> translation = _parseSections(
        translationContent,
        _translationLabels,
      );

      final String auditContent = await _request(
        systemPrompt: _auditPrompt,
        userContent: _buildAuditInput(
          translation: translation,
          engineerContext: normalizedEngineerContext,
        ),
        maxTokens: 500,
      );

      final Map<String, String> audit = _parseSections(
        auditContent,
        _auditLabels,
      );

      return TranslatorPhraseResult(
        sourceLanguage: _valueOrFallback(
          translation['SOURCE LANGUAGE'],
          normalizedSourceLanguageHint ?? 'unknown',
        ),
        sourceText: _valueOrFallback(
          translation['SOURCE TEXT'],
          normalizedSourceText,
        ),
        status: _resolveStatus(audit),
        ru: translation['RU'],
        en: translation['EN'],
        th: translation['TH'],
        enToRu: translation['EN_TO_RU'],
        thToRu: translation['TH_TO_RU'],
        enToTh: translation['EN_TO_TH'],
        thToEn: translation['TH_TO_EN'],
        comment: _buildComment(audit),
      );
    } on DioException catch (error) {
      return _failedResult(
        sourceText: normalizedSourceText,
        sourceLanguageHint: normalizedSourceLanguageHint,
        comment: _mapDioError(error),
      );
    } on FormatException catch (error) {
      return _failedResult(
        sourceText: normalizedSourceText,
        sourceLanguageHint: normalizedSourceLanguageHint,
        comment: error.message,
      );
    }
  }

  Future<String> _request({
    required String systemPrompt,
    required String userContent,
    required int maxTokens,
  }) async {
    final Response<dynamic> response = await apiClient.dio.post<dynamic>(
      '/chat/completions',
      data: <String, Object>{
        'model': appConfig.typhoonModel,
        'max_completion_tokens': maxTokens,
        'temperature': 0.0,
        'top_p': 1.0,
        'frequency_penalty': 0.0,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'system', 'content': systemPrompt},
          <String, String>{'role': 'user', 'content': userContent},
        ],
      },
    );

    return _extractContent(response.data);
  }

  static TranslatorPhraseResult _failedResult({
    required String sourceText,
    required String? sourceLanguageHint,
    required String comment,
  }) {
    return TranslatorPhraseResult(
      sourceLanguage: sourceLanguageHint ?? 'unknown',
      sourceText: sourceText,
      status: TranslatorPhraseStatus.failed,
      comment: comment,
    );
  }

  static String _buildTranslationInput({
    required String sourceText,
    required String? sourceLanguageHint,
    required String? engineerContext,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('SOURCE TEXT:')
      ..writeln(sourceText);

    if (sourceLanguageHint != null) {
      buffer
        ..writeln()
        ..writeln('SOURCE LANGUAGE HINT:')
        ..writeln(sourceLanguageHint);
    }

    if (engineerContext != null) {
      buffer
        ..writeln()
        ..writeln('ENGINEER CONTEXT:')
        ..writeln(engineerContext);
    }

    return buffer.toString().trim();
  }

  static String _buildAuditInput({
    required Map<String, String> translation,
    required String? engineerContext,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('SOURCE LANGUAGE:')
      ..writeln(translation['SOURCE LANGUAGE'] ?? '')
      ..writeln()
      ..writeln('SOURCE TEXT:')
      ..writeln(translation['SOURCE TEXT'] ?? '')
      ..writeln()
      ..writeln('RU:')
      ..writeln(translation['RU'] ?? '')
      ..writeln()
      ..writeln('EN:')
      ..writeln(translation['EN'] ?? '')
      ..writeln()
      ..writeln('TH:')
      ..writeln(translation['TH'] ?? '')
      ..writeln()
      ..writeln('EN_TO_RU:')
      ..writeln(translation['EN_TO_RU'] ?? '')
      ..writeln()
      ..writeln('TH_TO_RU:')
      ..writeln(translation['TH_TO_RU'] ?? '')
      ..writeln()
      ..writeln('EN_TO_TH:')
      ..writeln(translation['EN_TO_TH'] ?? '')
      ..writeln()
      ..writeln('TH_TO_EN:')
      ..writeln(translation['TH_TO_EN'] ?? '');

    if (engineerContext != null) {
      buffer
        ..writeln()
        ..writeln('ENGINEER CONTEXT:')
        ..writeln(engineerContext);
    }

    return buffer.toString().trim();
  }

  static Map<String, String> _parseSections(
    String content,
    List<String> labels,
  ) {
    final Map<String, String> result = <String, String>{};

    for (int index = 0; index < labels.length; index++) {
      final String label = labels[index];
      final String marker = '$label:';
      final int start = content.indexOf(marker);

      if (start == -1) {
        result[label] = '';
        continue;
      }

      final int valueStart = start + marker.length;
      int valueEnd = content.length;

      for (int nextIndex = index + 1; nextIndex < labels.length; nextIndex++) {
        final int nextStart = content.indexOf(
          '${labels[nextIndex]}:',
          valueStart,
        );

        if (nextStart != -1) {
          valueEnd = nextStart;
          break;
        }
      }

      result[label] = content.substring(valueStart, valueEnd).trim();
    }

    return result;
  }

  static TranslatorPhraseStatus _resolveStatus(Map<String, String> audit) {
    final bool meaningPreserved = _isYes(audit['MEANING_PRESERVED']);
    final bool terminologyPreserved = _isYes(audit['TERMINOLOGY_PRESERVED']);
    final bool canonicalStylePreserved = _isYes(
      audit['CANONICAL_STYLE_PRESERVED'],
    );
    final bool ambiguousWording = _isYes(audit['AMBIGUOUS_WORDING']);

    if (!meaningPreserved) {
      return TranslatorPhraseStatus.canonicalDrift;
    }

    if (meaningPreserved &&
        terminologyPreserved &&
        canonicalStylePreserved &&
        !ambiguousWording) {
      return TranslatorPhraseStatus.exact;
    }

    if (meaningPreserved && terminologyPreserved && !ambiguousWording) {
      return TranslatorPhraseStatus.equivalent;
    }

    return TranslatorPhraseStatus.needsReview;
  }

  static String _buildComment(Map<String, String> audit) {
    return '''
Meaning preserved: ${audit['MEANING_PRESERVED'] ?? 'NO'}
Terminology preserved: ${audit['TERMINOLOGY_PRESERVED'] ?? 'NO'}
Canonical style preserved: ${audit['CANONICAL_STYLE_PRESERVED'] ?? 'NO'}
Ambiguous wording: ${audit['AMBIGUOUS_WORDING'] ?? 'YES'}

${audit['REASON'] ?? ''}
'''
        .trim();
  }

  static String _extractContent(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Некорректный ответ Typhoon API.');
    }

    final Object? choices = data['choices'];

    if (choices is! List<dynamic> || choices.isEmpty) {
      throw const FormatException('Ответ Typhoon API не содержит перевод.');
    }

    final Object? firstChoice = choices.first;

    if (firstChoice is! Map<String, dynamic>) {
      throw const FormatException('Некорректный формат ответа Typhoon API.');
    }

    final Object? message = firstChoice['message'];

    if (message is! Map<String, dynamic>) {
      throw const FormatException('Ответ Typhoon API не содержит сообщение.');
    }

    final Object? content = message['content'];

    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('Ответ Typhoon API пустой.');
    }

    return content;
  }

  static String _mapDioError(DioException error) {
    final int? statusCode = error.response?.statusCode;

    if (statusCode == 401) {
      return 'Ошибка авторизации Typhoon API. Проверьте API key.';
    }

    if (statusCode == 429) {
      return 'Превышен лимит запросов Typhoon API.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'Ошибка сервера Typhoon API. Повторите позже.';
    }

    return 'Ошибка соединения с Typhoon API.';
  }

  static bool _isYes(String? value) {
    return value?.trim().toUpperCase() == 'YES';
  }

  static String _requiredText(String value, String name, String message) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, message);
    }

    return normalized;
  }

  static String? _optionalText(String? value) {
    if (value == null) {
      return null;
    }

    final String normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static String _valueOrFallback(String? value, String fallback) {
    return _optionalText(value) ?? fallback;
  }

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

  static const List<String> _auditLabels = <String>[
    'MEANING_PRESERVED',
    'TERMINOLOGY_PRESERVED',
    'CANONICAL_STYLE_PRESERVED',
    'AMBIGUOUS_WORDING',
    'REASON',
  ];

  static const String _translationPrompt = '''
You are Registry Studio strict multilingual translator.

Input can be RU, EN or TH.
Detect source language.
Use source language hint only as a hint when present.
Translate into RU, EN and TH.
Then perform cross-language reverse translations.

Do not audit.
Do not explain.
Do not approve canonical wording.
Do not change registry.
Preserve engineering meaning, instruction force and registry terminology.

Output strictly:

SOURCE LANGUAGE:
RU | EN | TH

SOURCE TEXT:
...

RU:
...

EN:
...

TH:
...

EN_TO_RU:
...

TH_TO_RU:
...

EN_TO_TH:
...

TH_TO_EN:
...
''';

  static const String _auditPrompt = '''
You are an independent Registry Studio canonical wording auditor.

You do not translate.
You only audit the provided multilingual translation set.

Check:
- Did all language versions preserve the same engineering meaning?
- Did terminology remain precise?
- Did canonical instructional style remain stable?
- Did any ambiguity appear?

Rules:
- If meaning changed: MEANING_PRESERVED = NO.
- If specific terminology became broader or softer: TERMINOLOGY_PRESERVED = NO.
- If instruction became description or style changed: CANONICAL_STYLE_PRESERVED = NO.
- If wording can be interpreted in more than one registry-relevant way: AMBIGUOUS_WORDING = YES.
- Be strict. Do not give benefit of doubt.
- Do not approve publication.
- Do not suggest registry mutation.

Output strictly:

MEANING_PRESERVED:
YES | NO

TERMINOLOGY_PRESERVED:
YES | NO

CANONICAL_STYLE_PRESERVED:
YES | NO

AMBIGUOUS_WORDING:
YES | NO

REASON:
Short Russian explanation.
''';
}
