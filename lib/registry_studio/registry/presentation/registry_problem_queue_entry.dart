import 'package:equatable/equatable.dart';

import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../domain/value_objects/registry_node_id.dart';

enum RegistryProblemQueueEntrySeverity {
  informational,
  reviewRequired,
  blocking,
}

final class RegistryProblemQueueEntry extends Equatable {
  factory RegistryProblemQueueEntry({
    required String identity,
    required RegistryNodeId nodeId,
    required RegistryPath path,
    required String typeLabel,
    required String statusLabel,
    required String reason,
    required RegistryProblemQueueEntrySeverity severity,
    required List<SourceEvidence> sourceEvidence,
  }) {
    final String normalizedIdentity = identity.trim();
    final String normalizedTypeLabel = typeLabel.trim();
    final String normalizedStatusLabel = statusLabel.trim();
    final String normalizedReason = reason.trim();

    if (normalizedIdentity.isEmpty) {
      throw ArgumentError.value(
        identity,
        'identity',
        'Problem queue entry identity must not be empty.',
      );
    }

    if (normalizedTypeLabel.isEmpty) {
      throw ArgumentError.value(
        typeLabel,
        'typeLabel',
        'Problem queue entry type label must not be empty.',
      );
    }

    if (normalizedStatusLabel.isEmpty) {
      throw ArgumentError.value(
        statusLabel,
        'statusLabel',
        'Problem queue entry status label must not be empty.',
      );
    }

    if (normalizedReason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Problem queue entry reason must not be empty.',
      );
    }

    if (sourceEvidence.isEmpty) {
      throw ArgumentError.value(
        sourceEvidence,
        'sourceEvidence',
        'Problem queue entry requires source evidence.',
      );
    }

    return RegistryProblemQueueEntry._(
      identity: normalizedIdentity,
      nodeId: nodeId,
      path: path,
      typeLabel: normalizedTypeLabel,
      statusLabel: normalizedStatusLabel,
      reason: normalizedReason,
      severity: severity,
      sourceEvidence: List<SourceEvidence>.unmodifiable(sourceEvidence),
    );
  }

  const RegistryProblemQueueEntry._({
    required this.identity,
    required this.nodeId,
    required this.path,
    required this.typeLabel,
    required this.statusLabel,
    required this.reason,
    required this.severity,
    required this.sourceEvidence,
  });

  final String identity;
  final RegistryNodeId nodeId;
  final RegistryPath path;
  final String typeLabel;
  final String statusLabel;
  final String reason;
  final RegistryProblemQueueEntrySeverity severity;
  final List<SourceEvidence> sourceEvidence;

  bool get requiresAttention =>
      severity != RegistryProblemQueueEntrySeverity.informational;

  @override
  List<Object?> get props => <Object?>[
    identity,
    nodeId,
    path,
    typeLabel,
    statusLabel,
    reason,
    severity,
    sourceEvidence,
  ];
}
