# StoreKit Test Matrix

## Fixed technical catalog

No formal App Store Connect product or subscription group exists yet. C2-01 commits one local
Xcode StoreKit Configuration fixture with these accepted technical identifiers. Its default test
environment is CHN/`zh_CN`; its fixed prices and bilingual copy are synthetic test controls, not
accepted storefront or customer terms:

| Product | Product ID | Group | Level | Duration | Price/trial |
|---|---|---|---|---|---|
| Pro Monthly | `com.xdgf558.mindbudget.pro.monthly` | `MindBudget Pro` | Same Pro service level | 1 month | Commercial terms TBD; local fixture value is synthetic test data |
| Pro Annual | `com.xdgf558.mindbudget.pro.annual` | `MindBudget Pro` | Same Pro service level | 1 year | Commercial terms TBD; local fixture value is synthetic test data |

Local Lifetime and all future entitlement/product IDs are absent and must be proven unreachable.

## Environment isolation

| Source | May affect | Must never affect | Required evidence |
|---|---|---|---|
| Debug entitlement provider | Debug process only | Release/TestFlight/Production persistence | Release binary/static absence and clean-relaunch test |
| StoreKit Configuration | Local development fixture and product presentation | App resources/Archive, default scheme, Sandbox/TestFlight/Production rights or server cache | `Config/StoreKit/MindBudgetPro.storekit`; CHN/`zh_CN` default; exact synthetic prices and local-test disclaimers; test-bundle-only resource; `MindBudget-StoreKit-Local` non-Archive scheme; catalog gate, StoreKitTest/JSON tests, and opt-in CHN/USA runtime product-load tests |
| Sandbox | Sandbox tester and transaction history | Production rights/current-entitlement cache | Environment mismatch rejection and account-reset test |
| TestFlight | Sandbox purchase environment under distributed build | Production grandfathering after public release | Production install starts from verified Production state only |
| Production | Verified current Production StoreKit/App Store state | Debug/Sandbox configuration | Bundle/app/Product/environment verification |

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
- renewal reminder exists only with a reliable renewal date and accepted terms;
- manage subscription and legal/restore links remain reachable without purchase pressure;
- family sharing stays off and `.familyShared` cannot silently grant a state not accepted later;
- TestFlight/Sandbox rights never become permanent Production rights.

## Test layers and report paths

- Pure unit reports: entitlement-set algebra, feature matrix, environment parser, exact-context
  presentation-cache semantics, current/status reconciliation, fail-closed unknown/mixed/
  unverified/incomplete state, concurrent immutable reads, one listener owner, the full C2-03
  status matrix, typed purchase/restore outcomes, publish-before-finish, duplicate delivery,
  operation serialization, failed-finish retry, unfinished startup processing, and transaction/
  subscription-status signals converging on the same full-reconciliation path.
- StoreKit Configuration reports: C2-01 catalog-shape/isolation tests, followed by
  C2-02 CHN/USA runtime product-loading tests enabled only by the dedicated Xcode local scheme.
  The C2-03 candidate adds deterministic purchase/restore/lifecycle tests and opt-in local
  Monthly/Annual transaction-verification-and-finish probes using the same fixture. These probes
  seed transactions through `SKTestSession.buyProduct`; a hosted test has no purchase-sheet UI
  anchor, so presented `Product.purchase()` evidence remains owned by C3. Customer-facing purchase
  UI remains C3, while the complete environment-isolation regression gate remains C2-04.
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
state matrix proves subscribed/grace/retry/expired/revoked interpretation. A physical forced-
renewal experiment terminated its hosted test runner before completion and was removed rather
than reported as evidence; a stable real transition probe remains a later UI/runtime obligation.
The source-level contract is implementation complete and pending independent review. Local
evidence records 44/44 focused lifecycle/runtime tests, 31 lifecycle tests across 10 iterations
(310/310), an isolated strict wall-clock signal at 10/10, and a complete default-scheme run with
342 Swift tests and 13 UI tests at zero failures. Its combined xcresult is 355 total, 351 passed,
4 explicit opt-in StoreKit runtime probes skipped, and 0 failed; every selected coverage file
remains above 85%. Evidence: `/private/tmp/MindBudget-C203-Full-Final15.xcresult`. CI and merge
evidence remain pending; the five-test physical
entry run above must not be relabeled as evidence that these new purchase/restore/finish paths ran.
There is no customer-facing purchase/restore UI or paywall, and C2-04 still owns the complete
Configuration/Sandbox/TestFlight/Production isolation gate.
- Sandbox/TestFlight manual reports: dated account/device/build/environment evidence under
  `TestResults/Commercialization/StoreKit/<build>/` or the CI artifact named in `CI_BASELINE.md`.
- Production preflight: no real purchase until formal products, prices, review metadata and owner
  approval exist.

## Stop conditions

Stop and do not grant paid access on unknown Product ID, environment mismatch, unverified result,
missing current status, duplicate lifecycle owner, non-idempotent update, hardcoded price/trial,
or any path that converts test state into Production rights.
