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
reference-date rejection outside the half-open cycle, nonzero days remaining, and exact
Today pace facts without view-layer arithmetic.

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
points must not accept `ExpenseDetail` or another raw-note-bearing projection. Ask input
must use an exhaustive per-intent fact enum rather than a generic string dictionary; tests
enumerate every case and assert its exact serialized fact-key set.

### CSVExporterTests

Cover header-only empty output, UTF-8 BOM, expense/income record discrimination, CSV escaping,
integer-minor-unit amount formatting, round-trip parsing, zero-exponent currencies, and
spreadsheet-formula neutralization for user-entered source, merchant, and note text.

### NotificationSchedulerTests

Cover no implicit authorization request, explicit authorized/denied results, one stable
identifier per cooling-off plan, replacement after quiet-hour changes, cross-midnight
deferral, precise removal after an outcome or wish deletion, delivered-event deduplication,
and cancellation of all app requests. Payload tests prove the scheduler has no amount/note
input and verify approved English/Simplified Chinese item-name review copy.

### Phase9SystemContextTests

Prove the onscreen capability requires product scope, conditional iOS 26/API support,
runtime availability, and the default-off Siri setting. Compile-time tests require all seven
redacted App Entities to conform to `IndexedEntity`; Spotlight documents must carry only those
typed amount-free projections. Entity-identifier tests cover the four supported single-subject
references. Notification tests prove a wishlist reference reaches the SDK adapter only when
the centralized conjunction is true and that the current no-public-API stub remains explicit.
Local-search tests prove each Ask intent receives only relevant authoritative SwiftData
projections and has no Spotlight numeric-fact input.

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
15. On a signed iOS 26 device with Siri enabled, open a wishlist detail and verify "remind me
    tomorrow about this" resolves the visible item without speaking its price or note.
16. Verify the custom navigation exposes only Today, Log, Insights, and Wishlist as tabs,
    while the center add control opens expense entry and Settings opens from Today.
17. Confirm there is no visible paid lock, quota, trial, paywall, StoreKit entry, or custom-rule
    purchase UI before the separate commercialization phase is implemented.
18. Confirm the localized corrupt-cooling-record count and explicit repair confirmation preserve
    every readable record and never run automatically.
19. Run pseudo-localization and long-text inspection across the redesigned screens, then capture
    the accepted AX5/VoiceOver order on a signed iPhone.
20. Before Archive, select and verify the owner's latest China-region Apple Developer team,
    final Bundle ID, distribution identity, agreements, and intended App Store Connect app.

21. Enable on-device enhancement in Simplified Chinese, ask for the remaining budget, and confirm
    the title, body, and action labels stay Chinese even if a model proposal drifts to English.
22. Open Settings > Budget, edit and save the current period amounts, and confirm the Dashboard
    refreshes without changing the cycle boundaries or creating a second overlapping plan.

## Coverage gates and stretch targets

The executable release gate is at least 85% line coverage for every deterministic core file
listed in `Scripts/check-coverage.sh`, matching the product specification. Higher numbers remain
review targets, not claims that defensive `preconditionFailure` or compiler-generated branches
can safely be executed.

| Module | Release gate | Stretch target |
|---|---:|---:|
| BudgetEngine | at least 85% | at least 95% |
| BudgetCycleCalculator / BudgetPlanFactory | at least 85% | at least 95% |
| SpendingPatternDetector | at least 85% | at least 95% |
| ReminderThrottle | at least 85% | at least 95% |
| AdviceSafetyValidator | at least 85% | at least 95% |
| PrivacyRedactor | at least 85% | 100% |
| Money | at least 85% | 100% |
| Other selected core services | at least 85% | increase when useful |
| Views | manual smoke coverage | UI automation where stable |

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
scope/risk/response projections. Current-budget update coverage proves that only the plan
containing the supplied reference date can change and that identity, half-open boundaries,
currency, category budgets, and the single-row count remain intact. Each `DataController` owns one `DataActor`; app test
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
receive a price or note. A corrupt cooling-off row is isolated: valid reminders still
schedule, the invalid row's stale identifier is cleared, and Settings exposes the integrity
warning rather than reporting an undifferentiated operation failure. A later scheduling
failure may coexist with that last-known integrity warning and must not erase it.

CSV tests define the exact stable unified-ledger header independently from the exporter and cover
expense/income row types, header-only empty data, UTF-8 BOM, RFC 4180 commas, quotes and embedded
newlines, exact two-/zero-exponent amount strings derived from `Int64` minor units, equal column
counts after parsing, and spreadsheet-formula neutralization. Income rows leave expense-only
attributes empty rather than manufacturing `false` or `manual` facts. The two Phase 12 allocation
columns append after every existing column so earlier positions do not move; release notes warn
saved spreadsheet/import templates about the extended header.
The settings UI exposes the in-memory ShareLink export and clearly discloses inclusion of
raw expense/income notes and optional source or merchant names.

