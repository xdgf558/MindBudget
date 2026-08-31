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
- [ ] Make the Add Expense category chooser fully discoverable and tappable at true AX5 in both
  English and Simplified Chinese, including categories beyond the first visible group. Correct the
  UI-test content-size launch value and add end-to-end AX5 coverage; keep this as a standalone
  accessibility follow-up rather than coupling it to the Insights chart fix in PR #41.
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
Status: Done
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
Status: COM-C0A through COM-C4C Done; C4B-01 Done through PR #57 (`90a1e66`); C4B-02P Done
through PR #58 (`6f5fded`); C4B-02 Done through PR #59 (`211dff2`); C4B-03 product capability
merged through PR #61 (`0f749ce`) after reviewed head `f49de94` passed run `32571676058`; PR #62
merged the reviewed calibration as `0128682` after run `32573992659`; DEC-COM-039 permanently
waives only same-account physical evidence; reviewed waiver head `7b23490` passed run
`32576885537` and PR #63 merged it as `1a14df9`; DEC-COM-040 restores opted-in automatic engine
scheduling, DEC-COM-041 preserves delegate/zone trust boundaries, and DEC-COM-042 permanently
waives only physical background-push observation without a pass. Reviewed final head `f1f37db`
passed run `32726507493`, and PR #64 merged it as `4f6d7fe`. DEC-COM-043 permanently waives the
remaining physical account-switch/offline/quota observations as non-passes and assigns
Distribution signing plus Production schema/deployment/release proof to COM-C6/COM-C12. Reviewed
C4C-01 head `d203308` passed Actions run `32845307426`, and PR #66 merged it
as `8611022`; PR #67 (`bdb94d9`) closed its documentation after run `32850616400`. C4C-01 is Done.
The owner explicitly entered C4C-02. Reviewed head `43c3a35` passed GitHub Actions run
`32860643712`, and PR #68 merged it as `4ca8f1c`; documentation head `4ab0daf` passed run
`32911659905`, and PR #69 merged the closeout as `3e1c5c9`. C4C-02 is Done. The owner explicitly
entered C4C-03. Reviewed head `92ed3a7` passed GitHub Actions run `32921913143`, and PR #70 merged
it as `d294cfb`; C4C-03 is Done. The owner explicitly entered C4C-04. Reviewed remediation head
`f2d249d` passed GitHub Actions run `32946104780`, and PR #72 merged it as `e6316fa`; PR #73 merged
the documentation closeout as `2107723`. C4C-04 is Done. Independent review approved C4C-05
remediation head `8607356` and raised three nonblocking P3 observations. Maintenance head
`81cd107` applied them, passed GitHub Actions run `33035427257`, and PR #74 merged it as `d751ff4`
without a pre-merge rereview. PR #75's closeout review then accepted that exact delta post-merge.
C4C-05 and COM-C4C are Done through PR #75 (`82ef0fa`). A separate explicit owner entry opened
COM-C5 on 2026-08-27. Reviewed final C5-01 head `d937dc8` passed GitHub Actions run `33085630481`,
and PR #76 merged it as `68304ad`. C5-01 is Done without a production capture call site. The owner
entered C5-02 on 2026-08-28. Independent review approved exact remediation head `72abf4b`, hosted
run `33176551566` passed, and PR #78 merged it as `4715054`; C5-02 is Done. The owner entered
C5-03 on 2026-08-29. Independent review approved head `4ea7cd9`; remediation head `0c61427`
closed its P2/P3 findings, passed hosted run `33211270363`, and PR #80 merged it as `a587f42`
without a pre-merge rereview. PR #81's post-merge closeout review confirmed the exact remediation
delta; C5-03 is Done. The owner entered C5-04 on 2026-08-29. Independent review approved the
deletion-order remediation on exact head `2c1cebe` within its declared scope; GitHub Actions run
`33233846430` passed, and PR #82 merged the controlled activation product capability as `28d9eae`.
The privacy manifest, two feature capture files, `TelemetryService`, and operations runbook were
outside that review. Independent review of PR #83 head `daea2d2` raised two P2 findings and one
P3; remediation head `e6bbd3f` applied them and recorded the implementation author's supplemental
inspection of the excluded surfaces, passed run `33242024609`, and merged as `becb020` without a
pre-merge rereview. Current source `becb020` is now deployed only to Development as
version `003c66fa-a57c-4b6a-a8d7-3f75b14cc716`; its synthetic TTL/delete/idempotency probe passed
and retained no new row. PR #84's opt-in real iOS `FixedTelemetryTransport`/`URLSession` probe then
received upload 202 and delete 204; final D1 aggregates were 0 events, 0 identities, and 3
tombstones (2 historical plus the expected live-probe tombstone). Independent review approved
exact PR #84 head `84a96bc`, Actions run `33247176815` passed, and PR #84 merged as `4194b73`.
C5-04/COM-C5 are Done. PR #85 merged the preserved C6 privacy-source handoff as `008b674`, and the
owner entered COM-C6 on 2026-08-29. Independent rereview approved exact PR #86 remediation head
`f77d2a6`, hosted run `33255898196` passed, and PR #86 merged as `015d00e`; C6-01 is Done. The
owner explicitly entered C6-02 on 2026-08-30. Independent review accepted exact PR #88 head
`0ac0500`, hosted run `33283398690` passed, and PR #88 merged as `6c2a051`; C6-02 now has an
implementation-complete bounded evidence packet pending independent review, hosted CI, and merge,
while C6-03, Staging/Production, G1, App Store Connect, distribution, and release remain blocked.
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
- [x] Review and merge C3-03B after the satisfied C3-03A gate. The one accepted fixed anonymous
  `GET /v1/config` transport, key provenance, privacy/log/TTL review, captured-traffic evidence,
  and verified presentation integration are implemented without expanding the payload vocabulary.
  Development version `bf6c5049-a389-4ea7-af0a-e8425b8957e2` is the only deployment; the live app
  path passed 8/8, Worker tests passed 13/13, and the owning full validation produced 402 results
  (395 passed, 7 explicit skips, 0 failed) plus 14/14 UI and a separate 10/10 performance signal.
  Review remediation closes request-time expiry, continuous-foreground expiry, unavailable-
  authority presentation, and direct-service cancellation gaps. Follow-up remediation makes
  startup refresh structured, cancels retained scene refresh on lifecycle exit/Session destruction,
  permits a canceled startup attempt to retry, and defines a tested pre-atomic-write persistence
  commit point. The follow-up owning validation
  produced 410 results (403 passed, 7 explicit skips, 0 failed), including 396/396 unit tests,
  14/14 UI tests, Release build, static gates, and every selected coverage threshold. The reviewed
  head `09c382e` passed GitHub Actions run `31873664396`; PR #38 merged to `main` as `db7926d` on
  2026-08-15. Staging/Production, final Release binary/traffic, and distribution remain blocked.
