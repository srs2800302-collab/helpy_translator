import 'package:equatable/equatable.dart';

import '../../../../core/domain/contracts/registry_entity_payload.dart';
import '../../../../core/domain/value_objects/registry_entity_kind.dart';
import '../../../../core/domain/value_objects/registry_semantic_contract_identity.dart';

final class ServiceIntakePayload extends Equatable
    implements RegistryEntityPayload {
  factory ServiceIntakePayload({
    required String displayName,
    required Iterable<IntakeScenario> scenarios,
  }) {
    final List<IntakeScenario> normalizedScenarios =
        List<IntakeScenario>.unmodifiable(scenarios);

    _ensureUniqueKeys(
      normalizedScenarios.map((IntakeScenario item) => item.key),
      'scenario',
    );
    _validateReuseReferences(normalizedScenarios);

    return ServiceIntakePayload._(
      displayName: _requiredText(displayName, 'displayName'),
      scenarios: normalizedScenarios,
    );
  }

  const ServiceIntakePayload._({
    required this.displayName,
    required this.scenarios,
  });

  static final RegistrySemanticContractIdentity semanticContractIdentity =
      RegistrySemanticContractIdentity(
        contractId: 'helpy.service_intake',
        version: '1',
      );

  static const String entityKindIdentifier = 'helpy.service_intake';
  static const String schemaVersion = '1';

  static final RegistryEntityKind entityKind = RegistryEntityKind(
    semanticContract: semanticContractIdentity,
    kindId: entityKindIdentifier,
    schemaVersion: schemaVersion,
  );

  final String displayName;
  final List<IntakeScenario> scenarios;

  @override
  RegistryEntityKind get kind => entityKind;

  static void _validateReuseReferences(List<IntakeScenario> scenarios) {
    final Map<String, Set<String>> photoKeysByScenario = <String, Set<String>>{
      for (final IntakeScenario scenario in scenarios)
        scenario.key: <String>{
          for (final PhotoQuestion item in scenario.photoQuestions) item.key,
        },
    };

    for (final IntakeScenario scenario in scenarios) {
      for (final PhotoQuestion photoQuestion in scenario.photoQuestions) {
        final PhotoQuestionSource source = photoQuestion.source;

        if (source.mode != PhotoSourceMode.reuse) {
          continue;
        }

        final String sourceScenarioKey = source.sourceScenarioKey!;
        final String sourcePhotoQuestionKey = source.sourcePhotoQuestionKey!;

        if (sourceScenarioKey == scenario.key &&
            sourcePhotoQuestionKey == photoQuestion.key) {
          throw ArgumentError(
            'Reusable photo question "${photoQuestion.key}" must not '
            'reference itself.',
          );
        }

        final Set<String>? sourcePhotoKeys =
            photoKeysByScenario[sourceScenarioKey];

        if (sourcePhotoKeys == null ||
            !sourcePhotoKeys.contains(sourcePhotoQuestionKey)) {
          throw ArgumentError(
            'Reusable photo question "${photoQuestion.key}" must reference '
            'a photo question inside the same intake payload.',
          );
        }
      }
    }
  }

  @override
  List<Object?> get props => <Object?>[kind, displayName, scenarios];
}

