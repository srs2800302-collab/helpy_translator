import '../../../core/domain/evidence/source_evidence.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/application/contracts/registry_snapshot_loader.dart';
import '../../../registry/application/contracts/registry_snapshot_refresh_loader.dart';
import '../../../registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import '../application/contracts/helpy_registry_node_identity_store.dart';
import 'github_registry_document_source.dart';
import 'helpy_registry_document_interpreter.dart';
import 'helpy_registry_node_identity_ledger_source.dart';

final class HelpyRegistrySnapshotLoader
    implements
        RegistrySnapshotLoader,
        RegistrySnapshotRefreshLoader,
        RegistrySnapshotRevisionLoader {
  const HelpyRegistrySnapshotLoader({
    required this.documentSource,
    required this.identityLedgerSource,
    required this.identityStore,
    this.documentInterpreter = const HelpyRegistryDocumentInterpreter(),
  });

  static const String projectId = 'helpy';
  static const String projectAdapterId = 'helpy.registry.adapter.v1';
  static const String _nodeIdPrefix = 'helpy.registry.node.';

  static final RegExp _nodeIdPattern = RegExp(
    r'^helpy\.registry\.node\.([0-9]{6,})$',
  );

  final GitHubRegistryDocumentSource documentSource;
  final HelpyRegistryNodeIdentityLedgerSource identityLedgerSource;
  final HelpyRegistryNodeIdentityStore identityStore;
  final HelpyRegistryDocumentInterpreter documentInterpreter;

  @override
  Future<RegistrySnapshot> loadSnapshot() {
    return _loadSnapshot();
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAfterRevision(String previousRevision) {
    return _loadSnapshot(inheritedRevision: previousRevision);
  }

  @override
  Future<RegistrySnapshot> loadSnapshotAtRevision(String sourceRevision) {
    return _loadSnapshot(exactRevision: sourceRevision);
  }

  Future<RegistrySnapshot> _loadSnapshot({
    String? exactRevision,
    String? inheritedRevision,
  }) async {
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
        'structural identity ledger: '
        '${sourceDocument.documentPath}.',
      );
    }

    final HelpyRegistryNodeIdentityLedger identityLedger =
        await identityLedgerSource.load(
          exactRevision: sourceDocument.sourceRevision,
        );

    final Map<RegistryPath, RegistryNodeId> ledgerIdentities =
        identityLedger.identitiesByPath;

    final Map<RegistryPath, RegistryNodeId> localIdentities =
        <RegistryPath, RegistryNodeId>{};

    if (inheritedRevision != null &&
        inheritedRevision != sourceDocument.sourceRevision) {
      localIdentities.addAll(
        await identityStore.loadIdentities(inheritedRevision),
      );
    }

    localIdentities.addAll(
      await identityStore.loadIdentities(sourceDocument.sourceRevision),
    );

    final Map<RegistryNodeId, RegistryPath> ledgerPathsById =
        <RegistryNodeId, RegistryPath>{
          for (final MapEntry<RegistryPath, RegistryNodeId> entry
              in ledgerIdentities.entries)
            entry.value: entry.key,
        };

    for (final MapEntry<RegistryPath, RegistryNodeId> entry
        in ledgerIdentities.entries) {
      final RegistryNodeId? localId = localIdentities[entry.key];

      if (localId == null) {
        continue;
      }

      if (localId != entry.value) {
        throw StateError(
          'Helpy Registry identity conflict for '
          '${entry.key.segments.join(' → ')}: '
          '${localId.value} != ${entry.value.value}.',
        );
      }

      localIdentities.remove(entry.key);
    }

    final Map<RegistryNodeId, RegistryPath> localPathsById =
        <RegistryNodeId, RegistryPath>{};

    int maximumAssignedSequence = identityLedger.maximumAssignedSequence;

    for (final MapEntry<RegistryPath, RegistryNodeId> entry
        in localIdentities.entries) {
      final RegExpMatch? match = _nodeIdPattern.firstMatch(entry.value.value);

      if (match == null) {
        throw StateError(
          'Helpy Registry local identity '
          '${entry.value.value} is invalid.',
        );
      }

      final RegistryPath? ledgerPath = ledgerPathsById[entry.value];

      if (ledgerPath != null) {
        throw StateError(
          'Helpy Registry local identity '
          '${entry.value.value} conflicts with ledger path '
          '${ledgerPath.segments.join(' → ')}.',
        );
      }

      final RegistryPath? duplicateLocalPath = localPathsById[entry.value];

      if (duplicateLocalPath != null) {
        throw StateError(
          'Helpy Registry local identity '
          '${entry.value.value} is assigned to both '
          '${duplicateLocalPath.segments.join(' → ')} and '
          '${entry.key.segments.join(' → ')}.',
        );
      }

      localPathsById[entry.value] = entry.key;

      final int assignedSequence = int.parse(match.group(1)!);

      if (assignedSequence > maximumAssignedSequence) {
        maximumAssignedSequence = assignedSequence;
      }
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

    final Set<RegistryNodeId> usedIds = <RegistryNodeId>{
      ...ledgerPathsById.keys,
      ...localPathsById.keys,
    };

    final Map<RegistryPath, RegistryNodeId> resolvedIdentities =
        Map<RegistryPath, RegistryNodeId>.of(ledgerIdentities);

    for (final HelpyRegistryDocumentNode interpretedNode in interpretedNodes) {
      final RegistryNodeId? ledgerId = resolvedIdentities[interpretedNode.path];

      if (ledgerId != null) {
        continue;
      }

      final RegistryNodeId? localId = localIdentities[interpretedNode.path];

      if (localId != null) {
        resolvedIdentities[interpretedNode.path] = localId;
        continue;
      }

      late RegistryNodeId allocatedId;

      do {
        maximumAssignedSequence += 1;

        allocatedId = RegistryNodeId(
          '$_nodeIdPrefix'
          '${maximumAssignedSequence.toString().padLeft(6, '0')}',
        );
      } while (!usedIds.add(allocatedId));

      localIdentities[interpretedNode.path] = allocatedId;
      resolvedIdentities[interpretedNode.path] = allocatedId;
    }

    final Map<RegistryPath, RegistryNode> nodesByPath =
        <RegistryPath, RegistryNode>{};

    for (final HelpyRegistryDocumentNode interpretedNode
        in interpretedNodes.reversed) {
      final RegistryNodeId nodeId = resolvedIdentities[interpretedNode.path]!;

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

    await identityStore.saveIdentities(
      sourceDocument.sourceRevision,
      Map<RegistryPath, RegistryNodeId>.unmodifiable(localIdentities),
    );

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
