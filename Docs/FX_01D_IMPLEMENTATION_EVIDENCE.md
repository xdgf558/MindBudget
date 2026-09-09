# FX-01D implementation evidence

Current FX-01D closeout: `Docs/FX_01D_CLOSEOUT.md` (implementation merged; D In Progress; E unentered).

Status: **In Progress — PR #117 implementation merged as d19c640; independent D closeout pending; FX-01E unentered.**

Current closeout checkpoint: #118 resumes after separately accepted #119 (`70fc7c1` /
`34182518433` / `b364444`), #120 (`705d2a7` / `34241669738` / `10e5b13`) and #121
(`689b932` / `34302080136` / `039ecdf`). All have
exact-head complete-local, hosted/native and independent corrective acceptance. #118 failed
runs `34097606992`, `34108994597`, `34218693463` and `34250759552` remain non-pass. #121 changes the runtime
baseline; its inherited controls are not a helper repair inside this documentation PR.
Original causes remain UNPROVEN. This closeout's own evidence is still pending.
See `FX_01D_CLOSEOUT.md` for provenance and sufficiency limits. #118 needs its own new exact-head
CI/native audit and rereview; earlier green implementation/repair evidence is not a substitute.
No helper change relative to accepted main, D checkbox, D Done or E entry is authorized here.

### Historical main-side source-freeze checkpoint (superseded by #120 acceptance)

Status: **D In Progress — #117 implementation merged d19c640; #118 closeout remains Draft.**

Current pointer: accepted #119 merge `b364444` does not replace the three failed #118 runs
`34097606992`, `34108994597`, `34218693463`. The owner-authorized separate readiness repair
and its unresolved acceptance are in `FX_UI_READINESS_REPAIR.md`. Four D boxes stay open;
E is unentered. Everything in the 8e57283 validation sections below is a historical
implementation checkpoint, not the current #117 PR state or #118 closeout evidence.

### Continuing implementation history and obligations

Owner entry and C completion are recorded in `FX_01_MANUAL_CURRENCY_PLAN.md`, using PR #116's
reviewed `f7b0bff`, hosted `34038682330` attempt 1 and merge `7e9d693`. Those accepted C facts do
not validate this D candidate. PR #117 subsequently received independent approval and merged
reviewed `7e901f2` after hosted `34090503092` passed. Its exact merge and fresh original-artifact
audit are in `FX_01D_CLOSEOUT.md`; D's four items remain unchecked pending independent closeout.
The following pre-merge evidence checkpoints are retained history, not current Draft status.
Original head `f3538f9` and diagnostic head `c1f0db2` retain their
non-passes below. Observer-free head `8e572832073f84be6513b7da4f3d7bbf5e67941b` now has
completed full-local evidence and hosted `34080624727` success. The owner's latest supplied
review accepts the hosted/native switch evidence but requires this complete-local result to be
recorded and rereviewed. This update supplies that evidence; it is not independent approval or
permission to undraft/merge. D's four plan checkboxes stay open; E is unentered.

## Historical observer-free implementation validation — 2026-09-07

The already-started, single full invocation on exact clean head
`8e572832073f84be6513b7da4f3d7bbf5e67941b` completed **exit 0**. No source was edited during
that invocation. This is default complete `Scripts/validate.sh` with no command-line arguments,
not a focused selection or `--ci-ordinary-only`. Local toolchain is **Xcode 27 beta 6 / iOS 26.5**,
not hosted Xcode 26.6. Environment selected that toolchain, task-owned unit simulator
`45F3E708-A2DC-4CFE-BDEC-6F41002F3B43`, retained result path
`/private/tmp/pr117-offtrack-complete-1.xcresult`, `MINDBUDGET_RETRY_TESTS_ON_FAILURE=0` and
`MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=0`.

The log ends `Complete local validation passed, including the FX UI host`. Static gates,
Release build, coverage-enabled test build, the separate serial benchmark, ordinary suite,
coverage thresholds, 23 C6-02 bindings, **49 FX unit bindings**, and the isolated FX host all
completed. The benchmark measured **0.21709825 s (217.09825 ms) < unchanged 500 ms**, once.
Its later exclusion from the ordinary suite is the existing serial-benchmark arrangement,
not omission from the full validator. No threshold, fixture, timing interval, retry setting,
switch helper or allowance was changed to obtain this completed result.

