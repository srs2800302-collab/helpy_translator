import 'dart:convert';

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

    Map<String, String>? translation;
    final List<String> semanticDiagnostics = <String>[];
    final List<String> technicalDiagnostics = <String>[];

    try {
      final Map<String, String> parsedTranslation = await _requestTranslation(
        systemPrompt: _translationPrompt,
        userContent: _buildTranslationInput(
          sourceText: normalizedSourceText,
          sourceLanguageHint: normalizedSourceLanguageHint,
          engineerContext: normalizedEngineerContext,
        ),
        maxTokens: 512,
      );
      translation = parsedTranslation;

      _validateTranslationSourceLanguage(translation: parsedTranslation);
      _validateDirectTranslation(parsedTranslation);

      final String returnedSourceText = parsedTranslation['SOURCE TEXT']!;
      final String sourceLanguage = parsedTranslation['SOURCE LANGUAGE']!;
      final String sourceLanguageText = parsedTranslation[sourceLanguage]!;

      if (returnedSourceText != normalizedSourceText) {
        semanticDiagnostics.add(
          '''
Переданный исходный текст:
$normalizedSourceText

SOURCE TEXT из ответа Typhoon:
$returnedSourceText
'''
              .trim(),
        );
      }

      if (sourceLanguageText != returnedSourceText) {
        semanticDiagnostics.add(
          '''
Секция исходного языка $sourceLanguage из ответа Typhoon:
$sourceLanguageText

SOURCE TEXT из ответа Typhoon:
$returnedSourceText
'''
              .trim(),
        );
      }

      final Map<String, String> reverseTranslation =
          await _requestReverseTranslation(
            en: parsedTranslation['EN']!,
            th: parsedTranslation['TH']!,
            maxTokens: 512,
          );

      final Map<String, String> completeTranslation = <String, String>{
        ...parsedTranslation,
        ...reverseTranslation,
      };

      translation = completeTranslation;
      _validateCompleteTranslation(completeTranslation);

      final String auditContent = await _requestContent(
        systemPrompt: _auditPrompt,
        userContent: _buildAuditInput(completeTranslation),
        maxTokens: 512,
      );

      final Map<String, String> audit = _parseStrictSections(
        content: auditContent,
        labels: _auditLabels,
        responseName: 'Ответ независимого аудита',
        diagnostics: technicalDiagnostics,
      );

      _validateAudit(audit);

      final String auditComment = _buildComment(audit);
      final List<String> diagnostics = <String>[
        ...technicalDiagnostics,
        ...semanticDiagnostics,
      ];
      final String comment = diagnostics.isEmpty
          ? auditComment
          : '${diagnostics.join('\n\n')}\n\n$auditComment';

      return TranslatorPhraseResult(
        sourceLanguage: completeTranslation['SOURCE LANGUAGE']!,
        sourceText: completeTranslation['SOURCE TEXT']!,
        status: semanticDiagnostics.isEmpty
            ? _resolveStatus(audit)
            : TranslatorPhraseStatus.canonicalDrift,
        ru: completeTranslation['RU'],
        en: completeTranslation['EN'],
        th: completeTranslation['TH'],
        enToRu: completeTranslation['EN_TO_RU'],
        thToRu: completeTranslation['TH_TO_RU'],
        enToTh: completeTranslation['EN_TO_TH'],
        thToEn: completeTranslation['TH_TO_EN'],
        comment: comment,
      );
    } on DioException catch (error) {
      return _failedResult(
        submittedSourceText: normalizedSourceText,
        sourceLanguageHint: normalizedSourceLanguageHint,
        translation: translation,
        diagnostics: <String>[...technicalDiagnostics, ...semanticDiagnostics],
        comment: _mapDioError(error),
      );
    } on FormatException catch (error) {
      return _failedResult(
        submittedSourceText: normalizedSourceText,
        sourceLanguageHint: normalizedSourceLanguageHint,
        translation: translation,
        diagnostics: <String>[...technicalDiagnostics, ...semanticDiagnostics],
        comment: error.message,
      );
    }
  }

  Future<Map<String, String>> _requestTranslation({
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
        'tools': _translationTools,
      },
    );

    return _extractTranslationArguments(response.data);
  }

  Future<Map<String, String>> _requestReverseTranslation({
    required String en,
    required String th,
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
          <String, String>{
            'role': 'system',
            'content': _reverseTranslationPrompt,
          },
          <String, String>{
            'role': 'user',
            'content': _buildReverseTranslationInput(en: en, th: th),
          },
        ],
        'tools': _reverseTranslationTools,
      },
    );

    return _extractReverseTranslationArguments(response.data);
  }

  Future<String> _requestContent({
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
    required String submittedSourceText,
    required String? sourceLanguageHint,
    required String comment,
    Map<String, String>? translation,
    required List<String> diagnostics,
  }) {
    final String combinedComment = diagnostics.isEmpty
        ? comment
        : '${diagnostics.join('\n\n')}\n\n$comment';

    return TranslatorPhraseResult(
      sourceLanguage:
          translation?['SOURCE LANGUAGE'] ?? sourceLanguageHint ?? 'unknown',
      sourceText: translation?['SOURCE TEXT'] ?? submittedSourceText,
      status: TranslatorPhraseStatus.failed,
      ru: translation?['RU'],
      en: translation?['EN'],
      th: translation?['TH'],
      enToRu: translation?['EN_TO_RU'],
      thToRu: translation?['TH_TO_RU'],
      enToTh: translation?['EN_TO_TH'],
      thToEn: translation?['TH_TO_EN'],
      comment: combinedComment,
    );
  }

  static String _buildTranslationInput({
    required String sourceText,
    required String? sourceLanguageHint,
    required String? engineerContext,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Source text:')
      ..writeln('"$sourceText"');

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

  static String _buildReverseTranslationInput({
    required String en,
    required String th,
  }) {
    return '''
EN:
$en

TH:
$th
'''
        .trim();
  }

  static String _buildAuditInput(Map<String, String> translation) {
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < _translationLabels.length; index++) {
      final String label = _translationLabels[index];

      if (index > 0) {
        buffer.writeln();
      }

      buffer
        ..writeln('$label:')
        ..writeln(translation[label]);
    }

    return buffer.toString().trim();
  }

  static Map<String, String> _parseStrictSections({
    required String content,
    required List<String> labels,
    required String responseName,
    List<String>? diagnostics,
  }) {
    final String normalized = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    if (normalized.isEmpty) {
      throw FormatException('$responseName пуст.');
    }

    final List<RegExpMatch> matches = _labelPattern
        .allMatches(normalized)
        .toList(growable: false);

    if (matches.isEmpty) {
      throw FormatException('$responseName не содержит обязательных секций.');
    }

    final String preamble = normalized.substring(0, matches.first.start).trim();

    if (preamble.isNotEmpty) {
      diagnostics?.add(
        '''
$responseName содержит технический текст до первой обязательной секции:
$preamble
'''
            .trim(),
      );
    }

    final List<String> actualLabels = matches
        .map<String>((RegExpMatch match) => match.group(1)!)
        .toList(growable: false);
    final Set<String> seenLabels = <String>{};

    for (final String label in actualLabels) {
      if (!seenLabels.add(label)) {
        throw FormatException(
          '$responseName содержит дублированную секцию $label.',
        );
      }

      if (!labels.contains(label)) {
        throw FormatException(
          '$responseName содержит неожиданную секцию $label.',
        );
      }
    }

    for (final String label in labels) {
      if (!seenLabels.contains(label)) {
        throw FormatException(
          '$responseName не содержит обязательную секцию $label.',
        );
      }
    }

    if (actualLabels.length != labels.length) {
      throw FormatException(
        '$responseName содержит неверное количество секций.',
      );
    }

    for (int index = 0; index < labels.length; index++) {
      if (actualLabels[index] != labels[index]) {
        throw FormatException(
          '$responseName содержит секции в неверном порядке.',
        );
      }
    }

    final Map<String, String> result = <String, String>{};

    for (int index = 0; index < labels.length; index++) {
      final int valueStart = matches[index].end;
      final int valueEnd = index + 1 < matches.length
          ? matches[index + 1].start
          : normalized.length;
      final String label = labels[index];
      final String value = normalized.substring(valueStart, valueEnd).trim();

      _validateSectionValue(
        responseName: responseName,
        label: label,
        value: value,
      );
      result[label] = value;
    }

    return result;
  }

  static void _validateSectionValue({
    required String responseName,
    required String label,
    required String value,
  }) {
    if (value.isEmpty) {
      throw FormatException('$responseName содержит пустую секцию $label.');
    }

    if (_placeholderValues.contains(value.toUpperCase())) {
      throw FormatException(
        '$responseName содержит значение-заглушку в секции $label.',
      );
    }
  }

  static void _validateTranslationSourceLanguage({
    required Map<String, String> translation,
  }) {
    final String sourceLanguage = translation['SOURCE LANGUAGE']!;

    if (!_sourceLanguages.contains(sourceLanguage)) {
      throw const FormatException(
        'SOURCE LANGUAGE должен содержать только RU, EN или TH.',
      );
    }
  }

  static void _validateDirectTranslation(Map<String, String> translation) {
    if (translation.length != _translationArgumentLabels.length) {
      throw const FormatException(
        'Прямой результат перевода должен содержать ровно пять секций.',
      );
    }

    for (final String label in _translationArgumentLabels.values) {
      final String? value = translation[label];

      if (value == null) {
        throw FormatException(
          'Прямой результат перевода не содержит секцию $label.',
        );
      }

      _validateSectionValue(
        responseName: 'Прямой результат перевода',
        label: label,
        value: value,
      );
    }
  }

  static void _validateCompleteTranslation(Map<String, String> translation) {
    if (translation.length != _translationLabels.length) {
      throw const FormatException(
        'Полный результат перевода должен содержать ровно девять секций.',
      );
    }

    for (final String label in _translationLabels) {
      final String? value = translation[label];

      if (value == null) {
        throw FormatException(
          'Полный результат перевода не содержит секцию $label.',
        );
      }

      _validateSectionValue(
        responseName: 'Полный результат перевода',
        label: label,
        value: value,
      );
    }
  }

  static void _validateAudit(Map<String, String> audit) {
    for (final String label in _auditDecisionLabels) {
      final String value = audit[label]!.toUpperCase();

      if (value != 'YES' && value != 'NO') {
        throw FormatException(
          'Секция аудита $label должна содержать только YES или NO.',
        );
      }
    }

    if (!_russianLetterPattern.hasMatch(audit['REASON']!)) {
      throw const FormatException(
        'Секция аудита REASON должна содержать объяснение на русском языке.',
      );
    }
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
Meaning preserved: ${audit['MEANING_PRESERVED']}
Terminology preserved: ${audit['TERMINOLOGY_PRESERVED']}
Canonical style preserved: ${audit['CANONICAL_STYLE_PRESERVED']}
Ambiguous wording: ${audit['AMBIGUOUS_WORDING']}

${audit['REASON']}
'''
        .trim();
  }

  static Map<String, String> _extractTranslationArguments(Object? data) {
    return _extractToolArguments(
      data: data,
      expectedToolName: _translationToolName,
      argumentLabels: _translationArgumentLabels,
      responseName: 'Ответ прямого перевода',
    );
  }

  static Map<String, String> _extractReverseTranslationArguments(Object? data) {
    return _extractToolArguments(
      data: data,
      expectedToolName: _reverseTranslationToolName,
      argumentLabels: _reverseTranslationArgumentLabels,
      responseName: 'Ответ независимого обратного перевода',
    );
  }

  static Map<String, String> _extractToolArguments({
    required Object? data,
    required String expectedToolName,
    required Map<String, String> argumentLabels,
    required String responseName,
  }) {
    final Map<String, dynamic> message = _extractMessage(data);
    final Object? toolCalls = message['tool_calls'];

    if (toolCalls is! List<dynamic> || toolCalls.length != 1) {
      throw FormatException(
        '$responseName должен содержать ровно один tool call.',
      );
    }

    final Object? toolCall = toolCalls.single;

    if (toolCall is! Map<String, dynamic>) {
      throw FormatException('$responseName содержит некорректный tool call.');
    }

    final Object? function = toolCall['function'];

    if (function is! Map<String, dynamic>) {
      throw FormatException('$responseName tool call не содержит функцию.');
    }

    if (function['name'] != expectedToolName) {
      throw FormatException('$responseName содержит неожиданную function.');
    }

    final Object? rawArguments = function['arguments'];

    if (rawArguments is! String || rawArguments.trim().isEmpty) {
      throw FormatException('$responseName tool call не содержит arguments.');
    }

    final Object? decodedArguments;

    try {
      decodedArguments = jsonDecode(rawArguments);
    } on FormatException {
      throw FormatException(
        '$responseName tool arguments содержат некорректный JSON.',
      );
    }

    if (decodedArguments is! Map<String, dynamic>) {
      throw FormatException(
        '$responseName tool arguments должны быть JSON object.',
      );
    }

    for (final String key in argumentLabels.keys) {
      if (!decodedArguments.containsKey(key)) {
        throw FormatException(
          '$responseName tool arguments не содержат обязательный ключ $key.',
        );
      }
    }

    for (final String key in decodedArguments.keys) {
      if (!argumentLabels.containsKey(key)) {
        throw FormatException(
          '$responseName tool arguments содержат неожиданный ключ $key.',
        );
      }
    }

    final Map<String, String> result = <String, String>{};

    for (final MapEntry<String, String> entry in argumentLabels.entries) {
      final Object? rawValue = decodedArguments[entry.key];

      if (rawValue is! String) {
        throw FormatException(
          '$responseName tool argument ${entry.key} должен быть строкой.',
        );
      }

      final String value = rawValue.trim();

      _validateSectionValue(
        responseName: responseName,
        label: entry.value,
        value: value,
      );

      result[entry.value] = value;
    }

    return result;
  }

  static Map<String, dynamic> _extractMessage(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Некорректный ответ Typhoon API.');
    }

    final Object? choices = data['choices'];

    if (choices is! List<dynamic> || choices.isEmpty) {
      throw const FormatException('Ответ Typhoon API не содержит результат.');
    }

    final Object? firstChoice = choices.first;

    if (firstChoice is! Map<String, dynamic>) {
      throw const FormatException('Некорректный формат ответа Typhoon API.');
    }

    final Object? message = firstChoice['message'];

    if (message is! Map<String, dynamic>) {
      throw const FormatException('Ответ Typhoon API не содержит сообщение.');
    }

    return message;
  }

  static String _extractContent(Object? data) {
    final Map<String, dynamic> message = _extractMessage(data);
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

  static final RegExp _labelPattern = RegExp(
    r'^([A-Z][A-Z0-9 _]*):[ \t]*$',
    multiLine: true,
  );
  static final RegExp _russianLetterPattern = RegExp(r'[А-Яа-яЁё]');

  static const Set<String> _sourceLanguages = <String>{'RU', 'EN', 'TH'};
  static const Set<String> _placeholderValues = <String>{
    '-',
    'N/A',
    'NONE',
    'NULL',
    'UNKNOWN',
    'NOT PROVIDED',
  };

  static const String _translationToolName = 'submit_translation';
  static const String _reverseTranslationToolName =
      'submit_reverse_translation';

  static const Map<String, String> _translationArgumentLabels =
      <String, String>{
        'source_language': 'SOURCE LANGUAGE',
        'source_text': 'SOURCE TEXT',
        'ru': 'RU',
        'en': 'EN',
        'th': 'TH',
      };

  static const Map<String, String> _reverseTranslationArgumentLabels =
      <String, String>{
        'en_to_ru': 'EN_TO_RU',
        'en_to_th': 'EN_TO_TH',
        'th_to_ru': 'TH_TO_RU',
        'th_to_en': 'TH_TO_EN',
      };

  static const List<Map<String, Object>> _translationTools =
      <Map<String, Object>>[
        <String, Object>{
          'type': 'function',
          'function': <String, Object>{
            'name': _translationToolName,
            'description':
                'Submit the source identity and direct RU, EN and TH '
                'translations.',
            'parameters': <String, Object>{
              'type': 'object',
              'properties': <String, Object>{
                'source_language': <String, Object>{
                  'type': 'string',
                  'enum': <String>['RU', 'EN', 'TH'],
                  'description': 'Exactly one detected source-language code.',
                },
                'source_text': <String, Object>{
                  'type': 'string',
                  'description':
                      'The original source text exactly as supplied. The field '
                      'matching source_language must repeat this exact value.',
                },
                'ru': <String, Object>{
                  'type': 'string',
                  'description': 'Natural Russian translation.',
                },
                'en': <String, Object>{
                  'type': 'string',
                  'description': 'Natural English translation.',
                },
                'th': <String, Object>{
                  'type': 'string',
                  'description': 'Natural Thai translation.',
                },
              },
              'required': <String>[
                'source_language',
                'source_text',
                'ru',
                'en',
                'th',
              ],
              'additionalProperties': false,
            },
          },
        },
      ];

  static const List<Map<String, Object>> _reverseTranslationTools =
      <Map<String, Object>>[
        <String, Object>{
          'type': 'function',
          'function': <String, Object>{
            'name': _reverseTranslationToolName,
            'description':
                'Submit independent translations derived only from the '
                'supplied EN and TH texts.',
            'parameters': <String, Object>{
              'type': 'object',
              'properties': <String, Object>{
                'en_to_ru': <String, Object>{
                  'type': 'string',
                  'description': 'Literal translation of EN into Russian.',
                },
                'en_to_th': <String, Object>{
                  'type': 'string',
                  'description': 'Literal translation of EN into Thai.',
                },
                'th_to_ru': <String, Object>{
                  'type': 'string',
                  'description': 'Literal translation of TH into Russian.',
                },
                'th_to_en': <String, Object>{
                  'type': 'string',
                  'description': 'Literal translation of TH into English.',
                },
              },
              'required': <String>[
                'en_to_ru',
                'en_to_th',
                'th_to_ru',
                'th_to_en',
              ],
              'additionalProperties': false,
            },
          },
        },
      ];

  static const List<String> _translationLabels = <String>[
    'SOURCE LANGUAGE',
    'SOURCE TEXT',
    'RU',
    'EN',
    'TH',
    'EN_TO_RU',
    'EN_TO_TH',
    'TH_TO_RU',
    'TH_TO_EN',
  ];
  static const List<String> _auditDecisionLabels = <String>[
    'MEANING_PRESERVED',
    'TERMINOLOGY_PRESERVED',
    'CANONICAL_STYLE_PRESERVED',
    'AMBIGUOUS_WORDING',
  ];
  static const List<String> _auditLabels = <String>[
    ..._auditDecisionLabels,
    'REASON',
  ];

  static const String _translationPrompt = '''
You are Helpy strict multilingual translator.

Input can be RU, EN or TH.
Detect source language.
Translate directly into RU, EN and TH.
The section matching SOURCE LANGUAGE must repeat SOURCE TEXT exactly.

Treat ENGINEER CONTEXT only as diagnostic context.
Never use it to repair, clarify, disambiguate or add meaning to SOURCE TEXT.

Do not perform reverse translations.
Do not audit.
Do not explain.
Do not improve wording.
Preserve business meaning and service-marketplace terminology.

Call submit_translation exactly once with all required values.
''';

  static const String _reverseTranslationPrompt = '''
You are an independent strict multilingual reverse translator.

Input contains only completed EN and TH direct translations.
Do not infer or reconstruct an original source phrase.
Do not use missing source context.

Translate EN literally into RU and TH.
Translate TH literally into RU and EN.

Do not audit.
Do not explain.
Do not improve, repair or harmonize meaning.
Expose the meaning actually present in each supplied text.

Call submit_reverse_translation exactly once with all required values.
''';

  static const String _auditPrompt = '''
Ты являешься независимым аудитором мультиязычных инженерных формулировок Registry Studio.

Ты не выполняешь перевод.
Ты не переписываешь формулировки.
Ты проверяешь только полный набор из 9 секций.

Секции дословного обратного перевода являются диагностическими сигналами, но не доказательством точности.
Главными фактическими результатами являются SOURCE TEXT и прямые секции RU, EN и TH с учётом SOURCE LANGUAGE.
Секция, соответствующая SOURCE LANGUAGE, должна дословно совпадать с SOURCE TEXT.
Используй остальные две языковые секции, чтобы определить фактически переданный смысл.

Проверь:

1. Сохранили ли RU, EN и TH один инженерный смысл.
2. Осталась ли техническая и реестровая терминология точной.
3. Сохранилась ли сила инструкции.
4. Изменилась ли обязательность, допустимость или запрещённость действия.
5. Изменилось ли отрицание.
6. Изменились ли границы работ или исключения.
7. Изменились ли количества, единицы измерения, условия или последовательность.
8. Стал ли конкретный термин более широким, мягким или менее точным.
9. Появилась ли неоднозначность.
10. Показывают ли дословные обратные переводы смысловой drift.

Правила аудита:

1. Если смысл изменился, установи MEANING_PRESERVED в NO.
2. Если терминология стала менее точной, установи TERMINOLOGY_PRESERVED в NO.
3. Если изменилась сила инструкции или инструктивная форма, установи CANONICAL_STYLE_PRESERVED в NO.
4. Если формулировка допускает несколько значимых для registry толкований, установи AMBIGUOUS_WORDING в YES.
5. Несовпадение прямой версии и дословного обратного перевода считай основанием для строгой проверки.
6. Не трактуй сомнения в пользу корректности.
7. Не улучшай формулировки.
8. Не предлагай замену.
9. Не утверждай публикацию.
10. Не предлагай изменение registry.
11. Не используй символы направления в ответе.

Ты обязан вернуть ровно 5 секций.
Все секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.

Верни результат строго с этими ASCII labels:

MEANING_PRESERVED:
YES | NO

TERMINOLOGY_PRESERVED:
YES | NO

CANONICAL_STYLE_PRESERVED:
YES | NO

AMBIGUOUS_WORDING:
YES | NO

REASON:
краткое объяснение на русском языке с указанием конкретных различий
''';
}
