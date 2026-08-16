# StoreKit Test Matrix

## Fixed technical catalog

No formal App Store Connect product or subscription group exists yet. C2-01 commits one local
Xcode StoreKit Configuration fixture with these accepted technical identifiers. Merged C3-01 changes its
default test environment to USA/`en_US` and applies the owner's provisional nonpublic test anchors;
these remain Configuration/Sandbox/TestFlight controls rather than final regional economics:

| Product | Product ID | Group | Level | Duration | Price/trial |
|---|---|---|---|---|---|
| Pro Monthly | `com.xdgf558.mindbudget.pro.monthly` | `MindBudget Pro` | Same Pro service level | 1 month | US$1.99 test anchor; one P1W free trial for eligible accounts |
| Pro Annual | `com.xdgf558.mindbudget.pro.annual` | `MindBudget Pro` | Same Pro service level | 1 year | US$19.99 test anchor; one P1W free trial for eligible accounts |

Local Lifetime and all future entitlement/product IDs are absent and must be proven unreachable.

## Environment isolation

| Source | May affect | Must never affect | Required evidence |
|---|---|---|---|
| Debug entitlement provider | Debug process only | Release/TestFlight/Production persistence | Release binary/static absence and clean-relaunch test |
| StoreKit Configuration | Local development fixture and product presentation | App resources/Archive, default scheme, Sandbox/TestFlight/Production rights or server cache | `Config/StoreKit/MindBudgetPro.storekit`; USA/`en_US` default; exact US$1.99/US$19.99 test anchors and one P1W free-trial offer per product; test-bundle-only resource; `MindBudget-StoreKit-Local` non-Archive scheme; catalog gate, StoreKitTest/JSON tests, and opt-in HKG/USA/SGP/TWN runtime product-load tests |
| Sandbox | Verified `AppTransaction` Sandbox environment plus matching Sandbox transaction/status facts | Production rights/current-entitlement cache | Exact Sandbox acceptance; Xcode/Production/bundle mismatch rejection |
| TestFlight | Apple's Sandbox environment under a distributed build; no build-channel inference | Production grandfathering after public release | TestFlight is modeled as verified Sandbox, never as a fourth entitlement environment |
| Production | Verified `AppTransaction` Production environment plus matching Production facts | Debug/Xcode/Sandbox configuration | Exact bundle/AppTransaction/Product/environment verification; mismatch fails closed |

An unavailable app environment may use the literal `Unknown` only to partition non-authoritative
product presentation and its deletable cache. That presentation path may still show StoreKit
metadata, but `Unknown` is never accepted by an entitlement read, purchase preflight, or access
decision and can never grant or preserve a paid right.

## Subscription-state mapping

| Verified state | Subscription right | Expected behavior |
|---|---:|---|
| Subscribed/current | Yes | Union current subscription entitlement into set |
| Billing grace period | Yes | Preserve access through Apple-reported grace end |
| Billing retry, not in grace | No | Soft landing and manage-subscription path; exact Free set |
| Expired | No | Exact Free set; local data remains available |
| Revoked/refunded | No | Remove right promptly; preserve user data |
| Unverified transaction/status | No | Reject as authority; safe localized error/fallback |
| Pending purchase | No new right | Show pending; do not finish until verified transaction arrives |
| User-cancelled purchase sheet | No change | Neutral cancellation, no error/shame |
| Cached presentation state only | No permanent right | May reduce launch flicker; reconcile before protected use |
| Unknown/new status | No | Fail closed and record content-free diagnostic |

## Lifecycle cases

Every row must be exercised for Monthly and Annual where applicable:

- product list success, partial result, empty result, timeout, offline, stale cache and unknown ID;
- product loading under the committed CHN storefront and at least one non-CHN test storefront;
- purchase success with verified result, pending, user cancellation, unverified, thrown error;
- exactly one app lifecycle task supervising `Transaction.updates` and
  `Product.SubscriptionInfo.Status.updates`, including signals before/after UI owner; a status
  signal triggers a fresh full reconciliation and never becomes a second authority;
- C2-02 preserves an unrevoked current-entitlement record even when its last renewal expiration
  is in the past; the C2-03 candidate combines that raw fact with verified StoreKit status and
  renewal information so expiration alone never invents or suppresses billing grace;
- the live AppSession access projection changes exact Free → Pro → exact Free after authority
  updates, without requiring an app restart;
- every verified transaction is handled idempotently, publishes an authoritative access snapshot
  before finish, and remains unfinished for later retry when finish fails;
