import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_adapter_contract_identity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('EngineeringContext', () {
    test(
      'exposes target RegistryEntity payload as read-only typed context',
      () {
        final RegistryAdapterContractIdentity adapter =
            RegistryAdapterContractIdentity(
              adapterId: 'helpy',
              semanticContractVersion: '1',
            );
        final _TestPayload payload = _TestPayload(
          adapterContract: adapter,
          entityKindId: 'helpy.service_intake',
          payloadSchemaVersion: '1',
        );
        final RegistryEntity entity = RegistryEntity(
          id: RegistryEntityId('registry-entity-001'),
          path: RegistryPath(<String>['helpy', 'plumbing', 'faucet']),
          kind: RegistryEntityKind(
            adapterContract: adapter,
            kindId: 'helpy.service_intake',
            schemaVersion: '1',
          ),
          payload: payload,
        );

        final EngineeringContext context = EngineeringContext(
          targetEntity: entity,
        );

        expect(context.targetEntity, entity);
        expect(context.payload, payload);
        expect(context.requirePayload<_TestPayload>(), payload);
      },
    );

    test('rejects an unexpected payload type', () {
      final RegistryAdapterContractIdentity adapter =
          RegistryAdapterContractIdentity(
            adapterId: 'helpy',
            semanticContractVersion: '1',
          );
      final RegistryEntity entity = RegistryEntity(
        id: RegistryEntityId('registry-entity-001'),
        path: RegistryPath(<String>['helpy', 'plumbing', 'faucet']),
        kind: RegistryEntityKind(
          adapterContract: adapter,
          kindId: 'helpy.service_intake',
          schemaVersion: '1',
        ),
        payload: _TestPayload(
          adapterContract: adapter,
          entityKindId: 'helpy.service_intake',
          payloadSchemaVersion: '1',
        ),
      );

      final EngineeringContext context = EngineeringContext(
        targetEntity: entity,
      );

      expect(context.requirePayload<_AnotherPayload>, throwsArgumentError);
    });
  });
}

final class _TestPayload implements RegistryEntityPayload {
  const _TestPayload({
    required this.adapterContract,
    required this.entityKindId,
    required this.payloadSchemaVersion,
  });

  @override
  final RegistryAdapterContractIdentity adapterContract;

  @override
  final String entityKindId;

  @override
  final String payloadSchemaVersion;
}

final class _AnotherPayload implements RegistryEntityPayload {
  const _AnotherPayload();

  @override
  RegistryAdapterContractIdentity get adapterContract =>
      RegistryAdapterContractIdentity(
        adapterId: 'helpy',
        semanticContractVersion: '1',
      );

  @override
  String get entityKindId => 'helpy.service_intake';

  @override
  String get payloadSchemaVersion => '1';
}
