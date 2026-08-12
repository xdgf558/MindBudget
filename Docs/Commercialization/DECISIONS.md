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
  leaves no residual paid state. Set containment is named `isSuperset(of:)`, while exact Free
  detection uses `isFree`, so `.free` cannot be mistaken for a singleton membership query. Tests
  require the union of every reachable paid singleton to equal the complete known version-1 bit
  mask. Migration dispatches by stored version so a future version can preserve explicit older
  branches instead of replacing them with an equality check. Subscribed and grace fixtures only
  name the shared domain right; the production StoreKit status mapper remains owned by COM-C2.
  C1-02 remains the only owner of feature-access decisions and injection.
- Alternatives rejected: `OptionSet(rawValue:)` exposed to feature code; direct `Codable`
  synthesis for the authority type; silently retaining known rights from a representation that
  also contains unknown bits; adding Lifetime/Connect placeholders; Product IDs in the domain;
  or implementing `FeatureAccessService` ahead of C1-02.

## DEC-COM-013 — Centralize paid access in an immutable session-owned snapshot

- Status/date: **Accepted — 2026-08-11**
- Requirements: REQ-ENTITLEMENT-001
- Decision: C1-02 adds one pure `FeatureAccessService` implementing the `FeatureAccessChecking`
  protocol. It evaluates a closed `PremiumFeature` against one immutable `EntitlementSet`
  snapshot. `AppEnvironment` constructs exact Free by default and `AppSession` owns the injected
  authority; consumers receive only `FeatureAccessDecision`. An arbitrary-combination provider is
  compiled only under `#if DEBUG`, is immutable, and has no persistence or process-argument path.
  Commerce is the production authority chokepoint: only it may construct
  `FeatureAccessService` with an entitlement snapshot or declare/refine a
  `FeatureAccessChecking` implementation. App consumers may use the exact-Free no-argument
  service and injected protocol values, but cannot originate a paid snapshot or unconditional
  provider.
- Consequences: All current premium candidates require the sole Release-reachable
  `.proSubscription` right, and the exhaustive feature switch forces every later vocabulary case
  to choose a requirement explicitly. Concurrent reads cannot observe partial mutation. Static
  validation rejects raw `version1Bits`/`version1KnownBits` consumers, duplicate subscription
  checks, persisted/manual authority, StoreKit imports during COM-C1,
  `isSuperset(of: .free)`, and `EntitlementSetMigrator` calls outside its domain file. The latter
  prevents a stored representation from silently becoming a second Release authority before
  COM-C2 explicitly owns and reviews that path. Static validation additionally rejects an
  entitlement-bearing `FeatureAccessService` construction or a `FeatureAccessChecking`
  implementation/refinement outside Commerce, closing source paths such as the reachable-right
  inventory without endlessly enumerating every API that can return an `EntitlementSet`. The
  DEBUG, constructor, and conformance parsers prove safe and unsafe classifications with built-in
  fixtures before scanning app source. Exact Free classification remains `isFree`. C1-03 may
  integrate only owner-approved existing entries after C1-02 review and merge.
- Alternatives rejected: Feature-local booleans; product-ID or billing checks in views; a global
  mutable singleton; UserDefaults/process arguments as entitlement authority; a Release manual
  unlock; permissive error fallback; or implementing StoreKit/paid UI in C1-02.

## DEC-COM-014 — Integrate only accepted existing advanced entries before StoreKit

- Status/date: **Accepted — 2026-08-11**
- Requirements: REQ-ENTITLEMENT-001
- Decision: C1-03 treats three already-implemented capabilities as the accepted existing Pro
  candidates: Apple on-device wording enhancement, cooling-off durations other than the basic
  24-hour period, and advanced Siri/App Entity actions. They consume an immutable
  `ExistingPremiumEntryAccess` built by Commerce from the single injected access authority. Exact
  Free retains complete deterministic Ask/reminder/summary templates, the 24-hour cooling-off
  flow, and basic Siri expense recording and budget-impact checking. The existing five-item
  wishlist and 30-day local Insights remain the Free baseline; their future unlimited/advanced
  variants are separate features and are not invented in C1-03.
- Consequences: Apple AI controls are hidden when unavailable, while template Ask remains visible.
  New or changed non-24-hour cooling choices are unavailable under exact Free, but a legacy stored
  value may remain readable without destructive rewriting. Passive App Entity providers return an
  empty set under unavailable/exact-Free access because they are system-initiated queries; active
  advanced Siri actions return neutral localized “not available yet” copy and never purchase/price
  language. Static validation rejects direct
  feature decisions outside Commerce, feature-local Product-ID/`isPro`/`isPremium`/manual-unlock
  state, StoreKit imports, and the earlier authority bypasses. There is no paywall, Pro badge,
  StoreKit product, transaction, price, trial, schema, network channel, or production unlock. The
  already-uploaded 0.9.6 binary remains unchanged; C1-03 and later source must not be archived or
  distributed until verified purchase/restore, purchase presentation, and the owning release gates
  are complete, so users never receive a build that removes a capability with no restoration path.
- Alternatives rejected: Gating all Siri actions; making the current wishlist or 30-day Insights
  paid; deleting legacy cooling values; leaving Apple AI controlled only by its historical user
  setting; or adding purchase presentation before COM-C2/C3.

## DEC-COM-015 — Isolate the first StoreKit catalog as local test infrastructure

