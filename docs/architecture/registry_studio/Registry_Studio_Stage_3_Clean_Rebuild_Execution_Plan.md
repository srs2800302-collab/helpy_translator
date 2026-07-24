# Registry Studio — окончательный план повторной реализации Stage 3

## 1. Принятое инженерное решение

Текущая реализация Stage 3 на commit:

```text
863e5a0f8a8088c425aedb626c74cdfcad13a631
```

сохраняется только как архивное evidence и не используется как implementation baseline.

Новая работа начинается от последнего полностью принятого Stage 2 checkpoint:

```text
5863b3f78130d5e9231bde996d6620a1c0ab742e
feat: persist Registry Explorer filter
```

Сохраняются Stage 1–2 и отдельно возвращаются только физически принятые Registry UX/identity improvements, не связанные с canonical architecture.

Это не шестая полная rebuild Registry Studio. Перестраивается только Stage 3 и только его Helpy canonical adapter + universal canonical capability.

---

## 2. Главная продуктовая цель Stage 3

Инженер должен получить один законченный рабочий сценарий:

```text
Registry загружен
→ автоматически проанализированы все допустимые бизнес-формулировки
→ видны реальные counters по статусам
→ инженер выбирает статус
→ получает реальные результаты
→ открывает точное место Registry
→ видит текст, контекст, причину и evidence
→ состояние сохраняется после restart/refresh
```

Обязательные статусы:

```text
Unclassified / Neutral
Exact
Equivalent
Review
Drift
Failed
```

Дополнительно анализируются ordered canonical blocks без потери значимого порядка.

Stage 3 не считается готовым, пока вся цепочка не работает в production APK.

---

## 3. Git-стратегия восстановления

### 3.1. Архив текущего состояния

Создать неизменяемую архивную ветку:

```text
registry-studio/stage3-archive-863e5a0
```

Она фиксирует текущий HEAD `863e5a0...` и остаётся только для сравнения/evidence.

### 3.2. Новая рабочая ветка

Создать ветку:

```text
registry-studio/stage3-clean-rebuild
```

от:

```text
5863b3f78130d5e9231bde996d6620a1c0ab742e
```

### 3.3. Возврат только принятых non-canonical улучшений

Не переносить текущую canonical implementation.

Вернуть одним консолидированным production commit только следующие принятые поведения:

- container открывается как subtree;
- единый reset icon;
- structural icons;
- structural roles;
- отсутствие duplicate scope clear;
- корректная filter presentation;
- сохранение hierarchy icons;
- запрет повторного использования retired Registry identity.

Source commits используются только как evidence для ручного переноса поведения:

```text
89b50d371917d6998e46ffec04125e6c3d6c770a
e2cc39bb7efd577491371ecde835d926fab95283
c8583804ef810c9683cdfe7e6344677562d6b84f
841ff724fcaea99623de1e02380f376a03dc209b
570d0e4a93fed5aa6b042749d35fc166d2ef212d
ea30553a5b6b544853f4149eec245ecb2673f4a3
935c1ea826a7c99ce2eec77e4861eb6efdacf3ce
eac040fe4f34469ee75c224f45904544382c76a0
```

Автоматический blind cherry-pick запрещён, потому что commits могли затрагивать уже появившийся canonical UI. Переносится поведение, а не историческая архитектура.

### 3.4. Текущий контракт

После восстановления Stage 2 переносится текущая утверждённая редакция контракта отдельным commit:

```text
Contract SHA-256:
10d3b66fe054bde748201b39681ec05fd92c0ae5bd53b752532856f904ce39e0
```

Старые canonical production files не переносятся.

---

## 4. Три крупные приёмки

Работа больше не разбивается для пользователя на десятки незавершённых классов.

### Gate A — восстановленный Stage 2

Должны быть доказаны:

- правильный branch/HEAD;
- clean working tree;
- Stage 1–2 functionality;
- все принятые Explorer UX/identity behaviors;
- full tests;
- analyzer;
- APK;
- физическая проверка.

Только после Gate A начинается новый adapter.

### Gate B — полностью готовый Helpy canonical adapter

Adapter считается готовым только целиком:

- читает полный Canonical Dictionary;
- строит typed dictionary;
- рекурсивно извлекает всю допустимую business scope;
- формирует полный structured canonical input;
- сохраняет entity/block/scenario/source evidence;
- поддерживает ordered blocks;
- не классифицирует;
- не содержит UI;
- не содержит persistence;
- не содержит write/publication;
- не повторяет полный Registry loader;
- проходит полный adapter test suite.

