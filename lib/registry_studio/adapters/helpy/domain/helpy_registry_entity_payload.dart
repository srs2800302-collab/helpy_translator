import '../../../core/domain/contracts/registry_entity_payload.dart';
import '../../../core/domain/value_objects/registry_entity_kind.dart';
import '../../../core/domain/value_objects/registry_semantic_contract_identity.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import 'helpy_registry_semantic_contract.dart';

sealed class HelpyRegistryEntityPayload implements RegistryEntityPayload {
  factory HelpyRegistryEntityPayload({
    required RegistryEntityKind kind,
    required RegistryNodeId sourceNodeId,
    required String title,
    required String content,
    required bool ownsBusinessScope,
  }) {
    final String normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Helpy Registry entity payload title must not be empty.',
      );
    }

    if (kind.semanticContract != HelpyRegistrySemanticContract.identity ||
        HelpyRegistrySemanticContract.kindsById[kind.kindId] != kind) {
      throw ArgumentError.value(
        kind,
        'kind',
        'Helpy Registry entity payload must use an approved Helpy kind.',
      );
    }

    switch (kind.kindId) {
      case 'contract':
        return HelpyRegistryContractPayload._(
          kind: kind,
          sourceNodeId: sourceNodeId,
          title: normalizedTitle,
          content: content,
          ownsBusinessScope: ownsBusinessScope,
        );
      case 'architectureGroup':
        return HelpyRegistryArchitectureGroupPayload._(
          kind: kind,
          sourceNodeId: sourceNodeId,
          title: normalizedTitle,
          content: content,
          ownsBusinessScope: ownsBusinessScope,
        );
      case 'platformRule':
        return HelpyRegistryPlatformRulePayload._(
          kind: kind,
          sourceNodeId: sourceNodeId,
          title: normalizedTitle,
          content: content,
          ownsBusinessScope: ownsBusinessScope,
        );
      case 'rootCategory':
        return HelpyRegistryRootCategoryPayload._(
          kind: kind,
          sourceNodeId: sourceNodeId,
          title: normalizedTitle,
          content: content,
          ownsBusinessScope: ownsBusinessScope,
        );
      default:
        throw UnsupportedError(
          'Helpy Registry entity payload schema is not implemented for '
          '${kind.kindId}.',
        );
    }
  }

  const HelpyRegistryEntityPayload._({
    required this.kind,
    required this.sourceNodeId,
    required this.title,
    required this.content,
    required this.ownsBusinessScope,
  });

  final RegistryEntityKind kind;
  final RegistryNodeId sourceNodeId;
  final String title;
  final String content;
  final bool ownsBusinessScope;

  @override
  RegistrySemanticContractIdentity get semanticContract =>
      kind.semanticContract;

  @override
  String get entityKindId => kind.kindId;

  @override
  String get payloadSchemaVersion => kind.schemaVersion;
}

final class HelpyRegistryContractPayload extends HelpyRegistryEntityPayload {
  const HelpyRegistryContractPayload._({
    required super.kind,
    required super.sourceNodeId,
    required super.title,
    required super.content,
    required super.ownsBusinessScope,
  }) : super._();
}

final class HelpyRegistryArchitectureGroupPayload
    extends HelpyRegistryEntityPayload {
  const HelpyRegistryArchitectureGroupPayload._({
    required super.kind,
    required super.sourceNodeId,
    required super.title,
    required super.content,
    required super.ownsBusinessScope,
  }) : super._();
}

final class HelpyRegistryPlatformRulePayload
    extends HelpyRegistryEntityPayload {
  const HelpyRegistryPlatformRulePayload._({
    required super.kind,
    required super.sourceNodeId,
    required super.title,
    required super.content,
    required super.ownsBusinessScope,
  }) : super._();
}

final class HelpyRegistryRootCategoryPayload
    extends HelpyRegistryEntityPayload {
  const HelpyRegistryRootCategoryPayload._({
    required super.kind,
    required super.sourceNodeId,
    required super.title,
    required super.content,
    required super.ownsBusinessScope,
  }) : super._();
}
