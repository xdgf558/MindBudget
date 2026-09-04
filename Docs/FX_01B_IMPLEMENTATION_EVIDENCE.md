# FX-01B implementation evidence

Status: **FX-01B delivery and separate closeout accepted; FX-01C entered separately.**

FX-01 remains In Progress. FX-01C is now entered; FX-01D–E, FX-02 and COM-C12
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
Reproduce from a checkout of reviewed head `a24cfa1`, not this later closeout's changed static
script (includes tracked and new files, sorted before hashing):

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
bundle excludes its duplicate invocation. This was local evidence at the implementation checkpoint;
subsequent independent review, hosted success and merge are recorded below.

Earlier non-passes are retained in SESSION_LOG: compilation diagnostics, an incorrect half-tie
test expectation, missing Node in an explicit PATH, and deliberately cancelled intermediate
full runs after source changes. Completed full run 4 passed on its earlier source, before the final
recovery/erasure fix; it is intermediate regression evidence, not final-source acceptance.
Focused passes before the final changes are supporting
development evidence only. None replaces final-source validation or this branch's hosted CI.

## 2026-09-04 — FX-01B post-merge closeout

Historical preparation checkpoint; the completed task and C entry below record its resolution.

PR #112 received owner-authorized independent agent review on `a24cfa1`, passed hosted run
`33841868078`, and merged as `2e49acd` with the reviewed head as second parent.
FX-01B is Done; FX-01 remains In Progress; FX-01C remains unentered.
The 14 skips remain non-pass. This new documentation/gate closeout has no Swift changes and
does not inherit the implementation run as its own hosted success.

| Provenance | Exact observation |
| --- | --- |
| Reviewed head | `a24cfa1f296defd1fb17f4a815bd8caa10039117`; no P1/P2/P3 product findings |
| Review attribution | Owner explicitly authorized a separate read-only agent, not the implementation author; this is not a human or second GitHub account's APPROVED review |
| Public review record | [Independent agent review summary](https://github.com/xdgf558/MindBudget/pull/112#issuecomment-5536380833) |
| Hosted run | [CI attempt 1](https://github.com/xdgf558/MindBudget/actions/runs/33841868078), success, job 36m6s, Xcode 26.6 / iOS 26.5 simulator |
| Actual Actions checkout | PR synthetic merge `ea6a17f91ccc50cd135537a22d47f15dc54c4d42`, parents base `34ac3f34dcfac5d5ee49a71b03fa83ef0193631f` and the reviewed head |
| Exact source equality | Synthetic merge, reviewed head and final merge all have tree `1ac571400f2241c2f987b2fdab2ea71e318cf9f4`; checked through GitHub commit metadata and local Git |
| Final merge | `2e49acdc62bef9aac89b12b4c483f3d12008f5ac`, 2026-09-04 06:32:31 UTC |
| Artifact | `MindBudget-xcresult-33841868078-1`, ID `9925915001`; GitHub-reported artifact digest `sha256:2388e4d9323129db7b0e6b2e566b224658a08f69c9f588b26c7dc8d5f0026e9c` (not a locally rehashed directory) |

Every one of the 589 native test-detail records was read by author and reviewer. The whole
case/parameter/status inventory matches accepted local full-5, including 575 Passed / 14 Skipped.
Four parameterized parents expand to 13 argument instances: 584 concrete Passed / 14 concrete
Skipped, zero extra attempts or failed attempts. All 17 source-declared FX methods occur once as
Passed; no Failed-to-Passed is accepted. The host's summary labels the retry-enabled configuration
"test repetitions", but its actual individual records contain no repeated attempt. UI remains
17 Passed / 1 physical-only Skipped; host core coverage and 23 C6 bindings passed.

The reviewer separately compiled the original Money/conversion source and checked 50,000
conversions, 10,000 overrides and 20,000 decimal inputs against a Python arbitrary-precision
oracle (seed `0xF001B`): 80,000 cases, zero mismatches. A native macOS SwiftData probe migrated
V1–V6 stores with five Expense rows each into V7 and reopened them without losing seeded fields
or inventing FX. That bounded probe is not iOS all-table, actor, recovery or physical proof;
the actual iOS full suite above supplies its own independently inspected evidence.

This closeout leaves the C6 registry placement, old AX5 Back selector, historical hosted failures,
14 opt-in non-passes and the B fixture population limits intact. No new device/provider/StoreKit
call occurred. C owns UI/Pro, D owns CSV and the thirteenth encrypted fact; this closes neither.
COM-C12, automatic rates, Archive, upload, distribution and release remain unauthorized.

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
