import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_capability_catalog.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';

void main() {
  group('EngineeringServiceBinding', () {
    test('normalizes binding identity and exposes contract identity', () {
      final EngineeringServiceBinding<_Input, _Output> binding = _binding(
        bindingKey: ' context_binding ',
        bindingProvenance: ' platform:v1/context ',
      );

      expect(binding.bindingKey, 'context_binding');
      expect(binding.bindingProvenance, 'platform:v1/context');
      expect(binding.source, EngineeringServiceBindingSource.platform);
      expect(binding.source.contractLabel, 'PLATFORM');
      expect(binding.approval, EngineeringServiceBindingApproval.approved);
      expect(binding.approval.contractLabel, 'APPROVED');
      expect(binding.isApproved, isTrue);
      expect(binding.contractKey, 'handle_context');
      expect(binding.contractSemanticVersion, '1.0.0');
      expect(binding.inputType, _Input);
      expect(binding.outputType, _Output);
    });

    test('rejects empty binding identity and provenance', () {
      expect(
        () =>
            _binding(bindingKey: ' ', bindingProvenance: 'platform:v1/context'),
        throwsArgumentError,
      );

      expect(
        () => _binding(bindingKey: 'context', bindingProvenance: ' '),
        throwsArgumentError,
      );
    });
  });

  group('EngineeringServiceCapabilityCatalog', () {
    test(
      'creates immutable versioned catalog and resolves binding for workflow step',
      () {
        final _Service service = _Service();
        final EngineeringServiceBinding<_Input, _Output> binding = _binding(
          service: service,
        );
        final WorkflowStepDefinition<_Input, _Output> step = _step();

        final EngineeringServiceCapabilityCatalog catalog =
            EngineeringServiceCapabilityCatalog(
              catalogVersion: ' 1.0.0 ',
              compositionFingerprint: ' composition:v1 ',
              bindings:
                  <
                    EngineeringServiceBinding<
                      EngineeringServiceInput,
                      EngineeringServiceOutput
                    >
                  >[binding],
              executableWorkflows: <EngineeringWorkflow>[_workflow(step)],
            );

        expect(catalog.catalogVersion, '1.0.0');
        expect(catalog.compositionFingerprint, 'composition:v1');
        expect(catalog.bindings.single.bindingKey, 'context_binding');
        expect(() => catalog.bindings.clear(), throwsUnsupportedError);

        final EngineeringServiceBinding<_Input, _Output> resolved = catalog
            .resolveForStep(step);

        expect(resolved, binding);
        expect(catalog.bindingProvenanceForStep(step), 'platform:v1/context');
        expect(service.executeCount, 0);
      },
    );

    test('resolves only declared typed service contract', () {
      final EngineeringServiceCapabilityCatalog catalog =
          EngineeringServiceCapabilityCatalog(
            catalogVersion: '1.0.0',
            compositionFingerprint: 'composition:v1',
            bindings:
                <
                  EngineeringServiceBinding<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[_binding()],
          );

      expect(
        catalog.resolveContract(_serviceContract()).bindingKey,
        'context_binding',
      );

      expect(
        () => catalog.resolveContract(
          EngineeringServiceContract<_Input, _Output>(
            contractKey: 'unknown',
            semanticVersion: '1.0.0',
            description: 'Unknown.',
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects unapproved bindings', () {
      expect(
        () => EngineeringServiceCapabilityCatalog(
          catalogVersion: '1.0.0',
          compositionFingerprint: 'composition:v1',
          bindings:
              <
                EngineeringServiceBinding<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_binding(approval: EngineeringServiceBindingApproval.rejected)],
        ),
        throwsArgumentError,
      );
    });

    test(
      'rejects duplicate binding provenance and duplicate contract binding',
      () {
        expect(
          () => EngineeringServiceCapabilityCatalog(
            catalogVersion: '1.0.0',
            compositionFingerprint: 'composition:v1',
            bindings:
                <
                  EngineeringServiceBinding<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[
                  _binding(bindingKey: 'one', bindingProvenance: 'same'),
                  _binding(bindingKey: 'two', bindingProvenance: 'same'),
                ],
          ),
          throwsArgumentError,
        );

        expect(
          () => EngineeringServiceCapabilityCatalog(
            catalogVersion: '1.0.0',
            compositionFingerprint: 'composition:v1',
            bindings:
                <
                  EngineeringServiceBinding<
                    EngineeringServiceInput,
                    EngineeringServiceOutput
                  >
                >[
                  _binding(bindingKey: 'one', bindingProvenance: 'one'),
                  _binding(bindingKey: 'two', bindingProvenance: 'two'),
                ],
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejects workflow when a step has no approved binding', () {
      expect(
        () => EngineeringServiceCapabilityCatalog(
          catalogVersion: '1.0.0',
          compositionFingerprint: 'composition:v1',
          bindings:
              <
                EngineeringServiceBinding<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_binding()],
          executableWorkflows: <EngineeringWorkflow>[
            _workflow(
              WorkflowStepDefinition<_Input, _Output>(
                stepKey: 'unknown',
                sequenceOrder: 1,
                title: 'Unknown',
                serviceContract: EngineeringServiceContract<_Input, _Output>(
                  contractKey: 'unknown_contract',
                  semanticVersion: '1.0.0',
                  description: 'Unknown.',
                ),
              ),
            ),
          ],
        ),
        throwsStateError,
      );
    });

    test('rejects empty catalog identity and empty bindings', () {
      expect(
        () => EngineeringServiceCapabilityCatalog(
          catalogVersion: ' ',
          compositionFingerprint: 'composition:v1',
          bindings:
              <
                EngineeringServiceBinding<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_binding()],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringServiceCapabilityCatalog(
          catalogVersion: '1.0.0',
          compositionFingerprint: ' ',
          bindings:
              <
                EngineeringServiceBinding<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[_binding()],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringServiceCapabilityCatalog(
          catalogVersion: '1.0.0',
          compositionFingerprint: 'composition:v1',
          bindings:
              const <
                EngineeringServiceBinding<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >[],
        ),
        throwsArgumentError,
      );
    });
  });
}

EngineeringServiceBinding<_Input, _Output> _binding({
  String bindingKey = 'context_binding',
  _Service? service,
  String bindingProvenance = 'platform:v1/context',
  EngineeringServiceBindingSource source =
      EngineeringServiceBindingSource.platform,
  EngineeringServiceBindingApproval approval =
      EngineeringServiceBindingApproval.approved,
}) {
  return EngineeringServiceBinding<_Input, _Output>(
    bindingKey: bindingKey,
    service: service ?? _Service(),
    bindingProvenance: bindingProvenance,
    source: source,
    approval: approval,
  );
}

WorkflowStepDefinition<_Input, _Output> _step() {
  return WorkflowStepDefinition<_Input, _Output>(
    stepKey: 'handle_context',
    sequenceOrder: 1,
    title: 'Handle context',
    serviceContract: _serviceContract(),
  );
}

EngineeringWorkflow _workflow(WorkflowStepDefinition<_Input, _Output> step) {
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
        >[step],
  );
}

EngineeringServiceContract<_Input, _Output> _serviceContract() {
  return EngineeringServiceContract<_Input, _Output>(
    contractKey: 'handle_context',
    semanticVersion: '1.0.0',
    description: 'Handle context.',
  );
}

final class _Service implements EngineeringService<_Input, _Output> {
  int executeCount = 0;

  @override
  EngineeringServiceContract<_Input, _Output> get contract =>
      _serviceContract();

  @override
  EngineeringServiceFailure? validatePreconditions(_Input input) => null;

  @override
  Future<EngineeringServiceResult<_Output>> execute(_Input input) async {
    executeCount++;

    return EngineeringServiceResult<_Output>.success(
      output: _Output('handled:${input.value}'),
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
