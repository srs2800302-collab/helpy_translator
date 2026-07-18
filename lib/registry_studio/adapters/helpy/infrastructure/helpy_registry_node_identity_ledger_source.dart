import 'dart:convert';

import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import 'github_registry_document_source.dart';

final class HelpyRegistryNodeIdentityLedger {
  const HelpyRegistryNodeIdentityLedger._({
    required this.version,
    required this.projectId,
    required this.registryDocumentPath,
    required this.initialSourceRevision,
    required this.initialSourceSnapshotFingerprint,
    required this.entries,
    required this.identitiesByPath,
    required this.parentIdByNodeId,
    required this.maximumAssignedSequence,
  });

  final String version;
  final String projectId;
  final String registryDocumentPath;
  final String initialSourceRevision;
  final String initialSourceSnapshotFingerprint;

  final List<({RegistryNodeId id, RegistryPath path, RegistryNodeId? parentId})>
  entries;

  final Map<RegistryPath, RegistryNodeId> identitiesByPath;
  final Map<RegistryNodeId, RegistryNodeId?> parentIdByNodeId;
  final int maximumAssignedSequence;
}

final class HelpyRegistryNodeIdentityLedgerSource {
  factory HelpyRegistryNodeIdentityLedgerSource({
    required GitHubRegistryDocumentSource documentSource,
  }) {
    if (documentSource.documentPath != ledgerDocumentPath) {
      throw ArgumentError.value(
        documentSource.documentPath,
        'documentSource',
        'Helpy Registry node identity ledger source must use '
            'the registered ledger document path.',
      );
    }

    return HelpyRegistryNodeIdentityLedgerSource._(
      documentSource: documentSource,
    );
  }

  const HelpyRegistryNodeIdentityLedgerSource._({required this.documentSource});

  static const String ledgerDocumentPath =
      'docs/architecture/registry_studio/'
      'registry_node_identity_ledger_v1.json';

  static const String _expectedVersion = 'v1';
  static const String _expectedProjectId = 'helpy';
  static const String _nodeIdPrefix = 'helpy.registry.node.';
  static const String registryDocumentPath =
      'docs/architecture/Helpy_Architecture_Registry_v1.md';

  static final RegExp _sourceRevisionPattern = RegExp(r'^[0-9a-f]{40}$');
  static final RegExp _sourceFingerprintPattern = RegExp(
    r'^git-blob:[0-9a-f]{40}$',
  );
  static final RegExp _nodeIdPattern = RegExp(
    r'^helpy\.registry\.node\.[0-9]{6,}$',
  );

  final GitHubRegistryDocumentSource documentSource;

  Future<HelpyRegistryNodeIdentityLedger> load({
    required String exactRevision,
  }) async {
    final ledgerDocument = await documentSource.load(
      exactRevision: exactRevision,
    );

    if (ledgerDocument.documentPath != ledgerDocumentPath) {
      throw const FormatException(
        'Helpy Registry node identity ledger source path is invalid.',
      );
    }

    if (ledgerDocument.sourceRevision != exactRevision) {
      throw StateError(
        'Helpy Registry node identity ledger was not loaded from '
        'the requested exact revision.',
      );
    }

    return decode(ledgerDocument.content);
  }

