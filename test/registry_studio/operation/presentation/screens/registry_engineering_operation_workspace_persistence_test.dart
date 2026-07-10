import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';
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

    await tester.pumpWidget(
      MaterialApp(
        home: RegistryEngineeringOperationWorkspaceScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          createRegistryEngineeringOperation:
              CreateRegistryEngineeringOperation(),
          transitionRegistryEngineeringOperationStatus:
              TransitionRegistryEngineeringOperationStatus(),
          workSessionPersistence: persistence,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byType(RegistryEngineeringOperationStatusTransitionScreen),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
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
}