- Status/date: **Accepted — 2026-08-11**
- Requirements: REQ-STOREKIT-LIFECYCLE-001
- Decision: C2-01 commits exactly one Xcode StoreKit Configuration fixture with the accepted Pro
  Monthly and Pro Annual identifiers, reference names, durations, and shared `MindBudget Pro`
  group. The fixture is copied only into `MindBudgetTests`, while a dedicated Debug/local scheme
  activates it and explicitly cannot Archive. The default scheme and app resource phase remain
  free of the fixture. The fixture defaults to CHN/`zh_CN` and pins exact synthetic prices,
  billing-plan values, and bilingual local-test disclaimers. Those values are test data only; they do
  not establish customer price, trial, offer, quota, storefront, or formal App Store Connect
  metadata.
- Consequences: StoreKit catalog shape can be reviewed and exercised before cost-dependent terms
  are accepted. A static same-code-path validator and StoreKitTest/JSON tests reject an unknown or
  duplicate identifier, Lifetime, Family Sharing, offers, wrong duration/service level, app-bundle
  embedding, default-scheme activation, or an Archive-capable local scheme. Its project/scheme
  checks are format-independent. The Shell entry remains a thin wrapper around an importable
  Python contract, and standard `unittest` accepted/rejected fixtures exercise the same functions
  before the real files, so an Xcode multiline project rewrite cannot make app-resource isolation
  fail open or later C2 growth turn into an unlintable embedded heredoc.
  Runtime StoreKit product
  loading, transactions, purchase/restore, entitlement authority, and paywall remain later C2/C3
  packets; those packets must cover CHN plus a non-CHN StoreKit test storefront and inject billing
  grace through their lifecycle-test owner. Distribution remains paused.
- Official evidence: Apple's
  [StoreKit Configuration guidance](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode/)
  documents local configuration before App Store Connect products and scheme-based activation;
  Apple's [SKTestSession documentation](https://developer.apple.com/documentation/storekittest/sktestsession)
  is the test-session boundary used by the focused fixture tests.
- Alternatives rejected: Creating formal products before the economics gate; embedding a local
  configuration in the app/Archive; activating it in the default scheme; adding Lifetime or a
  placeholder offer; or treating synthetic fixture values as customer terms.

## DEC-COM-016 — Make verified current StoreKit state the sole runtime paid authority

- Status/date: **Accepted — 2026-08-12**
- Requirements: REQ-STOREKIT-STATE-001, REQ-STOREKIT-LIFECYCLE-001
- Decision: C2-02 adds one typed runtime catalog containing only the accepted Monthly and Annual
  identifiers and one actor-owned entitlement lifecycle. Product display name, description, price,
  and subscription period come from `Product`; a deletable cache may retain only that presentation
  snapshot under an exact StoreKit environment plus storefront key. Paid access is derived only
  from a fresh `Transaction.currentEntitlements` read. One lifecycle-scoped
  `Transaction.updates` listener treats an update only as a signal to re-read current state; it
  never trusts the update as authority. A process-local locked bridge replaces whole immutable
  access snapshots so existing synchronous UI and App Intent consumers observe the same authority.
  C2-02 preserves verified ownership, revocation, and expiration as raw current-entitlement facts;
  it rejects revoked transactions but does not reject a record merely because its last renewal
  expiration is in the past. C2-03's status mapper is the sole owner of subscribed/grace/retry/
  expired semantics and transaction finishing.
- Consequences: Missing, unverified, unknown-product, unknown-environment, or mixed-environment
  authority input fails closed to exact Free. Product-loading or presentation-cache failure never
  erases a separately verified entitlement, and cached presentation can never grant one. Repeated
  SwiftUI lifecycle starts do not create another listener or catalog refresh. Delete All clears the
  presentation cache. Runtime CHN and USA product loading is isolated to the dedicated local Xcode
  StoreKit scheme; the default scheme runs deterministic catalog/cache/lifecycle tests and does not
  claim skipped local-configuration tests passed. The installed Xcode 26.6 RC `17F109`/iOS 26.5
  command-line environment currently produces `SKInternalErrorDomain Code=3` and empty catalogs,
  and that historical failure remains part of the evidence record. Post-merge revalidation with
  final Xcode 26.6 `17F113` executed both CHN/USA probes on final iOS 26.4 and 26.5 runtimes, but
  again produced `Code=3`/empty products while `storekitd` reported an Octane entitlement/
  development-install handshake failure. Final Xcode's SDK is build `23F81a`, the installed 26.5
  runtime is `23F77`, and Apple's offered export was the older `23F73`; it was not imported and
  could not replace the installed runtime. Direct download queries for build `23F81` and iOS
  `26.5.1` both returned unavailable.
  The same 16 tests in 2 suites passing on iOS 27 beta is diagnostic only. C2-03 therefore cannot
  begin until both storefront probes execute and pass under a supported final Xcode/runtime
  surface. Purchase, restore, transaction finishing,
  pending/cancel handling, subscription-status mapping, customer pricing/trial terms, paywall,
  formal App Store Connect products, and distribution remain blocked by C2-03/C2-04 and later
  release gates.
- Alternatives rejected: Persisting an entitlement bit or migrated entitlement representation as
  Release authority; granting from a cached Product; one update listener per view/scene; trusting
  an update payload without current-state reconciliation; silently accepting an unknown Product ID
  beside a known one; hardcoding customer-facing price or trial copy; or enabling purchase/restore
  ahead of their owning packet.
