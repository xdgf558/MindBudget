# CHANGELOG

## Unreleased

- Added the Schema V7 local-store foundation for future manual foreign-currency expenses.
  Existing records retain their accounting amounts and gain no inferred exchange-rate data.
  No automatic rate or new network path is added.
- Added manual foreign-currency expense entry for the existing Pro access snapshot, with explicit
  currency/rate/date entry, integer conversion and editable locked accounting amounts. Existing
  foreign-currency records remain editable after access ends; detail shows original and accounting
  amounts, rate date/zone and source. Invalid input is retained and cannot reuse a stale preview.
  CSV and the optional iCloud companion protocol remain deferred to FX-01D.

Every user-visible change must be added here when it is implemented. Before each TestFlight or
App Store upload, move the included entries into a dated version/build section and use the same
summary for the corresponding TestFlight “What to Test” or App Store “What's New” notes.

## 0.9.9 (10) — 2026-09-01 — TestFlight transport accepted; not publicly released

### Changed

- Kept the four-tab navigation bar compact at accessibility text sizes so it no longer obscures
  Dashboard or pushed Pro content. Page content still receives the user's full Dynamic Type size.
- Kept the Pro subscription navigation bar and its system back indicator on the selected skin's
  light or dark scheme, including the first Terms or Privacy push at accessibility text sizes.
- Corrected the unreleased App Privacy source declaration so the closed subscription-action
  outcome is conservatively disclosed as Purchase History. Product Interaction, the rotating
  app-scoped pseudonym as Device ID, and Purchase History remain Analytics-only, unlinked, and
  non-tracking; no product, price, transaction, storefront, subscription date, or financial
  content is added to telemetry.
- Added an unreleased, optional first-party product-analytics control in Privacy settings. It is
  default off, requires explicit confirmation, accepts only closed non-content interaction events,
  and can be disabled or deleted without changing budgets, subscriptions, receipt processing, or
  local app use. Financial values, merchant/category/note text, receipt data, StoreKit identifiers,
  CloudKit records, locale, and device/advertising identifiers are excluded.
- Kept local Delete All available when optional product-analytics deletion cannot reach its
  first-party endpoint. Local financial records and preferences are still erased; any authenticated
  remote deletion proof is retained and reported as pending for a separate Privacy-settings retry.
- Added an unreleased Pro receipt workflow to the new-expense form. A user can explicitly choose
  one photo or camera capture, process it entirely on device, review accepted merchant/date/total
  suggestions, and then use the existing Save action. Receipt images and recognized text are not
  stored or synced; missing local AI capability falls back to deterministic local extraction.
- Redesigned that unreleased receipt flow around one clear camera shutter, a local-only badge,
  photo preview, and inline form progress/review/retry states. The form stays usable after a failed
  read, while cancellation and backgrounding prevent a late recognition result from being applied.
- Kept amount, merchant, and date edits authoritative while receipt recognition finishes, added
  reason-specific access/camera/storage guidance, preserved in-progress work behind a privacy cover
  during brief inactive transitions, and prevented old cleanup from deleting a newer receipt image.
- Corrected the unreleased receipt flow for full-resolution iPhone photos and harmless sub-percent
  Vision bounding-box drift. Ordinary paper invoices can now reach review without relaxing image
  limits or guessing an uncertain amount.
- Added a Pro evidence line to locally calculated spending-pattern cards, showing the supporting
  and total sample counts plus an integer confidence ratio. Existing 30-day Insights and basic
  spending reminders remain Free, and no receipt image, OCR, or server processing was added.
- Corrected the unreleased, opted-in iCloud path so Apple's sync engine can respond to its private-
  database subscription and silent background notifications. Explicit foreground Retry remains
  available, and automatic scheduling still cannot bypass consent, local authority, conflict
  quarantine, or sticky recovery pauses.
- Added the unreleased C4B-03 controls for reviewing iCloud conflicts without revealing record
  content, explicitly choosing the local or iCloud candidate, deleting the app's private iCloud
  zone while keeping local facts, confirming reimport after a local-only reset, and rebuilding
  sync only after a trust-boundary warning. Cloud sync remains Free, default off, and unreleased;
  real multi-device and Production deployment gates are not yet satisfied.
- Kept the retained-iCloud-copy warning and cloud-deletion action visible immediately after local
  Delete All, and added reason-specific retry guidance while a separately confirmed cloud deletion
  is waiting for network, account, quota, or service recovery.
- Hardened the unreleased optional iCloud sync path so encrypted-key reset, missing-zone, and
  account-change pauses cannot be reopened by late retry callbacks; invalid allocations and
  divergent recurring claims now quarantine without changing local facts.
