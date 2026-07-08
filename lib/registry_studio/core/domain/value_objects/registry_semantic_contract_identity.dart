import 'package:equatable/equatable.dart';

final class RegistrySemanticContractIdentity extends Equatable {
  factory RegistrySemanticContractIdentity({
    required String contractId,
    required String version,
  }) {
    final String normalizedContractId = contractId.trim();
    final String normalizedVersion = version.trim();

    if (normalizedContractId.isEmpty) {
      throw ArgumentError.value(
        contractId,
        'contractId',
        'Semantic contract identity must not be empty.',
      );
    }

    if (normalizedVersion.isEmpty) {
      throw ArgumentError.value(
        version,
        'version',
        'Semantic contract version must not be empty.',
      );
    }

    return RegistrySemanticContractIdentity._(
      contractId: normalizedContractId,
      version: normalizedVersion,
    );
  }

  const RegistrySemanticContractIdentity._({
    required this.contractId,
    required this.version,
  });

  final String contractId;
  final String version;

  @override
  List<Object?> get props => <Object?>[contractId, version];
}
