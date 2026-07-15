import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';

void main() {
  group('GitHubRegistryDocumentSource', () {
    test(
      'resolves exact revision and loads unchanged raw registry document',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final Dio dio = _dioWithResponses(
          responses: <_TestResponse>[
            (statusCode: 200, data: <String, Object?>{'sha': _exactCommitSha}),
            (statusCode: 200, data: '## Registry\n- Правило\n'),
          ],
          requests: requests,
        );

        final GitHubRegistryDocumentSource source =
            GitHubRegistryDocumentSource(
              dio: dio,
              owner: 'srs2800302-collab',
              repository: 'helpy',
              documentPath:
                  'docs/architecture/Helpy_Architecture_Registry_v1.md',
              ref: 'main',
              token: 'test-token',
            );

        final GitHubRegistryDocumentSourceResult result = await source.load();

        expect(result.content, '## Registry\n- Правило\n');
        expect(
          result.documentPath,
          'docs/architecture/Helpy_Architecture_Registry_v1.md',
        );
        expect(result.requestedRef, 'main');
        expect(result.sourceRevision, _exactCommitSha);
        expect(result.sourceSnapshotFingerprint, startsWith('fnv1a64:'));
        expect(result.sourceSnapshotFingerprint, isNot(result.sourceRevision));

        expect(requests, hasLength(2));

        final RequestOptions revisionRequest = requests.first;
        final RequestOptions documentRequest = requests.last;

        expect(
          revisionRequest.uri.toString(),
          'https://api.github.com/repos/'
          'srs2800302-collab/helpy/commits/main',
        );
        expect(revisionRequest.responseType, ResponseType.json);
        expect(
          revisionRequest.headers['Accept'],
          'application/vnd.github+json',
        );
        expect(revisionRequest.headers['Authorization'], 'Bearer test-token');

        expect(
          documentRequest.uri.toString(),
          'https://api.github.com/repos/'
          'srs2800302-collab/helpy/contents/'
          'docs/architecture/Helpy_Architecture_Registry_v1.md'
          '?ref=$_exactCommitSha',
        );
        expect(documentRequest.responseType, ResponseType.plain);
        expect(
          documentRequest.headers['Accept'],
          'application/vnd.github.raw+json',
        );
        expect(documentRequest.headers['Authorization'], 'Bearer test-token');
      },
    );

    test(
      'omits authorization from both requests when token is empty',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final Dio dio = _dioWithResponses(
          responses: <_TestResponse>[
            (statusCode: 200, data: <String, Object?>{'sha': _exactCommitSha}),
            (statusCode: 200, data: '# Registry'),
          ],
          requests: requests,
        );

        await _source(dio: dio).load();

        expect(requests, hasLength(2));

        for (final RequestOptions request in requests) {
          expect(request.headers.containsKey('Authorization'), isFalse);
        }
      },
    );

    test('rejects a non-success revision response', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponses(
          responses: <_TestResponse>[
            (statusCode: 404, data: <String, Object?>{}),
          ],
        ),
      );

      await expectLater(
        source.load(),
        throwsA(
          isA<StateError>()
              .having(
                (StateError error) => error.message,
                'message',
                contains('revision resolve failed'),
              )
              .having(
                (StateError error) => error.message,
                'message',
                contains('HTTP 404'),
              ),
        ),
      );
    });

    test('rejects a revision response that is not a JSON object', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponses(
          responses: <_TestResponse>[
            (statusCode: 200, data: 'not-json-object'),
          ],
        ),
      );

      await expectLater(source.load(), throwsFormatException);
    });

    test('rejects an invalid exact commit SHA', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponses(
          responses: <_TestResponse>[
            (statusCode: 200, data: <String, Object?>{'sha': 'ABC123'}),
          ],
        ),
      );

      await expectLater(source.load(), throwsFormatException);
    });

    test('rejects a non-success document response', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponses(
          responses: <_TestResponse>[
            (statusCode: 200, data: <String, Object?>{'sha': _exactCommitSha}),
            (statusCode: 404, data: 'Not Found'),
          ],
        ),
      );

      await expectLater(
        source.load(),
        throwsA(
          isA<StateError>()
              .having(
                (StateError error) => error.message,
                'message',
                contains('document load failed'),
              )
              .having(
                (StateError error) => error.message,
                'message',
                contains('HTTP 404'),
              ),
        ),
      );
    });

    test('rejects an empty registry document', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponses(
          responses: <_TestResponse>[
            (statusCode: 200, data: <String, Object?>{'sha': _exactCommitSha}),
            (statusCode: 200, data: ' \n '),
          ],
        ),
      );

      await expectLater(source.load(), throwsFormatException);
    });

    test('rejects a document response that is not raw text', () async {
      final GitHubRegistryDocumentSource source = _source(
        dio: _dioWithResponses(
          responses: <_TestResponse>[
            (statusCode: 200, data: <String, Object?>{'sha': _exactCommitSha}),
            (statusCode: 200, data: <String, Object?>{'content': 'encoded'}),
          ],
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

typedef _TestResponse = ({int statusCode, Object? data});

Dio _dioWithResponses({
  required List<_TestResponse> responses,
  List<RequestOptions>? requests,
}) {
  final Dio dio = Dio();
  int responseIndex = 0;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        requests?.add(options);

        if (responseIndex >= responses.length) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Unexpected test request.',
            ),
          );
          return;
        }

        final _TestResponse response = responses[responseIndex++];

        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: response.statusCode,
            data: response.data,
          ),
        );
      },
    ),
  );

  return dio;
}

const String _exactCommitSha = '8e26a1eed581f96aa57f4b400dd4b6d59c30168f';
