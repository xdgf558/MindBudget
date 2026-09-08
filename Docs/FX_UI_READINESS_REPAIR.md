# Separate UI readiness repair

Current FX-01D closeout: `Docs/FX_01D_CLOSEOUT.md` (implementation merged; D In Progress; E unentered).

Status: **CORRECTIVE_DELIVERY_REVIEWED_AND_MERGED_IN_PR120; PR #118 Draft; D In Progress.**

Current acceptance: reviewed `705d2a7` passed default complete local, hosted `34241669738`
and native checks, then merged as `10e5b13` with owner approval. The original pseudo-long,
Wishlist and stewardship paths passed 110.227 / 60.379 / 93.742s on that hosted repair head.
See `FX_01D_CLOSEOUT.md`, Accepted second corrective repair provenance, for exact identities
and review attribution. It does not replace #118's own CI or prove original unknown causes.
The following source-freeze protocol and pending statements are retained historical checkpoints.

## Historical source-freeze protocol and evidence

The owner authorized this separate repair after the third #118 non-pass. Branch
`codex/fx-ui-readiness-repair` starts from main merge `b364444` (PR #119; second parent
`70fc7c1`), not the documentation closeout branch. It changes test controls, not product UI,
money, calendars, sync, privacy or phase authorization. D stays In Progress, its four
completion boxes stay open, E is unentered, and Insights income/sharing stays queued.

## Accepted baseline versus the newly retained failure

PR #119 was independently accepted and merged. Its exact-head hosted `34182518433`
attempt 1 and default full local `Scripts/validate.sh` passed on `70fc7c1`; local benchmark
216.419208 ms is below the unchanged 500 ms limit. Local Xcode 27 beta 6 / iOS 26.5 is not
hosted Xcode 26.6 / iOS 26.5. Correct #119 hosted FX durations are:

| Method | Seconds |
| --- | ---: |
| `testManualForeignCurrencyChineseAX5ExpiredStewardshipEdit` | 81.518 |
| `testManualForeignCurrencyChineseAX5ProCreateAndDetail` | 153.332 |
| `testManualForeignCurrencyEnglishProCreateAndDetail` | 87.676 |

That acceptance does not explain the old switch/AX-value/ambient-sender causes and cannot
replace #118's own validation. Keep all three #118 runs non-pass: `34097606992` on `5200816`,
`34108994597` on `9c3c6b1`, and `34218693463` on `98345d3`. Do not rerun the unchanged head
or push documentation merely to seek a green result. #118's local ledger work remains separate.

The third run, attempt 1, failed ordinary `102036452111`, FX `102036451825` and join
`102050557510`; artifacts are ordinary `10054527101` and FX `10053466531`. Reviewer native
accounting reports ordinary 614 Passed / 2 Failed / 17 Skipped methods, 623 concrete Passed,
13 argument executions and 49 FX bindings once. FX methods ran once on non-cloned
`E8F27099-0F64-49FF-9330-721849471677`: stewardship Failed 109.762 s, Chinese create Passed
195.580 s, English create Passed 114.074 s. Three Invalid-frame warnings remain. Author
inspection below concerns the original failed-method activities/attachments, not a new hosted
execution or an all-method author audit. Zero retry does not turn these failures into passes.

## What the original artifacts establish

### Settings: an unobserved final pan

`testPseudoLongTextKeepsOnboardingAndPrimaryNavigationReachable` fails inside read-only
stored-budget verification. Last sampled income frame `(196,734.3333333333333,174,65)`
crosses the unchanged safe bottom 794. The helper performs its twelfth permitted pan and
then fails without observing its result. The original recording at actual 95.996667 s shows
the lower income position; at actual 99.995 s, after that last pan, the `3000` editor is
visibly inside the unobscured area. This is not a failed Settings focus tap or evidence that
the saved amount is wrong. The final visual is not substituted for the missing AX check.

Correction: N permitted pans now have N+1 observations, including the final result. Keep
the same twelve-pan cap, coordinates, gesture duration, strict full-frame lane and hittability
checks. A deterministic test proves final-pan success can be observed, persistent absence
still stops at twelve gestures, capture failure stops, and the recorded unsafe frame still
fails. No thirteenth pan, field focus, value waiver or Settings Save is added.

### FX Done: valid recorded geometry, opaque waiter outcome

The kept single-tap trace contains one snapshot at elapsed 1.324054084 s. It has enabled Done
`(318.66666666666663,524,62.333333333333314,36)` inside app `(0,0,402,874)`, keyboard
`(0,583,402,233)`, and `fx.rate=3`. These frames satisfy the existing `doneTapOffset()` rule.
No Done tap was emitted. The former error discarded the actual XCTWaiter result, predicate
completion time and readiness decision, so the specific scheduling cause is **UNPROVEN**;
the record does not establish unsafe Done geometry, a lost Done tap or an invalid keyboard.

A separate local macOS XCTest probe (no App or simulator) demonstrates the control hazard:
the first predicate invocation starts about 1.03 s into a 3 s wait. A synthetic 2.1 s valid
capture therefore produces timedOut, whereas shorter captures complete. This is a bounded
reproduction of timer-budget consumption, not proof that the identical delay caused hosted.
The corresponding immediate-poll macOS probe accepts a 2.1 s capture at 2.106825 s and rejects
a 3.1 s capture at 3.101254 s, each with one observation. Neither probe executes the product.