Никакая отдельная часть adapter не объявляется завершённой до Gate B.

### Gate C — полностью рабочий Stage 3

Должны работать:

- все статусы;
- counters;
- filters;
- findings;
- ordered blocks;
- exact navigation;
- persistence;
- refresh/failure/retry;
- history;
- APK;
- физическая приёмка.

Только после Gate C разрешён Stage 4.

---

# 5. Финальная архитектурная схема

## 5.1. Полный production flow

```text
GitHub Registry source
        │
        ▼
существующий Helpy Registry loader (Stage 1–2)
        │
        ▼
RegistrySnapshot
        │
        ├──────────────────────────────────────┐
        │                                      │
        ▼                                      ▼
HelpyCanonicalAdapter                 Canonical Dictionary source
        │                                      │
        └───────────────┬──────────────────────┘
                        ▼
          CanonicalAnalysisPackage
          ├── typed dictionary
          ├── business locations
          ├── ordered business blocks
          ├── structured context
          └── exact source evidence
                        │
                        ▼
             AnalyzeCanonicalRegistry
                        │
                        ▼
             CanonicalAnalysisReport
          ├── location results
          ├── ordered-block results
          ├── counts
          ├── actionable findings
          ├── neutral results
          └── structured failures
                        │
             ┌──────────┴──────────┐
             ▼                     ▼
      canonical persistence   Registry UI projection
                                    │
                                    ▼
                    counters → filter → exact navigation
```

---

## 5.2. Единственная project-facing canonical граница

```dart
abstract interface class ProjectCanonicalAdapter {
  Future<CanonicalAnalysisPackage> prepareAnalysis({
    required RegistrySnapshot snapshot,
  });
}
```

Это один capability-specific adapter contract Stage 3.

Он не является универсальным God adapter проекта. Он отвечает только за подготовку project-specific canonical input.

Universal analyzer получает уже typed данные и не знает о:

- Helpy;
- Markdown;
- названиях категорий;
- названиях сценариев;
- `RegistryPath:` как строковом syntax;
- heading rules;
- GitHub coordinates.

---

# 6. Окончательная иерархия Helpy canonical adapter

```text
lib/registry_studio/adapters/helpy/
├── application/
│   └── contracts/
│       └── helpy_registry_node_identity_store.dart
│
├── registry/
│   ├── github_registry_document_source.dart
│   ├── helpy_registry_document_interpreter.dart
│   ├── helpy_registry_node_identity_ledger_source.dart
│   ├── helpy_registry_snapshot_loader.dart
│   └── json_file_helpy_registry_node_identity_store.dart
│
└── canonical/
    ├── helpy_canonical_adapter.dart
    ├── helpy_canonical_dictionary_reader.dart
    └── helpy_canonical_registry_projector.dart
```

Существующие Registry Stage 1–2 files могут сохранять текущие физические пути при первом восстановлении. Перемещение их в `registry/` допускается только если оно не создаёт функциональный риск; оно не является обязательным условием Stage 3.

## 6.1. `helpy_canonical_adapter.dart`

Единственная публичная точка Stage 3 внутри Helpy package.

Ответственность:

```text
получить RegistrySnapshot
→ загрузить exact Canonical Dictionary source
→ вызвать dictionary reader
→ вызвать Registry projector
→ вернуть CanonicalAnalysisPackage
```

Запрещено:

- классифицировать статусы;
- считать counters;
- создавать findings;
- управлять UI;
- сохранять workspace;
- повторно загружать Registry;
- выполнять publication.

## 6.2. `helpy_canonical_dictionary_reader.dart`

Ответственность:

- найти stable begin/end markers;
- проверить `Dictionary ID`;
- прочитать version/status;
- прочитать approved collections;
- создать phrase entries;
- создать approved equivalents;
- преобразовать applicability в typed context constraints;
- создать ordered blocks и ordered items;
- сохранить exact source evidence;
- отклонить malformed approved data как structured adapter failure.

После reader по production flow не передаются raw applicability strings.

## 6.3. `helpy_canonical_registry_projector.dart`

Ответственность:

- рекурсивно обойти существующий `RegistrySnapshot`;
- не использовать fixed root category list;
- не использовать fixed tree depth;
- определить business ownership по Helpy Registry structure;
- выделить business entity;
- определить один из четырёх Helpy content blocks:
  - questions;
  - photo questions;
  - client rules;
  - master rules;
