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

Registry Studio — самостоятельное универсальное registry engineering extension для engineer.

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

Registry Studio не строит domain identity вокруг source format, source headings или source line positions.

`RegistryPath` является canonical domain path: он описывает semantic domain position конкретного `RegistryEntity` внутри registry domain model.

`RegistryPath` не является source-format navigation path, source document heading path, document locator, line-based identity, UI navigation path или runtime adapter path.

Source document coordinates принадлежат `SourceEvidence`.

`SourceEvidence.headingPath`, `sourceDocumentPath`, `startLine` и `endLine` используются только как provenance/source evidence и не определяют domain identity `RegistryEntity`.

`RegistryPath` сейчас фиксирует базовые универсальные инварианты: non-empty ordered segments, trim каждого segment, запрет пустых segments и immutable list.

Это не MVP-сокращение и не временная слабая модель. Более строгая canonical path shape допускается только после отдельного ownership-аудита domain hierarchy, чтобы не зашить случайную adapter-shaped, source-format-shaped или UI-shaped структуру как долгоживущий domain contract.

## Принцип engineer-centered top-down design

Registry Studio проектируется сверху вниз от основного потребителя: engineer/user, который анализирует registry, принимает архитектурные решения, проверяет изменения и контролирует publication path.

Каждая новая responsibility должна объясняться через реальную engineering-задачу:

- какое решение принимает engineer/user;
- какой verified context нужен для этого решения;
- какие domain invariants должны защитить registry от ошибки;
- какая часть ответственности уже покрыта существующими domain сущностями;
- почему новая model/entity нужна или не нужна.

Этот принцип не означает UI-first design.

UI, source format, source markup, source document structure, runtime adapter, importer или presenter не должны определять domain identity.

Source markup, source headings и source lines допускаются только как source evidence/provenance, если конкретный adapter читает registry из документа. Они не являются центром Registry Studio и не определяют domain model.

Engineer-centered framing определяет problem boundary: Registry Studio проектируется как assistant/tool для engineer, который проверяет registry, видит связанные факты, понимает риск и принимает решение.

Рабочий процесс Registry Studio должен рассматриваться глазами engineer: что engineer проверяет, какие факты ему нужны, где он видит рассинхрон, где он принимает решение и что должно быть подтверждено перед изменением registry.

Engineer-centered framing не является основанием создавать view-only entities, visibility wrappers, presenter models или convenience context.

Новая model допускается только если у неё есть собственные invariants, owner, lifecycle и boundary. Сущность ради того, чтобы "что-то показать engineer", запрещена.

Domain model определяет устойчивые contracts, identity, lifecycle, ownership и invariants. Engineer workflow определяет, какие факты должны быть доступны для принятия решения, но не подменяет domain ownership.

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

Текущий repository начался с трехъязычного translator, и именно из этой практической задачи появилась идея Registry Studio.

Translator не отклоняется и не считается ненужным legacy.

Translator является обязательной assistant capability / product add-on для engineer и по product priority стоит сразу после Registry Studio registry engineering workflow.

Причина: для Thailand-oriented projects multilingual registry quality является критичной частью инженерной проверки. Engineer должен иметь инструмент для проверки RU/EN/TH canonical wording, reverse-check, consistency и translation drift.

Translator может помогать engineer:

- проверять канонические формулировки;
- выполнять multilingual translation / reverse-check;
- подсвечивать Exact / Equivalent / Needs Review / Canonical Drift / Failed status;
- объяснять различия между языками;
- готовить candidate canonical phrases для будущего registry dictionary.

Engineer остаётся владельцем решения: какую формулировку считать канонической, что добавить в registry dictionary, какой drift принять как проблему и когда отправлять изменение в publication path.

Историческим является только факт происхождения идеи и текущее смешение responsibilities в repository. Текущая translator implementation была недостаточно сильной как registry engineering foundation, поэтому Registry Studio вынесен в clean rebuild.

В новой архитектуре Registry Studio остаётся самостоятельным registry engineering tool и assistant для engineer.

Translator не является владельцем registry identity, registry structure, semantic decisions, drift analysis ownership или publication path.

Translator не должен становиться source of truth для Registry Studio Core и не должен протаскивать Helpy-specific prompts, client-rule vocabulary или translation workflow внутрь Core.

Интеграция translator capability с Registry Studio должна пройти отдельный ownership-аудит: owner, boundary, inputs, outputs, lifecycle, registry dictionary interaction и запрет на semantic/publication decisions за engineer.

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

## Application boundary decision для related context

В текущем `lib/registry_studio` нет готового application/use case boundary для подготовки связанных registry мест.

Первая read-only application responsibility после `RegistryRelation` называется `PrepareRegistryRelatedContext`.

