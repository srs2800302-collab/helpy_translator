import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

void main() {
  group('RegistryEntityPayload', () {
    test('exposes independent semantic and schema identity components', () {
      final RegistrySemanticContractIdentity semanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'sample.semantic_contract',
            version: '1',
          );

      final RegistryEntityPayload payload = _FixtureRegistryEntityPayload(
        semanticContract: semanticContract,
        entityKindId: 'sample.entity',
        payloadSchemaVersion: '3',
      );

      expect(payload.semanticContract, same(semanticContract));
      expect(payload.entityKindId, 'sample.entity');
      expect(payload.payloadSchemaVersion, '3');
    });
  });
}

final class _FixtureRegistryEntityPayload implements RegistryEntityPayload {
  const _FixtureRegistryEntityPayload({
    required this.semanticContract,
    required this.entityKindId,
    required this.payloadSchemaVersion,
  });

  @override
  final RegistrySemanticContractIdentity semanticContract;

  @override
  final String entityKindId;

  @override
  final String payloadSchemaVersion;
}