Deletion tests populate all current Schema V4 model types, then prove the ordered notification
and Core Spotlight cleanup precedes verified all-zero local deletion and preference reset.
An injected failed postcondition withholds completion and preserves preferences even after
the delete call returns. A forced Spotlight failure leaves SwiftData and onboarding
preferences intact, names the failed stage, and never reports completion. UI coverage
confirms Export and Privacy controls are reachable;
manual release smoke testing still opens the shared CSV in both Numbers and Excel, validates
a real notification, and inspects destructive progress on a physical device.

## Phase 7 acceptance

Phase 7 tests classify all seven approved Ask intents in English and Simplified Chinese and
prove that unknown or out-of-scope questions never invoke a model. With enhancement disabled,
every supported intent still returns a complete two-to-four-action template; affordability
without an explicit amount/category asks for clarification and never invents a value.

Privacy coverage records generator input and proves the raw question is absent, aggregate
contexts expose no raw note, merchant-list, transaction-row, or cooling-timestamp fields,
and generator APIs accept only dedicated allow-listed value types. Ask facts are a closed
per-intent payload containing only typed money, counts, booleans, and category values;
template prose and arbitrary insight strings cannot enter the redactor. Safety tests reject
fabricated numbers, oversized copy, shame, diagnosis, financial advice, and purchase prohibitions
on Ask text while accepting localized forms of allowed numbers. Construction tests reject
duplicate, oversized, or missing-Continue app-owned Ask action sets before a redacted context
exists; reminder and summary tests retain generated-action allow-list coverage. English output
requested for a Simplified Chinese context
and predominantly English output containing only token Chinese words must fail validation and
return the complete Chinese template, while short currency codes remain allowed; rendered dynamic Ask actions must
show their localized labels rather than catalog keys. Capability tests prove user-disabled and
build-disabled states fail closed before runtime access. Generator failure, validation rejection,
and timeout
all return a nonempty template with distinct source metadata. Ask model proposals cannot replace
the deterministic allow-listed action set, and Debug diagnostics retain only the exact typed
validation reason rather than rejected generated content. Cycle summary tests distinguish an
unavailable budget denominator, positive usage below one percent, and configured exact zero;
positive spend is never narrated as zero percent, sub-one-percent context does not allow the digit
`1`, and a cycle-label hyphen cannot turn the localized month into a fabricated negative number.
With zero-valued cooling-off counts present in the general numeric allow-list, unavailable and
sub-one-percent contexts must still reject numeric percentages, while an exact 8-percent context
accepts `8%` and rejects `0%`. Ask contexts reject every numeric percentage even when a zero count
is allowed; reminder contexts accept only values from their explicit free-budget-impact and
category-budget percentage fields, and reject both unrelated counts and `daysOfBudgetConsumed` as
percentage authority. ASCII and full-width percent signs, before or after the number, share the
same binding.
Reminder and cycle-summary enhancement
tests use injected mock generators only; the real on-device model remains a supported-device
manual smoke requirement.

## Phase 8A acceptance

Phase 8A tests prove the centralized Siri and Spotlight gates require product scope,
framework/OS support, runtime availability, and their independent default-off user settings.
Siri-disabled services expose no entity data and perform no writes. The isolated amount
adapter preserves exact USD/JPY minor units and distinguishes negative values, excess
precision, unsupported currencies, and amounts beyond the storage-safety boundary; each
transport failure and the neutral unexpected-failure fallback must have English and Simplified
Chinese copy. The explicitly invoked, authenticated impact answer may contain its deterministic
exact flexible-budget result;
Siri strings lose control characters and stop at 40 characters. Identical expense requests
inside five seconds persist once, currency mismatch remains typed and non-persisting, wishlist
creation uses a 24-hour default with no invented private detail, and candidate names used for
budget impact remain ephemeral.

Entity/index coverage proves expense displays use budget-relative bands and that exact
amounts, raw notes, and merchant names are absent by default. Merchant tests prove local
aggregates include opted-out expenses while system exposure still requires the centralized
Spotlight gate, global consent, and an eligible normalized expense key. Disabling Spotlight
deletes the app domain; an injected index failure returns a visible failure result without
mutating SwiftData. One reconciliation test must exercise the production path and withhold a
merchant document independently for a disabled centralized capability, disabled global consent,
and missing eligible expense before proving that all three enabled gates emit it. Identifier-
routing tests reject foreign items and map recognized app
results to the intended local destination. App Intents metadata extraction must succeed in
the build; final Siri phrase resolution and Spotlight behavior remain physical-device release
smoke tests.

## Phase 9 acceptance