- Clarified in Privacy settings that Delete All removes this device's data only and does not yet
  delete retained iCloud copies, which may return after a later re-enable.

- Added an unreleased, Free, default-off iCloud sync control in Settings. After the exact bilingual
  disclosure is accepted, the app can stage only the 12 approved budgeting fact types as encrypted
  private-database custom records while local reads and writes remain authoritative. Turning sync
  off keeps local data and the cloud copy; account changes, encrypted-key reset, malformed data,
  quota, network failure, and unresolved conflicts pause or defer transfer without blocking local
  use. The current C4B-03 source now carries exact Development/Production entitlements and a
  separately confirmed whole-zone deletion flow; Production schema deployment, distribution
  authorization, and the remaining physical lifecycle gates are still absent.
- Budget plans and category limits now reject values above MindBudget's documented safe minor-unit
  maximum consistently at entry and while opening an existing store. Existing invalid records are
  preserved for recovery rather than being silently changed to zero.

## 0.9.8 (9) — 2026-08-17 — Internal TestFlight candidate

### Changed

- Reorganized Settings into labeled groups — Budget, Reminders and Intelligence, Subscription,
  General, Privacy, and About — instead of one unlabeled list of eight unrelated destinations. The
  three pages that together decide the spendable amount now sit in one Budget group with a footer
  explaining the relationship, and every group carries a header so VoiceOver announces it.
- Moved app language out of "Appearance and skins" into its own Settings entry under General, and
  made its picker inline so choosing a language no longer pushes an extra screen.
- Category chart segments now use a palette derived from the selected skin instead of fixed system
  colours, so the chart belongs to the screen it sits on in all three appearances. Neighbouring
  segments alternate warm and cool rather than placing confusable colours side by side; the key
  still repeats every category name, so colour is never the only channel.
- Grouped Insights into named sections — This cycle, Long-term goals, Where money went, and the
  existing patterns list — so the screen reads as a few themes instead of one column of equally
  weighted cards.

## 0.9.7 (8) — 2026-08-16 — Internal TestFlight candidate

### Changed

- Corrected Insights so the point-in-time "budget still has a buffer" result is no longer stored
  or shown later as if it were a current balance; older stored copies are also hidden. The
  category breakdown is now a localized donut chart with a Dynamic Type-aware category key. It
  preserves up to six actual category names and uses a combined remainder only from seven
  categories onward, so every recorded amount in the 30-day total remains represented.
- Added bilingual, non-blocking subscription-status guidance for StoreKit-verified billing grace,
  billing retry, expiry, and revocation. Grace keeps Pro; retry, expiry, and revocation preserve
  local data and Free capabilities while providing Manage Subscription and Recheck actions. The
  Dashboard uses one calm navigation card instead of an automatic modal paywall. Pro plan rows and
  actions now expose explicit VoiceOver labels/hints and reflow at accessibility text sizes across
  all three appearances. Pro warnings use each skin's attention color, and the Pro, subscription-
  terms, and subscription-privacy screens retain the selected appearance during rapid navigation.
  Customer-facing trial terms no longer hardcode the fixture-only seven-day duration and instead
  defer exact length and eligibility to the App Store.
- Added an unreleased, signed first-party presentation configuration path that may show or hide
  only optional explicit Pro value triggers. It cannot hide Settings, Restore Purchases, Manage
  Subscription, or subscription status, and cannot change products, prices, trials, entitlement,
  notifications, cloud features, or release behavior. Requests contain only bounded app/config
  versions; verification, cache, expiry, rollback, persistence, transport, or offline failure uses
  a previously verified nonexpired value and then the conservative built-in default. Only the
  Development service has been deployed for verification; Staging, Production, Archive/upload,
  tester assignment, and distribution remain blocked.
- Active Pro trials now show their StoreKit-verified renewal date in the Dashboard and Pro screen.
  When StoreKit reports a scheduled same-group plan switch, the displayed renewal price follows
  the verified next-renewal product rather than the product carrying the current trial.
  When local notifications are already enabled and Apple supplies a reliable future date, the app
  schedules one generic reminder five calendar days before renewal; otherwise it keeps a quiet
  in-app reminder and never asks for notification permission automatically. Cancellation, trial
  end, refund/revocation, auto-renew off, product changes, or renewal-date changes remove or
  replace the pending request. Notification copy contains no date, price, amount, product, or
  remaining-day count. It says the trial is ending rather than promising that auto-renew remains
  enabled after the app stops running, and the configured seven-day test offer is never lifecycle
  authority.
