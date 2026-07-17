import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

void main() {
  group('RegistrySemanticContractIdentity', () {
    test('normalizes and preserves contract identity components', () {
      final RegistrySemanticContractIdentity identity =
          RegistrySemanticContractIdentity(
            contractId: ' registry.node ',
            version: ' 2 ',
          );

      expect(identity.contractId, 'registry.node');
      expect(identity.version, '2');
    });

    test('rejects an empty contract identifier', () {
      expect(
        () => RegistrySemanticContractIdentity(contractId: '', version: '1'),
        throwsArgumentError,
      );
      expect(
        () => RegistrySemanticContractIdentity(contractId: '   ', version: '1'),
        throwsArgumentError,
      );
    });

    test('rejects an empty contract version', () {
      expect(
        () => RegistrySemanticContractIdentity(
          contractId: 'registry.node',
          version: '',
        ),
        throwsArgumentError,
      );
      expect(
        () => RegistrySemanticContractIdentity(
          contractId: 'registry.node',
          version: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('uses both normalized components for equality', () {
      final RegistrySemanticContractIdentity first =
          RegistrySemanticContractIdentity(
            contractId: ' registry.node ',
            version: ' 2 ',
          );
      final RegistrySemanticContractIdentity second =
          RegistrySemanticContractIdentity(
            contractId: 'registry.node',
            version: '2',
          );
      final RegistrySemanticContractIdentity differentVersion =
          RegistrySemanticContractIdentity(
            contractId: 'registry.node',
            version: '3',
          );
      final RegistrySemanticContractIdentity differentCase =
          RegistrySemanticContractIdentity(
            contractId: 'Registry.node',
            version: '2',
          );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(differentVersion));
      expect(first, isNot(differentCase));
    });
  });
}
