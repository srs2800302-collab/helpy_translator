import 'package:equatable/equatable.dart';

import 'engineering_service_contract.dart';
import 'workflow_step_definition.dart';

enum WorkflowStepExecutionStatus {
  pending,
  running,
  stopped,
  completed,
  failed;

  String get contractLabel => name.toUpperCase();
}

enum WorkflowStepEngineerConfirmationState {
  notRequired,
  pending,
  confirmed;

  String get contractLabel {
    return switch (this) {
      WorkflowStepEngineerConfirmationState.notRequired => 'NOT_REQUIRED',
      WorkflowStepEngineerConfirmationState.pending => 'PENDING',
      WorkflowStepEngineerConfirmationState.confirmed => 'CONFIRMED',
    };
  }
}

final class WorkflowStepExecution<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>
    extends Equatable {
  factory WorkflowStepExecution.pending({
    required WorkflowStepDefinition<I, O> stepDefinition,
    required String resolvedHandlerBindingProvenance,
    WorkflowStepEngineerConfirmationState? engineerConfirmationState,
  }) {
    return WorkflowStepExecution._(
      stepDefinition: stepDefinition,
      status: WorkflowStepExecutionStatus.pending,
      resolvedServiceContractKey: stepDefinition.serviceContract.contractKey,
      resolvedServiceContractSemanticVersion:
          stepDefinition.serviceContract.semanticVersion,
      resolvedHandlerBindingProvenance: _requiredText(
        resolvedHandlerBindingProvenance,
        'resolvedHandlerBindingProvenance',
      ),
      engineerConfirmationState: _validateConfirmationState(
        stepDefinition,
        engineerConfirmationState ?? _initialConfirmationState(stepDefinition),
        WorkflowStepExecutionStatus.pending,
      ),
      input: null,
      output: null,
      failure: null,
      stopReason: null,
      isResumable: false,
      completionSummary: null,
    );
  }

  factory WorkflowStepExecution.running({
    required WorkflowStepDefinition<I, O> stepDefinition,
    required String resolvedHandlerBindingProvenance,
    required I input,
    WorkflowStepEngineerConfirmationState? engineerConfirmationState,
  }) {
    return WorkflowStepExecution._(
      stepDefinition: stepDefinition,
      status: WorkflowStepExecutionStatus.running,
      resolvedServiceContractKey: stepDefinition.serviceContract.contractKey,
      resolvedServiceContractSemanticVersion:
          stepDefinition.serviceContract.semanticVersion,
      resolvedHandlerBindingProvenance: _requiredText(
        resolvedHandlerBindingProvenance,
        'resolvedHandlerBindingProvenance',
      ),
      engineerConfirmationState: _validateConfirmationState(
        stepDefinition,
        engineerConfirmationState ??
            _executionConfirmationState(stepDefinition),
        WorkflowStepExecutionStatus.running,
      ),
      input: input,
      output: null,
      failure: null,
      stopReason: null,
      isResumable: false,
      completionSummary: null,
    );
  }

  factory WorkflowStepExecution.stopped({
    required WorkflowStepDefinition<I, O> stepDefinition,
    required String resolvedHandlerBindingProvenance,
    required I input,
    required String stopReason,
    bool isResumable = true,
    WorkflowStepEngineerConfirmationState? engineerConfirmationState,
  }) {
    return WorkflowStepExecution._(
      stepDefinition: stepDefinition,
      status: WorkflowStepExecutionStatus.stopped,
      resolvedServiceContractKey: stepDefinition.serviceContract.contractKey,
      resolvedServiceContractSemanticVersion:
          stepDefinition.serviceContract.semanticVersion,
      resolvedHandlerBindingProvenance: _requiredText(
        resolvedHandlerBindingProvenance,
        'resolvedHandlerBindingProvenance',
      ),
      engineerConfirmationState: _validateConfirmationState(
        stepDefinition,
        engineerConfirmationState ??
            _executionConfirmationState(stepDefinition),
        WorkflowStepExecutionStatus.stopped,
      ),
      input: input,
      output: null,
      failure: null,
      stopReason: _requiredText(stopReason, 'stopReason'),
      isResumable: isResumable,
      completionSummary: null,
    );
  }

  factory WorkflowStepExecution.completed({
    required WorkflowStepDefinition<I, O> stepDefinition,
    required String resolvedHandlerBindingProvenance,
    required I input,
    required O output,
    required String completionSummary,
    WorkflowStepEngineerConfirmationState? engineerConfirmationState,
  }) {
    return WorkflowStepExecution._(
      stepDefinition: stepDefinition,
      status: WorkflowStepExecutionStatus.completed,
      resolvedServiceContractKey: stepDefinition.serviceContract.contractKey,
      resolvedServiceContractSemanticVersion:
          stepDefinition.serviceContract.semanticVersion,
      resolvedHandlerBindingProvenance: _requiredText(
        resolvedHandlerBindingProvenance,
        'resolvedHandlerBindingProvenance',
      ),
      engineerConfirmationState: _validateConfirmationState(
        stepDefinition,
        engineerConfirmationState ??
            _executionConfirmationState(stepDefinition),
        WorkflowStepExecutionStatus.completed,
      ),
      input: input,
      output: output,
      failure: null,
      stopReason: null,
      isResumable: false,
      completionSummary: _requiredText(completionSummary, 'completionSummary'),
    );
  }

  factory WorkflowStepExecution.failed({
    required WorkflowStepDefinition<I, O> stepDefinition,
    required String resolvedHandlerBindingProvenance,
    required EngineeringServiceFailure failure,
    I? input,
    WorkflowStepEngineerConfirmationState? engineerConfirmationState,
  }) {
    return WorkflowStepExecution._(
      stepDefinition: stepDefinition,
      status: WorkflowStepExecutionStatus.failed,
      resolvedServiceContractKey: stepDefinition.serviceContract.contractKey,
      resolvedServiceContractSemanticVersion:
          stepDefinition.serviceContract.semanticVersion,
      resolvedHandlerBindingProvenance: _requiredText(
        resolvedHandlerBindingProvenance,
        'resolvedHandlerBindingProvenance',
      ),
      engineerConfirmationState: _validateConfirmationState(
        stepDefinition,
        engineerConfirmationState ??
            _executionConfirmationState(stepDefinition),
        WorkflowStepExecutionStatus.failed,
      ),
      input: input,
      output: null,
      failure: failure,
      stopReason: null,
      isResumable: false,
      completionSummary: null,
    );
  }

  const WorkflowStepExecution._({
    required this.stepDefinition,
    required this.status,
    required this.resolvedServiceContractKey,
    required this.resolvedServiceContractSemanticVersion,
    required this.resolvedHandlerBindingProvenance,
    required this.engineerConfirmationState,
    required this.input,
    required this.output,
    required this.failure,
    required this.stopReason,
    required this.isResumable,
    required this.completionSummary,
  });

  final WorkflowStepDefinition<I, O> stepDefinition;
  final WorkflowStepExecutionStatus status;
  final String resolvedServiceContractKey;
  final String resolvedServiceContractSemanticVersion;
  final String resolvedHandlerBindingProvenance;
  final WorkflowStepEngineerConfirmationState engineerConfirmationState;
  final I? input;
  final O? output;
  final EngineeringServiceFailure? failure;
  final String? stopReason;
  final bool isResumable;
  final String? completionSummary;

  String get stepKey => stepDefinition.stepKey;

  int get sequenceOrder => stepDefinition.sequenceOrder;

  bool get isPending => status == WorkflowStepExecutionStatus.pending;

  bool get isRunning => status == WorkflowStepExecutionStatus.running;

  bool get isStopped => status == WorkflowStepExecutionStatus.stopped;

  bool get isCompleted => status == WorkflowStepExecutionStatus.completed;

  bool get isFailed => status == WorkflowStepExecutionStatus.failed;

  bool get isTerminal => isCompleted || isFailed;

  bool canResumeWithBinding(String activeHandlerBindingProvenance) {
    return isStopped &&
        isResumable &&
        _requiredText(
              activeHandlerBindingProvenance,
              'activeHandlerBindingProvenance',
            ) ==
            resolvedHandlerBindingProvenance;
  }

  bool requiresEngineerDecisionForBinding(
    String activeHandlerBindingProvenance,
  ) {
    return isStopped &&
        isResumable &&
        _requiredText(
              activeHandlerBindingProvenance,
              'activeHandlerBindingProvenance',
            ) !=
            resolvedHandlerBindingProvenance;
  }

  @override
  List<Object?> get props => <Object?>[
    stepDefinition,
    status,
    resolvedServiceContractKey,
    resolvedServiceContractSemanticVersion,
    resolvedHandlerBindingProvenance,
    engineerConfirmationState,
    input,
    output,
    failure,
    stopReason,
    isResumable,
    completionSummary,
  ];
}

