import '../../../../core/domain/contracts/registry_entity_payload.dart';
import '../../../../core/domain/value_objects/registry_semantic_contract_identity.dart';

final class HelpyBusinessScopeOwnerPayload implements RegistryEntityPayload {
  factory HelpyBusinessScopeOwnerPayload({
    required RegistrySemanticContractIdentity semanticContract,
    required String entityKindId,
    required String payloadSchemaVersion,
    required String ownerClassId,
    required String title,
  }) {
    final String normalizedEntityKindId = entityKindId.trim();
    final String normalizedPayloadSchemaVersion = payloadSchemaVersion.trim();
    final String normalizedOwnerClassId = ownerClassId.trim();
    final String normalizedTitle = title.trim();

    if (normalizedEntityKindId.isEmpty) {
      throw ArgumentError.value(
        entityKindId,
        'entityKindId',
        'Helpy business-scope owner kind must not be empty.',
      );
    }

    if (normalizedPayloadSchemaVersion.isEmpty) {
      throw ArgumentError.value(
        payloadSchemaVersion,
        'payloadSchemaVersion',
        'Helpy business-scope payload schema version '
            'must not be empty.',
      );
    }

    if (normalizedOwnerClassId.isEmpty) {
      throw ArgumentError.value(
        ownerClassId,
        'ownerClassId',
        'Helpy business-scope owner class must not be empty.',
      );
    }

    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Helpy business-scope owner title must not be empty.',
      );
    }

    return HelpyBusinessScopeOwnerPayload._(
      semanticContract: semanticContract,
      entityKindId: normalizedEntityKindId,
      payloadSchemaVersion: normalizedPayloadSchemaVersion,
      ownerClassId: normalizedOwnerClassId,
      title: normalizedTitle,
    );
  }

  const HelpyBusinessScopeOwnerPayload._({
    required this.semanticContract,
    required this.entityKindId,
    required this.payloadSchemaVersion,
    required this.ownerClassId,
    required this.title,
  });

  @override
  final RegistrySemanticContractIdentity semanticContract;

  @override
  final String entityKindId;

  @override
  final String payloadSchemaVersion;

  final String ownerClassId;
  final String title;
}
