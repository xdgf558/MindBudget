# FX-01 Manual Foreign-Currency Expense Plan

Status: **FX-01 In Progress; FX-01A and FX-01B Done; B closeout pending review/CI/merge; FX-01C unentered.**

Owner authorization: 2026-09-03. This is a product phase outside the commercialization track. It
does not enter COM-C12, reopen G1, enable Luna, create a network route, or authorize distribution.

Planning-delivery evidence: independent rereview accepted exact remediation head
`0619d5ec59ab3dbea3e87412b16872b92c07d129` with no P1/P2 and one retained P3 summary-wording
observation; GitHub Actions run `33758966855` succeeded on that head; and PR #108 merged it as
`f2f57b45cb676d0dc5b08ceee109e50530a35707`, whose second parent is the reviewed head. This
evidence closes only the planning prerequisite and is not runtime or Schema V7 evidence.

Planning-closeout evidence: independent review accepted exact head
`8de85e61277f48914d2269701af00d86cf433f62` with no P1/P2/P3; GitHub Actions run
`33763718952` succeeded on that head in 40m10s; and PR #109 merged it as
`69050da62305e8df076772a5638528442341933b`, whose second parent is the reviewed head. The owner
then separately entered FX-01A. The resulting contract-gate delivery is closed below; this does
not complete the overall FX-01 product phase.

`Docs/FX_01_CONTRACT.json` is the machine-readable contract authority. The self-testing
`Scripts/check-fx01-contract.sh` validates its exact closed keys, the structurally scoped phase
status in this plan and `Docs/TASKS.md`, the frozen `Expense` stored-property inventory, the actual
`DataActor` accounting write anchors, whole-app floating-point/network exclusions, and the absence
of FX identifiers from the pre-existing exception files. The gate is run directly in hosted CI,
from `Scripts/validate.sh`, and from the closed C6 matrix inventory. Its success is static contract
evidence only; it is not conversion, migration, runtime, Schema V7, UI, or release evidence.

## FX-01A post-merge closeout

Status: **Owner merged with hosted non-pass retained; no independent rereview claimed.**

Owner-supplied off-platform independent rereview accepted PR #110 exact head
`4554d0e21c714e44d2e5dec91d6026ae3cf7a7bf` (`4554d0e`) with no P1/P2. Hosted run
`33823593637` succeeded on that head in 39m58s. PR #110 merged it on 2026-09-04 as
`9322e3bc8da59d5ea5b6d067d66fae879404b642` (`9322e3b`), whose second parent is that head.
This closes the FX-01A static contract-gate delivery only, not FX-01B or Schema V7.

The complete hosted bundle contains 572 unique cases: 558 Passed, 14 Skipped, 0 Failed.
All 572 test-detail records were read: 568 ordinary runs plus 13 argument runs explain all
581 concrete runs, with zero extra attempts and no Failed-to-Passed. UI was 17 Passed / 1
physical-only Skip / 0 Failed; all 23 C6-02 runtime bindings passed. These are regression results
for the merged head, not FX conversion/migration evidence or this closeout branch's own CI.
Run `33772144343` remains non-pass. It was cancelled at the 45-minute workflow timeout after
a real AX5 assertion failure and an automatic passing retry; neither the retry nor later green
evidence relabels that run.

`deliveryEvidence.acceptedRunFailedToPassedObserved: false` is scoped only to the adjacent
accepted `hostedRun` (`33823593637`). It does not describe `retainedNonPassRun` (`33772144343`),
which did contain Failed-to-Passed. The obsolete unscoped JSON key is rejected.

PR #111 closeout head `2539ed1` received conditional independent approval but run `33829310323`
failed twice: attempt 1 at the npm advisory endpoint; attempt 2 at a 30-second copied-CLI timeout.
Both remain non-pass. The authorized remediation delays exact-ID simulator boot until after
static checks and builds, adds named timeout/fault diagnostics and ordering regressions, and
retains all 67 CLI mutations and the 30-second deadline. Simulator-start contention is a risk
suggested by timing, not a proven root cause. The new head needs independent rereview and hosted
success at that checkpoint; the subsequent owner exception below did not satisfy those criteria.

The original entry prerequisite was review, hosted success, merge and separate owner entry.
PR #111 was instead merged under the explicit owner exception recorded below. The original
combined acceptance checkbox stays unchecked because hosted success and new-head rereview did not occur.

