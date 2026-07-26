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

  test('direct prompt preserves generic service-role granularity', () {
    final String prompt = const HelpyTranslatorPolicy()
        .buildDirectSystemPrompt();

    expect(prompt, contains('Preserve role granularity'));
    expect(prompt, contains('service professional'));
    expect(prompt, contains('Do not use EN "master"'));
    expect(prompt, contains('"ผู้ให้บริการ"'));
    expect(prompt, contains('Never infer carpenter'));
    expect(prompt, contains('unless SOURCE TEXT explicitly names it'));
  });

  test('audit prompt separates primary and reverse evidence', () {
    final String prompt = const HelpyTranslatorPolicy()
        .buildAuditSystemPrompt();
    final String normalizedPrompt = prompt.replaceAll(RegExp(r'\s+'), ' ');

    expect(normalizedPrompt, contains('PRIMARY EVIDENCE'));
    expect(normalizedPrompt, contains('SECONDARY DIAGNOSTIC EVIDENCE'));
    expect(
      normalizedPrompt,
      contains('A finding that cites only a reverse section is forbidden'),
    );
    expect(
      normalizedPrompt,
      contains('Confirm every finding directly against SOURCE TEXT'),
    );
    expect(normalizedPrompt, contains('state both readings explicitly'));
    expect(normalizedPrompt, contains('job/work'));
  });
}
