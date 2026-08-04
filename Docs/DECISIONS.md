# DECISIONS

Use this format for decisions: context, decision, alternatives, consequences, and affected files.

## 2026-07-29 — Store money as Int64 minor units

Context: SwiftData predicates on `Decimal` are unreliable, while floating-point
types introduce rounding errors that are unacceptable for financial state.

Decision: Persist `amountMinorUnits: Int64` with `currencyCode`. Use `Decimal`
only for explicit presentation conversions; aggregate and compare with integers.

Alternatives considered: stored `Decimal`, `Double`, and `NSDecimalNumber`.

Consequences: The project needs a `Money` value type and explicit currency
exponents. Cross-currency arithmetic fails rather than silently converting.

Files affected: future `Models/Money.swift`, model files, and budget services.

---

## 2026-08-02 — Close v3.1 money, reminder, and Ask contracts

Context: The v3 review found contradictions in currency switching, quiet hours,
and the boundary between raw Ask text and model input.

Decision: Lock the accounting currency after financial data exists; isolate the
App Intents floating-point transport edge; use value-type quiet hours and deferred
notification times; keep raw Ask text inside the local classifier.

Alternatives considered: relabelling amounts, `Range<Int>` quiet hours, and sending
the raw question to a language model.

Consequences: Changing currency requires export/delete/re-onboarding in V1. AI
receives only intent keys and redacted facts. Template Ask is an L0 feature.

Files affected: the authoritative v3.1 specification and future money, reminder,
redaction, Ask, and App Intents files.

---

## 2026-08-02 — Bootstrap with a manually versioned Xcode project

Context: The workspace was empty and neither XcodeGen nor Tuist was installed.
The specification requires an `.xcodeproj`, app target, unit-test target, and
UI-test target during Phase 0.

Decision: Commit a minimal Xcode project directly, target iOS 17.0, use Swift 6
with complete strict concurrency, and share one `MindBudget` scheme. Validate on
the installed iPhone 17 Pro simulator running iOS 26.5.

Alternatives considered: adding a project generator dependency or postponing the
project until a GUI-generated template was available.

Consequences: The repository has no bootstrap dependency. Future source files must
be added to the project file deliberately. The simulator destination may be
overridden through `MINDBUDGET_TEST_DESTINATION` on another machine.

Files affected: `MindBudget.xcodeproj`, `AGENTS.md`, `README.md`, and this file.

---

## 2026-08-02 — Keep capability flags separate from user consent

Context: Review feedback interpreted `FeatureFlags.enableFoundationModels`, Siri,
Spotlight, and onscreen-awareness values as default user preferences. The v3.1
specification requires the values during Phase 0 while also prohibiting those
features from being implemented in that phase, so "implemented" cannot be their
literal Phase 0 meaning.

Decision: Treat these booleans as product-scope gates: `true` permits a planned V1
capability to be implemented. It does not claim the implementation already exists.
Effective access is the conjunction of the scope flag, API and OS availability,
runtime capability, and an explicit default-off user setting.

Alternatives considered: Setting every flag to false, which would contradict the
required Phase 0 values and conflate product scope with implementation readiness.

Consequences: SettingsStore defaults require dedicated tests when implemented.
A true capability flag never authorizes data access or activates a user feature.
Phase 7/8 call sites must not read raw FeatureFlags directly; each capability must
expose one centralized gate that evaluates the full conjunction and has tests.

Files affected: `MindBudget/App/FeatureFlags.swift`, privacy and Siri documentation.

---

## 2026-08-02 — Limit V1 to iPhone and keep the public repository proprietary

Context: Supporting iPad adds layout, screenshot, accessibility, and release QA
scope. Public visibility also does not imply permission to reuse the project.

Decision: Set the V1 targeted device family to iPhone only. Publish source for
review while reserving all rights and granting no open-source license.

Alternatives considered: Universal iPhone/iPad support and an MIT license.

Consequences: iPad support needs a later scoped product decision. Forks may inspect
the source but have no permission to use or redistribute it without written consent.

Files affected: `MindBudget.xcodeproj`, `README.md`, `LICENSE`, and project memory.

