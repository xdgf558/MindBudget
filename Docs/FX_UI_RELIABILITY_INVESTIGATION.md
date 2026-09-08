# Separate UI / synchronization test investigation

Status: **INVESTIGATION_IN_PROGRESS; no corrective acceptance; PR #118 remains Draft.**

The owner authorized a separate investigation/repair after the second PR #118 review.
Branch `codex/fx-ui-reliability` starts at merged PR #117, `d19c6401bc14d2b43365b0936a37fe270e39c481`.
It does not add test changes to the documentation-only closeout branch, rerun that branch,
check D's four completion items, mark D Done, or enter E. Sharing remains queued.
Zero retries, single activation, the 240-second FX allowance and the default local 500 ms
benchmark are unchanged. A diagnostic success is not a repair or acceptance.

## Current budget-row focus candidate (2026-09-08; not accepted)

Owner requested the actual repair before pushing to #119 and allowed the sanitized evidence
summary to be published there. Product Design context/brief reused the existing budget Form
and AX5 screenshot: no layout, font, copy, new button or keyboard toolbar is introduced.
The three amount HStacks now have a rectangular touch area and a simultaneous single tap
that assigns their existing field-specific FocusState. Native TextField interaction remains;
no focus-on-launch, high-priority/long-press gesture, second tap, observer or debug override.
The original AX1→AX5 field-center activation test and its five-second keyboard wait are
unchanged. The shared Save/readback code is only extracted, not weakened or bypassed.

Two new real-app English/Chinese AX5 regressions begin without a keyboard, capture label and
editor from one snapshot, prove their tap point is outside the native editor, activate once,
type 3000/2500/500, Save once and independently read the exact stored amounts in Settings.
This is a product focus-control test, not a test-only model injection or live AX-value waiver.
The before candidate adds only label identifiers/tests, without the gesture: its single English
regression failed once (15.563s, exit 65), with no keyboard after tapping label `(104.5,541)`.
Native detail confirms one Failed, no expected failure or retry; diagnostic archive collection
also retained the existing missing-simctl exit 72. This demonstrates missing label activation,
not reproduction of the historical editor-center failure. No historical cause is relabelled.

Before/after locally retained source patches are `fx119-row-focus-before-source.patch` and
`fx119-row-focus-after-source.patch`, SHA-256 respectively
`ae90aec852296cbbb4b01256163f896259e4ea62873f90cda6885c61dd30a482` and
`79730b0223bda59136fb1548c38a298958a5056269fa1b7f9de430d2f5818edf`.
Their only product behavior difference is the six-line row gesture/content shape. Logs and
native bundles use `fx119-row-focus-before` and `fx119-row-focus-after` artifact prefixes.
Current OnboardingView SHA-256: `e1a62517e63532a5782662a4b0a7ec829be58a8c132a712ac63813318e134fb3`;
UI-test SHA-256: `2669a25ab2f4894946aba03244b90c20992c36ffc12f1efabb2bfb418573ae6a`.
After candidate passed four focused methods once (exit 0): original AX1→AX5 107.353s,
Chinese AX5 label 56.344s, English AX5 label 63.748s and Chinese legend 93.386s. Native
`fx119-row-focus-after-audit` confirms four concrete Passed, no Repetition/extra attempt,
and zero runtime warnings. All use local Xcode 27 beta 6 / iOS 26.5, not hosted 26.6.
Side-by-side English AX5 pre-activation screenshots retain the same layout, typography,
colors and controls; small scroll-offset/clock differences are not claimed pixel equality.
Before/after PNG SHA-256: `d9a9bce7a98813a1e6633c8acbbde13584ab5138dc38ff141aa7a015c94d7eb3` /
`a17d71adde36bb2d200aaf5373733cf08a0188c930ac4eed7fe21853f7697c8e`.

**Source-freeze checkpoint:** the full default validator has not run at commit preparation.
Freeze this source first, then run it once with only the selected Xcode/destination/result-path
environment, no skip/retry override. Its later exact-commit result and hosted run must be
reported in the PR execution checkpoint before acceptance; the focused result above does not
pre-approve those executions. Do not push as a completed repair if the full validator fails.
Original dispatch/recognizer cause remains UNPROVEN. Corrective acceptance requires complete
local validation, unchanged 500ms, exact-head hosted/native and independent review, not the
bounded before/after result alone. #118/#119 remain Draft; no D checkbox/Done or E entry.

## Previous owner-authorized button checkpoint (2026-09-08; not accepted)

**Subsequent hosted non-pass:** exact head `2c61da2`, run `34169377668` attempt 1 failed
ordinary `101886617002` and join `101893454890`; FX `101886616887` passed. GitHub artifact
IDs: ordinary `10035940628`, FX `10035486867`. The owner's native review reports ordinary
AX1→AX5 `testAccessibilityExtraLargeKeepsPrimaryActionsAndNavigationReachable` failed at
line 2646 after one budget focus tap (175.411s), pre-tap target `(185,494.67,185,64)`,
`keyboards=[]`. The 17 focused final-source checks did not include that method. Author
artifact inspection is recorded below; no transient/root-cause or complete-local claim is made.
The reviewer reports all three FX methods once, device-bound to fresh non-cloned
`0AF194A1-40F4-45B2-8134-947D8E293C17`, durations 103.876/148.216/114.280s and three
invalid-frame warnings. The Chinese legend pass (165.608s) is not AX1→AX5 acceptance.
The complete-local/hosted/native/review gate remains open; both PRs stay Draft and D/E locked.

### AX1→AX5 budget focus: artifact inspection and rejected hypothesis

Author native inspection of the downloaded ordinary artifact confirms 613 Passed / 1 Failed /
17 Skipped methods, 622 concrete Passed, and only the 175.410755s accessibility method failing.
The call stack identifies `completeBudgetSetup` line 1699 (`budget.monthlyIncome`), invoked
from the second AX5 launch at line 1146. AX1 setup and its stored-value verification finished.
Failure precedes AX5 typing, Save or Settings readback. The final hierarchy retains the same
`(185,494.6667,185,64)` income field and no keyboard. Original pre-tap/final snapshots and
video show no obvious intervening overlay or field displacement. The archived synthesized
event specifies `(277.5,526.6667)` down/up with a planned 0.05s offset; that is not app-side
receipt or gesture-consumption evidence. Slow event/query processing is observable, its
cause is not. Unit execution finished before ordinary UI, so concurrent units are not a
supported explanation. Original artifacts remain non-pass, not transient or corrected.

