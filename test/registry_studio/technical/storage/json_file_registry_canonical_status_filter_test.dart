import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import 'package:helpy_translator/registry_studio/technical/storage/json_file_registry_revision_state_store.dart';

void main() {
  late Directory supportDirectory;
  late JsonFileRegistryRevisionStateStore store;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'registry-canonical-status-filter-',
    );

    store = JsonFileRegistryRevisionStateStore(
      applicationSupportDirectory: supportDirectory,
    );
  });

  tearDown(() async {
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test('persists canonical status filter in v7 Registry state', () async {
    await store.saveRevisionState(
      RegistryRevisionState(
        projectId: 'project',
        projectAdapterId: 'project.adapter',
        sourceDocumentPath: 'registry.md',
        currentRevision: 'revision-1',
        registryViewFilter: 'branches',
        canonicalStatusFilter: 'review',
      ),
    );

    final RegistryRevisionState restored = (await store.loadRevisionState())!;

    expect(restored.registryViewFilter, 'branches');
    expect(restored.canonicalStatusFilter, 'review');

    final File stateFile = File(
      '${supportDirectory.path}/'
      '${JsonFileRegistryRevisionStateStore.directoryName}/'
      '${JsonFileRegistryRevisionStateStore.fileName}',
    );

    final Map<String, Object?> encoded =
        (jsonDecode(await stateFile.readAsString()) as Map<Object?, Object?>)
            .cast<String, Object?>();

    expect(encoded['version'], 'v7');
    expect(encoded['canonicalStatusFilter'], 'review');
  });

  test('migrates v6 Registry state with canonical filter set to all', () async {
    final Directory stateDirectory = Directory(
      '${supportDirectory.path}/'
      '${JsonFileRegistryRevisionStateStore.directoryName}',
    );

    await stateDirectory.create(recursive: true);

    final File v6File = File(
      '${stateDirectory.path}/'
      '${JsonFileRegistryRevisionStateStore.currentPreviousFileName}',
    );

    await v6File.writeAsString(
      '${jsonEncode(<String, Object?>{'version': 'v6', 'projectId': 'project', 'projectAdapterId': 'project.adapter', 'sourceDocumentPath': 'registry.md', 'currentRevision': 'revision-1', 'previousRevision': null, 'cleanBaselineRevision': null, 'openRegistryNodeId': null, 'openRegistryPath': null, 'selectedProblemIndex': null, 'searchQuery': '', 'registryViewFilter': 'leaves'})}\n',
      flush: true,
    );

    final RegistryRevisionState restored = (await store.loadRevisionState())!;

    expect(restored.registryViewFilter, 'leaves');
    expect(restored.canonicalStatusFilter, 'all');
  });
}
