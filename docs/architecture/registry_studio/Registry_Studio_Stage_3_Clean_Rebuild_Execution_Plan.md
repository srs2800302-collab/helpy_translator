# Registry Studio — Stage 3 Clean Rebuild Execution Plan

Нормативный источник:

`Registry_Studio_Engineering_Change_Propagation_and_Approval_Contract_v1.md`, объединённая редакция `5`.

Этот документ определяет только phases, gates, evidence и stop conditions. Он не дублирует продуктовый контракт и не задаёт фиксированное количество файлов или типов.

---

## 1. Текущее инженерное решение

Stage 3 перестраивается поверх принятых Stages 1–2.

Старые Stage 3 реализации используются только как read-only evidence.

Текущие canonical production files являются unaccepted candidates до полной end-to-end приёмки.

Documentation checkpoint редакции 5 создаётся до production-патча adapter.

Documentation patch и production patch не объединяются в один commit.

---

## 2. Главная цель Stage 3

```text
RegistrySnapshot загружен
→ обнаружены category, entity и terminal scenario
→ для каждого scenario разрешены четыре effective roles
→ учтены все user-facing phrases
→ выполнено сравнение с Canonical Dictionary
→ найдены duplicates, drift, differences, missing content,
  contradictions, applicability и translation problems
→ инженер видит exact context, reason и SourceEvidence
→ refresh обнаруживает новые Registry structures без hardcoding
```

Counters, filters, persistence и navigation являются UI projection результата, а не целью Stage 3.

---

## 3. Сохраняемые и пересматриваемые кандидаты

После exact production audit допускается сохранить:

- `ProjectCanonicalAdapter`;
- typed `CanonicalDictionary`;
- typed analysis package;
- entity и scenario identities;
- scope references;
- selector references и bindings;
- four-role identifiers;
- source revision;
- `RegistryPath`;
- `SourceEvidence`;
- typed failures.

Обязательно пересматриваются:

- missing-role representation;
- implicit terminal scenario;
- `mini-TZ`;
- `mini-scope`;
- `entity-as-scenario`;
- mixed topology;
- shared/inherited content;
- selector placement отдельно от ownership;
- partial result при локальном failure;
- расширяемость внутренних adapter capabilities;
- отсутствие fixed file count;
- отсутствие God projector.

Сохранение имени type не означает принятие его текущих invariants.

Внешняя canonical boundary остаётся одна.

Второй project adapter не является обязательным условием текущего Stage 3 и не входит в Gate B, Gate C или Gate D.

Его фактическое подключение откладывается в отдельный post-Stage-3 gate.

До этого universal modules всё равно ОБЯЗАНЫ сохранять project-independent boundaries: Helpy-specific branches, fixed topology и project-specific closed enums в universal code запрещены.

Внутренние capability owners создаются только при доказанной отдельной responsibility. Их количество заранее не фиксируется.

---

## 4. Gates

### Gate A — принятые Stages 1–2

Требуется:

- accepted baseline;
- clean branch и worktree;
- exact `RegistrySnapshot`;
- recursive structural index;
- stable identities;
- persistence и принятый Explorer UX;
- tests, analyzer и APK evidence.

Текущий статус: `PASS`.

### Gate B — полный Helpy canonical adapter

Требуется:

- полный Canonical Dictionary;
- typed dictionary;
- полный recursive `RegistrySnapshot`;
- все business entities;
- explicit и implicit terminal scenarios;
- четыре effective roles каждого scenario;
- missing-role representation;
- selector placement и ownership как отдельные facts;
- shared/inherited content;
- ordered content;
- exact identities и evidence;
- typed failures;
- отсутствие silent omission;
- отсутствие повторной загрузки Registry и полного Markdown parsing;
- authoritative full-Registry proof;
- `UNKNOWN_COUNT=0`.

Adapter не присваивает canonical statuses и не содержит UI, persistence или publication.

### Gate C — universal canonical analyzer

Требуется:

- `Unclassified / Neutral`;
- `Exact`;
- `Equivalent`;
- `Review`;
- `Drift`;
- `Failed`;
- duplicates;
- semantic duplicates;
- differences;
- missing content;
- conflicts и contradictions;
- applicability;
- constrained-entry precedence и universal fallback;
- previous canonical application evidence для `Drift`;
- ordered comparison;
- translation inconsistency;
- structured failures;
- partial-results behavior.

Analyzer не знает Helpy, Markdown, category names или scenario names.

### Gate D — production Stage 3

Требуется:

- adapter/analyzer composition;
- startup analysis;
- refresh analysis;
- exact revision consistency;
- persistence;
- counters и filters;
- actionable findings;
- exact navigation;
- failure/retry;
- history;
- APK;
- physical acceptance.

Только после Gate D разрешён Stage 4.

---

## 5. Порядок реализации

### Phase 0 — Documentation checkpoint

