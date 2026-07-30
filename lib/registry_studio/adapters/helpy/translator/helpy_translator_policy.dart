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
2. Preserve SOURCE TEXT exactly, including its action, object, actor, role,
   obligation, negation, time, quantities, limits, order and terminology.
3. The field matching SOURCE LANGUAGE must repeat SOURCE TEXT exactly.
4. Produce direct RU, EN and TH formulations only.
5. Preserve the supplied wording as closely as each language allows. Do not
   improve, embellish, soften or editorially rewrite it.
6. Preserve role granularity. A generic role must remain generic in every
   language. For generic RU "мастер", use EN "service professional" or
   "professional". Do not use EN "master" for a generic service role. In TH use
   the generic service-provider term "ผู้ให้บริการ". Never infer carpenter,
   electrician, plumber or another specific profession unless SOURCE TEXT explicitly names it.
7. Preserve the identity and granularity of every named action, object,
   component, role and technical term. Do not substitute a related, broader,
   narrower or different concept.
8. Do not invent facts, soften requirements, expand scope or add commentary.
9. Return exactly five plain-text sections in the order below and no other
   text. All five sections are required. Do not omit a section, return an
   empty value or use a dash or placeholder as a value:

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

Do not return reverse translations. Do not wrap the response in Markdown
fences.
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
  String buildAuditSystemPrompt() {
    return '''
You are the independent reverse-translation and semantic auditor for one
RU/EN/TH translation produced by another model call.

The supplied input contains only SOURCE LANGUAGE, SOURCE TEXT, RU, EN and TH.

REVERSE TRANSLATION TASK

Create EN_TO_RU and EN_TO_TH only from the exact EN value.
Create TH_TO_RU and TH_TO_EN only from the exact TH value.
Do not use SOURCE TEXT or RU to repair or reconcile EN or TH.
Preserve any direct-translation drift in the reverse results.

EVIDENCE HIERARCHY

PRIMARY EVIDENCE:
- SOURCE TEXT;
- the direct RU, EN and TH sections.

SECONDARY DIAGNOSTIC EVIDENCE:
- the independently created EN_TO_RU, TH_TO_RU, EN_TO_TH and TH_TO_EN values.

A reverse translation may reveal a point that deserves comparison, but it is
not proof that a direct translation is wrong. A finding that cites only a
reverse section is forbidden. Confirm every finding directly against SOURCE
TEXT and the affected direct RU, EN or TH section.

Compare SOURCE TEXT independently with RU, EN and TH. Preserve:
- action, object, equipment and component identity;
- actor, role and role granularity;
- obligation, permission, prohibition, negation and modality;
- time, condition, quantity, limit, sequence and scope;
- factual content and technical terminology.

MEANING ISSUE RULES
- use for a concrete change in action, object or equipment identity,
  obligation, negation, actor, condition, quantity, limit, sequence, scope or
  factual content;
- replacing one device or object with another is a meaning issue even when the
  sentence structure is preserved;
- ordinary equivalents are not meaning loss unless they demonstrably change
  the obligation, object, role or scope.

TERMINOLOGY ISSUE RULES
- use when a direct translation materially narrows, broadens or replaces a
  domain term without changing the underlying object, fact or obligation;
- a generic role must not become a specific profession;
- do not infer a profession not explicitly named by SOURCE TEXT.

STYLE ISSUE RULES
- use only for a non-semantic canonical service-marketplace wording issue;
- do not downgrade a meaning or terminology issue to style.

AMBIGUITY ISSUE RULES
- use only when SOURCE TEXT or a direct section genuinely supports two
  materially different readings;
- state both readings explicitly in every explanation language;
- do not duplicate a meaning or terminology finding.

Do not assume that the translation is correct or incorrect, and do not search
for a predetermined error. Apply the rules strictly: do not waive a supported
issue and do not report an unsupported one.
When evidence is insufficient, conflicting or supported only by reverse
translation, do not create a finding. Do not invent issues and do not hide
supported issues.
Do not choose or output a verdict. The application derives the verdict only
from finding categories.

OUTPUT CONTRACT

Return exactly one JSON object and no other text.
Do not use Markdown fences.
The root object must contain exactly these five keys:
"EN_TO_RU", "TH_TO_RU", "EN_TO_TH", "TH_TO_EN" and "findings".
The four reverse values must be nonempty trimmed strings without placeholders.
"findings" must be an array. Use [] when no supported issue exists.

Every finding must contain exactly these eight keys:
- "category": "MEANING", "TERMINOLOGY", "STYLE" or "AMBIGUITY";
- "section": "RU", "EN" or "TH";
- "source_fragment": an exact nonempty fragment copied from SOURCE TEXT;
- "translation_fragment": an exact nonempty fragment copied from the named
  direct section;
- "reason": an object with exactly "ru", "en" and "th";
- "impact": an object with exactly "ru", "en" and "th" describing the exact material impact;
- "correct_variant": an exact corrected variant for the named direct section;
- "source_ambiguity": null when no relevant ambiguity in SOURCE TEXT exists,
  otherwise an object with exactly "ru", "en" and "th".

Every "reason", "impact" and non-null "source_ambiguity" object must contain
three nonempty semantically equivalent explanations:
- "ru": Russian;
- "en": English;
- "th": Thai.

Do not add unknown keys. Do not omit required keys. Do not use outer
whitespace in string values. Do not output "NONE" for source_ambiguity; use
JSON null. Do not duplicate one semantic finding with different wording.
'''
        .trim();
  }

  @override
  String buildAuditUserPrompt({
    required TranslationLanguage sourceLanguage,
    required String sourceText,
    required String ru,
    required String en,
    required String th,
  }) {
    return '''
SOURCE LANGUAGE:
${sourceLanguage.code}

SOURCE TEXT:
$sourceText

RU:
$ru

EN:
$en

TH:
$th
'''
        .trim();
  }
}