- Added a voluntary MindBudget Pro screen in Settings and at explicit Pro value triggers. It shows
  only current StoreKit Monthly/Annual prices, exact renewal terms, and the actual introductory
  offer when StoreKit reports that the account is eligible; a promotion's presence or duration is
  never entitlement authority. Cached or unavailable catalog data cannot enable purchase or
  promise a trial, and an unconfirmed subscription state pauses purchase with an explicit recheck
  action. If StoreKit reports an eligible paid introductory offer rather than a free trial, its
  localized price and payment mode are retained but purchase is paused instead of showing
  misleading standard renewal terms; existing subscription access never depends on promotion
  shape. Renewal disclosure follows the app-selected language even when it differs from the
  device language. Purchase, Restore Purchases, and Manage Subscription require an explicit tap
  and use neutral localized outcomes. The provisional test anchors are not final launch prices,
  and this source remains under the post-0.9.6 distribution hold.
- Established the first exact-Free boundaries for capabilities accepted for the future Pro
  subscription, without adding a paywall or purchase flow. Under exact Free, Apple on-device
  wording enhancement is no longer used, 72-hour and custom cooling-off choices are no longer
  offered for new or changed items, advanced Siri wishlist/cooling-off/emotion/pattern actions are
  unavailable, and passive Siri/App Entity providers expose no expense, wishlist, cooling-off,
  merchant, insight, budget-snapshot, or emotion entities. Existing non-24-hour cooling records
  remain readable and unchanged.
- Exact Free continues to provide deterministic Ask/reminder/summary templates, the basic 24-hour
  cooling-off flow, basic Siri expense recording and budget-impact checking, the five-item
  wishlist, current 30-day local Insights, and every established trust/core capability. Passive
  system entity queries return no results without presenting an error; actively invoked advanced
  Siri actions return a neutral localized not-yet-available explanation.

## 0.9.6 (7) — 2026-08-10 — Uploaded internal TestFlight candidate

### Changed

- Budget setup now labels the inputs as Income this month and Expected expenses, removes the
  duplicate manual fixed-expense field, and uses one disposable amount in both setup and Today:
  configured monthly income plus only explicitly allocated extra income, minus the savings goal.
  Expected expenses remains an independent pace reference. Fixed expenses continue to come from
  actual expense entries and confirmed monthly recurring rules. An existing current-cycle fixed
  forecast remains temporarily reserved so upgrading cannot change the available amount, actual
  plans also keep their prior Expected expenses funding base—even when their old income field is
  zero—so the current cycle cannot jump in either direction. A lightweight Schema V3-to-V4
  migration adds companion authority metadata only for new plans; editing a migrated plan keeps
  its legacy authority for the current cycle, while the old base and compatibility value retire on
  the next cycle. New fixed entries are rebalanced across the remaining days instead of being
  charged to today's amount twice.

## 0.9.5 (6) — 2026-08-09 — Uploaded internal TestFlight candidate

### Added

- Added a separate Savings Progress module to Insights with the total target, confirmed saved
  amount, remaining amount, and completion percentage from the cross-cycle savings goal.

### Fixed

- On-device wording enhancement now checks the exact app-selected locale before generation and
  explicitly requires that language in every Foundation Models session. Wrong-language output
  still fails closed to the matching deterministic template, and Debug labels its counters as
  cumulative for the current app run rather than current availability. An unsupported selected
  app language now has its own actionable status instead of being mislabeled as a region problem;
  new capability callers must supply their locale explicitly, and Traditional Chinese locales
  receive a Traditional Chinese instruction instead of a Simplified Chinese instruction.
- Savings progress remains exact at the `Int64` boundary, caps completed goals at 100%, and never
  presents a negative remaining amount when confirmed savings exceed the target.
- Cycle overview no longer labels a positive but sub-one-percent spend as `0%`, and it now
  distinguishes an unavailable budget baseline from a configured cycle with exactly zero spend.
- Ask now tells the user whether a complete local answer was used because enhancement was
  unavailable, timed out, failed validation, or encountered a model error. On-device wording
  keeps the app-owned suggested-action labels instead of asking the model to reproduce internal
  identifiers. Numeric date labels, sub-one-percent facts, and mixed Chinese/English output are
  validated without weakening the existing number, length, or safety rules. Percentage wording
  is now bound to explicit facts on every generated path: Ask permits none, reminders permit only
  their supplied free-budget-impact or category-budget percentages, and summaries permit only the
  dedicated budget-usage value.
  Unrelated zero counts can no longer authorize false `0%` wording.

## 0.9.4 (5) — 2026-08-08 — Internal TestFlight candidate

### Added

- Added an in-app language choice under Settings > Appearance with Follow System, Simplified
  Chinese, and English. SwiftUI, money/date formatting, deterministic Ask/templates, local
  notifications, Spotlight copy, search labels, and exported filenames follow the selected app
  language without changing the iPhone language.
