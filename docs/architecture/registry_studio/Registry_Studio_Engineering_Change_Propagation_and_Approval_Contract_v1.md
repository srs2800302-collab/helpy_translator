# Registry Studio — единый продуктовый и архитектурный контракт

Стабильный Contract ID: `REGISTRY_STUDIO_ENGINEERING_CHANGE_PROPAGATION_AND_APPROVAL_V1`

Объединённая редакция: `5`

Роль документа: **единственный нормативный продуктовый и архитектурный контракт Registry Studio**

Статус: **УТВЕРЖДЁННЫЙ КОНТРАКТ**

Стабильный путь:

`docs/architecture/registry_studio/Registry_Studio_Engineering_Change_Propagation_and_Approval_Contract_v1.md`

Нормативный язык — русский. Английский сохраняется только для identifiers, типов, API, путей, схем, stable keys и дословных source fragments.

---

## 0. Полномочия и приоритет требований

Термины **ОБЯЗАН**, **ЗАПРЕЩЕНО**, **СЛЕДУЕТ** и **ДОПУСКАЕТСЯ** являются нормативными.

Первичная продуктовая задача раздела 1 имеет приоритет над UI, persistence, history, comparison, impact, Translator, approval и publication.

Supporting capability не может подменять основную бизнес-задачу самостоятельным generic workflow.

При обнаружении противоречия:

1. production-изменение останавливается;
2. фиксируются вопрос, варианты и последствия;
3. решение принимает инженер;
4. контракт и execution plan синхронизируются до production-патча.

Изменение контракта требует:

- полного read-only аудита текущего текста;
- явного решения инженера;
- ограниченного и проверяемого diff;
- проверки внутренних противоречий;
- отдельного documentation checkpoint.

Canonical Dictionary является versioned нормативным приложением. Его stable markers, `Dictionary ID`, approved entries и approved equivalents не изменяются как побочный эффект архитектурной редакции.

---

## 1. Первичная продуктовая задача

Главная задача Registry Studio — помогать инженеру поддерживать **единый канонический смысл всех пользовательских фраз, отображаемых на экранах приложения**.

Registry Studio ОБЯЗАНА анализировать фразы клиента, мастера и других пользователей приложения в полном business context.

Основная аналитическая цепочка:

```text
category
→ business entity
→ terminal scenario
→ effective content role
→ user-facing phrase
→ exact source evidence
```

Для каждой анализируемой фразы инженер должен видеть:

- category;
- business entity;
- terminal scenario;
- effective content role;
- фактический текст;
- canonical meaning, когда он доказан;
- applicability;
- связанные применения;
- обнаруженную проблему;
- точную причину;
- `RegistryPath`;
- `SourceEvidence`;
- unresolved facts.

Structural indexing, comparison, impact, Translator, persistence, history, approval и publication являются supporting capabilities и ОБЯЗАНЫ обслуживать эту задачу.

---

## 2. Модель канонического анализа

### 2.1. User-facing phrase и supporting context

Первичным предметом canonical status является фраза, фактически отображаемая пользователю или непосредственно формирующая отображаемый текст.

Business rules, lifecycle facts, applicability facts и architecture evidence могут использоваться как supporting context.

Supporting context НЕ ПОЛУЧАЕТ canonical phrase status автоматически, если сам не отображается пользователю и не является approved canonical entry.

Technical, build, deployment, database, API, audit, governance и implementation prose исключаются при отсутствии доказательства их прямого пользовательского значения.

### 2.2. Business entity и terminal scenario

Каждая анализируемая business entity ОБЯЗАНА иметь не менее одного terminal scenario.

Terminal scenario может быть:

- explicit — существует различимый business path или выбор;
- implicit — отдельный выбор отсутствует, но content принадлежит единственному terminal scenario.

Отсутствие selector не означает отсутствие scenario context.

Qualifier, answer branch, validation branch или условное изменение фотографий не являются отдельным scenario без business evidence.

### 2.3. Четыре effective content roles

Для каждого terminal scenario Helpy adapter ОБЯЗАН отдельно разрешить:

```text
questions
photoQuestions
clientRules
masterRules
```

Каждая роль разрешается как:

```text
present + exact content + exact provenance
или
missing + exact scenario context + typed finding
```

Adapter ЗАПРЕЩЕНО:

- выдумывать отсутствующий текст;
- создавать фиктивную фразу;
- скрывать остальные корректные роли из-за одной отсутствующей роли;
- поднимать или объединять blocks без evidence.

