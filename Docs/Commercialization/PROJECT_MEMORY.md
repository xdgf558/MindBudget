# Commercialization Project Memory

## Authority and current phase

This file is the durable product/engineering memory for the commercialization track only. The
main product baseline remains in `Docs/PROJECT_MEMORY.md`. Accepted decisions in
`Docs/Commercialization/DECISIONS.md` take precedence over this summary.

- Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`.
- Source SHA-256: `290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`.
- This fingerprint identifies the external input audited by COM-C0A; CI verifies the frozen
  repository snapshot, not changes to the unavailable owner-held file. See `SOURCE_PROVENANCE.md`.
- COM-C0A, COM-C0B, and COM-C1 are Done. PR #27 completed independent C1-03 review and merged the
  three-packet entitlement/access boundary on 2026-08-11. COM-C2 is Done; C2-01 and C2-02
  are Done. PR #29 passed independent review and green CI, then merged as `a45d480` on
  2026-08-12. C2-03 then passed independent review and green CI and merged through PR #30 as
  `3fc72b4` on 2026-08-13; it is Done. C2-04 then passed independent review and green CI and
  merged through PR #31 as `a293762` on 2026-08-13, closing COM-C2. COM-C3 C3-01 passed
  independent review and green CI and merged through PR #33 as `747b628` on 2026-08-14 under the
  provisional test terms accepted in DEC-COM-019. C3-02 trial-lifecycle implementation is
  complete pending independent review, hosted green CI, and merge; C3-03 and C3-04 remain blocked.
- C1-01 adds a pure entitlement value, a closed feature vocabulary, and a versioned representation
  migration boundary. C1-02 adds one immutable `FeatureAccessService` snapshot, protocol-based
  environment/session injection with exact Free as the production default, and a nonpersistent
  `#if DEBUG` provider. C1-03 routes only the accepted existing Apple on-device AI, non-24-hour
  cooling-off, and advanced Siri entries through one Commerce-owned decision snapshot. Exact Free
  continues to receive deterministic AI templates, the basic 24-hour period, and basic Siri
  expense-recording and budget-check actions. The existing 30-day Insights experience and
  five-item wishlist remain Free. Passive App Entity providers return no results under exact Free
  rather than presenting a system-initiated error. The uploaded 0.9.6 binary remains unchanged;
  this unreleased source is not a distribution candidate until verified purchase/restore,
  purchase presentation, and their owning release gates are complete. C2-01 adds one committed
  Xcode StoreKit Configuration fixture containing only the accepted Monthly/Annual technical
  catalog. It is copied only to the unit-test bundle, enabled only by a dedicated non-Archive
  local scheme, and absent from the app target/default scheme. The fixture defaults to
  CHN/`zh_CN` and pins synthetic test prices plus explicit bilingual “not a customer offer” copy;
  this does not accept a launch storefront or price. The catalog/project/scheme contract is an
  importable Python module with standard `unittest` fixtures behind a thin Shell/CI entry. C2-02
  adds the app-owned typed StoreKit catalog, environment/storefront-keyed presentation-only cache,
  an actor-isolated current-entitlement authority, exactly one lifecycle-owned
  `Transaction.updates` task, launch reconciliation, and a process-local synchronized bridge to
  existing feature consumers. Unknown products/environments, mixed environments, and unverified
  input fail closed; Delete All clears the presentation cache, which can never grant a right.
  C2-02 retained verified ownership, revocation, and expiration as raw facts without deciding
  billing grace from expiration alone. Merged C2-03 makes the single `EntitlementStore`
  the lifecycle authority for full verified subscription-state mapping, explicit typed purchase/
  restore seams, whole-snapshot publication, unfinished-transaction retry, and transaction finish.
  Its one lifecycle task supervises both `Transaction.updates` and
  `Product.SubscriptionInfo.Status.updates`. A status signal triggers a fresh full reconciliation
  through the same actor; it is never an independent access decision or a second authority/UI.
  Subscribed and verified grace grant Pro; billing retry, expired, revoked, unknown, unverified,
  and pending state grant no new right. Every handled verified transaction is reconciled and its
  authoritative access snapshot is published before `Transaction.finish()`; failed finish remains
  unfinished for a later lifecycle retry. The C2-03 entry condition required both opt-in CHN/USA
  runtime catalog probes to execute
  rather than skip and pass under a supported final Xcode/runtime surface. Historical Xcode 26.6
  RC `17F109`/iOS 26.5 CLI
  evidence remains a StoreKit synchronization `Code=3`/empty-catalog failure, not a pass. A
  post-merge recheck with final Xcode 26.6 `17F113` executed both probes on final iOS 26.4 and
  iOS 26.5 runtimes, but again returned `SKInternalErrorDomain Code=3` and empty products. On
  2026-08-13, the dedicated scheme ran on the physical `拉沙的iPhone` (`iPhone Air`) with final
  iOS 26.6.1 `23G82`: 5 passed, 0 failed, 0 skipped, and both CHN/USA runtime probes passed. That
  accepted evidence opened C2-03 only and remains separate from purchase/restore evidence. The
  merged implementation exposes purchase and restore as typed programmatic seams. C3-01 adds the
  first voluntary customer presentation on top of those seams: Settings and explicit Pro-value
  triggers may open a bilingual screen with StoreKit-provided prices, fresh trial eligibility,
  explicit purchase/restore, and Apple subscription management. The exact P1W promotion remains
  local fixture evidence only; production validates the stable subscription structure and treats
  an actual introductory offer as optional StoreKit presentation data. The presentation retains
  the offer's localized price and full payment mode, but C3-01 purchases only an eligible free
  trial; eligible paid or unknown modes pause at both View and adapter without affecting existing
  rights. An unavailable entitlement
  snapshot pauses purchase in both the View and actor and exposes explicit recheck, while renewal
  disclosure follows the app-selected locale. Final Xcode 26.6 `17F113` on the
  physical iPhone Air with final iOS 26.6.1 `23G82` executed all 9 dedicated catalog/lifecycle
  tests without a failure or skip, including HKG/USA/SGP/TWN and both Monthly/Annual transaction
  flows. PR #33 then passed independent review and green CI and merged as `747b628`. C3-02 now
  derives a process-local active-trial projection only when the verified current transaction is an
  introductory free-trial transaction and verified renewal information supplies the actual
  `renewalDate` and `willAutoRenew`. The projection keeps the current trial product separate from
  the accepted next-renewal `autoRenewPreference`, so a scheduled plan switch selects the correct
  live StoreKit price and changes the lifecycle even when its date is unchanged. A stable generic local reminder is reconciled five user-
  calendar days before a reliable future date; disabled/denied notifications or a passed reminder
  window use an in-app card without requesting permission. Cancellation, end of trial, revocation,
  product/date changes, and missing authority remove or replace the request. The notification has
  no price, date, amount, product, or remaining-day content, and says the trial ends soon instead
  of promising that auto-renew remains enabled after the app stops. Formal App Store Connect products,
  final price/trial economics, C3-03, C3-04, and distribution remain blocked by their owning
  packets and release gates. C2-04's completed environment proof does not waive them.
  Final Xcode 26.6 `17F113` on the physical iPhone Air with final iOS 26.6.1 `23G82` passed the
  C3-02 dedicated suite 9/9 with no failure or skip, including all four storefronts and both
  Monthly/Annual transaction-to-trial-lifecycle derivation paths.
  The historical simulator diagnostics reported an Octane entitlement/development-install
  handshake failure. The same
  16 tests in 2 suites pass on an iOS 27 beta runtime only as diagnostic evidence and do not
  satisfy the supported-final-runtime gate. Final Xcode's iOS SDK is build `23F81a`, the installed
  iOS 26.5 runtime is `23F77`, and Apple's offered export was the older `23F73`; it was not
  imported and could not replace the installed runtime. Direct queries for build `23F81` and iOS
  `26.5.1` returned unavailable. Those historical simulator and download-query results are not
  claimed as the accepted runtime-probe pass; the supported final physical-device result above is.
  The voluntary C3-01 purchase/restore presentation exists only in this unreleased source. No
  formal App Store Connect product/group, CloudKit container, telemetry receiver, backend, Watch
  target, receipt pipeline, or third-party model provider exists.
