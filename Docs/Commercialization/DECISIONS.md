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
  The same 16 tests in 2 suites passing on iOS 27 beta is diagnostic only. That condition was
  satisfied on 2026-08-13 when final Xcode 26.6 `17F113` ran the dedicated scheme on a physical
  iPhone Air with final iOS 26.6.1 `23G82`: 5 passed, 0 failed, 0 skipped, including passed CHN
  and USA probes. C2-03 may therefore begin, but no later gate is waived. Purchase, restore,
  transaction finishing,
  pending/cancel handling, subscription-status mapping, customer pricing/trial terms, paywall,
  formal App Store Connect products, and distribution remain blocked by C2-03/C2-04 and later
  release gates.
- Alternatives rejected: Persisting an entitlement bit or migrated entitlement representation as
  Release authority; granting from a cached Product; one update listener per view/scene; trusting
  an update payload without current-state reconciliation; silently accepting an unknown Product ID
  beside a known one; hardcoding customer-facing price or trial copy; or enabling purchase/restore
  ahead of their owning packet.

## DEC-COM-017 — Keep one StoreKit lifecycle authority and finish only after authoritative publish

- Status/date: **Accepted and implemented — 2026-08-13; C2-03 merged through PR #30 as
  `3fc72b4` after independent review and green CI**
- Requirements: REQ-STOREKIT-STATE-001, REQ-STOREKIT-LIFECYCLE-001
- Decision: C2-03 keeps `EntitlementStore` as the single process-local StoreKit authority. The
  StoreKit adapter supplies verified transaction, status-transaction, renewal-info, ownership,
  Product ID, environment, revocation, and expiration facts; `SubscriptionStatusMapper` is the
  sole interpreter. Subscribed and verified billing grace grant the Pro subscription right.
  Billing retry outside grace, expired, revoked, unknown, unverified, pending, incomplete-free,
  mixed-environment, and unknown-product input grant no new right. Expiration alone never infers
  grace. Purchase and restore are explicit typed seams: purchase maps verified success, pending,
  user cancellation, unverified, unavailable-product, disallowed-payment, and neutral failure;
  restore alone may call `AppStore.sync()` and distinguishes restored, no active subscription, and
  failure. No launch or current view invokes either seam.
- Lifecycle supervision: The authority starts one lifecycle task that supervises both
  `Transaction.updates` and `Product.SubscriptionInfo.Status.updates`. Transaction signals may
  carry a verified finishable transaction; a subscription-status signal carries no authority and
  only triggers a fresh full reconciliation through the same actor. This is not a second mapper,
  authority, or UI surface.
- Consequences: Before any handled verified transaction is acknowledged, the actor merges it with
  a fresh current/status read, resolves one actionable whole snapshot, publishes that snapshot
  to the central access authority, and only then calls `Transaction.finish()`. Duplicate and
  concurrent delivery is serialized and deduplicated in process. A failed finish is not reported
  as purchase success and is not added to the finished-ID set; StoreKit keeps it unfinished so a
  later startup/update lifecycle pass can retry. `Actionable` means safe to use, not that every
  presentation/catalog input was complete: a separately verified paid fact may remain actionable
  during a supplemental catalog failure, while incomplete Free or unverified authority fails
  closed. Unverified or non-actionable input is never
  finished merely to clear a queue. `Transaction.unfinished`, `Transaction.updates`, current
  entitlements, subscription-status updates, and subscription-status reads all feed the same actor
  rather than independent feature decisions. No entitlement representation is persisted as
  authority.
- Restore boundary: C2-03, not C2-04, owns the typed restore lifecycle. The post-`AppStore.sync()`
  transaction-signal bridge is retained even before a View calls it because StoreKit may deliver a
  verified restored transaction before `currentEntitlements` catches up. Removing it would make
  the later C3 UI depend on timing and could report no purchase after a valid restore. The bridge
  is provenance-scoped: only a completed verified transaction signal may satisfy it; status-only
  or foreground refreshes cannot, and newer revocation/unverified authority rejects stale facts.
  C2-04 remains the Configuration/Sandbox/TestFlight/Production isolation gate rather than the
  first implementation owner of restore.
