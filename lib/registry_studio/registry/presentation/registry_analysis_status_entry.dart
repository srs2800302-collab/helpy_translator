import 'package:equatable/equatable.dart';

import '../domain/value_objects/registry_node_id.dart';

final class RegistryAnalysisStatusEntry extends Equatable {
  factory RegistryAnalysisStatusEntry({
    required String identity,
    required RegistryNodeId nodeId,
    required String statusId,
  }) {
    final String normalizedIdentity = identity.trim();
    final String normalizedStatusId = statusId.trim();

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

    return RegistryAnalysisStatusEntry._(
      identity: normalizedIdentity,
      nodeId: nodeId,
      statusId: normalizedStatusId,
    );
  }

  const RegistryAnalysisStatusEntry._({
    required this.identity,
    required this.nodeId,
    required this.statusId,
  });

  final String identity;
  final RegistryNodeId nodeId;
  final String statusId;

  @override
  List<Object?> get props => <Object?>[identity, nodeId, statusId];
}
