# COM-C6 Execution Packet

Status: **Done after independent review of exact PR #96 head `3ed1357`, green GitHub Actions run
`33508360536`, and PR #96 merge `246e7c1` under DEC-COM-091.**

C6-01 is Done after independent rereview approved exact remediation head `f77d2a6`, hosted run
`33255898196` passed, and PR #86 merged as `015d00e`. The owner explicitly entered C6-02 on
2026-08-30. Independent final review approved exact PR #93 head `016dd33`, hosted run
`33405016652` passed, and PR #93 merged as `c940e8e`; DEC-COM-088 marks C6-02 Done. The owner
entered C6-03 on 2026-09-01 and bounded its authority to a reviewed/green/merged build-10 Archive
and transport upload, without tester assignment or public release.
Independent review then approved exact preparation head `11ab612`, hosted run `33488815168`
passed, and PR #95 merged as `d5d0959`. The Distribution export passed inspection and App Store
Connect accepted delivery UUID `1b358d3b-4544-4617-ab47-5be69addc7a8` for processing.

Owner entry: the project owner explicitly entered COM-C6 on 2026-08-29 after PR #85 merged the
COM-C5 closeout as `008b674`.

C6-02 entry: the project owner explicitly entered C6-02 on 2026-08-30. This authorizes source and
signed-device preflight only; it does not authorize archive, upload, deployment, App Store Connect
write, tester assignment, G1, distribution, or release.

C6-03 entry: DEC-COM-089 records that the project owner explicitly entered C6-03 on 2026-09-01 and
authorized one `0.9.9 (10)` Archive plus TestFlight transport upload after the exact preparation
head passes independent review, hosted CI, and merge. `C6_03_RELEASE_BASELINE.md` owns the candidate
checklist. The authority ends when
transport accepts build 10 and excludes tester assignment, external Beta App Review, App Store
submission, service/schema deployment, G1, and public release.

C6-03 execution: DEC-COM-090 records the exact reviewed merge, the explicit non-pass from the
first export attempt, the later cloud-managed Apple Distribution export, Production APS/CloudKit
inspection, and transport acceptance at `2026-09-01 19:27:25 +0800`. The accepted upload is not
tester assignment, distribution, or release evidence.

## Scope and sequence

COM-C6 prepares one reviewed TestFlight baseline without authorizing public release. Work remains
strictly sequential:

1. **C6-01 — Automated release matrix.** Freeze and run the repository-controlled automated
   evidence rows described below.
2. **C6-02 — Signed-device and App Review preflight.** Begin only after C6-01 is independently
   reviewed, green in hosted CI, merged, and the owner explicitly enters C6-02.
3. **C6-03 — TestFlight baseline.** Begin only after C6-02 is accepted. Archive and upload require
   a separate owner instruction at that time.

C6-01 and C6-02 performed no archive, upload, Staging or Production deployment, App Store Connect
write, tester assignment, schema deployment, customer-data collection, G1 decision, or release
action. C6-03 is the first bounded Archive/upload phase.

## C6-01 closed automated matrix

`C6_RELEASE_MATRIX.json` is the canonical machine-readable inventory. Its validator rejects
unknown keys, missing or reordered rows, unsafe paths, missing test methods, unknown static
checks, remote Worker commands, and any relaxation of the five blocked remote actions. The seven
required rows are:

| Row | Automated evidence | Boundary retained for C6-02/C12 |
|---|---|---|
| StoreKit lifecycle and entitlement | Exact access matrix, StoreKit environment/bundle authority, lifecycle states, trial projection, and the accepted StoreKit fixture | Signed-device purchase, restore, manage, price, trial, and legal presentation |
| Signed public configuration and R1 network | Verification/cache/expiry/transport regressions, exact endpoint allow-list, Worker tests/typecheck/dry-run | Final Release-binary traffic and App Review inspection |
| Migration and rollback | V1–V4 upgrade, interrupted restore, corrupt manifest, invalid-fact preservation, and money static gate | Archive/device data-protection inspection; never a customer-store rewrite |
| Free private iCloud | Default-off construction, local-first transport failure, and sticky trust-boundary tests | Owner-waived physical observations remain explicit non-passes; Distribution/Production proof is not waived |
| Local receipt pipeline | Bounded image lifecycle, OCR privacy filter, deterministic extraction, 60+ fixture matrix, and explicit-Save integration | Final-binary camera/photo-picker, accessibility, privacy disclosure, and signed-device memory inspection |
| Optional telemetry | Retained deletion proofs, retry after stop, local Delete All independence, Worker lifecycle/TTL/idempotency tests, and closed static contracts | Development synthetic evidence is not customer, final-binary, G1, or App Store Connect evidence |
| Offline local Pro | An injected verified local-Pro snapshot remains authoritative while public configuration is offline and telemetry is unavailable | Airplane-mode observation on the signed release candidate |

