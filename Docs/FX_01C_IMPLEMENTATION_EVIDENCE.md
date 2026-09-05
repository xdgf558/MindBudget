# FX-01C manual-entry implementation evidence

Status: **FX-01C In Progress; candidate validation and independent review pending.**

This packet covers the manual entry, saved detail, edit, and existing Commerce access boundary
only. It does not close FX-01, enter FX-01D/E or FX-02, enable optional services, or authorize
COM-C12, physical runs, Archive, upload, distribution, or release. PR #113 closed B separately;
the C owner entry and its exact provenance remain in `FX_01_MANUAL_CURRENCY_PLAN.md`.

Current runtime checkpoint: `b441df9` passed hosted `33952509502` and its native artifact audit,
but **did not pass complete acceptance**. A complete local recapture exited 65 on neonPulse
Terms navigation in the three-theme AX5 method. A previous local invocation's staged passes
also retain an unresolved wrapper/log-continuity provenance gap; neither it nor a later focused
pass is a complete local `validate.sh` pass. The earlier `bb4366b` hosted `33930201365` About
failure and 808.754667 ms > 500 ms benchmark failure remain non-pass. The session log records
these outcomes separately. The owner's latest review found no source P1/P2 but retained the
local failure as a merge blocker and required this repository synchronization. PR #114 remains
Draft. A repair requires new exact-head hosted/native evidence, one complete local validator
pass and owner review; it does not close C or enter D.

Post-review diagnostic checkpoint: the subsequent focused and complete ordinary-UI diagnostic
experiments did not reproduce the Terms failure. The complete UI diagnostic contains 21 Passed
and three existing Skipped methods, each once, but used temporary instrumentation and is **not**
`validate.sh` acceptance or proof of a repair. All diagnostic Swift was removed; product, tests,
scripts and project source again match b441df9. This documentation-only synchronization closes
the missing-record gap, not the original wrapper gap, the Terms non-pass, or FX-01C. The next
source repair still needs a captured mechanism; further green reruns alone cannot supply it.

## Implementation boundary

- `ForeignCurrencyFormState` retains user inputs and resolves through the accepted B integer
  converter. A validation error produces no usable preview or write. An explicit accounting
  override retains its exact amount-derived fraction across reopening; its rounded display rate
  is not parsed back into authority. Editing uses the saved row's accounting currency and rate
  time zone, not changed settings or a changed device time zone.
- The single `PremiumFeature.manualForeignCurrency` consumes the existing Pro snapshot; C adds
  no trial clock or StoreKit product. DataActor checks the live authority immediately before a
  new FX write or ordinary-to-FX conversion. Existing persisted FX retains Free stewardship.
  Caller-supplied metadata is not proof of existing ownership. Recurring, receipt and wishlist
  creation are not expanded into FX. Ordinary expense entry remains Free.
- The form exposes original currency/amount, manual rate, rate date, locked accounting preview,
  and explicit accounting override. Saved detail shows original amount first, accounting
  approximation second, and rate direction/date/source. English and Simplified Chinese are
  localized. The source date formatting explicitly uses the saved rate time zone.
- C preserves B's frozen Expense envelope and pre-D FX/sync exclusion. Consumer/CSV work and the
  thirteenth encrypted iCloud companion envelope belong to D, not this packet.

## Test host and runtime acceptance

The normal `MindBudget` application and complete default suite remain mandatory. Additional UI
coverage uses a different executable entry compiled only with Debug, simulator, and the explicit
`MINDBUDGET_FX_UI_TEST_HOST` build flag. No normal configuration enables that flag. The dedicated
scheme has no Launch/Profile/Archive action. The alternate entry constructs only an in-memory
store, isolated preferences, a fixed Commerce test authority and the real form/detail views;
it does not construct AppBootstrap, StoreKit or network/system lifecycles. The notification
dependency is a fail-on-call stub. These UI results cannot prove a StoreKit purchase or physical
VoiceOver behavior, and their compile-time fixture cannot grant normal-app paid rights.

`Scripts/fx01_ui_contract.py` owns 32 exact FX unit bindings (17 B and 15 C) and two UI bindings.
It reads this run's native tree and each required test's native details, requires one Passed
device/configuration/execution, and rejects skipped, failed, duplicate, parameterized or unknown
attempt shapes. No schema-version override or C6 tree-reader dependency is used. The UI runner
requires fresh result and DerivedData paths, normal simulator signing and no test retries.
Hosted artifacts must retain both ordinary and dedicated UI bundles.

