import '../../../core/domain/entities/registry_entity.dart';
import '../../../core/domain/evidence/source_evidence.dart';
import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/application/contracts/registry_snapshot_loader.dart';
import '../../../registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import '../domain/helpy_registry_semantic_contract.dart';
import '../domain/helpy_registry_semantic_identity_overlay.dart';
import 'github_registry_document_source.dart';
import 'helpy_registry_document_interpreter.dart';
import 'helpy_registry_node_identity_ledger_source.dart';

final class HelpyRegistryMissingNodeIdentityException implements Exception {
  HelpyRegistryMissingNodeIdentityException({
    required this.sourceDocumentPath,
    required this.sourceRevision,
    required this.sourceSnapshotFingerprint,
    required List<RegistryPath> missingPaths,
    required this.maximumAssignedSequence,
  }) : missingPaths = List<RegistryPath>.unmodifiable(missingPaths);

  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
  final List<RegistryPath> missingPaths;
  final int maximumAssignedSequence;

  @override
  String toString() {
    final String paths = missingPaths
        .map((RegistryPath path) => path.segments.join(' → '))
        .join('; ');

    return 'Helpy Registry identity evidence is incomplete for '
        'revision $sourceRevision. Missing paths: $paths.';
  }
}

final class HelpyRegistrySnapshotLoader
    implements RegistrySnapshotLoader, RegistrySnapshotRevisionLoader {
  const HelpyRegistrySnapshotLoader({
    required this.documentSource,
    required this.identityLedgerSource,
    this.documentInterpreter = const HelpyRegistryDocumentInterpreter(),
  });

  static const String projectId = 'helpy';
  static const String projectAdapterId =
      HelpyRegistrySemanticContract.adapterId;

  final GitHubRegistryDocumentSource documentSource;
  final HelpyRegistryNodeIdentityLedgerSource identityLedgerSource;
  final HelpyRegistryDocumentInterpreter documentInterpreter;

  @override
  Future<RegistrySnapshot> loadSnapshot() {
    return _loadSnapshot();
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAtRevision(String sourceRevision) {
    return _loadSnapshot(exactRevision: sourceRevision);
  }

  Future<RegistrySnapshot> _loadSnapshot({String? exactRevision}) async {
    final GitHubRegistryDocumentSource identityLedgerDocumentSource =
        identityLedgerSource.documentSource;

    if (documentSource.owner.toLowerCase() !=
            identityLedgerDocumentSource.owner.toLowerCase() ||
        documentSource.repository.toLowerCase() !=
            identityLedgerDocumentSource.repository.toLowerCase() ||
        documentSource.apiBaseUri != identityLedgerDocumentSource.apiBaseUri) {
      throw StateError(
        'Helpy Registry document and identity ledger must use '
        'the same GitHub repository source.',
      );
    }

    final sourceDocument = await documentSource.load(
      exactRevision: exactRevision,
    );

    if (sourceDocument.documentPath !=
        HelpyRegistryNodeIdentityLedgerSource.registryDocumentPath) {
      throw FormatException(
        'Helpy Registry source document path does not match the '
        'structural identity ledger: ${sourceDocument.documentPath}.',
      );
    }

    final HelpyRegistryNodeIdentityLedger identityLedger =
        await identityLedgerSource.load(
          exactRevision: sourceDocument.sourceRevision,
        );

    final Map<RegistryPath, RegistryNodeId> identitiesByPath =
        identityLedger.identitiesByPath;

    final List<HelpyRegistryDocumentNode> interpretedRoots = documentInterpreter
        .interpret(sourceDocument.content);

    final List<HelpyRegistryDocumentNode> interpretedNodes =
        <HelpyRegistryDocumentNode>[];

    final List<HelpyRegistryDocumentNode> remainingNodes =
        <HelpyRegistryDocumentNode>[...interpretedRoots.reversed];

    while (remainingNodes.isNotEmpty) {
      final HelpyRegistryDocumentNode node = remainingNodes.removeLast();

      interpretedNodes.add(node);

      for (final HelpyRegistryDocumentNode child in node.children.reversed) {
        remainingNodes.add(child);
      }
    }

    final List<RegistryPath> missingIdentityPaths = <RegistryPath>[
      for (final HelpyRegistryDocumentNode interpretedNode in interpretedNodes)
        if (!identitiesByPath.containsKey(interpretedNode.path))
          interpretedNode.path,
    ];

    if (missingIdentityPaths.isNotEmpty) {
      throw HelpyRegistryMissingNodeIdentityException(
        sourceDocumentPath: sourceDocument.documentPath,
        sourceRevision: sourceDocument.sourceRevision,
        sourceSnapshotFingerprint: sourceDocument.sourceSnapshotFingerprint,
        missingPaths: missingIdentityPaths,
        maximumAssignedSequence: identityLedger.maximumAssignedSequence,
      );
    }

    final HelpyRegistrySemanticIdentityOverlay semanticIdentityOverlay =
        HelpyRegistrySemanticIdentityOverlay.v1;

    final Map<RegistryNodeId, RegistryPath> activePathsByNodeId =
        <RegistryNodeId, RegistryPath>{
          for (final HelpyRegistryDocumentNode interpretedNode
              in interpretedNodes)
            identitiesByPath[interpretedNode.path]!: interpretedNode.path,
        };

    final Set<RegistryNodeId> activeNodeIds = activePathsByNodeId.keys.toSet();

    final bool semanticIdentityOverlayApplies = semanticIdentityOverlay
        .appliesTo(
          sourceDocumentPath: sourceDocument.documentPath,
          sourceRevision: sourceDocument.sourceRevision,
        );

    if (semanticIdentityOverlayApplies) {
      semanticIdentityOverlay.validateActiveEvidencePaths(
        activePathsByNodeId: activePathsByNodeId,
      );
    }

    final Map<RegistryNodeId, RegistryEntityId?> businessScopeOwnerIdsByNodeId =
        semanticIdentityOverlayApplies
        ? semanticIdentityOverlay.resolveBusinessScopeOwnerIds(
            activeNodeIds: activeNodeIds,
            parentIdByNodeId: identityLedger.parentIdByNodeId,
          )
        : Map<RegistryNodeId, RegistryEntityId?>.unmodifiable(
            <RegistryNodeId, RegistryEntityId?>{
              for (final RegistryNodeId nodeId in activeNodeIds) nodeId: null,
            },
          );

    final Map<RegistryPath, RegistryNode> nodesByPath =
        <RegistryPath, RegistryNode>{};

    for (final HelpyRegistryDocumentNode interpretedNode
        in interpretedNodes.reversed) {
      final RegistryNodeId nodeId = identitiesByPath[interpretedNode.path]!;
      final HelpyRegistrySemanticIdentity? semanticIdentity =
          semanticIdentityOverlayApplies
          ? semanticIdentityOverlay.identitiesByNodeId[nodeId]
          : null;

      final List<RegistryNode> children = <RegistryNode>[];

      for (final HelpyRegistryDocumentNode interpretedChild
          in interpretedNode.children) {
        final RegistryNode? child = nodesByPath[interpretedChild.path];

        if (child == null) {
          throw StateError(
            'Helpy Registry child node was not constructed for '
            '${interpretedChild.path.segments.join(' → ')}.',
          );
        }

        children.add(child);
      }

      nodesByPath[interpretedNode.path] = RegistryNode(
        id: nodeId,
        kindId:
            semanticIdentity?.kind.kindId ??
            'helpy.registry.markdown.heading.'
                '${interpretedNode.headingLevel}',
        path: interpretedNode.path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: sourceDocument.documentPath,
            sourceSnapshotFingerprint: sourceDocument.sourceSnapshotFingerprint,
            headingPath: interpretedNode.path.segments,
            startLine: interpretedNode.startLine,
            endLine: interpretedNode.endLine,
          ),
        ],
        content: interpretedNode.content,
        businessScopeOwnerId: businessScopeOwnerIdsByNodeId[nodeId],
        children: children,
      );
    }

    final List<RegistryNode> roots = <RegistryNode>[];

    for (final HelpyRegistryDocumentNode interpretedRoot in interpretedRoots) {
      final RegistryNode? root = nodesByPath[interpretedRoot.path];

      if (root == null) {
        throw StateError(
          'Helpy Registry root node was not constructed for '
          '${interpretedRoot.path.segments.join(' → ')}.',
        );
      }

      roots.add(root);
    }

    final Map<RegistryNodeId, RegistryNode> activeNodesById =
        <RegistryNodeId, RegistryNode>{
          for (final RegistryNode node in nodesByPath.values) node.id: node,
        };

    final List<RegistryEntity> entities = semanticIdentityOverlayApplies
        ? <RegistryEntity>[
            for (final HelpyRegistrySemanticIdentity identity
                in semanticIdentityOverlay.identities)
              identity.materializeEntity(
                activeNodesById[identity.nodeId] ??
                    (throw StateError(
                      'Helpy Registry semantic node was not constructed for '
                      '${identity.nodeId.value}.',
                    )),
              ),
          ]
        : const <RegistryEntity>[];

    return RegistrySnapshot(
      projectId: projectId,
      projectAdapterId: projectAdapterId,
      sourceDocumentPath: sourceDocument.documentPath,
      sourceRevision: sourceDocument.sourceRevision,
      sourceSnapshotFingerprint: sourceDocument.sourceSnapshotFingerprint,
      sourceContent: sourceDocument.content,
      roots: roots,
      entities: entities,
    );
  }
}
