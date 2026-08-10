# Commercialization Project Memory

## Authority and current phase

This file is the durable product/engineering memory for the commercialization track only. The
main product baseline remains in `Docs/PROJECT_MEMORY.md`. Accepted decisions in
`Docs/Commercialization/DECISIONS.md` take precedence over this summary.

- Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`.
- Source SHA-256: `290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`.
- COM-C0A and COM-C0B are Done. COM-C1 is Ready but has not started.
- Product implementation has not started. No StoreKit product/group, entitlement, paywall,
  CloudKit container, telemetry receiver, backend, Watch target, receipt pipeline, or third-party
  model provider exists.
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

All app-owned HTTP(S) egress is deny-by-default. The current Release allow-list is empty. Future
entries must be accepted in `NETWORK_EGRESS_POLICY.md` before implementation.

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

- SPEC-015 remains open until the receipt phase scopes non-money Vision floating point safely.
- SPEC-018 is resolved: current deletion documentation tracks all current model types without a
  fragile numeric claim.
- CloudKit architecture, app-owned domains, provider contracts/prices, App Attest design, trial,
  quotas, and storefront pricing remain `UNVERIFIED`/`TBD`.
- Signed-device file protection and future channel deletion require later manual evidence.

## Next phase boundary

COM-C0B created/updated documents, build scripts, and non-behavioral test infrastructure only; its
full baseline passed. COM-C1 may start only on explicit owner instruction and must follow the
independent packets in `COM_C1_EXECUTION_PACKET.md`. It stops at pure entitlement/access
infrastructure and must not import StoreKit, create StoreKit products, add a paywall, or work ahead.
