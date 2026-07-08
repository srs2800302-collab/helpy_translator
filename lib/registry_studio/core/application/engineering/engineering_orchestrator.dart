import 'engineering_service.dart';
import 'engineering_service_capability_catalog.dart';
import 'engineering_service_contract.dart';
import 'engineering_workflow.dart';
import 'engineering_workflow_confirmation.dart';
import 'engineering_workflow_instance.dart';
import 'workflow_step_definition.dart';
import 'workflow_step_execution.dart';

final class EngineeringOrchestrator {
  const EngineeringOrchestrator();

  EngineeringWorkflowInstance startConfirmedWorkflow({
    required String workflowInstanceId,
    required EngineeringWorkflowConfirmation confirmation,
    required String activeRuntimeCompositionFingerprint,
  }) {
    return EngineeringWorkflowInstance.started(
      workflowInstanceId: workflowInstanceId,
      workflow: confirmation.workflow,
      activeRuntimeCompositionFingerprint: activeRuntimeCompositionFingerprint,
      runtimeAuditReferences: _runtimeAuditReferencesFor(confirmation),
    );
  }

  Future<EngineeringWorkflowInstance> executeCurrentStep<
    I extends EngineeringServiceInput,
    O extends EngineeringServiceOutput
  >({
    required EngineeringWorkflowInstance instance,
    required EngineeringServiceCapabilityCatalog capabilityCatalog,
    required I input,
    required String completionSummary,
    String? engineerDecisionPointReference,
    String? engineerDecisionStopReason,
    Iterable<String> runtimeAuditReferences = const <String>[],
  }) async {
    _ensureRunningInstance(instance);
    _ensureCatalogMatchesInstance(instance, capabilityCatalog);

    final WorkflowStepDefinition<I, O> stepDefinition =
        _typedCurrentStepDefinition<I, O>(instance, input);

    final EngineeringServiceBinding<I, O> binding = capabilityCatalog
        .resolveForStep<I, O>(stepDefinition);

    if (stepDefinition.requiresEngineerConfirmation) {
      return _stopForEngineerConfirmation<I, O>(
        instance: instance,
        stepDefinition: stepDefinition,
        binding: binding,
        input: input,
        engineerDecisionPointReference: engineerDecisionPointReference,
        engineerDecisionStopReason: engineerDecisionStopReason,
        runtimeAuditReferences: runtimeAuditReferences,
      );
    }

    final EngineeringServiceResult<O> result;

    try {
      result = await binding.service.execute(input);
    } on Object catch (error) {
      return _failedInstance<I, O>(
        instance: instance,
        stepExecution: WorkflowStepExecution<I, O>.failed(
          stepDefinition: stepDefinition,
          resolvedHandlerBindingProvenance: binding.bindingProvenance,
          input: input,
          failure: EngineeringServiceFailure(
            code: 'engineering_service_exception',
            message: 'Engineering service execution threw: $error',
          ),
        ),
        failureState: 'engineering_service_exception: $error',
        runtimeAuditReferences: runtimeAuditReferences,
      );
    }

    if (result.isFailure) {
      final EngineeringServiceFailure failure = result.requireFailure;

      return _failedInstance<I, O>(
        instance: instance,
        stepExecution: WorkflowStepExecution<I, O>.failed(
          stepDefinition: stepDefinition,
          resolvedHandlerBindingProvenance: binding.bindingProvenance,
          input: input,
          failure: failure,
        ),
        failureState: '${failure.code}: ${failure.message}',
        runtimeAuditReferences: <String>[
          ...runtimeAuditReferences,
          ...result.traceabilityReferences,
        ],
      );
    }

    final WorkflowStepExecution<I, O> completedExecution =
        WorkflowStepExecution<I, O>.completed(
          stepDefinition: stepDefinition,
          resolvedHandlerBindingProvenance: binding.bindingProvenance,
          input: input,
          output: result.requireOutput,
          completionSummary: completionSummary,
        );

    return _instanceAfterCompletedStep<I, O>(
      instance: instance,
      completedExecution: completedExecution,
      completionSummary: completionSummary,
      runtimeAuditReferences: <String>[
        ...runtimeAuditReferences,
        ...result.traceabilityReferences,
      ],
    );
  }

