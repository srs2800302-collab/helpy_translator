import '../value_objects/registry_node_id.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import 'registry_node.dart';
import 'registry_snapshot.dart';

final class RegistryStructuralIndex {
  factory RegistryStructuralIndex(RegistrySnapshot snapshot) {
    final List<RegistryNode> nodes = <RegistryNode>[];
    final Map<RegistryNodeId, RegistryNode> nodesById =
        <RegistryNodeId, RegistryNode>{};
    final Map<RegistryPath, RegistryNode> nodesByPath =
        <RegistryPath, RegistryNode>{};
    final Map<RegistryNodeId, RegistryNodeId?> parentIdByNodeId =
        <RegistryNodeId, RegistryNodeId?>{};
    final Map<RegistryNodeId, int> siblingPositionByNodeId =
        <RegistryNodeId, int>{};

    final List<
      ({RegistryNode node, RegistryNodeId? parentId, int siblingPosition})
    >
    remaining =
        <
          ({RegistryNode node, RegistryNodeId? parentId, int siblingPosition})
        >[];

    for (int index = snapshot.roots.length - 1; index >= 0; index -= 1) {
      remaining.add((
        node: snapshot.roots[index],
        parentId: null,
        siblingPosition: index,
      ));
    }

    while (remaining.isNotEmpty) {
      final ({RegistryNode node, RegistryNodeId? parentId, int siblingPosition})
      current = remaining.removeLast();

      if (nodesById.containsKey(current.node.id)) {
        throw ArgumentError.value(
          current.node.id,
          'snapshot',
          'Registry structural index requires unique node identities.',
        );
      }

      if (nodesByPath.containsKey(current.node.path)) {
        throw ArgumentError.value(
          current.node.path,
          'snapshot',
          'Registry structural index requires unique node paths.',
        );
      }

      nodes.add(current.node);
      nodesById[current.node.id] = current.node;
      nodesByPath[current.node.path] = current.node;
      parentIdByNodeId[current.node.id] = current.parentId;
      siblingPositionByNodeId[current.node.id] = current.siblingPosition;

      for (
        int index = current.node.children.length - 1;
        index >= 0;
        index -= 1
      ) {
        remaining.add((
          node: current.node.children[index],
          parentId: current.node.id,
          siblingPosition: index,
        ));
      }
    }

    return RegistryStructuralIndex._(
      snapshot: snapshot,
      nodes: List<RegistryNode>.unmodifiable(nodes),
      nodesById: Map<RegistryNodeId, RegistryNode>.unmodifiable(nodesById),
      nodesByPath: Map<RegistryPath, RegistryNode>.unmodifiable(nodesByPath),
      parentIdByNodeId: Map<RegistryNodeId, RegistryNodeId?>.unmodifiable(
        parentIdByNodeId,
      ),
      siblingPositionByNodeId: Map<RegistryNodeId, int>.unmodifiable(
        siblingPositionByNodeId,
      ),
    );
  }

  const RegistryStructuralIndex._({
    required this.snapshot,
    required this.nodes,
    required this.nodesById,
    required this.nodesByPath,
    required this.parentIdByNodeId,
    required this.siblingPositionByNodeId,
  });

  final RegistrySnapshot snapshot;
  final List<RegistryNode> nodes;
  final Map<RegistryNodeId, RegistryNode> nodesById;
  final Map<RegistryPath, RegistryNode> nodesByPath;
  final Map<RegistryNodeId, RegistryNodeId?> parentIdByNodeId;
  final Map<RegistryNodeId, int> siblingPositionByNodeId;
}
