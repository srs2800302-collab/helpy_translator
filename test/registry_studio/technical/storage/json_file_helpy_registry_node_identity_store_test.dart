import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';
import 'package:helpy_translator/registry_studio/technical/storage/json_file_helpy_registry_node_identity_store.dart';

void main() {
  group('JsonFileHelpyRegistryNodeIdentityStore', () {
    test('persists and restores stable local identities', () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'helpy_registry_node_identity_store_',
      );

      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final JsonFileHelpyRegistryNodeIdentityStore store =
          JsonFileHelpyRegistryNodeIdentityStore(
            applicationSupportDirectory: directory,
          );

      final RegistryPath domainPath = RegistryPath(const <String>[
        'Registry',
        'Domain',
      ]);

      final RegistryPath otherPath = RegistryPath(const <String>[
        'Registry',
        'Other',
      ]);

      expect(await store.loadIdentities(), isEmpty);

      await store.saveIdentities(<RegistryPath, RegistryNodeId>{
        otherPath: RegistryNodeId('helpy.registry.node.000536'),
        domainPath: RegistryNodeId('helpy.registry.node.000535'),
      });

      final Map<RegistryPath, RegistryNodeId> restored = await store
          .loadIdentities();

      expect(restored, <RegistryPath, RegistryNodeId>{
        domainPath: RegistryNodeId('helpy.registry.node.000535'),
        otherPath: RegistryNodeId('helpy.registry.node.000536'),
      });

      final File stateFile = File(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.directoryName}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.fileName}',
      );

      final Map<String, dynamic> encoded =
          jsonDecode(await stateFile.readAsString()) as Map<String, dynamic>;

      final List<dynamic> entries = encoded['entries'] as List<dynamic>;

      expect(encoded['version'], 'v1');
      expect(encoded['projectId'], 'helpy');

      expect((entries.first as Map<String, dynamic>)['headingPath'], <String>[
        'Registry',
        'Domain',
      ]);
    });

    test('rejects duplicate node identities in persisted state', () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'helpy_registry_node_identity_store_invalid_',
      );

      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final Directory stateDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.directoryName}',
      );

      await stateDirectory.create(recursive: true);

      final File stateFile = File(
        '${stateDirectory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.fileName}',
      );

      await stateFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v1',
          'projectId': 'helpy',
          'entries': <Map<String, Object?>>[
            <String, Object?>{
              'nodeId': 'helpy.registry.node.000535',
              'headingPath': <String>['Registry', 'Domain'],
            },
            <String, Object?>{
              'nodeId': 'helpy.registry.node.000535',
              'headingPath': <String>['Registry', 'Other'],
            },
          ],
        }),
      );

      final JsonFileHelpyRegistryNodeIdentityStore store =
          JsonFileHelpyRegistryNodeIdentityStore(
            applicationSupportDirectory: directory,
          );

      await expectLater(
        store.loadIdentities(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
