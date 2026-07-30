# Registry Studio — Helpy Canonical Adapter Implementation Runbook v1

## 1. Назначение

Runbook фиксирует контролируемый процесс завершения Helpy canonical adapter
в ветке Stage 3 Clean Rebuild.

Он не заменяет действующий Registry Studio contract, не меняет утверждённую
архитектуру и обновляется только после фактически принятого этапа.

Отклонённая, экспериментальная или архивная реализация не является
production baseline и не переносится автоматически.

## 2. Исходный checkpoint

```text
PROJECT_ROOT=/data/data/com.termux/files/home/projects/helpy_translator_translator_first_rebuild
BRANCH=registry-studio/stage3-clean-rebuild
HEAD=da65fe5d687cf5a3b1918c34f0bb793cc6c5ceae
UPSTREAM=origin/registry-studio/stage3-clean-rebuild
WORKTREE_BASELINE=CLEAN
```

Локальная ветка создана из существующей remote-tracking ветки. Новый remote
branch не создавался. Fetch, pull, commit и push не выполнялись.

## 3. Порядок источников истины

1. Прямые решения пользователя.
2. Последняя утверждённая редакция Registry Studio contract.
3. Утверждённый Stage 3 Clean Rebuild plan.
4. Clean Rebuild Guard.
5. Этот Runbook.
6. Фактические tracked-типы и invariants текущего checkpoint.
7. Фактический RegistrySnapshot.
8. Переданный Canonical Dictionary sourceContent.

При противоречии источник с более высоким приоритетом имеет преимущество.

## 4. Архитектурная граница

```text
HelpyCanonicalDictionarySource
→ HelpyCanonicalDictionaryReader
→ CanonicalDictionary

RegistrySnapshot
→ HelpyCanonicalRegistryProjector
→ typed Helpy business projection

CanonicalDictionary + typed projection
→ HelpyCanonicalAdapter
→ CanonicalAnalysisPackage
```

Adapter не должен:

- загружать или обновлять Registry;
- повторно разбирать исходный Registry Markdown;
- изменять или публиковать Registry;
- выполнять canonical matching или classification;
- создавать findings, UI counters или statuses;
- зависеть от Presentation, persistence или Translator;
- переносить Helpy-specific правила в universal modules.

## 5. Обязательные domain invariants

Каждый scenario внутри business entity владеет собственными четырьмя
content-позициями:

1. questions;
2. photoQuestions;
3. clientRules;
4. masterRules.

Эти позиции нельзя поднимать, объединять, копировать между scenario,
заполнять искусственным текстом или подменять текстом business entity.

Business entity без explicit scenario сохраняет те же четыре позиции на
уровне entity.

Canonical Dictionary является единственным подтверждённым источником
канонических формулировок.

Project projection обязана сохранять stable identity, RegistryPath,
RegistryNodeId, source order, SourceEvidence, ownership, scenario hierarchy,
selector bindings, shared/inherited/conditional context и ordered content.

## 6. Дисциплина production-изменений

Перед каждым patch необходимо:

1. проверить repository, branch, HEAD, upstream и worktree;
2. прочитать exact current files;
3. проверить SHA-256 исходных файлов;
4. зафиксировать responsibility и allowed files;
5. зафиксировать strict diff budget;
6. зафиксировать targeted tests и rollback point;
7. остановиться до записи при любом несовпадении baseline.

До независимой приёмки запрещены commit, push, merge, rebase, cherry-pick,
reset, clean, stash, новая ветка, новый worktree, dependency/pubspec changes.

Запрещены blind string patching, speculative parsing, guessed Registry
grammar, hardcoded category names, fixed scope/depth/count, positional
identity, invented content/evidence, broad catch, silent partial parsing,
silent token ignoring, dangling equivalents, silent node loss и nearest-node
fallback.

## 7. Формат контроля каждого slice

```text
CURRENT_CHECKPOINT
FILES_TO_CHANGE
RESPONSIBILITY
EXPECTED_DIFF
MAX_DIFF_BUDGET
TARGETED_TESTS
FULL_CHECKS
FORBIDDEN_CHANGES
ROLLBACK_POINT
```

После изменения выполняются независимый read-only diff audit, targeted tests,
canonical tests, full suite, flutter analyze и git diff --check. Затем
выносится GO или NO-GO. Commit создаётся только после GO. Push выполняется
отдельно после разрешения пользователя.

## 8. Phase 0 — exact baseline audit

