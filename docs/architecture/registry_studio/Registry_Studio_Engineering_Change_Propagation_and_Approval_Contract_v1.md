# Registry Studio — Unified Product, Architecture, Engineering Change, Approval and Canonical Contract

Stable Contract ID: `REGISTRY_STUDIO_ENGINEERING_CHANGE_PROPAGATION_AND_APPROVAL_V1`

Unified revision: `2`

Document role: **the single normative architecture and product contract for the new branch**

Status: **APPROVED DRAFT — SINGLE NEW-BRANCH PRODUCT, ARCHITECTURE, UX, ENGINEERING CHANGE, APPROVAL AND CANONICAL SOURCE OF TRUTH**

Repository: `helpy_translator_registry_studio_clean`

Target: a new recovery branch created only after exact repository `HEAD`, branch, worktree status, source files and recovery baseline are re-verified.

This document synchronizes and consolidates the complete requirements of:

- `Registry_Studio_Engineering_Change_Propagation_and_Approval_Contract_v1.md`;
- `Registry_Studio_New_Branch_Product_Architecture_and_Canonical_Contract_v1.md`.

It is the only normative Registry Studio architecture document for the new branch. The earlier documents remain historical evidence only and must not be used as competing sources of truth.

The stable repository destination remains:

`docs/architecture/registry_studio/Registry_Studio_Engineering_Change_Propagation_and_Approval_Contract_v1.md`

Keeping the established path and stable Contract ID prevents stale references while the internal unified revision records the expanded product contract.

Recovery references:

- clean universal Registry Core reference: commit `6fd3260`;
- minimal Flutter/runtime composition reference: commit `a54136a`;
- prototype `4f0a717`: UX and behavior reference only;
- clean-rebuild tip `4bd60bc`: source of individually audited components only, not a continuation baseline.

Imported current Registry source:

- repository: `srs2800302-collab/helpy`;
- ref used for import: `main`;
- path: `docs/architecture/Helpy_Architecture_Registry_v1.md`;
- retrieved: `2026-07-17`;
- downloaded source SHA-256: `dbe4e4fbaa934e3e48c0190088421ff93190cda65083352df7cd67ff641010b7`;
- imported canonical-source block SHA-256: `96466d7b28f447056cdd5be79035c9d0c350c3ede6c3b7a9ae4714558e1f3c67`;
- imported global-rules block SHA-256: `66a03252bc9013646e47215989c042e42651a0a6562079bf77ffbeae6f4fe2fe`.

---

## 0. Contract authority and amendment rule

The terms **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative.

This document controls:

- product purpose;
- visible workspaces and controls;
- automatic analysis behavior;
- Registry growth model;
- canonical classification scope;
- persistence and history;
- Translator handoff;
- impact analysis, review, approval, and publication;
- the embedded engineer-maintained Canonical Dictionary.

A future change to this contract requires:

1. exact current document evidence;
2. an explicit engineer decision;
3. a visible diff;
4. validation of contradictions with existing requirements;
5. commit and revision evidence in the new branch.

The earlier two source documents MUST NOT remain active normative contracts in the new branch. After this unified document is committed at the stable repository path, any copies are historical references only.

The visible title of the dictionary MAY change. Its stable markers and `Dictionary ID` MUST NOT change without a versioned migration.


## 1. Product mission

Registry Studio is an engineering instrument for keeping a project Registry:

- structurally clean;
- semantically consistent;
- canonically aligned;
- traceable by exact source revision;
- safe to change;
- expandable without rebuilding Core.

The product must immediately detect external Registry changes, explain their impact, guide the engineer through every problematic location, support formulation work through Translator, and apply only a complete engineer-approved change set.

Registry Studio is not a workflow-management product. Internal comparisons, revisions, dependency analysis, completeness checks, proposals, validation, and patch preparation must operate automatically inside Registry Studio and appear only as contextual engineering information and actions.

All mandatory engineering-change, dependency, revision, completeness, human-authority, Guidance-order, application-code dependency, and safe-publication requirements from the original approved change-propagation contract are preserved in Section 7, but are reconciled with the approved two-workspace UX and the recursive Registry model.

---

## 2. Two primary engineer workspaces

The application has two primary workspaces:

```text
Registry Studio
Translator
```

They are separate in UI state and persistence but participate in one bidirectional engineering cycle.

### 2.1. Registry Studio workspace

Registry Studio is the primary workspace for:

- loading and indexing the full Registry;
- automatic analysis after every load;
- detecting changes from the previous known revision;
- detecting divergence from the last engineer-confirmed clean baseline;
- browsing and searching the full Registry;
- canonical status filtering;
- displaying problematic and affected locations;
- opening exact Registry blocks in context;
- navigating previous/next problem without returning to the full tree;
- sending a full phrase or selected fragment to Translator;
- accepting a Translator draft back;
- validating the proposed placement;
- rebuilding impact analysis;
- reviewing each affected location;
- showing the final diff;
- approving and applying the complete change set;
- viewing recent analysis and applied-change history.

### 2.2. Translator workspace

Translator is the primary workspace for:

- receiving a phrase or selected Registry fragment with exact context;
- creating a new phrase from scratch;
- manually editing engineer-authored content;
- producing and checking RU / EN / TH;
- reverse semantic checks;
- terminology and semantic drift analysis;
- warnings and audit commentary;
- choosing the final engineer-authored formulation;
- specifying the intended Registry target, operation, anchor, and placement;
- returning a draft to Registry Studio for preflight validation.

Translator does not independently scan dependencies, publish Registry changes, or approve the complete Registry change. It is nevertheless a full engineer authoring tool, not a passive API capability.

---

## 3. Mandatory visible UI contract

### 3.1. Registry Studio screen

The Registry Studio screen contains:

1. Registry title and source revision.
2. Compact problem/status summary.
3. Canonical status counters and filters.
4. Search.
5. Full expandable Registry hierarchy.
6. Contextual block view.
7. Problem navigation.
8. Translator handoff.
9. Contextual impact, proposal, validation, and final-diff panels.
10. Recent working-change history.

No separate top-level screens or menu entries are permitted for:

- Engineering Operation;
- Engineering Task;
- Comparison;
- Status Transition;
- Readiness Gate;
- Related Context;
- Dependency Graph;
- Guard Record;
- Revision Editor.

These remain internal product facts.

### 3.2. Compact problem list

A compact expandable problem list is placed near the top of Registry Studio, in the area previously used for the Registry selector/revision summary.

It shows:

- problem count;
- changed-location count;
- current revision;
- clean baseline revision;
- short entries with problem type and `RegistryPath`;
- status icon, color, and text explanation.

A button opens the same queue full-screen for dense review. The full-screen view is still part of Registry Studio, not a separate engineering product.

Selecting an item opens the exact Registry block directly. The engineer can then move to the previous or next problem without returning to the complete Registry tree.

### 3.3. Visual states

Visual highlighting may use:

- red — confirmed conflict or invalid state;
- orange/yellow — review required or semantic candidate;
- blue — confirmed affected or related location;
- green — prepared and validated change;
- gray — analyzed and proven unaffected or neutral.

Color is never the only signal. Every state must also include a text label, icon, and reason.

### 3.4. Canonical status controls

Both primary workspaces show canonical status controls, but they operate on different datasets.

