import '../../../translator/application/translator_provider.dart';
import '../../../translator/domain/translator_models.dart';

final class HelpyTranslatorPolicy implements TranslatorPolicy {
  const HelpyTranslatorPolicy();

  @override
  String buildDirectSystemPrompt() {
    return '''
You are a multilingual translation provider.

Translate one supplied text between RU, EN and TH.
Rules:
1. Detect exactly one source language: RU, EN or TH.
2. Preserve SOURCE TEXT exactly.
3. The field matching SOURCE LANGUAGE must repeat SOURCE TEXT exactly.
4. Return faithful direct RU, EN and TH translations.
5. Do not add facts, commentary, explanations or alternative versions.
6. No project glossary or canonical terminology dictionary is supplied.
7. Return exactly five plain-text sections in this order and no other text:
SOURCE LANGUAGE:
RU or EN or TH

SOURCE TEXT:
the exact supplied source text

RU:
the RU translation

EN:
the EN translation

TH:
the TH translation

Do not wrap the response in Markdown fences.
'''
        .trim();
  }

  @override
  String buildDirectUserPrompt(TranslatorWorkRequest request) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('SOURCE TEXT:')
      ..writeln(request.sourceText);

    if (request.engineerContext != null) {
      buffer
        ..writeln()
        ..writeln('ENGINEER CONTEXT:')
        ..writeln(request.engineerContext);
    }

    return buffer.toString().trim();
  }

  @override
  String buildAuditSystemPrompt() {
    return '''
You are an independent semantic auditor.

You receive the exact direct provider output: SOURCE LANGUAGE, SOURCE TEXT,
RU, EN and TH. Assess only those supplied texts.

Mandatory honesty rules:
- do not retranslate, rewrite or propose replacement wording;
- do not invent a project glossary or canonical terminology standard;
- do not claim conformance to an external dictionary;
- do not choose a verdict and do not output YES/NO flags;
- report only findings directly supported by SOURCE TEXT and the affected
  direct RU, EN or TH translation.

MEANING_FINDINGS:
Use only for a concrete change in actor, obligation, negation, condition,
quantity, limit, order, scope or factual content.

TERMINOLOGY_FINDINGS:
Use only for a concrete mistranslation, unjustified narrowing/broadening or
inconsistency visible in the supplied texts. Do not use external canonical
terms because no dictionary is connected.

STYLE_FINDINGS:
Use only for a clear target-language readability or grammar issue that does not
change meaning. Do not impose a project-specific style.

AMBIGUITY_FINDINGS:
Use only when a supplied direct translation genuinely supports two materially
different readings. State both readings.

When evidence is insufficient, output NONE. Do not hide supported issues.
Return exactly the following four plain-text sections in this exact order.
Every label must be written exactly as shown, followed by a colon on the same
line. Do not add a preamble, Markdown heading, code fence, verdict, summary or
any other text.

MEANING_FINDINGS:
NONE

TERMINOLOGY_FINDINGS:
NONE

STYLE_FINDINGS:
NONE

AMBIGUITY_FINDINGS:
NONE

Replace NONE only for a supported issue. Write each supported finding as a
concise Russian bullet point beginning with "- ".
'''
        .trim();
  }

  @override
  String buildAuditUserPrompt(TranslationBundle bundle) {
    final StringBuffer buffer = StringBuffer();

    for (final MapEntry<String, String> entry
        in bundle.directSections.entries) {
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
