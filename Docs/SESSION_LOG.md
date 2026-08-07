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

## 2026-08-04 — Session 18 — Preserve notification integrity state and plan explicit repair

Goal: Address the final Phase 6 review observation without auto-deleting an unreachable
orphan cooling-off record or conflating operation failure with known stored-data corruption.

Files changed: app-session notification state handling, Phase 6 notification tests, Phase 9
task memory, and the decision, test, changelog, project-memory, and session documents.

What was completed: A failed notification reconciliation now sets the operation-failure
state without erasing the last successfully observed data-integrity warning. The two states
can remain true together, and only a later successful reconciliation recomputes the warning.
The corrupt row remains stored. Phase 9 now owns an explicit localized repair action that
shows the affected count, requires confirmation, and never deletes records implicitly.

What was NOT completed: The repair action itself is intentionally not implemented during
Phase 6. Until Phase 9, Delete All remains the only whole-store removal path for an orphaned
cooling-off record.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 142 Swift Testing tests and 6 UI tests, 0 failures. Phase 6 targeted
coverage passes 13 tests and now proves a later scheduling failure preserves the known
integrity warning while also reporting the operation failure.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`Localizable.xcstrings` compiles successfully; `git diff --check` is clean.

Known issues: The explicit orphan-record repair UI remains scheduled for Phase 9. A real
App Icon, iOS 17 runtime validation, and physical-device notification, VoiceOver, and AX5
inspection remain deferred to release preparation. Xcode emitted the known post-test
diagnostic warning because its unqualified collector could not locate `simctl`; all build
and test suites had already succeeded.

Next suggested task: Commit and push this final remediation to PR #8 for approval.

## 2026-08-04 — Session 19 — Phase 7 deterministic Ask and on-device wording enhancement

Goal: Complete Phase 7 without weakening the iOS 17 experience or allowing raw user text,
detail projections, model arithmetic, or unconstrained actions across the generation boundary.

Files changed: Ask, generation, redaction, validation, cycle-summary, and classifier services;
Reminder Engine; Dashboard, Insights, Settings, and expense-entry integration; bilingual string
catalog and banned-phrase resource; Xcode project membership; Phase 7 unit/UI tests; and the
decision, task, privacy, test, changelog, project-memory, and session documents.

What was completed: Added deterministic English/Simplified Chinese classification and template
answers for all seven approved Ask intents, an explicit clarification for affordability without
amount/category, fixed unknown/out-of-scope responses, a Dashboard search-style entry, and no
conversation persistence. Added the three-method `AIAdviceGenerating` seam, complete fallback
output types, a centralized product-scope/API/runtime/default-off-user-setting gate, conditional
iOS 26 Foundation Models implementation with `LanguageModelSession`, `@Generable` constrained
outputs, and a constrained severity enum. Ask answers, purchase reminders, and current-cycle
summaries now share a 2.5-second timeout, explicit source metadata, and immediate templates for
unavailable, failed, timed-out, guardrail, or validation paths. DEBUG Settings exposes only local
reason counts for fallback diagnostics.

The three redacted contexts accept explicit aggregate value inputs only. Raw questions remain in
the local classifier, and raw notes, detail projections, transaction rows, merchant lists, and
cooling-off timestamps cannot enter a generator API. Summary outcome counts are attributed by
`outcomeRecordedAt` inside the current cycle, then only the counts cross the boundary. Numeric
validation preserves decimal meaning and rejects any normalized number absent from semantic
context values. Output validation also enforces task-specific action counts, allow-listed unique
actions, Continue Purchase for purchase decisions, length limits, and banned shame, diagnosis,
financial-advice, and purchase-prohibition language. Generated wording is never persisted.

What was NOT completed: Phase 8 Siri/App Intents, Spotlight, IndexedEntity, and onscreen-awareness
work was not pulled forward. Real Foundation Models generation was intentionally not invoked in
automation; supported-device Apple Intelligence validation remains a release smoke test.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 159 Swift Testing tests and 7 UI tests, 0 failures. Phase 7 targeted
coverage passes 17 tests for all intents, AI-off completeness, raw-question isolation,
aggregate-only contexts, current-cycle outcome attribution, four-part gates, timeout/failure/
validation fallback, numeric/action policies, and mock reminder/summary generation. The UI suite
also opens Dashboard Ask and verifies a template answer with enhancement off.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`Localizable.xcstrings` parses and compiles successfully; `git diff --check` is clean.