  static HelpyRegistryNodeIdentityLedger decode(String ledgerContent) {
    if (ledgerContent.trim().isEmpty) {
      throw const FormatException(
        'Helpy Registry node identity ledger must not be empty.',
      );
    }

    final Object? decodedLedger = jsonDecode(ledgerContent);

    if (decodedLedger is! Map<Object?, Object?>) {
      throw const FormatException(
        'Helpy Registry node identity ledger must be a JSON object.',
      );
    }

    if (decodedLedger.keys.any((Object? key) => key is! String)) {
      throw const FormatException(
        'Helpy Registry node identity ledger root keys must be strings.',
      );
    }

    final Map<String, Object?> ledger = decodedLedger.cast<String, Object?>();

    const Set<String> expectedRootKeys = <String>{
      'version',
      'projectId',
      'registryDocumentPath',
      'initialSourceRevision',
      'initialSourceSnapshotFingerprint',
      'entries',
    };

    final Set<String> actualRootKeys = ledger.keys.toSet();

    if (actualRootKeys.length != expectedRootKeys.length ||
        !actualRootKeys.containsAll(expectedRootKeys)) {
      throw const FormatException(
        'Helpy Registry node identity ledger root schema is invalid.',
      );
    }

    if (ledger['version'] != _expectedVersion) {
      throw const FormatException(
        'Helpy Registry node identity ledger version is unsupported.',
      );
    }

    if (ledger['projectId'] != _expectedProjectId) {
      throw const FormatException(
        'Helpy Registry node identity ledger project identifier is invalid.',
      );
    }

    if (ledger['registryDocumentPath'] != registryDocumentPath) {
      throw const FormatException(
        'Helpy Registry node identity ledger document path is invalid.',
      );
    }

    final Object? sourceRevision = ledger['initialSourceRevision'];

    if (sourceRevision is! String ||
        !_sourceRevisionPattern.hasMatch(sourceRevision)) {
      throw const FormatException(
        'Helpy Registry node identity ledger initial source revision '
        'must be an exact lowercase commit SHA.',
      );
    }

    final Object? sourceFingerprint =
        ledger['initialSourceSnapshotFingerprint'];

    if (sourceFingerprint is! String ||
        !_sourceFingerprintPattern.hasMatch(sourceFingerprint)) {
      throw const FormatException(
        'Helpy Registry node identity ledger initial source fingerprint '
        'must be an exact Git blob fingerprint.',
      );
    }

    final Object? entriesValue = ledger['entries'];

    if (entriesValue is! List<Object?> || entriesValue.isEmpty) {
      throw const FormatException(
        'Helpy Registry node identity ledger must contain entries.',
      );
    }

    final List<({RegistryNodeId id, RegistryPath path, String? parentNodeId})>
    entries =
        <({RegistryNodeId id, RegistryPath path, String? parentNodeId})>[];

    final Map<
      String,
      ({RegistryNodeId id, RegistryPath path, String? parentNodeId})
    >
    entriesById =
        <
          String,
          ({RegistryNodeId id, RegistryPath path, String? parentNodeId})
        >{};

    final Set<RegistryPath> discoveredPaths = <RegistryPath>{};

    for (int index = 0; index < entriesValue.length; index += 1) {
      final Object? entryValue = entriesValue[index];

      if (entryValue is! Map<Object?, Object?>) {
        throw FormatException(
          'Helpy Registry node identity ledger entry at index $index '
          'must be a JSON object.',
        );
      }

      if (entryValue.keys.any((Object? key) => key is! String)) {
        throw FormatException(
          'Helpy Registry node identity ledger entry at index $index '
          'must contain only string keys.',
        );
      }

      final Map<String, Object?> entry = entryValue.cast<String, Object?>();

      const Set<String> expectedEntryKeys = <String>{
        'nodeId',
        'headingPath',
        'parentNodeId',
      };

      final Set<String> actualEntryKeys = entry.keys.toSet();

      if (actualEntryKeys.length != expectedEntryKeys.length ||
          !actualEntryKeys.containsAll(expectedEntryKeys)) {
        throw FormatException(
          'Helpy Registry node identity ledger entry at index $index '
          'has an invalid schema.',
        );
      }

      final Object? nodeIdValue = entry['nodeId'];

      if (nodeIdValue is! String ||
          nodeIdValue != nodeIdValue.trim() ||
          !_nodeIdPattern.hasMatch(nodeIdValue)) {
        throw FormatException(
          'Helpy Registry node identity ledger entry at index $index '
          'has an invalid nodeId.',
        );
      }

      final RegistryNodeId nodeId = RegistryNodeId(nodeIdValue);

      if (entriesById.containsKey(nodeId.value)) {
        throw FormatException(
          'Helpy Registry node identity ledger contains duplicate nodeId '
          '${nodeId.value}.',
        );
      }

      final Object? headingPathValue = entry['headingPath'];

      if (headingPathValue is! List<Object?> || headingPathValue.isEmpty) {
        throw FormatException(
          'Helpy Registry node identity ledger entry ${nodeId.value} '
          'must contain a non-empty headingPath.',
        );
      }

      final List<String> headingPathSegments = <String>[];

      for (final Object? segmentValue in headingPathValue) {
        if (segmentValue is! String ||
            segmentValue.isEmpty ||
            segmentValue != segmentValue.trim()) {
          throw FormatException(
            'Helpy Registry node identity ledger entry ${nodeId.value} '
            'contains an invalid headingPath segment.',
          );
        }

        headingPathSegments.add(segmentValue);
      }

      final RegistryPath headingPath = RegistryPath(headingPathSegments);

      if (!discoveredPaths.add(headingPath)) {
        throw FormatException(
          'Helpy Registry node identity ledger contains duplicate headingPath '
          '${headingPath.segments.join(' → ')}.',
        );
      }

      final Object? parentNodeIdValue = entry['parentNodeId'];
      String? parentNodeId;

      if (parentNodeIdValue != null) {
        if (parentNodeIdValue is! String ||
            parentNodeIdValue != parentNodeIdValue.trim() ||
            !_nodeIdPattern.hasMatch(parentNodeIdValue)) {
          throw FormatException(
            'Helpy Registry node identity ledger entry ${nodeId.value} '
            'has an invalid parentNodeId.',
          );
        }

        if (parentNodeIdValue == nodeId.value) {
          throw FormatException(
            'Helpy Registry node identity ledger entry ${nodeId.value} '
            'must not reference itself as parent.',
          );
        }

        parentNodeId = parentNodeIdValue;
      }

      final ({RegistryNodeId id, RegistryPath path, String? parentNodeId})
      resolvedEntry = (
        id: nodeId,
        path: headingPath,
        parentNodeId: parentNodeId,
      );

      entries.add(resolvedEntry);
      entriesById[nodeId.value] = resolvedEntry;
    }

    int rootCount = 0;

    for (final ({RegistryNodeId id, RegistryPath path, String? parentNodeId})
        entry
        in entries) {
      final String? parentNodeId = entry.parentNodeId;

      if (parentNodeId == null) {
        rootCount += 1;

        if (entry.path.segments.length != 1) {
          throw FormatException(
            'Helpy Registry root identity ${entry.id.value} '
            'must have a one-segment headingPath.',
          );
        }

        continue;
      }

      final ({RegistryNodeId id, RegistryPath path, String? parentNodeId})?
      parent = entriesById[parentNodeId];

      if (parent == null) {
        throw FormatException(
          'Helpy Registry node identity ${entry.id.value} references '
          'unknown parent $parentNodeId.',
        );
      }

      if (entry.path.segments.length != parent.path.segments.length + 1) {
        throw FormatException(
          'Helpy Registry node identity ${entry.id.value} '
          'does not have the required parent-child path depth.',
        );
      }

      for (int index = 0; index < parent.path.segments.length; index += 1) {
        if (entry.path.segments[index] != parent.path.segments[index]) {
          throw FormatException(
            'Helpy Registry node identity ${entry.id.value} '
            'does not preserve its parent headingPath prefix.',
          );
        }
      }
    }

    if (rootCount == 0) {
      throw const FormatException(
        'Helpy Registry node identity ledger must contain at least one root.',
      );
    }

    final List<
      ({RegistryNodeId id, RegistryPath path, RegistryNodeId? parentId})
    >
    immutableEntries =
        List<
          ({RegistryNodeId id, RegistryPath path, RegistryNodeId? parentId})
        >.unmodifiable(
          entries.map(
            (entry) => (
              id: entry.id,
              path: entry.path,
              parentId: entry.parentNodeId == null
                  ? null
                  : RegistryNodeId(entry.parentNodeId!),
            ),
          ),
        );

    final Map<RegistryPath, RegistryNodeId> identitiesByPath =
        <RegistryPath, RegistryNodeId>{
          for (final entry in immutableEntries) entry.path: entry.id,
        };

    final Map<RegistryNodeId, RegistryNodeId?> parentIdByNodeId =
        <RegistryNodeId, RegistryNodeId?>{
          for (final entry in immutableEntries) entry.id: entry.parentId,
        };

    int maximumAssignedSequence = 0;

    for (final entry in immutableEntries) {
      final int assignedSequence = int.parse(
        entry.id.value.substring(_nodeIdPrefix.length),
      );

      if (assignedSequence > maximumAssignedSequence) {
        maximumAssignedSequence = assignedSequence;
      }
    }

    return HelpyRegistryNodeIdentityLedger._(
      version: _expectedVersion,
      projectId: _expectedProjectId,
      registryDocumentPath: registryDocumentPath,
      initialSourceRevision: sourceRevision,
      initialSourceSnapshotFingerprint: sourceFingerprint,
      entries: immutableEntries,
      identitiesByPath: Map<RegistryPath, RegistryNodeId>.unmodifiable(
        identitiesByPath,
      ),
      parentIdByNodeId: Map<RegistryNodeId, RegistryNodeId?>.unmodifiable(
        parentIdByNodeId,
      ),
      maximumAssignedSequence: maximumAssignedSequence,
    );
  }
}