---

## 2026-08-02 — Define project-generator migration triggers

Context: A hand-maintained pbxproj avoids a bootstrap dependency but becomes costly
when multiple branches add files, packages, or targets concurrently.

Decision: Re-evaluate XcodeGen or Tuist before the first of these events: two active
branches both need pbxproj edits; a recurring pbxproj merge conflict appears; adding
packages or targets makes manual project edits error-prone; or an Xcode upgrade causes
a large structural project-file rewrite. Record the selected generator before adoption.

Alternatives considered: Migrating immediately, or retaining manual maintenance
without an explicit threshold.

Consequences: Phase work stays dependency-free today, while the team has objective
signals for switching before project-file conflicts become routine.

Files affected: `MindBudget.xcodeproj` and `Docs/DECISIONS.md`.

---

## 2026-08-02 — Align hosted CI with the development toolchain

Context: The first workflow used Xcode 16.4 and a fixed iOS 18.5 runtime while local
development requires Xcode 26.6. That configuration could not compile planned iOS 26
capabilities and would fail whenever the hosted image removed the fixed runtime.

Decision: Run hosted CI on the macOS 26 image, require Xcode 26.6 or a later compatible
Xcode 26 release, and discover the newest available iOS 26 simulator runtime dynamically.
Validate the app target's deployment setting directly rather than matching any target
from scheme-wide build settings. Ignore newer preview runtimes that the selected Xcode
generation cannot support.

Alternatives considered: Keeping Xcode 16.4 until Phase 7/8, or documenting the
mismatch without fixing it.

Consequences: Local and hosted builds use the same Xcode generation and iOS SDK family.
Compatible runtime image rotation does not require a workflow edit. Real iOS 17 runtime
testing remains a release-validation responsibility until an appropriate runner is
available.

Files affected: `.github/workflows/ci.yml`, validation scripts, and project memory.

---

## 2026-08-03 — Persist ratios as basis points and isolate SwiftData behind DataActor

Context: The authoritative model sketches used binary floating-point fields for
category warning thresholds even though the repository-wide financial-source guard
forbids those types. Swift 6 also makes returning SwiftData models or `ModelContext`
from an actor unsafe.

Decision: Persist category warning thresholds as integer basis points, where 10,000
means 100 percent. Keep rule ratios in `Decimal`, and use basis points or `Decimal`
for future engine projections until a presentation-only conversion is explicitly
needed. Route all model writes through `DataActor` and return only immutable,
`Sendable` projections. Begin the V1 currency table with the currencies exposed by
`Money.supportedCurrencyCodes`; Phase 3 onboarding must use that table rather than
accept an unknown locale currency.

Alternatives considered: Weakening the source guard for threshold fields, storing
binary floating-point ratios, exposing `@Model` instances across actors, or silently
assuming two fractional digits for unknown currencies.

Consequences: Threshold boundaries are exact and directly compatible with reminder
event risk history. Phase 2 engines receive safe value types. A schema change from
`warningThresholdBasisPoints` requires a new versioned schema and migration rather
than editing `SchemaV1` after release.

Files affected: `MindBudget/Models`, `MindBudget/Data`, rule/settings services, tests,
and this file.

---

## 2026-08-03 — Use a currency-neutral entry limit and reject corrupt projections

Context: A limit of one million major units gave low-value currencies such as KRW,
VND, and IDR far less usable purchasing range than USD. Persisted raw currency and
enum strings could also trigger a process precondition or silently become a valid-
looking fallback state. Creating more than one `DataActor` weakened read-before-write
invariants across contexts.

Decision: Treat `Money.maximumMinorUnits(for:)` as a currency-neutral storage-safety
limit of `Int64.max / 1_000_000`, leaving headroom for one million maximum-sized
aggregate additions. Keep input reasonableness as a UI warning rather than a currency-
dependent hard rejection. Validate every persisted currency and projected enum raw
value, returning `PersistedModelError` instead of crashing or inventing a fallback.
Each `DataController` owns one shared `DataActor`. Sample replacement uses one save
and rolls back all pending changes on failure. Merchant aggregates are derived from
expense writes and deletes as required by the model contract.

