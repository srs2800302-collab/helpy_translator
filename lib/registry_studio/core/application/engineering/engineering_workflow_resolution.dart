import 'package:equatable/equatable.dart';

enum EngineeringWorkflowResolutionOutcome {
  resolved,
  ambiguous,
  unsupported,
  blocked,
  failed;

  String get contractLabel => name.toUpperCase();
}

final class EngineeringWorkflowResolution extends Equatable {
  factory EngineeringWorkflowResolution.resolved({
    required String selectedWorkflowKey,
    required String explanation,
  }) {
    return EngineeringWorkflowResolution._(
      outcome: EngineeringWorkflowResolutionOutcome.resolved,
      selectedWorkflowKey: _requiredText(
        selectedWorkflowKey,
        'selectedWorkflowKey',
      ),
      candidateWorkflowKeys: const <String>[],
      explanation: _requiredText(explanation, 'explanation'),
    );
  }

  factory EngineeringWorkflowResolution.ambiguous({
    required Iterable<String> candidateWorkflowKeys,
    required String explanation,
  }) {
    final List<String> normalizedCandidates = _normalizeUniqueCandidates(
      candidateWorkflowKeys,
    );

    if (normalizedCandidates.length < 2) {
      throw ArgumentError(
        'Ambiguous engineering workflow resolution requires at least two candidates.',
      );
    }

    return EngineeringWorkflowResolution._(
      outcome: EngineeringWorkflowResolutionOutcome.ambiguous,
      selectedWorkflowKey: null,
      candidateWorkflowKeys: normalizedCandidates,
      explanation: _requiredText(explanation, 'explanation'),
    );
  }

  factory EngineeringWorkflowResolution.unsupported({
    required String explanation,
  }) {
    return EngineeringWorkflowResolution._terminal(
      EngineeringWorkflowResolutionOutcome.unsupported,
      explanation,
    );
  }

  factory EngineeringWorkflowResolution.blocked({required String explanation}) {
    return EngineeringWorkflowResolution._terminal(
      EngineeringWorkflowResolutionOutcome.blocked,
      explanation,
    );
  }

  factory EngineeringWorkflowResolution.failed({required String explanation}) {
    return EngineeringWorkflowResolution._terminal(
      EngineeringWorkflowResolutionOutcome.failed,
      explanation,
    );
  }

  factory EngineeringWorkflowResolution._terminal(
    EngineeringWorkflowResolutionOutcome outcome,
    String explanation,
  ) {
    return EngineeringWorkflowResolution._(
      outcome: outcome,
      selectedWorkflowKey: null,
      candidateWorkflowKeys: const <String>[],
      explanation: _requiredText(explanation, 'explanation'),
    );
  }

  const EngineeringWorkflowResolution._({
    required this.outcome,
    required this.selectedWorkflowKey,
    required this.candidateWorkflowKeys,
    required this.explanation,
  });

  final EngineeringWorkflowResolutionOutcome outcome;
  final String? selectedWorkflowKey;
  final List<String> candidateWorkflowKeys;
  final String explanation;

  bool get isResolved =>
      outcome == EngineeringWorkflowResolutionOutcome.resolved;

  bool get requiresEngineerDecision =>
      outcome == EngineeringWorkflowResolutionOutcome.ambiguous ||
      outcome == EngineeringWorkflowResolutionOutcome.blocked;

  @override
  List<Object?> get props => <Object?>[
    outcome,
    selectedWorkflowKey,
    candidateWorkflowKeys,
    explanation,
  ];

  static String _requiredText(String value, String fieldName) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Engineering workflow resolution $fieldName must not be empty.',
      );
    }

    return normalized;
  }

  static List<String> _normalizeUniqueCandidates(Iterable<String> values) {
    final List<String> normalized = values
        .map((String value) => _requiredText(value, 'candidateWorkflowKey'))
        .toList(growable: false);

    final Set<String> seen = <String>{};

    for (final String value in normalized) {
      if (!seen.add(value)) {
        throw ArgumentError(
          'Duplicate engineering workflow candidate "$value" is not allowed.',
        );
      }
    }

    return List<String>.unmodifiable(normalized);
  }
}