Translator status counters describe the current Translator working session.

Registry Studio status counters describe all eligible business phrases in the currently loaded Registry revision:

```text
All
Unclassified / Neutral
Exact
Equivalent
Review
Drift
Failed
```

Pressing a status acts as a filter. For example, `Drift` immediately shows all business phrases classified as drift, their `RegistryPath`, and direct navigation to each exact block.

### 3.5. Exact existing button meanings

- Globe icon: choose application interface language `RU / EN / TH`.
- Circular refresh arrow on Registry screen: manually reload Registry and rerun automatic analysis.
- Cross icon on Translator screen: clear only the current Translator workspace.

The circular refresh action does not clear Registry Studio work.

The Translator cross does not clear Registry Studio state.

Registry Studio current-work reset is a separate confirmed action and must not reuse the refresh icon.

---

## 4. Automatic Registry analysis

### 4.1. Mandatory trigger

Every successful Registry load, including application startup and manual refresh, automatically starts analysis. The engineer must not launch a separate comparison operation.

### 4.2. Two comparison baselines

Registry Studio maintains:

1. **Previous known revision** — used to show what changed since the last load.
2. **Last engineer-confirmed clean baseline** — used to show what remains inconsistent with the accepted clean state.

A newly loaded revision never becomes the clean baseline automatically.

### 4.3. Automatic analysis pipeline

```text
load exact source revision
→ build full structural index
→ compare with previous known revision
→ compare with last clean baseline
→ detect additions
→ detect removals
→ detect replacements
→ detect moves
→ detect significant reordering
→ resolve stable identities and paths
→ classify eligible business phrases against Canonical Dictionary
→ detect canonical drift, missing canonical coverage, conflicts, and duplicates
→ rebuild direct and transitive impact
→ classify confirmed dependencies and semantic candidates
→ create or update the problem queue
→ persist analysis and current engineer workspace
```

### 4.4. External administrator changes

An administrator or another approved source may modify Registry business configuration at any time.

Registry Studio must detect at the next load:

- changed entity or scenario;
- added or removed category;
- added or removed nested business block;
- changed wording;
- changed applicability;
- changed requiredness;
- changed photo reuse or limits;
- changed Guidance order;
- changed client, master, or global rule;
- canonical drift;
- broken or newly introduced dependencies.

The engineer must see the exact changed location and reason immediately.

---

## 5. Dynamic recursive Registry model

Registry is treated as a recursive tree of arbitrary depth and an extensible set of node kinds.

The architecture MUST NOT define a mandatory chain of levels. Categories, entities, directions, scenarios, questions, photo requirements, guidance, rules, processes, and other current structures are examples only.

Universal structural form:

```text
Registry
└── RegistryNode
    ├── stable identity
    ├── kind or semantic descriptor
    ├── RegistryPath
    ├── Source Evidence
    ├── content
    ├── business-scope ownership
    └── children: RegistryNode[]
```

Any node MAY contain child nodes of existing or future types. A future project adapter or Registry schema MAY add semantic interpretation without changing universal Core.

No architecture, algorithm, UI, manifest, test, counter, persistence schema, or acceptance rule may depend on the current number of:

- root nodes;
- categories;
- nested levels;
- node kinds;
- entities;
- scenarios;
- phrases;
- rules;
- canonical entries.

Structural indexing MUST discover the full Registry recursively.

Project-specific semantic overlays MAY add:

- stable typed identity;
- relations;
- applicability;
- ordered-block semantics;
- validation;
- business-scope classification.

An overlay is evidence over the full structural index. It is never the boundary of Registry visibility or analysis.

New nodes and new node kinds MUST automatically:

- appear in Registry Explorer;
- become searchable;
- participate in revision comparison;
- participate in problem detection;
- participate in canonical analysis when classified inside eligible business scope;
- participate in dependency analysis;
- appear in analysis and change history;
- require no universal Core redesign.

A static manifest is permitted only as a versioned evidence overlay for explicitly stable identities or relations.

---

## 6. Canonical business analysis and dictionary ownership

### 6.1. Canonical source

The Canonical Dictionary embedded in this contract is the engineer-maintained source of approved canonical business phrases and ordered canonical blocks for the new branch.

The current Registry heading `Canonical Photo Labels` is preserved as an imported collection name. It is not the permanent identity of the dictionary.

Registry Studio MUST locate the dictionary through:

- stable `Dictionary ID`;
- explicit begin/end markers;
- version;
- collection identifiers.

Registry Studio MUST NOT depend on a visible Markdown heading because the visible title may be renamed.

### 6.2. Eligible business scope

Canonical classification applies only to Registry nodes that are structurally classified as user-facing business logic or as business rules directly controlling user-visible behavior.

This includes the complete recursive business subtree owned by:

- service or product catalog structures;
- client rules and client-visible guidance;
- master rules and master-visible guidance;
- global business rules;
- other current or future business owners defined by the project adapter or Registry schema.

These are ownership classes, not a closed enumeration of node kinds.

A new category, nested level, scenario type, process type, rule type, or other business node MUST enter canonical analysis automatically when it belongs to eligible business scope.

### 6.3. Excluded technical scope

Canonical phrase statuses MUST NOT be assigned to technical Registry content merely because it contains text.

Excluded by default:

- architecture implementation notes;
- database schema and migrations;
- API internals;
- CI configuration;
- code-level contracts;
- internal engineering procedures;
- build and deployment instructions.

A technically located text is included only when structural evidence proves that it is user-facing business logic.

### 6.4. Canonical classifications

Registry Studio distinguishes:

- `Exact` — exact canonical text after allowed technical normalization only;
- `Equivalent` — separately approved equivalent with evidence;
- `Review` — probable relation without sufficient proof;
- `Drift` — a proven canonical application whose wording differs;
- `Failed` — dictionary, translation, parsing, or validation failure preventing a reliable classification;
- `Unclassified / Neutral` — eligible business phrase with no proven canonical relation.

Whitespace normalization MUST NOT change punctuation, negation, quantities, mandatory force, terminology, applicability, order, or business meaning.

Text similarity alone MUST NOT produce `Exact` or `Equivalent`.

### 6.5. Engineer-maintained dictionary rules

An engineer adds or changes a canonical entry only inside the marked dictionary area at the end of this document.

Every added or changed entry MUST have:

- an approved collection;
- an explicit status;
- canonical source-language text or an ordered canonical block;
- applicability or scope when the phrase is not universally applicable;
- RU / EN / TH review evidence before the entry is considered multilingual-complete;
- duplicate, semantic duplicate, conflict, ambiguity, and terminology checks;
- an engineer decision and history entry.

Registry Studio reads only approved entries inside the dictionary markers.

Governance prose, examples, evidence notes, and headings outside approved collections MUST NOT be classified as canonical phrases.

### 6.6. Canonical identity

For a phrase entry, stable technical identity is derived from:

```text
Dictionary ID
+ collection ID
+ normalized approved source-language text hash
```

For an ordered block, identity also includes the stable block key and approved item order.

Changing canonical text creates a new versioned canonical identity. The previous identity remains in history and MUST NOT be silently overwritten.

---

## 7. Engineering change propagation and approval

