import 'package:equatable/equatable.dart';

final class RegistryPath extends Equatable {
  factory RegistryPath(Iterable<String> segments) {
    final List<String> normalized = segments
        .map((String segment) => segment.trim())
        .toList(growable: false);

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        segments,
        'segments',
        'Registry path must contain at least one semantic segment.',
      );
    }

    if (normalized.any((String segment) => segment.isEmpty)) {
      throw ArgumentError.value(
        segments,
        'segments',
        'Registry path must not contain empty semantic segments.',
      );
    }

    return RegistryPath._(List<String>.unmodifiable(normalized));
  }

  const RegistryPath._(this.segments);

  final List<String> segments;

  @override
  List<Object?> get props => <Object?>[segments];
}
