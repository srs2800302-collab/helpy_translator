# Registry Studio Clean Rebuild — читабельная русская версия v1

Этот документ является читабельной русской рабочей версией правил и текущего состояния Registry Studio clean rebuild.

Главный источник истины остаётся:

- `docs/architecture/registry_studio/Registry_Studio_Clean_Rebuild_Guard_v1.md`

Если этот документ и Guard расходятся, действует Guard.

---

## 1. Назначение Registry Studio

Registry Studio — самостоятельная инженерная система для работы с registry.

Её задача:

- моделировать registry;
- проверять связанные факты;
- помогать engineer видеть риск, рассинхрон и неполноту контекста;
- готовить проверенный контекст для инженерного решения;
- не принимать решение вместо engineer;
- не выполнять изменение registry без утверждённого прикладного сценария.

Registry Studio не является:

- runtime executor;
- service catalog;
- generic orchestrator;
- UI wrapper;
- helper layer;
- shortcut поверх старого translator.

---

## 2. Непереговорные правила работы

1. `Core` остаётся product-neutral.

2. `Core` не содержит project-specific названия, payloads, сценарии или бизнес-словарь.

3. Один change вводит одну responsibility.

4. Новая model допускается только после ownership-аудита:

   - identity;
   - lifecycle;
   - owner;
   - boundary;
   - invariants.

5. Новая entity/model не создаётся ради удобства.

6. Запрещены shortcut-слои:

   - helper;
   - wrapper;
   - manager;
   - facade;
   - bridge;
   - locator;
   - magic utility.

7. `Orchestrator`, если появится, остаётся только coordination boundary.

8. `Orchestrator` не выполняет workflow steps напрямую.

9. `Runtime execution` не прячется за generic abstraction.

10. `Registry mutation` допускается только через approved use case.

11. Код принимается только после:

   - boundary audit;
   - analyzer verification;
   - targeted tests, если local toolchain позволяет.

---

## 3. Термины в более читабельной русской форме

| Термин в коде/Guard | Рабочое русское понимание |
|---|---|
| Core | Ядро Registry Studio |
| product-neutral | независимый от конкретного проекта |
| boundary | граница ответственности |
| ownership audit | проверка владельца ответственности |
| use case | прикладной сценарий |
| provider | поставщик результата через утверждённую границу |
| infrastructure adapter | инфраструктурный адаптер |
| result object | объект результата без identity/lifecycle |
| entity | доменная сущность с identity/lifecycle |
| registry mutation | изменение registry |
| publication | публикация изменения |
| operation attachment | привязка факта/результата к operation |
| audit package | полный пакет проверки для решения engineer |
| source evidence | доказательство происхождения из источника |

Кодовые имена не русифицируются:

- class names;
- file names;
- directories;
- enum values;
- package imports;
- API/config/internal identifiers.

---

## 4. Главная граница human authority

Engineer остаётся владельцем решений:

- что считать канонической формулировкой;
- что считать drift;
- что считать ambiguity;
- какой change scope утверждён;
- когда можно менять registry;
- когда можно публиковать изменение.

Registry Studio может готовить факты, контекст и подсказки.

Registry Studio не должна сама принимать:

- semantic decision;
- canonicalization decision;
- approval decision;
- publication decision;
- mutation decision.

---

## 5. Что уже построено в Core

На текущей clean rebuild ветке Core содержит:

- `RegistryEntity`;
- `RegistryEntityId`;
- `RegistryEntityKind`;
- `RegistryEntityPayload`;
- `RegistryPath`;
- `RegistryRelation`;
- `RegistryRelationMeaning`;
- `RegistrySemanticContractIdentity`;
- `SourceEvidence`;
- `RegistryRelatedContext`;
- `RegistryResolvedRelatedContext`;
- `PrepareRegistryRelatedContext`;
- `PrepareRegistryResolvedRelatedContext`;
- `RegistryEngineeringOperation`;
- `RegistryEngineeringOperationStatus`;
- `CreateRegistryEngineeringOperation`;
- `TransitionRegistryEngineeringOperationStatus`.

