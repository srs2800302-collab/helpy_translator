import '../../core/domain/entities/registry_entity.dart';
import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_entity_id.dart';
import '../../core/domain/value_objects/registry_entity_kind.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../domain/registry_studio_guard_record_payload.dart';

final class CreateRegistryStudioGuardRecordEntity {
  RegistryEntity call({
    required String id,
    required Iterable<String> pathSegments,
    required RegistryStudioGuardRecordType recordType,
    required String heading,
    required String summary,
    required String sourceDocumentPath,
    required String sourceSnapshotFingerprint,
    required Iterable<String> sourceHeadingPath,
    required int sourceStartLine,
    required int sourceEndLine,
  }) {
    final RegistryStudioGuardRecordPayload payload =
        RegistryStudioGuardRecordPayload(
          recordType: recordType,
          heading: heading,
          summary: summary,
        );

    return RegistryEntity(
      id: RegistryEntityId(id),
      path: RegistryPath(pathSegments),
      kind: RegistryEntityKind(
        semanticContract:
            RegistryStudioGuardRecordPayload.semanticContractIdentity,
        kindId: RegistryStudioGuardRecordPayload.entityKindIdentifier,
        schemaVersion: RegistryStudioGuardRecordPayload.schemaVersion,
      ),
      payload: payload,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: sourceDocumentPath,
          sourceSnapshotFingerprint: sourceSnapshotFingerprint,
          headingPath: sourceHeadingPath,
          startLine: sourceStartLine,
          endLine: sourceEndLine,
        ),
      ],
    );
  }
}
