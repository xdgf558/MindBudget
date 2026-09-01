# Commercialization Specification Conflicts

## Purpose and workflow

This register is the durable decision gate for the commercialization track. An `Open` item is
also `BLOCKED_BY_SPEC`: Codex may continue unrelated audit and documentation work, but it must not
implement an affected phase until the owner changes the item to `Accepted`, `Rejected`, or
`Superseded` and records the resulting decision in `Docs/Commercialization/DECISIONS.md`.

Priority: P0 changes the permitted product/data boundary or phase ordering; P1 blocks a later
implementation contract; P2 is documentation/tooling ambiguity without current product impact.

Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`, SHA-256
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`.
See `SOURCE_PROVENANCE.md` for the external-source boundary and mandatory re-audit procedure.

## Historical conflicts resolved by the specification

| ID | Original conflict | Resolution and version | Code impact | Requirement | Status | Evidence |
|---|---|---|---|---|---|---|
| SPEC-001 | R1 simultaneously prohibited every network layer and required StoreKit, iCloud, public configuration, and telemetry. | v1.2 replaced the blanket ban with four allow-listed R1 channels and prohibited an account/entitlement/cloud-AI ledger backend. | A future centralized `NetworkEgressPolicy`; no implementation exists at COM-C0A. | REQ-R1-NET-001 | Resolved in v1.2 | v1.4 §0A F-11 and §4.7 |
| SPEC-002 | COM-C3 depended on public configuration that was scheduled only in COM-C5. | v1.2 put the signed configuration client in COM-C3 and left key rotation, operations, and telemetry to COM-C5. | Client/operations separation; no implementation exists. | REQ-R1-NET-001, REQ-R1-TELEMETRY-001 | Resolved in v1.2 | v1.4 §0A S-10, §§15.2–15.3 |
| SPEC-003 | The absolute “all data stays on device” claim conflicted with optional iCloud and telemetry. | v1.2 narrowed the claim to on-device budget/receipt processing and required separate iCloud and telemetry disclosure. | Privacy copy and App Privacy answers must change before either channel ships. | REQ-ICLOUD-001, REQ-R1-TELEMETRY-001 | Resolved in v1.2 | v1.4 §0A F-13 and §16 |
| SPEC-004 | Billing Retry and Billing Grace were both mapped to continued Pro access. | Only `subscribed` and `inGracePeriod` grant subscription rights; retry, expiry, and revocation do not. | One subscription-status mapper must enforce this table. | REQ-STOREKIT-STATE-001 | Resolved in v1.2 | v1.4 §0A F-14 and §7.5 |
| SPEC-005 | The old plan claimed every existing-subscriber price increase required consent. | Apple determines consent from current storefront rules; the app does not infer it. | StoreKit state/copy only; no hard-coded consent logic. | REQ-STOREKIT-LIFECYCLE-001 | Resolved in v1.2 | v1.4 §0A F-15 and §8.6 |
| SPEC-006 | A “one month” trial was treated as 30 days and a fixed day-25 message promised five days remaining. | Trial and renewal notices derive from accepted StoreKit terms and a verified `renewalDate`; no reliable date means no inferred reminder. | Dynamic scheduling and cancellation/rescheduling. | REQ-STOREKIT-LIFECYCLE-001 | Resolved in v1.2 | v1.4 §0A F-16 and §8.3 |
| SPEC-007 | Historical transaction JWS was treated as lasting proof of current cloud entitlement. | JWS establishes transaction identity; R2 must query current App Store server state, use a short cache, and invalidate it from notifications. | Server-side current-entitlement boundary in COM-C7/C10. | REQ-CLOUD-AUTH-001 | Resolved in v1.2 | v1.4 §0A F-17 and §15.5 |
| SPEC-008 | A public promise of exactly 200 Local Lifetime sales conflicted with delayed sales reporting and possible oversell. | v1.2 made 200 an internal planning limit; v1.4 further defers Lifetime entirely with no product, entry, or promise. | No Lifetime identifier, entitlement, copy, or public configuration key. | REQ-ENTITLEMENT-001 | Resolved in v1.2; superseded by v1.4 deferral | v1.4 §0A F-18, §0.2, §8.4 |
| SPEC-009 | The plan assumed App Store Analytics could receive arbitrary custom funnel events. | Platform metrics remain separate; an optional first-party, allow-listed, pseudonymous channel is required for custom events. | COM-C5 client/receiver, consent, deletion, TTL, and disclosure. | REQ-R1-TELEMETRY-001 | Resolved in v1.2 | v1.4 §0A F-12 and §17.2–17.5 |
| SPEC-010 | Receipt processing was named a three-stage pipeline while specifying five stages and unclear line-item scope. | It is a five-stage local pipeline; core fields are release-gated while line items remain experimental and default off. | COM-C4C pipeline and fixed evaluation corpus. | REQ-RECEIPT-PIPELINE-001, REQ-RECEIPT-PRIVACY-001 | Resolved in v1.2 | v1.4 §0A F-20/F-21 and §9.6 |
| SPEC-011 | Apple Watch was only a feature placeholder with no target, sync, entitlement, privacy, or release contract. | v1.3 created COM-C6.5, made iPhone authoritative, and specified WatchConnectivity, outbox/idempotency, StoreKit mapping, privacy, and test gates. | A future companion target; none exists at COM-C0A. | REQ-WATCH-SCOPE-001, REQ-WATCH-SYNC-001, REQ-WATCH-ENTITLEMENT-001, REQ-WATCH-PRIVACY-001 | Resolved in v1.3 | v1.4 §0A A-09–A-12 and §9.8 |

