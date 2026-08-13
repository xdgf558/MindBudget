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

Status: **Done** after independent review and full validation.

### Tasks

- Commit one Xcode StoreKit Configuration fixture containing exactly the accepted Monthly and
  Annual auto-renewable subscriptions at the same service level.
- Keep Lifetime, one-time products, non-renewing subscriptions, introductory/code/ad-hoc/win-back
  offers, and Family Sharing absent.
- Copy the fixture only into the unit-test bundle. The app target and Archive must not contain it.
- Keep the default shared scheme free of StoreKit Configuration. Add a dedicated Debug/local scheme
  that activates the fixture and cannot Archive.
- Add a same-code-path static validator plus StoreKitTest/JSON tests for identifiers, durations,
  group membership, exact bilingual local-test disclaimers, synthetic local prices/billing plans,
  the CHN/`zh_CN` default test environment, and forbidden catalog content. This default improves
  China-team test coverage but does not accept a launch storefront or customer price.

### Tests

- `Scripts/check-storekit-test-catalog.sh`
- `Scripts/storekit_catalog_contract.py` plus
  `Scripts/tests/test_storekit_catalog_contract.py` under Python `unittest`.
- `StoreKitTestCatalogTests`
- Default-scheme build-for-testing plus the complete repository validation suite.

### Stop conditions

- Stop if an accepted identifier/reference/group is missing or duplicated.
- Stop if the fixture enters the app resource phase, the default scheme, or an Archive-capable
  scheme.
- Stop if any Lifetime, formal offer, customer price/trial promise, purchase UI, entitlement
  authority, or App Store Connect product is introduced.

## C2-02 — Runtime catalog and entitlement store

Status: **Done** after independent review, green CI, and merge through PR #29 (`a45d480`).

### Tasks

- Add the app-owned StoreKit product catalog and actor-isolated entitlement lifecycle authority.
- Treat any cache as presentation-only; current verified StoreKit state remains authoritative.
- Own exactly one lifecycle-scoped `Transaction.updates` task.

### Tests

- Product-load failure, launch reconciliation, concurrent reads, lifecycle ownership, and
  presentation-cache isolation.
- Exercise runtime product loading under the committed CHN storefront and at least one non-CHN
  StoreKit test storefront so currency/locale behavior is not inferred from one environment.
- The two storefront-loading tests are enabled only by `MindBudget-StoreKit-Local` and run from
  Xcode's test action, because StoreKit Configuration activation belongs to that scheme's Run/Test
  session. Default-scheme CI runs the deterministic catalog/cache/lifecycle tests and must not
  claim that skipped local StoreKit-product tests passed. The probe opt-in remains explicit on the
  Test action with `shouldUseLaunchSchemeArgsEnv="NO"`; inheriting the Run environment is not
  evidence because it can silently skip both probes.

### Stop conditions

- Stop before purchase, restore, paywall, formal product creation, or price/trial decisions.

## C2-03 — Purchase, restore, and status mapping

Status: **Implementation complete, pending independent review.**

### Entry gate

- Satisfied on 2026-08-13: final Xcode 26.6 `17F113` ran the dedicated
  `MindBudget-StoreKit-Local` scheme on the physical `拉沙的iPhone` (`iPhone Air`) with final
  iOS 26.6.1 `23G82`. The run completed 5 passed, 0 failed, 0 skipped, and both the CHN and USA
  `Product.products(for:)` probes passed with the committed local StoreKit configuration. In
  short: both the CHN and USA `Product.products(for:)` probes passed.
  Evidence: `/private/tmp/MindBudget-C2-03-Physical-Unlocked-iOS26.6.1-17F113.xcresult`.
- `SKInternalErrorDomain Code=3`, an empty catalog, or a skipped probe is non-evidence and blocks
  entry. Record the Xcode build, device/runtime, execution surface, and result bundle/log path.
- Historical non-pass evidence (2026-08-13): final Xcode 26.6 `17F113` executed both probes on final iOS 26.4
  and 26.5 runtimes, but both returned `Code=3` and empty products while `storekitd` reported an
  Octane entitlement/development-install handshake failure. The final SDK is build `23F81a`, the
  installed iOS 26.5 runtime is `23F77`, and Apple's currently offered export was the older
  `23F73` runtime; it was not imported and could not replace it. Direct queries for build `23F81`
  and iOS `26.5.1` returned unavailable. The same 16 tests in 2 suites pass on iOS 27 beta only
  as diagnostic evidence. These historical results are retained and were not used as the accepted
  entry proof.
- A post-restart recheck after globally selecting final Xcode `17F113` removed the earlier
  auxiliary `xcrun`/`simctl` lookup error, but both CHN/USA probes still executed and failed with
  `Code=3` and empty products on iOS 26.5 `23F77`. Global toolchain selection is therefore closed;
  it did not satisfy or replace the supported-final-runtime entry gate. The later physical-device
  result above is the accepted evidence that opened C2-03.

