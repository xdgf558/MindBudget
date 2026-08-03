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

## Later scope

Foundation Models wording enhancement, IndexedEntity, and onscreen awareness.

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
  shorter transition returns an explicit confirmation state; the user chooses that
  interval's budget before persistence, then automatic generation resumes the new cadence.
- Fixed expenses are forecast reservations; pending fixed values prevent double counting.
- Overcommitted budget plans are valid input; Phase 2 clamps free budget to zero while
  preserving negative availability for an honest UI state.
- `SpendingInsight` stores localization keys and payload, not rendered text.
- User preferences use `@AppStorage`, not a singleton `@Model`.
- Reminder throttling records scope, threshold crossings, and deferred notification times.
- Merchant rows aggregate all local expenses. Merchant-name Spotlight indexing also
  requires the global merchant-name opt-in and at least one eligible matching expense.
- FeatureFlags are product-scope gates, not proof of implementation or user opt-in.
  Phase 7/8 must expose centralized gates combining scope, API/runtime availability,
  and an explicit user setting that defaults off; call sites cannot read raw flags.
- V1 targets iPhone only. iPad support requires a later explicit product decision.
- The public repository is review-visible but proprietary; no open-source rights are granted.

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

Phases 0 through 2 are complete. The app opens a versioned persistent SwiftData store
containing all nine V1 model types, with actor-isolated writes and Sendable projections.
The pure `BudgetEngine` exposes an unconfigured/configured enum so configured metrics are
nonoptional, validates that current-budget reference dates remain inside the half-open
cycle, and calculates reservations, safe daily spend, purchase impact, and category risk
using checked `Int64` and `Decimal` arithmetic. Free-budget ratios exist only for
discretionary spending with a real positive baseline. Calendar-injected cycle calculation
covers custom start days, month-end clamping, leap years, DST, immutable history, explicit
transition-budget confirmation, and atomic lazy generation capped at 120 plans. Stateless
currency formatting respects each supported exponent. Phase 3 UI has not started.