- [x] Begin C3-04 after explicit owner instruction. C3-03 is closed; C3-04 may address
  billing-retry/expiry soft landing, bilingual copy, VoiceOver, Dynamic Type, appearance testing,
  and review disclosures without deploying Production or relaxing the post-0.9.6 release hold.
- [x] Complete the C3-04 source candidate: one non-blocking Dashboard navigation card and matching
  Pro-screen guidance for verified grace/retry/expired/revoked, exact purchase-state gating,
  bilingual/VoiceOver/AX5 presentation across all three appearances, fixture-free customer trial
  terms, and updated privacy/App Review/Archive disclosure. Keep C3-04 pending independent review
  and green CI; do not mark COM-C3 Done or open Production/distribution.
- [x] Close C3-04 and COM-C3 after independent review, green GitHub Actions run `31918968478`,
  and PR #40 merge `9448ca9`.
- [x] Prepare owner-authorized TestFlight candidate 0.9.7 (8) with matching release notes and
  release gates. Archive/upload only; do not assign testers or submit external testing.
- [x] Record the later owner-authorized 0.9.8 (9) transport upload from merged source. App Store
  Connect accepted delivery `dda1eb09-5d8b-43c6-a2fd-ea910fa422ac` on 2026-08-17; no tester group,
  external Beta review, App Store submission, or Production configuration deployment was done.
- [x] Complete the C4A-01 repository delta audit and execution packet: current V1–V4 amounts are
  already `Int64` minor units, so no destructive amount rewrite is justified; define the missing
  recoverable migration journal/backup boundary, explicit merchant-cache currency ownership,
  sign/anomaly rules, and C4A-03 recovery/currency matrix. Keep it pending independent review.
