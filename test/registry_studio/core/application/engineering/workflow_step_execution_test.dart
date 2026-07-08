import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_execution.dart';

void main() {
  group('WorkflowStepExecutionStatus', () {
    test('exposes contract labels', () {
      expect(WorkflowStepExecutionStatus.pending.contractLabel, 'PENDING');
      expect(WorkflowStepExecutionStatus.running.contractLabel, 'RUNNING');
      expect(WorkflowStepExecutionStatus.stopped.contractLabel, 'STOPPED');
      expect(WorkflowStepExecutionStatus.completed.contractLabel, 'COMPLETED');
      expect(WorkflowStepExecutionStatus.failed.contractLabel, 'FAILED');
    });
  });

  group('WorkflowStepEngineerConfirmationState', () {
    test('exposes contract labels', () {
      expect(
        WorkflowStepEngineerConfirmationState.notRequired.contractLabel,
        'NOT_REQUIRED',
      );
      expect(
        WorkflowStepEngineerConfirmationState.pending.contractLabel,
        'PENDING',
      );
      expect(
        WorkflowStepEngineerConfirmationState.confirmed.contractLabel,
        'CONFIRMED',
      );
    });
  });

  group('WorkflowStepExecution', () {
    test(
      'creates pending execution evidence and preserves resolved binding',
      () {
        final WorkflowStepExecution<_Input, _Output> execution =
            WorkflowStepExecution<_Input, _Output>.pending(
              stepDefinition: _step(requiresConfirmation: true),
              resolvedHandlerBindingProvenance: ' catalog:v1/handler:load ',
            );

        expect(execution.status, WorkflowStepExecutionStatus.pending);
        expect(
          execution.engineerConfirmationState,
          WorkflowStepEngineerConfirmationState.pending,
        );
        expect(execution.stepKey, 'load_context');
        expect(execution.sequenceOrder, 1);
        expect(
          execution.resolvedServiceContractKey,
          'load_engineering_context',
        );
        expect(execution.resolvedServiceContractSemanticVersion, '1.0.0');
        expect(
          execution.resolvedHandlerBindingProvenance,
          'catalog:v1/handler:load',
        );
        expect(execution.input, isNull);
        expect(execution.output, isNull);
        expect(execution.failure, isNull);
        expect(execution.isPending, isTrue);
        expect(execution.isTerminal, isFalse);
      },
    );

    test('creates running execution evidence with typed input', () {
      final _Input input = const _Input('target');

      final WorkflowStepExecution<_Input, _Output> execution =
          WorkflowStepExecution<_Input, _Output>.running(
            stepDefinition: _step(requiresConfirmation: true),
            resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
            input: input,
          );

      expect(execution.status, WorkflowStepExecutionStatus.running);
      expect(
        execution.engineerConfirmationState,
        WorkflowStepEngineerConfirmationState.confirmed,
      );
      expect(execution.input, input);
      expect(execution.output, isNull);
      expect(execution.failure, isNull);
      expect(execution.isRunning, isTrue);
    });

    test(
      'creates stopped resumable execution evidence and guards binding changes',
      () {
        final WorkflowStepExecution<_Input, _Output> execution =
            WorkflowStepExecution<_Input, _Output>.stopped(
              stepDefinition: _step(),
              resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
              input: const _Input('target'),
              stopReason: ' Missing verified context. ',
            );

        expect(execution.status, WorkflowStepExecutionStatus.stopped);
        expect(execution.stopReason, 'Missing verified context.');
        expect(execution.isResumable, isTrue);
        expect(
          execution.canResumeWithBinding(' catalog:v1/handler:load '),
          isTrue,
        );
        expect(
          execution.requiresEngineerDecisionForBinding(
            'catalog:v2/handler:load',
          ),
          isTrue,
        );
      },
    );

    test('creates completed execution evidence with typed output', () {
      final _Input input = const _Input('target');
      final _Output output = const _Output('done');

      final WorkflowStepExecution<_Input, _Output> execution =
          WorkflowStepExecution<_Input, _Output>.completed(
            stepDefinition: _step(),
            resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
            input: input,
            output: output,
            completionSummary: ' Step completed. ',
          );

      expect(execution.status, WorkflowStepExecutionStatus.completed);
      expect(execution.input, input);
      expect(execution.output, output);
      expect(execution.failure, isNull);
      expect(execution.completionSummary, 'Step completed.');
      expect(execution.isCompleted, isTrue);
      expect(execution.isTerminal, isTrue);
    });

    test('creates failed execution evidence with typed failure', () {
      final EngineeringServiceFailure failure = EngineeringServiceFailure(
        code: 'missing_context',
        message: 'Missing verified context.',
      );

      final WorkflowStepExecution<_Input, _Output> execution =
          WorkflowStepExecution<_Input, _Output>.failed(
            stepDefinition: _step(),
            resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
            input: const _Input('target'),
            failure: failure,
          );

      expect(execution.status, WorkflowStepExecutionStatus.failed);
      expect(execution.input, const _Input('target'));
      expect(execution.output, isNull);
      expect(execution.failure, failure);
      expect(execution.isFailed, isTrue);
      expect(execution.isTerminal, isTrue);
    });

    test(
      'uses NOT_REQUIRED confirmation state when confirmation is not needed',
      () {
        final WorkflowStepExecution<_Input, _Output> execution =
            WorkflowStepExecution<_Input, _Output>.running(
              stepDefinition: _step(),
              resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
              input: const _Input('target'),
            );

        expect(
          execution.engineerConfirmationState,
          WorkflowStepEngineerConfirmationState.notRequired,
        );
      },
    );

    test('allows stopped step to preserve pending engineer confirmation', () {
      final WorkflowStepDefinition<_Input, _Output> step =
          WorkflowStepDefinition<_Input, _Output>(
            stepKey: 'confirmable_step',
            sequenceOrder: 1,
            title: 'Confirmable step',
            serviceContract: EngineeringServiceContract<_Input, _Output>(
              contractKey: 'confirmable_contract',
              semanticVersion: '1.0.0',
              description: 'Confirmable contract.',
            ),
            engineerConfirmationRequirements: <String>[
              'Confirm target before execution.',
            ],
          );

      final WorkflowStepExecution<_Input, _Output> execution =
          WorkflowStepExecution<_Input, _Output>.stopped(
            stepDefinition: step,
            resolvedHandlerBindingProvenance: 'handler:v1',
            input: const _Input('target'),
            stopReason: 'Required engineer confirmation before execution.',
            engineerConfirmationState:
                WorkflowStepEngineerConfirmationState.pending,
          );

      expect(execution.isStopped, isTrue);
      expect(
        execution.engineerConfirmationState,
        WorkflowStepEngineerConfirmationState.pending,
      );
      expect(execution.isResumable, isTrue);
    });

    test('rejects invalid confirmation state combinations', () {
      expect(
        () => WorkflowStepExecution<_Input, _Output>.running(
          stepDefinition: _step(requiresConfirmation: true),
          resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
          input: const _Input('target'),
          engineerConfirmationState:
              WorkflowStepEngineerConfirmationState.pending,
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepExecution<_Input, _Output>.running(
          stepDefinition: _step(),
          resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
          input: const _Input('target'),
          engineerConfirmationState:
              WorkflowStepEngineerConfirmationState.confirmed,
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty provenance and state text', () {
      expect(
        () => WorkflowStepExecution<_Input, _Output>.pending(
          stepDefinition: _step(),
          resolvedHandlerBindingProvenance: ' ',
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepExecution<_Input, _Output>.stopped(
          stepDefinition: _step(),
          resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
          input: const _Input('target'),
          stopReason: ' ',
        ),
        throwsArgumentError,
      );

      expect(
        () => WorkflowStepExecution<_Input, _Output>.completed(
          stepDefinition: _step(),
          resolvedHandlerBindingProvenance: 'catalog:v1/handler:load',
          input: const _Input('target'),
          output: const _Output('done'),
          completionSummary: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}

WorkflowStepDefinition<_Input, _Output> _step({
  bool requiresConfirmation = false,
}) {
  return WorkflowStepDefinition<_Input, _Output>(
    stepKey: 'load_context',
    sequenceOrder: 1,
    title: 'Load engineering context',
    serviceContract: EngineeringServiceContract<_Input, _Output>(
      contractKey: 'load_engineering_context',
      semanticVersion: '1.0.0',
      description: 'Load engineering context.',
    ),
    engineerConfirmationRequirements: requiresConfirmation
        ? <String>['confirm selected target']
        : const <String>[],
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
