# C6-02 Signed-Device and App Review Preflight

Status: **In Progress after explicit owner entry on 2026-08-30.** Independent review accepted
exact PR #88 head `0ac0500`, hosted run `33283398690` passed, and PR #88 merged as `6c2a051`.
That review left one non-blocking required-reason API source-inventory hardening item before C6-02
Done. PR #89 review accepted the lexer and wiring but found missing Foundation Swift overlay
symbols. Independent rereview accepted exact remediation head `6ffc6fa`, hosted run `33287620965`
passed, and PR #89 merged it as `72f016e`, closing that source-gate item.
Customer-facing StoreKit, accessibility, localization, data-protection, and distribution-signed
checks are now partially exercised below. C6-02 remains In Progress for the explicitly open manual
items. Independent review accepted exact PR #91 head `b3ed24d` with no P1/P2 findings, hosted run
`33362101536` passed, and PR #91 merged the bounded AX5/navigation increment as `4ddabcd` under
DEC-COM-082. C6-03, archive, upload, deployment, App Store Connect writes, tester assignment, G1,
distribution, and release remain unauthorized.

## Authorization and evidence boundary

The owner explicitly entered C6-02 on 2026-08-30. This packet may inspect source, build a Release
configuration for a connected development device, install and launch that build, and prepare draft
App Review/App Privacy answers. It may not archive, export, upload, deploy a Worker or CloudKit
schema, modify App Store Connect, assign testers, or make a release decision.

The app path under `/private/tmp` is an execution pointer, not a durable artifact. A build installed
directly by Xcode is signed with a development provisioning profile even when its build
configuration is Release. It therefore proves device compatibility and the inspected embedded
content, but it is not an App Store distribution signature, exported IPA, final-binary network
proof, or TestFlight baseline.

## Mandatory five-surface privacy inspection

The C5 implementation-author supplemental inspection did not satisfy this gate. C6-02 re-read all
five mandatory surfaces against Apple's current App Privacy definitions and the closed telemetry
vocabulary. Independent review accepted this pass through PR #88 (`6c2a051`).

| Surface | C6-02 result |
|---|---|
| `MindBudget/Resources/PrivacyInfo.xcprivacy` | Found one under-declaration: `subscription_action` carries an explicit purchase outcome, so Apple's Purchase History definition applies even though no product, price, transaction, storefront, or date is sent. Added Purchase History alongside Product Interaction and Device ID. All three remain Analytics-only, not linked, and not used for tracking. Tracking remains false, tracking domains remain empty, and UserDefaults `CA92.1` is the sole required-reason declaration. |
| `MindBudget/Features/AddExpense/AddExpenseView.swift` | Emits only the closed `receipt_flow` action/outcome milestones `opened`, `acquired`, `reviewed`, and `saved`. It cannot encode the image, OCR, merchant, date, amount, currency, category, note, or model evidence. |
| `MindBudget/Features/Commerce/ProSubscriptionView.swift` | Emits only `pro_surface` `presented` and `dismissed`. It cannot encode a product, price, trial state, transaction, entitlement, or legal-page content. Purchase/restore outcomes are recorded separately through the closed AppRouter event. |
| `TelemetryService` in `MindBudget/Services/TelemetryClient.swift` | Collection remains explicit opt-in and missing-state off. The service owns a bounded encrypted local queue, fixed first-party transport, fail-closed unavailable/terminal states, opt-out, retained proof-authenticated deletion, and retry. Optional telemetry state never grants entitlement or changes financial facts. |
| `Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md` | Still describes Development-only operational evidence. Staging remains unmigrated/undeployed and Production unprovisioned/undeployed. Synthetic probes are not customer, final-binary, App Store Connect, G1, distribution, or release evidence. |

`Scripts/privacy_manifest_contract.py` now enforces the exact checked-in and embedded manifest. Its
negative self-tests reject missing Purchase History, linked data, tracking, a tracking domain, a
non-Analytics purpose, the wrong required-reason API, and any extra collected-data type.

## Required-reason API source inventory

PR #88 review correctly observed that the first validator pinned UserDefaults `CA92.1` but did not
derive the set of accessed API categories from App-target source. Apple's current list was checked
again on 2026-08-30 and contains File Timestamp, System Boot Time, Disk Space, Active Keyboards,
and UserDefaults.

`Scripts/check_required_reason_apis.py` now scans production Swift, Objective-C, Objective-C++, C,
C++, and header files under `MindBudget/`. It removes nested comments and ordinary, multiline, and
raw string literal content while retaining real Swift interpolation code. The observed source
category set must exactly equal `NSPrivacyAccessedAPITypes`; an undeclared source category and an
unobserved manifest category both fail. The current source inventory finds only `UserDefaults` and
SwiftUI `@AppStorage`, matching the sole App-only `CA92.1` declaration.

