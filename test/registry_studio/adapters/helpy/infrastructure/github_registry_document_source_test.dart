import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';

void main() {
  group('GitHubRegistryDocumentSource', () {
    test('loads the unchanged raw registry document', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final Dio dio = _dioWithResponse(
        statusCode: 200,
        data: '## Registry\n- Правило\n',
        requests: requests,
      );

      final GitHubRegistryDocumentSource source = GitHubRegistryDocumentSource(
        dio: dio,
        owner: 'srs2800302-collab',
        repository: 'helpy',
        documentPath: 'docs/architecture/Helpy_Architecture_Registry_v1.md',
        ref: 'main',
        token: 'test-token',
      );

      final String document = await source.load();

      expect(document, '## Registry\n- Правило\n');
      expect(requests, hasLength(1));

      final RequestOptions request = requests.single;

      expect(request.method, 'GET');
      expect(
        request.uri.toString(),
        'https://api.github.com/repos/'
        'srs2800302-collab/helpy/contents/'
        'docs/architecture/Helpy_Architecture_Registry_v1.md'
        '?ref=main',
      );
      expect(request.responseType, ResponseType.plain);
      expect(request.headers['Accept'], 'application/vnd.github.raw+json');
      expect(request.headers['User-Agent'], 'registry-studio');
      expect(request.headers['Authorization'], 'Bearer test-token');
    });

    test('omits authorization when the token is empty', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final Dio dio = _dioWithResponse(
        statusCode: 200,
        data: '# Registry',
        requests: requests,
      );

      final GitHubRegistryDocumentSource source = _source(dio: dio);

      await source.load();

      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('rejects a non-success HTTP status', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponse(statusCode: 404, data: 'Not Found'),
      );

      await expectLater(
        source.load(),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            contains('HTTP 404'),
          ),
        ),
      );
    });

    test('rejects an empty registry document', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponse(statusCode: 200, data: ' \n '),
      );

      await expectLater(source.load(), throwsFormatException);
    });

    test('rejects a response that is not raw text', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponse(
          statusCode: 200,
          data: <String, Object?>{'content': 'encoded'},
        ),
      );

      await expectLater(source.load(), throwsFormatException);
    });

    test('rejects incomplete source configuration', () {
      final Dio dio = Dio();

      expect(
        () => GitHubRegistryDocumentSource(
          dio: dio,
          owner: ' ',
          repository: 'helpy',
          documentPath: 'docs/registry.md',
          ref: 'main',
        ),
        throwsArgumentError,
      );

      expect(
        () => GitHubRegistryDocumentSource(
          dio: dio,
          owner: 'owner',
          repository: ' ',
          documentPath: 'docs/registry.md',
          ref: 'main',
        ),
        throwsArgumentError,
      );

      expect(
        () => GitHubRegistryDocumentSource(
          dio: dio,
          owner: 'owner',
          repository: 'helpy',
          documentPath: 'docs//registry.md',
          ref: 'main',
        ),
        throwsArgumentError,
      );

      expect(
        () => GitHubRegistryDocumentSource(
          dio: dio,
          owner: 'owner',
          repository: 'helpy',
          documentPath: 'docs/registry.md',
          ref: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}

GitHubRegistryDocumentSource _source({required Dio dio}) {
  return GitHubRegistryDocumentSource(
    dio: dio,
    owner: 'owner',
    repository: 'repository',
    documentPath: 'docs/registry.md',
    ref: 'main',
  );
}

Dio _dioWithResponse({
  required int statusCode,
  required Object? data,
  List<RequestOptions>? requests,
}) {
  final Dio dio = Dio();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        requests?.add(options);

        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
        );
      },
    ),
  );

  return dio;
}