- [x] Implement the C4A-02 source candidate after C4A-01 passed independent review, green CI,
  and PR #51 merge `bcd56a3`: preserve V1–V4 values and IDs; add only the V5 merchant-currency
  companion, pre-open recovery envelope, exact-target fast path, integrity inventory, closed
  anomaly handling, and Delete All artifact boundary. Independent review and GitHub Actions run
  `32375823770` passed; PR #53 merged the result as `c905415` on 2026-08-20. The owner then
  explicitly started C4A-03's recovery/currency matrix; keep it limited to that active packet.
- [x] Close C4A-03 and COM-C4A after independent review, green GitHub Actions run `32406654986`,
  and PR #55 merge `77292c6`. Keep C4B blocked until its CloudKit architecture is accepted and the
  owner explicitly starts it; do not infer iCloud or distribution authority from this closeout.
- [x] Close C4B-01 after owner acceptance, independent review, green GitHub Actions run
  `32434148439`, and PR #57 merge `90a1e66`: custom private-zone `CKSyncEngine`
  envelopes, default-off/local-first semantics, stable IDs/tombstones/conflict order, explicit
  SwiftData `.none` guard, and permanently excluded attachments/OCR/recovery artifacts.
- [x] Finish C4B-02P prerequisites without runtime CloudKit changes: canonical occurrence identity,
  revision-1/no-parent genesis, accepted-parent ancestry, durable no-winner quarantine handoff,
  exact future container/disclosure inputs, and repository-wide SwiftData construction checks.
  Reviewed head `0fece3a` passed GitHub Actions run `32454490080`; PR #58 merged as `6f5fded`.
- [x] Complete C4B-02 review/CI/merge for the implemented default-off custom-record runtime.
  Reviewed head `0024507` passed GitHub Actions run `32490174014`; PR #59 merged as `211dff2`:
  Schema V6 metadata, explicit SwiftData `.none`, transactional outbox/inbox, all 12 allow-listed
  facts, logical tombstones, no-winner quarantine, account/key-reset pause, Settings consent, and
  local-first failure isolation. C4B-03 still owns entitlement/container provisioning, Dashboard,
  physical multi-device convergence, conflict resolution UI, cloud-wide deletion, and release.
- [x] Close the C4B-02 documentation state after PR #59. Reviewed head `b9944cd` passed GitHub
  Actions run `32494429474`; PR #60 merged it as `7138a9c`, satisfying formal C4B-03 entry.
- [x] Complete C4B-03 lifecycle/deletion evidence. Source now includes explicit conflict
  resolution, durable cloud-zone deletion, retained-copy reimport confirmation, sticky trust
  recovery, and exact Development/Production entitlements. Deterministic tests and signed local
  build/archive evidence pass; corrected full local validation passed 456 unit tests, 17 UI tests,
  strict Dashboard performance, Release, and coverage. Exact-head validation then passed 460 unit
  results, 17/17 UI, Release, and coverage with the wall-clock benchmark explicitly skipped. The
  owner-authorized physical Development
  suite passed 33/33 with a real zone create/send/fetch/disable/confirmed-reimport/delete lifecycle
  and local preservation. Read-only Dashboard inspection confirms the exact encrypted Development
  record shape and that Production has no app record type or deployed schema. Physical account/
  quota/offline observations were not passed, and Distribution signing plus Production deployment
  were not performed; DEC-COM-043 gives those gaps their final ownership below. The signed
  two-device harness did not converge because the devices use different iCloud Apple Accounts.
  DEC-COM-039 permanently waives the physical same-account rerun as an exit-evidence item without
  calling the stopped attempt a pass or weakening deterministic conflict/no-winner behavior. A
  subsequent 33/33 cleanup run confirmed the fixed Development zone is empty. PR #61 republishes
  the retained-cloud marker immediately after local
  Delete All, keeps the reimport/cloud-delete UI accurate in the same session, displays closed
  deletion retry reasons, and leaves incomplete cloud conflicts unresolvable. Focused CloudSync/
  Phase 6 passed 52 cases; the final full run passed 461 unit results and 17/17 UI tests. Reviewed
  head `f49de94` passed GitHub Actions run `32571676058`, and PR #61 merged as `0f749ce`.
  Reviewed waiver head `7b23490` passed run `32576885537`, and PR #63 merged as `1a14df9`.
  The next evidence audit found automatic `CKSyncEngine` scheduling disabled; DEC-COM-040 restores
  it after opt-in, and the focused 38-result regression passes with three physical-only skips.
  Exact-head full validation then passed 462 unit results, 17/17 UI, Release, and coverage with
  zero failures. The corrected 38-result Development physical rerun passed with only the two
  permanently waived multi-device roles skipped. Nine physical background-push probe bundles
  contain zero passes. DEC-COM-041 fixes delegate reentrancy and genesis-only zone creation;
  DEC-COM-042 permanently waives only the physical background/silent-push observation and records
  it as not passed.
