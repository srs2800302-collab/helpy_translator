import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_confirmation.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_resolution.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';

void main() {
  group('EngineeringWorkflowConfirmation', () {
    test('confirms resolved workflow selection as runtime authorization', () {
      final EngineeringWorkflow workflow = _workflow('review_intake');
      final EngineeringWorkflowResolution resolution =
          EngineeringWorkflowResolution.resolved(
            selectedWorkflowKey: ' review_intake ',
            explanation: ' Workflow is eligible. ',
          );

      final EngineeringWorkflowConfirmation confirmation =
          EngineeringWorkflowConfirmation.confirmed(
            resolution: resolution,
            workflow: workflow,
            confirmationReference: ' decision:confirm-review-intake ',
            runtimeAuditReferences: <String>[' audit:resolution '],
          );

      expect(confirmation.resolution, resolution);
      expect(confirmation.workflow, workflow);
      expect(confirmation.workflowKey, 'review_intake');
      expect(confirmation.workflowSemanticVersion, '1.0.0');
      expect(
        confirmation.confirmationReference,
        'decision:confirm-review-intake',
      );
      expect(confirmation.resolutionExplanation, 'Workflow is eligible.');
      expect(confirmation.runtimeAuditReferences, <String>['audit:resolution']);
    });

    test('keeps runtime audit references immutable and unique', () {
      final EngineeringWorkflowConfirmation confirmation =
          EngineeringWorkflowConfirmation.confirmed(
            resolution: EngineeringWorkflowResolution.resolved(
              selectedWorkflowKey: 'review_intake',
              explanation: 'Workflow is eligible.',
            ),
            workflow: _workflow('review_intake'),
            confirmationReference: 'decision:confirm-review-intake',
            runtimeAuditReferences: <String>['audit:resolution'],
          );

      expect(
        () => confirmation.runtimeAuditReferences.add('audit:other'),
        throwsUnsupportedError,
      );

      expect(
        () => EngineeringWorkflowConfirmation.confirmed(
          resolution: EngineeringWorkflowResolution.resolved(
            selectedWorkflowKey: 'review_intake',
            explanation: 'Workflow is eligible.',
          ),
          workflow: _workflow('review_intake'),
          confirmationReference: 'decision:confirm-review-intake',
          runtimeAuditReferences: <String>['same', 'same'],
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-resolved workflow resolution', () {
      final EngineeringWorkflow workflow = _workflow('review_intake');

      for (final EngineeringWorkflowResolution resolution
          in <EngineeringWorkflowResolution>[
            EngineeringWorkflowResolution.ambiguous(
              candidateWorkflowKeys: <String>['review_intake', 'rename_entity'],
              explanation: 'Ambiguous.',
            ),
            EngineeringWorkflowResolution.unsupported(
              explanation: 'Unsupported.',
            ),
            EngineeringWorkflowResolution.blocked(explanation: 'Blocked.'),
            EngineeringWorkflowResolution.failed(explanation: 'Failed.'),
          ]) {
        expect(
          () => EngineeringWorkflowConfirmation.confirmed(
            resolution: resolution,
            workflow: workflow,
            confirmationReference: 'decision:confirm-review-intake',
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects workflow mismatch with resolved selection', () {
      expect(
        () => EngineeringWorkflowConfirmation.confirmed(
          resolution: EngineeringWorkflowResolution.resolved(
            selectedWorkflowKey: 'review_intake',
            explanation: 'Workflow is eligible.',
          ),
          workflow: _workflow('rename_entity'),
          confirmationReference: 'decision:confirm-review-intake',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty confirmation identity', () {
      expect(
        () => EngineeringWorkflowConfirmation.confirmed(
          resolution: EngineeringWorkflowResolution.resolved(
            selectedWorkflowKey: 'review_intake',
            explanation: 'Workflow is eligible.',
          ),
          workflow: _workflow('review_intake'),
          confirmationReference: ' ',
        ),
        throwsArgumentError,
      );
    });
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