- Added explicit per-income allocation to the current cycle's spending budget and/or the separate
  total savings goal. Recording income by itself still changes neither one, and the two allocations
  can never exceed the income amount.
- Added one cross-cycle total savings goal with an owner-entered starting balance and progress from
  confirmed income allocations, without repurposing the existing per-cycle savings reservation.
- Added confirmed monthly fixed-expense rules from manual expense entry, including future-only
  edit, pause, resume, and delete controls; calendar/time-zone month-end handling; stable occurrence
  identities; duplicate prevention; and one-time catch-up when the app next opens.
- Added SwiftData Schema V3 with independent income-allocation, savings-goal, recurring-rule, and
  occurrence records. Schema V2 income rows migrate with zero allocation rather than an invented
  spending or savings decision.

### Changed

- Current-cycle budget calculations now include only the exact income amount explicitly allocated
  to spending; income allocated to savings remains separate and continues progress across cycles.
- CSV export discloses the two exact income-allocation minor-unit fields, and verified Delete All
  includes every new Schema V3 record. The two allocation columns are appended after the existing
  unified-ledger columns, so saved spreadsheet/import templates should be updated for the extended
  header without shifting earlier column positions. Income-only rows leave expense-only fields
  empty instead of inventing values that do not exist on the income model.
- Replaced all three App Icon appearances with the owner-approved enlarged budget-pace mark. The
  standard, dark, and tinted resources remain opaque, square, and free of a pre-rendered corner
  mask so iOS can apply its own presentation.
- The next internal candidate identifies itself as version `0.9.4`, build `5`; older in-app update
  notes remain available only inside the collapsed history section.

### Fixed

- App-language changes now update the current interface immediately without requiring a relaunch.
- Income allocated to spending now targets the exact saved budget cycle containing its received
  date. Historical income cannot silently change the current cycle or allocate into a missing one.
- Editing a monthly recurring rule into a new month no longer skips that month's first occurrence,
  and each atomic catch-up now saves at most the globally oldest 120 pending occurrences across all
  rules. Larger backlogs continue on later foreground passes instead of failing forever, and
  Settings now explains the remaining work as progress instead of leaving it invisible.
- Skin changes now update the complete interface immediately without waiting for navigation,
  another setting change, or an app relaunch.

## 0.9.2 (4) — 2026-08-08 — Replacement internal TestFlight candidate

### Changed

- Replaced the five-item quick category row plus separate list with one horizontally scrollable
  selector containing all 17 expense categories. Selection remains visible, follows programmatic
  changes, and exposes the selected trait to VoiceOver.

### Fixed

- Anchored each day's reference amount before today's flexible expenses, then subtracts each saved
  expense one for one. The Today value never displays below zero; reaching zero uses a red amount
  plus explicit localized text even when no spending occurred today, and exceeding the reference
  amount shows the exact overage.
- Localized the Log filter's record-type and budget-type values in English and Simplified Chinese,
  replacing internal catalog keys that could otherwise appear in development and TestFlight builds.

## 0.9.2 (3) — 2026-08-08 — Internal TestFlight candidate

### Added

- Exact per-entry income history with localized categories, optional source and note, edit,
  search, filter, delete, and unified expense/income CSV export. Income history remains
  independent from the budget the user explicitly configured.
- A true rolling 30-calendar-day Insights view with recent total/count, category and emotion
  breakdowns, and a 30-point daily trend calculated entirely on device.
- A free-tier limit of five open wishlist items, enforced atomically for app, Siri, and state
  transition writes while completed, skipped, and archived history remains available.
- SwiftData Schema V2 and a lightweight V1-to-V2 migration that adds income records without
  discarding existing expenses, budgets, wishes, or cooling-off history.

### Changed

- The center Add action now asks whether the user is recording an expense or income, and Log
  presents both kinds of entries in one chronological ledger.
- CSV export and Delete All now include income records, with the same exact minor-unit,
  raw-note disclosure, and spreadsheet-formula protections used for expenses.
- The next internal candidate identifies itself as version `0.9.2`, build `3`; older in-app
  release notes remain available only inside the collapsed history section.

### Fixed

- Made the Today empty-state “Add entry” action open the same expense-or-income chooser as the
  center Add button, instead of silently assuming an expense.
- Kept income rows visible when switching from an expense-only category or budget-bucket filter
  into Income, while preserving those expense filters for a later return to Expenses.
- Refreshed Insights whenever it is opened or a saved entry changes, rejected stale asynchronous
  results, and kept authoritative expense totals visible when optional cooling-off or derived
  insight refreshes fail.
