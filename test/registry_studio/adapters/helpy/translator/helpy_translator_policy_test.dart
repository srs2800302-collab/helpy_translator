import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/translator/helpy_translator_policy.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  const HelpyTranslatorPolicy policy = HelpyTranslatorPolicy();

  test('direct prompt uses automatic detection and nine ASCII sections', () {
    final String prompt = policy.buildDirectSystemPrompt();

    expect(prompt, contains('Detect exactly one source language'));
    expect(prompt, contains('SOURCE LANGUAGE:'));
    expect(prompt, contains('SOURCE TEXT:'));
    expect(prompt, contains('RU:'));
    expect(prompt, contains('EN:'));
    expect(prompt, contains('TH:'));
    expect(prompt, contains('EN_TO_RU:'));
    expect(prompt, contains('TH_TO_RU:'));
    expect(prompt, contains('EN_TO_TH:'));
    expect(prompt, contains('TH_TO_EN:'));
    expect(prompt, isNot(contains('SOURCE LANGUAGE HINT')));
  });

  test('direct prompt has no hardcoded project terminology', () {
    final String prompt = policy.buildDirectSystemPrompt();

    expect(prompt, contains('No project glossary'));
    expect(prompt, isNot(contains('service professional')));
    expect(prompt, isNot(contains('ผู้ให้บริการ')));
    expect(prompt, isNot(contains('canonical service-marketplace')));
  });

  test('audit prompt forbids rewriting and invented canon', () {
    final String prompt = policy.buildAuditSystemPrompt();

    expect(prompt, contains('do not retranslate, rewrite'));
    expect(prompt, contains('do not invent a project glossary'));
    final String normalizedPrompt = prompt.replaceAll(RegExp(r'\s+'), ' ');

    expect(
      normalizedPrompt,
      contains(
        'Do not use external canonical terms because no dictionary is connected.',
      ),
    );
    expect(prompt, contains('do not choose a verdict'));
    expect(prompt, contains('reverse translations'));
    expect(prompt, contains('never as independent proof'));
  });

  test('audit user prompt contains direct and reverse diagnostic sections', () {
    final String prompt = policy.buildAuditUserPrompt(
      TranslationBundle(
        sourceLanguage: TranslationLanguage.ru,
        sourceText: 'Исходный текст.',
        ru: 'Исходный текст.',
        en: 'Provider wording.',
        th: 'ข้อความจากผู้ให้บริการ',
        reverseTranslations: ReverseTranslationBundle(
          enToRu: 'Исходный текст.',
          thToRu: 'Исходный текст.',
          enToTh: 'ข้อความจากผู้ให้บริการ',
          thToEn: 'Provider wording.',
        ),
      ),
    );

    expect(prompt, contains('SOURCE LANGUAGE:\nRU'));
    expect(prompt, contains('EN:\nProvider wording.'));
    expect(prompt, contains('TH:\nข้อความจากผู้ให้บริการ'));
    expect(prompt, contains('EN_TO_RU:\nИсходный текст.'));
    expect(prompt, contains('TH_TO_EN:\nProvider wording.'));
  });
}
