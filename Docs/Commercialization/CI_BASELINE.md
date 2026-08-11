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
- Toolchain: Xcode 26.6 (`17F109`), Swift 6.3.3, iOS 26.5 SDK.
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
  one-line formatting. Before inspecting the repository, it proves the same parser accepts a
  test-bundle-only fixture and rejects app-resource, default-scheme, and Archive-capable fixtures.

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
