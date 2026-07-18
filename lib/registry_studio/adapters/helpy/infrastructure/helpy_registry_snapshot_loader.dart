import '../../../core/domain/evidence/source_evidence.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/application/contracts/registry_snapshot_loader.dart';
import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import 'github_registry_document_source.dart';
import 'helpy_registry_document_interpreter.dart';
import 'helpy_registry_node_identity_ledger_source.dart';

final class HelpyRegistrySnapshotLoader implements RegistrySnapshotLoader {
  const HelpyRegistrySnapshotLoader({
    required this.documentSource,
    required this.identityLedgerSource,
    this.documentInterpreter = const HelpyRegistryDocumentInterpreter(),
  });

  static const String projectId = 'helpy';
  static const String projectAdapterId = 'helpy.registry.adapter.v1';

  final GitHubRegistryDocumentSource documentSource;
  final HelpyRegistryNodeIdentityLedgerSource identityLedgerSource;
  final HelpyRegistryDocumentInterpreter documentInterpreter;

  @override
  Future<RegistrySnapshot> loadSnapshot() async {
    final Map<RegistryPath, RegistryNodeId> identitiesByPath =
        await identityLedgerSource.load();

    final sourceDocument = await documentSource.load();

    if (sourceDocument.documentPath !=
        HelpyRegistryNodeIdentityLedgerSource.registryDocumentPath) {
      throw FormatException(
        'Helpy Registry source document path does not match the '
        'structural identity ledger: ${sourceDocument.documentPath}.',
      );
    }

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

    final Map<RegistryPath, RegistryNode> nodesByPath =
        <RegistryPath, RegistryNode>{};

    for (final HelpyRegistryDocumentNode interpretedNode
        in interpretedNodes.reversed) {
      final RegistryNodeId? nodeId = identitiesByPath[interpretedNode.path];

      if (nodeId == null) {
        throw FormatException(
          'Helpy Registry node identity ledger does not contain '
          '${interpretedNode.path.segments.join(' → ')}.',
        );
      }

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
        businessScopeOwnerId: null,
        children: children,
      );
    }

    for (final RegistryPath identityPath in identitiesByPath.keys) {
      if (!nodesByPath.containsKey(identityPath)) {
        throw FormatException(
          'Helpy Registry node identity ledger contains an identity '
          'without a matching Registry node: '
          '${identityPath.segments.join(' → ')}.',
        );
      }
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

    return RegistrySnapshot(
      projectId: projectId,
      projectAdapterId: projectAdapterId,
      sourceDocumentPath: sourceDocument.documentPath,
      sourceRevision: sourceDocument.sourceRevision,
      sourceSnapshotFingerprint: sourceDocument.sourceSnapshotFingerprint,
      sourceContent: sourceDocument.content,
      roots: roots,
    );
  }
}
