# Dashboard first-load performance investigation

Status: **HOTSPOT_IDENTIFIED_ORIGINAL_CAUSE_UNPROVEN — original non-pass open; no corrective acceptance.**

The owner separately authorized this investigation on 2026-09-08 after the default full
validator on clean `b9cebd158098207049f31f42184dbece2ccbd365` exited 65: the first-load
measurement was **883.249166 ms > unchanged 500 ms**. The original native bundle contains one
failed method/device/configuration execution, no Repetition or extra attempt. Subsequent
ordinary/FX stages did not run. Original full-log SHA-256:
`d853b81282168741ef0e643e96f4fdd9f79dc2b2b60baf42a1b3387a0a064d81`.
That failure remains non-pass regardless of the diagnostic results below.

## Scope and pre-registered first diagnostic

Use separate branch `codex/dashboard-first-load-investigation` from the frozen UI repair.
Do not modify that repair worktree or documentation-only PR #118. No production optimization,
threshold/fixture/interval change, test retry, unchanged-head acceptance rerun, publication,
phase completion, CloudKit/model call or release action is authorized by this investigation.

Read the benchmark, `DashboardViewModel.load`, DataActor projections and BudgetEngine before
instrumenting. Fixture generation is outside the timer. The measured path includes plan
coverage, cooling-off reconciliation, expense/wishlist projections, budget snapshot, pace and
published state. Keep the same 10,000 records, calendar, money and 500 ms assertion.

First diagnostic: temporary Debug-only buffered timestamps and process CPU counters around
these boundaries, with expense fetch separated from summary mapping and DataActor entry
separated from its caller. Print the trace only after the existing measured interval. Run
the original benchmark once serially with coverage-enabled Debug test artifacts, explicitly
as an instrumented diagnostic, not an acceptance rerun. Do not execute full validation.
Probe overhead and process-wide CPU attribution limit causal claims. No financial record
values, private APIs, method swizzling or synthetic delay/load are used. Preserve the patch,
logs and native outcome, then remove instrumentation before any deliverable candidate.

Current-machine observations are context, not evidence about the earlier failed interval:
four iOS simulators are booted, physical RAM is 16 GiB and swap used is about 12 GiB. These
facts alone do not establish contention as the cause. Do not stop unrelated apps/simulators.

PR #118 remains Draft; D remains In Progress with four open completion items; E and Insights
income/sharing remain unentered. All historical non-passes and UNPROVEN causes are retained.

## Diagnostic 1 observation and bounded follow-up protocol

The instrumented original benchmark ran once and reported 206.517541 ms, with one native
Passed execution on the original task-owned UUID, local Xcode 27 beta 6 / iOS 26.5. This is
not corrective acceptance: 883.249166 ms remains non-pass. Buffered boundaries locate
122.851 ms in expense fetch and 69.951 ms in summary mapping; snapshot/pace take 3.321 ms.
Process CPU is shared across threads and background app services, so it is not a per-stage
exclusive CPU profile. The trace does not explain the original failed interval.

Pre-register one additional, separately named diagnostic method, not another run of the
500 ms acceptance method: fresh synthetic stores of 1,000 then 10,000 records, each loaded
once cold and once warm. Verify both loads return the same configured snapshot/pace and
the same complete record sets. This tests cardinality/cache sensitivity; it does not change
the acceptance fixture (still defaults to 10,000), skip its ceiling or substitute a warm
load for first-load acceptance. The fixed order has code-cache/startup confounders and is
not a statistical distribution. No intentional system pressure or process termination.

## Recorded findings (not a performance fix)

Both diagnostic commands exited 0. Each native bundle has exactly one Passed method and one
device/configuration execution, no Repetition/extra attempt, on
`3D6221D5-39DF-4CD4-ADEE-472B4139F47B`, local Xcode 27 beta 6 / iOS 26.5. Diagnostic 2's
four pre-registered load calls are inside its separate cold/warm comparison method, not four
acceptance attempts or automatic retries. The original benchmark method was not selected there.
Cold/warm configured snapshots, pace and complete expense/wishlist sets matched; counts were
1,000 and 10,000 as specified.

