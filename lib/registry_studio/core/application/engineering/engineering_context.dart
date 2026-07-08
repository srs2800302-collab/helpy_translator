import 'package:equatable/equatable.dart';

import '../../domain/contracts/registry_entity_payload.dart';
import '../../domain/entities/registry_entity.dart';

final class EngineeringContext extends Equatable {
  const EngineeringContext({required this.targetEntity});

  final RegistryEntity targetEntity;

  RegistryEntityPayload get payload => targetEntity.payload;

  T requirePayload<T extends RegistryEntityPayload>() {
    final RegistryEntityPayload currentPayload = payload;

    if (currentPayload is T) {
      return currentPayload;
    }

    throw ArgumentError('EngineeringContext target entity payload must be $T.');
  }

  @override
  List<Object?> get props => <Object?>[targetEntity];
}
