import 'package:flutter/services.dart';

import '../../../core/domain/entities/registry_entity.dart';
import '../../../core/domain/value_objects/registry_entity_id.dart';
import 'github_registry_document_source.dart';
import 'service_intake_identity_manifest_source.dart';
import 'service_intake_registry_entity_assembler.dart';
import 'service_intake_semantic_manifest_source.dart';
import 'service_intake_source_block_extractor.dart';

final class ServiceIntakeRegistrySourceResult {
  const ServiceIntakeRegistrySourceResult({
    required this.sourceBlocks,
    required this.entities,
    required this.sourceDocumentPath,
    required this.sourceRevision,
    required this.sourceSnapshotFingerprint,
  });

  final List<ServiceIntakeSourceBlock> sourceBlocks;
  final List<RegistryEntity> entities;
  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
}

final class ServiceIntakeRegistrySource {
  const ServiceIntakeRegistrySource({
    required this.documentSource,
    required this.assetBundle,
    this.identityManifestAssetPath =
        ServiceIntakeIdentityManifestSource.defaultAssetPath,
    this.semanticManifestAssetPath =
        ServiceIntakeSemanticManifestSource.defaultAssetPath,
  });

  final GitHubRegistryDocumentSource documentSource;
  final AssetBundle assetBundle;
  final String identityManifestAssetPath;
  final String semanticManifestAssetPath;

  Future<ServiceIntakeRegistrySourceResult> load() async {
    final List<ServiceIntakeIdentityManifestEntry> identities =
        await ServiceIntakeIdentityManifestSource(
          assetBundle: assetBundle,
          assetPath: identityManifestAssetPath,
        ).load();

    final GitHubRegistryDocumentSourceResult document = await documentSource
        .load();

    final List<ServiceIntakeSourceBlock> sourceBlocks =
        const ServiceIntakeSourceBlockExtractor().extract(
          source: document.content,
          identities: identities,
        );

    final List<ServiceIntakeSemanticManifestEntry> semanticEntries =
        await ServiceIntakeSemanticManifestSource(
          assetBundle: assetBundle,
          assetPath: semanticManifestAssetPath,
          expectedEntityIds: identities.map(
            (ServiceIntakeIdentityManifestEntry entry) => entry.entityId,
          ),
        ).load();

    final Map<RegistryEntityId, ServiceIntakeSemanticManifestEntry>
    semanticEntriesByEntityId =
        <RegistryEntityId, ServiceIntakeSemanticManifestEntry>{
          for (final ServiceIntakeSemanticManifestEntry entry
              in semanticEntries)
            entry.entityId: entry,
        };

    final List<RegistryEntity> entities = <RegistryEntity>[
      for (final ServiceIntakeSourceBlock sourceBlock in sourceBlocks)
        const ServiceIntakeRegistryEntityAssembler().assemble(
          sourceBlock: sourceBlock,
          manifestEntry:
              semanticEntriesByEntityId[sourceBlock.identity.entityId]!,
          sourceDocumentPath: document.documentPath,
          sourceSnapshotFingerprint: document.sourceSnapshotFingerprint,
        ),
    ];

    return ServiceIntakeRegistrySourceResult(
      sourceBlocks: List<ServiceIntakeSourceBlock>.unmodifiable(sourceBlocks),
      entities: List<RegistryEntity>.unmodifiable(entities),
      sourceDocumentPath: document.documentPath,
      sourceRevision: document.sourceRevision,
      sourceSnapshotFingerprint: document.sourceSnapshotFingerprint,
    );
  }
}