- Concurrency proof: The actor records one consolidated invariant block beside its three
  coordination mechanisms: reconciliation generations order whole-snapshot publication; one
  active transaction batch owns acknowledgement identities and finishes only after actionable
  publication; transaction-signal sequencing records restore provenance rather than authority;
  and all waiters are resumed on completion or stop. Deterministic tests inject gates at publish,
  finish, sync, and active-batch waiting points. Repeating the 31-test suite 10 times is stability
  evidence in addition to those controlled interleavings, not a substitute for them.
- Release boundary: This decision accepts only the programmatic lifecycle seams and their Apple-
  managed StoreKit transport. It creates no paywall, visible Pro purchase/restore UI, formal App
  Store Connect product, customer price/trial/offer, version bump, Archive/upload/tester action, or
  distribution permission. C2-03 completed independent review, green CI, and merge through PR #30
  as `3fc72b4`. C2-04 subsequently completed its environment isolation gate through PR #31 as
  `a293762`; all later release gates remain mandatory and the post-0.9.6 distribution hold remains
  active.
- Alternatives rejected: Finishing before actionable publication; granting from a purchase
  result without verified status and renewal information; treating expiration as grace; implicit
  restore on launch; persisting a paid bit/cache as authority; allowing each view to own a
  listener or mapper; swallowing a failed finish as success; deleting the C2-03 restore bridge and
  deferring its first implementation to the C2-04 environment gate; or exposing a paywall before
  C3 and accepted commercial terms.

## DEC-COM-018 — Bind StoreKit authority to the separately verified app environment

- Status/date: **Accepted and implemented — 2026-08-13; C2-04 and COM-C2 completed through
  PR #31 as `a293762` after independent review and green CI**
- Requirements: REQ-STOREKIT-STATE-001, REQ-STOREKIT-LIFECYCLE-001
- Decision: `AppTransaction.shared` is the whole-read environment authority. Its verified bundle
  identifier must match the app bundle, and its environment must be exactly Xcode, Sandbox, or
  Production. Every verified transaction/status fact in the read must carry the same recognized
  environment and expected app bundle before the mapper may act. StoreKit's environment is
  authoritative; Debug/Release, scheme name, or a manually supplied TestFlight flag cannot select
  an entitlement environment. Per Apple, TestFlight purchases are Sandbox.
- Consequences: Xcode Configuration can authorize only Xcode, Sandbox/local development/TestFlight
  can authorize only Sandbox, and App Store Production can authorize only Production. A missing or
  unverified app transaction, wrong bundle, unknown environment, or mismatch fails closed.
  Purchase and explicit restore reject before StoreKit action when the app environment cannot be
  verified; purchase result preflight obtains that environment independently from the source and
  never derives it from the transaction under review. Presentation caching remains keyed by exact
  environment plus storefront and never grants access. When app environment verification is
  unavailable, the presentation layer may use an explicit `Unknown` partition to show metadata,
  but entitlement reads and access decisions never accept it. Supplemental Product/catalog failure
  may leave an independently verified active subscription actionable, while incomplete Free
  remains failed closed.
- Enforcement: `AppTransaction.shared` has one Commerce-owned reader in `StoreCatalog.swift`.
  Static validation rejects another app-owned reader or construction of `StoreEntitlementRead`
  outside `EntitlementStore.swift`. Unit tests accept all three exact environments and reject
  cross-environment, missing-environment, and wrong-bundle cases. Focused, full Free regression,
  strict local performance, and coverage gates passed. PR #31 passed independent review and green
  CI and merged as `a293762`, making C2-04 and COM-C2 Done.
- Release boundary: No customer UI, paywall, formal product, price, trial, offer, version,
  Archive/upload, tester assignment, app-owned HTTP(S), or distribution permission is added. C3
  remains blocked and the post-0.9.6 release hold remains active.
- Alternatives rejected: Inferring Production from Release; treating TestFlight as a fourth
  authority environment or as Production; accepting a transaction's self-selected environment
  without a separately verified app transaction; cross-environment presentation cache; or a
  persisted/manual environment unlock.

## DEC-COM-019 — Use provisional test terms without creating a final price promise

