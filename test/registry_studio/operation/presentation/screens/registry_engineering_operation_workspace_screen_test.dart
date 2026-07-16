import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_status_transition_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

void main() {
  group('RegistryEngineeringOperationWorkspaceScreen', () {
    testWidgets('shows empty state without prepared operation context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Сначала выберите источник и цель изменения.'),
        findsOneWidget,
      );
      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsNothing,
      );
    });

    testWidgets('creates operation and opens status transition flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          initialProblemStatement: 'Check possible canonical wording drift.',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsOneWidget,
      );
      expect(
        find.textContaining('ID операции:\nregistry-operation-'),
        findsOneWidget,
      );
      expect(find.text('Текущий статус:\nopen'), findsOneWidget);
    });

    testWidgets('keeps transitioned operation as current workspace operation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          revisionPrimaryEntityId: RegistryEntityId('primary'),
          initialProblemStatement: 'Check possible canonical wording drift.',
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('registry_operation_revision_content')),
        'Approved working content.',
      );

      final Finder saveRevisionFinder = find.byKey(
        const Key('registry_operation_save_revision'),
      );
      await tester.scrollUntilVisible(
        saveRevisionFinder,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveRevisionFinder);
      await tester.pumpAndSettle();

      final Finder statusDropdown = find.byKey(
        const Key('registry_engineering_operation_requested_status_dropdown'),
      );
      await tester.scrollUntilVisible(
        statusDropdown,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      final Finder transitionButton = find.byKey(
        const Key('registry_engineering_operation_status_transition_button'),
      );
      await tester.scrollUntilVisible(
        transitionButton,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();

      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Текущий статус:\nreadyForDecision', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Текущий статус:\nopen', skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('locks revision editing after engineer decision', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          revisionPrimaryEntityId: RegistryEntityId('primary'),
          initialProblemStatement: 'Check possible canonical wording drift.',
        ),
      );
      await tester.pumpAndSettle();

      TextField revisionEditor = tester.widget<TextField>(
        find.byKey(const Key('registry_operation_revision_content')),
      );
      FilledButton saveRevisionButton = tester.widget<FilledButton>(
        find.byKey(const Key('registry_operation_save_revision')),
      );

      expect(revisionEditor.readOnly, isFalse);
      expect(saveRevisionButton.onPressed, isNotNull);
      expect(
        find.byKey(
          const Key('registry_engineering_operation_start_new_button'),
        ),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('registry_operation_revision_content')),
        'Approved working content.',
      );

      final Finder saveRevisionFinder = find.byKey(
        const Key('registry_operation_save_revision'),
      );
      await tester.scrollUntilVisible(
        saveRevisionFinder,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveRevisionFinder);
      await tester.pumpAndSettle();

      final Finder statusDropdown = find.byKey(
        const Key('registry_engineering_operation_requested_status_dropdown'),
      );
      final Finder transitionButton = find.byKey(
        const Key('registry_engineering_operation_status_transition_button'),
      );

      await tester.scrollUntilVisible(
        statusDropdown,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        transitionButton,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();

      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        statusDropdown,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('decided').last);
      await tester.pumpAndSettle();

      final Finder decisionField = find.byKey(
        const Key('registry_engineering_operation_decision_statement_field'),
      );

      await Scrollable.ensureVisible(
        tester.element(decisionField),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.enterText(decisionField, 'Approve canonical wording.');

      await tester.scrollUntilVisible(
        transitionButton,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();

      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      revisionEditor = tester.widget<TextField>(
        find.byKey(const Key('registry_operation_revision_content')),
      );
      saveRevisionButton = tester.widget<FilledButton>(
        find.byKey(const Key('registry_operation_save_revision')),
      );

      expect(
        find.text('Текущий статус:\ndecided', skipOffstage: false),
        findsOneWidget,
      );
      expect(revisionEditor.readOnly, isTrue);
      expect(saveRevisionButton.onPressed, isNull);

      final Finder startNewButton = find.byKey(
        const Key('registry_engineering_operation_start_new_button'),
      );

      expect(startNewButton, findsOneWidget);

      await tester.scrollUntilVisible(
        startNewButton,
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 16,
      );
      await tester.pumpAndSettle();
      await tester.tap(startNewButton);
      await tester.pumpAndSettle();

      expect(find.text('Начать новую операцию?'), findsOneWidget);

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsOneWidget,
      );

      await tester.tap(startNewButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Начать'));
      await tester.pumpAndSettle();

      expect(
        find.text('Сначала выберите источник и цель изменения.'),
        findsOneWidget,
      );
      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsNothing,
      );
    });

    testWidgets('localizes empty workspace state', (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(uiLanguage: RegistryStudioUiLanguage.th),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('เลือกแหล่งที่มาและเป้าหมายการเปลี่ยนแปลงก่อน'),
        findsOneWidget,
      );
    });
  });
}

Widget _testApp({
  RegistryStudioUiLanguage uiLanguage = RegistryStudioUiLanguage.ru,
  RegistryEntityId? revisionPrimaryEntityId,
  String? initialProblemStatement,
  RegistryWorkSessionPersistence? workSessionPersistence,
  VoidCallback? onInitialProblemStatementConsumed,
}) {
  return MaterialApp(
    home: RegistryEngineeringOperationWorkspaceScreen(
      uiLanguage: uiLanguage,
      createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
      transitionRegistryEngineeringOperationStatus:
          TransitionRegistryEngineeringOperationStatus(),
      revisionPrimaryEntityId: revisionPrimaryEntityId,
      initialProblemStatement: initialProblemStatement,
      workSessionPersistence: workSessionPersistence,
      onInitialProblemStatementConsumed: onInitialProblemStatementConsumed,
    ),
  );
}
