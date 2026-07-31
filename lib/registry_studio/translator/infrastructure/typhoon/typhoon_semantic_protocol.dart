import 'dart:convert';

import '../../domain/translator_models.dart';

final class TyphoonSemanticProtocol {
  const TyphoonSemanticProtocol._();

  static TranslationBundle parseTranslation({
    required String content,
    required String expectedSourceText,
  }) {
    final Map<String, Object?> root = _jsonObject(content, name: 'translation');

    const Set<String> baseKeys = <String>{
      'SOURCE_LANGUAGE',
      'SOURCE_TEXT',
      'RU',
      'EN',
      'TH',
    };

    final String sourceLanguageCode = _canonicalString(
      root['SOURCE_LANGUAGE'],
      'translation.SOURCE_LANGUAGE',
    );
    final TranslationLanguage sourceLanguage;

    try {
      sourceLanguage = TranslationLanguage.fromCode(sourceLanguageCode);
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        'translation.SOURCE_LANGUAGE is invalid: ${error.message}',
      );
    }

    if (sourceLanguage.code != sourceLanguageCode) {
      throw const TyphoonSemanticProtocolException(
        'translation.SOURCE_LANGUAGE must use an uppercase canonical code.',
      );
    }

    final Set<String> actualKeys = root.keys.toSet();
    final Set<String> missingKeys = baseKeys.difference(actualKeys);
    final Set<String> unknownKeys = actualKeys.difference(baseKeys);

    if (unknownKeys.isNotEmpty) {
      throw TyphoonSemanticProtocolException(
        'translation contains unknown keys: ${unknownKeys.join(', ')}.',
      );
    }

    if (missingKeys.length == 1 && missingKeys.single == sourceLanguage.code) {
      root[sourceLanguage.code] = root['SOURCE_TEXT'];
    } else if (missingKeys.isNotEmpty) {
      throw TyphoonSemanticProtocolException(
        'translation is missing required keys: ${missingKeys.join(', ')}.',
      );
    }

    if (root.keys.length != baseKeys.length ||
        !root.keys.toSet().containsAll(baseKeys)) {
      throw const TyphoonSemanticProtocolException(
        'translation must contain exactly five required keys.',
      );
    }

    final String sourceText = _canonicalString(
      root['SOURCE_TEXT'],
      'translation.SOURCE_TEXT',
    );

    if (sourceText != expectedSourceText) {
      throw const TyphoonSemanticProtocolException(
        'translation.SOURCE_TEXT does not match the requested source text.',
      );
    }

    final String ru = _translationString(root['RU'], 'translation.RU');
    final String en = _translationString(root['EN'], 'translation.EN');
    final String th = _translationString(root['TH'], 'translation.TH');

    final String sourceSection = switch (sourceLanguage) {
      TranslationLanguage.ru => ru,
      TranslationLanguage.en => en,
      TranslationLanguage.th => th,
    };

    if (sourceSection != expectedSourceText) {
      throw const TyphoonSemanticProtocolException(
        'The source-language section does not preserve SOURCE_TEXT exactly.',
      );
    }