1. Применить Contract revision 5.
2. Синхронизировать Stage 3 plan.
3. Доказать побайтную неизменность Canonical Dictionary.
4. Проверить documentation diff.
5. Создать отдельный commit и push.
6. Подтвердить clean tree и remote HEAD.

### Phase 1 — Current candidate audit

1. Прочитать каждый canonical production file.
2. Прочитать canonical tests.
3. Составить responsibility map.
4. Отделить сохраняемые types от несовместимых invariants.
5. Установить минимальный production diff budget.
6. Не изменять production code до Go.

### Phase 2 — Helpy topology projection

1. Реализовать full recursive business discovery.
2. Реализовать entity resolution.
3. Реализовать explicit и implicit terminal scenarios.
4. Реализовать four-role resolution.
5. Реализовать missing-role findings.
6. Разделить selector placement и ownership.
7. Реализовать shared/inherited content.
8. Реализовать ordered content.
9. Реализовать typed failures.
10. Доказать authoritative full-Registry coverage.

Результат: Gate B.

### Phase 3 — Universal analyzer

1. Реализовать statuses.
2. Реализовать duplicate и semantic-duplicate findings.
3. Реализовать drift и differences.
4. Реализовать missing и contradiction findings.
5. Реализовать applicability.
6. Реализовать ordered comparison.
7. Реализовать translation findings.
8. Реализовать partial-results behavior.
9. Выполнить deterministic test matrix.

Результат: Gate C.

### Phase 4 — Integration и UI

1. Composition.
2. Startup analysis.
3. Refresh analysis.
4. Persistence и restore.
5. Counters и filters.
6. Findings.
7. Exact navigation.
8. Context и evidence.
9. Failure/retry.
10. History.

UI не добавляет canonical logic в `RegistryExplorerCubit` или монолитный `RegistryExplorerView`.

### Phase 5 — Final acceptance

1. Targeted tests.
2. Full suite.
3. `flutter analyze`.
4. Format.
5. `git diff --check`.
6. APK CI.
7. Physical acceptance.
8. Clean worktree.
9. Local/remote HEAD equality.

Результат: Gate D.

---

## 6. Обязательный test matrix

Adapter:

- `mini-TZ`;
- `mini-scope`;
- `entity-as-scenario`;
- implicit scenario;
- mixed topology;
- nested selector order;
- selector outside content owner;
- shared scope;
- inherited role content;
- missing role;
- missing phrase;
- ordered content;
- technical exclusion;
- unsupported structure;
- malformed evidence;
- new category after refresh;
- new entity after refresh;
- new scenario after refresh.

Analyzer:

- exact;
- approved equivalent;
- review;
- drift;
- failed;
- neutral;
- duplicate;
- semantic duplicate;
- contradiction;
- missing content;
- constrained applicability;
- unresolved applicability;
- constrained-entry precedence и universal fallback;
- previous canonical application evidence;
- ordered mismatch;
- RU / EN / TH inconsistency.

Full-Registry tests не заменяются synthetic fixtures.

Synthetic fixtures не заменяются authoritative full-Registry proof.

---

## 7. Запреты

ЗАПРЕЩЕНО:

- fixed category names;
- fixed scenario names или count;
- fixed Registry depth;
- fixed adapter file count;
- fixed universal public type count;
- God projector;
- project-specific branch в universal code;
- silent omission;
- speculative parsing;
- повторный полный Markdown parsing после `RegistrySnapshot`;
- partial adapter acceptance;
- UI до production report;
- Stage 4 до Gate D.

---

## 8. Отчётность и stop conditions

Каждый production step сообщает:

```text
branch
HEAD
upstream
worktree status
exact files
exact diff
targeted tests
full suite when required
flutter analyze
git diff --check
remaining failures
next gate
```

При новой domain ambiguity:

1. production patch останавливается;
2. фиксируются вопрос, варианты и последствия;
3. решение принимает инженер;
4. при необходимости синхронизируется контракт.

При превышении diff budget, новой dependency или незапланированной responsibility — `NO_GO`.

---

## 9. Текущая фиксация

```text
ACCEPTED_BASELINE=STAGES_1_AND_2
OLD_STAGE3=ARCHIVED_EVIDENCE_ONLY
CURRENT_STAGE3_CODE=UNACCEPTED_CANDIDATE
CONTRACT_CHECKPOINT_REQUIRED_BEFORE_PRODUCTION_PATCH=YES
FIXED_HELPY_FILE_COUNT=FORBIDDEN
FIXED_UNIVERSAL_TYPE_COUNT=FORBIDDEN
SECOND_ADAPTER_REQUIRED_FOR_STAGE3=NO
SECOND_ADAPTER=DEFERRED_POST_STAGE3
GATE_B=NOT_PASSED
GATE_C=NOT_PASSED
GATE_D=NOT_PASSED
STAGE4=BLOCKED
```
