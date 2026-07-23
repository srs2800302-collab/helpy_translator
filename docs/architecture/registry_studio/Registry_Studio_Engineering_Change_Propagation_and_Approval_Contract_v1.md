# Registry Studio — единый контракт продукта, архитектуры, инженерных изменений, утверждения и канонических формулировок

Стабильный Contract ID: `REGISTRY_STUDIO_ENGINEERING_CHANGE_PROPAGATION_AND_APPROVAL_V1`

Объединённая редакция: `4`

Роль документа: **единственный нормативный архитектурный и продуктовый контракт новой ветки**

Статус: **УТВЕРЖДЁННЫЙ ПРОЕКТ — ЕДИНЫЙ ИСТОЧНИК ИСТИНЫ ДЛЯ ПРОДУКТА, АРХИТЕКТУРЫ, UX, ИНЖЕНЕРНЫХ ИЗМЕНЕНИЙ, УТВЕРЖДЕНИЯ И КАНОНИЧЕСКИХ ФОРМУЛИРОВОК НОВОЙ ВЕТКИ**

Репозиторий: `helpy_translator_registry_studio_clean`

Цель: новая recovery-ветка, создаваемая только после повторной проверки точных `HEAD`, ветки, состояния рабочего дерева, исходных файлов и recovery baseline.

Нормативный язык документа и инженерного взаимодействия по Registry Studio — **русский**. Английский язык сохраняется только для идентификаторов, имён типов, каталогов, путей, API, схем, конфигурации, commit SHA, стабильных ключей и дословно импортированных source fragments. Любая модель или инженерный помощник ОБЯЗАН отвечать и объяснять решения по Registry Studio на русском языке, пока пользователь явно не запросит другой язык.

Документ синхронизирует и объединяет полные требования из:

- `Registry_Studio_Engineering_Change_Propagation_and_Approval_Contract_v1.md`;
- `Registry_Studio_New_Branch_Product_Architecture_and_Canonical_Contract_v1.md`.

Это единственный нормативный архитектурный документ Registry Studio для новой ветки. Предыдущие документы сохраняются только как исторические доказательства и ЗАПРЕЩЕНЫ как конкурирующие источники истины.

Стабильный путь в репозитории сохраняется:

`docs/architecture/registry_studio/Registry_Studio_Engineering_Change_Propagation_and_Approval_Contract_v1.md`

Сохранение существующего пути и стабильного Contract ID предотвращает устаревшие ссылки, а номер объединённой редакции фиксирует развитие единого продуктового контракта.

Recovery references:

- чистая универсальная граница Registry Core: commit `6fd3260`;
- минимальная Flutter/runtime composition: commit `a54136a`;
- prototype `4f0a717`: только UX- и behavior-reference;
- clean-rebuild tip `4bd60bc`: только источник отдельно проверенных компонентов, не baseline для продолжения старой архитектуры.

Импортированный текущий источник Registry:

- репозиторий: `srs2800302-collab/helpy`;
- ref импорта: `main`;
- путь: `docs/architecture/Helpy_Architecture_Registry_v1.md`;
- дата получения: `2026-07-17`;
- SHA-256 загруженного источника: `dbe4e4fbaa934e3e48c0190088421ff93190cda65083352df7cd67ff641010b7`;
- SHA-256 импортированного canonical-source block: `96466d7b28f447056cdd5be79035c9d0c350c3ede6c3b7a9ae4714558e1f3c67`;
- SHA-256 импортированного global-rules block: `66a03252bc9013646e47215989c042e42651a0a6562079bf77ffbeae6f4fe2fe`.

---

## 0. Полномочия контракта и правило внесения изменений

Термины **ОБЯЗАН**, **ЗАПРЕЩЕНО**, **СЛЕДУЕТ** и **ДОПУСКАЕТСЯ** являются нормативными.

Документ определяет:

- назначение продукта;
- видимые рабочие пространства и элементы управления;
- автоматическое поведение анализа;
- модель расширения Registry;
- область канонической классификации;
- persistence и историю;
- передачу контекста в Translator и обратно;
- impact analysis, review, approval и publication;
- встроенный Canonical Dictionary, поддерживаемый инженером.

Будущее изменение контракта требует:

1. точного доказательства текущего содержимого документа;
2. явного решения инженера;
3. видимого diff;
4. проверки противоречий с существующими требованиями;
5. commit- и revision-evidence в новой ветке.

Два прежних исходных документа НЕ ДОЛЖНЫ оставаться действующими нормативными контрактами новой ветки. После фиксации этой объединённой редакции по стабильному пути любые копии считаются только историческими ссылками.

Видимый заголовок словаря ДОПУСКАЕТСЯ изменять. Стабильные маркеры и `Dictionary ID` ЗАПРЕЩЕНО изменять без versioned migration.

Язык исходного кода, identifiers, directory names, database/API/schema/configuration names остаётся английским. Бизнес-правила, UX, архитектурные решения, инженерные объяснения и взаимодействие с пользователем ведутся на русском языке.

---

## 1. Назначение продукта

Registry Studio — инженерный инструмент для поддержания проектного Registry в состоянии, которое является:

- структурно чистым;
- семантически согласованным;
- выровненным по каноническим формулировкам;
- прослеживаемым до точной source revision;
- безопасным для изменений;
- расширяемым без перестройки Core.

Продукт ОБЯЗАН сразу обнаруживать внешние изменения Registry, объяснять их влияние, проводить инженера через каждое проблемное место, поддерживать работу над формулировками через Translator и применять только полный change set, утверждённый инженером.

Registry Studio не является продуктом управления workflow. Внутренние comparisons, revisions, dependency analysis, completeness checks, proposals, validation и подготовка patch ОБЯЗАНЫ работать автоматически внутри Registry Studio и отображаться только как контекстная инженерная информация и действия.

Все обязательные требования к engineering change, dependencies, revisions, completeness, human authority, значимому порядку Guidance, application-code dependencies и safe publication из исходного утверждённого change-propagation contract сохранены в разделе 7 и согласованы с утверждённым UX двух рабочих пространств и рекурсивной моделью Registry.

---

## 2. Два основных рабочих пространства инженера

Приложение содержит два основных рабочих пространства:

```text
Registry Studio
Translator
```

Они независимы по UI-state и persistence, но участвуют в одном двустороннем инженерном цикле.

### 2.1. Рабочее пространство Registry Studio

Registry Studio является основным рабочим пространством для:

- загрузки и индексации полного Registry;
- автоматического анализа после каждой загрузки;
- обнаружения изменений относительно предыдущей известной revision;
- обнаружения расхождений с последним подтверждённым инженером clean baseline;
- просмотра и поиска по полному Registry;
- фильтрации по canonical status;
- отображения проблемных и затронутых мест;
- открытия точных блоков Registry в контексте;
- перехода к предыдущей или следующей проблеме без возврата к полному дереву;
- отправки полной фразы или выделенного фрагмента в Translator;
- приёма draft из Translator;
- проверки предложенного placement;
- повторного построения impact analysis;
- review каждого затронутого места;
- отображения итогового diff;
- утверждения и применения полного change set;
- просмотра истории последних анализов и применённых изменений.

### 2.2. Рабочее пространство Translator

Translator является основным рабочим пространством для:

- получения фразы или выбранного фрагмента Registry с точным контекстом;
- создания новой формулировки с нуля;
- ручного редактирования инженерного текста;
- подготовки и проверки RU / EN / TH;
- обратных семантических проверок;
- анализа терминологии и semantic drift;
- предупреждений и audit commentary;
- выбора окончательной формулировки инженером;
- указания целевого Registry, operation, anchor и placement;
- возврата draft в Registry Studio для preflight validation.

