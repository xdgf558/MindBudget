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

## 2026-08-07 — Session 31 — Approved App Icon variants

Goal: Replace the Phase 10 placeholder icon with the owner's approved budget-track design and
support the system's standard, dark, and tinted Home Screen appearances.

Files changed: standard/dark/tinted SVG sources and 1024px PNG assets, App Icon catalog metadata,
release validation, task/release memory, changelog, decision log, and this session log.

What was completed: Rebuilt the icon from the supplied numeric specification rather than cropping
the reference screenshot. The shared geometry is a 644×74 fully rounded track beginning at x 190,
a 352px completed segment, and a 33×264 rounded marker centered at x 622. Added the specified
green-gradient standard appearance, the supplied near-black/mint dark appearance, and a grayscale
tinted appearance. All three raster assets are 1024×1024 RGB PNGs without alpha or pre-rounded
corners. The asset catalog uses Xcode's luminosity `dark` and `tinted` appearance declarations,
and the release script now validates every variant plus both appearance mappings.

What was NOT completed: No signing, Archive, App Store Connect, or TestFlight operation was
performed. The final iOS-applied mask and tint rendering remain items for the signed-device
release checklist. Phase 10 remains In Progress.

Build result: pass — Xcode 26.6 compiled the standard, dark, and tinted catalog appearances in
both the generic iOS Simulator Release build and Debug build-for-testing with no asset warnings.

Test result: pass — 199 Swift Testing tests across 16 suites and 9 UI tests, 0 failures. The
existing nonblocking simulator diagnostic-collection warning appeared only after all suites passed.

Static policy result: pass — all three generated files are 1024×1024 RGB PNGs with no alpha;
the extended release-readiness script, floating-point money guard, asset-catalog JSON parse,
coverage gate, and `git diff --check` pass.

Next suggested task: Complete validation, publish this focused icon change for review, then verify
all three appearances on the signed release iPhone before Archive.

## 2026-08-07 — Session 32 — Release brand lock and China-account preflight

Goal: Begin the new-account signing → physical-device/Archive → TestFlight → internal-testing
sequence while ensuring the approved icon and complete public brand enter the exact release build.

Files changed: Debug/Release display-name settings, App Store submission draft, release validation
and checklist, task/project/decision memory, changelog, and this session log.

What was completed: Locked the public brand to `花有数 MindBudget`, kept the technical target and
bundle suffix stable as `MindBudget`, and set `温和的预算与消费复盘工具` as the Simplified Chinese
App Store subtitle. Added a static gate requiring the approved display name in both build
configurations. Re-ran the complete simulator release suite with the approved three-appearance
icon and brand together. Read-only Xcode preflight found only the legacy Apple Developer account
and its team; no action was taken with that account.

What was NOT completed: The icon/brand branch has not yet merged to `main`. The owner's new
China-region Apple Developer account is not signed into Xcode. No valid local code-signing
identity is currently available, no private `Config/Local.xcconfig` exists, and the effective
fallback Bundle ID still uses the public repository prefix. The connected physical iPhones were
unavailable during discovery. No certificate/profile was created or downloaded, no password or
two-factor code was requested or handled, no Archive was produced, and nothing was uploaded or
assigned to an internal TestFlight group. The legacy account was identified by the owner after
the read-only check; its exact local credential must be confirmed before deletion, and Apple/Xcode
credentials must never be deleted by a broad match.

Build result: pass — Xcode 26.6 generic iOS Simulator Release and Debug build-for-testing; the
generated app uses the approved display name and compiles all standard/dark/tinted icon assets.

Test result: pass — 199 Swift Testing tests across 16 suites and 9 UI tests, 0 failures; all
selected core files remain above the 85% coverage gate.

Static policy result: pass — brand, icon dimensions/opacity/catalog mappings, privacy/version/
iPhone-only checks, no shared Team ID, floating-point money policy, and `git diff --check` pass.

Next suggested task: Publish and review the icon/brand PR, then merge it before Archive. Sign the
identified legacy account out and delete only its exact local credential after explicit at-action
confirmation; when the new account login requests a password or two-factor code, hand control to
the owner. Then reconnect/unlock the release iPhone, identify the exact private Bundle ID prefix
under the new team, and obtain explicit confirmation before creating certificates or profiles.

## 2026-08-07 — Session 33 — Localized release name and signed-device preflight

Goal: Continue the current China-region account release sequence, validate the approved icon on a
signed iOS 26 iPhone, and ensure the Home Screen shows exactly one language-appropriate app name.

Files changed: the generated Info.plist display-name fallback, a dedicated InfoPlist string
catalog, localization tests, release validation, App Store drafts, release/task/project/decision
memory, changelog, and this session log.

What was completed: Signed the legacy Apple account out of Xcode and found no exact generic or
internet-password Keychain item under its email, so no broad credential deletion was attempted.
The owner manually signed the current China-region account into Xcode. Apple Developer access and
the active free/paid App Store agreements were verified without recording private account or team
identifiers in the repository. A private ignored `Config/Local.xcconfig` now selects the current
team and remains untracked.

After the owner enabled Developer Mode, Xcode registered the connected iOS 26 iPhone, generated an
Apple Development certificate and team provisioning profile, and produced a successful signed
Debug build. The app installed and launched on that device with the approved standard/dark/tinted
icon assets. The owner then clarified that the two names must not be combined: English now shows
`MindBudget`, Simplified Chinese shows `花有数`, and unsupported languages fall back to
`MindBudget`. Xcode compiled both `InfoPlist.strings` variants, App Intents training resolved the
matching localized application name, and the updated signed build was installed on the same
device. PR #14 was moved from Draft to ready for review after its earlier CI run passed.

What was NOT completed: PR #14 has not merged to `main`, so no production Archive was created.
The current team still has no explicit production App ID or App Store Connect app record for this
bundle, and no Apple Distribution identity/profile has been created or validated. The App Store
Connect app, localized listing, Archive, Organizer validation, upload, build processing, and
internal tester assignment remain pending. The full signed-device VoiceOver, AX5, appearance,
system-integration, Instruments, data-protection, and iOS 17 passes remain unchecked. The owner
still needs to visually confirm that the reinstalled Home Screen label and icon appearance match
the selected system language and design.

Build result: pass — Xcode 26.6 generic iOS Simulator Release plus a current-team signed Debug
build for the connected iOS 26 iPhone; the signed app installed and launched successfully.

Test result: pass — 200 Swift Testing tests across 16 suites and 9 end-to-end/localization UI
tests, 0 failures. The new test proves the English and Simplified Chinese InfoPlist display names
remain separate. The existing nonblocking post-test simulator diagnostic warning appeared only
after every suite passed.

Coverage result: pass — Money 91.73%, BudgetEngine 94.24%, BudgetCycleCalculator 95.15%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 90.98%,
AdviceSafetyValidator 94.50%, PrivacyRedactor 96.91%, CycleSummaryService 96.99%,
IntentClassifier 97.50%, CSVExporter 90.79%, and CurrencyFormatterService 100%.

Static policy result: pass — no unauthorized floating-point money paths; the three 1024px opaque
icon variants, bilingual InfoPlist names, privacy/version/iPhone-only checks, absence of a shared
Team ID, coverage gate, and `git diff --check` all pass.

Next suggested task: Have the owner confirm the signed-device Home Screen label, review PR #14,
and merge it to `main`. Then register the explicit App ID and App Store Connect app under the
current team, create and inspect a production Archive, validate its distribution identity, and
upload build 1 to the intended internal TestFlight group.

## 2026-08-07 — Session 34 — One explicit budget-save action

Goal: Remove the floating keyboard `Done` control reported on the signed-device budget setup
screen and make the bottom `Save Budget` button the only persistence action.

Files changed: budget setup, Phase 3 end-to-end UI coverage, redesign/decision memory, changelog,
and this session log.

What was completed: Removed only the budget setup keyboard toolbar; other contextual Done actions
remain unchanged. Tapping `Save Budget` now clears the focused amount field before running the
existing whole-draft validation and persistence flow. Every onboarding UI path now enters the
three budget values without dismissing the decimal keyboard between fields. The primary flow also
asserts that no `Done` button exists, then proves the bottom save action still advances to Today.
The same flow passed under accessibility-extra-large and pseudo-long-text configurations.

What was NOT completed: This focused change does not create a production Archive, App Store
Connect record, TestFlight upload, or internal tester assignment. PR #14 still requires owner
review and merge before those release actions. The revised budget setup should receive one final
visual confirmation on the signed iPhone before Archive.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and Debug build-for-testing.

Signed-device result: pass — the current-team Debug build was rebuilt from commit `bce905b`,
installed over the existing app on the connected iPhone Air without an uninstall/reset, and
launched successfully. The owner still owns the final visual interaction confirmation.

Test result: pass — 200 Swift Testing tests across 16 suites and 9 UI tests, 0 failures. The
targeted manual-expense onboarding flow also passed independently after the interaction change.

Coverage result: pass — all selected core-service files remain at or above the 85% gate.

Static policy result: pass — release-readiness checks, floating-point money guard, and the complete
validation script pass.

Next suggested task: Publish this focused PR update for owner review, visually verify the budget
setup on the signed iPhone, and merge PR #14 before creating the production App ID and Archive.

## 2026-08-07 — Session 35 — Keep custom navigation bottom-anchored

Goal: Diagnose and repair the signed-iPhone layout in which Today's custom navigation surface
expanded through most of the screen, moving the add action to the top and the four tabs to the
middle.

Files changed: app routing/navigation layout, Today state layout, Phase 3 UI geometry coverage,
redesign/decision memory, changelog, and this session log.

What was completed: Traced the expansion to the transparent center gap accepting an unconstrained
vertical proposal while Today exposed its compact loading state. The gap now has its intended
fixed placeholder height, the complete custom bar uses its vertically ideal size, real labels may
still grow for Dynamic Type, and Today's state container fills the remaining content area. Added
geometry assertions that require both the selected tab and add action to remain in the bottom
screen region at standard and AX5 sizes. Rebuilt with the current team's development signing and
installed the fixed build over the existing app on the connected iPhone Air without uninstalling
or resetting it.

What was NOT completed: The device locked before the newly installed build could be launched, so
the owner still needs to unlock it and visually confirm the corrected layout. PR #14 remains
unmerged; no production Archive, TestFlight upload, or internal tester assignment was performed.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, Debug build-for-testing, and
current-team signed iPhone Debug build.

Test result: pass — 200 Swift Testing tests across 16 suites and 9 UI tests, 0 failures; the two
focused layout tests also passed independently.

Coverage result: pass — all selected core-service files remain at or above the 85% gate.

Static policy result: pass — release-readiness checks, floating-point money guard, complete
validation, and `git diff --check` pass.

Next suggested task: Unlock the connected iPhone, launch the installed build, confirm Today and
the add action remain bottom-anchored, then review and merge PR #14.

## 2026-08-07 — Session 36 — Close PR 14 release-review gaps

Goal: Address the final review observations on PR #14 without hiding its signed-device behavior
changes behind a brand-only title.

Files changed: Phase 3 UI coverage, App Icon source/export documentation and checksum manifest,
release validation/checklist, decision memory, changelog, and this session log.

What was completed: Replaced the English-label-specific missing-`Done` assertion with a structural
check that the visible budget keyboard has no toolbar buttons, and exercised it in both English and
Simplified Chinese. Reset the account, team, and App Store agreement checklist items to unchecked
per-Archive gates; retained the 2026-08-07 development observations in a separately labeled,
non-authoritative historical section. Documented the one-to-one SVG-to-PNG App Icon mapping and
repeatable librsvg export commands. Added a checksum manifest covering all three SVG sources and
all three shipping PNGs, and made release validation reject unreviewed drift on either side.

What was NOT completed: No production Archive, Organizer validation, App Store Connect upload, or
internal TestFlight assignment was performed. The installed signed-device binary did not change in
this review-only patch, and the owner still needs to confirm the bottom-navigation fix on the
unlocked iPhone. The account, signing, agreement, certificate/profile, Bundle ID, and app-record
checks must be repeated against the exact Archive/upload environment rather than inferred from the
historical development preflight.

Build result: pass — Xcode 26.6 generic iOS Simulator Release and Debug build-for-testing.

Test result: pass — 200 Swift Testing tests across 16 suites and 9 UI tests, 0 failures. Both the
English manual flow and Simplified Chinese smoke flow found the software keyboard and verified a
zero-button toolbar. The deterministic 10,000-expense projection and local wall-clock signal also
passed.

Coverage result: pass — Money 91.73%, BudgetEngine 94.24%, BudgetCycleCalculator 95.15%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 90.98%,
AdviceSafetyValidator 94.50%, PrivacyRedactor 96.91%, CycleSummaryService 96.99%,
IntentClassifier 97.50%, CSVExporter 90.79%, and CurrencyFormatterService 100%.

Static policy result: pass — all six App Icon source/artifact checksums, dimensions, opacity,
catalog mappings, release metadata/privacy gates, floating-point money policy, coverage gate, and
`git diff --check` pass.

Next suggested task: Publish this correction to PR #14 under a title/body that explicitly includes
approved branding plus the signed-device budget and bottom-navigation fixes, obtain final review,
then merge before beginning production App ID, Archive, and TestFlight operations.

## 2026-08-07 — Session 37 — Restore empty-state action proportions

Goal: Repair the cramped near-square `Add Expense` action observed on Today's signed-iPhone empty
state and apply the same correction to Wishlist's `Add Item` action.

Files changed: shared empty-state button presentation, Today and Wishlist call sites, Phase 3 UI
geometry coverage, redesign/test/decision memory, changelog, and this session log.

What was completed: Replaced the full-width form button style inside `ContentUnavailableView` with
a dedicated compact primary style that preserves a one-line localized label, horizontal padding,
a 140-point minimum width, and the existing 50-point touch height. Added distinct accessibility
identifiers for both actions and geometry assertions requiring each control to remain at least
140 points wide and wider than twice its height. The first full validation exposed that Wishlist's
outer accessibility identifier replaced the nested button identifier; removed that parent-level
override and reran the complete suite successfully.

What was NOT completed: No production Archive, App Store Connect upload, TestFlight assignment,
or merge was performed. The owner still needs to review this update in PR #14 and visually confirm
the two actions on the signed iPhone before the release Archive.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and Debug
build-for-testing.

Test result: pass — 200 Swift Testing tests across 16 suites and 9 UI tests, 0 failures. Both
Dashboard and Wishlist compact-action geometry assertions passed in the final run.

Coverage result: pass — all selected core-service files remain at or above the 85% gate.

Static policy result: pass — release-readiness checks, floating-point money guard, and
`git diff --check` pass.

Next suggested task: Push the focused fix to PR #14, obtain owner review, and merge before the
production Archive and TestFlight workflow.

## 2026-08-07 — Session 38 — Refine bottom navigation and split Settings

Goal: Remove the unexplained horizontal line across the raised center Add Expense control, replace
the growing Settings scroll with first- and second-level pages, and prevent dynamic Settings values
from exposing raw localization keys.

Files changed: custom bottom-navigation presentation, Settings and AI-status views, localization,
UI tests, redesign/test/project/decision memory, changelog, and this session log.

What was completed: Identified the line as a one-point decorative hairline overlay rather than a
gesture indicator or functional boundary. Removed that overlay while retaining the semantic
navigation surface, bottom safe-area coverage, intrinsic layout, hit regions, and declared
VoiceOver order. Replaced the single long Settings screen with a short root directory and focused
Budget, Reminders and Notifications, Apple Intelligence, Integrations, Export, Privacy, and About
destinations. Export and Privacy remain directly reachable from the root. Localized reminder-tone
and AI status values explicitly through the active locale; the Debug fallback counters remain
inside `#if DEBUG` and compile out of Release/TestFlight.

What was NOT completed: Archive and TestFlight operations remain pending final PR approval and
merge. Validation, refreshed signed-device installation, commit, push, and hosted CI results are
recorded after their actual results below.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, Debug
build-for-testing, and current-team signed iPhone Debug build. Release compilation excludes the
`#if DEBUG` fallback diagnostics used during development.

Test result: pass — 200 Swift Testing tests across 16 suites and 9 UI tests, 0 failures. The
Simplified Chinese path opens the new Reminders page, reads the tone as `柔和`, and rejects the raw
catalog key; the English path proves every root destination plus Export and Privacy is reachable.

Coverage result: pass — all selected core-service files remain at or above the 85% gate.

Static policy result: pass — release-readiness checks, the floating-point money guard, String
Catalog JSON validation, and `git diff --check` pass.

Signed-device result: pass with launch deferred by lock state — team `2AM5S7BM2N` signed bundle
`com.xdgf558.MindBudget` installed in place on the connected iPhone without deleting app data. The
CoreDevice launch request was denied only because the phone was locked; the owner can unlock and
open the installed app directly.

Next suggested task: Commit and push the focused signed-device refinements to PR #14, obtain owner
review, then merge before the production Archive and TestFlight workflow.

## 2026-08-07 — Session 39 — Adopt a prerelease TestFlight identity

Goal: Make the first internal-test version visibly prerelease and ensure every future uploaded
build has a durable, tester-facing change record.

Files changed: app marketing version, release-readiness version gate, changelog, TestFlight notes,
submission/release/task/project/decision memory, and this session log.

What was completed: Changed Debug and Release marketing version from 1.0.0 to 0.9.0 while retaining
build 1 for the first upload. Reserved 1.0.0 for the first public App Store release. Added a dated
0.9.0 (1) TestFlight-candidate section to the changelog, a matching “What to Test” record, and a
release-checklist gate requiring future uploads to synchronize both records. The static gate now
checks both marketing version 0.9.0 and build 1 in Debug and Release.

What was NOT completed: The versioned binary has not been archived or uploaded. Replacement build
numbers will be incremented only immediately before their actual upload.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, Debug build-for-testing,
and current-team signed iPhone Debug build all use version 0.9.0 (1).

Test result: pass — the final versioned run repeated all 200 Swift Testing tests across 16 suites
and all 9 UI tests with 0 failures; every selected core-service file remains above 85% coverage.

Static policy result: pass — release readiness enforces version 0.9.0/build 1 in both configurations;
the floating-point money guard and `git diff --check` also pass.

Signed-device result: pass — team `2AM5S7BM2N` signed application identifier
`2AM5S7BM2N.com.xdgf558.MindBudget`; its Info.plist reports 0.9.0 (1). The package was installed in
place on the connected iPhone, preserved the app container, and launched successfully.

Next suggested task: Commit and push both signed-device refinements and prerelease identity to
PR #14 for owner review, then merge before production Archive and TestFlight upload.

## 2026-08-07 — Session 40 — Add three included skins and unify the Chinese product name

Goal: Replace remaining Simplified Chinese references to the English product name with `花有数`
and add three extensible visual skins based on the owner's supplied aurora, botanical, and neon
references without prematurely exposing paid-product UI.

Files changed: shared semantic theme and background, Settings/preferences, app routing, all free
feature surfaces, localization, unit/UI tests, Xcode project membership, changelog, submission
notes, redesign/test/project/task/decision memory, and this session log.

What was completed: Added Aurora Glow, Warm Botanical, and Neon Pulse as stable persisted
`AppSkin` values resolved through one environment-injected semantic theme. Added a focused
Appearance and Skins Settings destination with live previews, selection state, persistence, a
safe corrupt-value fallback, and Delete All reset behavior. All three initial skins are included;
no lock, price, paywall, or PRO placeholder is visible before commerce exists. Migrated the app's
shared backgrounds, cards, controls, feature views, and custom navigation to semantic palette
roles rather than duplicating screens. Audited the Simplified Chinese string catalogs and replaced
all user-facing `MindBudget` references with `花有数`; English copy and technical target, bundle,
store, Spotlight, and Swift identifiers remain unchanged. Added an unreleased TestFlight testing
record without claiming a build number that has not yet been uploaded.

What was NOT completed: No StoreKit product, entitlement, purchase, restore, paywall, or paid-skin
behavior was implemented. No production Archive, App Store Connect upload, TestFlight assignment,
commit, push, or PR was performed. The owner still needs to inspect all three skins on the signed
iPhone after unlocking it; the pre-existing PR #14 remains unchanged.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, Debug build-for-testing, and
current-team signed iPhone Debug build. The signed package reports version 0.9.0 (1), bundle
identifier `com.xdgf558.MindBudget`, and Team ID `2AM5S7BM2N`.

Test result: pass — 203 Swift Testing tests across 16 suites and 9 UI tests, 0 failures. Coverage
remains above the required gate for every selected core service. New coverage verifies skin
defaulting, persistence, corrupt-state fallback without silent rewriting, Delete All reset, all
three localized names, the Chinese product-name boundary, Settings reachability, and selected
accessibility state.

Static policy result: pass — floating-point money guard, release-readiness checks, bilingual
catalog validation, app-icon validation, coverage gate, and `git diff --check` all pass.

Signed-device result: installed, launch deferred by lock state — the Team `2AM5S7BM2N` package was
installed in place on the connected iPhone without uninstalling or deleting its local container.
The CoreDevice launch request was denied only because the phone was locked; the owner can unlock
and open `花有数` directly.

Next suggested task: Complete the owner's signed-iPhone visual and accessibility review of all
three skins, then commit and publish this focused follow-up branch for review. Increment build 1
only if it has already been uploaded and a replacement TestFlight binary is required.

## 2026-08-07 — Session 41 — Replace palette-only skins with complete background artwork

Goal: Address the owner's signed-device feedback that the three skins changed colors but did not
include the distinctive background motifs shown in the supplied visual references.

Files changed: three new portrait image sets in `Assets.xcassets`, the shared theme background and
skin preview, Settings skin artwork tests, release-readiness policy, brand source documentation,
TestFlight testing notes, changelog, redesign/test/project/task/decision memory, and this log.

What was completed: Created three purpose-built, text-free portrait backgrounds from the owner's
references instead of cropping or shipping the reference screenshots. Aurora Glow now includes a
teal aurora, small stars, and layered lower waves; Warm Botanical includes warm ivory paper,
upper-right leaves, natural shadows, and a restrained lower sprig; Neon Pulse includes an indigo
canvas with purple/cyan grid, particles, and light trails. `AppSkin` maps exhaustively to one asset,
the shared full-screen background renders that asset with a readability scrim, and Settings uses
the same artwork in each preview. Documented the exact generation prompts and asset contract in
`Docs/Brand/SkinBackgrounds.md`. Added unit and static release gates for presence, asset-catalog
membership, opaque portrait dimensions, and exhaustive skin coverage.

What was NOT completed: No StoreKit product, entitlement, purchase, restore, paywall, paid-skin
lock, production Archive, App Store Connect upload, TestFlight assignment, commit, push, or PR was
performed. The connected iPhone was locked when the automatic launch was attempted, so the owner
still needs to open the installed build and complete the final visual/readability comparison.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, Debug build-for-testing, and
current-team signed iPhone Debug build all compile the three new image sets successfully.

Test result: pass — the full Swift Testing suite and all 9 UI tests completed with 0 failures. The
new asset test resolves every `AppSkin` background through the app bundle and enforces an opaque
portrait canvas of at least 800×1700 pixels. Every selected core service remains above the 85%
coverage gate.

Static policy result: pass — release readiness validates each theme image's file reference,
dimensions, opacity, and image-set membership; floating-point money guard and `git diff --check`
also pass.

Signed-device result: installed, launch deferred by lock state — the build is signed with Team ID
`2AM5S7BM2N` and was installed in place as `com.xdgf558.MindBudget`, preserving the existing app
container. The launch request was denied only because the phone was locked.

Next suggested task: Unlock the iPhone, open `花有数`, and compare all three skins through
Settings > Appearance and Skins; then commit and publish this focused branch for owner review.

## 2026-08-07 — Session 42 — Publish in-app 0.9.1 update notes

Goal: Raise the signed-device prerelease version after the skin/brand update and make its release
notes visible inside Settings > About.

Files changed: app Debug/Release version settings, About UI, bilingual localization, Settings UI
coverage, release-readiness validation, changelog, TestFlight/submission and release-checklist
records, project/task/test/decision memory, and this session log.

What was completed: Raised the marketing version from `0.9.0` to `0.9.1` and the build from `1` to
`2` in both app configurations. About still reads the installed marketing version from the bundle
and now adds a bilingual `0.9.1` update section describing the three included skins, complete
background artwork, improved readability/previews, and unified Simplified Chinese `花有数` name.
Added matching dated changelog and next-candidate TestFlight notes. Release readiness now rejects a
project version/build that lacks matching changelog and submission-note sections. UI coverage opens
About and confirms both the built version and update summary are reachable.

The owner also asked why the app has no opening animation. The current app uses an iOS-generated
static launch screen and has no post-launch brand overlay; iOS launch screens themselves cannot
animate. No animation was added because this was a diagnostic question rather than authorization
to introduce a startup delay. A future implementation should be a short in-app cold-launch layer
that respects Reduce Motion and never blocks quick expense entry.

What was NOT completed: No startup animation, StoreKit/PRO behavior, production Archive, App Store
Connect upload, TestFlight assignment, commit, push, or PR was performed. The connected iPhone was
locked when the automatic launch was attempted, so final device inspection remains manual.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, Debug build-for-testing, and
current-team signed iPhone Debug build. The signed package reports `0.9.1 (2)`.

Test result: pass — 204 Swift Testing tests across 16 suites and all 9 UI tests completed with 0
failures. Core-service coverage remains above the 85% gate. The first UI run exposed only an
overly exact assertion against the combined VoiceOver label `Version, 0.9.1`; the corrected test
preserves the useful accessibility label and verifies that it contains the bundle version.

Static policy result: pass — release readiness enforces `0.9.1 (2)` plus matching source-controlled
release notes; localization catalog JSON, floating-point money guard, and `git diff --check` pass.

Signed-device result: installed, launch deferred by lock state — Team ID `2AM5S7BM2N` signed
`com.xdgf558.MindBudget`, and `0.9.1 (2)` was installed in place while preserving the existing app
container. The launch request was denied only because the phone was locked.

Next suggested task: Unlock the iPhone and inspect Settings > About. Decide separately whether the
next focused change should add a brief Reduce-Motion-aware cold-launch brand animation before this
branch is committed and published for review.

## 2026-08-07 — Session 43 — Add the localized cold-launch brand transition

Goal: Add the owner's requested short in-app opening animation without attempting to animate the
system launch screen or delaying fast access to the real app.

Files changed: shared theme presentation, app routing, About UI, bilingual localization, UI
coverage, release notes/checklist, changelog, and redesign/test/project/task/decision/session
memory.

What was completed: Added a selected-skin cold-launch overlay with the existing budget-track mark,
localized `花有数`/`MindBudget` product name, localized subtitle, and a gentle track/marker reveal
that exits in about 0.9 seconds. It is stored in process-local SwiftUI state, so returning from the
background does not replay it. Reduce Motion uses opacity only. The visual layer does not intercept
touches and is hidden from production accessibility, allowing VoiceOver to reach the real prepared
screen immediately. A Debug-only hold argument makes the otherwise sub-second final frame
deterministically inspectable by UI tests and is forced off in Release. Settings > About, the
0.9.1 changelog, and TestFlight notes now disclose the animation.

The first focused UI run exposed SwiftUI accessibility-identifier inheritance from the overlay
container; declaring a containing accessibility element preserved the distinct product-name and
subtitle identifiers. A second assertion showed that hiding the real screen during a decorative
overlay would be the wrong accessibility contract, so the production overlay became nonmodal,
noninteractive, and accessibility-hidden instead. The focused test and complete suite then passed.

What was NOT completed: No production Archive, App Store Connect upload, TestFlight assignment,
commit, push, or PR was performed. Signed-iPhone Reduce Motion, VoiceOver, and visual timing still
require the owner's direct observation.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, Debug build-for-testing, and
current-team signed iPhone Debug build all compile. The signed package remains `0.9.1 (2)` with
Team ID `2AM5S7BM2N` and Bundle ID `com.xdgf558.MindBudget`.

Test result: pass — 204 Swift Testing tests across 16 suites and all 10 UI tests completed with 0
failures. The new UI path verifies the held Simplified Chinese brand animation and subtitle. Every
selected core service remains above the 85% coverage gate.

Static policy result: pass — release readiness, bilingual catalog validation, floating-point money
guard, icon/skin asset checks, JSON parsing, and `git diff --check` all pass.

Signed-device result: installed and launched — the `0.9.1 (2)` package was installed in place on
the connected iPhone without uninstalling or deleting its local container, then cold-launched
successfully for immediate owner inspection.

Next suggested task: Inspect the animation once normally and once with Settings > Accessibility >
Motion > Reduce Motion enabled. If its timing and appearance are approved, commit and publish the
complete skin/brand/animation branch for review before producing the Archive candidate.

## 2026-08-07 — Session 44 — Keep on-device Ask output in the selected language

Goal: Fix the signed-device regression where a Simplified Chinese Ask question received an English
on-device answer and displayed literal dynamic action catalog keys.

Files changed: generated-output validation, Ask response UI, Phase 7 and UI tests, bilingual
release notes, changelog, TestFlight/release guidance, and AI/test/project/decision/task/session
memory.

What was completed: Added a deterministic writing-system check to `AdviceSafetyValidator` for all
three generated-output paths. Simplified Chinese proposals must contain Han text; English proposals
must contain Latin text without Han text. A mismatch now uses the existing
`modelValidatedFallback` path and returns the already-built localized template, so model language
drift cannot create a mixed-language answer. Dynamic Ask action identifiers now resolve through
`LocalizedCatalog` with the active SwiftUI locale instead of interpolation into a
`LocalizedStringKey`, eliminating visible keys such as `ask.action.reviewRecentSpending`. Added a
Chinese validator test, a composite-generator English-to-Chinese fallback test, and an end-to-end
Simplified Chinese UI test that verifies the localized title and both rendered action names.
Settings > About and the 0.9.1 tester notes now disclose the fix.

What was NOT completed: No production Archive, App Store Connect upload, TestFlight assignment,
commit, push, or PR was performed. The marketing/build version remains `0.9.1 (2)` because this is
the same not-yet-uploaded internal candidate.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and complete Debug
build-for-testing both compile.

Test result: pass — 206 Swift Testing tests across 16 suites and all 11 UI tests completed with 0
failures. The focused Phase 7 suite passed 21 tests, and the focused Chinese Ask UI flow also
passed independently.

Static and coverage result: pass — floating-point money, release readiness, localization catalog,
asset, and diff checks pass. Every selected core service remains above 85%; specifically,
`AdviceSafetyValidator.swift` reached 95.65% line coverage.

Signed-device result: pass — team `2AM5S7BM2N` signed bundle `com.xdgf558.MindBudget` version
`0.9.1 (2)` was installed in place on the connected iPhone without uninstalling or clearing local
data, and the app launched successfully.

Next suggested task: On the connected iPhone, repeat the same Simplified Chinese question with
on-device enhancement enabled and confirm either safe Chinese model wording or the complete Chinese
template appears, with localized actions in both cases.

## 2026-08-07 — Session 45 — Restore editable current-budget settings

Goal: Fix the regression where Settings > Budget exposed only read-only currency and cycle-start
information, leaving an already configured user unable to revise the current budget amounts.

Files changed: budget transfer objects and actor writes, the shared budget input builder, Settings
budget UI, bilingual localization, DataActor and UI tests, release notes/checklists, and durable
project, design, decision, test, task, changelog, and session memory.

What was completed: Added an amount-only `CurrentBudgetPlanUpdate` write path that updates the
current plan atomically while preserving its identity, half-open cycle boundaries, accounting
currency, and category-budget identities. The actor revalidates that the referenced plan still
covers an explicitly supplied reference date at commit time, so a page left open across a cycle
boundary fails closed instead of mutating history. Settings > Budget now loads current coverage
without generating plans, displays the locked accounting currency and current cycle, provides
localized exact-minor-unit fields for monthly income, spending budget, fixed expenses, and savings
goal, and uses the single Save Budget action to clear focus, validate the complete draft, persist
the amounts, then apply the chosen future cycle-start day. It shows localized loading, retry,
success, and typed failure states. The About release notes and 0.9.1 tester guidance disclose the
restored editing flow.

What was NOT completed: No production Archive, App Store Connect upload, TestFlight assignment,
commit, push, or PR was performed. Accounting currency and historical plan boundaries remain
intentionally immutable; changing them still requires the documented export/delete/re-onboard or
future-cycle transition flows. The marketing/build version remains `0.9.1 (2)` because this is the
same not-yet-uploaded internal candidate.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, complete Debug
build-for-testing, and the current-team signed iPhone Debug build all compile.

Test result: pass — 208 Swift Testing tests across 16 suites and all 11 UI tests completed with 0
failures. New actor coverage verifies amount changes preserve plan/category identity and rejects a
historical half-open interval atomically. The Settings UI smoke test edits the spending budget,
uses the sole Save Budget action, and observes the saved confirmation.

Static and coverage result: pass — floating-point money, release readiness, localization catalog,
asset, JSON, and diff checks pass. Every selected core service remains above the 85% coverage gate.

Signed-device result: installed and launched — team `2AM5S7BM2N` signed bundle
`com.xdgf558.MindBudget` version `0.9.1 (2)` was installed in place on the connected iPhone without
uninstalling or clearing its local container, then launched successfully.

Next suggested task: On the connected iPhone, open Settings > Budget, revise one amount, tap Save
Budget, and confirm Today reflects the new value while the accounting currency and current cycle
boundaries remain unchanged.

## 2026-08-07 — Session 46 — Rebalance Today's amount and add optional Face ID protection

Goal: Make Today show the concrete amount currently available for the day after a budget is saved,
and add an optional local Face ID app lock without introducing an account or storing biometric data.

Files changed: BudgetEngine and its tests, app environment/router/settings state, Privacy settings,
localized Info.plist and app copy, release-readiness checks, UI and settings tests, release notes, and
durable project/privacy/decision/test/task/changelog/session memory.

What was completed: `BudgetEngine.pace` now presents the engine's deterministic
`safeDailySpend` value as “Today you can spend”. That value is calculated from the remaining
flexible budget after fixed expenses and the savings goal, divided conservatively across the
remaining calendar days, and is rebalanced after saved expenses. It no longer subtracts today's
expenses a second time. A product-owner example is executable: a CNY 6,000 budget with CNY 3,000
fixed expenses and a CNY 500 savings goal on day 7 of a 31-day cycle leaves CNY 2,500 flexible and
shows CNY 100.00 for each of the 25 remaining days. Ask's remaining-budget template also exposes
the deterministic allocation breakdown instead of presenting an unexplained zero.

Added an optional, default-off local app lock. Enabling or disabling it requires local owner
authentication; Face ID is required to offer the setting, authentication uses the system device
owner policy so the device passcode remains a recovery path, and the app never receives or stores
face data. When protection is enabled, inactive/background transitions lock the app, and an opaque
lock surface covers all budget content until authentication succeeds. The app target now contains
a bilingual Face ID purpose string, Privacy settings exposes the control and typed states, deletion
resets the preference, and release notes mention both the daily rebalance and Face ID protection.

What was NOT completed: No production Archive, App Store Connect upload, TestFlight assignment,
commit, push, or PR was performed. Face ID behavior, app-switcher privacy, cancellation, passcode
recovery, and re-entry still require the documented signed-iPhone owner walkthrough because the
simulator cannot establish the production biometric trust flow. The marketing/build version
remains `0.9.1 (2)` because this is the same not-yet-uploaded internal candidate.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, complete Debug
build-for-testing, and the current-team signed physical-iPhone Debug build all compile.

Test result: pass — 216 Swift Testing tests across 16 suites and all 11 UI tests completed with 0
failures. Focused BudgetEngine and SettingsStore coverage passed 29 tests, including the exact CNY
6,000 / 3,000 / 500 allocation, settings persistence/reset, unavailable Face ID, and failed
authentication remaining locked.

Static and coverage result: pass — floating-point money, release readiness, bilingual Face ID
purpose strings, localization catalogs, assets, JSON parsing, and diff checks pass. All selected
core services remain above the 85% coverage gate.

Signed-device result: installed and launched — team `2AM5S7BM2N` signed bundle
`com.xdgf558.MindBudget` version `0.9.1 (2)` was installed in place on the connected physical
iPhone without uninstalling or clearing its local container, then launched successfully.

Next suggested task: On the connected iPhone, confirm the Today amount against the saved budget,
then enable Settings > Privacy > Require Face ID and manually test background locking,
cancellation, Face ID unlock, passcode recovery, and the app-switcher snapshot.

## 2026-08-08 — Session 47 — Complete the free tier with income, 30-day insights, and five open wishes

Goal: Finish the remaining free-tier scope by adding an exact per-entry income ledger, replacing the
short insights window with an in-app rolling 30-calendar-day summary, enforcing at most five open
wishlist items, and advancing the internal candidate version.

Files changed: SwiftData schema and migration, income model/projections/drafts and actor CRUD,
combined ledger and add-entry routing, deterministic Insights UI, wishlist policy and typed errors,
CSV export/privacy deletion, bilingual localization, release metadata and notes, unit/UI tests, and
durable project/privacy/AI/decision/test/task/changelog/session memory.

What was completed: Added `SchemaV2` and a lightweight V1-to-V2 migration for the new `Income`
model. Income values use exact `Int64` minor units and support unlimited manual create, read, update,
delete, search, category, source, note, and received-date workflows. The Log now merges income and
expense rows without changing the configured budget or spending calculations. CSV export uses one
stable bilingual-independent schema with a `record_type` discriminator and includes both ledgers;
full local-data deletion and post-delete verification now cover all ten models. Income notes remain
behind a detail projection and are explicitly excluded from AI inputs.

Insights now calculates the latest 30 complete calendar positions ending today with the injected
user calendar and time zone, shows exact daily totals, and restricts category/emotion breakdowns to
the same half-open range. Wishlist capacity is centralized at five statuses that count as open;
the actor rejects both a sixth insertion and a terminal-to-open transition atomically, while closed
items release a slot. The UI shows the localized count and disables the add action at capacity, and
Siri receives a typed localized limit response. The marketing/build version advanced from
`0.9.1 (2)` to `0.9.2 (3)`; Settings shows only the latest notes by default and keeps older notes in
the existing collapsed history.

The first complete UI run found two automation-contract regressions rather than product logic
failures: the confirmation dialog exposed duplicate identifier nodes, and the old test still looked
for “Last 7 days”. The chooser query now selects its first matching system-dialog node, the income
form identifier no longer propagates over its Save button, and the insight assertion now matches the
30-day product contract. Focused reruns and the final complete suite passed.

What was NOT completed: No signed physical-iPhone install, production Archive, App Store Connect
upload, or TestFlight assignment was performed. Income remains intentionally separate from budget
capacity in this candidate; changing that product rule would require a separate decision and engine
work. App Intents do not yet create income entries, and Ask does not consume raw income rows.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and complete Debug
build-for-testing compile with version `0.9.2 (3)`.

Test result: pass — 223 Swift Testing tests across 17 suites and all 11 UI tests completed with 0
failures. New tests cover exact income CRUD/note boundaries, V1-to-V2 migration, income-inclusive CSV
and deletion, the exact 30-calendar-day boundary, sixth-item rejection, slot reuse, and reopening
protection.

Static and coverage result: pass — release readiness, floating-point money, bilingual localization,
asset/JSON/project parsing, and `git diff --check` pass. Every selected core service remains above
the 85% coverage gate; CSV export is 87.20%, BudgetEngine is 93.41%, and the remaining selected
services range from 90.98% to 100%.

Next suggested task: Review and merge the free-tier completion PR, then install `0.9.2 (3)` on the
signed physical iPhone to walk through income add/edit/delete/search/export, the 30-day empty and
populated insight states, the fifth/sixth wishlist boundary, Face ID protection, and migration from
the existing on-device store before producing the Archive candidate.

## 2026-08-08 — Session 48 — Close free-tier review gaps and restore populated Insights

Goal: Resolve the final free-tier PR review issue where Income inherited hidden expense-only
filters, and fix the device-reported Insights screen retaining zero after a valid expense existed.

Files changed: combined-ledger filtering, Insights loading/selection lifecycle and accessibility
identifiers, Phase 11 and end-to-end UI regression coverage, bilingual current release notes,
TestFlight walkthrough notes, task/decision/changelog/session memory.

What was completed: Income mode now ignores preserved expense-only category and budget-bucket
filters, while All continues to exclude income when those filters are intentionally active and a
return to Expenses restores the user's selections. Insights now refreshes both on selected-tab
entry and saved-data revision, attaches a generation identifier to every request, and prevents an
older cancelled load from replacing newer facts. The deterministic expense summary is published
before cooling-off projections, narrative generation, or derived-pattern persistence, so a failure
in those supplementary paths cannot hide valid 30-day, current-cycle, category, or daily totals.

Regression coverage first loads an empty Insights model, saves an expense, reloads, and verifies
the exact amount/count/cycle/category facts. A corrupt cooling-off projection test proves the same
expense facts remain visible, and the UI flow now opens empty Insights, records USD 12.34 from
another tab, re-enters Insights, and asserts the displayed recent total is 12.34. The `0.9.2 (3)`
in-app and TestFlight notes now call out refresh behavior; the candidate version is unchanged
because it has not yet been uploaded.

What was NOT completed: No production Archive, App Store Connect upload, TestFlight assignment,
merge, or new PR was performed. The existing draft PR remains the delivery vehicle for these fixes.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, complete Debug
build-for-testing, and current-team signed physical-iPhone Debug build compile with version
`0.9.2 (3)`.

Test result: pass — 226 Swift Testing tests across 17 suites and all 11 UI tests completed with 0
failures. The focused Phase 11 suite passed 10 tests, and the populated-Insights end-to-end UI test
also passed independently before the complete run.

Static and coverage result: pass — release readiness, floating-point money, bilingual
localization, asset/JSON/project parsing, and `git diff --check` pass. Every selected core service
remains above the 85% coverage gate; selected coverage ranges from CSV export at 87.20% through
CurrencyFormatterService at 100%.

Signed-device result: installed, launch deferred by lock state — team `2AM5S7BM2N` signed bundle
`com.xdgf558.MindBudget` version `0.9.2 (3)` was installed in place on the connected physical
"拉沙的 iPhone" without uninstalling or clearing its existing local container. The subsequent
remote launch request was correctly denied because the device was locked; the installed app can
be opened normally after the owner unlocks it.

Next suggested task: Review the updated free-tier PR, merge it after approval, then install
`0.9.2 (3)` on the signed physical iPhone and repeat the expense-to-Insights flow against the
existing migrated local store before Archive.

## 2026-08-08 — Session 49 — Unify the Today add-entry chooser

Goal: Fix the device-reported inconsistency where the Today empty-state “Add entry” button opened
the expense form directly while the center Add button correctly asked whether the entry was an
expense or income.

Files changed: Today empty-state routing and accessibility identifier, end-to-end UI coverage,
bilingual current release notes, TestFlight walkthrough notes, changelog, and session memory.

What was completed: The Today empty-state action now uses the same centralized add-entry chooser as
the center Add button and the Log empty state. Its identifier was renamed from the misleading
`dashboard.empty.addExpense` to `dashboard.empty.addEntry`, and its copy now uses the generic
`entry.quickAdd` key. The primary onboarding-to-ledger UI flow now taps this exact empty-state
button, requires both Expense and Income actions to exist, records the expense through it, then
uses the center Add button for income. The `0.9.2 (3)` in-app notes and TestFlight walkthrough now
state that every generic Add entry action asks for the record type before opening a form.

What was NOT completed: No merge, production Archive, App Store Connect upload, or TestFlight
assignment was performed. Explicit “Record expense” actions remain allowed to open the expense
form directly; only generic “Add entry” actions are required to offer the chooser.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build, complete Debug
build-for-testing, and current-team signed physical-iPhone Debug build compile with version
`0.9.2 (3)`.

Test result: pass — 226 Swift Testing tests across 17 suites and all 11 UI tests completed with 0
failures. The onboarding/manual-ledger UI flow also passed independently after being changed to
exercise the Today empty-state chooser directly.

Static and coverage result: pass — release readiness, floating-point money, bilingual
localization, asset/JSON/project parsing, and `git diff --check` pass. Every selected core service
remains above the 85% coverage gate; selected coverage ranges from CSV export at 87.20% through
CurrencyFormatterService at 100%.

Signed-device result: installed — team `2AM5S7BM2N` signed bundle
`com.xdgf558.MindBudget` version `0.9.2 (3)` was installed in place on the connected physical
“拉沙的 iPhone” without uninstalling or clearing its existing local container.

Next suggested task: On the connected iPhone, tap the Today empty-state “记一笔” action and confirm
the “记支出 / 记收入” chooser appears, then finish review and merge PR #16 before producing the
Archive candidate.

## 2026-08-08 — Session 50 — Keep initial income and spending budget independent

Goal: Fix the device-reported setup behavior where typing a monthly income automatically copied
the same amount into the spending-budget field.

Files changed: Initial budget-setup state handling, Phase 3 and end-to-end UI regressions,
bilingual current release notes, TestFlight walkthrough notes, changelog, decision memory, and
session memory.

What was completed: The initial setup form no longer mirrors monthly income into spending budget
or overwrites a spending-budget amount the user has already entered. The two values remain
independent inputs, and saving still validates the complete explicit draft. Regression coverage
proves both the initially empty spending-budget field and a later user-entered value survive
monthly-income edits. Every UI setup flow now enters both values explicitly, and the simplified
Chinese flow verifies that entering income alone does not populate the spending budget. The
`0.9.2 (3)` in-app notes and TestFlight walkthrough now describe this correction.

What was NOT completed: No merge, production Archive, App Store Connect upload, TestFlight
assignment, or version/build-number change was performed. This remains a correction to the same
not-yet-uploaded `0.9.2 (3)` candidate in draft PR #16.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and complete Debug
build-for-testing compile successfully.

Test result: pass — 227 Swift Testing tests and all 11 UI tests completed with 0 failures. The
focused Phase 3 regression and simplified-Chinese setup UI flow also passed independently.

Static and coverage result: pass — release readiness, floating-point money, bilingual
localization, asset/JSON/project parsing, and `git diff --check` pass. Every selected core service
remains above the 85% coverage gate; selected coverage ranges from CSV export at 87.20% through
CurrencyFormatterService at 100%.

Signed-device result: installed and launched — team `2AM5S7BM2N` signed bundle
`com.xdgf558.MindBudget` version `0.9.2 (3)` was installed in place on the connected physical
“拉沙的 iPhone” without uninstalling or clearing its existing local container, then launched
successfully for immediate verification.

Next suggested task: On the connected iPhone, confirm that entering monthly income leaves spending
budget untouched, then finish review and merge PR #16 before producing the Archive candidate.

## 2026-08-08 — Session 51 — Fail closed on incomplete cooling-off insight data

Goal: Address the PR review finding that an unreadable cooling-off projection was treated as an
empty result, allowing Insights narrative, model enhancement, pattern persistence, and stale cards
to continue with outcome counts that were unknown rather than zero.

Files changed: Insights load state and partial-results presentation, Phase 11 regression coverage,
bilingual current release notes, TestFlight walkthrough notes, AI/test/task/project/decision memory,
changelog, and session memory.

What was completed: Insights still publishes its validated recent-30-day and current-cycle expense
facts first. If the cooling-off projection then fails, the load now exposes a localized partial-data
warning and returns before cycle narrative generation, optional on-device wording enhancement,
pattern detection/upsert, or stored-card reload. It does not delete or repair the unreadable record;
the existing explicit Settings repair flow remains the only cleanup path. The regression preloads a
current-cycle cooling-off-success card, introduces a corrupt cooling-off row, and proves the exact
expense amount/count remains while the narrative and all stored cards are absent. Durable AI and
test contracts now state that unreadable cooling outcomes are unknown and must never become zero
facts in model context.

What was NOT completed: No data was automatically deleted, no production Archive, App Store
Connect upload, TestFlight assignment, merge, signed-device install, or version/build-number change
was performed. This remains a correction to the same not-yet-uploaded `0.9.2 (3)` candidate in draft
PR #16.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and complete Debug
build-for-testing compile successfully.

Test result: pass — 227 Swift Testing tests and all 11 UI tests completed with 0 failures. The
focused Phase 11 suite passed all 10 tests, including the stale cooling-success regression.

Static and coverage result: pass — release readiness, floating-point money, bilingual
localization, asset/JSON/project parsing, and `git diff --check` pass. Every selected core service
remains above the 85% coverage gate; selected coverage ranges from CSV export at 87.20% through
CurrencyFormatterService at 100%.

Next suggested task: Re-review the updated PR #16 and merge it after approval, then install the
unchanged `0.9.2 (3)` candidate on the signed physical iPhone for final device verification before
Archive.

## 2026-08-08 — Session 52 — Reinstall the reviewed candidate on the physical iPhone

Goal: Rebuild and reinstall the latest PR #16 candidate on the connected physical iPhone for
continued owner testing without clearing its local data.

Files changed: Session memory only.

What was completed: Commit `5f0dcd5` was built as a signed Debug iPhoneOS app with Xcode 26.6,
bundle `com.xdgf558.MindBudget`, version `0.9.2 (3)`, and current team `2AM5S7BM2N`. The resulting
app was installed in place on the connected physical “拉沙的 iPhone”; no uninstall or container
reset was performed, so the existing local budget and ledger data should remain available.

What was NOT completed: The remote launch request was denied because the iPhone was locked. No
production Archive, App Store Connect upload, TestFlight assignment, merge, version/build-number
change, or user-data deletion was performed.

Build result: pass — current-team signed physical-iPhone Debug build completed successfully.

Test result: not rerun for this installation-only session. The installed code commit had already
passed 227 Swift Testing tests, all 11 UI tests, the full local validation script, and GitHub CI.

Next suggested task: Unlock the iPhone, open 花有数 manually, and continue the PR #16 device
walkthrough with the preserved local store.

## 2026-08-08 — Session 53 — Anchor Today's allowance and scroll every expense category

Goal: Fix signed-device findings that a newly saved expense barely changed "Left to spend today"
and that the expense category interaction did not scale cleanly to the complete category set.

Files changed: budget pace engine and tests, Today pace card, expense category selector, Phase 3
UI regression, bilingual strings, in-app release notes, version/build metadata, TestFlight and
release-readiness notes, changelog, product/test/decision/task memory, and session memory.

What was completed: `BudgetEngine` now reconstructs the flexible amount available at the start of
the user's local calendar day, divides that amount across the remaining days, and subtracts every
discretionary expense recorded today exactly once. The visible Today value clamps at zero while an
exact positive overage remains available for explanation. Zero/overage presentation uses the
destructive color together with an icon, localized gentle wording, and a combined VoiceOver value;
fixed and savings-bucket expenses do not consume this flexible daily reference. Add Expense now
places all 17 persisted categories in stable order inside one horizontally scrollable selector,
centers programmatic selections, and exposes a selected accessibility trait. The old recent-category
shortcut state and separate modal category list were removed. Replacement candidate metadata and
release notes now identify `0.9.2 (4)`, preserving already-uploaded build 3 as history.

What was NOT completed: No signed physical-iPhone install, Archive, Organizer validation, App Store
Connect upload, TestFlight tester assignment, commit, push, PR creation, or merge was performed.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and complete Debug
build-for-testing succeeded. An initial sandboxed validation attempt could not access DerivedData or
CoreSimulator; rerunning with the normal local Xcode permissions completed successfully.

Test result: pass — 228 Swift Testing tests across 17 suites and all 11 UI tests completed with zero
failures. New deterministic coverage proves that a 5,000-minor-unit discretionary expense reduces
Today's amount by exactly 5,000, and the end-to-end expense flow proves that Dashboard's accessible
Today value changes after save, can swipe from the first category to the final `Other` category,
announces selection, persists it, and shows it in Log.

Static and coverage result: pass — floating-point money, release readiness, bilingual localization,
asset/JSON/project parsing, and `git diff --check` pass. Every selected core service remains above
the 85% gate; coverage ranges from CSV export at 87.20% through CurrencyFormatterService at 100%,
with BudgetEngine at 93.80%.

Next suggested task: Install the `0.9.2 (4)` branch build on the signed physical iPhone and verify
one-for-one deduction, zero/overage wording, horizontal category swipe, Dynamic Type, and VoiceOver
before opening the review PR or producing the replacement TestFlight Archive.

## 2026-08-08 — Session 54 — Install the daily-allowance candidate on the physical iPhone

Goal: Build and install the current `0.9.2 (4)` branch candidate on the connected physical iPhone
so the owner can verify the anchored Today amount and horizontally scrollable category selector.

Files changed: Session memory only.

What was completed: Xcode 26.6 identified the paired physical “拉沙的iPhone” and built the current
working tree as a signed Debug iPhoneOS app. The product reports bundle
`com.xdgf558.MindBudget`, version `0.9.2 (4)`, and team `2AM5S7BM2N`. The app was installed in place;
no uninstall or container reset was performed, so the existing local budget and ledger data should
remain available.

What was NOT completed: iOS denied the remote launch because the development profile has not yet
been explicitly trusted or verified on the device. The owner must keep the phone online and finish
the Development App trust/verification step in Settings before opening the app. No Archive, App
Store Connect upload, TestFlight assignment, commit, push, PR creation, merge, or data deletion was
performed.

Build result: pass — current-team signed physical-iPhone Debug build completed successfully.

Test result: not rerun for this installation-only session. The exact installed working tree had
already passed 228 Swift Testing tests, all 11 UI tests, the complete validation script, release
readiness, and the floating-point money policy before installation.

Next suggested task: Complete the device trust/online verification step, open 花有数 manually, and
test one-for-one Today deduction, zero/overage presentation, and the full horizontal category list.

## 2026-08-08 — Session 55 — Publish the daily-allowance fix for review

Goal: Pause the requested TestFlight upload and publish the current daily-allowance/category
interaction candidate as a reviewable pull request before changing its marketing version.

Files changed: Session memory only, in addition to the previously completed candidate diff.

What was completed: Restored the owner's GitHub CLI authorization through the official device
flow, committed the complete verified `0.9.2 (4)` working tree as `0850d64`, pushed branch
`codex/daily-allowance-category-scroll`, and opened draft PR #17 against `main`. The PR describes
the start-of-day allowance root cause, one-for-one deduction, zero/overage presentation, complete
horizontal category selector, and full validation evidence.

What was NOT completed: The requested `0.9.3` marketing-version promotion, new release notes,
Archive, Organizer validation, App Store Connect upload, build processing, and TestFlight tester
assignment were explicitly paused until the owner reviews and approves PR #17.

Validation result: pass — the published commit had already passed 228 Swift Testing tests, all 11
UI tests, the generic Release build, coverage gates, floating-point money policy, release-readiness
checks, catalog parsing, and `git diff --check` before publication.

Next suggested task: Review PR #17. After approval and merge, promote the next upload candidate to
`0.9.3`, synchronize its in-app/changelog/TestFlight notes, validate, Archive under team
`2AM5S7BM2N`, and upload build 4 to the existing App Store Connect record.

## 2026-08-08 — Session 56 — Localize Log filters and reserve PR 18 scope

Goal: Keep TestFlight paused, correct the signed-device raw localization keys inside PR #17, and
record—but not implement—the owner-approved language/income/savings/recurring-expense work for a
separate PR #18.

Files changed: Log filter and expense detail presentation, typed budget/record localization keys,
bilingual release-note catalog, localization and UI tests, current changelog/TestFlight guidance,
test/product/task/decision memory, and this session log.

What was completed: `LedgerRecordType` and `BudgetBucket` now own stable localization-key
properties. The Log filter resolves all three record types and all three budget buckets through
those typed keys, and expense detail uses the same budget-bucket boundary. Simplified Chinese now
renders `全部` / `支出` / `收入` and `固定` / `灵活` / `储蓄` instead of catalog keys in Debug,
Release, or TestFlight. Added deterministic bilingual bundle coverage plus an end-to-end Chinese UI
test that opens the filter, checks every option, and rejects visible `ledger.type.*` / `bucket.*`
text. Current `0.9.2 (4)` About, changelog, and tester notes disclose the correction.

The requested app-language switch, explicit multiple-income planning relationship, cross-cycle
total savings goal, and monthly recurring fixed-expense rules are recorded as Phase 12 Todo. The
scope explicitly requires an extensible locale boundary, user-confirmed money allocation,
separate savings semantics, calendar-safe deduplication, and a Schema V3 decision before code. No
part of that larger product expansion was implemented or mixed into PR #17.

What was NOT completed: TestFlight remained paused. No Archive, Organizer validation, App Store
Connect upload, tester assignment, PR #18 implementation, Schema V3 change, merge, or version/build
promotion was performed.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and complete Debug
build-for-testing succeeded.

Test result: pass — 229 Swift Testing tests across 17 suites and all 12 end-to-end/localization UI
tests completed with zero failures. The first targeted UI launch was refused by a busy simulator;
after a clean simulator restart, the same test passed, followed by the complete suite without a
retry-on-failure policy.

Static and coverage result: pass — floating-point money, release readiness, bilingual catalog and
JSON parsing, and `git diff --check` pass. Every selected core service remains above the 85% gate;
coverage ranges from CSV export at 87.20% through CurrencyFormatterService at 100%, with
BudgetEngine at 93.80%.

Next suggested task: Review the updated draft PR #17. After approval and merge, begin Phase 12 on a
new branch and publish its completed, migrated, fully validated implementation as PR #18; do not
resume TestFlight until the owner explicitly asks after that review.

## 2026-08-08 — Session 57 — Explain a zero allowance before today's first expense

Goal: Address PR #17 review feedback that a cycle with no distributable flexible allowance could
show an unexplained zero before the user recorded any expense that day.

Files changed: budget pace presentation facts and tests, Today card, bilingual catalog and
localization coverage, Chinese UI regression, current release/TestFlight notes, project/test/
decision memory, changelog, and this session log.

What was completed: `BudgetPaceSummary` now distinguishes a pre-spend zero daily allowance from an
allowance used or exceeded by today's expenses. Today renders that zero with the existing attention
color, icon, and a neutral localized explanation that the current cycle has no distributable daily
flexible amount. The wording deliberately avoids claiming the whole flexible balance is exhausted,
because exact integer division can also produce a zero daily amount when a smaller balance remains.
Engine coverage fixes the zero/zero/no-expense boundary, bilingual bundle coverage fixes the exact
copy, and the existing Simplified Chinese onboarding path now exercises the fully allocated plan
and verifies the visible notice.

What was NOT completed: TestFlight remained paused. No Archive, Organizer validation, App Store
Connect upload, tester assignment, PR #18 implementation, Schema V3 change, merge, or version/build
promotion was performed.

Build result: pass — Xcode 26.6 generic iOS Simulator Release build and complete Debug
build-for-testing succeeded. The first sandboxed attempt could not access DerivedData or
CoreSimulator; rerunning the unchanged validation with normal local Xcode permissions passed.

Test result: pass — 231 Swift Testing tests across 17 suites and all 12 end-to-end/localization UI
tests completed with zero failures. BudgetEngine coverage is 93.87%, and every selected core
service remains above the 85% coverage gate.

Next suggested task: Re-review the focused correction on draft PR #17 before any merge or
TestFlight work.

## 2026-08-08 — Session 58 — Complete Phase 12 and prepare PR 18

Goal: Implement the owner-approved app-language, explicit income-allocation, total savings-goal,
and monthly recurring fixed-expense scope as a separately migrated and reviewable PR #18, while
keeping TestFlight paused and promoting the internal candidate to `0.9.4 (5)`.

Files changed: Schema V3 models and migration, DataActor and transfer projections, BudgetEngine,
income and expense entry flows, Settings and app locale plumbing, CSV export and privacy controls,
bilingual string catalog, release-note catalog and version metadata, unit/UI/migration tests,
release scripts and documentation memory.

What was completed: Settings now offers an extensible Follow System / Simplified Chinese / English
language choice that drives the SwiftUI locale, deterministic Ask/template formatting, localized
search and export filenames, and triggers app-owned notification/Spotlight reconciliation. Each
income remains an independent exact ledger row and may optionally allocate owner-entered portions
to the containing cycle's spending budget and/or the separate total savings goal; recording income
alone still cannot increase spending permission, and the allocation sum cannot exceed the income.
The total savings goal stores one cross-cycle target and starting balance, with progress calculated
from confirmed savings allocations rather than reinterpreting the existing per-cycle reservation.
User-confirmed monthly fixed-expense rules now preserve their calendar and time zone, clamp short
months, use stable rule/month occurrence identities, reconcile missed dates idempotently, and
support edit, pause, resume, and delete while preserving ledger history. Reconciliation is capped
at 120 generated occurrences and rolls back atomically on overflow. Schema V3 adds only companion
models, preserving the shipped Schema V2 Income shape; migration tests verify existing income rows
remain intact with zero invented allocation. CSV disclosure/export and Delete All cover every new
model. The installed candidate and localized About notes identify version `0.9.4`, build `5`.

What was NOT completed: TestFlight remained paused. No Archive, Organizer validation, App Store
Connect upload, build processing, tester assignment, PR merge, or deferred replacement app-icon
work was performed.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build and the
full Debug validation. All 242 Swift Testing tests and all 12 end-to-end/localization UI tests
passed with zero failures. A first full UI run exposed only an outdated test assumption that a
newly lower budget preview remained onscreen; the test now scrolls to that existing element, and
the complete suite passed without retry-on-failure masking.

Static and coverage result: pass — floating-point money, release readiness, bilingual catalog JSON,
and core-service coverage gates pass. Every selected core service remains above 85%, ranging from
CSV export at 87.60% through CurrencyFormatterService at 100%; BudgetEngine is 93.90%.

Next suggested task: Review draft PR #18. After owner approval and merge, decide whether to replace
the deferred app-icon assets before explicitly resuming Archive and TestFlight work.

## 2026-08-08 — Session 59 — Harden Phase 12 release contracts and replace the app icon

Goal: Address the PR #18 review observations without broadening Phase 12, replace all three App
Icon appearances with the owner's enlarged pace-mark revision, and keep TestFlight paused for
another review.

Files changed: model-count projection and deletion tests, unified CSV export and tests, recurring
calendar coverage, three App Icon SVG/PNG variants and checksum contract, localized 0.9.4 release
notes, release/TestFlight documentation, test/decision/project memory, changelog, and this log.

What was completed: `ModelCounts` no longer supplies defaults for persisted-table counts; both the
production actor and the explicit `.zero` fixture must enumerate all fourteen current tables, so a
future model addition cannot silently weaken verified Delete All. Income CSV rows now leave the
four expense-only planned/recurring/source/index-consent fields empty instead of inventing
`false`/`manual` facts. The stable 22-column header is asserted from an independent literal, with
the two Phase 12 allocation fields appended after the prior unified-ledger columns, and release
notes tell users to update saved import/formula templates. Recurring coverage now directly proves
a January 31 rule lands on February 29 in a leap year and remains idempotent, in addition to the
existing February 28, March 31, and April 30 checks. The owner-supplied enlarged budget-track icon
now ships as opaque 1024×1024 standard, dark, and luminance-separated tinted resources without a
pre-rendered corner mask; matching editable SVGs, manifest hashes, bilingual About copy, and
physical-device appearance checks were updated.

What was NOT completed: TestFlight remained paused. No Archive, Organizer validation, App Store
Connect upload, build processing, tester assignment, PR merge, signing change, or unrelated
feature work was performed.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build and full
Debug validation. All 243 Swift Testing tests and all 12 end-to-end/localization UI tests passed
with zero failures. The new leap-year recurrence, CSV empty-field, independent-header, localized
release-note, and full deletion assertions all passed.

Static and coverage result: pass — floating-point money, release readiness, App Icon source/
artifact checksums, opaque 1024px image checks, bilingual string-catalog JSON, and
`git diff --check` pass. Every selected core service remains above 85%, ranging from CSV export at 87.60%
through CurrencyFormatterService at 100%; BudgetEngine is 93.90%.

Next suggested task: Re-review the updated draft PR #18. Merge only after approval, then explicitly
decide when to resume Archive and TestFlight work for version `0.9.4 (5)`.

## 2026-08-09 — Session 60 — Close PR 18 review gaps

Goal: Address the four P2 findings from the second PR #18 review without changing the approved
Phase 12 product scope or resuming TestFlight.

Files changed: app-language persistence and observation, Schema V3 allocation/recurring companion
fields, DataActor validation and reconciliation, income and recurring-rule forms, bilingual copy,
unit/UI tests, release/TestFlight documentation, project decisions and memory, changelog, and this
log.

What was completed: The app-language setting is now explicit persisted `@Published` state, so a
selection invalidates the root locale immediately and the current screen changes language without
a relaunch. Every nonzero income-to-spending allocation now stores an explicit target BudgetPlan;
the actor requires that plan to exist, match the accounting currency, and contain the income date,
while the form displays its exact cycle and refuses allocation when a historical date has no saved
plan. Savings allocation remains cross-cycle and independent. Recurring rules now preserve an
immutable initial-occurrence date separately from the editable future anchor, so moving a January
rule into February cannot skip February. Reconciliation collects and deduplicates all pending
occurrences before writing, applies the 120-occurrence limit across the combined batch, and rolls
back the complete transaction on overflow.

What was NOT completed: TestFlight remained paused. No Archive, Organizer validation, App Store
Connect upload, tester assignment, merge, signing change, or additional product feature was
performed.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build and full
Debug validation. All 248 Swift Testing tests across 17 suites and all 13 end-to-end/localization UI
tests passed with zero failures. The new coverage proves language publication without relaunch,
explicit dated-plan allocation rejection, edited-anchor month generation, and combined cross-rule
rollback. The first sandboxed validation could not access DerivedData/CoreSimulator; rerunning the
unchanged command with normal local Xcode permissions passed.

Static and coverage result: pass — floating-point money, release readiness, bilingual catalog JSON,
App Icon source/artifact checksums, opaque 1024px resources, and `git diff --check` pass. Every
selected core service remains above 85%, ranging from CSV export at 87.60% through
CurrencyFormatterService at 100%; BudgetEngine is 93.90%.

Next suggested task: Re-review the correction on draft PR #18 before merge or any TestFlight action.

## 2026-08-09 — Session 61 — Make recurring catch-up recoverable

Goal: Close the remaining PR #18 blocking review item by replacing the permanent recurring-expense
overflow failure with bounded, resumable work, while confirming the income-allocation integrity
check and auditing root-level settings observation.

Files changed: recurring schedule and reconciliation projections, AppSession preparation, settings
persistence and publication, recurring/settings tests, Phase 12 project memory, decisions, task and
test plans, App Store submission checklist, changelog, and this log.

What was completed: Recurring reconciliation now discovers missing occurrences by stable
rule/month identity, globally orders them by scheduled date, and atomically inserts only the oldest
120 rows per foreground transaction. It returns an explicit `hasMore` result instead of throwing;
the next foreground activation continues with the remaining rows, so a long closure or many rules
cannot create a permanent failure loop. Tests prove a 122-row single-rule backlog and a 122-row
two-rule backlog complete over two passes, remain chronological, and become idempotent. AppSession
publishes backlog progress separately from actual reconciliation failure and now passes the
environment calendar through initial preparation as well as foreground refresh. Skin and language
are explicit persisted `@Published` root state with centralized storage keys, so both redraw the
root presentation immediately. The income-allocation cross-check was retained after confirming it
compares cycle-scoped incomes with the store-wide allocation map and therefore detects an
out-of-cycle income incorrectly targeting the plan.

What was NOT completed: TestFlight remained paused. No Archive, Organizer validation, App Store
Connect upload, tester assignment, merge, signing change, or new product feature was performed.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. The
full functional validation ran 249 Swift Testing tests with the repository's wall-clock-only test
excluded from the concurrent suite, and all 13 end-to-end/localization UI tests passed with zero
failures. The excluded strict 10,000-row Dashboard benchmark was then run independently on an idle
simulator and passed together with its deterministic 10,000-row projection companion. An initial
full run under concurrent load recorded only that known wall-clock signal at 0.770 seconds; no
functional test failed.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual catalog JSON, and `git diff --check` pass. Every selected core
service remains above 85%, ranging from CSV export at 87.60% through CurrencyFormatterService at
100%; BudgetEngine is 93.90%.

Next suggested task: Re-review the bounded recurring catch-up correction on draft PR #18. Merge
only after approval; keep TestFlight paused until the owner explicitly resumes it.

## 2026-08-09 — Session 62 — Surface and bound recurring catch-up progress

Goal: Close the final PR #18 review observations by making resumable recurring catch-up visible,
removing duplicate occurrence-key work, bounding calendar scanning, and independently confirming
the reported CI state.

Files changed: recurring schedule projections and reconciliation, recurring-expense settings UI,
bilingual copy, recurring/localization tests, Phase 12 project memory, task/test/release plans,
decisions, changelog, and this log.

What was completed: Settings now consumes `recurringExpenseReconciliationHasMore` and displays a
neutral bilingual progress notice while older fixed expenses remain to be added. Each pending
recurring occurrence now carries the stable year-month key computed during discovery, so
reconciliation does not calculate the same identity a second time. The monthly schedule scan is
explicitly limited to 1,200 examined months and fails closed with a typed validation error if
calendar behavior cannot reach an existing occurrence or the requested end date within that
bound. A regression fixture fills the entire bounded identity window and proves the guard throws
instead of hanging the foreground actor. The previously reported GitHub `0 / 1` state was also
verified as transient: run 31286727862 and its build-and-test job completed successfully.

What was NOT completed: TestFlight remained paused. No Archive, Organizer validation, App Store
Connect upload, tester assignment, PR merge, signing change, or new product feature was performed.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build and
full validation. All 250 Swift Testing tests across 17 suites and all 13 end-to-end/localization
UI tests passed with zero failures. The strict local 10,000-row Dashboard benchmark was then run
separately on an idle simulator and passed together with its deterministic projection companion.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual catalog JSON, and `git diff --check` pass. Every selected core
service remains above 85%, ranging from CSV export at 87.60% through CurrencyFormatterService at
100%; BudgetEngine is 93.90%.

Next suggested task: Re-review the final correction on draft PR #18. Merge only after approval;
keep TestFlight paused until the owner explicitly resumes it.

## 2026-08-09 — Session 63 — Install 0.9.4 on the physical iPhone

Goal: Build the approved `main` revision with the current China-region development team and
install it on the owner's connected physical iPhone for another hands-on test pass.

Files changed: this log only.

What was completed: The merged PR #18 revision `caa0acf` was built as MindBudget `0.9.4 (5)` for
the wired iPhone named “拉沙的iPhone” running iOS 26.0. The signed app uses bundle identifier
`com.xdgf558.MindBudget` and team identifier `2AM5S7BM2N`, then installed successfully through
CoreDevice. The development certificate holder remains displayed as Hao Ye, while the signed
application entitlement and provisioning team are the current team identifier.

What was NOT completed: The device was locked when the automatic launch was requested, so iOS
denied only that launch request; installation had already succeeded and the owner can unlock the
phone and open the app normally. No Archive, TestFlight upload, tester assignment, code change,
data reset, or signing-account change was performed.

Build result: pass — Xcode 26.6 completed the arm64 Debug device build and automatic development
signing without requesting account credentials.

Next suggested task: Test `0.9.4 (5)` on the physical iPhone and report any remaining product or
presentation issues before TestFlight work resumes.

## 2026-08-09 — Session 64 — Diagnose cycle usage and on-device AI fallback display

Goal: Diagnose two physical-device observations without changing product behavior: a cycle
snapshot that reports zero percent despite recorded spending, and Ask returning a local template
after the on-device enhancement toggle was enabled.

Files changed: this log only.

What was completed: The recorded-expense aggregation was confirmed healthy because the same
Insights load shows CNY 236 for both the recent window and current cycle. The narrative path was
found to collapse an unconfigured snapshot, a zero-valued budget denominator, and any positive
ratio below one percent into the integer value `0`; therefore its “0%” wording is not an honest
representation of every supported state. The Ask path was also confirmed to label every non-model
source as “Local template”: runtime unavailability, the 2.5-second model timeout, safety/language
validation failure, and other model errors are indistinguishable on the answer card. The Debug
settings screen retains per-reason fallback counters, but the response itself does not expose the
reason. A subsequent physical-device screenshot confirmed Apple Intelligence reports available
and the recorded fallback category is exactly one safety-validation failure, ruling out the user
toggle, runtime availability, and timeout for that request. The current diagnostic intentionally
does not retain generated text or the specific `AdviceSafetyViolation`, so it cannot distinguish
language, numeric, action, length, empty-field, or banned-copy rejection after the fact.

What was NOT completed: No business logic, localization, timeout, model prompt, validator, UI,
test, Archive, or TestFlight change was made. No user financial data was copied from the device.

Next suggested task: Replace the cycle percentage integer with an explicit availability/under-one-
percent/percentage state and show a truthful localized message. Separately expose a safe fallback
reason on Ask responses and use the existing Debug diagnostic counters to identify whether this
device is hitting availability, timeout, validation, or model-error fallback before changing the
model policy.

## 2026-08-09 — Session 65 — Fix cycle usage wording and on-device Ask fallback

Goal: Correct the two physical-device findings diagnosed in Session 64 without weakening the
project's deterministic budget arithmetic, AI safety validator, numeric allow-list, or privacy
boundary.

Files changed: cycle-summary aggregate/redaction state and narrative service, Ask generation and
source metadata, safety diagnostics, Ask and Debug settings UI, bilingual String Catalog entries,
Phase 7 and end-to-end localization tests, AI/project/test contracts, decisions, changelog, and
this log.

What was completed: Cycle usage is now a closed unavailable / less-than-one-percent / exact whole
percent state instead of one ambiguous integer. Only a configured positive budget with exactly
zero recorded spending may render 0%; a small positive spend says less than 1%, and a missing or
non-positive denominator says the budget baseline is unavailable. These states flow through the
redacted summary context without inventing a percentage. The sub-one-percent state contributes no
numeric percentage token, so an exact generated percentage fails closed to the local template.

Ask now differentiates enhancement unavailable, timeout, safety-validation fallback, and an
unexpected model error on the answer card while always returning the complete deterministic local
answer. Foundation Models generate only title and body; suggested action labels are attached from the
redacted app-owned allow-list after its construction contract is checked, removing the avoidable
failure mode where the wording model attempted to reproduce internal action identifiers. Ask
language, numeric, length, banned-copy, and empty-field validation remains fail-closed; generated
actions remain validated on reminder and summary paths. Debug
builds also retain aggregate counts for each typed safety violation without retaining prompts,
generated text, questions, or financial facts.

What was NOT completed: No Archive, TestFlight upload, tester assignment, physical-device install,
version/build change, signing change, merge, or unrelated product feature was performed.
TestFlight remains paused and the candidate version remains `0.9.4 (5)`.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
functional validation passed all 253 Swift Testing tests across 17 suites and all 13
end-to-end/localization UI tests with zero failures while the wall-clock-only benchmark was
excluded from the concurrent suite. The strict 10,000-row Dashboard benchmark was then run
independently on an idle simulator and passed together with its deterministic projection
companion.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every selected
core service remains above the 85% gate, ranging from CSV export at 87.60% through
CurrencyFormatterService at 100%; the directly changed CycleSummaryService is 97.37%,
AdviceSafetyValidator is 95.65%, PrivacyRedactor is 92.59%, and ReminderEngine is 91.00%.

Next suggested task: Review the focused draft PR and repeat the previously failing Insights and
Ask scenarios on the physical iPhone after approval. Keep TestFlight paused until that hands-on
verification is complete.

## 2026-08-09 — Session 66 — Close PR #19 AI validation review findings

Goal: Address the four follow-up review findings without weakening reminder or summary action
validation and without widening the data supplied to Foundation Models.

Files changed: Ask redaction and generation services, the safety validator, Phase 7 tests, the AI
prompt/project/test contracts, decisions, changelog, and this log.

What was completed: Ask suggested actions are now checked as an app-owned construction contract
at the redaction boundary. A true affordability decision must provide two to four unique actions
including Continue Purchase, while informational Ask intents may provide none. Because Ask actions
are never model output, Ask safety validation now checks generated title/body, language, banned
copy, length, and numeric truthfulness only; reminder and summary paths continue to validate their
generated actions. The less-than-one-percent budget state exposes no numeric percentage fact, so a
model that states an exact 1% fails closed. Numeric tokenization treats a hyphen between digits as
a separator rather than a unary negative sign, so `2026-08` permits truthful Chinese wording such
as `2026 年 8 月` without admitting `-8`. Chinese generated copy must also contain at least as many
Han characters as Latin letters, preventing a mostly-English answer with a token Chinese phrase
from passing. Ask generation now reuses the shared timeout helper, and all production
affordability-action branches are covered by deterministic regression tests.

What was NOT completed: No Archive, TestFlight upload, tester assignment, physical-device install,
version/build change, signing change, merge, or unrelated product feature was performed.
TestFlight remains paused and the candidate version remains `0.9.4 (5)`.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
functional validation passed all 255 Swift Testing tests across 17 suites and all 13
end-to-end/localization UI tests with zero failures while the wall-clock-only benchmark was
excluded from the concurrent suite. The strict 10,000-row Dashboard benchmark then passed
independently together with its deterministic projection companion.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every selected
core service remains above the 85% gate; the directly changed AdviceSafetyValidator is at 95.42%
and PrivacyRedactor is at 91.65%.

Next suggested task: Re-review the updated draft PR #19. After approval, merge it and repeat the
previously failing Insights and Ask scenarios on the physical iPhone before resuming TestFlight.

## 2026-08-09 — Session 67 — Bind generated percentages to their budget fact

Goal: Close the remaining PR #19 truthfulness gap where an unrelated zero-valued aggregate could
authorize a false generated `0%` cycle-usage statement.

Files changed: Summary numeric validation and its regression tests, the AI prompt/project/test
contracts, decisions, changelog, and this log.

What was completed: Generated numeric percentage expressions are now checked against the closed
`SummaryBudgetUsage` fact in addition to the general numeric allow-list. Unavailable and
less-than-one-percent states permit no numeric percentage expression; an exact percentage state
permits only its own integer. ASCII `%`, full-width `％`, and optional spacing before the sign are
handled consistently. Zero-valued cooling-off counts can therefore no longer make a false `0%`
claim valid, while a configured exact-zero state still permits a truthful `0%`. Tests cover the
unavailable, sub-one-percent, exact-zero, exact-eight-percent, unrelated-zero, and full-width-sign
cases. A stale test fixture name was also corrected to reflect that Ask action identifiers are
app-owned rather than model-authoritative.

What was NOT completed: No Archive, TestFlight upload, tester assignment, physical-device install,
version/build change, signing change, merge, or unrelated product feature was performed.
TestFlight remains paused and the candidate version remains `0.9.4 (5)`.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
functional validation passed all 256 Swift Testing tests across 17 suites and all 13
end-to-end/localization UI tests with zero failures while the wall-clock-only benchmark was
excluded from the concurrent suite. The strict 10,000-row Dashboard benchmark then passed
independently together with its deterministic projection companion.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every selected
core service remains above the 85% gate; the directly changed AdviceSafetyValidator is at 95.60%
and PrivacyRedactor is at 92.02%.

Next suggested task: Re-review the updated draft PR #19. After approval, merge it and repeat the
previously failing Insights and Ask scenarios on the physical iPhone before resuming TestFlight.

## 2026-08-09 — Session 68 — Bind percentages across every generated-output path

Goal: Close the final PR #19 review gap where Ask or reminder text could borrow an unrelated
zero-valued count to authorize a false `0%` statement even though summary validation was already
fact-bound.

Files changed: advice/Ask/summary percentage validation and token parsing, Phase 7 regressions,
the AI prompt/project/test contracts, decisions, changelog, and this log.

What was completed: The general numeric allow-list remains the first generated-text check, while a
second percentage-specific layer now applies to all three output paths. Ask has no percentage fact
and rejects every numeric percentage expression. Reminder output accepts only exact values from
its non-nil free-budget-impact and category-budget-used percentage fields; days consumed, stress,
or impulse counts cannot authorize percentage wording. Summary output retains its closed
budget-usage binding. The shared parser recognizes ASCII and full-width percent signs before or
after the number with optional spacing, so `%0`, `0%`, `％25`, and `25％` cannot take different
safety paths. Regression coverage proves unrelated zero counts remain valid ordinary numbers but
cannot become percentages, while explicitly supplied percentages still pass.

What was NOT completed: No Archive, TestFlight upload, tester assignment, physical-device install,
version/build change, signing change, merge, or unrelated product feature was performed.
TestFlight remains paused and the candidate version remains `0.9.4 (5)`.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
functional validation passed all 258 Swift Testing tests across 17 suites and all 13
end-to-end/localization UI tests with zero failures while the wall-clock-only benchmark was
excluded from the concurrent suite. The strict 10,000-row Dashboard benchmark then passed
independently together with its deterministic projection companion.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every selected
core service remains above the 85% gate; the directly changed `AdviceSafetyValidator` is at 96.15%
and `PrivacyRedactor` is at 91.91%.

Next suggested task: Re-review the updated draft PR #19. After approval, merge it and repeat the
previously failing Insights and Ask scenarios on the physical iPhone before resuming TestFlight.

## 2026-08-09 — Session 69 — Archive and upload TestFlight 0.9.4 (5)

Goal: Archive the approved PR #19 release from `main`, upload it to the owner's current App Store
Connect account, and stop before tester-group distribution as requested by the product owner.

Files changed: Release evidence in `RELEASE_CHECKLIST.md`, the current candidate identity in
`APP_STORE_SUBMISSION.md`, and this log. No product source, project build setting, version, or
binary content changed after PR #19 merged.

What was completed: Xcode 26.6 archived `main` merge commit `c13586d` as MindBudget/花有数
version `0.9.4`, build `5`, minimum iOS 17.0, bundle ID `com.xdgf558.MindBudget`, and team
`2AM5S7BM2N`. The archive was exported with the App Store Connect distribution method, automatic
signing, and the matching App Store provisioning profile, then uploaded successfully. App Store
Connect finished processing the binary and displayed build 5 under version 0.9.4. Source inspection
confirmed the app contains no custom, proprietary, or standard encryption implementation, so the
build's export-compliance response was recorded as “none of the listed algorithms”; the build then
advanced to `Ready to Submit` with a 90-day testing window.

What was NOT completed: No internal or external tester group was assigned, no external Beta App
Review was submitted, and no App Store production submission was made. The product owner will
perform tester-group distribution manually. App Privacy, age rating, content-rights, regional
availability, agreements, screenshots, physical-device accessibility/performance, and the other
unchecked release gates remain open.

Archive and upload result: pass — `xcodebuild -archivePath ... archive` and the App Store Connect
`-exportArchive` upload both succeeded. The uploaded binary and App Store Connect record agree on
version/build, bundle identifier, and Apple team. The temporary archive remains outside the
repository under `/private/tmp/MindBudgetArchive.LyRv9N/` for this local release session.

Next suggested task: In App Store Connect, manually add 0.9.4 (5) to the intended internal testing
group, complete the remaining release checklist on the signed build, and submit external testing
only after the Beta App Review information has been verified.

## 2026-08-09 — Session 70 — Savings progress and exact app-locale model guidance

Goal: Add the requested cross-cycle savings progress to Insights and address the on-device model
language fallback shown by the current-session diagnostic counters.

Files changed: Savings projections and Insights presentation, Foundation Models capability and
generation services, the AI status view, bilingual strings, Phase 7/11 regressions, and the
project/prompt/test/decision/changelog memory. Existing release-evidence edits for the already
uploaded TestFlight build were preserved.

What was completed: Insights now presents a standalone savings-progress card backed by the
authoritative cross-cycle savings projection. It shows the total goal, exact saved amount,
remaining amount, and completion percentage without changing budget arithmetic; an absent goal
and an unreadable savings projection have distinct localized states, and either condition leaves
expense insights usable. Foundation Models availability is now checked against the exact locale
selected inside the app rather than the device's process locale. Ask, reminder, and cycle-summary
sessions receive explicit locale and required-language instructions, while the existing generated
language validator remains the final fail-closed boundary. The AI status view rechecks when the
app locale changes, and its Debug heading now states that counters are cumulative for the current
process so a prior fallback is not mistaken for current unavailability.

What was NOT completed: No version/build change, Archive, TestFlight upload, tester assignment,
physical-device install, signing change, commit, push, pull request, or merge was performed. The
already processed TestFlight binary remains version `0.9.4 (5)`; these changes remain Unreleased.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
functional validation passed all 261 Swift Testing tests across 17 suites and all 13
end-to-end/localization UI tests with zero failures while the wall-clock-only benchmark was
excluded from the concurrent suite. The strict 10,000-row Dashboard benchmark then passed in its
isolated run.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every selected
core service remains above the 85% gate; `AdviceSafetyValidator` is at 96.15%,
`PrivacyRedactor` at 91.91%, and `CycleSummaryService` at 97.38%.

Next suggested task: Review this post-upload update, test the savings card and selected-language
Foundation Models path on the physical iPhone, then decide whether to ship it as the next
TestFlight build before starting the separate PRO commercialization scope.

## 2026-08-09 — Session 71 — Close PR #20 locale review and prepare 0.9.5 (6)

Goal: Close the review findings on the savings-progress and app-locale AI update, then promote the
next source candidate to version `0.9.5 (6)` with current bilingual release notes.

Files changed: Foundation Models capability and locale instructions, savings-progress arithmetic,
AI and savings regressions, bilingual settings/release-note strings, project version settings,
release-readiness checks, and the repository's AI, release, test, decision, task, changelog, and
project-memory documents.

What was completed: Unsupported app languages now produce a distinct, actionable
`languageNotSupported` reason instead of incorrectly blaming the user's region. Every model
capability boundary requires an explicit app-selected locale, the unused protocol availability
path was removed, and locale instructions distinguish Simplified Chinese, Traditional Chinese,
and U.S. English without silently falling back to `Locale.current`. Savings completion uses
full-width integer multiplication before division and remains capped at 100%, with over-target
savings verified to display zero remaining. The next source candidate is now `0.9.5 (6)` and the
About page exposes only its two current bilingual release-note items, while earlier notes remain
collapsed in history.

What was NOT completed: No Archive, TestFlight upload, tester assignment, physical-device install,
signing change, merge, or App Store submission was performed. App Store Connect still contains the
previously uploaded `0.9.4 (5)` binary; `0.9.5 (6)` is source-only and awaits PR #20 approval.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
functional validation passed all 264 Swift Testing tests across 17 suites and all 13
end-to-end/localization UI tests with zero failures while the wall-clock-only benchmark was
excluded from the concurrent suite. The strict 10,000-row Dashboard benchmark then passed in its
isolated run.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every selected
core service remains above the 85% gate; Money is at 91.73%, BudgetEngine 93.90%,
BudgetCycleCalculator 95.15%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService
97.38%, IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Re-review draft PR #20. After approval, merge it and verify the savings card,
language-switch availability state, and selected-language Foundation Models response on the signed
physical iPhone before deciding whether to Archive and upload `0.9.5 (6)`.

## 2026-08-09 — Session 72 — Align 0.9.5 release evidence and tester guidance

Goal: Close the remaining PR #20 documentation review by separating historical 0.9.4 release
evidence from the unexecuted 0.9.5 gates and aligning every 0.9.5 user-visible change across the
changelog, TestFlight tester guidance, and localized in-app release notes.

Files changed: Release checklist and TestFlight submission notes, the About-page release-note
catalog and bilingual String Catalog, localization regressions, post-upload task memory, and this
session log. No budgeting, savings, Ask, persistence, model, or release-signing implementation
changed.

What was completed: The completed Archive and upload checks now live under an explicitly
historical `0.9.4 (5)` heading, while the `0.9.5 (6)` Archive/upload and final note-matching gates
remain unchecked until they are actually performed. The 0.9.5 TestFlight guidance now asks
testers to verify truthful sub-one-percent/zero/unavailable cycle usage and all localized Ask
fallback reasons in addition to savings progress and app-locale AI behavior. The About page shows
the same four current-version topics in English and Simplified Chinese, and its regression requires
all four while preserving the collapsed history behavior for earlier versions.

What was NOT completed: No Archive, TestFlight upload, tester assignment, physical-device install,
signing change, merge, App Store submission, or GitHub review-thread write was performed. App Store
Connect still contains `0.9.4 (5)`; `0.9.5 (6)` remains an unuploaded source candidate.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
functional validation passed all 264 Swift Testing tests across 17 suites and all 13
end-to-end/localization UI tests with zero failures. The focused LocalizationTests suite passed
10/10, and the strict 10,000-row Dashboard benchmark passed independently after the concurrent
suite intentionally skipped only its noisy wall-clock assertion.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every selected
core service remains above the 85% gate: Money 91.73%, BudgetEngine 93.90%,
BudgetCycleCalculator 95.15%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService
97.38%, IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Re-review draft PR #20. After approval, merge it, complete the unchecked
signed-device release gates, and only then Archive/upload `0.9.5 (6)` if the product owner chooses
to resume TestFlight.

## 2026-08-09 — Session 73 — Simplify budget setup and use actual fixed expenses

Goal: Align budget setup with the current expense-entry workflow by removing the duplicate fixed
expense forecast, clarifying the income and expected-expense labels, and defining this period's
disposable budget as income minus the savings goal.

Files changed: Onboarding and Settings budget forms, Dashboard budget-transition calls, budget
engine and cycle-copy behavior, bilingual strings and 0.9.5 release notes, budget/reminder/wishlist
regressions and UI tests, plus the project memory, decisions, task, changelog, test-plan, and
TestFlight guidance documents.

What was completed: The budget form now labels its fields “本月收入” and “预计支出”, no longer
shows or validates a manual fixed-expense field, and previews “本期可支配预算” as monthly income
minus the savings goal. New, edited, and automatically copied plans persist a zero legacy fixed
forecast. Existing nonzero forecast values remain readable for schema compatibility but are no
longer deducted. Actual fixed and discretionary ledger expenses both reduce the available budget
and daily pace, while recurring fixed expenses continue to originate from the expense-entry
workflow. Reminder fixtures were updated to preserve their original thresholds under the new
model, and wishlist budget impact now reflects the absence of forecast pre-deduction.

What was NOT completed: No version/build change, Archive, TestFlight upload, tester assignment,
physical-device install, signing change, commit, push, pull request, merge, or App Store submission
was performed. The changes remain Unreleased in the `0.9.5 (6)` source candidate.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
functional validation passed all 264 Swift Testing tests across 17 suites and all 13
end-to-end/localization UI tests with zero failures while the wall-clock-only benchmark was
excluded from the concurrent suite. Focused budget and localization coverage passed 70 tests,
then the affected wishlist and reminder suites passed all 51 tests after their fixtures were
aligned with the new budget definition.

Static and coverage result: pass — floating-point money, release readiness, App Icon source and
artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every selected
core service remains above the 85% gate: Money 91.73%, BudgetEngine 90.55%,
BudgetCycleCalculator 95.15%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService
97.38%, IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Review the budget setup and Settings preview on a physical iPhone with an
existing plan that previously stored a fixed forecast, then decide whether to include this change
in the next `0.9.5 (6)` TestFlight upload.

## 2026-08-10 — Session 74 — Publish budget simplification as draft PR #21

Goal: Preserve the completed budget-setup work from the shared local checkout, verify it
independently, and publish a bounded draft pull request for owner review without merging or
uploading another binary.

What was completed: Created branch `codex/simplify-budget-setup`, committed the implementation and
tests, pushed the branch, and opened draft PR #21. Release memory was corrected to record that
`0.9.5 (6)` had already been accepted by App Store Connect transport on 2026-08-09. The current
budget changes remain Unreleased and the release checklist now requires a new build number before
any replacement Archive rather than allowing build 6 to be reused.

What was NOT completed: No PR merge, version/build increment, Archive, TestFlight upload, tester
assignment, signing change, or App Store submission was performed. The product owner still needs
to review PR #21 and verify the revised budget forms and legacy fixed-forecast behavior on a
physical iPhone.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
validation passed all 264 Swift Testing tests across 17 suites and all 13 UI tests with zero
failures. The strict local 10,000-row Dashboard performance benchmark also passed independently.

Static and coverage result: pass — floating-point money, release readiness, bilingual String
Catalog JSON, App Icon integrity, and `git diff --check` all pass. Every selected core service
remains above the 85% coverage gate.

Next suggested task: Review draft PR #21. If approved, merge it into `main`, then increment the
build number before preparing any TestFlight replacement containing these Unreleased changes.

## 2026-08-10 — Session 75 — Close PR #21 budget-authority review findings

Goal: Make the budget preview, persisted plan, Today pace, and upgrade behavior use one explicit
set of semantics before draft PR #21 is reviewed again.

What was completed: The configured monthly income plus explicitly allocated extra income is now
the authoritative disposable-budget funding base; the per-cycle savings goal and any surviving
legacy fixed forecast are deducted from that base. Expected expenses remains a separate planning,
pace, and amount-reasonableness reference and no longer masquerades as spending permission. Both
initial setup and Settings previews use the same calculation as the saved snapshot, including
allocated income. Existing current-cycle fixed forecasts are preserved during edits and consumed
by actual fixed entries before those entries reduce disposable budget again, preventing both an
upgrade-time balance jump and double deduction. Automatically copied future cycles continue with
a zero forecast, and Settings explains the temporary compatibility reservation. Today pace now
subtracts discretionary entries one-for-one while fixed entries rebalance the remaining cycle
rather than causing a second same-day charge. Orphaned fixed-forecast strings were removed, the
change remains in Unreleased documentation rather than the already uploaded 0.9.5 notes, and
regressions cover the 20,000 income / 8,000 expected expenses / 2,000 savings = 18,000 disposable
example, explicit income allocation, legacy upgrade behavior, and fixed-expense pace smoothing.

What was NOT completed: No merge, version/build increment, Archive, TestFlight upload, tester
assignment, physical-device install, signing change, or App Store submission was performed. No
recurring-rule-derived hidden forecast was added; actual ledger entries remain authoritative.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
validation passed all 267 Swift Testing tests across 17 suites and all 13 UI tests with zero
failures. The concurrent suite skipped only the intentionally environment-gated wall-clock
assertion while still exercising the deterministic 10,000-row Dashboard projection.

Static and coverage result: pass — floating-point money and release-readiness checks, App Icon
source/artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every
selected core service remains above the 85% coverage gate: Money 91.73%, BudgetEngine 94.12%,
BudgetCycleCalculator 95.15%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService
97.42%, IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Re-review draft PR #21, including a physical-iPhone upgrade check with a
current plan that still carries a legacy fixed forecast. Merge only after approval; any subsequent
TestFlight replacement must use a new build number.

## 2026-08-10 — Session 76 — Preserve migrated budget authority in PR #21

Goal: Close the remaining PR #21 review finding that changing every persisted plan to an
income-based funding baseline could silently raise or cut an existing user's current-cycle
disposable budget, especially when an older plan stored zero monthly income.

What was completed: Added Schema V4 with a `BudgetPlanSemantics` companion record that marks every
newly created, edited, transitioned, or automatically copied plan as income-based without changing
the frozen historical `BudgetPlan` schema. A migrated plan without that marker is structurally
recognized as legacy and keeps its original Expected-expenses funding base plus any current-cycle
fixed reservation; this applies even when its stored monthly income is zero. Its first automatically
created future cycle receives the explicit income-based marker, clears the legacy reservation, and
uses monthly income plus explicitly allocated income minus the savings goal. Settings preview now
uses the same authority as the persisted snapshot and explains that the compatibility calculation
ends next cycle. Deletion verification, model counts, corruption validation, durable documentation,
and bilingual copy were extended for the companion model. Regression tests open a real Schema V3
store through the V4 migration plan, prove the zero-income legacy cycle retains its old balance,
and prove the following cycle switches to the new semantics; separate engine tests prevent a new
zero-income plan from borrowing Expected expenses as spending permission.

What was NOT completed: No merge, version/build increment, Archive, TestFlight upload, tester
assignment, physical-device install, signing change, or App Store submission was performed. Draft
PR #21 remains open for owner review.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Focused
budget, migration, and date-boundary validation passed all 72 selected tests. Full validation then
passed all 270 Swift Testing tests across 17 suites and all 13 UI tests with zero failures.

Static and coverage result: pass — floating-point money and release-readiness checks, App Icon
source/artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every
selected core service remains above the 85% coverage gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService
97.42%, IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Re-review draft PR #21 and perform a physical-iPhone upgrade check against an
existing pre-V4 plan. Merge only after approval; any later TestFlight replacement must use a new
build number.

## 2026-08-10 — Session 77 — Close PR #21 migration and edit-authority review

Goal: Finish the small PR #21 review closeout by proving that editing a migrated legacy plan does
not silently change its funding authority, and align the pull-request and release memory with the
actual lightweight Schema V3-to-V4 migration.

What was completed: Extended the real Schema V3 migration regression to edit and save a migrated
current-cycle plan, prove it remains `legacyExpectedExpenses`, prove no `BudgetPlanSemantics`
marker is invented by that edit, and prove the saved snapshot keeps the legacy Expected-expenses
base. The same test still proves that the next automatically generated cycle becomes explicitly
income-based and receives its companion marker. The test plan, changelog, and TestFlight upgrade
notes now describe the lightweight V3-to-V4 migration, the no-marker legacy interpretation, the
edit behavior, and the next-cycle handoff consistently. The draft PR description is updated
separately after this commit is pushed so it no longer claims that the change has no schema
migration.

What was NOT completed: No PR merge, version/build increment, Archive, TestFlight upload, tester
assignment, physical-device install, signing change, or App Store submission was performed. Draft
PR #21 remains open for owner review.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
validation with the established hosted-environment wall-clock exclusion passed all 270 Swift
Testing tests across 17 suites and all 13 UI tests with zero failures. The new migrated-plan edit
regression passed. The strict local 500 ms wall-clock signal was also measured separately: it took
0.773 seconds under concurrent local load, while the deterministic 10,000-row Dashboard projection
test passed; this timing signal is recorded rather than misclassified as a functional regression.

Static and coverage result: pass — floating-point money and release-readiness checks, App Icon
source/artifact integrity, bilingual String Catalog JSON, and `git diff --check` pass. Every
selected core service remains above the 85% coverage gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService
97.42%, IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Re-review draft PR #21 with its corrected migration description. Merge only
after owner approval; any later TestFlight replacement must use a new build number.

## 2026-08-10 — Session 78 — Prepare 0.9.6 (7) TestFlight candidate

Goal: Prepare the owner-approved PR #21 budget-semantics work as the next signed internal
TestFlight candidate without assigning it to any tester group.

What was completed: Incremented the release from 0.9.5 (6) to 0.9.6 (7), moved the approved
income-based disposable-budget and lightweight Schema V3-to-V4 migration notes into the 0.9.6
release section, added concise bilingual in-app release copy, and aligned the About-screen,
release-readiness script, localization tests, UI tests, submission notes, and release checklist with
the candidate version. The TestFlight test notes ask testers to verify the new budget authority,
legacy-plan upgrade behavior, and next-cycle handoff. No signing identity or team identifier was
committed; the current China-region team remains a local signing override.

What was NOT completed: No Archive, TestFlight upload, tester assignment, external-test
submission, or App Store submission was performed in this preparation step. The Archive and upload
remain pending until this release commit is merged to `main`.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build. Full
validation with the established hosted-environment wall-clock exclusion passed all Swift Testing
and UI test suites with zero functional failures, including all 13 UI tests.

Static and coverage result: pass — floating-point money, release-readiness, App Icon
source/artifact integrity, bilingual String Catalog JSON, and `git diff --check` checks pass. Every
selected core service remains above the 85% coverage gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService
97.42%, IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Merge this release-preparation commit to `main`, create a signed 0.9.6 (7)
Archive with the current local team, upload it to App Store Connect, and stop before assigning any
tester group.

## 2026-08-10 — Session 79 — Archive and upload 0.9.6 (7)

Goal: Produce the signed 0.9.6 (7) release artifact from merged `main`, upload it to the intended
App Store Connect app with the owner's current China-region team, and stop before tester-group
assignment.

What was completed: GitHub PR #22 passed its independent Build and test job in 21 minutes 37
seconds and was merged to `main` at commit `c1ef153`. Xcode 26.6 then archived the arm64 Release
product from that merge. The archive reports version 0.9.6, build 7, bundle
`com.xdgf558.MindBudget`, team `2AM5S7BM2N`, iPhone-only family `[1]`, and iOS 17.0 minimum.
Automatic App Store Connect export used the same team and disabled automatic version/build
mutation. App Store Connect completed package analysis, accepted the full upload, and returned
`Uploaded package is processing`, `Upload succeeded`, and `EXPORT SUCCEEDED` at 2026-08-10
13:01 Asia/Singapore.

What was NOT completed: No internal or external tester group was assigned, no beta-review form was
submitted, and no App Store version was submitted for review. The owner will handle tester-group
distribution manually after App Store Connect finishes processing the uploaded build.

Build and test result: pass — the release candidate had already passed the complete local Release,
Swift Testing, UI testing, and coverage workflow; GitHub PR #22 independently passed before merge.
The signed generic-device Archive completed with `ARCHIVE SUCCEEDED` and the App Store Connect
export/upload completed with `EXPORT SUCCEEDED`.

Static and release result: pass — the final archive metadata and embedded entitlements match the
intended bundle and team. Build 7 is now immutable and must never be reused; any replacement must
increment the build number.

Next suggested task: Wait for App Store Connect processing, then let the owner manually attach
0.9.6 (7) to the intended TestFlight group and enter the prepared Simplified Chinese What to Test
notes. Continue the remaining signed physical-device accessibility and system-integration checks
before public release.

## 2026-08-10 — Commercialization task decomposition and development entry

Goal: Convert the owner-approved v1.4 commercialization and Pro cloud-AI specification into a
reviewable execution map while preserving the completed Phase 0–12 history and without beginning
commercial product implementation.

What was completed: Added `Docs/COMMERCIALIZATION_TASKS.md` as a pre-COM-C0A planning scaffold.
It separates 17 execution stages (COM-C0A, COM-C0B, COM-C1, COM-C2, COM-C3, COM-C4A, COM-C4B,
COM-C4C, COM-C5, COM-C6, COM-C6.5, and COM-C7 through COM-C12) plus the G1 evidence/cost gate,
records their dependencies and review-sized work packets, and marks COM-C0A as the only active next
phase. The map preserves the owner's current decisions: public launch stays paused until the full
commercialization release gate, test users do not inherit production Pro, prices/trial/cloud quota
remain cost-dependent TBD, Local Lifetime is deferred, cloud providers are not locked to one
vendor, and a future backend must be independent and hardened. The main task list and project
memory now point to the separate COM track.

What was NOT completed: No repository audit result was claimed, no Requirement IDs or conflict
decisions were invented, and no product code, schema, StoreKit product, CloudKit container,
telemetry receiver, Watch target, receipt pipeline, backend resource, model provider, version,
archive, upload, or tester assignment was changed. The three mandatory COM-C0A audit artifacts do
not yet exist because COM-C0A has not been executed.

Validation result: Documentation-only change. The v1.4 source SHA-256 was recorded as
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`; task order and phase gates
were checked against the source sections. Product build/test commands were not rerun because no
source, project, build configuration, resource, or test file changed.

Next suggested task: Begin COM-C0A with read-only repository inspection and reproducible baseline
execution, create `Docs/Commercialization/SPEC_CONFLICTS.md`,
`Docs/Commercialization/REQUIREMENTS_INDEX.md`, and
`Docs/Commercialization/COM_C0A_REPORT.md`, then stop for owner decisions before COM-C0B.

## 2026-08-10 — Session 80 — COM-C0A specification lock and repository audit

Goal: Execute only the read-only COM-C0A audit against the owner-approved v1.4 commercialization
specification, establish a reproducible baseline and durable Requirement/conflict evidence, and
stop before COM-C0B or any commercial implementation.

What was completed: Locked the v1.4 source at SHA-256
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0` and audited merged `main`
commit `6226823370d9ecaedfd89f2754e1f5705dc8d5dd`. Created
`Docs/Commercialization/REQUIREMENTS_INDEX.md`, `SPEC_CONFLICTS.md`, `COM_C0A_REPORT.md`, and the
dedicated commercialization session log. Audited toolchain, project/signing configuration,
SwiftData V1–V4 and all 15 current models, exact-money boundaries, migration/deletion behavior,
StoreKit/CloudKit/network/telemetry/backend/third-party absence, Foundation Models/privacy gates,
receipt/camera/Photos absence, logging/export/permissions, secrets, and Watch readiness. No
product source, schema, project, resource, version, product, or external system was changed.

What was NOT completed: COM-C0A was not marked Done. SPEC-012 (current local-only rules versus
approved later channels), SPEC-013 (Watch/G1 ordering), and SPEC-014
(price/product/economics phase cycle) remain Open and require explicit owner decisions. Product
IDs remain blocked by SPEC-017. COM-C0B, StoreKit, CloudKit, telemetry, Watch, receipt import,
backend, cloud AI, versioning, Archive, upload, and tester assignment were not started.

Build and test result: pass — Xcode 26.6 completed the generic iOS Simulator Release build and the
complete Swift Testing suite with zero functional failures. All 13 UI tests passed. The existing
shared-host switch excluded only the nondeterministic strict 500 ms wall-clock signal; its
deterministic 10,000-row contract still ran.

Static and coverage result: pass — money and release-readiness gates passed. All selected services
passed the 85% minimum: Money 91.73%, BudgetEngine 95.18%, BudgetCycleCalculator 95.17%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 91.02%,
AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService 97.42%,
IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Have the owner explicitly resolve SPEC-012, SPEC-013, and SPEC-014 and accept
the resulting C0B inputs. Only then begin COM-C0B documentation/execution controls; do not start
entitlement, StoreKit product, or other commercialization code early.

## 2026-08-10 — Session 81 — Close the COM-C0A owner decision gate

Goal: Record the owner's commercialization boundary, Watch schedule, economics-gate, and Product
ID decisions without starting COM-C0B or creating any commercial product.

What was completed: Accepted a phase-scoped replacement for future data channels while preserving
existing-version behavior; each later iCloud, telemetry, or cloud-AI channel still requires user
authorization, privacy disclosure, deletion, and release gates. Made Watch development a parallel,
nonblocking branch and Watch distribution a separate post-iPhone-1.0 release. Accepted the
configuration-only → preliminary unit-economics → G1 final economics sequence. Chose immutable
technical Product IDs `com.xdgf558.mindbudget.pro.monthly` and
`com.xdgf558.mindbudget.pro.annual` under the internal `MindBudget Pro` group. Closed SPEC-012,
SPEC-013, SPEC-014, and SPEC-017, marked COM-C0A Done, and made COM-C0B Ready.

What was NOT completed: COM-C0B and every product implementation remain unstarted. No StoreKit
Configuration or App Store Connect product/group, price, trial, quota, entitlement, CloudKit,
telemetry, backend, Watch target, receipt pipeline, version, Archive, upload, or tester assignment
was created.

Validation result: Documentation-only decision update; no buildable input changed. The complete
COM-C0A Release/test/coverage baseline from Session 80 remains applicable.

Next suggested task: Enter COM-C0B only on explicit owner instruction and create its durable
commercial controls before any COM-C1 entitlement code.

## 2026-08-10 — Session 82 — Complete COM-C0B governance and CI controls

Goal: Complete the explicitly authorized COM-C0B documentation/test-infrastructure phase without
starting entitlement, StoreKit, or any later commercial feature.

What was completed: Added the dedicated commercial memory and accepted decision register;
network-egress, provider, StoreKit, regional-pricing, and CI baseline matrices; a three-packet
COM-C1 execution contract; and an executable commercialization-document gate used locally and in
CI. The current app-owned Release HTTP(S) allow-list is explicitly empty. Product IDs are fixed,
commercial values remain TBD, future provider failover remains consent-bound, and SPEC-018's stale
deletion model count is corrected to all current models. Root project rules now distinguish the
unchanged current local baseline from narrowly approved future COM channels. No changelog entry
was added because app behavior and user-visible copy did not change.

What was NOT completed: No product source/schema/resource, entitlement, StoreKit product/group,
paywall, price/trial/quota, CloudKit, telemetry, backend, provider, receipt, Watch target, version,
Archive, upload, or tester assignment changed. COM-C1 is Ready but unstarted.

Validation result: pass — money, commercial-doc, and release-readiness gates; Xcode 26.6 Release
build; 270 Swift tests; 13 UI tests; and all existing coverage thresholds. Detailed evidence and
the result-bundle path are in commercialization Session 3 and `CI_BASELINE.md`.

Next suggested task: Enter COM-C1 only after explicit owner instruction and execute its three
review packets in order, stopping before StoreKit or paid UI.

## 2026-08-10 — Session 83 — Close COM-C0B executable review findings

Goal: Close PR #24's review findings without expanding the authorized commercialization phase.

What was completed: The accepted empty current Release app-owned egress set is now enforced
against all app Swift source, not only policy prose. CI now retains the deterministic xcresult as
a downloadable pinned-action artifact. The private owner-held v1.4 source has a single explicit
provenance/fingerprint record and honest external-drift limitation; the open-P0 parser is
order-independent; `BudgetPlanSemantics` is included in the current local deletion/privacy
inventory; and SPEC-015's accepted status is consistent across commercial memory. Detailed
decisions and evidence are in commercialization Session 4. The initial review-fix push also
exposed and closed a GitHub workflow-loader issue by scoping `runner.temp` to the test step rather
than job-level environment evaluation. The artifact action was also repinned from the deprecated
Node 20 release to GitHub's verified Node 24 `v7.0.1` commit.

What was NOT completed: No product behavior, app source/schema/resource, entitlement, StoreKit,
CloudKit, telemetry, backend, provider, receipt, Watch, version, Archive, upload, or tester state
changed. COM-C1 remains Ready but unstarted.

Validation result: pass — Release build, 270 Swift tests, 13 UI tests, money/release/network/doc
gates, and all existing coverage thresholds. The ignored review-result bundle path is recorded in
commercialization Session 4.

Next suggested task: Merge only after the updated PR CI is green, then wait for a new explicit
owner instruction before starting COM-C1.

## 2026-08-11 — Session 84 — Harden COM-C0B egress and conflict gates

Goal: Close PR #24's final nonblocking review findings without starting COM-C1 or changing app
behavior.

What was completed: Narrowed HTTP(S) source detection to quoted endpoint values and ignored
full-line documentation comments, while preserving detection of networking primitives and
framework imports. Expanded the empty-egress scanner to checked-in app property lists,
entitlements, privacy manifests, xcconfig files, and generated-Info.plist build settings in the
project file; ATS exceptions, networking entitlements, associated domains, and configured
HTTP(S) endpoints now fail closed. Added built-in positive and negative samples for comment/DTD
boundaries. Changed the unresolved-conflict parser so `Open` and `P0` must each be complete tokens,
with a regression sample for `Open-ended P01`. Updated the detailed and root decision pointers,
network policy, project memory, and completed-task evidence. No changelog entry was added because
there is no user-visible behavior change.

What was NOT completed: No app source/schema/resource, entitlement, StoreKit product/group,
CloudKit, telemetry, backend, provider, receipt, Watch, version, Archive, upload, or tester state
changed. COM-C1 remains Ready but unstarted.

Validation result: pass. Script syntax, network-gate self-tests, commercialization-document gate,
no-floating-point-money gate, Release build, 270 deterministic Swift tests, all 13 UI tests, and
all coverage thresholds passed under Xcode 26.6. The initial strict local run recorded only the
known non-deterministic 500 ms wall-clock signal at 0.752 seconds; the documented shared-host
switch excluded that single timing assertion on the successful rerun while retaining and passing
the deterministic 10,000-row dashboard projection test.

Next suggested task: Push this review closeout to PR #24, confirm CI is green, and merge only on
the owner's instruction. Do not start COM-C1 early.

## 2026-08-11 — Session 85 — Implement COM-C1-01 entitlement domain

Goal: Start the explicitly authorized COM-C1 phase with its first isolated review packet only.

What was completed: Added the pure `Sendable` entitlement algebra, closed approved premium
feature vocabulary, separate Free-core proof vocabulary, and versioned fail-closed entitlement
representation. Production code can construct only exact Free or Pro subscription; unknown bits
and unsupported representation versions cannot unlock anything. Added focused tests for all
C1-01 acceptance cases and recorded DEC-COM-012 plus the detailed evidence in commercialization
Session 6. No changelog entry was added because the app has no new user-visible behavior.

What was NOT completed: No runtime access service/injection, Debug override, StoreKit, product ID,
purchase/restore/paywall, paid UI, cloud/backend/provider, schema/resource, version, Archive,
upload, or tester state changed. C1-02 and C1-03 remain pending.

Validation result: pass under Xcode 26.6 — focused entitlement tests, Release build, complete
Swift tests, 13 UI tests, static money/network/commercial/release gates, and all coverage
thresholds passed. The documented shared-host option skipped only the nondeterministic wall-clock
signal and retained the deterministic 10,000-row projection contract.

Next suggested task: Review C1-01 in a focused PR, then start C1-02 only after merge.

## 2026-08-11 — Session 86 — Close COM-C1-01 review findings

Goal: Remove the entitlement algebra's ambiguous consumer surface and make its version-1
inventory structurally complete before COM-C1-02 begins.

What was completed: Replaced `contains(_:)` with explicit `isSuperset(of:)` semantics and added a
test proving Pro remains a superset of Free without being classified as `isFree`. Added an
independent invariant that the union of every Release-reachable paid entitlement exactly equals
the version-1 known-bit mask. Clarified that the subscribed/grace fixtures prove only the domain
vocabulary, not the deferred StoreKit mapping. Reworked migration into an explicit version switch
with a dedicated version-1 branch. Detailed rationale and evidence are recorded in
commercialization DEC-COM-012 and Session 7. No changelog entry was added because app behavior is
unchanged.

What was NOT completed: No access-service consumer, Debug provider, StoreKit, purchase/restore,
paywall, paid UI, cloud/backend/provider, schema/resource, version, Archive, upload, or tester
state changed. COM-C1-02 and COM-C1-03 remain pending.

Validation result: pass under Xcode 26.6 — 11 focused entitlement tests, Release build, 281 Swift
tests in 18 suites, 13 UI tests, static money/network/commercial/release gates, and every core
coverage threshold passed. The shared-host switch skipped only the nondeterministic wall-clock
signal and retained the deterministic 10,000-row projection test.

Next suggested task: Confirm PR #25 CI is green and merge only after owner approval. Start C1-02
only after that merge.

## 2026-08-11 — Session 87 — Implement COM-C1-02 central feature access

Goal: Add the second isolated COM-C1 review unit after C1-01 merged: one deterministic access
authority and injection boundary, with no StoreKit or visible paid behavior.

What was completed: Added a pure immutable `FeatureAccessService` behind a `Sendable` protocol,
with an exhaustive decision for every approved `PremiumFeature`. `AppEnvironment` and
`AppSession` now own one injected authority whose production/default snapshot is exact Free.
Added a nonpersistent arbitrary-combination provider compiled only under `#if DEBUG`. Focused
tests cover the full feature×entitlement matrix, exact-Free default, subscription removal back to
the same Free matrix, concurrent/read consistency, session injection, and every currently valid
Debug combination. Added an executable static gate to reject raw entitlement-bit reads,
`isSuperset(of: .free)`, duplicate paid checks outside the central service, persisted/manual
authority, an unguarded Debug provider, and StoreKit imports during COM-C1. Updated the execution
packet, project/task memory, requirement evidence, DEC-COM-013, and commercialization Session 8.
No changelog entry was added because no user-visible behavior changed.

What was NOT completed: Existing feature entries are not locked or rerouted; C1-03 still owns that
integration. No StoreKit state/product/group, purchase/restore/paywall, price/trial/quota, paid UI,
schema/resource, network/cloud/provider, telemetry, version, Archive, upload, or tester state
changed.

Validation result: pass under Xcode 26.6. Focused commercialization entitlement/access tests
passed. Full validation passed the Release build, complete Swift test suite, all 13 UI tests,
no-floating-point-money, empty-egress, commercialization-document, feature-access-boundary, and
release-readiness gates, plus every existing core-service coverage threshold. The documented
shared-host switch excluded only the nondeterministic wall-clock signal while retaining the
deterministic 10,000-row dashboard projection contract.

Next suggested task: Review C1-02 in a focused PR, merge only after owner approval, and begin C1-03
only after that merge.

## 2026-08-11 — Session 88 — Close COM-C1-02 authority-bypass review findings

Goal: Close PR #26's remaining static-boundary findings before C1-03 begins.

What was completed: Prevented app source outside the entitlement domain from calling
`EntitlementSetMigrator`, closing the second path by which persisted or transported raw bits could
otherwise reconstruct Pro without a `.proSubscription` literal. Added executable positive and
negative fixtures for the DEBUG-provider preprocessor parser: the active DEBUG branch passes,
while unguarded and `#else` declarations fail. The parser also tolerates a trailing directive
comment. Updated the C1 execution checklist, DEC-COM-013, project/task memory, and detailed
commercial Session 9. No changelog entry was added because no user-visible behavior changed.

What was NOT completed: No existing feature was locked or rerouted; C1-03 remains pending. No
StoreKit state/product, persistence authority, purchase/restore/paywall, paid UI, cloud/backend,
schema/resource, version, Archive, upload, or tester state changed.

Validation result: pass under Xcode 26.6 — shell syntax, focused access boundary and money gates,
Release build, 286 Swift tests in 18 suites, all 13 UI tests, static release/network/commercial
gates, and every coverage threshold. The shared-host switch skipped only the nondeterministic
500 ms wall-clock assertion and retained the deterministic 10,000-row projection test. An initial
invocation stopped before build because the global developer directory pointed to Command Line
Tools; rerunning against the project-recorded Xcode 26.6 path passed completely.

Next suggested task: Push this review closeout to PR #26, confirm CI is green, and merge only after
owner approval. Start C1-03 only after the merge.

## 2026-08-11 — Session 89 — Close COM-C1-02 authority chokepoints

Goal: Replace the remaining path-by-path paid-entitlement checks with complete authority
chokepoints before C1-03 adds the first feature-entry consumers.

What was completed: Extended `Scripts/check-feature-access-boundary.sh` with executable parsers
that allow app code outside Commerce to construct only the no-argument, exact-Free
`FeatureAccessService()`, while rejecting every entitlement-bearing construction. The same gate
now rejects `FeatureAccessChecking` conformances and protocol refinements outside Commerce while
still allowing ordinary consumers to hold the protocol existential. Built-in positive and
negative fixtures exercise no-argument construction, multiline entitlement injection, consumer
properties, multiline provider conformance, and protocol refinement through the same parsers
used on the repository. Existing literal, migrator, raw-bit, StoreKit, persistence, and DEBUG
checks remain as defense in depth. Updated DEC-COM-013, the C1 execution checklist, and
project/task memory. No changelog entry was added because user-visible behavior is unchanged.

What was NOT completed: No C1-03 feature entry was integrated or locked. No StoreKit mapping,
product/group, persisted authority, purchase/restore/paywall, paid UI, price/trial/quota,
schema/resource, network/cloud/provider, telemetry, version, Archive, upload, or tester state
changed.

Validation result: pass under Xcode 26.6. Shell syntax and every static access, money, network,
commercial-document, and release gate passed. Full validation passed the Release build, 286
Swift tests in 18 suites, all 13 UI tests, and every core-service coverage threshold. The
documented shared-host switch excluded only the nondeterministic wall-clock signal while
retaining the deterministic 10,000-row projection contract. An initial sandboxed invocation was
blocked from CoreSimulator and DerivedData; the identical normal Xcode invocation passed fully.

Next suggested task: Push this closeout to PR #26, confirm CI is green, and merge only after owner
approval. Begin C1-03 only after that merge.

## 2026-08-11 — Session 90 — Implement COM-C1-03 existing-entry integration

Goal: Route only the owner-approved existing feature entries through the COM-C1 access authority,
while keeping the production/default build exact Free and avoiding StoreKit or purchase UI.

What was completed: Added an immutable `ExistingPremiumEntryAccess` snapshot derived only from
`FeatureAccessChecking`, then injected that narrowed snapshot through the app session and accepted
service boundaries. Apple on-device text enhancement, non-24-hour cooling-off choices, and the
advanced Siri/App Intents set now use that one authority. Exact Free still receives complete local
Ask and reminder templates, the 24-hour cooling period, basic Siri expense recording and budget
checks, unlimited manual ledger use, CSV export, Delete All, the five-item wishlist, and the
30-day local insights baseline. Legacy non-24-hour cooling records remain readable and unchanged,
while new or changed premium durations fail closed with neutral localized copy. Strengthened the
static access gate so feature code cannot recreate access decisions through direct
`decision(for:)` calls, feature-local Pro aliases, manual unlock names, or product identifiers.
Added focused entitlement, AI, cooling-off, Siri, and Free-baseline regression coverage, and
updated the main/commercial task memory, DEC-COM-014, execution packet, requirements evidence,
and changelog.

What was NOT completed: No StoreKit import or state mapping, product identifier, subscription
group, purchase, restore, paywall, price, trial, quota, receipt, entitlement persistence, schema,
network/cloud/provider, telemetry, Apple Watch release, version, Archive, upload, or tester state
changed.

Validation result: pass under Xcode 26.6. All static money, empty-egress, commercialization-
document, feature-access, and release-readiness gates passed. The Release simulator build,
complete Swift test suite, all 13 UI tests, and every core-service coverage threshold passed.
The focused C1-03 regression selection additionally passed 114 tests across five suites. The
documented shared-host switch excluded only the nondeterministic wall-clock signal while retaining
the deterministic 10,000-row projection contract. A first sandboxed invocation lacked
CoreSimulator and DerivedData access; the identical validation with normal Xcode permissions
passed completely.

Next suggested task: Review C1-03 in its focused PR, merge only after owner approval, and begin
COM-C2 only after that merge and a separate explicit owner instruction.

## 2026-08-11 — Session 91 — Close COM-C1-03 disclosure and passive-query review

Goal: Close PR #27's review findings without widening the approved premium scope or introducing
an unreleased purchase authority.

What was completed: Made every advanced App Entity provider a passive system lookup that returns
an empty collection under exact Free or unavailable Siri integration, while keeping user-invoked
advanced writes on the neutral `featureNotYetAvailable` error path. Exact Free now presents the
fixed 24-hour cooling period as read-only content instead of a misleading single-option segmented
control. Expanded the changelog and commercialization memory to enumerate the affected Apple
on-device enhancement, custom cooling, advanced Siri action, and passive entity-query surfaces;
the retained Free baseline and legacy cooling-record behavior remain explicit. Recorded that the
already-uploaded 0.9.6 binary is unchanged and that this post-C1 source must not be distributed
until verified StoreKit-derived entitlement lifecycle, purchase/restore, purchase presentation,
and the owning release gates exist. Added service and UI regression coverage for all seven passive
entity providers, active-write rejection, and the fixed Free cooling presentation.

What was NOT completed: No temporary Pro entitlement, StoreKit state or import, product/group,
purchase, restore, paywall, price, trial, quota, receipt, entitlement persistence, schema,
network/cloud/provider, telemetry, version, Archive, upload, tester assignment, or release state
changed. The distribution hold is documentation and release-gate policy, not a new product flow.

Validation result: pass under Xcode 26.6. All static money, empty-egress, commercialization-
document, feature-access, release-readiness, and diff checks passed. Full validation passed the
Release build, complete Swift test suite, all 13 UI tests with zero failures, and every core-
service coverage threshold. The documented shared-host switch skipped only the nondeterministic
wall-clock assertion and retained the deterministic 10,000-row projection contract. The first
invocation stopped before build because the machine-wide developer directory pointed at Command
Line Tools; rerunning against the project-recorded Xcode 26.6 path passed completely.

Next suggested task: Push this closeout to PR #27, confirm CI is green, and merge only after owner
approval. Begin COM-C2 only after that merge and a fresh explicit instruction.

## 2026-08-11 — Session 92 — Close COM-C1 and enter COM-C2-01

Goal: Close the independently reviewed COM-C1 track, mark COM-C2 active, and deliver only its
first isolated StoreKit test-catalog packet.

What was completed: Updated the durable main and commercialization memory so COM-C1 is Done and
COM-C2 is In Progress at C2-01. Added exactly one local StoreKit Configuration fixture containing
the accepted Pro Monthly and Pro Annual identifiers, isolated it to the test bundle and a
non-Archive local Debug scheme, and kept the default scheme and app bundle free of the fixture.
Added StoreKitTest/JSON regression coverage, a self-testing static catalog/isolation gate, CI and
validation integration, DEC-COM-015, and a bounded C2-01 through C2-04 execution packet. This is
test infrastructure only and makes no user-visible product change, so no changelog entry was
added.

What was NOT completed: No formal App Store Connect product/group, runtime StoreKit catalog or
transaction owner, entitlement cache/authority, purchase, restore, paywall, price, trial, quota,
schema, network/cloud/provider, release version, Archive, upload, tester, or distribution state
changed. C2-02 has not started.

Validation result: pass under Xcode 26.6. All static gates passed. The Release build, 293 Swift
tests in 19 suites, 13 UI tests, and all selected core-service coverage thresholds passed; the
focused StoreKit catalog suite passed 3 tests. The shared-host option skipped only the
nondeterministic wall-clock assertion and retained the deterministic 10,000-row projection test.

Next suggested task: Review C2-01 in a focused PR. Start C2-02 only after review, merge, and a new
explicit owner instruction.

## 2026-08-12 — Session 93 — Harden COM-C2-01 catalog and project isolation

Goal: Close PR #28's StoreKit catalog-review findings without introducing runtime StoreKit
authority or beginning C2-02.

What was completed: Replaced line-format-dependent `pbxproj` resource checks with a balanced-object
parser that works with compact or Xcode-rewritten multiline project files. The gate now runs
accepted and rejected project/scheme fixtures through the same production parser before checking
the repository, proving that test-bundle-only placement is accepted while app-resource,
default-scheme, and Archive-capable configurations are rejected. Pinned the catalog's exact
bilingual local-test disclaimers, synthetic prices and billing plans, and changed the local default
environment to CHN/`zh_CN` without accepting customer pricing or a launch storefront. Expanded the
Swift catalog tests to enforce the same contract. Recorded that C2-02 must also test a non-CHN
storefront and that C2-03 owns controlled billing-grace lifecycle evidence.

What was NOT completed: No runtime StoreKit product loading, transaction listener, entitlement
authority/cache, purchase, restore, status mapping, paywall, formal App Store Connect product,
customer price/trial/quota, schema, app resource, network/cloud/provider, user-visible behavior,
version, Archive, upload, tester, or distribution state changed. C2-02 has not started.

Validation result: pass under Xcode 26.6. The focused StoreKit catalog suite passed all 3 tests.
Every static money, empty-egress, commercialization-document, feature-access, StoreKit-catalog,
release-readiness, and diff gate passed. Full validation passed the Release build, 293 Swift tests
in 19 suites, all 13 UI tests, and every selected core-service coverage threshold. The documented
shared-host option skipped only the nondeterministic wall-clock assertion while retaining the
deterministic 10,000-row projection contract.

Next suggested task: Push this focused review closeout to PR #28 and merge only after owner
approval. Begin C2-02 only after the merge and a new explicit owner instruction.

## 2026-08-12 — Session 94 — Extract and close the C2-01 StoreKit contract runner

Goal: Apply the final C2-01 maintainability recommendation, preserve the exact catalog/isolation
contract, and merge PR #28 only after complete validation and green CI.

What was completed: Extracted the approximately 330-line StoreKit catalog, project-resource, and
scheme contract from the Shell heredoc into importable `Scripts/storekit_catalog_contract.py`.
Reduced `check-storekit-test-catalog.sh` to a thin repository entry point and moved all accepted and
rejected fixtures into nine standard `unittest` cases that exercise the same functions used for the
real repository. Updated the durable commercialization decision, packet, CI baseline, and project
memory to record the new boundary. After owner approval, marked C2-01 Done while leaving C2-02
unstarted and blocked on a fresh explicit instruction.

What was NOT completed: No runtime StoreKit catalog, product loading, transaction listener,
entitlement authority/cache, purchase, restore, status mapping, paywall, customer price/trial,
formal App Store Connect product, schema, network/cloud/provider, version, Archive, upload, tester,
or distribution state changed. C2-02 was not started.

Validation result: pass under Xcode 26.6. All static money, empty-egress, commercialization-
document, feature-access, StoreKit-catalog, release-readiness, and diff gates passed. The extracted
contract's nine Python tests passed. Full validation passed the Release build, 293 Swift tests in
19 suites, all 13 UI tests with zero failures, and every selected core-service coverage threshold.
The documented shared-host option skipped only the nondeterministic wall-clock assertion while
retaining the deterministic 10,000-row projection contract.

Next suggested task: Wait for a fresh explicit owner instruction before beginning C2-02.

## 2026-08-12 — Session 95 — Implement COM-C2-02 runtime StoreKit authority

Goal: Implement the runtime catalog and verified entitlement store inside the accepted C2-02
boundary while keeping purchases, restores, customer terms, paywall, and distribution out of
scope.

What was completed: Added exact Monthly/Annual StoreKit product loading and validation,
environment/storefront-scoped presentation caching with Delete All cleanup, and a shared dynamic
feature-access authority backed only by verified current entitlements. The entitlement actor owns
one transaction-update listener, re-reads current state after signals, rejects mixed/unverified/
unknown states, and prevents stale suspended reconciliation from overwriting newer authority.
App UI and App Intents share this authority. Added focused catalog, cache, concurrency, lifecycle,
failure-closed, and stale-read tests, plus dedicated opt-in CHN/USA local StoreKit probes. Updated
the commercial decision, packet, matrix, requirements, network policy, project memory, task
status, CI evidence, and detailed commercial session log. C2-02 is implementation-complete and
awaiting focused review.

What was NOT completed: No purchase, restore, transaction finish, subscription status UI,
paywall, persistent entitlement cache, formal product/customer price/trial/quota, schema,
app-owned network/cloud/provider channel, version, Archive, upload, tester, or distribution state
changed. Xcode command-line tests did not receive the Run-action StoreKit configuration, and the
local Xcode GUI crashed before the dedicated scheme could run, so the two framework-backed
storefront probes remain explicitly unclaimed rather than reported as passing.

Validation result: pass under Xcode 26.6. All static gates and the Release build passed. The full
suite passed 303 Swift tests in 20 suites and all 13 UI tests with zero failures; every selected
coverage threshold passed. The StoreKit Python contract suite passed 11 tests. Default-scheme
execution honestly skipped the two opt-in framework-backed storefront probes.

Next suggested task: Review C2-02 as one focused PR, capture or explicitly accept the remaining
dedicated local-StoreKit evidence, and mark the packet Done only after owner approval and green CI.

## 2026-08-12 — Session 96 — Close COM-C2-02 focused review findings

Goal: Resolve PR #29's StoreKit expiration, probe-evidence, and live UI revocation findings while
remaining inside C2-02 and keeping distribution paused.

What was completed: Preserved verified transaction revocation and expiration as separate raw
facts. Revoked current entitlements remain fail-closed; a past expiration no longer preempts the
C2-03 billing-grace/status decision. Added direct regressions for both cases and proved the shared
AppSession publishes exact Free -> Pro -> exact Free to SwiftUI consumers without restart. The
dedicated CHN/USA local StoreKit probes were made to execute under Xcode 26.6 RC `17F109` and iOS
26.5, where StoreKit returned `SKInternalErrorDomain Code=3` and empty product sets. No pass is
claimed. A false-green scheme variation that silently skipped the probes was rejected and is now
blocked by a Python contract test. Durable COM decisions, entry gates, matrices, requirements,
project memory, task state, and CI evidence were synchronized; C2-03 is blocked until both probes
execute and pass under a supported final Xcode GUI/toolchain.

What was NOT completed: No purchase, restore, final subscription-status mapper, transaction
`finish()`, paywall, entitlement persistence, customer price/trial/quota, formal App Store Connect
product, schema, network/cloud/provider path, user-visible released behavior, version, Archive,
upload, tester, or distribution state changed. C2-02 remains implementation-complete and pending
owner review rather than Done.

Validation result: pass under Xcode 26.6 with the documented shared-host wall-clock exclusion.
All static gates and the Release build passed. The full selected suite passed 306 Swift tests in
20 suites and all 13 UI tests; every selected coverage threshold passed. The StoreKit contract
suite passed 12 Python tests, and the focused StoreRuntime suite passed all 11 tests. A separate
strict run recorded only the known local 10,000-row wall-clock signal at 0.830 seconds; the final
run skipped that nondeterministic 500 ms assertion while retaining its deterministic 10,000-row
projection companion.

Next suggested task: Push the remediation to PR #29 and wait for owner approval plus green CI.
After merge, mark C2-02 Done; C2-03 remains blocked by its framework-probe entry gate.

## 2026-08-13 — Session 97 — Close COM-C2-02 and recheck the StoreKit entry gate

Goal: Close the merged C2-02 packet and re-evaluate the C2-03 runtime-probe prerequisite under
the final Xcode toolchain without beginning the next packet.

What was completed: Recorded PR #29's green CI and merge as `a45d480`; C2-02 is now Done. Final
Xcode 26.6 build `17F113` ran both CHN/USA probes on final iOS 26.4 and 26.5 runtimes, but StoreKit
returned `SKInternalErrorDomain Code=3` and empty products while `storekitd` reported an Octane
entitlement/development-install handshake failure. Recorded final SDK build `23F81a`, installed
iOS 26.5 runtime build `23F77`, and the fact that Apple's offered export was the older `23F73`;
it was not imported and could not replace the installed runtime. The same 16 tests in 2 suites pass on iOS 27 beta only as
diagnostic evidence. Updated the durable main/commercial memories, C2 packet, matrix, requirement,
decision, and CI evidence without erasing the historical Xcode RC `17F109` failure.

Direct Apple download queries for build `23F81` and iOS `26.5.1` both returned unavailable. The
older exported `23F73` bundle was removed from temporary storage without import; installed runtime
`23F77` was preserved.

What was NOT completed: C2-03 remains Blocked; no supported-final-runtime storefront-probe pass
is claimed. No purchase, restore, status mapper, transaction finishing, paywall, commercial term,
formal product, schema, app-owned network/provider path, version, Archive, upload, tester, or
distribution state changed.

Validation result: pass under final Xcode 26.6 build `17F113` with the documented shared-host
wall-clock exclusion. All static gates, the Release build, 306 selected Swift tests in 20 suites,
all 13 UI tests, and every selected coverage threshold passed. The StoreKit Python contract suite
passed all 12 tests, and the closeout passed `git diff --check`.

Next suggested task: Resolve the supported-final-runtime StoreKit Octane/development-install
handshake and obtain passing CHN/USA probes before marking C2-03 In Progress.

## 2026-08-13 — Session 98 — Verify the restarted global Xcode toolchain

Goal: Verify the owner's manual global Xcode selection and Mac restart, then re-run the blocked
StoreKit entry probes without beginning C2-03.

What was completed: Confirmed that machine-wide `xcode-select`, default `xcodebuild`, `xcrun`, and
`simctl` now all resolve to final Xcode 26.6 build `17F113`. Xcode first-launch status is complete
and CoreSimulator services respond normally. Re-ran only `StoreKitTestCatalogTests` through the
dedicated non-Archive scheme on final iOS 26.5 runtime build `23F77`: 5 tests executed, 3 passed,
and the CHN/USA runtime probes both executed without skipping but failed with
`SKInternalErrorDomain Code=3` and empty products. The former auxiliary `xcrun`/`simctl` lookup
error is gone, proving global toolchain selection was fixed but was not the StoreKit root cause.

What was NOT completed: C2-03 remains Blocked. No purchase, restore, status mapper, transaction
finish, paywall, formal product, commercial term, schema, network/provider path, app version,
Archive, upload, tester, or distribution state changed.

Evidence: `/private/tmp/MindBudget-C2-02-Restart-17F113-iOS26.5-23F77.xcresult` and
`/private/tmp/mindbudget-storekit-restart-17F113-ios265-23F77.log`. The remaining prerequisite is a
supported final runtime on which both storefront probes execute and pass.

## 2026-08-13 — Session 99 — Pass the COM-C2-03 StoreKit entry gate on a physical device

Goal: Obtain supported-final runtime evidence for the CHN/USA local StoreKit probes without
starting purchase behavior or weakening the fail-closed commercialization gate.

What was completed: Final Xcode 26.6 build `17F113` ran the dedicated non-Archive
`MindBudget-StoreKit-Local` scheme on the connected physical `拉沙的iPhone` (`iPhone Air`) with
final iOS 26.6.1 build `23G82`. `StoreKitTestCatalogTests` completed 5 passed, 0 failed, 0 skipped.
Both the CHN and USA runtime product-loading probes executed and passed, with no empty catalog and
no `SKInternalErrorDomain Code=3`. `xcresulttool` independently confirmed the physical arm64
device, OS/build, all five test names, and the totals. The accepted evidence changes C2-03 from
Blocked to In Progress; historical simulator failures and beta diagnostic results remain intact.

Evidence: `/private/tmp/MindBudget-C2-03-Physical-Unlocked-iOS26.6.1-17F113.xcresult`.

What was NOT completed: No C2-03 source, purchase, restore, status mapper, transaction finish,
paywall, formal product or customer term, schema, network/provider channel, app version, Archive,
upload, tester, or distribution state changed. The public/TestFlight distribution hold remains.

Validation result: pass under final Xcode 26.6 `17F113` with the documented shared-host
wall-clock exclusion. All static gates and the Release build passed; 306 Swift tests in 20 suites
and all 13 UI tests passed; every selected coverage threshold remained above 85%; and
`git diff --check` passed.

Next suggested task: Begin only the C2-03 purchase/restore/status work described by the focused
execution packet, then stop for review before C2-04 or any customer-facing/paywall/release work.

## 2026-08-13 — Session 100 — Prepare COM-C2-03 for independent review

Goal: Complete the bounded C2-03 StoreKit lifecycle implementation without adding customer-facing
commerce or advancing any later commercialization/release phase.

What was implemented: The existing single `EntitlementStore` now owns complete verified
subscription-state mapping, explicit typed purchase and restore seams, one whole-snapshot
authority publication path, unfinished transaction processing, and transaction acknowledgement.
Subscribed and verified billing grace grant Pro; billing retry, expired, revoked, unknown,
unverified, pending, mixed, and incomplete-free input grant no new right. A handled verified
transaction is reconciled and published before finish. Failed finish remains unfinished and can be
retried, while duplicate/concurrent delivery cannot finish the same transaction twice in process.

Evidence status: The implementation candidate and its deterministic/opt-in StoreKit tests are
ready for independent review. **Final test counts, full validation, CI, coverage, and merge evidence
are pending and are not claimed here.** The physical iPhone Air 5/0/0 CHN/USA catalog run remains
the C2-03 entry proof only; historical simulator failures and beta diagnostic evidence remain
preserved rather than reclassified.

What was NOT changed: No current view invokes purchase or restore; no paywall, visible purchase
entry, formal customer price/trial/product, version, Archive, upload, tester assignment, app-owned
network destination, or distribution state changed. The 0.9.6 binary and release hold are
unchanged. C2-03 is implementation complete but not Done; C2-04 and C3 remain blocked.

Next suggested task: Perform independent C2-03 review and the owning validation run, then record
actual evidence before merge. Do not begin later packets early.

## 2026-08-13 — Session 101 — Supervise StoreKit status signals inside the existing C2-03 authority

Goal: Ensure retry or expiry can revoke access promptly even when StoreKit emits no new
transaction, without creating a second lifecycle owner or advancing beyond C2-03.

What changed: The existing `EntitlementStore` lifecycle task now supervises both transaction and
subscription-status update sequences. A status signal has no independent authority; it causes a
fresh full reconciliation through the same actor and central access publication path. The
purchase/restore, status mapper, unfinished retry, and publish-before-finish boundaries are
otherwise unchanged.

Evidence status: Final focused and full test totals, coverage, CI, independent review, and merge
evidence remain pending. No prior StoreKit entry-probe result is reused as proof of this change.

What was NOT changed: There is no second authority, new UI, paywall, formal product/term, version,
Archive, upload, tester assignment, app-owned network destination, or distribution change. C2-03
remains implementation complete and pending independent review; C2-04 and C3 remain blocked.

## 2026-08-13 — Session 102 — Complete local COM-C2-03 validation without advancing its review gate

Goal: Finish the bounded C2-03 local verification record after the final StoreKit lifecycle and
concurrency fixes, without advancing C2-04, C3, customer commerce UI, or distribution.

What was completed: The single `EntitlementStore` authority now has independently reviewed
fail-closed handling for subscription-state signals, restore provenance, same-transaction fact
conflicts, crossgrades, duplicate/concurrent delivery, authoritative publication, and transaction
finish retry. The focused lifecycle/runtime run passed 44/44. The 31-test lifecycle suite passed
10 consecutive iterations (310/310). The strict 500 ms Dashboard wall-clock signal separately
passed 10/10 isolated iterations. The full shared-host run excluded only that already-isolated
wall-clock signal through the existing validation switch and continued to execute the
deterministic 10,000-row projection contract.

Validation result: Release and build-for-testing passed; 342 Swift tests completed with zero
failures (338 passed, 4 dedicated StoreKit runtime probes skipped by design), and all 13 UI tests
passed. The combined result is 355 total, 351 passed, 4 skipped, 0 failed. Every selected coverage
file remains above 85%, ranging from CSVExporter at 87.60% to CurrencyFormatterService at 100%.
All static money, network, commercialization-document, feature-access, StoreKit-catalog,
release-readiness, and diff gates passed. Evidence:
`/private/tmp/MindBudget-C203-Full-Final15.xcresult`.

What was NOT completed: CI and merge evidence remain pending. The four opt-in StoreKit runtime
probes were not reclassified as default-scheme evidence; presented `Product.purchase()` and a
stable framework grace transition remain later UI/runtime obligations. No paywall, formal
product/price/trial, version, Archive, upload, tester assignment, app-owned network destination,
or distribution state changed. C2-03 remains implementation complete pending independent review,
green CI, and merge; C2-04 and C3 remain blocked.

Next suggested task: Open the C2-03 review unit and wait for independent review plus green CI
before merge. Do not begin the next packet early.

## 2026-08-13 — Session 103 — Clarify C2-03 actionability and restore concurrency invariants

Goal: Resolve the first PR review's naming/readability concern while preserving the accepted
C2-03 purchase/restore/status boundary.

What changed: Renamed the lifecycle resolution flag from `isAuthoritative` to `isActionable`.
Tests now explicitly pin that actionable means safe to use, not necessarily a complete
supplemental Product/catalog read: a separately verified paid fact survives a catalog-only
failure, while incomplete Free and unverified input remain fail-closed. Consolidated the actor's
three coordination mechanisms into one documented invariant block covering whole-snapshot
generation order, active acknowledgement-batch ownership, restore transaction provenance, and
continuation completion. The existing deterministic test harness injects suspension gates at
publish, finish, sync, and active-batch wait points; repeated runs remain stability evidence, not
the sole interleaving argument.

Review disposition: Did not delete the post-sync restore bridge. C2-03 is the accepted owner of
purchase, restore, and status mapping; C2-04 owns environment isolation. StoreKit can deliver the
verified restored transaction before `currentEntitlements` catches up, and the bridge prevents a
valid restore from being reported as empty. Only completed verified transaction evidence may
bridge; ordinary refreshes cannot, and newer revoked/unverified authority prevents stale paid
facts from being reused.

What was NOT changed: No runtime behavior, customer UI, paywall, formal product/term, version,
Archive, upload, tester assignment, network destination, or distribution state changed. C2-03
remains implementation complete pending re-review, green CI, and merge; C2-04/C3 remain blocked.

Validation result: The focused lifecycle/runtime suites passed 45/45 after the rename. Static
money, network, commercialization-document, StoreKit-catalog/environment-isolation, and diff
gates passed. This review response changes no state-machine behavior, so the existing complete
local validation and coverage evidence remains applicable.

## 2026-08-13 — Session 104 — Trace C2-03 concurrency gates and narrow framework evidence claims

Goal: Resolve the second review's evidence-location question without changing the reviewed
StoreKit lifecycle behavior.

What changed: Linked the consolidated actor invariant comment to the actual owning test files.
`StoreLifecycleDomainTests.swift` contains the 31 deterministic lifecycle tests, including gates
that suspend publication callbacks, transaction finish, `AppStore.sync()`, and active-batch
waiting. `StoreRuntimeTests.swift` contains 14 tests, including the separate delayed-first-read
gate; together they produced the focused 45/45 result. The PR and StoreKit matrix now make those
locations explicit instead of requiring a reviewer to infer the second test file from totals.

Evidence boundary: Mapper tests deliberately start after StoreKit verification has been projected
into app-owned boolean facts. They do not independently prove the private
`verifiedRecord(from:status:)` correlation of original IDs, environments, Product IDs, status
transactions, renewal info, and crossgrade preference. Only the opt-in Monthly/Annual StoreKit
integration flows enter the regular production derivation with real framework objects; default
coverage is not claimed as proof of that seam, and real crossgrade/malformed-status transitions
remain later controlled runtime evidence.

What was NOT changed: No production behavior, purchase/restore policy, entitlement result,
customer UI, commercial term, later phase, release artifact, or distribution state changed.
C2-03 remains implementation complete pending re-review, green CI, and merge.

## 2026-08-13 — Session 105 — Close C2-03 and start verified StoreKit environment isolation

Goal: Close the reviewed/merged C2-03 packet and begin only C2-04 without changing customer-visible
commerce or distribution behavior.

C2-03 closeout: PR #30 passed independent review and green CI, then merged to `main` as `3fc72b4`
on 2026-08-13. The complete GitHub Actions run passed in 14m26s:
<https://github.com/xdgf558/MindBudget/actions/runs/31675470258>. C2-03 is Done.

C2-04 work: StoreKit authority now requires a separately verified `AppTransaction` bundle and
environment. Every transaction/status fact must match the same Xcode, Sandbox, or Production
environment; TestFlight follows Apple's Sandbox environment and cannot be relabeled by Release
configuration. Wrong bundle, missing/unknown environment, or cross-environment input fails closed.
The exact environment/storefront presentation cache remains non-authoritative, and catalog-only
failure still preserves an independently verified active subscription. Static validation keeps the
app-transaction reader and entitlement-read construction inside Commerce.

Validation: Production/test compilation and all static gates pass. Focused StoreKit
environment/lifecycle tests passed 48/48. The strict Phase 10 suite passed 20/20 across 10
isolated iterations. The owning shared-host run completed 345 Swift tests (341 passed and 4
explicit StoreKit runtime probes skipped), all 13 UI tests, and every selected coverage gate;
combined result: 358 total, 354 passed, 4 skipped, 0 failed. Evidence:
`/private/tmp/MindBudget-C204-WallClockSuite-10x.xcresult` and
`/private/tmp/MindBudget-C204-Full-Shared.xcresult`. An initial unsplit run measured the
environment-sensitive 500 ms signal at 0.814 seconds and then hit Xcode's 600-second diagnostics
timeout; it is not used as passing evidence. C2-04 is implementation complete pending independent
review, green CI, and merge; C3 remains blocked.

What was NOT changed: No purchase/restore View, paywall, formal product or term, version, Archive,
upload, tester assignment, app-owned network destination, or distribution action was added. The
uploaded 0.9.6 binary and release hold are unchanged.

## 2026-08-13 — Session 106 — Make C2-04 purchase preflight use independent app authority

Goal: Resolve the first independent review of PR #31 without expanding the accepted C2-04 scope.

What changed: `StoreEntitlementSourcing` now exposes the independently verified app environment
owned by the Commerce `AppTransaction` provider. Purchase-result preflight compares the verified
transaction against that independent value instead of deriving the app environment from the same
transaction under review. A regression proves a Sandbox purchase result is rejected before
publication or `finish()` when the verified app authority is Production. Product presentation may
still use an explicit `Unknown` cache partition when app verification is unavailable, but durable
documentation now states that this partition is non-authoritative and cannot grant or preserve a
paid right.

Evidence boundary: The StoreKit matrix now names all three app-owned projection booleans—
`hasVerifiedStatusTransaction`, `hasVerifiedRenewalInfo`, and `hasVerifiedAppBundle`—as values
whose policy consumption is unit tested while their private StoreKit derivation is evidenced only
by the opt-in production-bridge probes. The focused lifecycle/runtime suites passed 49/49. The
strict Phase 10 signal passed 10/10 isolated iterations. The clean shared-host run completed 346
Swift tests (342 passed and 4 explicit StoreKit runtime probes skipped), all 13 UI tests, and the
coverage gate: 359 total, 355 passed, 4 skipped, 0 failed. Evidence:
`/private/tmp/MindBudget-C204-ReviewFix-Focused.xcresult`,
`/private/tmp/MindBudget-C204-ReviewFix-WallClockSuite-10x.xcresult`, and
`/private/tmp/MindBudget-C204-ReviewFix-Full-Shared-Retry.xcresult`.

What was NOT changed: No customer purchase or restore View, paywall, formal product/price/trial,
version, Archive, upload, tester assignment, app-owned network destination, C3 work, or
distribution state changed. C2-04 remains implementation complete pending re-review, green CI,
and merge; the post-0.9.6 release hold remains active.

## 2026-08-13 — Session 107 — Close C2-04 and COM-C2 after reviewed green merge

Goal: Record the independently reviewed C2-04 merge as durable state and close COM-C2 without
starting COM-C3 or changing customer-visible commerce.

Closeout evidence: PR #31 passed independent review and the complete GitHub Actions validation,
then merged to `main` as `a293762` on 2026-08-13. CI run:
<https://github.com/xdgf558/MindBudget/actions/runs/31701374466>. The accepted local evidence
remains 49/49 focused environment/lifecycle tests, 20/20 strict Phase 10 executions across 10
iterations, and 359 total results in the owning full validation: 355 passed, 4 explicit opt-in
StoreKit runtime probes skipped, and 0 failed. Every selected coverage threshold passed.

State transition: C2-04 is Done and COM-C2 is complete. The technical StoreKit catalog,
lifecycle authority, status mapping, purchase/restore programmatic seams, finish ordering, and
verified AppTransaction environment isolation are merged. COM-C3 is not active: accepted
price/trial inputs and a new explicit owner instruction are still required before paywall or
customer-visible purchase/restore work begins.

What was NOT changed: This closeout changes documentation and executable documentation gates
only. No app source behavior, schema, formal App Store Connect product, customer price/trial/
offer, paywall, purchase/restore View, version, Archive, upload, tester assignment, app-owned
HTTP(S), or distribution action changed. The post-0.9.6 release hold remains active.

Closeout verification: All four standalone COM static commands passed again. The complete
`Scripts/validate.sh` flow also passed with the documented shared-host wall-clock exclusion:
359 total results, 355 passed, 4 explicit opt-in StoreKit runtime probes skipped, and 0 failed.
Every selected core-service coverage threshold remained at or above 85%. Result bundle:
`/private/tmp/MindBudget-C204-Closeout.xcresult`.

## 2026-08-14 — Session 108 — Tighten completed-phase documentation assertions

Goal: Resolve the post-merge PR #32 gate-maintenance note before opening COM-C3 implementation.

What changed: The commercialization documentation gate again requires the complete active-release
hold phrase and the complete `C2-04 and COM-C2 are Done` phase result. The CI baseline keeps that
completion phrase on one line so the executable assertion cannot pass on an unrelated future
sentence prefix. The existing structural `hasVerified*` evidence boundary remains unchanged
because the StoreKit matrix already names all three projected booleans and their opt-in runtime
evidence level.

What was NOT changed: No phase status, Swift source, StoreKit behavior, price, trial, storefront,
product, entitlement, release artifact, or distribution state changed. COM-C3 had not started at
the time of this isolated maintenance commit.

## 2026-08-14 — Session 109 — Implement the voluntary C3-01 Pro presentation

Goal: Implement only C3-01 under the owner's provisional nonpublic test inputs: USD 1.99 monthly,
USD 19.99 annually, one 7-day trial per product, and initial HKG/USA/SGP/TWN storefront coverage.

What changed: Added a bilingual Pro screen reachable only from Settings or an explicit Pro value
trigger, with zero automatic presentations. It lists only the exact current Pro features, renders
localized StoreKit prices and fresh trial eligibility, states renewal terms, links local Terms and
Privacy, and exposes explicit purchase, restore, and manage-subscription controls through the
existing typed `EntitlementStore` authority. Cached or unavailable catalog state cannot enable a
purchase. The local StoreKit Configuration and its contract now require the two accepted product
IDs, P1M/P1Y periods, one P1W free trial each, USD 1.99/USD 19.99 test prices, and
HKG/USA/SGP/TWN probes.

Accepted evidence: Final Xcode 26.6 `17F113` ran the dedicated non-Archive scheme on the physical
`拉沙的iPhone` (`iPhone Air`) with final iOS 26.6.1 `23G82`; all 9 tests passed, including the
four storefront catalog probes and both Monthly/Annual verified transaction and finish paths.
The strict Phase 10 suite passed 20/20 across 10 isolated iterations. The owning shared-host full
validation passed 364 total results: 358 passed, 6 explicit opt-in StoreKit runtime probes skipped,
and 0 failed; all 14 UI tests and every selected coverage threshold passed. The 13-test Python
catalog contract and all standalone COM gates pass. Evidence:
`/private/tmp/MindBudget-C301-Storefronts-Physical.xcresult`,
`/private/tmp/MindBudget-C301-Phase10-10x.xcresult`, and
`/private/tmp/MindBudget-C301-Full-Shared.xcresult`.

State: C3-01 is implementation complete pending independent review, hosted green CI, and merge;
it is not Done. C3-02 and later packets remain blocked.

What was NOT changed: No formal App Store Connect product, public price/trial/offer, paywall
frequency automation, receipt import, schema, version, Archive, upload, tester assignment,
app-owned HTTP(S), or distribution action was added. The uploaded 0.9.6 build and post-0.9.6
release hold remain unchanged.

## 2026-08-14 — Session 110 — Make the C3-01 purchase surface fail closed under uncertainty

Goal: Close the first PR #33 review findings while keeping provisional promotional terms isolated
from production authority.

What changed: Production StoreKit validation no longer requires an exact seven-day introductory
offer; the exact P1W term remains owned by the local Configuration, Python contract, and opt-in
runtime probes. Customer presentation uses the actual optional StoreKit offer and fresh
eligibility. An unavailable entitlement snapshot now pauses purchase in both the Pro View and the
actor before StoreKit is invoked, with an explicit subscription-status recheck. Renewal disclosure
uses the app-selected SwiftUI locale, including when the device language differs. Added direct
regressions for a missing/changed promotion, unavailable-authority source suppression, View gating,
and explicit English/Simplified-Chinese renewal formatting. Durable commercial decisions,
requirements, matrices, current memory, changelog, and executable StoreKit checks were aligned.

Evidence: Focused Store runtime/lifecycle tests passed 53/53. Full validation passed 366 total:
360 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed; all 14 UI tests and
every selected coverage threshold passed. The StoreKit Python contract passed 13/13 and all
standalone release, money, network, commercialization-document, feature-access, localization, and
diff checks pass. Evidence: `/private/tmp/MindBudget-C301-ReviewFix-Focused.xcresult` and
`/private/tmp/MindBudget-C301-ReviewFix-Full.xcresult`.

State: C3-01 remains implementation complete pending independent re-review, hosted green CI, and
merge. C3-02 and all distribution work remain blocked.

What was NOT changed: No formal App Store Connect product, public economics, automatic paywall,
schema, network destination, version, Archive, upload, tester assignment, or distribution action
changed. The uploaded 0.9.6 build and release hold are unchanged.

## 2026-08-14 — Session 111 — Pause unsupported paid introductory offers before purchase

Goal: Close the second PR #33 review finding without misstating a paid introductory offer's price
or schedule and without changing entitlement authority.

What changed: The StoreKit presentation projection now preserves the offer's localized price and
complete payment-mode raw value. C3-01 remains free-trial-only: an eligible installment,
up-front, or future unknown introductory mode produces a bilingual unsupported-offer notice and
cannot call `Product.purchase()` from either the View or the concrete StoreKit source. An
ineligible paid offer still permits the ordinary subscription. Added direct regressions for paid
installment, paid upfront, ineligible, and unknown modes; updated the StoreKit boundary script,
decision, requirement, matrix, execution packet, memory, and changelog.

Evidence: Full shared-host validation passed 369 total results: 363 passed, 6 explicit opt-in
StoreKit runtime probes skipped, and 0 failed. All 14 UI tests and every selected coverage gate
passed. The 13-test Python StoreKit contract and all standalone release, money, network,
commercialization-document, feature-access, localization, StoreKit-isolation, and diff gates
pass. Evidence: `/private/tmp/MindBudget-C301-PaidOffer-ReviewFix-Full.xcresult`.

State: C3-01 remains implementation complete pending independent re-review, hosted green CI, and
merge. C3-02 and distribution remain blocked.

What was NOT changed: No formal App Store Connect product, public economics, automatic paywall,
entitlement rule, schema, network destination, version, Archive, upload, tester assignment, or
distribution action changed. The uploaded 0.9.6 build and release hold are unchanged.

## 2026-08-14 — Session 112 — Implement C3-02 trial lifecycle without inventing trial facts

Goal: Enter C3-02 only and add truthful active-trial presentation plus renewal reminder behavior
on top of the merged C3-01 purchase surface.

What changed: Commerce now publishes a process-local trial lifecycle only when the verified
current StoreKit transaction is an introductory free trial and verified renewal information
provides the actual renewal date and auto-renew state. One stable local reminder is reconciled at
five user-calendar days before renewal; it is removed/replaced on cancellation, expiry,
revocation, product/date changes, or missing authority. Reconciliation never requests permission,
uses an in-app fallback when it cannot schedule, and keeps the generic notification free of date,
price, amount, product, ledger data, or remaining-day counts. Settings Pro and Dashboard show the
verified lifecycle, using a current live StoreKit price only when available. Launch, foreground,
language, notification-preference, and entitlement changes use the same scheduler. Added 12 direct
trial tests, framework-backed Monthly/Annual derivation assertions, bilingual localization, and
static boundary/document gates. No configured P1W fixture or cached offer can create a lifecycle.

Evidence: Focused entitlement/lifecycle/runtime validation passed 68/68. Full validation passed
381 total results: 375 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed;
all 14 UI tests and every selected coverage threshold passed. Evidence:
`/private/tmp/MindBudget-C302-Focused.xcresult` and
`/private/tmp/MindBudget-C302-Full-Final2.xcresult`. The final physical iPhone Air/iOS 26.6.1
StoreKit suite passed 9/9 with no failure or skip, covering HKG/USA/SGP/TWN and both Monthly/Annual
trial-lifecycle derivation paths; evidence: `/private/tmp/MindBudget-C302-Physical4.xcresult`.
The first completed physical run also exposed and closed an old test-only locale defect: runtime
free-trial zero prices now remain StoreKit-localized instead of being fixed to the USA literal;
the isolated fixture contract still owns the exact provisional USD text.

State: C3-02 is implementation complete pending independent review, hosted green CI, and merge;
it is not Done. C3-03, final economics/products, versioning, Archive/upload, tester assignment,
and distribution remain blocked.

## 2026-08-20 — Session 138 — Confirm the C4A-02 retry-only recovery boundary

The owner accepted the product-level item raised by independent PR #53 review. C4A-02 keeps the
existing `StoreRecoveryView` retry-only. If both the live store and trusted recovery snapshot are
unusable, the present recovery path is deleting the app data container or reinstalling because
the in-app Delete All workflow requires an opened store.

Any in-app destructive reset is deferred to a separate C4A-03 Accepted decision and test contract.
This record changes no Swift, schema, data, migration, network, version, or distribution behavior.
PR #53 still awaits hosted green CI and merge; C4A-03 remains blocked.

What was NOT changed: No signed public configuration, formal product or trial term, automatic
paywall, receipt import, schema, network destination, version, Archive, upload, tester assignment,
or distribution action changed. The uploaded 0.9.6 build and release hold are unchanged.

## 2026-08-14 — Session 113 — Fix C3-02 renewal-plan price and pending reminder wording

Goal: Close the independent C3-02 review findings while keeping C3-03 and distribution blocked.

What changed: Trial lifecycle now distinguishes the current trial product from the verified
next-renewal product. A recognized `autoRenewPreference` owns next-period price disclosure; a
missing preference falls back to the current product, while an unknown explicit preference cannot
create a lifecycle projection. A same-date plan-switch regression proves the projection and live
price change. Pending bilingual local-notification copy now states that the trial ends soon and
asks the person to review current status instead of asserting renewal after the process stops.
The StoreKit and commercial-document gates were strengthened around both contracts.

Evidence: The targeted trial suite passed 13/13. Full validation produced 382 results: 376 passed,
6 explicit opt-in StoreKit runtime probes skipped, and 0 failed. All 14 UI tests, the Release
build, static gates, and selected coverage thresholds passed. Evidence:
`/private/tmp/MindBudget-C302-ReviewFix-Trial2.xcresult` and
`/private/tmp/MindBudget-C302-ReviewFix-Full.xcresult`. The prior PR head `71d7f54` had green
GitHub Actions run `31800476681`; the review-fix commit still requires a fresh hosted run.

State: C3-02 remains implementation complete pending independent re-review, hosted green CI, and
merge; it is not Done. C3-03, final economics/products, versioning, Archive/upload, tester
assignment, and distribution remain blocked.

What was NOT changed: No signed public configuration, formal product or trial term, automatic
paywall, receipt import, schema, network destination, version, Archive, upload, tester assignment,
or distribution action changed. The uploaded 0.9.6 build and release hold are unchanged.

## 2026-08-14 — Session 114 — Close C3-02 after PR #34 merge

Goal: Complete the C3-02 documentation closeout only, preserving the C3-03 and release gates.

What changed: The durable main and commercialization status now records that PR #34 passed
independent review and green GitHub Actions run `31803898776`, then merged as `12d9217` on
2026-08-14. C3-02 is Done. C3-03 has not started and remains blocked pending explicit owner
instruction and an accepted exact first-party configuration contract. The documentation gate now
requires the C3-02 completion evidence and rejects stale pending-review language in current-state
documents.

Evidence: Full closeout validation produced 382 results: 376 passed, 6 explicit opt-in StoreKit
runtime probes skipped, and 0 failed. All 14 UI tests, the Release build, static checks, and
selected coverage thresholds passed. Evidence:
`/private/tmp/MindBudget-C302-Closeout-Full.xcresult`. Existing physical-device C3-02 evidence
remains 9/9 with no failure or skip.

State: C3-01 and C3-02 are Done. C3-03 and C3-04 remain blocked; no C3-03 source work has begun.

What was NOT changed: No Swift behavior, signed public configuration, formal product or trial
economics, automatic paywall, receipt import, schema, network destination, version, Archive,
upload, tester assignment, or distribution action changed. The uploaded 0.9.6 build and release
hold are unchanged.

## 2026-08-14 — Session 115 — Implement C3-03A without opening a network channel

Goal: Begin the owner-authorized C3-03 recommended design with a separately reviewable local
verification/cache packet before any transport or presentation integration.

What changed: Added a strict Ed25519 signed public-configuration verifier, exact closed schema-v1
decoder, positive monotonic version and seven-day validity bounds, rollback/equivocation defense,
and an atomic file-protected signed cache with readback verification. The only configuration field
is the conservative optional-presentation boolean `proValueTriggersEnabled`; it cannot name or
change products, prices, trials, rights, notifications, cloud/AI, telemetry, Watch, or release
behavior. Invalid or unavailable input uses only a verified nonexpired cache and then built-in
`false`. Added eight focused tests and a self-tested static boundary gate, connected that gate to
local validation and CI, and recorded the exact future environment-isolated Worker/GET/privacy
contract in durable COM documentation. The second transport/integration packet remains blocked.

Evidence: The focused suite passed 8/8. Final full validation produced 390 results: 384 passed, 6
explicit opt-in StoreKit runtime probes skipped, and 0 failed; all 14 UI tests, Release build,
static gates, and selected coverage thresholds passed. The strict local performance signal passed
10/10 isolated iterations; one earlier shared-host measurement of 0.822698 seconds is recorded as
nonpassing diagnostic evidence. Results:
`/private/tmp/MindBudget-C303A-Focused3.xcresult`,
`/private/tmp/MindBudget-C303A-Full-Final.xcresult`, and
`/private/tmp/MindBudget-C303A-StrictPerformance.xcresult`.

State: C3-03A is implementation complete pending independent review, hosted green CI, and merge;
it is not Done. C3-03B, C3-04, formal economics/products, versioning, Archive/upload, tester
assignment, and distribution remain blocked.

What was NOT changed: No app-owned HTTP(S), URL, runtime adapter, Production verification key,
Worker deployment, app consumer, user-facing behavior, entitlement/StoreKit authority, schema,
version, Archive/upload, tester assignment, or distribution action was added. The uploaded 0.9.6
build and post-0.9.6 release hold are unchanged.

## 2026-08-15 — Session 116 — Harden C3-03A persistence and byte contracts after review

Goal: Resolve the independent PR #36 findings that affect rollback recovery, concurrent high-water
ordering, exact signed-byte interoperability, and persistence confirmation without advancing the
blocked transport packet.

What changed: Corrupt rollback state is now a documented sticky Release fail-closed condition:
normal Delete All, Offload, later remote bytes, and Release code cannot reset it; current recovery
requires deleting the app data container and reinstalling. File persistence uses explicit async
protocol witnesses. Remote acceptance serializes the complete read/compare/write/read-back
transaction so actor reentrancy cannot let a lower version overwrite a higher one, and a purported
write must re-read and re-verify the exact intended snapshot through the persistence abstraction
before returning `.remote`. Signed payload timestamps now use exact whole-second UTC grammar;
duplicate envelope or payload keys are rejected before Foundation decoding. A fixed Ed25519 golden
vector is independent of the test fixture encoder, while real Worker-produced bytes remain a
C3-03B gate. Added deterministic concurrency, no-op
persistence, malformed high-water, zero-validity, duplicate-key, and timestamp regressions.

Decision notes: We did not add client-side canonical JSON or require sorted keys: exact emitted
payload bytes remain the signature authority, while fixed timestamps and duplicate-key rejection
remove the relevant ambiguity. The real Worker does not exist in C3-03A, so a Worker-produced
golden response remains a C3-03B acceptance item. We also did not add `os_log`, rename the
controller, or parameterize fixed security bounds. C3-03B owns closed non-content reason codes once
a real transport/operations channel exists; payload and signature bytes may never be logged.

Evidence: The expanded focused suite passed 12/12 at
`/private/tmp/MindBudget-C303A-ReviewFix-Focused.xcresult`. Public-configuration,
commercialization-document, network-egress, shell-syntax, and diff checks pass. Final owning full
validation produced 394 results: 388 passed, 6 explicit opt-in StoreKit runtime probes skipped,
and 0 failed. All 14 UI tests, the Release build, every selected coverage threshold, and the
complete static gate set passed. Evidence:
`/private/tmp/MindBudget-C303A-ReviewFix-Full3.xcresult`. Fresh hosted CI remains pending before
merge.

State: C3-03A remains implementation complete pending independent re-review and green CI; it is
not Done. C3-03B and C3-04 remain blocked.

What was NOT changed: No URL, network adapter/request, Production public key, Worker deployment,
application consumer, user-visible behavior, entitlement/StoreKit authority, schema, version,
Archive/upload, tester assignment, or distribution action was added. The Release app-owned
HTTP(S) allow-list remains empty and the post-0.9.6 release hold remains active.

## 2026-08-15 — Session 117 — Close C3-03A and activate C3-03B

Goal: Record the independently reviewed C3-03A merge and green hosted evidence before allowing
the fixed transport/integration packet to begin.

What changed: PR #36 review approved the signed-document verifier, sticky rollback failure,
serialized acceptance, exact UTC/no-duplicate-key byte contract, and persistence read-back
boundary. Its review-remediation head `3a53107` passed GitHub Actions run `31856271268`; PR #36
merged to `main` as `1ebb36c` on 2026-08-15. Current tasks, memories, requirements, decisions,
network policy, CI baseline, and execution packet now mark C3-03A Done and C3-03B In Progress.

Evidence: The closeout branch repeated the full validation with 394 total: 388 passed, 6 explicit
opt-in StoreKit runtime probes skipped, and 0 failed, including 14/14 UI tests, Release build,
static gates, and all selected coverage thresholds. Evidence:
`/private/tmp/MindBudget-C303A-Closeout-Full.xcresult`. Hosted run `31856271268` completed
successfully on the exact review-remediation head before merge.

State: C3-03A is Done. C3-03B is In Progress under DEC-COM-021's exact host, anonymous GET,
Production-key, privacy/log/TTL/redirect, captured-traffic, binary, and conservative-failure
gates. C3-04 remains blocked.

What was NOT changed: This closeout adds no URL, request, Release egress exception, Production
key, Worker deployment, application consumer, entitlement/StoreKit authority, schema, user-
visible behavior, version, Archive/upload, tester assignment, or distribution action. The empty
Release HTTP(S) allow-list and post-0.9.6 release hold remain active.

## 2026-08-15 — Session 118 — Implement C3-03B without opening Production distribution

Goal: Complete the fixed signed public-configuration transport/consumer packet after reviewed
C3-03A merge, retaining conservative fallback and all later release gates.

What changed: Added the exact environment-isolated anonymous GET adapter, embedded public key,
closed non-content diagnostics, signed cache/remote lifecycle integration, and one optional Pro-
value-trigger consumer. Added an independent Cloudflare Worker with strict host/path/method/header
validation, environment-specific 60/60 rate limiting, seven-day pre-signed envelopes, `no-store`,
disabled observability, and no private key/storage/outbound fetch/app logging. CI now runs Worker
typecheck, audit, tests, and Production dry-run. Static gates constrain the only app HTTP(S)
exception, non-Archive live scheme, Worker contract, and consumer boundary.

Operational evidence: The owner-controlled private key remains outside the repository.
Development Worker version `bf6c5049-a389-4ea7-af0a-e8425b8957e2` was the only deployment. The
real Development endpoint passed the dedicated app transport/verifier suite 8/8 with no skip;
Worker tests passed 13/13, audit found zero vulnerabilities, and typecheck/dry-run passed. The
owning shared-host full validation produced 402 results (395 passed, 7 explicit skips, 0 failed),
including 14/14 UI, Release build, static gates, and all selected coverage thresholds. The
isolated local performance signal passed 10/10. Evidence:
`/private/tmp/MindBudget-C303B-LiveWorkerFinal.xcresult`,
`/private/tmp/MindBudget-C303B-Full-Final.xcresult`, and
`/private/tmp/MindBudget-C303B-StrictPerformance.xcresult`.

State: C3-03B is implementation complete pending independent review and green hosted CI; it is
not Done. C3-04 remains blocked.

What was NOT changed: No Production/Staging deployment, schema vocabulary, paid authority,
StoreKit fact, product/price/trial, notification, user-content upload, telemetry, formal economics,
version, Archive/upload, tester assignment, or distribution action changed. The currently uploaded
0.9.6 binary and post-0.9.6 release hold remain unchanged.

## 2026-08-15 — Session 119 — Close C3-03B expiry, authority, and cancellation findings

Goal: Resolve the independent PR #38 lifecycle findings without broadening signed configuration,
StoreKit authority, Worker scope, or distribution permission.

What changed: Public-configuration verification now samples time only after the complete network
response arrives. Verified remote/cache resolutions carry their exact signed expiry, and AppSession
owns a cancellation-safe expiry schedule that replaces presentation with the conservative built-in
value at that instant even while the app remains foregrounded. The optional Pro-value trigger now
requires an actionable exact-Free StoreKit whole snapshot; initial, incomplete, unverified,
unavailable, and previously-paid-then-unverifiable authority never qualifies as Free. Refresh and
acceptance operations are throwing/cancellation-aware; caller cancellation cancels owned work and
is checked before request, verification/persistence, and publication.

Evidence: Generic simulator build-for-testing passed. The focused
`PublicConfigurationTransportTests` suite passed 11/11 with no failure or skip at
`/private/tmp/MindBudget-C303B-ReviewFix-Focused.xcresult`. Deterministic response, expiry,
StoreKit-authority, and cancellation gates exercise the three reviewed boundaries. Both signed-
configuration gates, network-egress gate, commercialization-document gate, shell syntax, and diff
check pass. The final owning validation, with the shared-load wall-clock signal separated as
designed, produced 405 results: 398 passed, 7 explicit opt-in/runtime skips, and 0 failed. The
Release build, 14/14 UI tests, all static gates, and every selected coverage threshold passed at
`/private/tmp/MindBudget-C303B-ReviewFix-FullFinal.xcresult`. The strict local Dashboard signal
separately passed 10/10 isolated iterations at
`/private/tmp/MindBudget-C303B-ReviewFix-StrictPerformance.xcresult`; the preceding shared-load
0.838828417-second miss is retained only as diagnostic evidence at
`/private/tmp/MindBudget-C303B-ReviewFix-Full.xcresult`. Hosted CI remains pending.

State: C3-03B remains implementation complete pending independent re-review and green hosted CI;
it is not Done. C3-04 remains blocked.

What was NOT changed: No payload/schema field, entitlement right, StoreKit product/price/trial,
Worker behavior or deployment, Production/Staging deployment, user content, telemetry, version,
Archive/upload, tester assignment, or distribution action changed. The post-0.9.6 release hold
remains active.

## 2026-08-15 — Session 120 — Close remaining C3-03B cancellation boundaries

Goal: Resolve the second PR #38 cancellation review without expanding the signed payload,
transport destination, presentation authority, Worker, or release permission.

What changed: The startup public-configuration refresh is now directly awaited by a dedicated
SwiftUI task, so view-task cancellation reaches the service instead of leaving detached work.
The startup one-time guard resets after cancellation so a recreated SwiftUI task can retry.
Scene-active refresh remains independently concurrent with local startup, but AppSession retains
it and cancels it on replacement, inactive/background transition, and Session destruction. File
persistence checks cancellation after actor entry and immediately before the atomic write; that
last check is the documented commit point. Cancellation before it cannot change the cache. Once
the non-suspending atomic commit starts it may complete, but canceled acceptance cannot publish.

Evidence: The combined `PublicConfigurationTests` and `PublicConfigurationTransportTests` run
produced 28 results: 27 passed, the explicit live Development Worker probe skipped, and 0 failed.
Deterministic tests cover startup caller cancellation, retained scene cancellation, Session
destruction, a pre-canceled real file write, and cancellation while a persistence actor is
suspended. Evidence: `/private/tmp/MindBudget-C303B-CancellationFix-Focused3.xcresult`. Static
contract, network, and commercialization-document gates pass. The fresh owning validation produced
410 results: 403 passed, 7 explicit opt-in/runtime skips, and 0 failed. All 396 unit tests and
14/14 UI tests passed, together with the Release build, all static gates, and every selected
coverage threshold. Evidence: `/private/tmp/MindBudget-C303B-CancellationFix-FullFinal2.xcresult`.
Hosted CI for this follow-up head remains pending.

State: C3-03B remains implementation complete pending independent re-review and green hosted CI;
it is not Done. C3-04 remains blocked.

What was NOT changed: No configuration vocabulary, entitlement/StoreKit authority, product/price/
trial, notification, Worker behavior/deployment, Staging/Production deployment, user content,
telemetry, version, Archive/upload, tester assignment, or distribution action changed. The
post-0.9.6 release hold remains active.

## 2026-08-15 — Session 121 — Close C3-03B and C3-03 after PR #38 merged

Goal: Close the reviewed C3-03B implementation and its C3-03 parent after hosted CI and merge,
without starting C3-04 or changing runtime/distribution state.

What changed: Repository tasks, memory, decisions, requirements, network policy, the C3 packet,
public-configuration contract, CI baseline, and documentation gates now record reviewed head
`09c382e`, successful GitHub Actions run `31873664396`, and PR #38 merge commit `db7926d`.
C3-03B and C3-03 are Done. C3-04 is ready but not started pending explicit owner instruction.

Evidence: The post-merge CI-style validation produced 410 results: 403 passed, 7 explicit
opt-in/runtime skips, and 0 failed. All 396 unit tests, 14/14 UI tests, the Release build, static
gates, and selected coverage thresholds passed at
`/private/tmp/MindBudget-C303B-Closeout-FullGreen.xcresult`. The shared-load wall-clock diagnostic
measured 0.83718875 seconds at `/private/tmp/MindBudget-C303B-Closeout-Full.xcresult`; the same
signal passed 10/10 isolated iterations at
`/private/tmp/MindBudget-C303B-Closeout-StrictPerformance.xcresult`.

What was NOT changed: No Swift/runtime behavior, Worker source/deployment, payload, StoreKit or
entitlement authority, product/price/trial, notification, user content, telemetry, Staging or
Production deployment, formal economics, privacy approval, version, Archive/upload, tester
assignment, or distribution action changed. The post-0.9.6 release hold remains active.

## 2026-08-15 — Session 122 — Implement COM-C3-04 UI and release quality

Goal: Implement the scoped C3-04 UI and release-quality candidate without opening Production or
distribution.

What changed: Dashboard and Pro presentation now explain verified exceptional subscription states
through one non-blocking navigation surface and StoreKit-derived guidance. Purchase remains blocked
when authority is unavailable or otherwise not actionable. Restore, Manage, and Recheck remain
reachable, bilingual VoiceOver copy describes plans and actions, and AX5 layout adapts across all
three appearances. Manual screenshot review caught and fixed an appearance-transition contrast
defect. User-facing disclosure, review notes, tasks, decisions, requirements, matrices, release
checklists, and static gates were updated to match the candidate exactly.

Evidence: The focused StoreKit-domain suite passed 24/24 at
`/private/tmp/MindBudget-C304-StoreRuntime.xcresult`. The final three-appearance AX5 run passed 1/1
and was visually inspected at `/private/tmp/MindBudget-C304-ProAX5-ColorFix.xcresult`. The final
owning validation produced 413 results: 406 passed, 7 explicit opt-in/runtime skips, and 0 failed;
all 398 unit tests, 15/15 UI tests, the Release build, static gates, and selected coverage thresholds
passed at `/private/tmp/MindBudget-C304-Full-Final.xcresult`. Hosted CI remains pending.

State: C3-04 implementation is complete pending independent review and green hosted CI. It and
COM-C3 are not Done.

What was NOT changed: No StoreKit or entitlement authority, product IDs, formal price/trial terms,
signed configuration or Worker deployment, Staging/Production deployment, data schema, user content,
telemetry, version, Archive/upload, tester assignment, or distribution action changed. The
post-0.9.6 release hold remains active.

## 2026-08-16 — Session 123 — Resolve COM-C3-04 review feedback

Goal: Address the actionable UI/release-quality review findings and record the rejected
unavailable-as-Free finding accurately, without changing paid authority or distribution state.

What changed: The existing unavailable-authority purchase section was confirmed to show distinct
localized copy, disable purchase, and retain Recheck, so a code comment now explains why the
verified-state guidance does not duplicate that surface. Exceptional-state emphasis now uses the
selected skin's `attentionText` token. The Pro screen retains its local preferred-color-scheme
binding because the root already had the same value when the pushed List nevertheless exhibited a
captured appearance-transition lag. The StoreKit static contract pins the theme-aware tint, and
the commercialization test matrix now explicitly separates automated AX5 reachability evidence
from manual screenshot-based contrast review.

Evidence: The StoreKit-domain suite passed 24/24 at
`/private/tmp/MindBudget-C304-ReviewFix-StoreRuntime.xcresult`; the three-appearance AX5 run passed
1/1 at `/private/tmp/MindBudget-C304-ReviewFix-AX5.xcresult`, followed by manual inspection of all
three retained captures. Full validation produced 413 results: 406 passed, 7 explicit opt-in/
runtime skips, and 0 failed. All 398 unit tests and 15/15 UI tests, the Release build, static gates,
and selected coverage thresholds passed at
`/private/tmp/MindBudget-C304-ReviewFix-Full.xcresult`. Hosted CI for the follow-up head remains
pending.

State: C3-04 remains implementation complete pending independent re-review and green hosted CI;
it and COM-C3 are not Done.

What was NOT changed: No entitlement/StoreKit authority, purchase/restore behavior, product,
formal price/trial, signed configuration, Worker/deployment, Staging/Production status, schema,
user content, telemetry, version, Archive/upload, tester assignment, or distribution action
changed. The post-0.9.6 release hold remains active.

## 2026-08-16 — Session 124 — Close remaining COM-C3-04 presentation review notes

Goal: Resolve the final non-blocking C3-04 review observations without changing paid authority or
distribution state.

What changed: The purchase button and its action now consume one shared availability predicate,
preventing future guard drift. All Pro warning copy uses the selected skin's attention color. The
Pro, subscription-terms, and subscription-privacy screens each retain the selected preferred color
scheme. The AX5 flow now verifies navigation and bounds and captures those three screens under all
three appearances; the StoreKit static contract pins these boundaries.

Evidence: The expanded AX5 test passed 1/1 at
`/private/tmp/MindBudget-C304-P3-AX5-Rerun.xcresult`, and all nine screenshots were manually
inspected for readable contrast, correct appearance, bounds, and clipping. Full validation
produced 413 results: 406 passed, 7 explicit opt-in/runtime skips, and 0 failed. It included 398
unit-test results, 15/15 passing UI tests, the Release build, every static gate, and all selected
coverage thresholds at `/private/tmp/MindBudget-C304-P3-Full2.xcresult`. Hosted CI remains pending.

State: C3-04 remains implementation complete pending independent re-review and green hosted CI;
it and COM-C3 are not Done.

What was NOT changed: No StoreKit/entitlement authority, purchase or restore behavior, product ID,
formal price/trial term, signed configuration, Worker/deployment, Staging/Production state, schema,
user content, telemetry, version, Archive/upload, tester assignment, or distribution action
changed. The post-0.9.6 release hold remains active.

## 2026-08-16 — Session 125 — Correct stale budget-buffer insight and category chart

Goal: Pause new commercialization work to investigate the reported current-cycle buffer mismatch
and replace the category comparison with a more objective proportional chart.

What changed: The investigation confirmed that `BudgetEngine` includes current-cycle expenses;
the incorrect-looking ¥4,088.70 was a persisted `safeToProceed` payload calculated for an earlier
expense candidate, then displayed later as though it were current. The positive check remains
available during expense entry but is no longer persisted, and legacy rows are filtered from
retrospective reads without deleting user data. The category chart is now a localized donut with
the five largest categories plus a checked aggregate of all remaining categories, so the chart
represents the complete rolling 30-day amount. Deterministic aggregation, new/legacy persistence,
and UI reachability regressions were added.

Evidence: Focused Phase 5/11 tests passed 69/69, the follow-up Phase 5 legacy-row suite passed
39/39, and the focused Insights UI flow passed 1/1 with a retained screenshot at
`/private/tmp/MindBudget-InsightsFix-UI.xcresult`. The Phase 6/10 regression rerun passed 16/16,
including the strict local 10,000-expense wall-clock benchmark, at
`/private/tmp/MindBudget-InsightsFix-FailureSuites.xcresult`. Final validation then used the
repository's explicit wall-clock exclusion for the concurrently loaded full suite and produced
416 results: 409 passed, 7 explicit opt-in/runtime skips, and 0 failed. It included 401 unit-test
results, 15/15 passing UI tests, the Release build, every static gate, and all selected coverage
thresholds at `/private/tmp/MindBudget-InsightsFix-FullFinalSkip.xcresult`.

State: Core bug-fix implementation and local validation are complete pending independent review.
The next commercialization packet remains paused; C3-04 source is already merged but its separate
commercial closeout is not advanced by this fix.

What was NOT changed: No budget formula, expense amount, category assignment, schema, StoreKit or
entitlement authority, signed configuration, Worker/deployment, formal price/trial term, version,
Archive/upload, tester assignment, or distribution action changed. The post-0.9.6 release hold
remains active.

## 2026-08-16 — Session 126 — Resolve Insights persistence and chart review findings

Goal: Close the review findings in the Insights legacy-read path and category donut without
changing budget authority, persisted schema, or commercialization scope.

What changed: Retrospective insight reads now inspect persisted `typeRaw` before decoding a row.
A known legacy `safeToProceed` row is hidden before its payload is read, so a corrupted stale
positive check cannot prevent durable insight cards or the Insights page from loading. Unknown raw
types still reach the strict mapper and fail closed. The category donut preserves all six real
category labels, aggregates only from seven categories onward, and replaces Charts' fixed bottom
legend with an app-owned category-and-amount key. It uses a two-column grid at normal text sizes
and a one-column AX5 layout with explicit VoiceOver label/value semantics.

Evidence: Focused `Phase5FeatureTests` and `Phase11FreeTierTests` passed 72/72 on iPhone 17 Pro,
iOS 26.5. The malformed legacy-safe-check regression, six-category boundary, seven-category
remainder, and deterministic normal-versus-accessibility layout-contract tests are included. The
final English and Simplified Chinese localized UI runs passed 2/2 at
`/private/tmp/MindBudget-InsightsReview-LocalizedLegend-Final.xcresult`; each retained a screenshot
and asserted all six key entries exist, are reachable, and remain within the horizontal app bounds.
As supplemental evidence, an exploratory run with the simulator's actual AX5 content-size category
passed 1/1 in English at
`/private/tmp/MindBudget-InsightsReview-TrueAX5-English-Final4.xcresult`. Manual inspection of its
top and bottom exports at
`/private/tmp/MindBudget-InsightsReview-TrueAX5-English-Final4-Attachments/3F914329-58C2-40FA-A554-6B2D5252C282.png`
and `/private/tmp/MindBudget-InsightsReview-TrueAX5-English-Final4-Attachments/D363F962-E93E-4AAA-B038-A68036EF4747.png`
confirmed that the category key uses the intended single-column layout without horizontal label or
amount clipping. The retained bilingual UI tests intentionally run at normal Dynamic Type; the AX5
branch is language-independent and is locked by the focused layout-contract test. A matching true
AX5 Chinese end-to-end run was not claimed because its data-preparation flow was blocked in the
pre-existing Add Expense horizontal category chooser before the Insights chart was reached. The
money, network-egress, commercialization-document, and StoreKit-catalog static gates passed, and
`git diff --check` is clean.

What was NOT changed: No budget formula, expense amount, category assignment, schema, StoreKit or
entitlement authority, signed configuration, Worker/deployment, formal price/trial term, version,
Archive/upload, tester assignment, or distribution action changed. The post-0.9.6 release hold
remains active.

## 2026-08-16 — Session 127 — Close PR #41 visual-review follow-ups

Goal: Confirm the revised Insights category chart under every included skin before merge and
separate the pre-existing AX5 Add Expense category-selector limitation from this focused fix.

What changed: No runtime or retained test code changed. A temporary UI probe created the same
six-category dataset, switched through Aurora Glow, Warm Botanical, and Neon Pulse, and captured
both the donut and the complete app-owned legend under each skin. The probe was removed after the
run. `Docs/TASKS.md` now carries a standalone accessibility follow-up to make every Add Expense
category discoverable and tappable at true AX5 in English and Simplified Chinese and to correct
the UI-test content-size launch value.

Evidence: PR #41 head `7884b36` completed hosted CI successfully. The temporary three-skin probe
passed 1/1 at `/private/tmp/MindBudget-Insights-ThreeSkins-Final2.xcresult`; its six exported
screenshots are under `/private/tmp/MindBudget-Insights-ThreeSkins-Final2-Attachments`. Manual
inspection confirmed that all six donut colors remain distinct, the two-column category names and
amounts are readable without clipping or overlap, and card/background contrast is coherent under
all three skins. This is normal-Dynamic-Type appearance evidence; the already recorded true-AX5
English chart evidence remains separate, and the Chinese true-AX5 flow remains assigned to the
new standalone category-selector task.

What was NOT changed: No budget logic, chart aggregation, persisted data, localization, schema,
StoreKit or entitlement authority, signed configuration, Worker/deployment, formal price/trial
term, version, Archive/upload, tester assignment, merge, or distribution action changed. The
post-0.9.6 release hold remains active.

## 2026-08-16 — Session 128 — Merge PR #41 and prepare TestFlight 0.9.7 (8)

Goal: Merge the approved Insights correction after green CI, close the already merged C3-04/COM-C3
documentation state, and prepare one owner-authorized TestFlight upload without assigning testers.

What changed: PR #41 passed GitHub Actions run `31943778984` and merged to `main` as `afddb5c`.
The release candidate is now version 0.9.7/build 8 with matching bilingual in-app release notes,
changelog, TestFlight What to Test notes, release-readiness checks, and UI/localization assertions.
PR #40's independent review, green run `31918968478`, and merge `9448ca9` close C3-04 and COM-C3.
DEC-COM-024 records the owner's narrow instruction to Archive and transport-upload build 8 only.

Release boundary: Production signed configuration remains undeployed; the Release adapter can use
only its exact Production host and failure keeps the optional value trigger at conservative
`false`. StoreKit and permanent Settings/Restore/Manage controls remain independent. This session
does not assign internal testers, submit external Beta App Review, deploy Production, approve
public economics, start COM-C4A, or submit an App Store version.

Validation result: the 0.9.7 preparation passed every static release/commercialization/network/
StoreKit gate and the generic Release build. The final wall-clock-excluded run produced 420
results: 411 passed, 7 explicit opt-in/runtime skips, and 2 simulator UI failures. Both failed UI
cases then passed independently: Simplified Chinese ledger filters at
`/private/tmp/MindBudget-0.9.7-ReleasePrep-ChineseLedger.xcresult` and the three-skin Pro AX5 flow at
`/private/tmp/MindBudget-0.9.7-ReleasePrep-AX5-Quiet.xcresult`. The strict local 10,000-expense
Dashboard first-load signal also passed alone at
`/private/tmp/MindBudget-0.9.7-ReleasePrep-StrictPerformance3.xcresult`; its earlier loaded-suite
measurements were 2.500 seconds and 0.696 seconds, so they are retained as load evidence rather
than represented as passing. The corrected Simplified Chinese release-note brand assertion passed
in the focused localization run. Hosted CI for the release-preparation commit remains pending.

Upload result: completed on 2026-08-17. The preparation commit `e1f2831` merged through PR #42 as
`9792901` after GitHub Actions run `31984665049` passed. Release 0.9.7 (8) was archived from that
merged commit; the archive reports bundle ID `com.xdgf558.MindBudget`, team `2AM5S7BM2N`,
`UIDeviceFamily = [1]`, and `MinimumOSVersion 17.0`, and carries no `.storekit` fixture. Export used
Apple cloud-managed remote signing with `Apple Distribution: Hao Ye (2AM5S7BM2N)` — no local
distribution private key exists or is required. Transport accepted build 8 at 09:52 (+0800) with
delivery UUID `b7fb59b8-a9c6-4003-a07a-71ea608a2ea6`, and App Store Connect began processing. Build 8
is now immutable.

Recorded limitation: the Release binary still contains all three public-configuration endpoint
literals (Development, Staging, Production) because they are cases of one `endpoint` property.
`PublicConfigurationDeploymentEnvironment.current()` returns `.production` unconditionally outside
`DEBUG`, so no Release code path reaches Development or Staging; the extra strings are inert and are
reported here rather than described as an absent endpoint.

Correction to prior release history: App Store Connect also holds `0.9.6 (8)`, accepted 2026-08-11,
which no document in this repository recorded. `CURRENT_PROJECT_VERSION = 8` first entered the
repository in `e1f2831` on 2026-08-17, so that earlier upload did not come from a committed state;
the likely cause is an Organizer export that left `manageAppVersionAndBuildNumber` enabled and let
Xcode auto-increment the build number without writing it back. It caused no collision because build
uniqueness is scoped to the marketing version, and the 2026-08-17 export explicitly set
`manageAppVersionAndBuildNumber: false` so build 8 matches the merged commit.

Not performed: no internal tester-group assignment, no external Beta App Review submission, no App
Store version submission, no Production configuration deployment, and no COM-C4A start.

## 2026-08-17 — Session 129 — UI information architecture and TestFlight 0.9.8 (9)

Goal: Improve the Settings and Insights screens so later modules have a place to go, then prepare
one owner-authorized TestFlight upload of the result without assigning testers.

What changed: PR #44 (`ca01dec`) grouped the Settings root into named sections instead of one
unlabeled list of eight destinations, promoted app language to its own first-level entry with an
inline picker, and recorded a navigation-depth contract in `Docs/DECISIONS.md`: two levels by
default, a third only for editing one instance drawn from a list and for documents that stand
alone. PR #45 (`18460f2`) replaced the category chart's hardcoded system colours with a per-skin
`MindBudgetTheme.categoricalChart` scale and grouped Insights into This cycle, Long-term goals,
Where money went, and the existing patterns list. The release candidate is now version 0.9.8/build
9 with matching bilingual in-app release notes, changelog, and TestFlight notes.

Two defects were found and fixed during the work rather than shipped. Moving the language picker
inline removed the pop-back that had been refreshing the navigation bar, so the language screen
kept an English title under a Chinese list; a `.id()` rebuild did not fix it, which disproved the
"view did not rebuild" explanation and located the cause in the unchanging `LocalizedStringKey`,
resolved by formatting the title against the selected locale. Independent review then found the
Insights composition heading keyed off the category segments while `spendingCharts` also draws an
unconditional 30-day trend and a conditional emotion chart, so a cycle with no categorised spending
drew charts with no group above them; the heading moved inside `spendingCharts` so the two
conditions cannot drift apart again.

Deliberately not changed: `BudgetSettingsView` stays whole because its fields commit through one
save action, `ReminderSettingsView` stays whole because in-app reminders and system notifications
are two channels of one concern, and `InsightSummaryBuilder` is calculation with no UI role. An
earlier suggestion to split them was withdrawn after reading the code.

Release boundary: this candidate changes presentation only. No StoreKit, entitlement, pricing,
notification, network, calculation, or persistence behaviour changed. Production signed
configuration remains undeployed. This session does not assign internal testers, submit external
Beta App Review, deploy Production, or submit an App Store version.

Open product question, deliberately unresolved: Insights shows the same figure for "last 30 days"
and "current cycle" whenever every record falls inside the current cycle, which is systematic for
a cycle starting on the 1st rather than coincidental. Merging the cards, changing the wording, or
hiding one when equal is the owner's decision.

Upload result: completed on 2026-08-17. The preparation commit `2d25bd7` merged through PR #46 as
`6fa1cb3` after GitHub Actions run `32032989206` passed. Release 0.9.8 (9) was archived from that
merged commit; the archive reports bundle ID `com.xdgf558.MindBudget`, team `2AM5S7BM2N`,
`UIDeviceFamily = [1]`, and `MinimumOSVersion 17.0`, and carries no `.storekit` fixture. Export used
Apple cloud-managed remote signing with `Apple Distribution: Hao Ye (2AM5S7BM2N)` and kept
`manageAppVersionAndBuildNumber: false`, so build 9 corresponds exactly to the merged commit.
Transport accepted build 9 at 21:59 (+0800) with delivery UUID
`dda1eb09-5d8b-43c6-a2fd-ea910fa422ac`, and App Store Connect began processing. Build 9 is now
immutable.

App Store Connect now holds both 0.9.7 (8) and 0.9.8 (9). Only 0.9.8 (9) contains the grouped
Settings and Insights work; 0.9.7 (8) was built from `e1f2831` and predates it.

Not performed: no internal tester-group assignment, no external Beta App Review submission, no App
Store version submission, no Production configuration deployment.

## 2026-08-18 — Session 130 — Review PR #48 theme palette generator

Reviewed PR #48 (`Scripts/theme_palette.py`, its tests, and the `Docs/Brand/README.md`
section) at the owner's request. No code changed. Verified all 15 parser tests pass, the
shipping theme parses to the expected 22 tokens plus the six-entry chart scale per skin
with hand-checked alias/opacity values, and all seven static gates pass. Four edge-case
probes were run against the parser; findings (new skin silently omitted, alpha dropped
across an alias, whole-file mis-parse silent in JSON mode, declaration-order sensitivity)
were reported back in the review along with smaller rendering nits. The PR was judged sound to merge as a
developer tool with the reported items treated as non-blocking follow-ups.

All four findings were then fixed inside the same PR as `6653551` rather than deferred, each
verified by reproducing the reviewer's own probe: skins are parsed from the `AppSkin` enum, an
alias keeps the referenced token's alpha and stacked opacities multiply as SwiftUI does, a parse
matching no token raises so JSON mode fails too, and a second resolution pass removes the
declaration-order constraint instead of only explaining it. The three rendering nits were also
taken: a standards-mode document, checkerboard backing for translucent swatches, and rejection of
translucent inputs to contrast maths, which cannot composite. Tests grew from 15 to 24.

Recorded process note: this review entry reached the pull request only because an over-broad
`git add -A` in the review-fix commit swept it in alongside the intended source changes.

## 2026-08-20 — Session 131 — Calibrate current state and complete the C4A-01 delta audit

Goal: Synchronize current `main`, correct stale post-upload/project state, and enter only
COM-C4A-01 without implementing C4A-02 or a destructive money migration.

What changed: `main` was fast-forwarded to `abd27ce`, then work continued on
`codex/com-c4a-01-delta-audit`. Current memory now records that App Store Connect accepted 0.9.8
(9) as delivery `dda1eb09-5d8b-43c6-a2fd-ea910fa422ac`, while no tester assignment, external Beta
review, App Store submission, or Production configuration deployment followed. The completed
post-upload product section no longer remains incorrectly In Progress.

C4A-01 result: The source/schema audit found that V1–V4 authoritative amounts already use `Int64`
minor units, exact currency validation, and stable identities; a destructive conversion is not
justified. The new execution packet inventories persisted amounts and sign rules and assigns only
the proven delta to C4A-02: a recoverable pre-open store/sidecar backup, explicit durable migration
journal, idempotent restart/restore, post-open integrity validation, content-minimized anomaly
report, and explicit currency ownership for the rebuildable merchant aggregate cache. C4A-03 owns
the V1–V4 recovery plus USD/JPY/KWD/sign/bounds/anomaly matrix. C4A-02 and C4A-03 remain blocked.

Evidence: The money, network, commercialization-document, and StoreKit catalog gates passed. The
final owning validation produced 420 results: 413 passed, 7 explicit runtime/opt-in skips, and 0
failed; 17/17 UI tests, the Release build, and every selected coverage threshold passed at
`/private/tmp/MindBudget-C4A01-Full.xcresult`. The strict Phase 10 performance suite separately
executed and passed 2/2 at `/private/tmp/MindBudget-C4A01-StrictPerformanceSuite-Retry.xcresult`.
Hosted CI and independent review remain pending.

What was NOT changed: No Swift source, model schema, store bytes, amount, currency, entitlement,
StoreKit product, signed configuration, network channel, user content, version, Archive/upload,
tester assignment, review submission, Production deployment, or distribution action changed.

## 2026-08-20 — Session 132 — Make C4A-01 review evidence structurally checkable

Closed the PR #51 review findings without entering C4A-02. The money inventory now closes over the
15 `ModelCounts` tables and explicitly records the five models with no persisted monetary value.
The C4A-02 plan defines a conservative pre-open sidecar/journal trigger: no store means no backup,
a trusted committed target marker is the fast path, and only a missing/untrusted/target-mismatched
marker takes one recoverable snapshot before opening; post-open integrity validation is the only
way to commit the marker. This avoids undocumented SwiftData schema-metadata inference and keeps
the recovery route outside the normal Dashboard startup budget.

The marker fast path is intentionally closed: the marker must use a supported, parseable
app-owned format, be committed, match the exact target, and have no active/nonterminal recovery
journal. Any missing condition stays on the recoverable unknown-or-different path.

The commercialization documentation check now delegates phase-state consistency to a Python parser
with deterministic self-tests for headings, top-level and nested status cardinality,
review/completion contradictions, merge evidence, and C4A blocked-state conflicts. The real gate
requires every recognized phase/subphase in the authoritative map and C2/C3/C4A packets to own
exactly one direct Status; a stable approved top-level phase-ID set also detects whole-phase
deletion without making future nested subphases add another registration.
The historical prose-only C1 subpackets remain the one explicit source-level exception.
C4A-01 remains pending independent review; no
Swift source, schema, store, commercial behavior, build, upload, tester, deployment, or
distribution state changed.

## 2026-08-20 — Session 133 — Generalize the commercialization phase-state gate

Replaced the remaining per-C4A status registrations with source-level structural enforcement.
Every recognized phase/subphase in the authoritative task map and C2/C3/C4A packets now requires
exactly one direct status; C1 remains a documented historical packet-format exception while its
top-level state is still mandatory in the task map. An exact approved top-level phase-ID set,
including G1, detects deletion or unreviewed addition of a whole phase heading without hardcoding
its status sentence. Parser self-tests cover missing/duplicate nested statuses, a deleted C3-style status,
and missing/unapproved headings. Python compilation, the real-source parser run, all four named
static gates, shell syntax, and diff validation passed. No Swift, schema, runtime, data, or release
state changed.

## 2026-08-20 — Session 134 — Refresh the public repository README

Updated the previously skeletal README into a current public project entry point. It now describes
MindBudget's local-first budgeting value, implemented Free-core capabilities, privacy boundaries,
deterministic/SwiftData architecture, pre-1.0 and App Store Connect transport status, complete
repository validation commands, and the durable documentation map. The wording distinguishes
source-level StoreKit and signed-public-configuration support from formal products, pricing,
Production deployment, external testing, or public release, and identifies fixture economics as
test controls only.

No Swift source, schema, user data, entitlement, StoreKit behavior, network allowance, version,
Archive/upload, tester assignment, deployment, or distribution state changed.

## 2026-08-20 — Session 135 — Implement the C4A-02 recovery envelope

After C4A-01 merged as PR #51 (`bcd56a3`) with green CI, C4A-02 adds the bounded Schema V5
merchant-accounting companion plus the pre-open recoverable store envelope. The existing V1–V4
minor-unit fields and UUIDs are not rewritten. An app-owned marker/journal/manifest surrounds
SwiftData opening; the trusted exact-target marker avoids normal-start copying, while an unknown
existing store snapshots its SQLite artifacts before opening. Inventory failure restores a checksum-
verified source snapshot. Pending recovery artifacts are included in Delete All cleanup. C4A-03
remains blocked for the complete recovery and currency matrix; independent review and CI remain
required before C4A-02 is Done.

## 2026-08-20 — Session 136 — Harden C4A-02 recovery and deletion evidence

C4A-02 now snapshots the store plus `-wal`, `-shm`, `-journal`, and `_SUPPORT` artifacts before
an untrusted existing-store open, validates every journal path and manifest checksum before a
restore, and never promotes a merely parseable noncommitted marker to the fast path. The normal
fast path does neither a full copy nor a full inventory scan. A recovered interrupted attempt
restores only a formerly committed source marker, releases a failed `ModelContainer` before file
restore, and preserves a content-minimized closed anomaly report until Delete All.

Schema V5 adds only the merchant currency companion. The full post-open inventory builds all
checks and the merchant repair plan before it writes; it can repair only an existing merchant's
derived total and currency context from validated same-currency expenses. Ordinary historical
recurring/reflection provenance left after deletion remains readable rather than becoming a false
migration failure. Delete All now treats recovery-artifact cleanup as a privacy-critical stage:
failure leaves preferences intact and reports deletion failure.

Evidence: `StoreMigrationRecoveryTests` plus `Phase6FeatureTests` passed on the available iOS 26.4
iPhone 17 Pro simulator after a first iOS 26.5 destination reported an external Busy preflight
failure. `xcodebuild build-for-testing` passed (with the pre-existing weak-variable warning in
`PublicConfigurationTransportTests`). Money, network-egress, commercialization-document, and
StoreKit catalog gates plus `git diff --check` passed. C4A-02 remains pending independent review
and hosted green CI; C4A-03 remains blocked.

## 2026-08-20 — Session 137 — Review and fully validate the C4A-02 implementation

Root review tightened the recovery commit boundary: once the trusted target marker and committed
journal are durable, terminal artifact cleanup is best effort and retried later rather than being
allowed to trigger an unsafe rollback from a partly deleted backup. Support-directory checksums now
use a canonical sorted entry manifest containing relative path, byte count, and SHA-256.

The first full unit run found a real V1 compatibility issue. Legacy expense data may have a
normalized merchant name without a derived Merchant cache row, so the integrity inventory now
validates every cache row that exists but never invents a missing Merchant or UUID. The V1 migration
test locks this behavior. The corrected unit-only run produced 413 total, 406 passed, 7 skipped,
and 0 failed.

The final owning run under Xcode 26.6 (`17F113`) on iOS 26.4.1 (`23E254a`) passed with 429 results:
422 passed, 7 explicit runtime/opt-in skips, and 0 failed. It includes 17/17 UI tests, the Release
build, all static gates, and coverage at
`/private/tmp/MindBudget-C4A02-Validate-Green-Retry-20260820.xcresult`. The strict performance test
also passed ten isolated iterations at
`/private/tmp/MindBudget-C4A02-StrictPerformance-10x-20260820.xcresult`. An earlier concurrent run
hit only the known local 500 ms wall-clock diagnostic at 1.240605666 seconds and is recorded as a
non-pass, not promoted. C4A-02 still awaits independent review, hosted green CI, and merge; C4A-03
and distribution remain blocked.

## 2026-08-20 — Session 139 — Close C4A-02 after PR #53 merge

Reviewed head `9d2171d` passed GitHub Actions run `32375823770`; PR #53 merged the recoverable
migration envelope to `main` as `c905415` on 2026-08-20. C4A-02 is Done. The authoritative task
maps, requirements, decisions, CI evidence, execution packet, and project memories now carry the
same result instead of the pre-merge pending-review state.

No Swift, schema, data, migration, network, version, Archive/upload, tester, review, or distribution
behavior changed in this closeout. The owner-confirmed retry-only/reinstall recovery boundary
remains intact. C4A-03 is blocked pending explicit owner instruction and was not started.

## 2026-08-20 — Session 140 — Start COM-C4A-03 recovery/currency evidence

The owner explicitly started C4A-03 after C4A-02 merged. Work is limited to the approved
recovery/currency test matrix: deterministic V1–V4 clean/interrupted/restart evidence, backup and
journal failure recovery, exact USD/JPY/KWD and `Int64` boundaries, and malformed-store anomalies
that remain nonzero and recoverable. The previously accepted retry-only/reinstall recovery boundary
is retained; no in-app destructive reset, schema expansion, network, StoreKit, iCloud, release, or
distribution action is authorized.

C4A-03 remains In Progress. Final validation, independent review, hosted green CI, and merge
evidence are still required before it can be marked Done.

## 2026-08-20 — Session 141 — Complete COM-C4A-03 implementation evidence

C4A-03 now has deterministic recovery/currency matrix implementation evidence: clean and
interrupted V1–V4-to-V5 opens, a repeated independent reopen, checksum-journal retry after a
forced mid-restore failure, currency-exponent/boundary fixtures, and independent malformed-store
anomalies that preserve original nonzero facts. Budget-plan and category writes now reject values
above the same inclusive minor-unit maximum used by inventory; no invalid store value is converted
to zero. The accepted retry-only/reinstall recovery boundary remains unchanged.

The initial focused compilation had only three test-macro shape errors and is not promoted as
evidence. The final corrected focused result at
`/private/tmp/MindBudget-C4A03-Focused4.xcresult` passed 20 tests in two suites with zero failures,
and the generic Release build succeeded at `/private/tmp/MindBudget-C4A03-Release2-DD`.

The first shared-load validation attempt missed only the existing strict 500 ms Phase 10
Dashboard wall-clock signal and remains diagnostic-only. The strict performance suite then passed
10/10 in isolation at `/private/tmp/MindBudget-C4A03-StrictPerformance-10x.xcresult`. The final
wall-clock-excluded validation produced 441 results: 434 passed, 7 explicit runtime/opt-in skips,
and 0 failed; all 17 UI tests, static gates, the Release build, and selected coverage thresholds
passed at `/private/tmp/MindBudget-C4A03-FullFinal.xcresult`. C4A-03 is implementation complete
pending independent review, hosted green CI, and merge; no later commercial or distribution gate
changed.

## 2026-08-21 — Session 142 — Close COM-C4A after C4A-03 merge

Reviewed C4A-03 head `138c240` passed GitHub Actions run `32406654986`; PR #55 merged the recovery
and currency matrix to `main` as `77292c6`. C4A-03 and COM-C4A are Done. The authoritative task
maps, requirements, CI evidence, execution packet, project memories, and decision pointer now carry
the same result instead of the pre-merge pending-review state.

This closeout changes documentation and its static contract only. It does not change Swift,
schema, stored data, recovery behavior, network, StoreKit, iCloud, versioning, Archive/upload,
tester assignment, review, or distribution. C4B remains blocked pending an accepted CloudKit
architecture and explicit owner instruction.

The closeout itself also passed the wall-clock-excluded full validation on merged source: 441
results, 434 passed, 7 explicit runtime/opt-in skips, and 0 failed; all 17 UI tests, the Release
build, static gates, and selected coverage thresholds passed at
`/private/tmp/MindBudget-C4A03-Closeout-Full.xcresult`. The preceding sandbox-only attempt failed
before project testing because Xcode could not write DerivedData; it is environment diagnostics,
not a product failure or accepted evidence.


## 2026-08-21 — Session 143 — Start COM-C4B-01 architecture design only

The owner authorized only the C4B-01 Free iCloud design packet. DEC-COM-028 is Proposed, not
Accepted: it recommends explicit custom private-zone `CKSyncEngine` envelopes with default-off
Free/local-first behavior and rejects managed SwiftData mirroring. The source audit found V5
`ModelCounts` has 16 tables, not the pre-V5 15-table C4A inventory. Authoritative user facts are
allow-listed; derived Merchant/merchant-context/insight and device-specific reminder state stay local.

C4B-02 must first pin each primary `ModelConfiguration` to `cloudKitDatabase: .none`, because
the URL initializer defaults to `.automatic`; a new structural static gate enforces that whenever
an iCloud entitlement or CloudKit import appears. This session adds no Swift, schema, container,
entitlement, request, deployment, CloudKit Dashboard, release, or distribution behavior. C4B-02 and
C4B-03 remain blocked pending owner acceptance and independent review.

The four static gates, new contract-parser self-test, Python AST/shell syntax checks, and
`git diff --check` passed. No full runtime validation was run because C4B-01 changes no runtime code.

## 2026-08-21 — Session 144 — Close COM-C4B-01 and freeze C4B-02 prerequisites

Reviewed C4B-01 head `093535f` passed GitHub Actions run `32434148439`; PR #57 merged to `main`
as `90a1e66`. The owner accepted the reviewed custom-record/private-zone architecture, so the
detailed DEC-COM-028 is Accepted and C4B-01 is Done.

The prerequisite-only follow-up pins the occurrence-key grammar, revision-1/no-parent genesis,
accepted-parent ancestry, durable no-winner quarantine handoff, exact future container/disclosure
inputs, and repository-wide explicit SwiftData non-mirroring gate. The checker now covers every
production Swift source and alternate `ModelContainer` construction, with clear missing-owner and
managed `.automatic`/private self-tests. No Swift runtime, schema, container, entitlement, request,
Dashboard, deployment, version, Archive/upload, tester, review, or distribution behavior changed.

Money, network-egress, commercialization-document, StoreKit-catalog 13/13, iCloud contract
self-test/repository check, Python syntax, and `git diff --check` passed. C4B-02 runtime and C4B-03
remain blocked until this prerequisite change passes independent review/CI/merge and the owner
explicitly starts implementation.

## 2026-08-21 — Session 145 — Promote C4B-02P into the protected packet state map

PR #58 review confirmed the prerequisite decisions and static gate, then identified that the
active prerequisite checklist item lacked a heading-bound Status. The remediation introduces the
recognized `C4B-02P` packet subphase with its own pending-review Status, so the existing
`--require-all-status` validation covers it. C4B-02 runtime remains a separate Blocked phase.

No runtime Swift, schema, container, entitlement, request, deployment, version, or distribution
behavior changed. The known generic nested-heading deletion/format-drift limitation and fail-safe
lexical comment/string noise remain deferred P3 maintenance rather than expanding this repair.

## 2026-08-21 — Session 146 — Close C4B-02P SwiftData-gate bypasses

Independent review correctly found that the prerequisite gate counted source substrings, allowing
`ModelConfiguration.init`/`ModelContainer.init`, contextual `.init`, type aliases, or comment and
string text to evade or spoof the per-configuration `.none` requirement once a CloudKit import or
iCloud entitlement appears. The checker now uses a small conservative Swift lexer: it excludes
nested comments and normal/raw, single-line/multiline string literal text while retaining real
interpolation expressions. Every real `ModelConfiguration` direct call in `DataController` must
carry a top-level `cloudKitDatabase: .none`; aliases, direct/contextual `.init`, and metatype
`.self` escapes are rejected. `ModelContainer` construction remains centralized without banning
ordinary parameter/reference types such as the existing integrity-inventory input.

The deterministic self-test now proves the exact bypass fixtures, including direct and contextual
initializers, aliases, fake `.none` in comments/normal/raw/multiline strings, nested-code fake
`.none`, interpolation construction, metatype indirection, alternate construction, and missing
owner. C4B-02P is a mandatory active prerequisite, so both task maps now use `[ ]`, not the
optional/parallel `[~]`; its packet Status remains pending independent review and C4B-02 runtime
remains Blocked. No runtime Swift, schema, container, entitlement, request, deployment, Archive,
tester, or distribution behavior changed.

Money, network-egress, commercialization-document, StoreKit-catalog 13/13, iCloud contract
self-test/repository check, Python syntax, and `git diff --check` all passed locally. Hosted CI,
independent review, and merge remain required before C4B-02P can close.

## 2026-08-21 — Session 147 — Close raw-string, cross-file init, and selective-import escapes

The follow-up review correctly reproduced three remaining static-gate gaps. The raw-string scanner
treated an ordinary backslash like a non-raw escape and could swallow the closing quote plus later
Swift code. A bare `.init` could receive `ModelContainer` context from a declaration in another
file, defeating the same-file protected-type heuristic. Selective imports such as
`import class CloudKit.CKSyncEngine` did not match the direct-import trigger.

The lexer now applies Swift raw delimiters exactly: only a backslash followed by the opening number
of hashes starts a raw escape or interpolation. Instead of attempting local type inference, the
checker inventories every real production `.init(...)` repository-wide and permits only the 11
existing reviewed calls by exact path, receiver, top-level argument labels, and maximum count.
Direct and all supported selective CloudKit import kinds activate hardening. Comments and all
literal text remain excluded, while string-interpolation code remains visible.

New fixtures place a default configuration/container after a raw string ending in a literal
backslash, split a `ModelContainer` sink and inferred `.init` across two files, and exercise every
selective-import kind. Targeted self-test, repository scan, and Python syntax passed. No runtime
Swift, schema, container, entitlement, request, deployment, Archive/upload, tester, review, or
distribution behavior changed. C4B-02P stays pending independent review and C4B-02 stays Blocked.
The final money, network-egress, commercialization-document, StoreKit-catalog 13/13, iCloud
self/repository, Python syntax, and `git diff --check` rerun also passed.

## 2026-08-21 — Session 148 — Guard initializer values and SwiftUI-created containers

The next review correctly identified that `.init(...)` call scanning did not cover an initializer
stored as a function value, and that SwiftUI's `modelContainer(for:)` can create a persistent
container without a `ModelContainer(...)` token. Both shapes violated the centralized primary-store
boundary once future iCloud capability hardening activates.

Unapplied `.init` references now have their own exact repository allowance for the currently
reviewed `Date`, `Set`, `String`, and recovery-deleter function values; an unapproved
`ModelConfiguration.init` or `ModelContainer.init` reference fails before it can be called
indirectly. SwiftUI modifier calls are also path/label/count-bound. Only the existing unlabeled
`.modelContainer(environment.dataController.container)` call in `MindBudgetApp.swift` remains
valid; View, Scene, implicit-self, extra, `for:`-creating, and modifier-reference forms fail.

Deterministic fixtures cover both SwiftData initializer values, both SwiftUI surfaces, implicit
self, modifier reference, and the accepted existing-container call. No runtime Swift, schema,
container, entitlement, request, deployment, Archive/upload, tester, review, or distribution
behavior changed. C4B-02P remains pending independent review and C4B-02 remains Blocked.

The final money, network-egress, commercialization-document, StoreKit-catalog 13/13, iCloud
self/repository, Python syntax, and `git diff --check` rerun passed.

## 2026-08-21 — Session 149 — Implement C4B-02 custom-record sync without provisioning iCloud

PR #58 prerequisite evidence was first calibrated: reviewed head `0fece3a` passed GitHub Actions
run `32454490080` and merged as `6f5fded`. The owner then explicitly started C4B-02 and asked that
implementation and documentation closeout ship in the same review branch.

Schema V6 adds five local, non-authoritative sync metadata models. Every primary
`ModelConfiguration` is explicitly `cloudKitDatabase: .none`. The new default-off service and
Settings disclosure create no adapter before consent; after consent, local business facts and
outbox/tombstones share one `ModelContext` transaction. Remote records are inbox-first and only
`DataActor` may validate/topologically apply them. Twelve exact authoritative fact types are
supported; Merchant plus context, SpendingInsight, and ReminderEvent remain local. The adapter is
private-database/custom-zone only, encrypts the complete envelope, keeps logical tombstones, and
maps account, network, quota, service, conflict, physical deletion, malformed data, and encrypted-
key reset to closed local-first status. Account changes require explicit disable/re-consent before
new-account genesis staging; key reset cannot be cleared by generic re-enable.

The final focused sync suite passed 20/20 on Xcode 26.6/iOS 26.4.1 at
`/private/tmp/MindBudget-C4B02-CloudSync-Final.xcresult`. It includes all 12 facts and permanent
local-only exclusion, V5-to-V6 migration, lineage/replay, duplicate delivery, cascade and logical
tombstones, malformed/physical deletion, no-winner conflict, account and key-reset lifecycle, and
default-off transport. It also proves that encrypted-key reset and external remote-zone deletion/
purge remain sticky pauses that generic disable/re-enable cannot turn into a destructive reupload.
One preceding run failed only because a new cascade test compared two
equivalent record-name arrays in different queue order; it now compares sets and still reverses the
remote delivery to prove child-before-parent tombstone application.

No iCloud entitlement, provisioned container, Dashboard schema/deployment, verified CloudKit
request, physical/multi-device evidence, conflict-resolution UI, cloud-wide deletion, Archive,
upload, tester, review, or distribution action was added. C4B-02 remains pending independent review,
hosted CI, and merge; C4B-03 remains blocked.

## 2026-08-21 — Session 150 — Complete C4B-02 validation with an isolated performance signal

The first default `Scripts/validate.sh` run passed the Release build, the functional suites, and all
17 UI tests, but its strict 10,000-row Dashboard wall-clock test was the only failure while competing
with 27 concurrent Swift Testing suites. That run is explicitly a non-pass. A focused Phase 10 run
then passed, and 10 isolated iterations passed 20/20 on iOS 26.4.1 at
`/private/tmp/MindBudget-C4B02-Performance10-iOS264.xcresult`, closing an actual product-regression
theory and identifying invalid concurrent measurement.

`Scripts/validate.sh` now runs the local 500 ms benchmark once with parallel testing disabled and
skips only its duplicate invocation in the main run; hosted CI still skips the machine-sensitive
signal and runs the deterministic 10,000-row projection contract. The corrected full validation
passed: isolated benchmark 1/1, remaining unit tests 444/444, UI 17/17, Release build, static gates,
and coverage thresholds. Result: `/private/tmp/MindBudget-C4B02-Validate.xcresult`. C4B-02 remains
pending independent review/hosted CI/merge; no entitlement, provisioned container, Dashboard
deployment, real CloudKit request, Archive, upload, tester, or distribution action occurred.

## 2026-08-21 — Session 151 — Harden PR #59 trust-boundary pauses and remote apply

Independent review found that destructive `zoneNotFound` CKErrors could remain retryable, delayed
callbacks could overwrite a stored sticky pause, and several remote-apply edge cases did not match
the accepted C4B contract. DEC-COM-031 now owns the detailed remediation. Destructive database and
CKError paths cancel/discard the engine and enter an irreversible-within-C4B-02 pause; ordinary
transport/account callbacks cannot reopen it. Recurrence generation uses the canonical shared key,
invalid allocation arithmetic and divergent accepted claims quarantine without overwriting local
facts, required parent identities distinguish malformed envelopes from delivery-order waits, and
Delete All is accurately disclosed as local-only pending C4B-03 cloud deletion/reimport UX.

The focused sync suite passed 25/25 at `/private/tmp/MindBudget-C4B02-ReviewFix2.xcresult`. Final
`Scripts/validate.sh` passed the isolated benchmark 1/1; 466 combined correctness/UI results with
459 passed, seven opt-in skips, and UI 17/17; Release compilation; all static contracts; and selected
coverage (minimum 87.60%, required 85%) at
`/private/tmp/MindBudget-C4B02-ReviewFix-Validate.xcresult`. No entitlement, provisioned container,
Dashboard deployment, real CloudKit request, physical/multi-device evidence, cloud-wide deletion,
Archive, upload, tester, or distribution action occurred. C4B-02 remains pending final re-review,
hosted CI, and merge; C4B-03 remains blocked.

## 2026-08-21 — Session 152 — Calibrate C4B-02 to its reviewed merge

Reviewed remediation head `0024507` passed GitHub Actions run `32490174014` in 34m30s, and PR #59
merged the exact C4B-02 source to `main` as `211dff2`. The owner accepted the review and authorized
formal C4B-03 entry only after a separate documentation closeout passes review, hosted CI, and
merge. Current memory/task/requirement/contract/CI state now marks C4B-02 Done while keeping C4B-03
blocked by that closeout condition.

The closeout adds no Swift, Schema, iCloud entitlement, provisioned container, Dashboard
environment, CloudKit request, physical multi-device evidence, conflict/deletion UI, Archive,
upload, tester, or distribution action. Money, network-egress, commercialization-document,
StoreKit catalog 13/13, iCloud self-test/repository, shell syntax, and `git diff --check` all passed.
The next authorized step is to merge this closeout, then formally enter C4B-03 without inferring
any operational or release evidence from C4B-02.

## 2026-08-22 — Session 153 — Formally enter C4B-03 and implement lifecycle/deletion controls

Reviewed closeout head `b9944cd` passed GitHub Actions run `32494429474`; PR #60 merged it as
`7138a9c`, satisfying the owner's formal C4B-03 entry condition. DEC-COM-032 now owns the exact
boundary. The source adds separate Development/Production entitlement files for the one accepted
private container, explicit no-content conflict review, keep-local/use-iCloud resolution, durable
whole-zone cloud deletion that preserves local facts, retained-copy reimport confirmation, and an
explicit sticky trust-recovery flow. Generic Enable is hidden during a trust-boundary pause.

The focused sync suite passed 32/32 at `/private/tmp/MindBudget-C4B03-Focused3.xcresult`. A signed
Debug build proves the exact Development entitlement/profile at
`/private/tmp/MindBudget-C4B03-GenericSigned1.xcresult`. A Release archive succeeded at
`/private/tmp/MindBudget-C4B03-Release1.xcarchive`, but automatic signing used an Apple Development
profile; therefore it proves Production CloudKit configuration selection, not distribution push,
Production schema deployment, or release readiness. The physical iPhone disappeared from Xcode
before the direct-device build could execute, so no physical or real-request claim is made.

No primary SwiftData schema, money model, StoreKit, app-owned HTTP(S), public/shared CloudKit,
receipt/OCR, telemetry, Archive upload, tester, review, or distribution action changed. Full local
validation, real Development request/Dashboard, physical multi-device/account/quota/offline,
distribution signing, Production schema owner confirmation/deployment, review, hosted CI, and merge
remain open.

## 2026-08-22 — Session 154 — Complete C4B-03 local validation without claiming remote evidence

The C4B-03 entitlement exposed six legacy test stores that had relied on SwiftData's implicit
`.automatic` CloudKit selection. The first full validation is retained as a non-pass. Every local
test fixture now declares `cloudKitDatabase: .none`, and the iCloud contract gate checks both
production and test configurations. The corrected focused migration/free-tier regression passed
45/45 at `/private/tmp/MindBudget-C4B03-Regression2.xcresult`.

The generated app plist also proved that a build-setting-only background-mode attempt had not
materialized, so it was removed. Both configurations now reference the checked source plist with
exactly `UIBackgroundModes = [remote-notification]`, while separate entitlement files preserve
Development/Production selection. DEC-COM-033 owns the detailed boundary.

Final local validation passed: Release build, every static contract, isolated strict Dashboard
performance, 456/456 unit tests across 27 suites, 17/17 UI tests, and selected coverage (minimum
87.60% against 85%) at `/private/tmp/MindBudget-C4B03-Full1.xcresult`. C4B-03 stays In Progress.
Real CloudKit/Dashboard, physical multi-device/account/quota/offline, distribution signing,
Production schema deployment, independent review, hosted CI, and merge remain unproven.

## 2026-08-22 — Session 155 — Pass the authorized physical Development CloudKit lifecycle probe

The owner connected/unlocked physical `拉沙的iPhone` (`iPhone Air`) on final iOS 26.6.1 (`23G82`)
and explicitly authorized irreversible deletion of the fixed Development zone. A signed Debug
physical build first confirmed the exact Development CloudKit/push/container/team profile at
`/private/tmp/MindBudget-C4B03-Physical1.xcresult`; no existing MindBudget installation was present
before the test app was installed.

The first destructive-test bundle failed compilation because its condition inherited the suite's
main-actor isolation. After the pure condition became `nonisolated`, two exact-function filtered
runs still executed zero Swift Testing functions and were rejected as false greens. Xcode did not
forward the shell environment switch into the device test process, so DEC-COM-034 instead uses an
explicit `MINDBUDGET_PHYSICAL_CLOUDKIT_TESTS` Swift compilation condition; ordinary runs keep the
test disabled.

The accepted suite-level physical run passed 33/33 in 10.078 seconds with zero failures. Its real
case took 9.358 seconds and used the production adapter to create the Development private zone,
send/fetch the encrypted record, disable while retaining cloud-copy knowledge, require confirmed
reimport, delete the entire zone, and preserve the local expense. Evidence:
`/private/tmp/MindBudget-C4B03-PhysicalCloudKit4.xcresult`.

C4B-03 stays In Progress. Dashboard inspection, offline/quota/account/background-push evidence,
multi-device convergence/conflict, distribution signing, Production schema deployment, review,
hosted CI, merge, and release are not claimed.

## 2026-08-22 — Session 156 — Record read-only CloudKit Dashboard evidence

The default simulator configuration was rerun after the accepted physical probe. Its 33 results at
`/private/tmp/MindBudget-C4B03-PostPhysical-Sim.xcresult` contain 32 deterministic passes, one
explicit skip for the compile-time opt-in destructive physical case, and zero failures.

Read-only CloudKit Dashboard inspection then confirmed the exact environment split for team
`2AM5S7BM2N` and `iCloud.com.xdgf558.MindBudget`. Development contains the app record type
`MindBudgetEnvelopeV1` with exactly one unindexed app field, `envelope` (`ENCRYPTED BYTES`), and the
physical probe's fixed custom zone is gone. Production contains only the system `Users` type;
there is no app record type or deployed MindBudget schema, and deployment is disabled. Evidence:
`/private/tmp/MindBudget-C4B03-Dashboard-Development-Envelope.png` and
`/private/tmp/MindBudget-C4B03-Dashboard-Production-NoTypes.png`.

No Dashboard mutation or Production deployment was performed. C4B-03 remains In Progress pending
physical offline/quota/account/background-push, two-device convergence/conflict, distribution
signing, explicit Production deployment authority, independent review, hosted CI, merge, and
release.

## 2026-08-22 — Session 157 — Keep current-source validation evidence honest

A final simulator validation rebuilt Release, passed every static contract, and completed all 457
unit-test results without a failure. Sixteen of 17 UI cases passed; the pseudo-long-text case missed
its budget-setup-to-Dashboard transition and consequently failed four reachability assertions.
Xcode then hung during failure-diagnostics/coverage finalization, leaving
`/private/tmp/MindBudget-C4B03-FinalWithoutWallClock.xcresult` incomplete and ineligible as green
evidence. The identical test passed 1/1 in isolation in 23.625 seconds at
`/private/tmp/MindBudget-C4B03-PseudoLong-Isolated.xcresult`.

Two isolated strict Dashboard attempts under the current host load measured 0.870945 and 0.752715
seconds and are retained as performance non-passes; the latter bundle is
`/private/tmp/MindBudget-C4B03-PerformanceFinal.xcresult`. The accepted earlier
`/private/tmp/MindBudget-C4B03-Full1.xcresult` still owns the full green source evidence because the
intervening changes were limited to the compile-time opt-in physical test and documentation, not
production Dashboard/UI code. No release, Production CloudKit, or remaining physical/multi-device
gate is inferred; C4B-03 remains In Progress.

## 2026-08-22 — Session 158 — Reject saturated CloudKit lineage safely

Final C4B-03 review found that three child-envelope paths used unchecked signed revision
arithmetic. The new DEC-COM-035 helper advances zero to genesis one and permits the final
`Int64.max` revision, but throws `invalidLineage` for negative ancestry or any attempt to advance
past that ceiling. Staging, remote acceptance, and explicit keep-local conflict resolution now use
the same boundary, so malformed private ancestry cannot crash, wrap, or manufacture a winner.

The current source rebuilt and passed 34 focused CloudSync results at
`/private/tmp/MindBudget-C4B03-LineageBound.xcresult`: 33 deterministic cases passed and the
compile-time destructive physical test was explicitly skipped. All static contracts and diff
checks pass. This supersedes Session 157's statement that only test/docs had changed after the prior
full run; exact-head full UI/coverage and hosted CI are still required, and C4B-03 remains In
Progress with its external physical/multi-device/Production gates open.

## 2026-08-22 — Session 159 — Stop the different-account two-device evidence attempt

Both physical iPhones were paired, registered for the development team, in Developer Mode, and
able to build the opt-in convergence harness. After local-network permission was enabled on the
second phone, irreversible non-content fingerprints proved the devices use different iCloud Apple
Accounts. They therefore do not share the private CloudKit database required by this test. The
owner declined switching accounts and explicitly stopped the attempt.

DEC-COM-036 records the result as an evidence gap, not a convergence pass, product failure, or
release waiver. A repeated single-device cleanup suite passed 33/33 at
`/private/tmp/MindBudget-C4B03-PostMultiCleanup2.xcresult` and confirms only that the fixed
Development zone is empty. The default simulator configuration then passed 36 results with 33
deterministic passes, three physical-only skips, and zero failures at
`/private/tmp/MindBudget-C4B03-PostMultiDefault.xcresult`. The compile-time harness remains
available for a future same-account run without entering ordinary CI, while C4B-03 remains In
Progress.

The exact-head full validation subsequently passed Release compilation, all static gates, 460
unit-test results across 27 suites, 17/17 UI tests, and all selected coverage thresholds at
`/private/tmp/MindBudget-C4B03-ExactHeadFull2.xcresult`. The run explicitly skipped the wall-clock
benchmark after the previously documented loaded-host non-passes, so it does not manufacture a new
strict performance claim. C4B-03 remains In Progress for external evidence, review, hosted CI, and
merge.

## 2026-08-22 — Session 160 — Preserve retained-cloud authority after local Delete All

PR #61 review found a same-session authority mismatch: local Delete All correctly retained the
durable `cloudCopyMayExist` marker, but `AppSession` then published literal `.disabled` and hid the
reimport disclosure and cloud-delete action. DEC-COM-037 removes that synthetic snapshot. The
service now republishes disabled local control combined with the retained-copy marker immediately
after local deletion; unconfirmed Enable remains closed without constructing a CloudKit adapter,
while confirmed reimport can enable transport. Settings also provides closed, localized retry
guidance for durable cloud deletion and keeps content-free conflicts quarantined without offering
an unsafe keep/use choice.

The focused CloudSync + Phase 6 run passed 52 results with zero failures and three explicit
physical-only skips at
`/private/tmp/MindBudget-C4B03-ReviewRemediation-Focused1.xcresult`. A first full-validation attempt
inside the filesystem sandbox passed the static checks but could not connect to CoreSimulator or
write DerivedData and is retained as an environment non-pass, not product evidence. The accepted
outside-sandbox run passed every static contract, Release compilation, all 461 unit-test results
across 27 suites, 17/17 UI tests, and every selected coverage threshold at
`/private/tmp/MindBudget-C4B03-ReviewRemediation-Full2.xcresult`; minimum selected coverage was
87.60% against the required 85%. The three physical CloudKit tests remained explicit skips, and
the wall-clock benchmark remained intentionally skipped under the already recorded loaded-host
policy. C4B-03 stays In Progress for hosted CI, re-review, merge, and the external evidence gates
that the owner did not waive.

## 2026-08-22 — Session 161 — Calibrate the reviewed C4B-03 product merge without closing evidence

Reviewed C4B-03 product head `f49de948b88c9fc42aff996b6e90fd835742ca41` passed GitHub Actions
run `32571676058`; its only `Build and test` check completed successfully after 19m36s. PR #61 then
merged that exact head to `main` as `0f749ce18b877969248fb3e4e7c0b28df21139af`. The product's
conflict/deletion/reimport/recovery capability is therefore in `main`, and its independent-review,
hosted-CI, and merge gates are closed.

The owner requested that same-iCloud-account two-device convergence/conflict verification be
skipped for now because that account arrangement is unavailable. DEC-COM-038 records a temporary
evidence deferral, not a pass, product failure, permanent waiver, release authorization, or phase
exit. The earlier different-account attempt remains a non-pass and the opt-in harness remains
available. C4B-03 and COM-C4B stay In Progress; C4C and distribution stay blocked. Physical
account/offline/quota/background-push, distribution signing, and explicitly authorized Production
deployment/release evidence remain open.

This session changes documentation and its static contract only. It changes no Swift, Schema,
entitlement, container, CloudKit record, Dashboard environment, Production deployment, Archive,
upload, tester assignment, or release state. The owning validation is recorded after the final
document gate run below.

Money, network-egress, commercialization-document, StoreKit catalog 13/13, iCloud contract
self-test/repository, Python syntax, shell syntax, and `git diff --check` all pass. The first
commercialization-document run correctly rejected the old exact `C4B-03 is In Progress` anchor
after the calibrated prose moved to `remains In Progress`; the gate was updated to the current
contract and then passed. An initial Python compile-only check could not write Apple's default
cache outside the workspace; the identical check passed with a task-specific `/private/tmp`
bytecode cache. Neither environment result is product evidence, and no runtime suite was rerun for
this documentation-only change; hosted CI remains the PR merge gate.

PR #62 independent review found no P1/P2 issue and recommended approval after hosted CI. The
optional current-status cleanup was applied to `ICLOUD_SYNC_CONTRACT.md`: its opening now records
PR #61 (`0f749ce`) and describes the already merged entitlement/operational surfaces in present
tense. Older decision and CI sections remain chronological evidence and were not back-edited.

## 2026-08-22 — Session 162 — Make the same-account physical evidence waiver permanent

The owner permanently waived the physical same-iCloud-account two-device convergence/conflict
evidence requirement. DEC-COM-039 supersedes DEC-COM-038's temporary scheduling boundary without
rewriting it: the unexecuted run is not a pass, the different-account attempt remains a non-pass,
and deterministic conflict/no-automatic-winner behavior remains part of the product contract. The
opt-in physical harness stays available but is no longer an exit gate.

Reviewed documentation head `0350415` passed GitHub Actions run `32573992659`, and PR #62 merged it
as `0128682` before this new owner decision. C4B-03/COM-C4B remain In Progress for account/offline/
quota/background-push, distribution signing, and authorized Production/release evidence. C4C and
distribution remain blocked. This is documentation/static-contract work only and performs no
runtime, CloudKit, Production, signing, upload, tester, or release action.

Money, network-egress, commercialization-document, StoreKit catalog 13/13, iCloud contract
self-test/repository, Python syntax, shell syntax, and `git diff --check` all pass. No runtime suite
is rerun for this documentation-only calibration; hosted CI remains the PR merge gate.

PR #63 independent review found no P1/P2 issue and recommended approval after hosted CI. The
optional task-history polish was applied: the completed PR #62 item now explicitly says its
temporary deferral was the then-current state and is superseded by DEC-COM-039. Historical decision
and CI evidence remains chronological and was not rewritten.

## 2026-08-22 — Session 163 — Begin unwaived C4B-03 evidence and repair automatic scheduling

The owner started the remaining C4B-03 work after permanently waiving only same-account physical
two-device evidence. Main was already synchronized at PR #63 merge
`1a14df96d40d3248190d55861f88327407ea8f77`. GitHub confirms reviewed head `7b23490` passed Actions
run `32576885537` before that merge. C4B-03 remains In Progress; the work is combined with this
post-merge calibration rather than creating another documentation-only packet first.

The evidence inventory found a real background-delivery blocker: the production adapter set
`CKSyncEngine.Configuration.automaticallySync` to `false`. The existing checked
`remote-notification` plist, environment-specific push entitlement, and stable subscription ID
therefore could not make background push trigger automatic fetch/send. DEC-COM-040 changes the
opted-in production engine to automatic scheduling while retaining explicit foreground Retry and
every consent/local-authority/quarantine/sticky-pause boundary. The iCloud static contract now pins
the assignment to the production-true policy.

The focused CloudSync suite passed 38 selected results at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused1.xcresult`: 35 deterministic passes, three
physical-only skips, and zero failures. The iCloud contract self-test/repository scan, Python
syntax, and `git diff --check` also pass. This is regression/configuration evidence, not a physical
silent-push observation.

Read-only inventory found one usable paired physical Development iPhone and Apple Development
identities, but no Apple Distribution identity. Distribution signing therefore remains open. No
Production schema/deployment/release action was attempted. No supported non-destructive way to
force a real private-database quota-exceeded state was found, so filling a person's iCloud storage
is explicitly rejected as fabricated/destructive evidence; quota remains an owner evidence-boundary
decision or requires a legitimately quota-limited test account.

The exact-head full validation subsequently passed at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Full1.xcresult`: every static contract, Release, 462
unit-test results across 27 suites, 17/17 UI tests, and all selected coverage thresholds.
`xcresulttool` reports 479 combined results with zero failures, 469 passes, and ten explicit skips;
minimum selected coverage remains CSVExporter at 87.60% against the required 85%. The wall-clock
benchmark stayed explicitly skipped under the accepted loaded-host boundary, so no new strict
performance claim is made. A Development physical rerun was prepared but could not start because
Xcode reported the paired iPhone unavailable while browsing the local network and requested an
unlocked attached device. This is an environment non-pass, not CloudKit, push, account, offline,
or quota evidence.

Next suggested task: install the corrected Development build and execute only safe account/offline/
background-push probes with user-assisted device state changes. Keep physical quota, distribution
signing, and Production/release gates open unless their separate prerequisites become available.

## 2026-08-23 — Session 164 — Re-run corrected Development lifecycle on device

The owner reattached and unlocked `拉沙的iPhone`; Xcode then reported it available over USB. The
exact opt-in Development command passed all 38 selected `CloudSyncTests` at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Physical2.xcresult`: 36 passes, the two permanently
waived multi-device roles explicitly skipped, and zero failures on iPhone Air / iOS 26.6.1. The
real private-database case created the fixed Development zone, sent and fetched the encrypted
envelope, disabled sync, required confirmed reimport, deleted the whole test zone, and preserved
the local expense. Production remained untouched.

The runtime registered `CKSyncEngine` background tasks after automatic scheduling was enabled.
Disable/re-enable in the same process also produced Apple's duplicate-registration diagnostic;
Apple's sample permits engine reinitialization, and the explicit lifecycle completed. No
independent remote mutation arrived while the app was backgrounded, so this is not labeled a
silent-push pass. Physical account transition/offline/quota, distribution signing, and authorized
Production/release evidence remain open.

## 2026-08-24 — Session 165 — Permanently waive physical background-push evidence without a pass

The owner permanently waived only the C4B-03 physical background/silent-push observation and
explicitly required that it not be recorded as passed. DEC-COM-042 records the narrow evidence-
scope override. Nine inspected local result packages, `MindBudget-C4B03-BackgroundPush6.xcresult`
through `MindBudget-C4B03-BackgroundPush14.xcresult`, contain zero qualifying background-delivery
passes. They remain non-pass evidence; the compile-time probe remains an optional diagnostic.

The probe sequence nevertheless exposed runtime trust-boundary defects. DEC-COM-041 moves delegate-
triggered cancellation out of the serialized `CKSyncEngineDelegate` callback task, clears only the
matching engine, and permits custom-zone creation only for a newly consented transport without
accepted serialization. The exact focused simulator suite after the final correction passed 37
tests with four physical-only skips and zero failures at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused6.xcresult`.

The final physical probe reached READY but was canceled after the CloudKit Console was found to be
acting as the wrong account; no external deletion or silent-push delivery was observed. Production
was untouched. Because ordinary cleanup did not finish, the fixed Development test zone/record is
conservatively treated as potentially remaining, not claimed clean. Automatic scheduling, checked
capabilities, deterministic coverage, local authority, quarantine, and sticky recovery remain
mandatory. Physical account/offline/quota, distribution signing, and authorized Production/release
evidence remain open; C4B-03/COM-C4B remain In Progress and C4C remains blocked.

Next suggested task: validate and independently review this exact correction/evidence-waiver head.

Exact-head validation then found and corrected an XCTest-only query instability: SwiftUI can expose
the quick-add action as either a `Button` or `DisclosureTriangle`, and can attach the same stable
identifier to nested nodes. The UI harness now searches across element types and selects the first
matching identifier. The English/Chinese category legend, Insights, and manual expense/income flows
passed 4/4 at `/private/tmp/MindBudget-C4B03-Waiver-UIRerun5.xcresult`.

After a simulator cold boot, the full validation entry passed at
`/private/tmp/MindBudget-C4B03-Waiver-Full4.xcresult`: all static contracts, Release compilation,
465 unit-test results, 17/17 UI tests, and every selected coverage threshold passed. The result
summary contains 482 logical results, zero failures, 471 passes, and eleven explicit skips; minimum
selected coverage is CSVExporter at 87.60%. Earlier transient and simulator-polluted full-run
attempts remain non-green diagnostics and were not promoted to evidence. The strict wall-clock
benchmark was explicitly skipped, so no new performance claim is made.

DEC-COM-042 remains unchanged: physical background/silent-push observation has zero passes and is
permanently waived, not passed. C4B-03/COM-C4B remain In Progress; account/offline/quota,
distribution signing, and authorized Production deployment/release evidence remain open, and C4C
remains blocked.

## 2026-08-24 — Close C4B-03 and move release proof to its owning phases

GitHub confirms reviewed final head `f1f37db` passed Actions run `32726507493`, and PR #64 merged
it as `4f6d7fe`. The owner accepted DEC-COM-043 after confirming that the remaining iCloud physical
observations do not control StoreKit entitlement or local Pro access. Physical account switch,
offline, and quota are permanently waived as non-passes; deterministic local-first/fail-closed
coverage remains mandatory. Distribution signing and Production schema/deployment/release proof
move to COM-C6/COM-C12 and remain required there. No Production or distribution action occurred.

C4B-03 and COM-C4B are Done. C4C is unblocked, with C4C-01 as the next implementation packet.
This session changes durable phase/evidence ownership only and introduces no runtime or user-visible
behavior, so no changelog entry is required.

The closeout branch then passed the complete local validation entry: every static contract, Release
compilation, 465 unit-test results across 27 suites, 17/17 UI tests, and all selected core-service
coverage thresholds. The lowest selected coverage was CSVExporter at 87.60% against the required
85%. Four physical-only CloudSync probes remained explicit skips; this run does not convert any
owner-waived physical observation into a pass. The first sandboxed validation attempt could not
access CoreSimulator/DerivedData and is retained only as an environment non-pass; the unrestricted
rerun above is the accepted local closeout evidence.

## 2026-08-25 — Enter C4C-01 without taking away the Free insight baseline

The owner entered C4C-01 after COM-C4B closeout. The audit confirmed that the Commerce vocabulary
already contains the future local-Pro seams, while DEC-COM-014 explicitly keeps the current
30-day Insights and basic deterministic reminder/review experience Free.

The implementation candidate extends the immutable Commerce snapshot for advanced local insight
evidence, future purchase-preflight/post-purchase variants, and receipt scan/import without gating
the current Free detector or reminders. Every newly generated rule carries supporting/total sample
counts and an exact basis-point support ratio. The evidence reuses reserved typed payload keys, is
separated on read, remains optional for legacy rows, and fails closed when partial or inconsistent.
Only Pro sees the new evidence line.

A pure receipt baseline defines unavailable, deterministic, and on-device-model-enhanced-with-
deterministic-fallback tiers while `enableReceiptImport` stays false. The money gate now reserves
only two exact future Vision geometry/observation paths and rejects money vocabulary inside them.
No camera, photo picker, OCR, image, receipt persistence, schema, model prompt, iCloud field,
network channel, or release action was added. Focused entitlement/rule tests passed 58/58 before
the Free-boundary correction; final focused and complete validation are recorded separately.

The final focused matrix passed 92/92 after removing all temporary Pro injection from pre-existing
reminder tests. One preceding diagnostic run failed only because the new Free regression expected
the already-interrupting rule to also remain as an inline card; the accepted assertion instead
checks the durable reminder and Insights row, matching the existing product contract.

The complete validation entry then passed at `/private/tmp/MindBudget-C4C01-Full.xcresult`: all
static contracts, Release compilation, the strict wall-clock stage, 468 unit results across 27
suites, 17/17 UI tests, and every selected coverage threshold passed. `xcresulttool` reports 485
logical results, zero failures, 474 passes, and eleven explicit skips. Four physical-only CloudKit
probes remain intentional skips; no physical, Production, Archive/upload, tester, or release claim
is created. CSVExporter was the lowest selected coverage result at 87.60% against the required 85%.

## 2026-08-25 — Close C4C-01 after independent review and green CI

Independent review found no P1/P2 issue on exact head `d203308`. GitHub Actions run `32845307426`
completed successfully on that head, and PR #66 merged it to `main` as `8611022`. C4C-01 is Done;
C4C-02 remains blocked pending an explicit owner instruction.

The optional review note about `RuleEvidence.measured(...) ?? .exact` is retained in the C4C
execution packet: a future invariant violation must be surfaced rather than disguised as 1/1
evidence. No behavior is changed in this closeout. There is no new image/OCR/persistence/network,
Production, Archive/upload, tester, or release action, so no changelog entry is required.

The documentation-only closeout branch then passed `Scripts/validate.sh`: every static contract,
Release compilation, the strict Dashboard wall-clock stage, 468 unit-test results across 27
suites, 17/17 UI tests, and every selected core-service coverage threshold passed. CSVExporter was
the minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit probes
remained explicit skips, so this run creates no new physical or release evidence.

## 2026-08-25 — Enter C4C-02 with a bounded receipt image lifecycle

After C4C-01 documentation merged through PR #67 as `bdb94d9`, the owner explicitly entered
C4C-02. DEC-COM-045 adds only the acquisition and image-lifecycle substrate: a pure product/Pro/
permission/hardware capability resolver, one-image PHPicker and DataScanner camera adapters,
bounded ImageIO orientation/downsampling, geometry-only Vision/Core Image perspective correction,
one protected and backup-excluded prepared JPEG, and deterministic startup/cancel/background/
memory/Delete-All/session cleanup.

`FeatureFlags.enableReceiptImport` remains false, so there is no customer entry and the new camera
purpose string cannot be prompted by this build. No broad Photos permission, OCR result, structured
field, receipt persistence, schema, iCloud field, model prompt, network channel, Production action,
Archive/upload, tester, review, or release action was added. C4C-03 through C4C-05 remain blocked.

The final focused result `/private/tmp/MindBudget-C4C02-Focused5.xcresult` passed 10/10 on iPhone
17 Pro, iOS 26.5. It directly covers source-byte and source-pixel limits, corrupt input, EXIF
orientation/downsampling, geometry rejection, lifecycle and caller cancellation at an injected
suspension point, startup crash-orphan removal, and repeated prepared-only temporary teardown.

The complete local `Scripts/validate.sh` entry then passed: every static contract, Release
compilation, strict Dashboard wall-clock stage, 478 unit-test results across 28 suites, 17/17 UI
tests, and every selected core-service coverage threshold. Four physical-only CloudKit probes
remained explicit skips, and CSVExporter was the minimum selected coverage at 87.60% against the
required 85%. The validation bundle was ephemeral and removed by the script after success. This
candidate changes no enabled user-visible behavior, so `CHANGELOG.md` is intentionally unchanged.

## 2026-08-26 — Close C4C-02 after reviewed merge without entering OCR

Independent review found no P1/P2 issue on exact head `43c3a35`. GitHub Actions run `32860643712`
completed successfully on that head, and PR #68 merged the bounded image acquisition/lifecycle
substrate to `main` as `4ca8f1c`. C4C-02 is Done. `enableReceiptImport` remains false, and C4C-03
through C4C-05 remain blocked pending a separate explicit owner instruction.

DEC-COM-046 retains the three non-blocking review observations at their correct later boundaries:
a dedicated DataScanner temporary-availability error belongs with an actual UI consumer;
DataScanner/PHPicker physical behavior plus the 20-image stability matrix remain C4C-05 evidence;
and non-money image-quality floating-point literals do not widen the money exception. No runtime,
permission prompt, OCR, persistence, model/network content, Production, distribution, or release
change is made by this documentation closeout, so `CHANGELOG.md` remains unchanged.

The documentation-only closeout branch passed `Scripts/validate.sh`: every static contract,
Release compilation, the strict Dashboard wall-clock stage, 478 unit-test results across 28
suites, 17/17 UI tests, and every selected core-service coverage threshold passed. CSVExporter was
the minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit probes
remained explicit skips. The ephemeral result bundle
`mindbudget-validation.iJejGl/MindBudget.xcresult` was removed by normal script cleanup.

## 2026-08-26 — Enter C4C-03 with local OCR privacy before any model boundary

C4C-02 documentation head `4ab0daf` passed GitHub Actions run `32911659905`, and PR #69 merged
that closeout to `main` as `3e1c5c9`. The owner then explicitly entered C4C-03. DEC-COM-047 keeps
the receipt product flag off and adds only a local OCR/privacy substrate: accurate Vision text
recognition in one adapter, deterministic normalized reading order, retained non-money confidence,
and a mandatory sensitive-text filter whose safe wrapper cannot be constructed outside its file.

The filter replaces card-number, English/Chinese labelled or masked last-four, and labelled
authorization-code spans with `[redacted]`. It accepts no more than 256 observations, 512 UTF-8
bytes per line, and 16 KiB per filtered document. Invalid normalized geometry, invalid confidence,
filter failure, or overflow rejects the document. Raw recognition text, even when filtered, has no
current model, persistence, CloudKit, log, telemetry, or network consumer.

The first focused attempt, `/private/tmp/MindBudget-C4C03-Focused1.xcresult`, failed during test
compilation because a throwing filter call was embedded directly in `#require`; it executed no
test and is not pass evidence. After separating the throwing call from the optional assertion,
`/private/tmp/MindBudget-C4C03-Focused4.A42MrA/MindBudget.xcresult` passed 7/7. The cases cover English/Chinese and
full-width sensitive forms, ordinary text, control normalization, deterministic sorting/ties,
metadata retention, and fail-closed policy/count/byte/geometry/confidence limits. Receipt field accuracy,
physical OCR, 60+ fixtures, 20-image stability, confirmation/persistence, C4C-04/C4C-05,
Production, distribution, and release remain out of scope. With the customer feature still
disabled, `CHANGELOG.md` is unchanged.

The complete validation subsequently passed all static contracts, Release compilation, the strict
Dashboard wall-clock stage, 485 unit-test results across 29 suites, all 17 UI tests, and every
selected core-service coverage threshold. CSVExporter was the minimum selected result at 87.60%
against the required 85%. Four physical-only CloudKit probes remained explicit skips; normal script
cleanup removed the ephemeral `mindbudget-validation.dcltId/MindBudget.xcresult` bundle. An earlier
sandboxed invocation passed static checks but could not access CoreSimulator/DerivedData and ended
before an Xcode test result existed, so it is excluded as environment non-pass evidence.

PR #70 independent review found no P1/P2 issue and requested one optional pre-merge ordering
regression. The fix documents the complete-card-before-last-four rule invariant and adds a labelled,
separated sixteen-digit case that would expose the twelve-digit remainder if future code reordered
those rules. The exact review-fix source passed 7/7 focused tests at
`/private/tmp/MindBudget-C4C03-ReviewFix-Focused5.hKVLun/MindBudget.xcresult`. This changes no
production matching shape or enabled behavior; hosted CI on the new head remains the merge gate.

## 2026-08-26 — Close C4C-03 after reviewed merge without entering extraction

Exact source head `92ed3a7` passed independent review without a P1/P2 issue. The accepted P3
hardening documents the complete-card-before-last-four rule order and adds a labelled separated
sixteen-digit regression fixture. GitHub Actions run `32921913143` completed successfully on that
exact head, and PR #70 merged the bounded local OCR/privacy substrate to `main` as `d294cfb`.

DEC-COM-048 marks only C4C-03 Done. `enableReceiptImport` remains false, and C4C-04/C4C-05 remain
blocked pending separate explicit owner entry and predecessor completion. Continuous 20-plus-digit
values stay outside the accepted PAN shape; spaced-mask variants remain C4C-05 fixture work; regex
caching is optional; and a future C4C-04 caller must run Vision away from the main actor. This
documentation closeout changes no enabled customer behavior, so `CHANGELOG.md` is unchanged.

The documentation-only closeout branch then passed `Scripts/validate.sh`: every static contract,
Release compilation, the strict Dashboard wall-clock stage, 485 unit-test results across 29
suites, all 17 UI tests, and every selected core-service coverage threshold passed. CSVExporter
was the minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit
probes remained explicit skips. The ephemeral result bundle
`mindbudget-validation.IyfM8i/MindBudget.xcresult` was removed by normal script cleanup.

PR #71 review found no P1/P2 issue and requested two current-state clarity fixes before merge. The
commercial project memory now points forward to C4C-04 while explicitly waiting for separate owner
entry, and the execution packet's exit conditions describe the accepted C4C-03 local OCR/privacy
boundary instead of stopping at the older C4C-02 wording. This changes no phase status or runtime
scope: C4C-04 remains blocked and `enableReceiptImport` remains false.

All four required static gates and `git diff --check` passed after this wording-only review fix.
Hosted CI on the new exact PR head remains the merge gate; the earlier complete local validation
continues to be the runtime evidence because this follow-up changes documentation only.

## 2026-08-26 — Enter C4C-04 structured extraction and validation

After PR #71 merged the C4C-03 documentation closeout as `08fb718`, the owner explicitly entered
C4C-04. The candidate adds an ephemeral deterministic structured extractor for merchant, calendar
date, and exact minor-unit total; typed missing/ambiguous/invalid/currency/scale/range states; exact
duplicate matching; and a production-default-off line-item experiment. An optional Foundation
Models adapter runs on device and receives only the already privacy-filtered `ReceiptOCRDocument`.
It may select exact evidence snippets, but deterministic code re-verifies provenance, cannot let it
override an accepted deterministic field, and performs every field interpretation. Model absence,
timeout, invalid evidence/output, or error returns the deterministic result.

The pre-review focused C4C-04 suite passed 16/16 at
`/private/tmp/MindBudget-C4C04-FocusedFinal.xcresult` on iPhone 17 Pro, iOS 26.5, including
USD/JPY/KWD exponent
and locale punctuation, invalid scale/currency/range/date, missing/ambiguous values, exact duplicate
identity, model precedence/provenance/fallback/timeout, and default-off line items. All four static
gates and `git diff --check` passed before the full validation entry. `enableReceiptImport` remains
false; no UI, confirmation, persistence, iCloud field, logging, network, Production, or release
action was added. C4C-05 remains blocked, and `CHANGELOG.md` is unchanged because no customer-
visible behavior is enabled.

The exact C4C-04 candidate then passed `Scripts/validate.sh`: every static contract, Release
compilation, the strict Dashboard wall-clock stage, 501 unit-test results across 30 suites, all
17 UI tests, and every selected core-service coverage threshold passed. CSVExporter was the
minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit probes
remained explicit skips. The ephemeral result bundle
`mindbudget-validation.hAXTHp/MindBudget.xcresult` was removed by normal script cleanup. This is
simulator and deterministic extraction evidence only; it does not advance any C4C-05 physical,
accuracy, persistence, Production, distribution, or release gate.

PR #72 independent review found no P1 issue and identified two P2 fail-closed inconsistencies. The
review fix now rejects a total evidence line if any numeric token on that line fails parsing; a
valid token can no longer hide an invalid-scale sibling. Candidate merging now allows the optional
model to supplement only `.missing`; deterministic `.accepted` and `.rejected` resolutions remain
authoritative. The focused review-fix suite passed 17/17 at
`/private/tmp/MindBudget-C4C04-ReviewFix-Focused.xcresult`, including same-line mixed-validity and
deterministic-rejection regression cases. C4C-05 matching heuristics remain deferred, the product
flag stays false, and hosted CI on the replacement head remains the merge gate.

The replacement exact source then passed the complete `Scripts/validate.sh` entry: every static
contract, Release compilation, the strict Dashboard wall-clock stage, 502 unit-test results across
30 suites, all 17 UI tests, and every selected core-service coverage threshold passed. CSVExporter
was the minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit
probes remained explicit skips. The ephemeral result bundle
`mindbudget-validation.5DL4A2/MindBudget.xcresult` was removed by normal script cleanup. Hosted CI
on the pushed replacement head remains the merge gate; this evidence does not enter C4C-05 or
claim physical receipt, accuracy, persistence, Production, distribution, or release readiness.

## 2026-08-26 — Close C4C-04 after reviewed remediation merge without entering C4C-05

Initial PR #72 review found no P1 issue and two P2 fail-closed inconsistencies. Exact remediation
head `f2d249d` rejects a same-line amount when any numeric token fails parsing and restricts the
optional on-device model to supplementing deterministic `.missing`; deterministic `.accepted` and
`.rejected` remain final. The focused suite passed 17/17, and the complete local validation passed
502 unit-test results across 30 suites, 17/17 UI tests, Release compilation, the strict Dashboard
wall-clock stage, every static contract, and every selected coverage threshold.

Independent rereview approved exact head `f2d249d`. GitHub Actions run `32946104780` completed
successfully on that head in 19m39s, and PR #72 merged it to `main` as `e6316fa`. DEC-COM-050 marks
only C4C-04 Done. Receipt import remains disabled, all structured candidates remain ephemeral, and
C4C-05 remains blocked pending a separate explicit owner instruction. Generic uppercase currency
markers, broad `total` matching, off-main Vision integration, physical OCR, 60-plus fixture
accuracy, 20-image stability, confirmation, and persistence stay with C4C-05 and are not recorded
as passed here. This documentation-only closeout changes no customer behavior, so `CHANGELOG.md`
is unchanged.

The documentation-only closeout source passed `Scripts/validate.sh`: every static contract,
Release compilation, the strict Dashboard wall-clock stage, 502 unit-test results across 30
suites (491 passed and 11 explicit physical-only skips), all 17 UI tests, and every selected
core-service coverage threshold passed. CSVExporter remained the minimum selected result at
87.60% against the required 85%. The script's ephemeral
`mindbudget-validation.TbfLO2/MindBudget.xcresult` bundle was removed by normal cleanup; a
read-only mirror at `/private/tmp/MindBudget-C4C04-closeout-final.xcresult` parsed as `Passed`
with zero failures and independently passed the coverage gate.

Independent review, green hosted CI, and merge remain required for this closeout branch. No
Production, Archive/upload, tester, distribution, or release action is authorized, and this
closeout does not enter C4C-05 automatically.

## 2026-08-26 — Enter C4C-05 local receipt confirmation and evaluation

After PR #73 merged the C4C-04 documentation closeout as `2107723`, the owner explicitly entered
C4C-05. The in-progress candidate enables the verified-Pro receipt entry only for a new manual
expense. One explicit photo/camera choice enters the existing bounded lifecycle; accurate Vision
OCR runs off the main actor, sensitive filtering precedes any optional Apple on-device model, and
the temporary prepared JPEG is deleted before review. Missing model capability falls back to the
deterministic Pro tier. No URLSession, remote model, schema, iCloud receipt field, or content log
was added.

Accepted fields only prefill the editable expense form. A dedicated integration test proves the
database remains empty after review-prefill and gains one `receiptImport` expense only after the
existing Save action. The checked-in evaluation adds 60 exact supported fixtures (USD/JPY/KWD),
ten nonreceipts, generic-uppercase/`Totally` false-positive regressions, spaced-mask privacy
coverage, and 20 sequential real-JPEG bounded lifecycle/cleanup iterations. The four focused
receipt suites pass locally on iPhone 17 Pro, iOS 26.5. Physical DataScanner/PHPicker/OCR evidence,
independent review, hosted CI, and merge remain open; none is recorded as passed here. Production
and release actions remain unauthorized.

The exact candidate subsequently passed the complete local entry. Focused result
`/private/tmp/MindBudget-C4C05-Focused.xcresult` contains 40/40 passing tests with no skip. Full
result `/private/tmp/MindBudget-C4C05-Full.xcresult` contains 508 unit-test results (497 passed and
11 explicit opt-in/runtime skips), all 17 UI tests, Release compilation, the strict 10,000-row
Dashboard benchmark, every static contract, and every selected coverage threshold; CSVExporter is
the minimum selected result at 87.60% against 85%. The three registered physical iPhones were
offline during this entry. These simulator results do not satisfy the still-mandatory physical
DataScanner/PHPicker/OCR gate. Independent review, hosted CI, and merge also remain open.

## 2026-08-26 — Close the C4C-05 physical acquisition and confirmation evidence gap

The owner connected `拉沙的iPhone` on iOS 26.6.1 and exercised both system acquisition surfaces
under Xcode 27 beta 6 (`27A5252f`). The first paper-invoice camera attempts failed closed. A
privacy-safe `ReceiptImport` reason-code logger identified `ocr.invalidGeometry` without emitting
image, OCR, merchant, amount, or other receipt content. Investigation also found that 4032 x 3024
captures could remain above the 12-million prepared-pixel ceiling because the independent 4096
edge bound did not request a thumbnail reduction.

The remediation derives ImageIO's thumbnail edge from both reviewed bounds and clamps only finite,
positive Vision text geometry within 0.005 of the unit square. Material drift remains rejected.
Focused `ReceiptImageLifecycleTests` plus `ReceiptOCRPrivacyTests` pass 21/21 at
`/private/tmp/MindBudget-C4C05-PhysicalRemediation.xcresult`, including a full-resolution iPhone
capture and both sides of the geometry tolerance.

After deployment, the same physical camera flow reached local review. Merchant/date evidence was
accepted; the uncertain total stayed `needs manual review` and was not guessed. Applying that
review and canceling the expense form produced no new expense. A separate one-image PHPicker flow
reached review, applied to the editable form, and produced exactly one `$25.00` expense only after
explicit Save. These observations close the mandatory physical DataScanner/PHPicker/local-OCR and
confirmation-boundary evidence, but do not claim broad receipt accuracy or successful automatic
amount recognition for the paper invoice. C4C-05 remains In Progress pending independent review,
green hosted CI on the reviewed head, and merge; Production and release remain unauthorized.

The remediated candidate then passed the exact complete repository entry at
`/private/tmp/MindBudget-C4C05-Final.xcresult`: 510 unit-test results across 31 suites (499 passed
and 11 explicit opt-in/runtime skips), 17/17 UI tests, Release compilation, the strict 10,000-row
Dashboard wall-clock stage, every static contract, and every selected coverage threshold. The
result bundle reports 527 total logical results, 516 passed, 11 skipped, and zero failed after UI
and parameterized cases are included. CSVExporter remains the minimum selected coverage result at
87.60% against 85%. The earlier sandboxed validation failure and transient Simulator Busy preflight
were environmental non-passes; the clean rerun above is the candidate evidence.

## 2026-08-27 — Rebuild the C4C-05 receipt journey from the owner handoff

The owner paused submission and supplied `RECEIPT_CAPTURE_REDESIGN_HANDOFF.md`. DEC-COM-053 selects
its recommended option A because the accepted DataScanner surface provides no live rectangle
evidence. The implementation therefore uses an always-white framing aid and honest preview copy;
it never shows the handoff's C-only green aligned state or promises automatic cropping.

The first-use local-only explanation, one-primary-action camera overlay, torch control, PHPicker,
capture preview, form-level progress, edit-preserving prefill, inline review/failure cards, and
generation-safe cancellation are implemented. The existing Save action remains the only write.
A recent-photo thumbnail was not added because it would broaden Photos access, and long-receipt
stitching remains a disabled labelled slot because it has no reviewed product or processing
contract. Focused compile/test evidence is recorded on the commercialization track; complete
repository validation then passed at `/private/tmp/MindBudget-C4C05-Redesign-Final2.xcresult`:
514 unit results, 17/17 UI tests, Release, the strict Dashboard benchmark, every static contract,
and coverage passed. The result summary reports 531 total, 520 passed, 11 explicit skips, and zero
failed. Independent review, hosted CI, and merge remain open.

## 2026-08-27 — Close C4C-05 receipt review gaps on the production path

Independent review of PR #74 found that the no-write/edit-preservation tests were calling an
unreachable unconditional prefill helper, while the production method inferred user ownership from
value equality. The same review found that inline failures discarded their associated reason,
product/Pro gates impersonated storage failure, transient inactive scenes destroyed captured work,
and asynchronous cleanup did not identify the artifact it intended to remove.

DEC-COM-054 removes the dead helper and tests the actual recognition generation. Amount, merchant,
and date now carry explicit edit ownership for the whole generation, including when the user changes
a value back to its starting value. Typed failures retain distinct localized titles, details, and
appropriate recovery actions. Inactive scenes show a receipt privacy shield and preserve work;
backgrounding still cancels and discards. Prepared-image cleanup is artifact-scoped, so an old task
cannot delete a newer generation. No recognized field contribution continues to produce truthful
`.manual` provenance after explicit Save.

The app and test targets compile under final Xcode 26.6. Focused iOS 26.5 simulator execution under
Xcode 27 beta 6 passes 22/22 tests in `ReceiptImportIntegrationTests` and
`ReceiptImageLifecycleTests` at `/private/tmp/MindBudget-C4C05-ReviewFix-Focused2.xcresult`, with
zero failures or skips. A separate Designed-for-iPhone-on-Mac attempt was rejected before execution
because the provisioning profile did not include the Mac; it is an environmental non-pass and not
evidence. The exact remediated source then passed `Scripts/validate.sh` at
`/private/tmp/MindBudget-C4C05-ReviewFix-Final.xcresult`: every static contract, Release
compilation, the strict 10,000-row Dashboard wall-clock stage, 522 unit-test results across 31
suites, all 17 UI tests, and every selected coverage threshold passed. The bundle reports 539
logical results, 528 passed, 11 explicit opt-in/runtime skips, and zero failed; CSVExporter remains
the minimum selected coverage result at 87.60% against 85%. Independent rereview, hosted CI, and
merge remain open.

## 2026-08-27 — Tighten C4C-05 review-maintenance seams

The independent rereview raised three nonblocking maintainability observations. The bounded test
wait now exits as soon as recognition completes and records an explicit timeout instead of using a
`for ... where` filter. The unused `receipt.error.unreadable` catalog entry is removed, and the
unreadable-image title/detail use shared `receipt.failure.unreadable.*` keys rather than keys named
for only the inline surface. `amountText`, `merchantName`, and `spentAt` are now compiler-enforced
`private(set)` values; tests and UI mutations use the same user-input methods that own edit tracking.

The first focused attempt could not connect to CoreSimulator in the restricted environment and is
an environmental non-pass. The unrestricted rerun passes 76/76 tests across
`ReceiptImportIntegrationTests`, `Phase3FeatureTests`, `Phase4FeatureTests`, and
`Phase5FeatureTests` at `/private/tmp/MindBudget-C4C05-P3Fix-Focused2.xcresult`. This maintenance
does not change the C4C-05 scope, provenance decision, persistence boundary, or release authority.

## 2026-08-27 — Close C4C-05 and COM-C4C after PR #74 merge and exact-delta review

Independent review approved remediation head `8607356` and raised three nonblocking P3
observations. Final maintenance head `81cd107` applied them and passed GitHub Actions run
`33035427257` in 26m06s; PR #74 then merged the verified-Pro local receipt-import implementation,
physical evaluation remediations, owner-requested capture redesign, production-path review fixes,
and bounded P3 maintenance to `main` as `d751ff4` without a pre-merge rereview. During PR #75's
2026-08-27 closeout review, the independent reviewer read that exact maintenance delta and
confirmed all three fixes correct.

DEC-COM-055 records C4C-05 and COM-C4C as Done. The accepted evidence remains narrow: checked-in
60-receipt/10-nonreceipt and 20-image matrices, zero-leak/privacy tests, complete local validation,
and physical iOS 26.6.1 DataScanner/PHPicker/local-OCR plus cancel-without-write/explicit-Save
observations. The uncertain paper-invoice total remains manual-review-only and is not an automatic
amount-recognition pass.

This closeout changes documentation and its static guard only; `CHANGELOG.md` is unchanged. It does
not enter COM-C5, resolve first-party telemetry scope, add egress or receipt persistence, deploy
Production, or authorize Archive/upload/tester/distribution/release. The closeout branch still
requires independent review, green hosted CI, and merge.

The documentation-only branch then passed `Scripts/validate.sh` at
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.3SiQ1W/MindBudget.xcresult`:
all static contracts, Release compilation, the strict 10,000-row Dashboard wall-clock stage, the
complete unit-test execution, all 17 UI tests, and every selected coverage threshold passed.
`CSVExporter.swift` remains the minimum selected coverage result at 87.60% against 85%. The
temporary result bundle was removed by the validator after the successful run.

## 2026-08-27 — Enter COM-C5 and implement the dormant C5-01 typed telemetry client

After PR #75 merged the C4C-05 closeout as `82ef0fa`, the owner explicitly entered COM-C5.
DEC-COM-056 limits C5-01 to a dormant local capability: a closed typed event vocabulary, validated
content-free envelopes, default-off collection, rotating unlinkable pseudonyms, retained deletion
proofs, a bounded encrypted queue, serialized read/modify/write, generation-safe batching, and
bounded retry. The app contains no production `TelemetryClient` construction, capture call, URL,
receiver, or live transport, so current telemetry collection and network egress remain zero.
C5-02 through C5-04 remain blocked.

Thirteen deterministic telemetry tests pass on the simulator. The final test adds a gated transport
lane that proves concurrent flushes cannot upload the same batch twice. A first full-validation attempt in the
restricted environment could not connect to CoreSimulator and produced an empty bundle identifier;
it stopped before trustworthy execution and is excluded as an environmental non-pass. The
unrestricted rerun of `Scripts/validate.sh` passed every static contract, Release compilation, the
strict 10,000-row Dashboard wall-clock stage, 530 unit tests across 32 suites, all 17 UI tests, and
every selected coverage threshold. Four opt-in physical CloudKit probes were reported as skipped;
`CSVExporter.swift` was the minimum selected coverage result at 87.60% against 85%. The validator
removed its temporary result bundle after completion, so its path was an execution pointer rather
than a durable artifact. Independent review, hosted CI, and merge remain open.

## 2026-08-27 — Remediate C5-01 deletion and contract-gate review findings

Independent review of PR #76 found that sticky corrupt telemetry state also blocked the only local
file/key deletion path, and that the broad unlinkability wording did not disclose the grouped
complete-delete envelope. DEC-COM-057 now keeps corrupt state fail-closed for collection and
overwrite while allowing local file/key deletion with the distinct
`.deletedLocallyWithoutRemoteProofs` result. Ordinary upload envelopes never reuse or group a prior
pseudonym; the bounded complete-delete request intentionally groups retained proofs, and C5-02 must
not persist, log, or reuse that association. C5-02 also owns the real transport's in-flight opt-out
cancellation decision, while C5-04 owns truthful guidance when four retained generations block a
new identity.

The redundant capacity check was removed from retirement and remains only at identity creation.
The dormancy scan no longer depends on `rg` inside a fail-open conditional: required tools and source
roots are explicit, scan exit states distinguish clean from incomplete, and event, envelope,
construction, and scan-failure fixtures run on every invocation. Seventeen deterministic telemetry
tests pass, including corrupt protocol-state deletion, real encrypted-file/key deletion, explicit
grouped proof coverage, and the four-generation fail-closed boundary. The owning unrestricted
`Scripts/validate.sh` run then passed every static contract, Release compilation, the isolated
strict 10,000-row Dashboard benchmark, 534 unit tests across 32 suites, all 17 UI tests, and every
selected coverage threshold. Four physical CloudKit probes remained explicit skips;
`CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The validator removed
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.OzAGSt/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact. Exact-head
rereview, hosted CI, and merge remain open; no production client, collection, URL, transport, or
egress was added.

## 2026-08-27 — Close the C5-01 default-off persistence and failure-classification review

Final PR #76 review found that explicitly disabling a missing never-enabled client still committed
`.disabled`, which created the encrypted file and device-only key despite the zero-write default-off
contract. DEC-COM-058 makes an already-disabled request return before persistence, defaults
`TelemetryPolicy` to the user's autoupdating calendar, separates post-response local commit failure
as `.persistenceFailed`, and requires C5-02 event/delete idempotency because remote success may
precede failed local acknowledgement or cleanup.

The retry regression now proves capture remains available during backoff; the static gate anchors
the two previously omitted tests plus every new regression. Focused iOS 26.5 simulator execution
passes 21/21 with no failure or skip, including a real encrypted-persistence assertion that repeated
Disable creates neither file nor key, daylight-saving calendar behavior, local commit-failure
classification, and an identical delete retry after local cleanup failure. A first full-validation
attempt was blocked by restricted CoreSimulator and DerivedData access before trustworthy execution
and is retained as an environmental non-pass. The unrestricted rerun passed every static contract,
Release compilation, the isolated strict 10,000-row Dashboard benchmark, 538 unit tests across 32
suites, all 17 UI tests, and every selected coverage threshold. Four physical CloudKit probes were
explicit skips; `CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The
validator removed its temporary `mindbudget-validation.g8bqhg/MindBudget.xcresult` bundle after
success, so that name is an execution pointer rather than a durable artifact. Hosted CI and merge
remain required. The client remains dormant with no production
construction, capture call, URL, transport, collection, or egress.

## 2026-08-28 — Close C5-01 after reviewed PR #76 merge

Independent review approved exact final head `d937dc8`. GitHub Actions run `33085630481` completed
successfully on that head, and PR #76 merged the dormant typed telemetry client to `main` as
`68304ad`. DEC-COM-059 closes only C5-01 on this evidence.

The current app still has no production telemetry-client construction, capture call, URL,
receiver, transport, customer setting, or App Privacy change. Collection and egress remain zero.
C5-02 awaits a separate explicit owner instruction, C5-03/C5-04 remain blocked, and no Production,
Archive/TestFlight/App Store, tester, distribution, or release action is authorized. This session
changes documentation and its state gate only; it changes no Swift, schema, entitlement,
persistence, or customer behavior.

The closeout branch then passed `Scripts/validate.sh`: every static contract, Release compilation,
the strict 10,000-row Dashboard benchmark, 538 unit tests across 32 suites, all 17 UI tests, and
every selected coverage threshold passed. Four opt-in physical CloudKit probes were explicit
skips, and `CSVExporter.swift` remained the minimum selected result at 87.60% against 85%. The
validator removed its temporary `mindbudget-validation.k5zkq3/MindBudget.xcresult` bundle after
success, so the name is an execution pointer rather than a durable artifact.

## 2026-08-28 — Implement C5-02 deletion-safe minimal telemetry ingest

The owner explicitly entered C5-02 after the reviewed C5-01 closeout. DEC-COM-060 adds a strict
first-party Cloudflare Worker/D1 receiver with exact environment hosts, bounded closed-schema
upload and proof-authenticated complete deletion, event-ID idempotency, atomic conflict rejection,
independent deletion tombstones, maximum 90 x 24-hour UTC retention, bounded hourly cleanup, and
closed non-content monitoring. The iOS transport adapter is compiled and directly tested, but
`UnavailableTelemetryTransport` remains the production default: no production client is
constructed, no capture call exists, and current customer telemetry collection/egress remain zero.

Only Development was migrated, deployed, and probed. Worker version
`1c162a57-8789-4f7f-9fec-f2c484e9f4f2` accepted one event, accepted its identical retry,
atomically rejected the same event ID with changed facts, authenticated complete deletion, and
accepted-but-discarded a matching late upload. The final Development D1 read showed zero events,
zero identities, and two independent tombstones. Staging has only an isolated, unmigrated,
undeployed D1 resource; Production has no provisioned D1 and no deployment. C5-03/C5-04,
customer controls, App Privacy changes, metrics, Production, distribution, and release remain
blocked. Independent review, hosted CI, and merge remain required.

The first owning full-validation attempt used the system Command Line Tools selection and stopped
before any Xcode build; it is an environmental non-pass. The explicit Xcode 27 beta 6 rerun passed
every static contract, Release compilation, the strict 10,000-row Dashboard benchmark, 542 unit
tests across 32 suites, all 17 UI tests, and every selected coverage threshold. Four opt-in
physical CloudKit probes remained explicit skips, and `CSVExporter.swift` was the minimum selected
coverage result at 87.60% against 85%. The validator removed its temporary
`mindbudget-validation.1f3FOS/MindBudget.xcresult` bundle after success, so the name is an execution
pointer rather than a durable artifact. `Docs/CHANGELOG.md` is unchanged because the adapter remains
dormant and this package adds no customer-visible behavior.

## 2026-08-28 — Remediate C5-02 request-correlation, metadata, and retention findings

Independent review of PR #78 found that exact millisecond tombstone expirations could preserve a
complete-delete request grouping, ambient URLSession headers exceeded the closed egress contract,
and one 1,000-row hourly cleanup pass could not prove the documented maximum retention under
backlog. DEC-COM-061 replaces exact deletion timing with one coarse UTC-day expiry bucket shared
across independent requests, fixes `User-Agent` to `MindBudget`, suppresses `Accept-Language`, and
requires the receiver to reject variable metadata. Scheduled cleanup still uses bounded 1,000-row
transactions but repeats them until no expired full batch remains. Strict JSON whitespace,
explicit base64 deletion-secret encoding, and the redundant event-shape precheck were also closed.

Worker verification passes 32/32 against local D1, type generation/typecheck, all three environment
dry-run/startup checks, and `npm audit --audit-level=high` with zero vulnerabilities. The focused
iOS telemetry suite passes 25/25 with no failure or skip. The first owning full-validation attempt
passed every static contract but stopped at Release linking when the selected Xcode toolchain
briefly reported its own `clang` executable missing; the executable was immediately present on
reinspection, so this is retained as an environmental non-pass. A clean rerun with Xcode 27 beta 6
passed every static contract, Release compilation, the strict 10,000-row Dashboard benchmark, 542
unit tests across 32 suites, all 17 UI tests, and every selected coverage threshold. Four opt-in
physical CloudKit probes remained explicit skips; `CSVExporter.swift` was the minimum selected
result at 87.60% against 85%. The validator removed its temporary
`mindbudget-validation.Qwp8O6/MindBudget.xcresult` bundle after success, so the name is an execution
pointer rather than a durable artifact.

The iOS adapter remains unconstructed with zero capture/customer telemetry egress. HTTP
404/405/421 terminal handling remains an explicit C5-04 prerequisite before any construction.
C5-02 remains pending Development redeploy/probe of the remediated source, exact-head rereview,
green hosted CI, and merge. Staging/Production, C5-03/C5-04, App Privacy changes, distribution, and
release remain blocked. `Docs/CHANGELOG.md` remains unchanged because no customer-visible behavior
is enabled.

## 2026-08-28 — Close C5-02 after reviewed PR #78 merge

Independent review approved exact remediation head `72abf4b`: both P1, both P2, and two of three
P3 findings were closed with targeted tests. The fixed-endpoint 404/405/421 terminal-failure P3 is
deferred to C5-04, while the remaining observability and future physical confirmation observations
were explicitly nonblocking. GitHub Actions run `33176551566` completed successfully on that exact
head, and PR #78 merged to `main` as `4715054`. DEC-COM-062 therefore marks C5-02 Done.

This closeout does not claim a post-remediation Development deployment or probe. The recorded
Development Worker remains the earlier candidate; Staging remains unmigrated/undeployed and
Production remains unprovisioned/undeployed. `UnavailableTelemetryTransport` is still the app
default, there are zero production client constructions and capture calls, and current customer
telemetry collection/egress remain zero. C5-03 is no longer dependency-blocked but awaits separate
explicit owner entry; C5-04 remains blocked by C5-03. App Privacy changes, Production,
distribution, and release remain unauthorized.

This branch changes documentation and its state gate only; it changes no Swift, Worker, schema,
endpoint, entitlement, persistence, customer control, or user-visible behavior. Consequently
`Docs/CHANGELOG.md` remains unchanged. The closeout branch passed every static contract, Release
compilation, the isolated strict 10,000-row Dashboard benchmark, 542 unit tests across 32 suites,
all 17 UI tests, and every selected coverage threshold. Four opt-in physical CloudKit probes were
explicit skips; `CSVExporter.swift` was the minimum selected result at 87.60% against the 85%
floor. The validator removed its temporary
`mindbudget-validation.Bj3fdn/MindBudget.xcresult` bundle after success, so the name is an
execution pointer rather than a durable artifact. Independent review, green hosted CI, and merge
remain required for this documentation closeout.

PR #79 independent review identified that the egress matrix placed current post-DEC-COM-061
retention behavior beside the earlier Development probe without a time boundary, and that the
closeout record counted all three P3 findings as closed. The matrix now identifies Worker
`1c162a57-8789-4f7f-9fec-f2c484e9f4f2` as pre-remediation, non-current-source probe evidence; the
decision and session records state that two P3 findings closed while fixed 404/405/421 terminal
handling remains deferred to C5-04. The CI baseline now records Xcode 27.0 beta 6 (`27A5252f`) on
the iOS 26.5 iPhone 17 Pro simulator. No runtime or deployment state changed.

## 2026-08-29 — Implement C5-03 metrics and evidence computation

The owner explicitly entered C5-03 after the reviewed C5-02 closeout. DEC-COM-063 adds a dormant,
read-only receipt-funnel aggregate over local Worker D1 test infrastructure and a separate offline
evidence builder. The query accepts only an exact app version and a bounded half-open UTC window,
counts a pseudonym generation once at each ordered completed step, and returns only opened,
acquired, reviewed, and saved aggregate counts. It is not imported by the live Worker entry point
and exposes no HTTP route. No D1 write, identity row, event row, or content field can leave the
query boundary.

The evidence builder accepts a closed nine-metric vocabulary spanning owner-supplied App Store
Analytics aggregates, first-party telemetry aggregates, and a fixed bilingual voluntary survey.
It records exact numerator, denominator, sample size, observation window, source-export digest,
and one of four explicit availability states. Available ratios use a fixed 95% Wilson score
interval rounded outward to integer basis points. Coverage describes evidence completeness only;
it is never presented as customer participation, and telemetry pseudonyms are never divided by
Apple Active Devices. Canonical JSON is written immutably through a same-directory `0600` temporary
file plus no-overwrite hard link and read-back verification.

Worker verification passes 35/35 Vitest cases against local D1, six Node evidence-contract tests,
generated binding types, TypeScript checking, all three environment dry-run/startup checks, and a
high-severity dependency audit with zero vulnerabilities. The new static gate proves that neither
the metrics module nor evidence tool is reachable from the production Worker and that the evidence
tool contains no network client or identifier/content schema. Full validation with Xcode 27.0 beta
6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator passed every static contract, Release
compilation, the strict 10,000-row Dashboard benchmark, 542 unit tests across 32 suites, all 17 UI
tests, and every selected coverage threshold. Four opt-in physical CloudKit probes remained
explicit skips; `CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The
validator deleted its temporary `mindbudget-validation.0CrPs7/MindBudget.xcresult` bundle after
success, so the name is an execution pointer rather than a durable artifact.

No production telemetry client is constructed, no capture call or customer control is added, no
survey or App Store export is claimed collected, and no real evidence bundle, metric result,
threshold pass, G1 decision, deployment, App Privacy change, distribution, or release is claimed.
C5-03 remains pending independent review, hosted CI, and merge; C5-04 remains blocked. There is no
CHANGELOG entry because the package introduces no customer-visible or live-network behavior.

PR #80 independent review found that the candidate root coverage value added exact segments across
different environments and overlapping `ALL`/specific-storefront populations. DEC-COM-064 removes
that root roll-up entirely: coverage now belongs only to one exact environment/app-version/
storefront/device-family segment. Each segment also exposes
`widestConfidenceIntervalBasisPoints`; a one-of-one sample remains honestly computable but reports
the 7,935-basis-point Wilson width instead of looking as strong as a large sample. No arbitrary
minimum denominator or G1 threshold was invented in C5-03.

Regression coverage now includes mixed Development/Production segments, overlapping `ALL`/`USA`
storefronts, the one-of-one weak-sample vector, and a no-available-metric `null` width. The Worker
check passes 35/35 local-D1 cases and eight offline evidence-contract tests, all three environment
dry-runs/startup checks, generated bindings, TypeScript checking, and the high-severity dependency
audit with zero vulnerabilities. Full validation with Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 iPhone 17 Pro simulator passed every static contract, Release compilation, the strict
10,000-row Dashboard benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every selected
coverage threshold. Four opt-in physical CloudKit probes remained explicit skips;
`CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The validator removed
`mindbudget-validation.MjKE14/MindBudget.xcresult` after success, so the name is an execution
pointer rather than a durable artifact. No deployment, evidence collection, threshold pass, or G1
decision is claimed; exact-head rereview, hosted CI, and merge remain required.

## 2026-08-29 — Close C5-03 after reviewed PR #80 merge

Independent review approved head `4ea7cd9` and raised one P2 cross-segment coverage issue plus one
P3 weak-sample-visibility issue. Remediation head `0c61427` applied both, GitHub Actions run
`33211270363` completed successfully, and PR #80 merged it to `main` as `a587f42` without a
pre-merge rereview. PR #81's post-merge closeout review read that exact remediation delta and
confirmed both fixes. DEC-COM-065 marks C5-03 Done on the dormant metrics/evidence computation
only.

The reviewed package remains outside every live data path: the D1 aggregate has no route, the
offline builder has no network client, `UnavailableTelemetryTransport` remains the production app
default, and there are zero production client constructions or capture calls. No App Store export,
survey response, telemetry sample, real evidence bundle, metric conclusion, threshold pass, or G1
decision is claimed. C5-04 is no longer dependency-blocked but awaits separate explicit owner
entry; customer controls/disclosure, App Privacy, terminal endpoint-policy behavior, operational
TTL/delete proof, Staging/Production, distribution, and release remain unauthorized.

This closeout changes documentation and the commercialization state gate only. It changes no
Swift, Worker, schema, route, persistence, entitlement, egress, customer behavior, or release
artifact, so `Docs/CHANGELOG.md` remains unchanged. Independent review, green hosted CI, and merge
remain required for this documentation-only closeout.

The closeout branch then passed `Scripts/validate.sh` with Xcode 27.0 beta 6 (`27A5252f`) on the
iOS 26.5 iPhone 17 Pro simulator: Release compilation, 35/35 local-D1 Worker tests, eight C5
evidence-contract tests, 542 unit tests across 32 suites, all 17 UI tests, the strict 10,000-row
Dashboard benchmark, and every selected coverage threshold passed. Four opt-in physical CloudKit
tests were explicit skips. `CSVExporter.swift` remained the minimum selected coverage result at
87.60% against the 85% floor. The validator deleted
`mindbudget-validation.1rJYdA/MindBudget.xcresult` after success, so the name is an execution
pointer rather than a durable artifact.

## 2026-08-29 — Remediate PR #81 closeout provenance and gate review

Independent review found that the closeout incorrectly described remediation head `0c61427` as
independently reviewed before merge. The actual pre-merge review covered `4ea7cd9` and raised one
P2 cross-segment coverage issue plus one P3 weak-sample-visibility issue. `0c61427` applied both,
passed run `33211270363`, and merged through PR #80 as `a587f42` without a pre-merge rereview. PR
#81's review then read that exact remediation delta post-merge and confirmed both fixes.

The remediation replaces the inaccurate chronology throughout current-state/evidence documents,
requires `4ea7cd9`, `0c61427`, the hosted run, merge, PR #81, and the C5-04 owner-entry boundary in
every controlled file, and rejects any renewed claim that `0c61427` received pre-merge review. It
also removes the unqualified generic pending-review grep: the existing structural parser owns
heading-scoped phase Status validation and now includes an explicit valid C5-03 Done/C5-04 pending
review self-test. Static money, egress, commercialization-document, StoreKit 13/13, C5 evidence
8/8, parser self-test, and `git diff --check` all pass. No runtime or customer behavior changed;
hosted CI and rereview of the new exact closeout head remain required.

## 2026-08-29 — Enter C5-04 and implement controlled first-party telemetry activation

The owner explicitly entered C5-04 after the reviewed C5-03 closeout. DEC-COM-066 permits one
environment-isolated `TelemetryClient`/`FixedTelemetryTransport` factory behind a bilingual,
default-off Privacy control. The implementation adds bounded lifecycle start/flush, explicit Retry,
sticky non-retrying 404/405/421 endpoint-policy failures, and proof-authenticated telemetry deletion
before app-wide financial deletion can continue. Product capture is limited to the closed events in
`C5_TELEMETRY_CAPTURE_AUDIT.md` from `AppRouter.swift`, `ProSubscriptionView.swift`, and
`AddExpenseView.swift`; the vocabulary still cannot represent financial or receipt content,
StoreKit/CloudKit identifiers, locale, device details, or arbitrary strings.

The privacy manifest now declares Product Interaction and a conservative rotating Device ID as
unlinked, non-tracking Analytics. `C5_TELEMETRY_OPERATIONS_RUNBOOK.md` defines Development-only
publish/probe/rollback, closed monitoring, TTL/delete checks, and credential boundaries. Staging and
Production remain untouched. Focused iOS execution with Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 iPhone 17 Pro simulator passed 47/47 telemetry/Delete-All lifecycle tests; Worker verification passed 35/35
local-D1 tests and all eight immutable-evidence tests plus typecheck, dry-runs, startup checks, and
the high-severity audit. A sandboxed simulator attempt was excluded as an environmental non-pass.
The current Worker source was not uploaded because this run lacks explicit authorization for that
remote source deployment. Therefore no current-source Development probe, G1 decision,
Staging/Production action, distribution, or release is claimed. Full validation, exact-head review,
hosted CI, and merge remain open.

## 2026-08-29 — Finalize the C5-04 local activation candidate

The final self-review tightened four activation boundaries before external review: Pro-surface
events now pair once per visible interval; remote deletion durably disables collection and clears
the unsent queue before transport, retains deletion proofs after a remote failure, and blocks
re-enablement until Delete is explicitly retried; a missing application-support URL or invalid app
version now produces an unavailable telemetry service instead of blocking local app startup; and
the Privacy UI test verifies both the default-off toggle and the exact never-collected disclosure.
The disclosure assertion uses a label predicate because its localized English sentence exceeds
XCUITest's 128-character identifier-query limit.

The final focused `TelemetryClientTests` plus `Phase6FeatureTests` command passed all 48 declared
tests. The exact current-source `Scripts/validate.sh` run used Xcode 27.0 beta 6 (`27A5252f`) and
the iOS 26.5 iPhone 17 Pro simulator. It passed every static contract, the Release build, 35/35
local-D1 Worker tests, eight immutable-evidence tests, 550 unit tests across 32 suites, all 17 UI
tests, and every selected coverage threshold. Four opt-in physical CloudKit probes remained
explicit skips. `CSVExporter.swift` was the minimum selected coverage result at 87.60% against the
85% floor. The validator deleted
`mindbudget-validation.XKvHyp/MindBudget.xcresult` after success, so that name is only an execution
pointer.

An earlier strict wall-clock attempt measured the isolated 10,000-row Dashboard benchmark at
661.598333 milliseconds against the 500-millisecond ceiling on this loaded host. It is recorded as
a performance non-pass and was not replaced by a false passing claim; the final correctness run
used `MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1`. One intermediate full run was deliberately
interrupted after the overlong XCUITest query was found and is not evidence.

No Worker source was deployed and no live endpoint, TTL, or deletion probe was run because this
session still lacks explicit authorization to upload current source to Cloudflare Development.
Staging and Production remain untouched. C5-04/COM-C5 remain In Progress pending that separately
authorized Development evidence, exact-head independent review, green hosted CI, and merge; no
G1, distribution, or release conclusion is claimed.

## 2026-08-29 — Remediate PR #82 local deletion and performance review

Independent review found that the optional telemetry remote-delete result incorrectly controlled
whether app-wide Delete All could erase the authoritative local financial store. DEC-COM-067 now
supersedes that part of DEC-COM-066: Delete All still stops capture and attempts authenticated
telemetry deletion first, but `.failed`, `.terminalFailure`, and `.unavailable` results retain
proofs for a separate Privacy retry and cannot stop the local financial erase. The app publishes a
distinct completed-with-pending-telemetry state and bilingual guidance instead of falsely claiming
that the remote copy was deleted. A parameterized regression covers all three failure classes and
proves zero local model counts, reset preferences, retained retry evidence, and the intended stage
ordering.

The review also rejected the unsupported attribution of the earlier 661.598333-millisecond strict
Dashboard result to host load. That historical non-pass remains recorded. Under one controlled
same-machine comparison using Xcode 27.0 beta 6 (`27A5252f`), the iOS 26.5 iPhone 17 Pro simulator,
parallel testing disabled, and three consecutive repetitions, both the remediation branch and
`origin/main` passed the 500-millisecond strict assertion 3/3. The earlier result was therefore not
reproducible under this comparison; no unmeasured cause is claimed.

Focused Phase 6 execution passed all 16 declared tests, including all three parameterized
telemetry-failure cases. Exact-source `Scripts/validate.sh` then passed without a wall-clock skip:
every static contract, Release compilation, 35/35 local-D1 Worker tests, eight C5 evidence tests,
the strict 10,000-row Dashboard benchmark, 550 unit tests across 32 suites, all 17 UI tests, and
every selected coverage threshold. Four opt-in physical CloudKit tests remained explicit skips;
`CSVExporter.swift` was the minimum selected coverage result at 87.60% against the 85% floor. The
validator removed `mindbudget-validation.LO2cps/MindBudget.xcresult` after success, so that name is
an execution pointer rather than a durable artifact. No Worker deployment, endpoint probe, G1,
Staging/Production action, distribution, or release conclusion is introduced. C5-04/COM-C5 remain
In Progress pending the existing external evidence, exact-head rereview, hosted CI, and merge.

## 2026-08-29 — C5-04 reviewed product merge calibration

Independent review approved the deletion-order remediation on exact head `2c1cebe` within its
declared scope. It excluded the privacy manifest, AddExpense/Pro capture sites, `TelemetryService`,
and the operations runbook. GitHub Actions run `33233846430` completed successfully on that head,
and PR #82 merged it to `main` as `28d9eae`. DEC-COM-068 records the exact source/run/merge facts
without expanding review coverage or claiming the still-missing current-source Development Worker
deployment or endpoint/TTL/delete-idempotency probe.

The current-state task, memory, privacy, requirement, egress, capture-audit, operations-runbook,
and execution-packet documents now distinguish the merged product capability from its open
operational evidence. C5-04 and COM-C5 remain In Progress. No Worker/D1 mutation, customer
collection, App Store Connect update, evidence bundle, G1 decision, Staging/Production action,
distribution, or release occurred in this documentation-only session.

The closeout branch then passed `Scripts/validate.sh` with Xcode 27.0 beta 6 (`27A5252f`) on the
iOS 26.5 iPhone 17 Pro simulator: Release compilation, 35/35 local-D1 Worker tests, eight C5
evidence tests, the strict 10,000-row Dashboard benchmark, 550 unit tests across 32 suites, all 17
UI tests, and every selected coverage threshold passed. Four opt-in physical CloudKit tests were
explicit skips; `CSVExporter.swift` was the minimum selected result at 87.60% against the 85%
floor. The validator removed `mindbudget-validation.bKKG10/MindBudget.xcresult` after success, so
that name is an execution pointer rather than a durable artifact.

PR #83 review then required the closeout to separate the completed product merge from the
unchecked Development probe and to state PR #82's actual review scope. Its supplemental review is
explicitly directed at `PrivacyInfo.xcprivacy`, the AddExpense/Pro capture sites,
`TelemetryService` in `TelemetryClient.swift`, and the operations runbook. Source inspection also
confirmed that service `stop()` cancels tasks without invalidating the same client's explicit
delete retry. Delete All resets setup, so a retained remote-deletion proof becomes reachable from
Privacy & Security > Product Analytics only after onboarding is completed again; that manual UX
boundary is now carried in the runbook instead of being omitted.

## 2026-08-29 — Prove C5-04 current source only in Development

Synced `main` through PR #83 merge `becb020`, whose supplemental-review head `e6bbd3f` passed
GitHub Actions run `33242024609`. After exact account/Worker/D1/source verification and explicit
owner approval, Wrangler 4.127.0 deployed `becb020` only to Development as version
`003c66fa-a57c-4b6a-a8d7-3f75b14cc716`. No migration was pending or applied.

One disposable content-free synthetic sequence returned 202/202/409/204/202/204 with empty bodies.
Aggregate checks proved exact `7776000000`-millisecond event TTL, an earlier-or-equal UTC-day
tombstone, idempotent retry/conflict, proof deletion, and no late-upload resurrection. Exact cleanup
left no synthetic row; whole-D1 final counts remained 0 events, 0 identities, and 2 historical
pre-remediation tombstones. No customer data, request body, deletion secret, D1 row, or IP entered
the record. DEC-COM-069 keeps this as a pending-review Development operational-evidence candidate;
no G1, Staging/Production, App Store Connect, final-binary, distribution, or release conclusion
follows.

The evidence branch then passed `Scripts/validate.sh` with Xcode 27.0 beta 6 (`27A5252f`) on the
iOS 26.5 iPhone 17 Pro simulator. Every static contract, the Release build, 35/35 local-D1 Worker
tests, all eight evidence-contract tests, the complete unit-test run, 17/17 UI tests, and every
selected coverage threshold passed; `CSVExporter.swift` was the minimum selected result at 87.60%
against the 85% floor. The validator removed
`mindbudget-validation.wnudAw/MindBudget.xcresult` after success, so that name is an execution
pointer rather than a durable artifact. An immediately preceding attempt that inherited
`/Library/Developer/CommandLineTools` failed before Xcode execution and is recorded only as an
environmental non-pass; no product test failed in that attempt.

## 2026-08-29 — Correct PR #83 chronology and close the native telemetry transport gap

PR #84 review found that current-state documents omitted reviewed head `daea2d2` and incorrectly
described remediation head `e6bbd3f` as independently reviewed. The corrected chronology now says
that independent review covered `daea2d2`, raised two P2 findings and one P3, and explicitly
excluded the privacy manifest, AddExpense/Pro capture files, `TelemetryService`, and runbook.
`e6bbd3f` applied the findings and recorded the implementation author's supplemental inspection
of those surfaces, passed run `33242024609`, and merged as `becb020` without a pre-merge rereview.
DEC-COM-070 records that correction without rewriting the historical DEC-COM-069 entry.

The same remediation added `MindBudget-Telemetry-Live`, a default-disabled shared scheme that can
run tests but cannot archive. The first exact-method-filter invocation discovered zero tests and
is retained as a non-pass. The corrected suite-level run on the iOS 26.5 simulator explicitly
started the live test and exercised the real `FixedTelemetryTransport`, production
`BoundedTelemetryHTTPLoader`, and `URLSession`; the strict Development Worker accepted upload 202
and authenticated delete 204. A subsequent read-only D1 aggregate query returned 0 events,
0 identities, and 3 tombstones: 2 historical pre-remediation rows plus the expected UTC-day
tombstone from this native transport deletion. No row contents, UUID, secret, body, or IP were
read or recorded.

The ordinary focused telemetry suite passed 34/34 with the live test explicitly skipped by
default. It now includes `runtimeStopDoesNotInvalidateExplicitTelemetryDeletionRetry`, which calls
`stop()` and then proves an explicit delete on the same service performs the remote request,
removes encrypted persistence, and clears retained identity proofs. Static telemetry gates pin
both regressions, require the live opt-in only in its dedicated scheme, and forbid that scheme
from archiving. This is Debug simulator evidence, not customer/final-binary/G1/Staging/Production/
distribution/release authority. C5-04/COM-C5 remain In Progress pending rereview, hosted CI, and
merge.

The exact remediation branch then passed `Scripts/validate.sh` with Xcode 27.0 beta 6
(`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator. Every static contract and Release
compilation passed; 35/35 local-D1 Worker tests, 8/8 evidence-contract tests, 552 unit tests in 32
suites, and 17/17 UI tests passed. Every selected coverage threshold passed, with
`CSVExporter.swift` lowest at 87.60% against the 85% floor. The validator removed
`mindbudget-validation.ceXEOC/MindBudget.xcresult` after success, leaving only this execution
pointer rather than a durable artifact.

## 2026-08-29 — Close C5-04 and COM-C5 after PR #84

PR #84 exact head `84a96bc` passed independent review and GitHub Actions run `33247176815`, then
merged as `4194b73`. DEC-COM-071 marks C5-04/COM-C5 Done on that exact source/evidence chain and
keeps REQ-R1-TELEMETRY-001 Active for COM-C6/C12 final-binary and release verification.

The current-state documents now say COM-C6 awaits explicit owner entry rather than inheriting
entry from the C5 closeout. Development remains the only deployed telemetry environment; G1, App
Store Connect, Staging/Production, final-binary traffic, distribution, and release remain open.
This session changes only documentation and the commercialization-document gate, so CHANGELOG is
unchanged. The closeout branch still requires independent review, hosted CI, and merge.

`Scripts/validate.sh` passed this documentation-only branch under Xcode 27.0 beta 6 (`27A5252f`)
on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator: all static contracts, Release compilation,
35/35 local-D1 Worker tests, 8/8 C5 evidence-contract tests, 552 unit tests in 32 suites, 17/17 UI
tests, and every selected coverage threshold passed. `CSVExporter.swift` was the minimum at
87.60% against the 85% floor. The validator deleted
`mindbudget-validation.g93SCp/MindBudget.xcresult` after success, so the name is only an execution
pointer.

## 2026-08-29 — Preserve the independent App Privacy source review after C5

PR #85 review correctly found that C5 Done would otherwise leave no future independent-review
owner for the checked-in privacy manifest and its capture/service/runbook basis. The closeout now
makes COM-C6 independently inspect `MindBudget/Resources/PrivacyInfo.xcprivacy`, both telemetry
capture sites, the `TelemetryService` wiring in `MindBudget/Services/TelemetryClient.swift`, and
`Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md` before any App Store Connect privacy
answer is copied or accepted. The C5 implementation-author supplemental inspection remains
truthful provenance but explicitly does not satisfy this release gate.

C5-04/COM-C5 remain Done, COM-C6 remains unentered pending owner instruction, and no runtime,
manifest, capture, service, Worker, deployment, D1, App Store Connect, distribution, release, or
customer-data change occurred.

The remediated branch passed `Scripts/validate.sh` under Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 (`23F77`) iPhone 17 Pro simulator: all static contracts, Release compilation, 35/35 local-D1
Worker tests, 8/8 C5 evidence-contract tests, 552 unit tests in 32 suites, 17/17 UI tests, and every
selected coverage threshold passed. `CSVExporter.swift` was the minimum at 87.60% against the 85%
floor. The validator deleted `mindbudget-validation.lolUt1/MindBudget.xcresult` after success, so
the name is only an execution pointer. The new exact head still requires rereview, hosted CI, and
merge.

## 2026-08-29 — Enter COM-C6 and implement C6-01 automated release matrix

The owner explicitly entered COM-C6 after PR #85 merged as `008b674`. Work remained limited to
C6-01. Added a strict seven-row JSON inventory, fail-closed/self-testing validator, repository
contract command, and a complete local matrix runner that runs every reviewed static gate, both
first-party Worker `check` scripts, Release simulator build, and 16 Swift test containers. Added a
direct regression proving offline public configuration and unavailable telemetry cannot revoke an
injected verified local-Pro snapshot. `Scripts/validate.sh` now includes the matrix contract.

The complete C6-01 runner passed under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`)
iPhone 17 Pro simulator: all static contracts, Public Configuration Worker 13/13, Telemetry Worker
35/35 plus 8/8 evidence tests, all Worker typechecks/dry-runs/startup checks, Release build, and
285 Swift tests in 16 suites passed. The default-disabled live telemetry test remained skipped by
design. `/private/tmp/MindBudget-C6-01.xcresult` is a local execution artifact, not hosted or
durable release evidence.

The final branch also passed `Scripts/validate.sh` on the same toolchain and simulator: every
static contract, Release compilation, the strict 10,000-row Dashboard benchmark, 553 unit tests
in 32 suites, all 17 UI tests, and every selected coverage threshold passed. `CSVExporter.swift`
was lowest at 87.60% against the 85% floor. The validator removed its temporary xcresult after
success, so that path is only an execution pointer rather than a durable artifact.

No archive, upload, deployment, App Store Connect write, customer-data action, G1 decision, or
release action occurred. C6-02/C6-03 and the five-source independent privacy inspection remain
blocked pending C6-01 independent review, hosted CI, and merge. CHANGELOG is unchanged because the
only Swift change is test code and there is no user-visible behavior change.

## 2026-08-29 — Remediate C6-01 required-test and check-discovery review gaps

PR #86 review correctly found that `requiredMethods` was source metadata rather than execution
evidence and that a future repository check script could be omitted from the manual allow-list.
Added exact xcresult post-run verification: all 33 matrix bindings must appear once as Test Cases
with result Passed. Missing, skipped, failed, duplicate, wrong-type, commented-out, or non-test
methods now fail closed. Parameterized methods match their exact type and method basename.

Added direct discovery of every `Scripts/check-*.sh` and `Scripts/check_*.py` file. Twelve remain
row-driven; the C6 bootstrap and full-suite coverage consumer are the only exact special
classifications. Negative self-tests now reject an unclassified future gate plus skipped, missing,
and duplicate required-test evidence. The retained pre-remediation xcresult successfully exercised
all 33 bindings and exposed the parameterized Phase 6 identifier shape during implementation; it
is not exact-head evidence. The subsequent remediated C6 run passed all static and Worker checks,
Release/test builds, 285 tests in 16 suites, and the new post-run proof for all 33 bindings. Its
retained result is `/private/tmp/MindBudget-C6-01-Remediation.xcresult`; full repository validation
on the final documentation state then passed: the strict serial 10,000-row Dashboard benchmark,
553 unit tests in 32 suites, and 17/17 UI tests completed with 558 passed results, 12 explicit
opt-in skips, and zero failures. Every selected coverage threshold passed; `CSVExporter.swift`
was lowest at 87.60% against the 85% floor. The retained full result is
`/private/tmp/MindBudget-C6-01-Remediation-Full.xcresult`. Exact-head rereview, hosted CI, and merge
remain required. No product, remote, archive, upload, deployment, or App Store Connect change
occurred.

## 2026-08-29 — Close C6-01 after reviewed merge

Independent rereview approved exact PR #86 remediation head `f77d2a6`, confirming that all 33
declared type/method bindings are proved by exact Passed Test Cases and that repository check-script
discovery fails for either unclassified additions or missing reviewed classifications. GitHub
Actions run `33255898196` completed successfully on that exact head, and PR #86 merged it as
`015d00e`.

Marked only C6-01 Done and recorded DEC-COM-074. C6-02 remains blocked pending a separate explicit
owner entry. Its mandatory independent inspection of the checked-in privacy manifest, AddExpense
and Pro capture sites, `TelemetryService`, and telemetry operations runbook remains unperformed;
C6-01 automation does not satisfy it. C6-03, final-binary/IPA evidence, App Store Connect,
Staging/Production, G1, archive/upload, distribution, and release remain blocked or unauthorized.
This closeout changes documentation and its static contract only; it changes no Swift/runtime,
Worker, deployment, remote data, or customer state. CHANGELOG is unchanged because there is no
user-visible behavior change.

Validation: The first sandboxed `Scripts/validate.sh` attempt could not access CoreSimulator and
stopped before building; it is an environmental non-pass and is excluded from evidence. The
subsequent unrestricted run passed under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`)
iPhone 17 Pro simulator: every static contract, Release compilation, the strict serial 10,000-row
Dashboard benchmark, 553 unit tests in 32 suites, and all 17 UI tests passed. Four explicitly
opt-in physical CloudKit probes remained skipped by their accepted evidence policy. Every selected
coverage threshold passed; `CSVExporter.swift` was lowest at 87.60% against the 85% floor. The
retained local result bundle is `/private/tmp/MindBudget-C6-01-Closeout.xcresult`; it is an
execution artifact, not hosted, signed-device, final-binary, App Store Connect, or release evidence.

## 2026-08-29 — Bind C6 closeout authorization to exact sections

Author-side supplemental inspection of initial closeout head `4545e88` reproduced two
authorization-gate bypasses: summary prose could satisfy the C6-01 Done anchor after its formal
Status regressed, and the C6-02/C6-03 negative regex could not see a state placed on the Status
line below a heading. Replaced those status-prose controls with structural expectations in the
existing phase-state parser. The authoritative task map now must contain unique C6-01 Done/[x],
C6-02 Blocked/[B], and C6-03 Blocked/[B] sections.

The parser self-test mutates each of the three Status records and each task marker and requires all
six mutations to fail. No phase status changed: C6-01 remains Done, C6-02 still awaits a separate
owner entry, and C6-03 remains blocked. No Swift/runtime, Worker, deployment, remote, archive,
upload, App Store Connect, G1, distribution, or release action occurred. CHANGELOG remains
unchanged because there is no user-visible behavior change. Exact-head validation, rereview,
hosted CI, and merge remain required.

Validation: The structural parser self-test, bytecode compilation with its cache confined to
`/private/tmp`, all four standalone repository gates, the C6 matrix contract, Shell syntax, and
`git diff --check` passed. The exact remediated head then passed `Scripts/validate.sh` under Xcode
27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator: every static contract,
Release compilation, the strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32 suites,
and all 17 UI tests passed. Four accepted opt-in physical CloudKit probes remained skipped. Every
selected coverage threshold passed, with `CSVExporter.swift` lowest at 87.60% against the 85%
floor. The retained result bundle is
`/private/tmp/MindBudget-C6-01-Closeout-Remediation-Final.xcresult`; it is local execution evidence
only.
The first standalone `py_compile` attempt was denied only while trying to create the system user
cache directory; the explicit `/private/tmp` cache rerun passed and the environmental refusal is
not counted as a code failure.

## 2026-08-30 — Correct C6 gate-finding attribution

The first independent review of PR #87 found that the two authorization-gate bypasses had been
incorrectly attributed to “PR #87 review” even though remediation head `ba11fde` predated that
review. Corrected the persistent record: author-side supplemental inspection of initial closeout
head `4545e88` found the bypasses; the independent PR #87 review found this attribution mismatch.
No implementation, phase status, C6-01 Done evidence, C6-02/C6-03 authorization, or user-visible
behavior changed.

## 2026-08-30 — Enter C6-02 source/privacy and signed-device preflight

The owner explicitly entered C6-02. The mandatory five-surface pass found that the closed
subscription action/outcome is Purchase History under Apple's App Privacy definition. Added that
conservative Analytics-only, unlinked, non-tracking declaration, an exact checked-in/embedded
manifest validator, a two-mode signed-app inspector, `C6_02_PREFLIGHT.md`, and DEC-COM-076.

Xcode 27.0 beta 6 built Release 0.9.8 (9), and the inspected development-signed app installed and
launched on an iPhone Air running iOS 26.6.1. Development APS plus `get-task-allow=true` is recorded
as signed-device evidence only; no Archive/IPA/distribution/final-traffic claim follows. Full local
validation passed Release, the strict Dashboard benchmark, 553 unit tests in 32 suites, 17/17 UI
tests, and all selected coverage gates. Four accepted physical CloudKit probes remained skipped.
C6-02 stays In Progress pending independent review and the manual signed-device checklist; C6-03
and every archive/upload/deployment/App Store Connect/G1/distribution/release action remain blocked
or unauthorized.

## 2026-08-30 — Derive required-reason declarations from production source

Closed the non-blocking P2 left by PR #88 review without advancing C6-02. Added a comment/string-
aware production-source scanner for Apple's five current required-reason API categories and
required exact equality with the checked-in privacy manifest. The scanner recognizes real Swift
string interpolation, rejects ambiguous `getattrlist*` use, and has negative self-tests for every
non-UserDefaults category, misleading comments/strings, raw-string termination, C `stat`, wrong
reasons, and extra manifest categories. The current production inventory remains only
UserDefaults/`@AppStorage` with reason `CA92.1`.

The gate is classified in the C6 matrix and runs through the ordinary telemetry/privacy contract.
The C6 matrix passed 285 selected tests in 16 suites and verified all 33 required bindings as
Passed. Full validation under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17
Pro simulator passed Release compilation, the strict Dashboard benchmark, 553 unit tests in 32
suites, 17/17 UI tests, and all selected coverage gates; four accepted physical CloudKit probes
remained skipped and `CSVExporter.swift` was lowest at 87.60%. One sandboxed validation attempt
could not access CoreSimulator and is recorded as an environmental non-pass; the unrestricted run
is the owning result. C6-02 remains In Progress pending independent review and the manual checklist.
C6-03, Archive/IPA, upload, App Store Connect, G1, distribution, and release remain blocked or
unauthorized.

## 2026-08-30 — Close PR #89 required-reason Swift overlay gaps

PR #89 independent review accepted the required-reason lexer and C6 wiring but reproduced a
fail-open inventory for Foundation Swift overlays. Added the reviewed file-timestamp spellings
`fileCreationDate` and `contentModificationDate`; added the four `URLResourceValues` capacity
properties plus `fileSystemFreeSize` and `fileSystemSize`; and added a separate undeclared-category
self-test for every spelling. UserDefaults reason `CA92.1` is now enforced whenever that category
is declared, including a multi-category manifest. Dynamic raw-value keys remain outside lexical
proof and are explicitly assigned to C6-03 distribution privacy-report and compiled-artifact
inspection.

The exact remediation passed the full C6 matrix with 285 tests in 16 suites and all 33 required
bindings verified as Passed. `Scripts/validate.sh` under Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 (`23F77`) iPhone 17 Pro simulator passed Release compilation, the strict serial 10,000-row
Dashboard benchmark, 553 unit tests in 32 suites, all 17 UI tests, and every selected coverage
threshold; four accepted opt-in physical CloudKit probes remained skipped and `CSVExporter.swift`
was lowest at 87.60%. C6-02 remains In Progress pending exact-head rereview, hosted CI, and the
manual checklist. C6-03 and all Archive/IPA, upload, App Store Connect, G1, distribution, and
release actions remain blocked or unauthorized.

## 2026-08-30 — Continue C6-02 after the reviewed required-reason merge

Independent rereview accepted exact PR #89 remediation head `6ffc6fa`; GitHub Actions run
`33287620965` completed successfully on that head, and PR #89 merged it as `72f016e`. Calibrated
the current task, memory, privacy, requirement, release-checklist, and C6 packet records without
marking C6-02 Done or entering C6-03.

The required-reason self-test and production App scan, commercialization-document gate, and
telemetry/privacy gate passed. The retained development-signed Release 0.9.8 (9) app again passed
the signed-device signature, entitlement, embedded-manifest, exact-host, and no-fixture inspector.
The first sandboxed signature check could not consult the signing trust state and returned
`CSSMERR_TP_NOT_TRUSTED`; the unrestricted rerun verified the app as valid on disk and satisfying
its designated requirement, so only the rerun is evidence. No physical device was available in
CoreDevice at continuation time; `拉沙的iPhone` remained paired but unavailable. The manual
StoreKit, localization/accessibility, receipt, Instruments/data-protection, and system-integration
items remain open. No archive, upload, deployment, App Store Connect write, tester assignment,
G1, distribution, or release action occurred.

## 2026-08-30 — Continue C6-02 physical evidence and remediate AX5 navigation

The owner reconnected `拉沙的iPhone` through iPhone Mirroring and completed a bounded physical
preflight on the installed development-signed Release 0.9.8 (9). Chinese and English live StoreKit
surfaces showed monthly `$1.99`, annual `$19.99`, the active seven-day trial and renewal date, an
already-entitled state, and Restore/Manage/Terms/Privacy controls. Airplane-mode cold launch kept
the verified local Pro/trial snapshot rather than describing the user as Free. Privacy, Product
Analytics, receipt, iCloud, and export copy were inspected; cancelling receipt review and Add
Expense left Today's spending at `$0.00` and the existing `$25.00` expense unchanged.

Physical AX5 with Increase Contrast and Reduce Motion exposed a real non-pass: the custom four-tab
bar consumed enough height to obscure Dashboard and pushed Pro content. DEC-COM-078 caps only that
persistent navigation chrome at Accessibility 1 while leaving page content uncapped. The existing
AX5 UI test now asserts a bounded height for all four tab controls. An unrestricted focused run
under Xcode 27.0 beta 6 on the iOS 26.5 iPhone 17 Pro simulator passed one test with zero failures
at `/private/tmp/C6-02-AX5-TabBar-retry.xcresult`; the first sandboxed CoreSimulator attempt is an
environmental non-pass. The remediated build has not yet been reinstalled physically. Actual
purchase/restore/error paths, receipt acquisition, the complete accessibility/appearance matrix,
Instruments/data protection, and system integrations remain open. No archive, upload, deployment,
App Store Connect write, tester assignment, G1, distribution, or release action occurred.

## 2026-08-30 — Stabilize the C6-02 AX5 regression and pass complete validation

The first complete validation after the persistent-tab-bar correction passed Release, the strict
serial 10,000-row Dashboard benchmark, and 553 unit tests, but retained three UI non-passes. A
focused rerun showed the language-switch and onboarding/manual-flow cases were transient and
reproduced only the Pro AX5 test's immediate selected-state assertion for Warm Botanical. Replaced
that synchronous assumption with a two-second predicate wait and kept every subsequent Pro,
purchase-control, terms, and privacy assertion unchanged.

The focused Pro AX5 rerun then passed one test with zero failures at
`/private/tmp/C6-02-Pro-AX5-Selection-Retry.xcresult`. The final complete validation under Xcode
27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator passed Release, the
strict benchmark, 553 tests in 32 unit suites, all 17 UI tests, and every selected coverage gate.
Four accepted opt-in physical CloudKit probes remained skipped; `CSVExporter.swift` was lowest at
87.60% against the 85% floor. C6-02 remains In Progress for physical reinstall and the other open
manual items. The exact-source C6 matrix also passed every static and Worker check, Release/test
build, 285 tests in 16 suites, and all 33 required method bindings. Its first sandboxed attempt
could not write Wrangler logs or bind its local test server and is retained as an environmental
non-pass; the unrestricted rerun owns the result. No archive, upload, deployment, App Store Connect
write, G1, distribution, or release action occurred.

## 2026-08-30 — Correct C6-02 AX5 evidence and interaction synchronization

PR #90 review found that the persistent-navigation regression asserted only chrome height and did
not prove selected-page content stayed uncapped. It also rejected describing the language and
onboarding/manual-flow failures as transient merely because a rerun passed. Author-side
investigation found that the old
`UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge` launch argument is not a UIKit raw
value and was ignored, so earlier simulator bundles are not AX5 evidence.

Replaced the content-size arguments with canonical AX1 `UICTContentSizeCategoryAccessibilityM`
and AX5 `UICTContentSizeCategoryAccessibilityXXXL`. Added a nonvisual identifier to the existing
dynamic Dashboard date and made the regression compare its AX1/AX5 heights while retaining the
four-tab reachability and 96-point chrome bound. Budget setup and Pro navigation now scroll under
true AX5 geometry. Language labels, Dashboard-tab selection, expense-category selection, and
appearance selection use bounded predicate waits instead of immediate post-interaction reads.

The focused true-AX5 content comparison and three-appearance Pro regression each passed 1/1. A
new full `Scripts/validate.sh` run under Xcode 27.0 beta 6 on the iOS 26.5 iPhone 17 Pro simulator
passed Release, the strict benchmark, 553 unit tests in 32 suites, all 17 UI tests, and all selected
coverage gates; `CSVExporter.swift` was lowest at 87.60%. C6-02 remains In Progress because the
remediated build has not been physically reinstalled and the other manual items remain open. No
archive, upload, deployment, App Store Connect write, G1, distribution, or release action occurred.
The exact-source C6 matrix also passed every static and Worker check, Release/test build, 285 tests
in 16 suites, and all 33 required method bindings exactly once as Passed.

## 2026-08-30 — Make AX5 Pro navigation depend on an unobscured hit point

Hosted Actions run `33312286576` on head `6908f6c` failed the Pro AX5 regression. An initial
bounded tap retry was not accepted as a mechanism: a two-iteration run passed repetition one and
failed repetition two. Result-bundle inspection showed that `settings.pro` could be reported
hittable while its frame midpoint remained behind the Settings navigation bar after returning
from Appearance, so synthesized taps did not navigate and later control checks cascaded.

The test now scrolls until the live row midpoint is below the live navigation-bar frame, asserts
that geometry, uses a bounded tap-to-destination handshake, and stops immediately if navigation
does not settle. The pre-fix diagnostic passed 1/2; the safe-hit-point version passed 2/2 across all
three appearances. A fresh complete `Scripts/validate.sh` run passed Release, the strict benchmark,
553 unit tests in 32 suites, all 17 UI tests, and all selected coverage gates. This is simulator
evidence only. Physical reinstall and the remaining C6-02 manual checks stay open, and C6-03 plus
all remote/release actions remain blocked. The exact-source C6 matrix also passed all static and
Worker checks, Release/test build, 285 tests in 16 suites, and all 33 required method bindings.

## 2026-08-31 — Close the bounded C6-02 physical AX5 reinstall item

Goal: Reinstall and physically re-evidence only the DEC-COM-078/079 AX5 and bilingual appearance
item on `拉沙的iPhone`, without using `Xiao li的 iPhone (2)`, broadening the result into full
accessibility evidence, or entering C6-03.

Actions: Ran canonical true-AX5 content and four English/Simplified Chinese light/dark Pro
variants. Added geometry-safe budget-field entry after physical hierarchy export showed a field
could report hittable while its midpoint remained under the navigation bar. A later exact physical
Pro/legal regression was green but its retained screenshots showed that the first legal push could
render an invisible system back indicator. Removed duplicate child scheme ownership and bound
navigation chrome to the Pro presentation boundary with `.toolbarColorScheme`. Required settled
back-button geometry and consumed one non-evidence compositor frame before each retained capture.
Updated the StoreKit presentation gate from the old three-owner contract to require one parent
content/navigation scheme owner and reject child legal-page overrides.

Result: The bilingual light/dark run passed 1/1 at
`/private/tmp/MindBudget-C6-02-Physical-AX5-Bilingual-Light-Dark-Lasha-Geometry.xcresult` with four
inspected captures. The final three-skin Pro/Terms/Privacy run passed 1/1 at
`/private/tmp/MindBudget-C6-02-Physical-AX5-ToolbarScheme-Retry-Lasha.xcresult`; all nine retained
screenshots showed a visible back indicator. Earlier visually wrong, device-lock, and certificate-
trust runs are non-passes. The owner stopped one later redundant combined run; it is not called a
pass and was not needed for the accepted bounded evidence. DEC-COM-081 records the boundary.
C6-02 remains In Progress for transaction-error, receipt acquisition, full VoiceOver/accessibility,
Instruments/data protection, and system integration. C6-03 and all archive/upload/deployment/App
Store Connect/G1/distribution/release actions remain blocked or unauthorized.

## 2026-08-31 — Complete local validation after the bounded physical AX5 remediation

Goal: Close the local test loop for DEC-COM-081 while respecting the owner's stop on further
physical testing and retaining C6-02/C6-03 release boundaries.

Actions: Inspected the first failed full validator rather than retrying it blindly. The result
bundle showed that the AX5 setup helper's full-screen swipe alternated the total-budget field across
the narrow lane between the navigation bar and keyboard. Changed the test helper to use the live
keyboard top as its lower bound and small form-local drags. Ran two focused iterations, every
required static gate, a fresh complete validator, and the exact-source C6 matrix. No additional
physical run occurred, and the excluded `Xiao li的 iPhone (2)` was not used.

Result: The focused test passed 2/2. The complete result at
`/private/tmp/MindBudget-C6-02-DEC-COM-081-Full-Validated.xcresult` contains 558 passed, 13
intentionally skipped, and zero failed tests, with all selected coverage thresholds green. The C6
matrix passed 285 tests in 16 suites and all 33 required bindings at
`/private/tmp/MindBudget-C6-02-DEC-COM-081-C6-Matrix-Final.xcresult`. The earlier failed full bundle
remains a non-pass. This adds simulator regression evidence only; C6-02 remains In Progress and
C6-03 plus all archive/upload/deployment/App Store Connect/G1/distribution/release actions remain
blocked or unauthorized.

## 2026-08-31 — Close PR #91's reviewed partial C6-02 merge evidence

Goal: Record the exact independent-review, hosted-CI, and merge chain for the bounded DEC-COM-081
increment without marking C6-02 Done or entering C6-03.

Actions: Fast-forwarded local `main` to PR #91 merge `4ddabcd`. Verified that independent review
accepted exact head `b3ed24d` with no P1/P2 findings, that GitHub Actions run `33362101536` passed
on that head, and that the merge commit's second parent is the reviewed head. Updated both memory
tracks, the C6 execution packet and preflight, requirements/privacy/egress records, decisions,
tasks, CI baseline, and the commercialization-document gate.

Result: DEC-COM-082 closes only the reviewed AX5/navigation implementation and local-regression
evidence. Transaction-error paths, receipt acquisition, the complete signed-phone VoiceOver and
accessibility matrix, Instruments/data protection, and system integration remain open. No new
physical run occurred. C6-02 remains In Progress; C6-03, Archive/IPA, upload, deployment, App Store
Connect mutation, tester assignment, G1, distribution, and release remain blocked or unauthorized.

## 2026-08-31 — Bound the remaining C6-02 checklist without repeating device work

The owner accepted a narrow disposition of the remaining C6-02 manual rows and explicitly stopped
redundant physical reruns. Added `C6_02_ACCEPTANCE_MATRIX.json` plus a fail-closed/self-testing
validator that binds 23 exact runtime methods to StoreKit transaction errors, receipt acquisition,
accessibility regression, and system integration. The validator rejects missing, skipped,
duplicate, or non-Passed results and preserves every archive/remote/G1/distribution/release block.

Read-only inspection used only `拉沙的iPhone`. The app container exposed its expected SwiftData
artifacts and data-protection policy attributes. A request to copy the real financial store off the
phone was rejected by the safety boundary; it was not retried or bypassed. `xctrace` saw the device
as Offline while `devicectl` remained connected and generated no trace. Therefore full VoiceOver,
Instruments, exact data-protection class, and physical notification/Siri/Spotlight/Face ID/share/
Delete All side effects remain explicit non-passes or final-candidate checks. DEC-COM-083 does not
call them Passed. C6-02 awaits exact-head review, hosted CI, and merge; C6-03 and all remote/release
actions remain blocked.

Fresh exact-source validation subsequently passed on Xcode 27.0 beta 6 with the iOS 26.5 iPhone 17
Pro simulator: Release, the strict Dashboard benchmark, 553 unit tests in 32 suites, 18 UI tests
with 17 passed and the physical-only case skipped, all selected coverage gates, and all 23 bounded
C6-02 runtime bindings. The C6 release matrix also passed 285 tests in 16 suites and all 33 matrix
bindings at `/private/tmp/MindBudget-C6-02-DEC-COM-083-C6-Matrix.xcresult`. These are deterministic
local execution results only and do not alter the recorded physical non-passes or release blocks.

## 2026-08-31 — Remediate PR #93's hosted Xcode 26.6 evidence reader

Actions run `33370429991` on head `9f69f1a` passed its tests and coverage but is a non-pass because
the new verifier requested Xcode 27 schema `0.4.0`, which hosted Xcode 26.6 does not recognize. The
run's uploaded Xcode 26.6 xcresult was downloaded read-only. DEC-COM-084 changes the C6-02 reader
to shared schema `0.3.0`, accepts the stable Xcode 26/27 test-case identifier shapes, and adds a
negative failed-then-passed retry test so CI retries cannot hide a failed first attempt.

The remediated checker verifies all 23 exact bindings once as Passed in both the downloaded hosted
artifact and the existing local Xcode 27 bundle. That local read is remediation evidence, not a
green hosted run. The new exact head still needs rereview, hosted CI, and merge; C6-03 and all
archive/remote/release actions remain blocked.

## 2026-08-31 — Remediate PR #93's second hosted result-reader failure

Actions run `33384223530` on exact head `bf83faf` is a second explicit non-pass. Hosted Xcode 26.6
rejected forced schema `0.3.0`, and the suite retained one pseudo-long-text first-attempt failure
followed by a retry pass. The failure frame showed `500` visibly present in the active field, so the
immediate accessibility-value predicate was stale rather than the input being lost.

DEC-COM-085 removes explicit schema selection, consumes the active toolchain-native result shape,
and inspects real `Repetition` children so required bindings cannot hide a failed attempt. The UI
helper now uses the bounded Dashboard transition as its end-to-end authority. Its two-iteration
focused run passed without retry at `/private/tmp/MindBudget-C6-02-Native-Schema-Focus2.xcresult`.
Both hosted runs remain non-passes. A new exact head still requires rereview, green hosted CI, and
merge; C6-02 remains In Progress and C6-03 plus all remote/release actions remain blocked.

A fresh complete local validator then passed Release, the strict Dashboard benchmark, 553 unit
tests, all 18 UI tests with 17 passed and one expected physical-only skip, every selected coverage
gate, and the 23/23 C6-02 runtime check. No UI test retried. The validator deleted its temporary
xcresult, so the printed path is an execution pointer; a new hosted Xcode 26.6 run remains required.

## 2026-08-31 — Remediate PR #93's hosted AX1 Save retry

Independent rereview accepted exact head `44c53a5` subject to green hosted CI. Actions run
`33391122019` is instead a third explicit non-pass: native Xcode 26.6 result parsing worked, then
the 23-binding gate correctly rejected one AX1 Save failure followed by a runner retry pass. The
failure hierarchy showed the valid `3000`/`2500`/`500` values and matching preview still in the
Form with the decimal keyboard focused, identifying a swallowed Save interaction rather than lost
or invalid money input.

DEC-COM-086 reuses the bounded Save-to-Dashboard activation handshake and normalizes direct
`Repetition` children as concrete attempts without double-counting the aggregate Test Case parent.
Exactly one concrete Passed attempt is accepted; Failed→Passed remains rejected. The focused test
passes 2/2 without test-runner retry at
`/private/tmp/MindBudget-C6-02-Save-Handshake-Focus2.xcresult`. A subsequent complete validator
passes Release, the strict Dashboard benchmark, 553 unit tests, all 18 UI tests with 17 passed and
one expected physical-only skip, every selected coverage threshold, and 23/23 C6-02 bindings; no
UI test retried. The validator removed its temporary result bundle, so both paths are execution
pointers rather than durable artifacts. All three hosted runs remain non-passes. A new exact head
still requires rereview, green hosted CI, and merge; C6-02 remains In Progress, C6-03 remains
blocked, and no remote/release action occurred.

## 2026-08-31 — Remediate PR #93's fourth hosted AX5 interaction non-pass

Independent review accepted exact head `c05860f` subject to green hosted CI. Actions run
`33398172181` is instead a fourth explicit non-pass. The workflow reached UI execution without a
schema-version failure, but the AX1/AX5 test failed in two concrete attempts. In one iteration,
Terms and Privacy retained working back buttons and the test subsequently tapped them successfully,
but the helper timed out
against a delayed navigation-container frame. In another repetition, valid budget fields remained
onscreen with the decimal keyboard covering Save even though XCTest reported the button hittable.

DEC-COM-087 removes the unstable container-frame dependency and requires the back-button midpoint
inside the App window. Budget setup now moves the Form by bounded drags until Save's entire frame is
below the navigation bar and above the keyboard before activation. The first local focused attempt
is retained as a non-pass because the new helper initially queried Save's frame before the control
existed. After adding that existence boundary, the exact test passed 2/2 without test-runner retry
at `/private/tmp/MindBudget-C6-02-Hosted-UI-Focus5.xcresult` under Xcode 27.0 beta 6 on the iOS 26.5
iPhone 17 Pro simulator. This path is a local execution pointer, not hosted or distribution
evidence. All four hosted runs remain non-passes. A new exact head requires independent rereview,
green hosted CI, and merge; C6-02 remains In Progress, C6-03 remains blocked, and no remote/release
action occurred.

The first complete-validator launch was an environmental non-pass before build/test execution: the
restricted environment could not connect to CoreSimulator and could not read the local signing
prefix. The identical unrestricted command then passed Release, the strict Dashboard benchmark,
all unit tests, all 18 UI tests with 17 passed and one expected physical-only skip, every selected
coverage threshold, and all 23 C6-02 runtime bindings. The 18-case UI summary proves no test-runner
retry was added. The validator deleted its temporary xcresult, so the printed path is an execution
pointer rather than a durable artifact.

## 2026-09-01 — Close C6-02 after PR #93's exact reviewed merge

Verified that independent final review approved exact PR #93 head `016dd33` with no P1/P2
findings, GitHub Actions run `33405016652` passed on that exact head, and PR #93 merged as
`c940e8e`. DEC-COM-088 closes C6-02 while preserving all four earlier hosted runs as non-passes,
the accepted unrun physical rows for C6-03/C12, and the two non-blocking final-review harness
notes. Updated both documentation tracks and the structural commercialization gate. No Swift
product change, physical test, Archive, IPA, upload, deployment, App Store Connect mutation,
tester assignment, G1 decision, distribution, release, or Active Requirement completion occurred;
C6-03 remains blocked pending explicit owner entry and separate Archive/upload authority.

Validation used Xcode 27.0 beta 6 (`27A5252f`). The no-`DEVELOPER_DIR` CommandLineTools attempt
and sandbox-denied CoreSimulator attempt are recorded as environmental non-passes. The identical
unrestricted validator passed Release, the strict Dashboard benchmark, 553 unit tests across 32
suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one
expected physical-only skip, selected coverage, and all 23 C6-02 runtime bindings. All four static
gates, Shell syntax, and `git diff --check` also passed; no UI test-runner retry occurred.

## 2026-09-01 — Enter C6-03 and prepare build 10 for reviewed TestFlight transport

The owner explicitly entered C6-03 and authorized one reviewed, green, merged `0.9.9 (10)` Archive
and TestFlight transport upload. DEC-COM-089 keeps the preparation and distribution gates
sequential: this branch may change the traceable build number, release notes, inspector expectation,
and durable evidence packet, but may not Archive or upload before independent review, hosted CI,
and merge to `main`. The authority ends at transport acceptance and excludes tester assignment,
external Beta App Review, App Store submission, Production/Staging service or CloudKit-schema
deployment, G1, distribution, and public release.

Prepared build 10 in both Debug and Release while raising the marketing version and newest in-app
release-note entry to `0.9.9`; reserved `1.0.0` for public launch; added matching dated
release/TestFlight notes; updated the signed-app and release-readiness checks; added
`C6_03_RELEASE_BASELINE.md`; and changed the structural COM gate so
C6-03 is exactly In Progress with its prior stages Done. No Swift product behavior, Archive, IPA,
upload, deployment, App Store Connect mutation, tester assignment, or release action occurred.

The owner then corrected the candidate marketing version from the initially prepared `0.9.8` to
`0.9.9` while retaining build 10. The earlier successful validator and C6 matrix were run before
that correction and are not exact `0.9.9 (10)` evidence. The first complete `0.9.9` validator is
also retained as a non-pass: the product and unit layers built, but one localization test and one UI
test still expected `0.9.8`. The remediation preserved `0.9.8` as historical release notes, added a
new localized `0.9.9` entry, and updated the current/history/future localization checks plus the UI
version assertion.

Fresh exact-candidate validation then used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone
17 Pro simulator. All static and Worker checks passed. `Scripts/validate.sh` passed Release, the
strict Dashboard benchmark, 553 unit tests across 32 suites with the four expected opt-in CloudKit
physical probes skipped, all 18 UI tests with 17 passed and one expected physical-only skip, every
selected coverage threshold, and all 23 C6-02 runtime bindings; no UI test-runner retry occurred.
The validator deleted its temporary xcresult, so its printed path was an execution pointer. The
fresh C6 release matrix passed 285 tests across 16 suites and all 33 required runtime bindings at
`/private/tmp/MindBudget-C6-03-0.9.9-Build10-Matrix-20260901.xcresult`; this path is a local execution
pointer rather than hosted or distribution evidence. The exact preparation head still requires
independent review, green hosted CI, and merge before any Archive.

## 2026-09-01 — Archive, inspect, and upload the reviewed C6-03 build-10 baseline

Independent review approved exact PR #95 head `11ab612`, GitHub Actions run `33488815168` passed,
and PR #95 merged it as `d5d0959`. Archived Release `0.9.9 (10)` from that exact `main` commit with
Xcode 27.0 beta 6 (`27A5252f`). The archive retained a development signature and is not used as
Distribution evidence.

The first App Store Connect export is an explicit non-pass: Xcode initially lacked a usable current
account, distribution certificate, and entitlement-compatible Store profile. No package was
accepted. After the owner restored the account, automatic export with
`manageAppVersionAndBuildNumber=false` produced a cloud-managed Apple Distribution IPA. The closed
Distribution inspector passed version/build, bundle/team, arm64/iPhone-only, Production APS,
Production CloudKit, `get-task-allow=false`, beta reporting, exact host vocabulary, the reviewed
privacy manifest, and absence of StoreKit/test/extension/framework payloads.

The owner explicitly authorized upload. App Store Connect accepted `0.9.9 (10)` for processing at
`2026-09-01 19:27:25 +0800` with delivery UUID
`1b358d3b-4544-4617-ab47-5be69addc7a8`. DEC-COM-090 stops at that transport boundary. No tester
assignment, external Beta review, App Store submission, privacy-form write, service/schema
deployment, final-binary Production traffic probe, G1, distribution, or public release occurred.
The documentation closeout still needs independent review, hosted CI, and merge.

PR #96 review found a multi-file OR weakness in the new execution-anchor gate and an auditability
problem where original DEC-COM-089 criteria had been rewritten while being checked. The repair
makes every execution anchor mandatory in each of three authoritative evidence files, restores the
original criteria, records the development-signed archive criterion as an explicit non-pass with
an exported-IPA deviation under DEC-COM-090, aligns the release checklist, reverts the unrelated
What-to-test wording change, and adds a mandatory build-number increment before any later upload.

Closeout validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
simulator. `Scripts/validate.sh` passed Release, the strict Dashboard benchmark, 553 unit tests
across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed
and one expected physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime
bindings; no UI test-runner retry occurred. The validator removed its temporary xcresult, so that
path is only an execution pointer. The separate C6 release matrix passed 285 tests across 16
suites and all 33 required bindings at
`/private/tmp/MindBudget-C6-03-Upload-Closeout-20260901.xcresult`; this local path is not hosted,
Archive, Distribution, App Store Connect, G1, or release evidence.

## 2026-09-01 — Close C6-03 and COM-C6 after PR #96

Verified the exact final product-delivery chain before changing current state: PR #96 final head
`3ed1357` passed GitHub Actions run `33508360536` and merged to `main` as `246e7c1`. Under
DEC-COM-091, C6-03 and COM-C6 are now Done. This records the reviewed Distribution inspection and
App Store Connect transport acceptance of `0.9.9 (10)`; it does not turn that transport event into
tester assignment, external Beta App Review, App Store version submission, App Privacy-form
acceptance, Production traffic, G1, distribution, or public-release evidence.

The next commercial phases were not entered. G1 still requires explicit owner entry, a frozen
observation window, and accepted real supplier quotes. COM-C6.5 remains blocked behind its
post-COM-C6 14-day no-P0/P1 gate and a separate owner entry, with `2026-09-15` as the earliest
possible entry date. Any later candidate must increment the build number beyond 10.

Validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator.
`Scripts/validate.sh` passed Release, the strict Dashboard benchmark, 553 unit tests across 32
suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one
expected physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime
bindings. The UI summary contains exactly 18 executions, so no test-runner retry occurred. The
validator deleted `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.XehnXC/MindBudget.xcresult`;
that path is an execution pointer, not a durable artifact. This documentation branch still needs
its own independent review, green hosted CI, and merge.

## 2026-09-01 — Rescope the next G1 task to quote-backed AI unit economics

The owner replaced G1's public-observation prerequisite with a narrower commercial analysis.
DEC-COM-092 keeps G1 unentered but makes its next packet responsible for dated real cloud-AI and
backend quotes, deterministic typical/P50 and peak/P95 all-in cost per successful use, and an
evaluation of a US$4.99 one-time local-Pro unlock with finite starter AI credits plus separately
purchased consumable usage cards.

Added `G1_UNIT_ECONOMICS_PACKET.md` with closed quote provenance, workload, cost, commission,
refund, retry/failover, backend, credit-ledger, deletion and recovery inputs. The packet must derive
at least three starter allocations and three card options, then return `PROCEED_TO_R2`,
`REVISE_OFFER`, or `INSUFFICIENT_QUOTE_EVIDENCE`. No quote was collected, no included count/card
price/provider/product was accepted, G1/COM-C7 were not entered, and the existing Monthly/Annual
TestFlight product behavior was not changed.

Exact-scope validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
simulator. `Scripts/validate.sh` passed Release, the strict Dashboard benchmark, 553 unit tests
across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed
and one expected physical-only skip, selected coverage, and all 23 C6-02 runtime bindings. No UI
test-runner retry occurred. The deleted temporary xcresult at
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.UjGKJy/MindBudget.xcresult`
is an execution pointer, not a durable artifact. Independent review, green hosted CI, and merge
remain required for the updated exact head.

## 2026-09-02 — Enter G1 and build the first quote-backed cost envelope

The owner explicitly entered G1. Retrieved dated official rate, limit, and data-control evidence
from OpenAI, Anthropic, Google, Cloudflare, and Apple; no credentials were configured and no remote
request, product creation, App Store Connect mutation, or runtime code change occurred.

Added `Scripts/g1_unit_economics.py` and expanded `G1_UNIT_ECONOMICS_PACKET.md` with deterministic
integer-micro-USD arithmetic. At the 1,000-success/month planning floor it reports US$0.011330
typical and US$0.033098 peak all-in cost. The downside US$4.99 scenario derives a maximum of 11
peak-envelope starter uses, yielding provisional 10 starter uses and 10/25/65-use cards at
US$0.99/US$1.99/US$4.99. Updated regional pricing, provider, requirement, task, decision, and memory
records under DEC-COM-093.

The planning token/failure profiles are not measured Eval distributions, account-level region/ZDR
and exact App Store proceeds remain unverified, and no independent review has accepted the offer.
The formal interim result is `INSUFFICIENT_QUOTE_EVIDENCE`; G1 remains In Progress and COM-C7
remains blocked. The first validation invocation used the host's default Command Line Tools and
stopped after all static gates passed because `xcodebuild` was unavailable; it is an environment
non-pass, not product evidence. The explicit Xcode 27.0 beta 6 (`27A5252f`) rerun on the iOS 26.5
iPhone 17 Pro simulator passed Release, the strict Dashboard benchmark, 553 unit tests across 32
suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one
expected physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime bindings.
The validator deleted its temporary xcresult, so the printed path is only an execution pointer.

## 2026-09-02 — Close the reviewed first G1 quote/planning evidence package

Independent review found no P1/P2 on exact PR #98 head `9226985`, manually reproduced the integer
micro-USD arithmetic and conservative rounding, and approved merge after hosted CI. GitHub Actions
run `33570570896` completed successfully on that exact head, and PR #98 merged to `main` as
`6e2d242`.

Recorded DEC-COM-094 and synchronized the G1 packet, phase/task state, requirements, project
memories, decisions, CI evidence, and commercialization gate. This closes only the first quote-
backed planning evidence package. G1 remains In Progress with `INSUFFICIENT_QUOTE_EVIDENCE`; the
fixed bilingual Eval, account-level provider evidence, exact App Store proceeds, final-decision
review, and owner outcome remain open. The review's low-volume breaker, explicit-self-test, and
30-day re-quote observations are named future obligations rather than silently closed P3 items.

Local closeout validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
simulator. `Scripts/validate.sh` passed Release, the strict Dashboard benchmark, 553 unit tests
across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed
and one expected physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime
bindings. The UI summary contains exactly 18 executions, so no test-runner retry occurred. The
validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.aBMHd9/MindBudget.xcresult`;
that path is an execution pointer, not a durable artifact.

No Swift/product behavior, provider credential, remote request, backend, Product ID, credit ledger,
App Store Connect state, or COM-C7 phase changed. This documentation closeout still requires its
own independent review, green hosted CI, and merge.

## 2026-09-02 — Accept the one-time Pro and sole-Luna policy while keeping G1 open

The owner resolved the remaining G1 policy questions. Recorded DEC-COM-095 and recalculated the
planning worksheet around sole OpenAI `gpt-5.6-luna`: US$0.011330 typical/P50 and US$0.018986
peak/P95 at 1,000 monthly successes. Accepted US$4.99 one-time Pro; an explicitly started 30-day
local Pro/on-device-AI trial with zero Luna credits; starter/card lots valid for one user-calendar
year; a one-credit commit only for a user-initiated valid structured result ultimately displayed;
>=50% conservative peak margin; refund without local-data deletion; ordinary-test-user denial;
isolated capped Apple App Review access; and a separately reviewable local-only release path.

Exact starter/card choices, Luna Eval/account no-training/ZDR/region/rate/billing evidence,
StoreKit price-point evidence, independent review, and owner `PROCEED_TO_R2` remain open under
`EVAL_AND_ACCOUNT_EVIDENCE_PENDING`. No Swift behavior, credential, remote request, backend,
Product ID, App Store Connect mutation, distribution, release, or COM-C7 entry occurred.

The worksheet passed normal and `python3 -O` self-tests plus its document cross-check. The first
full-validator invocation inherited Command Line Tools and stopped after the successful static
gates because no full `xcodebuild` was selected; the next Xcode 27.0 beta 6 (`27A5252f`) invocation
was restricted from CoreSimulator and local build state. Both are environmental non-passes. The
identical unrestricted validation on the iOS 26.5 iPhone 17 Pro simulator passed Release, the
strict Dashboard benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit
physical skips, all 18 UI tests with 17 passed and one expected physical-only skip, every selected
coverage threshold, and all 23 C6-02 runtime bindings. The UI summary contains exactly 18
executions, so no test-runner retry occurred. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.G71eft/MindBudget.xcresult`;
the path is an execution pointer rather than a durable artifact. Exact-head independent review,
hosted CI, and merge remain required.

## 2026-09-02 — Freeze the Luna Eval and exact offer while account admission fails closed

The owner directed G1 to finish the fixed Luna Eval, account privacy/region/rate proof, and exact
credit/card decision before opening a PR. Added DEC-COM-096, a 12-scenario/24-case bilingual Eval
dataset, and `Scripts/g1_luna_eval.py`. Dataset SHA-256 is
`d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014`; prompt/schema SHA-256 is
`1d3e1d874ef054e8a41038cea99154a47c484c21658218d4c58809e19820d40b`. The scorer rejects unknown
facts/actions, invented numbers, forbidden tone/diagnosis, language drift, invalid final output,
and retry overflow.

Accepted exactly 10 Luna starter credits after verified US$4.99 Pro purchase and three usage-card
tiers: 10 uses / US$0.99, 25 uses / US$1.99, and 65 uses / US$4.99. Their conservative peak margins
at the 1,000-success planning floor are 65.13%, 56.63%, and 55.03%; the starter allocation is
93.08%. A later server must stop new card sales and starter grants below 1,000 trailing-30-day
successful analyses or below 50% recomputed peak margin while honoring existing credits.

Public OpenAI evidence was separated from account evidence. No API key, organization ID, or
project ID was locally available; organization/project ZDR, sharing state, region, subprocessors,
rate tier, billing cap, and effective price remain missing. Browser account access was blocked by
the security boundary and was not bypassed. No Luna request ran. Formal results are
`OPENAI_ACCOUNT_NOT_ADMITTED`, `LIVE_LUNA_EVAL_NOT_RUN_NO_ADMITTED_ACCOUNT`, and
`ACCOUNT_ADMISSION_AND_LIVE_EVAL_BLOCKED`. No Swift behavior, credential, backend, Product ID,
ledger, App Store Connect state, COM-C7 entry, distribution, or release changed.

Normal and optimized (`python3 -O`) Eval self-tests passed, the runner emitted 24 request fixtures,
the Luna-only integer worksheet and document cross-check passed, and an explicit live-run attempt
failed before network access because account admission is false. The initial full-validator run
passed the static gates but the restricted sandbox could not access CoreSimulator/build state; it
is an environment non-pass. The identical unrestricted Xcode 27.0 beta 6 (`27A5252f`) run on the
iOS 26.5 iPhone 17 Pro simulator passed Release, the strict Dashboard benchmark, 553 unit tests
across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed
and one expected physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime
bindings. The UI summary contains exactly 18 executions, so no test-runner retry occurred. The
validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.hu81QC/MindBudget.xcresult`;
the path is an execution pointer rather than a durable artifact. Exact-head independent review,
hosted CI, and merge remain required.

## 2026-09-02 — Adopt standard controls for synthetic Luna Eval

The owner accepted DEC-COM-097 after configuring a dedicated Global OpenAI project. Dated account
observations establish a Luna-only allow-list, Usage Tier 1 limits of 500,000 TPM/500 RPM/5,000,000
TPD, a US$5 project soft spend limit/alert, Pay-as-you-go balance of US$18.72, and auto-reload off.
No account, project, payment, or credential identifier is stored in the repository.

Replaced ZDR as a synthetic-Eval prerequisite with an exact standard-controls contract:
`scope: synthetic_eval_only`, `productionAdmitted: false`, standard abuse-monitoring retention up
to 30 days, `store=false`, `background=false`, and explicit prompt-cache mode without breakpoints.
Production customer traffic remains separately blocked behind consent, data minimization,
processor/subprocessor, server credential, App Privacy, final-binary egress, and release gates.

The machine evidence remains fail closed because final Saved-state confirmation for voluntary
sharing/API call logging and the isolated service-account credential are still missing. No live
Luna request ran; `OPENAI_ACCOUNT_NOT_ADMITTED`,
`LIVE_LUNA_EVAL_NOT_RUN_NO_ADMITTED_ACCOUNT`, and
`ACCOUNT_ADMISSION_AND_LIVE_EVAL_BLOCKED` remain current. No Swift product behavior, StoreKit
product, backend, COM-C7 entry, App Store Connect state, distribution, or release changed.

## 2026-09-02 — Run the admitted fixed Luna Eval

The owner confirmed all voluntary-sharing choices and API call logging were Saved disabled, then
stored a dedicated project service-account key in macOS Keychain without exposing it to Git, chat,
screenshots, command arguments, or environment variables. DEC-COM-098 records synthetic-only
admission; `productionAdmitted` remains false.

Two live attempts remain explicit non-passes. The first produced 48 zero-token HTTP failures because
the runner collapsed HTTP details and retried terminal errors. The hardened second attempt stopped
after one request and identified `HTTP_400:invalid_json_schema:text.format.schema`. Removing only
provider-unsupported `minLength`, `maxLength`, and `uniqueItems` from the wire schema—while retaining
the same local checks—changed the prompt/schema hash to
`c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018`.

Attempt 3 passed all 24 cases on the first request with no retries or hard failures. Input tokens
were P50 296/P95 301, output tokens P50 128/P95 203, and latency P50 3,614/P95 5,389 milliseconds.
The implementation author read all 24 final outputs with no additional finding; independent review
is still pending. G1 remains In Progress under
`EVAL_PASS_PENDING_REVIEW_AND_STOREFRONT_EVIDENCE`; StoreKit price-point/Product-ID evidence,
hosted CI/merge, and owner `PROCEED_TO_R2` remain open. COM-C7 and all production/product paths stay
blocked.

The first full-validator invocation selected CommandLineTools, and the second referenced a stale
Downloads Xcode path; both are environment non-passes. The exact Xcode 27.0 beta 6 (`27A5252f`)
run from `/Applications/Xcode-27-beta-6.app` on the iOS 26.5 iPhone 17 Pro simulator then passed
Release, the strict Dashboard benchmark, 553 unit tests across 32 suites with four expected
physical CloudKit skips, 18 UI tests with 17 passed and one expected physical-only skip, every
selected coverage threshold, and all 23 C6-02 runtime bindings. The UI summary contains exactly 18
executions, so no test-runner retry occurred. The xcresult was deleted after validation; its path
is retained in the commercialization baseline only as an execution pointer. Hosted CI and merge
remain open.

## 2026-09-02 — Close the independently reviewed Luna Eval delivery

Independent review read all 24 final outputs and exact PR #100 head `323d8d7`, found no P1/P2,
and accepted the automated result. GitHub Actions run `33593253561` succeeded on that exact head,
and PR #100 merged it as `7a473d2`. DEC-COM-099 records the exact chain and advances only to
`EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`.

The closeout clarifies that ten starter credits are owner policy constrained by the envelope rather
than derived from the current 72-use ceiling. It also makes the deliberate conservatism change from
PR #98 visible: peak cost US$0.033098 to US$0.018986 and fulfillment budget US$0.372250 to
US$1.372250 after removing the local-Pro reserve, separate cloud holdback, and backup provider.
Four nonblocking P3 areas remain for later hardening or explicit re-review: number-word detection,
failed-attempt percentile treatment, fail-closed usage fields, and use of the retry constant plus
current-state prompt-hash hygiene.

Static money, egress, commercialization-document, and StoreKit catalog gates passed. A first full-
validator attempt in the restricted execution sandbox stopped before Xcode testing because
CoreSimulatorService was unavailable and remains a local environment non-pass. The unrestricted
Xcode 27.0 beta 6 (`27A5252f`) run on the iOS 26.5 iPhone 17 Pro simulator passed Release, the
strict Dashboard benchmark, 553 unit tests across 32 suites with four expected physical CloudKit
skips, 18 UI tests with 17 passed and one expected physical-only skip, all selected coverage
thresholds, and all 23 C6-02 runtime bindings. The UI summary contains exactly 18 executions, so no
test-runner retry occurred. The deleted xcresult path is retained only as an execution pointer in
the commercialization baseline.

PR #101 review found one P2: the closeout had removed the still-unfulfilled fixed bilingual
template/on-device/Luna comparison together with two evidence requirements that were genuinely
complete. The remediation restores that three-way comparative Eval as a `PROCEED_TO_R2`
prerequisite across current G1 surfaces and adds a DEC-COM-099 scope-preservation clause. It also
restores the historical DEC-COM-098 pointer paragraph verbatim and changes the review-object gate
to validate the P3 count by type/range instead of freezing the entire object. Exact-head rereview
and a new hosted run remain required.

G1 remains In Progress; StoreKit Product-ID/price-point evidence and owner `PROCEED_TO_R2` remain
open. `productionAdmitted` stays false and COM-C7 stays blocked. This documentation closeout itself
still requires exact-head independent review, hosted CI, and merge.

## 2026-09-02 — Prepare the G1 template/on-device/Luna comparison

Recorded DEC-COM-100 and added a test-only physical Foundation Models harness plus a fail-closed
three-arm validator/blind-review packet builder. It reuses the frozen 24-case bilingual dataset and
the already reviewed Luna transcript, so it makes no new OpenAI request. The shared Eval scheme
cannot archive or run the App, ordinary schemes do not enable it, and the runner accepts only
`拉沙的iPhone` while rejecting the previously excluded phone.

The harness passed a generic unsigned iOS test build with Xcode 27 beta 6. The authorized phone was
not available, so physical Apple output and independent blind review remain open. G1 remains In
Progress at `EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`; no downstream authority changed.

After the owner connected `拉沙的iPhone`, the selected physical test passed and emitted all 24
structured outputs. The normalized transcript, unfilled A/B/C scoring surface, and separately
sealed post-score sidecar are now durable, but no subjective cloud-value conclusion is
self-approved. Independent blind review remains open and no new Luna request occurred. PR #102
review found that the first scoring packet leaked source/error fields and aggregate classifications;
the remediation removes them from the scoring surface and makes duplicate candidate bodies
ineligible to establish incremental value.
The first remediated full-validator run built Release but failed the test build on a Swift 6 type-
inference error in the new all-cases diagnostic; replacing split string concatenation with one
interpolated string closed that local non-pass. The complete Xcode 27.0 beta 6 revalidation then
passed: 554 unit tests across 33 suites, 18 UI executions with 17 passed and one expected
physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime bindings. This
validates the remediation and evidence wiring only; the sealed comparison remains unreviewed, G1
remains In Progress, and no Luna or physical-device rerun occurred.

GitHub Actions run `33623886226` on original head `9f04cee` is retained separately as a hosted
non-pass: the AX5 multi-appearance case failed before passing under the configured retry, and the
C6-02 verifier correctly rejected the resulting Failed-then-Passed repetition history.

## 2026-09-02 — Close the reviewed three-way capture delivery without blind scoring

Independent review accepted PR #102 exact remediation head
`bb939d035ab11bd7845edd30363e19631f5fce1a`; GitHub Actions run `33628847476` passed on that exact
head; and PR #102 merged it as `225490286a544bdb6141d47546ba7666185756fd`, whose second parent is
the reviewed head. DEC-COM-101 closes only implementation, physical capture, sealed-artifact
remediation, CI, and merge delivery.

The review was not blind-value scoring: its reviewer had already read the Luna outputs and leaked
packet. A different independent reviewer who has not read the sidecar, Luna transcript, leaked
packet, mapping code, or diagnostics must complete only the exact blind JSON at SHA-256
`bcbf943ba7d6a1a9d18442efc38e760cc798c30e8674c8d877f9e0cb751ab2a5` before opening the sidecar.
Comparative value remains unjudged. G1 remains In Progress at
`EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`; production remains false and COM-C7 remains blocked.
This closeout branch still requires its own exact-head independent review, hosted CI, and merge.

The first full-validator attempt selected `/Library/Developer/CommandLineTools` and stopped before
Xcode execution because it is not a full Xcode developer directory. This is retained as a local
environment non-pass; revalidation explicitly selects the recorded Xcode 27 beta 6 toolchain.
The second restricted attempt reached Xcode but could not access CoreSimulatorService or the local
bundle-ID configuration, so it is also an environment non-pass; final validation must run outside
that restricted sandbox.

The identical unrestricted validation then exited 0 under Xcode 27.0 beta 6 (`27A5252f`) on the
iOS 26.5 iPhone 17 Pro simulator. Release compilation and the strict Dashboard benchmark passed;
554 unit tests across 33 suites passed with four expected physical CloudKit skips; the UI suite
executed exactly 18 tests with 17 passed, one expected physical-only skip, zero failures, and no
test-runner retry. Every selected core file remained above the 85% coverage floor and the C6-02
verifier confirmed all 23 exact runtime bindings. The validator removed its temporary xcresult
after success; its path is retained only as an execution pointer in the commercialization baseline.

## 2026-09-02 — Record the independent G1 three-way comparative non-pass

An eligible independent reviewer completed every field using only the frozen blind JSON at merge
`f73881f209054068520e3c736f9e312fe22869e8`; all 24 material-increment decisions were explicitly
false. The completed packet was validated and locked before unsealing as commit `cd579be`, with
SHA-256 `d2b9310f4471400825e666009f646a190d8ac2819f859c8e38d58ec05cbf040e`.

Only then was the original sealed sidecar opened. The deterministic result is `NON_PASS`: 16
preferences map to the deterministic template, two to Luna, and six are ties; zero cases
materially prefer Luna and no bilingual task qualifies. There is no second eligible blind score,
so inter-rater overlap is unavailable. DEC-COM-102 moves G1 to
`COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION` without admitting production or entering
COM-C7. StoreKit, breaker, and legal gates remain unfulfilled, but owner disposition of the Luna
credit offer is now the next decision. This branch still requires exact-head review, hosted CI,
and merge.

Validation retained two environment-only non-passes before the authoritative run: the first used
the now-absent `/Users/shaola/Downloads/软件/Xcode.app` developer path and stopped before tests;
the second used the correct Xcode under the restricted sandbox but could not reach
CoreSimulatorService or the local bundle-ID configuration. The identical unrestricted command
then exited 0 under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator:
Release and the strict Dashboard benchmark passed; 554 unit tests across 33 suites passed with
four expected physical CloudKit skips; exactly 18 UI tests executed with 17 passed, one expected
physical-only skip, zero failures, and no test-runner retry; every selected core file exceeded the
85% coverage floor; and all 23 C6-02 runtime bindings passed. The temporary xcresult was an
execution pointer and was removed after validation. This local pass does not approve the owner
decision, admit production, enter COM-C7, or replace this branch's hosted CI and review.

PR #104 independent review confirmed the two-commit score-lock/unseal ordering and reproduced the
`NON_PASS`, but found that three current-state surfaces still spoke as if blind review were pending.
The remediation updates the top-level active phase, the three-way packet header and delivery prose,
and the economics packet's delivery prose to distinguish historical pending state from current
DEC-COM-102 state. The gate now parses the top-level Current state section and exact packet headers
instead of preserving the superseded status through an anywhere-in-file anchor. G1 remains In
Progress at `COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION`; exact-head rereview, a new hosted
run, and merge remain required.

## 2026-09-03 — Close reviewed PR #104 comparative-result delivery without closing G1

PR #104 exact remediation head `2fb2b64afa5035a7a159a6b29a89243340f6e786` passed independent
rereview with no P1/P2 and no new P3, plus GitHub Actions run `33701018178`. PR #104 then merged as
`e4b54af7eb3c17f1fd59b3869f42448c6d4e1d23`; local topology verification confirms that its second
parent is the reviewed head. DEC-COM-103 closes only the score-lock, sidecar-unseal,
deterministic-result recording, current-state remediation, review, CI, and merge delivery.

The frozen evidence is unchanged: completed-review SHA-256
`d2b9310f4471400825e666009f646a190d8ac2819f859c8e38d58ec05cbf040e`, sidecar SHA-256
`d29fca8246df5641d876be19ea56a936edd975616d2b3101bc18cca9d7bff507`, result SHA-256
`bf6b7212cc2ad4139a8e8f9d3eb877a5926ccc53378094dbcb12595f51b6f9f4`, and deterministic
`NON_PASS`. G1 remains In Progress at `COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION`,
production remains false, and COM-C7 remains blocked. No new OpenAI request, physical-device run,
product code, StoreKit mutation, server breaker, legal approval, customer path, or owner offer
decision occurred. This closeout branch still requires its own exact-head independent review,
hosted CI, and merge.

Local validation: `Scripts/validate.sh` exited 0 under Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 iPhone 17 Pro simulator. Release and the strict Dashboard benchmark passed; 554 unit tests
across 33 suites passed with the expected Debug-only G1 physical Eval skip plus four expected
physical CloudKit skips; the UI suite executed exactly 18 tests with 17 passed, one expected
physical-only skip, zero failures, and no test-runner retry; all selected core files exceeded 85%
coverage; and all 23 C6-02 runtime bindings passed. The validator removed its temporary xcresult;
this is local closeout-branch evidence only and does not replace hosted CI or independent review.

## 2026-09-03 — Record the G1 owner deferral and local-Pro-only direction

The owner accepted DEC-COM-104 after the frozen comparative Eval returned `NON_PASS`. G1 remains
In Progress at `LUNA_CREDITS_DEFERRED_PENDING_REVIEW_AND_CLOSEOUT`; the owner outcome is
`DEFER_LUNA_CREDITS_KEEP_LOCAL_PRO` and grants no `PROCEED_TO_R2`. Luna starter credits, usage cards,
their StoreKit products, provider/backend implementation, and COM-C7 through COM-C11 are deferred;
the frozen evidence remains historical and production admission remains false.

The US$4.99 one-time local-Pro direction, explicitly started 30-day local trial, supported
on-device AI, and deterministic fallback remain eligible for a separately owner-entered local-only
COM-C12 release review. This record makes no product, App Store Connect, credential, provider,
backend, distribution, or release mutation. Local validation passed under Xcode 27.0 beta 6
(`27A5252f`): Release build, 554 unit tests across 33 suites, 18 UI tests with 17 passed and one
expected physical-only C6-02 skip, all selected coverage gates, and all 23 C6-02 runtime bindings
passed. The recording branch still requires exact-head independent review, hosted CI, and merge.

## 2026-09-03 — Remediate PR #106 local-only policy and C12 boundary findings

Independent review of PR #106 exact head `f528db73f267a70f433fa96c8ca1e1e6fa485f18`
found no P1, but raised two P2 findings: the current regional-pricing section still presented
deferred Luna-credit rules as current policy, and the blocked COM-C12 checklist still required
cloud-only work that DEC-COM-104 had deferred. GitHub Actions run `33714752713` passed on that
exact original head; it does not validate this remediation.

The remediation separates the active local-only launch policy from explicitly inactive historical
cloud-credit evidence and replaces broad historical keyword checks with section-scoped assertions.
COM-C12 now distinguishes four mandatory local-only release-review items from a cloud-only subset
that remains with deferred COM-C7 through COM-C11 and a future cloud-enabled C12. The economics
packet now distinguishes the owner outcome from the still-open review/merge/closeout process state,
and the privacy chronology no longer presents the pre-DEC-COM-102 checkpoint as current. No frozen
Eval evidence, Swift/product code, provider/account state, StoreKit/App Store Connect state, or
release authority changed. The new exact head requires independent rereview and its own hosted CI
before merge; G1 remains In Progress at
`LUNA_CREDITS_DEFERRED_PENDING_REVIEW_AND_CLOSEOUT` and COM-C7 remains deferred.

## 2026-09-03 — Close the reviewed G1 deferral record

PR #106 exact remediation head `961acc046fb8c32870fb44cbecfc832e51354780` passed independent
rereview with no P1/P2 and one retained P3 clarification that optional iCloud and first-party
telemetry belong to local-only C12 only when enabled in the final candidate. GitHub Actions run
`33724552517` succeeded on that exact head, and PR #106 merged as
`fdd511bd628e2b80bd24d1a7556e28cb82cfa58a`; local topology confirms the reviewed head is its
second parent. Earlier run `33714752713` proves only original head `f528db7`.

DEC-COM-105 closes the DEC-COM-104 disposition delivery and marks G1 Done at
`DEFER_LUNA_CREDITS_KEEP_LOCAL_PRO`. The result remains a deferral rather than comparative PASS or
`PROCEED_TO_R2`: the frozen `NON_PASS` and production-false boundary remain, Luna/cards and
COM-C7 through COM-C11 remain deferred, and local-only COM-C12 is eligible but unentered pending a
separate owner decision. The C12 wording now makes optional iCloud/telemetry conditional on the
final candidate and does not enable either. This closeout changes documentation and gates only and
still requires its own exact-head independent review, hosted CI, and merge.

Local validation: `Scripts/validate.sh` exited 0 under Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 iPhone 17 Pro simulator. Release build and the strict Dashboard benchmark passed; 554 unit
tests across 33 suites passed with the expected Debug-only physical skips; the UI suite executed
18 tests with 17 passed, one expected physical-only skip, zero failures, and no retry; every
selected core file exceeded the 85% coverage floor; and all 23 C6-02 runtime bindings passed. The
validator removed `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.XU2lSP/MindBudget.xcresult`
after success; that path is an execution pointer only and does not replace hosted CI or review.

## 2026-09-03 — Enter and plan FX-01 manual foreign-currency expenses

The owner authorized a new product phase after G1 closeout for travel expenses paid in a currency
different from the current budget/accounting currency. This change records the full task plan only;
it does not change Swift, SwiftData, entitlements, localization catalogs, sync envelopes, privacy
manifests, network policy, or release state.

`Docs/FX_01_MANUAL_CURRENCY_PLAN.md` locks the manual-only behavior: explicit currency/original
amount/rate entry, editable accounting result, save-time historical lock, original-first detail,
dual-amount CSV, no location or country inference, and offline operation with no provider. Existing
`Expense.amountMinorUnits`/`currencyCode` remain authoritative. Schema V7 is planned as an optional
one-to-one companion with positive reduced `Int64` rational rate data and deterministic bankers
rounding. Existing records gain no inferred metadata.

The plan also fixes the entitlement lifecycle: verified local Pro and its active 30-day trial may
create an FX expense; after access ends, existing FX records remain editable/exportable while new,
converted, or duplicated FX records are denied. Optional iCloud compatibility is enabled-path
work only and this phase does not enable sync. Automatic reference rates and every provider/domain
remain deferred to a separately owner-entered FX-02. FX-01 is In Progress at the planning gate;
implementation waits for independent review, exact-head hosted CI, and merge. COM-C12 remains
unentered and no release action is authorized.
