import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/bootstrap/registry_studio_application.dart';
import 'package:helpy_translator/app/shell/registry_studio_shell.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
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
import 'package:helpy_translator/registry_studio/registry/presentation/registry_explorer_cubit.dart';

void main() {
  late RegistrySnapshot snapshot;

  setUp(() {
    const String documentPath = 'registry.md';
    const String fingerprint =
        'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    final RegistryNode child = RegistryNode(
      id: RegistryNodeId('project.registry.node.000002'),
      kindId: 'project.registry.heading.2',
      path: RegistryPath(const <String>['Registry', 'Domain']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry', 'Domain'],
          startLine: 3,
          endLine: 4,
        ),
      ],
      content: 'Domain content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode root = RegistryNode(
      id: RegistryNodeId('project.registry.node.000001'),
      kindId: 'project.registry.heading.1',
      path: RegistryPath(const <String>['Registry']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 4,
        ),
      ],
      content: 'Root content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[child],
    );

    snapshot = RegistrySnapshot(
      projectId: 'project',
      projectAdapterId: 'project.registry.adapter.v1',
      sourceDocumentPath: documentPath,
      sourceRevision: '1111111111111111111111111111111111111111',
      sourceSnapshotFingerprint: fingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n'
          '## Domain\n'
          'Domain content.\n',
      roots: <RegistryNode>[root],
    );
  });

  group('RegistryStudioWorkspaceCubit', () {
    test('starts in Registry Studio and emits only actual changes', () async {
      final RegistryStudioWorkspaceCubit cubit = RegistryStudioWorkspaceCubit();

      final Future<List<RegistryStudioWorkspace>> emittedStates = cubit.stream
          .toList();

      expect(cubit.state, RegistryStudioWorkspace.registryStudio);

      cubit.select(RegistryStudioWorkspace.translator);
      cubit.select(RegistryStudioWorkspace.translator);

      await cubit.close();

      expect(await emittedStates, <RegistryStudioWorkspace>[
        RegistryStudioWorkspace.translator,
      ]);
    });
  });

  test(
    'tracks the previous exact Registry revision only after manual refresh',
    () async {
      final RegistrySnapshot updatedSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: '2222222222222222222222222222222222222222',
        sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        sourceContent: snapshot.sourceContent,
        roots: snapshot.roots,
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () async => snapshot,
            () async => updatedSnapshot,
            () async => updatedSnapshot,
          ]);

      final _MemoryRegistryRevisionStateStore store =
          _MemoryRegistryRevisionStateStore();

      final _MemoryRegistryAnalysisHistoryStore historyStore =
          _MemoryRegistryAnalysisHistoryStore();

      final RegistryExplorerCubit cubit = RegistryExplorerCubit(
        snapshotLoader: loader,
        snapshotRefreshLoader: loader,
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
        analysisHistoryStore: historyStore,
        snapshotComparator: const RegistrySnapshotComparator(),
      );

      addTearDown(cubit.close);

      await cubit.restore();

      RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.snapshot, same(snapshot));
      expect(loaded.previousSnapshot, isNull);
      expect(loader.loadCount, 1);
      expect(loader.requestedRevisions, isEmpty);
      expect(store.loadCount, 1);
      expect(store.saveCount, 1);
      expect(store.state?.currentRevision, snapshot.sourceRevision);
      expect(store.state?.previousRevision, isNull);

      expect(historyStore.entries, hasLength(1));
      final RegistryAnalysisHistoryEntry initialHistoryEntry =
          historyStore.entries.single;
      expect(initialHistoryEntry.projectId, snapshot.projectId);
      expect(initialHistoryEntry.projectAdapterId, snapshot.projectAdapterId);
      expect(
        initialHistoryEntry.sourceDocumentPath,
        snapshot.sourceDocumentPath,
      );
      expect(initialHistoryEntry.sourceRevision, snapshot.sourceRevision);
      expect(
        initialHistoryEntry.sourceSnapshotFingerprint,
        snapshot.sourceSnapshotFingerprint,
      );
      expect(initialHistoryEntry.previousRevision, isNull);
      expect(initialHistoryEntry.cleanBaselineRevision, isNull);
      expect(initialHistoryEntry.previousChangeCount, 0);
      expect(initialHistoryEntry.cleanBaselineChangeCount, 0);
      expect(initialHistoryEntry.problemCount, 0);
      expect(loaded.analysisHistory, historyStore.entries);

      await cubit.refresh();

      loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.snapshot, same(updatedSnapshot));
      expect(loaded.previousSnapshot, same(snapshot));
      expect(loader.loadCount, 2);
      expect(loader.requestedRevisions, isEmpty);
      expect(store.loadCount, 1);
      expect(store.saveCount, 2);
      expect(store.state?.currentRevision, updatedSnapshot.sourceRevision);
      expect(store.state?.previousRevision, snapshot.sourceRevision);

      expect(historyStore.entries, hasLength(2));
      final RegistryAnalysisHistoryEntry firstRefreshHistoryEntry =
          historyStore.entries[1];
      expect(
        firstRefreshHistoryEntry.sourceRevision,
        updatedSnapshot.sourceRevision,
      );
      expect(
        firstRefreshHistoryEntry.previousRevision,
        snapshot.sourceRevision,
      );
      expect(
        firstRefreshHistoryEntry.previousAddedCount,
        loaded.previousComparison?.addedCount ?? 0,
      );
      expect(
        firstRefreshHistoryEntry.previousRemovedCount,
        loaded.previousComparison?.removedCount ?? 0,
      );
      expect(
        firstRefreshHistoryEntry.previousChangedCount,
        loaded.previousComparison?.changedCount ?? 0,
      );
      expect(loaded.analysisHistory, historyStore.entries);

      await cubit.refresh();

      loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.snapshot, same(updatedSnapshot));
      expect(loaded.previousSnapshot, same(snapshot));
      expect(loader.loadCount, 3);
      expect(loader.requestedRevisions, isEmpty);
      expect(store.loadCount, 1);
      expect(store.saveCount, 3);
      expect(store.state?.currentRevision, updatedSnapshot.sourceRevision);
      expect(store.state?.previousRevision, snapshot.sourceRevision);

      expect(historyStore.entries, hasLength(2));
      final RegistryAnalysisHistoryEntry sameRevisionHistoryEntry =
          historyStore.entries[1];
      expect(
        sameRevisionHistoryEntry.sourceRevision,
        updatedSnapshot.sourceRevision,
      );
      expect(
        sameRevisionHistoryEntry.previousRevision,
        snapshot.sourceRevision,
      );
      expect(loaded.analysisHistory, historyStore.entries);
    },
  );

  test('preserves, moves and clears open Registry '
      'context across refresh', () async {
    final RegistryNode currentRoot = snapshot.roots.single;

    final RegistryNode currentChild = currentRoot.children.single;

    const String movedFingerprint =
        'git-blob:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

    final RegistryPath movedPath = RegistryPath(const <String>[
      'Registry',
      'Moved Domain',
    ]);

    final RegistryNode movedChild = RegistryNode(
      id: currentChild.id,
      kindId: currentChild.kindId,
      path: movedPath,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: movedFingerprint,
          headingPath: movedPath.segments,
          startLine: 3,
          endLine: 4,
        ),
      ],
      content: currentChild.content,
      businessScopeOwnerId: currentChild.businessScopeOwnerId,
      children: const <RegistryNode>[],
    );

    final RegistryNode movedRoot = RegistryNode(
      id: currentRoot.id,
      kindId: currentRoot.kindId,
      path: currentRoot.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: movedFingerprint,
          headingPath: currentRoot.path.segments,
          startLine: 1,
          endLine: 4,
        ),
      ],
      content: currentRoot.content,
      businessScopeOwnerId: currentRoot.businessScopeOwnerId,
      children: <RegistryNode>[movedChild],
    );

    final RegistrySnapshot movedSnapshot = RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: '3333333333333333333333333333333333333333',
      sourceSnapshotFingerprint: movedFingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n'
          '## Moved Domain\n'
          'Domain content.\n',
      roots: <RegistryNode>[movedRoot],
    );

    const String deletedFingerprint =
        'git-blob:ffffffffffffffffffffffffffffffffffffffff';

    final RegistryNode deletedRoot = RegistryNode(
      id: currentRoot.id,
      kindId: currentRoot.kindId,
      path: currentRoot.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: deletedFingerprint,
          headingPath: currentRoot.path.segments,
          startLine: 1,
          endLine: 2,
        ),
      ],
      content: currentRoot.content,
      businessScopeOwnerId: currentRoot.businessScopeOwnerId,
      children: const <RegistryNode>[],
    );

    final RegistrySnapshot deletedSnapshot = RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: '4444444444444444444444444444444444444444',
      sourceSnapshotFingerprint: deletedFingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n',
      roots: <RegistryNode>[deletedRoot],
    );

    final _QueuedRegistrySnapshotLoader loader =
        _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
          () async => snapshot,
          () async => snapshot,
          () async => movedSnapshot,
          () async => deletedSnapshot,
        ]);

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();

    final RegistryExplorerCubit cubit = RegistryExplorerCubit(
      snapshotLoader: loader,
      snapshotRefreshLoader: loader,
      snapshotRevisionLoader: loader,
      revisionStateStore: store,
      analysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      snapshotComparator: const RegistrySnapshotComparator(),
    );

    addTearDown(cubit.close);

    await cubit.restore();

    await cubit.selectRegistryNode(currentChild.id);

    RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.openRegistryNode, same(currentChild));

    expect(store.state?.openRegistryPath, currentChild.path);

    await cubit.refresh();

    loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.snapshot, same(snapshot));

    expect(loaded.openRegistryNode, same(currentChild));

    expect(loaded.openRegistryNodeId, currentChild.id);

    expect(loaded.openRegistryPath, currentChild.path);

    expect(store.state?.openRegistryNodeId, currentChild.id);

    expect(store.state?.openRegistryPath, currentChild.path);

    expect(loaded.selectedProblemIndex, isNull);

    await cubit.refresh();

    loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.snapshot, same(movedSnapshot));

    expect(loaded.openRegistryNode, same(movedChild));

    expect(loaded.openRegistryNodeId, currentChild.id);

    expect(loaded.openRegistryPath, movedPath);

    expect(store.state?.openRegistryNodeId, currentChild.id);

    expect(store.state?.openRegistryPath, movedPath);

    expect(loaded.selectedProblemIndex, isNull);

    await cubit.refresh();

    loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.snapshot, same(deletedSnapshot));

    expect(loaded.openRegistryNode, isNull);

    expect(loaded.openRegistryNodeId, isNull);

    expect(loaded.openRegistryPath, isNull);

    expect(loaded.selectedProblemIndex, isNull);

    expect(store.state?.openRegistryNodeId, isNull);

    expect(store.state?.openRegistryPath, isNull);

    expect(loader.loadCount, 4);
    expect(loader.requestedRevisions, isEmpty);
    expect(store.saveCount, 5);
  });

  test(
    'changes clean baseline only after explicit engineer confirmation',
    () async {
      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () async => snapshot,
          ]);

      final _MemoryRegistryRevisionStateStore store =
          _MemoryRegistryRevisionStateStore();

      final RegistryExplorerCubit cubit = RegistryExplorerCubit(
        snapshotLoader: loader,
        snapshotRefreshLoader: loader,
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
        analysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        snapshotComparator: const RegistrySnapshotComparator(),
      );

      addTearDown(cubit.close);

      await cubit.restore();

      RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.cleanBaselineSnapshot, isNull);
      expect(loaded.cleanBaselineComparison, isNull);
      expect(store.state?.cleanBaselineRevision, isNull);
      expect(store.saveCount, 1);

      await cubit.confirmCurrentAsCleanBaseline();

      loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.cleanBaselineSnapshot, same(snapshot));
      expect(loaded.cleanBaselineComparison, isNotNull);
      expect(loaded.cleanBaselineComparison!.changes, isEmpty);
      expect(store.state?.cleanBaselineRevision, snapshot.sourceRevision);
      expect(store.saveCount, 2);

      await cubit.confirmCurrentAsCleanBaseline();

      expect(store.saveCount, 2);
    },
  );

  test('restores a persisted Registry block independently '
      'from problem navigation', () async {
    final RegistryNode child = snapshot.roots.single.children.single;

    final _QueuedRegistrySnapshotLoader loader = _QueuedRegistrySnapshotLoader(
      <Future<RegistrySnapshot> Function()>[],
      exactSnapshots: <String, RegistrySnapshot>{
        snapshot.sourceRevision: snapshot,
      },
    );

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore(
          state: RegistryRevisionState(
            projectId: snapshot.projectId,
            projectAdapterId: snapshot.projectAdapterId,
            sourceDocumentPath: snapshot.sourceDocumentPath,
            currentRevision: snapshot.sourceRevision,
            openRegistryNodeId: child.id,
            openRegistryPath: child.path,
          ),
        );

    final RegistryExplorerCubit cubit = RegistryExplorerCubit(
      snapshotLoader: loader,
      snapshotRefreshLoader: loader,
      snapshotRevisionLoader: loader,
      revisionStateStore: store,
      analysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      snapshotComparator: const RegistrySnapshotComparator(),
    );

    addTearDown(cubit.close);

    await cubit.restore();

    RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.openRegistryNodeId, child.id);
    expect(loaded.openRegistryPath, child.path);
    expect(loaded.openRegistryNode, same(child));
    expect(loaded.selectedProblemIndex, isNull);
    expect(loaded.selectedProblem, isNull);
    expect(store.saveCount, 0);

    await cubit.selectRegistryNode(null);

    loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.openRegistryNodeId, isNull);
    expect(loaded.openRegistryPath, isNull);
    expect(store.saveCount, 1);

    await cubit.selectRegistryNode(child.id);

    loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.openRegistryNode, same(child));
    expect(loaded.selectedProblemIndex, isNull);
    expect(store.state?.openRegistryNodeId, child.id);
    expect(store.state?.openRegistryPath, child.path);
    expect(store.saveCount, 2);
  });

  test(
    'restores a distinct persisted clean baseline and both comparisons',
    () async {
      const String cleanFingerprint =
          'git-blob:dddddddddddddddddddddddddddddddddddddddd';

      final RegistryNode currentRoot = snapshot.roots.single;
      final RegistryNode currentChild = currentRoot.children.single;

      final RegistryNode cleanChild = RegistryNode(
        id: currentChild.id,
        kindId: currentChild.kindId,
        path: currentChild.path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: snapshot.sourceDocumentPath,
            sourceSnapshotFingerprint: cleanFingerprint,
            headingPath: currentChild.path.segments,
            startLine: 3,
            endLine: 4,
          ),
        ],
        content: 'Clean baseline domain content.',
        businessScopeOwnerId: currentChild.businessScopeOwnerId,
        children: const <RegistryNode>[],
      );

      final RegistryNode cleanRoot = RegistryNode(
        id: currentRoot.id,
        kindId: currentRoot.kindId,
        path: currentRoot.path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: snapshot.sourceDocumentPath,
            sourceSnapshotFingerprint: cleanFingerprint,
            headingPath: currentRoot.path.segments,
            startLine: 1,
            endLine: 4,
          ),
        ],
        content: currentRoot.content,
        businessScopeOwnerId: currentRoot.businessScopeOwnerId,
        children: <RegistryNode>[cleanChild],
      );

      final RegistrySnapshot previousSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: '0000000000000000000000000000000000000000',
        sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        sourceContent: snapshot.sourceContent,
        roots: snapshot.roots,
      );

      final RegistrySnapshot cleanBaselineSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: 'ffffffffffffffffffffffffffffffffffffffff',
        sourceSnapshotFingerprint: cleanFingerprint,
        sourceContent:
            '# Registry\n'
            'Root content.\n'
            '## Domain\n'
            'Clean baseline domain content.\n',
        roots: <RegistryNode>[cleanRoot],
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(
            <Future<RegistrySnapshot> Function()>[],
            exactSnapshots: <String, RegistrySnapshot>{
              snapshot.sourceRevision: snapshot,
              previousSnapshot.sourceRevision: previousSnapshot,
              cleanBaselineSnapshot.sourceRevision: cleanBaselineSnapshot,
            },
          );

      final _MemoryRegistryRevisionStateStore store =
          _MemoryRegistryRevisionStateStore(
            state: RegistryRevisionState(
              projectId: snapshot.projectId,
              projectAdapterId: snapshot.projectAdapterId,
              sourceDocumentPath: snapshot.sourceDocumentPath,
              currentRevision: snapshot.sourceRevision,
              previousRevision: previousSnapshot.sourceRevision,
              cleanBaselineRevision: cleanBaselineSnapshot.sourceRevision,
              openRegistryNodeId: currentChild.id,
              openRegistryPath: currentChild.path,
              selectedProblemIndex: 7,
            ),
          );

      final _MemoryRegistryAnalysisHistoryStore historyStore =
          _MemoryRegistryAnalysisHistoryStore();

      final RegistryExplorerCubit cubit = RegistryExplorerCubit(
        snapshotLoader: loader,
        snapshotRefreshLoader: loader,
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
        analysisHistoryStore: historyStore,
        snapshotComparator: const RegistrySnapshotComparator(),
      );

      addTearDown(cubit.close);

      await cubit.restore();

      final RegistryExplorerLoaded loaded =
          cubit.state as RegistryExplorerLoaded;

      expect(loaded.snapshot, same(snapshot));
      expect(loaded.previousSnapshot, same(previousSnapshot));
      expect(loaded.cleanBaselineSnapshot, same(cleanBaselineSnapshot));

      expect(loaded.previousComparison, isNotNull);
      expect(loaded.previousComparison!.changes, isEmpty);

      expect(loaded.cleanBaselineComparison, isNotNull);
      expect(
        loaded.cleanBaselineComparison!.previousRevision,
        cleanBaselineSnapshot.sourceRevision,
      );
      expect(
        loaded.cleanBaselineComparison!.currentRevision,
        snapshot.sourceRevision,
      );
      expect(loaded.cleanBaselineComparison!.addedCount, 0);
      expect(loaded.cleanBaselineComparison!.removedCount, 0);
      expect(loaded.cleanBaselineComparison!.changedCount, 1);

      expect(historyStore.entries, hasLength(1));
      final RegistryAnalysisHistoryEntry restoredHistoryEntry =
          historyStore.entries.single;
      expect(restoredHistoryEntry.sourceRevision, snapshot.sourceRevision);
      expect(
        restoredHistoryEntry.previousRevision,
        previousSnapshot.sourceRevision,
      );
      expect(
        restoredHistoryEntry.cleanBaselineRevision,
        cleanBaselineSnapshot.sourceRevision,
      );
      expect(
        restoredHistoryEntry.previousAddedCount,
        loaded.previousComparison!.addedCount,
      );
      expect(
        restoredHistoryEntry.previousRemovedCount,
        loaded.previousComparison!.removedCount,
      );
      expect(
        restoredHistoryEntry.previousChangedCount,
        loaded.previousComparison!.changedCount,
      );
      expect(
        restoredHistoryEntry.cleanBaselineAddedCount,
        loaded.cleanBaselineComparison!.addedCount,
      );
      expect(
        restoredHistoryEntry.cleanBaselineRemovedCount,
        loaded.cleanBaselineComparison!.removedCount,
      );
      expect(
        restoredHistoryEntry.cleanBaselineChangedCount,
        loaded.cleanBaselineComparison!.changedCount,
      );
      expect(
        restoredHistoryEntry.problemCount,
        loaded.cleanBaselineComparison!.problems.length,
      );
      expect(loaded.analysisHistory, historyStore.entries);

      expect(loaded.selectedProblemIndex, 0);
      expect(loaded.selectedProblem, isNotNull);
      expect(loaded.selectedProblem!.exactNode.id, currentChild.id);
      expect(loaded.selectedProblem!.path, currentChild.path);

      expect(loader.loadCount, 0);
      expect(loader.requestedRevisions, <String>[
        snapshot.sourceRevision,
        previousSnapshot.sourceRevision,
        cleanBaselineSnapshot.sourceRevision,
      ]);

      expect(store.loadCount, 1);
      expect(store.saveCount, 0);
      expect(
        store.state?.cleanBaselineRevision,
        cleanBaselineSnapshot.sourceRevision,
      );

      final Future<void> persistedSelection = cubit.selectProblem(0);

      await expectLater(
        cubit.selectProblem(null),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            'Контекст Registry уже обновляется.',
          ),
        ),
      );

      await persistedSelection;

      expect(store.saveCount, 1);
      expect((cubit.state as RegistryExplorerLoaded).selectedProblemIndex, 0);
    },
  );

  test(
    'restores persisted current and previous snapshots without loading latest',
    () async {
      final RegistrySnapshot previousSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: '0000000000000000000000000000000000000000',
        sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        sourceContent: snapshot.sourceContent,
        roots: snapshot.roots,
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(
            <Future<RegistrySnapshot> Function()>[],
            exactSnapshots: <String, RegistrySnapshot>{
              snapshot.sourceRevision: snapshot,
              previousSnapshot.sourceRevision: previousSnapshot,
            },
          );

      final _MemoryRegistryRevisionStateStore store =
          _MemoryRegistryRevisionStateStore(
            state: RegistryRevisionState(
              projectId: snapshot.projectId,
              projectAdapterId: snapshot.projectAdapterId,
              sourceDocumentPath: snapshot.sourceDocumentPath,
              currentRevision: snapshot.sourceRevision,
              previousRevision: previousSnapshot.sourceRevision,
            ),
          );

      final RegistryExplorerCubit cubit = RegistryExplorerCubit(
        snapshotLoader: loader,
        snapshotRefreshLoader: loader,
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
        analysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        snapshotComparator: const RegistrySnapshotComparator(),
      );

      addTearDown(cubit.close);

      await cubit.restore();

      final RegistryExplorerLoaded loaded =
          cubit.state as RegistryExplorerLoaded;

      expect(loaded.snapshot, same(snapshot));
      expect(loaded.previousSnapshot, same(previousSnapshot));
      expect(loader.loadCount, 0);
      expect(loader.requestedRevisions, <String>[
        snapshot.sourceRevision,
        previousSnapshot.sourceRevision,
      ]);
      expect(store.loadCount, 1);
      expect(store.saveCount, 0);
      expect(store.state?.currentRevision, snapshot.sourceRevision);
      expect(store.state?.previousRevision, previousSnapshot.sourceRevision);
    },
  );

  test(
    'loads latest only on refresh and moves restored current to previous',
    () async {
      final RegistrySnapshot previousSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: '0000000000000000000000000000000000000000',
        sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        sourceContent: snapshot.sourceContent,
        roots: snapshot.roots,
      );

      final RegistrySnapshot latestSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: '3333333333333333333333333333333333333333',
        sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        sourceContent: snapshot.sourceContent,
        roots: snapshot.roots,
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(
            <Future<RegistrySnapshot> Function()>[() async => latestSnapshot],
            exactSnapshots: <String, RegistrySnapshot>{
              snapshot.sourceRevision: snapshot,
              previousSnapshot.sourceRevision: previousSnapshot,
            },
          );

      final _MemoryRegistryRevisionStateStore store =
          _MemoryRegistryRevisionStateStore(
            state: RegistryRevisionState(
              projectId: snapshot.projectId,
              projectAdapterId: snapshot.projectAdapterId,
              sourceDocumentPath: snapshot.sourceDocumentPath,
              currentRevision: snapshot.sourceRevision,
              previousRevision: previousSnapshot.sourceRevision,
            ),
          );

      final RegistryExplorerCubit cubit = RegistryExplorerCubit(
        snapshotLoader: loader,
        snapshotRefreshLoader: loader,
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
        analysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        snapshotComparator: const RegistrySnapshotComparator(),
      );

      addTearDown(cubit.close);

      await cubit.restore();

      RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.snapshot, same(snapshot));
      expect(loaded.previousSnapshot, same(previousSnapshot));
      expect(loader.loadCount, 0);
      expect(loader.requestedRevisions, <String>[
        snapshot.sourceRevision,
        previousSnapshot.sourceRevision,
      ]);
      expect(store.loadCount, 1);
      expect(store.saveCount, 0);

      await cubit.refresh();

      loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.snapshot, same(latestSnapshot));
      expect(loaded.previousSnapshot, same(snapshot));
      expect(loader.loadCount, 1);
      expect(loader.requestedRevisions, <String>[
        snapshot.sourceRevision,
        previousSnapshot.sourceRevision,
      ]);
      expect(store.loadCount, 1);
      expect(store.saveCount, 1);
      expect(store.state?.currentRevision, latestSnapshot.sourceRevision);
      expect(store.state?.previousRevision, snapshot.sourceRevision);
    },
  );

  test('retries a failed manual refresh as refresh', () async {
    final RegistryNode currentChild = snapshot.roots.single.children.single;

    final RegistrySnapshot latestSnapshot = RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: '3333333333333333333333333333333333333333',
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      sourceContent: snapshot.sourceContent,
      roots: snapshot.roots,
    );

    final _QueuedRegistrySnapshotLoader loader =
        _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
          () async => snapshot,
          () => Future<RegistrySnapshot>.error(StateError('refresh offline')),
          () async => latestSnapshot,
        ]);

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();

    final _MemoryRegistryAnalysisHistoryStore historyStore =
        _MemoryRegistryAnalysisHistoryStore();

    final RegistryExplorerCubit cubit = RegistryExplorerCubit(
      snapshotLoader: loader,
      snapshotRefreshLoader: loader,
      snapshotRevisionLoader: loader,
      revisionStateStore: store,
      analysisHistoryStore: historyStore,
      snapshotComparator: const RegistrySnapshotComparator(),
    );

    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.selectRegistryNode(currentChild.id);

    RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.openRegistryNode, same(currentChild));
    expect(loader.loadCount, 1);
    expect(store.loadCount, 1);
    expect(store.saveCount, 2);
    expect(store.state?.openRegistryNodeId, currentChild.id);
    expect(store.state?.openRegistryPath, currentChild.path);

    expect(historyStore.entries, hasLength(1));
    expect(loaded.analysisHistory, historyStore.entries);

    await cubit.refresh();

    final RegistryExplorerFailure failure =
        cubit.state as RegistryExplorerFailure;

    expect(failure.openRegistryNodeBeforeRefresh, same(currentChild));
    expect(loader.loadCount, 2);
    expect(store.loadCount, 1);
    expect(store.saveCount, 2);
    expect(store.state?.openRegistryNodeId, currentChild.id);
    expect(store.state?.openRegistryPath, currentChild.path);

    expect(historyStore.entries, hasLength(1));
    expect(failure.analysisHistoryBeforeRefresh, historyStore.entries);

    await cubit.retry();

    loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.snapshot, same(latestSnapshot));
    expect(loaded.previousSnapshot, same(snapshot));
    expect(loaded.openRegistryNode, same(currentChild));
    expect(loaded.openRegistryNodeId, currentChild.id);
    expect(loaded.openRegistryPath, currentChild.path);
    expect(loader.loadCount, 3);
    expect(loader.requestedRevisions, isEmpty);
    expect(store.loadCount, 1);
    expect(store.saveCount, 3);
    expect(store.state?.currentRevision, latestSnapshot.sourceRevision);
    expect(store.state?.previousRevision, snapshot.sourceRevision);
    expect(store.state?.openRegistryNodeId, currentChild.id);
    expect(store.state?.openRegistryPath, currentChild.path);

    expect(historyStore.entries, hasLength(2));
    final RegistryAnalysisHistoryEntry retryHistoryEntry =
        historyStore.entries.last;
    expect(retryHistoryEntry.sourceRevision, latestSnapshot.sourceRevision);
    expect(retryHistoryEntry.previousRevision, snapshot.sourceRevision);
    expect(loaded.analysisHistory, historyStore.entries);
  });
  testWidgets(
    'shows the previous exact revision after Registry revision changes',
    (WidgetTester tester) async {
      final RegistrySnapshot updatedSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: '2222222222222222222222222222222222222222',
        sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        sourceContent: snapshot.sourceContent,
        roots: snapshot.roots,
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () async => snapshot,
            () async => updatedSnapshot,
          ]);

      await tester.pumpWidget(
        RegistryStudioApplication(
          registrySnapshotLoader: loader,
          registrySnapshotRefreshLoader: loader,
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
          registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Предыдущая revision: ${snapshot.sourceRevision}'),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Перезагрузить Registry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Revision: ${updatedSnapshot.sourceRevision}'),
        findsOneWidget,
      );
      expect(
        find.text('Предыдущая revision: ${snapshot.sourceRevision}'),
        findsOneWidget,
      );
      expect(loader.loadCount, 2);
    },
  );

  testWidgets(
    'shows previous and clean baseline changes after manual refresh',
    (WidgetTester tester) async {
      const String currentFingerprint =
          'git-blob:cccccccccccccccccccccccccccccccccccccccc';

      final RegistryNode previousRoot = snapshot.roots.single;

      final RegistryNode previousChild = previousRoot.children.single;

      final RegistryNode changedChild = RegistryNode(
        id: previousChild.id,
        kindId: previousChild.kindId,
        path: previousChild.path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: snapshot.sourceDocumentPath,
            sourceSnapshotFingerprint: currentFingerprint,
            headingPath: previousChild.path.segments,
            startLine: 3,
            endLine: 4,
          ),
        ],
        content: 'Updated domain content.',
        businessScopeOwnerId: previousChild.businessScopeOwnerId,
        children: const <RegistryNode>[],
      );

      final RegistryNode addedChild = RegistryNode(
        id: RegistryNodeId('project.registry.node.000003'),
        kindId: 'project.registry.heading.2',
        path: RegistryPath(const <String>['Registry', 'Added Domain']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: snapshot.sourceDocumentPath,
            sourceSnapshotFingerprint: currentFingerprint,
            headingPath: const <String>['Registry', 'Added Domain'],
            startLine: 5,
            endLine: 6,
          ),
        ],
        content: 'Added domain content.',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistryNode currentRoot = RegistryNode(
        id: previousRoot.id,
        kindId: previousRoot.kindId,
        path: previousRoot.path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: snapshot.sourceDocumentPath,
            sourceSnapshotFingerprint: currentFingerprint,
            headingPath: previousRoot.path.segments,
            startLine: 1,
            endLine: 6,
          ),
        ],
        content: previousRoot.content,
        businessScopeOwnerId: previousRoot.businessScopeOwnerId,
        children: <RegistryNode>[changedChild, addedChild],
      );

      final RegistrySnapshot updatedSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: '4444444444444444444444444444444444444444',
        sourceSnapshotFingerprint: currentFingerprint,
        sourceContent:
            '# Registry\n'
            'Root content.\n'
            '## Domain\n'
            'Updated domain content.\n'
            '## Added Domain\n'
            'Added domain content.\n',
        roots: <RegistryNode>[currentRoot],
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () async => snapshot,
            () async => updatedSnapshot,
            () async => updatedSnapshot,
          ]);

      final _MemoryRegistryRevisionStateStore store =
          _MemoryRegistryRevisionStateStore();

      final _MemoryRegistryAnalysisHistoryStore historyStore =
          _MemoryRegistryAnalysisHistoryStore();

      await tester.pumpWidget(
        RegistryStudioApplication(
          registrySnapshotLoader: loader,
          registrySnapshotRefreshLoader: loader,
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: store,
          registryAnalysisHistoryStore: historyStore,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Изменения с предыдущей revision: нет baseline'),
        findsOneWidget,
      );

      expect(find.text('Clean baseline: не подтверждён'), findsOneWidget);

      final Finder historyButton = find.byKey(
        const ValueKey<String>('registry-analysis-history-button'),
      );

      expect(historyStore.entries, hasLength(1));
      expect(historyButton, findsOneWidget);

      expect(
        find.ancestor(of: historyButton, matching: find.byType(Badge)),
        findsNothing,
      );

      expect(find.byTooltip('История анализа: 1'), findsOneWidget);

      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      Finder historySheet = find.byKey(
        const ValueKey<String>('registry-analysis-history-sheet'),
      );

      expect(historySheet, findsOneWidget);
      expect(
        find.descendant(
          of: historySheet,
          matching: find.text('История анализа Registry: 1'),
        ),
        findsOneWidget,
      );

      final Finder initialHistoryEntry = find.byKey(
        const ValueKey<String>('registry-analysis-history-entry-0'),
      );

      expect(initialHistoryEntry, findsOneWidget);
      expect(
        find.descendant(
          of: initialHistoryEntry,
          matching: find.text('Revision: ${snapshot.sourceRevision}'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: initialHistoryEntry,
          matching: find.text('Предыдущая revision: нет baseline'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: initialHistoryEntry,
          matching: find.text('Clean baseline: не подтверждён'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: initialHistoryEntry,
          matching: find.text('С предыдущей revision: +0 · -0 · ~0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: initialHistoryEntry,
          matching: find.text('С clean baseline: +0 · -0 · ~0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: initialHistoryEntry,
          matching: find.text('Проблем: 0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: initialHistoryEntry,
          matching: find.textContaining('Время: '),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Закрыть историю анализа'));
      await tester.pumpAndSettle();

      expect(historySheet, findsNothing);

      await tester.tap(
        find.byTooltip('Подтвердить текущую revision как clean baseline'),
      );

      await tester.pumpAndSettle();

      expect(find.text('Подтвердить clean baseline?'), findsOneWidget);

      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();

      expect(
        find.text('Clean baseline: ${snapshot.sourceRevision}'),
        findsOneWidget,
      );

      expect(find.text('Расхождения с clean baseline: 0'), findsOneWidget);

      expect(store.state?.cleanBaselineRevision, snapshot.sourceRevision);

      await tester.tap(find.byTooltip('Перезагрузить Registry'));

      await tester.pumpAndSettle();

      expect(find.text('Изменения с предыдущей revision: 2'), findsOneWidget);

      expect(find.text('Расхождения с clean baseline: 2'), findsOneWidget);

      expect(historyStore.entries, hasLength(2));
      expect(find.byTooltip('История анализа: 2'), findsOneWidget);

      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      historySheet = find.byKey(
        const ValueKey<String>('registry-analysis-history-sheet'),
      );

      expect(historySheet, findsOneWidget);
      expect(
        find.descendant(
          of: historySheet,
          matching: find.text('История анализа Registry: 2'),
        ),
        findsOneWidget,
      );

      final Finder latestHistoryEntry = find.byKey(
        const ValueKey<String>('registry-analysis-history-entry-1'),
      );

      expect(latestHistoryEntry, findsOneWidget);
      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('Revision: ${updatedSnapshot.sourceRevision}'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text(
            'Предыдущая revision: '
            '${snapshot.sourceRevision}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('Clean baseline: ${snapshot.sourceRevision}'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('С предыдущей revision: +1 · -0 · ~1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('С clean baseline: +1 · -0 · ~1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('Проблем: 2'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('Identity: ${previousChild.id.value}'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text(
            'Путь: ${previousChild.path.segments.join(' → ')}',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('Причина: Изменены: содержимое.'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('Identity: ${addedChild.id.value}'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: latestHistoryEntry,
          matching: find.text('Причина: Добавлен новый Registry-узел.'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Закрыть историю анализа'));
      await tester.pumpAndSettle();

      expect(historySheet, findsNothing);

      final Finder previousSummary = find.byKey(
        const ValueKey<String>('registry-previous-comparison-summary'),
      );

      final Finder cleanSummary = find.byKey(
        const ValueKey<String>('registry-clean-baseline-summary'),
      );

      expect(
        find.descendant(
          of: previousSummary,
          matching: find.text('Добавлено: 1 · Удалено: 0 · Изменено: 1'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: cleanSummary,
          matching: find.textContaining(
            'Добавлено: 1 · Удалено: 0 · Изменено: 1',
          ),
        ),
        findsOneWidget,
      );

      final Finder problemQueue = find.byKey(
        const ValueKey<String>('registry-problem-queue'),
      );

      expect(problemQueue, findsOneWidget);

      final Finder registryNodeList = find.byKey(
        const ValueKey<String>('registry-node-list'),
      );

      expect(registryNodeList, findsOneWidget);

      expect(
        find.descendant(of: registryNodeList, matching: problemQueue),
        findsNothing,
      );

      expect(
        find.descendant(
          of: problemQueue,
          matching: find.text('Очередь проблем: 2'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: problemQueue,
          matching: find.textContaining('Источник: clean baseline'),
        ),
        findsOneWidget,
      );

      await tester.tap(problemQueue);
      await tester.pumpAndSettle();

      final Finder registryScrollable = find.descendant(
        of: find.byKey(const ValueKey<String>('registry-node-list')),
        matching: find.byType(Scrollable),
      );

      expect(registryScrollable, findsOneWidget);

      final Finder changedProblem = find.byKey(
        ValueKey<String>(
          'registry-problem-0-'
          '${previousChild.id.value}',
        ),
      );

      final Finder addedProblem = find.byKey(
        ValueKey<String>(
          'registry-problem-1-'
          '${addedChild.id.value}',
        ),
      );

      expect(changedProblem, findsOneWidget);
      expect(find.text('Затронуто · Domain'), findsOneWidget);

      await tester.scrollUntilVisible(
        addedProblem,
        180,
        scrollable: registryScrollable,
      );

      expect(addedProblem, findsOneWidget);
      expect(find.text('Затронуто · Added Domain'), findsOneWidget);

      await tester.scrollUntilVisible(
        changedProblem,
        -180,
        scrollable: registryScrollable,
      );

      expect(changedProblem, findsOneWidget);

      await tester.tap(problemQueue);
      await tester.pumpAndSettle();

      expect(changedProblem, findsNothing);
      expect(addedProblem, findsNothing);

      final Finder fullScreenButton = find.byTooltip(
        'Открыть очередь проблем на весь экран',
      );

      await tester.tap(fullScreenButton);
      await tester.pumpAndSettle();

      final Finder fullScreenQueue = find.byKey(
        const ValueKey<String>('registry-problem-queue-fullscreen'),
      );

      expect(fullScreenQueue, findsOneWidget);

      expect(
        find.descendant(
          of: fullScreenQueue,
          matching: find.text('Очередь проблем: 2'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: fullScreenQueue,
          matching: find.textContaining('Источник: clean baseline'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('full-registry-header')),
        findsNothing,
      );

      final Finder fullScreenCloseButton = find.byTooltip(
        'Закрыть полноэкранную очередь проблем',
      );

      await tester.tap(fullScreenCloseButton);
      await tester.pumpAndSettle();

      expect(fullScreenQueue, findsNothing);

      expect(
        find.byKey(const ValueKey<String>('full-registry-header')),
        findsOneWidget,
      );

      await tester.tap(fullScreenButton);
      await tester.pumpAndSettle();

      expect(fullScreenQueue, findsOneWidget);
      expect(changedProblem, findsOneWidget);

      await tester.scrollUntilVisible(
        addedProblem,
        180,
        scrollable: registryScrollable,
      );

      expect(addedProblem, findsOneWidget);

      await tester.scrollUntilVisible(
        changedProblem,
        -180,
        scrollable: registryScrollable,
      );

      expect(changedProblem, findsOneWidget);

      await tester.tap(changedProblem);
      await tester.pumpAndSettle();

      expect(store.state?.openRegistryNodeId, changedChild.id);
      expect(store.state?.openRegistryPath, changedChild.path);
      expect(store.state?.selectedProblemIndex, 0);

      expect(fullScreenQueue, findsNothing);
      expect(changedProblem, findsNothing);
      expect(addedProblem, findsNothing);

      final Finder selectedProblem = find.byKey(
        const ValueKey<String>('registry-selected-problem'),
      );

      expect(selectedProblem, findsOneWidget);

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.text('Проблемное место 1 из 2'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.text('Статус: затронуто'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.text('Причина: Изменены: содержимое.'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.textContaining('Updated domain content.'),
        ),
        findsOneWidget,
      );

      final Finder refreshButton = find.byTooltip('Перезагрузить Registry');

      expect(refreshButton, findsOneWidget);
      final int refreshCountBeforeRepeat = loader.refreshBaseRevisions.length;

      final String currentRevisionBeforeRepeat = store.state!.currentRevision;

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      expect(
        loader.refreshBaseRevisions,
        hasLength(refreshCountBeforeRepeat + 1),
      );

      expect(loader.refreshBaseRevisions.last, currentRevisionBeforeRepeat);

      expect(store.state?.openRegistryNodeId, changedChild.id);
      expect(store.state?.openRegistryPath, changedChild.path);
      expect(store.state?.selectedProblemIndex, 0);

      expect(selectedProblem, findsOneWidget);

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.text('Проблемное место 1 из 2'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.textContaining('Updated domain content.'),
        ),
        findsOneWidget,
      );

      final Finder nextProblemButton = find.byTooltip('Следующая проблема');

      await tester.ensureVisible(nextProblemButton);
      await tester.pumpAndSettle();

      await tester.tap(nextProblemButton);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.text('Проблемное место 2 из 2'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.text('Причина: Добавлен новый Registry-узел.'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.textContaining('Added domain content.'),
        ),
        findsOneWidget,
      );

      final Finder previousProblemButton = find.byTooltip(
        'Предыдущая проблема',
      );

      await tester.ensureVisible(previousProblemButton);
      await tester.pumpAndSettle();

      await tester.tap(previousProblemButton);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: selectedProblem,
          matching: find.text('Проблемное место 1 из 2'),
        ),
        findsOneWidget,
      );

      final Finder closeProblemButton = find.descendant(
        of: selectedProblem,
        matching: find.widgetWithText(TextButton, 'Закрыть'),
      );

      await tester.ensureVisible(closeProblemButton);
      await tester.pumpAndSettle();

      await tester.tap(closeProblemButton);
      await tester.pumpAndSettle();

      expect(selectedProblem, findsNothing);

      final Finder restoredFullRegistryHeader = find.byKey(
        const ValueKey<String>('full-registry-header'),
      );

      await tester.scrollUntilVisible(
        restoredFullRegistryHeader,
        -180,
        scrollable: registryScrollable,
      );

      expect(restoredFullRegistryHeader, findsOneWidget);

      expect(store.state?.cleanBaselineRevision, snapshot.sourceRevision);

      expect(loader.loadCount, 3);
    },
  );

  testWidgets('reports moved changed and deleted open Registry '
      'blocks after refresh', (WidgetTester tester) async {
    final RegistryNode currentRoot = snapshot.roots.single;

    final RegistryNode currentChild = currentRoot.children.single;

    const String movedFingerprint =
        'git-blob:abababababababababababababababababababab';

    final RegistryPath movedPath = RegistryPath(const <String>[
      'Registry',
      'Moved Domain',
    ]);

    final RegistryNode movedChild = RegistryNode(
      id: currentChild.id,
      kindId: currentChild.kindId,
      path: movedPath,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: movedFingerprint,
          headingPath: movedPath.segments,
          startLine: 3,
          endLine: 4,
        ),
      ],
      content: currentChild.content,
      businessScopeOwnerId: currentChild.businessScopeOwnerId,
      children: const <RegistryNode>[],
    );

    final RegistryNode movedRoot = RegistryNode(
      id: currentRoot.id,
      kindId: currentRoot.kindId,
      path: currentRoot.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: movedFingerprint,
          headingPath: currentRoot.path.segments,
          startLine: 1,
          endLine: 4,
        ),
      ],
      content: currentRoot.content,
      businessScopeOwnerId: currentRoot.businessScopeOwnerId,
      children: <RegistryNode>[movedChild],
    );

    final RegistrySnapshot movedSnapshot = RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: '5555555555555555555555555555555555555555',
      sourceSnapshotFingerprint: movedFingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n'
          '## Moved Domain\n'
          'Domain content.\n',
      roots: <RegistryNode>[movedRoot],
    );

    const String changedFingerprint =
        'git-blob:bcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbc';

    final RegistryNode changedChild = RegistryNode(
      id: currentChild.id,
      kindId: currentChild.kindId,
      path: movedPath,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: changedFingerprint,
          headingPath: movedPath.segments,
          startLine: 3,
          endLine: 4,
        ),
      ],
      content: 'Updated Domain content.',
      businessScopeOwnerId: currentChild.businessScopeOwnerId,
      children: const <RegistryNode>[],
    );

    final RegistryNode changedRoot = RegistryNode(
      id: currentRoot.id,
      kindId: currentRoot.kindId,
      path: currentRoot.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: changedFingerprint,
          headingPath: currentRoot.path.segments,
          startLine: 1,
          endLine: 4,
        ),
      ],
      content: currentRoot.content,
      businessScopeOwnerId: currentRoot.businessScopeOwnerId,
      children: <RegistryNode>[changedChild],
    );

    final RegistrySnapshot changedSnapshot = RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: '6666666666666666666666666666666666666666',
      sourceSnapshotFingerprint: changedFingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n'
          '## Moved Domain\n'
          'Updated Domain content.\n',
      roots: <RegistryNode>[changedRoot],
    );

    const String deletedFingerprint =
        'git-blob:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd';

    final RegistryNode deletedRoot = RegistryNode(
      id: currentRoot.id,
      kindId: currentRoot.kindId,
      path: currentRoot.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: deletedFingerprint,
          headingPath: currentRoot.path.segments,
          startLine: 1,
          endLine: 2,
        ),
      ],
      content: currentRoot.content,
      businessScopeOwnerId: currentRoot.businessScopeOwnerId,
      children: const <RegistryNode>[],
    );

    final RegistrySnapshot deletedSnapshot = RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: '7777777777777777777777777777777777777777',
      sourceSnapshotFingerprint: deletedFingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n',
      roots: <RegistryNode>[deletedRoot],
    );

    final _QueuedRegistrySnapshotLoader loader =
        _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
          () async => snapshot,
          () async => movedSnapshot,
          () async => changedSnapshot,
          () async => deletedSnapshot,
        ]);

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: store,
        registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      ),
    );

    await tester.pumpAndSettle();

    final Finder registryScrollable = find.descendant(
      of: find.byKey(const ValueKey<String>('registry-node-list')),
      matching: find.byType(Scrollable),
    );

    expect(registryScrollable, findsOneWidget);

    final Finder childRow = find.byKey(ValueKey<String>(currentChild.id.value));

    await tester.scrollUntilVisible(
      childRow,
      180,
      scrollable: registryScrollable,
    );

    await tester.pumpAndSettle();

    expect(childRow, findsOneWidget);

    await tester.tap(childRow);
    await tester.pumpAndSettle();

    final Finder selectedRegistryBlock = find.byKey(
      const ValueKey<String>('registry-selected-block'),
    );

    expect(selectedRegistryBlock, findsOneWidget);

    final Finder refreshButton = find.byTooltip('Перезагрузить Registry');

    await tester.tap(refreshButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Открытый Registry block перемещён.\n'
        'Было: Registry → Domain\n'
        'Стало: Registry → Moved Domain',
      ),
      findsOneWidget,
    );

    expect(selectedRegistryBlock, findsOneWidget);

    expect(
      find.descendant(
        of: selectedRegistryBlock,
        matching: find.text(
          'RegistryPath: '
          'Registry → Moved Domain',
        ),
      ),
      findsOneWidget,
    );

    expect(store.state?.openRegistryNodeId, currentChild.id);

    expect(store.state?.openRegistryPath, movedPath);

    await tester.tap(refreshButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Открытый Registry block изменён '
        'в новой revision.',
      ),
      findsOneWidget,
    );

    expect(selectedRegistryBlock, findsOneWidget);

    expect(
      find.descendant(
        of: selectedRegistryBlock,
        matching: find.textContaining('Updated Domain content.'),
      ),
      findsOneWidget,
    );

    expect(store.state?.openRegistryNodeId, currentChild.id);

    expect(store.state?.openRegistryPath, movedPath);

    await tester.tap(refreshButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Открытый Registry block удалён '
        'в новой revision.',
      ),
      findsOneWidget,
    );

    expect(selectedRegistryBlock, findsNothing);

    expect(store.state?.openRegistryNodeId, isNull);

    expect(store.state?.openRegistryPath, isNull);

    expect(loader.loadCount, 4);
  });

  testWidgets('preserves and reports open Registry block '
      'after failed refresh retry', (WidgetTester tester) async {
    final RegistryNode currentRoot = snapshot.roots.single;

    final RegistryNode currentChild = currentRoot.children.single;

    const String changedFingerprint =
        'git-blob:dededededededededededededededededededede';

    final RegistryNode changedChild = RegistryNode(
      id: currentChild.id,
      kindId: currentChild.kindId,
      path: currentChild.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: changedFingerprint,
          headingPath: currentChild.path.segments,
          startLine: 3,
          endLine: 4,
        ),
      ],
      content: 'Retried Domain content.',
      businessScopeOwnerId: currentChild.businessScopeOwnerId,
      children: const <RegistryNode>[],
    );

    final RegistryNode changedRoot = RegistryNode(
      id: currentRoot.id,
      kindId: currentRoot.kindId,
      path: currentRoot.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: changedFingerprint,
          headingPath: currentRoot.path.segments,
          startLine: 1,
          endLine: 4,
        ),
      ],
      content: currentRoot.content,
      businessScopeOwnerId: currentRoot.businessScopeOwnerId,
      children: <RegistryNode>[changedChild],
    );

    final RegistrySnapshot changedSnapshot = RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: '8888888888888888888888888888888888888888',
      sourceSnapshotFingerprint: changedFingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n'
          '## Domain\n'
          'Retried Domain content.\n',
      roots: <RegistryNode>[changedRoot],
    );

    final _QueuedRegistrySnapshotLoader loader =
        _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
          () async => snapshot,
          () => Future<RegistrySnapshot>.error(StateError('refresh offline')),
          () async => changedSnapshot,
        ]);

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: store,
        registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      ),
    );

    await tester.pumpAndSettle();

    final Finder registryScrollable = find.descendant(
      of: find.byKey(const ValueKey<String>('registry-node-list')),
      matching: find.byType(Scrollable),
    );

    expect(registryScrollable, findsOneWidget);

    final Finder childRow = find.byKey(ValueKey<String>(currentChild.id.value));

    await tester.scrollUntilVisible(
      childRow,
      180,
      scrollable: registryScrollable,
    );

    await tester.pumpAndSettle();

    expect(childRow, findsOneWidget);

    await tester.tap(childRow);
    await tester.pumpAndSettle();

    expect(store.state?.openRegistryNodeId, currentChild.id);

    expect(store.state?.openRegistryPath, currentChild.path);

    await tester.tap(find.byTooltip('Перезагрузить Registry'));

    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить Registry'), findsOneWidget);

    expect(store.state?.openRegistryNodeId, currentChild.id);

    expect(store.state?.openRegistryPath, currentChild.path);

    final Finder retryButton = find.byTooltip('Повторить загрузку Registry');

    expect(retryButton, findsOneWidget);

    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Открытый Registry block изменён '
        'в новой revision.',
      ),
      findsOneWidget,
    );

    final Finder selectedRegistryBlock = find.byKey(
      const ValueKey<String>('registry-selected-block'),
    );

    expect(selectedRegistryBlock, findsOneWidget);

    expect(
      find.descendant(
        of: selectedRegistryBlock,
        matching: find.textContaining('Retried Domain content.'),
      ),
      findsOneWidget,
    );

    expect(store.state?.openRegistryNodeId, currentChild.id);

    expect(store.state?.openRegistryPath, currentChild.path);

    expect(loader.loadCount, 3);
  });
  testWidgets('opens and closes a Registry block '
      'and persists its exact context', (WidgetTester tester) async {
    final _QueuedRegistrySnapshotLoader loader = _QueuedRegistrySnapshotLoader(
      <Future<RegistrySnapshot> Function()>[() async => snapshot],
    );

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: store,
        registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      ),
    );

    await tester.pumpAndSettle();

    final RegistryNode child = snapshot.roots.single.children.single;

    final Finder registryScrollable = find.descendant(
      of: find.byKey(const ValueKey<String>('registry-node-list')),
      matching: find.byType(Scrollable),
    );

    expect(registryScrollable, findsOneWidget);

    final Finder childRow = find.byKey(ValueKey<String>(child.id.value));

    await tester.scrollUntilVisible(
      childRow,
      180,
      scrollable: registryScrollable,
    );

    await tester.pumpAndSettle();

    expect(childRow, findsOneWidget);

    await tester.tap(childRow);
    await tester.pumpAndSettle();

    final Finder selectedRegistryBlock = find.byKey(
      const ValueKey<String>('registry-selected-block'),
    );

    expect(selectedRegistryBlock, findsOneWidget);

    final Finder selectedRegistryBlockScreen = find.byKey(
      const ValueKey<String>('registry-selected-block-screen'),
    );

    expect(selectedRegistryBlockScreen, findsOneWidget);

    expect(
      find.ancestor(
        of: selectedRegistryBlock,
        matching: selectedRegistryBlockScreen,
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: selectedRegistryBlock,
        matching: find.text('Открытый Registry block'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: selectedRegistryBlock,
        matching: find.text('RegistryPath: Registry → Domain'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: selectedRegistryBlock,
        matching: find.textContaining('Domain content.'),
      ),
      findsOneWidget,
    );

    expect(store.state?.openRegistryNodeId, child.id);

    expect(store.state?.openRegistryPath, child.path);

    expect(store.state?.selectedProblemIndex, isNull);

    final Finder closeButton = find.descendant(
      of: selectedRegistryBlock,
      matching: find.widgetWithText(TextButton, 'Закрыть'),
    );

    await tester.ensureVisible(closeButton);
    await tester.pumpAndSettle();

    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    expect(selectedRegistryBlock, findsNothing);

    expect(selectedRegistryBlockScreen, findsNothing);

    expect(store.state?.openRegistryNodeId, isNull);

    expect(store.state?.openRegistryPath, isNull);

    expect(store.state?.selectedProblemIndex, isNull);
  });

  testWidgets(
    'loads the complete Registry, reloads it and preserves workspace navigation',
    (WidgetTester tester) async {
      final Completer<RegistrySnapshot> firstLoad =
          Completer<RegistrySnapshot>();

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () => firstLoad.future,
            () async => snapshot,
          ]);

      await tester.pumpWidget(
        RegistryStudioApplication(
          registrySnapshotLoader: loader,
          registrySnapshotRefreshLoader: loader,
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
          registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Загрузка Registry'), findsOneWidget);

      firstLoad.complete(snapshot);
      await tester.pumpAndSettle();

      expect(find.text('Проект: project'), findsOneWidget);
      expect(find.text('Узлов: 2'), findsOneWidget);
      expect(find.text('Registry'), findsOneWidget);

      final Finder registryList = find.byKey(
        const ValueKey<String>('registry-node-list'),
      );

      final Finder registryScrollable = find.descendant(
        of: registryList,
        matching: find.byType(Scrollable),
      );

      expect(registryList, findsOneWidget);
      expect(registryScrollable, findsOneWidget);

      final Finder domainRow = find.byKey(
        ValueKey<String>(snapshot.roots.single.children.single.id.value),
      );

      await tester.scrollUntilVisible(
        domainRow,
        180,
        scrollable: registryScrollable,
      );

      await tester.pumpAndSettle();

      expect(domainRow, findsOneWidget);
      expect(find.text('Domain'), findsOneWidget);
      expect(find.byTooltip('Перезагрузить Registry'), findsOneWidget);

      await tester.tap(find.byTooltip('Перезагрузить Registry'));
      await tester.pumpAndSettle();

      expect(loader.loadCount, 2);
      expect(find.text('Узлов: 2'), findsOneWidget);

      expect(find.byType(NavigationBar), findsOneWidget);

      final List<NavigationDestination> destinations = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .toList(growable: false);

      expect(destinations, hasLength(2));
      expect(
        destinations
            .map((NavigationDestination destination) => destination.label)
            .toList(growable: false),
        <String>['Registry Studio', 'Translator'],
      );

      final Finder translatorNavigationLabel = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Translator'),
      );

      await tester.tap(translatorNavigationLabel);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Translator'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Перевод и проверка формулировок RU / EN / TH'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows scroll-to-top action after scrolling and returns to the first node',
    (WidgetTester tester) async {
      const String documentPath = 'long-registry.md';
      const String fingerprint =
          'git-blob:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

      final List<RegistryNode> children = List<RegistryNode>.generate(40, (
        int index,
      ) {
        final int nodeNumber = index + 2;
        final String label = 'Node ${index + 1}';

        return RegistryNode(
          id: RegistryNodeId(
            'project.registry.node.'
            '${nodeNumber.toString().padLeft(6, '0')}',
          ),
          kindId: 'project.registry.heading.2',
          path: RegistryPath(<String>['Registry', label]),
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: documentPath,
              sourceSnapshotFingerprint: fingerprint,
              headingPath: <String>['Registry', label],
              startLine: nodeNumber,
              endLine: nodeNumber,
            ),
          ],
          content: '$label content.',
          businessScopeOwnerId: null,
          children: const <RegistryNode>[],
        );
      });

      final RegistryNode root = RegistryNode(
        id: RegistryNodeId('project.registry.node.000001'),
        kindId: 'project.registry.heading.1',
        path: RegistryPath(const <String>['Registry']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: documentPath,
            sourceSnapshotFingerprint: fingerprint,
            headingPath: const <String>['Registry'],
            startLine: 1,
            endLine: children.length + 1,
          ),
        ],
        content: 'Root content.',
        businessScopeOwnerId: null,
        children: children,
      );

      final RegistrySnapshot longSnapshot = RegistrySnapshot(
        projectId: 'project',
        projectAdapterId: 'project.registry.adapter.v1',
        sourceDocumentPath: documentPath,
        sourceRevision: '2222222222222222222222222222222222222222',
        sourceSnapshotFingerprint: fingerprint,
        sourceContent: <String>[
          '# Registry',
          ...children.map(
            (RegistryNode node) => '## ${node.path.segments.last}',
          ),
        ].join('\n'),
        roots: <RegistryNode>[root],
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () async => longSnapshot,
          ]);

      await tester.pumpWidget(
        RegistryStudioApplication(
          registrySnapshotLoader: loader,
          registrySnapshotRefreshLoader: loader,
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
          registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Наверх'), findsNothing);

      final Finder registryList = find.byKey(
        const ValueKey<String>('registry-node-list'),
      );

      final Finder registryScrollable = find.descendant(
        of: registryList,
        matching: find.byType(Scrollable),
      );

      expect(registryList, findsOneWidget);
      expect(registryScrollable, findsOneWidget);

      await tester.drag(registryList, const Offset(0, -1600));
      await tester.pumpAndSettle();

      final ScrollableState scrolledState = tester.state<ScrollableState>(
        registryScrollable,
      );

      expect(
        scrolledState.position.pixels,
        greaterThan(scrolledState.position.viewportDimension),
      );
      expect(find.byTooltip('Наверх'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      await tester.tap(find.byTooltip('Наверх'));
      await tester.pumpAndSettle();

      final ScrollableState restoredState = tester.state<ScrollableState>(
        registryScrollable,
      );

      expect(restoredState.position.pixels, closeTo(0, 0.1));
      expect(find.byTooltip('Наверх'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('project.registry.node.000001')),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows hierarchy styling and collapses sibling branches', (
    WidgetTester tester,
  ) async {
    const String documentPath = 'tree-registry.md';
    const String fingerprint =
        'git-blob:abababababababababababababababababababab';

    final RegistryNode entity = RegistryNode(
      id: RegistryNodeId('project.registry.node.000003'),
      kindId: 'project.registry.heading.3',
      path: RegistryPath(const <String>['Registry', 'Category', 'Entity']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry', 'Category', 'Entity'],
          startLine: 5,
          endLine: 6,
        ),
      ],
      content: 'Entity content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode siblingEntity = RegistryNode(
      id: RegistryNodeId('project.registry.node.000005'),
      kindId: 'project.registry.heading.3',
      path: RegistryPath(const <String>[
        'Registry',
        'Second Category',
        'Second Entity',
      ]),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>[
            'Registry',
            'Second Category',
            'Second Entity',
          ],
          startLine: 9,
          endLine: 10,
        ),
      ],
      content: 'Second entity content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode category = RegistryNode(
      id: RegistryNodeId('project.registry.node.000002'),
      kindId: 'project.registry.heading.2',
      path: RegistryPath(const <String>['Registry', 'Category']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry', 'Category'],
          startLine: 3,
          endLine: 6,
        ),
      ],
      content: 'Category content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[entity],
    );

    final RegistryNode siblingCategory = RegistryNode(
      id: RegistryNodeId('project.registry.node.000004'),
      kindId: 'project.registry.heading.2',
      path: RegistryPath(const <String>['Registry', 'Second Category']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry', 'Second Category'],
          startLine: 7,
          endLine: 10,
        ),
      ],
      content: 'Second category content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[siblingEntity],
    );

    final RegistryNode root = RegistryNode(
      id: RegistryNodeId('project.registry.node.000001'),
      kindId: 'project.registry.heading.1',
      path: RegistryPath(const <String>['Registry']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 10,
        ),
      ],
      content: 'Root content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[category, siblingCategory],
    );

    final RegistrySnapshot treeSnapshot = RegistrySnapshot(
      projectId: 'project',
      projectAdapterId: 'project.registry.adapter.v1',
      sourceDocumentPath: documentPath,
      sourceRevision: 'abababababababababababababababababababab',
      sourceSnapshotFingerprint: fingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n'
          '## Category\n'
          'Category content.\n'
          '### Entity\n'
          'Entity content.\n'
          '## Second Category\n'
          'Second category content.\n'
          '### Second Entity\n'
          'Second entity content.\n',
      roots: <RegistryNode>[root],
    );

    final _QueuedRegistrySnapshotLoader loader = _QueuedRegistrySnapshotLoader(
      <Future<RegistrySnapshot> Function()>[() async => treeSnapshot],
    );

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
        registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      ),
    );

    await tester.pumpAndSettle();

    final Finder registryScrollable = find.descendant(
      of: find.byKey(const ValueKey<String>('registry-node-list')),
      matching: find.byType(Scrollable),
    );

    expect(registryScrollable, findsOneWidget);

    final Finder categoryRow = find.byKey(ValueKey<String>(category.id.value));

    await tester.scrollUntilVisible(
      categoryRow,
      180,
      scrollable: registryScrollable,
    );

    await tester.pumpAndSettle();

    expect(categoryRow, findsOneWidget);

    final Finder entityRow = find.byKey(ValueKey<String>(entity.id.value));

    expect(entityRow, findsNothing);

    final Finder categoryToggle = find.byKey(
      ValueKey<String>('registry-tree-toggle-${category.id.value}'),
    );

    expect(categoryToggle, findsOneWidget);

    await tester.tap(categoryToggle);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      entityRow,
      180,
      scrollable: registryScrollable,
    );

    await tester.pumpAndSettle();

    expect(entityRow, findsOneWidget);
    expect(find.text('Entity'), findsOneWidget);

    final Container categoryContainer = tester.widget<Container>(
      find.byKey(ValueKey<String>('registry-tree-row-${category.id.value}')),
    );

    final Container entityContainer = tester.widget<Container>(
      find.byKey(ValueKey<String>('registry-tree-row-${entity.id.value}')),
    );

    final BoxDecoration categoryDecoration =
        categoryContainer.decoration! as BoxDecoration;

    final BoxDecoration entityDecoration =
        entityContainer.decoration! as BoxDecoration;

    expect(categoryDecoration.color, isNot(entityDecoration.color));

    final Border categoryBorder = categoryDecoration.border! as Border;

    final Border entityBorder = entityDecoration.border! as Border;

    expect(categoryBorder.left.width, 4);
    expect(entityBorder.left.width, 4);

    final ListTile categoryTile = tester.widget<ListTile>(categoryRow);

    final ListTile entityTile = tester.widget<ListTile>(entityRow);

    final EdgeInsets categoryPadding =
        categoryTile.contentPadding! as EdgeInsets;

    final EdgeInsets entityPadding = entityTile.contentPadding! as EdgeInsets;

    expect(entityPadding.left, greaterThan(categoryPadding.left));

    final Finder siblingCategoryRow = find.byKey(
      ValueKey<String>(siblingCategory.id.value),
    );

    await tester.scrollUntilVisible(
      siblingCategoryRow,
      180,
      scrollable: registryScrollable,
    );

    await tester.pumpAndSettle();

    final Finder siblingCategoryToggle = find.byKey(
      ValueKey<String>('registry-tree-toggle-${siblingCategory.id.value}'),
    );

    expect(siblingCategoryToggle, findsOneWidget);

    await tester.tap(siblingCategoryToggle);
    await tester.pumpAndSettle();

    final Finder siblingEntityRow = find.byKey(
      ValueKey<String>(siblingEntity.id.value),
    );

    await tester.scrollUntilVisible(
      siblingEntityRow,
      180,
      scrollable: registryScrollable,
    );

    await tester.pumpAndSettle();

    expect(entityRow, findsNothing);
    expect(siblingEntityRow, findsOneWidget);
    expect(find.text('Second Entity'), findsOneWidget);

    await tester.scrollUntilVisible(
      siblingCategoryToggle,
      -180,
      scrollable: registryScrollable,
    );

    await tester.pumpAndSettle();

    await tester.tap(siblingCategoryToggle);
    await tester.pumpAndSettle();

    expect(siblingEntityRow, findsNothing);
  });

  testWidgets('shows search match reason, highlight and clear action', (
    WidgetTester tester,
  ) async {
    final _QueuedRegistrySnapshotLoader loader = _QueuedRegistrySnapshotLoader(
      <Future<RegistrySnapshot> Function()>[() async => snapshot],
    );

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: store,
        registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      ),
    );

    await tester.pumpAndSettle();

    final RegistryNode child = snapshot.roots.single.children.single;

    final Finder searchField = find.byKey(
      const ValueKey<String>('registry-search-field'),
    );

    await tester.enterText(searchField, 'Domain content');

    await tester.pumpAndSettle();

    expect(store.state?.searchQuery, 'Domain content');

    expect(find.text('Найдено: 1'), findsOneWidget);
    expect(find.text('Результаты поиска · 1 из 2'), findsOneWidget);
    expect(find.text('Совпадение в содержимом'), findsOneWidget);

    expect(
      find.byKey(
        ValueKey<String>(
          'registry-search-highlight-'
          '${child.id.value}',
        ),
      ),
      findsOneWidget,
    );

    final Finder selectedSearchResult = find.byKey(
      ValueKey<String>(child.id.value),
    );

    await tester.ensureVisible(selectedSearchResult);
    await tester.pumpAndSettle();

    await tester.tap(selectedSearchResult);
    await tester.pumpAndSettle();

    final Finder selectedBlockScreen = find.byKey(
      const ValueKey<String>('registry-selected-block-screen'),
    );

    expect(selectedBlockScreen, findsOneWidget);

    expect(
      find.descendant(
        of: selectedBlockScreen,
        matching: find.byKey(
          const ValueKey<String>('registry-selected-block-search-context'),
        ),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: selectedBlockScreen,
        matching: find.text('Поиск: "Domain content"'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: selectedBlockScreen,
        matching: find.text('Совпадение в содержимом'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: selectedBlockScreen,
        matching: find.byKey(
          const ValueKey<String>('registry-selected-block-search-highlight'),
        ),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: selectedBlockScreen,
        matching: find.byKey(
          const ValueKey<String>('registry-selected-block-content-highlight'),
        ),
      ),
      findsOneWidget,
    );

    expect(store.state?.searchQuery, 'Domain content');
    expect(store.state?.openRegistryNodeId, child.id);

    expect(find.text('Область: весь Registry'), findsOneWidget);

    final Finder blockClearSearchButton = find.byKey(
      const ValueKey<String>('registry-selected-block-search-clear'),
    );

    expect(blockClearSearchButton, findsOneWidget);

    await tester.tap(blockClearSearchButton);
    await tester.pumpAndSettle();

    expect(store.state?.searchQuery, isEmpty);
    expect(store.state?.openRegistryNodeId, child.id);
    expect(selectedBlockScreen, findsOneWidget);

    expect(
      find.byKey(
        const ValueKey<String>('registry-selected-block-search-context'),
      ),
      findsNothing,
    );

    expect(
      find.byKey(
        const ValueKey<String>('registry-selected-block-match-navigation'),
      ),
      findsNothing,
    );

    expect(
      find.byKey(
        const ValueKey<String>('registry-selected-block-content-highlight'),
      ),
      findsNothing,
    );

    expect(blockClearSearchButton, findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-selected-block-back')),
    );
    await tester.pumpAndSettle();

    expect(selectedBlockScreen, findsNothing);
    expect(store.state?.searchQuery, isEmpty);
    expect(find.text('Дерево Registry'), findsOneWidget);

    final Finder clearSearchButton = find.byKey(
      const ValueKey<String>('registry-search-clear'),
    );

    expect(clearSearchButton, findsNothing);

    final TextFormField restoredSearchField = tester.widget<TextFormField>(
      searchField,
    );

    expect(restoredSearchField.controller?.text, isEmpty);
  });

  testWidgets('resets Registry Studio context only after confirmation', (
    WidgetTester tester,
  ) async {
    final _QueuedRegistrySnapshotLoader loader = _QueuedRegistrySnapshotLoader(
      <Future<RegistrySnapshot> Function()>[() async => snapshot],
    );

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: store,
        registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      ),
    );

    await tester.pumpAndSettle();

    final RegistryNode child = snapshot.roots.single.children.single;

    final Finder searchField = find.byKey(
      const ValueKey<String>('registry-search-field'),
    );

    await tester.enterText(searchField, 'Domain content');
    await tester.pumpAndSettle();

    final Finder searchResult = find.byKey(ValueKey<String>(child.id.value));

    await tester.ensureVisible(searchResult);
    await tester.pumpAndSettle();

    await tester.tap(searchResult);
    await tester.pumpAndSettle();

    expect(store.state?.searchQuery, 'Domain content');
    expect(store.state?.openRegistryNodeId, child.id);

    final Finder selectedResetButton = find.byKey(
      const ValueKey<String>('registry-selected-block-reset'),
    );

    expect(selectedResetButton, findsOneWidget);

    await tester.tap(selectedResetButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('registry-studio-reset-dialog')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-studio-reset-cancel')),
    );
    await tester.pumpAndSettle();

    expect(store.state?.searchQuery, 'Domain content');
    expect(store.state?.openRegistryNodeId, child.id);

    await tester.tap(selectedResetButton);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-studio-reset-confirm')),
    );
    await tester.pumpAndSettle();

    expect(store.state?.searchQuery, isEmpty);
    expect(store.state?.openRegistryNodeId, isNull);
    expect(store.state?.openRegistryPath, isNull);
    expect(store.state?.selectedProblemIndex, isNull);

    expect(
      find.byKey(const ValueKey<String>('registry-selected-block-screen')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey<String>('registry-search-field')),
      findsOneWidget,
    );

    expect(find.text('Дерево Registry'), findsOneWidget);
    expect(find.text('Найдено: 1'), findsNothing);

    final TextFormField resetSearchField = tester.widget<TextFormField>(
      find.byKey(const ValueKey<String>('registry-search-field')),
    );

    expect(resetSearchField.controller?.text, isEmpty);

    expect(
      find.byKey(const ValueKey<String>('registry-node-list')),
      findsOneWidget,
    );
  });

  testWidgets(
    'scrolls to the first Registry content match and navigates matches',
    (WidgetTester tester) async {
      const String documentPath = 'search-navigation-registry.md';
      const String fingerprint =
          'git-blob:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd';

      final String longContent =
          '${List<String>.filled(35, 'Prefix line.').join('\n')}\n'
          'target phrase first\n'
          '${List<String>.filled(35, 'Middle line.').join('\n')}\n'
          'target phrase second';

      final RegistryNode searchNode = RegistryNode(
        id: RegistryNodeId('project.registry.node.search.navigation'),
        kindId: 'project.registry.heading.1',
        path: RegistryPath(const <String>['Registry']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: documentPath,
            sourceSnapshotFingerprint: fingerprint,
            headingPath: const <String>['Registry'],
            startLine: 1,
            endLine: 73,
          ),
        ],
        content: longContent,
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistrySnapshot searchSnapshot = RegistrySnapshot(
        projectId: 'project',
        projectAdapterId: 'project.registry.adapter.v1',
        sourceDocumentPath: documentPath,
        sourceRevision: 'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
        sourceSnapshotFingerprint: fingerprint,
        sourceContent: '# Registry\n$longContent\n',
        roots: <RegistryNode>[searchNode],
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () async => searchSnapshot,
          ]);

      await tester.pumpWidget(
        RegistryStudioApplication(
          registrySnapshotLoader: loader,
          registrySnapshotRefreshLoader: loader,
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
          registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        ),
      );

      await tester.pumpAndSettle();

      final Finder searchField = find.byType(TextField);

      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'target phrase');
      await tester.pumpAndSettle();

      final Finder searchResult = find.byKey(
        ValueKey<String>(searchNode.id.value),
      );

      await tester.ensureVisible(searchResult);
      await tester.pumpAndSettle();

      await tester.tap(searchResult);
      await tester.pumpAndSettle();

      final Finder selectedBlockScreen = find.byKey(
        const ValueKey<String>('registry-selected-block-screen'),
      );

      expect(selectedBlockScreen, findsOneWidget);

      final Finder selectedBlockScrollable = find.descendant(
        of: selectedBlockScreen,
        matching: find.byType(Scrollable),
      );

      expect(selectedBlockScrollable, findsOneWidget);

      final ScrollableState initialScrollableState = tester
          .state<ScrollableState>(selectedBlockScrollable);

      expect(initialScrollableState.position.pixels, greaterThan(0));

      expect(find.text('1 из 2'), findsOneWidget);

      final Finder previousButton = find.byKey(
        const ValueKey<String>('registry-selected-block-match-previous'),
      );

      final Finder nextButton = find.byKey(
        const ValueKey<String>('registry-selected-block-match-next'),
      );

      expect(tester.widget<IconButton>(previousButton).onPressed, isNull);

      expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);

      final double firstMatchScrollPosition =
          initialScrollableState.position.pixels;

      await tester.ensureVisible(nextButton);
      await tester.pumpAndSettle();

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('2 из 2'), findsOneWidget);

      final ScrollableState secondScrollableState = tester
          .state<ScrollableState>(selectedBlockScrollable);

      expect(
        secondScrollableState.position.pixels,
        greaterThan(firstMatchScrollPosition),
      );

      expect(tester.widget<IconButton>(previousButton).onPressed, isNotNull);

      expect(tester.widget<IconButton>(nextButton).onPressed, isNull);

      await tester.ensureVisible(previousButton);
      await tester.pumpAndSettle();

      await tester.tap(previousButton);
      await tester.pumpAndSettle();

      expect(find.text('1 из 2'), findsOneWidget);
    },
  );

  testWidgets('shows Registry failure and retries through the same loader', (
    WidgetTester tester,
  ) async {
    final _QueuedRegistrySnapshotLoader loader =
        _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
          () => Future<RegistrySnapshot>.error(StateError('offline')),
          () async => snapshot,
        ]);

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
        registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить Registry'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.byTooltip('Повторить загрузку Registry'), findsOneWidget);

    await tester.tap(find.byTooltip('Повторить загрузку Registry'));
    await tester.pumpAndSettle();

    expect(loader.loadCount, 2);
    expect(find.text('Узлов: 2'), findsOneWidget);
    expect(find.text('Не удалось загрузить Registry'), findsNothing);
  });

  test(
    'searches the complete recursive Registry and preserves exact search query',
    () async {
      const String previousFingerprint =
          'git-blob:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

      final RegistryNode currentRoot = snapshot.roots.single;
      final RegistryNode currentChild = currentRoot.children.single;

      final RegistryNode previousChild = RegistryNode(
        id: currentChild.id,
        kindId: currentChild.kindId,
        path: currentChild.path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: snapshot.sourceDocumentPath,
            sourceSnapshotFingerprint: previousFingerprint,
            headingPath: currentChild.path.segments,
            startLine: 3,
            endLine: 4,
          ),
        ],
        content: 'Previous domain content.',
        businessScopeOwnerId: currentChild.businessScopeOwnerId,
        children: const <RegistryNode>[],
      );

      final RegistryNode previousRoot = RegistryNode(
        id: currentRoot.id,
        kindId: currentRoot.kindId,
        path: currentRoot.path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: snapshot.sourceDocumentPath,
            sourceSnapshotFingerprint: previousFingerprint,
            headingPath: currentRoot.path.segments,
            startLine: 1,
            endLine: 4,
          ),
        ],
        content: currentRoot.content,
        businessScopeOwnerId: currentRoot.businessScopeOwnerId,
        children: <RegistryNode>[previousChild],
      );

      final RegistrySnapshot previousSnapshot = RegistrySnapshot(
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: '0000000000000000000000000000000000000000',
        sourceSnapshotFingerprint: previousFingerprint,
        sourceContent:
            '# Registry\n'
            'Root content.\n'
            '## Domain\n'
            'Previous domain content.\n',
        roots: <RegistryNode>[previousRoot],
      );

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(
            <Future<RegistrySnapshot> Function()>[
              () =>
                  Future<RegistrySnapshot>.error(StateError('refresh offline')),
              () async => snapshot,
            ],
            exactSnapshots: <String, RegistrySnapshot>{
              snapshot.sourceRevision: snapshot,
              previousSnapshot.sourceRevision: previousSnapshot,
            },
          );

      final _MemoryRegistryRevisionStateStore store =
          _MemoryRegistryRevisionStateStore(
            state: RegistryRevisionState(
              projectId: snapshot.projectId,
              projectAdapterId: snapshot.projectAdapterId,
              sourceDocumentPath: snapshot.sourceDocumentPath,
              currentRevision: snapshot.sourceRevision,
              previousRevision: previousSnapshot.sourceRevision,
            ),
          );

      final RegistryExplorerCubit cubit = RegistryExplorerCubit(
        snapshotLoader: loader,
        snapshotRefreshLoader: loader,
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
        analysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        snapshotComparator: const RegistrySnapshotComparator(),
      );

      addTearDown(() async {
        if (!cubit.isClosed) {
          await cubit.close();
        }
      });

      await cubit.restore();

      final List<String> queries = <String>[
        currentChild.id.value,
        'Registry → Domain',
        currentChild.kindId,
        currentChild.content,
        snapshot.sourceDocumentPath,
        snapshot.sourceSnapshotFingerprint,
        'Registry / Domain',
        '3-4',
      ];

      for (final String query in queries) {
        await cubit.updateSearchQuery(query);

        final RegistryExplorerLoaded loaded =
            cubit.state as RegistryExplorerLoaded;

        expect(loaded.searchQuery, query);
        expect(
          loaded.searchResults.map((RegistryNode node) => node.id),
          contains(currentChild.id),
          reason: 'Search query: $query',
        );
      }

      const String exactSearchQuery = '  Domain content.  ';

      await cubit.updateSearchQuery(exactSearchQuery);

      RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.searchQuery, exactSearchQuery);
      expect(store.state?.searchQuery, exactSearchQuery);
      expect(
        loaded.searchResults.map((RegistryNode node) => node.id),
        contains(currentChild.id),
      );

      await cubit.selectProblem(0);

      loaded = cubit.state as RegistryExplorerLoaded;
      expect(loaded.searchQuery, exactSearchQuery);
      expect(store.state?.searchQuery, exactSearchQuery);

      await cubit.selectRegistryNode(currentChild.id);

      loaded = cubit.state as RegistryExplorerLoaded;
      expect(loaded.searchQuery, exactSearchQuery);
      expect(store.state?.searchQuery, exactSearchQuery);

      await cubit.confirmCurrentAsCleanBaseline();

      loaded = cubit.state as RegistryExplorerLoaded;
      expect(loaded.searchQuery, exactSearchQuery);
      expect(store.state?.searchQuery, exactSearchQuery);

      await cubit.refresh();

      final RegistryExplorerFailure failure =
          cubit.state as RegistryExplorerFailure;

      expect(failure.searchQueryBeforeRefresh, exactSearchQuery);
      expect(store.state?.searchQuery, exactSearchQuery);

      await cubit.retry();

      loaded = cubit.state as RegistryExplorerLoaded;

      expect(loaded.searchQuery, exactSearchQuery);
      expect(store.state?.searchQuery, exactSearchQuery);
      expect(
        loaded.searchResults.map((RegistryNode node) => node.id),
        contains(currentChild.id),
      );

      await cubit.close();

      final _QueuedRegistrySnapshotLoader restartLoader =
          _QueuedRegistrySnapshotLoader(
            <Future<RegistrySnapshot> Function()>[],
            exactSnapshots: <String, RegistrySnapshot>{
              snapshot.sourceRevision: snapshot,
              previousSnapshot.sourceRevision: previousSnapshot,
            },
          );

      final RegistryExplorerCubit restartedCubit = RegistryExplorerCubit(
        snapshotLoader: restartLoader,
        snapshotRefreshLoader: restartLoader,
        snapshotRevisionLoader: restartLoader,
        revisionStateStore: store,
        analysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
        snapshotComparator: const RegistrySnapshotComparator(),
      );

      addTearDown(restartedCubit.close);

      await restartedCubit.restore();

      final RegistryExplorerLoaded restarted =
          restartedCubit.state as RegistryExplorerLoaded;

      expect(restarted.searchQuery, exactSearchQuery);
      expect(
        restarted.searchResults.map((RegistryNode node) => node.id),
        contains(currentChild.id),
      );
    },
  );

  testWidgets('persists exact Registry search query from Explorer field', (
    WidgetTester tester,
  ) async {
    final _QueuedRegistrySnapshotLoader loader = _QueuedRegistrySnapshotLoader(
      <Future<RegistrySnapshot> Function()>[() async => snapshot],
    );

    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: loader,
        registrySnapshotRefreshLoader: loader,
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: store,
        registryAnalysisHistoryStore: _MemoryRegistryAnalysisHistoryStore(),
      ),
    );

    await tester.pumpAndSettle();

    final Finder searchField = find.byKey(
      const ValueKey<String>('registry-search-field'),
    );

    expect(searchField, findsOneWidget);

    const String exactSearchQuery = '  project.registry.node.000002  ';

    await tester.enterText(searchField, exactSearchQuery);

    await tester.pumpAndSettle();

    expect(store.state?.searchQuery, exactSearchQuery);
    expect(find.text('Найдено: 1'), findsOneWidget);
    expect(find.text('Результаты поиска · 1 из 2'), findsOneWidget);
  });
}

