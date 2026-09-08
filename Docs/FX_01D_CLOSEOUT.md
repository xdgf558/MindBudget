# FX-01D independent post-merge closeout

Status: **PENDING_INDEPENDENT_REVIEW_AND_MERGE; D In Progress; FX-01E unentered.**

The owner authorized this separate documentation closeout after PR #117 merged. This is the
canonical record; other current-state documents point here rather than copying the evidence
table. Author evidence checking is not a second independent source review. This documentation
PR's diff against accepted main changes no product Swift, UI helper, threshold or retry policy
and authorizes no model request or CloudKit activation. Its own hosted tests failed twice below.
The owner now resumes #118 after the separately reviewed #119 repair merged into main. Main is
merged into this branch without reimplementing its repair; the remaining diff is documentation
and fail-closed evidence gates only. New exact-head evidence and independent rereview remain
required before any merge. #119's green is not this closeout's own green.

## Accepted corrective repair provenance

Repair reviewed head: `70fc7c13e361268c44b3cdf3a467eed2aa0fab17`.
Repair hosted run: `34182518433`; attempt 1; ordinary, FX and join succeeded.
Repair merge commit: `b3644444d2a56b6b1d42e564c57a1e1784809975`.
Repair merge second parent: `70fc7c13e361268c44b3cdf3a467eed2aa0fab17`.
Repair full-local runtime head: `70fc7c13e361268c44b3cdf3a467eed2aa0fab17`; default validate exit 0.
Repair strict benchmark: 216.419208 ms; unchanged ceiling 500 ms; zero retry; FX host included.
Repair acceptance is corrective, not proof of the original switch, AX-readback or ambient-sender cause.
This closeout requires its own exact-head ordinary/FX/join success and native audit; repair evidence is not a substitute.

