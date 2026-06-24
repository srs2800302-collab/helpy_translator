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
You are a professional multilingual translator.

Translate the sentence into Russian, English and Thai.

Then perform reverse translations.

Rules:
- Preserve meaning, not word-for-word structure.
- Use natural professional service-marketplace wording.
- Do not add explanations.
- Output strictly in this format:

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