- Status/date: **Accepted for C3-01 test presentation — 2026-08-14**
- Requirements: REQ-STOREKIT-LIFECYCLE-001
- Decision: The C3-01 nonpublic test configuration uses US$1.99 Monthly, US$19.99 Annual, and one
  P1W free-trial offer for StoreKit-eligible subscribers. Initial runtime/storefront evidence
  covers HKG, USA, SGP, and TWN. The exact P1W offer is a local fixture/test assertion only, not a
  production catalog or entitlement requirement. Production validates stable product identity,
  type, period, Family Sharing state, and subscription group; an introductory offer is optional
  StoreKit-owned presentation data. Customer UI renders StoreKit `displayPrice`, subscription
  period, actual offer duration, and verified introductory-offer eligibility; source code and
  localized strings do not hardcode a currency display or promise a trial to an ineligible
  subscriber. Removing or changing a promotion can never invalidate an otherwise verified paid
  entitlement.
- Introductory-offer boundary: C3-01 supports customer purchase only when a freshly eligible
  introductory offer is StoreKit `.freeTrial`, or when no offer applies to that account. The
  presentation model retains StoreKit's full payment-mode raw value and localized offer
  `displayPrice`. An eligible `.payAsYouGo`, `.payUpFront`, or future unknown mode pauses the
  product in both the View and the StoreKit purchase adapter so the app cannot substitute standard
  renewal terms for a paid introductory schedule. This presentation guard never participates in
  entitlement validation, so changing a promotion cannot remove verified Pro access.
- Purchase-authority boundary: A live catalog does not prove that the current entitlement read is
  trustworthy. An `.unavailable` subscription snapshot pauses purchase in both the customer View
  and `EntitlementStore.purchase`, exposes an explicit recheck action, and never aliases uncertainty
  to confirmed Free. The actor performs a fresh actionable-authority preflight before invoking
  StoreKit and retains the existing authoritative post-purchase reconciliation.
- Locale boundary: Renewal disclosure selects and formats localized copy with the SwiftUI
  app-selected locale. It never falls back to `Locale.current` or a process-global
  `NSLocalizedString` lookup when the person selected another in-app language.
- Presentation boundary: The paywall is voluntary. It may open from Settings or an explicit Pro
  value trigger only; C3-01 has zero automatic/interrupting presentations. Purchase, restore, and
  manage-subscription operations require explicit taps and continue through the single C2
  lifecycle authority. Cached or unavailable presentation never invents a price or trial.
- Product boundary: Customer copy names only shipped paid value: Apple on-device wording
  enhancement, non-24-hour cooling-off choices, and advanced Siri actions. It must not promise
  Lifetime, cloud AI/quota, Watch, iCloud, receipt capture, telemetry, or another deferred item.
- Release boundary: These values are provisional Configuration/Sandbox/TestFlight evidence, not
  final regional economics or authorization to create formal App Store Connect products, Archive,
  upload, assign testers, or distribute. The post-0.9.6 release hold remains active.
- Alternatives rejected: Hardcoded `$` UI; app-owned currency conversion; making production paid
  authority depend on an exact promotional offer; advertising a trial without StoreKit
  eligibility; treating `.unavailable` as Free for purchase; device-locale renewal copy inside an
  app-locale screen; presenting a paid introductory offer as an ordinary subscription; automatic
  paywall presentation; implicit restore; adding Lifetime or deferred product promises; or
  treating a test anchor as final launch pricing.

## DEC-COM-020 — Derive trial lifecycle from verified StoreKit facts and keep reminders generic

- Status/date: **Accepted and implemented; C3-02 Done through PR #34 (`12d9217`) — 2026-08-14**
- Requirements: REQ-STOREKIT-LIFECYCLE-001
- Decision: An active trial lifecycle exists only when the accepted, app-environment-matched,
  verified current transaction identifies an introductory free trial and the same verified
  subscription chain supplies verified renewal information. `Transaction.offer` proves that the
  current transaction is a free trial; verified `renewalDate` and `willAutoRenew` provide the
  lifecycle facts. `RenewalInfo.offer` is not required because Apple defines it as an offer for
  the next renewal period and it may be nil after a one-period trial. Presentation eligibility,
  cached catalog metadata, and the configured P1W fixture can never activate or preserve this
  projection. The projection remains process-local and is published with the existing immutable
  entitlement snapshot.
