# PROJECT_MEMORY

## Product

MindBudget V1 is an iPhone-only, local-first budgeting coach. Its core purpose is to
help people record spending, understand current budget pressure, notice possible
spending patterns, and consider calm alternatives before a regretted purchase.
The Home Screen and App Store name are localized by system/store language: `花有数` in Simplified
Chinese and `MindBudget` in English, never both in the same app name. The approved Chinese brand
line is `温和的预算与消费复盘工具`.

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

SwiftUI, SwiftData, manual expense and income tracking, fixed/discretionary/savings budget
buckets, emotion tags, wishlist, cooling-off plans, deterministic insights,
throttled template reminders, local notifications, CSV export, deterministic Ask,
App Intents, and Spotlight.

## Current and later scope

Phase 10's source-level release polish, accessibility/performance automation, TestFlight
documentation, and explicit repair flow for unreadable or orphaned cooling-off rows are complete.
Signed-device, production-signing, Instruments, App Store Connect, screenshot, and upload checks
remain manual release gates, so the phase is still In Progress. Commercialization is a separate
COM-C0A through COM-C12 track governed by the owner-approved v1.4 specification and the planning
map in `Docs/COMMERCIALIZATION_TASKS.md`. The public App Store launch is paused until that track's
formal release gates pass. COM-C1 is completed with a pure entitlement domain, immutable central
feature-access evaluator, and accepted existing-entry integration. COM-C2 is complete.
C2-01 and C2-02 are complete. PR #29 passed independent review and green CI, then merged the
runtime catalog/current-entitlement authority as `a45d480` on 2026-08-12. C2-03 passed independent
review and green CI and merged through PR #30 as `3fc72b4` on 2026-08-13; it is Done. C2-04
passed independent review and green CI and merged through PR #31 as `a293762` on 2026-08-13,
closing COM-C2. COM-C3 C3-01 passed independent review and green CI and merged through PR #33 as
`747b628` on 2026-08-14 under the owner's provisional, nonpublic test inputs: US$1.99 Monthly, US$19.99 Annual,
a 7-day StoreKit-eligible trial, and initial HKG/USA/SGP/TWN runtime coverage. These are test
controls rather than final launch economics.
COM-C4A is Done. C4A-01 closed through PR #51 (`bcd56a3`), and C4A-02 closed through PR #53
(`c905415`). Reviewed C4A-03 head `138c240` passed GitHub Actions run `32406654986`; PR #55
merged it as `77292c6`, closing C4A-03 and COM-C4A. C4B-01 is Done: reviewed head `093535f`
passed GitHub Actions run `32434148439`, and PR #57 merged the accepted custom-record/private-zone
`CKSyncEngine` architecture as `90a1e66`. DEC-COM-028 is Accepted. Reviewed C4B-02P head
`0fece3a` passed GitHub Actions run `32454490080`, and PR #58 merged the prerequisites as
`6f5fded`. C4B-02 implementation is complete pending independent review: Schema V6 adds only local
sync metadata, every primary SwiftData configuration is explicitly non-mirrored, and the Free,
default-off private custom-record path has transactional outbox/inbox, 12 allow-listed fact types,
logical tombstones, no-winner quarantine, account/key-reset pauses, and localized Settings consent.
External remote-zone deletion/purge also becomes a sticky pause rather than an automatic zone
recreation/reupload.
No entitlement, provisioned container, Dashboard deployment, verified CloudKit request,
multi-device evidence, cloud-wide deletion, or release authority is claimed; C4B-03 remains blocked.
The C4A audit
found no V1–V4 floating-point amount conversion to perform:
authoritative amounts are already `Int64` minor units. The missing delta is a recoverable migration
backup/journal/integrity boundary plus explicit currency ownership for the rebuildable merchant
aggregate cache. App Store Connect accepted 0.9.8 (9) on 2026-08-17; no tester assignment,
external Beta review, App Store submission, or Production configuration deployment followed.
C4A-02 local owning validation is green: 429 results produced 422 passes, 7 explicit skips, and
0 failures, including 17/17 UI tests, Release, static gates, and coverage; the strict performance
case separately passed 10/10. Review also proved that a V1 expense may legitimately have no
derived Merchant cache row, so inventory validates existing cache rows but never invents one.
Independent review, hosted green CI, and merge are satisfied through PR #53 (`c905415`).
The owner accepted the retry-only C4A-02 recovery UI on 2026-08-20. C4A-03 retained that boundary:
an unrecoverable store without a trusted backup currently requires app-data deletion or reinstall;
any future in-app destructive reset requires a separate Accepted decision with dedicated tests.
A post-merge recheck with final Xcode
26.6 (`17F113`)
executed both CHN/USA probes on final iOS 26.4 and 26.5 runtimes, but StoreKit still returned
`SKInternalErrorDomain Code=3` and empty product sets while `storekitd` reported an Octane
entitlement/development-install handshake failure. The same 16 tests in 2 suites pass on an
iOS 27 beta runtime only as diagnostic evidence; beta-runtime success does not satisfy the final-
runtime entry gate. The accepted final-runtime evidence came from the dedicated scheme on the
physical `拉沙的iPhone` (`iPhone Air`) running final iOS 26.6.1 `23G82`: 5 passed, 0 failed,
0 skipped, with both CHN and USA runtime product probes passing. This opens C2-03 implementation
only. Merged C2-03 adds one StoreKit lifecycle authority, full status mapping, typed
purchase/restore seams, publish-before-finish, and unfinished retry. The authority's single
lifecycle task supervises `Transaction.updates` and `Product.SubscriptionInfo.Status.updates`;
every status signal triggers a fresh full reconciliation instead of creating a second authority or
UI. C3-01 now adds a voluntary bilingual Pro screen reachable only from Settings or an explicit
Pro value trigger. It renders StoreKit-provided prices and fresh introductory-offer eligibility,
and routes explicit purchase, restore, and subscription-management actions through the existing
typed lifecycle seams. The exact 7-day offer belongs only to the local StoreKit fixture and
runtime contract; production validates stable product structure and presents any actual eligible
offer without making paid authority depend on it. C3-01 retains paid/unknown offer price and mode
but pauses purchase unless the eligible offer is a free trial, preventing standard renewal copy
from masking a paid introductory schedule. Unavailable entitlement authority pauses
purchase at the View and actor, offers an explicit recheck, and renewal disclosure follows the
app-selected locale. The dedicated physical-device scheme on final Xcode 26.6 `17F113` and
final iOS 26.6.1 `23G82` passed 9/9 with no skips: HKG/USA/SGP/TWN catalog probes and both
Monthly/Annual transaction-verification flows all executed. It does not create formal App Store
Connect products, final regional
prices, quotas, a Release manual unlock, or distribution permission, and existing TestFlight
users receive no production Pro rights. C3-02 passed independent review and GitHub Actions run
`31803898776`, then merged through PR #34 as `12d9217` on 2026-08-14; it is Done. It projects an active
trial only from a verified current introductory-free-trial transaction plus verified renewal
information, uses Apple's actual renewal date and auto-renew state, and separates the current
trial product from the accepted next-renewal `autoRenewPreference` for live-price disclosure. It reconciles one generic
T−5 calendar reminder or a noninterrupting in-app fallback. It never derives lifecycle from the
configured seven-day test offer, never requests notification permission implicitly, and removes or
replaces the stable request after cancellation, trial end, revocation, product/date change, or
missing authority. Pending notification copy says the trial ends soon and asks the person to
review current status rather than promising renewal after the app stops. C3-02 local evidence passed
the original 68/68 focused run and the 13/13 review-remediation trial suite. The owning full
validation produced 382 results (376 passed, 6 explicit opt-in StoreKit runtime probes skipped,
0 failed), including all 14 UI tests and every selected coverage gate. The physical final-device StoreKit suite passed
9/9 with no skip across HKG/USA/SGP/TWN and both Monthly/Annual trial-lifecycle derivation paths.
C3-03 is Done after both packets passed independent review, green CI, and merge. C3-03A passed
independent review and green GitHub Actions run
`31856271268`, then merged through PR #36 as `1ebb36c` on 2026-08-15. It adds
  only strict Ed25519 document verification, closed schema/version/expiry/size checks, rollback and
  same-version-equivocation rejection, and a signed cache/high-water mark with conservative local
  fallback. C3-03B adds one exact anonymous fixed-host adapter, the embedded public verification key, closed
  non-content reason codes, and one optional Pro-value-trigger presentation consumer. Review
  remediation validates at response completion, clears at signed expiry without waiting for a
  foreground refresh, cancels owned transport work with its caller, and requires actionable exact
  Free rather than unavailable/unverified fail-closed access. Follow-up review makes startup
  refresh structurally owned by SwiftUI, cancels retained scene refresh on lifecycle exit/Session
  destruction, resets canceled startup attempts so recreated SwiftUI tasks can retry, and defines
  a final pre-atomic-write persistence commit point. The
  Development deployment `bf6c5049-a389-4ea7-af0a-e8425b8957e2` passed the real live app path 8/8
  with no skip; the Worker passed 13/13 tests plus typecheck, audit, and Production dry-run. The
  reviewed head `09c382e` passed GitHub Actions run `31873664396`; PR #38 then merged to `main` as
  `db7926d` on 2026-08-15. C3-04 passed independent review and GitHub Actions run `31918968478`,
  then merged through PR #40 as `9448ca9` on 2026-08-16, closing COM-C3. Its one non-blocking
  Dashboard navigation card plus the Pro screen explain verified exceptional
  StoreKit states, with bilingual VoiceOver/AX5 presentation and updated release disclosure. Local
  evidence is 24/24 focused StoreKit-domain tests, a manually inspected 1/1 AX5 three-appearance
  screenshot run, and 413 final validation results with 406 passed, 7 explicit opt-in/runtime skips,
  and 0 failed at `/private/tmp/MindBudget-C304-Full-Final.xcresult`.
  The owner authorized 0.9.7 (8) Archive and transport upload only. Staging/Production, formal
  economics, tester assignment, external testing, and public distribution remain separate gates.
