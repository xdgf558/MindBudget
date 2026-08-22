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
because the app must not silently delete user data. Phase 10 will add an explicit, localized,
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
underlying fetch itself cannot be trusted. Until Phase 10 provides repair, the only existing
whole-store removal path is Delete All; the warning therefore remains intentionally durable.

Files affected: privacy deletion verification, notification projections/reconciliation,
settings copy, Phase 6 tests, and durable project memory.

---

## 2026-08-04 — Keep Ask deterministic and make Foundation Models a replaceable wording layer

Context: Phase 7 introduces a free-text Ask surface while the iOS 17 product must remain
complete without Apple Intelligence. The raw question can contain arbitrary private text or
prompt injection, and Foundation Models is available only on supported iOS 26 devices,
languages, regions, and user configurations. Reminder, Ask, and cycle-summary output must not
let a model invent arithmetic, actions, diagnoses, financial advice, or a prohibition on the
user's purchase. The Phase 0 capability contract also requires scope, API availability,
runtime readiness, and explicit default-off consent to be combined at one boundary rather
than reimplemented at each call site.

Decision: `IntentClassifier` handles the seven approved Ask intents locally in English and
Simplified Chinese. The raw question is never persisted, logged, copied into a redacted
context, or sent to a generator. Unknown and out-of-scope intents use fixed local responses
and never call a model; an affordability question without an explicit amount and category
asks for those facts instead of guessing. Every supported intent has a complete deterministic
template answer on iOS 17+.

`AIAdviceGenerating` is the only generation seam for reminders, cycle summaries, and Ask.
`AIEnhancementCapability` centrally combines the Foundation Models product-scope flag, iOS/API
availability, runtime eligibility/readiness, supported locale, and the user's independently
stored default-off setting. Call sites provide only the setting and injected runtime seam;
they never read the raw feature flag. The iOS 26 implementation uses conditional import,
availability guards, `LanguageModelSession`, the exact system instruction in
`AI_PROMPT_CONTRACT.md`, and `@Generable` outputs rather than free-form JSON.

Each task receives a distinct Codable allow-listed aggregate context. Generator APIs cannot
accept `ExpenseDetail`, `WishItemDetail`, transaction rows, merchant lists, raw notes, raw
cooling-off timestamps, or the raw Ask question. Deterministic code precomputes every amount,
ratio, count, conclusion, severity used by the product, and allowed action identifiers. Model
output is a wording proposal only. Ask does not expose a generic fact dictionary: its aggregate
input is an exhaustive per-intent enum containing typed `Money`, `Int`, `Bool`, and
`ExpenseCategory` values, plus typed insight/action enums. The redactor alone formats those
values into a private Codable representation. Deterministic fallback prose is derived from the
typed payload after redaction and never becomes a model fact. A 2.5-second timeout and
`AdviceSafetyValidator` enforce
nonempty length limits, two-to-four allow-listed actions, Continue Purchase for purchase
advice, banned-language categories, and a normalized numeric allow-list derived only from
the semantic context values. Any unavailable, timed-out, failed, or invalid result returns
the already-built template with explicit source metadata. Generated wording is never stored.
DEBUG builds also keep reason-only in-memory fallback counters for Settings diagnostics;
they contain no prompt, fact, generated text, timestamp, or server reporting.

Alternatives considered: Sending the raw question to the on-device model, persisting a chat
history, making the model classify intent or calculate budget facts, accepting free-form JSON,
scanning one generic context assembled from projections, retaining a `[String: String]` Ask
fact map with either comments or key-name validation, treating a product flag as user
consent, failing closed with no answer when Apple Intelligence is unavailable, and trusting
generated numbers or actions without post-validation.

Consequences: Ask has the same correct behavior on every supported iPhone, privacy-sensitive
fields and future Siri-supplied strings cannot be inserted as new Ask facts without adding and
reviewing an explicit enum case, and model availability
changes only phrasing. Tests can inject generators and runtime states without invoking the
real model. Settings can name the current availability reason while honestly promising that
templates remain fully functional. A supported physical Apple-Intelligence device still
requires release smoke testing because automated suites deliberately use mocks.

Files affected: Phase 7 generation/classification/redaction/validation services, Reminder
Engine, Ask/Dashboard/Insights/Settings UI, resources, tests, and durable project memory.

---

## 2026-08-04 — Ship custom iOS 17 system integrations behind independent fail-closed gates

Context: Phase 8A must expose MindBudget actions and app-owned data to Siri, Shortcuts, and
Spotlight without weakening the iOS 17 baseline or leaking exact amounts, raw notes, or
merchant names. The release-time contract also requires checking the current SDK for a
suitable official App Schema domain before defining custom integrations. In Xcode 26.6
(17F109) with the iOS 26.5 SDK, the public `AppIntents.swiftinterface` exposes Assistant
Schema families for Books, Browser, Camera, Files, Journal, Mail, Photos, Presentation,
Reader, Spreadsheet, System, Visual Intelligence, Whiteboard, and Word Processor. It exposes
no personal-finance, budget, expense, or wishlist schema whose semantics fit MindBudget.

Decision: Phase 8A ships all nine approved actions as custom `AppIntent` types and all seven
approved projections as custom `AppEntity` types, plus six suggested shortcuts. It does not
mislabel financial data as another schema domain. `SystemIntegrationCapability` is the only
place that reads the Siri and Spotlight product-scope flags and combines them with conditional
framework/OS availability, runtime readiness, and each independent default-off setting.
Queries return no suggestions and services perform no read or write when the Siri conjunction
is false.

Siri text is treated as untrusted, stripped of control characters, trimmed, and capped at 40
characters. App Intent `Double` parameters exist only in `IntentMoneyTransport.swift`; the
adapter rejects nonfinite, nonpositive, unsupported, oversized, or precision-losing values and
returns exact `Money` minor units before domain logic. Candidate product names used by impact
checks are ephemeral. Expense writes from Siri/Shortcuts use an actor-isolated five-second
deduplication transaction keyed by source, exact money, category, bucket, and normalized
merchant so system retries return the existing expense instead of inserting another row.

Core Spotlight owns one replaceable `mindbudget.local` domain. Its builder accepts only
summary projections and indexes expense category plus a budget-relative amount band, current
budget status, wishlist/cooling state, typed insights, and emotion labels. It cannot access raw
notes and does not emit exact amounts. Merchant display names require the centralized
Spotlight conjunction, global `indexMerchantNames`, and at least one expense with the same
persisted normalized key and `allowMerchantIndexing == true`; local merchant aggregation still
includes every expense. Turning Spotlight off clears the domain once, and index failures return
a UI-visible result without blocking or rolling back local data. Search identifiers and open
intents route only to app-owned destinations.

Alternatives considered: Treating a product flag as consent, exposing entities while the Siri
setting is off, adopting an unrelated Journal or Files schema, letting `Double` enter domain
services, trusting Siri strings, storing candidate names, relying on UI-only duplicate checks,
putting exact amounts or notes in Spotlight, using the local Merchant table as implicit consent,
or making index writes part of the user's SwiftData transaction.

Consequences: The complete iOS 17 app remains local and deterministic, user settings can
independently disable Siri or Spotlight, system retries do not duplicate expenses, and the
search index is useful without becoming a second raw ledger. Before each release, the SDK
schema catalog must be checked again. `IndexedEntity`, onscreen awareness, and notification
`appEntityIdentifier` remain Phase 8B because they require iOS 26 APIs and separate review.

Files affected: system-integration gates/settings, App Intents, App Entities, shortcuts,
Spotlight indexing/deep links, `DataActor` deduplication and merchant eligibility, localization,
Phase 8A tests, privacy/review notes, and durable project memory.

---

## 2026-08-04 — Keep App Intent errors truthful and active Siri impact answers exact

Context: Phase 8A review found that the App Intent amount adapter classified an unsupported
currency as an invalid amount, while three money-taking intents described every unexpected
failure as an invalid amount. The same review noted that an authenticated budget-impact
dialog returns an exact flexible-budget value even though passive system surfaces deliberately
exclude exact amounts. Authentication controls access but does not guarantee that spoken
output occurs in a private environment.

Decision: Keep invalid/nonpositive amounts, amounts outside the storage-safety boundary,
unsupported minor-unit precision, unsupported currencies, accounting-currency mismatch, and
unexpected execution failures as distinct localized outcomes. The transport adapter validates
currency support, exact decimal precision, and the maximum amount as separate checks; every
money-taking intent maps typed transport failures explicitly, and an unclassified failure uses
neutral temporary-failure copy instead of blaming the amount. Preserve the exact value in
`CheckBudgetImpactIntent` because the authenticated user explicitly requested that deterministic
calculation. Treat it as a narrow active-query exception: notifications, App Entity displays,
and Spotlight content remain exact-amount-free. Settings discloses that Siri may speak the exact
result in a separate paragraph from Spotlight and merchant privacy so both remain readable at
large accessibility sizes. The merchant-name conjunction is verified through the production
`reconcile()` path: centralized capability, global consent, and one eligible expense are all
required before a merchant document can be emitted.

Alternatives considered: Reporting every failure as an invalid amount, merging unsupported
currency with accounting-currency mismatch, removing the exact result from the impact action,
or assuming authentication also proves acoustic privacy.

Consequences: Siri directs the user toward the part of the request that can actually be
corrected, while persistence and unknown failures no longer make a false claim about their
amount. Oversized exact values are no longer misreported as a decimal-precision problem. The
active impact action remains useful, but the spoken-output disclosure is explicit and its
exception cannot be reused by passive system surfaces without a new reviewed decision. The
most privacy-sensitive Spotlight rule has executable end-to-end evidence instead of relying
only on builder-level tests and documentation.

Files affected: App Intent money transport/actions, localized integration and error copy,
Phase 8A tests, Siri/privacy plans, changelog, project memory, and this file.

---

## 2026-08-05 — Gate iOS 26 context at the entity boundary and stub unavailable public APIs

Context: The product owner names the former Phase 8B scope Phase 9: `IndexedEntity`, local
retrieval for Foundation Models, and onscreen awareness. The checked-in deployment target must
remain iOS 17.0 and every L2 capability must degrade without changing L0/L1 behavior. The
installed release toolchain is Xcode 26.6 (17F109) with the iOS 26.5 SDK. Its public interfaces
show `IndexedEntity`, `CSSearchableItemAttributeSet.associateAppEntity`, and Core Spotlight
entity indexing from iOS 18.0; `NSUserActivity.appEntityIdentifier` from iOS 18.2; and no public
SwiftUI multi-object list-selection annotation or UserNotifications app-entity property. The
external specification's list modifier and notification property therefore cannot be compiled
or truthfully claimed with this SDK.

Decision: Keep Phase 9 a product-level iOS 26 enhancement even where an underlying API was
introduced earlier. `SystemIntegrationCapability` centrally combines the onscreen product
flag, conditional App Intents import/OS check, runtime seam, and the existing default-off Siri
setting. Detail screens and the configured Dashboard publish an amount-free
`NSUserActivity.appEntityIdentifier` only when that conjunction is true. Activities are
ineligible for independent search, prediction, and Handoff. Wishlist and Insights list pages
use an explicit-selection adapter and pass no selection in the current iPhone UI, which fails
closed until a public multi-object API is present rather than registering competing per-row
activities.

All seven existing, privacy-redacted App Entities conform to `IndexedEntity`. Phase 9 does not
create a second entity index or change deletion semantics: the existing single app-owned
Spotlight domain still owns replacement and clearing. Each document carries a typed amount-free
entity projection, and iOS 26 associates it with the already-reviewed attribute set. Exact
amounts and notes remain structurally unavailable; merchant associations are created only
after the existing capability + global opt-in + eligible-expense triple gate.

Ask uses `LocalSearchService` after deterministic intent classification to select only the
authoritative SwiftData projections relevant to that intent. Spotlight remains a supplemental
navigation index and is never accepted as a source for amounts, counts, dates, or other facts
sent to Foundation Models. Notification scheduling carries a typed wishlist reference to the
SDK adapter only when the same onscreen conjunction is true. Because the installed SDK has no
public notification annotation property, the adapter is a tested no-op stub; stable `userInfo`
routing remains the iOS 17+ behavior. Recheck and fill that one adapter when a release SDK
actually exposes the API. No private or dynamically looked-up API is permitted.

The durable phase numbering follows the owner's current sequence: this iOS 26 enhancement is
Phase 9, and the former polish/TestFlight Phase 9 becomes Phase 10. The explicit corrupt-row
repair action moves with that polish scope and is not implemented ahead in this phase.

Alternatives considered: Enabling these APIs on iOS 18 because their framework availability
allows it, using direct `indexAppEntities` calls and creating separately managed index data,
registering one user activity per visible list row, inventing notification selectors through
Objective-C runtime lookup, feeding Spotlight descriptions back into model facts, or silently
claiming the external draft APIs exist.

Consequences: iOS 17/18 behavior and index deletion remain unchanged, while supported iOS 26
devices can relate Spotlight documents and three single-subject screens to reviewed App
Entities. Unsupported list and notification integrations are visible, testable debt rather
than hidden private-API risk. A signed physical iOS 26 device is still required to verify Siri's
"this" resolution end to end, and every newer Xcode SDK must be re-inspected before replacing
either stub.

Files affected: centralized system-integration capability, onscreen activity adapter, App
Entities, Spotlight and notification adapters, Ask local retrieval, five priority views,
Phase 9 tests, phase numbering, Siri/privacy/test memory, and this file.

