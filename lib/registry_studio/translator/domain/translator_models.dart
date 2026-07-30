import 'package:equatable/equatable.dart';

enum TranslationLanguage {
  ru('RU'),
  en('EN'),
  th('TH');

  const TranslationLanguage(this.code);

  final String code;

  static TranslationLanguage fromCode(String value) {
    final String normalized = value.trim().toUpperCase();

    for (final TranslationLanguage language in values) {
      if (language.code == normalized) {
        return language;
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'Translation language must be RU, EN or TH.',
    );
  }
}

enum TranslationCompleteness { complete, translationIncomplete }

enum TranslationVerdict { exact, equivalent, needsReview, canonicalDrift }

enum TranslatorRunStage { directTranslation, reverseTranslation, audit }

enum TranslatorFailureStage {
  validation,
  directTranslation,
  reverseTranslation,
  audit,
  transport,
}

enum TranslatorFailureCode {
  sourceTextEmpty,
  accessKeyEmpty,
  accessKeyInvalidCharacters,
  missingRequiredSection,
  emptyRequiredSection,
  placeholderValue,
  unexpectedSection,
  invalidSectionOrder,
  invalidSourceLanguage,
  sourceTextMismatch,
  malformedProviderResponse,
  invalidAuditResponse,
  unauthorized,
  rateLimited,
  serverFailure,
  networkFailure,
  timeout,
  cancelled,
}

final class TranslatorWorkRequest extends Equatable {
  TranslatorWorkRequest({
    required String sourceText,
    this.sourceLanguageHint,
    String? engineerContext,
  }) : sourceText = _requiredText(sourceText, 'sourceText'),
       engineerContext = _optionalText(engineerContext);

  final String sourceText;
  final TranslationLanguage? sourceLanguageHint;
  final String? engineerContext;

  @override
  List<Object?> get props => <Object?>[
    sourceText,
    sourceLanguageHint,
    engineerContext,
  ];
}

final class TranslationBundle extends Equatable {
  TranslationBundle({
    required this.sourceLanguage,
    required String sourceText,
    required String ru,
    required String en,
    required String th,
    required String enToRu,
    required String thToRu,
    required String enToTh,
    required String thToEn,
  }) : sourceText = _requiredText(sourceText, 'sourceText'),
       ru = _requiredText(ru, 'ru'),
       en = _requiredText(en, 'en'),
       th = _requiredText(th, 'th'),
       enToRu = _requiredText(enToRu, 'enToRu'),
       thToRu = _requiredText(thToRu, 'thToRu'),
       enToTh = _requiredText(enToTh, 'enToTh'),
       thToEn = _requiredText(thToEn, 'thToEn') {
    final String sourceLanguageText = switch (sourceLanguage) {
      TranslationLanguage.ru => this.ru,
      TranslationLanguage.en => this.en,
      TranslationLanguage.th => this.th,
    };

    if (sourceLanguageText != this.sourceText) {
      throw ArgumentError(
        'The section matching sourceLanguage must preserve sourceText exactly.',
      );
    }
  }

  final TranslationLanguage sourceLanguage;
  final String sourceText;
  final String ru;
  final String en;
  final String th;
  final String enToRu;
  final String thToRu;
  final String enToTh;
  final String thToEn;

  Map<String, String> get nineSections => <String, String>{
    'SOURCE LANGUAGE': sourceLanguage.code,
    'SOURCE TEXT': sourceText,
    'RU': ru,
    'EN': en,
    'TH': th,
    'EN_TO_RU': enToRu,
    'TH_TO_RU': thToRu,
    'EN_TO_TH': enToTh,
    'TH_TO_EN': thToEn,
  };

  @override
  List<Object?> get props => <Object?>[
    sourceLanguage,
    sourceText,
    ru,
    en,
    th,
    enToRu,
    thToRu,
    enToTh,
    thToEn,
  ];
}

enum TranslationFindingCategory {
  meaning('MEANING'),
  terminology('TERMINOLOGY'),
  style('STYLE'),
  ambiguity('AMBIGUITY');

  const TranslationFindingCategory(this.code);

  final String code;

  static TranslationFindingCategory fromCode(String value) {
    final String normalized = value.trim().toUpperCase();

    for (final TranslationFindingCategory category in values) {
      if (category.code == normalized) {
        return category;
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'Translation finding category is invalid.',
    );
  }
}

enum TranslationEvidenceKind { structured, legacy }

final class TranslationFinding extends Equatable {
  TranslationFinding({
    required this.category,
    required TranslationLanguage section,
    required String sourceFragment,
    required String translationFragment,
    required String reason,
    required String impact,
    required String correctVariant,
    required String sourceAmbiguity,
  }) : kind = TranslationEvidenceKind.structured,
       section = section,
       sourceFragment = _requiredText(sourceFragment, 'sourceFragment'),
       translationFragment = _requiredText(
         translationFragment,
         'translationFragment',
       ),
       reason = _requiredText(reason, 'reason'),
       impact = _requiredText(impact, 'impact'),
       correctVariant = _requiredText(correctVariant, 'correctVariant'),
       sourceAmbiguity = _requiredText(sourceAmbiguity, 'sourceAmbiguity'),
       legacyMessage = null;

