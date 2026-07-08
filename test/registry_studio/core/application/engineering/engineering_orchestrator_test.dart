import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_orchestrator.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_confirmation.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_instance.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_resolution.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';

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

    test('deduplicates confirmation reference in runtime audit evidence', () {
      final EngineeringWorkflow workflow = _workflow('review_intake');
      final EngineeringWorkflowConfirmation confirmation =
          EngineeringWorkflowConfirmation.confirmed(
            resolution: EngineeringWorkflowResolution.resolved(
              selectedWorkflowKey: 'review_intake',
              explanation: 'Workflow is eligible.',
            ),
            workflow: workflow,
            confirmationReference: 'decision:confirm-review-intake',
            runtimeAuditReferences: <String>['decision:confirm-review-intake'],
          );

      final EngineeringWorkflowInstance instance =
          const EngineeringOrchestrator().startConfirmedWorkflow(
            workflowInstanceId: 'workflow-instance-001',
            confirmation: confirmation,
            activeRuntimeCompositionFingerprint: 'composition:v1',
          );

      expect(instance.runtimeAuditReferences, <String>[
        'decision:confirm-review-intake',
      ]);
    });

    test(
      'does not advance workflow, resolve services or create registry transaction',
      () {
        final EngineeringWorkflow workflow = _workflow('review_intake');
        final EngineeringWorkflowConfirmation confirmation =
            EngineeringWorkflowConfirmation.confirmed(
              resolution: EngineeringWorkflowResolution.resolved(
                selectedWorkflowKey: 'review_intake',
                explanation: 'Workflow is eligible.',
              ),
              workflow: workflow,
              confirmationReference: 'decision:confirm-review-intake',
            );

        final EngineeringWorkflowInstance instance =
            const EngineeringOrchestrator().startConfirmedWorkflow(
              workflowInstanceId: 'workflow-instance-001',
              confirmation: confirmation,
              activeRuntimeCompositionFingerprint: 'composition:v1',
            );

        expect(instance.stepExecutions, isEmpty);
        expect(
          instance.currentExecutionPosition,
          workflow.firstStep.sequenceOrder,
        );
        expect(instance.registryTransactionReference, isNull);
      },
    );
  });
}

EngineeringWorkflow _workflow(String workflowKey) {
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
          WorkflowStepDefinition<_Input, _Output>(
            stepKey: '$workflowKey.step',
            sequenceOrder: 1,
            title: '$workflowKey step',
            serviceContract: EngineeringServiceContract<_Input, _Output>(
              contractKey: '$workflowKey.contract',
              semanticVersion: '1.0.0',
              description: '$workflowKey contract.',
            ),
          ),
        ],
  );
}

final class _Input implements EngineeringServiceInput {
  const _Input();
}

final class _Output implements EngineeringServiceOutput {
  const _Output();
}
