# CHANGELOG

## Unreleased

### Added

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
