import 'package:equatable/equatable.dart';

import '../../core/domain/evidence/source_evidence.dart';
import '../domain/value_objects/registry_node_id.dart';

final class RegistryAnalysisStatusEntry extends Equatable {
  factory RegistryAnalysisStatusEntry({
    required String identity,
    required RegistryNodeId nodeId,
    required String statusId,
    required String statusLabel,
    required String reason,
    required String text,
    required int directContentLine,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final String normalizedIdentity = identity.trim();
    final String normalizedStatusId = statusId.trim();
    final String normalizedStatusLabel = statusLabel.trim();
    final String normalizedReason = reason.trim();
    final String normalizedText = text.trim();
    final List<SourceEvidence> normalizedSourceEvidence = sourceEvidence.toList(
      growable: false,
    );

    if (normalizedIdentity.isEmpty) {
      throw ArgumentError.value(
        identity,
        'identity',
        'Registry analysis status entry identity must not be empty.',
      );
    }

    if (normalizedStatusId.isEmpty) {
      throw ArgumentError.value(
        statusId,
        'statusId',
        'Registry analysis status entry status must not be empty.',
      );
    }

    if (normalizedStatusLabel.isEmpty) {
      throw ArgumentError.value(
        statusLabel,
        'statusLabel',
        'Registry analysis status entry label must not be empty.',
      );
    }

    if (normalizedReason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Registry analysis status entry reason must not be empty.',
      );
    }

    if (normalizedText.isEmpty) {
      throw ArgumentError.value(
        text,
        'text',
        'Registry analysis status entry text must not be empty.',
      );
    }

    if (directContentLine < 0) {
      throw ArgumentError.value(
        directContentLine,
        'directContentLine',
        'Registry analysis direct-content line must not be negative.',
      );
    }

    if (normalizedSourceEvidence.isEmpty) {
      throw ArgumentError.value(
        sourceEvidence,
        'sourceEvidence',
        'Registry analysis status entry must preserve source evidence.',
      );
    }

    return RegistryAnalysisStatusEntry._(
      identity: normalizedIdentity,
      nodeId: nodeId,
      statusId: normalizedStatusId,
      statusLabel: normalizedStatusLabel,
      reason: normalizedReason,
      text: normalizedText,
      directContentLine: directContentLine,
      sourceEvidence: List<SourceEvidence>.unmodifiable(
        normalizedSourceEvidence,
      ),
    );
  }

  const RegistryAnalysisStatusEntry._({
    required this.identity,
    required this.nodeId,
    required this.statusId,
    required this.statusLabel,
    required this.reason,
    required this.text,
    required this.directContentLine,
    required this.sourceEvidence,
  });

  final String identity;
  final RegistryNodeId nodeId;
  final String statusId;
  final String statusLabel;
  final String reason;
  final String text;
  final int directContentLine;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    nodeId,
    statusId,
    statusLabel,
    reason,
    text,
    directContentLine,
    sourceEvidence,
  ];
}
