import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('RegistrySnapshotLoader', () {
    test(
      'allows a project-specific implementation to provide an exact snapshot',
      () async {
        final RegistrySnapshot expectedSnapshot = _createSnapshot();

        final RegistrySnapshotLoader adapter = _SampleRegistrySnapshotLoader(
          snapshot: expectedSnapshot,
        );

        final RegistrySnapshot loadedSnapshot = await adapter.loadSnapshot();

        expect(loadedSnapshot, same(expectedSnapshot));
        expect(loadedSnapshot.projectId, 'sample.project');
        expect(loadedSnapshot.projectAdapterId, 'sample.adapter');
        expect(loadedSnapshot.sourceRevision, 'revision-1');
      },
    );
  });
}

final class _SampleRegistrySnapshotLoader implements RegistrySnapshotLoader {
  const _SampleRegistrySnapshotLoader({required this.snapshot});

  final RegistrySnapshot snapshot;

  @override
  Future<RegistrySnapshot> loadSnapshot() async {
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