Effective content может быть:

- entity-local;
- scenario-local;
- размещённым в общем `mini-scope`;
- shared;
- inherited;
- расположенным выше дочерней entity;
- собранным из нескольких evidence-backed fragments.

Shared и inherited content представляются ссылками и provenance, а не молчаливым копированием.

### 2.4. Selector placement и ownership

Следующие факты являются независимыми:

```text
selector placement
selector option target
business entity ownership
scenario content ownership
effective role applicability
```

Selector не обязан находиться внутри entity или heading, содержащего scenario content.

Порядок selectors сохраняется, когда он влияет на пользовательский путь.

### 2.5. Открытая topology Helpy

Подтверждённые формы:

- `mini-TZ`;
- `mini-scope`;
- `entity-as-scenario`;
- `implicit scenario`;
- shared/inherited content;
- mixed topology.

Перечень не является закрытым enum.

Одна категория или branch может одновременно содержать несколько topology forms.

Heading depth и heading title сами по себе не доказывают entity, scenario, ownership или role.

---

## 3. Динамическое покрытие Registry

Registry рассматривается как полное рекурсивное дерево произвольной глубины.

Ни architecture, adapter, analyzer, UI, persistence, manifest или tests не могут зависеть от текущих:

- названий категорий;
- названий сущностей;
- названий сценариев;
- количества root categories;
- количества entities;
- количества scenarios;
- глубины headings;
- положения selector;
- количества topology forms;
- количества blocks;
- количества canonical entries;
- количества adapter-файлов.

После каждой успешной загрузки и refresh Registry Studio ОБЯЗАНА выполнить:

```text
full structural discovery
→ business-scope discovery
→ entity discovery
→ terminal-scenario discovery
→ selector and ownership resolution
→ four-role resolution
→ user-facing phrase extraction
→ canonical analysis
```

Новая категория, entity, scenario, selector, role placement или shared scope должны обнаруживаться без изменения universal Core.

Каждый structural node ОБЯЗАН быть учтён как:

- business content;
- supporting business context;
- technical/governance content;
- unresolved structure.

Silent omission ЗАПРЕЩЁН.

Неоднозначная или неподдерживаемая новая структура создаёт typed failure с точным `RegistryPath` и `SourceEvidence`.

---

## 4. Canonical Dictionary и applicability

Registry Studio использует ровно один вручную настроенный Canonical Dictionary проекта.

Canonical Dictionary является единственным источником утверждённых canonical formulations, approved equivalents и ordered canonical blocks.

Dictionary:

- не создаёт Registry topology;
- не определяет category, entity или scenario;
- не заменяет Registry;
- не разрешает applicability без structured project context;
- не разрешает автоматическую замену похожего текста.

Обязательные statuses:

```text
Unclassified / Neutral
Exact
Equivalent
Review
Drift
Failed
```

`Exact` требует approved text и доказанной applicability. Для constrained entry дополнительно требуется `CanonicalConfirmedApplicationEvidence`.

`Equivalent` требует отдельного engineer approval и applicability evidence.

Text similarity сама по себе не создаёт `Exact`, `Equivalent` или confirmed dependency.

При одинаковом exact text доказанно применимая constrained entry имеет приоритет над universal entry.

Universal entry используется как fallback только тогда, когда все constrained entries доказанно `notApplicable`.

Неразрешённая constrained applicability остаётся `Review` и блокирует universal fallback.

Явно неприменимая entry исключается из exact matching.

`Drift` требует previous canonical application evidence, доказывающего ранее подтверждённое canonical применение.

Ordered canonical block сравнивается как ordered sequence, а не как set.

---

## 5. Обязательные canonical findings

Для каждого terminal scenario каждой entity Registry Studio ОБЯЗАНА находить:

- exact canonical use;
- approved equivalent;
- canonical drift;
- unclassified phrase;
- lexical duplicate;
- semantic duplicate;
- разные формулировки одного смысла;
- conflict;
- contradiction;
- missing role;
- missing required phrase;
- incorrect applicability;
- incorrect universal fallback;
- incorrect shared/inherited binding;
- ordered mismatch;
- differences между аналогичными scenarios;
- RU / EN / TH inconsistency;
- malformed dictionary data;
- unresolved topology или ownership.

Findings разных scenarios не смешиваются.

Каждый finding содержит:

- stable identity;
- source revision;
- category/entity/scenario context;
- effective role;
- exact phrase или missing-role identity;
- canonical evidence;
- applicability evidence;
- `RegistryPath`;
- `SourceEvidence`;
- reason;
- severity;
- требуемое действие или engineer decision.

---

## 6. Архитектурные границы и расширяемый adapter

### 6.1. Universal modules

Universal `core`, `registry`, `canonical`, `maintenance`, `translator` и `publication`:

- не знают Helpy category names;
- не знают Helpy scenario names;
- не интерпретируют Markdown headings;
- не фиксируют topology;
- не фиксируют depth или counts;
- не расширяют universal enum каждым project-specific типом;
- не импортируют Helpy adapter.

Universal analyzer получает typed project context.

### 6.2. Project-facing canonical boundary

Canonical capability имеет одну project-facing boundary, принимающую точный `RegistrySnapshot` и возвращающую typed `CanonicalAnalysisPackage`.

Эта boundary не является God adapter проекта.

Adapter использует существующий `RegistrySnapshot`.

Повторная загрузка Registry или повторный полный Markdown parsing после `RegistrySnapshot` ЗАПРЕЩЕНЫ.

### 6.3. Внутренняя композиция Helpy adapter

Helpy adapter ОБЯЗАН быть расширяемым через capability-specific responsibilities.

Responsibilities могут включать:

- dictionary reading;
- business-scope discovery;
- entity resolution;
- terminal-scenario resolution;
- selector resolution;
- content-role binding;
- shared/inherited content resolution;
- ordered-content resolution;
- applicability resolution;
- evidence validation;
- failure aggregation.

Контракт не задаёт фиксированное количество классов или файлов.

Одна реализация не должна поглощать все responsibilities только ради сокращения количества файлов.

Новая topology добавляется внутри project adapter без изменения universal modules.

Пустые abstractions и speculative framework запрещены. Новый capability owner создаётся только при доказанной отдельной ответственности.

### 6.4. Typed failures

Обязательные failure families:

```text
category_architecture_ambiguous
scenario_boundary_ambiguous
selector_ownership_ambiguous
option_target_ambiguous
content_role_unresolved
content_binding_ambiguous
required_role_missing
ordered_sequence_ambiguous
unsupported_business_structure
```

Failure обязан быть typed и evidence-backed.

Adapter не превращает неоднозначность в догадку и не скрывает корректный partial result.

---

## 7. Supporting workflow и полномочия инженера

### 7.1. Revision comparisons, Explorer и принятые controls

Каждый analysis сохраняет точную текущую source revision и сравнивает её:

- с предыдущей известной revision;
- с последним clean baseline, явно подтверждённым инженером.

Новая загруженная revision никогда не становится clean baseline автоматически.

Registry Explorer ОБЯЗАН:

- сохранять полное рекурсивное дерево;
- поддерживать search и filters;
- открывать точный `RegistryPath`;
- переходить между findings без возврата к корню;
- сохранять видимость structural node даже без semantic identity.

Принятые controls:

- глобус выбирает язык UI `RU / EN / TH`;
- круговая стрелка загружает Registry заново и повторяет analysis;
- круговая стрелка не выполняет reset и не очищает текущую работу;
- крестик Translator очищает только Translator workspace;
- reset Registry Studio является отдельным подтверждаемым действием.

После refresh открытый context восстанавливается по stable identity и path. Перемещённый, изменённый или удалённый target показывается явно.

### 7.2. Независимая persistence и восстановление

Registry Studio workspace и Translator workspace имеют независимые UI-state, persistence и reset.

После backgrounding, process death, закрытия или restart каждое workspace ОБЯЗАНО восстановить последнее сохранённое состояние до собственного explicit reset.

Reset одного workspace не очищает другое workspace.

Registry snapshot, clean baseline, immutable history и publication evidence не удаляются обычным reset текущей работы.

### 7.3. Stable identity

`RegistryNodeId` является стабильной structural identity узла и сохраняется между revisions, пока сохраняется identity самого узла.

Structural identity и подтверждённая semantic identity являются разными фактами.

`RegistryEntityId` представляет подтверждённую semantic entity.

Optional identity overlay может связывать `RegistryNodeId` и `RegistryEntityId` только при наличии evidence.

Отсутствие semantic identity не скрывает structural node из Explorer, search, comparison, analysis или history.

Display label, heading text, line number, текущий path, source offset, content hash и commit SHA могут быть matching evidence, но не заменяют stable identity.

