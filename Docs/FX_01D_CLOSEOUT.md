# FX-01D independent post-merge closeout

Status: **PENDING_INDEPENDENT_REVIEW_AND_MERGE; D In Progress; FX-01E unentered.**

The owner authorized this separate documentation closeout after PR #117 merged. This is the
canonical record; other current-state documents point here rather than copying the evidence
table. Author evidence checking is not a second independent source review. This documentation
PR's diff against accepted main changes no product Swift, UI helper, threshold or retry policy
and authorizes no model request or CloudKit activation. Its own hosted tests failed four times below.
The owner now resumes #118 after the separately reviewed #119, #120 and #121 repairs merged into main. Main is
merged into this branch without reimplementing its repair; the remaining diff is documentation
and fail-closed evidence gates only. New exact-head evidence and independent rereview remain
required before any merge. None of those repairs' greens is this closeout's own green.

Current acceptance: **RESUMED_AFTER_PR121_MERGE_PENDING_EXACT_HEAD_CI_AND_REVIEW**.
The four failed closeout heads remain non-pass. The independently accepted #121 correction
now supplies a changed runtime baseline; importing that merged baseline is not an unchanged
head rerun or a new helper fix inside this documentation PR. This resumed head still needs
its own ordinary/FX/join green, native audit and independent review. D is not Done.

## Accepted third corrective repair provenance

Third repair reviewed head: `689b932011ff48e4bd952c41558eaa9182bef5d5`.
Third repair hosted run: `34302080136`; attempt 1; ordinary, FX and join succeeded.
Third repair merge commit: `039ecdfaa48c6cfac407aa375498024681afed32`.
Third repair merge second parent: `689b932011ff48e4bd952c41558eaa9182bef5d5`.
Third repair full-local runtime head: `689b932011ff48e4bd952c41558eaa9182bef5d5`; default validate exit 0.
Third repair strict benchmark: 180.427333 ms; unchanged ceiling 500 ms; zero retry; FX host included.
Third repair does not relabel the fourth #118 failure or prove the original 46.953s query cause.

