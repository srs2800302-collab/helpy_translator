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
    String? contentBlockIdentity,
    String? contentBlockLabel,
    String? scenarioIdentity,
    String? scenarioLabel,
  }) {
    final String normalizedIdentity = identity.trim();
    final List<SourceEvidence> normalizedSourceEvidence = sourceEvidence.toList(
      growable: false,
    );
    final String normalizedText = text.trim();

    final String? normalizedContentBlockIdentity = contentBlockIdentity?.trim();

    final String? normalizedContentBlockLabel = contentBlockLabel?.trim();

    final String? normalizedScenarioIdentity = scenarioIdentity?.trim();

    final String? normalizedScenarioLabel = scenarioLabel?.trim();

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

    if (normalizedContentBlockIdentity != null &&
        normalizedContentBlockIdentity.isEmpty) {
      throw ArgumentError.value(
        contentBlockIdentity,
        'contentBlockIdentity',
        'Content-block identity must not be empty.',
      );
    }

    if (normalizedContentBlockLabel != null &&
        normalizedContentBlockLabel.isEmpty) {
      throw ArgumentError.value(
        contentBlockLabel,
        'contentBlockLabel',
        'Content-block label must not be empty.',
      );
    }

    if ((normalizedContentBlockIdentity == null) !=
        (normalizedContentBlockLabel == null)) {
      throw ArgumentError(
        'Content-block identity and label must both be present '
        'or both be absent.',
      );
    }

    if (normalizedScenarioIdentity != null &&
        normalizedScenarioIdentity.isEmpty) {
      throw ArgumentError.value(
        scenarioIdentity,
        'scenarioIdentity',
        'Scenario identity must not be empty.',
      );
    }

    if (normalizedScenarioLabel != null && normalizedScenarioLabel.isEmpty) {
      throw ArgumentError.value(
        scenarioLabel,
        'scenarioLabel',
        'Scenario label must not be empty.',
      );
    }

    if ((normalizedScenarioIdentity == null) !=
        (normalizedScenarioLabel == null)) {
      throw ArgumentError(
        'Scenario identity and label must both be present '
        'or both be absent.',
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
      contentBlockIdentity: normalizedContentBlockIdentity,
      contentBlockLabel: normalizedContentBlockLabel,
      scenarioIdentity: normalizedScenarioIdentity,
      scenarioLabel: normalizedScenarioLabel,
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
    required this.contentBlockIdentity,
    required this.contentBlockLabel,
    required this.scenarioIdentity,
    required this.scenarioLabel,
  });

  final String identity;
  final RegistryNodeId nodeId;
  final RegistryEntityId businessScopeOwnerId;
  final RegistryPath path;
  final List<SourceEvidence> sourceEvidence;
  final CanonicalBusinessTextCandidateKind kind;
  final String rawText;
  final String text;

  final String? contentBlockIdentity;
  final String? contentBlockLabel;

  final String? scenarioIdentity;
  final String? scenarioLabel;

  bool get hasContentBlockContext => contentBlockIdentity != null;

  bool get hasScenarioContext => scenarioIdentity != null;

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
    contentBlockIdentity,
    contentBlockLabel,
    scenarioIdentity,
    scenarioLabel,
  ];
}