Its review remediation uses fixed whole-second UTC timestamps, rejects duplicate JSON keys,
serializes concurrent high-water acceptance, and requires abstraction-level write readback. A
corrupt high-water record remains fail-closed until the app data container is deleted and the app
is reinstalled; normal Delete All and Offload do not reset this security marker. Exact signed
bytes remain the authority rather than a client canonical-JSON re-encoding, and failure reason-code
  observability is now limited to closed reason codes without payload/signature logging. The
  Worker has no private key, storage, outbound fetch, analytics binding, or app request logs and
  has platform observability disabled. Source-level acceptance of the exact Production adapter is
  not permission to deploy Production, Archive/upload, assign testers, or distribute.
Local C2-03 validation passed 44/44 focused tests, the 31-test
lifecycle suite across 10 iterations (310/310), 342 Swift tests, all 13 UI tests, and every
selected coverage threshold; the isolated strict wall-clock signal passed 10/10. Independent
C2-04 binds those StoreKit facts to a separately verified app bundle/environment. Local
Xcode/Sandbox/TestFlight/Production isolation, full regression, and coverage evidence passed;
independent review and CI accepted that evidence before merge `a293762`. The read-only
COM-C0A specification/repository audit and owner decision gate
are complete. The owner accepted phase-scoped future data channels, parallel/nonblocking Watch
development with post-iPhone-1.0 Watch distribution, the three-stage commercial-economics gate,
and Product IDs `com.xdgf558.mindbudget.pro.monthly` and
`com.xdgf558.mindbudget.pro.annual`. COM-C0B is complete: it added durable commercial
documentation, an empty current Release egress policy, matrices, CI/report controls, and COM-C1
execution packets without product behavior. COM-C1's three packets were independently reviewed
and merged: C1-01 defines the exact
Free/Pro-subscription set, versioned fail-closed representation migration, and the closed premium
feature vocabulary. C1-02 adds one pure access decision boundary, exact-Free app/session injection,
a nonpersistent Debug-only provider, and static gates that reject raw-bit reads, duplicate paid
checks, entitlement-migrator calls, entitlement-bearing service construction, or access-protocol
implementations outside the Commerce authority boundary. The DEBUG and authority parsers prove
their own safe/unsafe classifications before scanning app source. C1-03 routes the accepted
existing Apple on-device AI, non-24-hour cooling-off, and advanced Siri entries through an
immutable Commerce snapshot. Exact Free retains deterministic templates, the basic 24-hour
period, basic Siri expense recording and budget checking, the five-item wishlist, current 30-day
Insights, and all other typed Free-core capabilities. Passive App Entity providers expose no
entities under exact Free without surfacing a system-initiated error; active advanced Siri actions
retain neutral localized rejection. The uploaded 0.9.6 binary remains unchanged, and this
unreleased commercial source is not distributable until purchase presentation and the owning
release gates are complete. C2-01's synthetic Monthly/Annual fixture
is test-bundle-only, activated by a dedicated non-Archive local scheme, and absent from the app
resources/default scheme. There is still no formal product, final customer price/trial,
Release manual unlock, or distribution authorization. C2-02's presentation cache never
grants access; merged C2-03 consumes its raw verified facts through the same
process-local `EntitlementStore`, grants only subscribed/verified grace, publishes authority before
finish, leaves failed acknowledgements unfinished for retry, and treats subscription-status
updates only as signals to re-read the same complete authority. The earlier
simulator mismatch remains useful historical evidence: final Xcode's iOS SDK build is `23F81a`;
the installed iOS 26.5 simulator runtime is `23F77`, and Apple's offered export was the older
`23F73`. None of those failed or beta-only results were used to claim the physical-device entry
pass.
Phase 12 implements an extensible in-app language choice (system, Simplified Chinese, and English),
explicit per-income allocation to current-cycle spending and/or savings, a cross-cycle total
savings goal distinct from the existing per-cycle savings reservation, and deduplicated monthly
recurring fixed-expense rules. Language changes publish immediately without relaunch. A nonzero
spending allocation targets one already-saved cycle containing the income date, while savings stays
cross-cycle. Recurring edits retain the immutable source-occurrence month, and each atomic
reconciliation commits at most the oldest 120 pending occurrences across all rules, reporting
whether later foreground work remains instead of entering a permanent failure loop. Settings
shows that remaining work as a neutral progress notice. Schedule enumeration carries each date
with its stable occurrence key and fails closed after 1,200 scanned months per rule, so duplicate
key work and an unbounded foreground loop are both excluded. Versions `0.9.4 (5)` and `0.9.5 (6)`
have been archived and uploaded through the owner's current team; the latter was accepted by App
Store Connect transport on 2026-08-09. The current source now contains additional Unreleased
budget-setup changes, so any replacement upload must increment the build number before Archive
rather than reuse build 6.
Cycle-summary budget usage is a closed unavailable/under-one-percent/exact-whole-percent fact;
positive recorded spending can no longer be described as zero percent merely because integer
presentation truncates it. Ask model generation owns wording only: the app attaches deterministic
allow-listed actions after validating their redacted-context contract, retains strict
text/number/language validation, and presents the safe fallback category when a complete local
template is used. Sub-one-percent summary state contributes no numeric `1` token, numeric
component hyphens are not interpreted as unary negative signs, and Chinese proposals cannot be
predominantly Latin text. Numeric percentages are bound to explicit percentage facts instead of
each path's flat numeric set: Ask permits none, reminders permit only their supplied free-budget
impact and category-budget percentages, and summaries permit only their budget-usage value. An
unrelated zero count cannot authorize a false `0%` claim, including when the percent sign precedes
the number.
Insights presents the cross-cycle savings goal as a separate progress module using the authoritative
goal projection: total target, confirmed saved total, remaining amount, and integer completion
percentage. This never reinterprets a cycle reservation or performs money arithmetic in SwiftUI.
Foundation Models availability is checked against the app-selected locale before every Ask,
reminder, or cycle-summary attempt. Model instructions name that exact locale and require the
matching output language; the existing language validator and localized template remain the final
fail-closed boundary if a proposal still drifts. The locale is a required capability input rather
than a `Locale.current` default, unsupported app language is distinct from unsupported region, and
Chinese session instructions preserve the selected Hans/Hant script where present. Savings
completion uses overflow-safe full-width integer arithmetic, caps at 100%, and keeps remaining
money at zero after the target is exceeded.
The production icon uses the owner-approved enlarged budget-track mark with standard
green-gradient, dark, and system-tinted 1024px opaque variants; iOS owns the final corner mask.
Cold process launches add a localized, selected-skin brand transition lasting less than one second
after the static iOS launch screen. It runs once per process, does not replay after foregrounding,
and uses opacity only when Reduce Motion is enabled.

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
- The Settings budget editor may update amounts only for the cycle containing its explicit
  reference date. It preserves plan identity, boundaries, currency, and category budgets;
  historical cycles cannot be edited through that path.
