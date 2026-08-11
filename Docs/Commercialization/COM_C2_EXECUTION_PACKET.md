# COM-C2 Execution Packet

## Purpose

This packet divides COM-C2 into independently reviewable StoreKit 2 changes. It does not authorize
formal App Store Connect products, customer pricing, trials, cloud quota, a paywall, or distribution
of the post-C1 source. The accepted technical catalog remains Pro Monthly and Pro Annual in one
`MindBudget Pro` subscription group; Local Lifetime remains absent.

## Input gate

- COM-C1 is completed and merged.
- Accepted identifiers are `com.xdgf558.mindbudget.pro.monthly` and
  `com.xdgf558.mindbudget.pro.annual`.
- Accepted internal references are `MindBudget Pro Monthly`, `MindBudget Pro Annual`, and the
  subscription-group reference `MindBudget Pro`.
- Commercial price, trial, included cloud calls, reset boundary, and storefront availability are
  still `TBD`; local fixture prices are synthetic test data and never a customer offer.
- Distribution remains paused until verified purchase/restore, purchase presentation, and their
  owning release gates are complete.

## C2-01 — StoreKit test catalog

### Tasks

- Commit one Xcode StoreKit Configuration fixture containing exactly the accepted Monthly and
  Annual auto-renewable subscriptions at the same service level.
- Keep Lifetime, one-time products, non-renewing subscriptions, introductory/code/ad-hoc/win-back
  offers, and Family Sharing absent.
- Copy the fixture only into the unit-test bundle. The app target and Archive must not contain it.
- Keep the default shared scheme free of StoreKit Configuration. Add a dedicated Debug/local scheme
  that activates the fixture and cannot Archive.
- Add a same-code-path static validator plus StoreKitTest/JSON tests for identifiers, durations,
  group membership, bilingual fixture labels, and forbidden catalog content.

### Tests

- `Scripts/check-storekit-test-catalog.sh`
- `StoreKitTestCatalogTests`
- Default-scheme build-for-testing plus the complete repository validation suite.

### Stop conditions

- Stop if an accepted identifier/reference/group is missing or duplicated.
- Stop if the fixture enters the app resource phase, the default scheme, or an Archive-capable
  scheme.
- Stop if any Lifetime, formal offer, customer price/trial promise, purchase UI, entitlement
  authority, or App Store Connect product is introduced.

## C2-02 — Runtime catalog and entitlement store

### Tasks

- Add the app-owned StoreKit product catalog and actor-isolated entitlement lifecycle authority.
- Treat any cache as presentation-only; current verified StoreKit state remains authoritative.
- Own exactly one lifecycle-scoped `Transaction.updates` task.

### Tests

- Product-load failure, launch reconciliation, concurrent reads, lifecycle ownership, and
  presentation-cache isolation.

### Stop conditions

- Stop before purchase, restore, paywall, formal product creation, or price/trial decisions.

## C2-03 — Purchase, restore, and status mapping

### Tasks

- Implement verified purchase/finish, pending, cancellation, neutral error, user-triggered restore,
  and the accepted subscription-status mapping.

### Tests

- Subscribed/grace grant Pro; retry/expired/revoked/unverified/pending do not. Restore and finish
  behavior are explicit and idempotent.

### Stop conditions

- Stop before customer-facing paywall presentation or unaccepted commercial terms.

## C2-04 — Environment and regression gate

### Tasks

- Prove Configuration, Sandbox, TestFlight, and Production state cannot contaminate one another.
- Prove catalog failure never erases a separately verified entitlement.

### Tests

- Complete `STOREKIT_TEST_MATRIX.md`, full Free regression, and retained distribution hold.

### Stop conditions

- COM-C2 is not Done until every environment/state row has objective evidence.
