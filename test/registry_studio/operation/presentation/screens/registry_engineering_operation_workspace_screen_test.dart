import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
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

    testWidgets('keeps operation unchanged when persistence write fails', (
      WidgetTester tester,
    ) async {
      const MethodChannel channel = MethodChannel(
        'plugins.flutter.io/shared_preferences',
      );
      bool failWrites = true;
      bool initialProblemStatementConsumed = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getAll' ||
                call.method == 'getAllWithParameters') {
              return <String, Object>{};
            }

            if (call.method == 'setString') {
              return !failWrites;
            }

            return true;
          });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await tester.pumpWidget(
        _testApp(
          workSessionPersistence: const RegistryWorkSessionPersistence(),
          revisionPrimaryEntityId: RegistryEntityId('primary'),
          initialProblemStatement: 'Candidate wording review.',
          onInitialProblemStatementConsumed: () {
            initialProblemStatementConsumed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('registry_engineering_operation_id_field')),
        'registry-operation-001',
      );

      final Finder createButton = find.byKey(
        const Key('registry_engineering_operation_create_button'),
      );

      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(
        find.byType(RegistryEngineeringOperationCreationScreen),
        findsOneWidget,
      );
      expect(
        find.text('Не удалось сохранить инженерную операцию.'),
        findsOneWidget,
      );
      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsNothing,
      );
      expect(initialProblemStatementConsumed, isFalse);

      final TextField retainedProblemStatement = tester.widget<TextField>(
        find.byKey(
          const Key('registry_engineering_operation_problem_statement_field'),
        ),
      );

      expect(
        retainedProblemStatement.controller?.text,
        'Candidate wording review.',
      );

      failWrites = false;

      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsOneWidget,
      );
      expect(find.text('Текущий статус:\nopen'), findsOneWidget);
      expect(initialProblemStatementConsumed, isTrue);

      await tester.enterText(
        find.byKey(const Key('registry_operation_revision_content')),
        'Approved working content.',
      );

      final Finder saveRevisionFinder = find.byKey(
        const Key('registry_operation_save_revision'),
      );
      await tester.ensureVisible(saveRevisionFinder);
      await tester.tap(saveRevisionFinder);
      await tester.pumpAndSettle();

      final Finder statusDropdown = find.byKey(
        const Key('registry_engineering_operation_requested_status_dropdown'),
      );
      await Scrollable.ensureVisible(
        tester.element(statusDropdown),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      failWrites = true;

      final Finder transitionButton = find.byKey(
        const Key('registry_engineering_operation_status_transition_button'),
      );
      await Scrollable.ensureVisible(
        tester.element(transitionButton),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();

      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Текущий статус:\nopen', skipOffstage: false),
        findsOneWidget,
      );

      final Finder persistenceError = find.textContaining(
        'Не удалось сохранить новый статус '
        'инженерной операции.',
        skipOffstage: false,
      );

      expect(persistenceError, findsOneWidget);

      await Scrollable.ensureVisible(
        tester.element(persistenceError),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Не удалось сохранить новый статус '
          'инженерной операции.',
        ),
        findsOneWidget,
      );
      expect(find.text('Статус изменён', skipOffstage: false), findsNothing);
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
      await tester.ensureVisible(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.tap(
        find.byKey(const Key('registry_engineering_operation_create_button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('registry_operation_revision_content')),
        'Approved working content.',
      );

      final Finder saveRevisionFinder = find.byKey(
        const Key('registry_operation_save_revision'),
      );
      await tester.ensureVisible(saveRevisionFinder);
      await tester.tap(saveRevisionFinder);
      await tester.pumpAndSettle();

      final Finder statusDropdown = find.byKey(
        const Key('registry_engineering_operation_requested_status_dropdown'),
      );
      await Scrollable.ensureVisible(
        tester.element(statusDropdown),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      final Finder transitionButton = find.byKey(
        const Key('registry_engineering_operation_status_transition_button'),
      );
      await Scrollable.ensureVisible(
        tester.element(transitionButton),
        alignment: 0.5,
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
          initialProblemStatement: 'Translator candidate.',
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
      await tester.ensureVisible(saveRevisionFinder);
      await tester.tap(saveRevisionFinder);
      await tester.pumpAndSettle();

      final Finder statusDropdown = find.byKey(
        const Key('registry_engineering_operation_requested_status_dropdown'),
      );
      final Finder transitionButton = find.byKey(
        const Key('registry_engineering_operation_status_transition_button'),
      );

      await Scrollable.ensureVisible(
        tester.element(statusDropdown),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      await Scrollable.ensureVisible(
        tester.element(transitionButton),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();

      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      await Scrollable.ensureVisible(
        tester.element(statusDropdown),
        alignment: 0.5,
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

      await Scrollable.ensureVisible(
        tester.element(transitionButton),
        alignment: 0.5,
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
        find.byType(RegistryEngineeringOperationCreationScreen),
        findsOneWidget,
      );
      expect(
        find.byType(RegistryEngineeringOperationStatusTransitionScreen),
        findsNothing,
      );

      final TextField problemStatementField = tester.widget<TextField>(
        find.byKey(
          const Key('registry_engineering_operation_problem_statement_field'),
        ),
      );

      expect(problemStatementField.controller?.text, isEmpty);
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
