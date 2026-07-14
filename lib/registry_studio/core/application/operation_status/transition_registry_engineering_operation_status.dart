import '../../domain/entities/registry_engineering_operation.dart';
import '../../domain/entities/registry_engineering_operation_revision.dart';
import '../../domain/value_objects/registry_engineering_operation_status.dart';

final class TransitionRegistryEngineeringOperationStatus {
  RegistryEngineeringOperation call({
    required RegistryEngineeringOperation operation,
    required RegistryEngineeringOperationStatus nextStatus,
    Iterable<RegistryEngineeringOperationRevision> revisions =
        const <RegistryEngineeringOperationRevision>[],
    String? decisionStatement,
  }) {
    if (!_isAllowedTransition(operation.status, nextStatus)) {
      throw ArgumentError(
        'Invalid registry engineering operation status transition: '
        '${operation.status.name} -> ${nextStatus.name}.',
      );
    }

    if (_requiresRevisionSet(nextStatus)) {
      final List<RegistryEngineeringOperationRevision> revisionSet = revisions
          .toList(growable: false);

      if (revisionSet.isEmpty) {
        throw ArgumentError(
          'Registry engineering operation transition to '
          '${nextStatus.name} requires at least one revision.',
        );
      }

      if (revisionSet.any(
        (RegistryEngineeringOperationRevision revision) =>
            revision.operationId != operation.id,
      )) {
        throw ArgumentError(
          'Registry engineering operation revisions must belong to '
          'the current operation.',
        );
      }
    }

    return RegistryEngineeringOperation(
      id: operation.id,
      status: nextStatus,
      problemStatement: operation.problemStatement,
      decisionStatement: decisionStatement,
    );
  }

  bool _requiresRevisionSet(RegistryEngineeringOperationStatus nextStatus) {
    return nextStatus == RegistryEngineeringOperationStatus.readyForDecision ||
        nextStatus == RegistryEngineeringOperationStatus.decided;
  }

  bool _isAllowedTransition(
    RegistryEngineeringOperationStatus currentStatus,
    RegistryEngineeringOperationStatus nextStatus,
  ) {
    return switch (currentStatus) {
      RegistryEngineeringOperationStatus.open =>
        nextStatus == RegistryEngineeringOperationStatus.awaitingContext ||
            nextStatus == RegistryEngineeringOperationStatus.readyForDecision ||
            nextStatus == RegistryEngineeringOperationStatus.cancelled,
      RegistryEngineeringOperationStatus.awaitingContext =>
        nextStatus == RegistryEngineeringOperationStatus.readyForDecision ||
            nextStatus == RegistryEngineeringOperationStatus.cancelled,
      RegistryEngineeringOperationStatus.readyForDecision =>
        nextStatus == RegistryEngineeringOperationStatus.awaitingContext ||
            nextStatus == RegistryEngineeringOperationStatus.decided ||
            nextStatus == RegistryEngineeringOperationStatus.cancelled,
      RegistryEngineeringOperationStatus.decided => false,
      RegistryEngineeringOperationStatus.cancelled => false,
    };
  }
}