  Future<EngineeringWorkflowInstance> resumeCurrentStepAfterEngineerDecision<
    I extends EngineeringServiceInput,
    O extends EngineeringServiceOutput
  >({
    required EngineeringWorkflowInstance instance,
    required EngineeringServiceCapabilityCatalog capabilityCatalog,
    required String engineerDecisionReference,
    required String completionSummary,
    String? bindingChangedDecisionPointReference,
    String? bindingChangedStopReason,
    Iterable<String> runtimeAuditReferences = const <String>[],
  }) async {
    _ensureStoppedInstance(instance);
    _ensureCatalogMatchesInstance(instance, capabilityCatalog);

    final String resumeDecisionReference = _requiredText(
      engineerDecisionReference,
      'engineerDecisionReference',
    );

    final WorkflowStepExecution<I, O> stoppedExecution =
        _typedCurrentStoppedExecution<I, O>(instance);

    final WorkflowStepDefinition<I, O> stepDefinition =
        stoppedExecution.stepDefinition;

    final EngineeringServiceBinding<I, O> binding = capabilityCatalog
        .resolveForStep<I, O>(stepDefinition);

    if (stoppedExecution.requiresEngineerDecisionForBinding(
      binding.bindingProvenance,
    )) {
      return EngineeringWorkflowInstance.stopped(
        workflowInstanceId: instance.workflowInstanceId,
        workflow: instance.workflow,
        activeRuntimeCompositionFingerprint:
            instance.activeRuntimeCompositionFingerprint,
        currentExecutionPosition: instance.currentExecutionPosition,
        stepExecutions: instance.stepExecutions,
        resumeState: _requiredText(
          bindingChangedStopReason,
          'bindingChangedStopReason',
        ),
        intermediateResultReferences: instance.intermediateResultReferences,
        engineerDecisionPoints: _mergeUnique(<String>[
          ...instance.engineerDecisionPoints,
          _requiredText(
            bindingChangedDecisionPointReference,
            'bindingChangedDecisionPointReference',
          ),
        ]),
        registryTransactionReference: instance.registryTransactionReference,
        runtimeAuditReferences: _mergeUnique(<String>[
          ...instance.runtimeAuditReferences,
          resumeDecisionReference,
          ...runtimeAuditReferences,
        ]),
      );
    }

    if (!stoppedExecution.canResumeWithBinding(binding.bindingProvenance)) {
      throw StateError(
        'Engineering orchestrator cannot resume current step with the active handler binding.',
      );
    }

    final I input = stoppedExecution.input as I;
    final EngineeringServiceResult<O> result;

    try {
      result = await binding.service.execute(input);
    } on Object catch (error) {
      return _failedInstance<I, O>(
        instance: instance,
        stepExecution: WorkflowStepExecution<I, O>.failed(
          stepDefinition: stepDefinition,
          resolvedHandlerBindingProvenance: binding.bindingProvenance,
          input: input,
          failure: EngineeringServiceFailure(
            code: 'engineering_service_exception',
            message: 'Engineering service execution threw: $error',
          ),
        ),
        failureState: 'engineering_service_exception: $error',
        runtimeAuditReferences: <String>[
          resumeDecisionReference,
          ...runtimeAuditReferences,
        ],
      );
    }

    if (result.isFailure) {
      final EngineeringServiceFailure failure = result.requireFailure;

      return _failedInstance<I, O>(
        instance: instance,
        stepExecution: WorkflowStepExecution<I, O>.failed(
          stepDefinition: stepDefinition,
          resolvedHandlerBindingProvenance: binding.bindingProvenance,
          input: input,
          failure: failure,
        ),
        failureState: '${failure.code}: ${failure.message}',
        runtimeAuditReferences: <String>[
          resumeDecisionReference,
          ...runtimeAuditReferences,
          ...result.traceabilityReferences,
        ],
      );
    }

    return _instanceAfterCompletedStep<I, O>(
      instance: instance,
      completedExecution: WorkflowStepExecution<I, O>.completed(
        stepDefinition: stepDefinition,
        resolvedHandlerBindingProvenance: binding.bindingProvenance,
        input: input,
        output: result.requireOutput,
        completionSummary: completionSummary,
      ),
      completionSummary: completionSummary,
      runtimeAuditReferences: <String>[
        resumeDecisionReference,
        ...runtimeAuditReferences,
        ...result.traceabilityReferences,
      ],
    );
  }
}

List<String> _runtimeAuditReferencesFor(
  EngineeringWorkflowConfirmation confirmation,
) {
  return _mergeUnique(<String>[
    confirmation.confirmationReference,
    ...confirmation.runtimeAuditReferences,
  ]);
}