Цель: зафиксировать нормативные SHA-256, production/read-only types, exact
code, canonical tests, placeholder/risk markers и исходные результаты tests
и analyzer. Production-код на Phase 0 не изменяется.

## 9. Phase 1 — HelpyCanonicalDictionaryReader

Основной production-файл:

```text
lib/registry_studio/adapters/helpy/canonical/helpy_canonical_dictionary_reader.dart
```

Focused test:

```text
test/registry_studio/canonical/helpy_canonical_dictionary_reader_test.dart
```

`canonical_dictionary.dart` остаётся read-only до доказанного blocker.

Reader должен проверить exact markers и metadata, разобрать все collections,
поддержать phrase, phrase_with_applicability, ordered_block,
ordered_rule_block и approved equivalents, сохранить actual source context,
создать точный one-based SourceEvidence, вернуть typed failures и отклонить
partial approved parsing.

Gate 1:

```text
DICTIONARY_PARSER_COMPLETE=YES
POSITIONAL_IDENTITIES=NO
FAKE_EVIDENCE=NO
BROAD_CATCH=NO
FOCUSED_TESTS_PRESENT=YES
TARGETED_TESTS_PASS=YES
CANONICAL_TESTS_PASS=YES
FULL_SUITE_PASS=YES
FLUTTER_ANALYZE_PASS=YES
DIFF_CHECK_PASS=YES
FORBIDDEN_FILES_CHANGED=NO
```

## 10. Phase 2 — HelpyCanonicalRegistryProjector

Основной production-файл:

```text
lib/registry_studio/adapters/helpy/canonical/helpy_canonical_registry_projector.dart
```

Focused test:

```text
test/registry_studio/canonical/helpy_canonical_registry_projector_test.dart
```

`canonical_analysis_package.dart` остаётся read-only до доказанного blocker.

Projector обязан сохранить все roots/depth, business scopes/entities,
recursive scenario tree, terminal scenarios, четыре content role, selector
bindings, qualifiers, answer-dependent branches, direct/shared/inherited/
conditional ownership, ordered content, полный node accounting и точный
SourceEvidence.

Запрещены `[ABSENT]`, invented content, копирование entity content во все
четыре роли, flat scenario list, `selectorBinding == null` как постоянный
fallback, guessed kindId, substring matching и silent node loss.

Gate 2:

```text
SCENARIO_TREE_COMPLETE=YES
FOUR_ROLES_TYPED=YES
INVENTED_CONTENT=NO
OWNERSHIP_PRESERVED=YES
ORDER_PRESERVED=YES
NODE_ACCOUNTING_COMPLETE=YES
TARGETED_TESTS_PASS=YES
CANONICAL_TESTS_PASS=YES
FULL_SUITE_PASS=YES
FLUTTER_ANALYZE_PASS=YES
DIFF_CHECK_PASS=YES
FORBIDDEN_FILES_CHANGED=NO
```

## 11. Phase 3 — HelpyCanonicalAdapter orchestration

Основной production-файл:

```text
lib/registry_studio/adapters/helpy/canonical/helpy_canonical_adapter.dart
```

Adapter сохраняет ProjectCanonicalAdapter boundary и
prepareAnalysis(RegistrySnapshot), запрашивает Dictionary source для exact
revision, проверяет path/revision/fingerprint, объединяет Dictionary и
projection, сохраняет typed operational failures и не выполняет matching или
classification.

Gate 3:

```text
ORCHESTRATION_COMPLETE=YES
INTERFACE_PRESERVED=YES
MATCHING_LOGIC_PRESENT=NO
SOURCE_CONTEXT_VALIDATED=YES
FAILURE_SEMANTICS_PRESERVED=YES
TARGETED_TESTS_PASS=YES
CANONICAL_TESTS_PASS=YES
FULL_SUITE_PASS=YES
FLUTTER_ANALYZE_PASS=YES
DIFF_CHECK_PASS=YES
FORBIDDEN_FILES_CHANGED=NO
```

## 12. Phase 4 — интеграционная приёмка

Выполняются focused canonical tests, полный canonical suite, полный Flutter
suite, flutter analyze, git diff --check, read-only boundary audit, проверка
CanonicalAnalysisPackage и build/физическая проверка при необходимости.

Push разрешается только после полной приёмки пользователем.

## 13. Текущая точка продолжения

```text
CURRENT_PHASE=0
NEXT_ACTION=READ_ONLY_EXACT_CODE_AND_TEST_BASELINE_AUDIT
PRODUCTION_PATCH_ALLOWED=NO
COMMIT_ALLOWED=NO
PUSH_ALLOWED=NO
```
