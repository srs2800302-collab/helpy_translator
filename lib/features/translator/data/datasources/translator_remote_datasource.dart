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
      final Response<dynamic> response = await apiClient.dio.post<dynamic>(
        '/chat/completions',
        data: <String, Object>{
          'model': appConfig.typhoonModel,
          'max_completion_tokens': 512,
          'temperature': 0.6,
          'top_p': 1.0,
          'frequency_penalty': 0.0,
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content': _systemPrompt,
            },
            <String, String>{
              'role': 'user',
              'content': 'Sentence:\n"$normalizedSentence"',
            },
          ],
        },
      );

      final String content = _extractContent(response.data);
      return TranslationResultModel.fromContent(content);
    } on DioException catch (error) {
      throw AppException(_mapDioError(error));
    }
  }

  static const String _systemPrompt = '''
You are Helpy canonical translation auditor.

Task:
Translate the sentence into Russian, English and Thai.
Then perform reverse translations.
Then evaluate whether the canonical Russian wording is preserved.

Strict rules:
- Preserve the source meaning.
- Preserve service-marketplace terminology.
- Do not replace key terms with softer synonyms when avoidable.
- мастер = master / technician / ช่าง depending on language naturalness.
- клиент = client / customer / ลูกค้า.
- оборудование = equipment / อุปกรณ์.
- Do not improve, simplify, legalize or rewrite the source sentence.
- For Russian reverse translations, return the closest possible wording to the original Russian canonical phrase.

Canonical verdict values:
- EXACT: reverse RU translations preserve the original wording almost exactly.
- EQUIVALENT: wording differs, but business meaning is fully preserved.
- NEEDS_REVIEW: meaning is mostly preserved, but wording may be risky for canonical rules.
- CANONICAL_DRIFT: meaning, responsibility, role, action, timing or boundary changed.

Output strictly in this format:

RU:
...

EN:
...

TH:
...

EN → RU:
...

TH → RU:
...

EN → TH:
...

TH → EN:
...

CANONICAL VERDICT:
...

CANONICAL COMMENT:
...
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
