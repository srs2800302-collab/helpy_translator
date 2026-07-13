# Registry Studio Engineering Change Propagation and Approval Contract v1

Contract ID: `REGISTRY_STUDIO_ENGINEERING_CHANGE_PROPAGATION_AND_APPROVAL_V1`

Status: **APPROVED — REGISTRY STUDIO PRODUCT AND WORKFLOW SOURCE OF TRUTH**

Repository: `helpy_translator_registry_studio_clean`

Helpy is the first project adapter and pilot. Helpy does not own the universal Registry Studio architecture.

## 1. Назначение

Registry Studio является самостоятельным инженерным инструментом для поддержания Registry в целостном, согласованном и каноническом состоянии.

Registry Studio должен помогать инженеру после точечных изменений бизнес-логики, а также при прямой инженерной работе с Registry.

Основная задача:

1. Получить исходное изменение или прямую инженерную задачу.
2. Определить созданные, изменённые, удалённые или перемещённые данные.
3. Найти все прямые и транзитивные зависимости.
4. Проанализировать каждое зависимое место в полном контексте его ветки.
5. Подготовить точные предложения там, где результат однозначен.
6. Отдельно показать всё, что требует решения инженера.
7. Позволить инженеру изменить, подтвердить или отклонить каждое место.
8. Проверить полноту всего change set.
9. Показать итоговый diff.
10. Внести только полный согласованный комплект после явного одобрения инженера.

Registry Studio не имеет права самостоятельно принимать бизнес-, семантические, канонические или публикационные решения.

## 2. Причина clean rebuild

Первая версия создавалась как отдельный Helpy Translator.

Позднее вокруг одной translator-centric сущности были добавлены:

- Registry Explorer;
- загрузка и ручное обновление Registry;
- поиск;
- статусы формулировок;
- persistence;
- history;
- рабочие сессии;
- дополнительные инженерные функции.

Registry был встроен внутрь архитектуры Translator.

По мере роста функциональности ответственности смешались, производительность деградировала, появились зависания и ANR.

Эта ветка была заморожена.

Translator был возвращён к стабильной версии до появления Registry-интеграции.

Новая система развивается от Registry как основной инженерной платформы.

Translator является подключаемой инженерной capability, но не владельцем Registry, dependency analysis, change propagation, approval или publication.

## 3. Первый pilot

Первым pilot-проектом является Helpy.

Helpy Registry содержит реальные:

- категории;
- Entity;
- Scenario;
- Scenario Entry Evidence;
- Questions;
- Answer Options;
- Qualifiers;
- Photo Questions;
- Photo Sources;
- Photo Limits;
- Client Guidance;
- Master Guidance;
- Canonical Dictionary;
- Admin Panel contracts;
- другие Helpy-specific semantics.

Helpy-specific semantics принадлежат Helpy adapter boundary.

Universal Registry Studio Core не должен содержать Helpy-specific бизнес-логику.

## 4. Источник первичного бизнес-изменения

Первичным источником бизнес-изменения является администратор проекта через Admin Panel.

Администратор может точечно создать, изменить, отключить или удалить разрешённую бизнес-конфигурацию.

Admin Panel ещё не реализована.

Её полный контракт хранится в Helpy Registry.

До реализации Admin Panel Registry Studio pilot должен использовать вход, эквивалентный утверждённому выходу Admin Panel, без создания альтернативной бизнес-семантики.

Admin Panel отвечает за точечное бизнес-изменение.

Admin Panel не обязана:

- искать все зависимости;
- исправлять весь Registry;
- выполнять полную канонизацию;
- проводить полный RU / EN / TH review;
- принимать инженерное решение;
- публиковать Registry от имени инженера.

Результат Admin Panel является входом Registry Studio engineering review.

## 5. Прямая инженерная задача

Инженер может создать задачу без предварительного изменения Admin Panel.

Допустимые задачи включают:

