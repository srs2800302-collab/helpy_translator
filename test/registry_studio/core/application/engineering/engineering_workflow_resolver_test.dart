import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineer_intent.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_context.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_resolution.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_resolver.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/workflow_step_definition.dart';
import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_adapter_contract_identity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('EngineeringWorkflowEligibilityOutcome', () {
    test('exposes contract labels', () {
      expect(
        EngineeringWorkflowEligibilityOutcome.eligible.contractLabel,
        'ELIGIBLE',
      );
      expect(
        EngineeringWorkflowEligibilityOutcome.unsupported.contractLabel,
        'UNSUPPORTED',
      );
      expect(
        EngineeringWorkflowEligibilityOutcome.blocked.contractLabel,
        'BLOCKED',
      );
      expect(
        EngineeringWorkflowEligibilityOutcome.failed.contractLabel,
        'FAILED',
      );
    });
  });

  group('EngineeringWorkflowEligibility', () {
    test('creates typed eligibility values', () {
      expect(
        EngineeringWorkflowEligibility.eligible(
          explanation: ' ok ',
        ).explanation,
        'ok',
      );
      expect(
        EngineeringWorkflowEligibility.unsupported(
          explanation: ' no ',
        ).isUnsupported,
        isTrue,
      );
      expect(
        EngineeringWorkflowEligibility.blocked(explanation: ' wait ').isBlocked,
        isTrue,
      );
      expect(
        EngineeringWorkflowEligibility.failed(explanation: ' error ').isFailed,
        isTrue,
      );
    });

    test('rejects empty explanation', () {
      expect(
        () => EngineeringWorkflowEligibility.eligible(explanation: ' '),
        throwsArgumentError,
      );
    });
  });

  group('EngineeringWorkflowResolver', () {
    test('resolves exactly one eligible approved workflow', () {
      final EngineeringWorkflowResolver resolver = EngineeringWorkflowResolver(
        eligibilityEvaluator:
            _MapEligibilityEvaluator(<String, EngineeringWorkflowEligibility>{
              'review_intake': EngineeringWorkflowEligibility.eligible(
                explanation: 'Matches intent.',
              ),
              'rename_entity': EngineeringWorkflowEligibility.unsupported(
                explanation: 'Different objective.',
              ),
            }),
      );

      final EngineeringWorkflowResolution resolution = resolver.resolve(
        intent: _intent(),
        context: _context(),
        approvedWorkflows: <EngineeringWorkflow>[
          _workflow('rename_entity'),
          _workflow('review_intake'),
        ],
      );

      expect(resolution.outcome, EngineeringWorkflowResolutionOutcome.resolved);
      expect(resolution.selectedWorkflowKey, 'review_intake');
      expect(resolution.candidateWorkflowKeys, isEmpty);
      expect(resolution.isResolved, isTrue);
    });

    test('returns ambiguous when several workflows are eligible', () {
      final EngineeringWorkflowResolver resolver = EngineeringWorkflowResolver(
        eligibilityEvaluator:
            _MapEligibilityEvaluator(<String, EngineeringWorkflowEligibility>{
              'b_workflow': EngineeringWorkflowEligibility.eligible(
                explanation: 'Matches.',
              ),
              'a_workflow': EngineeringWorkflowEligibility.eligible(
                explanation: 'Also matches.',
              ),
            }),
      );

      final EngineeringWorkflowResolution resolution = resolver.resolve(
        intent: _intent(),
        context: _context(),
        approvedWorkflows: <EngineeringWorkflow>[
          _workflow('b_workflow'),
          _workflow('a_workflow'),
        ],
      );

      expect(
        resolution.outcome,
        EngineeringWorkflowResolutionOutcome.ambiguous,
      );
      expect(resolution.candidateWorkflowKeys, <String>[
        'a_workflow',
        'b_workflow',
      ]);
      expect(resolution.requiresEngineerDecision, isTrue);
    });

    test(
      'returns blocked when no workflow is eligible and at least one is blocked',
      () {
        final EngineeringWorkflowResolver resolver =
            EngineeringWorkflowResolver(
              eligibilityEvaluator: _MapEligibilityEvaluator(
                <String, EngineeringWorkflowEligibility>{
                  'review_intake': EngineeringWorkflowEligibility.blocked(
                    explanation: 'Target context is incomplete.',
                  ),
                  'rename_entity': EngineeringWorkflowEligibility.unsupported(
                    explanation: 'Different objective.',
                  ),
                },
              ),
            );

        final EngineeringWorkflowResolution resolution = resolver.resolve(
          intent: _intent(),
          context: _context(),
          approvedWorkflows: <EngineeringWorkflow>[
            _workflow('review_intake'),
            _workflow('rename_entity'),
          ],
        );

        expect(
          resolution.outcome,
          EngineeringWorkflowResolutionOutcome.blocked,
        );
        expect(resolution.selectedWorkflowKey, isNull);
        expect(resolution.requiresEngineerDecision, isTrue);
        expect(resolution.explanation, contains('review_intake'));
      },
    );

    test('returns unsupported when no approved workflow supports intent', () {
      final EngineeringWorkflowResolver resolver = EngineeringWorkflowResolver(
        eligibilityEvaluator:
            _MapEligibilityEvaluator(<String, EngineeringWorkflowEligibility>{
              'review_intake': EngineeringWorkflowEligibility.unsupported(
                explanation: 'Different objective.',
              ),
            }),
      );

      final EngineeringWorkflowResolution resolution = resolver.resolve(
        intent: _intent(),
        context: _context(),
        approvedWorkflows: <EngineeringWorkflow>[_workflow('review_intake')],
      );

      expect(
        resolution.outcome,
        EngineeringWorkflowResolutionOutcome.unsupported,
      );
      expect(resolution.selectedWorkflowKey, isNull);
      expect(resolution.candidateWorkflowKeys, isEmpty);
      expect(resolution.explanation, contains('review_intake'));
    });

    test('returns unsupported when approved workflow list is empty', () {
      final EngineeringWorkflowResolver resolver = EngineeringWorkflowResolver(
        eligibilityEvaluator: _MapEligibilityEvaluator(
          const <String, EngineeringWorkflowEligibility>{},
        ),
      );

      final EngineeringWorkflowResolution resolution = resolver.resolve(
        intent: _intent(),
        context: _context(),
        approvedWorkflows: const <EngineeringWorkflow>[],
      );

      expect(
        resolution.outcome,
        EngineeringWorkflowResolutionOutcome.unsupported,
      );
    });

    test('returns failed for duplicate approved workflow keys', () {
      final EngineeringWorkflowResolver resolver = EngineeringWorkflowResolver(
        eligibilityEvaluator: _MapEligibilityEvaluator(
          const <String, EngineeringWorkflowEligibility>{},
        ),
      );

      final EngineeringWorkflowResolution resolution = resolver.resolve(
        intent: _intent(),
        context: _context(),
        approvedWorkflows: <EngineeringWorkflow>[
          _workflow('review_intake'),
          _workflow('review_intake'),
        ],
      );

      expect(resolution.outcome, EngineeringWorkflowResolutionOutcome.failed);
      expect(resolution.explanation, contains('duplicate workflow key'));
    });

    test('returns failed when evaluator returns failed eligibility', () {
      final EngineeringWorkflowResolver resolver = EngineeringWorkflowResolver(
        eligibilityEvaluator:
            _MapEligibilityEvaluator(<String, EngineeringWorkflowEligibility>{
              'review_intake': EngineeringWorkflowEligibility.failed(
                explanation: 'Evaluator failed.',
              ),
            }),
      );

      final EngineeringWorkflowResolution resolution = resolver.resolve(
        intent: _intent(),
        context: _context(),
        approvedWorkflows: <EngineeringWorkflow>[_workflow('review_intake')],
      );

      expect(resolution.outcome, EngineeringWorkflowResolutionOutcome.failed);
      expect(resolution.explanation, contains('Evaluator failed.'));
    });

    test('returns failed when evaluator throws', () {
      final EngineeringWorkflowResolver resolver = EngineeringWorkflowResolver(
        eligibilityEvaluator: _ThrowingEligibilityEvaluator(),
      );

      final EngineeringWorkflowResolution resolution = resolver.resolve(
        intent: _intent(),
        context: _context(),
        approvedWorkflows: <EngineeringWorkflow>[_workflow('review_intake')],
      );

      expect(resolution.outcome, EngineeringWorkflowResolutionOutcome.failed);
      expect(resolution.explanation, contains('review_intake'));
    });
  });
}