This section preserves and synchronizes the mandatory engineering-change requirements of the original approved contract. These mechanics are internal Registry Studio capabilities. They MUST NOT reappear as separate top-level technical screens or as a user-managed generic operation lifecycle.

### 7.1. Sources of change

Registry Studio accepts three equivalent engineering inputs:

1. A change detected automatically after loading a new Registry revision.
2. An Admin Panel-compatible business change request.
3. A direct engineer-authored change or canonicalization task.

Admin Panel is an external source of business intent. It does not own dependency discovery, semantic decisions, canonical approval, whole-change-set approval, publication, or application-code changes.

A direct engineering task follows the same requirements as an externally detected change.

### 7.2. Mandatory source facts

Every internal `EngineeringChangeSet` MUST preserve or reconstruct:

- exact project and project adapter;
- exact base source revision;
- previous known revision;
- last engineer-confirmed clean baseline revision;
- source identity and target identity when applicable;
- `RegistryPath`;
- `SourceEvidence`;
- source span or structural evidence;
- original value;
- proposed value;
- change origin;
- change intent;
- owning Registry branch;
- structural context;
- affected language data;
- audit lineage.

A display label, current line number, heading text, or current phrase text MUST NOT replace stable identity.

### 7.3. Supported change intents

Registry Studio may internally represent concrete change intents including:

- add;
- remove;
- replace;
- move;
- reorder;
- insert before;
- insert after;
- insert at start;
- insert at end;
- insert at an exact structural position;
- copy an explicitly selected semantic block;
- replace an explicitly selected semantic block;
- copy an explicitly selected subtree;
- revise a formulation;
- prepare a Canonical Dictionary candidate;
- update an approved canonical entry through a versioned change.

These are domain facts used by Registry Studio. They are not separate navigation screens.

A change intent MUST reference exact stable source, target, container, item, and anchor identities whenever those facts exist.

### 7.4. Full dependency graph

Registry Studio MUST build direct and transitive impact from the complete structural Registry index.

The graph MUST NOT be bounded by:

- one root section;
- one project-specific manifest;
- one semantic overlay;
- the current catalog size;
- the current number of node kinds;
- the current nesting depth;
- only identical text.

Evidence may include:

1. stable typed references;
2. explicit `RegistryRelation`;
3. adapter-defined reuse contracts;
4. stable semantic identity;
5. owner-block and applicability evidence;
6. Scenario or process entry evidence;
7. question, answer-option, qualifier, photo, limit, rule, and guidance references;
8. Canonical Dictionary applications;
9. application-code, backend, API, Admin Panel, or runtime-consumer evidence;
10. exact normalized canonical reuse with full context.

Textual or structural similarity without proof remains a semantic candidate.

Graph traversal continues until all reachable confirmed dependencies and unresolved candidates are represented. Cycles MUST be handled deterministically.

### 7.5. Classification of findings

Every discovered location is classified as one of:

#### Confirmed dependency

The relation is proven by stable identity, typed reference, explicit relation, reuse contract, canonical-application evidence, or other project-adapter evidence.

#### Semantic candidate

A relation is plausible but not proven. It requires an explicit engineer decision.

#### Unaffected with evidence

A location may be excluded only when Registry Studio can explain why the change cannot affect it.

Unknown is not equivalent to unaffected.

### 7.6. Context of each affected location

Each affected location is reviewed in its full recursive branch context.

Registry Studio MUST show:

- exact `RegistryPath`;
- source and target identities when relevant;
- owner nodes;
- ancestor context;
- ordered siblings when order is meaningful;
- original content;
- proposed content;
- text diff;
- structural diff;
- additions;
- removals;
- replacements;
- moves;
- reordered items;
- applicability;
- relations and evidence;
- direct and transitive dependency paths;
- canonical evidence;
- RU / EN / TH state;
- warnings;
- unresolved questions;
- proposal reason.

Project-specific structures such as categories, entities, scenarios, questions, photo requirements, rules, guidance, and future node types are examples only. The universal contract does not prescribe a fixed branch chain.

### 7.7. Exact proposals and engineer decisions

Registry Studio may prepare an exact proposal only when the result follows deterministically from proven evidence and full context.

An explicit engineer decision is mandatory when:

- the relation is a semantic candidate;
- the same phrase has different meaning or applicability;
- business meaning changes;
- applicability changes;
- requiredness changes;
- ordered behavior changes;
- photo reuse or limit semantics change;
- RU / EN / TH diverge;
- a new canonical formulation is needed;
- sources conflict;
- dependency coverage is incomplete;
- canonical drift or ambiguity remains;
- deterministic placement cannot be proven.

Each affected location has its own proposal and its own engineer decision.

A single global `proposalReviewed` or equivalent boolean MUST NOT replace per-location decisions.

The engineer can:

- accept;
- reject;
- edit;
- replace with an engineer-authored solution;
- send the phrase or selected fragment to Translator;
- resolve a semantic candidate;
- mark a location unaffected only with recorded reasoning.

### 7.8. Revisions and lineage

Every content-changing step creates or updates a revision of the current `EngineeringChangeSet`.

A revision preserves:

- affected stable identity;
- original value;
- proposed value;
- complete working content;
- change intent;
- source of proposal;
- dependency context;
- per-location engineer decisions;
- previous revision lineage;
- related identities;
- RU / EN / TH results;
- Translator evidence;
- validation and audit references.

Changing content, placement, target, applicability, or source revision invalidates stale comparison, impact analysis, completeness, validation, final diff, and approval as required.

### 7.9. Completeness gate

Registry Studio MUST block approval and apply while any relevant fact remains unresolved, including:

- not analyzed;
- dependency unresolved;
- semantic candidate unresolved;
- engineer decision required;
- translation incomplete;
- canonical drift unresolved;
- conflict unresolved;
- proposal not reviewed;
- dependent branch inconsistent;
- `SourceEvidence` missing;
- placement unresolved;
- duplicate unresolved;
- stale source revision;
- validation failed.

Before readiness, Registry Studio MUST prove:

1. Available direct and transitive dependencies have been discovered.
2. Every finding is classified.
3. Every ambiguous location has an engineer decision.
4. All affected RU / EN / TH data required by the project is checked.
5. All revisions belong to one coherent change set.
6. No internal conflict remains.
7. Significant order is valid.
8. Canonical conflicts and duplicates are resolved.
9. Application-code and other runtime-consumer dependencies have a decision.
10. The engineer can see the complete final diff.
11. Final validation passes against the still-current source revision.

The gate is derived automatically from facts. The engineer does not manually select technical lifecycle statuses.

### 7.10. Significant order

Order is domain semantics whenever the owning block declares ordered behavior.

Registry Studio MUST NOT:

- treat an ordered block as a set;
- silently sort it;
- reorder by text similarity;
- merge items without role, stage, applicability, and workflow analysis;
- copy an item without preserving or explicitly changing its position.

For an ordered change, Registry Studio shows the original sequence, proposed sequence, additions, removals, moves, reason, and workflow impact.

Placement requires an exact position or stable anchor when order matters.

### 7.11. Application-code and external-consumer dependencies

A Registry change does not automatically modify Flutter, backend, API, Admin Panel, database, or another runtime consumer.

When confirmed evidence shows such a dependency, Registry Studio MUST:

