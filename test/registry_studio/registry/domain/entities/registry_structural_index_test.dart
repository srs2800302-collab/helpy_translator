import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_structural_index.dart';

void main() {
  group('RegistryStructuralIndex', () {
    test('indexes the complete recursive tree in deterministic order', () {
      const String sourceDocumentPath = 'registry/source.document';
      const String sourceFingerprint = 'sha256:sample-source';

      final RegistryNode grandchild = RegistryNode(
        id: RegistryEntityId('sample.registry.child.rule'),
        kindId: 'project.rule',
        path: RegistryPath(const <String>[
          'registry',
          'domain',
          'child',
          'rule',
        ]),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['Registry', 'Domain', 'Child', 'Rule'],
            startLine: 4,
            endLine: 4,
          ),
        ],
        content: 'Rule content',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistryNode child = RegistryNode(
        id: RegistryEntityId('sample.registry.child'),
        kindId: 'project.block',
        path: RegistryPath(const <String>['registry', 'domain', 'child']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['Registry', 'Domain', 'Child'],
            startLine: 3,
            endLine: 4,
          ),
        ],
        content: 'Child content',
        businessScopeOwnerId: null,
        children: <RegistryNode>[grandchild],
      );

      final RegistryNode firstRoot = RegistryNode(
        id: RegistryEntityId('sample.registry.root'),
        kindId: 'project.registry_root',
        path: RegistryPath(const <String>['registry']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['Registry'],
            startLine: 1,
            endLine: 4,
          ),
        ],
        content: 'Registry content',
        businessScopeOwnerId: null,
        children: <RegistryNode>[child],
      );

      final RegistryNode secondRoot = RegistryNode(
        id: RegistryEntityId('sample.reference.root'),
        kindId: 'project.reference_root',
        path: RegistryPath(const <String>['reference']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['Reference'],
            startLine: 5,
            endLine: 5,
          ),
        ],
        content: 'Reference content',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistrySnapshot snapshot = RegistrySnapshot(
        projectId: 'sample.project',
        projectAdapterId: 'sample.adapter',
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: sourceFingerprint,
        sourceContent:
            'Registry content\n'
            'Domain content\n'
            'Child content\n'
            'Rule content\n'
            'Reference content\n',
        roots: <RegistryNode>[firstRoot, secondRoot],
      );

      final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

      expect(index.nodes, <RegistryNode>[
        firstRoot,
        child,
        grandchild,
        secondRoot,
      ]);
      expect(index.snapshot, snapshot);
      expect(index.nodesById[RegistryEntityId('sample.registry.child')], child);
      expect(
        index.nodesByPath[RegistryPath(const <String>[
          'registry',
          'domain',
          'child',
          'rule',
        ])],
        grandchild,
      );
      expect(index.parentIdByNodeId[child.id], firstRoot.id);
      expect(index.parentIdByNodeId[grandchild.id], child.id);
      expect(index.parentIdByNodeId[firstRoot.id], isNull);
      expect(index.siblingPositionByNodeId[firstRoot.id], 0);
      expect(index.siblingPositionByNodeId[secondRoot.id], 1);
      expect(index.siblingPositionByNodeId[child.id], 0);

      expect(() => index.nodes.add(firstRoot), throwsUnsupportedError);
      expect(() => index.nodesById.clear(), throwsUnsupportedError);
      expect(() => index.nodesByPath.clear(), throwsUnsupportedError);
      expect(() => index.parentIdByNodeId.clear(), throwsUnsupportedError);
      expect(
        () => index.siblingPositionByNodeId.clear(),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate identities across the complete tree', () {
      const String sourceDocumentPath = 'registry/source.document';
      const String sourceFingerprint = 'sha256:sample-source';

      final RegistryEntityId duplicateId = RegistryEntityId(
        'sample.registry.duplicate',
      );

      final RegistryNode firstRoot = RegistryNode(
        id: duplicateId,
        kindId: 'project.root',
        path: RegistryPath(const <String>['first']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['First'],
            startLine: 1,
            endLine: 1,
          ),
        ],
        content: 'First',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistryNode secondRoot = RegistryNode(
        id: duplicateId,
        kindId: 'project.root',
        path: RegistryPath(const <String>['second']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['Second'],
            startLine: 2,
            endLine: 2,
          ),
        ],
        content: 'Second',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistrySnapshot snapshot = RegistrySnapshot(
        projectId: 'sample.project',
        projectAdapterId: 'sample.adapter',
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: sourceFingerprint,
        sourceContent: 'First\nSecond\n',
        roots: <RegistryNode>[firstRoot, secondRoot],
      );

      expect(() => RegistryStructuralIndex(snapshot), throwsArgumentError);
    });

    test('rejects duplicate paths across the complete tree', () {
      const String sourceDocumentPath = 'registry/source.document';
      const String sourceFingerprint = 'sha256:sample-source';

      final RegistryPath duplicatePath = RegistryPath(const <String>[
        'registry',
      ]);

      final RegistryNode firstRoot = RegistryNode(
        id: RegistryEntityId('sample.registry.first'),
        kindId: 'project.root',
        path: duplicatePath,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['First'],
            startLine: 1,
            endLine: 1,
          ),
        ],
        content: 'First',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistryNode secondRoot = RegistryNode(
        id: RegistryEntityId('sample.registry.second'),
        kindId: 'project.root',
        path: duplicatePath,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceFingerprint,
            headingPath: const <String>['Second'],
            startLine: 2,
            endLine: 2,
          ),
        ],
        content: 'Second',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistrySnapshot snapshot = RegistrySnapshot(
        projectId: 'sample.project',
        projectAdapterId: 'sample.adapter',
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: sourceFingerprint,
        sourceContent: 'First\nSecond\n',
        roots: <RegistryNode>[firstRoot, secondRoot],
      );

      expect(() => RegistryStructuralIndex(snapshot), throwsArgumentError);
    });
  });
}