Known issues: The real Foundation Models path still needs a supported, Apple-Intelligence-enabled
physical-device smoke test. A real App Icon, iOS 17 runtime validation, and physical-device
VoiceOver/AX5 inspection remain deferred to release preparation. Xcode emitted the known
post-test diagnostic warning because its unqualified collector could not locate `simctl`; all
build and test suites had already succeeded.

Next suggested task: Commit Phase 7 locally, then push and open a pull request when review is
requested.

## 2026-08-04 — Session 20 — Close the Ask fact-dictionary privacy boundary

Goal: Address PR #9 review feedback that the Ask redactor still accepted an open
`[String: String]` fact map, which could let a future Siri caller place a merchant name,
note, or unrelated number into an otherwise aggregate-only model context.

Files changed: Ask redaction, aggregation, template, model-action, numeric-validation, and
Phase 7 test code; AI prompt contract, privacy notes, test plan, project memory, tasks,
decision record, changelog, and this session log.

What was completed: Replaced the generic Ask fact dictionary with exhaustive
`AskAggregateFacts` cases for affordability, remaining budget, stress, impulse, category
change, alternatives, wishlist status, unknown, and out-of-scope states. Aggregate inputs
now accept typed `Money`, `Int`, `Bool`, `ExpenseCategory`, `SpendingInsightType`,
`SuggestedAction`, and `ReminderTone` values rather than caller-provided fact keys, insight
strings, formatted money, or template prose. `PrivacyRedactor` alone validates currency,
formats money, maps enums to stable keys, and constructs a file-private Codable fact payload.
The deterministic fallback body is derived from that payload after redaction and is never
included in model prompt facts. Numeric output validation now derives its allow-list only
from the typed payload's semantic numeric members.

Added an exhaustive test over every Ask fact case that asserts the exact serialized prompt
key set, the matching intent, and absence of template-body, merchant, and note fields. The
previous validator, action, localized-number, raw-question, timeout, fallback, reminder, and
summary coverage remains active.

What was NOT completed: Phase 8 Siri/App Intents, Spotlight, IndexedEntity, and onscreen
awareness remain out of scope. No GitHub review thread was resolved or replied to; the user
provided the review text directly and only requested the implementation fix.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Test result: pass — 160 Swift Testing tests and 7 UI tests, 0 failures. Phase 7 targeted
coverage now passes 18 tests, including the new closed-fact-key contract.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths;
`git diff --check` is clean and the complete validation script succeeded.

Known issues: The real Foundation Models path still needs a supported,
Apple-Intelligence-enabled physical-device smoke test. The known post-test Xcode diagnostic
collector warning remains non-blocking because all build and test suites completed first.

Next suggested task: Commit and push this remediation to PR #9 for another review pass.

## 2026-08-04 — Session 21 — Phase 8A App Intents, App Entities, and Spotlight

Goal: Complete the iOS 17+ system-integration layer without pulling Phase 8B's iOS 26
`IndexedEntity` or onscreen-awareness work forward and without weakening the app's local-first
privacy boundaries.

Files changed: centralized integration capability/preferences; App Intent transport,
dependencies, actions, entities, queries, and shortcuts; Spotlight document/index service;
`DataActor` intent deduplication and merchant-eligibility query; app environment, routing,
Dashboard/Wishlist deep links, and Settings controls; English/Simplified Chinese string
catalog; Xcode project membership; Phase 8A tests; Siri/privacy/test/decision/task/changelog
memory; and this session log.

