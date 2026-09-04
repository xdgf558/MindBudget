# FX-01B implementation evidence

Status: **Implementation candidate; final local validation passed; independent review,
exact-head hosted CI and merge pending.** FX-01 remains In Progress. FX-01C–E, FX-02 and COM-C12
remain unentered. This packet is not UI, automatic-rate, wire-protocol or release evidence.

## Source and scope

The owner separately entered B after PR #111 merged `33b8009` as `34ac3f3`. That merge explicitly
waived hosted success following run `33834027746`'s npm advisory endpoint failure. No green run
or new-head independent rereview is imputed to it; B must earn its own review/CI/merge evidence.

- `ForeignCurrencyRate` closes locale decimal text into a reduced positive Int64 fraction:
  ten integer / twelve fractional input digits, eight-place half-even normalization, then GCD.
  A carry outside ten integer digits rejects rather than producing an unparseable display.
- `ForeignCurrencyConverter` uses checked two-word intermediates and bounded integer quotient
  search. Every result is half-even rounded and checked against the existing Money limit.
  Original-major to accounting-major orientation includes both ISO exponent scales.
- Home-amount override computes an exact fraction; its approximate display never mutates it.
  `.manualRate` must remain exactly expressible by the closed decimal input; override provenance
  must match the exact effective rate, not merely round to the same home amount.
- V7 adds only `ExpenseForeignCurrencyMetadata`. No field is added to the frozen 19-field Expense.
  Accounting amounts/currencies remain authoritative; detail projections carry the companion but
  summary/aggregate/CSV/telemetry/AI payloads are not extended here.
- The existing form constructor selects Settings currency for new records and the saved row's
  currency for edits. No new FX controls or layout are added. A real form-submit regression verifies
  saving the existing FX tuple after Settings currency changes.
- `DataActor` preserves metadata through legacy-form edits, locks an existing FX row's accounting
  currency and commits parent/companion atomically. Invalid tuples fail closed; deletion remains
  possible. ModelCounts includes the companion (17 business/companion tables, 22 total V7 models).
- Until D implements the thirteenth encrypted fact, ordinary iCloud upload and FX cannot coexist,
  including the separate trust-boundary recovery/reupload entry. Cloud erasure's temporary enabled
  flag is not an upload authorization and does not block ordinary or FX local recording.
  Pending legacy parent upserts quarantine without changing FX; parent tombstones cascade.
  Existing twelve-type wire records and `.expense` payload remain unchanged.
- The recovery marker advances to V7. Known format-1 V5/V6 journals restore checksum-verified
  snapshots before a V7 attempt; unknown targets, invalid paths and corrupt backups still reject.

## Runtime proof matrix

Seventeen tests in `ForeignCurrencyTests.swift`, across three suites, cover:

| Surface | Concrete verification |
| --- | --- |
| Decimal input | en_US, zh_CN, de_DE and Arabic digits/separator; trailing zeroes; exact half ties; precision and carry rejection |
| Integer conversion | USD/CNY/JPY/KWD, both orientation and ISO exponent scaling, even/odd halves, large full-width products, overflow/underflow; 5,239 small integer oracle combinations |
| Override | 1/3 display versus saved exact fraction; all distinct pairs of 0/2/3-exponent currencies at the Money limit |
| Atomic persistence | create/edit/manual-to-override-to-manual, preserved dates/zones, wrong accounting currency, duplicate IDs and unsupported source/recurrence/Intent rejection |
| Downstream rollback | a malformed adjacent merchant-source row causes failure after parent and companion mutations; neither update nor insert partially survives |
| Invalid tuples | canonical fraction/source/date/zone/amount errors, unsupported currency, non-finite date, orphan; inventory and detail reject, delete/Delete All still succeed |
| Legacy stores | actual V1–V6 stores, every field of each seeded row compared across migration and two opens, zero invented FX companions |
| V7 and recovery | V7 disk reopen/delete/reopen, captured Buddhist calendar/zone; known V5/V6 interrupted journals versus unknown V8 |
| Legacy sync isolation | mutual-exclusion failures and recovery/reupload rejection are atomic; cloud erasure preserves local recording without staging upserts; pending upsert preserves FX, pending parent tombstone removes both rows |