## Retained local development non-passes

All paths below are local `/private/tmp/mindbudget-fx01c-*` artifacts, not public hosted evidence.
They do not satisfy final-head acceptance.

| Run | Result and disposition |
| --- | --- |
| `focused-1` | Two new assertions expected `6.00` instead of the existing parser's `6`; corrected as assertion-format mistakes. Non-pass. |
| `focused-2` | 50 methods Passed, including all 32 FX bindings, with no retry. Retrospective strict native verification passed, but later Swift edits require fresh evidence. |
| `ui-1` through `ui-3` | SKTestSession configuration writes failed with SKInternalErrorDomain Code 3 / notEntitled before reaching the form. No purchase or form pass claimed. |
| `host-ui-1` through `host-ui-3` | Iterations exposed switch-label targeting, menu virtualization, obscured underlying host-strip geometry, then AX5 form width 457pt in a 402pt window. All whole runs non-pass. |
| `host-ui-4` | Reused unsigned artifacts executed removed assertion paths; not accepted as current-source proof. Permanent runner now requires fresh DerivedData and normal signing. |
| `host-ui-5` through `host-ui-8` | English passed, Chinese preview remained obscured by fixed Save. Outer-padding gestures did not scroll usefully. Whole runs non-pass; per-method 240s timeout added after run 5. |
| `host-ui-9` | Both cases failed. Per-pan coordinates exposed gestures consumed by the accounting TextField; slow release alone did not fix it. Non-pass. |
| `host-ui-10` | English passed after avoiding text-editor pan origins. Chinese hit a viewport filled by the embedded date wheel. Whole run non-pass. |
| `host-ui-11` | The separate AX5 date sheet allowed Chinese creation; an edit pan starting on its button reopened it. English passed, but the whole run remains non-pass. |
| `host-ui-12` | The new date mutation and accessibility values passed; Chinese editing still activated the date editor while panning with the keyboard present. English passed; whole run non-pass. |
| `host-ui-13` | Both tests executed once Passed (104.530s Chinese / 40.663s English); the initial wrapper rejected native Runtime Warning leaves as unknown attempts. The reviewed diagnostic-reader remediation revalidates the same bundle; it does not erase the original wrapper non-pass. |

The candidate replaces the AX5 embedded date wheel with a wrappable date button and independent
native date-editor sheet. Ordinary sizes retain compact date selection. Neither content text
nor the form environment is capped. The UI test keeps full target-frame visibility above Save
and below navigation; it does not treat `isHittable` alone as proof of readable content.
Pan origins exclude buttons as well as text editors and wheels. The candidate UI assertions
inspect localized input labels/values, original-before-accounting order in the combined
accessibility element, and the saved/reopened year after a real date-wheel change. They do not
claim a physical spoken VoiceOver session.
FX numeric fields also expose a localized keyboard Done action while focused; the candidate UI
must press it and observe keyboard dismissal before reading the preview. Ordinary-entry fields
do not acquire that toolbar. The hosted timeout is 60 minutes to accommodate the additional
fresh host build after the complete ordinary suite (B closeout already used 35m25s).

Run 13 contains two `Invalid frame dimension (negative or non-finite).` diagnostics, one per
test, represented in both the tree and native details. Native activity timing places them after
the first original-amount tap and before entering `3`; source URLs are empty. Both independent
and author inspection of the four retained screenshots found the amounts/preview readable, but
the emitting source has not been identified and the warnings are **not fixed or dismissed**.
The native reader separates only exact `{name, nodeType}` non-execution Runtime Warning leaves,
requires matching tree/detail warning multisets and reports each once. Extra keys, identities,
results or nested children cannot disguise an execution as a warning; retry acceptance is
unchanged. Self-tests add 612 disguised-execution negatives and 68 diagnostic-mismatch negatives,
with four real CLI positives / 16 negatives. The fresh complete validator must run this reader
against its own new bundle; retrospective run-13 verification is remediation evidence only.

## Review and remaining acceptance

The implementation author performed the development checks above. A separate read-only review
agent inspected the entry and implementation boundaries; intermediate review is not final-head
approval. Its two gate P2 findings and subsequent independent reproduction/closure are recorded
in `SESSION_LOG.md`, including the exact reviewed script SHA. No independent review is attributed
to work that only received author self-inspection.

