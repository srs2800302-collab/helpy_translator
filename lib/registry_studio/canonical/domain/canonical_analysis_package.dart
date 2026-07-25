import 'package:equatable/equatable.dart';

import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_entity_id.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../../registry/domain/value_objects/registry_node_id.dart';
import 'canonical_dictionary.dart';

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      '$fieldName must not be empty.',
    );
  }

  return normalized;
}

String? _optionalText(String? value) {
  final String? normalized = value?.trim();

  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized;
}

List<SourceEvidence> _requiredEvidence(
  Iterable<SourceEvidence> evidence,
  String fieldName,
) {
  final List<SourceEvidence> normalized = evidence.toList(growable: false);

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      evidence,
      fieldName,
      '$fieldName must preserve source evidence.',
    );
  }

  return List<SourceEvidence>.unmodifiable(normalized);
}

enum CanonicalAdapterFailureSource { adapter, dictionary, registry }

enum CanonicalAdapterFailureSeverity { fatal, partial }

final class CanonicalAnalysisPackage extends Equatable {
  factory CanonicalAnalysisPackage({
    required String projectId,
    required String projectAdapterId,
    required String registrySourceDocumentPath,
    required String registryRevision,
    required String registrySourceSnapshotFingerprint,
    required CanonicalDictionary? dictionary,
    required Iterable<CanonicalBusinessEntity> businessEntities,
    required Iterable<CanonicalOrderedBusinessBlock> orderedBusinessBlocks,
    required Iterable<CanonicalAdapterFailure> adapterFailures,
  }) {
    final String normalizedProjectId = _requiredText(projectId, 'projectId');
    final String normalizedAdapterId = _requiredText(
      projectAdapterId,
      'projectAdapterId',
    );
    final String normalizedRegistryPath = _requiredText(
      registrySourceDocumentPath,
      'registrySourceDocumentPath',
    );
    final String normalizedRegistryRevision = _requiredText(
      registryRevision,
      'registryRevision',
    );
    final String normalizedRegistryFingerprint = _requiredText(
      registrySourceSnapshotFingerprint,
      'registrySourceSnapshotFingerprint',
    );

    final List<CanonicalBusinessEntity> normalizedEntities = businessEntities
        .toList(growable: false);
    final List<CanonicalOrderedBusinessBlock> normalizedOrderedBlocks =
        orderedBusinessBlocks.toList(growable: false);
    final List<CanonicalAdapterFailure> normalizedFailures = adapterFailures
        .toList(growable: false);

    if (dictionary == null &&
        !normalizedFailures.any(
          (CanonicalAdapterFailure failure) =>
              failure.severity == CanonicalAdapterFailureSeverity.fatal,
        )) {
      throw ArgumentError(
        'Missing Canonical Dictionary requires a fatal adapter failure.',
      );
    }

    final Set<String> entityIdentities = <String>{};
    final Map<String, CanonicalBusinessScopeReference> scopesByIdentity =
        <String, CanonicalBusinessScopeReference>{};
    final Set<String> scenarioIdentities = <String>{};
    final Set<String> blockIdentities = <String>{};
    final Set<String> textIdentities = <String>{};
    final Set<String> orderedBlockIdentities = <String>{};
    final Set<String> orderedItemIdentities = <String>{};
    final Set<String> failureIdentities = <String>{};

    for (final CanonicalBusinessEntity entity in normalizedEntities) {
      _requireUniqueIdentity(
        entityIdentities,
        entity.identity,
        'businessEntities',
      );
      _validateRegistryEvidence(
        entity.sourceEvidence,
        sourceDocumentPath: normalizedRegistryPath,
        sourceSnapshotFingerprint: normalizedRegistryFingerprint,
      );

      for (final CanonicalBusinessScopeReference scope in entity.scopeLineage) {
        final CanonicalBusinessScopeReference? existingScope =
            scopesByIdentity[scope.identity];

        if (existingScope != null && existingScope != scope) {
          throw ArgumentError.value(
            scope.identity,
            'scopeLineage',
            'Repeated business-scope identity must preserve the same '
                'structural reference and evidence.',
          );
        }

        scopesByIdentity[scope.identity] = scope;
        _validateRegistryEvidence(
          scope.sourceEvidence,
          sourceDocumentPath: normalizedRegistryPath,
          sourceSnapshotFingerprint: normalizedRegistryFingerprint,
        );
      }

      for (final CanonicalBusinessScenario scenario in entity.scenarios) {
        _requireUniqueIdentity(
          scenarioIdentities,
          scenario.identity,
          'scenarios',
        );
        _validateRegistryEvidence(
          scenario.sourceEvidence,
          sourceDocumentPath: normalizedRegistryPath,
          sourceSnapshotFingerprint: normalizedRegistryFingerprint,
        );

        for (final CanonicalBusinessBlock block in scenario.blocks) {
          _requireUniqueIdentity(blockIdentities, block.identity, 'blocks');
          _validateRegistryEvidence(
            block.sourceEvidence,
            sourceDocumentPath: normalizedRegistryPath,
            sourceSnapshotFingerprint: normalizedRegistryFingerprint,
          );

          for (final CanonicalBusinessText text in block.items) {
            _requireUniqueIdentity(
              textIdentities,
              text.identity,
              'businessTexts',
            );
            _validateRegistryEvidence(
              text.sourceEvidence,
              sourceDocumentPath: normalizedRegistryPath,
              sourceSnapshotFingerprint: normalizedRegistryFingerprint,
            );
          }
        }
      }
    }

    for (final CanonicalOrderedBusinessBlock block in normalizedOrderedBlocks) {
      _requireUniqueIdentity(
        orderedBlockIdentities,
        block.identity,
        'orderedBusinessBlocks',
      );
      _validateRegistryEvidence(
        block.sourceEvidence,
        sourceDocumentPath: normalizedRegistryPath,
        sourceSnapshotFingerprint: normalizedRegistryFingerprint,
      );

      for (final CanonicalOrderedBusinessItem item in block.items) {
        _requireUniqueIdentity(
          orderedItemIdentities,
          item.identity,
          'orderedBusinessItems',
        );
        _validateRegistryEvidence(
          item.sourceEvidence,
          sourceDocumentPath: normalizedRegistryPath,
          sourceSnapshotFingerprint: normalizedRegistryFingerprint,
        );
      }
    }

    for (final CanonicalAdapterFailure failure in normalizedFailures) {
      _requireUniqueIdentity(
        failureIdentities,
        failure.identity,
        'adapterFailures',
      );

      if (failure.source == CanonicalAdapterFailureSource.registry &&
          failure.sourceEvidence.isNotEmpty) {
        _validateRegistryEvidence(
          failure.sourceEvidence,
          sourceDocumentPath: normalizedRegistryPath,
          sourceSnapshotFingerprint: normalizedRegistryFingerprint,
        );
      }

      if (failure.source == CanonicalAdapterFailureSource.dictionary &&
          dictionary != null &&
          failure.sourceEvidence.isNotEmpty) {
        _validateDictionaryEvidence(
          failure.sourceEvidence,
          dictionary: dictionary,
        );
      }
    }

    return CanonicalAnalysisPackage._(
      projectId: normalizedProjectId,
      projectAdapterId: normalizedAdapterId,
      registrySourceDocumentPath: normalizedRegistryPath,
      registryRevision: normalizedRegistryRevision,
      registrySourceSnapshotFingerprint: normalizedRegistryFingerprint,
      dictionary: dictionary,
      businessEntities: List<CanonicalBusinessEntity>.unmodifiable(
        normalizedEntities,
      ),
      orderedBusinessBlocks: List<CanonicalOrderedBusinessBlock>.unmodifiable(
        normalizedOrderedBlocks,
      ),
      adapterFailures: List<CanonicalAdapterFailure>.unmodifiable(
        normalizedFailures,
      ),
    );
  }