Author FX audit confirms three methods/three concrete Passed, no Repetition/extra attempt,
and three runtime warnings. Device provenance records `cloned: false` and the UUID above.
This is local Xcode 27 beta 6 artifact reading, not hosted 26.6 re-execution or ordinary repair.
Locally retained evidence prefixes: `fx119-34169377668-ordinary-artifact`,
`fx119-34169377668-fx-artifact`, `...-ax-attachments`, `...-fx-audit`;
native ordinary summary/detail/activity JSON and job log use the same run-number prefix.
Video files named `...-ax-video-149.png` and `...-ax-video-173.png` have actual decoded
timestamps 139.22s and 164.276667s respectively, not the requested filename timestamps.

Two local one-method probes investigated whether the AX field center misses its native editor.
Both used Xcode 27 beta 6 / iOS 26.5, owned ordinary simulator
`1B6529A0-D847-4757-9A08-C7DEDC08E376`, zero retry, no parallel testing and unchanged 240s
allowance. Each native audit reports one Passed once, zero extra attempts/Repetition/warnings.
Probe 1's environment flag did not reach the runner: no activation or app trace, so no
mechanism evidence. Probe 2 explicitly enabled the flag and a temporary DEBUG-only public
UIKit timer logging view bounds, textRect, hitTest and first-responder state. At AX5, the
income field `(185,509,185,64)` center hit UITextField before focus; it subsequently became
first responder at `(185,501.3333,185,65)`. Same dimensions do not mean the identical hosted
state. The blank-center hypothesis is unsupported locally; the hosted focus failure remains
UNPROVEN. A timing-affecting sampler and a passing probe are not corrective acceptance.

Retained `fx119-budget-hit-probe-1` and `fx119-budget-hit-probe-2` prefixes include source patches,
build/runtime logs, xcresult bundles and native audit directories. Probe-1 source SHA-256:
`79ee944917ff01849322a6f0fe609f945d05fd5f0a22b56d507bcd7f27a625fc`;
probe-2 source SHA-256: `cfdccbd0a271d52c0f76831d834d402d63b687d281e3ca8edbb8b108b3f4ca9a`;
probe-2 unified app log SHA-256:
`da2973bbcd1077565aee741493c8bc647d9a895f3c4c805848cf14ce4fe1095f`.
No gesture/touch observer, swizzle, fault injection, long press or retap was used. All probe
code and launch flags were removed; product/test source matches `2c61da2` exactly again.
No full validator, new hosted run, new source commit or corrective acceptance follows from
these observations. Next investigation must distinguish focus/event delivery with evidence;
do not change coordinates or repeat activation merely to obtain a green result.

The owner permitted replacing the sliding switch with explicit localized Enable/Cancel buttons.
The product reuses its existing card/secondary style; saved FX has no Cancel. Existing Pro/trial,
expired stewardship, draft restore, actor authorization and money/calendar rules are unchanged.
The test no longer targets a native switch track: one immutable snapshot supplies a wholly
visible button center; one tap must expose/remove the real FX fields in the unchanged three
seconds. Unknown state fails. English also checks Free denial and explicit cancellation;
the fixed three FX host method identities and limits are preserved. Focused final-source local
runtime/visual checks passed as recorded below; complete-local and hosted acceptance remain open.
The old switch cause is still UNPROVEN and all old failures remain.
This authorizes #119 implementation only, not acceptance or #118/D/E progression.

First button candidate compilation was non-pass, before any runtime test: synchronous
`XCTWaiter.wait` was placed in the existing async scenario. Both ordinary build (exit 65)
and the FX runner (build exit 65 / wrapper exit 1) caught it. The fresh runner device
`3462EA1E-55CA-4651-A969-A25A396D52F7` was ownership-checked and removed; no result bundle
or runtime success exists for it. Moved the Free-denial check to a synchronous MainActor helper,
retaining its three-second wait. Also reused the existing fail-closed keyboard snapshot for
mode transitions and included the new mode buttons in failure-only traces.
Retained `/private/tmp/fx119-explicit-button-1` source/log SHA-256:
`2302c2e858114b613e7d1b73018b98d1523b18ecb57203ed479b8c32b09bf993` /
`e9e5b87d7a0ef6ea646c9bdeb35122cbf199194727f470802f686a4e73b87a94`.
Ordinary failed-build log SHA-256:
`3a586dfa5a8f2d67166fd99c46d320cd1fd4574f57520c2e52bf6f547ce97fad`.

The corrected ordinary candidate passed 17 focused tests once (15 form unit tests, one
button-state/geometry test, one independent saved-budget round trip); native summary and all
17 details show no Repetition, extra attempt or warning. `/private/tmp/fx119-explicit-button-ordinary-2`
retains its bundle/log/audit. The parallel FX-2 binary was already fully built before a final
source hardening: preserve the original UI prohibition on Enable whenever an existing expense
has FX metadata, including an unsuccessful form load. Neither its focused ordinary nor FX-2
results can be attributed to that final product-source change; final-source verification follows.

### Final button source: focused local verification, not full acceptance

Candidate 2's frozen FX binary also passed its three methods once: expired stewardship 83.811s,
Chinese AX5 create/detail 89.998s, English create/detail 76.010s. Native audit retained three
invalid-frame warnings and no Repetition/extra attempt. Its fresh non-cloned device was
`56227247-A2B4-4101-8807-4FE40742D256`. This is pre-final-guard evidence only, not attributed
to candidate 3. Candidate-2 source patch/log SHA-256:
`839af6a09a1769138a3b1f23e43c4f426da7587900d8293c6ae11729985eb246` /
`d2e900fa15a2fe1527a62a1149445bded0af3e5b32a7f0bd40eb50ed0c09d1c8`.

Candidate 3 includes the preserved existing-FX Enable prohibition. All execution below used
local **Xcode 27 beta 6 / iOS 26.5 (23F77)**, not hosted Xcode 26.6.

| Final-source check | Actual result |
| --- | --- |
| Ordinary Debug build and focused bundle `fx119-explicit-button-ordinary-3` | Build/test exit 0; 15 existing form unit methods, button snapshot negatives and fresh saved-budget round trip: 17 Passed once; no Repetition, extra attempt or runtime warning |
| Isolated FX bundle `fx119-explicit-button-3` | Runner exit 0; expired Chinese AX5 stewardship 66.318s, Chinese AX5 create/detail 85.490s, English create/detail 80.195s; three Passed once, no skips/Repetition/extra attempt; three retained invalid-frame warnings |
| Ordinary scheme Release simulator build `fx119-explicit-button-release-3-build.log` | Build exit 0 only; not Archive, IPA, physical-device or release evidence |

