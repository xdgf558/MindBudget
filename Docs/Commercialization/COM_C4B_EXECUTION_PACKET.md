# COM-C4B Execution Packet — Free iCloud Sync

## Status

Status: **In Progress.**

C4B-01 is Done after owner acceptance, independent review, green GitHub Actions run
`32434148439`, and PR #57 merge `90a1e66`. C4B-02P prerequisite maintenance is pending review.

## Input gate

PR #57 closed C4B-01 design. This prerequisite closeout does not create an iCloud container, enable iCloud/
CloudKit/push/background entitlements, alter `ModelConfiguration`, introduce a `CloudKit` import,
create a network request, change SwiftData schema, deploy a CloudKit environment, or authorize
release/distribution. DEC-COM-028 is Accepted as architecture after owner acceptance, independent
review, green CI, and merge; runtime implementation still requires an explicit owner start.

The normative accepted design is `ICLOUD_SYNC_CONTRACT.md`. It selects custom versioned records and
`CKSyncEngine` in a private custom zone, preserving the primary SwiftData store as explicitly
non-mirrored. This maintenance packet pins the recurring-claim grammar, genesis ancestry,
quarantine handoff, exact container/disclosure inputs, and repository-wide SwiftData static gate
before C4B-02 runtime work may start.

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

Status: **Blocked.**

Runtime implementation is blocked pending review/merge of C4B-02P and
explicit owner instruction to begin it.

### C4B-02P — Prerequisite contract and static gate

Status: **Implementation complete pending independent review.**

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

## C4B-03 — Lifecycle and deletion

Status: **Blocked by C4B-02 implementation, review, CI, and merge.**

Own physical-device/multi-device lifecycle, CloudKit Dashboard, conflict/tombstone/deletion,
environment-isolation, privacy disclosure, and release evidence. C4B-02 unit fakes cannot close
these claims.

## Tests

C4B-01 runs documentation and static-boundary checks only. C4B-02 must add deterministic envelope,
outbox, conflict, malformed-record, and local-failure-isolation tests before enabling Development.
C4B-03 must add opt-in/account/offline/quota/disable/delete/re-enable/multi-device physical-device
evidence and separate Dashboard checks for Development and Production.

## Stop conditions

Stop and return to the owner if the requested solution needs managed SwiftData mirroring, implicit
enablement, a Pro gate, public/shared database, generated CloudKit identity, automatic destructive
conflict resolution, attachment/OCR transfer, or Production deployment without acceptance. No Free
sync implementation claim is valid before C4B-02 review/CI/merge; no cloud-delete or multi-device
claim is valid before C4B-03 evidence.