Translator не выполняет самостоятельное сканирование зависимостей, не публикует изменения Registry и не утверждает полное изменение Registry. При этом Translator является полноценным инженерным инструментом авторинга, а не пассивной API-capability.

---

## 3. Обязательный видимый UI-контракт

### 3.1. Экран Registry Studio

Экран Registry Studio содержит:

1. Заголовок Registry и source revision.
2. Компактную сводку проблем и статусов.
3. Счётчики и фильтры canonical status.
4. Поиск.
5. Полную раскрываемую иерархию Registry.
6. Контекстный просмотр блока.
7. Навигацию по проблемам.
8. Передачу контекста в Translator.
9. Контекстные панели impact, proposal, validation и final diff.
10. Историю последних рабочих изменений.

Отдельные верхнеуровневые экраны или пункты меню ЗАПРЕЩЕНЫ для:

- `Engineering Operation`;
- `Engineering Task`;
- `Comparison`;
- `Status Transition`;
- `Readiness Gate`;
- `Related Context`;
- `Dependency Graph`;
- `Guard Record`;
- `Revision Editor`.

Они остаются внутренними фактами продукта.

### 3.2. Компактный список проблем

Компактный раскрываемый список проблем располагается в верхней части Registry Studio, в области, ранее использованной для Registry selector/revision summary.

Он показывает:

- количество проблем;
- количество изменённых мест;
- текущую revision;
- revision clean baseline;
- короткие записи с типом проблемы и `RegistryPath`;
- status icon, цвет и текстовое объяснение.

Кнопка открывает ту же очередь в полноэкранном режиме для плотного review. Полноэкранное представление остаётся частью Registry Studio и не является отдельным инженерным продуктом.

Выбор элемента сразу открывает точный блок Registry. После этого инженер может перейти к предыдущей или следующей проблеме без возврата к полному дереву Registry.

### 3.3. Визуальные состояния

Допускается следующая подсветка:

- красный — подтверждённый conflict или invalid state;
- оранжевый/жёлтый — требуется review или найден semantic candidate;
- синий — подтверждённое затронутое или связанное место;
- зелёный — подготовленное и прошедшее validation изменение;
- серый — проанализированное и доказанно незатронутое либо нейтральное место.

Цвет никогда не является единственным сигналом. Каждое состояние ОБЯЗАНО дополнительно содержать текстовую метку, icon и причину.

### 3.4. Элементы управления canonical status

Оба основных рабочих пространства показывают canonical status controls, но работают с разными наборами данных.

Счётчики Translator описывают текущую рабочую сессию Translator.

Счётчики Registry Studio описывают все допустимые бизнес-фразы в текущей загруженной revision Registry:

```text
All
Unclassified / Neutral
Exact
Equivalent
Review
Drift
Failed
```

Нажатие статуса работает как фильтр. Например, `Drift` немедленно показывает все бизнес-фразы с классификацией drift, их `RegistryPath` и прямую навигацию к каждому точному блоку.

### 3.5. Точное значение существующих кнопок

- Значок глобуса: выбор языка интерфейса приложения `RU / EN / TH`.
- Круговая стрелка обновления на экране Registry: ручная перезагрузка Registry и повторный автоматический анализ.
- Значок крестика на экране Translator: очистка только текущего Translator workspace.

Круговая стрелка не очищает текущую работу Registry Studio.

Крестик Translator не очищает состояние Registry Studio.

Сброс текущей работы Registry Studio является отдельным подтверждаемым действием и не должен использовать значок обновления.

---

## 4. Автоматический анализ Registry

### 4.1. Обязательный trigger

Каждая успешная загрузка Registry, включая startup приложения и ручное обновление, автоматически запускает анализ. Инженер не запускает отдельную operation сравнения.

### 4.2. Два baseline сравнения

Registry Studio поддерживает:

1. **Предыдущую известную revision** — для отображения изменений с последней загрузки.
2. **Последний подтверждённый инженером clean baseline** — для отображения расхождений с принятым чистым состоянием.

Новая загруженная revision никогда не становится clean baseline автоматически.

### 4.3. Автоматический pipeline анализа

```text
загрузить точную source revision
→ построить полный структурный индекс
→ сравнить с предыдущей известной revision
→ сравнить с последним clean baseline
→ обнаружить добавления
→ обнаружить удаления
→ обнаружить замены
→ обнаружить перемещения
→ обнаружить значимое изменение порядка
→ разрешить стабильные identities и paths
→ классифицировать допустимые бизнес-фразы по Canonical Dictionary
→ обнаружить canonical drift, отсутствие canonical coverage, conflicts и duplicates
→ перестроить прямой и транзитивный impact
→ классифицировать confirmed dependencies и semantic candidates
→ создать или обновить очередь проблем
→ сохранить анализ и текущее рабочее пространство инженера
```

### 4.4. Внешние изменения администратора

Администратор или другой утверждённый источник может в любой момент изменить бизнес-конфигурацию Registry.

При следующей загрузке Registry Studio ОБЯЗАН обнаружить:

- изменённую сущность или сценарий;
- добавленную или удалённую категорию;
- добавленный или удалённый вложенный бизнес-блок;
- изменённую формулировку;
- изменённую applicability;
- изменённую requiredness;
- изменённые правила reuse фотографий или limits;
- изменённый порядок Guidance;
- изменённое client, master или global rule;
- canonical drift;
- нарушенные или вновь появившиеся зависимости.

Инженер ОБЯЗАН сразу видеть точное изменённое место и причину.

---

## 5. Динамическая рекурсивная модель Registry

Registry рассматривается как рекурсивное дерево произвольной глубины с расширяемым набором типов узлов.

Архитектура НЕ ДОЛЖНА задавать обязательную цепочку уровней. Категории, сущности, направления, сценарии, вопросы, требования к фотографиям, guidance, правила, процессы и другие текущие структуры являются только примерами.

Универсальная структурная форма:

```text
Registry
└── RegistryNode
    ├── stable identity
    ├── kind или semantic descriptor
    ├── RegistryPath
    ├── SourceEvidence
    ├── content
    ├── business-scope ownership
    └── children: RegistryNode[]
```

Любой узел МОЖЕТ содержать дочерние узлы существующих или будущих типов. Будущий project adapter или Registry schema МОЖЕТ добавлять семантическую интерпретацию без изменения универсального Core.

Ни архитектура, ни алгоритм, ни UI, ни manifest, ни тест, ни счётчик, ни persistence schema, ни acceptance rule не могут зависеть от текущего количества:

- корневых узлов;
- категорий;
- уровней вложенности;
- типов узлов;
- сущностей;
- сценариев;
- фраз;
- правил;
- canonical entries.

Структурная индексация ОБЯЗАНА рекурсивно обнаруживать весь Registry.

Project-specific semantic overlays МОГУТ добавлять:

- stable typed identity;
- relations;
- applicability;
- ordered-block semantics;
- validation;
- business-scope classification.

Overlay является доказательством поверх полного структурного индекса. Он никогда не является границей видимости или анализа Registry.

Новые узлы и новые типы узлов ОБЯЗАНЫ автоматически:

- появляться в Registry Explorer;
- становиться доступными для поиска;
- участвовать в сравнении revisions;
- участвовать в обнаружении проблем;
- участвовать в canonical analysis, когда принадлежат допустимой бизнес-области;
- участвовать в dependency analysis;
- появляться в истории анализа и изменений;
- не требовать переработки универсального Core.

Статический manifest допускается только как versioned evidence overlay для явно стабильных identities или relations.

---

## 6. Канонический анализ бизнес-логики и владение словарём

### 6.1. Канонический источник

Canonical Dictionary, встроенный в этот контракт, является поддерживаемым инженером источником утверждённых канонических бизнес-фраз и упорядоченных канонических блоков новой ветки.

