# C6-02 Signed-Device and App Review Preflight

Status: **In Progress after explicit owner entry on 2026-08-30.** The source/privacy correction
and one development-signed Release-device inspection are complete pending independent review.
Customer-facing StoreKit, accessibility, localization, data-protection, and distribution-signed
checks remain open. C6-03, archive, upload, deployment, App Store Connect writes, tester assignment,
G1, distribution, and release remain unauthorized.

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
vocabulary. This branch remains pending independent PR review.

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

Provisioning limitation:

- Direct device installation used a development provisioning profile, so the signed app has
  `aps-environment = development` and `get-task-allow = true`. This is expected for this mode and
  is not accepted as distribution evidence.
- `Scripts/inspect-c6-release-app.sh --mode signed-device` requires that exact development-signed
  shape. Its separate `--mode distribution` requires `aps-environment = production` and
  `get-task-allow = false`; C6-03 must run that mode on the authorized archive/export before any
  upload.

## Manual signed-device evidence still open

- [ ] Monthly and annual product presentation uses live localized StoreKit prices and correct
  legal/renewal disclosure; unsupported paid introductory offers remain fail-closed.
- [ ] Purchase, cancellation, restore, Manage Subscriptions, already-entitled, unavailable
  authority, and retry paths present truthful localized states without duplicate purchase entry.
- [ ] Airplane-mode launch preserves a previously verified local Pro snapshot while optional
  configuration/telemetry fail closed.
- [ ] English and Simplified Chinese purchase, privacy, receipt, iCloud, export, and Delete All
  copy has no raw localization keys, clipping, or stale terms.
- [ ] VoiceOver, AX5, Increase Contrast, Reduce Motion, light/dark appearance, focus order, touch
  targets, sheets, alerts, keyboard, and supported portrait orientations pass on the signed phone.
- [ ] Camera and photo-picker receipt paths remain local, preview/retry/cancel correctly, preserve
  edits, and require explicit Save before ledger persistence.
- [ ] Instruments confirms launch/scroll/memory/persistence behavior; effective SwiftData file
  protection is inspected in the installed container.
- [ ] Notification, Siri, Spotlight, Face ID lock, CSV export, and all-stage Delete All behaviors
  pass the signed-device checklist.

## Remaining release constraints

- Production telemetry has no provisioned D1 and is not deployed. Optional telemetry must remain
  fail-closed and must never affect local budgeting, entitlement, or deletion of local financial
  data.
- Production CloudKit schema/deployment and distribution signing remain unproved. The accepted
  C4B physical waivers remain explicit non-passes and do not waive deterministic or release checks.
- No App Store Connect answer has been copied or accepted. No archive, IPA, upload, tester
  assignment, G1 decision, or public-release action occurred.
- C6-02 cannot become Done until the exact branch receives independent review, hosted CI is green,
  and the owner accepts the remaining manual evidence or records a narrowly scoped decision for
  each unresolved item. C6-03 requires a separate explicit owner instruction.