- Product identity: Preserve the accepted `currentProductID` as the product carrying the active
  trial, but use an accepted nonnil `autoRenewPreference` as the next-renewal product. If StoreKit
  omits that preference, fall back to the current product. Keeping both identities in the
  projection makes a scheduled same-group plan switch observable even when the renewal date is
  unchanged and prevents disclosure from showing the old plan's standard price.
- Reminder decision: Reconcile one stable pending local-notification identifier at five user-
  calendar days before a reliable future renewal date. Use the person's `Calendar` and `TimeZone`,
  never fixed seconds. The notification is generic bilingual copy containing no renewal date,
  price, amount, product, remaining-day count, ledger content, or note. Because a pending request
  can fire while the app is terminated and cannot observe an App Store cancellation, it says the
  trial ends soon and asks the person to review current status; it never promises renewal. Remove the old request
  before replacement; trial end, auto-renew off, cancellation, refund/revocation, product switch,
  date change, missing authority, or missing/past date removes or replaces it.
- Consent and fallback: Lifecycle reconciliation reads notification authorization but never
  requests it. App notifications disabled, system denial/not-determined state, or a passed T−5
  window uses a noninterrupting in-app card. A missing reliable date schedules nothing. In-app
  renewal disclosure may show the verified date and only a current live StoreKit price; it never
  substitutes cached price.
- Ordering and failure: Notification-center mutations are serialized so an older add cannot land
  after a newer cancellation. Replacement removes the old request first; a failed add is visible
  as a neutral in-app failure and cannot leave stale reminder content pending.
- Evidence boundary: Pure tests prove projection consumption, failure closure, calendar
  scheduling, consent fallback, cancellation/replacement, generic copy, and failed-add cleanup.
  Only opt-in local StoreKit Monthly/Annual tests can exercise real `Transaction.offer`, verified
  renewal information, `renewalDate`, and `willAutoRenew` derivation. Construction-based unit
  coverage must not be cited as framework-bridge evidence.
- Release boundary: This adds no app-owned HTTP(S), formal App Store Connect product, final price
  or trial economics, notification auto-prompt, C3-03 configuration, version, Archive/upload,
  tester assignment, or distribution authorization. The post-0.9.6 release hold remains active.
- Closeout: PR #34 passed independent review and green GitHub Actions run `31803898776`, then
  merged as `12d9217` on 2026-08-14. This closes C3-02 only; C3-03 still requires an explicit
  owner instruction and an accepted exact first-party configuration contract.
- Alternatives rejected: Starting a local seven-day timer after purchase; deriving trial from
  paywall eligibility or cache; requiring `RenewalInfo.offer` for a one-period trial; including
  billing details or a mutable auto-renew assertion in a notification; pricing a scheduled switch
  from `currentProductID`; requesting notification consent automatically; retaining a
  stale request after cancellation/date change; fixed `5 * 86400` arithmetic; or persisting trial
  state as entitlement authority.

## DEC-COM-021 — Split signed public configuration into a pure verifier and one later fixed transport

- Status/date: **Accepted by the owner for COM-C3-03 — 2026-08-14**
- Requirements: REQ-R1-NET-001
- Decision: C3-03 is split into two independently reviewed packets. C3-03A owns only the exact
  signed document, Ed25519 verification over decoded payload bytes, closed schema/version/expiry/
  size bounds, rollback high-water mark, same-version equivocation rejection, durable signed
  cache, and conservative built-in fallback. C3-03B may add one fixed anonymous read-only transport
  and one optional-presentation consumer only after C3-03A is reviewed and merged.
- Environment and transport: Development, Staging, and Production use the exact hosts recorded in
  `PUBLIC_CONFIGURATION_CONTRACT.md`; future transport is anonymous HTTPS `GET /v1/config` and may
  send only bounded app version and last accepted configuration version. No request body, auth,
  cookie, identifier, locale/storefront, StoreKit fact, financial/content field, caller URL,
  redirect, wildcard, or cross-environment host is accepted. The service is an independent
  MindBudget Worker and cannot reuse another product's deployment, data, secret, or admin state.
