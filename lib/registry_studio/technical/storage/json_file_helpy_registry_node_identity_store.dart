import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../../adapters/helpy/application/contracts/helpy_registry_node_identity_store.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../../registry/domain/value_objects/registry_node_id.dart';

final class JsonFileHelpyRegistryNodeIdentityStore
    implements HelpyRegistryNodeIdentityStore {
  const JsonFileHelpyRegistryNodeIdentityStore({
    this.applicationSupportDirectory,
  });

  static const String directoryName = 'registry_studio';
  static const String fileName = 'helpy_registry_node_identities_v1.json';
  static const String _formatVersion = 'v1';
  static const String _projectId = 'helpy';

  static final RegExp _nodeIdPattern = RegExp(
    r'^helpy\.registry\.node\.[0-9]{6,}$',
  );

  final Directory? applicationSupportDirectory;

  @override
  Future<Map<RegistryPath, RegistryNodeId>> loadIdentities() async {
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

    final File stateFile = File(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName'
      '${Platform.pathSeparator}'
      '$fileName',
    );

    if (!await stateFile.exists()) {
      return <RegistryPath, RegistryNodeId>{};
    }

    final Object? decodedState = jsonDecode(await stateFile.readAsString());

    if (decodedState is! Map<Object?, Object?> ||
        decodedState.keys.any((Object? key) => key is! String)) {
      throw const FormatException(
        'Helpy Registry local identity state must be a JSON object '
        'with string keys.',
      );
    }

    final Map<String, Object?> state = decodedState.cast<String, Object?>();

    const Set<String> expectedKeys = <String>{
      'version',
      'projectId',
      'entries',
    };

    if (state.keys.length != expectedKeys.length ||
        !state.keys.toSet().containsAll(expectedKeys) ||
        state['version'] != _formatVersion ||
        state['projectId'] != _projectId) {
      throw const FormatException(
        'Helpy Registry local identity state schema is invalid.',
      );
    }

    final Object? entriesValue = state['entries'];

    if (entriesValue is! List<Object?>) {
      throw const FormatException(
        'Helpy Registry local identity entries must be a JSON array.',
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
          'Helpy Registry local identity entry at index $index is invalid.',
        );
      }

      final Map<String, Object?> entry = entryValue.cast<String, Object?>();

      const Set<String> expectedEntryKeys = <String>{'nodeId', 'headingPath'};

      if (entry.keys.length != expectedEntryKeys.length ||
          !entry.keys.toSet().containsAll(expectedEntryKeys)) {
        throw FormatException(
          'Helpy Registry local identity entry at index $index '
          'has an invalid schema.',
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
          'Helpy Registry local identity entry at index $index '
          'contains invalid values.',
        );
      }

      final RegistryNodeId nodeId = RegistryNodeId(nodeIdValue);
      final RegistryPath path = RegistryPath(headingPathValue.cast<String>());

      if (!discoveredIds.add(nodeId)) {
        throw FormatException(
          'Helpy Registry local identity state contains duplicate nodeId '
          '${nodeId.value}.',
        );
      }

      if (identities.containsKey(path)) {
        throw FormatException(
          'Helpy Registry local identity state contains duplicate '
          'headingPath ${path.segments.join(' → ')}.',
        );
      }

      identities[path] = nodeId;
    }

    return Map<RegistryPath, RegistryNodeId>.unmodifiable(identities);
  }

  @override
  Future<void> saveIdentities(
    Map<RegistryPath, RegistryNodeId> identities,
  ) async {
    final Set<RegistryNodeId> discoveredIds = <RegistryNodeId>{};

    for (final MapEntry<RegistryPath, RegistryNodeId> entry
        in identities.entries) {
      if (!_nodeIdPattern.hasMatch(entry.value.value)) {
        throw ArgumentError.value(
          entry.value.value,
          'identities',
          'Helpy Registry local identity has an invalid nodeId.',
        );
      }

      if (!discoveredIds.add(entry.value)) {
        throw ArgumentError.value(
          entry.value.value,
          'identities',
          'Helpy Registry local identities contain a duplicate nodeId.',
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

    final Directory stateDirectory = Directory(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName',
    );

    await stateDirectory.create(recursive: true);

    final File stateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$fileName',
    );
    final File temporaryFile = File('${stateFile.path}.tmp');

    if (await temporaryFile.exists()) {
      await temporaryFile.delete();
    }

    final List<MapEntry<RegistryPath, RegistryNodeId>> orderedEntries =
        identities.entries.toList(growable: false)..sort(
          (
            MapEntry<RegistryPath, RegistryNodeId> left,
            MapEntry<RegistryPath, RegistryNodeId> right,
          ) => left.key.segments
              .join('\u0000')
              .compareTo(right.key.segments.join('\u0000')),
        );

    try {
      await temporaryFile.writeAsString(
        '${jsonEncode(<String, Object?>{
          'version': _formatVersion,
          'projectId': _projectId,
          'entries': <Map<String, Object?>>[
            for (final MapEntry<RegistryPath, RegistryNodeId> entry in orderedEntries) <String, Object?>{'nodeId': entry.value.value, 'headingPath': entry.key.segments},
          ],
        })}\n',
        flush: true,
      );

      await temporaryFile.rename(stateFile.path);
    } catch (_) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      rethrow;
    }
  }
}
