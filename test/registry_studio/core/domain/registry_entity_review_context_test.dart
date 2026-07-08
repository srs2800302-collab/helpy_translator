import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/review/registry_entity_review_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_adapter_contract_identity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('RegistryEntityReviewContext', () {
    test(
      'preserves entity and source evidence as read-only review context',
      () {
        final RegistryEntity entity = _entity();
        final SourceEvidence evidence = _evidence();

        final RegistryEntityReviewContext context = RegistryEntityReviewContext(
          entity: entity,
          evidence: <SourceEvidence>[evidence],
        );

        expect(context.entity, entity);
        expect(context.evidence, <SourceEvidence>[evidence]);
        expect(() => context.evidence.add(evidence), throwsUnsupportedError);
      },
    );

    test('rejects review context without source evidence', () {
      expect(
        () => RegistryEntityReviewContext(
          entity: _entity(),
          evidence: const <SourceEvidence>[],
        ),
        throwsArgumentError,
      );
    });

    test('uses full review slice instead of registry entity identity only', () {
      final RegistryEntityId id = RegistryEntityId('registry-entity-001');
      final RegistryEntity first = _entity(
        id: id,
        path: RegistryPath(<String>['registry', 'plumbing', 'faucet']),
        payloadLabel: 'first',
      );
      final RegistryEntity second = _entity(
        id: id,
        path: RegistryPath(<String>['registry', 'plumbing', 'kitchen_faucet']),
        payloadLabel: 'second',
      );
      final SourceEvidence evidence = _evidence();

      expect(first, second);
      expect(
        RegistryEntityReviewContext(
          entity: first,
          evidence: <SourceEvidence>[evidence],
        ),
        isNot(
          RegistryEntityReviewContext(
            entity: second,
            evidence: <SourceEvidence>[evidence],
          ),
        ),
      );
    });
  });
}

RegistryEntity _entity({
  RegistryEntityId? id,
  RegistryPath? path,
  String payloadLabel = 'default',
}) {
  final RegistryAdapterContractIdentity adapter =
      RegistryAdapterContractIdentity(
        adapterId: 'registry_adapter',
        semanticContractVersion: '1',
      );
  final RegistryEntityKind kind = RegistryEntityKind(
    adapterContract: adapter,
    kindId: 'registry.service_intake',
    schemaVersion: '1',
  );

  return RegistryEntity(
    id: id ?? RegistryEntityId('registry-entity-001'),
    path: path ?? RegistryPath(<String>['registry', 'plumbing', 'faucet']),
    kind: kind,
    payload: _TestPayload(
      adapterContract: adapter,
      entityKindId: kind.kindId,
      payloadSchemaVersion: kind.schemaVersion,
      payloadLabel: payloadLabel,
    ),
  );
}

SourceEvidence _evidence() {
  return SourceEvidence(
    sourceDocumentPath: 'docs/architecture/registry.md',
    sourceSnapshotFingerprint: 'sha256:source',
    headingPath: <String>['Registry', 'Plumbing', 'Faucet'],
    startLine: 10,
    endLine: 20,
  );
}

final class _TestPayload extends Equatable implements RegistryEntityPayload {
  const _TestPayload({
    required this.adapterContract,
    required this.entityKindId,
    required this.payloadSchemaVersion,
    required this.payloadLabel,
  });

  @override
  final RegistryAdapterContractIdentity adapterContract;

  @override
  final String entityKindId;

  @override
  final String payloadSchemaVersion;

  final String payloadLabel;

  @override
  List<Object?> get props => <Object?>[
    adapterContract,
    entityKindId,
    payloadSchemaVersion,
    payloadLabel,
  ];
}