Alternatives considered: Per-currency purchasing-power limits, exchange-rate-driven
limits, optional projections that discard invalid values, `.unknown` business states,
and creating a new actor for each caller.

Consequences: Low-value currencies retain practical input range without exchange-rate
maintenance. Corrupt or future-version data remains visible as a recoverable error and
cannot re-enter reminder or state-machine logic under a false default. All app writes
must continue through the controller-owned actor; tests may use a separate seeder actor
only to verify corruption handling.

Files affected: `MindBudget/Models/Money.swift`, model projections, `DataActor`,
`DataController`, tests, and the authoritative money contract.

---

## 2026-08-03 — Persist merchant normalization and keep local aggregates independent of indexing consent

Context: Rebuilding one derived `Merchant` fetched every expense and normalized raw
names in memory. The per-expense `allowMerchantIndexing` field and the global
`indexMerchantNames` preference also lacked an explicit relationship to the local
merchant aggregate, risking either incomplete local insights or accidental system
index disclosure in Phase 8A.

Decision: Persist `Expense.normalizedMerchantName` in `SchemaV1` and set it atomically
with `merchantName` at the `DataActor` write boundary. Use the persisted key in
merchant rebuild predicates. `Merchant` always aggregates every matching local
expense, regardless of `allowMerchantIndexing`; local analytics must not change when
system-integration consent changes. Phase 8A may index a merchant name only through a
centralized Spotlight gate and when `indexMerchantNames` is enabled and at least one
expense with the same normalized key has `allowMerchantIndexing == true`.

Alternatives considered: Re-normalizing every fetched expense, excluding opted-out
expenses from local merchant totals, or storing a second indexing-eligibility field on
`Merchant` before the indexing service exists.

Consequences: Merchant rebuilds no longer materialize unrelated expenses. The
normalization algorithm is now a persistence contract; changing it after release
requires a schema migration or explicit derived-data rebuild. Phase 8A must query
eligible expenses rather than treating the existence of a `Merchant` row as consent.

Files affected: `Expense`, `DataActor`, merchant persistence tests, privacy plans, and
Phase 8A acceptance criteria.

---

## 2026-08-03 — Keep budget calculation value-based and make future cycle changes contiguous

Context: The Phase 2 service sketch mixed a non-Sendable SwiftData `BudgetPlan` with a
pure `Sendable` engine. An initial implementation represented configuration as one Boolean
plus parallel optional metrics, accepted reference dates outside the current cycle, and
gave undefined or non-discretionary free-budget ratios a numeric value. Changing a cycle
start day also needed a safe boundary between immutable history and the new cadence;
silently copying a full monthly budget into a one-day transition could overstate what is
safe to spend. A later review found the inverse propagation risk: once a user confirmed a
reduced transition budget, treating that short plan as the next copy source silently
understated every following complete cycle.

Decision: `BudgetSnapshot` is a two-state enum: `.unconfigured` carries only cycle/currency
identity, while `.configured(ConfiguredBudgetSnapshot)` carries nonoptional metrics.
`BudgetEngine` accepts only Sendable summaries plus an explicit accounting currency,
reference date, and calendar; the reference date must lie in `[cycleStart, cycleEnd)`.
Configured calculations use checked `Int64`, and ratios remain `Decimal`. Free-budget
ratio and days-consumed metrics are optional and exist only for discretionary spending
with a positive denominator. `impact` accepts only a configured snapshot. For lazy roll-
forward, every automatic plan begins exactly at the prior immutable end, but at most 120
plans may be generated in one atomic call. A shorter transition caused by a changed start
day is not auto-prorated or given a copied monthly budget: `DataActor` returns
`.transitionPlanRequired`, including both the shortened interval and the first complete
interval on the new cadence. Those intervals have independent user-confirmed budgets. If
only the transition is saved, the next coverage request returns
`.firstRegularPlanRequired` instead of copying the transition amounts. Automatic copying
resumes only from the confirmed first complete plan.

