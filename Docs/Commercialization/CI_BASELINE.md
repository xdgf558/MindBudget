# Commercialization CI Baseline

## Purpose

This file fixes the reproducible build/test baseline inherited by every COM phase. It records
evidence locations; it does not lower an existing product gate or authorize product behavior.

Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`, SHA-256
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`.
`SOURCE_PROVENANCE.md` records this as an external-input audit fingerprint. CI verifies the frozen
repository snapshot and does not claim access to the owner's external specification.

## Accepted baseline

- Baseline commit audited by COM-C0A: `6226823370d9ecaedfd89f2754e1f5705dc8d5dd`.
- Toolchain: Xcode 26.6 final (`17F113`), Swift 6.3.3, iOS SDK build `23F81a`.
- Deployment target: iOS 17.0; iPhone only.
- CI runner: `macos-26`, with an explicit Xcode 26.6-or-newer assertion.
- Required commands:

  ```bash
  Scripts/check-no-floating-point-money.sh
  Scripts/check-network-egress.sh
  Scripts/check-commercialization-docs.sh
  Scripts/check-storekit-test-catalog.sh
  Scripts/validate.sh
  ```

- `Scripts/validate.sh` continues to run the existing release-readiness gate, the isolated
  StoreKit test-catalog gate, Release build,
  build-for-testing, Swift Testing/UI tests, and coverage thresholds. The COM documentation gate
  is additive and contains no app behavior.
- The StoreKit catalog gate parses scheme XML and balanced `pbxproj` objects rather than assuming
  one-line formatting. Its Shell entry is a thin wrapper around the independently runnable and
  importable `Scripts/storekit_catalog_contract.py`; a normal Python `unittest` suite proves the
  same functions accept a test-bundle-only fixture and reject app-resource, default-scheme, and
  Archive-capable fixtures before the repository contract is checked.

## COM-C0A measured coverage

| Component | Line coverage |
|---|---:|
| Money | 91.73% |
| BudgetEngine | 95.18% |
| BudgetCycleCalculator | 95.17% |
| SpendingPatternDetector | 97.57% |
| ReminderThrottle | 96.84% |
| ReminderEngine | 91.02% |
| AdviceSafetyValidator | 96.15% |
| PrivacyRedactor | 91.91% |
| CycleSummaryService | 97.42% |
| IntentClassifier | 97.50% |
| CSVExporter | 87.60% |
| CurrencyFormatterService | 100.00% |

These numbers are a regression reference, not permission to weaken the thresholds in
`Scripts/check-coverage.sh`. Later phases must explain a material drop and add tests before
changing production behavior.

## COM-C0B verification

On 2026-08-10, Xcode 26.6 passed the additive commercialization-doc gate, the unchanged money
gate, release-readiness checks, generic Release simulator build, 270 Swift tests in 17 suites, all
13 UI tests, and the coverage gate. The result bundle was written to the documented local path
`TestResults/Commercialization/COM-C0B/local/MindBudget.xcresult`. The strict hosted wall-clock
signal was skipped through the existing documented switch; its deterministic 10,000-row contract
still passed. No product source/schema/resource or user-visible behavior changed in COM-C0B.

## COM-C2-02 verification

On 2026-08-12, Xcode 26.6 passed the complete static, Release-build, Swift Testing, UI, and
coverage pipeline for the runtime catalog and entitlement-store implementation plus its focused
review remediation. The run passed 306 selected Swift tests in 20 suites and all 13 UI tests with
zero failures; every selected core-service coverage threshold remained above 85%. The extracted
StoreKit contract suite passed all 12 Python tests. Focused runtime tests covered exact-context
presentation caching and deletion, malformed/partial catalogs, startup reconciliation, one
transaction-update listener, concurrent whole-snapshot reads, fail-closed mixed/unverified/
unknown/revoked states, stale-reconciliation suppression, preservation of a past expiration date
for C2-03's status mapper, and direct AppSession Free -> Pro -> Free UI snapshot propagation.

Two `Product.products(for:)` storefront probes are deliberately excluded from the default scheme
and are enabled only by the non-Archive `MindBudget-StoreKit-Local` scheme. Focused review ran the
dedicated Test action under the installed Xcode 26.6 RC build `17F109` and iOS 26.5. Both probes
executed, `SKTestSession` emitted `SKInternalErrorDomain Code=3` while synchronizing the local
configuration/storefront, and `Product.products(for:)` returned an empty set. A trial change that
inherited Launch arguments made the command green only by dropping the Test-action opt-in and
skipping both probes; that change was rejected, and the scheme contract now rejects this false-
green shape. Therefore CHN/USA framework-backed product loading is **not** claimed as passing
evidence in this packet. C2-03 has a hard entry gate requiring both probes to execute and pass
under a supported final Xcode toolchain, preferably the Xcode GUI while the iOS 26.5 CLI failure
remains reproducible. Default validation reports the probes as skipped rather than manufacturing
a pass.

