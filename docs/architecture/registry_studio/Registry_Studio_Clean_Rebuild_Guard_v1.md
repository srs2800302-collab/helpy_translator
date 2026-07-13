# Registry Studio Clean Rebuild Guard v1

## 1. Назначение документа
Этот документ содержит только действующие обязательные контракты Registry Studio:
- ответственности;
- архитектурные границы;
- invariants;
- обязательное поведение;
- актуальные запреты.
История разработки, закрытые аудиты, отклонённые варианты, коммиты, CI-результаты, тестовые отчёты и выполненные checkpoints в этот документ не включаются.
История принадлежит Git. Исполняемые проверки принадлежат `test/**` и CI.

## 2. Назначение продукта и human authority
Registry Studio является самостоятельным универсальным инженерным продуктом.
Core не зависит от семантики конкретного проекта.
Registry Studio предоставляет source-backed entities, relations, related context, engineering operations, revisions и read-only Translator.
Инженер является владельцем semantic decision.
Registry Studio не утверждает canonical wording, не изменяет registry и не выполняет approval или publication автоматически.

## 3. Архитектурные границы
`lib/registry_studio/core/**` содержит только product-neutral domain и application contracts.
Core не импортирует Translator, Guard infrastructure, presentation, persistence implementation, Typhoon, HTTP или app composition.
Translator является отдельной capability вне Core. Он предоставляет перевод, diagnostics и findings, но не владеет registry identity, operation lifecycle или semantic approval.
Guard владеет concrete Guard payload, чтением Guard asset и read-only presentation Guard record.
`lib/main.dart` является только composition boundary и не содержит domain policy, semantic assessment или workflow orchestration.
Новая production entity, use case или layer допускается только после подтверждения самостоятельной ответственности и отсутствия подходящего существующего owner.

### 3.1. Helpy service-intake source contracts
Helpy adapter infrastructure владеет project-specific identity manifest, source block extraction, semantic manifest и semantic decoding. Эти ответственности не принадлежат Core и не создают новый architectural layer.
`assets/registry_studio/helpy/service_intake_identity_manifest_v1.json` владеет только top-level `RegistryEntityId`, `RegistryPath` и точным H2/H3 source locator.
`ServiceIntakeIdentityManifestSource` валидирует identity manifest, а `ServiceIntakeSourceBlockExtractor` извлекает соответствующий H3 block без semantic interpretation.
`assets/registry_studio/helpy/service_intake_semantic_manifest_v1.json` отдельно владеет stable internal keys и typed references для scenarios, questions, answer options, qualifiers, photo questions, photo limits и client/master guidance. Для версии `v1` он обязан покрывать все 27 entity IDs identity manifest и не содержать неизвестных IDs.
Canonical пользовательский текст остаётся только в Helpy Registry. Semantic manifest не владеет `displayName`, `prompt`, answer text или guidance text.
Каждый stable semantic key отделён от contextual positional source locator. `occurrence` и `ordinal` являются только изменяемыми координатами locator и никогда не являются identity.
`expectedText` используется только для exact-match verification найденного source элемента и не является источником semantic content.
Абсолютные или относительные line numbers, keys из текста, fuzzy matching и fallback на первый или похожий элемент запрещены.
`ServiceIntakeSemanticManifestSource` читает и валидирует только JSON, schema version, coverage, unique keys и typed references. Он не читает Markdown и не создаёт `ServiceIntakePayload`, `RegistryEntity` или `SourceEvidence`.
Будущий `ServiceIntakePayloadDecoder` разрешает contextual locators только внутри соответствующего `ServiceIntakeSourceBlock`, требует ровно одно exact совпадение, извлекает canonical text из Registry и создаёт существующий `ServiceIntakePayload`. Decoder не изобретает identity или пользовательские формулировки.

## 4. Core invariants
`RegistryEntity` является source-backed registry unit.
Его identity определяется `RegistryEntityId`. Равенство определяется только по `id`.
`RegistryEntityPayload` определяет typed `RegistryEntityKind`. `RegistryEntity.kind` всегда равен `payload.kind`.
Каждая entity имеет непустой `SourceEvidence`.
`RegistryPath` является canonical domain path, а не Markdown path, physical source path или source locator.
`RegistryRelation` запрещает self-relation.
`RegistryRelatedContext` содержит primary entity, связанные с ней relations и derived `relatedEntityIds`. Primary id не входит в `relatedEntityIds`.
`RegistryResolvedRelatedContext` запрещает duplicates и entities вне base context. `missingRelatedEntityIds` вычисляются из unresolved ids.
Core не интерпретирует project-specific payload semantics.

