import 'package:equatable/equatable.dart';

import 'engineering_service_contract.dart';
import 'workflow_step_definition.dart';

final class EngineeringWorkflow extends Equatable {
  factory EngineeringWorkflow({
    required String workflowKey,
    required String semanticVersion,
    required String title,
    required Iterable<
      WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
    >
    steps,
    Iterable<String> stopConditions = const <String>[],
    Iterable<String> resumeConditions = const <String>[],
    Iterable<String> completionConditions = const <String>[],
  }) {
    final List<
      WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
    >
    normalizedSteps = steps.toList(growable: false);

    if (normalizedSteps.isEmpty) {
      throw ArgumentError(
        'Engineering workflow must contain at least one step.',
      );
    }

    _ensureUniqueStepKeys(normalizedSteps);
    _ensureUniqueStepOrders(normalizedSteps);

    normalizedSteps.sort(
      (
        WorkflowStepDefinition<
          EngineeringServiceInput,
          EngineeringServiceOutput
        >
        left,
        WorkflowStepDefinition<
          EngineeringServiceInput,
          EngineeringServiceOutput
        >
        right,
      ) => left.sequenceOrder.compareTo(right.sequenceOrder),
    );

    return EngineeringWorkflow._(
      workflowKey: _requiredText(workflowKey, 'workflowKey'),
      semanticVersion: _requiredText(semanticVersion, 'semanticVersion'),
      title: _requiredText(title, 'title'),
      steps:
          List<
            WorkflowStepDefinition<
              EngineeringServiceInput,
              EngineeringServiceOutput
            >
          >.unmodifiable(normalizedSteps),
      stopConditions: _normalizeUniqueList(stopConditions, 'stopCondition'),
      resumeConditions: _normalizeUniqueList(
        resumeConditions,
        'resumeCondition',
      ),
      completionConditions: _normalizeUniqueList(
        completionConditions,
        'completionCondition',
      ),
    );
  }

  const EngineeringWorkflow._({
    required this.workflowKey,
    required this.semanticVersion,
    required this.title,
    required this.steps,
    required this.stopConditions,
    required this.resumeConditions,
    required this.completionConditions,
  });

  final String workflowKey;
  final String semanticVersion;
  final String title;
  final List<
    WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
  >
  steps;
  final List<String> stopConditions;
  final List<String> resumeConditions;
  final List<String> completionConditions;

  WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
  get firstStep => steps.first;

  WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
  get lastStep => steps.last;

  List<String> get stepKeys => List<String>.unmodifiable(
    steps.map(
      (
        WorkflowStepDefinition<
          EngineeringServiceInput,
          EngineeringServiceOutput
        >
        step,
      ) => step.stepKey,
    ),
  );

  @override
  List<Object?> get props => <Object?>[
    workflowKey,
    semanticVersion,
    title,
    steps,
    stopConditions,
    resumeConditions,
    completionConditions,
  ];
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Engineering workflow $fieldName must not be empty.',
    );
  }

  return normalized;
}

List<String> _normalizeUniqueList(Iterable<String> values, String fieldName) {
  final List<String> normalized = values
      .map((String value) => _requiredText(value, fieldName))
      .toList(growable: false);

  final Set<String> seen = <String>{};

  for (final String value in normalized) {
    if (!seen.add(value)) {
      throw ArgumentError(
        'Duplicate engineering workflow $fieldName "$value" is not allowed.',
      );
    }
  }

  return List<String>.unmodifiable(normalized);
}

void _ensureUniqueStepKeys(
  Iterable<
    WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
  >
  steps,
) {
  final Set<String> seen = <String>{};

  for (final WorkflowStepDefinition<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
      step
      in steps) {
    if (!seen.add(step.stepKey)) {
      throw ArgumentError(
        'Duplicate engineering workflow step key "${step.stepKey}" is not allowed.',
      );
    }
  }
}

void _ensureUniqueStepOrders(
  Iterable<
    WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
  >
  steps,
) {
  final Set<int> seen = <int>{};

  for (final WorkflowStepDefinition<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
      step
      in steps) {
    if (!seen.add(step.sequenceOrder)) {
      throw ArgumentError(
        'Duplicate engineering workflow step order "${step.sequenceOrder}" is not allowed.',
      );
    }
  }
}
