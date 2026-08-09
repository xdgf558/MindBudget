# RELEASE_CHECKLIST

Phase 10 can automate source, build, test, coverage, localization, performance, and asset checks.
It cannot prove account ownership, production signing, physical-device accessibility, system
integration behavior, or App Store Connect state. Do not label V1 TestFlight-ready until every
unchecked item below has been performed against the release commit.

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
- [x] Release configuration is TestFlight candidate version 0.9.4/build 5, iPhone-only,
  iOS 17+, and contains no shared Apple Team ID.
- [x] Debug and Release use the English `MindBudget` fallback and ship localized Home Screen names:
  `MindBudget` for English and `花有数` for Simplified Chinese. The Chinese App Store draft uses
  `温和的预算与消费复盘工具` as its subtitle.

## Current China-region developer account and signing

- [ ] In Xcode Settings > Accounts, confirm the owner's latest China-region Apple ID is active.
- [ ] In Signing & Capabilities, select the current China-region team locally for the app and test
  targets. Do not commit `DEVELOPMENT_TEAM` and do not select the previous team.
- [ ] Confirm the final Bundle ID belongs to that team and exactly matches the App Store Connect
  app record; update the ignored `Config/Local.xcconfig` prefix if needed.
- [ ] Confirm the distribution certificate and provisioning profile are valid for that team.
- [ ] Confirm App Store Connect agreements are accepted and the correct legal entity, tax, and
  banking state is active where applicable.
- [ ] Archive Release 0.9.4 (5), validate it in Organizer, and inspect the
  archive's application identifier prefix/team before upload.
- [ ] Upload through Organizer while logged into the current account, wait for processing, and
  verify the build appears under the intended App Store Connect app before assigning testers.

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

- [ ] Confirm the upload's marketing version/build has a matching dated section in
  `Docs/CHANGELOG.md` and matching TestFlight “What to Test” notes in
  `Docs/APP_STORE_SUBMISSION.md`.
- [ ] Review `Docs/APP_STORE_SUBMISSION.md` with the product owner and finalize localized name,
  subtitle, description, keywords, support/privacy URLs, and App Review notes.
- [ ] Capture localized screenshots from the release build using synthetic data only.
- [ ] Complete App Privacy, age rating, encryption/export-compliance, content-rights, and regional
  availability forms from the final binary rather than the development plan.
- [ ] Confirm V1 contains no StoreKit product, paywall, paid lock, trial, quota, ad, or analytics.
- [ ] Run Instruments for launch, scrolling, memory, and persistence work; inspect Organizer and
  device logs for crashes or hangs.
- [ ] Distribute first to internal TestFlight testers, collect results, increment build number for
  every replacement, then expand testing only after the privacy/accessibility checklist passes.
