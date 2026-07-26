import '../../../translator/application/translator_provider.dart';
import '../../../translator/domain/translator_models.dart';

final class HelpyTranslatorPolicy implements TranslatorPolicy {
  const HelpyTranslatorPolicy();

  @override
  String buildDirectSystemPrompt() {
    return '''
You are the strict multilingual translation engine for Helpy, a service
marketplace that connects clients with home-service professionals.

Translate one engineering phrase between RU, EN and TH.

Mandatory rules:
1. Detect exactly one source language: RU, EN or TH.
2. Preserve SOURCE TEXT exactly, including its meaning, obligation,
   negation, quantities, limits, order and terminology.
3. The field matching SOURCE LANGUAGE must repeat SOURCE TEXT exactly.
4. Produce direct RU, EN and TH formulations only.
5. Keep concise canonical service-marketplace style.
6. Do not invent facts, soften requirements, expand scope or add commentary.
7. Return exactly five plain-text sections in this order and no other text:

SOURCE LANGUAGE:
RU or EN or TH

SOURCE TEXT:
the exact supplied source text

RU:
the RU formulation

EN:
the EN formulation

TH:
the TH formulation

Do not wrap the response in Markdown fences.
'''
        .trim();
  }

  @override
  String buildDirectUserPrompt(TranslatorWorkRequest request) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('SOURCE TEXT:')
      ..writeln(request.sourceText);

    if (request.sourceLanguageHint != null) {
      buffer
        ..writeln()
        ..writeln('SOURCE LANGUAGE HINT:')
        ..writeln(request.sourceLanguageHint!.code);
    }

    if (request.engineerContext != null) {
      buffer
        ..writeln()
        ..writeln('ENGINEER CONTEXT:')
        ..writeln(request.engineerContext);
    }

    return buffer.toString().trim();
  }

  @override
  String buildReverseSystemPrompt() {
    return '''
You are an independent reverse-translation engine.

You receive only EN and TH direct translations. You do not receive the
original source text and must not infer it from hidden context.

Return:
- EN translated literally to RU;
- TH translated literally to RU;
- EN translated literally to TH;
- TH translated literally to EN.

Preserve obligations, negation, quantities, limits, order and terminology.
Do not reconcile differences between EN and TH. Do not add explanations.

Return exactly four plain-text sections in this order and no other text:

EN_TO_RU:
the literal RU reverse translation of EN

TH_TO_RU:
the literal RU reverse translation of TH

EN_TO_TH:
the literal TH reverse translation of EN

TH_TO_EN:
the literal EN reverse translation of TH

Do not wrap the response in Markdown fences.
'''
        .trim();
  }

  @override
  String buildReverseUserPrompt({required String en, required String th}) {
    return '''
EN:
$en

TH:
$th
'''
        .trim();
  }

  @override
  String buildAuditSystemPrompt() {
    return '''
You are an independent semantic auditor for engineering translations.

You receive a complete nine-section RU/EN/TH translation bundle.
Do not choose a verdict and do not output YES/NO flags.

Return exactly four sections in this order:
MEANING_FINDINGS
TERMINOLOGY_FINDINGS
STYLE_FINDINGS
AMBIGUITY_FINDINGS

For each section:
- write NONE when no issue exists;
- otherwise write one or more concise Russian bullet points beginning with "- ".

Find only concrete differences supported by the supplied text.
Meaning findings include changed obligation, negation, scope, actor,
condition, quantity, limit, sequence or factual content.
Terminology findings include inconsistent or materially changed terms.
Style findings include canonical service-marketplace style differences that
do not change meaning.
Ambiguity findings include wording that allows more than one material reading.

Do not invent issues. Do not hide issues. Do not include any other section.
'''
        .trim();
  }

  @override
  String buildAuditUserPrompt(TranslationBundle bundle) {
    final StringBuffer buffer = StringBuffer();

    for (final MapEntry<String, String> entry in bundle.nineSections.entries) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }

      buffer
        ..writeln('${entry.key}:')
        ..writeln(entry.value);
    }

    return buffer.toString().trim();
  }
}
