import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';

void main() {
  group('RegistryEngineeringOperationId', () {
    test('normalizes and preserves stable operation identity', () {
      final RegistryEngineeringOperationId id = RegistryEngineeringOperationId(
        ' registry-operation-001 ',
      );

      expect(id.value, 'registry-operation-001');
    });

    test('rejects empty operation identity', () {
      expect(() => RegistryEngineeringOperationId(''), throwsArgumentError);
      expect(() => RegistryEngineeringOperationId('   '), throwsArgumentError);
    });
  });

  group('RegistryEngineeringOperation', () {
    test('creates a minimal lifecycle entity for an engineering operation', () {
      final RegistryEngineeringOperationId id = RegistryEngineeringOperationId(
        'registry-operation-001',
      );

      final RegistryEngineeringOperation operation =
          RegistryEngineeringOperation(
            id: id,
            status: RegistryEngineeringOperationStatus.open,
            problemStatement: ' Check possible canonical wording drift. ',
          );

      expect(operation.id, id);
      expect(operation.status, RegistryEngineeringOperationStatus.open);
      expect(
        operation.problemStatement,
        'Check possible canonical wording drift.',
      );
    });

    test('rejects empty problem statement', () {
      expect(
        () => RegistryEngineeringOperation(
          id: RegistryEngineeringOperationId('registry-operation-001'),
          status: RegistryEngineeringOperationStatus.open,
          problemStatement: '',
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistryEngineeringOperation(
          id: RegistryEngineeringOperationId('registry-operation-001'),
          status: RegistryEngineeringOperationStatus.open,
          problemStatement: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('uses stable immutable identity for operation equality', () {
      final RegistryEngineeringOperationId id = RegistryEngineeringOperationId(
        'registry-operation-001',
      );

      final RegistryEngineeringOperation first = RegistryEngineeringOperation(
        id: id,
        status: RegistryEngineeringOperationStatus.open,
        problemStatement: 'Check wording drift.',
      );
      final RegistryEngineeringOperation second = RegistryEngineeringOperation(
        id: id,
        status: RegistryEngineeringOperationStatus.readyForDecision,
        problemStatement: 'Another wording problem.',
      );

      expect(first, second);
      expect(first.status, isNot(second.status));
      expect(first.problemStatement, isNot(second.problemStatement));
    });

    test('does not require primary entity or related context', () {
      final RegistryEngineeringOperation operation =
          RegistryEngineeringOperation(
            id: RegistryEngineeringOperationId('registry-operation-001'),
            status: RegistryEngineeringOperationStatus.awaitingContext,
            problemStatement: 'Find affected registry places.',
          );

      expect(
        operation.status,
        RegistryEngineeringOperationStatus.awaitingContext,
      );
      expect(operation.problemStatement, 'Find affected registry places.');
    });
    test('normalizes decision statement for decided operation', () {
      final RegistryEngineeringOperation operation =
          RegistryEngineeringOperation(
            id: RegistryEngineeringOperationId('registry-operation-001'),
            status: RegistryEngineeringOperationStatus.decided,
            problemStatement: 'Check wording drift.',
            decisionStatement: '  Approve canonical wording.  ',
          );

      expect(operation.decisionStatement, 'Approve canonical wording.');
    });

    test('requires decision statement for decided status', () {
      expect(
        () => RegistryEngineeringOperation(
          id: RegistryEngineeringOperationId('registry-operation-001'),
          status: RegistryEngineeringOperationStatus.decided,
          problemStatement: 'Check wording drift.',
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistryEngineeringOperation(
          id: RegistryEngineeringOperationId('registry-operation-001'),
          status: RegistryEngineeringOperationStatus.decided,
          problemStatement: 'Check wording drift.',
          decisionStatement: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects decision statement before decided status', () {
      expect(
        () => RegistryEngineeringOperation(
          id: RegistryEngineeringOperationId('registry-operation-001'),
          status: RegistryEngineeringOperationStatus.readyForDecision,
          problemStatement: 'Check wording drift.',
          decisionStatement: 'Approve canonical wording.',
        ),
        throwsArgumentError,
      );
    });
  });
}