Alternatives considered: Passing `@Model` instances into the engine, representing no
budget as zero, returning `Double` ratios, silently wrapping arithmetic, treating an
undefined ratio as 100%, moving category risk queries into persistence, recomputing
historical boundaries, auto-prorating nonuniform bills, copying a full budget into a short
transition, allowing gaps between the old and new cadence, propagating the reduced
transition budget, silently choosing an older
"canonical" plan whose cadence or amounts may no longer express user intent, and inventing
a prorated recurring baseline.

Consequences: Illegal configured/optional combinations cannot compile. Phase 3 switches
once on the snapshot state, renders setup for `.unconfigured`, and must present a budget-
confirmation flow for `.transitionPlanRequired` that collects separate transition and
first-regular values. `.firstRegularPlanRequired` is a persistence-safe fallback when the
transition was saved alone. A crash or interrupted flow cannot make the reduced amount a
recurring default. Historical summaries use their own aggregate path instead of calling
current-cycle safe-daily calculations with today's date. An excessive clock jump returns a
typed generation-limit error without partial inserts. Presentation code formats `Decimal`
directly rather than reintroducing floating-point money paths.

Files affected: budget/cycle/formatting services, `DataActor`, Phase 2 tests, project
memory, and the authoritative development contract.

---

## 2026-08-03 — Drive Phase 3 UI from value projections and exact localized input

Context: Phase 3 needed responsive SwiftUI screens without moving SwiftData models or
write authority onto the main actor. Manual amount text could contain locale-specific
digits and separators, and a user-selected expense date could belong to a different
budget cycle from today. The shortened transition and first regular cycle also had to be
confirmed without allowing a partial save or accidental amount propagation.

Decision: `AppSession` owns the controller's shared `DataActor`; feature view models read
Sendable summaries and signal a revision only after successful actor writes. Dashboard
and list projections reload on that revision and when the app becomes active, covering
both in-app edits and later external integrations without exposing `@Model` instances to
views. Manual amounts accept validated locale digits and grouping but must map exactly to
the accounting currency's minor-unit exponent; extra precision and malformed grouping are
rejected rather than rounded or reinterpreted. Expense impact and cycle coverage use the
selected `spentAt` date, and save rechecks coverage. Transition and first-regular drafts
commit together through one `DataActor` transaction; recovery of a lone transition keeps
the regular-period fields blank and requires explicit confirmation.

Alternatives considered: Letting views write through `ModelContext`, using binary
floating-point text parsing, silently rounding fractional minor units, calculating every
expense against today's cycle, polling the store, saving transition plans one at a time,
and copying a reduced short-period amount into the regular cycle.

Consequences: All Phase 3 mutations preserve the actor boundary and merchant aggregates.
The UI refresh contract is explicit and testable, while later App Intents can become
visible on foreground activation. Pasted amounts that do not follow the active locale's
grouping are rejected with a friendly field error instead of being saved as a different
number. A historical date with no plan may still be recorded, but no budget impact is
invented. Future phases must continue to notify the app session after in-process writes
and keep system-integration writes behind `DataActor`.

Files affected: app routing/session state, Phase 3 feature views and view models,
`DataActor`, localized resources, and Phase 3 unit/UI tests.

---

## 2026-08-03 — Keep expense preview read-only and raw notes out of general projections

Context: A Phase 3 review found that changing the expense date called the mutating
`ensurePlanCovering`, so a DatePicker gesture could persist future budget plans even when
the form was cancelled. The same review found that adding raw notes to the general
`ExpenseSummary` projection weakened the Phase 7 privacy boundary, and that the UI-test
reset launch argument remained compiled into Release. The expense form also collapsed
unconfigured, historical, transition, and load-failure states into one misleading label.

Decision: `previewPlanCoverage` computes the same coverage or projected copied plan without
materializing drafts or saving the model context. Interactive date previews use only that
API and are debounced by a cancellable view task. `ensurePlanCovering` remains the explicit
write path used by Dashboard lifecycle work and immediately before expense persistence; it
does not call `save()` when no plan needs insertion. Expense recording remains available
when no plan exists or a transition/first-regular budget awaits confirmation, but the form
shows a truthful typed context and never invents an impact value. Raw notes are absent from
`ExpenseSummary`; only `ExpenseDetail` exposes one requested note, while note search runs
inside `DataActor` and returns matching expense IDs. Phase 7 redaction must accept only
allow-listed aggregate inputs and must never accept `ExpenseDetail`. The UI-test reset hook
is compiled only under `#if DEBUG`.

