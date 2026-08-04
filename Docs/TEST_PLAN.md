# TEST_PLAN

## Framework and determinism

- Unit tests use Swift Testing (`import Testing`, `@Test`, and `#expect`).
- UI tests use XCUITest.
- The full automated suite must pass on a simulator without Apple Intelligence.
- UI smoke coverage launches the current onboarding flow with forced English and
  Simplified Chinese locales and asserts rendered labels, not only accessibility
  identifiers.
- Every rule/date test injects `now`, `Calendar`, and `TimeZone`; production-clock
  lookups such as `Date()` and `Calendar.current` are forbidden inside testable engines.

## Fixtures

`TestFixtures.swift` defines a fixed instant at 2026-07-24 00:00 UTC and
Gregorian calendars for UTC, Asia/Shanghai, and America/Los_Angeles. It also
provide new-user, three-month-history, end-of-cycle, overspent, and no-budget scenarios.

## Required automated suites

### MoneyTests

Cover minor-unit round trips, USD/JPY exponents, bankers rounding, currency-safe
addition, ratio scaling, canonical App Intents decimal transport, and exact
non-floating-point results. CI also statically rejects `Double`/`Float` in money
paths outside `AppIntents/IntentMoneyTransport.swift`. The repository enforces
this across the complete `MindBudget/` source tree with
`Scripts/check-no-floating-point-money.sh` in GitHub Actions.

### WishItemStateMachineTests

Cover allowed and illegal transitions. Deleting a linked expense clears only the
weak expense identifier and preserves the purchased status.

### BudgetEngineTests

Cover cycle totals, discretionary filtering, free budget, pending-fixed double-count
prevention, available-now and safe-daily values, negative remaining budget, purchase
impact by bucket, undefined ratio baselines, category risk boundaries, no-plan behavior,
reference-date rejection outside the half-open cycle, and nonzero days remaining.

### DateBoundaryTests

Cover natural/custom cycles, day 31 clamping, leap day, 23/25-hour DST days,
recorded-time-zone late-night rules, contiguous lazy plan creation, immutable historical
settings, independent confirmation for shortened transition and first complete-cycle
budgets, non-propagation of reduced transition amounts, the 120-plan atomic generation
limit, plan-identity isolation, and overlap rejection. Cooling-off countdowns across DST
are added with the Phase 4 state machine rather than inferred in the Phase 2 cycle service.

### SpendingPatternDetectorTests

Every large-purchase, late-night, repeated-stress, image-increase, impulse-cluster,
category-risk, cooling-off-success, and safe-to-proceed rule needs triggering,
non-triggering, and exact-boundary tests. Also test new-user suppression,
unconfigured budgets, custom thresholds, and repeated-run determinism.

### ReminderThrottleTests

Cover the first reminder, five-event interruption suppression, 24-hour duplicate
suppression, category threshold recrossing, three-ignore downgrade, daily cap,
quiet-hour deferral, minimal tone, informational severity, booked cooling-off
exceptions, disabled presentation with retained insight, and reset after action.

### ReminderEngineTests

Cover the 2–4 action contract with a continue option, highest-severity selection,
tone length limits, all-template banned-language scanning, AI fallback, and source metadata.

### AdviceSafetyValidatorTests

Reject excess length, Chinese/English banned phrases, missing continue actions,
unknown action identifiers, diagnostic language, financial advice, commands not to
buy, fabricated numbers, and invalid action counts. Accept valid localized numbers.

### PrivacyRedactorTests

Prove notes never enter any context, merchant lists and transaction rows are absent,
amounts are formatted strings, Siri strings are sanitized, context fields are
allow-listed, and raw Ask questions never reach model input. Redactor/generator entry
points must not accept `ExpenseDetail` or another raw-note-bearing projection.

### CSVExporterTests

Cover header-only empty output, UTF-8 BOM, CSV escaping, integer-minor-unit amount
formatting, round-trip parsing, zero-exponent currencies, and spreadsheet-formula
neutralization for user-entered text.

### NotificationSchedulerTests

Cover no implicit authorization request, explicit authorized/denied results, one stable
identifier per cooling-off plan, replacement after quiet-hour changes, cross-midnight
deferral, precise removal after an outcome or wish deletion, delivered-event deduplication,
and cancellation of all app requests. Payload tests prove the scheduler has no amount/note
input and verify approved English/Simplified Chinese item-name review copy.

### SpotlightIndexingServiceTests