---

## 2026-08-05 — Stop onscreen advertisement explicitly and transfer identity only

Context: Review of the first Phase 9 implementation found that disabling the Siri setting
removed the SwiftUI `userActivity` modifier conditionally but did not express revocation through
the modifier's public lifecycle API. Apple's current SwiftUI contract says that
`userActivity(_:element:_:)` advertises nothing when `element` is nil. Current App Intents
guidance also calls for a `Transferable` App Entity when `NSUserActivity.appEntityIdentifier`
provides onscreen context without a suitable Assistant Schema. The finance schema review found
no applicable schema. The same review asked whether the generated Info.plist needs
`NSUserActivityTypes` and noted that emotion vocabulary remains indexed.

Decision: On iOS 26, keep the SwiftUI user-activity modifier installed for the lifetime of a
supported single-subject view and pass the fully gated entity reference as its optional
`element`. A disabled product/runtime/user gate or missing subject passes nil, which the public
SwiftUI contract defines as no advertised activity. Continue to make every advertised activity
ineligible for search, prediction, and Handoff.

Only `ExpenseEntity`, `BudgetSnapshotEntity`, and `WishlistItemEntity`, the three entity types
actually published by current single-subject screens, conform to `Transferable`. Their JSON
representation is a closed `OnscreenTransferReference` containing only a version, entity-kind
key, and stable identifier. It deliberately excludes the wishlist name, dates, category,
amount band, exact amount, note, and all other financial or user-authored fields. MindBudget's
entity query remains the only way to resolve that identity into authoritative local data.

Do not add `NSUserActivityTypes` speculatively. The current activities cannot be received for
continuation because Handoff is explicitly disabled, and the public App Entity association
documentation does not require that Info.plist key for same-device Siri context. Verify this on
a signed iOS 26 iPhone; add only the exact owned activity types if that test proves the key is
required. Continue associating the static emotion-tag vocabulary: those documents are the
app's fixed navigation lexicon, contain no selected tag, count, transaction, or other user
state, and expose no more than the product's visible feature vocabulary.

Alternatives considered: Relying on removal of a conditional view modifier, manually retaining
and invalidating a SwiftUI-owned `NSUserActivity`, exporting the complete App Entity as JSON,
using a user-visible plain-text transfer, declaring every activity type preemptively, removing
emotion navigation terms, or adopting a semantically incorrect schema.

Consequences: Gate closure now has a documented framework-level stop condition, and the system
can satisfy the public `Transferable` requirement without receiving a second copy of financial
or user-authored context. Same-device onscreen resolution still needs physical-device proof;
the simulator cannot establish Siri consumption or whether a future SDK changes Info.plist
requirements.

Files affected: App Entities, onscreen activity adapter, Phase 9 tests, privacy/Siri/test plans,
project memory, changelog, and this file.

---

## 2026-08-06 — Insert a design interlude before release polish

Context: The owner supplied a high-fidelity UI/UX handoff after Phase 9 and explicitly asked
for the product experience to be rebuilt before Phase 10. The handoff combines two different
kinds of work: a redesign of every existing V1 surface and a new non-consumable Pro business
model with quotas, locked states, StoreKit entitlement, and editable reminder rules. Treating
the whole package as a visual-only patch would hide new product behavior inside presentation
work, while starting Phase 10 first would polish an interface that is about to be replaced.

Decision: Add one explicit design interlude between Phase 9 and Phase 10. Its first slice
rebuilds the existing feature set in SwiftUI using the supplied design tokens and information
architecture while retaining the current `DataActor`, deterministic engines, projection
privacy boundaries, localized strings, and iOS 17 baseline. The main shell becomes four real
content tabs; expense entry is an independent accessible action and Settings is presented from
Today. Existing deep links continue to resolve to app-owned destinations.

The owner subsequently limited this interlude to the existing free product. The code may reserve
small presentation and routing seams for the handoff's later Pro screens, but StoreKit,
entitlement, quotas, locked states, paywall, and custom-rule purchase UI remain unimplemented
and invisible. No prototype switch, hard-coded price, fake entitlement, or disabled feature may
suggest that commerce already works. When commercialization is separately started, StoreKit
entitlement must be verified before any paid lock is enforced. Budget safety, purchase reminders,
cooling-off, CSV export, deletion, and privacy controls remain permanently available. No server,
account, cloud sync, advertising, or external analytics is introduced.

Moving Settings from a first-level tab to the Today header is an intentional information-
architecture decision, not a reduction in capability. Today is the app's daily hub, the gear is
a conventional 44-point labeled control, and Settings still groups export, deletion, AI/Siri/
Spotlight consent, notification authorization, quiet hours, reminder tone, and interruption limits
without hiding or gating any row. The tradeoff is lower first-run discoverability than a dedicated
tab. Automated UI coverage must continue from Today through the gear to both Export and Privacy,
and Phase 10 must verify the path with VoiceOver and AX5. If signed-device usability shows that
people cannot find these controls, add a visible Settings affordance in Today rather than restoring
a fake content tab or moving privacy controls behind commerce.

The handoff specifies only the light appearance outside its intentionally dark reminder and
paywall surfaces. Shared semantic color assets therefore receive conservative accessible dark
variants and remain a release-validation item rather than inventing a second unreviewed layout.
The prototype is a design reference, not a replacement architecture or permission to weaken a
repository invariant.

Alternatives considered: Starting Phase 10 against the old interface, implementing the HTML as
a WebView, replacing the existing data/services layer, mixing unverified Pro locks into the
first visual commit, or renumbering the already agreed Phase 10 release scope.

Consequences: UI changes remain reviewable as one pre-release stage, Phase 10 retains its
meaning, and no unfinished commerce appears in the shipped interface. The custom navigation
declares the VoiceOver order Today, Log, Add Expense, Insights, Wishlist rather than relying on
`ZStack` geometry; tab positions and totals come from the exhaustive `AppTab.allCases` order.
UI tests must cover the four-tab accessibility semantics, selected-state announcements, adaptive
tab height, custom amount keypad, and the renamed Today metric while unit tests continue to
prove the unchanged domain and privacy contracts. The later commercialization phase can reuse
the reserved seams but must make its own product, entitlement, price, and refund decisions.

Files affected: app routing, shared design components/assets, all existing V1 SwiftUI features,
localization, UI and feature tests, and durable project memory. StoreKit and Pro files are not
part of this interlude.

---

## 2026-08-07 — Make Phase 10 release evidence explicit and keep signing local

Context: Phase 10 must turn the V1 implementation into auditable release evidence without
claiming that simulator automation proves production signing, physical-device accessibility,
system integrations, data protection, or App Store Connect state. Settings also identified
unreadable cooling-off rows but offered no recovery short of Delete All. During this phase the
owner moved release operations to a different China-region Apple Developer account, so any
committed Team ID could silently select the previous legal entity or break forks and CI.

Decision: Add a localized repair action that shows the exact cached invalid-row count, requires
explicit destructive confirmation, and passes only those identifiers to `DataActor`. The actor
revalidates each row inside the commit and deletes it only if it remains invalid; readable rows,
unidentified rows, and all other user data are preserved. Repair success clears the corresponding
stale integrity warning even if the separate best-effort notification reconciliation fails.

The automated release gate now includes an unsigned generic-simulator Release build, the complete
unit/UI suite, bilingual catalog and printf compatibility, AX5 and pseudo-long navigation smoke,
an always-on deterministic Dashboard projection contract over 10,000 varied current-cycle
expenses, static asset/privacy/version checks, and at least 85% line coverage for each selected
deterministic money, budget, rule, privacy, formatting, and answer-safety source file. Higher
coverage targets remain useful stretch goals rather than undocumented blockers. A separate 500 ms
wall-clock Dashboard benchmark is a local release-machine signal and runs in local validation by
default; hosted GitHub Actions explicitly skips only that timing test because shared-runner load
cannot distinguish a product regression from VM contention. Instruments on the signed release
iPhone remains the authoritative performance check. The source-only Phase 10 plan initially named
version 1.0.0/build 1 as the TestFlight identity; the later prerelease-version decision below
supersedes that marketing-version choice. Every replacement upload still increments the build number.

Do not commit `DEVELOPMENT_TEAM`. Immediately before Archive, select and verify the owner's latest
China-region team locally, confirm that the final Bundle ID and App Store Connect app belong to
that team, inspect the distribution identity and provisioning profile, and confirm agreements.
No archive or upload is represented as complete by this source-only phase. The release checklist's
signed-device VoiceOver/AX5/dark-mode/iOS 17/iOS 26, Instruments, privacy, system-integration,
screenshot, archive, and upload items remain hard manual gates; Phase 10 stays In Progress until
they are evidenced. Account, team, agreement, certificate, profile, and App Store Connect checks
are therefore reset for every Archive/upload. Dated development observations may be retained as
historical preflight evidence, but never as durable checked release gates.

Alternatives considered: Silently deleting corrupt rows during reconciliation, deleting every
corrupt row without a user-confirmed identifier set, treating one aggregate coverage percentage
as sufficient, making a 500 ms hosted-runner clock a blocking correctness test, recording simulator
checks as proof of device behavior, hardcoding the new Team ID, or attempting an upload before the
owner confirms the final account and App Store Connect record.

Consequences: The repository can reproduce its automated release claims while distinguishing them
from account- and device-dependent evidence. A repair cannot broaden itself beyond the rows the
user was shown, notification outages no longer leave a false integrity warning, and neither the
previous nor current developer account leaks into shared build configuration. TestFlight remains
blocked on the explicit manual checklist rather than on an ambiguous “tests pass” statement. CI
still proves the 10,000-row workload and every deterministic assertion without converting hosted
CPU noise into a misleading performance failure.

Files affected: cooling-off repair actor/session/Settings flow, localization and tests, release
scripts and coverage gates, app icon/version metadata, App Store/release/privacy documentation,
project memory, changelog, and this file.

---

## 2026-08-07 — Ship the approved budget-track icon as standard, dark, and tinted assets

Context: The Phase 10 placeholder icon proved the release asset pipeline but was not the owner's
final brand mark. The approved August 2026 revision enlarges the same pace metaphor for small-size
recognition: a 720×116 track beginning at x 152, a 396px completed segment, and a 46×344 marker
beginning at x 585. It provides dedicated standard, dark, and monochrome variants and explicitly
delegates corner masking to iOS.

Decision: Replace the placeholder with three opaque universal App Icon resources. The standard
appearance uses the supplied green gradient, dark green track, warm-white completed segment, and
amber marker. The dark appearance uses the supplied near-black, muted-track, mint-segment treatment.
The tinted appearance is intentionally opaque grayscale with luminance-separated track and mark so
iOS can apply the user's chosen Home Screen tint without losing the pace distinction. Keep one SVG
source per appearance under `Docs/Brand`, render all three at exactly 1024px, retain square corners
in source, and make the release script reject a missing, transparent, mis-sized, or unreferenced
variant. Document the exact SVG-to-PNG mapping and export commands, and checksum all six files as
one reviewed source/artifact set so editing either side without refreshing the declared contract
fails validation.

Alternatives considered: Shipping only the standard image, using the screenshot itself as a
cropped icon, pre-rounding the corners, or asking iOS to derive dark/tinted appearances from the
standard artwork.

Consequences: The mark preserves its intended contrast in all supported Home Screen appearance
modes without baking screenshot furniture or a duplicate corner mask into the binary. The asset
catalog and static release gate now treat all three files as one production icon contract. Final
appearance still requires the signed-device check because the system owns masking and tinting.
The checksum proves that the reviewed source/artifact pair did not drift; it does not replace the
visual comparison required after an intentional raster export.

Files affected: App Icon SVG/PNG sources, asset-catalog metadata, release validation, and release
memory/checklists.

---

## 2026-08-07 — Localize the release name instead of combining both brands

Context: Before the first TestFlight build, the owner selected the Chinese name `花有数`, the
English name `MindBudget`, and the Chinese descriptor `温和的预算与消费复盘工具`. A signed-device
check showed that combining both names in one Home Screen label was not the intended result.

Decision: Keep `MindBudget` as the generated Info.plist fallback, localize `CFBundleDisplayName`
through `InfoPlist.xcstrings` to `MindBudget` for English and `花有数` for Simplified Chinese, and
use those same names in their matching App Store localizations. Never combine both names in the
same app-name field. Keep `温和的预算与消费复盘工具` as the Simplified Chinese subtitle, keep the
icon text-free, and retain `MindBudget` in code, target, scheme, bundle suffix, store filename,
and internal type names.

Alternatives considered: Combining both names on every device, renaming the Xcode target and
Swift types, or putting either name inside the App Icon.

Consequences: The user sees one short, language-appropriate name without destabilizing identifiers,
persistence, or system integrations. The release gate and localization tests must verify both
InfoPlist translations, and both App Store names remain subject to availability in the current
China-region account.

Files affected: app display-name build settings and InfoPlist catalog, localization tests, App
Store draft, release validation/checklist, project memory, and changelog.

---

## 2026-08-07 — Keep one explicit commit action in budget setup

Context: The decimal keyboard toolbar added a floating `Done` action directly above the bottom
`Save Budget` button. It visually overlapped the primary action on a physical iPhone and made it
unclear whether finishing text entry also saved the budget.

Decision: Do not attach a keyboard completion toolbar to budget setup. Moving between amount
fields only edits the in-memory draft. `Save Budget` is the sole action that dismisses input focus,
validates the complete draft, persists it, and advances to Today.

