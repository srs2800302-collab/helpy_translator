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

enum TranslationPair {
  ruEn('RU_EN', TranslationLanguage.ru, TranslationLanguage.en),
  ruTh('RU_TH', TranslationLanguage.ru, TranslationLanguage.th),
  enTh('EN_TH', TranslationLanguage.en, TranslationLanguage.th);

  const TranslationPair(this.code, this.leftLanguage, this.rightLanguage);

  final String code;
  final TranslationLanguage leftLanguage;
  final TranslationLanguage rightLanguage;

  static TranslationPair fromCode(String value) {
    final String normalized = value.trim().toUpperCase();

    for (final TranslationPair pair in values) {
      if (pair.code == normalized) {
        return pair;
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'Translation pair must be RU_EN, RU_TH or EN_TH.',
    );
  }
}

enum TranslationSemanticAtom {
  action('action'),
  objectIdentity('object'),
  equipmentIdentity('equipment_identity'),
  actor('actor'),
  roleSpecificity('role_specificity'),
  polarity('polarity'),
  modality('modality'),
  permission('permission'),
  obligation('obligation'),
  quantity('quantity'),
  time('time'),
  condition('condition'),
  sequence('sequence'),
  scope('scope'),
  ambiguity('ambiguity'),
  canonicalStyle('canonical_style');

  const TranslationSemanticAtom(this.code);

  final String code;

  static TranslationSemanticAtom fromCode(String value) {
    final String normalized = value.trim().toLowerCase();

    for (final TranslationSemanticAtom atom in values) {
      if (atom.code == normalized) {
        return atom;
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'Translation semantic atom is invalid.',
    );
  }
}

enum TranslationIssueStatus {
  mismatch('X'),
  unknown('U');

  const TranslationIssueStatus(this.code);

  final String code;

  static TranslationIssueStatus fromCode(String value) {
    final String normalized = value.trim().toUpperCase();

    for (final TranslationIssueStatus status in values) {
      if (status.code == normalized) {
        return status;
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'Translation issue status must be X or U.',
    );
  }
}

enum TranslationPairAuditResult {
  clear('CLEAR'),
  blocked('BLOCKED'),
  unproven('UNPROVEN');

  const TranslationPairAuditResult(this.code);

  final String code;

  static TranslationPairAuditResult fromCode(String value) {
    final String normalized = value.trim().toUpperCase();

    for (final TranslationPairAuditResult result in values) {
      if (result.code == normalized) {
        return result;
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'Pair audit result must be CLEAR, BLOCKED or UNPROVEN.',
    );
  }
}

enum ExactChallengeResult {
  clear('CLEAR'),
  blocked('BLOCKED'),
  unproven('UNPROVEN'),
  protocolFailure('PROTOCOL_FAILURE');

  const ExactChallengeResult(this.code);

  final String code;

  static ExactChallengeResult fromCode(String value) {
    final String normalized = value.trim().toUpperCase();

    for (final ExactChallengeResult result in values) {
      if (result.code == normalized) {
        return result;
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'Exact challenge result is invalid.',
    );
  }
}

enum TranslationCompleteness { complete, translationIncomplete }

enum TranslationVerdict { exact, equivalent, needsReview, canonicalDrift }

enum TranslatorRunStage {
  directTranslation,
  audit,
  exactCertification,
  reverseTranslation,
}

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
    String? enToRu,
    String? thToRu,
    String? enToTh,
    String? thToEn,
  }) : sourceText = _requiredExactText(sourceText, 'sourceText'),
       ru = _requiredExactText(ru, 'ru'),
       en = _requiredExactText(en, 'en'),
       th = _requiredExactText(th, 'th'),
       enToRu = _optionalText(enToRu),
       thToRu = _optionalText(thToRu),
       enToTh = _optionalText(enToTh),
       thToEn = _optionalText(thToEn) {
    final String sourceLanguageText = textFor(sourceLanguage);

    if (sourceLanguageText != this.sourceText) {
      throw ArgumentError(
        'The section matching sourceLanguage must preserve sourceText exactly.',
      );
    }

    final int reverseSectionCount = <String?>[
      this.enToRu,
      this.thToRu,
      this.enToTh,
      this.thToEn,
    ].whereType<String>().length;

    if (reverseSectionCount != 0 && reverseSectionCount != 4) {
      throw ArgumentError(
        'Reverse diagnostics must contain all four sections or none.',
      );
    }
  }

