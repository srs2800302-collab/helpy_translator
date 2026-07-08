# Registry Studio Clean Rebuild Guard v1

## Decision

`51964f0` is accepted only as a technical fork point.

The previous Registry Studio design source is not accepted as the architectural source of truth.

Registry Studio design starts from zero as a product-neutral engineering system for registry modeling, validation, review, and controlled mutation.

## Rejected growth point

`533fbfa | feat: execute current engineering workflow step`

This point is rejected as the first known runtime-executor growth point.

## Non-negotiable rules

1. Core must stay product-neutral.
2. Core must not contain product-specific names, payloads, scenarios, or business vocabulary.
3. One change must introduce one responsibility.
4. A new model is allowed only after explicit ownership audit: identity, lifecycle, owner, and boundary.
5. Helper, wrapper, manager, facade, bridge, locator, and magic utility shortcuts are forbidden.
6. Orchestrator remains a narrow coordination boundary.
7. Orchestrator must not execute workflow steps directly.
8. Orchestrator must not resolve services through a catalog.
9. Runtime execution must not be hidden behind a generic catch-all abstraction.
10. Registry mutation is allowed only through an approved use case.
11. Code is not accepted without boundary audit, analyzer verification, and targeted tests when the local toolchain allows them.

## Clean rebuild start condition

Before new Registry Studio design work starts, the Registry Studio boundary must not contain product-specific adapter names, payload names, fixtures, documents, or examples.

The Flutter package name is repository identity and is outside this guard until a separate package-rename decision is approved.
