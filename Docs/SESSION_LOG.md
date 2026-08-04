# SESSION_LOG

## 2026-08-02 — Session 1 — Phase 0

Goal: Initialize the repository, Xcode targets, project constraints, and durable agent memory.

Files changed: `.gitignore`, `README.md`, `AGENTS.md`, `MindBudget.xcodeproj`,
`MindBudget/App`, `MindBudget/Resources`, placeholder tests, and all files under `Docs/`.

What was completed: The workspace and installed simulator environment were inspected;
the repository and Phase 0 project skeleton were created. The initial missing
Preview Content path was removed, the simulator was returned to a clean state,
and the full build/test acceptance sequence passed.

What was NOT completed: Phase 1 models and persistence were intentionally not started.

Build result: pass — iPhone 17 Pro, iOS 26.5

Test result: pass — 2 tests, 0 failures, 0 skipped

Known issues: A machine whose active developer directory points to Command Line
Tools must select its installed Xcode or set `DEVELOPER_DIR` before validation.

Next suggested task: Begin Phase 1 with `Money`, enums, VersionedSchema models, and `DataActor`.

## 2026-08-02 — Session 2 — Phase 0 review remediation

Goal: Address accepted PR feedback without changing the v3.1 capability-flag contract.

Files changed: feature flags, Xcode project/configuration, asset catalog, scripts,
GitHub Actions workflow, smoke tests, repository licensing, and project memory.

What was completed: Capability/user-setting semantics were clarified; V1 became
iPhone-only; build identity became locally overridable; CI and meaningful localization
smoke tests were added; Package.resolved is no longer ignored; project-generator
migration triggers and proprietary repository terms were recorded. The hosted CI
simulator is created explicitly, and the money-path check uses macOS system tools.

What was NOT completed: A real App Icon and iOS 17 hosted runtime test remain deferred.

Build result: pass — iPhone 17 Pro, iOS 26.5

Test result: pass — 2 tests, 0 failures, 0 skipped

GitHub Actions result: pass — Xcode 16.4, iPhone 16 simulator, iOS 18.5

Known issues: Current GitHub-hosted macOS images do not include an iOS 17 runtime.

Next suggested task: Review and merge PR #2, then begin Phase 1 on a new branch.

## 2026-08-03 — Session 4 — Phase 1 data models and local persistence

Goal: Implement the complete V1 data schema, exact money representation, actor-safe
local storage, settings persistence, deterministic sample data, and Phase 1 tests.

Files changed: all files under `MindBudget/Models`, Phase 1 files under
`MindBudget/Data` and `MindBudget/Services`, app environment/container setup, unit
tests, the Xcode project, validation script, and project memory documents.

What was completed: Added `SchemaV1` and its migration plan; nine SwiftData models;
typed enums and Sendable projections; exact minor-unit Money with a bundled currency
exponent table; `DataActor` CRUD/invariant boundaries; restart-safe `DataController`;
validated `SettingsStore`, bucket overrides, quiet hours, and rule configuration;
four sample scenarios; wishlist state enforcement; cascade and weak-link behavior;
and reminder scope/risk/response persistence. Category thresholds use exact basis
points. The macOS Bash 3.2 empty-array failure in local validation was also fixed.

What was NOT completed: Budget-cycle generation and all budget/impact calculations
remain Phase 2. No Phase 3 UI was started.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 21 Swift Testing tests and 2 UI tests, 0 failures

Known issues: A real App Icon and real iOS 17 runtime validation remain deferred to
release preparation. Hosted CI for the Phase 1 branch has not run until changes are
published.

Next suggested task: Review and merge the Phase 1 pull request, then begin Phase 2
with pure budget-cycle and budget-engine types that consume the new projections.

## 2026-08-02 — Session 3 — Phase 0 final review hardening

Goal: Close the final PR review gaps and align hosted validation with the declared
Xcode 26.6 development environment.

