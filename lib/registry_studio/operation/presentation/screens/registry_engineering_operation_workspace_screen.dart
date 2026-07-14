import 'package:flutter/material.dart';

import '../../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../core/domain/value_objects/registry_engineering_operation_id.dart';
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
    this.revisionRelatedEntityIds,
    this.initialProblemStatement,
    this.initialWorkingContent,
    this.automaticOperationCreation = false,
    this.onInitialProblemStatementConsumed,
    this.onWorkSessionCleared,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;
  final RegistryWorkSessionPersistence? workSessionPersistence;
  final RegistryEntityId? revisionPrimaryEntityId;

  final Iterable<RegistryEntityId>? revisionRelatedEntityIds;
  final String? initialProblemStatement;
  final String? initialWorkingContent;
  final bool automaticOperationCreation;
  final VoidCallback? onInitialProblemStatementConsumed;
  final VoidCallback? onWorkSessionCleared;

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
  bool _isStartingNewOperation = false;
  bool _initialProblemStatementConsumed = false;
  bool _isCreatingInitialOperation = false;
  String? _initialOperationCreationError;

  @override
  void initState() {
    super.initState();

    _workingContentController.text = widget.initialWorkingContent?.trim() ?? '';

    if (widget.workSessionPersistence != null) {
      _isRestoring = true;
      unawaited(_restoreWorkspace());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_createInitialOperationIfNeeded());
        }
      });
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
          ? widget.initialWorkingContent?.trim() ?? ''
          : revisions.last.workingContent;
      _isRestoring = false;
    });

    if (operation != null) {
      _consumeInitialProblemStatement();
    } else {
      await _createInitialOperationIfNeeded();
    }
  }

  Future<void> _persistOperation(RegistryEngineeringOperation operation) async {
    final RegistryWorkSessionPersistence? persistence =
        widget.workSessionPersistence;

    if (persistence == null) {
      return;
    }

    await persistence.saveEngineeringOperationWorkspace(
      operation: operation,
      revisions: _revisions,
    );
  }

  Future<void> _setCurrentOperation(
    RegistryEngineeringOperation operation,
  ) async {
    await _persistOperation(operation);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentOperation = operation;
    });
  }

  void _consumeInitialProblemStatement() {
    if (_initialProblemStatementConsumed ||
        widget.initialProblemStatement == null) {
      return;
    }

    _initialProblemStatementConsumed = true;
    widget.onInitialProblemStatementConsumed?.call();
  }

  Future<void> _setCreatedOperation(
    RegistryEngineeringOperation operation,
  ) async {
    await _setCurrentOperation(operation);

    if (!mounted) {
      return;
    }

    _consumeInitialProblemStatement();
  }

  Future<void> _createInitialOperationIfNeeded() async {
    if (!widget.automaticOperationCreation ||
        _currentOperation != null ||
        _isRestoring ||
        _isCreatingInitialOperation ||
        _initialProblemStatementConsumed) {
      return;
    }

    final String? problemStatement = widget.initialProblemStatement?.trim();

    if (problemStatement == null || problemStatement.isEmpty) {
      return;
    }

    setState(() {
      _isCreatingInitialOperation = true;
      _initialOperationCreationError = null;
    });

    try {
      final RegistryEngineeringOperation operation = widget
          .createRegistryEngineeringOperation(
            id: RegistryEngineeringOperationId(
              'registry-operation-'
              '${DateTime.now().microsecondsSinceEpoch}',
            ),
            problemStatement: problemStatement,
          );

      await _setCreatedOperation(operation);

      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingInitialOperation = false;
        _initialOperationCreationError = null;
      });
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingInitialOperation = false;
        _initialOperationCreationError = switch (widget.uiLanguage) {
          RegistryStudioUiLanguage.ru =>
            'Не удалось автоматически создать инженерную операцию.',
          RegistryStudioUiLanguage.en =>
            'Failed to create the engineering operation automatically.',
          RegistryStudioUiLanguage.th =>
            'ไม่สามารถสร้างงานวิศวกรรมโดยอัตโนมัติได้',
        };
      });
    }
  }

  Future<void> _startNewOperation() async {
    if (_isStartingNewOperation) {
      return;
    }

    final RegistryEngineeringOperation? operation = _currentOperation;

    if (operation == null ||
        (operation.status != RegistryEngineeringOperationStatus.decided &&
            operation.status != RegistryEngineeringOperationStatus.cancelled)) {
      return;
    }

    final ({String title, String message, String cancel, String confirm})
    labels = switch (widget.uiLanguage) {
      RegistryStudioUiLanguage.ru => (
        title: 'Начать новую операцию?',
        message:
            'Текущая завершённая операция и её локальные редакции '
            'будут удалены из рабочей сессии.',
        cancel: 'Отмена',
        confirm: 'Начать',
      ),
      RegistryStudioUiLanguage.en => (
        title: 'Start a new operation?',
        message:
            'The current completed operation and its local revisions '
            'will be removed from the work session.',
        cancel: 'Cancel',
        confirm: 'Start',
      ),
      RegistryStudioUiLanguage.th => (
        title: 'เริ่มงานวิศวกรรมใหม่หรือไม่',
        message:
            'งานที่เสร็จสิ้นปัจจุบันและฉบับแก้ไขในเครื่อง'
            'จะถูกลบออกจากเซสชันการทำงาน',
        cancel: 'ยกเลิก',
        confirm: 'เริ่มใหม่',
      ),
    };

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(labels.title),
              content: Text(labels.message),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: Text(labels.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(labels.confirm),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isStartingNewOperation = true;
    });

    try {
      await widget.workSessionPersistence?.clearEngineeringOperationWorkspace();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentOperation = null;
        _revisions = const <RegistryEngineeringOperationRevision>[];
        _workingContentController.clear();
        _isSavingRevision = false;
        _isStartingNewOperation = false;
        _initialProblemStatementConsumed = true;
      });
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _isStartingNewOperation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось начать новую инженерную операцию.'),
        ),
      );
      return;
    }

    widget.onWorkSessionCleared?.call();
  }

  Future<void> _saveRevision() async {
    if (_isSavingRevision) {
      return;
    }

    final RegistryEngineeringOperation? operation = _currentOperation;
    final RegistryEngineeringOperationRevision? previous = _revisions.isEmpty
        ? null
        : _revisions.last;
    final RegistryEntityId? primaryEntityId =
        previous?.primaryEntityId ?? widget.revisionPrimaryEntityId;
    final Iterable<RegistryEntityId> relatedEntityIds =
        widget.revisionRelatedEntityIds ??
        previous?.relatedEntityIds ??
        const <RegistryEntityId>[];
    final String workingContent = _workingContentController.text.trim();

    if (operation == null ||
        operation.status == RegistryEngineeringOperationStatus.decided ||
        operation.status == RegistryEngineeringOperationStatus.cancelled ||
        primaryEntityId == null ||
        workingContent.isEmpty) {
      return;
    }

    final int revisionNumber = (previous?.revisionNumber ?? 0) + 1;

    final RegistryEngineeringOperationRevision revision =
        RegistryEngineeringOperationRevision(
          id: '${operation.id.value}-revision-$revisionNumber',
          operationId: operation.id,
          revisionNumber: revisionNumber,
          workingContent: workingContent,
          previousRevisionId: previous?.id,
          primaryEntityId: primaryEntityId,
          relatedEntityIds: relatedEntityIds,
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
      if (!widget.automaticOperationCreation) {
        return RegistryEngineeringOperationCreationScreen(
          initialProblemStatement: _initialProblemStatementConsumed
              ? null
              : widget.initialProblemStatement,
          uiLanguage: widget.uiLanguage,
          createRegistryEngineeringOperation:
              widget.createRegistryEngineeringOperation,
          onOperationCreated: _setCreatedOperation,
        );
      }

      final String? creationError = _initialOperationCreationError;
      final bool hasPendingProblemStatement =
          !_initialProblemStatementConsumed &&
          (widget.initialProblemStatement?.trim().isNotEmpty ?? false);

      if (creationError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(creationError, textAlign: TextAlign.center),
          ),
        );
      }

      if (_isCreatingInitialOperation || hasPendingProblemStatement) {
        return const Center(child: CircularProgressIndicator());
      }

      final String emptyStateMessage = switch (widget.uiLanguage) {
        RegistryStudioUiLanguage.ru =>
          'Сначала выберите источник и цель изменения.',
        RegistryStudioUiLanguage.en =>
          'Select the source and change target first.',
        RegistryStudioUiLanguage.th =>
          'เลือกแหล่งที่มาและเป้าหมายการเปลี่ยนแปลงก่อน',
      };

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyStateMessage, textAlign: TextAlign.center),
        ),
      );
    }

    final bool revisionsReadOnly =
        currentOperation.status == RegistryEngineeringOperationStatus.decided ||
        currentOperation.status == RegistryEngineeringOperationStatus.cancelled;

    final ({String startNew, String startingNew}) terminalLabels =
        switch (widget.uiLanguage) {
          RegistryStudioUiLanguage.ru => (
            startNew: 'Начать новую операцию',
            startingNew: 'Очистка…',
          ),
          RegistryStudioUiLanguage.en => (
            startNew: 'Start new operation',
            startingNew: 'Clearing…',
          ),
          RegistryStudioUiLanguage.th => (
            startNew: 'เริ่มงานวิศวกรรมใหม่',
            startingNew: 'กำลังล้าง…',
          ),
        };

    final Widget statusScreen =
        RegistryEngineeringOperationStatusTransitionScreen(
          uiLanguage: widget.uiLanguage,
          operation: currentOperation,
          revisions: _revisions,
          transitionRegistryEngineeringOperationStatus:
              widget.transitionRegistryEngineeringOperationStatus,
          onOperationTransitioned: _setCurrentOperation,
        );

    final Widget operationStatusSection = revisionsReadOnly
        ? Column(
            children: <Widget>[
              Expanded(child: statusScreen),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const Key(
                        'registry_engineering_operation_start_new_button',
                      ),
                      onPressed: _isStartingNewOperation
                          ? null
                          : _startNewOperation,
                      child: Text(
                        _isStartingNewOperation
                            ? terminalLabels.startingNew
                            : terminalLabels.startNew,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : statusScreen;

    if (widget.revisionPrimaryEntityId == null) {
      return operationStatusSection;
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
        Expanded(child: operationStatusSection),
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
