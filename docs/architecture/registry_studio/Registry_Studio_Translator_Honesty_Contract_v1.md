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

## 3. Current production strategy

The current production strategy is an implementation profile, not a permanent
architectural invariant.

It currently:

1. obtains the configured translation matrix while preserving every provider
   translation unchanged;
2. gives the completed matrix to one single-pass matrix audit;
3. gives only the original source and the primary translations to a separate
   Primary Linguist review;
4. prevents the matrix audit and the Linguist from receiving each other's
   findings;
5. validates displayed evidence against exact source and/or target excerpts;
6. calculates the matrix verdict deterministically in application code;
7. applies the Linguist only as a conservative constraint after the matrix
   verdict has been calculated;
8. preserves completed translations when the audit or Linguist cannot complete,
   while exposing the resulting limitation.

The matrix audit and the Linguist are separate evidence channels. In the current
implementation they use the same configured provider and model, so they must
not be described as independent expert review by different models.

The route topology, supported language set, provider, model, prompts, request
budget, number of calls, and number of evidence passes remain replaceable
product configuration. This contract does not freeze those implementation
details.

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

The provider does not select the final user-visible verdict. Application code
first evaluates grounded matrix-audit evidence and then applies the Primary
Linguist as a conservative constraint.

For the active matrix-audit path:

- `SINGLE_PASS` means evidence produced by one audit of the completed matrix. It
  is not independent confirmation.
- A grounded `ALTERED` single-pass observation requires review.
- An unusable or `UNVERIFIABLE` observation, malformed evidence, or an audit
  limitation cannot make the result more positive and may produce
  `INDETERMINATE`.
- When no concrete drift is detected, the application may produce
  `NO_CRITICAL_DRIFT_DETECTED`, accompanied by the explicit statement that this
  is not proof of absolute equivalence.

Historical persisted `CONFIRMED` observations remain readable for compatibility
with results created by the former two-pass implementation. They are not
produced by the active runtime. Their existing interpretation remains
compatible with stored results:

- confirmed critical altered evidence on a primary route may produce
  `UNRELIABLE`;
- other confirmed altered evidence produces `REVIEW_REQUIRED`;
- confirmed preserved variation may produce `ACCEPTABLE_VARIATION`.

The Primary Linguist is applied after the matrix verdict and is monotonic: it
may preserve or lower confidence, but it may never promote the matrix result.

- `COMPATIBLE` never upgrades the matrix verdict and is not proof of
  equivalence;
- `INCOMPATIBLE` may lower confidence only when the required exact difference
  evidence is grounded;
- `UNRESOLVED`, report limitations, missing usable coverage, or invalid
  Linguist evidence cannot make a positive result greener and may lower it to
  `INDETERMINATE`.

Linguist assessments, excerpts, and limitations must remain separately visible
to the user. Linguist evidence must not be silently absorbed into the final
verdict.

The final acceptance or rejection decision remains with the user.

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