Files changed: source policy and validation scripts, GitHub Actions, localization
smoke tests, shared configuration guidance, capability-gate documentation, and
project memory.

What was completed: The floating-point guard now scans the entire app source tree
except the single documented transport adapter. CI pins checkout, verifies Xcode
26.6+, checks the app target's deployment value, dynamically selects a compatible
iOS 26 runtime and iPhone type, validates the final bundle identifier, and uses
build-for-testing/test-without-building. English and Simplified Chinese rendered
labels are covered. Raw FeatureFlags are prohibited at Phase 7/8 call sites in favor
of tested centralized gates.

What was NOT completed: A real App Icon and real iOS 17 runtime validation remain
deferred to later release preparation.

Local build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Local test result: pass — 1 unit test and 2 UI tests, 0 failures

GitHub Actions result: pass — Xcode 26.6, iOS 26.5, 6m44s; all tests passed on
their first iteration. Hosted CI retains one assertion-preserving retry for a
confirmed cold-simulator launch timeout.

Known issues: GitHub-hosted images still do not provide the required iOS 17 runtime.

Next suggested task: Review and merge PR #2, then begin Phase 1 on a new branch.

## 2026-08-03 — Session 5 — Phase 1 review remediation

Goal: Close the Phase 1 review findings around low-value currencies, corrupt stored
values, actor consistency, merchant aggregation, startup recovery, and test gaps.

Files changed: money/enums/models, `DataActor`, `DataController`, `SettingsStore`, app
bootstrap and localizations, Phase 1 tests, and project memory documents.

What was completed: The entry limit is now currency-neutral; persisted currencies and
enum raw values throw recoverable projection errors; one actor is reused per controller;
sample replacement uses one save with rollback; accounting checks use bounded fetches;
merchant aggregates follow normalized expense creation/deletion; settings configuration
is cached; interruption limits are clamped at the write boundary; and store initialization
failure presents a localized retry path without deleting user data. Tests now cover the
reviewed invariants and corruption paths.

What was NOT completed: Full raw-store export and destructive store rebuilding remain
future recovery features; the current recovery path intentionally supports retry only.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 32 Swift Testing tests and 2 localized UI tests, 0 failures

Known issues: A real App Icon and real iOS 17 runtime validation remain deferred to
release preparation.

Next suggested task: Review and merge PR #3, then begin Phase 2.

## 2026-08-03 — Session 6 — Phase 1 schema closeout

Goal: Resolve the final Phase 1 review around merchant normalization, local aggregate
semantics, Spotlight consent, and the proposed budget-plan cross-field invariant.

Files changed: `Expense`, `DataActor`, persistence tests, Phase 1 decision/privacy/test
documents, the task backlog, and the authoritative development document.

What was completed: Added optional `Expense.normalizedMerchantName` to `SchemaV1`,
generated it atomically at the write boundary, and replaced the in-memory all-expense
filter with a SwiftData predicate. Documented that local `Merchant` rows aggregate all
matching expenses while future merchant-name indexing separately requires the global
Spotlight gate, the merchant-name opt-in, and an eligible matching expense. Added a
regression test proving the normalized key survives store reopening and a contract test
proving overcommitted budget plans remain valid Phase 2 input. Phase 3 now tracks the
dismissible amount-reasonableness warning as a soft UI concern.

What was NOT completed: The Phase 8A indexing service and its centralized capability
gate do not exist yet. No hard `fixedExpenses + savingGoal <= totalBudget` validation
was added because the authoritative formula deliberately supports overcommitted plans.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 33 Swift Testing tests and 2 localized UI tests, 0 failures

Known issues: A real App Icon and real iOS 17 runtime validation remain deferred to
release preparation.

Next suggested task: Push this closeout to PR #3, review CI, merge, then begin Phase 2.

## 2026-08-03 — Session 7 — Phase 2 budget engine and cycle math

Goal: Implement the deterministic budget calculation layer, calendar-safe cycle
boundaries, lazy future-plan generation, and currency formatting without starting
Phase 3 UI work.