- [ ] Independently review, pass exact-head hosted CI, and merge this separate FX-01A closeout.
- [ ] Retain the C6 `migration-and-rollback` registry placement as a maintenance follow-up: the
  FX gate also has its own hosted/validate entry and remains FX-owned, not new C6 completion work.
- [ ] Retain the existing AX5 Back selector `navigationBars.buttons.element(boundBy: 0)` as
  maintenance debt; do not claim new physical evidence or change product behavior in this closeout.

The PR #110 self-tests mutate temporary copies of authoritative files, never the repository
originals. That closeout retained a pre-B obligation to extend the JSON and negative gate for
eight-place decimal normalization and the thirteenth iCloud companion contract. The separate
FX-01B entry below now implements and tests that obligation. FX-01C–E, FX-02, COM-C12, network
activation, Archive, distribution, and release remain unentered or unauthorized.

## User outcome

A person travelling may explicitly turn on foreign-currency entry for a new expense, choose an
ISO 4217 currency, and enter the amount paid in that currency. For a new row, MindBudget shows the
converted amount in the current Settings/accounting currency; an edit continues to use that row's
persisted `Expense.currencyCode`. The person may edit either the rate or the final accounting-
currency result before Save.

After Save, the original amount remains the primary amount on the expense detail and the locked
accounting amount appears as an approximate equivalent. Budget pressure, reminders, insights,
totals, search summaries, and reports use only the locked accounting amount. A later rate change
must never revalue history.

## Locked product contract

- FX-01 is manual expense entry only. It does not add foreign-currency income, budgets, wishlist
  values, receipt inference, recurring foreign expenses, Siri/App Intent foreign amounts, or an
  automatic rate provider. Those paths continue to create accounting-currency records only.
- Enabling foreign-currency entry is always an explicit form action. The app never asks for
  location, reads location, infers a country, or changes currency from locale, storefront, SIM,
  network, or device region.
- A missing network is irrelevant: the rate is entered locally and Save remains available. FX-01
  contains no `URLSession`, provider SDK, API key, remote configuration, or new allowed domain.
- The capability is part of local Pro and is available during the explicitly started 30-day local
  Pro trial. It uses the existing verified local-Pro entitlement authority and adds no StoreKit
  product or price.
- FX-01 consumes only the current immutable Pro-access snapshot. It does not start, persist,
  calculate, schedule, extend, or repair the 30-day trial clock; those remain owned by the existing
  Commerce lifecycle.
- When trial/Pro access ends, existing foreign-currency records remain viewable, editable,
  deletable, searchable, synchronizable through an already enabled optional iCloud path, and
  exportable. Only creating a new foreign-currency record, converting an ordinary record into a
  foreign-currency record, or duplicating one as a new foreign-currency record is denied.
- Editing an existing foreign-currency record remains allowed after access ends, including
  correcting its original amount, currency, rate, rate date, or locked accounting amount. This is
  record stewardship, not a new paid-feature grant.
- An FX-01 expense cannot also create a monthly recurring rule. Each future occurrence would need
  a separately chosen rate, so recurring foreign expenses remain deferred.

## Persistence contract — Schema V7

`Expense.amountMinorUnits` and `Expense.currencyCode` remain the sole authoritative saved
accounting amount and currency. Existing budget and insight consumers must continue to read those
fields without a foreign-currency branch.

Schema V7 adds an optional one-to-one `ExpenseForeignCurrencyMetadata` companion keyed by the
expense UUID rather than changing the frozen V1 `Expense` shape. Its persisted fields are:

- `expenseID: UUID`
- `originalAmountMinorUnits: Int64`
- `originalCurrencyCode: String`
- `rateNumerator: Int64`
- `rateDenominator: Int64`
- `rateDate: Date`
- `rateTimeZoneIdentifier: String`
- `rateSourceRaw: String`, initially closed to `manualRate` and `manualHomeAmountOverride`

`rateDate` represents the selected civil day as `Calendar.startOfDay(for:)` in the captured
`rateTimeZoneIdentifier`; date arithmetic must use that calendar/time zone and never a fixed
seconds-per-day constant.

