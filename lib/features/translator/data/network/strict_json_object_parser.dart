import 'dart:convert';

import '../../domain/errors/translator_exception.dart';

final class StrictJsonObjectParser {
  const StrictJsonObjectParser();

  Map<String, Object?> parse(String content) {
    final String normalized = _removeSingleJsonFence(content.trim());

    if (normalized.isEmpty) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon returned an empty response.',
      );
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(normalized);
    } on FormatException {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon returned malformed JSON.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const TranslatorException(
        TranslatorFailureKind.invalidResponse,
        'Typhoon response must be one JSON object.',
      );
    }

    return Map<String, Object?>.unmodifiable(decoded);
  }

  static String _removeSingleJsonFence(String content) {
    if (!content.startsWith('```')) {
      return content;
    }

    final RegExp fencedJson = RegExp(
      r'^```(?:json)?\s*\n([\s\S]*?)\n```\s*$',
      caseSensitive: false,
    );
    final RegExpMatch? match = fencedJson.firstMatch(content);

    if (match == null) {
      return content;
    }

    return match.group(1)?.trim() ?? '';
  }
}
