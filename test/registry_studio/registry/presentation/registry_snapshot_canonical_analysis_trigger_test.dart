import 'package:flutter_test/flutter_test.dart';
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
  test('notifies the accepted snapshot after restore '
      'and every successful refresh', () async {
    final RegistrySnapshot snapshot = _snapshot();

    final _SnapshotLoader loader = _SnapshotLoader(<RegistrySnapshot>[
      snapshot,
      snapshot,
    ]);

    final List<RegistrySnapshot> accepted = <RegistrySnapshot>[];

    final RegistryExplorerCubit cubit = RegistryExplorerCubit(
      snapshotLoader: loader,
      snapshotRefreshLoader: loader,
      snapshotRevisionLoader: loader,
      revisionStateStore: _RevisionStateStore(),
      analysisHistoryStore: _AnalysisHistoryStore(),
      snapshotComparator: const RegistrySnapshotComparator(),
      onSnapshotAccepted: accepted.add,
    );

    await cubit.restore();

    expect(accepted, <RegistrySnapshot>[snapshot]);

    await cubit.updateSearchQuery('Registry');

    expect(accepted, <RegistrySnapshot>[snapshot]);

    await cubit.refresh();

    expect(accepted, <RegistrySnapshot>[snapshot, snapshot]);

    expect(loader.refreshBaseRevisions, <String>[snapshot.sourceRevision]);

    await cubit.close();
  });
}

final class _SnapshotLoader
    implements
        RegistrySnapshotLoader,
        RegistrySnapshotRefreshLoader,
        RegistrySnapshotRevisionLoader {
  _SnapshotLoader(this.snapshots);

  final List<RegistrySnapshot> snapshots;

  int _nextIndex = 0;

  final List<String> refreshBaseRevisions = <String>[];

  @override
  Future<RegistrySnapshot> loadSnapshot() async {
    return snapshots[_nextIndex++];
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAfterRevision(
    String previousRevision,
  ) async {
    refreshBaseRevisions.add(previousRevision);
    return snapshots[_nextIndex++];
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAtRevision(String sourceRevision) async {
    return snapshots.firstWhere(
      (RegistrySnapshot snapshot) => snapshot.sourceRevision == sourceRevision,
    );
  }
}

final class _RevisionStateStore implements RegistryRevisionStateStore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #loadRevisionState) {
      return Future<RegistryRevisionState?>.value();
    }

    if (invocation.memberName == #saveRevisionState) {
      return Future<void>.value();
    }

    return super.noSuchMethod(invocation);
  }
}

final class _AnalysisHistoryStore implements RegistryAnalysisHistoryStore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #loadHistory) {
      return Future<List<RegistryAnalysisHistoryEntry>>.value(
        const <RegistryAnalysisHistoryEntry>[],
      );
    }

    if (invocation.memberName == #appendHistoryEntry) {
      return Future<void>.value();
    }

    return super.noSuchMethod(invocation);
  }
}

RegistrySnapshot _snapshot() {
  const String fingerprint = 'git-blob:registry';

  final RegistryPath path = RegistryPath(const <String>['Registry']);

  return RegistrySnapshot(
    projectId: 'helpy',
    projectAdapterId: 'helpy.registry.adapter.v1',
    sourceDocumentPath: 'registry.md',
    sourceRevision: '1111111111111111111111111111111111111111',
    sourceSnapshotFingerprint: fingerprint,
    sourceContent: '# Registry',
    roots: <RegistryNode>[
      RegistryNode(
        id: RegistryNodeId('node-1'),
        kindId: 'helpy.registry.heading.1',
        path: path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: path.segments,
            startLine: 1,
            endLine: 1,
          ),
        ],
        content: '',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      ),
    ],
  );
}
