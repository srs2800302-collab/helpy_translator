import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/contracts/registry_entity_payload.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('RegistrySnapshot semantic content', () {
    test('preserves immutable entities and relations', () {
      final RegistrySemanticContractIdentity semanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'project.registry.semantic',
            version: '1',
          );
      final RegistryEntityKind kind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'project.entity',
        schemaVersion: '1',
      );

      final RegistryPath rootPath = RegistryPath(const <String>['Registry']);
      final RegistryPath childPath = RegistryPath(const <String>[
        'Registry',
        'Child',
      ]);

      const String fingerprint =
          'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      final SourceEvidence rootEvidence = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: fingerprint,
        headingPath: rootPath.segments,
        startLine: 1,
        endLine: 2,
      );
      final SourceEvidence childEvidence = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: fingerprint,
        headingPath: childPath.segments,
        startLine: 3,
        endLine: 4,
      );

      final RegistryNode child = RegistryNode(
        id: RegistryNodeId('project.node.child'),
        kindId: 'project.heading.2',
        path: childPath,
        sourceEvidence: <SourceEvidence>[childEvidence],
        content: 'Child content.',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );
      final RegistryNode root = RegistryNode(
        id: RegistryNodeId('project.node.root'),
        kindId: 'project.heading.1',
        path: rootPath,
        sourceEvidence: <SourceEvidence>[rootEvidence],
        content: 'Root content.',
        businessScopeOwnerId: null,
        children: <RegistryNode>[child],
      );

      final RegistryEntity rootEntity = RegistryEntity(
        id: RegistryEntityId('project.entity.root'),
        path: rootPath,
        kind: kind,
        payload: _FixturePayload(
          semanticContract: semanticContract,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[rootEvidence],
      );
      final RegistryEntity childEntity = RegistryEntity(
        id: RegistryEntityId('project.entity.child'),
        path: childPath,
        kind: kind,
        payload: _FixturePayload(
          semanticContract: semanticContract,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[childEvidence],
      );
      final RegistryRelation relation = RegistryRelation(
        sourceEntityId: rootEntity.id,
        targetEntityId: childEntity.id,
        meaning: RegistryRelationMeaning('contains'),
      );

      final RegistrySnapshot snapshot = RegistrySnapshot(
        projectId: 'project',
        projectAdapterId: 'project.adapter.v1',
        sourceDocumentPath: 'registry.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: fingerprint,
        sourceContent: '# Registry\n\n## Child',
        roots: <RegistryNode>[root],
        entities: <RegistryEntity>[rootEntity, childEntity],
        relations: <RegistryRelation>[relation],
      );

      expect(snapshot.entities, <RegistryEntity>[rootEntity, childEntity]);
      expect(snapshot.relations, <RegistryRelation>[relation]);
      expect(() => snapshot.entities.clear(), throwsUnsupportedError);
      expect(() => snapshot.relations.clear(), throwsUnsupportedError);
    });

    test('rejects semantic entity paths outside structural snapshot', () {
      final RegistrySemanticContractIdentity semanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'project.registry.semantic',
            version: '1',
          );
      final RegistryEntityKind kind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'project.entity',
        schemaVersion: '1',
      );
      final RegistryPath rootPath = RegistryPath(const <String>['Registry']);

      const String fingerprint =
          'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      final SourceEvidence evidence = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: fingerprint,
        headingPath: rootPath.segments,
        startLine: 1,
        endLine: 1,
      );
      final RegistryNode root = RegistryNode(
        id: RegistryNodeId('project.node.root'),
        kindId: 'project.heading.1',
        path: rootPath,
        sourceEvidence: <SourceEvidence>[evidence],
        content: '',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );
      final RegistryEntity entity = RegistryEntity(
        id: RegistryEntityId('project.entity.missing'),
        path: RegistryPath(const <String>['Missing']),
        kind: kind,
        payload: _FixturePayload(
          semanticContract: semanticContract,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[evidence],
      );

      expect(
        () => RegistrySnapshot(
          projectId: 'project',
          projectAdapterId: 'project.adapter.v1',
          sourceDocumentPath: 'registry.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: fingerprint,
          sourceContent: '# Registry',
          roots: <RegistryNode>[root],
          entities: <RegistryEntity>[entity],
        ),
        throwsArgumentError,
      );
    });

    test('rejects relations with absent semantic endpoints', () {
      final RegistrySemanticContractIdentity semanticContract =
          RegistrySemanticContractIdentity(
            contractId: 'project.registry.semantic',
            version: '1',
          );
      final RegistryEntityKind kind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'project.entity',
        schemaVersion: '1',
      );
      final RegistryPath rootPath = RegistryPath(const <String>['Registry']);

      const String fingerprint =
          'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      final SourceEvidence evidence = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: fingerprint,
        headingPath: rootPath.segments,
        startLine: 1,
        endLine: 1,
      );
      final RegistryNode root = RegistryNode(
        id: RegistryNodeId('project.node.root'),
        kindId: 'project.heading.1',
        path: rootPath,
        sourceEvidence: <SourceEvidence>[evidence],
        content: '',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );
      final RegistryEntity entity = RegistryEntity(
        id: RegistryEntityId('project.entity.root'),
        path: rootPath,
        kind: kind,
        payload: _FixturePayload(
          semanticContract: semanticContract,
          entityKindId: kind.kindId,
          payloadSchemaVersion: kind.schemaVersion,
        ),
        sourceEvidence: <SourceEvidence>[evidence],
      );
      final RegistryRelation invalidRelation = RegistryRelation(
        sourceEntityId: entity.id,
        targetEntityId: RegistryEntityId('project.entity.absent'),
        meaning: RegistryRelationMeaning('references'),
      );

      expect(
        () => RegistrySnapshot(
          projectId: 'project',
          projectAdapterId: 'project.adapter.v1',
          sourceDocumentPath: 'registry.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: fingerprint,
          sourceContent: '# Registry',
          roots: <RegistryNode>[root],
          entities: <RegistryEntity>[entity],
          relations: <RegistryRelation>[invalidRelation],
        ),
        throwsArgumentError,
      );
    });
  });
}

final class _FixturePayload implements RegistryEntityPayload {
  const _FixturePayload({
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
