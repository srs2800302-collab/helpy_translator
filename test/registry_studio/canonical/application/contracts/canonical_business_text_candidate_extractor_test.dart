import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_candidate_extractor.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  test('CanonicalBusinessTextCandidateExtractor exposes one '
      'project-facing extraction capability', () {
    final RegistrySnapshot snapshot = _snapshot();

    final CanonicalBusinessTextCandidateExtractor extractor =
        _EmptyCandidateExtractor();

    final CanonicalBusinessTextCandidateIndex index = extractor
        .extractCandidates(snapshot);

    expect(index.projectId, 'project');
    expect(index.sourceRevision, 'revision-1');
    expect(index.candidates, isEmpty);
  });
}

RegistrySnapshot _snapshot() {
  final RegistryPath path = RegistryPath(const <String>['Registry']);

  return RegistrySnapshot(
    projectId: 'project',
    projectAdapterId: 'project.adapter.v1',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'revision-1',
    sourceSnapshotFingerprint: 'git-blob:source',
    sourceContent: '# Registry',
    roots: <RegistryNode>[
      RegistryNode(
        id: RegistryNodeId('node-1'),
        kindId: 'project.heading.1',
        path: path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'git-blob:source',
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

final class _EmptyCandidateExtractor
    implements CanonicalBusinessTextCandidateExtractor {
  @override
  CanonicalBusinessTextCandidateIndex extractCandidates(
    RegistrySnapshot snapshot,
  ) {
    return CanonicalBusinessTextCandidateIndex(
      projectId: snapshot.projectId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: snapshot.sourceRevision,
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      candidates: const <Never>[],
    );
  }
}