  const CanonicalAnalysisPackage._({
    required this.projectId,
    required this.projectAdapterId,
    required this.registrySourceDocumentPath,
    required this.registryRevision,
    required this.registrySourceSnapshotFingerprint,
    required this.dictionary,
    required this.businessEntities,
    required this.orderedBusinessBlocks,
    required this.adapterFailures,
  });

  final String projectId;
  final String projectAdapterId;
  final String registrySourceDocumentPath;
  final String registryRevision;
  final String registrySourceSnapshotFingerprint;
  final CanonicalDictionary? dictionary;
  final List<CanonicalBusinessEntity> businessEntities;
  final List<CanonicalOrderedBusinessBlock> orderedBusinessBlocks;
  final List<CanonicalAdapterFailure> adapterFailures;

  bool get hasFatalFailure => adapterFailures.any(
    (CanonicalAdapterFailure failure) =>
        failure.severity == CanonicalAdapterFailureSeverity.fatal,
  );

  @override
  List<Object?> get props => <Object?>[
    projectId,
    projectAdapterId,
    registrySourceDocumentPath,
    registryRevision,
    registrySourceSnapshotFingerprint,
    dictionary,
    businessEntities,
    orderedBusinessBlocks,
    adapterFailures,
  ];
}

final class CanonicalBusinessScopeReference extends Equatable {
  factory CanonicalBusinessScopeReference({
    required String identity,
    required String kindId,
    required String label,
    required RegistryPath path,
    required RegistryNodeId sourceNodeId,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    return CanonicalBusinessScopeReference._(
      identity: _requiredText(identity, 'identity'),
      kindId: _requiredText(kindId, 'kindId'),
      label: _requiredText(label, 'label'),
      path: path,
      sourceNodeId: sourceNodeId,
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalBusinessScopeReference._({
    required this.identity,
    required this.kindId,
    required this.label,
    required this.path,
    required this.sourceNodeId,
    required this.sourceEvidence,
  });

  final String identity;
  final String kindId;
  final String label;
  final RegistryPath path;
  final RegistryNodeId sourceNodeId;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    kindId,
    label,
    path,
    sourceNodeId,
    sourceEvidence,
  ];
}

final class CanonicalBusinessEntity extends Equatable {
  factory CanonicalBusinessEntity({
    required String identity,
    required String label,
    required RegistryPath path,
    required RegistryNodeId sourceNodeId,
    required RegistryEntityId? businessScopeOwnerId,
    required Iterable<CanonicalBusinessScopeReference> scopeLineage,
    required Iterable<CanonicalBusinessScenario> scenarios,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final List<CanonicalBusinessScopeReference> normalizedLineage = scopeLineage
        .toList(growable: false);
    final List<CanonicalBusinessScenario> normalizedScenarios = scenarios
        .toList(growable: false);

    if (normalizedScenarios.isEmpty) {
      throw ArgumentError.value(
        scenarios,
        'scenarios',
        'Canonical business entity must contain at least one scenario.',
      );
    }

    final Set<String> scenarioIdentities = <String>{};

    for (final CanonicalBusinessScenario scenario in normalizedScenarios) {
      if (!scenarioIdentities.add(scenario.identity)) {
        throw ArgumentError.value(
          scenario.identity,
          'scenarios',
          'Scenario identity must be unique inside its entity.',
        );
      }
    }

    return CanonicalBusinessEntity._(
      identity: _requiredText(identity, 'identity'),
      label: _requiredText(label, 'label'),
      path: path,
      sourceNodeId: sourceNodeId,
      businessScopeOwnerId: businessScopeOwnerId,
      scopeLineage: List<CanonicalBusinessScopeReference>.unmodifiable(
        normalizedLineage,
      ),
      scenarios: List<CanonicalBusinessScenario>.unmodifiable(
        normalizedScenarios,
      ),
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalBusinessEntity._({
    required this.identity,
    required this.label,
    required this.path,
    required this.sourceNodeId,
    required this.businessScopeOwnerId,
    required this.scopeLineage,
    required this.scenarios,
    required this.sourceEvidence,
  });

  final String identity;
  final String label;
  final RegistryPath path;
  final RegistryNodeId sourceNodeId;
  final RegistryEntityId? businessScopeOwnerId;
  final List<CanonicalBusinessScopeReference> scopeLineage;
  final List<CanonicalBusinessScenario> scenarios;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    label,
    path,
    sourceNodeId,
    businessScopeOwnerId,
    scopeLineage,
    scenarios,
    sourceEvidence,
  ];
}

final class CanonicalBusinessScenario extends Equatable {
  factory CanonicalBusinessScenario({
    required String identity,
    required String label,
    required RegistryPath path,
    required RegistryNodeId sourceNodeId,
    required Iterable<CanonicalBusinessBlock> blocks,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final List<CanonicalBusinessBlock> normalizedBlocks = blocks.toList(
      growable: false,
    );

    final Set<CanonicalContentRole> roles = <CanonicalContentRole>{
      for (final CanonicalBusinessBlock block in normalizedBlocks) block.role,
    };

    if (normalizedBlocks.length != CanonicalContentRole.values.length ||
        roles.length != CanonicalContentRole.values.length ||
        !roles.containsAll(CanonicalContentRole.values)) {
      throw ArgumentError.value(
        blocks,
        'blocks',
        'Each scenario must contain exactly one questions, photoQuestions, '
            'clientRules and masterRules block.',
      );
    }

    return CanonicalBusinessScenario._(
      identity: _requiredText(identity, 'identity'),
      label: _requiredText(label, 'label'),
      path: path,
      sourceNodeId: sourceNodeId,
      blocks: List<CanonicalBusinessBlock>.unmodifiable(normalizedBlocks),
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalBusinessScenario._({
    required this.identity,
    required this.label,
    required this.path,
    required this.sourceNodeId,
    required this.blocks,
    required this.sourceEvidence,
  });

  final String identity;
  final String label;
  final RegistryPath path;
  final RegistryNodeId sourceNodeId;
  final List<CanonicalBusinessBlock> blocks;
  final List<SourceEvidence> sourceEvidence;

  CanonicalBusinessBlock blockForRole(CanonicalContentRole role) {
    return blocks.singleWhere(
      (CanonicalBusinessBlock block) => block.role == role,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    identity,
    label,
    path,
    sourceNodeId,
    blocks,
    sourceEvidence,
  ];
}

final class CanonicalBusinessBlock extends Equatable {
  factory CanonicalBusinessBlock({
    required String identity,
    required CanonicalContentRole role,
    required String label,
    required RegistryPath path,
    required RegistryNodeId sourceNodeId,
    required Iterable<CanonicalBusinessText> items,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final List<CanonicalBusinessText> normalizedItems = items.toList(
      growable: false,
    );

    if (normalizedItems.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'Canonical scenario block must contain business text.',
      );
    }

    for (int index = 0; index < normalizedItems.length; index += 1) {
      if (normalizedItems[index].sourceOrder != index + 1) {
        throw ArgumentError(
          'Canonical business-text source order must be contiguous.',
        );
      }
    }

    return CanonicalBusinessBlock._(
      identity: _requiredText(identity, 'identity'),
      role: role,
      label: _requiredText(label, 'label'),
      path: path,
      sourceNodeId: sourceNodeId,
      items: List<CanonicalBusinessText>.unmodifiable(normalizedItems),
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalBusinessBlock._({
    required this.identity,
    required this.role,
    required this.label,
    required this.path,
    required this.sourceNodeId,
    required this.items,
    required this.sourceEvidence,
  });

  final String identity;
  final CanonicalContentRole role;
  final String label;
  final RegistryPath path;
  final RegistryNodeId sourceNodeId;
  final List<CanonicalBusinessText> items;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    role,
    label,
    path,
    sourceNodeId,
    items,
    sourceEvidence,
  ];
}

final class CanonicalBusinessText extends Equatable {
  factory CanonicalBusinessText({
    required String identity,
    required String text,
    required int sourceOrder,
    required RegistryPath path,
    required RegistryNodeId sourceNodeId,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    if (sourceOrder <= 0) {
      throw ArgumentError.value(
        sourceOrder,
        'sourceOrder',
        'sourceOrder must be positive.',
      );
    }

    return CanonicalBusinessText._(
      identity: _requiredText(identity, 'identity'),
      text: _requiredText(text, 'text'),
      sourceOrder: sourceOrder,
      path: path,
      sourceNodeId: sourceNodeId,
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalBusinessText._({
    required this.identity,
    required this.text,
    required this.sourceOrder,
    required this.path,
    required this.sourceNodeId,
    required this.sourceEvidence,
  });

  final String identity;
  final String text;
  final int sourceOrder;
  final RegistryPath path;
  final RegistryNodeId sourceNodeId;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    text,
    sourceOrder,
    path,
    sourceNodeId,
    sourceEvidence,
  ];
}

final class CanonicalOrderedBusinessBlock extends Equatable {
  factory CanonicalOrderedBusinessBlock({
    required String identity,
    required String label,
    required String? ownerScopeIdentity,
    required String? ownerEntityIdentity,
    required String? ownerScenarioIdentity,
    required String? ownerContentBlockIdentity,
    required RegistryPath path,
    required RegistryNodeId sourceNodeId,
    required Iterable<CanonicalOrderedBusinessItem> items,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final String? normalizedScopeIdentity = _optionalText(ownerScopeIdentity);
    final String? normalizedEntityIdentity = _optionalText(ownerEntityIdentity);
    final String? normalizedScenarioIdentity = _optionalText(
      ownerScenarioIdentity,
    );
    final String? normalizedBlockIdentity = _optionalText(
      ownerContentBlockIdentity,
    );

    if (normalizedScopeIdentity == null &&
        normalizedEntityIdentity == null &&
        normalizedScenarioIdentity == null &&
        normalizedBlockIdentity == null) {
      throw ArgumentError(
        'Ordered business block must preserve at least one owner identity.',
      );
    }

    final List<CanonicalOrderedBusinessItem> normalizedItems = items.toList(
      growable: false,
    );

    if (normalizedItems.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'Ordered business block must contain items.',
      );
    }

    for (int index = 0; index < normalizedItems.length; index += 1) {
      if (normalizedItems[index].sourceOrder != index + 1) {
        throw ArgumentError(
          'Ordered business-item source order must be contiguous.',
        );
      }
    }

    return CanonicalOrderedBusinessBlock._(
      identity: _requiredText(identity, 'identity'),
      label: _requiredText(label, 'label'),
      ownerScopeIdentity: normalizedScopeIdentity,
      ownerEntityIdentity: normalizedEntityIdentity,
      ownerScenarioIdentity: normalizedScenarioIdentity,
      ownerContentBlockIdentity: normalizedBlockIdentity,
      path: path,
      sourceNodeId: sourceNodeId,
      items: List<CanonicalOrderedBusinessItem>.unmodifiable(normalizedItems),
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalOrderedBusinessBlock._({
    required this.identity,
    required this.label,
    required this.ownerScopeIdentity,
    required this.ownerEntityIdentity,
    required this.ownerScenarioIdentity,
    required this.ownerContentBlockIdentity,
    required this.path,
    required this.sourceNodeId,
    required this.items,
    required this.sourceEvidence,
  });

  final String identity;
  final String label;
  final String? ownerScopeIdentity;
  final String? ownerEntityIdentity;
  final String? ownerScenarioIdentity;
  final String? ownerContentBlockIdentity;
  final RegistryPath path;
  final RegistryNodeId sourceNodeId;
  final List<CanonicalOrderedBusinessItem> items;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    label,
    ownerScopeIdentity,
    ownerEntityIdentity,
    ownerScenarioIdentity,
    ownerContentBlockIdentity,
    path,
    sourceNodeId,
    items,
    sourceEvidence,
  ];
}

final class CanonicalOrderedBusinessItem extends Equatable {
  factory CanonicalOrderedBusinessItem({
    required String identity,
    required String text,
    required int sourceOrder,
    required RegistryPath path,
    required RegistryNodeId sourceNodeId,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    if (sourceOrder <= 0) {
      throw ArgumentError.value(
        sourceOrder,
        'sourceOrder',
        'sourceOrder must be positive.',
      );
    }

    return CanonicalOrderedBusinessItem._(
      identity: _requiredText(identity, 'identity'),
      text: _requiredText(text, 'text'),
      sourceOrder: sourceOrder,
      path: path,
      sourceNodeId: sourceNodeId,
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalOrderedBusinessItem._({
    required this.identity,
    required this.text,
    required this.sourceOrder,
    required this.path,
    required this.sourceNodeId,
    required this.sourceEvidence,
  });

  final String identity;
  final String text;
  final int sourceOrder;
  final RegistryPath path;
  final RegistryNodeId sourceNodeId;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    text,
    sourceOrder,
    path,
    sourceNodeId,
    sourceEvidence,
  ];
}

final class CanonicalAdapterFailure extends Equatable {
  factory CanonicalAdapterFailure({
    required String identity,
    required CanonicalAdapterFailureSource source,
    required CanonicalAdapterFailureSeverity severity,
    required String code,
    required String explanation,
    required String? relatedIdentity,
    required RegistryPath? path,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    return CanonicalAdapterFailure._(
      identity: _requiredText(identity, 'identity'),
      source: source,
      severity: severity,
      code: _requiredText(code, 'code'),
      explanation: _requiredText(explanation, 'explanation'),
      relatedIdentity: _optionalText(relatedIdentity),
      path: path,
      sourceEvidence: List<SourceEvidence>.unmodifiable(sourceEvidence),
    );
  }

  const CanonicalAdapterFailure._({
    required this.identity,
    required this.source,
    required this.severity,
    required this.code,
    required this.explanation,
    required this.relatedIdentity,
    required this.path,
    required this.sourceEvidence,
  });

  final String identity;
  final CanonicalAdapterFailureSource source;
  final CanonicalAdapterFailureSeverity severity;
  final String code;
  final String explanation;
  final String? relatedIdentity;
  final RegistryPath? path;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    source,
    severity,
    code,
    explanation,
    relatedIdentity,
    path,
    sourceEvidence,
  ];
}

void _requireUniqueIdentity(
  Set<String> identities,
  String identity,
  String fieldName,
) {
  if (!identities.add(identity)) {
    throw ArgumentError.value(
      identity,
      fieldName,
      'Canonical analysis identity must be globally unique.',
    );
  }
}

void _validateRegistryEvidence(
  Iterable<SourceEvidence> evidence, {
  required String sourceDocumentPath,
  required String sourceSnapshotFingerprint,
}) {
  for (final SourceEvidence record in evidence) {
    if (record.sourceDocumentPath != sourceDocumentPath ||
        record.sourceSnapshotFingerprint != sourceSnapshotFingerprint) {
      throw ArgumentError.value(
        record,
        'sourceEvidence',
        'Canonical business evidence must belong to the exact Registry '
            'snapshot.',
      );
    }
  }
}

void _validateDictionaryEvidence(
  Iterable<SourceEvidence> evidence, {
  required CanonicalDictionary dictionary,
}) {
  for (final SourceEvidence record in evidence) {
    if (record.sourceDocumentPath != dictionary.sourceDocumentPath ||
        record.sourceSnapshotFingerprint !=
            dictionary.sourceSnapshotFingerprint ||
        record.startLine < dictionary.beginMarkerLine ||
        record.endLine > dictionary.endMarkerLine) {
      throw ArgumentError.value(
        record,
        'sourceEvidence',
        'Dictionary failure evidence must belong to the exact dictionary '
            'snapshot.',
      );
    }
  }
}