Files changed: budget/cycle/formatting services, Sendable data projections, `DataActor`,
Phase 2 tests and project wiring, decision/task/test/memory/changelog documents, and the
authoritative development contract.

What was completed: Added configured and unconfigured budget snapshots, authoritative
fixed/saving reservation formulas, safe daily spend, purchase impact, category risk,
checked overflow and currency validation using only `Int64`/`Decimal`. Added natural and
custom budget cycles, day-31 clamping, recorded-time-zone hour extraction, immutable
history, contiguous transition cycles after future setting changes, overlap/identity
guards, and atomic lazy plan creation through `DataActor`. Added locale-aware formatting
for fractional and zero-exponent currencies and reconciled the service contract with
Sendable summaries and optional unconfigured metrics.

What was NOT completed: Phase 3 onboarding, Dashboard, expense-entry UI, and presentation
formatting are intentionally untouched. Cooling-off countdown behavior remains Phase 4;
Phase 2 covers the underlying DST-safe calendar boundaries only.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 62 Swift Testing tests and 2 localized UI tests, 0 failures

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths

Known issues: A real App Icon and real iOS 17 runtime validation remain deferred to
release preparation.

Next suggested task: Commit and push the Phase 2 branch, open it for review, then begin
Phase 3 only after merge.

## 2026-08-03 — Session 8 — Phase 2 review remediation

Goal: Address PR #4 review findings before Phase 3 creates consumers of the budget
snapshot, impact, cycle-transition, and formatting contracts.

Files changed: budget/cycle/formatting services, `DataActor` coverage projections,
Phase 2 tests, AI prompt contract, project decisions/memory/test plan/changelog, and the
authoritative development document.

What was completed: Replaced the Boolean-plus-Optional snapshot with a two-state enum and
a nonoptional configured payload; restricted impact calculation to configured snapshots;
rejected reference dates outside `[cycleStart, cycleEnd)`; made free-budget ratio and
days-consumed metrics exist only for discretionary spending with positive denominators;
and migrated currency output from per-call `NumberFormatter` construction to stateless
`Decimal.FormatStyle.Currency` with explicit exponent precision. Future start-day changes
now return a transition-budget confirmation requirement instead of silently copying a
full monthly budget, while normal lazy generation is preflighted in memory, capped at 120
plans, and remains atomic. Generated typed drafts no longer repeat persistence fetches for
each prospective plan.

What was NOT completed: Phase 3 still needs to build the transition-budget confirmation
UI and switch on configured/unconfigured snapshots. No historical-summary API was added;
Phase 5 must use cycle aggregates rather than current-cycle safe-daily calculations.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 65 Swift Testing tests and 2 localized UI tests, 0 failures

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths

Known issues: A real App Icon and real iOS 17 runtime validation remain deferred to
release preparation.

Next suggested task: Push the remediation commit to PR #4, wait for CI, review, and merge
before beginning Phase 3.

## 2026-08-03 — Session 9 — Phase 2 transition-budget propagation fix

Goal: Close the final PR #4 finding that a reduced, user-confirmed transition budget
could silently become the recurring amount for complete cycles on the new cadence.

Files changed: budget-cycle calculation, `DataActor` coverage projections, date-boundary
tests, project decision/memory/test/changelog documents, and the authoritative development
contract.

What was completed: Replaced the transition Boolean with an explicit confirmation reason
that distinguishes the shortened transition from its first complete successor. A
transition requirement now exposes both intervals so Phase 3 can collect two independent
budgets in one flow. If only the transition plan is saved, `DataActor` returns
`.firstRegularPlanRequired` and writes nothing automatically. Automatic roll-forward
resumes only after the first complete plan is explicitly saved. Regression coverage uses
300,000 for the original and recurring complete cycles and 210,000 for the transition,
then proves later complete cycles inherit only 300,000.