- Payload authority: Schema v1 contains only `proValueTriggersEnabled`, whose built-in value is
  `false`. Configuration can affect optional explicit Pro value-trigger presentation only. It can
  never hide Settings/Restore/Manage, grant or preserve a paid right, name or change a StoreKit
  product/price/trial, schedule a notification, or control Lifetime, iCloud, Cloud AI/provider/
  model/quota, receipt, telemetry, Watch, versioning, or release behavior.
- Verification and cache: Unknown fields/algorithms/keys/schema, invalid signature/encoding,
  oversize, future/expired/overlong validity, lower version, same-version different digest,
  corrupt rollback state, and persistence failure fail closed. The maximum signed validity is
  seven 24-hour intervals. Only the signed envelope, highest version, and SHA-256 payload digest
  persist in one atomic, file-protected record whose bytes are read back before publication.
  Remote presentation becomes active only after persistence succeeds; offline failure uses a
  matching nonexpired verified cache and then the conservative built-in default. Timestamps use
  exact UTC whole-second `yyyy-MM-dd'T'HH:mm:ss'Z'` bytes and duplicate object keys are rejected
  before Foundation decoding. Concurrent acceptance serializes the full read/compare/write/read-
  back transaction, and a successful write is re-read through the persistence abstraction and
  re-verified before `.remote` is returned.
- Corrupt-state recovery: A corrupt rollback/high-water record is a sticky Release fail-closed
  state. No later remote document, normal Delete All workflow, Release reset seam, or iOS Offload
  may replace it. Current recovery is full app-and-container deletion followed by reinstall. A
  future signed recovery or support reset needs a separate Accepted decision because clearing the
  marker can reopen rollback.
- Encoding and diagnostics boundary: The verifier signs exact payload bytes and does not invent a
  client-side canonical-JSON/re-encoding authority. The signer must use the fixed timestamp grammar
  and no duplicate keys; sorted-key output is optional signer discipline. C3-03A adds no `os_log`
  or analytics. C3-03B must add only closed reason-code observability after its real transport and
  operations contract is accepted, and must never log payload/signature/user content.
- Privacy and release boundary: Ordinary edge connection metadata must be disclosed and the real
  Worker/logging/analytics/TTL/redirect/cache behavior, public-key provenance, captured traffic,
  and final binary must be verified in C3-03B. C3-03A has no URL, adapter, production key, Release
  egress exception, user-visible behavior, version, Archive/upload, tester assignment, or
  distribution authorization. The post-0.9.6 release hold remains active.
- C3-03A completion evidence: The review-remediation head `3a53107` passed independent review and
  green GitHub Actions run `31856271268`; PR #36 merged it to `main` as `1ebb36c` on 2026-08-15.
  This satisfies only the C3-03A gate and activates C3-03B. It does not itself accept Release
  egress, a Worker deployment, a Production key, C3-04, or distribution.
- Alternatives rejected: Unsigned JSON; TLS as the sole integrity boundary; signing decoded or
  re-encoded/canonicalized JSON; a caller-selected URL; wildcard/shared hosts; long-lived or
  nonexpiring config; cache-before-verify; overwriting or locally resetting a corrupt rollback
  mark; remote entitlement/price/trial fields; payload/signature logging; telemetry/user
  identifiers; and adding transport before the verifier packet is reviewed.

## DEC-COM-022 — Keep public configuration first-party, fixed, non-content, and non-authoritative

- Status/date: **Accepted implementation boundary for COM-C3-03B — 2026-08-15**
- Requirements: REQ-R1-NET-001
- Decision: C3-03B owns exactly one centralized `URLSession` adapter for the three fixed DEC-COM-021
  hosts and exact anonymous `GET /v1/config`. Debug defaults to Development and may select Staging
  only through a local launch argument; Release is compiled to Production and cannot accept a
  caller or remote URL. Only bounded app version and optional last accepted configuration version
  headers leave the app. The ephemeral session has no cookies, credentials, or shared cache,
  rejects redirects, and enforces method/path, URL, status, MIME, size, timeout, and cancellation.
- Worker and key boundary: Each environment is an independent deployment of the repository-owned
  Worker with an environment-specific rate-limit namespace and pre-signed envelope variables. It
  has no signing key, database, KV, R2, queue, analytics binding, outbound fetch, cookie, CORS, or
  application request log; platform observability is disabled and responses are `no-store`. The
  Ed25519 private key remains in an owner-controlled protected file outside the repository. Only
  the public key, signer utility, and seven-day signed public envelope enter the repository.