What was completed: Added all nine required App Intents and all seven required App Entities,
plus six suggested shortcuts. Siri and Spotlight now use independent default-off settings
through one product-scope + conditional framework/OS + runtime + user-consent boundary.
Siri-supplied strings are control-character stripped and truncated to 40 characters. The
only App Intent floating-point parameters live in `IntentMoneyTransport.swift`, which rejects
invalid or precision-losing values and converts to exact minor units before domain services.
Expense actions atomically deduplicate identical Siri/Shortcut retries for five seconds;
wishlist creation uses the documented 24-hour default, and budget-impact candidate names are
never persisted.

Implemented one app-owned Core Spotlight domain with redacted expense amount bands, current
budget status, wishlist/cooling-off state, typed insights, and emotion labels. Exact amounts
and notes are excluded. Merchant names require the centralized Spotlight gate, global opt-in,
and an eligible expense with the same normalized key, while local aggregation remains complete
for all expenses. Turning Spotlight off clears the domain; indexing errors surface in Settings
without changing SwiftData. Spotlight results and open intents route only to app-owned screens.
The current Xcode 26.6/iOS 26.5 App Schema interface was inspected and has no suitable
personal-finance, budget, expense, or wishlist domain, so custom schemas were retained and the
evidence was recorded.

What was NOT completed: `IndexedEntity`, onscreen awareness, and notification
`appEntityIdentifier` remain Phase 8B. Real Siri phrase resolution, Shortcuts presentation,
and Core Spotlight indexing still require physical-device release smoke testing. No branch was
pushed and no pull request was opened because the user has not requested the PR step yet.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5; App Intents metadata extraction
completed during the build.

Test result: pass — 175 Swift Testing tests and 7 UI tests, 0 failures. Phase 8A adds 15
targeted tests for gates, exact amount transport, sanitization, deduplication, currency errors,
localized shortcut phrases, ephemeral candidate data, wishlist defaults, entity/index
redaction, merchant consent, nonblocking index failure, and buffered/live deep-link delivery.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths; the single
documented transport exception remains isolated, the string catalog is valid JSON, and
`git diff --check` is clean.

Known issues: Xcode still logs the existing post-test simulator diagnostic-collector warning
after all suites have passed. App Shortcut phrases and real Spotlight results must be checked
on a signed physical iPhone before release.

Next suggested task: Commit Phase 8A locally, then push and open a pull request when the user
requests review.

## 2026-08-04 — Session 22 — Phase 8A typed errors and spoken-result disclosure

Goal: Close PR #10 review findings around unsupported-currency classification, misleading
money-intent fallback copy, and the undocumented exact-amount boundary for an active Siri
budget-impact query.

Files changed: App Intent amount transport/actions, bilingual error and integration copy,
Phase 8A tests, and the Siri, privacy, test, decision, changelog, project-memory, and session
documents.

What was completed: Split currency support from amount validation so unsupported currency
reaches its dedicated typed error. All three money-taking intents now map invalid amount,
unsupported precision, unsupported currency, and accounting-currency mismatch distinctly;
an unclassified execution failure uses neutral temporary-failure copy rather than claiming
the amount is invalid. Added English/Simplified Chinese strings and regression coverage for
the new transport classification and every new key. Preserved the exact deterministic flexible-
budget result for the authenticated, explicitly invoked impact action, documented it as a
narrow active-query exception, and added a Settings disclosure that Siri may speak the value.
Notifications, App Entity displays, and Spotlight remain exact-amount-free. The centralized
Siri/Spotlight gates, string sanitization, atomic five-second deduplication, and merchant-name
triple gate were reverified and unchanged.

What was NOT completed: No Phase 8B `IndexedEntity`, onscreen-awareness, or notification
entity-identifier work was started. Real spoken output and Shortcuts error presentation still
require a signed physical-iPhone release smoke test.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5; App Intents metadata and the string
catalog compiled successfully.

Test result: pass — 176 Swift Testing tests and 7 UI tests, 0 failures. The Phase 8A suite now
contains 16 tests and passes independently.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths; JSON parsing
and `git diff --check` pass.

Known issues: Xcode still emits the existing nonblocking post-test simulator diagnostic-
collector warning after all suites pass. Physical-device Siri speech/privacy-context validation
remains release work.

Next suggested task: Commit and push this remediation to PR #10, then wait for review and CI.

