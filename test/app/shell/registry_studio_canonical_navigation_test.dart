import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/shell/registry_studio_shell.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_analysis_session_runner.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_analysis_result.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_analysis_status_action.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_analysis_view.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_classification_details.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import 'package:helpy_translator/registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import 'package:helpy_translator/registry_studio/maintenance/history/domain/entities/registry_analysis_history_entry.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  testWidgets('opens the exact Registry block from canonical classification', (
    WidgetTester tester,
  ) async {
    final RegistrySnapshot snapshot = _snapshot();
    final RegistryNode targetNode = snapshot.roots.single.children.single;

    final CanonicalBusinessTextAnalysisResult result = _result(
      snapshot: snapshot,
      targetNode: targetNode,
    );

    final _RevisionStateStore revisionStateStore = _RevisionStateStore();

    await tester.pumpWidget(
      MaterialApp(
        home: RegistryStudioShell(
          canonicalBusinessTextAnalysisSessionRunner: _SessionRunner(result),
          registrySnapshotLoader: _SnapshotLoader(snapshot),
          registrySnapshotRefreshLoader: _SnapshotRefreshLoader(),
          registrySnapshotRevisionLoader: _SnapshotRevisionLoader(),
          registryRevisionStateStore: revisionStateStore,
          registryAnalysisHistoryStore: _AnalysisHistoryStore(),
          registrySnapshotComparator: const RegistrySnapshotComparator(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder statusAction = find.byKey(
      CanonicalBusinessTextAnalysisStatusAction.actionKey,
    );

    expect(statusAction, findsOneWidget);

    await tester.tap(statusAction);
    await tester.pumpAndSettle();

    expect(
      find.byKey(CanonicalBusinessTextAnalysisView.viewKey),
      findsOneWidget,
    );

    final Finder classificationRow = find.byKey(
      const ValueKey<String>(
        'canonical-business-text-analysis-row-'
        'candidate-domain-rule',
      ),
    );

    expect(classificationRow, findsOneWidget);

    await tester.tap(classificationRow);
    await tester.pumpAndSettle();

    final Finder details = find.byKey(
      CanonicalBusinessTextClassificationDetails.sheetKey,
    );

    expect(details, findsOneWidget);

    final Finder openRegistry = find.byKey(
      CanonicalBusinessTextClassificationDetails.openRegistryKey,
    );

    await tester.scrollUntilVisible(
      openRegistry,
      300,
      scrollable: find
          .descendant(of: details, matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();

    await tester.tap(openRegistry);
    await tester.pumpAndSettle();

    expect(find.byKey(CanonicalBusinessTextAnalysisView.viewKey), findsNothing);

    expect(details, findsNothing);

    expect(revisionStateStore.state?.openRegistryNodeId, targetNode.id);
    expect(revisionStateStore.state?.openRegistryPath, targetNode.path);
    expect(revisionStateStore.state?.selectedProblemIndex, isNull);

    expect(
      find.text('RegistryPath: Registry → Domain'),
      findsAtLeastNWidgets(1),
    );

    await tester.pumpWidget(const SizedBox.shrink());
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
        endLine: 4,
      ),
    ],
    content: 'Canonical phrase.',
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
        'Canonical phrase.',
    roots: <RegistryNode>[root],
  );
}

CanonicalBusinessTextAnalysisResult _result({
  required RegistrySnapshot snapshot,
  required RegistryNode targetNode,
}) {
  final CanonicalPhraseEntry phrase = CanonicalPhraseEntry(
    identity: 'canonical.phrases::canonical-phrase',
    collectionId: 'canonical.phrases',
    phrase: 'Canonical phrase.',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceStartLine: 10,
    sourceEndLine: 10,
  );

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
        content: '- Canonical phrase.',
        startLine: 2,
        endLine: 19,
        entries: <CanonicalPhraseEntry>[phrase],
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
        status: CanonicalBusinessTextClassificationStatus.exact,
        reason:
            CanonicalBusinessTextClassificationReason.singleExactUniversalMatch,
        matchedCanonicalEntries: <CanonicalPhraseEntry>[phrase],
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

final class _SessionRunner
    implements CanonicalBusinessTextAnalysisSessionRunner {
  _SessionRunner(this.result);

  final CanonicalBusinessTextAnalysisResult result;

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis(
    RegistrySnapshot snapshot,
  ) async {
    return result;
  }
}

final class _SnapshotLoader implements RegistrySnapshotLoader {
  _SnapshotLoader(this.snapshot);

  final RegistrySnapshot snapshot;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #loadSnapshot) {
      return Future<RegistrySnapshot>.value(snapshot);
    }

    return super.noSuchMethod(invocation);
  }
}

final class _SnapshotRefreshLoader implements RegistrySnapshotRefreshLoader {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

final class _SnapshotRevisionLoader implements RegistrySnapshotRevisionLoader {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

final class _RevisionStateStore implements RegistryRevisionStateStore {
  RegistryRevisionState? state;

  @override
  Future<RegistryRevisionState?> loadRevisionState() async {
    return state;
  }

  @override
  Future<void> saveRevisionState(RegistryRevisionState state) async {
    this.state = state;
  }
}

final class _AnalysisHistoryStore implements RegistryAnalysisHistoryStore {
  @override
  Future<List<RegistryAnalysisHistoryEntry>> loadHistory() async {
    return const <RegistryAnalysisHistoryEntry>[];
  }

  @override
  Future<void> appendHistoryEntry(RegistryAnalysisHistoryEntry entry) async {}
}