Alternatives considered: Keeping both actions, making `Done` save immediately, or adding a second
floating keyboard control with different wording.

Consequences: The screen has one unambiguous persistence action and cannot imply that dismissing
the keyboard committed financial data. UI coverage must fill all amount fields without the former
toolbar and prove that the bottom action completes onboarding while the keyboard is active.

Files affected: budget setup, its end-to-end UI tests, the redesign handoff, changelog, and session
memory.

---

## 2026-08-07 — Give custom bottom navigation an intrinsic vertical size

Context: On a signed iPhone, Today entered its compact loading state while the transparent center
gap inside the custom navigation still accepted an unconstrained vertical proposal. That gap
expanded through most of the screen, leaving the add button near the top and centering the four
tabs inside a full-height surface. Existing UI tests checked presence and hit testing, so the
geometrically incorrect controls still passed.

Decision: Fix the center gap at its intended 54-point height, ask the complete navigation surface
to use its vertically ideal content size, and let real tab labels increase that ideal height for
accessibility text. Make Today's state container fill the remaining content area independently.
Assert that both a real tab and the add action remain inside the bottom region at standard and AX5
sizes.

Alternatives considered: Hardcoding the entire tab bar height, switching back to the system tab
bar, waiting for configured content before showing navigation, or relying on visual review alone.

Consequences: Loading and other compact destination states cannot turn a flexible decoration into
a full-screen layout participant. Dynamic Type remains content-driven, while automated coverage
now fails on gross vertical displacement rather than only missing controls.

Files affected: app routing/navigation layout, Today state layout, UI tests, redesign memory,
changelog, and session log.

---

## 2026-08-07 — Give empty-state actions their own compact primary style

Context: The shared full-width primary button asks for the maximum width offered by its parent.
Inside `ContentUnavailableView`, the compact action proposal on a signed iPhone instead compressed
the Today `Add Expense` and Wishlist `Add Item` labels into near-square mint controls. The action
remained tappable, but its visual hierarchy and localized label spacing no longer matched the rest
of the redesign.

Decision: Use a dedicated compact primary style for empty-state actions. Keep the label to one
line with controlled scaling, 22-point horizontal padding, a 140-point minimum width, a 50-point
minimum height, and the existing accent/pressed/disabled treatment. Give each release-critical
empty action its own accessibility identifier. Leave the full-width primary style unchanged for
forms and bottom commit actions.

Alternatives considered: Changing every primary button, hardcoding a separate width for each
localized label, shortening the approved copy, or relying only on a visual device check.

Consequences: Chinese and English empty-state actions retain horizontal breathing room without
changing unrelated form buttons. UI coverage now fails if either reviewed action becomes narrower
than 140 points or no longer remains wider than twice its height.

Files affected: shared presentation components, Today and Wishlist empty states, UI tests,
redesign/test memory, changelog, and session log.

---

## 2026-08-07 — Let the bottom-navigation surface replace its decorative top rule

Context: Signed-device review showed that the custom bottom navigation's one-point top hairline
continued through the raised center Add Expense control. The rule was intended to separate content
from navigation, but the navigation already has its own semantic surface color and the crossing
line made the central action look visually divided.

Decision: Remove only the decorative top overlay. Keep the navigation background, safe-area
coverage, intrinsic height, center-action geometry, hit testing, and accessibility order unchanged.

Alternatives considered: Masking the line only beneath the center button, adding a curved notch,
or retaining the line as a conventional tab-bar separator.

Consequences: The bottom navigation reads as one continuous surface and the primary add action is
no longer bisected. Content separation remains available through the existing surface contrast.

Files affected: app routing/navigation presentation, redesign memory, changelog, and session log.

---

## 2026-08-07 — Split Settings by durable responsibility

Context: The redesigned Settings screen placed budget, reminders, notifications, Apple
Intelligence, Siri, Spotlight, export, deletion, and diagnostics in one growing scroll view. The
signed iPhone review also exposed runtime localization keys in reminder-tone and AI-status values.

Decision: Make the Settings root a short navigation directory. Budget, reminders and notifications,
Apple Intelligence, integrations, export, privacy, and About each own a focused second-level page.
Keep Export and Privacy directly reachable from the root because their discoverability is part of
the release/privacy contract. Keep cooling-notification repair beside notification controls. Render
dynamic enum and status keys through `LocalizedCatalog` with the active SwiftUI locale. Local
fallback diagnostics remain guarded by `#if DEBUG` and therefore absent from Archive/TestFlight.

Alternatives considered: Retaining one long screen, creating a destination per individual toggle,
moving export/deletion under a generic advanced page, or interpolating localization keys directly
into `Text` and relying on implicit lookup.

Consequences: Settings can grow without making every user traverse unrelated controls, critical
privacy actions remain easy to find, and runtime values render in the selected language. Navigation
depth increases by one for ordinary settings, while Export and Privacy keep their prior depth.

Files affected: Settings and AI-status views, localization, UI tests, redesign/test/project memory,
changelog, and session log.

---

## 2026-08-07 — Treat generated language as an output-safety contract

Context: A signed Simplified Chinese build requested a remaining-budget answer from the on-device
model. Although the prompt asked for `localeIdentifier`'s language, the model returned an English
title and body. The existing validator accepted the proposal because length, actions, banned
phrases, and numbers were valid. The same screen interpolated action identifiers into a
`LocalizedStringKey`, so SwiftUI rendered the literal catalog keys instead of their Chinese labels.

Decision: Validate the writing system of every generated Ask answer, reminder, and cycle summary
for the two shipped interface languages. Simplified Chinese proposals must contain Han text;
English proposals must contain basic Latin text and no Han text. A mismatch is an invalid model
proposal and follows the existing complete-template fallback path. Resolve dynamic Ask action keys
explicitly with `LocalizedCatalog` and the active SwiftUI locale instead of relying on interpolated
localization-key inference.

Alternatives considered: Trusting the prompt alone, displaying the mismatched model output,
translating it with a second model pass, or using a probabilistic language-classification
framework. The first already failed on-device, the second produces mixed-language UI, the third
adds another nondeterministic generation step, and the fourth is unnecessary for the two closed
shipping languages.

Consequences: On-device wording remains optional; language drift now produces the same complete,
localized deterministic answer available on iOS 17 instead of leaking through to the UI. The
check is deliberately narrow to the shipped English and Simplified Chinese locales and is covered
by validator, composite-fallback, and rendered Chinese action-label tests.

Files affected: generated-output validation, Ask UI, localization/release notes, Phase 7 and UI
tests, TestFlight guidance, and durable project memory.

---

## 2026-08-07 — Reserve 1.0.0 for public launch

Context: The app is entering internal TestFlight rather than a public App Store release. Calling
that candidate 1.0.0 obscures its prerelease status and leaves no clear repository rule tying each
uploaded binary to its tester-facing change record.

Decision: Use marketing version 0.9.0 and build 1 for the first internal TestFlight candidate.
Increment `CURRENT_PROJECT_VERSION` for every replacement upload, even when the marketing version
remains 0.9.0. Reserve marketing version 1.0.0 for the first public App Store release. Keep an
Unreleased section in `Docs/CHANGELOG.md`; before every upload, move included changes into a dated
version/build section and copy a concise tester-facing summary into the TestFlight notes in
`Docs/APP_STORE_SUBMISSION.md`.

Alternatives considered: Uploading 1.0.0 before public release, using 0.1.0 despite the feature-
complete state, encoding beta labels in `CFBundleShortVersionString`, or recording changes only in
commit messages and App Store Connect.

Consequences: Installed and uploaded prerelease builds communicate their status clearly, App Store
launch retains a clean 1.0.0 identity, and every binary has durable source-controlled release notes.
The build number—not a mutable suffix—distinguishes replacement uploads accepted by App Store
Connect.

Files affected: Xcode version settings, release-readiness validation, changelog, submission notes,
release checklist, project/task/decision/session memory.

---

## 2026-08-07 — Make skins semantic, persistent, and entitlement-neutral

Context: The owner supplied three visual directions before the first internal TestFlight: deep
teal aurora glass, warm cream botanical, and midnight purple/cyan neon. Future additional skins
may become part of a paid tier, but StoreKit products, entitlements, restore, and purchase UX do
not yet exist. The Simplified Chinese UI also still contained localized references to the English
product name even though the release display name is `花有数`.

Decision: Model the three current choices as stable `AppSkin` raw values stored in `SettingsStore`.
Resolve each through one injected `MindBudgetTheme` containing semantic canvas, surface, ink,
accent, attention, and dark-surface roles. Keep layout, controls, cards, materials, and symbols
native SwiftUI, while each skin supplies one purpose-built portrait background derived from the
owner's visual direction. The supplied UI screenshots themselves are never cropped or shipped;
the standalone backgrounds contain no text, amount, control, status bar, logo, or watermark. All
three skins are included with no lock or paid messaging. Warm Botanical is the safe default and
corrupt-value fallback; Delete All resets it with other preferences. Simplified Chinese
user-facing catalog values use `花有数`, while English and technical identifiers retain
`MindBudget`.

Alternatives considered: Shipping only palette changes, cropping the supplied screenshots into
backgrounds, duplicating each screen per skin, tying skins to system light/dark mode, showing
disabled PRO rows before commerce exists, or renaming the Xcode target, bundle/store paths, and
Swift types.

Consequences: New skins can be added by extending one closed palette and localized metadata rather
than forking feature views. A future commerce phase may add entitlement metadata at the skin
catalog boundary only after end-to-end purchasing exists; the three original skins remain
included. Theme selection never changes financial data or privacy behavior.

Files affected: shared presentation theme, Settings/preferences, localized copy, feature views,
tests, redesign/test/project/task memory, changelog, and session log.

---

## 2026-08-07 — Version prerelease milestones visibly and publish their notes in-app

Context: Candidate `0.9.0 (1)` was visible on the signed device before the new skin system,
complete background artwork, and Chinese product-name cleanup were added. The owner requested that
the updated build carry a higher visible version and that users be able to read its changes from
the About screen, not only from repository and TestFlight documents.

Decision: Identify this cohesive prerelease milestone as marketing version `0.9.1`, build `2`.
Keep `1.0.0` reserved for the first public App Store release. Display the marketing version from
the bundle and show a concise bilingual update summary in Settings > About. Keep the same summary
represented in the dated changelog and next-candidate TestFlight notes. Future replacement uploads
always increment the build number; an owner-approved user-visible prerelease milestone may also
increment the `0.9.x` patch version.

Alternatives considered: Leaving the visible version at `0.9.0` and changing only the build,
showing repository prose verbatim inside the app, hardcoding the version in Swift, or using
`1.0.0` before public release.

Consequences: Testers can distinguish the skin/brand candidate on the device and understand its
changes without App Store Connect access. Version, build, changelog, TestFlight notes, About copy,
and release-readiness checks must move together.

Files affected: Xcode version settings, About UI/localization, UI coverage, release checks,
changelog, submission/release/task/project memory, and session log.

---

## 2026-08-07 — Use a brief app-owned transition for cold-launch branding

Context: iOS owns the launch screen and requires it to remain static. The owner requested a short
opening animation after seeing the signed-device build, while fast expense entry, accessibility,
and truthful startup state remain more important than a decorative splash sequence.

Decision: After the first app-rendered frame, show a selected-skin overlay containing the localized
product name, localized subtitle, and the existing budget-track mark for less than one second.
Run normal preparation concurrently underneath and present the overlay once per process, so a
background-to-foreground transition never replays it. During normal motion, gently reveal the
brand while the filled track and marker advance before fading out. With Reduce Motion enabled,
remove progress, marker, translation, and scale motion and use opacity only. Hide the animation
overlay from accessibility and hit testing so assistive technology and fast input can reach the
real prepared screen immediately. Permit a Debug-only launch argument to hold the final animation
frame for deterministic UI inspection; Release always ignores it.

Alternatives considered: Attempting to animate the system launch screen, shipping a video or
third-party animation runtime, delaying preparation until a long splash completes, replaying on
every foreground activation, or omitting Reduce Motion behavior.

Consequences: A cold launch gains a short branded transition without a new dependency or asset,
and the content can already be preparing during it. The decorative overlay never owns input or
accessibility focus. Signed-device release review must verify prompt exit, cold-only behavior,
both localized names, all skins, and the opacity-only Reduce Motion path.

Files affected: shared theme presentation, app routing, localization, About notes, UI coverage,
redesign/test/release/project/task/decision/session memory, changelog, and TestFlight notes.

---

## 2026-08-07 — Edit only the current budget plan in place

Context: The focused Settings hierarchy exposed Budget as a second-level page but rendered only
the accounting currency and preferred cycle start day. A signed-device check therefore looked
like budget editing had stopped working. Reusing first-time setup would be unsafe because that
flow creates a new plan and correctly rejects overlap with the already configured current cycle.

Decision: Give Settings its own current-budget edit path. Load the plan that contains an explicit
reference date, parse the four amount fields with the same exact locale-aware money parser used by
initial setup, and atomically update that existing plan through `DataActor`. Preserve its ID,
half-open boundaries, accounting currency, and category-budget rows. Reject a plan that no longer
contains the save-time reference date, so a page left open across a cycle boundary cannot mutate
history. Keep accounting currency read-only. Save the preferred cycle start day only after the
amount update succeeds; it affects future coverage and continues to use the established explicit
transition/first-regular confirmation flow.

