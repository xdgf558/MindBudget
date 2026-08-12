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
- exactly one app-lifecycle `Transaction.updates` listener, including update before/after UI owner;
- C2-02 preserves an unrevoked current-entitlement record even when its last renewal expiration
  is in the past; C2-03 alone combines that raw fact with StoreKit subscription status so billing
  grace is not filtered before the status mapper can see it;
- the live AppSession access projection changes exact Free → Pro → exact Free after authority
  updates, without requiring an app restart;
- every verified transaction is handled idempotently and finished at the required boundary;
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
  presentation-cache semantics, current-entitlement reconciliation, fail-closed unknown/mixed/
  unverified state, concurrent immutable reads, and one listener owner. Status mapping remains C2-03.
- StoreKit Configuration reports: C2-01 catalog-shape/isolation tests, followed by
  C2-02 CHN/USA runtime product-loading tests enabled only by the dedicated Xcode local scheme,
  followed by purchase/restore/lifecycle and UI tests in later COM-C2 packets using the same fixture.
  Before C2-03 starts, both runtime probes must execute (not skip) and pass under a supported final
  Xcode toolchain; `SKInternalErrorDomain Code=3` or an empty catalog blocks entry rather than
  authorizing a weaker probe.

### C2-03 runtime-probe entry evidence

| Execution surface | Probe result | Gate meaning |
|---|---|---|
| Xcode 26.6 RC `17F109`, iOS 26.5 | CHN/USA executed; `SKInternalErrorDomain Code=3`; empty products | Historical failure retained; not a pass |
| Xcode 26.6 final `17F113`, final iOS 26.4 | CHN/USA executed; `Code=3`; empty products; `storekitd` Octane entitlement/development-install handshake diagnostic | Supported-final-runtime failure; C2-03 blocked |
| Xcode 26.6 final `17F113`, final iOS 26.5 runtime `23F77` | CHN/USA executed; `Code=3`; empty products; same handshake diagnostic | Supported-final-runtime failure; C2-03 blocked |
| Xcode 26.6 final `17F113`, iOS 27 beta | 16 tests in 2 suites pass | Diagnostic only; beta runtime cannot satisfy the entry gate |

Final Xcode's iOS SDK build is `23F81a`. Apple's currently offered export was the older runtime
build `23F73`; it was not imported and could not replace installed build `23F77`, so it supplied no alternative supported-
runtime pass. Direct download queries for build `23F81` and iOS `26.5.1` returned unavailable.
This matrix records the observed evidence without inferring probe success.
- Sandbox/TestFlight manual reports: dated account/device/build/environment evidence under
  `TestResults/Commercialization/StoreKit/<build>/` or the CI artifact named in `CI_BASELINE.md`.
- Production preflight: no real purchase until formal products, prices, review metadata and owner
  approval exist.

## Stop conditions

Stop and do not grant paid access on unknown Product ID, environment mismatch, unverified result,
missing current status, duplicate lifecycle owner, non-idempotent update, hardcoded price/trial,
or any path that converts test state into Production rights.
