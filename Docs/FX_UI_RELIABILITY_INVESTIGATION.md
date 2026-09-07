# Separate UI / synchronization test investigation

Status: **INVESTIGATION_IN_PROGRESS; no corrective acceptance; PR #118 remains Draft.**

The owner authorized a separate investigation/repair after the second PR #118 review.
Branch `codex/fx-ui-reliability` starts at merged PR #117, `d19c6401bc14d2b43365b0936a37fe270e39c481`.
It does not add test changes to the documentation-only closeout branch, rerun that branch,
check D's four completion items, mark D Done, or enter E. Sharing remains queued.
Zero retries, single activation, the 240-second FX allowance and the default local 500 ms
benchmark are unchanged. A diagnostic success is not a repair or acceptance.

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

The synchronization candidate adds an injectable `NotificationCenter`, defaulting to `.default`
for all production callers. The explicit-retry fixture owns a private source; its original
exact count and paused-account assertions remain. A new controlled-source test requires an
unrelated store's global event not to pollute that count, an injected remote event to refresh,
an injected local event to synchronize once, and a paused injected event/retry to synchronize
zero times. This is fixture isolation, not a transport policy change or real CloudKit proof.
Focused compilation and three-method runtime validation passed as recorded below; complete
local/hosted validation and independent review remain pending.

UI changes currently add **failure-only** public app snapshots and screenshots, retaining real
post-action text-field/switch values, frames and enabled state. Existing gestures, assertions,
waits and limits are unchanged. Geometry logs now label captured values `preTapRowValue` and
`preTapChildValue`. No dispatch observer/private API is present. These traces are not a switch
or budget root-cause fix and do not remove either acceptance blocker.

The budget predicate also retains the last value from its **existing** query, without a second
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

## Completion boundary (still open)

Before proposing a mergeable repair, remove diagnostic-only code, provide bounded mechanism
tests and readable evidence, run default full local `Scripts/validate.sh` with the unchanged
500 ms benchmark and FX host, obtain exact-head hosted ordinary + FX + join success, and
audit native artifacts for no Repetition/extra attempt and exactly one pass per FX method
bound to its provenance UUID. Independent review is still required. PR #118 must later
retain both failed runs in its canonical packet and anchors; no old #117 green run substitutes
for its own accepted repair/closeout provenance. Real CloudKit / mixed-version / cross-calendar
physical evidence is not created by this investigation.
