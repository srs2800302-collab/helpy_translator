import 'package:equatable/equatable.dart';

import 'engineering_service_contract.dart';
import 'engineering_workflow.dart';
import 'workflow_step_definition.dart';
import 'workflow_step_execution.dart';

enum EngineeringWorkflowInstanceStatus {
  running,
  stopped,
  completed,
  failed;

  String get contractLabel => name.toUpperCase();
}

final class EngineeringWorkflowInstance extends Equatable {
  factory EngineeringWorkflowInstance.started({
    required String workflowInstanceId,
    required EngineeringWorkflow workflow,
    required String activeRuntimeCompositionFingerprint,
    Iterable<String> runtimeAuditReferences = const <String>[],
  }) {
    return EngineeringWorkflowInstance._build(
      workflowInstanceId: workflowInstanceId,
      status: EngineeringWorkflowInstanceStatus.running,
      workflow: workflow,
      activeRuntimeCompositionFingerprint: activeRuntimeCompositionFingerprint,
      currentExecutionPosition: workflow.firstStep.sequenceOrder,
      stepExecutions:
          const <
            WorkflowStepExecution<
              EngineeringServiceInput,
              EngineeringServiceOutput
            >
          >[],
      intermediateResultReferences: const <String>[],
      engineerDecisionPoints: const <String>[],
      failureState: null,
      resumeState: null,
      completionState: null,
      registryTransactionReference: null,
      runtimeAuditReferences: runtimeAuditReferences,
    );
  }

  factory EngineeringWorkflowInstance.running({
    required String workflowInstanceId,
    required EngineeringWorkflow workflow,
    required String activeRuntimeCompositionFingerprint,
    required int currentExecutionPosition,
    Iterable<
          WorkflowStepExecution<
            EngineeringServiceInput,
            EngineeringServiceOutput
          >
        >
        stepExecutions =
        const <
          WorkflowStepExecution<
            EngineeringServiceInput,
            EngineeringServiceOutput
          >
        >[],
    Iterable<String> intermediateResultReferences = const <String>[],
    Iterable<String> engineerDecisionPoints = const <String>[],
    String? registryTransactionReference,
    Iterable<String> runtimeAuditReferences = const <String>[],
  }) {
    return EngineeringWorkflowInstance._build(
      workflowInstanceId: workflowInstanceId,
      status: EngineeringWorkflowInstanceStatus.running,
      workflow: workflow,
      activeRuntimeCompositionFingerprint: activeRuntimeCompositionFingerprint,
      currentExecutionPosition: currentExecutionPosition,
      stepExecutions: stepExecutions,
      intermediateResultReferences: intermediateResultReferences,
      engineerDecisionPoints: engineerDecisionPoints,
      failureState: null,
      resumeState: null,
      completionState: null,
      registryTransactionReference: registryTransactionReference,
      runtimeAuditReferences: runtimeAuditReferences,
    );
  }

  factory EngineeringWorkflowInstance.stopped({
    required String workflowInstanceId,
    required EngineeringWorkflow workflow,
    required String activeRuntimeCompositionFingerprint,
    required int currentExecutionPosition,
    required Iterable<
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
    >
    stepExecutions,
    required String resumeState,
    Iterable<String> intermediateResultReferences = const <String>[],
    Iterable<String> engineerDecisionPoints = const <String>[],
    String? registryTransactionReference,
    Iterable<String> runtimeAuditReferences = const <String>[],
  }) {
    return EngineeringWorkflowInstance._build(
      workflowInstanceId: workflowInstanceId,
      status: EngineeringWorkflowInstanceStatus.stopped,
      workflow: workflow,
      activeRuntimeCompositionFingerprint: activeRuntimeCompositionFingerprint,
      currentExecutionPosition: currentExecutionPosition,
      stepExecutions: stepExecutions,
      intermediateResultReferences: intermediateResultReferences,
      engineerDecisionPoints: engineerDecisionPoints,
      failureState: null,
      resumeState: resumeState,
      completionState: null,
      registryTransactionReference: registryTransactionReference,
      runtimeAuditReferences: runtimeAuditReferences,
    );
  }