What was NOT completed: Phase 3 still needs to implement the combined confirmation UI.
No GitHub review thread was replied to or resolved.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 66 Swift Testing tests and 2 localized UI tests, 0 failures

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths

Known issues: A real App Icon and real iOS 17 runtime validation remain deferred to
release preparation.

Next suggested task: Push the fix to PR #4, wait for CI, review, and merge before Phase 3.

## 2026-08-03 — Session 10 — Phase 3 core UI and manual expense tracking

Goal: Deliver the complete Phase 3 iPhone flow from first launch through budget setup,
Dashboard understanding, manual expense creation, and expense history management without
starting Phase 4 emotion/wishlist behavior or Phase 5 insights.

Files changed: app routing/environment, Phase 3 onboarding/Dashboard/add/list/detail/
settings/shared views and view models, expense projections and `DataActor` write APIs,
English/Simplified Chinese strings, unit/UI tests, project wiring, and project memory.

What was completed: Replaced the bootstrap screen with the five-tab app shell, localized
onboarding, accounting-currency and cycle-day setup, configured/unconfigured Dashboard
cards, neutral overspend presentation, keyboard-accessible quick expense entry, inline
selected-date budget impact, recent categories, merchant suggestions, planned flag, and a
dismissible amount reasonableness check. Added searchable/filterable expense history,
detail, edit, swipe/delete confirmation, error/empty states, and honest placeholders for
future Insights and Wishlist phases. Expense updates now preserve the full projection and
rebuild merchant aggregates through `DataActor`. Transition and first-regular budgets save
atomically with independent values. Locale parsing validates localized digits/grouping and
rejects silent minor-unit rounding. App state refreshes after successful writes and when
returning to the foreground.

What was NOT completed: Emotion/reason fields and wishlist alternatives remain Phase 4;
reminder sheets and generated insights remain Phase 5; export, destructive all-data reset,
and advanced settings remain Phase 6+. No App Intents, Spotlight, or AI work was pulled
forward. Real-device VoiceOver/AX5 and iOS 17 runtime smoke checks remain release-manual
items, although Phase 3 controls expose localized accessibility labels and scalable money
text.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 75 Swift Testing tests and 3 UI tests, 0 failures. UI coverage includes
forced English and Simplified Chinese rendering plus onboarding → budget setup → Dashboard
→ quick expense → expense list.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths

Known issues: A real App Icon, iOS 17 runtime validation, and physical-device VoiceOver/
AX5 inspection remain deferred to release preparation. The simulator emitted a harmless
post-test diagnostic warning because its unqualified `xcrun` could not locate `simctl`;
the build and all test suites completed successfully before that diagnostic collection.

Next suggested task: Push the Phase 3 branch, open a pull request, and review CI before
beginning Phase 4.

## 2026-08-03 — Session 11 — Phase 3 PR review remediation

Goal: Resolve PR #5 findings around DatePicker-driven persistence, raw-note projection
scope, Release test hooks, truthful budget context, typed save errors, input precision,
and targeted detail loading without starting Phase 4.

Files changed: app environment, expense/data projections, `DataActor`, add/list/detail
views and view models, localized strings, date/data/Phase 3 tests, decisions, task privacy
acceptance, AI prompt contract, project memory, test plan, changelog, and this session log.

What was completed: Added a read-only coverage projection that can preview copied future
plans without saving and changed the date picker to a cancellable debounced read. The
mutating coverage path now saves only when drafts actually need insertion and remains the
explicit pre-save/Dashboard lifecycle entry. Expense forms distinguish configured,
unconfigured, historical, transition, first-regular, and unavailable budget contexts;
pending budget confirmation does not block factual expense capture or invent an impact.
Raw notes were removed from `ExpenseSummary`, placed behind targeted `ExpenseDetail`
fetches, and searched inside `DataActor` with only matching IDs returned. The UI-test reset
hook is Debug-only and a Release binary scan proves its launch argument is absent. Save
errors preserve accounting-currency mismatch, corrupt data, and generation-limit meaning;
extra fraction digits have a dedicated message; grouping rules are cached per locale; edit
refresh fetches one detail. Transition tests now also cover currency and identity conflicts.

