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