- Presentation boundary: The one consumer may show an optional explicit Pro value trigger only
  when the verified flag is true and StoreKit has published an actionable exact-Free whole
  snapshot. Initial, incomplete, unverified, mixed, or unavailable StoreKit authority never
  qualifies as Free for this presentation decision, including after a previously paid user's
  verification fails. Permanent Settings, Restore, Manage Subscription, current subscription
  status, StoreKit authority, price/trial facts, notifications, and every Free trust capability
  are independent of configuration.
- Expiry/cancellation boundary: The verification clock is sampled after a full response arrives,
  not when the request starts. Verified remote/cache resolutions carry the exact signed expiry and
  the app replaces presentation with the conservative built-in value at that instant, including
  while continuously foregrounded. The startup refresh is structurally awaited by a dedicated
  SwiftUI task; scene-active work is retained and canceled on inactive/background, replacement,
  or Session destruction. A canceled startup resets its one-time guard so a recreated SwiftUI task
  can retry. Canceling a refresh cancels its owned network/acceptance task. File
  persistence checks cancellation after actor entry and immediately before its atomic-write
  commit point; cancellation observed before that point leaves the prior cache untouched. Once
  the atomic write begins it may complete, but canceled acceptance can never publish its result.
- Diagnostics/privacy boundary: Client diagnostics are closed `transport.*` and `resolution.*`
  reason codes only. Payload, signature, response body, metadata values, IP address, StoreKit,
  and user/financial content are never logged. Cloudflare necessarily processes ordinary edge
  connection metadata and may inject platform response metadata on workers.dev; this must remain
  disclosed and included in final captured-traffic review even though native URLSession does not
  execute browser NEL reporting.
- Evidence and deployment: On 2026-08-15, Development Worker version
  `bf6c5049-a389-4ea7-af0a-e8425b8957e2` was deployed. The dedicated non-Archive live scheme used
  the real Development Worker, embedded production public key, production verifier, cache, and
  consumer boundary and passed 8/8 with no failure or skip. Worker unit tests passed 13/13;
  typecheck, high-severity dependency audit, and Production configuration dry-run passed. Staging
  and Production were not deployed.
- Release boundary: Source-level acceptance of this exact adapter is not distribution approval.
  Final Release binary/traffic, current App Privacy/review disclosure, Production deployment,
  C3-04 implementation, formal economics/products, Archive/upload, tester assignment, and
  distribution remain blocked by their own gates.
- Closeout: The final reviewed head `09c382e` passed GitHub Actions run `31873664396`; PR #38
  merged C3-03B to `main` as `db7926d` on 2026-08-15. C3-03A and C3-03B are Done, closing C3-03.
  C3-04 is ready but not started pending explicit owner instruction. This completion does not
  deploy Staging/Production or relax any release gate above.
- Alternatives rejected: Shared product Worker/admin state; a generic networking client;
  caller-selected URLs/headers; redirects; cookies/auth/identifiers; private key in app/repository/
  Worker; Worker storage or app logging; remotely granting entitlement; deploying all environments
  together; treating an unavailable fail-closed entitlement set as confirmed Free; retaining an
  enabled presentation until a later foreground refresh after signed expiry; detached refresh
  work that survives caller cancellation; and treating Development evidence as Production release
  evidence.

## DEC-COM-023 — Present subscription soft landing as one non-blocking verified-state surface

- Status/date: **Accepted implementation boundary for COM-C3-04 — 2026-08-15**
- Requirements: REQ-STOREKIT-LIFECYCLE-001
- Decision: A verified exceptional StoreKit state may produce one calm Dashboard navigation card
  and one explanatory section on the voluntary Pro screen. Neither surface is an automatic modal
  or entitlement authority. Billing grace retains Pro. Billing retry, expiry, and revocation do
  not grant Pro; they preserve local data and every Free capability and expose explicit Manage
  Subscription and Recheck actions.