Текущий заголовок Registry `Canonical Photo Labels` сохраняется как имя импортированной collection. Он не является постоянной identity словаря.

Registry Studio ОБЯЗАН находить словарь по:

- стабильному `Dictionary ID`;
- явным begin/end markers;
- version;
- collection identifiers.

Registry Studio ЗАПРЕЩЕНО зависеть от видимого Markdown heading, поскольку видимый заголовок может быть переименован.

### 6.2. Допустимая бизнес-область

Canonical classification применяется только к узлам Registry, которые структурно классифицированы как пользовательская бизнес-логика или как бизнес-правила, непосредственно управляющие видимым пользователю поведением.

Сюда входит полное рекурсивное бизнес-поддерево, принадлежащее:

- структурам каталога услуг или продуктов;
- client rules и видимому клиенту guidance;
- master rules и видимому мастеру guidance;
- global business rules;
- другим текущим или будущим business owners, определённым project adapter или Registry schema.

Это классы владения, а не закрытое перечисление типов узлов.

Новая категория, уровень вложенности, тип сценария, тип процесса, тип правила или иной бизнес-узел ОБЯЗАН автоматически попадать в canonical analysis, если принадлежит допустимой бизнес-области.

### 6.3. Исключённая техническая область

Canonical phrase statuses НЕ ДОЛЖНЫ назначаться техническому содержимому Registry только потому, что оно содержит текст.

По умолчанию исключаются:

- заметки об архитектурной реализации;
- database schema и migrations;
- API internals;
- CI configuration;
- code-level contracts;
- внутренние инженерные процедуры;
- инструкции build и deployment.

Текст в техническом разделе включается только при наличии структурного доказательства, что он является пользовательской бизнес-логикой.

### 6.4. Канонические классификации

Registry Studio различает:

- `Exact` — точное каноническое совпадение после допустимой только технической нормализации;
- `Equivalent` — отдельно утверждённый эквивалент с доказательством;
- `Review` — вероятная связь без достаточного доказательства;
- `Drift` — доказанное применение канонической формулировки с отличающимся текстом;
- `Failed` — ошибка словаря, перевода, parsing или validation, не позволяющая выполнить надёжную классификацию;
- `Unclassified / Neutral` — допустимая бизнес-фраза без доказанной канонической связи.

Нормализация пробелов НЕ ДОЛЖНА изменять пунктуацию, отрицание, количества, обязательную силу, терминологию, applicability, порядок или бизнес-смысл.

Text similarity само по себе НЕ ДОЛЖНО давать `Exact` или `Equivalent`.

### 6.5. Правила словаря, поддерживаемого инженером

Инженер добавляет или изменяет canonical entry только внутри размеченной области словаря в конце этого документа.

Каждая добавленная или изменённая entry ОБЯЗАНА иметь:

- утверждённую collection;
- явный status;
- canonical source-language text или ordered canonical block;
- applicability или scope, если фраза не универсальна;
- RU / EN / TH review evidence до признания multilingual-complete;
- проверки duplicate, semantic duplicate, conflict, ambiguity и terminology;
- решение инженера и history entry.

Registry Studio читает только утверждённые entries внутри markers словаря.

Governance prose, examples, evidence notes и headings вне утверждённых collections НЕ ДОЛЖНЫ классифицироваться как canonical phrases.

### 6.6. Каноническая identity

Для phrase entry стабильная техническая identity определяется из:

```text
Dictionary ID
+ collection ID
+ normalized approved source-language text hash
```

Для ordered block identity дополнительно включает stable block key и утверждённый порядок items.

Изменение canonical text создаёт новую versioned canonical identity. Предыдущая identity сохраняется в истории и НЕ ДОЛЖНА молча перезаписываться.

---

## 7. Распространение и утверждение инженерных изменений

Этот раздел сохраняет и синхронизирует обязательные требования исходного утверждённого engineering-change contract. Эти механизмы являются внутренними возможностями Registry Studio. Они НЕ ДОЛЖНЫ возвращаться как отдельные верхнеуровневые технические экраны или как управляемый пользователем generic operation lifecycle.

### 7.1. Источники изменения

Registry Studio принимает три равноправных инженерных входа:

1. Изменение, автоматически обнаруженное после загрузки новой revision Registry.
2. Business change request, совместимый с Admin Panel.
3. Прямое изменение инженера или задача canonicalization.

Admin Panel является внешним источником business intent. Он не владеет dependency discovery, semantic decisions, canonical approval, whole-change-set approval, publication или изменениями application code.

Прямая инженерная задача проходит те же требования, что и внешне обнаруженное изменение.

### 7.2. Обязательные исходные факты

Каждый внутренний `EngineeringChangeSet` ОБЯЗАН сохранять или восстанавливать:

- точный project и project adapter;
- точную base source revision;
- предыдущую известную revision;
- revision последнего подтверждённого инженером clean baseline;
- source identity и target identity, когда применимо;
- `RegistryPath`;
- `SourceEvidence`;
- source span или structural evidence;
- исходное значение;
- предлагаемое значение;
- origin изменения;
- intent изменения;
- owning Registry branch;
- структурный контекст;
- затронутые language data;
- audit lineage.

Display label, текущий line number, heading text или текущий phrase text НЕ ДОЛЖНЫ заменять стабильную identity.

### 7.3. Поддерживаемые change intents

Registry Studio может внутренне представлять конкретные change intents, включая:

- add;
- remove;
- replace;
- move;
- reorder;
- insert before;
- insert after;
- insert at start;
- insert at end;
- insert at exact structural position;
- copy явно выбранного semantic block;
- replace явно выбранного semantic block;
- copy явно выбранного subtree;
- revise formulation;
- prepare Canonical Dictionary candidate;
- update утверждённой canonical entry через versioned change.

Это domain facts, используемые Registry Studio, а не отдельные экраны навигации.

Change intent ОБЯЗАН ссылаться на точные стабильные source, target, container, item и anchor identities, когда такие факты существуют.

### 7.4. Полный граф зависимостей

Registry Studio ОБЯЗАН строить прямой и транзитивный impact из полного структурного индекса Registry.

Граф НЕ ДОЛЖЕН ограничиваться:

- одним корневым разделом;
- одним project-specific manifest;
- одним semantic overlay;
- текущим размером каталога;
- текущим количеством типов узлов;
- текущей глубиной вложенности;
- только идентичным текстом.

Доказательства могут включать:

1. stable typed references;
2. явные `RegistryRelation`;
3. adapter-defined reuse contracts;
4. stable semantic identity;
5. owner-block и applicability evidence;
6. scenario или process entry evidence;
7. ссылки на question, answer option, qualifier, photo, limit, rule и guidance;
8. применения Canonical Dictionary;
9. application-code, backend, API, Admin Panel или runtime-consumer evidence;
10. точное normalized canonical reuse с полным контекстом.

Текстовое или структурное сходство без доказательства остаётся semantic candidate.

Обход графа продолжается, пока не представлены все достижимые confirmed dependencies и unresolved candidates. Cycles ОБЯЗАНЫ обрабатываться детерминированно.

### 7.5. Классификация результатов

Каждое обнаруженное место классифицируется как одно из следующих.

#### Подтверждённая зависимость (`Confirmed dependency`)

Связь доказана stable identity, typed reference, explicit relation, reuse contract, canonical-application evidence или иным доказательством project adapter.

#### Семантический кандидат (`Semantic candidate`)

Связь вероятна, но не доказана. Требуется явное решение инженера.

#### Незатронутое место с доказательством (`Unaffected with evidence`)

Место может быть исключено только тогда, когда Registry Studio способен объяснить, почему изменение не может на него повлиять.

