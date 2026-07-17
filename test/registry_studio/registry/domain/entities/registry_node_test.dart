import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';

void main() {
  group('RegistryNode', () {
    test('preserves project-independent recursive structure', () {
      final RegistryEntityId rootId = RegistryEntityId('sample.registry.root');
      final List<SourceEvidence> leafEvidence = <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: 'registry.source',
          sourceSnapshotFingerprint: 'sha256:sample',
          headingPath: const <String>['Root', 'Domain', 'Rule'],
          startLine: 5,
          endLine: 7,
        ),
      ];
      final RegistryNode leaf = RegistryNode(
        id: RegistryEntityId('sample.registry.rule'),
        kindId: 'project.rule',
        path: RegistryPath(const <String>['root', 'domain', 'rule']),
        sourceEvidence: leafEvidence,
        content: 'Rule content',
        businessScopeOwnerId: rootId,
        children: const <RegistryNode>[],
      );
      final List<RegistryNode> children = <RegistryNode>[leaf];
      final RegistryNode root = RegistryNode(
        id: rootId,
        kindId: 'project.root',
        path: RegistryPath(const <String>['root']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.source',
            sourceSnapshotFingerprint: 'sha256:sample',
            headingPath: const <String>['Root'],
            startLine: 1,
            endLine: 7,
          ),
        ],
        content: 'Root content',
        businessScopeOwnerId: rootId,
        children: children,
      );

      leafEvidence.clear();
      children.clear();

      expect(root.kindId, 'project.root');
      expect(root.children, <RegistryNode>[leaf]);
      expect(root.children.single.businessScopeOwnerId, rootId);
      expect(root.children.single.sourceEvidence, hasLength(1));
      expect(() => root.children.add(leaf), throwsUnsupportedError);
      expect(
        () => root.children.single.sourceEvidence.clear(),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid kind, missing evidence and unrelated child path', () {
      final RegistryEntityId rootId = RegistryEntityId('sample.registry.root');
      final SourceEvidence evidence = SourceEvidence(
        sourceDocumentPath: 'registry.source',
        sourceSnapshotFingerprint: 'sha256:sample',
        headingPath: const <String>['Root'],
        startLine: 1,
        endLine: 1,
      );

      expect(
        () => RegistryNode(
          id: rootId,
          kindId: ' ',
          path: RegistryPath(const <String>['root']),
          sourceEvidence: <SourceEvidence>[evidence],
          content: '',
          businessScopeOwnerId: null,
          children: const <RegistryNode>[],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistryNode(
          id: rootId,
          kindId: 'project.root',
          path: RegistryPath(const <String>['root']),
          sourceEvidence: const <SourceEvidence>[],
          content: '',
          businessScopeOwnerId: null,
          children: const <RegistryNode>[],
        ),
        throwsArgumentError,
      );

      final RegistryNode unrelatedChild = RegistryNode(
        id: RegistryEntityId('sample.registry.other'),
        kindId: 'project.rule',
        path: RegistryPath(const <String>['other', 'rule']),
        sourceEvidence: <SourceEvidence>[evidence],
        content: '',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      expect(
        () => RegistryNode(
          id: rootId,
          kindId: 'project.root',
          path: RegistryPath(const <String>['root']),
          sourceEvidence: <SourceEvidence>[evidence],
          content: '',
          businessScopeOwnerId: null,
          children: <RegistryNode>[unrelatedChild],
        ),
        throwsArgumentError,
      );
    });
  });
}