Cover indexing/deletion, clearing the domain when disabled, amount buckets rather
than exact amounts, excluded notes, and nonblocking index failures. Merchant-name
tests must prove that local aggregates remain complete while indexing still requires
the centralized Spotlight gate, `indexMerchantNames`, and an eligible matching expense.

### AppIntentSmokeTests

Cover record creation and five-second deduplication, nonjudgmental budget impact,
non-persistence of candidate item names, 24-hour wishlist defaults, negative amount
rejection, accounting-currency confirmation, redacted displays, and Siri-disabled
suggested entities.

## Manual smoke tests before release

1. Complete onboarding, including accounting currency and cycle start day.
2. Create a budget; add, edit, and delete an expense.
3. Add emotion context and a wishlist item; start and complete a cooling-off period.
4. Export CSV and open it in Numbers and Excel.
5. Delete all data and verify every deletion stage.
6. Disable AI and verify all L0 behavior remains available.
7. Toggle Siri and Spotlight independently and verify index clearing.
8. Complete one expense flow with VoiceOver and inspect all screens at AX5 text size.
9. Inspect dark mode and English localization for residual hardcoded strings.
10. Validate Foundation Models on a supported, Apple-Intelligence-enabled device.
11. Validate the complete app on iOS 17.
12. Add five large expenses and confirm at most one interrupting reminder.
13. Attempt to change a populated store's currency and confirm export/delete guidance.
14. Ask about a candidate purchase without amount/category and confirm a fixed clarification.

## Coverage targets

| Module | Target |
|---|---:|
| BudgetEngine | at least 95% |
| BudgetCycleCalculator / BudgetPlanFactory | at least 95% |
| SpendingPatternDetector | at least 95% |
| ReminderThrottle | at least 95% |
| AdviceSafetyValidator | at least 95% |
| PrivacyRedactor | 100% |
| Money | 100% |
| Other services | at least 80% |
| Views | manual smoke coverage |

## Phase 0 acceptance

The app target must build, and all smoke tests must pass on the recorded simulator
destination. The initial bootstrap localization checks were replaced by Phase 3
onboarding localization and end-to-end coverage. Phase-specific tests replace obsolete
smoke assertions as implementation advances; tests are never disabled to make a phase
pass.

## Phase 1 acceptance

Phase 1 tests cover exact minor-unit conversion and bankers rounding, supported
currency exponents, the currency-neutral entry boundary, accounting-currency locking,
budget-cycle overlap rejection, category defaults, wishlist transition legality,
cross-midnight quiet hours, privacy-sensitive setting defaults, validated configuration
fallback, four deterministic sample scenarios, durable store reopening, atomic sample
replacement rollback, SwiftData cascade deletion, weak expense-link cleanup, merchant
aggregate maintenance, persisted currency/enum corruption errors, and reminder-event
scope/risk/response projections. Each `DataController` owns one `DataActor`; app test
assertions receive only Sendable value projections.

## Phase 2 acceptance

Phase 2 tests cover half-open cycle totals, every authoritative reservation formula,
overcommitted and unconfigured plans, exact purchase-impact ratios, all category-risk
levels, currency mismatches, checked overflow, natural and custom cycles, day-31 and leap-
year clamping, 23/25-hour DST days, recorded local hours, contiguous lazy plan generation,
future-setting transition confirmation, atomic generation limits, immutable history,
plan overlap/identity rejection, and currency formatting for zero-, two-, and three-digit
exponents without fixed ICU symbols. Budget engines receive only Sendable projections;
all calendars, time zones, and reference dates are explicit inputs.

## Phase 3 acceptance

Phase 3 tests cover locale digits and grouping, exact minor-unit precision, zero and
negative entry rejection, independent budget-draft amounts, selected-expense-date impact,
the dismissible reasonableness warning, explicit pending-transition context, manual create/
edit metadata, merchant aggregate rebuilds, atomic transition/first-regular persistence,
currency and identity rejection, and rollback when either transition draft is invalid.
Coverage-preview tests prove future date selection creates no stored plans. Projection
tests prove raw notes are available only through targeted detail and actor-contained search
boundaries. Error tests preserve accounting-currency mismatch, and precision tests distinguish
excess fraction digits from malformed input. UI tests force English and Simplified Chinese
onboarding copy and run an English end-to-end path through budget setup, Dashboard refresh,
quick expense entry, and the expense list. Edit/delete and VoiceOver/AX5 remain mandatory
manual smoke checks before release in addition to actor-level automated coverage.

## Phase 4 acceptance

