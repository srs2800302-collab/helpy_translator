import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

RegistryEntity registryEntityFixture({required String id}) {
  final RegistrySemanticContractIdentity semanticContract =
      RegistrySemanticContractIdentity(
        contractId: 'sample.semantic_contract',
        version: '1',
      );

  return RegistryEntity(
    id: RegistryEntityId(id),
    path: RegistryPath(<String>['sample_scope', id]),
    kind: RegistryEntityKind(
      semanticContract: semanticContract,
      kindId: 'sample.entity',
      schemaVersion: '1',
    ),
    payload: _FixtureRegistryEntityPayload(
      semanticContract: semanticContract,
      entityKindId: 'sample.entity',
      payloadSchemaVersion: '1',
    ),
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'docs/architecture/Registry_Studio_Source_v1.md',
        sourceSnapshotFingerprint: 'sha256:$id',
        headingPath: <String>['Sample', id],
        startLine: 1,
        endLine: 1,
      ),
    ],
  );
}

final class _FixtureRegistryEntityPayload implements RegistryEntityPayload {
  const _FixtureRegistryEntityPayload({
    required this.semanticContract,
    required this.entityKindId,
    required this.payloadSchemaVersion,
  });

  @override
  final RegistrySemanticContractIdentity semanticContract;

  @override
  final String entityKindId;

  @override
  final String payloadSchemaVersion;
}
