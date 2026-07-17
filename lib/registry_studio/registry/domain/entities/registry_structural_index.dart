import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import 'registry_node.dart';
import 'registry_snapshot.dart';

final class RegistryStructuralIndex {
  factory RegistryStructuralIndex(RegistrySnapshot snapshot) {
    final List<RegistryNode> nodes = <RegistryNode>[];
    final Map<RegistryEntityId, RegistryNode> nodesById =
        <RegistryEntityId, RegistryNode>{};
    final Map<RegistryPath, RegistryNode> nodesByPath =
        <RegistryPath, RegistryNode>{};
    final Map<RegistryEntityId, RegistryEntityId?> parentIdByNodeId =
        <RegistryEntityId, RegistryEntityId?>{};
    final Map<RegistryEntityId, int> siblingPositionByNodeId =
        <RegistryEntityId, int>{};

    final List<
      ({RegistryNode node, RegistryEntityId? parentId, int siblingPosition})
    >
    remaining =
        <
          ({RegistryNode node, RegistryEntityId? parentId, int siblingPosition})
        >[];

    for (int index = snapshot.roots.length - 1; index >= 0; index -= 1) {
      remaining.add((
        node: snapshot.roots[index],
        parentId: null,
        siblingPosition: index,
      ));
    }

    while (remaining.isNotEmpty) {
      final ({
        RegistryNode node,
        RegistryEntityId? parentId,
        int siblingPosition,
      })
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
      nodesById: Map<RegistryEntityId, RegistryNode>.unmodifiable(nodesById),
      nodesByPath: Map<RegistryPath, RegistryNode>.unmodifiable(nodesByPath),
      parentIdByNodeId: Map<RegistryEntityId, RegistryEntityId?>.unmodifiable(
        parentIdByNodeId,
      ),
      siblingPositionByNodeId: Map<RegistryEntityId, int>.unmodifiable(
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
  final Map<RegistryEntityId, RegistryNode> nodesById;
  final Map<RegistryPath, RegistryNode> nodesByPath;
  final Map<RegistryEntityId, RegistryEntityId?> parentIdByNodeId;
  final Map<RegistryEntityId, int> siblingPositionByNodeId;
}