- duplicate/reordered updates, reinstall, app restart, account change and concurrent purchase tap;
- explicit Restore Purchases success/no purchase/offline/error; no implicit restore prompt;
- subscribed → grace → recovered, subscribed → retry/no grace, expiry, revoke/refund;
- billing grace is enabled or injected by the lifecycle packet's controlled `SKTestSession` setup;
  the C2-01 catalog fixture alone is not lifecycle-mapping evidence;
- upgrade/crossgrade between Monthly/Annual at the same service level according to current StoreKit
  behavior; no app-invented proration or effective date;
- Product/catalog failure never deletes a separately verified current entitlement;
- price/term copy comes from `Product`/current renewal information and remains localized/accessible;
- trial eligibility and length come from the actual accepted StoreKit offer; no `30 days` guess;
- renewal reminder exists only when a verified current introductory-free-trial transaction and
  verified renewal information provide a reliable future date with auto-renew enabled; the P1W
  fixture and presentation eligibility are never lifecycle authority;
- the one stable generic reminder uses calendar T−5, contains no date/price/amount/product/day
  count, never prompts for permission, and is removed/replaced after cancellation, trial end,
  refund/revocation, product/date change, missing authority, or failed replacement;
- manage subscription and legal/restore links remain reachable without purchase pressure;
- family sharing stays off and `.familyShared` cannot silently grant a state not accepted later;
- TestFlight/Sandbox rights never become permanent Production rights.

## Test layers and report paths

- Pure unit reports: entitlement-set algebra, feature matrix, verified app-identity policy,
  Xcode/Sandbox/Production exact-match and cross-environment/bundle rejection, exact-context
  presentation-cache semantics, current/status reconciliation, fail-closed unknown/mixed/
  unverified/incomplete state, concurrent immutable reads, one listener owner, the full C2-03
  status matrix, typed purchase/restore outcomes, publish-before-finish, duplicate delivery,
  operation serialization, failed-finish retry, unfinished startup processing, and transaction/
  subscription-status signals converging on the same full-reconciliation path. The tests in
  `StoreLifecycleDomainTests.swift` own the deterministic publish, finish, sync, and active-batch
  wait gates; `StoreRuntimeTests.swift` owns the separate out-of-order whole-read gate and the
  C2-04 app-environment matrix. C2-04's focused run passed 49/49 across these two suites. The
  strict Phase 10 suite passed 20/20 across 10 iterations, and the owning full run completed 346
  Swift tests plus 13 UI tests with 0 failures; four explicit runtime probes skipped by design.
  Evidence: `/private/tmp/MindBudget-C204-ReviewFix-WallClockSuite-10x.xcresult` and
  `/private/tmp/MindBudget-C204-ReviewFix-Full-Shared-Retry.xcresult`.
- Verification-derivation boundary: pure mapper tests intentionally construct app-owned
  `VerifiedStoreTransaction` facts, including `hasVerifiedStatusTransaction`,
  `hasVerifiedRenewalInfo`, `hasVerifiedAppBundle`, and the optional trial projection; they prove how a completed fact set is
  consumed, not how StoreKit produces those booleans. Production derivation in
  `verifiedRecord(from:status:)` correlates the handled transaction, verified status transaction,
  verified renewal info, original transaction ID, verified app bundle, environment, accepted
  Product IDs, current Product ID, and deferred-crossgrade preference. Public StoreKit status/
  renewal value types cannot be freely constructed by unit tests. Only the opt-in
  `runtimeMonthlyPurchaseIsVerifiedGrantedAndFinished` and
  `runtimeAnnualPurchaseIsVerifiedGrantedAndFinished` flows enter that production derivation with
  real `Transaction` and `Product.SubscriptionInfo.Status` objects. Default-scheme coverage and
  the pure mapper matrix must never be cited as proof of that framework bridge; malformed-status
  and real deferred-crossgrade correlation remain controlled StoreKit runtime obligations. C3-02
  additionally derives trial activation from real `Transaction.offer` and its lifecycle facts
  from verified `renewalDate`/`willAutoRenew`; only the opt-in Monthly/Annual flows can prove this
  framework bridge. `RenewalInfo.offer` is deliberately not required because it describes an
  offer at the next renewal period and may be nil after a one-period free trial.
