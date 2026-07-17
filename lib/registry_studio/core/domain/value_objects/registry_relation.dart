import 'package:equatable/equatable.dart';

import 'registry_entity_id.dart';
import 'registry_relation_meaning.dart';

final class RegistryRelation extends Equatable {
  factory RegistryRelation({
    required RegistryEntityId sourceEntityId,
    required RegistryEntityId targetEntityId,
    required RegistryRelationMeaning meaning,
  }) {
    if (sourceEntityId == targetEntityId) {
      throw ArgumentError(
        'Registry relation target entity must differ from source entity.',
      );
    }

    return RegistryRelation._(
      sourceEntityId: sourceEntityId,
      targetEntityId: targetEntityId,
      meaning: meaning,
    );
  }

  const RegistryRelation._({
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.meaning,
  });

  final RegistryEntityId sourceEntityId;
  final RegistryEntityId targetEntityId;
  final RegistryRelationMeaning meaning;

  @override
  List<Object> get props => <Object>[sourceEntityId, targetEntityId, meaning];
}