The full candidate source review found no P1/P2/P3 at UI-test SHA-256
`66d7bdfb57560aa31460912534c4dde58c40463a8bf9d950875acae30c77b5d5` and sorted 36-file SHA-list
digest `7786d1da7d0164d197a29680740639c58dcecd8b4e057cd40cee7035c302788b` on base `ebd5785`.
The reviewer ran static checks only, did not modify source or start Xcode/devices, and explicitly
withheld a frozen-head/merge approval pending execution evidence. Later documentation additions
are not retrospectively included in that snapshot.

- [ ] Fresh final-candidate unit and dedicated UI execution, including localization/accessibility metadata.
- [ ] Complete ordinary application validation, Release build, coverage and strict local performance check.
- [ ] Final frozen-head independent review and exact-head hosted CI with native execution audit.
- [ ] Merge, then separate reviewed/green documentation closeout before D entry.

## Hosted native-format remediation — acceptance still pending

PR #114's initial head `7460081` passed complete local validation and independent native review:
606 ordinary method details (590 Passed / 16 Skipped), 615 concrete results, all 32 FX unit
bindings, a separate strict benchmark and two fresh FX UI methods each Passed once. No extra
attempt or Failed-to-Passed was observed. The two layout warnings remain unresolved; the logs
also retain a Binding setter compiler warning and simulator diagnostic-collection error.

Hosted run `33885693529` attempt 1 nevertheless failed. Ordinary tests, coverage and C6-02's
23 bindings passed; FX's native configuration check then rejected the first required method.
The dedicated FX UI stage never ran. This is a non-pass, not a hosted UI pass or a retried success.
The downloaded ordinary artifact's SHA-256 is
`fd8225714b4f128a51c382ba805922dfb4b199844ccf327f6f4cbc24dfa18a9e`. Xcode 27 re-reading it
confirmed the full local inventory without extra attempts, but could not prove Xcode 26 output.

Read-only diagnostic run `33890321460` on `934cf50` used Xcode 26.6 build `17F113` to read that
fixed artifact, without a build, app launch or test. Its JSON proves the sole gate-relevant
difference: the configuration execution node omits `nodeIdentifierURL`, while the main case and
detail URLs, nonempty device/configuration IDs and single Passed execution agree. The native JSON
is frozen unchanged at `Scripts/Fixtures/fx_native_xcode26.json`, SHA-256
`dbd4dd3b6546a64b1368b702582f8cba29d96eb3ffd622dcd5632b3f42387628`; the diagnostic ZIP is
`ee6680bd2aa2d7367611a986dc3a8f19af741571e0d6cba5a6fd99e54b2fcb06`.

The remediation permits only absence of that redundant configuration URL. When present, it must
match exactly; null, empty, wrong-typed or mismatched values fail. Main case/detail identity,
nonempty string device/configuration IDs, one Passed execution and diagnostic closure remain
mandatory. IDs are never stringified. Both configuration shapes receive the same negative tests,
including missing main identity, wrong IDs, duplicate executions and hidden Failed-to-Passed.
Self-tests cover the real native sample, 1,428 negative details and nine production-CLI positive /
34 negative fixtures, alongside the existing isolation, tree and diagnostic negatives.

The temporary diagnostic workflow has been removed; its ordinary CI `33890321361` was cancelled
as redundant before the reader was fixed and remains non-pass. The diagnostic success is not
current-head acceptance. Swift product/tests, the normal workflow and validation order are
unchanged. A new exact-head full hosted run and independent rereview/native audit remain required.

## Subsequent hosted green run — independent acceptance non-pass

Run `33892068800` attempt 1 on `4d8a856` is GitHub success but **not accepted**. The independent
all-606-detail audit found `testCategoryChartLegendKeepsSixItemsReachableInEnglish()` Failed
before Retry 1 Passed. There are 616 concrete results: 599 Passed, 16 Skipped and 1 Failed,
with one extra attempt; the aggregate method inventory is still 590 Passed / 16 Skipped.
The failure occurred when the budget helper typed into `budget.totalBudget` before that field
had keyboard focus, while the preceding income field still did. The cause of the missed focus
transfer is not proven. This is not a schema-reader mismatch or a transient accepted by rerun.

