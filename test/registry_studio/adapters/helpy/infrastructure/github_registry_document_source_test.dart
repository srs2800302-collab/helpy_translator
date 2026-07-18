import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';

void main() {
  group('GitHubRegistryDocumentSource', () {
    test('loads raw content pinned to an exact commit and blob', () async {
      const String commitSha = '0123456789abcdef0123456789abcdef01234567';
      const String blobSha = '89abcdef0123456789abcdef0123456789abcdef';
      const String content =
          '# Registry\n'
          'Complete Registry content.\n';

      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );

      addTearDown(() async {
        await server.close(force: true);
      });

      final List<
        ({
          String path,
          String query,
          String accept,
          String? apiVersion,
          String? authorization,
        })
      >
      requests =
          <
            ({
              String path,
              String query,
              String accept,
              String? apiVersion,
              String? authorization,
            })
          >[];

      server.listen((HttpRequest request) async {
        final String accept =
            request.headers.value(HttpHeaders.acceptHeader) ?? '';

        requests.add((
          path: request.uri.path,
          query: request.uri.query,
          accept: accept,
          apiVersion: request.headers.value('X-GitHub-Api-Version'),
          authorization: request.headers.value(HttpHeaders.authorizationHeader),
        ));

        if (request.uri.path == '/repos/srs2800302-collab/helpy/commits/main') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(<String, Object>{'sha': commitSha}),
          );
          await request.response.close();
          return;
        }

        if (request.uri.path ==
                '/repos/srs2800302-collab/helpy/contents/'
                    'docs/architecture/'
                    'Helpy_Architecture_Registry_v1.md' &&
            request.uri.queryParameters['ref'] == commitSha &&
            accept == 'application/vnd.github.object+json') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(<String, Object>{'type': 'file', 'sha': blobSha}),
          );
          await request.response.close();
          return;
        }

        if (request.uri.path ==
                '/repos/srs2800302-collab/helpy/contents/'
                    'docs/architecture/'
                    'Helpy_Architecture_Registry_v1.md' &&
            request.uri.queryParameters['ref'] == commitSha &&
            accept == 'application/vnd.github.raw+json') {
          request.response.headers.contentType = ContentType.text;
          request.response.write(content);
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final GitHubRegistryDocumentSource source = GitHubRegistryDocumentSource(
        owner: ' srs2800302-collab ',
        repository: ' helpy ',
        documentPath:
            ' docs/architecture/'
            'Helpy_Architecture_Registry_v1.md ',
        ref: ' main ',
        token: ' test-token ',
        apiBaseUri: Uri.parse(
          'http://${server.address.address}:${server.port}/',
        ),
      );

      final result = await source.load();

      expect(result.content, content);
      expect(
        result.documentPath,
        'docs/architecture/Helpy_Architecture_Registry_v1.md',
      );
      expect(result.sourceRevision, commitSha);
      expect(result.sourceSnapshotFingerprint, 'git-blob:$blobSha');

      expect(requests, hasLength(3));

      expect(requests.map((request) => request.accept), <String>[
        'application/vnd.github+json',
        'application/vnd.github.object+json',
        'application/vnd.github.raw+json',
      ]);

      expect(requests.map((request) => request.apiVersion).toSet(), <String?>{
        '2026-03-10',
      });

      expect(
        requests.map((request) => request.authorization).toSet(),
        <String?>{'Bearer test-token'},
      );

      expect(requests.first.query, isEmpty);
      expect(requests[1].query, 'ref=$commitSha');
      expect(requests[2].query, 'ref=$commitSha');
    });

    test(
      'loads a provided exact revision without resolving the configured ref',
      () async {
        const String commitSha = '0123456789abcdef0123456789abcdef01234567';
        const String blobSha = '89abcdef0123456789abcdef0123456789abcdef';
        const String documentPath =
            'docs/architecture/Helpy_Architecture_Registry_v1.md';
        const String documentRequestPath =
            '/repos/owner/repository/contents/'
            'docs/architecture/Helpy_Architecture_Registry_v1.md';
        const String content = '# Registry\nExact revision content.\n';

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

          if (request.uri.path == documentRequestPath &&
              request.uri.queryParameters['ref'] == commitSha &&
              accept == 'application/vnd.github.object+json') {
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode(<String, Object>{'type': 'file', 'sha': blobSha}),
            );
            await request.response.close();
            return;
          }

          if (request.uri.path == documentRequestPath &&
              request.uri.queryParameters['ref'] == commitSha &&
              accept == 'application/vnd.github.raw+json') {
            request.response.headers.contentType = ContentType.text;
            request.response.write(content);
            await request.response.close();
            return;
          }

          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        });

        final GitHubRegistryDocumentSource source =
            GitHubRegistryDocumentSource(
              owner: 'owner',
              repository: 'repository',
              documentPath: documentPath,
              ref: 'main',
              apiBaseUri: Uri.parse(
                'http://${server.address.address}:${server.port}/',
              ),
            );

        final result = await source.load(exactRevision: commitSha);

        expect(result.content, content);
        expect(result.documentPath, documentPath);
        expect(result.sourceRevision, commitSha);
        expect(result.sourceSnapshotFingerprint, 'git-blob:$blobSha');

        expect(requests, hasLength(2));
        expect(requests.map((request) => request.path).toSet(), <String>{
          documentRequestPath,
        });
        expect(requests.map((request) => request.ref).toSet(), <String?>{
          commitSha,
        });
        expect(requests.map((request) => request.accept), <String>[
          'application/vnd.github.object+json',
          'application/vnd.github.raw+json',
        ]);

        expect(
          requests.any((request) => request.path.contains('/commits/')),
          isFalse,
        );

        await expectLater(
          source.load(exactRevision: 'main'),
          throwsArgumentError,
        );
      },
    );

    test('rejects incomplete source coordinates', () {
      expect(
        () => GitHubRegistryDocumentSource(
          owner: ' ',
          repository: 'repository',
          documentPath: 'registry.md',
          ref: 'main',
        ),
        throwsArgumentError,
      );

      expect(
        () => GitHubRegistryDocumentSource(
          owner: 'owner',
          repository: 'repository',
          documentPath: 'docs//registry.md',
          ref: 'main',
        ),
        throwsArgumentError,
      );

      expect(
        () => GitHubRegistryDocumentSource(
          owner: 'owner',
          repository: 'repository',
          documentPath: 'registry.md',
          ref: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a revision that is not an exact commit SHA', () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );

      addTearDown(() async {
        await server.close(force: true);
      });

      server.listen((HttpRequest request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, Object>{'sha': 'not-an-exact-commit-sha'}),
        );
        await request.response.close();
      });

      final GitHubRegistryDocumentSource source = GitHubRegistryDocumentSource(
        owner: 'owner',
        repository: 'repository',
        documentPath: 'registry.md',
        ref: 'main',
        apiBaseUri: Uri.parse(
          'http://${server.address.address}:${server.port}/',
        ),
      );

      await expectLater(source.load(), throwsA(isA<FormatException>()));
    });
  });
}