final class IntakeScenario extends Equatable {
  factory IntakeScenario({
    required String key,
    required String displayName,
    required ScenarioEntryEvidence entryEvidence,
    required Iterable<IntakeQuestion> questions,
    required Iterable<PhotoQuestion> photoQuestions,
    required Iterable<PhotoLimit> photoLimits,
    required Iterable<ScenarioGuidanceItem> clientGuidance,
    required Iterable<ScenarioGuidanceItem> masterGuidance,
  }) {
    final List<IntakeQuestion> normalizedQuestions =
        List<IntakeQuestion>.unmodifiable(questions);
    final List<PhotoQuestion> normalizedPhotoQuestions =
        List<PhotoQuestion>.unmodifiable(photoQuestions);
    final List<PhotoLimit> normalizedPhotoLimits =
        List<PhotoLimit>.unmodifiable(photoLimits);
    final List<ScenarioGuidanceItem> normalizedClientGuidance =
        List<ScenarioGuidanceItem>.unmodifiable(clientGuidance);
    final List<ScenarioGuidanceItem> normalizedMasterGuidance =
        List<ScenarioGuidanceItem>.unmodifiable(masterGuidance);

    _ensureUniqueKeys(
      normalizedQuestions.map((IntakeQuestion item) => item.key),
      'question',
    );
    _ensureUniqueKeys(<String>[
      for (final IntakeQuestion question in normalizedQuestions)
        for (final QuestionQualifier qualifier in question.qualifiers)
          qualifier.key,
    ], 'scenario qualifier');
    _ensureUniqueKeys(
      normalizedPhotoQuestions.map((PhotoQuestion item) => item.key),
      'photo question',
    );
    _ensureUniqueKeys(
      normalizedPhotoLimits.map((PhotoLimit item) => item.key),
      'photo limit',
    );
    _ensureUniqueKeys(
      normalizedClientGuidance.map((ScenarioGuidanceItem item) => item.key),
      'client guidance',
    );
    _ensureUniqueKeys(
      normalizedMasterGuidance.map((ScenarioGuidanceItem item) => item.key),
      'master guidance',
    );

    final Set<String> qualifierKeys = <String>{
      for (final IntakeQuestion question in normalizedQuestions)
        for (final QuestionQualifier qualifier in question.qualifiers)
          qualifier.key,
    };
    final Set<String> photoLimitKeys = <String>{
      for (final PhotoLimit limit in normalizedPhotoLimits) limit.key,
    };

    for (final PhotoQuestion photoQuestion in normalizedPhotoQuestions) {
      if (!photoLimitKeys.contains(photoQuestion.photoLimitKey)) {
        throw ArgumentError(
          'Photo question "${photoQuestion.key}" must reference a local '
          'photo limit.',
        );
      }

      for (final String qualifierKey
          in photoQuestion.applicabilityQualifierKeys) {
        if (!qualifierKeys.contains(qualifierKey)) {
          throw ArgumentError(
            'Photo question "${photoQuestion.key}" must reference a '
            'scenario-owned question qualifier.',
          );
        }
      }
    }

    return IntakeScenario._(
      key: _requiredText(key, 'key'),
      displayName: _requiredText(displayName, 'displayName'),
      entryEvidence: entryEvidence,
      questions: normalizedQuestions,
      photoQuestions: normalizedPhotoQuestions,
      photoLimits: normalizedPhotoLimits,
      clientGuidance: normalizedClientGuidance,
      masterGuidance: normalizedMasterGuidance,
    );
  }

  const IntakeScenario._({
    required this.key,
    required this.displayName,
    required this.entryEvidence,
    required this.questions,
    required this.photoQuestions,
    required this.photoLimits,
    required this.clientGuidance,
    required this.masterGuidance,
  });

  final String key;
  final String displayName;
  final ScenarioEntryEvidence entryEvidence;
  final List<IntakeQuestion> questions;
  final List<PhotoQuestion> photoQuestions;
  final List<PhotoLimit> photoLimits;
  final List<ScenarioGuidanceItem> clientGuidance;
  final List<ScenarioGuidanceItem> masterGuidance;

  @override
  List<Object?> get props => <Object?>[
    key,
    displayName,
    entryEvidence,
    questions,
    photoQuestions,
    photoLimits,
    clientGuidance,
    masterGuidance,
  ];
}

final class ScenarioEntryEvidence extends Equatable {
  factory ScenarioEntryEvidence({
    required String sourceSelectorQuestionKey,
    required String sourceSelectedAnswerOptionKey,
  }) {
    return ScenarioEntryEvidence._(
      sourceSelectorQuestionKey: _requiredText(
        sourceSelectorQuestionKey,
        'sourceSelectorQuestionKey',
      ),
      sourceSelectedAnswerOptionKey: _requiredText(
        sourceSelectedAnswerOptionKey,
        'sourceSelectedAnswerOptionKey',
      ),
    );
  }

