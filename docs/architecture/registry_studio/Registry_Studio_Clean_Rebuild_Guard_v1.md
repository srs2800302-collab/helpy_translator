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

- `RegistrySemanticContractIdentity`
- `RegistryEntityKind`
- `RegistryEntityPayload`
- `RegistryEntity`

`semanticContract` допускается только как semantic contract identity.

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

## Принцип responsibility isolation и orchestration boundary

Registry Studio entities должны сохранять изоляцию responsibilities.

Entity не должна знать внутренний workflow другой entity и не должна смешивать чужие рабочие процессы со своей responsibility.

Взаимодействие между entities допускается только через явные domain contracts, value objects, invariants или approved use case boundary.

Orchestrator / coordinator не должен знать внутреннюю реализацию каждой entity и не должен владеть её domain logic.

Orchestrator может знать только доступный ему инструментарий: approved capabilities, contracts, use case boundaries и допустимые interaction points.

Orchestrator не должен становиться god object, service locator, runtime executor или местом, где смешиваются responsibilities разных entities.

Метафора: дирижёр не играет за каждого музыканта и не владеет техникой игры каждого инструмента. Он знает состав оркестра, допустимые партии, момент входа и правила координации.

## Основная mission Registry Studio и human authority boundary

Основная задача Registry Studio — находить drift, рассинхрон и неоднозначности в registry и показывать их engineer/user в проверяемом context.

Registry Studio должна:

- подсвечивать найденные проблемные места;
- показывать связанные registry места;
- анализировать найденную проблему в доступном context;
- явно показывать engineer/user, если context недостаточен, противоречив или неоднозначен;
- готовить verified engineering context для принятия решения.

Registry Studio не имеет права самостоятельно принимать semantic decisions, canonicalization decisions, change-scope decisions или publication decisions.

Registry Studio не должна самостоятельно править registry.

Любое изменение registry допускается только после решения engineer/user и через approved use case boundary.

Engineer/user остаётся единственным владельцем semantic decision, ambiguity resolution, approved change scope и publication control.

## Translator boundary note

Исторически текущий repository начинался как трехъязычный translator.

Registry functionality была добавлена поверх translator prototype, что привело к смешению responsibilities и последующему clean rebuild.

В новой архитектуре Registry Studio является самостоятельным registry engineering tool.

Translator может быть будущей assistant capability для engineer/user, но не является владельцем registry identity, registry structure, semantic decisions, drift analysis или publication path.

Детальная translator boundary требует отдельного ownership-аудита и не принимается в рамках текущего clean rebuild шага.

## Решение по RegistryEntityKind / RegistryEntityPayload contract boundary

`RegistryEntityKind` и `RegistryEntityPayload` защищают engineer/user от анализа registry entity с payload, который не соответствует заявленному semantic contract, entity kind или schema version.

Эта связка нужна для drift analysis, verified context и safe review: engineer/user должен видеть typed registry entity, у которой kind и payload согласованы до начала анализа связанных мест.

`semanticContract` в текущем Core означает только semantic contract identity.

`semanticContract` не является runtime adapter, service binding, presenter, importer, handler, locator или execution capability.

`RegistrySemanticContractIdentity` не даёт Core права создавать adapter, вызывать adapter, resolve-ить implementation или выполнять runtime operation.

Если позже потребуется runtime integration, importer или translator capability, это должно пройти отдельный ownership-аудит вне текущей domain entity compatibility responsibility.

## Ownership gap после audit текущих domain primitives

Текущие domain primitives закрывают только базовую валидность typed source-backed `RegistryEntity`.

Они покрывают:

- stable identity через `RegistryEntityId`;
- canonical domain position через `RegistryPath`;
- semantic contract / kind / schema compatibility через `RegistrySemanticContractIdentity`, `RegistryEntityKind` и `RegistryEntityPayload`;
- source provenance через `SourceEvidence`.

Они не покрывают responsibility поиска drift, рассинхрона, связанных registry мест, dependency context, unclear context или verified engineering context.

Эта responsibility не должна добавляться внутрь `RegistryEntity`, потому что `RegistryEntity` не должна знать внутреннюю работу других entities и не должна становиться graph, analyzer или review context.

Эта responsibility не должна добавляться внутрь `RegistryPath`, потому что `RegistryPath` является canonical domain path, а не relation graph или dependency model.

Эта responsibility не должна добавляться внутрь `SourceEvidence`, потому что `SourceEvidence` владеет только provenance/source coordinates.

Следующая domain responsibility должна быть спроектирована отдельно как representation of registry relationships / related context before drift analysis, но только после отдельного naming и ownership-аудита.

## Решение по первой relationship responsibility

Первая новая domain responsibility после `RegistryEntity` называется `RegistryRelation`.

`RegistryRelation` означает явную domain-связь между registry entities, которая помогает engineer/user увидеть связанные registry места до drift analysis.

`RegistryRelation` не является graph, analyzer, finding, review context, change plan, publication instruction или mutation command.

`RegistryRelation` не должна выполнять drift detection самостоятельно.

`RegistryRelation` не должна знать internal workflow связанных entities.

`RegistryRelation` должна быть atomic domain fact: какая registry entity связана с какой другой registry entity и каким relation meaning эта связь объясняется.

`RegistryDependency` отклоняется как первичное имя, потому что dependency является только одним возможным видом relation и преждевременно сужает domain.

`RegistryRelatedContext` отклоняется как первичное имя, потому что это assembled context/result для engineer/user, а не atomic relation fact.

`RegistryContextGraph` отклоняется как первичное имя, потому что graph является более поздней composition/analysis structure и может преждевременно потянуть infrastructure/analyzer design.

## Ownership decision для RegistryRelation

`RegistryRelation` на текущем этапе является value object, а не entity.

Для `RegistryRelation` не создаётся отдельный `RegistryRelationId`, потому что relation пока не имеет самостоятельного lifecycle, publication state, review state или mutation flow.

Уникальность `RegistryRelation` выводится из:

- source registry entity;
- target registry entity;
- relation meaning.

`RegistryRelation` является directional fact: связь от одной registry entity к другой registry entity имеет конкретный semantic meaning.

Если в будущем relation получит самостоятельный lifecycle, review state, confidence state, approval state или publication control, вопрос отдельной identity должен пройти новый ownership-аудит.

`RegistryRelation` не должна хранить payload связанных entities. Она ссылается на registry entities через `RegistryEntityId`.

`RegistryRelation` не должна становиться graph container. Набор relations, traversal, grouping и related context assembly являются отдельными responsibilities и не входят в первый `RegistryRelation` primitive.

`RegistryRelation` должна быть пригодна для построения related context, но не является этим context.

## Решение по RegistryRelation collection boundary

После добавления `RegistryRelation` отдельный `RegistryRelationSet`, `RegistryRelations`, `RegistryRelationCollection`, graph или context container не создаётся.

На текущем этапе набор relations может передаваться как `Iterable<RegistryRelation>`.

Отдельная collection/domain container responsibility допускается только при появлении явного domain invariant, например:

- запрет duplicate relations;
- принадлежность всех relations одному registry snapshot;
- completeness boundary для relation set;
- traversal/indexing/grouping;
- related context assembly для engineer/user.

До появления такого invariant collection wrapper будет преждевременным слоем и нарушит clean rebuild boundary.
