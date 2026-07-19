import 'package:equatable/equatable.dart';

import '../../../core/domain/entities/registry_entity.dart';
import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../../../core/domain/value_objects/registry_relation.dart';
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
    Iterable<RegistryEntity> entities = const <RegistryEntity>[],
    Iterable<RegistryRelation> relations = const <RegistryRelation>[],
  }) {
    final String normalizedProjectId = projectId.trim();
    final String normalizedProjectAdapterId = projectAdapterId.trim();
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedSourceRevision = sourceRevision.trim();
    final String normalizedSourceSnapshotFingerprint = sourceSnapshotFingerprint
        .trim();
    final List<RegistryNode> normalizedRoots = roots.toList(growable: false);
    final List<RegistryEntity> normalizedEntities = entities.toList(
      growable: false,
    );
    final List<RegistryRelation> normalizedRelations = relations.toList(
      growable: false,
    );

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
    final Set<RegistryPath> structuralPaths = <RegistryPath>{};

    while (remainingNodes.isNotEmpty) {
      final RegistryNode node = remainingNodes.removeLast();

      structuralPaths.add(node.path);

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

    final Set<RegistryEntityId> entityIds = <RegistryEntityId>{};

    for (final RegistryEntity entity in normalizedEntities) {
      if (!entityIds.add(entity.id)) {
        throw ArgumentError.value(
          entity.id,
          'entities',
          'Registry snapshot requires unique semantic entity identities.',
        );
      }

      if (!structuralPaths.contains(entity.path)) {
        throw ArgumentError.value(
          entity.path,
          'entities',
          'Registry semantic entity path must exist in the structural '
              'snapshot.',
        );
      }

      for (final evidence in entity.sourceEvidence) {
        if (evidence.sourceDocumentPath != normalizedSourceDocumentPath) {
          throw ArgumentError.value(
            evidence.sourceDocumentPath,
            'entities',
            'Registry semantic entity evidence must belong to the snapshot '
                'source document.',
          );
        }

        if (evidence.sourceSnapshotFingerprint !=
            normalizedSourceSnapshotFingerprint) {
          throw ArgumentError.value(
            evidence.sourceSnapshotFingerprint,
            'entities',
            'Registry semantic entity evidence must belong to the exact '
                'snapshot fingerprint.',
          );
        }
      }
    }

    final Set<RegistryRelation> uniqueRelations = <RegistryRelation>{};

    for (final RegistryRelation relation in normalizedRelations) {
      if (!entityIds.contains(relation.sourceEntityId) ||
          !entityIds.contains(relation.targetEntityId)) {
        throw ArgumentError.value(
          relation,
          'relations',
          'Registry relation endpoints must exist in the semantic snapshot.',
        );
      }

      if (!uniqueRelations.add(relation)) {
        throw ArgumentError.value(
          relation,
          'relations',
          'Registry snapshot must not contain duplicate semantic relations.',
        );
      }
    }

    return RegistrySnapshot._(
      projectId: normalizedProjectId,
      projectAdapterId: normalizedProjectAdapterId,
      sourceDocumentPath: normalizedSourceDocumentPath,
      sourceRevision: normalizedSourceRevision,
      sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
      sourceContent: sourceContent,
      roots: List<RegistryNode>.unmodifiable(normalizedRoots),
      entities: List<RegistryEntity>.unmodifiable(normalizedEntities),
      relations: List<RegistryRelation>.unmodifiable(normalizedRelations),
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
    required this.entities,
    required this.relations,
  });

  final String projectId;
  final String projectAdapterId;
  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
  final String sourceContent;
  final List<RegistryNode> roots;
  final List<RegistryEntity> entities;
  final List<RegistryRelation> relations;

  @override
  List<Object?> get props => <Object?>[
    projectId,
    projectAdapterId,
    sourceDocumentPath,
    sourceRevision,
    sourceSnapshotFingerprint,
    sourceContent,
    roots,
    entities,
    relations,
  ];
}
