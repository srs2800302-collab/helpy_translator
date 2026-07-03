import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/translator/domain/entities/canonical_audit_result.dart';
import '../../features/translator/domain/entities/translation_result.dart';

enum PersistedRegistryPhraseStatus {
  exact,
  equivalent,
  needsReview,
  drift,
  failed,
}

final class PersistedRegistryPhraseRecord {
  const PersistedRegistryPhraseRecord({
    required this.phrase,
    required this.status,
    required this.verdict,
    required this.comment,
    required this.checkedAtIso,
  });

  final String phrase;
  final PersistedRegistryPhraseStatus status;
  final String verdict;
  final String comment;
  final String checkedAtIso;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'phrase': phrase,
      'status': status.name,
      'verdict': verdict,
      'comment': comment,
      'checkedAtIso': checkedAtIso,
    };
  }

  static PersistedRegistryPhraseRecord fromJson(Map<String, dynamic> json) {
    return PersistedRegistryPhraseRecord(
      phrase: _string(json['phrase']),
      status: _statusFromName(_string(json['status'])),
      verdict: _string(json['verdict']),
      comment: _string(json['comment']),
      checkedAtIso: _string(json['checkedAtIso']),
    );
  }

  static PersistedRegistryPhraseStatus _statusFromName(String name) {
    return PersistedRegistryPhraseStatus.values.firstWhere(
      (PersistedRegistryPhraseStatus status) => status.name == name,
      orElse: () => PersistedRegistryPhraseStatus.failed,
    );
  }

  static String _string(Object? value) {
    return value is String ? value : '';
  }
}

final class RegistryPhraseStatusPersistence {
  const RegistryPhraseStatusPersistence();

  static const String _key = 'registry_phrase_status_index_v1';

