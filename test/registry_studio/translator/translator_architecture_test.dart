import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('universal Translator does not import project adapter code', () {
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
        reason: '${file.path} imports project-specific adapter code.',
      );
      expect(
        source,
        isNot(contains('Helpy')),
        reason: '${file.path} leaks project-specific knowledge.',
      );
    }
  });

  test('workspace is a bounded composition root', () {
    final File workspace = File(
      'lib/registry_studio/translator/presentation/'
      'translator_workspace_view.dart',
    );
    final String source = workspace.readAsStringSync();
    final int lineCount = source.split('\n').length;

    expect(lineCount, lessThanOrEqualTo(300));

    for (final String forbidden in <String>[
      'class _AccessKeyDialog',
      'class _SourceLanguageMenu',
      'class _ProgressCard',
      'class _FailureCard',
      'class _MessageCard',
      'class _TranslationReportView',
      'class _VerdictCard',
      'class _AuditFindingsCard',
    ]) {
      expect(
        source,
        isNot(contains(forbidden)),
        reason: 'Workspace owns extracted responsibility: $forbidden',
      );
    }
  });

  test('leaf presentation capabilities do not own stores or blocs', () {
    const List<String> leafFiles = <String>[
      'lib/registry_studio/translator/presentation/access_key/'
          'translator_access_key_dialog.dart',
      'lib/registry_studio/translator/presentation/source/'
          'translator_source_panel.dart',
      'lib/registry_studio/translator/presentation/execution/'
          'translator_run_actions.dart',
      'lib/registry_studio/translator/presentation/status/'
          'translator_status_cards.dart',
      'lib/registry_studio/translator/presentation/report/'
          'translator_report_view.dart',
    ];

    for (final String path in leafFiles) {
      final String source = File(path).readAsStringSync();

      for (final String forbidden in <String>[
        'flutter_bloc',
        'TranslatorCubit',
        'TranslatorAccessKeyCubit',
        'TranslatorAccessKeyStore',
        'TranslatorDraftStore',
        'TranslatorProvider',
      ]) {
        expect(
          source,
          isNot(contains(forbidden)),
          reason: '$path owns orchestration dependency: $forbidden',
        );
      }
    }
  });

  test('application layer never imports presentation', () {
    final Directory root = Directory(
      'lib/registry_studio/translator/application',
    );

    for (final File file
        in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.dart'))) {
      final String source = file.readAsStringSync();

      expect(
        source,
        isNot(contains('/presentation/')),
        reason: '${file.path} imports presentation.',
      );
      expect(
        source,
        isNot(contains('../presentation/')),
        reason: '${file.path} imports presentation.',
      );
    }
  });

  test('presentation capabilities avoid part coupling and oversized files', () {
    final Directory root = Directory(
      'lib/registry_studio/translator/presentation',
    );

    for (final File file
        in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.dart'))) {
      final String source = file.readAsStringSync();
      final int lineCount = source.split('\n').length;

      expect(
        source,
        isNot(contains(RegExp(r'^\s*part\s', multiLine: true))),
        reason: '${file.path} uses shared-library part coupling.',
      );
      expect(
        lineCount,
        lessThanOrEqualTo(400),
        reason: '${file.path} exceeds the presentation file budget.',
      );
    }
  });

  test('capability contract documents stable B and C extension points', () {
    final File contract = File('docs/architecture/translator_capability.md');
    final String source = contract.readAsStringSync();

    expect(contract.existsSync(), isTrue);
    expect(source, contains('History extension point'));
    expect(source, contains('Canonical actions extension point'));
    expect(source, contains('No behavior change'));
  });
}