The self-test rejects every currently unobserved Apple category, C `stat`, an extra manifest
category, the wrong UserDefaults reason, a real API hidden in string interpolation or after a raw
string ending in a backslash, and ambiguous `getattrlist*` file-metadata access. Comments and
literal strings containing API names do not satisfy or trip the contract. The check is classified
in `C6_RELEASE_MATRIX.json` and also runs through the ordinary telemetry/privacy gate.

PR #89 review reproduced missing Swift overlay coverage. The remediation explicitly maps
`fileCreationDate` and `contentModificationDate` to File Timestamp; maps the four
`URLResourceValues` capacity properties (`volumeAvailableCapacity`,
`volumeAvailableCapacityForImportantUsage`, `volumeAvailableCapacityForOpportunisticUsage`, and
`volumeTotalCapacity`) plus `fileSystemFreeSize` and `fileSystemSize` to Disk Space; and tests every
overlay independently. UserDefaults reason `CA92.1` is now checked whenever that category is
declared, including a future multi-category manifest.

This is a source-level drift control, not final-binary or dependency proof. C6-03 must still inspect
the distribution candidate's Xcode privacy report and rerun the signed-app/IPA checks before any
App Store Connect answer or upload. Literal strings are intentionally excluded, so dynamically
constructed raw-value keys such as `URLResourceKey(rawValue: "NSURLCreationDateKey")` are outside
this lexical proof and remain part of the distribution privacy-report and compiled-dependency
inspection boundary.

## Draft App Privacy mapping — do not submit from this packet

| Apple data type | Why it is declared | Purpose | Linked | Tracking |
|---|---|---|---|---|
| Product Interaction | Closed app/session, Pro-surface, receipt-flow, cloud-control, and subscription action/outcome events | Analytics | No | No |
| Device ID | Rotating random app-scoped telemetry pseudonym, conservatively classified | Analytics | No | No |
| Purchase History | Closed `subscription_action` purchase/restore/manage outcome | Analytics | No | No |

No amount, merchant, note, receipt image/OCR, category, currency, product ID, price, storefront,
transaction/JWS, subscription date, iCloud account, advertising identifier, locale, device model,
or arbitrary string is part of the telemetry schema. This table is a source-review draft only.
App Store Connect must be completed from the independently reviewed distribution candidate and
actual final-binary traffic evidence.

Authoritative Apple references checked on 2026-08-30:

- App Privacy details: <https://developer.apple.com/app-store/app-privacy-details/>
- App Review Guidelines: <https://developer.apple.com/app-store/review/guidelines/>
- Required-reason API declarations: <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>
- Privacy manifests: <https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk>
- Restoring purchases: <https://developer.apple.com/documentation/storekit/restoring-purchased-products>

## Signed-device Release preflight — 2026-08-30

Environment:

- Xcode 27.0 beta 6 (`27A5252f`)
- `拉沙的iPhone`, iPhone Air (`iPhone18,4`), iOS 26.6.1 (`23G83`)
- physical, paired, Developer Mode enabled
- Release configuration, version 0.9.8 (9), iPhone-only, iOS 17.0 minimum

Completed evidence:

- [x] Built Release for the physical-device destination with automatic provisioning.
- [x] Verified the app signature on disk and its designated requirement.
- [x] Verified bundle ID `com.xdgf558.MindBudget`, team/application identifiers, version/build,
  iPhone-only family, iOS 17.0 minimum, and only `remote-notification` background mode.
- [x] Verified the exact private CloudKit container/service and Production CloudKit environment.
- [x] Verified the exact embedded privacy manifest through the same closed validator used for
  source.
- [x] Verified the executable contains exactly the six reviewed public-configuration/telemetry
  Development, Staging, and Production host literals, and no unreviewed `workers.dev` literal.
  Literal presence is not reachability or deployment evidence.
- [x] Verified no `.storekit` fixture or `.xctest` bundle is embedded.
- [x] Installed and launched the app successfully on the named iPhone.

Physical observations from the same installed candidate:

- [x] Inspected Chinese and English Pro surfaces against live StoreKit presentation. Monthly was
  `$1.99`, annual was `$19.99`, the active seven-day trial disclosed renewal on 2026-09-02 at the
  current `$1.99` App Store price, and the already-entitled state disabled a duplicate purchase.
  Restore Purchases, Manage Subscription, Subscription Terms, and Subscription Privacy were
  visible in both languages. This did not execute a new purchase, cancellation, restore, paid
  introductory offer, or unavailable-authority transaction path.
