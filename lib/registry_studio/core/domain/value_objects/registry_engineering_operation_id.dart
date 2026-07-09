import 'package:equatable/equatable.dart';

final class RegistryEngineeringOperationId extends Equatable {
  factory RegistryEngineeringOperationId(String value) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Registry engineering operation identity must not be empty.',
      );
    }

    return RegistryEngineeringOperationId._(normalized);
  }

  const RegistryEngineeringOperationId._(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}
