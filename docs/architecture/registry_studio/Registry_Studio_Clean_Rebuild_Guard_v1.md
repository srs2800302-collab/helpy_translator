# Registry Studio Clean Rebuild Guard v1

## Решение

`51964f0` принимается только как техническая точка ветвления.

Предыдущий источник проектировки Registry Studio не принимается как архитектурный source of truth.

Проектировка Registry Studio начинается с нуля как самостоятельной, универсальной engineering-системы для моделирования, проверки, review и контролируемого изменения registry.

## Отклонённая точка роста

`533fbfa | feat: execute current engineering workflow step`

Эта точка отклоняется как первая известная точка роста в сторону `runtime executor`.

## Непереговорные правила

1. `Core` должен оставаться product-neutral.
2. `Core` не должен содержать project-specific names, payloads, scenarios или business vocabulary.
3. Один change должен вводить одну responsibility.
4. Новая model допускается только после явного ownership-аудита: identity, lifecycle, owner, boundary.
5. Новая entity/model не допускается как shortcut или convenience layer. Сначала должно быть доказано, что существующие сущности не могут корректно нести новую responsibility без нарушения identity, lifecycle, owner, boundary и Clean Architecture.
6. Запрещены `helper`, `wrapper`, `manager`, `facade`, `bridge`, `locator` и magic utility shortcuts.
7. `Orchestrator` остаётся узкой coordination boundary.
8. `Orchestrator` не должен выполнять workflow steps напрямую.
9. `Orchestrator` не должен resolve-ить services через catalog.
10. `Runtime execution` не должен прятаться за generic catch-all abstraction.
11. `Registry mutation` допускается только через approved use case.
12. Код не принимается без boundary audit, analyzer verification и targeted tests, если локальный toolchain позволяет их выполнить.

## Условие старта clean rebuild

Перед началом новой проектировки Registry Studio boundary не должен содержать product-specific adapter names, payload names, fixtures, documents или examples.

Flutter package name относится к repository identity и остаётся вне этого guard до отдельного решения о package rename.

## Решение по самостоятельности продукта

Registry Studio — самостоятельный универсальный registry engineering tool.

Registry Studio должен уметь работать с разными проектами и не должен наследовать product identity, naming, business vocabulary, adapter boundaries или architectural ownership от первого проекта, на котором он проверяется.

Первый проект является только pilot field для проверки Registry Studio в реальных условиях.

Pilot-project code, terminology, payloads, scenarios, fixtures или documents не должны случайно становиться design source для Registry Studio Core.

Если pilot-specific material потребуется позже, он должен находиться вне `Core` и пройти отдельный boundary и ownership audit.

## Решение Zero Core Inventory

После первого clean-boundary reset текущий `Core` классифицируется следующим образом.

### Принято как технические нейтральные primitives

- `RegistryEntityId`
- `RegistryPath`
- `SourceEvidence`

Эти primitives являются product-neutral и не содержат runtime execution, service resolution, project-specific vocabulary или adapter implementation behavior.

### Принято как contract primitives с ownership watch

- `RegistryAdapterContractIdentity`
- `RegistryEntityKind`
- `RegistryEntityPayload`
- `RegistryEntity`

Термин `adapterContract` допускается только как external/source-specific semantic contract identity.

Он не должен расширяться в runtime adapters, service locators, implementation bindings, presenters, helper layers или project-specific adapter packages.

### Отклонено как архитектурный source of truth

Текущий `core/application/engineering` runtime/execution/service-catalog design не принимается как архитектурный source of truth для clean rebuild.

Он может рассматриваться только как legacy reference.

Любая будущая workflow, orchestration, mutation, runtime или service execution model требует отдельного ownership audit до принятия кода.

## Решение по source ownership для RegistryEntity

`RegistryEntity` является source-backed registry unit.

`SourceEvidence` входит в `RegistryEntity` как обязательная provenance часть.

`RegistryEntity` не может существовать без хотя бы одного `SourceEvidence`, потому что Core не должен допускать registry entity без доказанного источника.

Для этого не создаётся новая entity/model. Используется уже существующий `SourceEvidence`.

Equality для `RegistryEntity` остаётся основанным на stable `RegistryEntityId`; `SourceEvidence`, `RegistryPath`, `RegistryEntityKind` и `RegistryEntityPayload` не меняют identity entity.

## Решение по RegistryPath domain ownership

Registry Studio не строит domain identity вокруг Markdown, source headings или source line positions.

`RegistryPath` является canonical domain path: он описывает semantic domain position конкретного `RegistryEntity` внутри registry domain model.

`RegistryPath` не является Markdown navigation path, source document heading path, document locator, line-based identity, UI navigation path или runtime adapter path.

Source document coordinates принадлежат `SourceEvidence`.

`SourceEvidence.headingPath`, `sourceDocumentPath`, `startLine` и `endLine` используются только как provenance/source evidence и не определяют domain identity `RegistryEntity`.

`RegistryPath` сейчас фиксирует базовые универсальные инварианты: non-empty ordered segments, trim каждого segment, запрет пустых segments и immutable list.

Это не MVP-сокращение и не временная слабая модель. Более строгая canonical path shape допускается только после отдельного ownership-аудита domain hierarchy, чтобы не зашить случайную adapter-shaped, Markdown-shaped или UI-shaped структуру как долгоживущий domain contract.

## Принцип engineer-centered top-down design

Registry Studio проектируется сверху вниз от основного потребителя: engineer/user, который анализирует registry, принимает архитектурные решения, проверяет изменения и контролирует publication path.

Каждая новая responsibility должна объясняться через реальную engineering-задачу:

- какое решение принимает engineer/user;
- какой verified context нужен для этого решения;
- какие domain invariants должны защитить registry от ошибки;
- какая часть ответственности уже покрыта существующими domain сущностями;
- почему новая model/entity нужна или не нужна.

Этот принцип не означает UI-first design.

UI, Markdown, source document structure, runtime adapter, importer или presenter не должны определять domain identity.

Engineer-centered framing определяет problem boundary; domain model определяет устойчивые contracts, identity, lifecycle, ownership и invariants.
