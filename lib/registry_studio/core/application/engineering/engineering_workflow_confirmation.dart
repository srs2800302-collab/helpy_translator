import 'package:equatable/equatable.dart';

import 'engineering_workflow.dart';
import 'engineering_workflow_resolution.dart';

final class EngineeringWorkflowConfirmation extends Equatable {
  factory EngineeringWorkflowConfirmation.confirmed({
    required EngineeringWorkflowResolution resolution,
    required EngineeringWorkflow workflow,
    required String confirmationReference,
    Iterable<String> runtimeAuditReferences = const <String>[],
  }) {
    if (!resolution.isResolved) {
      throw ArgumentError(
        'Engineering workflow confirmation requires a RESOLVED workflow resolution.',
      );
    }

    if (resolution.selectedWorkflowKey != workflow.workflowKey) {
      throw ArgumentError(
        'Engineering workflow confirmation selected workflow must match resolved workflow key.',
      );
    }

    return EngineeringWorkflowConfirmation._(
      resolution: resolution,
      workflow: workflow,
      confirmationReference: _requiredText(
        confirmationReference,
        'confirmationReference',
      ),
      runtimeAuditReferences: _normalizeUniqueList(
        runtimeAuditReferences,
        'runtimeAuditReference',
      ),
    );
  }

  const EngineeringWorkflowConfirmation._({
    required this.resolution,
    required this.workflow,
    required this.confirmationReference,
    required this.runtimeAuditReferences,
  });

  final EngineeringWorkflowResolution resolution;
  final EngineeringWorkflow workflow;
  final String confirmationReference;
  final List<String> runtimeAuditReferences;

  String get workflowKey => workflow.workflowKey;

  String get workflowSemanticVersion => workflow.semanticVersion;

  String get resolutionExplanation => resolution.explanation;

  @override
  List<Object?> get props => <Object?>[
    resolution,
    workflow,
    confirmationReference,
    runtimeAuditReferences,
  ];
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Engineering workflow confirmation $fieldName must not be empty.',
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
        'Duplicate engineering workflow confirmation $fieldName "$value" is not allowed.',
      );
    }
  }

  return List<String>.unmodifiable(normalized);
}