- [x] Calibrate the C4B-03 product merge without closing the evidence phase: record PR #61,
  `0f749ce`, green run `32571676058`, and the owner's temporary deferral of same-account two-device
  evidence while retaining C4B-03 In Progress and C4C blocked. This records PR #62's then-current
  state and is superseded by DEC-COM-039 below.
- [x] Supersede that temporary boundary after PR #62 (`0128682`, green run `32573992659`): permanently
  waive only the physical same-account two-device evidence gate under DEC-COM-039, retain the
  non-pass history and deterministic conflict contract, and keep every other C4B-03/release gate.
- [x] Record the owner-authorized DEC-COM-042 evidence-scope override: nine inspected physical
  background-push result bundles contain zero passes; permanently waive only that physical
  observation, keep it labeled not passed, retain the optional probe, and preserve every source,
  deterministic, account/offline/quota, distribution, and Production/release gate.
- [x] Close C4B-03 and COM-C4B after reviewed final head `f1f37db`, green Actions run
  `32726507493`, and PR #64 merge `4f6d7fe`. Under DEC-COM-043, record physical account-switch,
  offline, and quota observations as permanently waived non-passes; retain deterministic failure
  coverage; and move Distribution signing plus Production schema/deployment/release proof to
  COM-C6/COM-C12 without authorizing those actions. Unblock C4C-01.
- [x] Complete C4C-01 review/CI/merge for the central local-Pro seams and deterministic rule
  evidence. Preserve the existing 30-day Insights and basic reminder/review experience as Free;
  expose only the new integer sample/confidence line through `advancedLocalInsights`; at that
  decision, keep receipt product scope off. Reviewed head `d203308` passed GitHub
  Actions run `32845307426`, and PR #66 merged it as `8611022`.
- [x] Close C4C-01 documentation through reviewed PR #67 (`bdb94d9`) after green Actions run
  `32850616400`, without entering receipt image work automatically.
- [x] Complete C4C-02 image acquisition/lifecycle review, hosted CI, and merge. Reviewed head
  `43c3a35` passed GitHub Actions run `32860643712`, and PR #68 merged it as `4ca8f1c`. The packet owns
  exact product/Pro/permission/hardware gates, one-image DataScanner/PHPicker adapters, bounded
  orientation/perspective/downsampling, one protected non-backed-up temporary JPEG, and teardown
  on cancellation/background/memory/Delete All. Receipt entry remains disabled; OCR, receipt
  persistence, model/network content, C4C-03, Production, and release actions remain out of scope.
- [x] Complete the C4C-02 documentation closeout. Reviewed head `4ab0daf` passed GitHub Actions run
  `32911659905`, and PR #69 merged it as `3e1c5c9` without entering C4C-03 automatically.
- [x] Complete C4C-03 independent review, hosted CI, and merge after the owner's explicit entry.
  The source candidate runs local Vision OCR only inside one reviewed adapter, forms output only
  after mandatory card-number/last-four/authorization-code removal, preserves deterministic
  normalized geometry/order/confidence, and fails closed on invalid or bounded-input failures.
  Reviewed head `92ed3a7` passed GitHub Actions run `32921913143`, and PR #70 merged it as
  `d294cfb`. `enableReceiptImport` stays false; C4C-04/C4C-05 and every release action remain blocked.
- [x] Complete the C4C-03 documentation closeout through independent review, green hosted CI, and
  merge. PR #71 merged it as `08fb718`; the closeout itself did not enter C4C-04 automatically.
- [x] Complete C4C-04 independent review, green hosted CI, and merge after the owner's explicit
  entry. Reviewed remediation head `f2d249d` passed GitHub Actions run `32946104780`, and PR #72
  merged it as `e6316fa`. Deterministic accepted/rejected fields remain final; the optional
  on-device model may supplement only `.missing`; same-line amount parsing fails closed. At that
  merge, receipt import was disabled; the later explicit C4C-05 entry below supersedes that state.