### 7.4. Impact, dependencies и решения по каждому месту

Registry Studio ОБЯЗАНА строить direct и transitive impact из полного structural index, Canonical Dictionary applications и project-adapter evidence.

Каждая найденная relation классифицируется как:

- `Confirmed dependency` — связь доказана stable identity, typed reference, explicit relation, reuse contract, canonical-application evidence или другим adapter evidence;
- `Semantic candidate` — связь вероятна, но не доказана и требует решения инженера;
- `Unaffected with evidence` — место исключено с доказательством отсутствия влияния.

Неизвестное не равно незатронутому.

Для каждого затронутого места Registry Studio сохраняет и показывает:

- exact path и evidence;
- исходное значение;
- предлагаемое значение;
- dependency context;
- reason;
- собственный proposal;
- собственное решение инженера.

Один глобальный `proposalReviewed` или аналогичный boolean не заменяет решения по каждому месту.

Application code, backend, API, Admin Panel, database и другие runtime consumers включаются в тот же impact graph при наличии dependency evidence.

Registry Studio не изменяет такой consumer без отдельной implementation capability и explicit approval для соответствующего target.

### 7.5. Completeness gate

Approval и apply блокируются, пока существует любой релевантный unresolved fact, включая:

- unanalyzed content;
- unresolved dependency;
- unresolved semantic candidate;
- unresolved topology или ownership;
- missing role;
- missing `SourceEvidence`;
- unresolved applicability;
- unresolved conflict или duplicate;
- incomplete translation;
- unreviewed proposal;
- unresolved placement;
- stale source revision;
- failed validation.

Completeness и readiness выводятся из фактов автоматически. Инженер не переключает generic lifecycle status вручную.

### 7.6. Whole-change-set approval и guarded apply

Только авторизованный инженер утверждает полный whole-change-set.

Registry Studio может применить изменение только когда:

- показан полный final diff;
- каждое затронутое место имеет решение;
- completeness gate пройден;
- validation пройдена;
- base source revision остаётся актуальной;
- deterministic patch точно соответствует утверждённому final diff.

Partial apply запрещён, если он оставляет Registry в несогласованном состоянии.

Изменение source revision, content, placement, applicability, dependency или engineer decision инвалидирует stale analysis, validation, final diff и approval в соответствии с фактическими зависимостями.

После apply сохраняются:

- утверждённый diff;
- base revision;
- resulting revision;
- affected identities и paths;
- engineer decisions;
- validation result;
- publication evidence;
- явное failure или rollback evidence.

### 7.7. Immutable history и traceability

Registry Studio сохраняет immutable history:

- загрузок и source revisions;
- previous revision;
- clean baseline;
- findings;
- dependency evidence;
- proposals;
- решений инженера;
- Translator evidence;
- validation;
- final diff;
- resulting revision;
- publication, failure и rollback evidence.

История обеспечивает прослеживаемость от текущего результата до exact source revision и решений инженера.

### 7.8. Продуктовая поверхность

Comparison, impact, dependencies, proposals, completeness, validation, history и publication являются внутренними supporting capabilities Registry Studio.

Они не становятся отдельными верхнеуровневыми продуктами, пунктами меню, operation screens или вручную управляемым generic workflow.

Registry Studio:

- загружает Registry;
- запускает canonical analysis;
- показывает findings и evidence;
- сохраняет текущую работу;
- передаёт phrase или block в Translator;
- принимает draft;
- повторно анализирует затронутые места;
- показывает final diff;
- применяет только утверждённый change set.

Translator:

- помогает редактировать user-facing formulations;
- проверяет RU / EN / TH;
- выполняет reverse semantic checks;
- возвращает placement request;
- не определяет topology;
- не утверждает dependencies;
- не публикует Registry.

Registry остаётся read-only до отдельного explicit approval и publication capability.

Registry Studio НЕ ДОЛЖНА самостоятельно:

- утверждать новый business meaning;
- объявлять semantic candidate каноническим;
- разрешать неоднозначную topology;
- скрывать unresolved fact;
- изменять Canonical Dictionary;
- применять Registry patch;
- изменять application code;
- публиковать изменение.

Только инженер принимает решения по meaning, applicability, scenario boundary, selector ownership, shared content, conflicts и final change set.

Stale source revision инвалидирует analysis, validation и approval.

---

## 8. Acceptance criteria

