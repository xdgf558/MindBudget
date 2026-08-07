# PROJECT_MEMORY

## Product

MindBudget V1 is an iPhone-only, local-first budgeting coach. Its core purpose is to
help people record spending, understand current budget pressure, notice possible
spending patterns, and consider calm alternatives before a regretted purchase.

## Core user value

1. Track an amount and category in about ten seconds.
2. Understand pressure inside the current budget cycle.
3. Notice possible stress, impulse, social, or image-related spending patterns.
4. Choose a wishlist or cooling-off option before a large purchase.
5. Ask questions in-app or through Siri without exposing financial data to a remote service.

## What MindBudget is not

It is not a full accounting system, mental-health tool, financial adviser, or social app.

## Version tiers

- L0 core (iOS 17+): tracking, deterministic budget/rule engines, template reminders, deterministic Ask classification and template answers.
- L1 integration (iOS 17+): App Intents, Entities, Shortcuts, and Spotlight, controlled by the user.
- L2 intelligence (iOS 26+): Foundation Models wording enhancements, IndexedEntity, and onscreen awareness; all degrade to L0/L1.

## MVP scope

SwiftUI, SwiftData, manual expense tracking, fixed/discretionary/savings budget
buckets, emotion tags, wishlist, cooling-off plans, deterministic insights,
throttled template reminders, local notifications, CSV export, deterministic Ask,
App Intents, and Spotlight.

## Current and later scope

Phase 10's source-level release polish, accessibility/performance automation, TestFlight
documentation, and explicit repair flow for unreadable or orphaned cooling-off rows are complete.
Signed-device, production-signing, Instruments, App Store Connect, screenshot, and upload checks
remain manual release gates, so the phase is still In Progress. Commercialization is a separate
later phase; the current app contains no StoreKit product, entitlement, quota, lock, paywall,
trial, or visible paid-feature placeholder.

## Forbidden

Bank APIs, cloud sync, third-party AI, ads, third-party analytics, investment
advice, psychological diagnosis, shame language, private APIs, and reading another
app's private data are forbidden in V1.

## Key decisions already made

- Money is stored as `Int64` minor units; only the isolated App Intents transport adapter may receive `Double`.
- The per-entry hard limit is currency-neutral (`Int64.max / 1_000_000` minor units);
  UI reasonableness warnings must not encode exchange-rate assumptions.
- Persisted percentage thresholds use integer basis points; pure calculations keep
  ratios in `Decimal` until a presentation-only conversion is explicitly required.
- A populated V1 store has one locked accounting currency.
- A budget cycle is `[cycleStart, cycleEnd)` and may differ from a calendar month.
- Existing cycle boundaries are immutable. A changed future start day that requires a
  shorter transition returns an explicit confirmation state. The shortened interval and
  the first complete interval on the new cadence have independent user-confirmed budgets;
  automatic copying resumes only after the complete interval is saved.
- Fixed expenses are forecast reservations; pending fixed values prevent double counting.
- Overcommitted budget plans are valid input; Phase 2 clamps free budget to zero while
  preserving negative availability for an honest UI state.
- `SpendingInsight` stores localization keys and payload, not rendered text.
- User preferences use `@AppStorage`, not a singleton `@Model`.
- Reminder throttling records scope, threshold crossings, and deferred notification times.
- Notification reconciliation never prompts implicitly. Cooling-off requests use stable
  plan identifiers, contain no amount or notes, and are replanned through calendar-derived
  quiet hours only after explicit user consent. A corrupt plan is isolated so valid
  reminders still reconcile, while Settings surfaces the incomplete-data state. A later
  operation failure preserves that last-known warning until a successful reconciliation
  recomputes it. Corrupt rows are never auto-deleted; Settings provides a confirmed repair action
  that passes only the displayed identifiers and revalidates each row before deletion.
- V1 CSV is an explicit expense-ledger export from in-memory transfer data, with UTF-8 BOM,
  exact major/minor units, UTC dates, disclosed raw notes, and spreadsheet-formula safety.
- Delete All is a staged, two-confirmation workflow: notifications, awaited app index
  clearing, all SwiftData entities, verified all-zero model counts, preference reset, then
  onboarding. Any failed or unverifiable stage stops the sequence and remains visible.
- Merchant rows aggregate all local expenses. Merchant-name Spotlight indexing also
  requires the global merchant-name opt-in and at least one eligible matching expense.
- FeatureFlags are product-scope gates, not proof of implementation or user opt-in.
  Phase 7/8 must expose centralized gates combining scope, API/runtime availability,
  and an explicit user setting that defaults off; call sites cannot read raw flags.
- An authenticated, explicitly invoked Siri budget-impact check may return the exact
  calculated flexible budget. Unsolicited notifications, entity displays, and Spotlight
  content never expose exact amounts; Settings warns that the active result may be spoken.
- V1 targets iPhone only. iPad support requires a later explicit product decision.
- The public repository is review-visible but proprietary; no open-source rights are granted.
- The shared project never commits an Apple Developer Team ID. Release signing and upload must
  use the owner's latest China-region team, with the final Bundle ID, distribution identity,
  provisioning profile, agreements, and App Store Connect app reverified before every upload.