Alternatives considered: Keeping the page as a read-only summary, inserting another plan from the
onboarding form, deleting and recreating the current plan, allowing arbitrary historical edits,
or directly binding the cycle start preference before the financial write succeeds.

Consequences: Users can correct the current period without duplicate plans or data loss, while
historical boundaries and accounting identity remain stable. Future automatic roll-forward copies
the corrected current amounts when no later plan already exists. A separately confirmed future or
transition plan is not silently rewritten.

Files affected: budget transfer/update boundaries, DataActor, Settings budget UI, localization,
unit/UI tests, release notes, and durable project memory.

---

## 2026-08-07 — Rebalance Today from current remaining budget and protect the app with an optional owner lock

Context: Signed-device review showed that the Today card could subtract today's discretionary
entries after those entries had already reduced `remainingFree`, producing a negative amount that
did not answer the product question. The same review requested Face ID protection for local
financial records without adding an account or cloud identity.

Decision: Define the Today amount as `ConfiguredBudgetSnapshot.safeDailySpend`: the exact
nonnegative remaining flexible budget divided by remaining calendar days after all stored entries
have already been applied. Keep pace variance separate so overspending remains visible without
corrupting the actionable daily amount. Surface the deterministic allocation in setup/Settings and
the reservation breakdown in Ask so a true zero is explained rather than hidden. Add a default-off
app lock backed only by `LocalAuthentication`. Require enrolled Face ID and successful owner
authentication to enable it, authenticate again before disabling, and keep an opaque root overlay
through cold launch and every inactive/background return until authentication succeeds. Use
`.deviceOwnerAuthentication` at unlock time so iOS can offer device-passcode recovery if biometric
enrollment changes. Never receive, store, log, export, or model biometric data.

Alternatives considered: Clamping a double-subtracted value to zero, presenting the cycle-wide
available amount as a daily allowance, inventing a fallback budget, enabling Face ID by default,
using app-owned PIN storage, providing no passcode recovery, or treating authentication cancel as
permission to reveal the prior screen.

Consequences: A configured budget yields a concrete, continuously rebalanced daily amount, while
zero allocations remain truthful and diagnosable. The app lock adds no server or account surface,
and cancellation fails closed. Signed-device release testing must verify the system permission
copy, Face ID/passcode behavior, background snapshot cover, localized lock screen, and recovery
after biometric changes.

Files affected: budget engine and Dashboard tests, Ask/allocation presentation, root app routing,
privacy settings and persistence, Info.plist/localization, release notes, privacy/test/task/project
memory, changelog, and session log.

---

## 2026-08-08 — Complete the free tier with an independent income ledger, rolling insights, and five open wishes

Context: The owner confirmed that the remaining free-tier gaps were per-entry income history, a
real in-app recent-30-day view, and the stated five-item wishlist limit. Existing configured
monthly income is a planning input rather than a transaction, while the released V1 store already
contains user data and must migrate without destructive reset.

Decision: Add `Income` only through Schema V2 and a lightweight V1-to-V2 migration. Store exact
positive `Int64` minor units, a closed income category, optional source/note, received date/time
zone, and audit timestamps. Keep income summaries note-free; detail, actor-contained note search,
and explicit CSV export are the only raw-note boundaries. Income history never changes a budget
plan automatically. Present expense and income together in one chronological Log and export both
through a stable `record_type` CSV column. Calculate Insights over the half-open calendar interval
from the start of 29 days ago through tomorrow. Treat active, cooling-off, and ready-to-review
wishes as open, and atomically reject a sixth at the DataActor insertion or terminal-to-open
transition boundary; purchased, skipped, and archived history consumes no slot.

Alternatives considered: Reusing `BudgetPlan.monthlyIncomeMinorUnits` as a ledger, automatically
raising a budget when income is recorded, adding income fields to `Expense`, computing 30 days as
30 × 86,400 seconds, hiding old wishes to enforce a total-row cap, or enforcing the five-item
limit only by disabling the SwiftUI Add button.

Consequences: Income history is exact, searchable, exportable, and independently correct without
inventing how receipts should alter spending permission. The calendar window is deterministic
across DST, and every app/Siri write observes the same wishlist policy. Delete All, data counts,
privacy disclosures, migration tests, CSV tests, in-app release notes, and TestFlight notes must
include the tenth model. This prerelease milestone is version `0.9.2`, build `3`; `1.0.0` remains
reserved for the first public App Store release.

Files affected: Schema/migration and income model, DataActor/projections/transfers, Log/Add routing,
Insights, Wishlist/Siri error mapping, CSV/deletion/privacy UI, localization, tests, version and
release metadata, and durable project memory.

---

## 2026-08-08 — Keep authoritative expense facts independent from supplementary Insights refreshes

Context: Device review found that Insights could retain its initial zero state after an expense
was saved. The screen previously treated cooling-off projections, derived-pattern persistence, and
the cycle narrative as prerequisites for publishing already-fetched expense totals. A failure in
any supplementary step therefore hid valid local ledger facts. A hidden tab also relied only on a
global revision task rather than explicitly refreshing when the user entered Insights.

Decision: Publish the deterministic 30-day and current-cycle expense summary immediately after the
expense and budget projections validate. Refresh when Insights becomes selected and whenever the
session revision changes while it is selected. Give every load a generation identifier so a
cancelled older request cannot replace newer facts. Cooling-off projections, cycle wording, and
derived insight upserts remain supplementary: their failure may suppress their own presentation
but must never erase or replace an authoritative ledger summary.

Alternatives considered: Retrying the entire coupled pipeline, retaining the last zero summary on
any error, silently ignoring every supplementary error, or refreshing only on app foregrounding.

Consequences: A newly saved expense appears on the next Insights entry even if the tab was hidden,
and valid totals remain available when an unrelated derived record is unreadable. Core expense or
budget projection failures still fail closed with the existing data-load error. Tests cover an
empty-to-populated reload and a corrupt cooling-off projection alongside a valid expense.

Files affected: Insights loading and selection lifecycle, Phase 11 regression tests, localized
current release notes, TestFlight walkthrough notes, changelog, decision memory, and session log.

---

## 2026-08-08 — Keep initial income and spending-budget inputs independent

Context: Signed-device setup showed that typing monthly income automatically copied the same value
into spending budget. That convenience predated the explicit allocation UI, but it now presents an
unconfirmed spending plan as though the user entered it and can silently keep following later
income edits while the mirrored value remains unchanged.

Decision: Treat monthly income and spending budget as independent fields from the first keystroke.
Never prefill, mirror, or overwrite spending budget from income. Require the user to enter and save
the complete planning draft explicitly; keep the existing localized validation and flexible-budget
preview as the only guidance between the fields.

Alternatives considered: Mirroring only the first income value, offering a suggested budget equal
to income, or retaining the mirror until the spending-budget field receives focus.

Consequences: Setup no longer invents a spending amount. UI automation must enter both values, and
the Simplified Chinese setup regression must prove that income entry leaves spending budget
untouched before saving a separately confirmed amount.

Files affected: initial budget setup state and UI, Phase 3 unit/UI tests, bilingual current release
notes, TestFlight walkthrough notes, changelog, decision memory, and session log.

---

## 2026-08-08 — Treat unreadable cooling-off outcomes as unknown in Insights

Context: Insights publishes authoritative expense totals before loading supplementary cooling-off
outcomes. The first resilience change preserved those totals after a cooling projection failed,
but continued the derived pipeline with an empty cooling array. That converted unreadable data
into zero skipped/purchased outcomes, could send those invented zeros to the optional on-device
model, and allowed an already-persisted cooling-success card to remain visible.

Decision: Keep the validated 30-day and current-cycle expense summary visible, then stop the
remaining Insights pipeline immediately if cooling-off projections cannot be read completely.
Do not generate a cycle narrative, call the optional wording enhancement, detect or persist new
patterns, or reload stored insight cards. Expose a localized partial-data warning. Preserve the
unreadable records for the existing explicit Settings repair flow rather than deleting them during
a read.

Alternatives considered: Treating the failed projection as an empty list, continuing only the
expense-based detector rules, hiding the authoritative expense summary, silently retaining stale
cards, or automatically deleting unreadable cooling-off records.

Consequences: Missing cooling-off facts are never presented or supplied to a model as zero, and a
stale cooling-success insight cannot appear beside a partial summary. Users still retain immediate
access to exact ledger facts and are told why derived content is absent. A later complete reload
resumes the normal pipeline, while cleanup remains an explicit user-confirmed operation. Regression
coverage preloads a stale cooling-success row before introducing a corrupt cooling-off projection.

Files affected: Insights state and presentation, Phase 11 regression coverage, AI prompt and test
contracts, current release/TestFlight notes, changelog, project memory, and session log.

---

## 2026-08-08 — Anchor today's allowance and expose every expense category in one swipe

Context: Signed-device review showed that a newly recorded expense barely changed "Left to spend
today." The old presentation reused the post-entry `safeDailySpend`, which redistributed the
expense across every remaining day instead of making today's card respond to the amount just
recorded. The expense form also showed only a short category subset and moved the remaining
categories into a separate modal list.

Decision: Reconstruct the flexible amount available at the start of the local calendar day by
adding today's already-counted discretionary expenses back to the authoritative remaining amount,
divide that start-of-day amount by the remaining calendar days, and subtract today's discretionary
expenses exactly once. Clamp the visible result at zero and retain any exact overage in a separate
`Money` value for explanation. A used or exceeded amount uses the destructive color only together
with an icon, localized gentle text, and a combined VoiceOver value. Fixed and savings-bucket
expenses do not consume this flexible daily reference. Present all persisted expense categories in
stable enum order within one horizontally scrollable selector, center the selected category, and
announce its selected accessibility trait.

Alternatives considered: Continuing to display the newly rebalanced `safeDailySpend`, subtracting
today's expenses directly from that already-reduced value, showing a negative primary amount,
deriving the correction in SwiftUI, retaining the five-item shortcut row plus a modal full list,
or paging categories into arbitrary groups.

Consequences: Every new flexible expense changes Today's amount one for one until it reaches zero,
while exact checked minor-unit arithmetic and calendar-day semantics remain in `BudgetEngine`.
The UI never displays a negative "can spend" value, but it does not hide an overage: the amount and
gentle explanation remain available separately. Category selection now requires horizontal
scrolling for later items, so UI and signed-device accessibility checks must verify swipe reach,
selection state, dynamic type, and VoiceOver order. Replacement TestFlight build `0.9.2 (4)` carries
the corrected behavior and synchronized release notes.

Files affected: budget pace engine and tests, Today card, expense category selector and UI test,
bilingual catalog, release metadata, changelog, test plan, task memory, and session log.

---

## 2026-08-08 — Keep the filter correction in PR 17 and defer the next product expansion to PR 18

Context: Signed-device review exposed raw `ledger.type.*` values in the Log filter and raised four
larger requests: an in-app Chinese/English switch, multiple recorded incomes reflected in planning,
a cross-cycle total savings goal, and monthly recurring fixed expenses. The existing `0.9.2 (4)`
PR is already a narrowly reviewed daily-allowance and category-interaction correction, while the
larger requests affect locale ownership, money semantics, scheduling, and likely SwiftData schema.

Decision: Fix record-type and budget-type localization on PR #17 using stable typed localization
keys and bilingual runtime coverage. Keep TestFlight upload paused. Record the four larger requests
as one new Phase 12 to be designed and implemented only after PR #17 review, then publish that work
as PR #18. Preserve current behavior until then: income entries remain exact history and do not
silently mutate a budget, and the existing savings amount remains a per-cycle reservation rather
than being relabeled as a lifetime target.

Alternatives considered: Uploading the raw-key build, folding all four product changes into PR #17,
automatically increasing spending permission for every income, reusing the per-cycle savings
reservation as a total goal, or promising exact background creation of monthly expenses while the
app is suspended.

Consequences: The visible localization defect can be reviewed independently with low migration
risk. PR #18 must first define an extensible app-locale boundary, explicit income allocation,
separate savings-goal semantics, recurring-rule deduplication and calendar behavior, and a tested
Schema V3 migration if persistence changes. No Archive or TestFlight upload resumes from this
decision alone.

Files affected: Log filter localization, enum localization keys, unit/UI tests, current release
notes, TestFlight guidance, Phase 12 task scope, project memory, changelog, and session log.

---

## 2026-08-08 — Explain a zero daily amount even before same-day spending

Context: PR #17 review found that a cycle with no distributable flexible allowance and no spending
today produced a bare zero on Today. The existing flags explained only an allowance that had been
used or exceeded through same-day spending, leaving the most constrained pre-spend state without
context.

Decision: Derive a separate `hasNoDailyAllowance` presentation fact when the deterministic
start-of-day allowance is zero and no discretionary expense has been recorded today. Display the
zero with the existing attention color, icon, and a localized neutral explanation that the cycle
currently provides no daily flexible amount. Do not claim that all flexible money is gone, because
an amount smaller than one minor unit per remaining day can also round the integer daily reference
to zero.

Alternatives considered: Leaving the zero unexplained, reusing the “used today” wording, describing
the user as over budget, moving the condition into SwiftUI, or restoring a negative primary amount.

Consequences: Available, exactly used, exceeded, and unavailable-before-spending states remain
distinguishable without changing signed cycle-level budget facts. Color is never the sole signal,
and the copy remains accurate for both exhausted and sub-minor-unit-per-day flexible balances.