- The public iPhone launch remains paused through COM-C12. Watch distribution is a separate
  post-iPhone-1.0 milestone and does not block iPhone 1.0.

## Commercial model

- Formal launch products: Pro Monthly and Pro Annual only.
- Subscription group internal reference: `MindBudget Pro`.
- Monthly Product ID: `com.xdgf558.mindbudget.pro.monthly`.
- Annual Product ID: `com.xdgf558.mindbudget.pro.annual`.
- Monthly/Annual price, trial, included cloud calls, reset boundary, launch storefronts, and
  provider set are `TBD` until their accepted evidence gates.
- Local Lifetime is deferred: zero product, zero entitlement, zero UI entry, zero sale, and zero
  public promise.
- TestFlight, StoreKit Configuration, Sandbox, development overrides, and promotional tests never
  create production grandfathered rights. Production rights come only from verified Production
  StoreKit state.

## Entitlement shape

- Free remains a complete usable budgeting product, including manual records, export, Delete All,
  and the approved opt-in iCloud feature.
- The current Release domain can construct only exact Free or the single Pro-subscription right.
  Local Lifetime, Connect, and unknown future bits have no constructor; unknown or unsupported
  stored representations fail closed to exact Free through the versioned migrator.
- `EntitlementSet` is the future single source of truth. Feature code must consume a central
  `FeatureAccessService`, never Product IDs or ad-hoc booleans in views.
