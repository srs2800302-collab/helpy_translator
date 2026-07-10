import 'package:flutter/material.dart';

import '../../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';
import 'registry_engineering_operation_creation_screen.dart';
import 'registry_engineering_operation_status_transition_screen.dart';
import 'dart:async';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';

final class RegistryEngineeringOperationWorkspaceScreen extends StatefulWidget {
  const RegistryEngineeringOperationWorkspaceScreen({
    required this.uiLanguage,
    required this.createRegistryEngineeringOperation,
    required this.transitionRegistryEngineeringOperationStatus,
    this.workSessionPersistence,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;
  final RegistryWorkSessionPersistence? workSessionPersistence;

  @override
  State<RegistryEngineeringOperationWorkspaceScreen> createState() =>
      _RegistryEngineeringOperationWorkspaceScreenState();
}

final class _RegistryEngineeringOperationWorkspaceScreenState
    extends State<RegistryEngineeringOperationWorkspaceScreen> {
  RegistryEngineeringOperation? _currentOperation;
  List<RegistryEngineeringOperationRevision> _revisions =
      const <RegistryEngineeringOperationRevision>[];
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();

    if (widget.workSessionPersistence != null) {
      _isRestoring = true;
      unawaited(_restoreWorkspace());
    }
  }

  Future<void> _restoreWorkspace() async {
    final RegistryWorkSessionPersistence persistence =
        widget.workSessionPersistence!;

    final RegistryEngineeringOperation? operation = await persistence
        .loadEngineeringOperation();

    final List<RegistryEngineeringOperationRevision> revisions =
        operation == null
        ? const <RegistryEngineeringOperationRevision>[]
        : await persistence.loadEngineeringOperationRevisions();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentOperation = operation;
      _revisions = revisions;
      _isRestoring = false;
    });
  }

  Future<void> _persistWorkspace() async {
    final RegistryWorkSessionPersistence? persistence =
        widget.workSessionPersistence;
    final RegistryEngineeringOperation? operation = _currentOperation;

    if (persistence == null || operation == null) {
      return;
    }

    await persistence.saveEngineeringOperationWorkspace(
      operation: operation,
      revisions: _revisions,
    );
  }

  void _setCurrentOperation(RegistryEngineeringOperation operation) {
    setState(() {
      _currentOperation = operation;
    });

    unawaited(_persistWorkspace());
  }

  @override
  Widget build(BuildContext context) {
    final RegistryEngineeringOperation? currentOperation = _currentOperation;

    if (_isRestoring) {
      return const Center(child: CircularProgressIndicator());
    }

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
