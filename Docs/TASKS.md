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
- Export the expense/income ledger as an ephemeral RFC 4180 CSV with exact minor-unit conversion,
  raw-note/source disclosure, UTF-8 BOM, and spreadsheet-formula neutralization.
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
- Add three included, persisted skins from the owner's visual references through one semantic
  theme environment and distinct source-controlled background artwork; keep future entitlement
  metadata out of the UI until commerce exists.
- Use `花有数` throughout Simplified Chinese user-facing copy while preserving `MindBudget` for
  English and all established technical identifiers.

## Phase 10 — Polish, tests, accessibility, TestFlight readiness
Status: Done
- [x] Add an explicit, localized repair action for unreadable or orphaned cooling-off records.
  Show the affected count, require confirmation, revalidate before deletion, and never delete
  those records implicitly.
- [x] Add bilingual catalog parity/format checks, an AX5 navigation smoke test, an always-on
  deterministic Dashboard projection contract with 10,000 varied expenses, and a separate local
  release-machine first-load signal with a 500 ms ceiling.
- [x] Add opaque 1024px standard, dark, and tinted App Icon variants, current TestFlight candidate
  version 0.9.2/build 4 configuration, localized in-app release notes, static release checks,
  per-file core-service coverage enforcement, App Store metadata drafts, and a release checklist.
- [x] Localize the release display name to `花有数` for Simplified Chinese and `MindBudget` for
  English, without combining them, and use `温和的预算与消费复盘工具` as the Simplified Chinese
  App Store subtitle.
- [x] Add a sub-second, localized cold-launch brand transition that uses the selected skin, runs
  only once per process, and falls back to opacity-only presentation under Reduce Motion.
- [x] Reject on-device wording proposals that do not match the English/Simplified Chinese
  interface language, fall back to the matching deterministic template, and resolve dynamic Ask
  action labels explicitly through the active locale.
- [x] Restore current-period budget editing in the focused Settings page through an atomic
  amount-only update that preserves plan identity, boundaries, currency, and category budgets.
- [x] Rebalance the Today amount from the authoritative remaining flexible budget, explain budget
  reservations in Settings and Ask, and keep older in-app update notes collapsed as history.
- [x] Anchor Today's reference amount at the start of each calendar day so every flexible expense
  reduces it one for one, clamp the visible value at zero with a localized non-color-only notice,
  and expose all expense categories in one horizontally scrollable selector.
- [x] Add an optional, default-off Face ID app lock under Privacy controls, with authenticated
  enable/disable, launch and foreground locking, a passcode recovery path, and an opaque privacy
  cover while locked.
- [x] Complete the full automated validation after the Phase 10 diff is final, including a
  generic iOS Simulator Release build and the complete unit/UI/coverage suite.
- [ ] Complete signed physical-iPhone VoiceOver, AX5, dark-mode, iOS 17/iOS 26, Instruments,
  system-integration, data-protection, screenshot, and archive checks in `RELEASE_CHECKLIST.md`.
- [x] Archive and upload `0.9.6 (7)` using the owner's latest China-region Apple Developer team;
  Xcode and App Store Connect transport accepted bundle `com.xdgf558.MindBudget` under team
  `2AM5S7BM2N` on 2026-08-10. Tester-group assignment remains manual.

## Phase 11 — Free-tier feature completion
Status: Done
- [x] Add unlimited exact manual income entries through Schema V2, with create/edit/search/delete,
  targeted note projection, a unified chronological Log, and no automatic budget mutation.
- [x] Replace the seven-day presentation with deterministic recent-30-calendar-day totals,
  category/emotion breakdowns, and a 30-point daily trend calculated from local expenses.
- [x] Enforce at most five open wishlist items atomically at `DataActor` for app, Siri, and reopen
  paths; completed, skipped, and archived history remains outside the limit.
- [x] Include income in CSV disclosure/export and verified Delete All, migrate V1 stores without
  data loss, publish synchronized `0.9.2 (3)` notes, and pass the complete automated gates.
- [x] Keep expense-only category/bucket filters from hiding Income mode while preserving them for
  the user's return to Expenses.
- [x] Refresh Insights on selection and saved-data revisions, reject stale loads, and keep valid
  expense summaries visible when a supplementary insight projection fails. Treat unreadable
  cooling-off outcomes as unknown rather than zero, stop dependent narrative/AI/persistence work,
  and make the partial state visible without showing stale insight cards.

