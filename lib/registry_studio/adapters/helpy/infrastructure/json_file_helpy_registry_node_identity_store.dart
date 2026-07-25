import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import '../application/contracts/helpy_registry_node_identity_store.dart';

final class JsonFileHelpyRegistryNodeIdentityStore
    implements HelpyRegistryNodeIdentityStore {
  const JsonFileHelpyRegistryNodeIdentityStore({
    this.applicationSupportDirectory,
  });

  static const String directoryName = 'registry_studio';

  static const String revisionDirectoryName =
      'helpy_registry_node_identity_states_v3';

  static const String legacyRevisionDirectoryName =
      'helpy_registry_node_identities_v2';

  static const String legacyFileName = 'helpy_registry_node_identities_v1.json';

  static const String _formatVersion = 'v3';
  static const String _legacyRevisionFormatVersion = 'v2';
  static const String _legacyFormatVersion = 'v1';
  static const String _projectId = 'helpy';

  static final RegExp _sourceRevisionPattern = RegExp(r'^[0-9a-f]{40}$');

  static final RegExp _nodeIdPattern = RegExp(
    r'^helpy\.registry\.node\.[0-9]{6,}$',
  );

  final Directory? applicationSupportDirectory;

  @override
  Future<HelpyRegistryNodeIdentityState> loadState(
    String sourceRevision,
  ) async {
    final String normalizedSourceRevision = sourceRevision.trim();

    if (!_sourceRevisionPattern.hasMatch(normalizedSourceRevision)) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Helpy Registry identity source revision must be '
            'an exact lowercase Git commit SHA.',
      );
    }

    final Directory supportDirectory;

    if (applicationSupportDirectory != null) {
      supportDirectory = applicationSupportDirectory!;
    } else {
      final String? applicationSupportPath = await PathProviderAndroid()
          .getApplicationSupportPath();

      if (applicationSupportPath == null ||
          applicationSupportPath.trim().isEmpty) {
        throw StateError(
          'Android application support directory is unavailable.',
        );
      }

      supportDirectory = Directory(applicationSupportPath);
    }

    final File revisionFile = File(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName'
      '${Platform.pathSeparator}'
      '$revisionDirectoryName'
      '${Platform.pathSeparator}'
      '$normalizedSourceRevision.json',
    );

    final File legacyRevisionFile = File(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName'
      '${Platform.pathSeparator}'
      '$legacyRevisionDirectoryName'
      '${Platform.pathSeparator}'
      '$normalizedSourceRevision.json',
    );

    File? discoveredRevisionFile;
    String? discoveredFormatVersion;

    if (await revisionFile.exists()) {
      discoveredRevisionFile = revisionFile;
      discoveredFormatVersion = _formatVersion;
    } else if (await legacyRevisionFile.exists()) {
      discoveredRevisionFile = legacyRevisionFile;
      discoveredFormatVersion = _legacyRevisionFormatVersion;
    }

    if (discoveredRevisionFile != null && discoveredFormatVersion != null) {
      final Object? decodedState = jsonDecode(
        await discoveredRevisionFile.readAsString(),
      );

      if (decodedState is! Map<Object?, Object?> ||
          decodedState.keys.any((Object? key) => key is! String)) {
        throw const FormatException(
          'Helpy Registry revision identity state must be '
          'a JSON object with string keys.',
        );
      }

      final Map<String, Object?> state = decodedState.cast<String, Object?>();

      final Set<String> expectedKeys = discoveredFormatVersion == _formatVersion
          ? const <String>{
              'version',
              'projectId',
              'sourceRevision',
              'entries',
              'retiredNodeIds',
            }
          : const <String>{'version', 'projectId', 'sourceRevision', 'entries'};

      if (state.keys.length != expectedKeys.length ||
          !state.keys.toSet().containsAll(expectedKeys) ||
          state['version'] != discoveredFormatVersion ||
          state['projectId'] != _projectId ||
          state['sourceRevision'] != normalizedSourceRevision) {
        throw const FormatException(
          'Helpy Registry revision identity state schema is invalid.',
        );
      }

      final Object? entriesValue = state['entries'];

      if (entriesValue is! List<Object?>) {
        throw const FormatException(
          'Helpy Registry revision identity entries must be '
          'a JSON array.',
        );
      }

      final Map<RegistryPath, RegistryNodeId> identities =
          <RegistryPath, RegistryNodeId>{};

      final Set<RegistryNodeId> discoveredIds = <RegistryNodeId>{};

      for (int index = 0; index < entriesValue.length; index += 1) {
        final Object? entryValue = entriesValue[index];

        if (entryValue is! Map<Object?, Object?> ||
            entryValue.keys.any((Object? key) => key is! String)) {
          throw FormatException(
            'Helpy Registry revision identity entry '
            'at index $index is invalid.',
          );
        }

        final Map<String, Object?> entry = entryValue.cast<String, Object?>();

        const Set<String> expectedEntryKeys = <String>{'nodeId', 'headingPath'};

        if (entry.keys.length != expectedEntryKeys.length ||
            !entry.keys.toSet().containsAll(expectedEntryKeys)) {
          throw FormatException(
            'Helpy Registry revision identity entry '
            'at index $index has an invalid schema.',
          );
        }

        final Object? nodeIdValue = entry['nodeId'];
        final Object? headingPathValue = entry['headingPath'];

        if (nodeIdValue is! String ||
            !_nodeIdPattern.hasMatch(nodeIdValue) ||
            headingPathValue is! List<Object?> ||
            headingPathValue.isEmpty ||
            headingPathValue.any(
              (Object? segment) =>
                  segment is! String ||
                  segment.isEmpty ||
                  segment != segment.trim(),
            )) {
          throw FormatException(
            'Helpy Registry revision identity entry '
            'at index $index contains invalid values.',
          );
        }

        final RegistryNodeId nodeId = RegistryNodeId(nodeIdValue);
        final RegistryPath path = RegistryPath(headingPathValue.cast<String>());

        if (!discoveredIds.add(nodeId)) {
          throw FormatException(
            'Helpy Registry revision identity state contains '
            'duplicate nodeId ${nodeId.value}.',
          );
        }

        if (identities.containsKey(path)) {
          throw FormatException(
            'Helpy Registry revision identity state contains '
            'duplicate headingPath '
            '${path.segments.join(' → ')}.',
          );
        }

        identities[path] = nodeId;
      }

      final Set<RegistryNodeId> retiredNodeIds = <RegistryNodeId>{};

      if (discoveredFormatVersion == _formatVersion) {
        final Object? retiredNodeIdsValue = state['retiredNodeIds'];

        if (retiredNodeIdsValue is! List<Object?>) {
          throw const FormatException(
            'Helpy Registry retired identity IDs must be '
            'a JSON array.',
          );
        }

        for (int index = 0; index < retiredNodeIdsValue.length; index += 1) {
          final Object? retiredNodeIdValue = retiredNodeIdsValue[index];

          if (retiredNodeIdValue is! String ||
              !_nodeIdPattern.hasMatch(retiredNodeIdValue)) {
            throw FormatException(
              'Helpy Registry retired identity ID '
              'at index $index is invalid.',
            );
          }

          final RegistryNodeId retiredNodeId = RegistryNodeId(
            retiredNodeIdValue,
          );

          if (!retiredNodeIds.add(retiredNodeId)) {
            throw FormatException(
              'Helpy Registry revision identity state contains '
              'duplicate retired nodeId ${retiredNodeId.value}.',
            );
          }

          if (discoveredIds.contains(retiredNodeId)) {
            throw FormatException(
              'Helpy Registry revision identity state contains '
              'active and retired nodeId ${retiredNodeId.value}.',
            );
          }
        }
      }

      if (discoveredFormatVersion == _legacyRevisionFormatVersion) {
        return HelpyRegistryNodeIdentityState(retiredNodeIds: discoveredIds);
      }

      return HelpyRegistryNodeIdentityState(
        localIdentitiesByPath: identities,
        retiredNodeIds: retiredNodeIds,
      );
    }

    final File legacyFile = File(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName'
      '${Platform.pathSeparator}'
      '$legacyFileName',
    );

    if (!await legacyFile.exists()) {
      return HelpyRegistryNodeIdentityState();
    }

    final Object? decodedLegacyState = jsonDecode(
      await legacyFile.readAsString(),
    );

    if (decodedLegacyState is! Map<Object?, Object?> ||
        decodedLegacyState.keys.any((Object? key) => key is! String)) {
      throw const FormatException(
        'Helpy Registry legacy identity state must be '
        'a JSON object with string keys.',
      );
    }

    final Map<String, Object?> legacyState = decodedLegacyState
        .cast<String, Object?>();

    const Set<String> legacyExpectedKeys = <String>{
      'version',
      'projectId',
      'entries',
    };

    if (legacyState.keys.length != legacyExpectedKeys.length ||
        !legacyState.keys.toSet().containsAll(legacyExpectedKeys) ||
        legacyState['version'] != _legacyFormatVersion ||
        legacyState['projectId'] != _projectId) {
      throw const FormatException(
        'Helpy Registry legacy identity state schema is invalid.',
      );
    }

    final Object? legacyEntriesValue = legacyState['entries'];

    if (legacyEntriesValue is! List<Object?>) {
      throw const FormatException(
        'Helpy Registry legacy identity entries must be '
        'a JSON array.',
      );
    }

    final Map<RegistryPath, RegistryNodeId> legacyIdentities =
        <RegistryPath, RegistryNodeId>{};

    final Set<RegistryNodeId> legacyDiscoveredIds = <RegistryNodeId>{};

    for (int index = 0; index < legacyEntriesValue.length; index += 1) {
      final Object? entryValue = legacyEntriesValue[index];

      if (entryValue is! Map<Object?, Object?> ||
          entryValue.keys.any((Object? key) => key is! String)) {
        throw FormatException(
          'Helpy Registry legacy identity entry '
          'at index $index is invalid.',
        );
      }

      final Map<String, Object?> entry = entryValue.cast<String, Object?>();

      const Set<String> expectedEntryKeys = <String>{'nodeId', 'headingPath'};

      if (entry.keys.length != expectedEntryKeys.length ||
          !entry.keys.toSet().containsAll(expectedEntryKeys)) {
        throw FormatException(
          'Helpy Registry legacy identity entry '
          'at index $index has an invalid schema.',
        );
      }

      final Object? nodeIdValue = entry['nodeId'];
      final Object? headingPathValue = entry['headingPath'];

      if (nodeIdValue is! String ||
          !_nodeIdPattern.hasMatch(nodeIdValue) ||
          headingPathValue is! List<Object?> ||
          headingPathValue.isEmpty ||
          headingPathValue.any(
            (Object? segment) =>
                segment is! String ||
                segment.isEmpty ||
                segment != segment.trim(),
          )) {
        throw FormatException(
          'Helpy Registry legacy identity entry '
          'at index $index contains invalid values.',
        );
      }

      final RegistryNodeId nodeId = RegistryNodeId(nodeIdValue);
      final RegistryPath path = RegistryPath(headingPathValue.cast<String>());

      if (!legacyDiscoveredIds.add(nodeId)) {
        throw FormatException(
          'Helpy Registry legacy identity state contains '
          'duplicate nodeId ${nodeId.value}.',
        );
      }

      if (legacyIdentities.containsKey(path)) {
        throw FormatException(
          'Helpy Registry legacy identity state contains '
          'duplicate headingPath '
          '${path.segments.join(' → ')}.',
        );
      }

      legacyIdentities[path] = nodeId;
    }

    return HelpyRegistryNodeIdentityState(retiredNodeIds: legacyDiscoveredIds);
  }

  @override
  Future<void> saveState(
    String sourceRevision,
    HelpyRegistryNodeIdentityState state,
  ) async {
    final String normalizedSourceRevision = sourceRevision.trim();

    if (!_sourceRevisionPattern.hasMatch(normalizedSourceRevision)) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Helpy Registry identity source revision must be '
            'an exact lowercase Git commit SHA.',
      );
    }

    final Set<RegistryNodeId> activeNodeIds = <RegistryNodeId>{};

    for (final MapEntry<RegistryPath, RegistryNodeId> entry
        in state.localIdentitiesByPath.entries) {
      if (!_nodeIdPattern.hasMatch(entry.value.value)) {
        throw ArgumentError.value(
          entry.value.value,
          'state',
          'Helpy Registry local identity has an invalid nodeId.',
        );
      }

      if (!activeNodeIds.add(entry.value)) {
        throw ArgumentError.value(
          entry.value.value,
          'state',
          'Helpy Registry local identities contain '
              'a duplicate nodeId.',
        );
      }
    }

    for (final RegistryNodeId retiredNodeId in state.retiredNodeIds) {
      if (!_nodeIdPattern.hasMatch(retiredNodeId.value)) {
        throw ArgumentError.value(
          retiredNodeId.value,
          'state',
          'Helpy Registry retired identity has an invalid nodeId.',
        );
      }

      if (activeNodeIds.contains(retiredNodeId)) {
        throw ArgumentError.value(
          retiredNodeId.value,
          'state',
          'Helpy Registry identity cannot be active and retired.',
        );
      }
    }

    final Directory supportDirectory;

    if (applicationSupportDirectory != null) {
      supportDirectory = applicationSupportDirectory!;
    } else {
      final String? applicationSupportPath = await PathProviderAndroid()
          .getApplicationSupportPath();

      if (applicationSupportPath == null ||
          applicationSupportPath.trim().isEmpty) {
        throw StateError(
          'Android application support directory is unavailable.',
        );
      }

      supportDirectory = Directory(applicationSupportPath);
    }

    final Directory revisionDirectory = Directory(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName'
      '${Platform.pathSeparator}'
      '$revisionDirectoryName',
    );

    await revisionDirectory.create(recursive: true);

    final File revisionFile = File(
      '${revisionDirectory.path}'
      '${Platform.pathSeparator}'
      '$normalizedSourceRevision.json',
    );

    final File temporaryFile = File('${revisionFile.path}.tmp');

    if (await temporaryFile.exists()) {
      await temporaryFile.delete();
    }

    final List<MapEntry<RegistryPath, RegistryNodeId>> orderedEntries =
        state.localIdentitiesByPath.entries.toList(growable: false)..sort(
          (
            MapEntry<RegistryPath, RegistryNodeId> left,
            MapEntry<RegistryPath, RegistryNodeId> right,
          ) => left.key.segments
              .join('\u0000')
              .compareTo(right.key.segments.join('\u0000')),
        );

    final List<RegistryNodeId> orderedRetiredNodeIds =
        state.retiredNodeIds.toList(growable: false)..sort(
          (RegistryNodeId left, RegistryNodeId right) =>
              left.value.compareTo(right.value),
        );

    try {
      await temporaryFile.writeAsString(
        '${jsonEncode(<String, Object?>{
          'version': _formatVersion,
          'projectId': _projectId,
          'sourceRevision': normalizedSourceRevision,
          'entries': <Map<String, Object?>>[
            for (final MapEntry<RegistryPath, RegistryNodeId> entry in orderedEntries) <String, Object?>{'nodeId': entry.value.value, 'headingPath': entry.key.segments},
          ],
          'retiredNodeIds': <String>[for (final RegistryNodeId nodeId in orderedRetiredNodeIds) nodeId.value],
        })}\n',
        flush: true,
      );

      await temporaryFile.rename(revisionFile.path);

      final File legacyRevisionFile = File(
        '${supportDirectory.path}'
        '${Platform.pathSeparator}'
        '$directoryName'
        '${Platform.pathSeparator}'
        '$legacyRevisionDirectoryName'
        '${Platform.pathSeparator}'
        '$normalizedSourceRevision.json',
      );

      if (await legacyRevisionFile.exists()) {
        await legacyRevisionFile.delete();
      }

      final File legacyFile = File(
        '${supportDirectory.path}'
        '${Platform.pathSeparator}'
        '$directoryName'
        '${Platform.pathSeparator}'
        '$legacyFileName',
      );

      if (await legacyFile.exists()) {
        await legacyFile.delete();
      }
    } catch (_) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      rethrow;
    }
  }
}
