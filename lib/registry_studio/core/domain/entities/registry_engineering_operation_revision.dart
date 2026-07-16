import 'package:equatable/equatable.dart';

import '../value_objects/registry_engineering_operation_id.dart';
import '../value_objects/registry_entity_id.dart';

final class RegistryEngineeringOperationRevision extends Equatable {
  factory RegistryEngineeringOperationRevision({
    required String id,
    required RegistryEngineeringOperationId operationId,
    required int revisionNumber,
    required String workingContent,
    String? originalValue,
    String? proposedValue,
    required String? previousRevisionId,
    required RegistryEntityId primaryEntityId,
    required Iterable<RegistryEntityId> relatedEntityIds,
  }) {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'Registry engineering operation revision identity must not be empty.',
      );
    }

    if (revisionNumber < 1) {
      throw ArgumentError.value(
        revisionNumber,
        'revisionNumber',
        'Registry engineering operation revision number must be at least 1.',
      );
    }

    final String? normalizedPreviousRevisionId = previousRevisionId?.trim();

    if (normalizedPreviousRevisionId != null &&
        normalizedPreviousRevisionId.isEmpty) {
      throw ArgumentError.value(
        previousRevisionId,
        'previousRevisionId',
        'Previous revision identity must not be empty.',
      );
    }

    if (revisionNumber == 1 && normalizedPreviousRevisionId != null) {
      throw ArgumentError(
        'First registry engineering operation revision must not have '
        'a previous revision.',
      );
    }

    if (revisionNumber > 1 && normalizedPreviousRevisionId == null) {
      throw ArgumentError(
        'Registry engineering operation revision after the first must have '
        'a previous revision.',
      );
    }

    final String normalizedWorkingContent = workingContent.trim();
    final String normalizedOriginalValue =
        originalValue?.trim() ?? normalizedWorkingContent;
    final String normalizedProposedValue =
        proposedValue?.trim() ?? normalizedWorkingContent;

    if (normalizedWorkingContent.isEmpty) {
      throw ArgumentError.value(
        workingContent,
        'workingContent',
        'Registry engineering operation revision working content '
            'must not be empty.',
      );
    }

    if (normalizedOriginalValue.isEmpty) {
      throw ArgumentError.value(
        originalValue,
        'originalValue',
        'Registry engineering operation revision original value '
            'must not be empty.',
      );
    }

    if (normalizedProposedValue.isEmpty) {
      throw ArgumentError.value(
        proposedValue,
        'proposedValue',
        'Registry engineering operation revision proposed value '
            'must not be empty.',
      );
    }

    final List<RegistryEntityId> normalizedRelatedEntityIds = relatedEntityIds
        .toList(growable: false);

    if (normalizedRelatedEntityIds.toSet().length !=
        normalizedRelatedEntityIds.length) {
      throw ArgumentError(
        'Registry engineering operation revision related entity ids '
        'must be unique.',
      );
    }

    if (normalizedRelatedEntityIds.contains(primaryEntityId)) {
      throw ArgumentError(
        'Registry engineering operation revision related entity ids '
        'must not contain the primary entity id.',
      );
    }

    return RegistryEngineeringOperationRevision._(
      id: normalizedId,
      operationId: operationId,
      revisionNumber: revisionNumber,
      workingContent: normalizedWorkingContent,
      originalValue: normalizedOriginalValue,
      proposedValue: normalizedProposedValue,
      previousRevisionId: normalizedPreviousRevisionId,
      primaryEntityId: primaryEntityId,
      relatedEntityIds: List<RegistryEntityId>.unmodifiable(
        normalizedRelatedEntityIds,
      ),
    );
  }

  const RegistryEngineeringOperationRevision._({
    required this.id,
    required this.operationId,
    required this.revisionNumber,
    required this.workingContent,
    required this.originalValue,
    required this.proposedValue,
    required this.previousRevisionId,
    required this.primaryEntityId,
    required this.relatedEntityIds,
  });

  final String id;
  final RegistryEngineeringOperationId operationId;
  final int revisionNumber;
  final String workingContent;
  final String originalValue;
  final String proposedValue;
  final String? previousRevisionId;
  final RegistryEntityId primaryEntityId;
  final List<RegistryEntityId> relatedEntityIds;

  @override
  List<Object?> get props => <Object?>[id];
}
