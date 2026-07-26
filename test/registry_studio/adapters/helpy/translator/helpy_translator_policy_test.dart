import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/translator/helpy_translator_policy.dart';

void main() {
  test('audit prompt exposes exact parser-compatible section template', () {
    final String prompt = const HelpyTranslatorPolicy()
        .buildAuditSystemPrompt();

    final List<String> expectedLabels = <String>[
      'MEANING_FINDINGS',
      'TERMINOLOGY_FINDINGS',
      'STYLE_FINDINGS',
      'AMBIGUITY_FINDINGS',
    ];

    final List<String> actualLabels =
        RegExp(
              r'^(MEANING_FINDINGS|TERMINOLOGY_FINDINGS|STYLE_FINDINGS|AMBIGUITY_FINDINGS):$',
              multiLine: true,
            )
            .allMatches(prompt)
            .map((RegExpMatch match) => match.group(1)!)
            .toList(growable: false);

    expect(actualLabels, expectedLabels);

    for (final String label in expectedLabels) {
      expect(
        prompt.split('\n').where((String line) => line == '$label:'),
        hasLength(1),
      );
    }

    expect(prompt, contains('Do not add a preamble'));
    expect(prompt, contains('Do not choose a verdict'));
  });
}
