import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/json_file_helpy_registry_node_identity_store.dart';

void main() {
  group('JsonFileHelpyRegistryNodeIdentityStore', () {
    test('persists isolated local identities for exact revisions', () async {
      const String revisionA = '1111111111111111111111111111111111111111';

      const String revisionB = '2222222222222222222222222222222222222222';

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

      expect(await store.loadIdentities(revisionA), isEmpty);
      expect(await store.loadIdentities(revisionB), isEmpty);

      await store.saveIdentities(revisionA, <RegistryPath, RegistryNodeId>{
        domainPath: RegistryNodeId('helpy.registry.node.000535'),
      });

      await store.saveIdentities(revisionB, <RegistryPath, RegistryNodeId>{
        otherPath: RegistryNodeId('helpy.registry.node.000536'),
      });

      expect(
        await store.loadIdentities(revisionA),
        <RegistryPath, RegistryNodeId>{
          domainPath: RegistryNodeId('helpy.registry.node.000535'),
        },
      );

      expect(
        await store.loadIdentities(revisionB),
        <RegistryPath, RegistryNodeId>{
          otherPath: RegistryNodeId('helpy.registry.node.000536'),
        },
      );

      final File revisionAFile = File(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.directoryName}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.revisionDirectoryName}'
        '${Platform.pathSeparator}'
        '$revisionA.json',
      );

      final Map<String, dynamic> encoded =
          jsonDecode(await revisionAFile.readAsString())
              as Map<String, dynamic>;

      expect(encoded['version'], 'v2');
      expect(encoded['projectId'], 'helpy');
      expect(encoded['sourceRevision'], revisionA);

      final List<dynamic> entries = encoded['entries'] as List<dynamic>;

      expect((entries.single as Map<String, dynamic>)['headingPath'], <String>[
        'Registry',
        'Domain',
      ]);
    });

    test('migrates legacy identities into the first loaded revision', () async {
      const String currentRevision = '3333333333333333333333333333333333333333';

      const String historicalRevision =
          '4444444444444444444444444444444444444444';

      final Directory directory = await Directory.systemTemp.createTemp(
        'helpy_registry_node_identity_store_legacy_',
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

      final File legacyFile = File(
        '${stateDirectory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.legacyFileName}',
      );

      await legacyFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v1',
          'projectId': 'helpy',
          'entries': <Map<String, Object?>>[
            <String, Object?>{
              'nodeId': 'helpy.registry.node.000535',
              'headingPath': <String>['Registry', 'Domain'],
            },
          ],
        }),
      );

      final JsonFileHelpyRegistryNodeIdentityStore store =
          JsonFileHelpyRegistryNodeIdentityStore(
            applicationSupportDirectory: directory,
          );

      final Map<RegistryPath, RegistryNodeId> legacyIdentities = await store
          .loadIdentities(currentRevision);

      expect(legacyIdentities, hasLength(1));

      await store.saveIdentities(currentRevision, legacyIdentities);

      expect(await legacyFile.exists(), isFalse);

      expect(await store.loadIdentities(currentRevision), legacyIdentities);

      expect(await store.loadIdentities(historicalRevision), isEmpty);
    });

    test('rejects duplicate identities in revision state', () async {
      const String revision = '5555555555555555555555555555555555555555';

      final Directory directory = await Directory.systemTemp.createTemp(
        'helpy_registry_node_identity_store_invalid_',
      );

      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final Directory revisionDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.directoryName}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.revisionDirectoryName}',
      );

      await revisionDirectory.create(recursive: true);

      final File revisionFile = File(
        '${revisionDirectory.path}'
        '${Platform.pathSeparator}'
        '$revision.json',
      );

      await revisionFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v2',
          'projectId': 'helpy',
          'sourceRevision': revision,
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
        store.loadIdentities(revision),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