`PrepareRegistryRelatedContext` должен готовить related context для engineer/user на основе `RegistryEntity` и `Iterable<RegistryRelation>`.

Эта responsibility существует для того, чтобы engineer/user мог увидеть связанные registry места до drift analysis.

`PrepareRegistryRelatedContext` не является drift detector, analyzer, finding builder, graph traversal engine, presenter, UI projection, change plan, publication instruction или mutation command.

`PrepareRegistryRelatedContext` не должен принимать semantic decisions и не должен изменять registry.

`RegistryRelatedContext` не принимается как первичный domain primitive. Он может появиться только как explicit read-only application result после отдельного ownership-аудита result shape.

До появления result-specific invariants application boundary может быть зафиксирован без создания graph/container/domain wrapper.

## Result shape decision для PrepareRegistryRelatedContext

`PrepareRegistryRelatedContext` требует explicit read-only application result, потому что у результата есть собственные invariants.

Этот result называется `RegistryRelatedContext`.

`RegistryRelatedContext` допускается только как application result, а не как primary domain primitive.

`RegistryRelatedContext` должен содержать:

- primary `RegistryEntity`;
- matched `RegistryRelation` items, которые связаны с primary entity;
- related `RegistryEntityId` values, выведенные из matched relations.

`RegistryRelatedContext` не должен hydrated related entities, если они явно не переданы use case.

`RegistryRelatedContext` не должен выполнять drift detection, semantic analysis, graph traversal, finding building, review decision, publication decision или mutation.

`RegistryRelatedContext` не является presenter, UI projection или view model.

Минимальные invariants `RegistryRelatedContext`:

- каждая matched relation должна содержать `primary.id` как source или target;
- related entity ids выводятся из matched relations;
- related entity ids не должны содержать `primary.id`;
- collections внутри result должны быть immutable.

Unresolved/hydrated related entities не входят в первый result shape. Они могут быть добавлены только после отдельного ownership-аудита input boundary и result invariants.

## Provenance decision для текущих Core primitives

Часть текущих Core primitives была технически создана до clean rebuild в commit `79bd7e6 | feat: add registry studio intake domain slice`.

Эти primitives не принимаются как legacy source of truth автоматически. Они считаются carried but re-accepted только после отдельного ownership-аудита в clean rebuild.

Carried but re-accepted clean primitives:

- `RegistryEntityPayload`;
- `RegistryEntity`;
- `SourceEvidence`;
- `RegistryEntityId`;
- `RegistryEntityKind`;
- `RegistryPath`;
- `RegistrySemanticContractIdentity`.

Причины re-acceptance:

- `RegistryEntity` переутверждён как typed source-backed registry unit;
- `SourceEvidence` переутверждён как provenance/source coordinates;
- `RegistryPath` переутверждён как canonical domain path, не source-format/source-document/UI path;
- `RegistrySemanticContractIdentity` заменил rejected adapter/runtime naming;
- `RegistryEntityKind` и `RegistryEntityPayload` переутверждены как semantic contract / kind / schema compatibility boundary.

Created in clean rebuild:

- `RegistryRelation`;
- `RegistryRelationMeaning`;
- `RegistryRelatedContext`.

Legacy residue в текущем Core code/test не допускается.

`package:helpy_translator/...` imports сейчас являются package identity текущего repository и не считаются Helpy adapter/domain leak. Переименование package identity является отдельной операцией и не входит в текущий clean rebuild step.

Если carried primitive позже начнёт тянуть legacy responsibility, runtime adapter thinking, project-specific vocabulary или rejected workflow/execution semantics, он должен быть переписан, упрощён или удалён после отдельного ownership-аудита.

## Test fixture boundary decision

Test fixture допускается только как test-only средство для удаления повторяющегося технического setup в тестах.

Test fixture должен находиться только внутри `test/` и не должен попадать в `lib/`.

Test fixture не является production helper, wrapper, builder, factory, facade, bridge, locator, manager или magic utility shortcut.

Test fixture не должен определять domain behavior, application behavior, runtime behavior или registry mutation behavior.

Test fixture не должен скрывать проверяемый invariant.

Если тест проверяет constructor invariants конкретной domain model, constructor call должен оставаться явно видимым в тесте, а fixture может использоваться только для технических зависимостей этого constructor call.

Для `RegistryEntity` это означает:

- в application tests допустимо использовать готовый `RegistryEntity` fixture, если сам `RegistryEntity` не является предметом проверки;
- в `RegistryEntity` domain tests нельзя механически заменять `RegistryEntity(...)` на готовый entity fixture, если тест проверяет source evidence requirement, semantic contract compatibility, kind/schema compatibility или identity equality;
- в `RegistryEntity` domain tests допустимо вынести только повторяющийся setup: semantic contract, entity kind, payload test implementation и source evidence.

