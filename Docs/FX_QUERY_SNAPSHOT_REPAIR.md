# FX menu and viewport query repair

Status: **WORKER_AUDIT_REPAIR_PENDING_NEW_HEAD_VALIDATION; NOT_ACCEPTED.**

Hosted `34298810822` attempt 1 on `4086c59` failed ordinary at the Worker high-severity
audit before Xcode; join failed, although FX passed. This is retained non-pass, not a flake.
Owner authorized the separate dependency commit described in `WORKER_DEPENDENCY_AUDIT_REPAIR.md`.
New-head default full local and hosted ordinary/FX/join/native verification are required;
the earlier complete local and FX green below are historical evidence only.

Post-runtime working annotation: frozen `4086c59` predates this receipt. Default complete
validation exit 0, benchmark 190.020375 ms / 500 ms, ordinary native 625 Passed / 17 Skipped,
634 concrete Passed executions, 49 FX unit bindings once. Full FX native 3/3 Passed once,
no Repetition, non-cloned `6C2EE5CA-341A-4D0B-8656-92FB123221AD`: stewardship 26.994s,
Chinese create 53.569s, English 42.496s. Source remained exact throughout that run. Its
freeze was subsequently superseded only by the authorized dependency repair. See SESSION_LOG and local
`full-receipt.json` for the full author audit. Hosted and independent acceptance remain open.

Owner explicitly authorized currency-menu lookup and `revealFX` repeated-query repair after
the artifact-only report `FX_AX5_CREATE_DURATION_INVESTIGATION.md`. Local investigation commit
`26781e7` preserves that report; `codex/fx-query-snapshot-repair` is separate from Draft #118.
No product UI/design, financial code, model, synchronization, runner or allowance change.

## Mechanism and limits

- The real currency picker still opens once and selects EUR once. Wait for its collection
  view under the existing two-second appearance budget, then inspect one public application
  snapshot per observation. Match only a unique `EUR — ` button inside the unique menu, not
  a global absent `firstMatch`. Require full visibility/enablement; query live `isHittable`
  only when a scoped candidate exists in the snapshot. A not-yet-hittable candidate continues
  bounded scrolling without tapping; a hittable candidate gets one native tap. Preserve ten menu pans and
  their original endpoints. Invalid/ambiguous/occluded menus fail instead of guessing.
- `revealFX` receives a value identifier/type, never resolves the live element merely to
  learn its identity. Navigation, foreground form, sentinel, keyboard, Save, target and pan
  exclusions come from one immutable public snapshot per iteration. Preserve strict lane
  inequalities, keyboard and Save occlusion, gap-only pan origins, displacement/rest behavior
  and fourteen-pan cap. Also reject ambiguous chrome, non-finite geometry and an open picker.
  The host footer can be absent in the edit sheet (it belongs to the presenting view);
  foreground form/Save/window/keyboard still provide mandatory bounds.
  Final visibility includes application/form containment. Interactive targets retain one
  final `isHittable` check because public snapshots do not expose that property; geometry is
  not recomputed from live queries. Static text retains its non-interactive visibility test.
- After every pan discard the observation, including after the final allowed pan. An extra
  final observation is not an extra gesture. Never replay a stale plan or retap activation.
  Bounded activity attachments retain capture/classification elapsed time and decisions;
  failures also keep screenshots.

These controls reduce avoidable UI-test round trips. They do not prove why XCTest stalled
for 46.953s in the old run, guarantee snapshots cannot block, or atomically freeze the UI
between inspection and interaction. No new capture timeout or larger test allowance exists.
Existing monotonic-deadline tests still reject late observations in the keyboard helper;
pan loops are gesture-bounded and remain subject to the unchanged 240-second method limit.
No synchronous XCTest call can be forcibly pre-empted by this helper.

## Coverage and acceptance

Keep all real English lifecycle/Free guards, Chinese AX5 currency/date/input/preview/save/detail
assertions and expired stewardship editing. Do not replace them with seeded results or omit
date selection. Deterministic tests cover scoped/absent/clipped/duplicate/disabled choices,
strict edges, keyboard occupancy, missing/ambiguous chrome, unsafe pan origins and fresh
post-pan observations with exact caps. Existing polling tests cover late/error observations.

- [x] Focused deterministic tests and three real isolated FX methods, zero retry.
- [x] Frozen-head default full local `Scripts/validate.sh`, unchanged 500 ms and FX host (4086c59).
- [ ] Repeat default full local validation on the separately authorized dependency-repair head.
- [ ] New exact-head hosted ordinary + FX + join success and native artifact audit.
- [ ] Independent review and explicit merge authorization.

Source-freeze evidence (local Xcode 27 beta 6 / iOS 26.5, not hosted 26.6):
four deterministic methods Passed once, native audit 4/4, source simulator
`3D6221D5-39DF-4CD4-ADEE-472B4139F47B`. Three real FX methods Passed once on fresh non-cloned
`28CE4B3F-9C5F-4CCB-BBA6-4BCE2806EA14`: stewardship **25.929s**, Chinese create **55.291s**,
English **42.272s**. Runner exit 0 and exact three-binding verification passed; native audit
also verifies no Repetition/extra execution and that UUID. Three Invalid-frame diagnostics remain.
These are scoped observations, not an estimated hosted latency or proof of the old stall's cause.
UI-test SHA-256: `e601fd7c1a25d005edb8226ad0484689ccafc10ce6ba63f97e9f6c53cbf7076d`.

Retained first candidate non-pass: source `a063993cb70417415d3d5608db9a2e3008194fbbae1823843e2b07b75e45e4cb`,
fresh device `7FFB3B79-F875-4321-B0F3-9321B0012744`, three failures (12.681/23.049/36.764s),
runner exit 1 / xcodebuild 65. Over-strict mandatory presenting-footer rejected editing sheets;
in-window EUR geometry preceded hittability and was incorrectly fatal instead of another bounded
pan. Candidate was corrected and deterministic regressions added before the second run.
No unchanged-source rerun, waived assertion or timeout increase; original evidence is retained.
Local logs/results/audits: `/private/tmp/fx-query-repair-evidence.QLBvjN`.

This is not corrective acceptance, #118 closeout, D Done, E entry or Insights sharing.
All four #118 failures remain non-pass: `34097606992`, `34108994597`, `34218693463`,
`34250759552`; #120's green does not replace them. D's four boxes remain open. Physical
CloudKit, mixed-version and cross-calendar coverage is still absent. Existing unrelated
`makeBudgetSaveReady` final-pan, Settings row-focus and branch-protection debts remain.