C6-02's 23 bindings, FX's 32 unit bindings and two dedicated FX UI cases independently passed;
the dedicated UI has no retry and retains two layout warnings. Those partial results and the
fresh complete local validation at `4d8a856` cannot substitute for the required ordinary hosted
regression pass. The original hosted ZIP digest is recorded in `SESSION_LOG.md`; native-reader
working databases are distinguished from original archive bytes. PR #114 remains Draft and
unmerged. A new source remediation needs independent rereview and new exact-head evidence.

## Full local ordinary Settings failure — retained non-pass

At `221dcd9`, complete local validation exited 65 in the ordinary suite: 606 method records are
589 Passed / 16 Skipped / 1 Failed, with device totals of 598 Passed / 16 Skipped / 1 Failed.
`testSettingsShowsExportAndPrivacyControls()` ran once for 70.215324998s and failed at the `0.9.1`
history existence assertion. Ordinary UI totals are 16 Passed / 3 Skipped / 1 Failed. The separate
strict benchmark passed, but subsequent coverage, C6-02/FX unit verification and dedicated FX UI
were not executed after the ordinary failure. None is claimed as this run's downstream pass.

Independent read-only inspection of the closed result and the author's recorded-frame inspection
establish that history was expanded and still showing `0.9.2` after the fixed five swipes. The
final native hierarchy places the list at about 81% of eight pages. This is a deep-row lookup
failure, not proven product corruption or a failed disclosure tap. The test-only candidate keeps
`0.9.1`, scopes small drags to About's list and requires uniquely identified heading progress and
full target visibility. Its focused result and independent source rereview are pending. Hosted
run `33900664975` belongs to the older frozen `221dcd9`, not the new test-helper candidate.

Subsequent focused evidence: the same Settings method ran once Passed in 91.640970945s, with
no skipped/extra/Failed-to-Passed execution or native runtime warning. Independent native and
activity review confirmed one disclosure tap, the separate `0.9.8` anchor, nine progress-checked
drags and the original `0.9.1` target. Author and reviewer inspected the final retained screenshot.
The five-file test/document source delta was independently accepted for freezing, not merging.
This scoped result does not erase the failed full run; fresh exact-head complete local and
hosted validation, including all downstream stages, remain mandatory.

## Hosted no-retry budget non-pass and replacement candidate

Older head `221dcd9428033a2d891d7a6b1addab970c472cd7` hosted run `33900664975` is a terminal failure,
not reusable evidence. Its ordinary native summary contains 606 methods: 588 Passed, 16 Skipped
and two Failed; device/configuration totals are 597 Passed, 16 Skipped and two Failed. Each failed
detail has exactly one device, one configuration and one concrete Failed run, with no Repetition:
`testAccessibilityExtraLargeKeepsPrimaryActionsAndNavigationReachable` failed in 78.937368989s
during the first English AX1 setup, before its AX5 launch; the Simplified Chinese category case
failed in 33.957931995s before first saving-goal typing. Both ended at the same saving-goal settle
assertion. Failure-only native export found no attachments. The GitHub artifact was 206167652
bytes with upload SHA-256 `66eb27e4c25860672a24c90cb07c585fa874c20f735528d9b5f610ece07e3c4c`;
the downloaded extraction was preserved while a separate working copy was opened by Xcode 27.

The log proves the stable-frame predicate itself is not portable under hosted load: one flow lost
keyboard existence on its second poll; the other spent the window on two polls without an accepted
exact-equal pair. It cannot distinguish the underlying product/system state because actual frames
and subcondition values were not recorded. Independent review therefore withdrew whole-head
acceptance and kept only the About focused fix and strict benchmark conditionally accepted.

Later head `c332e539ed00b60b9e94851112108569dc7a11d7` completed local full run 4 without runner
retry. Its native audit verifies all 606 details (590 Passed / 16 Skipped), 615 concrete entries
(599 Passed / 16 Skipped), the exact prior inventory and zero extra/failed attempts. Coverage,
23 C6 bindings, 32 FX unit bindings and both dedicated FX UI methods also passed; the UI bundle
retains its two known layout diagnostics. This is not acceptance: that head changed only About
lookup and retained the budget helper that failed hosted twice.