The metadata is all-or-none. Original amount, numerator, and denominator must be positive; both
currency codes must be supported; original and accounting currencies must differ; the rate must
be reduced to a canonical positive fraction; the rate date/time-zone must be valid; and applying
the stored rate must reproduce the authoritative accounting minor units exactly under the locked
rounding rule. A partial, contradictory, overflowing, or unknown-source companion is unreadable
and must never enter budget arithmetic as a guessed value.

V1 through V6 stores migrate to V7 with no companion rows and no inferred foreign-currency facts.
Creation/update of an expense and its optional companion is one actor-owned transaction. Expense
deletion, Delete All, and any existing enabled-path sync tombstone cascade to the companion.

Accounting-currency selection is closed by operation type. A new expense snapshots the current
form `accountingCurrencyCode` supplied from Settings and validates it against the owning budget as
today. Editing an existing expense—including converting an ordinary row to FX while access is
allowed—uses only that row's persisted `Expense.currencyCode`. The edit flow must not read a newer
Settings currency for conversion, rewrite the row currency, or revalue the saved accounting
amount. A missing, unsupported, or budget-incompatible persisted currency fails closed.

## Exact conversion contract

The rate orientation is fixed and must be shown in the UI:

`1 original major unit = rateNumerator / rateDenominator accounting major units`

For original minor units `O`, original exponent scale `OS`, accounting exponent scale `AS`, and
rate `N/D`, the authoritative preview is:

`bankersRound(O × N × AS / (D × OS))`

Manual rate text has one canonical closure into `N/D`. Lexical input permits at most ten integer
digits and twelve fractional digits; the stored decimal precision is exactly eight fractional
places. Input uses the active locale's decimal separator and decimal digits only—no sign, grouping
separator, currency symbol, exponent, or surrounding text. The domain parser rejects a thirteenth
fractional digit, normalizes one through twelve entered fractional digits to eight places with
round-half-to-even, then removes the decimal separator and uses `100_000_000` as the initial
denominator. It rejects a zero or out-of-range normalized numerator and reduces by the greatest
common divisor. A rounding carry beyond ten integer digits is out of range, keeping the canonical
manual display valid under the same parser. Thus `7.1234` becomes `712340000/100000000`, then `35617/5000`,
independent of locale or typed trailing zeroes.

The converter is a pure, stateless, `Sendable` value type. It uses checked `Int64` inputs,
full-width integer operations, cross-cancellation where required, and deterministic round-half-to-
even. It must not use `Double` or `Float`; parsing display text may follow the existing exact
`Decimal` input boundary, but persisted rate and conversion arithmetic are integer rational.

If the person edits the final accounting amount, that amount becomes authoritative. The app
recomputes a reduced effective rate that reproduces it exactly and saves source
`manualHomeAmountOverride`; it must not preserve a contradictory displayed rate. Editing the rate
again restores source `manualRate` and recomputes the accounting preview. Zero, negative,
unsupported, non-finite, divide-by-zero, unrepresentable, and overflow results fail closed without
discarding the form.

A manually entered eight-place decimal rate is displayed as its canonical decimal with unnecessary
trailing zeroes removed. An exact effective override rate may be non-terminating in decimal; its
display is then explicitly approximate and rounded half-even to at most eight fractional places,
while the stored reduced fraction and locked accounting amount remain unchanged. Editing that
displayed rate creates a new eight-place-decimal `manualRate` value; display formatting must never
silently overwrite the saved fraction.

## Presentation and export contract

- The new-expense form provides an explicit toggle, ISO currency picker, original-amount entry,
  unambiguous rate direction, editable rate date, live accounting preview, and an explicit way to
  override the accounting result. Save shows both currency codes and never relies on a currency
  symbol alone.
- Expense detail leads with the original amount and shows localized “approximately” copy for the
  locked accounting amount, saved rate, date, and source. Ordinary expense detail is unchanged.
- Log rows, Dashboard, budgets, reminders, insights, Ask facts, and aggregate reports continue to
  use the accounting amount. No surface silently fetches or applies a newer rate.