Native summary/tree/detail audits are retained under each ordinary/FX `-audit` directory.
Every FX detail binds to fresh, non-cloned provenance UUID
`3E13EC47-9C4D-499A-B112-8D3DD9CF17EA`; the runner verified and removed only its own device.
Ordinary focused execution used owned UUID `1B6529A0-D847-4757-9A08-C7DEDC08E376`.
The FX logs additionally retain Xcode diagnostic archive collection's missing-simctl error
(exit 72); normal runner/device verification succeeded, but a complete diagnostic archive is
not claimed. Neither the warning count nor the archive error is silently discarded.

Final-source XCTest attachments were visually inspected against the prior AX5 switch screen:
Chinese AX5 `701E95F9-3ABF-4039-BD2D-07CB1F3EDE05.png` and English
`4978697E-A1B7-4A7A-AF74-E049CA69DAD7.png` show the existing card and a fully visible, wrapping
Enable button without label clipping. These are synthetic in-memory test-host screenshots,
not a physical VoiceOver/complete appearance or contrast matrix. The Chinese transition trace
`893BC0C2-D790-41B2-84E1-D5E842CB0769.txt` records the inactive button frame
`(36,132,330,79.3333)`, one center tap `(201,171.6667)`, then active real FX fields and Cancel.
English has separate successful enable/cancel/re-enable traces, not a failed-tap recovery.

Final source SHA-256:

- `ForeignCurrencyEntrySection.swift`: `0c1ae0465d9369c9b3ae39c671f154531a770e0588ad9ec463f9b86f29d0b1b5`
- `Localizable.xcstrings`: `a53143ed5b8be8c22ade2694c412cc5204a6b5ba6534450ec1cdca162286750d`
- `ForeignCurrencyFormTests.swift`: `3f854f4add70e3838ed5c92543056acf688431d245acc223ed1b2df92077f82b`
- `MindBudgetPhase3UITests.swift`: `c261c95ce923e3f4480b20ea258b0edeae772b343b4889ebab1fc81664b5120d`

Artifacts remain under `/private/tmp/` with the table prefixes, `.xcresult`, `.log`,
`-build.log`, `-audit` and FX `-attachments` / `.simulator.json` as applicable.
Final candidate source patch SHA-256:
`9c204cf1e8ec37bd124f8408b86160d7aed29a0deab27c3963becf9f5c385190`.
Ordinary / FX / Release log SHA-256 respectively:
`8bc5a5b269fecc76264f9f86c96695e40d2d55d59d152924bbc5803d035897d7` /
`44b20db536e81685722ec473fd55865f508bba7c558f1107c346940de299e5e4` /
`ff9f662b8a2a8bcb7e7572e5f8ecb5b1e8fee015dd736f994ddb74ddfddf5981`.

The pre-publication validation session did **not** run the default complete `Scripts/validate.sh`
or its 500 ms benchmark, obtain a new exact-head hosted result, or independent approval.
The owner subsequently requested publishing this source for review in existing Draft #119;
that request authorizes a commit/push and PR update, not acceptance or merge.
The complete-local/hosted/native/review gate remains open;
#118/#119 stay Draft, D's four items stay unchecked, D is not Done and E/sharing stay unentered.
All five final static gates (money/network/COM docs/StoreKit/FX) and diff whitespace passed;
project/schemes and `Scripts/` are unchanged. These are not complete-runtime evidence.

## Prior budget-only correction checkpoint (working tree; not accepted)

The keyboard-Done attempt below is **withdrawn**: default validation caught its conflict with
the accepted 2026-08-07 one-commit UI rule. The product file is restored; the original no-toolbar
assertions remain. Current test-only work instead keeps one Save and verifies all three values
from a freshly loaded Settings budget (DataActor plan projection), without focusing/editing or
saving that second form. The synthetic store is in-memory; no disk/relaunch durability claim.
Focused validation now exists for this replacement as detailed below. Full validation and
independent corrective acceptance are still pending. FX activation remains open.

The current implementation removes the unconditional second field-focus tap and the two-Save
handshake from the shared budget path. Its five-second exact amount check reads the newly
loaded Settings form, not the active onboarding draft. A dedicated parser rejects wrong,
empty/nil values, duplicate/disabled/offscreen fields, wrong forms, invalid raw frames,
keyboards, menus and alerts. Return navigation uses one captured native BackButton and the
root's single trailing dismissal action; extra actions/unknown geometry fail rather than retap.
No second-form editing, extra app launch/reset or disk-store access is introduced. Product
source and the original no-keyboard-toolbar assertions remain unchanged.

| Local replacement run | Source / validation boundary | Result |
| --- | --- | --- |
| `fx119-budget-persisted-1` | First negative fixture incorrectly assigned an immutable snapshot value | Compile exit 65; no tests; retained non-pass |
| `fx119-budget-persisted-2` | Immutable fixtures; fresh Chinese Settings readback, not yet return navigation | 2 Passed once; actual stored values 3000/2500/500; no warnings/Repetition/extra attempt |
| `fx119-budget-persisted-3` | Full Settings round trip plus navigation negatives | 6 Passed once: large-text path 112.616s, stored-value round trip 36.909s, value negatives 0.048s, navigation negatives 0.044s, English legend 101.314s, Chinese legend 92.940s; no warnings/Repetition/extra attempt |
| `fx119-budget-persisted-4` | Final raw-frame guard hardening; remove the no-return diagnostic parameter | Build and 3 checks passed once: stored-value round trip 30.769s, value negatives 0.056s, navigation negatives 0.047s; no warnings/Repetition/extra attempt |

All use Xcode 27 beta 6 / iOS 26.5 and owned ordinary UUID
`1B6529A0-D847-4757-9A08-C7DEDC08E376`. The large-text method is the existing ordinary
accessibility-extra-large scenario, not every FX/physical AX5 matrix. The `persisted-2` trace
`D6BD7371-98EA-426B-8BD2-11F238EB437F.txt` records all three exact amounts and BackButton identity.
`BudgetSettingsView.load()` obtains these strings from `DataActor.previewPlanCoverage`,
not the former BudgetSetupViewModel instance. Native summary/tree/details were audited for
each passed run; the focused final-source run does not stand in for the complete validator.

