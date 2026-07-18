import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import 'package:helpy_translator/registry_studio/technical/storage/json_file_registry_revision_state_store.dart';

void main() {
  group('JsonFileRegistryRevisionStateStore', () {
    late Directory directory;
    late JsonFileRegistryRevisionStateStore store;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'registry-revision-state-',
      );

      store = JsonFileRegistryRevisionStateStore(
        applicationSupportDirectory: directory,
      );
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('returns no state when the persisted file is absent', () async {
      expect(await store.loadRevisionState(), isNull);
    });

    test('persists and replaces Registry revision coordinates '
        'including clean baseline', () async {
      final RegistryRevisionState firstState = RegistryRevisionState(
        projectId: 'project',
        projectAdapterId: 'project.adapter',
        sourceDocumentPath: 'registry.md',
        currentRevision: 'revision-a',
        previousRevision: 'revision-b',
        cleanBaselineRevision: 'revision-clean',
      );

      await store.saveRevisionState(firstState);

      RegistryRevisionState? restored = await store.loadRevisionState();

      expect(restored, isNotNull);
      expect(restored!.projectId, 'project');
      expect(restored.projectAdapterId, 'project.adapter');
      expect(restored.sourceDocumentPath, 'registry.md');
      expect(restored.currentRevision, 'revision-a');
      expect(restored.previousRevision, 'revision-b');
      expect(restored.cleanBaselineRevision, 'revision-clean');

      final File stateFile = File(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.directoryName}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.fileName}',
      );

      final Object? decoded = jsonDecode(await stateFile.readAsString());

      expect(decoded, isA<Map<String, dynamic>>());

      final Map<String, dynamic> encodedState =
          decoded! as Map<String, dynamic>;

      expect(encodedState.keys, <String>{
        'version',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'currentRevision',
        'previousRevision',
        'cleanBaselineRevision',
      });

      expect(encodedState['version'], 'v2');
      expect(encodedState.containsKey('roots'), isFalse);
      expect(encodedState.containsKey('sourceContent'), isFalse);

      final RegistryRevisionState replacementState = RegistryRevisionState(
        projectId: 'project',
        projectAdapterId: 'project.adapter',
        sourceDocumentPath: 'registry.md',
        currentRevision: 'revision-c',
        previousRevision: 'revision-a',
        cleanBaselineRevision: 'revision-a',
      );

      await store.saveRevisionState(replacementState);

      restored = await store.loadRevisionState();

      expect(restored!.currentRevision, 'revision-c');
      expect(restored.previousRevision, 'revision-a');
      expect(restored.cleanBaselineRevision, 'revision-a');
    });

    test('restores legacy v1 state without a clean baseline', () async {
      final Directory stateDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.directoryName}',
      );

      await stateDirectory.create(recursive: true);

      final File legacyStateFile = File(
        '${stateDirectory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.legacyFileName}',
      );

      await legacyStateFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v1',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-b',
        }),
        flush: true,
      );

      final RegistryRevisionState? restored = await store.loadRevisionState();

      expect(restored, isNotNull);
      expect(restored!.currentRevision, 'revision-a');
      expect(restored.previousRevision, 'revision-b');
      expect(restored.cleanBaselineRevision, isNull);
    });

    test('rejects malformed persisted state', () async {
      final Directory stateDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.directoryName}',
      );

      await stateDirectory.create(recursive: true);

      final File stateFile = File(
        '${stateDirectory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.fileName}',
      );

      await stateFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v2',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-a',
          'cleanBaselineRevision': null,
        }),
        flush: true,
      );

      await expectLater(
        store.loadRevisionState(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
