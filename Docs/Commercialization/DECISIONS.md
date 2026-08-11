# Commercialization Decisions

Status values: Proposed, Accepted, Rejected, Superseded. Only an Accepted decision is binding.
Every entry cites stable Requirement IDs and records consequences rather than relying on session
context.

## DEC-COM-001 — Phase-scoped future data channels

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-R1-NET-001, REQ-R1-TELEMETRY-001, REQ-ICLOUD-001,
  REQ-CLOUD-CONSENT-001, REQ-CLOUD-USAGE-001
- Decision: Existing versions and Phase 0–12 history remain unchanged. A later iCloud,
  first-party telemetry, or multi-provider cloud-AI channel may be enabled only after explicit
  authorization, privacy disclosure, deletion, and release gates for that channel pass.
- Consequences: Current local-only privacy claims remain accurate. Future rules may permit only
  named, allow-listed channels; no broad networking permission is created. Revoke/delete/offline
  behavior must be tested before release.
- Alternatives rejected: Retroactively rewriting existing-version claims; enabling a general
  network layer; or shipping a channel before disclosure/deletion evidence exists.

## DEC-COM-002 — Product family, identifiers, and deferred Lifetime

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-ENTITLEMENT-001, REQ-STOREKIT-LIFECYCLE-001,
  REQ-WATCH-ENTITLEMENT-001
- Decision: Formal launch contains Pro Monthly and Pro Annual in one `MindBudget Pro` subscription
  group. Technical IDs are `com.xdgf558.mindbudget.pro.monthly` and
  `com.xdgf558.mindbudget.pro.annual`; internal reference names are `MindBudget Pro Monthly` and
  `MindBudget Pro Annual`. Local Lifetime is deferred with no product, entitlement, UI, sale, or
  public promise.
- Consequences: StoreKit Configuration, app code, App Store Connect, Watch, backend validation,
  and tests must share the exact IDs. Product creation remains blocked by the economics gate.
  Customer-facing names are localized separately and do not change technical identifiers.
- Alternatives rejected: The specification's unowned `com.stationcat...` example; versioned IDs;
  embedding price in an ID; separate monthly/annual subscription groups; or a Lifetime placeholder.

## DEC-COM-003 — Three-stage price and cloud-economics gate

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-STOREKIT-LIFECYCLE-001, REQ-CLOUD-USAGE-001, REQ-G1-001
- Decision: COM-C2/3 may use configuration-only products and provisional test terms. Formal App
  Store Connect products and COM-C6 require accepted preliminary unit economics. G1 accepts final
  provider, quota/reset, price, retry/failover, and cost evidence before COM-C7.
- Consequences: Monthly/Annual prices, trial, included calls, reset boundary, and storefront
  availability remain TBD. No UI hardcodes price or claims unlimited cloud AI.
- Alternatives rejected: Waiting for final cloud economics before any StoreKit test; creating
  formal products before preliminary economics; or letting engineering choose prices.

## DEC-COM-004 — Watch development and release ordering

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-G1-001, REQ-WATCH-SCOPE-001, REQ-WATCH-SYNC-001,
  REQ-WATCH-ENTITLEMENT-001, REQ-WATCH-PRIVACY-001
- Decision: COM-C6.5 development may run in the intermediate parallel window after its
  prerequisites. It does not block G1, COM-C7, COM-C12, or the formal iPhone 1.0 launch. Watch
  distribution is a separate post-iPhone-1.0 milestone after all Watch-specific gates pass.
- Consequences: The first iPhone 1.0 must not advertise or accidentally bundle an unreleased Watch
  experience. Watch work cannot weaken iPhone reliability, privacy, or entitlement authority.
- Alternatives rejected: Requiring Watch before G1/iPhone 1.0; silently dropping Watch scope; or
  releasing the companion without its signed-device and outbox/idempotency evidence.

## DEC-COM-005 — Test users do not receive production rights

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-ENTITLEMENT-001, REQ-STOREKIT-STATE-001
- Decision: TestFlight, StoreKit Configuration, Sandbox, development providers, and promotional
  tests do not create permanent or free production Pro access. Production access comes only from
  verified Production StoreKit state and the accepted status mapper.
- Consequences: No email/tester allow-list, version check, migration flag, local cache, or manual
  Release switch may grandfather test access.
- Alternatives rejected: Permanent tester unlocks or inferring production rights from a historical
  test transaction.

## DEC-COM-006 — Free iCloud and local authority

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-ICLOUD-001, REQ-ENTITLEMENT-001
- Decision: Opt-in iCloud is available to Free and paid users and is not a premium entitlement.
  Local use remains available when sync is disabled, unavailable, over quota, or signed out.
- Consequences: COM-C4B must define stable IDs, tombstones, conflicts, environments, attachments,
  account transitions, and local/cloud deletion before implementation. No container is created in
  COM-C0B.
- Alternatives rejected: Pro-gating sync, implicit enablement, or letting sync failure block local
  budgeting.

## DEC-COM-007 — Provider-neutral cloud AI with consent-bound failover

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-CLOUD-CONSENT-001, REQ-CLOUD-USAGE-001, REQ-G1-001
- Decision: Cloud Coach is provider-neutral. Domestic and international candidates receive the
  same quality, privacy, contractual, regional, availability, and cost evaluation. Consent names
  the complete possible provider set; failover cannot route to an unconsented provider. Material
  provider/data-policy changes require renewed consent.
- Consequences: The server router is allow-listed and configuration-driven, but no provider is
  selected in COM-C0B. Local/template fallback is mandatory on denial, exhaustion, failure, or
  unsupported routing.
