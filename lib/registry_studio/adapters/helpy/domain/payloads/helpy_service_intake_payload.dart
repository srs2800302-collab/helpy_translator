import 'package:equatable/equatable.dart';

import '../../../../core/domain/contracts/registry_entity_payload.dart';
import '../../../../core/domain/value_objects/registry_entity_kind.dart';
import '../../../../core/domain/value_objects/registry_semantic_contract_identity.dart';

final class HelpyServiceIntakePayload extends Equatable
    implements RegistryEntityPayload {
  factory HelpyServiceIntakePayload({
    required String displayName,
    required Iterable<HelpyIntakeScenario> scenarios,
  }) {
    final List<HelpyIntakeScenario> normalizedScenarios =
        List<HelpyIntakeScenario>.unmodifiable(scenarios);

    _ensureUniqueKeys(
      normalizedScenarios.map((HelpyIntakeScenario item) => item.key),
      'scenario',
    );
    _validateReuseReferences(normalizedScenarios);

    return HelpyServiceIntakePayload._(
      displayName: _requiredText(displayName, 'displayName'),
      scenarios: normalizedScenarios,
    );
  }

  const HelpyServiceIntakePayload._({
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
  final List<HelpyIntakeScenario> scenarios;

  @override
  RegistryEntityKind get kind => entityKind;

  static void _validateReuseReferences(List<HelpyIntakeScenario> scenarios) {
    final Map<String, Set<String>> photoKeysByScenario = <String, Set<String>>{
      for (final HelpyIntakeScenario scenario in scenarios)
        scenario.key: <String>{
          for (final HelpyPhotoQuestion item in scenario.photoQuestions)
            item.key,
        },
    };

    for (final HelpyIntakeScenario scenario in scenarios) {
      for (final HelpyPhotoQuestion photoQuestion in scenario.photoQuestions) {
        final HelpyPhotoQuestionSource source = photoQuestion.source;

        if (source.mode != HelpyPhotoSourceMode.reuse) {
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

final class HelpyIntakeScenario extends Equatable {
  factory HelpyIntakeScenario({
    required String key,
    required String displayName,
    required HelpyScenarioEntryEvidence entryEvidence,
    required Iterable<HelpyIntakeQuestion> questions,
    required Iterable<HelpyPhotoQuestion> photoQuestions,
    required Iterable<HelpyPhotoLimit> photoLimits,
    required Iterable<HelpyScenarioGuidanceItem> clientGuidance,
    required Iterable<HelpyScenarioGuidanceItem> masterGuidance,
  }) {
    final List<HelpyIntakeQuestion> normalizedQuestions =
        List<HelpyIntakeQuestion>.unmodifiable(questions);
    final List<HelpyPhotoQuestion> normalizedPhotoQuestions =
        List<HelpyPhotoQuestion>.unmodifiable(photoQuestions);
    final List<HelpyPhotoLimit> normalizedPhotoLimits =
        List<HelpyPhotoLimit>.unmodifiable(photoLimits);
    final List<HelpyScenarioGuidanceItem> normalizedClientGuidance =
        List<HelpyScenarioGuidanceItem>.unmodifiable(clientGuidance);
    final List<HelpyScenarioGuidanceItem> normalizedMasterGuidance =
        List<HelpyScenarioGuidanceItem>.unmodifiable(masterGuidance);

    _ensureUniqueKeys(
      normalizedQuestions.map((HelpyIntakeQuestion item) => item.key),
      'question',
    );
    _ensureUniqueKeys(<String>[
      for (final HelpyIntakeQuestion question in normalizedQuestions)
        for (final HelpyQuestionQualifier qualifier in question.qualifiers)
          qualifier.key,
    ], 'scenario qualifier');
    _ensureUniqueKeys(
      normalizedPhotoQuestions.map((HelpyPhotoQuestion item) => item.key),
      'photo question',
    );
    _ensureUniqueKeys(
      normalizedPhotoLimits.map((HelpyPhotoLimit item) => item.key),
      'photo limit',
    );
    _ensureUniqueKeys(
      normalizedClientGuidance.map(
        (HelpyScenarioGuidanceItem item) => item.key,
      ),
      'client guidance',
    );
    _ensureUniqueKeys(
      normalizedMasterGuidance.map(
        (HelpyScenarioGuidanceItem item) => item.key,
      ),
      'master guidance',
    );

    final Set<String> qualifierKeys = <String>{
      for (final HelpyIntakeQuestion question in normalizedQuestions)
        for (final HelpyQuestionQualifier qualifier in question.qualifiers)
          qualifier.key,
    };
    final Set<String> photoLimitKeys = <String>{
      for (final HelpyPhotoLimit limit in normalizedPhotoLimits) limit.key,
    };

    for (final HelpyPhotoQuestion photoQuestion in normalizedPhotoQuestions) {
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

    return HelpyIntakeScenario._(
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

  const HelpyIntakeScenario._({
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
  final HelpyScenarioEntryEvidence entryEvidence;
  final List<HelpyIntakeQuestion> questions;
  final List<HelpyPhotoQuestion> photoQuestions;
  final List<HelpyPhotoLimit> photoLimits;
  final List<HelpyScenarioGuidanceItem> clientGuidance;
  final List<HelpyScenarioGuidanceItem> masterGuidance;

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

final class HelpyScenarioEntryEvidence extends Equatable {
  factory HelpyScenarioEntryEvidence({
    required String sourceSelectorQuestionKey,
    required String sourceSelectedAnswerOptionKey,
  }) {
    return HelpyScenarioEntryEvidence._(
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

  const HelpyScenarioEntryEvidence._({
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

final class HelpyIntakeQuestion extends Equatable {
  factory HelpyIntakeQuestion({
    required String key,
    required String prompt,
    required Iterable<HelpyAnswerOption> answerOptions,
    required Iterable<HelpyQuestionQualifier> qualifiers,
  }) {
    final List<HelpyAnswerOption> normalizedAnswerOptions =
        List<HelpyAnswerOption>.unmodifiable(answerOptions);
    final List<HelpyQuestionQualifier> normalizedQualifiers =
        List<HelpyQuestionQualifier>.unmodifiable(qualifiers);

    _ensureUniqueKeys(
      normalizedAnswerOptions.map((HelpyAnswerOption item) => item.key),
      'answer option',
    );
    _ensureUniqueKeys(
      normalizedQualifiers.map((HelpyQuestionQualifier item) => item.key),
      'question qualifier',
    );

    return HelpyIntakeQuestion._(
      key: _requiredText(key, 'key'),
      prompt: _requiredText(prompt, 'prompt'),
      answerOptions: normalizedAnswerOptions,
      qualifiers: normalizedQualifiers,
    );
  }

  const HelpyIntakeQuestion._({
    required this.key,
    required this.prompt,
    required this.answerOptions,
    required this.qualifiers,
  });

  final String key;
  final String prompt;
  final List<HelpyAnswerOption> answerOptions;
  final List<HelpyQuestionQualifier> qualifiers;

  @override
  List<Object?> get props => <Object?>[key, prompt, answerOptions, qualifiers];
}

final class HelpyAnswerOption extends Equatable {
  factory HelpyAnswerOption({
    required String key,
    required String displayName,
  }) {
    return HelpyAnswerOption._(
      key: _requiredText(key, 'key'),
      displayName: _requiredText(displayName, 'displayName'),
    );
  }

  const HelpyAnswerOption._({required this.key, required this.displayName});

  final String key;
  final String displayName;

  @override
  List<Object?> get props => <Object?>[key, displayName];
}

enum HelpyQuestionQualifierKind { condition, answerContext }

final class HelpyQuestionQualifier extends Equatable {
  factory HelpyQuestionQualifier({
    required String key,
    required HelpyQuestionQualifierKind kind,
    required String expression,
  }) {
    return HelpyQuestionQualifier._(
      key: _requiredText(key, 'key'),
      kind: kind,
      expression: _requiredText(expression, 'expression'),
    );
  }

  const HelpyQuestionQualifier._({
    required this.key,
    required this.kind,
    required this.expression,
  });

  final String key;
  final HelpyQuestionQualifierKind kind;
  final String expression;

  @override
  List<Object?> get props => <Object?>[key, kind, expression];
}

enum HelpyPhotoSourceMode { direct, reuse, addition, replacement }

final class HelpyPhotoQuestionSource extends Equatable {
  factory HelpyPhotoQuestionSource({
    required HelpyPhotoSourceMode mode,
    String? sourceScenarioKey,
    String? sourcePhotoQuestionKey,
  }) {
    final String scenarioKey = sourceScenarioKey?.trim() ?? '';
    final String photoQuestionKey = sourcePhotoQuestionKey?.trim() ?? '';
    final bool hasCompleteReference =
        scenarioKey.isNotEmpty && photoQuestionKey.isNotEmpty;
    final bool hasAnyReference =
        scenarioKey.isNotEmpty || photoQuestionKey.isNotEmpty;

    if (mode == HelpyPhotoSourceMode.reuse && !hasCompleteReference) {
      throw ArgumentError(
        'Reusable photo question must declare local source references.',
      );
    }

    if (mode != HelpyPhotoSourceMode.reuse && hasAnyReference) {
      throw ArgumentError(
        'Only reusable photo questions may declare source references.',
      );
    }

    return HelpyPhotoQuestionSource._(
      mode: mode,
      sourceScenarioKey: hasCompleteReference ? scenarioKey : null,
      sourcePhotoQuestionKey: hasCompleteReference ? photoQuestionKey : null,
    );
  }

  const HelpyPhotoQuestionSource._({
    required this.mode,
    required this.sourceScenarioKey,
    required this.sourcePhotoQuestionKey,
  });

  final HelpyPhotoSourceMode mode;
  final String? sourceScenarioKey;
  final String? sourcePhotoQuestionKey;

  @override
  List<Object?> get props => <Object?>[
    mode,
    sourceScenarioKey,
    sourcePhotoQuestionKey,
  ];
}

final class HelpyPhotoQuestion extends Equatable {
  factory HelpyPhotoQuestion({
    required String key,
    required String prompt,
    required bool isRequired,
    required Iterable<String> applicabilityQualifierKeys,
    required String photoLimitKey,
    required HelpyPhotoQuestionSource source,
  }) {
    final List<String> qualifierKeys = List<String>.unmodifiable(
      applicabilityQualifierKeys.map(
        (String item) => _requiredText(item, 'applicabilityQualifierKey'),
      ),
    );

    _ensureUniqueKeys(qualifierKeys, 'photo question applicability qualifier');

    return HelpyPhotoQuestion._(
      key: _requiredText(key, 'key'),
      prompt: _requiredText(prompt, 'prompt'),
      isRequired: isRequired,
      applicabilityQualifierKeys: qualifierKeys,
      photoLimitKey: _requiredText(photoLimitKey, 'photoLimitKey'),
      source: source,
    );
  }

  const HelpyPhotoQuestion._({
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
  final HelpyPhotoQuestionSource source;

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

final class HelpyPhotoLimit extends Equatable {
  factory HelpyPhotoLimit({
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

    return HelpyPhotoLimit._(
      key: _requiredText(key, 'key'),
      requiredCount: requiredCount,
      optionalCount: optionalCount,
      totalMaximum: totalMaximum,
    );
  }

  const HelpyPhotoLimit._({
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

final class HelpyScenarioGuidanceItem extends Equatable {
  factory HelpyScenarioGuidanceItem({
    required String key,
    required String text,
  }) {
    return HelpyScenarioGuidanceItem._(
      key: _requiredText(key, 'key'),
      text: _requiredText(text, 'text'),
    );
  }

  const HelpyScenarioGuidanceItem._({required this.key, required this.text});

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
