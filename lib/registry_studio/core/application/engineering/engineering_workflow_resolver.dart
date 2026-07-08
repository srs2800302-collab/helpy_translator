import 'package:equatable/equatable.dart';

import 'engineer_intent.dart';
import 'engineering_context.dart';
import 'engineering_workflow.dart';
import 'engineering_workflow_resolution.dart';

enum EngineeringWorkflowEligibilityOutcome {
  eligible,
  unsupported,
  blocked,
  failed;

  String get contractLabel => name.toUpperCase();
}

final class EngineeringWorkflowEligibility extends Equatable {
  factory EngineeringWorkflowEligibility.eligible({
    required String explanation,
  }) {
    return EngineeringWorkflowEligibility._(
      outcome: EngineeringWorkflowEligibilityOutcome.eligible,
      explanation: _requiredText(explanation, 'explanation'),
    );
  }

  factory EngineeringWorkflowEligibility.unsupported({
    required String explanation,
  }) {
    return EngineeringWorkflowEligibility._(
      outcome: EngineeringWorkflowEligibilityOutcome.unsupported,
      explanation: _requiredText(explanation, 'explanation'),
    );
  }

  factory EngineeringWorkflowEligibility.blocked({
    required String explanation,
  }) {
    return EngineeringWorkflowEligibility._(
      outcome: EngineeringWorkflowEligibilityOutcome.blocked,
      explanation: _requiredText(explanation, 'explanation'),
    );
  }

  factory EngineeringWorkflowEligibility.failed({required String explanation}) {
    return EngineeringWorkflowEligibility._(
      outcome: EngineeringWorkflowEligibilityOutcome.failed,
      explanation: _requiredText(explanation, 'explanation'),
    );
  }

  const EngineeringWorkflowEligibility._({
    required this.outcome,
    required this.explanation,
  });

  final EngineeringWorkflowEligibilityOutcome outcome;
  final String explanation;

  bool get isEligible =>
      outcome == EngineeringWorkflowEligibilityOutcome.eligible;

  bool get isUnsupported =>
      outcome == EngineeringWorkflowEligibilityOutcome.unsupported;

  bool get isBlocked =>
      outcome == EngineeringWorkflowEligibilityOutcome.blocked;

  bool get isFailed => outcome == EngineeringWorkflowEligibilityOutcome.failed;

  @override
  List<Object?> get props => <Object?>[outcome, explanation];
}

abstract interface class EngineeringWorkflowEligibilityEvaluator {
  EngineeringWorkflowEligibility evaluate({
    required EngineerIntent intent,
    required EngineeringContext context,
    required EngineeringWorkflow workflow,
  });
}

final class EngineeringWorkflowResolver {
  const EngineeringWorkflowResolver({
    required EngineeringWorkflowEligibilityEvaluator eligibilityEvaluator,
  }) : _eligibilityEvaluator = eligibilityEvaluator;

  final EngineeringWorkflowEligibilityEvaluator _eligibilityEvaluator;

  EngineeringWorkflowResolution resolve({
    required EngineerIntent intent,
    required EngineeringContext context,
    required Iterable<EngineeringWorkflow> approvedWorkflows,
  }) {
    final List<EngineeringWorkflow> workflows = approvedWorkflows.toList(
      growable: false,
    );

    if (workflows.isEmpty) {
      return EngineeringWorkflowResolution.unsupported(
        explanation: 'No approved engineering workflows are available.',
      );
    }

    final String? duplicateWorkflowKey = _firstDuplicateWorkflowKey(workflows);
    if (duplicateWorkflowKey != null) {
      return EngineeringWorkflowResolution.failed(
        explanation:
            'Approved engineering workflow definitions contain duplicate workflow key "$duplicateWorkflowKey".',
      );
    }

    workflows.sort(
      (EngineeringWorkflow left, EngineeringWorkflow right) =>
          left.workflowKey.compareTo(right.workflowKey),
    );

    final List<String> eligibleWorkflowKeys = <String>[];
    final List<String> blockedReasons = <String>[];
    final List<String> unsupportedReasons = <String>[];

    for (final EngineeringWorkflow workflow in workflows) {
      final EngineeringWorkflowEligibility eligibility;

      try {
        eligibility = _eligibilityEvaluator.evaluate(
          intent: intent,
          context: context,
          workflow: workflow,
        );
      } on Object catch (error) {
        return EngineeringWorkflowResolution.failed(
          explanation:
              'Engineering workflow resolution failed while evaluating workflow "${workflow.workflowKey}": $error',
        );
      }

      switch (eligibility.outcome) {
        case EngineeringWorkflowEligibilityOutcome.eligible:
          eligibleWorkflowKeys.add(workflow.workflowKey);
        case EngineeringWorkflowEligibilityOutcome.blocked:
          blockedReasons.add(
            '${workflow.workflowKey}: ${eligibility.explanation}',
          );
        case EngineeringWorkflowEligibilityOutcome.unsupported:
          unsupportedReasons.add(
            '${workflow.workflowKey}: ${eligibility.explanation}',
          );
        case EngineeringWorkflowEligibilityOutcome.failed:
          return EngineeringWorkflowResolution.failed(
            explanation:
                'Engineering workflow resolution failed for workflow "${workflow.workflowKey}": ${eligibility.explanation}',
          );
      }
    }

    if (eligibleWorkflowKeys.length == 1) {
      return EngineeringWorkflowResolution.resolved(
        selectedWorkflowKey: eligibleWorkflowKeys.single,
        explanation:
            'Resolved eligible engineering workflow "${eligibleWorkflowKeys.single}".',
      );
    }

    if (eligibleWorkflowKeys.length > 1) {
      return EngineeringWorkflowResolution.ambiguous(
        candidateWorkflowKeys: eligibleWorkflowKeys,
        explanation:
            'Engineering workflow resolution is ambiguous: ${eligibleWorkflowKeys.join(', ')}.',
      );
    }

    if (blockedReasons.isNotEmpty) {
      return EngineeringWorkflowResolution.blocked(
        explanation:
            'Engineering workflow resolution is blocked: ${blockedReasons.join('; ')}.',
      );
    }

    return EngineeringWorkflowResolution.unsupported(
      explanation:
          'No approved engineering workflow supports the intent: ${unsupportedReasons.join('; ')}.',
    );
  }
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Engineering workflow eligibility $fieldName must not be empty.',
    );
  }

  return normalized;
}

String? _firstDuplicateWorkflowKey(Iterable<EngineeringWorkflow> workflows) {
  final Set<String> seen = <String>{};

  for (final EngineeringWorkflow workflow in workflows) {
    if (!seen.add(workflow.workflowKey)) {
      return workflow.workflowKey;
    }
  }

  return null;
}
