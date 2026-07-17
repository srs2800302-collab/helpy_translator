import 'package:equatable/equatable.dart';

import 'registry_node.dart';

final class RegistrySnapshot extends Equatable {
  factory RegistrySnapshot({
    required String projectId,
    required String projectAdapterId,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
    required String sourceContent,
    required Iterable<RegistryNode> roots,
  }) {
    final String normalizedProjectId = projectId.trim();
    final String normalizedProjectAdapterId = projectAdapterId.trim();
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedSourceRevision = sourceRevision.trim();
    final String normalizedSourceSnapshotFingerprint = sourceSnapshotFingerprint
        .trim();
    final List<RegistryNode> normalizedRoots = roots.toList(growable: false);

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError.value(
        projectId,
        'projectId',
        'Registry snapshot project identifier must not be empty.',
      );
    }

    if (normalizedProjectAdapterId.isEmpty) {
      throw ArgumentError.value(
        projectAdapterId,
        'projectAdapterId',
        'Registry snapshot project adapter identifier must not be empty.',
      );
    }

    if (normalizedSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentPath,
        'sourceDocumentPath',
        'Registry snapshot source document path must not be empty.',
      );
    }

    if (normalizedSourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Registry snapshot source revision must not be empty.',
      );
    }

    if (normalizedSourceSnapshotFingerprint.isEmpty) {
      throw ArgumentError.value(
        sourceSnapshotFingerprint,
        'sourceSnapshotFingerprint',
        'Registry snapshot fingerprint must not be empty.',
      );
    }

    if (sourceContent.trim().isEmpty) {
      throw ArgumentError.value(
        sourceContent,
        'sourceContent',
        'Registry snapshot source content must not be empty.',
      );
    }

    if (normalizedRoots.isEmpty) {
      throw ArgumentError.value(
        roots,
        'roots',
        'Registry snapshot must contain at least one root node.',
      );
    }

    final List<RegistryNode> remainingNodes = <RegistryNode>[
      ...normalizedRoots,
    ];

    while (remainingNodes.isNotEmpty) {
      final RegistryNode node = remainingNodes.removeLast();

      for (final evidence in node.sourceEvidence) {
        if (evidence.sourceDocumentPath != normalizedSourceDocumentPath) {
          throw ArgumentError.value(
            evidence.sourceDocumentPath,
            'roots',
            'Registry node evidence must belong to the snapshot source document.',
          );
        }

        if (evidence.sourceSnapshotFingerprint !=
            normalizedSourceSnapshotFingerprint) {
          throw ArgumentError.value(
            evidence.sourceSnapshotFingerprint,
            'roots',
            'Registry node evidence must belong to the exact snapshot fingerprint.',
          );
        }
      }

      remainingNodes.addAll(node.children);
    }

    return RegistrySnapshot._(
      projectId: normalizedProjectId,
      projectAdapterId: normalizedProjectAdapterId,
      sourceDocumentPath: normalizedSourceDocumentPath,
      sourceRevision: normalizedSourceRevision,
      sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
      sourceContent: sourceContent,
      roots: List<RegistryNode>.unmodifiable(normalizedRoots),
    );
  }

  const RegistrySnapshot._({
    required this.projectId,
    required this.projectAdapterId,
    required this.sourceDocumentPath,
    required this.sourceRevision,
    required this.sourceSnapshotFingerprint,
    required this.sourceContent,
    required this.roots,
  });

  final String projectId;
  final String projectAdapterId;
  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
  final String sourceContent;
  final List<RegistryNode> roots;

  @override
  List<Object?> get props => <Object?>[
    projectId,
    projectAdapterId,
    sourceDocumentPath,
    sourceRevision,
    sourceSnapshotFingerprint,
    sourceContent,
    roots,
  ];
}