Files affected: budget pace presentation facts and tests, Today card, bilingual copy, release/test
notes, project memory, changelog, and session log.

---

## 2026-08-08 — Make language, income allocation, savings progress, and recurrence explicit V3 facts

Context: After free-tier completion, the owner requested an app-local Chinese/English switch,
support for multiple incomes in planning, a total savings goal, and monthly fixed-expense
automation. These requests affect locale ownership, budget permission, cross-cycle state, and
calendar scheduling. Directly adding allocation fields to the shipped Schema V2 `Income` model
would also change that schema's fingerprint and put existing TestFlight stores at migration risk.

Decision: Persist one extensible app-language raw value with Follow System, Simplified Chinese, and
English. The stored value is also published observable state, so changing it invalidates the
SwiftUI root immediately rather than waiting for another preference change or a relaunch. Inject
its locale at the SwiftUI root and use it for deterministic Ask/templates, formatting, app-owned
notification and Spotlight reconciliation, localized ledger search, and export filenames. Keep
Siri's own surface governed by the system/Siri locale.

Recording an income remains a ledger fact and grants no spending permission by itself. Store any
owner-confirmed spending and savings portions in a new Schema V3 `IncomeAllocation` companion row;
require both values to be nonnegative and their checked sum not to exceed the income. A nonzero
spending portion must persist the explicit target `BudgetPlan` identifier, and that plan must exist,
match the accounting currency, and contain the income's `receivedAt`. The income form displays the
exact target cycle and refuses a spending allocation when no saved cycle contains a historical
date; it never creates a budget merely to accept an allocation. Only that targeted spending portion
increases the deterministic budget. Store one independent cross-cycle `SavingsGoal` whose progress
is its starting balance plus confirmed savings allocations; do not repurpose
`BudgetPlan.savingGoalMinorUnits`, which remains a cycle reservation.

A monthly fixed-expense rule begins only when the owner confirms the recurring toggle. Its editable
anchor uses the recorded local day/time and time-zone identifier, clamping days 29–31 to the last
valid day of shorter months. The immutable initial-occurrence date records only the source expense's
already-handled month; moving the editable anchor into a later month therefore cannot cause that
month to be skipped. Reconciliation runs on prepare and foreground, first plans and deduplicates all
rules' due occurrences, rejects the complete transaction when their combined count exceeds 120,
then atomically generates fixed/planned expenses and stable year-month occurrence identities. Edits
affect future occurrences; pause/resume advances `activeSince` so paused months are not backfilled.
Deleting a rule never deletes generated ledger history, and editing a generated entry cannot create
a second rule.

Alternatives considered: Mutating the budget for every income automatically; treating all income
as spendable; relabeling the cycle reservation as a lifetime savings target; modifying Schema V2's
Income fields in place; using timer/background promises for exact due-time insertion; storing
recurrence as 30-day seconds; silently backfilling months before confirmation or during a pause;
or deleting generated expenses with their rule.

Consequences: Existing V2 income migrates with an exact zero allocation rather than an invented
choice. The Today and Ask budget facts can reflect extra income only after an explicit, valid cycle
allocation; a historical income cannot silently change the current cycle or point at no cycle.
Savings progress survives cycle changes without changing cycle arithmetic. Recurring expenses are
honest about app execution limits, deterministic across DST/month ends, and idempotent after long
closures. Editing a rule's month cannot lose the first future occurrence, and the 120-row safety
bound applies to the full foreground transaction rather than independently to each rule. Schema V3
adds `IncomeAllocation`, `SavingsGoal`, `RecurringFixedExpenseRule`, and
`RecurringExpenseOccurrence`; CSV and verified Delete All include the new records. Every persisted
table is a required argument of the production `ModelCounts` initializer, and its explicit `.zero`
fixture enumerates the same set, so adding a model without extending deletion verification remains
a compile-time failure. The unified CSV leaves inapplicable attributes empty and appends the two
allocation columns after every existing column. Candidate version is `0.9.4 (5)` and TestFlight
remains paused until PR #18 is reviewed.

Files affected: language settings/root environment and integration reconciliation, Schema V3 and
migration plan, income/budget/savings/recurring actor paths, forms and Settings hierarchy, CSV and
privacy deletion, bilingual copy, release metadata, tests, task memory, changelog, and session log.

---

## 2026-08-09 — Drain recurring backlogs in bounded chronological batches

Context: The first combined-rule safety implementation rejected an entire reconciliation when more
than 120 occurrences were pending. Because the rollback preserved no new occurrence identities,
the next launch received the same input and failed again. A realistic set of monthly fixed expenses
could therefore become permanently unreconcilable after a long absence. Review also confirmed that
the selected skin, like the app language before it, affected the root view while remaining an
unpublished `@AppStorage` property inside an `ObservableObject`.

Decision: Each rule enumerates at most its oldest 120 missing occurrence dates while explicitly
reporting whether more exist. The actor combines those bounded candidates, sorts them by scheduled
time and stable occurrence key, and atomically inserts only the globally oldest 120. Its typed
result reports both the inserted count and whether another foreground pass is needed. Existing
occurrence identities are skipped during enumeration, so each later prepare/foreground pass makes
progress without duplicates. The 120 value remains a per-transaction write bound, not a reason to
reject valid accumulated history or to loop repeatedly during one foreground activation. Each
enumerated candidate carries its already-computed stable occurrence key into the actor write plan.
Settings renders the published `hasMore` state as neutral progress rather than an error. A single
rule scans at most 1,200 calendar months per reconciliation and fails closed if that defensive
bound is exhausted, preventing unexpected calendar behavior from hanging foreground work.

Persist skin and language selections as explicit `@Published` values synchronized through named
UserDefaults keys. These are the two settings directly consumed to build root theme/locale state;
tests require each change to publish immediately and persist independently. Pass the SwiftUI
environment calendar into initial preparation as well as foreground reconciliation. Keep the
budget-plan allocation cross-check unchanged: it deliberately compares cycle-scoped incomes with
a store-wide allocation map and can detect an out-of-cycle income targeting the plan.

Alternatives considered: Keeping overflow as an atomic error with only a generic Settings warning;
inserting every missing row in one transaction; repeatedly draining all batches during one launch;
returning only an insertion count; or relying on navigation and unrelated published state to redraw
the selected skin.

Consequences: A large backlog may require more than one foreground activation, but every successful
activation commits no more than 120 oldest entries, exposes remaining work as a non-error state,
shows that state in the recurring-expense Settings page, and cannot become stuck on the same first
121 rows. Occurrence identity is calculated once per candidate, and enumeration has a separate
hard termination bound. Root language and skin selections now share an observable persistence
contract. Other `@AppStorage` preferences retain their existing explicit session/action redraw
paths and should be converted if a future root-only consumer is added.

Files affected: recurring schedule/reconciliation projections and tests, app session calendar and
backlog state, SettingsStore observation tests, project memory, test plan, changelog, and session log.

---

## 2026-08-09 — Keep cycle usage states explicit and Ask actions deterministic

Context: Physical-device testing showed CNY 236 of recorded current-cycle spending beside a
“0%” cycle narrative. The percentage path used one integer for an unavailable budget denominator,
configured zero spend, and any positive ratio below one percent. A separate Ask test showed Apple
Intelligence available and enabled but the answer card reported only a generic local template;
Debug retained one coarse validation failure but not its typed cause. Ask also asked the model to
reproduce internal action identifiers even though those suggested labels are deterministic
product behavior.

Decision: Represent summary usage as a closed `.unavailable`, `.lessThanOnePercent`, or
`.percent(Int)` state. Only a configured positive budget with exactly zero spending may become
zero percent. A sub-one-percent state and an unavailable denominator expose no numeric percentage
fact. The closed state key communicates the relationship, while any generated digit not present in
other aggregate facts is rejected and falls back to localized template copy. Because every general
numeric allow-list intentionally flattens numbers from different facts, bind generated numeric
percentage expressions separately on all three output paths. Ask has no percentage-shaped fact and
therefore permits none. Reminder output permits only the exact non-nil values supplied by its
free-budget-impact and category-budget-used percentage fields; days consumed is a count, not
percentage authority. Summary output binds to `SummaryBudgetUsage`: unavailable and sub-one states
permit no numeric percent, and an exact state permits only its own integer. Recognize ASCII and
full-width percent signs before or after
the number, with optional presentation spacing. This prevents an unrelated zero cooling-off,
emotion, stress, or impulse count from authorizing a false `0%` statement.

For Ask, generate only title and body with Foundation Models. Validate the app-owned action
contract while constructing the redacted context: a purchase decision has two to four unique
actions including Continue Purchase, and every other Ask context has at most four unique actions.
Attach that complete action set in deterministic Swift and keep it outside model-output
validation, so an app configuration error cannot pollute model safety diagnostics. Continue to
reject fabricated numbers, the wrong language, unsafe wording, and empty or oversized text.
Reminder and summary paths still validate actions that their models generate. A numeric-component
hyphen is a separator rather than a unary sign, while a leading or whitespace-delimited minus
retains negative-money meaning. Simplified Chinese model copy must contain Han text and cannot
contain more basic Latin letters than Han characters, allowing short currency codes without
accepting predominantly English prose. Distinguish validation, timeout, availability, and
unexpected-model fallback on the answer card. In Debug builds retain aggregate counts for the exact typed
`AdviceSafetyViolation`; never retain rejected generated text, prompts, or user financial facts.

Alternatives considered: Rounding or truncating every ratio to zero; showing an invented
percentage when no budget denominator exists; weakening numeric or language validation so more
model output passes; persisting failed model text for diagnosis; or continuing to delegate app
suggested-action identifiers to the wording model; validating deterministic app actions as though
they were untrusted generated content; or treating every hyphen as a negative sign.

Consequences: Cycle overview remains honest for configured zero, very small positive use, and
missing baselines. The most avoidable Ask validation failure—generated internal action tokens—is
structurally removed without weakening any content safety rule. Sub-one-percent wording cannot
silently become an exact one-percent claim, localized cycle months do not create false fabricated-
number counts, token Chinese phrases cannot admit an otherwise English response, and percentage
claims on Ask, reminder, or summary cannot borrow an unrelated fact's number. Users can
tell why a safe complete template was used, while developers can identify the exact model-output
validator branch locally without creating a new privacy surface.

Files affected: advice/summary/Ask redaction and generation, safety diagnostics, Ask and Debug
settings UI, bilingual copy, Phase 7 tests and contracts, project memory, changelog, decisions,
and session log.

---

## 2026-08-09 — Present cross-cycle savings separately and bind Foundation Models to app locale

Context: The cross-cycle savings goal existed in Settings, but Insights did not show its progress.
Physical-device diagnostics also showed the model available while a Simplified Chinese request
fell back because the generated wording was English. Runtime support had been checked with
`Locale.current`, and the session carried only a generic locale-language sentence instead of the
selected app locale's explicit output requirement.

Decision: Derive target, saved, remaining, and integer completion progress from the existing
`SavingsGoalSummary`. Keep the ratio in basis points on the Sendable projection and let Insights
render those facts without recalculating money or treating the per-cycle savings reservation as a
lifetime goal. Read this projection independently so an unavailable goal can show a localized
module error without hiding valid spending insights.

Pass the active app locale into the centralized Foundation Models capability for Ask, reminders,
cycle summaries, and Settings status. On supported SDKs, call `supportsLocale` with that locale.
Every model session names the exact app-locale identifier using Apple's documented wording and
adds an explicit requirement to answer only in its language. Keep generated-language validation
and the localized deterministic template fallback unchanged, because instructions reduce drift but
do not establish trust. Debug fallback counters remain in-memory and cumulative for one process,
so their heading must not be read as the current availability state.

Alternatives considered: Building savings progress from the current `BudgetPlan` reservation;
calculating ratios independently in each view; hiding the entire Insights page when the goal read
fails; checking only the device/process locale; or weakening language validation so more generated
copy appears.

Consequences: The user can see one honest cross-cycle savings status beside spending insights,
while cycle budget math remains unchanged. Changing the app language immediately changes both the
model support check and the requested response language. A model that still answers in the wrong
language is never shown, and no new user text, raw transaction, or financial detail enters a model
context.

Files affected: savings projection and Insights/Settings presentation, Foundation Models
capability/session construction, Ask/reminder/summary locale plumbing, bilingual copy, tests,
prompt/test contracts, changelog, project memory, tasks, and session log.

---

## 2026-08-09 — Require the app locale at every model capability boundary

Context: Review of the savings/locale update found that runtime support had moved from region-
oriented process state to the app-selected language, but the unavailable reason still said the
region was unsupported. The capability initializer and SDK helper also retained
`Locale.current` defaults, allowing a future caller to compile while silently restoring the exact
language mismatch this update fixes. Chinese instructions treated every `zh` locale as Simplified,
and the savings completion projection multiplied by 10,000 without an explicit overflow-safe path.

Decision: Represent unsupported selected language as a dedicated actionable reason. Require
`targetLocale` in `AIEnhancementCapability` and `locale` in the runtime availability helper with no
default, and remove the unused generator-level availability property that was the last process-
locale route. Derive Simplified or Traditional Chinese instructions from the locale script, with
TW/HK/MO as the region fallback when a script is absent. Compute savings basis points with
`multipliedFullWidth` and `dividingFullWidth`, retain the actor's zero clamp for over-target
remaining money, and cap visible completion at 100%.