Stage 3 принимается только при end-to-end доказательстве основной бизнес-задачи.

Обязательные факты:

```text
ALL_REGISTRY_NODES_ACCOUNTED=PASS
ALL_BUSINESS_ENTITIES_ACCOUNTED=PASS
ALL_TERMINAL_SCENARIOS_RESOLVED=PASS
ALL_SELECTOR_BINDINGS_RESOLVED=PASS
ALL_EFFECTIVE_ROLES_RESOLVED_OR_MISSING_REPORTED=PASS
ALL_USER_FACING_PHRASES_ACCOUNTED=PASS
ALL_ORDERED_CONTENT_RESOLVED=PASS
FULL_DICTIONARY_PARSED=PASS
ALL_SOURCE_EVIDENCE_VALID=PASS
ALL_IDENTITIES_STABLE=PASS
NO_SILENT_OMISSION=PASS
UNKNOWN_COUNT=0
```

Обязательные tests покрывают:

- `mini-TZ`;
- `mini-scope`;
- `entity-as-scenario`;
- implicit scenario;
- mixed topology;
- selector placement отдельно от ownership;
- shared/inherited content;
- missing role;
- missing phrase;
- ordered content;
- technical exclusion;
- новую category после refresh;
- новую entity после refresh;
- новый scenario после refresh;
- unsupported structure;
- malformed dictionary;
- duplicate, drift, conflict и applicability;
- RU / EN / TH inconsistency.

Нулевые counters не являются доказательством functionality.

Acceptance также требует targeted tests, full suite, `flutter analyze`, `git diff --check`, production APK и физическую проверку findings и exact navigation.

---

## 9. Безусловные запреты

ЗАПРЕЩЕНО:

- фиксировать category names как scope;
- фиксировать entity names как architecture;
- фиксировать scenario names или count;
- фиксировать Registry depth;
- использовать heading depth как topology;
- считать каждую conditional branch отдельным scenario;
- смешивать selector placement и content ownership;
- копировать shared content без provenance;
- скрывать unsupported structure;
- классифицировать technical prose как user-facing phrase;
- строить God adapter, God service или central coordinator;
- фиксировать количество adapter-файлов;
- фиксировать количество universal public types;
- повторно читать полный Markdown после `RegistrySnapshot`;
- создавать speculative helpers или placeholder abstractions;
- принимать adapter только по synthetic domain tests;
- переходить к UI до production report;
- переходить к следующему Stage до полной приёмки текущего.

---

## 10. Языковой контракт

UI поддерживает RU / EN / TH.

Язык UI и язык Registry content являются разными фактами.

Нормативные объяснения и инженерное взаимодействие ведутся на русском языке. Identifiers, paths, API и schemas сохраняются на английском.

Canonical analysis включает translation consistency и reverse semantic checks поддерживаемых языков.

---

## 11. Встроенный словарь канонических бизнес-формулировок

<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->

Dictionary ID: `REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1`

Версия словаря: `1`

Статус: **APPROVED / STORED**

Видимый заголовок: **Словарь канонических бизнес-формулировок (`Canonical Business Phrase Dictionary`)**

Импортированные legacy titles collections:

- `Canonical Photo Labels`;
- `Canonical Client Labels`;
- `Canonical Master Workflow Blocks`;
- `Global Platform Rules`.

Источник импорта:

- source path: `docs/architecture/Helpy_Architecture_Registry_v1.md`;
- source ref: `main`;
- дата получения: `2026-07-17`;
- source SHA-256: `dbe4e4fbaa934e3e48c0190088421ff93190cda65083352df7cd67ff641010b7`;
- SHA-256 импортированного canonical-source block: `96466d7b28f447056cdd5be79035c9d0c350c3ede6c3b7a9ae4714558e1f3c67`;
- SHA-256 импортированного global-rules block: `66a03252bc9013646e47215989c042e42651a0a6562079bf77ffbeae6f4fe2fe`.

### Контракт сопровождения словаря

Только авторизованный инженер может утвердить новую canonical entry.

Новая фраза или блок добавляются в следующем порядке:

```text
инженер определяет повторно используемую бизнес-формулировку
→ анализ duplicates и conflicts
→ анализ applicability
→ review RU / EN / TH в Translator
→ обратная семантическая проверка
→ approval инженера
→ добавление или versioning entry словаря
→ повторная индексация словаря Registry Studio
→ анализ применений в Registry и подготовка proposals
```

