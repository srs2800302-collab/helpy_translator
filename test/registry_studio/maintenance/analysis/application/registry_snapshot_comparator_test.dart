import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import 'package:helpy_translator/registry_studio/maintenance/analysis/domain/entities/registry_node_change.dart';
import 'package:helpy_translator/registry_studio/maintenance/analysis/domain/entities/registry_structural_problem.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_structural_index.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  test('detects added removed and changed nodes by stable identity', () {
    const String documentPath = 'registry.md';
    const String previousFingerprint =
        'git-blob:1111111111111111111111111111111111111111';
    const String currentFingerprint =
        'git-blob:2222222222222222222222222222222222222222';

    final RegistryNode previousChangedNode = RegistryNode(
      id: RegistryNodeId('project.registry.node.changed'),
      kindId: 'project.registry.heading.2',
      path: RegistryPath(const <String>['Registry', 'Old Domain']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: previousFingerprint,
          headingPath: const <String>['Registry', 'Old Domain'],
          startLine: 3,
          endLine: 4,
        ),
      ],
      content: 'Old content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode previousRemovedNode = RegistryNode(
      id: RegistryNodeId('project.registry.node.removed'),
      kindId: 'project.registry.heading.2',
      path: RegistryPath(const <String>['Registry', 'Removed Domain']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: previousFingerprint,
          headingPath: const <String>['Registry', 'Removed Domain'],
          startLine: 5,
          endLine: 6,
        ),
      ],
      content: 'Removed content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode previousRoot = RegistryNode(
      id: RegistryNodeId('project.registry.node.root'),
      kindId: 'project.registry.heading.1',
      path: RegistryPath(const <String>['Registry']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: previousFingerprint,
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 6,
        ),
      ],
      content: 'Root content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[previousChangedNode, previousRemovedNode],
    );

    final RegistrySnapshot previousSnapshot = RegistrySnapshot(
      projectId: 'project',
      projectAdapterId: 'project.registry.adapter.v1',
      sourceDocumentPath: documentPath,
      sourceRevision: 'revision-a',
      sourceSnapshotFingerprint: previousFingerprint,
      sourceContent: 'previous Registry content',
      roots: <RegistryNode>[previousRoot],
    );

    final RegistryNode currentChangedNode = RegistryNode(
      id: previousChangedNode.id,
      kindId: 'project.registry.heading.3',
      path: RegistryPath(const <String>['Registry', 'New Domain']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: currentFingerprint,
          headingPath: const <String>['Registry', 'New Domain'],
          startLine: 7,
          endLine: 8,
        ),
      ],
      content: 'New content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode currentAddedNode = RegistryNode(
      id: RegistryNodeId('project.registry.node.added'),
      kindId: 'project.registry.heading.2',
      path: RegistryPath(const <String>['Registry', 'Added Domain']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: currentFingerprint,
          headingPath: const <String>['Registry', 'Added Domain'],
          startLine: 9,
          endLine: 10,
        ),
      ],
      content: 'Added content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode currentRoot = RegistryNode(
      id: previousRoot.id,
      kindId: previousRoot.kindId,
      path: previousRoot.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: currentFingerprint,
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 10,
        ),
      ],
      content: previousRoot.content,
      businessScopeOwnerId: null,
      children: <RegistryNode>[currentChangedNode, currentAddedNode],
    );

    final RegistrySnapshot currentSnapshot = RegistrySnapshot(
      projectId: previousSnapshot.projectId,
      projectAdapterId: previousSnapshot.projectAdapterId,
      sourceDocumentPath: documentPath,
      sourceRevision: 'revision-b',
      sourceSnapshotFingerprint: currentFingerprint,
      sourceContent: 'current Registry content',
      roots: <RegistryNode>[currentRoot],
    );

    final comparison = const RegistrySnapshotComparator().compare(
      previousIndex: RegistryStructuralIndex(previousSnapshot),
      currentIndex: RegistryStructuralIndex(currentSnapshot),
    );

    expect(comparison.previousRevision, 'revision-a');
    expect(comparison.currentRevision, 'revision-b');
    expect(comparison.changes, hasLength(3));
    expect(comparison.addedCount, 1);
    expect(comparison.removedCount, 1);
    expect(comparison.changedCount, 1);

    final RegistryNodeChange changed = comparison.changes[0];

    expect(changed.kind, RegistryNodeChangeKind.changed);
    expect(changed.previousNode, same(previousChangedNode));
    expect(changed.currentNode, same(currentChangedNode));
    expect(changed.aspects, <RegistryNodeChangeAspect>[
      RegistryNodeChangeAspect.kind,
      RegistryNodeChangeAspect.path,
      RegistryNodeChangeAspect.content,
    ]);

    expect(comparison.changes[1].kind, RegistryNodeChangeKind.added);
    expect(comparison.changes[1].currentNode, same(currentAddedNode));

    expect(comparison.changes[2].kind, RegistryNodeChangeKind.removed);
    expect(comparison.changes[2].previousNode, same(previousRemovedNode));

    expect(comparison.problems, hasLength(3));

    final RegistryStructuralProblem changedProblem = comparison.problems[0];

    expect(changedProblem.status, RegistryStructuralProblemStatus.affected);
    expect(changedProblem.reason, 'Изменены: тип, путь, содержимое.');
    expect(changedProblem.change, same(changed));
    expect(changedProblem.path, currentChangedNode.path);
    expect(changedProblem.baselineRevision, previousSnapshot.sourceRevision);
    expect(changedProblem.currentRevision, currentSnapshot.sourceRevision);
    expect(changedProblem.baselineEvidence, previousChangedNode.sourceEvidence);
    expect(changedProblem.currentEvidence, currentChangedNode.sourceEvidence);

    expect(comparison.problems[1].reason, 'Добавлен новый Registry-узел.');
    expect(comparison.problems[1].exactNode, same(currentAddedNode));

    expect(
      comparison.problems[2].reason,
      'Registry-узел удалён из текущей revision.',
    );
    expect(comparison.problems[2].exactNode, same(previousRemovedNode));

    expect(
      comparison.changes.any(
        (RegistryNodeChange change) =>
            change.currentNode?.id == currentRoot.id ||
            change.previousNode?.id == previousRoot.id,
      ),
      isFalse,
    );
  });

  test('rejects snapshots from different Registry coordinates', () {
    const String fingerprint =
        'git-blob:3333333333333333333333333333333333333333';

    final RegistryNode root = RegistryNode(
      id: RegistryNodeId('project.registry.node.root'),
      kindId: 'project.registry.heading.1',
      path: RegistryPath(const <String>['Registry']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 1,
        ),
      ],
      content: 'Root content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistrySnapshot previousSnapshot = RegistrySnapshot(
      projectId: 'project-a',
      projectAdapterId: 'project.registry.adapter.v1',
      sourceDocumentPath: 'registry.md',
      sourceRevision: 'revision-a',
      sourceSnapshotFingerprint: fingerprint,
      sourceContent: 'Registry content.',
      roots: <RegistryNode>[root],
    );

    final RegistrySnapshot currentSnapshot = RegistrySnapshot(
      projectId: 'project-b',
      projectAdapterId: 'project.registry.adapter.v1',
      sourceDocumentPath: 'registry.md',
      sourceRevision: 'revision-b',
      sourceSnapshotFingerprint: fingerprint,
      sourceContent: 'Registry content.',
      roots: <RegistryNode>[root],
    );

    expect(
      () => const RegistrySnapshotComparator().compare(
        previousIndex: RegistryStructuralIndex(previousSnapshot),
        currentIndex: RegistryStructuralIndex(currentSnapshot),
      ),
      throwsArgumentError,
    );
  });
}
