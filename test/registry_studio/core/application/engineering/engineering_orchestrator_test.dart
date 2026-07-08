import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_orchestrator.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_capability_catalog.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_confirmation.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_instance.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_resolution.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_execution.dart';

void main() {
  group('EngineeringOrchestrator', () {
    test('starts one confirmed workflow instance', () {
      final EngineeringWorkflow workflow = _workflow('review_intake');
      final EngineeringWorkflowConfirmation confirmation =
          EngineeringWorkflowConfirmation.confirmed(
            resolution: EngineeringWorkflowResolution.resolved(
              selectedWorkflowKey: 'review_intake',
              explanation: 'Workflow is eligible.',
            ),
            workflow: workflow,
            confirmationReference: 'decision:confirm-review-intake',
            runtimeAuditReferences: <String>['audit:resolution'],
          );

      final EngineeringWorkflowInstance instance =
          const EngineeringOrchestrator().startConfirmedWorkflow(
            workflowInstanceId: 'workflow-instance-001',
            confirmation: confirmation,
            activeRuntimeCompositionFingerprint: 'composition:v1',
          );

      expect(instance.workflowInstanceId, 'workflow-instance-001');
      expect(instance.workflow, workflow);
      expect(instance.workflowKey, 'review_intake');
      expect(instance.status, EngineeringWorkflowInstanceStatus.running);
      expect(instance.isRunning, isTrue);
      expect(
        instance.currentExecutionPosition,
        workflow.firstStep.sequenceOrder,
      );
      expect(instance.currentStepDefinition, workflow.firstStep);
      expect(instance.stepExecutions, isEmpty);
      expect(instance.intermediateResultReferences, isEmpty);
      expect(instance.engineerDecisionPoints, isEmpty);
      expect(instance.failureState, isNull);
      expect(instance.resumeState, isNull);
      expect(instance.completionState, isNull);
      expect(instance.registryTransactionReference, isNull);
      expect(instance.runtimeAuditReferences, <String>[
        'decision:confirm-review-intake',
        'audit:resolution',
      ]);
    });

    test(
      'executes current step through resolved approved binding and completes workflow',
      () async {
        final EngineeringWorkflow workflow = _workflow('review_intake');
        final EngineeringWorkflowInstance instance = _startedInstance(workflow);
        final _Service service = _Service(contract: _contract('review_intake'));

        final EngineeringWorkflowInstance updated =
            await const EngineeringOrchestrator()
                .executeCurrentStep<_Input, _Output>(
                  instance: instance,
                  capabilityCatalog: _catalog(service),
                  input: const _Input('target'),
                  completionSummary: 'Step completed.',
                  runtimeAuditReferences: <String>['audit:step'],
                );

        expect(updated.status, EngineeringWorkflowInstanceStatus.completed);
        expect(updated.isCompleted, isTrue);
        expect(updated.completionState, 'Step completed.');
        expect(updated.stepExecutions.single.isCompleted, isTrue);
        expect(
          updated.stepExecutions.single.resolvedHandlerBindingProvenance,
          'review_intake.contract:handler:v1',
        );
        expect(updated.runtimeAuditReferences, <String>[
          'decision:confirm-review-intake',
          'audit:step',
          'trace:target',
        ]);
        expect(service.executeCount, 1);
      },
    );

    test(
      'executes current step and advances to next declared position',
      () async {
        final EngineeringWorkflow workflow = _workflow(
          'review_intake',
          stepCount: 2,
        );
        final EngineeringWorkflowInstance instance = _startedInstance(workflow);
        final _Service service = _Service(contract: _contract('review_intake'));

        final EngineeringWorkflowInstance updated =
            await const EngineeringOrchestrator()
                .executeCurrentStep<_Input, _Output>(
                  instance: instance,
                  capabilityCatalog: _catalog(service),
                  input: const _Input('target'),
                  completionSummary: 'First step completed.',
                );

        expect(updated.status, EngineeringWorkflowInstanceStatus.running);
        expect(updated.currentExecutionPosition, 2);
        expect(updated.currentStepDefinition.stepKey, 'review_intake.step2');
        expect(updated.stepExecutions.single.isCompleted, isTrue);
        expect(updated.completionState, isNull);
        expect(service.executeCount, 1);
      },
    );

    test(
      'returns failed instance when service returns typed failure',
      () async {
        final EngineeringWorkflow workflow = _workflow('review_intake');
        final EngineeringWorkflowInstance instance = _startedInstance(workflow);
        final _Service service = _Service(
          contract: _contract('review_intake'),
          failure: EngineeringServiceFailure(
            code: 'missing_context',
            message: 'Missing context.',
          ),
        );

        final EngineeringWorkflowInstance updated =
            await const EngineeringOrchestrator()
                .executeCurrentStep<_Input, _Output>(
                  instance: instance,
                  capabilityCatalog: _catalog(service),
                  input: const _Input('target'),
                  completionSummary: 'Step completed.',
                );

        expect(updated.status, EngineeringWorkflowInstanceStatus.failed);
        expect(updated.failureState, 'missing_context: Missing context.');
        expect(updated.stepExecutions.single.isFailed, isTrue);
        expect(updated.stepExecutions.single.failure?.code, 'missing_context');
        expect(service.executeCount, 1);
      },
    );

    test(
      'stops before execution when current step requires engineer confirmation',
      () async {
        final EngineeringWorkflow workflow = _workflow(
          'review_intake',
          requiresConfirmation: true,
        );
        final EngineeringWorkflowInstance instance = _startedInstance(workflow);
        final _Service service = _Service(contract: _contract('review_intake'));

        final EngineeringWorkflowInstance updated =
            await const EngineeringOrchestrator()
                .executeCurrentStep<_Input, _Output>(
                  instance: instance,
                  capabilityCatalog: _catalog(service),
                  input: const _Input('target'),
                  completionSummary: 'Step completed.',
                  engineerDecisionPointReference: 'decision:confirm-step',
                  engineerDecisionStopReason:
                      'Required engineer confirmation before execution.',
                );

        expect(updated.status, EngineeringWorkflowInstanceStatus.stopped);
        expect(
          updated.resumeState,
          'Required engineer confirmation before execution.',
        );
        expect(updated.engineerDecisionPoints, <String>[
          'decision:confirm-step',
        ]);
        expect(updated.currentStepExecution?.isStopped, isTrue);
        expect(
          updated.currentStepExecution?.engineerConfirmationState,
          WorkflowStepEngineerConfirmationState.pending,
        );
        expect(service.executeCount, 0);
      },
    );

    test('resumes stopped current step after engineer decision', () async {
      final EngineeringWorkflow workflow = _workflow(
        'review_intake',
        requiresConfirmation: true,
      );
      final _Service service = _Service(contract: _contract('review_intake'));
      final EngineeringWorkflowInstance stopped = await _stoppedInstance(
        workflow,
        service,
      );

      final EngineeringWorkflowInstance resumed =
          await const EngineeringOrchestrator()
              .resumeCurrentStepAfterEngineerDecision<_Input, _Output>(
                instance: stopped,
                capabilityCatalog: _catalog(service),
                engineerDecisionReference: 'decision:resume-step',
                completionSummary: 'Step completed after confirmation.',
                runtimeAuditReferences: <String>['audit:resume'],
              );

      expect(resumed.status, EngineeringWorkflowInstanceStatus.completed);
      expect(resumed.stepExecutions.single.isCompleted, isTrue);
      expect(
        resumed.stepExecutions.single.engineerConfirmationState,
        WorkflowStepEngineerConfirmationState.confirmed,
      );
      expect(resumed.completionState, 'Step completed after confirmation.');
      expect(resumed.runtimeAuditReferences, <String>[
        'decision:confirm-review-intake',
        'decision:resume-step',
        'audit:resume',
        'trace:target',
      ]);
      expect(service.executeCount, 1);
    });

    test(
      'does not resume automatically when handler binding provenance changed',
      () async {
        final EngineeringWorkflow workflow = _workflow(
          'review_intake',
          requiresConfirmation: true,
        );
        final _Service service = _Service(contract: _contract('review_intake'));
        final EngineeringWorkflowInstance stopped = await _stoppedInstance(
          workflow,
          service,
        );

        final EngineeringWorkflowInstance stillStopped =
            await const EngineeringOrchestrator()
                .resumeCurrentStepAfterEngineerDecision<_Input, _Output>(
                  instance: stopped,
                  capabilityCatalog: _catalog(
                    service,
                    bindingProvenance: 'review_intake.contract:handler:v2',
                  ),
                  engineerDecisionReference: 'decision:resume-step',
                  completionSummary: 'Step completed after confirmation.',
                  bindingChangedDecisionPointReference:
                      'decision:confirm-new-binding',
                  bindingChangedStopReason:
                      'Handler binding provenance changed before resume.',
                );

        expect(stillStopped.status, EngineeringWorkflowInstanceStatus.stopped);
        expect(
          stillStopped.resumeState,
          'Handler binding provenance changed before resume.',
        );
        expect(stillStopped.engineerDecisionPoints, <String>[
          'decision:confirm-step',
          'decision:confirm-new-binding',
        ]);
        expect(stillStopped.currentStepExecution?.isStopped, isTrue);
        expect(service.executeCount, 0);
      },
    );

    test('rejects resume for non-stopped workflow instance', () async {
      final EngineeringWorkflow workflow = _workflow('review_intake');
      final EngineeringWorkflowInstance instance = _startedInstance(workflow);
      final _Service service = _Service(contract: _contract('review_intake'));

      expect(
        () => const EngineeringOrchestrator()
            .resumeCurrentStepAfterEngineerDecision<_Input, _Output>(
              instance: instance,
              capabilityCatalog: _catalog(service),
              engineerDecisionReference: 'decision:resume-step',
              completionSummary: 'Step completed.',
            ),
        throwsStateError,
      );
    });

    test(
      'rejects execution with mismatched runtime composition catalog',
      () async {
        final EngineeringWorkflow workflow = _workflow('review_intake');
        final EngineeringWorkflowInstance instance = _startedInstance(workflow);
        final _Service service = _Service(contract: _contract('review_intake'));

        expect(
          () => const EngineeringOrchestrator()
              .executeCurrentStep<_Input, _Output>(
                instance: instance,
                capabilityCatalog: _catalog(
                  service,
                  compositionFingerprint: 'composition:v2',
                ),
                input: const _Input('target'),
                completionSummary: 'Step completed.',
              ),
          throwsArgumentError,
        );
      },
    );
  });
}

