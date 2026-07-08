import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_instance.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_execution.dart';

void main() {
  group('EngineeringWorkflowInstanceStatus', () {
    test('exposes contract labels', () {
      expect(
        EngineeringWorkflowInstanceStatus.running.contractLabel,
        'RUNNING',
      );
      expect(
        EngineeringWorkflowInstanceStatus.stopped.contractLabel,
        'STOPPED',
      );
      expect(
        EngineeringWorkflowInstanceStatus.completed.contractLabel,
        'COMPLETED',
      );
      expect(EngineeringWorkflowInstanceStatus.failed.contractLabel, 'FAILED');
    });
  });

  group('EngineeringWorkflowInstance', () {
    test('starts a confirmed workflow instance at first step', () {
      final EngineeringWorkflow workflow = _workflow();

      final EngineeringWorkflowInstance instance =
          EngineeringWorkflowInstance.started(
            workflowInstanceId: ' run-1 ',
            workflow: workflow,
            activeRuntimeCompositionFingerprint: ' composition:v1 ',
            runtimeAuditReferences: <String>[' audit:created '],
          );

      expect(instance.workflowInstanceId, 'run-1');
      expect(instance.status, EngineeringWorkflowInstanceStatus.running);
      expect(instance.workflowKey, 'review_intake');
      expect(instance.activeRuntimeCompositionFingerprint, 'composition:v1');
      expect(instance.currentExecutionPosition, 1);
      expect(instance.currentStepDefinition.stepKey, 'load_context');
      expect(instance.currentStepExecution, isNull);
      expect(instance.stepExecutions, isEmpty);
      expect(instance.runtimeAuditReferences, <String>['audit:created']);
      expect(instance.isRunning, isTrue);
      expect(instance.isTerminal, isFalse);
    });

    test('records running instance state and immutable references', () {
      final EngineeringWorkflow workflow = _workflow();

      final EngineeringWorkflowInstance instance =
          EngineeringWorkflowInstance.running(
            workflowInstanceId: 'run-1',
            workflow: workflow,
            activeRuntimeCompositionFingerprint: 'composition:v1',
            currentExecutionPosition: 2,
            stepExecutions:
                <
                  WorkflowStepExecution<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[
                  _completedExecution(
                    _loadStep(),
                    input: const _Input('a'),
                    output: const _Output('loaded'),
                  ),
                ],
            intermediateResultReferences: <String>['result:load'],
            engineerDecisionPoints: <String>['decision:confirm-target'],
            registryTransactionReference: 'tx:1',
            runtimeAuditReferences: <String>['audit:step-1'],
          );

      expect(instance.currentStepDefinition.stepKey, 'present_context');
      expect(instance.stepExecutions.single.stepKey, 'load_context');
      expect(instance.intermediateResultReferences, <String>['result:load']);
      expect(instance.engineerDecisionPoints, <String>[
        'decision:confirm-target',
      ]);
      expect(instance.registryTransactionReference, 'tx:1');
      expect(
        () => instance.stepExecutions.add(_completedExecution(_presentStep())),
        throwsUnsupportedError,
      );
      expect(
        () => instance.intermediateResultReferences.add('x'),
        throwsUnsupportedError,
      );
      expect(
        () => instance.engineerDecisionPoints.add('x'),
        throwsUnsupportedError,
      );
      expect(
        () => instance.runtimeAuditReferences.add('x'),
        throwsUnsupportedError,
      );
    });

    test('preserves stopped current step and resume state', () {
      final EngineeringWorkflow workflow = _workflow();

      final EngineeringWorkflowInstance instance =
          EngineeringWorkflowInstance.stopped(
            workflowInstanceId: 'run-1',
            workflow: workflow,
            activeRuntimeCompositionFingerprint: 'composition:v1',
            currentExecutionPosition: 1,
            stepExecutions:
                <
                  WorkflowStepExecution<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[
                  WorkflowStepExecution<_Input, _Output>.stopped(
                    stepDefinition: _loadStep(),
                    resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
                    input: const _Input('a'),
                    stopReason: 'Missing context.',
                  ),
                ],
            resumeState: 'Waiting for engineer decision.',
          );

      expect(instance.isStopped, isTrue);
      expect(instance.resumeState, 'Waiting for engineer decision.');
      expect(instance.currentStepExecution!.isStopped, isTrue);
    });

    test('requires all steps completed for completed instance', () {
      final EngineeringWorkflow workflow = _workflow();

      final EngineeringWorkflowInstance instance =
          EngineeringWorkflowInstance.completed(
            workflowInstanceId: 'run-1',
            workflow: workflow,
            activeRuntimeCompositionFingerprint: 'composition:v1',
            stepExecutions:
                <
                  WorkflowStepExecution<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[
                  _completedExecution(
                    _loadStep(),
                    input: const _Input('a'),
                    output: const _Output('loaded'),
                  ),
                  _completedExecution(
                    _presentStep(),
                    input: const _Input('b'),
                    output: const _Output('presented'),
                  ),
                ],
            completionState: 'Workflow completed.',
            registryTransactionReference: 'tx:1',
          );

      expect(instance.isCompleted, isTrue);
      expect(instance.isTerminal, isTrue);
      expect(instance.currentExecutionPosition, 2);
      expect(instance.completionState, 'Workflow completed.');
      expect(instance.registryTransactionReference, 'tx:1');
    });

    test('preserves failed execution and failure state', () {
      final EngineeringWorkflow workflow = _workflow();

      final EngineeringWorkflowInstance instance =
          EngineeringWorkflowInstance.failed(
            workflowInstanceId: 'run-1',
            workflow: workflow,
            activeRuntimeCompositionFingerprint: 'composition:v1',
            currentExecutionPosition: 1,
            stepExecutions:
                <
                  WorkflowStepExecution<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[
                  WorkflowStepExecution<_Input, _Output>.failed(
                    stepDefinition: _loadStep(),
                    resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
                    input: const _Input('a'),
                    failure: EngineeringServiceFailure(
                      code: 'missing_context',
                      message: 'Missing context.',
                    ),
                  ),
                ],
            failureState: 'Workflow failed.',
          );

      expect(instance.isFailed, isTrue);
      expect(instance.isTerminal, isTrue);
      expect(instance.failureState, 'Workflow failed.');
      expect(instance.stepExecutions.single.isFailed, isTrue);
    });

    test('rejects invalid identity, fingerprint and current position', () {
      final EngineeringWorkflow workflow = _workflow();

      expect(
        () => EngineeringWorkflowInstance.started(
          workflowInstanceId: ' ',
          workflow: workflow,
          activeRuntimeCompositionFingerprint: 'composition:v1',
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflowInstance.started(
          workflowInstanceId: 'run-1',
          workflow: workflow,
          activeRuntimeCompositionFingerprint: ' ',
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflowInstance.running(
          workflowInstanceId: 'run-1',
          workflow: workflow,
          activeRuntimeCompositionFingerprint: 'composition:v1',
          currentExecutionPosition: 99,
        ),
        throwsArgumentError,
      );
    });

    test(
      'rejects step executions outside workflow or with invalid contract identity',
      () {
        final EngineeringWorkflow workflow = _workflow();

        expect(
          () => EngineeringWorkflowInstance.running(
            workflowInstanceId: 'run-1',
            workflow: workflow,
            activeRuntimeCompositionFingerprint: 'composition:v1',
            currentExecutionPosition: 1,
            stepExecutions:
                <
                  WorkflowStepExecution<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[_completedExecution(_unknownStep())],
          ),
          throwsArgumentError,
        );

        expect(
          () => EngineeringWorkflowInstance.running(
            workflowInstanceId: 'run-1',
            workflow: workflow,
            activeRuntimeCompositionFingerprint: 'composition:v1',
            currentExecutionPosition: 1,
            stepExecutions:
                <
                  WorkflowStepExecution<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[
                  _completedExecution(_loadStep(contractKey: 'wrong_contract')),
                ],
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejects invalid status state combinations', () {
      final EngineeringWorkflow workflow = _workflow();

      expect(
        () => EngineeringWorkflowInstance.stopped(
          workflowInstanceId: 'run-1',
          workflow: workflow,
          activeRuntimeCompositionFingerprint: 'composition:v1',
          currentExecutionPosition: 1,
          stepExecutions:
              <
                WorkflowStepExecution<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_completedExecution(_loadStep())],
          resumeState: 'Waiting.',
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflowInstance.completed(
          workflowInstanceId: 'run-1',
          workflow: workflow,
          activeRuntimeCompositionFingerprint: 'composition:v1',
          stepExecutions:
              <
                WorkflowStepExecution<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_completedExecution(_loadStep())],
          completionState: 'Done.',
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflowInstance.failed(
          workflowInstanceId: 'run-1',
          workflow: workflow,
          activeRuntimeCompositionFingerprint: 'composition:v1',
          currentExecutionPosition: 1,
          stepExecutions:
              <
                WorkflowStepExecution<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_completedExecution(_loadStep())],
          failureState: 'Failed.',
        ),
        throwsArgumentError,
      );
    });
  });
}

EngineeringWorkflow _workflow() {
  return EngineeringWorkflow(
    workflowKey: 'review_intake',
    semanticVersion: '1.0.0',
    title: 'Review intake',
    steps:
        <
          WorkflowStepDefinition<
            EngineeringServiceInput,
            EngineeringServiceOutput
          >
        >[_loadStep(), _presentStep()],
  );
}

WorkflowStepDefinition<_Input, _Output> _loadStep({
  String contractKey = 'load_engineering_context',
}) {
  return _step(
    stepKey: 'load_context',
    sequenceOrder: 1,
    contractKey: contractKey,
  );
}

WorkflowStepDefinition<_Input, _Output> _presentStep() {
  return _step(
    stepKey: 'present_context',
    sequenceOrder: 2,
    contractKey: 'present_engineering_context',
  );
}

WorkflowStepDefinition<_Input, _Output> _unknownStep() {
  return _step(
    stepKey: 'unknown',
    sequenceOrder: 99,
    contractKey: 'unknown_contract',
  );
}

WorkflowStepDefinition<_Input, _Output> _step({
  required String stepKey,
  required int sequenceOrder,
  required String contractKey,
}) {
  return WorkflowStepDefinition<_Input, _Output>(
    stepKey: stepKey,
    sequenceOrder: sequenceOrder,
    title: stepKey,
    serviceContract: EngineeringServiceContract<_Input, _Output>(
      contractKey: contractKey,
      semanticVersion: '1.0.0',
      description: contractKey,
    ),
  );
}

WorkflowStepExecution<_Input, _Output> _completedExecution(
  WorkflowStepDefinition<_Input, _Output> step, {
  _Input input = const _Input('input'),
  _Output output = const _Output('output'),
}) {
  return WorkflowStepExecution<_Input, _Output>.completed(
    stepDefinition: step,
    resolvedHandlerBindingProvenance: 'catalog:v1/handler:${step.stepKey}',
    input: input,
    output: output,
    completionSummary: 'Completed.',
  );
}

final class _Input implements EngineeringServiceInput {
  const _Input(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    return other is _Input && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

final class _Output implements EngineeringServiceOutput {
  const _Output(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    return other is _Output && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
