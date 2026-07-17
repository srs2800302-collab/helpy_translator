import 'package:equatable/equatable.dart';

import 'registry_semantic_contract_identity.dart';

final class RegistryEntityKind extends Equatable {
  factory RegistryEntityKind({
    required RegistrySemanticContractIdentity semanticContract,
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
      semanticContract: semanticContract,
      kindId: normalizedKindId,
      schemaVersion: normalizedSchemaVersion,
    );
  }

  const RegistryEntityKind._({
    required this.semanticContract,
    required this.kindId,
    required this.schemaVersion,
  });

  final RegistrySemanticContractIdentity semanticContract;
  final String kindId;
  final String schemaVersion;

  @override
  List<Object> get props => <Object>[semanticContract, kindId, schemaVersion];
}