- [x] Complete the C4C-04 documentation closeout through independent review, green hosted CI, and
  PR #73 merge `2107723`. The closeout records DEC-COM-050 and did not enter C4C-05 automatically.
- [x] Complete C4C-05 review/CI/merge after implementation/evaluation: expose the verified-Pro, local-only receipt
  entry; keep image/OCR/model output ephemeral; apply accepted fields only to the editable expense
  form; retain the existing explicit Save action as the sole persistence boundary; pass the 60+
  fixed receipt/non-receipt, offline-tier, zero-leak, and 20-image matrix. Physical iOS 26.6.1
  DataScanner/PHPicker/OCR evidence and cancel-versus-Save persistence evidence passed on
  2026-08-26. Independent review approved remediation head `8607356` and supplied three
  nonblocking P3 observations. Final maintenance head `81cd107` applied them, passed GitHub Actions
  run `33035427257`, and PR #74 merged the implementation as `d751ff4` without pre-merge rereview;
  PR #75's 2026-08-27 closeout review then confirmed the exact maintenance delta correct.
  The owner-requested capture redesign is included under DEC-COM-053: first-use privacy explanation,
  one-primary-action camera overlay, preview confirmation, form-inline processing/review/failure,
  generation-safe cancellation, and AX/Reduce Motion adaptations. It deliberately uses the A path:
  no live edge/alignment claim, no broad Photos permission, and no unreviewed long-receipt stitching.
  DEC-COM-054 removes the unreachable unconditional prefill seam and makes the production path the
  tested contract: per-field edit flags survive changes back to the original value, failure cards
  retain their typed reason and recovery action, inactive scenes hide without destroying work, and
  temporary cleanup is scoped to the prepared artifact identity. If all accepted fields remain
  user-owned, the eventual explicit Save truthfully keeps manual provenance.
- [x] Complete the C4C-05/COM-C4C documentation closeout through independent review, green hosted
  CI, and PR #75 merge `82ef0fa`. Record DEC-COM-055 and the exact PR #74 evidence without
  relabeling the manual-review-only physical amount as recognized.
- [x] Complete C5-01 independent review, hosted CI, and merge after the owner's explicit COM-C5
  entry. Keep the implementation dormant and default-off: no production construction/capture call,
  URL, receiver, customer setting, or transport. Require the closed event/envelope vocabulary,
  upload-envelope pseudonym non-reuse, explicit grouped-delete association, retained deletion
  proofs, corrupt-state local file/key deletion without a remote claim, encrypted bounded queue,
  serialized mutation, batch/backoff, self-testing fail-closed static scanning, and
  `UnavailableTelemetryTransport`. Record the four-generation re-enable boundary for C5-04 and
  in-flight upload cancellation plus idempotent event/delete retries for C5-02. Repeated Disable on
  missing state must create no file/key/write; lifecycle dates use the user calendar; local commit
  failure cannot masquerade as transport backoff. Do not enter C5-02 or
  authorize telemetry egress, Production, tester assignment, distribution, or release. Local
  focused telemetry tests pass 21/21; exact-source validation passes Release, the strict Dashboard
  benchmark, 538 unit tests across 32 suites, 17/17 UI tests, and every selected coverage gate.
  Exact final head `d937dc8` passed GitHub Actions run `33085630481`, and PR #76 merged it as
  `68304ad`. C5-02 was not entered automatically.
- [x] Complete C5-02 after the owner's explicit 2026-08-28 entry. Implement the exact independent
  dev/staging/production Worker/D1 contract, strict content-free request bytes, idempotent ingest
  and proof deletion, 90-day maximum server TTL, bounded abuse/cost controls, closed monitoring,
  and the smallest dormant iOS adapter. Development alone may be deployed/probed; keep
  `UnavailableTelemetryTransport` as the production client default, add no capture/customer
  control, and do not enter C5-03 or authorize Production/distribution/release. Implementation and
  the Development probe are complete. Review remediation replaces request-unique tombstone expiry
  times with a shared UTC-day bucket, fixes transport metadata, drains cleanup backlog through
  repeated bounded batches, and leaves permanent endpoint-policy failure UX to C5-04 before any
  transport construction. Independent review approved exact head `72abf4b`, hosted run
  `33176551566` passed, and PR #78 merged it as `4715054`. C5-03 was not entered automatically.
