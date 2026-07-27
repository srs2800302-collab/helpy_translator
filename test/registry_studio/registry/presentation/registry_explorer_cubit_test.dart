import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import 'package:helpy_translator/registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import 'package:helpy_translator/registry_studio/maintenance/history/domain/entities/registry_analysis_history_entry.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_cache.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';
import 'package:helpy_translator/registry_studio/registry/presentation/registry_explorer_cubit.dart';

void main() {
  test(
    'restore reads only the local cache and performs no network call',
    () async {
      final RegistrySnapshot snapshot = _snapshot('revision-1');
      final _MemorySnapshotCache cache = _MemorySnapshotCache(
        <String, RegistrySnapshot>{snapshot.sourceRevision: snapshot},
      );
      final _FakeSnapshotLoader loader = _FakeSnapshotLoader(snapshot);
      final RegistryExplorerCubit cubit = _cubit(
        loader: loader,
        cache: cache,
        revisionStateStore: _MemoryRevisionStateStore(_stateFor(snapshot)),
      );
      addTearDown(cubit.close);

      await cubit.restore();

      expect(cubit.state, isA<RegistryExplorerLoaded>());
      expect((cubit.state as RegistryExplorerLoaded).snapshot, snapshot);
      expect(loader.loadCount, 0);
      expect(loader.refreshCount, 0);
      expect(loader.revisionCount, 0);
    },
  );

  test('restore without a local snapshot waits for manual refresh', () async {
    final RegistrySnapshot snapshot = _snapshot('revision-1');
    final _FakeSnapshotLoader loader = _FakeSnapshotLoader(snapshot);
    final RegistryExplorerCubit cubit = _cubit(
      loader: loader,
      cache: _MemorySnapshotCache(),
      revisionStateStore: _MemoryRevisionStateStore(),
    );
    addTearDown(cubit.close);

    await cubit.restore();

    expect(cubit.state, isA<RegistryExplorerFailure>());
    expect(
      (cubit.state as RegistryExplorerFailure).message,
      contains('вручную'),
    );
    expect(loader.loadCount, 0);
    expect(loader.refreshCount, 0);
    expect(loader.revisionCount, 0);
  });

  test('first manual refresh saves a reusable local snapshot', () async {
    final RegistrySnapshot snapshot = _snapshot('revision-1');
    final _FakeSnapshotLoader loader = _FakeSnapshotLoader(snapshot);
    final _MemorySnapshotCache cache = _MemorySnapshotCache();
    final _MemoryRevisionStateStore revisionStore = _MemoryRevisionStateStore();
    final RegistryExplorerCubit cubit = _cubit(
      loader: loader,
      cache: cache,
      revisionStateStore: revisionStore,
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.retry();

    expect(loader.loadCount, 1);
    expect(cubit.state, isA<RegistryExplorerLoaded>());
    expect(cache.snapshots[snapshot.sourceRevision], snapshot);
    expect(revisionStore.state?.currentRevision, snapshot.sourceRevision);
  });

  test('failed manual refresh keeps the visible cached Registry', () async {
    final RegistrySnapshot snapshot = _snapshot('revision-1');
    final _MemorySnapshotCache cache = _MemorySnapshotCache(
      <String, RegistrySnapshot>{snapshot.sourceRevision: snapshot},
    );
    final _FakeSnapshotLoader loader = _FakeSnapshotLoader(
      snapshot,
      refreshError: const SocketException('connection closed'),
    );
    final _MemoryRevisionStateStore revisionStore = _MemoryRevisionStateStore(
      _stateFor(snapshot),
    );
    final RegistryExplorerCubit cubit = _cubit(
      loader: loader,
      cache: cache,
      revisionStateStore: revisionStore,
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.refresh();

    expect(loader.refreshCount, 1);
    expect(cubit.state, isA<RegistryExplorerLoaded>());
    final RegistryExplorerLoaded loaded = cubit.state as RegistryExplorerLoaded;
    expect(loaded.snapshot, snapshot);
    expect(loaded.refreshWarning, isNotNull);
    expect(loaded.refreshWarning, isNot(contains('https://')));
    expect(loaded.isRefreshing, isFalse);
    expect(revisionStore.state?.currentRevision, snapshot.sourceRevision);
  });
}

RegistryExplorerCubit _cubit({
  required _FakeSnapshotLoader loader,
  required RegistrySnapshotCache cache,
  required RegistryRevisionStateStore revisionStateStore,
}) {
  return RegistryExplorerCubit(
    snapshotLoader: loader,
    snapshotRefreshLoader: loader,
    snapshotRevisionLoader: loader,
    snapshotCache: cache,
    revisionStateStore: revisionStateStore,
    analysisHistoryStore: _MemoryAnalysisHistoryStore(),
    snapshotComparator: const RegistrySnapshotComparator(),
  );
}

RegistryRevisionState _stateFor(RegistrySnapshot snapshot) {
  return RegistryRevisionState(
    projectId: snapshot.projectId,
    projectAdapterId: snapshot.projectAdapterId,
    sourceDocumentPath: snapshot.sourceDocumentPath,
    currentRevision: snapshot.sourceRevision,
  );
}

RegistrySnapshot _snapshot(String revision) {
  const String documentPath = 'docs/registry.md';
  final String fingerprint = 'git-blob:$revision';
  final RegistryPath path = RegistryPath(<String>['Root']);

  final RegistryNode root = RegistryNode(
    id: RegistryNodeId('node.root'),
    kindId: 'heading.1',
    path: path,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: documentPath,
        sourceSnapshotFingerprint: fingerprint,
        headingPath: path.segments,
        startLine: 1,
        endLine: 1,
      ),
    ],
    content: 'Root content',
    businessScopeOwnerId: null,
    children: const <RegistryNode>[],
  );

  return RegistrySnapshot(
    projectId: 'project',
    projectAdapterId: 'adapter',
    sourceDocumentPath: documentPath,
    sourceRevision: revision,
    sourceSnapshotFingerprint: fingerprint,
    sourceContent: '# Root\n',
    roots: <RegistryNode>[root],
  );
}

