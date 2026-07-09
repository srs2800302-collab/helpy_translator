import '../../domain/entities/registry_engineering_operation.dart';
import '../../domain/value_objects/registry_engineering_operation_status.dart';

final class TransitionRegistryEngineeringOperationStatus {
  RegistryEngineeringOperation call({
    required RegistryEngineeringOperation operation,
    required RegistryEngineeringOperationStatus nextStatus,
  }) {
    if (!_isAllowedTransition(operation.status, nextStatus)) {
      throw ArgumentError(
        'Invalid registry engineering operation status transition: '
        '${operation.status.name} -> ${nextStatus.name}.',
      );
    }

    return RegistryEngineeringOperation(
      id: operation.id,
      status: nextStatus,
      problemStatement: operation.problemStatement,
    );
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