- [x] Complete C5-03 metrics and G1 evidence after the owner's explicit 2026-08-29 entry. The
  implementation adds a closed nine-metric aggregate evidence vocabulary, immutable canonical
  JSON builder, exact numerator/denominator/sample/source provenance, outward-rounded 95% Wilson
  intervals, fixed voluntary bilingual survey workflow, exact-segment evidence-completeness plus
  widest-interval reporting, and an ordered read-only D1 receipt funnel. No root/cross-segment
  coverage is emitted. It adds no App capture call, event field, HTTP route,
  deployment, customer collection, or G1 decision. Independent review approved head `4ea7cd9`;
  remediation head `0c61427` closed its P2/P3 findings, passed GitHub Actions run `33211270363`,
  and PR #80 merged it as `a587f42` without a pre-merge rereview. PR #81's post-merge closeout
  review confirmed the exact remediation delta.
- [x] Complete C5-04 after the owner's explicit 2026-08-29 entry. The reviewed product capability
  adds the sole fixed client factory behind bilingual default-off controls, an exhaustive closed
  capture audit, App Privacy manifest entries, bounded lifecycle/retry, sticky terminal
  404/405/421 handling, and proof-authenticated deletion attempted before app-wide financial
  deletion without allowing optional telemetry failure to block the local erase. A distinct
  pending-remote state retains proofs for a separate retry. The package also adds a
  Development-only operations/rollback runbook. Independent review approved the deletion-order
  remediation on exact head `2c1cebe` within its declared scope; hosted run `33233846430` passed,
  and PR #82 merged it as `28d9eae`. The privacy manifest, two feature capture files,
  `TelemetryService`, and operations runbook were outside that review. Independent review of PR
  #83 head `daea2d2` raised two P2 findings and one P3. Remediation head `e6bbd3f` applied them,
  recorded the implementation author's supplemental inspection of those four surfaces, passed
  run `33242024609`, and merged as `becb020` without a pre-merge rereview.
  Development version `003c66fa-a57c-4b6a-a8d7-3f75b14cc716` now carries that exact current source;
  the synthetic sequence proved 202/202/409/204/202/204, exact 90-day event TTL, UTC-day tombstone
  bucketing, non-resurrection, and exact cleanup. PR #84 additionally proves the actual iOS
  `FixedTelemetryTransport`/`URLSession` headers with upload 202 and delete 204, records final D1
  aggregates of 0 events/0 identities/3 tombstones, and tests that explicit deletion remains
  callable after `TelemetryService.stop()`. Independent review approved exact PR #84 head
  `84a96bc`, hosted run `33247176815` passed, and PR #84 merged as `4194b73`; C5-04 and COM-C5 are
  Done. PR #85 merged the preserved C6 privacy-source handoff as `008b674`, and the owner entered
  COM-C6 on 2026-08-29. Staging/Production, G1, App Store Connect, distribution, and release
  remain unauthorized.
- [x] Complete C6-01 independent review, hosted CI, and merge for the closed seven-row automated
  release matrix. The implementation adds strict JSON/self-test validation, all existing static
  gates, both Worker test/typecheck/dry-run checks, Release build, 16 Swift test containers, and a
  cross-domain regression proving optional network failure cannot revoke an injected verified
  local-Pro snapshot. PR #86 remediation additionally requires all 33 declared method bindings to
  appear once as Passed in the exact xcresult and classifies every repository check script. It
  performs no archive, upload, deployment, or App Store Connect write. Independent rereview
  approved exact remediation head `f77d2a6`, hosted run `33255898196` passed, and PR #86 merged as
  `015d00e`. The owner entered C6-02 on 2026-08-30, and C6-03 remains blocked.