- Kept monthly income and spending budget independent during initial setup, so editing income no
  longer fills or overwrites the amount the user explicitly plans to spend.
- Kept authoritative expense summaries visible when cooling-off data is unreadable while
  withholding cycle narratives, AI enhancement, pattern writes, and stale insight cards that
  would otherwise treat unknown outcome facts as zero.

## 0.9.1 (2) — 2026-08-07 — Internal TestFlight candidate

### Added

- Three included, persistent visual skins—Aurora Glow, Warm Botanical, and Neon Pulse—with a
  dedicated Appearance and Skins settings page and shared semantic theme tokens across the app.
- Distinct full-screen artwork for every included skin: Aurora Glow now carries an aurora, stars,
  and glass-like waves; Warm Botanical carries paper texture, foliage, and natural shadows; Neon
  Pulse carries purple/cyan light trails, a fading grid, and particles.
- A localized in-app release-note section under Settings > About, tied to the installed marketing
  version rather than hardcoded display copy.
- A brief localized cold-launch brand animation using the selected skin, with a fade-only path
  when Reduce Motion is enabled.
- An optional Face ID app lock under Privacy controls. Enabling or disabling it requires owner
  authentication; once enabled, launch and background return are protected and failed or
  cancelled authentication never reveals financial content.

### Changed

- Simplified Chinese user-facing copy now consistently names the product `花有数`; English keeps
  the release name `MindBudget`, while technical identifiers and storage paths remain unchanged.
- The next internal candidate now identifies itself as version `0.9.1`, build `2`; public release
  version `1.0.0` remains reserved.

### Fixed

- Kept Ask answers in the selected English or Simplified Chinese interface language by rejecting
  mismatched on-device wording and using the complete localized template, and replaced visible
  raw action keys with their localized names.
- Restored editable current-period budget amounts in Settings. Saving now updates the existing
  cycle atomically without creating an overlapping plan, while currency stays locked and a new
  cycle start day applies only after the current period.
- Rebalanced the Today amount after every entry from the remaining flexible budget and remaining
  calendar days, instead of subtracting today's entries a second time. Budget settings now show
  the exact flexible allocation and explain zero, fully allocated, or overcommitted plans.
- Expanded the remaining-budget Ask template with total remaining, pending fixed/savings
  reservations, and currently available money, and made the UI label template versus on-device
  enhanced answers explicitly.
- Kept only the installed version's update notes expanded in About; older version notes now move
  automatically into a collapsed history section.

## 0.9.0 (1) — 2026-08-07 — TestFlight candidate

### Added

- Language-specific release names: `花有数` for Simplified Chinese and `MindBudget` for English,
  plus the `温和的预算与消费复盘工具` Simplified Chinese App Store subtitle.
- An explicit, confirmed repair flow for unreadable cooling-off records that shows the affected
  count, revalidates every selected row at deletion time, and leaves readable records untouched.
- Phase 10 release gates for bilingual catalog parity, AX5 and pseudo-long UI navigation,
  deterministic 10,000-expense Dashboard performance, and per-file core-service coverage.
- Production-ready opaque 1024px standard, dark, and tinted App Icon variants using the approved
  budget-track mark, plus TestFlight version 0.9.0/build 1 configuration, App Store metadata drafts, and a
  release checklist for signing, privacy, accessibility, and TestFlight.
- A documented App Icon SVG export map and checksum gate that binds each editable source to its
  reviewed asset-catalog PNG.
- A handoff-driven warm-paper design system with semantic light/dark colors, rounded cards,
  wrapping context chips, consistent buttons, and redesigned free V1 screens.
- A deterministic Today pace projection from `BudgetEngine`, including today's discretionary
  spend, remaining daily allowance, and ahead/on-pace status without view-layer money math.
- A locale-aware app keypad for manual expense entry and a focused full-screen purchase-pause
  experience that preserves the existing safe action contract.
- Phase 0 SwiftUI app shell targeting iOS 17.0 with Swift 6 strict concurrency.
- Shared build/test scheme, unit-test target, and UI-test target.
- Feature flags, string catalog, privacy manifest, and persistent agent memory.
- Asset catalog scaffold with an accent color and App Icon slot.
- GitHub Actions validation and reusable local validation scripts.
- Proprietary public-repository license notice.
- English and Simplified Chinese rendered-localization smoke coverage.
- Versioned SwiftData schema with expense, budget, wishlist, insight, merchant,
  reflection, cooling-off, category-budget, and reminder-event models.
- Exact minor-unit `Money`, typed domain enums, and Sendable data projections.
- Actor-isolated local persistence, validated settings/configuration codecs, and
  deterministic new-user, three-month, end-of-cycle, and overspent sample data.
