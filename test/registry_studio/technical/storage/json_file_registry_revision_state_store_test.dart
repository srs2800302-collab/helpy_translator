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
        'including generic open context and problem position', () async {
      final RegistryRevisionState firstState = RegistryRevisionState(
        projectId: 'project',
        projectAdapterId: 'project.adapter',
        sourceDocumentPath: 'registry.md',
        currentRevision: 'revision-a',
        previousRevision: 'revision-b',
        cleanBaselineRevision: 'revision-clean',
        openRegistryNodeId: RegistryNodeId('project.registry.node.000003'),
        openRegistryPath: RegistryPath(const <String>[
          'Registry',
          'Added Domain',
        ]),
        selectedProblemIndex: 4,
        searchQuery: '  exact Registry query  ',
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
        restored.openRegistryNodeId,
        RegistryNodeId('project.registry.node.000003'),
      );
      expect(
        restored.openRegistryPath,
        RegistryPath(const <String>['Registry', 'Added Domain']),
      );
      expect(restored.selectedProblemIndex, 4);
      expect(restored.searchQuery, '  exact Registry query  ');

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
        'openRegistryNodeId',
        'openRegistryPath',
        'selectedProblemIndex',
        'searchQuery',
      });

      expect(encodedState['version'], 'v5');
      expect(encodedState['searchQuery'], '  exact Registry query  ');
      expect(
        encodedState['openRegistryNodeId'],
        'project.registry.node.000003',
      );
      expect(encodedState['openRegistryPath'], <String>[
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
        searchQuery: 'kind:rule',
      );

      await store.saveRevisionState(replacementState);

      restored = await store.loadRevisionState();

      expect(restored!.currentRevision, 'revision-c');
      expect(restored.previousRevision, 'revision-a');
      expect(restored.cleanBaselineRevision, 'revision-a');
      expect(restored.openRegistryNodeId, isNull);
      expect(restored.openRegistryPath, isNull);
      expect(restored.selectedProblemIndex, isNull);
      expect(restored.searchQuery, 'kind:rule');
    });

    test('migrates previous v4 state with an empty search query', () async {
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
          'version': 'v4',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-b',
          'cleanBaselineRevision': 'revision-clean',
          'openRegistryNodeId': 'project.registry.node.000003',
          'openRegistryPath': <String>['Registry', 'Added Domain'],
          'selectedProblemIndex': 4,
        }),
        flush: true,
      );

      final RegistryRevisionState? restored = await store.loadRevisionState();

      expect(restored, isNotNull);
      expect(
        restored!.openRegistryNodeId,
        RegistryNodeId('project.registry.node.000003'),
      );
      expect(
        restored.openRegistryPath,
        RegistryPath(const <String>['Registry', 'Added Domain']),
      );
      expect(restored.selectedProblemIndex, 4);
      expect(restored.searchQuery, isEmpty);
    });

    test('migrates previous v3 problem navigation '
        'to generic open Registry context', () async {
      final Directory stateDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.directoryName}',
      );

      await stateDirectory.create(recursive: true);

      final File previousStateFile = File(
        '${stateDirectory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.olderFileName}',
      );

      await previousStateFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v3',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-b',
          'cleanBaselineRevision': 'revision-clean',
          'selectedProblemNodeId': 'project.registry.node.000003',
          'selectedProblemPath': <String>['Registry', 'Added Domain'],
          'selectedProblemIndex': 4,
        }),
        flush: true,
      );

      final RegistryRevisionState? restored = await store.loadRevisionState();

      expect(restored, isNotNull);
      expect(
        restored!.openRegistryNodeId,
        RegistryNodeId('project.registry.node.000003'),
      );
      expect(
        restored.openRegistryPath,
        RegistryPath(const <String>['Registry', 'Added Domain']),
      );
      expect(restored.selectedProblemIndex, 4);
      expect(restored.searchQuery, isEmpty);
    });

    test('restores older v2 state without open Registry context', () async {
      final Directory stateDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.directoryName}',
      );

      await stateDirectory.create(recursive: true);

      final File previousStateFile = File(
        '${stateDirectory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileRegistryRevisionStateStore.legacyFileName}',
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
      expect(restored.openRegistryNodeId, isNull);
      expect(restored.openRegistryPath, isNull);
      expect(restored.selectedProblemIndex, isNull);
      expect(restored.searchQuery, isEmpty);
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
        '${JsonFileRegistryRevisionStateStore.oldestFileName}',
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
      expect(restored.openRegistryNodeId, isNull);
      expect(restored.openRegistryPath, isNull);
      expect(restored.selectedProblemIndex, isNull);
      expect(restored.searchQuery, isEmpty);
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
          'version': 'v5',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-a',
          'cleanBaselineRevision': null,
          'openRegistryNodeId': null,
          'openRegistryPath': null,
          'selectedProblemIndex': null,
          'searchQuery': '',
        }),
        flush: true,
      );

      await expectLater(
        store.loadRevisionState(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects incomplete persisted open Registry context', () async {
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
          'version': 'v5',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-b',
          'cleanBaselineRevision': null,
          'openRegistryNodeId': 'project.registry.node.000003',
          'openRegistryPath': null,
          'selectedProblemIndex': null,
          'searchQuery': '',
        }),
        flush: true,
      );

      await expectLater(
        store.loadRevisionState(),
        throwsA(isA<FormatException>()),
      );
    });
    test('rejects problem position without '
        'open Registry context', () async {
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
          'version': 'v5',
          'projectId': 'project',
          'projectAdapterId': 'project.adapter',
          'sourceDocumentPath': 'registry.md',
          'currentRevision': 'revision-a',
          'previousRevision': 'revision-b',
          'cleanBaselineRevision': null,
          'openRegistryNodeId': null,
          'openRegistryPath': null,
          'selectedProblemIndex': 0,
          'searchQuery': '',
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
