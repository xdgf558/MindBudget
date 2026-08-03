# CHANGELOG

## Unreleased

### Added

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

### Changed

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

### Fixed

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

### Privacy

- Declared no tracking, no tracking domains, and no collected data types.
- Declared the required-reason UserDefaults API category for app settings.
- Kept raw expense notes out of common engine/list projections and reserved `ExpenseDetail`
  for explicitly requested local detail/edit flows.
- Kept raw wishlist notes out of common projections and reserved `WishItemDetail` for one
  explicitly requested local detail/edit flow.
