# Helpy Architecture Registry v1 Foundation

Status: APPROVED ✅

Approved By:
- Roman ✅
- Arthur ✅

## Contract Map / Architecture Groups
Status: APPROVED ✅

Purpose:
- Provide a logical navigation layer over the Architecture Registry.
- Preserve the historical recovery order of contracts.
- Group contracts by architectural responsibility without physically moving existing sections.
- Support closure planning before final Roadmap and new database design.

Rule:
- This map does not replace or rewrite existing contracts.
- Physical regrouping is deferred until Registry v2.
- Contract closure decisions must still be made inside the source contracts.
- New Registry changes should be written in Russian by default.
- English remains allowed for API paths, database entities, enum values, code identifiers and migration names.
- Реестр считается архитектурно зрелым и в основном финализированным.
- Будущие изменения должны в первую очередь выполнять аудит, синхронизацию и закрытие уже утверждённых решений.
- Новые архитектурные решения допускаются только при доказанном GAP, противоречии между контрактами или новой утверждённой бизнес-модели.
- Бизнес-логика, сценарии и пояснительный текст оформляются на русском языке.
- Технические идентификаторы остаются на английском языке, включая API paths, database entities, enum values, event_type, DTO, migrations, slugs и file names.
- Утверждённые контракты усиливаются через синхронизацию, а не переписываются без доказательств.

### Group A — Foundation / Product Identity
Scope:
- Product identity.
- Long-term architecture principles.
- Core product and business model.
- Chat governance.
- Reference standards.
- Deferred categories.
- Future business direction.
- Recovery methodology.
- Guided Job Flow foundation.

Contracts:
- Contract 1 — Project Identity — CLOSED.
- Contract 2 — Long-Term Architecture Principle — CLOSED.
- Contract 3 — Core Product Principle — CLOSED.
- Contract 4 — Core Business Model — CLOSED.
- Contract 5 — Chat Governance — CLOSED.
- Contract 8 — Reference Category Standard — CLOSED.
- Contract 9 — Specialized Reference Categories — CLOSED.
- Contract 10 — Electrical Shower Policy — CLOSED.
- Contract 11 — Deferred Categories — CLOSED.
- Contract 18 — Future Business Direction — PARTIALLY CLOSED — FUTURE STRATEGY APPROVED.
- Contract 19 — Registry Expansion Plan — CLOSED — RECOVERY METHODOLOGY APPROVED.
- Contract 39 — Guided Job Flow Foundation — APPROVED ✅.

Closure Notes:
- Foundation is architecturally aligned.
- Future verticals remain post-MVP and require dedicated future contracts.

### Group B — Service Registry / Categories
Scope:
- Root categories.
- Category governance.
- Reference category completion.
- Service-specific question flows, photos, rules, playbooks and admin dependencies.

Contracts:
- Contract 6 — Approved Root Categories — PARTIALLY CLOSED.
- Contract 7 — Category Governance — PARTIALLY CLOSED.
- Contract 20 — Furniture Assembly — CLOSED — STORED + DOCS VERIFIED.
- Contract 21 — Cleaning — CLOSED — STORED + DOCS VERIFIED.
- Contract 22 — Air Conditioning — CLOSED — APPROVED / STORED + DOCS VERIFIED.
- Contract 23 — Electrical — CLOSED — STORED + CATEGORY ARCHITECTURE VERIFIED.
- Contract 24 — Plumbing — CLOSED — STORED + DOCS VERIFIED.
- Contract 25 — Locks — CLOSED — STORED + DOCS VERIFIED.

Closure Notes:
- Electrical is CLOSED and migrated to the current Plumbing-level Registry template.
- Appliance Installation & Connection remains the final required MVP root category before root category closure.
- Categories must support future expansion without schema redesign.

### Group C — Admin / Dynamic Forms / Knowledge / Guidance
Scope:
- Admin as Business Logic Builder.
- Dynamic Form Engine.
- Knowledge Base Engine.
- Guidance Builder.
- Guidance API.
- Mobile guidance slots and rendering.

Contracts:
- Contract 12 — Knowledge Base Engine — PARTIALLY CLOSED.
- Contract 13 — Dynamic Form Engine — PARTIALLY CLOSED.
- Contract 17 — Admin Panel Architecture — PARTIALLY CLOSED — GAP APPROVED.
- Contract 40 — Contextual Guidance Knowledge System — APPROVED ✅.
- Contract 41 — Mobile Guidance Slots Contract — APPROVED ✅.
- Contract 46 — Guidance API Contract — APPROVED ✅.
- Contract 47 — Mobile Guidance Component Contract — APPROVED ✅.

Closure Notes:
- Dynamic Form Engine closure depends on final pure dynamic vs hybrid decision.
- Admin Panel closure depends on builders, platform settings, guidance, rules, evidence, review and DB baseline strategy alignment.
- Guidance implementation requires future DB/API/mobile implementation planning, not direct migration from contract text alone.

### Group D — Order Lifecycle / Timeline / Chat / Evidence
Scope:
- Chat lifecycle.
- Immutable job_events timeline.
- Timeline API.
- Communication layer separation.
- Chat threads.
- Evidence photos.
- Canonical order lifecycle.

Contracts:
- Contract 26 — Chat Lifecycle Rules / Job Events / Timeline API — APPROVED GLOBAL RULE ✅ + GAP_APPROVED timeline sections.
- Contract 30 — Chat Evidence Photos & Job Details Photo Ownership — APPROVED ✅.
- Contract 32 — Communication Layer / Business Timeline Contract — GAP_APPROVED.
- Contract 33 — Chat Threads Architecture Decision — GAP_APPROVED.
- Contract 37 — Structured Job Scope / Price Justification Contract — APPROVED ✅.
- Contract 38 — Helpy Canonical Order Lifecycle Contract — GAP_APPROVED.

Closure Notes:
- Runtime must emit the full canonical timeline before timeline-related contracts can close.
- chat_threads must become the canonical chat context model in the future database.
- job_events remains the immutable lifecycle source of truth.

### Group E — Offers / Pricing / Payments / Financial Snapshot
Scope:
- Client Expected Price.
- Final Agreed Price.
- Offer lifecycle.
- Payment runtime for Thailand.
- Immutable financial snapshot.

Contracts:
- Contract 31 — Client Expected Price / Final Price Contract — APPROVED ✅.
- Contract 34 — Offer Lifecycle Architecture Decision — GAP_APPROVED.
- Contract 35 — Thailand Payment Runtime Architecture Decision — APPROVED ✅.
- Contract 36 — Final Price Architecture Decision — GAP_APPROVED.

Closure Notes:
- Canonical default deposit / commission percent is 30% of Final Agreed Price.
- 40% is rejected as incorrect legacy Chain 0001 value.
- Deposit / commission percent must be configurable from Admin Panel.
- jobs.deposit_percent stores the Admin-configured percent active at master selection.
- Historical financial snapshots must not be recalculated after Admin changes.
- Offer lifecycle and financial snapshot must be implemented in the future clean database/runtime design.

### Group F — Reviews / Reputation / Ranking / Language Matching
Scope:
- Reviews.
- Reputation metrics.
- Language matching.
- Master ranking.
- Client choice model.

Contracts:
- Contract 29 — Reviews & Reputation System — APPROVED ✅.
- Contract 42 — Language Matching Principle — APPROVED ✅.
- Contract 43 — Language Matching Ranking Rule — APPROVED ✅.
- Contract 44 — Master Ranking Signal Hierarchy — APPROVED ✅.
- Contract 45 — Master Ranking Hybrid Model Contract — APPROVED ✅.

Closure Notes:
- Reviews require admin moderation and anti-abuse rules before full closure.
- Ranking separates eligibility, ordering and client choice.
- Language matching is a ranking signal, not a hard eligibility filter.

### Group G — Recovery / Global Rules
Scope:
- Lost approved global platform rules.
- Recovery from approved sources.

Contracts:
- Contract 16 — Global Platform Rules — PARTIALLY CLOSED — RECOVERED FROM VERIFIED CATEGORY SOURCES.

Closure Notes:
- Seven global rules were previously approved, but their detailed texts are missing.
- Rules must be recovered from approved documentation, service playbooks, category records and approved history.
- Replacement rules must not be invented without evidence.

### Critical Closure Path
1. Recover Contract 16 Global Platform Rules.
2. Contract 23 Electrical — CLOSED.
3. Finalize Appliance Installation & Connection.
4. Close Contract 6 and Contract 7 root category governance.
5. Close Contract 13 Dynamic Form Engine decision.
6. Align Contract 17 Admin Panel Architecture.
7. Close canonical runtime/database group: Contracts 26, 32, 33, 34, 36 and 38.
8. Define Review moderation and anti-abuse rules for Contract 29.
9. Produce final Roadmap.
10. Design new clean database from the completed Roadmap and closed architecture contracts.

---

## Architecture Freeze Decision
Status: APPROVED ✅

Purpose:
- Preserve the agreed critical path.
- Prevent premature work on lifecycle architecture.
- Allow category completion without reopening already stabilized decisions.
- Provide a deterministic restart point if chat context is degraded.

Frozen Contracts:
- Contract 13 — Dynamic Form Engine.
- Contract 16 — Global Platform Rules.
- Contract 26/32/33/34/36/38 — Lifecycle Architecture Group.

Frozen Scope:
- Timeline.
- Chat Threads.
- Offer Lifecycle.
- Final Price Snapshot.
- Canonical Lifecycle.
- Clean Database Design.

Active Scope:
- Contract 23 — Electrical — CLOSED.
- Appliance Installation & Connection.
- Closure of Contract 6.
- Closure of Contract 7.

Unfreeze Conditions:
1. Electrical reaches CLOSED.
2. Appliance Installation & Connection reaches CLOSED.
3. Contract 6 reaches CLOSED.
4. Contract 7 reaches CLOSED.
5. Contract 16 is reconciled against DOCX/TXT evidence.

Next Milestone After Unfreeze:
- Close Lifecycle Architecture Group.
- Produce Final Roadmap.
- Design the new clean database.

Execution Order:
1. Extract Plumbing Category Development Methodology.
2. Contract 23 Electrical — CLOSED against Plumbing Standard.
3. Close Contract 23.
4. Complete Appliance Installation & Connection.
5. Close Contract 6 and Contract 7.
6. Reconcile Contract 16 against DOCX/TXT evidence.
7. Unfreeze Lifecycle Architecture Group.
8. Close Contracts 26/32/33/34/36/38.
9. Produce Final Roadmap.
10. Design the new clean database.

Process Rule:
- Work must follow the approved execution order.
- Earlier frozen milestones cannot be reopened without documentary evidence.
- Later milestones cannot start before prerequisite milestones are closed.
- Chat context degradation must not be used as justification to bypass the approved sequence.

---

## 1. Project Identity
Status: CLOSED

Decision Summary:
- Project identity is fixed for MVP.
- Helpy is an Android-first household services marketplace for Pattaya, Thailand.
- Supported product languages are RU / EN / TH.
- No unresolved architecture decisions remain in this contract.

- Project Name: Helpy
- Region: Pattaya, Thailand
- Platform: Android First
- Languages: RU / EN / TH
- Business Model: Marketplace of household services

## 2. Long-Term Architecture Principle
Status: CLOSED

Decision Summary:
- MVP may simplify or postpone complex features.
- MVP must preserve future expansion points.
- Architecture must not introduce dead ends or require full platform rewrite later.
- Business logic requiring admin control must not be hardcoded.
- No unresolved architecture decisions remain in this contract.

MVP must not block future platform development.

Allowed:
- simplify MVP;
- postpone complex features;
- reserve future expansion points.

Forbidden:
- architectural dead ends;
- hardcoded business logic where admin control is required;
- decisions requiring full platform rewrite later.

## 3. Core Product Principle
Status: CLOSED

Decision Summary:
- Client does not choose a master profession directly.
- Client chooses the work type.
- Client answers system-defined questions for the selected work type.
- Client adds the photos required by the system for assessment and routing.
- Platform uses category, answers, and photo requirements to route the job to relevant masters.
- Category exists for platform routing and master visibility, not as a profession selector for the client.
- No unresolved architecture decisions remain in this contract.

Client chooses problem, not profession.

Client describes the problem.
Platform determines the required specialist.

## 4. Core Business Model
Status: CLOSED

Decision Summary:
- 30% is the default platform commission value.
- Platform commission value is editable from Admin Panel without application release.
- Commission source depends on selected payment method.
- Thailand Payment Runtime Architecture Decision has priority.
- No unresolved architecture decisions remain in this contract.


Canonical business flow is defined by:
- Helpy Canonical Order Lifecycle Contract;
- Client Expected Price / Final Price Contract;
- Thailand Payment Runtime Architecture Decision.

Default Platform Commission:
30% of Final Agreed Price

Commission / Payment Source:
- PromptPay QR: client pays platform deposit.
- Bank Transfer: client pays platform deposit with manual/verified confirmation.
- Cash: client pays master directly; platform creates master commission obligation.

Commission Value:
Editable from Admin Panel.

Rule:
Commission source depends on selected payment method.
Core Business Model must not override the Thailand Payment Runtime Architecture Decision.

## 5. Chat Governance
Status: CLOSED

Decision Summary:
- Chat is mandatory for the order workflow.
- Chat stores agreements between client and master.
- Chat messages are evidence.
- Photos shared in chat are evidence.
- Admin can access any chat for moderation, support, and dispute resolution.
- Disputes must consider chat history.
- No unresolved architecture decisions remain in this contract.

- Chat is mandatory.
- Chat stores agreements.
- Chat is evidence.
- Photos in chat are evidence.
- Admin can access any chat.
- Disputes must consider chat history.

## 6. Approved Root Categories
Status: PARTIALLY CLOSED

Decision Summary:
- MVP root category set is not fully closed yet.
- The currently approved closed root categories are listed below.
- One required MVP root category remains to be finalized before this contract can be CLOSED.
- Root categories are client work/problem entry points, not master profession selectors.
- Root categories are used for routing, marketplace visibility, and admin control.
- Final database architecture and Admin Panel must support at least 20 root categories without schema redesign or application rewrite.

Closed Categories:
- Cleaning
- Air Conditioning
- Plumbing
- Electrical
- Locks
- Furniture Assembly

Next Category Required Before Final Closure:
- Appliance Installation & Connection
- Установка и подключение бытовой техники

## 7. Category Governance
Status: PARTIALLY CLOSED

Decision Summary:
- Category governance is aligned with the Approved Root Categories contract.
- Six MVP root categories are currently closed.
- One final MVP root category remains to be finalized before launch.
- No additional categories may be added before MVP launch.
- Category scaling starts only after real marketplace statistics are collected.
- Final database architecture and Admin Panel must support at least 20 root categories without schema redesign or application rewrite.

Helpy Categories

1. Cleaning
2. Air Conditioning
3. Plumbing
4. Electrical
5. Locks
6. Furniture Assembly

Electrical Category Architecture:
Status: CLOSED ✅

Purpose:
- Provide the category-level source of truth for Create Job screen design.
- Keep Electrical category navigation, form architecture, photo rules, client/master rules and admin dependencies in one place.
- Contract 23 remains the audit/history source; this category block is the practical implementation reference.

Root Category:
Electrical

Root Question:
Что нужно сделать?

Launch Branches:
- Установить розетку/выключатель.
- Заменить розетку/выключатель.
- Перенести розетку/выключатель.

Excluded From MVP:
- Автоматы / электрощит.
- Прокладка проводки.
- Замена проводки.
- Аварийная электрика.

Disabled On Launch:
- Освещение.
- Потолочные вентиляторы.

Moved / Future:
- Диагностика неисправности is moved to future Global Diagnostics.
- Appliance connection belongs to Appliance Installation & Connection.

Form Pattern:
- Electrical uses Point-Based Mini Scope Pattern.
- One physical work point equals one mini technical assignment.
- A mini assignment groups all data related to that point.
- Quantity is determined by the number of added mini scopes, not by a separate quantity question.

Mini Scope Contains:
- work type;
- point-specific parameters;
- required photos for that point.

Photo Pattern:
- Electrical uses Visual Coverage Principle.
- Photos must visually cover the work points.
- One photo may cover multiple points if they are clearly identifiable.
- Total photo limit per order remains 10.
- Equipment photos do not replace work-front photos.

Equipment Verification:
- If new items are already on site, client adds a general photo of those items.
- One photo may cover multiple identical items if the master can identify type, model and quantity.
- Equipment verification helps the master assess compatibility before Final Agreed Price.

Future Launch Category:
- Appliance Installation & Connection
- Установка и подключение бытовой техники

Rules:
- Appliance Installation & Connection is designed as the final category before MVP Launch.
- До запуска платформы новые категории не добавляются.
- Масштабирование категорий начинается только после получения реальной статистики.

## 8. Reference Category Standard
Status: CLOSED

Decision Summary:
- Plumbing is the reference category standard for Helpy.
- Every category must reach Plumbing-level detail before it can be considered complete.
- The required minimum architecture sections are fixed in this contract.
- This contract defines the quality gate for all category work.
- No unresolved architecture decisions remain in this contract.

Reference Category:
- Plumbing

Definition:
- Plumbing является эталонной категорией Helpy.
- Все категории сравниваются с уровнем детализации Plumbing.

Minimum Architecture Standard:

- Business Scope
- Definitions
- Question Flow
- Required Photos
- Service Playbook
- Business Rules
- Admin Rules
- GAP
- Registry Storage

Rule:
- Категория считается завершённой только после достижения уровня детализации Plumbing.
## 9. Specialized Reference Categories
Status: CLOSED

Decision Summary:
- Cleaning and Furniture Assembly use specialized business logic.
- Specialized categories are not required to replicate Plumbing structure.
- Specialized categories must not provide a lower level of detail than Plumbing.
- Specialized categories may diverge in form, but never in completeness.
- No unresolved architecture decisions remain in this contract.

Categories:
- Cleaning
- Furniture Assembly

Definition:
- Данные категории используют собственную бизнес-логику.
- Они не обязаны повторять структуру Plumbing.

Rule:
- Уровень детализации не может быть ниже Plumbing.
## Roadmap Decision → Appliance Installation & Connection Architecture

Status: GAP_APPROVED / ROADMAP STORED ✅

Decision Summary:
- Appliance Installation & Connection remains the final unresolved MVP root category before root category closure.
- The category must be designed around the client's real-life scenario, not around technical installation taxonomy.
- MVP launch scope is intentionally narrow and works only with new equipment scenarios.
- Work with used / previously owned household appliances is disabled on launch because of hidden defects, unclear condition, warranty risk and dispute risk.
- Used appliance scenarios are architecturally supported as disabled / future branches.
- Used appliance scenarios may be enabled later through Admin Panel after market demand audit, risk review and operational validation.

MVP Architecture:
Appliance Installation & Connection
├─ Установить новую технику
└─ Заменить существующую технику

MVP Scenario Rules:
- Установить новую технику means the client has new equipment on site and needs installation / connection.
- Заменить существующую технику means the client has new equipment on site and existing equipment must be removed before the new equipment is installed.
- Replacement includes removal / dismantling of existing equipment.
- Separate appliance dismantling is not an MVP launch branch.
- Подключить имеющуюся технику is not an MVP launch branch because it usually means used / previously installed equipment.
- If new equipment was physically placed by another party but still requires connection, the scenario remains Установить новую технику.

MVP Equipment List Rule:
- MVP uses a fixed short equipment list plus Другая бытовая техника.
- The goal is to avoid a large catalogue before launch and collect real demand after launch.
- Current MVP candidates:
  - Стиральная машина.
  - Посудомоечная машина.
  - Измельчитель пищевых отходов / Waste disposer.
  - Другая бытовая техника.

Built-in Classification Rule:
- Built-in remains a technical work-mode classification, not a separate root category.
- The client is asked one simple routing question after selecting the appliance type:
  Техника встроенная?
  - Да
  - Нет
- If the client selects Да, the flow redirects to Kitchen Built-in Appliances.
- If the client selects Нет, the flow continues inside the standard Appliance Installation & Connection scenario.
- The purpose of this question is routing and mistake prevention, not collecting technical specifications.
- The question must not include Не знаю because that option creates weak UX and may make the client feel incompetent.

Kitchen Built-in Appliances Direction:
- Kitchen Built-in Appliances is a Phase 2 branch inside Appliance Installation & Connection, not a separate root category.
- Kitchen Built-in Appliances covers more complex kitchen-related appliance installation scenarios.
- It exists because these scenarios intersect with Kitchen Assembly, niches, furniture, water, drainage, ventilation and electrical readiness.
- Kitchen Built-in Appliances may use mini-scope / add-more architecture similar to Electrical point-based flows when multiple appliances are involved.

Linked Jobs Rule:
- Kitchen Assembly and Kitchen Built-in Appliances must remain separate jobs.
- For the client, they may be presented as one connected kitchen project.
- For the platform, they keep separate deposits, statuses, disputes, reviews and completion logic.
- The system should support a logical Linked Jobs Group between related orders.

Mandatory Guided Transition:
- Kitchen Assembly must be able to guide the client into Kitchen Built-in Appliances.
- Appliance flows must route the client into Kitchen Built-in Appliances through the approved routing question:
  Техника встроенная?
  - Да
  - Нет
- If the client selects Да, the system shows:
  Для встроенной техники используется отдельный сценарий заказа.

  [Продолжить]
- Kitchen Assembly prompt pattern:
  Хотите сразу создать заказ
  на установку встроенной техники?

  [Да, продолжить]
  [Нет, позже]

## Appliance Mini-TZ Standard

Status: APPROVED / STORED ✅

Назначение:
- Этот стандарт применяется к обычной бытовой технике внутри Appliance Installation & Connection.
- Стандарт фиксирует единый порядок проектирования mini-ТЗ сценариев «Установить и подключить» и «Заменить».
- Appliance Mini-TZ Standard используется для снижения дублей, устранения расхождений между сценариями и формирования единых правил Guided Job Flow.
- Обычная бытовая техника работает как mini-ТЗ ветка: клиент выбирает конкретную технику, отвечает на минимальные routing-вопросы и прикрепляет required photos для формирования initial structured job scope.
- Если техника встроенная, клиент переводится в Kitchen Built-in Appliances.

Базовое правило сценариев:
- Сценарий «Установить и подключить» является базовым сценарием.
- Сценарий «Заменить» состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- После завершения демонтажа установленного оборудования сценарий «Заменить» использует правила сценария «Установить и подключить», если иное не указано явно.
- Отдельный демонтаж бытовой техники не является MVP-сценарием внутри Appliance Installation & Connection.

Routing Rule:
- Для техники, которая может быть встроенной, система задаёт вопрос:
  Техника встроенная?
  - Да.
  - Нет.
- Если клиент выбирает «Да», система показывает сообщение:
  Для встроенной техники используется отдельный сценарий заказа.
  [Продолжить]
- После этого клиент переводится в Kitchen Built-in Appliances.
- Вариант «Не знаю» не используется, чтобы не создавать слабый UX и не снижать уверенность клиента.

Алгоритм работы мастера для обычной бытовой техники:
1. Проверка оборудования до установки.
2. Демонтаж установленного оборудования — только для сценария «Заменить».
3. Установка и подключение.
4. Проверка подключений.
5. Проверка работоспособности.
6. Проверка качества установки, если такая проверка явно описана в mini-ТЗ конкретной техники.

Правило проверки оборудования:
- До начала установки мастер обязан выполнить визуальный осмотр оборудования.
- Проверка включает наличие видимых механических повреждений.
- Мастер обязан проверить комплектность оборудования и наличие штатных элементов подключения или установки.
- При обнаружении повреждений мастер обязан зафиксировать их на фотографиях и направить клиенту через чат приложения до продолжения работ.
- Если клиент подтверждает продолжение работ, подтверждение клиента и фотографии становятся частью доказательной базы заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

Правило демонтажа:
- Демонтаж установленного оборудования применяется только в сценарии «Заменить».
- Демонтаж выполняется в пределах стоимости услуги замены.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.
- Вынос или утилизация демонтированного оборудования не входят в базовую стоимость услуги и могут быть согласованы отдельно через чат.

Правило установки и подключения:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Если для подключения требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.
- Упаковка товара является собственностью клиента.
- Вынос или утилизация упаковки не входят в стоимость услуги.

Правило электрической готовности:
- До начала подключения мастер обязан проверить наличие электропитания в точке подключения.
- Поиск неисправностей электропроводки не входит в объём услуги установки.
- Электрическая готовность регулируется Global Electrical Readiness Rule.

Правило проверки работоспособности:
- После подключения мастер обязан выполнить базовую проверку работоспособности оборудования в пределах согласованного объёма заказа.
- Проверка выполняется безопасным способом и только в рамках характера выполненных работ.
- Проверка работоспособности не является диагностикой скрытых дефектов оборудования.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Terminology Normalization Rule:
- Для техники и оборудования, находящихся на объекте до начала работ, используется термин «установленное оборудование».
- Примеры:
  - установленная стиральная машина;
  - установленная посудомоечная машина;
  - установленный измельчитель пищевых отходов;
  - демонтаж установленного оборудования.
- Термин «существующий» используется для инфраструктуры объекта и элементов, не являющихся оборудованием.
- Примеры:
  - существующая система водоотведения;
  - существующий вывод водоотведения;
  - существующее подключение;
  - существующая электропроводка;
  - существующая электрическая точка подключения.
- Формулировка «существующее оборудование» не используется.

- Для install-сценариев используется формулировка «Установить и подключить <оборудование>».
- Формулировка «Установить новый <оборудование>» не используется.
- В вопросе наличия оборудования используется формулировка «<Оборудование> находится на объекте?».
- Формулировка «Новый <оборудование> находится на объекте?» не используется.
- Для stop-message используется формулировка «наличие приобретённого оборудования на объекте».
- Формулировка «наличие нового оборудования на объекте» не используется.
- В обязательных фотографиях используется формулировка «Фото оборудования в упаковке».
- Формулировка «Фото нового оборудования в упаковке» используется только в сценарии замены, если нужно явно отделить приобретаемое оборудование от установленного оборудования.
- Для фото упаковки используется формулировка «Фото упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией».
- Формулировка «Фото упаковки нового оборудования...» не используется.
- В шаблонных правилах клиента, мастера, фотографий и проверок используется термин «оборудование», если конкретизация сущности не нужна.
- Для replacement-сценариев используется формулировка «Проверка оборудования до демонтажа установленного».
- Формулировка «Проверка нового оборудования до демонтажа установленного» не используется.

Применение:
- Стиральная машина следует этому стандарту.
- Посудомоечная машина следует этому стандарту.
- Измельчитель пищевых отходов следует этому стандарту.
- Kitchen Built-in Appliances использует отдельный Built-in Appliance Architecture Standard.
- Будущие обычные бытовые приборы внутри Appliance Installation & Connection должны проектироваться по Appliance Mini-TZ Standard, если не утверждено отдельное исключение.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Appliance → Стиральная машина

Status: APPROVED / STORED ✅
Standard Compliance: Appliance Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку, подключение и замену стиральной машины внутри Appliance Installation & Connection.
- В MVP поддерживается установка только новой стиральной машины.
- Установка включает размещение, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Если техника встроенная, клиент переводится в Kitchen Built-in Appliances.

Если выбрано «Установить и подключить»:

1. Техника встроенная?
- Да.
- Нет.

Если клиент выбирает «Да», система показывает сообщение:

Для встроенной техники используется отдельный сценарий заказа.

[Продолжить]

и переводит клиента в Kitchen Built-in Appliances.

Если клиент выбирает «Нет»:
- Дополнительных вопросов нет.

Если выбрано «Заменить»:

1. Техника встроенная?
- Да.
- Нет.

Если клиент выбирает «Да», система показывает сообщение:

Для встроенной техники используется отдельный сценарий заказа.

[Продолжить]

и переводит клиента в Kitchen Built-in Appliances.

Если клиент выбирает «Нет»:
- Дополнительных вопросов нет.

Правила вопросов:
- Тип стиральной машины не спрашивается.
- Максимальная загрузка не спрашивается.
- Скорость отжима не спрашивается.
- Энергетический класс не спрашивается.
- Мощность оборудования не спрашивается.
- Тип подключения не спрашивается.
- Наличие вилки не спрашивается.
- Наличие заземления не спрашивается.
- Наличие AquaStop не спрашивается.
- Наличие функции сушки не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки.
- 1 обязательная фотография.

4. Фотография зоны подключения стиральной машины.
- До 3 фотографий:
  - 1 обязательная;
  - до 2 дополнительных.

Правило фотографии зоны подключения:
- Фотографии должны позволять оценить подключение воды, водоотведение и наличие точки электропитания.

Лимит фотографий — Установить и подключить:
- Обязательные: 5 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 9 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной стиральной машины.
- 1 обязательная фотография.

4. Фотография зоны подключения стиральной машины.
- До 3 фотографий:
  - 1 обязательная;
  - до 2 дополнительных.

Правило фотографии зоны подключения:
- Фотографии должны позволять оценить подключение воды, водоотведение и наличие точки электропитания.

Лимит фотографий — Заменить:
- Обязательные: 5 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 9 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Замена кухонной мойки может потребовать демонтажа связанного с ней оборудования.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Уберите содержимое до приезда мастера.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

2. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан снять транспортировочные болты и удалить транспортировочные фиксаторы барабана, предусмотренные производителем.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

3. Проверка подключений:
- Подключение водоснабжения и водоотведения выполняется в соответствии с требованиями производителя.
- Если оборудование оснащено системой AquaStop либо иным защитным устройством, требующим определённого положения при подключении, мастер обязан выполнить подключение в соответствии с требованиями производителя.
- Подключение защитных систем с нарушением требований производителя считается нарушением правил установки.

4. Проверка работоспособности:
- После подключения мастер обязан выполнить тестовый запуск оборудования без загрузки на минимальной программе.
- Мастер обязан убедиться в корректной работе заливной и дренажной системы.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:


1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер отключает оборудование от коммуникаций и выполняет демонтаж техники в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан снять транспортировочные болты и удалить транспортировочные фиксаторы барабана, предусмотренные производителем.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка подключений:
- Подключение водоснабжения и водоотведения выполняется в соответствии с требованиями производителя.
- Если оборудование оснащено системой AquaStop либо иным защитным устройством, требующим определённого положения при подключении, мастер обязан выполнить подключение в соответствии с требованиями производителя.
- Подключение защитных систем с нарушением требований производителя считается нарушением правил установки.

6. Проверка работоспособности:
- После подключения мастер обязан выполнить тестовый запуск оборудования без загрузки на минимальной программе.
- Мастер обязан убедиться в корректной работе заливной и дренажной системы.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Appliance → Посудомоечная машина

Status: APPROVED / STORED ✅
Standard Compliance: Appliance Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку, подключение и замену посудомоечной машины внутри Appliance Installation & Connection.
- В MVP поддерживается только новая техника.
- Установка включает размещение, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Если техника встроенная, клиент переводится в Kitchen Built-in Appliances.

Если выбрано «Установить и подключить»:

1. Техника встроенная?
- Да.
- Нет.

Если клиент выбирает «Да», система показывает сообщение:

Для встроенной техники используется отдельный сценарий заказа.

[Продолжить]

и переводит клиента в Kitchen Built-in Appliances.

Если клиент выбирает «Нет»:
- Дополнительных вопросов нет.

Если выбрано «Заменить»:

1. Техника встроенная?
- Да.
- Нет.

Если клиент выбирает «Да», система показывает сообщение:

Для встроенной техники используется отдельный сценарий заказа.

[Продолжить]

и переводит клиента в Kitchen Built-in Appliances.

Если клиент выбирает «Нет»:
- Дополнительных вопросов нет.

Правила вопросов:
- Тип посудомоечной машины не спрашивается.
- Вместимость посудомоечной машины не спрашивается.
- Энергетический класс не спрашивается.
- Мощность оборудования не спрашивается.
- Тип подключения не спрашивается.
- Наличие вилки не спрашивается.
- Наличие заземления не спрашивается.
- Наличие AquaStop не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки.
- 1 обязательная фотография.

4. Фотография зоны подключения посудомоечной машины.
- До 3 фотографий:
  - 1 обязательная;
  - до 2 дополнительных.

Правило фотографии зоны подключения:
- Фотографии должны позволять оценить подключение воды, водоотведение и наличие точки электропитания.

Лимит фотографий — Установить и подключить:
- Обязательные: 5 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 9 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной посудомоечной машины.
- 1 обязательная фотография.

4. Фотография зоны подключения посудомоечной машины.
- До 3 фотографий:
  - 1 обязательная;
  - до 2 дополнительных.

Правило фотографии зоны подключения:
- Фотографии должны позволять оценить подключение воды, водоотведение и наличие точки электропитания.

Лимит фотографий — Заменить:
- Обязательные: 5 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 9 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Уберите содержимое до приезда мастера.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

2. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

3. Проверка подключений:
- Подключение водоснабжения и водоотведения выполняется в соответствии с требованиями производителя.
- Если оборудование оснащено системой AquaStop либо иным защитным устройством, требующим определённого положения при подключении, мастер обязан выполнить подключение в соответствии с требованиями производителя.
- Подключение защитных систем с нарушением требований производителя считается нарушением правил установки.

4. Проверка работоспособности:
- После подключения мастер обязан выполнить тестовый запуск оборудования без загрузки на минимальной программе.
- Мастер обязан убедиться в корректной работе заливной и дренажной системы.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:


1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер отключает оборудование от коммуникаций и выполняет демонтаж техники в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка подключений:
- Подключение водоснабжения и водоотведения выполняется в соответствии с требованиями производителя.
- Если оборудование оснащено системой AquaStop либо иным защитным устройством, требующим определённого положения при подключении, мастер обязан выполнить подключение в соответствии с требованиями производителя.
- Подключение защитных систем с нарушением требований производителя считается нарушением правил установки.

6. Проверка работоспособности:
- После подключения мастер обязан выполнить тестовый запуск оборудования без загрузки на минимальной программе.
- Мастер обязан убедиться в корректной работе заливной и дренажной системы.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Appliance → Измельчитель пищевых отходов

Status: APPROVED / STORED ✅
Standard Compliance: Appliance Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку, подключение и замену измельчителя пищевых отходов внутри Appliance Installation & Connection.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Бизнес-логика сценария сохраняется без изменений и приведена к современному mini-ТЗ шаблону.

Вопросы:

1. Что требуется сделать?
- Установить и подключить.
- Заменить.

Если выбрано «Установить и подключить»:

2. Кухонная мойка установлена?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для установки и подключения измельчителя пищевых отходов требуется установленная кухонная мойка.

[Понятно]

Если выбрано «Заменить»:

2. Измельчитель пищевых отходов установлен?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для замены требуется наличие установленного измельчителя пищевых отходов.
- Будет использован сценарий установки новой техники.

[Продолжить]

и переводит клиента в сценарий «Установить и подключить».

Правила вопросов:
- Тип измельчителя пищевых отходов не спрашивается.
- Мощность измельчителя пищевых отходов не спрашивается.
- Тип подключения не спрашивается.
- Наличие пневмокнопки не спрашивается.
- Наличие вилки или провода не спрашивается.
- Наличие заземления не спрашивается.
- Тип электрической точки не спрашивается.
- Тип сифона не спрашивается.
- Диаметр сливного отверстия мойки не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография кухонной мойки сверху.
- 1 обязательная фотография.

4. Фотография пространства под кухонной мойкой и системой водоотведения.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

5. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить:
- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография пространства под кухонной мойкой с измельчителем пищевых отходов и системой водоотведения.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны разбирать систему водоотведения или элементы мойки.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе выполнить кратковременную проверку реакции оборудования на включение и выключение, подключив предусмотренный производителем элемент управления.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Мастер не должен использовать гофрированные элементы водоотведения.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер обязан проверить надёжность крепления к мойке.
- Мастер обязан убедиться, что элементы подключения не создают препятствий для нормальной эксплуатации пространства под мойкой.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан выполнить первый запуск оборудования с включённым потоком воды.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан проверить отсутствие протечек в системе водоотведения.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе выполнить кратковременную проверку реакции оборудования на включение и выключение, подключив предусмотренный производителем элемент управления.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Мастер не должен использовать гофрированные элементы водоотведения.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер обязан проверить надёжность крепления к мойке.
- Мастер обязан убедиться, что элементы подключения не создают препятствий для нормальной эксплуатации пространства под мойкой.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан выполнить первый запуск оборудования с включённым потоком воды.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан проверить отсутствие протечек в системе водоотведения.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

## Built-in Appliance Architecture Standard

Status: APPROVED / STORED ✅

Назначение:
- Этот стандарт применяется к встроенной бытовой технике внутри Kitchen Built-in Appliances.
- Стандарт фиксирует единый порядок проектирования сценариев «Установить и подключить» и «Заменить».
- Стандарт используется для снижения дублей, устранения расхождений между сценариями и формирования единых правил Guided Job Flow.
- Kitchen Built-in Appliances работает как mini-scope / add-more ветка: клиент выбирает оборудование из списка и добавляет нужные элементы в один кухонный заказ.
- Отдельные mini-scope сущности внутри Kitchen Built-in Appliances могут дублировать бизнес-логику из Appliance или Plumbing, если это снижает когнитивную нагрузку клиента и позволяет не переводить клиента в другие ветки заказа.

Базовое правило сценариев:
- Сценарий «Установить и подключить» является базовым сценарием.
- Сценарий «Заменить» состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- После завершения демонтажа установленного оборудования сценарий «Заменить» использует правила сценария «Установить и подключить», если иное не указано явно.

Entry Flow Rule:
- Внутри Kitchen Built-in Appliances клиент сначала выбирает конкретное оборудование из списка.
- Затем система показывает общий вопрос mini-scope:
  Что требуется сделать?
  - Установить и подключить.
  - Заменить.
- Этот вопрос относится к экрану mini-scope ветки и не обязан дублироваться внутри каждой дочерней mini-scope сущности, если сценарий уже следует Kitchen Built-in Appliances mini-scope architecture.

Применение:

### Kitchen Built-in Appliances → Кухонная мойка

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку и замену кухонной мойки внутри Kitchen Built-in Appliances.
- Пользовательское название должно быть «Кухонная мойка», чтобы не смешивать её с раковинами ванной комнаты и улучшить локализацию RU/EN/TH.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена включает демонтаж, монтаж, подключение и базовую проверку результата.
- Отдельное подключение кухонной мойки не является MVP-сценарием.

Если выбрано «Установить и подключить»:

Дополнительных вопросов нет.

Если выбрано «Заменить»:

Дополнительных вопросов нет.

Правила вопросов:
- Тип кухонной мойки не спрашивается.
- Тип монтажа не спрашивается.
- Количество чаш не спрашивается.
- Тип сифона / выпуска не спрашивается.
- Требуется ли изменение существующего отверстия — не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография кухонной мойки в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки сверху.
- 1 обязательная фотография.

4. Фотография места установки спереди с открытыми дверцами, позволяющая оценить толщину столешницы, ширину шкафа, точки подключения воды и водоотвода.
- 1 обязательная фотография.

Лимит фотографий — Установить и подключить:
- Обязательные: 5 фотографий.
- Дополнительные: до 2 фотографий.
- Всего: до 7 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография новой кухонной мойки в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной кухонной мойки сверху.
- 1 обязательная фотография.

4. Фотография места установки спереди с открытыми дверцами, позволяющая оценить толщину столешницы, ширину шкафа, точки подключения воды и водоотвода.
- 1 обязательная фотография.

Лимит фотографий — Заменить:
- Обязательные: 5 фотографий.
- Дополнительные: до 2 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Установка или замена оборудования может потребовать изготовления или изменения отверстия в столешнице.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны изготавливать отверстие в столешнице.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Установка или замена оборудования может потребовать изготовления или изменения отверстия в столешнице.
- Замена оборудования может потребовать демонтажа связанного с ним оборудования.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны изменять отверстие в столешнице.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Оценка дополнительного объёма работ:
- Изготовление отверстия в столешнице допускается при согласовании в чате приложения.

2. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

3. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования и столешницы на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан проверить отсутствие протечек в системе водоотведения.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Оценка дополнительного объёма работ:
- Мастер обязан согласовать дополнительный объём работ через чат приложения до утверждения финальной цены, если для замены оборудования требуется демонтаж связанного с ним оборудования.
- Изменение отверстия в столешнице допускается при согласовании в чате приложения.

2. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

3. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования и столешницы на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

4. Демонтаж оборудования:
- Мастер отключает оборудование от коммуникаций и выполняет демонтаж техники в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

5. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

6. Проверка работоспособности:
- Мастер обязан проверить отсутствие протечек в системе водоотведения.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule, если в заказ включено электрическое оборудование.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.


### Kitchen Built-in Appliances → Кухонный кран

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену кухонного крана внутри Kitchen Built-in Appliances.
- Вопрос «Что требуется сделать?» находится на уровне Kitchen Built-in Appliances mini-scope экрана и не дублируется внутри этой mini-scope сущности.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».

Если выбрано «Установить и подключить»:

Дополнительных вопросов нет.

Если выбрано «Заменить»:

Дополнительных вопросов нет.

Правила вопросов:
- Тип кухонного крана не спрашивается.
- Тип монтажа не спрашивается.
- Тип подключения не спрашивается.
- Длина подводки не спрашивается.
- Наличие переходников, прокладок и расходников не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография в упаковке кухонного крана.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной кухонной мойки сверху.
- 1 обязательная фотография.

4. Фотография пространства под кухонной мойкой с точками подключения водоснабжения и отвода сточных вод.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография в упаковке нового кухонного крана.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленного кухонного крана.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.


### Kitchen Built-in Appliances → Проточный водонагреватель

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену проточного водонагревателя внутри Kitchen Built-in Appliances.
- Вопрос «Что требуется сделать?» находится на уровне Kitchen Built-in Appliances mini-scope экрана и не дублируется внутри этой mini-scope сущности.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».

Если выбрано «Установить и подключить»:

Дополнительных вопросов нет.

Если выбрано «Заменить»:

Дополнительных вопросов нет.

Правила вопросов:
- Тип проточного водонагревателя не спрашивается.
- Мощность проточного водонагревателя не спрашивается.
- Тип электрического подключения не спрашивается.
- Наличие заземления не спрашивается.
- Тип автомата защиты не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.
- Электрическая готовность регулируется Global Electrical Readiness Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография проточного водонагревателя в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки проточного водонагревателя.
- 1 обязательная фотография.

4. Фотография точки подключения воды.
- 1 обязательная фотография.

5. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить:
- Обязательные: 6 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 9 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового проточного водонагревателя в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленного проточного водонагревателя.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер обязан проверить отсутствие протечек.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер обязан проверить отсутствие протечек.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.


### Kitchen Built-in Appliances → Измельчитель пищевых отходов

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену измельчителя пищевых отходов внутри Kitchen Built-in Appliances.
- Измельчитель пищевых отходов является отдельной mini-scope сущностью в списке кухонной техники.
- Вопрос «Что требуется сделать?» находится на уровне Kitchen Built-in Appliances mini-scope экрана и не дублируется внутри этой mini-scope сущности.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».

Если выбрано «Установить и подключить»:

Дополнительных вопросов нет.

Если выбрано «Заменить»:

Дополнительных вопросов нет.

Правила вопросов:
- Тип измельчителя пищевых отходов не спрашивается.
- Мощность измельчителя пищевых отходов не спрашивается.
- Тип подключения не спрашивается.
- Наличие пневмокнопки не спрашивается.
- Наличие вилки или провода не спрашивается.
- Наличие заземления не спрашивается.
- Тип электрической точки не спрашивается.
- Тип сифона не спрашивается.
- Диаметр сливного отверстия мойки не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография кухонной мойки сверху.
- 1 обязательная фотография.

4. Фотография пространства под кухонной мойкой и системой водоотведения.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

5. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить:
- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография пространства под кухонной мойкой с измельчителем пищевых отходов и системой водоотведения.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны разбирать систему водоотведения или элементы мойки.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе выполнить кратковременную проверку реакции оборудования на включение и выключение, подключив предусмотренный производителем элемент управления.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Мастер не должен использовать гофрированные элементы водоотведения.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер обязан проверить надёжность крепления к мойке.
- Мастер обязан убедиться, что элементы подключения не создают препятствий для нормальной эксплуатации пространства под мойкой.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан выполнить первый запуск оборудования с включённым потоком воды.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан проверить отсутствие протечек в системе водоотведения.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе выполнить кратковременную проверку реакции оборудования на включение и выключение, подключив предусмотренный производителем элемент управления.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Мастер не должен использовать гофрированные элементы водоотведения.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер обязан проверить надёжность крепления к мойке.
- Мастер обязан убедиться, что элементы подключения не создают препятствий для нормальной эксплуатации пространства под мойкой.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан выполнить первый запуск оборудования с включённым потоком воды.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан проверить отсутствие протечек в системе водоотведения.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Kitchen Built-in Appliances → Варочная панель

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену варочной панели внутри Kitchen Built-in Appliances.
- В MVP поддерживаются только электрические и индукционные варочные панели.
- Газовые варочные панели, подключение газа и работы с LPG-баллонами исключены из MVP и не поддерживаются архитектурой запуска Helpy.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Сценарий следует Built-in Appliance Architecture Standard.

Если выбрано «Установить и подключить»:

Дополнительных вопросов нет.

Если выбрано «Заменить»:

Дополнительных вопросов нет.

Правила вопросов:
- Тип варочной панели не спрашивается.
- Мощность варочной панели не спрашивается.
- Количество конфорок не спрашивается.
- Тип подключения не спрашивается.
- Наличие заземления не спрашивается.
- Тип электрической точки не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки сверху.
- 1 обязательная фотография.

4. Фотография места установки спереди с открытыми дверцами, позволяющая оценить толщину столешницы и ширину шкафа.
- 1 обязательная фотография.

5. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить:
- Обязательные: 6 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 9 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной варочной панели.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Установка или замена оборудования может потребовать изготовления или изменения отверстия в столешнице.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны изготавливать отверстие в столешнице.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Установка или замена оборудования может потребовать изготовления или изменения отверстия в столешнице.
- Замена оборудования может потребовать демонтажа связанного с ним оборудования.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны изменять отверстие в столешнице.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Оценка дополнительного объёма работ:
- Изготовление отверстия в столешнице допускается при согласовании в чате приложения.

2. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

3. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования и столешницы на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Оценка дополнительного объёма работ:
- Мастер обязан согласовать дополнительный объём работ через чат приложения до утверждения финальной цены, если для замены оборудования требуется демонтаж связанного с ним оборудования.
- Изменение отверстия в столешнице допускается при согласовании в чате приложения.

2. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

3. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования и столешницы на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

4. Демонтаж оборудования:
- Мастер отключает оборудование от электропитания и выполняет демонтаж техники в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

5. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

6. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.


### Kitchen Built-in Appliances → Духовой шкаф

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену встроенного духового шкафа внутри Kitchen Built-in Appliances.
- В MVP поддерживаются только электрические духовые шкафы.
- Газовые духовые шкафы, подключение газа и работы с LPG-баллонами исключены из MVP и не поддерживаются архитектурой запуска Helpy.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Сценарий следует Built-in Appliance Architecture Standard.

Если выбрано «Установить и подключить»:

2. Размер ниши для установки (Ш × В × Г).
- Обязательное поле.

Если выбрано «Заменить»:

Дополнительных вопросов нет.

Правила вопросов:
- Тип духового шкафа не спрашивается.
- Мощность духового шкафа не спрашивается.
- Тип подключения не спрашивается.
- Наличие вилки или провода не спрашивается.
- Наличие заземления не спрашивается.
- Тип электрической точки не спрашивается.
- Размер ниши является характеристикой места установки, а не технической характеристикой оборудования.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки спереди.
- 1 обязательная фотография.

4. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленного духового шкафа.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Замена духового шкафа может потребовать демонтажа связанного с ним оборудования.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Подготовьте доступ к установленному оборудованию.
- Уберите содержимое до приезда мастера.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Оценка дополнительного объёма работ:
- Мастер обязан согласовать дополнительный объём работ через чат приложения до утверждения финальной цены, если для замены оборудования требуется демонтаж связанного с ним оборудования.

2. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

3. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

4. Демонтаж оборудования:
- Мастер отключает оборудование от электропитания и выполняет демонтаж техники в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

5. Установка и подключение:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

6. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Kitchen Built-in Appliances → Встроенная микроволновая печь

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену встроенной микроволновой печи внутри Kitchen Built-in Appliances.
- В MVP поддерживаются встроенные электрические микроволновые печи.
- Функции гриля, конвекции и комбинированные режимы не создают отдельные ветки.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Сценарий следует Built-in Appliance Architecture Standard.

Если выбрано «Установить и подключить»:

1. Размер ниши для установки (Ш × В × Г).
- Обязательное поле.

Если выбрано «Заменить»:

Дополнительных вопросов нет.

Правила вопросов:
- Тип микроволновой печи не спрашивается.
- Мощность микроволновой печи не спрашивается.
- Наличие гриля не спрашивается.
- Наличие конвекции не спрашивается.
- Тип подключения не спрашивается.
- Наличие вилки или провода не спрашивается.
- Наличие заземления не спрашивается.
- Тип электрической точки не спрашивается.
- Размер ниши является характеристикой места установки, а не технической характеристикой оборудования.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки спереди.
- 1 обязательная фотография.

4. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной микроволновой печи.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Подготовьте доступ к установленному оборудованию.
- Уберите содержимое до приезда мастера.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.


### Kitchen Built-in Appliances → Кухонная вытяжка

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену кухонной вытяжки внутри Kitchen Built-in Appliances.
- В MVP поддерживаются электрические кухонные вытяжки.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Сценарий следует Built-in Appliance Architecture Standard.

Если выбрано «Установить и подключить»:

1. Режим работы?
- Подключение к вентиляции.
- Без подключения к вентиляции (через фильтры — обычно не входят в комплект).

Если выбрано «Заменить»:

1. Режим работы новой кухонной вытяжки?
- Подключение к вентиляции.
- Без подключения к вентиляции (через фильтры — обычно не входят в комплект).

Системная подсказка для режима без подключения к вентиляции:
- Некоторые модели вытяжек требуют установки угольных фильтров для работы без подключения к вентиляции.
- Фильтры могут не входить в комплект поставки оборудования.

Правила вопросов:
- Тип кухонной вытяжки не спрашивается.
- Мощность кухонной вытяжки не спрашивается.
- Производительность кухонной вытяжки не спрашивается.
- Тип подключения не спрашивается.
- Наличие вилки или провода не спрашивается.
- Наличие заземления не спрашивается.
- Тип электрической точки не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить — Подключение к вентиляции:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки спереди.
- 1 обязательная фотография.

4. Фотография отверстия вентиляции воздуха.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

5. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить — Подключение к вентиляции:
- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

Обязательные фотографии — Установить и подключить — Без подключения к вентиляции:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки спереди.
- 1 обязательная фотография.

4. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить — Без подключения к вентиляции:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной кухонной вытяжки.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Если выбран режим подключения к вентиляции, мастер выполняет подключение воздуховода длиной не более 2,5 метров при наличии вентиляционного отверстия, в пределах стоимости услуги.
- Если выбран режим работы без подключения к вентиляции, установка угольных фильтров выполняется только при их наличии и если такая установка предусмотрена производителем.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер отключает оборудование от электропитания и выполняет демонтаж техники в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Если выбран режим подключения к вентиляции, мастер выполняет подключение воздуховода длиной не более 2,5 метров при наличии вентиляционного отверстия, в пределах стоимости услуги.
- Если выбран режим работы без подключения к вентиляции, установка угольных фильтров выполняется только при их наличии и если такая установка предусмотрена производителем.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Global Surface Protection Rule.
- Chat Evidence Rules.

### Kitchen Built-in Appliances → Встроенный холодильник

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену встроенного холодильника внутри Kitchen Built-in Appliances.
- В MVP поддерживаются только встроенные электрические холодильники.
- Сценарий следует Built-in Appliance Architecture Standard.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».

Если выбрано «Установить и подключить»:

2. Размер ниши для установки (Ш × В × Г).
- Обязательное поле.

Если выбрано «Заменить»:

2. Планируется замена мебельных фасадов?
- Да.
- Нет.

Правила вопросов:
- Тип встроенного холодильника не спрашивается.
- Объём холодильника не спрашивается.
- Объём морозильной камеры не спрашивается.
- Энергетический класс не спрашивается.
- Мощность оборудования не спрашивается.
- Тип подключения не спрашивается.
- Наличие вилки не спрашивается.
- Наличие заземления не спрашивается.
- Сторона открывания дверей не спрашивается.
- Тип крепления мебельных фасадов не спрашивается.
- Наличие доводчиков не спрашивается.
- Тип системы крепления мебельных фасадов не спрашивается.
- Наличие системы No Frost не спрашивается.
- Наличие льдогенератора не спрашивается.
- Наличие диспенсера воды не спрашивается.
- Размер ниши является характеристикой места установки, а не технической характеристикой оборудования.
- При замене установленный встроенный холодильник оценивается по фотографиям.
- При замене существующие мебельные фасады оцениваются по фотографиям.
- Если планируется замена мебельных фасадов, информация о новых мебельных фасадах оценивается по фотографиям.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотографии с размерами устанавливаемых мебельных фасадов.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

4. Фотография места установки спереди.
- 1 обязательная фотография.

5. Фотография точки подключения электропитания.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Установить и подключить:
- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленного холодильника с открытыми дверцами.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Если выбрано «Да» в вопросе «Планируется замена мебельных фасадов?»:

4. Фотографии с размерами устанавливаемых мебельных фасадов.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

Лимит фотографий — Заменить без замены мебельных фасадов:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Лимит фотографий — Заменить с заменой мебельных фасадов:
- Обязательные: 5 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 9 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Подготовьте доступ к установленному оборудованию.
- Уберите содержимое до приезда мастера.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер устанавливает мебельный фасад на оборудование, выполняет регулировку по зазорам и плоскости в процессе установки.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан проверить надёжность крепления мебельного фасада.
- Мастер обязан убедиться в свободном открывании и закрывании мебельного фасада, проверить зазоры с соседними фасадами и соответствие их плоскостей.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер устанавливает мебельный фасад на оборудование, выполняет регулировку по зазорам и плоскости в процессе установки.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды после подключения оборудования.
- Мастер обязан проверить надёжность крепления мебельного фасада.
- Мастер обязан убедиться в свободном открывании и закрывании мебельного фасада, проверить зазоры с соседними фасадами и соответствие их плоскостей.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.


### Kitchen Built-in Appliances → Встроенная посудомоечная машина

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену встроенной посудомоечной машины внутри Kitchen Built-in Appliances.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Сценарий следует Built-in Appliance Architecture Standard.

Если выбрано «Установить и подключить»:

2. Размер ниши для установки (Ш × В × Г).
- Обязательное поле.

Если выбрано «Заменить»:

2. Планируется замена мебельного фасада?
- Да.
- Нет.

Правила вопросов:
- Тип встроенной посудомоечной машины не спрашивается.
- Вместимость посудомоечной машины не спрашивается.
- Энергетический класс не спрашивается.
- Мощность оборудования не спрашивается.
- Тип подключения не спрашивается.
- Наличие вилки не спрашивается.
- Наличие заземления не спрашивается.
- Тип системы крепления мебельного фасада не спрашивается.
- Наличие AquaStop не спрашивается.
- Размер ниши является характеристикой места установки, а не технической характеристикой оборудования.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография с размерами устанавливаемого мебельного фасада.
- 1 обязательная фотография.

4. Фотография места установки спереди.
- 1 обязательная фотография.

5. Фотография зоны подключения посудомоечной машины.
- До 3 фотографий:
  - 1 обязательная;
  - до 2 дополнительных.

Правило фотографии зоны подключения:
- Фотографии должны позволять оценить подключение воды, водоотведение и наличие точки электропитания.

Лимит фотографий — Установить и подключить:
- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной посудомоечной машины с открытой дверцей.
- 1 обязательная фотография.

Если выбрано «Да» в вопросе «Планируется замена мебельного фасада?»:

4. Фотография с размерами устанавливаемого мебельного фасада.
- 1 обязательная фотография.

Лимит фотографий — Заменить без замены мебельного фасада:
- Обязательные: 4 фотографии.
- Дополнительные: до 2 фотографий.
- Всего: до 6 из 10 фотографий.

Лимит фотографий — Заменить с заменой мебельного фасада:
- Обязательные: 5 фотографий.
- Дополнительные: до 2 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Уберите содержимое до приезда мастера.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.
Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер устанавливает мебельный фасад на оборудование, выполняет регулировку по зазорам и плоскости в процессе установки.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка подключений:
- Подключение водоснабжения и водоотведения выполняется в соответствии с требованиями производителя.
- Если оборудование оснащено системой AquaStop либо иным защитным устройством, требующим определённого положения при подключении, мастер обязан выполнить подключение в соответствии с требованиями производителя.
- Подключение защитных систем с нарушением требований производителя считается нарушением правил установки.

5. Проверка работоспособности:
- После подключения мастер обязан выполнить тестовый запуск оборудования без загрузки на минимальной программе.
- Мастер обязан убедиться в корректной работе заливной и дренажной системы.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан проверить надёжность крепления мебельного фасада.
- Мастер обязан убедиться в свободном открывании и закрывании мебельного фасада, проверить зазоры с соседними фасадами и соответствие их плоскостей.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер отключает оборудование от коммуникаций и выполняет демонтаж техники в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер устанавливает мебельный фасад на оборудование, выполняет регулировку по зазорам и плоскости в процессе установки.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка подключений:
- Подключение водоснабжения и водоотведения выполняется в соответствии с требованиями производителя.
- Если оборудование оснащено системой AquaStop либо иным защитным устройством, требующим определённого положения при подключении, мастер обязан выполнить подключение в соответствии с требованиями производителя.
- Подключение защитных систем с нарушением требований производителя считается нарушением правил установки.

6. Проверка работоспособности:
- После подключения мастер обязан выполнить тестовый запуск оборудования без загрузки на минимальной программе.
- Мастер обязан убедиться в корректной работе заливной и дренажной системы.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан проверить надёжность крепления мебельного фасада.
- Мастер обязан убедиться в свободном открывании и закрывании мебельного фасада, проверить зазоры с соседними фасадами и соответствие их плоскостей.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.


### Kitchen Built-in Appliances → Встроенная стиральная машина

Status: APPROVED / STORED ✅
Standard Compliance: Built-in Appliance Architecture Standard ✅

Назначение:
- Эта mini-scope сущность описывает установку, подключение и замену встроенной стиральной машины внутри Kitchen Built-in Appliances.
- Установка включает монтаж, подключение и базовую проверку результата.
- Замена состоит из демонтажа установленного оборудования и последующего выполнения сценария «Установить и подключить».
- Сценарий следует Built-in Appliance Architecture Standard.

Если выбрано «Установить и подключить»:

2. Размер ниши для установки (Ш × В × Г).
- Обязательное поле.

Если выбрано «Заменить»:

2. Планируется замена мебельного фасада?
- Да.
- Нет.

Правила вопросов:
- Тип встроенной стиральной машины не спрашивается.
- Максимальная загрузка не спрашивается.
- Скорость отжима не спрашивается.
- Энергетический класс не спрашивается.
- Мощность оборудования не спрашивается.
- Тип подключения не спрашивается.
- Наличие вилки не спрашивается.
- Наличие заземления не спрашивается.
- Тип системы крепления мебельного фасада не спрашивается.
- Наличие AquaStop не спрашивается.
- Наличие функции сушки не спрашивается.
- Размер ниши является характеристикой места установки, а не технической характеристикой оборудования.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография с размерами устанавливаемого мебельного фасада.
- 1 обязательная фотография.

4. Фотография места установки спереди.
- 1 обязательная фотография.

5. Фотография зоны подключения стиральной машины.
- До 3 фотографий:
  - 1 обязательная;
  - до 2 дополнительных.

Правило фотографии зоны подключения:
- Фотографии должны позволять оценить подключение воды, водоотведение и наличие точки электропитания.

Лимит фотографий — Установить и подключить:
- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

Обязательные фотографии — Заменить:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленной стиральной машины с открытой дверцей.
- 1 обязательная фотография.

Если выбрано «Да» в вопросе «Планируется замена мебельного фасада?»:

4. Фотография с размерами устанавливаемого мебельного фасада.
- 1 обязательная фотография.

Лимит фотографий — Заменить без замены мебельного фасада:
- Обязательные: 4 фотографии.
- Дополнительные: до 2 фотографий.
- Всего: до 6 из 10 фотографий.

Лимит фотографий — Заменить с заменой мебельного фасада:
- Обязательные: 5 фотографий.
- Дополнительные: до 2 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Уберите содержимое до приезда мастера.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан снять транспортировочные болты и удалить транспортировочные фиксаторы барабана, предусмотренные производителем.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер устанавливает мебельный фасад на оборудование, выполняет регулировку по зазорам и плоскости в процессе установки.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка подключений:
- Подключение водоснабжения и водоотведения выполняется в соответствии с требованиями производителя.
- Если оборудование оснащено системой AquaStop либо иным защитным устройством, требующим определённого положения при подключении, мастер обязан выполнить подключение в соответствии с требованиями производителя.
- Подключение защитных систем с нарушением требований производителя считается нарушением правил установки.

5. Проверка работоспособности:
- После подключения мастер обязан выполнить тестовый запуск оборудования без загрузки на минимальной программе.
- Мастер обязан убедиться в корректной работе заливной и дренажной системы.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан проверить надёжность крепления мебельного фасада.
- Мастер обязан убедиться в свободном открывании и закрывании мебельного фасада, проверить зазоры с соседними фасадами и соответствие их плоскостей.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер отключает оборудование от коммуникаций и выполняет демонтаж техники в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан снять транспортировочные болты и удалить транспортировочные фиксаторы барабана, предусмотренные производителем.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер устанавливает мебельный фасад на оборудование, выполняет регулировку по зазорам и плоскости в процессе установки.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка подключений:
- Подключение водоснабжения и водоотведения выполняется в соответствии с требованиями производителя.
- Если оборудование оснащено системой AquaStop либо иным защитным устройством, требующим определённого положения при подключении, мастер обязан выполнить подключение в соответствии с требованиями производителя.
- Подключение защитных систем с нарушением требований производителя считается нарушением правил установки.

6. Проверка работоспособности:
- После подключения мастер обязан выполнить тестовый запуск оборудования без загрузки на минимальной программе.
- Мастер обязан убедиться в корректной работе заливной и дренажной системы.
- Мастер обязан убедиться в отсутствии нехарактерных шумов и вибраций.
- Мастер обязан проверить надёжность крепления мебельного фасада.
- Мастер обязан убедиться в свободном открывании и закрывании мебельного фасада, проверить зазоры с соседними фасадами и соответствие их плоскостей.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

## Pre-Build Decision Gate → Client Expected Price Architecture

Status: CLOSED ✅

Decision Summary:
- Источник первой цены заказа закрыт в пользу Client Expected Price Model.
- Клиент указывает ожидаемую стоимость работ при создании заказа.
- Платформа устанавливает только minimum threshold по категории / подкатегории / сценарию.
- Minimum threshold не является рыночной ценой услуги и не является рекомендацией стоимости.
- Минимальный порог стоимости нужен для защиты от опечаток, заведомо нереалистичных заявок и заказов без рыночного интереса.
- Minimum threshold не участвует в расчёте комиссии, депозита или commission obligation.
- Мастер после изучения structured scope, ответов клиента, required photos и Client Expected Price может принять цену или один раз предложить изменение цены.
- Изменение цены должно быть предварительно обсуждено и согласовано с клиентом в чате до выбора мастера.
- После выбора мастера согласованная цена становится Final Agreed Price.
- Депозит, комиссия платформы и commission obligation рассчитываются только от Final Agreed Price.

Build Gate:
- Pricing-related DB structures должны проектироваться от Client Expected Price, minimum threshold, proposed master price и Final Agreed Price.
- Admin pricing settings должны управлять minimum threshold и финансовыми настройками, но не должны навязывать клиенту рекомендованную цену услуги.
- MVP pricing flow должен использовать Client Expected Price Model.

Boundary:
- Existing Final Agreed Price contracts remain valid.
- Existing One-Time Final Price Rule remains valid.
- Existing Commission Rule remains valid.
- Existing Global Materials Separation Rule remains valid.
- Category mini-ТЗ должны исключать legacy Base Price / Platform Entry Price модель, если нет отдельного утверждённого исключения.

Status Effect:
- DOES NOT BLOCK PRICING IMPLEMENTATION.
- REQUIRES DB / MVP / ADMIN PRICING DESIGN TO FOLLOW CLIENT EXPECTED PRICE MODEL.





## Global Surface Protection Rule

Status: STORED ⚠️ ТРЕБУЕТ ПОВТОРНОГО РАССМОТРЕНИЯ ПЕРЕД РЕАЛИЗАЦИЕЙ MVP

Краткое описание:
- При выполнении работ мастер обязан принимать разумные меры по защите имущества клиента от случайного повреждения.
- Правило применяется независимо от категории услуги.
- Наиболее актуально при работах над столешницами, мебелью, бытовой техникой и другими поверхностями в зоне выполнения работ.

Правило:
- Перед началом работ мастер обязан защитить поверхности, которые могут быть повреждены в процессе выполнения работ, если такая защита является разумно необходимой.
- Инструменты и материалы должны размещаться таким образом, чтобы минимизировать риск случайного повреждения имущества клиента.
- При необходимости использования поверхности в качестве временной рабочей опоры мастер обязан предварительно защитить её поверхность.
- Если безопасное выполнение работ невозможно без создания необоснованного риска повреждения имущества клиента, мастер вправе отказаться от продолжения работ до устранения препятствий.

Границы применения:
- Правило не требует использования специальных защитных материалов, отсутствующих у мастера.
- Оценивается соблюдение разумных профессиональных мер предосторожности.

Влияние на статус:
- Должно быть повторно рассмотрено перед реализацией логики выполнения работ в MVP.
- Может наследоваться категориями при необходимости.

## Global Materials Separation Rule
Status: APPROVED / STORED ✅

Decision Summary:
- Стоимость работ и стоимость материалов разделяются.
- Материалы, комплектующие и расходные элементы не входят в стоимость заказа платформы.
- Платформа не участвует в ценообразовании дополнительных материалов.

Rule:
- В стоимость заказа входят только работы, предусмотренные согласованным объёмом услуги.
- Дополнительные материалы, комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.

Boundary:
- Платформа не претендует на процент от стоимости материалов.
- Качество и выбор дополнительных материалов остаются предметом договорённости между клиентом и мастером.


## Global Electrical Readiness Rule
Status: APPROVED / STORED ✅

Decision Summary:
- Наличие розетки не подтверждает наличие электропитания.

Rule:
- До начала работ мастер вправе проверить наличие электропитания в точке подключения.
- Поиск неисправностей существующей электропроводки не входит в объём услуги установки.

Boundary:
- Дальнейшие действия согласовываются отдельно между клиентом и мастером.


## Global Completion Evidence Rule
Status: APPROVED / STORED ✅

Decision Summary:
- Завершение работ и завершение заказа являются разными событиями.

Rule:
- После выполнения работ мастер обязан направить клиенту через чат платформы подтверждение результата и фотографии выполненных работ.
- Заказ считается завершённым только после подтверждения клиента посредством функционала платформы.

Boundary:
- Отсутствие клиента на объекте не препятствует выполнению работ.


## Global Service Quality Rule
Status: APPROVED / STORED ✅

Decision Summary:
- Установка не считается качественно выполненной только по факту физического завершения работ.

Rule:
- Базовая работоспособность результата должна быть подтверждена в рамках согласованного объёма заказа.
- Проверки выполняются безопасным способом и в пределах характера выполненных работ.

Boundary:
- Подтверждение базовой работоспособности не является диагностикой скрытых дефектов и не заменяет гарантийные обязательства производителя.


## Rule Language & Translation Standard

Status: APPROVED / STORED ✅

Стандарт внесения изменений:

- Любые изменения в реестр выполняются только на основании фактов, подтверждённых текущим состоянием документа.
- Перед внесением изменений обязательно снимаются точные координаты редактируемого блока.
- Перед началом правки запрещается опираться на память, предположения или предыдущие версии документа.
- После каждой правки обязательно выполняется проверка внесённых изменений.
- Перед завершением работы обязательно выполняется проверка git diff --check.
- После успешной проверки изменения фиксируются последовательностью: git add → git commit → git push.
- При обнаружении несоответствия работа продолжается только после его устранения и повторной проверки.
- При отсутствии подтверждённых фактов используется ответ «НЕ ЗНАЮ». Восстанавливать информацию по памяти, ассоциациям или предположениям запрещено.
- Любое утверждение о состоянии документа должно быть подтверждено его текущим содержимым.

Формат рабочих ответов:

- Перед каждым блоком обязательно указывается цель текущего шага.
- Перед каждым блоком обязательно указывается его тип:
  - Выполнить в Termux.
  - Вставить в файл.
  - Заменить блок в файле.
  - Ожидаемый результат.
- После каждого блока обязательно указывается ожидаемый результат выполнения.
- Команды, текст для вставки, ожидаемый вывод и пояснения не смешиваются в одном блоке.
- Рабочий ответ содержит только информацию, необходимую для выполнения текущего шага.
- Рассуждения, не влияющие на выполнение текущего шага, не включаются в рабочий ответ.
- Если задачу можно выполнить одной командой или одним скриптом, предпочтение отдаётся этому способу.
- Если требуется запуск в Termux, выдаётся полностью готовый блок команд.
- Если требуется вставка в файл, выдаётся только содержимое, предназначенное для вставки.
- Использование заглушек («...», «TODO», «вставить самостоятельно» и т.п.) в рабочих блоках запрещено.
- Любой блок «Выполнить в Termux» должен быть полностью готов к выполнению без дополнительного редактирования.
- Любой блок «Ожидаемый результат» должен соответствовать реальному ожидаемому выводу команды.

Правила проверки:

- Проверяется именно тот участок документа, который был изменён.
- Проверка считается завершённой только после получения фактического результата.
- При расхождении между ожидаемым и фактическим результатом приоритет всегда имеет фактический результат.
- Запрещается утверждать, что изменение выполнено, пока оно не подтверждено проверкой.
- Если вывод команды противоречит предыдущему ответу, источником истины считается вывод команды.
- При обнаружении ошибки сначала выполняется повторная проверка, затем корректировка, после чего проверка повторяется.
- Любое утверждение о состоянии документа должно подтверждаться текущим содержимым документа или результатом выполненной проверки.
- При аудите источником истины является только последний вывод терминала. Если текущий вывод противоречит предыдущему ответу или вызывает сомнение, запрещено делать вывод. Сначала выполняется повторная проверка, затем формируется заключение. Запрещено дополнять анализ памятью предыдущих ответов.

### Canonical Workflow Development Process

Status: APPROVED / STORED ✅

Назначение:
Определяет единый процесс построения новых правил выполнения работ мастером.

Алгоритм:

1. Определить тип оборудования.
- Определяется класс оборудования и его технические особенности.

2. Использовать Canonical Master Workflow Blocks.
- За основу всегда используются утверждённые канонические блоки.
- Последовательность блоков не изменяется без отдельного утверждения.

3. Добавить техническую специфику оборудования.
- Специфичные правила добавляются внутрь соответствующего канонического блока.
- Канонические формулировки не заменяются, если не требуется изменение общего стандарта.

4. Проверить универсальность новых формулировок.
- Если новая формулировка подходит более чем одной сущности, она рассматривается как кандидат на канонизацию.

5. Обновить Rule Language & Translation Standard.
- После утверждения новая универсальная формулировка переносится в словарь.
- Все последующие сущности используют обновлённую каноническую формулировку.

Результат:
- Единая структура правил выполнения работ мастером.
- Минимизация дублирования.
- Единая терминология.
- Предсказуемое развитие реестра.
- Упрощение сопровождения и аудита.
- Сокращение времени разработки новых сущностей.

### Canonical Entity Naming

В вопросах, сообщениях системы и stop-сценариях необходимо использовать полное название текущей сущности.

Причины:
- Клиент должен сразу понимать, о какой сущности идёт речь.
- Формулировка не должна требовать восстановления контекста.
- Полное название обеспечивает более точный машинный перевод между RU / EN / TH.
- Использование сокращённых или обобщённых наименований сущностей не допускается.

Правила применения утверждённых формулировок:

Подготовьте доступ к месту выполнения работ.
- Используется только для сценария «Установить и подключить».

Подготовьте доступ к установленному оборудованию.
- Используется только для сценариев «Заменить» и «Перенести».

### Canonical Photo Labels

Status: APPROVED / STORED ✅

Назначение:
Определяет единый утверждённый словарь фотоформулировок Helpy. Используется как источник истины для обязательных и дополнительных фотографий в сценариях заказа.

Правила использования:
- Если подходящая фотоформулировка уже утверждена, она используется без изменения.
- Новые фотоформулировки не добавляются без отдельного утверждения.
- Если требуется одна фотография, используется формулировка «Фотография ...».
- Если требуется несколько фотографий, используется формулировка «Фотографии ...».
- Фотоформулировка должна быть проверена через встроенный переводчик Helpy для RU / EN / TH до добавления в этот словарь.

Утверждённые фотоформулировки:

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

### Canonical Client Labels

Status: APPROVED / STORED ✅

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

### Canonical Master Workflow Blocks

Status: APPROVED / STORED ✅

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

#### Compatibility Check Before Work
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

#### Equipment Inspection Before Installation and Connection
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

#### Equipment Removal
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

#### Installation and Connection
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

#### Functional Verification
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
## Registry Language Standard
Status: APPROVED / STORED ✅

Decision Summary:
- Регистр Helpy использует два языка в зависимости от уровня ответственности.
- Настоящий стандарт обязателен для всех последующих изменений регистра.

English:
- code;
- directories;
- database objects;
- table names;
- column names;
- enum values;
- slug values;
- API routes;
- DTO names;
- config keys;
- internal statuses;
- contract names;
- rule names;
- technical identifiers.

Русский:
- UX;
- бизнес-логика;
- правила клиента;
- правила мастера;
- Question Flow;
- Photo Requirements;
- Service Playbook;
- причины принятия решений;
- описания сценариев.

Пример:

Наследуемые правила:
- Packaging Inspection Rules.
- Damage Escalation Rules.
- Chat Evidence Rules.

Registry Editing Safety Rule:
- Cross-category terminology changes are prohibited unless the edit range is explicitly limited to the target category, standard or entity.
- Mass replacements must not be executed across the full registry without domain-context validation.
- A term approved for one service-flow or equipment-flow category must not automatically propagate into other category architectures.
- Before committing terminology changes, the diff must be checked for accidental leakage into unrelated categories.
- If leakage is detected after commit, it must be fixed by a separate corrective commit with clear proof.

Closure Note:
- Все последующие изменения регистра должны соответствовать данному стандарту.

---

## Global Diagnostics Pattern
Status: APPROVED / ROADMAP STORED ✅

Decision Summary:
- Diagnostics is not a root category.
- Diagnostics is not a separate marketplace vertical.
- Diagnostics is a reusable category-level branch pattern.
- The client first selects the problem domain/category.
- Inside the category, the client may choose a diagnostic flow when they do not know the exact work required.
- Diagnostic branches are independently enabled or disabled per category.
- Diagnostic branches remain disabled until explicitly approved for that category.

Diagnostics UI Placement Rule:
- Diagnostics lives only inside Create Job flows.
- Diagnostics does not introduce separate application screens.
- Diagnostics does not create a separate marketplace entry mode.
- Diagnostics is implemented using the existing category → subcategory architecture.
- The dynamic form engine requires no special diagnostics support.

Approved Navigation Pattern:

Create Job
↓
Category
↓
Action Branch / Diagnostic Branch
↓
Question Flow
↓
Photo Flow
↓
Preview
↓
Deposit

Reason:
- Clients usually understand the problem domain.
- Clients often do not understand the exact work required.
- The uncertainty exists inside the category, not above it.

Closure Note:
- Future Global Diagnostics is governed by this pattern.
- Root-level diagnostics and entry-mode diagnostics are rejected architectural approaches.

---

## 10. Electrical Shower Policy
Status: CLOSED

Decision Summary:
- Helpy MVP supports installation and replacement scenarios for electric showers.
- Diagnostic and repair scenarios are intentionally excluded from the Electrical domain.
- Repair scenarios are already covered by Plumbing reference flows where applicable.
- In the Thailand market, replacement is generally more economical than repair.
- Electric shower repair will not return to MVP discussion before launch.
- No unresolved architecture decisions remain in this contract.

Enabled:
- Install New Electric Shower
- Replace Existing Electric Shower

Disabled On Launch:
- Not Heating Water
- Water Leak
- Trips Breaker / Power Loss

Reason:
- Helpy MVP ориентирован на установку и замену оборудования.
- Диагностика и ремонт электрических душей не являются приоритетом запуска.
- Замена устройства обычно проще и дешевле ремонта.
## 11. Deferred Categories
Status: CLOSED

Decision Summary:
- Handyman is excluded from MVP launch.
- Handyman will not return to MVP discussion before launch.
- Home Appliances is no longer a deferred category.
- Home Appliances has been promoted into the MVP roadmap as the final category before launch.
- Deferred categories do not block MVP launch.
- No unresolved architecture decisions remain in this contract.

Deferred Categories:
- Handyman

Promoted Category:
- Appliance Installation & Connection
- Установка и подключение бытовой техники

Reason:
- Specialized categories are completed first.
- Handyman is too broad and low-value for Helpy MVP.
- Profile categories, chat negotiation, and fixed-price flows cover most handyman-like scenarios during MVP.

Rule:
- Deferred categories may be reconsidered only after collecting real marketplace statistics following launch.
## 12. Knowledge Base Engine
Status: PARTIALLY CLOSED

Decision Summary:
- Knowledge Base Engine is required for every category.
- Category knowledge must include Client Guidance, Master Guidance, Platform Notes, Safety Notes, and Premium Recommendations.
- Users must not keep category rules in their heads.
- Guidance must be integrated into client and master screens.
- Guidance visibility depends on user role and order stage.
- Exact guidance trigger matrix and mobile screen placement are defined by downstream guidance contracts.
- This contract cannot be CLOSED until the downstream guidance contracts are reviewed and aligned.

Every category must support:
- Client Guidance
- Master Guidance
- Platform Notes
- Safety Notes
- Premium Recommendations

Purpose:
Users should not keep rules in their heads.
System must display information at the correct stage of the order.
## 13. Dynamic Form Engine
Status: PARTIALLY CLOSED

Decision Summary:
- Create Job Screen must be generated dynamically.
- Admin Panel is the source of form structure.
- API delivers form structure to the Mobile Application.
- Mobile Application renders categories, subcategories, questions, photo requirements, rules, and guidance blocks from data.
- No category-specific hardcoded create-job forms are allowed.
- Pure dynamic form engine is the current target architecture.
- Hybrid shell approach may be reconsidered only after the full roadmap and all MVP categories are completed.
- This contract cannot be CLOSED until the final pure dynamic vs hybrid implementation decision is made.

Create Job Screen must be generated dynamically.

Source:
Admin Panel → API → Mobile Application

Generated Elements:
- Categories
- Subcategories
- Questions
- Photo Requirements
- Rules
- Guidance Blocks

No hardcoded forms.
## 10. Premium Services
Status: APPROVED ✅

Confirmed Premium Services:
- Control Measurement
- Completeness Verification

Purpose:
Reduce installation risks before work begins.

## 15. Furniture Skill Levels
Status: CLOSED

Decision Summary:
- Furniture skill levels are manually assigned by the platform.
- A master may be confirmed by the platform or by a more experienced master.
- Skill level controls access to furniture projects by complexity.
- Unconfirmed masters must not access higher-complexity furniture jobs.
- The goal is to prevent masters from learning on the client site and creating avoidable problems.
- No unresolved architecture decisions remain in this contract.

Levels:
- Basic
- Intermediate
- Advanced

Complexity Access:
- Basic: simple cabinet furniture.
- Intermediate: kitchen furniture projects.
- Advanced: complex built-in furniture projects.

Purpose:
Control access to complex furniture projects.

Architecture Link:
- Furniture Skill Levels are used as furniture-specific master eligibility bindings.
- Furniture Skill Levels feed Master Eligibility Rules.
- Furniture Skill Levels are eligibility gates, not ranking signals.
- Eligible furniture masters may still be ranked by the Master Ranking Hybrid Model.

## 16. Global Platform Rules
Status: PARTIALLY CLOSED — RECOVERED FROM VERIFIED CATEGORY SOURCES

Decision Summary:
- Global Platform Rules Registry exists.
- Seven global platform rules were previously approved.
- The rules apply across client, master, and platform workflows.
- Rule #1–Rule #7 are recovered from verified closed category sources: Furniture Assembly, Plumbing and Locks.
- Electrical was reviewed after Contract 23 closure and confirms Rule #1–Rule #7 without introducing new Global Rules.
- Appliance Installation & Connection may add or duplicate global rules before final closure.
- Electrical no longer blocks Contract 16 because its closed category architecture is covered by existing Global Platform Rules.
- No replacement texts may be invented without documentary evidence.

Platform Rules Registry exists.

Confirmed Rules:

### Rule #1 — Client-Safe Scope Rule
Клиент отвечает только на вопросы, которые он объективно может понять.
Платформа не должна требовать от клиента технической диагностики, разборки оборудования, действий с электричеством или иных действий, которые могут быть небезопасны или ухудшить его положение.

Evidence:
- Plumbing: клиент отвечает только на объективно понятные вопросы.
- Plumbing Electric Shower: клиент не разбирает розетки, автоматы или проводку и не выполняет действий, связанных с электричеством.
- Locks: платформа не должна заставлять клиента выполнять действия, которые могут ухудшить его положение как покупателя оборудования.

### Rule #2 — Equipment Packaging Protection Rule
Если клиент уже приобрёл новое оборудование самостоятельно, Helpy не требует вскрытия упаковки до проверки совместимости мастером.
Фотографии упаковки должны позволять увидеть модель, характеристики, размеры и комплектацию, если они указаны производителем.
Клиент должен сохранять право на возврат, обмен и гарантийное обслуживание.

Evidence:
- Plumbing: клиент не должен вскрывать упаковку оборудования для создания заказа.
- Plumbing: при фотографировании упаковки клиент предоставляет упаковку со всей информацией на ней.
- Locks: платформа не требует вскрывать упаковку, нарушать заводские пломбы, раскладывать комплектующие или извлекать оборудование из коробки.

### Rule #3 — Equipment Compatibility Before Demolition Rule
Если работа предполагает замену оборудования, мастер обязан проверить новое оборудование до демонтажа существующего.
Проверка включает совместимость, комплектность, целостность и возможность установки.
Только после проверки мастер приступает к демонтажу.

Evidence:
- Plumbing faucet replacement: мастер проверяет совместимость до демонтажа.
- Plumbing toilet/electric shower replacement: новое оборудование должно быть проверено до работ.
- Locks: проверка нового оборудования до демонтажа существующего закреплена как Global Equipment Verification Rule.

### Rule #4 — Structured Scope Before Chat Rule
Форма заказа собирает первоначальное техническое задание и закрывает визуальную часть ТЗ.
Чат завершает текстовую часть ТЗ, уточняет скрытые работы, материалы, доступ и фиксирует окончательную стоимость.
Чат не заменяет структурированную форму заказа.

Evidence:
- Plumbing: форма собирает первоначальное ТЗ и закрывает визуальную часть.
- Plumbing: чат завершает текстовую часть ТЗ и фиксирует окончательную стоимость.
- Structured Job Scope Contract: Initial job scope is formed from structured questions, answers and required photos.

### Rule #5 — No Extra Photo Requests In Chat Rule
Мастер не может запрашивать дополнительные фотографии в чате, если обязательные фотографии уже определены формой заказа.
Фото-ТЗ должно формироваться через approved photo requirements.
Исключения возможны только через будущие утверждённые правила жизненного цикла чата.

Evidence:
- Plumbing faucet/mixer: мастер не может запрашивать фотографии в чате.
- Plumbing blockage: мастер не может запрашивать дополнительные фотографии в чате.
- Plumbing electric shower: мастер не может запрашивать дополнительные фотографии в чате.

### Rule #6 — One-Time Final Price Rule
Окончательная стоимость заказа может быть изменена мастером только один раз до выбора мастера.
Изменение требует обоснования, обсуждения с клиентом и согласования.
После согласования клиентом и выбора мастера Final Agreed Price становится неизменяемым финансовым фактом заказа.

Evidence:
- Plumbing: окончательная цена фиксируется мастером один раз и после согласования становится неизменяемой.
- Client Expected Price / Final Price Contract: мастер может один раз предложить изменение цены до выбора мастера.
- Final Price Architecture Decision: job-level financial snapshot is immutable after master selection.

### Rule #7 — Platform Boundary / Ownership Rule
Helpy не включает в услугу действия, которые не утверждены как часть сервиса платформы.
Материалы, дополнительные работы, утилизация, вынос демонтированного оборудования, личные вещи клиента, транспортировка, хранение, публичные зоны и вопросы собственности/права доступа не входят в платформенную ответственность, если отдельный контракт явно не утверждает обратное.

Evidence:
- Furniture: master does not move, sort or store client belongings.
- Plumbing: демонтированное оборудование остаётся собственностью клиента; вынос/утилизация не являются услугой Helpy.
- Locks: Helpy не работает с вопросами собственности, аренды и права доступа.
- Air Conditioning: материалы и дополнительные работы согласуются через чат; платформа не участвует в покупке материалов.

Recovery Note:
- Rule #1–Rule #7 recovered from verified category contracts and approved architecture contracts.
- Electrical confirms the existing Global Platform Rules and introduces zero new global rules.
- Electrical evidence is stored in Contract 23 and in the Electrical Category Architecture block.
- Final closure requires review after Appliance Installation & Connection is completed.
- If the future appliance category introduces overlapping global rules, this contract must be reconciled before being marked CLOSED.

## 17. Admin Panel Architecture
Status: PARTIALLY CLOSED — GAP APPROVED

Decision Summary:
- Admin Panel is a Business Logic Builder, not a simple order-management dashboard.
- Admin Panel is the source of truth for live Helpy operational configuration: categories, subcategories, questions, photo requirements, pricing, guidance, platform settings, rules, evidence, reviews, translations and operational control.
- Its standard Registry interface uses shared Registry governance contracts and does not redefine Registry Studio architecture.
- Mobile app must consume Admin-managed business logic through structured API contracts.
- Runtime Markdown document parsing is not allowed for mobile guidance.
- Draft / Published lifecycle, Audit Log, Preview, governed recovery, Helpy Category Health Check and PUBLISHING_DRAFT / SANDBOX workspace purposes are required governance capabilities.
- Implementation is not complete: multiple approved builders and roadmap modules remain GAP_APPROVED.
- Final DB baseline vs migration strategy remains DRAFT.
- This contract cannot be CLOSED until Admin builders, platform settings, guidance, rules, evidence, review and DB baseline strategy are aligned.

Implementation State:
- TARGET_APPROVED: Admin Panel as Business Logic Builder.
- IMPLEMENTED: basic Admin dashboard shell, Jobs list, Payments list, Disputes list, Translation Tasks admin endpoints, reset endpoints.
- GAP_APPROVED: Category Builder, Subcategory Builder, Question Builder, Photo Requirement Builder, Pricing Builder, Guidance Builder, Platform Settings Center, Audit Log, Governed Recovery, Rules Simulator, Impact Analysis, Helpy Registry Coverage, SANDBOX DraftWorkspace, Notification Center, Admin Order Timeline / Evidence Screen.
- CURRENT GAP: Admin frontend API client still references legacy admin URLs while backend exposes /api/v1/admin/* routes.
- DEFERRED: advanced admin roles, bulk operations, import/export, search everywhere.
- DRAFT: final DB baseline vs 0005 migration strategy.

Admin Panel is not a list of orders.

Admin Panel is a Business Logic Builder.

### Related Orders Admin Visibility

Status: GAP_APPROVED

Назначение:
- Admin Panel должна отображать группы связанных заказов.
- Admin Panel должна показывать, какие заказы входят в связанную группу.
- Admin Panel должна показывать исполнителя по каждому связанному заказу.
- Admin Panel должна показывать Final Agreed Price и комиссию платформы по каждому связанному заказу.
- При оплате наличными комиссия платформы удерживается с мастера отдельно по каждому заказу.
- Связка заказов не объединяет финансовые обязательства, evidence, dispute scope и completion flow.

### Category Builder

Category Builder is the top-level category architecture container.

Admin can manage:
- enable / disable category;
- add category;
- archive category instead of physical deletion;
- change category order;
- change category name;
- change category localizations;
- change category icons;
- manage category launch state;
- manage category structure;
- manage structured scope model;
- manage scenario architecture;
- manage client rules;
- manage master rules;
- manage scenario rules;
- manage required photo architecture;
- manage admin dependencies;
- manage guidance bindings;
- manage master eligibility bindings.

Category Builder must not bypass specialized builders.
Question Builder, Photo Requirement Builder, Pricing Builder, Guidance Builder, Global Rules Builder and Platform Settings Center remain specialized editors for their own domains.

### Subcategory Builder

Subcategory Builder is the second-level category architecture container.

Admin can manage:
- enable / disable subcategory;
- add subcategory;
- archive subcategory instead of physical deletion;
- sort subcategories;
- change subcategory name;
- change subcategory localizations;
- change subcategory launch state;
- manage subcategory structured scope model;
- manage subcategory scenario architecture;
- manage subcategory client rules;
- manage subcategory master rules;
- manage subcategory scenario rules;
- manage subcategory required photo architecture;
- manage subcategory guidance bindings;
- manage subcategory master eligibility bindings.

Subcategory Builder must inherit category-level rules unless explicitly overridden by approved subcategory architecture.

Subcategory Builder must not bypass specialized builders.
Question Builder, Photo Requirement Builder, Pricing Builder, Guidance Builder and Global Rules Builder remain specialized editors for their own domains.

### Question Builder

Question Builder is the specialized editor for structured client questions.

Admin can manage:
- enable / disable question;
- add question;
- archive question instead of physical deletion;
- sort questions;
- change question text;
- change question localizations;
- manage question type;
- manage answer options;
- manage required / optional state;
- manage conditional visibility;
- manage branching logic;
- manage dependency rules between questions;
- manage question impact on structured scope;
- manage question impact on scenario selection;
- manage question impact on required photo requirements;
- manage question-specific guidance bindings;
- manage role-based guidance bindings for answers.

Question Builder must not define category architecture directly.
Question impact must be validated through Category Health Check, Rules Simulator and Impact Analysis before publishing.

### Photo Requirement Builder

Photo Requirement Builder is the specialized editor for required photo architecture.

Admin can manage:
- enable / disable photo requirement;
- add photo requirement;
- archive photo requirement instead of physical deletion;
- sort photo requirements;
- change photo requirement text;
- change photo requirement localizations;
- manage required / optional state;
- manage minimum required photo count;
- manage maximum additional photo count;
- manage total photo limits;
- manage conditional visibility;
- manage dependency rules from questions and answers;
- manage scenario-specific photo requirements;
- manage photo impact on structured scope;
- manage photo impact on final job scope;
- manage photo-specific guidance bindings;
- manage role-based guidance bindings for photo steps.

Photo Requirement Builder must not define category architecture directly.
Photo requirement impact must be validated through Category Health Check, Rules Simulator and Impact Analysis before publishing.

### Pricing Builder

Pricing Builder is the specialized editor for category and scenario pricing logic.

Admin can manage:
- pricing rules;
- category-level pricing configuration;
- subcategory-level pricing configuration;
- scenario-level pricing configuration;
- coefficients;
- premium services;
- pricing visibility rules;
- pricing guidance bindings;
- pricing rule activation;
- Draft / Published pricing lifecycle.

Pricing Builder must use Final Agreed Price as the commission calculation basis.

Pricing Builder must not own global commission percentage.
Global commission percentage belongs to Platform Settings Center.

Pricing Builder must not own payment method behavior.
Payment method behavior belongs to payment and financial contracts.

Pricing changes must be validated through Rules Simulator, Impact Analysis and Category Health Check before publishing.

### Guidance Builder

Status: ✅ APPROVED

Purpose:
Admin-managed contextual guidance for clients and masters during key product flows.

Guidance content must be derived from approved service documentation, Service Playbooks, Client Docs, Master Docs and Admin Rules, but delivered to mobile app only through structured Admin/API records.

Runtime Markdown document parsing is not allowed for mobile guidance.

Guidance Targets:
- Client Guidance;
- Master Guidance;
- Safety Notes;
- Platform Notes;
- category-specific hints;
- subcategory-specific hints;
- question-specific hints;
- photo requirement hints;
- before-offer master guidance;
- create-order client guidance;
- completion guidance;
- dispute-prevention guidance.

Rule-Based Role Guidance:
- Client rules, master rules and scenario rules from approved category architecture must be available as role-based contextual guidance.
- Client rules must be shown only to clients.
- Master rules must be shown only to masters.
- Guidance must be attached to the relevant category, subcategory, scenario, screen, form step, photo step, order status or workflow action.
- Mobile app must show role-specific guidance at the step where the rule is relevant, not as a static document dump.
- Admin Panel must allow preview of role-specific guidance separately for Client View and Master View.
- Rule-based guidance must not contradict approved category architecture, Service Playbooks, Client Docs or Master Docs.

Trigger Context:
- role;
- screen;
- category;
- subcategory;
- form step;
- question key;
- photo step;
- order status;
- language.

Governance Rules:
- Guidance must be editable from Admin Panel without APK rebuild.
- Guidance must support RU, EN and TH.
- Guidance must support Draft / Published lifecycle.
- Only Published guidance is visible to users.
- Guidance must support preview for Client View and Master View.
- Guidance changes must be written to Audit Log.
- Guidance must not contradict approved Service Playbooks.
- Guidance must not replace legal documents.
- Guidance must be short, contextual and action-oriented.
- Mobile app must request guidance through structured API, not from raw documents.

Future Roadmap:
- Guidance Builder must be included in Admin Panel roadmap.
- Guidance Builder must be connected to Dynamic Form Engine.
- Guidance Builder must be connected to Knowledge Base Engine.
- Guidance Builder must be connected to Category Health Check.
- Guidance Builder must allow Admin to attach hints to category, subcategory, structured scope, question, photo requirement, client rules, master rules, role-based guidance and workflow stages.

### Draft / Published
Changes are prepared in Draft.
Only Published content is visible to users.

### Clone Category
Full category duplication.

### Archive Instead Of Delete
No physical deletion.
Archive only.

### Preview
- Client View
- Master View

### Test Order Preview
Create test orders before publishing.

### Category Health Check
Verify:
- category structure;
- subcategory structure;
- structured scope;
- scenario readiness;
- questions;
- photo requirements;
- localizations;
- pricing;
- client rules;
- master rules;
- scenario rules;
- guidance;
- role-based guidance;
- master eligibility bindings;
- launch state;
- admin dependencies;
- builder consistency;
- dependencies.

Category Health Check is a publishing gate.

Draft category changes must not be published if required health checks fail.

### Audit Log
Store:
- who changed;
- what changed;
- when changed.

### Rollback
Restore previous published version.

### Dependency Rules
Questions and photos can depend on previous answers.

### Admin Notes
Internal notes.
Not visible to users.

### Master Eligibility Rules

Master Eligibility Rules define whether a master may participate in a specific order.

Eligibility is a yes/no gate and must not be mixed with ranking.

Admin can manage eligibility bindings for:
- category;
- subcategory;
- scenario;
- required skill level;
- required verification;
- launch state;
- safety restrictions;
- platform restrictions.

Eligibility rules may depend on approved category architecture and master profile state.

Examples:
- master profile is active;
- master is not blocked;
- master supports the selected category/subcategory;
- category/subcategory/scenario is enabled;
- master meets required skill or verification rules if applicable.

Ineligible masters must not be shown as available for the order.

Eligible masters may still be ranked differently by the Master Ranking Hybrid Model.

Category Health Check must verify that category and subcategory master eligibility bindings are configured before publishing.

### Translation Review Workflow
Languages:
- RU
- EN
- TH

Statuses:
- Auto Generated
- Reviewed
- Approved

Admin can manually correct translations.

Translation review must support two entry paths:

- a selected existing Registry formulation forwarded into the translation workspace;
- a manually entered candidate source formulation for review before approval and
  addition to the canonical dictionary.

Both entry paths must use the same RU / EN / TH translation flow and the same
review statuses.

Manual candidate input:

- does not create a RegistryEntity, canonical dictionary record or publication evidence;
- does not approve or apply a formulation automatically;
- may be discarded without affecting Registry.

### Multi-Language Admin Interface
Supported:
- Russian
- English
- Thai

Entire admin interface must support localization.

### Feature Flags
Published but hidden functionality.
Enable without release.

### Notification Center
- Client Notifications
- Master Notifications
- Admin Notifications

### Platform Settings Center

Status: ✅ APPROVED

Purpose:
Centralized platform settings layer for business, legal, support, compliance, release, maintenance, backup-status and system-health metadata.

This section is part of Admin Panel Architecture.
It defines the required future Platform Settings contract, not the immediate UI implementation.

Editable Settings:
- commission;
- disputes;
- timers;
- premium prices;
- notification settings;
- translation settings;
- company name;
- company legal name;
- company address;
- company country;
- company city;
- support email;
- support phone;
- support WhatsApp;
- support Telegram;
- support working hours;
- Privacy Policy URL;
- Terms of Service URL;
- Refund Policy URL;
- Master Agreement URL;
- Client Agreement URL;
- maintenance mode;
- maintenance message;
- minimum supported Android app version;
- latest Android app version;
- soft update message;
- force update message.

Read-Only Operational Status:
- backup enabled;
- last backup run time;
- last backup status;
- backup retention policy;
- backup storage provider;
- last backup error;
- system status;
- API status;
- database status;
- translation status;
- payment status;
- last health check time;
- Data Safety last review time;
- permissions review status.

Governance Rules:
- Mobile app, backend and Admin Panel must consume public platform settings from one API contract.
- Legal, support and company metadata must not be hardcoded inside APK.
- Admin Panel may edit only approved editable settings.
- Operational status fields are read-only by default.
- Every platform setting change must create an audit log entry.
- Backup execution is infrastructure-owned.
- Admin Panel may display backup status and approved backup actions.
- Admin Panel must not expose unsafe raw database download by default.
- Secrets must never be stored in platform settings.
- API keys, payment credentials, Cloudflare tokens, Google Play credentials and private keys must remain in environment secrets.

Reserved Data Model:
- platform_settings;
- platform_setting_audit_log.

Reserved Public API:
- GET /api/v1/platform/settings/public

Reserved Admin API:
- GET /api/v1/admin/platform/settings
- PATCH /api/v1/admin/platform/settings/:key

### Admin Panel Roadmap Extensions

Status: ✅ APPROVED

Purpose:
Reserved Admin Panel modules that reduce operational risk, prevent business-rule drift and help validate configuration before publication.

These modules are part of the Admin Panel roadmap.
They do not require immediate MVP implementation, but the architecture must reserve space for them before Admin Panel development.

#### Registry Studio / Registry Operations

Status: PLANNED / ACTIVE DEVELOPMENT

Registry Studio integration is an Admin Panel roadmap capability for maintaining Helpy Registry as a structured source of truth.
Registry Studio itself remains a standalone engineering platform; Helpy is its first project adapter and pilot.

Purpose:
- Navigate the Registry as an architecture tree.
- Search Registry without losing hierarchy.
- Support canonical translation and audit workflows.
- Preserve checked phrase statuses between sessions.
- Track Registry changes until the workspace returns to CLEAN state.
- Support project Admin Panel integration through shared Registry governance contracts.

Core principle:
- Studio analyzes, highlights risks and preserves context.
- Studio does not make autonomous decisions. Final Registry structure, canonicalization, drift and ambiguity decisions remain with authorized engineers; project governance may require additional approval.

Required modules:
- Registry Explorer.
- Hierarchical Registry Search.
- Translation Review Integration.
- Canonical Audit.
- Phrase Status Persistence.
- Registry Health.
- Change Workspace.
- Impact Analysis.
- Dependency Graph.
- Registry Maintenance.
- Registry Diff.
- Registry Timeline.
- Registry Snapshot.
- Phrase Usage.
- TODO Queue.
- Favorites.
- Recently Opened.
- Cross References.
- Dead Object Detection.
- Duplicate Detector.
- Global Rename with Impact Analysis.
- Contract Validator.
- Registry Statistics.
- Registry CI.
- Draft Workspace.
- Session Recovery.
- Admin Panel Integration.

Design principles:
- Registry is the source of truth for canonical engineering state; live operational records remain owned by their project domain.
- Any Registry change must be traceable.
- Any Registry change must expose its impact before application.
- A PUBLISHING_DRAFT workspace becomes CLEAN only through successful atomic publication; abandoned work must be explicitly discarded.
- Studio must preserve work context between sessions.
- Studio must support engineers and authorized administrators, not replace human decision-making.
- Studio must reveal drift and unfinished work, including drift between project operational configuration and canonical Registry representation.
- Studio must allow one authorized actor to continue another authorized actor's work without losing context.



##### Registry Transaction Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

RegistryTransaction is the only governed lifecycle owner for one Registry
modification intended for publication.

RegistryTransaction:

- has stable transaction identity;
- originates from one PUBLISHING_DRAFT DraftWorkspace;
- preserves the source RegistrySnapshot reference;
- preserves exact draft revision and draft fingerprint references used as
  governance evidence;
- owns analysis, validation, approval and publication evidence for that
  modification;
- owns transaction outcome;
- owns PublicationAttempt records;
- preserves immutable audit references;
- must not modify Published Registry directly;
- must not own DraftWorkspace revision, fingerprint, DIRTY state or CLEAN state;
- must not finish in CLEAN state;
- must not change the historical outcome of an already published transaction.

RegistryTransaction is not Published Registry, DraftWorkspace, a storage
commit or a generic data-transfer wrapper.

All Registry changes intended for publication must originate through a
PUBLISHING_DRAFT DraftWorkspace and exactly one active RegistryTransaction.

Transaction evidence must remain pinned to the exact source RegistrySnapshot
and exact DraftWorkspace revision from which it was produced.

A later workspace modification invalidates prior analysis, validation, risk
and gate evidence. Publication remains prohibited until current evidence is
recomputed.

Required engineer approval must be preserved as transaction evidence when
approval is required by governance policy.

Partial publication is prohibited.

The successful publication path uses the atomic PublishRegistryRevision
application boundary defined by Repository Boundary Contracts.

Data, API and storage mappings may serialize transaction information, but no
separate Domain payload model is introduced for RegistryTransaction.

Legacy rollback-specific transaction states are removed. Recovery is governed
through a new RegistryTransaction and does not rewrite historical outcome of
the original published transaction.

##### Registry Storage Independence

Status: APPROVED

- Registry Studio operates on Registry domain entities.
- Markdown parsing belongs exclusively to the Data layer.
- Domain, Application and Presentation layers must never depend on Markdown syntax.
- Repository boundary contracts isolate published Registry state, DraftWorkspace state and governance records from storage implementation.
- Replacing Markdown with another storage implementation must not require changes to Registry Studio business logic.

##### Registry Studio Clean Architecture Rule

Status: APPROVED

- Registry Studio must be designed through explicit domain models, use cases, repositories and presentation state.
- Helpers, wrappers and temporary adapters must not replace domain modeling.
- Shared logic must be promoted into the correct layer instead of being hidden in UI helpers.
- Presentation layer must not contain Registry parsing, search, dependency analysis, validation or publication logic.
- Data layer may adapt storage formats, but must not leak storage-specific details into Domain or Presentation.
- Any temporary technical shortcut must be treated as technical debt and removed before the related module is considered complete.
- Registry Studio architecture must prioritize long-term maintainability over fast local fixes.




##### AI Engineering Principles

Status: APPROVED

Purpose:

Define the mandatory engineering principles for AI-assisted development of Registry Studio.

1. Registry and verified project artifacts are the source of truth.
Conversational context, AI memory and assumptions must never override verified project artifacts.

2. Verify project state before making engineering conclusions.
Every engineering conclusion must be based on verified project artifacts.

3. Architecture before implementation.
Architecture, domain model and contracts must be approved before implementation begins.

4. Respect architectural boundaries.
Business logic belongs to the appropriate architectural layer and must never be hidden inside helpers, wrappers or presentation code.

5. Preserve engineering consistency.
Every implementation must remain consistent with approved architecture and must reduce, not increase, technical debt.

6. Engineer remains the decision maker.
AI assists engineering work but never replaces architectural or business decisions.

7. Engineering success is measured by correctness, maintainability and long-term stability rather than implementation speed.

##### Engineering Workflow

Status: APPROVED

Mandatory order:

Architecture
→ Contracts
→ Domain Model
→ Validation
→ Implementation
→ Integration
→ Refactoring
→ Optimization

Skipping stages is prohibited.

##### Engineering Evidence

Status: APPROVED

Engineering decisions may rely only on verified project artifacts.

Verified engineering evidence includes:
- Approved Registry.
- Repository history.
- Verified source code.
- Verified implementation.
- Terminal command output.
- Build results.
- Analyzer results.
- Test results.
- Git status.
- Git diff.
- CI/CD execution results.

Conversational context, AI memory, assumptions and expected behavior are not engineering evidence.

##### Runtime Verification Rule

Status: APPROVED

Every implementation step must finish with runtime verification before being considered complete.

Engineering conclusions about implementation must be based on actual execution results rather than expected behavior.

If runtime evidence contradicts assumptions, runtime evidence always takes precedence.



##### Registry Engineering Model

Status: APPROVED

Registry Studio is an engineering platform for the full Registry lifecycle.

It is not a set of disconnected tools.

Registry Studio responsibilities:
- design Registry;
- analyze Registry;
- modify Registry;
- verify Registry;
- validate Registry;
- preserve engineering context;
- manage the engineering workflow;
- apply approved changes through Registry Transaction Model.

Registry Studio boundaries:
- Registry Studio does not replace Admin Panel.
- Registry Studio does not replace Git.
- Registry Studio does not manage mobile runtime behavior.
- Registry Studio does not manage orders, payments or users.
- Registry Studio must not perform hidden Registry changes.
- Registry Studio must not bypass Registry Transaction Model.
- Registry Studio must not publish changes outside the approved transaction workflow.

Registry Studio is authorized to modify the Registry only through the approved Registry Transaction Model.


##### Registry Studio Domain Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

Registry Studio Core is a reusable engineering foundation for one logical
Registry and its governed semantic evolution.

Core Registry model:

- Registry;
- RegistryEntity;
- RegistryEntityKind extension contract;
- RegistryEntityPayload extension contract;
- RegistryPath;
- RegistryRelation;
- RegistryDependency;
- RegistryGraph;
- immutable RegistrySnapshot governance record.

Registry:

- is the Core root aggregate for one logical Registry;
- has stable storage-independent identity;
- owns current published semantic state composed of RegistryEntity,
  RegistryPath and RegistryRelation;
- exposes exactly one current published revision;
- records deterministic published content fingerprint;
- records adapter identity and adapter semantic-contract version required
  to interpret published semantic state;
- does not use Markdown bytes, line numbers, Git identifiers, parser output
  or storage coordinates as semantic identity;
- does not own DraftWorkspace mutable state or draft revisions;
- does not own RegistryGraph or RegistryDependency projections;
- does not own analysis, validation, risk, publication, audit or runtime state.

Published Registry is not a separate aggregate. It is the current immutable
published revision of Registry and changes only through a successful approved
PublicationAttempt governed by RegistryTransaction.

Published revision is immutable provenance identified by Registry identity,
published revision reference and published content fingerprint.

Published content fingerprint must be calculated from canonical semantic state:

- RegistryEntity identity;
- adapter-defined kind;
- typed semantic content;
- canonical RegistryPath;
- canonical RegistryRelation;
- required adapter semantic-contract version.

The fingerprint must be deterministic for semantically identical published
state and must not depend on formatting, ordering, storage addresses or Git
commit identity.

RegistryEntity:

- has stable identity;
- has exactly one primary adapter-defined RegistryEntityKind;
- owns one canonical RegistryPath;
- contains typed adapter-defined semantic content;
- participates in canonical RegistryRelation records;
- does not own Draft / Published lifecycle;
- does not own validation, impact or risk state;
- does not own RegistryTransaction lifecycle;
- does not own audit history;
- does not own runtime execution state.

EngineeringAsset is removed. It has no independent identity, lifecycle,
ownership or consumers that cannot be represented by Registry governance,
transaction evidence and runtime contracts.

Registry Studio Core must not rely on untyped dynamic semantic payloads.

##### RegistryEntityKind and RegistryEntityPayload Boundary

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

Registry Studio Core retains only:

- RegistryEntityKind extension contract;
- RegistryEntityPayload extension contract;
- typed payload requirement;
- prohibition of untyped dynamic payloads;
- analysis and validation support for adapter-defined kinds and payloads.

Concrete RegistryEntityKind values and concrete RegistryEntityPayload schemas
belong to project adapters.

Every RegistryEntity must have exactly one primary adapter-defined kind.
Additional classification belongs to adapter-defined semantic content,
qualifiers or canonical RegistryRelation records.

RegistryEntityPayload:

- contains typed adapter-defined semantic content for one RegistryEntity;
- represents semantic meaning, not Markdown formatting, parser output,
  database schema or API response shape;
- is interpreted through adapter identity, adapter semantic-contract version,
  RegistryEntityKind schema version and RegistryEntityPayload schema version;
- must remain deterministic for one exact Registry revision.

Governance records, analysis results, application capabilities, runtime
contracts and UI concepts must not become RegistryEntityKind values or
RegistryEntityPayload schemas.

This includes draft state, published revision, transaction, impact analysis,
dependency analysis, risk classification, validation result, health check,
audit log, rollback, snapshot, feature flag, platform setting, builder,
workflow and review concepts.

The current Helpy semantic kinds and payload schemas remain valid Helpy adapter
semantics. They are not Registry Studio Core taxonomy.

##### RegistryRelation Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

RegistryRelation is one canonical directed semantic edge between exactly two
RegistryEntity objects.

RegistryRelation:

- belongs to Registry semantic state;
- has deterministic relation identity;
- changes only through DraftWorkspace and RegistryTransaction governance;
- participates in RegistryGraph;
- has no separate RegistryEntityPayload;
- must be derived from approved semantic contracts, not Markdown hierarchy alone;
- may contain typed adapter-defined qualifiers when required.

Only one canonical directed RegistryRelation record may be persisted for one
semantic fact.

Reverse traversal, inverse display labels and reverse dependency navigation
must be derived by RegistryGraph. They must not create a second persisted
semantic fact.

Registry Studio Core does not own a closed enumeration of concrete relation
kinds.

Each project adapter must define for every concrete relation kind:

- stable kind identifier;
- adapter semantic-contract version;
- semantic meaning;
- qualifier schema when required;
- impact propagation behavior;
- validation constraints;
- cycle policy;
- inverse and display interpretation when required.

No inverse adapter labels may be persisted as separate RegistryRelation records
for the same semantic fact.

Relation labels such as contains, references, inherits, overrides, belongsTo,
bindsTo, extends, specializes, triggers, follows and precedes may exist as
adapter-defined semantics only.

##### RegistryDependency Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

RegistryDependency is a derived explainable impact edge for one exact Registry
or DraftWorkspace revision and adapter semantic-contract version.

RegistryDependency:

- is built from RegistryRelation and adapter-defined semantic rules;
- is not independently editable Registry content;
- is not a RegistryEntity;
- has no separate RegistryEntityPayload;
- preserves source relation, revision and adapter provenance;
- does not own risk, validation or publication state.

Dependency result categories:

1. Direct confirmed dependency.
2. Indirect impact through confirmed relation or dependency paths.
3. Semantic candidate requiring engineer decision.
4. Informational text match without confirmed semantic relation.

Only direct confirmed dependencies and indirect impacts enter deterministic
impact scope automatically.

Each project adapter must declare cycle policy for every concrete
RegistryRelation kind.

Validation must enforce declared adapter cycle policy for the exact revision.

RegistryGraph must detect cycles, stop configured traversal deterministically
when a cycle is reached and explain the complete traversal path.

##### RegistryPath Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

RegistryPath is the canonical logical address of one RegistryEntity.

RegistryPath:

- is a value object;
- is not a RegistryEntity;
- is not a RegistryGraph node;
- has no independent payload;
- belongs to RegistryEntity;
- remains stable while RegistryEntity identity is preserved;
- may be indexed as derived lookup material;
- changes only through governed Registry modification.

RegistryPath must not depend on Markdown line numbers, heading levels, file
offsets, parser details, storage backend identifiers or database addresses.

Engineering services must use RegistryPath and stable RegistryEntity identity
instead of storage coordinates.

##### RegistrySnapshot Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

RegistrySnapshot is an immutable governance record for one exact verified
Registry revision.

RegistrySnapshot:

- has independent snapshot identity;
- is not a storage backup;
- is not a second editable Registry source of truth;
- is not a RegistryEntity;
- is not a RegistryGraph node;
- has no separate Domain payload model;
- pins semantic state required for history comparison, impact explanation,
  audit evidence and governed recovery.

RegistrySnapshot must contain:

- snapshot identity;
- Registry identity;
- snapshot revision reference;
- deterministic semantic fingerprint;
- creation timestamp;
- creation reason;
- adapter identity;
- adapter semantic-contract version;
- RegistryEntityKind and RegistryEntityPayload schema versions;
- exact pinned canonical semantic state composed of RegistryEntity identity,
  adapter-defined kind, typed semantic content, RegistryPath and
  RegistryRelation;
- immutable verification or publication evidence references when applicable.

RegistrySnapshot must not own as canonical snapshot state:

- RegistryGraph;
- RegistryDependency;
- ValidationResult state;
- RiskAssessment;
- DraftWorkspace DIRTY / CLEAN state;
- AuditLog contents;
- runtime state.

Entity and relation indexes may exist only as pinned or reproducible lookup
materializations of snapshot semantic state. They must never become separately
editable semantic truth.

RegistryDependency is derived for the exact RegistrySnapshot revision and
adapter semantic-contract version. It must not be stored as canonical snapshot
state.

Snapshot lifecycle:

- source RegistrySnapshot must exist before DraftWorkspace begins mutable
  change preparation;
- successful publication creates a resulting RegistrySnapshot for the new
  published semantic state;
- failed, blocked or cancelled publication does not create a resulting
  published RegistrySnapshot;
- RegistrySnapshot provides immutable source and resulting state evidence only.

Snapshot comparison must expose changed, added, removed and affected
RegistryEntity objects, RegistryPath values and RegistryRelation records.

##### RegistryGraph Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

RegistryGraph is a derived deterministic projection of one exact published
Registry revision or DraftWorkspace revision.

RegistryGraph is not a UI tree, Markdown outline, independent aggregate,
RegistryEntity or canonical source of semantic truth.

RegistryGraph derives from:

- RegistryEntity;
- RegistryPath;
- RegistryRelation;
- RegistryDependency;
- adapter-defined relation and dependency semantics;
- exact revision and adapter semantic-contract version.

RegistryGraph provides:

- deterministic entity and path lookup;
- forward and reverse relation traversal;
- derived dependency navigation;
- affected-entity lookup;
- path provenance;
- cycle detection;
- explainable deterministic traversal.

RegistryGraph:

- must not modify Registry;
- must not persist inverse relation duplicates;
- must not own semantic state independently of the exact source revision;
- may expose indexes only as derived projections;
- must remain independent of Markdown hierarchy and storage implementation.

##### Repository Boundary Contracts

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

Registry Studio uses exactly three logical persistence boundaries.

These boundaries are not wrappers, helpers or a requirement for separate
databases, tables or physical stores. One storage adapter may implement all
three boundaries while preserving their independent ownership contracts.

RegistryRepository:

- owns load and persistence of current published Registry semantic state;
- persists Registry identity, current published revision, fingerprint,
  RegistryEntity, RegistryPath and RegistryRelation;
- does not own DraftWorkspace state;
- does not own RegistryTransaction, RegistrySnapshot or AuditLog;
- does not own RegistryGraph or RegistryDependency projections;
- does not own analysis, validation, risk, gate or publication evidence.

DraftWorkspaceRepository:

- owns isolated DraftWorkspace state for PUBLISHING_DRAFT and SANDBOX;
- persists workspace identity, purpose, source RegistrySnapshot reference,
  current workspace revision, fingerprint, resumable engineering context and
  DIRTY / CLEAN state;
- does not own Published Registry state;
- does not own RegistryTransaction lifecycle;
- does not own immutable RegistrySnapshot or AuditLog records.

RegistryGovernanceRepository:

- owns RegistryTransaction and transaction-owned evidence;
- owns immutable RegistrySnapshot records;
- owns append-only AuditLog records;
- persists ImpactAnalysisResult, ValidationResult, RiskAssessment,
  PublishingGateDecision and PublicationAttempt only through their owning
  RegistryTransaction;
- does not own current Published Registry state;
- does not own mutable DraftWorkspace state;
- does not build RegistryGraph or derive RegistryDependency.

No independent persistence boundary exists for RegistryGraph,
RegistryDependency, reverse traversal, relation indexes, ImpactAnalysisResult,
ValidationResult, RiskAssessment, PublishingGateDecision or PublicationAttempt.

RegistryGraph, RegistryDependency, traversal and indexes are derived
projections. Transaction evidence remains owned by RegistryTransaction.

Publication atomicity:

- one invocation of PublishRegistryRevision is the single atomic application
  boundary for publication;
- PublishRegistryRevision coordinates RegistryRepository,
  DraftWorkspaceRepository and RegistryGovernanceRepository according to
  their independent ownership contracts;
- every publication write must participate in one native all-or-nothing
  storage write scope;
- repositories must not expose begin, commit or rollback methods, technical
  transaction wrappers or staged mutable write state;
- publication must verify expected source Registry revision and fingerprint
  before applying changes;
- a storage implementation that cannot provide all-or-nothing publication is
  not publication-capable.

No composite RegistryRepository, PublicationCommitPort, SnapshotRepository or
technical transaction wrapper is introduced.

##### Engineering Change Analysis

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

Engineering Change Analysis is an application use case that prepares verified
decision support for one exact DraftWorkspace revision.

Engineering Change Analysis:

- collects verified source RegistrySnapshot and DraftWorkspace context;
- derives explainable relation and dependency impact context;
- creates immutable ImpactAnalysisResult evidence;
- may identify semantic candidates and informational text matches;
- is not a RegistryEntity;
- is not a RegistryEntityPayload;
- is not a persistent lifecycle owner;
- does not publish Registry changes;
- does not replace engineer decision-making.

Registry Studio must provide enough verified context to prevent an engineer
from manually reconstructing Registry logic before a change decision.

##### Impact Analysis Result Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

ImpactAnalysisResult is an immutable assessment for one exact
RegistryTransaction, DraftWorkspace revision and source RegistrySnapshot.

ImpactAnalysisResult:

- identifies directly changed and indirectly affected RegistryEntity objects;
- identifies affected RegistryPath values and RegistryRelation records;
- identifies confirmed dependency paths;
- explains why each affected item enters scope;
- distinguishes direct confirmed dependency, indirect confirmed impact,
  semantic candidate and informational text match;
- preserves adapter identity and semantic-contract provenance;
- does not become a RegistryEntity;
- does not require a RegistryEntityPayload;
- does not become an independent aggregate or persistence boundary.

Only direct confirmed dependencies and indirect confirmed impacts enter
deterministic impact scope automatically.

Semantic candidates require engineer decision.

Informational text matches provide context only and must not become confirmed
dependency evidence without approved semantic support.

RiskAssessment is derived from current ImpactAnalysisResult and
ValidationResult.

RiskAssessment:

- is advisory evidence for engineer decision-making;
- is not a standalone RegistryEntity;
- is not persistent dependency state;
- must not become a separate lifecycle model;
- must not bypass blocking validation, hard dependency or approval rules.

##### Validation Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

Validation is a deterministic policy and service that verifies one exact
DraftWorkspace revision.

Validation:

- validates semantic integrity, path integrity, relation constraints and
  adapter-defined semantic rules;
- validates declared adapter cycle policy for the exact revision;
- may execute approved adapter-defined validation extensions;
- remains storage independent;
- does not modify Registry;
- does not publish Registry changes;
- does not own transaction lifecycle.

ValidationResult is immutable transaction-owned verification evidence.

ValidationResult:

- belongs to one RegistryTransaction and one exact DraftWorkspace revision;
- references the verified source RegistrySnapshot;
- identifies affected RegistryEntity and RegistryPath values when validation
  fails or blocks publication;
- becomes stale after any DraftWorkspace modification;
- must remain explainable and reproducible for identical verified inputs.

Failed validation, unresolved hard dependency and missing required approval are
blocking conditions. Advisory risk does not override them.

##### Publishing Gate Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

PublishingGate is a pure governance policy for one exact current
DraftWorkspace revision.

PublishingGate:

- evaluates only non-stale ImpactAnalysisResult, ValidationResult,
  RiskAssessment and required approval evidence;
- verifies that no newer unvalidated DraftWorkspace revision exists;
- applies blocking governance invariants;
- returns PublishingGateDecision;
- does not own lifecycle state;
- does not modify Registry;
- does not create RegistryTransaction;
- does not execute publication.

PublishingGateDecision is a transaction-owned decision value for one exact
draft revision.

A blocked gate decision is not a completed PublicationAttempt.

DraftWorkspace CLEAN transition occurs only inside successful atomic
PublishRegistryRevision publication. CLEAN is not a pre-publication gate
condition.

##### Publication Attempt

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

PublicationAttempt is transaction-owned immutable evidence of an applied,
failed or cancelled publication execution.

PublicationAttempt contains:

- current DraftWorkspace revision;
- source RegistrySnapshot;
- PublishingGateDecision reference;
- before-publication RegistrySnapshot;
- resulting RegistrySnapshot when publication succeeds;
- publication outcome;
- cancellation or failure reason when applicable;
- immutable audit references.

PublicationAttempt is not an independent aggregate, RegistryEntity,
RegistryEntityPayload or persistence boundary.

A blocked PublishingGateDecision prevents creation of an applied publication
attempt.

##### Governed Recovery

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

Recovery is a governed operation, not a parallel aggregate or storage restore.

Canonical recovery flow:

Published RegistryTransaction A
→ recovery request
→ new PUBLISHING_DRAFT DraftWorkspace
→ new RegistryTransaction B
→ Engineering Change Analysis
→ Validation
→ required engineer approval
→ publication

Recovery RegistryTransaction B references:

- published RegistryTransaction A;
- target verified RegistrySnapshot;
- recovery reason;
- current analysis, validation and approval evidence;
- PublicationAttempt;
- immutable audit records.

RegistryTransaction A remains historically PUBLISHED.

No standalone recovery payload model is introduced.

##### Draft Workspace Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

DraftWorkspace is the common isolated workspace aggregate for Registry change
preparation and experimentation.

DraftWorkspace:

- has exactly one purpose:
  - PUBLISHING_DRAFT;
  - SANDBOX;
- references one source RegistrySnapshot;
- owns current isolated workspace revision and fingerprint;
- preserves resumable engineering work context;
- may be discarded without affecting Published Registry;
- does not own RegistryTransaction lifecycle;
- does not own validation lifecycle;
- does not own publication lifecycle;
- does not own RegistryGraph or RegistryDependency as independent state.

PUBLISHING_DRAFT:

- prepares Registry changes intended for publication;
- has exactly one active RegistryTransaction;
- owns mutable draft revision and fingerprint;
- owns DIRTY and CLEAN state;
- may request ImpactAnalysis, Validation, RiskAssessment and PublishingGate
  evidence;
- is the only workspace purpose permitted to enter publication governance.

SANDBOX:

- owns an isolated experimental revision;
- has no RegistryTransaction;
- must not invoke PublishingGate or publication;
- may run deterministic simulation, analysis and validation experiments;
- produces informational experimental results only;
- must not treat experimental results as publication evidence;
- may be discarded without affecting PUBLISHING_DRAFT workspaces or Published
  Registry.

Sandbox promotion does not convert an existing SANDBOX workspace.

Promotion creates a new PUBLISHING_DRAFT DraftWorkspace seeded from the exact
sandbox revision and fingerprint, then creates a new RegistryTransaction and
requires fresh analysis, validation, risk and gate evidence.

Blocking state belongs to current validation and gate evidence, not to
DraftWorkspace lifecycle.

No separate SandboxMode model is introduced.

##### Audit Log Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

AuditLog is an append-only immutable audit-record stream.

Each audit record has independent identity and contains:

- actor;
- action;
- timestamp;
- immutable event summary;
- stable references;
- affected RegistryEntity and RegistryPath references when applicable;
- RegistryTransaction reference when applicable;
- DraftWorkspace reference when applicable;
- RegistrySnapshot reference when applicable.

Audit records may reference ImpactAnalysisResult, ValidationResult,
PublishingGateDecision, PublicationAttempt and governed recovery evidence.

AuditLog:

- must remain immutable after record creation;
- must use RegistryPath and stable RegistryEntity identity rather than storage
  coordinates;
- must not depend on Markdown line numbers or parser implementation details;
- must not duplicate mutable governance state from transaction, workspace or
  evidence owners;
- must not expose secrets or unsafe operational data.

##### Bulk Operations Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

BulkOperations is an application service that prepares and applies approved
deterministic change plans inside one PUBLISHING_DRAFT DraftWorkspace.

BulkOperations:

- operates only against the current isolated DraftWorkspace revision;
- applies only a deterministic plan with explicit affected semantic targets;
- must not create or own RegistryTransaction lifecycle;
- must not directly own analysis, validation, gate or audit lifecycle;
- must not modify Published Registry directly;
- must preserve transaction atomicity through the established governance flow;
- must not apply a partial deterministic plan;
- must remain explainable and reproducible for identical verified inputs.

BulkOperations may support semantic rename, move, replace, delete, create,
merge, split, metadata update, reclassification and refactoring operations
when the active project adapter defines their semantics.

Any resulting change invalidates prior draft evidence. Analysis, validation,
risk, gate and publication remain governed by the active RegistryTransaction.

##### Global Rename Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

GlobalRename is a semantic bulk-refactoring operation. It is not a text
replacement tool.

GlobalRename:

- identifies one target RegistryEntity through stable immutable identity;
- preserves RegistryEntity identity;
- may change display name, semantic key, RegistryPath segment, canonical label
  and adapter-defined semantic references;
- identifies confirmed semantic references through RegistryGraph and
  adapter-defined relation semantics;
- distinguishes confirmed semantic references from semantic candidates and
  informational text matches;
- prepares deterministic changes through BulkOperations;
- must not modify Published Registry directly;
- must remain explainable and reproducible for identical verified inputs.

Informational text matches must not be rewritten automatically.

Naming conflict, invalid target semantics or incomplete confirmed reference
coverage must block the deterministic plan until resolved through governance.

##### Registry Studio Platform Scope

Status: APPROVED

RegistryStudio is a reusable engineering platform for managing Registry-based domain models.

RegistryStudio is not tied to a specific business project.

RegistryStudio provides a generic engineering foundation that may be reused across multiple products.

RegistryStudio consists of:
- Registry Domain Model;
- Engineering Governance;
- Engineering Services;
- Analysis Engine;
- Repository Contracts;
- Platform APIs.

Business projects integrate through project-specific adapters.

Project adapters may define:
- RegistryEntityKind;
- RegistryEntityPayload;
- business rules;
- guidance;
- workflows;
- validation extensions;
- project metadata.

RegistryStudio core must remain independent of project-specific business logic.

RegistryStudio responsibilities:
- manage Registry domain models;
- provide deterministic engineering analysis;
- support safe Registry evolution;
- provide reusable engineering services;
- remain storage independent;
- remain project independent.

Rules:
- RegistryStudio core must not contain project-specific business logic.
- Every project must integrate through approved platform contracts.
- Platform services must operate only on Registry domain contracts.
- Project adapters may extend, but must not modify RegistryStudio core.
- RegistryStudio upgrades must not require redesign of integrated projects.
- New platform capabilities require an approved domain contract before implementation.

###### Interface Boundary

One Registry governance core supports multiple project-neutral Registry interfaces:

- Registry Studio provides the full precise engineering interface;
- an Admin Panel provides the standard project interface;
- every Registry-facing interface uses the same approved Registry governance contracts and publication path;
- Registry Studio may operate standalone and is not a module of any project's Admin Panel.

A project Admin Panel may separately publish project operational records through
project-specific workflows. That does not redefine Registry Studio or directly
alter canonical Registry engineering state. Any resulting divergence is input
to subsequent Registry Studio drift analysis.

###### Current Development Boundary

- Registry Studio universal source code and contracts develop in the `helpy_translator` repository on `develop/v2`;
- Helpy is the first project adapter and pilot, not the owner of Registry Studio;
- generic Registry Studio changes and builds must not be made in the Helpy repository;
- the Helpy repository receives only explicit Helpy adapter or integration changes.



##### Registry Studio Architecture Audit Decision Register

Status: APPROVED — ARCHITECTURE CORRECTION BASELINE

Purpose:

This register records the architectural audit decisions required before further Registry Studio expansion.

Registry Studio must not continue adding domain models, payload models, result contracts, runtime components or platform capabilities until the current responsibility boundaries are applied consistently.

Precedence:

- This register has priority over earlier Registry Studio descriptions when they conflict.
- Legacy models, taxonomy lists and cross-references that contradict this register must not be used as a basis for new implementation.
- Existing contracts remain subject to targeted reclassification, merge, relocation or removal according to the decisions below.
- Required product capability does not automatically require a new Registry entity, payload, result contract, service model or runtime aggregate.
- A separate model is allowed only when an existing owner cannot legally hold the responsibility without mixing identity, lifecycle, ownership or architectural boundaries.

Audit criteria:

Every Registry Studio candidate model must prove:

- independent identity;
- independent lifecycle;
- explicit lifecycle owner;
- required RegistryGraph participation;
- required typed payload;
- non-duplication of an existing responsibility;
- storage independence;
- project independence when proposed for Registry Studio Core;
- stable behavior across Registry revisions, adapter upgrades and workflow changes.

###### 1. Target Platform Boundary

Registry Studio Core:

- reusable engineering foundation for Registry-based domain models;
- Registry domain contracts;
- governance contracts;
- analysis execution contracts;
- repository boundaries;
- runtime execution abstractions;
- storage-independent engineering services.

Project Adapter:

- RegistryEntityKind definitions;
- RegistryEntityPayload schemas;
- business semantics;
- validation extensions;
- relation and dependency semantics;
- workflow definitions;
- guidance;
- project metadata;
- project-specific migration and compatibility rules.

Application Services:

- graph traversal;
- analysis;
- validation;
- simulation;
- semantic refactoring;
- deterministic change planning.

Runtime:

- confirmed engineering workflow execution;
- step execution;
- handler binding;
- engineer decision points;
- deterministic stop, resume and completion behavior.

Governance:

- DraftWorkspace;
- RegistryTransaction;
- immutable RegistrySnapshot;
- publication governance;
- audit records;
- governed recovery transactions.

###### 2. Core Registry Domain Decisions

| Object | Decision | Canonical role |
|---|---|---|
| Registry | retain / contract closed | Core root aggregate for one logical Registry and its current published semantic state |
| RegistryEntity | retain | Semantic Registry unit |
| RegistryEntityKind | retain / reclassify | Core extension contract; concrete kinds belong to project adapters |
| RegistryEntityPayload | retain / reclassify | Typed adapter-defined semantic content for RegistryEntity |
| RegistryPath | retain as value object | Canonical logical address of RegistryEntity |
| RegistryRelation | retain / reclassify | Canonical directed semantic edge |
| RegistryDependency | retain / reclassify | Derived explainable impact edge |
| RegistryGraph | retain / reclassify | Derived projection of a specific Registry revision |
| RegistryRepository | retain / narrow | Storage port for current published Registry semantic state |
| EngineeringAsset | remove | Orphaned abstraction with no independent responsibility or consumers |

Registry:

- is the Core root aggregate for one logical Registry;
- has stable storage-independent Registry identity;
- owns canonical published semantic state composed of RegistryEntity, RegistryPath and RegistryRelation;
- exposes exactly one current published revision;
- records deterministic published content fingerprint;
- records adapter identity and adapter semantic-contract version required to interpret current published semantic state;
- does not use Markdown bytes, line numbers, Git commit identifiers or storage coordinates as Registry identity, published revision identity or semantic fingerprint;
- does not own DraftWorkspace mutable state;
- does not own draft revisions;
- does not own RegistryGraph or RegistryDependency projections;
- does not own ImpactAnalysisResult, ValidationResult or RiskAssessment;
- does not own RegistryTransaction lifecycle;
- does not own AuditLog records;
- does not own runtime execution state.

Published Registry:

- is not a separate model;
- means the current immutable published revision of Registry;
- changes only through a successful approved PublicationAttempt governed by RegistryTransaction.

Published revision:

- is immutable once published;
- is Registry provenance, not a new aggregate;
- is identified by Registry identity, published revision reference and published content fingerprint;
- is interpreted through the adapter identity and semantic-contract version captured with it.

Published content fingerprint:

- is calculated from canonical semantic state;
- includes RegistryEntity identity, adapter-defined kind, typed semantic content, canonical RegistryPath, canonical RegistryRelation and required adapter semantic-contract version;
- must be deterministic for semantically identical published state;
- must not depend on storage formatting, Markdown ordering, parser output, database record addresses or Git commit identity.

Draft revision:

- is not a Registry published revision;
- belongs only to DraftWorkspace;
- is mutable until publication;
- references its source published RegistrySnapshot;
- invalidates analysis, validation, risk and gate evidence whenever it changes.

RegistryEntity:

- has stable identity;
- has exactly one primary adapter-defined RegistryEntityKind;
- owns one canonical RegistryPath;
- contains typed adapter-defined semantic content;
- participates in semantic RegistryRelation objects;
- does not own Draft / Published lifecycle;
- does not own validation state;
- does not own impact or risk state;
- does not own transaction lifecycle;
- does not own audit history;
- does not own runtime execution state.

RegistryPath:

- is not a RegistryEntity;
- is not a RegistryGraph node;
- has no independent payload;
- belongs to RegistryEntity;
- remains stable while entity identity is preserved;
- must not depend on Markdown lines, headings, offsets, parser details or storage identifiers.

Repository boundaries:

Registry Studio uses exactly three logical persistence boundaries.

These boundaries are not wrappers, helpers or a requirement for separate databases, tables or physical stores. One storage adapter may implement all three boundaries when it preserves their independent ownership contracts.

RegistryRepository:

- owns load and persistence of current published Registry semantic state;
- persists Registry identity, current published revision, fingerprint, RegistryEntity, RegistryPath and RegistryRelation;
- does not own DraftWorkspace state;
- does not own RegistryTransaction, RegistrySnapshot or AuditLog;
- does not own RegistryGraph or RegistryDependency projections;
- does not own analysis, validation, risk, gate or publication evidence.

DraftWorkspaceRepository:

- owns isolated DraftWorkspace state for both PUBLISHING_DRAFT and SANDBOX purposes;
- persists workspace identity, purpose, source RegistrySnapshot reference, current workspace revision, fingerprint, resumable engineering context and DIRTY / CLEAN state;
- does not own Published Registry state;
- does not own RegistryTransaction lifecycle;
- does not own immutable RegistrySnapshot or AuditLog records.

RegistryGovernanceRepository:

- owns RegistryTransaction and transaction-owned evidence;
- owns immutable RegistrySnapshot records;
- owns append-only AuditLog records;
- persists ImpactAnalysisResult, ValidationResult, RiskAssessment, PublishingGateDecision and PublicationAttempt only through their owning RegistryTransaction;
- does not own current Published Registry state;
- does not own mutable DraftWorkspace state;
- does not build RegistryGraph or derive RegistryDependency.

No independent persistence boundary exists for:

- RegistryGraph;
- RegistryDependency;
- reverse traversal;
- relation indexes;
- ImpactAnalysisResult;
- ValidationResult;
- RiskAssessment;
- PublishingGateDecision;
- PublicationAttempt.

RegistryGraph, RegistryDependency, traversal and indexes are derived projections for one exact Registry or DraftWorkspace revision.

ImpactAnalysisResult, ValidationResult, RiskAssessment, PublishingGateDecision and PublicationAttempt remain RegistryTransaction-owned evidence. They must not become independent aggregates or repositories.

Publication atomicity:

- one invocation of PublishRegistryRevision is the single atomic application boundary for publication;
- PublishRegistryRevision is an application use case, not a new domain object, repository or persistence wrapper;
- it coordinates RegistryRepository, DraftWorkspaceRepository and RegistryGovernanceRepository according to their independent ownership contracts;
- every publication write across those contracts must participate in one native all-or-nothing storage write scope;
- repositories must not expose begin, commit or rollback methods, technical transaction wrappers or staged mutable write state;
- a publication-capable storage implementation must atomically persist the published Registry revision, resulting RegistrySnapshot, RegistryTransaction and PublicationAttempt outcome, AuditLog records and PUBLISHING_DRAFT CLEAN transition;
- publication must verify the expected source Registry revision and fingerprint before applying changes;
- a storage implementation that cannot provide all-or-nothing publication is not publication-capable.

No composite RegistryRepository, PublicationCommitPort, SnapshotRepository or technical transaction wrapper is introduced.

###### 3. RegistryEntityKind and RegistryEntityPayload Boundary

Registry Studio Core retains only:

- RegistryEntityKind extension contract;
- RegistryEntityPayload extension contract;
- typed payload requirement;
- prohibition of untyped dynamic payloads;
- analysis and validation support for adapter-defined kinds and payloads.

Concrete RegistryEntityKind values belong to project adapters.

The current Helpy semantic kinds must move to Helpy adapter ownership, including:

- contract;
- architectureGroup;
- rootCategory;
- category;
- subcategory;
- scenario;
- section;
- clientRule;
- masterRule;
- scenarioRule;
- globalRule;
- platformRule;
- eligibilityRule;
- dependencyRule;
- translationRule;
- question;
- answerOption;
- structuredScope;
- photoRequirement;
- photoLimit;
- pricingRule;
- guidance;
- guidanceTrigger;
- guidanceSlot;
- adminDependency.

The following items must be removed from RegistryEntityKind taxonomy because they are not Registry content:

- draft;
- publishedRevision;
- changeSet;
- transaction;
- impactAnalysis;
- dependencyAnalysis;
- riskClassification;
- validationResult;
- healthCheck;
- auditLog;
- rollback;
- snapshot;
- featureFlag;
- platformSetting;
- builder;
- workflow;
- review.

The corresponding concrete Helpy payload schemas must move to Helpy adapter ownership.

The following items must be removed from RegistryEntityPayload taxonomy because they are governance records, analysis results, application capabilities, runtime contracts or UI concepts:

- DraftPayload;
- PublishedRevisionPayload;
- ChangeSetPayload;
- TransactionPayload;
- ImpactAnalysisPayload;
- DependencyAnalysisPayload;
- RiskClassificationPayload;
- ValidationResultPayload;
- HealthCheckPayload;
- AuditLogPayload;
- RollbackPayload;
- SnapshotPayload;
- FeatureFlagPayload;
- PlatformSettingPayload;
- BuilderPayload;
- WorkflowPayload;
- ReviewPayload.

Adapter provenance must be preserved for any snapshot, analysis, validation or audit evidence through:

- adapter identity;
- adapter semantic-contract version;
- RegistryEntityKind schema version;
- RegistryEntityPayload schema version.

###### 4. Governance Core Decisions

| Object | Decision | Canonical owner |
|---|---|---|
| RegistryTransaction | retain | Governed change lifecycle |
| DraftWorkspace | retain / tighten | Draft state, work context and DIRTY / CLEAN state |
| RegistrySnapshot | retain / reclassify | Immutable verified revision evidence |
| AuditLog | retain / reclassify | Append-only immutable audit records |
| TransactionPayload | remove from Domain | Data/API mapping boundary only |
| SnapshotPayload | remove from Domain | Data/API mapping boundary only |
| RollbackPayload | remove from Domain | Data/API mapping boundary only |
| PublicationResult | remove as standalone model | Replaced by transaction-owned PublicationAttempt |
| Rollback | reclassify | Governed recovery operation through a new RegistryTransaction |

DraftWorkspace:

- is retained as the common isolated workspace aggregate;
- has exactly one workspace purpose:
  - PUBLISHING_DRAFT;
  - SANDBOX;
- references one source RegistrySnapshot;
- owns its current isolated workspace revision and fingerprint;
- preserves resumable engineering work context;
- may be discarded without affecting Published Registry;
- must not own RegistryTransaction lifecycle;
- must not own validation lifecycle;
- must not own publication lifecycle.

PUBLISHING_DRAFT workspace:

- prepares Registry changes intended for publication;
- has exactly one active RegistryTransaction;
- owns mutable draft revision and draft fingerprint;
- owns DIRTY and CLEAN state;
- may request ImpactAnalysis, Validation, RiskAssessment and PublishingGate evidence;
- is the only workspace purpose permitted to enter publication governance.

SANDBOX workspace:

- owns isolated experimental revision;
- has no RegistryTransaction;
- must not invoke PublishingGate or publication;
- may run deterministic simulation, analysis and validation experiments;
- produces informational experimental results only;
- must not treat experimental evidence as publication evidence;
- may be discarded without affecting any PUBLISHING_DRAFT workspace or Published Registry.

Sandbox promotion:

- does not convert an existing SANDBOX workspace into PUBLISHING_DRAFT;
- creates a new PUBLISHING_DRAFT DraftWorkspace seeded from the exact sandbox revision and fingerprint;
- creates a new RegistryTransaction;
- requires fresh ImpactAnalysis, Validation, RiskAssessment and PublishingGate evidence;
- may preserve sandbox results only as engineering context and audit references.

The separate SandboxMode model must be removed during controlled contract rewrite.

RegistryTransaction:

- is the only governed lifecycle owner for one Registry modification;
- preserves analysis, validation, approval and publication evidence;
- preserves transaction outcome;
- preserves audit references;
- originates from DraftWorkspace;
- must not own DraftWorkspace DIRTY / CLEAN state;
- must not finish in CLEAN state;
- must not change the historical outcome of an already published transaction.

The current rollback-specific RegistryTransaction states must be removed:

- ROLLBACK_PREPARED;
- ROLLED_BACK.

###### 5. Draft Revision Invalidation Rule

Every DraftWorkspace modification creates a new draft revision.

ImpactAnalysisResult, ValidationResult, derived RiskAssessment and PublishingGateDecision are valid only for the exact draft revision and source RegistrySnapshot used to produce them.

After any DraftWorkspace modification:

- previous ImpactAnalysisResult becomes stale;
- previous ValidationResult becomes stale;
- previous RiskAssessment becomes stale;
- previous PublishingGateDecision becomes stale;
- publication is prohibited until current revision evidence is recomputed.

###### 6. RegistrySnapshot and Revision Ownership

RegistrySnapshot:

- is an immutable governance record for one exact verified Registry revision;
- has independent snapshot identity;
- is not a storage backup;
- is not a second editable Registry source of truth;
- is not a RegistryEntity;
- is not a RegistryGraph node;
- has no separate Domain payload model;
- pins semantic state required to compare history, explain impact, preserve audit evidence and prepare governed recovery.

RegistrySnapshot must contain:

- snapshot identity;
- Registry identity;
- snapshot revision reference;
- deterministic semantic fingerprint;
- creation timestamp;
- creation reason;
- adapter identity;
- adapter semantic-contract version;
- RegistryEntityKind and RegistryEntityPayload schema versions required to interpret pinned semantic state;
- exact pinned canonical semantic state composed of RegistryEntity identity, adapter-defined kind, typed semantic content, RegistryPath and RegistryRelation;
- immutable verification or publication evidence references when applicable.

RegistrySnapshot must not own as canonical snapshot state:

- RegistryGraph;
- RegistryDependency;
- ValidationResult state;
- RiskAssessment;
- DraftWorkspace DIRTY / CLEAN state;
- AuditLog contents;
- runtime state.

Entity indexes and relation indexes may exist only as pinned or reproducible materialized lookup representations of snapshot semantic state. They must not become independently editable semantic truth.

RegistryDependency is always derived for the exact RegistrySnapshot revision and adapter semantic-contract version. It must not be stored as canonical Snapshot state.

ValidationResult is immutable evidence for a specific verification run. A RegistrySnapshot may reference such evidence when applicable, but must not own current validation state.

Snapshot lifecycle:

- source RegistrySnapshot must exist before DraftWorkspace begins mutable change preparation;
- DraftWorkspace owns mutable draft revision and draft fingerprint;
- successful publication creates resulting RegistrySnapshot for the new published semantic state;
- failed, blocked or cancelled publication does not create resulting published RegistrySnapshot;
- DraftWorkspace owns CLEAN verification;
- RegistrySnapshot provides immutable source and resulting state evidence only.

RegistrySnapshot comparison must expose changed, added, removed and affected RegistryEntity objects, RegistryPath values and RegistryRelation records through pinned semantic state.

###### 7. Analysis, Validation and Publication Decisions

| Object | Decision | Canonical role |
|---|---|---|
| Engineering Change Analysis | reclassify | Application use case |
| ImpactAnalysis | retain / reclassify | Immutable assessment of one draft revision |
| Validation | reclassify | Validation policy/service |
| ValidationResult | retain as result value | Transaction-owned verification evidence |
| RiskClassification | merge | Derived part of ImpactAnalysisResult |
| PublishingGate | reclassify | Pure governance policy |
| PublishingGateDecision | retain as result value | Decision for one current draft revision |
| PublicationResult | remove standalone | Replaced by PublicationAttempt |

Canonical flow:

DraftWorkspace revision
→ Engineering Change Analysis
→ ImpactAnalysisResult
→ ValidationResult
→ derived RiskAssessment
→ PublishingGateDecision
→ PublicationAttempt
→ Audit records

Engineering Change Analysis:

- is an application use case;
- collects verified context;
- creates explainable impact evidence;
- is not a RegistryEntity;
- is not a RegistryEntityPayload;
- is not a persistent lifecycle owner.

ImpactAnalysisResult:

- belongs to one RegistryTransaction;
- belongs to one exact DraftWorkspace revision;
- references one source RegistrySnapshot;
- identifies direct and indirect affected entities;
- identifies relation and dependency paths;
- exposes why each affected item is included;
- distinguishes confirmed impact from semantic candidates and informational matches;
- does not become a RegistryEntity;
- does not require a separate RegistryEntityPayload model.

Validation:

- is a deterministic policy/service;
- validates one exact DraftWorkspace revision;
- may execute adapter-defined validation extensions;
- must remain storage independent.

ValidationResult:

- is immutable verification evidence;
- belongs to one RegistryTransaction and draft revision;
- becomes stale after DraftWorkspace modification;
- identifies affected entities and paths when validation fails or blocks publication.

RiskAssessment:

- is derived from current ImpactAnalysisResult and ValidationResult;
- is advisory evidence for engineer decision-making;
- is not a standalone RegistryEntity;
- is not persistent dependency state;
- must not duplicate a separate RiskClassification model.

The duplicate standalone Risk Classification section must be removed during contract consolidation.

PublishingGate:

- is a pure governance policy;
- does not own lifecycle state;
- does not modify Registry;
- evaluates only current non-stale evidence;
- verifies that no newer unvalidated draft revision exists;
- returns PublishingGateDecision.

Blocking invariant:

- risk is advisory;
- failed validation, unresolved hard dependency or missing required approval is blocking;
- blocking conditions cannot be bypassed by ordinary advisory review.

###### 8. PublicationAttempt and Recovery

RegistryTransaction owns PublicationAttempt records.

PublicationAttempt contains:

- current draft revision;
- source RegistrySnapshot;
- PublishingGateDecision reference;
- before publication snapshot;
- after publication snapshot when applied;
- publication outcome;
- cancellation or failure reason when applicable;
- audit references.

Publication blocking remains a PublishingGateDecision outcome. A blocked gate decision is not a completed publication attempt.

Rollback is a governed recovery operation, not a parallel aggregate.

Canonical recovery flow:

Published RegistryTransaction A
→ recovery request
→ new RegistryTransaction B
→ analysis
→ validation
→ engineer approval
→ publication

Recovery RegistryTransaction B references:

- source RegistryTransaction A;
- target verified RegistrySnapshot;
- recovery reason;
- current evidence;
- publication attempt;
- audit records.

RegistryTransaction A remains historically PUBLISHED.

###### 9. Audit Log Decision

AuditLog is an append-only immutable audit-record stream.

Each audit record has independent identity and contains:

- actor;
- action;
- timestamp;
- immutable event summary;
- stable references;
- affected RegistryEntity and RegistryPath references;
- RegistryTransaction reference when applicable;
- DraftWorkspace reference when applicable;
- RegistrySnapshot reference when applicable.

Audit records may reference ImpactAnalysisResult, ValidationResult, PublishingGateDecision, PublicationAttempt and recovery transaction evidence.

AuditLog must not duplicate full mutable governance state from these owners.

###### 10. Relation and Dependency Semantics

RegistryRelation:

- is a canonical directed semantic edge between exactly two RegistryEntity objects;
- belongs to Registry state;
- changes only through DraftWorkspace and RegistryTransaction;
- participates in RegistryGraph;
- has no separate RegistryEntityPayload;
- must be derived from approved semantic contracts, not Markdown hierarchy alone.

Only one canonical directed RegistryRelation record may be persisted for one semantic fact.

Reverse traversal, inverse display labels and reverse dependency navigation must be derived by RegistryGraph. They must not create a second persisted semantic fact.

Registry Studio Core does not own a closed enumeration of concrete RegistryRelation kinds.

Core provides:

- source and target RegistryEntity identity;
- one canonical directed semantic edge;
- deterministic relation identity;
- adapter-defined typed qualifiers when required;
- deterministic forward and reverse traversal;
- path provenance and explainable graph traversal;
- inverse derivation without persisted duplicate edges;
- cycle detection.

Each project adapter must define for every concrete relation kind:

- stable kind identifier;
- adapter semantic-contract version;
- semantic meaning;
- qualifier schema when required;
- impact propagation behavior;
- validation constraints;
- cycle policy;
- inverse and display interpretation when required.

No pair of inverse adapter labels may be persisted as separate RegistryRelation records for the same semantic fact.

Relation labels such as contains, references, inherits, overrides, belongsTo, bindsTo, extends, specializes, triggers, follows and precedes may exist as adapter-defined semantics only. They are not a closed Registry Studio Core enum.

RegistryDependency:

- is a derived explainable impact edge;
- is built from RegistryRelation and adapter-defined semantic rules;
- is not independently editable Registry content;
- is not a RegistryEntity;
- has no separate RegistryEntityPayload;
- must preserve provenance.

RegistryDependency must not own:

- risk state;
- validation state;
- publication state.

These belong to current transaction evidence.

Dependency result categories:

1. Direct confirmed dependency.
2. Indirect impact through confirmed relation/dependency paths.
3. Semantic candidate requiring engineer decision.
4. Informational text match without confirmed semantic relation.

Only direct confirmed dependencies and indirect impacts enter deterministic impact scope automatically.

Cycle rules:

- each project adapter must declare cycle policy for every concrete RegistryRelation kind;
- cycle policy must state whether a cycle is prohibited, allowed or allowed only with explicit traversal constraints;
- Validation must enforce declared adapter cycle policy for the exact Registry revision;
- RegistryGraph must detect cycles, stop traversal deterministically when a configured traversal reaches a cycle and explain the complete path.

###### 11. Application Service Decisions

| Object | Decision | Canonical role |
|---|---|---|
| DependencyExplorer | retain / reclassify | Read-only graph traversal service |
| RulesSimulator | retain / reclassify | Universal Core simulation capability with adapter-defined simulation contracts |
| BulkOperations | reclassify | Deterministic change-plan application service |
| GlobalRename | reclassify | Semantic bulk-refactoring operation |
| RegistryCoverage | move to project adapter | Adapter-defined completeness checks |
| SandboxMode | merge | DraftWorkspace purpose; not a separate model or lifecycle owner |

BulkOperations:

- prepares and applies approved deterministic change plans inside DraftWorkspace;
- must not own transaction lifecycle;
- must not directly own analysis, validation, gate or audit lifecycle;
- must preserve transaction atomicity through governance flow.

GlobalRename:

- is not text replacement;
- is a semantic bulk refactoring operation;
- must preserve immutable RegistryEntity identity;
- may change display name, semantic key, RegistryPath segment, canonical label and semantic references;
- must not modify Published Registry directly.

RegistryCoverage must move to project adapter because category, question, photo, pricing, guidance and eligibility completeness are not generic Registry Studio Core concepts.


RulesSimulator:

- is a universal Core application capability for deterministic non-mutating behavior simulation;
- is not a RegistryEntity;
- is not a RegistryEntityPayload;
- is not a lifecycle aggregate;
- is not a publication authority;
- is not merged with ImpactAnalysis;
- executes against one exact published RegistrySnapshot, PUBLISHING_DRAFT workspace revision or SANDBOX workspace revision;
- preserves source Registry identity, revision reference, fingerprint, adapter identity and adapter semantic-contract version;
- accepts typed adapter-defined hypothetical scenario input;
- returns typed adapter-defined simulation output with an explainable execution trace;
- must remain independent of project-specific business terms, storage representation and UI implementation;
- must not modify Registry, DraftWorkspace or RegistryTransaction;
- must not create ValidationResult, RiskAssessment or PublishingGateDecision;
- must not automatically create publication evidence.

RulesSimulator and ImpactAnalysis have distinct responsibilities:

- ImpactAnalysis explains what Registry entities, relations and dependencies are affected by a proposed change.
- RulesSimulator evaluates what adapter-defined behavior results from one hypothetical scenario against one exact Registry revision.

Project adapters define:

- scenario input semantics;
- evaluator bindings;
- output semantics;
- behavior trace interpretation;
- UI preview bindings;
- adapter-specific simulation constraints.

A project validation extension may invoke RulesSimulator and include its trace in ValidationResult evidence. The evidence is then owned by Validation, not by RulesSimulator.

The legacy Rules Simulator Model must be rewritten during controlled contract correction.

###### 12. Runtime Decisions

| Object | Decision | Canonical role |
|---|---|---|
| EngineeringContext | retain / reclassify | Read-only provider of verified base Registry context |
| EngineerIntent | retain | Runtime input |
| EngineeringWorkflowResolver | retain | Workflow resolution application service |
| EngineeringWorkflowResolutionResult | retain | Typed resolution result |
| EngineeringOrchestrator | retain / narrow | Workflow run coordinator |
| EngineeringExecutionContext | merge | Into EngineeringWorkflowInstance |
| EngineeringWorkflow | reclassify | Core workflow contract; concrete definitions belong to project adapters |
| EngineeringWorkflowInstance | retain | Runtime aggregate for one workflow run |
| EngineeringOperation | merge | WorkflowStepDefinition |
| EngineeringOperationInstance | merge | WorkflowStepExecution |
| EngineeringServiceContract | retain / reclassify | Typed handler boundary |
| EngineeringServiceContractPayload | remove | Redundant wrapper |
| EngineeringServiceInput / Output / Failure | retain | Typed execution values |
| EngineeringService | reclassify | Application handler implementation |
| EngineeringServiceCapabilityRegistry | reclassify / rename | EngineeringServiceCapabilityCatalog: immutable versioned runtime composition catalog |

EngineeringServiceCapabilityCatalog:

- is an immutable versioned runtime composition catalog;
- is created and validated during platform and active project-adapter composition before any workflow is resolved or executed;
- accepts only declared approved EngineeringServiceContract bindings from platform and adapter composition;
- validates that every executable WorkflowStepDefinition admitted into the active runtime resolves to exactly one approved typed handler binding;
- provides deterministic resolution only for a declared typed EngineeringServiceContract required by workflow execution;
- preserves composition fingerprint, contract identity, contract semantic version and binding provenance;
- remains immutable for the lifetime of its active runtime composition;
- allows platform or adapter extensions to contribute bindings only before catalog validation;
- does not execute handler logic;
- does not select workflows;
- does not coordinate workflow execution;
- does not modify Registry, DraftWorkspace or RegistryTransaction;
- is not a RegistryEntity;
- has no RegistryEntityPayload;
- has no persistent capability state;
- is not a generic service locator;
- does not expose arbitrary service lookup or implementation details;
- does not own mutable capability availability.

Runtime dependency unavailability belongs to typed handler preconditions and EngineeringServiceFailure. It is not catalog state.

Handler replacement creates a new validated runtime composition. It may preserve the approved EngineeringServiceContract without requiring workflow redesign. A changed contract requires a separately approved contract and semantic version.

EngineeringWorkflowInstance must preserve the active composition fingerprint as run-level runtime evidence. Each WorkflowStepExecution must preserve its resolved EngineeringServiceContract identity and handler binding provenance. A resumable step must not execute automatically when its previously resolved binding provenance has changed; it must stop for engineer decision.

EngineeringContext:

- provides only verified base Registry context;
- may use Registry, RegistryPath, RegistryRelation, RegistryDependency, RegistryGraph and RegistrySnapshot;
- must not depend on ImpactAnalysis, Validation, RegistryCoverage or PublishingGate as input dependencies;
- must not define publication readiness.

EngineerIntent:

- expresses engineer objective, target, scope and explicit constraints;
- does not select workflow;
- does not execute workflow;
- does not modify Registry;
- is not Published Registry data.

EngineeringWorkflowResolver:

- proposes one eligible approved workflow only when resolution is unambiguous;
- explains resolution, ambiguity, unsupported intent or blocking reason;
- does not execute workflow;
- does not create workflow instances;
- does not replace engineer decision.

Engineer confirmation is required after workflow resolution and before runtime execution begins.

EngineeringWorkflowInstance owns:

- runtime lifecycle;
- active runtime composition fingerprint;
- current step;
- WorkflowStepExecution records;
- intermediate result references;
- engineer decision points;
- failure, resume and completion state;
- RegistryTransaction reference when Registry modification exists;
- runtime audit references.

Each WorkflowStepExecution preserves its resolved EngineeringServiceContract identity and handler binding provenance.

EngineeringExecutionContext must merge into EngineeringWorkflowInstance. It must not remain as a second lifecycle and state owner.

EngineeringOperation must merge into WorkflowStepDefinition because it belongs to exactly one EngineeringWorkflow definition.

EngineeringOperationInstance must merge into WorkflowStepExecution because it is execution evidence inside one EngineeringWorkflowInstance.

Canonical runtime flow:

EngineerIntent
→ EngineeringContext
→ EngineeringWorkflowResolver
→ engineer confirmation
→ EngineeringWorkflowInstance
   └─ WorkflowStepExecution[]
       → required EngineeringServiceContract
       → EngineeringServiceCapabilityCatalog
       → resolved approved handler binding
       → EngineeringService
→ DraftWorkspace
→ RegistryTransaction
→ analysis / validation / publishing / audit

EngineeringOrchestrator:

- coordinates confirmed workflow execution;
- advances WorkflowStepExecution sequence;
- enforces stop conditions;
- stops for engineer decisions;
- resolves the required typed handler contract through EngineeringServiceCapabilityCatalog and delegates a step through the resolved approved binding;
- transitions Registry modification work through DraftWorkspace governance boundary;
- must not directly depend on BulkOperations, GlobalRename, RulesSimulator, ImpactAnalysis, Validation, RegistryCoverage, PublishingGate or AuditLog implementations;
- must not create RegistryTransaction outside DraftWorkspace boundary.

EngineeringServiceContractPayload must be removed because typed EngineeringServiceInput, EngineeringServiceOutput and EngineeringServiceFailure already define the required service boundary.

The legacy dynamic EngineeringServiceCapabilityRegistry model must be replaced by EngineeringServiceCapabilityCatalog during controlled contract correction.

###### 13. Helpy Adapter Decisions

The following remain required Helpy adapter capabilities:

- Category Health Check;
- Helpy RegistryCoverage rules;
- category, subcategory, question, photo, pricing and guidance completeness;
- master eligibility checks;
- launch checks;
- canonical RU / EN / TH formulation semantics;
- translation semantics;
- Helpy-specific RegistryEntityKind values;
- Helpy-specific RegistryEntityPayload schemas;
- Helpy-specific relation and dependency semantics;
- Helpy simulation scenario semantics, evaluator bindings, behavior traces and preview bindings;
- Helpy workflow definitions;
- Helpy guidance and platform metadata.

Category Health Check remains a required Helpy publishing gate extension. It is not Registry Studio Core model or RegistryEntityKind.

###### 14. Deferred Future Expansion

No unresolved Core architecture decision remains in this audit baseline.

Dynamic capability lifecycle is explicitly deferred. It may be modeled only after an approved evidence-backed scenario requires handler installation, removal, activation, deactivation or replacement without creating a new runtime composition.

###### 15. Controlled Rewrite Scope

The following Registry Studio blocks must be rewritten as one coordinated architecture correction:

- RegistryTransaction and TransactionPayload;
- Registry Studio Domain Model and RegistryEntityKind;
- RegistrySnapshot and RegistryEntityPayload taxonomy;
- RegistryRelation, RegistryDependency, RegistryGraph and repository boundary contracts;
- Engineering Change Analysis, ImpactAnalysis, Validation, RiskClassification, PublishingGate, PublicationResult and Rollback;
- DraftWorkspace and AuditLog;
- BulkOperations, GlobalRename, RulesSimulator, RegistryCoverage and SandboxMode;
- Engineering Context, Engineering Runtime and EngineeringServiceCapabilityRegistry legacy model;
- duplicated Risk Classification section.

No implementation may begin from a legacy contract block until its corresponding correction is completed.


##### Dependency Explorer Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

DependencyExplorer is a read-only graph traversal service for one exact
published Registry revision or DraftWorkspace revision.

DependencyExplorer:

- derives traversal from RegistryGraph, RegistryRelation, RegistryDependency,
  RegistryPath and adapter-defined semantic rules;
- supports deterministic forward and reverse traversal;
- exposes direct confirmed dependencies, indirect impact paths, semantic
  candidates and informational text matches distinctly;
- exposes relation and path provenance for every traversal result;
- detects configured traversal cycles and explains the full cycle path;
- supports engineering navigation, context reconstruction, impact analysis,
  validation and semantic refactoring;
- does not modify Registry, DraftWorkspace or RegistryTransaction;
- does not create independent dependency state;
- remains storage independent.

DependencyExplorer is not a generic text search engine.

##### Rules Simulator Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

RulesSimulator is a universal Core application capability for deterministic
non-mutating behavior simulation.

RulesSimulator:

- is not a RegistryEntity;
- is not a RegistryEntityPayload;
- is not a lifecycle aggregate;
- is not a publication authority;
- is not merged with ImpactAnalysis;
- executes against one exact published RegistrySnapshot, PUBLISHING_DRAFT
  workspace revision or SANDBOX workspace revision;
- preserves Registry identity, revision reference, fingerprint, adapter
  identity and adapter semantic-contract version;
- accepts typed adapter-defined hypothetical scenario input;
- returns typed adapter-defined simulation output with an explainable
  execution trace;
- remains independent of project-specific business terms, storage
  representation and UI implementation;
- must not modify Registry, DraftWorkspace or RegistryTransaction;
- must not create ValidationResult, RiskAssessment or PublishingGateDecision;
- must not automatically create publication evidence.

ImpactAnalysis explains affected Registry entities, relations and dependencies
for a proposed change.

RulesSimulator evaluates adapter-defined behavior for one hypothetical scenario
against one exact Registry revision.

Project adapters define scenario input semantics, evaluator bindings, output
semantics, behavior trace interpretation, preview bindings and adapter-specific
simulation constraints.

A validation extension may invoke RulesSimulator and include its trace in
ValidationResult evidence. The resulting evidence remains owned by Validation.

##### Helpy Registry Coverage Extension

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

RegistryCoverage is not a Registry Studio Core model.

Helpy RegistryCoverage is an adapter-defined completeness capability for Helpy
semantic contracts and launch readiness.

Helpy RegistryCoverage may evaluate:

- category and subcategory completeness;
- question, answer option and structured-scope completeness;
- photo, pricing, guidance and eligibility completeness;
- canonical RU / EN / TH formulation coverage;
- translation semantics;
- category health and launch readiness;
- Helpy-specific relation, dependency and workflow completeness.

Helpy RegistryCoverage:

- operates on one exact Registry or DraftWorkspace revision;
- remains distinct from Validation;
- must not modify Registry directly;
- must produce explainable adapter-defined findings;
- may participate in the required Helpy Category Health Check publishing-gate
  extension;
- must not become Registry Studio Core taxonomy, payload or persistence state.

No separate SandboxMode model exists.

SANDBOX behavior is owned exclusively by DraftWorkspace purpose and follows
the SANDBOX contract defined by Draft Workspace Model.

##### Engineering Context Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringContext is a read-only provider of verified base Registry context
for one exact Registry state.

EngineeringContext обязан показывать инженеру полный read-only контекст целевой RegistryEntity из RegistryEntityPayload:

```text
Entity
→ Scenario
  → Scenario Entry Evidence
  → Questions
  → Photo Questions
  → Photo Limits
  → Client Guidance
  → Master Guidance
```

Каждый Scenario рассматривается отдельно. У разных Scenario могут быть
разные Questions, Photo Questions, Photo Limits, Client Guidance и
Master Guidance.

Client Guidance и Master Guidance являются role-specific подсказками
экранов для конкретного Scenario.

EngineeringContext не создаёт отдельный RegistryEntityReviewContext,
ReviewContent или параллельный payload. Он использует существующих владельцев
ответственности: RegistryEntity, RegistryEntityPayload, SourceEvidence,
RegistryRelation, RegistryDependency, RegistryGraph и RegistrySnapshot.

EngineeringContext may derive verified context from Registry, RegistryPath,
RegistryRelation, RegistryDependency, RegistryGraph and RegistrySnapshot.

EngineeringContext:

- reconstructs only verified base Registry context;
- identifies related entities, inherited semantic rules, confirmed dependencies
  and applicable constraints;
- distinguishes verified Registry data from inferred information;
- remains deterministic and storage independent;
- does not modify Registry, DraftWorkspace or RegistryTransaction;
- does not define publication readiness;
- does not depend on ImpactAnalysis, Validation, Helpy RegistryCoverage or
  PublishingGate as input dependencies.

EngineeringContext is not a search engine, publication authority or workflow
lifecycle owner.

##### Engineer Intent Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineerIntent is the runtime input that expresses an engineer objective,
target, scope and explicit constraints.

EngineerIntent:

- may identify a target RegistryEntity or RegistryPath;
- preserves explicit engineering scope and constraints;
- provides input to EngineeringWorkflowResolver;
- does not select a workflow;
- does not execute a workflow;
- does not modify Registry;
- is not Published Registry data;
- remains independent of storage implementation.

##### Engineering Workflow Resolver Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringWorkflowResolver is an application service that evaluates one
EngineerIntent against verified EngineeringContext and active approved workflow
definitions.

EngineeringWorkflowResolver:

- proposes exactly one eligible approved workflow only when resolution is
  unambiguous;
- returns a typed resolution result with RESOLVED, AMBIGUOUS, UNSUPPORTED,
  BLOCKED or FAILED outcome;
- explains selected workflow, ambiguity, unsupported intent or blocking reason;
- does not execute workflow logic;
- does not create EngineeringWorkflowInstance;
- does not create DraftWorkspace or RegistryTransaction;
- does not replace engineer decision.

Engineer confirmation is required after RESOLVED workflow selection and before
runtime execution begins.

##### Engineering Orchestrator Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringOrchestrator is the narrow coordinator of confirmed
EngineeringWorkflowInstance execution.

EngineeringOrchestrator ownership boundary:

EngineeringOrchestrator не заменяет EngineeringOperation и не владеет
workflow step definition, runtime step state, typed handler contract,
service handler execution или service capability resolution.

Эти ответственности остаются у WorkflowStepDefinition,
WorkflowStepExecution, EngineeringServiceContract и
EngineeringServiceCapabilityCatalog.

EngineeringOrchestrator:

- starts one confirmed EngineeringWorkflowInstance;
- advances the declared WorkflowStepExecution sequence;
- enforces workflow and step stop conditions;
- stops for required engineer decisions;
- resolves the required typed EngineeringServiceContract through
  EngineeringServiceCapabilityCatalog;
- delegates a step only through the resolved approved handler binding;
- transitions Registry modification work through the DraftWorkspace governance
  boundary;
- must not create RegistryTransaction outside DraftWorkspace boundary;
- remains independent of storage implementation.

EngineeringOrchestrator must not:

- implement handler logic;
- define workflow or step semantics;
- directly depend on BulkOperations, GlobalRename, RulesSimulator,
  ImpactAnalysis, Validation, Helpy RegistryCoverage, PublishingGate or AuditLog
  implementations;
- modify Published Registry directly;
- replace engineer decisions.

##### Engineering Workflow Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringWorkflow is a Core runtime workflow contract. Concrete workflow
definitions belong to the active project adapter.

EngineeringWorkflow defines deterministic execution order, workflow-level stop,
resume and completion conditions, and required engineer decision points.

Each executable workflow contains WorkflowStepDefinition records.

WorkflowStepDefinition:

- belongs to exactly one EngineeringWorkflow definition;
- defines one ordered executable workflow step;
- declares exactly one required typed EngineeringServiceContract;
- defines typed input, expected output, typed failure handling, preconditions,
  stop conditions and engineer confirmation requirements;
- does not execute handler logic;
- does not coordinate workflow execution;
- does not modify Registry directly.

EngineeringWorkflow is not a RegistryEntity, a DraftWorkspace, a
RegistryTransaction or an executable handler.

##### Engineering Workflow Instance Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringWorkflowInstance is the runtime aggregate for one confirmed
EngineeringWorkflow execution.

EngineeringWorkflowInstance owns:

- runtime lifecycle;
- active EngineeringWorkflow definition reference;
- active runtime composition fingerprint;
- current execution position;
- WorkflowStepExecution records;
- intermediate result references;
- engineer decision points;
- failure, resume and completion state;
- RegistryTransaction reference when Registry modification exists;
- runtime audit references.

EngineeringExecutionContext merges into EngineeringWorkflowInstance. No second
runtime lifecycle or mutable state owner exists.

WorkflowStepExecution is execution evidence for one WorkflowStepDefinition. It
preserves:

- step identity and execution position;
- resolved typed EngineeringServiceContract identity and semantic version;
- resolved handler binding provenance;
- typed input, output or failure value;
- engineer confirmation state;
- stop, resume and completion state.

A resumable WorkflowStepExecution must not continue automatically when its
previously resolved handler binding provenance changed. It must stop for an
engineer decision.

##### Engineering Service Contract Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringServiceContract is the typed handler boundary required by a
WorkflowStepDefinition.

EngineeringServiceContract defines:

- stable contract identity and semantic version;
- typed EngineeringServiceInput;
- typed EngineeringServiceOutput;
- typed EngineeringServiceFailure;
- handler preconditions;
- handler failure semantics;
- declared traceability requirements.

EngineeringServiceContract:

- is not an executable handler;
- does not coordinate workflow execution;
- does not modify Registry directly;
- does not expose untyped dynamic or generic Map payloads;
- does not become a universal engineering utility contract.

No EngineeringServiceContractPayload model exists. Typed
EngineeringServiceInput, EngineeringServiceOutput and EngineeringServiceFailure
are the complete execution value boundary.

##### Engineering Service Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringService is an application handler implementation invoked through
one resolved approved EngineeringServiceCapabilityCatalog binding.

EngineeringService:

- receives only typed EngineeringServiceInput;
- returns only typed EngineeringServiceOutput or EngineeringServiceFailure;
- executes only the capability defined by the resolved approved
  EngineeringServiceContract;
- validates handler preconditions before execution;
- exposes failure through typed failure values;
- does not select workflows;
- does not coordinate workflow execution;
- does not call EngineeringOrchestrator;
- does not modify Published Registry directly;
- must route Registry modification work through DraftWorkspace governance.

Handler unavailability is a handler precondition and typed
EngineeringServiceFailure. It is not mutable catalog state.

##### Engineering Service Capability Catalog Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringServiceCapabilityCatalog is an immutable versioned runtime
composition catalog.

EngineeringServiceCapabilityCatalog:

- is created and validated during platform and active project-adapter
  composition before any workflow is resolved or executed;
- accepts only declared approved EngineeringServiceContract bindings from
  platform and adapter composition;
- validates that every executable WorkflowStepDefinition admitted into the
  active runtime resolves to exactly one approved typed handler binding;
- resolves only a declared typed EngineeringServiceContract required by workflow
  execution;
- preserves composition fingerprint, contract identity, contract semantic
  version and handler binding provenance;
- remains immutable for the lifetime of active runtime composition;
- allows platform or adapter extensions to contribute bindings only before
  catalog validation;
- does not execute handler logic;
- does not select workflows;
- does not coordinate workflow execution;
- does not modify Registry, DraftWorkspace or RegistryTransaction;
- is not a RegistryEntity;
- has no RegistryEntityPayload;
- has no persistent capability state;
- is not a generic service locator;
- does not expose arbitrary handler lookup or implementation details;
- does not own mutable capability availability.

Handler replacement creates a new validated runtime composition. A replacement
may preserve an approved contract; a changed contract requires a separately
approved semantic version.

##### Engineering Runtime Model

Status: APPROVED — CONTROLLED CONTRACT CORRECTION

EngineeringRuntime defines the canonical execution chain for Registry
engineering.

Canonical runtime flow:

EngineerIntent
→ EngineeringContext
→ EngineeringWorkflowResolver
→ engineer confirmation
→ EngineeringWorkflowInstance
   └─ WorkflowStepExecution[]
       → required EngineeringServiceContract
       → EngineeringServiceCapabilityCatalog
       → resolved approved handler binding
       → EngineeringService
→ DraftWorkspace
→ RegistryTransaction
→ analysis / validation / publishing / audit

Responsibility separation:

- EngineerIntent expresses objective, target, scope and constraints.
- EngineeringContext provides verified base Registry context.
- EngineeringWorkflowResolver proposes an eligible workflow.
- Engineer confirmation authorizes runtime execution.
- EngineeringWorkflowInstance owns one runtime execution and absorbed
  EngineeringExecutionContext state.
- WorkflowStepExecution preserves step-level execution evidence.
- EngineeringOrchestrator coordinates confirmed execution without implementing
  handler logic.
- EngineeringServiceCapabilityCatalog resolves declared approved typed handler
  bindings from immutable active runtime composition.
- EngineeringService executes one resolved typed handler capability.
- DraftWorkspace is the required mutable Registry modification boundary.
- RegistryTransaction governs publication evidence and outcome.
- Analysis, validation, publishing and audit follow governance contracts.

Every runtime component has exactly one architectural responsibility.
Published Registry may change only through successful governed publication.
##### Registry Studio Development Phases

Status: APPROVED

Registry Studio development is divided into architectural phases to preserve navigation, context and design intent.

Phase 1: Registry Foundation
- Registry domain model;
- Registry entities;
- entity kinds;
- typed payloads;
- paths;
- relations;
- dependencies;
- snapshots;
- graph model;
- repository boundary.

Phase 2: Engineering Governance
- Registry transactions;
- DraftWorkspace purposes: PUBLISHING_DRAFT and SANDBOX;
- Impact Analysis;
- Validation;
- derived RiskAssessment;
- Publishing Gate;
- PublicationAttempt;
- governed recovery;
- Audit Log.

Phase 3: Engineering Services
- Dependency Explorer;
- Engineering Context;
- Rules Simulator;
- Helpy Registry Coverage;
- Bulk Operations;
- Global Rename.

Phase 4: Engineering Runtime
- Engineering Orchestrator;
- approved workflows;
- intent-based engineering execution;
- service coordination;
- deterministic workflow state.

Phase 5: Platform Expansion
- project adapters;
- storage adapters;
- immutable validated engineering service capability composition;
- reusable Registry Studio Core;
- future engineering assistant capabilities.

Rules:
- Development phases describe architectural maturity, not strict implementation order.
- New capabilities must be assigned to the phase that best matches their architectural responsibility.
- Phase separation must improve navigation and design consistency.
- Phase separation must not override approved domain contracts.
- Registry Studio must continue evolving through approved contracts, verified implementation and runtime evidence.

### Реализованные возможности

На текущем этапе в Registry Studio реализованы следующие возможности.

#### Навигация по Registry

- Древовидное представление Registry.
- Автоматическое построение дерева по структуре Markdown.
- Загрузка актуального Registry напрямую из GitHub.
- Выбор формулировки одним нажатием.
- Передача выбранной формулировки в рабочее пространство перевода.

#### Сохранение рабочего состояния

- Сохранение состояния дерева между сессиями.
- Сохранение положения прокрутки.
- Сохранение статусов проверки формулировок.
- Сохранение последнего рабочего контекста.
- Сохранение последнего открытого раздела.
- Сохранение последней выбранной формулировки.

#### Поиск и навигация

- Поиск по иерархии Registry.
- Подсветка найденных совпадений.
- Отображение полного пути до найденного элемента.
- Отображение статистики результатов поиска.
- Совместная работа поиска и фильтрации.

#### Контроль проверки

- Отображение статусов проверки формулировок.
- Фильтрация Registry по статусам проверки.
- Продолжение работы с последней сохранённой точки.

### Практическое применение

Registry Studio предназначен для сопровождения и развития Helpy Registry.

Использование Registry Studio позволяет:

- сократить время поиска необходимых разделов;
- сократить количество повторных действий;
- сохранять рабочий контекст между сессиями;
- ускорить проверку канонических формулировок;
- контролировать состояние проверки Registry;
- снизить вероятность появления архитектурного дрейфа;
- ускорить сопровождение и развитие Helpy Registry.

### Развитие Registry Studio

Registry Studio развивается одновременно с развитием Helpy Registry.

Новые возможности определяются практической работой с Registry и добавляются в настоящий раздел после проверки в реальном рабочем процессе.

Архитектура Registry Studio предусматривает постепенное расширение функциональности без нарушения ранее принятых архитектурных решений.


Non-goals:
- Studio must not silently change Registry.
- Studio must not publish changes without administrator confirmation.
- Studio must not resolve Drift automatically without review.
- Studio must not perform mass changes without Impact Analysis.
- Studio must not replace Git as the final version-control system.


Must-Have Roadmap:
- Rules Simulator;
- Impact Analysis;
- Helpy Registry Coverage;
- SANDBOX DraftWorkspace purpose.

Nice-To-Have Roadmap:
- Search Everywhere;
- Bulk Operations;
- Import / Export.

Rules Simulator:
Admin can simulate what the client or master will see for a selected role, category, subcategory, structured scope, form step, language, pricing rule, photo requirement, client rules, master rules, guidance rule, role-based guidance and workflow state.

Purpose:
- Evaluate adapter-defined expected behavior before publication; its trace
  becomes publication evidence only when a validation extension includes it
  in ValidationResult.
- Reduce APK rebuilds.
- Prevent broken category/form/pricing/guidance combinations.

Impact Analysis:
Admin can see what depends on a category, subcategory, structured scope, question, photo requirement, pricing rule, client rules, master rules, guidance rule, role-based guidance, admin dependencies, feature flag or workflow rule before changing, disabling, archiving or publishing it.

Purpose:
- Prevent accidental breakage.
- Show dependencies before risky changes.
- Support safe Admin Panel publishing.

Helpy Registry Coverage:
Admin can see Helpy readiness coverage per category/subcategory:
- category structure;
- structured scope;
- questions;
- photo requirements;
- pricing rules;
- client rules;
- master rules;
- scenario rules;
- guidance;
- role-based guidance;
- translations;
- client docs;
- master docs;
- service playbook;
- admin rules;
- health check status.

Purpose:
- Show what is complete, missing or risky before launch.
- Support category readiness decisions.
- Keep Registry and Admin Panel aligned.

SANDBOX DraftWorkspace:
Admin can prepare an isolated SANDBOX workspace for draft categories, rules,
pricing, guidance, completion flows and feature flags without exposing them to
real users. SANDBOX does not create RegistryTransaction or publication evidence.

Purpose:
- Separate draft experiments from production.
- Test future service logic safely.
- Support controlled Admin Panel experimentation; promotion uses a new instance
  of the existing DraftWorkspace with purpose = PUBLISHING_DRAFT, seeded from
  the exact SANDBOX revision and fingerprint.

Search Everywhere:
Admin can search across categories, subcategories, questions, photo requirements, pricing rules, guidance, translations, notes and platform settings.

Purpose:
- Reduce admin friction as Registry grows.
- Help find duplicated or conflicting rules.
- Support faster maintenance.

Governance Rules:
- Roadmap extensions must follow Draft / Published lifecycle where applicable.
- Roadmap extensions must support Audit Log where changes are possible.
- Roadmap extensions must not bypass Category Health Check.
- Roadmap extensions must not expose secrets or unsafe database access.
- Roadmap extensions should be implemented gradually after core Admin Panel builders.
- Rules Simulator, Impact Analysis, Helpy Registry Coverage and SANDBOX DraftWorkspace are higher priority than Search Everywhere, Bulk Operations and Import / Export.

### Future Admin Roles Reserve
Reserved:
- Super Admin
- Content Manager
- Support Manager
- Finance Manager
- Moderator

### Chat Lifecycle / Attachment Rules Builder

Admin can configure:
- Which order stages allow chat access.
- Which order stages allow photo attachments.
- Who can send attachments.
- Attachment limits.
- Attachment rules.
- Chat system guidance.

Purpose:
- Change chat business rules without APK rebuild.
- Keep chat behavior controlled by platform business logic.

### Completion Flow Builder

Admin can configure:
- Who initiates completion.
- Whether client confirmation is required.
- When the master can access Complete Order.
- Completion timers.
- Auto-completion behavior.
- Escalation to disputes.
- Completion notifications.

Purpose:
- Completion flow is business logic.
- Completion rules must remain configurable without APK rebuild.

### Admin Order Timeline / Evidence Screen

Admin must be able to open an order and see the full business lifecycle:

- job created;
- deposit paid;
- master selected;
- work started;
- master evidence photos uploaded;
- client completion confirmation;
- job completed;
- review submitted;
- dispute opened / resolved if applicable.

Prepared MVP Flow:

- Start Work changes order status from master_selected to in_progress.
- Start Work creates job_events.work_started.
- Master can upload evidence photos only after work starts.
- Master can select up to 10 evidence photos per upload action.
- Total order photo limit is 20 photos for MVP.
- Evidence photos are used for hidden defects, unsafe conditions, work process and final result.
- Current DB field job_photos.client_user_id is a legacy name and acts as uploaded_by_user_id until schema-cleanup.
- Final schema-cleanup before launch must rename this concept cleanly.

Admin Screen Requirements:

- Show order status timeline.
- Show chat history.
- Show client initial photos.
- Show master evidence photos.
- Show event history from job_events.
- Show payment/deposit state.
- Show selected master.
- Show completion state.
- Show review state.
- Show dispute state.

Purpose:

- Prepare Admin Panel for operational control.
- Connect Chat Lifecycle, Evidence, Completion Flow, Disputes and Reviews into one order screen.
- Prevent business-rule drift between mobile flow and admin visibility.

### Evidence / Quality Control Center

Admin can access:
- Chat history.
- Chat photos.
- Final work photos.
- Client confirmations.
- Price change history.
- Status history.
- Related disputes.

Purpose:
- Evidence protection.
- Quality control.
- Operational analytics.
- Platform improvement.

### Review / Reputation Builder

Admin can configure:
- Review activation.
- Review visibility.
- Review checkbox management.
- Review translations.
- Reputation metric visibility.
- Reliability icon visibility.
- Review publication rules.

Admin can access:
- Review list.
- Client comments.
- Reputation analytics.
- Review statistics.

Purpose:
- Improve service quality.
- Monitor reputation trends.
- Manage review experience without APK rebuild.

### Global Rules Builder

Admin can manage:
- Global rule activation.
- Global rule versions.
- Category assignments.
- Draft / Published states.
- Feature rollout.

Purpose:
- Reduce APK rebuilds.
- Centralize business logic management.

## 18. Future Business Direction
Status: PARTIALLY CLOSED — FUTURE STRATEGY APPROVED

Decision Summary:
- Future Business Direction is strategically approved.
- Design, Production, Logistics and Installation are confirmed post-MVP expansion directions.
- These directions must influence current architecture decisions.
- MVP implementation is not required.
- Database architecture, Admin Panel and business logic systems must support future expansion without redesign.
- Detailed workflows for these directions remain out of scope until post-MVP planning.
- This contract cannot be CLOSED until dedicated architecture contracts are created for these future verticals.

Helpy Projects:
- Design
- Production
- Logistics
- Installation

Purpose:
Prepare the platform architecture for future expansion without redesign.

Scope:
- Not MVP.
- Not required before launch.
## 19. Registry Expansion Plan
Status: CLOSED — RECOVERY METHODOLOGY APPROVED

Decision Summary:
- Service Architecture Registry defines the approved recovery methodology.
- Categories are recovered and expanded only as needed.
- Recovery follows a fixed category template.
- Approved chat history and future DOCX archives are approved recovery sources.
- The purpose of this methodology is to restore architecture quickly instead of redesigning it.
- No replacement architecture may be invented without evidence from approved sources.
- No unresolved architecture decisions remain in this contract.

Recovery Template:
- Subcategories
- Client Questions
- Required Photos
- Client Guidance
- Master Guidance
- Platform Rules
- Pricing Rules
- Admin Dependencies

Approved Recovery Sources:
- Approved chat history
- Future DOCX archives

Purpose:
Recover approved architecture rather than recreate it.
---
## 20. Service Architecture Registry — Furniture Assembly
Status: CLOSED — STORED + DOCS VERIFIED

Decision Summary:
- Furniture Assembly is fully recovered and verified.
- Registry evidence exists in approved documentation and stored archives.
- Furniture Assembly has reached the approved Helpy reference level of detail.
- Kitchen Assembly, Cabinet Furniture and Built-in Furniture retain their individual historical statuses.
- Internal category contracts remain unchanged.
- No unresolved architecture decisions remain at the Furniture Assembly root level.

Registry Status: STORED + DOCS VERIFIED ✅
### Root Category
Furniture Assembly

### Subcategories
- Kitchen Assembly — STORED + DOCS ✅
- Cabinet Furniture — STORED + DOCS ✅
- Built-in Furniture — STORED + DOCS ✅

---

## Furniture Assembly Mini-TZ Standard

Status: APPROVED / STORED ✅

Назначение:
- Этот стандарт применяется к Furniture Assembly mini-ТЗ внутри Service Architecture Registry — Furniture Assembly.
- Furniture Assembly использует customer-facing mini-TZ сущности и governing blocks.
- Mini-scope архитектура внутри Furniture Assembly не используется.
- Initial structured job scope формируется через выбранную mini-TZ сущность, structured questions, client answers и required photos.
- Каждая Furniture Assembly mini-TZ сущность должна содержать полный набор вопросов, фотографий, правил клиента и правил мастера внутри собственной ветки.
- Смысловое наследование между Furniture Assembly сценариями допускается, но не заменяет явное описание формы внутри конкретной сущности.

Mini-TZ Entity Rule:
- Kitchen Assembly, Cabinet Furniture и Built-in Furniture являются customer-facing mini-TZ сущностями.
- Mini-TZ сущность должна описывать назначение, вопросы, required photos, правила клиента, правила мастера, platform boundaries, admin dependencies и inherited rules.
- Mini-TZ сущность должна быть достаточной для формирования initial structured job scope без перехода в другую сущность.
- Вопросы и required photos дополняют друг друга и вместе формируют полноценное initial structured job scope.
- Furniture Assembly mini-TZ не должен превращаться в свободную диагностику мебели или помещения.

Governing Blocks Rule:
- Furniture Skill Levels, Furniture Admin Settings, Pricing, Premium Services и Admin Dependencies являются governing blocks.
- Governing blocks не являются customer-facing услугами.
- Governing blocks управляют доступом мастеров, настройками админ-панели, ценовыми параметрами, premium checks и правилами видимости.
- Governing blocks не заменяют явное описание вопросов, фотографий и правил внутри customer-facing mini-TZ сущностей.

Service-Flow Rule:
- Furniture Assembly является service-flow категорией с physical-product constraints.
- Furniture Assembly описывает сборку, установку, подготовку зоны работ, комплектность, доступность, безопасность крепления и ограничения выполнения работ.
- Furniture Assembly не включает подключение бытовой техники, перенос сантехники, перенос электрики, транспортировку, хранение или логистику мебели.
- Furniture Assembly не включает сортировку, упаковку, хранение или перемещение личных вещей клиента.
- Furniture Assembly может включать демонтаж мебели только там, где это явно утверждено сценарием или pricing rule.

Terminology Normalization Rule:
- Используется термин «сборка мебели» для cabinet/corpus furniture.
- Используется термин «установка встроенной мебели» для Built-in Furniture.
- Используется термин «кухонная сборка» для Kitchen Assembly.
- Используется термин «зона сборки / установки», если речь идёт о месте выполнения работ.
- Используется термин «комплектность», если речь идёт о наличии штатных деталей, крепежа, фурнитуры и элементов мебели.
- Термин «mini-scope» не используется для Furniture Assembly сущностей; governing blocks не являются mini-scope сущностями.
- Формулировка «диагностика мебели» не используется для Furniture Assembly сценариев.
- Формулировка «мастер может попросить дополнительные фото» не используется.
- Формулировка «клиент должен подготовить объект полностью» не используется без конкретного действия.

Furniture Mini-TZ Template:
1. Status:
- APPROVED / STORED.
- Standard Compliance: Furniture Assembly Mini-TZ Standard.

2. Назначение:
- Что описывает mini-ТЗ.
- Где применяется сценарий.
- Что входит в initial structured job scope.
- Чем сценарий не является.

3. Scope / Architecture:
- Что входит в сценарий.
- Что не входит в сценарий.
- Технологический тип работ.
- Ограничения сценария.
- Для встроенной мебели указывается workflow: measurement → project → installation.
- Для cabinet/corpus furniture указывается список поддерживаемых типов мебели без создания отдельных подкатегорий по product names.

4. Вопросы:
- Полный набор вопросов формы.
- Условные вопросы указываются явно.
- Табличные вопросы описываются как структура данных формы.
- Measurement / dimensions / niche tables описываются как структурированные поля.
- Safety questions указываются явно: wall fastening, children, stretch ceiling, reinforcements, lighting / electrical elements.
- Disassembly questions указываются явно: no / disposal / preserve.

5. Правила вопросов:
- Какие ответы формируют scope.
- Какие вопросы являются safety / access / completeness questions.
- Что клиент не обязан определять самостоятельно.
- Какие детали оцениваются по required photos и при необходимости уточняются через чат.
- Какие ответы влияют на сложность, цену, eligibility или необходимость отдельного согласования.

6. Обязательные фотографии:
- Фотография должны закрывать визуальную часть initial structured job scope.
- Каждое фото указывается отдельно.
- Для каждой позиции указывается обязательность и количество.
- Для схем, layouts, specifications, packing lists и карточек товара указывается, являются ли они обязательными или optional if available.

7. Дополнительные фотографии:
- Дополнительные фотографии указываются отдельно от обязательных.
- Дополнительные фотографии не должны ломать общий лимит фотографий.

8. Лимит фотографий:
- Обязательные.
- Дополнительные.
- Всего: до 10 из 10 фотографий, если для конкретной ветки не утверждён иной лимит.

9. Правила для клиента:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Доступ к зоне сборки / установки.
- Наличие мебели, коробок, комплектующих и документации на объекте.
- Подготовка зоны работ конкретными действиями.
- Освобождение личных вещей и ценностей из зоны работ.
- Раскрытие ограничений: демонтаж, сохранение старой мебели, стены, потолок, освещение, электрика, высота потолка.
- Границы того, что клиент не обязан определять самостоятельно.

10. Правила выполнения работ мастером:
- Проверка initial structured job scope.
- Проверка мебели / комплектующих / упаковки.
- Фиксация повреждений упаковки, мебели или деталей до начала работ через чат платформы.
- Проверка зоны сборки / установки.
- Проверка комплектности.
- Проверка safety constraints: wall/base safety, wall fastening, ceiling height, stretch ceiling, reinforcements, lighting / electrical elements.
- Выполнение сборки / установки.
- Проверка результата.
- Ограничения и действия при повреждениях, нехватке деталей или небезопасных условиях.
- Если мебель или детали повреждены, но клиент подтверждает продолжение работ, подтверждение клиента и фото становятся частью evidence заказа.

11. Platform boundaries:
- Что не входит в услугу.
- Какие работы являются отдельными услугами.
- Какие действия требуют согласования через чат.
- Transport, lifting, storage, logistics, packing for moving and removal are outside Furniture Assembly scope unless separately approved.
- Appliance connection, plumbing relocation and electrical relocation are outside Furniture Assembly scope unless separately approved.
- Мастер не перемещает, не сортирует, не хранит и не упаковывает личные вещи клиента.

12. Pricing:
- Client Expected Price Model.
- Minimum threshold rules.
- Percent rules.
- Premium inspection service price.
- Disassembly percent.
- MVP baseline prices must be editable from Admin Panel.

13. Premium Services:
- Control measurement.
- Completeness verification.
- Premium services are recommended, not mandatory, unless separately approved.
- Premium services do not replace the customer-facing mini-TZ.

14. Admin Dependencies:
- Minimum threshold settings.
- Commission percent settings.
- Percent rules.
- Dynamic questions.
- Dynamic tables.
- Required photos management.
- Rule visibility.
- Premium inspection service settings.
- Master eligibility rules.

15. Наследуемые правила:
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.
- Mobile Guidance Slots Contract.
- Contextual Guidance Knowledge System.
- Registry Editing Safety Rule.

Применение:
- Kitchen Assembly должен быть приведён к Furniture Assembly Mini-TZ Standard.
- Cabinet Furniture должен быть приведён к Furniture Assembly Mini-TZ Standard.
- Built-in Furniture должен быть приведён к Furniture Assembly Mini-TZ Standard.
- Furniture Skill Levels и Furniture Admin Settings остаются governing blocks.
- Future Furniture Assembly branches должны проектироваться по Furniture Assembly Mini-TZ Standard, если не утверждено отдельное исключение.

Наследуемые правила:
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.
- Mobile Guidance Slots Contract.
- Contextual Guidance Knowledge System.
- Registry Editing Safety Rule.

### 16.1 Kitchen Assembly
Status: APPROVED / CLOSED / STORED + DOCS ✅
Standard Compliance: Furniture Assembly Mini-TZ Standard ✅

#### Required Photos

1. Фотография мебели, комплектующих и фурнитуры на объекте.
- 1 обязательная фотография.

2. Проект кухонной мебели с размерами.
- 1 обязательная фотография.

3. Комплектовочный лист или спецификация поставщика.
- 1 необязательная фотография.

4. Фотография места установки спереди.
- 1 обязательная фотография.

5. Фотография выводов воды и водоотвода с рулеткой от угла или пола.
- 1 обязательная фотография.

6. Фотография центра электрических точек с рулеткой от угла или пола.
- 2 обязательные фотографии.
- До 2 дополнительных фотографий.

7. Фотография воздуховода.
- 1 необязательная фотография.

#### Лимит фотографий

- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

#### Правила для клиента

- Мебель, комплектующие и фурнитура должны находиться на объекте до приезда мастера.
- Клиент обеспечивает доступ к месту выполнения работ.
- Личные вещи должны быть убраны из зоны выполнения работ до начала установки.
- Установка кухонной мебели не включает установку и подключение встроенной бытовой техники.
- Для установки и подключения встроенной бытовой техники необходимо создать отдельный заказ в соответствующей категории.

#### Правила выполнения работ мастером

1. Проверка на соответствие.

- Мастер сверяет проект кухонной мебели, фотографии, комплектовочный лист при наличии и пояснения клиента перед началом работ.

2. Проверка мебели и комплектующих.

- Мастер проверяет наличие мебели, модулей, столешницы, комплектующих, фурнитуры и видимую комплектность поставки перед началом работ.
- Мастер фиксирует повреждения упаковки, мебели, столешницы или деталей в чате платформы до начала работ.

3. Проверка места установки.

- Мастер проверяет место установки, выводы воды, водоотвод, электрические точки и воздуховод по фотографиям и на объекте.
- Мастер самостоятельно проверяет качество стен перед навесом верхних модулей.
- Если условия установки отличаются от проекта или фотографий и мешают продолжению заказа, мастер фиксирует это в чате платформы до продолжения работ.

4. Выполнение сборки и установки.

- Мастер выполняет сборку и установку кухонной мебели по проекту клиента в пределах согласованного объёма работ.
- Подключение бытовой техники, перенос сантехники и перенос электрических точек не входят в базовую услугу сборки кухонной мебели.

5. Проверка результата.

- Мастер проверяет результат сборки, установку модулей, столешницы, фурнитуры и надёжность крепления мебели.

6. Ограничения и действия при повреждениях, нехватке деталей или небезопасных условиях.

- При выявлении повреждений, нехватки комплектующих или иных препятствий мастер фиксирует информацию в чате платформы до продолжения работ.
- Если повреждённые детали допускают продолжение работ, выполнение возможно только после согласования с клиентом через чат платформы.
- Если условия выполнения работ являются небезопасными, мастер вправе отказаться от выполнения работ до устранения причины.

#### Admin Dependencies

- Управление обязательными фотографиями.
- Управление отображением правил.
- Управление правилами допуска мастеров.

---

### 16.2 Cabinet Furniture
Status: APPROVED / CLOSED / STORED + DOCS ✅
Standard Compliance: Furniture Assembly Mini-TZ Standard ✅

#### Состав категории

Категория включает сборку новой корпусной мебели:

- шкафов;
- шкафов-купе;
- комодов;
- тумб;
- полок;
- кроватей;
- столов;
- стульев;
- мебельных комплектов;
- иной корпусной мебели.

Категория не включает:

- встроенную мебель;
- кухонную мебель.

#### Перечень мебели для сборки

Таблица:

- Тип мебели.
- Количество.
- Размеры (Ш × В × Г).

По умолчанию:
- 3 строки.
- Кнопка «Добавить мебель».
- Количество строк не ограничено.

#### Required Photos

1. Фотография мебели, комплектующих и фурнитуры на объекте.
- 1 обязательная фотография.
- До 1 дополнительной фотографии.

2. Фотография помещения, где будет установлена мебель.
- 1 обязательная фотография.
- До 7 дополнительных фотографий.

#### Лимит фотографий

- Обязательные: 2 фотографии.
- Дополнительные: до 8 фотографий.
- Всего: до 10 из 10 фотографий.

#### Правила для клиента

- Клиент обеспечивает доступ к месту выполнения работ.
- Личные вещи должны быть убраны из зоны выполнения работ до начала сборки.
- Для крупногабаритной мебели клиент должен обеспечить достаточное свободное пространство для сборки.
- Для высокой мебели высота потолка должна превышать высоту мебели не менее чем на 10 см.

#### Правила выполнения работ мастером

1. Проверка мебели и комплектующих.

- Мастер проверяет упаковку, мебель, комплектующие, фурнитуру и видимые повреждения перед началом сборки.
- Мастер фиксирует повреждения упаковки, мебели, комплектующих или деталей в чате платформы до начала работ.

2. Выполнение сборки.

- Мастер выполняет сборку корпусной мебели в пределах согласованного объёма работ.
- Если повреждённые детали допускают продолжение сборки, выполнение возможно только после согласования с клиентом через чат платформы.

3. Проверка устойчивости и безопасности.

- Мастер проверяет устойчивость мебели и необходимость фиксации к стене.
- Если мебель не имеет штатной фиксации к стене либо после установки остаётся неустойчивой, мастер обязан уведомить клиента о возможных рисках.
- Если дополнительная фиксация возможна, мастер должен предложить её выполнение до завершения работ.
- Дополнительная фиксация выполняется только после согласования с клиентом и является частью услуги.

4. Проверка результата.

- Мастер проверяет результат сборки, работу фурнитуры и надёжность устойчивости мебели.

#### Admin Dependencies

- Управление перечнем мебели для сборки.
- Управление обязательными фотографиями.
- Управление отображением правил.
- Управление правилами допуска мастеров.

---

### 16.3 Built-in Furniture
Status: APPROVED / CLOSED / STORED + DOCS ✅
Standard Compliance: Furniture Assembly Mini-TZ Standard ✅

#### Архитектура

Встроенная мебель является отдельной технологией установки.

Установка встроенной мебели выполняется непосредственно в нише или месте установки изделия.

Встроенная мебель не относится к Cabinet Furniture и не должна смешиваться с корпусной мебелью.

#### Вопросы клиенту

1. Требуется ли демонтаж установленной мебели перед установкой?

- Да
- Нет

2. Кто выполнял замер помещения перед заказом мебели?

- Поставщик мебели
- Самостоятельный замер

3. Из какого материала выполнены стены в месте установки?

- Бетон
- Кирпич
- Газобетон
- Гипсокартон, указать количество слоёв
- Другое, указать

4. Есть ли натяжной потолок в зоне установки?

- Да
- Нет
- Не знаю

Если выбрано «Да»:

5. Подготовлены ли закладные элементы?

- Да
- Нет
- Не знаю

6. Предусмотрены ли в проекте освещение или электрические подключения?

- Да
- Нет

#### Required Photos

1. Фотография мебели, комплектующих и фурнитуры на объекте.
- 1 обязательная фотография.
- До 1 дополнительной фотографии.

2. Проект изделия с размерами.
- 1 обязательная фотография.
- До 1 дополнительной фотографии.

3. Внутренняя схема наполнения с размерами.
- 1 обязательная фотография.
- До 1 дополнительной фотографии.

4. Фотография места установки.
- 1 обязательная фотография.
- До 1 дополнительной фотографии.

5. Комплектовочный лист или спецификация поставщика.
- До 1 дополнительной фотографии.

#### Лимит фотографий

- Обязательные: 4 фотографии.
- Дополнительные: до 5 фотографий.
- Всего: до 9 из 10 фотографий.

#### Таблица замеров ниши

Ширина:

- снизу снаружи
- снизу внутри
- по центру снаружи
- по центру внутри
- сверху снаружи
- сверху внутри

Высота:

- слева
- справа

Глубина:

- снизу слева
- снизу справа
- по центру слева
- по центру справа
- сверху слева
- сверху справа

#### Правила для клиента

- Клиент обеспечивает доступ к месту выполнения работ.
- Личные вещи должны быть убраны из зоны выполнения работ до начала установки.
- Клиент обеспечивает доступ к месту установки, нише и зоне монтажа мебели.
- Вы не обязаны самостоятельно определять соответствие размеров ниши и необходимость доработок по месту.
- Проект изделия, схема внутреннего наполнения и комплектовочный лист при наличии должны быть доступны мастеру до завершения работ.

#### Правила выполнения работ мастером

1. Проверка на соответствие.

- Мастер сверяет проект изделия, схему наполнения, размеры ниши, фотографии и пояснения клиента перед началом работ.

2. Проверка мебели и комплектующих.

- Мастер проверяет наличие мебели, комплектующих, фурнитуры и комплектность поставки перед началом работ.
- Мастер фиксирует повреждения упаковки, мебели, комплектующих или деталей в чате платформы до начала работ.

3. Проверка места установки.

- Мастер самостоятельно проверяет материал стен для подбора нужного крепления.
- При наличии натяжного потолка мастер проверяет наличие закладных элементов.
- Мастер проверяет точку подключения, если проект предусматривает освещение или электрические подключения.

4. Выполнение установки.

- Мастер выполняет монтаж встроенной мебели в пределах согласованного объёма работ.

5. Проверка результата.

- Мастер проверяет результат установки, работу фурнитуры и надёжность крепления мебели.

6. Ограничения и действия при повреждениях, нехватке деталей или небезопасных условиях.

- При выявлении повреждений, нехватки комплектующих или иных препятствий мастер фиксирует информацию в чате платформы до продолжения работ.
- Если повреждённые детали допускают продолжение работ, выполнение возможно только после согласования с клиентом через чат платформы.
- Если условия выполнения работ являются небезопасными, мастер вправе отказаться от выполнения работ до устранения причины.

#### Правила встроенной мебели

- Основным документом проекта являются схема изделия и схема внутреннего наполнения с размерами.
- После проекта изделия наиболее важными данными являются размеры места установки и ниши.
- Размеры ниши должны соответствовать проекту изделия или допустимым монтажным допускам.
- Сложность установки определяется не только внешними размерами изделия, но и внутренним наполнением.
- Освещение и электрические подключения могут влиять на сложность установки.

#### Admin Dependencies

- Управление таблицей замеров ниши.
- Управление обязательными фотографиями.
- Управление отображением правил.
- Управление правилами допуска мастеров по уровню Advanced furniture skill.

---

### 16.4 Furniture Disassembly
Status: APPROVED / CLOSED / STORED + DOCS ✅
Standard Compliance: Furniture Assembly Mini-TZ Standard ✅

#### Состав категории

Категория включает разборку мебели:

- корпусной мебели;
- кухонной мебели;
- встроенной мебели;
- мебельных комплектов;
- иной мебели.

Категория не включает:

- демонтаж элементов помещения;
- вынос, перевозку, хранение или утилизацию мебели;
- сортировку, упаковку, хранение и перемещение личных вещей клиента.

#### Архитектура

Furniture Disassembly является единой customer-facing mini-TZ сущностью.

Категория не разделяется на отдельные подкатегории по типу мебели.

Тип мебели определяется через:

- вопросы клиента;
- перечень мебели для разборки;
- required photos.

Один заказ может одновременно включать:

- корпусную мебель;
- кухонную мебель;
- встроенную мебель;
- мебельные комплекты.

Сформированное ТЗ формируется на основе ответов клиента, перечня демонтажа и загруженных фотографий.

#### Вопросы клиенту

1. Планируется ли повторная установка разобранной мебели?

- Да
- Нет

2. Требуется ли демонтаж бытовой техники?

- Да
- Нет

3. Требуется ли демонтаж электрического оборудования?

- Да
- Нет

4. Требуется ли демонтаж сантехнического оборудования?

- Да
- Нет

#### Перечень демонтажа

Таблица:

- Название мебели.
- Количество.
- Описание / Размеры.

По умолчанию:
- 3 строки.
- Кнопка «Добавить мебель».
- Количество строк не ограничено.

#### Required Photos

1. Фотография мебели, объектов демонтажа.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

2. Фотография бытового, электрического и сантехнического оборудования, которое требуется демонтировать.
- До 6 дополнительных фотографий.

#### Лимит фотографий

- Обязательные: 1 фотография.
- Дополнительные: до 9 фотографий.
- Всего: до 10 из 10 фотографий.

#### Правила для клиента

- Клиент обеспечивает доступ к месту выполнения работ.
- Личные вещи должны быть убраны из зоны демонтажа до начала работ.
- Клиент должен указать необходимость демонтажа бытовой техники, электрического и сантехнического оборудования через форму заказа.
- Вы не обязаны самостоятельно определять способ разборки мебели, порядок демонтажа, тип крепежа или технологию выполнения работ.
- Разобранная мебель, комплектующие, крепёж и фурнитура остаются собственностью клиента и остаются на объекте.

#### Правила выполнения работ мастером

1. Проверка заказа и зоны выполнения работ.

- Мастер изучает объект демонтажа, фотографии и ответы клиента перед началом работ.
- Мастер проверяет наличие бытовой техники, электрического и сантехнического оборудования, указанного клиентом в форме заказа.

2. Выполнение демонтажа.

- Мастер выполняет демонтаж мебели в пределах согласованного объёма работ.
- Демонтаж бытовой техники, электрического и сантехнического оборудования выполняется только если он был указан клиентом в форме заказа.

3. Проверка результата.

- Мастер проверяет завершённость согласованного объёма демонтажных работ.
- Демонтированная мебель, комплектующие, крепёж и фурнитура являются собственностью клиента и остаются на объекте.
- Демонтированное бытовое, электрическое и сантехническое оборудование являются собственностью клиента и остаются на объекте.

4. Ограничения и действия при препятствиях.

- Если условия выполнения работ являются небезопасными, мастер вправе отказаться от выполнения работ до устранения причины.

#### Admin Dependencies

- Управление перечнем демонтажа.
- Управление обязательными фотографиями.
- Управление отображением правил.
- Управление правилами допуска мастеров.

---
### 16.5 Furniture Skill Levels
Status: APPROVED ✅

Базовый уровень (Basic):
- Cabinet Furniture.

Средний уровень (Intermediate):
- Kitchen Assembly.

Продвинутый уровень (Advanced):
- Built-in Furniture.

Назначение:
- Управление доступом мастеров к мебельным заказам в зависимости от уровня сложности работ.
- Furniture Skill Levels используются как furniture-specific master eligibility bindings.
- Furniture Skill Levels являются eligibility gates, а не ranking signals.

---
### 16.6 Furniture Admin Settings
Status: APPROVED ✅

Future Admin Panel must support:
- Required photo management.
- Question management.
- Rule visibility.
- Master eligibility rules.

Removed legacy settings:
- Kitchen Assembly Base Price.
- Cabinet Furniture Base Price.
- Built-in Furniture Base Price.
- Furniture Disassembly Percent.
- Inspection Service Price.

Причина:
- Фиксированные базовые цены не используются в текущей модели ценообразования.
- Решение по Furniture Disassembly находится в статусе ARCHITECTURE REVIEW PENDING.
- Inspection Service / Premium Services удалены из MVP scope Furniture Assembly.

---
## 21. Service Architecture Registry — Cleaning
Status: CLOSED — STORED + DOCS VERIFIED

Decision Summary:
- Cleaning is fully recovered and verified.
- Registry evidence exists in approved documentation and stored archives.
- Cleaning is a specialized reference category with its own business logic.
- Regular Cleaning, Deep Cleaning and Post-Repair Cleaning retain their individual historical statuses.
- Internal category contracts remain unchanged.
- No unresolved architecture decisions remain at the Cleaning root level.

Registry Status: STORED + DOCS VERIFIED ✅
### Root Category
Cleaning

### Subcategories
- Regular Cleaning ✅ STORED + DOCS
- Deep Cleaning ✅ STORED + DOCS
- Post-Repair Cleaning ✅ STORED + DOCS

---

## Cleaning Mini-TZ Standard

Status: APPROVED / STORED ✅

Назначение:
- Этот стандарт применяется к Cleaning mini-ТЗ внутри Service Architecture Registry — Cleaning.
- Стандарт фиксирует единый порядок проектирования сценариев уборки внутри Cleaning.
- Cleaning Mini-TZ Standard используется для снижения дублей, устранения терминологических расхождений и подготовки старых Cleaning-блоков к переносу в Dart-модель без костылей.
- Cleaning является service-flow категорией, а не equipment-flow категорией.
- Initial structured job scope формируется через выбранный сценарий уборки, structured questions, client answers и required photos.
- Каждая Cleaning-сущность должна содержать полный набор вопросов и фотографий внутри своего mini-ТЗ.
- Смысловое наследование между Cleaning-сценариями допускается, но не заменяет явное описание формы внутри конкретной сущности.

Базовое правило сценариев уборки:
- Сценарии Cleaning описывают тип уборки, объект, площадь, дополнительные зоны и ограничения выполнения работ.
- Regular Cleaning применяется для обычной поддерживающей уборки.
- Deep Cleaning применяется для расширенной уборки, включая внутреннюю уборку подготовленной мебели, если это предусмотрено сценарием.
- Post-Repair Cleaning применяется для уборки после завершённого ремонта и строительных загрязнений.
- Если ремонт продолжается, Post-Repair Cleaning не выполняется.
- Cleaning-сценарии не являются свободной диагностикой состояния объекта.

Service-Flow Rule:
- Cleaning не использует install / replace terminology.
- Cleaning не использует правила проверки оборудования, демонтажа, подключения или совместимости оборудования.
- Cleaning не включает ремонт, перенос, монтаж, демонтаж или утилизацию мебели, техники, сантехники, электрики или строительных материалов.
- Cleaning не включает перемещение, сортировку, хранение или оценку личных вещей клиента.
- Cleaning не включает работы в небезопасных или недоступных зонах.

Алгоритм работы мастера для Cleaning-сценариев:
1. Проверка initial structured job scope до отклика.
2. Проверка доступности зон уборки.
3. Проверка ограничений сценария.
4. Выполнение уборки в пределах стоимости услуги.
5. Проверка результата в пределах выполненных работ.
6. Завершение заказа и подсказки мастеру выполняются по Global Completion / Guidance Rules.

Правило проверки scope:
- До отклика мастер изучает тип уборки, тип объекта, площадь, выбранные дополнительные зоны, ограничения и required photos.
- Если scope непонятен, мастер уточняет детали через чат без запроса дополнительных фотографий.
- Если после уточнений выявлены дополнительные работы, применяется глобальное правило платформы по изменению Final Agreed Price.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

Photo Scope Rule:
- Required photos должны закрывать визуальную часть initial structured job scope.
- Мастер не может запрашивать дополнительные фотографии в чате, если required photos уже определены формой.
- Дополнительные фото допускаются только как evidence после начала работ или как часть утверждённого completion/evidence flow.
- Общий лимит фотографий заказа составляет 10, если для конкретной ветки не утверждён иной лимит.

Terminology Normalization Rule:
- Используется термин «сценарий уборки», а не install / replace.
- Используется термин «зоны уборки», если речь идёт о помещениях или частях объекта.
- Используется термин «объект», если речь идёт о condo, квартире, доме, townhouse или другом объекте.
- Используется термин «required photos» / «обязательные фотографии» для фото, определённых формой.
- Формулировка «диагностика» не используется для Cleaning-сценариев.
- Формулировка «базовая работоспособность результата работ» не используется для Cleaning-сценариев; используется «подтверждение завершения результата уборки».
- Формулировка «ремонт продолжается» используется как stop-condition для Post-Repair Cleaning.
- Термин «строительные загрязнения» используется как scope Post-Repair Cleaning, а не как диагностика состояния объекта.
- Вопрос про домашних животных используется только в Cleaning-сценариях, где он влияет на безопасность выбора средств и выполнение работ.
- Формулировка «мастер может попросить дополнительные фото» не используется.
- Формулировка «клиент должен описать проблему своими словами» не используется.
- Формулировка «клиент должен подготовить объект полностью» не используется без конкретного действия.
- Формулировка «личные вещи» используется только в правилах ответственности клиента и запрета мастеру перемещать или сортировать вещи.

Применение:
- Regular Cleaning должен быть приведён к Cleaning Mini-TZ Standard.
- Deep Cleaning должен быть приведён к Cleaning Mini-TZ Standard.
- Post-Repair Cleaning должен быть приведён к Cleaning Mini-TZ Standard.
- Future Cleaning branches должны проектироваться по Cleaning Mini-TZ Standard, если не утверждено отдельное исключение.

Наследуемые правила:
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.
- Mobile Guidance Slots Contract.
- Contextual Guidance Knowledge System.

Architecture Notes:
- Cleaning Mini-TZ Standard является service-flow стандартом и не наследует terminology rules equipment-flow категорий.
- Каждая Cleaning-сущность должна оставаться самодостаточной формой для клиента, мастера и будущей Dart-модели.
- Вопросы и required photos внутри Cleaning дополняют друг друга и вместе формируют полноценное initial structured job scope.
- Cross-category terminology changes запрещены без ограничения диапазона редактирования конкретной категорией или сущностью.
- Cleaning wording не должен попадать в Appliance, Plumbing, Locks или другие equipment-flow категории.

### 17.1 Regular Cleaning

Status: APPROVED / STORED ✅
Standard Compliance: Cleaning Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает сценарий обычной поддерживающей уборки внутри Cleaning.
- Regular Cleaning применяется для объекта клиента без строительных загрязнений и без расширенной внутренней уборки мебели.
- Initial structured job scope формируется через тип объекта, площадь, балкон, домашних животных и required photos.
- Сценарий не является Deep Cleaning, Post-Repair Cleaning, ремонтом, разбором вещей или диагностикой состояния объекта.

Вопросы:

1. Тип объекта:
- Кондо.
- Квартира.
- Дом.
- Таунхаус.
- Другое.

2. Площадь объекта:
- До 30 м².
- 31–50 м².
- 51–80 м².
- 81–120 м².
- Более 120 м².

3. Есть ли балкон?
- Да.
- Нет.

Если выбрано «Да»:

4. Требуется уборка балкона?
- Да.
- Нет.

Если выбрано «Да»:

5. Площадь балкона:
- До 3 м².
- 4–6 м².
- 7–10 м².
- Более 10 м².

6. Есть ли домашние животные?
- Да.
- Нет.

Если выбрано «Да»:

7. Какие животные?
- Текстовое поле.

Правила вопросов:
- Клиент выбирает тип объекта и площадь объекта.
- Балкон уточняется только если он есть.
- Площадь балкона уточняется только если клиент выбирает уборку балкона.
- Вопрос про домашних животных используется для безопасности выбора средств и поведения мастера на объекте.
- Вы не обязаны описывать проблему в свободной форме.
- Вы не обязаны определять тип загрязнения.
- Эти детали оцениваются по required photos и при необходимости уточняются через чат.

Обязательные фотографии — Regular Cleaning:

1. Кухня.
- 1 обязательная фотография.

2. Санузел.
- 2 обязательные фотографии с разных ракурсов.

3. Спальня.
- 2 обязательные фотографии с разных ракурсов.

Дополнительные фотографии — Regular Cleaning:
1. Гостиная.
- До 1 дополнительной фотографии.

2. Балкон, если выбран.
- До 1 дополнительной фотографии.

3. Дополнительные помещения.
- До 3 дополнительных фотографий.

Лимит фотографий — Regular Cleaning:
- Обязательные: 5 фотографий.
- Дополнительные: до 5 фотографий.
- Всего: до 10 из 10 фотографий.

Правила для клиента — Regular Cleaning:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Подготовьте доступ к месту выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Вы не обязаны описывать проблему в свободной форме.
- Если используются специальные средства клиента, согласование выполняется через чат.
- Если на объекте есть домашние животные, клиент обязан указать это в форме.

Правила выполнения работ мастером — Regular Cleaning:

1. Проверка initial structured job scope:
- Мастер изучает тип уборки, тип объекта, площадь, балкон, домашних животных и фотографии до отклика.
- Если scope непонятен, мастер уточняет детали через чат без запроса дополнительных фотографий.

2. Выполнение уборки:
- Мастер выполняет уборку в пределах стоимости услуги.
- Мастер не перемещает личные вещи клиента без необходимости выполнения согласованной уборки.
- Мастер не сортирует личные вещи клиента.
- При наличии домашних животных мастер использует безопасные средства и действует с учётом указанной информации.
- Если используются специальные средства клиента, их применение должно быть согласовано через чат.

3. Проверка результата:
- После завершения работ мастер проверяет результат в пределах выполненной уборки.
- Услуга не считается качественно выполненной до подтверждения завершения результата уборки в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.
- Mobile Guidance Slots Contract.
- Contextual Guidance Knowledge System.

### 17.2 Deep Cleaning

Status: APPROVED / STORED ✅
Standard Compliance: Cleaning Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает сценарий глубокой уборки внутри Cleaning.
- Deep Cleaning применяется для расширенной уборки объекта, включая внутреннюю уборку подготовленной мебели, если это входит в согласованный объём услуги.
- Initial structured job scope формируется через тип объекта, площадь, балкон, домашних животных, заполненность помещения, подготовку мебели и required photos.
- Сценарий не является Regular Cleaning, Post-Repair Cleaning, ремонтом, разбором вещей или диагностикой состояния объекта.

Вопросы:

1. Тип объекта:
- Кондо.
- Квартира.
- Дом.
- Таунхаус.
- Другое.

2. Площадь объекта:
- До 30 м².
- 31–50 м².
- 51–80 м².
- 81–120 м².
- Более 120 м².

3. Есть ли балкон?
- Да.
- Нет.

Если выбрано «Да»:

4. Требуется уборка балкона?
- Да.
- Нет.

Если выбрано «Да»:

5. Площадь балкона:
- До 3 м².
- 4–6 м².
- 7–10 м².
- Более 10 м².

6. Есть ли домашние животные?
- Да.
- Нет.

Если выбрано «Да»:

7. Какие животные?
- Текстовое поле.

8. Помещение пустое?
- Да.
- Нет.

Правила вопросов:
- Клиент выбирает тип объекта и площадь объекта.
- Балкон уточняется только если он есть.
- Площадь балкона уточняется только если клиент выбирает уборку балкона.
- Вопрос про домашних животных используется для безопасности выбора средств и поведения мастера на объекте.
- Вопрос «Помещение пустое?» используется для оценки доступности зон уборки и возможности внутренней уборки мебели.
- Вы не обязаны описывать проблему в свободной форме.
- Вы не обязаны определять тип загрязнения.
- Эти детали оцениваются по required photos и при необходимости уточняются через чат.

Обязательные фотографии — Deep Cleaning:

1. Кухня.
- 1 обязательная фотография.

2. Санузел.
- 2 обязательные фотографии с разных ракурсов.

3. Спальня.
- 2 обязательные фотографии с разных ракурсов.

Дополнительные фотографии — Deep Cleaning:
1. Гостиная.
- До 1 дополнительной фотографии.

2. Балкон, если выбран.
- До 1 дополнительной фотографии.

3. Дополнительные помещения.
- До 3 дополнительных фотографий.

Лимит фотографий — Deep Cleaning:
- Обязательные: 5 фотографий.
- Дополнительные: до 5 фотографий.
- Всего: до 10 из 10 фотографий.

Правила для клиента — Deep Cleaning:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Подготовьте доступ к месту выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите личные вещи из зон внутренней уборки.
- Подготовьте мебель для внутренней уборки, если она входит в согласованный объём услуги.
- Если мебель не подготовлена, внутренняя уборка мебели не выполняется.
- Вы не обязаны описывать проблему в свободной форме.
- Если используются специальные средства клиента, согласование выполняется через чат.
- Если на объекте есть домашние животные, клиент обязан указать это в форме.

Правила выполнения работ мастером — Deep Cleaning:

1. Проверка initial structured job scope:
- Мастер изучает тип уборки, тип объекта, площадь, балкон, домашних животных, заполненность помещения и фотографии до отклика.
- Если scope непонятен, мастер уточняет детали через чат без запроса дополнительных фотографий.

2. Выполнение уборки:
- Мастер выполняет глубокую уборку в пределах стоимости услуги.
- Внутренняя уборка мебели выполняется только для пустой и подготовленной мебели.
- Мастер не перекладывает личные вещи клиента.
- Мастер не сортирует личные вещи клиента.
- Мастер не выполняет внутреннюю уборку неподготовленных зон.
- При наличии домашних животных мастер использует безопасные средства и действует с учётом указанной информации.
- Если используются специальные средства клиента, их применение должно быть согласовано через чат.

3. Проверка результата:
- После завершения работ мастер проверяет результат в пределах выполненной уборки.
- Услуга не считается качественно выполненной до подтверждения завершения результата уборки в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.
- Mobile Guidance Slots Contract.
- Contextual Guidance Knowledge System.

### 17.3 Post-Repair Cleaning

Status: APPROVED / STORED ✅
Standard Compliance: Cleaning Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает сценарий уборки после завершённого ремонта внутри Cleaning.
- Post-Repair Cleaning применяется для объекта клиента со строительной пылью, следами краски, герметика, шпаклёвки и другими строительными загрязнениями.
- Сценарий включает двойную влажную уборку в пределах стоимости услуги.
- Initial structured job scope формируется через тип объекта, площадь, балкон, завершённость ремонта, строительные загрязнения и required photos.
- Сценарий не является Regular Cleaning, Deep Cleaning, ремонтом, демонтажем, выносом строительных материалов или диагностикой состояния объекта.

Вопросы:

1. Тип объекта:
- Кондо.
- Квартира.
- Дом.
- Таунхаус.
- Другое.

2. Площадь объекта:
- До 30 м².
- 31–50 м².
- 51–80 м².
- 81–120 м².
- Более 120 м².

3. Есть ли балкон?
- Да.
- Нет.

Если выбрано «Да»:

4. Требуется уборка балкона?
- Да.
- Нет.

Если выбрано «Да»:

5. Площадь балкона:
- До 3 м².
- 4–6 м².
- 7–10 м².
- Более 10 м².

6. Ремонт полностью завершён?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Уборка после ремонта выполняется только после завершения ремонтных работ.

[Понятно]

Правила вопросов:
- Клиент выбирает тип объекта и площадь объекта.
- Балкон уточняется только если он есть.
- Площадь балкона уточняется только если клиент выбирает уборку балкона.
- Вопрос про домашних животных не используется в Post-Repair Cleaning.
- Вопрос «Ремонт полностью завершён?» является stop-condition.
- Вы не обязаны описывать проблему в свободной форме.
- Вы не обязаны определять тип загрязнения.
- Эти детали оцениваются по required photos и при необходимости уточняются через чат.

Обязательные фотографии — Post-Repair Cleaning:

1. Кухня.
- 1 обязательная фотография.

2. Санузел.
- 2 обязательные фотографии с разных ракурсов.

3. Спальня.
- 2 обязательные фотографии с разных ракурсов.

Дополнительные фотографии — Post-Repair Cleaning:
1. Гостиная.
- До 1 дополнительной фотографии.

2. Балкон, если выбран.
- До 1 дополнительной фотографии.

3. Дополнительные помещения.
- До 3 дополнительных фотографий.

Лимит фотографий — Post-Repair Cleaning:
- Обязательные: 5 фотографий.
- Дополнительные: до 5 фотографий.
- Всего: до 10 из 10 фотографий.

Правила для клиента — Post-Repair Cleaning:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Подготовьте доступ к месту выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите строительные материалы до начала уборки.
- Уберите инструмент до начала уборки.
- Если ремонт продолжается, уборка после ремонта не выполняется.
- Вы не обязаны описывать проблему в свободной форме.

Правила выполнения работ мастером — Post-Repair Cleaning:

1. Проверка initial structured job scope:
- Мастер изучает тип уборки, тип объекта, площадь, балкон, завершённость ремонта, строительные загрязнения и фотографии до отклика.
- Если scope непонятен, мастер уточняет детали через чат без запроса дополнительных фотографий.

2. Выполнение уборки:
- Мастер выполняет уборку после ремонта в пределах стоимости услуги.
- Мастер не выносит строительные материалы, инструмент или мусор, если это не входит в согласованный объём услуги.
- Мастер не перемещает личные вещи клиента без необходимости выполнения согласованной уборки.
- Мастер не сортирует личные вещи клиента.
- Мастер не отвечает за новую пыль, появившуюся после завершения работ из-за продолжения ремонта или новых строительных работ.

3. Проверка результата:
- После завершения работ мастер проверяет результат в пределах выполненной уборки.
- Услуга не считается качественно выполненной до подтверждения завершения результата уборки в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.
- Mobile Guidance Slots Contract.
- Contextual Guidance Knowledge System.

## 22. Service Architecture Registry — Air Conditioning
Status: CLOSED — APPROVED / STORED + DOCS VERIFIED

Decision Summary:
- Air Conditioning is an approved Helpy MVP root category.
- Repair is removed from Air Conditioning for launch.
- Preventive maintenance is not a separate launch subcategory and is treated as Cleaning from the client perspective.
- Relocation remains disabled on launch.
- Categories and subcategories must support independent enabled/disabled status.
- No unresolved architecture decisions remain at the Air Conditioning root level.

Registry Status: APPROVED / STORED + DOCS VERIFIED ✅

### Root Category
Air Conditioning

### Subcategories
Enabled on launch:
- Cleaning.
- Not Cooling.
- Leaking.
- Installation.
- Removal.
- Remote Control Issues.

Disabled on launch:
- Relocation.

Removed from MVP:
- Repair.

Reason:
- For Pattaya MVP, repair is high-variance and often less practical than replacement.
- Preventive maintenance is perceived by clients as cleaning.
- Relocation requires combined removal, installation and technical risk, so it remains disabled for launch.

---

## Air Conditioning Mini-TZ Standard
Status: APPROVED / STORED ✅

Назначение:
- Этот стандарт применяется ко всем mini-ТЗ внутри Service Architecture Registry — Air Conditioning.
- Стандарт фиксирует единый порядок проектирования сценариев обслуживания, установки, демонтажа и ограниченных problem-flow сценариев внутри Air Conditioning.
- Стандарт Air Conditioning Mini-TZ Standard используется для снижения дублей, устранения терминологических расхождений и подготовки старых Air Conditioning-блоков к переносу в Dart-модель без костылей.
- ТЗ формируется через выбранный сценарий, вопросы, ответы клиента и фотографии.
- Клиент выбирает проблему или действие, а не профессию мастера.
- Финальная стоимость утверждается после общения клиента и мастера в чате.
- Комиссия платформы рассчитывается от Final Agreed Price.

Обязательная структура каждой Air Conditioning mini-TZ сущности:

1. Status.
2. Standard Compliance.
3. Назначение.
4. Вопросы клиенту.
5. Правила вопросов.
6. Обязательные фотографии.
7. Лимит фотографий.
8. Правила для клиента.
9. Правила выполнения работ мастером.
10. Admin Dependencies.

Общие правила вопросов:
- Вопросы должны формировать ТЗ без свободного описания проблемы клиентом.
- Вопросы должны задаваться до этапа загрузки фотографий.
- Вопросы должны собирать только данные, которые невозможно или нецелесообразно надёжно определить по фотографиям.
- Если информация может быть определена по фотографиям без потери качества формирования заказа, отдельный вопрос не создаётся.
- Клиент не должен выступать техническим экспертом при заполнении формы заказа.
- Сложные технические параметры определяются по фотографиям и при необходимости уточняются через чат.
- Вопросы не должны превращать диагностику в скрытый ремонт.
- Вопросы не должны создавать обещание покупки материалов, запчастей или оборудования через платформу.

Structured Job Formation Principle:
1. Вопросы → намерение и границы работ.
2. Фотографии → фактическое состояние объекта.
3. Чат → уточнение исключений, согласование деталей и утверждение финальной цены заказа.

Общие правила фотографий:
- Фотографии должны подтверждать объект работ, фактическое состояние объекта, условия доступа и видимые ограничения.
- Форма не должна требовать от клиента опасного доступа к наружному блоку.
- Фотография наружного блока загружается только если к нему есть безопасный доступ.
- Технические характеристики, модель, упаковка или шильдик запрашиваются только там, где это реально влияет на выполнение конкретного сценария.
- Общий лимит фотографий заказа составляет 10, если для конкретной ветки не утверждён иной лимит.
- Мастер не может запрашивать дополнительные фотографии в чате, если фотографии уже определены формой заказа.
- Дополнительные фотографии допускаются только как доказательная база после начала работ или как часть утверждённого completion/evidence flow.

Общие правила для клиента:
- Вы не обязаны быть техническим специалистом по кондиционерам.
- Вы не обязаны самостоятельно диагностировать неисправности.
- Вы не обязаны разбирать кондиционер, снимать элементы оборудования или выполнять действия, которые могут быть небезопасны.
- Подготовьте доступ к месту выполнения работ.
- Уберите личные вещи, которые могут препятствовать выполнению работ.
- Доступ к наружному блоку требуется только в рамках согласованного объёма работ и только если он безопасен.
- Дополнительные работы, материалы и расходные материалы согласуются через чат до утверждения финальной цены заказа.

Общие правила выполнения работ мастером:
- Мастер изучает ТЗ, ответы клиента и фотографии до отклика.
- Мастер проверяет доступ к месту выполнения работ и безопасность выполнения работ до начала работ.
- Мастер проверяет доступность внутреннего блока и наружного блока, если это применимо к согласованному объёму работ.
- Мастер не выполняет работы на высоте без подходящего оборудования и безопасных условий.
- Мастер фиксирует видимые повреждения, небезопасный доступ, недоступность наружного блока или иные ограничения выполнения работ в чате до начала работ.
- Мастер выполняет работы только в пределах стоимости услуги.
- Если базовый сценарий не решает проблему клиента, мастер фиксирует ограничение и рекомендуемый следующий шаг в чате.
- Все дополнительные работы, материалы и изменение цены должны быть согласованы через чат до утверждения финальной цены заказа.

Правило ожидаемой стоимости клиента:
- Клиент указывает ожидаемую стоимость работ и размещает заказ.
- Платформа может установить минимальный порог стоимости (minimum threshold) по категории, подкатегории или сценарию.
- Минимальный порог стоимости не является рекомендацией цены.
- Минимальный порог стоимости не участвует в расчёте комиссии платформы.
- Минимальный порог стоимости нужен для защиты от опечаток, заведомо нереалистичных заявок и заказов без рыночного интереса.
- После публикации заказа мастер изучает ТЗ, ответы клиента, фотографии и ожидаемую стоимость клиента.
- Если ожидаемая стоимость клиента устраивает мастера, мастер подаёт заявку без изменения цены.
- Если ожидаемая стоимость клиента не устраивает мастера, мастер может предложить изменение цены только один раз.
- Причины изменения цены обсуждаются и предварительно согласуются с клиентом в чате.
- После согласования мастер отправляет финальную заявку.
- Клиент выбирает мастера по согласованной цене.
- В момент выбора мастера согласованная цена становится Final Agreed Price.
- Комиссия платформы, депозит и обязательство по комиссии рассчитываются только от Final Agreed Price.

Admin Dependencies:
- Category Builder.
- Subcategory Builder.
- Question Builder.
- Photo Requirement Builder.
- Pricing Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

---

### 22.1 Service
Status: APPROVED / STORED ✅
Standard Compliance: Air Conditioning Mini-TZ Standard ✅

Назначение:

- Этот mini-ТЗ описывает обслуживание кондиционера внутри категории Air Conditioning.
- Сценарий «Обслуживание» применяется для чистки внутреннего блока и внешнего, если есть к нему безопасный доступ.
- Сценарий «Обслуживание» предназначен для чистки и базового обслуживания кондиционера.
- Ремонт, диагностика неисправностей и замена компонентов не входят в данный сценарий.
- Техническое задание формируется по типу, количеству кондиционеров, мощности оборудования и доступности внутреннего и наружного блока.

#### Вопросы клиенту

1. Количество кондиционеров?
- 1.
- 2.
- Указать количество.

2. Доступен ли наружный блок?
- Да.
- Нет.

#### Правила вопросов

- Тип кондиционера не спрашивается.
- Мощность кондиционера не спрашивается.
- Доступность внутреннего блока не спрашивается.
- Тип кондиционера, мощность оборудования, способ установки и доступность внутреннего блока оцениваются по фотографиям.
- Доступность наружного блока спрашивается отдельно, так как влияет на возможность его обслуживания.
- Если наружный блок недоступен, его обслуживание не включается в объём заказа.
- Дополнительные условия доступа и сложность выполнения работ при необходимости уточняются через чат.

#### Обязательные фотографии

1. Фотография внутреннего блока и зоны его установки.
- 1 обязательная фотография.
- До 4 дополнительных фотографий.

2. Фотография наружного блока, если к нему есть безопасный доступ.
- До 5 дополнительных фотографий.

#### Лимит фотографий

- Всего: до 10 фотографий.

#### Правила для клиента — Service

- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбирать оборудование.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

#### Правила выполнения работ мастером — Обслуживание

1. Проверка технического задания до отклика:
- Мастер изучает количество кондиционеров, доступность наружного блока и фотографии.
- Мастер оценивает тип кондиционера, мощность оборудования и доступность внутреннего блока по фотографиям.
- Если информации недостаточно для оценки объёма работ, мастер уточняет детали через чат до финального согласования цены.

2. Проверка условий на объекте:
- До начала работ мастер проверяет доступ к месту выполнения работ.
- До начала работ мастер проверяет возможность безопасного обслуживания внутреннего блока.
- Если наружный блок входит в согласованный объём работ, мастер проверяет возможность безопасного доступа к нему.
- Если доступ к наружному блоку небезопасен или невозможен, мастер фиксирует ограничение в чате до начала работ.

3. Выполнение обслуживания:
- Мастер выполняет обслуживание только в пределах согласованного объёма работ.
- Обслуживание включает чистку и базовое обслуживание доступных частей кондиционера.
- Мастер не выполняет работы на высоте без подходящего оборудования и безопасных условий.
- Дополнительные расходные материалы регулируются Global Materials Separation Rule.

4. Проверка результата:
- Мастер проверяет результат обслуживания в пределах выполненного объёма работ.
- Проверка результата не является диагностикой скрытых неисправностей.
- Если обслуживание не может решить проблему клиента, мастер фиксирует ограничение и рекомендуемый следующий шаг в чате.

#### Admin Dependencies

- Question Builder.
- Photo Requirement Builder.
- Pricing Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

---

### 22.2 Not Cooling
Status: APPROVED / DISABLED ON LAUNCH / STORED + DOCS ✅
Standard Compliance: Air Conditioning Mini-TZ Standard — disabled diagnostics branch

Conservation Note:
- Этот блок сохранён полностью как архитектурный материал для будущей диагностической ветки Air Conditioning.
- Not Cooling не является активной MVP-сущностью и не должен отображаться клиенту на launch.
- Вопросы, фотографии, правила клиента, правила мастера и pricing notes ниже сохранены как исторический материал, а не как активный customer-flow.
- Повторное проектирование возможно только после утверждения диагностической ветки по Global Diagnostics Pattern.

Назначение:
- Этот блок сохранён как source material для будущей diagnostic branch внутри Air Conditioning.
- Not Cooling не является active launch subcategory.
- Not Cooling требует диагностики причины неисправности и может привести к repair, refrigerant refill, PCB repair, compressor repair or replacement recommendation.
- Repair removed from Air Conditioning MVP.
- Diagnostic branches remain disabled until explicitly approved for that category.
- Для launch MVP клиент не должен создавать обычный Air Conditioning заказ через Not Cooling.
- Будущая версия должна быть повторно спроектирована по Global Diagnostics Pattern.

#### Historical Client Questions
1. What happens?
   - Blows warm air.
   - Weak cooling.
   - Works then stops cooling.
   - Error light / error code.
   - I do not know.

2. When was the last cleaning?
   - Less than 3 months ago.
   - 3–6 months ago.
   - More than 6 months ago.
   - I do not know.

3. Is the outdoor unit running?
   - Yes.
   - No.
   - I do not know.

4. Is there an error code?
   - Yes, client enters text/photo.
   - No.
   - I do not know.

#### Historical Required Photos
- Indoor unit front view.
- Outdoor unit photo if accessible.
- Remote display / error code if visible.
- General installation area.

#### Historical Client Rules
- This subcategory is diagnostics-first.
- Final repair scope and parts are agreed through chat.
- If replacement is more practical than repair, master must explain before work continues.

#### Historical Master Rules
- Diagnose before offering repair work.
- Do not promise refrigerant refill, compressor repair or PCB repair before inspection.
- High-risk or major repair can be refused for MVP scope.
- Record diagnosis and recommended next step in chat.

#### Historical Pricing Notes
- Historical diagnostics pricing references are preserved as source material only.
- Для launch MVP не утверждена активная диагностика Not Cooling и не утверждены отдельные diagnostic pricing rules.
- Future diagnostics pricing must follow Client Expected Price Model and Global Diagnostics Pattern.

#### Admin Dependencies
- Global Diagnostics Pattern.
- Question Builder.
- Photo Requirement Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

---

### 22.3 Leaking
Status: APPROVED / DISABLED ON LAUNCH / STORED + DOCS ✅
Standard Compliance: Air Conditioning Mini-TZ Standard — disabled diagnostics branch

Conservation Note:
- Этот блок сохранён полностью как архитектурный материал для будущей диагностической ветки Air Conditioning.
- Leaking не является активной MVP-сущностью и не должен отображаться клиенту на launch.
- Вопросы, фотографии, правила клиента, правила мастера и pricing notes ниже сохранены как исторический материал, а не как активный customer-flow.
- Повторное проектирование возможно только после утверждения диагностической ветки по Global Diagnostics Pattern.

Назначение:
- Этот mini-ТЗ описывает ограниченный problem-flow по протечке воды из кондиционера внутри Air Conditioning.
- Leaking применяется, когда клиент видит воду из indoor unit, drain hose, outdoor unit или рядом с зоной кондиционера.
- Leaking не является ремонтом кондиционера, ремонтом стен, пола, мебели, электрики или последствий затопления.
- Leaking не включает вскрытие стен, строительные работы, electrical work или complex repair.
- Repair removed from Air Conditioning MVP and must not return as hidden scope inside Leaking.
- Initial structured job scope формируется через место протечки, время появления протечки, факт недавней чистки/сервиса и required photos.

#### Вопросы клиенту

1. Where is water leaking?
   - From indoor unit.
   - From drain hose.
   - From outdoor unit.
   - I do not know.

2. When does it leak?
   - Immediately after turning on.
   - After some time.
   - Constantly.
   - Only sometimes.
   - I do not know.

3. Was the unit recently cleaned or serviced?
   - Yes.
   - No.
   - I do not know.

#### Правила вопросов

- Клиент указывает видимое место протечки.
- Если клиент не знает источник воды, он выбирает «I do not know».
- Время появления протечки помогает мастеру оценить вероятный bounded cause, но не превращает сценарий в repair diagnostics.
- Вопрос про недавнюю чистку/сервис нужен для оценки возможной связи с drain blockage, загрязнением или ошибкой обслуживания.
- Вы не обязаны самостоятельно определять техническую причину протечки.
- Если проблема требует complex repair, вскрытия стен, electrical work or construction work, такой scope не входит в Leaking MVP.

#### Required Photos

1. Leak location.
- 1 обязательная фотография.

2. Indoor unit front view.
- 1 обязательная фотография.

3. Drain hose / drain area if visible.
- До 1 дополнительной фотографии.

4. Wall/floor damage area if present.
- До 1 дополнительной фотографии.

#### Лимит фотографий

- Обязательные: 2 фотографии.
- Дополнительные: до 2 фотографий.
- Всего: до 4 из 10 фотографий.

#### Правила для клиента

- Клиент должен прекратить использование кондиционера, если вода может повредить electrical points, мебель, стены или пол.
- Клиент обеспечивает безопасный доступ к indoor unit и видимой зоне протечки.
- Вы не обязаны вскрывать панели, стены или выполнять техническую диагностику.
- Water damage repair is not included.
- Wall repair, floor repair, furniture repair, repainting, electrical repair and construction work are not included.
- Drain cleaning, cleaning or additional bounded work may be agreed through chat before Final Agreed Price.
- Leaking не гарантирует устранение скрытой неисправности, если причина требует repair removed from MVP.

#### Правила выполнения работ мастером

1. Проверка initial structured job scope.
- Мастер изучает место протечки, время появления протечки, факт недавней чистки/сервиса и required photos до отклика.
- Мастер проверяет видимый drain area, indoor unit position, доступность зоны работы и возможные visible installation issues.

2. Выполнение bounded leaking work.
- Мастер выполняет работы только в пределах согласованного Leaking scope.
- Мастер может проверить drain blockage, visible drain hose issues, visible indoor unit slope and visible installation issues.
- Мастер не выполняет complex repair, refrigerant work, PCB repair, compressor repair, electrical repair, wall opening or construction work.
- Мастер не открывает стены и не выполняет ремонт повреждений от воды.
- Если scope выходит за пределы Leaking MVP, мастер фиксирует причину и следующий шаг в чате.

3. Проверка результата.
- Мастер проверяет результат в пределах выполненного bounded scope.
- Если причина протечки не может быть устранена в рамках Leaking MVP, мастер объясняет клиенту следующий шаг через чат.

#### Admin Dependencies

- Question Builder.
- Photo Requirement Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

---

### 22.4 Install & Connect
Status: APPROVED / STORED ✅
Standard Compliance: Air Conditioning Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку и подключение нового кондиционера внутри категории Air Conditioning.
- В MVP поддерживается установка только нового кондиционера.
- Сценарий «Установить и подключить» применяется, когда новый кондиционер находится на объекте клиента и требуется монтаж, подключение и базовая проверка результата.
- Установка бывших в эксплуатации или ранее демонтированных кондиционеров не входит в MVP.
- Сценарий «Установить и подключить» не является ремонтом, заменой, переносом, демонтажем или диагностикой кондиционера.
- Перенос электрической точки, новая проводка, работы с автоматами, строительные работы, ремонт стен и отделочные работы не входят в базовый объём установки.
- ТЗ формируется через вопросы, материал стены, место размещения наружного блока, фотографии места установки, фотографии коммуникаций подключения и техническую информацию оборудования.

#### Вопросы клиенту — Установить и подключить

1. Из какого материала выполнена стена в месте установки?

- Бетон
- Кирпич
- Газобетон
- Гипсокартон, указать количество слоёв
- Другое, указать

2. Где будет размещён наружный блок?

- Балкон
- Земля / площадка
- На кронштейне фасада
- Крыша
- Другое, указать самостоятельно

#### Правила вопросов

- Материал стены влияет на сложность монтажа и риски крепления.
- Если выбран вариант «Другое», клиент указывает материал самостоятельно.
- Место размещения наружного блока уточняется для оценки доступа и безопасности выполнения работ.
- Если выбран вариант «Другое», клиент указывает место размещения самостоятельно.
- Вы не обязаны самостоятельно определять скрытое состояние стены, электропроводки или трассы.
- Технические характеристики кондиционера, наличие оборудования на объекте и комплектность оборудования определяются по фотографиям и информации на упаковке либо карточке товара.
- Расходные материалы, дополнительная длина трассы, кронштейны, дренаж и кабель регулируются Global Materials Separation Rule.

#### Обязательные фотографии — Установить и подключить

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотография упаковки со всей информацией на ней или карточка товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография места установки внутреннего блока.
- 1 обязательная фотография.

4. Фотография места установки наружного блока.
- До 2 дополнительных фотографий.

5. Фотография коммуникаций подключения.
- 1 обязательная фотография;
- до 1 дополнительной фотографии.

#### Лимит фотографий — Установить и подключить

- Обязательные: 5 фотографий.
- Дополнительные: до 5 фотографий.
- Всего: до 10 фотографий.

#### Правила для клиента — Install & Connect

- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

#### Правила выполнения работ мастером — Установить и подключить

1. Проверка технического задания до отклика:

- Мастер изучает место установки, место размещения наружного блока, материал стены, фотографии и техническую информацию оборудования.
- Мастер оценивает доступ, видимую готовность места установки и возможную потребность в дополнительных материалах.
- Если информации недостаточно для оценки объёма работ, мастер уточняет детали через чат до финального согласования цены.

2. Проверка оборудования до установки:

- До начала установки мастер обязан выполнить визуальный осмотр оборудования.
- Проверка включает наличие видимых механических повреждений.
- Мастер обязан проверить комплектность оборудования и наличие штатных элементов установки и подключения.
- При обнаружении повреждений или отсутствия необходимых элементов мастер обязан зафиксировать это на фотографиях и направить клиенту через чат приложения до продолжения работ.
- Если клиент подтверждает продолжение работ, подтверждение клиента и фотографии становятся частью доказательной базы заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Проверка условий установки:

- Мастер проверяет совместимость места установки внутреннего блока, места размещения наружного блока, материала стены и зоны подключения до начала работ.
- Мастер не выполняет работы на высоте без соответствующего оборудования.
- Если условия установки небезопасны или несовместимы, мастер фиксирует причину в чате до начала работ.

4. Установка и подключение:

- Мастер выполняет установку и подключение только в пределах согласованного объёма работ.
- Расходные материалы, такие как дополнительная длина трассы, кронштейны, дренаж и кабель, регулируются Global Materials Separation Rule.
- Упаковка оборудования является собственностью клиента и остаётся на объекте.

5. Проверка результата:

- Мастер проверяет результат установки в пределах выполненного объёма работ.
- Проверка результата не является диагностикой скрытых неисправностей.

#### Наследуемые правила

- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

#### Admin Dependencies

- Question Builder.
- Photo Requirement Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

---

### 22.5 Replacement
Status: APPROVED / STORED ✅
Standard Compliance: Air Conditioning Mini-TZ Standard ✅

Назначение:

- Этот mini-ТЗ описывает замену кондиционера внутри категории Air Conditioning.
- Замена включает демонтаж оборудования и установку нового кондиционера.
- Сценарий «Заменить» не является ремонтом, переносом или диагностикой.
- ТЗ формируется через вопросы, фотографии места установки, коммуникаций подключения и техническую информацию.

#### Вопросы клиенту — Заменить

1. Где расположен наружный блок?

- Балкон
- Земля / площадка
- На кронштейне фасада
- Крыша
- Другое, указать самостоятельно

#### Правила вопросов

- Вопрос о наличии нового кондиционера на объекте является стоп-условием.
- Вопрос о новом оборудовании является стоп-условием.
- Если новый кондиционер был в использовании, клиент не уверен или новый кондиционер ещё не находится на объекте, заказ на замену не создаётся в рамках MVP.
- Старый установленный кондиционер является основанием для сценария «Заменить».
- Если старого установленного кондиционера нет, клиент должен использовать сценарий «Установить и подключить».
- Вопрос о месте установки нужен, чтобы отделить обычную замену на том же месте от переноса кондиционера.
- Если новый кондиционер устанавливается не на место старого, мастер оценивает риски как расширенный объём работ через чат до утверждения финальной цены заказа.
- Необходимость сохранения старого кондиционера уточняется до начала работ.
- Утилизация уточняется отдельно, потому что не входит в замену автоматически.
- Доступность наружного блока уточняется для оценки безопасности и сложности доступа.
- Вы не обязаны выполнять опасные действия для проверки доступа к наружному блоку.
- Материалы, дополнительная длина трассы, кронштейны, дренаж, кабель и работы со сложным доступом регулируются Global Materials Separation Rule.

#### Обязательные фотографии — Заменить

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.
- до 1 дополнительной фотографии.

2. Фотография упаковки со всей информацией на ней или карточка товара с технической информацией.
- До 4 фотографий:
  - 2 обязательные;
  - до 2 дополнительных.

3. Фотография установленного внутреннего блока.
- 1 обязательная фотография.
- до 1 дополнительной фотографии.

4. Фотография установленного наружного блока.
- 1 обязательная фотография.
- до 1 дополнительной фотографии.

#### Лимит фотографий — Заменить

- Обязательные: 5 фотографий.
- Дополнительные: до 5 фотографий.
- Всего: до 10 фотографий.

#### Правила для клиента — Replacement

- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

#### Правила выполнения работ мастером — Заменить

1. Проверка технического задания до отклика:
- Мастер изучает данные о новом кондиционере, установленном старом кондиционере, месте установки, доступности наружного блока, электрической точке и фотографии.
- Мастер оценивает доступ, видимую готовность места установки, сложность демонтажа и возможную потребность в дополнительных материалах.
- Если информации недостаточно для оценки объёма работ, мастер уточняет детали через чат до финального согласования цены.

2. Демонтаж установленного кондиционера:
- Мастер выполняет демонтаж установленного кондиционера в пределах стоимости услуги замены.
- Мастер защищает имущество клиента во время демонтажа.
- Мастер не выполняет работы на высоте без подходящего оборудования и безопасных условий.
- Мастер размещает демонтированное оборудование и комплектующие в согласованной зоне.
- Утилизация, сложный доступ и дополнительные ограниченные работы должны быть согласованы через чат до утверждения финальной цены заказа.

3. Проверка нового оборудования до установки:
- До начала установки мастер обязан выполнить визуальный осмотр нового оборудования.
- Проверка включает наличие видимых механических повреждений.
- Мастер обязан проверить комплектность оборудования и наличие штатных элементов установки или подключения.
- При обнаружении повреждений или отсутствия необходимых элементов мастер обязан зафиксировать это на фотографиях и направить клиенту через чат приложения до продолжения работ.
- Если клиент подтверждает продолжение работ, подтверждение клиента и фотографии становятся частью доказательной базы заказа.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

4. Установка и подключение нового кондиционера:
- После демонтажа мастер выполняет установку и подключение нового кондиционера в пределах согласованного объёма работ.
- Мастер проверяет совместимость места установки внутреннего блока, места размещения наружного блока, типа стены, доступа и видимой готовности электроподключения до начала работ.
- Мастер не выполняет перенос электрической точки, новую проводку, работы с автоматами, строительные работы, ремонт стен или отделочные работы в рамках базового объёма замены.
- Дополнительная длина трассы, кронштейны, дренаж, кабель, расходные материалы, сложный доступ и дополнительные материалы регулируются Global Materials Separation Rule.
- Упаковка нового товара является собственностью клиента.
- Вынос или утилизация упаковки не входят в стоимость услуги.

5. Проверка результата:
- Мастер проверяет результат замены в пределах выполненного объёма работ.
- Проверка результата не является диагностикой скрытых неисправностей.
- Если после проверки выявлены ограничения, не входящие в MVP-сценарий замены, мастер объясняет следующий шаг через чат.

#### Наследуемые правила

- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

#### Admin Dependencies

- Question Builder.
- Photo Requirement Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

---

### 22.6 Removal
Status: APPROVED / DISABLED ON LAUNCH / STORED + DOCS ✅
Standard Compliance: Air Conditioning Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает демонтаж кондиционера внутри категории Air Conditioning.
- Сценарий «Демонтаж» применяется для демонтажа внутреннего блока, наружного блока или обеих частей кондиционера.
- Сценарий «Демонтаж» не является переносом кондиционера, установкой, ремонтом, ремонтом стены, покраской, отделочными работами или автоматической утилизацией.
- Демонтированное оборудование, крепления, трубы и комплектующие остаются собственностью клиента, если иное не согласовано отдельно.
- Утилизация не входит в базовый объём демонтажа и должна быть согласована через чат до утверждения финальной цены заказа.
- ТЗ формируется через состав демонтажа, необходимость сохранения оборудования, необходимость утилизации, доступность наружного блока и фотографии.

#### Вопросы клиенту

1. Что нужно демонтировать?
- Внутренний и наружный блоки.
- Только внутренний блок.
- Только наружный блок.

2. Нужно ли сохранить демонтированный кондиционер?
- Да.
- Нет.
- Не знаю.

3. Требуется ли утилизация?
- Да.
- Нет.
- Не знаю.

4. Доступен ли наружный блок?
- Да.
- Нет.
- Доступ с балкона.
- Сложный доступ.
- Не знаю.

#### Правила вопросов

- Клиент указывает, какие части кондиционера нужно демонтировать.
- Если клиент не знает точный состав демонтажа, он выбирает «Не знаю».
- Необходимость сохранения оборудования уточняется до начала работ, потому что влияет на аккуратность демонтажа.
- Утилизация уточняется отдельно, потому что не входит в демонтаж автоматически.
- Доступность наружного блока уточняется для оценки безопасности и сложности доступа.
- Вы не обязаны выполнять опасные действия для проверки доступа к наружному блоку.
- Ремонт стены, покраска, отделочные работы, строительные работы и перенос кондиционера не входят в MVP-сценарий демонтажа.

#### Обязательные фотографии

1. Фотография внутреннего блока.
- 1 обязательная фотография.

2. Фотография наружного блока, если к нему есть безопасный доступ.
- До 1 дополнительной фотографии.

3. Фотография трассы, отверстия в стене или видимого участка коммуникаций, если они видны.
- До 1 дополнительной фотографии.

4. Фотография зоны доступа к месту демонтажа.
- 1 обязательная фотография.

#### Лимит фотографий

- Обязательные: 2 фотографии.
- Дополнительные: до 2 фотографий.
- Всего: до 4 из 10 фотографий.

#### Правила для клиента

- Клиент обеспечивает безопасный доступ к зоне демонтажа.
- Вы не обязаны выполнять опасные действия для фотографирования наружного блока.
- Демонтаж не включает утилизацию автоматически.
- Утилизация должна быть согласована через чат до утверждения финальной цены заказа.
- Ремонт стены, покраска, отделочные работы и строительные работы не входят в демонтаж.
- Демонтированное оборудование, крепления, трубы и комплектующие остаются собственностью клиента, если иное не согласовано отдельно.
- Если демонтированный кондиционер нужно сохранить, клиент должен указать это в форме заказа.

#### Правила выполнения работ мастером

1. Проверка технического задания до отклика:
- Мастер изучает состав демонтажа, необходимость сохранения оборудования, необходимость утилизации, доступность наружного блока и фотографии.
- Мастер оценивает безопасность доступа, зону выполнения работ, видимое состояние стены и видимый участок трассы до начала работ.
- Мастер подтверждает, нужно ли сохранить демонтированный кондиционер.

2. Выполнение демонтажа:
- Мастер выполняет демонтаж только в пределах согласованного объёма работ.
- Мастер защищает имущество клиента во время демонтажа.
- Мастер не выполняет работы на высоте без подходящего оборудования и безопасных условий.
- Мастер не выполняет ремонт стены, покраску, отделочные работы, строительные работы, установку или перенос кондиционера в рамках демонтажа.
- Мастер размещает демонтированное оборудование и комплектующие в согласованной зоне.
- Утилизация, сложный доступ и дополнительные ограниченные работы должны быть согласованы через чат до утверждения финальной цены заказа.

3. Проверка результата:
- Мастер проверяет завершённость демонтажа в пределах согласованного объёма работ.
- Мастер фиксирует видимые повреждения стены, риск доступа или ограничение объёма работ в чате, если это влияет на результат.

#### Admin Dependencies

- Question Builder.
- Photo Requirement Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

---

### 22.7 Remote Control Issues
Status: APPROVED / DISABLED ON LAUNCH / STORED + DOCS ✅
Standard Compliance: Air Conditioning Mini-TZ Standard — disabled diagnostics branch

Conservation Note:
- Этот блок сохранён полностью как архитектурный материал для будущей диагностической ветки Air Conditioning.
- Remote Control Issues не является активной MVP-сущностью и не должен отображаться клиенту на launch.
- Вопросы, фотографии, правила клиента и правила мастера ниже сохранены как исторический материал, а не как активный customer-flow.
- Повторное проектирование возможно только после утверждения диагностической ветки по Global Diagnostics Pattern.

Назначение:
- Этот mini-ТЗ описывает ограниченный problem-flow по пульту управления кондиционером внутри Air Conditioning.
- Remote Control Issues применяется для проблем с remote control, display, buttons, signal, lost remote or basic compatibility check.
- Remote Control Issues не является ремонтом кондиционера, ремонтом receiver board, PCB repair, electrical repair или заменой внутренних компонентов кондиционера.
- Replacement remote purchase is not handled by platform.
- Initial structured job scope формируется через тип проблемы, battery check, наличие другого remote / mobile control и required photos.

#### Вопросы клиенту

1. What is the issue?
   - Remote does not turn on.
   - Remote display works but AC does not respond.
   - Some buttons do not work.
   - Remote is lost.
   - I do not know.

2. Are batteries replaced?
   - Yes.
   - No.
   - I do not know.

3. Is there another remote / mobile control?
   - Yes.
   - No.
   - I do not know.

#### Правила вопросов

- Клиент указывает видимую проблему с remote control.
- Battery check уточняется для исключения простой причины.
- Наличие другого remote / mobile control помогает оценить, проблема связана с remote, настройками или откликом indoor unit.
- Вы не обязаны самостоятельно диагностировать receiver, PCB, wiring or internal unit failure.
- Если проблема требует repair кондиционера или внутренних компонентов, такой scope не входит в Remote Control Issues MVP.
- Replacement remote purchase is not handled by platform.

#### Required Photos

1. Remote control front.
- 1 обязательная фотография, если remote control есть у клиента.

2. Remote display if visible.
- До 1 дополнительной фотографии.

3. Air conditioner model label if available.
- 1 обязательная фотография.

4. Indoor unit front view.
- 1 обязательная фотография.

#### Лимит фотографий

- Обязательные: 3 фотографии.
- Дополнительные: до 1 фотографии.
- Всего: до 4 из 10 фотографий.

#### Правила для клиента

- Клиент проверяет batteries before visit, если это возможно и безопасно.
- Если remote lost, клиент указывает это в форме заказа.
- Клиент обеспечивает доступ к indoor unit и model label, если это безопасно.
- Вы не обязаны вскрывать remote control, indoor unit или electrical components.
- Replacement remote purchase is not handled by platform.
- Compatibility and purchase options may be discussed through chat before Final Agreed Price.
- Remote Control Issues не гарантирует repair кондиционера, receiver board, PCB or internal electronics.

#### Правила выполнения работ мастером

1. Проверка initial structured job scope.
- Мастер изучает issue type, battery check, наличие другого remote / mobile control, model label and required photos до отклика.
- Мастер проверяет batteries, visible remote condition, signal behavior and basic indoor unit response if possible.

2. Выполнение bounded remote-control work.
- Мастер выполняет работу только в пределах согласованного Remote Control Issues scope.
- Мастер не выполняет PCB repair, receiver board repair, internal electronics repair, electrical repair or hidden unit repair.
- Мастер не обещает replacement remote availability before model and compatibility check.
- Replacement remote/materials must be discussed through chat before Final Agreed Price if applicable.

3. Проверка результата.
- Мастер фиксирует model, observed behavior and recommendation в чате.
- Если проблема выходит за пределы Remote Control Issues MVP, мастер объясняет следующий шаг через чат.

#### Admin Dependencies

- Question Builder.
- Photo Requirement Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

---

### 22.8 Relocation
Status: APPROVED / DISABLED ON LAUNCH / STORED + DOCS ✅

Conservation Note:
- Этот блок сохранён полностью как архитектурный материал для будущей ветки Relocation внутри Air Conditioning.
- Relocation не является активной MVP-сущностью и не должен отображаться клиенту на launch.
- Scope, Launch Decision и Reason ниже сохранены как исторический архитектурный материал.
- Повторное проектирование возможно только после отдельного утверждения relocation branch.

#### Scope
Relocation combines removal and installation of the same air conditioner in a new place.

#### Launch Decision
- Disabled on launch.
- Can be enabled later from Admin Panel after operational validation.

#### Reason
- Requires removal, installation, material calculation and access risk in one order.
- Higher chance of hidden extra work.
- Better handled after installation/removal flows are proven.

---

### Business Rules
- Client chooses the problem, not the profession.
- Preventive maintenance is not a separate subcategory for launch.
- Repair is removed from Air Conditioning MVP.
- Materials and additional work are agreed between client and master through chat.
- Platform does not participate in materials purchase.
- Each subcategory has independent enabled/disabled status.
- High-risk work may be refused by master if unsafe or outside MVP scope.

### Service Playbook
1. Client selects Air Conditioning subcategory.
2. Client answers structured questions.
3. Client uploads required photos.
4. Master reviews access, unit type and risk.
5. Master sends offer or asks clarifying questions in chat.
6. Extra materials or additional work are confirmed in chat.
7. Work result and exceptions are recorded in chat before completion.

### Admin Dependencies
- Air Conditioning category enabled/disabled.
- Independent subcategory enabled/disabled.
- Question Builder.
- Photo Requirement Builder.
- Guidance Builder.
- Global Rules Builder.
- Master Eligibility Rules.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

### FAQ
- Repair is not a launch subcategory.
- Preventive maintenance is shown to clients as Cleaning.
- Disposal is separate from Removal.
- Materials are not included automatically.
- Platform deposit is platform income and does not cover materials.
- Relocation is approved but disabled on launch.
---
## 23. Service Architecture Registry — Electrical
Status: APPROVED / STORED ✅

Decision Summary:
- Electrical использует mini-scope architecture по модели add-more.
- Одна электрическая точка = одно mini-ТЗ внутри одного заказа.
- Клиент может добавить несколько электрических точек в один заказ.
- Каждая электрическая точка содержит собственный Work Type, Equipment Type, вопросы и фотографии.
- Старые отдельные ветки Install / Replacement / Relocation больше не используются как самостоятельные подкатегории.
- Логика Install / Replacement / Relocation хранится внутри каждой electrical point через поле Work Type.

### Electrical Mini-Scope Standard
Status: APPROVED / STORED ✅

Назначение:
- Этот стандарт описывает архитектуру Electrical как mini-scope категорию.
- Electrical строится вокруг электрических точек, а не вокруг отдельных сценариев.
- Каждая electrical point является самостоятельным mini-ТЗ внутри одного заказа.
- Категория поддерживает смешанные типы работ внутри одного заказа.

Mini-Scope Architecture:
- Клиент создаёт один заказ Electrical.
- Клиент добавляет одну или несколько электрических точек.
- Для каждой точки клиент выбирает Work Type.
- Для каждой точки клиент выбирает Equipment Type.
- Для каждой точки клиент добавляет required photos.
- Итоговое ТЗ заказа состоит из набора electrical points.

Work Type:
- Install & Connect.
- Replacement.
- Relocation.

Equipment Type on launch:
- Socket.
- Switch.

Future Equipment Types:
- Ceiling Light.
- Wall Light.
- Chandelier.
- Dimmer.
- Motion Sensor.
- Doorbell.
- USB Socket.
- Network Outlet.
- TV Outlet.
- Ceiling Fan.
- Exhaust Fan.
- Circuit Breaker.

Launch Boundary:
- На запуске Electrical поддерживает только Socket и Switch.
- Работы с электрощитом, автоматами, новой линией, скрытой проводкой, диагностикой неисправностей и высокорисковыми электрическими работами не входят в MVP.
- Future Equipment Types могут быть добавлены позже без изменения mini-scope architecture.

### Electrical Entry Flow
Status: APPROVED / STORED ✅

Entry Flow:
1. Клиент выбирает категорию Electrical.
2. Система создаёт первую electrical point.
3. Клиент выбирает Work Type:
   - Install & Connect.
   - Replacement.
   - Relocation.
4. Клиент выбирает Equipment Type:
   - Socket.
   - Switch.
5. Клиент отвечает на вопросы для выбранной точки.
6. Клиент добавляет фотографии для выбранной точки.
7. Клиент может добавить следующую electrical point через Add More.
8. Клиент указывает желаемую стоимость всего заказа.
9. Финальная стоимость фиксируется после общения клиента и мастера в чате.

Add More Rule:
- Клиент может добавить одну или несколько электрических точек через кнопку «Добавить ещё».
- Количество точек не задаётся отдельным вопросом.
- Количество точек определяется количеством созданных mini-ТЗ.
- В одном заказе могут быть разные Work Type и разные Equipment Type.

Pricing Rule:
- Клиент указывает желаемую стоимость всего заказа.
- Мастер оценивает весь набор electrical points до отклика.
- Если объём работ, материалы или сложность требуют изменения цены, мастер обосновывает изменение через чат.
- Изменение Final Agreed Price возможно только один раз и только до выбора мастера клиентом.

Photo Limit:
- Общий лимит фотографий заказа — 10.
- Каждая electrical point должна иметь фотографии, достаточные для идентификации точки работ.
- Одно фото может покрывать несколько точек, если они хорошо различимы.
- Фотография оборудования не заменяет фото фронта работ.

Equipment Verification Rule:
- Если новые изделия уже есть на объекте, клиент добавляет фото общего вида этих изделий.
- Одно фото может покрывать несколько одинаковых изделий, если мастер видит тип, модель и количество.
- Если изделия ещё не куплены, совместимость и материалы уточняются через чат.

### Electrical Point Mini-TZ Standard
Status: APPROVED / STORED ✅

Назначение:
- Electrical Point Mini-TZ описывает одну электрическую точку внутри заказа Electrical.
- Одна электрическая точка может быть розеткой или выключателем на запуске.
- Каждая точка имеет собственный Work Type, Equipment Type, structured questions и required photos.

Обязательные поля одной electrical point:
- Work Type.
- Equipment Type.
- Mounting Type.
- Required Photos.

Work Type Rules:
- Install & Connect применяется, когда требуется установить новое изделие без демонтажа существующего.
- Replacement применяется, когда требуется демонтировать существующее изделие и установить новое на его место.
- Relocation применяется, когда требуется перенести существующее изделие в новое место.
- Relocation может требовать дополнительных материалов, кабеля, штробления, сверления или отделочных работ; такие работы согласуются через чат до утверждения Final Agreed Price.

Mounting Type:
- Surface-mounted.
- Flush-mounted.
- Не знаю.

Safety Boundary:
- Клиент не обязан открывать электрощит.
- Клиент не обязан фотографировать автоматы, проводку или внутренние соединения.
- Клиент не обязан выполнять опасные действия для предоставления информации.
- Работы под напряжением запрещены.
- Перед началом работ мастер обязан отключить электропитание соответствующего участка.

### Electrical → Socket
Status: IN PROGRESS / QUALITY REWORK
Standard Compliance: Electrical Mini-Scope Standard ✅

Назначение:
- Эта mini-ТЗ сущность описывает работы с розеткой внутри Electrical.
- Socket является Equipment Type.
- Сценарии работ находятся внутри Socket.
- На запуске поддерживаются сценарии «Установить и подключить», «Заменить» и «Перенести».

Scope:
- Установить и подключить розетку.
- Заменить установленную розетку.
- Перенести установленную розетку.

Work Type:
- Установить и подключить.
- Заменить.
- Перенести.

Mounting Type:
- Накладная.
- Внутренняя.

Add More Rule:
- Клиент может добавить одну или несколько точек через кнопку «Добавить ещё».
- Количество точек не задаётся отдельным вопросом.
- Количество точек определяется количеством созданных mini-ТЗ.

#### Socket → Установить и подключить
Status: IN PROGRESS / QUALITY REWORK

Definition:
- Установка = монтаж и подключение.
- Одна точка установки = одно mini-ТЗ.

Вопросы — Установить и подключить:

1. Количество изделий:
- 1.
- 2.
- 3.
- Указать самостоятельно.

2. Тип установки:
- Накладная.
- Внутренняя.

Required Photos — Установить и подключить:

1. Фотография изделия/изделий.
- 1 обязательная фотография.
- До 2 дополнительных фотографий.

2. Фотография места установки розетки.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

3. Общая фотография зоны установки.
- 1 обязательная фотография.
- До 2 дополнительных фотографий.

#### Socket → Заменить
Status: IN PROGRESS / QUALITY REWORK

Definition:
- Замена = демонтаж + установка и подключение.
- Одна точка замены = одно mini-ТЗ.

Вопросы — Заменить:

1. Количество изделий:
- 1.
- 2.
- 3.
- Указать самостоятельно.

2. Тип установки:
- Накладная.
- Внутренняя.

Required Photos — Заменить:

1. Фотография нового изделия/изделий.
- 1 обязательная фотография.
- До 2 дополнительных фотографий.

2. Фотография установленной розетки.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

3. Общая фотография зоны замены/установки.
- 1 обязательная фотография.
- До 2 дополнительных фотографий.

#### Socket → Перенести
Status: IN PROGRESS / QUALITY REWORK

Definition:
- Перенос = демонтаж + установка и подключение в другой зоне.
- Одна точка переноса = одно mini-ТЗ.

Вопросы — Перенести:

1. Количество изделий:
- 1.
- 2.
- 3.
- Указать самостоятельно.

2. Тип установки:
- Накладная.
- Внутренняя.

Required Photos — Перенести:

1. Фотография установленного изделия/изделий.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

2. Фотография новой зоны установки.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

3. Фотография нового изделия/изделий.
- До 2 дополнительных фотографий.

Правила для клиента — Socket — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте доступ для работы с электрикой.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Socket — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте доступ для работы с электрикой.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила для клиента — Socket — Перенести:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Если вы не предоставили новое изделие, по умолчанию при переносе используется установленное изделие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте доступ для работы с электрикой.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Работы по отделке, такие как штукатурка, покраска и другие, не входят в базовую услугу.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Socket:

1. Проверка технического задания до отклика:
- Мастер изучает Work Type, Mounting Type, фотографии точки работ и информацию о новых изделиях.
- Мастер оценивает видимую готовность места работ, совместимость изделия и возможную потребность в дополнительных материалах.
- Если информации недостаточно для оценки объёма работ, мастер уточняет детали через чат до финального согласования цены.

2. Проверка условий на объекте:
- До начала работ мастер проверяет доступ к точке работ.
- Перед началом работ мастер обязан отключить электропитание соответствующего участка.
- Работы под напряжением запрещены.
- Если условия небезопасны, мастер фиксирует причину в чате до начала работ.

3. Выполнение работ:
- Мастер выполняет работы только в пределах согласованного объёма.
- Сценарий «Установить и подключить» включает установку новой розетки без демонтажа существующего изделия.
- Сценарий «Заменить» включает демонтаж + установку и подключение.
- Сценарий «Перенести» включает демонтаж + установку и подключение в новом месте.
- Если клиент не предоставил новое изделие, при переносе используется установленное изделие.
- Демонтированное изделие является собственностью клиента и остаётся на объекте по умолчанию.
- Вынос или утилизация демонтированного изделия выполняются только по отдельной договорённости через чат.
- Если требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.

4. Проверка результата:
- После завершения работ мастер обязан проверить базовую работоспособность розетки.
- Проверка результата не является диагностикой скрытых неисправностей электропроводки.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Platform Boundaries:
- Диагностика неисправностей розетки не входит в услугу.
- Работы с электрощитом не входят в MVP.
- Прокладка новой линии не входит в базовый объём услуги.
- Скрытые строительные работы не входят в базовый объём услуги.
- Дополнительные материалы согласуются через чат до утверждения Final Agreed Price.

Admin Dependencies:
- Work Type management.
- Equipment Type management.
- Mounting Type management.
- Question management.
- Required Photo management.
- Photo Limit management.
- Guidance Builder.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Electrical Readiness Rule.
- Client Rules Language Standard.
- Chat Evidence Rules.

### Electrical → Switch
Status: IN PROGRESS / QUALITY REWORK
Standard Compliance: Electrical Mini-Scope Standard ✅

Назначение:
- Эта mini-ТЗ сущность описывает работы с выключателем внутри Electrical.
- Switch является Equipment Type.
- Сценарии работ находятся внутри Switch.
- На запуске поддерживаются сценарии «Установить и подключить», «Заменить» и «Перенести».

Scope:
- Установить и подключить выключатель.
- Заменить установленный выключатель.
- Перенести установленный выключатель.

Work Type:
- Установить и подключить.
- Заменить.
- Перенести.

Mounting Type:
- Накладная.
- Внутренняя.

Add More Rule:
- Клиент может добавить одну или несколько точек через кнопку «Добавить ещё».
- Количество точек не задаётся отдельным вопросом.
- Количество точек определяется количеством созданных mini-ТЗ.

#### Switch → Установить и подключить
Status: IN PROGRESS / QUALITY REWORK

Definition:
- Установка = монтаж и подключение.
- Одна точка установки = одно mini-ТЗ.

Вопросы — Установить и подключить:

1. Количество изделий:
- 1.
- 2.
- 3.
- Указать самостоятельно.

2. Тип установки:
- Накладная.
- Внутренняя.

Required Photos — Установить и подключить:

1. Фотография изделия/изделий.
- 1 обязательная фотография.
- До 2 дополнительных фотографий.

2. Фотография места установки выключателя.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

3. Общая фотография зоны установки.
- 1 обязательная фотография.
- До 2 дополнительных фотографий.

#### Switch → Заменить
Status: IN PROGRESS / QUALITY REWORK

Definition:
- Замена = демонтаж + установка и подключение.
- Одна точка замены = одно mini-ТЗ.

Вопросы — Заменить:

1. Количество изделий:
- 1.
- 2.
- 3.
- Указать самостоятельно.

2. Тип установки:
- Накладная.
- Внутренняя.

Required Photos — Заменить:

1. Фотография нового изделия/изделий.
- 1 обязательная фотография.
- До 2 дополнительных фотографий.

2. Фотография установленного выключателя.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

3. Общая фотография зоны замены/установки.
- 1 обязательная фотография.
- До 2 дополнительных фотографий.

#### Switch → Перенести
Status: IN PROGRESS / QUALITY REWORK

Definition:
- Перенос = демонтаж + установка и подключение в другой зоне.
- Одна точка переноса = одно mini-ТЗ.

Вопросы — Перенести:

1. Количество изделий:
- 1.
- 2.
- 3.
- Указать самостоятельно.

2. Тип установки:
- Накладная.
- Внутренняя.

Required Photos — Перенести:

1. Фотография установленного изделия/изделий.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

2. Фотография новой зоны установки.
- 1 обязательная фотография.
- До 3 дополнительных фотографий.

3. Фотография нового изделия/изделий.
- До 2 дополнительных фотографий.

Правила для клиента — Switch — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте доступ для работы с электрикой.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Switch — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте доступ для работы с электрикой.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила для клиента — Switch — Перенести:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Если вы не предоставили новое изделие, по умолчанию при переносе используется установленное изделие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте доступ для работы с электрикой.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Работы по отделке, такие как штукатурка, покраска и другие, не входят в базовую услугу.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Switch:

1. Проверка технического задания до отклика:
- Мастер изучает Work Type, Mounting Type, фотографии точки работ и информацию о новых изделиях.
- Мастер оценивает видимую готовность места работ, совместимость изделия и возможную потребность в дополнительных материалах.
- Если информации недостаточно для оценки объёма работ, мастер уточняет детали через чат до финального согласования цены.

2. Проверка условий на объекте:
- До начала работ мастер проверяет доступ к точке работ.
- Перед началом работ мастер обязан отключить электропитание соответствующего участка.
- Работы под напряжением запрещены.
- Если условия небезопасны, мастер фиксирует причину в чате до начала работ.

3. Выполнение работ:
- Мастер выполняет работы только в пределах согласованного объёма.
- Сценарий «Установить и подключить» включает установку нового выключателя без демонтажа существующего изделия.
- Сценарий «Заменить» включает демонтаж + установку и подключение.
- Сценарий «Перенести» включает демонтаж + установку и подключение в новом месте.
- Если клиент не предоставил новое изделие, при переносе используется установленное изделие.
- Демонтированное изделие является собственностью клиента и остаётся на объекте по умолчанию.
- Вынос или утилизация демонтированного изделия выполняются только по отдельной договорённости через чат.
- Если требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.

4. Проверка результата:
- После завершения работ мастер обязан проверить базовую работоспособность выключателя.
- Проверка результата не является диагностикой скрытых неисправностей электропроводки.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Platform Boundaries:
- Диагностика неисправностей выключателя не входит в услугу.
- Работы с электрощитом не входят в MVP.
- Прокладка новой линии не входит в базовый объём услуги.
- Скрытые строительные работы не входят в базовый объём услуги.
- Дополнительные материалы согласуются через чат до утверждения Final Agreed Price.

Admin Dependencies:
- Work Type management.
- Equipment Type management.
- Mounting Type management.
- Question management.
- Required Photo management.
- Photo Limit management.
- Guidance Builder.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Electrical Readiness Rule.
- Client Rules Language Standard.
- Chat Evidence Rules.

### Electrical → Client Rules
Status: APPROVED / STORED ✅

Общие правила для клиента:
- Клиент отвечает только на вопросы, которые объективно понимает.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны обладать специальными знаниями в электрике.
- Вы не обязаны выполнять работы с электрикой.
- Вы не обязаны открывать электрощит.
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбирать оборудование.
- Вы не обязаны фотографировать автоматы, проводку и внутренние соединения.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте доступ для работы с электрикой.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Личные вещи клиента перемещает только клиент; мастер не обязан и не должен перемещать, сортировать или убирать личные вещи клиента.

Equipment Verification Rule:
- Если сценарий требует новое изделие, новое изделие должно быть на объекте до создания заказа.
- Если новое изделие отсутствует, создание заказа по этому сценарию невозможно.
- Фотография оборудования не заменяет фотографии фронта работ.
- Одно фото может покрывать несколько одинаковых изделий, если мастер видит тип, модель и количество.

Photo Coverage Rule:
- Фотографии должны обеспечивать визуальное покрытие фронта работ.
- Одно фото может покрывать несколько точек, если они хорошо различимы.
- Общий лимит фотографий заказа составляет 10.
- Дополнительные детали и материалы уточняются через чат.

### Electrical → Master Rules
Status: APPROVED / STORED ✅

Before Work:
- Мастер изучает все electrical points до отклика.
- Мастер оценивает Work Type, Equipment Type, Mounting Type, фотографии и возможную потребность в дополнительных материалах.
- Мастер оценивает достаточность информации.
- При необходимости мастер запрашивает уточнения через чат.
- Мастер предупреждает клиента о несовместимости оборудования или необходимости дополнительных материалов через чат.
- Изменение Final Agreed Price должно быть согласовано до выбора мастера клиентом.
- Мастер не принимает работы, выходящие за рамки MVP или связанные с запрещёнными высокорисковыми операциями.

During Work:
- Работы под напряжением запрещены.
- Перед началом работ мастер обязан отключить электропитание соответствующего участка.
- Мастер выполняет работы только в пределах согласованного объёма.
- Если требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.

After Work:
- Мастер обязан проверить базовую работоспособность выполненных работ.
- Проверка выполняется без специализированной диагностики скрытых неисправностей электропроводки.
- Мастер обязан убедиться в качестве выполненного монтажа.
- Мастер обязан оставить рабочее место в чистом и безопасном состоянии.

Safety Escalation:
- При обнаружении опасного состояния существующей электропроводки, оборудования или условий эксплуатации мастер обязан сообщить об этом клиенту через чат.
- Обнаружение опасности не обязывает мастера выполнять работы вне MVP или вне своей квалификации.
- Мастер вправе отказаться от продолжения работ, если дальнейшее выполнение создаёт угрозу жизни, здоровью или имуществу.

### Electrical → Admin Dependencies
Status: APPROVED / STORED ✅

Decision:
- Electrical does not introduce new admin modules beyond approved Helpy Admin / Dynamic Form capabilities.
- Electrical inherits the existing category, equipment type, work type, question, photo requirement, pricing, rule visibility and guidance administration model.
- Future Global Diagnostics must remain hidden from Electrical launch flow until approved.
- Disabled future branches remain configurable but hidden from launch UI.

Required Admin Capabilities:
- Electrical category enabled/disabled.
- Electrical mini-scope enabled/disabled.
- Equipment Type management.
- Work Type management.
- Mounting Type management.
- Question management by Equipment Type and Work Type.
- Required Photo management by Equipment Type and Work Type.
- Photo Limit management.
- Add More support.
- Total photo limit enforcement.
- Pricing guidance management.
- Rule visibility for client/master guidance.
- Guidance Builder support.
- Category Health Check.
- Rules Simulator.
- Impact Analysis.
- Registry Coverage.

Conclusion:
- No unresolved Electrical-specific Admin Dependencies remain.

Electrical Diagnostics:
Status: HISTORICAL — MOVED TO FUTURE GLOBAL DIAGNOSTICS

- Не работает розетка.
- Не работает выключатель.
- Нет света.
- Периодически пропадает питание.
- Искрит.
- Не знаю.
- Другое.

## 24. Service Architecture Registry — Plumbing
Status: CLOSED — STORED + DOCS VERIFIED

Decision Summary:
- Plumbing is fully recovered and verified.
- Registry evidence exists in approved documentation and stored archives.
- Faucet/Mixer, Blockage and Toilet branches are complete.
- Electric Shower installation and replacement branches remain approved.
- Electric Shower repair scenarios were later excluded by the approved Electrical Shower Policy contract.
- Legacy GAP has been aligned with current approved decisions.
- No unresolved architecture decisions remain at the Plumbing root level.

### Plumbing Registry Content

Plumbing
├── Кран
├── Засор
├── Унитаз
└── Проточный водонагреватель

## Plumbing Mini-TZ Standard

Status: APPROVED / STORED ✅

Назначение:
- Этот стандарт применяется к Plumbing mini-ТЗ внутри Service Architecture Registry — Plumbing.
- Стандарт фиксирует единый порядок проектирования сценариев установки, замены и простых problem-flow сценариев внутри Plumbing.
- Plumbing Mini-TZ Standard используется для снижения дублей, устранения терминологических расхождений и подготовки старых Plumbing-блоков к переносу в Dart-модель без костылей.
- Вопрос «Что требуется сделать?» остаётся внутри mini-ТЗ, потому что Plumbing не является mini-scope / add-more веткой.
- Initial structured job scope формируется через выбранный сценарий, structured questions, client answers и required photos.

Базовое правило сценариев установки и замены:
- Сценарий «Установить новый» применяется, когда новое оборудование физически находится на объекте и требуется монтаж, подключение и базовая проверка результата.
- Сценарий «Заменить установленный» применяется, когда новое оборудование физически находится на объекте, а установленное оборудование требуется демонтировать перед монтажом нового.
- Сценарий «Заменить установленный» использует правила сценария «Установить новый» после завершения демонтажа установленного оборудования, если иное не указано явно.
- Отдельный демонтаж оборудования не является самостоятельным MVP-сценарием Plumbing, если он не утверждён отдельным mini-ТЗ.

Problem-Flow Rule:
- Problem-flow сценарии Plumbing допускаются только там, где они утверждены явно.
- Problem-flow сценарий не должен превращаться в свободную диагностику без границ.
- Если сценарий требует диагностики, но диагностика не утверждена для этой ветки, сценарий должен быть исключён из MVP или перенесён в будущий Global Diagnostics Pattern.
- Засор и неисправность бачка унитаза являются утверждёнными bounded problem-flow сценариями Plumbing.

Алгоритм работы мастера для install / replace сценариев:
1. Проверка совместимости до начала работ.
2. Проверка оборудования до установки.
3. Демонтаж установленного оборудования — только для сценария «Заменить установленный».
4. Установка и подключение.
5. Проверка подключений.
6. Проверка результата / работоспособности.
7. Проверка качества результата, если такая проверка явно описана в mini-ТЗ конкретной ветки.

Правило проверки совместимости:
- До начала вскрытия упаковки, демонтажа или установки мастер обязан убедиться, что оборудование подходит для данного объекта.
- Проверка включает совместимость оборудования с местом установки и точками подключения в пределах информации, доступной до начала работ.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения до продолжения работ.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

Правило проверки оборудования:
- До установки мастер обязан выполнить визуальный осмотр оборудования.
- Проверка включает наличие видимых механических повреждений и комплектность в пределах штатных элементов установки или подключения.
- При обнаружении повреждений или отсутствия необходимых штатных элементов мастер обязан зафиксировать это на фотографиях и направить клиенту через чат приложения до продолжения работ.
- Если клиент подтверждает продолжение работ, подтверждение клиента и фотографии становятся частью доказательной базы заказа.

Правило демонтажа:
- Демонтаж установленного оборудования применяется только в сценарии «Заменить установленный».
- Демонтаж выполняется в пределах стоимости услуги замены.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.
- Мастер не обязан забирать, выносить или утилизировать демонтированное оборудование.
- Вынос или утилизация демонтированного оборудования не входят в базовую стоимость услуги и могут быть согласованы отдельно через чат.

Правило установки и подключения:
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Если доступ ограничен или требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.
- Упаковка оборудования является собственностью клиента.
- Вынос или утилизация упаковки не входят в стоимость услуги.

Правило проверки результата:
- После завершения работ мастер обязан проверить результат в пределах согласованного объёма заказа.
- Проверка выполняется безопасным способом и только в рамках характера выполненных работ.
- Проверка результата не является диагностикой скрытых дефектов, если диагностика не утверждена отдельным сценарием.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Photo Scope Rule:
- Required photos должны закрывать визуальную часть initial structured job scope.
- Мастер не может запрашивать дополнительные фотографии в чате, если required photos уже определены формой.
- Дополнительные фото допускаются только как evidence после начала работ или как часть утверждённого completion/evidence flow.
- Общий лимит фотографий заказа составляет 10, если для конкретной ветки не утверждён иной лимит.

Terminology Normalization Rule:
- Для оборудования, находящегося на объекте до начала работ, используется термин «установленное оборудование».
- Примеры:
  - установленный кран;
  - установленный унитаз;
  - установленный электрический душ;
  - демонтаж установленного оборудования.
- Термин «существующий» используется для инфраструктуры объекта и элементов, не являющихся оборудованием.
- Примеры:
  - существующая система водоотведения;
  - существующий вывод водоотведения;
  - существующее подключение;
  - существующая электропроводка;
  - существующая точка подключения воды.
- Формулировка «существующее оборудование» не используется.

- Для install-сценариев используется формулировка «Установить и подключить <оборудование>».
- Формулировка «Установить новый <оборудование>» не используется.
- В вопросе наличия оборудования используется формулировка «<Оборудование> находится на объекте?».
- Формулировка «Новый <оборудование> находится на объекте?» не используется.
- Для stop-message используется формулировка «наличие приобретённого оборудования на объекте».
- Формулировка «наличие нового оборудования на объекте» не используется.
- В обязательных фотографиях используется формулировка «Фото оборудования в упаковке».
- Формулировка «Фото нового оборудования в упаковке» используется только в сценарии замены, если нужно явно отделить приобретаемое оборудование от установленного оборудования.
- Для фото упаковки используется формулировка «Фото упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией».
- Формулировка «Фото упаковки нового оборудования...» не используется.
- В шаблонных правилах клиента, мастера, фотографий и проверок используется термин «оборудование», если конкретизация сущности не нужна.
- Для replacement-сценариев используется формулировка «Проверка оборудования до демонтажа установленного».
- Формулировка «Проверка нового оборудования до демонтажа установленного» не используется.

Применение:
- Future Plumbing branches должны проектироваться по Plumbing Mini-TZ Standard, если не утверждено отдельное исключение.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.
- Global Electrical Readiness Rule, если Plumbing-сценарий включает электрическое оборудование.

### Plumbing → Кран

Status: APPROVED / STORED ✅
Standard Compliance: Plumbing Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку и подключение крана и замену установленного крана внутри Plumbing.
- Вопрос «Что требуется сделать?» остаётся внутри mini-ТЗ, потому что Plumbing не является mini-scope / add-more веткой.
- Установка включает монтаж, подключение воды и базовую проверку результата.
- Замена состоит из демонтажа установленного крана и последующего выполнения сценария «Установить и подключить кран».
- Сценарии «не работает», «протекает» и «другая проблема» исключены из MVP.

Вопросы:

1. Что требуется сделать?
- Установить и подключить кран.
- Заменить установленный кран.

Если выбрано «Установить и подключить кран»:

2. Кран находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для установки крана требуется наличие приобретённого крана на объекте.

[Понятно]

3. Где будет установлен и подключён кран?
- Раковина.
- Кухня.
- Душ.
- Балкон.

Если выбрано «Заменить установленный кран»:

2. Кран находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для замены крана требуется наличие приобретённого крана на объекте.

[Понятно]

3. Где нужно заменить кран?
- Раковина.
- Кухня.
- Душ.
- Балкон.

Правила вопросов:
- Тип крана не спрашивается.
- Тип монтажа не спрашивается.
- Тип подключения не спрашивается.
- Длина подводки не спрашивается.
- Наличие переходников, прокладок и расходников не спрашивается.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Исключено из MVP:
- Кран не работает.
  - Причина: обычно ведёт к замене и не создаёт достаточной ценности как отдельная ветка.
- Кран протекает.
  - Причина: часто создаёт мелкие диагностические или материальные выезды и отвлекает мастеров от предсказуемых заказов.
- Другая проблема.
  - Причина: вне установки и замены не выявлены отдельные MVP-сценарии.

Обязательные фотографии — Установить и подключить кран — Раковина:

1. Фотография установленной раковины.
- 1 обязательная фотография.

2. Фотография оборудования в упаковке.
- 1 обязательная фотография.

3. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

4. Фотография точек подключения воды.
- 1 обязательная фотография.

5. Фотография, позволяющая оценить расстояние от места установки до точек подключения воды.
- 1 обязательная фотография.

Дополнительные фотографии — Установить и подключить кран — Раковина:

1. Фотография пространства под раковиной.
- До 1 дополнительной фотографии.

Лимит фотографий — Установить и подключить кран — Раковина:
- Обязательные: 5 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 9 из 10 фотографий.

Обязательные фотографии — Установить и подключить кран — Кухня:

1. Фотография установленной кухонной мойки сверху.
- 1 обязательная фотография.

2. Фотография оборудования в упаковке.
- 1 обязательная фотография.

3. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

4. Фотография точек подключения воды под кухонной мойкой.
- 1 обязательная фотография.

5. Фотография пространства под кухонной мойкой.
- 1 обязательная фотография.

Дополнительные фотографии — Установить и подключить кран — Кухня:

1. Фотография, позволяющая оценить расстояние от места установки до точек подключения воды.
- До 1 дополнительной фотографии.

Лимит фотографий — Установить и подключить кран — Кухня:
- Обязательные: 5 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 9 из 10 фотографий.

Обязательные фотографии — Установить и подключить кран — Душ:

1. Фотография зоны душа.
- 1 обязательная фотография.

2. Фотография оборудования в упаковке.
- 1 обязательная фотография.

3. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

4. Фотография места установки.
- 1 обязательная фотография.

5. Фотография точек подключения воды.
- 1 обязательная фотография.

Лимит фотографий — Установить и подключить кран — Душ:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Обязательные фотографии — Установить и подключить кран — Балкон:

1. Фотография места установки.
- 1 обязательная фотография.

2. Фотография оборудования в упаковке.
- 1 обязательная фотография.

3. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

4. Фотография точек подключения воды.
- 1 обязательная фотография.

Лимит фотографий — Установить и подключить кран — Балкон:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Обязательные фотографии — Заменить установленный кран:
- Используются фотографии сценария «Установить и подключить кран» для выбранного места установки.
- Дополнительно клиент прикрепляет фотографии установленного крана по правилам ниже.

Обязательные фотографии — Заменить установленный кран — Раковина:

1. Фотография установленного крана.
- 1 обязательная фотография.

2. Фотография крепления снизу.
- До 1 дополнительной фотографии.

Обязательные фотографии — Заменить установленный кран — Кухня:

1. Фотография установленного крана.
- 1 обязательная фотография.

2. Фотография крепления снизу.
- До 1 дополнительной фотографии.

Обязательные фотографии — Заменить установленный кран — Душ:

1. Фотография установленного крана в зоне душа.
- 1 обязательная фотография.

Обязательные фотографии — Заменить установленный кран — Балкон:

1. Фотография установленного крана.
- 1 обязательная фотография.

Лимит фотографий — Заменить установленный кран — Раковина:
- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

Лимит фотографий — Заменить установленный кран — Кухня:
- Обязательные: 6 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 10 из 10 фотографий.

Лимит фотографий — Заменить установленный кран — Душ:
- Обязательные: 6 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 9 из 10 фотографий.

Лимит фотографий — Заменить установленный кран — Балкон:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Plumbing → Электрический душ

Status: APPROVED / STORED ✅
Standard Compliance: Plumbing Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку и подключение электрического душа, а также замену установленного электрического душа внутри Plumbing.
- Вопрос «Что требуется сделать?» остаётся внутри mini-ТЗ, потому что Plumbing не является mini-scope / add-more веткой.
- Установка включает монтаж, подключение воды, подключение к электрической точке и базовую проверку результата.
- Замена состоит из демонтажа установленного электрического душа и последующего выполнения сценария «Установить и подключить электрический душ».
- Диагностика и ремонт электрических душей исключены согласно утверждённому Electrical Shower Policy contract.

Вопросы:

1. Что требуется сделать?
- Установить и подключить электрический душ.
- Заменить установленный электрический душ.

Если выбрано «Установить и подключить электрический душ»:

2. Электрический душ находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для установки электрического душа требуется наличие приобретённого оборудования на объекте.

[Понятно]

3. Заливной шланг уже куплен?
- Да.
- Нет.

Если выбрано «Заменить установленный электрический душ»:

2. Электрический душ находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для замены электрического душа требуется наличие приобретённого оборудования на объекте.

[Понятно]

3. Новый заливной шланг нужен?
- Да.
- Нет.

Правила вопросов:
- Тип электрического душа не спрашивается.
- Мощность электрического душа не спрашивается.
- Тип электрического подключения не спрашивается.
- Наличие заземления не спрашивается.
- Тип автомата защиты не спрашивается.
- Длина заливного шланга не измеряется клиентом.
- Наличие или отсутствие заливного шланга не является stop-сценарием.
- Вы не обязаны разбираться в технических характеристиках.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.
- Электрическая готовность регулируется Global Electrical Readiness Rule.

Исключено из MVP:
- Плохо греет воду.
- Протекает.
- Выбивает автомат / отключается электричество.

Правило исключения:
- Сценарии ремонта электрического душа не возвращаются в MVP-обсуждение до запуска.

Обязательные фотографии — Установить и подключить электрический душ:

1. Фотография оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

3. Фотография места установки электрического душа.
- 1 обязательная фотография.

4. Фотография точки подключения воды.
- 1 обязательная фотография.

5. Фотография точки подключения электропитания.
- 1 обязательная фотография.

Лимит фотографий — Установить и подключить электрический душ:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Обязательные фотографии — Заменить установленный электрический душ:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

3. Фотография установленного электрического душа.
- 1 обязательная фотография.

4. Фотография точки подключения воды.
- 1 обязательная фотография.

5. Фотография точки подключения электропитания.
- 1 обязательная фотография.

Лимит фотографий — Заменить установленный электрический душ:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер обязан проверить отсутствие протечек.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Мастер обязан проверить отсутствие протечек.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан убедиться, что органы управления реагируют на команды.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.
Наследуемые правила:
- Global Materials Separation Rule.
- Global Electrical Readiness Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Plumbing → Унитаз

Status: APPROVED / STORED ✅
Standard Compliance: Plumbing Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку и подключение унитаза и замену установленного унитаза внутри Plumbing.
- Вопрос «Что требуется сделать?» остаётся внутри mini-ТЗ, потому что Plumbing не является mini-scope / add-more веткой.
- Установка включает монтаж, подключение воды, подключение канализационного выпуска и базовую проверку результата.
- Замена состоит из демонтажа установленного унитаза и последующего выполнения сценария «Установить и подключить унитаз».

Launch Decision:
- В MVP активны только сценарии установки и замены унитаза.
- Сценарии «Не набирается вода в бачок» и «Вода постоянно течёт в чашу» отключены на запуске.
- Документация по отключённым сценариям сохранена в реестре для возможного возврата после анализа реальной статистики.

Reason:
- Сценарии неисправности бачка относятся к диагностике и ремонту.
- Диагностика и ремонт не входят в текущую install/replace философию MVP.
- Сценарии могут потребовать подбора деталей, вскрытия доступа, уточнения причины неисправности и расширенного согласования цены.
- После запуска они могут быть возвращены как отдельная сущность устранения неисправностей.

Вопросы:

1. Что требуется сделать?
- Установить и подключить унитаз.
- Заменить установленный унитаз.

Если выбрано «Установить и подключить унитаз»:

2. Унитаз находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для установки унитаза требуется наличие приобретённого унитаза на объекте.

[Понятно]

Если выбрано «Заменить установленный унитаз»:

2. Унитаз находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для замены унитаза требуется наличие приобретённого унитаза на объекте.

[Понятно]

Conserved Branches:
- Не набирается вода в бачок.
- Вода постоянно течёт в чашу.

Status: APPROVED / DISABLED ON LAUNCH / STORED + DOCS ✅

Stored Documentation:
- Дополнительных вопросов нет.

Правила вопросов:
- Тип унитаза не спрашивается.
- Тип выпуска не спрашивается.
- Тип подключения воды не спрашивается.
- Тип бачка не спрашивается.
- Наличие инсталляции не спрашивается.
- Размеры унитаза не спрашиваются.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить и подключить унитаз:

1. Фотография места установки.
- 1 обязательная фотография.

2. Фотография оборудования в упаковке.
- 1 обязательная фотография.

3. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

4. Фотография точки подключения воды.
- 1 обязательная фотография.

5. Фотография отверстия для слива сточных вод.
- 1 обязательная фотография.

Лимит фотографий — Установить и подключить унитаз:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Обязательные фотографии — Заменить установленный унитаз:

1. Фотография нового оборудования в упаковке.
- 1 обязательная фотография.

2. Фотографии упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

3. Фотография установленного унитаза.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

4. Фотография точки подключения воды.
- 1 обязательная фотография.

5. Фотография отверстия для слива сточных вод.
- 1 обязательная фотография.

Лимит фотографий — Заменить установленный унитаз:
- Обязательные: 5 фотографий.
- Дополнительные: до 4 фотографий.
- Всего: до 9 из 10 фотографий.

Stored Documentation — Обязательные фотографии — Неисправность бачка унитаза:

1. Общий вид унитаза.
- До 2 фотографий:
  - 1 обязательная;
  - до 1 дополнительной.

2. Фотография чаши сверху.
- 1 обязательная фотография.

3. Фотография бачка сверху.
- 1 обязательная фотография.

Stored Documentation — Лимит фотографий — Неисправность бачка унитаза:
- Обязательные: 3 фотографии.
- Дополнительные: до 1 фотографии.
- Всего: до 4 из 10 фотографий.

Stored Documentation — Не требуется — Неисправность бачка унитаза:
- Фотография бачка с открытой крышкой.
- Фотография узла подачи воды.

Правила для клиента — Установить и подключить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.

Правила для клиента — Заменить:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Уберите документы, деньги и ценные вещи до начала работ.
- Уберите домашних животных из рабочей зоны.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Установить и подключить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

4. Проверка работоспособности:
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Правила выполнения работ мастером — Заменить:

1. Проверка совместимости до начала работ:
- Перед распаковкой мастер обязан убедиться в наличии технической возможности установки и подключения оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения.

2. Проверка оборудования до установки и подключения:
- Мастер обязан выполнить осмотр оборудования на наличие механических повреждений.
- При выявлении повреждений мастер обязан направить фотографии клиенту через чат приложения до продолжения работ.
- При подтверждении клиентом продолжения работ фотографии становятся доказательной базой заказа.
- Мастер обязан проверить комплектацию оборудования и наличие штатных элементов установки и подключения.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

3. Демонтаж оборудования:
- Мастер выполняет отключение и демонтаж оборудования в пределах стоимости услуги.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.

4. Установка и подключение:
- Дополнительные комплектующие и расходные материалы являются отдельной договорённостью между клиентом и мастером.
- Мастер обязан использовать штатные элементы установки и подключения, предусмотренные производителем.
- Подключение оборудования выполняется в соответствии с требованиями производителя.
- Мастер устанавливает и подключает оборудование в пределах стоимости услуги.
- Утилизация упаковки не входит в стоимость услуги, поскольку является собственностью клиента.

5. Проверка работоспособности:
- Мастер обязан проверить отсутствие протечек.
- Мастер обязан подтвердить корректную работу оборудования в пределах стоимости услуги.

Stored Documentation — Правила выполнения работ мастером — Неисправность бачка унитаза:

1. Проверка границ сценария:
- Мастер выполняет работу только при наличии доступа к бачку и его механизмам.
- Если доступ отсутствует и требуется демонтаж стены, короба, плитки или иных строительных конструкций, такие работы не входят в данную услугу.
- Работы по обеспечению доступа рассматриваются как отдельная услуга и согласовываются отдельно.
- Наличие инсталляции само по себе не является ограничением.
- Если предусмотрен сервисный доступ к механизму, работа выполняется в рамках данной услуги.

2. Выполнение работ:
- Мастер устраняет заявленную неисправность бачка в пределах стоимости услуги.
- Если требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.
- Диагностика иных сантехнических проблем не входит в данный bounded problem-flow сценарий.

3. Проверка результата:
- После выполнения работ мастер обязан проверить набор воды в бачок.
- Мастер обязан проверить прекращение набора воды после заполнения бачка.
- Мастер обязан проверить отсутствие постоянного течения воды в чашу.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Plumbing → Засор

Status: APPROVED / DISABLED ON LAUNCH / STORED + DOCS ✅
Standard Compliance: Plumbing Mini-TZ Standard ✅

Launch Decision:
- Сценарий «Засор» отключён на запуске MVP.
- Может быть возвращён после анализа реальной статистики использования платформы.

Reason:
- Сценарий устранения засора относится к problem-flow, а не к install/replace логике MVP.
- Может требовать диагностики причины засора, дополнительных работ и изменения объёма заказа.
- Требует отдельной проработки после запуска основных сценариев Plumbing.

Stored Documentation:

Вопросы:

1. Где засор?
- Раковина.
- Кухонная мойка.
- Душевой слив.
- Унитаз.

2. Что происходит?
- Вода уходит медленно.
- Вода не уходит совсем.

Дополнительных вопросов нет.

Правила вопросов:
- Техническая причина засора не спрашивается.
- Что клиент уже пробовал, не спрашивается.
- Свободное описание проблемы не спрашивается.
- Эти детали не влияют на initial structured job scope.
- Эти детали не влияют на стартовую цену.
- Эти детали не влияют на обязательные фотографии.
- При необходимости мастер уточняет детали через чат.

Обязательные фотографии — Засор — Раковина:

1. Вид раковины сбоку так, чтобы были видны чаша и сливное отверстие.
- 1 обязательная фотография.

2. Фотография пространства под раковиной с видом на сифон.
- 1 обязательная фотография.

Лимит фотографий — Засор — Раковина:
- Обязательные: 2 фотографии.
- Дополнительные: 0 фотографий.
- Всего: 2 из 10 фотографий.

Обязательные фотографии — Засор — Кухонная мойка:

1. Вид мойки сбоку так, чтобы были видны чаша и сливное отверстие.
- 1 обязательная фотография.

2. Фотография пространства под мойкой с видом на сифон.
- 1 обязательная фотография.

Лимит фотографий — Засор — Кухонная мойка:
- Обязательные: 2 фотографии.
- Дополнительные: 0 фотографий.
- Всего: 2 из 10 фотографий.

Обязательные фотографии — Засор — Душевой слив:

1. Фотография зоны душа.
- 1 обязательная фотография.

2. Фотография сливного трапа крупным планом.
- 1 обязательная фотография.

Лимит фотографий — Засор — Душевой слив:
- Обязательные: 2 фотографии.
- Дополнительные: 0 фотографий.
- Всего: 2 из 10 фотографий.

Обязательные фотографии — Засор — Унитаз:

1. Общий вид унитаза.
- 1 обязательная фотография.

2. Фотография чаши сверху.
- 1 обязательная фотография.

Лимит фотографий — Засор — Унитаз:
- Обязательные: 2 фотографии.
- Дополнительные: 0 фотографий.
- Всего: 2 из 10 фотографий.

Правила для клиента — Засор:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны знать техническую причину засора.
- Вы не обязаны описывать проблему в свободной форме.
- Вы не обязаны самостоятельно разбирать систему водоотведения, трап, унитаз или другие элементы сантехники.
- Вы не обязаны самостоятельно устранять засор до приезда мастера.
- Предоставьте обязательные фотографии по выбранному месту засора.
- Подготовьте доступ к месту засора.
- Подготовьте безопасные условия для выполнения работ.

Правила выполнения работ мастером — Засор:

1. Проверка initial structured job scope:
- Мастер изучает выбранное место засора, симптом и фотографии до отклика.
- Если мастеру важно знать, что клиент уже пробовал, он может уточнить это через чат.
- Мастер не может запрашивать дополнительные фотографии в чате.

2. Выполнение работ:
- Мастер устраняет засор в пределах стоимости услуги.
- Если после уточнений выявлены дополнительные работы, мастер обязан обосновать изменение окончательной стоимости через чат.
- Изменение Final Agreed Price возможно только один раз и только до выбора мастера клиентом.
- Если требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.

3. Проверка результата:
- После выполнения работ мастер обязан проверить восстановление нормального отвода воды в пределах выбранного места засора.
- Проверка выполняется безопасным способом и только в рамках характера выполненных работ.
- Проверка результата не является диагностикой скрытых дефектов Plumbing.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

## 25. Service Architecture Registry — Locks
Status: CLOSED — STORED + DOCS VERIFIED

Decision Summary:
- Locks is fully recovered and verified.
- Registry evidence exists in approved documentation and stored archives.
- Locks remains a standalone Helpy root category.
- Locks is not moved into Handyman.
- Internal category contracts remain unchanged.
- The current Registry Review completes the previous final audit GAP.
- No unresolved architecture decisions remain at the Locks root level.

Registry Status: STORED + DOCS VERIFIED ✅

Root Category:
Locks (Замки)

Business Scope:
- Категория предназначена только для работ внутри объекта клиента.
- Категория не является аварийной службой вскрытия.
- Категория не работает с входными дверями.

Approved Subcategories:
1. Замена замка межкомнатной двери
2. Установка замка межкомнатной двери
3. Замена мебельного замка
4. Установка врезного мебельного замка

Excluded From MVP:
- Входные двери
- Вскрытие помещений
- Аварийное открытие дверей
- Замена личинки
- Скобяные задвижки
- Работы со стеклом
- Врезка замка в стекло
- Отдельные подкатегории для шкафов, тумб, комодов, ящиков и витрин

Business Rules:
- Helpy не оказывает услуги вскрытия входных дверей.
- Helpy не работает с вопросами собственности, аренды и права доступа.
- Работы выполняются внутри объекта клиента.
- Работы в публичных зонах не входят в MVP.
- Замена = демонтаж старого элемента + монтаж нового элемента.
- Установка = монтаж нового элемента без демонтажа существующего.
- Клиент выбирает результат, а не технологию выполнения работ.
- Технические детали определяет мастер.

## Locks Mini-TZ Standard

Status: APPROVED / STORED ✅

Назначение:
- Этот стандарт применяется к Locks mini-ТЗ внутри Service Architecture Registry — Locks.
- Стандарт фиксирует единый порядок проектирования сценариев установки, замены и простых problem-flow сценариев внутри Locks.
- Locks Mini-TZ Standard используется для снижения дублей, устранения терминологических расхождений и подготовки старых Locks-блоков к переносу в Dart-модель без костылей.
- Вопрос «Что требуется сделать?» остаётся внутри mini-ТЗ, потому что Locks не является mini-scope / add-more веткой.
- Initial structured job scope формируется через выбранный сценарий, structured questions, client answers и required photos.

Базовое правило сценариев установки и замены:
- Сценарий «Установить» применяется, когда приобретённое оборудование физически находится на объекте и требуется монтаж и базовая проверка результата.
- Сценарий «Заменить установленный» применяется, когда приобретённое оборудование физически находится на объекте, а установленное оборудование требуется демонтировать перед монтажом приобретённого оборудования.
- Сценарий «Заменить установленный» использует правила сценария «Установить» после завершения демонтажа установленного оборудования, если иное не указано явно.
- Отдельный демонтаж оборудования не является самостоятельным MVP-сценарием Locks, если он не утверждён отдельным mini-ТЗ.

Problem-Flow Rule:
- Problem-flow сценарии Locks допускаются только там, где они утверждены явно.
- Problem-flow сценарий не должен превращаться в свободную диагностику без границ.
- Если сценарий требует диагностики, но диагностика не утверждена для этой ветки, сценарий должен быть исключён из MVP или перенесён в будущий Global Diagnostics Pattern.
- Problem-flow сценарии Locks должны быть утверждены явно перед добавлением в MVP.

Алгоритм работы мастера для install / replace сценариев:
1. Проверка совместимости до начала работ.
2. Проверка оборудования до установки.
3. Демонтаж установленного оборудования — только для сценария «Заменить установленный».
4. Установка.
5. Проверка работы механизма.
6. Проверка результата / работоспособности.
7. Проверка качества результата, если такая проверка явно описана в mini-ТЗ конкретной ветки.

Правило проверки совместимости:
- До начала вскрытия упаковки, демонтажа или установки мастер обязан убедиться, что оборудование подходит для данного объекта.
- Проверка включает совместимость оборудования с местом установки и точками подключения в пределах информации, доступной до начала работ.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения до продолжения работ.
- Мастер вправе отказаться от продолжения работ, если безопасное выполнение работ невозможно.

Правило проверки оборудования:
- До установки мастер обязан выполнить визуальный осмотр оборудования.
- Проверка включает наличие видимых механических повреждений и комплектность в пределах штатных элементов установки или подключения.
- При обнаружении повреждений или отсутствия необходимых штатных элементов мастер обязан зафиксировать это на фотографиях и направить клиенту через чат приложения до продолжения работ.
- Если клиент подтверждает продолжение работ, подтверждение клиента и фотографии становятся частью доказательной базы заказа.

Правило демонтажа:
- Демонтаж установленного оборудования применяется только в сценарии «Заменить установленный».
- Демонтаж выполняется в пределах стоимости услуги замены.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.
- Мастер не обязан забирать, выносить или утилизировать демонтированное оборудование.
- Вынос или утилизация демонтированного оборудования не входят в базовую стоимость услуги и могут быть согласованы отдельно через чат.

Правило установки:
- Мастер устанавливает оборудование в пределах стоимости услуги.
- Если доступ ограничен или требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.
- Упаковка оборудования является собственностью клиента.
- Вынос или утилизация упаковки не входят в стоимость услуги.

Правило проверки результата:
- После завершения работ мастер обязан проверить результат в пределах согласованного объёма заказа.
- Проверка выполняется безопасным способом и только в рамках характера выполненных работ.
- Проверка результата не является диагностикой скрытых дефектов, если диагностика не утверждена отдельным сценарием.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Photo Scope Rule:
- Required photos должны закрывать визуальную часть initial structured job scope.
- Мастер не может запрашивать дополнительные фотографии в чате, если required photos уже определены формой.
- Дополнительные фото допускаются только как evidence после начала работ или как часть утверждённого completion/evidence flow.
- Общий лимит фотографий заказа составляет 10, если для конкретной ветки не утверждён иной лимит.

Terminology Normalization Rule:
- Для оборудования, находящегося на объекте до начала работ, используется термин «установленное оборудование».
- Примеры:
  - установленный замок;
  - установленный мебельный замок;
  - установленная фурнитура;
  - демонтаж установленного оборудования.
- Термин «существующий» используется для инфраструктуры объекта и элементов, не являющихся оборудованием.
- Примеры:
  - существующая дверь;
  - существующее полотно двери;
  - существующий фасад мебели;
  - существующее посадочное место;
  - существующее отверстие под замок.
- Формулировка «существующее оборудование» не используется.

- Для install-сценариев внутри Locks используется формулировка «Установить <оборудование>».
- Формулировки «Установить новый <оборудование>» и «Установить и подключить <оборудование>» не используются внутри Locks.
- В вопросе наличия оборудования используется формулировка «<Оборудование> находится на объекте?».
- Формулировка «Новый <оборудование> находится на объекте?» не используется.
- Для stop-message используется формулировка «наличие приобретённого оборудования на объекте».
- Формулировка «наличие нового оборудования на объекте» не используется.
- В обязательных фотографиях используется формулировка «Фото оборудования в упаковке».
- Формулировка «Фото нового оборудования в упаковке» используется только в сценарии замены, если нужно явно отделить приобретаемое оборудование от установленного оборудования.
- Для фото упаковки используется формулировка «Фото упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией».
- Формулировка «Фото упаковки нового оборудования...» не используется.
- В шаблонных правилах клиента, мастера, фотографий и проверок используется термин «оборудование», если конкретизация сущности не нужна.
- Для replacement-сценариев используется формулировка «Проверка оборудования до демонтажа установленного».
- Формулировка «Проверка нового оборудования до демонтажа установленного» не используется.

Применение:
- Замена замка межкомнатной двери должна быть приведена к Locks Mini-TZ Standard.
- Установка замка межкомнатной двери должна быть приведена к Locks Mini-TZ Standard.
- Замена мебельного замка должна быть приведена к Locks Mini-TZ Standard.
- Установка врезного мебельного замка должна быть приведена к Locks Mini-TZ Standard.
- Future Locks branches должны проектироваться по Locks Mini-TZ Standard, если не утверждено отдельное исключение.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Locks → Установка замка межкомнатной двери

Status: APPROVED / STORED ✅
Standard Compliance: Locks Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку замка межкомнатной двери внутри Locks.
- Установка включает монтаж замка, возможную подготовку посадочного места и базовую проверку работы механизма.
- Врезка может быть частью работы, но не выносится в название услуги.
- Сценарий не является ремонтом замка, аварийным вскрытием или диагностикой права доступа.

Вопросы:

1. Был ли ранее установлен замок в этой двери?
- Да.
- Нет.

2. Замок находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для установки замка требуется наличие приобретённого оборудования на объекте.

[Понятно]

Правила вопросов:
- Тип замка не спрашивается.
- Тип механизма не спрашивается.
- Размеры замка не спрашиваются.
- Тип двери не спрашивается.
- Размеры посадочного места не спрашиваются.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить замок межкомнатной двери — если замок ранее был установлен:

1. Общий вид посадочного места с одной стороны двери.
- 1 обязательная фотография.

2. Общий вид посадочного места с другой стороны двери.
- 1 обязательная фотография.

3. Посадочное место в торце двери крупным планом.
- 1 обязательная фотография.

4. Посадочное место в дверной коробке крупным планом.
- 1 обязательная фотография.

5. Фотография оборудования в упаковке.
- 1 обязательная фотография.

6. Фотография упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

Лимит фотографий — Установить замок межкомнатной двери — если замок ранее был установлен:
- Обязательные: 6 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 9 из 10 фотографий.

Обязательные фотографии — Установить замок межкомнатной двери — если замок ранее не был установлен:

1. Общий вид двери с первой стороны.
- 1 обязательная фотография.

2. Общий вид двери со второй стороны.
- 1 обязательная фотография.

3. Фотография оборудования в упаковке.
- 1 обязательная фотография.

4. Фотография упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

Лимит фотографий — Установить замок межкомнатной двери — если замок ранее не был установлен:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить замок межкомнатной двери:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны определять тип замка.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны самостоятельно измерять дверь, замок или посадочное место.
- Вы не обязаны самостоятельно подготавливать посадочное место.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к двери.
- Подготовьте безопасные условия для выполнения работ.
- Если оборудование отсутствует на объекте, форма заказа останавливается.

Правила выполнения работ мастером — Установить замок межкомнатной двери:

1. Проверка совместимости до начала работ:
- До начала вскрытия упаковки, разметки, подготовки посадочного места или установки мастер обязан убедиться, что оборудование подходит для данной двери.
- Проверка включает совместимость оборудования с дверью, посадочным местом, дверной коробкой и условиями установки в пределах информации, доступной до начала работ.
- Если замок ранее был установлен, мастер оценивает существующие посадочные места.
- Если замок ранее не устанавливался, мастер учитывает разметку, врезку корпуса замка, врезку ответной планки и подготовку посадочных мест.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения до продолжения работ.

2. Проверка оборудования до установки:
- До установки мастер обязан выполнить визуальный осмотр оборудования.
- Проверка включает наличие видимых механических повреждений и комплектность в пределах штатных элементов установки.
- При обнаружении повреждений или отсутствия необходимых штатных элементов мастер обязан зафиксировать это на фотографиях и направить клиенту через чат приложения до продолжения работ.
- Если клиент подтверждает продолжение работ, подтверждение клиента и фотографии становятся частью доказательной базы заказа.

3. Установка:
- Мастер устанавливает замок межкомнатной двери в пределах стоимости услуги.
- Если доступ ограничен или требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.
- Упаковка оборудования является собственностью клиента.
- Вынос или утилизация упаковки не входят в стоимость услуги.

4. Проверка работы механизма:
- После установки мастер обязан проверить открывание и закрывание замка.
- Мастер обязан проверить работу защёлки, язычка, ручки или иного штатного механизма установленного оборудования.
- Мастер обязан проверить взаимодействие замка с ответной частью в пределах выполненной установки.

5. Проверка результата:
- После завершения работ мастер обязан предоставить клиенту готовый результат.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Locks → Замена замка межкомнатной двери

Status: APPROVED / STORED ✅
Standard Compliance: Locks Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает замену установленного замка межкомнатной двери внутри Locks.
- Замена состоит из демонтажа установленного замка межкомнатной двери и последующего выполнения сценария «Установить замок межкомнатной двери».
- Сценарий не является ремонтом замка, аварийным вскрытием или диагностикой права доступа.
- Вопрос причины замены исключён, потому что он не влияет на initial structured job scope, required photos, совместимость, алгоритм работ мастера или Final Agreed Price.

Вопросы:

1. Замок находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для замены замка требуется наличие приобретённого оборудования на объекте.

[Понятно]

Правила вопросов:
- Причина замены не спрашивается.
- Тип замка не спрашивается.
- Тип механизма не спрашивается.
- Размеры замка не спрашиваются.
- Тип двери не спрашивается.
- Размеры посадочного места не спрашиваются.
- Эти детали оцениваются по фотографиям и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Заменить установленный замок межкомнатной двери:

1. Общий вид установленного замка с первой стороны двери.
- 1 обязательная фотография.

2. Общий вид установленного замка со второй стороны двери.
- 1 обязательная фотография.

3. Торец двери с установленным замком крупным планом.
- 1 обязательная фотография.

4. Фотография оборудования в упаковке.
- 1 обязательная фотография.

5. Фотография упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

Лимит фотографий — Заменить установленный замок межкомнатной двери:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Правила для клиента — Заменить установленный замок межкомнатной двери:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны определять тип замка.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны самостоятельно измерять дверь, замок или посадочное место.
- Вы не обязаны снимать оборудование.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Если оборудование отсутствует на объекте, форма заказа останавливается.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Заменить установленный замок межкомнатной двери:
- Сценарий «Заменить установленный замок межкомнатной двери» использует правила сценария «Установить замок межкомнатной двери» после завершения демонтажа установленного замка, если иное не указано явно.

1. Проверка оборудования до демонтажа установленного:
- Если работа предполагает замену замка межкомнатной двери, мастер обязан проверить оборудование до демонтажа установленного.
- Проверка включает совместимость, комплектность, целостность и возможность установки.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения до продолжения работ.

2. Демонтаж установленного замка:
- Мастер демонтирует установленный замок межкомнатной двери в пределах стоимости услуги замены.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.
- Мастер не обязан забирать, выносить или утилизировать демонтированное оборудование.
- Вынос или утилизация демонтированного оборудования не входят в базовую стоимость услуги и могут быть согласованы отдельно через чат.

3. Установка:
- Мастер устанавливает замок межкомнатной двери в пределах стоимости услуги.
- Если доступ ограничен или требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.
- Упаковка оборудования является собственностью клиента.
- Вынос или утилизация упаковки не входят в стоимость услуги.

4. Проверка работы механизма:
- После установки мастер обязан проверить открывание и закрывание замка.
- Мастер обязан проверить работу защёлки, язычка, ручки или иного штатного механизма установленного оборудования.
- Мастер обязан проверить взаимодействие замка с ответной частью в пределах выполненной установки.

5. Проверка результата:
- После завершения работ мастер обязан предоставить клиенту готовый результат.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Locks → Установка врезного мебельного замка

Status: APPROVED / STORED ✅
Standard Compliance: Locks Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает установку врезного мебельного замка внутри Locks.
- Сценарий применяется, если мебельный замок ранее не был установлен в изделии.
- Установка включает разметку, создание посадочного места, врезку мебельного замка, базовую проверку работы механизма и регулировку при необходимости.
- Если мебельный замок ранее был установлен, используется сценарий «Заменить установленный мебельный замок».

Вопросы:

1. В каком изделии будет выполняться работа?
- Обязательное текстовое поле.

2. Мебельный замок находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для установки мебельного замка требуется наличие приобретённого оборудования на объекте.

[Понятно]

Правила вопросов:
- Тип мебельного замка не спрашивается.
- Тип механизма не спрашивается.
- Размеры мебельного замка не спрашиваются.
- Толщина материала не спрашивается.
- Тип мебели не выбирается отдельной подкатегорией.
- Эти детали оцениваются по фотографиям, описанию изделия и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Установить врезной мебельный замок:

1. Общий вид изделия.
- 1 обязательная фотография.

2. Фотография двери или элемента мебели под углом, чтобы была видна обратная сторона двери и конструкция изделия.
- 1 обязательная фотография.

3. Фотография оборудования в упаковке.
- 1 обязательная фотография.

4. Фотография упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

Лимит фотографий — Установить врезной мебельный замок:
- Обязательные: 4 фотографии.
- Дополнительные: до 3 фотографий.
- Всего: до 7 из 10 фотографий.

Правила для клиента — Установить врезной мебельный замок:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны определять тип мебельного замка.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны самостоятельно измерять изделие, дверь, фасад или толщину материала.
- Вы не обязаны самостоятельно подготавливать посадочное место.
- Клиент должен сохранить право на возврат, обмен и гарантийное обслуживание приобретённого оборудования.
- Подготовьте доступ к месту выполнения работ.
- Подготовьте безопасные условия для выполнения работ.
- Если оборудование отсутствует на объекте, форма заказа останавливается.

Правила выполнения работ мастером — Установить врезной мебельный замок:

1. Проверка совместимости до начала работ:
- До начала вскрытия упаковки, разметки, подготовки посадочного места или установки мастер обязан убедиться, что оборудование подходит для данного изделия.
- Проверка включает совместимость оборудования с изделием, конструкцией, толщиной материала и условиями установки в пределах информации, доступной до начала работ.
- Мастер оценивает изделие, конструкцию, толщину материала, совместимость замка и необходимость дополнительной фурнитуры.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения до продолжения работ.

2. Проверка оборудования до установки:
- До установки мастер обязан выполнить визуальный осмотр оборудования.
- Проверка включает наличие видимых механических повреждений и комплектность в пределах штатных элементов установки.
- При обнаружении повреждений или отсутствия необходимых штатных элементов мастер обязан зафиксировать это на фотографиях и направить клиенту через чат приложения до продолжения работ.
- Если клиент подтверждает продолжение работ, подтверждение клиента и фотографии становятся частью доказательной базы заказа.

3. Установка:
- Мастер устанавливает врезной мебельный замок в пределах стоимости услуги.
- Работа может включать разметку, создание посадочного места, врезку мебельного замка и регулировку при необходимости.
- Если доступ ограничен или требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.
- Упаковка оборудования является собственностью клиента.
- Вынос или утилизация упаковки не входят в стоимость услуги.

4. Проверка работы механизма:
- После установки мастер обязан проверить открывание и закрывание мебельного замка.
- Мастер обязан проверить работу штатного механизма установленного оборудования.
- Мастер обязан проверить взаимодействие мебельного замка с ответной частью, если она предусмотрена конструкцией.

5. Проверка результата:
- После завершения работ мастер обязан предоставить клиенту готовый результат.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

### Locks → Замена мебельного замка

Status: APPROVED / STORED ✅
Standard Compliance: Locks Mini-TZ Standard ✅

Назначение:
- Этот mini-ТЗ описывает замену установленного мебельного замка внутри Locks.
- Замена состоит из демонтажа установленного мебельного замка и последующего выполнения сценария «Установить врезной мебельный замок».
- Сценарий не является ремонтом мебельного замка, аварийным вскрытием или диагностикой права доступа.
- Вопрос причины замены исключён, потому что он не влияет на initial structured job scope, required photos, совместимость, алгоритм работ мастера или Final Agreed Price.
- Отдельные подкатегории по типу мебели не создаются.

Вопросы:

1. В каком изделии будет выполняться работа?
- Обязательное текстовое поле.

2. Мебельный замок находится на объекте?
- Да.
- Нет.

Если клиент выбирает «Нет», система показывает сообщение:
- Для замены мебельного замка требуется наличие приобретённого оборудования на объекте.

[Понятно]

Правила вопросов:
- Причина замены не спрашивается.
- Тип мебельного замка не спрашивается.
- Тип механизма не спрашивается.
- Размеры мебельного замка не спрашиваются.
- Толщина материала не спрашивается.
- Тип мебели не выбирается отдельной подкатегорией.
- Эти детали оцениваются по фотографиям, описанию изделия и при необходимости уточняются через чат.
- Дополнительные материалы, комплектующие и расходники регулируются Global Materials Separation Rule.

Обязательные фотографии — Заменить установленный мебельный замок:

1. Общий вид изделия.
- 1 обязательная фотография.

2. Вид установленного мебельного замка снаружи.
- 1 обязательная фотография.

3. Фотография двери или элемента мебели под углом, чтобы была видна обратная сторона двери и конструкция изделия.
- 1 обязательная фотография.

4. Фотография оборудования в упаковке.
- 1 обязательная фотография.

5. Фотография упаковки со всей информацией на ней или карточка приобретённого товара с технической информацией.
- До 4 фотографий:
  - 1 обязательная;
  - до 3 дополнительных.

Лимит фотографий — Заменить установленный мебельный замок:
- Обязательные: 5 фотографий.
- Дополнительные: до 3 фотографий.
- Всего: до 8 из 10 фотографий.

Правила для клиента — Заменить установленный мебельный замок:
- Вы не обязаны выполнять опасные действия для предоставления информации.
- Вы не обязаны определять тип мебельного замка.
- Вы не обязаны разбираться в технических характеристиках.
- Вы не обязаны распаковывать товар.
- Вы не обязаны самостоятельно измерять изделие, дверь, фасад или толщину материала.
- Вы не обязаны снимать оборудование.
- Вы не обязаны самостоятельно подготавливать посадочное место.
- Вы не обязаны заранее покупать дополнительные материалы или комплектующие.
- Подготовьте доступ к установленному оборудованию.
- Подготовьте безопасные условия для выполнения работ.
- Если оборудование отсутствует на объекте, форма заказа останавливается.
- Снятое оборудование является вашей собственностью и остаётся на объекте по умолчанию.

Правила выполнения работ мастером — Заменить установленный мебельный замок:
- Сценарий «Заменить установленный мебельный замок» использует правила сценария «Установить врезной мебельный замок» после завершения демонтажа установленного мебельного замка, если иное не указано явно.

1. Проверка оборудования до демонтажа установленного:
- Если работа предполагает замену мебельного замка, мастер обязан проверить оборудование до демонтажа установленного.
- Проверка включает совместимость, комплектность, целостность и возможность установки.
- Мастер оценивает изделие, тип установленного мебельного замка, крепление, конструкцию и совместимость оборудования.
- При выявлении несовместимости мастер обязан сообщить об этом клиенту через чат приложения до продолжения работ.

2. Демонтаж установленного мебельного замка:
- Мастер демонтирует установленный мебельный замок в пределах стоимости услуги замены.
- Демонтированное оборудование является собственностью клиента и остаётся на объекте.
- Мастер не обязан забирать, выносить или утилизировать демонтированное оборудование.
- Вынос или утилизация демонтированного оборудования не входят в базовую стоимость услуги и могут быть согласованы отдельно через чат.

3. Установка:
- Мастер устанавливает мебельный замок в пределах стоимости услуги.
- Работа может включать подготовку посадочного места и регулировку при необходимости.
- Если доступ ограничен или требуются дополнительные материалы, комплектующие или расходники, применяется Global Materials Separation Rule.
- Упаковка оборудования является собственностью клиента.
- Вынос или утилизация упаковки не входят в стоимость услуги.

4. Проверка работы механизма:
- После установки мастер обязан проверить открывание и закрывание мебельного замка.
- Мастер обязан проверить работу штатного механизма установленного оборудования.
- Мастер обязан проверить взаимодействие мебельного замка с ответной частью, если она предусмотрена конструкцией.

5. Проверка результата:
- После завершения работ мастер обязан предоставить клиенту готовый результат.
- Услуга не считается качественно выполненной до подтверждения базовой работоспособности результата работ в рамках согласованного объёма заказа.

Наследуемые правила:
- Global Materials Separation Rule.
- Global Completion Evidence Rule.
- Global Service Quality Rule.
- Chat Evidence Rules.

## Global Rule → Chat Lifecycle Rules

Status: APPROVED GLOBAL RULE ✅

Purpose:
- Chat is not a messenger.
- Chat is a business process tool and changes its role depending on the order lifecycle stage.

### Stage 1. Initial Scope Collection

Client:
- Sends photos only through the order form.

Purpose:
- Build the initial technical specification (TЗ).

### Stage 2. Chat Before Work Starts

Allowed:
- Clarifying questions.
- Discussion of hidden works.
- Material clarification.
- Technical discussion.
- Price justification.
- One-time final price agreement.

Forbidden:

Client:
- Cannot send additional photos.

Master:
- Cannot send photos.

Reason:
- Chat must not become a remote diagnostic/help center.

### Stage 3. Start Work

Trigger:
- Master presses "Start Work".

After this action:

Client:
- Photo sending remains unavailable.

Master:
- Photo sending becomes available.

Purpose:
- Protect the master.
- Record hidden defects.
- Record dangerous conditions.
- Provide evidence.

### Stage 4. Work Completion

Master obligations:
- Verify the result of work.
- Take final photos of completed work.
- Send final photos through Helpy chat.

Examples:
- Installed equipment.
- Final result.
- Clean work area.

### Stage 5. Client Confirmation

Client:
- Reviews the result.
- Confirms work completion.

Before confirmation:
- The master cannot complete the order.

### Stage 6. Complete Order

Trigger:
- "Complete Order" button becomes available to the master only after client confirmation.

Result:
- Order status changes to completed.
- Review flow starts.
- Historical data is preserved.
- Order becomes available for analytics and disputes.

Business Principles:
- Chat is part of the order workflow.
- Chat protects the client.
- Chat protects the master.
- Chat protects the platform.
- Chat generates knowledge for improving Helpy.

## Job Events / Order Timeline Contract

Status: GAP_APPROVED

Implementation State:
- TARGET_APPROVED: full append-only business timeline.
- IMPLEMENTED: master_selected, work_started, evidence_uploaded, completion_confirmed_by_client, job_completed.
- PARTIAL: payment lifecycle exists but timeline coverage is incomplete.
- GAP_APPROVED: order_created, job_published, initial_offer_sent, price_adjustment_requested, price_adjustment_approved, final_application_sent, financial_snapshot_created, deposit_created, deposit_paid, commission_obligation_created, dispute_opened, dispute_resolved, refund_issued, review_submitted, admin_intervention.
- CURRENT GAP: runtime does not emit the full approved canonical timeline.

### Purpose

`job_events` is the append-only platform timeline for an order.

It is the source of truth for:
- order lifecycle audit;
- Admin Panel order timeline;
- disputes;
- evidence flow;
- completion flow;
- payment/financial timeline visibility;
- operational analytics;
- future notifications.

### Data Separation

`chat_messages` stores human communication.

`job_events` stores business process history.

System/platform lifecycle events must not be stored as fake user chat messages.

Chat may explain human context.
`job_events` must record business facts.

### Core Fields

- id;
- job_id;
- event_type;
- actor_user_id;
- actor_role;
- payload_json;
- created_at.

### Immutability Rule

`job_events` are append-only.

Normal users must not edit, delete or hide job events.

Admin must not rewrite business history.

If correction or intervention is required, it must be recorded as a new event.

### Actor Rule

`actor_user_id` may be null only for pure system/platform events.

`actor_role` must be one of:
- client;
- master;
- admin;
- system.

### Canonical Event Types
Этот раздел перечисляет технические `event_type`, которые используются в `job_events`.
Названия событий не переводятся, потому что они являются частью будущей схемы БД, API и runtime-логики.

#### Order / Scope

- order_created;
- job_published;
- job_cancelled.

#### Offer / Price

- initial_offer_sent;
- price_adjustment_requested;
- price_adjustment_approved;
- final_application_sent;
- master_selected.

#### Financial

- financial_snapshot_created;
- deposit_created;
- deposit_paid;
- commission_obligation_created;
- commission_collected;
- refund_issued.

#### Work / Evidence / Completion

- work_started;
- evidence_uploaded;
- arrival_coordination_requested;
- completion_confirmed_by_client;
- job_completed.

#### Review / Dispute / Admin

- review_submitted;
- dispute_opened;
- dispute_resolved;
- admin_intervention.

### Event Visibility Principle

Admin can see all job events.

Client and master timelines may show selected user-facing events only.

Internal/system events may be hidden from mobile UI while remaining visible to Admin.

### Current Runtime Coverage

Current backend already writes:
- master_selected;
- work_started;
- evidence_uploaded;
- completion_confirmed_by_client;
- job_completed.

Current backend reads:
- completion_confirmed_by_client.

### Current DB Domain Coverage

Current migration `0004_job_events_timeline.sql` already supports active canonical/runtime event types:
- deposit_paid;
- master_selected;
- work_started;
- completion_confirmed_by_client;
- job_completed;
- dispute_opened;
- dispute_resolved;
- job_cancelled;
- review_submitted;
- refund_issued;
- admin_intervention;
- price_adjustment_requested;
- price_adjustment_approved;
- evidence_uploaded.

Current migration also still supports legacy/reserved DB-domain event types:
- work_completed_by_master;
- attachment_policy_changed.

Runtime must not emit legacy/reserved event types unless a future approved migration/runtime contract explicitly reactivates them.

### Known Domain Gap

The current DB domain does not yet include all canonical event types.

Missing canonical event types:
- order_created;
- job_published;
- initial_offer_sent;
- final_application_sent;
- financial_snapshot_created;
- deposit_created;
- commission_obligation_created;
- commission_collected;
- arrival_coordination_requested.

Deprecated / legacy event types:
- work_completed_by_master.

Reserved / admin configuration event types:
- attachment_policy_changed.

### Implementation Rule

No runtime code should emit an event type that is not documented here.

No migration should be written from this contract alone.

Before DB migration, create a concrete migration plan that:
- adds missing canonical event types;
- preserves existing event history;
- keeps compatibility with current runtime events;
- documents deprecated/reserved event types;
- includes APPLY / REGISTER / DONE / audit / smoke.

### Timeline Rule

Timeline contracts must be derived from this event contract.

Mobile timelines may display only selected event types.

Admin timelines must preserve the complete event history.

## Timeline API Contract

Status: GAP_APPROVED

Implementation State:
- TARGET_APPROVED: role-aware Timeline API over job_events.
- IMPLEMENTED: job_events storage and partial event emission.
- GAP_APPROVED: client timeline endpoint, master timeline endpoint, admin timeline endpoint, visibility filtering, event enrichment.
- CURRENT GAP: no runtime Timeline API endpoints exist.

### Purpose

Timeline API exposes `job_events` as an ordered order lifecycle timeline.

Timeline API must serve:
- client order timeline;
- master order timeline;
- admin order timeline;
- dispute evidence review;
- operational audit.

### Source Of Truth

Timeline API reads from `job_events`.

Timeline API must not rebuild business history from chat messages.

Timeline API may enrich events with related job, payment, offer, photo, review or dispute data, but `job_events` remains the lifecycle source.

### Endpoints

Client / Master:

GET /api/v1/jobs/:jobId/timeline

Admin:

GET /api/v1/admin/jobs/:jobId/timeline

### Access Rules

Client may read timeline only for own job.

Selected master may read timeline only for selected job.

Master with active pre-selection offer may later read only pre-selection timeline context if approved.

Admin may read full timeline for any job.

### Visibility Rules

Admin timeline shows all events.

Client and master timelines show only user-facing events.

Internal/system events may be hidden from mobile while remaining visible to Admin.

### Timeline Visibility Matrix

| event_type | Client | Master | Admin | Mobile Timeline | Internal Only |
|---|---:|---:|---:|---:|---:|
| order_created | yes | no | yes | yes | no |
| job_published | yes | if eligible / active offer | yes | yes | no |
| job_cancelled | yes | if participant | yes | yes | no |
| initial_offer_sent | yes | owner master | yes | yes | no |
| price_adjustment_requested | yes | owner master | yes | yes | no |
| price_adjustment_approved | yes | owner master | yes | yes | no |
| final_application_sent | yes | owner master | yes | yes | no |
| master_selected | yes | selected master | yes | yes | no |
| financial_snapshot_created | no | no | yes | no | yes |
| deposit_created | yes | selected master | yes | yes | no |
| deposit_paid | yes | selected master | yes | yes | no |
| commission_obligation_created | no | selected master | yes | yes | no |
| commission_collected | no | selected master | yes | no | yes |
| refund_issued | yes | if affected | yes | yes | no |
| arrival_coordination_requested | yes | selected master | yes | yes | no |
| work_started | yes | selected master | yes | yes | no |
| evidence_uploaded | yes | selected master | yes | yes | no |
| completion_confirmed_by_client | yes | selected master | yes | yes | no |
| job_completed | yes | selected master | yes | yes | no |
| review_submitted | yes | selected master | yes | yes | no |
| dispute_opened | yes | selected master | yes | yes | no |
| dispute_resolved | yes | selected master | yes | yes | no |
| admin_intervention | no | no | yes | no | yes |

### Visibility Rules By Role

Client can see:
- own order lifecycle events;
- selected master lifecycle events;
- offer/price events for offers visible to the client;
- payment/deposit/refund events affecting the client.

Master can see:
- own offer events;
- selected work lifecycle events after selection;
- commission obligation events affecting the master;
- dispute/review events related to selected work.

Admin can see:
- all events;
- internal-only events;
- legacy/reserved events;
- malformed payload warnings when implemented.

### Mobile Timeline Filter Rule

Mobile Timeline must render only events where `Mobile Timeline = yes`.

Mobile must not locally override visibility.

Timeline API is responsible for filtering events according to actor role and relationship to the order.


### Guidance Trigger Matrix

Guidance Trigger Matrix defines which lifecycle events may trigger contextual guidance or next-step CTA cards.

Guidance is not hardcoded in Flutter.

Timeline events may trigger guidance lookup by:
- event_type;
- role;
- screen;
- workflow stage;
- category;
- subcategory;
- language.

| event_type | Client Guidance | Master Guidance | Runtime Now | Purpose |
|---|---:|---:|---:|---|
| order_created | yes | no | no | explain next step before publication |
| job_published | yes | eligible / offer master | no | explain marketplace visibility and offer review |
| initial_offer_sent | yes | owner master | no | explain offer received / waiting state |
| price_adjustment_requested | yes | owner master | no | explain price justification and client decision |
| price_adjustment_approved | yes | owner master | no | explain approved revised price |
| final_application_sent | yes | owner master | no | explain final application and selection |
| master_selected | yes | selected master | yes | guide chat, arrival coordination and deposit state |
| financial_snapshot_created | no | no | no | admin-only financial audit |
| deposit_created | yes | selected master | no | explain deposit/payment obligation |
| deposit_paid | yes | selected master | no | explain next step after payment |
| commission_obligation_created | no | selected master | no | explain master platform commission obligation for cash flow |
| commission_collected | no | selected master | no | explain master commission obligation has been collected |
| arrival_coordination_requested | yes | selected master | yes | guide chat-based arrival coordination after financial route is fixed |
| work_started | yes | selected master | yes | guide evidence photos and work process |
| evidence_uploaded | yes | selected master | yes | explain evidence review / continue work |
| completion_confirmed_by_client | yes | selected master | yes | unlock master complete order guidance |
| job_completed | yes | selected master | yes | guide review / closeout |
| review_submitted | yes | selected master | no | explain reputation / completion closure |
| dispute_opened | yes | selected master | no | explain dispute process |
| dispute_resolved | yes | selected master | no | explain resolution outcome |
| admin_intervention | no | no | no | admin-only operational context |

### Guidance Trigger Rules

If `Runtime Now = yes`, mobile may use the event once Timeline API is implemented.

If `Runtime Now = no`, the trigger is approved but must wait until backend emits the event.

Guidance lookup must not be implemented as local Flutter `if event_type` text.

Flutter may use event_type only to request or place guidance records.

Actual guidance text must come from Guidance Records through API.

### CTA Rule

Guidance may include CTA metadata later.

Examples:
- open_chat;
- pay_deposit;
- upload_evidence_photos;
- confirm_completion;
- complete_order;
- leave_review;
- open_dispute.

CTA availability must still be validated by backend business rules.

Mobile must not use guidance CTA as the source of permission.

### Default Sorting

Timeline events are returned in ascending chronological order by default.

created_at ASC

API may later support DESC pagination for large timelines.

### Response Shape

Response must use the standard API envelope:

{
  "success": true,
  "data": {
    "job_id": "...",
    "timeline": [
      {
        "id": "...",
        "event_type": "master_selected",
        "actor_user_id": "...",
        "actor_role": "client",
        "created_at": "...",
        "payload": {},
        "visibility": {
          "client": true,
          "master": true,
          "admin": true
        }
      }
    ]
  }
}

### Event Payload Rule

payload_json is stored as text in DB.

Timeline API must return parsed payload as object.

Invalid payload_json must not crash timeline response.

If payload_json is invalid, API returns an empty object and may include admin-only warning later.

### Mobile Timeline Rule

Mobile must not infer lifecycle from job status alone when timeline is available.

Mobile may render selected timeline events as system cards.

Mobile must not display internal-only events.

### Admin Timeline Rule

Admin timeline must preserve full event history.

Admin timeline must support dispute review, evidence review, payment review and operational audit.

### Localization Rule

Timeline API may return raw event_type first.

User-facing labels must be produced through localization layer or guidance/timeline label registry.

Hardcoded event labels inside Flutter are not allowed.

### Relationship With Guided Job Flow

Timeline API is the read model for Guided Job Flow lifecycle history.

Guided Job Flow defines what should happen.

job_events records what happened.

Timeline API exposes what happened to clients, masters and admins according to visibility rules.

---



## Cognitive Load Audit Backlog
Status: STORED ✅

### 1. Atomic Orders vs Composite Orders
Status: ARCHITECTURAL FACT

Описание:
- Атомарные заказы используются для одиночной техники.
- Составные заказы (mini-ТЗ) используются для Kitchen Built-in.
- Решение утверждено, внесено в регистр и подтверждено аудитом.

Действие:
- Не пересматривать без появления новых доказательств, влияющих на продукт.

Приоритет:
- NONE.


### 2. Унификация формулировок типов работ
Status: TECH DEBT

Описание:
- В старых сценариях Appliance используются формулировки:
  - «Установить новую технику»;
  - «Заменить существующую технику».
- В Kitchen Built-in используются:
  - «Установить и подключить»;
  - «Заменить».

Действие:
- После завершения Appliance провести аудит унификации терминологии.

Приоритет:
- LOW.


### 3. Electrical Cognitive Load Audit
Status: MANUAL REVIEW REQUIRED

Описание:
- Автоматический аудит выявил возможные повторяющиеся технические вопросы.
- Необходимо визуально проверить Electrical на предмет лишней когнитивной нагрузки.

Действие:
- Провести ручной аудит глазами.

Приоритет:
- MEDIUM.


### 4. Global Low Cognitive Load Rule
Status: GLOBAL RULE CANDIDATE

Описание:
- Если информация уже определяется:
  - контекстом категории;
  - ранее выбранной веткой;
  - обязательными фотографиями;
то повторно спрашивать клиента не следует.

Действие:
- После завершения общего аудита оформить как глобальное правило.

Приоритет:
- HIGH.


### 5. Registry Language Cleanup
Status: CONTINUOUS IMPROVEMENT

Описание:
- Во время будущих аудитов устранять остатки англоязычных терминов,
если они не являются технически необходимыми.

Действие:
- Выполнять постепенно без влияния на MVP.

Приоритет:
- LOW.


## Global GAP → Reviews & Reputation System

Status: ✅ APPROVED

Review Flow:

Вопрос 1:
Как вы оцениваете работу мастера?

- ☆ ☆ ☆ ☆ ☆ (горизонтальный выбор 1–5 звёзд).

Вопрос 2:
Что вы можете отметить?
(можно выбрать несколько вариантов)

- Соблюдал договорённости;
- Работа выполнена аккуратно;
- Убрал за собой после завершения работ;
- Готов(а) обратиться к этому мастеру снова.

Комментарий:
- Необязателен.

Review Rules:
- Клиент самостоятельно решает, оставлять комментарий или нет.
- Экран отзыва можно закрыть.
- Создание новых заказов не блокируется.

Master Metrics:
- ⭐ Качество работы;
- 🛠 Опыт;
- 💬⏰ Надёжность;
- 💬 Отзывы.

Reliability:
- Отражает соблюдение договорённостей.
- Включает соблюдение согласованного времени и качество предварительной коммуникации.
- Использует утверждённый фирменный значок Helpy.

Reputation MVP Formulas:
- ⭐ Качество работы = средняя оценка по оставленным отзывам.
- 🛠 Опыт = количество завершённых заказов.
- 💬⏰ Надёжность = количество отзывов с отметкой «Соблюдал договорённости» / общее количество оставленных отзывов.
- 💬 Отзывы = количество оставленных отзывов.

Reliability Calculation Rules:
- Учитываются только оставленные отзывы.
- Завершённые заказы без отзывов не участвуют в расчёте.
- Закрытый экран отзыва не влияет на репутацию мастера.
- Отсутствие отзыва не считается ни положительным, ни отрицательным сигналом.
- Не используются скрытые коэффициенты.
- Не используются временные веса.
- Не используются штрафы для новых мастеров.
- Платформа не делает выводов за клиента.

Rating Display:
- Показывается сразу после первого отзыва.
- Новые мастера отображаются без специальных ограничений.
- Платформа не создаёт искусственных преимуществ или ограничений.

Reviews:
- Показывается количество отзывов.
- При нажатии открывается список комментариев клиентов.

Admin / Analytics Notes:
- Reviews помогают клиентам принимать решения.
- Reviews используются для контроля качества.
- Reviews используются для аналитики платформы.

GAP:
- Admin moderation rules.
- Anti-abuse rules.

## Global Decision → Chat Evidence Photos & Job Details Photo Ownership

Status: ✅ APPROVED

Scope:
- Mobile chat.
- Backend photo upload endpoint.
- Client job details screen.
- Master job details screen.
- RU / EN / TH localization.

Chat Evidence Photo Rules:
- Master evidence photos are allowed only for the selected master during `in_progress`.
- One user action of selecting N photos creates one chat system message.
- Backend upload batching must not leak into UX.
- Example: if the master selects 10 photos, mobile may upload them as 3+3+3+1, but chat must show one message only.
- Approved chat system message format:
  - RU: `Мастер прикрепил N 📷`
  - EN: `The master attached N 📷`
  - TH: `ช่างแนบ N 📷`
- The message is stored as a normal chat message with localized `text_translations_json`.
- Evidence photos are rendered inline under the upload message in chat.
- Evidence photos must not be rendered as a separate block at the top of chat.
- This keeps evidence visually connected to the exact chat event that created it.
- Current MVP detection of evidence-photo system messages is text-pattern based for RU / EN / TH.
- Future schema improvement: replace text-pattern detection with explicit message type or metadata when chat message schema is revised.

Job Details Photo Display Rules:
- Job details must separate photos into two visual sections:
  - Client photos.
  - Master photos.
- Client and master details screens must use the same grouping logic.
- Empty photo sections are hidden.
- If no photos exist at all, show the existing "photos not saved" message.
- Photo section labels must be localized in RU / EN / TH.
- Master evidence/result photos remain visible in job details after completion.
- This is intentional: both client and master should see the result/history of work after completion.

Photo Ownership Contract:
- `job_photos.client_user_id` currently stores the actor user id that uploaded the photo.
- Backend proof:
  - `INSERT INTO job_photos (... client_user_id ...)`
  - `.bind(id, jobId, actorUserId, url, now)`
- API proof:
  - `GET /jobs/:id/photos` returns `client_user_id`.
- Mobile treats this returned value as `ownerUserId`.
- Current grouping rule:
  - `photo.ownerUserId == job.selectedMasterUserId` → Master photos.
  - Otherwise → Client photos.
- The current field name is legacy and misleading, but current behavior is correct for MVP.

Recorded Technical Debt:
- `job_photos.client_user_id` should be reviewed during the next canonical DB/schema revision.
- Preferred future name: `owner_user_id` or `uploaded_by_user_id`.
- Rename must be done only after read-only usage audit across backend, mobile, admin, migrations and live D1 data.
- Do not rename this field as an isolated quick patch.

---

## Client Expected Price / Final Price Contract

Status: APPROVED ✅

### Client Expected Price

For each order, the client enters an expected price for the work.

Client Expected Price:
- is entered by the client during order creation;
- is shown to masters in Marketplace;
- is the client's expected starting price;
- is part of the permanent order history;
- is not a platform price recommendation;
- is not the final legally significant order price;
- is not used for final commission, deposit or commission obligation calculation.

### Minimum Threshold

The platform sets only a minimum threshold for the selected category, subcategory or scenario.

Minimum threshold:
- prevents accidental input errors;
- prevents obviously unrealistic orders;
- reduces orders with no market interest;
- is lower than the expected lower market price where appropriate;
- is not a recommended price;
- is not shown as the market price;
- is not used for commission, deposit or commission obligation calculation.

The client cannot publish an order below the minimum threshold.

### Master One-Time Price Change

After reviewing structured scope, client answers, required photos and Client Expected Price, the master may either:
- submit a final application with the same price;
- request one price change before the client selects a master.

Price change is allowed only once and only before master selection.

Price change requires:
- clear explanation from the master;
- discussion with the client in chat;
- preliminary client agreement with the new price.

The system must store:
- original Client Expected Price;
- proposed master price;
- price change reason;
- confirmation timestamp;
- master user id;
- client confirmation evidence.

Repeated price changes are forbidden for normal users.

Exceptions are allowed only through admin-controlled business rules.

### Final Master Application

After the price is accepted or changed and preliminarily agreed, the master sends a final application to the client.

The client selects the master based on the agreed price.

At the moment of master selection, the agreed price becomes Final Agreed Price and the platform fixes:
- selected master;
- final agreed price;
- selected offer/application;
- commission base amount.

### Commission Rule

Platform commission is calculated only from Final Agreed Price.

Deposit = Final Agreed Price × 30%

Канонический процент депозита / комиссии:
- 30% — утверждённый базовый процент депозита / комиссии платформы.
- 40% отклонены как ошибочное историческое значение Chain 0001.
- Процент должен изменяться из Admin Panel без релиза приложения.
- Admin может менять процент для утверждённых бизнес-сценариев: сезонные скидки, запусковые кампании, пиковые сезонные надбавки.
- Активный процент, применённый в момент выбора мастера, должен сохраняться в постоянном финансовом снимке заказа.
- Будущая архитектура БД должна хранить процент как версионируемую бизнес-конфигурацию, а не как захардкоженную runtime-логику.

### Post-Selection Work Lifecycle

After client selects the master:
- chat is used for arrival coordination;
- master presses Start Work after arriving on site;
- Start Work creates job_events.work_started;
- master uploads evidence photos;
- client confirms completion;
- order can proceed to review or dispute.

### Admin Visibility

Admin Order Timeline must show:
- Client Expected Price;
- minimum threshold active at order creation;
- proposed master price if changed;
- price change reason;
- client confirmation evidence;
- Final Agreed Price;
- payment method;
- deposit amount;
- commission payer;
- chat history;
- work_started event;
- evidence photos;
- completion;
- review;
- dispute state.


---

## Communication Layer / Business Timeline Contract

Status: GAP_APPROVED

Implementation State:
- TARGET_APPROVED: complete separation of chat context and immutable business timeline.
- IMPLEMENTED: chat_messages separated from job_events; partial timeline event emission.
- GAP_APPROVED: full price negotiation evidence, financial timeline evidence, admin evidence aggregation.
- CURRENT GAP: runtime does not emit and expose the complete approved communication timeline.

### Core Principle

Human communication and business lifecycle events must be stored and treated as separate layers.

Chat messages are user communication.

Job events are the immutable business timeline of the order.

This separation is required to prevent business-rule drift, protect dispute evidence and support the future Admin Panel.

### Human Chat Layer

Human chat is stored in `chat_messages`.

Human chat is used for:
- pre-selection communication;
- order scope clarification;
- price discussion;
- arrival coordination;
- normal participant communication;
- supporting evidence context.

Human chat may contain messages, replies and attachments.

Human chat must not be used as the only source of legally significant lifecycle state.

### Business Timeline Layer

Business lifecycle events are stored in `job_events`.

`job_events` is the append-only platform timeline.

Timeline events include:
- price_adjustment_requested;
- price_adjustment_approved;
- master_selected;
- financial_snapshot_created;
- deposit_created;
- deposit_paid;
- commission_obligation_created;
- work_started;
- evidence_uploaded;
- completion_confirmed_by_client;
- job_completed;
- review_submitted;
- dispute_opened;
- dispute_resolved;
- refund_issued;
- admin_intervention.

Business state changes must be represented as timeline events, not only as chat text.

### Price Negotiation Evidence Rule

Price negotiation may happen in chat.

However, the legally significant result of price negotiation must be stored as timeline events.

When a master proposes a one-time price change:
- причина изменения может обсуждаться в чате;
- предварительное согласие клиента может быть зафиксировано в чате;
- платформа должна также сохранить подтверждённый business result в `job_events`.

Required events:
- price_adjustment_requested;
- price_adjustment_approved.

The chat provides human context.

The timeline provides the business proof.

### Admin Chat Access Rule

Admin must be able to access any order chat from the Admin Panel.

Admin chat access is required for:
- dispute review;
- quality control;
- evidence review;
- operational support;
- fraud prevention;
- business-rule enforcement.

Admin access to chat must be read-only by default unless an explicit admin action is recorded as `admin_intervention`.

### Timeline Immutability Rule

Normal users must not edit, delete or hide `job_events`.

Admin must not rewrite business history.

If admin action is required, it must be recorded as a new `admin_intervention` event.

### Chat Evidence Rule

Chat has two different evidence meanings and they must not be mixed.

Price justification evidence:
- до выбора мастера мастер может объяснить, почему Client Expected Price не покрывает реальный scope;
- объяснение может происходить в чате;
- клиент должен понять причину и предварительно согласовать proposed master price до выбора мастера;
- выбор мастера клиентом фиксирует согласованную цену как Final Agreed Price;
- платформа должна записать подтверждённый price result в `job_events`;
- required timeline events: price_adjustment_requested and price_adjustment_approved.

Completion evidence:
- after work starts, the master must upload evidence photos;
- evidence photos prove hidden defects, unsafe conditions, work process and final result;
- the client must confirm completion before the master can complete the order;
- only after client completion confirmation may the master access Complete Order;
- completion confirmation and completion must be recorded in `job_events`.

Disputes must use:
- chat history;
- job_events timeline;
- price change history;
- payment state;
- evidence photos;
- completion state;
- review state.

### Admin Order Timeline Requirement

Admin Order Timeline must combine:
- human chat context from `chat_messages`;
- lifecycle events from `job_events`;
- payment/deposit state;
- evidence photos;
- selected master;
- completion;
- review;
- dispute state.

The Admin Panel must present these layers together while keeping their data responsibilities separate.


---

## Chat Threads Architecture Decision

Status: GAP_APPROVED

Implementation State:
- TARGET_APPROVED: chat_threads as canonical chat context model.
- IMPLEMENTED: chat_messages linked directly to jobs.
- GAP_APPROVED: chat_threads table, thread lifecycle, thread visibility rules, admin thread aggregation.
- CURRENT GAP: runtime does not implement chat_threads.

### Decision

Helpy will use `chat_threads` as the canonical chat context model.

Chat is not a side feature.

Chat is part of the order workflow, business logic, evidence model and future Admin Panel control layer.

### Why

A single order can have multiple chat contexts:
- pre-selection negotiation with each master;
- post-selection work coordination;
- evidence discussion;
- dispute/support review;
- admin-visible operational context.

Using only `job_id` for chat messages would mix different business contexts into one conversation and create long-term drift.

### Canonical Model

`chat_threads` will represent the chat context.

`chat_messages` will belong to a chat thread.

A thread may be linked to:
- job;
- offer;
- selected master;
- lifecycle stage;
- thread type;
- thread status.

### Initial Thread Types

- pre_selection_offer;
- work;
- dispute;
- admin_support.

### Business Rules

Pre-selection offer threads:
- one thread per job + offer;
- visible to the client and the offering master;
- not visible to other masters;
- used for scope clarification and price negotiation.

Work thread:
- created or activated after master selection;
- visible to the client and selected master;
- used for arrival coordination, work execution and evidence context.

Admin:
- can read all threads for an order from the Admin Panel;
- must see thread type, participants, lifecycle stage and related timeline events;
- admin interventions must be recorded as `admin_intervention` events, not by rewriting chat history.

### Timeline Separation

`chat_threads` and `chat_messages` provide human communication context.

`job_events` remains the immutable business timeline.

Chat threads must not replace `job_events`.

`job_events` must not be stored as fake chat messages.


---

## Offer Lifecycle Architecture Decision

Status: GAP_APPROVED

Implementation State:
- TARGET_APPROVED: full offer lifecycle with negotiation history.
- IMPLEMENTED: offers.status and simple offer.price flow.
- GAP_APPROVED: initial_offer_price, revised_offer_price, price_revision_reason, price_revision_requested_at, final_application_sent_at, final_agreed_price.
- CURRENT GAP: runtime does not preserve approved offer lifecycle facts and history.

### Decision

Helpy will use `offers.status` + offer lifecycle fields + `job_events` for offer lifecycle state, facts and immutable history.

### Responsibility Split

`offers.status` stores current operational state.

Offer lifecycle fields store business facts:
- initial_offer_price;
- revised_offer_price;
- price_revision_reason;
- price_revision_requested_at;
- final_application_sent_at;
- final_agreed_price.

`job_events` stores immutable business history:
- price_adjustment_requested;
- price_adjustment_approved;
- final_application_sent;
- master_selected.

### Why

Status alone is not enough because it does not preserve price amounts, reason, confirmation time and evidence.

Fields alone are not enough because they make current state ambiguous and complicate UI/API business rules.

`job_events` alone is not enough because operational screens need current state and direct facts without rebuilding state from the full timeline.

### Business Rule

Master selection is allowed only after a final application exists.

Final agreed price must be fixed before deposit/commission calculation.

Repeated master price revision is forbidden for normal users unless an admin-controlled business rule explicitly allows it.


---

## Thailand Payment Runtime Architecture Decision

Status: APPROVED ✅

### Decision

Helpy payment runtime must follow Thailand-first payment behavior.

### PromptPay QR

PromptPay QR is the primary deposit payment method.

For PromptPay:
- client pays platform;
- payment type is deposit;
- deposit equals 30% of Final Agreed Price;
- commission payer is client;
- payment status must support pending, paid, failed and expired.

### Cash

Cash is a mandatory option.

For Cash:
- client pays the full Final Agreed Price directly to the master;
- platform does not receive client deposit immediately;
- platform creates a master commission obligation;
- commission payer is master;
- commission obligation equals 30% of Final Agreed Price.

Cash must not be modelled as client deposit paid to platform.

### Bank Transfer

Bank Transfer is an alternative method for larger customers.

MVP model may be simple:
- client transfers deposit to platform bank account;
- payment starts as pending;
- admin or verified process marks payment as paid;
- proof workflow may be added later.

### Wallet / TrueMoney

Wallets, including TrueMoney, are reserved as configurable payment methods.

Wallet availability must be controlled by platform financial settings.

### Cards

Cards are reserved for later market rollout.

Card-related schema may remain for future expansion, but runtime/mobile must not expose cards while card_enabled is false.

### Canonical Rule

Payment method determines payment obligation:

PromptPay:
- client → platform;
- deposit/commission.

Cash:
- master → platform;
- commission obligation.

Bank Transfer:
- client → platform;
- deposit with manual/verified confirmation.


### Financial Event Creation Rule

After `master_selected`, the platform must first create the immutable job financial snapshot.

Required event:
- financial_snapshot_created.

Then payment method determines the next financial event:

PromptPay:
- create deposit payment state;
- emit deposit_created;
- later emit deposit_paid only after confirmed payment.

Bank Transfer:
- create pending manual/verified deposit payment state;
- emit deposit_created;
- later emit deposit_paid only after admin/verified confirmation.

Cash:
- do not create client deposit-paid state;
- create master commission obligation state;
- emit commission_obligation_created.

Rule:
- deposit_created and commission_obligation_created are mutually exclusive for the selected payment method.
- deposit_paid must never be emitted for Cash unless a future approved cash-collection contract explicitly changes this rule.
- financial_snapshot_created is internal/admin-visible proof that payment/commission was calculated from fixed Final Agreed Price.


---

## Final Price Architecture Decision

Status: GAP_APPROVED

Implementation State:
- TARGET_APPROVED: offer-level negotiation history + immutable job financial snapshot.
- IMPLEMENTED: selected_offer_price copied to jobs and deposit_amount calculated during selection.
- GAP_APPROVED: initial_offer_price, revised_offer_price, offers.final_agreed_price, jobs.final_agreed_price, commission_base_amount, price_change_reason, confirmation_timestamp, client_confirmation_evidence.
- CURRENT GAP: runtime and schema do not preserve final price evolution.

### Decision

Helpy will use offer-level final price history together with a job-level financial snapshot.

### Responsibility Split

Offer lifecycle preserves negotiation history:

- initial_offer_price;
- revised_offer_price;
- final_agreed_price.

Jobs preserve the immutable financial result of the order:

- final_agreed_price;
- commission_base_amount;
- deposit_percent;
- deposit_amount;
- payment_method;
- commission_payer.

### Why

Offer data answers:

> How did the parties arrive at this price?

Job data answers:

> Which financial conditions became part of the order?

Using only jobs would lose price evolution.

Using only offers would couple financial execution to negotiation records.

### Final Price Ownership Rule

`offers.final_agreed_price` is offer-scoped negotiation history.

It preserves the final price submitted by a specific master in a specific final application.

Multiple offers for the same job may have different `offers.final_agreed_price` values before master selection.

`jobs.final_agreed_price` is the order-level immutable financial snapshot.

It is copied from the selected offer/application at master selection time and becomes the source for commission, deposit, payment method and dispute evidence.

After master selection, `jobs.final_agreed_price` must not be recalculated from offers.

### Canonical Rule

When a master is selected:

- jobs.final_agreed_price becomes the financial snapshot;
- commission_base_amount is fixed;
- deposit_percent is fixed;
- jobs.deposit_percent хранит процент депозита / комиссии, установленный в Admin Panel и действовавший в момент выбора мастера;
- Последующие изменения процента в Admin Panel не должны пересчитывать исторические финансовые снимки заказов.
- deposit_amount is fixed;
- payment_method is fixed;
- commission_payer is fixed.

Later negotiations must not rewrite historical financial snapshots.


---

## Structured Job Scope / Price Justification Contract

Status: APPROVED ✅

### Structured Job Scope

A Helpy order scope is not free text.

Initial job scope is formed from:
- category;
- subcategory;
- selected service branch;
- dynamic question flow;
- client answers;
- required photos;
- category business rules;
- category photo rules;
- category service playbook rules.

The Plumbing category is the reference standard for structured scope formation.

### Scope Formation Rule

Client answers and required photos form the initial technical assignment for the order.

The form collects the initial scope and closes the visual part of the scope.

The chat completes the textual clarification part of the scope.

Masters must not request additional photos in chat when required photos were already defined by the form.

### Client Expected Price Rule

The client enters Client Expected Price during order creation.

The platform may apply a minimum threshold for the selected category, subcategory or scenario.

Structured job scope allows the master to validate the scope, accept Client Expected Price or justify one price change before master selection.

Client Expected Price is not based only on free-text description.

Minimum threshold:
- is a publishing safeguard;
- is not a platform price recommendation;
- is not used for commission, deposit or commission obligation calculation.

### Price Justification Rule

If a master changes Client Expected Price, the master must justify the change against the structured job scope.

The justification must explain what was not covered by the initial scope, client answers, required photos, visible conditions or expected price.

Examples:
- hidden work discovered from required photos;
- access limitation visible from photos;
- additional material length or connection distance;
- equipment mismatch;
- condition that changes work complexity;
- missing required equipment on site when the selected branch requires it;
- expected price is below the real work scope after clarification.

`price_revision_reason` is a structured business field, not only a chat comment.

Chat may contain discussion, but the final price justification must be stored in offer lifecycle data and represented in `job_events`.

### Admin Visibility

Admin must be able to compare:
- structured job scope;
- client answers;
- required photos;
- Client Expected Price;
- minimum threshold active at order creation;
- master price justification;
- proposed master price;
- client confirmation;
- Final Agreed Price;
- related chat context;
- related job_events.

---
## Helpy Canonical Order Lifecycle Contract

Status: GAP_APPROVED

### Назначение

Контракт определяет канонический жизненный цикл заказа Helpy.

Helpy является Guided Job Flow платформой: заказ проходит через управляемые этапы от создания технического задания до подтверждённого результата, отзыва или спора.

### Текущее состояние

ЦЕЛЕВОЕ СОСТОЯНИЕ:
- полный канонический жизненный цикл заказа;
- разделение business lifecycle, chat, financial route и evidence;
- поддержка PromptPay QR, Cash, Bank Transfer и будущих платёжных маршрутов.

УЖЕ РЕАЛИЗОВАНО:
- structured job creation;
- master selection;
- work_started;
- evidence flow;
- completion flow.

УТВЕРЖДЁННЫЙ GAP:
- full offer lifecycle;
- immutable financial snapshot;
- payment method route;
- master Safety Gate;
- arrival coordination;
- commission collection для Cash;
- полный timeline через job_events.

ТЕКУЩИЙ GAP:
- runtime реализует только часть утверждённого lifecycle;
- старые runtime-фрагменты не должны считаться каноническим источником бизнес-логики.

### Related Orders

Status: GAP_APPROVED

Furniture ↔ Appliance Related Orders Rule:
- Клиент может связать заказ Furniture Assembly с заказами Home Appliances Installation & Connection.

Связка может включать до 3 заказов:

1. Основной мебельный заказ:
   - Kitchen Assembly или Built-in Furniture.

2. Связанный заказ на встроенную кухонную технику:
   - Kitchen Built-in Appliances.

3. Связанный заказ на отдельно стоящую технику:
   - Appliance Installation & Connection.

- После выбора связанного сценария клиент переходит на экран Home Appliances Installation & Connection и выбирает нужную ветку техники.
- Связанные заказы остаются отдельными заказами с отдельными mini-TZ, чатами, финальными ценами, оплатами, evidence, dispute scope и completion flow.
- Платформа должна отдавать приоритет мастерам, способным выполнить все связанные заказы.
- Если один мастер не может выполнить все связанные заказы, платформа может показать мастеров по каждому заказу отдельно.
- Admin Panel должна отображать группу связанных заказов, исполнителя по каждому заказу и комиссию платформы по каждому Final Agreed Price.

### Канонический жизненный цикл заказа

Клиент
↓
указывает Client Expected Price
↓
Система
↓
проверяет minimum threshold по категории / подкатегории / сценарию
↓
Клиент
↓
создаёт заказ через structured questions и required photos
↓
формирует initial structured job scope
↓
публикует заказ
↓
Мастер
↓
изучает structured job scope, required photos and Client Expected Price
↓
если expected price устраивает — отправляет final application без изменения цены
↓
если expected price не устраивает — выполняет ONE justified price change
↓
объясняет причину в чате
↓
сохраняет price_revision_reason
↓
отправляет final application с Final Agreed Price
↓
Client
↓
выбирает мастера
↓
Safety Gate
↓
если мастер проходит обязательные safety requirements:
- фиксируется master_selected;
если мастер отказывается от обязательных safety requirements:
- заказ возвращается в open;
- фиксируется отказ;
- увеличивается счётчик отказов мастера;
- мастер получает предупреждение;
- после третьего такого случая мастер переводится в suspended до решения администрации.
↓
Система
↓
создаёт immutable financial snapshot
↓
фиксирует:
- selected master;
- selected offer/application;
- Final Agreed Price;
- commission base amount;
- deposit_percent / commission_percent;
- payment_method;
- commission_payer.
↓
Payment Method Route
↓
PromptPay QR:
- deposit_created;
- клиент оплачивает депозит платформе;
- deposit_paid после подтверждения оплаты.
↓
Bank Transfer:
- deposit_created;
- клиент оплачивает депозит платформе вручную / через подтверждённый процесс;
- deposit_paid после admin / verified confirmation.
↓
Cash:
- клиент оплачивает весь Final Agreed Price напрямую мастеру;
- платформа создаёт commission_obligation_created;
- у мастера возникает обязательство оплатить комиссию платформе;
- после получения комиссии платформой событие commission_collected закрывает финансовое обязательство.
↓
TrueMoney / Wallets:
- зарезервированный настраиваемый маршрут для локальных wallet-платежей;
- точный runtime route требует отдельного утверждения перед запуском.
↓
Cards:
- зарезервировано для более позднего выхода на рынок.
- runtime/mobile не должны показывать карты до утверждения и включения.
↓
Координация прибытия
↓
Для PromptPay QR / Bank Transfer / future deposit-to-platform routes:
- координация прибытия начинается только после deposit_paid.

Для Cash:
- координация прибытия начинается только после commission_obligation_created.

Системное уведомление мастеру для депозитных методов:
"Депозит успешно внесён. Свяжитесь с клиентом в чате и согласуйте время прибытия на объект."

Системное уведомление клиенту для депозитных методов:
"Депозит получен. Свяжитесь с мастером в чате и согласуйте удобное время выполнения работ."

Системное уведомление мастеру для Cash:
"Заказ подтверждён. Свяжитесь с клиентом в чате и согласуйте время прибытия на объект."

Системное уведомление клиенту для Cash:
"Мастер подтверждён. Согласуйте удобное время выполнения работ. Оплата производится мастеру после выполнения условий заказа."

System event:
- arrival_coordination_requested.

Правило финансового закрытия:
- для PromptPay QR / Bank Transfer / future deposit-to-platform routes финансовый цикл считается закрытым после deposit_paid;
- для Cash финансовый цикл заказа не считается закрытым после job_completed;
- для Cash после job_completed обязательство мастера перед платформой остаётся pending до commission_collected;
- commission_collected фиксирует, что платформа получила комиссию мастера.
↓
Рабочий lifecycle
↓
мастер прибывает на объект
↓
мастер нажимает Start Work
↓
work_started
↓
мастер выполняет работу
↓
мастер загружает evidence photos
↓
evidence_uploaded
↓
клиент проверяет результат
↓
клиент подтверждает завершение работ
↓
completion_confirmed_by_client
↓
только после подтверждения клиента мастеру доступна кнопка Complete Order
↓
мастер нажимает Complete Order
↓
job_completed
↓
Review / Dispute

### Канонические правила

- Клиент указывает Client Expected Price при создании заказа.
- Платформа проверяет minimum threshold, но не рекомендует цену услуги.
- Initial job scope формируется через structured questions и required photos.
- Мастер может один раз предложить изменение цены до выбора мастера.
- Price revision должен быть обоснован через structured job scope.
- Chat содержит human explanation.
- Structured fields и job_events содержат business facts.
- Выбор мастера клиентом означает принятие Final Price и выбранного мастера.
- master_selected создаётся только после прохождения Safety Gate.
- Financial snapshot становится immutable после фиксации.
- Commission и deposit / commission obligation всегда считаются от Final Agreed Price.
- Deposit не является универсальным обязательным этапом для всех payment methods.
- Cash не должен моделироваться как клиентский депозит, оплаченный платформе.
- Для Cash финансовый цикл не закрывается событием job_completed.
- Для Cash финансовый цикл закрывается только после commission_collected.
- Координация прибытия запускается только после финансовой фиксации маршрута оплаты.
- Для депозитных методов arrival coordination запрещён до deposit_paid.
- Для Cash arrival coordination разрешён после commission_obligation_created.
- Master Complete Order доступен только после completion_confirmed_by_client.
- Chat не является единственным источником юридически значимого lifecycle state.
- job_events остаётся источником бизнес-истории заказа.

----

## Guided Job Flow Foundation

Status: APPROVED ✅

### Определение

Helpy является Guided Job Flow платформой.

Helpy не является обычным маркетплейсом услуг.

Главная ответственность платформы — провести заказ через управляемый жизненный цикл: от входных условий до проверенного результата.

### Центральный объект

Центральный объект системы — заказ.

Не мастер.
Не клиент.
Не чат.
Не платежи.

Все остальные компоненты существуют для того, чтобы поддержать успешное завершение жизненного цикла заказа.

### Назначение

Guided Job Flow помогает клиенту и мастеру безопасно и предсказуемо довести заказ до результата.

Платформа ведёт участников через:

- structured questions;
- required photos;
- service playbooks;
- contextual guidance;
- business rules;
- pricing safeguards;
- evidence protection;
- dispute prevention;
- operational controls.

### Принцип structured scope

Client Expected Price указывается клиентом при создании заказа.

Платформа не рассчитывает и не рекомендует цену услуги.

Structured forms не рассчитывают цену, а формируют initial job scope и проверяют minimum threshold.

Structured questions и required photos нужны для того, чтобы:

- сформировать initial job scope;
- дать мастеру возможность проверить объём работ;
- разрешить одно обоснованное изменение цены при необходимости;
- защитить участников через evidence;
- поддержать прозрачное формирование Final Price.

### Канонический жизненный цикл

Клиент
↓
указывает Client Expected Price
↓
Система
↓
проверяет minimum threshold
↓
Клиент
↓
продолжает создание заказа, если цена не ниже minimum threshold
↓
отвечает на structured questions
↓
загружает required photos
↓
формирует initial structured job scope
↓
публикует заказ
↓
Мастер
↓
изучает structured job scope, required photos и Client Expected Price
↓
принимает Client Expected Price
↓
или выполняет ONE justified price change
↓
объясняет причину в чате
↓
сохраняет price_revision_reason
↓
отправляет final application с Final Price
↓
Клиент
↓
выбирает мастера
↓
официально принимает Final Price
↓
Система
↓
создаёт immutable financial snapshot
↓
рассчитывает commission от Final Price
↓
определяет Payment Method Route и связанные финансовые обязательства

Далее
↓
Start Work
↓
Evidence Photos
↓
Client Completion Confirmation
↓
Master Complete Order
↓
Review / Dispute

### Канонические правила

- Клиент указывает Client Expected Price при создании заказа.
- Платформа проверяет minimum threshold, но не рекомендует цену услуги.
- Initial job scope формируется через structured questions и required photos.
- Мастер может один раз предложить изменение цены до выбора мастера.
- Price revision должен быть обоснован через structured job scope.
- Chat содержит human explanation и agreements.
- Structured fields и job_events содержат business facts.
- Выбор мастера клиентом означает принятие Final Price.
- Financial snapshots становятся immutable после фиксации.
- Commission и deposit / commission obligation всегда считаются от Final Price.
- Evidence Photos и Completion являются обязательными частями lifecycle.
- Disputes используют полный evidence package.

### Product Positioning

Обычный маркетплейс отвечает:

"Кого нанять?"

Guided Job Flow отвечает:

"Как безопасно и предсказуемо провести этот заказ к успешному результату?"

### Governance Rule

Все будущие решения по categories, screens, APIs, databases, admin capabilities и business logic должны оцениваться через принципы Guided Job Flow.

Если будущее решение противоречит Guided Job Flow, противоречие должно быть явно обосновано и утверждено до реализации.

----
## Contextual Guidance Knowledge System

Status: APPROVED ✅

### Определение

Helpy не рассматривает документы как пассивные справочные материалы.

Helpy превращает накопленные знания платформы в contextual guidance, которое показывается участникам именно в нужный момент.

Эта система является частью Guided Job Flow.

### Основной принцип

Клиент и мастер не должны искать знания самостоятельно.

Платформа доставляет нужное знание в нужный момент.

### Уровни Guidance

Level 1 — Structured Scope Formation

Платформа собирает объективные факты через:
- category;
- subcategory;
- scenario branch;
- structured questions;
- client answers;
- required photos.

Назначение:
- уменьшить хаос;
- повысить качество initial job scope;
- поддержать прозрачное формирование Final Price.

Level 2 — Client Guidance

Клиент получает contextual prompts во время создания и управления заказом.

Примеры:
- не вскрывать упаковку оборудования до прибытия мастера;
- подготовить рабочую зону до прибытия;
- проверить выполненную работу перед подтверждением.

Level 3 — Master Guidance

Мастер получает contextual prompts, связанные с текущим заказом.

Примеры:
- изучить фотографии до отклика;
- проверить совместимость оборудования до вскрытия упаковки;
- обосновать скрытые работы через чат, если требуется price revision.

Level 4 — Workflow Guidance

Guidance зависит от текущего lifecycle stage.

Примеры:

After Master Selection:
- клиент согласует прибытие через чат;
- мастер согласует прибытие через чат.

In Progress:
- мастер фиксирует скрытые дефекты и этапы работы через evidence photos;
- клиент проверяет результат перед подтверждением.

Before Completion:
- клиенту объясняется, что подтверждение закрывает заказ;
- мастеру объясняется, что completion становится доступен только после подтверждения клиента.

Level 5 — Living Knowledge Base

Client Docs, Master Docs, Service Playbooks и Admin Rules становятся structured knowledge sources.

Они не являются пассивными документами.

### Knowledge Flow

Approved Category Architecture
      ↓
Client Rules / Master Rules / Scenario Rules
      ↓
Client Docs / Master Docs
      ↓
Service Playbooks
      ↓
Admin Rules
      ↓
Guidance Records
      ↓
API
      ↓
Mobile UI

### Runtime Rule

Mobile applications не должны напрямую читать Markdown documents.

Mobile applications consume only structured guidance records delivered by API.

Example structure:

{
  "context": "before_offer",
  "role": "master",
  "category": "plumbing",
  "subcategory": "faucet_replace",
  "text": "Do not open equipment packaging before compatibility verification."
}

### Guidance Context Dimensions

Guidance может зависеть от:
- role;
- category;
- subcategory;
- structured scope;
- scenario branch;
- question;
- answer;
- photo requirement;
- client rule;
- master rule;
- scenario rule;
- workflow stage;
- form step;
- language.

### Governance

Guidance Records должны поддерживать:
- Draft / Published;
- Audit Log;
- Preview;
- RU / EN / TH localization;
- publication without APK rebuild.

### Business Outcome

По мере роста Helpy платформа масштабирует накопленный опыт.

Ожидаемые эффекты:
- меньше ошибок клиентов;
- меньше ошибок мастеров;
- меньше споров;
- более качественные job scopes;
- более быстрый onboarding новых мастеров;
- постоянное улучшение платформы без mobile releases.

### Relationship With Guided Job Flow

Guidance не является FAQ.

Guidance является операционным компонентом Guided Job Flow.

Guided Job Flow отвечает:

"Как движется заказ?"

Contextual Guidance отвечает:

"Как накопленный опыт платформы помогает участникам успешно пройти каждый этап заказа?"

---
## Mobile Guidance Slots Contract

Status: APPROVED ✅

### Назначение

Mobile screens не должны содержать hardcoded business knowledge, service rules или contextual guidance.

Mobile screens должны содержать guidance slots: стабильные UI-точки, где может отображаться contextual guidance, полученное через API.

### Основное правило

Flutter UI не владеет знаниями платформы.

Flutter UI только отображает structured guidance records, возвращённые API.

### Причина

Это предотвращает business-rule drift между:
- Registry;
- Admin Panel;
- API;
- Mobile UI;
- Client Docs;
- Master Docs;
- Service Playbooks.

### Required Guidance Slots

Mobile screens должны резервировать guidance slots для ключевых этапов Guided Job Flow:

- Create Job;
- photo upload;
- offer creation;
- offer review;
- pre-selection chat;
- price revision;
- master selection;
- deposit/payment;
- work chat;
- start work;
- evidence photos;
- client completion confirmation;
- master complete order;
- review;
- dispute.

### Slot Context

Каждый guidance request должен уметь включать:
- role;
- screen;
- category;
- subcategory;
- structured scope;
- scenario branch;
- form step;
- question;
- answer;
- photo requirement;
- client rule;
- master rule;
- scenario rule;
- job status;
- workflow stage;
- language.

### Runtime Rule

Если API возвращает guidance records, экран отображает их в соответствующем slot.

Если API не возвращает guidance records, экран остаётся чистым и продолжает работать штатно.

Экран не должен добавлять локальные fallback business advice без явного утверждения.

### Implementation Rule

При изменении или создании mobile screens разработчики должны проверить, нужен ли экрану guidance slot.

Если guidance требуется, нужно добавить generic reusable guidance rendering component.

Нельзя добавлять hardcoded instructional text как быстрый patch.

Нельзя позже оборачивать screens магическими guidance overlays.

Нельзя дублировать business knowledge внутри Flutter widgets.

### Admin Rule

Guidance content должно управляться через Admin/Guidance Builder с поддержкой:
- Draft / Published lifecycle;
- Audit Log;
- RU / EN / TH localization;
- Preview;
- publication without APK rebuild.

---
## Language Matching Principle

Status: APPROVED ✅

### Decision

Helpy separates three language concepts:

- UI Language;
- Original Content Language;
- Spoken Languages.

These concepts must not be mixed.

### UI Language

UI Language defines how the interface is displayed to the user.

It controls:
- buttons;
- labels;
- guidance;
- timeline labels;
- system messages;
- category texts.

UI Language must not be used as a proxy for communication compatibility.

### Original Content Language

Original Content Language is the language in which the client originally created the order content.

It is preserved as a business signal.

The localized title rule remains approved:

- main bold title is shown in the selected UI language;
- original client title is shown as secondary small text only if it meaningfully differs from the localized title;
- if translation is missing or identical, the original title is not duplicated.

This rule preserves original meaning and helps the platform understand the client communication context.

### Spoken Languages

Spoken Languages describe which languages a user can communicate in.

They are used for communication compatibility between client and master.

### Matching Rule

The platform should prefer masters who share at least one spoken language with the client.

Shared spoken language may improve:
- offer ranking;
- master recommendation;
- chat quality;
- conversion to selected master;
- completion quality;
- review quality;
- dispute prevention.

### Business Principle

Translation helps users understand content.

Language matching helps users communicate.

These are different platform responsibilities.

### Future Product Usage

Language compatibility may later affect:
- master ranking;
- badges in master profile;
- offer sorting;
- admin quality analytics;
- dispute analytics;
- onboarding recommendations.

---
## Language Matching Ranking Rule

Status: APPROVED ✅

### Decision

Language Matching is a ranking signal, not a hard filter.

The platform should prefer masters who share at least one spoken language with the client, but it must not hide other eligible masters.

### Rule

If a client and master share a spoken language:
- the master may receive ranking preference;
- communication quality is expected to improve;
- dispute risk may be reduced.

If no shared spoken language exists:
- the master may still be shown;
- the master may still apply;
- the client may still select that master.

### Business Reason

Helpy should improve communication quality without artificially limiting marketplace supply.

This is especially important in Pattaya, where masters and clients may speak different combinations of:
- RU;
- EN;
- TH;
- other regional languages.

### Implementation Principle

Language compatibility may affect:
- offer ordering;
- master recommendation;
- profile badges;
- admin analytics.

Language compatibility must not be used as the only eligibility rule unless a future explicit business rule is approved.

---
## Master Ranking Signal Hierarchy

Status: APPROVED ✅

### Decision

Master ranking signals are applied in the following conceptual order:

1. shared_spoken_language
2. work_quality_rating
3. reliability_ratio
4. completed_jobs_count
5. review_count

### Signal Meaning

shared_spoken_language
- communication compatibility signal;
- ranking signal only;
- must not hide other eligible masters.

work_quality_rating
- average star rating from submitted reviews;
- represents quality of completed work.

reliability_ratio
- represents adherence to agreements;
- includes punctuality and communication quality;
- uses the approved Helpy reliability icon;
- calculated only from actual submitted reviews.

completed_jobs_count
- represents accumulated experience;
- does not imply quality or reliability by itself.

review_count
- confidence/trust signal;
- increases confidence in other metrics;
- does not represent quality independently.

### Business Principle

Helpy should prioritize:
- effective communication;
- quality of work;
- reliability;
- practical experience;
- confidence in statistics.

No single signal should become an absolute eligibility filter unless explicitly approved by future business rules.
---
## Master Ranking Hybrid Model Contract

Status: APPROVED ✅

### Decision

Helpy uses a hybrid master ranking model.

The model separates:

1. Eligibility
2. Ranking
3. Client Choice

These concepts must not be mixed.

### Eligibility

Eligibility answers:

"Can this master participate in this order?"

Eligibility is a yes/no business decision.

Examples:
- master profile is active;
- master is not blocked;
- master supports the selected category/subcategory;
- category/subcategory is enabled;
- master meets required skill or verification rules if applicable.

Ineligible masters must not be shown as available for the order.

### Ranking

Ranking answers:

"In what order should eligible masters or offers be presented?"

Ranking affects presentation order only.

Ranking must not hide eligible masters.

Ranking must use approved MVP signals:

1. shared_spoken_language
2. work_quality_rating
3. reliability_ratio
4. completed_jobs_count
5. review_count

### Hybrid Model

Helpy does not use pure hard sorting.

Helpy does not use unexplained black-box scoring.

Helpy uses a hybrid model:

- eligibility gates define who may participate;
- approved ranking signals influence ordering;
- signal hierarchy defines conceptual priority;
- final choice remains with the client.

### Signal Application Rule

Ranking signals should improve ordering, not create absolute exclusion.

A master with weaker ranking signals may still be visible if eligible.

A master with no shared spoken language may still be visible and selectable.

A new master must not be hidden only because they have fewer reviews or completed jobs.

### No Hidden Penalty Rule

MVP ranking must not use:
- hidden coefficients;
- hidden penalties;
- temporal weights;
- penalties for new masters;
- platform assumptions not supported by explicit user/client feedback.

### Review Count Rule

review_count is the last ranking signal.

It is a confidence/trust signal, not an independent quality signal.

It may increase confidence in work_quality_rating and reliability_ratio, but must not dominate them.

### Client Choice Rule

Helpy recommends.

Client decides.

Client selection of the master is the official acceptance of Final Price and selected master.

### Admin Rule

Any future change to ranking signals, weights, eligibility rules or visibility rules must be explicitly approved and auditable.

Admin configuration may tune published ranking behavior only after the contract, implementation and audit model support it.

### Business Principle

Helpy should help clients find the best-fit master without artificially limiting marketplace supply.

The platform should improve decision quality while preserving client freedom of choice.
---
## Guidance API Contract

Status: APPROVED ✅

### Purpose

Guidance API delivers structured contextual guidance records to mobile screens.

Mobile applications must not read Markdown documents.

Mobile applications must not hardcode business guidance text.

### Source Of Truth

Guidance API reads published Guidance Records managed through Admin / Guidance Builder.

Guidance content is derived from:
- Approved Category Architecture;
- Client Rules / Master Rules / Scenario Rules;
- Client Docs / Master Docs;
- Service Playbooks;
- Admin Rules;
- approved workflow rules.

### Endpoints

Mobile:

GET /api/v1/guidance

Admin Preview:

GET /api/v1/admin/guidance/preview

### Mobile Request Context

Mobile guidance requests must be able to pass:

- role;
- screen;
- category;
- subcategory;
- structured_scope;
- scenario_branch;
- form_step;
- question_key;
- answer_key;
- photo_requirement_key;
- photo_step;
- client_rule_key;
- master_rule_key;
- scenario_rule_key;
- job_status;
- workflow_stage;
- event_type;
- language.

Not every field is required for every screen.

The API must match the most specific published guidance records available.

### Response Shape

Response must use the standard API envelope:

{
  "success": true,
  "data": {
    "items": [
      {
        "id": "...",
        "slot": "before_form_step",
        "role": "client",
        "context": "create_order",
        "title": "...",
        "body": "...",
        "severity": "info",
        "cta": {
          "type": "open_chat",
          "label": "Open chat"
        },
        "dismissible": true
      }
    ]
  }
}

### Empty Response Rule

If no matching guidance exists, API returns:

{
  "success": true,
  "data": {
    "items": []
  }
}

Mobile must keep the screen clean and continue normally.

### Publication Rule

Mobile API returns only Published guidance.

Draft guidance must never be visible to normal users.

Admin Preview API may return Draft guidance for preview and testing.

### Localization Rule

Guidance API returns text in requested language.

Supported launch languages:
- RU;
- EN;
- TH.

If a requested translation is unavailable, API may return configured fallback text, but must not make one language structurally primary.

### CTA Rule

Guidance records may include CTA metadata.

CTA examples:
- open_chat;
- pay_deposit;
- upload_evidence_photos;
- confirm_completion;
- complete_order;
- leave_review;
- open_dispute.

CTA from guidance is presentation only.

Backend business rules remain the source of permission.

### Priority Rule

When multiple records match, API should return records ordered by:
1. exact context match;
2. workflow stage specificity;
3. category/subcategory specificity;
4. form step or event specificity;
5. admin-defined sort order.

### Audit / Governance

Guidance changes must support:
- Draft / Published lifecycle;
- Audit Log;
- Preview;
- RU / EN / TH localization;
- publication without APK rebuild.

### Implementation Rule

Flutter renders guidance records.

Flutter does not own guidance content.

Flutter does not duplicate business rules inside widgets.

### Guidance API Contract Completion Addendum

Status: APPROVED ✅

Purpose:
Close the remaining Guidance API contract gaps before implementation.

This addendum is part of the Guidance API Contract.
It does not create a migration by itself.
It defines the required API and data contract for future implementation.

### Required Guidance Record Identity

Every guidance record returned by API must include:

- id;
- guidance_key;
- version;
- published_at;
- slot;
- role;
- context;
- title;
- body;
- severity;
- dismissible.

Rules:
- `id` is the internal record identifier.
- `guidance_key` is the stable business key used by mobile, admin, analytics and dismiss tracking.
- `version` identifies the published content version.
- `published_at` identifies the exact published revision visible to users.
- Mobile must not treat translated text as identity.
- Mobile must not derive identity from title or body.

### Guidance Key Rule

`guidance_key` must be stable across languages.

Allowed format:
- lowercase;
- snake_case;
- scoped by product area where useful.

Examples:
- create_order_plumbing_faucet_photo_tip;
- offer_review_price_change_warning;
- work_started_evidence_photo_reminder;
- completion_confirm_review_notice.

Changing text must not require changing `guidance_key`.

Changing business meaning should create a new `guidance_key` or increment version according to Admin publishing rules.

### Version Rule

Guidance records must support versioning.

Version is required for:
- audit;
- rollback;
- dismiss behavior;
- analytics;
- Admin Preview comparison.

Mobile must receive the currently published version.

If a dismissed guidance record is republished with a new version, dismiss behavior depends on dismiss scope.

### Published At Rule

`published_at` must be returned for every Published guidance record.

Purpose:
- prove which guidance version was visible at runtime;
- support admin audit;
- support dispute and quality review if guidance behavior is questioned.

Draft records returned by Admin Preview may use `draft_updated_at` instead of `published_at`.

### Severity Rule

Supported severity values for MVP:

- info;
- warning;
- critical.

Meaning:
- `info` is normal contextual help.
- `warning` is risk prevention or important workflow guidance.
- `critical` is reserved for safety, payment, dispute, compliance or irreversible workflow risk.

Rules:
- `critical` guidance must be short and action-oriented.
- `critical` guidance must not be dismissible by default unless explicitly approved.
- Mobile rendering may visually emphasize severity, but business permissions remain backend-owned.
- Severity must not be used as a substitute for backend validation.

### Dismissible Rule

`dismissible` controls whether the user may hide a guidance record from the current UI.

Rules:
- `dismissible = true` means user may hide the record according to its dismiss scope.
- `dismissible = false` means mobile must show the record whenever returned by API.
- Payment, dispute, safety and irreversible workflow guidance should default to `dismissible = false`.
- Routine hints and educational guidance may be dismissible.

### Dismiss Scope Rule

Guidance dismiss behavior must support explicit scope.

Supported dismiss scopes:

- session;
- user;
- job;
- job_stage;
- guidance_version.

Meaning:
- `session`: hidden until app/session refresh.
- `user`: hidden for the user until guidance version changes.
- `job`: hidden only for this job.
- `job_stage`: hidden only for this job and workflow stage.
- `guidance_version`: hidden for this exact guidance_key + version.

Default MVP scope:
- `guidance_version`.

Rules:
- Mobile must not invent dismiss scope.
- API response must include dismiss metadata when dismissible is true.
- Dismissed records must not disappear from Admin Preview.
- Dismiss tracking must not delete the guidance record.

### Slot Return Limit Rule

Guidance API must limit records per slot.

MVP default:
- maximum 1 primary guidance record per slot.

Future reserved:
- API may return up to 3 records per slot only if mobile component supports stacked rendering.

Rules:
- API must order records before returning them.
- Mobile must render records in API order.
- Mobile must not choose the best guidance locally.
- If more records match than the slot limit allows, API decides by priority and sort order.

### Response Shape Addendum

Each item in `data.items` must support:

{
  "id": "...",
  "guidance_key": "...",
  "version": 1,
  "published_at": "...",
  "slot": "...",
  "role": "...",
  "context": "...",
  "title": "...",
  "body": "...",
  "severity": "info",
  "dismissible": true,
  "dismiss_scope": "guidance_version",
  "cta": null,
  "analytics": {
    "impression_event": "guidance_impression",
    "dismiss_event": "guidance_dismissed",
    "cta_event": "guidance_cta_clicked"
  }
}

### Analytics Event Rule

Guidance API contract reserves analytics events.

MVP implementation may log server-side only first.

Required analytics event names:

- guidance_impression;
- guidance_dismissed;
- guidance_cta_clicked.

Required event dimensions:

- guidance_key;
- version;
- role;
- screen;
- slot;
- language;
- category;
- subcategory;
- workflow_stage;
- event_type;
- job_id when available.

Rules:
- Analytics must not contain message text or private chat content.
- Analytics must not become a permission source.
- Analytics must support Admin quality review later.

### API Responsibility Rule

Guidance API is responsible for:
- matching records;
- filtering unpublished records;
- applying actor/context visibility;
- sorting by priority;
- enforcing slot limits;
- returning identity/version/dismiss metadata.

Flutter is responsible only for:
- requesting guidance with context;
- rendering returned records;
- sending dismiss / analytics actions when supported.

Flutter must not:
- hardcode guidance text;
- hardcode business conditions for guidance visibility;
- locally rank guidance records;
- silently generate guidance when API returns empty items.

### Contract Closure Rule

Guidance API Contract is considered Closed for MVP only when it defines:

- identity;
- guidance_key;
- version;
- published_at;
- severity rules;
- dismissible rules;
- dismiss scope;
- slot limits;
- analytics events;
- API/mobile responsibility boundary.

Implementation is still a separate step.
No DB migration should be written from this addendum alone.

## Mobile Guidance Component Contract

Status: APPROVED ✅

### Purpose

Mobile Guidance Component defines how Flutter renders structured guidance records returned by Guidance API.

This contract closes the gap between:
- Guidance API Contract;
- Mobile Guidance Slots Contract;
- Guided Job Flow;
- Flutter screen implementation.

Flutter must render guidance records consistently without owning business guidance content.

### Source Of Truth

Guidance text, severity, dismiss behavior, CTA metadata and record priority come from Guidance API.

Flutter owns only:
- layout;
- visual rendering;
- user interaction dispatch;
- loading and empty-state behavior.

Flutter must not:
- hardcode business guidance text;
- hardcode service rules;
- locally decide which guidance is more important;
- create fallback guidance when API returns no items.

### Component Name

Canonical mobile component name:

`GuidanceCard`

Reserved supporting components:
- `GuidanceSlot`;
- `GuidanceCtaButton`;
- `GuidanceDismissButton`.

Implementation may choose exact Flutter class names later, but architecture must preserve these responsibilities.

### Input Contract

The component receives already matched guidance records from API.

Required item fields:
- id;
- guidance_key;
- version;
- published_at;
- slot;
- role;
- context;
- title;
- body;
- severity;
- dismissible;
- dismiss_scope;
- cta;
- analytics.

The component must not require Markdown parsing.

Body text must be plain localized text for MVP.

### Slot Rendering Rule

A mobile screen renders guidance only inside approved guidance slots.

Rules:
- each slot requests or receives guidance by slot key;
- slot placement is screen-owned;
- record content is API-owned;
- empty slots render nothing;
- empty slots must not leave blank cards, loaders or layout gaps;
- mobile must not show guidance outside declared slots.

### Card Layout Rule

GuidanceCard MVP layout:

- optional severity icon;
- title;
- body;
- optional CTA button;
- optional dismiss action if dismissible is true.

Rules:
- title should be short;
- body should be concise and action-oriented;
- card must not block the main flow unless backend permissions block the action;
- card must not replace form validation, payment validation or backend authorization.

### Severity UI Rule

Supported severity values:
- info;
- warning;
- critical.

Rendering rules:
- info: neutral contextual help;
- warning: visible risk-prevention hint;
- critical: high-attention message for safety, payment, dispute, compliance or irreversible workflow risk.

Rules:
- severity changes presentation only;
- severity must not change backend permissions;
- critical guidance should remain visible when dismissible is false;
- mobile must gracefully render unknown severity as info and report the mismatch when analytics/logging exists.

### CTA Rendering Rule

Guidance CTA is presentation metadata.

Supported MVP CTA types:
- open_chat;
- pay_deposit;
- upload_evidence_photos;
- confirm_completion;
- complete_order;
- leave_review;
- open_dispute.

Rules:
- CTA button may navigate or call an existing screen action;
- CTA must not bypass backend permissions;
- if CTA target is unavailable, card remains visible without crashing;
- mobile may hide unsupported CTA button but must still render guidance text;
- CTA labels come from API/localization contract, not hardcoded business text.

### Dismiss UX Rule

If `dismissible = true`, GuidanceCard may show a dismiss action.

Rules:
- dismiss action must use API-provided `guidance_key`, `version` and `dismiss_scope`;
- mobile must not invent dismiss scope;
- dismissing hides only according to dismiss scope;
- dismissing must not delete local or server guidance content;
- non-dismissible guidance must not show a dismiss action.

MVP may store dismiss locally only if backend dismiss endpoint is not implemented yet.
When backend support exists, dismiss must be sent to API.

### Loading Rule

Guidance loading must not block the main screen.

Rules:
- screen must remain usable while guidance loads;
- no full-screen loader for guidance;
- no screen-level flicker when guidance refreshes;
- stale guidance may remain until fresh response arrives;
- failed guidance request must not block job creation, offer submission, chat, payment or completion.

### Error Rule

Guidance errors are non-fatal for MVP.

Rules:
- user-facing red error banners must not be shown for guidance loading failure;
- technical errors may be logged;
- screen continues normally with no guidance items;
- backend validation errors for the actual business action are separate and may still be shown.

### Analytics Dispatch Rule

Component must reserve hooks for:
- guidance_impression;
- guidance_dismissed;
- guidance_cta_clicked.

Rules:
- impression should fire only when a card is actually rendered;
- dismiss event should include guidance_key, version, slot and dismiss_scope;
- CTA event should include guidance_key, version, slot and cta.type;
- analytics must not include body text, private chat content or uploaded photo content.

### Accessibility / Localization Rule

GuidanceCard must support:
- RU;
- EN;
- TH;
- longer translated text;
- multiline body;
- dynamic text scaling.

Rules:
- card must not assume equal text length across languages;
- Thai text must not be truncated in a way that hides action meaning;
- CTA label must remain readable;
- mobile must not duplicate original guidance text in another language unless API explicitly returns it.

### Reuse Rule

GuidanceCard must be reusable across:
- create order flow;
- offer review;
- payment/deposit;
- chat/work coordination;
- evidence upload;
- completion;
- review;
- dispute prevention;
- master workflow.

Each screen owns placement.
The component owns rendering.
The API owns content and matching.

### No Overlay Rule

Guidance must not be implemented as magic overlays wrapped around screens.

Rules:
- no global surprise popups for normal guidance;
- no screen-covering guidance layer for MVP;
- no blocking modal unless future contract explicitly approves it;
- guidance belongs inside declared slots.

### Mobile Responsibility Boundary

Flutter may:
- request guidance;
- render cards;
- navigate from supported CTA;
- send dismiss and analytics events;
- cache last successful guidance response if needed.

Flutter must not:
- derive lifecycle state from guidance;
- decide business permissions from guidance;
- emit job_events from guidance;
- create or modify guidance records;
- read raw Markdown docs;
- rank competing guidance records locally.

### Done Criteria

Mobile Guidance Component Contract is Closed for MVP when it defines:

- component responsibility;
- input fields;
- slot rendering;
- card layout;
- severity rendering;
- CTA behavior;
- dismiss UX;
- loading behavior;
- error behavior;
- analytics hooks;
- localization/accessibility;
- no-overlay rule;
- Flutter/API responsibility boundary.

Implementation is still a separate step.
No Flutter code should be written from this contract until Mobile Timeline Contract and Guided Job Flow Screen Architecture are also closed.

## Client Identity & Usage Contract

### Client Rules

• Клиентом Helpy может быть только человек, который находится в Таиланде и самостоятельно использует сервис.

• Аккаунт Helpy предназначен для личного использования. Передача аккаунта другим лицам запрещена.

• Клиент лично принимает решения по работам, оформленным через Helpy, включая:
  – создание работ;
  – выбор мастера;
  – принятие решений в процессе выполнения;
  – завершение работы;
  – участие в споре при необходимости.

• При регистрации клиент обязан указать:
  – номер телефона;
  – email.

• Email является основной идентичностью клиента и используется для:
  – входа в аккаунт;
  – Email OTP;
  – восстановления доступа;
  – долгосрочной связи платформы с клиентом.

• Номер телефона является обязательным, но вторичным каналом связи и используется для:
  – связи платформы с клиентом при необходимости;
  – административных процедур;
  – разрешения спорных ситуаций.

• Мастера не видят телефон и email клиентов.
• Клиенты не видят телефон и email мастеров.

• Взаимодействие между клиентом и мастером осуществляется только через встроенный чат Helpy.

### Registration Confirmation

При завершении регистрации клиент подтверждает, что:

• находится в Таиланде;
• лично принимает решения по работам, оформленным через Helpy;
• не передаёт свой аккаунт другим лицам.

### Registration Flow

1. Phone *
2. Email *
3. Email OTP
4. Display Name *
5. Подтверждение условий
6. Активировать аккаунт

### Client Registration Screen Contract

Экран 1

Phone *
Email *
Email OTP *

[Продолжить]

↓

Экран 2

Display Name *

☐ Я подтверждаю условия

[Активировать аккаунт]

### Not Used

• SMS OTP;
• обязательная GPS-проверка;
• обязательная проверка IP;
• отображение клиенту термина Guided Job Flow;
• передача контактов между клиентом и мастером;
• использование одного аккаунта несколькими людьми.

----
## Master Identity & Access Contract

### Master Rules

• Мастером Helpy может быть только человек, который самостоятельно оказывает услуги на территории Таиланда.

• Аккаунт мастера предназначен для личного использования. Передача аккаунта другим лицам запрещена.

• Мастер лично отвечает за:
  – отклики на заказы;
  – подтверждение готовности выполнять работы;
  – соблюдение требований безопасности;
  – выполнение работ;
  – участие в спорах при необходимости.

• При регистрации мастер обязан указать:
  – номер телефона;
  – email;
  – Display Name;
  – фотографию профиля;
  – документ, подтверждающий личность.

• Email является основной идентичностью мастера и используется для:
  – входа в аккаунт;
  – Email OTP;
  – восстановления доступа;
  – долгосрочной связи платформы с мастером.

• Номер телефона является обязательным, но вторичным каналом связи и используется для:
  – административных процедур;
  – разрешения спорных ситуаций;
  – экстренной связи платформы с мастером.

• Клиенты не видят телефон и email мастеров.
• Мастера не видят телефон и email клиентов.

• Взаимодействие между клиентом и мастером осуществляется только через встроенный чат Helpy.

### Registration Flow

1. Phone *
2. Email *
3. Email OTP
4. Display Name *
5. Profile Photo *
6. Identity Document *
7. Подтверждение условий
8. Активировать аккаунт

### Safety Gate

• Safety Gate применяется перед фиксацией master_selected.

• Если мастер проходит обязательные требования безопасности:
  – создаётся master_selected.

• Если мастер отказывается от обязательных safety requirements:
  – заказ возвращается в open;
  – фиксируется отказ;
  – увеличивается счётчик отказов;
  – мастер получает предупреждение.

• После третьего отказа мастер переводится в suspended до решения администрации.

### Not Used

• SMS OTP;
• обязательная GPS-проверка;
• обязательная проверка IP;
• постоянный GPS-трекинг мастера;
• selfie с документом;
• обязательное указание банковских реквизитов на этапе регистрации;
• передача контактов между клиентом и мастером;
• использование одного аккаунта несколькими людьми.
