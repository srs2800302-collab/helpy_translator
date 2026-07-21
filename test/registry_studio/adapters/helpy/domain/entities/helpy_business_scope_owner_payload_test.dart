import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/entities/helpy_business_scope_owner_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

void main() {
  group('HelpyBusinessScopeOwnerPayload', () {
    test('preserves semantic contract, owner class and title', () {
      final RegistrySemanticContractIdentity contract =
          RegistrySemanticContractIdentity(
            contractId: 'helpy.registry.business_scope',
            version: '1',
          );

      final HelpyBusinessScopeOwnerPayload payload =
          HelpyBusinessScopeOwnerPayload(
            semanticContract: contract,
            entityKindId: 'helpy.registry.business_scope_owner',
            payloadSchemaVersion: '1',
            ownerClassId: ' service_catalog ',
            title: ' Future Category ',
          );

      expect(payload.semanticContract, contract);

      expect(payload.entityKindId, 'helpy.registry.business_scope_owner');

      expect(payload.payloadSchemaVersion, '1');
      expect(payload.ownerClassId, 'service_catalog');
      expect(payload.title, 'Future Category');
    });

    test('rejects an empty owner class', () {
      expect(
        () => HelpyBusinessScopeOwnerPayload(
          semanticContract: RegistrySemanticContractIdentity(
            contractId: 'helpy.registry.business_scope',
            version: '1',
          ),
          entityKindId: 'helpy.registry.business_scope_owner',
          payloadSchemaVersion: '1',
          ownerClassId: ' ',
          title: 'Future Category',
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty owner title', () {
      expect(
        () => HelpyBusinessScopeOwnerPayload(
          semanticContract: RegistrySemanticContractIdentity(
            contractId: 'helpy.registry.business_scope',
            version: '1',
          ),
          entityKindId: 'helpy.registry.business_scope_owner',
          payloadSchemaVersion: '1',
          ownerClassId: 'service_catalog',
          title: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}
