# Dashboard first-load repair candidate

Status: **In Progress — owner authorized implementation; acceptance pending.**

The owner authorized corrective work after the separately recorded investigation. Historical
first-load **883.249166 ms > 500 ms** on `b9cebd1` remains non-pass; its exact event cause is
UNPROVEN. Investigation commit `fbc24e0` is documentation, not corrective acceptance.
This candidate remains separate from documentation-only #118, whose three non-passes stay open.

## Narrow implementation contract

Optimize the existing full ExpenseSummary projection, not BudgetEngine, the benchmark workload,
the result population, a warm cache or the 500 ms ceiling. Keep Int64 money, existing recoverable
validation/errors, actor ownership, unchanged sort and pending-change behavior. No predicates,
limits, dropped records, stale result cache, new SDK requirement, raw persistence adapter,
network channel, schema change or UI behavior change.

Rejected candidate 1: an explicit iOS 17+ `FetchDescriptor.propertiesToFetch` list for every attribute read
by the existing summary; exclude only `note` and `normalizedMerchantName`, which are not summary
inputs. Detailed/edit/export consumers still access their original full data. Capture `expense.id`
once inside each synchronous actor-isolated conversion and reuse it for exactly the same error
identities. No await occurs between these reads. The Apple contract permits omitted attributes
to be fetched later; tests must prove this does not discard them or corrupt subsequent edits.
Source: [Apple propertiesToFetch](https://developer.apple.com/documentation/swiftdata/fetchdescriptor/propertiestofetch).

Its pre-registered comparison did **not** show a gain: baseline/candidate/candidate/baseline
was **210.223917 / 242.055792 / 248.426541 / 201.636166 ms**. Both orders regress, so partial
fetching has been withdrawn, not accepted because the diagnostic method passed. Those four
observations are retained. The public API's possible benefit did not materialize here.

Retained candidate 2 keeps the original full fetch exactly and isolates only the per-record
identity read. One ABBA comparison with the same protocol measured
**195.435708 / 164.186125 / 161.508875 / 190.064625 ms**. The two candidate samples total
15.51% less than the baseline pair, with improvement in both orders. This meets the
pre-registered exploratory criterion. It is four local observations, not a latency
distribution, production guarantee, hosted result or proof of the original 883 ms cause.

Before accepting the candidate, verify complete projections across saved/reopened stores,
insert/edit/delete freshness and pending changes, exact recoverable errors for invalid stored
currency/all enum fields, no raw-note/FX field leaks, and the unchanged 10,000-record contract.
Use a pre-registered baseline/candidate performance comparison with fresh fixtures and both
orders; distinguish its diagnostic observations from complete exact-head acceptance. Reject
the candidate if it does not show a useful gain or breaks data semantics. Remove temporary
comparison code before a frozen head's default full `Scripts/validate.sh` (zero retry,
unchanged 500 ms, ordinary suite and isolated FX host). Retain every intervening non-pass.

No push/new PR, undraft/merge, D completion or E/sharing entry is authorized by this local
repair work. Exact-head hosted/native evidence and independent review remain separate gates.

## Pre-registered candidate comparison

One temporary diagnostic method uses **baseline, candidate, candidate, baseline (ABBA)**,
each with a newly created in-memory store and the unchanged 10,000-row fixture. It calls the
real Dashboard load; only expense projection selection differs. The baseline fetch/mapper
is copied verbatim from `b9cebd1` apart from method renaming. Selector setup and record-shape
assertions/logging stay outside the original timed interval. No acceptance benchmark run is
selected. This fixed diagnostic checks both temporal orders, not best-of repeats; all four
samples are retained and none closes the 883 ms failure. Look for at least about 10% overall
gain without a reverse-order regression before retaining this specific optimization.
Withdraw the comparison selector/methods afterward. Final acceptance uses no alternate path.

## Candidate source and focused correctness

Both temporary comparison paths and the temporary test are now removed.
`Phase10ReleaseReadinessTests.swift` and the original `fetchExpenseSummaries()` descriptor
are byte-for-byte unchanged against `b9cebd1`; the only production diff is a function-local
`let id = expense.id` reused for the result and seven validation identities. No await, state
cache, changed currency check, enum fallback, dropped row or reordered validation is added.

Four new `ExpenseSummaryIdentityTests` cover all summary fields/currency codes and enum
variants across disk reopen, raw notes/detail/export continuity, per-row error identities
for currency and six enum fields (including first-error ordering), unsaved insert/edit/delete,
and saved edit/delete freshness. Together with 24 existing DataActor tests and the unchanged
10,000-record projection method, **29 focused methods passed**. This is not full validation.
No physical CloudKit, mixed-version peer or cross-calendar cloud claim is made.

Local comparison/focused toolchain: **Xcode 27 beta 6 (27A5252f), iOS Simulator 26.5 (23F77)**,
device `3D6221D5-39DF-4CD4-ADEE-472B4139F47B`. Each comparison method ran once with no
Repetition/extra execution in native detail. The first xcresult metadata extraction failed
with permission exit 64; only extraction was retried with permission, not either test.

Local artifacts: `/private/tmp/dashboard-repair-evidence.OpjqV6/` retains both logs, exact
temporary patches/source hashes, native summary/tree/detail JSON and focused bundle/log.
`analyze_comparisons.py` uses explicit failure checks (normal and `python3 -O` outputs match).
Analysis SHA-256: `ec9a098e50ffeae421feb18c9afbb5ca17eff9b7879c279f8fa026dc743a356e`;
analyzer SHA-256: `e8bae8753f29089d9f099493c1e05d5db9c1bbdb1669f1b19edf3a9d7bb4c5cb`.
Rejected candidate 1 remains negative evidence, not hidden behind the passing native test.

## Freeze / acceptance boundary

Freeze this source only after static/self-check completion, then run default complete
`Scripts/validate.sh` once with zero retry, the unchanged 500 ms benchmark and isolated FX
host. At this checkpoint no complete-local or hosted acceptance is claimed. Record the exact
frozen commit and every result in a subsequent local receipt; no doc-only rerun replaces it.
Original non-pass `b9cebd1`/883.249166 ms and all three #118 hosted non-passes remain retained.

Pre-freeze static checks passed: no-floating-point-money, network egress, commercialization
docs, StoreKit catalog and the complete FX contract self-test (including 1,021 closeout
mutations, no-retry/join controls and 165 privacy-sink mutations). `git diff --check` is clean.
