import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../../core/domain/value_objects/registry_path.dart';
import '../../registry/application/contracts/registry_revision_state_store.dart';
import '../../registry/domain/value_objects/registry_node_id.dart';

final class JsonFileRegistryRevisionStateStore
    implements RegistryRevisionStateStore {
  const JsonFileRegistryRevisionStateStore({this.applicationSupportDirectory});

  static const String directoryName = 'registry_studio';
  static const String fileName = 'registry_revision_state_v7.json';
  static const String currentPreviousFileName =
      'registry_revision_state_v6.json';
  static const String previousFileName = 'registry_revision_state_v5.json';
  static const String olderFileName = 'registry_revision_state_v4.json';
  static const String legacyFileName = 'registry_revision_state_v3.json';
  static const String oldestFileName = 'registry_revision_state_v2.json';
  static const String originalFileName = 'registry_revision_state_v1.json';

  static const String _formatVersion = 'v7';
  static const String _currentPreviousFormatVersion = 'v6';
  static const String _previousFormatVersion = 'v5';
  static const String _olderFormatVersion = 'v4';
  static const String _legacyFormatVersion = 'v3';
  static const String _oldestFormatVersion = 'v2';
  static const String _originalFormatVersion = 'v1';

  final Directory? applicationSupportDirectory;

  @override
  Future<RegistryRevisionState?> loadRevisionState() async {
    final Directory supportDirectory;

    if (applicationSupportDirectory != null) {
      supportDirectory = applicationSupportDirectory!;
    } else {
      final String? applicationSupportPath = await PathProviderAndroid()
          .getApplicationSupportPath();

      if (applicationSupportPath == null ||
          applicationSupportPath.trim().isEmpty) {
        throw StateError(
          'Android application support directory '
          'is unavailable.',
        );
      }

      supportDirectory = Directory(applicationSupportPath);
    }

    final Directory stateDirectory = Directory(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName',
    );

    final File currentStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$fileName',
    );

    final File currentPreviousStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$currentPreviousFileName',
    );

    final File previousStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$previousFileName',
    );

    final File olderStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$olderFileName',
    );

    final File legacyStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$legacyFileName',
    );

    final File oldestStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$oldestFileName',
    );

    final File originalStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$originalFileName',
    );

    final File stateFile;

    if (await currentStateFile.exists()) {
      stateFile = currentStateFile;
    } else if (await currentPreviousStateFile.exists()) {
      stateFile = currentPreviousStateFile;
    } else if (await previousStateFile.exists()) {
      stateFile = previousStateFile;
    } else if (await olderStateFile.exists()) {
      stateFile = olderStateFile;
    } else if (await legacyStateFile.exists()) {
      stateFile = legacyStateFile;
    } else if (await oldestStateFile.exists()) {
      stateFile = oldestStateFile;
    } else if (await originalStateFile.exists()) {
      stateFile = originalStateFile;
    } else {
      return null;
    }

    final Object? decodedState = jsonDecode(await stateFile.readAsString());

    if (decodedState is! Map<Object?, Object?>) {
      throw const FormatException(
        'Registry revision state must be '
        'a JSON object.',
      );
    }

    if (decodedState.keys.any((Object? key) => key is! String)) {
      throw const FormatException(
        'Registry revision state keys '
        'must be strings.',
      );
    }

    final Map<String, Object?> state = decodedState.cast<String, Object?>();

    final Object? version = state['version'];
    final Set<String> expectedKeys;

    if (version == _originalFormatVersion) {
      expectedKeys = const <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
      };
    } else if (version == _oldestFormatVersion) {
      expectedKeys = const <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
        'cleanBaselineRevision',
      };
    } else if (version == _legacyFormatVersion) {
      expectedKeys = const <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
        'cleanBaselineRevision',
        'selectedProblemNodeId',
        'selectedProblemPath',
        'selectedProblemIndex',
      };
    } else if (version == _olderFormatVersion) {
      expectedKeys = const <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
        'cleanBaselineRevision',
        'openRegistryNodeId',
        'openRegistryPath',
        'selectedProblemIndex',
      };
    } else if (version == _previousFormatVersion) {
      expectedKeys = const <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
        'cleanBaselineRevision',
        'openRegistryNodeId',
        'openRegistryPath',
        'selectedProblemIndex',
        'searchQuery',
      };
    } else if (version == _currentPreviousFormatVersion) {
      expectedKeys = const <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
        'cleanBaselineRevision',
        'openRegistryNodeId',
        'openRegistryPath',
        'selectedProblemIndex',
        'searchQuery',
        'registryViewFilter',
      };
    } else if (version == _formatVersion) {
      expectedKeys = const <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
        'cleanBaselineRevision',
        'openRegistryNodeId',
        'openRegistryPath',
        'selectedProblemIndex',
        'searchQuery',
        'registryViewFilter',
        'canonicalStatusFilter',
      };
    } else {
      throw const FormatException(
        'Registry revision state version '
        'is unsupported.',
      );
    }

    final Set<String> actualKeys = state.keys.toSet();

    if (actualKeys.length != expectedKeys.length ||
        !actualKeys.containsAll(expectedKeys)) {
      throw const FormatException(
        'Registry revision state schema '
        'is invalid.',
      );
    }

    final Object? projectId = state['projectId'];
    final Object? projectAdapterId = state['projectAdapterId'];
    final Object? sourceDocumentPath = state['sourceDocumentPath'];
    final Object? currentRevision = state['currentRevision'];
    final Object? previousRevision = state['previousRevision'];

    final bool includesCleanBaseline =
        version == _oldestFormatVersion ||
        version == _legacyFormatVersion ||
        version == _olderFormatVersion ||
        version == _previousFormatVersion ||
        version == _currentPreviousFormatVersion ||
        version == _formatVersion;

    final Object? cleanBaselineRevision = includesCleanBaseline
        ? state['cleanBaselineRevision']
        : null;

    final Object? openRegistryNodeId;

    if (version == _formatVersion ||
        version == _currentPreviousFormatVersion ||
        version == _previousFormatVersion ||
        version == _olderFormatVersion) {
      openRegistryNodeId = state['openRegistryNodeId'];
    } else if (version == _legacyFormatVersion) {
      openRegistryNodeId = state['selectedProblemNodeId'];
    } else {
      openRegistryNodeId = null;
    }

    final Object? openRegistryPath;

    if (version == _formatVersion ||
        version == _currentPreviousFormatVersion ||
        version == _previousFormatVersion ||
        version == _olderFormatVersion) {
      openRegistryPath = state['openRegistryPath'];
    } else if (version == _legacyFormatVersion) {
      openRegistryPath = state['selectedProblemPath'];
    } else {
      openRegistryPath = null;
    }

    final Object? selectedProblemIndex =
        version == _formatVersion ||
            version == _currentPreviousFormatVersion ||
            version == _previousFormatVersion ||
            version == _olderFormatVersion ||
            version == _legacyFormatVersion
        ? state['selectedProblemIndex']
        : null;

    final Object? searchQuery =
        version == _formatVersion ||
            version == _currentPreviousFormatVersion ||
            version == _previousFormatVersion
        ? state['searchQuery']
        : '';

    final Object? registryViewFilter =
        version == _formatVersion || version == _currentPreviousFormatVersion
        ? state['registryViewFilter']
        : 'all';

    final Object? canonicalStatusFilter = version == _formatVersion
        ? state['canonicalStatusFilter']
        : 'all';

    final bool openRegistryPathInvalid =
        openRegistryPath != null &&
        (openRegistryPath is! List<Object?> ||
            openRegistryPath.any((Object? segment) => segment is! String));

    if (projectId is! String ||
        projectAdapterId is! String ||
        sourceDocumentPath is! String ||
        currentRevision is! String ||
        (previousRevision != null && previousRevision is! String) ||
        (cleanBaselineRevision != null && cleanBaselineRevision is! String) ||
        (openRegistryNodeId != null && openRegistryNodeId is! String) ||
        openRegistryPathInvalid ||
        (selectedProblemIndex != null && selectedProblemIndex is! int) ||
        searchQuery is! String ||
        registryViewFilter is! String ||
        canonicalStatusFilter is! String) {
      throw const FormatException(
        'Registry revision state field types '
        'are invalid.',
      );
    }

    final RegistryPath? restoredOpenRegistryPath = openRegistryPath == null
        ? null
        : RegistryPath((openRegistryPath as List<Object?>).cast<String>());

    try {
      return RegistryRevisionState(
        projectId: projectId,
        projectAdapterId: projectAdapterId,
        sourceDocumentPath: sourceDocumentPath,
        currentRevision: currentRevision,
        previousRevision: previousRevision as String?,
        cleanBaselineRevision: cleanBaselineRevision as String?,
        openRegistryNodeId: openRegistryNodeId == null
            ? null
            : RegistryNodeId(openRegistryNodeId as String),
        openRegistryPath: restoredOpenRegistryPath,
        selectedProblemIndex: selectedProblemIndex as int?,
        searchQuery: searchQuery,
        registryViewFilter: registryViewFilter,
        canonicalStatusFilter: canonicalStatusFilter,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        'Registry revision state values '
        'are invalid.',
        error,
      );
    }
  }

  @override
  Future<void> saveRevisionState(RegistryRevisionState state) async {
    final Directory supportDirectory;

    if (applicationSupportDirectory != null) {
      supportDirectory = applicationSupportDirectory!;
    } else {
      final String? applicationSupportPath = await PathProviderAndroid()
          .getApplicationSupportPath();

      if (applicationSupportPath == null ||
          applicationSupportPath.trim().isEmpty) {
        throw StateError(
          'Android application support directory '
          'is unavailable.',
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

    try {
      await temporaryFile.writeAsString(
        '${jsonEncode(<String, Object?>{'version': _formatVersion, 'projectId': state.projectId, 'projectAdapterId': state.projectAdapterId, 'sourceDocumentPath': state.sourceDocumentPath, 'currentRevision': state.currentRevision, 'previousRevision': state.previousRevision, 'cleanBaselineRevision': state.cleanBaselineRevision, 'openRegistryNodeId': state.openRegistryNodeId?.value, 'openRegistryPath': state.openRegistryPath?.segments, 'selectedProblemIndex': state.selectedProblemIndex, 'searchQuery': state.searchQuery, 'registryViewFilter': state.registryViewFilter, 'canonicalStatusFilter': state.canonicalStatusFilter})}\n',
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