Core сейчас не содержит:

- Translator;
- provider;
- repository;
- data source;
- runtime execution;
- mutation/publication path;
- operation attachment package;
- audit package;
- generic semantic analyzer.

---

## 6. Что уже построено в Translator boundary

Translator находится вне Core:

- production: `lib/registry_studio/translator/...`;
- tests: `test/registry_studio/translator/...`.

Реализовано:

- `TranslatorPhraseStatus`;
- `TranslatorPhraseResult`;
- `TranslatorPhraseProvider`;
- `TranslatePhrase`;
- `TyphoonTranslatorPhraseProvider`.

Translator boundary разрешена только как Registry Studio product boundary, но не как часть Core.

---

## 7. TranslatorPhraseResult

`TranslatorPhraseResult` — не entity.

Это immutable read-only result object для одной выбранной engineer phrase/text.

Он может выражать:

- source language;
- source text;
- RU / EN / TH translation values;
- reverse-check evidence;
- status;
- comment/explanation;
- optional candidate canonical phrase.

Он не имеет:

- identity;
- lifecycle;
- operation ownership;
- registry identity ownership;
- dictionary mutation ownership;
- approval ownership;
- publication ownership.

---

## 8. TranslatePhrase

`TranslatePhrase` — прикладной сценарий внутри Translator boundary.

Ответственность:

- принять `sourceText`;
- принять optional `sourceLanguageHint`;
- принять optional `engineerContext`;
- trim/normalize input;
- reject empty required `sourceText`;
- вызвать `TranslatorPhraseProvider`;
- вернуть `TranslatorPhraseResult` без изменения.

`TranslatePhrase` не должен:

- знать HTTP/Dio;
- знать Typhoon;
- знать prompt;
- знать model;
- грузить registry;
- создавать operation;
- менять operation status;
- attach-ить result к operation;
- создавать audit package;
- выполнять mutation;
- выполнять approval;
- выполнять publication.

---

## 9. TranslatorPhraseProvider

`TranslatorPhraseProvider` — application boundary для actual translation capability.

Он возвращает только:

- `TranslatorPhraseResult`.

Он не является Repository.

Он не должен:

- хранить result;
- загружать registry;
- refresh-ить registry;
- возвращать registry tree;
- выполнять cache/store behavior;
- искать registry items.

Он не является DataSource.

Он не должен задавать application language через:

- HTTP;
- Dio;
- raw vendor API;
- model name;
- prompt format;
- token settings;
- raw response parsing;
- infrastructure exception mapping.

---

## 10. TyphoonTranslatorPhraseProvider

`TyphoonTranslatorPhraseProvider` — infrastructure adapter.

Placement:

- `lib/registry_studio/translator/infrastructure/...`

Ответственность:

- implements `TranslatorPhraseProvider`;
- вызывает Typhoon chat completions через existing `ApiClient`;
- использует existing `AppConfig`;
- держит prompt construction внутри infrastructure;
- держит raw response parsing внутри infrastructure;
- маппит output в `TranslatorPhraseResult`;
- возвращает failed `TranslatorPhraseResult` при Dio/format failure.

Он не должен протекать в Core или application language.

`TranslatePhrase` не должен знать:

- Typhoon;
- HTTP;
- Dio;
- model;
- prompt;
- raw response.

---

## 11. Что нельзя переносить из legacy translator

Legacy `lib/features/translator` можно использовать только как evidence.

Допустимое evidence:

- multilingual translation shape;
- reverse-check shape;
- canonical wording status;
- needs-review/drift signal;
- comment/explanation;
- candidate canonical phrase.

Нельзя переносить как architecture:

- `TranslatorRepository`;
- `TranslatorRepositoryImpl`;
- `TranslatorRemoteDataSource`;
- `RegistryRemoteDataSource`;
- `RegistryNode`;
- `LoadRegistryTree`;
- `LoadCanonicalClientRules`;
- `AuditCanonicalClientRules`;
- `TranslatorCubit`;
- `TranslatorState`;
- persistence state;
- prompt-driven source of truth;
- Helpy-specific client-rules workflow.

---