Post-merge probe revalidation used final Xcode 26.6 build `17F113`. Both CHN and USA probes
executed on final iOS 26.4 and 26.5 runtimes, but `Product.products(for:)` again returned empty
sets with `SKInternalErrorDomain Code=3`; contemporaneous `storekitd` diagnostics reported an
Octane entitlement/development-install handshake failure. The installed iOS 26.5 runtime is build
`23F77`, while final Xcode's SDK is build `23F81a`. Apple currently offered only an export of the
older runtime build `23F73`; it was not imported and could not provide an alternate supported-
runtime execution surface. Direct download queries for build `23F81` and iOS `26.5.1` both
returned unavailable. The identical dedicated scheme passes all 16 tests
in 2 suites on an iOS 27 beta runtime. That beta result is useful diagnostic evidence that the
fixture and test code can execute, but it is not accepted evidence for the supported-final-runtime
entry gate. The historical RC failure above remains part of the record; no final-runtime pass is
claimed.

After the machine-wide `xcode-select` was switched to final Xcode `17F113` and the Mac restarted,
the dedicated iOS 26.5 `23F77` run executed 5 catalog tests: 3 passed, while the CHN and USA probes
both executed without skipping and failed with the same `Code=3`/empty-product result. The earlier
auxiliary `xcrun`/`simctl` lookup error disappeared, proving the global toolchain is now coherent
but was not the StoreKit failure's root cause. Evidence is retained at
`/private/tmp/MindBudget-C2-02-Restart-17F113-iOS26.5-23F77.xcresult` and
`/private/tmp/mindbudget-storekit-restart-17F113-ios265-23F77.log` for this local session.

No purchase, restore, transaction finishing, customer term, paywall, schema, app-owned network
destination, Archive, upload, tester, or distribution state was introduced or changed. PR #29
passed independent review and green CI, then merged as `a45d480` on 2026-08-12; C2-02 is Done.
C2-03 was still blocked at the conclusion of C2-02; the separate physical-device evidence below
subsequently satisfied that entry gate.

## COM-C2-03 entry-gate verification

On 2026-08-13, final Xcode 26.6 build `17F113` ran the dedicated non-Archive
`MindBudget-StoreKit-Local` scheme on the physical `拉沙的iPhone` (`iPhone Air`) with final
iOS 26.6.1 build `23G82`. All 5 catalog tests passed with 0 failed and 0 skipped. Both the CHN and
USA `Product.products(for:)` runtime probes executed and passed; neither returned an empty product
set or `SKInternalErrorDomain Code=3`. Independent `xcresulttool` parsing confirmed the physical
arm64 device, OS/build, each named test, and the 5/0/0 totals. Evidence:
`/private/tmp/MindBudget-C2-03-Physical-Unlocked-iOS26.6.1-17F113.xcresult`.

This supported-final physical-device pass opens C2-03 implementation. It introduces no C2-03
source, purchase, restore, transaction finish, subscription-status decision, paywall, formal
product/term, version, Archive, upload, tester, or distribution change. The post-0.9.6 release
hold remains active.

## COM-C2-03 implementation candidate verification

The merged C2-03 implementation adds a
single `EntitlementStore` lifecycle authority, full verified status/renewal mapping, explicit
typed purchase and restore seams, authoritative whole-snapshot publication before transaction
finish, and retry for transactions that remain unfinished. One lifecycle task supervises both
`Transaction.updates` and `Product.SubscriptionInfo.Status.updates`; a status signal triggers a
fresh full reconciliation through the same authority without creating a second authority or UI.
Deterministic focused tests cover the
state table, pending/cancel/error outcomes, restore outcomes, duplicate/concurrent delivery,
operation serialization, finish ordering/failure, and unfinished startup processing. Opt-in local
StoreKit probes cover Monthly/Annual seeded transaction verification, authority publication, and
finish. Presented `Product.purchase()` remains a C3 UI-host obligation. A forced-renewal grace
experiment terminated the hosted runner before completion and was removed; deterministic state
tests cover the mapper without claiming a framework transition pass.

Local C2-03 validation is complete. The focused lifecycle/runtime run passed 44/44 tests, and the
31-test lifecycle suite passed 10 consecutive iterations (310/310). The strict 500 ms local
Dashboard wall-clock signal also passed 10/10 isolated iterations. The owning full run used the
repository's documented shared-host switch to exclude only that already-isolated wall-clock
signal while retaining the deterministic 10,000-row projection contract. It completed 342 Swift
tests with zero failures (338 passed and 4 explicit opt-in StoreKit runtime probes skipped), all
13 UI tests, and the full coverage gate. The combined result summary is 355 total, 351 passed,
4 skipped, and 0 failed. Evidence:
`/private/tmp/MindBudget-C203-Full-Final15.xcresult`.