- R1 subscription state grants rights only for verified `subscribed` and `inGracePeriod` states.
  Billing retry, expired, revoked, unverified, pending, and cached presentation state do not grant
  permanent rights.
- Removing a subscription must produce the exact Free set. Deferred future bits remain
  unreachable until a later Accepted decision.

## Price and economics gates

Commercial evidence is deliberately split so StoreKit testing does not depend circularly on final
cloud economics:

1. COM-C2/3 may use configuration-only products and provisional test terms.
2. Formal App Store Connect products and COM-C6 require accepted preliminary unit economics.
3. G1 accepts final provider, quota, reset, cost, and price inputs before COM-C7/cloud work.

The app never hardcodes a customer price. Visible prices and subscription terms come from StoreKit
or current SDK renewal information. `REGIONAL_PRICING.md` is the owner acceptance surface.

## Data, money, and migration baseline

- The current V4 store has 15 SwiftData model types and a V1 → V2 → V3 → V4 lightweight plan.
- Every stored/calculated amount is `Int64` minor units plus ISO currency. The existing App Intents
  transport adapter is the only current documented `Double` boundary.
- COM-C4A begins with a delta audit. It must not invent a destructive money migration where the
  existing exact representation already satisfies the Requirement.
- Any future migration needs a recoverable backup, explicit migration identifier, idempotent
  restart, anomaly report, and fail-closed rollback. An unconvertible value never becomes zero.
- Receipt images, OCR intermediates, raw notes, and transaction rows never enter cloud model,
  telemetry, or log channels.

## Approved future data channels

The current 0.9.x behavior and historical local-only claims remain unchanged. A later channel is
permitted only when its named phase completes authorization, disclosure, deletion, and release
gates:

- Apple-managed StoreKit lifecycle and current-entitlement verification.
- Explicit opt-in Free iCloud synchronization; local use remains authoritative and usable when
  sync fails.
- Signed public configuration with conservative offline fallback.
- Optional first-party, allow-listed, content-free telemetry with rotation, TTL, opt-out and
  deletion.
- Explicitly consented cloud AI after G1, current-entitlement verification, server quota, dual
  redaction, provider-set disclosure, and deterministic local fallback.

All app-owned HTTP(S) egress is deny-by-default. The current Release allow-list is empty and
`Scripts/check-network-egress.sh` rejects app-target network primitives, quoted HTTP(S) literals,
and app Release configuration that declares ATS exceptions, networking entitlements, associated
domains, or endpoint values. Future entries must be accepted in `NETWORK_EGRESS_POLICY.md` before
an exact centralized adapter exception is implemented.

## AI and provider boundary

- Deterministic Swift owns all money, budget, pattern, risk, entitlement, quota, and action facts.
- Template fallback remains complete on every path.
- On-device Foundation Models stays optional, gated, redacted, validated, and language-aware.
- Cloud Coach is not tied to one provider. A domestic provider may be primary or backup only after
  the same quality, privacy, regional, contractual, latency, and cost gates.
- User consent covers an explicit provider set, purpose, field set, and policy version. A provider
  outside that set is never used as silent failover; material provider/policy changes require
  renewed consent.
- No raw ledger, note, receipt image/OCR, identifier, or unbounded free text is an approved cloud
  input. Exact schemas will be frozen only in their later phase.

## iCloud boundary

- iCloud is a Free feature, never a premium entitlement.
- It is explicit opt-in and cannot block local use.
- Stable IDs, tombstones, conflict rules, account/quota/offline behavior, container environments,
  and local/cloud deletion must be accepted before COM-C4B implementation.
- Receipt images and local intermediate files are excluded.
- The sync architecture is still `UNVERIFIED`; COM-C0B records the decision criteria but does not
  create a container.

