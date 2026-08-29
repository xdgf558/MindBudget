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

- Status/date: **Accepted and implemented through PR #53 (`c905415`) after green GitHub Actions
  run `32375823770` — 2026-08-20**
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
- Recovery UI boundary: **Owner-confirmed — 2026-08-20.** C4A-02 deliberately keeps the existing
  recovery surface retry-only. If the live store is invalid and no trusted backup can restore it,
  recovery currently requires deleting the app data container or reinstalling. Adding an in-app
  destructive reset is not a review fix for this packet; C4A-03 must explicitly decide and test
  that product boundary before changing it.
- Alternatives rejected: Adding currency directly to `Merchant`; using undocumented SwiftData
  metadata to decide whether to back up; treating any parseable marker as trusted; treating
  historical provenance IDs as broken relationships; deleting/recreating orphan merchants; or
  silently converting a failed repair to zero.
- Merge evidence: Reviewed head `9d2171d` passed GitHub Actions run `32375823770`; PR #53 merged
  the C4A-02 implementation as `c905415` on 2026-08-20. This closes C4A-02 only. The owner later
  started C4A-03's limited recovery/currency matrix; implementation and independent review remain
  pending.

## DEC-COM-027 — Bound persisted budget values and make recovery interruption deterministic

- Status/date: **Accepted implementation decision pending independent review — 2026-08-20**
- Requirements: REQ-MONEY-001, REQ-MONEY-MIGRATION-001
- Decision: The post-open inventory and every `BudgetPlan` write path use the same inclusive
  `Money.maximumMinorUnits(for:)` ceiling for all plan and category amounts. Existing source
  ledger values remain positive where their established owner contract requires it; a zero
  `SavingsGoal` target remains readable in the migration inventory for historical compatibility,
  even though new goal entry continues to require a positive target. Insight payload money is a
  derived signed aggregate/delta, so it remains valid anywhere in `Int64` storage range; the
  single-entry ceiling deliberately leaves aggregation headroom and must not be applied to it.
  Invalid source facts fail closed and are never repaired to zero.
- Deterministic evidence boundary: `StoreMigrationRecoveryCoordinator` accepts an internal,
  default-no-op callback immediately before each already-checksummed backup artifact is copied
  during restore. It exists only to inject a deterministic mid-restore failure in tests; production
  supplies no behavior, it exposes no user surface, and it does not alter state transitions or
  recovery authority. The next ordinary coordinator invocation must recover from the retained
  journal and verified backup.
- Evidence: The final corrected focused run recorded 20 passing tests across the 12-case C4A-03
  matrix and 8 existing recovery cases at `/private/tmp/MindBudget-C4A03-Focused4.xcresult`. Full
  validation, Release evidence, independent review, hosted CI, and merge remain required.
- Alternatives rejected: Allowing values above the aggregate-safety ceiling through create or
  transition paths while rejecting them only during recovery; treating signed insight values as
  persisted source-ledger amounts; using a timing-dependent `Task.yield()` failure test; adding an
  in-app destructive reset; or changing V1–V4 schema hashes.

### Closeout evidence — 2026-08-21

Reviewed head `138c240` passed GitHub Actions run `32406654986`, including the complete Build and
test job and report upload. PR #55 merged C4A-03 to `main` as `77292c6`, satisfying DEC-COM-027's
review/CI/merge gates and closing COM-C4A. This is append-only closeout evidence, not a change to
the accepted recovery or money boundary. C4B remains blocked pending an accepted CloudKit
architecture and explicit owner instruction.

## DEC-COM-028 — Accepted Free iCloud custom-record architecture

- Status/date: **Accepted — 2026-08-21 after owner acceptance, independent review, green GitHub
  Actions run `32434148439`, and PR #57 merge `90a1e66`**
- Requirements: REQ-ICLOUD-001, REQ-RECEIPT-PRIVACY-001, REQ-MONEY-001
- Decision: Use `CKSyncEngine` only with one custom zone in the current person's private
  CloudKit database. Sync is Free, default off, and not initialized before explicit opt-in. The
  app owns typed/versioned custom envelopes, canonical record names, a durable transactional
  outbox, a validated inbox/shadow, and logical tombstones. Full allow-listed user fields are stored
  with parent/semantic digests in one `CKRecord.encryptedValues` Data field; unencrypted routing
  metadata has no content or query index. Per-record lineage revision plus encrypted digest ancestry may
  acknowledge replay or safe descent, but a true divergent payload/tombstone is quarantined rather
  than selected by wall clock, device identity, or last-writer-wins. Durable local sync metadata
  retains encoded server-owned CKRecord system fields/change tags for conditional save.
  `CKSyncEngine` serialized state is persisted but rebuildable; it never replaces the
  outbox or local business authority. Remote changes enter staging and are validated/topologically
  applied by `DataActor`, never directly by the engine delegate.
- Local-store safeguard: Before any iCloud entitlement or CloudKit import, every primary local
  `ModelConfiguration` must explicitly use `cloudKitDatabase: .none`. This prevents its documented
  `.automatic` default from enabling managed SwiftData mirroring when a ubiquity container appears.
  Managed SwiftData/Core Data mirroring is excluded because the current V5 graph has unique
  identities/cascade edges and the product needs a selective envelope/tombstone/conflict contract.
- Data boundary: The allow-list and all 16 V5 owners are in `ICLOUD_SYNC_CONTRACT.md`. Merchant,
  MerchantAccountingContext, SpendingInsight, and ReminderEvent remain local-only/rebuildable or
  device-specific. Recurring occurrence control-plane facts use `occurrenceKey` record identity to
  prevent duplicate multi-device generation; simultaneous divergent claims must surface or gain an
  accepted deterministic origin companion, never delete an edited expense automatically. Receipt
  images/OCR/intermediates, recovery artifacts, logs, StoreKit, notification, and configuration
  caches never enter CloudKit.
- Account/deletion rule: Account change pauses transfer and requires new explicit consent;
  local writes never use an online lease. Same-record logical tombstones prevent stale resurrection
  after reinstall/full fetch and remain until C4B-03 proves safe compaction. Disable keeps local
  data and does not silently delete cloud data. C4B-03 owns the required cloud-wide deletion
  choice and evidence, distinct from local-only deletion.
- Alternatives rejected: Pro-gating or implicit sync; public/shared database; CloudKit-generated
  business IDs; direct delegate writes into SwiftData; immediate physical deletes that permit
  resurrection; relying on engine state as the unsent-write authority; managed model mirroring; and
  a timing-based online write lease.
- Environment: one accepted but still uncreated/unprovisioned `iCloud.com.xdgf558.MindBudget` container, with
  provisioning-selected Development/Production environments and accepted `MindBudget.Sync.v1`
  private custom zone containing accepted `MindBudgetEnvelopeV1` records.
  Encrypted-key reset pauses and requires explicit recovery; it never auto-purges/reuploads.
- Accepted C4B-02P inputs: occurrence claims use only the canonical lower-case UUID + calendar-year/
  month grammar and reject slash-bearing caller strings; genesis is revision 1 with no parent;
  every later revision names the last accepted semantic digest. C4B-02 durably quarantines without
  an automatic winner; C4B-03 owns keep-local/accept-cloud/explicit tombstone resolution. The exact
  bilingual opt-in disclosure and container identifier are frozen in `ICLOUD_SYNC_CONTRACT.md`.
- Not yet evidenced: dashboard roles/schema, Development/Production provisioning/deployment,
  physical-device account transitions, multi-device convergence, and the C4B-03 resolution UI.
- Acceptance evidence: reviewed head `093535f` passed every step of GitHub Actions run
  `32434148439`; PR #57 merged to `main` as `90a1e66` on 2026-08-21. This accepts the architecture,
  not a container creation, entitlement, CloudKit request, deployment, runtime implementation, or
  distribution action. C4B-02 remains blocked pending prerequisite review/merge and explicit owner
  instruction.

## DEC-COM-029 — Implement C4B-02 as an explicit local-authority custom-record runtime

- Status/date: **Accepted implementation decision pending independent review — 2026-08-21**
- Requirements: REQ-ICLOUD-001, REQ-RECEIPT-PRIVACY-001, REQ-MONEY-001
- Decision: Schema V6 adds five non-authoritative local sync models for consent/control, accepted
  record lineage/system fields, durable outbox, durable inbox/quarantine, and rebuildable opaque
  engine state. Every primary SwiftData configuration explicitly selects
  `cloudKitDatabase: .none`; managed mirroring remains prohibited. Enabling sync after the exact
  bilingual disclosure stages the current 12-type authoritative fact inventory, and every later
  local authoring/deletion transaction stages its envelope or logical tombstone in the same
  `ModelContext` save. Remote records enter the inbox first, then are decoded, validated, and
  topologically applied by `DataActor`; the engine delegate never writes a business fact directly.
- Conflict and lifecycle boundary: Canonical bytes, exact record identity, revision/digest ancestry,
  encoded server change tags, and same-name logical tombstones are mandatory. Replay is idempotent;
  true divergence, physical deletion, malformed data, unknown schema, or invalid lineage is
  durably quarantined without choosing a financial winner. Account change pauses, clears only the
  old account's transport metadata after explicit disable, and requires a new disclosure acceptance
  before staging new-account genesis facts. Encrypted-key reset remains a distinct sticky pause that
  generic enable/disable cannot clear. External custom-zone deletion or purge is also sticky:
  C4B-02 never treats a missing zone as an empty server to recreate and repopulate. Network,
  account, quota, service, and transport failures never block local reads or writes.
- Transport and UI boundary: The centralized adapter is private-database only, creates only the
  accepted custom zone/record type, places the full typed envelope in one encrypted value, and uses
  no public/shared database, attachment, physical record delete, or app-owned HTTP endpoint. Settings
  exposes only default-off consent, neutral closed status, retry, and disable-retaining-data. The
  exact container identifier is still an unprovisioned source constant; this packet adds no iCloud
  entitlement, Dashboard deployment, verified CloudKit request, or distribution authority.
- C4B-03 handoff: Physical account and multi-device convergence, actual container/entitlement and
  Development/Production schema, conflict-resolution visibility, cloud-wide Delete All, tombstone
  retention/compaction, Dashboard roles, quota wording on device, privacy/review evidence, and
  release remain blocked for C4B-03.
- Evidence: Focused deterministic `CloudSyncTests` pass 20/20 at
  `/private/tmp/MindBudget-C4B02-CloudSync-Final.xcresult`; the exact 12-type source gate and
  existing money/network/commercial/StoreKit gates are part of final validation. Independent
  review, hosted CI, and merge remain required.
- Alternatives rejected: Managed model mirroring; immediate physical delete; delegate writes into
  SwiftData; storing attachments or local-only caches; implicit/Pro-gated enablement; retry loops
  that block budgeting; last-writer-wins/device/wall-clock conflict choice; automatically uploading
  an old account's ledger to a new account; and treating simulator fakes as C4B-03 cloud evidence.

## DEC-COM-030 — Isolate the strict local Dashboard benchmark from correctness-suite contention

- Status/date: **Accepted verification maintenance — 2026-08-21**
- Requirements: REQ-ICLOUD-001 and the existing local release-performance contract
- Decision: `Scripts/validate.sh` runs the 10,000-row, 500 ms Dashboard wall-clock test once in a
  dedicated non-parallel test invocation on local release machines, then excludes only the
  duplicate invocation from the full correctness/coverage run. Hosted CI continues to skip the
  machine-sensitive wall-clock signal while running the deterministic 10,000-row projection test.
- Reason: The pre-change validation attempt passed every functional and UI assertion but ran the
  wall-clock test concurrently with 27 Swift Testing suites. The same code passed a focused run and
  10/10 isolated iterations. Measuring unrelated suite contention would not represent Dashboard
  first-load latency and made the release signal nondeterministic.
- Consequences: The 500 ms threshold is not raised, disabled locally, retried until green, or
  replaced by a mock. The final validation must pass both the isolated benchmark and the complete
  correctness/UI/coverage run. This maintenance grants no CloudKit entitlement, container,
  deployment, or C4B-03 authority.
- Evidence: 20/20 Phase 10 tests across 10 isolated iterations passed at
  `/private/tmp/MindBudget-C4B02-Performance10-iOS264.xcresult`; the corrected full validation then
  passed at `/private/tmp/MindBudget-C4B02-Validate.xcresult`.

## DEC-COM-031 — Close C4B-02 destructive-state and remote-apply review gaps

- Status/date: **Accepted review remediation pending final independent re-review — 2026-08-21**
- Requirements: REQ-ICLOUD-001, REQ-MONEY-001
- Sticky-state decision: Account change, encrypted-key reset, and accepted-zone loss are
  trust-boundary transitions. Once stored, ordinary status/account callbacks cannot replace them.
  Both database-deletion events and `zoneNotFound` CKErrors enter a sticky pause; the
  `CKErrorUserDidResetEncryptedDataKey` flag distinguishes encrypted reset from other remote-zone
  loss. The active engine is cancelled and discarded before retry can recreate a zone.
- Apply decision: The recurrence engine and record-name path share `RecurringOccurrenceKey`.
  Missing allocation parents remain pending, while arithmetic overflow or allocation above the
  verified income is quarantined. An accepted occurrence claim cannot change its `id`, `ruleID`,
  or `expenseID`; divergence is quarantined without overwriting the local claim. CategoryBudget and
  CoolingOffPlan keep optional SwiftData relations for migration/cascade mechanics, but every sync
  upsert envelope requires `planID` or `wishItemID`. A missing key is malformed; a named parent that
  has not arrived remains pending. Tombstones need only the canonical record identity.