  const ScenarioEntryEvidence._({
    required this.sourceSelectorQuestionKey,
    required this.sourceSelectedAnswerOptionKey,
  });

  final String sourceSelectorQuestionKey;
  final String sourceSelectedAnswerOptionKey;

  @override
  List<Object?> get props => <Object?>[
    sourceSelectorQuestionKey,
    sourceSelectedAnswerOptionKey,
  ];
}

final class IntakeQuestion extends Equatable {
  factory IntakeQuestion({
    required String key,
    required String prompt,
    required Iterable<AnswerOption> answerOptions,
    required Iterable<QuestionQualifier> qualifiers,
  }) {
    final List<AnswerOption> normalizedAnswerOptions =
        List<AnswerOption>.unmodifiable(answerOptions);
    final List<QuestionQualifier> normalizedQualifiers =
        List<QuestionQualifier>.unmodifiable(qualifiers);

    _ensureUniqueKeys(
      normalizedAnswerOptions.map((AnswerOption item) => item.key),
      'answer option',
    );
    _ensureUniqueKeys(
      normalizedQualifiers.map((QuestionQualifier item) => item.key),
      'question qualifier',
    );

    return IntakeQuestion._(
      key: _requiredText(key, 'key'),
      prompt: _requiredText(prompt, 'prompt'),
      answerOptions: normalizedAnswerOptions,
      qualifiers: normalizedQualifiers,
    );
  }

  const IntakeQuestion._({
    required this.key,
    required this.prompt,
    required this.answerOptions,
    required this.qualifiers,
  });

  final String key;
  final String prompt;
  final List<AnswerOption> answerOptions;
  final List<QuestionQualifier> qualifiers;

  @override
  List<Object?> get props => <Object?>[key, prompt, answerOptions, qualifiers];
}

final class AnswerOption extends Equatable {
  factory AnswerOption({required String key, required String displayName}) {
    return AnswerOption._(
      key: _requiredText(key, 'key'),
      displayName: _requiredText(displayName, 'displayName'),
    );
  }

  const AnswerOption._({required this.key, required this.displayName});

  final String key;
  final String displayName;

  @override
  List<Object?> get props => <Object?>[key, displayName];
}

enum QuestionQualifierKind { condition, answerContext }

final class QuestionQualifier extends Equatable {
  factory QuestionQualifier({
    required String key,
    required QuestionQualifierKind kind,
    required String expression,
  }) {
    return QuestionQualifier._(
      key: _requiredText(key, 'key'),
      kind: kind,
      expression: _requiredText(expression, 'expression'),
    );
  }

  const QuestionQualifier._({
    required this.key,
    required this.kind,
    required this.expression,
  });

  final String key;
  final QuestionQualifierKind kind;
  final String expression;

  @override
  List<Object?> get props => <Object?>[key, kind, expression];
}

enum PhotoSourceMode { direct, reuse, addition, replacement }

final class PhotoQuestionSource extends Equatable {
  factory PhotoQuestionSource({
    required PhotoSourceMode mode,
    String? sourceScenarioKey,
    String? sourcePhotoQuestionKey,
  }) {
    final String scenarioKey = sourceScenarioKey?.trim() ?? '';
    final String photoQuestionKey = sourcePhotoQuestionKey?.trim() ?? '';
    final bool hasCompleteReference =
        scenarioKey.isNotEmpty && photoQuestionKey.isNotEmpty;
    final bool hasAnyReference =
        scenarioKey.isNotEmpty || photoQuestionKey.isNotEmpty;

    if (mode == PhotoSourceMode.reuse && !hasCompleteReference) {
      throw ArgumentError(
        'Reusable photo question must declare local source references.',
      );
    }

    if (mode != PhotoSourceMode.reuse && hasAnyReference) {
      throw ArgumentError(
        'Only reusable photo questions may declare source references.',
      );
    }

    return PhotoQuestionSource._(
      mode: mode,
      sourceScenarioKey: hasCompleteReference ? scenarioKey : null,
      sourcePhotoQuestionKey: hasCompleteReference ? photoQuestionKey : null,
    );
  }