Hosted run `33903657605` on that same `c332e53` then also completed Failure with retries disabled.
Native summary/tree report 606 methods at 587 Passed / 16 Skipped / three Failed and concrete
device totals of 596 Passed / 16 Skipped / three Failed, with no runtime warning. Each failed
detail is `Test case with 1 run`, one device/configuration/concrete Failed result and no Repetition:
English AX1/AX5 stopped at the old monthly-income settle wait in 63.294551969s; language switching
stopped at total-budget settle in 60.428116918s; English category stopped at monthly-income settle
in 50.726115108s. The artifact is 262437777 bytes and its upload SHA-256 is
`e0c7c6d1d126cb6c115fa75f75849c148eb7620ccbe12d8e56cc856ad2e99406`. The original extraction
remains preserved while native inspection uses a separate working copy. This is a second hosted
non-pass for the superseded exact-frame helper, not evidence for the later working-tree repair.

The next source candidate removes exact-frame equality, not safety. It separates a no-tap bounded
field reveal from a two-center-tap input preparation around keyboard appearance and keyboard-driven
layout. It then performs one dedicated two-tap move to monthly income, followed by three no-tap
reveals and exact value readbacks. Targeted typing remains exactly once per input, but only the
later three-value readback is treated as authority. Public frame/condition diagnostics accompany
failures. Focused tests, independent rereview, a new frozen head and complete fresh local/hosted
native acceptance remain required; C is not Done and D is not entered.

The first replacement-focused command reached Swift compilation but failed before testing because
two diagnostic string interpolations escaped inner string literals incorrectly. Its result bundle
contains no runtime evidence and remains non-pass. The diagnostic builds those optional frame
strings as separate values instead; no interaction condition changed. A new result path is required.

Replacement-focused probe 2 then passed all four requested methods once on the specified iOS 26.5
simulator: English AX1/AX5, English category, Simplified Chinese category and pseudo-long. Native
summary and all-detail inspection agree on four Passed methods, four concrete Passed executions,
zero skips, failures, repetitions, extra attempts or runtime warnings. The AX method intentionally
contains two launches, one at AX1 and one at AX5; each launch typed 3000/2500/500 exactly once,
used two center taps for each input, used one further two-tap monthly-income preparation intended
to move away from the final editor and then
performed three no-tap exact readbacks. Each other method has one launch and the same per-setup
interaction counts. The five static gates also passed on this source candidate.

Implementation-separated read-only rereview found no P1/P2/P3 in the candidate at UI-test
SHA-256 `5eb40d7670f684fa1d42fcffa371d0dd83b60f53e3f7bb0de26f34746d52a54b`. That review accepts the
source and focused result for freezing only. It is relayed by the implementation account and does
not represent another GitHub account or a human approval. A new committed head, exact-head source
rereview and complete local/hosted native acceptance remain mandatory. Because the later hosted
non-pass additionally identified the language-switch method, a fresh focused probe must include
that method before freeze; the four-method result alone does not close C or authorize D.

Focused probe 3 used a new result path and added that language-switch method to the prior four.
Native summary and every detail report five Passed methods, five concrete Passed executions and
zero skip, failure, Repetition, extra attempt or runtime warning. English AX1/AX5 has the intended
two launches; each launch has one targeted input for each value, four monthly-income center taps
(including the two-tap post-input preparation), two taps for each other editor and one exact
readback per field. Each of the other four methods has one launch and corresponding 1/4/2/2
type/monthly/total/saving activity counts plus three exact readbacks. This is the complete focused
scope for every method seen failing the superseded helper. It still permits only final source and
runtime rereview before freeze; it is not complete-validation or merge evidence.

## Exact-head green execution superseded by actor-contract P2

Head `c2fd249a7467df995c898746b8e524efd0d4c553` passed a complete local validator without
test retries or the local strict-benchmark skip. Its native ordinary inventory contains 606 test
methods (590 Passed / 16 Skipped), 615 concrete executions (599 Passed / 16 Skipped), all 23 C6
and 32 FX unit bindings, zero failed/extra attempts and exact inventory equality with the accepted
prior full bundle. The separate strict 500 ms benchmark passed once. Both dedicated FX UI methods
passed once and retain exactly one known layout diagnostic each.

Hosted run `33909424630` also succeeded on that exact head without retries. Native inspection of
the downloaded artifact confirms the same ordinary inventory and every one of its 606 details,
plus two single-run dedicated FX UI passes. Hosted skips only the nondeterministic 500 ms wall-clock
oracle; the deterministic 10,000-row projection test is present once and Passed. Artifact
`9952259201` has upload SHA-256
`34bf2f8d667a2c296857f401cc747b1092faab618df5c4995ecf3d20762cf205`.

