import '../value_objects/registry_semantic_contract_identity.dart';

abstract interface class RegistryEntityPayload {
  RegistrySemanticContractIdentity get semanticContract;

  String get entityKindId;

  String get payloadSchemaVersion;
}