- сравнение Entity и Scenario;
- поиск расхождений канона;
- замену semantic block;
- копирование semantic block;
- копирование полного Scenario;
- точечное добавление формулировки;
- удаление элемента;
- замену элемента;
- перемещение элемента;
- изменение порядка;
- переработку формулировки;
- подготовку Canonical Dictionary entry;
- исправление canonical drift.

Прямая задача подчиняется тем же требованиям анализа, validation, completeness gate и engineer approval.

## 6. Представление исходного изменения

Registry Studio должен получить или восстановить:

- стабильную identity;
- исходное состояние;
- предлагаемое новое состояние;
- тип операции;
- источник;
- проект и adapter;
- Source Evidence;
- RegistryPath;
- контекст ветки;
- базовую source revision;
- связь с инженерной операцией.

Инженеру показываются:

- что изменено;
- старое значение;
- новое значение;
- точное место;
- source identity;
- target identity;
- source evidence;
- предполагаемая область воздействия.

## 7. Поиск зависимостей

Registry Studio должен находить все места, которые прямо или косвенно зависят от изменённого элемента.

Поиск не ограничивается одинаковым текстом.

Учитываются:

- stable typed references;
- RegistryRelation;
- Registry dependencies;
- повторное использование канонических формулировок;
- Scenario Entry Evidence;
- Question references;
- Answer Option references;
- Qualifier references;
- Photo Question reuse;
- Photo Limits;
- Client Guidance;
- Master Guidance;
- Canonical Dictionary candidates;
- project-specific adapter semantics;
- подтверждённые структурные связи;
- подтверждённые семантические связи;
- semantic candidates.

Текстовое совпадение без доказанной семантической связи является кандидатом, а не подтверждённой зависимостью.

Registry Studio должен обходить прямые и транзитивные зависимости до полного построения затронутого change graph.

## 8. Классы найденных связей

Каждое найденное место классифицируется как:

### 8.1. Подтверждённая зависимость

Связь доказана stable identity, typed reference, relation, reuse contract или другим adapter-defined evidence.

### 8.2. Semantic candidate

Связь вероятна по тексту, структуре или смыслу, но не доказана.

Semantic candidate требует проверки инженера.

### 8.3. Не затронуто

Место исключается только с объяснимым доказательством отсутствия зависимости.

## 9. Контекст каждой зависимости

Каждое место анализируется отдельно в полном контексте ветки.

Для Helpy service-intake обязательна структура:

    Entity
    → Scenario
      → Scenario Entry Evidence
      → Questions
        → Answer Options
        → Qualifiers
      → Photo Questions
        → Applicability Qualifiers
        → Photo Source
        → Photo Limits
      → Client Guidance
      → Master Guidance

Разные Scenario одной Entity могут иметь разные Questions, Photo Questions, Limits, Guidance и условия применимости.

Исправление, корректное для одного Scenario, не считается автоматически корректным для другого.

Registry Studio должен показывать путь ветки и доказательства, на которых основан вывод.

## 10. Классификация предлагаемого изменения

### 10.1. Однозначное предложение

Предложение считается однозначным, когда результат полностью следует из:

- stable identity;
- typed dependency;
- канонического источника;
- полного контекста;
- подтверждённого правила операции;
- отсутствия семантической неоднозначности.

Registry Studio может подготовить точный patch, но не применять его автоматически.

### 10.2. Требуется решение инженера

Инженерное решение обязательно, когда:

- связь является semantic candidate;
- одинаковый текст используется с разным смыслом;
- контекст веток требует разных результатов;
- изменяется бизнес-смысл;
- изменяется область применимости;
- требуется структурная переработка;
- требуется новая каноническая формулировка;
- расходятся RU / EN / TH;
- изменяется Guidance sequence;
- изменяется Photo reuse или Photo Limit semantics;
- отсутствует полная зависимость;
- есть конфликт источников;
- обнаружен canonical drift;
- точность изменения невозможно доказать.

Registry Studio обязан остановить такое место и показать причину.

## 11. Рабочий экран инженера