  factory EngineeringWorkflowInstance.completed({
    required String workflowInstanceId,
    required EngineeringWorkflow workflow,
    required String activeRuntimeCompositionFingerprint,
    required Iterable<
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
    >
    stepExecutions,
    required String completionState,
    Iterable<String> intermediateResultReferences = const <String>[],
    Iterable<String> engineerDecisionPoints = const <String>[],
    String? registryTransactionReference,
    Iterable<String> runtimeAuditReferences = const <String>[],
  }) {
    return EngineeringWorkflowInstance._build(
      workflowInstanceId: workflowInstanceId,
      status: EngineeringWorkflowInstanceStatus.completed,
      workflow: workflow,
      activeRuntimeCompositionFingerprint: activeRuntimeCompositionFingerprint,
      currentExecutionPosition: workflow.lastStep.sequenceOrder,
      stepExecutions: stepExecutions,
      intermediateResultReferences: intermediateResultReferences,
      engineerDecisionPoints: engineerDecisionPoints,
      failureState: null,
      resumeState: null,
      completionState: completionState,
      registryTransactionReference: registryTransactionReference,
      runtimeAuditReferences: runtimeAuditReferences,
    );
  }

  factory EngineeringWorkflowInstance.failed({
    required String workflowInstanceId,
    required EngineeringWorkflow workflow,
    required String activeRuntimeCompositionFingerprint,
    required int currentExecutionPosition,
    required Iterable<
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
    >
    stepExecutions,
    required String failureState,
    Iterable<String> intermediateResultReferences = const <String>[],
    Iterable<String> engineerDecisionPoints = const <String>[],
    String? registryTransactionReference,
    Iterable<String> runtimeAuditReferences = const <String>[],
  }) {
    return EngineeringWorkflowInstance._build(
      workflowInstanceId: workflowInstanceId,
      status: EngineeringWorkflowInstanceStatus.failed,
      workflow: workflow,
      activeRuntimeCompositionFingerprint: activeRuntimeCompositionFingerprint,
      currentExecutionPosition: currentExecutionPosition,
      stepExecutions: stepExecutions,
      intermediateResultReferences: intermediateResultReferences,
      engineerDecisionPoints: engineerDecisionPoints,
      failureState: failureState,
      resumeState: null,
      completionState: null,
      registryTransactionReference: registryTransactionReference,
      runtimeAuditReferences: runtimeAuditReferences,
    );
  }

  factory EngineeringWorkflowInstance._build({
    required String workflowInstanceId,
    required EngineeringWorkflowInstanceStatus status,
    required EngineeringWorkflow workflow,
    required String activeRuntimeCompositionFingerprint,
    required int currentExecutionPosition,
    required Iterable<
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
    >
    stepExecutions,
    required Iterable<String> intermediateResultReferences,
    required Iterable<String> engineerDecisionPoints,
    required String? failureState,
    required String? resumeState,
    required String? completionState,
    required String? registryTransactionReference,
    required Iterable<String> runtimeAuditReferences,
  }) {
    _ensureWorkflowContainsPosition(workflow, currentExecutionPosition);

    final List<
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
    >
    normalizedExecutions = _normalizeStepExecutions(workflow, stepExecutions);

    final EngineeringWorkflowInstance instance = EngineeringWorkflowInstance._(
      workflowInstanceId: _requiredText(
        workflowInstanceId,
        'workflowInstanceId',
      ),
      status: status,
      workflow: workflow,
      activeRuntimeCompositionFingerprint: _requiredText(
        activeRuntimeCompositionFingerprint,
        'activeRuntimeCompositionFingerprint',
      ),
      currentExecutionPosition: currentExecutionPosition,
      stepExecutions: normalizedExecutions,
      intermediateResultReferences: _normalizeUniqueList(
        intermediateResultReferences,
        'intermediateResultReference',
      ),
      engineerDecisionPoints: _normalizeUniqueList(
        engineerDecisionPoints,
        'engineerDecisionPoint',
      ),
      failureState: _optionalText(failureState, 'failureState'),
      resumeState: _optionalText(resumeState, 'resumeState'),
      completionState: _optionalText(completionState, 'completionState'),
      registryTransactionReference: _optionalText(
        registryTransactionReference,
        'registryTransactionReference',
      ),
      runtimeAuditReferences: _normalizeUniqueList(
        runtimeAuditReferences,
        'runtimeAuditReference',
      ),
    );

    _validateStatusState(instance);

    return instance;
  }