- Delete boundary: The existing Delete All workflow remains local-only in C4B-02. It stops sync and
  clears local facts plus sync metadata, but authors no cloud tombstones and deletes no zone.
  Bilingual Settings and confirmation copy disclose that retained iCloud copies may be imported
  after a future re-enable. C4B-03 still owns confirmed cloud-wide deletion and confirmed reimport.
- Alternatives rejected: Treating destructive CloudKit errors as retryable; permitting delayed
  callbacks to reopen a sticky pause; waiting forever on a mathematically invalid allocation;
  overwriting a divergent occurrence claim; calling absent parent identity a retryable delivery
  order; or implying local Delete All removes cloud copies.
- Evidence: The expanded focused sync suite passed 25/25 at
  `/private/tmp/MindBudget-C4B02-ReviewFix2.xcresult`. The final owning validation then passed the
  isolated strict benchmark 1/1; 466 combined correctness/UI results with 459 passed, seven opt-in
  skips, and UI 17/17; Release compilation; every static contract; and the coverage gate at
  `/private/tmp/MindBudget-C4B02-ReviewFix-Validate.xcresult`.

### Closeout evidence — 2026-08-21

Reviewed remediation head `0024507` passed every step of GitHub Actions run `32490174014`. PR #59
merged that exact head to `main` as `211dff2`, satisfying DEC-COM-029 and DEC-COM-031's independent
review, hosted-CI, and merge conditions. C4B-02 is Done. This evidence does not authorize an iCloud
entitlement, provision a container, deploy a Dashboard schema/environment, prove a real CloudKit
request or physical multi-device lifecycle, delete cloud data, or distribute the feature. The
owner authorized formal C4B-03 entry only after this documentation closeout passes review/CI/merge.

## DEC-COM-032 — Own C4B-03 conflict, deletion, retention, and environment isolation

- Status/date: **Accepted implementation boundary — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-028/029/031
- Entry evidence: Reviewed closeout head `b9944cd` passed GitHub Actions run `32494429474`; PR #60
  merged it as `7138a9c`, satisfying the owner's formal-entry condition.
- Environment decision: Debug selects `MindBudgetDebug.entitlements` with Development CloudKit and
  development push; Release selects `MindBudgetRelease.entitlements` with Production CloudKit and
  production push. Both name only `iCloud.com.xdgf558.MindBudget` and CloudKit. The primary
  SwiftData store remains explicitly `.none`; no managed mirroring, public/shared database, or
  second container is allowed.
- Conflict decision: Quarantine remains no-winner. The conflict list exposes only the fact type and
  keep/delete operation, never note, merchant, amount, or other record content. “Keep local” authors
  a new descendant; “Use iCloud” applies the exact verified remote candidate. A malformed or
  physical-deletion quarantine has no destructive resolution shortcut.
- Deletion decision: Normal records retain same-name logical tombstones indefinitely. Explicit
  cloud-wide deletion is a separate destructive confirmation that calls
  `CKDatabase.deleteRecordZone(withID:)`, keeps local business facts, and durably remains pending
  through network/account/quota interruption. Only confirmed whole-zone deletion clears the local
  “cloud copy may exist” marker. Local Delete All keeps that marker; a later enable requires an
  explicit reimport confirmation so retained remote facts never silently return.
- Recovery decision: Account change, encrypted-data-key reset, and remote-zone loss stay sticky.
  Ordinary Enable/Retry is hidden or rejected. Explicit rebuild clears only sync ancestry and
  re-stages current local facts after the user accepts that the current iCloud account may already
  hold a copy and divergence will return to quarantine rather than be auto-merged.
- Release boundary: A signed Development build and local Release archive may prove source/profile
  selection. They do not prove a real request, Dashboard schema, Production deployment,
  distribution signing, physical multi-device convergence, quota/account lifecycle, or release.
  Production schema deployment is one-way operational state and requires a separate explicit owner
  confirmation.
- Alternatives rejected: Per-record physical deletion during normal sync; automatic LWW/replica
  winner; deleting local facts as a side effect of cloud deletion; clearing retained-copy state
  before zone confirmation; treating a Release archive as Production deployment; or letting generic
  retry clear a trust-boundary pause.

## DEC-COM-033 — Keep background CloudKit delivery and every SwiftData test store explicit

- Status/date: **Accepted implementation boundary — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-028/029/031/032
- Decision: The app-owned source plist contains exactly `UIBackgroundModes = [remote-notification]`
  and both Debug and Release reference it. Environment selection remains exclusively in the two
  exact entitlement files; the source plist cannot collapse Development and Production isolation.
  Because the test host is now entitled, every `ModelConfiguration` used by a local test store must
  explicitly select `cloudKitDatabase: .none`, just like production. The repository gate parses the
  plist, checks both build-setting references, rejects alternate background modes, and scans test
  fixtures for the same non-mirroring boundary.
- Evidence: The entitlement first made six legacy migration fixtures fail because their default
  `.automatic` configuration became observable. That run remains a non-pass. After every fixture
  declared `.none`, the focused migration/free-tier regression passed 45/45 at
  `/private/tmp/MindBudget-C4B03-Regression2.xcresult`. A fresh Debug build's generated plist was
  read back with the exact remote-notification array. The corrected complete validation passed
  Release compilation, static contracts, the isolated strict Dashboard benchmark, 456/456 unit
  tests, 17/17 UI tests, and coverage at `/private/tmp/MindBudget-C4B03-Full1.xcresult`.
- Boundary: This proves local configuration and regression safety only. It does not prove a real
  push, CloudKit request, Dashboard environment, physical account/multi-device lifecycle,
  distribution signing, Production schema deployment, review, hosted CI, merge, or release.
- Alternatives rejected: Relying on generated-plist build settings that do not materialize in the
  final app; letting the entitled test host infer `.automatic`; disabling the entitlement in tests
  to hide the production-like default; or treating a successful local build as remote evidence.

## DEC-COM-034 — Keep destructive CloudKit runtime evidence explicitly opt-in

- Status/date: **Accepted implementation and evidence boundary — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-028/029/031/032/033
- Decision: The test that contacts the real private Development database and deletes the fixed
  `MindBudget.Sync.v1` zone is disabled in every ordinary build. It compiles as enabled only when
  the explicit `MINDBUDGET_PHYSICAL_CLOUDKIT_TESTS` Swift condition is supplied on a physical
  device. A process environment variable is not used because Xcode does not forward the invoking
  shell's value into the device test process. Function-level `-only-testing` is also not accepted
  as evidence on this toolchain because it can discover the Swift Testing suite while executing
  zero functions; evidence must report a nonzero exact total.
- Owner authorization: The owner explicitly accepted that the fixed Development zone and any
  existing Development records would be irrecoverably deleted by this probe. No Production
  environment action was authorized.
- Evidence: Final Xcode 26.6 (`17F113`) ran the complete `CloudSyncTests` suite on physical
  `拉沙的iPhone` (`iPhone Air`), final iOS 26.6.1 (`23G82`). All 33 tests passed; the real case
  took 9.358 seconds and exercised custom-zone creation, encrypted private-record send/fetch,
  disable, confirmed reimport, whole-zone deletion, and local-expense preservation. Evidence:
  `/private/tmp/MindBudget-C4B03-PhysicalCloudKit4.xcresult`.
- Non-passes retained: The first result failed compilation because a suite-isolated test condition
  was not `nonisolated`; the next two exact-function filters executed zero tests. None is counted
  as CloudKit evidence.
- Boundary: This closes one single-device Development request/deletion case only. It does not
  close Dashboard inspection, push/background observation, offline/quota/account transition,
  multi-device convergence/conflict, distribution signing, Production schema deployment, review,
  hosted CI, merge, or release.
- Alternatives rejected: Enabling destructive tests for every physical run; silently trusting a
  zero-test green result; using Production; preserving the Development zone after the deletion
  contract was explicitly under test; or treating one device as multi-device evidence.

## DEC-COM-035 — Fail closed when CloudKit lineage revision space is exhausted

- Status/date: **Accepted implementation boundary — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-028/029/031/032
- Decision: Every transition to a child CloudKit envelope uses one checked revision helper.
  Revision zero may advance to genesis revision one, and `Int64.max - 1` may advance to
  `Int64.max`; attempting to advance `Int64.max`, or any negative persisted ancestry, throws the
  closed `invalidLineage` error. Local staging, remote acceptance, and explicit conflict
  resolution all share this helper.
- Consequence: A malformed or exhausted private record cannot crash the process through signed
  integer overflow, wrap ancestry, or invent a winner. The affected record remains local and
  failed closed for explicit support/recovery; normal budgeting facts are not rewritten.
- Evidence: The focused exact-head run passed 34 results—33 deterministic cases and one explicit
  physical-test skip—with zero failures at
  `/private/tmp/MindBudget-C4B03-LineageBound.xcresult`.
- Alternatives rejected: Unchecked `+ 1`; wrapping revision arithmetic; accepting a negative
  revision; resetting exhausted ancestry automatically; or treating wall-clock/device identity as
  a replacement conflict winner.

## DEC-COM-036 — Record the stopped cross-account device run as an evidence gap

- Status/date: **Accepted evidence boundary — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-028/032/034
- Context: The signed two-device harness was prepared on two paired, Developer-Mode iPhones. After
  local-network permission was enabled, one-way non-content fingerprints proved that the devices
  use different iCloud Apple Accounts and therefore address different private CloudKit databases.
- Decision: The owner declined an account switch and explicitly stopped the current two-device
  convergence attempt. Keep the compile-time opt-in harness for a future same-account run, but do
  not relabel the stopped run as passed, failed product behavior, or a release waiver. C4B-03
  remains In Progress and its final evidence assessment must disclose this unproven item.
- Cleanup evidence: The interrupted run's fixed Development zone was removed. The first cleanup
  surfaced the leftover seed and is retained as a non-pass; the second passed 33/33 at
  `/private/tmp/MindBudget-C4B03-PostMultiCleanup2.xcresult`, proving only that the test zone is
  clean. The ordinary simulator configuration then passed 36 results—33 deterministic and three
  physical-only skips—at `/private/tmp/MindBudget-C4B03-PostMultiDefault.xcresult`.
- Alternatives rejected: Treating different private databases as a convergence test; publishing
  raw iCloud record names; forcing an Apple Account change after the owner declined; deleting the
  reusable harness; or treating a cleanup pass as multi-device evidence.

## DEC-COM-037 — Keep retained-cloud authority visible after local deletion

- Status/date: **Accepted review-remediation boundary — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-028/032
- Context: Independent review found that local Delete All correctly preserved the durable
  `cloudCopyMayExist` preference but then replaced the current `AppSession` snapshot with the
  literal `.disabled`, whose marker is false. Until a later scene refresh, Settings hid the cloud
  deletion action, showed the ordinary Enable disclosure, and sent an unconfirmed enable request
  that the service correctly rejected without explanation.
- Decision: `AppSession` never synthesizes a cloud-sync snapshot after local deletion. Once the
  local store is cleared, `CloudSyncService` reloads the now-disabled control state, combines it
  with the independent retained-copy marker, and publishes that authoritative snapshot in the
  same session. Settings derives both the reimport confirmation and cloud-delete visibility from
  that snapshot. An unconfirmed enable remains fail-closed; confirmed reimport may start transfer.
- Deletion/conflict clarification: A cloud-wide deletion first persists local tombstone intent,
  but confirmed whole-zone absence is the final privacy postcondition and does not wait to upload
  each tombstone. Pending deletion displays a closed network/account/quota/failure reason plus a
  safe Retry explanation and hides the ineffective ordinary Disable action. Keep-local/use-iCloud
  conflict actions require two verified candidates and reusable CloudKit system fields; an
  incomplete server conflict remains quarantined without changing local facts.
- Environment clarification: The current authority is the provisioned exact container with
  Development Debug and Production Release entitlements plus the checked remote-notification
  plist. Earlier “no entitlement/unprovisioned constant” statements are explicitly time-boxed to
  C4B-01/C4B-02; Production still has no deployed app schema or distribution authorization.
- Evidence: The focused CloudSync + Phase 6 run passed 52 tests across two suites at
  `/private/tmp/MindBudget-C4B03-ReviewRemediation-Focused1.xcresult`; the three destructive/
  multi-device physical cases were explicit skips. Hosted CI and independent rereview remain
  required.
- Alternatives rejected: Clearing the durable marker with local facts; relying on scene activation
  to repair the UI; letting the first Enable tap fail silently; allowing Disable to abandon a
  pending zone deletion; resolving a content-free conflict; uploading every tombstone before the
  stronger whole-zone delete; or rewriting historical phase evidence as if it had never been true.

## DEC-COM-038 — Defer same-account two-device evidence without closing C4B-03

- Status/date: **Accepted owner scheduling boundary — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-036/037
- Context: Reviewed C4B-03 product head `f49de94` passed GitHub Actions run `32571676058`, and PR
  #61 merged it to `main` as `0f749ce`. The only prepared two-device attempt used different iCloud
  Apple Accounts, so the devices addressed different private databases. A same-account device
  arrangement is not currently available, and the owner requested that this verification be
  skipped for now.
