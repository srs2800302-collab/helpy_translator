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

final class TranslationAudit extends Equatable {
  TranslationAudit({
    Iterable<String> meaningFindings = const <String>[],
    Iterable<String> terminologyFindings = const <String>[],
    Iterable<String> styleFindings = const <String>[],
    Iterable<String> ambiguityFindings = const <String>[],
  }) : meaningFindings = _findings(meaningFindings, 'meaningFindings'),
       terminologyFindings = _findings(
         terminologyFindings,
         'terminologyFindings',
       ),
       styleFindings = _findings(styleFindings, 'styleFindings'),
       ambiguityFindings = _findings(ambiguityFindings, 'ambiguityFindings');

  final List<String> meaningFindings;
  final List<String> terminologyFindings;
  final List<String> styleFindings;
  final List<String> ambiguityFindings;

  bool get meaningPreserved => meaningFindings.isEmpty;
  bool get terminologyPreserved => terminologyFindings.isEmpty;
  bool get canonicalStylePreserved => styleFindings.isEmpty;
  bool get ambiguousWording => ambiguityFindings.isNotEmpty;

  TranslationVerdict get verdict {
    if (meaningFindings.isNotEmpty) {
      return TranslationVerdict.canonicalDrift;
    }
    if (terminologyFindings.isNotEmpty || ambiguityFindings.isNotEmpty) {
      return TranslationVerdict.needsReview;
    }
    if (styleFindings.isNotEmpty) {
      return TranslationVerdict.equivalent;
    }
    return TranslationVerdict.exact;
  }

  @override
  List<Object?> get props => <Object?>[
    meaningFindings,
    terminologyFindings,
    styleFindings,
    ambiguityFindings,
  ];
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

List<String> _findings(Iterable<String> values, String name) {
  final List<String> normalized = values
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);

  if (normalized.toSet().length != normalized.length) {
    throw ArgumentError.value(values, name, '$name contains duplicates.');
  }

  return List<String>.unmodifiable(normalized);
}
