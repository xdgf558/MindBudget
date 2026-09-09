# FX Chinese AX5 create duration investigation

Current FX-01D closeout: `Docs/FX_01D_CLOSEOUT.md` (implementation merged; D In Progress; E unentered).

Historical investigation; corrective query/dependency delivery was later accepted in #121
(`689b932` / `34302080136` / `039ecdf`). Original query cause stays UNPROVEN. The historical
status and artifact-only scope below are not pending #121 acceptance or permission to rerun #118.

Status: **ARTIFACT_TIMELINE_COMPLETE; QUERY_DELAY_CAUSE_UNPROVEN; NO_CORRECTIVE_ACCEPTANCE.**

Owner authorized a separate duration investigation after #118's fourth non-pass, not a repair,
allowance increase or unchanged-head rerun. Branch `codex/fx-ax5-create-duration-investigation`
starts at accepted main `10e5b13` (#120 merge). Product/test/project/workflow/runtime-script
trees match failed #118 `2ab850a` exactly. Existing #118 and other dirty worktrees are untouched.
No Swift, helper, runner, fixture, snapshot observer, device or API call was changed/executed.

## Inputs and attribution

Compare the same method, `testManualForeignCurrencyChineseAX5ProCreateAndDetail()`, not an
English or stewardship surrogate:

| Original run / head | Outcome | FX artifact / fresh non-cloned device |
| --- | --- | --- |
| #120 `34241669738` / `705d2a7` | Passed | `10063045432` / `36B43ECD-2060-471D-93B1-F9B7D537D02B` |
| #118 `34250759552` / `2ab850a` | Failed, attempt 1 | `10066839243` / `34650A96-F547-49BC-BC3B-60EFE0244DEF` |

Both are hosted Xcode 26.6 / iOS 26.5. Author read the existing original artifact/log copies
with local Xcode 27 beta 6 `xcresulttool`, without pinning a schema version; this is not a
hosted-toolchain rerun. Direct GitHub artifact inventories confirm IDs/names/unexpired state.
Both method details have one device/configuration execution and expected provenance UUID.
This is an author audit of the compared method/activity records, not a new all-suite audit.
The owner's ordinary 622/17/0, 631 concrete Passed and 49 bindings once remain attributed to
their independent review. FX/join failure is not covered by ordinary or #120's pass.

## Comparable activity timeline

Numbers below are elapsed wall time between native activity **start markers**, not exclusive
CPU time, exact API durations or a statistical latency distribution. Nested activities are not
summed into their parents. Both runs have seven recorded FX viewport pans; currency menu pans
are five in the passing run and four in the failed run. More pans do not explain this failure.

| Milestone (seconds from method start) | #120 pass | #118 fail | Fail minus pass |
| --- | ---: | ---: | ---: |
| Tap currency picker | 19.511 | 39.763 | 20.252 |
| Tap EUR option | 57.320 | 115.534 | 58.214 |
| Tap rate-date picker | 88.175 | 149.960 | 61.785 |
| Tap original-amount field | 98.516 | 163.082 | 64.566 |
| Tap rate field | 140.808 | 202.986 | 62.178 |
| Single keyboard Done tap | 148.522 | 209.672 | 61.150 |
| Begin preview existence wait | 172.480 | 237.439 | 64.959 |

The largest isolated excess precedes any currency-menu pan. The first EUR-query activity begins
at 42.609s in the failed run, a `(retry 1)` activity at 73.760s, and the next collection-view
wait begins at 89.562s: **46.953s** total. Same marker interval in the pass is 25.050–30.369s,
**5.319s**. Difference **41.634s**, about 64% of the 64.959s lag already accumulated at preview.
The preceding launch/open stage is also slower (16.628s versus 6.887s between root markers),
and pre-currency work totals 39.763s versus 19.511s. There is no uniform slowdown: original-field
focus to rate-field focus is 39.904s in the failure versus 42.292s in the pass.

Source maps the first query to the real menu's EUR predicate `firstMatch` existence check in
the bounded currency-selection loop. The activity label `(retry 1)` is XCTest query-internal,
not a second execution of the test method, a user-authored retap, or permission to relax zero
test-level retry. The platform's reason for that query delay was not captured. No claim of
deadlock, overloaded runner, slow financial calculation or localization bug is established.

## Timeout, post-deadline progress and cleanup are separate

Original job log confirms the allowance fired at 240s. Native activities exported by this
tool stop around the deadline; the continuing job log must not be silently treated as part
of that activity tree. The log records Save at **246.49s**, saved-detail attachment at **249.46s**,
and termination beginning at **253.61s**. Termination failed about **314.60s**, followed by
method completion at **316.533s**. The pass tapped Save at 177.12s and terminated at 181.58s.
Progress after the deadline does not make the failed method Passed, but it disproves an
unsupported claim that it permanently stopped at preview or never reached the Save event.
An event log is not proof of physical input delivery or a successful full assertion sequence.

Do not conflate the different duration fields: failed native top-level `durationInSeconds`
is **240**, device/configuration duration is **326.6010000705719**, while the original test-case
log reports **316.533**. Their endpoints are not equivalent and the native/log discrepancy
is not explained here. The additional cleanup time is not the entire pre-deadline cause.

The automatic spindump covers 16:43:23.228–16:43:28.226 UTC, about 240.628–245.626s into the
method, **not** the 42.609–89.562s currency-query stall. It shows `revealFX` in the Save-reveal
call and public XCTest element resolution/snapshot waits. This corroborates later repeated
live queries but cannot identify the earlier stall's cause. Hardware/memory metadata is
context, not retrospective resource-pressure proof. No new process sampling was performed.
Three existing FX Invalid-frame diagnostics remain, not a demonstrated cause of this timeout.

## Repair direction requiring separate authorization

The evidence supports investigating/removing avoidable **UI-test query work**, not loosening
the 240s allowance, retapping or classifying a later green as proof:

- First priority: narrow and bound the currency-menu observation. Avoid repeatedly resolving
  an absent global EUR `firstMatch`; use one validated menu snapshot per observation, real
  visible EUR selection and unchanged pan/one-tap limits. Preserve all real picker assertions.
- Second priority: `revealFX` currently resolves navigation bars, sentinel, keyboard, Save,
  target and occupied controls separately and repeatedly. A single immutable snapshot per
  iteration could reduce round trips while keeping the exact safety lane, keyboard/Save
  occlusion, numeric/date-wheel exclusions and pan limits. This is a proposal, not an implemented
  or validated optimization. A synchronous snapshot can itself block; a loop deadline alone
  cannot guarantee pre-emption, so no proposed guarantee of eliminating platform latency.
- Require deterministic missing/duplicate/unsafe/stale/late snapshot negatives, unchanged
  functional coverage, then complete local and new-head hosted/native/independent acceptance.
  Do not delete date selection or split assertions away merely to make the existing run green.

No repair, new PR, push, #118 undraft, D checkbox/Done or E/Insights-share work is authorized
by this investigation. Keep all four #118 runs non-pass: `34097606992`, `34108994597`,
`34218693463`, `34250759552`. Physical CloudKit/mixed-version/cross-calendar gaps remain open.

## Reproducibility

Local evidence directory `/private/tmp/fx-create-duration-evidence.ZnMWlK/` retains two native
activities exports, two details, the timeout spindump, root-interval analysis and explicit-failure
`summarize.py`. It checks method identity, single run, expected result/device/provenance, unique
ordered markers and log execution boundaries. Normal and optimized Python output bytes match.
No `assert`-only checks or runtime invocation. Original input copies were not overwritten.

| Artifact | SHA-256 |
| --- | --- |
| Timing summary | `d74d8ea0310fa40ea0cc994e281969fb7d7f5da4ecf048d36b177598dc9ef890` |
| Summary analyzer | `747afaf3c2ef42802ad44caa8a5e4e5d5616322a8143f3df22d609a73266b7f8` |
| Failed activities | `371bec877a0fe37af5df56e081640390817cde1b2395a8d03ec84f32a8855155` |
| Passed activities | `e5dab5b687b0a91ce046a41e4180a35f2606d86396b4d92a7573c9c43ff4d234` |
| Failed detail | `d844603449fc8c28fc79a3f65889dfc353e0c1cfa9a29c189e50a5702673bc52` |
| Passed detail | `21395a968ab8b86afc4cc316f7f20e2baeebbd7ca0fccd856af37ddb4beda76b` |
| Timeout spindump | `41686ce7e32ca39ee9289d4f3beee2949dfc217fda1b693b0456e40d033e4de5` |

Input job-log/archive hashes are retained in the timing summary. Hashes identify local evidence;
they are not a remotely accessible independent review, fixture pass or corrective admission.
