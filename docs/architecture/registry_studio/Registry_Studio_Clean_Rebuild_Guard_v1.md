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

### Отклонено как архитектурный источник истины

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

## Заметка по границе Translator

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

## Решение по ownership RegistryRelation

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

## Решение по прикладной границе related context

В текущем `lib/registry_studio` нет готового application/use case boundary для подготовки связанных registry мест.

Первая read-only application responsibility после `RegistryRelation` называется `PrepareRegistryRelatedContext`.

`PrepareRegistryRelatedContext` должен готовить related context для engineer/user на основе `RegistryEntity` и `Iterable<RegistryRelation>`.

Эта responsibility существует для того, чтобы engineer/user мог увидеть связанные registry места до drift analysis.

`PrepareRegistryRelatedContext` не является drift detector, analyzer, finding builder, graph traversal engine, presenter, UI projection, change plan, publication instruction или mutation command.

`PrepareRegistryRelatedContext` не должен принимать semantic decisions и не должен изменять registry.

`RegistryRelatedContext` не принимается как первичный domain primitive. Он может появиться только как explicit read-only application result после отдельного ownership-аудита result shape.

До появления result-specific invariants application boundary может быть зафиксирован без создания graph/container/domain wrapper.

## Решение по форме результата PrepareRegistryRelatedContext

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

## Решение по provenance текущих Core primitives

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

## Решение по границе test fixture

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

Допустимое переиспользование из существующего Translator prototype:

- capability evidence для multilingual translation;
- capability evidence для reverse-check;
- capability evidence для canonical wording status;
- capability evidence для drift / needs-review signal;
- capability evidence для candidate canonical phrase;
- future read-only Translator proposal/result input после clean boundary.

Недопустимое переиспользование:

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

Владение жизненным циклом:

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

Разрешённый результат:

- read-only operation snapshot;
- current operation lifecycle state;
- context readiness facts;
- missing related context facts;
- attached input/proposal facts;
- verified audit package readiness for engineer decision.

Запрещённый результат:

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

Направление размещения будущего кода:

- production: `lib/registry_studio/core/domain/entities/registry_engineering_operation.dart`;
- operation id value object: `lib/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart`;
- tests: `test/registry_studio/core/domain/registry_engineering_operation_test.dart`.

This placement is allowed only because the operation boundary is product-neutral Registry Studio domain lifecycle, not project-specific workflow, not Translator implementation, not assessment implementation and not publication path.

Первый будущий code-step должен быть минимальным:

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

Значение:

- `open` — operation создана и активна;
- `awaitingContext` — operation ожидает обязательный read-only context/input;
- `readyForDecision` — operation готова к решению engineer;
- `decided` — engineer принял решение, а его human-facing текст зафиксирован в operation;
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
- normalized non-empty `problemStatement`;
- optional normalized non-empty `decisionStatement`, обязательный только для `decided`.

`problemStatement` является product-neutral description of engineering problem/intent. Он не является semantic decision, canonical wording approval или change scope.

`decisionStatement` является human-facing текстом решения engineer. Он не является registry mutation command, publication instruction, approved change scope или автоматическим решением программы.

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

Утверждённые файлы первого code-step:

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

## Решение по правилам переходов статуса RegistryEngineeringOperation

`RegistryEngineeringOperation` хранит текущий статус жизненного цикла, но не должна становиться `workflow executor`.

Правила переходов являются invariant границы operation, но само выполнение смены статуса должно принадлежать будущему прикладному сценарию.

`RegistryEngineeringOperation` не должна в ближайшем code-step получать методы:

- `markAwaitingContext`;
- `markReadyForDecision`;
- `markDecided`;
- `cancel`;
- generic `changeStatus`;
- generic `copyWith`.

Причины:

- такие методы быстро создают pressure превратить entity в `workflow executor`;
- смена статуса зависит от прикладных facts: available context, missing context, engineer action, future decision record, cancellation reason;
- сама entity не должна искать context, читать assessment, вызывать Translator или принимать решение engineer.

Правильное направление:

- operation entity остаётся неизменяемым снимком;
- будущий прикладной сценарий проверяет запрошенный переход;
- будущий прикладной сценарий создаёт новый неизменяемый `RegistryEngineeringOperation` snapshot со следующим статусом;
- проверка перехода должна использовать явную матрицу разрешённых переходов;
- repository/store не вводятся до отдельного persistence ownership-аудита.

Разрешённые переходы статуса:

- `open` -> `awaitingContext`;
- `open` -> `readyForDecision`;
- `open` -> `cancelled`;
- `awaitingContext` -> `readyForDecision`;
- `awaitingContext` -> `cancelled`;
- `readyForDecision` -> `awaitingContext`;
- `readyForDecision` -> `decided`;
- `readyForDecision` -> `cancelled`.

`readyForDecision` -> `awaitingContext` разрешён только до решения engineer.

Причина: если новый обязательный context обнаружен до решения, operation больше не готова к решению, но остаётся той же engineering problem. Создание новой operation раздробило бы audit trail.

Терминальные статусы:

- `decided`;
- `cancelled`.

Запрещённые переходы из терминальных статусов:

- `decided` -> `open`;
- `decided` -> `awaitingContext`;
- `decided` -> `readyForDecision`;
- `decided` -> `cancelled`;
- `cancelled` -> `open`;
- `cancelled` -> `awaitingContext`;
- `cancelled` -> `readyForDecision`;
- `cancelled` -> `decided`.

Другие запрещённые переходы:

- `awaitingContext` -> `open`;
- `readyForDecision` -> `open`;
- `open` -> `decided`.

`open` -> `decided` запрещён, потому что решение engineer должно проходить через явный статус готовности. Если context сразу достаточен, правильный путь: `open` -> `readyForDecision` -> `decided`.

Cancellation reason пока не входит в `RegistryEngineeringOperation` entity.

Decision evidence пока не входит в `RegistryEngineeringOperation` entity.

Human-facing `decisionStatement` не является decision evidence package и не требует отдельной entity, пока у решения нет собственной identity, автора, времени, evidence, нескольких версий или supersession policy.

Причины:

- cancellation reason требует отдельного ownership-аудита: value object, required/optional policy, owner и persistence boundary;
- decision evidence требует отдельного ownership-аудита: engineer decision record, audit package, approved change scope и publication boundary;
- эти responsibilities остаются вне текущей operation lifecycle entity.

Смена статуса operation не означает registry mutation.

Смена статуса operation не означает publication.

`decided` означает, что engineer принял решение и его нормализованный human-facing текст сохранён в operation lifecycle entity. Это не означает, что registry был изменён, утверждён к mutation или опубликован.

Следующий безопасный шаг после этого docs-решения:

- не добавлять transition methods внутрь `RegistryEngineeringOperation`;
- спроектировать будущую прикладную границу для смены operation status;
- перед кодом доказать её owner, inputs, outputs и invariants;
- в первом шаге сохранить её repository-free, store-free, Translator-free, assessment-free и publication-free.

## Решение по existing-fit audit перед прикладной границей смены статуса

Перед созданием прикладной границы для изменения `RegistryEngineeringOperationStatus` выполнен existing-fit audit текущих Registry Studio Core сущностей, value objects, application results и use cases.

Проверенные candidates:

- `RegistryEngineeringOperation`;
- `RegistryEngineeringOperationStatus`;
- `RegistryEngineeringOperationId`;
- `RegistryEntity`;
- `RegistryRelation`;
- `SourceEvidence`;
- `RegistryRelatedContext`;
- `RegistryResolvedRelatedContext`;
- `PrepareRegistryRelatedContext`;
- `PrepareRegistryResolvedRelatedContext`;
- Orchestrator boundary;
- Translator capability.

`RegistryEngineeringOperation` не может владеть transition execution.

Причина: operation entity уже определена как неизменяемый lifecycle snapshot. Если добавить в неё `markAwaitingContext`, `markReadyForDecision`, `markDecided`, `cancel`, generic `changeStatus` или `copyWith`, entity начнёт принимать workflow responsibility и получит pressure стать `workflow executor`.

`RegistryEngineeringOperationStatus` не может владеть матрицей переходов как behavior owner.

Причина: status enum является lifecycle marker. Если enum начнёт принимать transition decisions, он станет policy object и начнёт смешивать marker, lifecycle policy, application facts и future decision/cancellation rules.

`RegistryEngineeringOperationId` не может владеть transition responsibility.

Причина: operation id является только stable identity. Identity не должна знать lifecycle direction, readiness, engineer decision или cancellation.

`RegistryEntity` не может владеть operation status transition.

Причина: registry entity является typed source-backed registry unit. Она не должна знать engineering operation lifecycle, audit status или engineer decision path.

`RegistryRelation` не может владеть operation status transition.

Причина: relation является atomic directional relation fact. Она не является operation, workflow state, readiness policy или audit boundary.

`SourceEvidence` не может владеть operation status transition.

Причина: source evidence фиксирует provenance и source coordinates. Оно не является lifecycle owner.

`RegistryRelatedContext` и `RegistryResolvedRelatedContext` не могут владеть operation status transition.

Причина: это read-only application results. Они могут быть inputs/facts для future use case, но не должны менять operation status, вычислять readiness policy или принимать engineer decision.

`PrepareRegistryRelatedContext` и `PrepareRegistryResolvedRelatedContext` не могут владеть operation status transition.

Причина: это stateless application use cases для подготовки related context. Они не должны расширяться до operation lifecycle transition use cases.

Orchestrator не может владеть operation status transition.

Причина: Orchestrator допустим только как узкая coordination boundary. Он не должен выполнять workflow steps, держать transition matrix или принимать lifecycle decisions.

Translator capability не может владеть operation status transition.

Причина: Translator supplies read-only language proposal/input only. Он не является owner registry operation lifecycle, readiness, decision, mutation или publication.

Вывод:

- ни один существующий candidate не может корректно нести status-change responsibility без нарушения identity, lifecycle, owner или boundary;
- отдельная application boundary для status transition допустима;
- эта boundary должна быть operation-status specific;
- эта boundary не должна быть repository, store, manager, facade, helper, Orchestrator, Translator adapter, assessment runner, mutation use case или publication use case.

Направление будущей прикладной границы:

- имя first candidate: `TransitionRegistryEngineeringOperationStatus`;
- слой: `lib/registry_studio/core/application/operation_status/`;
- вход: current `RegistryEngineeringOperation`;
- вход: requested next `RegistryEngineeringOperationStatus`;
- выход: new immutable `RegistryEngineeringOperation` snapshot;
- invalid transition: `ArgumentError`;
- transition matrix: explicit внутри этой первой application boundary;
- отдельный transition matrix value object сейчас не создаётся.

Причина не выделять сейчас отдельный value object для матрицы переходов:

- у transition rules сейчас один consumer;
- отдельный object был бы premature modeling;
- если transition policy начнёт переиспользоваться несколькими application boundaries, extracted policy/value object должен пройти отдельный ownership-аудит.

Первый code-step для смены статуса не должен включать:

- repository/store;
- persistence;
- Orchestrator;
- Translator;
- assessment;
- related context inspection;
- readiness computation;
- cancellation reason;
- decision evidence;
- registry mutation;
- publication.

Первый test scope для будущего кода:

- разрешённые переходы возвращают новый неизменяемый operation snapshot;
- исходная operation остаётся неизменной;
- запрещённые переходы выбрасывают `ArgumentError`;
- терминальные статусы отклоняют все исходящие переходы;
- `open` -> `decided` отклоняется;
- use case не требует related context, Translator proposal, assessment result, repository или store.

## Контрольная точка реализации: прикладной сценарий перехода статуса operation

Первый status-change application boundary реализован.

Коммит:

- `8adaa71 feat: add registry operation status transition use case`.

Реализованный production-файл:

- `lib/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart`.

Реализованный test-файл:

- `test/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status_test.dart`.

Реализованная boundary:

- `TransitionRegistryEngineeringOperationStatus`.

Ответственность:

- принимает current `RegistryEngineeringOperation`;
- принимает requested next `RegistryEngineeringOperationStatus`;
- проверяет explicit allowed transition matrix;
- возвращает new immutable `RegistryEngineeringOperation` snapshot;
- отклоняет invalid transitions через `ArgumentError`.

Подтверждённые исключения:

- no repository/store;
- no persistence;
- no Orchestrator;
- no Translator;
- no assessment;
- no related context inspection;
- no readiness computation;
- no cancellation reason;
- no decision evidence;
- no registry mutation;
- no publication.

Проверки перед коммитом:

- strict forbidden production import check passed;
- pure Dart status transition smoke check passed;
- `flutter analyze` passed;
- staged diff check passed.

Известное ограничение окружения:

- `flutter test` не используется как final local proof в Termux, потому что локальный `flutter_tester` падает из-за missing `libvk_swiftshader.so`;
- domain/application runtime behavior проверялся временными pure Dart smoke checks.

## Решение по creation boundary RegistryEngineeringOperation

Перед созданием `CreateRegistryEngineeringOperation` выполнен existing-fit audit текущих candidates.

`RegistryEngineeringOperation` factory не является creation application boundary.

Причина: factory принадлежит domain entity и отвечает только за invariants entity: required id, required status, normalized non-empty `problemStatement` и immutable snapshot. Она не должна становиться application use case, workflow boundary или owner creation policy.

`RegistryEngineeringOperationId` не может владеть созданием operation.

Причина: id value object нормализует и валидирует уже переданную identity. Он не должен генерировать id, знать uuid policy, platform policy, repository policy или persistence boundary.

`RegistryEngineeringOperationStatus` не может владеть созданием operation.

Причина: status enum является lifecycle marker. Он не должен определять initial status policy или создавать operation.

`TransitionRegistryEngineeringOperationStatus` не может владеть созданием operation.

Причина: этот use case уже имеет отдельную responsibility: проверить status transition matrix и вернуть новый immutable operation snapshot. Добавление creation responsibility смешает creation и lifecycle transition.

`RegistryEntity`, `RegistryRelation`, `SourceEvidence`, `RegistryRelatedContext`, `RegistryResolvedRelatedContext`, `PrepareRegistryRelatedContext` и `PrepareRegistryResolvedRelatedContext` не могут владеть созданием operation.

Причина: эти модели и use cases закрывают registry identity, relation facts, provenance и related context. Они не являются owner operation creation, operation id, initial status или problem statement.

Orchestrator не может владеть созданием operation.

Причина: Orchestrator допускается только как узкая coordination boundary. Он не должен выполнять workflow steps, создавать operation, генерировать id или принимать lifecycle policy.

Translator capability не может владеть созданием operation.

Причина: Translator может быть read-only input/proposal source, но не является owner Registry Studio operation lifecycle или creation policy.

Вывод:

- ни один существующий candidate не может корректно нести creation responsibility без нарушения boundary;
- отдельный application use case `CreateRegistryEngineeringOperation` допустим;
- первый creation use case должен быть минимальным и не должен вводить persistence, id generation или status policy beyond initial `open`.

Утверждённая прикладная граница:

- имя: `CreateRegistryEngineeringOperation`;
- слой: `lib/registry_studio/core/application/operation_creation/`;
- production file: `lib/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart`;
- test file: `test/registry_studio/core/application/operation_creation/create_registry_engineering_operation_test.dart`.

Входы первого use case:

- `RegistryEngineeringOperationId id`;
- `String problemStatement`.

Выход первого use case:

- `RegistryEngineeringOperation`.

Initial status policy:

- created operation всегда получает `RegistryEngineeringOperationStatus.open`.

Причина:

- creation создаёт новую активную operation;
- `awaitingContext`, `readyForDecision`, `decided` и `cancelled` должны достигаться через отдельный status transition boundary;
- status parameter в creation use case смешал бы creation и lifecycle transition.

Первый creation use case не должен принимать:

- status parameter;
- primary `RegistryEntity`;
- `RegistryRelatedContext`;
- `RegistryResolvedRelatedContext`;
- Translator proposal;
- assessment result;
- decision evidence;
- cancellation reason;
- repository/store;
- id generator;
- uuid service;
- Orchestrator;
- mutation command;
- publication command.

Id generation не вводится в первом step.

Причина:

- id generation policy может зависеть от platform/runtime/persistence;
- текущий clean boundary может оставаться repository-free, store-free, uuid-free и platform-free;
- caller передаёт уже готовый `RegistryEngineeringOperationId`;
- если id generation понадобится позже, она должна пройти отдельный ownership-аудит.

Result object не вводится в первом step.

Причина:

- output содержит только одну operation;
- нет partial success, warnings, attached facts или diagnostics;
- отдельный result object сейчас был бы premature modeling.

Первый test scope:

- use case creates `RegistryEngineeringOperation`;
- created operation preserves provided id;
- created operation trims and preserves problem statement через domain entity invariant;
- created operation always starts with `open`;
- use case does not accept status;
- use case does not require context, Translator, assessment, repository, store, uuid or Orchestrator.

## Контрольная точка реализации: прикладной сценарий создания operation

Первый прикладной сценарий создания `RegistryEngineeringOperation` реализован.

Коммит:

- `e2b91b6 feat: add registry operation creation use case`.

Реализованный production-файл:

- `lib/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart`.

Реализованный test-файл:

- `test/registry_studio/core/application/operation_creation/create_registry_engineering_operation_test.dart`.

Реализованная boundary:

- `CreateRegistryEngineeringOperation`.

Ответственность:

- принимает готовый `RegistryEngineeringOperationId`;
- принимает `String problemStatement`;
- создаёт `RegistryEngineeringOperation`;
- всегда устанавливает initial status `RegistryEngineeringOperationStatus.open`;
- передаёт normalization и validation problem statement в domain entity invariant.

Подтверждённые исключения:

- no status parameter;
- no id generator;
- no uuid service;
- no repository/store;
- no persistence;
- no Orchestrator;
- no Translator;
- no assessment;
- no related context inspection;
- no readiness computation;
- no decision evidence;
- no cancellation reason;
- no registry mutation;
- no publication.

Проверки перед коммитом:

- strict forbidden production import check passed;
- status parameter check passed;
- pure Dart operation creation smoke check passed;
- `flutter analyze` passed;
- staged diff check passed.

Известное ограничение окружения:

- `flutter test` не используется как final local proof в Termux, потому что локальный `flutter_tester` падает из-за missing `libvk_swiftshader.so`;
- domain/application runtime behavior проверялся временными pure Dart smoke checks.

Аудит после реализации:

- `CreateRegistryEngineeringOperation` и `TransitionRegistryEngineeringOperationStatus` остаются двумя отдельными атомарными boundaries;
- composite use case `create + transition` не вводится;
- lifecycle Orchestrator не вводится;
- id generation не вводится;
- repository/store не вводятся;
- readiness computation не смешивается с creation или transition.

## Решение по operation attachment boundary

После реализации `CreateRegistryEngineeringOperation` и `TransitionRegistryEngineeringOperationStatus` выполнен audit возможной attachment boundary для operation inputs.

Проверенные candidates:

- primary `RegistryEntity`;
- `RegistryRelatedContext`;
- `RegistryResolvedRelatedContext`;
- Translator proposal;
- assessment result;
- future verified audit package;
- separate operation context/result.

`RegistryEngineeringOperation` не должна прямо хранить primary `RegistryEntity`.

Причина: operation entity уже определена как lifecycle snapshot. Добавление primary entity превратит её в context container и смешает lifecycle identity с application context.

`RegistryEngineeringOperation` не должна прямо хранить `RegistryRelatedContext`.

Причина: `RegistryRelatedContext` является read-only application result для related facts вокруг primary entity. Если поместить его внутрь operation, operation начнёт владеть context assembly result, хотя сама не должна искать, собирать или оценивать context.

`RegistryEngineeringOperation` не должна прямо хранить `RegistryResolvedRelatedContext`.

Причина: `RegistryResolvedRelatedContext` является read-only application result для resolved/missing related entities. Он может быть input/fact для будущего audit flow, но не должен превращать operation entity в audit package.

Translator proposal не прикрепляется к operation entity в текущем step.

Причина: Translator proposal должен пройти отдельный ownership-аудит как read-only engineering input. Он не является owner operation lifecycle, semantic decision, registry mutation или publication.

Assessment result не прикрепляется к operation entity в текущем step.

Причина: assessment result ещё не имеет утверждённой Core boundary. До отдельного ownership-аудита Core не должен создавать generic assessment attachment.

