import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('universal Translator does not import Helpy adapter code', () {
    final Directory root = Directory('lib/registry_studio/translator');

    expect(root.existsSync(), isTrue);

    final List<File> dartFiles = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList(growable: false);

    expect(dartFiles, isNotEmpty);

    for (final File file in dartFiles) {
      final String source = file.readAsStringSync();

      expect(
        source,
        isNot(contains('/adapters/helpy/')),
        reason: '${file.path} imports Helpy-specific code.',
      );
      expect(
        source,
        isNot(contains('Helpy')),
        reason: '${file.path} leaks Helpy-specific knowledge.',
      );
    }
  });
}
