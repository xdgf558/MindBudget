# Commercialization and Pro Development Tasks

## Purpose

This is the execution map for the separate MindBudget commercialization track. It does not
replace the completed product phases in `Docs/TASKS.md`, and it does not grant permission to work
ahead of the active COM phase.

Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`

Source SHA-256:
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`

This is the frozen COM-C0A audit fingerprint, not automatic monitoring of the owner-held external
file. Its provenance, byte length, repository derivatives, and change procedure are recorded in
`Docs/Commercialization/SOURCE_PROVENANCE.md`.

This file began as a planning scaffold before COM-C0A. The audit and owner decision gate are now
complete and their evidence lives under `Docs/Commercialization/`. COM-C0B promoted only the
owner's accepted result into authoritative commercialization memory, decisions, matrices, and
detailed phase checklists; it added no paid product behavior.

## Current state

- Active review packet: **COM-C1 / C1-03 — existing-entry integration and audit**.
- Product implementation status: all three COM-C1 packets are implemented for review. Existing
  Apple on-device AI, non-24-hour cooling-off choices, and advanced Siri entries consume one
  Commerce-owned access snapshot; exact Free retains deterministic templates, the basic 24-hour
  period, and basic Siri record/check actions. StoreKit, paywall, receipt import, iCloud sync,
  commercialization telemetry, Watch, cloud AI, and backend remain unstarted.
- Distribution hold: keep the uploaded 0.9.6 binary unchanged. C1-03 and later source is not a
  TestFlight/App Store candidate until verified purchase/restore, purchase presentation, and the
  owning release gates are complete; exact-Free gating must not reach users before there is an
  approved way to obtain or restore the corresponding right.
- Public launch: **paused** until the commercialization track reaches COM-C12 and all release
  gates pass.
- Existing TestFlight users receive no production Pro entitlement. Production rights will be
  derived from verified production transactions only.
- Products: Pro Monthly (`com.xdgf558.mindbudget.pro.monthly`) and Pro Annual
  (`com.xdgf558.mindbudget.pro.annual`) in the `MindBudget Pro` subscription group. Price, trial,
  included cloud calls, reset policy, and storefront availability remain TBD until accepted cost
  analysis. Local Lifetime is deferred and must have no product, entry point, or promise.
- Backend: a new, independent hardened service may follow the engineering pattern of the owner's
  other Cloudflare service, but it must not reuse its data, secrets, admin authorization, or
  deployment state.

## Status legend

- `[ ]` Ready or pending in the active phase.
- `[B]` Blocked by an earlier phase, decision gate, owner input, or verification.
- `[~]` Optional/parallel work that is not on the immediate critical path.
- `[x]` Completed and recorded with tests and a session pointer.

## Dependency map

```text
COM-C0A -> COM-C0B -> COM-C1 -> COM-C2 -> COM-C3
                                      |
                                      v
                         COM-C4A -> COM-C4B -> COM-C4C
                                                   |
                                                   v
                                           COM-C5 -> COM-C6
                                                        |\
                                                        | +-> COM-C6.5 (Watch, parallel)
                                                        v
                                              G1 decision gate
                                                        |
                                                        v
                                      COM-C7 -> C8 -> C9 -> C10 -> C11
                                                        |             |
                                                        +-------------+
                                                                      v
                                                                  COM-C12
                                                                      |
                                                                      v
                                                              formal 1.0 launch
```

Accepted SPEC-013 makes COM-C6.5 a parallel development branch after its prerequisites. It does not
block G1, COM-C7, COM-C12, or the formal iPhone 1.0 launch. Watch distribution is a separate
post-iPhone-1.0 release and remains blocked by its own release gates.

## Review and execution rules

1. Work on one COM phase at a time. COM-C6.5 and the post-G1 cloud path are the only documented
   parallel exception.
2. Each review unit below should normally be one focused draft PR. Split it further when the diff
   mixes schema, security boundary, UI, and deployment changes.
