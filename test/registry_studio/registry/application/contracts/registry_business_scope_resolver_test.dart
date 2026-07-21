import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_business_scope_resolver.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  test(
    'RegistryBusinessScopeResolver exposes one project-facing capability',
    () {
      final RegistrySnapshot snapshot = _snapshot();

      final RegistryBusinessScopeResolver resolver =
          _PassThroughRegistryBusinessScopeResolver();

      expect(resolver.resolveBusinessScope(snapshot), same(snapshot));
    },
  );
}

RegistrySnapshot _snapshot() {
  const String sourceDocumentPath = 'registry.md';

  const String sourceSnapshotFingerprint =
      'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  final RegistryPath path = RegistryPath(const <String>['Registry']);

  return RegistrySnapshot(
    projectId: 'project',
    projectAdapterId: 'project.registry.adapter.v1',
    sourceDocumentPath: sourceDocumentPath,
    sourceRevision: 'revision-1',
    sourceSnapshotFingerprint: sourceSnapshotFingerprint,
    sourceContent: '# Registry',
    roots: <RegistryNode>[
      RegistryNode(
        id: RegistryNodeId('project.registry.node.000001'),
        kindId: 'project.registry.markdown.heading.1',
        path: path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocumentPath,
            sourceSnapshotFingerprint: sourceSnapshotFingerprint,
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

final class _PassThroughRegistryBusinessScopeResolver
    implements RegistryBusinessScopeResolver {
  @override
  RegistrySnapshot resolveBusinessScope(RegistrySnapshot snapshot) {
    return snapshot;
  }
}
