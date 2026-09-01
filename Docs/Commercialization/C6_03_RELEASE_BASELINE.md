# C6-03 TestFlight Baseline

Status: **Implementation and bounded transport complete under DEC-COM-090; documentation closeout
pending independent review, hosted CI, and merge.**

## Authorized outcome

Prepare `MindBudget` / `花有数` version `0.9.9`, build `10`, as one traceable TestFlight
baseline. Archive and upload may occur only after the exact preparation head receives independent
review, passes hosted CI, and merges to `main`. Stop after App Store Connect transport accepts the
build. Do not assign internal testers, submit external Beta App Review, submit an App Store version,
deploy Staging/Production services or CloudKit schema, decide G1, or authorize public release.

## Preparation gates before merge

- [x] Build 10 is committed in both app configurations with marketing version `0.9.9`;
  `1.0.0` remains reserved for public launch.
- [x] `Docs/CHANGELOG.md` and `Docs/APP_STORE_SUBMISSION.md` contain the same build-10 scope and
  truthful known boundaries.
- [x] The signed-app inspector expects exactly build 10 and retains the closed bundle, team,
  entitlement, privacy-manifest, host-literal, device-family, minimum-OS, and no-test-fixture checks.
- [x] Every repository static gate, full validator, and C6 release matrix passes on the preparation
  head with no hidden test retry accepted as evidence.
- [x] Independent review approved exact preparation head `11ab612`, GitHub Actions run
  `33488815168` passed on that head, and PR #95 merged it to `main` as `d5d0959` before Archive.

## Distribution gates after reviewed merge

- [x] Archive plain `MindBudget` Release from exact merged `main` commit `d5d0959` using the owner-selected
  team `2AM5S7BM2N` and bundle ID `com.xdgf558.MindBudget`.
- [x] Run `Scripts/inspect-c6-release-app.sh --mode distribution` against the exported app and require
  Production APS, Production private-CloudKit environment, and `get-task-allow = false`.
- [x] Confirm the exported app embeds the reviewed `PrivacyInfo.xcprivacy`, contains no StoreKit fixture
  or test bundle, and contains no unreviewed app/extension/framework privacy manifest or dependency.
- [x] Confirm Release environment selection can reach only the reviewed Production configuration
  and telemetry contexts. Development and Staging literals may remain inert enum-case strings, but
  there must be no Release selection path to them.
- [x] Export/upload with `manageAppVersionAndBuildNumber: false`; App Store Connect accepted
  `0.9.9 (10)` and record the delivery UUID, timestamp, signing identity, and merged source commit.
- [x] Record that tester assignment, external review, Production deployment/schema, G1, distribution,
  and public release were not performed.

## Exact distribution and transport evidence

- Archive: `/private/tmp/MindBudget-C6-03-0.9.9-zv9Qeg/MindBudget.xcarchive`, produced from
  `d5d0959` with Xcode 27.0 beta 6 (`27A5252f`). The archive's development signature is not used as
  distribution evidence.
- The first App Store Connect export is an explicit non-pass: Xcode had no usable current account,
  distribution certificate, or entitlement-compatible Store provisioning profile. No package was
  accepted from that attempt.
- After the owner restored the current Xcode account, automatic App Store Connect export produced
  `/private/tmp/MindBudget-C6-03-0.9.9-zv9Qeg/Exported/MindBudget.ipa`. The extracted app passed the
  distribution inspector as version `0.9.9`, build `10`, bundle `com.xdgf558.MindBudget`, team
  `2AM5S7BM2N`, arm64, iPhone-only, and `get-task-allow = false`.
- Distribution signing used the cloud-managed Apple Distribution certificate with SHA-1
  `772445FF75853BB4E4D8145E13D5AE0730F97D72` and Store profile UUID
  `b2a9f8d1-2e48-41bf-84fd-48a9922ce82b`; both expire 2027-08-08. The app carries Production APS,
  Production CloudKit, `iCloud.com.xdgf558.MindBudget`, `beta-reports-active = true`, the sole
  reviewed app privacy manifest, no StoreKit fixture/test bundle, and no embedded app extension,
  framework, or test target.
- The owner explicitly authorized upload. At `2026-09-01 19:27:25 +0800`, App Store Connect
  accepted the package for processing with delivery UUID
  `1b358d3b-4544-4617-ab47-5be69addc7a8`. This is transport acceptance only.

## Accepted non-passes carried forward

- The owner-waived physical same-account two-device, background-push, account-switch, offline, and
  quota iCloud observations remain non-passes, not successes.
- Complete physical VoiceOver, Instruments/exact data-protection, and notification/Siri/Spotlight/
  Face ID/share/Delete All side-effect matrices remain C12 responsibilities and are not inferred
  from deterministic tests or a successful upload.
- The C6-02 back-button helper still selects `buttons.element(boundBy: 0)` and proves App-window
  geometry only; its budget Save helper performs bounded upward Form drags only.
- Development telemetry evidence is synthetic and does not establish customer participation, G1,
  final-binary production traffic, or App Store Connect privacy-answer completion.

## Failure boundary

Any P0/P1, signing mismatch, manifest/dependency drift, failed static/test gate, red hosted CI,
failed independent review, archive-inspector failure, or transport rejection stops the upload.
Nothing in C6-03 may be reclassified as public-release approval.
