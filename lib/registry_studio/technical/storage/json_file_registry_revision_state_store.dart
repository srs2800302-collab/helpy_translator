import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../../registry/application/contracts/registry_revision_state_store.dart';

final class JsonFileRegistryRevisionStateStore
    implements RegistryRevisionStateStore {
  const JsonFileRegistryRevisionStateStore({this.applicationSupportDirectory});

  static const String directoryName = 'registry_studio';
  static const String fileName = 'registry_revision_state_v1.json';
  static const String _formatVersion = 'v1';

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

    final File stateFile = File(
      '${stateDirectory.path}'
      '${Platform.pathSeparator}'
      '$fileName',
    );

    if (!await stateFile.exists()) {
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

    const Set<String> expectedKeys = <String>{
      'version',
      'projectId',
      'projectAdapterId',
      'sourceDocumentPath',
      'currentRevision',
      'previousRevision',
    };

    final Set<String> actualKeys = state.keys.toSet();

    if (actualKeys.length != expectedKeys.length ||
        !actualKeys.containsAll(expectedKeys)) {
      throw const FormatException('Registry revision state schema is invalid.');
    }

    if (state['version'] != _formatVersion) {
      throw const FormatException(
        'Registry revision state version is unsupported.',
      );
    }

    final Object? projectId = state['projectId'];
    final Object? projectAdapterId = state['projectAdapterId'];
    final Object? sourceDocumentPath = state['sourceDocumentPath'];
    final Object? currentRevision = state['currentRevision'];
    final Object? previousRevision = state['previousRevision'];

    if (projectId is! String ||
        projectAdapterId is! String ||
        sourceDocumentPath is! String ||
        currentRevision is! String ||
        previousRevision != null && previousRevision is! String) {
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
        '${jsonEncode(<String, Object?>{'version': _formatVersion, 'projectId': state.projectId, 'projectAdapterId': state.projectAdapterId, 'sourceDocumentPath': state.sourceDocumentPath, 'currentRevision': state.currentRevision, 'previousRevision': state.previousRevision})}\n',
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
