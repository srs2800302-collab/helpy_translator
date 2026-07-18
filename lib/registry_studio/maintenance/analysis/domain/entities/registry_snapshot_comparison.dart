import 'package:equatable/equatable.dart';

import 'registry_node_change.dart';

final class RegistrySnapshotComparison extends Equatable {
  factory RegistrySnapshotComparison({
    required String previousRevision,
    required String currentRevision,
    required Iterable<RegistryNodeChange> changes,
  }) {
    final String normalizedPreviousRevision = previousRevision.trim();
    final String normalizedCurrentRevision = currentRevision.trim();
    final List<RegistryNodeChange> normalizedChanges = changes.toList(
      growable: false,
    );

    if (normalizedPreviousRevision.isEmpty) {
      throw ArgumentError.value(
        previousRevision,
        'previousRevision',
        'Previous Registry revision must not be empty.',
      );
    }

    if (normalizedCurrentRevision.isEmpty) {
      throw ArgumentError.value(
        currentRevision,
        'currentRevision',
        'Current Registry revision must not be empty.',
      );
    }

    return RegistrySnapshotComparison._(
      previousRevision: normalizedPreviousRevision,
      currentRevision: normalizedCurrentRevision,
      changes: List<RegistryNodeChange>.unmodifiable(normalizedChanges),
    );
  }

  const RegistrySnapshotComparison._({
    required this.previousRevision,
    required this.currentRevision,
    required this.changes,
  });

  final String previousRevision;
  final String currentRevision;
  final List<RegistryNodeChange> changes;

  int get addedCount => changes
      .where(
        (RegistryNodeChange change) =>
            change.kind == RegistryNodeChangeKind.added,
      )
      .length;

  int get removedCount => changes
      .where(
        (RegistryNodeChange change) =>
            change.kind == RegistryNodeChangeKind.removed,
      )
      .length;

  int get changedCount => changes
      .where(
        (RegistryNodeChange change) =>
            change.kind == RegistryNodeChangeKind.changed,
      )
      .length;

  @override
  List<Object> get props => <Object>[
    previousRevision,
    currentRevision,
    changes,
  ];
}