  const PhotoQuestionSource._({
    required this.mode,
    required this.sourceScenarioKey,
    required this.sourcePhotoQuestionKey,
  });

  final PhotoSourceMode mode;
  final String? sourceScenarioKey;
  final String? sourcePhotoQuestionKey;

  @override
  List<Object?> get props => <Object?>[
    mode,
    sourceScenarioKey,
    sourcePhotoQuestionKey,
  ];
}

final class PhotoQuestion extends Equatable {
  factory PhotoQuestion({
    required String key,
    required String prompt,
    required bool isRequired,
    required Iterable<String> applicabilityQualifierKeys,
    required String photoLimitKey,
    required PhotoQuestionSource source,
  }) {
    final List<String> qualifierKeys = List<String>.unmodifiable(
      applicabilityQualifierKeys.map(
        (String item) => _requiredText(item, 'applicabilityQualifierKey'),
      ),
    );

    _ensureUniqueKeys(qualifierKeys, 'photo question applicability qualifier');

    return PhotoQuestion._(
      key: _requiredText(key, 'key'),
      prompt: _requiredText(prompt, 'prompt'),
      isRequired: isRequired,
      applicabilityQualifierKeys: qualifierKeys,
      photoLimitKey: _requiredText(photoLimitKey, 'photoLimitKey'),
      source: source,
    );
  }

  const PhotoQuestion._({
    required this.key,
    required this.prompt,
    required this.isRequired,
    required this.applicabilityQualifierKeys,
    required this.photoLimitKey,
    required this.source,
  });

  final String key;
  final String prompt;
  final bool isRequired;
  final List<String> applicabilityQualifierKeys;
  final String photoLimitKey;
  final PhotoQuestionSource source;

  @override
  List<Object?> get props => <Object?>[
    key,
    prompt,
    isRequired,
    applicabilityQualifierKeys,
    photoLimitKey,
    source,
  ];
}

final class PhotoLimit extends Equatable {
  factory PhotoLimit({
    required String key,
    required int requiredCount,
    required int optionalCount,
    required int totalMaximum,
  }) {
    if (requiredCount < 0 || optionalCount < 0 || totalMaximum < 0) {
      throw ArgumentError('Photo limit values must not be negative.');
    }

    if (requiredCount + optionalCount > totalMaximum) {
      throw ArgumentError(
        'Photo total maximum must allow required and optional photos.',
      );
    }

    return PhotoLimit._(
      key: _requiredText(key, 'key'),
      requiredCount: requiredCount,
      optionalCount: optionalCount,
      totalMaximum: totalMaximum,
    );
  }

  const PhotoLimit._({
    required this.key,
    required this.requiredCount,
    required this.optionalCount,
    required this.totalMaximum,
  });

  final String key;
  final int requiredCount;
  final int optionalCount;
  final int totalMaximum;

  @override
  List<Object?> get props => <Object?>[
    key,
    requiredCount,
    optionalCount,
    totalMaximum,
  ];
}

final class ScenarioGuidanceItem extends Equatable {
  factory ScenarioGuidanceItem({required String key, required String text}) {
    return ScenarioGuidanceItem._(
      key: _requiredText(key, 'key'),
      text: _requiredText(text, 'text'),
    );
  }

  const ScenarioGuidanceItem._({required this.key, required this.text});

  final String key;
  final String text;

  @override
  List<Object?> get props => <Object?>[key, text];
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      '$fieldName must not be empty.',
    );
  }

  return normalized;
}

void _ensureUniqueKeys(Iterable<String> keys, String scope) {
  final Set<String> seen = <String>{};

  for (final String key in keys) {
    if (!seen.add(key)) {
      throw ArgumentError(
        'Duplicate $scope key "$key" is not allowed in one intake entity.',
      );
    }
  }
}
