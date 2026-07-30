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
    expect(prompt, contains('do not waive a supported issue'));
  });

  test('translation prompt requires one atomic nine-section bundle', () {
    final String prompt = const HelpyTranslatorPolicy()
        .buildDirectSystemPrompt();

    final List<String> expectedLabels = <String>[
      'SOURCE LANGUAGE',
      'SOURCE TEXT',
      'RU',
      'EN',
      'TH',
      'EN_TO_RU',
      'TH_TO_RU',
      'EN_TO_TH',
      'TH_TO_EN',
    ];

    final List<String> actualLabels =
        RegExp(
              r'^(SOURCE LANGUAGE|SOURCE TEXT|RU|EN|TH|EN_TO_RU|TH_TO_RU|EN_TO_TH|TH_TO_EN):$',
              multiLine: true,
            )
            .allMatches(prompt)
            .map((RegExpMatch match) => match.group(1)!)
            .toList(growable: false);

    expect(actualLabels, expectedLabels);
    expect(prompt, contains('one atomic translation bundle'));
    expect(prompt, contains('All nine sections are required'));
    expect(prompt, contains('only from the exact EN and TH values'));
    expect(prompt, contains('Preserve any direct-translation drift'));
    expect(prompt, contains('Preserve role granularity'));
    expect(prompt, contains('service professional'));
    expect(prompt, contains('Do not use EN "master"'));
    expect(prompt, contains('"ผู้ให้บริการ"'));
    expect(prompt, contains('Never infer carpenter'));
    expect(prompt, contains('unless SOURCE TEXT explicitly names it'));
    expect(prompt, contains('editorially rewrite it'));
  });

  test('audit prompt is neutral and requires grounded evidence', () {
    final HelpyTranslatorPolicy policy = const HelpyTranslatorPolicy();
    final String auditPrompt = policy.buildAuditSystemPrompt();
    final String normalizedPrompt = auditPrompt.replaceAll(RegExp(r'\s+'), ' ');
    final String productionPrompts = <String>[
      policy.buildDirectSystemPrompt(),
      auditPrompt,
    ].join('\n').toLowerCase();

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
    expect(
      normalizedPrompt,
      contains('do not search for a predetermined error'),
    );
    expect(normalizedPrompt, contains('exact material impact'));
    expect(normalizedPrompt, contains('relevant ambiguity in SOURCE TEXT'));

    for (final String forbidden in <String>[
      'варочная панель',
      'cooktop',
      'hob',
      'oven',
      'เตาอบ',
    ]) {
      expect(productionPrompts, isNot(contains(forbidden)));
    }
  });
}
