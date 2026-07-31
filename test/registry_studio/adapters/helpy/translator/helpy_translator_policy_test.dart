import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/translator/helpy_translator_policy.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  const HelpyTranslatorPolicy policy = HelpyTranslatorPolicy();

  test('direct prompt locks five-key JSON and forbids verdicts', () {
    final String prompt = policy.buildDirectSystemPrompt();

    expect(prompt, contains('"SOURCE_LANGUAGE"'));
    expect(prompt, contains('"SOURCE_TEXT"'));
    expect(prompt, contains('"RU"'));
    expect(prompt, contains('"EN"'));
    expect(prompt, contains('"TH"'));
    expect(prompt, contains('exactly these five keys'));
    expect(prompt, contains('Do not add explanations'));
    expect(prompt, isNot(contains('EN_TO_RU')));
    expect(prompt, isNot(contains('findings')));
  });

  test('direct user prompt serializes source text as JSON data', () {
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

  test('audit prompt defines compact fail-closed three-pair contract', () {
    final String prompt = policy.buildAuditSystemPrompt();

    expect(prompt, contains('RU_EN'));
    expect(prompt, contains('RU_TH'));
    expect(prompt, contains('EN_TH'));
    expect(prompt, contains('"CLEAR"'));
    expect(prompt, contains('"BLOCKED"'));
    expect(prompt, contains('"UNPROVEN"'));
    expect(prompt, contains('"X"'));
    expect(prompt, contains('"U"'));
    expect(prompt, contains('at most two objects'));
    expect(prompt, contains('never ambiguity/X'));
    expect(prompt, contains('Do not output translations'));
    expect(prompt, isNot(contains('correct_variant')));
    expect(prompt, contains('application verdict'));
    expect(prompt, isNot(contains('"VERDICT"')));
  });

  test('audit user prompt contains only the translated JSON bundle', () {
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

  test('exact challenger is pair-specific and has two outcomes', () {
    final String system = policy.buildExactChallengerSystemPrompt(
      TranslationPair.ruTh,
    );
    final String user = policy.buildExactChallengerUserPrompt(
      pair: TranslationPair.ruTh,
      leftText: 'варочная панель',
      rightText: 'เตาไฟ',
    );

    expect(system, contains('RU_TH'));
    expect(system, contains('"RESULT":"CLEAR"'));
    expect(system, contains('"RESULT":"NOT_CERTIFIED"'));
    expect(system, contains('surface difference alone'));
    expect(system, isNot(contains('CANONICAL_DRIFT')));

    final Map<String, Object?> userData =
        jsonDecode(user) as Map<String, Object?>;
    expect(userData, <String, Object?>{
      'PAIR': 'RU_TH',
      'LEFT_LANGUAGE': 'RU',
      'LEFT_TEXT': 'варочная панель',
      'RIGHT_LANGUAGE': 'TH',
      'RIGHT_TEXT': 'เตาไฟ',
    });
  });
}