Amount reasonableness remains relative to a user-confirmed period budget: the dismissible
check appears only when an entry exceeds that entire budget. An unconfigured store has no
currency-neutral personal baseline, so it receives no invented purchasing-power threshold;
sign, precision, locale syntax, and the storage-safety boundary are still validated. Extra
fraction digits now receive their own field error, and locale grouping rules are cached per
locale instead of constructing a formatter for every grouped keystroke. Accounting-currency
mismatch, corrupt persisted data, and excessive future-plan generation retain typed UI
errors. Swipe deletion remains immediate as the standard list gesture, while the explicit
detail-screen delete keeps a confirmation dialog.

Alternatives considered: Allowing preview requests to persist and relying on request IDs,
passing raw notes through every summary and trusting future callers, inventing a fixed soft
amount threshold for every currency, blocking expense capture until every budget transition
is confirmed, shipping the test reset hook in Release, and flattening every actor error into
one save-failed message.

Consequences: Cancelling or scrubbing the expense date cannot change stored budgets. Budget
generation stays explicit and atomic, while future-date impact can still use an in-memory
copied projection. Engine and list consumers cannot accidentally receive raw notes through
their common summary type. Detail/edit and note search perform targeted actor reads. Pending
budget states remain visible without preventing factual expense capture, and Phase 7 has a
compile-time-narrower privacy input surface.

Files affected: `DataActor`, expense projections and Phase 3 views, app environment,
localized copy, Phase 3/data/date tests, privacy acceptance criteria, and project memory.

---

## 2026-08-03 — Treat cooling-off as an atomic local state machine

Context: Phase 4 needed to represent repeated cooling-off periods, expiry, purchase/skip
decisions, and optional expense conversion without allowing `WishItem` and
`CoolingOffPlan` to disagree. A 24-hour duration crossing daylight-saving time also must
mean 24 elapsed hours, while raw wishlist notes must not widen later AI inputs. System
notifications belong to Phase 6 and cannot be implied by a Phase 4 countdown.

Decision: `DataActor` owns atomic APIs for starting, expiring, deciding, archiving, and
converting wishlist items. An item may have at most one scheduled/active plan. Starting
from ready-to-review records the prior outcome as `extended` and creates a new plan in the
same transaction. Expiry completes the plan at its fixed `reviewAt` and moves the item to
ready-to-review without inventing an outcome; a later decision does not rewrite that
completion time. Purchase and skip complete any current plan with a neutral outcome.
Archiving cancels an active plan. Converting to an expense atomically creates one planned
`wishlistConversion` expense, moves the item to purchased, and stores only the existing
weak expense identifier. Cooling durations and remaining values are calculated as elapsed
calendar hours, never as fixed seconds. Phase 4 starts only a local countdown and states
plainly that no notification has been scheduled. Raw wishlist notes exist only in the
targeted `WishItemDetail` projection, which is forbidden at future redactor/generator
entry points.

Alternatives considered: Letting views coordinate separate item/plan writes, allowing
multiple active plans, deriving state without persistence refresh, treating a 24-hour plan
as the next local wall-clock day, marking expiry as `noResponse`, celebrating skipped
items, creating the expense and weak link in separate saves, and exposing notes through
the list summary.

Consequences: Dashboard and wishlist lifecycle loads may persist only factual expiry
transitions; ordinary countdown rendering remains read-only. Phase 6 can schedule and
cancel notification identifiers around the same actor-owned plan lifecycle without
changing its semantics. Phase 5 consumes neutral outcome counts and deterministic budget
impact rather than prices of skipped items. Future system integrations must call these
atomic APIs instead of recreating the state machine.

Files affected: wishlist/cooling projections, `DataActor`, Phase 4 views and countdown
service, localization/copy/privacy contracts, and Phase 4 tests.

---

## 2026-08-03 — Separate cooling completion from outcome recording

