import 'package:equatable/equatable.dart';

final class RegistryEntityId extends Equatable {
  factory RegistryEntityId(String value) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Registry entity identity must not be empty.',
      );
    }

    return RegistryEntityId._(normalized);
  }

  const RegistryEntityId._(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}
