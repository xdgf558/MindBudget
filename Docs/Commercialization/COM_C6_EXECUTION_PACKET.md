# COM-C6 Execution Packet

Status: **In Progress after reviewed C6-01 merge.**

C6-01 is Done after independent rereview approved exact remediation head `f77d2a6`, hosted run
`33255898196` passed, and PR #86 merged as `015d00e`. C6-02 awaits a separate explicit owner
entry; C6-03 remains blocked.

Owner entry: the project owner explicitly entered COM-C6 on 2026-08-29 after PR #85 merged the
COM-C5 closeout as `008b674`.

## Scope and sequence

COM-C6 prepares one reviewed TestFlight baseline without authorizing public release. Work remains
strictly sequential:

1. **C6-01 — Automated release matrix.** Freeze and run the repository-controlled automated
   evidence rows described below.
2. **C6-02 — Signed-device and App Review preflight.** Begin only after C6-01 is independently
   reviewed, green in hosted CI, merged, and the owner explicitly enters C6-02.
3. **C6-03 — TestFlight baseline.** Begin only after C6-02 is accepted. Archive and upload require
   a separate owner instruction at that time.

C6-01 performs no archive, upload, Staging or Production deployment, App Store Connect write,
tester assignment, schema deployment, customer-data collection, G1 decision, or release action.

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
serially into one xcresult. It then reads that exact bundle through `xcresulttool` schema 0.4.0 and
requires every one of the 33 row/method bindings to appear exactly once as a Test Case with result
`Passed`; a missing, disabled/skipped, duplicated, wrong-type, commented-out, or non-test method is
non-evidence and fails the matrix. Parameterized Swift Testing methods bind by their exact test type
and method basename while their argument rows remain subordinate evidence. Worker `check` scripts
may typecheck, test, profile, and perform local dry-runs; they may not deploy.

Repository check discovery is also closed. Every `Scripts/**/check-*.sh` or
`Scripts/**/check_*.py` file must be either one of the twelve row-driven matrix checks or one of two
exact special classifications: `check-c6-release-matrix.sh` is the matrix bootstrap and
`check-coverage.sh` consumes the full-suite xcresult produced by `Scripts/validate.sh`. A newly
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
signed-device purchase/restore/manage testing, final-binary and IPA egress inspection, release
entitlements, privacy/data-protection/localization/accessibility evidence, and every accepted
manual release-checklist item.

## Exit and stop conditions

C6-01 is Done through PR #86 (`015d00e`) after independent rereview approved exact remediation
head `f77d2a6` and hosted run `33255898196` passed. C6-02 remains blocked pending a separate
explicit owner entry; C6-03 remains blocked by C6-02 acceptance and a separate owner instruction
for archive/upload.

Stop and request a new decision if the automated matrix would need to deploy, upload, archive,
write App Store Connect, weaken an existing fail-closed gate, reinterpret an owner-waived physical
observation as a pass, claim a real G1 sample, or mark an Active Requirement complete from local
automation alone.