3. Every phase starts from merged `main`, records its input gate, and stops at its exit gate.
4. Product IDs are accepted, but no formal StoreKit product is created until the preliminary
   cost-dependent commercial inputs are Accepted. StoreKit Configuration products may be used
   first.
5. No external model, telemetry receiver, CloudKit container, Watch target, or production backend
   is created in an earlier phase.
6. `Int64` minor-unit money, deterministic finance facts, template fallback, data minimization,
   localization, and the existing Delete All guarantee remain non-negotiable.
7. A phase is not Done until the required documentation, automated gates, manual verification,
   and `Docs/Commercialization/SESSION_LOG.md` entry exist.

## COM-C0A — Specification lock and repository audit

Status: **Done.**

Allowed scope is read-only inspection, reproducible build/test execution, and audit documents.
There must be no product code, schema, StoreKit product, backend, telemetry, CloudKit, Watch, or
model-provider change.

- [x] **C0A-01 — Baseline and source inventory.** Record Xcode/Swift/SDK/deployment/bundle/build
  configuration; run current build, unit, UI, coverage, money, and release checks; inventory source
  documents and their precedence.
- [x] **C0A-02 — Requirement index and conflict register.** Create stable Requirement IDs and map
  source, status, phase, test, and decision. Audit at minimum the current no-cloud/no-analytics
  rules against Free iCloud, first-party telemetry, Local Lifetime deferral, current-entitlement
  validation, receipt scope, and multi-provider cloud AI.
- [x] **C0A-03 — Repository boundary audit.** Inspect SwiftData schemas and every money field;
  StoreKit/CloudKit/network/third-party SDK state; feature flags and Pro checks; Foundation Models,
  Vision, camera and picker capabilities; logs, exports, diagnostics, privacy deletion, and
  possible content leakage.
- [x] **C0A-04 — Report and owner gate.** Create `SPEC_CONFLICTS.md`, `REQUIREMENTS_INDEX.md`, and
  `COM_C0A_REPORT.md`; label unknown facts `UNVERIFIED`; identify C0B blockers and recommended
  order; stop for owner decisions.

Exit gate: reproducible baseline, complete report, no product-code change, all P0 conflicts closed
as Accepted/Rejected/Superseded, and the owner explicitly accepts the C0B input assumptions.

Audit evidence: `Docs/Commercialization/COM_C0A_REPORT.md`,
`Docs/Commercialization/REQUIREMENTS_INDEX.md`,
`Docs/Commercialization/SPEC_CONFLICTS.md`, and commercialization Session 1. The owner accepted
SPEC-012, SPEC-013, SPEC-014, and SPEC-017 on 2026-08-10, satisfying the final decision gate.

## COM-C0B — Durable memory, baseline, and execution controls

Status: **Done.**

- [x] **C0B-01 — Commercial memory and decisions.** Create the dedicated project memory,
  decisions, session log, and main-document pointers from accepted Requirement IDs.
- [x] **C0B-02 — Security and commercial matrices.** Create the network egress policy, AI provider
  contract, StoreKit test matrix, and regional-pricing worksheet with prices explicitly TBD.
- [x] **C0B-03 — CI baseline and C1 packets.** Establish report paths and non-behavioral gates;
  turn COM-C1 into small PR-ready changes with input, test, and stop conditions.

### Current todo

- None. COM-C0B is closed; no additional work belongs in this phase.

### Completed work

- Dedicated commercial memory/decision register plus egress, AI-provider, StoreKit, and pricing
  matrices exist with accepted Product IDs and an empty current Release app-owned egress set.
- The empty egress set is enforced against app Swift source and Release configuration surfaces,
  with comment/DTD false-positive samples built into the gate. The external specification's
  audit fingerprint has an explicit provenance/limitation record, and CI publishes downloadable
  xcresult evidence rather than only a runner-local path.
- SPEC-018's stale deletion-model count is corrected without changing app behavior.
- CI/report paths and the COM-C1 three-packet input/task/test/stop contract are executable. The
  money, source-network, and documentation gates, Release build, 270 Swift tests, 13 UI tests,
  and coverage gate passed on 2026-08-10.

