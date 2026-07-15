import 'dart:convert';

import 'package:dio/dio.dart';

final class GitHubRegistryDocumentSourceResult {
  const GitHubRegistryDocumentSourceResult({
    required this.content,
    required this.documentPath,
    required this.requestedRef,
    required this.sourceRevision,
    required this.sourceSnapshotFingerprint,
  });

  final String content;
  final String documentPath;
  final String requestedRef;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
}

final class GitHubRegistryDocumentSource {
  factory GitHubRegistryDocumentSource({
    required Dio dio,
    required String owner,
    required String repository,
    required String documentPath,
    required String ref,
    String token = '',
  }) {
    final String normalizedOwner = _requiredValue(owner, 'owner');
    final String normalizedRepository = _requiredValue(
      repository,
      'repository',
    );
    final String normalizedRef = _requiredValue(ref, 'ref');
    final String normalizedDocumentPath = _normalizeDocumentPath(documentPath);

    return GitHubRegistryDocumentSource._(
      dio: dio,
      owner: normalizedOwner,
      repository: normalizedRepository,
      documentPath: normalizedDocumentPath,
      ref: normalizedRef,
      token: token.trim(),
    );
  }

  const GitHubRegistryDocumentSource._({
    required this.dio,
    required this.owner,
    required this.repository,
    required this.documentPath,
    required this.ref,
    required this.token,
  });

  static const String _host = 'api.github.com';
  static const String _jsonMediaType = 'application/vnd.github+json';
  static const String _rawMediaType = 'application/vnd.github.raw+json';
  static const String _userAgent = 'registry-studio';

  static final RegExp _commitShaPattern = RegExp(r'^[0-9a-f]{40}$');

  final Dio dio;
  final String owner;
  final String repository;
  final String documentPath;
  final String ref;
  final String token;

  Future<GitHubRegistryDocumentSourceResult> load() async {
    final Uri revisionUri = Uri(
      scheme: 'https',
      host: _host,
      pathSegments: <String>['repos', owner, repository, 'commits', ref],
    );

    final Response<dynamic> revisionResponse = await dio.getUri<dynamic>(
      revisionUri,
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (int? status) => true,
        headers: _headers(_jsonMediaType),
      ),
    );

    final int? revisionStatusCode = revisionResponse.statusCode;

    if (revisionStatusCode == null ||
        revisionStatusCode < 200 ||
        revisionStatusCode >= 300) {
      throw StateError(
        'GitHub registry revision resolve failed: '
        'HTTP ${revisionStatusCode ?? "unknown"}.',
      );
    }

    final Object? revisionData = revisionResponse.data;

    if (revisionData is! Map<String, dynamic>) {
      throw const FormatException(
        'GitHub registry revision response must be a JSON object.',
      );
    }

    final Object? revisionValue = revisionData['sha'];

    if (revisionValue is! String ||
        !_commitShaPattern.hasMatch(revisionValue)) {
      throw const FormatException(
        'GitHub registry revision response must contain '
        'an exact lowercase 40-character commit SHA.',
      );
    }

    final String sourceRevision = revisionValue;

    final Uri documentUri = Uri(
      scheme: 'https',
      host: _host,
      pathSegments: <String>[
        'repos',
        owner,
        repository,
        'contents',
        ...documentPath.split('/'),
      ],
      queryParameters: <String, String>{'ref': sourceRevision},
    );

    final Response<dynamic> documentResponse = await dio.getUri<dynamic>(
      documentUri,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (int? status) => true,
        headers: _headers(_rawMediaType),
      ),
    );

    final int? documentStatusCode = documentResponse.statusCode;

    if (documentStatusCode == null ||
        documentStatusCode < 200 ||
        documentStatusCode >= 300) {
      throw StateError(
        'GitHub registry document load failed: '
        'HTTP ${documentStatusCode ?? "unknown"}.',
      );
    }

    final Object? documentData = documentResponse.data;

    if (documentData is! String) {
      throw const FormatException(
        'GitHub registry document response must be raw text.',
      );
    }

    if (documentData.trim().isEmpty) {
      throw const FormatException(
        'GitHub registry document must not be empty.',
      );
    }

    final String sourceSnapshotFingerprint = _fingerprint(documentData);

    return GitHubRegistryDocumentSourceResult(
      content: documentData,
      documentPath: documentPath,
      requestedRef: ref,
      sourceRevision: sourceRevision,
      sourceSnapshotFingerprint: sourceSnapshotFingerprint,
    );
  }

  Map<String, String> _headers(String mediaType) {
    return <String, String>{
      'Accept': mediaType,
      'User-Agent': _userAgent,
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}

String _fingerprint(String source) {
  const int offsetBasis = 0xcbf29ce484222325;
  const int prime = 0x100000001b3;
  const int mask = 0xffffffffffffffff;

  int hash = offsetBasis;

  for (final int byte in utf8.encode(source)) {
    hash ^= byte;
    hash = (hash * prime) & mask;
  }

  return 'fnv1a64:${hash.toRadixString(16).padLeft(16, '0')}';
}

String _requiredValue(String value, String parameterName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      parameterName,
      'GitHub registry document source value must not be empty.',
    );
  }

  return normalized;
}

String _normalizeDocumentPath(String value) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      'documentPath',
      'GitHub registry document path must not be empty.',
    );
  }

  final List<String> segments = normalized
      .split('/')
      .map((String segment) => segment.trim())
      .toList(growable: false);

  if (segments.any((String segment) => segment.isEmpty)) {
    throw ArgumentError.value(
      value,
      'documentPath',
      'GitHub registry document path must not contain empty segments.',
    );
  }

  return segments.join('/');
}