Alternatives considered: Rewording the old region message to cover both concepts; retaining
`Locale.current` as a convenience fallback; mapping every Chinese locale to Simplified Chinese;
or relying only on the current money ceiling to make ordinary multiplication practically safe.

Consequences: A newly added model path cannot omit the app locale without a compile error. Users
who select an unsupported language receive a relevant recovery suggestion instead of a false
region diagnosis. Chinese instructions preserve the requested writing system, and savings
progress remains exact without overflow or negative remaining money at successful completion.

Files affected: Foundation Models capability and protocol surface, bilingual status copy, savings
projection arithmetic, Phase 7/11 regressions, and durable project memory.

---

## 2026-08-09 — Retire manual fixed-expense forecasts from budget setup

Context: Budget setup required a fixed-expense forecast even though expense entry now owns the
confirmed monthly recurring fixed-expense workflow. Keeping both paths asked for the same fact
twice and risked reserving a forecast in addition to counting the generated ledger entry. The
visible “flexible budget after reservations” also no longer matched the requested income-level
planning question.

Decision: Remove the fixed-expense input from initial setup, transition confirmation, and the
current-cycle Settings editor. New and automatically copied plans write zero to the existing
`fixedExpensesMinorUnits` field. Add a Schema V4 `BudgetPlanSemantics` companion row rather than
mutating the frozen `BudgetPlan` shape. A plan without that row is a migrated Schema V1–V3 plan and
keeps its persisted Expected expenses amount as the funding base, plus any fixed reservation,
through that legacy cycle. Every newly materialized plan writes an `.incomeBased` marker and uses
configured monthly income plus only extra income explicitly allocated to the spending budget,
minus the per-cycle savings goal, clamped at zero. Actual fixed entries consume any retained
compatibility reservation first, so only an amount above it is an additional deduction.
Expected expenses remains a separate planning reference for pace, cycle-usage copy, and amount
reasonableness; it does not grant additional spending permission. Actual fixed and discretionary
ledger rows reduce the disposable balance. The daily card charges only discretionary entries to
that day's reference amount; a fixed entry already reduces the cycle balance and is therefore
rebalanced across the remaining days instead of being subtracted a second time on its entry date.

Alternatives considered: Hiding the field without changing persisted or engine behavior; deleting
the persisted property through a new schema migration; using Expected expenses as the runtime
funding limit; or deriving a hidden fixed forecast from recurring rules. A schedule-derived
forecast was rejected because recurring rules are execution aids rather than a complete forecast:
one-off fixed entries, paused rules, and mid-cycle edits would make that reservation incomplete and
could silently recreate the same double-accounting problem.

Consequences: Users manage fixed expenses in one place. Existing stores migrate through a
lightweight companion model without changing the historical plan shape or causing either an upward
or downward current-cycle balance jump—even when an old plan stored zero monthly income. Legacy
forecasts cannot double-reserve the current balance. A new 20,000 income,
8,000 Expected expenses plan, and 2,000 savings goal shows and enforces 18,000 disposable money in
both setup and Today. Explicit extra-income allocation increases both funding and the spending-plan
reference; merely recording income changes neither. A large fixed entry can move the cycle's linear
pace on its occurrence date, but it cannot zero today's amount through a second same-day charge.
The old funding base and forecast remain readable only for unmarked migrated plans. Settings uses
that same base for the current preview and explains that the next automatic cycle switches to
income-minus-savings and writes a zero fixed forecast. A new plan with genuinely zero income stays
at zero rather than borrowing Expected expenses. No destructive migration is required.

Files affected: budget setup, transition and Settings UI, Schema V4 companion metadata and
migration, budget draft/copy construction, `BudgetEngine`, bilingual copy and release notes,
unit/UI regressions, test plan, changelog, project
memory, tasks, decisions, and session log.

---

## 2026-08-10 — Govern commercialization through a separate accepted decision register

Context: The owner-approved commercialization specification creates a new COM-C0A through
COM-C12 track without replacing the completed local-first product history. Copying every
commercial Product-ID, pricing, network, iCloud, provider, backend, Watch, and entitlement
decision into this already long main log would create two authorities that can drift.

Decision: Keep the main product history and current-version guarantees in this file. Make
`Docs/Commercialization/DECISIONS.md` the detailed decision authority for the COM track, backed by
stable Requirement IDs, `Docs/Commercialization/PROJECT_MEMORY.md`, and the accepted empty current
Release app-owned egress set in `NETWORK_EGRESS_POLICY.md`. Existing 0.9.x behavior remains local;
later channels are permitted only through their named authorization, disclosure, deletion,
failure, and release gates. This entry is a pointer, not a duplicate commercial decision set.

Alternatives considered: Duplicating every commercial decision here; overwriting historical
local-only decisions; or leaving commercialization decisions only in session transcripts.

Consequences: A reviewer can identify one detailed authority and one historical pointer. COM-C0B
changes documentation, CI/report paths, and non-behavioral gates only; entitlement/StoreKit work
starts no earlier than COM-C1/COM-C2. Prices, trial, quotas, storefronts, providers, domains, and
formal App Store Connect products remain TBD/evidence-gated. The empty current app-owned egress
set is enforced against app Swift source and Release configuration surfaces without classifying
documentation links as endpoints, and the owner-held detailed specification remains private with
one repository fingerprint/provenance record whose external-drift limitation is explicit.
Detailed rationale is DEC-COM-010 and DEC-COM-011.

Files affected: root agent rules, main/commercial project memory, commercial decisions and
matrices, commercialization task map, CI source/documentation gates, source provenance, retained
CI evidence, and session logs.

---

## 2026-08-11 — Route accepted existing advanced entries through the COM authority

Context: COM-C1-03 is the first packet allowed to change how existing advanced entries are
reached, but it cannot add StoreKit, a paywall, pricing, a new feature, or a network channel.

Decision: The detailed accepted scope and fallback behavior live in commercial decision
DEC-COM-014. Apple on-device wording, non-24-hour cooling choices, and advanced Siri consume one
Commerce-owned snapshot. Exact Free retains templates, basic 24-hour cooling, basic Siri
record/check actions, current 30-day Insights, the five-item wishlist, and all trust/core features.

Consequences: Main product history points to one commercial authority instead of duplicating the
matrix. Passive App Entity providers return no results under unavailable/exact-Free access, while
active advanced Siri actions retain neutral rejection. The uploaded 0.9.6 binary remains
unchanged; this source is not distributable until verified purchase/restore, purchase presentation,
and the owning release gates are complete. No version, schema, product, purchase UI, or release
state changes in this packet.

---

## 2026-08-11 — Keep the first StoreKit catalog test-only and non-archivable

Context: COM-C1 is complete, and COM-C2 begins with catalog-shape validation before prices, trials,
formal App Store Connect products, or a runtime transaction authority are accepted.

Decision: Detailed catalog and isolation rules live in commercial decision DEC-COM-015. C2-01
contains only the accepted Monthly/Annual Xcode StoreKit Configuration fixture, copied to tests and
activated by a dedicated local scheme that cannot Archive. The default app scheme and app resources
remain fixture-free.

Consequences: The catalog can be tested without converting synthetic local values into commercial
terms or test state into Release authority. Runtime StoreKit, purchase/restore, paywall, formal
products, and distribution remain blocked by their later packets and release gates.

---

## 2026-08-12 — Keep runtime StoreKit authority separate from presentation state

Context: COM-C2-02 is the first packet that may load runtime StoreKit products and reconcile
current entitlements, but purchase, restore, status mapping, customer terms, and distribution still
belong to later packets.

Decision: Detailed runtime catalog, cache, lifecycle-listener, environment-isolation, and
fail-closed rules live in commercial decision DEC-COM-016. The app has one process-local StoreKit
authority. Only current verified StoreKit state can replace its immutable entitlement snapshot;
cached Product presentation never grants access. C2-02 retains revocation and expiration as raw
facts rather than filtering a past expiration before C2-03 can apply the billing-status mapper.

Consequences: Existing UI and App Intents receive one dynamic authority without learning Product
IDs, prices, raw entitlement bits, or billing state. Unknown, mixed, or unverified authority input
returns to Free. C2-02 adds no purchase/restore/paywall, schema, app-owned network domain, customer
term, version, Archive, upload, tester, or distribution change. The C2-03 entry condition required
the CHN and USA local StoreKit product probes to execute rather than skip and pass under a
supported final Xcode/runtime surface. Detailed evidence remains in commercial DEC-COM-016:
final Xcode 26.6 `17F113` produced historical `Code=3`/empty-product failures on final iOS
26.4/26.5 simulators, and the iOS 27 beta pass was diagnostic only. On 2026-08-13 the dedicated
scheme passed all 5 tests with 0 failed and 0 skipped on a physical iPhone Air running final
iOS 26.6.1 `23G82`, including passed CHN and USA probes. This unlocks C2-03 implementation only;
C2-04, paywall, commercial terms, and distribution remain blocked by their own gates.

---

## 2026-08-13 — Publish StoreKit authority before finishing a handled transaction

Context: COM-C2-03 is the first packet allowed to add purchase, restore, subscription-status
mapping, and transaction acknowledgement, but it cannot add a paywall, customer terms, formal
products, or distribution authorization.

Decision: Detailed lifecycle semantics live in commercial decision DEC-COM-017. One
`EntitlementStore` remains the sole process-local StoreKit authority. It maps verified status
transaction and renewal information, grants only subscribed and verified billing grace, exposes
purchase/restore as typed programmatic seams, publishes one actionable access snapshot before
calling `Transaction.finish()`, and leaves a failed acknowledgement unfinished for later retry.
One lifecycle task supervises `Transaction.updates` and
`Product.SubscriptionInfo.Status.updates`; a status signal only causes the same authority to
perform a fresh full reconciliation and cannot become a second authority or UI.

The detailed COM decision also keeps the restore post-sync transaction bridge in C2-03. A verified
restored transaction can arrive before `currentEntitlements` catches up; C2-04 owns environment
isolation, not first implementation of restore. Status/foreground refreshes cannot satisfy this
bridge, and newer revocation or unverified authority rejects stale facts. The implementation calls
a resolution `actionable` when it is safe to use; this intentionally differs from asserting every
supplemental presentation/catalog read was complete.

Consequences: Pending, cancelled, unverified, retry, expired, revoked, unknown, mixed, or
incomplete authority cannot silently grant a paid right. Duplicate/concurrent transaction
delivery does not create another listener or finish the same transaction twice in process. PR #30
passed independent review and green CI and merged C2-03 as `3fc72b4`. No current view invokes
purchase or restore; C2-04 subsequently completed through PR #31 as `a293762`, while paywall/
purchase presentation, formal price/trial/product work, versioning, Archive/upload, tester
assignment, and distribution remain blocked. The uploaded 0.9.6 binary and release hold are
unchanged.

---

## 2026-08-13 — Bind StoreKit rights to a verified app environment

Context: COM-C2-03 passed independent review and green CI and merged through PR #30 as `3fc72b4`.
C2-04 must prevent local Configuration, Sandbox/TestFlight, and Production authority from
contaminating one another without adding customer UI or distribution permission.

Decision: Detailed environment semantics live in commercial decision DEC-COM-018. The verified
`AppTransaction` bundle and environment select the whole StoreKit authority context. Every
verified transaction/status fact must match that independently verified environment and expected
bundle. TestFlight follows Apple's Sandbox environment; no build configuration or manual flag may
relabel it as Production.

Consequences: Missing, unknown, cross-environment, or wrong-bundle input fails closed. Exact
environment/storefront presentation caches remain non-authoritative, and catalog-only failure
does not erase a separately verified active subscription. Focused, full regression, strict local
performance, and coverage gates passed; PR #31 passed independent review and green CI and merged
C2-04 as `a293762`, completing COM-C2. C3 has not started; paywall/customer purchase UI, formal
terms/products, versioning, Archive/upload, tester assignment, and distribution remain blocked.

---

## 2026-08-14 — Begin C3-01 with provisional StoreKit test terms

Context: COM-C2 is complete. The owner explicitly authorized C3-01 and supplied nonpublic test
inputs: US$1.99 Monthly, US$19.99 Annual, a 7-day free trial, and HKG/USA/SGP/TWN as the first test
storefront set.

Decision: Detailed presentation and release boundaries live in commercial decision DEC-COM-019.
Customer UI must render StoreKit price, period, and eligibility rather than a hardcoded currency or
local conversion. C3-01 is voluntary and noninterrupting; Settings and explicit Pro value triggers
are the only entry points. The accepted values configure tests but are not final launch economics.

Consequences: C3-01 may add a transparent purchase/restore/manage-subscription View through the
existing typed StoreKit lifecycle seams. C3-02 reminders, signed public configuration, formal App
Store Connect products, versioning, Archive/upload, tester assignment, and distribution remain
blocked. The post-0.9.6 release hold remains active.

Review remediation: The exact P1W offer remains an isolated Configuration/test assertion and is
not part of production catalog or entitlement validity. Production presents an optional actual
StoreKit offer only after fresh eligibility, blocks purchase at both View and actor boundaries
when subscription authority is unavailable, and formats renewal disclosure with the app-selected
locale. Eligible paid/unknown introductory modes retain their StoreKit price/mode but pause at the
View and adapter instead of inheriting standard renewal copy; promotion shape remains outside
entitlement authority. Detailed ownership remains in amended DEC-COM-019.

---

