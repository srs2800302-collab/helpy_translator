import '../../../core/domain/evidence/source_evidence.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/application/contracts/registry_snapshot_loader.dart';
import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
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

    final sourceDocument = await documentSource.load();

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

    final Map<RegistryPath, RegistryNode> nodesByPath =
        <RegistryPath, RegistryNode>{};

    for (final HelpyRegistryDocumentNode interpretedNode
        in interpretedNodes.reversed) {
      final RegistryNodeId nodeId = identitiesByPath[interpretedNode.path]!;

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