Если test fixture начинает содержать branching logic, скрытые scenario defaults, project-specific vocabulary, runtime lookup, service resolution или неочевидные invalid states, работу нужно остановить и заново провести boundary audit.


## Решение по границе `RegistryResolvedRelatedContext`

`RegistryRelatedContext` намеренно хранит не сами связанные `RegistryEntity`, а только их `RegistryEntityId`.

Такого результата достаточно, чтобы показать engineer/user наличие связанных registry мест. Но его недостаточно, чтобы честно оценивать неоднозначность, противоречия, полноту контекста или готовность проверяемого engineering context.

Следующая ответственность application-слоя называется `PrepareRegistryResolvedRelatedContext`.

Результат этой ответственности называется `RegistryResolvedRelatedContext`.

`RegistryResolvedRelatedContext` является результатом application-слоя только для чтения.

Он не является:

- доменной примитивой;
- результатом repository или store;
- graph;
- analyzer;
- finding;
- review context;
- presenter;
- view model;
- mutation command.

Назначение `RegistryResolvedRelatedContext` — показать engineer/user:

- какие связанные ids из `RegistryRelatedContext` уже представлены source-backed `RegistryEntity`;
- какие связанные ids пока не представлены entity и остаются отсутствующими в текущем контексте.

`RegistryResolvedRelatedContext` должен содержать:

- base `RegistryRelatedContext`;
- связанные `RegistryEntity`, уже переданные вызывающей стороной;
- связанные `RegistryEntityId`, для которых entity в текущем контексте отсутствует.

`RegistryResolvedRelatedContext` не должен сам искать, загружать или получать registry entities.

`RegistryResolvedRelatedContext` не должен принимать infrastructure, repository, store, runtime adapter или service resolution dependencies.

`PrepareRegistryResolvedRelatedContext` может принимать только:

- base `RegistryRelatedContext`;
- связанные `RegistryEntity`, уже доступные вызывающей стороне.

`PrepareRegistryResolvedRelatedContext` не должен:

- искать или загружать registry entities;
- выполнять graph traversal;
- выполнять drift analysis;
- создавать findings;
- принимать review decisions;
- принимать publication decisions;
- изменять registry.

Минимальные invariants `RegistryResolvedRelatedContext`:

- каждый resolved related entity должен иметь id, который присутствует в `base.relatedEntityIds`;
- resolved related entities не должны включать `base.primary`;
- отсутствующие related ids должны выводиться из `base.relatedEntityIds` после исключения ids переданных related entities;
- collections внутри результата должны быть immutable.

`RegistryResolvedRelatedContext` сам по себе не решает ambiguity, contradiction или drift. Он только подготавливает source-backed related facts для будущей context assessment responsibility, которая должна пройти отдельный ownership-аудит.

`RegistryHydratedRelatedContext` отклоняется как имя, потому что оно преждевременно тянет инфраструктурную семантику загрузки данных.

`RegistryVerifiedContext` отклоняется как имя, потому что оно слишком широкое и преждевременно заявляет готовый verified decision context.

`RegistryContextAssessment` откладывается, потому что assessment должен выполняться только после подготовки source-backed related facts.



## Решение по readiness после ownership-аудита

После `RegistryResolvedRelatedContext` Core уже может показать engineer/user:

- primary registry entity;
- связанные registry entities, которые уже доступны как source-backed `RegistryEntity`;
- связанные ids, для которых entity отсутствует в текущем context.

Повторный ownership-аудит показал, что отдельная model `RegistryContextReadiness` на текущем этапе не нужна.

Причина: текущая readiness полностью выводится из уже существующего `RegistryResolvedRelatedContext.missingRelatedEntityIds`.

Если `missingRelatedEntityIds` пустой, context готов к будущему assessment по критерию наличия source-backed related entities.

Если `missingRelatedEntityIds` не пустой, context не готов к будущему assessment по критерию наличия source-backed related entities.

Это не новая lifecycle, не новый owner и не новая boundary. Отдельный `RegistryContextReadiness` был бы convenience layer поверх уже существующего result, что запрещено Clean Rebuild Guard.

`RegistryResolvedRelatedContext` может нести этот derived state без превращения в analyzer или finding, потому что он не читает `RegistryEntityPayload`, не определяет ambiguity, contradiction или drift и не принимает semantic decisions.

На текущем этапе запрещено вводить:

- `RegistryContextReadiness` как отдельную model;
- `PrepareRegistryContextReadiness` как отдельный use case;
- `RegistryContextAssessmentIssue`;
- `RegistryVerifiedContext`.