## Conflicts found in COM-C0A

### SPEC-012 — Current local-only rules versus approved commercialization data paths

- Priority/status: **P0 — Accepted by owner on 2026-08-10**
- Locations: root `AGENTS.md` non-negotiable 6; `Docs/PROJECT_MEMORY.md` V1 forbidden
  scope; `Docs/PRIVACY_AND_REVIEW_NOTES.md` data handling; v1.4 §0.3, §4.7, §§11–17.
- Conflict: the current repository forbids cloud sync and third-party AI and promises no
  automatic developer-side data transfer. v1.4 requires opt-in Free iCloud, optional first-party
  telemetry, and later consented multi-provider cloud AI. The new track is additive and must not
  silently rewrite what the currently shipped 0.9.x binary does, but later code cannot comply with
  both rule sets literally.
- Impact: CloudKit, telemetry, cloud AI, network egress, privacy copy, App Privacy, deletion, and
  the root non-negotiables.
- Owner resolution: existing released/TestFlight behavior and historical documentation remain
  unchanged. A later commercialization build may enable an approved iCloud, first-party telemetry,
  or multi-provider cloud-AI channel only after that channel passes explicit user authorization,
  privacy disclosure, deletion, and release gates. COM-C0B may update forward-looking rules using
  this phase-scoped boundary without rewriting Phase 0–12 history.
- Owner: Product owner.
- Blocks: none at the specification layer; the named implementation/release gates still block each
  channel until objectively satisfied.
- Requirements: REQ-R1-NET-001, REQ-R1-TELEMETRY-001, REQ-ICLOUD-001,
  REQ-CLOUD-CONSENT-001, REQ-CLOUD-USAGE-001.
- Verification evidence: current source contains no CloudKit, telemetry, backend, URLSession, or
  third-party provider implementation; current privacy manifest declares no collection/tracking.

### SPEC-013 — Watch dependency on G1 and COM-C7 is contradictory

- Priority/status: **P0 — Accepted by owner on 2026-08-10**
- Locations: v1.4 historical S-13 and COM-C6.5 “Next inputs” say Watch does not block G1 or
  COM-C7; v1.4 §19.1 orders Watch before G1 and G1-1 requires COM-C0A through COM-C6.5 all green.
- Conflict: both phase graphs cannot be enforced. The pre-created
  `Docs/COMMERCIALIZATION_TASKS.md` inherited the nonblocking S-13 interpretation while the current
  v1.4 G1 table expresses the opposite.