Context: A Phase 4 review found that expiry correctly stored `completedAt = reviewAt`, but
a later purchase/skip/extend decision had no separate timestamp. Reusing `completedAt` for
the later decision would erase how long the completed cooling period actually lasted;
leaving the decision time unstored would discard a potentially useful deterministic Phase
5 signal while Schema V1 can still accept the field without a migration. The review also
found that wishlist action failures were flattened, countdown preview time could drift, and
countdown copy ignored an injected SwiftUI locale.

Decision: `CoolingOffPlan.completedAt` remains the actual time the period completed or was
cancelled. Optional `outcomeRecordedAt` stores when a non-nil outcome was recorded, and the
write boundary requires outcome and timestamp to be present or absent together. Expiry
stores neither an outcome nor an outcome timestamp; a later decision preserves the earlier
completion time. Phase 5 may use the timestamp only for deterministic interval attribution
or delay calculations. It must not enter generative context. Phase 4 action surfaces retain
recoverable state-changed, corrupt-data, and persistence meanings. A cooling-off sheet fixes
one start instant for both preview and save, and countdown rendering formats through the
active environment locale.

Expense and wishlist projections remain intentionally asymmetric. `ExpenseSummary` carries
emotion and purchase-reason enums because Phase 5 aggregates those fields across expenses;
`WishItemSummary` omits them because list and budget-impact consumers do not need them, and
one explicitly requested `WishItemDetail` supplies them locally. Neither targeted detail
type is a permitted redactor or generator input.

Alternatives considered: Overwriting `completedAt` when the user decides, omitting the
decision signal from V1, calling the field `decidedAt` despite the neutral `noResponse`
outcome, flattening all action errors into one Boolean, taking a new `Date()` on every
render/save, and resolving countdown strings directly from the process bundle language.

Consequences: Phase 5 can distinguish cooling duration from later outcome timing without a
Schema V2 migration or invented inference. Persisted outcome state cannot represent only
one half of the outcome/time pair. Previewed and stored review times match, locale overrides
remain coherent, and future privacy work has a documented narrow projection boundary.

Files affected: Schema V1 cooling-off model and projections, `DataActor`, Phase 4 action and
countdown UI, localization, privacy/test contracts, and Phase 4 tests.

---

## 2026-08-03 — Keep Phase 5 detection deterministic and presentation separately throttled

Context: Phase 5 needed to find useful spending patterns, show timely purchase check-ins,
and retain dismissible insights without letting a disabled reminder setting erase factual
analysis. The same candidate can match several rules, while repeated sheets would undermine
the product's calm tone. Notifications and real Foundation Models integration belong to
later phases, but template output and future-enhancement failure still need a stable contract.

Decision: `SpendingPatternDetector` is a pure Sendable service over allow-listed value
projections, injected dates/calendars, `Int64` money, `Decimal` ratios, and basis-point
thresholds. It implements the eight approved rule families and never receives raw notes or
detail projections. Late-hour amount comparison requires a real positive free-budget
baseline; a zero or overcommitted baseline is undefined rather than treated as 100 percent.
Image-related increase requires enough complete historical cycles and a positive aggregate
baseline. Cooling-off success is attributed by `outcomeRecordedAt`, never `completedAt`.

Detection always runs even when check-ins are disabled. Typed insight payloads are encoded
deterministically and upserted by cycle/category dedupe key; updating a match never clears a
user's dismissal. Candidate insights are persisted only after the expense is actually saved,
while the Insights screen may recompute and upsert patterns from already persisted facts.
`ReminderEvent` records only a card, inline message, sheet, or later notification that was
actually presented or delivered. The throttle applies user settings, a 24-hour scoped
cooldown with the category first-crossing exception, recent dismiss/ignore adaptation, daily
interrupt caps, and quiet-hour deferral in that order. One purchase submission can present
at most one sheet, selected from the highest-severity match; continuing the purchase remains
the primary action and can never be removed.