- Fixed expenses are actual ledger entries created directly or by confirmed monthly recurring
  rules. Budget setup no longer accepts a separate fixed-expense forecast. A Schema V1–V3 plan
  temporarily preserves both its old Expected expenses funding base and any legacy reservation so
  upgrading cannot change the current cycle's available amount; actual fixed entries consume the
  reservation first. The next copied cycle writes zero and switches to the new income basis.
- New-plan setup preview and runtime use the same disposable basis: monthly income plus only extra
  income explicitly allocated to the spending budget, minus the per-cycle savings goal, clamped at zero.
  Expected expenses remains an independent pace and reasonableness reference rather than being
  auto-filled from income or used as hidden spending permission.
- Actual fixed and discretionary rows both reduce the cycle's disposable balance. Today's amount
  subtracts today's discretionary rows one for one; an actual fixed row is rebalanced across the
  remaining days because it has already reduced the cycle balance.
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
- V1 CSV is an explicit unified expense/income-ledger export from in-memory transfer data, with
  UTF-8 BOM, exact major/minor units, UTC dates, disclosed raw notes/source or merchant fields,
  and spreadsheet-formula safety.
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
- Internal TestFlight started with candidate `0.9.0 (1)`; build `0.9.2 (3)` completed the free
  tier, `0.9.4 (5)` was uploaded after Phase 12 and PR #19, and `0.9.5 (6)` was accepted by App
  Store Connect transport after PR #20. Current Unreleased source changes require a new build
  number before the next upload. Replacement uploads increment the build number, and owner-approved
  prerelease milestones may also increment the `0.9.x` patch version. The first public App Store
  release reserves `1.0.0`. Every upload must have a matching dated CHANGELOG section and
  TestFlight/App Store release-note entry, and the app's About page shows localized notes for the
  installed marketing version.
