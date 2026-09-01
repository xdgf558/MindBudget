# C6-03 TestFlight Baseline

Status: **In Progress under DEC-COM-089 after explicit owner entry and bounded Archive/upload authority on
2026-09-01.**

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
- [ ] Independent review approves the exact head, hosted CI passes on that head, and the reviewed
  candidate merges to `main` before Archive.

## Distribution gates after reviewed merge

- [ ] Archive plain `MindBudget` Release from the exact merged `main` commit using the owner-selected
  team `2AM5S7BM2N` and bundle ID `com.xdgf558.MindBudget`.
- [ ] Run `Scripts/inspect-c6-release-app.sh --mode distribution` against the archived app and require
  Production APS, Production private-CloudKit environment, and `get-task-allow = false`.
- [ ] Confirm the archive embeds the reviewed `PrivacyInfo.xcprivacy`, contains no StoreKit fixture
  or test bundle, and contains no unreviewed app/extension/framework privacy manifest or dependency.
- [ ] Confirm Release environment selection can reach only the reviewed Production configuration
  and telemetry contexts. Development and Staging literals may remain inert enum-case strings, but
  there must be no Release selection path to them.
- [ ] Export/upload with `manageAppVersionAndBuildNumber: false`; require transport acceptance for
  `0.9.9 (10)` and record the delivery UUID, timestamp, signing identity, and merged source commit.
- [ ] Record that tester assignment, external review, Production deployment/schema, G1, distribution,
  and public release were not performed.

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
