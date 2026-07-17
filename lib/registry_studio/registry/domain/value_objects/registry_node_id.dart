import 'package:equatable/equatable.dart';

final class RegistryNodeId extends Equatable {
  factory RegistryNodeId(String value) {
    final String normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Registry node identity must not be empty.',
      );
    }

    return RegistryNodeId._(normalizedValue);
  }

  const RegistryNodeId._(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}