Review closeout evidence: `Docs/Commercialization/SESSION_LOG.md`, Sessions 4–5.

### Technical debt

- Prices, trial, included cloud calls/reset, storefronts, provider set/contracts, backend domains,
  CloudKit architecture, and App Attest design remain deliberately `TBD`/`UNVERIFIED`.
- SPEC-015 permits a future narrowly reviewed non-money Vision float boundary, but COM-C4C must
  update the scanner before adding Vision code.

### Session pointer

- `Docs/Commercialization/SESSION_LOG.md`, 2026-08-10 Session 3.

Exit gate: durable documents do not overlap, Release egress allow-list exists, CI has no baseline
regression, and every C1 Requirement is Active with no `BLOCKED_BY_SPEC` state.

## COM-C1 — Entitlement model and Feature Access

Status: **In Progress — all three packets implemented; C1-03 awaits independent review.**

- [x] **C1-01 — Pure entitlement domain.** Implement `EntitlementSet`, `PremiumFeature`, collection
  semantics, versioned migration, and the reachable entitlement-domain matrix. Free iCloud must
  not be a premium feature; deferred entitlement bits remain unreachable. Evidence:
  `CommercializationEntitlementTests` and commercialization Session 6.
- [x] **C1-02 — Central access service and injection.** Add pure `FeatureAccessService`, protocol
  seams, the full feature-access matrix, and a Debug-only arbitrary-combination provider without
  StoreKit or manual Release unlock. Static authority chokepoints reserve entitlement-bearing
  construction and protocol implementation/refinement for Commerce while allowing exact-Free and
  injected protocol consumers elsewhere. Evidence: `CommercializationEntitlementTests`,
  `Scripts/check-feature-access-boundary.sh`, and commercialization Sessions 8–10.
- [x] **C1-03 — Existing-entry integration.** Route the accepted existing Apple on-device AI,
  non-24-hour cooling-off, and advanced Siri entries through one immutable Commerce snapshot;
  keep exact-Free templates, 24-hour cooling-off, basic Siri record/check actions, and all typed
  Free-core capabilities available. Static validation rejects feature-local Product IDs,
  `isPro`/`isPremium` state, manual unlock aliases, and duplicate direct feature decisions.
  Evidence: focused integration tests, the full validation record in commercialization Session
  11, and `Scripts/check-feature-access-boundary.sh`.

Exit gate: all reachable entitlement combinations pass; removing subscription returns exactly to
Free; no Release manual unlock or duplicate paid check exists.

## COM-C2 — StoreKit 2 purchase, restore, and subscription state

Status: **Blocked by COM-C1 and accepted Product IDs/subscription group.**

- [B] **C2-01 — StoreKit test catalog.** Add Configuration-only Monthly/Annual products and an
  isolated environment matrix. Do not create Lifetime or formal App Store products yet.
- [B] **C2-02 — Catalog and entitlement store.** Implement `StoreCatalog`, actor-isolated
  `EntitlementStore`, startup cache for presentation only, and exactly one lifecycle-owned
  `Transaction.updates` task.
- [B] **C2-03 — Purchase and restore flows.** Implement verification, finish, pending, cancel,
  error, user-triggered restore, and `SubscriptionStatusMapper` for subscribed/grace/retry/
  expired/revoked states.
- [B] **C2-04 — Environment and regression gate.** Prove Configuration, Sandbox, TestFlight, and
  Production rights cannot contaminate one another and Product loading failure does not erase a
  verified entitlement.

Exit gate: StoreKit matrix passes. Formal prices, trial, cloud quota, and App Store Connect
products remain blocked until the accepted cost inputs are available.

## COM-C3 — Paywall, trial, subscription management, and public configuration

Status: **Blocked by COM-C2 and accepted price/trial inputs.**

