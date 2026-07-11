import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_status_transition_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('restores saved engineering operation', (
    WidgetTester tester,
  ) async {
    const RegistryWorkSessionPersistence persistence =
        RegistryWorkSessionPersistence();

    await persistence.saveEngineeringOperationWorkspace(
      operation: RegistryEngineeringOperation(
        id: RegistryEngineeringOperationId('operation-1'),
        status: RegistryEngineeringOperationStatus.open,
        problemStatement: 'Original problem.',
      ),
      revisions: const [],
    );

    bool initialProblemStatementConsumed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: RegistryEngineeringOperationWorkspaceScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          createRegistryEngineeringOperation:
              CreateRegistryEngineeringOperation(),
          transitionRegistryEngineeringOperationStatus:
              TransitionRegistryEngineeringOperationStatus(),
          workSessionPersistence: persistence,
          initialProblemStatement: 'Translator candidate.',
          onInitialProblemStatementConsumed: () {
            initialProblemStatementConsumed = true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byType(RegistryEngineeringOperationStatusTransitionScreen),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(initialProblemStatementConsumed, isTrue);
  });

  testWidgets('creates linked revisions and restores them', (
    WidgetTester tester,
  ) async {
    const RegistryWorkSessionPersistence persistence =
        RegistryWorkSessionPersistence();
    final RegistryEngineeringOperation operation = RegistryEngineeringOperation(
      id: RegistryEngineeringOperationId('operation-1'),
      status: RegistryEngineeringOperationStatus.open,
      problemStatement: 'Original problem.',
    );

    await persistence.saveEngineeringOperationWorkspace(
      operation: operation,
      revisions: const [],
    );

    Widget workspace() {
      return MaterialApp(
        home: RegistryEngineeringOperationWorkspaceScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          createRegistryEngineeringOperation:
              CreateRegistryEngineeringOperation(),
          transitionRegistryEngineeringOperationStatus:
              TransitionRegistryEngineeringOperationStatus(),
          workSessionPersistence: persistence,
          revisionPrimaryEntityId: RegistryEntityId('primary'),
          revisionRelatedEntityIds: <RegistryEntityId>[
            RegistryEntityId('related-001'),
          ],
        ),
      );
    }

    await tester.pumpWidget(workspace());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('registry_operation_revision_content')),
      'Первая полная версия.',
    );
    await tester.tap(find.byKey(const Key('registry_operation_save_revision')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('registry_operation_revision_content')),
      'Вторая расширенная версия.',
    );
    await tester.tap(find.byKey(const Key('registry_operation_save_revision')));
    await tester.pumpAndSettle();

    final revisions = await persistence.loadEngineeringOperationRevisions();

    expect(revisions, hasLength(2));
    expect(revisions.first.revisionNumber, 1);
    expect(revisions.first.previousRevisionId, isNull);
    expect(revisions.last.revisionNumber, 2);
    expect(revisions.last.previousRevisionId, revisions.first.id);
    expect(revisions.last.primaryEntityId, RegistryEntityId('primary'));
    expect(revisions.last.relatedEntityIds, <RegistryEntityId>[
      RegistryEntityId('related-001'),
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(workspace());
    await tester.pumpAndSettle();

    expect(find.text('Редакции: 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('registry_operation_revision_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('registry_operation_revision_2')),
      findsOneWidget,
    );

    final TextField editor = tester.widget<TextField>(
      find.byKey(const Key('registry_operation_revision_content')),
    );

    expect(editor.controller?.text, 'Вторая расширенная версия.');
  });

  for (final RegistryEngineeringOperationStatus terminalStatus
      in <RegistryEngineeringOperationStatus>[
        RegistryEngineeringOperationStatus.decided,
        RegistryEngineeringOperationStatus.cancelled,
      ]) {
    testWidgets(
      'restores ${terminalStatus.name} workspace as revision read-only',
      (WidgetTester tester) async {
        const RegistryWorkSessionPersistence persistence =
            RegistryWorkSessionPersistence();

        final RegistryEngineeringOperation operation =
            RegistryEngineeringOperation(
              id: RegistryEngineeringOperationId('operation-1'),
              status: terminalStatus,
              problemStatement: 'Original problem.',
              decisionStatement:
                  terminalStatus == RegistryEngineeringOperationStatus.decided
                  ? 'Approve canonical wording.'
                  : null,
            );

        final RegistryEngineeringOperationRevision revision =
            RegistryEngineeringOperationRevision(
              id: 'operation-1-revision-1',
              operationId: operation.id,
              revisionNumber: 1,
              workingContent: 'Final working version.',
              previousRevisionId: null,
              primaryEntityId: RegistryEntityId('primary'),
              relatedEntityIds: const <RegistryEntityId>[],
            );

        await persistence.saveEngineeringOperationWorkspace(
          operation: operation,
          revisions: <RegistryEngineeringOperationRevision>[revision],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RegistryEngineeringOperationWorkspaceScreen(
              uiLanguage: RegistryStudioUiLanguage.ru,
              createRegistryEngineeringOperation:
                  CreateRegistryEngineeringOperation(),
              transitionRegistryEngineeringOperationStatus:
                  TransitionRegistryEngineeringOperationStatus(),
              workSessionPersistence: persistence,
              revisionPrimaryEntityId: RegistryEntityId('primary'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final TextField revisionEditor = tester.widget<TextField>(
          find.byKey(const Key('registry_operation_revision_content')),
        );
        final FilledButton saveRevisionButton = tester.widget<FilledButton>(
          find.byKey(const Key('registry_operation_save_revision')),
        );

        expect(
          find.byKey(const ValueKey<String>('registry_operation_revision_1')),
          findsOneWidget,
        );
        expect(revisionEditor.controller?.text, 'Final working version.');
        expect(revisionEditor.readOnly, isTrue);
        expect(saveRevisionButton.onPressed, isNull);

        final Finder startNewButton = find.byKey(
          const Key('registry_engineering_operation_start_new_button'),
        );

        expect(startNewButton, findsOneWidget);

        await tester.tap(startNewButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Начать'));
        await tester.pumpAndSettle();

        expect(
          find.byType(RegistryEngineeringOperationCreationScreen),
          findsOneWidget,
        );
        expect(await persistence.loadEngineeringOperation(), isNull);
        expect(await persistence.loadEngineeringOperationRevisions(), isEmpty);
      },
    );
  }
}
