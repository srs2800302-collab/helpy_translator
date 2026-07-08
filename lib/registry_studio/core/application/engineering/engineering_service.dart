import 'package:equatable/equatable.dart';

import 'engineering_service_contract.dart';

final class EngineeringServiceResult<O extends EngineeringServiceOutput>
    extends Equatable {
  factory EngineeringServiceResult.success({
    required O output,
    Iterable<String> traceabilityReferences = const <String>[],
  }) {
    return EngineeringServiceResult._(
      output: output,
      failure: null,
      traceabilityReferences: _normalizeUniqueList(
        traceabilityReferences,
        'traceabilityReference',
      ),
    );
  }

  factory EngineeringServiceResult.failure({
    required EngineeringServiceFailure failure,
    Iterable<String> traceabilityReferences = const <String>[],
  }) {
    return EngineeringServiceResult._(
      output: null,
      failure: failure,
      traceabilityReferences: _normalizeUniqueList(
        traceabilityReferences,
        'traceabilityReference',
      ),
    );
  }

  const EngineeringServiceResult._({
    required this.output,
    required this.failure,
    required this.traceabilityReferences,
  });

  final O? output;
  final EngineeringServiceFailure? failure;
  final List<String> traceabilityReferences;

  bool get isSuccess => output != null;

  bool get isFailure => failure != null;

  O get requireOutput {
    final O? value = output;

    if (value == null) {
      throw StateError('Engineering service result does not contain output.');
    }

    return value;
  }

  EngineeringServiceFailure get requireFailure {
    final EngineeringServiceFailure? value = failure;

    if (value == null) {
      throw StateError('Engineering service result does not contain failure.');
    }

    return value;
  }

  @override
  List<Object?> get props => <Object?>[output, failure, traceabilityReferences];
}

abstract interface class EngineeringService<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
> {
  EngineeringServiceContract<I, O> get contract;

  EngineeringServiceFailure? validatePreconditions(I input);

  Future<EngineeringServiceResult<O>> execute(I input);
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Engineering service result $fieldName must not be empty.',
    );
  }

  return normalized;
}

List<String> _normalizeUniqueList(Iterable<String> values, String fieldName) {
  final List<String> normalized = values
      .map((String value) => _requiredText(value, fieldName))
      .toList(growable: false);

  final Set<String> seen = <String>{};

  for (final String value in normalized) {
    if (!seen.add(value)) {
      throw ArgumentError(
        'Duplicate engineering service result $fieldName "$value" is not allowed.',
      );
    }
  }

  return List<String>.unmodifiable(normalized);
}
