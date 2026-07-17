import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';

void main() {
  group('RegistryEntityId', () {
    test('trims boundary whitespace and preserves the identity value', () {
      final RegistryEntityId entityId = RegistryEntityId(
        '  helpy.service_intake.plumbing.faucet  ',
      );

      expect(entityId.value, 'helpy.service_intake.plumbing.faucet');
    });

    test('rejects empty and whitespace-only values', () {
      expect(() => RegistryEntityId(''), throwsArgumentError);
      expect(() => RegistryEntityId('   '), throwsArgumentError);
    });

    test('uses the normalized value for equality and hash code', () {
      final RegistryEntityId first = RegistryEntityId(
        ' helpy.service_intake.plumbing.faucet ',
      );
      final RegistryEntityId second = RegistryEntityId(
        'helpy.service_intake.plumbing.faucet',
      );
      final RegistryEntityId differentCase = RegistryEntityId(
        'Helpy.service_intake.plumbing.faucet',
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(differentCase));
    });
  });
}
