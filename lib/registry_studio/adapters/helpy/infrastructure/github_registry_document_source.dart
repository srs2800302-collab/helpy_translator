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
  static const String _rawMediaType = 'application/vnd.github.raw+json';
  static const String _userAgent = 'registry-studio';

  final Dio dio;
  final String owner;
  final String repository;
  final String documentPath;
  final String ref;
  final String token;

  Future<GitHubRegistryDocumentSourceResult> load() async {
    final Uri uri = Uri(
      scheme: 'https',
      host: _host,
      pathSegments: <String>[
        'repos',
        owner,
        repository,
        'contents',
        ...documentPath.split('/'),
      ],
      queryParameters: <String, String>{'ref': ref},
    );

    final Response<dynamic> response = await dio.getUri<dynamic>(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (int? status) => true,
        headers: <String, String>{
          'Accept': _rawMediaType,
          'User-Agent': _userAgent,
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );

    final int? statusCode = response.statusCode;

    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw StateError(
        'GitHub registry document load failed: '
        'HTTP ${statusCode ?? "unknown"}.',
      );
    }

    final Object? data = response.data;

    if (data is! String) {
      throw const FormatException(
        'GitHub registry document response must be raw text.',
      );
    }

    if (data.trim().isEmpty) {
      throw const FormatException(
        'GitHub registry document must not be empty.',
      );
    }

    final String sourceSnapshotFingerprint = _fingerprint(data);

    return GitHubRegistryDocumentSourceResult(
      content: data,
      documentPath: documentPath,
      requestedRef: ref,
      sourceRevision: sourceSnapshotFingerprint,
      sourceSnapshotFingerprint: sourceSnapshotFingerprint,
    );
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