Допустимым минимальным развитием `RegistryResolvedRelatedContext` может быть только явный derived getter для readiness, если он нужен коду:

- getter должен выводиться только из `missingRelatedEntityIds`;
- getter не должен читать payload;
- getter не должен создавать findings;
- getter не должен определять ambiguity, contradiction или drift;
- getter не должен утверждать достаточность context для semantic decision, canonicalization decision, change-scope decision или publication decision.

`RegistryContextAssessment` остаётся отложенным до отдельного ownership-аудита semantic assessment boundary.

## Решение по ownership semantic assessment boundary

После `RegistryResolvedRelatedContext` Core имеет source-backed related facts, но не имеет универсальной semantic model для чтения `RegistryEntityPayload`.

`RegistryEntityPayload` в Core остаётся только compatibility boundary:

- `semanticContract`;
- `entityKindId`;
- `payloadSchemaVersion`.

Core проверяет, что payload соответствует `RegistryEntityKind` и `RegistrySemanticContractIdentity`, но Core не интерпретирует содержимое payload.

Semantic assessment не является responsibility универсального Core.

Semantic assessment должен принадлежать contract-specific boundary, потому что только semantic contract знает, какие payload fields имеют смысл, какие комбинации считаются ambiguity, contradiction, drift или insufficient context.

Core не должен вводить generic `Analyzer`, `AssessmentService`, `SemanticResolver`, service catalog, runtime lookup или locator для contract-specific assessment.

Core не должен выбирать implementation assessment по `semanticContract` самостоятельно.

Core может в будущем принять уже подготовленный contract-specific assessment result как input, если этот result пройдёт отдельный ownership-аудит и не будет содержать mutation, publication decision или semantic decision вместо engineer/user.

Engineer/user остаётся владельцем:

- semantic decision;
- ambiguity resolution;
- canonicalization decision;
- approved change scope;
- publication control.

На текущем этапе запрещено вводить в Core:

- `RegistryContextAssessment`;
- `RegistryContextAssessmentIssue`;
- `RegistryDriftAnalyzer`;
- `RegistrySemanticAnalyzer`;
- `RegistryAssessmentService`;
- generic contract-specific resolver;
- service locator или registry catalog для assessment implementations.

Следующая допустимая работа перед semantic assessment — спроектировать contract-specific boundary отдельно от Core и доказать:

- кто владеет semantic interpretation;
- какие payload types она читает;
- где находится implementation;
- какой read-only result она может вернуть Core/Application;
- почему result не принимает decisions за engineer/user;
- почему это не mutation, не publication и не generic analyzer shortcut.

До такого ownership-аудита Core должен остановиться на `RegistryResolvedRelatedContext` и derived readiness из `missingRelatedEntityIds`.

## Решение по ownership Translator capability boundary

Translator является обязательной assistant capability для engineer и product add-on к Registry Studio.

Translator не является source of truth для Registry Studio Core и не является заменой registry domain model.

Текущий `lib/features/translator` принимается только как prototype evidence того, какая capability нужна engineer:

- multilingual translation;
- reverse-check;
- canonical wording audit;
- consistency check;
- translation drift signal;
- candidate canonical phrase preparation.

Текущий `lib/features/translator` не принимается как clean Registry Studio boundary as-is.

Причины:

- `RegistryNode` является source-format/tree-shaped model и не должен заменять `RegistryEntity`, `RegistryPath`, `RegistryRelation` или related context;
- `LoadRegistryTree` не является Registry Studio registry domain boundary;
- `loadCanonicalClientRules` фиксирует узкий client-rules workflow и не является универсальной registry dictionary boundary;
- `TranslatorRepository` смешивает translation capability и registry loading;
- data-layer prompts могут быть Helpy-specific и не должны попадать в Registry Studio Core;
- translator workflow не должен определять registry identity, registry structure или publication path.

Translator capability должна владеть:

- multilingual phrase processing;
- target language set;
- translation result;
- reverse-translation result;
- canonical wording consistency check;
- translation drift / needs-review signal;
- explanation of language differences;
- candidate canonical phrase output for engineer review.

Translator capability не должна владеть:

- `RegistryEntity` identity;
- `RegistryPath`;
- `RegistryRelation`;
- related context ownership;
- registry dictionary mutation;
- canonical phrase approval;
- semantic decision;
- ambiguity resolution;
- publication control;
- registry change scope.

Translator capability может получать input только как read-only engineering input:

- phrase or text selected by engineer;
- optional source evidence/provenance;
- optional read-only registry dictionary snapshot;
- optional target languages;
- optional engineer-provided context.

Translator capability не должна получать право самостоятельно искать registry, изменять registry или выбирать publication path.

Translator capability может возвращать engineer только read-only output:

- multilingual translation set;
- reverse-check result;
- canonical wording status;
- drift / needs-review signal;
- explanation/comment;
- candidate canonical phrase.

Candidate canonical phrase не является approved registry dictionary entry.

Добавление candidate phrase в registry dictionary допускается только через отдельный approved engineer decision path и будущий registry mutation use case.

Будущая clean implementation Translator capability должна находиться вне `Core`.

Допустимое направление для будущего кода должно пройти отдельный ownership-аудит и не может механически переносить `lib/features/translator` как готовую architecture.

До такого аудита запрещено:

- переносить `RegistryNode` в Registry Studio Core;
- делать translator repository частью Core;
- делать translator prompt source of truth для registry semantics;
- создавать generic translator manager/facade/helper;
- давать Translator право approval/mutation/publication;
- подменять registry dictionary domain model translator workflow.

## Решение по Translator dictionary change proposal flow

Translator capability имеет право инициировать command/proposal на исправление, замену или дополнение canonical wording в registry dictionary.

Это право не является правом mutation, approval или publication.

Translator dictionary command/proposal может выражать только intent:

- добавить candidate canonical phrase;
- исправить существующую canonical phrase;
- заменить рассинхронную формулировку;
- дополнить dictionary словом, фразой или формулировкой;
- указать suspected translation drift или canonical wording drift.

Translator command/proposal должен оставаться engineering input для Registry Studio audit flow.

Translator command/proposal не является approved dictionary entry и не может напрямую менять registry.

После такой command/proposal Registry Studio должна подготовить полный audit context до publication:

- найти все связанные registry места;
- проверить usage найденной фразы или формулировки;
- проверить related context;
- выявить unclear, ambiguous, contradictory или drift-prone места;
- показать engineer спорные места;
- подготовить verified audit package для решения engineer.

Engineer остаётся владельцем:

- выбора final canonical wording;
- исправления спорных мест;
- ambiguity resolution;
- approved change scope;
- dictionary approval;
- publication control.

Canonical phrase может быть опубликована в registry только после полного audit flow и через approved registry mutation/publication path.

До завершения полного audit flow запрещено:

- автоматически добавлять candidate phrase в registry dictionary;
- автоматически заменять все найденные формулировки;
- считать Translator verdict достаточным для publication;
- обходить related context audit;
- публиковать phrase только потому, что Translator нашёл Exact / Equivalent / Needs Review / Canonical Drift;
- давать Translator право direct registry mutation.

Предыдущее правило о read-only output уточняется так: Translator output read-only для registry, но может включать command/proposal, который запускает отдельный Registry Studio audit flow.

Это сохраняет границу:

- Translator обнаруживает и формулирует candidate correction;
- Registry Studio проверяет impact и drift risk;
- engineer принимает решение;
- publication выполняется только через approved use case.

## Решение по Translator capability placement

Future clean Translator capability должна жить внутри Registry Studio product boundary, но вне Registry Studio Core.

Approved placement:

- production: `lib/registry_studio/translator/...`;
- tests: `test/registry_studio/translator/...`.

Это placement означает:

- Translator является частью Registry Studio product extension;
- Translator не является частью `Core`;
- `Core` не должен импортировать Translator;
- Translator может зависеть от read-only Core contracts только inward-направлением;
- Translator не должен менять Core contracts ради собственного workflow.

Запрещённые placements:

- `lib/registry_studio/core/translator/...`;
- `lib/registry_studio/core/application/translator/...`;
- `lib/registry_studio/core/domain/translator/...`;
- `lib/features/translator/...` как clean Registry Studio architecture;
- `lib/core/persistence/...` как Registry Studio boundary;
- generic `lib/registry_studio/capabilities/...` до отдельного taxonomy ownership-аудита.

Причины:

- `lib/registry_studio/core` должен оставаться universal product-neutral registry core;
- old `lib/features/translator` связан с prototype workflow, app-level persistence, source-format registry tree и Helpy-specific prompts;
- generic `capabilities` placement может преждевременно создать capability catalog / manager / locator pressure;
- Translator сейчас является конкретной assistant capability, а не generic plugin system.

Допустимая future dependency direction:

- `registry_studio/translator` may import read-only `registry_studio/core` contracts;
- `registry_studio/core` must never import `registry_studio/translator`;
- publication/mutation path must not be owned by Translator;
- proposal from Translator must enter Registry Studio audit flow through approved application boundary.

Первый future implementation step в `lib/registry_studio/translator` должен вводить только одну small boundary с одной responsibility.

Недопустимо первым шагом создавать:

- translator repository;
- translator manager;
- translator facade;
- generic capability registry;
- plugin catalog;
- prompt-driven source of truth;
- registry dictionary mutation use case;
- publication use case;
- RegistryNode replacement inside Registry Studio.