- [B] **C3-01 — Transparent paywall.** Monthly/Annual StoreKit prices, terms, restore, manage
  subscription, legal links, voluntary entry, value triggers, and frequency limits; no Lifetime or
  cloud promise.
- [B] **C3-02 — Trial lifecycle.** Drive activation and renewal reminders from accepted parameters
  and actual dates, with generic notification copy and correct cancellation/rescheduling.
- [B] **C3-03 — Signed public configuration.** Implement signature/version/expiry/rollback/cache
  verification with conservative offline defaults; configuration may change presentation but
  never entitlement or StoreKit price.
- [B] **C3-04 — UI and release quality.** Add billing-retry/expiry soft landing, bilingual copy,
  VoiceOver, Dynamic Type, appearance testing, and review disclosures.

Exit gate: purchase presentation is accurate and non-blocking, signed-config failure is safe, and
no deferred or incomplete product is advertised.

## COM-C4A — Money migration delta

Status: **Blocked by COM-C3 and COM-C0A's money audit.**

The current app already has an `Int64` minor-unit `Money` model, currency exponents, exact parsers,
versioned SwiftData migrations, and a floating-point gate. This phase must begin with a delta audit;
it must not replace correct existing infrastructure merely because v1.4 describes it generically.

- [B] **C4A-01 — Delta and migration plan.** Compare every v1.4 money/migration requirement with
  the existing implementation; define signs and anomaly/rollback behavior; mark already-satisfied
  requirements with evidence.
- [B] **C4A-02 — Required migration only.** Implement only missing schema/currency/identifier/
  backup behavior proven by C4A-01. Unsafe conversion stops and preserves the old store; no value
  passes through `Double`.
- [B] **C4A-03 — Recovery and currency matrix.** Prove idempotence, interruption rollback,
  anomalies-not-zero, `Int64` boundaries, USD/JPY/KWD, negative values, and existing money gates.

Exit gate: accepted plan and full money/migration test matrix pass with a rehearsed recovery path.

## COM-C4B — Free iCloud sync

Status: **Blocked by COM-C4A and accepted CloudKit architecture.**

- [B] **C4B-01 — Sync data design.** Define opt-in semantics, stable IDs, tombstones, conflict
  rules, local attachment separation, containers/environments, deletion, and schema migration.
- [B] **C4B-02 — Sync implementation.** Implement Free access, multi-device reconciliation,
  offline retry, quota/iCloud-disabled handling, and allow-listed diagnostics. Receipt images and
  local intermediate files never enter CloudKit.
- [B] **C4B-03 — Lifecycle and deletion.** Verify enable/disable/re-enable, entitlement changes,
  local/cloud Delete All, conflict visibility, duplicate prevention, and failure isolation.

Exit gate: Free users can sync safely; CloudKit failure never blocks local use; deletion and
retained local attachments have verified behavior.

## COM-C4C — Local Pro and receipt recognition

Status: **Blocked by COM-C4B.**

- [B] **C4C-01 — Premium seams and evidence.** Gate the accepted local Pro features centrally;
  expose rule sample/confidence; establish local-model and deterministic baselines.
- [B] **C4C-02 — Image acquisition and lifecycle.** Add camera/DataScanner/PHPicker capability
  gates, orientation/perspective/downsampling/pixel limits, cancellation, memory/background, and
  temporary-file cleanup.
- [B] **C4C-03 — OCR and pre-model privacy.** Preserve OCR geometry/order/confidence and remove
  card numbers, last-four patterns, and authorization codes before any model boundary.
- [B] **C4C-04 — Structured extraction and validation.** Add deterministic fallback, core-field
  generation, exact amount/date/currency/scale/duplicate validation, and experimental line-item
  switch defaulting off until accepted.
- [B] **C4C-05 — Mandatory confirmation and evaluation.** Persist nothing before confirmation;
  build at least 60 fixed receipts plus non-receipts; verify offline tiers, privacy zero leaks,
  accuracy, and 20-image memory stability.

Exit gate: local Pro has durable value without cloud AI; core receipt gates pass offline with zero
known sensitive-field leaks and no unconfirmed persistence.