Неизвестное не равно незатронутому.

### 7.6. Контекст каждого затронутого места

Каждое затронутое место рассматривается в полном контексте своей рекурсивной ветки.

Registry Studio ОБЯЗАН показывать:

- точный `RegistryPath`;
- source и target identities, когда применимо;
- owner nodes;
- ancestor context;
- ordered siblings, когда порядок значим;
- исходный content;
- предлагаемый content;
- text diff;
- structural diff;
- additions;
- removals;
- replacements;
- moves;
- reordered items;
- applicability;
- relations и evidence;
- прямые и транзитивные dependency paths;
- canonical evidence;
- состояние RU / EN / TH;
- warnings;
- unresolved questions;
- причину proposal.

Project-specific структуры, такие как категории, сущности, сценарии, вопросы, требования к фотографиям, правила, guidance и будущие типы узлов, являются только примерами. Универсальный контракт не задаёт фиксированную последовательность ветки.

### 7.7. Точные proposals и решения инженера

Registry Studio может подготовить точный proposal только тогда, когда результат детерминированно следует из доказанных фактов и полного контекста.

Явное решение инженера обязательно, когда:

- relation является semantic candidate;
- одна и та же фраза имеет другой смысл или applicability;
- меняется business meaning;
- меняется applicability;
- меняется requiredness;
- меняется ordered behavior;
- меняется семантика photo reuse или limit;
- RU / EN / TH расходятся;
- требуется новая canonical formulation;
- источники конфликтуют;
- dependency coverage неполна;
- остаётся canonical drift или ambiguity;
- невозможно доказать deterministic placement.

Каждое затронутое место имеет собственный proposal и собственное решение инженера.

Один глобальный `proposalReviewed` или эквивалентный boolean НЕ ДОЛЖЕН заменять решения по каждому месту.

Инженер может:

- принять;
- отклонить;
- отредактировать;
- заменить собственным инженерным решением;
- отправить фразу или выбранный фрагмент в Translator;
- разрешить semantic candidate;
- отметить место незатронутым только с зафиксированным обоснованием.

### 7.8. Revisions и lineage

Каждый шаг, изменяющий content, создаёт или обновляет revision текущего `EngineeringChangeSet`.

Revision сохраняет:

- affected stable identity;
- original value;
- proposed value;
- полный working content;
- change intent;
- source of proposal;
- dependency context;
- решения инженера по каждому месту;
- previous revision lineage;
- related identities;
- результаты RU / EN / TH;
- Translator evidence;
- validation и audit references.

Изменение content, placement, target, applicability или source revision инвалидирует устаревшие comparison, impact analysis, completeness, validation, final diff и approval в соответствии с фактическими зависимостями.

### 7.9. Completeness gate

Registry Studio ОБЯЗАН блокировать approval и apply, пока остаётся любой релевантный unresolved fact, включая:

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

До readiness Registry Studio ОБЯЗАН доказать:

1. Обнаружены доступные прямые и транзитивные зависимости.
2. Каждый finding классифицирован.
3. Каждое неоднозначное место имеет решение инженера.
4. Проверены все затронутые RU / EN / TH data, требуемые проектом.
5. Все revisions принадлежат одному согласованному change set.
6. Не осталось внутренних conflicts.
7. Значимый порядок корректен.
8. Canonical conflicts и duplicates разрешены.
9. Application-code и другие runtime-consumer dependencies имеют решение.
10. Инженер видит полный final diff.
11. Final validation проходит относительно всё ещё актуальной source revision.

Gate автоматически выводится из фактов. Инженер не выбирает вручную технические lifecycle statuses.

### 7.10. Значимый порядок

Порядок является domain semantics, когда owning block объявляет ordered behavior.

Registry Studio ЗАПРЕЩЕНО:

- рассматривать ordered block как set;
- молча сортировать его;
- изменять порядок по text similarity;
- объединять items без анализа role, stage, applicability и workflow;
- копировать item без сохранения или явного изменения его позиции.

Для ordered change Registry Studio показывает исходную последовательность, предлагаемую последовательность, additions, removals, moves, причину и workflow impact.

Placement требует точной позиции или stable anchor, когда порядок значим.

### 7.11. Application-code и external-consumer dependencies

Изменение Registry не изменяет автоматически Flutter, backend, API, Admin Panel, database или иной runtime consumer.

Когда подтверждённые доказательства показывают такую зависимость, Registry Studio ОБЯЗАН:

1. Показать зависимость инженеру.
2. Добавить её в тот же impact graph и change set.
3. Потребовать решение инженера.
4. Блокировать completeness, пока зависимость не разрешена.
5. Никогда не изменять и не публиковать application code без явного approval и implementation capability, предназначенной для соответствующего target.

### 7.12. Полномочия человека

Registry Studio НЕ ДОЛЖЕН самостоятельно:

- утверждать business meaning;
- разрешать semantic ambiguity;
- объявлять candidate каноническим;
- принимать proposal;
- скрывать unresolved dependency;
- изменять Registry;
- публиковать Registry;
- выполнять merge pull request;
- изменять application code.

Translator и Admin Panel также не обладают этими полномочиями.

Только авторизованный инженер утверждает полный change set.

### 7.13. Безопасное применение

После whole-change-set approval Registry Studio может применить только точный набор, ранее показанный и прошедший validation.

Если source revision изменилась:

- apply останавливается;
- source context загружается заново;
- comparison и dependency analysis повторяются;
- stale approval инвалидируется;
- требуется новое approval инженера.

Partial apply запрещён, когда он оставляет Registry в несогласованном состоянии.

После apply Registry Studio сохраняет:

- окончательный утверждённый diff;
- все затронутые identities и paths;
- base revision;
- resulting revision;
- ссылки на решения инженера;
- canonical и Translator evidence;
- результат validation;
- результат publication;
- failure или rollback evidence.

### 7.14. Первый полный рабочий вертикальный сценарий

```text
новая revision Registry, Admin Panel-compatible input или прямая задача инженера
→ точное восстановление изменения
→ полный структурный и канонический анализ
→ полный граф прямых и транзитивных зависимостей
→ confirmed dependencies и semantic candidates
→ контекстные proposals для каждого затронутого места
→ редактирование и решения инженера
→ round-trip через Translator при необходимости
→ повторные comparison и dependency analysis
→ автоматический completeness gate
→ полный final diff
→ явное whole-change-set approval
→ deterministic guarded apply
→ resulting revision или failure/rollback evidence
```

Search, source blocks, свободное редактирование, изолированные revisions, только comparison или технический operation screen не являются завершением основного продуктового workflow.

---

## 8. Двусторонний цикл Registry Studio ↔ Translator

### 8.1. Передача из Registry Studio в Translator

Инженер может отправить:

- полную фразу;
- выбранный фрагмент;
- полный semantic block;
- несколько явно выбранных связанных строк.

Handoff включает:

- `RegistryEntityId`, когда доступен;
- `RegistryPath`;
- точную source revision;
- source span и evidence;
- owning category/entity/scenario/block;
- исходный content;
- обнаруженную проблему;
- контекст связанных мест;
- текущее canonical evidence.

### 8.2. Авторинг в Translator

Инженер может:

- изменить полученную формулировку;
- создать новую формулировку;
- вручную редактировать RU / EN / TH;
- просматривать reverse checks;
- просматривать warnings;
- выбирать окончательный текст;
- выбирать intended placement.

### 8.3. RegistryPlacementRequest

Возвращаемый draft содержит конкретный `RegistryPlacementRequest`:

- content для размещения;
- target Registry;
- точную base revision;
- target identity или container;
- target `RegistryPath`;
- operation type;
- anchor identity или точный structural anchor;
- placement position;
- intended application scope;
- rationale инженера;
- Translator evidence и warnings.

