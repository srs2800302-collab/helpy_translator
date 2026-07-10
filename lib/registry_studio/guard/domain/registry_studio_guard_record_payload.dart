import 'package:equatable/equatable.dart';

import '../../core/domain/contracts/registry_entity_payload.dart';
import '../../core/domain/value_objects/registry_semantic_contract_identity.dart';

enum RegistryStudioGuardRecordType {
  decision,
  ownershipAudit,
  checkpoint,
  restriction,
}

final class RegistryStudioGuardRecordPayload extends Equatable
    implements RegistryEntityPayload {
  factory RegistryStudioGuardRecordPayload({
    required RegistryStudioGuardRecordType recordType,
    required String heading,
    required String summary,
  }) {
    final String normalizedHeading = heading.trim();
    final String normalizedSummary = summary.trim();

    if (normalizedHeading.isEmpty) {
      throw ArgumentError.value(
        heading,
        'heading',
        'Registry Studio Guard record heading must not be empty.',
      );
    }

    if (normalizedSummary.isEmpty) {
      throw ArgumentError.value(
        summary,
        'summary',
        'Registry Studio Guard record summary must not be empty.',
      );
    }

    return RegistryStudioGuardRecordPayload._(
      recordType: recordType,
      heading: normalizedHeading,
      summary: normalizedSummary,
    );
  }

  const RegistryStudioGuardRecordPayload._({
    required this.recordType,
    required this.heading,
    required this.summary,
  });

  static final RegistrySemanticContractIdentity semanticContractIdentity =
      RegistrySemanticContractIdentity(
        contractId: 'registry_studio.guard_record',
        version: '1',
      );

  static const String entityKindIdentifier = 'registry_studio.guard_record';

  static const String schemaVersion = '1';

  final RegistryStudioGuardRecordType recordType;

  final String heading;

  final String summary;

  @override
  RegistrySemanticContractIdentity get semanticContract =>
      semanticContractIdentity;

  @override
  String get entityKindId => entityKindIdentifier;

  @override
  String get payloadSchemaVersion => schemaVersion;

  @override
  List<Object?> get props => <Object?>[
    semanticContract,
    entityKindId,
    payloadSchemaVersion,
    recordType,
    heading,
    summary,
  ];
}
