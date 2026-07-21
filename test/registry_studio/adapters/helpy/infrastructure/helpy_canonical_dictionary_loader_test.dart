import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_dictionary_loader.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';

void main() {
  test('HelpyCanonicalDictionaryLoader loads dictionary from an exact commit '
      'and blob without write capability', () async {
    const String commitSha = '1111111111111111111111111111111111111111';

    const String blobSha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    const String sourceContent =
        '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->\n'
        '\n'
        'Dictionary ID: '
        '`REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1`\n'
        'Версия словаря: `1`\n'
        'Статус: **APPROVED / STORED**\n'
        '\n'
        '### Collection: `helpy.canonical.phrases`\n'
        'Тип записи: `phrase`\n'
        'Статус: **APPROVED / STORED**\n'
        '- Canonical phrase.\n'
        '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';

    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );

    addTearDown(() async {
      await server.close(force: true);
    });

    final List<String> requestedMethods = <String>[];

    server.listen((HttpRequest request) async {
      requestedMethods.add(request.method);

      if (request.method != 'GET') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }

      if (request.uri.path == '/repos/owner/repository/commits/main') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(<String, Object>{'sha': commitSha}));
        await request.response.close();
        return;
      }

      if (request.uri.path ==
          '/repos/owner/repository/contents/docs/contract.md') {
        final String? requestedRevision = request.uri.queryParameters['ref'];

        if (requestedRevision != commitSha) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final String accept =
            request.headers.value(HttpHeaders.acceptHeader) ?? '';

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
          request.response.write(sourceContent);
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

    final HelpyCanonicalDictionaryLoader loader =
        HelpyCanonicalDictionaryLoader(
          documentSource: GitHubRegistryDocumentSource(
            owner: 'owner',
            repository: 'repository',
            documentPath: 'docs/contract.md',
            ref: 'main',
            apiBaseUri: apiBaseUri,
          ),
        );

    final CanonicalDictionary dictionary = await loader.loadDictionary();

    expect(
      dictionary.dictionaryId,
      'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
    );
    expect(dictionary.sourceRevision, commitSha);
    expect(dictionary.sourceSnapshotFingerprint, 'git-blob:$blobSha');
    expect(dictionary.collections, hasLength(1));
    expect(requestedMethods, everyElement('GET'));
  });
}