Final UI source SHA-256 `160ca93fceb6215f97f029392c0f1d06824c912e07ddaf3c48a843ed5cd7d632`.
Final `persisted-4` patch/log:
`8f79e54b24263dc2f489f9e1edc827e5587e051deaa1d942a3d148ac838a2d63` /
`9779f1eb3aab9ef4dea9037783e1b96efc1dd5d14325bc3f6966ef503c8de6a1`.
`persisted-3` patch/log:
`ea86349db65b3fd6ed0c3ae26a0af0e0ec66c0d65bc8f155df9b9f5ba2748724` /
`ca043b7df077a881bfbdd64b13c692e35669f5443d53fae6f7b1da5a62866648`.
`persisted-2` patch/log:
`a7ca0a2c82648943835d9916d9d1dbc88331c5eca5f4f703b00f256ccc62aaf8` /
`91388260792f5647f685eaa19e8df53daa798d40a5b4a3d20836cdfb47eea1fa`.
`persisted-1` failed-build log:
`dfc3176ab805b02d2ccd42e37a9f33aff2e47bee069b12ba35f017576b8fcb3b`.
Each `/private/tmp/` prefix retains source patch/build/test logs, xcresult and native audit
when applicable. The six-method run precedes final guard hardening; no new default full-local
pass or exact-head hosted result exists. All five static gates and diff whitespace passed.
No new commit, push, PR mutation, merge, D checkbox, D Done or E entry is implied.

### Withdrawn keyboard-Done attempt — retained non-pass

The owner requested actual repair. The attempted BudgetSetupView reused the existing FX
numeric keyboard's localized Done pattern, clearing its existing FocusState. The UI helper
removes the unconditional second focus tap and the return-to-income commit workaround. One
snapshot-bound Done tap must remove both toolbar and visible keyboard before the unchanged
exact 3000/2500/500 readback; one final safe snapshot supplies one Save tap. The previous
two-Save handshake is removed from this budget path, not retained as a fallback. Another
unrelated legacy caller of `tapAndWaitForDestination` remains maintenance debt.

The shared keyboard parser is explicitly bound to budget or expense form type/identifier and
its own Done identifier. Deterministic tests reject wrong forms, duplicate/disabled/occluded
Done controls, a selection menu, lost activation, and a remaining keyboard or toolbar. This
repairs the known implicit end-editing / double-tap control gap. The original failed AX value
was never captured, so its precise historical cause is still **UNPROVEN**, not called transient.

Focused local `fx119-budget-keyboard-repair-2` build and test exited 0 on Xcode 27 beta 6 /
iOS 26.5, ordinary UUID `1B6529A0-D847-4757-9A08-C7DEDC08E376`: English category legend
83.565s, Chinese category legend 81.187s, new budget snapshot contract 0.125s, existing FX
keyboard snapshot contract 0.056s. Native summary/tree/four details close at four Passed
concrete executions, no Repetition/extra attempt, and **two retained invalid-frame warnings**.
The initial audit invocation incorrectly expected zero warnings and failed; after inspecting
both summary warnings, the corrected audit counted two. This was not a runtime rerun.
The Xcode log also reports diagnostic collection unable to locate simctl (exit 72); no
complete simulator diagnostics are claimed. Explicit snapshots and native test results exist.

The Chinese trace `2AC9ED90-E8B6-4541-BC15-43BB76734606.txt` records three exact values before
and after one Done at `(353,542)`. Before: Done `(325,524,56,36)`, keyboard `(0,583,402,233)`;
after: both absent and all three values unchanged. English has the corresponding own trace.
The real methods then performed exact readback, saved once and reached the category chart.
These two language scenarios use their ordinary text size, **not AX5 coverage**.
Product source SHA-256 `00c0f384525883809f0c5793e5c46d32e9e0dbc3c72868d9cf097a387f1f0659`;
UI test source SHA-256 `24785d036bdeb6bbac248720ed352054e44237dbb41dbc2e1ee9a1cb0b762f4e`.
Source patch SHA-256 `00c789c611bf4de3f4309222d9a8914aee26cadb45768051ef8eb487b316aae0`;
log SHA-256 `770600ddd70f3c3166e158fb2243e6d023f0d9b090c7ae5485166f669746cde3`.
An earlier incremental build (`repair-1`) passed compilation only. After `repair-2`, optional
before/after keyboard screenshots were added to the two category-legend methods for visual
review. That follow-up is not the exact UI source fingerprint of the focused run above.

Artifacts are `/private/tmp/fx119-budget-keyboard-repair-2` with `.xcresult`, `.log`,
`-build.log`, `-source.patch`, `-native-audit` and `-attachments` suffixes. Full default local
validation, exact-head hosted/native evidence and independent corrective review remain open.
FX switch activation is unchanged and unresolved; no D item, D Done or E entry is earned.

Default `fx119-budget-repair-full-1` passed static gates, Release/Debug compilation and one
217.268 ms benchmark under the unchanged 500 ms ceiling, but failed the explicit no-keyboard-
toolbar assertion in `testOnboardingAndManualExpenseFlow` (one button versus required zero).
The author then sent SIGINT only to this run's verified xcodebuild PID 42658; wrapper exit 75.
Native summary: 605 Passed / 2 Failed / 17 Skipped methods, 614 Passed concrete executions;
one failure is the real contract conflict, the second is cancellation of the pseudo-long test.
Ten invalid-frame warnings remain. Remaining ordinary methods, coverage/acceptance checks and
FX host were not completed; this is a retained incomplete **non-pass**, never full validation.
The source patch/log and full exported attachments use that `/private/tmp/` prefix. The
benchmark bundle is separately retained as `-benchmark.xcresult` with its one-run native audit;
its success does not salvage the incomplete validator. Full-1 log SHA-256:
`da5977c054765c2752e9ffebe8396adbec5827d35f134d76c86e14614a881b3e`.
All keyboard-Done source/test changes
were removed before the replacement. An initial reverse-patch formatting error made no edits;
the corrected scoped patch restored both source paths to reviewed `604caa9` before new work.

### Minimal-control switch comparison, not a repair

`fx119-minimal-controls-1` compared direct UIKit UISwitch, a switch in a native scroll view,
and SwiftUI Toggle in a ScrollView, each with a baseline and a bounded display-link-only
50 ms stall (30 Hz scheduling, first 30 seconds). All six unique methods passed once, zero
Repetition/extra attempt/warnings, local Xcode 27 beta 6 / iOS 26.5 on the previously owned
F7A device. Each used one native 0.75-width tap, the unchanged three-second wait and exactly
one value-change count. Durations: 7.681 / 7.176 / 6.817 / 7.965 / 6.768 / 7.229 seconds.

