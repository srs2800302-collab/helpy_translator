import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/translator/helpy_translator_policy.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  test('audit prompt exposes strict structured JSON contract', () {
    final String prompt = const HelpyTranslatorPolicy()
        .buildAuditSystemPrompt();

    for (final String key in <String>[
      '"EN_TO_RU"',
      '"TH_TO_RU"',
      '"EN_TO_TH"',
      '"TH_TO_EN"',
      '"findings"',
      '"category"',
      '"section"',
      '"source_fragment"',
      '"translation_fragment"',
      '"reason"',
      '"impact"',
      '"correct_variant"',
      '"source_ambiguity"',
    ]) {
      expect(prompt, contains(key));
    }

    expect(prompt, contains('exactly these five keys'));
    expect(prompt, contains('only from the exact EN value'));
    expect(prompt, contains('only from the exact TH value'));
    expect(prompt, contains('Do not use SOURCE TEXT or RU to repair'));
    expect(prompt, contains('Preserve any direct-translation drift'));
    expect(prompt, contains('three nonempty semantically equivalent'));
    expect(prompt, contains('"ru"'));
    expect(prompt, contains('"en"'));
    expect(prompt, contains('"th"'));
    expect(prompt, contains('JSON null'));
    expect(prompt, contains('do not search'));
    expect(prompt, contains('predetermined error'));
    expect(prompt, contains('do not report an unsupported one'));
    expect(prompt, contains('evidence is insufficient'));
    expect(prompt, contains('Do not invent issues'));
    expect(prompt, contains('exactly one JSON object'));
    expect(prompt, contains('Do not add unknown keys'));
    expect(prompt, contains('Do not omit required keys'));
    expect(prompt, contains('Do not use Markdown fences'));
    expect(prompt, contains('Do not assume that the translation is correct'));
    expect(prompt, matches(RegExp(r'do not waive a supported\s+issue')));
    expect(prompt, isNot(contains('MEANING_FINDINGS:')));
  });

  test('translation prompt requires only five direct sections', () {
    final String prompt = const HelpyTranslatorPolicy()
        .buildDirectSystemPrompt();

    final List<String> expectedLabels = <String>[
      'SOURCE LANGUAGE',
      'SOURCE TEXT',
      'RU',
      'EN',
      'TH',
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
    expect(prompt, contains('direct RU, EN and TH formulations only'));
    expect(prompt, contains('All five sections are required'));
    expect(prompt, contains('Do not return reverse translations'));
    expect(prompt, isNot(contains('EN_TO_RU:')));
    expect(prompt, isNot(contains('TH_TO_EN:')));
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

  test('audit user prompt contains only direct evidence', () {
    final String prompt = const HelpyTranslatorPolicy().buildAuditUserPrompt(
      sourceLanguage: TranslationLanguage.ru,
      sourceText: 'Исходный текст.',
      ru: 'Исходный текст.',
      en: 'Source text.',
      th: 'ข้อความต้นฉบับ',
    );

    final List<String> labels =
        RegExp(
              r'^(SOURCE LANGUAGE|SOURCE TEXT|RU|EN|TH|EN_TO_RU|TH_TO_RU|EN_TO_TH|TH_TO_EN|findings):$',
              multiLine: true,
            )
            .allMatches(prompt)
            .map((RegExpMatch match) => match.group(1)!)
            .toList(growable: false);

    expect(labels, <String>[
      'SOURCE LANGUAGE',
      'SOURCE TEXT',
      'RU',
      'EN',
      'TH',
    ]);
  });
}
