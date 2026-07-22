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

      expect(historyStore.entries, hasLength(3));
      final RegistryAnalysisHistoryEntry sameRevisionHistoryEntry =
          historyStore.entries[2];
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

      expect(loader.loadCount, 2);

      final Finder statusButton = find.byKey(
        const ValueKey<String>('registry-status-center-button'),
      );

      expect(statusButton, findsOneWidget);

      await tester.tap(statusButton);
      await tester.pumpAndSettle();

      final Finder statusSheet = find.byKey(
        const ValueKey<String>('registry-status-center-sheet'),
      );

      final Finder statusScrollable = find
          .descendant(of: statusSheet, matching: find.byType(Scrollable))
          .first;

      final Finder previousRevisionText = find.descendant(
        of: statusSheet,
        matching: find.text(snapshot.sourceRevision),
      );

      expect(statusSheet, findsOneWidget);
      expect(statusScrollable, findsOneWidget);

      await tester.scrollUntilVisible(
        previousRevisionText,
        240,
        scrollable: statusScrollable,
      );

      expect(
        find.descendant(
          of: statusSheet,
          matching: find.text('Предыдущая revision'),
        ),
        findsOneWidget,
      );

      expect(previousRevisionText, findsOneWidget);

      expect(
        find.text('Предыдущая revision: ${snapshot.sourceRevision}'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'opens the Registry status center without changing Registry state',
    (WidgetTester tester) async {
      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () async => snapshot,
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

      final Finder statusButton = find.byKey(
        const ValueKey<String>('registry-status-center-button'),
      );

      expect(statusButton, findsOneWidget);

      final Finder searchField = find.byKey(
        const ValueKey<String>('registry-search-field'),
      );

      final Finder searchEditable = find.descendant(
        of: searchField,
        matching: find.byType(EditableText),
      );

      expect(searchField, findsOneWidget);
      expect(searchEditable, findsOneWidget);

      final FocusNode searchFocusNode = tester
          .widget<EditableText>(searchEditable)
          .focusNode;

      final List<bool> searchFocusStates = <bool>[];

      void recordSearchFocusState() {
        searchFocusStates.add(searchFocusNode.hasFocus);
      }

      searchFocusNode.addListener(recordSearchFocusState);

      addTearDown(() => searchFocusNode.removeListener(recordSearchFocusState));

      await tester.showKeyboard(searchEditable);
      expect(searchFocusNode.hasFocus, isTrue);

      await tester.tap(statusButton);
      await tester.pumpAndSettle();

      Finder statusSheet = find.byKey(
        const ValueKey<String>('registry-status-center-sheet'),
      );

      expect(statusSheet, findsOneWidget);

      expect(
        find.descendant(
          of: statusSheet,
          matching: find.text('Проблемы Registry: 0'),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: statusSheet,
          matching: find.text('Clean baseline не подтверждён'),
        ),
        findsOneWidget,
      );

      final Finder statusScrollable = find
          .descendant(of: statusSheet, matching: find.byType(Scrollable))
          .first;

      final Finder openHistoryButton = find.byKey(
        const ValueKey<String>('registry-status-center-open-history'),
      );

      expect(statusScrollable, findsOneWidget);

      await tester.scrollUntilVisible(
        openHistoryButton,
        240,
        scrollable: statusScrollable,
      );

      expect(
        find.descendant(
          of: statusSheet,
          matching: find.text('История анализа: 1'),
        ),
        findsOneWidget,
      );

      searchFocusStates.clear();

      await tester.tap(openHistoryButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(searchFocusStates, isNot(contains(true)));
      expect(searchFocusNode.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      expect(statusSheet, findsNothing);

      expect(
        find.byKey(const ValueKey<String>('registry-analysis-history-sheet')),
        findsOneWidget,
      );

      expect(find.text('Событие: Первичная загрузка Registry'), findsOneWidget);

      expect(
        find.textContaining(
          'Каждая запись фиксирует результат загрузки или refresh',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Закрыть историю анализа'));

      await tester.pumpAndSettle();

      await tester.showKeyboard(searchEditable);
      expect(searchFocusNode.hasFocus, isTrue);

      await tester.tap(statusButton);
      await tester.pumpAndSettle();

      statusSheet = find.byKey(
        const ValueKey<String>('registry-status-center-sheet'),
      );

      expect(statusSheet, findsOneWidget);

      final Finder confirmBaselineButton = find.byKey(
        const ValueKey<String>('registry-status-center-confirm-baseline'),
      );

      await tester.dragUntilVisible(
        confirmBaselineButton,
        statusScrollable,
        const Offset(0, -80),
      );

      await tester.pumpAndSettle();

      expect(confirmBaselineButton.hitTestable(), findsOneWidget);

      searchFocusStates.clear();

      await tester.tap(confirmBaselineButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(searchFocusStates, isNot(contains(true)));
      expect(searchFocusNode.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      expect(find.text('Подтвердить clean baseline?'), findsOneWidget);

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(store.state?.cleanBaselineRevision, isNull);
      expect(store.state?.openRegistryNodeId, isNull);
      expect(store.state?.selectedProblemIndex, isNull);
      expect(store.state?.searchQuery, isEmpty);
    },
  );

  testWidgets(
    'lays out the clean baseline action below its content on mobile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
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

      await tester.tap(
        find.byKey(const ValueKey<String>('registry-status-center-button')),
      );

      await tester.pumpAndSettle();

      final Finder statusSheet = find.byKey(
        const ValueKey<String>('registry-status-center-sheet'),
      );

      final Finder statusScrollable = find
          .descendant(of: statusSheet, matching: find.byType(Scrollable))
          .first;

      final Finder card = find.byKey(
        const ValueKey<String>('registry-status-center-clean-baseline-card'),
      );

      final Finder description = find.byKey(
        const ValueKey<String>(
          'registry-status-center-clean-baseline-description',
        ),
      );

      final Finder confirmButton = find.byKey(
        const ValueKey<String>('registry-status-center-confirm-baseline'),
      );

      await tester.dragUntilVisible(
        confirmButton,
        statusScrollable,
        const Offset(0, -80),
      );

      await tester.pumpAndSettle();

      expect(card, findsOneWidget);
      expect(description, findsOneWidget);
      expect(confirmButton.hitTestable(), findsOneWidget);

      expect(find.text('Clean baseline не подтверждён'), findsOneWidget);

      expect(
        find.text(
          'Текущая revision ещё не сохранена как '
          'подтверждённая инженером контрольная точка. '
          'Clean baseline не изменяется автоматически '
          'при refresh.',
        ),
        findsOneWidget,
      );

      final Rect cardRect = tester.getRect(card);
      final Rect descriptionRect = tester.getRect(description);
      final Rect buttonRect = tester.getRect(confirmButton);

      expect(buttonRect.top, greaterThan(descriptionRect.bottom));

      expect(buttonRect.width, greaterThan(cardRect.width * 0.75));
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
      final Finder statusButton = find.byKey(
        const ValueKey<String>('registry-status-center-button'),
      );

      expect(statusButton, findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('registry-analysis-history-button')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('registry-problem-queue')),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('registry-previous-comparison-summary'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('registry-clean-baseline-summary')),
        findsNothing,
      );

      await tester.tap(statusButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Сравнение с предыдущей revision: нет baseline'),
        findsOneWidget,
      );

      expect(find.text('Clean baseline не подтверждён'), findsOneWidget);

      final Finder statusSheet = find.byKey(
        const ValueKey<String>('registry-status-center-sheet'),
      );

      final Finder statusScrollable = find
          .descendant(of: statusSheet, matching: find.byType(Scrollable))
          .first;

      final Finder openHistoryButton = find.byKey(
        const ValueKey<String>('registry-status-center-open-history'),
      );

      final Finder confirmBaselineButton = find.byKey(
        const ValueKey<String>('registry-status-center-confirm-baseline'),
      );

      expect(statusSheet, findsOneWidget);
      expect(statusScrollable, findsOneWidget);

      await tester.scrollUntilVisible(
        openHistoryButton,
        240,
        scrollable: statusScrollable,
      );

      expect(find.text('История анализа: 1'), findsOneWidget);

      await tester.scrollUntilVisible(
        confirmBaselineButton,
        -240,
        scrollable: statusScrollable,
      );

      await tester.tap(confirmBaselineButton);

      await tester.pumpAndSettle();

      expect(find.text('Подтвердить clean baseline?'), findsOneWidget);

      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();

      expect(store.state?.cleanBaselineRevision, snapshot.sourceRevision);

      await tester.tap(find.byTooltip('Перезагрузить Registry'));

      await tester.pumpAndSettle();

      expect(historyStore.entries, hasLength(2));

      await tester.tap(statusButton);
      await tester.pumpAndSettle();

      expect(find.text('Проблемы Registry: 2'), findsOneWidget);

      expect(find.text('Изменения с предыдущей revision: 2'), findsOneWidget);

      expect(
        find.textContaining('Расхождения с clean baseline: 2'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        openHistoryButton,
        240,
        scrollable: statusScrollable,
      );

      expect(find.text('История анализа: 2'), findsOneWidget);

      await tester.tap(openHistoryButton);

      await tester.pumpAndSettle();

      expect(find.text('Событие: Обнаружена новая revision'), findsOneWidget);

      final Finder historySheet = find.byKey(
        const ValueKey<String>('registry-analysis-history-sheet'),
      );

      final Finder historyScrollable = find
          .descendant(of: historySheet, matching: find.byType(Scrollable))
          .first;

      final Finder initialLoadEvent = find.text(
        'Событие: Первичная загрузка Registry',
      );

      expect(historySheet, findsOneWidget);
      expect(historyScrollable, findsOneWidget);

      await tester.scrollUntilVisible(
        initialLoadEvent,
        240,
        scrollable: historyScrollable,
      );

      expect(initialLoadEvent, findsOneWidget);

      await tester.tap(find.byTooltip('Закрыть историю анализа'));

      await tester.pumpAndSettle();

      await tester.tap(statusButton);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('registry-status-center-open-problems'),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('registry-problem-queue-fullscreen')),
        findsOneWidget,
      );

      expect(find.text('Очередь проблем: 2'), findsOneWidget);

      expect(store.state?.cleanBaselineRevision, snapshot.sourceRevision);
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

    final Finder backButton = find.byKey(
      const ValueKey<String>('registry-selected-block-back'),
    );

    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
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

  testWidgets(
    'places Registry Studio title before status reset and refresh actions on mobile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
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

      final Finder title = find.byKey(
        const ValueKey<String>('registry-explorer-title'),
      );
      final Finder statusButton = find.byKey(
        const ValueKey<String>('registry-status-center-button'),
      );
      final Finder resetButton = find.byKey(
        const ValueKey<String>('registry-studio-reset'),
      );
      final Finder refreshButton = find.byKey(
        const ValueKey<String>('registry-refresh-button'),
      );

      expect(title, findsOneWidget);
      expect(tester.widget<Text>(title).data, 'Registry Studio');
      expect(statusButton.hitTestable(), findsOneWidget);
      expect(resetButton.hitTestable(), findsOneWidget);
      expect(refreshButton.hitTestable(), findsOneWidget);

      expect(
        find.descendant(
          of: statusButton,
          matching: find.byIcon(Icons.fact_check_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: resetButton,
          matching: find.byIcon(Icons.layers_clear_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: refreshButton,
          matching: find.byIcon(Icons.refresh),
        ),
        findsOneWidget,
      );

      final Rect titleRect = tester.getRect(title);
      final Rect statusRect = tester.getRect(statusButton);
      final Rect resetRect = tester.getRect(resetButton);
      final Rect refreshRect = tester.getRect(refreshButton);

      expect(titleRect.left, lessThan(statusRect.left));
      expect(titleRect.right, lessThanOrEqualTo(statusRect.left));

      expect(statusRect.left, lessThan(resetRect.left));
      expect(resetRect.left, lessThan(refreshRect.left));

      expect(titleRect.center.dy, closeTo(statusRect.center.dy, 1));
      expect(statusRect.center.dy, closeTo(resetRect.center.dy, 1));
      expect(resetRect.center.dy, closeTo(refreshRect.center.dy, 1));
    },
  );

  testWidgets('restores persisted Registry Explorer filter after restart', (
    WidgetTester tester,
  ) async {
    final _MemoryRegistryRevisionStateStore store =
        _MemoryRegistryRevisionStateStore();
    final _MemoryRegistryAnalysisHistoryStore historyStore =
        _MemoryRegistryAnalysisHistoryStore();

    final _QueuedRegistrySnapshotLoader firstLoader =
        _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
          () async => snapshot,
        ]);

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: firstLoader,
        registrySnapshotRefreshLoader: firstLoader,
        registrySnapshotRevisionLoader: firstLoader,
        registryRevisionStateStore: store,
        registryAnalysisHistoryStore: historyStore,
      ),
    );

    await tester.pumpAndSettle();

    final Finder filterButton = find.byKey(
      const ValueKey<String>('registry-view-filter-button'),
    );

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-branches')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(store.state?.registryViewFilter, 'branches');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final _QueuedRegistrySnapshotLoader restoredLoader =
        _QueuedRegistrySnapshotLoader(
          const <Future<RegistrySnapshot> Function()>[],
          exactSnapshots: <String, RegistrySnapshot>{
            snapshot.sourceRevision: snapshot,
          },
        );

    await tester.pumpWidget(
      RegistryStudioApplication(
        registrySnapshotLoader: restoredLoader,
        registrySnapshotRefreshLoader: restoredLoader,
        registrySnapshotRevisionLoader: restoredLoader,
        registryRevisionStateStore: store,
        registryAnalysisHistoryStore: historyStore,
      ),
    );

    await tester.pumpAndSettle();

    final Finder restoredFilterButton = find.byKey(
      const ValueKey<String>('registry-view-filter-button'),
    );

    expect(
      tester.widget<IconButton>(restoredFilterButton).tooltip,
      'Фильтр: Ветки',
    );

    await tester.tap(restoredFilterButton);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey<String>('registry-view-filter-branches')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey<String>('registry-view-filter-all')),
          )
          .selected,
      isFalse,
    );
  });

  testWidgets('filters only visible Registry nodes and keeps search global', (
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

    final RegistryNode root = snapshot.roots.single;
    final RegistryNode child = root.children.single;

    final Finder rootNode = find.byKey(ValueKey<String>(root.id.value));

    final Finder childNode = find.byKey(ValueKey<String>(child.id.value));

    final Finder filterButton = find.byKey(
      const ValueKey<String>('registry-view-filter-button'),
    );

    expect(rootNode, findsOneWidget);
    expect(filterButton, findsOneWidget);

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('registry-view-filter-sheet')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-leaves')),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(rootNode, findsNothing);
    expect(childNode, findsOneWidget);

    expect(
      find.textContaining('Фильтр: Конечные блоки · показано:'),
      findsOneWidget,
    );

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-branches')),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(rootNode, findsOneWidget);
    expect(childNode, findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('registry-search-field')),
      'Domain content',
    );

    await tester.pumpAndSettle();

    expect(find.text('Найдено: 1'), findsOneWidget);

    expect(find.text('Фильтр: Ветки · показано: 0 из 1'), findsOneWidget);

    expect(childNode, findsNothing);

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-all')),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    expect(childNode, findsOneWidget);
    expect(find.text('Найдено: 1'), findsOneWidget);

    expect(store.state?.searchQuery, 'Domain content');
    expect(store.state?.registryViewFilter, 'all');
    expect(store.state?.openRegistryNodeId, isNull);
    expect(store.state?.selectedProblemIndex, isNull);
    expect(loader.loadCount, 1);
  });

  testWidgets('opens a filtered Registry branch as a complete local tree', (
    WidgetTester tester,
  ) async {
    const String filteredFingerprint =
        'git-blob:abababababababababababababababababababab';

    final RegistryNode leaf = RegistryNode(
      id: RegistryNodeId('project.registry.node.filtered.000004'),
      kindId: 'project.registry.heading.4',
      path: RegistryPath(const <String>[
        'Registry',
        'Branch',
        'Nested Branch',
        'Leaf',
      ]),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: filteredFingerprint,
          headingPath: const <String>[
            'Registry',
            'Branch',
            'Nested Branch',
            'Leaf',
          ],
          startLine: 7,
          endLine: 8,
        ),
      ],
      content: 'Leaf content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode nestedBranch = RegistryNode(
      id: RegistryNodeId('project.registry.node.filtered.000003'),
      kindId: 'project.registry.heading.3',
      path: RegistryPath(const <String>['Registry', 'Branch', 'Nested Branch']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: filteredFingerprint,
          headingPath: const <String>['Registry', 'Branch', 'Nested Branch'],
          startLine: 5,
          endLine: 8,
        ),
      ],
      content: 'Nested branch content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[leaf],
    );

    final RegistryNode branch = RegistryNode(
      id: RegistryNodeId('project.registry.node.filtered.000002'),
      kindId: 'project.registry.heading.2',
      path: RegistryPath(const <String>['Registry', 'Branch']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: filteredFingerprint,
          headingPath: const <String>['Registry', 'Branch'],
          startLine: 3,
          endLine: 8,
        ),
      ],
      content: 'Branch content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[nestedBranch],
    );

    final RegistryNode root = RegistryNode(
      id: RegistryNodeId('project.registry.node.filtered.000001'),
      kindId: 'project.registry.heading.1',
      path: RegistryPath(const <String>['Registry']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: snapshot.sourceDocumentPath,
          sourceSnapshotFingerprint: filteredFingerprint,
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 8,
        ),
      ],
      content: 'Root content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[branch],
    );

    final RegistrySnapshot filteredSnapshot = RegistrySnapshot(
      projectId: snapshot.projectId,
      projectAdapterId: snapshot.projectAdapterId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: '3333333333333333333333333333333333333333',
      sourceSnapshotFingerprint: filteredFingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n'
          '## Branch\n'
          'Branch content.\n'
          '### Nested Branch\n'
          'Nested branch content.\n'
          '#### Leaf\n'
          'Leaf content.\n',
      roots: <RegistryNode>[root],
    );

    final _QueuedRegistrySnapshotLoader loader = _QueuedRegistrySnapshotLoader(
      <Future<RegistrySnapshot> Function()>[() async => filteredSnapshot],
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

    final Finder filterButton = find.byKey(
      const ValueKey<String>('registry-view-filter-button'),
    );

    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-branches')),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-view-filter-close')),
    );
    await tester.pumpAndSettle();

    final Finder rootRow = find.byKey(ValueKey<String>(root.id.value));
    final Finder branchRow = find.byKey(ValueKey<String>(branch.id.value));
    final Finder nestedBranchRow = find.byKey(
      ValueKey<String>(nestedBranch.id.value),
    );
    final Finder leafRow = find.byKey(ValueKey<String>(leaf.id.value));

    final Finder nestedBranchToggle = find.byKey(
      ValueKey<String>('registry-tree-toggle-${nestedBranch.id.value}'),
    );

    expect(rootRow, findsOneWidget);
    expect(branchRow, findsOneWidget);
    final Finder filteredBranchNodeList = find.byKey(
      const ValueKey<String>('registry-node-list'),
    );

    expect(filteredBranchNodeList, findsOneWidget);

    final Finder filteredBranchScrollable = find
        .descendant(
          of: filteredBranchNodeList,
          matching: find.byType(Scrollable),
        )
        .first;

    final Finder deepestFilteredBranchNode = nestedBranchRow;

    await tester.scrollUntilVisible(
      deepestFilteredBranchNode,
      240,
      scrollable: filteredBranchScrollable,
    );

    await tester.pumpAndSettle();

    expect(deepestFilteredBranchNode, findsOneWidget);
    expect(leafRow, findsNothing);
    expect(nestedBranchToggle, findsNothing);

    expect(
      find.descendant(
        of: rootRow,
        matching: find.byIcon(Icons.folder_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: branchRow,
        matching: find.byIcon(Icons.folder_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: nestedBranchRow,
        matching: find.byIcon(Icons.folder_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(branchRow);
    await tester.pumpAndSettle();

    expect(find.text('Ветка: Branch'), findsOneWidget);

    final Finder branchScopeBack = find.byKey(
      const ValueKey<String>('registry-branch-scope-back'),
    );

    expect(branchScopeBack, findsOneWidget);

    expect(rootRow, findsNothing);
    expect(branchRow, findsOneWidget);
    expect(nestedBranchRow, findsOneWidget);
    expect(leafRow, findsNothing);
    expect(nestedBranchToggle, findsOneWidget);

    expect(
      find.descendant(
        of: branchRow,
        matching: find.byIcon(Icons.folder_open_outlined),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: branchRow,
        matching: find.byIcon(Icons.account_tree_outlined),
      ),
      findsNothing,
    );

    await tester.tap(nestedBranchToggle);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      leafRow,
      240,
      scrollable: filteredBranchScrollable,
    );

    await tester.pumpAndSettle();

    expect(leafRow, findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('registry-search-field')),
      'Nested branch content',
    );

    await tester.pumpAndSettle();

    expect(nestedBranchRow, findsOneWidget);
    expect(nestedBranchToggle, findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('registry-search-clear')),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ветка: Branch'), findsOneWidget);
    expect(nestedBranchToggle, findsOneWidget);
    await tester.scrollUntilVisible(
      leafRow,
      240,
      scrollable: filteredBranchScrollable,
    );

    await tester.pumpAndSettle();

    expect(leafRow, findsOneWidget);

    await tester.scrollUntilVisible(
      branchScopeBack,
      -240,
      scrollable: filteredBranchScrollable,
    );

    await tester.pumpAndSettle();

    expect(branchScopeBack, findsOneWidget);

    await tester.tap(branchScopeBack);

    await tester.pumpAndSettle();

    expect(rootRow, findsOneWidget);
    expect(branchRow, findsOneWidget);
    expect(nestedBranchRow, findsOneWidget);
    expect(leafRow, findsNothing);
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

      expect(find.text('1/2'), findsOneWidget);

      final Finder previousButton = find.byKey(
        const ValueKey<String>('registry-selected-block-match-previous'),
      );

      final Finder nextButton = find.byKey(
        const ValueKey<String>('registry-selected-block-match-next'),
      );

      final Finder matchNavigation = find.byKey(
        const ValueKey<String>('registry-selected-block-match-navigation'),
      );

      expect(matchNavigation, findsOneWidget);

      expect(
        find.descendant(
          of: selectedBlockScreen,
          matching: find.text('Закрыть'),
        ),
        findsNothing,
      );

      expect(tester.widget<IconButton>(previousButton).onPressed, isNull);

      expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);

      final double firstMatchScrollPosition =
          initialScrollableState.position.pixels;

      initialScrollableState.position.jumpTo(
        initialScrollableState.position.maxScrollExtent,
      );
      await tester.pumpAndSettle();

      final Rect selectedBlockRect = tester.getRect(selectedBlockScreen);

      final Rect matchNavigationRect = tester.getRect(matchNavigation);

      expect(selectedBlockRect.overlaps(matchNavigationRect), isTrue);

      expect(
        matchNavigationRect.bottom,
        lessThanOrEqualTo(selectedBlockRect.bottom),
      );

      await tester.ensureVisible(nextButton);
      await tester.pumpAndSettle();

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('2/2'), findsOneWidget);

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

      expect(find.text('1/2'), findsOneWidget);
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
