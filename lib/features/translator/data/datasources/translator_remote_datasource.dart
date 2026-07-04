import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/translation_result_model.dart';

abstract interface class TranslatorRemoteDataSource {
  Future<TranslationResultModel> translate(String sentence);
}

final class TranslatorRemoteDataSourceImpl implements TranslatorRemoteDataSource {
  const TranslatorRemoteDataSourceImpl({
    required this.apiClient,
    required this.appConfig,
  });

  final ApiClient apiClient;
  final AppConfig appConfig;

  @override
  Future<TranslationResultModel> translate(String sentence) async {
    final String normalizedSentence = sentence.trim();

    if (normalizedSentence.isEmpty) {
      throw const AppException('Введите текст для перевода.');
    }

    try {
      final String translationContent = await _request(
        systemPrompt: _translationPrompt,
        userContent: 'Source text:\n"$normalizedSentence"',
        maxTokens: 700,
      );

      final Map<String, String> translation =
          _parseSections(translationContent, _translationLabels);

      final String auditContent = await _request(
        systemPrompt: _auditPrompt,
        userContent: _buildAuditInput(translation),
        maxTokens: 500,
      );

      final Map<String, String> audit =
          _parseSections(auditContent, _auditLabels);

      final String verdict = _resolveVerdict(audit);
      final String comment = _buildComment(audit);

      return TranslationResultModel(
        sourceLanguage: translation['SOURCE LANGUAGE'] ?? 'UNKNOWN',
        sourceText: translation['SOURCE TEXT'] ?? normalizedSentence,
        ru: translation['RU'] ?? '',
        en: translation['EN'] ?? '',
        th: translation['TH'] ?? '',
        enToRu: translation['EN_TO_RU'] ?? '',
        thToRu: translation['TH_TO_RU'] ?? '',
        enToTh: translation['EN_TO_TH'] ?? '',
        thToEn: translation['TH_TO_EN'] ?? '',
        canonicalVerdict: verdict,
        canonicalComment: comment,
      );
    } on DioException catch (error) {
      throw AppException(_mapDioError(error));
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
        'temperature': 0.1,
        'top_p': 0.7,
        'frequency_penalty': 0.0,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'system',
            'content': systemPrompt,
          },
          <String, String>{
            'role': 'user',
            'content': userContent,
          },
        ],
      },
    );

    return _extractContent(response.data);
  }

  static String _buildAuditInput(Map<String, String> translation) {
    return '''
SOURCE LANGUAGE:
${translation['SOURCE LANGUAGE'] ?? ''}

SOURCE TEXT:
${translation['SOURCE TEXT'] ?? ''}

RU:
${translation['RU'] ?? ''}

EN:
${translation['EN'] ?? ''}

TH:
${translation['TH'] ?? ''}

EN_TO_RU:
${translation['EN_TO_RU'] ?? ''}

TH_TO_RU:
${translation['TH_TO_RU'] ?? ''}

EN_TO_TH:
${translation['EN_TO_TH'] ?? ''}

TH_TO_EN:
${translation['TH_TO_EN'] ?? ''}
'''.trim();
  }

  static String _resolveVerdict(Map<String, String> audit) {
    final bool meaning = _isYes(audit['MEANING_PRESERVED']);
    final bool terminology = _isYes(audit['TERMINOLOGY_PRESERVED']);
    final bool style = _isYes(audit['CANONICAL_STYLE_PRESERVED']);
    final bool ambiguous = _isYes(audit['AMBIGUOUS_WORDING']);

    if (!meaning) {
      return 'CANONICAL_DRIFT';
    }

    if (meaning && terminology && style && !ambiguous) {
      return 'EXACT';
    }

    if (meaning && terminology && !ambiguous) {
      return 'EQUIVALENT';
    }

    return 'NEEDS_REVIEW';
  }

  static String _buildComment(Map<String, String> audit) {
    return '''
Meaning preserved: ${audit['MEANING_PRESERVED'] ?? 'NO'}
Terminology preserved: ${audit['TERMINOLOGY_PRESERVED'] ?? 'NO'}
Canonical style preserved: ${audit['CANONICAL_STYLE_PRESERVED'] ?? 'NO'}
Ambiguous wording: ${audit['AMBIGUOUS_WORDING'] ?? 'YES'}

${audit['REASON'] ?? ''}
'''.trim();
  }

  static bool _isYes(String? value) {
    return value?.trim().toUpperCase() == 'YES';
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
        final int nextStart = content.indexOf('${labels[nextIndex]}:', valueStart);
        if (nextStart != -1) {
          valueEnd = nextStart;
          break;
        }
      }

      result[label] = content.substring(valueStart, valueEnd).trim();
    }

    return result;
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
You are Helpy strict multilingual translator.

Input can be RU, EN or TH.
Detect source language.
Translate into RU, EN and TH.
Then perform cross-language reverse translations.

Do not audit.
Do not explain.
Do not improve wording.
Preserve business meaning and service-marketplace terminology.

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
You are an independent Helpy canonical translation auditor.

You do not translate.
You only audit the provided multilingual translation set.

Judge strictly for a home-services marketplace.

Check:
- Did all language versions preserve the same business meaning?
- Did terminology remain precise?
- Did canonical instructional style remain stable?
- Did any ambiguity appear?

Rules:
- If meaning changed: MEANING PRESERVED = NO.
- If specific terminology became broader or softer: TERMINOLOGY PRESERVED = NO.
- If instruction became description or style changed: CANONICAL STYLE PRESERVED = NO.
- If wording can be interpreted in more than one business-relevant way: AMBIGUOUS WORDING = YES.
- Be strict. Do not give benefit of doubt.

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

  static String _extractContent(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const AppException('Некорректный ответ сервера.');
    }

    final Object? choices = data['choices'];

    if (choices is! List<dynamic> || choices.isEmpty) {
      throw const AppException('Ответ сервера не содержит перевод.');
    }

    final Object? firstChoice = choices.first;

    if (firstChoice is! Map<String, dynamic>) {
      throw const AppException('Некорректный формат ответа сервера.');
    }

    final Object? message = firstChoice['message'];

    if (message is! Map<String, dynamic>) {
      throw const AppException('Ответ сервера не содержит сообщение.');
    }

    final Object? content = message['content'];

    if (content is! String || content.trim().isEmpty) {
      throw const AppException('Ответ сервера пустой.');
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
}