- [ ] During C6-02, independently inspect
  `MindBudget/Resources/PrivacyInfo.xcprivacy`, both telemetry capture sites in
  `MindBudget/Features/AddExpense/AddExpenseView.swift` and
  `MindBudget/Features/Commerce/ProSubscriptionView.swift`, the `TelemetryService` wiring in
  `MindBudget/Services/TelemetryClient.swift`, and
  `Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md` before copying or accepting any App
  Store Connect privacy answer. The C5 implementation-author supplemental inspection is not this
  independent review, and C6-01 automation does not satisfy it. The implementation pass corrected
  the missing Purchase History declaration, added exact source/embedded-manifest and signed-app
  checks, and installed/launched a development-signed Release build on an iPhone Air running iOS
  26.6.1. `Docs/Commercialization/C6_02_PREFLIGHT.md` retains the open independent-review and
  manual-device evidence; no archive, upload, deployment, or App Store Connect write occurred.
  Independent review accepted exact PR #88 head `0ac0500`, hosted run `33283398690` passed, and
  PR #88 merged as `6c2a051`. Its required-reason source-inventory P2 is implemented by
  `Scripts/check_required_reason_apis.py` on this follow-up branch. PR #89 review found incomplete
  Swift overlay coverage. Independent rereview accepted exact remediation head `6ffc6fa`, hosted
  run `33287620965` passed, and PR #89 merged it as `72f016e`. The continuation records bilingual
  live StoreKit/renewal/legal presentation, offline verified-local-Pro retention, privacy/receipt/
  iCloud/export copy, and a no-write receipt cancellation. Its physical AX5 run found a persistent-
  tab-bar obstruction; DEC-COM-078 caps only that chrome. PR #90 review found that the first
  regression lacked a content-side guarantee and used an ignored noncanonical content-size value.
  DEC-COM-079 uses canonical AX1/AX5 values, proves Dashboard content grows while chrome remains
  bounded, and gives language/tab/category/appearance changes bounded waits. Focused tests and a
  new full local validation pass. The corrected build was then installed only on
  `拉沙的iPhone`; physical AX5 content plus English/Simplified Chinese light/dark Pro evidence
  passed. Screenshot review found a separate first-push legal-navigation contrast defect that a
  green hierarchy test missed. DEC-COM-081 binds navigation chrome to the Pro skin, and the final
  three-skin Pro/Terms/Privacy run passed 1/1 with all nine retained screenshots manually
  inspected. A later duplicate combined run was stopped by the owner and is not counted as a
  pass. Independent review accepted exact PR #91 head `b3ed24d` with no P1/P2 findings, hosted run
  `33362101536` passed, and PR #91 merged the bounded remediation as `4ddabcd` under DEC-COM-082.
  DEC-COM-083 closes the remaining disposition work without claiming unrun physical checks passed.
  `C6_02_ACCEPTANCE_MATRIX.json` binds 23 exact StoreKit/receipt/accessibility/system methods to a
  fresh full xcresult. Final local revalidation already records those bindings Passed. The owner
  accepted existing C4C-05/PR #91 device continuity and retained full VoiceOver,
  Instruments/exact file protection, and physical notification/Siri/Spotlight/Face ID/share/Delete
  All actions as explicit non-passes for C6-03/C12. A read-only container listing on only
  `拉沙的iPhone` found the protected SwiftData artifacts; `xctrace` reported that permitted phone
  Offline and generated no trace. No financial store was exported. C6-02 now awaits exact-head
  review, hosted CI, and merge; C6-03 remains blocked.
- [ ] Close PR #93's hosted-schema/runtime remediation. Runs `33370429991`, `33384223530`,
  `33391122019`, and `33398172181` are non-passes:
  hosted Xcode 26.6 rejected forced schemas `0.4.0` and `0.3.0`; the latter run also retained one
  unrelated pseudo-long-text failure followed by a retry pass. DEC-COM-085 uses the toolchain-native
  result shape and replaces a lagging active-field value assertion with the bounded Dashboard
  transition. The third run proved that reader works on hosted Xcode 26.6 and correctly rejected a
  real AX1 Save interaction failure followed by a retry pass. DEC-COM-086 uses a bounded
  Save-to-Dashboard interaction handshake and counts concrete `Repetition` attempts without also
  counting their aggregate parent. Reviewed head `c05860f` then exposed two remaining hosted UI
  geometry assumptions: delayed navigation-container bounds and a Save control reported hittable
  while the keyboard still covered it. DEC-COM-087 binds the back-button midpoint to the App window
  and requires the whole Save frame in the keyboard-safe interaction lane. The corrected focused
  regression passes 2/2 without test-runner retry. A fresh complete validator passes Release, the
  strict Dashboard benchmark, all unit tests, all 18 UI tests with 17 passed and one expected
  physical-only skip, coverage, and 23/23 C6-02 bindings without a UI retry. A new remediation head
  still requires rereview, green hosted CI, and merge; do not enter C6-03.
- [ ] Independently review, run hosted CI, and merge the DEC-COM-083 bounded C6-02 acceptance
  packet before marking C6-02 Done. Do not enter C6-03 or authorize Archive/upload automatically.
