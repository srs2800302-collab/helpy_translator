import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_status_transition_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

void main() {
  group('RegistryEngineeringOperationWorkspaceScreen', () {
    testWidgets('starts with operation creation flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      expect(
        find.byType(RegistryEngineeringOperationCreationScreen),
        findsOneWidget,
      );
      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsNothing,
      );
      expect(find.text('Создание инженерной операции'), findsOneWidget);
    });

    testWidgets('switches to status transition flow after operation creation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

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

      expect(
        find.byType(RegistryEngineeringOperationCreationScreen),
        findsNothing,
      );
      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsOneWidget,
      );
      expect(find.text('Смена статуса инженерной операции'), findsOneWidget);
      expect(find.text('ID операции:\nregistry-operation-001'), findsOneWidget);
      expect(find.text('Текущий статус:\nopen'), findsOneWidget);
    });

    testWidgets('keeps transitioned operation as current workspace operation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

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

      await tester.tap(
        find.byKey(
          const Key('registry_engineering_operation_requested_status_dropdown'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('registry_engineering_operation_status_transition_button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Текущий статус:\nreadyForDecision'), findsWidgets);
      expect(find.text('Текущий статус:\nopen'), findsNothing);
    });

    testWidgets('locks revision editing after engineer decision', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(revisionPrimaryEntityId: RegistryEntityId('primary')),
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

      final Finder createButton = find.byKey(
        const Key('registry_engineering_operation_create_button'),
      );

      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      TextField revisionEditor = tester.widget<TextField>(
        find.byKey(const Key('registry_operation_revision_content')),
      );
      FilledButton saveRevisionButton = tester.widget<FilledButton>(
        find.byKey(const Key('registry_operation_save_revision')),
      );

      expect(revisionEditor.readOnly, isFalse);
      expect(saveRevisionButton.onPressed, isNotNull);

      final Finder statusDropdown = find.byKey(
        const Key('registry_engineering_operation_requested_status_dropdown'),
      );
      final Finder transitionButton = find.byKey(
        const Key('registry_engineering_operation_status_transition_button'),
      );

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(transitionButton);
      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('decided').last);
      await tester.pumpAndSettle();

      final Finder decisionField = find.byKey(
        const Key('registry_engineering_operation_decision_statement_field'),
      );

      await tester.ensureVisible(decisionField);
      await tester.enterText(decisionField, 'Approve canonical wording.');

      await tester.ensureVisible(transitionButton);
      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      revisionEditor = tester.widget<TextField>(
        find.byKey(const Key('registry_operation_revision_content')),
      );
      saveRevisionButton = tester.widget<FilledButton>(
        find.byKey(const Key('registry_operation_save_revision')),
      );

      expect(find.text('Текущий статус:\ndecided'), findsWidgets);
      expect(revisionEditor.readOnly, isTrue);
      expect(saveRevisionButton.onPressed, isNull);
    });

    testWidgets('passes supplied UI language into operation flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(uiLanguage: RegistryStudioUiLanguage.th),
      );

      expect(find.text('สร้างงานวิศวกรรม'), findsOneWidget);
      expect(find.text('รหัสงาน'), findsOneWidget);
      expect(find.text('คำอธิบายปัญหา'), findsOneWidget);
    });
  });
}

Widget _testApp({
  RegistryStudioUiLanguage uiLanguage = RegistryStudioUiLanguage.ru,
  RegistryEntityId? revisionPrimaryEntityId,
}) {
  return MaterialApp(
    home: RegistryEngineeringOperationWorkspaceScreen(
      uiLanguage: uiLanguage,
      createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
      transitionRegistryEngineeringOperationStatus:
          TransitionRegistryEngineeringOperationStatus(),
      revisionPrimaryEntityId: revisionPrimaryEntityId,
    ),
  );
}