What was NOT completed: No Phase 4 fields or behavior were added. No fixed pre-budget
amount heuristic was invented because an unconfigured user has no currency-neutral personal
baseline; the configured dismissible check remains relative to the confirmed period budget.
PR #5 contains no GitHub review thread to reply to or resolve, so the externally supplied
review remains represented by code, tests, and decision records only.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5; Release simulator build and
binary test-hook scan also pass

Test result: pass — 80 Swift Testing tests and 3 UI tests, 0 failures

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths

Known issues: A real App Icon, iOS 17 runtime validation, and physical-device VoiceOver/
AX5 inspection remain deferred to release preparation. The simulator may emit its known
post-test diagnostic warning after all suites have already succeeded.

Next suggested task: Wait for PR #5 CI, continue review, and merge only after approval.

## 2026-08-03 — Session 12 — Phase 4 emotion context, wishlist, and cooling-off

Goal: Deliver optional purchase-context tagging, a complete local wishlist, and a
DST-safe cooling-off lifecycle while keeping Phase 5 reminder rules and Phase 6 local
notifications out of scope.

Files changed: expense and wishlist projections/data transfers, `DataActor` lifecycle
writes, elapsed-hour countdown service, add-expense/Dashboard/shared/wishlist SwiftUI
features, English/Simplified Chinese strings, unit/UI tests, project wiring, and the
project memory, decisions, privacy, copy, test, task, and changelog documents.

What was completed: Added optional emotion and purchase-reason context to manual expenses
with neutral, approved bilingual labels and no diagnosis or judgment. Replaced the
Wishlist placeholder with add/edit/detail/list/history flows, optional price and private
notes, deterministic current-budget impact, direct seeding from a potential expense, and
an atomic planned-expense conversion. Cooling-off supports 24-hour, 72-hour, and custom
elapsed-hour periods, one active period per wish, automatic ready-for-review progression,
repeat rounds, explicit purchase/skip/archive decisions, and history that never invents
an outcome. Dashboard surfaces pending cooling/review items. Raw wish notes remain behind
the targeted `WishItemDetail` boundary, and the AI contract forbids that projection from
entering future redaction or generation APIs.

What was NOT completed: Phase 5 rule evaluation, throttled interventions, and generated
insights remain untouched. Phase 6 owns notification permission and local notification
scheduling; the Phase 4 UI explicitly states that its countdown is local and schedules no
notification. Phase 7+ Siri, Spotlight, and AI integrations remain out of scope.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 91 Swift Testing tests and 4 UI tests, 0 failures. New coverage
includes optional context persistence, note projection boundaries, expense-to-wishlist
seeding, DST countdown behavior, atomic lifecycle and rollback invariants, deterministic
budget impact, approved bilingual copy, Dashboard pending items, and onboarding →
Wishlist → cooling-off end-to-end interaction.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`Localizable.xcstrings` parses successfully; `git diff --check` is clean.

Known issues: A real App Icon, iOS 17 runtime validation, and physical-device VoiceOver/
AX5 inspection remain deferred to release preparation. The simulator emitted the known
post-test diagnostic warning because its unqualified `xcrun` could not locate `simctl`;
the build and every test suite had already completed successfully.

Next suggested task: Commit the Phase 4 branch, then push and open a pull request when the
user requests review.

## 2026-08-03 — Session 13 — Phase 4 PR review remediation

Goal: Resolve the Phase 4 review findings around outcome timing, recoverable wishlist
errors, fixed cooling-off preview time, locale-aware countdown copy, and projection/privacy
semantics without starting Phase 5.

Files changed: Schema V1 cooling-off model and value transfers, `DataActor` lifecycle
validation, wishlist detail/cooling-off views, countdown localization service, bilingual
strings, Phase 4/data tests, decisions, project memory, task/privacy/test contracts,
changelog, and this session log.