EngineeringWorkflowInstance _startedInstance(EngineeringWorkflow workflow) {
  return const EngineeringOrchestrator().startConfirmedWorkflow(
    workflowInstanceId: 'workflow-instance-001',
    confirmation: EngineeringWorkflowConfirmation.confirmed(
      resolution: EngineeringWorkflowResolution.resolved(
        selectedWorkflowKey: workflow.workflowKey,
        explanation: 'Workflow is eligible.',
      ),
      workflow: workflow,
      confirmationReference: 'decision:confirm-review-intake',
    ),
    activeRuntimeCompositionFingerprint: 'composition:v1',
  );
}

Future<EngineeringWorkflowInstance> _stoppedInstance(
  EngineeringWorkflow workflow,
  _Service service,
) {
  return const EngineeringOrchestrator().executeCurrentStep<_Input, _Output>(
    instance: _startedInstance(workflow),
    capabilityCatalog: _catalog(service),
    input: const _Input('target'),
    completionSummary: 'Step completed.',
    engineerDecisionPointReference: 'decision:confirm-step',
    engineerDecisionStopReason:
        'Required engineer confirmation before execution.',
  );
}

EngineeringWorkflow _workflow(
  String workflowKey, {
  bool requiresConfirmation = false,
  int stepCount = 1,
}) {
  return EngineeringWorkflow(
    workflowKey: workflowKey,
    semanticVersion: '1.0.0',
    title: workflowKey,
    steps:
        <
          WorkflowStepDefinition<
            EngineeringServiceInput,
            EngineeringServiceOutput
          >
        >[
          for (int index = 1; index <= stepCount; index++)
            WorkflowStepDefinition<_Input, _Output>(
              stepKey: '$workflowKey.step$index',
              sequenceOrder: index,
              title: '$workflowKey step $index',
              serviceContract: EngineeringServiceContract<_Input, _Output>(
                contractKey: index == 1
                    ? '$workflowKey.contract'
                    : '$workflowKey.contract.$index',
                semanticVersion: '1.0.0',
                description: '$workflowKey contract $index.',
              ),
              engineerConfirmationRequirements:
                  index == 1 && requiresConfirmation
                  ? <String>['Confirm before execution.']
                  : const <String>[],
            ),
        ],
  );
}