Рабочий экран должен показывать:

- исходную задачу;
- source и target identities;
- все найденные ветки;
- change graph;
- прямые и транзитивные зависимости;
- подтверждённые зависимости;
- semantic candidates;
- полный контекст;
- исходное значение;
- предлагаемое значение;
- структурный diff;
- причину предложения;
- нерешённые вопросы;
- RU / EN / TH состояние;
- статус решения;
- completeness status.

Инженер может:

- открыть любую ветку;
- перейти к любому элементу;
- изменить предложение;
- подтвердить его;
- отклонить его;
- указать собственное решение;
- передать формулировку в Translator;
- вернуть Translator result в ту же операцию;
- повторно запустить анализ;
- просмотреть revisions;
- отменить операцию;
- подтвердить итоговый change set.

## 12. Translator integration

Любая формулировка Registry должна открываться в Translator нажатием.

Обязательный цикл:

    формулировка из Registry
    → открыть в Translator
    → переработать RU / EN / TH
    → получить verdict, warnings и audit commentary
    → вернуть candidate в текущую инженерную операцию
    → повторно найти и проверить все зависимости
    → инженер исправляет или подтверждает каждое место
    → completeness gate
    → явное одобрение инженера
    → внесение согласованного комплекта

Translator отвечает за:

- работу с формулировкой;
- RU / EN / TH перевод;
- reverse semantic verification;
- verdict;
- warnings;
- audit commentary;
- candidate canonical phrase;
- ручную переработку инженером.

Translator не отвечает за:

- поиск зависимостей;
- выбор всех мест применения;
- изменение Registry;
- утверждение канонического статуса;
- approval;
- publication.

Translator result является инженерным входом, а не разрешением на изменение.

## 13. Трёхъязычный контур

Helpy использует:

- RU;
- EN;
- TH.

Формулировка не считается завершённой без проверки всего трёхъязычного контура.

Registry Studio показывает:

- RU;
- EN;
- TH;
- reverse checks;
- semantic drift;
- terminology drift;
- ambiguity;
- отсутствующий или неподтверждённый язык.

Однозначность одного языка не доказывает однозначность полного change set.

## 14. Revisions

Каждое изменение хранится как revision текущей инженерной операции.

Revision сохраняет:

- identity изменяемого места;
- исходное значение;
- предлагаемое значение;
- полный working content;
- тип операции;
- источник предложения;
- dependency context;
- решение инженера;
- previous revision lineage;
- связанные identities;
- RU / EN / TH results;
- audit references.

Свободное редактирование не отменяет completeness gate.

## 15. Completeness gate

Изменения нельзя применять, пока существует хотя бы одно место со статусом:

- not analyzed;
- dependency unresolved;
- semantic candidate unresolved;
- engineer decision required;
- translation incomplete;
- canonical drift unresolved;
- conflict unresolved;
- proposal not reviewed;
- dependent branch inconsistent;
- Source Evidence missing;
- validation failed.

Перед готовностью Registry Studio должен доказать:

1. Найдены все доступные зависимости.
2. Каждая зависимость классифицирована.
3. Каждое неоднозначное место получило решение инженера.
4. Все затронутые RU / EN / TH данные проверены.
5. Все revisions входят в один change set.
6. Между изменениями нет внутренних конфликтов.
7. Итоговое состояние проходит validation.
8. Инженер видит полный diff.

## 16. Human authority

Registry Studio не имеет права самостоятельно:

- подтверждать изменение;
- принимать semantic decision;
- признавать candidate каноническим;
- применять замену;
- изменять Registry;
- публиковать Registry;
- объединять pull request;
- изменять application code;
- скрывать нерешённую зависимость.

Применение разрешено только после явного решения авторизованного инженера.

Approval относится ко всему change set.

## 17. Применение

После approval Registry Studio может применить только заранее показанный change set.

Нельзя применять частичный комплект, если Registry останется несогласованным.

Если source revision изменилась после анализа:

- применение останавливается;
- исходный контекст перечитывается;
- dependency analysis повторяется;
- требуется новое подтверждение.

После применения сохраняются:

- итоговый diff;
- identities всех мест;
- source revision;
- resulting revision;
- engineer decision reference;
- audit references;
- validation result;
- publication result;
- failure или rollback evidence.

## 18. Зависимости application code

Registry change не означает автоматическое изменение приложения.

Когда изменение требует правки Flutter, backend, API, Admin Panel или другого runtime consumer, Registry Studio должен:

1. Найти подтверждённую зависимость.
2. Показать её инженеру.
3. Добавить её в change set.
4. Не считать операцию полной без решения по этой зависимости.
5. Не изменять приложение без approval.

Изменения application code допускаются только после обработки всех зависимых мест исходного изменения.

## 19. Начальная задача Helpy pilot

Не все категории, Entity и Scenario Helpy сейчас приведены к единому канону.

Первая практическая задача Registry Studio — ускорить их канонизацию без ручного обхода каждой Entity и каждого Scenario.

Registry Studio должен:

- сравнивать однотипные Entity;
- сравнивать Scenario;
- сравнивать semantic blocks;
- находить отсутствующие элементы;
- находить дополнительные элементы;
- находить различия текста;
- находить различия структуры;
- находить различия порядка;
- находить различия обязательности;
- находить различия применимости;
- находить различия references и reuse semantics;
- показывать потенциальный канонический источник;
- отделять допустимые различия от вероятной неканоничности;
- готовить точные предложения;
- передавать неоднозначные случаи инженеру.

Различие не считается ошибкой только потому, что тексты или структуры не совпадают.

Каждое расхождение проверяется по Entity, Scenario, роли, этапу workflow и adapter semantics.

Инженер может выбрать:

- категорию;
- несколько Entity;
- несколько Scenario;
- один semantic block;
- полную ветку Entity.

## 20. Управляемые инженерные операции

Инженер может явно выбрать source и target и выполнить:

- замену Client Guidance;
- замену Master Guidance;
- замену Questions;
- замену Answer Options;
- замену Qualifiers;
- замену Photo Questions;
- замену Photo Sources;
- замену Photo Limits;
- копирование semantic block;
- копирование полного Scenario;
- вставку элемента;
- удаление элемента;
- замену элемента;
- перемещение элемента;
- дополнение конкретной формулировкой.

Операция должна ссылаться на стабильные:

- RegistryEntityId;
- RegistryPath;
- Scenario key;
- semantic block key;
- item key;
- точную source identity;
- точную target identity.

UI-названия вида «Entity 2» или «Scenario Замена» не заменяют stable identity.

Перед применением Registry Studio показывает:

1. Source block.
2. Target block.
3. Структурный diff.
4. Контекст source.
5. Контекст target.
6. References.
7. Порядок.
8. Добавления.
9. Удаления.
10. Замены.
11. Перемещения.
12. Зависимости.
13. Неоднозначности.

После любой операции dependency analysis выполняется повторно.

## 21. Значимость порядка Guidance

Порядок Client Guidance и Master Guidance является доменной семантикой.

Эти элементы представляют последовательные подсказки пользователю согласно:

- роли;
- Scenario;
- этапу рабочего процесса;
- предыдущему действию;
- следующему действию;
- условиям применимости.

Registry Studio не имеет права:

- трактовать Guidance как множество;
- автоматически сортировать Guidance;
- менять порядок по текстовому сходству;
- объединять элементы без анализа роли и этапа;
- копировать элемент без сохранения или явного изменения позиции.

При изменении показываются:

- исходная последовательность;
- предлагаемая последовательность;
- добавленные элементы;
- удалённые элементы;
- перемещённые элементы;
- причина изменения;
- влияние на workflow.

Инженер может вставить элемент:

- в начало;
- в конец;
- перед выбранным элементом;
- после выбранного элемента;
- вместо выбранного элемента;
- в точную позицию.