Поддерживаемые placement intents включают:

- replace выбранной formulation;
- insert before;
- insert after;
- insert at start;
- insert at end;
- insert at exact position;
- add new element;
- replace semantic block;
- copy semantic block;
- prepare Canonical Dictionary candidate.

Order-sensitive Guidance всегда требует явного placement или anchor.

### 8.4. Preflight в Registry Studio

Возвращённый draft Translator не изменяет Registry немедленно.

Registry Studio сначала проверяет:

- актуальность base revision;
- существование exact target;
- существование exact anchor;
- structural compatibility;
- semantic-block compatibility;
- significant ordering;
- создание duplicates;
- conflicts с Canonical Dictionary;
- прямые и транзитивные dependencies;
- semantic candidates;
- затронутые RU / EN / TH data;
- итоговый structural и textual diff.

Draft превращается в один или несколько конкретных proposals по местам только после preflight.

### 8.5. Review и apply инженером

Инженер может принять, отклонить или отредактировать proposal каждого затронутого места.

Registry Studio может выполнить apply только когда:

- проанализировано каждое затронутое место;
- разрешён каждый semantic candidate;
- завершены все обязательные language checks;
- разрешены canonical conflicts;
- validation проходит;
- показан final diff;
- явно утверждён весь change set;
- source revision остаётся актуальной.

---

## 9. Внутренняя архитектурная модель

### 9.1. Архитектурный стиль

Registry Studio реализуется как модульный монолит, организованный вокруг конкретных продуктовых возможностей и двух основных рабочих пространств инженера:

```text
Registry Studio
Translator
```

Comparison, обнаружение изменений, dependency analysis, revisions, proposals, completeness, validation, подготовка итогового diff, история и подготовка publication являются внутренними возможностями Registry Studio.

Они не должны становиться:

- отдельными верхнеуровневыми продуктами;
- техническими пунктами навигации;
- отдельными экранами инженерных операций;
- вручную управляемым generic workflow.

Архитектура не должна строиться вокруг:

- владения Registry со стороны Translator;
- generic workflow engine;
- generic operation lifecycle;
- технических operation screens;
- центрального runtime orchestrator;
- God App, God Workspace или глобального God Cubit;
- универсальных repositories и result envelopes;
- helper, wrapper, facade, utility, coordinator или manager, заменяющих ясное предметное владение.

### 9.2. Чистый универсальный Core

Начальный универсальный Core берётся из чистой архитектурной границы commit `6fd3260` без преждевременного расширения:

- `RegistryEntity`;
- `RegistryEntityId`;
- `RegistryEntityKind`;
- `RegistryPath`;
- `SourceEvidence`;
- `RegistryRelation`;
- `RegistryRelationMeaning`;
- `RegistrySemanticContractIdentity`;
- контракты related context.

Core:

- не импортирует Flutter;
- не импортирует presentation;
- не импортирует infrastructure;
- не импортирует Translator;
- не импортирует project-specific adapter;
- не содержит Helpy-specific semantics;
- не знает о GitHub, HTTP, local storage, Admin Panel, Markdown или конкретном формате Registry;
- не задаёт фиксированную глубину Registry;
- не задаёт обязательную последовательность бизнес-уровней;
- не использует текущее количество узлов как архитектурную границу;
- не требует изменения при появлении новых project-specific типов бизнес-узлов.

Новые категории, подкатегории, сущности, направления, сценарии, вопросы, фотографии, guidance, правила, процессы и будущие вложенные бизнес-блоки обнаруживаются из структурного Registry. Они не должны требовать расширения Core только из-за появления нового типа или уровня дерева.

Конкретные виды узлов, их семантика и принадлежность к пользовательской бизнес-логике определяются project adapter и структурой конкретного Registry.

### 9.2.1. Обязательная универсальность и подключение новых проектов

Registry Studio ОБЯЗАН оставаться reusable, project-independent инженерной платформой для сопровождения Registry разных проектов.

Helpy является первым project adapter и пилотным проектом для проверки продукта. Helpy НЕ ЯВЛЯЕТСЯ архитектурной моделью, встроенной в универсальные модули Registry Studio.

После обкатки Registry Studio на первом проекте подключение нового или другого проекта ОБЯЗАНО требовать только:

- добавления `adapters/<project>`;
- project-specific configuration источника Registry;
- получения точной source revision;
- интерпретации конкретного формата и структуры Registry;
- разрешения и сохранения стабильных structural identities проекта;
- optional versioned semantic identity overlay;
- определения business-scope ownership;
- предоставления project-specific relations и dependency evidence;
- регистрации adapter в `app` composition или конфигурации выбора проекта;
- project-specific publication integration, когда она требуется проекту.

Подключение нового проекта НЕ ДОЛЖНО требовать глобальной переработки или изменения:

- `core`;
- универсальных моделей и contracts областей `registry`, `canonical`, `maintenance`, `translator`, `publication` и `technical`;
- `RegistryNode`, `RegistrySnapshot` и `RegistryStructuralIndex`;
- рекурсивного Registry Explorer;
- search и filters;
- comparison revisions;
- persistence и restoration;
- history;
- dependency analysis;
- Translator handoff;
- completeness и validation;
- универсального publication workflow;
- adapters уже подключённых проектов.

Изменение универсального модуля допускается только для отдельно доказанного и утверждённого требования, которое действительно является общим для всех проектов, а не для размещения project-specific исключения.

Все предположения о конкретном проекте ОБЯЗАНЫ оставаться вне универсальных модулей. К ним относятся:

- repository owner, repository name, branch, source path и другие source coordinates;
- GitHub, Markdown или иной конкретный transport и storage format;
- текущая taxonomy узлов;
- business rules;
- фиксированное количество категорий, сущностей, сценариев или других узлов;
- фиксированная глубина дерева;
- project-specific identity ledger;
- project-specific semantic classification;
- project-specific relations и consumer evidence.

Универсальная structural identity и подтверждённая semantic identity являются разными фактами:

- `RegistryNodeId` является стабильной identity структурного узла и ОБЯЗАН сохраняться между revisions, пока сохраняется identity самого узла;
- способ разрешения и сохранения `RegistryNodeId` принадлежит project adapter и versioned identity evidence проекта;
- `RegistryEntityId` является identity подтверждённой semantic entity;
- optional `RegistryIdentityOverlay` связывает `RegistryNodeId` с `RegistryEntityId`, когда такая связь доказана;
- отсутствие semantic identity НЕ ДОЛЖНО скрывать structural node из Explorer, search, comparison, analysis или history;
- display label, heading text, текущий `RegistryPath`, line number, source offset, content hash или Git commit SHA МОГУТ использоваться как matching evidence, но НЕ ДОЛЖНЫ самостоятельно заменять стабильную identity.

Обязательным критерием архитектурной универсальности является подключение второго test project adapter, который отличается от Helpy:

- источником;
- форматом Registry;
- структурой дерева;
- типами узлов;
- системой stable identities;
- business-scope rules;
- project-specific relations.

Второй adapter ОБЯЗАН подключаться добавлением adapter-specific реализации и composition registration без переработки универсальных моделей и workflows.

Архитектура считается нарушенной, если подключение второго проекта требует:

- условия вида `if (projectId == ...)` в универсальных модулях;
- добавления project-specific branch в Core;
- расширения закрытого universal enum каждым новым типом узла проекта;
- фиксации глубины или количества узлов;
- переноса project-specific semantics в `registry`, `canonical`, `maintenance`, `translator`, `publication` или reusable `technical`;
- изменения универсального workflow только из-за формата или структуры нового проекта.


### 9.3. Владение продуктовыми возможностями

Registry Studio разделяется на конкретные области владения:

