import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';
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
        'including clean baseline and problem navigation', () async {
      final RegistryRevisionState firstState = RegistryRevisionState(
        projectId: 'project',
        projectAdapterId: 'project.adapter',
        sourceDocumentPath: 'registry.md',
        currentRevision: 'revision-a',
        previousRevision: 'revision-b',
        cleanBaselineRevision: 'revision-clean',
        selectedProblemNodeId: RegistryNodeId('project.registry.node.000003'),
        selectedProblemPath: RegistryPath(const <String>[
          'Registry',
          'Added Domain',
        ]),
        selectedProblemIndex: 4,
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
      expect(
        restored.selectedProblemNodeId,
        RegistryNodeId('project.registry.node.000003'),
      );
      expect(
        restored.selectedProblemPath,
        RegistryPath(const <String>['Registry', 'Added Domain']),
      );
      expect(restored.selectedProblemIndex, 4);

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
        'selectedProblemNodeId',
        'selectedProblemPath',
        'selectedProblemIndex',
      });

      expect(encodedState['version'], 'v3');
      expect(
        encodedState['selectedProblemNodeId'],
        'project.registry.node.000003',
      );
      expect(encodedState['selectedProblemPath'], <String>[
        'Registry',
        'Added Domain',
      ]);
      expect(encodedState['selectedProblemIndex'], 4);
      expect(encodedState.containsKey('roots'), isFalse);
      expect(encodedState.containsKey('sourceContent'), isFalse);
      expect(encodedState.containsKey('problems'), isFalse);

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
      expect(restored.selectedProblemNodeId, isNull);
      expect(restored.selectedProblemPath, isNull);
      expect(restored.selectedProblemIndex, isNull);
    });

    test('restores previous v2 state without problem navigation', () async {
      final Directory stateDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.directoryName}',
      );

      await stateDirectory.create(recursive: true);

      final File previousStateFile = File(
        '${stateDirectory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.previousFileName}',
      );

      await previousStateFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v2',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-b',
          'cleanBaselineRevision': 'revision-clean',
        }),
        flush: true,
      );

      final RegistryRevisionState? restored = await store.loadRevisionState();

      expect(restored, isNotNull);
      expect(restored!.currentRevision, 'revision-a');
      expect(restored.previousRevision, 'revision-b');
      expect(restored.cleanBaselineRevision, 'revision-clean');
      expect(restored.selectedProblemNodeId, isNull);
      expect(restored.selectedProblemPath, isNull);
      expect(restored.selectedProblemIndex, isNull);
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
      expect(restored.selectedProblemNodeId, isNull);
      expect(restored.selectedProblemPath, isNull);
      expect(restored.selectedProblemIndex, isNull);
    });

    test('rejects malformed persisted state values', () async {
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
          'version': 'v3',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-a',
          'cleanBaselineRevision': null,
          'selectedProblemNodeId': null,
          'selectedProblemPath': null,
          'selectedProblemIndex': null,
        }),
        flush: true,
      );

      await expectLater(
        store.loadRevisionState(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects incomplete persisted problem navigation', () async {
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
          'version': 'v3',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-b',
          'cleanBaselineRevision': null,
          'selectedProblemNodeId': 'project.registry.node.000003',
          'selectedProblemPath': null,
          'selectedProblemIndex': null,
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