What was completed: Added optional `outcomeRecordedAt` while preserving `completedAt` as
the actual expiry/cancellation time; outcome and its recorded time now form an atomic
persistence pair. Expiry still invents no outcome, and a decision made days later no longer
loses either timestamp. Wishlist start/action failures retain state-changed, corrupt-data,
and persistence meanings instead of collapsing to one Boolean. Cooling-off preview and
save share one fixed start instant. Countdown copy follows the SwiftUI environment locale
through an explicitly selected localization bundle. The expense/wishlist projection
asymmetry is now intentional and documented, and raw cooling-off timestamps are prohibited
from future model contexts.

What was NOT completed: No Phase 5 insight or rule consumes `outcomeRecordedAt` yet; the
task records that deterministic attribution must be implemented there. Notification
scheduling remains Phase 6, and no Phase 7+ AI or system integration work was pulled
forward. PR #6 has no GitHub review conversation or review thread to resolve, so the
externally supplied review is represented by code, tests, and decision records only.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 95 Swift Testing tests and 4 UI tests, 0 failures. New coverage proves
the outcome/timestamp invariant, preserves completion time across delayed decisions,
distinguishes recoverable Phase 4 errors, and renders English/Chinese countdown text from
the requested locale.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`Localizable.xcstrings` parses successfully; `git diff --check` is clean.

Known issues: A real App Icon, iOS 17 runtime validation, and physical-device VoiceOver/
AX5 inspection remain deferred to release preparation. The simulator emitted the known
post-test diagnostic warning because its unqualified `xcrun` could not locate `simctl`;
the build and all test suites completed successfully before diagnostic collection.

Next suggested task: Commit and push the Phase 4 review fix to PR #6, then wait for review
and CI before merging.

## 2026-08-03 — Session 14 — Phase 5 rules, check-ins, and insights

Goal: Deliver deterministic spending-pattern detection, independently throttled template
check-ins, and useful local insights without pulling Phase 6 notifications or Phase 7 model
generation into scope.

Files changed: deterministic detector/throttle/reminder services, typed insight and reminder
projections, `DataActor` persistence, manual expense and Insights/settings UI, router and
project wiring, English/Simplified Chinese strings, Phase 5 unit/integration/UI tests, and
the task, decision, copy, test, changelog, project-memory, and session documents.

What was completed: Implemented all eight approved rule families with checked minor-unit
math, exact threshold semantics, deterministic ordering, historical-cycle aggregation, and
cooling-off attribution through `outcomeRecordedAt`. Detection remains active when gentle
check-ins are disabled. Typed insights deduplicate by scope, preserve dismissal, and never
accept raw-note projections. Presentation applies scoped cooldowns, category threshold
re-crossing, response adaptation, daily caps, authorization, and quiet-hour deferral.
Manual expense entry shows at most one highest-priority sheet, records only actual
presentations, keeps Continue Purchase primary, and offers Wishlist as an alternative.
Localized soft/direct/minimal templates are the mandatory fallback, while the injected
enhancer seam contains no real AI call. Insights now provides seven-day/current-cycle
summaries, category/emotion/trend charts, dismissible pattern cards, and an informational
disclaimer. Settings expose the check-in toggle, tone, and zero-to-two daily interruption
limit.

What was NOT completed: Phase 6 still owns notification permission requests, delivery, and
scheduling; Phase 5 only calculates deferral decisions. Phase 7 still owns any real
Foundation Models enhancement and the allow-listed redaction boundary. No raw expense or
wishlist note was added to detector, reminder, or insight inputs.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 122 Swift Testing tests and 5 UI tests, 0 failures. Coverage includes
every rule family and boundary, 100-run determinism, throttle ordering and exceptions,
template validation/fallback, typed persistence, five sequential large-purchase flows, and
the Insights local-summary/empty-state/disclaimer UI path.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`Localizable.xcstrings` parses successfully; `git diff --check` is clean.

