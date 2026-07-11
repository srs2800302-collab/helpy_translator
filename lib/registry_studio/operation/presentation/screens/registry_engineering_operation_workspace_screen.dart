import 'package:flutter/material.dart';

import '../../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../core/domain/value_objects/registry_engineering_operation_status.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';
import 'registry_engineering_operation_creation_screen.dart';
import 'registry_engineering_operation_status_transition_screen.dart';
import 'dart:async';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';

final class RegistryEngineeringOperationWorkspaceScreen extends StatefulWidget {
  const RegistryEngineeringOperationWorkspaceScreen({
    required this.uiLanguage,
    required this.createRegistryEngineeringOperation,
    required this.transitionRegistryEngineeringOperationStatus,
    this.workSessionPersistence,
    this.revisionPrimaryEntityId,
    this.revisionRelatedEntityIds = const <RegistryEntityId>[],
    this.initialProblemStatement,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;
  final RegistryWorkSessionPersistence? workSessionPersistence;
  final RegistryEntityId? revisionPrimaryEntityId;

  final Iterable<RegistryEntityId> revisionRelatedEntityIds;
  final String? initialProblemStatement;

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
  final TextEditingController _workingContentController =
      TextEditingController();
  bool _isSavingRevision = false;

  @override
  void initState() {
    super.initState();

    if (widget.workSessionPersistence != null) {
      _isRestoring = true;
      unawaited(_restoreWorkspace());
    }
  }

  @override
  void dispose() {
    _workingContentController.dispose();
    super.dispose();
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
      _workingContentController.text = revisions.isEmpty
          ? ''
          : revisions.last.workingContent;
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

  Future<void> _saveRevision() async {
    if (_isSavingRevision) {
      return;
    }

    final RegistryEngineeringOperation? operation = _currentOperation;
    final RegistryEntityId? primaryEntityId = widget.revisionPrimaryEntityId;
    final String workingContent = _workingContentController.text.trim();

    if (operation == null ||
        operation.status == RegistryEngineeringOperationStatus.decided ||
        operation.status == RegistryEngineeringOperationStatus.cancelled ||
        primaryEntityId == null ||
        workingContent.isEmpty) {
      return;
    }

    final RegistryEngineeringOperationRevision? previous = _revisions.isEmpty
        ? null
        : _revisions.last;
    final int revisionNumber = (previous?.revisionNumber ?? 0) + 1;

    final RegistryEngineeringOperationRevision revision =
        RegistryEngineeringOperationRevision(
          id: '${operation.id.value}-revision-$revisionNumber',
          operationId: operation.id,
          revisionNumber: revisionNumber,
          workingContent: workingContent,
          previousRevisionId: previous?.id,
          primaryEntityId: primaryEntityId,
          relatedEntityIds: widget.revisionRelatedEntityIds,
        );

    final List<RegistryEngineeringOperationRevision> next =
        List<RegistryEngineeringOperationRevision>.unmodifiable(
          <RegistryEngineeringOperationRevision>[..._revisions, revision],
        );

    setState(() {
      _isSavingRevision = true;
    });

    try {
      final RegistryWorkSessionPersistence? persistence =
          widget.workSessionPersistence;

      if (persistence != null) {
        await persistence.saveEngineeringOperationWorkspace(
          operation: operation,
          revisions: next,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _revisions = next;
        _isSavingRevision = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingRevision = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить редакцию.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final RegistryEngineeringOperation? currentOperation = _currentOperation;

    if (_isRestoring) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentOperation == null) {
      return RegistryEngineeringOperationCreationScreen(
        initialProblemStatement: widget.initialProblemStatement,
        uiLanguage: widget.uiLanguage,
        createRegistryEngineeringOperation:
            widget.createRegistryEngineeringOperation,
        onOperationCreated: _setCurrentOperation,
      );
    }

    final bool revisionsReadOnly =
        currentOperation.status == RegistryEngineeringOperationStatus.decided ||
        currentOperation.status == RegistryEngineeringOperationStatus.cancelled;

    final Widget statusScreen =
        RegistryEngineeringOperationStatusTransitionScreen(
          uiLanguage: widget.uiLanguage,
          operation: currentOperation,
          transitionRegistryEngineeringOperationStatus:
              widget.transitionRegistryEngineeringOperationStatus,
          onOperationTransitioned: _setCurrentOperation,
        );

    if (widget.revisionPrimaryEntityId == null) {
      return statusScreen;
    }

    final ({
      String count,
      String field,
      String save,
      String saving,
      String item,
    })
    labels = switch (widget.uiLanguage) {
      RegistryStudioUiLanguage.ru => (
        count: 'Редакции',
        field: 'Полная рабочая версия',
        save: 'Сохранить редакцию',
        saving: 'Сохранение…',
        item: 'Редакция',
      ),
      RegistryStudioUiLanguage.en => (
        count: 'Revisions',
        field: 'Complete working version',
        save: 'Save revision',
        saving: 'Saving…',
        item: 'Revision',
      ),
      RegistryStudioUiLanguage.th => (
        count: 'ฉบับแก้ไข',
        field: 'เวอร์ชันการทำงานฉบับเต็ม',
        save: 'บันทึกฉบับแก้ไข',
        saving: 'กำลังบันทึก…',
        item: 'ฉบับแก้ไข',
      ),
    };

    return Column(
      children: <Widget>[
        Expanded(child: statusScreen),
        Material(
          elevation: 6,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    key: const Key('registry_operation_revision_content'),
                    controller: _workingContentController,
                    readOnly: revisionsReadOnly,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: labels.field,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('${labels.count}: ${_revisions.length}'),
                      ),
                      FilledButton(
                        key: const Key('registry_operation_save_revision'),
                        onPressed: revisionsReadOnly || _isSavingRevision
                            ? null
                            : _saveRevision,
                        child: Text(
                          _isSavingRevision ? labels.saving : labels.save,
                        ),
                      ),
                    ],
                  ),
                  if (_revisions.isNotEmpty) ...<Widget>[
                    const Divider(),
                    SizedBox(
                      height: 112,
                      child: ListView.builder(
                        itemCount: _revisions.length,
                        itemBuilder: (BuildContext context, int index) {
                          final RegistryEngineeringOperationRevision revision =
                              _revisions[_revisions.length - index - 1];

                          return ListTile(
                            key: ValueKey<String>(
                              'registry_operation_revision_'
                              '${revision.revisionNumber}',
                            ),
                            dense: true,
                            title: Text(
                              '${labels.item} '
                              '${revision.revisionNumber} · '
                              '${revision.primaryEntityId.value}',
                            ),
                            subtitle: Text(revision.workingContent),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