final class _QueuedRegistrySnapshotLoader
    implements
        RegistrySnapshotLoader,
        RegistrySnapshotRefreshLoader,
        RegistrySnapshotRevisionLoader {
  _QueuedRegistrySnapshotLoader(
    this.loads, {
    Map<String, RegistrySnapshot> exactSnapshots =
        const <String, RegistrySnapshot>{},
  }) : exactSnapshots = Map<String, RegistrySnapshot>.unmodifiable(
         exactSnapshots,
       );

  final List<Future<RegistrySnapshot> Function()> loads;
  final Map<String, RegistrySnapshot> exactSnapshots;
  final List<String> requestedRevisions = <String>[];
  final List<String> refreshBaseRevisions = <String>[];

  int loadCount = 0;

  @override
  Future<RegistrySnapshot> loadSnapshot() {
    if (loadCount >= loads.length) {
      return Future<RegistrySnapshot>.error(
        StateError('No configured Registry snapshot load remains.'),
      );
    }

    final Future<RegistrySnapshot> Function() load = loads[loadCount];

    loadCount += 1;

    return load();
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAfterRevision(String previousRevision) {
    refreshBaseRevisions.add(previousRevision);
    return loadSnapshot();
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAtRevision(String sourceRevision) {
    requestedRevisions.add(sourceRevision);

    final RegistrySnapshot? snapshot = exactSnapshots[sourceRevision];

    if (snapshot == null) {
      return Future<RegistrySnapshot>.error(
        StateError(
          'No exact Registry snapshot is configured for '
          '$sourceRevision.',
        ),
      );
    }

    return Future<RegistrySnapshot>.value(snapshot);
  }
}

final class _MemoryRegistryAnalysisHistoryStore
    implements RegistryAnalysisHistoryStore {
  final List<RegistryAnalysisHistoryEntry> entries =
      <RegistryAnalysisHistoryEntry>[];

  @override
  Future<List<RegistryAnalysisHistoryEntry>> loadHistory() async {
    return List<RegistryAnalysisHistoryEntry>.unmodifiable(entries);
  }

  @override
  Future<void> appendHistoryEntry(RegistryAnalysisHistoryEntry entry) async {
    entries.add(entry);
  }
}

final class _MemoryRegistryRevisionStateStore
    implements RegistryRevisionStateStore {
  _MemoryRegistryRevisionStateStore({this.state});

  RegistryRevisionState? state;

  int loadCount = 0;
  int saveCount = 0;

  @override
  Future<RegistryRevisionState?> loadRevisionState() async {
    loadCount += 1;

    return state;
  }

  @override
  Future<void> saveRevisionState(RegistryRevisionState state) async {
    saveCount += 1;
    this.state = state;
  }
}
