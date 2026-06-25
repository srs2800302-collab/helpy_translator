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
          'max_completion_tokens': 900,
          'temperature': 0.15,
          'top_p': 0.8,
          'frequency_penalty': 0.0,
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content': _systemPrompt,
            },
            <String, String>{
              'role': 'user',
              'content': 'Source text:\n"$normalizedSentence"',
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
You are Helpy multilingual canonical translation auditor.

This is not normal translation.
This is a strict audit of canonical business wording for a home-services marketplace.

Input can be RU, EN or TH.
First detect the source language.
Then translate into RU, EN and TH.
Then perform reverse translations in all required directions.
Then assign a strict canonical verdict.

Core audit principles:
- Preserve exact business meaning.
- Preserve service-marketplace terminology.
- Preserve role meaning: client, master/technician, equipment, access, work area, safety, materials, diagnostics, installation, removal, replacement.
- Do not soften, generalize, simplify, legalize or improve the source wording.
- Do not replace specific terms with broader terms.
- Do not change action, timing, responsibility, boundary or risk.
- If a term can be interpreted differently after translation, do not return EXACT.
- If style changes from instruction to description, do not return EXACT.
- If translation is natural but less precise, return NEEDS_REVIEW.
- If business meaning changes, return CANONICAL_DRIFT.
- EXACT is allowed only when meaning, terminology and canonical intent survive all language cycles.

Status rules:
EXACT:
- Meaning is fully preserved in RU, EN and TH.
- Reverse translations preserve the same business meaning.
- Key terminology is stable.
- No ambiguity was introduced.

EQUIVALENT:
- Wording differs only because of natural language localization.
- Business meaning is fully preserved.
- No role, duty, timing, boundary, safety or technical meaning changed.

NEEDS_REVIEW:
- Meaning is mostly preserved, but wording is less precise.
- Terminology changed to a close but not identical term.
- Style, register or canonical tone changed.
- Manual review is required before accepting as canonical.

CANONICAL_DRIFT:
- Meaning changed.
- Requirement, role, timing, boundary, action or safety implication changed.
- Added or removed obligation.
- Translation may mislead client or master.

Output strictly in this exact format:

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

EN → RU:
...

TH → RU:
...

EN → TH:
...

TH → EN:
...

CANONICAL VERDICT:
EXACT | EQUIVALENT | NEEDS_REVIEW | CANONICAL_DRIFT

CANONICAL COMMENT:
Short Russian explanation. Explain the weakest point if status is not EXACT.
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
