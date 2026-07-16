import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../core/domain/entities/registry_engineering_operation_revision.dart';
import '../../../core/domain/value_objects/registry_engineering_operation_status.dart';
import '../../../presentation/language/registry_studio_ui_labels.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';

final class RegistryEngineeringOperationStatusTransitionScreen
    extends StatefulWidget {
  const RegistryEngineeringOperationStatusTransitionScreen({
    required this.uiLanguage,
    required this.operation,
    required this.revisions,
    required this.transitionRegistryEngineeringOperationStatus,
    this.onOperationTransitioned,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final RegistryEngineeringOperation operation;
  final Iterable<RegistryEngineeringOperationRevision> revisions;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;
  final FutureOr<void> Function(RegistryEngineeringOperation)?
  onOperationTransitioned;

  @override
  State<RegistryEngineeringOperationStatusTransitionScreen> createState() =>
      _RegistryEngineeringOperationStatusTransitionScreenState();
}

final class _RegistryEngineeringOperationStatusTransitionScreenState
    extends State<RegistryEngineeringOperationStatusTransitionScreen> {
  static const Key requestedStatusDropdownKey = Key(
    'registry_engineering_operation_requested_status_dropdown',
  );
  static const Key transitionButtonKey = Key(
    'registry_engineering_operation_status_transition_button',
  );
  static const Key decisionStatementFieldKey = Key(
    'registry_engineering_operation_decision_statement_field',
  );
  static const Key currentOperationCardKey = Key(
    'registry_engineering_operation_current_status_card',
  );
  static const Key resultCardKey = Key(
    'registry_engineering_operation_status_transition_result_card',
  );
  static const Key latestRevisionCardKey = Key(
    'registry_engineering_operation_latest_revision_card',
  );
  static const Key readinessGateCardKey = Key(
    'registry_engineering_operation_readiness_gate_card',
  );
  static const Key errorTextKey = Key(
    'registry_engineering_operation_status_transition_error_text',
  );

  late RegistryEngineeringOperation _currentOperation;
  late RegistryEngineeringOperationStatus _requestedStatus;
  bool _hasTransitioned = false;
  String? _errorMessage;
  bool _isTransitioning = false;
  late final TextEditingController _decisionStatementController;

  @override
  void initState() {
    super.initState();
    _currentOperation = widget.operation;
    _requestedStatus = widget.operation.status;
    _decisionStatementController = TextEditingController(
      text: widget.operation.decisionStatement,
    );
  }

  @override
  void dispose() {
    _decisionStatementController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(
    covariant RegistryEngineeringOperationStatusTransitionScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.operation, widget.operation)) {
      _currentOperation = widget.operation;
      _requestedStatus = widget.operation.status;
      _decisionStatementController.text =
          widget.operation.decisionStatement ?? '';
      _hasTransitioned = false;
      _errorMessage = null;
      _isTransitioning = false;
    }
  }

  Future<void> _transitionStatus() async {
    if (_isTransitioning) {
      return;
    }

    final RegistryStudioOperationStatusTransitionLabels labels =
        RegistryStudioUiLabels.forLanguage(
          widget.uiLanguage,
        ).operationStatusTransition;

    final RegistryEngineeringOperation transitionedOperation;

    try {
      transitionedOperation = widget
          .transitionRegistryEngineeringOperationStatus(
            operation: _currentOperation,
            nextStatus: _requestedStatus,
            revisions: widget.revisions,
            decisionStatement:
                _requestedStatus == RegistryEngineeringOperationStatus.decided
                ? _decisionStatementController.text
                : null,
          );
    } on ArgumentError catch (error) {
      setState(() {
        _hasTransitioned = false;
        _errorMessage =
            '${labels.transitionFailedTitle}: ${error.message.toString()}';
      });
      return;
    }

    setState(() {
      _isTransitioning = true;
      _hasTransitioned = false;
      _errorMessage = null;
    });

    try {
      await widget.onOperationTransitioned?.call(transitionedOperation);
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _isTransitioning = false;
        _hasTransitioned = false;
        _errorMessage =
            '${labels.transitionFailedTitle}: '
            '${labels.persistenceFailedError}';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    _decisionStatementController.text =
        transitionedOperation.decisionStatement ?? '';

    setState(() {
      _currentOperation = transitionedOperation;
      _isTransitioning = false;
      _hasTransitioned = true;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final RegistryStudioOperationStatusTransitionLabels labels =
        RegistryStudioUiLabels.forLanguage(
          widget.uiLanguage,
        ).operationStatusTransition;
    final String? errorMessage = _errorMessage;
    final List<RegistryEngineeringOperationRevision> revisions = widget
        .revisions
        .toList(growable: false);
    final RegistryEngineeringOperationRevision? latestRevision =
        revisions.isEmpty ? null : revisions.last;
    final ({String title, String original, String proposed, String working})
    revisionLabels = switch (widget.uiLanguage) {
      RegistryStudioUiLanguage.ru => (
        title: 'Последняя редакция',
        original: 'Исходное значение',
        proposed: 'Предложенное значение',
        working: 'Рабочая версия',
      ),
      RegistryStudioUiLanguage.en => (
        title: 'Latest revision',
        original: 'Original',
        proposed: 'Proposed',
        working: 'Working',
      ),
      RegistryStudioUiLanguage.th => (
        title: 'ฉบับแก้ไขล่าสุด',
        original: 'ค่าต้นฉบับ',
        proposed: 'ค่าที่เสนอ',
        working: 'เวอร์ชันการทำงาน',
      ),
    };

    final ({
      String title,
      String ready,
      String blocked,
      String invalidTransition,
      String revisionRequired,
      String revisionOwnershipMismatch,
      String decisionRequired,
    })
    readinessGateLabels = switch (widget.uiLanguage) {
      RegistryStudioUiLanguage.ru => (
        title: 'Проверка готовности',
        ready: 'Блокеров нет',
        blocked: 'Блокеры',
        invalidTransition: 'Переход статуса не разрешён',
        revisionRequired: 'Требуется минимум одна редакция',
        revisionOwnershipMismatch:
            'Редакции должны принадлежать текущей операции',
        decisionRequired: 'Требуется решение инженера',
      ),
      RegistryStudioUiLanguage.en => (
        title: 'Readiness check',
        ready: 'No blockers',
        blocked: 'Blockers',
        invalidTransition: 'Status transition is not allowed',
        revisionRequired: 'At least one revision is required',
        revisionOwnershipMismatch:
            'Revisions must belong to the current operation',
        decisionRequired: 'Engineer decision is required',
      ),
      RegistryStudioUiLanguage.th => (
        title: 'การตรวจสอบความพร้อม',
        ready: 'ไม่มีตัวบล็อก',
        blocked: 'ตัวบล็อก',
        invalidTransition: 'ไม่อนุญาตให้เปลี่ยนสถานะนี้',
        revisionRequired: 'ต้องมีฉบับแก้ไขอย่างน้อยหนึ่งรายการ',
        revisionOwnershipMismatch: 'ฉบับแก้ไขต้องเป็นของงานปัจจุบัน',
        decisionRequired: 'ต้องมีการตัดสินใจของวิศวกร',
      ),
    };
    final bool isAllowedTransition = switch (_currentOperation.status) {
      RegistryEngineeringOperationStatus.open =>
        _requestedStatus ==
                RegistryEngineeringOperationStatus.awaitingContext ||
            _requestedStatus ==
                RegistryEngineeringOperationStatus.readyForDecision ||
            _requestedStatus == RegistryEngineeringOperationStatus.cancelled,
      RegistryEngineeringOperationStatus.awaitingContext =>
        _requestedStatus ==
                RegistryEngineeringOperationStatus.readyForDecision ||
            _requestedStatus == RegistryEngineeringOperationStatus.cancelled,
      RegistryEngineeringOperationStatus.readyForDecision =>
        _requestedStatus ==
                RegistryEngineeringOperationStatus.awaitingContext ||
            _requestedStatus == RegistryEngineeringOperationStatus.decided ||
            _requestedStatus == RegistryEngineeringOperationStatus.cancelled,
      RegistryEngineeringOperationStatus.decided => false,
      RegistryEngineeringOperationStatus.cancelled => false,
    };
    final bool requiresRevisionSet =
        _requestedStatus ==
            RegistryEngineeringOperationStatus.readyForDecision ||
        _requestedStatus == RegistryEngineeringOperationStatus.decided;
    final bool revisionsBelongToCurrentOperation = revisions.every(
      (RegistryEngineeringOperationRevision revision) =>
          revision.operationId == _currentOperation.id,
    );
    final bool requiresEngineerDecision =
        _requestedStatus == RegistryEngineeringOperationStatus.decided;
    final bool hasEngineerDecision = _decisionStatementController.text
        .trim()
        .isNotEmpty;
    final List<String> readinessBlockers = <String>[
      if (!isAllowedTransition) readinessGateLabels.invalidTransition,
      if (requiresRevisionSet && revisions.isEmpty)
        readinessGateLabels.revisionRequired,
      if (requiresRevisionSet && !revisionsBelongToCurrentOperation)
        readinessGateLabels.revisionOwnershipMismatch,
      if (requiresEngineerDecision && !hasEngineerDecision)
        readinessGateLabels.decisionRequired,
    ];

    return Material(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(labels.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _RegistryEngineeringOperationStatusCard(
              key: _hasTransitioned ? resultCardKey : currentOperationCardKey,
              title: _hasTransitioned
                  ? labels.transitionedTitle
                  : labels.currentOperationTitle,
              labels: labels,
              operation: _currentOperation,
            ),
            if (latestRevision != null) ...<Widget>[
              const SizedBox(height: 16),
              _RegistryEngineeringOperationRevisionCard(
                key: latestRevisionCardKey,
                labels: revisionLabels,
                revision: latestRevision,
              ),
            ],
            const SizedBox(height: 16),
            Card(
              key: readinessGateCardKey,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      readinessGateLabels.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (readinessBlockers.isEmpty)
                      Text(readinessGateLabels.ready)
                    else ...<Widget>[
                      Text(readinessGateLabels.blocked),
                      const SizedBox(height: 8),
                      for (final String blocker in readinessBlockers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $blocker'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RegistryEngineeringOperationStatus>(
              key: requestedStatusDropdownKey,
              initialValue: _requestedStatus,
              decoration: InputDecoration(
                labelText: labels.requestedStatusLabel,
                border: const OutlineInputBorder(),
              ),
              items: RegistryEngineeringOperationStatus.values
                  .map(
                    (status) =>
                        DropdownMenuItem<RegistryEngineeringOperationStatus>(
                          value: status,
                          child: Text(status.name),
                        ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _requestedStatus = value;
                  });
                }
              },
            ),
            if (_requestedStatus ==
                RegistryEngineeringOperationStatus.decided) ...<Widget>[
              const SizedBox(height: 16),
              TextField(
                key: decisionStatementFieldKey,
                controller: _decisionStatementController,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: labels.decisionStatementLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: transitionButtonKey,
              onPressed: _isTransitioning ? null : _transitionStatus,
              child: Text(labels.transitionButton),
            ),
            if (errorMessage != null) ...<Widget>[
              const SizedBox(height: 16),
              _OperationStatusTransitionErrorMessage(message: errorMessage),
            ],
          ],
        ),
      ),
    );
  }
}

final class _OperationStatusTransitionErrorMessage extends StatelessWidget {
  const _OperationStatusTransitionErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        key: _RegistryEngineeringOperationStatusTransitionScreenState
            .errorTextKey,
        padding: const EdgeInsets.all(12),
        child: Text(message),
      ),
    );
  }
}