Verified audit package не создаётся в текущем step.

Причина: audit package может объединять operation, related context, resolved context, Translator proposal, assessment facts, readiness и future decision evidence. Такой объект имеет высокий риск стать workflow container, mini-orchestrator или premature modeling.

Separate operation context/result не вводится в текущем step.

Причина:

- текущий код уже имеет атомарные boundaries для creation, status transition, related context и resolved related context;
- нет отдельного consumer, которому прямо нужен `operation + attached context` result;
- readiness может быть derived from `RegistryResolvedRelatedContext.missingRelatedEntityIds` без изменения operation;
- создание operation context сейчас преждевременно соберёт несколько responsibilities в один container.

Текущая approved composition остаётся внешней и явной:

- `CreateRegistryEngineeringOperation`;
- `PrepareRegistryRelatedContext`;
- `PrepareRegistryResolvedRelatedContext`;
- `TransitionRegistryEngineeringOperationStatus`.

Эта composition не оформляется как composite use case, pipeline, Orchestrator, manager, facade или workflow runner.

Запрещено в текущем step:

- добавлять primary/context/proposal fields в `RegistryEngineeringOperation`;
- создавать `RegistryEngineeringOperationContext`;
- создавать `RegistryEngineeringOperationInput`;
- создавать `RegistryEngineeringOperationAuditPackage`;
- создавать composite use case `create + attach + transition`;
- добавлять repository/store;
- добавлять id generator;
- вызывать Translator;
- вызывать assessment;
- вычислять readiness внутри operation;
- выполнять registry mutation;
- выполнять publication.

Вывод:

- operation attachment boundary отклоняется на текущем этапе;
- `RegistryEngineeringOperation` остаётся минимальным lifecycle snapshot;
- read-only context остаётся в existing application results;
- следующий безопасный audit может быть только вокруг derived readiness на базе `RegistryResolvedRelatedContext`, если коду нужен явный readiness marker.

## Решение по readiness consumer audit

После отклонения operation attachment boundary выполнен read-only audit реального consumer-а для derived readiness marker на базе `RegistryResolvedRelatedContext.missingRelatedEntityIds`.

Проверены:

- production application boundaries;
- production domain operation boundaries;
- related context results;
- operation creation use case;
- operation status transition use case;
- tests around operation and related context;
- guard rules around readiness, operation lifecycle и attachment boundary.

Вывод аудита:

- production consumer, который сейчас читает `missingRelatedEntityIds`, отсутствует;
- production consumer, которому сейчас нужен explicit getter readiness внутри `RegistryResolvedRelatedContext`, отсутствует;
- production consumer, который должен переводить `RegistryEngineeringOperation` в `readyForDecision` на основании resolved context, отсутствует;
- текущие обращения к `missingRelatedEntityIds` находятся внутри самой result model и targeted tests;
- test-only pressure не является основанием расширять production API.

Следствие:

- `RegistryResolvedRelatedContext` не получает readiness getter в текущем step;
- `hasResolvedAllRelatedEntities` не добавляется до появления реального production consumer-а;
- `RegistryContextReadiness` не создаётся;
- `PrepareRegistryContextReadiness` не создаётся;
- use case для status transition based on resolved context не создаётся;
- composite use case для `create + prepare context + resolve context + transition` не создаётся;
- Orchestrator, pipeline, manager, facade или workflow runner не вводятся.

Текущее правило остаётся строгим:

- `missingRelatedEntityIds` остаётся единственным source of truth для resolved related context completeness;
- derived readiness marker может быть добавлен только тогда, когда появится реальный production consumer;
- такой future step должен включать targeted test в том же change;
- future getter не должен читать payload, выполнять assessment, создавать findings, определять ambiguity/contradiction/drift, менять operation status, выполнять registry mutation или publication.

Вывод:

- readiness consumer отсутствует;
- readiness marker откладывается;
- текущий Core остаётся на `RegistryResolvedRelatedContext.missingRelatedEntityIds` без дополнительного API.

## Решение по first clean Translator proposal/result boundary

После audit текущего Core и legacy `lib/features/translator` подтверждено, что следующий clean шаг Registry Studio не должен расширять Core.

Текущий Core уже содержит:

- source-backed registry identity;
- registry relations;
- related context;
- resolved related context;
- operation lifecycle;
- operation creation;
- operation status transition.

Для Core сейчас отсутствует production consumer, который требует readiness getter, operation attachment, composite use case или assessment.

Следующая допустимая зона — clean Translator capability внутри Registry Studio product boundary, но вне Core:

- production: `lib/registry_studio/translator/...`;
- tests: `test/registry_studio/translator/...`.

Legacy `lib/features/translator` не принимается как architecture source of truth.

Допустимое использование legacy Translator:

- evidence для multilingual translation result;
- evidence для reverse-check;
- evidence для canonical wording status;
- evidence для needs-review / drift signal;
- evidence для comment / explanation;
- evidence для candidate canonical phrase.

Недопустимое использование legacy Translator:

- перенос `TranslatorRepository`;
- перенос `RegistryNode`;
- перенос `LoadRegistryTree`;
- перенос `LoadCanonicalClientRules`;
- перенос `AuditCanonicalClientRules` как full Registry Studio audit flow;
- перенос `TranslatorCubit` / `TranslatorState`;
- перенос persistence state;
- перенос prompt-driven source of truth;
- перенос Helpy-specific client-rules workflow.

Первая clean Translator boundary должна владеть только read-only language-quality output для одной engineer-selected phrase или text fragment.

Эта boundary может выражать:

- source language;
- source text;
- RU / EN / TH translated text values;
- reverse-check evidence;
- canonical wording status;
- comment / explanation;
- optional candidate canonical phrase for engineer review.

Эта boundary не должна владеть:

- registry identity;
- registry path;
- registry relation;
- related context;
- resolved related context;
- operation lifecycle;
- operation status transition;
- registry dictionary mutation;
- canonical phrase approval;
- semantic decision;
- ambiguity resolution;
- approved change scope;
- publication control.

Первый implementation step в `lib/registry_studio/translator` не должен создавать:

- repository;
- data source;
- remote prompt adapter;
- manager;
- facade;
- helper;
- capability catalog;
- plugin registry;
- mutation use case;
- publication use case;
- Registry Studio operation;
- verified audit package.

Первый implementation step может создать только immutable read-only result/proposal shape и targeted tests.

Approved first code direction:

- определить typed status для Translator phrase result;
- определить immutable read-only result/proposal object для одной phrase/text;
- нормализовать text fields через trim;
- запретить empty required text fields;
- сохранить result free of Core mutation, registry loading, repository, presentation и persistence;
- не импортировать этот Translator boundary из Core.

Future application use case, который будет вызывать actual translation provider, не входит в первый code step.

Future dictionary mutation/publication path не входит в первый code step.

Future operation attachment of Translator proposal не входит в первый code step.

Вывод:

- первый clean Translator step может быть только read-only result/proposal model outside Core;
- old Translator используется только как evidence по output shape;
- Core остаётся независимым от Translator;
- registry mutation, approval и publication остаются вне Translator.

## Checkpoint реализации TranslatorPhraseResult

Первый clean Translator code step реализован.

Добавлены:

- `lib/registry_studio/translator/translator_phrase_status.dart`;
- `lib/registry_studio/translator/translator_phrase_result.dart`;
- `test/registry_studio/translator/translator_phrase_result_test.dart`.

Реализованная ответственность:

- immutable read-only language-quality result для одной engineer-selected phrase/text;
- typed status через `TranslatorPhraseStatus`;
- normalized required source fields;
- normalized optional translation / reverse-check / comment / candidate phrase fields;
- value equality через Equatable.

`TranslatorPhraseResult` не является entity.

Он не имеет:

- identity;
- lifecycle;
- operation ownership;
- registry identity ownership;
- dictionary mutation ownership;
- approval ownership;
- publication ownership.

Подтверждённые ограничения:

- Core не импортирует Translator;
- Translator не импортируется в Registry Studio Core;
- repository не создан;
- data source не создан;
- remote prompt adapter не создан;
- manager/facade/helper не создан;
- application use case не создан;
- provider boundary не создан;
- mutation/publication path не создан;
- operation attachment не создан;
- verified audit package не создан.

Проверки implementation step:

- `dart analyze` для новых Translator files прошёл;
- `flutter analyze` прошёл;
- temporary pure Dart smoke check прошёл;
- targeted Flutter test сохранён, но локальный `flutter test` в Termux не используется как blocking verification из-за known `libvk_swiftshader.so` runner issue.

Следующий шаг не должен автоматически создавать application use case.

Перед future application use case требуется отдельный ownership-аудит:

- кто вызывает actual translation provider;
- как называется provider boundary;
- почему provider boundary не является repository/data source;
- какие inputs принимает use case;
- почему result остаётся read-only;
- почему use case не выполняет registry mutation, approval или publication.

## Ownership-аудит Translator provider boundary

После реализации `TranslatorPhraseResult` подтверждён следующий допустимый future boundary: provider boundary для actual translation provider.

Эта boundary допустима только внутри Translator product boundary:

- production: `lib/registry_studio/translator/...`;
- tests: `test/registry_studio/translator/...`.

Owner boundary:

- `registry_studio/translator`.

Caller boundary:

- future Translator application use case.

Core ownership:

- Registry Studio Core не вызывает provider;
- Registry Studio Core не импортирует provider;
- provider не является частью Core.

Provider boundary может иметь только одну ответственность:

- получить один engineer-selected phrase/text input;
- вызвать actual translation capability через будущую implementation boundary;
- вернуть `TranslatorPhraseResult`.

Provider boundary не является Repository, потому что он не должен:

- владеть registry persistence;
- загружать registry tree;
- загружать canonical client rules;
- refresh-ить registry;
- хранить result;
- искать entities;
- возвращать collections;
- выполнять cache/store behavior.

Provider boundary не является DataSource, потому что clean Translator boundary не должна зависеть от raw remote shape:

- HTTP/Dio;
- vendor API request;
- model name;
- prompt format;
- token settings;
- raw response parsing;
- infrastructure exception mapping.

Эти детали принадлежат future infrastructure adapter и не должны определять application/domain language.

Минимальный input для first provider/application step:

- required source text;
- optional source language hint;
- optional engineer-provided context.

В first provider/application step не входят:

- registry dictionary snapshot;
- source evidence object;
- related context;
- resolved context;
- operation;
- audit package.

Эти inputs требуют отдельного ownership-аудита, потому что могут создать связь с Core, registry context или future audit flow.

Output boundary:

- provider возвращает только `TranslatorPhraseResult`;
- provider не возвращает mutation command;
- provider не возвращает approval decision;
- provider не возвращает publication instruction;
- provider не возвращает operation attachment;
- provider не возвращает verified audit package.

Следующий implementation step может вводить provider boundary только вместе с явным consumer/use case либо после отдельного доказательства, почему provider interface без consumer не является premature modeling.

Future application use case должен оставаться:

- Translator-only;
- Core-independent;
- repository-free;
- data-source-free at application boundary;
- mutation-free;
- publication-free;
- approval-free;
- operation-free.

Вывод:

- `TranslatorPhraseProvider` допустим как future boundary name candidate;
- `TranslatorRepository` остаётся запрещённым;
- `TranslatorRemoteDataSource` не переносится в clean Translator boundary;
- legacy provider/data source code остаётся evidence только по behavior shape, но не по architecture shape.

## Ownership-аудит Translator use case boundary

После ownership-аудита provider boundary подтверждён допустимый future consumer/use case boundary.

Допустимое имя use case:

- `TranslatePhrase`.

Отклонённое имя:

- `TranslateTranslatorPhrase`.

Причина отклонения:

- `translator` уже задан placement-ом `lib/registry_studio/translator/...`;
- повторение `Translator` в имени use case создаёт лишний noise;
- use case внутри Translator boundary должен называться по действию над объектом: translate phrase/text.

Use case owner:

- `registry_studio/translator`.

Provider dependency:

- `TranslatePhrase` может зависеть от `TranslatorPhraseProvider`.

Provider interface placement:

- внутри Translator application boundary;
- вне Core;
- без import-а в Core.

Минимальный use case input:

- required `sourceText`;
- optional `sourceLanguageHint`;
- optional `engineerContext`.

Отдельный input object сейчас не создаётся.

Причина:

- input shape малый;
- у input нет identity;
- у input нет lifecycle;
- у input нет самостоятельных invariants сверх trim / empty required source text;
- object вроде `TranslatorPhraseInput`, `TranslatorPhraseRequest` или `TranslatorPhraseCommand` сейчас был бы premature modeling.

Use case responsibility:

- принять engineer-selected phrase/text;
- normalize required source text;
- normalize optional hints;
- reject empty required source text;
- вызвать `TranslatorPhraseProvider`;
- вернуть `TranslatorPhraseResult`.

Use case не является Repository, потому что он не должен:

- хранить result;
- загружать registry;
- refresh-ить registry;
- возвращать registry tree;
- выполнять persistence/cache/store behavior.

Use case не является DataSource, потому что он не должен:

- знать HTTP/Dio;
- знать vendor API;
- знать prompt format;
- знать model name;
- парсить raw provider response;
- маппить infrastructure errors.

Use case не является registry operation, потому что он не должен:

- создавать `RegistryEngineeringOperation`;
- менять operation status;
- прикреплять proposal/result к operation;
- вычислять readiness;
- создавать audit package.

Use case output:

- только `TranslatorPhraseResult`.

Use case не должен возвращать:

- mutation command;
- approval decision;
- publication instruction;
- operation attachment;
- verified audit package;
- registry dictionary entry.

Запрещено для first implementation step:

- Core import;
- registry loading;
- registry dictionary snapshot;
- source evidence object;
- related context;
- resolved context;
- operation input;
- audit package;
- mutation;
- approval;
- publication.

Вывод:

- `TranslatePhrase` допустим как next code step;
- `TranslatorPhraseProvider` допустим как dependency для `TranslatePhrase`;
- separate input object не создаётся в этом step;
- output остаётся `TranslatorPhraseResult`;
- implementation должен остаться Translator-only, Core-independent, repository-free, data-source-free, mutation-free, publication-free.

## Checkpoint реализации TranslatePhrase

Translator application boundary реализована.

Добавлены:

- `lib/registry_studio/translator/application/translator_phrase_provider.dart`;
- `lib/registry_studio/translator/application/translate_phrase.dart`;
- `test/registry_studio/translator/application/translate_phrase_test.dart`.

Реализованная ответственность `TranslatePhrase`:

- принять engineer-selected phrase/text;
- normalize required `sourceText`;
- normalize optional `sourceLanguageHint`;
- normalize optional `engineerContext`;
- reject empty required `sourceText`;
- вызвать `TranslatorPhraseProvider`;
- вернуть `TranslatorPhraseResult` без изменения.

Реализованная ответственность `TranslatorPhraseProvider`:

- быть application boundary для actual translation capability;
- принимать только phrase/text input;
- возвращать только `TranslatorPhraseResult`.

Подтверждённые ограничения:

- Core не импортирует Translator;
- Translator boundary не импортируется в Core;
- repository не создан;
- data source не создан;
- infrastructure provider implementation не создан;
- remote prompt adapter не создан;
- Registry Studio operation не создана и не меняется;
- operation attachment не создан;
- registry loading не добавлен;
- registry dictionary snapshot не добавлен;
- source evidence input не добавлен;
- related/resolved context input не добавлен;
- audit package не создан;
- mutation/approval/publication path не создан.

Проверки implementation step:

- `dart analyze` для новых Translator application files прошёл;
- `flutter analyze` прошёл;
- temporary pure Dart smoke check прошёл;
- targeted Flutter test сохранён, но локальный `flutter test` в Termux не используется как blocking verification из-за known `libvk_swiftshader.so` runner issue.

Следующий шаг не должен автоматически создавать infrastructure adapter.

Перед infrastructure/provider implementation требуется отдельный ownership-аудит:

- где живёт implementation `TranslatorPhraseProvider`;
- как называется implementation;
- какие infrastructure dependencies допустимы;
- почему implementation не является Repository/DataSource;
- почему prompt/vendor/model/raw response не становятся application language;
- как implementation возвращает `TranslatorPhraseResult`;
- почему implementation не получает registry loading, mutation, approval, publication или operation attachment.

## Ownership-аудит Translator infrastructure provider implementation

После реализации `TranslatePhrase` подтверждён следующий допустимый future infrastructure adapter:

- `TyphoonTranslatorPhraseProvider`.

Placement:

- production: `lib/registry_studio/translator/infrastructure/...`;
- tests: `test/registry_studio/translator/infrastructure/...`.

Implementation responsibility:

- implement `TranslatorPhraseProvider`;
- call actual Typhoon translation capability;
- keep vendor/API/prompt/raw response details inside infrastructure;
- map provider output into `TranslatorPhraseResult`;
- expose only `TranslatorPhraseProvider` to application boundary.

Почему имя `TyphoonTranslatorPhraseProvider` допустимо:

- implementation действительно vendor-specific;
- vendor detail явно ограничен infrastructure layer;
- application boundary остаётся vendor-neutral через `TranslatorPhraseProvider`;
- `TranslatePhrase` не знает Typhoon, HTTP, prompt, model или raw response.

Отклонённые имена:

- `TranslatorPhraseProviderImpl` — generic `Impl` не раскрывает infrastructure responsibility;
- `TranslatorPhraseRemoteDataSource` — возвращает запрещённый DataSource language;
- `TranslatorRepositoryImpl` — возвращает запрещённый Repository language;
- `RemoteTranslatorPhraseProvider` — слишком общий и скрывает vendor-specific behavior;
- `ApiTranslatorPhraseProvider` — слишком общий и смешивает transport/API naming с provider responsibility.

Допустимые infrastructure dependencies для implementation:

- existing `ApiClient`;
- existing `AppConfig`;
- Dio response/error handling внутри adapter;
- prompt construction внутри adapter;
- raw response parsing внутри adapter.

Эти dependencies допустимы только внутри infrastructure implementation и не должны стать частью application boundary.

Запрещено протаскивать в `TranslatePhrase` или `TranslatorPhraseProvider`:

- Dio;
- HTTP request shape;
- vendor API path;
- model name;
- token settings;
- prompt labels;
- raw response map;
- infrastructure exception mapping.

Legacy usage:

- `translator_remote_datasource.dart` может использоваться только как behavior evidence;
- `translation_result_model.dart` может использоваться только как output-shape evidence;
- `translator_repository_impl.dart` не переносится;
- `TranslatorRepository` не переносится;
- `RegistryRemoteDataSource` не переносится;
- `RegistryNode` не переносится;
- `main.dart` wiring не является clean architecture source of truth.

Implementation не должна:

- загружать registry tree;
- загружать canonical client rules;
- refresh-ить registry;
- искать registry items;
- хранить result;
- выполнять cache/store behavior;
- создавать operation;
- менять operation status;
- attach-ить result к operation;
- создавать audit package;
- выполнять mutation;
- выполнять approval;
- выполнять publication.

Output:

- только `TranslatorPhraseResult`.

Вывод:

- next code step может создать `TyphoonTranslatorPhraseProvider`;
- placement должен быть infrastructure-only;
- application boundary остаётся `TranslatorPhraseProvider`;
- Core не импортирует Translator;
- legacy DataSource/Repository architecture не переносится.

## Checkpoint реализации TyphoonTranslatorPhraseProvider

Translator infrastructure provider implementation реализована.

Implementation commit:

- `cac4461 feat: add typhoon translator phrase provider`.

Добавлены:

- `lib/registry_studio/translator/infrastructure/typhoon_translator_phrase_provider.dart`;
- `test/registry_studio/translator/infrastructure/typhoon_translator_phrase_provider_test.dart`.

Реализованная ответственность `TyphoonTranslatorPhraseProvider`:

- implements `TranslatorPhraseProvider`;
- вызывает Typhoon chat completions через existing `ApiClient`;
- использует existing `AppConfig` только внутри infrastructure;
- строит translation prompt внутри infrastructure;
- строит audit prompt внутри infrastructure;
- парсит raw Typhoon response внутри infrastructure;
- маппит translation/audit output в `TranslatorPhraseResult`;
- возвращает failed `TranslatorPhraseResult` при Dio/format failure.

Подтверждённые ограничения:

