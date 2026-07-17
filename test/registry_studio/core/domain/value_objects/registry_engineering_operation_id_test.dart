import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';

void main() {
  group('RegistryEngineeringOperationId', () {
    test('trims boundary whitespace and preserves operation identity', () {
      final RegistryEngineeringOperationId id = RegistryEngineeringOperationId(
        ' registry-operation-001 ',
      );

      expect(id.value, 'registry-operation-001');
    });

    test('rejects empty and whitespace-only operation identities', () {
      expect(() => RegistryEngineeringOperationId(''), throwsArgumentError);
      expect(() => RegistryEngineeringOperationId('   '), throwsArgumentError);
    });

    test('uses the normalized value for equality and hash code', () {
      final RegistryEngineeringOperationId first =
          RegistryEngineeringOperationId(' registry-operation-001 ');
      final RegistryEngineeringOperationId second =
          RegistryEngineeringOperationId('registry-operation-001');
      final RegistryEngineeringOperationId different =
          RegistryEngineeringOperationId('registry-operation-002');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });
  });
}
