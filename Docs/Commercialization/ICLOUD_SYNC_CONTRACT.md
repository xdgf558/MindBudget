# Free iCloud Sync Contract

## Status

Status: **C4B-01 Done after owner acceptance, independent review, green GitHub Actions run
`32434148439`, and PR #57 merge `90a1e66`.**

This is the Accepted design contract, not authorization by itself to create a CloudKit container,
add an entitlement, ship a request, migrate SwiftData, deploy a schema, or change local-only
behavior. C4B-02 remains blocked until C4B-02P is reviewed and merged and the owner explicitly
starts runtime implementation.

## Scope and authority

MindBudget remains local-first. Sync is Free for every entitlement state, default off, and begins
only after explicit user choice. Missing account, disabled iCloud, offline state, quota, malformed
remote data, CloudKit failure, or unresolved conflict never prevents local create/read/edit/export/
Delete All.

The accepted architecture is **custom versioned records in one custom zone of the signed-in person's CloudKit
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
| Cloud database | Private database only; accepted zone `MindBudget.Sync.v1` and record type `MindBudgetEnvelopeV1`; never public/shared database |
| Record identity | Canonical lower-case UUID business ID; record name `<type>/<uuid>` except recurring claim `<type>/<occurrenceKey>`, where the only accepted occurrence key is lower-case UUID + `:` + signed base-10 calendar year + `-` + two-digit month; `/`, `%`, controls, and caller strings are rejected |
| Envelope | Closed `schemaVersion`, `type`, `id`, per-record-lineage `revision`, `isDeleted`, `modifiedAt`, and typed encrypted payload carrying parent/semantic digests; genesis is revision 1 with absent parent digest; unknown data fails closed without mutating local facts |
| Ordering | Server-owned CKRecord system fields/change tag plus encrypted parent/semantic digest detect replay or descent; revision 1 has no parent and every later revision names the last accepted semantic digest; wall clock and device identity never choose a divergent financial winner |
| Deletion | Logical tombstone has the same record name and participates in ordering; retain until C4B-03 proves compaction safety |
| Environment | One accepted exact future container identifier `iCloud.com.xdgf558.MindBudget`, not created here; entitlement-selected Development/Production environments and same-named private custom zone remain strictly separate |
| Encryption | Typed ledger/note/reflection payload and semantic digest are one encrypted `Data` field in `CKRecord.encryptedValues`; only non-content routing metadata is unencrypted and no content field is indexed |
| Attachments | Receipt images, OCR text/geometry, local intermediates, recovery artifacts, logs, StoreKit data, notification state, and config cache never enter CloudKit |
| Managed SwiftData sync | Every production `ModelConfiguration` across `MindBudget/**/*.swift` must explicitly use `cloudKitDatabase: .none`, and `ModelContainer` construction remains centralized in `DataController`, before any CloudKit entitlement/import |
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

Each allow-listed object has deterministic record name from type and canonical UUID in
`MindBudget.Sync.v1` using record type `MindBudgetEnvelopeV1`. The recurring
claim instead derives from its stable `occurrenceKey`, not random `occurrence.id`. The only
accepted occurrence-key serializer is the existing `DataActor` format: canonical lower-case UUID,
`:`, the persisted calendar's signed base-10 year, `-`, and a two-digit month from `01` through
`12`. C4B-02 must share one parser/formatter, require a full ASCII match, and reject `/`, `%`, NUL,
controls, noncanonical UUID case, out-of-range month, and arbitrary caller-supplied strings before
constructing a record name. Typed payloads
preserve `Int64` minor units plus ISO currency. Every local authoring transaction writes its local
fact plus durable pending envelope/tombstone in one `ModelContext` transaction before background
send. C4B-02 may add those sync metadata models in Schema V6; a save without its outbox is invalid.
Local sync metadata stores encoded CKRecord system fields, including the server-owned change tag,
for conditional save. Replays are idempotent by record name, accepted parent digest, per-record
lineage revision, and encrypted semantic digest; engine serialization may be a rebuildable sidecar
because the durable outbox, not engine state, is the source for unsent work.

An envelope records a per-record-lineage revision plus encrypted parent and semantic digests.
The first accepted envelope is exactly revision 1 with no encoded parent digest and a required
semantic digest. Revision 0, revision 1 with a parent, or revision greater than 1 without the exact
last accepted semantic digest is malformed and quarantined without local mutation. A
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

The accepted future identifier is `iCloud.com.xdgf558.MindBudget`, but it has not been created,
provisioned, or deployed.
One CloudKit container has strictly separate Development and Production environments selected by
the provisioning entitlement, and each environment uses the same-named private custom zone. Apple
documents the entitlement-selected environment and that deployment copies a tested Development
schema to Production without copying records. C4B-01 adds neither entitlement nor schema.
Sources: [CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer) and
[Deploying an iCloud Container’s Schema](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema).
C4B-02 runtime implementation starts only after C4B-02P is reviewed/merged and
the owner gives explicit implementation instruction. Team/roles and account matrix remain
operational inputs. Neutral
quota wording must say local data and edits remain safe and sync resumes after iCloud space/account
availability; it must not promise a time or amount.

## C4B-02 prerequisite decisions

- The exact container identifier is `iCloud.com.xdgf558.MindBudget`; Development and Production
  are entitlement-selected environments of that one container and never exchange records.
- The first envelope is revision 1 with absent parent digest. Every later revision must name the
  last accepted semantic digest; no zero digest or generated placeholder is a valid parent.
- A conflict quarantine is durable status, not entitlement or financial authority. C4B-02 stores
  both candidates, keeps the last valid local fact visible, pauses only that record, and exposes no
  automatic winner. C4B-03 owns the user resolution surface: keep local by authoring a new
  descendant against the accepted server base, accept the verified cloud candidate, or explicitly
  keep/delete when one candidate is a tombstone. It never duplicates an accounting fact to make a
  conflict disappear.
- The opt-in title is `Sync with iCloud` / `使用 iCloud 同步`. The accepted disclosure is:
  `When enabled, MindBudget stores your financial records, budgets, savings goals, wishlist and
  cooling-off plans, notes, and reflections in your private iCloud database and syncs them across
  devices signed in to the same Apple Account. Receipt images, OCR data, reminder history,
  diagnostics, and local recovery files are not uploaded. Sync is off by default, and local use
  continues when iCloud is unavailable. Turning sync off keeps local data and does not delete the
  iCloud copy; deleting cloud data is a separate confirmed action.` /
  `开启后，MindBudget 会将你的收支记录、预算、储蓄目标、愿望清单与冷静期计划、备注和复盘内容存入你的私人
  iCloud 数据库，并在登录同一 Apple 账户的设备间同步。收据图片、OCR 数据、提醒历史、诊断信息和本地恢复文件不会上传。
  同步默认关闭；iCloud 不可用时仍可在本机使用。关闭同步会保留本地数据，也不会删除 iCloud 副本；删除云端数据是另一个需确认的操作。`
- Before any CloudKit import, entitlement, or engine initialization, every production
  `ModelConfiguration` across `MindBudget/**/*.swift` explicitly uses
  `cloudKitDatabase: .none`, and `ModelContainer` construction remains centralized in
  `DataController`. The structural checker must fail clearly for missing/alternate owners and for
  explicit `.automatic`/private managed-mirroring selection.

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
- The owner accepted the exact identifier, disclosure scope/copy, genesis rule, and quarantine
  responsibility split above. Cloud-wide Delete All is required for COM-C4B completion; Dashboard
  roles and test Apple IDs remain C4B-03 operational evidence inputs.