Correction: observe immediately under an explicit monotonic 3 s deadline; include capture
and classification time and reject even a valid sample completed at/after the deadline.
Only observations may repeat; activate exactly once from the accepted immutable snapshot,
then apply the same 3 s deadline to Done-and-keyboard disappearance. Snapshot errors fail
immediately. Trace capture start/end, rejection/acceptance and deadline outcome. Do not extend
either wait, accept an out-of-time sample, send a second tap or pan after failed dismissal.
Injected-clock tests cover immediate observation, valid-but-late rejection, persistent absence
and capture errors. Existing geometry/lost-tap negatives remain.

### Wishlist: independent direct setup bypassed the accepted Save control

`testWishlistAndCoolingOffFlow` had its own direct tap/type/Save sequence, unlike the shared
setup. Its event archive describes one planned Save tap at `(201,506)`; the later hierarchy
still shows budget setup and values 3000/2500/500, with savingGoal focused. A planned event
does not prove app receipt or identify a recognizer. Original Save dispatch/commit cause is
**UNPROVEN**; the later missing Wishlist tab is a dependent failure, not the cause.

Correction: use `completeBudgetSetup`: one focus/type per amount, the accepted single-snapshot
safe Save, one Dashboard handshake and exact independent readback through a newly loaded
Settings form. Stop on failed setup; never navigate to Wishlist after failure. The actual
wishlist/add/cooling-off assertions remain. No second Save or product focus change is added.

## Evidence index and remaining acceptance

Original/derived local files use the task-owned `fx-readiness-evidence` directory. No original
artifact is overwritten. Hashes are content identifiers, not a claim that derived pictures are
new runtime or accessibility proof:

- Original FX trace SHA-256: `98614bc8456c4db5b65e1f6399ceb762bebfdb11738c9a76ca2379479cc55f3e`.
- Original pseudo-long recording SHA-256: `e5fd59b25a12f05e3419b11b966c8c2c9bc1a3e0e493fe30456f06b9de0c7d40`.
- Final video frame (actual 99.995 s) SHA-256: `18c58052eb60a4c9500e3d9fd46b3e3907a0df15846e950f6385893ccdcee0da`.
- Synthetic macOS waiter-probe log SHA-256: `5a9117c848f24099ea1d3231645ab116dcb66cd994046a3870b1b8337dce012a`.
- Immediate-poll counterpart log SHA-256: `5a27a064c1686dce2ce28c30094e4389a53ff0269faed9cabfd2880d7fab60eb`.

Focused local execution passed on UI-test SHA-256
`6d04fef09679a8cb16afd8116a422d5ec40fe2bab0de0ed7f7fdadf0371ff0ef`:
six ordinary methods once, including the original pseudo-long path (132.590 s), Wishlist
(47.043 s) and four deterministic/readback tests; native audit found no warnings, Repetition
or extra attempt. The ordinary device is the task-created
`3D6221D5-39DF-4CD4-ADEE-472B4139F47B`, iOS 26.5, local Xcode 27 beta 6.

The isolated FX runner also exited 0, with three methods once, no Repetition/extra attempt,
all native device bindings matching new non-cloned `D40E5901-B53F-45C9-987B-3C426F7DD243`.
Stewardship/create-zh/create-en durations are 61.229 / 79.834 / 58.119 s. The three existing
Invalid-frame warnings are retained. The runner removed only its owned temporary FX simulator.
The complete local validator has **not** run at this source-freeze checkpoint; these local
checks are not hosted Xcode 26.6 evidence. Test source stayed unchanged throughout both runs.
The new stewardship trace records the same Done/keyboard frames as the failed attachment:
capture starts immediately, geometry is accepted at 0.3231585 s, one `(349.83333333333326,542)`
tap is emitted and the following snapshot has neither Done nor keyboard. Trace SHA-256:
`9eea342de0f007f9d392546747df2dba401e2dec3707f12978258bd598b0f142b`.
Matching frames and successful corrective control are not retrospective scheduling proof.

This is not full-local, hosted, independent corrective acceptance or permission to merge.
Freeze the final head and run default complete `Scripts/validate.sh` with the unchanged 500 ms ceiling,
zero retry and isolated three-method FX host. Exact-head hosted ordinary + FX + join must then
pass and native details must show no Repetition/extra attempt, all required bindings once and
FX device IDs matching the fresh non-cloned provenance UUID. Independent review is required.
Keep any intervening non-passes. #118 is not undrafted or merged by this work; D is not Done.
Later exact-head full-local/hosted results belong in the execution receipt and PR checkpoint;
do not reinterpret this pre-execution paragraph as a claim that those checks already passed.
Inherited debt remains: main has no required check, the 600 s boot and 240 s FX ceilings stay
unchanged, two older hidden-retap calls are outside this scope, and real CloudKit/mixed-version/
cross-calendar coverage has not run. This repair does not certify those paths or erase warnings.