- State-machine enforcement for wishlist transitions and persistence tests for
  restart durability, cascade deletion, and weak purchase links.
- Pure budget snapshot and purchase-impact calculations with checked minor-unit
  arithmetic, category risk, and explicit unconfigured behavior.
- Calendar-injected budget cycles with month-end/DST handling, contiguous lazy future-
  plan generation, and immutable historical boundaries.
- Locale-aware currency formatting for supported fractional and zero-exponent currencies.
- Localized onboarding and budget setup with accounting-currency confirmation, custom
  cycle start day, and explicit transition/first-regular budget confirmation.
- Five-tab iPhone shell, value-driven Dashboard cards, reusable money/empty/error views,
  and honest Insights/Wishlist placeholders.
- Ten-second manual expense entry with selected-date inline impact, category recency,
  merchant suggestions, soft amount reasonableness checks, and keyboard completion.
- Searchable and filterable expense history with detail, edit, swipe delete, and confirmed
  destructive deletion flows.
- Phase 3 unit coverage plus English, Simplified Chinese, and end-to-end onboarding/manual-
  expense UI tests.
- Collapsed optional purchase-reason and emotion pickers with approved non-diagnostic copy.
- Wishlist create, edit, detail, archive, delete, reactivate, purchased, and skipped flows,
  including a direct alternative from manual expense entry.
- Local 24-hour, 72-hour, and custom cooling-off countdowns with pending Dashboard cards,
  DST coverage, review transitions, and repeat rounds.
- Deterministic wishlist budget-impact previews and atomic wishlist-to-expense conversion.
- Phase 4 actor, localization, budget-preview, DST, rollback, and end-to-end wishlist UI
  coverage.
- Deterministic Phase 5 rules for large purchases, late-hour/stress/image/impulse patterns,
  category risk, cooling-off outcomes, and adequate budget buffers.
- Setting-aware reminder frequency control with scoped cooldowns, category re-crossing,
  response adaptation, daily caps, quiet-hour deferral, and actual-presentation event history.
- Localized soft/direct/minimal template reminders with one highest-priority purchase sheet,
  Continue Purchase as the primary action, and Wishlist as an alternative.
- A local Insights dashboard with seven-day and cycle summaries, category/emotion/trend
  charts, typed dismissible cards, and a fixed informational disclaimer.
- Phase 5 rule, throttle, reminder fallback, persistence, localization, and Insights UI
  coverage.
- Explicit-permission cooling-off notifications with one stable plan identifier, local
  delivery history, precise lifecycle cancellation, and cross-midnight quiet-hour replanning.
- Local notification settings with authorization status, denial guidance, and localized
  English/Simplified Chinese lock-screen copy that excludes amounts and notes.
- An in-memory ShareLink expense CSV with UTF-8 BOM, exact major/minor-unit fields, UTC
  timestamps, RFC 4180 escaping, raw-note disclosure, and spreadsheet-formula safety.
- A two-confirmation Delete All flow with visible notification, Core Spotlight, SwiftData,
  and preference stages; failures stop at and name the incomplete stage.
- Phase 6 notification, CSV, nine-entity deletion, failure-path, localization, and Settings
  reachability coverage.
- A local Dashboard Ask surface with seven deterministic English/Simplified Chinese intents,
  structured affordability details, explicit clarification/refusal paths, and no stored
  conversation history.
- Optional on-device Foundation Models wording for Ask, purchase reminders, and cycle
  summaries behind a centralized default-off capability and availability gate.
- Allow-listed aggregate redaction, constrained generated outputs, numeric/action/language
  safety validation, short timeouts, and complete template fallback for every AI path.
- Settings status that explains Apple Intelligence availability while confirming that all
  template features remain usable.
- Nine localized iOS 17 App Intents, seven privacy-redacted App Entities, and six suggested
  App Shortcuts for expense capture, budget impact, wishlist/cooling-off, patterns, and
  app-owned navigation.
- A centralized default-off Siri/Spotlight capability boundary, exact App Intent amount
  transport, sanitized external strings, and atomic five-second expense deduplication.
- One redacted Core Spotlight domain with budget-relative expense bands, independent
  merchant-name consent, deep links, awaited clearing, and nonblocking failure handling.
- iOS 26 typed Spotlight associations for all seven amount-free `IndexedEntity` projections,
  without creating a second index or changing merchant consent.
- Default-off onscreen entity context for configured Dashboard, expense detail, and wishlist
  detail through a centralized Siri/API/runtime gate and non-searchable `NSUserActivity`.
- Identity-only `Transferable` references for the three onscreen entity types, with no name,
  date, category, amount band, exact amount, or note in the exported representation.