Словарь не разрешает автоматическую замену каждой похожей фразы.

Одна точная canonical entry может иметь разные допустимые applicability. Applicability оценивается в полном контексте ветки Registry.

Тексты утверждённых фраз и блоков ниже перенесены из текущего источника Registry и не переписываются этим контрактом. Стабильные legacy titles и отдельные source evidence fragments могут оставаться на английском языке как дословные identifiers или доказательства.

### Утверждённые эквивалентные формулировки

Эквивалентная формулировка не становится новой canonical entry и не разрешает автоматическую классификацию других похожих текстов.

Эквивалентность действует только в явно зафиксированной applicability. Наличие похожего текста вне этой applicability не является доказательством эквивалентности.

<!-- REGISTRY_STUDIO_CANONICAL_APPROVED_EQUIVALENTS:BEGIN -->

### Approved equivalent: `helpy.canonical.approved-equivalent.electrical-safety-boundary.001`

Approval status: **APPROVED / STORED**
Canonical entry identity: `REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1::helpy.canonical.client_labels::sha256:09bad4adec8d4bc7e0995396df9af95ad197417022f64c04c2ba8301e2d85c99`
Equivalent text: `Клиент не обязан выполнять опасные действия для предоставления информации.`
Applicability: `RegistryPath: Helpy Architecture Registry v1 Foundation -> 23. Service Architecture Registry — Electrical -> Electrical Point Mini-TZ Standard`
Approval evidence ID: `registry-studio.engineer-approval.2026-07-23.equivalent-001`
Registry source path: `docs/architecture/Helpy_Architecture_Registry_v1.md`
Registry source revision: `64f45059c6043f2e65165a4a8da053cf3a73c107`
Registry source fingerprint: `git-blob:c69a0f5812e00f99ecc3eb3235d5a2c8fc3271a9`
Registry source line: `9366`

<!-- REGISTRY_STUDIO_CANONICAL_APPROVED_EQUIVALENTS:END -->

### Collection: `helpy.canonical.general_preparation`

Тип записи: `phrase_with_applicability`

Статус: **APPROVED / STORED**

Правила применения утверждённых формулировок:

Подготовьте доступ к месту выполнения работ.
- Используется только для сценария «Установить и подключить».

Подготовьте доступ к установленному оборудованию.
- Используется только для сценария «Заменить».

### Collection: `helpy.canonical.photo_labels`

Тип записи: `phrase`

Статус: **APPROVED / STORED**

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

Тип записи: `phrase`

Статус: **APPROVED / STORED**

### Канонические формулировки для клиента (`Canonical Client Labels`)

Статус: APPROVED / STORED ✅

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

Тип записи: `ordered_block`

Статус: **APPROVED / STORED**

### Канонические рабочие блоки мастера (`Canonical Master Workflow Blocks`)

Статус: APPROVED / STORED ✅

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

#### Проверка совместимости до начала работ (`Compatibility Check Before Work`)
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

#### Осмотр оборудования до установки и подключения (`Equipment Inspection Before Installation and Connection`)
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

#### Демонтаж оборудования (`Equipment Removal`)
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

#### Установка и подключение (`Installation and Connection`)
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

#### Проверка работоспособности (`Functional Verification`)
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

### Collection: `helpy.canonical.global_business_rules`

Тип записи: `ordered_rule_block`

Статус: **APPROVED / STORED**

Подтверждённые правила:

### Правило № 1 — Безопасная область действий клиента (`Client-Safe Scope Rule`)
Клиент отвечает только на вопросы, которые он объективно может понять.
Платформа не должна требовать от клиента технической диагностики, разборки оборудования, действий с электричеством или иных действий, которые могут быть небезопасны или ухудшить его положение.

Доказательства:
- Plumbing: клиент отвечает только на объективно понятные вопросы.
- Plumbing Electric Shower: клиент не разбирает розетки, автоматы или проводку и не выполняет действий, связанных с электричеством.
- Locks: платформа не должна заставлять клиента выполнять действия, которые могут ухудшить его положение как покупателя оборудования.

### Правило № 2 — Защита упаковки оборудования (`Equipment Packaging Protection Rule`)
Если клиент уже приобрёл новое оборудование самостоятельно, Helpy не требует вскрытия упаковки до проверки совместимости мастером.
Фотографии упаковки должны позволять увидеть модель, характеристики, размеры и комплектацию, если они указаны производителем.
Клиент должен сохранять право на возврат, обмен и гарантийное обслуживание.