Native audit reads each original tree and method detail, not just the xcodebuild summary:

| Artifact | Native result | Repetition / extra attempt | Runtime warnings |
| --- | --- | --- | --- |
| Serial benchmark `Test-MindBudget-2026.09.07_11-46-16-+0800.xcresult` in the existing DerivedData test log directory | 1 method / 1 concrete Passed | 0 / 0 | 0 |
| `pr117-offtrack-complete-1.xcresult` | 627 methods: 610 Passed / 17 Skipped; 619 concrete Passed, including 13 argument executions across four parameterized methods | 0 / 0 | 0 |
| `pr117-offtrack-complete-1-FX-UI.xcresult` | 3 methods / 3 concrete Passed | 0 / 0 | 3 |

All tree/detail parameter bijections passed. The 17 ordinary skips remain skips, not transport
or physical-device passes: four physical CloudKit, one on-device Eval, one physical C6-02,
two live configuration/telemetry, six opt-in StoreKit runtime methods and the three FX methods
reserved for the separate host. Those three FX methods did execute in the complete validator's
isolated host below; the ordinary skips are not their runtime evidence.
The FX verifier also checked each method detail against freshly
created, non-cloned provenance UUID **`1C487684-0638-434F-82A6-FCD54EDB17EE`**; scoped cleanup
completed. Chinese AX5 stewardship / Chinese AX5 create / English create took
**39.339 / 78.040 / 41.725 s**. Three existing invalid-frame warnings and diagnostic collection's
`simctl` lookup error 72 remain recorded; they are not test failures or extra attempts, and this
is not a zero-diagnostic claim. No physical CloudKit or real-account transport was tested.

Retained full log: `/private/tmp/pr117-offtrack-complete-1.log`, SHA-256
`78c2f4c79f31106be7debf5374dcd4a24459dc49af7078d4fa4eba92aa8390c2`.
FX provenance: `/private/tmp/pr117-offtrack-complete-1-FX-UI.simulator.json`, SHA-256
`0ca4dfec5345130c6689f86f54ef9e08958023dbcb733b3d5ca0421263d3e024`.
Native audit directories use the same basename with `-native`, `-fx-native` and
`-benchmark-native` suffixes. These local artifacts are not embedded in this repository.