## Phase 12 — Language, income allocation, savings goal, and recurring fixed expenses
Status: Done
- [x] Add a persisted, extensible app-language setting with Follow System, Simplified Chinese, and
  English choices; make SwiftUI copy, formatters, deterministic Ask/templates, and app-owned
  notifications consistently follow the selected app locale without changing device language.
- [x] Show exact per-entry income in cycle planning without silently increasing spending
  permission. Define and implement an explicit user-confirmed allocation between current spending
  budget and savings while preserving the independent income ledger.
- [x] Add a cross-cycle total savings goal and progress model that remains distinct from the
  existing per-cycle savings reservation used by `BudgetEngine`.
- [x] Add user-confirmed monthly recurring fixed-expense rules with calendar/time-zone semantics,
  stable occurrence identities, duplicate prevention, edit/pause/delete controls, and honest
  reconciliation when the app was not running on the intended date.
- [x] Decide and test the required SwiftData Schema V3 migration before adding persisted fields or
  models, then publish the completed work as PR #18. Do not mix this scope into PR #17.
- [x] Close PR #18 review gaps: publish language changes immediately without relaunch, bind every
  nonzero spending allocation to an explicit persisted cycle containing the income date, preserve
  the source-occurrence month when a recurring rule date is edited, and bound each complete
  reconciliation transaction to the oldest 120 pending occurrences across all rules.
- [x] Make recurrence catch-up recoverable across successive foreground batches, publish skin
  changes to the root theme immediately, centralize the new persisted setting keys, and inject the
  SwiftUI environment calendar into initial reconciliation as well as foreground reconciliation.
- [x] Surface remaining recurring catch-up work in Settings as a non-error progress state, return
  each pending schedule date with its already-computed occurrence key, and fail closed after a
  bounded 1,200-month scan instead of leaving an unbounded foreground loop.
- [x] Remove the redundant manual fixed-expense forecast from initial, transition, and Settings
  budget forms. Keep fixed expenses in the ledger/recurring workflow, use monthly income plus only
  explicitly allocated extra income minus savings for both preview and runtime, keep Expected
  expenses as an independent pace reference, preserve the old funding base and reservation for a
  migrated current cycle, and retire both through a lightweight Schema V4 authority marker when
  future plans are created.

## Post-upload update — Savings progress and app-locale model guidance
Status: In Progress
- [x] Add a standalone Insights savings-progress module backed by the cross-cycle savings-goal
  projection, showing target, saved, remaining, and completion percentage without changing budget
  arithmetic.
- [x] Check Foundation Models support against the selected app locale and provide Apple's explicit
  locale plus required-language instruction on Ask, reminder, and cycle-summary model paths.
- [x] Close review gaps by separating unsupported app language from unsupported region, requiring
  every capability caller to provide a locale, preserving Hans/Hant session instructions, and
  proving overflow-safe savings completion at and beyond the target.
- [x] Promote the reviewed source candidate to `0.9.5 (6)` with matching localized in-app notes,
  changelog, tester guidance, and release-readiness checks; do not Archive or upload before approval.
- [x] Pass the complete static, Release-build, unit/UI, and coverage validation gates.
- [x] Keep 0.9.4 Archive/upload evidence explicitly historical, leave every 0.9.5 execution gate
  unchecked, and align all four 0.9.5 user-visible changes across the changelog, TestFlight tester
  guidance, and localized in-app release notes.
- [x] Archive and upload `0.9.5 (6)` through the owner's current team; App Store Connect transport
  accepted it on 2026-08-09. Keep subsequent budget-setup work in Unreleased and require a new build
  number before the next replacement upload.
- [x] Promote the approved budget-setup work to `0.9.6 (7)`, pass local and GitHub release gates,
  Archive from merged `main`, and upload it through the owner's current team. App Store Connect
  transport accepted build 7 for processing on 2026-08-10; tester-group assignment remains manual.

## Commercialization and Pro development — separate COM track
Status: COM-C0A, COM-C0B, COM-C1, and COM-C2 Done; COM-C3 C3-01, C3-02, and C3-03A Done, with C3-03B implementation complete pending independent review
- [x] Extract the owner-approved v1.4 commercialization specification into a dependency-aware,
  review-sized execution map at `Docs/COMMERCIALIZATION_TASKS.md` without changing product code.
