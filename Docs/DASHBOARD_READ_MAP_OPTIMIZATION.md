# Dashboard read/map optimization candidate

Status: DRAFT_REVIEW_CANDIDATE_PENDING_EXACT_HEAD_VALIDATION.

Owner explicitly authorized controlled read/map optimization after the #123 full-local
701.230625 ms / unchanged 500 ms failure. The experiment base was
bedac7fc3539da5dd18c7d8a682f6e200ab1c564 on codex/dashboard701-batched-projection.
Owner subsequently requested a Draft PR. Publication is a separate transplant on
codex/dashboard-read-map-optimization from main ba1464775dbfeafddcdd7b4c115217ae85ee56f6.
The original product/test/project trees of those two bases match byte-for-byte. Only the
two-file candidate and its documentation move to this branch; #123's probe/signing/gate changes
are NOT included. The final two source hashes below match the focused experiment exactly.
Earlier runtime evidence is still labelled by its experiment tree, not an exact-head run of
this publication. #123 stays frozen/Draft. No merge, installation, CloudKit request, D Done or E/share.

## Change and preserved semantics

Only DataActor.fetchExpenseSummaries changes: use public ModelContext.enumerate with 5,000
records per batch for a clean context, mapping each through the unchanged throwing mapper.
If hasChanges, retain the exact original fetch/map path. No forced save/rollback, cache,
query predicate, record limit, propertiesToFetch, schema, tie-breaker, field removal, money
calculation or budget-engine change. Output still materializes all value summaries; bounded
intermediate model fetching does not mean O(1) total output memory. No memory reduction was
measured or asserted. Mapping itself is deliberately unchanged.

