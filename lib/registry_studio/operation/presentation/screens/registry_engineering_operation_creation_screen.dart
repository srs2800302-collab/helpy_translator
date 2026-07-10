import 'package:flutter/material.dart';

import '../../../core/application/operation_creation/create_registry_engineering_operation.dart';
import '../../../core/domain/entities/registry_engineering_operation.dart';
import '../../../core/domain/value_objects/registry_engineering_operation_id.dart';

final class RegistryEngineeringOperationCreationScreen extends StatefulWidget {
  const RegistryEngineeringOperationCreationScreen({
    required this.createRegistryEngineeringOperation,
    super.key,
  });

  final CreateRegistryEngineeringOperation createRegistryEngineeringOperation;

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
  final TextEditingController _problemStatementController =
      TextEditingController();

  RegistryEngineeringOperation? _createdOperation;
  String? _errorMessage;

  @override
  void dispose() {
    _operationIdController.dispose();
    _problemStatementController.dispose();
    super.dispose();
  }

  void _createOperation() {
    FocusScope.of(context).unfocus();

    try {
      final RegistryEngineeringOperation operation = widget
          .createRegistryEngineeringOperation(
            id: RegistryEngineeringOperationId(_operationIdController.text),
            problemStatement: _problemStatementController.text,
          );

      setState(() {
        _createdOperation = operation;
        _errorMessage = null;
      });
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

    return Scaffold(
      appBar: AppBar(title: const Text('Создание engineering operation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            key: operationIdFieldKey,
            controller: _operationIdController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'ID операции',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: problemStatementFieldKey,
            controller: _problemStatementController,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Постановка проблемы',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: createButtonKey,
            onPressed: _createOperation,
            child: const Text('Создать operation'),
          ),
          if (errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            _OperationCreationErrorMessage(message: errorMessage),
          ],
          if (operation != null) ...<Widget>[
            const SizedBox(height: 16),
            _RegistryEngineeringOperationCard(operation: operation),
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
  const _RegistryEngineeringOperationCard({required this.operation});

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
              'Operation создана',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _TextValueRow(label: 'ID операции', value: operation.id.value),
            _TextValueRow(
              label: 'Постановка проблемы',
              value: operation.problemStatement,
            ),
            _TextValueRow(label: 'Статус', value: operation.status.name),
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
