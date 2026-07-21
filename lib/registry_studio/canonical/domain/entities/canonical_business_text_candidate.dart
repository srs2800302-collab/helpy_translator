import 'package:equatable/equatable.dart';

import '../../../core/domain/evidence/source_evidence.dart';
import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';

enum CanonicalBusinessTextCandidateKind {
  heading,
  paragraph,
  listItem,
  blockquote,
  tableRow,
}

final class CanonicalBusinessTextCandidate extends Equatable {
  factory CanonicalBusinessTextCandidate({
    required String identity,
    required RegistryNodeId nodeId,
    required RegistryEntityId businessScopeOwnerId,
    required RegistryPath path,
    required Iterable<SourceEvidence> sourceEvidence,
    required CanonicalBusinessTextCandidateKind kind,
    required String rawText,
    required String text,
    required int directContentLine,
  }) {
    final String normalizedIdentity = identity.trim();
    final List<SourceEvidence> normalizedSourceEvidence = sourceEvidence.toList(
      growable: false,
    );
    final String normalizedText = text.trim();

    if (normalizedIdentity.isEmpty) {
      throw ArgumentError.value(
        identity,
        'identity',
        'Canonical business-text candidate identity '
            'must not be empty.',
      );
    }

    if (normalizedSourceEvidence.isEmpty) {
      throw ArgumentError.value(
        sourceEvidence,
        'sourceEvidence',
        'Canonical business-text candidate must preserve '
            'source evidence.',
      );
    }

    if (rawText.trim().isEmpty) {
      throw ArgumentError.value(
        rawText,
        'rawText',
        'Canonical business-text candidate raw text '
            'must not be empty.',
      );
    }

    if (normalizedText.isEmpty) {
      throw ArgumentError.value(
        text,
        'text',
        'Canonical business-text candidate text '
            'must not be empty.',
      );
    }

    if (kind == CanonicalBusinessTextCandidateKind.heading &&
        directContentLine != 0) {
      throw ArgumentError.value(
        directContentLine,
        'directContentLine',
        'Heading candidate must use direct-content line zero.',
      );
    }

    if (kind != CanonicalBusinessTextCandidateKind.heading &&
        directContentLine < 1) {
      throw ArgumentError.value(
        directContentLine,
        'directContentLine',
        'Content candidate direct-content line '
            'must be positive.',
      );
    }

    return CanonicalBusinessTextCandidate._(
      identity: normalizedIdentity,
      nodeId: nodeId,
      businessScopeOwnerId: businessScopeOwnerId,
      path: path,
      sourceEvidence: List<SourceEvidence>.unmodifiable(
        normalizedSourceEvidence,
      ),
      kind: kind,
      rawText: rawText,
      text: normalizedText,
      directContentLine: directContentLine,
    );
  }

  const CanonicalBusinessTextCandidate._({
    required this.identity,
    required this.nodeId,
    required this.businessScopeOwnerId,
    required this.path,
    required this.sourceEvidence,
    required this.kind,
    required this.rawText,
    required this.text,
    required this.directContentLine,
  });

  final String identity;
  final RegistryNodeId nodeId;
  final RegistryEntityId businessScopeOwnerId;
  final RegistryPath path;
  final List<SourceEvidence> sourceEvidence;
  final CanonicalBusinessTextCandidateKind kind;
  final String rawText;
  final String text;

  /// Zero identifies the structural heading.
  ///
  /// Positive values identify a line inside RegistryNode.content.
  /// This coordinate is evidence only and is not part of permanent
  /// Registry node identity.
  final int directContentLine;

  @override
  List<Object?> get props => <Object?>[
    identity,
    nodeId,
    businessScopeOwnerId,
    path,
    sourceEvidence,
    kind,
    rawText,
    text,
    directContentLine,
  ];
}
