import 'package:equatable/equatable.dart';

abstract interface class EngineeringServiceInput {}

abstract interface class EngineeringServiceOutput {}

final class EngineeringServiceFailure extends Equatable {
  factory EngineeringServiceFailure({
    required String code,
    required String message,
    bool isRetryable = false,
    Iterable<String> details = const <String>[],
  }) {
    return EngineeringServiceFailure._(
      code: _requiredText(code, 'code'),
      message: _requiredText(message, 'message'),
      isRetryable: isRetryable,
      details: _normalizeUniqueList(details, 'detail'),
    );
  }

  const EngineeringServiceFailure._({
    required this.code,
    required this.message,
    required this.isRetryable,
    required this.details,
  });

  final String code;
  final String message;
  final bool isRetryable;
  final List<String> details;

  @override
  List<Object?> get props => <Object?>[code, message, isRetryable, details];
}

final class EngineeringServiceContract<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>
    extends Equatable {
  factory EngineeringServiceContract({
    required String contractKey,
    required String semanticVersion,
    required String description,
    Iterable<String> preconditions = const <String>[],
    Iterable<String> traceabilityRequirements = const <String>[],
  }) {
    if (I == EngineeringServiceInput || O == EngineeringServiceOutput) {
      throw ArgumentError(
        'Engineering service contract must declare concrete typed input and output.',
      );
    }

    return EngineeringServiceContract._(
      contractKey: _requiredText(contractKey, 'contractKey'),
      semanticVersion: _requiredText(semanticVersion, 'semanticVersion'),
      description: _requiredText(description, 'description'),
      preconditions: _normalizeUniqueList(preconditions, 'precondition'),
      traceabilityRequirements: _normalizeUniqueList(
        traceabilityRequirements,
        'traceabilityRequirement',
      ),
    );
  }

  const EngineeringServiceContract._({
    required this.contractKey,
    required this.semanticVersion,
    required this.description,
    required this.preconditions,
    required this.traceabilityRequirements,
  });

  final String contractKey;
  final String semanticVersion;
  final String description;
  final List<String> preconditions;
  final List<String> traceabilityRequirements;

  Type get inputType => I;

  Type get outputType => O;

  Type get failureType => EngineeringServiceFailure;

  bool acceptsInput(EngineeringServiceInput input) => input is I;

  bool acceptsOutput(EngineeringServiceOutput output) => output is O;

  @override
  List<Object?> get props => <Object?>[
    contractKey,
    semanticVersion,
    description,
    inputType,
    outputType,
    preconditions,
    traceabilityRequirements,
  ];
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Engineering service contract $fieldName must not be empty.',
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
        'Duplicate engineering service contract $fieldName "$value" is not allowed.',
      );
    }
  }

  return List<String>.unmodifiable(normalized);
}
