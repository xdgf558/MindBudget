# FX-01D independent post-merge closeout

Status: **PENDING_INDEPENDENT_REVIEW_AND_MERGE; D In Progress; FX-01E unentered.**

The owner authorized this separate documentation closeout after PR #117 merged. This is the
canonical record; other current-state documents point here rather than copying the evidence
table. Author evidence checking is not a second independent source review. This documentation
PR changes no product Swift, UI helper, threshold or retry policy and authorizes no model request
or CloudKit activation. Its own hosted tests did execute and failed as recorded below; it must
obtain new exact-head evidence and independent rereview before any merge.

## Current closeout non-pass — 34097606992

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

The 0.75 off-track single tap is therefore not a demonstrated stable hosted-26.6 solution;
its earlier success remains a bounded observation, not cause closure or universal reliability.
The filling timeout's mechanism is not established here either. No helper, longer press,
retap, allowance, benchmark ceiling or retry setting changes in this documentation PR.
Retain both failures without calling them transient, blaming the documentation, or reusing
`34090503092` as this PR's acceptance. The status correction requires one new-head hosted run;
it is not a code repair of either observed failure or approval to rerun until green.

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
and the dead isFinite branch. The 0.75 point is limited to the current LTR/off fixtures;
width > height is not RTL detection. Native long-press can still participate; failure stays
fail-closed without a second click or longer press. Earlier C and D non-passes are untouched.

D remains In Progress; its four checkboxes remain unchecked.
FX-01E, FX-02, COM-C12 and Insights/share implementation remain unentered here.
No Archive, upload, tester assignment, distribution, release or automatic merge is authorized.

This closeout needs independent review, its own exact-head hosted CI/native audit and merge.
Only an explicit final acceptance resolving the checklist assessment may later mark D Done;
the implementation merge and this pending packet cannot do so. Do not start another phase
as a side effect. Future acceptance may be recorded together with the separately authorized
next task rather than inventing an endless chain of self-approving documentation PRs.
