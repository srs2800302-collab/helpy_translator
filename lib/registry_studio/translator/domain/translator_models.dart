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

enum TranslatorRunStage { directTranslation, audit }

enum TranslatorFailureStage { validation, directTranslation, audit, transport }

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
  accessForbidden,
  requestRejected,
  networkBlocked,
  rateLimited,
  serverFailure,
  networkFailure,
  unexpectedFailure,
  timeout,
  cancelled,
}

final class TranslatorWorkRequest extends Equatable {
  TranslatorWorkRequest({required String sourceText, String? engineerContext})
    : sourceText = _requiredContent(sourceText, 'sourceText'),
      engineerContext = _optionalText(engineerContext);

  final String sourceText;
  final String? engineerContext;

  @override
  List<Object?> get props => <Object?>[sourceText, engineerContext];
}

final class ReverseTranslationBundle extends Equatable {
  ReverseTranslationBundle({
    required String enToRu,
    required String thToRu,
    required String enToTh,
    required String thToEn,
  }) : enToRu = _requiredContent(enToRu, 'enToRu'),
       thToRu = _requiredContent(thToRu, 'thToRu'),
       enToTh = _requiredContent(enToTh, 'enToTh'),
       thToEn = _requiredContent(thToEn, 'thToEn');

  final String enToRu;
  final String thToRu;
  final String enToTh;
  final String thToEn;

  Map<String, String> get sections => <String, String>{
    'EN_TO_RU': enToRu,
    'TH_TO_RU': thToRu,
    'EN_TO_TH': enToTh,
    'TH_TO_EN': thToEn,
  };

  @override
  List<Object?> get props => <Object?>[enToRu, thToRu, enToTh, thToEn];
}

final class TranslationBundle extends Equatable {
  TranslationBundle({
    required this.sourceLanguage,
    required String sourceText,
    required String ru,
    required String en,
    required String th,
    this.reverseTranslations,
  }) : sourceText = _requiredContent(sourceText, 'sourceText'),
       ru = _requiredContent(ru, 'ru'),
       en = _requiredContent(en, 'en'),
       th = _requiredContent(th, 'th') {
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
  final ReverseTranslationBundle? reverseTranslations;

  Map<String, String> get directSections => <String, String>{
    'SOURCE LANGUAGE': sourceLanguage.code,
    'SOURCE TEXT': sourceText,
    'RU': ru,
    'EN': en,
    'TH': th,
  };

  Map<String, String> get allSections => <String, String>{
    ...directSections,
    ...?reverseTranslations?.sections,
  };

  @override
  List<Object?> get props => <Object?>[
    sourceLanguage,
    sourceText,
    ru,
    en,
    th,
    reverseTranslations,
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
  bool get stylePreserved => styleFindings.isEmpty;
  bool get ambiguousWording => ambiguityFindings.isNotEmpty;

  TranslationVerdict get verdict {
    if (meaningFindings.isNotEmpty ||
        terminologyFindings.isNotEmpty ||
        ambiguityFindings.isNotEmpty) {
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

String _requiredContent(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '$name must not be empty.');
  }

  return value;
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