- Decision: Defer the same-account two-device convergence/conflict run. Preserve the opt-in harness
  and the earlier different-account non-pass, but do not schedule another attempt in the current
  task. This is a temporary evidence deferral only: it is not a convergence pass, product failure,
  permanent waiver, release authorization, or permission to mark C4B-03/COM-C4B Done.
- Consequences: PR #61 closes the product code's independent-review, hosted-CI, and merge gates.
  C4B-03 and COM-C4B remain In Progress; C4C and distribution remain blocked. Physical account,
  offline, quota, and background-push evidence plus distribution signing and explicitly authorized
  Production deployment/release evidence remain open. A future same-account run may close the
  deferred evidence without changing the product contract.
- Alternatives rejected: Relabeling the different-account attempt as convergence; deleting the
  harness; silently removing multi-device evidence from the exit gate; treating temporary
  unavailability as a permanent waiver; marking C4B-03 Done because product code reached `main`;
  or entering C4C while COM-C4B remains open.

## DEC-COM-039 — Permanently waive the physical same-account two-device evidence gate

- Status/date: **Accepted owner evidence-scope override — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-036/037/038
- Context: DEC-COM-038 temporarily deferred the physical same-iCloud-account two-device
  convergence/conflict run because the available devices addressed different private databases.
  The owner has now explicitly made that evidence deferral permanent. Reviewed documentation head
  `0350415` passed GitHub Actions run `32573992659`, and PR #62 merged the preceding calibration as
  `0128682` before this scope decision.
- Decision: Permanently remove the physical same-account two-device convergence/conflict run from
  the C4B-03 and COM-C4B exit evidence. Preserve the stopped different-account attempt as a
  non-pass, and retain the compile-time opt-in harness as an optional diagnostic, not a required
  gate. The waiver applies only to that physical evidence item; it does not waive the product's
  deterministic multi-device lineage/conflict semantics or permit an automatic financial winner.
- Consequences: No same-account physical run is required to close C4B-03. This is a waiver, not a
  convergence pass or product-failure finding. C4B-03 and COM-C4B remain In Progress because
  physical account/offline/quota/background-push evidence, distribution signing, and explicitly
  authorized Production deployment/release evidence remain open. C4C and distribution remain
  blocked until their existing gates are closed.
- Alternatives rejected: Fabricating a pass; erasing the different-account attempt or DEC-COM-038;
  deleting the opt-in harness; weakening deterministic conflict/no-winner behavior; expanding the
  waiver to account/offline/quota/push or release evidence; or marking C4B-03 Done immediately.

## DEC-COM-040 — Keep production CKSyncEngine automatic scheduling enabled

