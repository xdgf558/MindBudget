# TASKS

Status values: Todo, In Progress, Blocked, Done.
A phase may only be marked Done after both `xcodebuild build` and `xcodebuild test` pass.

## Phase 0 — Repo and agent memory
Status: Done

## Phase 1 — Money, enums, SwiftData models, DataActor
Status: Done

## Phase 2 — Budget engine and cycle math
Status: Done

## Phase 3 — Onboarding, dashboard, manual expense tracking
Status: Done

## Phase 4 — Emotion tags, wishlist, cooling-off
Status: Done

## Phase 5 — Rule engine, reminder throttle, template reminders, insights
Status: Done
- Attribute cooling-off outcomes with `outcomeRecordedAt` only through deterministic code;
  preserve `completedAt` as the actual cooling-period end.
- Keep insight detection independent from whether reminders are enabled. Record only actual
  reminder presentations, and allow at most one interrupting sheet per purchase flow.
- Keep local template generation mandatory and deterministic. Phase 5 has no notification
  scheduling and no real Foundation Models call.

## Phase 6 — Notifications, CSV export, privacy controls
Status: Done
- Request local-notification permission only from an explicit user action; background and
  foreground reconciliation must never prompt implicitly.
- Schedule only cooling-off review reminders, with stable per-plan identifiers, quiet-hour
  deferral, exact cancellation, documented item-name review copy, and no amount or raw-note
  input; isolate corrupt plans without blocking valid reminders.
- Export the expense ledger as an ephemeral RFC 4180 CSV with exact minor-unit conversion,
  raw-note disclosure, UTF-8 BOM, and spreadsheet-formula neutralization.
- Delete local data through the ordered notification → Spotlight → SwiftData → preferences
  pipeline; verify all model counts are zero before preference reset, stop on the first
  failure, and never report a partial deletion as success.

## Phase 7 — Ask fallback and AI layer
Status: Done
- Keep `ExpenseDetail` and every raw note outside redactor/model input APIs. Privacy tests
  must prove only allow-listed aggregate contexts can reach a generator.
- Keep raw cooling-off completion/outcome timestamps outside model contexts; expose only
  deterministic aggregate outcome counts.
- Classify the seven supported Ask intents locally and keep unknown/out-of-scope questions
  on explicit template paths that never call a model.
- Keep complete template answers authoritative on iOS 17+; make Foundation Models a
  default-off wording enhancement behind one centralized four-part capability gate.
- Keep Ask facts in an exhaustive per-intent typed payload; never reopen the redactor boundary
  with a generic fact dictionary, arbitrary insight strings, or caller-provided template prose.
- Validate every generated title, body, number, and action against its redacted context;
  timeout, availability, generation, and validation failures must return templates.

## Phase 8A — App Intents, App Entities, Spotlight (iOS 17+)
Status: Done
- Provide all nine approved App Intents and all seven redacted App Entities behind one
  centralized, default-off Siri capability gate; keep every action correct without AI.
- Convert App Intent amount parameters to exact minor units only inside the isolated
  transport adapter, sanitize Siri text to 40 characters, and deduplicate identical
  Siri/Shortcut expense writes inside one actor transaction for five seconds.
- Publish localized App Shortcuts and route open intents and Spotlight results only to
  app-owned Dashboard, expense, wishlist, item-detail, and Insights destinations.
- Maintain one redacted app-owned Spotlight domain. Exclude exact amounts and notes,
  represent expenses with budget-relative bands, clear the domain when disabled, and
  keep index failures from changing local user data.
- Gate merchant-name indexing on the centralized Spotlight capability, the global
  merchant-name opt-in, and at least one eligible expense with the same normalized key.

## Phase 9 — IndexedEntity and onscreen awareness (iOS 26+)
Status: Done
- Conform all seven amount-free App Entities to `IndexedEntity` and associate those typed
  projections with the existing redacted Spotlight documents only on iOS 26+.
- Route Ask through an intent-scoped `LocalSearchService` whose facts come only from
  authoritative SwiftData projections; Spotlight remains navigation-only and never supplies
  a numeric model fact.
- Publish amount-free `NSUserActivity.appEntityIdentifier` references for Dashboard,
  expense detail, and wishlist detail behind the centralized default-off Siri conjunction.
  Stop publication through a nil SwiftUI activity element whenever that conjunction closes,
  and export only version/kind/identifier through the three entities' `Transferable` boundary.
  Keep Wishlist and Insights list selection fail-closed until a public multi-object API ships.
- Carry a gated wishlist entity reference to the notification SDK boundary. Xcode 26.6 /
  iOS 26.5 exposes no public notification entity-annotation property, so the adapter remains
  an explicit no-op stub and the iOS 17+ `userInfo` route remains authoritative.

## Design interlude — UI/UX redesign with reserved Pro seams
Status: Done
- Rebuild the existing iPhone experience from the owner-provided high-fidelity handoff while
  preserving the actor, money, privacy, localization, and deterministic-engine boundaries.
- Replace the fake add/settings tabs with four real content tabs, a separate accessible add
  action, and Settings presented from Today; update every app-owned deep-link route with tests.
- Apply the shared warm-paper design system and redesign Today, expense entry and reminder,
  expense history, Insights, Wishlist/review, Ask, Settings, and budget setup without removing
  an existing capability or moving raw notes across their targeted projection boundaries.
- Reserve clear presentation and routing seams for a later Pro phase, but do not ship StoreKit,
  quotas, locked states, paywall, custom-rule editing, or a visible purchase entry in this
  interlude. Safety, privacy, and data-control features remain unchanged and available.
- Validate the finished redesign with the complete static money check, the complete unit suite,
  and seven end-to-end/localization UI tests before Phase 10 begins.
- Preserve VoiceOver-selected and position semantics for the custom four-tab control, allow its
  labels to grow at accessibility sizes, expose both ratios in the Today pace track, and keep the
  separate center add action fully inside its hit-test layout.
- Declare the five-element VoiceOver order as Today, Log, Add Expense, Insights, Wishlist, and
  derive tab positions/totals from the exhaustive `AppTab` order rather than numeric literals.

## Phase 10 — Polish, tests, accessibility, TestFlight readiness
Status: In Progress
- [x] Add an explicit, localized repair action for unreadable or orphaned cooling-off records.
  Show the affected count, require confirmation, revalidate before deletion, and never delete
  those records implicitly.
- [x] Add bilingual catalog parity/format checks, an AX5 navigation smoke test, an always-on
  deterministic Dashboard projection contract with 10,000 varied expenses, and a separate local
  release-machine first-load signal with a 500 ms ceiling.
- [x] Add an opaque 1024px App Icon, version 1.0.0/build 1 configuration, static release checks,
  per-file core-service coverage enforcement, App Store metadata drafts, and a release checklist.
- [x] Complete the full automated validation after the Phase 10 diff is final, including a
  generic iOS Simulator Release build and the complete unit/UI/coverage suite.
- [ ] Complete signed physical-iPhone VoiceOver, AX5, dark-mode, iOS 17/iOS 26, Instruments,
  system-integration, data-protection, screenshot, and archive checks in `RELEASE_CHECKLIST.md`.
- [ ] Archive and upload using the owner's latest China-region Apple Developer team; verify the
  final Bundle ID, distribution identity, agreements, and App Store Connect app before upload.
