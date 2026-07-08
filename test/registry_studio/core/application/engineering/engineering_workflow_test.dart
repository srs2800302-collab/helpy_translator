import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';

void main() {
  group('EngineeringWorkflow', () {
    test('normalizes workflow identity and sorts steps by sequence order', () {
      final EngineeringWorkflow workflow = EngineeringWorkflow(
        workflowKey: ' review_intake ',
        semanticVersion: ' 1.0.0 ',
        title: ' Review intake entity ',
        steps:
            <
              WorkflowStepDefinition<
                EngineeringServiceInput,
                EngineeringServiceOutput
              >
            >[
              _step(stepKey: 'second', sequenceOrder: 2),
              _step(stepKey: 'first', sequenceOrder: 1),
            ],
        stopConditions: <String>[' missing context '],
        resumeConditions: <String>[' context restored '],
        completionConditions: <String>[' review completed '],
      );

      expect(workflow.workflowKey, 'review_intake');
      expect(workflow.semanticVersion, '1.0.0');
      expect(workflow.title, 'Review intake entity');
      expect(workflow.stepKeys, <String>['first', 'second']);
      expect(workflow.firstStep.stepKey, 'first');
      expect(workflow.lastStep.stepKey, 'second');
      expect(workflow.stopConditions, <String>['missing context']);
      expect(workflow.resumeConditions, <String>['context restored']);
      expect(workflow.completionConditions, <String>['review completed']);
    });

    test('keeps steps and condition lists immutable', () {
      final EngineeringWorkflow workflow = EngineeringWorkflow(
        workflowKey: 'review_intake',
        semanticVersion: '1.0.0',
        title: 'Review intake entity',
        steps:
            <
              WorkflowStepDefinition<
                EngineeringServiceInput,
                EngineeringServiceOutput
              >
            >[_step(stepKey: 'first', sequenceOrder: 1)],
        stopConditions: <String>['missing context'],
        resumeConditions: <String>['context restored'],
        completionConditions: <String>['review completed'],
      );

      expect(
        () => workflow.steps.add(_step(stepKey: 'second', sequenceOrder: 2)),
        throwsUnsupportedError,
      );
      expect(() => workflow.stepKeys.add('second'), throwsUnsupportedError);
      expect(
        () => workflow.stopConditions.add('another'),
        throwsUnsupportedError,
      );
      expect(
        () => workflow.resumeConditions.add('another'),
        throwsUnsupportedError,
      );
      expect(
        () => workflow.completionConditions.add('another'),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid workflow identity and empty steps', () {
      expect(
        () => EngineeringWorkflow(
          workflowKey: ' ',
          semanticVersion: '1.0.0',
          title: 'Review intake entity',
          steps:
              <
                WorkflowStepDefinition<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_step(stepKey: 'first', sequenceOrder: 1)],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflow(
          workflowKey: 'review_intake',
          semanticVersion: ' ',
          title: 'Review intake entity',
          steps:
              <
                WorkflowStepDefinition<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_step(stepKey: 'first', sequenceOrder: 1)],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflow(
          workflowKey: 'review_intake',
          semanticVersion: '1.0.0',
          title: ' ',
          steps:
              <
                WorkflowStepDefinition<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_step(stepKey: 'first', sequenceOrder: 1)],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflow(
          workflowKey: 'review_intake',
          semanticVersion: '1.0.0',
          title: 'Review intake entity',
          steps:
              const <
                WorkflowStepDefinition<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate step keys and sequence orders', () {
      expect(
        () => EngineeringWorkflow(
          workflowKey: 'review_intake',
          semanticVersion: '1.0.0',
          title: 'Review intake entity',
          steps:
              <
                WorkflowStepDefinition<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[
                _step(stepKey: 'same', sequenceOrder: 1),
                _step(stepKey: 'same', sequenceOrder: 2),
              ],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflow(
          workflowKey: 'review_intake',
          semanticVersion: '1.0.0',
          title: 'Review intake entity',
          steps:
              <
                WorkflowStepDefinition<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[
                _step(stepKey: 'first', sequenceOrder: 1),
                _step(stepKey: 'second', sequenceOrder: 1),
              ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid workflow condition values', () {
      expect(
        () => EngineeringWorkflow(
          workflowKey: 'review_intake',
          semanticVersion: '1.0.0',
          title: 'Review intake entity',
          steps:
              <
                WorkflowStepDefinition<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_step(stepKey: 'first', sequenceOrder: 1)],
          stopConditions: <String>['missing context', ' '],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflow(
          workflowKey: 'review_intake',
          semanticVersion: '1.0.0',
          title: 'Review intake entity',
          steps:
              <
                WorkflowStepDefinition<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_step(stepKey: 'first', sequenceOrder: 1)],
          completionConditions: <String>['same', 'same'],
        ),
        throwsArgumentError,
      );
    });
  });
}

WorkflowStepDefinition<_Input, _Output> _step({
  required String stepKey,
  required int sequenceOrder,
}) {
  return WorkflowStepDefinition<_Input, _Output>(
    stepKey: stepKey,
    sequenceOrder: sequenceOrder,
    title: stepKey,
    serviceContract: EngineeringServiceContract<_Input, _Output>(
      contractKey: 'contract_$stepKey',
      semanticVersion: '1.0.0',
      description: 'Contract $stepKey.',
    ),
  );
}

final class _Input implements EngineeringServiceInput {
  const _Input();
}

final class _Output implements EngineeringServiceOutput {
  const _Output();
}
