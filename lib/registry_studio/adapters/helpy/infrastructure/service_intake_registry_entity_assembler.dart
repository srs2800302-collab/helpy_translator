import '../../../core/domain/entities/registry_entity.dart';
import '../../../core/domain/evidence/source_evidence.dart';
import 'service_intake_payload_decoder.dart';
import 'service_intake_semantic_manifest_source.dart';
import 'service_intake_source_block_extractor.dart';

final class ServiceIntakeRegistryEntityAssembler {
  const ServiceIntakeRegistryEntityAssembler();

  RegistryEntity assemble({
    required ServiceIntakeSourceBlock sourceBlock,
    required ServiceIntakeSemanticManifestEntry manifestEntry,
    required String sourceDocumentPath,
    required String sourceSnapshotFingerprint,
  }) {
    final payload = const ServiceIntakePayloadDecoder().decode(
      sourceBlock: sourceBlock,
      manifestEntry: manifestEntry,
    );

    final SourceEvidence sourceEvidence = SourceEvidence(
      sourceDocumentPath: sourceDocumentPath,
      sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      headingPath: <String>[
        sourceBlock.identity.ownerHeading,
        sourceBlock.identity.heading,
      ],
      startLine: sourceBlock.startLine,
      endLine: sourceBlock.endLine,
    );

    return RegistryEntity(
      id: sourceBlock.identity.entityId,
      path: sourceBlock.identity.path,
      payload: payload,
      sourceEvidence: <SourceEvidence>[sourceEvidence],
    );
  }
}