The top-level runner first validates the JSON contract and its negative self-tests, runs every
referenced static gate, executes the exact local `check` script for both first-party Workers, builds
Release for the simulator, builds tests once, and then executes the 16 named Swift test containers
serially into one xcresult. It then reads that exact bundle through the active Xcode toolchain's
native `xcresulttool` shape and
requires every one of the 33 row/method bindings to appear exactly once as a Test Case with result
`Passed`; a missing, disabled/skipped, duplicated, wrong-type, commented-out, or non-test method is
non-evidence and fails the matrix. Parameterized Swift Testing methods bind by their exact test type
and method basename while their argument rows remain subordinate evidence. Worker `check` scripts
may typecheck, test, profile, and perform local dry-runs; they may not deploy.

Repository check discovery is also closed. Every `Scripts/**/check-*.sh` or
`Scripts/**/check_*.py` file must be either one of the twelve row-driven matrix checks or one of
three exact special classifications: `check-c6-release-matrix.sh` is the matrix bootstrap,
`check-coverage.sh` is the full-suite coverage consumer, and
`check_c6_02_acceptance.py` is the bounded C6-02 result verifier. These roles are closed rather
than inferred from filenames; all other checks must be row-driven. `check-coverage.sh` consumes
the full-suite xcresult produced by `Scripts/validate.sh`. A newly
added but unclassified check makes the C6 contract fail instead of silently falling outside the
release matrix.

## New cross-domain regression

`CommercializationEntitlementTests.optionalNetworkFailuresCannotChangeTheInjectedLocalProSnapshot`
constructs an in-memory app session with a verified Pro entitlement, an offline public-
configuration service, and the unavailable telemetry service. It proves that the conservative
configuration and unavailable telemetry snapshots cannot revoke Apple on-device AI, advanced
local insights, custom cooling periods, purchase/review flows, advanced Siri, or the accepted
local receipt tier. The test does not simulate StoreKit authority; the separate StoreKit rows own
that verification.

## Commands

Contract only:

```bash
Scripts/check-c6-release-matrix.sh
```

Complete automated matrix:

```bash
DEVELOPER_DIR=/Applications/Xcode-27-beta-6.app/Contents/Developer \
  Scripts/run-c6-release-matrix.sh
```

The ordinary repository validator also runs the C6 matrix contract:

```bash
Scripts/validate.sh
```

## C6-02 mandatory handoff

C6-01 does not satisfy the independent privacy-source review preserved by PR #85. Before any App
Store Connect privacy answer is copied or accepted, C6-02 must independently inspect:

- `MindBudget/Resources/PrivacyInfo.xcprivacy`;
- the telemetry capture in `MindBudget/Features/AddExpense/AddExpenseView.swift`;
- the telemetry capture in `MindBudget/Features/Commerce/ProSubscriptionView.swift`;
- the `TelemetryService` wiring in `MindBudget/Services/TelemetryClient.swift`; and
- `Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md`.

The implementation-author C5 supplemental inspection does not satisfy this gate. C6-02 also owns
signed-device purchase/restore/manage testing, release entitlements,
privacy/data-protection/localization/accessibility evidence, and every accepted manual release-
checklist item. `C6_02_PREFLIGHT.md` is the current evidence packet. C6-02 may exercise the
distribution inspector against a development-signed Release app, but final Archive/IPA evidence
is impossible before archive authority and therefore remains a mandatory C6-03 rerun rather than
something C6-02 may infer.