WorkflowStepEngineerConfirmationState _initialConfirmationState<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>(WorkflowStepDefinition<I, O> stepDefinition) {
  if (stepDefinition.requiresEngineerConfirmation) {
    return WorkflowStepEngineerConfirmationState.pending;
  }

  return WorkflowStepEngineerConfirmationState.notRequired;
}

WorkflowStepEngineerConfirmationState _executionConfirmationState<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>(WorkflowStepDefinition<I, O> stepDefinition) {
  if (stepDefinition.requiresEngineerConfirmation) {
    return WorkflowStepEngineerConfirmationState.confirmed;
  }

  return WorkflowStepEngineerConfirmationState.notRequired;
}

WorkflowStepEngineerConfirmationState _validateConfirmationState<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>(
  WorkflowStepDefinition<I, O> stepDefinition,
  WorkflowStepEngineerConfirmationState state,
  WorkflowStepExecutionStatus status,
) {
  if (!stepDefinition.requiresEngineerConfirmation &&
      state != WorkflowStepEngineerConfirmationState.notRequired) {
    throw ArgumentError(
      'Workflow step execution confirmation state must be NOT_REQUIRED when the step does not require engineer confirmation.',
    );
  }

  if (stepDefinition.requiresEngineerConfirmation &&
      state == WorkflowStepEngineerConfirmationState.notRequired) {
    throw ArgumentError(
      'Workflow step execution confirmation state must not be NOT_REQUIRED when the step requires engineer confirmation.',
    );
  }

  if (status != WorkflowStepExecutionStatus.pending &&
      state == WorkflowStepEngineerConfirmationState.pending) {
    throw ArgumentError(
      'Workflow step execution cannot run before required engineer confirmation.',
    );
  }

  return state;
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Workflow step execution $fieldName must not be empty.',
    );
  }

  return normalized;
}
