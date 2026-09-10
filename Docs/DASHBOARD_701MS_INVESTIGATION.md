# PR #123 — 701 ms first-load investigation

Status: INVESTIGATION_RECORDED; original cause UNPROVEN; no corrective acceptance.

Historical checkpoint: all source/no-repair statements below describe the investigation on
bedac7f, before the separately published optimization. Current delivery scope and validation
limits are in DASHBOARD_READ_MAP_OPTIMIZATION.md; this report is not a no-product-change claim
about that new PR.

Owner authorized investigation after the exact `bedac7fc3539da5dd18c7d8a682f6e200ab1c564`
default validator failed on 2026-09-09 at **701.230625 ms / unchanged 500 ms**, exit 65.
That run did not reach the ordinary complete suite or isolated FX host. Its failure remains
non-pass; neither hosted `34357148406` nor any diagnostic below replaces it.

## Confirmed source / original-evidence boundary

The original timer begins after in-memory container construction, fixture seeding/save and
DashboardViewModel initialization. It measures the actual load: plan coverage, cooling-off
reconciliation, expense/wishlist projection, budget snapshot/pace and state publication.
It does not include generating the 10,000 expenses, although startup/seed can influence later
cache/resource conditions. The native original method has one failed concrete execution and
no Repetition; `hasPerformanceMetrics` is false and there are no stage/CPU samples inside the
701 ms interval. The later diagnostic-collection `simctl` error is after the failed assertion,
not an established explanation of its duration.

Product sources/project/tests are unchanged from reviewed #122 `161d7f8`. DashboardView,
DataActor, BudgetEngine and the benchmark fixture are also unchanged from #120 `705d2a7`.
The independent CloudKit probe target is not the ordinary application target. This excludes
a new change to these source paths; it does not prove identical runtime conditions or absolve
an existing performance weakness.

## Preregistered diagnostics, not repeated acceptance

Both diagnostics ran in a separate detached worktree from `bedac7f`, with separate DerivedData
and results, local Xcode 27 beta 6 / iOS Simulator 26.5. They retained the exact 10,000-row
fixture, user-calendar calculation, money logic and real load. No cache warming, forced system
pressure, process termination, schema/query optimization, threshold change, retry or CloudKit
probe was introduced. Only buffered marks matching the synthetic fixture's actor were enabled;
console output occurred after the original elapsed value was captured.

1. One instrumented execution of the original benchmark, including the original 500 ms assertion:
   **867.858042 ms**, exit 65, native **Failed** once. Marks separate actor dispatch, fetch, mapping,
   budget work and main-thread return. Whole-process CPU/fault counters are not exclusive stage cost.
2. One separately named `diagnoseDashboard701ThreadCPUOnFreshStore()` method, preregistered after
   diagnostic 1, adds public `CLOCK_THREAD_CPUTIME_ID` / `pthread_threadid_np` counters. It creates
   one fresh fixture, loads it once and checks 10,000 expenses / empty wishlist. Measured duration
   **985.974667 ms**; native **Passed** once means those structural checks passed, NOT the 500 ms gate.
   The acceptance benchmark was not selected for this second command.

Both native detail trees confirm one method, device and configuration, no Repetition or extra
attempt. The same selected simulator was used. No physical device or account operation occurred.

## Observed bottleneck

| Stage | Diagnostic 1 wall ms | Diagnostic 2 wall ms | Diagnostic 2 same-thread CPU ms |
| --- | ---: | ---: | ---: |
| Expense fetch | 587.497042 | 682.125292 | 464.300833 |
| Expense summary mapping | 219.855625 | 208.023083 | 155.454834 |
| Budget snapshot + pace | 14.263709 | 10.954708 | 10.813375 |

Fetch plus mapping account for about 93.0% / 90.3% of the respective loads. Dispatch before
expense actor entry is 0.649708 / 1.806875 ms; the return after mapping is 13.233125 / 25.906375 ms.
Wishlist projection is 0.334834 / 0.851083 ms. Budget computation is not the dominant observed cost.

