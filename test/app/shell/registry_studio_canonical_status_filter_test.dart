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
  testWidgets(
    'filters Registry by canonical status and restores the selection',
    (WidgetTester tester) async {
      final RegistrySnapshot snapshot = _snapshot();
      final RegistryNode targetNode = snapshot.roots.single.children.single;

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

      final Finder targetRow = find.byKey(
        ValueKey<String>(targetNode.id.value),
      );

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

      expect(tester.widget<ListTile>(neutralFilter).selected, isFalse);

      await tester.tap(exactFilter);
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

      expect(restoredFilterScrollable, findsOneWidget);

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

      expect(restoredNeutralFilter, findsOneWidget);

      await tester.tap(restoredNeutralFilter);

      await tester.pumpAndSettle();

      expect(targetRow, findsOneWidget);
      expect(
        revisionStateStore.state?.canonicalStatusFilter,
        'unclassifiedNeutral',
      );
    },
  );
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
        endLine: 4,
      ),
    ],
    content: 'Canonical candidate phrase.',
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
        endLine: 4,
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
        'Canonical candidate phrase.',
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

  final CanonicalBusinessTextCandidate candidate =
      CanonicalBusinessTextCandidate(
        identity: 'candidate-domain-rule',
        nodeId: targetNode.id,
        businessScopeOwnerId: targetNode.businessScopeOwnerId!,
        path: targetNode.path,
        sourceEvidence: targetNode.sourceEvidence,
        kind: CanonicalBusinessTextCandidateKind.paragraph,
        rawText: targetNode.content,
        text: targetNode.content,
        directContentLine: 1,
      );

  final CanonicalBusinessTextClassification classification =
      CanonicalBusinessTextClassification(
        candidate: candidate,
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
      candidates: <CanonicalBusinessTextCandidate>[candidate],
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
      classifications: <CanonicalBusinessTextClassification>[classification],
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
