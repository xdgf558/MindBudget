# Free iCloud Sync Contract

## Status

Status: **C4B-01 proposed architecture candidate complete pending owner and independent review.**

This is a design contract, not authorization to create a CloudKit container, add an entitlement,
ship a request, migrate SwiftData, deploy a schema, or change local-only behavior. Only an Accepted
decision may authorize C4B-02.

## Scope and authority

MindBudget remains local-first. Sync is Free for every entitlement state, default off, and begins
only after explicit user choice. Missing account, disabled iCloud, offline state, quota, malformed
remote data, CloudKit failure, or unresolved conflict never prevents local create/read/edit/export/
Delete All.

The candidate is **custom versioned records in one custom zone of the signed-in person's CloudKit
private database, synchronized by `CKSyncEngine`**. `CKSyncEngine` supplies Apple-managed
scheduling/change transfer; MindBudget owns the record schema, identity, outbox, conflict resolver,
tombstones, and local projection. Its opaque serialized state must be persisted/restored unchanged,
but is never the authority for unsent business data.

Apple documents that `CKSyncEngine` manages a chosen database, calls a delegate for records,
retries listed transient account/network/service conditions, requires persistent opaque state, has
indeterminate scheduling, and must not sync a public database. Sources:
[CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine),
[CKSyncEngineDelegate](https://developer.apple.com/documentation/cloudkit/cksyncenginedelegate), and
[Remote Records](https://developer.apple.com/documentation/cloudkit/remote-records).

## Contract declarations

| Key | Required value |
|---|---|
| Access | Free for all entitlement states; explicit default-off opt-in; no implicit enablement or Pro gate |
| Local authority | Local reads/writes/export/Delete All never wait for CloudKit success; retries are asynchronous and nonblocking |
| Cloud database | Private database only; proposed zone `MindBudget.Sync.v1` and record type `MindBudgetEnvelopeV1`; never public/shared database |
| Record identity | Canonical lower-case UUID business ID; record name `<type>/<uuid>` except recurring occurrence claim `<type>/<occurrenceKey>`; CloudKit-generated identity is never a business key |
| Envelope | Closed `schemaVersion`, `type`, `id`, per-record-lineage `revision`, `isDeleted`, `modifiedAt`, and typed encrypted payload carrying parent/semantic digests; unknown data fails closed without mutating local facts |
| Ordering | Server-owned CKRecord system fields/change tag plus encrypted parent/semantic digest detect replay or descent; wall clock and device identity never choose a divergent financial winner |
| Deletion | Logical tombstone has the same record name and participates in ordering; retain until C4B-03 proves compaction safety |
| Environment | One proposed exact container `iCloud.com.xdgf558.MindBudget`, not created here; entitlement-selected Development/Production environments and same-named private custom zone remain strictly separate |
| Encryption | Typed ledger/note/reflection payload and semantic digest are one encrypted `Data` field in `CKRecord.encryptedValues`; only non-content routing metadata is unencrypted and no content field is indexed |
| Attachments | Receipt images, OCR text/geometry, local intermediates, recovery artifacts, logs, StoreKit data, notification state, and config cache never enter CloudKit |
| Managed SwiftData sync | Every primary local `ModelConfiguration` must explicitly use `cloudKitDatabase: .none` before any CloudKit entitlement/import |
| Disable/delete | Disable cancels transfer and retains local facts; remote deletion is separately confirmed and never silently implied |

## Why this architecture

### Chosen: custom records plus `CKSyncEngine`

The store has stable UUID identities, local-only derived caches, cascade edges, historical
provenance references, and a recovery envelope around SQLite files. The product needs an allow-list
of payload fields, deterministic conflict ordering, tombstones, and an auditable Delete All meaning.
Custom private-zone records make each rule reviewable. `CKSyncEngine` retains the Apple scheduler
but leaves application-specific server-record-changed resolution to MindBudget, as Apple documents.

### Rejected: SwiftData/Core Data managed CloudKit mirroring

Managed mirroring would export the local model graph instead of this explicit allow-list. The model
uses many `@Attribute(.unique)` identities and two cascade relationships. Apple's Core Data/CloudKit
compatibility documentation says unique constraints are unsupported and relationships must be
optional, inverse-backed, and may arrive out of order. `ModelConfiguration`'s URL initializer also
defaults `cloudKitDatabase` to `.automatic`, which uses the primary ubiquity container once an
entitlement exists; `.none` disables it. Sources:
[CloudKit-compatible Core Data model](https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit),
[ModelConfiguration initializer](https://developer.apple.com/documentation/swiftdata/modelconfiguration/init%28_%3Aschema%3Aurl%3Aallowssave%3Acloudkitdatabase%3A), and
[ModelConfiguration.CloudKitDatabase.none](https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct/none).

### Rejected: direct lower-level CloudKit without `CKSyncEngine`

Direct operations can carry the same envelopes, but would make MindBudget own retry-after,
reachability, subscriptions, and change-token mechanics without a product need. The selected engine
does not remove the need for the app outbox, tombstones, conflict resolver, or tests.

### Encryption boundary

Every typed payload contains the allow-listed full user fields for its authoritative record,
including expense/rule notes, income source/note, merchant/wish text, and reflection text, plus its
parent/semantic digests. It is encoded as one versioned `Data` value in `CKRecord.encryptedValues`.
Only minimum routing/control metadata is unencrypted: record type/name, envelope schema version,
per-record revision, and tombstone flag.
Encrypted fields are never queried or indexed. Apple documents that encrypted values are encrypted
on-device, cannot be indexed, and encrypted-key reset may report `zoneNotFound` plus
`CKErrorUserDidResetEncryptedDataKey`; C4B-02 must pause, preserve local facts/outbox, and require
an explicit recovery choice. It must never auto-purge/reupload after key reset. Sources:
[Encrypting User Data](https://developer.apple.com/documentation/cloudkit/encrypting-user-data) and
[CKRecord.encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues).

## Current-store inventory and mapping

`SchemaV1` contains 9 models, V2 adds `Income`, V3 adds four income/recurrence models, V4 adds
`BudgetPlanSemantics`, and V5 adds `MerchantAccountingContext`. `ModelCounts` therefore has **16**
V5 tables (not 15): the prior C4A 15-table audit predates the V5 companion. UUIDs below are current
unique business IDs; `BudgetPlanSemantics.planID` and `MerchantAccountingContext.merchantID` are
stable companion keys.

| V5 owner | Identity / relationship | C4B treatment |
|---|---|---|
| Expense | `id`; scalar recurrence/merchant provenance | Sync authoritative envelope |
| Income | `id` | Sync authoritative envelope |
| IncomeAllocation | `id`, unique `incomeID`, optional `budgetPlanID` | Sync; missing parent queues, never guesses |
| SavingsGoal | `id` | Sync authoritative envelope |
| RecurringFixedExpenseRule | `id`, unique `originExpenseID` | Sync authoritative envelope |
| RecurringExpenseOccurrence | `id`, unique `occurrenceKey`, rule/expense IDs | Sync control-plane envelope to prevent duplicate cross-device generation |
| BudgetPlan | `id`; cascades category budgets | Sync authoritative envelope; child carries `planID` |
| BudgetPlanSemantics | unique `planID` | Sync companion envelope |
| CategoryBudget | `id`, optional plan relationship | Sync; remote child may arrive before parent |
| WishItem | `id`; cascades cooling-off plans | Sync authoritative envelope |
| CoolingOffPlan | `id`, optional wish relationship | Sync excluding local notification identifier |
| ReflectionLog | `id`, scalar provenance IDs | Sync authoritative envelope |
| SpendingInsight | `id`, unique dedupe key, derived payload | Local-only/recompute |
| ReminderEvent | `id`, throttle/notification history | Local-only/device-specific |
| Merchant | `id`, unique normalized name, aggregate cache | Local-only/rebuild |
| MerchantAccountingContext | unique `merchantID` | Local-only/rebuild |

No receipt/OCR/image/attachment/temp-file model exists in V5. Future C4C artifacts are permanently
excluded. Recovery backup/journal/manifest and signed public-config cache are local security or
recovery artifacts, never envelopes.

## Envelope, mutation, and conflict rules

Each allow-listed object has deterministic record name from type and canonical UUID in proposed
`MindBudget.Sync.v1` using proposed record type `MindBudgetEnvelopeV1`. The recurring
claim instead derives from its stable `occurrenceKey`, not random `occurrence.id`. Typed payloads
preserve `Int64` minor units plus ISO currency. Every local authoring transaction writes its local
fact plus durable pending envelope/tombstone in one `ModelContext` transaction before background
send. C4B-02 may add those sync metadata models in Schema V6; a save without its outbox is invalid.
Local sync metadata stores encoded CKRecord system fields, including the server-owned change tag,
for conditional save. Replays are idempotent by record name, accepted parent digest, per-record
lineage revision, and encrypted semantic digest; engine serialization may be a rebuildable sidecar
because the durable outbox, not engine state, is the source for unsent work.

An envelope records a per-record-lineage revision plus encrypted parent and semantic digests. A
later envelope is an idempotent replay or safe supersession only when it descends from the same
accepted parent and its digest proves the stated content. The durable local sync metadata's
CKRecord system fields carry the server-owned change tag; save-if-unchanged is the concurrency
authority and detects a concurrent server change; equal
semantic digest is acknowledgement, not conflict. A divergent payload or tombstone is never chosen
by wall clock, device identity, or last-writer-wins: both candidates enter durable conflict quarantine,
the current valid local fact remains visible, and that record's transfer pauses for explicit
resolution/visibility owned by C4B-03. A logical tombstone uses the same record name, rather than
an immediate `CKRecord` delete, so reinstall/re-enable/full fetch cannot resurrect stale facts.
`CKSyncEngine` account-change handling clears its pending state; MindBudget's durable outbox must
remain separate, pause on account change, and require re-consent before any new-account upload.
Remote fetched changes first enter a durable inbox/shadow. The app validates and topologically
applies them through `DataActor`; a sync-engine delegate never mutates SwiftData directly. Unknown
schema/enum, malformed money, invalid cross-currency data, or unresolved required link is
quarantined without local mutation. A server-record-changed error refetches/recompares; it never
blindly overwrites newer remote data.

Parent/child arrival is order-independent: missing-parent children stay in staging, not as an
orphan or fabricated fact. Parent deletion emits explicit child tombstones, never an inferred remote
cascade. `RecurringExpenseOccurrence` is synced as a control-plane claim because keeping it only on
each device would allow two devices to generate duplicate recurring expenses. If simultaneous
offline claims carry different expense IDs, C4B-02 must introduce a deterministic origin companion
or surface the conflict; it must not delete either possibly edited expense to manufacture agreement.

## Account, offline, quota, and lifecycle behavior

Before opt-in no engine or CloudKit database/zone call is initialized. Enable checks account
availability only after consent. Account absence, sign-out, quota, network/rate/service failure, or
background suspension preserves local authority and reports neutral allow-listed reason codes with
retry. Disable stops future transfer and keeps local records; it neither deletes remote copies nor
permits automatic reimport. A different iCloud account pauses the old state and requires explicit
re-consent. No timing-based online lease may delay or reject offline budgeting writes.

Delete All is unchanged in C4B-01. C4B-03 must offer an explicit distinction between local delete,
required cloud-wide delete, and disable while retaining cloud copy. Cloud-wide delete writes durable
tombstones and reports pending completion while offline; local deletion remains available even if
cloud deletion cannot start. Re-enable after local-only deletion needs confirmation before import.

## Environment and deployment boundary

The proposed identifier is `iCloud.com.xdgf558.MindBudget`, but it has not been created or accepted.
One CloudKit container has strictly separate Development and Production environments selected by
the provisioning entitlement, and each environment uses the same-named private custom zone. Apple
documents the entitlement-selected environment and that deployment copies a tested Development
schema to Production without copying records. C4B-01 adds neither entitlement nor schema.
Sources: [CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer) and
[Deploying an iCloud Container’s Schema](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema).
C4B-02 starts only when owner acceptance confirms this exact identifier, team/roles, account
matrix, and explicit opt-in disclosure naming financial records plus notes/reflections. Neutral
quota wording must say local data and edits remain safe and sync resumes after iCloud space/account
availability; it must not promise a time or amount.

## C4B-02 and C4B-03 handoff

C4B-02 owns explicit `.none` primary-store hardening before entitlement, private-zone
`CKSyncEngine` adapter, envelopes/outbox/staging, local status UI, and diagnostics. It must prove
opt-out, no account, offline, quota, duplicate delivery, account change, and attachment exclusion.
C4B-03 owns physical-device/multi-device lifecycle, Dashboard evidence, conflict/tombstone/delete
retention, Development/Production isolation, disclosure, and release approval. Unit fakes alone
cannot close C4B-03 claims.

## Unknowns and required evidence

- No container identifier, provisioning, Dashboard schema, quota, push, account transition, or
  multi-device convergence is claimed verified in C4B-01.
- Local-at-rest protection/lifecycle for engine state, outbox, staging, encoded system fields, and
  audit still needs C4B-02 threat-model review; CloudKit payload encryption is selected above. None may be an
  exported ledger or uploaded attachment data.
- Owner must accept the proposed `iCloud.com.xdgf558.MindBudget` identifier and the exact opt-in
  disclosure naming financial records plus notes/reflections. Cloud-wide Delete All is required for
  COM-C4B completion; Dashboard roles and test Apple IDs remain C4B-03 operational evidence inputs.
