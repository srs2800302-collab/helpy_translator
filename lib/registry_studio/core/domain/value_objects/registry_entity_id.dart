import 'package:equatable/equatable.dart';

final class RegistryEntityId extends Equatable {
  factory RegistryEntityId(String value) {
    final String normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Registry entity identity must not be empty.',
      );
    }

    return RegistryEntityId._(normalizedValue);
  }

  const RegistryEntityId._(this.value);

  final String value;

  @override
  List<Object> get props => <Object>[value];
}