- [x] Enabled airplane mode and cold-launched the app. The previously verified local Pro snapshot,
  active trial, renewal date, and `$1.99` disclosure remained visible rather than becoming exact
  Free. The screenshot copied to
  `/private/tmp/MindBudget-C6-02-physical-20260830/offline-pro-zh.png` has SHA-256
  `a039b956ce736725b89c2bd84d3d84368d28d3546bb5623542b08610e8201420`; the path is an
  execution pointer, not a durable repository artifact or final-binary traffic proof.
- [x] Inspected English Privacy & Security and Product Analytics copy. It states that financial
  records stay on device, analytics is explicit opt-in/default-off, and amounts, merchants,
  categories, notes, receipt images/text, StoreKit/CloudKit identifiers, locale, device IDs, and
  advertising IDs are excluded. Delete All and retained remote-proof retry copy were visible.
- [x] Inspected the Chinese receipt entry, local-only disclosure, camera/photo choices, CSV local-
  file disclosure, iCloud default-off disclosure, and both-language Pro surfaces without a raw key
  or stale product term. Cancelling receipt review and then cancelling Add Expense left Today's
  spending at `$0.00` and the existing `$25.00` recent expense unchanged, confirming no ledger
  persistence without explicit Save. Camera/photo acquisition itself was not rerun because iPhone
  Mirroring cannot use the camera and opening the picker would expose unrelated private photos.
- [x] Physical AX5/Increase Contrast/Reduce Motion inspection found a real non-pass: the uncapped
  persistent four-tab bar obscured Dashboard and pushed Pro content. DEC-COM-078 caps only that
  navigation chrome at Accessibility 1 while page content remains uncapped. PR #90 review found
  that the first simulator check asserted only chrome height and that its noncanonical content-size
  launch value was ignored by UIKit. DEC-COM-079 therefore replaces that evidence with canonical
  AX1/AX5 raw values, an AX1-versus-AX5 Dashboard-content height comparison, and the existing
  chrome reachability/height bound. Earlier simulator bundles remain ordinary UI execution
  pointers, not AX5 evidence. The remediated build was subsequently installed only on
  `拉沙的iPhone`. A physical true-AX5 content run and four English/Simplified Chinese light/dark
  Pro captures passed. A separate exact physical regression then exposed a first-legal-push
  system-back-indicator contrast defect despite a green hierarchy result. DEC-COM-081 binds the
  navigation-bar scheme at the Pro presentation boundary. Its final three-skin physical run passed
  1/1, and manual inspection of all nine Pro/Terms/Privacy screenshots confirmed the back indicator
  remained visible. This closes only the named reinstall/appearance item; the full physical
  accessibility line remains open.

Provisioning limitation:

- Direct device installation used a development provisioning profile, so the signed app has
  `aps-environment = development` and `get-task-allow = true`. This is expected for this mode and
  is not accepted as distribution evidence.
- `Scripts/inspect-c6-release-app.sh --mode signed-device` requires that exact development-signed
  shape. Its separate `--mode distribution` requires `aps-environment = production` and
  `get-task-allow = false`; C6-03 must run that mode on the authorized archive/export before any
  upload.

Automated remediation evidence:

- The first complete `Scripts/validate.sh` run after the navigation change passed Release, the
  strict serial 10,000-row Dashboard benchmark, and all 553 unit tests, but retained three UI
  non-passes. A rerun alone did not establish a transient mechanism. PR #90 review required the
  language, onboarding/tab/category, and Pro appearance transitions to use bounded predicate
  waits rather than immediate post-interaction reads.
- Author-side review then found that all four old tests used the noncanonical string
  `UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge`, which UIKit ignored. The supported
  raw values are `UICTContentSizeCategoryAccessibilityM` for AX1 and
  `UICTContentSizeCategoryAccessibilityXXXL` for AX5. The earlier simulator bundles therefore do
  not prove AX5, even though the physical AX5 obstruction remains a valid non-pass.
- The corrected focused AX1/AX5 content regression passed one test with zero failures at
  `/private/tmp/C6-02-ReviewFix-TrueAX5-setup-rerun.xcresult`. It proves the dynamic Dashboard date
  content is taller at AX5 than AX1 while every persistent tab remains present, hittable, and at
  or below the reviewed chrome bound. The corrected three-appearance Pro AX5 regression passed
  one test with zero failures at `/private/tmp/C6-02-ReviewFix-TrueAX5-Pro.xcresult`.
- Hosted Actions run `33312286576` on remediation head `6908f6c` was a real non-pass: the
  three-appearance Pro regression could expose `settings.pro` as hittable while that row's center
  remained behind the Settings navigation bar after returning from Appearance. Two synthesized
  taps therefore did not navigate, and the old test then emitted cascading missing-control
  failures. This is not classified as transient or environmental.