Правильный первый code direction после отдельного code ownership-аудита:

- определить read-only Translator proposal/result boundary;
- без registry mutation;
- без publication;
- без old `RegistryNode`;
- без переноса `lib/features/translator`;
- без изменения Registry Studio Core.

## Решение по existing-fit audit перед operation boundary

Перед созданием новой operation model выполнен existing-fit audit текущих Registry Studio Core сущностей, application results/use cases и существующего Translator prototype.

Проверенные Registry Studio candidates:

- `RegistryEntity`;
- `RegistryRelation`;
- `RegistryRelatedContext`;
- `RegistryResolvedRelatedContext`;
- `PrepareRegistryRelatedContext`;
- `PrepareRegistryResolvedRelatedContext`.

Проверенные Translator candidates:

- `CanonicalAuditResult`;
- `TranslationResult`;
- `AuditCanonicalClientRules`;
- `TranslateCanonicalPhrase`;
- `LoadCanonicalClientRules`;
- `LoadRegistryTree`;
- `TranslatorState`;
- `TranslatorCubit`;
- `TranslatorRepository`;
- `RegistryNode`;
- Translator remote prompts/data sources;
- Translator persistence records.

`RegistryEntity` не может владеть engineering operation lifecycle.

Причина: `RegistryEntity` является typed source-backed registry unit со stable identity. Добавление operation lifecycle, proposal state, audit package или engineer decision flow внутрь `RegistryEntity` нарушит identity, responsibility isolation и запрет entity знать workflow других entities.

`RegistryRelation` не может владеть operation/proposal/audit lifecycle.

Причина: `RegistryRelation` является atomic directional relation fact между registry entities. Она не имеет самостоятельного lifecycle, review state, publication state или mutation flow. Добавление operation state превратит relation в workflow container.

`RegistryRelatedContext` не может владеть operation lifecycle.

Причина: `RegistryRelatedContext` является read-only application result, который показывает primary entity, matched relations и related ids. Он не должен выполнять drift detection, semantic analysis, review decision, publication decision или mutation.

`RegistryResolvedRelatedContext` не может владеть operation lifecycle.

Причина: `RegistryResolvedRelatedContext` является read-only application result, который показывает resolved related entities и missing related ids. Он не решает ambiguity, contradiction или drift и не должен становиться review context, finding container или mutation command.

`PrepareRegistryRelatedContext` и `PrepareRegistryResolvedRelatedContext` не могут владеть workflow state.

Причина: это stateless application use cases для подготовки context. Они не должны хранить operation lifecycle, proposal state, audit status, engineer decision state или publication state.

`CanonicalAuditResult` не может владеть Registry Studio operation lifecycle.

Причина: это result проверки одной canonical phrase / translation set. Он не имеет operation identity, operation lifecycle, related context, impact scope, engineer decision state или publication boundary.

`TranslationResult` не может владеть Registry Studio operation lifecycle.

Причина: это multilingual translation / reverse-check output. Он может быть read-only language-quality evidence, но не является registry operation, audit flow или verified engineering package.

`AuditCanonicalClientRules` не может владеть полным Registry Studio audit flow.

Причина: этот use case фиксирует узкий batch workflow: загрузить canonical client rules, перевести каждую phrase и вернуть `CanonicalAuditResult`. Он не ищет все related registry places, не проверяет impact scope, не готовит verified audit package и не ведёт engineer decision path.

`TranslateCanonicalPhrase`, `LoadCanonicalClientRules` и `LoadRegistryTree` не могут владеть operation lifecycle.

Причина: это narrow use cases Translator prototype. Они выполняют отдельные действия и не имеют owner/lifecycle для Registry Studio operation.

`TranslatorState` и `TranslatorCubit` не могут владеть verified audit package lifecycle.

Причина: это presentation/app state для loading, progress, registry tree view, persistence и UI interaction. Presentation state не является Registry Studio domain/application operation boundary.

`TranslatorRepository` не может владеть Registry Studio operation boundary.

Причина: он смешивает translation capability и registry loading. Такой repository уже отклонён как clean Registry Studio boundary и не должен определять registry identity, structure, context, mutation или publication path.

`RegistryNode` не может быть reused как Registry Studio operation/context model.

Причина: `RegistryNode` является source-format/tree-shaped model: heading level, line number, phrases, children. Он не заменяет `RegistryEntity`, `RegistryPath`, `RegistryRelation`, related context или operation lifecycle.

Translator remote prompts/data sources не могут владеть Registry Studio operation lifecycle.

Причина: prompts могут быть Helpy-specific, data source грузит Markdown/GitHub registry text, а prompt-driven output не может быть source of truth для registry semantics, audit flow, mutation или publication.

