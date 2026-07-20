import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/application/contracts/helpy_registry_node_identity_store.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_snapshot_loader.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_structural_index.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

const String _registryDocumentPath =
    HelpyRegistryNodeIdentityLedgerSource.registryDocumentPath;

const String _ledgerDocumentPath =
    HelpyRegistryNodeIdentityLedgerSource.ledgerDocumentPath;

const String _registryDocumentRequestPath =
    '/repos/owner/repository/contents/'
    'docs/architecture/Helpy_Architecture_Registry_v1.md';

const String _otherDocumentRequestPath =
    '/repos/owner/repository/contents/other.md';

const String _ledgerDocumentRequestPath =
    '/repos/owner/repository/contents/'
    'docs/architecture/registry_studio/'
    'registry_node_identity_ledger_v1.json';

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
            '## Domain\n'
            '## Other\n';

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

        final Map<String, String> ledgerBlobByCommit = <String, String>{
          successCommitSha: 'dddddddddddddddddddddddddddddddddddddddd',
          missingCommitSha: 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
          extraCommitSha: 'ffffffffffffffffffffffffffffffffffffffff',
        };

        final Map<String, String> ledgerContentByCommit = <String, String>{
          successCommitSha: _completeLedger,
          missingCommitSha: _rootOnlyLedger,
          extraCommitSha: _completeLedger,
        };

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
              request.uri.path == _otherDocumentRequestPath ||
              request.uri.path == _ledgerDocumentRequestPath) {
            final String? commitSha = request.uri.queryParameters['ref'];
            final bool isLedger =
                request.uri.path == _ledgerDocumentRequestPath;

            final String? blobSha = isLedger
                ? ledgerBlobByCommit[commitSha]
                : blobByCommit[commitSha];

            final String? content = isLedger
                ? ledgerContentByCommit[commitSha]
                : contentByCommit[commitSha];

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
              identityStore: _MemoryHelpyRegistryNodeIdentityStore(),
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: _registryDocumentPath,
                ref: 'success',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                documentSource: GitHubRegistryDocumentSource(
                  owner: 'owner',
                  repository: 'repository',
                  documentPath: _ledgerDocumentPath,
                  ref: 'main',
                  apiBaseUri: apiBaseUri,
                ),
              ),
            );

        final RegistrySnapshot snapshot = await successfulLoader.loadSnapshot();

        expect(
          requests.where((request) => request.path.contains('/commits/')),
          hasLength(1),
        );

        expect(
          requests.where(
            (request) => request.path == _ledgerDocumentRequestPath,
          ),
          hasLength(2),
        );

        expect(
          requests
              .where((request) => request.path == _ledgerDocumentRequestPath)
              .map((request) => request.ref)
              .toSet(),
          <String?>{successCommitSha},
        );

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

        requests.clear();

        final RegistrySnapshot exactRevisionSnapshot = await successfulLoader
            .loadSnapshotAtRevision(successCommitSha);

        expect(
          requests.where((request) => request.path.contains('/commits/')),
          isEmpty,
        );

        expect(
          requests.where(
            (request) => request.path == _registryDocumentRequestPath,
          ),
          hasLength(2),
        );

        expect(
          requests.where(
            (request) => request.path == _ledgerDocumentRequestPath,
          ),
          hasLength(2),
        );

        expect(
          requests
              .where(
                (request) =>
                    request.path == _registryDocumentRequestPath ||
                    request.path == _ledgerDocumentRequestPath,
              )
              .map((request) => request.ref)
              .toSet(),
          <String?>{successCommitSha},
        );

        expect(exactRevisionSnapshot.sourceRevision, successCommitSha);
        expect(
          exactRevisionSnapshot.sourceSnapshotFingerprint,
          'git-blob:$successBlobSha',
        );
        expect(
          exactRevisionSnapshot.roots.single.id,
          RegistryNodeId('helpy.registry.node.000001'),
        );
        expect(
          exactRevisionSnapshot.roots.single.children.single.id,
          RegistryNodeId('helpy.registry.node.000002'),
        );

        final int requestCountBeforeRepositoryMismatch = requests.length;

        final HelpyRegistrySnapshotLoader mismatchedRepositoryLoader =
            HelpyRegistrySnapshotLoader(
              identityStore: _MemoryHelpyRegistryNodeIdentityStore(),
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: _registryDocumentPath,
                ref: 'success',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                documentSource: GitHubRegistryDocumentSource(
                  owner: 'another-owner',
                  repository: 'repository',
                  documentPath: _ledgerDocumentPath,
                  ref: 'main',
                  apiBaseUri: apiBaseUri,
                ),
              ),
            );

        await expectLater(
          mismatchedRepositoryLoader.loadSnapshot(),
          throwsA(isA<StateError>()),
        );

        expect(requests, hasLength(requestCountBeforeRepositoryMismatch));

        final HelpyRegistrySnapshotLoader mismatchedDocumentLoader =
            HelpyRegistrySnapshotLoader(
              identityStore: _MemoryHelpyRegistryNodeIdentityStore(),
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: 'other.md',
                ref: 'success',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                documentSource: GitHubRegistryDocumentSource(
                  owner: 'owner',
                  repository: 'repository',
                  documentPath: _ledgerDocumentPath,
                  ref: 'main',
                  apiBaseUri: apiBaseUri,
                ),
              ),
            );

        await expectLater(
          mismatchedDocumentLoader.loadSnapshot(),
          throwsA(isA<FormatException>()),
        );

        final _MemoryHelpyRegistryNodeIdentityStore missingIdentityStore =
            _MemoryHelpyRegistryNodeIdentityStore();

        final HelpyRegistrySnapshotLoader missingIdentityLoader =
            HelpyRegistrySnapshotLoader(
              identityStore: missingIdentityStore,
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: _registryDocumentPath,
                ref: 'missing',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                documentSource: GitHubRegistryDocumentSource(
                  owner: 'owner',
                  repository: 'repository',
                  documentPath: _ledgerDocumentPath,
                  ref: 'main',
                  apiBaseUri: apiBaseUri,
                ),
              ),
            );

        final RegistrySnapshot missingIdentitySnapshot =
            await missingIdentityLoader.loadSnapshot();

        expect(
          missingIdentitySnapshot.roots.single.id,
          RegistryNodeId('helpy.registry.node.000001'),
        );

        expect(
          missingIdentitySnapshot.roots.single.children
              .map((node) => node.id)
              .toList(growable: false),
          <RegistryNodeId>[
            RegistryNodeId('helpy.registry.node.000002'),
            RegistryNodeId('helpy.registry.node.000003'),
          ],
        );

        expect(missingIdentityStore.savedIdentities, hasLength(2));

        final RegistrySnapshot repeatedMissingIdentitySnapshot =
            await missingIdentityLoader.loadSnapshot();

        expect(
          repeatedMissingIdentitySnapshot.roots.single.children
              .map((node) => node.id)
              .toList(growable: false),
          <RegistryNodeId>[
            RegistryNodeId('helpy.registry.node.000002'),
            RegistryNodeId('helpy.registry.node.000003'),
          ],
        );

        final HelpyRegistrySnapshotLoader retiredIdentityLoader =
            HelpyRegistrySnapshotLoader(
              identityStore: _MemoryHelpyRegistryNodeIdentityStore(),
              documentSource: GitHubRegistryDocumentSource(
                owner: 'owner',
                repository: 'repository',
                documentPath: _registryDocumentPath,
                ref: 'extra',
                apiBaseUri: apiBaseUri,
              ),
              identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
                documentSource: GitHubRegistryDocumentSource(
                  owner: 'owner',
                  repository: 'repository',
                  documentPath: _ledgerDocumentPath,
                  ref: 'main',
                  apiBaseUri: apiBaseUri,
                ),
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

final class _MemoryHelpyRegistryNodeIdentityStore
    implements HelpyRegistryNodeIdentityStore {
  Map<RegistryPath, RegistryNodeId> savedIdentities =
      <RegistryPath, RegistryNodeId>{};

  @override
  Future<Map<RegistryPath, RegistryNodeId>> loadIdentities() async {
    return Map<RegistryPath, RegistryNodeId>.unmodifiable(savedIdentities);
  }

  @override
  Future<void> saveIdentities(
    Map<RegistryPath, RegistryNodeId> identities,
  ) async {
    savedIdentities = Map<RegistryPath, RegistryNodeId>.of(identities);
  }
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
