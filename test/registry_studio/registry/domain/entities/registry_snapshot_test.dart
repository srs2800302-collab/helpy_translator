import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';

void main() {
  group('RegistrySnapshot', () {
    test('preserves an exact project-independent source snapshot', () {
      const String sourceDocumentPath = 'registry/source.document';
      const String sourceFingerprint = 'sha256:sample-source';

      final RegistryNode child = RegistryNode(
        id: RegistryNodeId('sample.registry.child'),
        kindId: 'project.rule',
        path: RegistryPath(const <String>['registry', 'child']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['Registry', 'Child'],
            startLine: 2,
            endLine: 3,
          ),
        ],
        content: 'Child content',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistryNode root = RegistryNode(
        id: RegistryNodeId('sample.registry.root'),
        kindId: 'project.registry_root',
        path: RegistryPath(const <String>['registry']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['Registry'],
            startLine: 1,
            endLine: 3,
          ),
        ],
        content: 'Root content',
        businessScopeOwnerId: null,
        children: <RegistryNode>[child],
      );

      final List<RegistryNode> roots = <RegistryNode>[root];

      final RegistrySnapshot snapshot = RegistrySnapshot(
        projectId: ' sample.project ',
        projectAdapterId: ' sample.adapter ',
        sourceDocumentPath: ' $sourceDocumentPath ',
        sourceRevision: ' release/registry-42 ',
        sourceSnapshotFingerprint: ' $sourceFingerprint ',
        sourceContent: '# Registry\n## Child\nChild content\n',
        roots: roots,
      );

      roots.clear();

      expect(snapshot.projectId, 'sample.project');
      expect(snapshot.projectAdapterId, 'sample.adapter');
      expect(snapshot.sourceDocumentPath, sourceDocumentPath);
      expect(snapshot.sourceRevision, 'release/registry-42');
      expect(snapshot.sourceSnapshotFingerprint, sourceFingerprint);
      expect(snapshot.sourceContent, '# Registry\n## Child\nChild content\n');
      expect(snapshot.roots, <RegistryNode>[root]);
      expect(snapshot.roots.single.children, <RegistryNode>[child]);
      expect(() => snapshot.roots.add(root), throwsUnsupportedError);
    });

    test('rejects incomplete snapshot provenance and empty structure', () {
      const String sourceDocumentPath = 'registry/source.document';
      const String sourceFingerprint = 'sha256:sample-source';

      final RegistryNode root = RegistryNode(
        id: RegistryNodeId('sample.registry.root'),
        kindId: 'project.registry_root',
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
        content: 'Root content',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      expect(
        () => RegistrySnapshot(
          projectId: ' ',
          projectAdapterId: 'sample.adapter',
          sourceDocumentPath: sourceDocumentPath,
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: sourceFingerprint,
          sourceContent: '# Registry',
          roots: <RegistryNode>[root],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistrySnapshot(
          projectId: 'sample.project',
          projectAdapterId: ' ',
          sourceDocumentPath: sourceDocumentPath,
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: sourceFingerprint,
          sourceContent: '# Registry',
          roots: <RegistryNode>[root],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistrySnapshot(
          projectId: 'sample.project',
          projectAdapterId: 'sample.adapter',
          sourceDocumentPath: sourceDocumentPath,
          sourceRevision: ' ',
          sourceSnapshotFingerprint: sourceFingerprint,
          sourceContent: '# Registry',
          roots: <RegistryNode>[root],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistrySnapshot(
          projectId: 'sample.project',
          projectAdapterId: 'sample.adapter',
          sourceDocumentPath: sourceDocumentPath,
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: sourceFingerprint,
          sourceContent: ' ',
          roots: <RegistryNode>[root],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistrySnapshot(
          projectId: 'sample.project',
          projectAdapterId: 'sample.adapter',
          sourceDocumentPath: sourceDocumentPath,
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: sourceFingerprint,
          sourceContent: '# Registry',
          roots: const <RegistryNode>[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects node evidence from another exact source snapshot', () {
      final RegistryNode root = RegistryNode(
        id: RegistryNodeId('sample.registry.root'),
        kindId: 'project.registry_root',
        path: RegistryPath(const <String>['registry']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'another/source.document',
            sourceSnapshotFingerprint: 'sha256:another-source',
            headingPath: const <String>['Registry'],
            startLine: 1,
            endLine: 1,
          ),
        ],
        content: 'Root content',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      expect(
        () => RegistrySnapshot(
          projectId: 'sample.project',
          projectAdapterId: 'sample.adapter',
          sourceDocumentPath: 'registry/source.document',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'sha256:sample-source',
          sourceContent: '# Registry',
          roots: <RegistryNode>[root],
        ),
        throwsArgumentError,
      );
    });
  });
}
