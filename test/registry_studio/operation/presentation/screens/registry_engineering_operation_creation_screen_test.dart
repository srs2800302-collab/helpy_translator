import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart';

void main() {
  group('RegistryEngineeringOperationCreationScreen', () {
    testWidgets('renders isolated operation creation form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      expect(find.text('Создание engineering operation'), findsOneWidget);
      expect(find.text('ID операции'), findsOneWidget);
      expect(find.text('Постановка проблемы'), findsOneWidget);
      expect(find.text('Создать operation'), findsOneWidget);
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

      await tester.tap(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Operation создана'), findsOneWidget);
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

      await tester.tap(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Registry engineering operation identity must not be empty.',
        ),
        findsOneWidget,
      );
      expect(find.text('Operation создана'), findsNothing);
    });

    testWidgets('shows presentation error for empty problem statement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      await tester.enterText(
        find.byKey(const Key('registry_engineering_operation_id_field')),
        'registry-operation-001',
      );

      await tester.tap(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Registry engineering operation problem statement must not be empty.',
        ),
        findsOneWidget,
      );
      expect(find.text('Operation создана'), findsNothing);
    });
  });
}

Widget _testApp() {
  return MaterialApp(
    home: RegistryEngineeringOperationCreationScreen(
      createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
    ),
  );
}