Phase 9 tests prove all seven amount-free entities satisfy `IndexedEntity`, the existing
Spotlight domain associates typed entities only at the iOS 26 layer, and no new exact amount,
note, merchant-consent bypass, or separately managed index is introduced. The onscreen gate
must fail closed for a disabled product flag, missing iOS/API support, unavailable runtime, or
disabled Siri setting. Dashboard, expense detail, and wishlist detail publish only app-owned
amount-free entity identifiers; list pages publish nothing without an explicit selection. The
three single-subject entity types must compile as `Transferable`, and their encoded
representation must have exactly version, entity-kind, and identifier keys with no name, date,
category, amount-band, exact-amount, or note field. Gate closure uses a nil activity element,
whose public SwiftUI contract advertises no activity.

Ask local retrieval must select facts only after deterministic intent classification and only
from authoritative SwiftData projections. Spotlight stays a navigation supplement and cannot
provide model numbers. Notification scheduling may carry a typed wishlist reference only
through the same gate; Xcode 26.6/iOS 26.5's missing public notification annotation remains a
tested no-op adapter rather than a private selector. Automated build/test covers the iOS 17
deployment target against the current SDK; real Siri onscreen resolution and any future list
or notification API require a signed physical-device release smoke test. That test must also
confirm same-device entity resolution without `NSUserActivityTypes`; add the exact owned types
only if the release SDK/device proves the declaration is required.

## UI/UX design interlude acceptance

The redesigned shell must expose four real tab destinations with a separate accessible add
action, retain every existing free feature, and keep deep links routed to app-owned screens.
Today pace values must come from deterministic `BudgetEngine` output. Manual entry must preserve
locale syntax and exact minor-unit conversion through the custom keypad, while the full-screen
pause surface retains two to four safe actions including Continue Purchase. English and
Simplified Chinese onboarding, Ask, expense, Insights, Wishlist/cooling-off, and Settings paths
remain covered by automated UI smoke tests. The built app must contain no visible commerce
surface or fake entitlement behavior; reserved Pro seams render nothing.

The Appearance and Skins page exposes exactly the three included `AppSkin` cases, marks the active
option as selected for assistive technologies, updates the global semantic palette without
touching financial state, and persists the choice across a store reload. Corrupt or future skin
raw values fall back to Warm Botanical without destroying the stored raw value. Delete All resets
the preference to Warm Botanical with the other local preferences. Simplified Chinese catalog
coverage proves that no user-facing value contains the English product name `MindBudget`.
When optional first-party telemetry is present, app-wide Delete All attempts its authenticated
remote deletion before erasing local financial data. A `.failed`, terminal endpoint-policy, or
unavailable telemetry result must still leave all local model counts at zero and reset preferences,
while publishing a distinct pending-remote state and retaining any proof for a separate retry.
Every `AppSkin` must resolve to an opaque portrait artwork asset at least 800 pixels wide and 1700
pixels tall. The release-readiness script validates all three asset-catalog mappings and dimensions.
Before each TestFlight replacement, visually inspect Today, Log, Add Expense, Insights, Wishlist, Ask, Settings, and
onboarding in all three skins, including AX5 and VoiceOver on a signed iPhone.

The navigation smoke path must observe Today as selected initially and Wishlist as selected after
activation, with English values `Tab 1 of 4` and `Tab 4 of 4`. The exhaustive tab declaration
must remain Today, Log, Insights, Wishlist; the custom navigation explicitly sorts the five
accessible controls as Today, Log, Add Expense, Insights, Wishlist. The custom tab group supplies
localized position values from that declaration, supports multiline labels without a fixed-height
clip, and keeps the center add action inside its layout bounds. The Today
pace track exposes a nonempty localized accessibility value containing the spent percentage and
cycle day position. UI identifiers describe the metric they expose; `dashboard.today.left` must
never reuse the former cycle-wide `dashboard.available` meaning. Engine tests explicitly
distinguish reconstructed start-of-day allowance from double subtraction and cover the last
in-cycle day. The Today `Add Expense` and Wishlist `Add Item` empty-state actions must each remain
at least 140 points wide and wider than twice their height, preventing localized labels from
collapsing into cramped square controls.