1. Show the dependency to the engineer.
2. Add it to the same impact graph and change set.
3. Require an engineer decision.
4. Prevent completeness while it remains unresolved.
5. Never modify or publish application code without explicit approval and an implementation capability designed for that target.

### 7.12. Human authority

Registry Studio MUST NOT independently:

- approve business meaning;
- resolve a semantic ambiguity;
- declare a candidate canonical;
- accept a proposal;
- hide an unresolved dependency;
- alter Registry;
- publish Registry;
- merge a pull request;
- change application code.

Translator and Admin Panel also do not have this authority.

Only an authorized engineer approves the complete change set.

### 7.13. Safe apply

After whole-change-set approval, Registry Studio may apply only the exact previously displayed and validated set.

If the source revision has changed:

- apply stops;
- source context is reloaded;
- comparison and dependency analysis are repeated;
- stale approval is invalidated;
- a new engineer approval is required.

Partial apply is forbidden when it would leave Registry inconsistent.

After apply, Registry Studio preserves:

- final approved diff;
- all affected identities and paths;
- base revision;
- resulting revision;
- engineer decision references;
- canonical and Translator evidence;
- validation result;
- publication result;
- failure or rollback evidence.

### 7.14. First complete usable vertical

The first complete product vertical is:

```text
new Registry revision, Admin Panel-compatible input, or direct engineer task
→ exact change reconstruction
→ complete structural and canonical analysis
→ full direct and transitive dependency graph
→ confirmed dependencies and semantic candidates
→ contextual proposals for every affected location
→ engineer editing and decisions
→ Translator round-trip when needed
→ repeated comparison and dependency analysis
→ automatic completeness gate
→ final full diff
→ explicit whole-change-set approval
→ deterministic guarded apply
→ resulting revision or failure/rollback evidence
```

Search, source blocks, free editing, isolated revisions, comparison alone, or a technical operation screen do not constitute completion of the primary product workflow.

---

## 8. Bidirectional Registry Studio ↔ Translator cycle

### 7.1. Registry Studio to Translator

The engineer may send:

- a complete phrase;
- a selected fragment;
- a complete semantic block;
- multiple explicitly selected related lines.

The handoff includes:

- `RegistryEntityId` when available;
- `RegistryPath`;
- exact source revision;
- source span and evidence;
- owning category/entity/scenario/block;
- original content;
- detected problem;
- related-location context;
- current canonical evidence.

### 7.2. Translator authoring

The engineer may:

- revise the received formulation;
- create a new formulation;
- edit RU / EN / TH manually;
- inspect reverse checks;
- inspect warnings;
- choose the final wording;
- choose intended placement.

### 7.3. Registry placement request

The returned draft contains a concrete `RegistryPlacementRequest`:

- content to place;
- target Registry;
- exact base revision;
- target identity or container;
- target `RegistryPath`;
- operation type;
- anchor identity or exact structural anchor;
- placement position;
- intended application scope;
- engineer rationale;
- Translator evidence and warnings.

Supported placement intent includes:

- replace selected formulation;
- insert before;
- insert after;
- insert at start;
- insert at end;
- insert at exact position;
- add new element;
- replace semantic block;
- copy semantic block;
- prepare a Canonical Dictionary candidate.

Order-sensitive Guidance always requires explicit placement or anchor.

### 7.4. Registry Studio preflight

A returned Translator draft does not immediately change Registry.

Registry Studio first checks:

- base revision freshness;
- exact target existence;
- exact anchor existence;
- structural compatibility;
- semantic-block compatibility;
- significant ordering;
- duplicate creation;
- Canonical Dictionary conflicts;
- direct and transitive dependencies;
- semantic candidates;
- affected RU / EN / TH data;
- final structural and textual diff.

The draft becomes one or more concrete location proposals only after preflight.

### 7.5. Engineer review and apply

The engineer can accept, reject, or edit each affected-location proposal.

Registry Studio may apply only when:

- every affected location is analyzed;
- every semantic candidate is resolved;
- all required language checks are complete;
- canonical conflicts are resolved;
- validation passes;
- the final diff is shown;
- the whole change set is explicitly approved;
- the source revision is still current.

---

## 9. Internal architecture model

### 8.1. Architecture style

Registry Studio is a modular monolith organized by product capability.

It is not organized around:

- Translator ownership;
- generic workflow engine;
- generic operation lifecycle;
- technical screens;
- a central orchestrator;
- universal repositories or result envelopes;
- helper, wrapper, facade, utility, or manager layers replacing domain ownership.

### 8.2. Clean universal Core

Initial Core is taken from the clean `6fd3260` boundary without redesign:

- `RegistryEntity`;
- `RegistryEntityId`;
- `RegistryEntityKind`;
- `RegistryPath`;
- `SourceEvidence`;
- `RegistryRelation`;
- `RegistryRelationMeaning`;
- `RegistrySemanticContractIdentity`;
- related-context contracts.

Core:

- imports no Flutter;
- imports no presentation;
- imports no infrastructure;
- imports no Translator;
- imports no Helpy-specific semantics;
- knows no GitHub, HTTP, SharedPreferences, Admin Panel, or concrete Registry format.

### 8.3. Concrete internal change aggregate

A concrete internal `EngineeringChangeSet` may own:

- exact base revision;
- detected or engineer-authored change;
- source/target or placement request;
- comparison result;
- impact graph;
- per-location proposals;
- engineer decisions;
- Translator candidates;
- revisions;
- completeness facts;
- validation;
- final diff;
- approval;
- publication evidence.

It is not a top-level screen, menu entry, or user-selected lifecycle.

### 8.4. Derived state

Readiness and progress are derived from factual state. The user does not manually choose technical statuses.

Any content change invalidates stale analysis, validation, final diff, and approval as required.

---

## 10. Target physical hierarchy

Directories define ownership boundaries. Files are created only when a real working vertical needs them.

