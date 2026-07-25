import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/application/contracts/helpy_registry_node_identity_store.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/json_file_helpy_registry_node_identity_store.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('JsonFileHelpyRegistryNodeIdentityStore', () {
    test('persists isolated active and retired identities', () async {
      const String revisionA = '1111111111111111111111111111111111111111';

      const String revisionB = '2222222222222222222222222222222222222222';

      final Directory directory = await Directory.systemTemp.createTemp(
        'helpy_registry_node_identity_state_',
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

      final HelpyRegistryNodeIdentityState emptyA = await store.loadState(
        revisionA,
      );

      final HelpyRegistryNodeIdentityState emptyB = await store.loadState(
        revisionB,
      );

      expect(emptyA.localIdentitiesByPath, isEmpty);
      expect(emptyA.retiredNodeIds, isEmpty);
      expect(emptyB.localIdentitiesByPath, isEmpty);
      expect(emptyB.retiredNodeIds, isEmpty);

      await store.saveState(
        revisionA,
        HelpyRegistryNodeIdentityState(
          localIdentitiesByPath: <RegistryPath, RegistryNodeId>{
            domainPath: RegistryNodeId('helpy.registry.node.000535'),
          },
          retiredNodeIds: <RegistryNodeId>{
            RegistryNodeId('helpy.registry.node.000534'),
          },
        ),
      );

      await store.saveState(
        revisionB,
        HelpyRegistryNodeIdentityState(
          localIdentitiesByPath: <RegistryPath, RegistryNodeId>{
            otherPath: RegistryNodeId('helpy.registry.node.000536'),
          },
        ),
      );

      final HelpyRegistryNodeIdentityState loadedA = await store.loadState(
        revisionA,
      );

      final HelpyRegistryNodeIdentityState loadedB = await store.loadState(
        revisionB,
      );

      expect(loadedA.localIdentitiesByPath, <RegistryPath, RegistryNodeId>{
        domainPath: RegistryNodeId('helpy.registry.node.000535'),
      });

      expect(loadedA.retiredNodeIds, <RegistryNodeId>{
        RegistryNodeId('helpy.registry.node.000534'),
      });

      expect(loadedB.localIdentitiesByPath, <RegistryPath, RegistryNodeId>{
        otherPath: RegistryNodeId('helpy.registry.node.000536'),
      });

      expect(loadedB.retiredNodeIds, isEmpty);

      final File revisionAFile = File(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.directoryName}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.revisionDirectoryName}'
        '${Platform.pathSeparator}'
        '$revisionA.json',
      );

      final Object? decoded = jsonDecode(await revisionAFile.readAsString());

      expect(decoded, isA<Map<Object?, Object?>>());

      final Map<String, Object?> encoded = (decoded! as Map<Object?, Object?>)
          .cast<String, Object?>();

      expect(encoded['version'], 'v3');
      expect(encoded['projectId'], 'helpy');
      expect(encoded['sourceRevision'], revisionA);
      expect(encoded['retiredNodeIds'], <Object?>[
        'helpy.registry.node.000534',
      ]);
    });

    test('quarantines revision v2 identities when v3 is saved', () async {
      const String revision = '3333333333333333333333333333333333333333';

      final Directory directory = await Directory.systemTemp.createTemp(
        'helpy_registry_node_identity_state_v2_',
      );

      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final Directory legacyRevisionDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.directoryName}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.legacyRevisionDirectoryName}',
      );

      await legacyRevisionDirectory.create(recursive: true);

      final File legacyRevisionFile = File(
        '${legacyRevisionDirectory.path}'
        '${Platform.pathSeparator}'
        '$revision.json',
      );

      await legacyRevisionFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 'v2',
          'projectId': 'helpy',
          'sourceRevision': revision,
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

      final HelpyRegistryNodeIdentityState migrated = await store.loadState(
        revision,
      );

      expect(migrated.localIdentitiesByPath, isEmpty);

      expect(migrated.retiredNodeIds, <RegistryNodeId>{
        RegistryNodeId('helpy.registry.node.000535'),
      });

      await store.saveState(revision, migrated);

      expect(await legacyRevisionFile.exists(), isFalse);

      final File currentRevisionFile = File(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.directoryName}'
        '${Platform.pathSeparator}'
        '${JsonFileHelpyRegistryNodeIdentityStore.revisionDirectoryName}'
        '${Platform.pathSeparator}'
        '$revision.json',
      );

      expect(await currentRevisionFile.exists(), isTrue);

      final HelpyRegistryNodeIdentityState reloaded = await store.loadState(
        revision,
      );

      expect(reloaded.localIdentitiesByPath, isEmpty);

      expect(reloaded.retiredNodeIds, <RegistryNodeId>{
        RegistryNodeId('helpy.registry.node.000535'),
      });
    });

    test('quarantines global v1 identities in loaded revision', () async {
      const String currentRevision = '4444444444444444444444444444444444444444';

      const String historicalRevision =
          '5555555555555555555555555555555555555555';

      final Directory directory = await Directory.systemTemp.createTemp(
        'helpy_registry_node_identity_state_v1_',
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

      final HelpyRegistryNodeIdentityState legacyState = await store.loadState(
        currentRevision,
      );

      expect(legacyState.localIdentitiesByPath, isEmpty);

      expect(legacyState.retiredNodeIds, <RegistryNodeId>{
        RegistryNodeId('helpy.registry.node.000535'),
      });

      await store.saveState(currentRevision, legacyState);

      expect(await legacyFile.exists(), isFalse);

      final HelpyRegistryNodeIdentityState currentState = await store.loadState(
        currentRevision,
      );

      expect(currentState.localIdentitiesByPath, isEmpty);

      expect(currentState.retiredNodeIds, <RegistryNodeId>{
        RegistryNodeId('helpy.registry.node.000535'),
      });

      final HelpyRegistryNodeIdentityState historicalState = await store
          .loadState(historicalRevision);

      expect(historicalState.localIdentitiesByPath, isEmpty);
      expect(historicalState.retiredNodeIds, isEmpty);
    });

    test('rejects identity that is active and retired', () async {
      const String revision = '6666666666666666666666666666666666666666';

      final Directory directory = await Directory.systemTemp.createTemp(
        'helpy_registry_node_identity_state_invalid_',
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

      final RegistryNodeId duplicatedNodeId = RegistryNodeId(
        'helpy.registry.node.000535',
      );

      await expectLater(
        store.saveState(
          revision,
          HelpyRegistryNodeIdentityState(
            localIdentitiesByPath: <RegistryPath, RegistryNodeId>{
              RegistryPath(const <String>['Registry', 'Domain']):
                  duplicatedNodeId,
            },
            retiredNodeIds: <RegistryNodeId>{duplicatedNodeId},
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
