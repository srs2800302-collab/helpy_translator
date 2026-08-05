# Registry Studio Translator Honesty Contract v1

## 1. Immutable invariant

The only immutable Translator requirement is honesty.

Registry Studio Translator must not:

- add facts, context, intent, causes, examples, entities, or assumptions that are
  not supported by the user's source text;
- hide a detected addition, omission, contradiction, change of negation,
  quantity, participant, object, time, condition, modality, ambiguity, or other
  meaning;
- present uncertainty, provider failure, malformed output, missing evidence, or
  disagreement between model passes as confirmation that a translation is
  correct;
- describe a model pass as independent review when the same provider and model
  performed it;
- choose the softer or harsher model classification when model passes disagree;
- replace the user's decision with an automatic acceptance or correction.

Registry Studio Translator must:

- preserve and display the unchanged source text;
- separate translations from audit observations;
- ground every displayed observation in exact source and/or target excerpts;
- state limitations and unverifiable observations explicitly;
- calculate the visible verdict with deterministic application rules;
- leave the final decision to the user.

## 2. Replaceable implementation

Everything except the honesty invariant is replaceable configuration or
strategy, including:

- supported languages;
- route count and route topology;
- primary and cross-check roles;
- provider, model, prompts, and number of API calls;
- semantic relation and dimension taxonomies;
- verification passes;
- verdict thresholds;
- presentation and card layout.

A failed honesty evaluation may change any of these mechanisms without changing
the invariant.

## 3. Current Stage 5 strategy

The current strategy is not a permanent contract.

It currently uses:

1. two primary translations from the detected or selected source language;
2. four diagnostic cross-check routes for RU, EN, and TH;
3. one route-local first audit pass per route;
4. a route-local second factual pass to the same model;
5. exact application-side validation of every source and target excerpt;
6. a universal factual tuple instead of a model-selected verdict category:
   - relation;
   - semantic dimension;
   - meaning preservation;
7. explicit pass outcomes:
   - `CONFIRMED` when both factual tuples match exactly;
   - `CONFLICT` when the factual tuples differ;
   - `UNVERIFIABLE` when a tuple cannot be supported;
8. deterministic application-side verdicts and explanations;
9. preservation of completed translations when an audit route fails.

The second pass is explicitly not an independent expert review.

## 4. Current factual vocabulary

### Relations

- `ADDITION`
- `OMISSION`
- `SUBSTITUTION`
- `CONTRADICTION`
- `SCOPE_CHANGE`
- `AMBIGUITY_RESOLUTION`
- `WORDING_VARIATION`
- `REGISTER_CHANGE`

### Semantic dimensions

- `PROPOSITION`
- `NEGATION`
- `MODALITY`
- `QUANTITY`
- `TIME`
- `CONDITION`
- `ACTOR`
- `OBJECT`
- `DIRECTION`
- `CAUSE`
- `RESTRICTION`
- `AMBIGUITY`
- `TERMINOLOGY`
- `SPECIFICITY`
- `REGISTER`
- `STYLE`
- `FORMALITY`
- `LEXICAL_CHOICE`
- `OTHER`

### Meaning preservation

- `PRESERVED`
- `ALTERED`
- `UNKNOWN`

The model does not return `UNRELIABLE`, `REVIEW_REQUIRED`, or any other final
verdict.

## 5. Current deterministic verdict policy

- Any limitation, ungrounded evidence, malformed audit response, unknown fact,
  or disagreement between passes produces `INDETERMINATE`.
- A confirmed `ALTERED` observation on a primary route produces `UNRELIABLE`
  when:
  - the relation is `ADDITION`, `OMISSION`, or `CONTRADICTION`; or
  - the semantic dimension is proposition, negation, modality, quantity, time,
    condition, actor, object, direction, cause, restriction, or ambiguity.
- A confirmed altered observation that is not critical under the current policy
  produces `REVIEW_REQUIRED`.
- A confirmed altered observation that exists only on a cross-check route
  produces `REVIEW_REQUIRED`, because cross-check drift is diagnostic evidence,
  not proof that a primary translation is wrong.
- Only confirmed preserved variations produce `ACCEPTABLE_VARIATION`.
- No detected observations produces `NO_CRITICAL_DRIFT_DETECTED`, accompanied
  by an explicit statement that this is not proof of absolute equivalence.

This policy is replaceable when evidence shows that another policy is more
honest.

## 6. Testing strategy

Production rules must not contain phrase-specific exceptions.

Tests cover invariants and generated combinations of:

- primary and cross-check roles;
- all relation codes;
- all semantic dimensions;
- preserved, altered, and unknown meaning;
- confirmed, conflicting, and unverifiable passes;
- all six language route identifiers;
- grounded and ungrounded evidence;
- valid, malformed, incomplete, and provider-failure responses.

Concrete phrases may be used only as end-to-end fixtures. They do not define
production rules.
