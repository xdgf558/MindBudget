# TEST_PLAN

## Framework and determinism

- Unit tests use Swift Testing (`import Testing`, `@Test`, and `#expect`).
- UI tests use XCUITest.
- The full automated suite must pass on a simulator without Apple Intelligence.
- Phase 0 smoke coverage launches the app with forced English and Simplified Chinese
  locales and asserts rendered labels, not only accessibility identifiers.
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
impact by bucket, category risk boundaries, no-plan behavior, and nonzero days remaining.

### DateBoundaryTests

Cover natural/custom cycles, day 31 clamping, leap day, 23/25-hour DST days,
recorded-time-zone late-night rules, contiguous lazy plan creation, immutable historical
settings, transition cycles, plan-identity isolation, and overlap rejection. Cooling-off
countdowns across DST are added with the Phase 4 state machine rather than inferred in
the Phase 2 cycle service.

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
allow-listed, and raw Ask questions never reach model input.

### CSVExporterTests

Cover header-only empty output, UTF-8 BOM, CSV escaping, integer-minor-unit amount
formatting, and round-trip parsing.

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
destination. The unit test verifies that the hosted app bundle resolves localized
bootstrap copy. UI tests force English and Simplified Chinese locales and verify both
the accessibility identifier and rendered label. These tests are replaced by
phase-specific coverage as implementation begins; tests are never disabled to make
a phase pass.

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
future-setting transition cycles, immutable history, plan overlap/identity rejection,
and currency formatting for fractional and zero-exponent currencies. Budget engines
receive only Sendable projections; all calendars, time zones, and reference dates are
explicit inputs.

## Continuous integration

GitHub Actions uses Xcode 26.6+ to run the floating-point source check, assert the app
target's deployment target is 17.0, dynamically create a compatible iOS 26 simulator,
and execute build plus tests. GitHub-hosted macOS images currently do not include an
iOS 17 runtime, so this is a deployment compatibility check rather than an iOS 17
runtime claim. Release smoke testing on a real iOS 17 device or simulator remains
required. Hosted CI permits one retry for a transient first-launch timeout on a newly
migrated simulator; assertion failures must fail both attempts and remain blocking.