The second fetch/map span stays on one thread without source-level awaits. Its CPU total is
619.755667 ms versus 890.148375 ms wall time: these samples show both substantial synchronous
CPU work and a 270.392708 ms wall-minus-thread-CPU difference. That difference is **not** a proven
scheduler delay; blocking, page faults, runtime/library work and accounting effects have not been
separated. Equal thread IDs around an async load would not make its CPU delta an exclusive load
cost; the analyzer deliberately attributes thread CPU only to known synchronous spans.

Source shows an unchanged full-table SwiftData fetch sorted by spentAt followed by per-record
validated ExpenseSummary construction. These measurements identify that existing storage/projection
path as the next profiling/corrective candidate. They do not identify a particular SwiftData
internal function, SQL query plan, accessor, allocator or scheduler mechanism as the root cause.

## Environmental observations and limits

The first diagnostic's pre/post one-minute host load readings were 7.80 and 286.13; later readback
was 151.00. The machine has 16 GiB RAM / 10 logical CPUs and about 10 GiB swap in use. Four unrelated
previous task simulators remained booted. These readings span the whole command, not precisely
the measured interval. They suggest environmental interference is plausible, but do not establish
causality for either diagnostic, let alone the earlier 701 ms event. No unrelated app/simulator
was stopped. Process-wide CPU exceeding wall time in diagnostic 1 reflects concurrent process
work; it must not all be attributed to the expense actor.

No uninstrumented reference or controlled-load comparison was performed in this investigation.
Probe overhead, cold process/code state, fixed diagnostic order, Debug/coverage instrumentation
and other host activity limit comparisons. Historical #120 measurements are different executions,
not a paired control. Neither a transient classification nor a gate waiver is justified.

## Withdrawal / evidence

All temporary changes in DataActor, DashboardView and the test file were removed with a scoped
reverse patch after preserving both patches and source hashes. The diagnostic worktree is clean
and `git diff --exit-code -- MindBudget MindBudgetTests MindBudgetUITests Scripts` passes. Do not
reuse its instrumented build products for acceptance; a future candidate must rebuild.
PR #123 remains at `bedac7f`, Draft. Only local documentation changes are retained; no commit,
push, PR edit, merge, full-validator rerun or product repair occurred in this investigation.

Private evidence retains both logs/receipts/patches, native summary/tree/detail, pre/post resource
readings and an explicit-failure analyzer. No personal identifiers or unrelated record data are
included in this report.

- Original failure receipt SHA-256: `96b8353d05488ac581536292f8cd2f61909a01711364e797c368c0bf740f6a14`.
- Diagnostic 1 patch SHA-256: `5bf2c3bf6ef410d530c7cdb08467f1fea1aab4e62d7bb7f5dffed7ef8e40c5ee`.
- Diagnostic 2 patch SHA-256: `5505598ad171feee19be330eaee1df00715ab4100b5f984a790c5d568e3e490a`.
- Analysis JSON SHA-256: `a0031a1c6f544c88b029070ee4911f4d588791d0081a68973714a1f171dae783`.
- Analyzer SHA-256: `64f46d18806f3cb5519e25c91eb458398d080c231f6352c5ba2311e872f14a6c`.

At that checkpoint, the next decision was to authorize a bounded storage/projection profiling or corrective experiment, keeping
all fields/validation/freshness/sort semantics and comparing against the unchanged baseline.
Do not assume the previously rejected propertiesToFetch experiment is a fix. Any accepted change
still needs a new reviewed source head, full default local validation and hosted/native evidence.
No change to the 500 ms gate, D's four open items, E/Insights or live CloudKit prerequisites.

## Subsequent owner authorization

After this investigation, owner authorized controlled read/map optimization. See
DASHBOARD_READ_MAP_OPTIMIZATION.md for the separate candidate, all controlled observations
and still-pending complete validation. This does not relabel the original failure or prove
its cause. The preceding investigation/no-repair statements describe that completed checkpoint.
