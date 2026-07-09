import '../../domain/entities/registry_engineering_operation.dart';
import '../../domain/value_objects/registry_engineering_operation_id.dart';
import '../../domain/value_objects/registry_engineering_operation_status.dart';

final class CreateRegistryEngineeringOperation {
  RegistryEngineeringOperation call({
    required RegistryEngineeringOperationId id,
    required String problemStatement,
  }) {
    return RegistryEngineeringOperation(
      id: id,
      status: RegistryEngineeringOperationStatus.open,
      problemStatement: problemStatement,
    );
  }
}