void _ensureRunningInstance(EngineeringWorkflowInstance instance) {
  if (!instance.isRunning) {
    throw StateError(
      'Engineering orchestrator can execute current step only for RUNNING workflow instance.',
    );
  }
}

void _ensureStoppedInstance(EngineeringWorkflowInstance instance) {
  if (!instance.isStopped) {
    throw StateError(
      'Engineering orchestrator can resume current step only for STOPPED workflow instance.',
    );
  }
}

void _ensureCatalogMatchesInstance(
  EngineeringWorkflowInstance instance,
  EngineeringServiceCapabilityCatalog capabilityCatalog,
) {
  if (instance.activeRuntimeCompositionFingerprint !=
      capabilityCatalog.compositionFingerprint) {
    throw ArgumentError(
      'Engineering orchestrator cannot execute workflow step with a catalog from a different runtime composition.',
    );
  }
}

WorkflowStepDefinition<I, O> _typedCurrentStepDefinition<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>(EngineeringWorkflowInstance instance, I input) {
  final WorkflowStepDefinition<
    EngineeringServiceInput,
    EngineeringServiceOutput
  >
  currentStepDefinition = instance.currentStepDefinition;

  if (!currentStepDefinition.serviceContract.acceptsInput(input)) {
    throw ArgumentError(
      'Engineering orchestrator input type does not match current workflow step service contract.',
    );
  }

  return currentStepDefinition as WorkflowStepDefinition<I, O>;
}

WorkflowStepExecution<I, O> _typedCurrentStoppedExecution<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>(EngineeringWorkflowInstance instance) {
  final WorkflowStepExecution<
    EngineeringServiceInput,
    EngineeringServiceOutput
  >?
  execution = instance.currentStepExecution;

  if (execution == null || !execution.isStopped) {
    throw StateError(
      'Engineering orchestrator stopped workflow instance must preserve stopped current step execution.',
    );
  }

  final EngineeringServiceInput? input = execution.input;
  if (input == null) {
    throw StateError(
      'Engineering orchestrator cannot resume stopped current step without preserved typed input.',
    );
  }

  if (!execution.stepDefinition.serviceContract.acceptsInput(input)) {
    throw StateError(
      'Engineering orchestrator stopped current step input no longer matches its service contract.',
    );
  }

  return execution as WorkflowStepExecution<I, O>;
}

EngineeringWorkflowInstance _stopForEngineerConfirmation<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>({
  required EngineeringWorkflowInstance instance,
  required WorkflowStepDefinition<I, O> stepDefinition,
  required EngineeringServiceBinding<I, O> binding,
  required I input,
  required String? engineerDecisionPointReference,
  required String? engineerDecisionStopReason,
  required Iterable<String> runtimeAuditReferences,
}) {
  final String decisionPoint = _requiredText(
    engineerDecisionPointReference,
    'engineerDecisionPointReference',
  );
  final String stopReason = _requiredText(
    engineerDecisionStopReason,
    'engineerDecisionStopReason',
  );

  final WorkflowStepExecution<I, O> stoppedExecution =
      WorkflowStepExecution<I, O>.stopped(
        stepDefinition: stepDefinition,
        resolvedHandlerBindingProvenance: binding.bindingProvenance,
        input: input,
        stopReason: stopReason,
        engineerConfirmationState:
            WorkflowStepEngineerConfirmationState.pending,
      );

  return EngineeringWorkflowInstance.stopped(
    workflowInstanceId: instance.workflowInstanceId,
    workflow: instance.workflow,
    activeRuntimeCompositionFingerprint:
        instance.activeRuntimeCompositionFingerprint,
    currentExecutionPosition: instance.currentExecutionPosition,
    stepExecutions: _replaceStepExecution(instance, stoppedExecution),
    resumeState: stopReason,
    intermediateResultReferences: instance.intermediateResultReferences,
    engineerDecisionPoints: _mergeUnique(<String>[
      ...instance.engineerDecisionPoints,
      decisionPoint,
    ]),
    registryTransactionReference: instance.registryTransactionReference,
    runtimeAuditReferences: _mergeUnique(<String>[
      ...instance.runtimeAuditReferences,
      ...runtimeAuditReferences,
    ]),
  );
}