  const EngineeringWorkflowInstance._({
    required this.workflowInstanceId,
    required this.status,
    required this.workflow,
    required this.activeRuntimeCompositionFingerprint,
    required this.currentExecutionPosition,
    required this.stepExecutions,
    required this.intermediateResultReferences,
    required this.engineerDecisionPoints,
    required this.failureState,
    required this.resumeState,
    required this.completionState,
    required this.registryTransactionReference,
    required this.runtimeAuditReferences,
  });

  final String workflowInstanceId;
  final EngineeringWorkflowInstanceStatus status;
  final EngineeringWorkflow workflow;
  final String activeRuntimeCompositionFingerprint;
  final int currentExecutionPosition;
  final List<
    WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
  >
  stepExecutions;
  final List<String> intermediateResultReferences;
  final List<String> engineerDecisionPoints;
  final String? failureState;
  final String? resumeState;
  final String? completionState;
  final String? registryTransactionReference;
  final List<String> runtimeAuditReferences;

  String get workflowKey => workflow.workflowKey;

  WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
  get currentStepDefinition {
    return workflow.steps.firstWhere(
      (
        WorkflowStepDefinition<
          EngineeringServiceInput,
          EngineeringServiceOutput
        >
        step,
      ) => step.sequenceOrder == currentExecutionPosition,
    );
  }

  WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>?
  get currentStepExecution {
    for (final WorkflowStepExecution<
          EngineeringServiceInput,
          EngineeringServiceOutput
        >
        execution
        in stepExecutions) {
      if (execution.sequenceOrder == currentExecutionPosition) {
        return execution;
      }
    }

    return null;
  }

  bool get isRunning => status == EngineeringWorkflowInstanceStatus.running;

  bool get isStopped => status == EngineeringWorkflowInstanceStatus.stopped;

  bool get isCompleted => status == EngineeringWorkflowInstanceStatus.completed;

  bool get isFailed => status == EngineeringWorkflowInstanceStatus.failed;

  bool get isTerminal => isCompleted || isFailed;

  @override
  List<Object?> get props => <Object?>[
    workflowInstanceId,
    status,
    workflow,
    activeRuntimeCompositionFingerprint,
    currentExecutionPosition,
    stepExecutions,
    intermediateResultReferences,
    engineerDecisionPoints,
    failureState,
    resumeState,
    completionState,
    registryTransactionReference,
    runtimeAuditReferences,
  ];
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Engineering workflow instance $fieldName must not be empty.',
    );
  }

  return normalized;
}

String? _optionalText(String? value, String fieldName) {
  if (value == null) {
    return null;
  }

  return _requiredText(value, fieldName);
}

List<String> _normalizeUniqueList(Iterable<String> values, String fieldName) {
  final List<String> normalized = values
      .map((String value) => _requiredText(value, fieldName))
      .toList(growable: false);

  final Set<String> seen = <String>{};

  for (final String value in normalized) {
    if (!seen.add(value)) {
      throw ArgumentError(
        'Duplicate engineering workflow instance $fieldName "$value" is not allowed.',
      );
    }
  }

  return List<String>.unmodifiable(normalized);
}

void _ensureWorkflowContainsPosition(
  EngineeringWorkflow workflow,
  int currentExecutionPosition,
) {
  final bool found = workflow.steps.any(
    (
      WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
      step,
    ) => step.sequenceOrder == currentExecutionPosition,
  );

  if (!found) {
    throw ArgumentError.value(
      currentExecutionPosition,
      'currentExecutionPosition',
      'Engineering workflow instance current execution position must reference a workflow step.',
    );
  }
}