Translator persistence records не могут владеть Registry Studio operation lifecycle.

Причина: persistence хранит UI/app history/status index и не определяет domain/application operation identity, lifecycle, invariants или engineer decision path.

Valid reuse из существующего Translator prototype:

- capability evidence для multilingual translation;
- capability evidence для reverse-check;
- capability evidence для canonical wording status;
- capability evidence для drift / needs-review signal;
- capability evidence для candidate canonical phrase;
- future read-only Translator proposal/result input после clean boundary.

Invalid reuse:

- reuse `lib/features/translator` как Registry Studio architecture;
- reuse `RegistryNode` как registry context;
- reuse `TranslatorRepository` как operation boundary;
- reuse `TranslatorCubit` / `TranslatorState` как operation lifecycle;
- reuse prompts as source of truth;
- reuse `AuditCanonicalClientRules` as full Registry Studio audit flow.

Вывод existing-fit audit:

- текущие Registry Studio сущности закрывают source-backed identity, relation facts, related context и resolved related context;
- существующий Translator prototype закрывает только language-quality signal и candidate proposal evidence;
- ни один существующий candidate не может корректно нести responsibility operation lifecycle / verified audit package flow без нарушения identity, lifecycle, owner или boundary;
- новая operation boundary допустима только после отдельного ownership-аудита;
- эта boundary не должна подменять Orchestrator, Translator, assessment, mutation или publication.

## Решение по RegistryEngineeringOperation ownership boundary

После existing-fit audit новая operation boundary допускается.

Новая central lifecycle responsibility называется `RegistryEngineeringOperation`.

`RegistryEngineeringOperation` означает одну конкретную engineering-задачу Registry Studio: проверить problem / drift / proposal / unclear context, собрать verified audit package и довести задачу до точки, где engineer может принять решение.

`RegistryEngineeringOperation` является lifecycle entity Registry Studio.

`RegistryEngineeringOperation` не является:

- Orchestrator;
- workflow executor;
- runtime step runner;
- manager;
- facade;
- helper;
- service locator;
- assessment service;
- finding catalog;
- mutation use case;
- publication use case;
- Translator result;
- presentation state.

Identity `RegistryEngineeringOperation` должна быть собственной stable identity.

Правильное направление identity:

- `RegistryEngineeringOperationId`.

Identity не должна выводиться из:

- primary `RegistryEntityId`;
- `RegistryPath`;
- `SourceEvidence`;
- source line;
- Translator proposal;
- detected drift hash;
- operation title;
- current lifecycle state.

Причины:

- одна registry entity может иметь несколько независимых operations;
- один detected signal может быть split/merged engineer decision;
- Translator proposal может быть input, но не owner identity;
- source coordinates могут измениться при document edit и не являются domain identity.

Owner lifecycle:

- operation lifecycle принадлежит Registry Studio operation boundary;
- engineer owns decisions;
- Orchestrator coordinates allowed capabilities and use case boundaries only;
- Translator supplies read-only proposal/input only;
- assessment supplies read-only contract-specific result only;
- mutation/publication remains separate approved use case path.

`RegistryEngineeringOperation` может содержать или ссылаться на read-only inputs:

- engineer-created issue / problem statement;
- detected drift/desync signal;
- Translator dictionary command/proposal;
- primary `RegistryEntity`;
- `RegistryRelatedContext`;
- `RegistryResolvedRelatedContext`;
- future contract-specific assessment result after its own ownership audit.

Allowed output:

- read-only operation snapshot;
- current operation lifecycle state;
- context readiness facts;
- missing related context facts;
- attached input/proposal facts;
- verified audit package readiness for engineer decision.

Forbidden output:

- registry mutation command;
- publication decision;
- semantic decision;
- canonicalization decision;
- ambiguity resolution;
- approved change scope;
- direct payload interpretation outside explicit contract-specific boundary.

Lifecycle states must describe the operation itself, not derived context facts.

Allowed lifecycle direction:

- created / opened;
- collecting context;
- awaiting required context;
- ready for engineer decision;
- decided by engineer;
- closed / cancelled.

Derived facts are not lifecycle states:

- `missingRelatedEntityIds` empty or non-empty;
- related context exists or does not exist;
- resolved related entities exist or do not exist;
- Translator proposal attached or absent;
- assessment result attached or absent;
- audit package complete or incomplete.

Those facts may affect readiness, but they do not replace operation lifecycle identity or lifecycle.

`RegistryEngineeringOperation` must not perform work directly.

It may not:

- search registry;
- load registry entities;
- run graph traversal;
- call Translator;
- call assessment;
- resolve services;
- mutate registry;
- publish registry.

Work must happen through approved application use cases, and operation may only capture resulting read-only facts/state after those use cases complete.