    try {
      return TranslationBundle(
        sourceLanguage: sourceLanguage,
        sourceText: sourceText,
        ru: ru,
        en: en,
        th: th,
      );
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        'translation bundle is invalid: ${error.message}',
      );
    }
  }

  static List<TranslationPairAudit> parseGeneralAudit(String content) {
    final Map<String, Object?> root = _jsonObject(content, name: 'audit');
    final Set<String> expectedKeys = TranslationPair.values
        .map((TranslationPair pair) => pair.code)
        .toSet();
    _requireExactKeys(root, expectedKeys, 'audit');

    final List<TranslationPairAudit> result = <TranslationPairAudit>[];

    for (final TranslationPair pair in TranslationPair.values) {
      final String name = 'audit.${pair.code}';
      final Map<String, Object?> pairObject = _object(root[pair.code], name);
      _requireExactKeys(pairObject, const <String>{'RESULT', 'ISSUES'}, name);

      final String resultCode = _canonicalString(
        pairObject['RESULT'],
        '$name.RESULT',
      );
      final TranslationPairAuditResult pairResult;

      try {
        pairResult = TranslationPairAuditResult.fromCode(resultCode);
      } on ArgumentError catch (error) {
        throw TyphoonSemanticProtocolException(
          '$name.RESULT is invalid: ${error.message}',
        );
      }

      if (pairResult.code != resultCode) {
        throw TyphoonSemanticProtocolException(
          '$name.RESULT must use an uppercase canonical code.',
        );
      }

      final Object? rawIssues = pairObject['ISSUES'];
      if (rawIssues is! List<Object?>) {
        throw TyphoonSemanticProtocolException(
          '$name.ISSUES must be a JSON array.',
        );
      }
      if (rawIssues.length > _maxAuditIssuesPerPair) {
        throw TyphoonSemanticProtocolException(
          '$name.ISSUES exceeds the $_maxAuditIssuesPerPair-item limit.',
        );
      }

      final List<TranslationPairIssue> issues = <TranslationPairIssue>[
        for (int index = 0; index < rawIssues.length; index += 1)
          _parseAuditIssue(rawIssues[index], name: '$name.ISSUES[$index]'),
      ];

      try {
        result.add(
          TranslationPairAudit(pair: pair, result: pairResult, issues: issues),
        );
      } on ArgumentError catch (error) {
        throw TyphoonSemanticProtocolException(
          '$name is inconsistent: ${error.message}',
        );
      }
    }

    return List<TranslationPairAudit>.unmodifiable(result);
  }

  static ExactPairCertification parseExactCertification({
    required String content,
    required TranslationPair pair,
  }) {
    final Map<String, Object?> root = _jsonObject(
      content,
      name: 'exact certification',
    );
    _requireExactKeys(root, const <String>{
      'RESULT',
      'ATOM',
    }, 'exact certification');

    final String resultCode = _canonicalString(
      root['RESULT'],
      'exact certification.RESULT',
    );

    if (resultCode == ExactCertificationResult.clear.code) {
      if (root['ATOM'] != null) {
        throw const TyphoonSemanticProtocolException(
          'CLEAR exact certification must use JSON null for ATOM.',
        );
      }

      return ExactPairCertification(
        pair: pair,
        result: ExactCertificationResult.clear,
      );
    }

    if (resultCode != ExactCertificationResult.notCertified.code) {
      throw const TyphoonSemanticProtocolException(
        'exact certification.RESULT must be CLEAR or NOT_CERTIFIED.',
      );
    }

    final String atomCode = _canonicalString(
      root['ATOM'],
      'exact certification.ATOM',
    );
    final TranslationSemanticAtom atom;

    try {
      atom = TranslationSemanticAtom.fromCode(atomCode);
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        'exact certification.ATOM is invalid: ${error.message}',
      );
    }

    if (atom.code != atomCode) {
      throw const TyphoonSemanticProtocolException(
        'exact certification.ATOM must use a canonical lowercase code.',
      );
    }

    return ExactPairCertification(
      pair: pair,
      result: ExactCertificationResult.notCertified,
      atom: atom,
    );
  }

  static TranslationPairIssue _parseAuditIssue(
    Object? value, {
    required String name,
  }) {
    final Map<String, Object?> issue = _object(value, name);
    _requireExactKeys(issue, const <String>{'ATOM', 'STATUS'}, name);

    final String atomCode = _canonicalString(issue['ATOM'], '$name.ATOM');
    final String statusCode = _canonicalString(issue['STATUS'], '$name.STATUS');
    final TranslationSemanticAtom atom;
    final TranslationIssueStatus status;

    try {
      atom = TranslationSemanticAtom.fromCode(atomCode);
      status = TranslationIssueStatus.fromCode(statusCode);
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        '$name contains an invalid code: ${error.message}',
      );
    }

    if (atom.code != atomCode || status.code != statusCode) {
      throw TyphoonSemanticProtocolException(
        '$name must use canonical ATOM and STATUS codes.',
      );
    }

    return TranslationPairIssue(atom: atom, status: status);
  }

  static Map<String, Object?> _jsonObject(
    String content, {
    required String name,
  }) {
    final String normalized = content.trim();

    if (normalized.isEmpty) {
      throw TyphoonSemanticProtocolException('$name response is empty.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(normalized);
    } on FormatException catch (error) {
      throw TyphoonSemanticProtocolException(
        '$name response is not valid JSON: ${error.message}',
      );
    }

    return _object(decoded, name);
  }

  static Map<String, Object?> _object(Object? value, String name) {
    if (value is! Map<Object?, Object?> ||
        value.keys.any((Object? key) => key is! String)) {
      throw TyphoonSemanticProtocolException('$name must be a JSON object.');
    }

    return value.cast<String, Object?>();
  }

  static void _requireExactKeys(
    Map<String, Object?> value,
    Set<String> expected,
    String name,
  ) {
    final Set<String> actual = value.keys.toSet();

    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw TyphoonSemanticProtocolException(
        '$name contains an invalid key set.',
      );
    }
  }

  static String _canonicalString(Object? value, String name) {
    if (value is! String || value.trim().isEmpty) {
      throw TyphoonSemanticProtocolException(
        '$name must be a nonempty string.',
      );
    }

    if (value != value.trim()) {
      throw TyphoonSemanticProtocolException(
        '$name must not contain outer whitespace.',
      );
    }

    return value;
  }

  static String _translationString(Object? value, String name) {
    final String result = _canonicalString(value, name);

    if (_placeholderValues.contains(result.toUpperCase())) {
      throw TyphoonSemanticProtocolException(
        '$name contains a placeholder value.',
      );
    }

    return result;
  }

  static const int _maxAuditIssuesPerPair = 2;

  static const Set<String> _placeholderValues = <String>{
    '-',
    'N/A',
    'NONE',
    'NULL',
    'UNKNOWN',
    'NOT PROVIDED',
  };
}

final class TyphoonSemanticProtocolException implements Exception {
  const TyphoonSemanticProtocolException(this.message);

  final String message;

  @override
  String toString() => 'TyphoonSemanticProtocolException($message)';
}