## COM-C5 — R1 first-party telemetry, metrics, and runbook

Status: **Blocked by COM-C4C and accepted first-party telemetry conflict resolution.**

- [B] **C5-01 — Typed private client.** Fixed event/property allow-list, rotating pseudonymous ID,
  delete key, opt-out/reset/delete, encrypted bounded queue, batching, backoff, and no content.
- [B] **C5-02 — Minimal ingest and deletion.** Independent serverless ingest, unknown/free-text
  rejection, 90-day TTL, deletion API, environment separation, monitoring, and cost limits.
- [B] **C5-03 — Metrics and G1 evidence.** Define App Store metric workflow, survey, exact
  numerator/denominator/confidence intervals, observability coverage, and receipt funnel.
- [B] **C5-04 — Operations and disclosures.** Signed-config publish/rollback/key-rotation runbook,
  privacy policy, App Privacy, data-flow map, capture tests, and actual TTL/delete verification.

Exit gate: data channel is optional, content-free, deletable, observable, and cost-bounded; its
failure never changes app behavior.

## COM-C6 — Local commercialization TestFlight and review preflight

Status: **Blocked by COM-C5. No public release in this phase.**

- [B] **C6-01 — Automated release matrix.** Exercise StoreKit lifecycle, exact entitlement
  states, environment isolation, public config, R1 networking, migration/rollback, Free iCloud,
  receipt privacy/accuracy/memory, telemetry deletion/TTL, and offline local Pro.
- [B] **C6-02 — Signed-device and App Review preflight.** Validate purchase/restore/manage/legal
  visibility; screenshots and notes; network and IPA egress; key/content scans; data-protection,
  localization, accessibility, and privacy disclosures.
- [B] **C6-03 — TestFlight baseline.** Close P0/P1, record the accepted R1 baseline and known
  limitations, upload only after approval, and keep formal App Store release paused.

Exit gate: all v1.4 COM-C6 entry criteria pass and the baseline is suitable for Watch and G1
observation, but not public distribution.

## COM-C6.5 — Apple Watch companion

Status: **Parallel development after COM-C6 plus its 14-day no-P0/P1 gate. Distribution is a
separate post-iPhone-1.0 milestone and does not block G1, COM-C7, COM-C12, or iPhone 1.0.**

- [~] **C6.5-01 — Contracts and shared module.** Verify current watchOS guidance; move only common
  Money/entitlement/enums; version snapshot, command, acknowledgement, receipt, envelope, and
  `ledgerGenerationID` contracts.
- [~] **C6.5-02 — Targets and connectivity owner.** Create watchOS/Widget targets and one
  actor-owned `WCSession`; App Group is same-device Watch/Widget storage only, never cross-device
  transport.
- [~] **C6.5-03 — Durable outbox and exactly-once phone commit.** Data-protected bounded Outbox,
  fast and background paths, source-command dedupe, atomic receipt, tombstones, stale-generation
  rejection, crash/retry recovery, and Delete All compensation.
- [~] **C6.5-04 — Minimal Watch UX.** Confirmed amount/category/optional emotion, queue/retry state,
  freshness-labelled budget snapshot, Free/Pro state, fixed cooling actions, accessibility, and
  no free text or on-Watch purchasing.
- [~] **C6.5-05 — Widget, intents, and disclosure.** Smart Stack/complication and App Intents use
  the same entitlement/outbox/idempotency path; exact watch-face amounts are off by default.
- [~] **C6.5-06 — Reliability matrix.** Duplicate/replay/delete races, 100-entry capacity,
  offline/restart, stale snapshots, currency/time-zone/category changes, entitlement states,
  privacy capture, power/memory, and real-device matrix.

Exit gate: R1.1 Watch TestFlight evidence recorded before the separate Watch release. Watch delay
must not break iPhone R1 or block G1, COM-C7, COM-C12, or iPhone 1.0.

## G1 — Evidence and cost decision gate