Placement direction for future code:

- production: `lib/registry_studio/core/domain/entities/registry_engineering_operation.dart`;
- operation id value object: `lib/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart`;
- tests: `test/registry_studio/core/domain/registry_engineering_operation_test.dart`.

This placement is allowed only because the operation boundary is product-neutral Registry Studio domain lifecycle, not project-specific workflow, not Translator implementation, not assessment implementation and not publication path.

First future code step must be minimal:

- introduce `RegistryEngineeringOperationId`;
- introduce `RegistryEngineeringOperation` with identity and minimal lifecycle invariants;
- no Orchestrator;
- no workflow executor;
- no Translator import;
- no assessment import;
- no mutation/publication use case;
- no repository/store;
- no service catalog.

Before production code, lifecycle state naming and minimal invariants must be checked in a separate code ownership step.

## Решение по RegistryEngineeringOperation lifecycle status и minimal invariants

Для lifecycle marker используется имя `RegistryEngineeringOperationStatus`.

`RegistryEngineeringOperationState` отклоняется.

Причина: `State` слишком широкое имя и может смешать lifecycle marker, UI state, workflow execution state, readiness facts, attached inputs и presentation state. Для первой domain entity нужен только lifecycle marker.

`RegistryEngineeringOperationStatus` означает только lifecycle status самой operation.

Первый approved status set:

- `open`;
- `awaitingContext`;
- `readyForDecision`;
- `decided`;
- `cancelled`.

Meaning:

- `open` — operation создана и активна;
- `awaitingContext` — operation ожидает обязательный read-only context/input;
- `readyForDecision` — operation готова к решению engineer;
- `decided` — engineer уже принял решение вне operation;
- `cancelled` — operation остановлена без движения к mutation/publication.

`collectingContext` не входит в первый status set.

Причина: collecting context описывает application process / use case activity. Если сделать его lifecycle status, появится pressure превратить operation в workflow executor.

`closed` не входит в первый status set.

Причина: `closed` слишком общее состояние и скрывает важное различие между `decided` и `cancelled`. Для первого lifecycle marker terminal statuses должны быть явными.

Derived readiness facts не являются statuses:

- наличие или отсутствие `RegistryRelatedContext`;
- наличие или отсутствие `RegistryResolvedRelatedContext`;
- empty/non-empty `missingRelatedEntityIds`;
- attached/absent Translator proposal;
- attached/absent assessment result;
- audit package complete/incomplete.

Эти facts могут использоваться application use cases для выбора next status, но `RegistryEngineeringOperation` не должна вычислять их сама.

Минимальные fields для первого production code:

- `RegistryEngineeringOperationId id`;
- `RegistryEngineeringOperationStatus status`;
- normalized non-empty `problemStatement`.

`problemStatement` является product-neutral description of engineering problem/intent. Он не является semantic decision, canonical wording approval или change scope.

Первый production code не должен включать:

- primary `RegistryEntity`;
- `RegistryRelatedContext`;
- `RegistryResolvedRelatedContext`;
- Translator proposal;
- assessment result;
- verified audit package object;
- decision result;
- approved change scope;
- mutation command;
- publication command;
- transition methods;
- repository/store;
- Orchestrator;
- workflow executor;
- service catalog.

Причины исключения primary `RegistryEntity` из первого code step:

- не каждая operation стартует от known primary entity;
- Translator proposal может создать engineering intent до выбора конкретного registry place;
- detected drift signal может требовать поиска related places до выбора primary;
- optional primary entity в первом step превратит entity в частичный context container;
- attachment primary/context должен пройти отдельный application/use case boundary.

Минимальные invariants первого production code:

- `RegistryEngineeringOperationId` trims value and rejects empty identity;
- `RegistryEngineeringOperation.problemStatement` trims value and rejects empty problem statement;
- `RegistryEngineeringOperation` equality is based only on `id`;
- `status` is required;
- entity is immutable;
- entity does not import Translator;
- entity does not import assessment;
- entity does not import application related context;
- entity does not call any use case.

Transition rules не входят в первый code step.

Причина: transition methods требуют отдельного audit: allowed transitions, terminal statuses, decision evidence, cancellation reason и application use case ownership. Если добавить transitions сразу, operation начнёт расти в workflow executor.

Approved first code files:

- `lib/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart`;
- `lib/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart`;
- `lib/registry_studio/core/domain/entities/registry_engineering_operation.dart`;
- `test/registry_studio/core/domain/registry_engineering_operation_test.dart`.

Первый test scope:

- id trims and rejects empty;
- operation trims and rejects empty problem statement;
- operation preserves required status;
- equality uses stable id only;
- operation does not require primary entity or related context.
