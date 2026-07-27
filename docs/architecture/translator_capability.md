# Translator Capability

## Status

This contract describes the accepted Translator behavior at checkpoint
`d27ec93c543918fb75c777fe5151570f0cce92d0` after capability normalization.

## No behavior change

Normalization preserves the accepted A1 user experience:

- RU, EN and TH interface localization;
- compact source-language selection;
- secure API-key restore, replace and delete;
- direct translation, reverse diagnostics and semantic audit;
- existing verdict semantics and provider settings;
- existing widget keys used by regression tests.

## Capability boundaries

### Workspace composition

`translator_workspace_view.dart` creates application state, coordinates the
accepted shell controller and composes leaf presentation capabilities. It does
not implement dialogs, source controls, result cards or persistence algorithms.

### Translation execution

`application/translator_state.dart` defines execution state, while
`application/translator_cubit.dart` owns draft restoration, request execution,
progress, cancellation and current-result transitions. It depends only on application
ports and domain models.

### Access-key management

`application/translator_access_key_cubit.dart` owns typed restore, save and
delete state. Secure storage remains behind `TranslatorAccessKeyStore`.
Presentation maps typed failures to localized strings.

### Source input

`presentation/source/translator_source_panel.dart` renders source text and the
source-language selector. It receives values and callbacks and owns no store or
Bloc dependency.

### Run actions

`presentation/execution/translator_run_actions.dart` renders run, cancel and
clear controls. It receives callbacks and does not start provider operations.

### Status presentation

`presentation/status/translator_status_cards.dart` renders warnings, progress
and failures. It does not mutate translation state.

### Current report

`presentation/report/translator_report_view.dart` renders the accepted direct
translation, reverse diagnostics, verdict evidence and audit findings. It owns
no execution or persistence dependency.

### API-key dialog

`presentation/access_key/translator_access_key_dialog.dart` owns only temporary
field and visibility state for the dialog route. The application capability
owns persistence.

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
presentation below the run controls. Existing report rendering can be reused by
history cards without adding persistence to the workspace or report widgets.

## Canonical actions extension point

Checkpoint C adds canonical-rule checking and write actions as a separate
application capability. It may consume an accepted translation report, but it
must not be implemented inside source input, execution controls or report
rendering.

## Change policy

New Translator functionality extends a named capability. A presentation file
over 400 lines or a workspace over 300 lines is a blocking architecture signal.
Behavior changes and structural normalization remain separate checkpoints.