The V6 fixture populates 13 model types (Expense, Merchant, Income, IncomeAllocation, SavingsGoal,
BudgetPlan, BudgetPlanSemantics, MerchantAccountingContext and all five transport-state models).
Earlier fixtures include the corresponding schema-available subset. This is not a claim that
every historical table is populated by this new fixture; existing migration/relationship/sync
suites remain part of full regression validation. It is not physical-device or iOS 17 evidence.

## Local runs and limitations

Use Xcode 27 beta 6, iOS 26.5 simulator `238FF288-C843-43CD-82CD-15536F107AE1`, never a physical
phone. Final execution is `Scripts/validate.sh` with `MINDBUDGET_RETRY_TESTS_ON_FAILURE=0` and a
new result bundle; the strict serial wall-clock benchmark is not waived.

Final-source acceptance on 2026-09-04:

| Evidence | Observed result |
| --- | --- |
| Focused run 6 | 17 Passed / 0 Skipped / 0 Failed; all three FX suites |
| Complete run 5 | `Scripts/validate.sh` exit 0; Release/Debug builds, strict serial benchmark, full tests, coverage and 23 existing C6 runtime bindings passed |
| Complete result tree | 575 Passed / 14 Skipped / 0 Failed across 589 Test Case nodes; zero Repetition nodes |
| Parameterized tests | Four aggregate Test Case parents contain 13 Passed Arguments; 584 concrete ordinary/argument passes, not 584 distinct methods |
| FX runtime binding check | Each of the 17 source-declared FX methods occurs exactly once as Passed in the complete bundle, with no skip or retry |
| New-source coverage | `ForeignCurrency.swift` 225/229 executable lines (98.25%); `ForeignCurrencyDataActor.swift` 51/52 (98.08%); observed values, not a new gate threshold |

Artifacts:

- `/private/tmp/mindbudget-fx01b-focused-6.xcresult` and `/private/tmp/mindbudget-fx01b-focused-6.log`.
- `/private/tmp/mindbudget-fx01b-full-5.xcresult` and `/private/tmp/mindbudget-fx01b-full-5.log`.

The frozen Swift/test/PBX/script/CI source inventory hash, unchanged before and after run 5, is
`86ad1082d0462a2234421b3bcfb412b2cbaa29c37447e296b4c08ccf92df1bc2`.
Reproduce from the repository root (includes tracked and new files, sorted before hashing):

```bash
git ls-files -z -co --exclude-standard -- \
  'MindBudget/**/*.swift' 'MindBudgetTests/*.swift' 'MindBudgetUITests/*.swift' \
  MindBudget.xcodeproj/project.pbxproj 'Scripts/*.py' 'Scripts/*.sh' .github/workflows/ci.yml \
  | LC_ALL=C sort -z | xargs -0 shasum -a 256 | shasum -a 256
```

The 14 skips remain non-pass: six opt-in StoreKit runtime catalog/purchase cases, two live
configuration/telemetry probes, four physical CloudKit probes, one physical on-device Eval and
one physical AX5 UI capture. None is an FX method. No physical, provider, live-cloud or StoreKit
transaction observation is claimed by this run. The strict benchmark runs separately; the full
bundle excludes its duplicate invocation. Hosted CI and independent review remain pending.

Earlier non-passes are retained in SESSION_LOG: compilation diagnostics, an incorrect half-tie
test expectation, missing Node in an explicit PATH, and deliberately cancelled intermediate
full runs after source changes. Completed full run 4 passed on its earlier source, before the final
recovery/erasure fix; it is intermediate regression evidence, not final-source acceptance.
Focused passes before the final changes are supporting
development evidence only. None replaces final-source validation or this branch's hosted CI.
