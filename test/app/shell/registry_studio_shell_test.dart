import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/bootstrap/registry_studio_application.dart';
import 'package:helpy_translator/app/shell/registry_studio_shell.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
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