## Receipt and local Pro boundary

- Receipt import is not implemented. COM-C4C owns the five-stage acquisition → OCR → structured
  extraction → deterministic validation → user confirmation pipeline.
- Core total/date/merchant fields are release-gated; line items remain experimental/default-off.
- Nothing persists before user confirmation. OCR failure returns missing/uncertain fields, never
  an invented zero.
- Vision geometry/confidence may require narrowly reviewed non-money floating point; the exact
  amount path remains under the money gate (SPEC-015).

## Apple Watch boundary

- COM-C6.5 may be developed in parallel after its prerequisites but does not block G1, COM-C7,
  COM-C12, or iPhone 1.0.
- Watch distribution occurs only in a separate post-iPhone-1.0 release after its own gates.
- iPhone is authoritative. Watch has no CloudKit, cloud AI, OCR, free note, account, purchase,
  restore, or subscription-management UI.
- A durable outbox, stable command IDs, iPhone-side persisted dedupe, acknowledgement, tombstones,
  stale-generation rejection, and bounded offline recovery are mandatory.
- Watch reuses the same Product ID allow-list, status mapping, exact money, and entitlement-set
  semantics. Watch failure cannot impair the iPhone app.

## Privacy and deletion

- Existing PrivacyInfo declares no tracking or collected data; keep it accurate for the shipped
  binary rather than predeclaring future channels.
- Each future channel needs current bilingual disclosure and App Privacy review before release.
- Delete All must remain confirmed, ordered, observable, and fail-closed. Every current/persisted
  table and every later cloud/telemetry artifact must be independently deleted or explicitly
  disclosed when platform retention cannot be controlled.
- No content-bearing logs, prompts, responses, notes, ledger rows, receipt text, or merchant names
  enter telemetry/admin logs.

## Backend boundary

- A future Cloudflare service must be a new independent project/environment with separate data,
  secrets, admin authorization, bindings, deployment state, quotas, logs, and deletion keys.
- It may reuse sound engineering patterns from another owner project, never its data or security
  identity.
- Provider IDs, model IDs, app/bundle/environment/Product IDs, endpoints, fields, limits, and
  admin actions are allow-listed. Unknown values fail closed.
- No account/ledger database is part of R1. Current entitlement is checked from current App Store
  server state rather than treating historical JWS as permanent proof.

## Current technical debt and unknowns

- SPEC-015 is accepted as a prospective tooling boundary; COM-C4C must scope non-money Vision
  floating point narrowly before receipt code is added.
- SPEC-018 is resolved: current deletion documentation tracks all current model types without a
  fragile numeric claim.
- CloudKit architecture, app-owned domains, provider contracts/prices, App Attest design, final
  trial economics, quotas, and storefront pricing remain `UNVERIFIED`/`TBD`.
- Signed-device file protection and future channel deletion require later manual evidence.

## Next phase boundary

COM-C1 and C2-01 through C2-04 are closed. PR #31 passed independent review and green CI and
merged C2-04 as `a293762`, completing COM-C2. C3-01 passed independent review and green CI and
merged through PR #33 as `747b628` under DEC-COM-019 and its provisional test terms. C3-02 is
implementation complete pending independent review, hosted green CI, and merge. Merged C2-03 keeps one
`EntitlementStore` authority, performs full verified status
mapping, uses one lifecycle task for transaction and subscription-status update sequences, makes
each status signal trigger a fresh full reconciliation, exposes explicit typed purchase/restore
seams, publishes authoritative access before finish, and retries transactions that remain
unfinished. Access decisions still may not read raw
entitlement bits; exact Free checks use `isFree`, never `isSuperset(of: .free)`. The accepted
physical-device CHN/USA catalog run remains entry evidence rather than proof of the new lifecycle
paths.

The merged C3-01 review remediation keeps the exact 7-day offer in the isolated Configuration/runtime
contract instead of production authority, blocks purchase whenever entitlement authority is
unavailable at both UI and actor boundaries, and binds renewal copy to the app-selected locale.
C3-02 may implement only the verified active-trial projection, actual-date reminder reconciliation,
and in-app fallback in `COM_C3_EXECUTION_PACKET.md`. It must not use the P1W fixture as lifecycle
authority, prompt for notification consent, persist a right, or add C3-03 configuration.

Next suggested task: independently review C3-02, obtain hosted green CI, and merge only. Keep signed public
configuration, final customer terms/products, versioning, Archive/upload, tester assignment, and
distribution blocked until their owning C3 and release gates pass.
