# PR #117 switch dispatch investigation

Status: **Historical diagnostic evidence; observer-free 8e57283 has hosted success and full-local exit 0; PR #117 remains Draft pending evidence rereview.**

The investigation checkpoints below are retained history, not the current validation status.
Hosted `34080624727` passed on observer-free `8e57283`; the owner's supplied independent review
accepts its hosted/native switch evidence. The already-started default full local validator on
that same exact head subsequently completed exit 0, including 217.09825 ms under the unchanged
500 ms ceiling and three FX methods Passed once with device binding and no extra attempt.
See `FX_01D_IMPLEMENTATION_EVIDENCE.md` for toolchains, artifacts, hashes and audit attribution.
Both failed hosted runs remain non-pass; original gesture arbitration cause remains unproven.
No further helper change, retap or longer press was made. The trailing-quarter choice is scoped
to the existing English/Chinese LTR, off-state fixtures. `width > height` rejects non-horizontal
geometry; it does not itself detect RTL. D stays In Progress and E remains unentered.

## Retained failed hosted run

Run `34077058451`, attempt 1, exact head
`c1f0db2a675ad2474254a45d338a8a0e5aaaf5c5`, failed. Ordinary succeeded; FX and join failed.
FX artifact `10002713432` (`MindBudget-fx-xcresult-34077058451-1`) contains the original
`MindBudget-FX-UI.xcresult` and provenance UUID `53F93571-5955-4057-88D8-A77889620CCF`.
Chinese stewardship Passed (169.446 s), Chinese AX5 create Failed (33.247 s), English create
Passed (100.488 s). These are failed-run observations, not a three-method admission.

The AX attachment `AA9A3537-6D4B-4955-84B0-70BE5526D805.txt` records:

| Geometry | x | y | width | height |
| --- | ---: | ---: | ---: | ---: |
| Labelled Chinese AX5 row | 36 | 132 | 330 | 125.3333435 |
| Native switch child | 305 | 180.6666667 | 63 | 28 |
| Thumb view from dispatch trace | 307 | 182.6666667 | 37 | 24 |

The existing helper taps the child centre `(336.5,194.6666667)`, delivered after display
rounding at `(336.6666667,194.6666667)`. The row and control share the same vertical centre
(within rounding). Replacing the child's height with the 125pt row height would not explain or
correct this failure. Video `E3DF8581-EDB6-41AD-BF85-79D0BC72716F.mp4` also shows the off control
at that position; there is no observed geometry mismatch.

## Reproduce the readable dispatch evidence

Export diagnostics using `xcrun xcresulttool export diagnostics --path BUNDLE --output-path OUT`.
Within the exported FX diagnostic directory, the original App console is under
`MindBudgetUITests-7BFDBB03-F1DB-4E3A-B50B-DC9A6EB58AEF-Configuration-Test Scheme Action-Iteration-1/`
`MindBudgetUITests-97D39910-3937-4D0D-8F87-DBE3B0A09BB6/`
`StandardOutputAndStandardError-com.xdgf558.MindBudget.txt`.
Lines 105681–105684 contain the failed process 23879's four readable `[touch]` records.
The successful English process 25233's `ACTION UISwitch selector=toggleStateChanged:` appears
at line 114616. Thus absence from the GitHub step log does not mean absence from xcresult.

The same failed event is readable from the exported
`simctl_diagnostics/53F93571-5955-4057-88D8-A77889620CCF/system.logarchive`:

```sh
/usr/bin/log show --archive ARCHIVE --info --debug --style compact \
  --start '2026-09-07 02:53:50+0000' --end '2026-09-07 02:54:00+0000' \
  --predicate 'subsystem == "MindBudget.FX117Diagnostic"'
```

Local export SHA-256 `432bc4035115d668be95c6614bc4f05da6981287ed1c6089d51cfd523a1144db`
identifies the header and four full records, without truncating the ancestor chains.
Console wall timestamps are about 253 ms later than the archive-rendered timestamps; the
touch timestamps and geometry match. Do not combine wall timestamps from the two renderings.