Settings smoke coverage must prove that Today reaches a first-level category directory and that
Export and Privacy remain directly discoverable there. The Simplified Chinese path opens the
Reminders second-level page, verifies that the tone value renders as `柔和`, and rejects the raw
`settings.reminders.tone.soft` key. Debug-only local fallback diagnostics must remain compiled out
of the generic Release build used for Archive and TestFlight. About must read the marketing version
from the built bundle, render `0.9.5` for the current marketing version, and expose the localized update summary
while keeping `0.9.4` and earlier notes collapsed as history.
The Budget destination must load the existing current plan into enabled amount fields, expose one
Save Budget action, and confirm a successful update without adding another plan.
Its amount section must show Income this month, Expected expenses, and Savings goal without a
manual fixed-expense field. Its disposable preview must use `BudgetEngine` exact-minor-unit
arithmetic to calculate monthly income plus only explicitly allocated extra income minus the
savings goal, clamped at zero with distinct zero, fully allocated, and overcommitted explanations.
The configured snapshot must enforce that same amount; for example, income 20,000, Expected
expenses 8,000, and savings 2,000 must preview and enforce 18,000. Expected expenses independently
drives pace and cycle-usage comparisons. New and automatically copied plans must store zero in the
legacy fixed-forecast field. A real Schema V3 store must pass through the lightweight Schema
V3-to-V4 migration with no invented authority row: old plans with income 8,000 / Expected expenses
6,000 and income 0 / Expected expenses 6,000 both keep Expected expenses as the current-cycle
funding base. Editing and saving one of those plans must preserve its missing-marker legacy
authority and Settings must preview that same result while explaining the next-cycle switch. A new
zero-income plan must stay at zero.
The next copied cycle must persist the income-based authority, write zero fixed forecast, and use
income-minus-savings. A nonzero value on an existing current plan must remain reserved through
Settings edits and retire only on that next cycle copy. An actual fixed entry consumes that
reservation first without changing availability; only
the amount above it is an additional deduction. For plans without that legacy reservation, actual
fixed and discretionary expense entries both reduce the current disposable amount, while savings
entries satisfy the savings reservation. The engine reconstructs
that calendar day's starting amount before division, so a discretionary entry reduces today's
display one for one. A fixed entry is already deducted from the cycle amount and is rebalanced
across the remaining days rather than being charged to today's reference a second time.
The visible amount must clamp at zero; exact overage remains available for a localized icon, text,
and VoiceOver notice, so red is never the only signal. If the cycle cannot provide even one minor
unit of daily allowance before any spending today, the zero must use the attention color and expose
a neutral localized explanation rather than appearing without context.
The expense form must expose every persisted expense category in one horizontally scrollable
selector, keep deterministic ordering, center the selected item, and announce its selected trait.
The Simplified Chinese Log filter must render `全部` / `支出` / `收入` for record type and
`固定` / `灵活` / `储蓄` for budget type. Runtime option types own stable localization keys;
neither `ledger.type.*` nor `bucket.*` may be visible in Debug, Release, or TestFlight builds.
The release-readiness gate must reject a version/build without matching dated changelog and
TestFlight-note sections.

The optional app lock defaults off. Enabling and disabling require successful owner
authentication. When enabled, cold launch, inactive/background transition, and return to active
must keep the content inaccessible until authentication succeeds; cancellation or failure stays
locked. Face ID availability is required before first enabling, while device-owner authentication
provides the system passcode recovery path if biometrics later change. Settings reset after full
data deletion must turn the preference off. A signed iPhone check must also confirm that the app
switcher snapshot shows only the opaque lock surface and that the localized Face ID usage purpose
appears before the first biometric request.

Cold-launch UI coverage uses a Debug-only hold argument to inspect the otherwise sub-second brand
layer deterministically. It must find the animation, the Simplified Chinese `花有数` name, and the
localized subtitle. The hold argument must compile to `false` in Release. The production animation
is decorative, absent from accessibility, and does not intercept input; VoiceOver can reach the
real prepared screen without waiting for it. Signed-device checks must confirm that a normal cold
launch finishes promptly, does not replay after foregrounding, and becomes fade-only when Reduce
Motion is enabled.

## Phase 10 acceptance

The standard suite always loads a configured Dashboard from 10,000 current-cycle expenses and
asserts the complete projection count. Its fixture spans multiple calendar dates, every expense
category, fixed and discretionary buckets, varied exact minor-unit amounts, and sixteen optional
merchant names; this is a Dashboard read/projection contract, not a merchant-rebuild benchmark.

The separate 500 ms wall-clock assertion is a local release-machine signal. Local
`Scripts/validate.sh` runs it by default. Hosted GitHub Actions sets
`MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1` and skips only that timing test because neighboring VM
load is not a reliable product-performance oracle; CI still runs the deterministic 10,000-row
contract, Release build, full remaining suite, and coverage gate. Instruments on the signed
release iPhone remains authoritative for launch, scrolling, persistence, and memory performance.

`Scripts/check-coverage.sh` must fail nonzero when the result bundle, app target, or any selected
core file is missing, or when any selected file is below 85%. `Scripts/validate.sh` invokes it
after coverage-enabled tests, and the CI workflow invokes `validate.sh`, so this is a hosted
blocking gate rather than a local-only report.

## Phase 11 acceptance

Schema migration coverage creates a real V1 persistent store, opens it through Schema V2, and
proves an existing expense remains intact while the new income table begins empty. Income tests
cover exact minor-unit create/edit/search/export/delete boundaries, keep raw notes out of the
summary projection, include income in verified Delete All, and prove income writes never rewrite
the configured monthly-income or spending-budget values. The unified CSV must discriminate
`expense` and `income` rows and neutralize formula-like source and note text.