- `registry` владеет точным Registry snapshot, рекурсивным деревом, структурным индексом, search, navigation, refresh, очередью проблем и контекстом clean baseline;
- `canonical` владеет чтением Canonical Dictionary, canonical identities, классификацией фраз и canonical findings;
- `maintenance` владеет автоматическим анализом изменений, comparison, dependency impact, `EngineeringChangeSet`, proposals по каждому месту, решениями инженера, revisions, completeness, validation, итоговым diff и историей работы;
- `translator` владеет инженерной работой над формулировками, проверками RU / EN / TH, reverse checks, warnings, placement intent и двусторонней передачей контекста;
- `publication` владеет построением deterministic patch, проверкой актуальности revision, безопасным apply и publication evidence;
- `adapters` владеют структурой и семантикой конкретного проекта, business-scope ownership, project-specific relations и доказательствами внешних зависимостей;
- `technical` владеет техническими реализациями configuration, networking, serialization и storage.

Ни одна область не должна поглощать решения другой области только ради упрощения wiring.

### 9.4. Конкретный внутренний агрегат изменения

Внутренний `EngineeringChangeSet` может владеть:

- точной base revision;
- предыдущей известной revision;
- последним подтверждённым clean baseline;
- обнаруженным или созданным инженером change intent;
- source, target или placement request;
- результатом comparison;
- dependency impact;
- proposals по каждому затронутому месту;
- решениями инженера по каждому месту;
- Translator candidates;
- revisions и lineage;
- canonical findings;
- completeness facts;
- validation;
- итоговым diff;
- approval;
- publication evidence.

`EngineeringChangeSet` не является отдельным верхнеуровневым экраном, пунктом меню, generic operation framework или вручную переключаемым lifecycle. Это внутреннее предметное состояние текущей инженерной работы Registry Studio.

### 9.5. Производное состояние

Readiness и progress вычисляются из фактического состояния работы. Инженер не выбирает вручную технические lifecycle statuses.

Изменение content, placement, target, applicability, dependency, source revision, engineer decision или другого значимого факта должно инвалидировать устаревшие analysis, validation, final diff и approval в соответствии с их фактическими зависимостями.

---

## 10. Целевая иерархия владения

Каталоги фиксируют устойчивые границы ответственности. Конкретные файлы и более глубокие каталоги создаются только тогда, когда они требуются реализуемому рабочему вертикальному сценарию.

### 10.1. Минимальные физические границы

```text
lib/
├── main.dart
├── app/
│   ├── bootstrap/
│   ├── shell/
│   └── localization/
│
├── registry_studio/
│   ├── core/
│   ├── registry/
│   ├── canonical/
│   ├── maintenance/
│   ├── translator/
│   ├── publication/
│   └── adapters/
│       └── helpy/
│
└── technical/
    ├── config/
    ├── network/
    └── storage/
```

Эта иерархия является контрактом владения, а не требованием заранее создать пустые каталоги, placeholder-файлы или speculative abstractions.

### 10.2. Ответственность модулей

#### `app`

`app` владеет только композицией приложения:

- запуском;
- созданием зависимостей;
- двумя основными рабочими пространствами;
- application shell;
- выбором языка интерфейса `RU / EN / TH`;
- координацией восстановления состояния;
- отображением startup failure.

`app` не владеет analysis Registry, canonical classification, dependency logic, proposals, validation или publication decisions.

#### `core`

`core` владеет только минимальными project-independent Registry contracts, определёнными в разделе 9.2.

#### `registry`

`registry` владеет:

- точной source revision и `RegistrySnapshot`;
- рекурсивным представлением узлов Registry;
- полным структурным индексом;
- search и filters;
- Registry Explorer;
- выбранным `RegistryPath` и выбранным block;
- переходом к предыдущему и следующему проблемному месту;
- ручной перезагрузкой по кнопке с круговой стрелкой;
- восстановлением открытого контекста после перезагрузки;
- ссылками на предыдущую revision и clean baseline;
- контекстным отображением результатов `maintenance`.

Дерево Registry может иметь произвольную глубину и расширяемый набор project-specific типов узлов.

#### `canonical`

`canonical` владеет:

- стабильной identity Canonical Dictionary;
- чтением словаря между стабильными markers;
- collections и versioned entries;
- canonical phrase identities;
- статусами `Exact`, `Equivalent`, `Review`, `Drift` и `Failed`;
- не классифицированными допустимыми бизнес-фразами;
- доказательствами связи entries словаря с применениями в Registry.

`canonical` не содержит жёстко заданного дерева категорий. Область пользовательской бизнес-логики передаётся project adapter на основании структурного владения.

#### `maintenance`

`maintenance` является внутренней инженерной capability Registry Studio и владеет:

- автоматическим сравнением с предыдущей revision;
- автоматическим сравнением с последним clean baseline;
- обнаружением изменений;
- анализом значимого порядка;
- классификацией проблем;
- прямым и транзитивным dependency analysis;
- confirmed dependencies и semantic candidates;
- `EngineeringChangeSet`;
- proposals по каждому месту;
- решениями инженера;
- revisions;
- completeness;
- validation;
- итоговым diff;
- историей текущей и завершённой работы.

Более глубокие области владения могут появляться постепенно:

```text
maintenance/
├── analysis/
├── impact/
├── change_set/
├── review/
├── validation/
└── history/
```

Они создаются только при появлении реализованной ответственности и являются внутренними capability boundaries, а не дополнительными экранами продукта.

#### `translator`

`translator` владеет:

- независимым состоянием Translator workspace;
- исходной formulation;
- ручным редактированием инженером;
- значениями RU / EN / TH;
- reverse checks;
- warnings;
- formulation draft;
- Registry handoff context;
- target, operation, anchor, position и rationale;
- возвратом конкретного placement request в Registry Studio.

Translator не утверждает полный change set, не определяет достоверность dependencies, не применяет изменения Registry и не публикует Registry.

#### `publication`

`publication` владеет:

- построением deterministic Registry patch;
- проверкой актуальности base revision;
- проверкой соответствия patch утверждённому final diff;
- безопасным применением полного утверждённого change set;
- resulting revision;
- publication evidence;
- failure evidence;
- rollback evidence.

`publication` не создаёт business proposals и не принимает инженерные решения.

#### `adapters/helpy`

Helpy adapter владеет всей Helpy-specific информацией:

- конкретным источником и форматом Registry;
- project-specific структурной интерпретацией;
- рекурсивным business-scope ownership;
- текущими и будущими типами бизнес-узлов;
- категориями и их произвольной вложенностью;
- client rules, master rules и global rules;
- интеграцией Canonical Dictionary;
- Admin Panel evidence;
- backend, API и application-code dependencies;
- доказательствами других внешних consumers;
- project-specific semantic relations.

Helpy adapter не должен делать универсальный Core зависимым от Helpy. Новый проект получает собственный adapter без изменения Core и без изменения основного рабочего сценария Registry Studio.

#### `technical`

`technical` владеет повторно используемыми техническими реализациями:

- configuration;
- networking;
- local storage;
- serialization;
- platform lifecycle integration.

Технические реализации не принимают бизнес-решений и не выполняют инженерное approval.

### 10.3. Направление зависимостей

Целевое направление зависимостей:

```text
app
→ registry / canonical / maintenance / translator / publication

registry / canonical / maintenance / translator / publication
→ core

project adapters
→ project-facing contracts соответствующих capabilities
→ core

technical implementations
→ infrastructure ports конкретного владельца
```

Обязательные ограничения:

