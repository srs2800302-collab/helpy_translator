# Translator Capability

## Status

This contract describes the normalized Translator capability after the accepted
A1 interface and the direct-output honesty correction.

## Accepted behavior

- RU, EN and TH interface localization;
- secure API-key restore, replace and delete;
- one source-text field accepting any keyboard language;
- provider-side automatic source-language detection;
- direct RU, EN and TH translations exactly as parsed from provider output;
- semantic audit based only on the direct provider output;
- no freeform reverse-translation calls or reverse-check UI;
- no local wording replacement;
- no hardcoded project glossary before Checkpoint C;
- unchanged Typhoon model and sampling settings.

## Capability boundaries

### Workspace composition

`translator_workspace_view.dart` creates application state, coordinates the
shell controller and composes leaf presentation capabilities. It does not
implement dialogs, source controls, result cards or persistence algorithms.

### Translation execution

`application/translator_state.dart` defines execution state, while
`application/translator_cubit.dart` owns draft restoration, request execution,
progress, cancellation and current-result transitions. Every request uses
provider automatic source-language detection.

### Access-key management

`application/translator_access_key_cubit.dart` owns typed restore, save and
delete state. Secure storage remains behind `TranslatorAccessKeyStore`.

### Source input

`presentation/source/translator_source_panel.dart` renders one multilingual
source text field. It owns no source-language override and no store or Bloc
dependency.

### Provider output

`TranslationBundle` contains only SOURCE LANGUAGE, SOURCE TEXT and direct
RU / EN / TH sections. Provider text is not rewritten or replaced locally.

### Semantic audit

The audit receives the exact direct bundle. It may report supported meaning,
terminology, style and ambiguity findings, but it may not retranslate, rewrite,
invent a canonical dictionary or choose a verdict. The application derives the
verdict from those findings.

Before Checkpoint C, terminology findings produce `NEEDS REVIEW`.
`CANONICAL DRIFT` remains reserved for a connected, revisioned canonical
dictionary.

### Draft compatibility

The v1 draft loader accepts legacy manual-language and reverse-section fields
only for migration. New saves write automatic mode and direct sections only.

## Dependency direction

```text
presentation leaf widgets -> domain/localization
workspace composition -> application + presentation leaves
application -> domain + application ports
infrastructure -> application ports
domain -> no Flutter presentation
```

Application code must never import presentation code. Leaf presentation
capabilities must not import stores, providers or Blocs.

## History extension point

Checkpoint B adds a separate history application/store capability and history
presentation below the run controls. Each immutable history entry stores the
detected source language and exact direct provider output.

## Canonical actions extension point

Checkpoint C connects `Rule Language & Translation Standard` as a separate,
revisioned capability. Prompt selection and canonical enforcement are deferred
until that dictionary is available and testable.

## Change policy

New Translator functionality extends a named capability. A presentation file
over 400 lines or a workspace over 300 lines is a blocking architecture signal.
No local component may silently rewrite provider translations.
