import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('RegistryNodeId', () {
    test('normalizes and compares structural identities by value', () {
      final RegistryNodeId first = RegistryNodeId(' sample.registry.node-001 ');
      final RegistryNodeId second = RegistryNodeId('sample.registry.node-001');
      final RegistryNodeId different = RegistryNodeId(
        'sample.registry.node-002',
      );

      expect(first.value, 'sample.registry.node-001');
      expect(first, second);
      expect(first, isNot(different));
    });

    test('rejects an empty structural identity', () {
      expect(() => RegistryNodeId(''), throwsArgumentError);
      expect(() => RegistryNodeId('   '), throwsArgumentError);
    });
  });
}
