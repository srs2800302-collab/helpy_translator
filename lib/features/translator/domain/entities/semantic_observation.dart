import 'package:equatable/equatable.dart';

import 'translation_route.dart';

enum SemanticRelation {
  addition,
  omission,
  substitution,
  contradiction,
  scopeChange,
  ambiguityResolution,
  wordingVariation,
  registerChange,
  unknown;

  static SemanticRelation parseCode(String value) {
    return switch (_normalizeCode(value)) {
      'ADDITION' => SemanticRelation.addition,
      'OMISSION' => SemanticRelation.omission,
      'SUBSTITUTION' => SemanticRelation.substitution,
      'CONTRADICTION' => SemanticRelation.contradiction,
      'SCOPE_CHANGE' => SemanticRelation.scopeChange,
      'AMBIGUITY_RESOLUTION' => SemanticRelation.ambiguityResolution,
      'WORDING_VARIATION' => SemanticRelation.wordingVariation,
      'REGISTER_CHANGE' => SemanticRelation.registerChange,
      _ => SemanticRelation.unknown,
    };
  }

  String get code {
    return switch (this) {
      SemanticRelation.addition => 'ADDITION',
      SemanticRelation.omission => 'OMISSION',
      SemanticRelation.substitution => 'SUBSTITUTION',
      SemanticRelation.contradiction => 'CONTRADICTION',
      SemanticRelation.scopeChange => 'SCOPE_CHANGE',
      SemanticRelation.ambiguityResolution => 'AMBIGUITY_RESOLUTION',
      SemanticRelation.wordingVariation => 'WORDING_VARIATION',
      SemanticRelation.registerChange => 'REGISTER_CHANGE',
      SemanticRelation.unknown => 'UNKNOWN',
    };
  }
}

enum SemanticDimension {
  proposition,
  negation,
  modality,
  quantity,
  time,
  condition,
  actor,
  object,
  direction,
  cause,
  restriction,
  ambiguity,
  terminology,
  specificity,
  register,
  style,
  formality,
  lexicalChoice,
  other,
  unknown;

  static SemanticDimension parseCode(String value) {
    return switch (_normalizeCode(value)) {
      'PROPOSITION' => SemanticDimension.proposition,
      'NEGATION' => SemanticDimension.negation,
      'MODALITY' => SemanticDimension.modality,
      'QUANTITY' => SemanticDimension.quantity,
      'TIME' => SemanticDimension.time,
      'CONDITION' => SemanticDimension.condition,
      'ACTOR' => SemanticDimension.actor,
      'OBJECT' => SemanticDimension.object,
      'DIRECTION' => SemanticDimension.direction,
      'CAUSE' => SemanticDimension.cause,
      'RESTRICTION' => SemanticDimension.restriction,
      'AMBIGUITY' => SemanticDimension.ambiguity,
      'TERMINOLOGY' => SemanticDimension.terminology,
      'SPECIFICITY' => SemanticDimension.specificity,
      'REGISTER' => SemanticDimension.register,
      'STYLE' => SemanticDimension.style,
      'FORMALITY' => SemanticDimension.formality,
      'LEXICAL_CHOICE' => SemanticDimension.lexicalChoice,
      'OTHER' => SemanticDimension.other,
      _ => SemanticDimension.unknown,
    };
  }

  String get code {
    return switch (this) {
      SemanticDimension.proposition => 'PROPOSITION',
      SemanticDimension.negation => 'NEGATION',
      SemanticDimension.modality => 'MODALITY',
      SemanticDimension.quantity => 'QUANTITY',
      SemanticDimension.time => 'TIME',
      SemanticDimension.condition => 'CONDITION',
      SemanticDimension.actor => 'ACTOR',
      SemanticDimension.object => 'OBJECT',
      SemanticDimension.direction => 'DIRECTION',
      SemanticDimension.cause => 'CAUSE',
      SemanticDimension.restriction => 'RESTRICTION',
      SemanticDimension.ambiguity => 'AMBIGUITY',
      SemanticDimension.terminology => 'TERMINOLOGY',
      SemanticDimension.specificity => 'SPECIFICITY',
      SemanticDimension.register => 'REGISTER',
      SemanticDimension.style => 'STYLE',
      SemanticDimension.formality => 'FORMALITY',
      SemanticDimension.lexicalChoice => 'LEXICAL_CHOICE',
      SemanticDimension.other => 'OTHER',
      SemanticDimension.unknown => 'UNKNOWN',
    };
  }
}

enum MeaningPreservation {
  preserved,
  altered,
  unknown;

  static MeaningPreservation parseCode(String value) {
    return switch (_normalizeCode(value)) {
      'PRESERVED' => MeaningPreservation.preserved,
      'ALTERED' => MeaningPreservation.altered,
      _ => MeaningPreservation.unknown,
    };
  }

  String get code {
    return switch (this) {
      MeaningPreservation.preserved => 'PRESERVED',
      MeaningPreservation.altered => 'ALTERED',
      MeaningPreservation.unknown => 'UNKNOWN',
    };
  }
}

enum ObservationVerificationStatus { confirmed, conflict, unverifiable }

final class SemanticObservation extends Equatable {
  const SemanticObservation({
    required this.routeId,
    required this.routeRole,
    required this.relation,
    required this.dimension,
    required this.preservation,
    required this.verificationStatus,
    required this.sourceExcerpt,
    required this.targetExcerpt,
    this.verifierRelation,
    this.verifierDimension,
    this.verifierPreservation,
  });

  final String routeId;
  final TranslationRouteRole routeRole;
  final SemanticRelation relation;
  final SemanticDimension dimension;
  final MeaningPreservation preservation;
  final ObservationVerificationStatus verificationStatus;
  final String? sourceExcerpt;
  final String? targetExcerpt;

  /// Populated only when the verification pass disagrees with the first pass.
  final SemanticRelation? verifierRelation;
  final SemanticDimension? verifierDimension;
  final MeaningPreservation? verifierPreservation;

  bool get isPrimary => routeRole == TranslationRouteRole.primary;

  bool get hasVerifierTuple =>
      verifierRelation != null ||
      verifierDimension != null ||
      verifierPreservation != null;

  @override
  List<Object?> get props => <Object?>[
    routeId,
    routeRole,
    relation,
    dimension,
    preservation,
    verificationStatus,
    sourceExcerpt,
    targetExcerpt,
    verifierRelation,
    verifierDimension,
    verifierPreservation,
  ];

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'route': routeId,
      'route_role': routeRole.name,
      'relation': relation.code,
      'dimension': dimension.code,
      'preservation': preservation.code,
      'verification_status': verificationStatus.name,
      'source_excerpt': sourceExcerpt,
      'target_excerpt': targetExcerpt,
      'verifier_relation': verifierRelation?.code,
      'verifier_dimension': verifierDimension?.code,
      'verifier_preservation': verifierPreservation?.code,
    };
  }
}

String normalizeSemanticCode(String value) => _normalizeCode(value);

String _normalizeCode(String value) {
  return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
}
