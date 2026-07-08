# Registry Studio Architecture Contract v1

Status: APPROVED — UNIVERSAL ARCHITECTURE BASELINE
Repository: `helpy_translator`
Development branch: `registry-studio/v1`

## 1. Authority and Development Boundary

This document is the working source of truth for universal Registry Studio
architecture.

Registry Studio is a standalone reusable engineering platform. It is not a
subsystem, module, or architectural dependency of any specific product.

Universal Registry Studio source code, contracts, and builds develop in the
`helpy_translator` repository.

Helpy is the first project adapter and pilot. It provides real Registry
scenarios for validating Studio architecture, but it does not own Registry
Studio.

The Helpy repository receives only explicit Helpy adapter or integration
changes. Generic Registry Studio changes must not be developed there.

The existing Translator and Registry UI prototype is implementation evidence,
not the final definition of Registry Studio domain identity or ownership.

## 2. Interface Boundary

One Registry governance core supports multiple project-neutral Registry
interfaces:

- Registry Studio provides the full precise engineering interface.
- An Admin Panel provides the standard project interface.
- Every Registry-facing interface uses the same approved Registry governance
  contracts and publication path.
- Registry Studio may operate standalone and is not a module of any project's
  Admin Panel.

A project Admin Panel may separately publish project operational records
through project-specific workflows. That does not redefine Registry Studio or
directly alter canonical Registry engineering state.

Any divergence between project operational configuration and canonical Registry
representation is input to Registry Studio drift analysis.

## 3. Translator Integration Boundary

Helpy Translator is a specialized translation-review capability.

Translator responsibilities:

- accept a selected existing Registry formulation;
- accept manually entered candidate source formulations;
- perform mandatory RU / EN / TH circular translation review;
- provide verdict, translation results, warnings, and audit commentary;
- support manual correction of translations.

Translator does not:

- own Registry structure;
- determine Registry dependencies;
- decide canonical placement;
- publish Registry changes;
- perform automatic Registry-wide replacement.

Translation review has two entry paths:

1. A selected existing Registry formulation forwarded into the translation
   workspace.
2. A manually entered candidate source formulation reviewed before approval and
   addition to a canonical dictionary.

Both entry paths use the same RU / EN / TH translation flow and review
statuses.

A reviewed candidate may be handed to Registry Studio as typed integration
input.

Registry Studio must support an explicit authorized-engineer operation to add a
reviewed candidate to a selected canonical dictionary section inside a selected
`PUBLISHING_DRAFT` DraftWorkspace.

That operation:

- preserves the RU / EN / TH review result, verdict, warnings, and audit
  commentary as draft engineering context;
- does not create Published Registry state;
- does not approve or apply the candidate automatically;
- may trigger impact, duplicate, semantic-candidate, and drift analysis before
  governed publication.

A translation verdict, including `EXACT`, is not autonomous approval,
canonicalization, publication evidence, or permission for automatic
replacement.

## 4. Canonical Formulation and Adapter Boundary

Registry Studio Core does not define concrete phrase, rule, photo, question,
guidance, or translation kinds.

A project adapter defines its own canonical dictionary semantics.

For any adapter that uses canonical formulations:

- every dictionary entry has stable adapter-defined identity;
- phrase text, Markdown bytes, line number, Git commit, and storage coordinate
  are never formulation identity;
- use sites reference the stable dictionary identity through typed
  adapter-defined semantics where confirmed dependency is required;
- identical text without approved semantic reference remains an informational
  text match;
- a semantically similar unresolved use remains a semantic candidate requiring
  human decision.

A candidate added from Translator enters only a DraftWorkspace. It does not
create Published Registry state until governed publication succeeds.

### Helpy Adapter: Permanent Service Intake Semantic Contract

The Helpy adapter defines durable semantic content for service intake. This
content is not a temporary parser projection, Translator feature model, or
Markdown navigation model.

Helpy uses adapter-defined RegistryEntity kinds including:

- `helpy.service_standard` for an approved service/category/branch standard;
- `helpy.service_intake` for one service intake entity.

