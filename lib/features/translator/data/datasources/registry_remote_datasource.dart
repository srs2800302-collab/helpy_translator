import 'dart:convert';
import 'dart:io';

import '../../../../core/config/app_config.dart';

abstract interface class RegistryRemoteDataSource {
  Future<List<String>> loadCanonicalClientRules();
}

final class RegistryRemoteDataSourceImpl implements RegistryRemoteDataSource {
  const RegistryRemoteDataSourceImpl({
    required this.appConfig,
  });

  final AppConfig appConfig;

  static const List<String> _prefixes = <String>[
    'Вы не обязаны',
    'Подготовьте',
    'Уберите',
  ];

  @override
  Future<List<String>> loadCanonicalClientRules() async {
    final String registryText = await _loadRegistryTextFromGitHub();
    return _extractCanonicalClientRules(registryText);
  }

  Future<String> _loadRegistryTextFromGitHub() async {
    final Uri uri = Uri.https(
      'api.github.com',
      '/repos/${appConfig.githubOwner}/${appConfig.githubRepo}/contents/${appConfig.githubRegistryPath}',
      <String, String>{
        'ref': appConfig.githubRegistryRef,
      },
    );

    final HttpClient httpClient = HttpClient();

    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github.raw');
      request.headers.set(HttpHeaders.userAgentHeader, 'helpy-translator');

      if (appConfig.githubToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${appConfig.githubToken}',
        );
      }

      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'GitHub Registry load failed: HTTP ${response.statusCode}\n$body',
        );
      }

      return body;
    } finally {
      httpClient.close(force: true);
    }
  }

  List<String> _extractCanonicalClientRules(String text) {
    final RegExp blockPattern = RegExp(
      r'## Client Rules Language & Translation Standard(.*?)(?:\n## |\$)',
      dotAll: true,
    );

    final Match? match = blockPattern.firstMatch(text);

    if (match == null) {
      throw Exception(
        'Client Rules Language & Translation Standard block not found.',
      );
    }

    final List<String> result = <String>[];

    for (final String raw in match.group(1)!.split('\n')) {
      final String line = raw.trim();

      if (!line.startsWith('- ')) {
        continue;
      }

      final String phrase = line.substring(2).trim();

      if (_prefixes.any(phrase.startsWith)) {
        result.add(phrase);
      }
    }

    final List<String> uniqueRules = result.toSet().toList(growable: false);

    if (uniqueRules.isEmpty) {
      throw Exception('No canonical client rules found in Registry.');
    }

    return uniqueRules;
  }
}
