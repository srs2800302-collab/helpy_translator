import 'package:equatable/equatable.dart';

import 'engineering_service_contract.dart';

final class WorkflowStepDefinition<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>
    extends Equatable {
  factory WorkflowStepDefinition({
    required String stepKey,
    required int sequenceOrder,
    required String title,
    required EngineeringServiceContract<I, O> serviceContract,
    Iterable<String> preconditions = const <String>[],
    Iterable<String> stopConditions = const <String>[],
    Iterable<String> engineerConfirmationRequirements = const <String>[],
  }) {
    if (sequenceOrder <= 0) {
      throw ArgumentError.value(
        sequenceOrder,
        'sequenceOrder',
        'Workflow step sequence order must be positive.',
      );
    }

    return WorkflowStepDefinition._(
      stepKey: _requiredText(stepKey, 'stepKey'),
      sequenceOrder: sequenceOrder,
      title: _requiredText(title, 'title'),
      serviceContract: serviceContract,
      preconditions: _normalizeUniqueList(preconditions, 'precondition'),
      stopConditions: _normalizeUniqueList(stopConditions, 'stopCondition'),
      engineerConfirmationRequirements: _normalizeUniqueList(
        engineerConfirmationRequirements,
        'engineerConfirmationRequirement',
      ),
    );
  }

  const WorkflowStepDefinition._({
    required this.stepKey,
    required this.sequenceOrder,
    required this.title,
    required this.serviceContract,
    required this.preconditions,
    required this.stopConditions,
    required this.engineerConfirmationRequirements,
  });

  final String stepKey;
  final int sequenceOrder;
  final String title;
  final EngineeringServiceContract<I, O> serviceContract;
  final List<String> preconditions;
  final List<String> stopConditions;
  final List<String> engineerConfirmationRequirements;

  String get requiredServiceContractKey => serviceContract.contractKey;

  Type get inputType => serviceContract.inputType;

  Type get outputType => serviceContract.outputType;

  bool get requiresEngineerConfirmation =>
      engineerConfirmationRequirements.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[
    stepKey,
    sequenceOrder,
    title,
    serviceContract,
    preconditions,
    stopConditions,
    engineerConfirmationRequirements,
  ];
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Workflow step definition $fieldName must not be empty.',
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
        'Duplicate workflow step definition $fieldName "$value" is not allowed.',
      );
    }
  }

  return List<String>.unmodifiable(normalized);
}