## 2026-08-14 — Drive trial reminders from verified lifecycle facts, not configured duration

Context: C3-01 passed independent review and green CI and merged through PR #33 as `747b628`.
C3-02 may now own trial activation and renewal reminders, but the provisional P1W fixture remains
test presentation input rather than production lifecycle authority.

Decision: Detailed ownership lives in commercial decision DEC-COM-020. A verified current
introductory-free-trial transaction proves trial activation; verified renewal information supplies
Apple's actual renewal date and auto-renew state. The projection keeps the current trial product
separate from the accepted `autoRenewPreference` used for next-renewal price display, falling back
only when the preference is absent. One generic pending reminder is reconciled at
calendar T−5 only when permission already exists and the date is reliable. Disabled/denied
notifications use an in-app card without an implicit authorization prompt.

Consequences: Cancellation, trial end, refund/revocation, product/date change, missing authority,
or failed replacement cannot leave stale billing content scheduled. Notification copy contains no
date, price, amount, product, or day count; in-app disclosure uses only the verified date and a
current live StoreKit price for the next-renewal product. Pending notification copy says the trial
ends soon rather than promising renewal after the app process can no longer observe cancellation.
C3-03/configuration, formal products/economics, versioning, Archive/
upload, tester assignment, and distribution remain blocked.

Closeout: PR #34 passed independent review and green GitHub Actions run `31803898776`, then
merged as `12d9217` on 2026-08-14. C3-02 is Done. This does not start C3-03 or relax the
post-0.9.6 release hold.

---

## 2026-08-14 — Accept a two-packet signed public-configuration boundary

Context: C3-01 and C3-02 are Done. The owner explicitly authorized C3-03 and accepted the
recommended exact environment, transport, signature, cache, rollback, privacy, and presentation
boundary.

Decision: Detailed ownership lives in DEC-COM-021 and
`Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md`. C3-03A implements only strict Ed25519
verification, the closed schema/version/expiry/size contract, rollback/equivocation protection,
durable signed cache/high-water mark, and conservative fallback. It has no network adapter, URL,
production key, entitlement/StoreKit authority, or application consumer. C3-03B may add only the
accepted fixed anonymous `GET /v1/config` transport and optional-presentation integration after
C3-03A review and merge.

Consequences: The current Release HTTP(S) allow-list stays empty. Configuration schema v1 can
control only `proValueTriggersEnabled` and can never grant paid rights or change products, prices,
trials, notifications, cloud features, or release behavior. C3-04, formal economics/products,
versioning, Archive/upload, tester assignment, and distribution remain blocked.

Review clarification: Detailed DEC-COM-021 now makes corrupt rollback state a sticky Release
fail-closed condition recoverable only by deleting the app data container and reinstalling; normal
Delete All and Offload do not reset it. It also fixes UTC timestamps to whole-second
`yyyy-MM-dd'T'HH:mm:ss'Z'`, rejects duplicate keys, serializes concurrent high-water acceptance,
and requires post-write abstraction-level re-verification. The client continues to verify exact
signed bytes instead of defining a second canonical-JSON encoder. C3-03A adds no runtime logging;
closed non-content reason-code observability remains a C3-03B transport/operations responsibility.

Completion evidence: The review-remediation head `3a53107` passed independent review and green
GitHub Actions run `31856271268`; PR #36 merged C3-03A to `main` as `1ebb36c` on 2026-08-15.
This activates only C3-03B implementation. The empty Release HTTP(S) allow-list, C3-04 block, and
post-0.9.6 distribution hold remain unchanged.

---

## 2026-08-15 — Keep the public-configuration transport fixed and non-authoritative

Context: C3-03A is Done. C3-03B needs one real first-party path without creating a generic network
client, entitlement channel, identifier, content upload, or premature Production deployment.

Decision: Detailed ownership lives in DEC-COM-022. The app uses one exact environment-isolated
anonymous configuration GET, an ephemeral no-cookie/no-cache session, the embedded Ed25519 public
key, conservative verified cache fallback, and closed non-content reason codes. The independent
Worker serves only pre-signed bounded envelopes and has no private key, storage, outbound fetch, or
app logging. Configuration can affect only an optional explicit Pro value trigger and never paid
authority or permanent purchase/restore/manage access.

Independent-review remediation requires that the response-completion clock validate expiry, that
every verified resolution carry its signed expiry for automatic foreground invalidation, and that
caller cancellation cancel the owned refresh operation before it can publish. The optional trigger
also requires an actionable exact-Free StoreKit whole snapshot; unavailable or unverified
fail-closed access is not treated as confirmed Free presentation authority.

Follow-up review makes startup refresh a dedicated structured SwiftUI task, retains and cancels
scene refresh on lifecycle exit or Session destruction, resets the startup one-time guard after
cancellation so a recreated SwiftUI task can retry, and defines the persistence commit point as
the final cancellation check immediately before the atomic write. Cancellation before that
point cannot change the cache; an already-started atomic commit may finish but cannot publish a
canceled acceptance result. See DEC-COM-022 for the full boundary.

Consequences: Development was deployed and passed real adapter/verifier tests; Staging and
Production remain undeployed. The final reviewed head `09c382e` passed GitHub Actions run
`31873664396`; PR #38 merged C3-03B as `db7926d` on 2026-08-15, closing C3-03. C3-04 is ready but
not started pending explicit owner instruction. Final binary/Production traffic, privacy/review
disclosure, formal products/economics, Archive/upload, tester assignment, and distribution remain
blocked.

---

## 2026-08-15 — Keep C3-04 subscription guidance non-blocking and StoreKit-authoritative

Context: C3-03 is Done and the owner explicitly started C3-04. The existing entitlement mapper
already distinguishes subscribed, billing grace, billing retry, expired, revoked, and unavailable;
the release-quality packet needs truthful presentation without creating a second authority.

Decision: Detailed ownership lives in DEC-COM-023. Exceptional verified states use one bilingual
Dashboard navigation card plus one Pro-screen explanation with Manage Subscription and Recheck.
Grace keeps Pro; retry/expired/revoked preserve local data and Free capabilities. Unavailable is
not exact Free. Plan controls reflow at accessibility sizes and carry explicit VoiceOver semantics
across all three appearances. Customer terms never hardcode fixture prices or a seven-day trial.

Consequences: No automatic modal paywall, entitlement rule, StoreKit product, signed-config field,
or network channel changes. Review disclosure is updated, but Staging/Production deployment,
formal economics, final Release binary/traffic evidence, versioning, Archive/upload, tester
assignment, and distribution remain blocked.

---

## 2026-08-16 — Keep positive purchase checks transient and category proportions lossless

Context: A retained `safeToProceed` insight displayed its candidate-entry
`remainingFreeAfter` value as a current budget buffer after later expenses had changed the ledger.
The budget snapshot and impact calculation already included every expense supplied to them; the
defect was persisting a time-bound positive check and later presenting that frozen payload as a
current conclusion. The category chart also displayed only the six largest categories, silently
omitting the remaining categories from the visual breakdown.

Decision: Keep `safeToProceed` available to the immediate expense-entry reminder flow, but classify
it as non-durable. `DataActor` does not persist new instances and filters legacy instances from all
retrospective insight reads. The legacy filter runs on `typeRaw` before payload decoding so a
malformed legacy safe-check row cannot block an otherwise valid retrospective read; unknown raw
types still reach the strict mapper and fail closed. Warning and recurring-pattern insight types
remain durable. Replace the category bar chart with a donut chart based on the full rolling
30-calendar-day ledger. Keep up to six real categories; only seven or more categories show the
five largest plus one localized "Other categories" segment using checked `Int64` minor-unit
addition. Equal totals use a stable category-identifier tie-breaker. The chart uses an app-owned
key with category and amount values, changing from two columns to one at accessibility sizes so
each item remains available to VoiceOver without a clipped system legend.

Alternatives considered: Recomputing the old stored positive card from its payload, retaining it
with a historical label, deleting all legacy rows destructively, continuing to show only a prefix
of categories, and rendering an unbounded legend with every category. A stored payload cannot
reconstruct current authority, a positive entry check has little retrospective value, destructive
migration is unnecessary, and silently omitted or unbounded categories make proportions harder to
interpret.

Consequences: The immediate purchase check remains deterministic, but Insights and passive system
projections no longer repeat a stale positive balance. Existing legacy rows remain recoverable in
the local store but are hidden by the typed read boundary. The category chart is bounded to six
segments while its segment sum remains exactly equal to the 30-day category total; a six-category
ledger preserves every category name rather than replacing one with a remainder. No budget formula,
schema, entitlement, network, commerce, version, upload, or distribution behavior changes.

Files affected: Insight-type durability vocabulary, spending-insight persistence/read policy,
Insights aggregation and chart presentation, localization, Phase 5/11 tests, UI evidence, change
log, and durable project memory.

---

## 2026-08-16 — Authorize only the 0.9.7 TestFlight transport upload

Context: C3-04 passed independent review and green GitHub Actions run `31918968478`, then merged
through PR #40 as `9448ca9`, closing COM-C3. The owner requested a new uploaded build while
retaining control of internal/external TestFlight assignment.

Decision: Detailed ownership lives in DEC-COM-024. Prepare version 0.9.7/build 8 from merged source,
validate and sign it with the current team, upload it to the existing App Store Connect record,
and stop after transport acceptance. Do not assign testers or submit external/App Store review.
Production signed configuration remains undeployed and therefore leaves only its optional trigger
conservatively off; it does not affect StoreKit or permanent subscription controls.

Consequences: Build 8 becomes immutable after upload. This instruction does not approve public
launch economics, deploy Production, begin COM-C4A, or complete any manual distribution gate.

---

## 2026-08-17 — Group Settings at the first level and cap navigation depth at two

Context: The Settings root put eight unrelated destinations into one unlabeled section — budget
domain configuration, system integration, an AI feature switch, and the subscription entry — while
only the privacy group carried a header and footer. Readers got no grouping context, VoiceOver users
got none at all, and the three pages that together decide the spendable amount (budget, savings
goal, fixed expenses) read as unrelated siblings. App language was also reachable only through the
"Appearance and skins" row, which no reader would search for it under.

Navigation depth had drifted without a rule. Three third-level paths already existed and none was a
deliberate choice: appearance to a pushed language picker, fixed expenses to a rule editor, and the
AI page to the Pro screen.

Decision: Group the Settings root into labeled sections — Budget, Reminders and Intelligence,
Subscription, General, Privacy, About — instead of adding a navigation level. Promote app language
to its own first-level destination under General and render its picker inline.

Cap normal navigation at two levels. A third level is reserved for exactly two cases: editing one
instance drawn from a list (a fixed-expense rule, and later categories, accounts, or templates), and
documents that stand alone (subscription terms, privacy policy, licenses). Grouping never justifies
a third level, because it charges every visit an extra tap and hides the destination.

Growth is absorbed by first-level sections and by splitting a page whose *concerns* diverge — not by
page length. `BudgetSettingsView` stays whole at roughly 375 lines because currency, cycle start day,
and amounts commit through one save action, and splitting it would break that atomic save.
`ReminderSettingsView` stays whole because in-app reminders and system notifications are two channels
of one concern.

Consequences: Every destination, accessibility identifier, and second-level page body is unchanged,
so this is a grouping and ordering change plus one promoted language entry. Language moves out of
appearance, which changes the path in `testAppLanguageChangesImmediatelyWithoutRelaunching`. Four new
group-header strings enter both catalogs. Adding a future third level now requires justifying it
against the two reserved cases above.

---

## 2026-08-20 — Preserve exact money and make recovery the COM-C4A delta

Context: App Store Connect accepted 0.9.8 (9), no tester/review/distribution action followed, and
the owner explicitly started COM-C4A-01. The repository already has four versioned SwiftData
schemas and exact minor-unit money; the v1.4 migration requirement therefore needed a source audit
before any implementation.

Decision: Detailed ownership lives in DEC-COM-025 and
`Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md`. V1–V4 authoritative amounts remain exact
`Int64` minor units. C4A-02 may add only the proven recovery delta: pre-open store/sidecar backup,
an explicit durable and idempotent migration journal, post-open integrity validation, fail-closed
restore/anomaly handling, and explicit currency ownership for the rebuildable merchant aggregate.

Consequences: No C4A-01 source/schema change or destructive rewrite is justified. At this
decision's time, C4A-02 and C4A-03 were blocked until the prerequisite review, green CI, and
merge; C4A-02 subsequently closed and C4A-03 is now implementation complete pending its own
review. No failed conversion may become zero, and no later COM or release authority is implied.

---

## 2026-08-20 — Keep C4A-02 recovery outside historical money schemas

Context: C4A-01 passed independent review, green CI, and merged through PR #51 as `bcd56a3`.
C4A-02 now implements the approved recovery delta without changing a V1–V4 authoritative amount.

Decision: Detailed ownership lives in DEC-COM-026. Schema V5 is a companion-only merchant
currency record; a pre-open app-owned journal/manifest surrounds SwiftData opening, and an
integrity failure restores the checksum-verified original only after the container has been
released. Merchant repair is deliberately limited to its rebuildable total and currency context.

Consequences: Reviewed head `9d2171d` passed GitHub Actions run `32375823770`; PR #53 merged
C4A-02 as `c905415` on 2026-08-20. C4A-02 is Done; the owner later started C4A-03's limited
recovery/currency matrix, pending implementation and independent review. The recovery envelope
creates no user-visible behavior, no network path, and
no distribution authority. On 2026-08-20 the owner accepted the current retry-only recovery UI: an unrecoverable
store without a trusted backup requires app-data deletion or reinstall. Any in-app destructive
reset needs a separate C4A-03 decision and evidence.

