import 'package:flutter/material.dart';

import '../../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';
import 'registry_engineering_operation_creation_screen.dart';
import 'registry_engineering_operation_status_transition_screen.dart';

final class RegistryEngineeringOperationWorkspaceScreen extends StatefulWidget {
  const RegistryEngineeringOperationWorkspaceScreen({
    required this.uiLanguage,
    required this.createRegistryEngineeringOperation,
    required this.transitionRegistryEngineeringOperationStatus,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;

  @override
  State<RegistryEngineeringOperationWorkspaceScreen> createState() =>
      _RegistryEngineeringOperationWorkspaceScreenState();
}

final class _RegistryEngineeringOperationWorkspaceScreenState
    extends State<RegistryEngineeringOperationWorkspaceScreen> {
  RegistryEngineeringOperation? _currentOperation;

  void _setCurrentOperation(RegistryEngineeringOperation operation) {
    setState(() {
      _currentOperation = operation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final RegistryEngineeringOperation? currentOperation = _currentOperation;

    if (currentOperation == null) {
      return RegistryEngineeringOperationCreationScreen(
        uiLanguage: widget.uiLanguage,
        createRegistryEngineeringOperation:
            widget.createRegistryEngineeringOperation,
        onOperationCreated: _setCurrentOperation,
      );
    }

    return RegistryEngineeringOperationStatusTransitionScreen(
      uiLanguage: widget.uiLanguage,
      operation: currentOperation,
      transitionRegistryEngineeringOperationStatus:
          widget.transitionRegistryEngineeringOperationStatus,
      onOperationTransitioned: _setCurrentOperation,
    );
  }
}
