import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/errors/translator_exception.dart';
import 'typhoon_translator_config.dart';

final class TyphoonChatClient {
  TyphoonChatClient({
    required TyphoonTranslatorConfig config,
    http.Client? httpClient,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client();

  final TyphoonTranslatorConfig _config;
  final http.Client _httpClient;

  Future<String> complete({
    required String apiKey,
    required String systemPrompt,
    required String userContent,
    required int maxTokens,
  }) async {
    final String normalizedApiKey = apiKey.trim();

    if (normalizedApiKey.isEmpty) {
      throw const TranslatorException(
        TranslatorFailureKind.missingApiKey,
        'Typhoon API key is not configured.',
      );
    }

    final http.Response response;

    try {
      response = await _httpClient
          .post(
            _config.chatCompletionsUri,
            headers: <String, String>{
              'Authorization': 'Bearer $normalizedApiKey',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, Object>{
              'model': _config.model,
              'messages': <Map<String, String>>[
                <String, String>{'role': 'system', 'content': systemPrompt},
                <String, String>{'role': 'user', 'content': userContent},
              ],
              'temperature': 0.1,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(_config.requestTimeout);
    } on TimeoutException {
      throw const TranslatorException(
        TranslatorFailureKind.transport,
        'Typhoon API request timed out.',
      );
    } on http.ClientException {
      throw const TranslatorException(
        TranslatorFailureKind.transport,
        'Typhoon API connection failed.',
      );
    }

    _throwForStatus(response.statusCode);

    final Object? decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon API returned malformed JSON.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon API response must be a JSON object.',
      );
    }

    final Object? choices = decoded['choices'];

    if (choices is! List<dynamic> || choices.isEmpty) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon API response contains no completion choice.',
      );
    }

    final Object? firstChoice = choices.first;

    if (firstChoice is! Map<String, dynamic>) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon API completion choice has an invalid format.',
      );
    }

    final Object? message = firstChoice['message'];

    if (message is! Map<String, dynamic>) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon API completion contains no message.',
      );
    }

    final Object? content = message['content'];

    if (content is! String || content.trim().isEmpty) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon API completion content is empty.',
      );
    }

    return content;
  }

  void close() {
    _httpClient.close();
  }

  static void _throwForStatus(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    if (statusCode == 401 || statusCode == 403) {
      throw const TranslatorException(
        TranslatorFailureKind.authorization,
        'Typhoon API rejected the API key.',
      );
    }

    if (statusCode == 429) {
      throw const TranslatorException(
        TranslatorFailureKind.rateLimited,
        'Typhoon API rate limit was exceeded.',
      );
    }

    if (statusCode >= 500) {
      throw TranslatorException(
        TranslatorFailureKind.provider,
        'Typhoon API server error ($statusCode).',
      );
    }

    throw TranslatorException(
      TranslatorFailureKind.provider,
      'Typhoon API request failed with status $statusCode.',
    );
  }
}
