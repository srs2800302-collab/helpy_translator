import 'package:equatable/equatable.dart';

import '../contracts/registry_entity_payload.dart';
import '../evidence/source_evidence.dart';
import '../value_objects/registry_entity_id.dart';
import '../value_objects/registry_entity_kind.dart';
import '../value_objects/registry_path.dart';

final class RegistryEntity extends Equatable {
  factory RegistryEntity({
    required RegistryEntityId id,
    required RegistryPath path,
    required RegistryEntityKind kind,
    required RegistryEntityPayload payload,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final List<SourceEvidence> normalizedSourceEvidence = sourceEvidence
        .toList(growable: false);

    if (normalizedSourceEvidence.isEmpty) {
      throw ArgumentError.value(
        sourceEvidence,
        'sourceEvidence',
        'Registry entity must contain at least one source evidence item.',
      );
    }

    if (payload.semanticContract != kind.semanticContract) {
      throw ArgumentError(
        'Registry entity payload semantic contract must match entity kind.',
      );
    }

    if (payload.entityKindId != kind.kindId) {
      throw ArgumentError(
        'Registry entity payload kind must match entity primary kind.',
      );
    }

    if (payload.payloadSchemaVersion != kind.schemaVersion) {
      throw ArgumentError(
        'Registry entity payload schema version must match entity kind.',
      );
    }

    return RegistryEntity._(
      id: id,
      path: path,
      kind: kind,
      payload: payload,
      sourceEvidence: List<SourceEvidence>.unmodifiable(
        normalizedSourceEvidence,
      ),
    );
  }

  const RegistryEntity._({
    required this.id,
    required this.path,
    required this.kind,
    required this.payload,
    required this.sourceEvidence,
  });

  final RegistryEntityId id;
  final RegistryPath path;
  final RegistryEntityKind kind;
  final RegistryEntityPayload payload;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[id];
}