Recent Insights tests use an injected calendar and prove the inclusive window is today through
29 days ago, while an entry 30 days ago is excluded. Exactly 30 daily totals must be returned even
for zero-spend days. A corrupt cooling-off projection test preloads an old cooling-success card,
then proves the exact expense total/count remains visible while the partial-data state is exposed,
the cycle narrative stays absent, and no stored insight card is reloaded. Wishlist tests fill all
five open slots, reject a sixth without a partial write, preserve an archived item's state when
reopening would exceed the limit, and allow a new item after a slot closes. The same typed limit
error must reach form and Siri presentation paths.

## Phase 12 acceptance

The app-language setting persists a closed, extensible value for Follow System, Simplified
Chinese, or English. Changing it updates the SwiftUI locale immediately and reruns app-owned
notification and Spotlight reconciliation in that locale; deterministic Ask/templates, currency
and date formatting, Log category search, and the export filename use the same selection. Unknown
future values fall back to Follow System without destroying their stored raw value, while Delete
All resets the setting to Follow System. Both catalogs contain every Phase 12 runtime and
release-note key. A UI test changes from English to Simplified Chinese without relaunching and
asserts the current navigation title, picker value, and parent Settings destination update in place.

Schema migration coverage creates a real Schema V2 store containing an income, opens it through
Schema V3, and proves every V2 fact remains intact while the new allocation is exactly zero. Income
allocation persists in a V3 companion model so the shipped V2 `Income` schema fingerprint remains
frozen. Actor tests reject negative, overflowing, or over-income allocations atomically. Budget
tests prove only the user-confirmed spending portion increases the containing cycle's deterministic
budget; savings allocation never increases spending permission, and edit/delete recomputes from
remaining authoritative entries. A nonzero spending allocation carries the target plan identifier;
actor tests reject a missing plan, mismatched currency, or income date outside that plan, and the
form identifies the exact target dates rather than describing every allocation as current-cycle.

The total savings goal stores one target and optional starting balance across cycles. Its progress
is the checked sum of that starting balance and explicit per-income savings allocations, while the
existing `BudgetPlan.savingGoalMinorUnits` remains a separate per-cycle reservation. CSV exports
both allocation values as exact minor units; Delete All verifies the allocation, savings-goal,
recurring-rule, and occurrence tables are empty before completion.

Monthly recurring tests use injected calendars and time zones. A day-31 rule generates on
February 28 or February 29 as appropriate and on April 30, repeated reconciliation is idempotent,
and a generated entry remains fixed/planned/recurring without becoming a second rule when edited.
Pausing prevents
generation, resuming starts after the new confirmation time without backfilling paused months,
and deleting a rule preserves ledger history. Moving a January rule anchor to a future date inside
February still generates that February occurrence, because the immutable source month is separate
from the editable anchor. A catch-up with more than 120 missing rows commits only the globally
oldest 120 in one atomic transaction, reports that more remain, and a later reconciliation resumes
without duplicates until the backlog is empty. Cover both one-rule and combined multi-rule
backlogs, stable chronological ordering, and final idempotency.
When another batch remains, Settings must expose the published progress state with localized,
non-error copy. Schedule enumeration returns each pending date together with its stable occurrence
key so reconciliation does not recompute it, and a rule whose known occurrences force more than
1,200 month probes must fail closed rather than leaving foreground reconciliation unbounded.

Settings observation tests prove both language and skin changes publish through
`SettingsStore.objectWillChange`, persist to the configured defaults suite, and can invalidate the
root locale/theme without an unrelated state change or relaunch. App startup passes the SwiftUI
environment calendar into the same reconciliation path used on foreground return.

## Post-upload update acceptance

Insights must fetch the cross-cycle `SavingsGoalSummary` independently from spending-pattern
projections and show its exact target, saved total, remaining amount, and integer completion
percentage. A goal-reading failure must not hide authoritative expense totals; a missing goal uses
a localized neutral empty state. Tests use a starting balance plus an explicit income-to-savings
allocation and prove the module reads the authoritative combined total without changing a
`BudgetPlan` reservation.

Every Foundation Models attempt must evaluate runtime support with the active app locale supplied
by Ask, reminder, cycle-summary, or Settings status. Tests capture that locale at the centralized
capability boundary and verify the system instruction names the exact identifier and explicitly
requires the matching language. The capability initializer and runtime check have no
`Locale.current` default, so any new production caller that omits the app locale fails to compile.
An unsupported selected language must remain a dedicated actionable state rather than a region
error. Test Simplified Chinese, Traditional Chinese script/region identifiers, and English. The
existing generated-language validator and template fallback remain mandatory even after the
stronger instruction.

Savings progress tests must prove that confirmed savings beyond the target render 100% with zero
remaining rather than a negative amount. The integer completion calculation must also remain exact
and non-overflowing for values at the `Int64` boundary.

## Continuous integration