final class _FakeSnapshotLoader
    implements
        RegistrySnapshotLoader,
        RegistrySnapshotRefreshLoader,
        RegistrySnapshotRevisionLoader {
  _FakeSnapshotLoader(this.snapshot, {this.refreshError});

  final RegistrySnapshot snapshot;
  final Object? refreshError;
  int loadCount = 0;
  int refreshCount = 0;
  int revisionCount = 0;

  @override
  Future<RegistrySnapshot> loadSnapshot() async {
    loadCount += 1;
    return snapshot;
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAfterRevision(
    String previousRevision,
  ) async {
    refreshCount += 1;
    final Object? error = refreshError;

    if (error != null) {
      throw error;
    }

    return snapshot;
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAtRevision(String sourceRevision) async {
    revisionCount += 1;
    return snapshot;
  }
}

final class _MemorySnapshotCache implements RegistrySnapshotCache {
  _MemorySnapshotCache([Map<String, RegistrySnapshot>? snapshots])
    : snapshots = <String, RegistrySnapshot>{...?snapshots};

  final Map<String, RegistrySnapshot> snapshots;

  @override
  Future<RegistrySnapshot?> loadSnapshot(String sourceRevision) async {
    return snapshots[sourceRevision];
  }

  @override
  Future<void> saveSnapshot(RegistrySnapshot snapshot) async {
    snapshots[snapshot.sourceRevision] = snapshot;
  }
}

final class _MemoryRevisionStateStore implements RegistryRevisionStateStore {
  _MemoryRevisionStateStore([this.state]);

  RegistryRevisionState? state;

  @override
  Future<RegistryRevisionState?> loadRevisionState() async => state;

  @override
  Future<void> saveRevisionState(RegistryRevisionState state) async {
    this.state = state;
  }
}

final class _MemoryAnalysisHistoryStore
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