## 22. Canonical Dictionary boundary

Helpy Canonical Dictionary является отдельным хранилищем канонических формулировок.

Он:

- не является активной runtime-конфигурацией;
- не изменяет приложение автоматически;
- не заменяет Registry;
- не доказывает применимость формулировки к конкретному Scenario;
- используется как инженерный reference source.

Registry Studio может:

- искать словарные записи;
- сравнивать Registry со словарём;
- открывать запись в Translator;
- перерабатывать RU / EN / TH;
- создавать candidate entry;
- изменять candidate;
- искать точные дубли;
- искать semantic duplicates;
- искать conflicts;
- искать потенциальные места использования.

Перед записью обязательны:

1. Exact duplicate check.
2. Semantic duplicate check.
3. Conflict check.
4. Applicability check.
5. RU / EN / TH review.
6. Reverse semantic verification.
7. Terminology drift check.
8. Ambiguity check.
9. Canonical drift check.
10. Validation.
11. Engineer review.
12. Explicit approval.
13. Audit evidence.

Canonical Dictionary entry не разрешает автоматическую замену похожих текстов Registry.

## 23. Первый обязательный сценарий канонизации

    инженер выбирает категорию
    → Registry Studio сравнивает Entity и Scenario
    → находит структурные и текстовые расхождения
    → показывает потенциальный канонический источник
    → инженер выбирает source и target
    → выбирает полный copy или точечную операцию
    → Registry Studio строит diff
    → проверяет контекст, порядок и зависимости
    → точные изменения становятся proposals
    → неоднозначные места требуют решения инженера
    → формулировка при необходимости открывается в Translator
    → RU / EN / TH candidate возвращается в операцию
    → dependency analysis повторяется
    → инженер подтверждает каждое место
    → completeness gate
    → итоговый diff
    → approval
    → применение полного change set

Реализация только поиска, source blocks, свободного редактора или revisions не является выполнением основной задачи.

## 24. Вертикальный workflow первой версии

Первая версия должна поддерживать:

    Admin Panel compatible input или прямая инженерная задача
    → определение изменения
    → поиск всех зависимостей
    → отображение веток
    → контекстный анализ
    → точные и неоднозначные proposals
    → инженерное редактирование
    → Registry formulation → Translator
    → Translator candidate → текущая операция
    → повторный dependency analysis
    → completeness gate
    → engineer approval
    → применение полного change set

## 25. Запрет архитектурного возврата

Запрещено строить Registry Studio вокруг Translator entity, Translator screen или Translator Cubit.

Запрещено объединять в одном владельце:

- Registry parsing;
- dependency analysis;
- Translator state;
- engineering operation;
- persistence;
- validation;
- approval;
- publication.

Registry является основной инженерной системой.

Translator является подключаемой capability.

Admin Panel является внешним источником точечных изменений.

Инженер является единственным владельцем итогового решения.

## 26. Критерий соответствия

Registry Studio соответствует назначению, только когда инженер может:

1. Получить Admin Panel-compatible change или создать прямую задачу.
2. Увидеть точное исходное изменение.
3. Получить полный список найденных зависимостей.
4. Увидеть все затронутые ветки.
5. Понять контекст каждого места.
6. Отделить точные предложения от неоднозначных.
7. Сравнить Entity, Scenario и semantic blocks.
8. Выполнить контролируемое копирование или точечную операцию.
9. Управлять значимым порядком Guidance.
10. Открыть любую формулировку в Translator.
11. Вернуть RU / EN / TH candidate.
12. Повторно проверить все зависимости.
13. Исправить или подтвердить каждое место.
14. Закрыть completeness gate.
15. Просмотреть итоговый diff.
16. Явно одобрить полный change set.
17. Применить только одобренный комплект.
18. Добавить Canonical Dictionary entry только после отдельной проверки и approval.

Любой более короткий workflow является подготовительной инфраструктурой, но не завершённой реализацией основной задачи.