- Core не импортирует Translator;
- application boundary не знает Typhoon;
- `TranslatePhrase` не знает HTTP/Dio/model/prompt/raw response;
- `TranslatorPhraseProvider` не знает HTTP/Dio/model/prompt/raw response;
- legacy `TranslatorRepository` не перенесён;
- legacy `TranslatorRemoteDataSource` не перенесён как architecture shape;
- legacy `TranslationResultModel` не перенесён;
- `RegistryNode` не перенесён;
- registry loading не добавлен;
- registry dictionary snapshot не добавлен;
- operation attachment не создан;
- audit package не создан;
- mutation/approval/publication path не создан.

Проверки implementation step:

- `dart analyze` для infrastructure provider/test прошёл;
- `flutter analyze` прошёл;
- architecture forbidden checks прошли;
- Core import boundary check прошёл;
- targeted Flutter test сохранён, но локальный `flutter test` в Termux не используется как blocking verification из-за known `libvk_swiftshader.so` runner issue.

Следующий шаг не должен автоматически подключать provider в runtime.

Перед runtime wiring требуется отдельный ownership-аудит:

- где создаётся `TyphoonTranslatorPhraseProvider`;
- кто создаёт `TranslatePhrase`;
- является ли wiring частью current app bootstrap или отдельной Registry Studio composition boundary;
- почему wiring не возвращает legacy `TranslatorRepository`;
- почему wiring не подключает registry loading;
- почему wiring не создаёт operation attachment;
- почему wiring не создаёт mutation, approval или publication.

## Контракт мультиязычного перевода и дословной обратной проверки Typhoon

Этот раздел является источником истины для поведения `TyphoonTranslatorPhraseProvider`.

Контракт изменяет только существующий Translator infrastructure behavior и не меняет утверждённые архитектурные границы:

- Translator остаётся вне Registry Studio Core;
- `TranslatorPhraseProvider` остаётся application boundary;
- Typhoon, HTTP, prompts, parser и raw response остаются внутри infrastructure;
- результат остаётся read-only engineering evidence;
- Translator не принимает semantic decision;
- Translator не утверждает canonical wording;
- Translator не изменяет и не публикует registry.

Историческим behavior evidence является commit:

- `1da3033 fix: require complete ascii translation sections`.

Из старой реализации принимается требование полного девятисекционного результата. Legacy Repository, DataSource и Helpy-specific architecture не переносятся.

### Назначение

Для проектов, работающих в Таиланде, инженер должен получить:

- исходную формулировку;
- русскую версию;
- английскую версию;
- тайскую версию;
- дословный смысл английской версии на русском и тайском;
- дословный смысл тайской версии на русском и английском;
- независимый аудит смыслового, терминологического и инструктивного drift.

Дословный обратный перевод является диагностическим доказательством фактически переданного смысла.

Он не должен:

- улучшать формулировку;
- нормализовать формулировку;
- восстанавливать предполагаемое намерение;
- исправлять результат по исходному тексту;
- приводить текст к canonical style;
- устранять неоднозначность;
- добавлять отсутствующий контекст.

### Запрет символов направления

Provider-generated system prompts и provider-generated user-content wrappers не должны содержать символы направления любого вида.

Направления перевода описываются только словами и через стабильные ASCII labels.

Ограничение относится к тексту, создаваемому provider. Пользовательский `SOURCE TEXT` сохраняется без изменения.

### Последовательность запросов

Одна операция `translatePhrase` выполняет четыре независимых запроса:

1. Прямой мультиязычный перевод с секциями `SOURCE LANGUAGE`, `SOURCE TEXT`, `RU`, `EN`, `TH`.
2. Дословная проверка английской версии с секциями `EN_TO_RU`, `EN_TO_TH`.
3. Дословная проверка тайской версии с секциями `TH_TO_RU`, `TH_TO_EN`.
4. Независимый аудит полного валидированного набора из девяти секций.

Запрос проверки английской версии получает только содержимое `EN`.

Запрос проверки тайской версии получает только содержимое `TH`.

В запросы дословной проверки запрещено передавать:

- `SOURCE TEXT`;
- `SOURCE LANGUAGE`;
- другие прямые языковые версии;
- `SOURCE LANGUAGE HINT`;
- `ENGINEER CONTEXT`;
- предыдущий аудит;
- ожидаемую каноническую формулировку.

### Prompt прямого мультиязычного перевода

```text
Ты являешься строгим мультиязычным инженерным переводчиком Registry Studio.

Язык исходного текста: RU, EN или TH.
Определи язык исходного текста.
Используй SOURCE LANGUAGE HINT только как подсказку, если он передан.
Используй ENGINEER CONTEXT только для понимания терминологии или устранения неоднозначности.
Не переводи ENGINEER CONTEXT.
Не добавляй сведения из ENGINEER CONTEXT в переводимый текст.

Ты обязан вернуть ровно 5 секций.
Все секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.
Не используй дефис или тире вместо значения.
Не используй символы направления в ответе.

Правила перевода:

1. Сохрани SOURCE TEXT точно в том виде, в котором он передан.
2. Не добавляй кавычки вокруг SOURCE TEXT.
3. В языковой секции, соответствующей SOURCE LANGUAGE, повтори SOURCE TEXT без изменений.
4. Сформируй версии на русском, английском и тайском языках.
5. Переводи настолько дословно, насколько позволяет грамматика целевого языка.
6. Сохраняй точный инженерный смысл.
7. Сохраняй техническую и реестровую терминологию.
8. Сохраняй силу инструкции.
9. Сохраняй обязательность, допустимость и запрет.
10. Сохраняй отрицания.
11. Сохраняй границы работ и исключения.
12. Сохраняй количества, единицы измерения, условия и последовательность.
13. Не улучшай формулировку.
14. Не упрощай формулировку.
15. Не заменяй конкретные термины более общими.
16. Не смягчай и не усиливай инструкцию.
17. Не добавляй пояснения.
18. Не выполняй аудит.
19. Не утверждай каноничность формулировки.
20. Не изменяй содержимое registry.

Верни результат строго с этими ASCII labels:

SOURCE LANGUAGE:
RU | EN | TH

SOURCE TEXT:
исходный текст без изменений

RU:
русская версия

EN:
английская версия

TH:
тайская версия
```

Формат обязательных входных данных:

```text
SOURCE TEXT:
исходный текст
```

Опциональная подсказка:

```text
SOURCE LANGUAGE HINT:
RU | EN | TH
```

Опциональный инженерный контекст:

```text
ENGINEER CONTEXT:
инженерный контекст
```

Опциональные секции полностью отсутствуют, если соответствующее значение не задано.

### Prompt дословной проверки английской версии

```text
Ты являешься переводчиком дословной обратной проверки Registry Studio.

Ты получаешь только инженерную фразу на английском языке.
Ты не знаешь исходный текст.
Не пытайся угадать или восстановить исходную формулировку.

Ты обязан вернуть ровно 2 секции.
Обе секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.
Не используй дефис или тире вместо значения.
Не используй символы направления в ответе.

Правила перевода:

1. Переведи переданный английский текст дословно на русский язык.
2. Переведи тот же английский текст дословно на тайский язык.
3. Переводи только фактически переданный текст.
4. Передай точный смысл английской формулировки.
5. Сохраняй терминологию.
6. Сохраняй силу инструкции.
7. Сохраняй обязательность, допустимость, запрет и отрицание.
8. Сохраняй границы, количества, условия и последовательность.
9. Сохраняй порядок слов там, где это допускает грамматика целевого языка.
10. Не улучшай формулировку.
11. Не нормализуй формулировку.
12. Не приводи формулировку к каноническому стилю.
13. Не устраняй неоднозначность.
14. Не добавляй отсутствующий контекст.
15. Не объясняй результат.
16. Не выполняй аудит.

Верни результат строго с этими ASCII labels:

EN_TO_RU:
дословный русский перевод переданного английского текста

EN_TO_TH:
дословный тайский перевод переданного английского текста
```

Формат входных данных:

```text
EN:
содержимое секции EN
```

### Prompt дословной проверки тайской версии

```text
Ты являешься переводчиком дословной обратной проверки Registry Studio.

Ты получаешь только инженерную фразу на тайском языке.
Ты не знаешь исходный текст.
Не пытайся угадать или восстановить исходную формулировку.

Ты обязан вернуть ровно 2 секции.
Обе секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.
Не используй дефис или тире вместо значения.
Не используй символы направления в ответе.

Правила перевода:

1. Переведи переданный тайский текст дословно на русский язык.
2. Переведи тот же тайский текст дословно на английский язык.
3. Переводи только фактически переданный текст.
4. Передай точный смысл тайской формулировки.
5. Сохраняй терминологию.
6. Сохраняй силу инструкции.
7. Сохраняй обязательность, допустимость, запрет и отрицание.
8. Сохраняй границы, количества, условия и последовательность.
9. Сохраняй порядок слов там, где это допускает грамматика целевого языка.
10. Не улучшай формулировку.
11. Не нормализуй формулировку.
12. Не приводи формулировку к каноническому стилю.
13. Не устраняй неоднозначность.
14. Не добавляй отсутствующий контекст.
15. Не объясняй результат.
16. Не выполняй аудит.

Верни результат строго с этими ASCII labels:

TH_TO_RU:
дословный русский перевод переданного тайского текста

TH_TO_EN:
дословный английский перевод переданного тайского текста
```

Формат входных данных:

```text
TH:
содержимое секции TH
```

### Обязательный девятисекционный результат

Provider собирает ровно девять секций в следующем порядке:

```text
SOURCE LANGUAGE:
значение

SOURCE TEXT:
значение

RU:
значение

EN:
значение

TH:
значение

EN_TO_RU:
значение

TH_TO_RU:
значение

EN_TO_TH:
значение

TH_TO_EN:
значение
```

Все девять секций обязательны и должны содержать непустые значения.

### Строгая валидация translation output

До аудита infrastructure parser обязан проверить:

1. Присутствуют ровно все девять ожидаемых labels.
2. Каждый label присутствует только один раз.
3. Неожиданные labels отсутствуют.
4. Порядок секций соответствует контракту.
5. Каждая секция содержит непустое значение.
6. `SOURCE LANGUAGE` содержит только `RU`, `EN` или `TH`.
7. `SOURCE TEXT` совпадает с нормализованным входным текстом.
8. Секция исходного языка совпадает с `SOURCE TEXT`.
9. Значения-заглушки не принимаются как перевод.

Минимальный запрещённый набор заглушек:

```text
-
N/A
NONE
NULL
UNKNOWN
NOT PROVIDED
```

Parser не должен заменять отсутствующую секцию пустой строкой и продолжать обработку.

При нарушении translation format:

- аудит не вызывается;
- частичный результат не считается успешным;
- provider возвращает `TranslatorPhraseResult` со статусом `failed`;
- причина ошибки передаётся инженеру через `comment`.

### Prompt независимого аудита

```text
Ты являешься независимым аудитором мультиязычных инженерных формулировок Registry Studio.

Ты не выполняешь перевод.
Ты не переписываешь формулировки.
Ты проверяешь только полный набор из 9 секций.

Секции дословного обратного перевода являются диагностическим доказательством.
Используй их, чтобы определить, какой смысл фактически передают английская и тайская версии.

Проверь:

1. Сохранили ли RU, EN и TH один инженерный смысл.
2. Осталась ли техническая и реестровая терминология точной.
3. Сохранилась ли сила инструкции.
4. Изменилась ли обязательность, допустимость или запрещённость действия.
5. Изменилось ли отрицание.
6. Изменились ли границы работ или исключения.
7. Изменились ли количества, единицы измерения, условия или последовательность.
8. Стал ли конкретный термин более широким, мягким или менее точным.
9. Появилась ли неоднозначность.
10. Показывают ли дословные обратные переводы смысловой drift.

Правила аудита:

1. Если смысл изменился, установи MEANING_PRESERVED в NO.
2. Если терминология стала менее точной, установи TERMINOLOGY_PRESERVED в NO.
3. Если изменилась сила инструкции или инструктивная форма, установи CANONICAL_STYLE_PRESERVED в NO.
4. Если формулировка допускает несколько значимых для registry толкований, установи AMBIGUOUS_WORDING в YES.
5. Несовпадение прямой версии и дословного обратного перевода считай основанием для строгой проверки.
6. Не трактуй сомнения в пользу корректности.
7. Не улучшай формулировки.
8. Не предлагай замену.
9. Не утверждай публикацию.
10. Не предлагай изменение registry.
11. Не используй символы направления в ответе.

Ты обязан вернуть ровно 5 секций.
Все секции обязательны.
Не пропускай секции.
Не возвращай пустые значения.

Верни результат строго с этими ASCII labels:

MEANING_PRESERVED:
YES | NO

TERMINOLOGY_PRESERVED:
YES | NO

CANONICAL_STYLE_PRESERVED:
YES | NO

AMBIGUOUS_WORDING:
YES | NO

REASON:
краткое объяснение на русском языке с указанием конкретных различий
```

### Строгая валидация audit output

Infrastructure parser обязан проверить:

- присутствуют ровно пять audit labels;
- каждый label присутствует один раз;
- неожиданные labels отсутствуют;
- первые четыре значения содержат только `YES` или `NO`;
- `REASON` содержит непустое объяснение;
- пустые значения и заглушки запрещены.

При нарушении audit format provider возвращает `failed`.

Невалидный audit не преобразуется в `Exact`, `Equivalent`, `Needs Review` или `Canonical Drift`.

### Запрещённое поведение

Запрещено:

- формировать все девять translation sections одним Typhoon request;
- передавать исходный текст в literal reverse requests;
- передавать engineer context в literal reverse requests;
- исправлять literal reverse result по исходному тексту;
- принимать отсутствующие секции как пустые строки;
- запускать аудит после неполного translation result;
- использовать prompt как source of truth для registry semantics;
- считать audit verdict canonical approval;
- автоматически менять или публиковать registry.

### Требования к следующему implementation step

Следующий code-step изменяет только существующий Translator infrastructure behavior и его тесты.

Разрешено изменить:

- `TyphoonTranslatorPhraseProvider`;
- его infrastructure tests;
- существующий `TranslatorPhraseResult` только при доказанной невозможности представить утверждённые девять секций.

Без отдельного ownership-аудита не создавать:

- новую domain entity;
- новый application use case;
- repository;
- data source;
- manager;
- facade;
- helper;
- service locator;
- workflow engine;
- audit package;
- mutation или publication boundary.

Тестами должны быть покрыты:

- четыре независимых request;
- отсутствие исходного текста и engineer context в literal reverse requests;
- полный девятисекционный результат;
- отказ при отсутствующей, пустой, дублированной или неожиданной секции;
- отказ при placeholder value;
- запрет аудита после translation format failure;
- отказ при неполном audit output;
- преобразование format failure в `failed`;
- отсутствие символов направления в provider-generated prompts.

## Аудит владения ответственностью за подключение Translator во время запуска

После контрольной точки реализации `TyphoonTranslatorPhraseProvider` проведён аудит владения ответственностью за подключение во время запуска приложения.

Фактическое состояние `lib/main.dart`:

- `main.dart` остаётся старой точкой запуска приложения;
- он создаёт `TranslatorRemoteDataSourceImpl`;
- он создаёт `RegistryRemoteDataSourceImpl`;
- он создаёт `TranslatorRepositoryImpl`;
- он создаёт старый `TranslateCanonicalPhrase`;
- он создаёт старый `AuditCanonicalClientRules`;
- он создаёт старый `LoadRegistryTree`;
- он создаёт `TranslatorCubit`;
- он открывает старый `TranslatorPage`.

Фактическое состояние чистого Translator:

- `TranslatePhrase` существует только внутри `registry_studio/translator/application`;
- `TranslatorPhraseProvider` существует только как граница слоя приложения;
- `TyphoonTranslatorPhraseProvider` существует только как инфраструктурный адаптер;
- чистый Translator сейчас используется только целевыми тестами и документацией;
- рабочий потребитель чистого `TranslatePhrase` во время запуска сейчас отсутствует.

Решение:

- подключение во время запуска сейчас не разрешено;
- `main.dart` сейчас не является источником истины для чистой сборки Registry Studio;
- прямое подключение чистого Translator в текущий `main.dart` запрещено;
- создание объекта корневой сборки приложения сейчас запрещено как преждевременное моделирование без чистого потребителя.

Причина запрета:

- подключение создаёт новую ответственность;
- текущий `main.dart` уже несёт давление старой архитектуры Translator;
- прямое подключение в `main.dart` смешало бы чистый Translator со старыми Repository/DataSource/Cubit/Page;
- подключение без чистого потребителя было бы неиспользуемым слоем сборки;
- подключение без аудита владения ответственностью за consumer boundary нарушило бы правило "один change = одна responsibility".

Запрещено в следующем code step:

- править `main.dart`;
- подключать `TyphoonTranslatorPhraseProvider` в старую точку запуска;
- подключать `TranslatePhrase` в старый `TranslatorCubit`;
- возвращать `TranslatorRepository`;
- возвращать `TranslatorRemoteDataSource`;
- возвращать `RegistryRemoteDataSource`;
- возвращать `RegistryNode`;
- подключать загрузку Registry;
- подключать snapshot словаря Registry;
- создавать operation attachment;
- создавать audit package;
- создавать mutation path;
- создавать approval path;
- создавать publication path.

Следующая допустимая зона аудита:

- чистый потребитель / граница слоя представления для `TranslatePhrase`.

Перед любым code step, связанным с запуском приложения, требуется отдельный аудит владения ответственностью:

- кто является чистым потребителем `TranslatePhrase`;
- это UI, command, diagnostic screen или другая product boundary;
- где живёт чистый потребитель слоя представления или слоя приложения;
- заменяет ли он старый `TranslatorPage` или существует отдельно;
- почему он не зависит от `TranslatorRepository`;
- почему он не зависит от `TranslatorCubit`;
- почему он не загружает Registry;
- почему он не создаёт operation attachment;
- почему он не выполняет mutation, approval или publication.

Вывод:

- текущая реализация чистого Translator закрыта на уровне слоя приложения и инфраструктурного адаптера;
- подключение во время запуска отложено;
- следующий code step не разрешён без аудита владения ответственностью за границу чистого потребителя.

## Аудит владения ответственностью за границу чистого потребителя Translator

После запрета преждевременного подключения во время запуска проведён аудит границы чистого потребителя для `TranslatePhrase`.

Фактическое состояние старого слоя представления:

- старый `TranslatorCubit` зависит от `TranslateCanonicalPhrase`;
- старый `TranslatorCubit` зависит от `AuditCanonicalClientRules`;
- старый `TranslatorCubit` зависит от `LoadRegistryTree`;
- старый `TranslatorCubit` зависит от persistence;
- старый `TranslatorCubit` работает с `RegistryNode`;
- старый `TranslatorCubit` хранит историю переводов;
- старый `TranslatorCubit` хранит результаты аудита;
- старый `TranslatorCubit` хранит статусы фраз Registry;
- старый `TranslatorPage` напрямую читает старый `TranslatorCubit`;
- старый `TranslatorPage` содержит вкладку Registry, поиск, фильтры, статусы и workflow, специфичный для Helpy.

Вывод по старому слою представления:

- старый `TranslatorCubit` не может быть чистым потребителем `TranslatePhrase`;
- старый `TranslatorState` не может быть чистым состоянием Registry Studio Translator;
- старый `TranslatorPage` не может быть первой чистой границей слоя представления;
- перенос старого слоя представления запрещён.

Фактическое состояние чистого Translator:

- `TranslatePhrase` уже реализован;
- `TranslatorPhraseProvider` уже реализован как граница слоя приложения;
- `TyphoonTranslatorPhraseProvider` уже реализован как инфраструктурный адаптер;
- рабочий чистый потребитель отсутствует;
- директория чистого слоя представления отсутствует;
- конфликт имён для чистого потребителя не найден.

Решение:

- первым чистым потребителем может быть только узкая граница состояния слоя представления;
- первый чистый потребитель не должен быть `main.dart`;
- первый чистый потребитель не должен быть экраном;
- первый чистый потребитель не должен быть командой;
- первый чистый потребитель не должен быть диагностическим экраном;
- первый чистый потребитель не должен создавать provider;
- первый чистый потребитель не должен выполнять подключение во время запуска.

Допустимая первая граница чистого потребителя:

- `TranslatorPhraseCubit`;
- `TranslatorPhraseState`.