Hosted [34080624727](https://github.com/xdgf558/MindBudget/actions/runs/34080624727), attempt 1,
is **success on exact head 8e57283**: ordinary job `101615078191`, FX job `101615078310`, and
join `101622038054` all succeeded. Artifact IDs are ordinary `10004308058` and FX `10003779754`.
Run/head/job metadata was checked directly. Hosted native switch acceptance is the
owner-supplied independent review in this conversation; the new native audits described above
are author-performed **local** audits, not a claim of a second independent hosted audit.

Original full-local **814.581125 ms / exit 65**, hosted **34072691064** and **34077058451**
remain retained non-passes. The original benchmark cause and native gesture arbitration cause
are still unproven; this complete result does not retroactively relabel them or claim a
performance fix. The latest review specifically requested complete default validation and
evidence synchronization, without another helper change. Its completed evidence is now ready
for rereview; no author self-approval, D Done or E entry follows.

This evidence-sync change is Docs-only relative to `8e57283`. Its later commit/hosted run must
be identified separately in the PR: neither the full-local invocation nor `34080624727` ran on
that later documentation commit. Identical non-Docs source is provenance, not an invented
exact-head runtime result. The sections below retain earlier checkpoint wording as history;
this current section governs the present acceptance state.

## Implemented CSV and consumer slice

`ExpenseExportRecord` carries a validated immutable optional FX value. The actor reads the entire
persisted companion and the pure `CSVExporter` validates it again against the record's saved
accounting amount. The exporter returns bytes only after every row succeeds; throwing clears
the existing view's shareable result/count and uses its existing localized error/retry state.
This is no new UI layout or share-card design.

The first 22 CSV columns, order, accounting values, UTF-8 BOM, RFC 4180 escaping and user-text
formula neutralization are unchanged. Eight columns follow, in this order:

```
original_amount
original_amount_minor_units
original_currency_code
exchange_rate_numerator
exchange_rate_denominator
exchange_rate_date
exchange_rate_time_zone_identifier
exchange_rate_source
```

Original amounts use the original currency exponent and a locale-independent decimal point.
The saved rate remains an exact fraction, including nonterminating home-amount overrides.
Rate date is UTC ISO-8601 with fractional seconds; the saved IANA time zone is exported alongside
it. No date/rate is refreshed or inferred. Ordinary expenses and all income rows have eight
empty cells. Existing FX stewardship/export does not require a current Pro entitlement.
English/Chinese disclosure lists the added fields; CSV remains an explicit in-memory export,
not a persistent backup or permission for another egress channel.

No consumer arithmetic changed. New tests compare otherwise-identical ordinary, manual-rate
EUR and home-override JPY records with the same locked USD amount, a different rate date and
changed Settings currency. Actual actor summaries, Dashboard snapshot/pace, budget impact,
Insights/category totals, ledger projection, template Ask and cycle summary remain equal.
The Ask/report comparisons use English and Simplified Chinese with enhancement disabled.
These are consumer regression fixtures, not real user data or AI evaluations.

## Historical CSV-only local evidence and retained non-passes

Toolchain: Xcode 27 beta 6; iOS 26.5 simulator. The first two CSV-focused runs used existing
simulator `6E0EA9FF-E886-45F4-B752-79C6F60B0235`. They are uncommitted working-tree probes,
not a complete validator or hosted candidate.

| Run | Outcome | Interpretation |
| --- | --- | --- |
| `/private/tmp/fx01d-csv-focus-1.xcresult` | exit 65, build failure | New `#expect(allSatisfy(\.isEmpty))` macro expansion produced an unhandled-throw diagnostic; tests did not start. Retained non-pass. |
| `/private/tmp/fx01d-csv-focus-2.xcresult` | exit 0 | After replacing both new blank-column assertions with array equality: 30 Passed methods / 32 concrete executions, including one existing three-argument method; native tree/detail bijection, zero Repetition/extra attempt, zero runtime warnings. |
| `/private/tmp/fx01d-all-fx-unit-1.xcresult` | exit 65, runner launch failure | `SBMainWorkspace` denied launch as Busy / failed preflight checks. Native summary records one infrastructure error, zero Passed methods; no FX test method started. Not a product verdict or transient pass. |

Logs have the same basenames with `.log`; the successful CSV native audit is in
`/private/tmp/fx01d-csv-focus-2-native`. The broader run's launch failure is kept distinct from
the earlier test compilation failure. Its diagnostic collection also could not find `simctl`
through the diagnostic subprocess's tool lookup; this does not establish the underlying Busy
cause. No global Xcode selection, shared simulator reset, test retap or retry policy changed.
A fresh, task-owned simulator `45F3E708-A2DC-4CFE-BDEC-6F41002F3B43` was created for separate
expanded validation; its result must be appended after completion, never inferred from creation.

At this CSV-only checkpoint the FX-owned runtime gate required 41 unit methods (32 retained B/C plus nine CSV/consumer
bindings) and the unchanged three isolated FX UI methods. The 30-method focus is not evidence
that all 41 bindings or the UI host passed. Full `Scripts/validate.sh`, new-head hosted jobs,
native audits and independent review remain mandatory before D acceptance.

### Expanded isolated unit result

The task-owned simulator completed initial boot in 26 seconds. One subsequent invocation,
`/private/tmp/fx01d-all-fx-unit-isolated-1.xcresult` with its matching `.log`, exited 0:
54 methods Passed / 56 concrete executions, including the existing three-argument method.
Native audit in `/private/tmp/fx01d-all-fx-unit-isolated-1-native` confirmed zero skipped/failed
methods, zero Repetition/extra attempt, zero runtime warnings and a parameter tree/detail
bijection. The repository verifier separately confirmed all 41 required FX unit bindings
Passed exactly once. The native device identity is `45F3E708-A2DC-4CFE-BDEC-6F41002F3B43`.

This is a new isolated environment observation, not proof of the original shared simulator's
Busy cause and not a relabelling of that failed invocation. No test-source change was made
between the failed launch and this isolated run. Product/test diff against base `7e9d693`,
captured with `git diff HEAD -- MindBudget MindBudgetTests`, has SHA-256
`bdcb16bd3afcfd808515eee972d4d32de0660da2b2d3b30cbc73f6c4c005566d`.
The isolated run log SHA-256 is
`3e8f0a2b124404b5903ea21854161dce22cd9402274e33c363a180ab758aec55`.
These identify a working-tree probe, not an immutable reviewed commit or distribution bundle.

Integer-money, network, StoreKit catalog, commercialization-document and FX static checks
passed, including 1021 closeout CLI mutations, 484 binding negatives, 1848 detail negatives,
792 disguised-execution negatives and 88 missing-diagnostic negatives. No UI method, complete
validator or new hosted job was run for D; neither the 41 unit bindings nor the static results
close the remaining D acceptance scope.

## Optional iCloud compatibility and privacy candidate — 2026-09-07

The thirteenth `expenseForeignCurrencyMetadata` fact now carries exactly eight closed fields
in the existing encrypted payload, keyed by its expense ID. Envelope version 1, the parent
`.expense` field projection and semantic digest algorithm are unchanged. The iCloud gate pins
the thirteen-type order and the whitespace-normalized pre-D expense projection hash
`204bec476a14f6ef169d094b73ddeae4bdde125c12c296983daa43ba3a9144cd` from `7e9d693`.
Its negative tests reject order/removal/duplicate/parent-field/contract-section mutations.

Matching available upserts validate the tuple and both lineages in one transaction. A retained
FX parent cannot change accounting value without a matching companion; missing matches remain
pending, while malformed/contradictory/ambiguous cohorts are quarantined. Exact duplicate
envelopes are idempotent, including before first application. Undecodable companions do not
silently become parent-only imports. Explicit paired conflict choices preserve the whole local
or remote pair, including a local note-only edit with no independently dirty companion.
The unchanged wire format has no cross-record transaction ID: arbitrary competing revisions
are not resolved by timestamp. Real mixed-version CloudKit scheduling has not been exercised.

Normal parent deletion stages both tombstones; companion-only deletion never deletes the
accounting expense. Accepted parent tombstones prevent child resurrection. Disabled mode,
explicit reupload/recovery, cloud erasure with continued local recording, quarantine isolation,
transaction rollback and ordinary legacy projection compatibility have synthetic fixtures.
No CloudKit client/account, schema deployment or channel activation was used for this work.

Settings now names FX fields in its existing English/Chinese sync disclosure and explains that
paired conflicts use one choice. This is copy within existing controls, not a new UI design.
No FX fields were added to ExpenseSummary, App Entities, Spotlight, notification/telemetry or
AI context types. The consumer fixture captures real Ask/report redaction through a local
throwing model double (four captured prompts per language/variant) and compares ordinary/FX
prompts and Spotlight projections. No model request occurs. A separate source gate rejects
154 field/type injections across fourteen existing private sinks. This narrow source barrier
does not prove arbitrary renamed/reflected fields or new sinks safe; whole-app egress and
runtime gates remain mandatory.

All following probes use Xcode 27 beta 6 / iOS 26.5 on task-owned simulator
`45F3E708-A2DC-4CFE-BDEC-6F41002F3B43`, zero retry, synthetic data only:

| Run basename under `/private/tmp` | Outcome / retained interpretation |
| --- | --- |
| `fx01d-sync-focus-1` | exit 65 before tests: Settings' entity-name switch lacked the new enum case; fixed with localized name. Retained non-pass. |
| `fx01d-sync-focus-2` | exit 65: the new frozen-parent fixture compared full envelope bytes, including informational staging time. Payload/digest/version/lineage comparison now pins the actual frozen contract; no product payload changed. Retained non-pass. |
| `fx01d-sync-focus-3` | exit 0; native summary 53 Passed / 4 existing physical-cloud skips, 57 methods total, zero failures/warnings. Not final-source acceptance. |
| `fx01d-privacy-sync-1` | exit 65: one method had four failed assertions because Spotlight includes eleven existing non-expense index items alongside the expense. Corrected the new assertion to count the exact expense identifier; all ordinary/FX projection and prompt equalities already passed. Retained non-pass. |
| `fx01d-privacy-sync-2` | exit 0; six suites / 152 methods reported by the test log. Native audit and final-source validation are recorded separately below; the later note-only conflict control is not covered by this earlier run. |

Each has matching `.xcresult` and `.log` paths. Failed-run diagnostics again report a subprocess
`simctl` lookup failure; this is diagnostic collection, not the cause of the deterministic test
assertions. The first privacy static-check attempt also failed closed because the checker looked
for `ExpenseSummary` in DataTransferObjects instead of its actual owner Models/Projections;
the corrected owner plus 154 mutation tests passed. These failures are not erased by later runs.

`fx01d-privacy-sync-2-native` subsequently verified 152 method details: 147 Passed / 5 skipped,
149 concrete Passed executions (one existing three-argument method), no Repetition/extra attempt,
no warnings and a parameter tree/detail bijection. The five skips are the four physical-cloud
tests and one opt-in live telemetry test, not provider/transport passes. Its log SHA-256 is
`9187dbdaa857e689a1ce05d52e4e3cdc688ad43f232691a5b79df9fdc5239dff`.

After the note-only conflict control, `fx01d-sync-conflict-1.xcresult` / `.log` exited 0.
Native audit `fx01d-sync-conflict-1-native` verified 58 methods: 54 Passed / four existing
physical-cloud skips, no Repetition/extra attempt, no warnings, tree/detail bijection.
Its log SHA-256 is `11cbe589410271fc8c0f03fb97f22472e3f652882037f1ef34727a3487d8ed76`.
Product/test diff against `7e9d693`, using `git diff HEAD -- MindBudget MindBudgetTests`, is
`1db088798cabfb87c644c6afb2b4118bd4d44312030a4324d849b0e311f3c0d2` at this source checkpoint.
This identifies an uncommitted candidate, not independent review or hosted acceptance.

Current unit admission requires 48 FX bindings (the prior 41 plus seven companion regression
methods), and the unchanged three isolated UI bindings. Four physical-cloud skips never count
as transport evidence. D acceptance, new-head hosted proof and independent review are pending.

## Remaining D acceptance

Retained complete-validator non-pass: `/private/tmp/fx01d-complete-2.log` exited 65. Static gates,
Release build and coverage-enabled test build passed. The separate serial strict benchmark then
measured **0.814581125 seconds > 0.500 seconds** and failed at
`Phase10ReleaseReadinessTests.swift:30`. Ordinary full-suite/coverage/runtime-binding checks and
the FX UI host were not reached by that invocation. The benchmark xcresult is retained at
`DerivedData/MindBudget-bgtxmturevndajczwxgkudyqnrka/Logs/Test/Test-MindBudget-2026.09.07_07-54-17-+0800.xcresult`.
Diagnostic collection again could not locate `simctl` in its subprocess; it is not the reason
the measured assertion failed.

Source comparison against `7e9d693` finds no changes to DashboardView/ViewModel, BudgetEngine,
the benchmark fixture, or `DataActor.fetchExpenseSummaries`; DataActor's D change is confined to
the separate export projection. This is scope evidence, **not a measured causal diagnosis** of
the 814.6 ms result or proof it is transient/pre-existing. No threshold, benchmark skip, timing
interval, normal UI helper or retry setting was changed. The complete local non-pass remains a
blocker; focused passes cannot replace it. Resolving that performance observation is separate
from claiming the iCloud/privacy implementation accepted or entering another phase.

Supplementary `fx01d-final-targeted-1.xcresult` / `.log` exited 0 for its selected methods but
is explicitly non-admissible for the full FX set: its command mistyped the rate/form suite names.
The native binding gate rejected 21 missing methods. The subsequent selection is derived directly
from `UNIT_BINDINGS` rather than hand-entered names; no missing method is counted as a pass.

Retained complete-validator non-pass: `/private/tmp/fx01d-complete-1.log` exited 1 during static
gates, before compilation/tests or creation of a result bundle. The closed repository check
inventory rejected the new `check_fx01_privacy.py` as unclassified. It is now explicitly
classified as an FX-01D nested gate, with its exact wrapper invocation checked; it was not added
as new work to C6's completed migration row. The C6 contract passed after this registration.
The same product/test source requires a fresh complete validator; this failed invocation is
not a partial runtime pass and no source/UI test retry was enabled.

- Complete full local/hosted/native validation, independent review and merged D acceptance.

## Final-source supplementary regressions — 2026-09-07

These runs cover the unchanged product/test diff
`1db088798cabfb87c644c6afb2b4118bd4d44312030a4324d849b0e311f3c0d2`
against `7e9d693`. They do not replace the complete-validator benchmark non-pass above.
All use local Xcode 27 beta 6 / iOS 26.5, not hosted Xcode 26.6 or real iCloud devices.

`fx01d-final-targeted-2.xcresult` / `.log` exited 0. Selection was derived from all types in
`UNIT_BINDINGS`, plus CloudSync, Siri/Ask/report and telemetry suites. Native audit in
`fx01d-final-targeted-2-native` verified 228 methods: 223 Passed / five existing opt-in skips,
227 concrete Passed executions, six argument executions across two parameterized methods,
zero Repetition/extra attempts/runtime warnings and a parameter tree/detail bijection.
The separate FX binding verifier accepted **all 48 mandatory methods exactly once**.
The four physical-cloud skips and one live-telemetry skip remain unexecuted environment gates,
not transport/privacy passes. Log SHA-256:
`20b658c8ce270685286634c286207c9a757cdcba59eaf34702d1b4cdc34d2079`.

`fx01d-ui-1.xcresult` / `.log` completed successfully with its runner's strict three-binding
verification. The runner created simulator `AA1C462C-FC75-4B38-886A-16597242B227` solely for
this invocation, verified each method detail's device ID against that provenance, then shut
down/deleted only that temporary simulator. The logs, result bundle and simulator JSON remain.
Native audit `fx01d-ui-1-native` verified three methods / three Passed executions, no skips,
Repetition or extra attempts. Each method retains one existing
`Invalid frame dimension (negative or non-finite).` diagnostic: three warnings, not zero.
The diagnostic collector's separate `simctl` lookup failure is also retained in the log.

| Isolated UI method | Local duration |
| --- | --- |
| Chinese AX5 expired stewardship edit | 68.879 s |
| Chinese AX5 Pro create/detail | 91.653 s |
| English Pro create/detail | 49.149 s |

These durations are local observations, not predictions of hosted capacity or a relaxation
of the unchanged 240 s allowance. UI log SHA-256:
`1ba26f33e00625c2248e021001e4e2776db4a7482fdba06ec9500ff46d336d58`;
provenance JSON SHA-256:
`e343f46705ac3720d214df11fa761b01dd75d9e20c0617ef5ae72b0bae19dc3d`.

`fx01d-boundaries-1.xcresult` / `.log` exited 0 on the task-owned unit simulator. The ten
selected suites cover receipt lifecycle/import/OCR privacy/structured extraction, Phase 3
reminders, Phase 4 wishlist/cooling-off, Phase 5 patterns, DataActor, SettingsStore and model
contracts. Native audit `fx01d-boundaries-1-native` verified 157 methods / 157 concrete Passed
executions, no skips, Repetition, extra attempts, argument executions or runtime warnings,
and a tree/detail bijection. Log SHA-256:
`a7cdf2895f5b9760d904b3e6325d9b506598aac8ada105a9398e4310700e1700`.
Together with the earlier final-source targeted run, this completes the supplementary
consumer/privacy regression matrix (including notifications, Siri/Ask/report, Spotlight,
telemetry, recurring and deletion). It is neither a full ordinary-suite/coverage acceptance
nor a real-account, final-binary network or old/new physical-device interoperability proof.
The unresolved full-validator performance failure remains the next acceptance blocker.

Insights income/sharing is queued separately after D. Its approved card content is cycle dates,
total income, total spending and spending-category totals only, with Product Design required
when UI work begins. No share-card implementation, iCloud activation, real provider request,
physical run, COM-C12/FX-02 entry, Archive, upload or release is authorized by this D checkpoint.

## PR #117 review and repair diagnostics — 2026-09-07

Retain run `34072691064`, attempt 1, head `f3538f9`, as **failure/non-pass**: ordinary job
`101592835329` succeeded, FX job `101592835535` failed, and the `Build and test` join failed.
Hosted ordinary skips the wall-clock benchmark; its success cannot close local P2-1.
The FX artifact is `MindBudget-fx-xcresult-34072691064-1`, ID `10001187217`.
Its native tree shows Chinese AX5 stewardship edit Passed in 101.374 s and Chinese AX5
create/detail Passed in 123.291 s; English create/detail Failed in 22.748 s after one switch tap.
The three methods ran on provenance UUID `8A2A2702-B4B5-49C6-AC8E-6610AF280E01`; this is a
failed-bundle observation, not admission. The hosted compiler is Xcode 26.6; the artifact's
simulator runtime is iOS 26.5 (23F77), distinct from the local Xcode 27 beta 6 compiler.

The retained activation attachment has native switch frame `(305.3333,132,63,28)`, value 0,
and a safe lane beginning at y=124. The synthesized event really targets `(336.8333,146)`.
Subsequent AX descriptions still report 0; video frames show a stationary, visually off switch.
The helper already uses a single snapshot for activation geometry. These observations do not
identify a stale-coordinate race, a specific recognizer, or a rejected model binding. Additional
temporary public event/control-action diagnostics are investigation only, not a fix or acceptance.
Downloaded originals and exported attachments/video frames are retained under
`/private/tmp/pr117-hosted-34072691064-fx`.

Performance segmentation uses temporary clock-only instrumentation, removed after two probes.
`pr117-perf-stages-1` and `pr117-perf-stages-coverage-1` both exited 0, measuring 195.579 ms and
190.097 ms respectively; the latter explicitly uses `-enableCodeCoverage YES`. Fetching 10,000
models took 114.595/112.553 ms and summary projection 64.233/64.505 ms; budget snapshot/pace were
small. These diagnostic probes did **not reproduce 814.6 ms**, do not establish coverage as its
cause, and do not close the failed complete validator. No timing threshold or fixture changed.

The first attempt to start the temporary touch diagnostic was rejected before process creation
because the tool approval service reported a usage-limit error. No test ran and no result was
accepted from that attempt. The subsequent owner continuation permits the same isolated
diagnostic to proceed; its result must be recorded before interpretation.

Review follow-ups remain explicit: ReminderEngine ordinary/FX equality was a coverage gap;
the saved-rate-date/current-calendar reconstruction needs cross-calendar scrutiny; owner C/D
authority is off-platform, not a GitHub approval; prior required-check/boot/time-limit/hidden-retap
and copy issues remain. D's four checkboxes stay open. New-head complete local success, hosted
ordinary/FX/join success and native no-extra-attempt/device audits, followed by independent
rereview, are still required before undraft; D Done and E entry are not included.

### Completed local diagnostics and next hosted observation

`pr117-touch-diagnostic-1` exited 0 on fresh simulator
`5F2E1988-0CC0-4AE9-B02E-8916FE33DC90` (Xcode 27 beta 6 / iOS 26.5): three FX methods
Passed once, bound to that UUID, with the existing three invalid-frame warnings retained.
Chinese edit/create and English create durations were 38.946 / 79.458 / 41.189 s.
The observer recorded the English `(337,146)` touch reaching a native UISwitch, followed by
`toggleStateChanged:` with `isOn=true`. This is a successful local observation, not the missing
failed hosted recipient trace. Logging may perturb timing. The original temporary observer
was removed and its patch retained separately; no product/performance correction was inferred.
Log SHA-256: `7cf7525cb69cd8b7360b65ca517a15b2018edba587cf1b5248ec070fb96ec3dc`;
event-log SHA-256: `d29d51e4965590c5b098cc525767917496fd94eedba886f5cd3c6264e95041ea`.

Native diagnostics exported from the original failed hosted bundle include the simulator's
system logarchive. Between 01:31:08.663 and 01:31:08.681 UTC UIKit dispatched two events to the
App window, then reported TouchEventsCompleted and an idle main run loop. These logs do not
identify the touch recipient/control action or establish the touch phases from dispatch times
alone. The scoped App log export has SHA-256
`b9add4cb85fbda3c6721ad8eb0611e5f1562dffd1151cbb0eaedf0e97deb4144`.

The candidate now adds the missing real ReminderEngine ordinary/manual-rate/home-override
byte comparisons for template messages, model-error fallback messages and captured redacted
prompts, in both languages and all three tones. The local model double never sends requests.
`pr117-reminder-1` exited 0; native audit verified one Passed method/execution, no Repetition,
extra attempt or runtime warning. Log SHA-256:
`e964f7f6024acfabed6350fce5cc730b3f23ed18fa21a79cd819492e6dc1ff4b`.
The current mandatory count is 49 FX unit bindings and 165 privacy mutations across 15 sinks
(adding ReminderEngine). Earlier 48-binding/154-mutation evidence remains historical, not
acceptance for this additional test.

A **temporary hosted diagnostic candidate** reinstates the public UIApplication/UIControl
dispatch observer exclusively in the Debug-only simulator FX test executable. Installation is
one-time and fail-closed; original dispatch forwards once. It adds no gesture, retap, delay,
threshold/allowance change, private API, production logging or real-data capture. Ordinary and
Release executables exclude this source branch. Existing xcresult diagnostics retain its logs;
the runner lifecycle and isolated-device cleanup are unchanged. This candidate must not be
merged as a fix: remove the observer after investigation, then validate a final repair head.
Neither a successful instrumented hosted run nor another focused benchmark closes the two P2
findings. Complete local acceptance and final-head hosted/native acceptance remain open.

### Diagnostic head c1f0db2 retained non-pass and readable trace

Hosted `34077058451` attempt 1 failed on `c1f0db2`: ordinary succeeded; FX and join failed.
Chinese AX5 create failed at one switch tap (33.247 s); Chinese stewardship and English create
Passed in 169.446 / 100.488 s. The observer is not a fix and this is not acceptance. The full
local 814.6 ms benchmark remains open independently. Preserve both failed hosted runs.

The review correctly keeps both P2 findings open. Its statement that no readable dispatch was
retained is corrected by the original exported App console lines 105681–105684 and the native
system.logarchive: the failed thumb receives began/ended, then its native long-press/pan fail,
with no control action. The 125pt row contains a 28pt native switch; the recorded tap already
matches the latter's centre. See `FX_01D_SWITCH_DIAGNOSTIC.md` for exact extraction, artifact
identity, geometry, scoped log hash and limitations. No unavailable internal cause is asserted.

A working-tree candidate moves the same one tap to the native off track outside the observed
thumb. One deterministic geometry test Passed locally; a single isolated instrumented run is
underway to verify the target path, not to admit the candidate. The observer must then be
removed. Complete local validation, final-head hosted/native audits and rereview remain required.

The candidate's isolated diagnostic has now completed: three Passed once, strict UUID binding,
existing warnings retained; the off-track dispatch is observed to avoid the thumb and emit one
control action. This is local path evidence, not a complete causal proof or hosted acceptance.
The observer was then entirely removed and the FX host restored exactly to `f3538f9`; the static
isolation gate rejects three dispatch-replacement APIs. Exact hashes, durations and the limitation
that native long-press still participates are appended to `FX_01D_SWITCH_DIAGNOSTIC.md`.
Prepare an observer-free repair candidate with the one-tap geometry control only; no benchmark
code, 500ms ceiling, retry/allowance or product view has changed. Both P2 findings remain open
until the complete validation and independent rereview conditions are actually satisfied.