## 2026-08-05 — Session 23 — Phase 8A final review cleanup and Spotlight gate proof

Goal: Close the remaining PR #10 review observations by making App Intent amount feedback
semantically exact, keeping integration privacy copy readable at large accessibility sizes, and
verifying the Spotlight merchant-name conjunction through the real reconciliation path.

Files changed: App Intent money transport, Settings integration copy/layout, English/Simplified
Chinese string catalog, Phase 8A tests, and the Siri/privacy/test/decision/changelog/project-
memory documents plus this session log.

What was completed: Shortened the invalid-amount response to describe only nonfinite or
nonpositive input. Added a distinct typed and localized out-of-range response, and separated
the storage-safety limit from the exact-decimal-precision check so an oversized exact amount is
not misreported as a precision error. Split Siri spoken-result disclosure from the Spotlight
and merchant-consent explanation into separate Settings paragraphs. Added an end-to-end
Spotlight reconciliation test that independently proves a disabled centralized capability,
disabled global merchant setting, or absence of an eligible opted-in expense prevents merchant
documents, and that all three satisfied gates allow the document.

What was NOT completed: No Phase 8B `IndexedEntity`, onscreen-awareness, or notification
entity-identifier work was started. Real Siri speech, Shortcuts presentation, accessibility at
AX5, and Core Spotlight results still require release smoke testing on a signed physical iPhone.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5; `build-for-testing` completed and
App Intents metadata plus both string catalogs compiled successfully.

Test result: pass — 177 Swift Testing tests and 7 UI tests, 0 failures. The Phase 8A suite now
contains 17 tests and also passes independently.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths; the string
catalog parses as valid JSON and `git diff --check` is clean.

Known issues: Xcode still emits the existing nonblocking post-test simulator diagnostic-
collector warning after all suites pass. Physical-device Siri, accessibility, and Spotlight
validation remain release work.

Next suggested task: Commit and push this final cleanup to PR #10 for the next review pass.

## 2026-08-05 — Session 24 — Phase 9 IndexedEntity and onscreen awareness

Goal: Add the iOS 26 system-context enhancements without weakening the iOS 17 baseline,
local-only data boundary, amount-free system representations, or default-off consent gates.

Files changed: App Entity declarations, Spotlight document association, centralized system-
integration capabilities, onscreen `NSUserActivity` publication, notification scheduling,
Ask local retrieval, Dashboard/expense/wishlist/Insights presentation surfaces, Phase 6/8A/9
tests, the Xcode project, and the task, decision, Siri, privacy, test, changelog, and project-
memory documents.

What was completed: Conformed all seven amount-free App Entity projections to
`IndexedEntity` and associated them with the existing redacted Spotlight documents only on
iOS 26+. Added a centralized onscreen-awareness conjunction covering product scope,
conditional framework and OS availability, runtime support, and the default-off Siri user
setting. Dashboard, expense detail, and wishlist detail now publish typed, amount-free current-
subject references through `NSUserActivity`; Wishlist and Insights list screens explicitly
fail closed because the installed public SDK has no multi-object list-selection modifier.
Notification requests carry a gated wishlist entity reference to an explicit public-SDK
adapter boundary while retaining the existing iOS 17+ `userInfo` route. Ask now obtains only
intent-relevant, authoritative SwiftData projections through `LocalSearchService`; Spotlight
remains navigation-only and cannot supply numeric model facts. Renumbered release polish and
corrupt-row repair as Phase 10 so the owner's requested iOS 26 enhancement scope is Phase 9.

What was NOT completed: The installed Xcode 26.6/iOS 26.5 SDK exposes no public notification-
content App Entity annotation and no public multi-object SwiftUI list-selection API, so those
two adapters deliberately remain fail-closed stubs rather than using private or dynamic APIs.
Real Siri "this" resolution, Shortcuts/Spotlight behavior, and system-context handoff still
require signed physical-iPhone smoke testing. Phase 10 polish and corrupt-row repair were not
started. No commit was created, branch pushed, or pull request opened because review was not
requested yet.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5; the full validation build and App
Intents metadata extraction completed successfully.