## Local development environment

- Xcode: 26.6 (build 17F109)
- Minimum deployment target: iOS 17.0
- Swift language mode: Swift 6 with complete strict concurrency checking
- Phase 0 validation destination: `platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5`
- GitHub Actions requires Xcode 26.6+ on macOS 26, dynamically creates a simulator
  from the newest compatible iOS 26 runtime, and separately asserts the app target's
  iOS 17.0 deployment setting. Real iOS 17 runtime testing remains manual until a
  reliable hosted or self-hosted runtime is available.

## Current state

Phases 0 through 9 and the pre-Phase-10 UI/UX design interlude are complete. The app opens a
versioned persistent SwiftData store
containing all nine V1 model types, with actor-isolated writes and Sendable projections.
The pure `BudgetEngine` exposes an unconfigured/configured enum so configured metrics are
nonoptional, validates that current-budget reference dates remain inside the half-open
cycle, and calculates reservations, safe daily spend, purchase impact, and category risk
using checked `Int64` and `Decimal` arithmetic. It also derives the Today screen's daily-spend
pace and remaining-today facts without moving financial arithmetic into SwiftUI. Free-budget
ratios exist only for
discretionary spending with a real positive baseline. Calendar-injected cycle calculation
covers custom start days, month-end clamping, leap years, DST, immutable history, explicit
transition and first-regular-budget confirmation, and atomic lazy generation capped at 120
plans. Stateless currency formatting respects each supported exponent. The iPhone UI now
provides localized onboarding and budget setup, a warm-paper card-based Today experience,
four real content tabs plus a separate accessible add action, exact locale-aware manual
expense entry with an app-owned keypad and selected-date impact, recent-category
and merchant suggestions, and searchable/filterable expense list, detail, edit, and delete
flows. Interactive date previews project budget coverage without writes; only Dashboard
lifecycle work and expense save may persist automatic cycle coverage. General expense
summaries exclude raw notes, while targeted details and actor-contained note search support
the UI without widening later AI inputs. Optional purchase-reason and emotion fields stay
collapsed by default and use situation-based, non-diagnostic labels. Wishlist items now
have localized create, edit, detail, archive, delete, purchase, skip, and reactivate flows;
current expense input can move into the wishlist without creating an expense. Cooling-off
periods support 24-hour, 72-hour, and custom elapsed-hour durations, one active plan per
item, lifecycle expiry refresh, DST-safe countdowns, and another round after review. A
wishlist purchase can atomically create a planned expense with `wishlistConversion` source
and its weak link. Cooling completion and later outcome recording use separate timestamps;
outcome timestamps are retained only for deterministic analysis and never for generated
context. Dashboard and wishlist details show pending reviews and deterministic budget
impact. Expense summaries intentionally carry aggregate-safe emotion/reason enums, while
wishlist summaries omit them and targeted `WishItemDetail` supplies them only for local
detail flows. Raw wishlist notes stay confined to that targeted projection. Phase 4 action
errors retain recoverable meanings, and countdown preview/save share one fixed instant while
formatting follows the SwiftUI environment locale. The UI-test reset hook is Debug-only.
Empty/error states and English/Simplified Chinese accessibility coverage are active. Settings
opens from Today, reminders use a focused full-screen pause surface, and every existing free
surface shares semantic light/dark color assets. The supplied paid-screen concepts are recorded
only as future composition seams and render nothing until commercialization is implemented end
to end in its own phase. The custom navigation owns explicit selected/position semantics,
an exhaustive tab-derived position count, the declared traversal Today → Log → Add Expense →
Insights → Wishlist, and adaptive label height, while the Today pace track exposes its spent
percentage and cycle-day position to assistive technology. Moving Settings behind Today's gear is an
accepted discoverability tradeoff with automated Export/Privacy reachability and a Phase 10
signed-device usability check.
Phase 5 adds a pure deterministic detector for large purchases, late-hour patterns,
stress-related repetition, image-related increases, impulse clusters, category risk,
cooling-off outcomes, and adequate budget buffers. Typed localized insights are deduplicated
and dismissible in SwiftData. Presentation is independently throttled by settings, scoped
cooldowns, threshold re-crossing, recent responses, and daily caps; only actually shown
messages create reminder events. Manual expense entry offers one highest-priority sheet at
most, keeps Continue Purchase primary, and supports Wishlist as a calm alternative. The
Insights tab now shows local seven-day/current-cycle summaries, category/emotion/trend
charts, generated pattern cards, dismissal, and a fixed informational disclaimer. Template
copy is the mandatory local path; Phase 5 itself performs no notification scheduling or real
AI model call. Expense persistence remains authoritative over best-effort reminder history:
logging failures skip the advisory surface but never reject a valid expense. Rule and
throttle thresholds are named at their owning layer, unavailable daily calendar bounds
downgrade interruptions, and overflowing historical aggregates produce no biased baseline.
Phase 6 adds explicit-permission local notifications for cooling-off reviews, one persisted
stable request identifier per plan, lifecycle reconciliation, delivered-event history, and
calendar-safe quiet-hour replanning. Notification content names only the wishlist item and
never accepts an amount or note. Settings now exposes authorization state, a System Settings
path after denial, quiet hours, an in-memory ShareLink expense CSV, and clear privacy facts.
CSV uses UTF-8 BOM, exact integer-derived amount fields, UTC timestamps, correct embedded
comma/quote/newline escaping, and formula neutralization; its screen discloses that an
explicit export includes raw expense notes. Delete All requires two confirmations, displays
each notification/index/data/preference stage, stops without a success claim on failure,
and returns to onboarding only after a post-delete query verifies all nine SwiftData types
are gone. Notification reconciliation isolates invalid cooling-off records, clears their
stale identifiers, continues valid requests, and exposes a localized integrity warning with the
affected count. Settings can explicitly repair only those displayed rows after confirmation;
`DataActor` revalidates them at commit time, and a separate notification failure cannot revive a
stale integrity warning.
The existing privacy manifest remains accurate: no tracking, collection, third-party SDKs,
or new required-reason
file API was added. Notification `appEntityIdentifier` remains Phase 8 work behind the future
centralized Siri gate; Phase 6 does not implement indexing ahead of its phase. Phase 7 adds
the local Ask surface with seven deterministic bilingual intents, complete template answers,
and explicit clarification or refusal paths for missing, unknown, and out-of-scope questions.
The raw question exists only in the view and local classifier; it is neither persisted nor
passed to a generator. Reminder wording, Ask answers, and cycle-summary narratives may use
Apple's on-device Foundation Models only through one centralized product-scope + OS/API +
runtime + default-off user-setting gate. Every generator receives a dedicated allow-listed
aggregate context, never detail projections, transaction rows, merchant lists, raw notes,
raw cooling timestamps, or the raw question. Ask facts are an exhaustive per-intent payload
made only from typed money, counts, booleans, and category values; the redactor owns formatting
and enum-key conversion, while fallback prose remains outside model facts. Deterministic Swift
remains authoritative for classification, arithmetic, rules, and allowed actions. Model output uses constrained
generation, a short timeout, length/action/language/number safety validation, and immediate
template fallback; generated copy is not persisted. Settings always explains the current
availability reason and that the complete template experience remains usable without Apple
Intelligence. Phase 8A adds nine localized App Intents, seven redacted App Entities, and six
suggested App Shortcuts on iOS 17+. Siri and Spotlight are independent default-off settings
combined with product-scope, import/OS, and runtime gates at one boundary. Siri strings are
control-character stripped and capped at 40 characters; its amount parameters cross the
single documented floating-point adapter and become exact minor units before domain code.
Identical Siri/Shortcut expense requests within five seconds deduplicate atomically. Candidate
purchase names used for impact checks remain ephemeral. Core Spotlight owns one replaceable
domain containing category/amount-band expense entries, budget status, wishlist/cooling-off
state, typed insights, and emotion labels, but no exact amount or raw note. Merchant names
require both global consent and an eligible expense with the same normalized key; the local
aggregate remains complete regardless. Disabling Spotlight clears the domain, indexing
failures never alter SwiftData, and recognized search identifiers deep-link only to app-owned
destinations. The Xcode 26.6/iOS 26.5 App Schema catalog has no suitable personal-finance,
budget, expense, or wishlist domain, so Phase 8A uses custom intents/entities. Phase 9 makes
all seven redacted entities `IndexedEntity` values and associates them with the existing
amount-free Spotlight documents only on iOS 26+. Ask now selects intent-relevant facts through
`LocalSearchService`; those facts remain authoritative SwiftData projections, while Spotlight
continues to serve navigation rather than model arithmetic. A centralized iOS 26 onscreen gate
combines product scope, conditional App Intents availability, runtime support, and the default-
off Siri setting. Dashboard, expense detail, and wishlist detail publish amount-free
`NSUserActivity.appEntityIdentifier` references. Gate closure or a missing subject passes a nil
SwiftUI activity element, which explicitly stops advertisement. Those three entity types are
`Transferable` through an identity-only version/kind/identifier payload; the representation
cannot carry names, dates, categories, amount bands, exact amounts, or notes. Wishlist and
Insights list pages deliberately publish no entity without an explicit selection because the
installed SDK exposes no public multi-object list annotation API. `NSUserActivityTypes` is not
declared because Handoff/continuation is disabled; signed-device validation must confirm that
same-device Siri context does not require it. Notification requests carry the same gated wishlist reference
to the system adapter, but Xcode 26.6 exposes no public UserNotifications entity property, so
the adapter is an explicit stub and existing iOS 17+ `userInfo` routing remains intact.
App Intent money transport keeps invalid values, out-of-range amounts, unsupported precision,
unsupported currencies, and unexpected execution failures distinct. The authenticated budget-
impact intent returns its exact calculated flexible-budget result only after explicit invocation,
while passive system surfaces remain amount-free. Settings presents separate, scalable Siri-
speech and Spotlight/merchant privacy explanations. A production-path reconciliation test proves
the merchant-name capability, global-consent, and eligible-expense gates together.