## 12. Текущая точка ветки

Текущий закрытый commit:

- `c751236 docs: record operation workspace ci success`

Закрытая рабочая цепочка operation workspace:

- `57c3dd3 feat: add operation workspace presentation flow`;
- `3ee27ad test: stabilize operation workspace creation taps`;
- `68abc6a fix: emit operation creation callback`;
- `c751236 docs: record operation workspace ci success`.

Последний подтверждённый CI:

- workflow: `Build APK`;
- run: `29069179505`;
- job: `86286996069`;
- branch: `registry-studio/clean-rebuild`;
- head commit: `68abc6a`;
- conclusion: `success`;
- artifact: `helpy-translator-debug-apk`.

Закрытый результат:

- clean runtime composition подключён;
- Registry Studio app shell подключён;
- UI language RU/EN/TH вынесен в presentation-level state;
- operation creation screen реализован;
- operation status transition screen реализован;
- operation workspace реализован как отдельная presentation boundary;
- selected/current `RegistryEngineeringOperation` живёт только внутри operation workspace;
- `RegistryStudioApp` не хранит selected/current operation;
- `lib/main.dart` не создаёт operation;
- Core operation entity/use cases/status/id не менялись;
- repository/store/persistence/routing/Cubit/Bloc не вводились;
- readiness, related context inspection, assessment, audit package, mutation, approval и publication не добавлялись.

---

## 13. Что сейчас ещё не закрыто

После закрытия operation workspace ещё не закрыты:

- presentation consumer для `PrepareRegistryRelatedContext`;
- presentation consumer для `PrepareRegistryResolvedRelatedContext`;
- owner primary `RegistryEntity` selection;
- owner relation source;
- owner available related entities;
- runtime connection related context к workspace;
- operation attachment;
- readiness marker/getter;
- semantic assessment;
- verified audit package;
- registry mutation;
- approval;
- publication;
- persistence/store/repository.

Важно: existing Core related context contracts уже есть, но они не являются UI, presenter, view model или workflow container.

`RegistryEngineeringOperationWorkspaceScreen` сейчас не должен расширяться до related context workflow без отдельного ownership-аудита.

---

## 14. Следующий правильный шаг

Следующий шаг: отдельный docs-only ownership-аудит в Guard для related context presentation consumer.

Этот audit должен решить:

- достаточно ли существующих Core contracts;
- почему Core менять не нужно;
- почему `RegistryEngineeringOperationWorkspaceScreen` нельзя расширять прямо сейчас;
- почему `RegistryStudioApp` и `lib/main.dart` нельзя трогать;
- почему runtime connection ещё преждевременен;
- какой isolated presentation consumer допустим;
- какие inputs этот consumer получает извне;
- почему он не создаёт fake/demo/seed registry entities;
- почему он не делает readiness, assessment или audit package.

Вероятный безопасный следующий code step после такого audit:

- isolated `RegistryRelatedContextPreparationScreen`.

Этот screen может только:

- получать `RegistryStudioUiLanguage` извне;
- получать primary `RegistryEntity` извне;
- получать `Iterable<RegistryRelation>` извне;
- получать available related `Iterable<RegistryEntity>` извне;
- получать `PrepareRegistryRelatedContext` извне;
- получать `PrepareRegistryResolvedRelatedContext` извне;
- показывать related/resolved/missing facts;
- показывать presentation error.

Этот screen не должен:

- подключаться к runtime app shell;
- подключаться к operation workspace;
- attach-ить context к operation;
- вычислять readiness;
- выполнять assessment;
- создавать audit package;
- выполнять mutation, approval или publication.

---

## 15. Рабочая логика дальнейшей разработки

Каждый следующий шаг выполняется так:

1. Открываем документы и текущий код.
2. Проверяем source of truth.
3. Проводим ownership/boundary audit.
4. Формулируем короткий вывод.
5. Только потом пишем код.
6. Проверяем analyzer/tests.
7. Проверяем forbidden architecture pressure.
8. Коммитим один responsibility.
9. Фиксируем docs checkpoint, если был code step.

Работа по памяти запрещена.
