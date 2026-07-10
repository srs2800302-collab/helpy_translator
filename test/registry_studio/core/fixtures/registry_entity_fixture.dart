import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

RegistryEntity registryEntityFixture({required String id}) {
  final RegistrySemanticContractIdentity semanticContract =
      registrySemanticContractFixture();
  final RegistryEntityKind kind = registryEntityKindFixture(
    semanticContract: semanticContract,
  );

  return RegistryEntity(
    id: RegistryEntityId(id),
    path: RegistryPath(<String>['sample_scope', id]),
    payload: registryEntityPayloadFixture(kind: kind),
    sourceEvidence: <SourceEvidence>[
      sourceEvidenceFixture(
        sourceSnapshotFingerprint: 'sha256:$id',
        headingPath: <String>['Sample', id],
      ),
    ],
  );
}

RegistrySemanticContractIdentity registrySemanticContractFixture({
  String contractId = 'sample.semantic_contract',
  String version = '1',
}) {
  return RegistrySemanticContractIdentity(
    contractId: contractId,
    version: version,
  );
}

RegistryEntityKind registryEntityKindFixture({
  required RegistrySemanticContractIdentity semanticContract,
  String kindId = 'sample.entity',
  String schemaVersion = '1',
}) {
  return RegistryEntityKind(
    semanticContract: semanticContract,
    kindId: kindId,
    schemaVersion: schemaVersion,
  );
}

RegistryEntityPayload registryEntityPayloadFixture({
  required RegistryEntityKind kind,
}) {
  return _FixtureRegistryEntityPayload(kind: kind);
}

SourceEvidence sourceEvidenceFixture({
  String sourceDocumentPath = 'docs/architecture/Registry_Studio_Source_v1.md',
  String sourceSnapshotFingerprint = 'sha256:fixture',
  Iterable<String> headingPath = const <String>[
    'Sample Domain',
    'Sample Entity',
  ],
  int startLine = 100,
  int? endLine,
}) {
  return SourceEvidence(
    sourceDocumentPath: sourceDocumentPath,
    sourceSnapshotFingerprint: sourceSnapshotFingerprint,
    headingPath: headingPath,
    startLine: startLine,
    endLine: endLine ?? startLine + 10,
  );
}

final class _FixtureRegistryEntityPayload implements RegistryEntityPayload {
  const _FixtureRegistryEntityPayload({required this.kind});

  @override
  final RegistryEntityKind kind;
}
