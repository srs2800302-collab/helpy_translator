import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';

void main() {
  group('TransitionRegistryEngineeringOperationStatus', () {
    final TransitionRegistryEngineeringOperationStatus transition =
        TransitionRegistryEngineeringOperationStatus();

    test(
      'returns a new immutable operation snapshot for allowed transition',
      () {
        final RegistryEngineeringOperation original = _operationWith(
          RegistryEngineeringOperationStatus.open,
        );

        final RegistryEngineeringOperation transitioned = transition(
          operation: original,
          nextStatus: RegistryEngineeringOperationStatus.awaitingContext,
        );

        expect(original.status, RegistryEngineeringOperationStatus.open);
        expect(
          transitioned.status,
          RegistryEngineeringOperationStatus.awaitingContext,
        );
        expect(transitioned.id, original.id);
        expect(transitioned.problemStatement, original.problemStatement);
        expect(identical(transitioned, original), isFalse);
      },
    );

    test('allows approved non-terminal transitions', () {
      final List<_StatusTransition> allowedTransitions = <_StatusTransition>[
        _StatusTransition(
          RegistryEngineeringOperationStatus.open,
          RegistryEngineeringOperationStatus.awaitingContext,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.open,
          RegistryEngineeringOperationStatus.readyForDecision,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.open,
          RegistryEngineeringOperationStatus.cancelled,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.awaitingContext,
          RegistryEngineeringOperationStatus.readyForDecision,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.awaitingContext,
          RegistryEngineeringOperationStatus.cancelled,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.readyForDecision,
          RegistryEngineeringOperationStatus.awaitingContext,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.readyForDecision,
          RegistryEngineeringOperationStatus.decided,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.readyForDecision,
          RegistryEngineeringOperationStatus.cancelled,
        ),
      ];

      for (final _StatusTransition allowedTransition in allowedTransitions) {
        final RegistryEngineeringOperation operation = _operationWith(
          allowedTransition.currentStatus,
        );
        final bool requiresRevisionSet =
            allowedTransition.nextStatus ==
                RegistryEngineeringOperationStatus.readyForDecision ||
            allowedTransition.nextStatus ==
                RegistryEngineeringOperationStatus.decided;

        final RegistryEngineeringOperation transitioned = transition(
          operation: operation,
          nextStatus: allowedTransition.nextStatus,
          revisions: requiresRevisionSet
              ? <RegistryEngineeringOperationRevision>[_revisionFor(operation)]
              : const <RegistryEngineeringOperationRevision>[],
          decisionStatement:
              allowedTransition.nextStatus ==
                  RegistryEngineeringOperationStatus.decided
              ? 'Approve canonical wording.'
              : null,
        );

        expect(transitioned.status, allowedTransition.nextStatus);
      }
    });

    test('rejects open to decided because readiness must be explicit', () {
      expect(
        () => transition(
          operation: _operationWith(RegistryEngineeringOperationStatus.open),
          nextStatus: RegistryEngineeringOperationStatus.decided,
        ),
        throwsArgumentError,
      );
    });

    test('rejects terminal status outgoing transitions', () {
      for (final RegistryEngineeringOperationStatus terminalStatus
          in <RegistryEngineeringOperationStatus>[
            RegistryEngineeringOperationStatus.decided,
            RegistryEngineeringOperationStatus.cancelled,
          ]) {
        for (final RegistryEngineeringOperationStatus nextStatus
            in RegistryEngineeringOperationStatus.values) {
          expect(
            () => transition(
              operation: _operationWith(terminalStatus),
              nextStatus: nextStatus,
            ),
            throwsArgumentError,
          );
        }
      }
    });

    test('rejects non-approved reverse and same-status transitions', () {
      final List<_StatusTransition> forbiddenTransitions = <_StatusTransition>[
        _StatusTransition(
          RegistryEngineeringOperationStatus.awaitingContext,
          RegistryEngineeringOperationStatus.open,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.readyForDecision,
          RegistryEngineeringOperationStatus.open,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.open,
          RegistryEngineeringOperationStatus.open,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.awaitingContext,
          RegistryEngineeringOperationStatus.awaitingContext,
        ),
        _StatusTransition(
          RegistryEngineeringOperationStatus.readyForDecision,
          RegistryEngineeringOperationStatus.readyForDecision,
        ),
      ];

      for (final _StatusTransition forbiddenTransition
          in forbiddenTransitions) {
        expect(
          () => transition(
            operation: _operationWith(forbiddenTransition.currentStatus),
            nextStatus: forbiddenTransition.nextStatus,
          ),
          throwsArgumentError,
        );
      }
    });

    test('requires a current operation revision before readiness', () {
      final RegistryEngineeringOperation operation = _operationWith(
        RegistryEngineeringOperationStatus.open,
      );

      expect(
        () => transition(
          operation: operation,
          nextStatus: RegistryEngineeringOperationStatus.readyForDecision,
        ),
        throwsArgumentError,
      );

      final RegistryEngineeringOperation transitioned = transition(
        operation: operation,
        nextStatus: RegistryEngineeringOperationStatus.readyForDecision,
        revisions: <RegistryEngineeringOperationRevision>[
          _revisionFor(operation),
        ],
      );

      expect(
        transitioned.status,
        RegistryEngineeringOperationStatus.readyForDecision,
      );
    });

    test('rejects revisions owned by another operation', () {
      final RegistryEngineeringOperation operation = _operationWith(
        RegistryEngineeringOperationStatus.open,
      );
      final RegistryEngineeringOperation otherOperation =
          RegistryEngineeringOperation(
            id: RegistryEngineeringOperationId('registry-operation-002'),
            status: RegistryEngineeringOperationStatus.open,
            problemStatement: 'Other operation.',
          );

      expect(
        () => transition(
          operation: operation,
          nextStatus: RegistryEngineeringOperationStatus.readyForDecision,
          revisions: <RegistryEngineeringOperationRevision>[
            _revisionFor(otherOperation),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('requires engineer decision for decided transition', () {
      final RegistryEngineeringOperation ready = _operationWith(
        RegistryEngineeringOperationStatus.readyForDecision,
      );

      expect(
        () => transition(
          operation: ready,
          nextStatus: RegistryEngineeringOperationStatus.decided,
          revisions: <RegistryEngineeringOperationRevision>[
            _revisionFor(ready),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => transition(
          operation: ready,
          nextStatus: RegistryEngineeringOperationStatus.decided,
          revisions: <RegistryEngineeringOperationRevision>[
            _revisionFor(ready),
          ],
          decisionStatement: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('stores normalized engineer decision', () {
      final RegistryEngineeringOperation operation = _operationWith(
        RegistryEngineeringOperationStatus.readyForDecision,
      );
      final RegistryEngineeringOperation transitioned = transition(
        operation: operation,
        nextStatus: RegistryEngineeringOperationStatus.decided,
        revisions: <RegistryEngineeringOperationRevision>[
          _revisionFor(operation),
        ],
        decisionStatement: '  Approve canonical wording.  ',
      );

      expect(transitioned.status, RegistryEngineeringOperationStatus.decided);
      expect(transitioned.decisionStatement, 'Approve canonical wording.');
    });
  });
}

RegistryEngineeringOperation _operationWith(
  RegistryEngineeringOperationStatus status,
) {
  return RegistryEngineeringOperation(
    id: RegistryEngineeringOperationId('registry-operation-001'),
    status: status,
    problemStatement: 'Check possible canonical wording drift.',
    decisionStatement: status == RegistryEngineeringOperationStatus.decided
        ? 'Approved canonical wording.'
        : null,
  );
}

RegistryEngineeringOperationRevision _revisionFor(
  RegistryEngineeringOperation operation,
) {
  return RegistryEngineeringOperationRevision(
    id: '${operation.id.value}-revision-1',
    operationId: operation.id,
    revisionNumber: 1,
    workingContent: 'Approved working content.',
    previousRevisionId: null,
    primaryEntityId: RegistryEntityId('primary'),
    relatedEntityIds: const <RegistryEntityId>[],
  );
}

final class _StatusTransition {
  const _StatusTransition(this.currentStatus, this.nextStatus);

  final RegistryEngineeringOperationStatus currentStatus;
  final RegistryEngineeringOperationStatus nextStatus;
}