| Observation | Full measured load (ms) | Expense fetch (ms) | Summary mapping (ms) | Budget snapshot + pace (ms) |
| --- | ---: | ---: | ---: | ---: |
| Diagnostic 1, original 10,000 cold | 206.517541 | 122.851 | 69.951 | 3.321 |
| Diagnostic 2, 1,000 cold | 22.732291 | 11.272 | 6.697 | 0.596 |
| Diagnostic 2, 1,000 warm | 18.471042 | 10.657 | 6.523 | 0.362 |
| Diagnostic 2, 10,000 cold | 182.934167 | 110.624 | 64.003 | 3.217 |
| Diagnostic 2, 10,000 warm | 185.523250 | 114.225 | 64.404 | 3.189 |

Full measured intervals above come from the fixture's unchanged `ContinuousClock` boundaries.
Stage values are differences between buffered marks, with microsecond truncation; their
slightly shorter load-enter-to-end totals are not substituted for the benchmark's exact value.

Expense fetch + mapping account for approximately **93–96%** of the observed 10,000-record
loads. Their roughly tenfold increase with tenfold cardinality is consistent with the source's
unfiltered full-table fetch/sort and per-record validation/projection. This small fixed-order
comparison is not a scaling guarantee or field-level profile. A second same-store load does
not remove that work; deliberately warming caches is neither a demonstrated solution nor an
acceptable replacement for first-load acceptance. Observed expense-actor dispatch is only
9–199 microseconds and budget computation is small; neither observation proves those paths
could not have stalled in the original failed interval.

**The original 883.249166 ms cause remains UNPROVEN.** There was no stage/CPU/resource sample
inside that interval. Current high swap use cannot establish historical memory pressure or
CPU scheduling as its cause. Diagnostic 1's process CPU exceeds wall time (294.289 vs about
206.515 ms), which is permitted for process-wide counters spanning concurrent threads and
must not be attributed entirely to one actor. The normal test host also starts existing app
services; StoreKit sandbox error 12 and public-configuration expiry messages are retained
console context, not newly proven causes. No service behavior or account setting was changed.

The investigation identifies the storage projection as the first area worth profiling or
optimizing if the owner authorizes a corrective change; it does not justify changing the
budget algorithm, bypassing persisted-data validation, truncating Dashboard/Ask consumers,
raising 500 ms, calling the failure transient, or accepting a later diagnostic green.

## Probe withdrawal and reproducibility

Removed every temporary probe and the additional diagnostic method using scoped patches.
`git diff --exit-code b9cebd1 -- MindBudget MindBudgetTests MindBudgetUITests Scripts` passes.
The final worktree contains only local documentation edits; no production fix, commit, push,
new PR, #118 edit, full validator rerun, hosted run or D/E advancement occurred. Diagnostic
build products are not acceptance artifacts and must not be reused with test-without-building.

The task-owned `dashboard-perf-evidence` directory retains both logs, native summary/tree/detail,
instrumentation patches, original failure metadata copies, before/after resource records,
source hashes and a reproducible explicit-failure analyzer. No original artifact was replaced.

- Analysis JSON SHA-256: `4a1cc2e3bdf6a3c8c2403333fece189f9f40c8444d3f4ef2912d0be9ae3841ae`.
- Analyzer SHA-256: `e7ab90e18c93bb18f3fbaaed33634c7139a372166d40f39988d4e08a600672c0`.
- Diagnostic 1 patch SHA-256: `d65030d607f1dbbc68c8474cd914445ee1c709164b5e133bd9d2b844e28f6d6c`.
- Diagnostic 2 patch SHA-256: `326035f31df62e34722ba6e19570b0c201e5388affbb10b282b230fc886fb36a`.

The original UI repair's failed complete validator still blocks acceptance. Source and evidence
from its own worktree, as well as all #118 non-passes, remain untouched. A performance repair
needs a distinct evidence-backed scope followed by complete exact-head validation and review.

Post-withdrawal verification passed the money, network, commercialization-doc and StoreKit
checks plus the normal FX static contract check and `git diff --check`. This did not rerun
the FX copied-file self-test battery or runtime suites. The analyzer also produces identical
JSON under normal Python and `python3 -O`; it uses explicit failure checks, not removable asserts.
