import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_snapshot_loader.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_structural_index.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

const String _registryDocumentPath =
    HelpyRegistryNodeIdentityLedgerSource.registryDocumentPath;

const String _registryDocumentRequestPath =
    '/repos/owner/repository/contents/'
    'docs/architecture/Helpy_Architecture_Registry_v1.md';

const String _otherDocumentRequestPath =
    '/repos/owner/repository/contents/other.md';

void main() {
  group('HelpyRegistrySnapshotLoader', () {
    test(
      'loads an exact snapshot and tolerates retired identity evidence',
      () async {
        const String successCommitSha =
            '1111111111111111111111111111111111111111';
        const String missingCommitSha =
            '2222222222222222222222222222222222222222';
        const String extraCommitSha =
            '3333333333333333333333333333333333333333';

        const String successBlobSha =
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        const String missingBlobSha =
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
        const String extraBlobSha = 'cccccccccccccccccccccccccccccccccccccccc';

        const String successContent =
            '# Registry\n'
            'Root content.\n'
            '## Domain\n'
            'Domain content.\n';

        const String missingContent =
            '# Registry\n'
            '## Domain\n';

        const String extraContent =
            '# Registry\n'
            'Root content.\n';

        final Map<String, String> commitByRequestedRef = <String, String>{
          'success': successCommitSha,
          'missing': missingCommitSha,
          'extra': extraCommitSha,
        };

        final Map<String, String> blobByCommit = <String, String>{
          successCommitSha: successBlobSha,
          missingCommitSha: missingBlobSha,
          extraCommitSha: extraBlobSha,
        };

        final Map<String, String> contentByCommit = <String, String>{
          successCommitSha: successContent,
          missingCommitSha: missingContent,
          extraCommitSha: extraContent,
        };

        final HttpServer server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );

        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((HttpRequest request) async {
          final List<String> pathSegments = request.uri.pathSegments;

          if (pathSegments.length == 5 &&
              pathSegments[0] == 'repos' &&
              pathSegments[1] == 'owner' &&
              pathSegments[2] == 'repository' &&
              pathSegments[3] == 'commits') {
            final String requestedRef = pathSegments[4];
            final String? commitSha = commitByRequestedRef[requestedRef];

            if (commitSha == null) {
              request.response.statusCode = HttpStatus.notFound;
              await request.response.close();
              return;
            }

            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode(<String, Object>{'sha': commitSha}),
            );
            await request.response.close();
            return;
          }

          if (request.uri.path == _registryDocumentRequestPath ||
              request.uri.path == _otherDocumentRequestPath) {
            final String? commitSha = request.uri.queryParameters['ref'];
            final String? blobSha = blobByCommit[commitSha];
            final String? content = contentByCommit[commitSha];
            final String accept =
                request.headers.value(HttpHeaders.acceptHeader) ?? '';

            if (blobSha == null || content == null) {
              request.response.statusCode = HttpStatus.notFound;
              await request.response.close();
              return;
            }

            if (accept == 'application/vnd.github.object+json') {
              request.response.headers.contentType = ContentType.json;
              request.response.write(
                jsonEncode(<String, Object>{'type': 'file', 'sha': blobSha}),
              );
              await request.response.close();
              return;
            }

            if (accept == 'application/vnd.github.raw+json') {
              request.response.headers.contentType = ContentType.text;
              request.response.write(content);
              await request.response.close();
              return;
            }
          }

          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        });

        final Uri apiBaseUri = Uri.parse(
          'http://${server.address.address}:${server.port}/',
        );

        final HelpyRegistrySnapshotLoader successfulLoader =
            HelpyRegistrySnapshotLoader(
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: _registryDocumentPath,
                ref: 'success',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                assetBundle: _MemoryAssetBundle(const <String, String>{
                  'success.json': _completeLedger,
                }),
                assetPath: 'success.json',
              ),
            );

        final RegistrySnapshot snapshot = await successfulLoader.loadSnapshot();

        expect(snapshot.projectId, HelpyRegistrySnapshotLoader.projectId);
        expect(
          snapshot.projectAdapterId,
          HelpyRegistrySnapshotLoader.projectAdapterId,
        );
        expect(snapshot.sourceDocumentPath, _registryDocumentPath);
        expect(snapshot.sourceRevision, successCommitSha);
        expect(snapshot.sourceSnapshotFingerprint, 'git-blob:$successBlobSha');
        expect(snapshot.sourceContent, successContent);
        expect(snapshot.roots, hasLength(1));

        final root = snapshot.roots.single;
        final domain = root.children.single;

        expect(root.id, RegistryNodeId('helpy.registry.node.000001'));
        expect(root.kindId, 'helpy.registry.markdown.heading.1');
        expect(root.path, RegistryPath(const <String>['Registry']));
        expect(root.content, 'Root content.');
        expect(root.sourceEvidence.single.startLine, 1);
        expect(root.sourceEvidence.single.endLine, 4);

        expect(domain.id, RegistryNodeId('helpy.registry.node.000002'));
        expect(domain.kindId, 'helpy.registry.markdown.heading.2');
        expect(domain.path, RegistryPath(const <String>['Registry', 'Domain']));
        expect(domain.content, 'Domain content.');
        expect(domain.sourceEvidence.single.startLine, 3);
        expect(domain.sourceEvidence.single.endLine, 4);

        final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

        expect(index.nodesById, hasLength(2));
        expect(index.parentIdByNodeId[domain.id], root.id);

        final HelpyRegistrySnapshotLoader mismatchedDocumentLoader =
            HelpyRegistrySnapshotLoader(
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: 'other.md',
                ref: 'success',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                assetBundle: _MemoryAssetBundle(const <String, String>{
                  'mismatched.json': _completeLedger,
                }),
                assetPath: 'mismatched.json',
              ),
            );

        await expectLater(
          mismatchedDocumentLoader.loadSnapshot(),
          throwsA(isA<FormatException>()),
        );

        final HelpyRegistrySnapshotLoader missingIdentityLoader =
            HelpyRegistrySnapshotLoader(
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: _registryDocumentPath,
                ref: 'missing',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                assetBundle: _MemoryAssetBundle(const <String, String>{
                  'missing.json': _rootOnlyLedger,
                }),
                assetPath: 'missing.json',
              ),
            );

        await expectLater(
          missingIdentityLoader.loadSnapshot(),
          throwsA(isA<FormatException>()),
        );

        final HelpyRegistrySnapshotLoader retiredIdentityLoader =
            HelpyRegistrySnapshotLoader(
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: _registryDocumentPath,
                ref: 'extra',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                assetBundle: _MemoryAssetBundle(const <String, String>{
                  'extra.json': _completeLedger,
                }),
                assetPath: 'extra.json',
              ),
            );

        final RegistrySnapshot retiredIdentitySnapshot =
            await retiredIdentityLoader.loadSnapshot();

        expect(retiredIdentitySnapshot.sourceRevision, extraCommitSha);
        expect(
          retiredIdentitySnapshot.roots.single.id,
          RegistryNodeId('helpy.registry.node.000001'),
        );
        expect(retiredIdentitySnapshot.roots.single.children, isEmpty);

        final RegistryStructuralIndex retiredIdentityIndex =
            RegistryStructuralIndex(retiredIdentitySnapshot);

        expect(retiredIdentityIndex.nodesById, hasLength(1));
      },
    );
  });
}

const String _completeLedger = '''
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

const String _rootOnlyLedger = '''
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