List<WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>>
_normalizeStepExecutions(
  EngineeringWorkflow workflow,
  Iterable<
    WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
  >
  stepExecutions,
) {
  final Map<
    String,
    WorkflowStepDefinition<EngineeringServiceInput, EngineeringServiceOutput>
  >
  workflowStepsByKey =
      <
        String,
        WorkflowStepDefinition<
          EngineeringServiceInput,
          EngineeringServiceOutput
        >
      >{
        for (final WorkflowStepDefinition<
              EngineeringServiceInput,
              EngineeringServiceOutput
            >
            step
            in workflow.steps)
          step.stepKey: step,
      };

  final List<
    WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
  >
  normalized = stepExecutions.toList(growable: false);
  final Set<String> seenStepKeys = <String>{};

  for (final WorkflowStepExecution<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
      execution
      in normalized) {
    final WorkflowStepDefinition<
      EngineeringServiceInput,
      EngineeringServiceOutput
    >?
    expectedStep = workflowStepsByKey[execution.stepKey];

    if (expectedStep == null) {
      throw ArgumentError(
        'Workflow step execution "${execution.stepKey}" does not belong to workflow.',
      );
    }

    if (expectedStep.sequenceOrder != execution.sequenceOrder) {
      throw ArgumentError(
        'Workflow step execution "${execution.stepKey}" has invalid sequence order.',
      );
    }

    if (expectedStep.requiredServiceContractKey !=
        execution.resolvedServiceContractKey) {
      throw ArgumentError(
        'Workflow step execution "${execution.stepKey}" has invalid resolved service contract key.',
      );
    }

    if (expectedStep.serviceContract.semanticVersion !=
        execution.resolvedServiceContractSemanticVersion) {
      throw ArgumentError(
        'Workflow step execution "${execution.stepKey}" has invalid resolved service contract semantic version.',
      );
    }

    if (!seenStepKeys.add(execution.stepKey)) {
      throw ArgumentError(
        'Duplicate workflow step execution "${execution.stepKey}" is not allowed.',
      );
    }
  }

  normalized.sort(
    (
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
      left,
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
      right,
    ) => left.sequenceOrder.compareTo(right.sequenceOrder),
  );

  return List<
    WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
  >.unmodifiable(normalized);
}

void _validateStatusState(EngineeringWorkflowInstance instance) {
  switch (instance.status) {
    case EngineeringWorkflowInstanceStatus.running:
      _ensureAbsent(instance.failureState, 'failureState');
      _ensureAbsent(instance.resumeState, 'resumeState');
      _ensureAbsent(instance.completionState, 'completionState');
    case EngineeringWorkflowInstanceStatus.stopped:
      _ensurePresent(instance.resumeState, 'resumeState');
      _ensureAbsent(instance.failureState, 'failureState');
      _ensureAbsent(instance.completionState, 'completionState');
      if (instance.currentStepExecution == null ||
          !instance.currentStepExecution!.isStopped) {
        throw ArgumentError(
          'Stopped engineering workflow instance must preserve stopped current step execution.',
        );
      }
    case EngineeringWorkflowInstanceStatus.completed:
      _ensurePresent(instance.completionState, 'completionState');
      _ensureAbsent(instance.failureState, 'failureState');
      _ensureAbsent(instance.resumeState, 'resumeState');
      _ensureAllWorkflowStepsCompleted(instance);
    case EngineeringWorkflowInstanceStatus.failed:
      _ensurePresent(instance.failureState, 'failureState');
      _ensureAbsent(instance.resumeState, 'resumeState');
      _ensureAbsent(instance.completionState, 'completionState');
      if (!instance.stepExecutions.any(
        (
          WorkflowStepExecution<
            EngineeringServiceInput,
            EngineeringServiceOutput
          >
          execution,
        ) => execution.isFailed,
      )) {
        throw ArgumentError(
          'Failed engineering workflow instance must preserve failed step execution.',
        );
      }
  }
}

void _ensureAllWorkflowStepsCompleted(EngineeringWorkflowInstance instance) {
  final Set<String> completedStepKeys = instance.stepExecutions
      .where(
        (
          WorkflowStepExecution<
            EngineeringServiceInput,
            EngineeringServiceOutput
          >
          execution,
        ) => execution.isCompleted,
      )
      .map(
        (
          WorkflowStepExecution<
            EngineeringServiceInput,
            EngineeringServiceOutput
          >
          execution,
        ) => execution.stepKey,
      )
      .toSet();

  for (final WorkflowStepDefinition<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
      step
      in instance.workflow.steps) {
    if (!completedStepKeys.contains(step.stepKey)) {
      throw ArgumentError(
        'Completed engineering workflow instance must preserve completed execution for step "${step.stepKey}".',
      );
    }
  }
}

void _ensurePresent(String? value, String fieldName) {
  if (value == null) {
    throw ArgumentError(
      'Engineering workflow instance $fieldName is required for this status.',
    );
  }
}

void _ensureAbsent(String? value, String fieldName) {
  if (value != null) {
    throw ArgumentError(
      'Engineering workflow instance $fieldName must be absent for this status.',
    );
  }
}