- Alternatives rejected: Single-provider lock-in; choosing solely by price; silent provider
  substitution; or sending raw ledger/receipt/note content.

## DEC-COM-008 — Independent hardened backend

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-R1-NET-001, REQ-R1-TELEMETRY-001, REQ-CLOUD-AUTH-001,
  REQ-CLOUD-USAGE-001
- Decision: A future backend may reuse engineering patterns from the owner's other Cloudflare
  service, but it is a new independent service with separate resources, data, secrets, bindings,
  admin authorization, deployment state, logs, limits, and deletion keys.
- Consequences: No cross-product credentials or data; dev/staging/prod separation; deny unknown
  endpoints/fields/IDs; rate/body/token/cost caps; content-free admin logs; and no entitlement
  override from the admin plane.
- Alternatives rejected: Reusing the existing service's database, secrets, admin session, Worker,
  or production deployment.

## DEC-COM-009 — Current Release egress is empty and future egress is allow-listed

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-R1-NET-001, REQ-R1-TELEMETRY-001
- Decision: The current app-owned HTTP(S) Release allow-list is empty. Apple system-framework
  channels and future app-owned endpoints require an explicit typed entry in
  `NETWORK_EGRESS_POLICY.md` before implementation; unknown egress fails closed.
- Consequences: COM-C0B adds policy/CI structure only. It does not add a URL, entitlement, SDK, or
  request. Each later entry specifies domain, endpoint, method, fields, consent, retention,
  failure default, environment, and owning Requirement.
- Alternatives rejected: Wildcard domains, arbitrary URL construction, provider URLs in the
  client, or treating TLS alone as approval.

## DEC-COM-010 — Enforce the empty egress baseline against source and Release configuration

- Status/date: **Accepted — 2026-08-10**
- Requirements: REQ-R1-NET-001, REQ-R1-TELEMETRY-001
- Decision: While the current app-owned Release allow-list is empty, validation scans all
  `MindBudget/**/*.swift` files for known app-owned networking primitives, networking framework
  imports, and quoted HTTP(S) literals. It also scans checked-in app property lists, entitlements,
  privacy manifests, xcconfig files, and generated-Info.plist build settings in the project file
  for ATS exceptions, network entitlements, associated domains, and HTTP(S) endpoint values. A
  later accepted channel may introduce only a narrow centralized adapter exception tied to its
  exact policy row; binary and captured-traffic review remain required at the release gate.
- Consequences: Adding a direct URL session or network client now fails CI even if documentation
  still says the app is local. StoreKit and CloudKit remain Apple-owned typed framework channels
  and are not falsely classified as app-owned HTTP. Full-line documentation comments and the
  standard property-list DTD do not create false positives; built-in positive/negative samples
  fail the gate if those detection boundaries drift. The lexical gate is defense in depth, not a
  proof that arbitrary source or configuration cannot conceal networking.
- Alternatives rejected: Checking policy prose only, granting a directory-wide exception, or
  treating source scanning as a substitute for final binary and traffic evidence.

## DEC-COM-011 — Keep the detailed source external and make SHA semantics explicit

- Status/date: **Accepted — 2026-08-10**
- Requirements: all v1.4-derived commercial Requirements
- Decision: The owner's detailed commercialization specification remains outside the public
  repository. `SOURCE_PROVENANCE.md` records its audited filename, SHA-256, byte length, date,
  derived repository snapshot, and mandatory stop/re-audit procedure. CI reads that single lock
  and checks internal snapshot consistency; it does not claim to monitor an external file it
  cannot access.
- Consequences: A replacement source must be supplied explicitly, rehashed, semantically diffed,
  and accepted before affected work continues. The public repository does not expose the private
  detailed specification merely to make an impossible CI drift claim.
- Alternatives rejected: Committing the full owner specification to the public repository,
  duplicating the hash as an unanchored script constant, or claiming automatic external drift
  detection.

## DEC-COM-012 — Make the first Release entitlement domain closed and version-migrated

- Status/date: **Accepted — 2026-08-11**
- Requirements: REQ-ENTITLEMENT-001
- Decision: C1-01 represents Free as the empty `EntitlementSet` and exposes only one constructible
  paid singleton, `proSubscription`. `EntitlementSet` is not directly `Codable`; persistence or
  transport must use `EntitlementSetRepresentation` with an explicit version and
  `EntitlementSetMigrator`. Strict migration rejects unknown bits and unsupported versions, while
  the boundary's safe resolver returns exact Free. Local Lifetime, Connect, and other deferred
  rights have no Release-domain symbol or constructor. `PremiumFeature` contains the approved
  subscription-reachable vocabulary but performs no access decision in C1-01. Manual records,
  CSV export, Delete All, app lock, and opt-in iCloud are separately typed Free invariants.
- Consequences: Duplicate/union/removal behavior is deterministic; removing the subscription
  leaves no residual paid state. A future entitlement representation requires a new accepted
  version migration instead of interpreting a raw unknown bit. Subscribed and grace fixtures both
  expect the same subscription right, but the production StoreKit status mapper remains owned by
  COM-C2. C1-02 remains the only owner of feature-access decisions and injection.
- Alternatives rejected: `OptionSet(rawValue:)` exposed to feature code; direct `Codable`
  synthesis for the authority type; silently retaining known rights from a representation that
  also contains unknown bits; adding Lifetime/Connect placeholders; Product IDs in the domain;
  or implementing `FeatureAccessService` ahead of C1-02.