A `helpy.service_intake` RegistryEntity owns one permanent typed Helpy payload:

```text
Entity
→ Scenario
  → Scenario Entry Evidence
  → Questions
  → Photo Questions
  → Photo Limits
  → Client Guidance
  → Master Guidance
```

The Core `RegistryEntity` remains the only aggregate identity owner. The Helpy
payload must not be duplicated by a parallel intake aggregate created solely
for a pilot, parser, navigation tree, or UI.

`Scenario Selection` is represented as Scenario Entry Evidence. It is not a
fifth domain entity. It records the selector question and selected answer
through which the client enters that Scenario.

Conditions and answer/context variants are not additional primary scenarios.
They remain qualifiers inside Questions and determine the applicability of
Photo Questions and photo limits.

Any engineering review of scenario content must be able to raise the full
technical specification for the Entity and all relevant Scenarios:

```text
Entity
→ relevant Scenario(s)
  → Scenario Entry Evidence
  → Questions
  → Photo Questions
  → Photo Limits
  → Client Guidance
  → Master Guidance
```

Questions and Photo Questions are the primary structure through which Helpy
collects the client technical specification for the master. Client Guidance and
Master Guidance are scenario-owned role-specific hints shown on application
screens. The client sees only Client Guidance. The master sees only Master
Guidance. Guidance wording may differ between Scenarios and must be evaluated
against the full technical specification context of the relevant Scenario,
never in isolation.

Scenarios remain independent semantic branches. A Replace scenario may repeat
selected questions or photo requests from Install & Connect and may contain
additional requirements. Repeated wording or source context must not create an
automatic cross-scenario identity, relation, or merge.

Within one `helpy.service_intake` entity, Questions, answer options, Photo
Questions, and photo limits must have adapter-defined semantic keys whenever
another payload component refers to them. These keys are scoped to the owning
RegistryEntity and are not Core RegistryEntity identities.

Scenario photo content contains:

- required and optional Photo Questions;
- photo limits;
- confirmed answer/context applicability;
- confirmed reuse, addition, or replacement semantics where explicitly
  approved by an engineer.

A `helpy.service_standard` and a rendered local intake question are different
semantic objects even when their wording is similar. A standard may govern
the placement or structure of a local Scenario Selection without duplicating
that local intake question.

A confirmed standard-to-intake dependency is represented only through an
adapter-defined RegistryRelation. The initial Helpy relation kind is
`governs_intake_structure`. Its typed qualifiers identify the governed scope,
for example `scenario_entry_placement`. Textual similarity alone must never
create this relation.

Helpy source evidence may preserve:

- configured document path;
- immutable loaded-source fingerprint;
- heading path;
- source line range or ranges.

Source evidence proves provenance only. Markdown text, heading path, line
number, fingerprint, Git revision, cache key, and storage coordinate are
never RegistryEntity identity, semantic component identity, or automatic
relation identity.

Source extraction may create read-only verified facts for EngineeringContext.
It must not independently create RegistryEntity records, stable identities,
confirmed RegistryRelation records, DraftWorkspace changes, publication
evidence, or automatic Registry modifications.

## 5. Core Domain Model

### Registry

Registry is the root aggregate for one published semantic Registry state.

Registry owns:

- RegistryEntity;
- RegistryPath;
- RegistryRelation;
- current published revision;
- deterministic published content fingerprint;
- adapter identity;
- adapter semantic-contract version.

Registry is not Markdown, a Git commit, a file path, a storage coordinate, or
a UI tree.

### RegistryEntity

RegistryEntity has:

- stable immutable identity;
- exactly one primary adapter-defined kind;
- canonical RegistryPath;
- typed adapter-defined semantic content;
- semantic relations.

RegistryEntity does not own governance, runtime execution, validation, risk,
publication, or UI state.

### RegistryPath

RegistryPath is a value object representing a canonical logical address.

It is not a RegistryEntity and has no independent lifecycle.

### RegistryRelation

RegistryRelation is one canonical directed semantic edge between exactly two
RegistryEntity objects.