EngineeringServiceContract<_Input, _Output> _contract(String workflowKey) {
  return EngineeringServiceContract<_Input, _Output>(
    contractKey: '$workflowKey.contract',
    semanticVersion: '1.0.0',
    description: '$workflowKey contract.',
  );
}

EngineeringServiceCapabilityCatalog _catalog(
  _Service service, {
  String compositionFingerprint = 'composition:v1',
  String? bindingProvenance,
}) {
  return EngineeringServiceCapabilityCatalog(
    catalogVersion: '1.0.0',
    compositionFingerprint: compositionFingerprint,
    bindings:
        <
          EngineeringServiceBinding<
            EngineeringServiceInput,
            EngineeringServiceOutput
          >
        >[
          EngineeringServiceBinding<_Input, _Output>(
            bindingKey: '${service.contract.contractKey}.binding',
            service: service,
            bindingProvenance:
                bindingProvenance ??
                '${service.contract.contractKey}:handler:v1',
            source: EngineeringServiceBindingSource.platform,
          ),
        ],
  );
}

final class _Service implements EngineeringService<_Input, _Output> {
  _Service({required this.contract, this.failure});

  @override
  final EngineeringServiceContract<_Input, _Output> contract;

  final EngineeringServiceFailure? failure;

  int executeCount = 0;

  @override
  EngineeringServiceFailure? validatePreconditions(_Input input) => failure;

  @override
  Future<EngineeringServiceResult<_Output>> execute(_Input input) async {
    executeCount++;

    final EngineeringServiceFailure? currentFailure = validatePreconditions(
      input,
    );
    if (currentFailure != null) {
      return EngineeringServiceResult<_Output>.failure(
        failure: currentFailure,
        traceabilityReferences: <String>['trace:${input.value}'],
      );
    }

    return EngineeringServiceResult<_Output>.success(
      output: _Output('handled:${input.value}'),
      traceabilityReferences: <String>['trace:${input.value}'],
    );
  }
}

final class _Input implements EngineeringServiceInput {
  const _Input(this.value);

  final String value;
}

final class _Output implements EngineeringServiceOutput {
  const _Output(this.value);

  final String value;
}