- Purchase boundary: Billing grace and billing retry do not start a second purchase flow. Expired
  or revoked users may review and select only currently live, structurally accepted StoreKit
  products. Unavailable or unverified authority is not a Free state and continues to block a new
  purchase. Status guidance never changes StoreKit facts or signed-configuration eligibility.
- Copy and accessibility boundary: Every new status, action, plan-selection label, and hint is
  localized in English and Simplified Chinese. Plan rows reflow vertically at accessibility text
  sizes, status is conveyed by text and symbol rather than color alone, and the primary purchase,
  restore, and manage controls remain reachable at AX5 across Aurora Glow, Warm Botanical, and
  Neon Pulse. The Pro list applies the selected skin's light/dark preference locally so an
  in-session skin change cannot briefly combine stale system text colors with the new row
  appearance. Customer copy never hardcodes the local fixture's price or seven-day duration;
  exact terms and eligibility remain StoreKit/App Store facts.
- Review and release boundary: Review notes disclose Apple-handled purchase/status, local-data
  retention, the first-party anonymous signed-config request, and ordinary Cloudflare edge
  connection metadata. Final screenshots may advertise only live approved StoreKit products and
  must omit Lifetime, cloud-AI quotas, receipt/iCloud/Watch claims, provisional prices/trials, or
  another deferred product. Staging/Production deployment, formal economics, final Release
  binary/traffic evidence, Archive/upload, tester assignment, and distribution remain blocked.
- Alternatives rejected: automatic blocking paywall; treating StoreKit-unavailable as exact Free;
  hiding local data after a paid-state loss; opening a second purchase during grace/retry; color-
  only status; fixed-height/truncating plan rows; fixture literals in customer terms; and release
  screenshots that advertise incomplete work.

## DEC-COM-024 — Allow one transport-only 0.9.7 TestFlight upload after COM-C3

- Status/date: **Accepted owner release instruction — 2026-08-16**
- Requirements: REQ-STOREKIT-LIFECYCLE-001, REQ-R1-NET-001
- Decision: PR #40 passed independent review and GitHub Actions run `31918968478`, then merged
  C3-04 as `9448ca9`; COM-C3 is Done. The owner authorizes preparing, signing, archiving, and
  transport-uploading version 0.9.7/build 8 to the existing App Store Connect record. This
  workflow must stop after a successful upload and must not assign an internal tester, submit
  external Beta App Review, or submit an App Store version.
- Configuration boundary: Production signed configuration remains undeployed. The Release binary
  may contact only the exact reviewed Production host. Failure or absence keeps the optional Pro
  value trigger at the built-in `false`; Settings, Restore Purchases, Manage Subscription,
  StoreKit entitlement, price/trial facts, and Free trust capabilities remain independent.
- Product boundary: Customer-facing prices, offers, eligibility, and availability come only from
  StoreKit. Catalog or authority uncertainty pauses purchase. This upload does not convert the
  provisional test anchors into public-launch economics or authorize a later COM phase.
- Evidence boundary: Archive metadata, embedded endpoints/resources, signing identity, and upload
  acceptance must be recorded against the merged release commit. Tester assignment and any later
  distribution evidence remain the owner's manual responsibility.
- Alternatives rejected: Reusing immutable build 7; uploading from an unmerged feature branch;
  treating an undeployed configuration service as entitlement failure; deploying Production as
  an inferred side effect; or broadening upload authority into tester assignment/public release.

## DEC-COM-025 — Preserve exact V1–V4 amounts and add only a recoverable migration envelope

- Status/date: **Accepted C4A-01 implementation plan pending independent review — 2026-08-20**
- Requirements: REQ-MONEY-001, REQ-MONEY-MIGRATION-001
- Decision: The C4A-01 repository audit found that authoritative V1–V4 amounts already use
  `Int64` minor units and independently owned amounts already carry ISO currency. COM-C4A must not
  rewrite those values through a new representation or a floating-point intermediate. C4A-02 is
  limited to the missing recovery envelope documented in `COM_C4A_EXECUTION_PACKET.md`: a
  pre-open backup of the store and sidecars, a durable explicit migration journal, idempotent
  restart/restore states, post-open integrity validation, content-minimized anomaly reporting, and
  explicit currency ownership for the rebuildable merchant aggregate cache.