- StoreKit Configuration reports: C2-01 catalog-shape/isolation tests, followed by
  C2-02 CHN/USA runtime product-loading tests enabled only by the dedicated Xcode local scheme.
  The C2-03 candidate adds deterministic purchase/restore/lifecycle tests and opt-in local
  Monthly/Annual transaction-verification-and-finish probes using the same fixture. These probes
  seed transactions through `SKTestSession.buyProduct`; a hosted test has no purchase-sheet UI
  anchor, so presented `Product.purchase()` evidence remains owned by C3. Customer-facing purchase
  UI remains C3. The C2-04 environment-isolation regression gate is complete and merged; it does
  not substitute for the presented-purchase evidence owned by C3.
  The C2-03 entry gate required both runtime probes to execute (not skip) and pass under a
  supported final Xcode/runtime surface; `SKInternalErrorDomain Code=3` or an empty catalog could
  not authorize a weaker probe. The accepted physical-device evidence below satisfied that gate.

### C2-03 runtime-probe entry evidence

| Execution surface | Probe result | Gate meaning |
|---|---|---|
| Xcode 26.6 RC `17F109`, iOS 26.5 | CHN/USA executed; `SKInternalErrorDomain Code=3`; empty products | Historical failure retained; not a pass |
| Xcode 26.6 final `17F113`, final iOS 26.4 | CHN/USA executed; `Code=3`; empty products; `storekitd` Octane entitlement/development-install handshake diagnostic | Supported-final-runtime failure; C2-03 blocked |
| Xcode 26.6 final `17F113`, final iOS 26.5 runtime `23F77` | CHN/USA executed; `Code=3`; empty products; same handshake diagnostic | Supported-final-runtime failure; C2-03 blocked |
| Xcode 26.6 final `17F113`, iOS 27 beta | 16 tests in 2 suites pass | Diagnostic only; beta runtime cannot satisfy the entry gate |
| Xcode 26.6 final `17F113`, physical `iPhone Air`, final iOS 26.6.1 `23G82` | 5 passed, 0 failed, 0 skipped; CHN Passed; USA Passed | Accepted supported-final physical-device evidence; C2-03 entry gate passed |

Final Xcode's iOS SDK build is `23F81a`. Apple's currently offered export was the older runtime
build `23F73`; it was not imported and could not replace installed build `23F77`, so it supplied no alternative supported-
runtime pass. Direct download queries for build `23F81` and iOS `26.5.1` returned unavailable.
The historical simulator and beta evidence remains part of the record. The physical final-device
row is the accepted pass that opens C2-03; it does not satisfy later purchase, restore, status,
environment-isolation, paywall, or release gates.

### C2-03 implementation candidate evidence

The implementation candidate adds deterministic lifecycle tests plus opt-in local StoreKit probes
for Monthly/Annual transaction verification, authority publication, and finish. The deterministic
state matrix proves subscribed/grace/retry/expired/revoked interpretation after app-owned facts
exist; it does not independently prove StoreKit's status/renewal-to-fact derivation. The two
purchase/finish probes are the framework-backed path for the regular Monthly/Annual derivation,
and they remain opt-in rather than part of default-scheme coverage. A physical forced-
renewal experiment terminated its hosted test runner before completion and was removed rather
than reported as evidence; a stable real transition probe remains a later UI/runtime obligation.
The source-level contract passed independent review and green CI and merged through PR #30 as
`3fc72b4`. Local
evidence records 44/44 focused lifecycle/runtime tests, 31 lifecycle tests across 10 iterations
(310/310), an isolated strict wall-clock signal at 10/10, and a complete default-scheme run with
342 Swift tests and 13 UI tests at zero failures. Its combined xcresult is 355 total, 351 passed,
4 explicit opt-in StoreKit runtime probes skipped, and 0 failed; every selected coverage file
remains above 85%. Evidence: `/private/tmp/MindBudget-C203-Full-Final15.xcresult`. The five-test physical
entry run above covered catalog entry only and must not be relabeled as evidence that these new
purchase/restore/finish or status/renewal-derivation paths ran.
At the C2-04 closeout there was no customer-facing purchase/restore UI or paywall. C2-04 completed
the Configuration/Sandbox/TestFlight/Production isolation gate through PR #31, green CI, and merge
`a293762`; the C3-01 candidate below now owns voluntary presentation without changing that
authority.
- Sandbox/TestFlight manual reports: dated account/device/build/environment evidence under
  `TestResults/Commercialization/StoreKit/<build>/` or the CI artifact named in `CI_BASELINE.md`.
- Production preflight: no real purchase until formal products, prices, review metadata and owner
  approval exist.

### C3-01 merged presentation

