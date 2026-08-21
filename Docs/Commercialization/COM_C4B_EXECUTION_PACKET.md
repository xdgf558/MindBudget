# COM-C4B Execution Packet — Free iCloud Sync

## Status

Status: **In Progress.**

C4B-01 is Done after owner acceptance, independent review, green GitHub Actions run
`32434148439`, and PR #57 merge `90a1e66`. C4B-02P is Done after independent review, green
GitHub Actions run `32454490080`, and PR #58 merge `6f5fded`. C4B-02 implementation is complete
pending independent review; C4B-03 remains blocked.

## Input gate

PR #57 closed C4B-01 design and PR #58 closed the C4B-02P static prerequisites. The owner then
explicitly started C4B-02. This implementation adds an explicit non-mirrored Schema V6 sync
metadata boundary, a custom `CKSyncEngine` adapter, and default-off Settings consent, but it does
not create or provision an iCloud container, add iCloud/CloudKit/push/background entitlements,
deploy a Dashboard schema, contact a verified environment, or authorize release/distribution.

The normative accepted design is `ICLOUD_SYNC_CONTRACT.md`. It selects custom versioned records and
`CKSyncEngine` in a private custom zone, preserving the primary SwiftData store as explicitly
non-mirrored. The prerequisite work pins the recurring-claim grammar, genesis ancestry, quarantine
handoff, exact container/disclosure inputs, and repository-wide SwiftData static gate. C4B-02
implements that accepted local/runtime boundary while C4B-03 retains operational cloud and release
evidence.

## C4B-01 — Sync data design

Status: **Done after independent review, GitHub Actions run `32434148439`, and PR #57 merge
`90a1e66`.**

### Deliverables

- Audit V1–V5 and all 16 current `ModelCounts` owners, UUID/companion identities, cascade edges,
  historical provenance references, and rebuildable local caches.
- Define default-off Free/private-database custom-zone design, typed envelopes, deterministic
  conflict order, tombstones, durable inbox/staging, and an idempotent durable outbox.
- Prove why managed SwiftData/Core Data mirroring is excluded and why every primary
  `ModelConfiguration` must become `.none` before a CloudKit entitlement is added.
- Define C4B-02/C4B-03 boundaries, physical-device/Dashboard evidence, and permanent exclusion of
  attachments/OCR/recovery/security artifacts, encryption/key-reset behavior, and one-container
  Development/Production separation.

### Accepted evidence

- Apple primary documentation for `CKSyncEngine`, custom-record changes, managed-model
  compatibility, and `ModelConfiguration.CloudKitDatabase` is cited in the sync contract.
- The document gate parses packet states and contract declarations, and rejects a CloudKit
  import/entitlement unless every primary local `ModelConfiguration` explicitly uses `.none`.
- C4B-01 claims no verified container, account, Dashboard, quota, push, multi-device, or deployment
  behavior.
- Reviewed head `093535f` passed every step of GitHub Actions run `32434148439`; PR #57 merged as
  `90a1e66` on 2026-08-21.

## C4B-02 — Sync implementation

Status: **Implementation complete pending independent review.**

Schema V6 adds five app-owned sync metadata models without changing financial authority. Every
primary `ModelConfiguration` is explicitly `.none`. The implementation stages local fact and
outbox/tombstone in one `ModelContext` transaction, puts fetched records in a durable inbox before
topological `DataActor` application, and exposes only closed local-first status/retry controls.
The adapter uses only the accepted private database/custom zone/record type and one encrypted
envelope field; no entitlement or deployed container is claimed.

### C4B-02P — Prerequisite contract and static gate

Status: **Done after independent review, GitHub Actions run `32454490080`, and PR #58 merge
`6f5fded`.**

Before runtime implementation, the accepted contract requires: the canonical occurrence-key
parser/formatter with no `/`-bearing caller input; revision-1/no-parent genesis and exact accepted
parent ancestry thereafter; durable quarantine without an automatic winner; the exact bilingual
opt-in disclosure and container identifier; and a repository-wide production SwiftData gate that
centralizes `ModelContainer` construction and requires `.none` on every `ModelConfiguration`
before any CloudKit import/entitlement.

### Runtime implementation boundary

Implement only the accepted custom-record adapter/outbox/staging/status surface and explicit local
store hardening. All local mutations and sync outbox/tombstone creation must be one
`ModelContext` transaction, while fetched records enter durable inbox/shadow before `DataActor`
applies them. Managed SwiftData mirroring, public/shared database, attachment transfer,
cross-account merge, online write leases, and automatic enablement are prohibited.

### Implementation evidence

- The focused deterministic `CloudSyncTests` suite passes 20/20 on an iOS 26.4 simulator with
  Xcode 26.6 (`17F113`) at
  `/private/tmp/MindBudget-C4B02-CloudSync-Final.xcresult`.
- Tests cover default-off adapter construction, account/retry/failure mapping, V5-to-V6 migration,
  canonical recurrence identity and bytes, all 12 allow-listed fact types, permanent local-only
  cache exclusion, duplicate/replay, logical and cascade tombstones, topology, malformed/physical
  deletion, lineage ordering, resurrection rejection, account re-consent, encrypted-key reset,
  server-save conflict quarantine, and a sticky no-reupload pause after remote zone deletion/purge.
- Static verification enforces the exact 12-type allow-list, runtime anchors, private database,
  no physical `deleteRecord`, no public/shared database, no `CKAsset`, no iCloud entitlement in
  this packet, repository-wide `.none`, and centralized container construction.
- Full local validation, independent review, hosted CI, and merge remain required. C4B-03 evidence
  cannot be inferred from simulator fakes or this source-only adapter.

## C4B-03 — Lifecycle and deletion

Status: **Blocked by C4B-02 independent review, hosted CI, and merge.**

Own physical-device/multi-device lifecycle, CloudKit Dashboard, conflict/tombstone/deletion,
environment-isolation, privacy disclosure, and release evidence. C4B-02 unit fakes cannot close
these claims.

## Tests

C4B-01 ran documentation and static-boundary checks only. C4B-02 adds deterministic envelope,
outbox, conflict, malformed-record, local-failure-isolation, account, and full allow-list tests
without enabling Development.
C4B-03 must add opt-in/account/offline/quota/disable/delete/re-enable/multi-device physical-device
evidence and separate Dashboard checks for Development and Production.

## Stop conditions

Stop and return to the owner if the requested solution needs managed SwiftData mirroring, implicit
enablement, a Pro gate, public/shared database, generated CloudKit identity, automatic destructive
conflict resolution, attachment/OCR transfer, or Production deployment without acceptance. No Free
sync implementation claim is valid before C4B-02 review/CI/merge; no cloud-delete or multi-device
claim is valid before C4B-03 evidence.
