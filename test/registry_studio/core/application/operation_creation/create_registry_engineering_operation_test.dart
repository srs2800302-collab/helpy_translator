import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';

void main() {
  group('CreateRegistryEngineeringOperation', () {
    final CreateRegistryEngineeringOperation create =
        CreateRegistryEngineeringOperation();

    test('creates a registry engineering operation with provided identity', () {
      final RegistryEngineeringOperationId id = RegistryEngineeringOperationId(
        'registry-operation-001',
      );

      final RegistryEngineeringOperation operation = create(
        id: id,
        problemStatement: 'Check possible canonical wording drift.',
      );

      expect(operation.id, id);
      expect(operation.status, RegistryEngineeringOperationStatus.open);
      expect(
        operation.problemStatement,
        'Check possible canonical wording drift.',
      );
    });

    test('always creates operation with open initial status', () {
      final RegistryEngineeringOperation operation = create(
        id: RegistryEngineeringOperationId('registry-operation-001'),
        problemStatement: 'Prepare verified audit package.',
      );

      expect(operation.status, RegistryEngineeringOperationStatus.open);
    });

    test('uses domain invariant to normalize problem statement', () {
      final RegistryEngineeringOperation operation = create(
        id: RegistryEngineeringOperationId('registry-operation-001'),
        problemStatement: '  Check affected registry places.  ',
      );

      expect(operation.problemStatement, 'Check affected registry places.');
    });

    test('uses domain invariant to reject empty problem statement', () {
      expect(
        () => create(
          id: RegistryEngineeringOperationId('registry-operation-001'),
          problemStatement: '',
        ),
        throwsArgumentError,
      );

      expect(
        () => create(
          id: RegistryEngineeringOperationId('registry-operation-001'),
          problemStatement: '   ',
        ),
        throwsArgumentError,
      );
    });

    test(
      'does not require context, translator, assessment, repository or store',
      () {
        final RegistryEngineeringOperation operation = create(
          id: RegistryEngineeringOperationId('registry-operation-001'),
          problemStatement:
              'Open an operation from explicit engineering intent.',
        );

        expect(operation.status, RegistryEngineeringOperationStatus.open);
      },
    );
  });
}
