import 'package:flutter/material.dart';

import '../../../core/application/operation_status/transition_registry_engineering_operation_status.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../core/domain/value_objects/registry_engineering_operation_status.dart';
import '../../../presentation/language/registry_studio_ui_labels.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';

final class RegistryEngineeringOperationStatusTransitionScreen
    extends StatefulWidget {
  const RegistryEngineeringOperationStatusTransitionScreen({
    required this.uiLanguage,
    required this.operation,
    required this.transitionRegistryEngineeringOperationStatus,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final RegistryEngineeringOperation operation;
  final TransitionRegistryEngineeringOperationStatus
  transitionRegistryEngineeringOperationStatus;

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
  static const Key currentOperationCardKey = Key(
    'registry_engineering_operation_current_status_card',
  );
  static const Key resultCardKey = Key(
    'registry_engineering_operation_status_transition_result_card',
  );
  static const Key errorTextKey = Key(
    'registry_engineering_operation_status_transition_error_text',
  );

  late RegistryEngineeringOperation _currentOperation;
  late RegistryEngineeringOperationStatus _requestedStatus;
  bool _hasTransitioned = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentOperation = widget.operation;
    _requestedStatus = widget.operation.status;
  }

  @override
  void didUpdateWidget(
    covariant RegistryEngineeringOperationStatusTransitionScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.operation, widget.operation)) {
      _currentOperation = widget.operation;
      _requestedStatus = widget.operation.status;
      _hasTransitioned = false;
      _errorMessage = null;
    }
  }

  void _transitionStatus() {
    final RegistryStudioOperationStatusTransitionLabels labels =
        RegistryStudioUiLabels.forLanguage(
          widget.uiLanguage,
        ).operationStatusTransition;

    try {
      final RegistryEngineeringOperation transitionedOperation = widget
          .transitionRegistryEngineeringOperationStatus(
            operation: _currentOperation,
            nextStatus: _requestedStatus,
          );

      setState(() {
        _currentOperation = transitionedOperation;
        _hasTransitioned = true;
        _errorMessage = null;
      });
    } on ArgumentError catch (error) {
      setState(() {
        _hasTransitioned = false;
        _errorMessage =
            '${labels.transitionFailedTitle}: ${error.message.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final RegistryStudioOperationStatusTransitionLabels labels =
        RegistryStudioUiLabels.forLanguage(
          widget.uiLanguage,
        ).operationStatusTransition;
    final String? errorMessage = _errorMessage;

    return Scaffold(
      appBar: AppBar(title: Text(labels.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _RegistryEngineeringOperationStatusCard(
            key: currentOperationCardKey,
            title: labels.currentOperationTitle,
            labels: labels,
            operation: _currentOperation,
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
          const SizedBox(height: 16),
          FilledButton(
            key: transitionButtonKey,
            onPressed: _transitionStatus,
            child: Text(labels.transitionButton),
          ),
          if (errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            _OperationStatusTransitionErrorMessage(message: errorMessage),
          ],
          if (_hasTransitioned) ...<Widget>[
            const SizedBox(height: 16),
            _RegistryEngineeringOperationStatusCard(
              key: resultCardKey,
              title: labels.transitionedTitle,
              labels: labels,
              operation: _currentOperation,
            ),
          ],
        ],
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