- `core` не зависит от внешних модулей;
- presentation не импортирует конкретные GitHub, HTTP или storage implementations;
- `maintenance` не зависит от presentation;
- Translator не импортируется в Core;
- Helpy не импортируется в Core;
- `publication` не утверждает change set;
- technical infrastructure не классифицирует бизнес-смысл;
- service locator запрещён;
- глобальное mutable runtime state запрещено;
- generic `Repository<T>` запрещён без доказанной конкретной ответственности.

### 10.4. Правило поэтапного создания

Физическая структура расширяется только через рабочие вертикальные сценарии.

Перед созданием нового production type, каталога, abstraction или service реализация должна доказать:

1. ответственность существует в утверждённом продуктовом workflow;
2. существующий владелец не может корректно её принять;
3. новый владелец имеет конкретную domain или application responsibility;
4. новый элемент не создаёт generic workflow engine или central orchestrator;
5. новый элемент не кодирует текущее количество узлов Registry;
6. новый элемент не кодирует текущую глубину Registry;
7. новый элемент не кодирует закрытый набор project-specific типов;
8. новый элемент используется текущим вертикальным сценарием;
9. направление dependencies соответствует этому контракту.

Пустые speculative packages, placeholder abstractions, convenience wrappers и future-framework scaffolding запрещены.

---

## 11. Persistence и восстановление состояния

### 11.1. Независимая persistence рабочих пространств

Registry Studio и Translator имеют отдельные persisted workspaces.

При уходе приложения в background, завершении процесса, закрытии и повторном запуске каждое рабочее пространство восстанавливает последнее состояние до собственного явного reset action.

### 11.2. Сохраняемое состояние Registry Studio

Registry Studio сохраняет:

- загруженную revision;
- предыдущую известную revision;
- revision clean baseline;
- последний analysis;
- очередь проблем;
- выбранный status filter;
- search и filters;
- открытый `RegistryPath`;
- выбранный block;
- позицию навигации по проблемам;
- текущий внутренний change set;
- proposals и решения инженера;
- возвращённый Translator draft;
- неутверждённый final diff.

### 11.3. Сохраняемое состояние Translator

Translator сохраняет:

- source content;
- Registry context, когда он передан;
- рабочие значения RU / EN / TH;
- reverse checks;
- warnings;
- текущий результат;
- intended target и placement request;
- не возвращённый draft.

### 11.4. Независимая очистка

Крестик Translator очищает только текущее состояние Translator и не возвращённый Translator handoff draft.

Reset Registry Studio очищает только текущую незавершённую работу Registry Studio:

- selection;
- временные filters, когда это определено reset contract;
- текущий draft change set;
- неутверждённые proposals и decisions;
- неутверждённый final diff.

Reset Registry Studio не удаляет:

- последний Registry snapshot;
- clean baseline;
- analysis history;
- applied-change history;
- publication evidence;
- Translator workspace.

Любой destructive reset требует явного подтверждения с точным описанием удаляемых и сохраняемых данных.

### 11.5. Поведение ручного обновления

Круговая стрелка Registry:

- загружает последнюю точную revision;
- повторно запускает analysis;
- пытается восстановить открытый контекст по stable identity и path;
- явно сообщает о перемещённом, изменённом или удалённом target;
- не очищает текущую работу.

---

## 12. История

История обязательна.

Registry Studio сохраняет:

- timestamp загрузки;
- source revision;
- previous revision;
- revision clean baseline;
- обнаруженные изменения;
- обнаруженные проблемы;
- решения инженера;
- handoffs в Translator и возвращённые drafts;
- принятые и отклонённые proposals;
- final diff;
- применённый patch;
- resulting revision;
- validation;
- evidence успеха publication, failure или rollback.

История отображается как последние инженерные работы внутри Registry Studio, а не как экран generic operation lifecycle.

---

## 13. Правила dependencies и impact

Impact analysis охватывает полный структурный Registry и доказательства project adapter.

Приоритет доказательств:

1. stable typed reference;
2. явный `RegistryRelation`;
3. adapter-defined reuse contract;
4. stable identity и owning business block;
5. точный normalized canonical reuse с контекстным доказательством;
6. structural или textual similarity только как semantic candidate.

Обязательные результаты:

- direct dependencies;
- transitive dependencies;
- dependency paths;
- confirmed relations и evidence;
- semantic candidates и причины;
- unresolved coverage;
- affected branches;
- unaffected locations только при наличии exclusion evidence;
- обработка cycles;
- deterministic ordering.

Text similarity само по себе никогда не становится confirmed dependency.

---

## 14. Безопасная publication

Registry Studio генерирует deterministic patch только из окончательного утверждённого change set.

Перед apply:

- base revision должна совпадать;
- final diff должен совпадать с утверждённым content;
- validation должна по-прежнему проходить;
- каждое затронутое место должно иметь решение инженера;
- не должно оставаться unresolved candidate или conflict.

Partial application запрещено, когда оно оставляет Registry в несогласованном состоянии.

После apply сохраняются:

- утверждённый diff;
- source revision;
- resulting revision;
- все затронутые identities и paths;
- результат validation;
- publication evidence;
- failure или rollback evidence.

---

## 15. Языковой контракт

Интерфейс приложения поддерживает:

- RU;
- EN;
- TH.

Значок глобуса открывает компактный selector. Выбранный язык интерфейса сохраняется между запусками.

Язык содержимого Registry и язык UI являются разными сущностями.

Нормативный язык архитектурного контракта, инженерного review и взаимодействия с пользователем по Registry Studio — русский. Модель или инженерный помощник НЕ ДОЛЖЕН переходить на английский язык из-за английских identifiers или source fragments.

Все explanations для инженера должны быть ясными на выбранном языке интерфейса. Code identifiers, paths, APIs, schemas и configuration остаются английскими.

---

## 16. Последовательность реализации

### Этап 0 — Recovery foundation

- создать recovery branch от проверенного technical baseline;
- сохранить чистый Core из `6fd3260`;
- удалить преждевременное generic operation и workspace ownership;
- установить минимальную composition;
- доказать успешные tests, analyze, build и APK.

### Этап 1 — Полная видимость Registry и persistence

- exact source snapshot;
- полный structural index;
- раскрываемый и доступный для поиска Registry;
- ручное обновление круговой стрелкой;
- автоматическая persistence и restore сессии;
- отслеживание previous revision;
- история загрузок.

### Этап 2 — Автоматический анализ изменений

- comparison с previous revision;
- comparison с clean baseline;
- очередь проблем;
- точная навигация по проблемам;
- полноэкранная очередь проблем;
- история изменений.

### Этап 3 — Канонический анализ бизнес-логики

- загрузить Canonical Dictionary;
- структурно обнаружить допустимую бизнес-область;
- классифицировать все допустимые бизнес-фразы;
- status counters и filters в Registry;
- точная навигация по canonical status;
- отсутствие фиксированного количества каталога, последовательности уровней или закрытого списка node kinds.

### Этап 4 — Двусторонняя передача в Translator

- отправка phrase/selection с точным контекстом;
- редактирование или создание formulation;
- RU / EN / TH и reverse checks;
- placement request;
- возврат в Registry Studio;
- независимые persistence и clearing.

### Этап 5 — Impact, proposals и review инженера

- preflight;
- direct/transitive dependency graph;
- классификация confirmed и candidate;
- proposals по каждому месту;
- contextual review panels;
- completeness и validation;
- final diff.

### Этап 6 — Безопасный apply

- whole-set approval;
- deterministic patch;
- rejection stale revision;
- guarded publication;
- resulting revision и rollback evidence.

Каждый этап завершается рабочим APK и явным acceptance инженера до начала следующего этапа.

---

## 17. Безусловные запреты

Rebuild ЗАПРЕЩЕНО:

- воссоздавать Translator-centric ownership;
- создавать generic workflow engine;
- выставлять внутренний operation lifecycle как продуктовую навигацию;
- создавать God App, God Workspace или глобальный God Cubit;
- использовать фиксированное количество элементов каталога;
- использовать static manifest как границу Registry scope;
- использовать line numbers как постоянную identity;
- классифицировать технические разделы Registry как canonical business phrases;
- считать text similarity подтверждённой зависимостью;
- применять частичный несогласованный change set;
- применять изменение к stale revision;
- позволять Translator или Admin Panel утверждать либо публиковать изменения Registry;
- терять незавершённую работу при backgrounding или restart;
- очищать одно рабочее пространство reset другого;
- делать refresh эквивалентом reset;
- создавать speculative helpers, wrappers, managers, facades, utilities или generic repositories.

---

## 18. Проверяемые возможности продукта

Реализация соответствует контракту только тогда, когда все группы возможностей ниже доказаны фактически.

### Состояние Registry и автоматический анализ

- Открыть Registry Studio и показать точную текущую source revision.
- Автоматически анализировать каждую успешную загрузку и ручное обновление.
- Показывать изменения относительно предыдущей известной revision.
- Показывать расхождения с последним подтверждённым инженером clean baseline.
- Сохранять clean baseline до его явного изменения инженером.

### Навигация по проблемам

- Показывать компактную очередь проблем в Registry Studio.
- Открывать ту же очередь полноэкранно без создания отдельного технического product screen.
- Напрямую открывать каждый точный проблемный блок Registry.
- Переходить к предыдущей и следующей проблеме без возврата к полному дереву.
- Показывать точные `RegistryPath`, evidence, reason, revision и status.

### Динамическое покрытие Registry

- Рекурсивно просматривать и искать по Registry tree произвольного расширения.
- Обнаруживать новые node types и вложенность через structural indexing и project schema.
- Не использовать фиксированные предположения о categories, entities, scenarios, phrases или depth.
- Сохранять видимость структурно обнаруженных веток даже при отсутствии semantic manifest entry.

### Канонический анализ

- Читать встроенный словарь по stable markers и `Dictionary ID`, а не по видимому heading.
- Ограничивать status counters допустимой бизнес-областью.
- Фильтровать Registry phrases по `Exact`, `Equivalent`, `Review`, `Drift`, `Failed` и neutral state.
- Открывать каждый status result в точном контексте Registry.
- Сохранять различие между canonical ownership, translation quality и dependency evidence.
- Позволять авторизованному инженеру добавлять новую canonical phrase через reviewed dictionary change.

### Цикл Registry Studio и Translator

- Отправлять полную phrase, выбранный fragment или выбранный block в Translator с точным Registry context.
- Редактировать существующую phrase или создавать новую formulation.
- Подготавливать и проверять RU / EN / TH и reverse checks.
- Указывать target, operation, anchor, position, applicability и rationale.
- Возвращать draft в Registry Studio без прямой publication.

### Внутренний анализ и решение инженера

- Автоматически выполнять preflight, structural comparison, text diff, impact analysis, duplicate checks, canonical checks, completeness и validation.
- Разделять confirmed dependencies и semantic candidates.
- Показывать proposal каждого затронутого места в контексте.
- Требовать явное решение инженера для каждого unresolved place.
- Инвалидировать stale analysis и approval после релевантных изменений content или source revision.

### Безопасный apply и evidence

- Показывать полный final diff.
- Требовать whole-change-set approval.
- Отклонять apply при stale source revision.
- Применять только точный утверждённый набор.
- Возвращать resulting revision или явное failure/rollback evidence.
- Сохранять immutable publication evidence и history.

### Persistence и независимая очистка

- Восстанавливать незавершённую работу Registry Studio и Translator после backgrounding, process death, закрытия и restart.
- Сохранять независимость состояний Registry Studio и Translator workspace.
- Крестиком Translator очищать только работу Translator.
- Круговой стрелкой Registry выполнять reload и reanalysis без очистки текущей работы.
- Реализовать reset Registry Studio как отдельное подтверждаемое действие.
- Сохранять Registry history, clean baseline и applied-change evidence после reset текущей работы.

---

## 19. Запись синхронизации контракта

Эта объединённая редакция подготовлена из двух исходных документов:

- SHA-256 исходного engineering-change contract: `3ffa5e50a109d8f47c19ece84d93ff61f2cc91e1d3763a9308a007a1bd95e5c6`;
- SHA-256 нового product/architecture/canonical contract ветки: `87c0307c44f8058ae14866805afca64ad6ad4c48659ca00b873a9f5aa1394db0`.

Применённые правила синхронизации:

- текущее количество элементов каталога не используется как архитектурная граница;
- фиксированная последовательность глубины ветки не используется как универсальная модель;
- сохранены исходные требования к dependencies, proposals, revisions, completeness, human authority, ordered Guidance, application-code dependencies и safe apply;
- внутренние инженерные механизмы остаются автоматическими и контекстными внутри Registry Studio;
- Registry Studio и Translator остаются единственными основными рабочими пространствами инженера;
- встроенный Canonical Dictionary поддерживается инженером внутри этого единого контракта;
- установленный путь в репозитории и стабильный Contract ID остаются authoritative;
- нормативный текст контракта приведён к русскому языку без перевода стабильных технических identifiers и без изменения утверждённых канонических фраз.

После commit этой объединённой русской редакции прежняя англоязычная редакция и старые standalone documents считаются superseded.

---

## 20. Итоговое определение продукта

```text
Registry Studio непрерывно отслеживает и объясняет состояние Registry
→ инженер открывает точные проблемные бизнес-места
→ Translator помогает создать или изменить формулировку
→ инженер возвращает точный placement request
→ Registry Studio проверяет request по полному Registry
→ инженер рассматривает каждое затронутое место
→ Registry Studio применяет только полное утверждённое изменение
→ clean baseline и history сохраняют полную прослеживаемость
```

Registry Studio и Translator являются двумя основными рабочими пространствами инженера.

Registry Studio остаётся владельцем целостности Registry, автоматического analysis, impact, review, approval context и safe apply.

Translator остаётся рабочим пространством инженера для формулировок с точным intent возврата и placement в Registry.

Инженер остаётся окончательной инстанцией принятия решения.

---

## 21. Встроенный словарь канонических бизнес-формулировок

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

---

## 22. Контекст канонического анализа бизнес-формулировок

Единицей канонического анализа является бизнес-формулировка вместе с полным контекстом:

`business entity + content block + optional scenario context + exact source evidence`.

Каждая бизнес-сущность может иметь сценарии или не иметь их. Количество сценариев и уровень их выбора не кодируются фиксированным списком категорий, названий сценариев или глубины Registry.

Каждая бизнес-сущность Helpy предоставляет стабильные типы бизнес-блоков:

- вопросы;
- фото-вопросы;
- правила клиента;
- правила мастера.

Helpy adapter распознаёт business entity, business block, опциональный scenario context и точную строку источника. Универсальный модуль `canonical` получает generic identities и labels и не распознаёт Helpy-specific категории, сценарии или Markdown headings.

Правила клиента и правила мастера могут различаться между сценариями. Canonical applicability, comparison, duplicate analysis и completeness analysis не должны смешивать формулировки разных scenario contexts.

Добавление новых категорий, сущностей и сценариев не требует изменения универсального `canonical`, если project adapter передаёт тот же generic context contract.

---

## 23. Разрешение применимости Canonical Dictionary

Universal `canonical` не интерпретирует project-specific строки применимости. Generic resolver возвращает `applicable`, `notApplicable` или `unresolved`. Project adapter сопоставляет applicability со structured candidate context. `Exact` для constrained entry допустим только с `CanonicalConfirmedApplicationEvidence`. Неизвестная применимость остаётся `Review`; явно неприменимая entry исключается из exact matches.
