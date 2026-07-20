import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_structural_index.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
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

    final Map<RegistryNodeId?, List<RegistryNodeId>> previousSiblingOrders =
        <RegistryNodeId?, List<RegistryNodeId>>{
          null: previousSnapshot.roots
              .map((RegistryNode node) => node.id)
              .toList(growable: false),
        };

    for (final RegistryNode previousNode in previousIndex.nodes) {
      previousSiblingOrders[previousNode.id] = previousNode.children
          .map((RegistryNode child) => child.id)
          .toList(growable: false);
    }

    final Map<RegistryNodeId?, List<RegistryNodeId>> currentSiblingOrders =
        <RegistryNodeId?, List<RegistryNodeId>>{
          null: currentSnapshot.roots
              .map((RegistryNode node) => node.id)
              .toList(growable: false),
        };

    for (final RegistryNode currentNode in currentIndex.nodes) {
      currentSiblingOrders[currentNode.id] = currentNode.children
          .map((RegistryNode child) => child.id)
          .toList(growable: false);
    }

    final Set<RegistryNodeId> reorderedNodeIds = <RegistryNodeId>{};

    for (final MapEntry<RegistryNodeId?, List<RegistryNodeId>>
        previousSiblingOrder
        in previousSiblingOrders.entries) {
      final List<RegistryNodeId>? currentSiblingOrder =
          currentSiblingOrders[previousSiblingOrder.key];

      if (currentSiblingOrder == null) {
        continue;
      }

      final Set<RegistryNodeId> currentSiblingIds = currentSiblingOrder.toSet();

      final List<RegistryNodeId> previousCommonOrder = previousSiblingOrder
          .value
          .where(currentSiblingIds.contains)
          .toList(growable: false);

      final Set<RegistryNodeId> previousSiblingIds = previousSiblingOrder.value
          .toSet();

      final List<RegistryNodeId> currentCommonOrder = currentSiblingOrder
          .where(previousSiblingIds.contains)
          .toList(growable: false);

      final Map<RegistryNodeId, int> previousPositions = <RegistryNodeId, int>{
        for (int index = 0; index < previousCommonOrder.length; index += 1)
          previousCommonOrder[index]: index,
      };

      for (int index = 0; index < currentCommonOrder.length; index += 1) {
        final RegistryNodeId nodeId = currentCommonOrder[index];

        if (previousPositions[nodeId] != index) {
          reorderedNodeIds.add(nodeId);
        }
      }
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

      if (reorderedNodeIds.contains(currentNode.id)) {
        aspects.add(RegistryNodeChangeAspect.order);
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
