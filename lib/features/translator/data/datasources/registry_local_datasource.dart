import 'dart:io';

abstract interface class RegistryLocalDataSource {
  Future<List<String>> loadCanonicalClientRules();
}

final class RegistryLocalDataSourceImpl
    implements RegistryLocalDataSource {
  const RegistryLocalDataSourceImpl();

  static const String _registryPath =
      '/data/data/com.termux/files/home/projects/helpy/docs/architecture/Helpy_Architecture_Registry_v1.md';

  static const List<String> _prefixes = <String>[
    'Вы не обязаны',
    'Подготовьте',
    'Уберите',
  ];

  @override
  Future<List<String>> loadCanonicalClientRules() async {
    final File file = File(_registryPath);

    if (!await file.exists()) {
      throw Exception('Registry not found:\n$_registryPath');
    }

    final String text = await file.readAsString();

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

    return result.toSet().toList(growable: false);
  }
}
