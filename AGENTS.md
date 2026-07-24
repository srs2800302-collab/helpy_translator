# Registry Studio — mandatory execution instructions

## Read before any change

Normative product and architecture contract:

`docs/architecture/registry_studio/Registry_Studio_Engineering_Change_Propagation_and_Approval_Contract_v1.md`

Authoritative Stage 3 execution plan:

`docs/architecture/registry_studio/Registry_Studio_Stage_3_Clean_Rebuild_Execution_Plan.md`

The contract defines what the product must do. The execution plan defines the approved implementation sequence and architecture for the current Stage 3 recovery.

## Fixed recovery decision

- Accepted Stage 2 baseline: `5863b3f78130d5e9231bde996d6620a1c0ab742e`.
- Current Stage 3 implementation at `863e5a0f8a8088c425aedb626c74cdfcad13a631` is archive evidence only.
- Working branch: `registry-studio/stage3-clean-rebuild`.
- Do not reuse or cherry-pick the archived canonical implementation.
- Preserve accepted Stage 1–2 functionality.
- Restore only explicitly accepted non-canonical Registry UX/identity behavior after read-only verification.

## Work order

1. Gate A: restore and physically accept Stage 2.
2. Gate B: create and fully implement the complete Helpy canonical adapter.
3. Implement the complete universal canonical analyzer.
4. Connect adapter and analyzer.
5. Add canonical persistence and Registry UI.
6. Gate C: full Stage 3 APK and physical acceptance.
7. Stage 4 remains blocked until Gate C.

Do not report isolated classes, enums, indexes, resolvers, or unit tests as completed product work.

## Approved Helpy canonical hierarchy

Exactly these Stage 3 Helpy canonical production files are approved:

```text
lib/registry_studio/adapters/helpy/canonical/
├── helpy_canonical_adapter.dart
├── helpy_canonical_dictionary_reader.dart
└── helpy_canonical_registry_projector.dart
```

Responsibilities:

- `HelpyCanonicalAdapter`: one public Helpy canonical entry point; prepares the complete analysis package.
- `HelpyCanonicalDictionaryReader`: reads the complete approved dictionary and converts all applicability to typed constraints.
- `HelpyCanonicalRegistryProjector`: projects the existing `RegistrySnapshot` into all eligible business locations and ordered blocks with exact context/evidence.

The adapter does not classify statuses, own UI, own persistence, reload Registry, write Registry, or publish changes.

## Approved universal canonical hierarchy

```text
lib/registry_studio/canonical/
├── application/
│   ├── project_canonical_adapter.dart
│   └── analyze_canonical_registry.dart
├── domain/
│   ├── canonical_dictionary.dart
│   ├── canonical_analysis_package.dart
│   └── canonical_analysis_report.dart
├── persistence/
│   └── canonical_analysis_store.dart
└── presentation/
    └── canonical_analysis_cubit.dart
```

No additional production file or public type may be introduced without explicit engineer approval.

## Forbidden additions

Do not create:

- candidate/classification/finding index types;
- vocabulary wrappers;
- applicability resolver classes;
- runner/session/coordinator/manager/facade/helper/utility layers;
- generic repositories or result envelopes;
- a second project adapter before final Stage 3 acceptance;
- a second full Registry parser;
- project-specific applicability parsing in universal modules;
- Stage 3 responsibilities inside `RegistryExplorerCubit` or `RegistryExplorerView`;
- statuses without real production producers and engineer-visible results.

## Product acceptance rule

Every Stage 3 status must work end-to-end:

```text
real Registry content
→ adapter package
→ production analyzer
→ report
→ count
→ filter
→ exact Registry navigation
→ persistence/restore
```

Required statuses:

- `Unclassified / Neutral`
- `Exact`
- `Equivalent`
- `Review`
- `Drift`
- `Failed`

Ordered canonical blocks must preserve and analyze significant order.

## Stop rule

If implementation appears to require anything outside the approved hierarchy or public-type allowlist:

1. stop before editing;
2. show the missing responsibility;
3. prove why the approved owner cannot hold it;
4. obtain explicit engineer approval.

Do not expand architecture autonomously.

## Engineering workflow

- Russian explanations; English identifiers and paths.
- Termux/Bash workflow.
- Verify branch, exact HEAD, upstream, status, and contract hash before changes.
- One reviewed production change at a time inside the approved major phase.
- Use here-doc edits.
- Run targeted tests, full suite when required, `flutter analyze`, formatting check, and `git diff --check`.
- Report engineer-visible outcome, files added/deleted, and production LOC delta.
- Do not begin Stage 4.
