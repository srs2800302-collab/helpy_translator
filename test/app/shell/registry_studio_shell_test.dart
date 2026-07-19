import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/bootstrap/registry_studio_application.dart';
import 'package:helpy_translator/app/shell/registry_studio_shell.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
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

      final RegistryExplorerCubit cubit = RegistryExplorerCubit(
        snapshotLoader: loader,
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
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
    },
  );

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
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
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
      snapshotRevisionLoader: loader,
      revisionStateStore: store,
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

      final RegistryExplorerCubit cubit = RegistryExplorerCubit(
        snapshotLoader: loader,
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
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
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
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
        snapshotRevisionLoader: loader,
        revisionStateStore: store,
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

    final RegistryExplorerCubit cubit = RegistryExplorerCubit(
      snapshotLoader: loader,
      snapshotRevisionLoader: loader,
      revisionStateStore: store,
      snapshotComparator: const RegistrySnapshotComparator(),
    );

    addTearDown(cubit.close);

    await cubit.restore();

    expect(cubit.state, isA<RegistryExplorerLoaded>());
    expect(loader.loadCount, 1);
    expect(store.loadCount, 1);
    expect(store.saveCount, 1);

    await cubit.refresh();

    expect(cubit.state, isA<RegistryExplorerFailure>());
    expect(loader.loadCount, 2);
    expect(store.loadCount, 1);
    expect(store.saveCount, 1);

    await cubit.retry();

    final RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;

    expect(loaded.snapshot, same(latestSnapshot));
    expect(loaded.previousSnapshot, same(snapshot));
    expect(loader.loadCount, 3);
    expect(loader.requestedRevisions, isEmpty);
    expect(store.loadCount, 1);
    expect(store.saveCount, 2);
    expect(store.state?.currentRevision, latestSnapshot.sourceRevision);
    expect(store.state?.previousRevision, snapshot.sourceRevision);
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
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
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
          ]);

      final _MemoryRegistryRevisionStateStore store =
          _MemoryRegistryRevisionStateStore();

      await tester.pumpWidget(
        RegistryStudioApplication(
          registrySnapshotLoader: loader,
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: store,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Изменения с предыдущей revision: нет baseline'),
        findsOneWidget,
      );

      expect(find.text('Clean baseline: не подтверждён'), findsOneWidget);

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
        scrollable: find.byType(Scrollable).first,
      );

      expect(addedProblem, findsOneWidget);
      expect(find.text('Затронуто · Added Domain'), findsOneWidget);

      await tester.scrollUntilVisible(
        changedProblem,
        -180,
        scrollable: find.byType(Scrollable).first,
      );

      expect(changedProblem, findsOneWidget);

      await tester.ensureVisible(problemQueue);
      await tester.pumpAndSettle();

      await tester.tap(problemQueue);
      await tester.pumpAndSettle();

      expect(changedProblem, findsNothing);
      expect(addedProblem, findsNothing);

      final Finder fullScreenButton = find.byTooltip(
        'Открыть очередь проблем на весь экран',
      );

      await tester.ensureVisible(fullScreenButton);
      await tester.pumpAndSettle();

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

      await tester.ensureVisible(fullScreenButton);
      await tester.pumpAndSettle();

      await tester.tap(fullScreenButton);
      await tester.pumpAndSettle();

      expect(fullScreenQueue, findsOneWidget);
      expect(changedProblem, findsOneWidget);

      await tester.scrollUntilVisible(
        addedProblem,
        180,
        scrollable: find.byType(Scrollable).first,
      );

      expect(addedProblem, findsOneWidget);

      await tester.scrollUntilVisible(
        changedProblem,
        -180,
        scrollable: find.byType(Scrollable).first,
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

      expect(
        find.byKey(const ValueKey<String>('full-registry-header')),
        findsOneWidget,
      );

      expect(store.state?.cleanBaselineRevision, snapshot.sourceRevision);

      expect(loader.loadCount, 2);
    },
  );

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
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: store,
      ),
    );

    await tester.pumpAndSettle();

    final RegistryNode child = snapshot.roots.single.children.single;

    final Finder childRow = find.byKey(ValueKey<String>(child.id.value));

    expect(childRow, findsOneWidget);

    await Scrollable.ensureVisible(tester.element(childRow), alignment: 0.5);
    await tester.pumpAndSettle();

    await tester.tap(childRow);
    await tester.pumpAndSettle();

    final Finder selectedRegistryBlock = find.byKey(
      const ValueKey<String>('registry-selected-block'),
    );

    expect(selectedRegistryBlock, findsOneWidget);

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
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Загрузка Registry'), findsOneWidget);

      firstLoad.complete(snapshot);
      await tester.pumpAndSettle();

      expect(find.text('Проект: project'), findsOneWidget);
      expect(find.text('Узлов: 2'), findsOneWidget);
      expect(find.text('Registry'), findsOneWidget);
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
          registrySnapshotRevisionLoader: loader,
          registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Наверх'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -1600));
      await tester.pumpAndSettle();

      final ScrollableState scrolledState = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
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
        find.byType(Scrollable).first,
      );

      expect(restoredState.position.pixels, closeTo(0, 0.1));
      expect(find.byTooltip('Наверх'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('project.registry.node.000001')),
        findsOneWidget,
      );
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
        registrySnapshotRevisionLoader: loader,
        registryRevisionStateStore: _MemoryRegistryRevisionStateStore(),
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
}

final class _QueuedRegistrySnapshotLoader
    implements RegistrySnapshotLoader, RegistrySnapshotRevisionLoader {
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