[PR #119](https://github.com/xdgf558/MindBudget/pull/119) merged at 2026-09-08T08:41:21Z after
the owner supplied independent no-P1/P2 rereview and explicitly authorized ready/merge. GitHub
head/run/jobs/merge parents were checked directly. This off-platform review is not invented as
a GitHub review event. Accepted controls are localized explicit FX Enable/Cancel, a single Save
followed by independently loaded exact budget readback, explicit one-tap BudgetSetup row focus,
and private NotificationCenter sources at all ten synthetic service construction sites. Real
CloudKit/production defaults remain unchanged. Original mechanisms remain **UNPROVEN**;
failure-only public snapshots remain in the accepted tests, not temporary dispatch observers.

The source-freeze documents in `70fc7c1` predate its full execution; the authorized PR body
and retained local artifacts carried the later evidence before final rereview. This record
now preserves it in the repository without pretending that the frozen documents contained it.

| Evidence | Result and attribution |
| --- | --- |
| Exact-head complete local validator | Local Xcode 27 beta 6 / iOS 26.5; ordinary 633 methods = 616 Passed / 17 Skipped / 0 Failed, 625 concrete Passed, 13 argument executions; no Repetition/extra attempt. Coverage >=85% per selected core file, 23 C6-02 and 49 FX unit bindings each once. Author native audits and original log retained. |
| Local isolated FX | Three methods each Passed once; native details bound to fresh non-cloned `9788331F-61FB-48C4-BAE5-647F8F4F7934`; stewardship/create-zh/create-en 51.753 / 78.525 / 54.359s. Three Invalid frame warnings and diagnostic archive missing-simctl exit 72 retained; no complete diagnostic archive claimed. |
| Hosted metadata | Xcode 26.6 / iOS 26.5 run above; ordinary `101924294267`, FX `101924294076`, join `101932209214` all success. Direct API verification, not a test re-execution. |
| Hosted native audit | Attributed to the owner's supplied independent review: 616 Passed / 17 Skipped methods, 625 concrete executions, 49 unit bindings each once, no Repetition/extra attempt. FX three once, bound to fresh non-cloned `FE74F87B-0125-4F7B-94A2-F53DD05BB01E`; create-en/create-zh/stewardship 81.518 / 153.332 / 87.676s. Reviewer used local Xcode 27 beta 6 to read hosted artifacts, not rerun hosted 26.6. |

Full-local log SHA-256: `d428f94f79a3e94126882dd17e33a12ce399124ab80a1001fd1ec1c31899704d`.
Local FX provenance SHA-256: `f5c004b2f664f3ee49a2b96c517cff7362c216808646572b1c62e3037f50f4a7`.
Retained local artifact prefix: `fx119-70fc7c1-full-1`, with separate benchmark/native-audit
bundles. This is not a new full-local run on #118. New #118 head/run/native results will be
identified in its PR execution checkpoint after source freeze; no result is pre-approved here.

## Retained closeout non-pass ledger

Closeout retained non-pass: `34097606992` / `52008165d1faf4a03a92d282cdb036b2bcaf3c8c`; attempt 1; ordinary, FX and join failed.
Closeout retained non-pass: `34108994597` / `9c3c6b1d905c4e4f0c9f1cf903bc924f572ce19d`; attempt 1; ordinary, FX and join failed.
Neither closeout failure is transient, waived, or relabelled by the accepted #119 repair.

The second run's jobs are ordinary `101700573464`, FX `101700573721`, join `101711782743`;
head/attempt/conclusions were checked directly. Original artifacts are ordinary `10014896092`
and FX `10014180442`. The prior investigation's native audit records ordinary
`retryRunsOneTransportPassAndPausedAccountChangeRunsNone()` line 87: synchronize count 2 vs 1,
not another budget-field failure; FX Chinese AX5 create remained off after one off-track tap.
Each ordinary bundle has 609 Passed / 1 Failed / 17 Skipped methods, 618 concrete Passed;
each FX bundle is 2 Passed / 1 Failed. The fresh non-cloned FX UUIDs were respectively
`FE266090-65CD-4ADC-9D71-08A5712AC89F` and `D3932B37-3B3C-4A3B-85BC-D97E2B62B201`.
The original ambient notification sender is unobserved. Detailed original inspection is
retained in `FX_UI_RELIABILITY_INVESTIGATION.md`; no new failed-bundle audit is claimed here.

## Historical first-closeout failure detail — 34097606992

PR #118 head `52008165d1faf4a03a92d282cdb036b2bcaf3c8c`, hosted
[34097606992](https://github.com/xdgf558/MindBudget/actions/runs/34097606992), attempt 1:
**failure / retained non-pass**. Ordinary `101664622832`, FX `101664623020` and join
`101673689351` all failed. Run/head/job metadata and original artifact IDs were checked directly;
the failure details below are attributed to the owner's supplied independent artifact review,
not a newly performed author native audit of this failed run.

| Suite / artifact | Reviewer-observed failure | Other observed methods, not suite admission |
| --- | --- | --- |
| FX / `10009729091` | `testManualForeignCurrencyChineseAX5ProCreateAndDetail` failed in 29.8 s after one off-track tap. Row `(36,132,330,125.33)`, native child `(305,180.67,63,28)`, offTrackTap `(352.25,194.67)`; both rowValue and childValue remained 0. Reviewer reports a fresh non-cloned device with UUID prefix `FE266090-`. | Chinese stewardship Passed 163.3 s; English create Passed 101.5 s. Neither makes the failed three-method bundle pass. |
| Ordinary / `10010259290` | `testCategoryChartLegendKeepsSixItemsReachableInSimplifiedChinese` failed at `MindBudgetPhase3UITests.swift:1682`: budget.savingGoal did not become `"500"` in the bounded 5 s wait (`XCTWaiter.timedOut`). | The English counterpart Passed in 106 s; not proof that the Chinese state transition succeeded. |

The later #119 inspection clarifies that the error's rowValue/childValue literals were captured
pre-tap, not independent post-tap measurements. Separate video/AX attachments establish the
failed activation. Retain this distinction alongside the original reviewer report above.

The 0.75 off-track single tap is therefore not a demonstrated stable hosted-26.6 solution;
its earlier success remains a bounded observation, not cause closure or universal reliability.
The filling timeout's mechanism is not established here either. No helper, longer press,
retap, allowance, benchmark ceiling or retry setting changes in this documentation PR.
Retain both failures without calling them transient, blaming the documentation, or reusing
`34090503092` as this PR's acceptance. The earlier status-only correction did not repair either
failure; its new run also failed. Resumption now follows the separately accepted #119 source
repair, not a documentation-only rerun until green.

P2-1's missed Current D work sentence is corrected from "implemented in Draft PR #117" to
"were merged in PR #117". P2-2 remains open until this closeout's new exact head has ordinary,
FX and join success with zero retry and the required native audit/rereview. Keep Draft; D's
four checkboxes remain unchecked, D is not Done and FX-01E remains unentered. The original
814.581125 ms failure and `34072691064` / `34077058451` remain retained alongside this run.

The accepted implementation provenance and audit below refer only to #117's `34090503092`,
not to the failed closeout bundle or its replacement head. This pending packet must not be
self-approved after merging; explicit final acceptance is still required.

## Accepted implementation provenance

Reviewed head: `7e901f2e3b521e2185bf7c4c00b6e77e21b8d80c`.
Hosted run: `34090503092`; attempt 1; ordinary, FX and join succeeded.
Merge commit: `d19c6401bc14d2b43365b0936a37fe270e39c481`.
Merge second parent: `7e901f2e3b521e2185bf7c4c00b6e77e21b8d80c`.
Reviewed and merged tree: `0337e7b6ffa6267285b5b7a904e711d62c7f6535`.
Review scope: owner-supplied independent implementation approval; not D Done.
Full-local runtime head: `8e572832073f84be6513b7da4f3d7bbf5e67941b`; default validate exit 0.
Strict benchmark: 217.09825 ms; unchanged ceiling 500 ms; zero retry; FX host included.
Retained non-passes: `34072691064`, `34077058451`, original 814.581125 ms / exit 65.
Original benchmark and gesture causes remain unproven.

[PR #117](https://github.com/xdgf558/MindBudget/pull/117) merged at 2026-09-07T07:28:23Z.
[Hosted run](https://github.com/xdgf558/MindBudget/actions/runs/34090503092) jobs are ordinary
`101642813577`, FX `101642813753`, join `101652174130`. GitHub run/head/job/parent metadata and
the matching trees were checked directly. The independent approval and subsequent owner merge
authorization were supplied in this conversation, not fabricated as a GitHub review event.
The non-Docs tree is identical between `8e57283` and `7e901f2`; the full local run belongs only
to `8e57283`. Neither that invocation nor the accepted hosted run tested this closeout head.

## Original hosted artifact audit

Downloaded original artifact IDs **10007720280** (ordinary) and **10007144902** (FX), unexpired
at inspection. Xcode 26.6 produced them; the read-only native audit used local Xcode 27 beta 6
`xcresulttool`, not a re-execution under the hosted compiler or a new physical-device result.

| Artifact | Methods / concrete executions | Repetition / extra attempt | Warnings |
| --- | --- | --- | --- |
| Ordinary | 627 methods: 610 Passed / 17 Skipped; 619 concrete Passed plus 17 Skipped; 13 argument executions across four parameterized methods | 0 / 0 | 0 |
| FX | Three methods, each Passed once | 0 / 0 | Three existing invalid-frame diagnostics |

Every method detail was read; parameter tree/detail bijections passed. Ordinary UUID is
`861779CC-5DF4-4C5B-9262-A703C36C6407`. All three FX detail device IDs equal provenance
**`1D772EA9-44AC-44FA-8AD7-9DEE828F1CB7`**, fresh/non-cloned, not the source simulator
`F208A4B5-6297-4EC3-836B-936C547F887E`. Both use iPhone 17 Pro / iOS 26.5 (23F77).
The repository verifier separately requires all 49 FX unit bindings and three FX UI bindings
Passed exactly once. The 17 ordinary skips are preserved: four physical-cloud, one on-device
Eval, one physical C6-02, two live configuration/telemetry, six opt-in StoreKit and three FX
methods reserved for the separate host. They are not transport passes.

| FX method | Hosted seconds | Unchanged per-method allowance |
| --- | ---: | ---: |
| Chinese AX5 stewardship edit | 108.765 | 240 |
| Chinese AX5 create/detail | 171.399 | 240 |
| English create/detail | 96.387 | 240 |

That accepted implementation run's maximum uses 71.4% of the allowance, with 68.6 s remaining. This is an observation,
not a future performance guarantee or permission to raise allowances/retry. The 600 s boot
capacity obligation and zero-retap boundaries remain. Hosted ordinary skips the strict wall-clock
benchmark; only the complete local run in the implementation evidence satisfies that signal.

Native tree JSON SHA-256: ordinary
`59673be65b54e75182d7131328982bac215093b4642555df9f19781245c9189d`; FX
`419b52a5b81d06d32aa7adeeb6d0b74bbc6f67bd0ba9d6cce53e4b60a5f6a747`.
FX provenance JSON SHA-256:
`a4befdb4791698f4588b770c4229e3ba4a62d87001457d2d1170db4df34e29d6`.
Local retained downloads/audits use `/private/tmp/pr117-closeout-34090503092-ordinary.xcresult`,
`-ordinary-native`, `-fx` and `-fx-native`. These are artifact locations, not committed copies.
An initial repository-verifier invocation omitted `DEVELOPER_DIR` and failed to find xcresulttool;
no runtime test ran. After selecting Xcode, the ordinary binding verifier also rejected the
extracted directory's missing `.xcresult` suffix; that directory was renamed without changing
its contents. These are retained read-only audit setup failures, not test reruns or product fixes.

## Four-item checklist assessment (no checkbox changes)

The original four obligations in the plan and TASKS are unchanged and remain unchecked until
the closeout is independently accepted. This matrix maps evidence and limits; it does not
silently redefine the obligations or certify an unexecuted path.

| D obligation | Concrete implementation evidence | Remaining limit / disposition |
| --- | --- | --- |
| Locked accounting consumers | `ForeignCurrencyPersistenceTests.lockedAccountingConsumersMatchOrdinaryRowsAcrossForeignMetadataVariants` compares actor summaries, Dashboard/budget/pace, Insights/categories, Log, Ask/report and Spotlight; `lockedAccountingReminderMessagesAndRedactedPromptsMatchOrdinaryRows` covers real ReminderEngine messages and captured redacted prompts in both languages/three tones. | Equality is tested on synthetic ordinary/manual/override variants, including changed Settings and rate date. It is not a claim of exhaustive possible inputs or a model/physical run. |
| CSV | `Phase6FeatureTests` pins 22+8 columns, BOM/escaping/formula protection, JPY/EUR/KWD, exact saved rational/date/time-zone, override/DST facts and contradictory-tuple rejection; actor export snapshot test covers damaged metadata. Income/ordinary rows keep eight blanks. | Existing bilingual disclosure/source checks; explicit in-memory CSV only. No social card, network export or receipt/FX inference authorized. |
| Optional iCloud | Frozen pre-D parent projection hash plus 13-type/order gate; `ForeignCurrencyPersistenceTests` covers arrival permutations, duplicate replay, missing/invalid/undecodable cohorts, lineage rollback, paired conflict choice, deletion, disabled/recovery/erasure and legacy-shaped parent replay. | In-memory synthetic transport, not an executed old 12-type application or real mixed-version CloudKit delivery. The original legacy-peer obligation stays open to independent sufficiency assessment; no waiver is created. Cross-calendar risk below is unresolved. |
| Privacy and other consumers | Full ordinary suite plus 49 binding gate; 165 source injections across 15 private sinks; real redaction seams with local throwing model doubles, plus notification/telemetry/Siri/App Intent/receipt/wishlist/recurrence/Delete All regressions. | Source gate is finite: renamed/new/reflected sinks are not universally proven safe. Ordinary suite passes do not convert opt-in skips into live-channel evidence or supersede final-binary privacy checks. |

Test owners and exact method names are in `MindBudgetTests/ForeignCurrencyTests.swift` and
`MindBudgetTests/Phase6FeatureTests.swift`; the mandatory bindings are in
`Scripts/fx01_ui_contract.py`. No tests are weakened or added in this documentation closeout.

## Open obligations and acceptance boundary

Cross-calendar companion reconstruction remains unverified: the reader uses `Calendar.current`
with the payload time zone, reconstructs start-of-day, then requires exact stored-date equality.
That fails closed but may reject a legitimate tuple on a non-Gregorian peer. No cross-calendar
matrix was run and no calendar identifier was added. Independent closeout review must decide
whether the existing D compatibility obligation is satisfied; this record does not silently
move an unmet D requirement into E or waive it. A required code correction needs separate scope.

Real CloudKit/account/offline scheduling, an actual old/new binary pair and release-device
privacy evidence were not run. Historical COM waivers apply only to their named observations;
they are not new waivers of FX compatibility. No channel is enabled by this record.

Retain the existing maintenance debts: last observed absence of main required-check enforcement
(no settings change here), 600 s boot capacity, 240 s timing curve, two existing hidden-retap
callers outside the repaired path, fx.mode/fx.accounting.format copy, duplicate reminder Close,
and the dead isFinite branch. The old 0.75 switch point is retired by #119's explicit FX
buttons, not certified as reliable. Settings budget rows lack BudgetSetup's whole-row focus.
The accepted repair's hosted Chinese FX create used 153.332s / 240s and retained three Invalid
frame warnings. Failure-only public snapshots remain. Original event causes are UNPROVEN;
no second click or longer press is authorized. Earlier C and D non-passes are untouched.

D remains In Progress; its four checkboxes remain unchecked.
FX-01E, FX-02, COM-C12 and Insights/share implementation remain unentered here.
No Archive, upload, tester assignment, distribution, release or automatic merge is authorized.

This closeout needs independent review, its own exact-head hosted CI/native audit and merge.
Only an explicit final acceptance resolving the checklist assessment may later mark D Done;
the implementation merge and this pending packet cannot do so. Do not start another phase
as a side effect. Future acceptance may be recorded together with the separately authorized
next task rather than inventing an endless chain of self-approving documentation PRs.