  Future<Map<String, PersistedRegistryPhraseRecord>> loadIndex() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_key);

    if (raw == null || raw.isEmpty) {
      return <String, PersistedRegistryPhraseRecord>{};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return <String, PersistedRegistryPhraseRecord>{};
    }

    if (decoded is! Map<String, dynamic>) {
      return <String, PersistedRegistryPhraseRecord>{};
    }

    final Map<String, PersistedRegistryPhraseRecord> result =
        <String, PersistedRegistryPhraseRecord>{};

    decoded.forEach((String key, Object? value) {
      if (value is Map<String, dynamic>) {
        final PersistedRegistryPhraseRecord record =
            PersistedRegistryPhraseRecord.fromJson(value);
        final String normalizedKey = record.phrase.trim().isEmpty
            ? _normalize(key)
            : _normalize(record.phrase);

        result[normalizedKey] = record;
        return;
      }

      result[_normalize(key)] = PersistedRegistryPhraseRecord(
        phrase: '',
        status: PersistedRegistryPhraseStatus.failed,
        verdict: 'FAILED',
        comment: 'Invalid persisted record.',
        checkedAtIso: '',
      );
    });

    return result;
  }

  Future<void> saveTranslationResult(TranslationResult result) async {
    final String phrase = result.sourceText.trim().isEmpty
        ? result.ru.trim()
        : result.sourceText.trim();

    if (phrase.isEmpty) {
      return;
    }

    await _upsert(
      phrase: phrase,
      status: _statusFromVerdict(result.canonicalVerdict),
      verdict: result.canonicalVerdict,
      comment: result.canonicalComment,
    );
  }

  Future<void> saveAuditResults(List<CanonicalAuditResult> results) async {
    final Map<String, PersistedRegistryPhraseRecord> index = await loadIndex();

    for (final CanonicalAuditResult result in results) {
      final String phrase = result.sourceRu.trim();

      if (phrase.isEmpty) {
        continue;
      }

      final TranslationResult? translation = result.translation;

      index[_normalize(phrase)] = PersistedRegistryPhraseRecord(
        phrase: phrase,
        status: _statusFromAuditStatus(result.status),
        verdict: translation?.canonicalVerdict ?? result.status.name,
        comment: translation?.canonicalComment ?? result.errorMessage,
        checkedAtIso: DateTime.now().toIso8601String(),
      );
    }

    await _saveIndex(index);
  }

  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }

  Future<String> exportJson() async {
    final Map<String, PersistedRegistryPhraseRecord> index = await loadIndex();

    final Map<String, Object?> json = index.map((
      String key,
      PersistedRegistryPhraseRecord value,
    ) {
      return MapEntry<String, Object?>(key, value.toJson());
    });

    return jsonEncode(json);
  }

  Future<void> importJson(String rawJson) async {
    final Object? decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Registry status JSON.');
    }

    final Map<String, PersistedRegistryPhraseRecord> imported =
        <String, PersistedRegistryPhraseRecord>{};

    decoded.forEach((String key, Object? value) {
      if (value is! Map<String, dynamic>) {
        return;
      }

      final PersistedRegistryPhraseRecord record =
          PersistedRegistryPhraseRecord.fromJson(value);

      final String normalizedKey = record.phrase.trim().isEmpty
          ? _normalize(key)
          : _normalize(record.phrase);

      if (normalizedKey.isEmpty) {
        return;
      }

      imported[normalizedKey] = record;
    });

    await _saveIndex(imported);
  }

  Future<void> _upsert({
    required String phrase,
    required PersistedRegistryPhraseStatus status,
    required String verdict,
    required String comment,
  }) async {
    final Map<String, PersistedRegistryPhraseRecord> index = await loadIndex();

    index[_normalize(phrase)] = PersistedRegistryPhraseRecord(
      phrase: phrase,
      status: status,
      verdict: verdict,
      comment: comment,
      checkedAtIso: DateTime.now().toIso8601String(),
    );

    await _saveIndex(index);
  }

  Future<void> _saveIndex(
    Map<String, PersistedRegistryPhraseRecord> index,
  ) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final Map<String, Object?> json = index.map((
      String key,
      PersistedRegistryPhraseRecord value,
    ) {
      return MapEntry<String, Object?>(key, value.toJson());
    });

    await preferences.setString(_key, jsonEncode(json));
  }

  static PersistedRegistryPhraseStatus _statusFromVerdict(String verdict) {
    return switch (verdict.trim().toUpperCase()) {
      'EXACT' => PersistedRegistryPhraseStatus.exact,
      'EQUIVALENT' => PersistedRegistryPhraseStatus.equivalent,
      'NEEDS_REVIEW' => PersistedRegistryPhraseStatus.needsReview,
      'CANONICAL_DRIFT' => PersistedRegistryPhraseStatus.drift,
      _ => PersistedRegistryPhraseStatus.failed,
    };
  }

  static PersistedRegistryPhraseStatus _statusFromAuditStatus(
    CanonicalAuditStatus status,
  ) {
    return switch (status) {
      CanonicalAuditStatus.exact => PersistedRegistryPhraseStatus.exact,
      CanonicalAuditStatus.equivalent =>
        PersistedRegistryPhraseStatus.equivalent,
      CanonicalAuditStatus.needsReview =>
        PersistedRegistryPhraseStatus.needsReview,
      CanonicalAuditStatus.drift => PersistedRegistryPhraseStatus.drift,
      CanonicalAuditStatus.failed => PersistedRegistryPhraseStatus.failed,
    };
  }

  static String normalizePhrase(String phrase) {
    return _normalize(phrase);
  }

  static String _normalize(String phrase) {
    return phrase
        .trim()
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll('ё', 'е')
        .replaceAll('Ё', 'Е')
        .replaceAll(RegExp(r'[«»"“”„‟‹›]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s.!?,:;]+'), '')
        .replaceAll(RegExp(r'[\s.!?,:;]+$'), '')
        .toLowerCase();
  }
}
