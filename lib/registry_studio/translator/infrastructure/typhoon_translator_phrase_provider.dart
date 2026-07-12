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
  }) async {
    final String normalizedSourceText = _requiredText(
      sourceText,
      'sourceText',
      'Translator phrase source text must not be empty.',
    );
    Map<String, String>? translation;
    final List<String> semanticDiagnostics = <String>[];
    final List<String> technicalDiagnostics = <String>[];

    try {
      final Map<String, String> parsedTranslation = await _requestTranslation(
        systemPrompt: _translationPrompt,
        userContent: _buildTranslationInput(sourceText: normalizedSourceText),
        maxTokens: 700,
      );
      translation = parsedTranslation;

      _validateTranslationSourceLanguage(translation: parsedTranslation);
      _validateCompleteTranslation(parsedTranslation);

      final String returnedSourceText = parsedTranslation['SOURCE TEXT']!;
      final String sourceLanguage = parsedTranslation['SOURCE LANGUAGE']!;
      final String sourceLanguageText = parsedTranslation[sourceLanguage]!;

      final bool returnedSourceTextHasAddedOuterQuotes =
          returnedSourceText == '"$normalizedSourceText"';

      if (returnedSourceTextHasAddedOuterQuotes) {
        technicalDiagnostics.add(
          'SOURCE TEXT из ответа Typhoon содержит лишнюю внешнюю пару '
          'кавычек. Смысл исходного текста не изменён.',
        );
      }

      if (returnedSourceText != normalizedSourceText &&
          !returnedSourceTextHasAddedOuterQuotes) {
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

      final bool sourceLanguageTextMatchesSourceText =
          sourceLanguageText == returnedSourceText ||
          sourceLanguageText == '"$returnedSourceText"' ||
          returnedSourceText == '"$sourceLanguageText"';

      if (!sourceLanguageTextMatchesSourceText) {
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

      final String auditContent = await _requestContent(
        systemPrompt: _auditPrompt,
        userContent: _buildAuditInput(parsedTranslation),
        maxTokens: 500,
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
        sourceLanguage: parsedTranslation['SOURCE LANGUAGE']!,
        sourceText: parsedTranslation['SOURCE TEXT']!,
        status: semanticDiagnostics.isEmpty
            ? _resolveStatus(audit)
            : TranslatorPhraseStatus.canonicalDrift,
        ru: parsedTranslation['RU'],
        en: parsedTranslation['EN'],
        th: parsedTranslation['TH'],
        enToRu: parsedTranslation['EN_TO_RU'],
        thToRu: parsedTranslation['TH_TO_RU'],
        enToTh: parsedTranslation['EN_TO_TH'],
        thToEn: parsedTranslation['TH_TO_EN'],
        comment: comment,
      );
    } on DioException catch (error) {
      return _failedResult(
        submittedSourceText: normalizedSourceText,
        translation: translation,
        diagnostics: <String>[...technicalDiagnostics, ...semanticDiagnostics],
        comment: _mapDioError(error),
      );
    } on FormatException catch (error) {
      return _failedResult(
        submittedSourceText: normalizedSourceText,
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
    final String content = await _requestContent(
      systemPrompt: systemPrompt,
      userContent: userContent,
      maxTokens: maxTokens,
    );

    return _parseStrictSections(
      content: content,
      labels: _translationLabels,
      responseName: 'Ответ перевода Typhoon',
    );
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
        'temperature': 0.1,
        'top_p': 0.7,
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
    required String comment,
    Map<String, String>? translation,
    required List<String> diagnostics,
  }) {
    final String combinedComment = diagnostics.isEmpty
        ? comment
        : '${diagnostics.join('\n\n')}\n\n$comment';

    return TranslatorPhraseResult(
      sourceLanguage: translation?['SOURCE LANGUAGE'] ?? 'unknown',
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

  static String _buildTranslationInput({required String sourceText}) {
    return 'Source text:\n"$sourceText"';
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
    for (final String label in _auditLabels) {
      final String value = audit[label]!;

      if (value.toUpperCase() == _noFindings) {
        continue;
      }

      if (!_russianLetterPattern.hasMatch(value)) {
        throw FormatException(
          'Секция аудита $label должна содержать $_noFindings '
          'или конкретное объяснение на русском языке.',
        );
      }
    }
  }

  static TranslatorPhraseStatus _resolveStatus(Map<String, String> audit) {
    final bool meaningPreserved =
        audit['MEANING_FINDINGS']!.toUpperCase() == _noFindings;
    final bool terminologyPreserved =
        audit['TERMINOLOGY_FINDINGS']!.toUpperCase() == _noFindings;
    final bool canonicalStylePreserved =
        audit['STYLE_FINDINGS']!.toUpperCase() == _noFindings;
    final bool ambiguousWording =
        audit['AMBIGUITY_FINDINGS']!.toUpperCase() != _noFindings;

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
    final bool meaningPreserved =
        audit['MEANING_FINDINGS']!.toUpperCase() == _noFindings;
    final bool terminologyPreserved =
        audit['TERMINOLOGY_FINDINGS']!.toUpperCase() == _noFindings;
    final bool canonicalStylePreserved =
        audit['STYLE_FINDINGS']!.toUpperCase() == _noFindings;
    final bool ambiguousWording =
        audit['AMBIGUITY_FINDINGS']!.toUpperCase() != _noFindings;

    return '''
Meaning preserved: ${meaningPreserved ? 'YES' : 'NO'}
Terminology preserved: ${terminologyPreserved ? 'YES' : 'NO'}
Canonical style preserved: ${canonicalStylePreserved ? 'YES' : 'NO'}
Ambiguous wording: ${ambiguousWording ? 'YES' : 'NO'}

Смысловые различия:
${audit['MEANING_FINDINGS']}

Терминологические различия:
${audit['TERMINOLOGY_FINDINGS']}

Стилевые различия:
${audit['STYLE_FINDINGS']}

Неоднозначность:
${audit['AMBIGUITY_FINDINGS']}
'''
        .trim();
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

  static String _requiredText(String value, String name, String message) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, message);
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
  static const String _noFindings = 'NO_FINDINGS';
  static const List<String> _auditLabels = <String>[
    'MEANING_FINDINGS',
    'TERMINOLOGY_FINDINGS',
    'STYLE_FINDINGS',
    'AMBIGUITY_FINDINGS',
  ];

  static const String _translationPrompt = '''
You are Helpy strict multilingual translator.

Input can be RU, EN or TH.
Detect source language.

You must return exactly 9 sections.
All sections are required.
Do not omit any section.
Do not return empty values.
Do not use dashes as values.

Task:
1. Preserve SOURCE TEXT exactly as provided, without quotes.
2. Produce normalized RU, EN and TH versions.
3. Produce reverse translations for EN_TO_RU, TH_TO_RU, EN_TO_TH, TH_TO_EN.

Do not audit.
Do not explain.
Do not improve wording.
Preserve business meaning and service-marketplace terminology.

Output strictly with these exact ASCII labels:

SOURCE LANGUAGE:
RU | EN | TH

SOURCE TEXT:
original input text

RU:
Russian version

EN:
English version

TH:
Thai version

EN_TO_RU:
Russian reverse translation of EN

TH_TO_RU:
Russian reverse translation of TH

EN_TO_TH:
Thai reverse translation of EN

TH_TO_EN:
English reverse translation of TH
''';

  static const String _auditPrompt = '''
Ты являешься независимым аудитором мультиязычных инженерных формулировок Registry Studio.

Ты не выполняешь перевод.
Ты не исправляешь и не переписываешь формулировки.
Ты не выбираешь статус и не выставляешь бинарные значения.
Ты сначала фиксируешь фактические различия.

Порядок проверки:

1. Напрямую сравни RU, EN и TH.
2. Определи, одинаковые ли объект, действие, функция, условие, ограничение, количество и технический термин обозначены в каждой прямой версии.
3. После прямого сравнения используй EN_TO_RU, TH_TO_RU, EN_TO_TH и TH_TO_EN только как вспомогательное доказательство.
4. Обратные переводы не являются доказательством корректности прямых переводов.
5. Совпадение обратного перевода с исходником не отменяет различие, обнаруженное в прямой иностранной версии.
6. Близкий контекст, похожая функция или принадлежность к одной категории не означают эквивалентность.
7. Не оценивай различие как несущественное. Фиксируй сам факт различия.
8. Не трактуй сомнения в пользу корректности.

Классификация findings:

1. В MEANING_FINDINGS укажи изменение объекта, действия, функции, условия, отрицания, обязательности, допустимости, запрета, количества, границ работ или последовательности.
2. В TERMINOLOGY_FINDINGS укажи неточный, более широкий, более мягкий, иной либо технически неверный термин.
3. В STYLE_FINDINGS укажи изменение силы инструкции, инструктивной формы или канонического стиля.
4. В AMBIGUITY_FINDINGS укажи появившееся значимое для registry неоднозначное толкование.
5. Одно различие укажи в нескольких findings, когда оно затрагивает несколько категорий.
6. Если различий соответствующей категории нет, верни ровно NO_FINDINGS.
7. Если различие есть, кратко и конкретно опиши его на русском языке.
8. Не добавляй рекомендации, исправленные варианты, оправдания или желаемый статус.

Ты обязан вернуть ровно 4 секции.
Все секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.
Не возвращай дополнительный текст.

Верни результат строго с этими ASCII labels и в этом порядке:

MEANING_FINDINGS:
NO_FINDINGS либо конкретное смысловое различие на русском языке

TERMINOLOGY_FINDINGS:
NO_FINDINGS либо конкретное терминологическое различие на русском языке

STYLE_FINDINGS:
NO_FINDINGS либо конкретное стилевое различие на русском языке

AMBIGUITY_FINDINGS:
NO_FINDINGS либо конкретная неоднозначность на русском языке
''';
}
