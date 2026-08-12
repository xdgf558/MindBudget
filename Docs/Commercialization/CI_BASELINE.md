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
C2-03 remains blocked pending the separate runtime-probe entry gate described above.

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
