import 'package:flutter/material.dart';

import '../../../core/application/change_impact/registry_dependency_graph.dart';
import '../../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../core/domain/value_objects/registry_engineering_operation_id.dart';
import '../../../core/domain/value_objects/registry_engineering_operation_status.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';
import 'registry_engineering_operation_status_transition_screen.dart';
import 'dart:async';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';

typedef RegistryOperationComparisonViewData = ({
  String operationType,
  String projectAdapter,
  String sourceRevision,
  String sourceHeading,
  RegistryEntityId sourceEntityId,
  String sourceRegistryPath,
  String sourceEvidence,
  String sourceText,
  String targetHeading,
  RegistryEntityId targetEntityId,
  String targetRegistryPath,
  String targetEvidence,
  String targetText,
  String lineDiff,
  RegistryDependencyGraph dependencyGraph,
  List<String> affectedBranchPaths,
  List<String> unaffectedIdentityExplanations,
  List<String> semanticCandidateExplanations,
  List<String> conflictExplanations,
});

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
    this.comparisonViewData,
    this.readinessBlockers = const <String>[],
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
  final RegistryOperationComparisonViewData? comparisonViewData;
  final Iterable<String> readinessBlockers;
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
  Map<String, bool> _semanticCandidateDecisions = const <String, bool>{};
  bool _proposalReviewed = false;

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
  void didUpdateWidget(
    covariant RegistryEngineeringOperationWorkspaceScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.comparisonViewData, widget.comparisonViewData)) {
      _semanticCandidateDecisions = const <String, bool>{};
      _proposalReviewed = false;
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
      _semanticCandidateDecisions = revisions.isEmpty
          ? const <String, bool>{}
          : revisions.last.semanticCandidateDecisions;
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
    if (_currentOperation != null ||
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
        _semanticCandidateDecisions = const <String, bool>{};
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
    final String revisionOriginalValue =
        previous?.originalValue ??
        widget.comparisonViewData?.sourceText.trim() ??
        workingContent;
    final String revisionProposedValue = workingContent;

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
          originalValue: revisionOriginalValue,
          proposedValue: revisionProposedValue,
          previousRevisionId: previous?.id,
          primaryEntityId: primaryEntityId,
          relatedEntityIds: relatedEntityIds,
          semanticCandidateDecisions: _semanticCandidateDecisions,
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
        _proposalReviewed = false;
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

    final List<String> externalOperationReadinessBlockers = widget
        .readinessBlockers
        .map((String blocker) => blocker.trim())
        .where((String blocker) => blocker.isNotEmpty)
        .toList(growable: false);

    final List<String> unresolvedSemanticCandidateExplanations =
        widget.comparisonViewData?.semanticCandidateExplanations
            .where(
              (String candidate) =>
                  !_semanticCandidateDecisions.containsKey(candidate),
            )
            .toList(growable: false) ??
        const <String>[];

    final List<String> semanticReadinessBlockers = <String>[
      for (final String candidate
          in unresolvedSemanticCandidateExplanations.take(5))
        'Semantic candidates unresolved: $candidate',
      if (unresolvedSemanticCandidateExplanations.length > 5)
        'Semantic candidates unresolved: '
            '${unresolvedSemanticCandidateExplanations.length - 5} more',
    ];

    final List<String> conflictReadinessBlockers =
        widget.comparisonViewData?.conflictExplanations
            .map((String conflict) => conflict.trim())
            .where((String conflict) => conflict.isNotEmpty)
            .map((String conflict) => 'Conflict unresolved: $conflict')
            .toList(growable: false) ??
        const <String>[];

    final List<String> proposalReadinessBlockers =
        widget.comparisonViewData != null &&
            _revisions.isNotEmpty &&
            !_proposalReviewed
        ? const <String>['Proposal not reviewed']
        : const <String>[];

    final Widget statusScreen =
        RegistryEngineeringOperationStatusTransitionScreen(
          uiLanguage: widget.uiLanguage,
          operation: currentOperation,
          revisions: _revisions,
          externalReadinessBlockers: <String>[
            ...externalOperationReadinessBlockers,
            ...semanticReadinessBlockers,
            ...conflictReadinessBlockers,
            ...proposalReadinessBlockers,
          ],
          transitionRegistryEngineeringOperationStatus:
              widget.transitionRegistryEngineeringOperationStatus,
          onOperationTransitioned: _setCurrentOperation,
        );

    final Widget operationStatusContent = revisionsReadOnly
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

    final RegistryOperationComparisonViewData? comparisonViewData =
        widget.comparisonViewData;

    final ({
      String title,
      String operationContext,
      String operationType,
      String projectAdapter,
      String sourceRevision,
      String source,
      String target,
      String registryPath,
      String sourceEvidence,
      String affected,
      String primaryAffected,
      String confirmedStructural,
      String noConfirmedStructural,
      String semanticCandidates,
      String noSemanticCandidates,
      String semanticCandidateDecision,
      String semanticCandidateConfirm,
      String semanticCandidateReject,
      String semanticCandidateConfirmed,
      String semanticCandidateRejected,
      String semanticCandidateClear,
      String fullChangeGraph,
      String direct,
      String transitive,
      String paths,
      String affectedBranches,
      String unaffected,
      String noUnaffected,
      String changeSummary,
      String additions,
      String deletions,
      String replacements,
      String potentialMoves,
      String unchanged,
      String changes,
    })
    comparisonLabels = switch (widget.uiLanguage) {
      RegistryStudioUiLanguage.ru => (
        title: 'Сравнение Registry',
        operationContext: 'Контекст операции',
        operationType: 'Тип операции',
        projectAdapter: 'Project adapter',
        sourceRevision: 'Исходная ревизия',
        source: 'Источник',
        target: 'Цель изменения',
        registryPath: 'Registry path',
        sourceEvidence: 'Source Evidence',
        affected: 'Затронутые Registry identities',
        primaryAffected: 'Основная затронутая identity',
        confirmedStructural: 'Подтверждённые структурные связи',
        noConfirmedStructural: 'Подтверждённых структурных связей нет',
        semanticCandidates: 'Semantic candidates',
        noSemanticCandidates: 'Semantic candidates не найдены',
        semanticCandidateDecision: 'Решение инженера',
        semanticCandidateConfirm: 'Подтвердить как зависимость',
        semanticCandidateReject: 'Отклонить как unrelated',
        semanticCandidateConfirmed: 'Подтверждено как зависимость',
        semanticCandidateRejected: 'Отклонено как unrelated',
        semanticCandidateClear: 'Снять решение',
        fullChangeGraph: 'Полный change graph',
        direct: 'Прямые зависимости',
        transitive: 'Транзитивные зависимости',
        paths: 'Пути зависимостей',
        affectedBranches: 'Затронутые ветки',
        unaffected: 'Незатронутые identities',
        noUnaffected: 'Незатронутых identities нет',
        changeSummary: 'Изменения',
        additions: 'Добавления',
        deletions: 'Удаления',
        replacements: 'Замены',
        potentialMoves: 'Потенциальные перемещения',
        unchanged: 'Без изменений',
        changes: 'Построчные изменения',
      ),
      RegistryStudioUiLanguage.en => (
        title: 'Registry comparison',
        operationContext: 'Operation context',
        operationType: 'Operation type',
        projectAdapter: 'Project adapter',
        sourceRevision: 'Source revision',
        source: 'Source',
        target: 'Change target',
        registryPath: 'Registry path',
        sourceEvidence: 'Source Evidence',
        affected: 'Affected Registry identities',
        primaryAffected: 'Primary affected identity',
        confirmedStructural: 'Confirmed structural dependencies',
        noConfirmedStructural: 'No confirmed structural dependencies',
        semanticCandidates: 'Semantic candidates',
        noSemanticCandidates: 'No semantic candidates',
        semanticCandidateDecision: 'Engineer decision',
        semanticCandidateConfirm: 'Confirm dependency',
        semanticCandidateReject: 'Reject as unrelated',
        semanticCandidateConfirmed: 'Confirmed dependency',
        semanticCandidateRejected: 'Rejected as unrelated',
        semanticCandidateClear: 'Clear decision',
        fullChangeGraph: 'Full change graph',
        direct: 'Direct dependencies',
        transitive: 'Transitive dependencies',
        paths: 'Dependency paths',
        affectedBranches: 'Affected branches',
        unaffected: 'Unaffected identities',
        noUnaffected: 'No unaffected identities',
        changeSummary: 'Changes',
        additions: 'Additions',
        deletions: 'Deletions',
        replacements: 'Replacements',
        potentialMoves: 'Potential moves',
        unchanged: 'Unchanged',
        changes: 'Line changes',
      ),
      RegistryStudioUiLanguage.th => (
        title: 'การเปรียบเทียบ Registry',
        operationContext: 'บริบทงาน',
        operationType: 'ประเภทงาน',
        projectAdapter: 'Project adapter',
        sourceRevision: 'รีวิชันต้นทาง',
        source: 'ต้นทาง',
        target: 'เป้าหมายการเปลี่ยนแปลง',
        registryPath: 'Registry path',
        sourceEvidence: 'Source Evidence',
        affected: 'Registry identities ที่ได้รับผลกระทบ',
        primaryAffected: 'identity หลักที่ได้รับผลกระทบ',
        confirmedStructural: 'ความสัมพันธ์เชิงโครงสร้างที่ยืนยันแล้ว',
        noConfirmedStructural: 'ไม่มีความสัมพันธ์เชิงโครงสร้างที่ยืนยันแล้ว',
        semanticCandidates: 'Semantic candidates',
        noSemanticCandidates: 'ไม่พบ semantic candidates',
        semanticCandidateDecision: 'การตัดสินใจของวิศวกร',
        semanticCandidateConfirm: 'ยืนยันว่าเป็น dependency',
        semanticCandidateReject: 'ปฏิเสธว่าไม่เกี่ยวข้อง',
        semanticCandidateConfirmed: 'ยืนยันว่าเป็น dependency แล้ว',
        semanticCandidateRejected: 'ปฏิเสธว่าไม่เกี่ยวข้องแล้ว',
        semanticCandidateClear: 'ล้างการตัดสินใจ',
        fullChangeGraph: 'change graph ทั้งหมด',
        direct: 'การขึ้นต่อกันโดยตรง',
        transitive: 'การขึ้นต่อกันแบบส่งต่อ',
        paths: 'เส้นทางการขึ้นต่อกัน',
        affectedBranches: 'สาขาที่ได้รับผลกระทบ',
        unaffected: 'identity ที่ไม่ได้รับผลกระทบ',
        noUnaffected: 'ไม่มี identity ที่ไม่ได้รับผลกระทบ',
        changeSummary: 'การเปลี่ยนแปลง',
        additions: 'เพิ่ม',
        deletions: 'ลบ',
        replacements: 'แทนที่',
        potentialMoves: 'การย้ายที่เป็นไปได้',
        unchanged: 'ไม่เปลี่ยนแปลง',
        changes: 'การเปลี่ยนแปลงรายบรรทัด',
      ),
    };

    int comparisonAdditionCount = 0;
    int comparisonDeletionCount = 0;
    int comparisonReplacementCount = 0;
    int comparisonPotentialMoveCount = 0;
    int comparisonUnchangedCount = 0;
    int pendingComparisonAdditions = 0;
    int pendingComparisonDeletions = 0;
    final Map<String, int> comparisonAddedLineCounts = <String, int>{};
    final Map<String, int> comparisonDeletedLineCounts = <String, int>{};

    if (comparisonViewData != null) {
      for (final String line in comparisonViewData.lineDiff.split('\n')) {
        if (line.startsWith('  ')) {
          final int finishedRunReplacements =
              pendingComparisonAdditions < pendingComparisonDeletions
              ? pendingComparisonAdditions
              : pendingComparisonDeletions;
          comparisonReplacementCount += finishedRunReplacements;
          comparisonAdditionCount +=
              pendingComparisonAdditions - finishedRunReplacements;
          comparisonDeletionCount +=
              pendingComparisonDeletions - finishedRunReplacements;
          pendingComparisonAdditions = 0;
          pendingComparisonDeletions = 0;
          comparisonUnchangedCount += 1;
          continue;
        }

        if (line.startsWith('+ ')) {
          pendingComparisonAdditions += 1;
          final String addedLine = line.substring(2);
          comparisonAddedLineCounts[addedLine] =
              (comparisonAddedLineCounts[addedLine] ?? 0) + 1;
          continue;
        }

        if (line.startsWith('- ')) {
          pendingComparisonDeletions += 1;
          final String deletedLine = line.substring(2);
          comparisonDeletedLineCounts[deletedLine] =
              (comparisonDeletedLineCounts[deletedLine] ?? 0) + 1;
        }
      }

      final int trailingRunReplacements =
          pendingComparisonAdditions < pendingComparisonDeletions
          ? pendingComparisonAdditions
          : pendingComparisonDeletions;
      comparisonReplacementCount += trailingRunReplacements;
      comparisonAdditionCount +=
          pendingComparisonAdditions - trailingRunReplacements;
      comparisonDeletionCount +=
          pendingComparisonDeletions - trailingRunReplacements;

      for (final MapEntry<String, int> deletedLineEntry
          in comparisonDeletedLineCounts.entries) {
        final int? addedLineCount =
            comparisonAddedLineCounts[deletedLineEntry.key];

        if (addedLineCount == null) {
          continue;
        }

        comparisonPotentialMoveCount += deletedLineEntry.value < addedLineCount
            ? deletedLineEntry.value
            : addedLineCount;
      }
    }

    final int semanticCandidateCount =
        comparisonViewData?.semanticCandidateExplanations.length ?? 0;
    final int pendingSemanticCandidateCount = comparisonViewData == null
        ? 0
        : comparisonViewData.semanticCandidateExplanations
              .where(
                (String candidate) =>
                    !_semanticCandidateDecisions.containsKey(candidate),
              )
              .length;
    final List<String> visibleSemanticCandidateExplanations =
        comparisonViewData?.semanticCandidateExplanations
            .take(5)
            .toList(growable: false) ??
        const <String>[];

    final Widget operationStatusSection = comparisonViewData == null
        ? operationStatusContent
        : Column(
            children: <Widget>[
              Flexible(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Card(
                        key: const Key('registry_operation_context_card'),
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                comparisonLabels.operationContext,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              SelectableText(
                                '${comparisonLabels.operationType}: '
                                '${comparisonViewData.operationType}',
                              ),
                              SelectableText(
                                '${comparisonLabels.projectAdapter}: '
                                '${comparisonViewData.projectAdapter}',
                              ),
                              SelectableText(
                                '${comparisonLabels.sourceRevision}: '
                                '${comparisonViewData.sourceRevision}',
                              ),
                              const Divider(),
                              SelectableText(
                                '${comparisonLabels.source}: '
                                '${comparisonViewData.sourceHeading}\n'
                                '${comparisonViewData.sourceEntityId.value}\n'
                                '${comparisonLabels.registryPath}: '
                                '${comparisonViewData.sourceRegistryPath}\n'
                                '${comparisonLabels.sourceEvidence}: '
                                '${comparisonViewData.sourceEvidence}',
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                '${comparisonLabels.target}: '
                                '${comparisonViewData.targetHeading}\n'
                                '${comparisonViewData.targetEntityId.value}\n'
                                '${comparisonLabels.registryPath}: '
                                '${comparisonViewData.targetRegistryPath}\n'
                                '${comparisonLabels.sourceEvidence}: '
                                '${comparisonViewData.targetEvidence}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        key: const Key(
                          'registry_operation_visible_change_summary',
                        ),
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                comparisonLabels.changeSummary,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                '${comparisonLabels.additions}: '
                                '$comparisonAdditionCount',
                              ),
                              SelectableText(
                                '${comparisonLabels.deletions}: '
                                '$comparisonDeletionCount',
                              ),
                              SelectableText(
                                '${comparisonLabels.replacements}: '
                                '$comparisonReplacementCount',
                              ),
                              SelectableText(
                                '${comparisonLabels.potentialMoves}: '
                                '$comparisonPotentialMoveCount',
                              ),
                              SelectableText(
                                '${comparisonLabels.unchanged}: '
                                '$comparisonUnchangedCount',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        key: const Key(
                          'registry_operation_visible_dependency_summary',
                        ),
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                comparisonLabels.affected,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                comparisonLabels.direct,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              if (comparisonViewData
                                  .dependencyGraph
                                  .directDependencyIds
                                  .isEmpty)
                                const SelectableText('—'),
                              for (final RegistryEntityId entityId
                                  in comparisonViewData
                                      .dependencyGraph
                                      .directDependencyIds)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: SelectableText(entityId.value),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                comparisonLabels.transitive,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              if (comparisonViewData
                                  .dependencyGraph
                                  .transitiveDependencyIds
                                  .isEmpty)
                                const SelectableText('—'),
                              for (final RegistryEntityId entityId
                                  in comparisonViewData
                                      .dependencyGraph
                                      .transitiveDependencyIds)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: SelectableText(entityId.value),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        key: const Key(
                          'registry_operation_visible_semantic_candidates',
                        ),
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                comparisonLabels.semanticCandidates,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                'Всего: $semanticCandidateCount · '
                                'не закрыто: $pendingSemanticCandidateCount',
                              ),
                              const SizedBox(height: 8),
                              if (comparisonViewData
                                  .semanticCandidateExplanations
                                  .isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    OutlinedButton(
                                      key: const Key(
                                        'registry_operation_visible_semantic_candidates_reject_all',
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _semanticCandidateDecisions =
                                              <String, bool>{
                                                ..._semanticCandidateDecisions,
                                                for (final String candidate
                                                    in comparisonViewData
                                                        .semanticCandidateExplanations)
                                                  candidate: false,
                                              };
                                        });
                                      },
                                      child: const Text(
                                        'Отклонить все как unrelated',
                                      ),
                                    ),
                                    TextButton(
                                      key: const Key(
                                        'registry_operation_visible_semantic_candidates_clear_all',
                                      ),
                                      onPressed:
                                          _semanticCandidateDecisions.isEmpty
                                          ? null
                                          : () {
                                              setState(() {
                                                _semanticCandidateDecisions =
                                                    const <String, bool>{};
                                              });
                                            },
                                      child: Text(
                                        comparisonLabels.semanticCandidateClear,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              if (comparisonViewData
                                  .semanticCandidateExplanations
                                  .isEmpty)
                                SelectableText(
                                  comparisonLabels.noSemanticCandidates,
                                ),
                              for (
                                int candidateIndex = 0;
                                candidateIndex <
                                    visibleSemanticCandidateExplanations.length;
                                candidateIndex += 1
                              )
                                StatefulBuilder(
                                  builder:
                                      (
                                        BuildContext context,
                                        StateSetter setCandidateCardState,
                                      ) {
                                        final String candidate =
                                            visibleSemanticCandidateExplanations[candidateIndex];
                                        final bool? decision =
                                            _semanticCandidateDecisions[candidate];

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              SelectableText(candidate),
                                              if (decision != null) ...<Widget>[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${comparisonLabels.semanticCandidateDecision}: '
                                                  '${decision ? comparisonLabels.semanticCandidateConfirmed : comparisonLabels.semanticCandidateRejected}',
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: <Widget>[
                                                  OutlinedButton(
                                                    key: ValueKey<String>(
                                                      'registry_operation_visible_semantic_candidate_confirm_$candidateIndex',
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _semanticCandidateDecisions =
                                                            <String, bool>{
                                                              ..._semanticCandidateDecisions,
                                                              candidate: true,
                                                            };
                                                      });
                                                      setCandidateCardState(
                                                        () {},
                                                      );
                                                    },
                                                    child: Text(
                                                      comparisonLabels
                                                          .semanticCandidateConfirm,
                                                    ),
                                                  ),
                                                  OutlinedButton(
                                                    key: ValueKey<String>(
                                                      'registry_operation_visible_semantic_candidate_reject_$candidateIndex',
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _semanticCandidateDecisions =
                                                            <String, bool>{
                                                              ..._semanticCandidateDecisions,
                                                              candidate: false,
                                                            };
                                                      });
                                                      setCandidateCardState(
                                                        () {},
                                                      );
                                                    },
                                                    child: Text(
                                                      comparisonLabels
                                                          .semanticCandidateReject,
                                                    ),
                                                  ),
                                                  if (decision != null)
                                                    TextButton(
                                                      key: ValueKey<String>(
                                                        'registry_operation_visible_semantic_candidate_clear_$candidateIndex',
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          final Map<
                                                            String,
                                                            bool
                                                          >
                                                          next = <String, bool>{
                                                            ..._semanticCandidateDecisions,
                                                          };
                                                          next.remove(
                                                            candidate,
                                                          );
                                                          _semanticCandidateDecisions =
                                                              next;
                                                        });
                                                        setCandidateCardState(
                                                          () {},
                                                        );
                                                      },
                                                      child: Text(
                                                        comparisonLabels
                                                            .semanticCandidateClear,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        key: const Key('registry_operation_comparison_summary'),
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: ListTile(
                          leading: const Icon(Icons.compare_arrows),
                          title: Text(comparisonLabels.title),
                          subtitle: Text(
                            '${comparisonViewData.sourceHeading}\n'
                            '→ ${comparisonViewData.targetHeading}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            unawaited(
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext sheetContext) {
                                  return SafeArea(
                                    child: FractionallySizedBox(
                                      heightFactor: 0.9,
                                      child: ListView(
                                        key: const Key(
                                          'registry_operation_comparison_sheet',
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        children: <Widget>[
                                          Text(
                                            comparisonLabels.title,
                                            style: Theme.of(
                                              sheetContext,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 12),
                                          Card(
                                            key: const Key(
                                              'registry_operation_comparison_source',
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    comparisonLabels.source,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SelectableText(
                                                    comparisonViewData
                                                        .sourceHeading,
                                                  ),
                                                  SelectableText(
                                                    comparisonViewData
                                                        .sourceEntityId
                                                        .value,
                                                  ),
                                                  const Divider(),
                                                  SelectableText(
                                                    comparisonViewData
                                                        .sourceText,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Card(
                                            key: const Key(
                                              'registry_operation_comparison_target',
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    comparisonLabels.target,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SelectableText(
                                                    comparisonViewData
                                                        .targetHeading,
                                                  ),
                                                  SelectableText(
                                                    comparisonViewData
                                                        .targetEntityId
                                                        .value,
                                                  ),
                                                  const Divider(),
                                                  SelectableText(
                                                    comparisonViewData
                                                        .targetText,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Card(
                                            key: const Key(
                                              'registry_operation_comparison_affected',
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    comparisonLabels.affected,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    comparisonLabels
                                                        .primaryAffected,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleSmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  SelectableText(
                                                    comparisonViewData
                                                        .dependencyGraph
                                                        .primaryEntityId
                                                        .value,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    comparisonLabels
                                                        .confirmedStructural,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleSmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (comparisonViewData
                                                      .dependencyGraph
                                                      .dependencyEdges
                                                      .isEmpty)
                                                    SelectableText(
                                                      comparisonLabels
                                                          .noConfirmedStructural,
                                                    ),
                                                  for (final relation
                                                      in comparisonViewData
                                                          .dependencyGraph
                                                          .dependencyEdges)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4,
                                                          ),
                                                      child: SelectableText(
                                                        '${relation.sourceEntityId.value} → '
                                                        '${relation.targetEntityId.value} '
                                                        '(${relation.meaning.value})',
                                                      ),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    comparisonLabels
                                                        .fullChangeGraph,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleSmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  for (final relation
                                                      in comparisonViewData
                                                          .dependencyGraph
                                                          .dependencyEdges)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4,
                                                          ),
                                                      child: SelectableText(
                                                        '${relation.sourceEntityId.value} → '
                                                        '${relation.targetEntityId.value} '
                                                        '(${relation.meaning.value})',
                                                      ),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    comparisonLabels.direct,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleSmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  for (final RegistryEntityId
                                                      entityId
                                                      in comparisonViewData
                                                          .dependencyGraph
                                                          .directDependencyIds)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4,
                                                          ),
                                                      child: SelectableText(
                                                        entityId.value,
                                                      ),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    comparisonLabels.transitive,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleSmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  for (final RegistryEntityId
                                                      entityId
                                                      in comparisonViewData
                                                          .dependencyGraph
                                                          .transitiveDependencyIds)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4,
                                                          ),
                                                      child: SelectableText(
                                                        entityId.value,
                                                      ),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    comparisonLabels.paths,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleSmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  for (final RegistryEntityId
                                                      entityId
                                                      in comparisonViewData
                                                          .dependencyGraph
                                                          .affectedEntityIds)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 6,
                                                          ),
                                                      child: SelectableText(
                                                        comparisonViewData
                                                            .dependencyGraph
                                                            .pathTo(entityId)
                                                            .map(
                                                              (
                                                                RegistryEntityId
                                                                id,
                                                              ) => id.value,
                                                            )
                                                            .join(' → '),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Card(
                                            key: const Key(
                                              'registry_operation_comparison_semantic_candidates',
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    comparisonLabels
                                                        .semanticCandidates,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  if (comparisonViewData
                                                      .semanticCandidateExplanations
                                                      .isEmpty)
                                                    SelectableText(
                                                      comparisonLabels
                                                          .noSemanticCandidates,
                                                    ),
                                                  for (
                                                    int candidateIndex = 0;
                                                    candidateIndex <
                                                        comparisonViewData
                                                            .semanticCandidateExplanations
                                                            .length;
                                                    candidateIndex += 1
                                                  )
                                                    StatefulBuilder(
                                                      builder:
                                                          (
                                                            BuildContext
                                                            context,
                                                            StateSetter
                                                            setCandidateSheetState,
                                                          ) {
                                                            final String
                                                            candidate =
                                                                comparisonViewData
                                                                    .semanticCandidateExplanations[candidateIndex];
                                                            final bool?
                                                            decision =
                                                                _semanticCandidateDecisions[candidate];

                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    bottom: 12,
                                                                  ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: <Widget>[
                                                                  SelectableText(
                                                                    candidate,
                                                                  ),
                                                                  if (decision !=
                                                                      null) ...<
                                                                    Widget
                                                                  >[
                                                                    const SizedBox(
                                                                      height: 4,
                                                                    ),
                                                                    Text(
                                                                      '${comparisonLabels.semanticCandidateDecision}: '
                                                                      '${decision ? comparisonLabels.semanticCandidateConfirmed : comparisonLabels.semanticCandidateRejected}',
                                                                    ),
                                                                  ],
                                                                  const SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  Wrap(
                                                                    spacing: 8,
                                                                    runSpacing:
                                                                        8,
                                                                    children: <Widget>[
                                                                      OutlinedButton(
                                                                        key:
                                                                            ValueKey<
                                                                              String
                                                                            >(
                                                                              'registry_operation_semantic_candidate_confirm_$candidateIndex',
                                                                            ),
                                                                        onPressed: () {
                                                                          setState(() {
                                                                            _semanticCandidateDecisions =
                                                                                <
                                                                                  String,
                                                                                  bool
                                                                                >{
                                                                                  ..._semanticCandidateDecisions,
                                                                                  candidate: true,
                                                                                };
                                                                          });
                                                                          setCandidateSheetState(
                                                                            () {},
                                                                          );
                                                                        },
                                                                        child: Text(
                                                                          comparisonLabels
                                                                              .semanticCandidateConfirm,
                                                                        ),
                                                                      ),
                                                                      OutlinedButton(
                                                                        key:
                                                                            ValueKey<
                                                                              String
                                                                            >(
                                                                              'registry_operation_semantic_candidate_reject_$candidateIndex',
                                                                            ),
                                                                        onPressed: () {
                                                                          setState(() {
                                                                            _semanticCandidateDecisions =
                                                                                <
                                                                                  String,
                                                                                  bool
                                                                                >{
                                                                                  ..._semanticCandidateDecisions,
                                                                                  candidate: false,
                                                                                };
                                                                          });
                                                                          setCandidateSheetState(
                                                                            () {},
                                                                          );
                                                                        },
                                                                        child: Text(
                                                                          comparisonLabels
                                                                              .semanticCandidateReject,
                                                                        ),
                                                                      ),
                                                                      if (decision !=
                                                                          null)
                                                                        TextButton(
                                                                          key:
                                                                              ValueKey<
                                                                                String
                                                                              >(
                                                                                'registry_operation_semantic_candidate_clear_$candidateIndex',
                                                                              ),
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              final Map<
                                                                                String,
                                                                                bool
                                                                              >
                                                                              next =
                                                                                  <
                                                                                    String,
                                                                                    bool
                                                                                  >{
                                                                                    ..._semanticCandidateDecisions,
                                                                                  };
                                                                              next.remove(
                                                                                candidate,
                                                                              );
                                                                              _semanticCandidateDecisions = next;
                                                                            });
                                                                            setCandidateSheetState(
                                                                              () {},
                                                                            );
                                                                          },
                                                                          child: Text(
                                                                            comparisonLabels.semanticCandidateClear,
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Card(
                                            key: const Key(
                                              'registry_operation_comparison_dependency_coverage',
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    comparisonLabels
                                                        .affectedBranches,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  for (final String path
                                                      in comparisonViewData
                                                          .affectedBranchPaths)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4,
                                                          ),
                                                      child: SelectableText(
                                                        path,
                                                      ),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    comparisonLabels.unaffected,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  if (comparisonViewData
                                                      .unaffectedIdentityExplanations
                                                      .isEmpty)
                                                    SelectableText(
                                                      comparisonLabels
                                                          .noUnaffected,
                                                    ),
                                                  for (final String explanation
                                                      in comparisonViewData
                                                          .unaffectedIdentityExplanations)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4,
                                                          ),
                                                      child: SelectableText(
                                                        explanation,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Card(
                                            key: const Key(
                                              'registry_operation_comparison_change_summary',
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    comparisonLabels
                                                        .changeSummary,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SelectableText(
                                                    '${comparisonLabels.additions}: '
                                                    '$comparisonAdditionCount',
                                                  ),
                                                  SelectableText(
                                                    '${comparisonLabels.deletions}: '
                                                    '$comparisonDeletionCount',
                                                  ),
                                                  SelectableText(
                                                    '${comparisonLabels.replacements}: '
                                                    '$comparisonReplacementCount',
                                                  ),
                                                  SelectableText(
                                                    '${comparisonLabels.potentialMoves}: '
                                                    '$comparisonPotentialMoveCount',
                                                  ),
                                                  SelectableText(
                                                    '${comparisonLabels.unchanged}: '
                                                    '$comparisonUnchangedCount',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Card(
                                            key: const Key(
                                              'registry_operation_comparison_diff',
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    comparisonLabels.changes,
                                                    style: Theme.of(
                                                      sheetContext,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SelectableText(
                                                    comparisonViewData.lineDiff,
                                                    style:
                                                        Theme.of(sheetContext)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              fontFamily:
                                                                  'monospace',
                                                            ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(flex: 3, child: operationStatusContent),
            ],
          );

    if (widget.revisionPrimaryEntityId == null) {
      return operationStatusSection;
    }

    final ({
      String count,
      String field,
      String save,
      String saving,
      String item,
      String original,
      String proposed,
      String working,
      String semanticDecisions,
      String semanticConfirmed,
      String semanticRejected,
      String reviewProposal,
      String proposalReviewed,
    })
    labels = switch (widget.uiLanguage) {
      RegistryStudioUiLanguage.ru => (
        count: 'Редакции',
        field: 'Полная рабочая версия',
        save: 'Сохранить редакцию',
        saving: 'Сохранение…',
        item: 'Редакция',
        original: 'Исходное значение',
        proposed: 'Предложенное значение',
        working: 'Рабочая версия',
        semanticDecisions: 'Решения по semantic candidates',
        semanticConfirmed: 'Подтверждено как dependency',
        semanticRejected: 'Отклонено как unrelated',
        reviewProposal: 'Подтвердить review proposal',
        proposalReviewed: 'Proposal review подтверждён',
      ),
      RegistryStudioUiLanguage.en => (
        count: 'Revisions',
        field: 'Complete working version',
        save: 'Save revision',
        saving: 'Saving…',
        item: 'Revision',
        original: 'Original',
        proposed: 'Proposed',
        working: 'Working',
        semanticDecisions: 'Semantic candidate decisions',
        semanticConfirmed: 'Confirmed dependency',
        semanticRejected: 'Rejected as unrelated',
        reviewProposal: 'Confirm proposal review',
        proposalReviewed: 'Proposal reviewed',
      ),
      RegistryStudioUiLanguage.th => (
        count: 'ฉบับแก้ไข',
        field: 'เวอร์ชันการทำงานฉบับเต็ม',
        save: 'บันทึกฉบับแก้ไข',
        saving: 'กำลังบันทึก…',
        item: 'ฉบับแก้ไข',
        original: 'ค่าต้นฉบับ',
        proposed: 'ค่าที่เสนอ',
        working: 'เวอร์ชันการทำงาน',
        semanticDecisions: 'การตัดสินใจ semantic candidates',
        semanticConfirmed: 'ยืนยันว่าเป็น dependency แล้ว',
        semanticRejected: 'ปฏิเสธว่าไม่เกี่ยวข้องแล้ว',
        reviewProposal: 'ยืนยัน proposal review',
        proposalReviewed: 'ตรวจสอบ proposal แล้ว',
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
                  if (widget.comparisonViewData != null &&
                      _revisions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key(
                          'registry_operation_proposal_review_confirm',
                        ),
                        onPressed: revisionsReadOnly || _proposalReviewed
                            ? null
                            : () {
                                setState(() {
                                  _proposalReviewed = true;
                                });
                              },
                        child: Text(
                          _proposalReviewed
                              ? labels.proposalReviewed
                              : labels.reviewProposal,
                        ),
                      ),
                    ),
                  ],
                  if (_revisions.isNotEmpty) ...<Widget>[
                    const Divider(),
                    SizedBox(
                      height: 112,
                      child: ListView.builder(
                        itemCount: _revisions.length,
                        itemBuilder: (BuildContext context, int index) {
                          final RegistryEngineeringOperationRevision revision =
                              _revisions[_revisions.length - index - 1];

                          final String semanticDecisionEvidence = revision
                              .semanticCandidateDecisions
                              .entries
                              .map(
                                (MapEntry<String, bool> decision) =>
                                    '${decision.value ? labels.semanticConfirmed : labels.semanticRejected}: ${decision.key}',
                              )
                              .join('\\n');

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
                            subtitle: Text(
                              '${labels.original}: ${revision.originalValue}\n'
                              '${labels.proposed}: ${revision.proposedValue}\n'
                              '${labels.working}: ${revision.workingContent}'
                              '${semanticDecisionEvidence.isEmpty ? '' : '\\n${labels.semanticDecisions}:\\n$semanticDecisionEvidence'}',
                            ),
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
