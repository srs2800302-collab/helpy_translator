import '../value_objects/registry_adapter_contract_identity.dart';

abstract interface class RegistryEntityPayload {
  RegistryAdapterContractIdentity get adapterContract;

  String get entityKindId;

  String get payloadSchemaVersion;
}