Phase 4 tests cover optional emotion/reason persistence, exact English and Simplified
Chinese labels for the sensitive emotion tags, optional wishlist prices, targeted
raw-note details, validated wishlist edits, one-active-plan enforcement, expiry to
ready-to-review, another cooling-off round, neutral purchased/skipped outcomes, archive
cancellation, and cascade-safe deletion. Countdown tests use injected calendars and prove
that a 24-hour duration remains 24 elapsed hours across both DST transitions without
assuming a fixed-length calendar day. Tests also prove completion time survives a later
outcome, outcome and `outcomeRecordedAt` remain an atomic pair, requested English/Chinese
countdown locales are honored, and recoverable action errors remain typed. Wishlist
conversion tests atomically create one planned `wishlistConversion` expense and weak link,
and prove rollback on invalid input.
Budget-preview and Dashboard-projection tests use only deterministic engine facts. The UI
suite runs an English onboarding → wishlist → cooling-off path; physical-device VoiceOver,
AX5, and iOS 17 checks remain release-manual requirements.

## Phase 5 acceptance

Phase 5 tests exercise all eight approved rule families at their exact boundaries, including
unconfigured stress/impulse analysis, positive free-budget baselines, three-record late-hour
qualification, complete historical image baselines, category warning and 100-percent
severity, `outcomeRecordedAt` cycle attribution, and safe-buffer suppression whenever a
warning applies. Identical inputs must produce identical ordered drafts.

Throttle tests cover disabled presentation with retained analysis, scoped 24-hour duplicate
suppression, the category first-crossing exception, three consecutive dismiss/ignore
responses whose newest response is inside 14 days, acted-response reset, minimal/info
downgrades, daily interruption caps, conservative downgrade when a daily calendar interval
is unavailable, invalid-request diagnostics, notification authorization, and calendar-derived
quiet-hour deferral. Reminder tests require two to four
actions, always retain Continue Purchase, select the highest-severity match, obey tone length
limits, and fall back to local templates when optional enhanced wording is structurally
invalid. Configuration tests prove late-night window/count and safe-buffer ownership, keep
the image-analysis minimum independent from the large-purchase floor, and reject an entire
historical aggregate build on overflow instead of skipping a cycle. Persistence tests prove
deduplicated typed payloads, dismissal preservation, response updates on actual reminder
events, and that failed reminder creation/response logging cannot block expense saving. The
UI suite opens Insights after onboarding and
asserts the local summary, honest empty state, and fixed disclaimer. Notification delivery,
Foundation Models wording, VoiceOver/AX5, and iOS 17 runtime checks remain owned by later or
release-manual phases.

## Phase 6 acceptance

Phase 6 tests prove reconciliation never requests notification permission implicitly,
authorized cooling-off plans receive one persisted stable request identifier, and denied
permission clears pending/stored requests without undoing the local cooling-off period.
Calendar-injected coverage verifies 21:00–09:00 quiet hours move a 22:00 review to the next
09:00, delivered notifications produce at most one booked reminder-history event, and an
outcome removes the exact request. Notification copy is bilingual and structurally cannot
receive a price or note.

CSV tests cover the exact stable header, header-only empty data, UTF-8 BOM, RFC 4180 commas,
quotes and embedded newlines, exact two-/zero-exponent amount strings derived from `Int64`
minor units, equal column counts after parsing, and spreadsheet-formula neutralization.
The settings UI exposes the in-memory ShareLink export and clearly discloses inclusion of
raw expense notes.

Deletion tests populate all nine Schema V1 entity types, then prove the ordered notification
and Core Spotlight cleanup precedes complete local deletion and preference reset. A forced
Spotlight failure leaves SwiftData and onboarding preferences intact, names the failed stage,
and never reports completion. UI coverage confirms Export and Privacy controls are reachable;
manual release smoke testing still opens the shared CSV in both Numbers and Excel, validates
a real notification, and inspects destructive progress on a physical device.

## Continuous integration

GitHub Actions uses Xcode 26.6+ to run the floating-point source check, assert the app
target's deployment target is 17.0, dynamically create a compatible iOS 26 simulator,
and execute build plus tests. GitHub-hosted macOS images currently do not include an
iOS 17 runtime, so this is a deployment compatibility check rather than an iOS 17
runtime claim. Release smoke testing on a real iOS 17 device or simulator remains
required. Hosted CI permits one retry for a transient first-launch timeout on a newly
migrated simulator; assertion failures must fail both attempts and remain blocking.