GitHub Actions uses Xcode 26.6+ to run the floating-point source check, assert the app
target's deployment target is 17.0, dynamically create a compatible iOS 26 simulator,
and execute build plus tests. GitHub-hosted macOS images currently do not include an
iOS 17 runtime, so this is a deployment compatibility check rather than an iOS 17
runtime claim. Release smoke testing on a real iOS 17 device or simulator remains
required. Hosted CI permits one retry for a first-launch timeout on a newly
migrated simulator; any failed concrete attempt of a required C6-02 binding remains blocking even
when a later retry passes. The explicit
wall-clock benchmark exclusion above is independent from retry behavior and cannot skip another
correctness, localization, UI, or coverage assertion.

The FX-01A static gate runs as a dedicated hosted step and from `Scripts/validate.sh`. Its own
negative fixtures must reject a summary-prose status bypass, early FX-01B entry, changes to the
frozen `Expense` property inventory, new FX domains, floating-point FX arithmetic, automatic FX
network code, FX code hidden in a pre-existing source exception, unknown JSON keys, historical
revaluation, and runtime-evidence claims. A green result proves only that reviewed source and
configuration still satisfy the static contract; it does not prove conversion arithmetic,
Schema V7 migration, UI behavior, or release readiness.

PR #110 hosted run `33772144343` is a retained non-pass: it hit the workflow's 45-minute timeout
after an AX5 appearance assertion failed and its automatic retry passed. The app-side diagnostic
snapshot was already Selected; the test's two-second waiter interrupted the first cross-process
query before its reply. For the scoped remediation, both AX5 appearance flows must query the exact
skin button, retain the selected-state predicate with a five-second bound, and stop the flow on
failure before collecting later appearance evidence. Other selected-state waits keep their
two-second default. Run the focused simulator AX5 case and a fresh complete validator without
runner retry. The physical-only variant remains unrun unless separately authorized; changed test
code does not refresh prior device evidence. Do not treat the failed-then-passed hosted attempt,
an incomplete xcresult, or an increased timeout as a passing C6-02 runtime result.

## FX-01A post-merge closeout validation

PR #110's owner-supplied off-platform independent rereview accepted `4554d0e`; hosted run
`33823593637` passed, and merge `9322e3b` has that head as second parent. The hosted bundle's
572 unique cases were 558 Passed / 14 Skipped / 0 Failed; all 572 detail records explain 581
concrete runs (568 ordinary plus 13 parameter-argument runs), with zero extra attempts and no
Failed-to-Passed. All 23 C6-02 bindings passed; UI was 17 Passed / 1 physical-only Skip / 0 Failed.
Run `33772144343` remains non-pass. These are merged-head regression results, not FX arithmetic,
V7 migration, a new physical run, or this documentation closeout's hosted evidence.

That checkpoint required review, hosted success, merge and separate owner entry. PR #111 later
merged by explicit owner exception with hosted non-pass retained; the B owner-entry section
below supersedes the former unentered/pending status, not the historical failed results.

At that checkpoint the FX validator rejected missing/substituted per-file closeout anchors,
rollback/duplicate FX-01A Status and premature B–E entry. The B entry now pins B In Progress,
C–E Blocked, the completed pre-B contract task and the explicit merge exception.
Negative self-tests mutate temporary copies of the authoritative documents, JSON, and source;
they never change repository originals. Exercise the same validator through a child CLI with
nonzero exit for each new closeout mutation, and require the clean copied fixture to exit zero.
Keep the existing accounting, no-floating-point, no-network/location, and static-only evidence
tests. The C6 registry placement and AX5 Back-selector maintenance debts remain open in the plan.

PR #111 remediation retains the 67 real child-CLI negative mutations. A separate injected-process
self-test must reject timeouts on both valid and invalid fixtures, unexpected success, signal
termination, another nonzero status, a missing verdict, and stderr. Timeout diagnostics must name
the mutated file, section, replacement, and deadline; no retry or increased timeout is permitted.
Reject the obsolete `failedToPassedObserved` JSON key: `acceptedRunFailedToPassedObserved` refers
only to accepted run `33823593637`, not the retained failed-then-passed run.

`validation_order_self_test.py`, invoked by the FX self-test, executes the actual `validate.sh`
against command stubs in temporary copies. Check the exact order of every static gate, build
settings, Release build, build-for-testing, exact-ID simulator boot/readiness, tests, coverage,
and runtime acceptance. Exercise benchmark-on/off and the unchanged named-local-destination
path. Fail each of the 12 static checks, three build commands, and boot readiness in turn: no
later command may execute. Also reject an eager `simctl boot`/`bootstatus` in the workflow.
These are harness regressions, not simulator or hosted runtime evidence. PR #111 run `33829310323`
attempts 1 and 2 remain non-pass; only a fresh complete local run plus new-head independent review
and hosted success can validate the remediation.
## 2026-09-04 — FX-01B owner entry

Local final acceptance is in `FX_01B_IMPLEMENTATION_EVIDENCE.md`: complete run 5 has
575 Passed / 14 opt-in Skipped / 0 Failed, no Repetition nodes, and 17/17 exact FX runtime bindings.
The strict serial benchmark and core coverage gates passed. This does not substitute for
independent review or exact-head hosted CI, and does not enter FX-01C.

