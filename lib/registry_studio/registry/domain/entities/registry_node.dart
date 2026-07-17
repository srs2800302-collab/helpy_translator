import 'package:equatable/equatable.dart';

import '../../../core/domain/evidence/source_evidence.dart';
import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../value_objects/registry_node_id.dart';

final class RegistryNode extends Equatable {
  factory RegistryNode({
    required RegistryNodeId id,
    required String kindId,
    required RegistryPath path,
    required Iterable<SourceEvidence> sourceEvidence,
    required String content,
    required RegistryEntityId? businessScopeOwnerId,
    required Iterable<RegistryNode> children,
  }) {
    final String normalizedKindId = kindId.trim();
    final List<SourceEvidence> normalizedSourceEvidence = sourceEvidence.toList(
      growable: false,
    );
    final List<RegistryNode> normalizedChildren = children.toList(
      growable: false,
    );

    if (normalizedKindId.isEmpty) {
      throw ArgumentError.value(
        kindId,
        'kindId',
        'Registry node kind identifier must not be empty.',
      );
    }

    if (normalizedSourceEvidence.isEmpty) {
      throw ArgumentError.value(
        sourceEvidence,
        'sourceEvidence',
        'Registry node must preserve source evidence.',
      );
    }

    for (final RegistryNode child in normalizedChildren) {
      if (child.path.segments.length <= path.segments.length) {
        throw ArgumentError.value(
          child.path,
          'children',
          'Registry child path must be deeper than its parent path.',
        );
      }

      for (int index = 0; index < path.segments.length; index += 1) {
        if (child.path.segments[index] != path.segments[index]) {
          throw ArgumentError.value(
            child.path,
            'children',
            'Registry child path must preserve its parent path prefix.',
          );
        }
      }
    }

    return RegistryNode._(
      id: id,
      kindId: normalizedKindId,
      path: path,
      sourceEvidence: List<SourceEvidence>.unmodifiable(
        normalizedSourceEvidence,
      ),
      content: content,
      businessScopeOwnerId: businessScopeOwnerId,
      children: List<RegistryNode>.unmodifiable(normalizedChildren),
    );
  }

  const RegistryNode._({
    required this.id,
    required this.kindId,
    required this.path,
    required this.sourceEvidence,
    required this.content,
    required this.businessScopeOwnerId,
    required this.children,
  });

  final RegistryNodeId id;
  final String kindId;
  final RegistryPath path;
  final List<SourceEvidence> sourceEvidence;
  final String content;
  final RegistryEntityId? businessScopeOwnerId;
  final List<RegistryNode> children;

  @override
  List<Object?> get props => <Object?>[
    id,
    kindId,
    path,
    sourceEvidence,
    content,
    businessScopeOwnerId,
    children,
  ];
}
