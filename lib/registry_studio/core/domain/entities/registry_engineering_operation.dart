import 'package:equatable/equatable.dart';

import '../value_objects/registry_engineering_operation_id.dart';
import '../value_objects/registry_engineering_operation_status.dart';

final class RegistryEngineeringOperation extends Equatable {
  factory RegistryEngineeringOperation({
    required RegistryEngineeringOperationId id,
    required RegistryEngineeringOperationStatus status,
    required String problemStatement,
  }) {
    final String normalizedProblemStatement = problemStatement.trim();

    if (normalizedProblemStatement.isEmpty) {
      throw ArgumentError.value(
        problemStatement,
        'problemStatement',
        'Registry engineering operation problem statement must not be empty.',
      );
    }

    return RegistryEngineeringOperation._(
      id: id,
      status: status,
      problemStatement: normalizedProblemStatement,
    );
  }

  const RegistryEngineeringOperation._({
    required this.id,
    required this.status,
    required this.problemStatement,
  });

  final RegistryEngineeringOperationId id;
  final RegistryEngineeringOperationStatus status;
  final String problemStatement;

  @override
  List<Object?> get props => <Object?>[id];
}