Test result: pass — 183 Swift Testing tests and 7 UI tests, 0 failures. Phase 9 adds six
targeted tests for the four-part gate, all seven `IndexedEntity` conformances, entity-reference
mapping, intent-scoped local retrieval, typed redacted Spotlight payloads, and gated
notification entity references.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths and
`git diff --check` is clean.

Known issues: Xcode still emits the existing nonblocking simulator diagnostic-collector
warning after all suites pass. The unavailable public notification/list APIs and physical-
device system-context validation remain explicit release checks rather than simulated support.

Next suggested task: Review the Phase 9 diff, then commit, push, and open its pull request when
the user requests that step.

## 2026-08-05 — Session 25 — Phase 9 activity lifecycle and identity-only transfer

Goal: Close PR #11 review findings around onscreen activity withdrawal, the
`NSUserActivityTypes` declaration question, and the public `Transferable` expectation for
custom onscreen App Entities without widening MindBudget's system data surface.

Files changed: the onscreen activity adapter, App Entity transfer representations, Phase 9
tests, and the task, decision, Siri, privacy, test, changelog, project-memory, and session
documents.

What was completed: Replaced conditional removal of the SwiftUI activity modifier with
`userActivity(_:element:_:)`; the fully gated entity is the optional element, so disabled
consent, unavailable capability, or a missing subject passes nil and the public SwiftUI
contract advertises no activity. `ExpenseEntity`, `BudgetSnapshotEntity`, and
`WishlistItemEntity` now conform to `Transferable`. Their shared, versioned JSON reference
contains exactly entity kind, stable identifier, and version. It cannot encode names, dates,
categories, amount bands, exact amounts, notes, or another financial/user-authored field;
authoritative resolution remains inside each local entity query. Added compile-time conformance
and exact-key privacy tests. Kept search, prediction, and Handoff disabled.

Confirmed that the generated app Info.plist contains no `NSUserActivityTypes` declaration and
retains iOS 17.0 as its minimum OS. The key was not added speculatively because these activities
are not continuation inputs and the current App Entity association documentation does not
require it for same-device Siri context. Recorded a signed-device check that must decide this
before release. Also recorded that indexed emotion entities are a fixed app navigation
vocabulary and contain no user selection, count, transaction, or other user state.

What was NOT completed: Simulator tests cannot prove real Siri "this" resolution or the
release-device Info.plist behavior. The missing public multi-object list and notification
annotation APIs remain the existing explicit Phase 9 stubs. Phase 10 work was not started.

Build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5; build-for-testing and App Intents
metadata extraction completed successfully.

Test result: pass — 184 Swift Testing tests and 7 UI tests, 0 failures. Phase 9 now contains
seven targeted tests, including the three `Transferable` conformances and exact identity-only
payload key set.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths and
`git diff --check` is clean.

Known issues: Xcode emits the existing nonblocking post-test simulator diagnostic-collector
warning after all suites pass. Signed physical-iPhone validation remains required for Siri
onscreen consumption and the `NSUserActivityTypes` release decision.

Next suggested task: Commit and push this remediation to PR #11 for another review pass.

## 2026-08-06 — Session 26 — Pre-Phase-10 UI/UX redesign

Goal: Rebuild the existing free iPhone experience from the owner's high-fidelity UI/UX handoff
before Phase 10, while reserving only invisible integration seams for separately implemented
commercial features.

Files changed: app routing, shared SwiftUI components, semantic asset colors, onboarding,
Today/Dashboard, manual expense entry and reminders, Log, Insights, Wishlist/cooling-off, Ask,
Settings, `BudgetEngine`, unit/UI tests, localization, and durable project memory.

What was completed: Replaced the old shell with four real tabs—Today, Log, Insights, and
Wishlist—a separate accessible center add action, and Settings from Today. Applied the supplied
warm-paper visual language across all existing free screens. Added deterministic Today pace facts
to `BudgetEngine`, a locale-aware custom amount keypad, grouped expense history, wrapping context
chips, and a full-screen purchase-pause surface. Preserved the DataActor boundary, exact minor-unit
money, localized copy, raw-note projections, reminder safety contract, and all capability/privacy
gates. Documented later composition seams for Insights, Ask, Settings, and reminder rules, but did
not implement or expose StoreKit, entitlements, quotas, locked states, paywalls, trials, paid rules,
or any purchase entry.