- Sign and anomaly boundary: Persisted expense, income, recurring, and optional wishlist prices
  are positive when present; persisted budget, goal, allocation, category, and merchant totals are
  nonnegative. Negative numbers are valid only for derived in-memory differences. Unsupported or
  cross-currency facts, overflow, invalid signs, broken references, duplicate stable identity,
  inconsistent allocations, unreadable stores, and interruption stop migration and preserve the
  original store. No failure is coerced to zero or treated as a successful empty migration.
- Recovery boundary: SwiftData's existing V1 → V2 → V3 → V4 `SchemaMigrationPlan` remains the
  schema mechanism. The app-owned coordinator surrounds container opening and does not infer a
  SwiftData schema version from undocumented persistent-store metadata. No store means no backup;
  a trusted committed sidecar marker for the current target is the normal fast path. Trust
  requires a parseable supported app-owned marker format, committed state, exact target match,
  and no active/nonterminal recovery journal. A missing marker or failure of any trust condition
  creates one recoverable pre-open snapshot/journal before the attempted open; only successful
  post-open inventory validation commits the target marker.
  A durable journal then determines whether restart validates or restores; it must never infer
  success from a partially opened store. This recovery path has separate C4A-03 evidence and is
  excluded from the normal Dashboard first-screen performance budget.
- Test boundary: C4A-03 must cover V1–V4 clean/interrupted paths, repeated restart, backup restore,
  USD/JPY/KWD exponents, persisted sign rules, derived negative values, `Int64` bounds, overflow,
  unsupported/cross-currency facts, duplicate identity, broken references, allocation mismatch,
  merchant currency context, and every existing money/migration gate.
- Release boundary: C4A-01 adds documentation and gates only. C4A-02/C4A-03, iCloud, telemetry,
  receipts, Watch, backend, cloud AI, formal economics, Production deployment, tester assignment,
  Beta/App Store review, and public distribution remain blocked.
- Alternatives rejected: Destructively rewriting correct minor-unit fields merely to create a
  migration; adding an unneeded schema version in C4A-01; treating the globally locked accounting
  currency as permanently implicit for a stored merchant amount; attempting repair by zeroing,
  dropping, or partially committing anomalous records; and relying on SwiftData container opening
  without an app-owned recoverable checkpoint.

## DEC-COM-026 — Use a V5 merchant-currency companion and fail-closed recovery envelope

- Status/date: **Accepted C4A-02 implementation boundary pending independent review — 2026-08-20**
- Requirements: REQ-MONEY-001, REQ-MONEY-MIGRATION-001
- Decision: Preserve all V1–V4 model hashes, UUIDs, and authoritative `Int64` minor-unit values.
  Schema V5 adds only `MerchantAccountingContext`, keyed by the existing merchant UUID, so the
  rebuildable merchant aggregate has an explicit accounting currency without reinterpreting an
  old number. Before a non-fast-path SwiftData open, snapshot the store plus SQLite sidecars and
  `_SUPPORT` directory with a checksum manifest; persist an app-owned journal with closed state
  transitions. Only a parseable committed current-target marker with no active journal skips that
  work. A failed open or inventory releases the container before checksum-verified restoration,
  restores only a previously trusted source marker, and records only a closed reason code.
- Integrity and deletion boundary: Build the complete integrity and merchant repair plan before
  mutating. A repair may change only `Merchant.totalMinorUnitsAllTime` and its companion context,
  and only from existing, validated same-currency expense facts. Missing/ambiguous facts, broken
  required links, unsupported/mixed currency, invalid amount/allocation, unreadable insight, or
  duplicate stable identity fail closed and retain the original store. Historical provenance IDs
  left by ordinary deletion are not required live references. Once the target marker and journal
  are both durably committed, removing their terminal backup/journal artifacts is best effort: a
  cleanup failure must never trigger rollback of an already-committed store, and the next cold
  start or Delete All retries removal. A prior closed anomaly report remains available for support;
  Delete All must clear all recovery artifacts before it can reset preferences.
- Alternatives rejected: Adding currency directly to `Merchant`; using undocumented SwiftData
  metadata to decide whether to back up; treating any parseable marker as trusted; treating
  historical provenance IDs as broken relationships; deleting/recreating orphan merchants; or
  silently converting a failed repair to zero.
