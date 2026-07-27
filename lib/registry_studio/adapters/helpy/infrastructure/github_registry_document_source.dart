import 'dart:convert';
import 'dart:io';

final class GitHubRegistryDocumentSource {
  factory GitHubRegistryDocumentSource({
    required String owner,
    required String repository,
    required String documentPath,
    required String ref,
    String token = '',
    Uri? apiBaseUri,
  }) {
    final String normalizedOwner = owner.trim();
    final String normalizedRepository = repository.trim();
    final String normalizedRef = ref.trim();
    final List<String> normalizedDocumentPathSegments = documentPath
        .trim()
        .split('/')
        .map((String segment) => segment.trim())
        .toList(growable: false);
    final Uri normalizedApiBaseUri =
        apiBaseUri ?? Uri.parse('https://api.github.com/');

    if (normalizedOwner.isEmpty) {
      throw ArgumentError.value(
        owner,
        'owner',
        'GitHub repository owner must not be empty.',
      );
    }

    if (normalizedRepository.isEmpty) {
      throw ArgumentError.value(
        repository,
        'repository',
        'GitHub repository name must not be empty.',
      );
    }

    if (normalizedRef.isEmpty) {
      throw ArgumentError.value(
        ref,
        'ref',
        'GitHub source ref must not be empty.',
      );
    }

    if (normalizedDocumentPathSegments.isEmpty ||
        normalizedDocumentPathSegments.any(
          (String segment) => segment.isEmpty,
        )) {
      throw ArgumentError.value(
        documentPath,
        'documentPath',
        'GitHub document path must contain only non-empty segments.',
      );
    }

    if (!normalizedApiBaseUri.hasScheme || normalizedApiBaseUri.host.isEmpty) {
      throw ArgumentError.value(
        apiBaseUri,
        'apiBaseUri',
        'GitHub API base URI must contain a scheme and host.',
      );
    }

    return GitHubRegistryDocumentSource._(
      owner: normalizedOwner,
      repository: normalizedRepository,
      documentPath: normalizedDocumentPathSegments.join('/'),
      ref: normalizedRef,
      token: token.trim(),
      apiBaseUri: normalizedApiBaseUri,
    );
  }

  const GitHubRegistryDocumentSource._({
    required this.owner,
    required this.repository,
    required this.documentPath,
    required this.ref,
    required this.token,
    required this.apiBaseUri,
  });

  static final RegExp _gitObjectShaPattern = RegExp(r'^[0-9a-f]{40}$');

  final String owner;
  final String repository;
  final String documentPath;
  final String ref;
  final String token;
  final Uri apiBaseUri;

  Future<
    ({
      String content,
      String documentPath,
      String sourceRevision,
      String sourceSnapshotFingerprint,
    })
  >
  load({String? exactRevision}) async {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25);

    try {
      late final String sourceRevision;

      if (exactRevision == null) {
        final Uri revisionUri = apiBaseUri.replace(
          pathSegments: <String>['repos', owner, repository, 'commits', ref],
          queryParameters: const <String, String>{},
        );

        final HttpClientRequest revisionRequest = await client.getUrl(
          revisionUri,
        );

        revisionRequest.headers.set(
          HttpHeaders.acceptHeader,
          'application/vnd.github+json',
        );
        revisionRequest.headers.set(
          HttpHeaders.userAgentHeader,
          'registry-studio',
        );
        revisionRequest.headers.set('X-GitHub-Api-Version', '2026-03-10');

        if (token.isNotEmpty) {
          revisionRequest.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $token',
          );
        }

        final HttpClientResponse revisionResponse = await revisionRequest
            .close()
            .timeout(const Duration(seconds: 90));
        final String revisionResponseBody = await utf8.decoder
            .bind(revisionResponse)
            .join()
            .timeout(const Duration(seconds: 90));

        if (revisionResponse.statusCode < 200 ||
            revisionResponse.statusCode >= 300) {
          throw HttpException(
            'GitHub Registry revision resolution failed: '
            'HTTP ${revisionResponse.statusCode}.',
            uri: revisionUri,
          );
        }

        final Object? decodedRevision = jsonDecode(revisionResponseBody);

        if (decodedRevision is! Map<String, dynamic>) {
          throw const FormatException(
            'GitHub revision response must be a JSON object.',
          );
        }

        final Object? revisionValue = decodedRevision['sha'];

        if (revisionValue is! String ||
            !_gitObjectShaPattern.hasMatch(revisionValue)) {
          throw const FormatException(
            'GitHub revision response must contain an exact '
            'lowercase 40-character commit SHA.',
          );
        }

        sourceRevision = revisionValue;
      } else {
        if (!_gitObjectShaPattern.hasMatch(exactRevision)) {
          throw ArgumentError.value(
            exactRevision,
            'exactRevision',
            'GitHub exact revision must be a lowercase '
                '40-character commit SHA.',
          );
        }

        sourceRevision = exactRevision;
      }