- Intent-scoped local retrieval for Ask that selects only authoritative SwiftData projections
  and never treats Spotlight text as a Foundation Models fact source.
- A typed, gated cooling-notification entity reference and an explicit public-SDK stub for
  Xcode 26.6, which has no compile-time notification entity-annotation property.

### Changed

- Split Settings into a short first-level directory and focused second-level pages for budget,
  reminders and notifications, Apple Intelligence, integrations, export, privacy, and About.
- Reset account, team, and agreement checklist items for every Archive/upload while preserving
  dated development observations as non-authoritative preflight evidence.
- Removed the redundant budget-setup keyboard Done control; the bottom Save Budget button now
  dismisses input focus and remains the only action that validates and commits the draft.
- Kept Apple Developer Team selection out of the shared project and documented that Archive and
  upload must use the owner's latest China-region account after revalidating the final identity.
- Replaced the former five-slot tab semantics with four real destinations—Today, Log, Insights,
  and Wishlist—plus a separate center add action; Settings now opens from Today.
- Grouped the Log by local calendar day and restyled Today, Insights, Wishlist, Ask, Settings,
  onboarding, budget setup, and expense flows without changing their data/privacy boundaries.
- Reserved future commerce composition seams without showing or implementing StoreKit,
  entitlements, quotas, locks, trial copy, paywalls, paid rules, or a purchase entry.
- Made onscreen activity withdrawal explicit through a nil SwiftUI activity element when any
  capability or user-consent gate closes, instead of depending on conditional modifier removal.
- Renamed the former Phase 8B iOS 26 enhancement to Phase 9 per the product owner's sequence;
  release polish, accessibility, repair, and TestFlight readiness move to Phase 10.
- Split Siri spoken-result disclosure from Spotlight/merchant privacy copy so large
  accessibility sizes do not render four independent claims as one paragraph.
- Limited V1 device support to iPhone.
- Moved the bundle identifier prefix into an overridable xcconfig.
- Replaced constant-only smoke assertions with bundle localization checks.
- Clarified that capability FeatureFlags do not enable default-off user features.
- Aligned hosted CI with Xcode 26.6+, made simulator selection dynamic, and pinned
  the checkout action to its reviewed commit.
- Replaced duplicate build/test work with build-for-testing/test-without-building.
- Added one hosted-only retry for a confirmed cold-simulator UI launch timeout.
- Replaced persisted fractional thresholds with integer basis points so financial
  state remains free of binary floating-point values.
- Made expense saving independent from best-effort reminder event creation and response
  logging, so an advisory-history failure cannot discard user-entered financial data.
- Centralized late-night/safe-buffer and throttle policy constants, separated the image
  analysis floor from the large-purchase floor, and made missing day bounds fail closed.
- Rejected overflowing historical aggregate builds instead of silently omitting a cycle and
  biasing the image-related baseline.
- Replaced the purchasing-power-sensitive one-million-major-unit cap with a
  currency-neutral minor-unit safety limit.
- Defined future cycle-start changes as independently confirmed transition and first-
  regular intervals, without rewriting history or silently copying either interval's
  budget into the other.
- Replaced parallel optional snapshot metrics with configured/unconfigured states and
  limited free-budget ratios to discretionary spending with a positive baseline.
- Expanded expense projections and actor APIs so edit screens preserve metadata and
  rebuild merchant aggregates atomically.
- Replaced the bootstrap screen with a projection-based app session that refreshes after
  successful writes and foreground activation without allowing view-layer SwiftData writes.
- Split interactive budget-coverage preview from persistent lazy generation and represented
  every expense-form budget state explicitly.
- Replaced raw-note-bearing expense summaries with targeted detail reads and actor-contained
  note search.
- Kept wishlist notes out of common summaries and exposed them only through targeted local
  detail reads.
- Separated cooling-period completion from later outcome-recording time and documented the
  intentional expense/wishlist projection asymmetry used by future aggregate analysis.
- Separated factual insight detection from reminder presentation settings and retained
  dismissed state across deterministic insight upserts.

### Fixed

- Localized runtime reminder-tone and Apple Intelligence status values explicitly, so Simplified
  Chinese Settings no longer exposes catalog keys such as `settings.reminders.tone.soft`.
- Removed the decorative hairline that crossed behind the raised center Add Expense control in
  the custom bottom navigation; the navigation surface color still separates it from content.
- Kept the Today `Add Expense` and Wishlist `Add Item` empty-state actions on one line with
  stable horizontal breathing room instead of allowing compact container proposals to collapse
  them into near-square controls.
- Made the missing budget keyboard completion-toolbar regression language-neutral and exercised
  it in both English and Simplified Chinese UI flows.