C3-01 owns the first customer-facing purchase surface without changing entitlement authority.
The voluntary Settings/value-trigger screen displays `Product.displayPrice`, exact Monthly/Annual
periods, and the actual optional StoreKit introductory offer only after a fresh
`isEligibleForIntroOffer` result. Its cached snapshot retains presentation metadata but
deliberately clears eligibility; cached and unavailable states disable purchase and never invent
a price or trial. An unavailable entitlement snapshot independently blocks the View and actor and
offers a user-initiated recheck. Purchase, restore, and manage subscription remain explicit taps
through the C2 typed seams, and the automatic-presentation count is zero.

The presentation model retains an introductory offer's localized `displayPrice` and full
payment-mode raw value. C3-01 supports only an eligible free trial. An eligible pay-as-you-go,
pay-up-front, or unknown future mode suppresses standard renewal disclosure and pauses purchase
at both the View and StoreKit adapter; an ineligible offer falls back to ordinary subscription
terms. None of these presentation decisions enter entitlement mapping.

Pure tests cover the complete typed purchase/restore notice matrix, stable production catalog
shape with a missing or changed promotion, cache eligibility stripping, malformed structural
terms, StoreKit-price interpolation, unavailable-authority purchase rejection before the source,
and English/Chinese renewal disclosure under explicit app locales. Exact P1W offer validation is
owned only by the isolated `.storekit` fixture contract and opt-in runtime probes. The UI test
opens the screen only after the person selects Settings and proves no launch/dashboard
presentation.
Pure tests additionally cover eligible paid installment and paid-up-front modes, retained offer
price/mode identity, unknown-mode rejection, and the ineligible-offer fallback. The production
derivation of `hasVerifiedStatusTransaction`, `hasVerifiedRenewalInfo`, and
`hasVerifiedAppBundle` still requires real StoreKit `Transaction`/subscription-status objects;
its evidence layer is the opt-in local scheme and supported-final physical-device probes, not
direct construction-based unit coverage.
The static StoreKit gate rejects provisional price literals or raw StoreKit purchase/sync calls in
customer source and requires the two approved Settings/value-trigger entry sites.
The signed public-configuration value trigger is stricter than an empty fail-closed entitlement
set: it requires an actionable whole-snapshot StoreKit resolution whose effective state is exact
Free. Initial, incomplete, unverified, mixed, unavailable, and paid-then-unverifiable states remain
suppressed. Focused C3-03B regressions cover each unavailable shape and the paid-to-unavailable
refresh transition.

The dedicated local scheme owns four runtime product probes—HKG, USA, SGP, and TWN. Each must
actually execute and load the exact Monthly/Annual test catalog, periods, localized
`displayPrice`, and fixture-only P1W free-trial offer; a skip, empty set, wrong test term, or
StoreKit error is non-evidence. Those probes validate StoreKit-to-app projection for the local
fixture; production authority deliberately does not require a promotion. Formal App
Store Connect product creation, final regional prices, C3-02 reminders, Archive/upload, tester
assignment, and distribution remain blocked even after these local probes pass.

Accepted C3-01 candidate evidence: final Xcode 26.6 `17F113` ran `MindBudget-StoreKit-Local` on
the physical `拉沙的iPhone` (`iPhone Air`) with final iOS 26.6.1 `23G82`. All 9 tests passed,
0 failed, and 0 skipped. HKG, USA, SGP, and TWN each loaded both products with exact periods and
P1W offers; the Monthly and Annual transaction probes also entered the production StoreKit
derivation/authority path, granted Pro, finished, and left no unfinished transaction. Evidence:
`/private/tmp/MindBudget-C301-Storefronts-Physical.xcresult`. This remains local test-fixture
evidence, not formal-product, Sandbox-account, TestFlight, price-acceptance, or distribution
evidence.

### C3-02 trial-lifecycle candidate

C3-02 does not start a local seven-day clock. The existing verified StoreKit authority publishes
one process-local `TrialLifecycleProjection` only when the current verified transaction is an
introductory free trial in the accepted app/product/environment chain. Verified renewal info owns
the actual renewal date and auto-renew state. It keeps the current trial product separate from the
accepted next-period `autoRenewPreference`, so a same-group switch changes the projection and live
renewal-price lookup even when the date does not move. The projection disappears with nontrial, grace,
retry, expired, revoked, unverified, conflicting, or missing authority and is never persisted.

