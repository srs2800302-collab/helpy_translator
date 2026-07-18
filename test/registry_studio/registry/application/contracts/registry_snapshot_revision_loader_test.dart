import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('RegistrySnapshotRevisionLoader', () {
    test(
      'allows a project-specific implementation to load an exact revision',
      () async {
        final RegistrySnapshot expectedSnapshot = _createSnapshot();

        final _SampleRegistrySnapshotRevisionLoader adapter =
            _SampleRegistrySnapshotRevisionLoader(snapshot: expectedSnapshot);

        final RegistrySnapshot loadedSnapshot = await adapter
            .loadSnapshotAtRevision('revision-1');

        expect(adapter.requestedRevision, 'revision-1');
        expect(loadedSnapshot, same(expectedSnapshot));
        expect(loadedSnapshot.projectId, 'sample.project');
        expect(loadedSnapshot.projectAdapterId, 'sample.adapter');
        expect(loadedSnapshot.sourceRevision, 'revision-1');
      },
    );
  });
}

final class _SampleRegistrySnapshotRevisionLoader
    implements RegistrySnapshotRevisionLoader {
  _SampleRegistrySnapshotRevisionLoader({required this.snapshot});

  final RegistrySnapshot snapshot;

  String? requestedRevision;

  @override
  Future<RegistrySnapshot> loadSnapshotAtRevision(String sourceRevision) async {
    requestedRevision = sourceRevision;

    return snapshot;
  }
}

RegistrySnapshot _createSnapshot() {
  const String sourceDocumentPath = 'sample/registry.source';
  const String sourceFingerprint = 'sha256:sample-source';

  final RegistryNode root = RegistryNode(
    id: RegistryNodeId('sample.registry.root'),
    kindId: 'sample.root',
    path: RegistryPath(const <String>['registry']),
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: sourceDocumentPath,
        sourceSnapshotFingerprint: sourceFingerprint,
        headingPath: const <String>['Registry'],
        startLine: 1,
        endLine: 1,
      ),
    ],
    content: 'Registry content',
    businessScopeOwnerId: null,
    children: const <RegistryNode>[],
  );

  return RegistrySnapshot(
    projectId: 'sample.project',
    projectAdapterId: 'sample.adapter',
    sourceDocumentPath: sourceDocumentPath,
    sourceRevision: 'revision-1',
    sourceSnapshotFingerprint: sourceFingerprint,
    sourceContent: 'Registry content\n',
    roots: <RegistryNode>[root],
  );
}