Размещение:

- production: `lib/registry_studio/translator/presentation/cubit/...`;
- tests: `test/registry_studio/translator/presentation/cubit/...`.

Ответственность `TranslatorPhraseCubit`:

- принять выбранную инженером формулировку или текст;
- вызвать `TranslatePhrase`;
- выразить состояние загрузки, успеха или ошибки в слое представления;
- хранить только текущий `TranslatorPhraseResult`;
- хранить только текущее сообщение ошибки слоя представления;
- сбрасывать текущий результат перевода формулировки.

Ответственность `TranslatorPhraseState`:

- неизменяемое состояние слоя представления для сценария перевода одной формулировки;
- текущий статус;
- текущий результат;
- текущее сообщение ошибки.

`TranslatorPhraseCubit` может зависеть только от:

- `TranslatePhrase`.

`TranslatorPhraseState` может зависеть только от:

- `TranslatorPhraseResult`;
- enum/value статуса слоя представления, если потребуется;
- `Equatable`, если используется сравнение по значению.

Запрещено для `TranslatorPhraseCubit`:

- зависеть от `TranslatorRepository`;
- зависеть от `TranslatorRemoteDataSource`;
- зависеть от `RegistryRemoteDataSource`;
- зависеть от `RegistryNode`;
- зависеть от старого `TranslatorCubit`;
- зависеть от старого `TranslatorState`;
- зависеть от старого `TranslatorPage`;
- зависеть от persistence;
- зависеть от хранилища статусов фраз Registry;
- зависеть от контроллера фонового выполнения;
- загружать Registry;
- обновлять Registry;
- хранить историю переводов;
- хранить результаты canonical audit;
- выполнять batch audit;
- создавать operation attachment;
- создавать audit package;
- выполнять mutation;
- выполнять approval;
- выполнять publication.

Запрещено для `TranslatorPhraseCubit` знать:

- Typhoon;
- `ApiClient`;
- `AppConfig`;
- Dio;
- форму HTTP request;
- имя модели;
- формат prompt;
- parsing raw response;
- infrastructure error mapping.

Отложено:

- `TranslatorPhraseScreen`;
- `RegistryStudioTranslatorScreen`;
- подключение во время запуска;
- изменения `main.dart`;
- корневая сборка приложения;
- замена старого `TranslatorPage`.

Вывод:

- следующий code step может создать `TranslatorPhraseCubit` и `TranslatorPhraseState`;
- следующий code step не должен создавать экран;
- следующий code step не должен править `main.dart`;
- следующий code step не должен создавать объект корневой сборки приложения;
- следующий code step должен иметь целевые тесты;
- после code step нужна контрольная точка реализации в Guard.

## Контрольная точка реализации TranslatorPhraseCubit

Чистый потребитель слоя представления Translator реализован.

Коммиты реализации:

- `751deb4 feat: add translator phrase presentation cubit`;
- `9c079be refactor: clean translator phrase state initializer`.

Добавлены:

- `lib/registry_studio/translator/presentation/cubit/translator_phrase_cubit.dart`;
- `lib/registry_studio/translator/presentation/cubit/translator_phrase_state.dart`;
- `test/registry_studio/translator/presentation/cubit/translator_phrase_cubit_test.dart`.

Реализованная ответственность `TranslatorPhraseCubit`:

- зависит только от `TranslatePhrase`;
- принимает выбранный инженером `sourceText`;
- принимает optional `sourceLanguageHint`;
- принимает optional `engineerContext`;
- вызывает `TranslatePhrase`;
- выставляет состояние загрузки перед переводом;
- выставляет состояние успеха с текущим `TranslatorPhraseResult`;
- выставляет состояние ошибки с текущим сообщением ошибки слоя представления;
- поддерживает сброс в начальное состояние.

Реализованная ответственность `TranslatorPhraseState`:

- неизменяемое состояние слоя представления для сценария перевода одной формулировки;
- содержит текущий статус слоя представления;
- содержит текущий `TranslatorPhraseResult`;
- содержит текущее сообщение ошибки слоя представления;
- использует сравнение по значению.

Подтверждённые ограничения:

- экран не создан;
- `main.dart` не изменён;
- подключение во время запуска не добавлено;
- объект корневой сборки приложения не создан;
- создание provider не добавлено;
- старый `TranslatorRepository` не используется;
- старый `TranslatorRemoteDataSource` не используется;
- старый `RegistryRemoteDataSource` не используется;
- старый `RegistryNode` не используется;
- старый `TranslatorCubit` не используется;
- старый `TranslatorState` не используется;
- старый `TranslatorPage` не используется;
- persistence не используется;
- хранилище статусов фраз Registry не используется;
- контроллер фонового выполнения не используется;
- загрузка Registry не добавлена;
- история переводов не добавлена;
- результаты canonical audit не добавлены;
- batch audit не добавлен;
- operation attachment не создан;
- audit package не создан;
- mutation path не создан;
- approval path не создан;
- publication path не создан.

Утечки инфраструктурных деталей отсутствуют:

- `TranslatorPhraseCubit` не знает Typhoon;
- `TranslatorPhraseCubit` не знает `ApiClient`;
- `TranslatorPhraseCubit` не знает `AppConfig`;
- `TranslatorPhraseCubit` не знает Dio;
- `TranslatorPhraseCubit` не знает форму HTTP request;
- `TranslatorPhraseCubit` не знает имя модели;
- `TranslatorPhraseCubit` не знает формат prompt;
- `TranslatorPhraseCubit` не знает parsing raw response;
- `TranslatorPhraseCubit` не знает infrastructure error mapping.

Проверки шага реализации:

- целевой `dart analyze` для Cubit/State/test прошёл clean;
- полный `flutter analyze` прошёл clean;
- архитектурные forbidden checks прошли;
- scope check прошёл;
- коммит очистки `9c079be` закрыл `prefer_initializing_formals`.

Следующий шаг не должен автоматически подключать Cubit во время запуска.

Перед следующим code step требуется отдельный аудит владения ответственностью:

- нужен ли `TranslatorPhraseScreen`;
- где он должен жить;
- кто создаёт `TranslatorPhraseCubit`;
- кто создаёт `TranslatePhrase`;
- где создаётся `TyphoonTranslatorPhraseProvider`;
- почему это не возвращает старый `TranslatorPage`;
- почему это не правит `main.dart` преждевременно;
- почему это не создаёт загрузку Registry;
- почему это не создаёт operation attachment;
- почему это не создаёт mutation, approval или publication.

## Аудит владения ответственностью за TranslatorPhraseScreen

После контрольной точки реализации `TranslatorPhraseCubit` проведён аудит границы экрана слоя представления.

Фактическое состояние чистого слоя представления:

- `TranslatorPhraseCubit` реализован;
- `TranslatorPhraseState` реализован;
- чистый слой представления сейчас содержит только `presentation/cubit`;
- чистый экран сейчас отсутствует;
- чистый слой представления остаётся изолированным;
- проверка запрещённых импортов для чистого слоя представления прошла.

Фактическое состояние старого слоя представления:

- старый `TranslatorPage` зависит от старого `TranslatorCubit`;
- старый `TranslatorPage` содержит вкладку Registry;
- старый `TranslatorPage` содержит загрузку Registry;
- старый `TranslatorPage` содержит поиск, фильтры и статусы Registry;
- старый `TranslatorPage` зависит от `RegistryNode`;
- старые виджеты зависят от старого `TranslationResult`;
- старые виджеты зависят от `CanonicalAuditResult`;
- старые виджеты зависят от `RegistryPhraseStatusPersistence`.

Вывод по старому слою представления:

- старый `TranslatorPage` не переносится;
- старые виджеты перевода не переносятся;
- старые виджеты Registry не переносятся;
- старый интерфейс статусов, аудита и истории не переносится.

Решение:

- `TranslatorPhraseScreen` допустим как изолированный экран слоя представления;
- `TranslatorPhraseScreen` не является подключением во время запуска;
- `TranslatorPhraseScreen` не является корневой сборкой приложения;
- `TranslatorPhraseScreen` не создаёт граф зависимостей;
- `TranslatorPhraseScreen` не заменяет `main.dart`;
- `TranslatorPhraseScreen` не заменяет старый `TranslatorPage` во время запуска.

Размещение:

- рабочий код: `lib/registry_studio/translator/presentation/screens/translator_phrase_screen.dart`;
- тесты: `test/registry_studio/translator/presentation/screens/translator_phrase_screen_test.dart`.

Ответственность `TranslatorPhraseScreen`:

- дать инженеру поле для выбранной формулировки или текста;
- дать optional поле для language hint;
- дать optional поле для engineering context;
- вызвать `TranslatorPhraseCubit.translatePhrase`;
- вызвать `TranslatorPhraseCubit.clear`;
- показать состояние загрузки;
- показать текущий `TranslatorPhraseResult`;
- показать текущее сообщение ошибки слоя представления.

`TranslatorPhraseScreen` может зависеть только от:

- Flutter Material;
- `flutter_bloc` как связующий слой представления;
- `TranslatorPhraseCubit`;
- `TranslatorPhraseState`;
- `TranslatorPhraseResult`;
- `TranslatorPhraseStatus`.

`TranslatorPhraseScreen` должен получать `TranslatorPhraseCubit` извне через `BlocProvider` или context.

`TranslatorPhraseScreen` не должен создавать:

- `TranslatorPhraseCubit`;
- `TranslatePhrase`;
- `TranslatorPhraseProvider`;
- `TyphoonTranslatorPhraseProvider`;
- `ApiClient`;
- `AppConfig`.

Запрещено для `TranslatorPhraseScreen`:

- править `main.dart`;
- подключаться в текущий запуск приложения;
- создавать корневую сборку приложения;
- импортировать `features/translator`;
- импортировать старый `TranslatorPage`;
- импортировать старый `TranslatorCubit`;
- импортировать старый `TranslatorState`;
- импортировать старый `TranslationResult`;
- импортировать старый `CanonicalAuditResult`;
- импортировать `RegistryNode`;
- импортировать `TranslatorRepository`;
- импортировать `TranslatorRemoteDataSource`;
- импортировать `RegistryRemoteDataSource`;
- импортировать persistence;
- импортировать хранилище статусов фраз Registry;
- импортировать контроллер фонового выполнения;
- загружать Registry;
- обновлять Registry;
- показывать вкладку Registry;
- показывать дерево Registry;
- показывать поиск, фильтры или статусы Registry;
- хранить историю переводов;
- хранить результаты canonical audit;
- выполнять batch audit;
- создавать operation attachment;
- создавать audit package;
- выполнять mutation;
- выполнять approval;
- выполнять publication.

Отложено:

- кто создаёт `TranslatorPhraseCubit`;
- кто создаёт `TranslatePhrase`;
- где создаётся `TyphoonTranslatorPhraseProvider`;
- корневая сборка приложения;
- изменения `main.dart`;
- замена старого `TranslatorPage`;
- интерфейс загрузки Registry;
- интерфейс operation attachment;
- интерфейс mutation, approval и publication.

Вывод:

- следующий code step может создать изолированный `TranslatorPhraseScreen`;
- следующий code step должен иметь тесты виджета;
- следующий code step не должен править `main.dart`;
- следующий code step не должен создавать подключение во время запуска;
- следующий code step не должен создавать провайдер или корневую сборку приложения;
- после code step нужна контрольная точка реализации в Guard.

## Контрольная точка реализации TranslatorPhraseScreen

Изолированный экран слоя представления Translator реализован.

Коммит реализации:

- `4cfcc48 feat: add translator phrase screen`.

Добавлены:

- `lib/registry_studio/translator/presentation/screens/translator_phrase_screen.dart`;
- `test/registry_studio/translator/presentation/screens/translator_phrase_screen_test.dart`.

Реализованная ответственность `TranslatorPhraseScreen`:

- показывает поле для выбранной инженером формулировки или текста;
- показывает optional поле для language hint;
- показывает optional поле для engineering context;
- вызывает `TranslatorPhraseCubit.translatePhrase`;
- вызывает `TranslatorPhraseCubit.clear`;
- показывает состояние загрузки;
- показывает текущий `TranslatorPhraseResult`;
- показывает текущее сообщение ошибки слоя представления;
- показывает read-only результат по RU, EN, TH и reverse-check полям;
- показывает статус `TranslatorPhraseStatus` в виде текста слоя представления.

Подтверждённые ограничения:

- `main.dart` не изменён;
- подключение во время запуска не добавлено;
- корневая сборка приложения не создана;
- `TranslatorPhraseCubit` не создаётся внутри экрана;
- `TranslatePhrase` не создаётся внутри экрана;
- `TranslatorPhraseProvider` не создаётся внутри экрана;
- `TyphoonTranslatorPhraseProvider` не создаётся внутри экрана;
- `ApiClient` не создаётся внутри экрана;
- `AppConfig` не создаётся внутри экрана;
- экран получает `TranslatorPhraseCubit` извне через `BlocProvider` или context.

Старый слой Translator не возвращён:

- `features/translator` не импортирован;
- старый `TranslatorPage` не импортирован;
- старый `TranslatorCubit` не импортирован;
- старый `TranslatorState` не импортирован;
- старый `TranslationResult` не импортирован;
- старый `CanonicalAuditResult` не импортирован;
- `RegistryNode` не импортирован;
- `TranslatorRepository` не импортирован;
- `TranslatorRemoteDataSource` не импортирован;
- `RegistryRemoteDataSource` не импортирован;
- persistence не импортирован;
- хранилище статусов фраз Registry не импортировано;
- контроллер фонового выполнения не импортирован.

Запрещённые функции не появились:

- загрузка Registry не добавлена;
- обновление Registry не добавлено;
- вкладка Registry не добавлена;
- дерево Registry не добавлено;
- поиск, фильтры и статусы Registry не добавлены;
- история переводов не добавлена;
- результаты canonical audit не добавлены;
- batch audit не добавлен;
- operation attachment не создан;
- audit package не создан;
- mutation path не создан;
- approval path не создан;
- publication path не создан.

Проверки шага реализации:

- целевой `dart analyze` для screen/test прошёл clean;
- полный `flutter analyze` прошёл clean;
- production screen forbidden check прошёл;
- test legacy forbidden check прошёл;
- scope check прошёл;
- widget tests созданы.

Ограничение локальной проверки:

- локальный `flutter test` не запускался из-за известного риска Termux `libvk_swiftshader.so`;
- тестовый файл добавлен для CI или среды, где Flutter widget tests запускаются штатно.

Текущее состояние после реализации:

- чистый Translator имеет result object;
- чистый Translator имеет use case;
- чистый Translator имеет provider boundary;
- чистый Translator имеет Typhoon infrastructure adapter;
- чистый Translator имеет presentation Cubit/State;
- чистый Translator имеет isolated presentation screen;
- runtime wiring всё ещё отсутствует;
- текущий `main.dart` всё ещё остаётся старым bootstrap и не является clean Registry Studio composition root.

Перед следующим code step требуется отдельный аудит владения ответственностью:

- кто создаёт `TranslatorPhraseCubit`;
- кто создаёт `TranslatePhrase`;
- где создаётся `TyphoonTranslatorPhraseProvider`;
- где должна жить корневая сборка чистого Registry Studio Translator;
- можно ли создавать отдельный clean app entry point;
- нужно ли трогать текущий `main.dart`;
- почему следующее подключение не возвращает старый `TranslatorPage`;
- почему следующее подключение не создаёт загрузку Registry;
- почему следующее подключение не создаёт operation attachment;
- почему следующее подключение не создаёт mutation, approval или publication.

## Контрольная точка удаления legacy Translator MVP

Legacy Translator MVP удалён из clean rebuild ветки.

Коммит реализации:

- `1dcd3c8 refactor: remove legacy translator mvp`.

Удалены legacy runtime и feature files:

- `lib/features/translator/**`;
- `lib/core/background/android_foreground_service_controller.dart`;
- `lib/core/background/background_execution_controller.dart`;
- `lib/core/persistence/translator_state_persistence.dart`;
- `lib/core/persistence/registry_phrase_status_persistence.dart`.

Переписан:

- `lib/main.dart`.

Новое состояние `lib/main.dart`:

- временный нейтральный Flutter entrypoint;
- не создаёт clean runtime composition;
- не создаёт `TranslatorPhraseCubit`;
- не создаёт `TranslatePhrase`;
- не создаёт `TyphoonTranslatorPhraseProvider`;
- не открывает `TranslatorPhraseScreen`;
- не содержит `Helpy` naming;
- не импортирует старый Translator;
- не импортирует `features/translator`;
- не импортирует Registry loading;
- не содержит mutation / approval / publication path.

Причина сохранения `lib/main.dart`:

- Flutter default build ожидает `lib/main.dart`;
- файл оставлен только как временная техническая заглушка;
- файл должен быть заменён после отдельного ownership-аудита clean runtime composition;
- текущая заглушка не является архитектурным app shell, composition root, bootstrap entity или runtime boundary.

Подтверждённые удаления:

- `HelpyTranslatorApp` удалён;
- старый `TranslatorPage` удалён;
- старый `TranslatorCubit` удалён;
- старый `TranslatorState` удалён;
- старый `TranslationResult` удалён;
- старый `CanonicalAuditResult` удалён;
- старый `RegistryNode` удалён;
- старый `TranslatorRepository` удалён;
- старый `TranslatorRemoteDataSource` удалён;
- старый `RegistryRemoteDataSource` удалён;
- старый `TranslateCanonicalPhrase` удалён;
- старый `AuditCanonicalClientRules` удалён;
- старый `LoadCanonicalClientRules` удалён;
- старый `LoadRegistryTree` удалён;
- old persistence удалён;
- old background execution controller удалён.

Проверки шага:

- legacy symbols отсутствуют в `lib` и `test`;
- `lib/main.dart` нейтрален;
- clean Registry Studio production naming clean;
- `Core` не импортирует `Translator`;
- clean `Translator` не импортирует legacy/product-specific names;
- targeted `dart analyze` прошёл clean;
- full `flutter analyze` прошёл clean.

Ограничение проверки:

- `flutter build apk --debug` в этом шаге не запускался.

Текущее состояние после удаления:

- clean Registry Studio hierarchy остаётся в `lib/registry_studio/**`;
- clean Translator stack остаётся в `lib/registry_studio/translator/**`;
- shared infrastructure `AppConfig` и `ApiClient` сохранены;
- текущий runtime не подключён;
- текущий `lib/main.dart` является временной заглушкой до отдельного clean runtime composition решения.

Запрещено после этого шага:

- возвращать `lib/features/translator`;
- возвращать `HelpyTranslatorApp`;
- возвращать старый `TranslatorPage`;
- возвращать старый `TranslatorCubit`;
- возвращать старую Registry tree loading модель;
- использовать old persistence/background execution;
- смешивать clean Translator с legacy runtime;
- создавать runtime composition без отдельного ownership-аудита.

## Контрольная точка CI после удаления legacy Translator MVP

Clean rebuild ветка подтверждена через GitHub Actions после удаления legacy Translator MVP.

Подтверждённый commit:

- `196e44c test: stabilize translator phrase presentation tests`.

CI run:

- workflow: `build-apk.yml`;
- run: `29048121635`;
- GitHub Actions title: `Build APK #97`;
- branch: `registry-studio/clean-rebuild`;
- status: `Success`;
- duration: `5m 18s`;
- artifacts: `1`.

Что проверено CI:

- `flutter analyze` прошёл;
- `flutter test` прошёл;
- `flutter build apk --debug` прошёл;
- debug APK artifact создан.

Причина предыдущего CI failure:

- production code не был причиной failure;
- failure был в presentation tests;
- `TranslatorPhraseCubit` tests отменяли stream subscription слишком рано и могли видеть только loading state;
- `TranslatorPhraseScreen` test использовал неоднозначный text finder, потому что одинаковый текст отображался в RU и reverse-check поле.

Исправление tests:

- `TranslatorPhraseCubit` tests теперь используют `expectLater` и `emitsInOrder`;
- `TranslatorPhraseScreen` test проверяет точное поле `RU`;
- production code не изменялся;
- runtime composition не добавлялся;
- legacy code не возвращался.

Подтверждённое состояние после CI:

- legacy `lib/features/translator/**` отсутствует;
- legacy `HelpyTranslatorApp` отсутствует;
- legacy `TranslatorPage` отсутствует;
- legacy `TranslatorCubit` отсутствует;
- legacy Registry tree loading отсутствует;
- old persistence/background execution отсутствуют;
- clean Registry Studio hierarchy остаётся в `lib/registry_studio/**`;
- temporary neutral `lib/main.dart` остаётся только технической заглушкой;
- clean runtime composition всё ещё не подключён.

Ограничение локальной Termux проверки:

- локальный `flutter build apk --debug` в Termux был заблокирован toolchain issue `aapt2` x86_64 vs AARCH64;
- это не являлось ошибкой проекта;
- GitHub Actions подтвердил APK build в нормальной Linux build environment.

Следующее ограничение:

- следующий runtime step требует отдельного ownership-аудита clean runtime composition;
- нельзя возвращать legacy Translator runtime;
- нельзя создавать app shell/composition root без отдельного решения;
- нельзя подключать mutation / approval / publication path через Translator.

## Контрольная точка Build APK #100

Clean rebuild ветка подтверждена финальным GitHub Actions build после удаления legacy Translator MVP, стабилизации presentation tests, удаления legacy GitHub registry config и обновления workflow actions.

Подтверждённый финальный документационный commit:

- `a1a5e13 docs: record build apk 100 success`.

Подтверждённый workflow maintenance commit:

- `704b5b7 ci: update artifact actions for node 24`.

CI run:

- workflow: `build-apk.yml`;
- GitHub Actions title: `Build APK #100`;
- run: `29052706699`;
- job: `86237041000`;
- branch: `registry-studio/clean-rebuild`;
- commit under build: `704b5b7`;
- status: `Success`;
- artifact: `helpy-translator-debug-apk`.

Что проверено в `Build APK #100`:

- `Analyze` прошёл;
- `Test` прошёл;
- `Build debug APK` прошёл;
- `Upload APK` прошёл;
- debug APK artifact создан.

Что закрыто этим build:

- legacy `lib/features/translator/**` не возвращён;
- legacy `TranslatorPage` не возвращён;
- legacy `TranslatorCubit` не возвращён;
- legacy Registry tree loading не возвращён;
- old persistence/background execution не возвращены;
- clean Registry Studio hierarchy остаётся в `lib/registry_studio/**`;
- clean Translator stack остаётся в `lib/registry_studio/translator/**`;
- `lib/main.dart` остаётся временной нейтральной заглушкой;
- clean runtime composition всё ещё не подключён.

Workflow warning status:

- предупреждение Node.js 20 было закрыто workflow maintenance commit `704b5b7`;
- `.github/workflows/build-apk.yml` обновлён с `actions/checkout@v4` на `actions/checkout@v5`;
- `.github/workflows/build-apk.yml` обновлён с `actions/upload-artifact@v4` на `actions/upload-artifact@v6`.

Локальные Termux build/test ограничения остаются внешними toolchain-ограничениями:

- `flutter test` в Termux может падать из-за `libvk_swiftshader.so`;
- `flutter build apk --debug` в Termux может падать из-за `aapt2` x86_64 vs AARCH64;
- эти ограничения не являются ошибкой проекта;
- GitHub Actions является подтверждающей средой для APK build.

Следующее ограничение:

- перед runtime step всё ещё требуется отдельный ownership-аудит clean runtime composition;
- нельзя возвращать legacy Translator runtime;
- нельзя создавать app shell/composition root без отдельного решения;
- нельзя подключать mutation / approval / publication path через Translator.

## Ownership-аудит clean runtime composition

После `Build APK #100` выполнен аудит возможности заменить временную нейтральную `lib/main.dart` заглушку на clean runtime composition.

Фактическое состояние перед решением:

- ветка синхронизирована с `origin/registry-studio/clean-rebuild`;
- рабочее дерево clean;
- HEAD: `09e6bd2 docs: add build apk 100 guard checkpoint`;
- `Build APK #100` подтверждён как successful;
- legacy Translator MVP удалён;
- legacy GitHub registry config удалён из code/test surface;
- `lib/main.dart` сейчас является временной технической заглушкой;
- clean runtime composition отсутствует;
- clean `TranslatorPhraseScreen` уже реализован;
- clean `TranslatorPhraseCubit` уже реализован;
- clean `TranslatePhrase` уже реализован;
- clean `TyphoonTranslatorPhraseProvider` уже реализован;
- `AppConfig` является Typhoon-only config;
- `ApiClient` является Typhoon API client;
- `Core` не зависит от `Translator`;
- clean `Translator` не импортирует legacy runtime.

Решение:

- временную `lib/main.dart` заглушку можно заменить в следующем code step;
- замена `lib/main.dart` должна быть только clean runtime composition;
- `lib/main.dart` становится default Flutter entrypoint и владельцем создания infrastructure/application dependency graph;
- `lib/main.dart` не становится domain layer, application use case, registry workflow, orchestrator, bootstrap abstraction или generic composition service.

Разрешённый production surface следующего code step:

- `lib/main.dart`;
- `lib/registry_studio/translator/presentation/app/registry_studio_translator_app.dart`.

Разрешённый test surface следующего code step:

- `test/registry_studio/translator/presentation/app/registry_studio_translator_app_test.dart`.

Ответственность `lib/main.dart`:

- вызвать `WidgetsFlutterBinding.ensureInitialized`;
- загрузить `.env` через `dotenv.load(fileName: '.env')`;
- создать `AppConfig` через `AppConfig.fromEnv`;
- создать `ApiClient`;
- создать `TyphoonTranslatorPhraseProvider`;
- создать `TranslatePhrase`;
- передать `TranslatePhrase` в clean Flutter app shell;
- вызвать `runApp`.

`lib/main.dart` не должен:

- создавать `RegistryEntity`;
- создавать `RegistryEngineeringOperation`;
- читать или загружать Registry tree;
- создавать Registry search/filter/status UI;
- создавать operation attachment;
- создавать audit package;
- выполнять mutation;
- выполнять approval;
- выполнять publication;
- импортировать `features/translator`;
- возвращать старый `TranslatorPage`;
- возвращать старый `TranslatorCubit`;
- возвращать старый `TranslatorRepository`;
- возвращать старый `RegistryNode`;
- возвращать old persistence/background execution;
- создавать generic `CompositionRoot`, `Bootstrap`, `Manager`, `Facade`, `Bridge`, `Locator`, helper или factory shortcut.

Ответственность `RegistryStudioTranslatorApp`:

- быть малым Flutter app shell для clean Translator runtime;
- принимать готовый `TranslatePhrase`;
- создать `TranslatorPhraseCubit` через `BlocProvider`;
- открыть `TranslatorPhraseScreen`;
- владеть только presentation-level app wiring;
- закрывать `TranslatorPhraseCubit` через lifecycle `BlocProvider.create`.

`RegistryStudioTranslatorApp` не должен:

- читать `.env`;
- создавать `AppConfig`;
- создавать `ApiClient`;
- создавать `TyphoonTranslatorPhraseProvider`;
- выполнять HTTP;
- знать Typhoon model/request/response/prompt details;
- загружать Registry;
- создавать operation;
- выполнять mutation;
- выполнять approval;
- выполнять publication.

Причина вынесения `RegistryStudioTranslatorApp` из `main.dart`:

- `main.dart` остаётся entrypoint и infrastructure composition boundary;
- Flutter app shell получает отдельную presentation responsibility;
- `TranslatorPhraseScreen` продолжает получать `TranslatorPhraseCubit` извне;
- screen не начинает создавать dependencies;
- runtime wiring тестируется через app shell без запуска real Typhoon infrastructure;
- это не generic helper/wrapper, а явная Flutter presentation app boundary.

Запрещённые имена для следующего code step:

- `RegistryStudioCompositionRoot`;
- `TranslatorPhraseCompositionRoot`;
- `RegistryStudioBootstrap`;
- `TranslatorPhraseBootstrap`;
- `RegistryStudioManager`;
- `TranslatorManager`;
- `RegistryStudioFacade`;
- `TranslatorFacade`;
- `RegistryStudioLocator`;
- `TranslatorLocator`;
- `createTranslatorPhraseCubit`;
- `createTranslatePhrase`;
- `createTyphoonTranslatorPhraseProvider`.

Разрешённое имя app shell:

- `RegistryStudioTranslatorApp`.

Почему это не возвращает legacy runtime:

- dependency graph строится из clean classes only;
- старый `features/translator` отсутствует;
- старый `TranslatorPage` отсутствует;
- старый `TranslatorCubit` отсутствует;
- старый `RegistryNode` отсутствует;
- старый repository/data source stack отсутствует;
- old persistence/background execution отсутствуют;
- Registry tree loading не создаётся.

Почему это не нарушает `Core`:

- `Core` не импортирует `Translator`;
- runtime entrypoint может импортировать clean Translator как внешний consumer;
- `Translator` остаётся outside Core;
- runtime composition не меняет domain или application contracts Core.

Проверки следующего code step обязательны:

- scope check только для `lib/main.dart`, `RegistryStudioTranslatorApp` и его test;
- forbidden legacy checks;
- `Core` must not import `Translator`;
- clean `Translator` must not import legacy;
- `dart analyze` для изменённых файлов;
- full `flutter analyze`;
- targeted app shell widget test должен быть создан;
- local `flutter test` в Termux не обязателен из-за known `libvk_swiftshader.so`;
- финальное подтверждение через GitHub Actions после push.

Вывод:

- следующий code step может заменить временную `lib/main.dart` заглушку на clean runtime composition;
- следующий code step должен добавить `RegistryStudioTranslatorApp`;
- следующий code step не должен создавать Registry workflow, mutation, approval или publication path;
- следующий code step не должен возвращать legacy Translator runtime.

## Контрольная точка clean runtime composition CI

Clean runtime composition подключён и подтверждён через GitHub Actions.

Коммиты:

- `28b5e20 feat: wire clean translator runtime composition`;
- `6bf0bb6 test: stabilize clean translator app wiring test`.

CI run:

- workflow: `build-apk.yml`;
- GitHub Actions title: `Build APK`;
- run: `29059514146`;
- job: `86258069547`;
- branch: `registry-studio/clean-rebuild`;
- head: `6bf0bb6`;
- status: `Success`;
- duration: `5m45s`;
- artifact: `helpy-translator-debug-apk`.

Что подтверждено:

- `flutter analyze` прошёл;
- `flutter test` прошёл;
- `flutter build apk --debug` прошёл;
- `Upload APK` прошёл;
- debug APK artifact создан.

Архитектурное состояние:

- временная `lib/main.dart` заглушка заменена на clean runtime composition;
- `RegistryStudioTranslatorApp` добавлен как малый Flutter app shell;
- `TranslatorPhraseScreen` открывается через clean dependency graph;
- `TranslatorPhraseCubit` создаётся в app shell через `BlocProvider`;
- `TranslatePhrase` создаётся в runtime composition;
- `TyphoonTranslatorPhraseProvider` создаётся в runtime composition;
- `AppConfig` остаётся Typhoon-only;
- `ApiClient` остаётся infrastructure client;
- `Core` не зависит от `Translator`;
- clean `Translator` не импортирует legacy runtime.

Что не появилось:

- legacy `features/translator`;
- старый `TranslatorPage`;
- старый `TranslatorCubit`;
- старый `TranslatorRepository`;
- старый `RegistryNode`;
- Registry tree loading;
- operation attachment;
- audit package;
- mutation path;
- approval path;
- publication path;
- old persistence/background execution.

Вывод:

- clean runtime composition закрыт;
- APK теперь открывает clean Translator runtime вместо временной заглушки;
- следующий шаг должен снова начинаться с ownership-аудита, а не с расширения runtime по инерции.

## Ownership-аудит operation creation presentation existing-fit

После clean runtime composition выполнен ownership-аудит первого Registry Studio operation creation presentation step.

Проверенный вопрос:

- нужна ли новая domain/application entity/model для первого screen skeleton создания `RegistryEngineeringOperation`.

Ответ:

- новая domain entity не нужна;
- новая application model не нужна;
- новая result model не нужна;
- новая draft/input/context/view model не нужна;
- существующий Core contract достаточен.

Existing Core contract, который уже закрывает responsibility:

- `RegistryEngineeringOperationId` владеет stable operation identity;
- `RegistryEngineeringOperation` владеет lifecycle snapshot;
- `RegistryEngineeringOperationStatus` владеет lifecycle marker;
- `CreateRegistryEngineeringOperation` владеет application creation boundary.

Достаточные inputs первого presentation step:

- вручную введённый engineer `RegistryEngineeringOperationId`;
- вручную введённый engineer `problemStatement`.

Достаточный output первого presentation step:

- in-memory `RegistryEngineeringOperation`.

Почему новая model/entity отклонена:

- `CreateRegistryEngineeringOperation` уже принимает `RegistryEngineeringOperationId` и `problemStatement`;
- `CreateRegistryEngineeringOperation` уже возвращает `RegistryEngineeringOperation`;
- `RegistryEngineeringOperation` уже нормализует `problemStatement`;
- `RegistryEngineeringOperation` уже отклоняет empty `problemStatement`;
- initial status policy уже утверждена как `RegistryEngineeringOperationStatus.open`;
- отдельный result object был ранее отклонён как premature modeling;
- operation attachment boundary ранее отклонён;
- отдельный operation context/input/audit package ранее запрещён для текущего этапа.

Разрешённый production surface следующего code step:

- `lib/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart`.

Разрешённый test surface следующего code step:

- `test/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen_test.dart`.

Ответственность `RegistryEngineeringOperationCreationScreen`:

- быть isolated presentation consumer существующего `CreateRegistryEngineeringOperation`;
- дать engineer поле для operation id;
- дать engineer поле для problem statement;
- вызвать переданный извне `CreateRegistryEngineeringOperation`;
- создать in-memory `RegistryEngineeringOperation`;
- показать operation id;
- показать normalized problem statement;
- показать initial status `open`;
- показать presentation error при пустом id или пустом problem statement.

`RegistryEngineeringOperationCreationScreen` не является:

- domain entity;
- application model;
- application use case;
- orchestrator;
- workflow executor;
- helper;
- wrapper;
- manager;
- facade;
- bridge;
- locator;
- runtime composition boundary.

Запрещено в следующем code step:

- создавать `RegistryEngineeringOperationInput`;
- создавать `RegistryEngineeringOperationDraft`;
- создавать `RegistryEngineeringOperationViewModel`;
- создавать `RegistryEngineeringOperationContext`;
- создавать `RegistryEngineeringOperationAuditPackage`;
- создавать Cubit/Bloc без отдельного ownership-аудита;
- создавать repository/store/persistence;
- создавать id generator/uuid service;
- создавать routing/navigation;
- менять `main.dart`;
- менять `RegistryStudioTranslatorApp`;
- импортировать Translator;
- импортировать Typhoon;
- импортировать `ApiClient`;
- импортировать `AppConfig`;
- загружать Registry tree;
- искать Registry items;
- attach-ить primary entity;
- attach-ить related context;
- выполнять status transition;
- выполнять mutation;
- выполнять approval;
- выполнять publication.

Dependency direction:

- operation presentation может импортировать Core application/domain;
- Core не должен импортировать operation presentation;
- Core не должен импортировать Translator;
- operation presentation не должен импортировать Translator.

Вывод:

- следующий code step может создать только isolated `RegistryEngineeringOperationCreationScreen`;
- следующий code step должен использовать существующий `CreateRegistryEngineeringOperation`;
- следующий code step не должен создавать новую domain/application model;
- следующий code step не должен подключать screen в runtime.

## Контрольная точка экрана создания инженерной операции

Экран создания `RegistryEngineeringOperation` реализован и подтверждён через GitHub Actions.

Связанные коммиты:

- `c0b6623 docs: define operation creation presentation ownership`;
- `bb57a5a feat: add registry operation creation screen`.

Подтверждение CI:

- workflow: `build-apk.yml`;
- название workflow: `Build APK`;
- run: `29061446439`;
- job: `86263991599`;
- branch: `registry-studio/clean-rebuild`;
- head: `bb57a5a`;
- результат: `Success`;
- длительность: `5m7s`;
- artifact: `helpy-translator-debug-apk`.

CI подтвердил:

- `flutter analyze` прошёл;
- `flutter test` прошёл;
- `flutter build apk --debug` прошёл;
- загрузка artifact прошла;
- artifact debug APK создан.

Реализованные файлы:

- экран: `lib/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart`;
- тест: `test/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen_test.dart`.

Закрытая ответственность экрана:

- экран изолирован от среды выполнения и использует существующий `CreateRegistryEngineeringOperation`;
- инженер вручную вводит `RegistryEngineeringOperationId`;
- инженер вручную вводит `problemStatement`;
- экран создаёт только временный объект `RegistryEngineeringOperation` в памяти;
- экран показывает id операции;
- экран показывает нормализованный problem statement;
- экран показывает начальный status `open`;
- экран показывает ошибку отображения при пустом id;
- экран показывает ошибку отображения при пустом problem statement.

Подтверждённые запреты:

- новая domain entity не создана;
- новая application model не создана;
- Cubit/Bloc не создан;
- repository/store/persistence не созданы;
- id generator/uuid service не созданы;
- routing/navigation не созданы;
- подключение к среде выполнения не добавлено;
- `main.dart` не изменён;
- `RegistryStudioTranslatorApp` не изменён;
- Translator не импортирован;
- Typhoon не импортирован;
- `AppConfig` не импортирован;
- `ApiClient` не импортирован;
- загрузка Registry tree не создана;
- mutation path не создан;
- approval path не создан;
- publication path не создан.

Вывод:

- экран создания инженерной операции закрыт как первый изолированный слой отображения;
- следующий шаг снова должен начинаться с аудита соответствия существующему контракту и ownership-аудита;
- экран нельзя подключать к среде выполнения без отдельного ownership-аудита.

## Ownership-аудит верхней оболочки приложения Registry Studio

После закрытия экрана создания инженерной операции выполнен аудит владельца подключения нескольких экранов Registry Studio к среде выполнения.

Фактическое состояние перед решением:

- HEAD: `cf93e65 docs: record operation creation screen ci success`;
- ветка синхронизирована с `origin/registry-studio/clean-rebuild`;
- рабочее дерево clean;
- `dart analyze` прошёл;
- `flutter analyze` прошёл;
- `Core` не импортирует presentation или Translator;
- operation presentation не импортирует Translator, Typhoon, `AppConfig` или `ApiClient`;
- translator app shell не импортирует operation;
- текущий `lib/main.dart` запускает только `RegistryStudioTranslatorApp`;
- общего app shell для Registry Studio сейчас нет;
- `RegistryEngineeringOperationCreationScreen` существует, но намеренно не подключён к среде выполнения.

Проверенные кандидаты на владение подключением экранов:

1. `lib/main.dart`.

Вывод:

- подходит как точка запуска Flutter;
- подходит как место создания infrastructure/application dependency graph;
- не подходит как владелец экранов;
- не подходит как владелец верхнего UI-переключения;
- не должен становиться workflow executor, orchestrator, generic composition service или navigation owner.

2. `RegistryStudioTranslatorApp`.

Вывод:

- подходит только как утверждённый малый shell clean Translator runtime;
- владеет только созданием `TranslatorPhraseCubit` и открытием `TranslatorPhraseScreen`;
- не подходит как владелец operation screen;
- не должен создавать operation;
- не должен становиться общей оболочкой Registry Studio.

3. `TranslatorPhraseScreen`.

Вывод:

- подходит только как изолированный экран Translator;
- не является корневой сборкой приложения;
- не создаёт dependency graph;
- не подходит как владелец подключения других экранов.

4. `RegistryEngineeringOperationCreationScreen`.

Вывод:

- подходит только как изолированный экран создания `RegistryEngineeringOperation`;
- не является runtime composition boundary;
- не должен создавать routing/navigation;
- не должен подключать себя к среде выполнения.

5. `CreateRegistryEngineeringOperation` и `RegistryEngineeringOperation`.

Вывод:

- подходят только как Core application/domain responsibility;
- не должны знать Flutter;
- не должны импортировать presentation;
- не подходят как владельцы UI-подключения.

6. Существующий общий Registry Studio app shell.

Вывод:

- не найден;
- совпадения поиска по `application` являются шумом;
- единственный существующий app shell — `RegistryStudioTranslatorApp`, и он Translator-specific.

Решение:

