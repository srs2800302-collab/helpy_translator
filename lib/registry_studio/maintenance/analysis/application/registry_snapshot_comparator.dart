import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_structural_index.dart';
import '../domain/entities/registry_node_change.dart';
import '../domain/entities/registry_snapshot_comparison.dart';

final class RegistrySnapshotComparator {
  const RegistrySnapshotComparator();

  RegistrySnapshotComparison compare({
    required RegistryStructuralIndex previousIndex,
    required RegistryStructuralIndex currentIndex,
  }) {
    final previousSnapshot = previousIndex.snapshot;
    final currentSnapshot = currentIndex.snapshot;

    if (previousSnapshot.projectId != currentSnapshot.projectId ||
        previousSnapshot.projectAdapterId != currentSnapshot.projectAdapterId ||
        previousSnapshot.sourceDocumentPath !=
            currentSnapshot.sourceDocumentPath) {
      throw ArgumentError(
        'Registry comparison requires matching project, adapter, '
        'and source document coordinates.',
      );
    }

    final List<RegistryNodeChange> changes = <RegistryNodeChange>[];

    for (final RegistryNode currentNode in currentIndex.nodes) {
      final RegistryNode? previousNode =
          previousIndex.nodesById[currentNode.id];

      if (previousNode == null) {
        changes.add(RegistryNodeChange.added(currentNode: currentNode));
        continue;
      }

      final List<RegistryNodeChangeAspect> aspects =
          <RegistryNodeChangeAspect>[];

      if (previousNode.kindId != currentNode.kindId) {
        aspects.add(RegistryNodeChangeAspect.kind);
      }

      if (previousNode.path != currentNode.path) {
        aspects.add(RegistryNodeChangeAspect.path);
      }

      if (previousNode.content != currentNode.content) {
        aspects.add(RegistryNodeChangeAspect.content);
      }

      if (previousNode.businessScopeOwnerId !=
          currentNode.businessScopeOwnerId) {
        aspects.add(RegistryNodeChangeAspect.businessScopeOwner);
      }

      if (aspects.isNotEmpty) {
        changes.add(
          RegistryNodeChange.changed(
            previousNode: previousNode,
            currentNode: currentNode,
            aspects: aspects,
          ),
        );
      }
    }

    for (final RegistryNode previousNode in previousIndex.nodes) {
      if (!currentIndex.nodesById.containsKey(previousNode.id)) {
        changes.add(RegistryNodeChange.removed(previousNode: previousNode));
      }
    }

    return RegistrySnapshotComparison(
      previousRevision: previousSnapshot.sourceRevision,
      currentRevision: currentSnapshot.sourceRevision,
      changes: changes,
    );
  }
}