Unlike the earlier induced failure, no existing recognizer observers or recursive hit-path
sampling were installed; the stall was not inside gesture targets. No failure was reproduced.
This weakens extrapolation from the earlier observer-perturbed failure; it does not prove
the historical cause, that the native control is universally reliable, or that app code
must be at fault. All temporary host/tests/scheme changes were removed before the actual
budget candidate. No swizzle, stall, minimal root or bypass fixture is in the candidate.
Patch hash `703b4059499ddb3eb63f046225b9797cf84a7d97385091d799ad0c026130e86a`;
log hash `98da1610066f3b3e555bc7968b5c486d524387c4fd2b3acf33699bbcd3a51a02`.
The result, source patch, audit and event log remain under `/private/tmp/fx119-minimal-controls-1`.

## Retained native failures

Both runs below are attempt 1 with ordinary, FX and join failed. The author downloaded
the original artifacts and read summaries/details with local Xcode 27 beta 6's native
`xcresulttool` (no schema override). This is artifact inspection, not execution on hosted
Xcode 26.6. Both hosted destinations report iOS 26.5 / build 23F77.

| Run / exact head | Ordinary failure | FX failure | Original artifacts (ordinary / FX) |
| --- | --- | --- | --- |
| `34097606992` / `52008165d1faf4a03a92d282cdb036b2bcaf3c8c` | Chinese category-legend UI, `budget.savingGoal` readback timed out at line 1682 | Chinese AX5 create, switch did not enable | `10010259290` / `10009729091` |
| `34108994597` / `9c3c6b1d905c4e4f0c9f1cf903bc924f572ce19d` | `CloudSyncTests/retryRunsOneTransportPassAndPausedAccountChangeRunsNone()`, line 87: synchronize count 2 rather than 1 | Chinese AX5 create, switch did not enable | `10014896092` / `10014180442` |

Each ordinary summary is 609 Passed / 1 Failed / 17 Skipped methods (618 Passed
concrete executions). Each FX summary is 2 Passed / 1 Failed, not an accepted suite.
The first FX device is `FE266090-65CD-4ADC-9D71-08A5712AC89F`; the second is
`D3932B37-3B3C-4A3B-85BC-D97E2B62B201`. Neither is a cloned destination.
The two FX summaries retain invalid-frame warnings; these are not proven causes.

### Switch: observe actual post-tap state separately