- прямое подключение `RegistryEngineeringOperationCreationScreen` в `RegistryStudioTranslatorApp` отклонено;
- прямое превращение `lib/main.dart` в владельца экранов отклонено;
- для следующего code step требуется отдельная верхняя Flutter-оболочка приложения Registry Studio;
- имя разрешённой оболочки: `RegistryStudioApp`;
- `RegistryStudioApp` является presentation boundary, а не domain/application model;
- `RegistryStudioApp` не является helper, wrapper, manager, facade, bridge, locator, bootstrap или composition root;
- `RegistryStudioApp` владеет только верхним Flutter отображением и переключением между уже утверждёнными экранами.

Разрешённый production surface следующего code step:

- `lib/main.dart`;
- `lib/registry_studio/presentation/app/registry_studio_app.dart`;
- удаление `lib/registry_studio/translator/presentation/app/registry_studio_translator_app.dart`, если его ответственность полностью заменена `RegistryStudioApp`.

Разрешённый test surface следующего code step:

- `test/registry_studio/presentation/app/registry_studio_app_test.dart`;
- удаление `test/registry_studio/translator/presentation/app/registry_studio_translator_app_test.dart`, если `RegistryStudioTranslatorApp` удалён.

Ответственность `RegistryStudioApp`:

- быть верхней Flutter-оболочкой Registry Studio;
- принимать готовый `TranslatePhrase`;
- принимать готовый `CreateRegistryEngineeringOperation`;
- создавать `TranslatorPhraseCubit` только для `TranslatorPhraseScreen`;
- передавать `CreateRegistryEngineeringOperation` в `RegistryEngineeringOperationCreationScreen`;
- открывать `TranslatorPhraseScreen`;
- открывать `RegistryEngineeringOperationCreationScreen`;
- владеть только локальным UI-состоянием выбора текущего экрана;
- показывать engineer понятный выбор между Translator и созданием инженерной операции.

`RegistryStudioApp` не должен:

- читать `.env`;
- создавать `AppConfig`;
- создавать `ApiClient`;
- создавать `TyphoonTranslatorPhraseProvider`;
- выполнять HTTP;
- знать Typhoon request/response/prompt details;
- создавать `RegistryEngineeringOperation` до действия engineer;
- генерировать operation id;
- создавать repository/store/persistence;
- загружать Registry tree;
- искать Registry items;
- attach-ить primary entity;
- attach-ить related context;
- выполнять status transition;
- выполнять mutation;
- выполнять approval;
- выполнять publication;
- принимать semantic decisions;
- принимать canonicalization decisions;
- создавать `Navigator`, `routes` или `onGenerateRoute` в первом шаге;
- создавать Cubit/Bloc для верхнего выбора экрана без отдельного ownership-аудита.

Ответственность `lib/main.dart` после следующего code step:

- остаться точкой запуска Flutter;
- загрузить `.env`;
- создать `AppConfig`;
- создать `ApiClient`;
- создать `TyphoonTranslatorPhraseProvider`;
- создать `TranslatePhrase`;
- создать stateless `CreateRegistryEngineeringOperation`;
- передать готовые dependencies в `RegistryStudioApp`;
- вызвать `runApp`.

`lib/main.dart` не должен:

- создавать `RegistryEngineeringOperation`;
- выполнять `CreateRegistryEngineeringOperation` до действия engineer;
- владеть экранным переключением;
- владеть UI-state;
- загружать Registry tree;
- выполнять mutation;
- выполнять approval;
- выполнять publication;
- становиться generic composition abstraction.

Причина замены `RegistryStudioTranslatorApp`:

- прежний app shell был корректен для одного Translator screen;
- после появления operation screen он становится слишком узким владельцем среды выполнения;
- расширять `RegistryStudioTranslatorApp` до operation responsibility нельзя, потому что это смешивает Translator capability и Registry Studio operation capability;
- сохранять два публичных app shell без необходимости нельзя, потому что это создаёт ложную точку владения;
- `RegistryStudioApp` заменяет только верхнюю presentation responsibility, не меняя Core contracts.

Dependency direction:

- `main.dart` может импортировать `RegistryStudioApp`;
- `RegistryStudioApp` может импортировать Translator presentation/application;
- `RegistryStudioApp` может импортировать operation presentation/application;
- `Core` не должен импортировать `RegistryStudioApp`;
- `Core` не должен импортировать Translator;
- operation presentation не должен импортировать Translator;
- Translator screen не должен импортировать operation screen.

Проверки следующего code step обязательны:

- scope check только для разрешённых production/test files;
- forbidden legacy checks;
- check, что `Core` не импортирует presentation или Translator;
- check, что operation presentation не импортирует Translator;
- check, что Translator screen не импортирует operation;
- check, что `RegistryStudioApp` не создаёт Typhoon infrastructure;
- `dart analyze` для изменённых файлов;
- full `flutter analyze`;
- targeted widget test для `RegistryStudioApp`;
- GitHub Actions `Build APK` после push.

Вывод:

- следующий code step может ввести `RegistryStudioApp`;
- следующий code step может переключить `main.dart` с `RegistryStudioTranslatorApp` на `RegistryStudioApp`;
- следующий code step может удалить `RegistryStudioTranslatorApp`, если его ответственность полностью заменена;
- следующий code step не должен создавать registry loading, repository/store, id generator, routing system, mutation, approval или publication path.

## Уточнение ownership UI-языка Registry Studio

После начала реализации `RegistryStudioApp` уточнено требование к языку интерфейса.

Причина уточнения:

- Registry Studio работает в Thailand context;
- для Thailand context базовыми языками продукта являются RU, EN и TH;
- engineer может работать на RU, EN или TH;
- multilingual Translator capability существует именно из-за необходимости проверять RU/EN/TH wording, reverse-check, consistency и translation drift;
- Typhoon translator provider используется как практический provider для RU/EN/TH translation capability;
- наличие Translator capability не означает, что Translator владеет UI-языком Registry Studio;
- верхняя оболочка приложения не должна быть RU-only;
- выбор языка не должен применяться только к верхним кнопкам;
- выбранный UI-язык должен применяться ко всему Registry Studio UI, который входит в текущую среду выполнения.

Решение:

- UI-язык Registry Studio является presentation-level runtime state;
- UI-язык не является Core domain model;
- UI-язык не является Translator capability;
- UI-язык не является semantic language of registry content;
- UI-язык не является source/original content language;
- UI-язык не является spoken language matching;
- UI-язык не должен использоваться для semantic decisions, canonicalization decisions, registry mutation, approval или publication;
- `RegistryStudioApp` владеет выбором текущего UI-языка;
- `RegistryStudioApp` должен передавать выбранный UI-язык во все Registry Studio screens, которые он открывает;
- каждый screen должен получать UI-язык извне и показывать свои labels на выбранном языке.

Разрешённые UI-языки первого шага:

- RU;
- EN;
- TH.

Разрешённая production responsibility следующего code step:

- ввести presentation-level UI language value для Registry Studio;
- ввести presentation-level labels для `RegistryStudioApp`;
- ввести presentation-level labels для `TranslatorPhraseScreen`;
- ввести presentation-level labels для `RegistryEngineeringOperationCreationScreen`;
- передавать выбранный UI-язык из `RegistryStudioApp` в `TranslatorPhraseScreen`;
- передавать выбранный UI-язык из `RegistryStudioApp` в `RegistryEngineeringOperationCreationScreen`.

Запрещено в следующем code step:

- создавать Core entity/model для UI-языка;
- переносить UI-язык в Translator domain/application;
- использовать Translator как source of truth для UI labels;
- создавать полноценную localization/i18n architecture;
- подключать `.arb`, generated localization или platform locale до отдельного ownership-аудита;
- сохранять UI-язык в persistence/store;
- создавать repository/service/provider для UI labels;
- создавать Cubit/Bloc для UI-языка без отдельного ownership-аудита;
- смешивать UI language с source language, target language, original content language или spoken language;
- оставлять новый Registry Studio runtime UI только на русском языке;
- переводить только верхние кнопки без передачи языка во внутренние экраны.

Обязательное правило для следующего code step:

- если `RegistryStudioApp` имеет выбор RU/EN/TH, то `TranslatorPhraseScreen` и `RegistryEngineeringOperationCreationScreen` должны получать выбранный UI-язык извне;
- все новые и уже подключённые в runtime Registry Studio labels должны иметь RU/EN/TH варианты;
- technical identifiers, ids, status enum names и code-level values могут оставаться на английском.

Вывод:

- текущий подход, где `RegistryStudioApp` переводит только top-level labels, недостаточен;
- следующий code step должен сделать UI-язык общей presentation boundary для подключённых экранов;
- code step нельзя коммитить, пока подключённые экраны остаются RU-only.

## Build APK # registry studio multilingual app shell success

После commit `ae77533 feat: add registry studio multilingual app shell` GitHub Actions сначала выявил нестабильность одного widget test в `RegistryStudioApp`.

Исправляющие test-only commits:

- `e29b0b4 test: stabilize registry studio app shell test`;
- `24090c3 test: increase registry studio app shell viewport`.

Финальная проверка GitHub Actions:

- workflow: `Build APK`;
- run: `29065196479`;
- job: `86275136378`;
- branch: `registry-studio/clean-rebuild`;
- head commit: `24090c3`;
- conclusion: `success`;
- artifact: `helpy-translator-debug-apk`.

Проверка подтверждает:

- `Analyze` прошёл успешно;
- `Test` прошёл успешно;
- debug APK собран успешно;
- artifact `helpy-translator-debug-apk` загружен успешно.

Закрытый результат code step:

- `RegistryStudioApp` заменил старый `RegistryStudioTranslatorApp`;
- UI-язык Registry Studio вынесен в presentation-level boundary;
- поддержаны RU, EN и TH;
- выбранный UI-язык передаётся в `TranslatorPhraseScreen`;
- выбранный UI-язык передаётся в `RegistryEngineeringOperationCreationScreen`;
- Translator capability не владеет UI-языком;
- Core не владеет UI-языком;
- старый translator-only app shell удалён.

## Ownership-аудит operation status transition presentation consumer

После закрытия multilingual `RegistryStudioApp` выполнен audit следующей presentation responsibility вокруг уже существующего Core use case `TransitionRegistryEngineeringOperationStatus`.

Проверенные candidates:

- `TransitionRegistryEngineeringOperationStatus`;
- `RegistryEngineeringOperation`;
- `RegistryEngineeringOperationStatus`;
- `RegistryEngineeringOperationCreationScreen`;
- `RegistryStudioApp`;
- `main.dart`;
- future operation workspace;
- repository/store;
- operation attachment/readiness/audit package boundaries.

`TransitionRegistryEngineeringOperationStatus` уже владеет application policy смены статуса.

Он не является UI boundary.

`RegistryEngineeringOperation` не должен получать transition methods.

Причина: entity остаётся immutable lifecycle snapshot. Добавление `mark...`, `changeStatus`, `copyWith` или screen-driven behavior превратит entity в workflow executor.

`RegistryEngineeringOperationStatus` не должен владеть UI labels или presentation policy.

Причина: enum является lifecycle marker и не должен становиться UI model, policy object или localization owner.

`RegistryEngineeringOperationCreationScreen` не должен расширяться до общего operation lifecycle workspace.

Причина: экран был утверждён как isolated consumer `CreateRegistryEngineeringOperation`. Добавление lifecycle controls в этот экран смешает creation и status transition presentation responsibility.

`RegistryStudioApp` не должен владеть status transition.

Причина: app shell владеет top-level screen selection и UI-языком, но не выполняет operation action, не хранит operation workspace state и не принимает lifecycle decisions.

`main.dart` не должен владеть status transition.

Причина: runtime composition создаёт dependencies и вызывает `runApp`, но не выполняет operation action до действия engineer.

Repository/store не вводятся в этом step.

Причина: persistence ownership ещё не проходил audit. Следующий presentation consumer должен оставаться in-memory и isolated.

Future operation workspace не вводится в этом step.

Причина: workspace может объединить creation, selected operation, status transition, related context, readiness, audit package и future decision evidence. Это отдельная responsibility и требует отдельного ownership-аудита.

Вывод existing-fit audit:

- существующий Core use case `TransitionRegistryEngineeringOperationStatus` достаточен для application behavior;
- новой Core entity/model/value object/use case не требуется;
- нужен только isolated presentation consumer для existing use case;
- presentation consumer не должен быть подключён в runtime app shell в этом step.

Разрешённая production responsibility следующего code step:

- создать isolated screen `RegistryEngineeringOperationStatusTransitionScreen`;
- screen получает `RegistryStudioUiLanguage` извне;
- screen получает текущий `RegistryEngineeringOperation` извне;
- screen получает `TransitionRegistryEngineeringOperationStatus` извне;
- screen показывает текущий operation snapshot;
- screen позволяет выбрать requested next `RegistryEngineeringOperationStatus`;
- screen вызывает existing `TransitionRegistryEngineeringOperationStatus`;
- screen показывает новый immutable operation snapshot после successful transition;
- screen показывает presentation error при invalid transition.

Разрешённые production files следующего code step:

- `lib/registry_studio/operation/presentation/screens/registry_engineering_operation_status_transition_screen.dart`;
- `lib/registry_studio/presentation/language/registry_studio_ui_labels.dart`.

Разрешённый test file следующего code step:

- `test/registry_studio/operation/presentation/screens/registry_engineering_operation_status_transition_screen_test.dart`.

Запрещено в следующем code step:

- менять `RegistryEngineeringOperation`;
- менять `RegistryEngineeringOperationStatus`;
- менять `TransitionRegistryEngineeringOperationStatus`;
- менять `CreateRegistryEngineeringOperation`;
- менять `RegistryEngineeringOperationCreationScreen`;
- менять `RegistryStudioApp`;
- менять `lib/main.dart`;
- добавлять repository/store/persistence;
- добавлять operation workspace;
- добавлять routing/navigation;
- добавлять Orchestrator, manager, facade, helper, wrapper, bridge, locator или magic utility;
- добавлять readiness computation;
- добавлять related context inspection;
- добавлять Translator dependency;
- добавлять assessment;
- добавлять audit package;
- выполнять registry mutation, approval или publication.

UI language requirement:

- все labels нового screen должны иметь RU/EN/TH варианты;
- UI-язык должен приходить через `RegistryStudioUiLanguage`;
- technical enum values могут отображаться как code-level status names только если label responsibility для human-readable status names не вводится в этом step.

Проверки следующего code step обязательны:

- scope check только для разрешённых files;
- check, что Core не изменён;
- check, что screen не импортирует Translator, AppConfig, ApiClient, Typhoon, repository/store или app shell;
- `dart analyze` для изменённых файлов;
- full `flutter analyze`;
- targeted widget test нового screen;
- `git diff --check`.

Вывод:

- следующий code step может создать isolated presentation consumer для `TransitionRegistryEngineeringOperationStatus`;
- следующий code step не должен подключать этот screen в `RegistryStudioApp`;
- runtime connection требует отдельного ownership-аудита после успешной реализации isolated screen.

## Build APK # operation status transition screen success

Isolated presentation consumer для `TransitionRegistryEngineeringOperationStatus` реализован и подтверждён через GitHub Actions.

Code commit:

- `fa66cb2 feat: add operation status transition screen`.

Финальная проверка GitHub Actions:

- workflow: `Build APK`;
- run: `29066716696`;
- job: `86279715466`;
- branch: `registry-studio/clean-rebuild`;
- head commit: `fa66cb2`;
- conclusion: `success`;
- artifact: `helpy-translator-debug-apk`.

Проверка подтверждает:

- `Analyze` прошёл успешно;
- `Test` прошёл успешно;
- debug APK собран успешно;
- artifact `helpy-translator-debug-apk` загружен успешно.

Закрытый результат code step:

- создан isolated screen `RegistryEngineeringOperationStatusTransitionScreen`;
- screen использует существующий Core use case `TransitionRegistryEngineeringOperationStatus`;
- screen получает `RegistryStudioUiLanguage` извне;
- screen получает `RegistryEngineeringOperation` извне;
- screen получает `TransitionRegistryEngineeringOperationStatus` извне;
- screen показывает текущий operation snapshot;
- screen позволяет выбрать requested next `RegistryEngineeringOperationStatus`;
- screen показывает новый immutable operation snapshot после successful transition;
- screen показывает presentation error при invalid transition;
- labels нового screen имеют RU/EN/TH варианты.

Подтверждённые ограничения:

- `Core` не изменён;
- `RegistryEngineeringOperationCreationScreen` не изменён;
- `RegistryStudioApp` не изменён;
- `lib/main.dart` не изменён;
- runtime connection не добавлен;
- repository/store/persistence не добавлены;
- operation workspace не добавлен;
- routing/navigation не добавлены;
- Translator dependency не добавлена;
- readiness, related context inspection, assessment, audit package, mutation, approval и publication не добавлены.

Следующая точка требует отдельного ownership-аудита перед подключением status transition screen в runtime app shell или перед проектированием operation workspace.

## Ownership-аудит runtime connection для operation status transition screen

После реализации isolated `RegistryEngineeringOperationStatusTransitionScreen` выполнен audit возможности подключить этот экран напрямую в `RegistryStudioApp`.

Проверенные candidates:

- `RegistryStudioApp`;
- `lib/main.dart`;
- `RegistryEngineeringOperationCreationScreen`;
- `RegistryEngineeringOperationStatusTransitionScreen`;
- `CreateRegistryEngineeringOperation`;
- `TransitionRegistryEngineeringOperationStatus`;
- заранее созданная seed operation;
- future selected operation state;
- future operation workspace.

`RegistryEngineeringOperationStatusTransitionScreen` не может быть подключён как независимый третий экран без входной operation.

Причина: экран требует текущий `RegistryEngineeringOperation`. Без выбранной/current operation у него нет корректного runtime input.

`RegistryStudioApp` не должен создавать seed `RegistryEngineeringOperation` для status transition screen.

Причина: app shell уже утверждён как владелец top-level screen selection и UI-языка. Он не должен создавать `RegistryEngineeringOperation` до действия engineer, генерировать operation id или владеть operation lifecycle state.

`lib/main.dart` не должен создавать seed `RegistryEngineeringOperation`.

Причина: runtime composition создаёт dependencies и вызывает `runApp`, но не выполняет operation action и не создаёт domain operation до действия engineer.

`RegistryEngineeringOperationCreationScreen` сейчас не является владельцем selected operation для всего runtime.

Причина: экран является isolated consumer `CreateRegistryEngineeringOperation`; созданная operation хранится локально внутри экрана. Расширение экрана до передачи created operation наружу или до управления transition flow требует отдельного ownership-аудита.

Hardcoded/fake operation для runtime connection отклоняется.

Причина: fake operation сделает экран technically reachable, но не создаст реальный engineering workflow. Это нарушит clean rebuild contract и создаст ложную runtime readiness.

Прямое добавление `TransitionRegistryEngineeringOperationStatus` dependency в `RegistryStudioApp` недостаточно.

Причина: dependency можно передать экрану, но без корректного владельца текущей operation подключение остаётся неправильным. Проблема не в use case wiring, а в ownership selected operation state.

Вывод:

- прямое подключение `RegistryEngineeringOperationStatusTransitionScreen` в `RegistryStudioApp` сейчас отклоняется;
- следующий code step не должен добавлять третью кнопку экрана для status transition;
- следующий code step не должен создавать seed operation в `RegistryStudioApp` или `main.dart`;
- следующий code step не должен менять `RegistryEngineeringOperationCreationScreen` для external callback без отдельного ownership-аудита;
- следующий code step не должен вводить store/repository/persistence/routing/navigation.

Нужная следующая boundary:

- владелец selected/current `RegistryEngineeringOperation` должен быть определён отдельно;
- возможное имя зоны аудита: operation workspace / selected operation presentation state;
- эта boundary должна решить, где живёт created operation после `CreateRegistryEngineeringOperation`;
- эта boundary должна решить, как status transition получает реальную operation;
- эта boundary не должна становиться repository, persistence store, workflow runner, Orchestrator, manager, facade, helper, wrapper, bridge, locator или magic utility.

До отдельного ownership-аудита operation workspace / selected operation state запрещено:

- подключать status transition screen в runtime app shell;
- создавать demo/fake/seed operation для runtime;
- смешивать creation и transition в одном existing screen;
- переносить operation lifecycle state в Core entity;
- добавлять repository/store/persistence;
- добавлять readiness, related context inspection, assessment, audit package, mutation, approval или publication.

