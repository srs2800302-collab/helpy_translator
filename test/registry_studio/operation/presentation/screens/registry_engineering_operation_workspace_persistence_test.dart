import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import 'package:helpy_translator/registry_studio/core/application/change_impact/registry_dependency_graph.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';
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

  testWidgets(
    'preserves comparison original value and stores edited proposed value',
    (WidgetTester tester) async {
      const RegistryWorkSessionPersistence persistence =
          RegistryWorkSessionPersistence();

      final RegistryOperationComparisonViewData comparisonViewData = (
        operationType: 'Service Intake comparison',
        projectAdapter: 'Helpy Service Intake',
        sourceRevision: 'source-revision',
        sourceHeading: 'Source heading',
        sourceEntityId: RegistryEntityId('source'),
        sourceRegistryPath: 'source',
        sourceEvidence: 'H2 Source owner → H3 Source heading; lines 1–10',
        sourceText: 'Original source value.',
        targetHeading: 'Target heading',
        targetEntityId: RegistryEntityId('target'),
        targetRegistryPath: 'target',
        targetEvidence: 'H2 Target owner → H3 Target heading; lines 11–20',
        targetText: 'Initial target value.',
        lineDiff: '- Original source value.\n+ Initial target value.',
        dependencyGraph: RegistryDependencyGraph(
          primaryEntityId: RegistryEntityId('source'),
          dependencyEdges: const [],
          directDependencyIds: const <RegistryEntityId>[],
          transitiveDependencyIds: const <RegistryEntityId>[],
          dependencyPaths: const <Iterable<RegistryEntityId>>[],
        ),
        affectedBranchPaths: const <String>[],
        unaffectedIdentityExplanations: const <String>[],
        semanticCandidateExplanations: const <String>[],
        conflictExplanations: const <String>[],
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
            revisionPrimaryEntityId: RegistryEntityId('target'),
            initialProblemStatement: 'Compare source and target.',
            initialWorkingContent: comparisonViewData.targetText,
            comparisonViewData: comparisonViewData,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final Finder revisionEditor = find.byKey(
        const Key('registry_operation_revision_content'),
      );
      await tester.scrollUntilVisible(
        revisionEditor,
        600.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(revisionEditor, 'Edited proposed value.');

      final Finder saveRevisionButton = find.byKey(
        const Key('registry_operation_save_revision'),
      );
      await tester.scrollUntilVisible(
        saveRevisionButton,
        600.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveRevisionButton);
      await tester.pumpAndSettle();

      final List<RegistryEngineeringOperationRevision> revisions =
          await persistence.loadEngineeringOperationRevisions();

      expect(revisions, hasLength(1));
      expect(revisions.single.originalValue, 'Original source value.');
      expect(revisions.single.proposedValue, 'Edited proposed value.');
      expect(revisions.single.workingContent, 'Edited proposed value.');
      expect(
        find.textContaining('Исходное значение: Original source value.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Предложенное значение: Edited proposed value.'),
        findsOneWidget,
      );
    },
  );

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

    Widget workspace({Iterable<RegistryEntityId>? revisionRelatedEntityIds}) {
      return MaterialApp(
        home: RegistryEngineeringOperationWorkspaceScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          createRegistryEngineeringOperation:
              CreateRegistryEngineeringOperation(),
          transitionRegistryEngineeringOperationStatus:
              TransitionRegistryEngineeringOperationStatus(),
          workSessionPersistence: persistence,
          revisionPrimaryEntityId: RegistryEntityId('primary'),
          revisionRelatedEntityIds: revisionRelatedEntityIds,
        ),
      );
    }

    await tester.pumpWidget(
      workspace(
        revisionRelatedEntityIds: <RegistryEntityId>[
          RegistryEntityId('related-001'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final Finder saveRevisionButton = find.byKey(
      const Key('registry_operation_save_revision'),
    );

    await tester.enterText(
      find.byKey(const Key('registry_operation_revision_content')),
      'Первая полная версия.',
    );
    await tester.scrollUntilVisible(
      saveRevisionButton,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 16,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveRevisionButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('registry_operation_revision_content')),
      'Вторая расширенная версия.',
    );
    await tester.scrollUntilVisible(
      saveRevisionButton,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 16,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveRevisionButton);
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

    final Finder restoredSaveRevisionButton = find.byKey(
      const Key('registry_operation_save_revision'),
    );
    await tester.enterText(
      find.byKey(const Key('registry_operation_revision_content')),
      'Третья версия после восстановления.',
    );
    await tester.scrollUntilVisible(
      restoredSaveRevisionButton,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 16,
    );
    await tester.pumpAndSettle();
    await tester.tap(restoredSaveRevisionButton);
    await tester.pumpAndSettle();

    final List<RegistryEngineeringOperationRevision> restoredRevisions =
        await persistence.loadEngineeringOperationRevisions();

    expect(restoredRevisions, hasLength(3));

    final RegistryEngineeringOperationRevision inheritedRevision =
        restoredRevisions.last;

    expect(inheritedRevision.revisionNumber, 3);
    expect(inheritedRevision.previousRevisionId, restoredRevisions[1].id);
    expect(inheritedRevision.primaryEntityId, RegistryEntityId('primary'));
    expect(inheritedRevision.relatedEntityIds, <RegistryEntityId>[
      RegistryEntityId('related-001'),
    ]);
  });

  testWidgets('restores semantic candidate decisions into next revision', (
    WidgetTester tester,
  ) async {
    const RegistryWorkSessionPersistence persistence =
        RegistryWorkSessionPersistence();

    final RegistryEngineeringOperation operation = RegistryEngineeringOperation(
      id: RegistryEngineeringOperationId('operation-semantic'),
      status: RegistryEngineeringOperationStatus.open,
      problemStatement: 'Resolve semantic candidate.',
    );
    final RegistryEngineeringOperationRevision revision =
        RegistryEngineeringOperationRevision(
          id: 'operation-semantic-revision-1',
          operationId: operation.id,
          revisionNumber: 1,
          workingContent: 'Saved working value.',
          previousRevisionId: null,
          primaryEntityId: RegistryEntityId('primary'),
          relatedEntityIds: const <RegistryEntityId>[],
          semanticCandidateDecisions: const <String, bool>{
            'candidate-a': false,
          },
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

    expect(
      find.textContaining('Решения по semantic candidates'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Отклонено как unrelated: candidate-a'),
      findsOneWidget,
    );

    final Finder semanticSaveRevisionButton = find.byKey(
      const Key('registry_operation_save_revision'),
    );
    await tester.enterText(
      find.byKey(const Key('registry_operation_revision_content')),
      'Next working value.',
    );
    await tester.scrollUntilVisible(
      semanticSaveRevisionButton,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 16,
    );
    await tester.pumpAndSettle();
    await tester.tap(semanticSaveRevisionButton);
    await tester.pumpAndSettle();

    final List<RegistryEngineeringOperationRevision> revisions =
        await persistence.loadEngineeringOperationRevisions();

    expect(revisions, hasLength(2));
    expect(revisions.last.semanticCandidateDecisions, const <String, bool>{
      'candidate-a': false,
    });
  });

  testWidgets('restored semantic candidate decisions satisfy readiness gate', (
    WidgetTester tester,
  ) async {
    const RegistryWorkSessionPersistence persistence =
        RegistryWorkSessionPersistence();

    final RegistryEngineeringOperation operation = RegistryEngineeringOperation(
      id: RegistryEngineeringOperationId('operation-semantic-gate'),
      status: RegistryEngineeringOperationStatus.open,
      problemStatement: 'Resolve semantic readiness gate.',
    );
    final RegistryEngineeringOperationRevision revision =
        RegistryEngineeringOperationRevision(
          id: 'operation-semantic-gate-revision-1',
          operationId: operation.id,
          revisionNumber: 1,
          workingContent: 'Saved working value.',
          previousRevisionId: null,
          primaryEntityId: RegistryEntityId('target'),
          relatedEntityIds: const <RegistryEntityId>[],
          semanticCandidateDecisions: const <String, bool>{
            'candidate-a': false,
          },
        );

    final RegistryOperationComparisonViewData comparisonViewData = (
      operationType: 'Service Intake comparison',
      projectAdapter: 'Helpy Service Intake',
      sourceRevision: 'source-revision',
      sourceHeading: 'Source heading',
      sourceEntityId: RegistryEntityId('source'),
      sourceRegistryPath: 'source',
      sourceEvidence: 'H2 Source owner → H3 Source heading; lines 1–10',
      sourceText: 'Original source value.',
      targetHeading: 'Target heading',
      targetEntityId: RegistryEntityId('target'),
      targetRegistryPath: 'target',
      targetEvidence: 'H2 Target owner → H3 Target heading; lines 11–20',
      targetText: 'Saved working value.',
      lineDiff: '- Original source value.\n+ Saved working value.',
      dependencyGraph: RegistryDependencyGraph(
        primaryEntityId: RegistryEntityId('target'),
        dependencyEdges: const [],
        directDependencyIds: const <RegistryEntityId>[],
        transitiveDependencyIds: const <RegistryEntityId>[],
        dependencyPaths: const <Iterable<RegistryEntityId>>[],
      ),
      affectedBranchPaths: const <String>[],
      unaffectedIdentityExplanations: const <String>[],
      semanticCandidateExplanations: const <String>['candidate-a'],
      conflictExplanations: const <String>[],
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
          revisionPrimaryEntityId: RegistryEntityId('target'),
          comparisonViewData: comparisonViewData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Semantic candidates unresolved'), findsNothing);

    final Finder proposalReviewButton = find.byKey(
      const Key('registry_operation_proposal_review_confirm'),
    );
    await tester.scrollUntilVisible(
      proposalReviewButton,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(proposalReviewButton);
    await tester.pumpAndSettle();

    final Finder statusDropdown = find.byKey(
      const Key('registry_engineering_operation_requested_status_dropdown'),
    );
    final Finder transitionButton = find.byKey(
      const Key('registry_engineering_operation_status_transition_button'),
    );

    await tester.scrollUntilVisible(
      statusDropdown,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('readyForDecision').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      transitionButton,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(transitionButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Semantic candidates unresolved'), findsNothing);
    final RegistryEngineeringOperation? transitionedOperation =
        await persistence.loadEngineeringOperation();

    expect(
      transitionedOperation?.status,
      RegistryEngineeringOperationStatus.readyForDecision,
    );
  });

  testWidgets('blocks readiness when comparison conflict is unresolved', (
    WidgetTester tester,
  ) async {
    const RegistryWorkSessionPersistence persistence =
        RegistryWorkSessionPersistence();

    final RegistryOperationComparisonViewData comparisonViewData = (
      operationType: 'Service Intake comparison',
      projectAdapter: 'Helpy Service Intake',
      sourceRevision: 'source-revision',
      sourceHeading: 'Source heading',
      sourceEntityId: RegistryEntityId('source'),
      sourceRegistryPath: 'source',
      sourceEvidence: 'H2 Source owner → H3 Source heading; lines 1–10',
      sourceText: 'Original source value.',
      targetHeading: 'Target heading',
      targetEntityId: RegistryEntityId('target'),
      targetRegistryPath: 'target',
      targetEvidence: 'H2 Target owner → H3 Target heading; lines 11–20',
      targetText: 'Initial target value.',
      lineDiff: '- Original source value.\n+ Initial target value.',
      dependencyGraph: RegistryDependencyGraph(
        primaryEntityId: RegistryEntityId('target'),
        dependencyEdges: const [],
        directDependencyIds: const <RegistryEntityId>[],
        transitiveDependencyIds: const <RegistryEntityId>[],
        dependencyPaths: const <Iterable<RegistryEntityId>>[],
      ),
      affectedBranchPaths: const <String>[],
      unaffectedIdentityExplanations: const <String>[],
      semanticCandidateExplanations: const <String>[],
      conflictExplanations: const <String>[
        'target: proposed value conflicts with existing approved wording',
      ],
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
          revisionPrimaryEntityId: RegistryEntityId('target'),
          initialProblemStatement: 'Compare source and target.',
          initialWorkingContent: comparisonViewData.targetText,
          comparisonViewData: comparisonViewData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder conflictSaveRevisionButton = find.byKey(
      const Key('registry_operation_save_revision'),
    );
    await tester.scrollUntilVisible(
      conflictSaveRevisionButton,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(conflictSaveRevisionButton);
    await tester.pumpAndSettle();

    final Finder proposalReviewButton = find.byKey(
      const Key('registry_operation_proposal_review_confirm'),
    );
    await tester.scrollUntilVisible(
      proposalReviewButton,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(proposalReviewButton);
    await tester.pumpAndSettle();

    final Finder statusDropdown = find.byKey(
      const Key('registry_engineering_operation_requested_status_dropdown'),
    );
    final Finder transitionButton = find.byKey(
      const Key('registry_engineering_operation_status_transition_button'),
    );

    await tester.scrollUntilVisible(
      statusDropdown,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('readyForDecision').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      transitionButton,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(transitionButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Conflict unresolved'), findsWidgets);

    final RegistryEngineeringOperation? operation = await persistence
        .loadEngineeringOperation();

    expect(operation?.status, RegistryEngineeringOperationStatus.open);
  });

  testWidgets('blocks readiness when comparison proposal is not reviewed', (
    WidgetTester tester,
  ) async {
    const RegistryWorkSessionPersistence persistence =
        RegistryWorkSessionPersistence();

    final RegistryOperationComparisonViewData comparisonViewData = (
      operationType: 'Service Intake comparison',
      projectAdapter: 'Helpy Service Intake',
      sourceRevision: 'source-revision',
      sourceHeading: 'Source heading',
      sourceEntityId: RegistryEntityId('source'),
      sourceRegistryPath: 'source',
      sourceEvidence: 'H2 Source owner → H3 Source heading; lines 1–10',
      sourceText: 'Original source value.',
      targetHeading: 'Target heading',
      targetEntityId: RegistryEntityId('target'),
      targetRegistryPath: 'target',
      targetEvidence: 'H2 Target owner → H3 Target heading; lines 11–20',
      targetText: 'Initial target value.',
      lineDiff: '- Original source value.\n+ Initial target value.',
      dependencyGraph: RegistryDependencyGraph(
        primaryEntityId: RegistryEntityId('target'),
        dependencyEdges: const [],
        directDependencyIds: const <RegistryEntityId>[],
        transitiveDependencyIds: const <RegistryEntityId>[],
        dependencyPaths: const <Iterable<RegistryEntityId>>[],
      ),
      affectedBranchPaths: const <String>[],
      unaffectedIdentityExplanations: const <String>[],
      semanticCandidateExplanations: const <String>[],
      conflictExplanations: const <String>[],
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
          revisionPrimaryEntityId: RegistryEntityId('target'),
          initialProblemStatement: 'Compare source and target.',
          initialWorkingContent: comparisonViewData.targetText,
          comparisonViewData: comparisonViewData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder proposalSaveRevisionButton = find.byKey(
      const Key('registry_operation_save_revision'),
    );
    await tester.scrollUntilVisible(
      proposalSaveRevisionButton,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(proposalSaveRevisionButton);
    await tester.pumpAndSettle();

    final Finder statusDropdown = find.byKey(
      const Key('registry_engineering_operation_requested_status_dropdown'),
    );
    final Finder transitionButton = find.byKey(
      const Key('registry_engineering_operation_status_transition_button'),
    );

    await tester.scrollUntilVisible(
      statusDropdown,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('readyForDecision').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      transitionButton,
      600.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(transitionButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Proposal not reviewed'), findsWidgets);

    final RegistryEngineeringOperation? operation = await persistence
        .loadEngineeringOperation();

    expect(operation?.status, RegistryEngineeringOperationStatus.open);
  });

  for (final RegistryEngineeringOperationStatus terminalStatus
      in <RegistryEngineeringOperationStatus>[
        RegistryEngineeringOperationStatus.decided,
        RegistryEngineeringOperationStatus.cancelled,
      ]) {
    testWidgets(
      'restores ${terminalStatus.name} workspace as revision read-only',
      (WidgetTester tester) async {
        bool workSessionCleared = false;

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
              onWorkSessionCleared: () {
                workSessionCleared = true;
              },
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

        if (terminalStatus == RegistryEngineeringOperationStatus.decided) {
          expect(
            find.text('Решение инженера:\nApprove canonical wording.'),
            findsWidgets,
            reason:
                'restored decided workspace exposes engineer decision evidence',
          );
        } else {
          expect(find.textContaining('Решение инженера'), findsNothing);
        }

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
        await tester.tap(find.text('Начать'));
        await tester.pumpAndSettle();

        expect(workSessionCleared, isTrue);
        expect(
          find.text('Сначала выберите источник и цель изменения.'),
          findsOneWidget,
        );
        expect(await persistence.loadEngineeringOperation(), isNull);
        expect(await persistence.loadEngineeringOperationRevisions(), isEmpty);
      },
    );
  }
}