[PR #121](https://github.com/xdgf558/MindBudget/pull/121) merged at 2026-09-09T03:03:52Z
after owner-supplied independent no-P1/P2 review and explicit ready/merge authorization.
Direct API checks verified run/head/attempt/conclusion and merge parents: first parent `10e5b13`,
second parent above. Independent native findings here are attributed to that supplied review,
not an invented GitHub approval event or a new author audit of every old artifact.

Accepted query controls use scoped currency-menu snapshots and one immutable `revealFX`
geometry observation per iteration, then retain native selection/final hittability checks.
Ten/fourteen pan caps, single activation, actual input/save/detail assertions and 240s remain.
They reduce redundant queries, not prove or guarantee platform latency. The accepted separate
dependency commit scopes Miniflare's sharp override to 0.35.4 in both Workers and patches
PublicConfiguration Vitest to 4.1.11; no audit threshold/runtime/Worker source change.
Keep that temporary override until a compatible upstream chain uses patched sharp and passes
the unchanged checks without it. No new helper or dependency edit is made inside #118.

| Evidence on 689b932 only | Result and attribution |
| --- | --- |
| Complete local | Default validate exit 0, 2026-09-09 02:09:33–02:35:12 UTC; local Xcode 27 beta 6 / iOS 26.5. Strict benchmark 180.427333ms / 500ms, ordinary 625 Passed / 17 Skipped; lockfile hashes match the runtime head. User-supplied independent review; original receipt/log/provenance rechecked here. Not a new local run on this closeout head. |
| Local FX | Three methods Passed once on fresh non-cloned `CA5D9B29-41A7-42F0-A395-FD3141CD7113`; stewardship/create-zh/create-en 27.814 / 56.039 / 42.367s. |
| Hosted metadata | Xcode 26.6 / iOS 26.5; ordinary `102310924915`, FX `102310924614`, join `102319725282` success; artifacts ordinary `10086307270`, FX `10085644601`. Both Worker `npm audit --audit-level=high` and `npm run check` passed before Xcode. |
| Hosted native | Supplied independent audit: ordinary 625 Passed / 17 Skipped, no Repetition, 49 FX unit bindings once and 23 C6 bindings. All three new deterministic tests Passed; isolated FX methods correctly skipped in ordinary. Ordinary UUID `89E13B97-6725-4686-9B76-3AFE61050F38`. FX three Passed once on non-cloned `C416519E-8F2C-4AEB-AE2E-2630E59D8A8C`, repository verifier device-bound. Reader used local Xcode 27 beta 6 for hosted 26.6 artifacts, not a hosted rerun. |

| Hosted FX method | Seconds | Result |
| --- | ---: | --- |
| `testManualForeignCurrencyChineseAX5ExpiredStewardshipEdit` | 83.923 | Passed once |
| `testManualForeignCurrencyChineseAX5ProCreateAndDetail` | 107.546 | Passed once |
| `testManualForeignCurrencyEnglishProCreateAndDetail` | 65.284 | Passed once |

Three Invalid-frame warnings remain. 107.546s is an observation on this accepted head,
not a rewriting of #118's 240s timeout or a forecast for the new closeout head.
Local full-log SHA-256: `a3830e33461894acaca7fbefa7a69c8b7eb9105cd084417636bf3341b75f5e82`.
Local FX provenance SHA-256: `71c412aa4edc46055e264aa040865eac8526aa29a9f925c8577a29dc521e4ba8`.
Raw local prefix is `/private/tmp/worker-audit-repair.ZIgNda`; hashes are not remotely accessible artifacts.
Both local audit JSON reports show zero vulnerabilities (13 PublicConfiguration tests,
35 Telemetry tests plus 8 evidence checks); full `validate.sh` itself does not run npm audit.

Retain the intermediate #121 non-pass separately from #118's four-run ledger:
Third repair retained non-pass: `34298810822` / `4086c59b7ab2a2554ccc1911ecee8e69482d35e3`; attempt 1; ordinary and join failed; FX passed.
Ordinary failed at the high-severity Worker audit before Xcode, not an ordinary test failure;
no ordinary xcresult exists, upload failed and Telemetry audit was skipped. Old FX UUID
`4460E94D-7A79-40F0-A0D4-06778C13061B` and 121.980/100.849/73.399s cannot substitute for 689b932.
Source-freeze pending #121 checklists are historical; this accepted chain supersedes their
current status but never changes their old execution head. The first local prototype non-pass
and all earlier packets remain intact. This third repair is not #118 acceptance or D Done.

## Accepted second corrective repair provenance

Second repair reviewed head: `705d2a776c56f6722beb73ec00fc093b9ca3ed16`.
Second repair hosted run: `34241669738`; attempt 1; ordinary, FX and join succeeded.
Second repair merge commit: `10e5b13937fb4960d85acbb6f30ede0a44e39dfd`.
Second repair merge second parent: `705d2a776c56f6722beb73ec00fc093b9ca3ed16`.
Second repair full-local runtime head: `705d2a776c56f6722beb73ec00fc093b9ca3ed16`; default validate exit 0.
Second repair strict benchmark: 194.901083 ms; unchanged ceiling 500 ms; zero retry; FX host included.
Second repair does not relabel any #118 failure or prove the original 883.249166 ms event cause.

[PR #120](https://github.com/xdgf558/MindBudget/pull/120) merged at 2026-09-08T16:03:46Z
after owner-supplied independent no-P1/P2 review and explicit ready/merge authorization.
Direct GitHub checks verified the exact head, attempt, three job conclusions and two-parent
merge chain (first parent `b364444`, second parent above). This is an off-platform review,
not an invented GitHub approval. The review accepts corrective controls, not D completion.

Its accepted source observes the final permitted Settings pan, performs immediate
capture-inclusive FX Done/keyboard observation within the unchanged three-second deadlines,
and routes Wishlist through one safe Save with exact independent Settings readback. Dashboard
mapping reads each Expense identity once; full fetch/population/sort/validation remain intact.
Rejected partial-fetch candidate and original 883.249166ms exit 65 remain in the investigation.
No comparison probe, selector, dispatch observer, retap, changed 500ms or 240s limit is imported.

| Evidence on 705d2a7 only | Result and attribution |
| --- | --- |
| Complete local | Local Xcode 27 beta 6 / iOS 26.5; default validator exit 0, 194.901083ms. 622 Passed / 17 Skipped methods, 631 concrete Passed; 23 C6-02 and 49 FX unit bindings each once; selected core coverage >=85%. Author receipt/native checks independently reviewed; not a local run on this closeout head. |
| Local FX | Three methods Passed once, no Repetition/extra attempt, bound to fresh non-cloned `558FE3CB-0361-4E57-ADC0-C62AA226EA51`. Stewardship/create-zh/create-en 44.906 / 74.543 / 50.690s. |
| Hosted metadata | Xcode 26.6 / iOS 26.5; ordinary `102113124749`, FX `102113125136`, join `102130361276` success. Artifacts ordinary `10064250004`, FX `10063045432`. |
| Hosted native | Owner-supplied independent audit: 622 Passed / 17 Skipped / 0 Failed methods, 631 concrete Passed, 49 FX bindings each once, zero Repetition/extra attempt. FX three Passed once bound to non-cloned `36B43ECD-2060-471D-93B1-F9B7D537D02B`. Reviewer read artifacts with local Xcode 27 beta 6, not a hosted-toolchain rerun. |

The three third-closeout failed paths Passed on this repair head: pseudo-long 110.227s,
Wishlist 60.379s, FX stewardship 93.742s. These results do not backfill their failed heads.
All three existing FX Invalid-frame warnings remain. Exact hosted method attribution:

| Hosted FX method | Seconds | Result |
| --- | ---: | --- |
| `testManualForeignCurrencyChineseAX5ExpiredStewardshipEdit` | 93.742 | Passed once |
| `testManualForeignCurrencyChineseAX5ProCreateAndDetail` | 183.322 | Passed once |
| `testManualForeignCurrencyEnglishProCreateAndDetail` | 113.153 | Passed once |

Complete-local receipt SHA-256: `ca06b925c5328bb5c9de40d060c3619e4e4113966080bebace80eac9682ffae8`.
Full-local log SHA-256: `b73c60136137e3b8abaf26a16a32c07d09ec874d42d570bb6e0cd4e158405c85`.
Local FX provenance SHA-256: `20d00b80cd776b78f3efc4adcea1c3a944104f87e8f0441995788054a0536302`.
The initial local audit refused nested enum Test Value display metadata; its non-pass verdict
is retained. A closed recursive metadata adapter (2 positive/6 negative checks) reread the
same bundle without a test rerun or repository-gate change. Final counts above were accepted
in independent review. Raw artifacts remain local; hashes alone are not remotely accessible proof.

Source-freeze pending checklists in #120 predated its execution and review. This post-merge
record supersedes their current acceptance status without pretending that the frozen files
already contained the later proof. Its packet/PR receipts remain attributable to 705d2a7.
The independent review's five P3 obligations remain below; no new scope is implemented here.

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
| Hosted native audit | Attributed to the owner's supplied independent review: 616 Passed / 17 Skipped methods, 625 concrete executions, 49 unit bindings each once, no Repetition/extra attempt. FX three once, bound to fresh non-cloned `FE74F87B-0125-4F7B-94A2-F53DD05BB01E`; exact method/duration mapping is in the table below. Reviewer used local Xcode 27 beta 6 to read hosted artifacts, not rerun hosted 26.6. |

Full-local log SHA-256: `d428f94f79a3e94126882dd17e33a12ce399124ab80a1001fd1ec1c31899704d`.
Local FX provenance SHA-256: `f5c004b2f664f3ee49a2b96c517cff7362c216808646572b1c62e3037f50f4a7`.
Retained local artifact prefix: `fx119-70fc7c1-full-1`, with separate benchmark/native-audit
bundles. This is not a new full-local run on #118. New #118 head/run/native results will be
identified in its PR execution checkpoint after source freeze; no result is pre-approved here.

## Accepted repair hosted FX duration mapping

This table belongs only to hosted `34182518433`, not local execution or #118's failed run.
The earlier `98345d3` paragraph mislabeled 81.518s as English create and 87.676s as stewardship.
Direct original job-log inspection confirms the corrected identities below. The three local
durations above were correct and are unchanged. Exact row anchors and negative swaps guard
against matching an unlabeled sequence of numbers with the wrong methods.

| Hosted FX method | Seconds | Result |
| --- | ---: | --- |
| `testManualForeignCurrencyChineseAX5ExpiredStewardshipEdit` | 81.518 | Passed once |
| `testManualForeignCurrencyChineseAX5ProCreateAndDetail` | 153.332 | Passed once |
| `testManualForeignCurrencyEnglishProCreateAndDetail` | 87.676 | Passed once |

## Retained closeout non-pass ledger

Closeout retained non-pass: `34097606992` / `52008165d1faf4a03a92d282cdb036b2bcaf3c8c`; attempt 1; ordinary, FX and join failed.
Closeout retained non-pass: `34108994597` / `9c3c6b1d905c4e4f0c9f1cf903bc924f572ce19d`; attempt 1; ordinary, FX and join failed.
Closeout retained non-pass: `34218693463` / `98345d3c935355cc3217ff010e6e629f2358161b`; attempt 1; ordinary, FX and join failed.
Closeout retained non-pass: `34250759552` / `2ab850a5dcd77d90b7d088856b97b003fc9619d3`; attempt 1; ordinary succeeded; FX and join failed.
None of the four closeout failures is transient, waived, or relabelled by the accepted #119, #120 or #121 repairs.

Fourth-run jobs: ordinary `102144301398` success, FX `102144301907` and join `102160721420`
failure; artifacts ordinary `10067720558`, FX `10066839243`. Exact head/outcome checked
directly; the native findings are attributed to the supplied independent review.
Chinese AX5 create/detail exceeded the unchanged 240s allowance, total method duration
316.533s (`Test exceeded execution time allowance of 4 minutes`). At about 239s it still
queried fx.preview / expense.save; deferred termination also failed at line 51. Cleanup
failure is not established as the originating cause. Stewardship 101.004s and English
140.238s Passed. Three methods each once, non-cloned `34650A96-F547-49BC-BC3B-60EFE0244DEF`,
three Invalid-frame diagnostics; the UI bundle verifier correctly rejects the failed method.
Ordinary 622 Passed / 17 Skipped / 0 Failed, 631 concrete Passed, 49 FX bindings once;
pseudo-long 120.557s, Wishlist 58.593s, AX5 ExtraLarge 203.032s passed without admitting FX/join.
The separate investigation found a 46.953s query interval; original cause remains UNPROVEN.
No documentation-jitter label, allowance increase, retry or unchanged-head acceptance rerun.

Third-run jobs: ordinary `102036452111`, FX `102036451825`, join `102050557510`; original
artifacts ordinary `10054527101` and FX `10053466531`. GitHub metadata and original job logs
were checked directly. Detailed native counts/device binding below are attributed to the
owner's independent review, not a new author all-method artifact audit. Zero test-level retry.

| Third-run failure | Observed boundary, not a causal claim |
| --- | --- |
| FX `testManualForeignCurrencyChineseAX5ExpiredStewardshipEdit` | 109.762s Failed. `fx.active` was present; after rate editing, Done did not enter safe snapshot geometry in 3s. Error at UI-test line 222 explicitly says no tap sent. This is not an FX Enable-button activation failure. |
| Ordinary `testPseudoLongTextKeepsOnboardingAndPrimaryNavigationReachable` | `settings.budget.monthlyIncome` failed the safe-lane condition; target `(196,734.3333,174,65)` has bottom 799.3333 while lane ends at 794. No keyboard in that snapshot. Missing whole-row focus is a known difference, not established as the cause of offscreen geometry. |
| Ordinary `testWishlistAndCoolingOffFlow` | Save was followed by no `dashboard.view` within 5s; the budget form remained, then `tab.wishlist` was missing. Do not relabel the later missing-tab error as the originating cause. |

Ordinary: 633 methods = 614 Passed / 2 Failed / 17 Skipped; 623 concrete Passed, 13 parameter
executions, all 49 FX unit bindings once. FX: three methods once, two Passed / one Failed,
bound to non-cloned `E8F27099-0F64-49FF-9330-721849471677`. Chinese create 195.580s and English
create 114.074s Passed; three Invalid frame diagnostics remain. `--verify-ui-bundle` rejects
the non-Passed stewardship method, as required. Its passing peers do not admit the bundle.
Earlier Chinese legend/CloudSync count/Chinese FX activation failures did not recur; AX5
ExtraLarge 181.534s, both legends and both new budget-label regressions Passed. Those observations
do not clear the three new failures. Keyboard Done geometry/original event causes remain UNPROVEN.

The second run's jobs are ordinary `101700573464`, FX `101700573721`, join `101711782743`;
head/attempt/conclusions were checked directly. Original artifacts are ordinary `10014896092`
and FX `10014180442`. The prior investigation's native audit records ordinary
`retryRunsOneTransportPassAndPausedAccountChangeRunsNone()` line 87: synchronize count 2 vs 1,
not another budget-field failure; FX Chinese AX5 create remained off after one off-track tap.
For the first two failed runs, each ordinary bundle has 609 Passed / 1 Failed / 17 Skipped
methods, 618 concrete Passed; each FX bundle is 2 Passed / 1 Failed. Their fresh non-cloned FX UUIDs were respectively
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
The #119 repair's hosted Chinese FX create used 153.332s / 240s; failed #118 run
`34218693463` used 195.580s / 240s; #120 used 183.322s / 240s (56.678s margin),
the fourth #118 run exceeded 240s, and accepted #121 used 107.546s / 240s.
These observations do not guarantee future runner latency. Three Invalid frame warnings remain.
`makeBudgetSaveReady` still uses `0..<12` without a final post-pan observation; #120 corrected
only `revealBudgetField`. Keep this maintenance debt; no additional helper change in #118.
Failure-only public snapshots remain. Original event causes are UNPROVEN;
no second click or longer press is authorized. Earlier C and D non-passes are untouched.

D remains In Progress; its four checkboxes remain unchecked.
FX-01E, FX-02, COM-C12 and Insights/share implementation remain unentered here.
No Archive, upload, tester assignment, distribution, release or automatic merge is authorized.

This closeout needs independent review, its own exact-head hosted CI/native audit and merge.
Only an explicit final acceptance resolving the checklist assessment may later mark D Done;
the implementation merge and this pending packet cannot do so. Do not start another phase
as a side effect. Future acceptance may be recorded together with the separately authorized
next task rather than inventing an endless chain of self-approving documentation PRs.