```text
lib/
├── main.dart
├── app/
│   ├── bootstrap/
│   │   └── registry_studio_composition.dart
│   ├── shell/
│   │   ├── registry_studio_app.dart
│   │   └── primary_workspace_navigation.dart
│   └── startup/
│       └── startup_failure_screen.dart
│
├── registry_studio/
│   ├── core/
│   │   ├── domain/
│   │   │   ├── contracts/
│   │   │   ├── entities/
│   │   │   ├── evidence/
│   │   │   └── value_objects/
│   │   └── application/
│   │       └── related_context/
│   │
│   ├── registry/
│   │   ├── domain/
│   │   │   ├── registry_snapshot.dart
│   │   │   ├── registry_document.dart
│   │   │   ├── registry_document_node.dart
│   │   │   ├── registry_clean_baseline.dart
│   │   │   ├── registry_analysis.dart
│   │   │   └── registry_problem.dart
│   │   ├── application/
│   │   │   ├── load_registry_snapshot.dart
│   │   │   ├── reload_registry.dart
│   │   │   ├── index_registry_document.dart
│   │   │   ├── analyze_loaded_registry.dart
│   │   │   ├── search_registry.dart
│   │   │   ├── filter_registry_problems.dart
│   │   │   └── confirm_clean_baseline.dart
│   │   ├── infrastructure/
│   │   │   ├── registry_snapshot_source.dart
│   │   │   └── markdown_registry_document_parser.dart
│   │   ├── persistence/
│   │   │   └── registry_workspace_persistence.dart
│   │   └── presentation/
│   │       ├── registry_screen.dart
│   │       ├── registry_state.dart
│   │       ├── registry_problem_queue.dart
│   │       ├── registry_problem_queue_fullscreen.dart
│   │       ├── registry_block_context.dart
│   │       ├── canonical_status_filter.dart
│   │       ├── registry_history_panel.dart
│   │       └── contextual_review/
│   │           ├── change_summary_panel.dart
│   │           ├── impact_panel.dart
│   │           ├── proposal_panel.dart
│   │           ├── validation_panel.dart
│   │           └── final_diff_panel.dart
│   │
│   ├── canonical/
│   │   ├── domain/
│   │   │   ├── canonical_dictionary.dart
│   │   │   ├── canonical_dictionary_entry.dart
│   │   │   ├── canonical_phrase_finding.dart
│   │   │   └── canonical_phrase_status.dart
│   │   ├── application/
│   │   │   ├── load_canonical_dictionary.dart
│   │   │   ├── identify_business_phrase_scope.dart
│   │   │   └── classify_registry_business_phrases.dart
│   │   └── persistence/
│   │       └── canonical_analysis_persistence.dart
│   │
│   ├── translator/
│   │   ├── domain/
│   │   │   ├── translator_formulation_draft.dart
│   │   │   ├── translator_phrase_result.dart
│   │   │   ├── translator_phrase_status.dart
│   │   │   └── registry_placement_request.dart
│   │   ├── application/
│   │   │   ├── prepare_registry_handoff.dart
│   │   │   ├── translate_registry_phrase.dart
│   │   │   ├── prepare_registry_placement_request.dart
│   │   │   └── return_draft_to_registry.dart
│   │   ├── infrastructure/
│   │   │   └── typhoon_translator_phrase_provider.dart
│   │   ├── persistence/
│   │   │   └── translator_workspace_persistence.dart
│   │   └── presentation/
│   │       ├── translator_screen.dart
│   │       ├── translator_state.dart
│   │       └── registry_handoff_panel.dart
│   │
│   ├── impact_analysis/
│   │   ├── domain/
│   │   │   ├── registry_dependency_graph.dart
│   │   │   ├── dependency_finding.dart
│   │   │   ├── dependency_evidence.dart
│   │   │   └── dependency_classification.dart
│   │   └── application/
│   │       ├── build_registry_dependency_graph.dart
│   │       ├── classify_dependency_findings.dart
│   │       └── explain_unaffected_location.dart
│   │
│   ├── change_review/
│   │   ├── domain/
│   │   │   ├── engineering_change_set.dart
│   │   │   ├── engineering_change_set_revision.dart
│   │   │   ├── registry_change_proposal.dart
│   │   │   ├── engineer_decision.dart
│   │   │   ├── completeness_issue.dart
│   │   │   ├── change_set_validation.dart
│   │   │   └── change_set_approval.dart
│   │   ├── application/
│   │   │   ├── preflight_registry_placement.dart
│   │   │   ├── prepare_change_proposals.dart
│   │   │   ├── record_engineer_decision.dart
│   │   │   ├── revise_change_set.dart
│   │   │   ├── evaluate_completeness.dart
│   │   │   ├── validate_change_set.dart
│   │   │   └── approve_change_set.dart
│   │   └── persistence/
│   │       └── change_set_persistence.dart
│   │
│   ├── history/
│   │   ├── domain/
│   │   │   ├── registry_analysis_history_entry.dart
│   │   │   └── applied_change_history_entry.dart
│   │   ├── application/
│   │   │   ├── record_registry_analysis.dart
│   │   │   ├── record_applied_change.dart
│   │   │   └── load_recent_work_history.dart
│   │   └── persistence/
│   │       └── registry_history_persistence.dart
│   │
│   ├── publication/
│   │   ├── domain/
│   │   │   ├── registry_patch.dart
│   │   │   ├── publication_evidence.dart
│   │   │   └── rollback_evidence.dart
│   │   ├── application/
│   │   │   ├── build_registry_patch.dart
│   │   │   ├── verify_base_revision.dart
│   │   │   └── apply_approved_change_set.dart
│   │   └── infrastructure/
│   │       └── github_registry_change_publisher.dart
│   │
│   └── adapters/
│       └── helpy/
│           ├── registry_source/
│           ├── business_scope/
│           ├── service_intake/
│           ├── client_rules/
│           ├── master_rules/
│           ├── global_rules/
│           ├── canonical_dictionary/
│           ├── admin_panel/
│           └── application_code/
│
└── technical/
    ├── config/
    ├── network/
    └── local_storage/
```

Presentation does not import concrete infrastructure. App bootstrap wires concrete implementations.

No empty speculative directory tree is created in advance.

---

## 11. Persistence and restoration

### 10.1. Independent workspace persistence

Registry Studio and Translator have separate persisted workspaces.

On application backgrounding, process death, closing, and restart, each workspace restores its last state until its own explicit reset action.

### 10.2. Registry Studio persisted state

Registry Studio preserves:

- loaded revision;
- previous known revision;
- clean baseline revision;
- latest analysis;
- problem queue;
- selected status filter;
- search and filters;
- open `RegistryPath`;
- selected block;
- problem navigation position;
- current internal change set;
- proposals and engineer decisions;
- returned Translator draft;
- unapproved final diff.

### 10.3. Translator persisted state

Translator preserves:

- source content;
- Registry context when provided;
- RU / EN / TH working values;
- reverse checks;
- warnings;
- current result;
- intended target and placement request;
- unreturned draft.

### 10.4. Independent clearing

Translator cross clears only current Translator state and unreturned Translator handoff draft.

Registry Studio reset clears only current unfinished Registry Studio work:

- selection;
- temporary filters when specified by the reset contract;
- current draft change set;
- unapproved proposals and decisions;
- unapproved final diff.

Registry Studio reset does not delete:

- latest Registry snapshot;
- clean baseline;
- analysis history;
- applied-change history;
- publication evidence;
- Translator workspace.

Any destructive reset requires explicit confirmation describing exactly what is deleted and preserved.

### 10.5. Manual reload behavior

Registry circular refresh:

- loads the latest exact revision;
- reruns analysis;
- attempts to restore open context by stable identity and path;
- reports moved, changed, or deleted targets explicitly;
- does not clear current work.

---

## 12. History

History is mandatory.

Registry Studio stores:

- load timestamp;
- source revision;
- previous revision;
- clean baseline revision;
- detected changes;
- detected problems;
- engineer decisions;
- Translator handoffs and returned drafts;
- accepted and rejected proposals;
- final diff;
- applied patch;
- resulting revision;
- validation;
- publication success, failure, or rollback evidence.

History is presented as recent engineering work inside Registry Studio, not as a generic operation lifecycle screen.

---

## 13. Dependency and impact rules

Impact analysis covers the full structural Registry plus project-adapter evidence.

Evidence precedence:

1. stable typed reference;
2. explicit `RegistryRelation`;
3. adapter-defined reuse contract;
4. stable identity and owning business block;
5. exact normalized canonical reuse with context evidence;
6. structural or textual similarity as semantic candidate only.

Required outputs:

- direct dependencies;
- transitive dependencies;
- dependency paths;
- confirmed relations and evidence;
- semantic candidates and reasons;
- unresolved coverage;
- affected branches;
- unaffected locations only when exclusion evidence exists;
- cycle handling;
- deterministic ordering.

Text similarity alone never becomes confirmed dependency.

---

## 14. Safe publication

Registry Studio generates a deterministic patch only from the final approved change set.

Before apply:

- base revision must match;
- final diff must match approved content;
- validation must still pass;
- every affected location must have an engineer decision;
- no unresolved candidate or conflict may remain.

Partial application is forbidden when it would leave Registry inconsistent.

After apply, save:

- approved diff;
- source revision;
- resulting revision;
- all affected identities and paths;
- validation result;
- publication evidence;
- failure or rollback evidence.

---

## 15. Language contract

Application interface supports:

- RU;
- EN;
- TH.

The globe icon opens a compact selector. The selected interface language persists across restarts.

The Registry content language and the UI language are separate concerns.

All engineer-facing explanations must remain clear in the selected interface language. Code identifiers, paths, APIs, schemas, and configuration remain English.

---

## 16. Implementation sequence

### Stage 0 — Recovery foundation

- create recovery branch from the verified technical baseline;
- preserve the clean Core from `6fd3260`;
- remove premature generic operation and workspace ownership;
- establish minimal composition;
- prove clean tests, analyze, build, and APK.

### Stage 1 — Full Registry visibility and persistence

- exact source snapshot;
- full structural index;
- expandable/searchable Registry;
- circular manual refresh;
- automatic session persistence and restore;
- previous-revision tracking;
- history of loads.

### Stage 2 — Automatic change analysis

- previous revision comparison;
- clean baseline comparison;
- problem queue;
- exact problem navigation;
- full-screen problem queue;
- change history.

### Stage 3 — Canonical business analysis

- load Canonical Dictionary;
- structurally discover eligible business scope;
- classify all eligible business phrases;
- status counters and filters in Registry;
- exact navigation by canonical status;
- no fixed catalog counts, level sequence, or closed node-kind list.

### Stage 4 — Bidirectional Translator handoff

- send phrase/selection with exact context;
- edit or create formulation;
- RU / EN / TH and reverse checks;
- placement request;
- return to Registry Studio;
- independent persistence and clearing.

### Stage 5 — Impact, proposals, and engineer review

- preflight;
- direct/transitive dependency graph;
- confirmed versus candidate classification;
- per-location proposals;
- contextual review panels;
- completeness and validation;
- final diff.

### Stage 6 — Safe apply

- whole-set approval;
- deterministic patch;
- stale-revision rejection;
- guarded publication;
- resulting revision and rollback evidence.

Each stage ends with a usable APK and explicit engineer acceptance before the next stage begins.

---

## 17. Non-negotiable prohibitions

The rebuild must not:

- recreate Translator-centric ownership;
- create a generic workflow engine;
- expose internal operation lifecycle as product navigation;
- create a God App, God Workspace, or global God Cubit;
- use fixed catalog counts;
- use a static manifest as Registry scope;
- use line numbers as permanent identity;
- classify technical Registry sections as canonical business phrases;
- treat text similarity as confirmed dependency;
- apply a partial inconsistent change set;
- apply against a stale revision;
- let Translator or Admin Panel approve or publish Registry changes;
- lose unfinished work on backgrounding or restart;
- make one workspace reset clear the other;
- make refresh behave as reset;
- create speculative helpers, wrappers, managers, facades, utilities, or generic repositories.

---

## 18. Product acceptance capabilities

The implementation is conformant only when all capability groups below are factually demonstrated.

### Registry state and automatic analysis

- Open Registry Studio and show the exact current source revision.
- Automatically analyze every successful load and manual refresh.
- Show changes from the previous known revision.
- Show divergence from the last engineer-confirmed clean baseline.
- Preserve the clean baseline until explicit engineer confirmation changes it.

### Problem navigation

- Show a compact problem queue in Registry Studio.
- Open the same queue full-screen without creating a separate technical product screen.
- Open each exact problematic Registry block directly.
- Move to previous and next problem without returning to the complete tree.
- Show exact `RegistryPath`, evidence, reason, revision, and status.

### Dynamic Registry coverage

- Recursively browse and search an arbitrarily expanding Registry tree.
- Discover new node types and nesting through structural indexing and project schema.
- Avoid fixed category, entity, scenario, phrase, or depth assumptions.
- Keep structurally visible branches visible even when no semantic manifest entry exists.

### Canonical analysis

- Read the embedded dictionary by stable markers and `Dictionary ID`, not by visible heading.
- Restrict status counters to eligible business scope.
- Filter Registry phrases by `Exact`, `Equivalent`, `Review`, `Drift`, `Failed`, and neutral state.
- Open each status result in exact Registry context.
- Preserve distinction between canonical ownership, translation quality, and dependency evidence.
- Allow an authorized engineer to add a new canonical phrase through a reviewed dictionary change.

### Registry Studio and Translator cycle

- Send a full phrase, selected fragment, or selected block to Translator with exact Registry context.
- Edit an existing phrase or create a new formulation.
- Produce and inspect RU / EN / TH and reverse checks.
- Specify target, operation, anchor, position, applicability, and rationale.
- Return the draft to Registry Studio without publishing directly.

### Internal analysis and engineer decision

- Automatically execute preflight, structural comparison, text diff, impact analysis, duplicate checks, canonical checks, completeness, and validation.
- Separate confirmed dependencies from semantic candidates.
- Show every affected-location proposal in context.
- Require an explicit engineer decision for every unresolved place.
- Invalidate stale analysis and approval after relevant content or source-revision changes.

### Safe apply and evidence

- Show the final complete diff.
- Require whole-change-set approval.
- Reject apply when the source revision is stale.
- Apply only the exact approved set.
- Return resulting revision or explicit failure/rollback evidence.
- Preserve immutable publication evidence and history.

### Persistence and independent clearing

- Restore unfinished Registry Studio and Translator work after backgrounding, process death, closing, and restart.
- Keep Registry Studio and Translator workspace states independent.
- Make the Translator cross clear only Translator work.
- Make Registry circular refresh reload and reanalyze without clearing current work.
- Make Registry Studio reset a separate confirmed action.
- Preserve Registry history, clean baseline, and applied-change evidence after current-work reset.

---

## 19. Contract synchronization record

This unified revision was prepared from the two source documents below:

- original engineering-change contract SHA-256: `3ffa5e50a109d8f47c19ece84d93ff61f2cc91e1d3763a9308a007a1bd95e5c6`;
- new-branch product/architecture/canonical contract SHA-256: `87c0307c44f8058ae14866805afca64ad6ad4c48659ca00b873a9f5aa1394db0`.

Synchronization rules applied:

- no current catalog count is retained as an architecture boundary;
- no fixed branch-depth sequence is retained as a universal model;
- original dependency, proposal, revision, completeness, human-authority, ordered-Guidance, application-code dependency, and safe-apply requirements are preserved;
- internal engineering mechanics remain automatic and contextual inside Registry Studio;
- Registry Studio and Translator remain the only primary engineer workspaces;
- the embedded Canonical Dictionary remains engineer-maintained inside this single contract;
- the established repository path and stable Contract ID remain authoritative.