EngineerIntent _intent() {
  return EngineerIntent(
    objective: 'Review intake context',
    scope: <String>['scenario'],
    constraints: <String>['read-only'],
  );
}

EngineeringContext _context() {
  final RegistryAdapterContractIdentity adapter =
      RegistryAdapterContractIdentity(
        adapterId: 'sample_adapter',
        semanticContractVersion: '1',
      );

  final RegistryEntity entity = RegistryEntity(
    id: RegistryEntityId('registry-entity-001'),
    path: RegistryPath(<String>['sample_adapter', 'sample_domain', 'sample_entity']),
    kind: RegistryEntityKind(
      adapterContract: adapter,
      kindId: 'sample.entity',
      schemaVersion: '1',
    ),
    payload: _TestPayload(
      adapterContract: adapter,
      entityKindId: 'sample.entity',
      payloadSchemaVersion: '1',
    ),
  );

  return EngineeringContext(targetEntity: entity);
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

final class _MapEligibilityEvaluator
    implements EngineeringWorkflowEligibilityEvaluator {
  const _MapEligibilityEvaluator(this._eligibilityByWorkflowKey);

  final Map<String, EngineeringWorkflowEligibility> _eligibilityByWorkflowKey;

  @override
  EngineeringWorkflowEligibility evaluate({
    required EngineerIntent intent,
    required EngineeringContext context,
    required EngineeringWorkflow workflow,
  }) {
    expect(intent.objective, 'Review intake context');
    expect(context.targetEntity.path.segments, <String>[
      'sample_adapter',
      'sample_domain',
      'sample_entity',
    ]);

    return _eligibilityByWorkflowKey[workflow.workflowKey] ??
        EngineeringWorkflowEligibility.unsupported(
          explanation: 'No eligibility rule.',
        );
  }
}

final class _ThrowingEligibilityEvaluator
    implements EngineeringWorkflowEligibilityEvaluator {
  @override
  EngineeringWorkflowEligibility evaluate({
    required EngineerIntent intent,
    required EngineeringContext context,
    required EngineeringWorkflow workflow,
  }) {
    throw StateError('boom');
  }
}

final class _TestPayload implements RegistryEntityPayload {
  const _TestPayload({
    required this.adapterContract,
    required this.entityKindId,
    required this.payloadSchemaVersion,
  });

  @override
  final RegistryAdapterContractIdentity adapterContract;

  @override
  final String entityKindId;

  @override
  final String payloadSchemaVersion;
}

final class _Input implements EngineeringServiceInput {
  const _Input();
}

final class _Output implements EngineeringServiceOutput {
  const _Output();
}