Вывод по следующему шагу:

- следующая работа должна быть ownership-аудитом selected/current operation presentation state;
- code step пока не разрешён.

## Ownership-аудит selected/current operation presentation state

После отклонения прямого runtime connection для `RegistryEngineeringOperationStatusTransitionScreen` выполнен audit selected/current operation presentation state.

Проверенные candidates:

- `RegistryStudioApp`;
- `lib/main.dart`;
- `RegistryEngineeringOperationCreationScreen`;
- `RegistryEngineeringOperationStatusTransitionScreen`;
- `RegistryEngineeringOperation`;
- `CreateRegistryEngineeringOperation`;
- `TransitionRegistryEngineeringOperationStatus`;
- callback из creation screen напрямую в app shell;
- `RegistryEngineeringOperationState`;
- repository/store/persistence;
- отдельная presentation boundary operation workspace.

`RegistryStudioApp` не должен владеть selected/current `RegistryEngineeringOperation`.

Причина: app shell уже утверждён как владелец top-level screen selection и UI-языка. Если app shell начнёт хранить current operation, он станет operation workspace state owner и начнёт смешивать top-level shell responsibility с operation lifecycle presentation responsibility.

`lib/main.dart` не должен владеть selected/current `RegistryEngineeringOperation`.

Причина: runtime composition создаёт dependencies и вызывает `runApp`, но не хранит operation lifecycle state и не выполняет operation action.

`RegistryEngineeringOperationCreationScreen` не должен расширяться до общего lifecycle workspace.

Причина: screen утверждён как isolated consumer `CreateRegistryEngineeringOperation`. Он может создать operation, но не должен сам становиться owner всего дальнейшего flow: status transition, related context, readiness, audit package или future decision evidence.

`RegistryEngineeringOperationStatusTransitionScreen` не должен становиться owner creation flow.

Причина: screen утверждён как isolated consumer `TransitionRegistryEngineeringOperationStatus`. Он получает текущую operation извне и выполняет только presentation flow смены статуса.

`RegistryEngineeringOperation` не должен становиться state holder, workflow executor или mutable object.

Причина: entity остаётся immutable lifecycle snapshot. Добавление mutable lifecycle state, callbacks, screen behavior или presentation flags нарушит Core boundary.

`RegistryEngineeringOperationState` отклоняется.

Причина: отдельный state model выглядит как удобная промежуточная модель, но уже был отклонён как лишний shortcut. Current operation в этом шаге является presentation state, а не новой Core/domain entity/model/value object.

Callback из `RegistryEngineeringOperationCreationScreen` напрямую в `RegistryStudioApp` отклоняется.

Причина: callback сам по себе только переносит created operation наружу. Если получателем становится app shell, selected/current operation ownership попадает в неправильную boundary.

Repository/store/persistence не вводятся.

Причина: текущий workflow остаётся in-memory presentation flow. Долговременное хранение operation, восстановление сессии, загрузка operation и multi-operation selection требуют отдельного ownership-аудита.

Вывод existing-fit audit:

- существующие Core use cases достаточны;
- новая Core entity/model/value object/use case не требуется;
- selected/current operation должна жить в отдельной presentation boundary;
- минимальная корректная boundary — `RegistryEngineeringOperationWorkspaceScreen`.

Ответственность `RegistryEngineeringOperationWorkspaceScreen`:

- получать `RegistryStudioUiLanguage` извне;
- получать `CreateRegistryEngineeringOperation` извне;
- получать `TransitionRegistryEngineeringOperationStatus` извне;
- владеть nullable in-memory current `RegistryEngineeringOperation`;
- показывать creation flow, когда current operation отсутствует;
- получать created operation после successful creation;
- показывать status transition flow, когда current operation существует;
- обновлять current operation после successful status transition;
- передавать выбранный UI-язык во внутренние operation screens;
- не создавать operation id самостоятельно;
- не создавать seed/demo/fake operation;
- не выполнять registry mutation, approval или publication.

Разрешённая production responsibility следующего code step:

- создать `RegistryEngineeringOperationWorkspaceScreen`;
- добавить optional presentation callback в `RegistryEngineeringOperationCreationScreen` для передачи created `RegistryEngineeringOperation` после successful creation;
- добавить optional presentation callback в `RegistryEngineeringOperationStatusTransitionScreen` для передачи transitioned `RegistryEngineeringOperation` после successful transition;
- подключить `RegistryEngineeringOperationWorkspaceScreen` в `RegistryStudioApp` вместо прямого открытия `RegistryEngineeringOperationCreationScreen`;
- передать `TransitionRegistryEngineeringOperationStatus` dependency через `main.dart` → `RegistryStudioApp` → `RegistryEngineeringOperationWorkspaceScreen`;
- добавить RU/EN/TH labels только если workspace вводит собственные visible labels.

Разрешённые production files следующего code step:

- `lib/main.dart`;
- `lib/registry_studio/presentation/app/registry_studio_app.dart`;
- `lib/registry_studio/presentation/language/registry_studio_ui_labels.dart`, только если нужны workspace labels;
- `lib/registry_studio/operation/presentation/screens/registry_engineering_operation_workspace_screen.dart`;
- `lib/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart`;
- `lib/registry_studio/operation/presentation/screens/registry_engineering_operation_status_transition_screen.dart`.

Разрешённые test files следующего code step:

- `test/registry_studio/operation/presentation/screens/registry_engineering_operation_workspace_screen_test.dart`;
- `test/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen_test.dart`, только если меняется callback contract;
- `test/registry_studio/operation/presentation/screens/registry_engineering_operation_status_transition_screen_test.dart`, только если меняется callback contract;
- `test/registry_studio/presentation/app/registry_studio_app_test.dart`.

Запрещено в следующем code step:

- менять Core operation entity/use cases/status enum/id;
- создавать `RegistryEngineeringOperationState`;
- создавать repository/store/persistence;
- создавать Cubit/Bloc для operation workspace без отдельного ownership-аудита;
- создавать Navigator/routes/onGenerateRoute;
- создавать manager/facade/helper/wrapper/bridge/locator/magic utility;
- создавать seed/demo/fake operation;
- генерировать operation id в `RegistryStudioApp`, workspace или `main.dart`;
- переносить operation lifecycle state в `RegistryStudioApp`;
- переносить operation lifecycle state в `lib/main.dart`;
- добавлять readiness computation;
- добавлять related context inspection;
- добавлять assessment;
- добавлять audit package;
- выполнять registry mutation, approval или publication;
- добавлять Translator dependency в operation presentation.

Проверки следующего code step обязательны:

- scope check только для разрешённых files;
- check, что Core не изменён;
- check, что `RegistryStudioApp` не хранит `RegistryEngineeringOperation`;
- check, что `main.dart` не создаёт `RegistryEngineeringOperation`;
- check, что operation presentation не импортирует Translator/AppConfig/ApiClient/Typhoon/repository/store;
- `dart analyze` для изменённых файлов;
- full `flutter analyze`;
- targeted widget tests для workspace и app shell;
- `git diff --check`;
- GitHub Actions `Build APK` после push.

Вывод:

- следующий code step может ввести `RegistryEngineeringOperationWorkspaceScreen`;
- следующий code step может подключить workspace в `RegistryStudioApp` как operation entry screen;
- следующий code step не должен подключать `RegistryEngineeringOperationStatusTransitionScreen` напрямую как третий top-level screen;
- selected/current operation state должен остаться внутри operation workspace presentation boundary.

## Build APK # operation workspace presentation flow success

Operation workspace presentation flow закрыт успешным GitHub Actions `Build APK`.

Проверенная commit chain:

- `57c3dd3 feat: add operation workspace presentation flow`;
- `3ee27ad test: stabilize operation workspace creation taps`;
- `68abc6a fix: emit operation creation callback`.

CI proof:

- workflow: `Build APK`;
- run: `29069179505`;
- job: `86286996069`;
- branch: `registry-studio/clean-rebuild`;
- head commit: `68abc6a`;
- conclusion: `success`;
- artifact: `helpy-translator-debug-apk`.

Закрытый результат:

- `RegistryEngineeringOperationWorkspaceScreen` введён как отдельная presentation boundary;
- workspace владеет только nullable in-memory current `RegistryEngineeringOperation`;
- `RegistryStudioApp` не хранит selected/current operation entity;
- `lib/main.dart` не создаёт `RegistryEngineeringOperation`;
- `RegistryEngineeringOperationCreationScreen` отдаёт created operation через optional presentation callback;
- `RegistryEngineeringOperationStatusTransitionScreen` отдаёт transitioned operation через optional presentation callback;
- `RegistryStudioApp` открывает operation workspace вместо прямого creation screen;
- `TransitionRegistryEngineeringOperationStatus` передаётся как dependency через runtime composition;
- Core operation entity/use cases/status enum/id не менялись;
- repository/store/persistence/routing/navigation/Cubit/Bloc не вводились;
- readiness, related context inspection, assessment, audit package, registry mutation, approval и publication не добавлялись.

Проверки перед push:

- scope matched ownership audit;
- Core diff был пустой;
- `RegistryStudioApp` не импортировал и не хранил `RegistryEngineeringOperation`;
- `main.dart` не импортировал и не создавал `RegistryEngineeringOperation`;
- operation presentation не импортировал Translator/AppConfig/ApiClient/Typhoon/repository/store;
- forbidden workspace abstractions отсутствовали;
- targeted `dart analyze` был clean;
- full `flutter analyze` был clean;
- `git diff --check` был clean.

## Ownership-аудит related context presentation consumer

После закрытия operation workspace presentation flow выполнен audit следующего безопасного шага вокруг related context.

Проверенные candidates:

- `RegistryEngineeringOperationWorkspaceScreen`;
- `RegistryEngineeringOperation`;
- `RegistryRelatedContext`;
- `RegistryResolvedRelatedContext`;
- `PrepareRegistryRelatedContext`;
- `PrepareRegistryResolvedRelatedContext`;
- `RegistryStudioApp`;
- `lib/main.dart`;
- repository/store/persistence;
- isolated related context presentation consumer.

Existing-fit audit:

- `PrepareRegistryRelatedContext` уже существует как read-only application use case;
- `RegistryRelatedContext` уже существует как read-only application result;
- `PrepareRegistryResolvedRelatedContext` уже существует как read-only application use case;
- `RegistryResolvedRelatedContext` уже существует как read-only application result;
- новая Core entity/model/value object/use case не требуется;
- существующие Core contracts достаточны для isolated presentation consumer.

`RegistryEngineeringOperationWorkspaceScreen` не должен в следующем step получать related context responsibility.

Причина: workspace сейчас владеет только nullable in-memory current `RegistryEngineeringOperation`. Для related context ему нужны отдельные owners input-ов: primary `RegistryEntity`, `Iterable<RegistryRelation>` и available related `RegistryEntity`. Эти owners ещё не определены. Прямое расширение workspace сейчас превратит его в широкий workflow container.

`RegistryEngineeringOperation` не должен хранить `RegistryRelatedContext` или `RegistryResolvedRelatedContext`.

Причина: operation entity остаётся immutable lifecycle snapshot. Related context является read-only application result и не должен превращать operation entity в audit package, context bundle или workflow container.

`RegistryRelatedContext` и `RegistryResolvedRelatedContext` не являются presentation state.

Причина: это application results. Они не должны знать UI-язык, screen state, selected operation, button actions, navigation или workspace lifecycle.

`PrepareRegistryRelatedContext` и `PrepareRegistryResolvedRelatedContext` не должны становиться presenters.

Причина: это stateless application use cases. Они не должны форматировать UI labels, владеть Flutter state, принимать engineer decision или запускать registry mutation/publication.

`RegistryStudioApp` и `lib/main.dart` не должны подключать related context screen в этом step.

Причина: нет утверждённого owner-а для primary entity selection, relation source, available related entities или operation-to-context connection.

Repository/store/persistence не вводятся.

Причина: текущий шаг не решает загрузку registry graph, entity search, saved context, multi-operation session или durable operation context.

Разрешённая next presentation boundary:

- isolated `RegistryRelatedContextPreparationScreen`.

Ответственность `RegistryRelatedContextPreparationScreen`:

- получать `RegistryStudioUiLanguage` извне;
- получать primary `RegistryEntity` извне;
- получать `Iterable<RegistryRelation>` извне;
- получать available related `Iterable<RegistryEntity>` извне;
- получать `PrepareRegistryRelatedContext` извне;
- получать `PrepareRegistryResolvedRelatedContext` извне;
- вызывать existing Core use cases только по explicit engineer action;
- показывать prepared `RegistryRelatedContext`;
- показывать prepared `RegistryResolvedRelatedContext`;
- показывать matched relations;
- показывать related entity ids;
- показывать resolved related entities;
- показывать missing related entity ids;
- показывать presentation error для invalid input;
- передавать selected UI language только в labels;
- не создавать fake/demo/seed registry entities;
- не загружать registry entities из storage/network;
- не выбирать primary entity;
- не искать relations;
- не менять operation status;
- не attach-ить context к operation;
- не вычислять readiness;
- не выполнять assessment;
- не создавать audit package;
- не выполнять registry mutation, approval или publication.

Разрешённые production files следующего code step:

- `lib/registry_studio/operation/presentation/screens/registry_related_context_preparation_screen.dart`;
- `lib/registry_studio/presentation/language/registry_studio_ui_labels.dart`, только если нужны новые RU/EN/TH labels.

Разрешённые test files следующего code step:

- `test/registry_studio/operation/presentation/screens/registry_related_context_preparation_screen_test.dart`.

Запрещено в следующем code step:

- менять Core related context files;
- менять Core operation entity/use cases/status enum/id;
- менять `RegistryEngineeringOperationWorkspaceScreen`;
- менять `RegistryStudioApp`;
- менять `lib/main.dart`;
- подключать related context screen в runtime app shell;
- добавлять repository/store/persistence;
- добавлять Cubit/Bloc без отдельного ownership-аудита;
- добавлять Navigator/routes/onGenerateRoute;
- добавлять manager/facade/helper/wrapper/bridge/locator/magic utility;
- создавать fake/demo/seed registry entity в production;
- создавать operation context attachment;
- создавать readiness marker/getter;
- создавать assessment;
- создавать audit package;
- выполнять registry mutation, approval или publication;
- добавлять Translator dependency в operation presentation.

Проверки следующего code step обязательны:

- scope check только для разрешённых files;
- check, что Core не изменён;
- check, что `RegistryEngineeringOperationWorkspaceScreen` не изменён;
- check, что `RegistryStudioApp` и `lib/main.dart` не изменены;
- check, что related context screen не импортирует Translator/AppConfig/ApiClient/Typhoon/repository/store;
- targeted `dart analyze`;
- full `flutter analyze`;
- targeted widget tests;
- `git diff --check`;
- GitHub Actions `Build APK` после push.

Вывод:

- следующий code step может создать isolated `RegistryRelatedContextPreparationScreen`;
- следующий code step не должен подключать этот экран к workspace или app shell;
- runtime connection related context требует отдельного ownership-аудита после isolated presentation consumer.

## Build APK # related context preparation screen success

Related context preparation screen закрыт успешным GitHub Actions `Build APK`.

Проверенная commit chain:

- `c32e99c docs: define related context presentation ownership`;
- `74c207e feat: add related context preparation screen`.

CI proof:

- workflow: `Build APK`;
- run: `29070829494`;
- job: `86291754635`;
- branch: `registry-studio/clean-rebuild`;
- head commit: `74c207e`;
- conclusion: `success`;
- artifact: `helpy-translator-debug-apk`;
- artifact expired: `false`;
- artifact size: `70997009`.

Закрытый результат:

- создан isolated `RegistryRelatedContextPreparationScreen`;
- экран получает `RegistryStudioUiLanguage` извне;
- экран получает primary `RegistryEntity` извне;
- экран получает `Iterable<RegistryRelation>` извне;
- экран получает available related `Iterable<RegistryEntity>` извне;
- экран получает `PrepareRegistryRelatedContext` извне;
- экран получает `PrepareRegistryResolvedRelatedContext` извне;
- экран вызывает existing Core use cases только по explicit engineer action;
- экран показывает prepared `RegistryRelatedContext`;
- экран показывает prepared `RegistryResolvedRelatedContext`;
- экран показывает matched relations;
- экран показывает related entity ids;
- экран показывает resolved related entities;
- экран показывает missing related entity ids;
- экран показывает presentation error для invalid input;
- добавлены RU/EN/TH labels для related context preparation;
- Core related context files не менялись;
- Core operation entity/use cases/status enum/id не менялись;
- `RegistryEngineeringOperationWorkspaceScreen` не менялся;
- `RegistryStudioApp` не менялся;
- `lib/main.dart` не менялся;
- runtime app shell connection не добавлялся;
- repository/store/persistence не вводились;
- Cubit/Bloc/Navigator/routes не вводились;
- fake/demo/seed registry entity в production не создавались;
- operation context attachment не создавался;
- readiness marker/getter не создавался;
- assessment и audit package не создавались;
- registry mutation, approval и publication не добавлялись;
- Translator dependency в operation presentation не добавлялась.

Проверки перед push:

- scope matched ownership audit;
- forbidden files были unchanged;
- forbidden imports отсутствовали;
- targeted `dart analyze` был clean;
- full `flutter analyze` был clean;
- `git diff --check` был clean;
- targeted local `flutter test` был заблокирован известным Termux blocker `libvk_swiftshader.so`, поэтому authoritative verification выполнен через GitHub Actions.

Вывод:

- isolated related context preparation presentation consumer закрыт;
- related context screen пока не подключён к workspace или app shell;
- runtime connection related context требует отдельного ownership-аудита.

## Ownership-аудит related context runtime connection

После закрытия isolated `RegistryRelatedContextPreparationScreen` выполнен audit возможности подключить экран в runtime flow.

Проверенные candidates:

- `RegistryStudioApp`;
- `lib/main.dart`;
- `RegistryEngineeringOperationWorkspaceScreen`;
- `RegistryEngineeringOperation`;
- `RegistryRelatedContextPreparationScreen`;
- fake/demo/seed production registry entities;
- repository/store/persistence;
- separate source-backed related context input owner.

`RegistryStudioApp` не должен подключать `RegistryRelatedContextPreparationScreen` как top-level screen в текущем step.

Причина: app shell владеет только top-level screen selection и UI language. Он не владеет primary `RegistryEntity`, relation source или available related entities. Если app shell начнёт создавать эти inputs, он станет registry graph/input owner.

`lib/main.dart` не должен создавать inputs для `RegistryRelatedContextPreparationScreen`.

Причина: runtime composition создаёт dependencies и запускает app. Создание primary entity, relations или available related entities в `main.dart` было бы production seed/demo data или hidden registry input construction.

`RegistryEngineeringOperationWorkspaceScreen` не должен подключать `RegistryRelatedContextPreparationScreen` в текущем step.

Причина: workspace сейчас владеет только nullable in-memory current `RegistryEngineeringOperation`. Он не владеет source-backed primary entity selection, relation source или available related entities. Прямое добавление related context flow расширит workspace до workflow container.

`RegistryEngineeringOperation` не должен становиться source для related context inputs.

Причина: operation entity остаётся immutable lifecycle snapshot и не хранит primary/context/relation graph.

`RegistryRelatedContextPreparationScreen` не должен сам создавать missing inputs.

Причина: isolated screen уже утверждён как presentation consumer existing Core use cases. Он получает inputs извне и не выбирает primary entity, не ищет relations, не загружает entities и не создаёт fake/demo/seed data.

Fake/demo/seed production registry entities отклоняются.

Причина: они создадут видимость runtime connection без настоящего owner-а source-backed input. Это нарушит clean rebuild boundary и замаскирует нерешённую registry input responsibility.

Repository/store/persistence не вводятся в этом step.

Причина: текущий audit не решает durable registry graph loading, saved sessions, multi-operation storage или persistence lifecycle.

Вывод existing-fit audit:

- isolated related context screen готов;
- runtime connection пока не готов;
- existing runtime boundaries не владеют required inputs;
- новый code step для connection запрещён до ownership-аудита input owner-а.

Следующий шаг:

- не добавлять промежуточные ownership-аудиты ради перечисления отказов;
- сразу рассмотреть первый concrete semantic contract для source-backed input;
- текущий кандидат: Registry Studio Guard record.