- Impact: critical path, CI/release evidence ownership, and the earliest legal start of COM-C7.
- Owner resolution: COM-C6.5 development may run in the documented middle/parallel window after
  its prerequisites, but it does not block G1, COM-C7, COM-C12, or the formal iPhone 1.0 launch.
  Apple Watch distribution is a separate post-iPhone-1.0 release milestone. The Watch target must
  not be bundled or advertised in the first formal iPhone release unless the owner later makes a
  new Accepted decision and its own release gates pass.
- Owner: Product owner.
- Blocks: none for G1/COM-C7/iPhone 1.0. Watch distribution remains blocked by COM-C6.5's own
  automated, signed-device, privacy, entitlement, and review gates.
- Requirements: REQ-G1-001, REQ-WATCH-SCOPE-001.
- Verification evidence: direct text comparison of v1.4 §0A S-13, §19.1–19.2, and COM-C6.5.

### SPEC-014 — Price/product input creates a circular phase gate

- Priority/status: **P0 — Accepted by owner on 2026-08-10**
- Locations: v1.4 §4.2–4.3; COM-C2 next-input gate; G1-3; COM-C7 sequencing.
- Conflict: formal Monthly/Annual products require accepted price and cloud-quota economics, and
  COM-C3 requires StoreKit product data. The full provider cost/quota decision is placed at G1
  after COM-C6, but COM-C6 needs real TestFlight StoreKit behavior. A single final cost decision
  therefore depends on a phase that itself depends on that decision.
- Impact: Product IDs, App Store Connect products, COM-C2/3/6 inputs, TestFlight purchase tests,
  regional pricing, and cloud quota copy.
- Owner resolution: use three explicit evidence gates: (a) configuration-only Monthly/Annual test
  products and provisional test terms for COM-C2/3; (b) accepted preliminary unit economics before
  formal products and COM-C6; and (c) the G1 final provider/quota/cost decision. Monthly/Annual
  prices, trial, included calls, reset policy, and public quota claims remain TBD until the
  applicable worksheet is Accepted.
- Owner: Product owner with engineering/cost evidence.
- Blocks: the circular specification conflict is closed. Formal products and public commercial
  terms remain operationally blocked until evidence gate (b); cloud quota/provider claims remain
  blocked until evidence gate (c).
- Requirements: REQ-STOREKIT-LIFECYCLE-001, REQ-CLOUD-USAGE-001, REQ-G1-001.
- Verification evidence: v1.4 explicitly leaves price/trial/quota `TBD`; no current Product ID or
  StoreKit catalog exists.
- Current owner override: DEC-COM-092 supersedes only the pending G1 offer hypothesis. G1 now
  evaluates a US$4.99 one-time local-Pro unlock with finite starter cloud credits and consumable
  usage cards from dated real AI/backend quotes. It does not retroactively relabel the completed
  Monthly/Annual TestFlight evidence, create a formal product, or accept a customer price/count.

### SPEC-015 — Floating-point CI scope conflicts with receipt geometry/confidence

- Priority/status: **P1 — Accepted by owner on 2026-08-10**
- Locations: `Scripts/check-no-floating-point-money.sh`; v1.4 §9.6.2 and §9.6.4.
- Conflict: the current script rejects `Double` or `Float` in every app Swift file except the
  isolated App Intents adapter. The receipt contract requires non-money OCR confidence and image
  geometry, for which SDK APIs use floating-point values. The specification forbids floating
  point in money paths, not in all vision transport.
- Impact: receipt OCR code would fail CI even while keeping all money exact.
- Suggested resolution: before COM-C4C, replace the repository-wide lexical rule with an explicit
  money-module/path allow-list plus reviewed, narrow non-money exceptions for Vision geometry and
  confidence. Keep amount parsing/conversion under the existing exact-money gate.
- Owner: Engineering, accepted by product owner as a tooling boundary.
- Blocks: COM-C4C only.
- Requirements: REQ-MONEY-001, REQ-RECEIPT-PIPELINE-001.
- Verification evidence: current script scans all `MindBudget/**/*.swift`; receipt/Vision code is
  absent, so the conflict is prospective and reproducible from the script.

