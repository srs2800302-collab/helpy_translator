import 'package:equatable/equatable.dart';

import 'engineering_service.dart';
import 'engineering_service_contract.dart';
import 'engineering_workflow.dart';
import 'workflow_step_definition.dart';

enum EngineeringServiceBindingSource {
  platform,
  adapter;

  String get contractLabel => name.toUpperCase();
}

enum EngineeringServiceBindingApproval {
  approved,
  rejected;

  String get contractLabel => name.toUpperCase();
}

final class EngineeringServiceBinding<
  I extends EngineeringServiceInput,
  O extends EngineeringServiceOutput
>
    extends Equatable {
  factory EngineeringServiceBinding({
    required String bindingKey,
    required EngineeringService<I, O> service,
    required String bindingProvenance,
    required EngineeringServiceBindingSource source,
    EngineeringServiceBindingApproval approval =
        EngineeringServiceBindingApproval.approved,
  }) {
    return EngineeringServiceBinding._(
      bindingKey: _requiredText(bindingKey, 'bindingKey'),
      service: service,
      bindingProvenance: _requiredText(bindingProvenance, 'bindingProvenance'),
      source: source,
      approval: approval,
    );
  }

  const EngineeringServiceBinding._({
    required this.bindingKey,
    required this.service,
    required this.bindingProvenance,
    required this.source,
    required this.approval,
  });

  final String bindingKey;
  final EngineeringService<I, O> service;
  final String bindingProvenance;
  final EngineeringServiceBindingSource source;
  final EngineeringServiceBindingApproval approval;

  EngineeringServiceContract<I, O> get contract => service.contract;

  String get contractKey => contract.contractKey;

  String get contractSemanticVersion => contract.semanticVersion;

  Type get inputType => contract.inputType;

  Type get outputType => contract.outputType;

  bool get isApproved => approval == EngineeringServiceBindingApproval.approved;

  @override
  List<Object?> get props => <Object?>[
    bindingKey,
    service,
    bindingProvenance,
    source,
    approval,
    contractKey,
    contractSemanticVersion,
    inputType,
    outputType,
  ];
}

final class EngineeringServiceCapabilityCatalog extends Equatable {
  factory EngineeringServiceCapabilityCatalog({
    required String catalogVersion,
    required String compositionFingerprint,
    required Iterable<
      EngineeringServiceBinding<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
    >
    bindings,
    Iterable<EngineeringWorkflow> executableWorkflows =
        const <EngineeringWorkflow>[],
  }) {
    final List<
      EngineeringServiceBinding<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
    >
    normalizedBindings = bindings.toList(growable: false);

    if (normalizedBindings.isEmpty) {
      throw ArgumentError(
        'Engineering service capability catalog must contain at least one binding.',
      );
    }

    _validateApprovedBindings(normalizedBindings);
    _validateUniqueBindingProvenance(normalizedBindings);
    _validateUniqueContractBindings(normalizedBindings);

    final EngineeringServiceCapabilityCatalog catalog =
        EngineeringServiceCapabilityCatalog._(
          catalogVersion: _requiredText(catalogVersion, 'catalogVersion'),
          compositionFingerprint: _requiredText(
            compositionFingerprint,
            'compositionFingerprint',
          ),
          bindings:
              List<
                EngineeringServiceBinding<
                  EngineeringServiceInput,
                  EngineeringServiceOutput
                >
              >.unmodifiable(normalizedBindings),
        );

    for (final EngineeringWorkflow workflow in executableWorkflows) {
      catalog.validateWorkflowSupport(workflow);
    }

    return catalog;
  }

  const EngineeringServiceCapabilityCatalog._({
    required this.catalogVersion,
    required this.compositionFingerprint,
    required this.bindings,
  });

  final String catalogVersion;
  final String compositionFingerprint;
  final List<
    EngineeringServiceBinding<EngineeringServiceInput, EngineeringServiceOutput>
  >
  bindings;

  EngineeringServiceBinding<I, O> resolveForStep<
    I extends EngineeringServiceInput,
    O extends EngineeringServiceOutput
  >(WorkflowStepDefinition<I, O> stepDefinition) {
    return resolveContract(stepDefinition.serviceContract);
  }

  EngineeringServiceBinding<I, O> resolveContract<
    I extends EngineeringServiceInput,
    O extends EngineeringServiceOutput
  >(EngineeringServiceContract<I, O> contract) {
    final List<
      EngineeringServiceBinding<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
    >
    matches = bindings
        .where(
          (
            EngineeringServiceBinding<
              EngineeringServiceInput,
              EngineeringServiceOutput
            >
            binding,
          ) =>
              binding.contractKey == contract.contractKey &&
              binding.contractSemanticVersion == contract.semanticVersion &&
              binding.inputType == contract.inputType &&
              binding.outputType == contract.outputType,
        )
        .toList(growable: false);

    if (matches.length != 1) {
      throw StateError(
        'Engineering service capability catalog must resolve exactly one approved binding for contract "${contract.contractKey}" version "${contract.semanticVersion}".',
      );
    }

    return matches.single as EngineeringServiceBinding<I, O>;
  }

  String bindingProvenanceForStep<
    I extends EngineeringServiceInput,
    O extends EngineeringServiceOutput
  >(WorkflowStepDefinition<I, O> stepDefinition) {
    return resolveForStep(stepDefinition).bindingProvenance;
  }

  void validateWorkflowSupport(EngineeringWorkflow workflow) {
    for (final WorkflowStepDefinition<
          EngineeringServiceInput,
          EngineeringServiceOutput
        >
        step
        in workflow.steps) {
      resolveForStep(step);
    }
  }

  @override
  List<Object?> get props => <Object?>[
    catalogVersion,
    compositionFingerprint,
    bindings,
  ];
}

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Engineering service capability catalog $fieldName must not be empty.',
    );
  }

  return normalized;
}

String _contractSignature(
  EngineeringServiceBinding<EngineeringServiceInput, EngineeringServiceOutput>
  binding,
) {
  return <Object?>[
    binding.contractKey,
    binding.contractSemanticVersion,
    binding.inputType,
    binding.outputType,
  ].join('|');
}

void _validateApprovedBindings(
  Iterable<
    EngineeringServiceBinding<EngineeringServiceInput, EngineeringServiceOutput>
  >
  bindings,
) {
  for (final EngineeringServiceBinding<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
      binding
      in bindings) {
    if (!binding.isApproved) {
      throw ArgumentError(
        'Engineering service capability catalog accepts only approved bindings.',
      );
    }
  }
}

void _validateUniqueBindingProvenance(
  Iterable<
    EngineeringServiceBinding<EngineeringServiceInput, EngineeringServiceOutput>
  >
  bindings,
) {
  final Set<String> seen = <String>{};

  for (final EngineeringServiceBinding<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
      binding
      in bindings) {
    if (!seen.add(binding.bindingProvenance)) {
      throw ArgumentError(
        'Duplicate engineering service binding provenance "${binding.bindingProvenance}" is not allowed.',
      );
    }
  }
}

void _validateUniqueContractBindings(
  Iterable<
    EngineeringServiceBinding<EngineeringServiceInput, EngineeringServiceOutput>
  >
  bindings,
) {
  final Set<String> seen = <String>{};

  for (final EngineeringServiceBinding<
        EngineeringServiceInput,
        EngineeringServiceOutput
      >
      binding
      in bindings) {
    final String signature = _contractSignature(binding);

    if (!seen.add(signature)) {
      throw ArgumentError(
        'Engineering service capability catalog must contain exactly one approved binding per typed service contract.',
      );
    }
  }
}
