import 'package:equatable/equatable.dart';

import '../../../../registry/domain/entities/registry_node.dart';

enum RegistryNodeChangeKind { added, removed, changed }

enum RegistryNodeChangeAspect { kind, path, content, businessScopeOwner }

final class RegistryNodeChange extends Equatable {
  factory RegistryNodeChange.added({required RegistryNode currentNode}) {
    return RegistryNodeChange._(
      kind: RegistryNodeChangeKind.added,
      previousNode: null,
      currentNode: currentNode,
      aspects: const <RegistryNodeChangeAspect>[],
    );
  }

  factory RegistryNodeChange.removed({required RegistryNode previousNode}) {
    return RegistryNodeChange._(
      kind: RegistryNodeChangeKind.removed,
      previousNode: previousNode,
      currentNode: null,
      aspects: const <RegistryNodeChangeAspect>[],
    );
  }

  factory RegistryNodeChange.changed({
    required RegistryNode previousNode,
    required RegistryNode currentNode,
    required Iterable<RegistryNodeChangeAspect> aspects,
  }) {
    if (previousNode.id != currentNode.id) {
      throw ArgumentError(
        'Changed Registry nodes must preserve the same stable identity.',
      );
    }

    final List<RegistryNodeChangeAspect> normalizedAspects = aspects
        .toSet()
        .toList(growable: false);

    if (normalizedAspects.isEmpty) {
      throw ArgumentError.value(
        aspects,
        'aspects',
        'Changed Registry node must contain at least one changed aspect.',
      );
    }

    return RegistryNodeChange._(
      kind: RegistryNodeChangeKind.changed,
      previousNode: previousNode,
      currentNode: currentNode,
      aspects: List<RegistryNodeChangeAspect>.unmodifiable(normalizedAspects),
    );
  }

  const RegistryNodeChange._({
    required this.kind,
    required this.previousNode,
    required this.currentNode,
    required this.aspects,
  });

  final RegistryNodeChangeKind kind;
  final RegistryNode? previousNode;
  final RegistryNode? currentNode;
  final List<RegistryNodeChangeAspect> aspects;

  @override
  List<Object?> get props => <Object?>[
    kind,
    previousNode,
    currentNode,
    aspects,
  ];
}