The old standalone documents are superseded after this unified revision is committed to the new branch.

---

## 20. Final product definition

```text
Registry Studio continuously monitors and explains Registry state
→ engineer opens exact problematic business locations
→ Translator helps author or revise the formulation
→ engineer returns a precise placement request
→ Registry Studio validates the request across the full Registry
→ engineer reviews every affected location
→ Registry Studio applies only the complete approved change
→ clean baseline and history remain traceable
```

Registry Studio and Translator are the two main engineer workspaces.

Registry Studio remains the owner of Registry integrity, automatic analysis, impact, review, approval context, and safe apply.

Translator remains the engineer’s formulation workspace with precise return-to-Registry placement intent.

The engineer remains the final decision authority.
---

## 21. Embedded Canonical Business Phrase Dictionary

<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->

Dictionary ID: `REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1`

Dictionary version: `1`

Status: **APPROVED / STORED**

Visible title: **Canonical Business Phrase Dictionary**

Legacy imported collection titles:

- `Canonical Photo Labels`;
- `Canonical Client Labels`;
- `Canonical Master Workflow Blocks`;
- `Global Platform Rules`.

Source import:

- source path: `docs/architecture/Helpy_Architecture_Registry_v1.md`;
- source ref used for import: `main`;
- retrieved: `2026-07-17`;
- source SHA-256: `dbe4e4fbaa934e3e48c0190088421ff93190cda65083352df7cd67ff641010b7`;
- imported canonical-source block SHA-256: `96466d7b28f447056cdd5be79035c9d0c350c3ede6c3b7a9ae4714558e1f3c67`;
- imported global-rules block SHA-256: `66a03252bc9013646e47215989c042e42651a0a6562079bf77ffbeae6f4fe2fe`.

### Dictionary maintenance contract

Only an authorized engineer may approve a new canonical entry.

A new phrase or block is added in this order:

```text
engineer identifies a reusable business formulation
→ duplicate and conflict analysis
→ applicability analysis
→ Translator RU / EN / TH review
→ reverse semantic verification
→ engineer approval
→ add or version the dictionary entry
→ Registry Studio reindexes the dictionary
→ Registry applications are analyzed and proposed
```

The dictionary does not authorize automatic replacement of every similar phrase.

An exact canonical entry may have different valid applicability. Applicability is evaluated in the full Registry branch context.

The phrase text below is copied from the current Registry source. It is not rewritten in this contract.

### Collection: `helpy.canonical.general_preparation`

Entry type: `phrase_with_applicability`

Status: **APPROVED / STORED**

Правила применения утверждённых формулировок:

Подготовьте доступ к месту выполнения работ.
- Используется только для сценария «Установить и подключить».

Подготовьте доступ к установленному оборудованию.
- Используется только для сценариев «Заменить» и «Перенести».

### Collection: `helpy.canonical.photo_labels`

Entry type: `phrase`

Status: **APPROVED / STORED**

- Фотография оборудования в упаковке.
- Фотография нового оборудования в упаковке.
- Фотография кухонной мойки в упаковке.
- Фотография новой кухонной мойки в упаковке.
- Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- Фотография места установки.
- Фотография места установки сверху.
- Фотография места установки спереди.
- Фотография места установки проточного водонагревателя.
- Фотография места установки электрического душа.
- Фотография места установки спереди с открытыми дверцами, позволяющая оценить толщину столешницы, ширину шкафа, точки подключения воды и водоотвода.
- Фотография места установки спереди с открытыми дверцами, позволяющая оценить толщину столешницы и ширину шкафа.
- Фотография зоны подключения стиральной машины.
- Фотография зоны подключения посудомоечной машины.
- Фотография точки подключения электропитания.
- Фотография точки подключения воды.
- Фотография точек подключения воды.
- Фотография точек подключения воды под кухонной мойкой.
- Фотография кухонной мойки сверху.
- Фотография пространства под кухонной мойкой и системой водоотведения.
- Фотография пространства под кухонной мойкой с измельчителем пищевых отходов и системой водоотведения.
- Фотография пространства под раковиной.
- Фотография пространства под кухонной мойкой.
- Фотография крепления снизу.
- Фотография, позволяющая оценить расстояние от места установки до точек подключения воды.
- Фотография проточного водонагревателя.
- Фотография зоны балкона.
- Фотография отверстия вентиляции воздуха.
- Фотография отверстия для слива сточных вод.
- Фотография установленной стиральной машины.
- Фотография установленной посудомоечной машины.
- Фотография установленной кухонной вытяжки.
- Фотография установленного унитаза.
- Фотография установленного проточного водонагревателя.
- Фотография установленной варочной панели.
- Фотография установленного духового шкафа.
- Фотография установленной микроволновой печи.
- Фотография установленного холодильника с открытыми дверцами.
- Фотография установленной посудомоечной машины с открытой дверцей.
- Фотография установленной стиральной машины с открытой дверцей.
- Фотография в упаковке кухонного крана.
- Фотография в упаковке нового кухонного крана.
- Фотография пространства под кухонной мойкой с точками подключения водоснабжения и отвода сточных вод.
- Фотография установленного кухонного крана.
- Фотография установленной кухонной мойки сверху.
- Фотография установленной раковины.
- Фотография зоны душа.
- Фотография установленного крана.
- Фотография установленного крана в зоне душа.
- Фотография установленного электрического душа.

### Collection: `helpy.canonical.client_labels`

Entry type: `phrase`

Status: **APPROVED / STORED**

### Canonical Client Labels

Status: APPROVED / STORED ✅

Утверждённые формулировки:
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Вы не обязаны снимать оборудование.
- Вы не обязаны отключать водоснабжение.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны подготавливать систему водоотвода.
- Вы не обязаны устранять засор до приезда мастера.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте доступ для работы с электрикой.
- Подготовьте доступ к двери.
- Подготовьте безопасные условия для выполнения работ.
- Уберите содержимое до приезда мастера.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Вы не обязаны разбирать систему водоотведения или элементы мойки.
- Вы не обязаны разбирать систему водоотведения, трап, унитаз или другие элементы сантехники.
- Вы не обязаны отключать водоснабжение или водоотведение.
- Вы не обязаны определять тип крана.
- Вы не обязаны определять тип кухонной мойки.
- Подготовьте доступ к месту засора.
- Вы не обязаны определять тип загрязнения.
- Подготовьте мебель для внутренней уборки, если она входит в согласованный объём услуги.
- Вы не обязаны определять техническую причину проблемы.
- Вы не обязаны выполнять диагностику неисправностей.
- Вы не обязаны разбирать оборудование.
- Работы по отделке, такие как штукатурка, покраска и другие, не входят в базовую услугу.

Требования к новым формулировкам:
Новые формулировки не добавляются без отдельного утверждения.

Правила построения канонических формулировок:
- При наличии утверждённой канонической формулировки она используется без изменения, если не требуется техническая специфика оборудования.
- Формулировки, дублирующие смысл утверждённой канонической формулировки, заменяются на каноническую.
- Новые формулировки создаются только в случаях, когда существующая каноническая формулировка не покрывает необходимую бизнес-логику или техническую специфику.
- Перед утверждением новая формулировка сокращается до максимально универсального и однозначного варианта без потери смысла.
- Перед утверждением новая формулировка проверяется на корректность перевода для всех поддерживаемых языков платформы.
- После утверждения новая каноническая формулировка сначала добавляется в Rule Language & Translation Standard, после чего соответствующие сущности приводятся к новой канонической формулировке.

