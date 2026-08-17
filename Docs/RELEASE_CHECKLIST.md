# RELEASE_CHECKLIST

Phase 10 can automate source, build, test, coverage, localization, performance, and asset checks.
It cannot prove account ownership, production signing, physical-device accessibility, system
integration behavior, or App Store Connect state. Do not label V1 TestFlight-ready until every
unchecked item below has been performed against the release commit.

The uploaded 0.9.6 (7) binary is historical and immutable. COM-C3 passed independent review and
green CI through PR #40 (`9448ca9`), and the owner authorized one traceable 0.9.7 (8) Archive and
transport upload on 2026-08-16. This does not authorize this workflow to assign internal testers,
submit external Beta App Review, or submit an App Store version; those actions remain manual.
Production signed configuration remains undeployed and therefore fails to its conservative `false`
presentation default without changing StoreKit entitlement or permanent subscription controls.

## Automated release gates

- [x] `Scripts/check-no-floating-point-money.sh` passes.
- [x] `Scripts/validate.sh` passes the Release build, full unit/UI suite, and per-file core
  coverage gate.
- [x] The deterministic 10,000-expense Dashboard projection passes with varied dates, all
  categories, and optional merchants. The separate local first-load signal remains below 500 ms
  on the recorded simulator; hosted CI deliberately skips only that noisy clock assertion.
- [ ] Repeat the Dashboard load, scrolling, and persistence measurement with Instruments on the
  signed release iPhone; treat that device evidence as authoritative.
- [x] English and Simplified Chinese catalogs have matching, nonempty, format-compatible keys.
- [x] AX5 UI smoke keeps onboarding, all four tabs, Add Expense, and Settings reachable.
- [x] Settings smoke edits and saves the current budget through the focused second-level page;
  actor tests reject historical-period mutation and preserve plan/category identities.
- [x] The standard, dark, and tinted 1024px opaque App Icon variants and privacy manifest pass
  static release checks.
- [x] Release configuration is version 0.9.8/build 9, iPhone-only, iOS 17+, and contains no shared
  Apple Team ID. Build 9 is the next replacement candidate and build 8 remains historical.
- [x] Debug and Release use the English `MindBudget` fallback and ship localized Home Screen names:
  `MindBudget` for English and `花有数` for Simplified Chinese. The Chinese App Store draft uses
  `温和的预算与消费复盘工具` as its subtitle.

## Current China-region developer account and signing

- [x] In Xcode Settings > Accounts, confirm the owner's latest China-region Apple ID is active.
- [x] In Signing & Capabilities, select the current China-region team locally for the app and test
  targets. Do not commit `DEVELOPMENT_TEAM` and do not select the previous team.
- [x] Confirm the final Bundle ID belongs to that team and exactly matches the App Store Connect
  app record; update the ignored `Config/Local.xcconfig` prefix if needed.
- [x] Confirm the distribution certificate and provisioning profile are valid for that team.
- [ ] Confirm App Store Connect agreements are accepted and the correct legal entity, tax, and
  banking state is active where applicable.
- [x] Before the 0.9.7 replacement Archive, increment the build number. Reverify the current team,
  App Store Connect record, agreements, certificate, and profile during Archive/export.

### Completed 0.9.8 (9) release execution

- [x] On 2026-08-17, Archive Release 0.9.8 (9) from merged `main` (`6fa1cb3`). The archive reports
  bundle ID `com.xdgf558.MindBudget`, team `2AM5S7BM2N`, `UIDeviceFamily = [1]` (iPhone-only), and
  `MinimumOSVersion 17.0`.
- [x] Confirm the Archive contains no local StoreKit fixture, and that Release still reaches only
  the Production configuration host because `PublicConfigurationDeploymentEnvironment.current()`
  returns `.production` unconditionally outside `DEBUG`. The same recorded limitation applies: all
  three endpoint literals remain inert strings in the binary.
- [x] Upload Release 0.9.8 (9) with `manageAppVersionAndBuildNumber: false`, so build 9 stays
  traceable to the merged commit. Export used Apple cloud-managed remote signing with
  `Apple Distribution: Hao Ye (2AM5S7BM2N)`; transport accepted build 9 at 2026-08-17 21:59 (+0800)
  with delivery UUID `dda1eb09-5d8b-43c6-a2fd-ea910fa422ac`.