Known issues: A real App Icon, iOS 17 runtime validation, and physical-device VoiceOver/
AX5 inspection remain deferred to release preparation. Xcode emitted the known post-test
diagnostic warning because its unqualified diagnostic collector could not locate `simctl`;
the build and all test suites had already succeeded.

Next suggested task: Commit the Phase 5 branch, then push and open a pull request when the
user requests review.

## 2026-08-03 — Session 15 — Phase 5 PR review remediation

Goal: Resolve PR #7 review findings without changing the approved reminder actions or
pulling notification delivery and model generation into Phase 5.

Files changed: manual-expense reminder integration, rule configuration, detector and cycle
aggregate builder, reminder throttle policy, Insights aggregate call site, Phase 5/settings
tests, decisions, test plan, project memory, changelog, and this session log.

What was completed: Made reminder event creation and response updates best effort so neither
can reject an otherwise valid expense. Failed sheet-event creation now skips the advisory
surface and follows the normal save path; failed Continue Purchase response logging still
saves the expense. A live/injected writer boundary proves both failure modes. Daily cap
calculation now downgrades when the calendar cannot produce a day interval, and malformed
behavioral requests report `invalidRequest` rather than user opt-out. Late-night window and
count, safe-proceed buffer basis points, and the image-analysis minimum now belong to
validated rule configuration. Cooldown and negative-response constants are centralized in
`ReminderThrottlePolicy`. The image floor is independent from the large-purchase floor, the
unsafe decimal-zero fallback was removed, and aggregate overflow rejects the full build
instead of silently replacing a missing recent cycle with older history. Review confirmed
that the sheet already prevents swipe dismissal: Close retains the expense form, Wishlist
uses a seeded form and returns on cancellation, and Continue Purchase is the only expense-
saving action.

What was NOT completed: Notification scheduling remains Phase 6 and real Foundation Models
wording remains Phase 7. No action was written to GitHub review threads because PR #7 has no
conversation comments, submitted reviews, or inline threads; the supplied external review
is represented by code, tests, and decision records.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 129 Swift Testing tests and 5 UI tests, 0 failures. Phase 5 alone passes
34 tests, including reminder create/update failures, unavailable day bounds, invalid
requests, configurable safe/late thresholds, independent image floor, and aggregate
overflow rejection.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`Localizable.xcstrings` parses successfully; `git diff --check` is clean.

Known issues: A real App Icon, iOS 17 runtime validation, and physical-device VoiceOver/
AX5 inspection remain deferred to release preparation. Xcode emitted the known post-test
diagnostic warning because its unqualified diagnostic collector could not locate `simctl`;
the build and all test suites had already succeeded.

Next suggested task: Commit and push this remediation to PR #7, then wait for another review
and CI before merging.

## 2026-08-04 — Session 16 — Phase 6 notifications, CSV export, and privacy controls

Goal: Add explicit local notification consent and cooling-off delivery, a deliberate
expense-ledger CSV export, and reliable local-data deletion without pulling Phase 7 AI or
Phase 8 Siri/Spotlight indexing into scope.

Files changed: notification scheduling and system-center adapters, privacy deletion and
Spotlight cleanup services, CSV export DTO/encoder and share UI, `DataActor` export,
notification, and deletion paths, settings/cooling-off/wishlist/router integration,
bilingual strings, Phase 6 unit/integration and settings UI coverage, Xcode project wiring,
and the task, decision, privacy, copy, test, changelog, project-memory, and session documents.