What was NOT completed: Phase 10 release polish, signed-device VoiceOver/AX5/dark-mode checks,
the corrupt cooling-off-row repair action, App Store assets, TestFlight work, and the separate
commercialization phase were intentionally not started.

Build result: pass — Xcode 26.6, iPhone 17 simulator, iOS 26.5; build-for-testing and App
Intents metadata extraction completed successfully.

Test result: pass — 186 Swift Testing tests and 7 UI tests, 0 failures. The UI suite covers
English/Simplified Chinese onboarding, Ask fallback, Insights, manual expense entry through the
custom keypad and Log, Settings privacy/export reachability, and Wishlist/cooling-off.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths, localization
JSON is valid, and `git diff --check` is clean.

Known issues: Xcode emits the existing nonblocking post-test simulator diagnostic-collector
warning after all suites pass. Signed physical-iPhone visual/accessibility validation remains
owned by Phase 10.

Next suggested task: Review this redesign diff, then commit, push, and open its pull request when
the owner requests that step; begin Phase 10 only after merge.

## 2026-08-06 — Session 27 — UI/UX review remediation

Goal: Close the accessibility, information-architecture, identifier, and pace-test findings from
the first review of PR #12 without expanding the pre-Phase-10 redesign scope.

Files changed: custom app navigation, Today pace presentation, localization, `BudgetEngine`
tests, Phase 3 UI tests, and the decision, task, test, changelog, UI/UX, project-memory, and
session documents.

What was completed: Kept Settings behind Today's conventional labeled gear and recorded the
discoverability tradeoff plus the Phase 10 signed-device check. Restored explicit selected-state
and localized position announcements on the four custom tab buttons, allowed labels and the bar
to grow at accessibility text sizes, and placed the center add action fully inside its layout and
hit-test bounds. A first grouped-accessibility implementation was rejected by the UI test because
its synthesized container intercepted the Ask tab; the final implementation keeps the public
button semantics and supplies position values per tab without an overlaying synthetic container.
The Today pace track now exposes spending progress and cycle-day position to VoiceOver, and the
daily metric identifier is now `dashboard.today.left` rather than the misleading cycle-wide
`dashboard.available`. Added an explicit no-double-subtraction assertion plus a final-cycle-day
pace boundary test. Also corrected the Settings budget-section localization that the original
redesign had inadvertently changed to Today.

What was NOT completed: Phase 10 release polish and signed-device VoiceOver/AX5 verification were
not started. No commerce surface, entitlement, StoreKit path, or other paid feature was added.

Build result: pass — Xcode 26.6, iPhone 17 simulator, iOS 26.5; build-for-testing and App Intents
metadata extraction completed successfully.

Test result: pass — 187 Swift Testing tests and 7 UI tests, 0 failures. The UI suite verifies the
selected Today/Wishlist states, nonempty pace accessibility value, renamed Today metric, Ask tab
hit testing, Settings privacy/export reachability, and the existing bilingual feature flows.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths, localization
JSON is valid, and `git diff --check` is clean.

Known issues: Xcode emits the existing nonblocking post-test simulator diagnostic-collector
warning after all suites pass. Phase 10 still owns signed physical-iPhone VoiceOver order,
position wording, AX5 layout, and center-button edge hit testing.

Next suggested task: Push this review remediation to PR #12 and request a second review; begin
Phase 10 only after the redesign PR is approved and merged.

## 2026-08-07 — Session 28 — Deterministic navigation accessibility order

Goal: Close the second PR #12 review's nonblocking findings about the center add action's
VoiceOver position and the literal tab-count accessibility value.

Files changed: `AppRouter`, Phase 3 unit/UI tests, and the decision, task, test, changelog,
UI/UX, project-memory, and session documents.