- [ ] Not performed here and still owned manually: internal tester-group assignment, external Beta
  App Review submission, and App Store version submission.

### Completed 0.9.7 (8) release execution

- [x] On 2026-08-17, Archive Release 0.9.7 (8) from merged `main` (`9792901`). The archive reports
  bundle ID `com.xdgf558.MindBudget`, team `2AM5S7BM2N`, `UIDeviceFamily = [1]` (iPhone-only), and
  `MinimumOSVersion 17.0`.
- [x] Confirm the Archive contains no local StoreKit fixture: the archived `MindBudget.app` has no
  `.storekit` resource, because the fixture belongs only to the separate `MindBudget-StoreKit-Local`
  scheme while `MindBudget.xcscheme` archives plain Release.
- [x] Confirm Release selects only the exact Production configuration host.
  `PublicConfigurationDeploymentEnvironment.current()` returns `.production` unconditionally outside
  `DEBUG`, so a Release build has no code path to Development or Staging. Recorded limitation: all
  three endpoint literals remain present as inert strings in the binary because they are cases of the
  same `endpoint` property; presence of a string is not a reachable endpoint.
- [x] Upload Release 0.9.7 (8) through the authenticated current App Store Connect account. Export
  used Apple cloud-managed remote signing with `Apple Distribution: Hao Ye (2AM5S7BM2N)`; transport
  accepted build 8 for `com.xdgf558.MindBudget` at 2026-08-17 09:52 (+0800) with delivery UUID
  `b7fb59b8-a9c6-4003-a07a-71ea608a2ea6`, and App Store Connect began processing the package.
- [ ] Not performed here and still owned manually: internal tester-group assignment, external Beta
  App Review submission, and App Store version submission.

### Completed 0.9.6 (7) release evidence (historical, not a next-upload gate)

- [x] On 2026-08-10, Archive Release 0.9.6 (7) with the current team and confirm the archive reports bundle ID
  `com.xdgf558.MindBudget`, team `2AM5S7BM2N`, iPhone-only support, and iOS 17.0 minimum deployment.
- [x] On 2026-08-10, upload Release 0.9.6 (7) through the authenticated current App Store Connect account and
  confirm transport accepts build 7 for the intended app. Tester-group assignment remains manual.

### Completed 0.9.5 (6) release evidence (historical, not a current-source gate)

- [x] On 2026-08-09, Archive Release 0.9.5 (6) with the current team and upload it through the
  authenticated App Store Connect account; transport accepted the upload for processing.

### Completed 0.9.4 (5) release evidence (historical, not a 0.9.5 gate)

- [x] On 2026-08-09, Archive Release 0.9.4 (5), validate it in Organizer, and inspect the
  archive's application identifier prefix/team before upload.
- [x] On 2026-08-09, upload Release 0.9.4 (5) while logged into the current account, wait for
  processing, and verify the build appears under the intended App Store Connect app before
  assigning testers.

### Dated development preflight evidence (historical, not a release gate)

On 2026-08-07, the owner's development Mac showed the current China-region account active in
Xcode, used the current team through ignored local configuration to produce a signed iPhone Debug
build, and showed the applicable App Store Connect agreements as active. This records what was
observed during development; it does not satisfy the unchecked Archive-time gates above. Reverify
all account, team, agreement, certificate, profile, and app-record state on the machine and account
used for every Archive and upload.

## Physical iPhone and accessibility

- [ ] Run the full core journey with VoiceOver; confirm navigation order is Today, Log, Add
  Expense, Insights, Wishlist and that selected-tab state and pace values are spoken.
- [ ] Inspect every V1 screen at AX5, in English and Simplified Chinese, including keyboard,
  sheets, alerts, repair confirmation, Export, Privacy, and Delete All.
- [ ] Inspect light/dark mode, Increase Contrast, Reduce Motion, and both portrait orientations
  supported by the iPhone target.