- Prevented the custom bottom navigation's transparent center gap from expanding to full-screen
  height while Today loads, and added bottom-position assertions for normal and AX5 layouts.
- Declared the custom navigation's VoiceOver traversal as Today, Log, Add Expense, Insights,
  and Wishlist, and derived each tab's announced position and total from `AppTab.allCases`.
- Restored selected and position announcements, adaptive large-text layout, and in-bounds hit
  testing for the custom navigation; exposed Today pace values to VoiceOver and renamed the
  daily allowance UI identifier so it cannot be confused with cycle-wide availability.
- Restored the Settings budget-section title while keeping the redesigned first tab labeled
  Today, and added the final-cycle-day pace boundary test.
- Preserved distinct App Intent responses for invalid amounts, unsupported decimal precision,
  out-of-range amounts, unsupported currencies, accounting-currency mismatch, and unexpected
  execution failures.
- Added production-path reconciliation coverage for the complete Spotlight merchant-name
  capability, global-consent, and eligible-expense conjunction.
- Prevented a reduced transition-cycle budget from becoming the recurring amount for
  subsequent complete cycles.
- Expanded the floating-point money guard to the complete app source tree while
  retaining the single documented App Intents transport exception.
- Made iOS deployment and bundle identifier validation target-specific and strict.
- Made local validation compatible with macOS Bash 3.2 when hosted-only test retry
  arguments are disabled.
- Prevented corrupt persisted currency and enum values from crashing or silently
  changing business meaning during projection.
- Reused one `DataActor` per controller, made sample replacement rollback-safe, and
  maintained merchant aggregates from expense creates and deletes.
- Replaced the local-store startup crash with a retryable, localized recovery screen.
- Rejected current-budget snapshots outside their half-open cycle and capped atomic lazy
  plan generation at 120 periods.
- Rejected malformed localized grouping and fractional minor units instead of silently
  reinterpreting or rounding manually entered amounts.
- Made transition and first-regular budget confirmation a single atomic persistence
  operation, with an explicit recovery path if only a transition plan exists.
- Prevented DatePicker previews and cancelled expense forms from persisting future budget
  plans, and skipped no-op model-context saves for already covered dates.
- Removed the UI-test reset launch path from Release builds and preserved actionable expense
  errors for currency mismatch, corrupt data, excessive future dates, and extra precision.
- Cached locale grouping rules instead of constructing a number formatter for every grouped
  amount keystroke, and refreshed edited details with one targeted actor fetch.
- Preserved typed wishlist action failures, fixed cooling-off preview and persistence to one
  start instant, and made countdown copy follow the active SwiftUI locale.
- Verified all nine model counts are empty before Delete All resets preferences or reports
  completion, and kept an unverifiable deletion in the failed data stage.
- Isolated invalid cooling-off records during notification reconciliation so valid requests
  still update, stale identifiers clear, and Settings shows a localized integrity warning.
- Preserved the last confirmed notification-data integrity warning when a later scheduling
  operation fails, so operation and stored-data failures can remain visible together.
- Made CSV UTF-8 conversion total and deletion confirmation follow the active SwiftUI locale.
- Kept the raw Ask question inside the local classifier, rejected unknown and out-of-scope
  questions before generation, and prevented failed or unsafe model wording from changing
  deterministic budget conclusions.

### Privacy

- Documented and disclosed that only an authenticated, explicitly invoked Siri budget-impact
  answer may speak its exact calculated flexible budget; notifications, entity displays, and
  Spotlight content remain exact-amount-free.
- Declared no tracking, no tracking domains, and no collected data types.
- Declared the required-reason UserDefaults API category for app settings.
- Kept raw expense notes out of common engine/list projections and reserved `ExpenseDetail`
  for explicitly requested local detail/edit flows.
- Kept raw wishlist notes out of common projections and reserved `WishItemDetail` for one
  explicitly requested local detail/edit flow.
- Kept raw cooling-off timestamps out of future generated contexts; only deterministic
  aggregate outcome counts may cross that boundary.
- Kept cooling-off amounts and notes structurally outside notification payload inputs, while
  disclosing that the user-entered wishlist name can appear on the lock screen.
- Generated explicit expense exports in memory without retaining a second CSV in the app
  container, and disclosed that raw expense notes enter only the user-invoked export.
- Made full deletion wait for app-owned search-index removal and withhold the success state
  after any incomplete cross-system stage.
- Structurally excluded raw notes, detail projections, transaction rows, merchant lists,
  raw cooling-off timestamps, and raw Ask text from every generator API.
- Replaced the open Ask fact dictionary with exhaustive per-intent typed facts and typed
  insight identifiers, keeping fallback prose and arbitrary caller strings outside prompts.
