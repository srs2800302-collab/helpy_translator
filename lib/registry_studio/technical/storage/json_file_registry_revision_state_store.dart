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
  static const String fileName = 'registry_revision_state_v3.json';
  static const String previousFileName = 'registry_revision_state_v2.json';
  static const String legacyFileName = 'registry_revision_state_v1.json';

  static const String _formatVersion = 'v3';
  static const String _previousFormatVersion = 'v2';
  static const String _legacyFormatVersion = 'v1';

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

    final File currentStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$fileName',
    );

    final File previousStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$previousFileName',
    );

    final File legacyStateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$legacyFileName',
    );

    final File stateFile;

    if (await currentStateFile.exists()) {
      stateFile = currentStateFile;
    } else if (await previousStateFile.exists()) {
      stateFile = previousStateFile;
    } else if (await legacyStateFile.exists()) {
      stateFile = legacyStateFile;
    } else {
      return null;
    }

    final Object? decodedState = jsonDecode(await stateFile.readAsString());

    if (decodedState is! Map<Object?, Object?>) {
      throw const FormatException(
        'Registry revision state must be a JSON object.',
      );
    }

    if (decodedState.keys.any((Object? key) => key is! String)) {
      throw const FormatException(
        'Registry revision state keys must be strings.',
      );
    }

    final Map<String, Object?> state = decodedState.cast<String, Object?>();

    final Object? version = state['version'];
    final Set<String> expectedKeys;

    if (version == _legacyFormatVersion) {
      expectedKeys = const <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
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
        'selectedProblemNodeId',
        'selectedProblemPath',
        'selectedProblemIndex',
      };
    } else {
      throw const FormatException(
        'Registry revision state version is unsupported.',
      );
    }

    final Set<String> actualKeys = state.keys.toSet();

    if (actualKeys.length != expectedKeys.length ||
        !actualKeys.containsAll(expectedKeys)) {
      throw const FormatException('Registry revision state schema is invalid.');
    }

    final Object? projectId = state['projectId'];
    final Object? projectAdapterId = state['projectAdapterId'];
    final Object? sourceDocumentPath = state['sourceDocumentPath'];
    final Object? currentRevision = state['currentRevision'];
    final Object? previousRevision = state['previousRevision'];

    final bool includesCleanBaseline =
        version == _previousFormatVersion || version == _formatVersion;

    final Object? cleanBaselineRevision = includesCleanBaseline
        ? state['cleanBaselineRevision']
        : null;

    final Object? selectedProblemNodeId = version == _formatVersion
        ? state['selectedProblemNodeId']
        : null;

    final Object? selectedProblemPath = version == _formatVersion
        ? state['selectedProblemPath']
        : null;

    final Object? selectedProblemIndex = version == _formatVersion
        ? state['selectedProblemIndex']
        : null;

    final bool selectedProblemPathInvalid =
        selectedProblemPath != null &&
        (selectedProblemPath is! List<Object?> ||
            selectedProblemPath.any((Object? segment) => segment is! String));

    if (projectId is! String ||
        projectAdapterId is! String ||
        sourceDocumentPath is! String ||
        currentRevision is! String ||
        (previousRevision != null && previousRevision is! String) ||
        (cleanBaselineRevision != null && cleanBaselineRevision is! String) ||
        (selectedProblemNodeId != null && selectedProblemNodeId is! String) ||
        selectedProblemPathInvalid ||
        (selectedProblemIndex != null && selectedProblemIndex is! int)) {
      throw const FormatException(
        'Registry revision state field types are invalid.',
      );
    }

    try {
      return RegistryRevisionState(
        projectId: projectId,
        projectAdapterId: projectAdapterId,
        sourceDocumentPath: sourceDocumentPath,
        currentRevision: currentRevision,
        previousRevision: previousRevision as String?,
        cleanBaselineRevision: cleanBaselineRevision as String?,
        selectedProblemNodeId: selectedProblemNodeId == null
            ? null
            : RegistryNodeId(selectedProblemNodeId as String),
        selectedProblemPath: selectedProblemPath == null
            ? null
            : RegistryPath(
                (selectedProblemPath as List<Object?>).cast<String>(),
              ),
        selectedProblemIndex: selectedProblemIndex as int?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        'Registry revision state values are invalid.',
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

    try {
      await temporaryFile.writeAsString(
        '${jsonEncode(<String, Object?>{'version': _formatVersion, 'projectId': state.projectId, 'projectAdapterId': state.projectAdapterId, 'sourceDocumentPath': state.sourceDocumentPath, 'currentRevision': state.currentRevision, 'previousRevision': state.previousRevision, 'cleanBaselineRevision': state.cleanBaselineRevision, 'selectedProblemNodeId': state.selectedProblemNodeId?.value, 'selectedProblemPath': state.selectedProblemPath?.segments, 'selectedProblemIndex': state.selectedProblemIndex})}\n',
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