The first C6-02 five-surface pass found that the closed `subscription_action` outcome meets
Apple's Purchase History definition. The checked-in privacy manifest now declares exactly Product
Interaction, Device ID, and Purchase History as Analytics-only, unlinked, and non-tracking. A
closed validator checks both source and embedded manifests. One Release-configuration app was
development-signed, inspected, installed, and launched on an iPhone Air running iOS 26.6.1. Its
development `aps-environment` and `get-task-allow=true` are expressly not distribution evidence.
Independent review accepted exact PR #88 head `0ac0500`, hosted run `33283398690` passed, and PR
#88 merged as `6c2a051`. Its one non-blocking P2 found that the required-reason declaration was
pinned rather than derived from production source. `Scripts/check_required_reason_apis.py` now
closes that source-drift path across Apple's five current categories and is classified in the C6
matrix. PR #89 review found missing Foundation Swift overlay spellings; the remediation adds those
aliases and keeps UserDefaults `CA92.1` enforcement active in future multi-category manifests.
Independent rereview accepted exact remediation head `6ffc6fa`, hosted run `33287620965` passed,
and PR #89 merged it as `72f016e`. The continuation partially exercises the manual checklist:
bilingual live StoreKit/renewal/legal presentation, offline retention of verified local Pro,
privacy/receipt/iCloud/export copy, and receipt cancellation without persistence passed. A physical
AX5 navigation obstruction is remediated under DEC-COM-078/079. PR #90 review found the first
simulator check used an ignored noncanonical content-size value and lacked a content-side
guarantee; the corrected regression compares canonical AX1/AX5 page content while separately
bounding persistent chrome and using bounded interaction waits. Focused and full local validation
pass. Independent review accepted exact PR #91 head `b3ed24d` with no P1/P2 findings, hosted run
`33362101536` passed, and PR #91 merged the bounded remediation as `4ddabcd` under DEC-COM-082.
Physical reinstall/appearance is therefore closed only at that reviewed boundary. DEC-COM-083
now dispositions the remaining five rows without calling unperformed physical checks passed.
Distribution privacy-report inspection remains C6-03 evidence.

## Exit and stop conditions

C6-01 is Done through PR #86 (`015d00e`) after independent rereview approved exact remediation
head `f77d2a6` and hosted run `33255898196` passed. C6-02 is Done after explicit owner entry on
2026-08-30 and the reviewed closeout below. PR #88 merged the reviewed privacy correction and
development-signed Release inspection as `6c2a051`; PR #89 merged the independently rereviewed
required-reason source-gate remediation as `72f016e` after hosted run `33287620965` passed. PR #91
exact head `b3ed24d` passed
independent review and hosted run `33362101536`, then merged the bounded AX5/navigation increment as
`4ddabcd`. Independent final review approved the bounded acceptance packet on exact PR #93 head
`016dd33` with no P1/P2 findings, hosted run `33405016652` passed, and PR #93 merged as
`c940e8e`. The owner then entered C6-03 on 2026-09-01 under the bounded authority above. Exact
preparation head `11ab612` passed hosted run `33488815168` and independent review before PR #95
merged it as `d5d0959`. The resulting Distribution IPA passed the closed inspector and App Store
Connect accepted delivery `1b358d3b-4544-4617-ab47-5be69addc7a8` for processing. Independent
review then approved exact PR #96 head `3ed1357`, hosted run `33508360536` passed, and PR #96
merged as `246e7c1`. DEC-COM-091 closes C6-03/COM-C6; no later phase or remote action is entered
automatically.

DEC-COM-083 replaces the ambiguous open-manual list with the closed five-row
`C6_02_ACCEPTANCE_MATRIX.json`. A fresh complete xcresult must contain all 23 exact named StoreKit,
receipt, accessibility-regression, and system-integration bindings exactly once as Passed. The
owner accepted existing C4C-05 and PR #91
physical continuity and declined redundant device reruns. The complete VoiceOver matrix,
Instruments/exact file-protection proof, and physical notification/Siri/Spotlight/Face ID/share/
Delete All side effects are explicit non-passes retained for distribution-candidate C6-03/C12,
not rewritten as successes. Read-only container metadata from only `拉沙的iPhone` showed the
SwiftData artifacts under containermanagerd protection; no financial database was exported.
`xctrace` listed that permitted phone Offline and generated no trace. C6-02 is Done without
rewriting any of those physical non-passes as successful evidence.