- The regression now scrolls until the Pro row's center is below the live navigation-bar frame,
  asserts that geometry, then uses a bounded tap-to-destination handshake and stops on failure so
  downstream checks cannot obscure the first cause. The pre-fix two-iteration diagnostic passed
  1/2 at `/private/tmp/C6-02-ReviewFix-TrueAX5-Pro-NavigationHandshake-TwoIterations.xcresult`;
  the safe-hit-point version passed 2/2 at
  `/private/tmp/C6-02-ReviewFix-TrueAX5-Pro-SafeHitPoint-TwoIterations.xcresult`.
- The new owning complete validation under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5
  (`23F77`) iPhone 17 Pro simulator passed Release, the strict benchmark, 553 tests in 32 unit
  suites, all 17 UI tests with the canonical AX5 values, and every selected coverage threshold.
  Four accepted opt-in physical CloudKit probes remained skipped; `CSVExporter.swift` was lowest
  at 87.60% against the 85% floor. The validator removed its temporary xcresult, so that path was
  an execution pointer rather than a durable artifact.
- The exact-source C6 matrix rerun passed every static and Worker check, Release/test build, 285
  tests in 16 suites, and all 33 required method bindings exactly once as Passed. A first sandboxed
  attempt could not write Wrangler logs or bind its local test server and is an environmental
  non-pass; the unrestricted rerun is the owning result. Its temporary result bundle was removed.

## Manual signed-device evidence still open

- [ ] Execute or deterministically re-evidence purchase cancellation, actual restore, unsupported
  paid introductory offer, unavailable StoreKit authority, and retry states. Live monthly/annual,
  renewal/legal, already-entitled, and Manage Subscription presentation passed as recorded above.
- [x] Reinstall the DEC-COM-078/079 remediation and repeat physical AX5 plus English/Simplified
  Chinese light/dark appearance on `拉沙的iPhone` only. True-AX5 content and all four bilingual
  light/dark Pro captures passed. DEC-COM-081 additionally closes the screenshot-only first-push
  back-indicator defect with a 1/1 three-skin run and nine manually inspected Pro/Terms/Privacy
  captures. Pre-fix, certificate-trust, and owner-stopped duplicate bundles remain explicit
  non-passes and are not used as evidence. Independent review accepted exact PR #91 head
  `b3ed24d`, hosted run `33362101536` passed, and PR #91 merged this item as `4ddabcd`; automated
  geometry remains non-contrast evidence, so the manual screenshot review stays the visual proof.
- [ ] VoiceOver, AX5, Increase Contrast, Reduce Motion, light/dark appearance, focus order, touch
  targets, sheets, alerts, keyboard, and supported portrait orientations pass on the signed phone.
- [x] Revalidate the DEC-COM-081 simulator regression without retries after the physical item: the
  focused AX1/AX5 content/chrome test passed 2/2, the complete validator recorded 558 passed, 13
  intentionally skipped, and zero failed tests, and the exact-source C6 matrix passed 285 tests
  plus all 33 required bindings. This is local regression evidence, not a substitute for the still-
  open full signed-phone accessibility row above.
- [ ] Camera and photo-picker receipt paths remain local, preview/retry/cancel correctly, preserve
  edits, and require explicit Save before ledger persistence. The local-only entry and cancellation
  no-write boundary passed, but acquisition was not rerun in this continuation.
- [ ] Instruments confirms launch/scroll/memory/persistence behavior; effective SwiftData file
  protection is inspected in the installed container.
- [ ] Notification, Siri, Spotlight, Face ID lock, CSV export, and all-stage Delete All behaviors
  pass the signed-device checklist. CSV copy was inspected but no share destination or file was
  created in this continuation.

## Remaining release constraints

- Production telemetry has no provisioned D1 and is not deployed. Optional telemetry must remain
  fail-closed and must never affect local budgeting, entitlement, or deletion of local financial
  data.
- Production CloudKit schema/deployment and distribution signing remain unproved. The accepted
  C4B physical waivers remain explicit non-passes and do not waive deterministic or release checks.
- No App Store Connect answer has been copied or accepted. No archive, IPA, upload, tester
  assignment, G1 decision, or public-release action occurred.
- The required-reason source gate cannot replace Xcode's distribution privacy report or inspection
  of compiled dependencies; those remain mandatory C6-03/C12 evidence.
- C6-02 cannot become Done until the exact branch receives independent review, hosted CI is green,
  and the owner accepts the remaining manual evidence or records a narrowly scoped decision for
  each unresolved item. C6-03 requires a separate explicit owner instruction.