Both pre-tap geometry attachments report row `(36,132,330,125.3333435)`, native child
`(305,180.6666667,63,28)` and trailing-quarter point `(352.25,194.6666667)`.
The helper's error description prints the **captured pre-tap** literals `rowValue=0,
childValue=0`; those two literals are not an independently captured post-tap child state.
The second run's separate post-tap debug attachment `1071676A-1BBE-44EE-B24A-962A21C4D13E.txt`
does show the identified row value 0. Its video `5BC3EBA6-1CCA-4813-8A0D-7899E1E5131C.mp4`
also shows the switch off after the synthesized event. This is a real failed activation,
not proof of the private recognizer or dispatch mechanism. Do not revive the removed observer
or claim that another green run makes the off-track choice universally reliable.

### Budget: visible input and readback are different observations

The first ordinary failure's video `840D8787-D90D-44C7-8D4C-044DDB93349A.mp4` shows
income 3000, spending 2500 and saving goal 500. At video time 16.988 seconds, the saving
field still has the insertion caret. At 23.800 seconds, focus is visibly on income and
the Select / Select All / AutoFill menu is open; saving still visibly reads 500.
The activity tree records two income taps after typing 500, then the three readback
assertions; only saving fails. Thus a claim that 500 was never entered is not supported.
The raw failing predicate did not retain its actual returned value. The archived XCTest
snapshot attachments contain pruned application roots, not a readable three-field state.
Do not infer whether this was stale accessibility, a different returned value, or a lookup
problem without a readable post-input snapshot. Keep the assertion until evidence supports
a replacement with equivalent or stronger persisted-value verification.

### Synchronization: investigate ambient notifications separately

The second ordinary failure is not a repeated budget UI failure. Its first count assertion
(line 80) passed, paused-account status passed, and only the final cumulative count failed.
`CloudSyncService` currently observes process-global `NotificationCenter.default` local-change
signals; those signals carry no store identity. The test's `.serialized` suite does not
serialize other Swift Testing suites, which also mutate isolated in-memory stores and post
that same signal. An unrelated event can therefore request another pass between the two
account-binding awaits. This is a concrete isolation gap in the fixture; the original
artifact does not identify the specific notification sender or prove a transport ran after
the pause. A controlled notification-source test is needed before calling it resolved.

## Rejected local label-route probe

`fx-reliability-label-probe-1` is a **non-pass**, not a repair. From the merged base, a
temporary test-only geometry candidate used the midpoint of the row area to the left of
the native switch (8pt gap), guarded as inside the row/lane and outside the native child.
It still issued one normal tap with the unchanged 3-second value wait. No product view or
binding changed. The compiled UI test file SHA-256 was
`dc695dc7a96a072a9d93f68724056a362dbd7bf3161b631aaa66abb5c136a7fe`.

The isolated runner created `3D1B617A-AEE2-4E6F-BF85-73DE99CE8B2D` and ran each method once
on local Xcode 27 beta 6 / iOS 26.5. Stewardship passed in 64.942s; Chinese create failed
in 14.273s at label point `(166.5,194.6666718)`; English create failed in 12.578s at
`(166.6666667,146)`. Both were still off after the single activation. `xcodebuild` exited 65
and the wrapper exited 1; the runner removed only its owned simulator and retained evidence.
The result is `/private/tmp/fx-reliability-label-probe-1.xcresult`, with adjacent `.log` and
`.simulator.json`. The candidate geometry and its changed tests were reverted with a patch;
the UI file was verified byte-identical to the merged base before adding failure-only traces.
Do not interpret this as a failed hosted retest or as proof of a UIKit recognizer mechanism.

## Current corrective / diagnostic work

Review follow-up: all ten explicit synthetic `CloudSyncService` construction sites now inject
a fixture-owned center (nine in `CloudSyncTests`, one in `Phase6FeatureTests`). The offline
deletion/restart fixture shares its private center between the stopped and resumed services.
Synthetic service lifecycles are explicitly stopped. The four opt-in physical CloudKit methods
retain the production default notification path and real adapters; they were not executed.
No production publisher or default changed in this follow-up. The original sender remains
unobserved; this broader isolation does not close the switch or budget mechanism investigation.

The synchronization candidate adds an injectable `NotificationCenter`, defaulting to `.default`
for all production callers. The explicit-retry fixture owns a private source; its original
exact count and paused-account assertions remain. A new controlled-source test requires an
unrelated store's global event not to pollute that count, an injected remote event to refresh,
an injected local event to synchronize once, and a paused injected event/retry to synchronize
zero times. This is fixture isolation, not a transport policy change or real CloudKit proof.
Focused compilation and three-method runtime validation passed as recorded below; complete
local/hosted validation and independent review remain pending.

At reviewed diagnostic head `604caa9`, UI changes added **failure-only** public app snapshots and screenshots, retaining real
post-action text-field/switch values, frames and enabled state. Existing gestures, assertions,
waits and limits are unchanged. Geometry logs now label captured values `preTapRowValue` and
`preTapChildValue`. No dispatch observer/private API is present. These traces are not a switch
or budget root-cause fix and do not remove either acceptance blocker.

That review follow-up stored those pre-tap values from the same captured row/child instead of
formatting literal zeroes. Their guards still require off state. They are explicitly **not**
post-tap observations; the failure attachment remains the separate post-action capture. No
gesture, hit point, focus workaround, retap or timeout changed.

The budget predicate retains the last value from its **existing** query, without a second
query or a changed comparison. A later full snapshot is distinct from that exact failed read.

## Local validation checkpoint

All runs here use Xcode 27 beta 6 / iOS 26.5 and synthetic data, not hosted 26.6 or real CloudKit.

- `fx-reliability-sync-probe-1`: compilation succeeded and xcodebuild exited 0, but the Swift
  Testing method filters omitted `()` and selected **zero tests**. Native summary is unknown /
  0 total. This is **non-pass**, not synchronization validation. Log SHA-256:
  `9b2d64e31e6c8369682924696dc66f38d911268e8f477011968def7e052c80b3`.
- `fx-reliability-sync-probe-2`: corrected exact method selectors, no rebuild/source change,
  three methods Passed once: default-off adapter boundary (0.051s), explicit retry/paused
  account (0.032s), isolated-source positive/negative behavior (0.058s). Author native detail
  audit confirms 3 concrete executions, no Repetition/extra attempt, no runtime warnings and
  tree/detail bijection. Device `1B6529A0-D847-4757-9A08-C7DEDC08E376`. Log SHA-256:
  `9bf9fe3fa40d71351c9b083550affcbaa09db7a9553e6202db77546899b6d5df`.
- `fx-reliability-budget-trace-1`: the Chinese category-legend method Passed once in 109.900s
  on that same owned ordinary simulator. Its UI source included failure-only full snapshots,
  but not the later last-predicate-value string. Native audit confirms one concrete execution,
  no Repetition/extra attempt or runtime warnings. **Failure did not recur; cause remains open.**
  Log SHA-256: `61d9b4e805fefea0f4fa21352187a4ed484dd838853036e27a811d381d28d4b6`.

Adjacent result bundles are `/private/tmp/<name>.xcresult`; native author audit directories
for the latter two runs use `<name>-audit`. The rejected label probe log SHA-256 is
`3170811db0dc3deb5360ab1b4fc663e3859db35d73e24d4869b687bddff6c274`.
The synchronization source hashes tested were `CloudSyncRuntime.swift`
`e6525ecbbc93e4d51801a787fa91aeb2e58bf6585e4da48cf26de81db94970a8` and `CloudSyncTests.swift`
`0d011ead72b532d2e66fa9ccd3fe1b71073a2faf158366c4a4ebe2a96d6c3da6`.

The five static gates (integer money, network, commercialization documents, StoreKit catalog,
FX contract and negatives) passed at this checkpoint, as did `git diff --check`. This is not
default full `validate.sh`, a 500 ms benchmark result, exact-head hosted evidence or D acceptance.
The later last-predicate-value diagnostic passed incremental `build-for-testing`
(`fx-reliability-trace-build-1.log`); no additional runtime pass is inferred. The separate PR is a
Draft investigation checkpoint, not a merge recommendation; a green diagnostic run cannot by
itself establish a UI root cause or satisfy the still-open correction gate.

## Reviewed-head results and follow-up (not corrective acceptance)

Exact diagnostic head `e83017f6aab59e63f31857723ea54c6edcf2dd53` hosted run `34116397624`,
attempt 1, finished **success**: ordinary `101724123651`, FX `101724123782`, join `101736517662`.
Original artifacts are ordinary `10017878005` and FX `10017015334`. Author native audit of
all 628 ordinary method details found 611 Passed / 17 Skipped methods, 620 Passed concrete
executions, no Repetition/extra attempt, and no runtime warnings. FX's three methods each
Passed once, with no Repetition/extra attempt and each detail bound to provenance UUID
`712A528C-3E65-4964-9EFD-7AD9552EF2DC` (`cloned: false`). Stewardship / Chinese create /
English durations were 93.247 / 133.536 / 72.540 seconds. Three invalid-frame warnings remain
retained. This is hosted Xcode 26.6 execution with iOS 26.5; the author inspected the downloaded
artifacts with local Xcode 27 beta 6. Green diagnostic execution is not mechanism evidence.

The **default complete local validator on that same clean head failed**, wrapper exit 1.
Log `fx-reliability-e83017f-complete-1.log` SHA-256:
`bc5ab379902133604002d627714d3c7dd03efedd7c03212acb04d5e199b6e3d4`.
Local Xcode 27 beta 6 / iOS 26.5, zero retry, no benchmark skip. The strict benchmark measured
496.448167 ms under the unchanged 500 ms limit, with only 3.551833 ms margin; this is not a
performance improvement claim. Ordinary summary was 611 Passed / 17 Skipped methods (620
Passed concrete executions). That partial result does not make the full command pass.

The isolated local FX device was `28330F90-72C9-4DDD-8138-7F6FF3EDFEAE`. All three methods
failed, and the native summary additionally includes a runner error (4 failed records, 0
Passed):

| Method | Duration | Observed failure on `e83017f` |
| --- | --- | --- |
| Chinese AX5 stewardship | 67.695s | Line 144: no `fx.enabled` after Edit; failure hierarchy still shows Details. Synthesized Edit event is `(349.8333,84)`, inside the recorded button, not evidence of recognizer delivery. |
| Chinese AX5 create | 188.312s | Line 110: no `expense.edit` after Save; hierarchy still shows the entry form with FX enabled and entered rate 2. |
| English create/stewardship | 95.508s | Line 236: deletion into rate field fails because neither it nor a descendant has keyboard focus; the edit sheet exists, rate remains 2. XCTest internally retries synthesis twice and still fails. This is not an accepted single-input result. |

The runner also exited with code 75 before finishing tests; its mechanism is unproven. Two
invalid-frame warnings remain. None of these local failures reproduces the original hosted
off-switch state, and none explains it. Original attachments were exported without the
`--only-failures` filter because the Chinese failure hierarchies are not marked failure-associated.
Hierarchy attachments and SHA-256:

- Stewardship `D2BE2C92-F9D3-4390-8126-7E8E1AE1D0FC.txt`:
  `7057a4b3c9eae7fac219d8e6696a3a0373df644955e4901a46c7aeda6b2a250d`.
- Chinese create `56991187-8E09-4624-86C3-1C62D47B1F2C.txt`:
  `a7ca52408403ae9ce08ea499fa22ac1b85427731e502d7df587e8f5bcd5b429a`.
- English edit `637379B9-D356-400B-8370-B8320272C335.txt`:
  `6b91c6c8864f773da8f7511f8fbaf76ef7df588c826402ad23ca88cf7c4f7d06`.

Follow-up source validation (working-tree candidate, not `e83017f` execution):

- `fx119-review-followup-build-1`: incremental `build-for-testing` exit 0.
- `fx119-review-followup-probe-1`: command error, exit 65 before tests. The author incorrectly
  supplied `-retry-tests-on-failure NO`; this option takes no Boolean argument, so `NO` was
  rejected as a build action. No test execution or retry is counted; retained non-pass.
- `fx119-review-followup-probe-2`: removed the retry option entirely, unchanged built source.
  Whole `CloudSyncTests`, the Phase 6 privacy-deletion integration fixture and the switch
  snapshot geometry test: **40 Passed / 4 Skipped**, native audit of all 44 details confirms
  no Repetition/extra attempt and no runtime warnings. The four skips are the opt-in physical
  CloudKit methods, not synthetic checks. Device `1B6529A0-D847-4757-9A08-C7DEDC08E376`.
  This tests fixture isolation and captured values, not FX tap reliability or full validation.

Follow-up compiled source SHA-256: CloudSyncTests
`72de9eda7a10440b7cb3c5940473fab75ff08b17e426a458ba5c4f7b9f8f10d6`, Phase6FeatureTests
`ef4f5992411f1d72fb189ce01c01f1720f741d34db1e0f37d4e763089d3d5ec2`, Phase3UITests
`ba0c922ad672467b20d9e656bd270ea1ade7e4637a2d7d077c1f3ae521065bf7`.
CloudSyncRuntime is unchanged from the earlier tested hash above. Focused probe-2 log SHA-256:
`0e7aaf391ad7dd7da844b071b1ec4ca6ce2f767ccd697224ae17923fd075c2e1`.

The five static gates and `git diff --check` passed after these source changes. TASKS and
the manual-currency plan now distinguish merged #117 implementation from blocked #118
closeout. No new full-local/UI run is claimed, and no unchanged-source rerun is used to close
the open UI mechanisms. Main required-check protection and physical CloudKit / mixed-peer /
cross-calendar evidence remain open.

## Completion boundary (still open)

Owner-supplied independent rereview of `604caa9`: previous P2 documentation-state and
synthetic-isolation findings are closed, but the incomplete-investigation P2 remains open.
Hosted `34123406554` attempt 1 succeeded on that exact head (ordinary `101746396714`, FX
`101746396403`, join `101759354956`), independently confirmed through GitHub run metadata.
The reviewer reports 611 Passed / 17 Skipped ordinary methods, 620 concrete executions and
49 FX unit bindings once; each FX method Passed once without Repetition and matched fresh
non-cloned UUID `A40DF0A0-6946-46BE-95DD-4BFB3D7DFB70`. Chinese create was 178.567s / 240s;
each FX method retained one invalid-frame diagnostic. Retry/pause and controlled-source
methods passed in 0.785s / 0.739s. These native findings are attributed to the supplied review,
not a new author audit or test execution. Local Xcode 27 beta 6 artifact inspection is not
hosted Xcode 26.6 / iOS 26.5 execution.

The reviewer's interrupted isolation scan produced no usable output and is not evidence.
Its isolation conclusion came from a separate direct read of `604caa9`: all ten synthetic
construction sites inject private centers, whereas physical CloudKit / production use defaults.
This is not identification of the original ambient sender. No complete-local success exists
for `604caa9`; `e83017f`'s three local FX failures and runner exit 75 remain non-pass and do not
explain the hosted switch failure. `34097606992` / `34108994597` are still #118 non-passes.
GitHub mergeability is a merge-conflict status, not testing acceptance or authorization.
No new source repair, runtime execution, D checkbox, D Done, #118 undraft or E entry follows
from this review record. Branch protection, physical/mixed-peer/cross-calendar evidence and
the unproven original `34026066152` keyboard mechanism remain open.

## 2026-09-07 public-target switch observation and bounded fault injection

This is **controlled diagnostic evidence, not a corrective acceptance or identification of
the original hosted cause**. Four local experiments started from `604caa9` with temporary,
uncommitted probes. None ran the complete validator or the three contractual FX methods.
The original switch helper, trailing-quarter coordinate, single normal tap, 3-second value
predicate, zero runner retry and 240-second allowance were unchanged.

The author used Xcode 27 beta 6, iOS 26.5 / 23F77, and the newly created, non-cloned iPhone
17 Pro simulator `F7A155D9-9C37-4D00-BC13-0F3D439B3F5D`. The four experiments reused that
owned device; each language method relaunched the compile-isolated in-memory host. They are
not four fresh-device samples, hosted Xcode 26.6 results, or physical-device evidence.

The temporary zero-size, non-hit-testing host overlay sampled public `UISwitch` state and
the existing hit-path recognizers with `CADisplayLink`. It added target/action observers to
existing controls/recognizers and logged binding entry/result in the real view model. It
did not replace dispatch, swizzle, install a new recognizer, change a delegate or recognizer
configuration, synthesize a control action, or alter Pro access. Public state observation
still changes process timing; absence of a sampled recognizer transition is not proof that
no transient competitor existed. These observations must not be shipped as a repair.

| Experiment suffix | Controlled difference | Native result |
| --- | --- | --- |
| `probe-1` | Public targets, no injected stall; aggregate recognizer log | 2 Passed once, exit 0; some aggregate log lines truncated at 1,024 bytes, so the full recognizer chain is not evidence |
| `probe-2` | Separate short recognizer logs, including public minimum duration | 2 Passed once, exit 0; both languages emitted binding, model and value-changed events |
| `probe-3` | Same observer plus a 50 ms main-thread stall in each sample during its first 30 seconds | Chinese AX5 Failed once (15.985s), English Passed once (14.468s), exit 65; retained induced non-pass |
| `probe-4` | Removed only that bounded stall; restored probe-2 source | 2 Passed once, exit 0; Chinese binding/model/value-changed events returned |

The two selected methods were `testFX119SwitchMechanismChineseAX5Probe()` and
`testFX119SwitchMechanismEnglishProbe()`, not the contractual create/detail/stewardship tests.
Native author audits for 1/2/4 found two concrete executions, no Repetition/extra attempt and
zero runtime warnings. Native tree and both details for 3 contain one execution per method,
one failed Chinese method and one passed English method on the same UUID, no Repetition and
no runtime warnings. Separate experiments with changed diagnostic conditions do not turn
the induced failed execution into Passed, nor close either historical #118 failure.

### What the induced failure actually shows

Probe-3 Chinese PID `20311` had the same geometry as both retained #118 failures:
row `(36,132,330,125.3333435)`, native child `(305,180.6666667,63,28)` and one tap at
`(352.25,194.6666667)`. Separate post-failure snapshot attachment
`05F65BEF-EDC8-4623-91C5-F07CFDC34D40.txt` reports **both** identified row and native child
`Optional("0")`, enabled true. Screenshot `4F9AE234-C2CE-4F96-A5E8-97BF055DE2BA.png`
also visibly shows the off switch. These are actual post-action observations, not the
pre-tap geometry literals.

The observed hit-path long-press recognizer had `minimumPressDuration=0.01`. Its sampled
state changed from possible (`0`, monotonic `186019.513006`) to failed (`5`, `186027.303206`)
and reset to possible (`186027.368890`). No binding-entry, model-result, value-changed or
recognized-gesture target callback was logged for that failed app process. The observed
scroll pan and delayed-touch recognizers also sampled failed, not a recorded winning scroll.
In probe-4 Chinese PID `21043`, the same public recognizer duration was observed, followed by
began/ended at `186434.496095` / `186434.497321`, then binding requested 1, permitted 1,
model enabled 1 and value changed 1 at `186434.500236`. Thus this induced failure occurs
before the view-model binding, not after a successful binding overwritten by app state.

Limits: probe-3's sampling function is also called by a gesture target, so its artificial
stall applies to those callbacks as well as display-link samples. It is not a calibrated
model of hosted contention. The baseline and withdrawal runs are observations, not proof of
universal reliability. The historic `c1f0db2` trace's approximately 3 ms interval between
return from began dispatch and entry to ended dispatch is compatible with compressed event
processing, but neither its main-thread stall nor this 10 ms property was recorded then.
The `34097606992` / `34108994597` artifacts have no comparable control/timer timeline.
Timer starvation / event batching is therefore a **candidate explanation**, not a proven
historical cause, an identified competing recognizer, or an accepted corrective control.

Apple documents the public [minimum-duration property](https://developer.apple.com/documentation/uikit/uilongpressgesturerecognizer/minimumpressduration)
and [UISwitch value-changed event](https://developer.apple.com/documentation/uikit/uiswitch).
Those contracts support interpretation of the observed properties/events, not a documented
guarantee that every UISwitch uses this recognizer or an Apple-confirmed framework defect.

### Reproducibility and cleanup

Local artifacts use `/private/tmp/fx119-switch-mechanism-probe-N` plus `.xcresult`, `.log`,
`-build.log`, `-events.log` and `-source.patch`. Probe-3 attachments and complete exported
diagnostics are retained in adjacent `-attachments` / `-diagnostics` directories. Source
patch SHA-256 values for 1/2/3 are respectively
`379bdf55abfe5666feaff0a9c40db420e9a669544b04b93a858b719185cca835`,
`ade83db37b144a8f187d73f94b3c4db796ea16d5022025f984c3b4ff22efc85a`,
`5d1b976e9b9d9a7c47db84ce9fcadcfea5b0b4bbb8f1ffbc4b48970c178a52c0`.
Probe-4's `-source-full-index.patch` is byte-identical to probe-2's patch; the initially
compared short-index patch differed only in Git index abbreviation, not source content.
Probe-3 command log SHA-256 is
`3cd054c29da44912e4b030a446512e3352188bd9e713c82b8da4d7bc08ad93b1`;
its event log is `4da302677a5157344826838cb13e7ddce9e7b22984dc15bb755e3f1cfbf0ca00`.
Probe-4 command/event log hashes are
`7671b0a446933ac70aab12c924bda2c3df0965c53cdeae968c3fd1ad4f2d7b8d` /
`933526d630a3ffd5125f9a7ada2a62c8f99c91a5a5eab4f172ee1ce024e22f78`.

All temporary source changes were removed with a scoped patch: host, AddExpense view model,
UI tests and FX scheme are byte-identical to `604caa9`; no probe/fault-injection symbol remains.
Only this session's owned simulator was shut down; device data, source patches, bundles and
logs were retained. No real iPhone, CloudKit account, product UI change or new network route.
The budget visible-500/readback failure was inspected in source but not re-executed or resolved
by these switch-only experiments. No full local pass, hosted run, commit/push, PR mutation,
undraft, D checkbox, D Done or E entry is implied by this local diagnostic record.

Before proposing a mergeable repair, remove diagnostic-only code, provide bounded mechanism
tests and readable evidence, run default full local `Scripts/validate.sh` with the unchanged
500 ms benchmark and FX host, obtain exact-head hosted ordinary + FX + join success, and
audit native artifacts for no Repetition/extra attempt and exactly one pass per FX method
bound to its provenance UUID. Independent review is still required. PR #118 must later
retain both failed runs in its canonical packet and anchors; no old #117 green run substitutes
for its own accepted repair/closeout provenance. Real CloudKit / mixed-version / cross-calendar
physical evidence is not created by this investigation.
