import 'package:equatable/equatable.dart';

final class RegistryAdapterContractIdentity extends Equatable {
  factory RegistryAdapterContractIdentity({
    required String adapterId,
    required String semanticContractVersion,
  }) {
    final String normalizedAdapterId = adapterId.trim();
    final String normalizedVersion = semanticContractVersion.trim();

    if (normalizedAdapterId.isEmpty) {
      throw ArgumentError.value(
        adapterId,
        'adapterId',
        'Adapter identity must not be empty.',
      );
    }

    if (normalizedVersion.isEmpty) {
      throw ArgumentError.value(
        semanticContractVersion,
        'semanticContractVersion',
        'Adapter semantic-contract version must not be empty.',
      );
    }

    return RegistryAdapterContractIdentity._(
      adapterId: normalizedAdapterId,
      semanticContractVersion: normalizedVersion,
    );
  }

  const RegistryAdapterContractIdentity._({
    required this.adapterId,
    required this.semanticContractVersion,
  });

  final String adapterId;
  final String semanticContractVersion;

  @override
  List<Object?> get props => <Object?>[adapterId, semanticContractVersion];
}