`TrialLifecycleScheduler` reconciles one stable pending request at five user-calendar days before
a reliable future renewal. Its serialized add/remove effects make the latest entitlement/settings/
locale state win even across actor suspension. It removes the prior request before replacement,
so a failed add cannot retain an old renewal date. Disabled/denied/not-determined notifications or
an already-passed reminder window use a noninterrupting in-app card and never request permission.
No reliable date or auto-renew off schedules nothing. Dashboard and the voluntary Pro screen show
the verified date; they may add the accepted next-renewal product's price only from a current
`.live` StoreKit catalog snapshot. Notification copy says the trial ends soon and asks the person
to review current status instead of asserting that auto-renew remains enabled while the app is
terminated.

Pure C3-02 tests cover matching/mismatched trial projections, exact calendar T−5, generic content,
disabled/denied/no-date/past-window fallback, cancellation/revoke/auto-renew-off removal, product/
date replacement, same-date `autoRenewPreference` switching, state-safe bilingual copy, and
failed-add cleanup. They consume app-owned projections. The opt-in Monthly/
Annual local StoreKit tests additionally assert that the real production bridge returns the
matching product, a nonnil renewal date, and auto-renew enabled. Final Xcode 26.6 `17F113` ran
the dedicated suite on physical `iPhone Air`, final iOS 26.6.1 `23G82`: 9 passed, 0 failed,
0 skipped. HKG/USA/SGP/TWN and both Monthly/Annual trial-lifecycle derivation paths passed. Runtime
tests validate the free-trial mode/P1W structure while StoreKit owns each locale's zero-price
string; the isolated fixture validator retains the exact provisional USD literal. Evidence:
`/private/tmp/MindBudget-C302-Physical4.xcresult`.

Independent-review remediation split the current trial product from the verified next-renewal
product, added the same-date `autoRenewPreference` switch regression, and made pending reminder
copy state-safe after process termination. The focused trial suite passed 13/13; the owning full
run produced 382 results (376 passed, 6 explicit opt-in probes skipped, 0 failed), including all
14 UI tests and every selected coverage threshold. Evidence:
`/private/tmp/MindBudget-C302-ReviewFix-Trial2.xcresult` and
`/private/tmp/MindBudget-C302-ReviewFix-Full.xcresult`.

PR #34 subsequently passed independent review and green GitHub Actions run `31803898776`, then
merged C3-02 to `main` as `12d9217` on 2026-08-14. C3-02 is Done. This evidence does not start
C3-03, accept formal products/economics, or authorize versioning, Archive/upload, tester
assignment, or distribution.

### C3-04 UI and release-quality candidate

C3-04 consumes only `EffectiveStoreSubscriptionState`; it does not interpret StoreKit objects or
change entitlement authority. Verified grace shows a non-blocking payment-method/status prompt and
retains Pro. Verified retry, expired, and revoked states preserve local data and Free capabilities,
show one calm Dashboard navigation card plus the matching Pro-screen explanation, and expose
Manage Subscription and Recheck. Retry cannot start a second purchase. Expired/revoked may select
only a current live accepted product. Unavailable/unverified authority is not a confirmed Free
state and receives no exceptional-state card or enabled purchase.

Pure tests cover the four-state presentation table, exact purchase gate, English/Chinese strings,
and VoiceOver plan labels under an explicit app locale with StoreKit-supplied price tokens. The AX5
UI test selects all three appearances and verifies that purchase remains visible, restore/manage
remain reachable, and the pushed subscription-terms and subscription-privacy destinations open
without horizontal clipping. It retains Pro, Terms, and Privacy screenshots for every appearance.
Those automated assertions prove existence, bounds, navigation, and hit testing; they do not prove
visual contrast. All nine retained screenshots therefore require separate manual contrast
inspection. Customer terms no longer hardcode the fixture-only seven-day duration. Review notes
disclose Apple-handled commerce, local-data retention, the exact anonymous first-party
configuration request, and ordinary edge connection metadata; screenshots must not advertise a
deferred product or provisional term.

The production derivation of `hasVerifiedStatusTransaction`, `hasVerifiedRenewalInfo`, and
`hasVerifiedAppBundle` remains outside direct unit construction. Those booleans are consumed by
pure tests, while their derivation evidence is the opt-in local scheme and supported-final physical
device using real `Transaction`, subscription-status, renewal-info, and `AppTransaction` values.
C3-04's view tests must not be cited as proof of that framework bridge.

## Stop conditions

Stop and do not grant paid access on unknown Product ID, environment mismatch, unverified result,
missing current status, duplicate lifecycle owner, non-idempotent update, hardcoded price/trial,
or any path that converts test state into Production rights.
