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
      final String directContent = await _request(
        systemPrompt: _directTranslationPrompt,
        userContent: _buildDirectTranslationInput(
          sourceText: normalizedSourceText,
          sourceLanguageHint: normalizedSourceLanguageHint,
          engineerContext: normalizedEngineerContext,
        ),
        maxTokens: 700,
      );

      final Map<String, String> directTranslation = _parseStrictSections(
        content: directContent,
        labels: _directTranslationLabels,
        responseName: 'Ответ прямого перевода Typhoon',
      );

      _validateDirectTranslation(
        translation: directTranslation,
        normalizedSourceText: normalizedSourceText,
      );

      final String englishLiteralContent = await _request(
        systemPrompt: _englishLiteralTranslationPrompt,
        userContent: _buildEnglishLiteralInput(directTranslation['EN']!),
        maxTokens: 350,
      );

      final Map<String, String> englishLiteralTranslation =
          _parseStrictSections(
            content: englishLiteralContent,
            labels: _englishLiteralLabels,
            responseName: 'Ответ дословной проверки английской версии',
          );

      final String thaiLiteralContent = await _request(
        systemPrompt: _thaiLiteralTranslationPrompt,
        userContent: _buildThaiLiteralInput(directTranslation['TH']!),
        maxTokens: 350,
      );

      final Map<String, String> thaiLiteralTranslation = _parseStrictSections(
        content: thaiLiteralContent,
        labels: _thaiLiteralLabels,
        responseName: 'Ответ дословной проверки тайской версии',
      );

      final Map<String, String> translation = <String, String>{
        'SOURCE LANGUAGE': directTranslation['SOURCE LANGUAGE']!,
        'SOURCE TEXT': directTranslation['SOURCE TEXT']!,
        'RU': directTranslation['RU']!,
        'EN': directTranslation['EN']!,
        'TH': directTranslation['TH']!,
        'EN_TO_RU': englishLiteralTranslation['EN_TO_RU']!,
        'TH_TO_RU': thaiLiteralTranslation['TH_TO_RU']!,
        'EN_TO_TH': englishLiteralTranslation['EN_TO_TH']!,
        'TH_TO_EN': thaiLiteralTranslation['TH_TO_EN']!,
      };

      _validateCompleteTranslation(translation);

      final String auditContent = await _request(
        systemPrompt: _auditPrompt,
        userContent: _buildAuditInput(translation),
        maxTokens: 500,
      );

      final Map<String, String> audit = _parseStrictSections(
        content: auditContent,
        labels: _auditLabels,
        responseName: 'Ответ независимого аудита',
      );

      _validateAudit(audit);

      return TranslatorPhraseResult(
        sourceLanguage: translation['SOURCE LANGUAGE']!,
        sourceText: translation['SOURCE TEXT']!,
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

  static String _buildDirectTranslationInput({
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

  static String _buildEnglishLiteralInput(String englishText) {
    return 'EN:\n$englishText';
  }

  static String _buildThaiLiteralInput(String thaiText) {
    return 'TH:\n$thaiText';
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

    if (matches.isEmpty || matches.first.start != 0) {
      throw FormatException(
        '$responseName содержит текст до первой обязательной секции.',
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

  static void _validateDirectTranslation({
    required Map<String, String> translation,
    required String normalizedSourceText,
  }) {
    final String sourceLanguage = translation['SOURCE LANGUAGE']!;

    if (!_sourceLanguages.contains(sourceLanguage)) {
      throw const FormatException(
        'SOURCE LANGUAGE должен содержать только RU, EN или TH.',
      );
    }

    if (translation['SOURCE TEXT'] != normalizedSourceText) {
      throw const FormatException(
        'SOURCE TEXT не совпадает с переданным исходным текстом.',
      );
    }

    if (translation[sourceLanguage] != normalizedSourceText) {
      throw FormatException(
        'Секция исходного языка $sourceLanguage не совпадает с SOURCE TEXT.',
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

  static const List<String> _directTranslationLabels = <String>[
    'SOURCE LANGUAGE',
    'SOURCE TEXT',
    'RU',
    'EN',
    'TH',
  ];
  static const List<String> _englishLiteralLabels = <String>[
    'EN_TO_RU',
    'EN_TO_TH',
  ];
  static const List<String> _thaiLiteralLabels = <String>[
    'TH_TO_RU',
    'TH_TO_EN',
  ];
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

  static const String _directTranslationPrompt = '''
Ты являешься строгим мультиязычным инженерным переводчиком Registry Studio.

Язык исходного текста: RU, EN или TH.
Определи язык исходного текста.
Используй SOURCE LANGUAGE HINT только как подсказку, если он передан.
Используй ENGINEER CONTEXT только для понимания терминологии или устранения неоднозначности.
Не переводи ENGINEER CONTEXT.
Не добавляй сведения из ENGINEER CONTEXT в переводимый текст.

Ты обязан вернуть ровно 5 секций.
Все секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.
Не используй дефис или тире вместо значения.
Не используй символы направления в ответе.

Правила перевода:

1. Сохрани SOURCE TEXT точно в том виде, в котором он передан.
2. Не добавляй кавычки вокруг SOURCE TEXT.
3. В языковой секции, соответствующей SOURCE LANGUAGE, повтори SOURCE TEXT без изменений.
4. Сформируй версии на русском, английском и тайском языках.
5. Переводи настолько дословно, насколько позволяет грамматика целевого языка.
6. Сохраняй точный инженерный смысл.
7. Сохраняй техническую и реестровую терминологию.
8. Сохраняй силу инструкции.
9. Сохраняй обязательность, допустимость и запрет.
10. Сохраняй отрицания.
11. Сохраняй границы работ и исключения.
12. Сохраняй количества, единицы измерения, условия и последовательность.
13. Не улучшай формулировку.
14. Не упрощай формулировку.
15. Не заменяй конкретные термины более общими.
16. Не смягчай и не усиливай инструкцию.
17. Не добавляй пояснения.
18. Не выполняй аудит.
19. Не утверждай каноничность формулировки.
20. Не изменяй содержимое registry.

Верни результат строго с этими ASCII labels:

SOURCE LANGUAGE:
RU | EN | TH

SOURCE TEXT:
исходный текст без изменений

RU:
русская версия

EN:
английская версия

TH:
тайская версия
''';

  static const String _englishLiteralTranslationPrompt = '''
Ты являешься переводчиком дословной обратной проверки Registry Studio.

Ты получаешь только инженерную фразу на английском языке.
Ты не знаешь исходный текст.
Не пытайся угадать или восстановить исходную формулировку.

Ты обязан вернуть ровно 2 секции.
Обе секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.
Не используй дефис или тире вместо значения.
Не используй символы направления в ответе.

Правила перевода:

1. Переведи переданный английский текст дословно на русский язык.
2. Переведи тот же английский текст дословно на тайский язык.
3. Переводи только фактически переданный текст.
4. Передай точный смысл английской формулировки.
5. Сохраняй терминологию.
6. Сохраняй силу инструкции.
7. Сохраняй обязательность, допустимость, запрет и отрицание.
8. Сохраняй границы, количества, условия и последовательность.
9. Сохраняй порядок слов там, где это допускает грамматика целевого языка.
10. Не улучшай формулировку.
11. Не нормализуй формулировку.
12. Не приводи формулировку к каноническому стилю.
13. Не устраняй неоднозначность.
14. Не добавляй отсутствующий контекст.
15. Не объясняй результат.
16. Не выполняй аудит.

Верни результат строго с этими ASCII labels:

EN_TO_RU:
дословный русский перевод переданного английского текста

EN_TO_TH:
дословный тайский перевод переданного английского текста
''';

  static const String _thaiLiteralTranslationPrompt = '''
Ты являешься переводчиком дословной обратной проверки Registry Studio.

Ты получаешь только инженерную фразу на тайском языке.
Ты не знаешь исходный текст.
Не пытайся угадать или восстановить исходную формулировку.

Ты обязан вернуть ровно 2 секции.
Обе секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.
Не используй дефис или тире вместо значения.
Не используй символы направления в ответе.

Правила перевода:

1. Переведи переданный тайский текст дословно на русский язык.
2. Переведи тот же тайский текст дословно на английский язык.
3. Переводи только фактически переданный текст.
4. Передай точный смысл тайской формулировки.
5. Сохраняй терминологию.
6. Сохраняй силу инструкции.
7. Сохраняй обязательность, допустимость, запрет и отрицание.
8. Сохраняй границы, количества, условия и последовательность.
9. Сохраняй порядок слов там, где это допускает грамматика целевого языка.
10. Не улучшай формулировку.
11. Не нормализуй формулировку.
12. Не приводи формулировку к каноническому стилю.
13. Не устраняй неоднозначность.
14. Не добавляй отсутствующий контекст.
15. Не объясняй результат.
16. Не выполняй аудит.

Верни результат строго с этими ASCII labels:

TH_TO_RU:
дословный русский перевод переданного тайского текста

TH_TO_EN:
дословный английский перевод переданного тайского текста
''';

  static const String _auditPrompt = '''
Ты являешься независимым аудитором мультиязычных инженерных формулировок Registry Studio.

Ты не выполняешь перевод.
Ты не переписываешь формулировки.
Ты проверяешь только полный набор из 9 секций.

Секции дословного обратного перевода являются диагностическим доказательством.
Используй их, чтобы определить, какой смысл фактически передают английская и тайская версии.

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
