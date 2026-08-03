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
