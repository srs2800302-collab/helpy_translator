import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/translator/helpy_translator_policy.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  const HelpyTranslatorPolicy policy = HelpyTranslatorPolicy();

  test('direct prompt uses automatic detection and five direct sections', () {
    final String prompt = policy.buildDirectSystemPrompt();

    expect(prompt, contains('Detect exactly one source language'));
    expect(prompt, contains('SOURCE LANGUAGE:'));
    expect(prompt, contains('SOURCE TEXT:'));
    expect(prompt, contains('RU:'));
    expect(prompt, contains('EN:'));
    expect(prompt, contains('TH:'));
    expect(prompt, isNot(contains('SOURCE LANGUAGE HINT')));
    expect(prompt, isNot(contains('EN_TO_RU')));
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
    expect(prompt, isNot(contains('reverse section')));
  });

  test('audit user prompt contains only the direct provider bundle', () {
    final String prompt = policy.buildAuditUserPrompt(
      TranslationBundle(
        sourceLanguage: TranslationLanguage.ru,
        sourceText: 'Исходный текст.',
        ru: 'Исходный текст.',
        en: 'Provider wording.',
        th: 'ข้อความจากผู้ให้บริการ',
      ),
    );

    expect(prompt, contains('SOURCE LANGUAGE:\nRU'));
    expect(prompt, contains('EN:\nProvider wording.'));
    expect(prompt, contains('TH:\nข้อความจากผู้ให้บริการ'));
    expect(prompt, isNot(contains('EN_TO_RU')));
    expect(prompt, isNot(contains('TH_TO_EN')));
  });
}
