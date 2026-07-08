import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';

void main() {
  group('WorkflowStepDefinition', () {
    test('normalizes step identity and exposes required service contract', () {
      final EngineeringServiceContract<_Input, _Output> contract =
          _serviceContract();

      final WorkflowStepDefinition<_Input, _Output> step =
          WorkflowStepDefinition<_Input, _Output>(
            stepKey: ' load_context ',
            sequenceOrder: 1,
            title: ' Load engineering context ',
            serviceContract: contract,
            preconditions: <String>[' engineer intent exists '],
            stopConditions: <String>[' missing target entity '],
            engineerConfirmationRequirements: <String>[
              ' confirm selected target ',
            ],
          );

      expect(step.stepKey, 'load_context');
      expect(step.sequenceOrder, 1);
      expect(step.title, 'Load engineering context');
      expect(step.serviceContract, contract);
      expect(step.requiredServiceContractKey, 'load_engineering_context');
      expect(step.inputType, _Input);
      expect(step.outputType, _Output);
      expect(step.preconditions, <String>['engineer intent exists']);
      expect(step.stopConditions, <String>['missing target entity']);
      expect(step.engineerConfirmationRequirements, <String>[
        'confirm selected target',
      ]);
      expect(step.requiresEngineerConfirmation, isTrue);
    });

    test('allows a step without engineer confirmation requirements', () {
      final WorkflowStepDefinition<_Input, _Output> step =
          WorkflowStepDefinition<_Input, _Output>(
            stepKey: 'load_context',
            sequenceOrder: 1,
            title: 'Load engineering context',
            serviceContract: _serviceContract(),
          );

      expect(step.preconditions, isEmpty);
      expect(step.stopConditions, isEmpty);
      expect(step.engineerConfirmationRequirements, isEmpty);
      expect(step.requiresEngineerConfirmation, isFalse);
    });

    test('keeps declared lists immutable', () {
      final WorkflowStepDefinition<_Input, _Output> step =
          WorkflowStepDefinition<_Input, _Output>(
            stepKey: 'load_context',
            sequenceOrder: 1,
            title: 'Load engineering context',
            serviceContract: _serviceContract(),
            preconditions: <String>['engineer intent exists'],
            stopConditions: <String>['missing target entity'],
            engineerConfirmationRequirements: <String>[
              'confirm selected target',
            ],
          );

      expect(() => step.preconditions.add('another'), throwsUnsupportedError);
      expect(() => step.stopConditions.add('another'), throwsUnsupportedError);
      expect(
        () => step.engineerConfirmationRequirements.add('another'),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid identity and sequence order', () {
      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: ' ',
          sequenceOrder: 1,
          title: 'Load engineering context',
          serviceContract: _serviceContract(),
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: 'load_context',
          sequenceOrder: 0,
          title: 'Load engineering context',
          serviceContract: _serviceContract(),
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: 'load_context',
          sequenceOrder: 1,
          title: ' ',
          serviceContract: _serviceContract(),
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty declared list values', () {
      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: 'load_context',
          sequenceOrder: 1,
          title: 'Load engineering context',
          serviceContract: _serviceContract(),
          preconditions: <String>['engineer intent exists', ' '],
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: 'load_context',
          sequenceOrder: 1,
          title: 'Load engineering context',
          serviceContract: _serviceContract(),
          stopConditions: <String>['missing target entity', ' '],
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: 'load_context',
          sequenceOrder: 1,
          title: 'Load engineering context',
          serviceContract: _serviceContract(),
          engineerConfirmationRequirements: <String>[
            'confirm selected target',
            ' ',
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate declared list values', () {
      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: 'load_context',
          sequenceOrder: 1,
          title: 'Load engineering context',
          serviceContract: _serviceContract(),
          preconditions: <String>['same', 'same'],
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: 'load_context',
          sequenceOrder: 1,
          title: 'Load engineering context',
          serviceContract: _serviceContract(),
          stopConditions: <String>['same', 'same'],
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepDefinition<_Input, _Output>(
          stepKey: 'load_context',
          sequenceOrder: 1,
          title: 'Load engineering context',
          serviceContract: _serviceContract(),
          engineerConfirmationRequirements: <String>['same', 'same'],
        ),
        throwsArgumentError,
      );
    });
  });
}

EngineeringServiceContract<_Input, _Output> _serviceContract() {
  return EngineeringServiceContract<_Input, _Output>(
    contractKey: ' load_engineering_context ',
    semanticVersion: ' 1.0.0 ',
    description: ' Load engineering context. ',
  );
}

final class _Input implements EngineeringServiceInput {
  const _Input();
}

final class _Output implements EngineeringServiceOutput {
  const _Output();
}