The following is a **derived synopsis**, not replacement raw logs:

| Archive UTC | Stage | Touch timestamp | Observed native state |
| --- | --- | ---: | --- |
| 02:53:53.750 | before began | 934.111467625 | Thumb view receives touch; UISwitch enabled, off; internal long-press/pan possible. |
| 02:53:53.769 | after began | 934.111467625 | Same target and off state; native long-press/pan still possible. |
| 02:53:53.772 | before ended | 934.1781342916667 | Same target and off state; native long-press/pan still possible. |
| 02:53:53.775 | after ended | 934.1781342916667 | Native long-press/pan failed; UISwitch remains off; no control-action record. |

The target chain contains the runtime thumb/visual-element classes followed by public UISwitch.
Class names are observations from public `type(of:)`, not private API calls or selectors.
This proves that the tap reached the control's thumb; it is not a missed coordinate or an
unreadable trace. It does not prove why native gesture arbitration failed. The observer changes
process timing; a wall-dispatch interval is not the synthesized touch duration.

## Bounded corrective candidate

Keep a single public snapshot, one tap, the same enabled/off preconditions and the same value
wait. For these English/Chinese left-to-right fixtures only, choose the trailing quarter of
the **native off switch**, not the label row or draggable thumb. The candidate point is
`(352.25,194.6666667)`, inside the observed track and outside the thumb ending at x=344.
Deterministic tests include this real AX5 geometry, the earlier English geometry, an off-centre
control, invalid/occluded/ambiguous states and a non-horizontal control. No retap, long press,
sleep, timeout increase, product gesture change or direct accessibility action is added.

`pr117-track-geometry-1` passed the one deterministic geometry method locally (0.225 s).
An isolated three-method diagnostic with the observer still present must verify the new
dispatch target before interpretation. Then remove the observer and validate a final head.
Neither this geometry test nor an instrumented pass closes the failed 500ms complete validator,
establishes hosted acceptance, permits merging, marks D Done, or enters E.

## Local target-path observation and observer removal

`pr117-offtrack-diagnostic-1` exited 0 on task-owned
`FE9C492D-0D98-4950-BF4A-2B4D28888AD8` (Xcode 27 beta 6 / iOS 26.5). Its three methods
Passed once with strict provenance binding; durations were 40.346 / 79.556 / 42.654 s for
Chinese stewardship / Chinese create / English create. Three existing invalid-frame warnings
remain diagnostics, not additional executions. The runner removed only its own simulator.
Log SHA-256: `98a995adeb443c0d3eee2e85cc409639e5700b74a4e4fa4ab20c9f0a04d0c806`.

The captured Chinese began/ended path at rounded `(352.3333333,194.6666667)` now starts with
track UIViews inside the same native switch instead of the thumb view. One control action
`toggleStateChanged:` follows, with `isOn=true`. The live scoped observer export SHA-256 is
`26b115d4ea22b9ba36e6ac27db156203e9ede9b5497042cc606ebd7d61bb7f79`.
This verifies the changed target path and a successful single activation locally. The native
long-press also began in this successful run, so these observations do **not** establish that
the candidate eliminates every gesture-timing failure or reproduce a controlled counterfactual
for the hosted failed event. Final hosted acceptance and independent assessment remain necessary.

After that diagnostic completed, the entire observer was removed: `FXUITestHost.swift` is
byte-for-byte identical to the original uninstrumented `f3538f9` host. The isolation gate now
rejects native dispatch replacement via `method_exchangeImplementations`, `method_setImplementation`
or `class_replaceMethod`, with three copied-source negative tests. This is a narrow source check,
not proof against arbitrary aliases/new files. Final complete local/hosted validation must run
on the observer-free repair head; no instrumented runtime result substitutes for it.
