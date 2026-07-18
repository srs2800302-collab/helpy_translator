import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HelpyRegistryNodeIdentityLedgerSource', () {
    test('loads the registered production identity ledger asset', () async {
      final HelpyRegistryNodeIdentityLedgerSource source =
          HelpyRegistryNodeIdentityLedgerSource(assetBundle: rootBundle);

      final Map<RegistryPath, RegistryNodeId> identities = await source.load();

      expect(identities, isNotEmpty);
      expect(
        identities[RegistryPath(const <String>[
          'Helpy Architecture Registry v1 Foundation',
        ])],
        RegistryNodeId('helpy.registry.node.000001'),
      );
      expect(
        identities[RegistryPath(const <String>[
          'Helpy Architecture Registry v1 Foundation',
          'Contract Map / Architecture Groups',
        ])],
        RegistryNodeId('helpy.registry.node.000002'),
      );
    });

    test('loads a validated immutable path-to-identity lookup', () async {
      const String assetPath = 'ledger.json';

      final HelpyRegistryNodeIdentityLedgerSource source =
          HelpyRegistryNodeIdentityLedgerSource(
            assetBundle: _MemoryAssetBundle(<String, String>{
              assetPath: _validLedger,
            }),
            assetPath: assetPath,
          );

      final Map<RegistryPath, RegistryNodeId> identities = await source.load();

      expect(identities, hasLength(2));
      expect(
        identities[RegistryPath(const <String>['Registry'])],
        RegistryNodeId('helpy.registry.node.000001'),
      );
      expect(
        identities[RegistryPath(const <String>['Registry', 'Domain'])],
        RegistryNodeId('helpy.registry.node.000002'),
      );

      expect(
        () => identities[RegistryPath(const <String>['Registry', 'Other'])] =
            RegistryNodeId('helpy.registry.node.000003'),
        throwsUnsupportedError,
      );
    });

    test('rejects an invalid root schema or metadata', () async {
      const String assetPath = 'ledger.json';

      final HelpyRegistryNodeIdentityLedgerSource invalidSchemaSource =
          HelpyRegistryNodeIdentityLedgerSource(
            assetBundle: _MemoryAssetBundle(<String, String>{
              assetPath: '''
{
  "version": "v1",
  "projectId": "helpy",
  "registryDocumentPath": "docs/architecture/Helpy_Architecture_Registry_v1.md",
  "initialSourceRevision": "0123456789abcdef0123456789abcdef01234567",
  "initialSourceSnapshotFingerprint": "git-blob:89abcdef0123456789abcdef0123456789abcdef",
  "entries": [],
  "unexpected": true
}
''',
            }),
            assetPath: assetPath,
          );

      await expectLater(
        invalidSchemaSource.load(),
        throwsA(isA<FormatException>()),
      );

      final HelpyRegistryNodeIdentityLedgerSource invalidMetadataSource =
          HelpyRegistryNodeIdentityLedgerSource(
            assetBundle: _MemoryAssetBundle(<String, String>{
              assetPath: '''
{
  "version": "v1",
  "projectId": "another-project",
  "registryDocumentPath": "docs/architecture/Helpy_Architecture_Registry_v1.md",
  "initialSourceRevision": "0123456789abcdef0123456789abcdef01234567",
  "initialSourceSnapshotFingerprint": "git-blob:89abcdef0123456789abcdef0123456789abcdef",
  "entries": [
    {
      "nodeId": "helpy.registry.node.000001",
      "headingPath": ["Registry"],
      "parentNodeId": null
    }
  ]
}
''',
            }),
            assetPath: assetPath,
          );

      await expectLater(
        invalidMetadataSource.load(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects duplicate node identities and heading paths', () async {
      const String assetPath = 'ledger.json';

      final HelpyRegistryNodeIdentityLedgerSource duplicateIdentitySource =
          HelpyRegistryNodeIdentityLedgerSource(
            assetBundle: _MemoryAssetBundle(<String, String>{
              assetPath: '''
{
  "version": "v1",
  "projectId": "helpy",
  "registryDocumentPath": "docs/architecture/Helpy_Architecture_Registry_v1.md",
  "initialSourceRevision": "0123456789abcdef0123456789abcdef01234567",
  "initialSourceSnapshotFingerprint": "git-blob:89abcdef0123456789abcdef0123456789abcdef",
  "entries": [
    {
      "nodeId": "helpy.registry.node.000001",
      "headingPath": ["Registry"],
      "parentNodeId": null
    },
    {
      "nodeId": "helpy.registry.node.000001",
      "headingPath": ["Other"],
      "parentNodeId": null
    }
  ]
}
''',
            }),
            assetPath: assetPath,
          );

      await expectLater(
        duplicateIdentitySource.load(),
        throwsA(isA<FormatException>()),
      );

      final HelpyRegistryNodeIdentityLedgerSource duplicatePathSource =
          HelpyRegistryNodeIdentityLedgerSource(
            assetBundle: _MemoryAssetBundle(<String, String>{
              assetPath: '''
{
  "version": "v1",
  "projectId": "helpy",
  "registryDocumentPath": "docs/architecture/Helpy_Architecture_Registry_v1.md",
  "initialSourceRevision": "0123456789abcdef0123456789abcdef01234567",
  "initialSourceSnapshotFingerprint": "git-blob:89abcdef0123456789abcdef0123456789abcdef",
  "entries": [
    {
      "nodeId": "helpy.registry.node.000001",
      "headingPath": ["Registry"],
      "parentNodeId": null
    },
    {
      "nodeId": "helpy.registry.node.000002",
      "headingPath": ["Registry"],
      "parentNodeId": null
    }
  ]
}
''',
            }),
            assetPath: assetPath,
          );

      await expectLater(
        duplicatePathSource.load(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown or structurally inconsistent parents', () async {
      const String assetPath = 'ledger.json';

      final HelpyRegistryNodeIdentityLedgerSource unknownParentSource =
          HelpyRegistryNodeIdentityLedgerSource(
            assetBundle: _MemoryAssetBundle(<String, String>{
              assetPath: '''
{
  "version": "v1",
  "projectId": "helpy",
  "registryDocumentPath": "docs/architecture/Helpy_Architecture_Registry_v1.md",
  "initialSourceRevision": "0123456789abcdef0123456789abcdef01234567",
  "initialSourceSnapshotFingerprint": "git-blob:89abcdef0123456789abcdef0123456789abcdef",
  "entries": [
    {
      "nodeId": "helpy.registry.node.000001",
      "headingPath": ["Registry"],
      "parentNodeId": null
    },
    {
      "nodeId": "helpy.registry.node.000002",
      "headingPath": ["Registry", "Domain"],
      "parentNodeId": "helpy.registry.node.999999"
    }
  ]
}
''',
            }),
            assetPath: assetPath,
          );

      await expectLater(
        unknownParentSource.load(),
        throwsA(isA<FormatException>()),
      );

      final HelpyRegistryNodeIdentityLedgerSource invalidPrefixSource =
          HelpyRegistryNodeIdentityLedgerSource(
            assetBundle: _MemoryAssetBundle(<String, String>{
              assetPath: '''
{
  "version": "v1",
  "projectId": "helpy",
  "registryDocumentPath": "docs/architecture/Helpy_Architecture_Registry_v1.md",
  "initialSourceRevision": "0123456789abcdef0123456789abcdef01234567",
  "initialSourceSnapshotFingerprint": "git-blob:89abcdef0123456789abcdef0123456789abcdef",
  "entries": [
    {
      "nodeId": "helpy.registry.node.000001",
      "headingPath": ["Registry"],
      "parentNodeId": null
    },
    {
      "nodeId": "helpy.registry.node.000002",
      "headingPath": ["Other", "Domain"],
      "parentNodeId": "helpy.registry.node.000001"
    }
  ]
}
''',
            }),
            assetPath: assetPath,
          );

      await expectLater(
        invalidPrefixSource.load(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid identity values and empty asset paths', () async {
      expect(
        () => HelpyRegistryNodeIdentityLedgerSource(
          assetBundle: _MemoryAssetBundle(const <String, String>{}),
          assetPath: ' ',
        ),
        throwsArgumentError,
      );

      const String assetPath = 'ledger.json';

      final HelpyRegistryNodeIdentityLedgerSource invalidIdentitySource =
          HelpyRegistryNodeIdentityLedgerSource(
            assetBundle: _MemoryAssetBundle(<String, String>{
              assetPath: '''
{
  "version": "v1",
  "projectId": "helpy",
  "registryDocumentPath": "docs/architecture/Helpy_Architecture_Registry_v1.md",
  "initialSourceRevision": "0123456789abcdef0123456789abcdef01234567",
  "initialSourceSnapshotFingerprint": "git-blob:89abcdef0123456789abcdef0123456789abcdef",
  "entries": [
    {
      "nodeId": "Registry heading",
      "headingPath": ["Registry"],
      "parentNodeId": null
    }
  ]
}
''',
            }),
            assetPath: assetPath,
          );

      await expectLater(
        invalidIdentitySource.load(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

const String _validLedger = '''
{
  "version": "v1",
  "projectId": "helpy",
  "registryDocumentPath": "docs/architecture/Helpy_Architecture_Registry_v1.md",
  "initialSourceRevision": "0123456789abcdef0123456789abcdef01234567",
  "initialSourceSnapshotFingerprint": "git-blob:89abcdef0123456789abcdef0123456789abcdef",
  "entries": [
    {
      "nodeId": "helpy.registry.node.000001",
      "headingPath": ["Registry"],
      "parentNodeId": null
    },
    {
      "nodeId": "helpy.registry.node.000002",
      "headingPath": ["Registry", "Domain"],
      "parentNodeId": "helpy.registry.node.000001"
    }
  ]
}
''';

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final String? content = assets[key];

    if (content == null) {
      throw StateError('Missing test asset: $key');
    }

    final Uint8List bytes = Uint8List.fromList(utf8.encode(content));

    return ByteData.sublistView(bytes);
  }
}