PR #111 head `33b8009` merged as `34ac3f3` (second parent `33b8009`) after the owner
explicitly requested direct merge despite run `33834027746` failing at the npm advisory endpoint.
Hosted failure is retained as non-pass, not a green result or independent rereview.
The older run `33829310323` attempts and run `33772144343` also remain non-pass.
FX-01B has a separate owner entry; FX-01C remains unentered.

B owns integer rational arithmetic, half-even normalization, Schema V7 and atomic local persistence.
The JSON now binds 10 integer / 12 input fractional / 8 stored decimal places and the future 13th
`expenseForeignCurrencyMetadata` encrypted fact. That wire implementation and coordinated
`ICLOUD_SYNC_CONTRACT.md` changes belong to FX-01D; the existing `.expense` payload stays frozen.
Until D, ordinary iCloud upload (including recovery/reupload) and FX writes must fail closed
against coexistence, rather than sending a parent without its companion. Cloud erasure is not
ordinary upload and must not block local recording. No new FX UI, Pro snapshot changes, trial clock, CSV, provider or release
entry is authorized. B remains In Progress pending implementation verification, independent
review, hosted CI and merge. The previous merge exception does not waive those B requirements.

## 2026-09-04 — FX-01B post-merge closeout

Historical preparation checkpoint; the completed task and C entry below record its resolution.

PR #112 received owner-authorized independent agent review on `a24cfa1`, passed hosted run
`33841868078`, and merged as `2e49acd` with the reviewed head as second parent.
FX-01B is Done; FX-01 remains In Progress; FX-01C remains unentered.
The 14 skips remain non-pass. Keep the exact source/hosted tree, full 589-case inventory,
598 concrete results and 17 exact FX runtime bindings distinct from this static record gate.
Require the B provenance/next-entry boundary independently in every named document section,
reject duplicate or substituted evidence keys, rolled-back B status/task markers, premature C–E
entry, missing/duplicated local status and a checked closeout task. Continue all existing
accounting/decimal/sync/no-floating-point/no-network mutations and subprocess/order fault tests.
Self-tests mutate temporary copies only. A green gate does not manufacture runtime proof.

- [x] Independently review, pass exact-head hosted CI, and merge this separate FX-01B closeout before FX-01C entry.

## 2026-09-04 — FX-01C owner entry after B closeout

Status: **FX-01C In Progress; implementation and independent acceptance pending; FX-01D unentered.**

