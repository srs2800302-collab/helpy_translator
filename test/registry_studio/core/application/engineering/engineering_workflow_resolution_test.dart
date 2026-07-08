import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_workflow_resolution.dart';

void main() {
  group('EngineeringWorkflowResolutionOutcome', () {
    test('exposes contract labels', () {
      expect(
        EngineeringWorkflowResolutionOutcome.resolved.contractLabel,
        'RESOLVED',
      );
      expect(
        EngineeringWorkflowResolutionOutcome.ambiguous.contractLabel,
        'AMBIGUOUS',
      );
      expect(
        EngineeringWorkflowResolutionOutcome.unsupported.contractLabel,
        'UNSUPPORTED',
      );
      expect(
        EngineeringWorkflowResolutionOutcome.blocked.contractLabel,
        'BLOCKED',
      );
      expect(
        EngineeringWorkflowResolutionOutcome.failed.contractLabel,
        'FAILED',
      );
    });
  });

  group('EngineeringWorkflowResolution', () {
    test('creates resolved result with one selected workflow', () {
      final EngineeringWorkflowResolution resolution =
          EngineeringWorkflowResolution.resolved(
            selectedWorkflowKey: ' review_intake ',
            explanation: ' Selected intake review workflow. ',
          );

      expect(resolution.outcome, EngineeringWorkflowResolutionOutcome.resolved);
      expect(resolution.selectedWorkflowKey, 'review_intake');
      expect(resolution.candidateWorkflowKeys, isEmpty);
      expect(resolution.explanation, 'Selected intake review workflow.');
      expect(resolution.isResolved, isTrue);
      expect(resolution.requiresEngineerDecision, isFalse);
    });

    test('creates ambiguous result with multiple candidates', () {
      final EngineeringWorkflowResolution resolution =
          EngineeringWorkflowResolution.ambiguous(
            candidateWorkflowKeys: <String>[
              ' review_intake ',
              ' review_runtime_contract ',
            ],
            explanation: ' Multiple workflows match. ',
          );

      expect(
        resolution.outcome,
        EngineeringWorkflowResolutionOutcome.ambiguous,
      );
      expect(resolution.selectedWorkflowKey, isNull);
      expect(resolution.candidateWorkflowKeys, <String>[
        'review_intake',
        'review_runtime_contract',
      ]);
      expect(resolution.explanation, 'Multiple workflows match.');
      expect(resolution.isResolved, isFalse);
      expect(resolution.requiresEngineerDecision, isTrue);
    });

    test('creates unsupported, blocked and failed terminal results', () {
      final EngineeringWorkflowResolution unsupported =
          EngineeringWorkflowResolution.unsupported(
            explanation: 'No workflow supports this intent.',
          );
      final EngineeringWorkflowResolution blocked =
          EngineeringWorkflowResolution.blocked(
            explanation: 'Missing verified context.',
          );
      final EngineeringWorkflowResolution failed =
          EngineeringWorkflowResolution.failed(explanation: 'Resolver failed.');

      expect(
        unsupported.outcome,
        EngineeringWorkflowResolutionOutcome.unsupported,
      );
      expect(blocked.outcome, EngineeringWorkflowResolutionOutcome.blocked);
      expect(failed.outcome, EngineeringWorkflowResolutionOutcome.failed);

      expect(unsupported.selectedWorkflowKey, isNull);
      expect(blocked.selectedWorkflowKey, isNull);
      expect(failed.selectedWorkflowKey, isNull);

      expect(unsupported.candidateWorkflowKeys, isEmpty);
      expect(blocked.candidateWorkflowKeys, isEmpty);
      expect(failed.candidateWorkflowKeys, isEmpty);

      expect(unsupported.requiresEngineerDecision, isFalse);
      expect(blocked.requiresEngineerDecision, isTrue);
      expect(failed.requiresEngineerDecision, isFalse);
    });

    test('keeps candidate workflow keys immutable', () {
      final EngineeringWorkflowResolution resolution =
          EngineeringWorkflowResolution.ambiguous(
            candidateWorkflowKeys: <String>['one', 'two'],
            explanation: 'Ambiguous.',
          );

      expect(
        () => resolution.candidateWorkflowKeys.add('three'),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid resolved result', () {
      expect(
        () => EngineeringWorkflowResolution.resolved(
          selectedWorkflowKey: ' ',
          explanation: 'Selected.',
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflowResolution.resolved(
          selectedWorkflowKey: 'review_intake',
          explanation: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid ambiguous result', () {
      expect(
        () => EngineeringWorkflowResolution.ambiguous(
          candidateWorkflowKeys: <String>['one'],
          explanation: 'Ambiguous.',
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflowResolution.ambiguous(
          candidateWorkflowKeys: <String>['one', ' '],
          explanation: 'Ambiguous.',
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringWorkflowResolution.ambiguous(
          candidateWorkflowKeys: <String>['one', 'one'],
          explanation: 'Ambiguous.',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty terminal explanations', () {
      expect(
        () => EngineeringWorkflowResolution.unsupported(explanation: ' '),
        throwsArgumentError,
      );
      expect(
        () => EngineeringWorkflowResolution.blocked(explanation: ' '),
        throwsArgumentError,
      );
      expect(
        () => EngineeringWorkflowResolution.failed(explanation: ' '),
        throwsArgumentError,
      );
    });
  });
}