Only one directed relation record may represent one semantic fact. Reverse
traversal and inverse labels are derived projections.

Concrete relation kinds, qualifiers, impact propagation, validation constraints
and cycle policy are adapter-defined.

### RegistrySnapshot

RegistrySnapshot is immutable verified semantic evidence for one exact Registry
revision.

It preserves revision provenance, fingerprint, adapter identity and semantic
contract version. It is not mutable draft state.

### RegistryDependency and RegistryGraph

RegistryDependency is a derived explainable impact edge for one exact Registry
or DraftWorkspace revision.

Dependency result categories are:

1. Direct confirmed dependency.
2. Indirect confirmed impact.
3. Semantic candidate requiring human decision.
4. Informational text match without confirmed semantic relation.

Only direct confirmed dependencies and indirect confirmed impacts enter
deterministic impact scope automatically.

RegistryGraph is a derived deterministic projection. It provides entity lookup,
forward and reverse traversal, dependency navigation, cycle detection, path
provenance, and explainable traversal.

## 6. Governance Lifecycle

RegistryTransaction is the only governed lifecycle owner for one Registry
modification intended for publication.

DraftWorkspace is the common isolated workspace aggregate with exactly one
purpose:

- `PUBLISHING_DRAFT`;
- `SANDBOX`.

`PUBLISHING_DRAFT`:

- prepares Registry changes intended for publication;
- has exactly one active RegistryTransaction;
- owns mutable draft revision, fingerprint, and DIRTY / CLEAN state;
- may request current analysis, validation, risk, and gate evidence;
- is the only workspace purpose permitted to enter publication governance.

`SANDBOX`:

- owns isolated experimental revision;
- has no RegistryTransaction;
- must not invoke PublishingGate or publication;
- may run deterministic simulation, analysis, and validation experiments;
- produces informational experimental results only.

Sandbox promotion never converts an existing SANDBOX workspace.

Promotion creates a new `PUBLISHING_DRAFT` DraftWorkspace seeded from the exact
sandbox revision and fingerprint, then creates a new RegistryTransaction and
requires fresh analysis, validation, risk, and gate evidence.

Every DraftWorkspace modification invalidates stale analysis, validation, risk,
and gate evidence.

ImpactAnalysisResult, ValidationResult, RiskAssessment, PublishingGateDecision,
and PublicationAttempt are transaction-owned evidence. They are not independent
aggregates or repositories.

## 7. Repositories and Publication

Registry Studio has exactly three logical repository boundaries:

- RegistryRepository;
- DraftWorkspaceRepository;
- RegistryGovernanceRepository.

Publication uses one atomic application boundary. Repositories must not expose
technical begin, commit, rollback, staged-write, or transaction-wrapper APIs.

A successful publication atomically persists the resulting published Registry
revision, RegistrySnapshot, RegistryTransaction, PublicationAttempt, AuditLog
records, and PUBLISHING_DRAFT CLEAN transition.

Recovery creates a new RegistryTransaction that references the historical
published transaction. Historical publication outcome is never rewritten.

## 8. Engineering Capabilities

DependencyExplorer is read-only graph traversal for one exact Registry or
DraftWorkspace revision.

BulkOperations applies a deterministic approved plan inside DraftWorkspace. It
does not own transaction, validation, gate, publication, or audit lifecycle.

GlobalRename is semantic bulk refactoring. It preserves immutable entity
identity and must never perform blind text replacement.

RulesSimulator is a universal deterministic non-mutating capability. It runs
against one exact published Registry, PUBLISHING_DRAFT revision, or SANDBOX
revision and returns typed adapter-defined output and trace.

RulesSimulator does not modify Registry or DraftWorkspace and does not create
publication evidence automatically.

RegistryCoverage is adapter-defined. Helpy Registry Coverage is a Helpy adapter
capability, not Registry Studio Core.

## 9. Runtime Boundary

EngineeringContext provides verified read-only base context.

`EngineeringContext` обязан показывать инженеру полный read-only контекст целевой `RegistryEntity` из `RegistryEntity.payload`:

```text
Entity
→ Scenario
  → Scenario Entry Evidence
  → Questions
  → Photo Questions
  → Photo Limits
  → Client Guidance
  → Master Guidance
```

Каждый `Scenario` рассматривается отдельно. У разных `Scenario` могут быть
разные `Questions`, `Photo Questions`, `Photo Limits`, `Client Guidance` и
`Master Guidance`.

`Client Guidance` и `Master Guidance` являются role-specific подсказками
экранов для конкретного `Scenario`.

`EngineeringContext` не создаёт отдельный `RegistryEntityReviewContext`,
`ReviewContent` или параллельный payload. Он использует существующих владельцев
ответственности: `RegistryEntity`, `RegistryEntityPayload`, `SourceEvidence`,
`RegistryRelation`, `RegistryDependency`, `RegistryGraph` и `RegistrySnapshot`.

EngineerIntent is runtime input.

EngineeringWorkflowResolver proposes eligible workflow. Engineer confirmation is
required before execution.

EngineeringOrchestrator coordinates only confirmed workflow execution.

EngineeringWorkflowInstance owns workflow runtime state.

WorkflowStepDefinition replaces legacy EngineeringOperation.

WorkflowStepExecution replaces legacy EngineeringOperationInstance.

EngineeringServiceContract is a typed handler boundary with typed input, output,
and failure values.

EngineeringServiceCapabilityCatalog is immutable validated runtime composition.
It resolves each executable workflow step to exactly one approved typed handler
binding and preserves composition fingerprint, contract identity, version, and
binding provenance.

Canonical runtime flow:

EngineerIntent
→ EngineeringContext
→ EngineeringWorkflowResolver
→ engineer confirmation
→ EngineeringWorkflowInstance
→ WorkflowStepExecution
→ EngineeringServiceContract
→ EngineeringServiceCapabilityCatalog
→ EngineeringService
→ DraftWorkspace
→ RegistryTransaction
→ analysis / validation / publishing / audit

## 10. Human Decision and Drift

Registry Studio provides verified context, dependency analysis, drift detection,
ambiguity reporting, and explainable change plans.

Registry Studio does not make autonomous semantic, canonicalization, or
publication decisions.

Authorized human actors decide:

- canonical formulation placement;
- semantic candidate resolution;
- acceptable exceptions;
- confirmed replacement scope;
- approval of deterministic bulk change plans.

Informational text matches must never be rewritten automatically.

A project Admin Panel may use standard Registry operations through the shared
governance core. Registry Studio remains the full engineering interface for
deep analysis, controlled refactoring, ambiguity handling, and Registry health.

## 11. Explicit Non-Goals

Registry Studio Core must not:

- contain project-specific business logic;
- include project-specific names in universal Studio component names;
- allow project names such as `Helpy` outside explicit adapter or
  source-integration boundaries. Universal Core, Review, Workflow, Runtime,
  Publication, and Registry components must remain project-agnostic;
- execute orders, payments, finance, customer, worker, or operational runtime;
- become an Admin Panel module;
- use Markdown syntax as domain identity;
- create a separate SandboxMode model;
- create standalone TransactionPayload, PublicationResult, RollbackPayload,
  RiskClassification, EngineeringExecutionContext, EngineeringOperation,
  EngineeringOperationInstance, EngineeringServiceContractPayload, or
  EngineeringServiceCapabilityRegistry models;
- replace human engineering judgment with automatic text replacement.

## 12. Current Implementation Baseline

The current Registry Studio prototype provides working evidence for:

- manual source-formulation input;
- translation review;
- RU / EN / TH translation results;
- verdict and audit feedback;
- Registry loading and navigation prototype;
- phrase-status persistence;
- work-session persistence.

Current prototype types such as Markdown-derived RegistryNode and lineNumber
remain implementation details. They must not define final Registry Studio Core
identity, publication, relation, dependency, or governance contracts.

Future development must proceed through this contract and controlled
implementation steps in `helpy_translator/develop/v2`.
