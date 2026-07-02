import 'dart:convert';
import 'dart:io';

import '../../../../core/config/app_config.dart';
import '../../../../core/persistence/registry_cache_persistence.dart';
import '../../domain/entities/registry_node.dart';

abstract interface class RegistryRemoteDataSource {
  Future<List<String>> loadCanonicalClientRules();

  Future<RegistryNode> loadRegistryTree();

  Future<RegistryNode> refreshRegistryTree();
}

final class RegistryRemoteDataSourceImpl implements RegistryRemoteDataSource {
  const RegistryRemoteDataSourceImpl({
    required this.appConfig,
    this.cachePersistence = const RegistryCachePersistence(),
  });

  final AppConfig appConfig;
  final RegistryCachePersistence cachePersistence;

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

  @override
  Future<RegistryNode> loadRegistryTree() async {
    final String? cachedText = await cachePersistence.load();

    if (cachedText != null) {
      return _buildRegistryTree(cachedText);
    }

    return refreshRegistryTree();
  }

  @override
  Future<RegistryNode> refreshRegistryTree() async {
    final String registryText = await _loadRegistryTextFromGitHub();
    await cachePersistence.save(registryText);
    return _buildRegistryTree(registryText);
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
      request.headers.set(HttpHeaders.userAgentHeader, 'helpy-registry-studio');

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

  RegistryNode _buildRegistryTree(String text) {
    final List<_MutableRegistryNode> stack = <_MutableRegistryNode>[
      _MutableRegistryNode(
        id: 'root',
        title: 'Registry',
        level: 0,
        lineNumber: 0,
      ),
    ];

    final List<String> lines = text.split('\n');

    for (int index = 0; index < lines.length; index++) {
      final String trimmed = lines[index].trim();
      final RegExpMatch? headingMatch =
          RegExp(r'^(#{2,6})\s+(.+)$').firstMatch(trimmed);

      if (headingMatch != null) {
        final int level = headingMatch.group(1)!.length;
        final String title = headingMatch.group(2)!.trim();

        final _MutableRegistryNode node = _MutableRegistryNode(
          id: 'line_${index + 1}',
          title: title,
          level: level,
          lineNumber: index + 1,
        );

        while (stack.isNotEmpty && stack.last.level >= level) {
          stack.removeLast();
        }

        stack.last.children.add(node);
        stack.add(node);
        continue;
      }

      if (trimmed.startsWith('- ') && stack.isNotEmpty) {
        final String phrase = trimmed.substring(2).trim();

        if (phrase.isNotEmpty) {
          stack.last.phrases.add(phrase);
        }
      }
    }

    return stack.first.toImmutable();
  }

  List<String> _extractCanonicalClientRules(String text) {
    final RegExp blockPattern = RegExp(
      r'## Rule Language & Translation Standard(.*?)(?:\n## |\$)',
      dotAll: true,
    );

    final Match? match = blockPattern.firstMatch(text);

    if (match == null) {
      throw Exception('Rule Language & Translation Standard block not found.');
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

final class _MutableRegistryNode {
  _MutableRegistryNode({
    required this.id,
    required this.title,
    required this.level,
    required this.lineNumber,
  });

  final String id;
  final String title;
  final int level;
  final int lineNumber;
  final List<String> phrases = <String>[];
  final List<_MutableRegistryNode> children = <_MutableRegistryNode>[];

  RegistryNode toImmutable() {
    return RegistryNode(
      id: id,
      title: title,
      level: level,
      lineNumber: lineNumber,
      phrases: List<String>.unmodifiable(phrases),
      children: List<RegistryNode>.unmodifiable(
        children.map((_MutableRegistryNode child) => child.toImmutable()),
      ),
    );
  }
}