- CSV keeps the existing `amount`, `amount_minor_units`, and `currency_code` columns as the
  accounting values. It appends `original_amount`, `original_amount_minor_units`,
  `original_currency_code`, `exchange_rate_numerator`, `exchange_rate_denominator`,
  `exchange_rate_date`, `exchange_rate_time_zone_identifier`, and `exchange_rate_source` in that
  order. `original_amount` uses the same locale-independent exact decimal convention as the
  existing `amount` column. `exchange_rate_date` uses the existing UTC ISO-8601 formatter with
  Internet date/time and fractional seconds; the adjacent IANA time-zone identifier preserves the
  selected civil-day context. Ordinary expense rows and every income row leave all eight appended
  FX fields empty. Formula neutralization, RFC 4180 escaping, UTF-8 BOM, disclosure, and in-memory
  sharing remain mandatory.
- All new English and Simplified Chinese copy follows `COPY_GUIDELINES.md`. VoiceOver reads the
  original amount, accounting approximation, and rate direction without ambiguity; AX5, dark
  appearance, validation errors, and keyboard flows remain usable.

## Existing-channel compatibility

- Optional iCloud remains Free, default-off, and is not enabled by FX-01. If it is already enabled,
  FX-01 adds `expenseForeignCurrencyMetadata` as the thirteenth closed `CloudSyncEntityType`,
  ordered immediately after its parent `.expense`. It uses a separate record name/encrypted
  envelope with exactly the complete companion fields; the existing `.expense` payload, key set,
  digest meaning, and envelope version must not change. `ICLOUD_SYNC_CONTRACT.md`, the allow-list,
  application order, parser, conflict/tombstone behavior, and exact 12-to-13 inventory gates change
  together. Parent absence remains pending and any partial/unknown tuple quarantines without
  overwriting the local accounting authority. Legacy-peer tests must prove an older 12-type client
  cannot reinterpret the companion as `.expense` or mutate/delete the authoritative expense.
- First-party telemetry remains independently default-off and its closed vocabulary receives no
  amount, currency, rate, date, country, trip, merchant, note, or FX-mode field.
- Siri, Spotlight, `NSUserActivity`, notifications, and on-device/cloud model contexts receive no
  new exact amount or rate. Existing amount-free/redacted contracts remain unchanged.
- Delete All and explicit CSV export disclosures must be updated for the V7 companion. No new App
  Privacy collected-data type, required-reason API, permission string, SDK, or network domain is
  justified by this local-only phase.

## Implementation checklist

### FX-01A — Entry and contract lock

Status: **Done — merged static contract-gate delivery only.**

- [x] Record the owner's product rules, local-Pro/trial boundary, manual-only scope, locked-history
  rule, Schema V7 direction, and FX-02 deferral in durable repository memory.
- [x] Obtain independent review, exact-head hosted CI, and merge for this planning package before
  changing Swift, the project file, a schema, a localization catalog, or a sync envelope. Exact
  head `0619d5e` passed run `33758966855` and PR #108 merged it as `f2f57b4`.
- [x] At implementation start, add a fail-closed FX-01 contract gate that protects the active
  phase, accounting-authority fields, manual-only/no-domain boundary, and no-`Double` rule without
  claiming runtime evidence from prose.

### FX-01B — Integer conversion and Schema V7

Status: **Done — reviewed, hosted-green, merged integer conversion and Schema V7 only.**

The implementation items below are accepted from PR #112's own reviewed, hosted-green merged
source. Its separate post-merge closeout still requires review/CI/merge before C can start.
See [FX-01B implementation evidence](FX_01B_IMPLEMENTATION_EVIDENCE.md) for scope, fixture coverage,
retained non-passes and final local/hosted validation; the static gate itself claims no runtime evidence.

- [x] Before FX-01B implementation, extend the JSON and negative gate for eight-place decimal
  normalization and the thirteenth iCloud companion contract, preserving the `.expense` payload
  and requiring `ICLOUD_SYNC_CONTRACT.md` to change with implementation.
- [x] Add the closed rate/source domain and pure integer-rational converter, with table tests for
  the twelve-digit lexical/eight-place stored decimal-to-reduced-fraction closure, display-only
  approximation, 0-, 2-, and 3-decimal currencies (including JPY, USD, and KWD), inverse-direction
  mistakes, reducible fractions, exact halves with even/odd quotients, limits, and every failure
  case.
- [x] Add the optional V7 companion and lightweight V6-to-V7 migration; prove real V1 through V6
  fixtures preserve every existing fact and gain no invented metadata.
- [x] Extend drafts, projections, `DataActor`, model counts, deletion, and edit flows so the
  expense/accounting amount and companion are validated and committed atomically. Prove new rows
  snapshot the current Settings/accounting currency while edits use only the row's persisted
  `Expense.currencyCode`, including after Settings changes.