## 5. Engineering operation и revisions
Статусы operation:
- `open`;
- `awaitingContext`;
- `readyForDecision`;
- `decided`;
- `cancelled`.
Новая operation всегда создаётся со статусом `open`.
Разрешённые переходы:
- `open` → `awaitingContext`, `readyForDecision`, `cancelled`;
- `awaitingContext` → `readyForDecision`, `cancelled`;
- `readyForDecision` → `awaitingContext`, `decided`, `cancelled`.
`decided` и `cancelled` являются terminal statuses.
`decisionStatement` обязателен только для `decided` и запрещён для остальных статусов.
Смена статуса не означает registry mutation, approval или publication.
`RegistryEngineeringOperationRevision` хранит полную рабочую версию, а не diff.
Revision имеет положительный последовательный `revisionNumber`, непустой `workingContent`, обязательный `primaryEntityId` и optional `previousRevisionId`.
`relatedEntityIds` не содержат duplicates и `primaryEntityId`.
Следующая revision наследует context предыдущей persisted revision, если новый context не передан.
`revisionRelatedEntityIds == null` означает наследование. Non-null collection означает явную замену, включая пустую collection.
Operation workspace и Translator history сохраняются отдельно. Persistence не владеет domain policy или semantic decision.

## 6. Translator contract
Translator принимает один обязательный `sourceText`. Source language определяется автоматически как `RU`, `EN` или `TH`.
Translation response содержит ровно девять непустых секций в фиксированном порядке:
1. `SOURCE LANGUAGE`
2. `SOURCE TEXT`
3. `RU`
4. `EN`
5. `TH`
6. `EN_TO_RU`
7. `TH_TO_RU`
8. `EN_TO_TH`
9. `TH_TO_EN`
Missing, duplicate, unexpected, переставленные, пустые или placeholder sections являются format failure.
Одна операция выполняет два последовательных `/chat/completions` request:
1. translation request — `700` tokens;
2. independent audit request — `500` tokens.
Для обоих запросов действуют параметры:
- `temperature: 0.1`;
- `top_p: 0.7`;
- `frequency_penalty: 0.0`.
`tools`, `tool_calls` и function submission не используются.
Provider не добавляет внешние кавычки к source text.
Ровно одна искусственная пара внешних кавычек, добавленная моделью вокруг полного исходника, удаляется. Пользовательские кавычки сохраняются.
Любое другое изменение `SOURCE TEXT` или секции исходного языка является semantic diagnostic и принудительно устанавливает `canonicalDrift`.
Reverse sections являются диагностическими данными, а не независимым доказательством корректности.
Audit сначала напрямую сравнивает `RU`, `EN` и `TH`, после чего может использовать reverse sections только как вспомогательные данные.
Audit возвращает ровно четыре секции:
1. `MEANING_FINDINGS`
2. `TERMINOLOGY_FINDINGS`
3. `STYLE_FINDINGS`
4. `AMBIGUITY_FINDINGS`
Каждая секция содержит `NO_FINDINGS` либо конкретный finding на русском языке.
Модель не выбирает статус и не возвращает binary verdict.
Статус выводится механически:
- meaning finding → `canonicalDrift`;
- findings отсутствуют → `exact`;
- присутствует только style finding → `equivalent`;
- остальные валидные комбинации без meaning finding → `needsReview`;
- transport или format failure → `failed`.
Исходная формулировка корректируется по итоговому статусу и конкретным findings. После корректировки выполняется полный повторный перевод и аудит.
Translator result не является automatic approval.

## 7. Guard runtime declaration
Guard является runtime asset и содержит ровно одну declaration версии `v1`.
<!-- registry-studio-guard-record:v1
{
  "entityId": "registry_studio.guard.source_contract_foundation",
  "path": [
    "registry_studio",
    "guard",
    "source_contract_foundation"
  ],
  "recordType": "decision",
  "heading": "Действующий контракт Registry Studio",
  "summary": "Актуальные обязательные границы, invariants и запреты Registry Studio.",
  "relations": []
}
-->
`RegistryStudioGuardAssetSource` читает только явно объявленные values, создаёт source-backed `RegistryEntity` и формирует `SourceEvidence` из asset path, fingerprint и диапазона declaration.
Identity, canonical path и relations не выводятся из Markdown structure.

## 8. Действующие запреты
Запрещены:
- project-specific semantics внутри Core;
- reverse dependencies из Core;
- service locator, generic manager, facade или god object;
- thin wrappers над существующими constructors;
- автоматическая registry mutation, approval или publication;
- использование reverse translation как доказательства корректности;
- добавление истории разработки и проверок в этот контракт;
- выполнение `flutter precache --linux --force` в Termux.
