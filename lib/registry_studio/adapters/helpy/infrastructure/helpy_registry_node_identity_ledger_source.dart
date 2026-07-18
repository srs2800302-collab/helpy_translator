import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';

final class HelpyRegistryNodeIdentityLedgerSource {
  factory HelpyRegistryNodeIdentityLedgerSource({
    required AssetBundle assetBundle,
    String assetPath = defaultAssetPath,
  }) {
    final String normalizedAssetPath = assetPath.trim();

    if (normalizedAssetPath.isEmpty) {
      throw ArgumentError.value(
        assetPath,
        'assetPath',
        'Helpy Registry node identity ledger asset path must not be empty.',
      );
    }

    return HelpyRegistryNodeIdentityLedgerSource._(
      assetBundle: assetBundle,
      assetPath: normalizedAssetPath,
    );
  }

  const HelpyRegistryNodeIdentityLedgerSource._({
    required this.assetBundle,
    required this.assetPath,
  });

  static const String defaultAssetPath =
      'assets/registry_studio/helpy/'
      'registry_node_identity_ledger_v1.json';

  static const String _expectedVersion = 'v1';
  static const String _expectedProjectId = 'helpy';
  static const String _expectedRegistryDocumentPath =
      'docs/architecture/Helpy_Architecture_Registry_v1.md';

  static final RegExp _sourceRevisionPattern = RegExp(r'^[0-9a-f]{40}$');
  static final RegExp _sourceFingerprintPattern = RegExp(
    r'^git-blob:[0-9a-f]{40}$',
  );
  static final RegExp _nodeIdPattern = RegExp(
    r'^helpy\.registry\.node\.[0-9]{6,}$',
  );

  final AssetBundle assetBundle;
  final String assetPath;

  Future<Map<RegistryPath, RegistryNodeId>> load() async {
    final String assetContent = await assetBundle.loadString(assetPath);

    if (assetContent.trim().isEmpty) {
      throw const FormatException(
        'Helpy Registry node identity ledger must not be empty.',
      );
    }

    final Object? decodedLedger = jsonDecode(assetContent);

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

    if (ledger['registryDocumentPath'] != _expectedRegistryDocumentPath) {
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

    final Map<RegistryPath, RegistryNodeId> identitiesByPath =
        <RegistryPath, RegistryNodeId>{
          for (final ({
                RegistryNodeId id,
                RegistryPath path,
                String? parentNodeId,
              })
              entry
              in entries)
            entry.path: entry.id,
        };

    return Map<RegistryPath, RegistryNodeId>.unmodifiable(identitiesByPath);
  }
}