EngineeringWorkflowInstance _failedInstance<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>({
  required EngineeringWorkflowInstance instance,
  required WorkflowStepExecution<I, O> stepExecution,
  required String failureState,
  required Iterable<String> runtimeAuditReferences,
}) {
  return EngineeringWorkflowInstance.failed(
    workflowInstanceId: instance.workflowInstanceId,
    workflow: instance.workflow,
    activeRuntimeCompositionFingerprint:
        instance.activeRuntimeCompositionFingerprint,
    currentExecutionPosition: instance.currentExecutionPosition,
    stepExecutions: _replaceStepExecution(instance, stepExecution),
    failureState: failureState,
    intermediateResultReferences: instance.intermediateResultReferences,
    engineerDecisionPoints: instance.engineerDecisionPoints,
    registryTransactionReference: instance.registryTransactionReference,
    runtimeAuditReferences: _mergeUnique(<String>[
      ...instance.runtimeAuditReferences,
      ...runtimeAuditReferences,
    ]),
  );
}

EngineeringWorkflowInstance _instanceAfterCompletedStep<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>({
  required EngineeringWorkflowInstance instance,
  required WorkflowStepExecution<I, O> completedExecution,
  required String completionSummary,
  required Iterable<String> runtimeAuditReferences,
}) {
  final List<
    WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
  >
  updatedExecutions = _replaceStepExecution(instance, completedExecution);

  final int? nextPosition = _nextExecutionPosition(
    instance.workflow,
    instance.currentExecutionPosition,
  );

  if (nextPosition == null) {
    return EngineeringWorkflowInstance.completed(
      workflowInstanceId: instance.workflowInstanceId,
      workflow: instance.workflow,
      activeRuntimeCompositionFingerprint:
          instance.activeRuntimeCompositionFingerprint,
      stepExecutions: updatedExecutions,
      completionState: completionSummary,
      intermediateResultReferences: instance.intermediateResultReferences,
      engineerDecisionPoints: instance.engineerDecisionPoints,
      registryTransactionReference: instance.registryTransactionReference,
      runtimeAuditReferences: _mergeUnique(<String>[
        ...instance.runtimeAuditReferences,
        ...runtimeAuditReferences,
      ]),
    );
  }

  return EngineeringWorkflowInstance.running(
    workflowInstanceId: instance.workflowInstanceId,
    workflow: instance.workflow,
    activeRuntimeCompositionFingerprint:
        instance.activeRuntimeCompositionFingerprint,
    currentExecutionPosition: nextPosition,
    stepExecutions: updatedExecutions,
    intermediateResultReferences: instance.intermediateResultReferences,
    engineerDecisionPoints: instance.engineerDecisionPoints,
    registryTransactionReference: instance.registryTransactionReference,
    runtimeAuditReferences: _mergeUnique(<String>[
      ...instance.runtimeAuditReferences,
      ...runtimeAuditReferences,
    ]),
  );
}

List<WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>>
_replaceStepExecution<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>(EngineeringWorkflowInstance instance, WorkflowStepExecution<I, O> execution) {
  final List<
    WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
  >
  updated =
      <
        WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
      >[
        for (final WorkflowStepExecution<
              EngineeringServiceInput,
              EngineeringServiceOutput
            >
            existing
            in instance.stepExecutions)
          if (existing.stepKey != execution.stepKey) existing,
        execution,
      ];

  updated.sort(
    (
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
      left,
      WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
      right,
    ) => left.sequenceOrder.compareTo(right.sequenceOrder),
  );

  return List<
    WorkflowStepExecution<EngineeringServiceInput, EngineeringServiceOutput>
  >.unmodifiable(updated);
}

int? _nextExecutionPosition(
  EngineeringWorkflow workflow,
  int currentExecutionPosition,
) {
  final List<int> positions =
      workflow.steps
          .map(
            (
              WorkflowStepDefinition<
                EngineeringServiceInput,
                EngineeringServiceOutput
              >
              step,
            ) => step.sequenceOrder,
          )
          .where((int position) => position > currentExecutionPosition)
          .toList(growable: false)
        ..sort();

  if (positions.isEmpty) {
    return null;
  }

  return positions.first;
}

String _requiredText(String? value, String fieldName) {
  final String? current = value;
  if (current == null) {
    throw ArgumentError('Engineering orchestrator $fieldName is required.');
  }

  final String normalized = current.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Engineering orchestrator $fieldName must not be empty.',
    );
  }

  return normalized;
}

List<String> _mergeUnique(Iterable<String> values) {
  final Set<String> seen = <String>{};
  final List<String> unique = <String>[];

  for (final String value in values) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError(
        'Engineering orchestrator references must not contain empty values.',
      );
    }

    if (seen.add(normalized)) {
      unique.add(normalized);
    }
  }

  return List<String>.unmodifiable(unique);
}
