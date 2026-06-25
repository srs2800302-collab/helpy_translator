import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/translator/domain/entities/canonical_audit_result.dart';
import '../../features/translator/domain/entities/translation_result.dart';

final class TranslatorStatePersistence {
  const TranslatorStatePersistence();

  static const String _translationHistoryKey = 'translation_history_v1';
  static const String _auditResultsKey = 'audit_results_v1';

  Future<List<TranslationResult>> loadTranslationHistory() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_translationHistoryKey);

    if (raw == null || raw.isEmpty) {
      return const <TranslationResult>[];
    }

    final Object? decoded = jsonDecode(raw);

    if (decoded is! List<dynamic>) {
      return const <TranslationResult>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_translationFromJson)
        .toList(growable: false);
  }

  Future<List<CanonicalAuditResult>> loadAuditResults() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_auditResultsKey);

    if (raw == null || raw.isEmpty) {
      return const <CanonicalAuditResult>[];
    }

    final Object? decoded = jsonDecode(raw);

    if (decoded is! List<dynamic>) {
      return const <CanonicalAuditResult>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_auditResultFromJson)
        .toList(growable: false);
  }

  Future<void> saveTranslationHistory(List<TranslationResult> history) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String raw = jsonEncode(history.map(_translationToJson).toList());
    await preferences.setString(_translationHistoryKey, raw);
  }

  Future<void> saveAuditResults(List<CanonicalAuditResult> results) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String raw = jsonEncode(results.map(_auditResultToJson).toList());
    await preferences.setString(_auditResultsKey, raw);
  }

  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_translationHistoryKey);
    await preferences.remove(_auditResultsKey);
  }

  static Map<String, Object?> _translationToJson(TranslationResult result) {
    return <String, Object?>{
      'ru': result.ru,
      'en': result.en,
      'th': result.th,
      'enToRu': result.enToRu,
      'thToRu': result.thToRu,
      'enToTh': result.enToTh,
      'thToEn': result.thToEn,
      'canonicalVerdict': result.canonicalVerdict,
      'canonicalComment': result.canonicalComment,
    };
  }

  static TranslationResult _translationFromJson(Map<String, dynamic> json) {
    return TranslationResult(
      ru: _string(json['ru']),
      en: _string(json['en']),
      th: _string(json['th']),
      enToRu: _string(json['enToRu']),
      thToRu: _string(json['thToRu']),
      enToTh: _string(json['enToTh']),
      thToEn: _string(json['thToEn']),
      canonicalVerdict: _string(json['canonicalVerdict']),
      canonicalComment: _string(json['canonicalComment']),
    );
  }

  static Map<String, Object?> _auditResultToJson(CanonicalAuditResult result) {
    return <String, Object?>{
      'sourceRu': result.sourceRu,
      'status': result.status.name,
      'errorMessage': result.errorMessage,
      'translation': result.translation == null
          ? null
          : _translationToJson(result.translation!),
    };
  }

  static CanonicalAuditResult _auditResultFromJson(Map<String, dynamic> json) {
    final Object? translation = json['translation'];

    return CanonicalAuditResult(
      sourceRu: _string(json['sourceRu']),
      translation: translation is Map<String, dynamic>
          ? _translationFromJson(translation)
          : null,
      status: _auditStatusFromName(_string(json['status'])),
      errorMessage: _string(json['errorMessage']),
    );
  }

  static CanonicalAuditStatus _auditStatusFromName(String name) {
    return CanonicalAuditStatus.values.firstWhere(
      (CanonicalAuditStatus status) => status.name == name,
      orElse: () => CanonicalAuditStatus.failed,
    );
  }

  static String _string(Object? value) {
    return value is String ? value : '';
  }
}