Status: **Blocked by COM-C6 observation and accepted real supplier quotes.**

- [B] Freeze the evaluated app/schema/event/Eval versions and observation window.
- [B] Report App Store metrics, actual proceeds, telemetry coverage/funnels, surveys, local-model
  Evals, supplier quality/latency/cost, fixed backend costs, and candidate Monthly/Annual prices and
  included calls.
- [B] Record numerator, denominator, confidence interval, and segmentation for every criterion.
- [B] Output `PROCEED_TO_R2`, `CONTINUE_R1`, or `INSUFFICIENT_SAMPLE`; never lower a gate merely to
  advance the backend.
- [B] Accept the R2 provider candidates, unit economics, quota/reset policy, and C7 start decision.

Exit gate: an Accepted G1 decision. Only `PROCEED_TO_R2` authorizes COM-C7.

## COM-C7 — Current entitlement, App Attest, and backend skeleton

Status: **Blocked by G1.**

- [B] **C7-01 — Independent backend foundation.** Separate dev/staging/prod Cloudflare resources,
  secrets, deployment state, allow-lists, TTL, logs, monitoring, and hardened admin boundary; no
  reuse of another product's data or credentials.
- [B] **C7-02 — Apple current-state authority.** Verify signed transactions/notifications with
  App Store Server Library; validate bundle/app/environment/product; derive `subjectHash` only on
  server; query current subscription status; use short cache plus invalidation.
- [B] **C7-03 — Attestation and session.** App Attest nonce/assertion, short-lived token, replay
  protection, fail-closed cloud access, and explicit local fallback.
- [B] **C7-04 — License/usage/delete skeleton and economics.** Add minimal metadata structures and
  real-quote unit-economics document; do not connect a model provider.

Exit gate: only current subscribed/grace production state can create an attested cloud session;
historical/test/deferred/retry/expired/revoked state cannot. No model call exists.

## COM-C8 — Cloud Coach consent, redaction, and provider router

Status: **Blocked by COM-C7.**

- [B] **C8-01 — Versioned consent.** Explicit opt-in, pre-send preview, withdrawal, local history,
  Provider-scope renewal, and unreachable cloud path without current consent.
- [B] **C8-02 — Dual minimization boundary.** Client `PrivacyRedactionService` plus server
  `CloudPayloadSanitizer`; forbidden fields reject and alert; logs never contain prompt/response.
- [B] **C8-03 — Multi-provider router.** At least one primary and one independently evaluated
  backup adapter, provider/model allow-lists, separate keys, minimal-retention settings, region and
  policy records, and consent-aware failover. A domestic provider is eligible only after the same
  quality/privacy/security evaluation.
- [B] **C8-04 — Safe generation contract.** Stateless requests, at most six local summary turns,
  JSON Schema, app-owned actions, one repair attempt, timeout/cancel/idempotent short result cache,
  and deterministic/local fallback.
- [B] **C8-05 — Privacy and provider Evals.** Capture tests, delete cache, provider-by-provider
  quality/latency/cost, policy-disclosure updates, and proof that cloud values never override local
  financial facts.

Exit gate: no consent means no provider traffic; provider failover stays inside current consent;
forbidden content is absent from traffic/logs; local functionality remains complete.

## COM-C9 — Quota, rate limits, idempotency, and degradation

Status: **Blocked by COM-C8 and accepted cost/config inputs.**

- [B] **C9-01 — Authoritative plan quota.** Trial/Monthly/Annual/Connect included calls and reset
  policy come from accepted signed server config; Annual still resets at the accepted monthly
  boundary; no unlimited/fair-use or extra token pack.
- [B] **C9-02 — Atomic usage and idempotency.** Concurrent/retry/offline calls produce one model
  expense and one successful-user count; parse failures count cost/rate but not successful quota.
- [B] **C9-03 — Abuse and spend controls.** Per-minute/hour/day/month, token cap, user parse-failure
  breaker, App Attest/session checks, monitoring, and budget alarms.