### SPEC-016 — COM-C0A report/source names disagree inside v1.4

- Priority/status: **P2 — Resolved in COM-C0A**
- Locations: v1.4 mandatory files require `COM_C0A_REPORT.md`; the embedded first prompt says
  `PHASE_0A_REPORT.md` and refers to v1.3.
- Resolution: the current top-level v1.4 phase contract wins over its stale embedded prompt. This
  audit uses `COM_C0A_REPORT.md` and records the v1.4 hash.
- Impact: documentation only.
- Owner: Engineering (mechanical current-source correction).
- Blocks: none.
- Requirements: none.
- Verification evidence: this file and `COM_C0A_REPORT.md` use the current names.

### SPEC-017 — Suggested Product ID domain differs from the actual app domain

- Priority/status: **P1 — Accepted by product owner on 2026-08-10**
- Locations: v1.4 §4.3–4.4 examples use `com.stationcat.mindbudget`; current app is
  `com.xdgf558.MindBudget` and v1.4 directs COM-C0A to record the actual value.
- Conflict: the examples are explicitly nonfinal, but C1/C2 need an immutable canonical Product
  ID allow-list.
- Impact: entitlement mapping, StoreKit configuration, App Store Connect products, Watch shared
  identifiers, server verification, and tests.
- Owner resolution: use one lowercase reverse-domain family derived from the current owned bundle
  namespace:
  - Monthly: `com.xdgf558.mindbudget.pro.monthly`
  - Annual: `com.xdgf558.mindbudget.pro.annual`
  - Subscription group internal reference name: `MindBudget Pro`
  - Internal product reference names: `MindBudget Pro Monthly` and `MindBudget Pro Annual`
  These are technical identifiers, not localized customer-facing names. They must be used
  consistently by StoreKit configuration, App Store Connect, entitlement mapping, Watch, backend
  validation, and tests. Do not create the formal products before SPEC-014 evidence gate (b).
- Owner: Product owner.
- Blocks: none at the naming layer; formal product creation remains blocked by SPEC-014 evidence
  gate (b).
- Requirements: REQ-ENTITLEMENT-001, REQ-STOREKIT-LIFECYCLE-001,
  REQ-WATCH-ENTITLEMENT-001.
- Verification evidence: Xcode build settings report `com.xdgf558.MindBudget`; repository search
  finds no existing StoreKit Product ID. Apple documents Product ID as immutable after creation
  and not reusable within the app, so the accepted values must not be casually changed:
  <https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/view-and-edit-in-app-purchase-information>.

### SPEC-018 — Current privacy deletion documentation has a stale model count

- Priority/status: **P1 — Resolved in COM-C0B on 2026-08-10**
- Locations: `Docs/PRIVACY_AND_REVIEW_NOTES.md` says Delete All removes/verifies ten entity types;
  Schema V4 and `ModelCounts` contain fifteen.
- Conflict: production code correctly enumerates and verifies all fifteen current models, but the
  durable privacy/review statement understates the deletion surface.
- Impact: App Review notes and future iCloud/telemetry deletion design; no current deletion-code
  failure was found.
- Resolution: current privacy, project-memory, and test-plan statements now say “all current
  SwiftData model types”/“every current model count” rather than maintaining a fragile numeric
  claim. The runtime enumeration and fail-closed postcondition remain unchanged.
- Owner: Engineering documentation, reviewed by product owner.
- Blocks: privacy documentation sign-off; not COM-C0A audit completion.
- Requirements: REQ-ICLOUD-001, REQ-R1-TELEMETRY-001.
- Verification evidence: `SchemaV4.models`, `DataActor.modelCounts()`, and
  `deleteAllLocalModels()` contain the same fifteen types; deletion tests are green.

## Owner decision checklist

The owner explicitly accepted SPEC-012, SPEC-013, SPEC-014, SPEC-015, and SPEC-017 on 2026-08-10.
COM-C0B resolved SPEC-018 by correcting the durable deletion surface without changing runtime
behavior. The COM-C0A decision gate is closed. No remaining Open item grants permission to work
ahead of its named phase.