- [x] Execute the COM-C0A audit work only: lock the specification, build the Requirement index and
  conflict register, audit the repository and reproducible baseline, and stop for owner decisions.
  The owner accepted SPEC-012, SPEC-013, SPEC-014, and SPEC-017 on 2026-08-10.
- [ ] Keep the public iPhone App Store launch paused until the COM-C0B through COM-C12 iPhone gates
  are complete. Existing TestFlight users receive no production Pro rights. Watch distribution is
  a separate post-iPhone-1.0 milestone and does not block the iPhone launch.
- [x] Begin COM-C0B only after the owner's explicit instruction and keep it to durable commercial
  documents, CI/report gates, and non-behavioral test infrastructure. Do not skip ahead to
  entitlement, StoreKit, iCloud, telemetry, Watch, receipt, backend, or cloud-AI implementation.
- [x] Complete COM-C0B with separate commercial memory/decisions, accepted empty current Release
  egress enforced against app Swift source, AI/StoreKit/pricing matrices, reproducible and
  downloadable CI result bundles, source-provenance and documentation gates, the SPEC-018 privacy
  correction, and independently reviewable COM-C1 execution packets. Full Release, Swift/UI,
  money, network, documentation, and coverage validation passed.
- [x] Start COM-C1 only after a new explicit owner instruction; follow
  `Docs/Commercialization/COM_C1_EXECUTION_PACKET.md` and do not import StoreKit or add paid UI.
- [x] Complete the C1-01 pure entitlement domain as its own review unit: exact Free and reachable
  Pro-subscription set semantics, versioned fail-closed representation migration, closed premium
  vocabulary, and structural proof that Free trust features and deferred bits remain unreachable.
- [x] Complete C1-02 only after C1-01 was reviewed and merged: add one immutable central access
  service, deterministic Free environment/session injection, a Debug-only nonpersistent provider,
  and executable raw-bit/migrator-call/duplicate-check/authority-chokepoint/Release-boundary gates
  with built-in parser samples, without StoreKit, purchase UI, products, prices, or feature-entry
  locks.
- [x] Complete C1-03 only after C1-02 was reviewed and merged: route the accepted Apple on-device
  AI, non-24-hour cooling-off, and advanced Siri entries through one Commerce-owned snapshot;
  preserve template fallback, 24-hour cooling-off, basic Siri record/check actions, and every
  typed Free-core capability; reject feature-local paid booleans, Product IDs, manual unlocks, and
  duplicate direct access decisions with the static gate.
- [x] Close COM-C1 after PR #27 passed independent review and merged to `main`; preserve the
  post-0.9.6 distribution hold until purchase/restore and purchase presentation exist.
- [x] Enter COM-C2 only after the owner's explicit instruction. Complete C2-01 as an isolated
  Xcode StoreKit Configuration fixture containing exactly the accepted Monthly/Annual test
  catalog, copied only to tests and activated only by a non-Archive local scheme. Do not add
  runtime StoreKit authority, purchase/restore, paywall, prices, trials, or formal products.
- [x] Complete C2-02 review and merge for the typed runtime catalog, presentation-only cache,
  verified current-entitlement authority, one update listener, and live UI/App Intent snapshot.
  PR #29 passed independent review and green CI, then merged as `a45d480`; purchase, restore,
  status mapping, transaction finish, formal terms, and distribution remain out.
- [x] Begin C2-03 only after C2-02 review/merge and both dedicated CHN/USA
  `Product.products(for:)` probes execute rather than skip and pass under a supported final
  Xcode/runtime surface. The 2026-08-13 physical iPhone Air run used final Xcode 26.6 `17F113`
  and final iOS 26.6.1 `23G82`; 5 passed, 0 failed, 0 skipped, including both storefront probes.
- [x] Independently review, obtain green CI, and merge the implementation-complete C2-03
  candidate. Local validation is complete: 44/44 focused tests, 310/310 lifecycle iterations,
  342 Swift tests, all 13 UI tests, and every selected coverage file passed; the strict local
  wall-clock signal separately passed 10/10. The candidate centralizes verified purchase/finish,
  pending, cancellation, neutral error,
  user-triggered restore, unfinished retry, and subscribed/grace/retry/expired/revoked mapping in
  the single `EntitlementStore` lifecycle authority. The same lifecycle task supervises both
  transaction and subscription-status update sequences; a status signal triggers a fresh full
  reconciliation rather than becoming a second authority. No current view calls the typed
  purchase or restore seams. PR #30 passed independent review and CI, then merged as `3fc72b4`
  on 2026-08-13.