`AdviceTemplateGenerator` is the mandatory local generator. It produces localized soft,
direct, and minimal variants under the approved length/action rules. The optional wording
enhancer is only an injected test/future seam in Phase 5: no SDK model is called. Empty,
oversized, or exclamation-bearing enhanced text falls back to the local template. Phase 6
owns notification authorization and scheduling, and Phase 7 owns any real on-device model
gate plus its stronger safety validator.

Alternatives considered: Combining detection and presentation into one setting-dependent
service, persisting candidate patterns before the user records an expense, logging every
rule match as a reminder, showing one sheet per match, interpreting zero free budget as a
100-percent ratio, using cooling completion time as outcome time, and calling a language
model before the template path was complete.

Consequences: Insights remain available when interruptions are off, frequency history
reflects real user-visible events, and deterministic tests can reproduce every threshold and
throttle decision. Dismissed insights stay dismissed for their dedupe period. Phase 6 can
consume deferred notification decisions without changing rule semantics, while Phase 7 can
enhance wording only behind the existing template and validation fallback.

Files affected: Phase 5 detector/throttle/reminder services, insight and reminder
projections/persistence, expense and Insights UI, settings, localization, tests, and agent
memory.

---

## 2026-08-03 — Keep expense persistence authoritative over advisory history

Context: PR #7 review found that a failed `ReminderEvent` insert, or a failed response
update after Continue Purchase, prevented the user's expense from being saved. The same
review identified fail-open calendar handling, scattered intervention constants, a shared
large-purchase/image-analysis floor, and silent historical-cycle omission on overflow.

Decision: Expense persistence is authoritative; reminder history is best effort. If a
sheet event cannot be recorded, the form skips that sheet and continues through the normal
expense save path. If a response update fails, Continue Purchase still attempts the expense
save, whose result alone controls the user-visible outcome. `ReminderEventWriter` is an
injected boundary so both failures remain executable tests rather than theoretical catches.

Rule thresholds stay deterministic but are named at their owning layer. Late-night window
and count, safe-proceed buffer basis points, and a separate image-related minimum amount
belong to validated `RuleConfiguration`. Scoped cooldown hours, negative-response count,
and response-window days belong to `ReminderThrottlePolicy`; they are specification
constants, not user preferences. An invalid behavioral request has its own diagnostic
reason. If the calendar cannot produce a daily interval, an interrupting channel is
downgraded instead of treating the daily count as zero. A cycle aggregate overflow rejects
the aggregate build instead of silently substituting older cycles into the image baseline.

Alternatives considered: Treating reminder persistence as part of an atomic expense write,
showing an untracked sheet after event failure, reporting invalid requests as user-disabled,
defaulting failed decimal parsing to zero, sharing one amount floor between unrelated rules,
and dropping only the overflowing cycle.

Consequences: A coaching subsystem failure cannot lose user-entered financial data, while
frequency decisions remain conservative when calendar evidence is unavailable. Product
threshold changes are reviewable and validated in one place per domain. Historical image
analysis prefers no result over a biased result.

Files affected: `AddExpenseView`, rule configuration, detector/aggregate builder, reminder
throttle, Phase 5 tests, and project memory.

---

## 2026-08-04 — Make notification consent explicit, exports ephemeral, and deletion staged

Context: Phase 6 connects three privacy-sensitive boundaries: lock-screen notification
content, an explicit user export that may include raw notes, and irreversible deletion
across UserNotifications, Core Spotlight, SwiftData, and app preferences. A cooling-off
period must remain useful when notification permission is denied, quiet-hour changes must
replan existing requests, and a cross-system deletion cannot honestly be represented as one
atomic database transaction. Phase 8 has not yet implemented Spotlight indexing or the
centralized Siri capability gate required for iOS 26 notification entity identifiers.

Decision: Background reconciliation only reads authorization and never prompts. Permission
is requested solely when the user selects an at-expiry notification while starting a
cooling-off period or enables the notification setting. Each plan uses the stable request
identifier `mindbudget.cooling-off.<plan UUID>` stored on `CoolingOffPlan`; reconciliation
replaces requests when quiet hours change, removes stale identifiers after outcomes or wish
deletion, and records an actually delivered booked notification as non-cap-counting history.
Notification payloads structurally receive an item name, plan/wish identifiers, duration,
and trigger date only—never price or notes. `appEntityIdentifier` remains Phase 8 work so it
can use the required centralized Siri scope/availability/runtime/user-setting gate.

