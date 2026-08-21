# COM-C4B Execution Packet — Free iCloud Sync

## Status

Status: **C4B-01 proposed architecture candidate complete pending independent review and owner acceptance.**

## Input gate

This packet is limited to C4B-01 design. It does not create an iCloud container, enable iCloud/
CloudKit/push/background entitlements, alter `ModelConfiguration`, introduce a `CloudKit` import,
create a network request, change SwiftData schema, deploy a CloudKit environment, or authorize
release/distribution. The owner started the design phase only; DEC-COM-028 remains Proposed until
owner acceptance and independent review.

The normative candidate is `ICLOUD_SYNC_CONTRACT.md`. It selects custom versioned records and
`CKSyncEngine` in a private custom zone, preserving the primary SwiftData store as explicitly
non-mirrored. C4B-02 cannot start until the owner accepts the decision and names the required
environment/container/disclosure inputs.

## C4B-01 — Sync data design

Status: **Proposed architecture candidate complete pending independent review and owner acceptance.**

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

### Candidate evidence

- Apple primary documentation for `CKSyncEngine`, custom-record changes, managed-model
  compatibility, and `ModelConfiguration.CloudKitDatabase` is cited in the sync contract.
- The document gate parses packet states and contract declarations, and rejects a CloudKit
  import/entitlement unless every primary local `ModelConfiguration` explicitly uses `.none`.
- C4B-01 claims no verified container, account, Dashboard, quota, push, multi-device, or deployment
  behavior.

## C4B-02 — Sync implementation

Status: **Blocked pending accepted DEC-COM-028, owner container/disclosure inputs, and C4B-01 independent review.**

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