What was completed: Notification authorization is requested only after an explicit settings
or cooling-off action; ordinary reconciliation only reads authorization. Stable per-plan
identifiers reconcile scheduled, delivered, stored, completed, cancelled, and deleted state,
while quiet hours defer delivery through the deterministic throttle. Lock-screen content is
sanitized and excludes amounts and notes. CSV export is an in-memory, expense-only ledger
with a stable schema, UTF-8 BOM, CRLF/RFC 4180 escaping, exact `Int64` minor-unit formatting,
raw merchant/note disclosure, and spreadsheet-formula neutralization. Privacy deletion uses
two confirmations and a visible staged state machine, then strictly cancels notifications,
clears app-owned Spotlight items, deletes all nine SwiftData model types, and resets app
preferences; any failed stage stops the sequence without claiming success. The settings UI
shows authorization state, quiet hours, export, and deletion controls in English and
Simplified Chinese.

What was NOT completed: Notification-tap routing, App Entities, merchant Spotlight indexing,
Siri, and onscreen awareness remain Phase 8 work behind their centralized capability gates.
Phase 7 still owns Ask fallback, allow-listed redaction, and any Foundation Models wording.
CSV is a human-readable expense ledger, not a full backup/restore format, and export never
runs automatically.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 139 Swift Testing tests and 6 UI tests, 0 failures. New coverage proves
authorization is never requested by background reconciliation, notification copy receives
no money or note data, quiet-hour delivery and exact cancellation, delivered-event
deduplication, CSV byte/escaping/formula/zero-exponent behavior, all-nine-model deletion,
ordered preference reset, and failure-stop semantics. The settings UI path verifies the
export and privacy controls after scrolling the full list.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`Localizable.xcstrings` compiles successfully; `git diff --check` is clean.

Known issues: A real App Icon, iOS 17 runtime validation, and physical-device notification,
VoiceOver, and AX5 inspection remain deferred to release preparation. Xcode emitted the
known post-test diagnostic warning because its unqualified diagnostic collector could not
locate `simctl`; the build and all test suites had already succeeded.

Next suggested task: Commit the Phase 6 branch, then push and open a pull request when the
user requests review.

## 2026-08-04 — Session 17 — Phase 6 privacy and notification review remediation

Goal: Close the Phase 6 privacy review by making deletion completion observable, preventing
one corrupt cooling-off record from disabling every valid reminder, and removing optional
fallbacks at the CSV and localized confirmation boundaries.

Files changed: privacy deletion verification, model-count projection, notification candidate
batching and app-session reconciliation, Settings integrity copy, explicit-locale deletion
confirmation, total UTF-8 export conversion, Phase 6 tests, localization, and the decision,
privacy, copy, test, changelog, task, project-memory, and session documents.

What was completed: Delete All now re-queries all nine Schema V1 model counts and withholds
preference reset/completion unless every count is zero. Notification reconciliation separates
invalid plan IDs from valid candidates, continues scheduling valid reminders, clears stale
identifiers for invalid records, and shows a localized Settings warning. CSV body conversion
uses total UTF-8 bytes, and the destructive confirmation word follows the active SwiftUI
locale. The existing export disclosure was confirmed to name merchant names and raw notes;
notification payloads were confirmed to contain the wishlist item name but no amount/note,
and quiet-hour deferral was confirmed to drive the actual system trigger.

What was NOT completed: Revision-wide notification reconciliation remains a nonblocking
performance optimization for a later phase; current no-op identifier updates do not open a
SwiftData transaction. Phase 7/8 scope remains unchanged.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 142 Swift Testing tests and 6 UI tests, 0 failures. Phase 6 targeted
coverage passes 13 tests, including injected incomplete deletion verification, corrupt-row
partial notification reconciliation, stale identifier clearing, and explicit-locale
confirmation copy.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`Localizable.xcstrings` parses and compiles successfully; `git diff --check` is clean.

Known issues: A real App Icon, iOS 17 runtime validation, and physical-device notification,
VoiceOver, and AX5 inspection remain deferred to release preparation. Xcode emitted the
known post-test diagnostic warning because its unqualified diagnostic collector could not
locate `simctl`; the build and all test suites had already succeeded.

Next suggested task: Commit and push this remediation to PR #8, then wait for review and CI.