- App language is app-owned persisted and published state with Follow System, Simplified Chinese,
  and English choices. A selection change immediately invalidates the root view and drives SwiftUI,
  deterministic Ask/templates, formatting, app-owned
  notifications, Spotlight wording, localized search, and export filenames without changing the
  iPhone language.
- Recording income alone never increases spending permission. A V3 companion allocation record
  stores only owner-confirmed portions; a nonzero spending portion must identify an existing budget
  cycle that contains the income date, while savings remains separate and cross-cycle. Their sum
  cannot exceed the income, and the form cannot invent a missing historical budget cycle.
- The total savings goal is one cross-cycle target plus optional starting balance. It does not
  replace or reinterpret the per-cycle savings reservation in `BudgetPlan`.
- Monthly recurring fixed-expense rules begin after explicit confirmation, keep the source expense's
  handled month independent from the editable future anchor, use the saved calendar day/local time
  with end-of-month clamping, reconcile each occurrence once by stable identity, commit the oldest
  120 pending occurrences across all rules per atomic foreground batch, continue remaining work on
  a later foreground pass with a visible non-error Settings notice, stop an anomalous scan after
  1,200 months, skip paused months after resume, and never delete ledger history when a rule is
  removed.
- The iOS launch screen remains static. The optional brand motion is an app-owned cold-launch
  overlay, never a video or third-party animation, and its Debug UI-test hold cannot ship in Release.