  TranslationFinding.legacy({
    required this.category,
    required String message,
  }) : kind = TranslationEvidenceKind.legacy,
       section = null,
       sourceFragment = null,
       translationFragment = null,
       reason = null,
       impact = null,
       correctVariant = null,
       sourceAmbiguity = null,
       legacyMessage = _requiredText(message, 'message');

  final TranslationFindingCategory category;
  final TranslationEvidenceKind kind;
  final TranslationLanguage? section;
  final String? sourceFragment;
  final String? translationFragment;
  final String? reason;
  final String? impact;
  final String? correctVariant;
  final String? sourceAmbiguity;
  final String? legacyMessage;

  bool get isLegacy => kind == TranslationEvidenceKind.legacy;

  String get displayText => isLegacy ? legacyMessage! : reason!;

  @override
  List<Object?> get props => <Object?>[
    category,
    kind,
    section,
    sourceFragment,
    translationFragment,
    reason,
    impact,
    correctVariant,
    sourceAmbiguity,
    legacyMessage,
  ];
}

final class TranslationAudit extends Equatable {
  TranslationAudit({
    Iterable<TranslationFinding> findings = const <TranslationFinding>[],
    Iterable<String> meaningFindings = const <String>[],
    Iterable<String> terminologyFindings = const <String>[],
    Iterable<String> styleFindings = const <String>[],
    Iterable<String> ambiguityFindings = const <String>[],
  }) : findings = _translationFindings(<TranslationFinding>[
         ...findings,
         ..._legacyFindings(
           TranslationFindingCategory.meaning,
           meaningFindings,
         ),
         ..._legacyFindings(
           TranslationFindingCategory.terminology,
           terminologyFindings,
         ),
         ..._legacyFindings(TranslationFindingCategory.style, styleFindings),
         ..._legacyFindings(
           TranslationFindingCategory.ambiguity,
           ambiguityFindings,
         ),
       ]);

  final List<TranslationFinding> findings;

  List<String> get meaningFindings =>
      _displayFindings(TranslationFindingCategory.meaning);

  List<String> get terminologyFindings =>
      _displayFindings(TranslationFindingCategory.terminology);

  List<String> get styleFindings =>
      _displayFindings(TranslationFindingCategory.style);

  List<String> get ambiguityFindings =>
      _displayFindings(TranslationFindingCategory.ambiguity);

  bool get meaningPreserved =>
      !_hasFinding(TranslationFindingCategory.meaning);

  bool get terminologyPreserved =>
      !_hasFinding(TranslationFindingCategory.terminology);

  bool get canonicalStylePreserved =>
      !_hasFinding(TranslationFindingCategory.style);

  bool get ambiguousWording =>
      _hasFinding(TranslationFindingCategory.ambiguity);

  TranslationVerdict get verdict {
    if (!meaningPreserved) {
      return TranslationVerdict.canonicalDrift;
    }

    if (meaningPreserved &&
        terminologyPreserved &&
        canonicalStylePreserved &&
        !ambiguousWording) {
      return TranslationVerdict.exact;
    }

    if (meaningPreserved &&
        terminologyPreserved &&
        !ambiguousWording) {
      return TranslationVerdict.equivalent;
    }

    return TranslationVerdict.needsReview;
  }

  bool _hasFinding(TranslationFindingCategory category) {
    return findings.any(
      (TranslationFinding finding) => finding.category == category,
    );
  }

  List<String> _displayFindings(TranslationFindingCategory category) {
    return List<String>.unmodifiable(
      findings
          .where(
            (TranslationFinding finding) => finding.category == category,
          )
          .map((TranslationFinding finding) => finding.displayText),
    );
  }

  @override
  List<Object?> get props => <Object?>[findings];
}

final class TranslatorRunReport extends Equatable {
  const TranslatorRunReport({
    required this.request,
    required this.bundle,
    required this.audit,
    required this.createdAt,
  });

  final TranslatorWorkRequest request;
  final TranslationBundle bundle;
  final TranslationAudit audit;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[request, bundle, audit, createdAt];
}

final class TranslatorFailure extends Equatable {
  TranslatorFailure({
    required this.stage,
    required this.code,
    required String message,
    this.completeness,
    this.partialBundle,
  }) : message = _requiredText(message, 'message');

  final TranslatorFailureStage stage;
  final TranslatorFailureCode code;
  final String message;
  final TranslationCompleteness? completeness;
  final TranslationBundle? partialBundle;

  bool get isCancelled => code == TranslatorFailureCode.cancelled;

  @override
  List<Object?> get props => <Object?>[
    stage,
    code,
    message,
    completeness,
    partialBundle,
  ];
}

String _requiredText(String value, String name) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '$name must not be empty.');
  }
  return normalized;
}

String? _optionalText(String? value) {
  if (value == null) {
    return null;
  }

  final String normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

Iterable<TranslationFinding> _legacyFindings(
  TranslationFindingCategory category,
  Iterable<String> values,
) sync* {
  for (final String value in values) {
    final String normalized = value.trim();

    if (normalized.isNotEmpty) {
      yield TranslationFinding.legacy(
        category: category,
        message: normalized,
      );
    }
  }
}

List<TranslationFinding> _translationFindings(
  Iterable<TranslationFinding> values,
) {
  final List<TranslationFinding> normalized = values.toList(growable: false);

  if (normalized.toSet().length != normalized.length) {
    throw ArgumentError.value(
      values,
      'findings',
      'findings contains duplicates.',
    );
  }

  return List<TranslationFinding>.unmodifiable(normalized);
}
