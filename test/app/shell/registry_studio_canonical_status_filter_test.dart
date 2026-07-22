import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/bootstrap/registry_studio_application.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_analysis_session_runner.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_analysis_result.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import 'package:helpy_translator/registry_studio/maintenance/history/domain/entities/registry_analysis_history_entry.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  testWidgets('explains canonical counts and exposes classified formulations', (
    WidgetTester tester,
  ) async {
    final RegistrySnapshot snapshot = _snapshot();
    final RegistryNode rootNode = snapshot.roots.single;
    final RegistryNode targetNode = rootNode.children.single;

    final _RevisionStateStore revisionStateStore = _RevisionStateStore();
    final _SnapshotLoader firstLoader = _SnapshotLoader(snapshot);

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: firstLoader,
        registrySnapshotRefreshLoader: firstLoader,
        registrySnapshotRevisionLoader: firstLoader,
        registryRevisionStateStore: revisionStateStore,
        registryAnalysisHistoryStore: _HistoryStore(),
        canonicalBusinessTextAnalysisSessionRunner: _SessionRunner(
          _result(snapshot: snapshot, targetNode: targetNode),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder targetRow = find.byKey(ValueKey<String>(targetNode.id.value));

    expect(targetRow, findsOneWidget);

    final Finder filterButton = find.byKey(
      const ValueKey<String>('registry-view-filter-button'),
    );

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    final Finder filterSheet = find.byKey(
      const ValueKey<String>('registry-view-filter-sheet'),
    );

    final Finder filterScrollable = find.descendant(
      of: filterSheet,
      matching: find.byType(Scrollable),
    );

    expect(filterScrollable, findsOneWidget);

    final Finder allCanonicalFilter = find.byKey(
      const ValueKey<String>('registry-canonical-status-filter-all'),
    );

    expect(allCanonicalFilter, findsOneWidget);

    final Finder allCanonicalCount = find.descendant(
      of: allCanonicalFilter,
      matching: find.byKey(
        const ValueKey<String>('registry-canonical-status-count-all'),
      ),
    );

    expect(
      tester.widget<Text>(allCanonicalCount).data,
      'Формулировок: 2 · узлов: 1',
    );

    final Finder neutralFilter = find.byKey(
      const ValueKey<String>(
        'registry-canonical-status-filter-unclassifiedNeutral',
      ),
    );

    await tester.scrollUntilVisible(
      neutralFilter,
      300,
      scrollable: filterScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    final Finder exactFilter = find.byKey(
      const ValueKey<String>('registry-canonical-status-filter-exact'),
    );

    expect(neutralFilter, findsOneWidget);
    expect(exactFilter, findsOneWidget);

    final Finder neutralCount = find.descendant(
      of: neutralFilter,
      matching: find.byKey(
        const ValueKey<String>(
          'registry-canonical-status-count-unclassifiedNeutral',
        ),
      ),
    );

    final Finder exactCount = find.descendant(
      of: exactFilter,
      matching: find.byKey(
        const ValueKey<String>('registry-canonical-status-count-exact'),
      ),
    );

    expect(
      tester.widget<Text>(neutralCount).data,
      'Формулировок: 2 · узлов: 1',
    );
    expect(tester.widget<Text>(exactCount).data, 'Формулировок: 0 · узлов: 0');

    await tester.tap(exactFilter);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(targetRow, findsNothing);
    expect(revisionStateStore.state?.canonicalStatusFilter, 'exact');
    expect(revisionStateStore.state?.registryViewFilter, 'all');

    final Finder activeFilterBadge = find.ancestor(
      of: filterButton,
      matching: find.byType(Badge),
    );

    expect(activeFilterBadge, findsOneWidget);
    expect(tester.widget<Badge>(activeFilterBadge).isLabelVisible, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final _SnapshotLoader restartLoader = _SnapshotLoader(snapshot);

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: restartLoader,
        registrySnapshotRefreshLoader: restartLoader,
        registrySnapshotRevisionLoader: restartLoader,
        registryRevisionStateStore: revisionStateStore,
        registryAnalysisHistoryStore: _HistoryStore(),
        canonicalBusinessTextAnalysisSessionRunner: _SessionRunner(
          _result(snapshot: snapshot, targetNode: targetNode),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(targetRow, findsNothing);

    final Finder restoredFilterButton = find.byKey(
      const ValueKey<String>('registry-view-filter-button'),
    );

    expect(
      tester.widget<IconButton>(restoredFilterButton).tooltip,
      contains('Canonical: Exact'),
    );

    await tester.tap(restoredFilterButton);
    await tester.pumpAndSettle();

    final Finder restoredFilterSheet = find.byKey(
      const ValueKey<String>('registry-view-filter-sheet'),
    );

    final Finder restoredFilterScrollable = find.descendant(
      of: restoredFilterSheet,
      matching: find.byType(Scrollable),
    );

    final Finder restoredExactFilter = find.byKey(
      const ValueKey<String>('registry-canonical-status-filter-exact'),
    );

    await tester.scrollUntilVisible(
      restoredExactFilter,
      300,
      scrollable: restoredFilterScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<ListTile>(restoredExactFilter).selected, isTrue);

    final Finder restoredNeutralFilter = find.byKey(
      const ValueKey<String>(
        'registry-canonical-status-filter-unclassifiedNeutral',
      ),
    );

    await tester.scrollUntilVisible(
      restoredNeutralFilter,
      -300,
      scrollable: restoredFilterScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    await tester.tap(restoredNeutralFilter);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(targetRow, findsOneWidget);
    expect(
      revisionStateStore.state?.canonicalStatusFilter,
      'unclassifiedNeutral',
    );

    final Finder nodeCanonicalSummary = find.byKey(
      ValueKey<String>(
        'registry-node-canonical-summary-${targetNode.id.value}',
      ),
    );

    expect(nodeCanonicalSummary, findsOneWidget);
    expect(
      tester.widget<Text>(nodeCanonicalSummary).data,
      'Canonical: Без точного канонического совпадения · '
      'формулировок: 2',
    );

    await tester.tap(targetRow);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('registry-selected-canonical-analysis'),
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'registry-selected-analysis-'
          'canonical-status:candidate-domain-rule-1',
        ),
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'registry-selected-analysis-'
          'canonical-status:candidate-domain-rule-2',
        ),
      ),
      findsOneWidget,
    );

    expect(find.text('Место: строка 1 внутри блока'), findsOneWidget);
    expect(find.text('Место: строка 2 внутри блока'), findsOneWidget);

    expect(
      find.text('Причина: Точное каноническое совпадение не найдено'),
      findsNWidgets(2),
    );

    expect(find.text('Canonical candidate phrase.'), findsNWidgets(2));
    expect(find.text('Second canonical candidate phrase.'), findsNWidgets(2));

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SelectableText &&
            widget.data ==
                'Причина: '
                    'Точное каноническое совпадение не найдено',
      ),
      findsNWidgets(2),
    );

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SelectableText &&
            widget.data == 'Source evidence: registry.md, строки 2–5',
      ),
      findsNWidgets(2),
    );

    final Finder canonicalNavigation = find.byKey(
      const ValueKey<String>('registry-selected-canonical-navigation'),
    );

    final Finder canonicalPosition = find.byKey(
      const ValueKey<String>('registry-selected-canonical-position'),
    );

    expect(canonicalNavigation, findsOneWidget);
    expect(tester.widget<Text>(canonicalPosition).data, '1/2');

    final Finder firstActiveCanonicalLine = find.byKey(
      const ValueKey<String>('registry-selected-canonical-line-active-1'),
    );

    expect(firstActiveCanonicalLine, findsOneWidget);

    final Container firstActiveLineContainer = tester.widget<Container>(
      firstActiveCanonicalLine,
    );

    final BoxDecoration firstActiveLineDecoration =
        firstActiveLineContainer.decoration! as BoxDecoration;

    final BuildContext firstActiveLineContext = tester.element(
      firstActiveCanonicalLine,
    );

    expect(
      firstActiveLineDecoration.color,
      Theme.of(firstActiveLineContext).colorScheme.tertiaryContainer,
    );

    expect(
      firstActiveLineDecoration.color,
      isNot(Theme.of(firstActiveLineContext).colorScheme.primaryContainer),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'registry-selected-analysis-show-'
          'canonical-status:candidate-domain-rule-2',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('registry-selected-canonical-line-active-2'),
      ),
      findsOneWidget,
    );

    expect(tester.widget<Text>(canonicalPosition).data, '2/2');

    await tester.tap(
      find.byKey(
        const ValueKey<String>('registry-selected-canonical-previous'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('registry-selected-canonical-line-active-1'),
      ),
      findsOneWidget,
    );

    expect(tester.widget<Text>(canonicalPosition).data, '1/2');

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-selected-block-back')),
    );
    await tester.pumpAndSettle();

    final Finder rootRow = find.byKey(ValueKey<String>(rootNode.id.value));

    expect(rootRow, findsOneWidget);
    expect(targetRow, findsOneWidget);

    final Finder rootCanonicalSummary = find.byKey(
      ValueKey<String>('registry-node-canonical-summary-${rootNode.id.value}'),
    );

    expect(rootCanonicalSummary, findsOneWidget);
    expect(
      tester.widget<Text>(rootCanonicalSummary).data,
      'Canonical: Без точного канонического совпадения · '
      'формулировок: 2',
    );

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    final Finder rootFilter = find.byKey(
      const ValueKey<String>('registry-view-filter-roots'),
    );

    expect(rootFilter, findsOneWidget);

    await tester.tap(rootFilter);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(rootRow, findsOneWidget);
    expect(targetRow, findsNothing);

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    final Finder rootScopedSheet = find.byKey(
      const ValueKey<String>('registry-view-filter-sheet'),
    );

    final Finder rootScopedScrollable = find.descendant(
      of: rootScopedSheet,
      matching: find.byType(Scrollable),
    );

    final Finder rootScopedNeutralFilter = find.byKey(
      const ValueKey<String>(
        'registry-canonical-status-filter-unclassifiedNeutral',
      ),
    );

    await tester.scrollUntilVisible(
      rootScopedNeutralFilter,
      300,
      scrollable: rootScopedScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    final Finder rootScopedNeutralCount = find.descendant(
      of: rootScopedNeutralFilter,
      matching: find.byKey(
        const ValueKey<String>(
          'registry-canonical-status-count-unclassifiedNeutral',
        ),
      ),
    );

    expect(
      tester.widget<Text>(rootScopedNeutralCount).data,
      'Формулировок: 2 · узлов: 1',
    );

    final Finder branchFilter = find.byKey(
      const ValueKey<String>('registry-view-filter-branches'),
    );

    await tester.scrollUntilVisible(
      branchFilter,
      -300,
      scrollable: rootScopedScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    await tester.tap(branchFilter);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(rootRow, findsOneWidget);
    expect(targetRow, findsNothing);

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    final Finder branchScopedSheet = find.byKey(
      const ValueKey<String>('registry-view-filter-sheet'),
    );

    final Finder branchScopedScrollable = find.descendant(
      of: branchScopedSheet,
      matching: find.byType(Scrollable),
    );

    final Finder branchScopedNeutralFilter = find.byKey(
      const ValueKey<String>(
        'registry-canonical-status-filter-unclassifiedNeutral',
      ),
    );

    await tester.scrollUntilVisible(
      branchScopedNeutralFilter,
      300,
      scrollable: branchScopedScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    final Finder branchScopedNeutralCount = find.descendant(
      of: branchScopedNeutralFilter,
      matching: find.byKey(
        const ValueKey<String>(
          'registry-canonical-status-count-unclassifiedNeutral',
        ),
      ),
    );

    expect(
      tester.widget<Text>(branchScopedNeutralCount).data,
      'Формулировок: 2 · узлов: 1',
    );

    final Finder leafFilter = find.byKey(
      const ValueKey<String>('registry-view-filter-leaves'),
    );

    await tester.scrollUntilVisible(
      leafFilter,
      -300,
      scrollable: branchScopedScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    await tester.tap(leafFilter);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(rootRow, findsNothing);
    expect(targetRow, findsOneWidget);

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    final Finder leafScopedSheet = find.byKey(
      const ValueKey<String>('registry-view-filter-sheet'),
    );

    final Finder leafScopedScrollable = find.descendant(
      of: leafScopedSheet,
      matching: find.byType(Scrollable),
    );

    final Finder leafScopedNeutralFilter = find.byKey(
      const ValueKey<String>(
        'registry-canonical-status-filter-unclassifiedNeutral',
      ),
    );

    await tester.scrollUntilVisible(
      leafScopedNeutralFilter,
      300,
      scrollable: leafScopedScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    final Finder leafScopedNeutralCount = find.descendant(
      of: leafScopedNeutralFilter,
      matching: find.byKey(
        const ValueKey<String>(
          'registry-canonical-status-count-unclassifiedNeutral',
        ),
      ),
    );

    expect(
      tester.widget<Text>(leafScopedNeutralCount).data,
      'Формулировок: 2 · узлов: 1',
    );

    expect(revisionStateStore.state?.registryViewFilter, 'leaves');
    expect(
      revisionStateStore.state?.canonicalStatusFilter,
      'unclassifiedNeutral',
    );
  });
  testWidgets('keeps the Registry filter sheet open while selections update', (
    WidgetTester tester,
  ) async {
    final RegistrySnapshot snapshot = _snapshot();
    final RegistryNode targetNode = snapshot.roots.single.children.single;

    final _RevisionStateStore revisionStateStore = _RevisionStateStore();

    final _SnapshotLoader loader = _SnapshotLoader(snapshot);

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: revisionStateStore,
        registryAnalysisHistoryStore: _HistoryStore(),
        canonicalBusinessTextAnalysisSessionRunner: _SessionRunner(
          _result(snapshot: snapshot, targetNode: targetNode),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder filterButton = find.byKey(
      const ValueKey<String>('registry-view-filter-button'),
    );

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    final Finder filterSheet = find.byKey(
      const ValueKey<String>('registry-view-filter-sheet'),
    );

    final Finder filterScrollable = find.descendant(
      of: filterSheet,
      matching: find.byType(Scrollable),
    );

    expect(filterSheet, findsOneWidget);
    expect(filterScrollable, findsOneWidget);

    final Finder rootsFilter = find.byKey(
      const ValueKey<String>('registry-view-filter-roots'),
    );

    await tester.tap(rootsFilter);
    await tester.pumpAndSettle();

    expect(filterSheet, findsOneWidget);
    expect(tester.widget<ListTile>(rootsFilter).selected, isTrue);
    expect(revisionStateStore.state?.registryViewFilter, 'roots');

    final Finder exactFilter = find.byKey(
      const ValueKey<String>('registry-canonical-status-filter-exact'),
    );

    await tester.scrollUntilVisible(
      exactFilter,
      300,
      scrollable: filterScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    await tester.tap(exactFilter);
    await tester.pumpAndSettle();

    expect(filterSheet, findsOneWidget);
    expect(tester.widget<ListTile>(exactFilter).selected, isTrue);
    expect(revisionStateStore.state?.canonicalStatusFilter, 'exact');

    final Finder neutralFilter = find.byKey(
      const ValueKey<String>(
        'registry-canonical-status-filter-'
        'unclassifiedNeutral',
      ),
    );

    await tester.scrollUntilVisible(
      neutralFilter,
      -300,
      scrollable: filterScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    await tester.tap(neutralFilter);
    await tester.pumpAndSettle();

    expect(filterSheet, findsOneWidget);
    expect(tester.widget<ListTile>(neutralFilter).selected, isTrue);
    expect(tester.widget<ListTile>(exactFilter).selected, isFalse);
    expect(
      revisionStateStore.state?.canonicalStatusFilter,
      'unclassifiedNeutral',
    );

    final Finder leavesFilter = find.byKey(
      const ValueKey<String>('registry-view-filter-leaves'),
    );

    await tester.scrollUntilVisible(
      leavesFilter,
      -300,
      scrollable: filterScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    await tester.tap(leavesFilter);
    await tester.pumpAndSettle();

    expect(filterSheet, findsOneWidget);
    expect(tester.widget<ListTile>(leavesFilter).selected, isTrue);
    expect(revisionStateStore.state?.registryViewFilter, 'leaves');

    await tester.scrollUntilVisible(
      rootsFilter,
      -300,
      scrollable: filterScrollable,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<ListTile>(rootsFilter).selected, isFalse);

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(filterSheet, findsNothing);
    expect(revisionStateStore.state?.registryViewFilter, 'leaves');
    expect(
      revisionStateStore.state?.canonicalStatusFilter,
      'unclassifiedNeutral',
    );
  });
}

RegistrySnapshot _snapshot() {
  const String fingerprint = 'git-blob:registry';

  final RegistryPath rootPath = RegistryPath(const <String>['Registry']);

  final RegistryPath targetPath = RegistryPath(const <String>[
    'Registry',
    'Domain',
  ]);

  final RegistryNode targetNode = RegistryNode(
    id: RegistryNodeId('node-domain'),
    kindId: 'project.registry.heading.2',
    path: targetPath,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: fingerprint,
        headingPath: targetPath.segments,
        startLine: 2,
        endLine: 5,
      ),
    ],
    content:
        'Canonical candidate phrase.\n'
        'Second canonical candidate phrase.',
    businessScopeOwnerId: RegistryEntityId('owner-domain'),
    children: const <RegistryNode>[],
  );

  final RegistryNode root = RegistryNode(
    id: RegistryNodeId('node-root'),
    kindId: 'project.registry.heading.1',
    path: rootPath,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: fingerprint,
        headingPath: rootPath.segments,
        startLine: 1,
        endLine: 5,
      ),
    ],
    content: '',
    businessScopeOwnerId: null,
    children: <RegistryNode>[targetNode],
  );

  return RegistrySnapshot(
    projectId: 'project',
    projectAdapterId: 'project.registry.adapter',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'registry-revision',
    sourceSnapshotFingerprint: fingerprint,
    sourceContent:
        '# Registry\n'
        '## Domain\n'
        'Canonical candidate phrase.\n'
        'Second canonical candidate phrase.',
    roots: <RegistryNode>[root],
  );
}

CanonicalBusinessTextAnalysisResult _result({
  required RegistrySnapshot snapshot,
  required RegistryNode targetNode,
}) {
  final CanonicalDictionary dictionary = CanonicalDictionary(
    dictionaryId: 'DICTIONARY',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceContent: 'dictionary source',
    beginMarkerLine: 1,
    endMarkerLine: 20,
    collections: <CanonicalDictionaryCollection>[
      CanonicalDictionaryCollection(
        id: 'canonical.phrases',
        entryType: 'phrase',
        status: 'APPROVED / STORED',
        content: '- Other canonical phrase.',
        startLine: 2,
        endLine: 19,
        entries: const [],
      ),
    ],
  );

  final CanonicalBusinessTextCandidate firstCandidate =
      CanonicalBusinessTextCandidate(
        identity: 'candidate-domain-rule-1',
        nodeId: targetNode.id,
        businessScopeOwnerId: targetNode.businessScopeOwnerId!,
        path: targetNode.path,
        sourceEvidence: targetNode.sourceEvidence,
        kind: CanonicalBusinessTextCandidateKind.paragraph,
        rawText: 'Canonical candidate phrase.',
        text: 'Canonical candidate phrase.',
        directContentLine: 1,
      );

  final CanonicalBusinessTextCandidate secondCandidate =
      CanonicalBusinessTextCandidate(
        identity: 'candidate-domain-rule-2',
        nodeId: targetNode.id,
        businessScopeOwnerId: targetNode.businessScopeOwnerId!,
        path: targetNode.path,
        sourceEvidence: targetNode.sourceEvidence,
        kind: CanonicalBusinessTextCandidateKind.paragraph,
        rawText: 'Second canonical candidate phrase.',
        text: 'Second canonical candidate phrase.',
        directContentLine: 2,
      );

  final CanonicalBusinessTextClassification firstClassification =
      CanonicalBusinessTextClassification(
        candidate: firstCandidate,
        status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        reason:
            CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
      );

  final CanonicalBusinessTextClassification secondClassification =
      CanonicalBusinessTextClassification(
        candidate: secondCandidate,
        status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        reason:
            CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
      );

  return CanonicalBusinessTextAnalysisResult(
    candidates: CanonicalBusinessTextCandidateIndex(
      projectId: snapshot.projectId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: snapshot.sourceRevision,
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      candidates: <CanonicalBusinessTextCandidate>[
        firstCandidate,
        secondCandidate,
      ],
    ),
    classifications: CanonicalBusinessTextClassificationIndex(
      projectId: snapshot.projectId,
      candidateSourceDocumentPath: snapshot.sourceDocumentPath,
      candidateSourceRevision: snapshot.sourceRevision,
      candidateSourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      dictionaryId: dictionary.dictionaryId,
      dictionaryVersion: dictionary.version,
      dictionarySourceRevision: dictionary.sourceRevision,
      dictionarySourceSnapshotFingerprint: dictionary.sourceSnapshotFingerprint,
      classifications: <CanonicalBusinessTextClassification>[
        firstClassification,
        secondClassification,
      ],
    ),
    dictionary: dictionary,
  );
}

final class _SnapshotLoader
    implements
        RegistrySnapshotLoader,
        RegistrySnapshotRefreshLoader,
        RegistrySnapshotRevisionLoader {
  const _SnapshotLoader(this.snapshot);

  final RegistrySnapshot snapshot;

  @override
  Future<RegistrySnapshot> loadSnapshot() async => snapshot;

  @override
  Future<RegistrySnapshot> loadSnapshotAfterRevision(
    String sourceRevision,
  ) async => snapshot;

  @override
  Future<RegistrySnapshot> loadSnapshotAtRevision(
    String sourceRevision,
  ) async => snapshot;
}

final class _RevisionStateStore implements RegistryRevisionStateStore {
  RegistryRevisionState? state;

  @override
  Future<RegistryRevisionState?> loadRevisionState() async => state;

  @override
  Future<void> saveRevisionState(RegistryRevisionState state) async {
    this.state = state;
  }
}

final class _HistoryStore implements RegistryAnalysisHistoryStore {
  @override
  Future<List<RegistryAnalysisHistoryEntry>> loadHistory() async {
    return const <RegistryAnalysisHistoryEntry>[];
  }

  @override
  Future<void> appendHistoryEntry(RegistryAnalysisHistoryEntry entry) async {}
}

final class _SessionRunner
    implements CanonicalBusinessTextAnalysisSessionRunner {
  const _SessionRunner(this.result);

  final CanonicalBusinessTextAnalysisResult result;

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis(
    RegistrySnapshot snapshot,
  ) async => result;
}
