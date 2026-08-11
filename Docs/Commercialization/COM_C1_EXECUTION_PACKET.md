# COM-C1 Execution Packet — Entitlement Model and Feature Access

## Input gate

COM-C1 may start only when all of the following are true:

- COM-C0B is Done and `Scripts/check-commercialization-docs.sh` plus the existing validation
  commands pass.
- `REQ-ENTITLEMENT-001` is Active with no `BLOCKED_BY_SPEC` dependency.
- Product IDs remain exactly `com.xdgf558.mindbudget.pro.monthly` and
  `com.xdgf558.mindbudget.pro.annual` for future mapping tests; COM-C1 does not import StoreKit or
  create either product.
- Free iCloud is explicitly excluded from premium features. Local Lifetime and every unapproved
  future entitlement bit are unreachable.

Each packet below is an independently reviewable commit/PR. Do not combine StoreKit, paywall,
schema migration, backend, telemetry, CloudKit, receipt, Watch, or cloud-AI work with COM-C1.

## C1-01 — Pure entitlement domain

### Inputs

- `REQ-ENTITLEMENT-001` and DEC-COM-002/005/006.
- Existing `FeatureFlags` remain product-scope build gates, not paid rights.

### Tasks

- Add a pure, `Sendable` `EntitlementSet` value whose union/removal semantics are deterministic.
- Add a closed `PremiumFeature` vocabulary containing only owner-approved reachable COM-C1 seams.
- Add explicit versioned migration functions for entitlement representations even if v1 begins
  empty; unknown/deferred bits fail closed.
- Keep Product IDs outside view/feature code. Domain fixtures may map accepted technical IDs only
  in tests or a later StoreKit adapter boundary.

### Tests

- Empty/Free, subscription, grace, removal, union idempotence/commutativity, duplicate input,
  unknown bit, version migration, and exact Free fallback.
- Parameterized proof that Free manual records, export, Delete All, Face ID, and opt-in iCloud are
  never premium-gated.
- Compile/static proof that Local Lifetime and deferred future bits cannot be constructed through
  a reachable Release API.

### Stop conditions

Stop on an ambiguous feature tier, a Product-ID check in a view, a persisted entitlement without
a migration contract, a manual Release unlock, or any proposal to make Free iCloud premium.

## C1-02 — Central feature-access service and injection

### Inputs

- Merged C1-01 domain and green parameterized matrix.

### Tasks

- Add one pure `FeatureAccessService`/protocol boundary that answers access from an
  `EntitlementSet`; feature consumers never inspect products or billing state.
- Inject the service through `AppEnvironment`/session ownership with a deterministic Free default.
- Add a Debug-only provider for arbitrary valid combinations. Prove its symbols/state are absent
  from Release and never persist as production authority.

### Tests

- Full feature × entitlement matrix, concurrent/read consistency, Free default, removal back to
  exact Free, and Debug/Release compile boundary.
- Existing validation suite remains unchanged and green.

### Review checklist

- No feature-access or application path reads `version1Bits` or `version1KnownBits`; those values
  remain representation/test seams rather than feature authority.
- Exact Free checks use `isFree`. Never use `isSuperset(of: .free)`, because every entitlement set
  is mathematically a superset of the empty Free set.
- Subscription checks exist only in the central access service. Views and feature entry points do
  not repeat `.proSubscription` checks or inspect product/billing state.
- `EntitlementSetMigrator` remains callable only inside `EntitlementDomain.swift` and tests. A
  future COM-C2 authority adapter must explicitly narrow and review this allow-list before a
  stored representation may influence the session snapshot.
- App code outside Commerce may construct only the exact-Free no-argument
  `FeatureAccessService()`. Supplying an entitlement snapshot is an authority operation owned by
  Commerce, regardless of whether that set came from a literal, migrator, inventory, or later
  adapter.
- `FeatureAccessChecking` implementations and protocol refinements remain inside Commerce or test
  targets. Application consumers may hold the protocol existential, but cannot create an
  always-allowed provider outside the authority boundary.
- The arbitrary-combination provider is declared only under `#if DEBUG`, is immutable, and has no
  persistence, process-argument, or Release selection path. The static parser must first prove
  active-DEBUG acceptance and unguarded/`#else` rejection against built-in fixtures. Constructor
  and conformance parsers likewise prove safe-consumer acceptance and authority-bypass rejection
  before scanning app source.

### Stop conditions

Stop if access depends on UI state, UserDefaults as authority, network/StoreKit, scattered
booleans, a singleton with hidden mutable state, or a fallback that grants access on error.

## C1-03 — Existing-entry integration and audit

### Inputs

- Merged C1-02 service and accepted list of actual premium candidates. If the owner has not
  accepted a candidate, add no lock/paywall/Pro badge for it.

### Tasks

- Route only accepted candidate entry points through the central service.
- Keep unavailable paid work hidden or neutrally marked as not yet available; COM-C1 creates no
  purchase UI and no false promise.
- Run a repository audit for Product IDs, `isPro`/`premium` booleans, manual unlocks, and duplicate
  access checks; record every intentional result.

### Tests

- Free regression for record/edit/delete, export, Delete All, app lock, current local AI fallback,
  and approved iCloud seam.
- Paid candidate allow/deny tests through the service only; accessibility/localization for any
  user-visible state actually added.
- Release static scan finds no arbitrary entitlement provider or manual unlock.

### Stop conditions

Stop if a candidate requires StoreKit, price/trial copy, schema migration, a new network channel,
or an unaccepted Free/Pro product decision. Defer it to its owning phase rather than working ahead.

## COM-C1 exit gate

- All three packets are merged in order with separate review evidence.
- The reachable entitlement matrix is complete; subscription removal yields exact Free.
- There is one access authority, no Release manual unlock, no Product-ID check in feature/UI code,
  no StoreKit import, and no paid product/paywall.
- Money, commercialization-doc, full validation, localization/accessibility, and Release static
  gates pass; the commercial session log records evidence and unresolved debt.