V1 CSV export is explicitly the expense ledger, not a claim to serialize every internal
model. It uses stable machine-readable headers, UTC ISO-8601 timestamps, exact canonical
major units derived from integer minor units, the raw minor units and currency code, and
UTF-8 with BOM. An explicit export may include the user's merchant names and raw expense
notes; formula-like user text receives an apostrophe prefix before RFC 4180 escaping. The
file is provided from in-memory `Transferable` data through `ShareLink`, so MindBudget does
not retain a second CSV copy in its container.

Delete All requires a confirmation dialog followed by a localized confirmation word. It
runs and displays these stages in order: cancel all app notifications, await deletion of
all app-owned Core Spotlight items, delete all nine SwiftData entity types, reset app
preferences except system language, and return to onboarding. The sequence stops at the
first failure and names that stage; only full completion resets onboarding state. The
delete-only Core Spotlight boundary exists in Phase 6 because deletion promises require it,
but it does not authorize or implement indexing ahead of Phase 8.

Alternatives considered: Prompting on launch, treating the app toggle as system consent,
putting amounts or notes on the lock screen, generating random notification identifiers,
leaving cancelled wish notifications for eventual OS cleanup, persisting temporary export
files, describing an expense-only CSV as a full database backup, deleting SwiftData before
index cleanup, continuing after an index failure, and adding the iOS 26 entity identifier
before the Siri gate exists.

Consequences: A denied notification never blocks or rolls back the local cooling-off state.
Disabling notifications or completing/deleting a wish converges pending and stored request
state, including after a restart. Exported raw text leaves the app only through an explicit
share action and is disclosed before export. A failed deletion can leave an earlier cleanup
stage completed, but it can never erase later data or claim success; retrying the idempotent
sequence is safe. Phase 8 must retain the notification identifier prefix and deletion
boundary when it adds searchable items and Siri notification entities.

Files affected: notification/CSV/privacy services, `DataActor`, app session and settings/
wishlist UI, localization, privacy manifest review, Phase 6 tests, and project memory.

---

## 2026-08-04 — Verify destructive postconditions and isolate corrupt notification rows

Context: Phase 6 originally treated a non-throwing SwiftData delete as proof that every
local model was gone, while one malformed cooling-off relationship aborted reconciliation
for every otherwise valid notification. Neither behavior matched the promise that partial
deletion is never reported as complete or the established preference for detecting corrupt
data without disabling unrelated functionality.

Decision: Delete All re-queries all nine Schema V1 model counts after the delete call and
resets preferences only when all are zero. The verification boundary is injectable so a
false postcondition remains testable. Notification candidate projection returns valid
candidates and invalid plan identifiers separately; valid requests continue, invalid stored
and pending identifiers are cleared, and Settings displays a localized integrity warning.
The warning is last-known integrity state: a later operation failure can coexist with it and
does not clear it; only a successful reconciliation recomputes it. Invalid rows remain stored
because the app must not silently delete user data. Phase 9 will add an explicit, localized,
confirmed repair action that reports the affected count. Fetch-level failures still fail the
whole operation. Explicit export disclosure, item-name-only notification copy without
amount/notes, and quiet-hour scheduling were reverified and remain unchanged.

Alternatives considered: Trusting absence of an exception, continuing after a failed
postcondition, aborting all notification work for one corrupt row, silently skipping the row
without user-visible evidence, auto-deleting it, or clearing known integrity state when an
unrelated scheduling operation fails.

Consequences: Completion now means the database was observed empty, not merely that a delete
call returned. One corrupt record cannot suppress all valid reminders, and the partial state
is visible rather than silently normalized. Reconciliation still fails closed when the
underlying fetch itself cannot be trusted. Until Phase 9 provides repair, the only existing
whole-store removal path is Delete All; the warning therefore remains intentionally durable.

Files affected: privacy deletion verification, notification projections/reconciliation,
settings copy, Phase 6 tests, and durable project memory.
