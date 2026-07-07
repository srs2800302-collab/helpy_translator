import 'package:equatable/equatable.dart';

import 'registry_adapter_contract_identity.dart';

final class RegistryEntityKind extends Equatable {
  factory RegistryEntityKind({
    required RegistryAdapterContractIdentity adapterContract,
    required String kindId,
    required String schemaVersion,
  }) {
    final String normalizedKindId = kindId.trim();
    final String normalizedSchemaVersion = schemaVersion.trim();

    if (normalizedKindId.isEmpty) {
      throw ArgumentError.value(
        kindId,
        'kindId',
        'Registry entity kind identifier must not be empty.',
      );
    }

    if (normalizedSchemaVersion.isEmpty) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'Registry entity kind schema version must not be empty.',
      );
    }

    return RegistryEntityKind._(
      adapterContract: adapterContract,
      kindId: normalizedKindId,
      schemaVersion: normalizedSchemaVersion,
    );
  }

  const RegistryEntityKind._({
    required this.adapterContract,
    required this.kindId,
    required this.schemaVersion,
  });

  final RegistryAdapterContractIdentity adapterContract;
  final String kindId;
  final String schemaVersion;

  @override
  List<Object?> get props => <Object?>[adapterContract, kindId, schemaVersion];
}