What was completed: Made `AppTab` exhaustive through `CaseIterable`, derived each localized
position and total from its declared order, and removed all four numeric position arguments plus
the literal total. Declared the complete accessibility sort order with descending priorities:
Today, Log, Add Expense, Insights, Wishlist. The tab-priority switch is exhaustive, so a new tab
cannot compile without an explicit traversal decision. Added a unit contract for the declared tab
order/positions and UI assertions for the English `Tab 1 of 4` and `Tab 4 of 4` values.

What was NOT completed: Simulator automation cannot reproduce a real VoiceOver swipe traversal.
Phase 10 still owns a signed physical-iPhone check of actual order, focus restoration, and AX5
layout. No commerce or Phase 10 feature was started.

Build result: pass — Xcode 26.6, iPhone 17 simulator, iOS 26.5; build-for-testing and App Intents
metadata extraction completed successfully.

Test result: pass — 188 Swift Testing tests and 7 UI tests, 0 failures. The two new UI assertions
confirm the derived English positions while the existing navigation, Ask, Settings, expense,
Insights, localization, and Wishlist/cooling-off flows remain green.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths and
`git diff --check` is clean.

Known issues: Xcode emits the existing nonblocking post-test simulator diagnostic-collector
warning after all suites pass. Signed-device VoiceOver traversal remains the authoritative final
check because `accessibilitySortPriority` itself is not exposed as an XCTest query property.

Next suggested task: Push this final accessibility remediation to PR #12 for approval and merge;
begin Phase 10 only after the redesign PR lands on `main`.

## 2026-08-07 — Session 29 — Phase 10 automated release readiness

Goal: Complete the source-controlled portion of Phase 10—repairability, accessibility and
localization automation, deterministic performance evidence, coverage enforcement, release
configuration, App Store drafts, and a truthful handoff to signed-device/TestFlight work.

Files changed: cooling-off repair actor/session/Settings flow, localization, release-readiness,
money/rule/AI/privacy and Phase 6 tests, UI tests, app icon and version metadata, validation and
coverage scripts, App Store/release/privacy documents, and durable project memory.

What was completed: Added a localized, count-aware, destructive-confirmation repair path for
unreadable cooling-off rows. Only identifiers previously shown to the user cross the actor
boundary; every row is revalidated inside the commit, readable rows are preserved, and repair
success clears stale integrity state independently from a later notification failure. Added
English/Simplified Chinese catalog parity and format checks, AX5 and pseudo-long navigation smoke,
and a deterministic 10,000-expense Dashboard first-load assertion below 500 ms. Raised selected
core source files above the documented 85% per-file coverage gate and made validation enforce it.
Added an opaque 1024px icon, version 1.0.0/build 1, a generic-simulator Release build gate, static
release checks, bilingual App Store metadata drafts, and an explicit release checklist.

The owner changed to a China-region Apple Developer account. No Team ID was committed and no
certificate, App ID, App Store Connect record, Archive, or upload was changed in this session.
The release checklist now requires the latest China-region team, final Bundle ID ownership,
distribution identity/profile, agreements, archive identity, and target App Store Connect app to
be reverified immediately before upload. Xcode also reported several locally installed malformed
provisioning-profile files during the first sandbox-limited attempt; they did not affect simulator
validation but must not be mistaken for valid release signing material.

What was NOT completed: Signed physical-iPhone VoiceOver traversal, AX5/dark-mode visual review,
real iOS 17/iOS 26 integration checks, data-protection inspection, Instruments profiling, localized
screenshots, App Store privacy/age/encryption forms, production Archive validation, and TestFlight
upload all require the owner account and/or physical hardware and remain unchecked. Phase 10 stays
In Progress. Commercialization/StoreKit remains a separate future phase and no paid UI was added.

Build result: pass — Xcode 26.6; generic iOS Simulator Release build plus Debug
build-for-testing completed successfully for the iPhone-only iOS 17+ app.

Test result: pass — 198 Swift Testing tests across 16 suites and 9 end-to-end/localization UI
tests, 0 failures. The deterministic 10,000-expense Dashboard load assertion passed. Xcode emitted
the existing nonblocking diagnostic-collection warning after the completed simulator suites.