PR #93 runs `33370429991`, `33384223530`, `33391122019`, and `33398172181` are not green evidence. The first two
failed because hosted Xcode 26.6 rejected forced schemas `0.4.0` and `0.3.0`; the second also
retained one pseudo-long-text failure followed by a retry pass. DEC-COM-085 consumes each supported
toolchain-native result shape, pins the shared
reviewed fields and both `Test Case` identifier forms, and inspects real `Repetition` nodes so a
failed-then-passed required binding cannot be accepted. The UI failure screenshot showed the
entered digits rendered; a focused two-iteration run passes without retry after the bounded
Dashboard transition replaced the lagging active-field accessibility-value assertion. The
third run proved native parsing on hosted Xcode 26.6, then correctly failed because AX1 Save had
one failed attempt followed by a pass. DEC-COM-086 uses a bounded Save-to-Dashboard activation
handshake and counts concrete repetition attempts without their aggregate parent; one future
`Repetition:Passed` remains valid while Failed→Passed remains a non-pass. Independently reviewed
head `c05860f` then exposed a delayed navigation-container frame and a keyboard-covered Save that
still reported hittable. DEC-COM-087 replaces those assumptions with App-window back-button
geometry and a full Save frame inside the keyboard-safe interaction lane. Its corrected focused
regression passes 2/2 without test-runner retry. A fresh complete validator passes Release, the
strict Dashboard benchmark, all unit tests, all 18 UI tests with 17 passed and one expected
physical-only skip, coverage, and 23/23 C6-02 bindings without a UI retry. The repository now has
three exact C6 special checks: matrix bootstrap, full-suite coverage consumption, and bounded
C6-02 acceptance. Exact head `016dd33` passed hosted run `33405016652`
and merged as `c940e8e`. Final review retained two non-blocking C6-03/C12 harness notes: the back-
button helper still selects `buttons.element(boundBy: 0)` and proves App-window rather than
navigation-bar-container geometry, while the budget Save helper performs only bounded upward Form
drags. These notes do not weaken C6-02 evidence and do not authorize C6-03.

After COM-C6 closeout, stop and request a new decision if work would deploy Staging/Production or
CloudKit schema, assign testers, submit Beta/App Store review, publish, weaken an existing fail-
closed gate, reinterpret an owner-waived physical observation as a pass, claim G1 economics
without dated real supplier evidence, or mark an Active Requirement complete from Archive/upload
evidence alone. At C6 closeout DEC-COM-092 left G1 unentered while replacing the public-observation
prerequisite with `G1_UNIT_ECONOMICS_PACKET.md`. The owner later entered G1 on 2026-09-02;
DEC-COM-093 captures dated quotes and the first reproducible typical/P50 plus peak/P95 planning
envelope. Independent review found no P1/P2 on exact PR #98 head `9226985`; hosted run
`33570570896` passed and PR #98 merged as `6e2d242`. DEC-COM-094 closes only that first package and
preserves its historical `INSUFFICIENT_QUOTE_EVIDENCE` result. DEC-COM-095 now accepts US$4.99
one-time Pro, a user-started local-only 30-day trial with zero cloud credit, sole
`gpt-5.6-luna`, starter/consumable-card lots valid for one user-calendar year,
displayed-valid-result accounting,
>=50% conservative margin, refund-without-local-deletion, ordinary-test-user denial with isolated
capped Apple Review access, and a separately reviewable local-only release path. The 24-case Eval
protocol and exact 10-credit starter plus three usage-card tiers are frozen under DEC-COM-096.
DEC-COM-097 accepts standard retention only for the fixed synthetic Eval and records the observed
Global/Luna-only/Tier 1/billing controls while keeping production admission false. DEC-COM-098
records completed synthetic account admission and a 24/24 first-pass automated Eval result after
two explicit non-pass attempts. Independent review, StoreKit price-point/Product-ID evidence,
hosted CI/merge, and owner decision remain open under
`EVAL_PASS_PENDING_REVIEW_AND_STOREFRONT_EVIDENCE`; no product/backend mutation is authorized.
COM-C6.5 remains unentered until its 14-day no-P0/P1 gate is met no earlier than 2026-09-15 and the
owner separately enters it.