- определить optional scenario context;
- выделить business formulations;
- выделить ordered business blocks;
- сохранить stable location identity;
- сохранить `RegistryPath`;
- сохранить exact `SourceEvidence`;
- исключить technical/governance/admin content на основании structural rules.

Projector не читает Canonical Dictionary и не присваивает canonical status.

---

# 7. Минимальная universal canonical иерархия

```text
lib/registry_studio/canonical/
├── application/
│   ├── project_canonical_adapter.dart
│   └── analyze_canonical_registry.dart
│
├── domain/
│   ├── canonical_dictionary.dart
│   ├── canonical_analysis_package.dart
│   └── canonical_analysis_report.dart
│
├── persistence/
│   └── canonical_analysis_store.dart
│
└── presentation/
    └── canonical_analysis_cubit.dart
```

Никаких дополнительных файлов без отдельного доказательства необходимости.

## 7.1. `canonical_dictionary.dart`

Содержит только:

- dictionary identity/version;
- phrase entries;
- approved equivalents;
- typed applicability constraints;
- ordered blocks.

Не создаются отдельные `Vocabulary`, `EntryIndex`, `OrderedBlockIndex`.

## 7.2. `canonical_analysis_package.dart`

Содержит:

- dictionary;
- business locations;
- ordered business blocks;
- adapter failures;
- exact Registry revision;
- exact dictionary revision.

Не создаются отдельные `Candidate`, `CandidateIndex`, `SessionInput`.

## 7.3. `canonical_analysis_report.dart`

Содержит:

- `CanonicalStatus`;
- results по каждой location;
- ordered-block results;
- counts;
- actionable findings;
- structured failures;
- Registry revision;
- dictionary revision.

Не создаются отдельные `ClassificationIndex`, `FindingIndex`, `AnalysisResultIndex`.

## 7.4. `analyze_canonical_registry.dart`

Один deterministic analyzer.

Он обязан в первой полной реализации поддержать:

- `Exact`;
- `Equivalent`;
- `Review`;
- `Drift`;
- `Failed`;
- `Unclassified / Neutral`;
- constrained applicability;
- unresolved applicability;
- universal fallback;
- duplicate/conflict/coverage findings;
- ordered-block comparison;
- previous canonical application evidence.

Отдельные classifier/resolver/runner/session classes не создаются.

## 7.5. `canonical_analysis_store.dart`

Feature-owned persistence:

- exact Registry revision;
- exact dictionary revision;
- report;
- previous confirmed canonical applications;
- selected canonical filter;
- analysis timestamp;
- structured failures.

Canonical persistence не добавляется в `RegistryExplorerCubit`.

## 7.6. `canonical_analysis_cubit.dart`

Владеет только:

- запуском adapter;
- запуском analyzer;
- loading/ready/failure state;
- restore persisted report;
- refresh/retry без потери filter.

Business classification rules в Cubit запрещены.

---

# 8. Разрешённые production-типы

Полный allowlist новых публичных типов Stage 3:

```text
ProjectCanonicalAdapter
CanonicalDictionary
CanonicalAnalysisPackage
CanonicalAnalysisReport
CanonicalStatus
AnalyzeCanonicalRegistry
CanonicalAnalysisStore
CanonicalAnalysisCubit
HelpyCanonicalAdapter
HelpyCanonicalDictionaryReader
HelpyCanonicalRegistryProjector
```

Вложенные immutable value types допускаются внутри трёх domain files, если они непосредственно являются полями package/report/dictionary.

Новый отдельный production file/type запрещён, пока не доказано, что его обязанность:

1. не помещается в allowlist owner;
2. нужна текущему end-to-end Stage 3;
3. имеет реального producer и consumer;
4. уменьшает, а не дублирует logic;
5. не является `Index`, `Resolver`, `Runner`, `Manager`, `Facade`, `Coordinator`, `Utility`.

---

# 9. Запрещённые конструкции

Не создаются:

```text
CanonicalCandidateIndex
CanonicalClassificationIndex
CanonicalFindingIndex
CanonicalVocabulary
CanonicalSessionRunner
CanonicalApplicabilityResolver
CanonicalPipelineCoordinator
CanonicalManager
CanonicalFacade
CanonicalRepository<T>
```

Также запрещено:

- raw Helpy applicability parsing в universal modules;
- отдельный parser для approved equivalent;
- повторный полный Markdown parsing после `RegistrySnapshot`;
- fixed category names в universal code;
- fixed scenario count;
- fixed Registry depth;
- status enum без production producer;
- test, который доказывает только нулевой count;
- новая Stage 3 logic в `RegistryExplorerCubit`;
- новый Stage 3 UI внутри монолитного метода `RegistryExplorerView`;
- второй project adapter до Gate C;
- Stage 4 до полной физической приёмки Stage 3.

---

# 10. Порядок реализации

## Phase 0 — Recovery

Результат: Gate A.

1. Архивировать `863e5a0`.
2. Создать новую ветку от `5863b3`.
3. Вернуть одним commit принятые Registry UX/identity behaviors.
4. Перенести текущий contract.
5. Запустить full tests/analyzer/diff check.
6. Собрать APK.
7. Провести физическую проверку Stage 2.

## Phase 1 — Полностью построить Helpy canonical adapter

Результат: Gate B.

Одним законченным adapter block:

1. Создать universal boundary models, необходимые adapter.
2. Создать три Helpy canonical files.
3. Реализовать dictionary reader полностью.
4. Реализовать Registry projector полностью.
5. Реализовать adapter orchestration.
6. Добавить real-contract test.
7. Добавить representative full-Registry fixture tests.
8. Доказать:
   - recursion;
   - no fixed categories;
   - four blocks;
   - optional scenarios;
   - exact evidence;
   - typed applicability;
   - ordered blocks;
   - technical exclusions.
9. Не подключать UI/analyzer/persistence.

Adapter не принимается частями.

## Phase 2 — Полностью реализовать universal analyzer

1. Реализовать все шесть statuses.
2. Реализовать ordered blocks.
3. Реализовать duplicate/conflict/coverage.
4. Реализовать structured failures.
5. Реализовать previous application evidence для `Drift`.
6. Один полный test matrix.
7. Никакого UI.

Analyzer не принимается с пустыми statuses.

## Phase 3 — Связать adapter и analyzer

1. Composition.
2. Startup auto-analysis.
3. Refresh auto-analysis.
4. Exact revision consistency.
5. Fatal/partial failure behavior.

После этой фазы production report существует, но UI ещё не считается принятым.

## Phase 4 — Persistence и Registry UI

1. Persist report и filter.
2. Restore.
3. Counters.
4. Filter.
5. Findings.
6. Exact navigation.
7. Failure/retry preservation.
8. Context details/evidence.
9. History.

UI реализуется через небольшие видимые sections, а не добавлением новых обязанностей в монолитный Explorer.

## Phase 5 — Final Stage 3 acceptance

Результат: Gate C.

- full tests;
- analyzer;
- format;
- diff check;
- APK CI;
- physical device acceptance;
- реальные ненулевые примеры всех применимых statuses;
- controlled fixture для `Drift` и `Failed`;
- ordered-block demonstration;
- restart/refresh/failure/retry;
- exact navigation;
- clean tree;
- local/remote HEAD match.

---

# 11. Правило отчётности

Пользователю больше не предъявляются как «результат»:

- созданный enum;
- новый index;
- новый resolver;
- пустой filter;
- unit test отдельной модели;
- количество добавленных классов.

Отчёт формируется только по крупному gate:

```text
Что теперь реально может сделать инженер
Какая полная цепочка работает
Какие файлы добавлены
Какие файлы удалены
Production LOC before/after
Какие обязательные statuses реально произведены
Какая проверка выполнена на APK
```

---

# 12. Критерий остановки

Если во время реализации возникает потребность добавить тип или subsystem вне утверждённой иерархии:

```text
работа останавливается
→ показывается конкретная недостающая ответственность
→ доказывается, почему allowlist недостаточен
→ инженер принимает или отклоняет изменение архитектуры
```

Модель не имеет права самостоятельно расширять архитектуру.

---

# 13. Финальная фиксация

```text
BASELINE=5863b3f78130d5e9231bde996d6620a1c0ab742e
CURRENT_STAGE3=ARCHIVE_ONLY
NEW_BRANCH=registry-studio/stage3-clean-rebuild
PROJECT_ADAPTERS=1
HELPY_CANONICAL_FILES=3
UNIVERSAL_CANONICAL_PUBLIC_TYPES=8
SECOND_ADAPTER=DEFERRED_UNTIL_FINAL_ACCEPTANCE
STAGE4=BLOCKED
WORK_MODE=COMPLETE_MAJOR_GATES_ONLY
```
