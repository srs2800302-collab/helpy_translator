import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

void main() {
  group('RegistryEngineeringOperationCreationScreen', () {
    testWidgets('renders isolated operation creation form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      expect(find.text('Создание инженерной операции'), findsOneWidget);
      expect(find.text('ID операции'), findsOneWidget);
      expect(find.text('Постановка проблемы'), findsOneWidget);
      expect(find.text('Создать операцию'), findsOneWidget);
    });

    testWidgets('creates in-memory operation through existing use case', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      await tester.enterText(
        find.byKey(const Key('registry_engineering_operation_id_field')),
        ' registry-operation-001 ',
      );
      await tester.enterText(
        find.byKey(
          const Key('registry_engineering_operation_problem_statement_field'),
        ),
        '  Check possible canonical wording drift.  ',
      );

      await tester.ensureVisible(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.tap(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Операция создана'), findsOneWidget);
      expect(find.text('ID операции:\nregistry-operation-001'), findsOneWidget);
      expect(
        find.text(
          'Постановка проблемы:\nCheck possible canonical wording drift.',
        ),
        findsOneWidget,
      );
      expect(find.text('Статус:\nopen'), findsOneWidget);
    });

    testWidgets('shows presentation error for empty operation id', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      await tester.enterText(
        find.byKey(
          const Key('registry_engineering_operation_problem_statement_field'),
        ),
        'Check possible canonical wording drift.',
      );

      await tester.ensureVisible(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.tap(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ID операции обязателен.'), findsOneWidget);
      expect(find.text('Операция создана'), findsNothing);
    });

    testWidgets('shows presentation error for empty problem statement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      await tester.enterText(
        find.byKey(const Key('registry_engineering_operation_id_field')),
        'registry-operation-001',
      );

      await tester.ensureVisible(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.tap(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Постановка проблемы обязательна.'),
        findsOneWidget,
      );
      expect(find.text('Операция создана'), findsNothing);
    });

    testWidgets('reports created operation through optional callback', (
      WidgetTester tester,
    ) async {
      String? receivedOperationId;

      await tester.pumpWidget(
        _testApp(
          onOperationCreated: (operation) {
            receivedOperationId = operation.id.value;
          },
        ),
      );

      await tester.enterText(
        find.byKey(const Key('registry_engineering_operation_id_field')),
        'registry-operation-001',
      );
      await tester.enterText(
        find.byKey(
          const Key('registry_engineering_operation_problem_statement_field'),
        ),
        'Check possible canonical wording drift.',
      );

      await tester.ensureVisible(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.tap(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.pumpAndSettle();

      expect(receivedOperationId, 'registry-operation-001');
    });
    testWidgets('prefills editable initial problem statement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(initialProblemStatement: 'Candidate wording review.'),
      );

      final Finder field = find.byKey(
        const Key('registry_engineering_operation_problem_statement_field'),
      );

      TextField textField = tester.widget<TextField>(field);

      expect(textField.controller?.text, 'Candidate wording review.');

      await tester.enterText(field, 'Edited candidate wording review.');

      textField = tester.widget<TextField>(field);

      expect(textField.controller?.text, 'Edited candidate wording review.');
    });
  });
}

Widget _testApp({
  String? initialProblemStatement,
  ValueChanged<RegistryEngineeringOperation>? onOperationCreated,
}) {
  return MaterialApp(
    home: RegistryEngineeringOperationCreationScreen(
      uiLanguage: RegistryStudioUiLanguage.ru,
      createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
      initialProblemStatement: initialProblemStatement,
      onOperationCreated: onOperationCreated,
    ),
  );
}