Coverage result: pass — Money 91.73%, BudgetEngine 94.24%, BudgetCycleCalculator 95.15%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 90.98%,
AdviceSafetyValidator 94.50%, PrivacyRedactor 96.91%, CycleSummaryService 96.99%,
IntentClassifier 97.50%, CSVExporter 90.79%, and CurrencyFormatterService 100%.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths; the app icon is
1024px and opaque; the privacy manifest, version, bundle identifier shape, iPhone-only target,
localization JSON, absence of a committed Apple Team ID, shipping-source TODO/FIXME scan, and
`git diff --check` all pass.

Known release gates: Complete every unchecked item in `Docs/RELEASE_CHECKLIST.md` against the
release commit and the owner's current China-region Apple Developer team before marking Phase 10
Done or describing V1 as TestFlight-ready.

Next suggested task: Review the Phase 10 diff, then commit, push, and open its pull request when
the owner requests that step. After merge, perform the signed-device and App Store Connect release
checklist using the current China-region account.

## 2026-08-07 — Session 30 — Stable Phase 10 performance evidence

Goal: Close the Phase 10 review findings about hosted-runner wall-clock flakiness, the narrow
10,000-expense fixture, repair-flow discoverability, and the coverage gate's actual enforcement.

Files changed: the Phase 10 release-readiness tests, validation/CI configuration, release and test
checklists, and the decision, task, and session documents.

What was completed: Split Dashboard performance evidence into an always-on deterministic
10,000-expense projection contract and a separately named local wall-clock benchmark. The fixture
now spans the current cycle's dates, every expense category and bucket, varied exact minor-unit
amounts, and 16 normalized merchants, while the assertions confirm all 10,000 rows and the intended
merchant distribution reach the Dashboard projection. Hosted CI explicitly skips only the strict
500 ms clock assertion because shared-runner contention is not a reliable performance oracle; the
deterministic workload still runs there, while the strict clock signal remains available locally
and signed-device Instruments remains authoritative for release.

Verified the exact Swift Testing identifier, including its trailing parentheses, so the CI skip is
effective rather than silently ignored. Confirmed that `Scripts/check-coverage.sh` exits nonzero
when a selected file is missing or below 85%, that `Scripts/validate.sh` always invokes it after the
coverage-enabled test run, and that the GitHub Actions workflow invokes `Scripts/validate.sh`.
Expanded the release usability walk-through to begin from Wishlist, judge whether the existing
Today → Settings → Notifications repair route is discoverable, and require a neutral Wishlist
pointer later if signed-device testing shows it is not. The repair itself remains intentionally
single-sourced and never automatic.

What was NOT completed: No release signing, physical-device accessibility/performance pass,
Archive, App Store Connect work, or TestFlight upload was performed. Phase 10 remains In Progress
until the unchecked signed-device and owner-account items in the release checklist are completed.

Build result: pass — Xcode 26.6; generic iOS Simulator Release build plus Debug
build-for-testing completed successfully.

Test result: pass — 199 Swift Testing tests across 16 suites and 9 UI tests, 0 failures. The local
strict benchmark passed. A separate CI-mode verification ran the deterministic Phase 10 test while
successfully excluding only the wall-clock benchmark. Xcode emitted the existing nonblocking
post-test simulator diagnostic-collection warning after all UI suites passed.

Coverage result: pass — Money 91.73%, BudgetEngine 94.24%, BudgetCycleCalculator 95.15%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 90.98%,
AdviceSafetyValidator 94.50%, PrivacyRedactor 96.91%, CycleSummaryService 96.99%,
IntentClassifier 97.50%, CSVExporter 90.79%, and CurrencyFormatterService 100%.

Static policy result: pass — no unauthorized `Double`/`Float` in app money paths,
`Scripts/check-release-readiness.sh` passed, `Scripts/validate.sh` is valid Bash, and
`git diff --check` is clean.

Next suggested task: Push this remediation to PR #13 for review. After approval and merge, execute
the remaining signed-iPhone and China-region Apple Developer release checklist before the first
TestFlight upload.
