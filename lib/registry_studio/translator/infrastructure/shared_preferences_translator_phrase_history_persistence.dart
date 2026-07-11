import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../application/translator_phrase_history_persistence.dart';
import '../translator_phrase_result.dart';
import '../translator_phrase_status.dart';

final class SharedPreferencesTranslatorPhraseHistoryPersistence
    implements TranslatorPhraseHistoryPersistence {
  const SharedPreferencesTranslatorPhraseHistoryPersistence();

  static const int _schemaVersion = 1;
  static const String _historyKey =
      'registry_studio_translator_phrase_history_v1';

  @override
  Future<List<TranslatorPhraseResult>> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_historyKey);

    if (raw == null || raw.trim().isEmpty) {
      return const <TranslatorPhraseResult>[];
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const <TranslatorPhraseResult>[];
    }

    if (decoded is! Map<String, Object?> ||
        decoded['version'] != _schemaVersion) {
      return const <TranslatorPhraseResult>[];
    }

    final Object? rawHistory = decoded['history'];

    if (rawHistory is! List<Object?>) {
      return const <TranslatorPhraseResult>[];
    }

    final List<TranslatorPhraseResult> history = <TranslatorPhraseResult>[];

    for (final Object? rawResult in rawHistory) {
      final TranslatorPhraseResult? result = _decodeResult(rawResult);

      if (result != null) {
        history.add(result);
      }
    }

    return List<TranslatorPhraseResult>.unmodifiable(history);
  }

  @override
  Future<void> save(List<TranslatorPhraseResult> history) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final Map<String, Object?> payload = <String, Object?>{
      'version': _schemaVersion,
      'history': history
          .map<Map<String, Object?>>(_encodeResult)
          .toList(growable: false),
    };

    await preferences.setString(_historyKey, jsonEncode(payload));
  }

  @override
  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_historyKey);
  }

  static Map<String, Object?> _encodeResult(TranslatorPhraseResult result) {
    return <String, Object?>{
      'sourceLanguage': result.sourceLanguage,
      'sourceText': result.sourceText,
      'status': result.status.name,
      'ru': result.ru,
      'en': result.en,
      'th': result.th,
      'enToRu': result.enToRu,
      'thToRu': result.thToRu,
      'enToTh': result.enToTh,
      'thToEn': result.thToEn,
      'comment': result.comment,
      'candidateCanonicalPhrase': result.candidateCanonicalPhrase,
    };
  }

  static TranslatorPhraseResult? _decodeResult(Object? rawResult) {
    if (rawResult is! Map<String, Object?>) {
      return null;
    }

    final String sourceLanguage = _string(rawResult['sourceLanguage']);
    final String sourceText = _string(rawResult['sourceText']);
    final TranslatorPhraseStatus? status = _status(
      _string(rawResult['status']),
    );

    if (sourceLanguage.isEmpty || sourceText.isEmpty || status == null) {
      return null;
    }

    try {
      return TranslatorPhraseResult(
        sourceLanguage: sourceLanguage,
        sourceText: sourceText,
        status: status,
        ru: _optionalString(rawResult['ru']),
        en: _optionalString(rawResult['en']),
        th: _optionalString(rawResult['th']),
        enToRu: _optionalString(rawResult['enToRu']),
        thToRu: _optionalString(rawResult['thToRu']),
        enToTh: _optionalString(rawResult['enToTh']),
        thToEn: _optionalString(rawResult['thToEn']),
        comment: _optionalString(rawResult['comment']),
        candidateCanonicalPhrase: _optionalString(
          rawResult['candidateCanonicalPhrase'],
        ),
      );
    } on ArgumentError {
      return null;
    }
  }

  static TranslatorPhraseStatus? _status(String name) {
    for (final TranslatorPhraseStatus status in TranslatorPhraseStatus.values) {
      if (status.name == name) {
        return status;
      }
    }

    return null;
  }

  static String _string(Object? value) {
    return value is String ? value.trim() : '';
  }

  static String? _optionalString(Object? value) {
    final String normalized = _string(value);
    return normalized.isEmpty ? null : normalized;
  }
}