[Apple's public enumeration API](https://developer.apple.com/documentation/swiftdata/modelcontext/enumerate(_:batchsize:allowescapingmutations:block:))
documents batching and the default no-escaping-mutations constraint. The dirty-context fallback
preserves pending inserts/edits/deletions without relying on new enumeration semantics for them.
The choice of 5,000 uses Apple's documented default; no batch-size search was conducted.

## Controlled evidence, not the release gate

Same Debug/coverage binary per round; serial A–B–B–A; four fresh original 10,000-row stores per
round through the actual Dashboard loader. Selector set before the timer; logging and reference
checks afterward. Untimed baseline on each same fixture verifies full ExpenseSummary sets,
count/spentAt order, wishlist, budget snapshot and pace. Equal-date secondary ordering is not
specified by the unchanged descriptor. No intentionally warmed timed store or dropped fields.
Code/OS caches and unrelated host activity are uncontrolled; local Xcode 27 beta 6 / iOS 26.5
simulator is not hosted Xcode 26.6. No unrelated process/simulator was stopped.

Keep rule was written before the first command: all correctness checks, >=10% mean gain and
both chronological pairs improving. The first round met that numeric rule but lacked actual
branch readback. A written addendum added last-path assignment to both branches and an untimed
assertion before reference loading. One second round was allowed; it independently had to meet
the same rule. Initial evidence is retained as preliminary, not quietly replaced by round 2.

| Round | A1 ms | B1 ms | B2 ms | A2 ms | Mean gain | Path confirmed |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Preliminary | 223.308750 | 179.797500 | 259.511875 | 284.593625 | 13.505% | No |
| Path-verified | 591.891584 | 309.220667 | 489.055542 | 584.168708 | 32.123% | A=baseline, B=enumerate5000 |

Verified mean A=588.030146 ms, B=399.1381045 ms. Both pairs improve, but B2 is just 10.944458 ms
below 500 ms. These are fixed small samples with substantial variability, not a distribution,
guarantee, or explanation of the earlier 701 ms. The separately named comparison method has
no 500 ms assertion: native Passed certifies its structural/equivalence/path assertions only.
The two verified baseline intervals exceed 500 ms and are retained as such, not relabeled.
The original acceptance test/fixture is restored byte-for-byte from bedac7f and not rerun here.

Native audit: each comparison method Passed once, no Repetition/extra attempt; six initial
identity/batch-boundary methods each Passed once. Both rounds built and exited 0, with exact
source hashes unchanged during each command. An explicit-failure analyzer produced identical
results under ordinary Python and python -O. No asserts can silently remove its checks.

## Uninstrumented retained candidate — pre-publication experiment tree

All temporary selectors, path recording, baseline duplicate and comparison test were removed
before rebuilding. Product diff is 10 added lines / 1 removed line in one existing method.
Three deterministic regression methods remain: every field/sort across >5,000 records;
exact corrupt currency/row identity after the first batch; large dirty insert/edit/delete
followed by clean read. Existing disk-reopen/optional fields/currencies/error order/freshness
tests remain unchanged. No product probe or debug environment hook remains.

Uninstrumented rebuild and focused execution passed: 88 methods in 10 suites, comprising
24 DataActor methods, 7 identity/boundary methods, the original 10,000-row projection method
and 56 FX unit bindings. Native detail confirms each Passed once on the selected simulator,
no Repetition/extra attempt. The repository's --verify-unit-bundle independently accepts all
56 bindings exactly once. All six static entry points passed (money, network, commercialization,
StoreKit, C6 and the complete FX wrapper including privacy/compatibility/probe protocol doubles).
Source hashes stayed unchanged throughout these commands. This is not complete validate.sh,
the 500 ms benchmark, isolated FX UI, hosted execution or an independent review.
In particular, the earlier six-gate result includes #123's probe protocol checks because that
experiment inherited #123; it is not a claim that this main-based PR ships the probe. Publication
preflight runs this branch's own existing static gates. Exact-head full local/hosted remain pending.

One original dirty-context fixture emitted SwiftData's ModelActor deinitialization-with-unsaved-
changes diagnostic during the first correctness run; the final focused log has two such
diagnostics while exercising the original/new large dirty-state fixtures. Native assertions
passed. These observations are retained, not claimed fixed or causally explained by batching.
No second-click/retry/skip/timing waiver is introduced anywhere.

## Evidence and remaining gate

Private evidence retains protocol/addendum, both instrumented patches, retained patch, exact
commands/logs/receipts and native bundles/JSON. Public report contains only synthetic aggregate
facts/hashes, no phone/profile/personal-account data.

- Preliminary patch SHA-256: 7f84f00e26b771ef3cd2c613bb60de1705923befde8e6461bc6482f9d05bcc8d.
- Path-verified patch SHA-256: 4a438e7fe8368bc5f770eae7c30e78519f88c2928d01277c776c066d1e8ff0f0.
- Comparison analysis SHA-256: 2b7e585f134d6f023e9e9e6284cdfb781712c9938c4069ff098e4b5d0792cda4.
- Analyzer SHA-256: fc32953974b62445cd674d51c4aa8b0c0aecfe3dde0e39e5e6ab61106018d893.
- Uninstrumented source/test patch SHA-256: 6523730a1a4f675478a15b1f654adf2e08186b5aeb82ff0f4b040d81a03e83d7.
- Focused/static receipt SHA-256: e6adcef51537f158d887a0258b4a69b6e75a777405764d3b8a22a501b4e274c8.
- Focused native JSON SHA-256: 3006493a14eeab673947f4f6aa98eeb455fc80406ae54522250bfbcfe36d6311.
- DataActor source SHA-256: 15b3b5e5d0e8085375ed7077b897c61fa619eec18164783430bf22c46e51c808.
- DataActorTests source SHA-256: 56894ec7ae4fa763709f967c5c07600507f313fb9ac1cfb45f63859baeaf94bc.
- Original failed validation receipt SHA-256: 96b8353d05488ac581536292f8cd2f61909a01711364e797c368c0bf740f6a14.

Not merge-ready. Next required acceptance is a reviewed new source head with default complete
local validate.sh (unchanged 500 ms, zero retry, ordinary and isolated FX), its own hosted
ordinary/FX/join and native audit, then independent review and explicit merge authorization.
#123's 701.230625 ms exit 65 remains a retained non-pass; original cause remains UNPROVEN.
Its old hosted success cannot validate this candidate. The external hard watchdog/collector
and separate signed-package live approval remain necessary for any physical CloudKit test.
