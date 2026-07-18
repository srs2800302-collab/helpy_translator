import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

const String _exactRevision = '0123456789abcdef0123456789abcdef01234567';

const String _blobSha = '89abcdef0123456789abcdef0123456789abcdef';

const String _ledgerRequestPath =
    '/repos/owner/repository/contents/'
    'docs/architecture/registry_studio/'
    'registry_node_identity_ledger_v1.json';

void main() {
  group('HelpyRegistryNodeIdentityLedgerSource', () {
    test('loads ledger content from a provided exact revision', () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );

      addTearDown(() async {
        await server.close(force: true);
      });

      final List<({String path, String? ref, String accept})> requests =
          <({String path, String? ref, String accept})>[];

      server.listen((HttpRequest request) async {
        final String accept =
            request.headers.value(HttpHeaders.acceptHeader) ?? '';

        requests.add((
          path: request.uri.path,
          ref: request.uri.queryParameters['ref'],
          accept: accept,
        ));

        if (request.uri.path == _ledgerRequestPath &&
            request.uri.queryParameters['ref'] == _exactRevision &&
            accept == 'application/vnd.github.object+json') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(<String, Object>{'type': 'file', 'sha': _blobSha}),
          );
          await request.response.close();
          return;
        }

        if (request.uri.path == _ledgerRequestPath &&
            request.uri.queryParameters['ref'] == _exactRevision &&
            accept == 'application/vnd.github.raw+json') {
          request.response.headers.contentType = ContentType.text;
          request.response.write(_validLedger);
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final HelpyRegistryNodeIdentityLedgerSource source =
          HelpyRegistryNodeIdentityLedgerSource(
            documentSource: GitHubRegistryDocumentSource(
              owner: 'owner',
              repository: 'repository',
              documentPath:
                  HelpyRegistryNodeIdentityLedgerSource.ledgerDocumentPath,
              ref: 'main',
              apiBaseUri: Uri.parse(
                'http://${server.address.address}:${server.port}/',
              ),
            ),
          );

      final HelpyRegistryNodeIdentityLedger ledger = await source.load(
        exactRevision: _exactRevision,
      );

      final RegistryNodeId rootId = RegistryNodeId(
        'helpy.registry.node.000001',
      );
      final RegistryNodeId domainId = RegistryNodeId(
        'helpy.registry.node.000002',
      );

      expect(ledger.version, 'v1');
      expect(ledger.projectId, 'helpy');
      expect(
        ledger.registryDocumentPath,
        HelpyRegistryNodeIdentityLedgerSource.registryDocumentPath,
      );
      expect(ledger.initialSourceRevision, _exactRevision);
      expect(ledger.initialSourceSnapshotFingerprint, 'git-blob:$_blobSha');
      expect(ledger.entries, hasLength(2));
      expect(ledger.entries[0].id, rootId);
      expect(ledger.entries[0].parentId, isNull);
      expect(ledger.entries[1].id, domainId);
      expect(ledger.entries[1].parentId, rootId);
      expect(ledger.identitiesByPath, hasLength(2));
      expect(
        ledger.identitiesByPath[RegistryPath(const <String>['Registry'])],
        rootId,
      );
      expect(
        ledger.identitiesByPath[RegistryPath(const <String>[
          'Registry',
          'Domain',
        ])],
        domainId,
      );
      expect(ledger.parentIdByNodeId, hasLength(2));
      expect(ledger.parentIdByNodeId.containsKey(rootId), isTrue);
      expect(ledger.parentIdByNodeId[rootId], isNull);
      expect(ledger.parentIdByNodeId[domainId], rootId);
      expect(ledger.maximumAssignedSequence, 2);

      expect(requests, hasLength(2));
      expect(requests.map((request) => request.path).toSet(), <String>{
        _ledgerRequestPath,
      });
      expect(requests.map((request) => request.ref).toSet(), <String?>{
        _exactRevision,
      });
      expect(requests.map((request) => request.accept), <String>[
        'application/vnd.github.object+json',
        'application/vnd.github.raw+json',
      ]);
      expect(
        requests.any((request) => request.path.contains('/commits/')),
        isFalse,
      );
    });

    test('rejects a configured non-ledger document path', () {
      expect(
        () => HelpyRegistryNodeIdentityLedgerSource(
          documentSource: GitHubRegistryDocumentSource(
            owner: 'owner',
            repository: 'repository',
            documentPath: 'other.json',
            ref: 'main',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('decodes immutable metadata and structural identity evidence', () {
      final HelpyRegistryNodeIdentityLedger ledger =
          HelpyRegistryNodeIdentityLedgerSource.decode(_validLedger);

      final RegistryNodeId rootId = RegistryNodeId(
        'helpy.registry.node.000001',
      );
      final RegistryNodeId domainId = RegistryNodeId(
        'helpy.registry.node.000002',
      );

      expect(ledger.version, 'v1');
      expect(ledger.projectId, 'helpy');
      expect(
        ledger.registryDocumentPath,
        HelpyRegistryNodeIdentityLedgerSource.registryDocumentPath,
      );
      expect(ledger.initialSourceRevision, _exactRevision);
      expect(ledger.initialSourceSnapshotFingerprint, 'git-blob:$_blobSha');

      expect(ledger.entries, hasLength(2));
      expect(ledger.entries[0].id, rootId);
      expect(ledger.entries[0].path, RegistryPath(const <String>['Registry']));
      expect(ledger.entries[0].parentId, isNull);
      expect(ledger.entries[1].id, domainId);
      expect(
        ledger.entries[1].path,
        RegistryPath(const <String>['Registry', 'Domain']),
      );
      expect(ledger.entries[1].parentId, rootId);

      expect(ledger.identitiesByPath, hasLength(2));
      expect(
        ledger.identitiesByPath[RegistryPath(const <String>['Registry'])],
        rootId,
      );
      expect(
        ledger.identitiesByPath[RegistryPath(const <String>[
          'Registry',
          'Domain',
        ])],
        domainId,
      );

      expect(ledger.parentIdByNodeId, hasLength(2));
      expect(ledger.parentIdByNodeId.containsKey(rootId), isTrue);
      expect(ledger.parentIdByNodeId[rootId], isNull);
      expect(ledger.parentIdByNodeId[domainId], rootId);
      expect(ledger.maximumAssignedSequence, 2);

      expect(
        () =>
            ledger.identitiesByPath[RegistryPath(const <String>[
              'Registry',
              'Other',
            ])] = RegistryNodeId(
              'helpy.registry.node.000003',
            ),
        throwsUnsupportedError,
      );

      expect(
        () =>
            ledger.parentIdByNodeId[RegistryNodeId(
                  'helpy.registry.node.000003',
                )] =
                rootId,
        throwsUnsupportedError,
      );

      expect(
        () => ledger.entries.add((
          id: RegistryNodeId('helpy.registry.node.000003'),
          path: RegistryPath(const <String>['Registry', 'Other']),
          parentId: rootId,
        )),
        throwsUnsupportedError,
      );
    });

    test('rejects an invalid root schema or metadata', () {
      final Map<String, dynamic> invalidSchema =
          jsonDecode(_validLedger) as Map<String, dynamic>;

      invalidSchema['unexpected'] = true;

      expect(
        () => HelpyRegistryNodeIdentityLedgerSource.decode(
          jsonEncode(invalidSchema),
        ),
        throwsA(isA<FormatException>()),
      );

      final Map<String, dynamic> invalidMetadata =
          jsonDecode(_validLedger) as Map<String, dynamic>;

      invalidMetadata['projectId'] = 'another-project';

      expect(
        () => HelpyRegistryNodeIdentityLedgerSource.decode(
          jsonEncode(invalidMetadata),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects duplicate node identities and heading paths', () {
      final Map<String, dynamic> duplicateIdentity =
          jsonDecode(_validLedger) as Map<String, dynamic>;

      final List<dynamic> duplicateIdentityEntries =
          duplicateIdentity['entries'] as List<dynamic>;

      duplicateIdentityEntries.add(<String, Object?>{
        'nodeId': 'helpy.registry.node.000001',
        'headingPath': <String>['Other'],
        'parentNodeId': null,
      });

      expect(
        () => HelpyRegistryNodeIdentityLedgerSource.decode(
          jsonEncode(duplicateIdentity),
        ),
        throwsA(isA<FormatException>()),
      );

      final Map<String, dynamic> duplicatePath =
          jsonDecode(_validLedger) as Map<String, dynamic>;

      final List<dynamic> duplicatePathEntries =
          duplicatePath['entries'] as List<dynamic>;

      duplicatePathEntries.add(<String, Object?>{
        'nodeId': 'helpy.registry.node.000003',
        'headingPath': <String>['Registry', 'Domain'],
        'parentNodeId': 'helpy.registry.node.000001',
      });

      expect(
        () => HelpyRegistryNodeIdentityLedgerSource.decode(
          jsonEncode(duplicatePath),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown or structurally inconsistent parents', () {
      final Map<String, dynamic> unknownParent =
          jsonDecode(_validLedger) as Map<String, dynamic>;

      final List<dynamic> unknownParentEntries =
          unknownParent['entries'] as List<dynamic>;

      final Map<String, dynamic> unknownParentChild =
          unknownParentEntries[1] as Map<String, dynamic>;

      unknownParentChild['parentNodeId'] = 'helpy.registry.node.999999';

      expect(
        () => HelpyRegistryNodeIdentityLedgerSource.decode(
          jsonEncode(unknownParent),
        ),
        throwsA(isA<FormatException>()),
      );

      final Map<String, dynamic> invalidPrefix =
          jsonDecode(_validLedger) as Map<String, dynamic>;

      final List<dynamic> invalidPrefixEntries =
          invalidPrefix['entries'] as List<dynamic>;

      final Map<String, dynamic> invalidPrefixChild =
          invalidPrefixEntries[1] as Map<String, dynamic>;

      invalidPrefixChild['headingPath'] = <String>['Other', 'Domain'];

      expect(
        () => HelpyRegistryNodeIdentityLedgerSource.decode(
          jsonEncode(invalidPrefix),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid identity values and empty content', () {
      final Map<String, dynamic> invalidIdentity =
          jsonDecode(_validLedger) as Map<String, dynamic>;

      final List<dynamic> entries = invalidIdentity['entries'] as List<dynamic>;

      final Map<String, dynamic> root = entries.first as Map<String, dynamic>;

      root['nodeId'] = 'Registry heading';

      expect(
        () => HelpyRegistryNodeIdentityLedgerSource.decode(
          jsonEncode(invalidIdentity),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => HelpyRegistryNodeIdentityLedgerSource.decode(' '),
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
