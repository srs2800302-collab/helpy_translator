import 'package:flutter/material.dart';

import '../../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../core/domain/value_objects/registry_engineering_operation_id.dart';
import '../../../presentation/language/registry_studio_ui_labels.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';

final class RegistryEngineeringOperationCreationScreen extends StatefulWidget {
  const RegistryEngineeringOperationCreationScreen({
    required this.uiLanguage,
    required this.createRegistryEngineeringOperation,
    this.initialProblemStatement,
    this.onOperationCreated,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;
  final String? initialProblemStatement;
  final ValueChanged<RegistryEngineeringOperation>? onOperationCreated;

  @override
  State<RegistryEngineeringOperationCreationScreen> createState() =>
      _RegistryEngineeringOperationCreationScreenState();
}

final class _RegistryEngineeringOperationCreationScreenState
    extends State<RegistryEngineeringOperationCreationScreen> {
  static const Key operationIdFieldKey = Key(
    'registry_engineering_operation_id_field',
  );
  static const Key problemStatementFieldKey = Key(
    'registry_engineering_operation_problem_statement_field',
  );
  static const Key createButtonKey = Key(
    'registry_engineering_operation_create_button',
  );
  static const Key resultCardKey = Key(
    'registry_engineering_operation_result_card',
  );
  static const Key errorTextKey = Key(
    'registry_engineering_operation_error_text',
  );

  final TextEditingController _operationIdController = TextEditingController();
  late final TextEditingController _problemStatementController;

  RegistryEngineeringOperation? _createdOperation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _problemStatementController = TextEditingController(
      text: widget.initialProblemStatement,
    );
  }

  @override
  void dispose() {
    _operationIdController.dispose();
    _problemStatementController.dispose();
    super.dispose();
  }

  void _createOperation() {
    FocusScope.of(context).unfocus();

    final RegistryStudioOperationCreationLabels labels =
        RegistryStudioUiLabels.forLanguage(widget.uiLanguage).operationCreation;
    final String operationId = _operationIdController.text;
    final String problemStatement = _problemStatementController.text;

    if (operationId.trim().isEmpty) {
      setState(() {
        _createdOperation = null;
        _errorMessage = labels.operationIdRequiredError;
      });
      return;
    }

    if (problemStatement.trim().isEmpty) {
      setState(() {
        _createdOperation = null;
        _errorMessage = labels.problemStatementRequiredError;
      });
      return;
    }

    try {
      final RegistryEngineeringOperation operation = widget
          .createRegistryEngineeringOperation(
            id: RegistryEngineeringOperationId(operationId),
            problemStatement: problemStatement,
          );

      setState(() {
        _createdOperation = operation;
        _errorMessage = null;
      });

      widget.onOperationCreated?.call(operation);
    } on ArgumentError catch (error) {
      setState(() {
        _createdOperation = null;
        _errorMessage = error.message.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final RegistryEngineeringOperation? operation = _createdOperation;
    final String? errorMessage = _errorMessage;
    final RegistryStudioOperationCreationLabels labels =
        RegistryStudioUiLabels.forLanguage(widget.uiLanguage).operationCreation;

    return Scaffold(
      appBar: AppBar(title: Text(labels.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            key: operationIdFieldKey,
            controller: _operationIdController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: labels.operationIdLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: problemStatementFieldKey,
            controller: _problemStatementController,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: labels.problemStatementLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: createButtonKey,
            onPressed: _createOperation,
            child: Text(labels.createButton),
          ),
          if (errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            _OperationCreationErrorMessage(message: errorMessage),
          ],
          if (operation != null) ...<Widget>[
            const SizedBox(height: 16),
            _RegistryEngineeringOperationCard(
              labels: labels,
              operation: operation,
            ),
          ],
        ],
      ),
    );
  }
}

final class _OperationCreationErrorMessage extends StatelessWidget {
  const _OperationCreationErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        key: _RegistryEngineeringOperationCreationScreenState.errorTextKey,
        padding: const EdgeInsets.all(12),
        child: Text(message),
      ),
    );
  }
}

final class _RegistryEngineeringOperationCard extends StatelessWidget {
  const _RegistryEngineeringOperationCard({
    required this.labels,
    required this.operation,
  });

  final RegistryStudioOperationCreationLabels labels;
  final RegistryEngineeringOperation operation;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: _RegistryEngineeringOperationCreationScreenState.resultCardKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              labels.createdTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
              label: labels.statusLabel,
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