### FX-01C — Pro entry, form, detail, and edit behavior

Status: **Blocked — unentered.**

- [ ] Add one exhaustive `PremiumFeature` case and route new-FX access through the central
  entitlement snapshot. Pro and active local trial allow creation; exact Free and expired access
  deny only new/conversion/duplication paths; ordinary expense entry remains Free. Consume the
  existing Pro snapshot only; do not add or mutate a trial-start clock or lifecycle.
- [ ] Add the manual foreign-currency form and deterministic preview/override state machine.
  Currency, amount, rate, rate date, source, and accounting result must survive validation errors
  without triggering a location or network path.
- [ ] Show the original amount first on detail and allow stewardship edits after entitlement loss.
  Prevent FX plus recurring-rule creation in this phase with truthful localized copy.
- [ ] Complete English/Simplified Chinese localization, VoiceOver order/value tests, AX5, keyboard,
  dark/light appearance, and ordinary-entry regression coverage.

### FX-01D — Consumers, CSV, optional sync, and privacy

Status: **Blocked — unentered.**

- [ ] Prove budget, reminder, insight, Ask, Dashboard, Log aggregation, category totals, and report
  results are byte-for-byte driven by the locked accounting amount and never revalue history.
- [ ] Append the exact FX columns to CSV while preserving all existing columns and protections;
  test the UTC fractional-seconds ISO-8601 rate date plus IANA time-zone column, blank FX columns
  for ordinary expenses and every income row, multiple exponents, overrides, localization
  independence, and disclosure.
- [ ] Extend the already enabled optional-iCloud path without enabling it: add the thirteenth
  `expenseForeignCurrencyMetadata` fact immediately after `.expense`, keep the existing `.expense`
  envelope and payload unchanged, update `ICLOUD_SYNC_CONTRACT.md` and the exact inventory/order
  gates, and prove atomic parent linkage, quarantine, conflict/replay/tombstone/delete semantics,
  legacy 12-type peer safety, and full disabled/offline failure behavior.
- [ ] Re-run privacy, telemetry, Siri, Spotlight, notification, Delete All, receipt, wishlist,
  recurring-rule, and App Intent boundaries. No new field may cross those surfaces by accident.

### FX-01E — Release evidence and closeout

Status: **Blocked — unentered.**

- [ ] Pass money, network, commercialization-document, StoreKit-catalog, full validation, migration,
  coverage, and dedicated FX negative gates on the exact review head.
- [ ] Complete independent source/privacy review, hosted CI, and merge without entering COM-C12 or
  authorizing Archive, upload, tester assignment, distribution, or release.
- [ ] Use a separate closeout change to record exact review head, hosted run, merge topology, and
  retained non-passes before marking FX-01 Done.

## Deferred FX-02

Automatic daily/historical reference rates are not part of FX-01. A future explicit owner entry
must select and review a provider, current/history semantics, cache and stale-rate behavior,
failure UX, deletion/privacy disclosure, App Privacy impact, and a closed network-egress domain.
Any automatic value must be labelled a reference rate, never a bank/card settlement rate. No
Frankfurter, ECB, or other provider URL is authorized by this plan.

## Exit gate

FX-01 may be marked Done only after every FX-01A through FX-01E item is complete on reviewed,
hosted-green, merged source and a separate closeout records the evidence. Completion changes only
the local product capability; COM-C12 and every release/distribution action remain separately
blocked until expressly entered.
## 2026-09-04 — FX-01B owner entry

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

PR #112 received owner-authorized independent agent review on `a24cfa1`, passed hosted run
`33841868078`, and merged as `2e49acd` with the reviewed head as second parent.
FX-01B is Done; FX-01 remains In Progress; FX-01C remains unentered.
The 14 skips remain non-pass. The complete evidence, synthetic-merge source-tree equality and
review scope are in `FX_01B_IMPLEMENTATION_EVIDENCE.md`; no new physical or provider run occurred.
The earlier B owner-entry section is a historical checkpoint, superseded by this closeout.
No C–E/FX-02/COM-C12 implementation, network activation, Archive or distribution is included.

- [ ] Independently review, pass exact-head hosted CI, and merge this separate FX-01B closeout before FX-01C entry.