## Local development environment

- Xcode: 26.6 final (build 17F113; iOS SDK build 23F81a)
- Minimum deployment target: iOS 17.0
- Swift language mode: Swift 6 with complete strict concurrency checking
- Phase 0 validation destination: `platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5`
  (installed runtime build 23F77)
- GitHub Actions requires Xcode 26.6+ on macOS 26, dynamically creates a simulator
  from the newest compatible iOS 26 runtime, and separately asserts the app target's
  iOS 17.0 deployment setting. Real iOS 17 runtime testing remains manual until a
  reliable hosted or self-hosted runtime is available.

## Current state

Phases 0 through 9, Phase 11, Phase 12, and the pre-Phase-10 UI/UX design interlude are complete;
Phase 10 retains its signed-device and distribution release gates. The app opens a versioned
persistent SwiftData store. Schema V2 adds per-entry income to the nine original V1 model types,
and Schema V3 adds companion income allocation, total savings-goal, and monthly recurring-rule
models. Schema V4 adds companion budget-authority metadata: absence means a migrated legacy plan,
while every new plan persists the income-based authority. Tested lightweight migrations preserve
the shipped V2 income and V1–V3 budget shapes. All
writes remain actor-isolated and cross-boundary projections remain Sendable.
The pure `BudgetEngine` exposes an unconfigured/configured enum so configured metrics are
nonoptional, validates that current-budget reference dates remain inside the half-open
cycle, and calculates reservations, safe daily spend, purchase impact, and category risk
using checked `Int64` and `Decimal` arithmetic. It also derives the Today screen's daily-spend
pace and remaining-today facts without moving financial arithmetic into SwiftUI. A zero daily
amount is always explained, including when the cycle has no currently distributable flexible
allowance before the user records anything that day. Free-budget
ratios exist only for
discretionary spending with a real positive baseline. Calendar-injected cycle calculation
covers custom start days, month-end clamping, leap years, DST, immutable history, explicit
transition and first-regular-budget confirmation, and atomic lazy generation capped at 120
plans. Stateless currency formatting respects each supported exponent. The iPhone UI now
provides localized onboarding and budget setup, three persisted visual skins
(Aurora Glow, Warm Botanical, and Neon Pulse) backed by one semantic theme environment and three
purpose-built, text-free portrait background artworks,
with a card-based Today experience,
four real content tabs plus a separate accessible add action, exact locale-aware manual
expense entry with an app-owned keypad and selected-date impact, recent-category
and merchant suggestions, plus an exact income-entry path. Log merges expense and income in a
searchable/filterable chronological ledger with targeted detail, edit, and delete flows. Income
history never mutates the user's configured budget. Interactive date previews project budget coverage without writes; only Dashboard
lifecycle work and expense save may persist automatic cycle coverage. General expense
summaries exclude raw notes, while targeted details and actor-contained note search support
the UI without widening later AI inputs. Optional purchase-reason and emotion fields stay
collapsed by default and use situation-based, non-diagnostic labels. Wishlist items now
have localized create, edit, detail, archive, delete, purchase, skip, and reactivate flows;
current expense input can move into the wishlist without creating an expense. At most five
active/cooling-off/ready-to-review items may be open; the actor enforces this for every app and
Siri write, while purchased/skipped/archived history does not consume a slot. Cooling-off
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
opens from Today as a short first-level directory with responsibility-scoped second-level pages;
its Budget destination edits the existing current-period amounts through one Save action while
keeping currency and historical boundaries locked. Runtime enum/status values are explicitly
localized rather than rendered as catalog keys. Reminders
use a focused full-screen pause surface, and every existing free
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
cooling-off outcomes, and point-in-time adequate-budget-buffer checks. The positive
`safeToProceed` result remains an entry-flow check only: it is neither persisted nor returned
from retrospective insight reads because its remaining-balance payload becomes stale after later
ledger changes. Other typed localized insights are deduplicated and dismissible in SwiftData.
Presentation is independently throttled by settings, scoped
cooldowns, threshold re-crossing, recent responses, and daily caps; only actually shown
messages create reminder events. Manual expense entry offers one highest-priority sheet at
most, keeps Continue Purchase primary, and supports Wishlist as a calm alternative. The
Insights tab now shows a rolling local 30-calendar-day total/count, a category donut that keeps
up to six real categories and combines categories into one localized remainder only when seven or
more categories exist, without dropping any recorded amount, an emotion breakdown, a 30-point daily trend, the
current-cycle summary, generated pattern cards, dismissal, and a fixed informational disclaimer.
Its ledger summary remains authoritative when a supplementary
cooling-off projection is unreadable, but that partial state is disclosed and all dependent
narrative, model, pattern-write, and stored-card work stops because unknown outcomes must never be
represented as zero. Template
copy is the mandatory local path; Phase 5 itself performs no notification scheduling or real
AI model call. Expense persistence remains authoritative over best-effort reminder history:
logging failures skip the advisory surface but never reject a valid expense. Rule and
throttle thresholds are named at their owning layer, unavailable daily calendar bounds
downgrade interruptions, and overflowing historical aggregates produce no biased baseline.
Phase 6 adds explicit-permission local notifications for cooling-off reviews, one persisted
stable request identifier per plan, lifecycle reconciliation, delivered-event history, and
calendar-safe quiet-hour replanning. Notification content names only the wishlist item and
never accepts an amount or note. Settings now exposes authorization state, a System Settings
path after denial, quiet hours, an in-memory ShareLink expense/income CSV, and clear privacy facts.
CSV uses UTF-8 BOM, exact integer-derived amount fields, UTC timestamps, correct embedded
comma/quote/newline escaping, and formula neutralization; its screen discloses that an
explicit export includes raw expense/income notes and source or merchant names. Delete All requires two confirmations, displays
each notification/index/data/preference stage, stops without a success claim on failure,
and returns to onboarding only after a post-delete query verifies every current SwiftData type
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
remains authoritative for classification, arithmetic, rules, and allowed actions. Ask model output
contains wording only and receives its already-contracted action identifiers from deterministic
code; app configuration is not reported as a model safety failure.
Model output uses constrained
generation, a short timeout, path-appropriate length/action/language/number safety validation, and immediate
template fallback; English/Simplified Chinese proposals with the wrong writing system are
rejected, dynamic action identifiers are resolved explicitly through the active locale, and the
UI distinguishes validation, timeout, availability, and model-error fallback without retaining
rejected generated text.
Generated copy is not persisted. Settings always explains the current
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

The Today card's actionable amount is the deterministic `safeDailySpend`: current remaining
flexible budget divided across remaining calendar days after stored entries have already been
applied. Pace variance remains separate. Budget setup and Settings expose the flexible allocation,
and Ask can explain total remaining, pending fixed/savings reservations, and current availability.
The optional local app lock is independent from accounts and cloud services. It is default-off,
requires Face ID availability and owner authentication to enable, authenticates again to disable,
and covers all app content on launch and foreground return until `LocalAuthentication` succeeds.
The system passcode is an intentional recovery path; no biometric material enters app storage.
