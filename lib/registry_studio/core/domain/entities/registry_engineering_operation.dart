import 'package:equatable/equatable.dart';

import '../value_objects/registry_engineering_operation_id.dart';
import '../value_objects/registry_engineering_operation_status.dart';

final class RegistryEngineeringOperation extends Equatable {
  factory RegistryEngineeringOperation({
    required RegistryEngineeringOperationId id,
    required RegistryEngineeringOperationStatus status,
    required String problemStatement,
    String? decisionStatement,
  }) {
    final String normalizedProblemStatement = problemStatement.trim();
    final String normalizedDecisionValue = decisionStatement?.trim() ?? '';
    final String? normalizedDecisionStatement = normalizedDecisionValue.isEmpty
        ? null
        : normalizedDecisionValue;

    if (normalizedProblemStatement.isEmpty) {
      throw ArgumentError.value(
        problemStatement,
        'problemStatement',
        'Registry engineering operation problem statement must not be empty.',
      );
    }

    if (status == RegistryEngineeringOperationStatus.decided &&
        normalizedDecisionStatement == null) {
      throw ArgumentError.value(
        decisionStatement,
        'decisionStatement',
        'Decided registry engineering operation must contain a decision statement.',
      );
    }

    if (status != RegistryEngineeringOperationStatus.decided &&
        normalizedDecisionStatement != null) {
      throw ArgumentError.value(
        decisionStatement,
        'decisionStatement',
        'Registry engineering operation decision statement is only allowed for decided status.',
      );
    }

    return RegistryEngineeringOperation._(
      id: id,
      status: status,
      problemStatement: normalizedProblemStatement,
      decisionStatement: normalizedDecisionStatement,
    );
  }

  const RegistryEngineeringOperation._({
    required this.id,
    required this.status,
    required this.problemStatement,
    required this.decisionStatement,
  });

  final RegistryEngineeringOperationId id;
  final RegistryEngineeringOperationStatus status;
  final String problemStatement;
  final String? decisionStatement;

  @override
  List<Object?> get props => <Object?>[id];
}