### Tasks

- Implemented one actor-owned `EntitlementStore` lifecycle authority. Its one lifecycle task
  supervises both `Transaction.updates` and `Product.SubscriptionInfo.Status.updates`; this does
  not create a second authority or UI. A status signal triggers a fresh full reconciliation and
  never grants or revokes access directly. The actor also owns the status mapper, whole-snapshot
  entitlement publication, purchase/restore operation serialization, unfinished-transaction
  processing, and in-process finish deduplication.
- Contract: one lifecycle task supervises both `Transaction.updates` and `Product.SubscriptionInfo.Status.updates`.
- Contract: a status signal triggers a fresh full reconciliation through the same authority.
- Implemented typed explicit purchase and restore seams. Purchase verifies the accepted Product,
  maps verified success/pending/user-cancelled/unverified/error outcomes, and grants nothing from
  pending or unverified input. Restore calls `AppStore.sync()` only from the explicit typed seam.
- Implemented authoritative publish-before-`Transaction.finish()`: a handled transaction is
  merged with a fresh current/status read, mapped, and published before acknowledgement. A
  failed finish remains unfinished in StoreKit, is not reported as success, and is eligible for a
  later lifecycle retry; concurrent duplicate delivery cannot finish the same transaction twice.
- Consume the raw revocation and expiration facts retained by C2-02. Only C2-03 may map them with
  verified StoreKit status transaction and renewal information; expiration alone never infers
  billing grace. Subscribed and verified grace grant Pro. Billing retry, expired, revoked,
  unknown, unverified, and pending input grant no new right.
- `AppSession` exposes typed seams for later C3 purchase presentation, but no current view calls
  them. Stop before paywall presentation, formal product creation, formal customer price/trial,
  versioning, Archive, upload, tester assignment, or distribution.

### Tests

- Deterministic lifecycle tests cover subscribed/grace grant versus retry/expired/revoked/
  unknown/unverified denial; pending/cancel/error; explicit restore outcomes; publish-before-
  finish; duplicate/concurrent delivery; operation serialization; failed-finish retry; and
  unfinished startup processing. The listener contract covers transaction and subscription-status
  signals converging on the same fresh whole-authority reconciliation path.
- The dedicated StoreKit configuration surface contains opt-in Monthly/Annual transaction-
  verification-and-finish probes. `SKTestSession.buyProduct` seeds the transaction because a
  hosted unit-test process has no purchase-confirmation UI anchor; C3 owns presented
  `Product.purchase()` evidence. Final execution of the strengthened probes is pending device
  reconnection and must not be borrowed from an earlier assertion set.
- Billing-grace/retry behavior is covered by the deterministic verified-state matrix. A physical
  forced-renewal experiment terminated the hosted test runner before a result, so it was removed
  rather than retained as a flaky or false-green probe. A stable StoreKit transition probe remains
  required in a later owning UI/runtime packet; C2-01's catalog fixture proves no lifecycle state.

### Local validation evidence

- Focused lifecycle/runtime tests passed 44/44. The 31-test lifecycle suite passed 10 consecutive
  iterations (310/310), including the transaction-ordering, restore-provenance, conflict, and
  finish-retry regressions.
- The strict 500 ms local Dashboard wall-clock signal passed 10/10 isolated iterations. The full
  shared-host run used the repository's existing switch to skip only that wall-clock signal while
  retaining the deterministic 10,000-row projection test.
- The final default-scheme run completed 342 Swift tests and 13 UI tests with zero failures; its
  xcresult summary is 355 total, 351 passed, 4 explicit opt-in StoreKit runtime probes skipped,
  and 0 failed. Every selected core file remains above the 85% coverage gate. Evidence:
  `/private/tmp/MindBudget-C203-Full-Final15.xcresult`.
- This local evidence does not replace the pending independent review, green CI, merge, dedicated
  device probes, presented `Product.purchase()` evidence, or later stable StoreKit transition
  evidence.

### Stop conditions

- The local full-validation gate is satisfied. Keep C2-03 not Done until independent review,
  green CI, and merge. C2-04 and
  C3 remain blocked; the post-0.9.6 release hold remains active.
- Stop before customer-facing paywall presentation or unaccepted commercial terms.

## C2-04 — Environment and regression gate

### Tasks

- Prove Configuration, Sandbox, TestFlight, and Production state cannot contaminate one another.
- Prove catalog failure never erases a separately verified entitlement.

### Tests

- Complete `STOREKIT_TEST_MATRIX.md`, full Free regression, and retained distribution hold.

### Stop conditions

- COM-C2 is not Done until every environment/state row has objective evidence.