- [B] **C9-04 — L1–L5 degradation and UI.** Independently triggerable/recoverable fallback levels;
  show included/used/remaining/reset without affecting local features when exhausted.

Exit gate: unit cost is bounded under concurrency/replay/abuse, quota follows the verified subject
across reinstall/devices, and every cloud failure has a local fallback.

## COM-C10 — Server notifications and reconciliation

Status: **Blocked by COM-C9.**

- [B] **C10-01 — V2 notification receiver.** Verify JWS, dedupe `notificationUUID`, reject
  forgeries, safely record unknown types, and invalidate related current-state cache.
- [B] **C10-02 — State and order handling.** Handle subscribed/renew/fail/grace-expired/expired/
  refund/revoke, out-of-order payloads, terminal temporary denial, and authoritative refresh.
- [B] **C10-03 — Operations and reconciliation.** History lookup, retry/alert, sampled current-state
  reconciliation and repair; plan change never resets current-period usage.

Exit gate: cached/backend entitlement converges to Apple current state, refunds/revocations close
cloud access promptly, grace remains allowed, retry does not.

## COM-C11 — Cloud operations, configuration, experiments, and cost dashboard

Status: **Blocked by COM-C10.**

- [B] **C11-01 — Safe operational configuration.** Signed/versioned/cached/rollback provider,
  model, token, quota, and consent-copy config; unknown IDs fail closed; rollback within five
  minutes.
- [B] **C11-02 — Content-free operations.** Cost/token/latency/error/degradation/TTL/App Store
  health dashboards and experiments that cannot change price or entitlement.
- [B] **C11-03 — Hardened admin.** Access/MFA, RBAC, CSRF, rate limits, audit logs, key rotation,
  high-risk review, no Prompt/response/ledger access, and no override of StoreKit/consent/quota.

Exit gate: every expense and retention path is explainable and observable without collecting
consumer content; configuration and admin failures use safe defaults.

## COM-C12 — Full-product security, privacy, review, and formal 1.0

Status: **Blocked by COM-C11. Watch distribution is a separate later milestone.**

- [B] **C12-01 — End-to-end automated matrix.** Consent lifecycle, entitlement/cache/notification,
  billing states, quota/reset, concurrency/idempotency, providers, cancellation, L1–L5, dual
  redaction, context trimming, deletion/TTL, environment isolation, signed config, and offline
  fallback.
- [B] **C12-02 — Security and privacy release review.** Threat model, penetration/abuse review,
  dependency and secret scans, data-flow map, App Privacy, policy, provider disclosure, egress,
  Delete All, and actual TTL evidence.
- [B] **C12-03 — Quality and economics gate.** Accepted model Evals, structured-output threshold,
  P95/SLO, availability, current entitlement, reconciliation, quota, degradation, and actual unit
  economics.
- [B] **C12-04 — App Review and 1.0 release.** Final StoreKit metadata and products, Review Notes,
  test path/account where required, screenshots, localized release copy, archive/sign/upload,
  phased operational watch, and no release with open P0/P1.

Exit gate: all v1.4 release gates are satisfied and recorded. Only then may the owner authorize
formal 1.0 App Store submission and public launch.

## Technical debt and deferred decisions

- Local Lifetime remains deferred; there must be no implementation placeholder or public promise.
- Monthly/Annual prices, trial, included cloud calls, reset boundary, regions, and launch provider
  set remain TBD until accepted evidence and cost analysis.
- Existing money infrastructure makes COM-C4A a delta audit, not an assumed rewrite.
- First-party telemetry, Free iCloud, and third-party provider use follow accepted SPEC-012: the
  current version stays unchanged and each later channel remains disabled until its authorization,
  privacy disclosure, deletion, and release gates pass.
- The exact formal 1.0 date is intentionally unset.

## Session pointers

- Planning extraction: `Docs/SESSION_LOG.md`, 2026-08-10 commercialization task decomposition.
- COM execution history starts in `Docs/Commercialization/SESSION_LOG.md`; keep a short pointer in
  the main session log.