- [x] Independently review, obtain green CI, and merge the implementation-complete C2-04
  candidate. It binds every verified StoreKit fact to the same verified app environment,
  preserves exact environment-scoped presentation caches, proves
  Configuration/Sandbox/TestFlight/Production isolation and catalog-failure behavior, runs the
  full Free regression, and retains the distribution hold. Local evidence passed 49/49 focused
  tests, 20/20 Phase 10 tests across 10 iterations, 346 Swift tests, all 13 UI tests, and the
  complete coverage gate. PR #31 passed independent review and green CI and merged as `a293762`
  on 2026-08-13.
- [x] Complete and independently review C3-01 under the owner's provisional test inputs:
  US$1.99 Monthly, US$19.99 Annual, a 7-day StoreKit-eligible trial, and HKG/USA/SGP/TWN runtime
  coverage. The paywall must remain voluntary, show only StoreKit prices and eligibility, use the
  typed purchase/restore authority, and preserve the post-0.9.6 distribution hold. At the time of
  implementation, C3-02 and later remained blocked. The physical final-runtime
  dedicated scheme passed 9/9 with HKG/USA/SGP/TWN plus Monthly/Annual transaction verification;
  review remediation now keeps exact P1W terms fixture-only, blocks purchase under unavailable
  entitlement authority in both View and actor, and binds renewal disclosure to the app locale.
  PR #33 passed independent review and green CI and merged as `747b628` on 2026-08-14.
- [x] Independently review, obtain hosted green CI, and merge the implementation-complete C3-02
  candidate: derive active trial lifecycle from verified
  StoreKit transaction/renewal facts, separate the current trial product from the accepted next-
  renewal `autoRenewPreference`, schedule one generic T−5 calendar reminder, cancel or
  replace it on every lifecycle change, and use an in-app fallback without an implicit permission
  prompt. Pending notification copy says the trial ends soon without asserting mutable auto-renew
  state. Local evidence passed the original 68/68 focused run and the 13/13 review-remediation
  trial suite. The owning full validation produced 382 results: 376 passed, 6 explicit opt-in
  StoreKit runtime probes skipped, and 0 failed; all 14 UI tests and every selected coverage gate
  passed. The physical final-device suite passed 9/9 with no skip across
  HKG/USA/SGP/TWN and both Monthly/Annual trial-lifecycle derivation paths. PR #34 passed
  independent review and green GitHub Actions run `31803898776`, then merged as `12d9217` on
  2026-08-14. The P1W fixture is never authority; C3-03, formal economics,
  versioning, Archive/upload, tester assignment, and distribution remain blocked.
- [x] Independently review and merge C3-03A: strict Ed25519 signed-envelope verification, exact
  schema/version/expiry/size bounds, rollback and same-version-equivocation rejection, durable
  signed cache/high-water mark, serialized concurrent acceptance, exact UTC timestamp/no-duplicate-
  key parsing, sticky corrupt-state fail-closed recovery, abstraction-level write readback, and
  conservative built-in presentation. The accepted v1 payload
  contains only `proValueTriggersEnabled`; C3-03A adds no network transport, URL, production key,
  entitlement/StoreKit authority, version, Archive/upload, tester assignment, or distribution.
  PR #36 passed independent review and green GitHub Actions run `31856271268`, then merged to
  `main` as `1ebb36c` on 2026-08-15.
- [ ] Review and merge C3-03B after the satisfied C3-03A gate. The one accepted fixed anonymous
  `GET /v1/config` transport, key provenance, privacy/log/TTL review, captured-traffic evidence,
  and verified presentation integration are implemented without expanding the payload vocabulary.
  Development version `bf6c5049-a389-4ea7-af0a-e8425b8957e2` is the only deployment; the live app
  path passed 8/8, Worker tests passed 13/13, and the owning full validation produced 402 results
  (395 passed, 7 explicit skips, 0 failed) plus 14/14 UI and a separate 10/10 performance signal.
  Review remediation closes request-time expiry, continuous-foreground expiry, unavailable-
  authority presentation, and detached-cancellation gaps; its focused suite passed 11/11 and fresh
  full/hosted evidence is pending.
  Staging/Production, final Release binary/traffic, C3-04, and distribution remain blocked.
