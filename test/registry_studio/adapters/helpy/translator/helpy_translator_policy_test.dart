import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/translator/helpy_translator_policy.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  const HelpyTranslatorPolicy policy = HelpyTranslatorPolicy();

  test('direct prompt locks five-key JSON and translation-only behavior', () {
    final String prompt = policy.buildDirectSystemPrompt();

    for (final String key in <String>[
      'SOURCE_LANGUAGE',
      'SOURCE_TEXT',
      'RU',
      'EN',
      'TH',
    ]) {
      expect(prompt, contains('"$key"'));
    }
    expect(prompt, contains('A lexical gap is allowed'));
    expect(prompt, contains('Do not audit or output a verdict'));
    expect(prompt, isNot(contains('EN_TO_RU')));
  });

  test('direct user prompt serializes input as JSON data', () {
    final Map<String, Object?> prompt =
        jsonDecode(
              policy.buildDirectUserPrompt(
                TranslatorWorkRequest(
                  sourceText: 'мастер должен установить варочную панель',
                  sourceLanguageHint: TranslationLanguage.ru,
                  engineerContext: 'монтаж на объекте',
                ),
              ),
            )
            as Map<String, Object?>;

    expect(prompt, <String, Object?>{
      'SOURCE_TEXT': 'мастер должен установить варочную панель',
      'SOURCE_LANGUAGE_HINT': 'RU',
      'ENGINEER_CONTEXT': 'монтаж на объекте',
    });
  });

  test('audit prompt matches laboratory evidence contract', () {
    final String prompt = policy.buildAuditSystemPrompt();

    expect(prompt, contains('PAIR_RESULTS'));
    expect(prompt, contains('RU_EN'));
    expect(prompt, contains('RU_TH'));
    expect(prompt, contains('EN_TH'));
    expect(prompt, contains('CLEAR: exact identity is positively established'));
    expect(prompt, contains('Not disproved'));
    expect(prompt, contains('LEFT, RIGHT and REASON'));
    expect(prompt, contains('at most 18 words'));
    expect(prompt, contains('Unresolved ambiguity is U'));
    expect(prompt, isNot(contains('correct_variant')));
    expect(prompt, isNot(contains('"VERDICT"')));
  });

  test('audit user prompt contains only RU EN TH', () {
    final Map<String, Object?> prompt =
        jsonDecode(
              policy.buildAuditUserPrompt(
                ru: 'установить варочную панель',
                en: 'install the cooktop',
                th: 'ติดตั้งเตาไฟ',
              ),
            )
            as Map<String, Object?>;

    expect(prompt, <String, Object?>{
      'RU': 'установить варочную панель',
      'EN': 'install the cooktop',
      'TH': 'ติดตั้งเตาไฟ',
    });
  });

  test('exact challenger is global, audit-blind and evidence-bearing', () {
    final String system = policy.buildExactChallengerSystemPrompt();
    final Map<String, Object?> user =
        jsonDecode(
              policy.buildExactChallengerUserPrompt(
                ru: 'установить варочную панель',
                en: 'install the cooktop',
                th: 'ติดตั้งเตาไฟ',
              ),
            )
            as Map<String, Object?>;

    expect(system, contains('You never receive the general audit'));
    expect(system, contains('RU_EN, RU_TH and EN_TH'));
    expect(system, contains('RESULT and DISQUALIFIERS'));
    expect(system, contains('BLOCKED'));
    expect(system, contains('UNPROVEN'));
    expect(system, contains('LEFT, RIGHT and REASON'));
    expect(system, isNot(contains('CANONICAL_DRIFT')));
    expect(user, <String, Object?>{
      'RU': 'установить варочную панель',
      'EN': 'install the cooktop',
      'TH': 'ติดตั้งเตาไฟ',
    });
  });
}