This green result is **not** merge acceptance. Independent final review found that
`ForeignCurrencyEntrySection.numericField` erased its three main-actor form-update closures into a
plain escaping parameter before passing them to SwiftUI's sendable `Binding` setter. The hosted
Xcode 26.6 log emitted that warning. The helper now preserves `@MainActor @Sendable` explicitly;
an Xcode 27 build completed without that source warning, but this compile check is not a new full
acceptance run. Because product Swift changed, a new committed head requires fresh source review,
complete local validation, hosted validation and native artifact audit. C remains In Progress and
D remains unentered.

## Hosted Xcode 26.6 compiler-crash non-pass and replacement candidate

Hosted run `33917389140` failed on exact head
`add6231aab9ae731c57b01415eb8aa3f06c4ba97` during the Release build, before any test ran.
Xcode 26.6's Swift 6.3.3 frontend aborted while emitting IR for a compiler-generated closure
conversion thunk. The trigger was the explicit `@MainActor @Sendable (String) -> Void` parameter
added to `ForeignCurrencyEntrySection.numericField`; the build ended with both architecture
compilation and project-build failures. All preceding hosted static gates passed. This run is a
non-pass and its uploaded report cannot be treated as runtime evidence.

The replacement removes the function parameter rather than weakening its annotations. Callers
now pass one of three `Sendable` field identities. `numericField` constructs the SwiftUI `Binding`
setter directly in the view's actor-isolated context and exhaustively dispatches original amount,
rate or accounting amount to the existing form-state mutation methods. No unchecked annotation,
compatibility escape or warning suppression is used, and all three input behaviors remain in the
dedicated UI coverage. A local Xcode 27 Release build completed for arm64 and x86_64 simulator
architectures. That compile probe neither proves Xcode 26.6 compatibility nor replaces a complete
validator run. The working tree must be committed, rereviewed and receive fresh local plus hosted
native acceptance. C remains In Progress and D remains unentered.

## Budget snapshot repair — direct owner-review handoff

Hosted `33921069764` attempt 1 on `bed216b` passed Release/test compilation but failed the
ordinary AX5 budget setup: `keyboard.exists` and `keyboard.frame` resolved different UI states.
Native summary/tree contain 606 methods (589 Passed / 16 Skipped / 1 Failed), and the failed
detail is one Failed execution of 205.671247s, before exact amount readback. The verified ZIP
SHA-256 is `fa8ae0ab77ac2b013bae868f99a7ae1c0f79af72da3e5a4a1ceda139336e7fd8`; it contains only
the ordinary bundle. This remains non-pass; downstream binding checks and dedicated FX UI were
not reached. The earlier complete local pass on bed216b does not substitute for hosted evidence.

The test-only repair captures field/save/navigation/keyboard frames from one public application
snapshot per sample. Errors and invalid/ambiguous geometry stop setup; diagnostics use already
captured values. Multiple visible chrome frames narrow rather than widen the lane. An absent
virtualized target only allows another bounded reveal. Save must fit completely below navigation
and above the keyboard; captured target centers replace live frame resolution during input taps.
The three exact readbacks, typing counts, 12-drag bounds, Save-to-Dashboard handshake and
no-runner-retry configuration remain. Two deterministic helper tests cover coherent sampling,
keyboard disappearance, conservative bounds and rejected capture/geometry failures.

The owner will personally review this repair in existing PR #114 and requested direct handoff
after implementation/local checks, without another agent-approval cycle. No new source review
approval, complete-suite pass, hosted pass or merge is claimed for this repair at this checkpoint.
Product Swift, schema, CSV/iCloud, network channels, timeouts and test retries are unchanged.
C remains In Progress; D requires the separate post-merge closeout.

Local repair verification now covers seven distinct methods on UI-test SHA-256
`35cad00344527dfb07eb9300c85439164d2a9e7712b3bffd6a2608b31250a071`: two geometry contracts,
English AX1/AX5, language switching, English/Chinese category charts and pseudo-long text.
The first bundle contains six actual Passed methods, not the intended seven, because the
pseudo-long selector was misspelled. A separate fresh bundle executes the correct missing
method once Passed. Native summary/tree/all details across both bundles verify seven concrete
Passed runs with zero skip, failure, extra attempt or runtime warning; no method is duplicated
between bundles. Five static gates and `git diff --check` passed. These focused author checks
do not replace full ordinary validation or the hosted workflow; the owner will review the PR.