Доказательства:
- Plumbing: клиент не должен вскрывать упаковку оборудования для создания заказа.
- Plumbing: при фотографировании упаковки клиент предоставляет упаковку со всей информацией на ней.
- Locks: платформа не требует вскрывать упаковку, нарушать заводские пломбы, раскладывать комплектующие или извлекать оборудование из коробки.

### Правило № 3 — Проверка совместимости до демонтажа (`Equipment Compatibility Before Demolition Rule`)
Если работа предполагает замену оборудования, мастер обязан проверить новое оборудование до демонтажа существующего.
Проверка включает совместимость, комплектность, целостность и возможность установки.
Только после проверки мастер приступает к демонтажу.

Доказательства:
- Plumbing faucet replacement: мастер проверяет совместимость до демонтажа.
- Plumbing toilet/electric shower replacement: новое оборудование должно быть проверено до работ.
- Locks: проверка нового оборудования до демонтажа существующего закреплена как Global Equipment Verification Rule.

### Правило № 4 — Структурированное ТЗ до чата (`Structured Scope Before Chat Rule`)
Форма заказа собирает первоначальное техническое задание и закрывает визуальную часть ТЗ.
Чат завершает текстовую часть ТЗ, уточняет скрытые работы, материалы, доступ и фиксирует окончательную стоимость.
Чат не заменяет структурированную форму заказа.

Доказательства:
- Plumbing: форма собирает первоначальное ТЗ и закрывает визуальную часть.
- Plumbing: чат завершает текстовую часть ТЗ и фиксирует окончательную стоимость.
- `Structured Job Scope Contract`: первоначальный scope заказа формируется из структурированных вопросов, ответов и обязательных фотографий.

### Правило № 5 — Запрет дополнительных запросов фотографий в чате (`No Extra Photo Requests In Chat Rule`)
Мастер не может запрашивать дополнительные фотографии в чате, если обязательные фотографии уже определены формой заказа.
Фото-ТЗ должно формироваться через approved photo requirements.
Исключения возможны только через будущие утверждённые правила жизненного цикла чата.

Доказательства:
- Plumbing faucet/mixer: мастер не может запрашивать фотографии в чате.
- Plumbing blockage: мастер не может запрашивать дополнительные фотографии в чате.
- Plumbing electric shower: мастер не может запрашивать дополнительные фотографии в чате.

### Правило № 6 — Однократное изменение окончательной цены (`One-Time Final Price Rule`)
Окончательная стоимость заказа может быть изменена мастером только один раз до выбора мастера.
Изменение требует обоснования, обсуждения с клиентом и согласования.
После согласования клиентом и выбора мастера Final Agreed Price становится неизменяемым финансовым фактом заказа.

Доказательства:
- Plumbing: окончательная цена фиксируется мастером один раз и после согласования становится неизменяемой.
- Client Expected Price / Final Price Contract: мастер может один раз предложить изменение цены до выбора мастера.
- Final Price Architecture Decision: job-level financial snapshot является неизменяемым после выбора мастера.

### Правило № 7 — Границы ответственности платформы (`Platform Boundary / Ownership Rule`)
Helpy не включает в услугу действия, которые не утверждены как часть сервиса платформы.
Материалы, дополнительные работы, утилизация, вынос демонтированного оборудования, личные вещи клиента, транспортировка, хранение, публичные зоны и вопросы собственности/права доступа не входят в платформенную ответственность, если отдельный контракт явно не утверждает обратное.

Доказательства:
- Furniture: мастер не перемещает, не сортирует и не хранит личные вещи клиента.
- Plumbing: демонтированное оборудование остаётся собственностью клиента; вынос/утилизация не являются услугой Helpy.
- Locks: Helpy не работает с вопросами собственности, аренды и права доступа.
- Air Conditioning: материалы и дополнительные работы согласуются через чат; платформа не участвует в покупке материалов.

### История изменений словаря

| Версия словаря | Дата | Изменение | Доказательство |
|---|---|---|---|
| `1` | `2026-07-17` | Первичный импорт текущих утверждённых общих подготовительных фраз, `Canonical Photo Labels`, `Canonical Client Labels`, `Canonical Master Workflow Blocks` и подтверждённых Global Platform Rules в контракт новой ветки. | Путь источника, source hashes и точный импортированный текст зафиксированы выше. |

<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->