- [ ] Force-quit and cold-launch in English and Simplified Chinese on the signed iPhone. Confirm
  the localized name and selected-skin artwork, sub-second exit, no replay after foregrounding,
  and an opacity-only presentation while Reduce Motion is enabled.
- [ ] Inspect the standard, dark, and tinted Home Screen icon appearances on a real supported
  iPhone; confirm iOS applies the corner mask, no track or marker is clipped, and the localized
  `花有数` / `MindBudget` label matches the current system language without combining both names.
- [ ] Verify touch targets, focus order, dismissal behavior, and no clipped or overlapping text.
- [ ] Run on a real iOS 17 device and a supported iOS 26 device.
- [ ] Verify the effective SwiftData file-protection class in the release-signed container.

## System integrations and privacy

- [ ] With every integration disabled, confirm no AI call, Siri entity, notification, Spotlight
  document, merchant name, or onscreen activity is exposed.
- [ ] Verify notification authorization/denial, quiet hours, replacement, cancellation, and
  amount/note-free lock-screen copy.
- [ ] Verify Siri writes, five-second deduplication, amount precision errors, and authenticated
  budget-impact speech on a real device.
- [ ] Verify Spotlight indexing and clearing, including the merchant-name triple gate.
- [ ] Verify Apple Intelligence availability/fallback and output validation on a supported device;
  in both English and Simplified Chinese, confirm a wrong-language proposal falls back to a fully
  localized template and no dynamic action key is rendered literally.
- [ ] Enable the optional Face ID app lock on the signed release iPhone. Verify authenticated
  enable/disable, cancel/failure staying locked, device-passcode recovery, cold launch and
  background return, localized purpose copy, and an amount-free app-switcher snapshot.
- [ ] Verify same-device Siri “this” resolution. Add only expense, budget, and wishlist-item to
  `NSUserActivityTypes` if the signed test proves declaration is required; never add the inactive
  placeholder type.
- [ ] Export CSV to Numbers and Excel; confirm raw-note/merchant disclosure and formula safety.
- [ ] Exercise Delete All and confirm all stages plus the post-delete zero-count verification.
- [ ] Create an isolated orphan cooling-off fixture and begin in Wishlist. Confirm no corrupt row
  is presented as a valid item, then judge whether Today → Settings gear → Notifications makes
  the warning discoverable enough from that symptom. Confirm the count, cancel once, explicitly
  repair it, and verify readable records remain. If the route is not discoverable on device, add
  a neutral Wishlist pointer without duplicating or automatically triggering the repair action.

## Store listing and TestFlight

- [x] Before any post-0.9.6 Archive, verify that the StoreKit-derived
  entitlement lifecycle, user-visible purchase and restore paths, and the owning commercialization
  release gates are complete. COM-C3 met that source/review/CI gate through PR #40 (`9448ca9`).
  Upload-only authorization does not complete the separate tester-assignment or public-release
  checks below.

- [x] Immediately before uploading the next replacement, confirm its marketing version/build has a
  matching dated section in
  `Docs/CHANGELOG.md` and matching TestFlight “What to Test” notes in
  `Docs/APP_STORE_SUBMISSION.md`.
- [ ] Review `Docs/APP_STORE_SUBMISSION.md` with the product owner and finalize localized name,
  subtitle, description, keywords, support/privacy URLs, and App Review notes.
- [ ] Capture localized screenshots from the release build using synthetic data only.
- [ ] Complete App Privacy, age rating, encryption/export-compliance, content-rights, and regional
  availability forms from the final binary rather than the development plan.
- [ ] Confirm the release app/Archive contains no local StoreKit Configuration fixture, Debug
  entitlement provider, Development/Staging configuration endpoint, provisional price/trial
  literal, or deferred Lifetime/cloud-AI quota/iCloud/receipt/Watch claim. Confirm only approved
  products and current StoreKit terms are presented, and that the embedded Production host/key
  match the dated captured-traffic and Worker-deployment evidence.
- [ ] Run Instruments for launch, scrolling, memory, and persistence work; inspect Organizer and
  device logs for crashes or hangs.
- [ ] Distribute first to internal TestFlight testers, collect results, increment build number for
  every replacement, then expand testing only after the privacy/accessibility checklist passes.