final class _RegistryEngineeringOperationStatusCard extends StatelessWidget {
  const _RegistryEngineeringOperationStatusCard({
    required this.title,
    required this.labels,
    required this.operation,
    super.key,
  });

  final String title;
  final RegistryStudioOperationStatusTransitionLabels labels;
  final RegistryEngineeringOperation operation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _TextValueRow(
              label: labels.operationIdLabel,
              value: operation.id.value,
            ),
            _TextValueRow(
              label: labels.problemStatementLabel,
              value: operation.problemStatement,
            ),
            _TextValueRow(
              label: labels.currentStatusLabel,
              value: operation.status.name,
            ),
            if (operation.decisionStatement != null)
              _TextValueRow(
                label: labels.decisionStatementLabel,
                value: operation.decisionStatement!,
              ),
          ],
        ),
      ),
    );
  }
}

final class _RegistryEngineeringOperationRevisionCard extends StatelessWidget {
  const _RegistryEngineeringOperationRevisionCard({
    required this.labels,
    required this.revision,
    super.key,
  });

  final ({String title, String original, String proposed, String working})
  labels;
  final RegistryEngineeringOperationRevision revision;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(labels.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _TextValueRow(
              label: labels.original,
              value: revision.originalValue,
            ),
            _TextValueRow(
              label: labels.proposed,
              value: revision.proposedValue,
            ),
            _TextValueRow(
              label: labels.working,
              value: revision.workingContent,
            ),
          ],
        ),
      ),
    );
  }
}

final class _TextValueRow extends StatelessWidget {
  const _TextValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText('$label:\n$value'),
    );
  }
}