Selected line coverage was Money 91.73%, BudgetEngine 95.18%, BudgetCycleCalculator 95.17%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 91.04%,
AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService 97.45%,
IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100.00%; every selected
file remains above the 85% gate. The four skipped probes remain opt-in dedicated-scheme/device
evidence and are not reclassified by this default-scheme run. PR #30 subsequently passed
independent review and the complete GitHub Actions validation in 14m26s, then merged to `main` as
`3fc72b4` on 2026-08-13. CI run:
<https://github.com/xdgf558/MindBudget/actions/runs/31675470258>. C2-03 is Done; C2-04 is now
implementation complete pending independent review.
Paywall/customer purchase presentation, formal products/customer terms, versioning, Archive,
upload, tester assignment, and distribution remain blocked. The post-0.9.6 release hold is active.

## COM-C2-04 implementation verification

C2-04 binds each whole entitlement read to a separately verified `AppTransaction` bundle and
environment. Xcode, Sandbox (including TestFlight), and Production transactions are accepted only
when the app environment and every verified transaction/status fact match exactly; missing,
unknown, cross-environment, or wrong-bundle input fails closed. Presentation caching continues to
require an exact environment plus storefront key, and catalog-only failure may not erase an
independently verified active subscription.

Focused evidence: `StoreRuntimeTests` plus `StoreLifecycleDomainTests` passed 48/48 on the iOS
26.5 simulator with final Xcode 26.6 `17F113`. The strict Phase 10 suite then passed 20/20 across
10 isolated iterations, including 10/10 executions of the 500 ms local Dashboard signal. The
owning shared-host run used the repository's documented switch to omit only that already-isolated
wall-clock assertion while retaining its deterministic 10,000-row projection test. It completed
345 Swift tests with zero failures (341 passed and 4 explicit StoreKit runtime probes skipped) and
all 13 UI tests. The combined result is 358 total, 354 passed, 4 skipped, and 0 failed. Every
selected coverage file passed the 85% gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.04%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%,
CycleSummaryService 97.45%, IntentClassifier 97.50%, CSVExporter 87.60%, and
CurrencyFormatterService 100.00%. Static release, money, network, commercialization-document,
feature-access, StoreKit-catalog, and diff gates pass. Evidence:
`/private/tmp/MindBudget-C204-WallClockSuite-10x.xcresult` and
`/private/tmp/MindBudget-C204-Full-Shared.xcresult`.

An initial unsplit full run also completed all functional/UI tests but measured the shared-host
wall-clock signal at 0.814 seconds and Xcode then spent 600 seconds timing out while collecting
simulator diagnostics. It is not used as passing evidence; the isolated 10-iteration run and the
clean shared-host run above are the owning evidence. Independent review, CI, and merge remain
pending; C2-04 is not Done and C3 remains blocked.

## Result and report paths

`Scripts/validate.sh` accepts an optional `MINDBUDGET_RESULT_BUNDLE_PATH`. The path must not
already exist. Without it, the script uses and removes an isolated temporary directory as before.

- Recommended local path:
  `TestResults/Commercialization/<phase>/<build>/MindBudget.xcresult`.
- CI working path: `${RUNNER_TEMP}/MindBudget.xcresult`.
- Downloadable CI artifact:
  `MindBudget-xcresult-<run-id>-<run-attempt>`, retained for 14 days and uploaded even when the
  validation step fails after producing a result bundle. If validation stops before testing,
  absence of an xcresult is reported without hiding the original failure.
- Signed-device/manual evidence:
  `TestResults/Commercialization/<phase>/<build>/README.md` plus only redacted screenshots/logs.
- StoreKit evidence: `TestResults/Commercialization/StoreKit/<build>/`.
- Cloud/Watch evidence later uses its named phase directory and must never contain credentials,
  receipt images/OCR, notes, ledger rows, prompts/responses, or stable user identifiers.

Example:

```bash
MINDBUDGET_RESULT_BUNDLE_PATH="$PWD/TestResults/Commercialization/COM-C1/local/MindBudget.xcresult" \
  Scripts/validate.sh
```

`TestResults/` is evidence workspace, not an automatic commit target. Review and redact every
artifact before deliberately adding it to version control.

## Failure and change rules

- A failed money, StoreKit-catalog isolation, documentation, release-readiness, build, test, UI,
  or coverage gate blocks the
  phase. Hosted wall-clock noise may skip only the already documented 500 ms signal; the
  deterministic 10,000-row contract still runs.
- A new app-owned network channel, persisted model, Product ID, entitlement, premium feature,
  privacy statement, or SDK capability must extend its owning matrix and tests in the same PR.
- CI/action upgrades remain commit-SHA pinned. A report path or test retry never converts a failed
  assertion into success.
