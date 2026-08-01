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

    if (missingKeys.isNotEmpty) {
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

  static List<TranslationPairAudit> parseGeneralAudit({
    required String content,
    required TranslationBundle bundle,
  }) {
    final Map<String, Object?> root = _jsonObject(content, name: 'audit');
    _requireExactKeys(root, const <String>{'PAIR_RESULTS'}, 'audit');

    final Map<String, Object?> pairResults = _object(
      root['PAIR_RESULTS'],
      'audit.PAIR_RESULTS',
    );
    final Set<String> expectedPairs = TranslationPair.values
        .map((TranslationPair pair) => pair.code)
        .toSet();
    _requireExactKeys(pairResults, expectedPairs, 'audit.PAIR_RESULTS');

    final List<TranslationPairAudit> audits = <TranslationPairAudit>[];
    for (final TranslationPair pair in TranslationPair.values) {
      final String name = 'audit.PAIR_RESULTS.${pair.code}';
      final Map<String, Object?> pairObject = _object(
        pairResults[pair.code],
        name,
      );
      _requireExactKeys(pairObject, const <String>{'RESULT', 'ISSUES'}, name);

      final String resultCode = _canonicalString(
        pairObject['RESULT'],
        '$name.RESULT',
      );
      final TranslationPairAuditResult result;
      try {
        result = TranslationPairAuditResult.fromCode(resultCode);
      } on ArgumentError catch (error) {
        throw TyphoonSemanticProtocolException(
          '$name.RESULT is invalid: ${error.message}',
        );
      }
      if (result.code != resultCode) {
        throw TyphoonSemanticProtocolException(
          '$name.RESULT must use an uppercase canonical code.',
        );
      }

      final List<Object?> rawIssues = _array(
        pairObject['ISSUES'],
        '$name.ISSUES',
      );
      if (rawIssues.length > _maxAuditIssuesPerPair) {
        throw TyphoonSemanticProtocolException(
          '$name.ISSUES exceeds the $_maxAuditIssuesPerPair-item limit.',
        );
      }

      final List<TranslationPairIssue> issues = <TranslationPairIssue>[
        for (int index = 0; index < rawIssues.length; index += 1)
          _parsePairIssue(
            rawIssues[index],
            pair: pair,
            bundle: bundle,
            name: '$name.ISSUES[$index]',
          ),
      ];

      try {
        audits.add(
          TranslationPairAudit(pair: pair, result: result, issues: issues),
        );
      } on ArgumentError catch (error) {
        throw TyphoonSemanticProtocolException(
          '$name is inconsistent: ${error.message}',
        );
      }
    }

    return List<TranslationPairAudit>.unmodifiable(audits);
  }

  static ExactChallenge parseExactChallenge({
    required String content,
    required TranslationBundle bundle,
  }) {
    final Map<String, Object?> root = _jsonObject(
      content,
      name: 'exact challenge',
    );
    _requireExactKeys(root, const <String>{
      'RESULT',
      'DISQUALIFIERS',
    }, 'exact challenge');

    final String resultCode = _canonicalString(
      root['RESULT'],
      'exact challenge.RESULT',
    );
    final ExactChallengeResult result;
    try {
      result = ExactChallengeResult.fromCode(resultCode);
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        'exact challenge.RESULT is invalid: ${error.message}',
      );
    }
    if (result == ExactChallengeResult.protocolFailure ||
        result.code != resultCode) {
      throw const TyphoonSemanticProtocolException(
        'exact challenge.RESULT must be CLEAR, BLOCKED or UNPROVEN.',
      );
    }

    final List<Object?> rawItems = _array(
      root['DISQUALIFIERS'],
      'exact challenge.DISQUALIFIERS',
    );
    if (rawItems.length > _maxChallengeDisqualifiers) {
      throw TyphoonSemanticProtocolException(
        'exact challenge.DISQUALIFIERS exceeds the '
        '$_maxChallengeDisqualifiers-item limit.',
      );
    }

    final List<ExactChallengeDisqualifier> disqualifiers =
        <ExactChallengeDisqualifier>[
          for (int index = 0; index < rawItems.length; index += 1)
            _parseDisqualifier(
              rawItems[index],
              bundle: bundle,
              name: 'exact challenge.DISQUALIFIERS[$index]',
            ),
        ];

    try {
      return ExactChallenge(result: result, disqualifiers: disqualifiers);
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        'exact challenge is inconsistent: ${error.message}',
      );
    }
  }

  static TranslationPairIssue _parsePairIssue(
    Object? value, {
    required TranslationPair pair,
    required TranslationBundle bundle,
    required String name,
  }) {
    final Map<String, Object?> issue = _object(value, name);
    _requireExactKeys(issue, const <String>{
      'ATOM',
      'STATUS',
      'LEFT',
      'RIGHT',
      'REASON',
    }, name);

    final TranslationSemanticAtom atom = _atom(issue['ATOM'], '$name.ATOM');
    final TranslationIssueStatus status = _status(
      issue['STATUS'],
      '$name.STATUS',
    );
    final String? left = _fragment(
      issue['LEFT'],
      name: '$name.LEFT',
      source: bundle.textFor(pair.leftLanguage),
    );
    final String? right = _fragment(
      issue['RIGHT'],
      name: '$name.RIGHT',
      source: bundle.textFor(pair.rightLanguage),
    );

    try {
      return TranslationPairIssue(
        atom: atom,
        status: status,
        left: left,
        right: right,
        reason: _reason(issue['REASON'], '$name.REASON'),
      );
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        '$name is invalid: ${error.message}',
      );
    }
  }

  static ExactChallengeDisqualifier _parseDisqualifier(
    Object? value, {
    required TranslationBundle bundle,
    required String name,
  }) {
    final Map<String, Object?> item = _object(value, name);
    _requireExactKeys(item, const <String>{
      'PAIR',
      'ATOM',
      'STATUS',
      'LEFT',
      'RIGHT',
      'REASON',
    }, name);

    final String pairCode = _canonicalString(item['PAIR'], '$name.PAIR');
    final TranslationPair pair;
    try {
      pair = TranslationPair.fromCode(pairCode);
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        '$name.PAIR is invalid: ${error.message}',
      );
    }
    if (pair.code != pairCode) {
      throw TyphoonSemanticProtocolException(
        '$name.PAIR must use an uppercase canonical code.',
      );
    }

    try {
      return ExactChallengeDisqualifier(
        pair: pair,
        atom: _atom(item['ATOM'], '$name.ATOM'),
        status: _status(item['STATUS'], '$name.STATUS'),
        left: _fragment(
          item['LEFT'],
          name: '$name.LEFT',
          source: bundle.textFor(pair.leftLanguage),
        ),
        right: _fragment(
          item['RIGHT'],
          name: '$name.RIGHT',
          source: bundle.textFor(pair.rightLanguage),
        ),
        reason: _reason(item['REASON'], '$name.REASON'),
      );
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        '$name is invalid: ${error.message}',
      );
    }
  }

  static TranslationSemanticAtom _atom(Object? value, String name) {
    final String code = _canonicalString(value, name);
    final TranslationSemanticAtom atom;
    try {
      atom = TranslationSemanticAtom.fromCode(code);
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        '$name is invalid: ${error.message}',
      );
    }
    if (atom.code != code) {
      throw TyphoonSemanticProtocolException(
        '$name must use a canonical lowercase atom code.',
      );
    }
    return atom;
  }

  static TranslationIssueStatus _status(Object? value, String name) {
    final String code = _canonicalString(value, name);
    final TranslationIssueStatus status;
    try {
      status = TranslationIssueStatus.fromCode(code);
    } on ArgumentError catch (error) {
      throw TyphoonSemanticProtocolException(
        '$name is invalid: ${error.message}',
      );
    }
    if (status.code != code) {
      throw TyphoonSemanticProtocolException(
        '$name must use canonical X or U.',
      );
    }
    return status;
  }

  static String? _fragment(
    Object? value, {
    required String name,
    required String source,
  }) {
    if (value == null) {
      return null;
    }
    final String fragment = _canonicalString(value, name);
    if (!source.contains(fragment)) {
      throw TyphoonSemanticProtocolException(
        '$name must be an exact substring of its pair text.',
      );
    }
    return fragment;
  }

  static String _reason(Object? value, String name) {
    final String reason = _canonicalString(value, name);
    final int wordCount = RegExp(r'\S+').allMatches(reason).length;
    if (wordCount > _maxReasonWords) {
      throw TyphoonSemanticProtocolException(
        '$name exceeds the $_maxReasonWords-word limit.',
      );
    }
    return reason;
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

  static List<Object?> _array(Object? value, String name) {
    if (value is! List<Object?>) {
      throw TyphoonSemanticProtocolException('$name must be a JSON array.');
    }
    return value;
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
  static const int _maxChallengeDisqualifiers = 3;
  static const int _maxReasonWords = 18;

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