---

## 2026-08-20 — Bound persisted budget values and deterministically test interrupted restore

Context: The owner started C4A-03 after C4A-02 merged. The recovery/currency matrix needed to
prove both the preexisting signed-derived-value boundary and recovery behavior if restoration
fails after the live artifact has been removed.

Decision: Detailed ownership is DEC-COM-027. `BudgetPlan` and `CategoryBudget` persistence now
share the inventory's inclusive `Money.maximumMinorUnits` single-entry ceiling. Historical zero
`SavingsGoal` targets remain readable only in the migration inventory; source-ledger contracts are
unchanged. Derived signed insight aggregates remain valid throughout the existing `Int64` storage
range because the single-entry ceiling intentionally leaves aggregation headroom. An internal
default-no-op restore-copy callback supplies deterministic test-only interruption; production
behavior, schema hashes, recovery UI, and authority do not change.

Consequences: The corrected focused C4A-03 recovery/currency suite passed 20 tests with no
failures. This is implementation evidence only: full validation, independent review, hosted green
CI, and merge remain required. No network, StoreKit, iCloud, release, or distribution authority is
added.

---

## 2026-08-21 — Close COM-C4A after the recovery and currency matrix

Context: C4A-03 passed independent review and every step of GitHub Actions run `32406654986` at
reviewed head `138c240`; PR #55 merged it to `main` as `77292c6`.

Decision: Detailed closeout evidence is appended to DEC-COM-027. C4A-01 through C4A-03 are Done,
so COM-C4A is closed. The accepted retry-only/reinstall recovery boundary remains unchanged.

Consequences: C4B is not started and remains blocked pending an accepted CloudKit architecture
and explicit owner instruction. This closeout adds no iCloud, network, StoreKit, schema, reset UI,
release, or distribution authority.

---

## 2026-08-21 — Propose, but do not yet accept, the Free iCloud sync architecture

Context: The owner explicitly started C4B-01 design after COM-C4A closed. The existing SwiftData
store's URL-backed `ModelConfiguration` calls rely on the SDK's `.automatic` CloudKit default, so
adding an iCloud entitlement later could accidentally select managed mirroring.

Decision: Detailed candidate ownership is DEC-COM-028. The proposal is default-off Free sync through
custom versioned `CKSyncEngine` records in one private custom zone, with primary local store
configurations explicitly pinned to `.none` before any entitlement/import. The candidate is not
Accepted and C4B-02/C4B-03 remain blocked.

Consequences: No CloudKit container, entitlement, request, schema, SwiftData migration, deployment,
or distribution authority is granted. A static gate will reject a future CloudKit import/entitlement
unless the primary local store is explicitly non-mirrored. Remote facts would enter durable staging
and be applied through `DataActor`; local writes/outbox creation would remain transactional.

---

## 2026-08-21 — Accept C4B-01 architecture and freeze C4B-02 prerequisites

Context: The owner accepted the independently reviewed C4B-01 result. Reviewed head `093535f`
passed GitHub Actions run `32434148439`; PR #57 merged to `main` as `90a1e66`.

Decision: DEC-COM-028 is Accepted. The C4B-02 prerequisite contract pins the existing recurring
occurrence-key grammar, revision-1/no-parent genesis, exact digest ancestry, durable no-winner
quarantine, the exact future container/disclosure inputs, and repository-wide explicit
`cloudKitDatabase: .none`/centralized `ModelContainer` gate. Detailed wording remains in the COM
decision and `ICLOUD_SYNC_CONTRACT.md`.

Consequences: C4B-01 is Done. This closeout and maintenance step creates no container, entitlement,
request, schema, deployment, or distribution authority. C4B-02 runtime implementation remains
blocked until the prerequisite change passes review/CI/merge and the owner explicitly starts it;
C4B-03 retains physical-device, conflict-resolution, deletion, and Dashboard evidence ownership.

---

## 2026-08-21 — Implement the local-authority C4B-02 custom-record runtime

Context: C4B-02P passed independent review and GitHub Actions run `32454490080`, then merged
through PR #58 as `6f5fded`. The owner explicitly started C4B-02.

Decision: Detailed ownership is DEC-COM-029. Schema V6 contains only non-authoritative custom-sync
metadata; all primary SwiftData configurations remain `.none`. A default-off Settings consent can
start the private-database custom-record adapter, while local fact plus outbox/tombstone is one
transaction and remote records are inbox-first, validated, and topologically applied by `DataActor`.
Conflict, malformed input, account change, encrypted-key reset, quota, network, and service failure
never select a financial winner or block local budgeting.

Consequences: C4B-02 implementation is complete pending independent review, hosted CI, and merge.
No iCloud entitlement, provisioned container, Dashboard deployment, verified CloudKit request,
physical multi-device convergence, cloud-wide deletion, or distribution authority is added.
C4B-03 retains those operational and release gates.

---

## 2026-08-21 — Isolate the strict local Dashboard benchmark from suite contention

Context: C4B-02's first full validation passed the Release build and all functional/UI assertions,
but its strict 500 ms local Dashboard benchmark ran concurrently with 27 Swift Testing suites and
was the sole non-pass. The same implementation passed the focused Phase 10 suite and 10/10
isolated benchmark iterations.

Decision: Detailed verification ownership is DEC-COM-030. Local `Scripts/validate.sh` executes the
wall-clock test once with parallel testing disabled, then skips only the duplicate concurrent
invocation in its full correctness/coverage run. Hosted CI's existing wall-clock skip is unchanged.

Consequences: The 500 ms limit remains intact and must pass independently; correctness, UI, and
coverage still run in full. This changes validation scheduling only and grants no CloudKit,
deployment, or release authority.

---

## 2026-08-21 — Harden C4B-02 destructive pauses and remote application

Context: Independent review of PR #59 found that destructive `zoneNotFound` CKErrors could enter a
retryable state, delayed callbacks could overwrite an existing sticky pause, and several remote
application edge cases did not match the accepted contract.

Decision: Detailed ownership is DEC-COM-031. All trust-boundary pauses are sticky, destructive
CloudKit errors cancel the engine, recurrence identity uses one formatter, invalid allocations and
divergent occurrence claims quarantine, and parent-owned upsert envelopes require the parent key.
The current bilingual Delete All surface now states that it deletes local data only and leaves
cloud-wide deletion/reimport to C4B-03.

Consequences: PR #59 remains C4B-02 implementation pending final re-review and hosted green CI.
No entitlement, live container, cloud deletion, conflict-resolution UI, or release authority is
added.

---

## 2026-08-21 — Close C4B-02 after reviewed merge

Context: Reviewed remediation head `0024507` passed GitHub Actions run `32490174014`; PR #59 then
merged that exact C4B-02 source to `main` as `211dff2`.

Decision: Detailed closeout evidence is appended to DEC-COM-031. C4B-02 is Done. C4B-03 remains
blocked until this documentation closeout passes review/CI/merge; the owner has explicitly
authorized formal C4B-03 entry only after that condition is met.

Consequences: The merged custom-record runtime remains default-off, local-authority, and source-
only without an iCloud entitlement or provisioned environment. No Dashboard deployment, verified
CloudKit request, physical multi-device claim, conflict-resolution UX, cloud-wide deletion,
Archive, upload, tester, or distribution authority is inferred.

---

## 2026-08-22 — Enter C4B-03 with explicit conflict, deletion, and environment boundaries

Context: PR #60 merged the reviewed C4B-02 closeout as `7138a9c` after green GitHub Actions run
`32494429474`; the owner then formally entered C4B-03.

Decision: Detailed ownership is DEC-COM-032. C4B-03 uses separate exact Development and Production
entitlement files for one private CloudKit container. Unresolved records never receive an automatic
winner; the user may explicitly keep the local fact or accept the iCloud candidate. A separately
confirmed cloud deletion removes the entire app-owned custom zone while keeping local facts, and a
durable retained-copy marker requires confirmed reimport after local-only deletion. Sticky account,
key-reset, or zone-loss pauses can be cleared only through the explicit recovery surface.

Consequences: Signed local build/archive evidence proves configuration selection only. It does not
prove a real CloudKit request, Dashboard schema/deployment, physical multi-device convergence,
distribution signing, Production schema deployment, or release readiness. Those remain C4B-03
gates; Production schema deployment requires explicit owner acceptance.

---

## 2026-08-22 — Make CloudKit background delivery and test-store isolation explicit

Context: Adding the exact C4B-03 entitlement made six legacy migration fixtures expose their
implicit SwiftData `.automatic` default, and the first generated app plist did not contain the
remote-notification background mode despite a build-setting-only attempt.

Decision: Detailed ownership is DEC-COM-033. MindBudget uses a checked source plist containing
exactly `UIBackgroundModes = [remote-notification]`; both configurations reference it while their
separate entitlement files keep Development and Production isolated. Every test-store
`ModelConfiguration`, like production, must explicitly choose `cloudKitDatabase: .none`.

Consequences: The corrected focused regression passed 45/45 and the complete local validation
passed 456 unit tests, 17 UI tests, strict Dashboard performance, Release compilation, static
contracts, and coverage. These are local implementation facts only; real CloudKit/Dashboard,
physical multi-device, distribution, Production deployment, review, CI, and merge remain open.

---

## 2026-08-22 — Require an explicit compile-time opt-in for destructive CloudKit evidence

Context: The owner explicitly authorized one real test that deletes the fixed private Development
zone. The first physical build exposed a test-isolation compile error, and two subsequent
function-level Swift Testing filters produced green zero-test results; none was accepted.

Decision: Detailed ownership is DEC-COM-034. The destructive test is enabled only by the explicit
`MINDBUDGET_PHYSICAL_CLOUDKIT_TESTS` Swift compilation condition and must report a nonzero exact
test total. Ordinary simulator, CI, and physical test runs keep it disabled.

Consequences: The final physical Development run passed 33/33, including real custom-zone create,
encrypted send/fetch, disable, confirmed reimport, whole-zone delete, and local-expense
preservation. This does not prove Dashboard, offline/quota/account, background push, multi-device,
distribution signing, Production deployment, review, CI, merge, or release.

---

## 2026-08-22 — Fail closed at the CloudKit lineage revision ceiling

Context: Final C4B-03 source review found unchecked child-revision arithmetic in local staging,
remote acceptance, and explicit conflict resolution.

Decision: Detailed ownership is DEC-COM-035. A single throwing helper now advances revision
lineage and rejects negative ancestry or any attempt to advance `Int64.max`.

Consequences: Exhausted or malformed private ancestry cannot crash or wrap the process. The
exact-head CloudSync suite passed 33 deterministic cases with the destructive physical case
explicitly skipped. Full exact-head UI/coverage, external lifecycle gates, review, hosted CI, and
merge remain open.

---

## 2026-08-22 — Stop the different-account two-device evidence attempt without claiming a pass

Context: Two physical iPhones were paired, signed, placed in Developer Mode, and prepared with a
compile-time opt-in convergence harness. Non-content one-way fingerprints then proved that the
devices use different iCloud Apple Accounts, so their private CloudKit databases cannot exchange
the test record.

Decision: Detailed ownership is DEC-COM-036. The owner declined an account switch and stopped the
attempt. Keep the harness for future evidence, disclose the gap, and do not treat the run as a
product failure, a pass, or a release waiver.

Consequences: A subsequent 33/33 cleanup run proves the fixed Development zone is clean, not that
two devices converged. C4B-03 remains In Progress with the other external, review, hosted-CI, and
merge gates open.

---

## 2026-08-22 — Preserve retained-iCloud authority after local Delete All

Context: Independent review of PR #61 found that local Delete All preserved the separate retained-
cloud preference but overwrote `AppSession` presentation with a marker-free `.disabled` snapshot,
temporarily hiding the cloud-delete action and reimport disclosure.

Decision: Detailed ownership is DEC-COM-037. The sync service now republishes the disabled local
control state combined with the durable retained-copy marker immediately after local deletion.
Settings uses that one snapshot for reimport confirmation, cloud-delete visibility, and closed
reason-specific retry guidance. Incomplete cloud conflict candidates remain quarantined without an
unsafe resolution action, and whole-zone absence—not pre-upload of every tombstone—is the final
cloud-deletion postcondition.

Consequences: The same-session Delete All path cannot silently hide a retained cloud copy or issue
an unconfirmed Enable. Focused CloudSync/Phase 6 tests pass 52 cases with only the three physical-
only probes skipped. C4B-03 remains In Progress pending rereview, hosted CI, and its documented
external lifecycle/release gates.

---

## 2026-08-22 — Defer same-account two-device evidence without claiming closure

Context: Reviewed C4B-03 product head `f49de94` passed GitHub Actions run `32571676058`, and PR #61
merged it to `main` as `0f749ce`. The prepared physical devices use different iCloud Apple
Accounts, while a same-account arrangement is not currently available.

Decision: Detailed ownership is DEC-COM-038. The owner temporarily defers the same-account
convergence/conflict rerun. The harness and evidence requirement remain; the deferral is not a pass,
product failure, permanent waiver, or release authorization.

Consequences: Product review/CI/merge is closed, but C4B-03 and COM-C4B remain In Progress. C4C and
distribution remain blocked while the other physical and release evidence gates stay open.
