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
| StoreKit Configuration | Local development fixture | App resources/Archive, default scheme, Sandbox/TestFlight/Production rights or server cache | `Config/StoreKit/MindBudgetPro.storekit`; CHN/`zh_CN` default; exact synthetic prices and local-test disclaimers; test-bundle-only resource; `MindBudget-StoreKit-Local` non-Archive scheme; catalog gate and StoreKitTest/JSON tests |
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

- Pure unit reports: entitlement-set algebra, feature matrix, status mapper, environment parser,
  cache semantics and transaction idempotency.
- StoreKit Configuration reports: C2-01 catalog-shape/isolation tests, followed by
  purchase/restore/lifecycle and UI tests in later COM-C2 packets using the same committed fixture.
- Sandbox/TestFlight manual reports: dated account/device/build/environment evidence under
  `TestResults/Commercialization/StoreKit/<build>/` or the CI artifact named in `CI_BASELINE.md`.
- Production preflight: no real purchase until formal products, prices, review metadata and owner
  approval exist.

## Stop conditions

Stop and do not grant paid access on unknown Product ID, environment mismatch, unverified result,
missing current status, duplicate lifecycle owner, non-idempotent update, hardcoded price/trial,
or any path that converts test state into Production rights.