      final Uri documentUri = apiBaseUri.replace(
        pathSegments: <String>[
          'repos',
          owner,
          repository,
          'contents',
          ...documentPath.split('/'),
        ],
        queryParameters: <String, String>{'ref': sourceRevision},
      );

      final HttpClientRequest metadataRequest = await client.getUrl(
        documentUri,
      );

      metadataRequest.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github.object+json',
      );
      metadataRequest.headers.set(
        HttpHeaders.userAgentHeader,
        'registry-studio',
      );
      metadataRequest.headers.set('X-GitHub-Api-Version', '2026-03-10');

      if (token.isNotEmpty) {
        metadataRequest.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $token',
        );
      }

      final HttpClientResponse metadataResponse = await metadataRequest
          .close()
          .timeout(const Duration(seconds: 90));
      final String metadataResponseBody = await utf8.decoder
          .bind(metadataResponse)
          .join()
          .timeout(const Duration(seconds: 90));

      if (metadataResponse.statusCode < 200 ||
          metadataResponse.statusCode >= 300) {
        throw HttpException(
          'GitHub Registry metadata load failed: '
          'HTTP ${metadataResponse.statusCode}.',
          uri: documentUri,
        );
      }

      final Object? decodedMetadata = jsonDecode(metadataResponseBody);

      if (decodedMetadata is! Map<String, dynamic>) {
        throw const FormatException(
          'GitHub document metadata response must be a JSON object.',
        );
      }

      if (decodedMetadata['type'] != 'file') {
        throw const FormatException(
          'GitHub Registry source path must resolve to one file.',
        );
      }

      final Object? blobShaValue = decodedMetadata['sha'];

      if (blobShaValue is! String ||
          !_gitObjectShaPattern.hasMatch(blobShaValue)) {
        throw const FormatException(
          'GitHub document metadata must contain an exact '
          'lowercase 40-character blob SHA.',
        );
      }

      final HttpClientRequest documentRequest = await client.getUrl(
        documentUri,
      );

      documentRequest.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github.raw+json',
      );
      documentRequest.headers.set(
        HttpHeaders.userAgentHeader,
        'registry-studio',
      );
      documentRequest.headers.set('X-GitHub-Api-Version', '2026-03-10');

      if (token.isNotEmpty) {
        documentRequest.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $token',
        );
      }

      final HttpClientResponse documentResponse = await documentRequest
          .close()
          .timeout(const Duration(seconds: 90));
      final String content = await utf8.decoder
          .bind(documentResponse)
          .join()
          .timeout(const Duration(seconds: 90));

      if (documentResponse.statusCode < 200 ||
          documentResponse.statusCode >= 300) {
        throw HttpException(
          'GitHub Registry document load failed: '
          'HTTP ${documentResponse.statusCode}.',
          uri: documentUri,
        );
      }

      if (content.trim().isEmpty) {
        throw const FormatException(
          'GitHub Registry document must not be empty.',
        );
      }

      return (
        content: content,
        documentPath: documentPath,
        sourceRevision: sourceRevision,
        sourceSnapshotFingerprint: 'git-blob:$blobShaValue',
      );
    } finally {
      client.close(force: true);
    }
  }
}