PR #113 received owner-authorized independent agent review on `642eb50`, passed hosted run
`33847157685` attempt 2, and merged as `ebd5785` with the reviewed head as second parent.
The tested synthetic merge `acd8729` and reviewed/merged source share tree
`fef0a2eae85f3f6bb26601f43f7388690a2314ee`. All 589 hosted case details match the final local
inventory: 575 Passed / 14 Skipped, 584 concrete Passed / 14 concrete Skipped, 17 FX methods
exactly once Passed, zero extra attempts and no Failed-to-Passed in this accepted attempt.
The 14 skips remain non-pass. Hosted configuration permits retries; concrete details show none.
Strict performance acceptance is from the separate local serial bundle, not hosted wall-clock
waiver. Independent source and final hosted audits are publicly recorded at
[the final review](https://github.com/xdgf558/MindBudget/pull/113#issuecomment-5537555248).

The downloaded raw artifact ZIP matches GitHub's SHA-256
`6f9e58db993049663fa2fc3ee9e00981d68f646f2e9982c8d72ac1efe66d9cb8`.
Attempt 1 remains non-pass: npm's advisory endpoint timed out before Xcode ran. Earlier cancelled
runs `33845662761` and `33846284169`, and interrupted local full-1/full-2, remain non-pass.
No failing test was hidden by retry. Local full-3 and hosted attempt 2 are the accepted evidence.

The owner's previously explicit sequential B/C/D/E/FX-02 instruction now enters C separately,
after B's implementation and closeout requirements are satisfied; merge alone is not entry.
C owns the existing central Pro snapshot, manual form/preview/override, original-first detail,
stewardship edits and localized accessible UI. Creation, ordinary-to-FX conversion and duplication
need current Pro access; editing a persisted FX record remains available after access ends.
New records use current Settings currency; edits use only that row's persisted accounting currency.
No trial-start clock, CSV change, thirteenth sync fact, automatic rate, network enablement,
COM-C12, Archive, upload, physical rerun, distribution or release is authorized by C.
FX-01 remains In Progress; C requires its own review, hosted CI, merge and separate closeout.

## FX-01C candidate verification (not completion evidence)

`ForeignCurrencyFormTests` adds 15 unparameterized methods covering explicit currency selection,
8-place half-even rate normalization, exact override reopening, invalid-input retention, saved
date/zone, currency exponents, new/conversion/duplicate authority, expired stewardship, asynchronous
revocation, ordinary-mode restoration and nonmanual/recurring exclusions. The original 17 B
arithmetic/migration/persistence methods remain required. Complete validation must read all 32
from its own fresh ordinary-App bundle and their native per-test execution records.

The separate `MindBudget-FX-UI` scheme uses a Debug + simulator + dedicated-flag entry, in-memory
financial data and fixed Commerce fixtures. It must independently run both exact English/light
and Chinese/AX5/dark create/detail/expired-edit methods. Those methods skip under the ordinary
scheme; those skips are explicitly not substitutes for the dedicated run. The host's own bundle
must prove both executed once and passed, including actual per-test device/configuration records.
No StoreKit purchase, physical VoiceOver/device, network, CSV or iCloud protocol claim follows.
The ordinary complete suite, coverage and isolated local strict benchmark remain separate gates.

Host isolation has copied-source negatives for its three compile conditions, exclusion before
normal bootstrap construction, fixed grant/revoke behavior, preferences/financial-store isolation,
notification stub and default/test-only scheme separation. CLI probes reject the independently
reproduced aggregate-tree bypasses and hidden extra/failed detail runs. Runtime native schema is
not pinned to a local Xcode version; unknown execution shapes fail closed pending explicit review.

Pure native Runtime Warning leaves are diagnostics, not execution attempts: accept only the exact
`name`/`nodeType` key set with a nonempty name, require tree/detail multiset agreement, and report
each diagnostic once. Fake warning leaves carrying result/identity/children/extra keys fail. Run
13 exposed two layout warnings with no source location; keep them visible as unresolved diagnostics,
not repaired bugs or retries. Full validation still requires its own fresh ordinary and UI bundles.


## 2026-09-04 — Strict JSON and main TASKS negative coverage

PR #113's independent review of `2dff233` demonstrated that dictionary mutation cannot test raw
duplicate JSON keys and that plan validation cannot imply main TASKS validation. Parse all object
levels with duplicate-key rejection before constructing their dictionaries. Cover conflicting,
identical and escaped duplicate keys plus non-standard constants through real child CLI input.
Bind the full ordered main FX checklist text/states and test each of its 12 items for flipped
checkbox, deletion, duplication and substituted text, plus loss of the B converter's task marker.
The repaired gate rejects 258 copied-CLI mutations, retaining the existing seven process-fault
and 3/16 ordering tests. Temporary fixtures must return to the passing source after mutation.

Rereview of `cc4b7a0` required an additional canonical-syntax boundary: alternative CommonMark
task markers must fail, never disappear from the inventory. The shared checker now applies to
main TASKS, each A–E plan checklist, the historical A closeout and all seven B closeout sections.
Real CLI negatives cover `*`, `+`, one-space/four-space indentation, Tab, both numbered-list
markers, blockquote, uppercase/unknown status, and an extra inline checkbox. Final negative count
is 332; the earlier 258 result is a superseded checkpoint, not complete acceptance.

## FX-01C ordinary budget-focus regression

Run the ordinary English category-legend, English AX1/AX5 navigation and English pseudo-long cases
without test retries. Each budget field must enter the full unobscured lane; the keyboard and
target frames must settle between two explicit center taps before one targeted text entry. Exact
3000/2500/500 readbacks after leaving the last editor must pass before Save reaches Dashboard.
This does not infer keyboard focus from geometry: targeted typing remains allowed to fail.
Retain the public `hasFocus` probe failure and the withdrawn diagnostic-parser probe separately;
neither is acceptance of the supported implementation. No debug-description or private KVC
focus predicates remain, and no product accessibility trait/value is changed for test signaling.
This focused probe does not provide Chinese evidence. Complete validation still requires the
existing Chinese ordinary regressions and the separately compiled Chinese AX5 FX host.

The complete hosted caller must set ordinary retries to zero, with no alternative override.
`validation_order_self_test.py` rejects six mutations of that real workflow and rejects retry
or iteration flags in the actual validator's stubbed test invocations. Still inspect every native
ordinary method detail and retain all non-passes, including run `33892068800` despite its green
GitHub status. FX's 32 unit / two UI bindings and complete local/hosted regression gates are not
weakened by this remediation.

## FX-01C ordinary About-history regression

Retain the `221dcd9` complete-local non-pass: Settings history expanded but fixed five whole-app
swipes stopped in `0.9.2`, before the deep `0.9.1` heading entered the accessibility tree. The
focused remediation must exercise that same full Settings test once without XCTest retries.
Confirm `0.9.8` as the first expanded historical heading, then independently require `0.9.1`.
Scope gestures to the About CollectionView and require bounded position progress for each drag,
using an unambiguous release-heading identifier rather than a mutable index or repeated body label.
Success requires a nonempty complete target frame below navigation and inside the list; progress
alone is not success. Preserve the maximum 20 drags and fail on no progress. Retain a final screenshot.
This focused check cannot replace fresh complete local validation and new-head hosted acceptance.
