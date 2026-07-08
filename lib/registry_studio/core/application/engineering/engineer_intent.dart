import 'package:equatable/equatable.dart';

import '../../domain/value_objects/registry_entity_id.dart';
import '../../domain/value_objects/registry_path.dart';

final class EngineerIntent extends Equatable {
  factory EngineerIntent({
    required String objective,
    RegistryEntityId? targetEntityId,
    RegistryPath? targetPath,
    Iterable<String> scope = const <String>[],
    Iterable<String> constraints = const <String>[],
  }) {
    final String normalizedObjective = objective.trim();

    if (normalizedObjective.isEmpty) {
      throw ArgumentError.value(
        objective,
        'objective',
        'Engineer intent objective must not be empty.',
      );
    }

    if (targetEntityId != null && targetPath != null) {
      throw ArgumentError(
        'Engineer intent must not identify both targetEntityId and targetPath.',
      );
    }

    return EngineerIntent._(
      objective: normalizedObjective,
      targetEntityId: targetEntityId,
      targetPath: targetPath,
      scope: _normalizeUniqueList(scope, 'scope'),
      constraints: _normalizeUniqueList(constraints, 'constraint'),
    );
  }

  const EngineerIntent._({
    required this.objective,
    required this.targetEntityId,
    required this.targetPath,
    required this.scope,
    required this.constraints,
  });

  final String objective;
  final RegistryEntityId? targetEntityId;
  final RegistryPath? targetPath;
  final List<String> scope;
  final List<String> constraints;

  bool get hasTarget => targetEntityId != null || targetPath != null;

  @override
  List<Object?> get props => <Object?>[
    objective,
    targetEntityId,
    targetPath,
    scope,
    constraints,
  ];

  static List<String> _normalizeUniqueList(
    Iterable<String> values,
    String fieldName,
  ) {
    final List<String> normalized = values
        .map((String value) => value.trim())
        .toList(growable: false);

    if (normalized.any((String value) => value.isEmpty)) {
      throw ArgumentError.value(
        values,
        fieldName,
        'Engineer intent $fieldName must not contain empty values.',
      );
    }

    final Set<String> seen = <String>{};

    for (final String value in normalized) {
      if (!seen.add(value)) {
        throw ArgumentError(
          'Duplicate engineer intent $fieldName "$value" is not allowed.',
        );
      }
    }

    return List<String>.unmodifiable(normalized);
  }
}
