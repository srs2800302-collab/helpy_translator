import 'package:equatable/equatable.dart';

final class RegistryRelationMeaning extends Equatable {
  factory RegistryRelationMeaning(String value) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Registry relation meaning must not be empty.',
      );
    }

    return RegistryRelationMeaning._(normalized);
  }

  const RegistryRelationMeaning._(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}