- Status/date: **Accepted C4B-03 correction — 2026-08-22**
- Requirements: REQ-ICLOUD-001; DEC-COM-028/032/033/034/039
- Context: C4B-03 evidence closure audited the remaining physical background-push gate and found
  that the merged adapter set `CKSyncEngine.Configuration.automaticallySync` to `false`. The app
  had the exact remote-notification background mode, environment-specific push entitlement, and
  stable subscription ID, but an engine configured this way requires callers to initiate fetches
  and sends manually. Foreground/scene Retry therefore could not prove or provide automatic
  background delivery. Apple's
  [`automaticallySync`](https://developer.apple.com/documentation/cloudkit/cksyncengineconfiguration/automaticallysync)
  contract and its
  [SyncEngine sample](https://github.com/apple/sample-cloudkit-sync-engine) reserve `false` for
  explicit manual control/testing and keep production automatic scheduling on. Reviewed waiver
  head `7b23490` passed GitHub Actions run `32576885537`, and
  PR #63 merged as `1a14df9` before this runtime correction began.
- Decision: Every production `CKSyncEngine` created after explicit opt-in must set
  `automaticallySync = true` and retain the fixed private-database subscription ID. Explicit start,
  scene-activation, and Retry passes remain available for bounded immediate work, but they do not
  substitute for or disable Apple's indeterminate scheduling. Default-off adapter construction,
  local fact/outbox authority, durable inbox validation, no-winner quarantine, whole-zone delete,
  and sticky account/key-reset/zone-loss pauses are unchanged; stopping or entering a sticky pause
  still cancels and releases the engine.
- Consequences: The source and static contract can now support a real silent-push observation.
  The focused simulator run at
  `/private/tmp/MindBudget-C4B03-AutomaticSync-Focused1.xcresult` passed 38 selected results: 35
  deterministic passes and three physical-only skips. The follow-up opt-in Development run at
  `/private/tmp/MindBudget-C4B03-AutomaticSync-Physical2.xcresult` passed 36 results and explicitly
  skipped only the two permanently waived multi-device roles; its real case repeated the fixed-zone
  lifecycle and local preservation with automatic scheduling enabled. Neither run independently
  mutates the server while the app is backgrounded, so neither is physical silent-push evidence.
  C4B-03 stays In Progress for physical account/offline/quota/background-push, distribution
  signing, and explicitly authorized Production/release evidence.
- Alternatives rejected: Keeping automatic scheduling off and relabeling scene activation as
  background push; inventing a custom push handler beside `CKSyncEngine`; enabling an adapter before
  consent; weakening sticky pauses so a push can recreate a rejected zone; removing explicit Retry;
  or treating a source-level boolean as completed physical delivery evidence.

## DEC-COM-041 — Keep delegate cancellation and zone genesis outside accepted ancestry

- Status/date: **Accepted C4B-03 trust-boundary correction — 2026-08-24**
- Requirements: REQ-ICLOUD-001; DEC-COM-028/031/032/040
- Context: The physical background-delivery probe exposed two runtime boundaries that deterministic
  lifecycle coverage had not forced. First, awaiting an engine operation from the serialized
  `CKSyncEngineDelegate` callback task can re-enter that same callback and trigger CloudKit's client-
  misuse failure. Second, unconditionally queuing `saveZone` for an engine restored from accepted
  serialization can race the first fetch and recreate a remotely deleted zone before the sticky
  remote-zone-loss authority is observed. Both defects affect trust-boundary handling independently
  of whether a physical silent push can be captured.
- Decision: Delegate-triggered engine cancellation is scheduled from a detached task and clears
  only the same engine instance, so a late cancellation cannot discard an explicitly rebuilt
  replacement. The fixed private zone is created directly only for a newly consented transport with
  no accepted serialized ancestry. A restored transport fetches first; a missing, purged, deleted,
  or encrypted-key-reset zone remains a sticky pause and is never recreated automatically.
- Consequences: Deterministic tests pin automatic scheduling, detached delegate context, and the
  genesis-only creation predicate. The static iCloud gate rejects inline delegate cancellation and
  queued unconditional zone creation. The exact simulator CloudSync run after the final source
  correction passed 37 tests with four physical-only skips at
  `/private/tmp/MindBudget-C4B03-AutomaticSync-Focused6.xcresult`. This correction does not prove
  physical background delivery or authorize Production, distribution, or release.
- Alternatives rejected: Calling `cancelOperations()` inline from the delegate; clearing whichever
  engine happens to be current after a delayed task; recreating the custom zone for every restored
  engine; treating a missing accepted zone as ordinary transport failure; or weakening the sticky
  recovery contract to make the probe easier to pass.

## DEC-COM-042 — Permanently waive physical background-push evidence without recording a pass

- Status/date: **Accepted owner evidence-scope override — 2026-08-24**
- Requirements: REQ-ICLOUD-001; DEC-COM-039/040/041
- Context: Nine local result packages, `MindBudget-C4B03-BackgroundPush6.xcresult` through
  `MindBudget-C4B03-BackgroundPush14.xcresult`, were inspected. The attempts exposed and drove the
  DEC-COM-041 runtime corrections, but none observed an independently initiated Development
  mutation reaching the app while it remained backgrounded. Some attempts timed out before an
  external mutation, one failed before readiness because of the device network proxy, one could not
  launch because device trust was absent, one selected zero tests, and the final exact probe was
  canceled after the CloudKit Console was found to be acting as the wrong account. The evidence
  count is therefore zero physical background-push passes.
- Decision: Permanently remove only the physical Development background/silent-push observation
  from the C4B-03 and COM-C4B exit evidence. Preserve all attempt bundles as non-pass evidence and
  retain the compile-time opt-in probe as an optional diagnostic. This waiver must always be
  described as “not passed” and must never be converted into a delivery or convergence claim.
- Consequences: A physical background-push run is no longer required to close C4B-03. Production
  `automaticallySync = true`, the fixed subscription identifier, exact entitlements/background mode,
  detached delegate safety, genesis-only zone creation, local authority, durable inbox/outbox,
  quarantine, and sticky recovery remain mandatory. Physical account/offline/quota evidence,
  distribution signing, and explicitly authorized Production deployment/release evidence remain
  open; C4B-03 and COM-C4B remain In Progress and C4C remains blocked.
- Alternatives rejected: Calling any attempt a pass; erasing or combining the nine non-pass result
  packages; disabling automatic scheduling after waiving its physical observation; broadening the
  waiver to account/offline/quota or release evidence; deleting deterministic coverage; or marking
  C4B-03/COM-C4B Done in this decision.

## DEC-COM-043 — Close C4B with non-pass physical dispositions and retain release gates

- Status/date: **Accepted owner evidence-scope and phase-ownership decision — 2026-08-24**
- Requirements: REQ-ICLOUD-001; DEC-COM-039/040/041/042; COM-C4B/COM-C6/COM-C12
- Context: Reviewed final correction head `f1f37db` passed GitHub Actions run `32726507493`, and
  PR #64 merged it as `4f6d7fe`. The C4B product has deterministic account-change, offline,
  quota, retry, sticky-pause, local-authority, conflict, deletion, and reimport coverage; a signed
  physical Development lifecycle also passed. Physical same-account two-device and background-push
  observations were already permanently waived without passes. The remaining physical account-
  switch/offline/quota observations are unavailable or unsafe to force, the local keychain has no
  valid Distribution identity, and Production has no deployed app schema. None of these gaps alters
  StoreKit entitlement authority or local Pro behavior.
- Decision: Permanently remove only the physical account-switch, offline, and quota observations
  from the C4B-03/COM-C4B exit evidence. Record each as waived and not passed; retain all
  deterministic local-first/fail-closed tests and closed product behavior. Reassign Distribution
  signing and owner-authorized Production schema deployment, final-binary/traffic verification,
  and release proof to COM-C6/COM-C12. Those release gates are not waived, and this decision does
  not authorize any Production, Archive/upload, tester, review, or release action.
- Consequences: C4B-03 and COM-C4B are Done, and COM-C4C is unblocked. The five physical evidence
  dispositions—same-account two-device, background push, account switch, offline, and quota—remain
  non-passes and cannot be cited as successful physical validation. Free iCloud sync stays
  default-off and local-first; StoreKit purchase/restore/entitlement authority remains independent.
  COM-C6/COM-C12 must still obtain the appropriate signing identity, explicitly authorized
  Production schema/deployment evidence, and their full distribution/release proof before those
  exits can close.
- Alternatives rejected: Fabricating physical passes; weakening deterministic coverage; treating
  a missing signing identity or undeployed Production schema as complete; deploying Production to
  unblock local receipt work; allowing an iCloud failure to affect StoreKit or local Pro; or
  waiving later distribution/release gates.

## DEC-COM-044 — Add advanced rule evidence without taking away the Free baseline

- Status/date: **Accepted C4C-01 implementation decision — 2026-08-25**
- Requirements: REQ-ENTITLEMENT-001; REQ-RECEIPT-PIPELINE-001;
  REQ-RECEIPT-PRIVACY-001; SPEC-010/015; DEC-COM-014
- Context: C4C-01 requires central premium seams, rule sample/confidence evidence, and local-model/
  deterministic baselines. The entitlement vocabulary already reserves advanced local insights,
  purchase-preflight/post-purchase variants, receipt scan/import, and Apple on-device AI for Pro.
  DEC-COM-014 separately guarantees the current five-item wishlist, 30-day Insights, deterministic
  templates, and basic reminder/review behavior to Free, so C4C-01 cannot implement its advanced
  layer by locking those existing paths.
- Decision: Extend `ExistingPremiumEntryAccess` with immutable decisions for advanced local
  insight evidence, future purchase-preflight/post-purchase variants, receipt scan, and receipt
  import. Keep existing deterministic insight generation, reminder presentation, and durable
  review rows Free. Every new detector-produced rule carries `sampleCount`,
  `supportingSampleCount`, and `confidenceBasisPoints`; confidence is the exact supporting/total
  ratio truncated to integer basis points, not a probability or model score. Persist the evidence
  inside the existing typed JSON payload under three reserved keys, separate it on read, accept
  legacy rows with no triple, and fail closed on partial/inconsistent triples. Show the evidence
  line only when the central `advancedLocalInsights` decision allows it.
- Receipt baseline: Define only `.unavailable`, `.deterministic`, and
  `.deterministicWithOnDeviceModel`. Both usable tiers require deterministic extraction; there is
  no model-only or remote-model tier. Product scope remains disabled, and this packet adds no image,
  OCR, temporary file, receipt persistence, prompt, or egress. SPEC-015's future float exception is
  limited to the exact `ReceiptGeometry.swift` and `ReceiptVisionObservation.swift` paths and
  rejects money vocabulary there.
- Consequences: Exact Free retains its existing user value. Pro gains independently recomputable
  evidence presentation, while entitlement removal merely hides that evidence and does not delete
  financial or derived local rows. Missing local-model capability will fall back deterministically
  after a later packet opens receipt product scope. C4C-02 through C4C-05 remain blocked until
  C4C-01 passes independent review, hosted CI, merge, and explicit owner entry.
- Alternatives rejected: Making the current Insights/reminder experience paid; computing confidence
  with `Double`/`Float`; treating the ratio as statistical certainty; adding a model-only receipt
  tier; enabling `FeatureFlags.enableReceiptImport`; adding camera/OCR/persistence early; accepting
  partial evidence metadata; or widening the Vision float exception by directory or filename
  pattern.

## DEC-COM-045 — Bound receipt image acquisition before OCR and persistence

- Status/date: **Accepted C4C-02 implementation decision — 2026-08-25**
- Requirements: REQ-ENTITLEMENT-001; REQ-RECEIPT-PIPELINE-001;
  REQ-RECEIPT-PRIVACY-001; SPEC-015; DEC-COM-044
- Context: Reviewed C4C-01 source merged through PR #66 and its closeout merged through PR #67
  (`bdb94d9`). The owner then explicitly entered C4C-02. This subpacket owns source selection,
  permission/hardware availability, orientation, perspective geometry, resource limits,
  cancellation, and temporary cleanup. OCR, extraction, validation, confirmation, and receipt
  persistence belong to later subpackets and cannot be inferred from image acquisition.
- Decision: Keep `FeatureFlags.enableReceiptImport` false and require both future product scope and
  the central Pro receipt baseline before any acquisition surface can be available. Use PHPicker
  for a single image without broad Photo Library permission and DataScanner as a camera surface
  without a delegate or recognized-item consumer. Request camera permission only after a future
  explicit camera-source action. Reject empty, corrupt, overflowed, over-48-MiB, or over-64-million-
  pixel source input; use ImageIO to apply orientation while thumbnail-decoding to a 4,096-pixel
  edge; cap the prepared image at 12 million pixels and 8 MiB. Restrict Vision to normalized
  rectangle geometry and Core Image perspective correction in the exact SPEC-015 files. Keep only
  one prepared JPEG in one file-protected, backup-excluded temporary directory. Caller/lifecycle
  cancellation, replacement, startup orphan cleanup, background/inactive transitions, memory
  pressure, Delete All, and AppSession teardown all converge on idempotent removal.
- Consequences: Source bytes never enter the temporary store; prepared bytes are never SwiftData,
  iCloud, analytics, logs, model input, or network payload in this packet. `NSCameraUsageDescription`
  exists in English and Simplified Chinese, but the disabled product scope means this build has no
  receipt customer entry and cannot initiate the prompt. PHPicker uses a temporary file
  representation and materializes no more than the source-byte limit plus one sentinel byte.
  Ten focused tests pass at
  `/private/tmp/MindBudget-C4C02-Focused5.xcresult`, including source-pixel rejection, caller and
  lifecycle cancellation, startup crash-orphan cleanup, and repeated prepared-only teardown.
  C4C-03 remains blocked pending reviewed merge and a separate owner entry.
- Alternatives rejected: Enabling receipt import with acquisition alone; requesting camera access
  at launch; requesting broad Photos permission; decoding unbounded full-resolution images;
  retaining original source bytes; storing receipt images in SwiftData, app backup, or iCloud;
  consuming DataScanner/Vision text results; starting local-model or network processing; treating
  temporary-file cleanup as best-effort UI work; or claiming C4C-05 resource stability from this
  smaller lifecycle regression.

## DEC-COM-046 — Close C4C-02 without entering OCR work

- Status/date: **Accepted reviewed-merge closeout — 2026-08-26**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001; DEC-COM-045
- Context: Independent review found no P1/P2 issue on exact head `43c3a35`. GitHub Actions run
  `32860643712` completed successfully on that head, and PR #68 merged the bounded acquisition and
  image-lifecycle substrate to `main` as `4ca8f1c`. The receipt product flag remains off, so this
  merge adds no enabled customer surface or permission prompt.
- Decision: Mark C4C-02 Done on the reviewed source/CI/merge evidence only. Preserve the exact
  acquisition, resource-limit, one-artifact, and cleanup boundaries from DEC-COM-045. Do not infer
  owner entry into C4C-03, OCR accuracy, physical system-adapter behavior, 20-image resource
  stability, receipt persistence, Production action, or release authority from this merge.
- Review follow-up: When a later UI consumes DataScanner availability, replace the current
  generation-oriented `.superseded` error for `isAvailable == false` with a dedicated temporary-
  availability error and corresponding presentation. Physical DataScanner/PHPicker behavior and
  the 20-image stability matrix remain C4C-05 evidence. Non-money image compression-quality
  floating-point literals do not widen SPEC-015 or authorize floating-point money.
- Consequences: C4C-02 is Done; C4C-03 through C4C-05 remain blocked pending separate owner entry
  and predecessor completion. `enableReceiptImport` remains false. No source or prepared receipt
  bytes enter SwiftData, CloudKit, backup, logs, a model prompt, or any network channel.
- Alternatives rejected: Fixing a non-blocking dormant-adapter error taxonomy by expanding the
  reviewed C4C-02 source after merge; treating infrastructure existence as physical evidence;
  treating image-quality floats as money-policy exceptions; entering OCR automatically; or marking
  either active receipt Requirement or COM-C4C complete.

## DEC-COM-047 — Make privacy-filtered local text the only OCR output

- Status/date: **Accepted C4C-03 implementation decision — 2026-08-26**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001; SPEC-015;
  DEC-COM-044/045/046
- Context: C4C-02 documentation head `4ab0daf` passed GitHub Actions run `32911659905`, and PR #69
  merged that closeout as `3e1c5c9`. The owner then explicitly entered C4C-03. This packet owns
  local OCR geometry/order/confidence and mandatory pre-model sensitive-pattern removal, not field
  extraction, money interpretation, confirmation, persistence, a customer surface, or release.
- Decision: Confine `VNRecognizeTextRequest`, recognized candidates, and raw strings to the exact
  `ReceiptVisionObservation.swift` adapter and its immediately invoked privacy pipeline. Permit an
  output line only with `ReceiptModelSafeText`, whose constructor is file-private to the filter.
  Replace 13–19 Unicode-digit card shapes with common separators, English or Chinese labelled/
  masked last-four shapes, and labelled authorization/approval codes with `[redacted]`; do not
  require Luhn validity. Retain normalized bounds and confidence on the filtered line. Order by a
  fixed normalized vertical band, then horizontal origin, source index, and stable input index.
  Cap input at 256 observations, 512 UTF-8 bytes per line, and 16 KiB per filtered document.
  Reject the whole document for invalid geometry/confidence, capacity overflow, or filter failure.
- Consequences: Raw recognized receipt text has no type path to models, SwiftData, CloudKit, logs,
  or egress. Over-redaction is preferred to allowing a plausible payment credential. Empty lines
  may disappear only after control/whitespace normalization; a sensitive-only line remains as a
  marker so geometry/order evidence is not silently removed. Seven deterministic tests cover the
  accepted patterns, stable order, retained metadata, and fail-closed limits. The product flag
  remains false, and C4C-04/C4C-05 remain blocked.
- Alternatives rejected: Returning raw OCR plus a caller instruction to redact; making safe text a
  public/internal memberwise initializer; relying on Luhn validity after OCR; silently truncating
  an over-limit document; using unstable collection order; persisting an intermediate; sending
  OCR to a remote model; enabling receipt import; or claiming C4C-04/C4C-05 accuracy/confirmation
  evidence from this infrastructure packet.

## DEC-COM-048 — Close C4C-03 without entering structured extraction

- Status/date: **Accepted reviewed-merge closeout — 2026-08-26**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001; DEC-COM-047
- Context: Independent review found no P1/P2 issue on exact source head `92ed3a7`. The accepted
  P3 ordering hardening documented that complete-card removal must precede labelled-last-four
  removal and added a regression fixture that exposes any future reordering. GitHub Actions run
  `32921913143` completed successfully on that exact head, and PR #70 merged the bounded local
  OCR/privacy substrate to `main` as `d294cfb`.
- Decision: Mark C4C-03 Done on the reviewed source, green hosted CI, and merge evidence only. Do
  not infer entry into C4C-04, receipt-field accuracy, confirmation, persistence, physical OCR,
  resource stability, Production action, or release authority. Preserve the rule-order invariant
  and the exact raw-text confinement and fail-closed limits from DEC-COM-047.
- Review follow-up: A continuous 20-plus-digit value remains outside the accepted 13–19 digit PAN
  shape. Spaced-mask variants belong in the C4C-05 60-plus-fixture evaluation before any matcher
  expansion. Regex caching remains an optional bounded optimization. A future C4C-04 caller must
  run Vision recognition away from the main actor.
- Consequences: C4C-03 is Done. `enableReceiptImport` remains false, and C4C-04/C4C-05 remain
  blocked pending separate explicit owner entry and predecessor completion. No structured receipt
  field, money interpretation, persistence, model/network content, customer entry, Production,
  distribution, or release behavior is authorized by this closeout.
- Alternatives rejected: Entering C4C-04 automatically after merge; broadening sensitive-pattern
  matching without fixture evidence; treating deterministic privacy tests as receipt-accuracy or
  physical-system evidence; enabling the dormant product flag; or marking COM-C4C or either active
  receipt Requirement complete.

## DEC-COM-049 — Keep structured receipt authority deterministic

- Status/date: **Accepted C4C-04 implementation decision — 2026-08-26**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001; REQ-MONEY-001;
  DEC-COM-044/045/046/047/048
- Context: PR #71 merged the C4C-03 documentation closeout as `08fb718`, after which the owner
  explicitly entered C4C-04. This packet owns only ephemeral structured extraction and exact
  validation. C4C-05 still owns customer wiring, confirmation-before-persistence, the 60-plus
  receipt/non-receipt fixture matrix, physical/resource evidence, and accuracy gates.
- Decision: Run a deterministic extractor before any optional model work and keep every accepted
  deterministic field authoritative. The optional Foundation Models adapter runs on device and
  receives only the bounded `ReceiptOCRDocument` created after C4C-03 filtering. It may return only
  exact contiguous evidence snippets. Deterministic code re-proves that provenance and alone
  interprets merchant, calendar date, ISO currency, currency exponent, integer minor units, range,
  and exact duplicate identity. Missing, ambiguous, invalid, mismatched, unsupported-scale, and
  out-of-range states remain typed; none becomes zero. Model absence, timeout, error, invented
  evidence, or unusable output returns the deterministic result. The line-item experiment defaults
  off and has no production enablement path in this packet.
- Consequences: The candidate has no UI, permission prompt, confirmation, persistence, SwiftData/
  CloudKit field, logging, telemetry, remote model, or network path. The C4C-03 raw/safe-text type
  boundary remains exact. A later C4C-05 integration must execute Vision recognition away from the
  main actor and may persist nothing before explicit user confirmation. C4C-05 remains blocked.
- Alternatives rejected: Letting a model produce normalized values or override deterministic
  fields; treating model output as authority; accepting binary floating-point money; inferring
  currency or zero from missing evidence; fuzzy duplicate winners; enabling experimental line
  items by default; moving confirmation/persistence or the accuracy/resource matrix into C4C-04;
  sending receipt text to an existing advice/network service; or enabling receipt import.

## DEC-COM-050 — Close C4C-04 without entering confirmation and evaluation

- Status/date: **Accepted reviewed-merge closeout — 2026-08-26**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001; REQ-MONEY-001;
  DEC-COM-049
- Context: Initial independent review found no P1 issue and two P2 fail-closed inconsistencies:
  one valid amount token could hide an invalid sibling on the same line, and optional-model output
  could replace a deterministic rejection. Exact remediation head `f2d249d` makes any same-line
  parse failure reject the amount and permits model supplementation only for deterministic
  `.missing`. The 17-test focused suite and complete local validation passed. Independent rereview
  approved that exact head, GitHub Actions run `32946104780` completed successfully, and PR #72
  merged the bounded structured-extraction implementation to `main` as `e6316fa`.
- Decision: Mark C4C-04 Done on the reviewed remediation source, green hosted CI, and merge
  evidence only. Do not infer entry into C4C-05 or enable receipt import. Preserve deterministic
  accepted/rejected authority, exact-evidence provenance, integer minor-unit interpretation, typed
  missing/invalid states, default-off line items, and the no-persistence/no-egress boundary.
- Review follow-up: C4C-05 must evaluate generic three-uppercase-letter currency markers and broad
  `total` substring matching against its 60-plus receipt/non-receipt fixture matrix, run Vision
  integration away from the main actor, and own physical acquisition/OCR, accuracy, 20-image
  stability, customer confirmation, and persistence evidence. These observations are not C4C-04
  failures and are not evidence that those later gates passed.
- Consequences: C4C-04 is Done. `enableReceiptImport` remains false, all structured results remain
  ephemeral, and C4C-05 remains blocked pending separate explicit owner entry. COM-C4C and both
  receipt Requirements remain active. No Production, Archive/upload, tester, distribution, or
  release action is authorized by this closeout.
- Alternatives rejected: Entering C4C-05 automatically after merge; treating a deterministic
  rejection as model-fillable; weakening same-line amount validation; calling simulator extraction
  tests receipt accuracy or physical OCR evidence; enabling the product flag; persisting before
  confirmation; or marking COM-C4C or either active receipt Requirement complete.

## DEC-COM-051 — Confirm locally, then reuse the existing expense Save boundary

- Status/date: **Accepted C4C-05 implementation/evaluation decision — 2026-08-26**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001; REQ-MONEY-001;
  DEC-COM-044/045/046/047/048/049/050
- Context: PR #73 merged the C4C-04 documentation closeout as `2107723`, and the owner explicitly
  entered C4C-05. The predecessor packets already own bounded acquisition, local OCR/privacy, and
  deterministic structured candidates. C4C-05 must create the customer boundary without making a
  raw image, OCR line, model snippet, or unreviewed field durable.
- Decision: Enable `enableReceiptImport` and expose `Scan a Receipt` only from the existing
  new-expense form when the immutable Commerce snapshot grants both receipt rights. Camera
  permission follows an explicit camera-source tap; PHPicker remains one-image and requests no
  broad library permission. Run bounded image processing plus accurate Vision OCR off the main
  actor, apply the C4C-03 privacy filter before any optional on-device model, and delete the one
  protected temporary prepared JPEG before presenting a result. The optional Apple model is used
  only when the existing user setting is enabled and runtime capability is available; otherwise
  verified Pro keeps the deterministic offline tier. Review copies only accepted merchant/date/
  total fields into the editable form and performs no write. The existing explicit Save action is
  the sole persistence boundary, retaining current exact Money, budget, reminder, and validation
  behavior. A saved imported expense stores only normal expense facts plus the closed non-content
  source enum `receiptImport`; receipt image/OCR/model/duplicate evidence is never stored.
- Evaluation: The checked-in deterministic matrix requires 60 exact supported receipts (20 each
  USD/JPY/KWD) and ten nonreceipts with no accepted total. It specifically prevents generic
  `USA`/`THE`/`IBM` from impersonating a supported currency and prevents `Totally` from matching
  the `total` label. The zero-leak matrix adds spaced-mask last-four coverage. Twenty sequential
  real JPEG lifecycle iterations must stay bounded, keep at most one artifact, and leave none.
  These are deterministic contract gates, not a population-wide OCR accuracy claim.
- Open evidence: Physical DataScanner capture, PHPicker selection, and resulting local OCR remain
  mandatory and are not passed by simulator tests. Independent review, hosted CI on the reviewed
  head, and merge remain required before C4C-05 can be Done.
- Consequences: No SwiftData schema or CloudKit envelope changes. No URLSession, HTTP(S), remote
  model, telemetry, receipt logging, Production, Archive/upload, tester, distribution, release, or
  COM-C5 authority. Exact Free or unavailable StoreKit authority exposes no receipt entry. A
  missing local model does not remove the deterministic Pro baseline.
- Alternatives rejected: A receipt-specific direct writer; persistence when the review sheet is
  accepted rather than when Save is tapped; storing a receipt draft/image/OCR for later; treating
  model output or OCR as authority; blocking deterministic extraction when the model is absent;
  broad Photo Library permission; remote OCR/model use; syncing receipt intermediates; counting a
  generated/simulator fixture as physical evidence; or marking either receipt Requirement, C4C-05,
  COM-C4C, or a release gate complete before review/CI/merge.

## DEC-COM-052 — Bound real-device image and Vision drift without accepting uncertain fields

- Status/date: **Accepted C4C-05 physical-remediation decision — 2026-08-26**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001; REQ-MONEY-001;
  DEC-COM-045/047/049/051
- Context: The first physical paper-invoice attempts on `拉沙的iPhone` exposed two fail-closed
  interoperability defects. A common 4032 x 3024 capture stayed at source dimensions because the
  4096 edge limit alone did not trigger ImageIO downsampling, then exceeded the separate 12-million
  prepared-pixel limit. After that was fixed, local Vision returned a text observation whose
  normalized bounding box drifted a fraction outside the documented unit square, causing the whole
  document to reject as `ocr.invalidGeometry`.
- Decision: Derive ImageIO's requested thumbnail edge from both the maximum edge and maximum
  prepared-pixel contracts using checked integer arithmetic. Accept only finite positive Vision
  geometry whose edges remain within 0.005 of the unit square, clamp that bounded drift, and keep
  every larger or degenerate shape fail-closed. Log only closed non-content receipt reason codes;
  never log an image, OCR text, merchant, amount, or other receipt-derived value.
- Physical evidence: Under Xcode 27 beta 6 (`27A5252f`) on physical iOS 26.6.1, DataScanner camera
  capture reached local review with accepted merchant/date while an uncertain total remained manual
  review. Applying that review and canceling the expense form wrote nothing. A separate one-image
  PHPicker selection reached review and produced exactly one `$25.00` expense only after explicit
  Save. Focused remediation tests pass 21/21 at
  `/private/tmp/MindBudget-C4C05-PhysicalRemediation.xcresult`.
- Consequences: The mandatory physical acquisition/OCR and confirmation boundary are evidenced.
  This is not a claim that the uncertain paper-invoice amount was recognized, nor a population-wide
  accuracy claim. C4C-05 stays In Progress pending independent review, green hosted CI on the
  reviewed head, and merge. No Production, Archive/upload, tester, distribution, or release action
  is authorized.
- Alternatives rejected: Raising the source or prepared-pixel limits; accepting all Vision geometry;
  dropping the whole physical requirement; guessing the missing total; persisting on review; logging
  receipt content for diagnosis; or marking C4C-05/COM-C4C Done before review, CI, and merge.

## DEC-COM-053 — Redesign receipt capture without implying unavailable live detection

- Status/date: **Accepted C4C-05 presentation-remediation decision — 2026-08-27**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001;
  DEC-COM-044/045/046/047/048/049/050/051/052
- Context: Physical evaluation proved the bounded DataScanner/PHPicker/OCR boundary, but the
  acquisition-to-review journey used several full-screen steps and did not give the user a clear
  capture hierarchy. The owner supplied a UI/UX redesign handoff whose full alignment state assumes
  per-frame rectangle detection. The accepted C4C-02 DataScanner adapter intentionally exposes no
  frame or delegate, so claiming live alignment or automatic cropping would be false without a new
  AVCapture/Vision privacy and performance surface.
- Decision: Implement the handoff's recommended option A. Keep DataScanner as the bounded camera
  authority with system guidance disabled, place one custom 72-point shutter beneath an always-white
  breathing frame, and never show an aligned state or promise automatic cropping. Add the local-only
  privacy badge, three-state torch control, PHPicker action, honest capture preview, and first-use
  explanation. Move recognition back to the expense form under a generation-protected task, show
  progress/failure/review inline, preserve user edits, and keep the existing explicit Save action as
  the sole persistence boundary. The photo control remains a generic icon because a recent-photo
  thumbnail would require broader library access. Long-receipt stitching remains a disabled,
  accessibility-labelled visual slot because no reviewed interaction or processing contract exists.
- Consequences: The redesign changes presentation and navigation only. It adds no camera frame
  processing, live rectangle detector, automatic crop, broad Photos permission, schema, receipt
  persistence, CloudKit field, network path, remote model, telemetry, or content log. Cancellation,
  backgrounding, generation replacement, and Delete All continue to discard ephemeral receipt state.
  Manual amount entry may release the temporary recognition Save gate, but a late recognition result
  cannot overwrite a field changed after recognition began. C4C-05 remains In Progress pending
  independent review, green hosted CI, and merge.
- Alternatives rejected: Showing a fake green alignment state; presenting crop language when only
  geometry correction after capture exists; adopting VNDocumentCamera and discarding the custom
  hierarchy; creating AVCaptureSession plus VNDetectRectanglesRequest inside this packet; requesting
  broad Photos access for a cosmetic thumbnail; implying that the disabled long-receipt slot performs
  stitching; restoring a full-screen processing or review page; or persisting before explicit Save.

## DEC-COM-054 — Make edit ownership and artifact identity authoritative

- Status/date: **Accepted C4C-05 independent-review remediation — 2026-08-27**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001;
  DEC-COM-051/052/053
- Context: Independent review found that two persistence/edit-preservation tests exercised an
  unreachable unconditional prefill helper instead of the production recognition path. The live
  path inferred ownership from value equality, so a user who changed a field and returned it to its
  starting value could be overwritten by late recognition. The inline UI also discarded typed
  failure reasons, acquisition gates impersonated local-storage failure, inactive scenes destroyed
  captured work, and cleanup carried no artifact identity.
- Decision: Remove the unconditional helper and drive the production generation through tests.
  Track edit ownership separately for amount, merchant, and date; once edited, a field remains
  user-owned for that recognition generation regardless of its final value. Copy only accepted,
  non-user-owned fields, and keep explicit Save as the only writer. Preserve each closed failure as
  a distinct localized title/detail plus a recovery action appropriate to that failure. A true
  background transition cancels and discards receipt work; an inactive transition covers it with a
  privacy shield and resumes on active. Give each prepared artifact an identity and allow late task
  cleanup to remove only the matching artifact, never a replacement generation.
- Consequences: Rejected/missing suggestions and any user-edited field cannot be overwritten by
  late OCR. Product-disabled/requires-Pro are disclosed as access states, not storage faults, and a
  local-data failure no longer suggests that taking another photo will repair storage. Tests now
  prove the no-write-before-Save boundary through the same production method the app uses, protect
  edit-then-return-to-starting-value for all three fields, and prove stale artifact cleanup cannot
  delete a newer generation. If every accepted suggestion remains user-owned, recognition has not
  contributed a field and the later explicit Save truthfully retains `.manual` provenance.
  C4C-05 remains In Progress pending rereview, green hosted CI, and merge.
- Alternatives rejected: Keeping a shorter unconditional internal API beside the guarded path;
  using current value equality as a proxy for user intent; clearing edit ownership when a value
  returns to its starting state; flattening all failures into one retake card; destroying work on
  transient inactive transitions; allowing unscoped late cleanup; or recording `receiptImport`
  provenance when no recognized field contributed to the saved expense.

## DEC-COM-055 — Close C4C-05 and COM-C4C after post-merge exact-delta review

- Status/date: **Accepted post-merge exact-delta closeout — 2026-08-27**
- Requirements: REQ-RECEIPT-PIPELINE-001; REQ-RECEIPT-PRIVACY-001; REQ-MONEY-001;
  DEC-COM-051/052/053/054
- Context: Independent review through remediation head `8607356` required the receipt flow to prove
  the actual production path,
  persistent edit ownership, truthful typed failures, non-destructive inactive handling, and
  artifact-scoped cleanup. DEC-COM-054 closed those findings. Follow-up P3 maintenance then made
  recognition waits bounded, removed the orphaned unreadable-image string, and compiler-enforced
  the three receipt-prefill mutation boundaries. Exact final head `81cd107` passed 76/76 focused
  maintenance tests, retained the complete 522-unit/17-UI local evidence, passed GitHub Actions run
  `33035427257`, and merged through PR #74 as `d751ff4` without pre-merge rereview. During PR #75's
  2026-08-27 closeout review, the independent reviewer read that exact maintenance delta and
  confirmed all three P3 fixes correct.
- Decision: Mark C4C-05 and COM-C4C Done on the pre-merge review of `8607356`, final-head CI/merge,
  and post-merge exact-delta review. Preserve the local,
  verified-Pro-only, explicit-Save, no-egress boundary. Record physical DataScanner/PHPicker/local-
  OCR and cancel-versus-Save evidence as passed, but keep the uncertain paper-invoice amount as a
  manual-review-only non-pass rather than broadening it into an accuracy claim.
- Consequences: The local receipt pipeline and privacy implementation satisfy COM-C4C's exit gate.
  REQ-RECEIPT-PIPELINE-001 and REQ-RECEIPT-PRIVACY-001 remain Active for their later final-binary,
  remote-provider, and release verification in C6/C8/C12. COM-C5 is no longer dependency-blocked by
  COM-C4C, but it remains unopened pending explicit owner entry and accepted first-party telemetry
  conflict resolution. No Production, Archive/upload, tester, distribution, or release action is
  authorized.
- Alternatives rejected: Calling the uncertain physical total recognized; treating review-prefill
  as persistence; persisting receipt images/OCR/model evidence; opening a network or CloudKit
  receipt channel; marking later release/privacy verification complete; entering COM-C5
  automatically; or using this closeout as telemetry, Production, TestFlight, or release authority.

## DEC-COM-056 — Enter COM-C5 through a dormant, closed-schema C5-01 client

- Status/date: **Accepted owner-entry and C5-01 implementation decision — 2026-08-27**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; REQ-RECEIPT-PRIVACY-001;
  SPEC-009/012; DEC-COM-001/002/003/004/055
- Context: PR #75 merged the reviewed C4C-05/COM-C4C closeout as `82ef0fa`, satisfying the
  predecessor dependency. The owner then explicitly entered COM-C5. The first-party telemetry
  domain, endpoint, receiver bytes, TTL, deletion service, monitoring, costs, customer disclosure,
  App Privacy answers, and final-binary traffic are still unverified. Implementing a network adapter
  or production capture calls in C5-01 would therefore make an unaccepted channel reachable.
- Decision: Open only C5-01. Add a closed `TelemetryEvent` enum and exact upload/deletion envelope;
  it has no arbitrary property dictionary or content field. Missing state is default-off and creates
  no file/key/identity. A 30-day pseudonym generation owns a random deletion secret; reset rotates,
  opt-out clears unsent events and retires that generation, and re-enable creates a different
  pseudonym. Retain deletion proofs for a bounded 90-day local target while referenced; cap the
  encrypted AES-GCM/file-protected/non-backed-up queue at 256 events and four identity generations;
  send at most 20 events from one generation; serialize each local read/modify/write; use bounded
  backoff; and treat corrupt persistence as sticky invalid. Only confirmed deletion may destroy
  retained proofs. Keep `UnavailableTelemetryTransport` as the only production default and forbid
  every production client construction/capture call, URL, endpoint, and network primitive in this
  packet.
- Consequences: The checked-in app continues to collect and transmit zero telemetry. No customer
  control or disclosure is presented yet because there is no reachable client or receiver, and App
  Privacy answers do not change. C5-01 can prove local type/persistence/concurrency/deletion
  semantics but cannot claim real server TTL, deletion, unknown-field rejection, environment
  isolation, monitoring, cost, capture audit, disclosure, or egress. C5-02 through C5-04 remain
  blocked; COM-C6 and Production/distribution/release remain blocked.
- Alternatives rejected: Embedding a provisional URL; accepting `[String: Any]` or caller-defined
  properties; recording money, merchant, note, category, receipt/OCR/model evidence, StoreKit IDs,
  or CloudKit envelopes; using an advertising/vendor/device/account identifier; reusing a pseudonym
  after opt-out; deleting a failed proof; persisting plaintext or an unbounded queue; allowing
  concurrent actor suspension to lose a capture; wiring dormant code into AppSession/Settings;
  treating focused client tests as receiver/TTL/deletion evidence; entering C5-02 automatically; or
  authorizing Production/release.

## DEC-COM-057 — Preserve privacy deletion under corruption and scope pseudonym unlinkability

- Status/date: **Accepted C5-01 independent-review remediation — 2026-08-27**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-056
- Context: Independent review found that sticky corrupt persistence correctly blocked collection
  and overwrite but also made the encrypted file and device-only at-rest key impossible to delete.
  It also found that the broad word “unlinkability” obscured a deliberate deletion-envelope
  tradeoff: normal upload envelopes carry only one non-reused pseudonym, while one complete-delete
  request groups every retained generation proof. The dormancy scan depended on `rg` inside a shell
  conditional and therefore treated a missing tool as a clean scan, and the new gate had no positive
  or negative fixture self-tests.
- Decision: Keep corrupt state sticky for collection, opt-in, capture, and overwrite, but allow the
  explicit privacy deletion to remove the unreadable file and at-rest key without parsing it. Return
  `.deletedLocallyWithoutRemoteProofs`, restore an empty available state only after that local delete
  succeeds, and never imply that unreadable remote proofs were exercised. Define unlinkability
  narrowly and mechanically: ordinary upload envelopes never reuse or group pseudonyms across
  opt-out/re-enable. A delete request intentionally groups the bounded retained proof set to avoid
  partial deletion; C5-02 must process that association only for deletion and must not persist, log,
  or reuse it. Keep identity-capacity enforcement only where a new identity is created. Record the
  four-generation re-enable failure for C5-04 guidance and require C5-02 to decide and test in-flight
  upload cancellation. Replace the dormancy scan with an explicitly fail-closed `grep` result model
  and run positive/negative event, envelope, construction, and scan-failure fixtures on every gate
  invocation.
- Consequences: A malformed, oversized, unauthenticated, structurally invalid, or missing-key local
  telemetry file can always be removed together with its local key, while the client truthfully
  distinguishes that result from confirmed remote deletion. Normal uploads remain pseudonym-
  separated; the deletion association is explicit, bounded, and reserved for later first-party
  deletion processing. C5-01 remains dormant with zero collection and egress, and C5-02 through
  C5-04 remain blocked.
- Alternatives rejected: Blocking privacy deletion because content cannot be authenticated;
  reporting corrupt local cleanup as remote deletion; claiming deletion-envelope unlinkability;
  sending one proof per immediately adjacent request and pretending shared timing/connection
  metadata cannot correlate them; accepting partial deletion state solely to avoid the grouped
  request; discarding a retained proof to make re-enable succeed; letting a missing scan tool pass;
  or using this remediation to add a live transport, customer setting, Production, or release.

## DEC-COM-058 — Keep default-off storage-free and separate transport from persistence failure

- Status/date: **Accepted C5-01 final review remediation — 2026-08-27**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-056/057
- Context: Final independent review found that calling `setCollectionEnabled(false)` on a missing
  never-enabled state still committed `.disabled`, creating an encrypted file and device-only key
  despite the default-off zero-write contract. It also identified a UTC default behind the stated
  user-calendar lifecycle, a retry test that did not exercise capture, upload-result commit failure
  being relabeled as transport failure, a remote-delete/local-cleanup retry that requires server
  idempotency, and two existing tests omitted from the static gate anchors.
- Decision: Make an already-disabled request return before persistence. Default `TelemetryPolicy`
  to `Calendar.autoupdatingCurrent` and continue allowing deterministic injected calendars. Keep
  transport failure as the only path that advances transport backoff; when a transport resolution
  was received but local state cannot commit, return `.persistenceFailed` without changing the
  prior local authority or inventing a transport retry. Require C5-02 event ingestion to deduplicate
  event IDs and proof deletion to accept an identical retry, because remote success can precede a
  failed local acknowledgement or cleanup. Exercise capture while backoff is active and make every
  current telemetry test an explicit static-gate anchor.
- Consequences: Merely reading, capturing while disabled, or repeating Disable on never-enabled
  telemetry cannot create a file, key, identity, or write. Rotation/proof deadlines obey the user's
  calendar and time zone without fixed-duration days. A local commit failure is observable without
  being misdiagnosed as network instability, and the later C5-02 service contract must be
  idempotent before any transport becomes reachable. C5-01 remains dormant with zero collection
  and egress; C5-02 through C5-04 remain blocked.
- Alternatives rejected: Persisting `.disabled` for symmetry; creating a key before affirmative
  opt-in; keeping an undocumented UTC calendar; renaming a test without exercising capture;
  incrementing transport backoff after a successful remote response; deleting local proof state
  after cleanup failure; assuming remote upload/delete is exactly-once; weakening static anchors;
  or using this fix to enter C5-02, add egress, Production, distribution, or release.

## DEC-COM-059 — Close only the reviewed dormant C5-01 client

- Status/date: **Accepted C5-01 reviewed-merge closeout — 2026-08-28**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-056/057/058
- Context: Independent review approved exact final PR #76 head `d937dc8`. GitHub Actions run
  `33085630481` completed successfully on that head, and PR #76 merged to `main` as `68304ad`.
  The reviewed implementation contains no production `TelemetryClient` construction, capture call,
  URL, receiver, network transport, customer setting, or App Privacy change.
- Decision: Mark C5-01 Done on that exact evidence. Keep COM-C5 In Progress. C5-02 is no longer
  dependency-blocked by C5-01 but remains unopened pending a separate explicit owner instruction;
  C5-03 and C5-04 remain blocked by their predecessors. Preserve `UnavailableTelemetryTransport`
  as the only production default and preserve zero telemetry collection and egress until C5-02
  accepts and implements its complete receiver/deletion/environment/monitoring/cost contract.
- Consequences: C5-01's closed schema, encrypted bounded persistence, deletion-proof lifecycle,
  serialization, batching/backoff, and fail-closed static gate are accepted as a dormant local
  capability. The closeout is not endpoint, server TTL/deletion, capture, disclosure, App Privacy,
  Production, distribution, or release evidence. REQ-R1-TELEMETRY-001 remains Active through later
  COM-C5 and final-binary verification.
- Alternatives rejected: Entering C5-02 automatically; treating the unavailable transport as a
  deployed channel; describing local proof retention as server TTL/deletion evidence; adding a
  provisional host, call site, customer control, or App Privacy answer in a closeout; marking
  COM-C5 Done; or using the reviewed merge as Production, distribution, or release authority.

## DEC-COM-060 — Enter C5-02 with a deletion-safe first-party receiver

- Status/date: **Accepted owner-entry and C5-02 implementation contract — 2026-08-28**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-056/057/058/059
- Context: C5-01 is reviewed and merged, but its transport is deliberately unavailable. Before any
  endpoint can become reachable, C5-02 must make retries idempotent, make late upload unable to
  resurrect deleted data, prove a real maximum server retention window, isolate environments, and
  bound anonymous abuse without introducing a customer/content identifier or persisting the
  complete-delete request's cross-generation association.
- Decision: Accept the three exact `mindbudget-telemetry[-dev|-staging].yehao1105.workers.dev`
  hosts with anonymous `POST /v1/events` and proof-authenticated `POST /v1/delete`. Use distinct
  Worker/D1/rate-limit resources per environment. Enforce exact bounded JSON and a closed event
  vocabulary; store only independent typed event rows, one handle per pseudonym, and independent
  per-generation delete tombstones. Event UUID conflicts with different facts reject atomically;
  exact retries do not duplicate. Delete validates every proof before any mutation, records no
  request/group association, is idempotent, and makes late matching uploads accepted-but-discarded.
  Expire rows and tombstones within 90 x 24 UTC hours from server acceptance using indexed bounded
  Cron deletion. Disable invocation logs; persist only sampled closed operational reason codes.
  Opt-out best-effort cancels the active upload but does not claim to revoke an already accepted
  request. Add the fixed iOS adapter and direct tests without constructing it in the app; keep the
  unavailable transport default and zero capture call sites. Deploy/probe Development only.
- Consequences: C5-02 can prove receiver schema, environment separation, TTL mechanics, deletion,
  retry, cancellation, and cost/monitoring boundaries without changing customer collection or App
  Privacy answers. C5-03 metrics and C5-04 control/disclosure remain blocked. Staging/Production
  deployment, final traffic, distribution, and release remain unauthorized. Development alone may
  own a migrated D1 and deployed Worker; an isolated Staging D1 may exist without migration or
  deployment, while the Production binding stays an invalid placeholder until a separately
  authorized resource-provisioning gate.
- Alternatives rejected: A shared database or wildcard host; arbitrary dictionaries/free text;
  storing raw deletion secrets, grouped proof requests, IP addresses, or request bodies; a static
  client API secret presented as authentication; IP rate limiting as deletion authority; deleting
  only currently present events without a late-upload tombstone; exactly-once assumptions; keeping
  data 90 days from a client-controlled timestamp; unbounded cleanup; claiming opt-out can recall a
  request already accepted at the edge; enabling capture/customer controls; or deploying Production.

## DEC-COM-061 — Remove request-unique deletion timing and ambient transport metadata

- Status/date: **Accepted C5-02 review remediation — 2026-08-28**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-057/058/060
- Context: Independent review found that one exact millisecond tombstone expiry shared by every
  proof in a complete-delete request preserved a recoverable request grouping for the tombstone
  lifetime, ambient URLSession metadata could disclose build/OS/locale outside the closed egress
  row, and a single 1,000-row hourly cleanup pass did not prove the documented 90-day maximum under
  backlog.
- Decision: Round delete-tombstone expiration down to a UTC-day bucket shared across independent
  requests accepted that day; disclose that broad expiry day while persisting no exact acceptance
  timestamp or request/group identifier. Send only fixed `User-Agent: MindBudget`, explicitly
  suppress `Accept-Language`, and reject any different/nonempty value at the receiver. Keep every
  cleanup transaction bounded to 1,000 rows per table but repeat bounded transactions during the
  same scheduled operation until no full expired batch remains. Make JSON whitespace exactly the
  RFC grammar, make Swift deletion-secret base64 explicit, and remove the redundant event-shape
  precheck. Add deterministic regressions and static anchors for every boundary.
- Consequences: The dormant transport reveals neither app version/OS nor locale in HTTP metadata;
  tombstones retain only a coarse daily TTL bucket rather than a request-unique deletion time; and
  the 90 x 24-hour maximum no longer assumes less than one batch of backlog. HTTP 404/405/421 fixed
  endpoint-policy failures remain typed failures in the unconstructed adapter; C5-04 must make
  them terminal/non-retrying before it creates any production transport. This remediation does not
  enable capture, customer controls, Staging/Production, distribution, or release.
- Alternatives rejected: Persisting exact per-request expiry for operational convenience;
  allowing URLSession's variable default user agent or language; weakening the 90-day statement to
  eventual deletion; unbounded SQL statements; or expanding the dormant C5-02 local lifecycle for
  customer-facing terminal error handling owned by C5-04.

## DEC-COM-062 — Close C5-02 on reviewed dormant-receiver evidence

- Status/date: **Accepted after reviewed PR #78 merge — 2026-08-28**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-056/057/058/059/060/061
- Context: Independent review approved exact remediation head `72abf4b`, GitHub Actions run
  `33176551566` completed successfully on that head, and PR #78 merged it to `main` as `4715054`.
  The review confirmed both P1, both P2, and two of three P3 findings were closed with targeted
  tests. The fixed-endpoint 404/405/421 terminal-failure P3 remains explicitly deferred to C5-04;
  the remaining observability and future physical confirmation observations are nonblocking and
  belong to later activation/operations work.
- Decision: Mark C5-02 Done on the reviewed source, hosted run, and merge. Preserve
  `UnavailableTelemetryTransport` as the production default with zero client construction and
  capture calls. Do not infer that the DEC-COM-061 remediation was redeployed or live-probed: the
  recorded Development version remains the earlier candidate, Staging remains undeployed, and
  Production remains unprovisioned/undeployed. C5-03 is no longer dependency-blocked but requires a
  separate explicit owner entry; C5-04 remains blocked by C5-03.
- Consequences: C5-02 closes the strict content-free receiver and dormant adapter only. Customer
  telemetry collection/egress, controls/disclosure, App Privacy changes, metrics/G1 evidence,
  terminal fixed-endpoint guidance, Production, distribution, and release remain unauthorized.
- Alternatives rejected: Treating green CI as a deployment claim; automatically entering C5-03;
  constructing the adapter before C5-04 terminal-failure and disclosure work; or marking COM-C5
  Done before C5-03/C5-04.

## DEC-COM-063 — Build C5-03 as dormant aggregate evidence, not a new data channel

- Status/date: **Accepted C5-03 implementation boundary — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; REQ-G1-001; SPEC-009/012
- Context: The owner explicitly entered C5-03 after the reviewed C5-02 closeout. Later G1 needs
  exact App Store, first-party telemetry, and voluntary survey evidence, but C5-04 still owns the
  only possible customer control/capture activation and all release/privacy operations. Current
  collection and customer telemetry egress are zero, and Apple may threshold or noise Analytics
  rows. The existing receipt vocabulary contains only stage/outcome facts and a rotating
  pseudonym generation, not a durable user/session identity.
- Decision: Add no event, client construction, capture call, host, or HTTP route. Accept a closed
  nine-metric aggregate vocabulary with exact integer numerator, denominator, and sample size;
  source-export SHA-256 provenance; explicit `available`, `zero_denominator`,
  `source_suppressed`, and `not_collected` states; and immutable canonical output. Compute
  available proportions with a two-sided 95% Wilson score interval rounded outwards to integer
  basis points. Define coverage as evidence completeness rather than population participation.
  Add a read-only D1 receipt funnel that counts only ordered completed stages in one app-version,
  half-open, at-most-90-day window and returns counts only. Its unit is a pseudonym generation,
  never a user/device. Fix a bilingual, optional, aggregate-only two-question survey workflow with
  no free text or product-data request.
- Consequences: C5-03 can make later evidence reproducible without turning evidence preparation
  into a fifth egress channel. Apple-suppressed values remain unavailable rather than inferred
  from percentages; a proven zero denominator is not displayed as 0%; and current zero collection
  remains visible as `not_collected`. The tooling does not claim App Store, survey, or production
  funnel results and cannot decide G1. C5-04, Staging/Production, App Privacy changes,
  distribution, and release remain blocked pending separate gates.
- Alternatives rejected: Adding a `/metrics` or admin endpoint; storing raw App Store reports or
  survey responses in the repository; dividing rotating telemetry pseudonyms by Apple's distinct
  opt-in population and calling it customer coverage; treating missing/suppressed data as zero;
  reverse-engineering counts from a displayed percentage; exposing pseudonyms in an evidence
  report; accepting caller-defined metric names; or enabling capture to manufacture a C5-03 sample.

## DEC-COM-064 — Never roll C5 evidence coverage across exact segments

- Status/date: **Accepted independent-review remediation — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; REQ-G1-001; DEC-COM-063
- Context: Independent review showed that the draft bundle's root coverage summed metric cells
  across Development, Staging, and Production and also allowed overlapping `ALL` and specific
  storefront segments. A 50% root result could therefore coexist with zero Production evidence,
  while completeness alone made a denominator-one metric look equivalent to a large sample.
- Decision: Remove root coverage rather than defining an environment-only partial roll-up that
  would still mix storefront or device populations. Keep completeness only inside each exact
  `environment / appVersion / storefront / deviceFamily` segment. Add
  `widestConfidenceIntervalBasisPoints` to every segment: the maximum available Wilson upper-minus-
  lower width, or `null` when no estimate exists. Keep `available` as source availability and do
  not invent a minimum denominator or G1 acceptance threshold in C5-03.
- Consequences: Development can never raise a Production coverage figure, and `ALL` cannot be
  averaged with a contained storefront. A `1 / 1` metric remains exactly represented but exposes a
  7,935-basis-point widest interval beside completeness. Any later G1 decision must cite exact
  segments and inspect counts plus intervals; C5-04 remains blocked pending reviewed C5-03 merge.
- Alternatives rejected: A single cross-environment roll-up; a Production-only root value that
  silently discards other segments; an environment-grouped roll-up that still mixes overlapping
  storefront/device populations; documenting an ambiguous global number without removing it; or
  inventing an unapproved minimum sample threshold in C5-03.

## DEC-COM-065 — Close C5-03 on reviewed dormant evidence computation

- Status/date: **Accepted after PR #81 post-merge verification of PR #80 — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; REQ-G1-001; DEC-COM-063/064
- Context: Independent review approved head `4ea7cd9` and raised one P2 cross-segment coverage
  issue plus one P3 weak-sample-visibility issue. Remediation head `0c61427` applied both, GitHub
  Actions run `33211270363` completed successfully, and PR #80 merged it to `main` as `a587f42`
  without a pre-merge rereview. PR #81's post-merge closeout review read that exact remediation
  delta and confirmed both fixes: coverage remains exact-segment-only and exposes widest Wilson
  interval width.
- Decision: Mark C5-03 Done on the pre-merge review of `4ea7cd9`, successful hosted run and merge
  of remediation `0c61427`, and PR #81's post-merge verification of that exact delta. This closes
  only the dormant read-only D1 aggregate and offline immutable evidence computation. C5-04 is no
  longer dependency-blocked but requires separate explicit owner entry before customer controls,
  capture construction, App Privacy changes, operational deployment/proof, or final-binary traffic.
- Consequences: No real App Store export, survey response, telemetry sample, evidence bundle,
  threshold pass, or G1 decision is claimed. `UnavailableTelemetryTransport` remains the app
  default with zero production construction/capture call sites and zero customer telemetry egress.
  COM-C5 remains In Progress; Staging/Production, distribution, and release remain unauthorized.
- Alternatives rejected: Treating implementation tests as collected evidence; automatically
  entering C5-04; marking COM-C5 Done before controls/disclosures/operations; or using C5-03 merge
  as authorization to deploy, capture, update App Privacy, decide G1, distribute, or release.

## DEC-COM-066 — Activate C5 telemetry only behind customer control and closed operations

- Status/date: **Accepted C5-04 implementation boundary — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-056 through DEC-COM-065
- Context: After C5-03's reviewed closeout, the owner explicitly entered C5-04. The dormant client,
  fixed adapter, Development Worker, and evidence computation already existed, but the product had
  no customer control, production construction, capture inventory, App Privacy declaration,
  terminal endpoint policy, or current-source operational proof.
- Decision: Permit exactly one `TelemetryClient` plus `FixedTelemetryTransport` construction in
  `TelemetryServiceFactory`. Keep missing state default-off and require bilingual confirmation in
  Privacy settings before creating a pseudonym or request. Limit capture to the three reviewed
  production files and the closed events in `C5_TELEMETRY_CAPTURE_AUDIT.md`; never add content,
  financial values, receipt evidence, StoreKit/CloudKit identifiers, device/locale metadata, or
  arbitrary strings. Treat fixed 404/405/421 endpoint-policy failures as durable, non-retrying
  states; upload retry requires explicit Send Retry or opt-out, while deletion retry requires
  another explicit Delete. Delete first durably disables collection, clears the unsent queue, and
  retires the active identity, then removes every authenticated retained generation before app-wide
  financial deletion can proceed. A failed delete cannot re-enable or create a new identity while
  any terminal proof state remains. Declare Product Interaction and a conservative
  rotating Device ID as unlinked, non-tracking Analytics in the privacy manifest. Use
  `C5_TELEMETRY_OPERATIONS_RUNBOOK.md` for separately authorized Development publish, rollback,
  closed monitoring, synthetic TTL/delete proof, and credentials. Telemetry has no server signing
  key; client deletion secrets remain local and must never be exported.
- Consequences: Runtime telemetry is optional and cannot affect entitlement, budgets, local use,
  or any product decision. Factory prerequisites fail to a typed unavailable telemetry service
  rather than failing app startup; its UI remains off and explains that budgeting still works.
  Disable drops unsent events and stops capture; Delete remains a distinct
  proof-authenticated action. Corrupt local state remains deletable without a false remote claim.
  App Store Connect privacy answers must be updated before distribution. C5-04 and COM-C5 remain
  In Progress until current-source Development proof, exact-head review, green hosted CI, and merge.
  Staging/Production, G1, TestFlight/App Store distribution, and release remain unauthorized.
- Alternatives rejected: Implicit or mandatory collection; a global analytics singleton with
  arbitrary properties; stable account/device/advertising identity; financial or receipt-content
  events; automatic retry of endpoint-policy failures; deleting financial data before telemetry
  deletion truthfully resolves; relying on a privacy manifest to update App Store Connect; treating
  a Development probe as Production/final-binary/G1 evidence; or deploying remotely without exact
  environment approval.

## DEC-COM-067 — Never let optional telemetry block authoritative local deletion

- Status/date: **Accepted independent-review remediation for C5-04 — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; SPEC-009/012; DEC-COM-056/057/066
- Context: Independent review found that DEC-COM-066's ordering made app-wide Delete All return
  before deleting local financial records whenever the optional telemetry endpoint was offline,
  unavailable, or in a terminal 404/405/421 state. Because Production remains undeployed, that
  could hold a customer's local records behind an unrelated first-party network for as long as a
  retained proof remained. This contradicted the local-first contract and the requirement that
  telemetry failure cannot change local product use.
- Decision: App-wide Delete All still stops capture, commits telemetry opt-out and queue removal,
  and attempts proof-authenticated remote deletion before touching local financial data. A remote
  `.failed`, `.terminalFailure`, or `.unavailable` result is not authority over the local store and
  must never stop `DataActor.deleteAllUserData()`, verification, recovery-artifact deletion, or
  preference reset. The app publishes a distinct completed-with-pending-telemetry state; any
  authenticated proof remains in the telemetry client for the separate Privacy-settings Delete
  retry. Only failures in the actual notification/search/local-store/recovery verification stages
  may make the local Delete All return false.
- Consequences: Offline and undeployed-endpoint users can always erase local financial records.
  Remote telemetry deletion is neither falsely reported as complete nor silently forgotten, and
  collection remains disabled while proofs survive. Tests cover nonterminal failure, terminal
  endpoint policy, and unavailable service with zero remaining local model counts and reset
  preferences. C5-04 remains In Progress under its existing operational/review/release gates.
- Alternatives rejected: Holding local records until an optional endpoint recovers; destroying
  proofs and claiming remote deletion; treating the whole operation as failed after local records
  were erased; or allowing a pending remote deletion to resume collection or create a new identity.

## DEC-COM-068 — Record the reviewed C5-04 product merge without closing operational evidence

- Status/date: **Accepted post-merge calibration — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-066/067
- Context: Independent review approved the deletion-order remediation on exact head `2c1cebe`
  within its declared scope. It did not inspect `PrivacyInfo.xcprivacy`, the AddExpense and Pro
  capture sites, `TelemetryService` (defined in `TelemetryClient.swift`), or the operations
  runbook. GitHub Actions run `33233846430` completed successfully on that head, and PR #82 merged
  the product capability to `main` as `28d9eae`. No current-source Development Worker deployment
  or endpoint/TTL/delete-idempotency probe has occurred.
- Decision: Record the exact implementation, scoped review, hosted CI, and product merge facts
  without expanding review coverage. PR #83's closeout review is explicitly asked to supplement
  the four excluded surfaces. Keep C5-04 and COM-C5 In Progress for that review boundary and the
  separately authorized current-source Development operational proof. This documentation-only
  calibration performs no Worker deployment, D1 mutation, endpoint probe, customer collection,
  App Store Connect change, or release action.
- Consequences: After PR #83's supplemental review, the next authorized C5 task is only the
  Development publish/monitoring/TTL and delete-idempotency evidence described by
  `C5_TELEMETRY_OPERATIONS_RUNBOOK.md`. App Store Connect
  privacy answers, final-binary traffic verification, G1, Staging/Production, distribution, and
  release remain later gates. Earlier Development evidence from Worker
  `1c162a57-8789-4f7f-9fec-f2c484e9f4f2` remains historical and cannot satisfy the current-source
  probe.
- Alternatives rejected: Marking C5-04 or COM-C5 Done from a source merge alone; describing
  excluded files as independently reviewed; treating the pre-DEC-COM-061 probe as current-source
  evidence; or inferring a remote deployment from local and hosted tests.

## DEC-COM-069 — Prove current-source telemetry only in Development

- Status/date: **Accepted Development operational evidence candidate — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-061/066/067/068
- Context: PR #83 supplemental review covered the privacy manifest, capture sites,
  `TelemetryService`, and operations runbook on exact head `e6bbd3f`; GitHub Actions run
  `33242024609` passed and PR #83 merged as `becb020`. The owner then explicitly authorized only
  the current-source Development Worker/D1 publish and synthetic operational proof. The previous
  live evidence remained tied to pre-remediation version `1c162a57-8789-4f7f-9fec-f2c484e9f4f2`.
- Decision: Bind the operation to Cloudflare account `3f5394e0ef5a531c63c0ceaa74262e0d`, Worker
  `mindbudget-telemetry-dev`, and D1 `mindbudget-telemetry-development`
  (`2faff8ac-de17-4fd0-aaa7-546bd1902e74`). After local generated-types/typecheck, 35 Worker tests,
  eight evidence tests, three dry-runs, and three startup checks passed with Wrangler 4.127.0,
  publish exact source `becb020` as version `003c66fa-a57c-4b6a-a8d7-3f75b14cc716`. Use one
  disposable synthetic identity/event/secret only; record status/body-size and aggregate counts,
  never its request or secret; remove only its exact tombstone after proof.
- Consequences: The synthetic sequence returned 202/202/409/204/202/204 with empty bodies, proved
  an exact `7776000000`-millisecond event TTL, an earlier-or-equal UTC-day tombstone, idempotency,
  and no late-upload resurrection. Exact cleanup returned synthetic counts to 0; whole-D1 final
  counts were 0 events, 0 identities, and the same 2 historical pre-remediation tombstones. No
  rollback was needed. C5-04 and COM-C5 remain In Progress pending independent review, hosted CI,
  and merge of this evidence. No customer participation, G1, App Store Connect update,
  Staging/Production action, final-binary traffic, distribution, or release is inferred.
- Alternatives rejected: Reusing the historical probe as current evidence; logging request bytes
  or the deletion secret; retaining a new synthetic tombstone; touching Staging/Production;
  treating Development proof as G1/final-binary/release evidence; or marking the phase Done before
  exact-head review, CI, and merge.

## DEC-COM-070 — Correct PR #83 provenance and prove the real iOS transport boundary

- Status/date: **Accepted PR #84 review remediation candidate — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-066/067/068/069
- Context: Independent review of PR #83 covered head `daea2d2`, raised two P2 findings and one P3,
  and explicitly excluded `PrivacyInfo.xcprivacy`, the AddExpense/Pro capture files,
  `TelemetryService`, and the operations runbook. Remediation head `e6bbd3f` applied those findings
  and recorded the implementation author's supplemental inspection of the four excluded surfaces;
  GitHub Actions run `33242024609` passed and PR #83 merged it as `becb020` without a pre-merge
  rereview. Separately, DEC-COM-069's manual HTTP transcript did not prove that the actual iOS
  `URLSession` preserved the Worker's strict `User-Agent` and absent/empty `Accept-Language`
  contract. The documented claim that explicit deletion remains callable after
  `TelemetryService.stop()` also lacked an executable regression.
- Decision: Preserve the historical DEC-COM-069 entry but treat its "supplemental review" wording
  as an author-side inspection record, not an independent-review claim. Add a default-disabled,
  non-archiving `MindBudget-Telemetry-Live` scheme that alone enables one opt-in test using the
  actual Development `FixedTelemetryTransport`, production `BoundedTelemetryHTTPLoader`, and
  `URLSession`. Keep the default scheme free of that environment variable. Add a deterministic
  service test that calls `stop()` before explicit deletion and proves the same service still
  deletes remotely and clears local encrypted state.
- Consequences: The corrected live suite-level run on the iOS 26.5 simulator received HTTP 202
  (`.accepted`) for upload and HTTP 204 for authenticated delete from the strict Development
  Worker. A read-only aggregate query then found 0 events, 0 identities, and 3 tombstones: the 2
  historical pre-remediation rows plus the expected UTC-day tombstone from this live transport
  deletion. No event or identity row remained. The earlier exact-method-filter invocation that
  discovered zero tests is a non-pass and not evidence. This is Debug simulator evidence only;
  final-binary traffic, App Store Connect, G1, Staging/Production, distribution, and release remain
  open, and C5-04/COM-C5 remain In Progress pending review, hosted CI, and merge.
- Alternatives rejected: Continuing to call `e6bbd3f` independently reviewed; treating a manual
  HTTP client as evidence of native URLSession headers; enabling the live test in the default
  scheme; allowing the probe scheme to archive; dumping D1 rows or identifiers; relabeling the
  expected deletion tombstone as a cleanup failure; or treating Debug simulator traffic as a
  final-binary/release gate.

## DEC-COM-071 — Close C5-04 and COM-C5 on reviewed Development evidence

- Status/date: **Accepted C5-04/COM-C5 closeout — 2026-08-29**
- Requirements: REQ-R1-TELEMETRY-001; REQ-R1-NET-001; DEC-COM-056 through DEC-COM-070
- Context: Independent review approved exact PR #84 head `84a96bc` after confirming both P2
  findings and the P3 regression were closed. GitHub Actions run `33247176815` completed
  successfully on that exact head, and PR #84 merged it as `4194b73`. The reviewed evidence
  includes the actual Development `FixedTelemetryTransport`/`URLSession` 202/204 path, the
  deterministic post-`stop()` deletion retry, the default-disabled/non-archiving probe scheme,
  and the disclosed aggregate state of 0 events, 0 identities, and 3 tombstones (2 historical plus
  the expected live-probe tombstone).
- Decision: Mark C5-04 and COM-C5 Done on the recorded source, Development evidence, independent
  review, hosted CI, and merge. Keep REQ-R1-TELEMETRY-001 Active for COM-C6/C12 final-binary,
  App Store Connect, environment, distribution, and release verification. Before any App Store
  Connect privacy answer is copied or accepted, require COM-C6 independent inspection of
  `MindBudget/Resources/PrivacyInfo.xcprivacy`, both telemetry capture sites, the
  `TelemetryService` wiring in `MindBudget/Services/TelemetryClient.swift`, and
  `Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md`; the implementation-author
  supplemental inspection does not satisfy that gate. Do not enter COM-C6 without a separate
  explicit owner instruction.
- Consequences: Development version `003c66fa-a57c-4b6a-a8d7-3f75b14cc716` remains the only
  deployed telemetry environment. Staging remains unmigrated/undeployed and Production remains
  unprovisioned/undeployed. No real customer evidence bundle, G1 decision, App Store Connect
  update, final-binary traffic, distribution, or release authority follows from this closeout.
- Alternatives rejected: Leaving C5-04 or COM-C5 In Progress after their exact exit evidence
  merged; auto-entering COM-C6; treating Debug simulator traffic as final-binary evidence;
  relabeling the expected tombstone as a leak or removing it outside ordinary expiry; deciding G1
  from synthetic traffic; or authorizing Staging/Production, distribution, or release.

## DEC-COM-072 — Enter COM-C6 through a closed non-mutating C6-01 matrix

- Status/date: **Accepted C6-01 implementation decision — 2026-08-29**
- Requirements: REQ-ENTITLEMENT-001; REQ-STOREKIT-STATE-001;
  REQ-STOREKIT-LIFECYCLE-001; REQ-R1-NET-001; REQ-R1-TELEMETRY-001; REQ-MONEY-001;
  REQ-MONEY-MIGRATION-001; REQ-ICLOUD-001; REQ-RECEIPT-PIPELINE-001;
  REQ-RECEIPT-PRIVACY-001
- Context: The owner explicitly entered COM-C6 after PR #85 merged the C5 closeout/privacy-source
  handoff as `008b674`. The pre-existing C6 task named many product domains but did not provide a
  machine-readable inventory proving that every row remained attached to concrete tests and
  static gates. It also lacked one direct cross-domain regression for the product promise that
  optional app-owned network failure cannot revoke a separately verified local Pro entitlement.
- Decision: Implement only C6-01. Freeze seven rows in strict `C6_RELEASE_MATRIX.json`; validate
  exact keys, order, sources, test types/methods, static checks, local Worker commands, and five
  blocked remote actions with fail-closed negative self-tests. Run every reviewed static gate,
  both Worker `check` scripts, Release simulator build, and 16 Swift test containers serially.
  Add the offline public-configuration/unavailable-telemetry local-Pro regression. Keep
  `remoteMutationAllowed` false and forbid archive, upload, Staging/Production deployment, and App
  Store Connect writes.
- Consequences: C6-01 is implemented pending independent review, hosted CI, and merge. The local
  matrix passed 285 tests in 16 suites, with the existing opt-in live telemetry probe skipped by
  design; both Worker suites and dry-runs passed. C6-02 and C6-03 remain blocked. The five-source
  privacy inspection preserved by PR #85 remains an independent C6-02 responsibility; this
  automation does not satisfy it. No physical waiver becomes a pass, no Active Requirement is
  marked complete, and no G1, TestFlight, App Store Connect, distribution, or release claim
  follows.
- Alternatives rejected: Running the entire repository without a closed row inventory; treating
  a dry-run as deployment; folding signed-device/manual review into automation; entering C6-02
  before C6-01 review/CI/merge; archiving or uploading during C6-01; or letting optional network
  state become entitlement authority.

## DEC-COM-073 — Make C6 row evidence depend on passed xcresult cases

- Status/date: **Accepted C6-01 review remediation — 2026-08-29**
- Requirements: DEC-COM-072; all Requirements named by `C6_RELEASE_MATRIX.json`
- Context: Independent review of PR #86 found that `requiredMethods` was only a source-text
  preflight while the runner filtered at test-type granularity and never proved the named methods
  executed. A disabled/skipped method, a comment, a method in another type, or a non-test function
  could therefore leave the matrix green. Review also identified that the manually maintained
  static-check allow-list would not notice a future repository check script.
- Decision: After `test-without-building`, parse the exact new xcresult with `xcresulttool` schema
  0.4.0. Require every type/method binding to occur exactly once as a `Test Case` whose result is
  `Passed`; missing, skipped, failed, or duplicate evidence fails closed. Retain type-level test
  filters so the matrix continues to execute the full owning suites. Discover every
  `Scripts/check-*.sh` and `Scripts/check_*.py` file and require it to be either a row-driven matrix
  check or one of two exact special roles: matrix bootstrap or full-suite coverage consumer.
- Consequences: `requiredMethods` is now runtime evidence rather than documentation metadata.
  Negative self-tests cover unclassified scripts plus skipped, missing, and duplicate required
  cases. The retained earlier bundle independently exercised 33 matrix bindings, including the
  parameterized local-Delete-All regression. The subsequent remediated matrix passed 285 tests in
  16 suites and proved all 33 bindings exactly once as Passed. Full validation then passed the
  strict Dashboard benchmark, 553 unit tests in 32 suites, 17/17 UI tests, and every selected
  coverage threshold with zero failures; rereview, hosted CI, and merge remain required.
  C6-02/C6-03 stay blocked.
- Alternatives rejected: Merely changing filters to individual methods without checking results;
  accepting skipped methods because the owning suite passed; trusting comment-sensitive source
  regexes as execution evidence; treating every `check-*` script as an interchangeable no-argument
  static gate; recursively adding the C6 bootstrap to itself; or running selected-suite coverage as
  if it were the full-suite coverage gate.

## DEC-COM-074 — Close C6-01 and preserve explicit C6-02 entry

- Status/date: **Accepted C6-01 reviewed closeout — 2026-08-29**
- Requirements: DEC-COM-072/073; all Requirements named by `C6_RELEASE_MATRIX.json`
- Context: Independent rereview approved exact PR #86 remediation head `f77d2a6` after confirming
  that required methods are runtime evidence and repository check discovery is closed in both
  directions. GitHub Actions run `33255898196` completed successfully on that exact head, and PR
  #86 merged it as `015d00e`.
- Decision: Mark only C6-01 Done. Require a separate explicit owner instruction before entering
  C6-02, and keep C6-03 blocked by accepted C6-02 evidence plus separate archive/upload authority.
  Preserve the five-source independent privacy inspection as mandatory C6-02 work; C6-01
  automation does not satisfy it.
- Consequences: The reviewed seven-row matrix, 33 exact Passed bindings, static/Worker/local build
  execution, local full validation, hosted CI, and merge are closed C6-01 evidence. No Active
  Requirement is marked complete. The checked-in privacy manifest, two capture sites,
  `TelemetryService`, and operations runbook remain independently unreviewed for C6 purposes.
  Signed-device purchase/restore/manage/legal evidence, final-binary/IPA traffic and key/content
  scans, App Store Connect, Staging/Production, G1, archive/upload, distribution, and release remain
  open and unauthorized.
- Alternatives rejected: Auto-entering C6-02 after merge; treating automation as the independent
  privacy-source review; carrying C6-01 as In Progress after its exact review/CI/merge chain closed;
  archiving or uploading from a documentation closeout; or relabeling any owner-waived physical
  observation as a pass.

## DEC-COM-075 — Bind C6 authorization to exact phase sections

- Status/date: **Accepted C6-01 closeout review remediation — 2026-08-29**
- Requirements: DEC-COM-074; COM-C6 phase authorization boundary
- Context: Author-side supplemental inspection of initial closeout head `4545e88` demonstrated
  two reproducible bypasses in the closeout gate. A summary occurrence of `C6-01 is Done` could
  keep the gate green after the formal C6-01 Status regressed, while a C6-02 heading followed on
  the next line by `Status: **In Progress.**` escaped a regex that required the identifier and
  state on one line. The same structural risk applied to C6-03.
- Decision: Extend `commercialization_phase_states.py` with section expectations. In the
  authoritative `COMMERCIALIZATION_TASKS.md`, require exactly one C6-01 heading with one Done
  Status and one `[x]` task, one C6-02 heading with one Blocked Status and one `[B]` task, and one
  C6-03 heading with one Blocked Status and one `[B]` task. Validate only the Status and task item
  owned by each section. Add negative self-tests for all three state changes and all three task
  marker changes.
- Consequences: Unrelated summaries and line layout cannot grant phase authority. Changing any
  C6 subphase state or task marker without the accepted owner transition fails the ordinary
  commercialization gate. C6-01 remains Done; C6-02 still requires a separate explicit owner
  entry; C6-03 remains blocked by C6-02 acceptance and separate archive/upload authority.
- Alternatives rejected: Adding more repository-wide positive strings; keeping the line-oriented
  C6-02/C6-03 regex as the authorization control; trusting headings without task markers; or
  entering C6-02 as part of this review remediation.