Запрещено в следующем code step без отдельного решения по concrete semantic contract:

- подключать `RegistryRelatedContextPreparationScreen` к `RegistryStudioApp`;
- подключать `RegistryRelatedContextPreparationScreen` к `RegistryEngineeringOperationWorkspaceScreen`;
- менять `lib/main.dart` для related context runtime inputs;
- создавать production fixtures/seeds/demo registry entities;
- добавлять registry repository/store/persistence;
- добавлять operation context attachment;
- добавлять readiness marker/getter;
- добавлять assessment или audit package;
- выполнять registry mutation, approval или publication.

Вывод:

- direct runtime connection related context отклонён;
- промежуточные отрицательные ownership-аудиты не нужны;
- следующий рабочий шаг — рассмотреть `Registry Studio Guard record` как первый concrete semantic contract для source-backed input.

## Ownership-аудит semantic source input для Registry Studio Guard record

Первая concrete Guard source declaration явно предоставляет semantic facts. Source coordinates и snapshot fingerprint остаются provenance и принадлежат concrete adapter.

<!-- registry-studio-guard-record:v1
{
  "entityId": "registry_studio.guard.source_contract_foundation",
  "path": [
    "registry_studio",
    "guard",
    "source_contract_foundation"
  ],
  "recordType": "ownershipAudit",
  "heading": "Ownership-аудит semantic source input для Registry Studio Guard record",
  "summary": "Текущий Core foundation полностью выражает минимальный semantic source contract Guard record; отдельная source-input model не требуется.",
  "relations": []
}
-->

### Concrete Guard source declaration contract

`registry-studio-guard-record:v1` является concrete infrastructure annotation внутри Guard source document.

Annotation явно предоставляет:

- `entityId`;
- canonical `path`;
- `recordType`;
- `heading`;
- `summary`;
- explicit `relations`.

Она не является новой domain model и не заменяет существующие Core contracts.

Ownership:

- Guard document владеет явно записанными semantic facts;
- concrete adapter владеет только чтением annotation и созданием `SourceEvidence`;
- существующие Core contracts сохраняют собственные invariants.

Adapter обязан:

- использовать значения annotation без semantic inference;
- создавать source coordinates только как provenance;
- отклонять неполную или неизвестную declaration;
- не выводить identity, canonical path или relations из Markdown structure.

Одна declaration представляет один `RegistryEntity` и ноль или более явно объявленных `RegistryRelation`.


После добавления первого concrete payload и удаления лишнего entity wrapper выполнен аудит владельца source-backed input для `Registry Studio Guard record`.

Фактическое состояние:

- `RegistryStudioGuardRecordPayload` существует как concrete implementation `RegistryEntityPayload`;
- payload владеет только Guard-specific semantic content:
  - `recordType`;
  - `heading`;
  - `summary`;
- `RegistryEntity` уже владеет source-backed registry entity envelope;
- `RegistryEntityId` уже владеет stable entity identity;
- `RegistryPath` уже владеет canonical domain position;
- `RegistryEntityKind` уже владеет semantic contract / kind / schema identity;
- `SourceEvidence` уже владеет provenance и координатами внешнего источника;
- `RegistryRelation` уже представляет explicit directional relation fact;
- отдельная Guard source-input model не требуется; concrete source adapter пока отсутствует.

### Основное архитектурное решение

Registry Studio не строится вокруг Markdown, структуры документа, headings, номеров строк или другого физического source format.

`Registry Studio Guard record` является concrete semantic contract Registry Studio.

Markdown или другой физический формат может использоваться конкретным infrastructure adapter как внешний источник, но не определяет:

- `RegistryEntityId`;
- `RegistryPath`;
- Guard record identity;
- semantic contract;
- relation meaning;
- related context;
- архитектуру Registry Studio.

`SourceEvidence` может фиксировать физическое происхождение записи, но provenance не является domain identity или canonical registry structure.

### Результат повторного existing-fit audit

Минимальный semantic source contract Guard record уже выражен существующими owners:

- `RegistryEntityId` — stable identity;
- `RegistryPath` — canonical semantic position;
- `RegistryStudioGuardRecordPayload` — Guard-specific semantic content и typed `RegistryEntityKind`;
- `SourceEvidence` — обязательное source provenance;
- `RegistryEntity` — source-backed registry unit;
- `RegistryRelation` — отдельно объявленный directional relation fact.

Для создания Guard record достаточно существующего constructor contract `RegistryEntity`:

- `RegistryEntityId`;
- `RegistryPath`;
- `RegistryStudioGuardRecordPayload`;
- `Iterable<SourceEvidence>`.

Relations не входят в entity envelope и передаются отдельно как `Iterable<RegistryRelation>` только при подготовке related context.

Новая entity, value object, input/result model, application use case, factory, builder, provider, repository или store не требуются.

Объект, который только принимает эти typed values и вызывает `RegistryEntity(...)`, снова был бы thin wrapper.

### Оставшаяся незакрытая ответственность

Не закрыто только получение уже определённых semantic facts из конкретного внешнего источника.

Это infrastructure responsibility, а не отсутствующий domain contract.

До выбора и отдельного аудита concrete source запрещено:

- создавать generic parser или importer;
- выводить identity, canonical path или relations из физической структуры источника;
- добавлять source provider interface без реального consumer;
- подключать related context screen к runtime;
- менять `Core`, `RegistryStudioApp`, operation workspace или `main.dart`.

### Вывод

Текущий foundation достаточен.

Минимальный semantic source contract Guard record не требует нового слоя.

Следующий production step возможен только после отдельного ownership-аудита concrete source acquisition boundary.

## Решение по структурной принадлежности RegistryEntityPayload к RegistryEntityKind

После подтверждения достаточности текущего Core foundation выполнен existing-fit audit связки:

- `RegistryEntityPayload`;
- `RegistryEntityKind`;
- `RegistryEntity`;
- `RegistryStudioGuardRecordPayload`.

### Фактическое состояние до решения

`RegistryEntityPayload` отдельно предоставляет:

- `semanticContract`;
- `entityKindId`;
- `payloadSchemaVersion`.

`RegistryEntityKind` хранит те же contract facts:

- `semanticContract`;
- `kindId`;
- `schemaVersion`.

`RegistryEntity` принимает `RegistryEntityKind` и `RegistryEntityPayload` как два независимых аргумента, после чего проверяет совпадение semantic contract, entity kind id и schema version.

Текущий public contract допускает противоречивое состояние:

- вызывающая сторона может передать kind, который не соответствует payload;
- вызывающая сторона обязана вручную собрать два объекта с одинаковыми contract facts;
- concrete Guard boundary вынуждена повторно собирать `RegistryEntityKind` из уже известных payload constants;
- повторная сборка создаёт давление в сторону thin factory или wrapper.

Production implementation `RegistryEntityPayload` сейчас одна:

- `RegistryStudioGuardRecordPayload`.

Дополнительная implementation существует только как test fixture внутри `test/`.

### Existing-fit audit

`RegistryEntityKind` является полноценным существующим value object.

Он владеет:

- `RegistrySemanticContractIdentity`;
- `kindId`;
- `schemaVersion`;
- validation invariants непустого kind id и schema version.

Удалять `RegistryEntityKind` нельзя.

`RegistryEntityPayload` уже обязан объявлять совместимость с конкретным semantic contract, entity kind и schema version.

Предоставление payload собственного полного `RegistryEntityKind` не добавляет payload новую responsibility. Оно заменяет три разрозненных contract values одним существующим typed value object.

`RegistryEntity` должен оставаться source-backed registry unit и не должен самостоятельно строить или угадывать entity kind.

Отдельный Guard entity factory не требуется.

Factory, который только повторно собирает `RegistryEntityKind` и вызывает `RegistryEntity`, является thin wrapper без самостоятельной responsibility.

Новая entity, application use case, input model, result model, helper или builder не требуются.

### Решение

`RegistryEntityPayload` должен структурно предоставлять собственный `RegistryEntityKind`.

Целевой contract:

- `RegistryEntityPayload` предоставляет `RegistryEntityKind get kind`;
- отдельные getters `semanticContract`, `entityKindId` и `payloadSchemaVersion` удаляются из `RegistryEntityPayload`;
- `RegistryStudioGuardRecordPayload` предоставляет фиксированный Guard kind;
- `RegistryEntity` больше не принимает отдельный `RegistryEntityKind` argument;
- `RegistryEntity.kind` устанавливается из `payload.kind`.

Фиксированный Guard kind содержит:

- semantic contract id: `registry_studio.guard_record`;
- semantic contract version: `1`;
- kind id: `registry_studio.guard_record`;
- schema version: `1`.

Целевые constructor inputs `RegistryEntity`:

- `RegistryEntityId`;
- `RegistryPath`;
- `RegistryEntityPayload`;
- `Iterable<SourceEvidence>`.

### Инварианты после изменения

После изменения:

- payload принадлежит одному typed `RegistryEntityKind` структурно;
- невозможно передать kind, противоречащий payload;
- semantic contract, kind и schema mismatch становятся unrepresentable state;
- вызывающая сторона больше не повторяет contract metadata;
- `RegistryEntityKind` сохраняет свою responsibility и validation invariants;
- `RegistryEntity` сохраняет обязательный `SourceEvidence`;
- equality `RegistryEntity` остаётся основанным на `RegistryEntityId`;
- Guard-specific semantic content остаётся вне Core.

### Удаляемые проверки

Из `RegistryEntity` удаляются runtime-проверки совпадения:

- payload semantic contract и отдельно переданного kind semantic contract;
- payload entity kind id и отдельно переданного kind id;
- payload schema version и отдельно переданного kind schema version.

Причина: после структурного изменения несовместимую комбинацию нельзя создать через public contract.

Тесты, существующие только для проверки этих противоречивых комбинаций, удаляются или заменяются тестами новой структурной гарантии.

### Сохраняемые проверки

Сохраняются проверки:

- `RegistryEntityKind` отклоняет пустой `kindId`;
- `RegistryEntityKind` отклоняет пустой `schemaVersion`;
- `RegistryEntity` отклоняет пустой `sourceEvidence`;
- `RegistryEntity` сохраняет immutable source evidence collection;
- equality `RegistryEntity` определяется stable `RegistryEntityId`;
- concrete payload предоставляет правильный `RegistryEntityKind`;
- `RegistryEntity.kind` равен `payload.kind`.

### Отклонённые варианты

Отклоняется отдельный Guard entity factory, потому что это thin wrapper над существующими constructors.

Отклоняется дополнительный constructor `RegistryEntity.fromPayload`, потому что он сохранит два конкурирующих способа создания entity.

Отклоняется создание `RegistryEntityKind` внутри `RegistryEntity` из трёх строковых payload getters, потому что это сохранит раздробленный contract.

Отклоняется удаление `RegistryEntityKind`, потому что value object имеет самостоятельные contract facts и invariants.

### Разрешённый следующий code step

Разрешённый production surface:

- `lib/registry_studio/core/domain/contracts/registry_entity_payload.dart`;
- `lib/registry_studio/core/domain/entities/registry_entity.dart`;
- `lib/registry_studio/guard/domain/registry_studio_guard_record_payload.dart`.

Разрешённый test surface:

- `test/registry_studio/core/fixtures/registry_entity_fixture.dart`;
- `test/registry_studio/core/domain/registry_entity_test.dart`;
- `test/registry_studio/guard/domain/registry_studio_guard_record_payload_test.dart`;
- application и presentation tests только для обязательной адаптации существующих fixture calls.

### Запрещено в следующем code step

Запрещено:

- создавать новую entity;
- создавать Guard entity factory;
- создавать input/result wrapper;
- создавать новый application use case;
- создавать repository/store/persistence;
- создавать parser или source adapter;
- менять `RegistryEntityId`;
- менять `RegistryPath`;
- менять `SourceEvidence`;
- менять `RegistryRelation`;
- подключать related context screen к runtime;
- менять `RegistryStudioApp`;
- менять operation workspace;
- менять `main.dart`;
- выполнять registry mutation, approval или publication.

### Вывод

Текущий foundation достаточен.

Правильное решение — точечно усилить существующий Core contract:

- `RegistryEntityPayload` предоставляет typed `RegistryEntityKind`;
- `RegistryEntity` получает kind только через payload;
- дублирующая ручная сборка kind удаляется;
- новый архитектурный слой не создаётся.

## Termux Flutter environment restriction

- Never run `flutter precache --linux --force`.
- This command replaces the Android/Termux-adapted engine artifacts with standard Linux/glibc artifacts and breaks local `flutter test` and `flutter build bundle --debug`.

## Решение по presentation ownership Guard record после code step `277238f`

Ownership-аудит подтвердил необходимость отдельного contract-specific read-only presentation consumer для существующего `RegistryStudioGuardRecordPayload`.

Утверждённый owner:

- `lib/registry_studio/guard/presentation/screens/registry_studio_guard_record_screen.dart`;
- production-класс `RegistryStudioGuardRecordScreen`;
- boundary принадлежит `guard/presentation`, а не универсальному Core и не operation workflow.

Ответственность `RegistryStudioGuardRecordScreen` ограничена отображением уже существующей source-backed `RegistryEntity`, payload которой имеет тип `RegistryStudioGuardRecordPayload`.

Экран может показывать только уже подготовленные факты:

- `RegistryEntityId`;
- `RegistryPath`;
- `RegistryEntityKind`;
- `RegistryStudioGuardRecordType`;
- `heading`;
- `summary`;
- существующий `SourceEvidence`, включая document path, snapshot fingerprint, heading path и line range.

Экран не владеет:

- загрузкой или разбором Guard source;
- созданием `RegistryEntity`;
- подготовкой или разрешением related context;
- semantic assessment;
- ambiguity, contradiction или drift detection;
- созданием findings;
- semantic decision;
- mutation;
- approval;
- canonicalization decision;
- publication control.

`RegistryStudioApp` остаётся владельцем только top-level navigation и runtime presentation composition.

`main.dart` передаёт в приложение уже загруженную `guardSource.entity`. Это не создаёт новый source owner, repository, provider, service locator или lookup boundary.

Для этого шага не вводились:

- новая domain entity;
- новый use case;
- новый Core contract;
- repository;
- store;
- provider;
- analyzer;
- assessment service;
- resolver;
- orchestrator;
- manager;
- facade;
- locator.

Code step зафиксирован commit `277238f feat: add guard record presentation`.

Подтверждённые проверки code step:

- `flutter analyze` — без ошибок;
- целевые widget tests — 8 из 8;
- полный test suite — 99 из 99;
- `flutter build bundle --debug` — успешно;
- forbidden architecture pressure — отсутствует;
- изменения Core — отсутствуют.

Этот presentation consumer не является precedent для generic payload renderer, universal registry record screen или автоматического выбора presentation implementation по `semanticContract`.

## Минимальный контракт RegistryEngineeringOperationRevision

`RegistryEngineeringOperationRevision` — одна самостоятельная immutable Core domain entity.

Её ответственность — хранить одну полную версию инженерной работы и её место в истории одной `RegistryEngineeringOperation`.

Минимальный контракт entity:

- `String id`;
- `RegistryEngineeringOperationId operationId`;
- `int revisionNumber`;
- `String workingContent`;
- `String? previousRevisionId`;
- `RegistryEntityId primaryEntityId`;
- immutable `List<RegistryEntityId> relatedEntityIds`.

Инварианты:

- `id` нормализуется через `trim()` и не может быть пустым;
- `revisionNumber` начинается с `1`;
- первая revision не имеет `previousRevisionId`;
- каждая последующая revision имеет `previousRevisionId`;
- `previousRevisionId` нормализуется и не может быть пустым;
- `workingContent` содержит полную рабочую версию, нормализуется и не может быть пустым;
- `relatedEntityIds` уникальны;
- `relatedEntityIds` не содержат `primaryEntityId`;
- `relatedEntityIds` immutable;
- equality определяется только `id`.

`RegistryEngineeringOperation.problemStatement` остаётся исходной immutable причиной открытия operation.

Новая revision не изменяет `problemStatement` и предыдущие revisions.

После перехода operation в terminal status `decided` или `cancelled` сохранённые revisions и последняя working version остаются доступными для чтения, но создание новой revision запрещено.

Существующий workspace применяет этот lifecycle invariant без нового domain contract: revision editor становится read-only, save action отключается, а `_saveRevision` дополнительно отклоняет terminal operation.

Новая entity, use case, repository, store, manager или persistence boundary для этого не создаются.

Дополнительные revision id, working content, attachment, lineage, history, snapshot и context contracts не создаются.

Если ответственность entity расширится, дополняется этот же единый контракт.

Terminal operation остаётся текущей рабочей сессией до явного действия инженера `Начать новую операцию`.

Действие доступно только для statuses `decided` и `cancelled`. Workspace предварительно показывает confirmation о том, что текущая завершённая operation и её локальные revisions будут удалены из рабочей сессии.

После подтверждения workspace вызывает существующий `clearEngineeringOperationWorkspace()`, очищает текущие in-memory operation и revisions и возвращает пользователя в чистый operation creation flow. Исходный Translator candidate повторно не подставляется.

App-level owner одноразового Translator candidate — `RegistryStudioApp`.

`RegistryEngineeringOperationWorkspaceScreen` получает candidate как presentation input и сообщает существующему owner о фактическом потреблении через optional callback:

- после успешного создания operation;
- после восстановления уже существующей persisted operation.

После callback `RegistryStudioApp` очищает `_initialOperationProblemStatement`. Поэтому переключение экранов и повторный mount operation workspace не могут снова подставить уже использованный Translator candidate.

Workspace не становится owner Translator result и не сохраняет candidate в domain или persistence. Для этого lifecycle не вводятся новая entity, use case, repository, store, manager или persistence contract.


Этот flow заменяет только одну текущую локальную work session. Multi-operation archive, новая entity, use case, repository, store, manager или persistence model не вводятся до появления отдельного end-user requirement.

`RegistryEngineeringOperation` и `RegistryEngineeringOperationRevision` сохраняются существующим `RegistryWorkSessionPersistence`; новые persistence entities, repository, store и manager не создаются. Экземпляр persistence создаётся в composition root `main.dart`, явно передаётся через `RegistryStudioApp` в operation workspace и не создаётся внутри UI.

## Continuity revision context после восстановления workspace

Каждая `RegistryEngineeringOperationRevision` уже сохраняет полный context своей рабочей версии:

- `primaryEntityId`;
- immutable `relatedEntityIds`.

Поэтому отдельный operation-context persistence contract не требуется.

Правило создания следующей revision:

- первая revision получает primary и related ids из текущего подготовленного presentation context;
- после восстановления workspace следующая revision наследует `primaryEntityId` и `relatedEntityIds` последней persisted revision, если новый related context не был подготовлен;
- nullable `revisionRelatedEntityIds` означает отсутствие нового presentation context;
- non-null collection означает явно подготовленный текущий related context и используется вместо предыдущей collection;
- lineage через `previousRevisionId` и полная `workingContent` сохраняются без изменений.

Context continuity реализуется внутри существующего operation workspace с использованием уже восстановленных revisions.

Для этого flow не вводятся:

- новая entity;
- новый use case;
- context wrapper;
- repository;
- store;
- manager;
- дополнительный persistence payload.

## Очистка related context для новой work session

`RegistryStudioApp` владеет текущим подготовленным `RegistryResolvedRelatedContext`.

Этот presentation context относится только к текущей локальной work session и не должен автоматически переходить в следующую operation.

После подтверждённого действия `Начать новую операцию`:

- workspace успешно очищает persisted operation workspace через существующий `clearEngineeringOperationWorkspace()`;
- workspace очищает текущие in-memory operation, revisions и editor state;
- только после успешного завершения очистки workspace вызывает optional `onWorkSessionCleared`;
- `RegistryStudioApp` обрабатывает callback и очищает `_resolvedRelatedContext`;
- первая revision следующей operation не получает related ids завершённой work session.

Если persistence-очистка завершилась ошибкой, callback не вызывается, terminal operation и app-level related context сохраняются.

Workspace не становится owner `RegistryResolvedRelatedContext`. App не передаёт context через новый repository или persistence payload.

Для этого lifecycle не вводятся:

- новая entity;
- новый use case;
- context wrapper;
- repository;
- store;
- manager;
- новый persistence contract.
