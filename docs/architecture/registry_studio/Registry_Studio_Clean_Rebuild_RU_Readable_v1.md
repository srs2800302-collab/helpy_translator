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

- `cac4461 feat: add typhoon translator phrase provider`

До него закрыты:

- `14a6d2b docs: define translator infrastructure provider ownership`;
- `dbdeec8 docs: record translator phrase use case implementation`;
- `76da30c feat: add translator phrase use case boundary`;
- `d977ae0 docs: define translator use case boundary ownership`;
- `81a8fa9 docs: define translator provider boundary ownership`;
- `6965024 docs: record translator phrase result implementation`;
- `7d69068 feat: add translator phrase result model`.

---

## 13. Что сейчас ещё не закрыто

После реализации `TyphoonTranslatorPhraseProvider` нужен отдельный docs checkpoint в Guard.

Нельзя сразу переходить к runtime wiring.

Причина:

- wiring создаёт новую responsibility;
- wiring может вернуть legacy bootstrap shape;
- wiring может случайно связать Translator с old repository/data source;
- wiring может затронуть `main.dart`;
- wiring может превратиться в composition/root ownership decision.

---

## 14. Следующий правильный шаг

Следующий шаг:

1. Зафиксировать в Guard checkpoint реализации `TyphoonTranslatorPhraseProvider`.

После этого отдельно провести ownership-аудит runtime wiring:

- где создаётся `TyphoonTranslatorPhraseProvider`;
- кто создаёт `TranslatePhrase`;
- является ли wiring частью current app bootstrap;
- нужна ли отдельная Registry Studio composition boundary;
- почему wiring не возвращает `TranslatorRepository`;
- почему wiring не подключает registry loading;
- почему wiring не создаёт operation attachment;
- почему wiring не создаёт mutation/approval/publication path.

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
