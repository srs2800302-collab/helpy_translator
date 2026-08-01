import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/translator/helpy_translator_policy.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_provider.dart';
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

  test('reverse diagnostics prompt is diagnostic-only and exact', () {
    final ExactCapabilityPolicy capabilityPolicy = policy;
    final String system = capabilityPolicy
        .buildReverseDiagnosticsSystemPrompt();
    final Map<String, Object?> user =
        jsonDecode(
              capabilityPolicy.buildReverseDiagnosticsUserPrompt(
                en: 'provider EN text',
                th: 'ข้อความจากผู้ให้บริการ',
              ),
            )
            as Map<String, Object?>;

    expect(system, contains('EN_TO_RU'));
    expect(system, contains('TH_TO_RU'));
    expect(system, contains('Do not reconcile'));
    expect(system, isNot(contains('"VERDICT"')));
    expect(user, <String, Object?>{
      'EN': 'provider EN text',
      'TH': 'ข้อความจากผู้ให้บริการ',
    });
  });

  test(
    'atom verification prompt handles one target without lab hardcoding',
    () {
      final ExactCapabilityPolicy capabilityPolicy = policy;
      final String system = capabilityPolicy
          .buildAtomVerificationSystemPrompt();
      final Map<String, Object?> user =
          jsonDecode(
                capabilityPolicy.buildAtomVerificationUserPrompt(
                  sourceRu: 'исполнитель завершит работу завтра',
                  targetLanguage: TranslationLanguage.en,
                  targetText: 'the worker will finish tomorrow',
                  reverseDiagnostic: 'работник закончит завтра',
                ),
              )
              as Map<String, Object?>;

      expect(system, contains('exactly one target language'));
      expect(system, contains('ASSESSMENTS'));
      expect(system, contains('S, C, U or X'));
      expect(system, isNot(contains('canonical_style')));
      expect(system, isNot(contains('"VERDICT"')));
      expect(system, isNot(contains('"REASON"')));
      for (final String forbidden in <String>[
        'cooktop',
        'oven',
        'master',
        'technician',
        'вароч',
        'духов',
        'เตาอบ',
        'หัวหน้า',
      ]) {
        expect(system.toLowerCase(), isNot(contains(forbidden.toLowerCase())));
      }
      expect(user, <String, Object?>{
        'SOURCE_RU': 'исполнитель завершит работу завтра',
        'TARGET_LANGUAGE': 'EN',
        'TARGET_TEXT': 'the worker will finish tomorrow',
        'REVERSE_DIAGNOSTIC': 'работник закончит завтра',
      });
    },
  );

  test(
    'atom verification user prompt rejects RU and altered input boundaries',
    () {
      final ExactCapabilityPolicy capabilityPolicy = policy;

      expect(
        () => capabilityPolicy.buildAtomVerificationUserPrompt(
          sourceRu: 'текст',
          targetLanguage: TranslationLanguage.ru,
          targetText: 'текст',
          reverseDiagnostic: 'текст',
        ),
        throwsArgumentError,
      );
      expect(
        () => capabilityPolicy.buildAtomVerificationUserPrompt(
          sourceRu: ' текст ',
          targetLanguage: TranslationLanguage.th,
          targetText: 'ข้อความ',
          reverseDiagnostic: 'текст',
        ),
        throwsArgumentError,
      );
    },
  );

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