  final TranslationLanguage sourceLanguage;
  final String sourceText;
  final String ru;
  final String en;
  final String th;
  final String? enToRu;
  final String? thToRu;
  final String? enToTh;
  final String? thToEn;

  bool get hasReverseDiagnostics => enToRu != null;

  String textFor(TranslationLanguage language) {
    return switch (language) {
      TranslationLanguage.ru => ru,
      TranslationLanguage.en => en,
      TranslationLanguage.th => th,
    };
  }

  Map<String, String> get fiveSections => <String, String>{
    'SOURCE LANGUAGE': sourceLanguage.code,
    'SOURCE TEXT': sourceText,
    'RU': ru,
    'EN': en,
    'TH': th,
  };

  Map<String, String> get nineSections => <String, String>{
    ...fiveSections,
    'EN_TO_RU': ?enToRu,
    'TH_TO_RU': ?thToRu,
    'EN_TO_TH': ?enToTh,
    'TH_TO_EN': ?thToEn,
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

final class LocalizedEvidenceText extends Equatable {
  LocalizedEvidenceText({
    required String ru,
    required String en,
    required String th,
  }) : ru = _requiredText(ru, 'ru'),
       en = _requiredText(en, 'en'),
       th = _requiredText(th, 'th');

  final String ru;
  final String en;
  final String th;

  String forLanguage(TranslationLanguage language) {
    return switch (language) {
      TranslationLanguage.ru => ru,
      TranslationLanguage.en => en,
      TranslationLanguage.th => th,
    };
  }

  @override
  List<Object?> get props => <Object?>[ru, en, th];
}

enum TranslationEvidenceKind { multilingual, russianOnly, legacy }

final class TranslationFinding extends Equatable {
  TranslationFinding({
    required this.category,
    required TranslationLanguage this.section,
    required String sourceFragment,
    required String translationFragment,
    required String reason,
    required String impact,
    required String correctVariant,
    required String sourceAmbiguity,
  }) : kind = TranslationEvidenceKind.russianOnly,
       sourceFragment = _requiredText(sourceFragment, 'sourceFragment'),
       translationFragment = _requiredText(
         translationFragment,
         'translationFragment',
       ),
       reason = _requiredText(reason, 'reason'),
       impact = _requiredText(impact, 'impact'),
       correctVariant = _requiredText(correctVariant, 'correctVariant'),
       sourceAmbiguity = _requiredText(sourceAmbiguity, 'sourceAmbiguity'),
       localizedReason = null,
       localizedImpact = null,
       localizedSourceAmbiguity = null,
       legacyMessage = null;

  TranslationFinding.multilingual({
    required this.category,
    required TranslationLanguage this.section,
    required String sourceFragment,
    required String translationFragment,
    required LocalizedEvidenceText reason,
    required LocalizedEvidenceText impact,
    required String correctVariant,
    required LocalizedEvidenceText? sourceAmbiguity,
  }) : kind = TranslationEvidenceKind.multilingual,
       sourceFragment = _requiredText(sourceFragment, 'sourceFragment'),
       translationFragment = _requiredText(
         translationFragment,
         'translationFragment',
       ),
       reason = reason.ru,
       impact = impact.ru,
       correctVariant = _requiredText(correctVariant, 'correctVariant'),
       sourceAmbiguity = sourceAmbiguity?.ru ?? 'NONE',
       localizedReason = reason,
       localizedImpact = impact,
       localizedSourceAmbiguity = sourceAmbiguity,
       legacyMessage = null;

  TranslationFinding.legacy({required this.category, required String message})
    : kind = TranslationEvidenceKind.legacy,
      section = null,
      sourceFragment = null,
      translationFragment = null,
      reason = null,
      impact = null,
      correctVariant = null,
      sourceAmbiguity = null,
      localizedReason = null,
      localizedImpact = null,
      localizedSourceAmbiguity = null,
      legacyMessage = _requiredText(message, 'message');

  final TranslationEvidenceKind kind;
  final TranslationFindingCategory category;
  final TranslationLanguage? section;
  final String? sourceFragment;
  final String? translationFragment;
  final String? reason;
  final String? impact;
  final String? correctVariant;
  final String? sourceAmbiguity;
  final LocalizedEvidenceText? localizedReason;
  final LocalizedEvidenceText? localizedImpact;
  final LocalizedEvidenceText? localizedSourceAmbiguity;
  final String? legacyMessage;

  bool get isMultilingual => kind == TranslationEvidenceKind.multilingual;

  bool get isRussianOnly => kind == TranslationEvidenceKind.russianOnly;

  bool get isLegacy => kind == TranslationEvidenceKind.legacy;

  String reasonFor(TranslationLanguage language) {
    if (isLegacy) {
      throw StateError('Legacy evidence has no structured reason.');
    }

    return localizedReason?.forLanguage(language) ?? reason!;
  }

  String impactFor(TranslationLanguage language) {
    if (isLegacy) {
      throw StateError('Legacy evidence has no structured impact.');
    }

    return localizedImpact?.forLanguage(language) ?? impact!;
  }

  String? sourceAmbiguityFor(TranslationLanguage language) {
    if (isLegacy) {
      throw StateError('Legacy evidence has no structured ambiguity.');
    }

    if (localizedSourceAmbiguity != null) {
      return localizedSourceAmbiguity!.forLanguage(language);
    }

    if (isRussianOnly && sourceAmbiguity != 'NONE') {
      return sourceAmbiguity;
    }

    return null;
  }

  String get displayText => isLegacy ? legacyMessage! : reason!;

  @override
  List<Object?> get props => <Object?>[
    kind,
    category,
    section,
    sourceFragment,
    translationFragment,
    reason,
    impact,
    correctVariant,
    sourceAmbiguity,
    localizedReason,
    localizedImpact,
    localizedSourceAmbiguity,
    legacyMessage,
  ];
}

final class TranslationPairIssue extends Equatable {
  TranslationPairIssue({
    required this.atom,
    required this.status,
    String? left,
    String? right,
    required String reason,
  }) : left = _optionalText(left),
       right = _optionalText(right),
       reason = _requiredText(reason, 'reason') {
    if (this.left == null && this.right == null) {
      throw ArgumentError(
        'Translation pair issue must contain at least one evidence fragment.',
      );
    }
    if (atom == TranslationSemanticAtom.ambiguity &&
        status == TranslationIssueStatus.mismatch) {
      throw ArgumentError('Unresolved ambiguity must use U rather than X.');
    }
  }

  final TranslationSemanticAtom atom;
  final TranslationIssueStatus status;
  final String? left;
  final String? right;
  final String reason;

  @override
  List<Object?> get props => <Object?>[atom, status, left, right, reason];
}

final class TranslationPairAudit extends Equatable {
  TranslationPairAudit({
    required this.pair,
    required this.result,
    Iterable<TranslationPairIssue> issues = const <TranslationPairIssue>[],
  }) : issues = List<TranslationPairIssue>.unmodifiable(issues) {
    if (this.issues.length > 2) {
      throw ArgumentError.value(
        issues,
        'issues',
        'Pair audit must contain at most two issues.',
      );
    }

    final Set<TranslationSemanticAtom> atoms = this.issues
        .map((TranslationPairIssue issue) => issue.atom)
        .toSet();

    if (atoms.length != this.issues.length) {
      throw ArgumentError.value(
        issues,
        'issues',
        'Pair audit contains duplicate semantic atoms.',
      );
    }

    final bool hasMismatch = this.issues.any(
      (TranslationPairIssue issue) =>
          issue.status == TranslationIssueStatus.mismatch,
    );
    final bool hasUnknown = this.issues.any(
      (TranslationPairIssue issue) =>
          issue.status == TranslationIssueStatus.unknown,
    );

    switch (result) {
      case TranslationPairAuditResult.clear:
        if (this.issues.isNotEmpty) {
          throw ArgumentError('CLEAR pair audit must have no issues.');
        }
      case TranslationPairAuditResult.blocked:
        if (!hasMismatch) {
          throw ArgumentError('BLOCKED pair audit must contain an X issue.');
        }
      case TranslationPairAuditResult.unproven:
        if (!hasUnknown || hasMismatch) {
          throw ArgumentError(
            'UNPROVEN pair audit must contain U issues and no X issues.',
          );
        }
    }
  }

  final TranslationPair pair;
  final TranslationPairAuditResult result;
  final List<TranslationPairIssue> issues;

  @override
  List<Object?> get props => <Object?>[pair, result, issues];
}

final class ExactChallengeDisqualifier extends Equatable {
  ExactChallengeDisqualifier({
    required this.pair,
    required this.atom,
    required this.status,
    String? left,
    String? right,
    required String reason,
  }) : left = _optionalText(left),
       right = _optionalText(right),
       reason = _requiredText(reason, 'reason') {
    if (this.left == null && this.right == null) {
      throw ArgumentError(
        'Exact challenge disqualifier must contain evidence.',
      );
    }
    if (atom == TranslationSemanticAtom.ambiguity &&
        status == TranslationIssueStatus.mismatch) {
      throw ArgumentError('Unresolved ambiguity must use U rather than X.');
    }
  }

  final TranslationPair pair;
  final TranslationSemanticAtom atom;
  final TranslationIssueStatus status;
  final String? left;
  final String? right;
  final String reason;

  @override
  List<Object?> get props => <Object?>[pair, atom, status, left, right, reason];
}

final class ExactChallenge extends Equatable {
  ExactChallenge({
    required this.result,
    Iterable<ExactChallengeDisqualifier> disqualifiers =
        const <ExactChallengeDisqualifier>[],
  }) : disqualifiers = List<ExactChallengeDisqualifier>.unmodifiable(
         disqualifiers,
       ) {
    if (this.disqualifiers.length > 3) {
      throw ArgumentError.value(
        disqualifiers,
        'disqualifiers',
        'Exact challenge must contain at most three disqualifiers.',
      );
    }

    final Set<(TranslationPair, TranslationSemanticAtom)> identities = this
        .disqualifiers
        .map((ExactChallengeDisqualifier item) => (item.pair, item.atom))
        .toSet();
    if (identities.length != this.disqualifiers.length) {
      throw ArgumentError.value(
        disqualifiers,
        'disqualifiers',
        'Exact challenge contains duplicate pair/atom evidence.',
      );
    }

    final bool hasMismatch = this.disqualifiers.any(
      (ExactChallengeDisqualifier item) =>
          item.status == TranslationIssueStatus.mismatch,
    );
    final bool hasUnknown = this.disqualifiers.any(
      (ExactChallengeDisqualifier item) =>
          item.status == TranslationIssueStatus.unknown,
    );

    switch (result) {
      case ExactChallengeResult.clear:
        if (this.disqualifiers.isNotEmpty) {
          throw ArgumentError('CLEAR challenge must have no disqualifiers.');
        }
      case ExactChallengeResult.blocked:
        if (!hasMismatch) {
          throw ArgumentError('BLOCKED challenge must contain at least one X.');
        }
      case ExactChallengeResult.unproven:
        if (!hasUnknown || hasMismatch) {
          throw ArgumentError(
            'UNPROVEN challenge must contain U items and no X items.',
          );
        }
      case ExactChallengeResult.protocolFailure:
        if (this.disqualifiers.isNotEmpty) {
          throw ArgumentError(
            'Protocol-failure challenge must not contain disqualifiers.',
          );
        }
    }
  }

  final ExactChallengeResult result;
  final List<ExactChallengeDisqualifier> disqualifiers;

  @override
  List<Object?> get props => <Object?>[result, disqualifiers];
}

final class TranslationAudit extends Equatable {
  TranslationAudit({
    Iterable<TranslationFinding> findings = const <TranslationFinding>[],
    Iterable<String> meaningFindings = const <String>[],
    Iterable<String> terminologyFindings = const <String>[],
    Iterable<String> styleFindings = const <String>[],
    Iterable<String> ambiguityFindings = const <String>[],
    Iterable<TranslationPairAudit> pairAudits = const <TranslationPairAudit>[],
    this.exactChallenge,
    this.protocolFallback = false,
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
       ]),
       pairAudits = _pairAudits(pairAudits) {
    final bool hasSemanticEvidence =
        this.pairAudits.isNotEmpty || exactChallenge != null;

    if (protocolFallback && (this.findings.isNotEmpty || hasSemanticEvidence)) {
      throw ArgumentError(
        'Protocol-fallback audit must not contain other evidence.',
      );
    }

    if (this.findings.isNotEmpty && hasSemanticEvidence) {
      throw ArgumentError(
        'Legacy findings and semantic-protocol evidence must not be mixed.',
      );
    }

    if (exactChallenge != null && !candidateForExact) {
      throw ArgumentError('Exact challenge requires three CLEAR pair audits.');
    }
  }

  final List<TranslationFinding> findings;
  final List<TranslationPairAudit> pairAudits;
  final ExactChallenge? exactChallenge;
  final bool protocolFallback;

  bool get usesSemanticProtocol =>
      protocolFallback || pairAudits.isNotEmpty || exactChallenge != null;

  bool get candidateForExact =>
      pairAudits.length == TranslationPair.values.length &&
      pairAudits.every(
        (TranslationPairAudit audit) =>
            audit.result == TranslationPairAuditResult.clear,
      );

  bool get auditProtocolFailed => protocolFallback;

  bool get exactChallengeProtocolFailed =>
      exactChallenge?.result == ExactChallengeResult.protocolFailure;

  bool get auditChallengerConflict =>
      candidateForExact &&
      exactChallenge != null &&
      exactChallenge!.result != ExactChallengeResult.clear &&
      exactChallenge!.result != ExactChallengeResult.protocolFailure;

  List<String> get meaningFindings =>
      _displayFindings(TranslationFindingCategory.meaning);

  List<String> get terminologyFindings =>
      _displayFindings(TranslationFindingCategory.terminology);

  List<String> get styleFindings =>
      _displayFindings(TranslationFindingCategory.style);

  List<String> get ambiguityFindings =>
      _displayFindings(TranslationFindingCategory.ambiguity);

  Iterable<TranslationPairIssue> get semanticIssues sync* {
    for (final TranslationPairAudit audit in pairAudits) {
      yield* audit.issues;
    }
  }

  bool get meaningPreserved {
    if (!usesSemanticProtocol) {
      return !_hasFinding(TranslationFindingCategory.meaning);
    }

    return !semanticIssues.any(
      (TranslationPairIssue issue) =>
          issue.atom != TranslationSemanticAtom.canonicalStyle,
    );
  }

  bool get terminologyPreserved {
    if (!usesSemanticProtocol) {
      return !_hasFinding(TranslationFindingCategory.terminology);
    }

    return !semanticIssues.any(
      (TranslationPairIssue issue) =>
          issue.atom == TranslationSemanticAtom.equipmentIdentity ||
          issue.atom == TranslationSemanticAtom.roleSpecificity,
    );
  }

  bool get canonicalStylePreserved {
    if (!usesSemanticProtocol) {
      return !_hasFinding(TranslationFindingCategory.style);
    }

    return !semanticIssues.any(
      (TranslationPairIssue issue) =>
          issue.atom == TranslationSemanticAtom.canonicalStyle,
    );
  }

  bool get ambiguousWording {
    if (!usesSemanticProtocol) {
      return _hasFinding(TranslationFindingCategory.ambiguity);
    }

    return semanticIssues.any(
      (TranslationPairIssue issue) =>
          issue.atom == TranslationSemanticAtom.ambiguity,
    );
  }

  TranslationVerdict get verdict {
    if (usesSemanticProtocol) {
      if (protocolFallback) {
        return TranslationVerdict.needsReview;
      }

      final List<TranslationPairIssue> issues = semanticIssues.toList(
        growable: false,
      );

      if (issues.any(
        (TranslationPairIssue issue) =>
            issue.status == TranslationIssueStatus.mismatch &&
            issue.atom != TranslationSemanticAtom.canonicalStyle &&
            issue.atom != TranslationSemanticAtom.ambiguity,
      )) {
        return TranslationVerdict.canonicalDrift;
      }

      if (issues.any(
        (TranslationPairIssue issue) =>
            issue.status == TranslationIssueStatus.unknown ||
            issue.atom == TranslationSemanticAtom.ambiguity,
      )) {
        return TranslationVerdict.needsReview;
      }

      if (issues.any(
        (TranslationPairIssue issue) =>
            issue.status == TranslationIssueStatus.mismatch &&
            issue.atom == TranslationSemanticAtom.canonicalStyle,
      )) {
        return TranslationVerdict.equivalent;
      }

      if (candidateForExact &&
          exactChallenge?.result == ExactChallengeResult.clear) {
        return TranslationVerdict.exact;
      }

      return TranslationVerdict.needsReview;
    }

    if (!meaningPreserved) {
      return TranslationVerdict.canonicalDrift;
    }

    if (findings.isEmpty) {
      return TranslationVerdict.needsReview;
    }

    if (meaningPreserved && terminologyPreserved && !ambiguousWording) {
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
          .where((TranslationFinding finding) => finding.category == category)
          .map((TranslationFinding finding) => finding.displayText),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    findings,
    pairAudits,
    exactChallenge,
    protocolFallback,
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

String _requiredExactText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '$name must not be empty.');
  }

  if (value != value.trim()) {
    throw ArgumentError.value(
      value,
      name,
      '$name must not contain outer whitespace.',
    );
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

Iterable<TranslationFinding> _legacyFindings(
  TranslationFindingCategory category,
  Iterable<String> values,
) sync* {
  for (final String value in values) {
    final String normalized = value.trim();

    if (normalized.isNotEmpty) {
      yield TranslationFinding.legacy(category: category, message: normalized);
    }
  }
}

final class _TranslationFindingIdentity extends Equatable {
  const _TranslationFindingIdentity({
    required this.legacy,
    this.legacyCategory,
    this.section,
    this.sourceFragment,
    this.translationFragment,
    this.legacyMessage,
  });

  factory _TranslationFindingIdentity.fromFinding(TranslationFinding finding) {
    return _TranslationFindingIdentity(
      legacy: finding.isLegacy,
      legacyCategory: finding.isLegacy ? finding.category : null,
      section: finding.section,
      sourceFragment: finding.sourceFragment,
      translationFragment: finding.translationFragment,
      legacyMessage: finding.legacyMessage,
    );
  }

  final bool legacy;
  final TranslationFindingCategory? legacyCategory;
  final TranslationLanguage? section;
  final String? sourceFragment;
  final String? translationFragment;
  final String? legacyMessage;

  @override
  List<Object?> get props => <Object?>[
    legacy,
    legacyCategory,
    section,
    sourceFragment,
    translationFragment,
    legacyMessage,
  ];
}

List<TranslationFinding> _translationFindings(
  Iterable<TranslationFinding> values,
) {
  final List<TranslationFinding> normalized = values.toList(growable: false);
  final Set<_TranslationFindingIdentity> identities = normalized
      .map(_TranslationFindingIdentity.fromFinding)
      .toSet();

  if (identities.length != normalized.length) {
    throw ArgumentError.value(
      values,
      'findings',
      'findings contains semantic duplicates.',
    );
  }

  return List<TranslationFinding>.unmodifiable(normalized);
}

List<TranslationPairAudit> _pairAudits(Iterable<TranslationPairAudit> values) {
  final List<TranslationPairAudit> normalized = values.toList(growable: false);

  if (normalized.isEmpty) {
    return const <TranslationPairAudit>[];
  }

  final Set<TranslationPair> pairs = normalized
      .map((TranslationPairAudit audit) => audit.pair)
      .toSet();

  if (normalized.length != TranslationPair.values.length ||
      pairs.length != TranslationPair.values.length ||
      !pairs.containsAll(TranslationPair.values)) {
    throw ArgumentError.value(
      values,
      'pairAudits',
      'Semantic audit must contain every translation pair exactly once.',
    );
  }

  normalized.sort(
    (TranslationPairAudit left, TranslationPairAudit right) =>
        left.pair.index.compareTo(right.pair.index),
  );
  return List<TranslationPairAudit>.unmodifiable(normalized);
}