### Collection: `helpy.canonical.master_workflow_blocks`

Entry type: `ordered_block`

Status: **APPROVED / STORED**

### Canonical Master Workflow Blocks

Status: APPROVED / STORED ✅

Правило использования:
- Если сущность не требует специальной логики, используется канонический блок без изменений.
- Изменения канонического блока допускаются только при наличии технической специфики оборудования.
- Специфичные пункты добавляются внутрь соответствующего канонического блока и не заменяют его полностью.

Алгоритм построения сценариев:

1. Источником истины являются утверждённые канонические формулировки.
- Перед началом работы открыть раздел Canonical Master Workflow Blocks и использовать его как единственный источник истины для правил мастера.
- Новые формулировки не создаются, если подходящая уже существует.

2. Сначала собирается сценарий «Установить и подключить».
- Именно этот сценарий является базовым.
- Он описывает полный алгоритм работы мастера без демонтажа.

3. После утверждения сценария «Установить и подключить» собирается сценарий «Заменить».
- Используются те же канонические блоки.
- Добавляется только канонический блок демонтажа.
- Остальная последовательность блоков сохраняется.

4. Правила строятся глазами мастера.
- Блоки располагаются в той последовательности, в которой мастер выполняет работу на объекте.
- Алгоритм должен соответствовать реальному порядку выполнения работ.

5. Каждая новая формулировка проверяется на универсальность.
- Если формулировка подходит нескольким сущностям, она становится кандидатом в канонический словарь.
- После утверждения сначала обновляется словарь.
- Только затем формулировка используется в сущностях.

6. Специфика оборудования добавляется только внутрь соответствующего канонического блока.
- Канонические блоки не переписываются.
- Добавляются только действительно необходимые технические особенности оборудования.

#### Compatibility Check Before Work
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

#### Equipment Inspection Before Installation and Connection
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

#### Equipment Removal
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

#### Installation and Connection
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

#### Functional Verification
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

### Collection: `helpy.canonical.global_business_rules`

Entry type: `ordered_rule_block`

Status: **APPROVED / STORED**

Confirmed Rules:

### Rule #1 — Client-Safe Scope Rule
Клиент отвечает только на вопросы, которые он объективно может понять.
Платформа не должна требовать от клиента технической диагностики, разборки оборудования, действий с электричеством или иных действий, которые могут быть небезопасны или ухудшить его положение.

Evidence:
- Plumbing: клиент отвечает только на объективно понятные вопросы.
- Plumbing Electric Shower: клиент не разбирает розетки, автоматы или проводку и не выполняет действий, связанных с электричеством.
- Locks: платформа не должна заставлять клиента выполнять действия, которые могут ухудшить его положение как покупателя оборудования.

### Rule #2 — Equipment Packaging Protection Rule
Если клиент уже приобрёл новое оборудование самостоятельно, Helpy не требует вскрытия упаковки до проверки совместимости мастером.
Фотографии упаковки должны позволять увидеть модель, характеристики, размеры и комплектацию, если они указаны производителем.
Клиент должен сохранять право на возврат, обмен и гарантийное обслуживание.

Evidence:
- Plumbing: клиент не должен вскрывать упаковку оборудования для создания заказа.
- Plumbing: при фотографировании упаковки клиент предоставляет упаковку со всей информацией на ней.
- Locks: платформа не требует вскрывать упаковку, нарушать заводские пломбы, раскладывать комплектующие или извлекать оборудование из коробки.

### Rule #3 — Equipment Compatibility Before Demolition Rule
Если работа предполагает замену оборудования, мастер обязан проверить новое оборудование до демонтажа существующего.
Проверка включает совместимость, комплектность, целостность и возможность установки.
Только после проверки мастер приступает к демонтажу.

Evidence:
- Plumbing faucet replacement: мастер проверяет совместимость до демонтажа.
- Plumbing toilet/electric shower replacement: новое оборудование должно быть проверено до работ.
- Locks: проверка нового оборудования до демонтажа существующего закреплена как Global Equipment Verification Rule.

### Rule #4 — Structured Scope Before Chat Rule
Форма заказа собирает первоначальное техническое задание и закрывает визуальную часть ТЗ.
Чат завершает текстовую часть ТЗ, уточняет скрытые работы, материалы, доступ и фиксирует окончательную стоимость.
Чат не заменяет структурированную форму заказа.

Evidence:
- Plumbing: форма собирает первоначальное ТЗ и закрывает визуальную часть.
- Plumbing: чат завершает текстовую часть ТЗ и фиксирует окончательную стоимость.
- Structured Job Scope Contract: Initial job scope is formed from structured questions, answers and required photos.

### Rule #5 — No Extra Photo Requests In Chat Rule
Мастер не может запрашивать дополнительные фотографии в чате, если обязательные фотографии уже определены формой заказа.
Фото-ТЗ должно формироваться через approved photo requirements.
Исключения возможны только через будущие утверждённые правила жизненного цикла чата.

Evidence:
- Plumbing faucet/mixer: мастер не может запрашивать фотографии в чате.
- Plumbing blockage: мастер не может запрашивать дополнительные фотографии в чате.
- Plumbing electric shower: мастер не может запрашивать дополнительные фотографии в чате.

### Rule #6 — One-Time Final Price Rule
Окончательная стоимость заказа может быть изменена мастером только один раз до выбора мастера.
Изменение требует обоснования, обсуждения с клиентом и согласования.
После согласования клиентом и выбора мастера Final Agreed Price становится неизменяемым финансовым фактом заказа.

Evidence:
- Plumbing: окончательная цена фиксируется мастером один раз и после согласования становится неизменяемой.
- Client Expected Price / Final Price Contract: мастер может один раз предложить изменение цены до выбора мастера.
- Final Price Architecture Decision: job-level financial snapshot is immutable after master selection.

### Rule #7 — Platform Boundary / Ownership Rule
Helpy не включает в услугу действия, которые не утверждены как часть сервиса платформы.
Материалы, дополнительные работы, утилизация, вынос демонтированного оборудования, личные вещи клиента, транспортировка, хранение, публичные зоны и вопросы собственности/права доступа не входят в платформенную ответственность, если отдельный контракт явно не утверждает обратное.

Evidence:
- Furniture: master does not move, sort or store client belongings.
- Plumbing: демонтированное оборудование остаётся собственностью клиента; вынос/утилизация не являются услугой Helpy.
- Locks: Helpy не работает с вопросами собственности, аренды и права доступа.
- Air Conditioning: материалы и дополнительные работы согласуются через чат; платформа не участвует в покупке материалов.

### Dictionary change history

| Dictionary version | Date | Change | Evidence |
|---|---|---|---|
| `1` | `2026-07-17` | Initial import of the current approved general preparation phrases, `Canonical Photo Labels`, `Canonical Client Labels`, `Canonical Master Workflow Blocks`, and confirmed Global Platform Rules into the new-branch contract. | Source path, source hashes, and exact imported text recorded above. |

<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->
