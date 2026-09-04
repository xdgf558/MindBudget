# Free iCloud Sync Contract

## Status

Status: **COM-C4B and C4B-01 through C4B-03 are Done. Reviewed final head `f1f37db` passed GitHub
Actions run `32726507493`, PR #64 merged it as `4f6d7fe`, and DEC-COM-043 closes the evidence scope
without recording any waived physical observation as passed or authorizing Production/release.**

This is the Accepted design and implementation contract. PR #58 merged the prerequisites as
`6f5fded`; reviewed C4B-02 head `0024507` passed GitHub Actions run `32490174014`, and PR #59 merged
it as `211dff2`. PR #60 (`7138a9c`) closed the documentation gate. Reviewed C4B-03 product head
`f49de94` passed GitHub Actions run `32571676058`, and PR #61 merged the exact entitlement and
operational surfaces as `0f749ce`. Reviewed waiver head `7b23490` passed run `32576885537`, and PR
#63 merged it as `1a14df9`. Reviewed final correction head `f1f37db` passed run `32726507493`, and
PR #64 merged it as `4f6d7fe`. Neither the merged source nor a locally signed build authorizes
Production schema deployment or distribution by itself; those proofs remain COM-C6/COM-C12 gates.

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
| Envelope | Closed `schemaVersion`, canonical `recordName`, `entityType`, `operation` (`upsert` or `tombstone`), per-record-lineage `revision`, informational `modifiedAt`, `parentSemanticDigest`, `semanticDigest`, and encrypted typed payload; genesis is revision 1 with absent parent digest; unknown data fails closed without mutating local facts |
| Ordering | Server-owned CKRecord system fields/change tag plus encrypted parent/semantic digest detect replay or descent; revision 1 has no parent and every later revision names the last accepted semantic digest; wall clock and device identity never choose a divergent financial winner |
| Deletion | Normal sync retains same-name logical tombstones indefinitely; separately confirmed cloud-wide deletion records local tombstone intent and then uses whole-zone absence as the final privacy postcondition |
| Environment | One provisioned container `iCloud.com.xdgf558.MindBudget`; Debug selects Development and development push, Release selects Production and production push, and the same-named private custom zone remains environment-isolated; Production has no deployed app schema yet |
| Background delivery | The app source plist contains exactly `UIBackgroundModes = [remote-notification]`; Debug and Release both reference it while their separate entitlement files retain Development/Production isolation; an opted-in production `CKSyncEngine` keeps `automaticallySync = true` with the fixed private-database subscription ID, while explicit foreground retry remains available |
| Encryption | Typed ledger/note/reflection payload and semantic digest are one encrypted `Data` field in `CKRecord.encryptedValues`; only non-content routing metadata is unencrypted and no content field is indexed |
| Attachments | Receipt images, OCR text/geometry, local intermediates, recovery artifacts, logs, StoreKit data, notification state, and config cache never enter CloudKit |
| Managed SwiftData sync | Every production `ModelConfiguration` across `MindBudget/**/*.swift` and every local test-store configuration across `MindBudgetTests/**/*.swift` must explicitly use `cloudKitDatabase: .none`; production `ModelContainer` construction remains centralized in `DataController`, before any CloudKit entitlement/import |
| Disable/delete | Disable cancels transfer and retains local facts; remote deletion is separately confirmed and never silently implied |

## Why this architecture

### FX-01B local-store foundation (not a sync protocol expansion)

Schema V7 adds a local `ExpenseForeignCurrencyMetadata` companion while retaining all V6 sync
models and the existing twelve-type wire allow-list. `.expense` payload keys, semantic digest
and envelope version are unchanged. Before FX-01D supplies the separately reviewed thirteenth
companion protocol, FX writes reject ordinary enabled iCloud, and enabling or recovering/reuploading
iCloud rejects stored FX rows. Cloud erasure's enabled flag authorizes deletion only: ordinary and
FX local recording remain available during erasure without staging parent-only upserts.
Legacy parent-only upserts also reject this coexistence; parent tombstones delete companions.
This interim isolation adds no UI or network activation. FX-01D must update this contract and
the exact thirteen-type inventory together before removing these protections.

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
`BudgetPlanSemantics`, and V5 adds `MerchantAccountingContext`. Schema V6 adds five local sync
metadata models: `CloudSyncControl`, `CloudSyncRecordMetadata`, `CloudSyncOutboxItem`,
`CloudSyncInboxItem`, and `CloudSyncEngineState`. They are transport/control state, never a
business or financial authority. The V6 `ModelCounts` inventory covered **16** business tables
(not 15): the prior C4A 15-table audit predates the V5 companion. FX-01B's Schema V7 adds
`ExpenseForeignCurrencyMetadata`, bringing the local business/companion count to **17**, but
does not add it to the twelve-type sync allow-list. UUIDs below are current
unique business IDs; `BudgetPlanSemantics.planID` and `MerchantAccountingContext.merchantID` are
stable companion keys.

| V6 business owner | Identity / relationship | C4B treatment |
|---|---|---|
| Expense | `id`; scalar recurrence/merchant provenance | Sync authoritative envelope |
| Income | `id` | Sync authoritative envelope |
| IncomeAllocation | `id`, unique `incomeID`, optional `budgetPlanID` | Sync; missing parent queues, never guesses |
| SavingsGoal | `id` | Sync authoritative envelope |
| RecurringFixedExpenseRule | `id`, unique `originExpenseID` | Sync authoritative envelope |
| RecurringExpenseOccurrence | `id`, unique `occurrenceKey`, rule/expense IDs | Sync control-plane envelope to prevent duplicate cross-device generation |
| BudgetPlan | `id`; cascades category budgets | Sync authoritative envelope; child carries `planID` |
| BudgetPlanSemantics | unique `planID` | Sync companion envelope |
| CategoryBudget | `id`, required `planID` in every upsert envelope; SwiftData relationship stays optional only for persistence/migration mechanics | Sync; key absence is malformed, while an identified parent that has not arrived stays pending |
| WishItem | `id`; cascades cooling-off plans | Sync authoritative envelope |
| CoolingOffPlan | `id`, required `wishItemID` in every upsert envelope; SwiftData relationship stays optional only for persistence/migration mechanics | Sync excluding local notification identifier; key absence is malformed, while an identified parent that has not arrived stays pending |
| ReflectionLog | `id`, scalar provenance IDs | Sync authoritative envelope |
| SpendingInsight | `id`, unique dedupe key, derived payload | Local-only/recompute |
| ReminderEvent | `id`, throttle/notification history | Local-only/device-specific |
| Merchant | `id`, unique normalized name, aggregate cache | Local-only/rebuild |
| MerchantAccountingContext | unique `merchantID` | Local-only/rebuild |

No receipt/OCR/image/attachment/temp-file model exists in V6. Future C4C artifacts are permanently
excluded. Recovery backup/journal/manifest and signed public-config cache are local security or
recovery artifacts, never envelopes.

## Envelope, mutation, and conflict rules

Each allow-listed object has deterministic record name from type and canonical UUID in
`MindBudget.Sync.v1` using record type `MindBudgetEnvelopeV1`. The recurring
claim instead derives from its stable `occurrenceKey`, not random `occurrence.id`. The only
accepted occurrence-key serializer is the shared `RecurringOccurrenceKey` format: canonical lower-case UUID,
`:`, the persisted calendar's signed base-10 year, `-`, and a two-digit month from `01` through
`12`. C4B-02 must share one parser/formatter, require a full ASCII match, and reject `/`, `%`, NUL,
controls, noncanonical UUID case, out-of-range month, and arbitrary caller-supplied strings before
constructing a record name. The C4B-02 implementation uses the same parser for existing recurrence
generation and record-name validation. Typed payloads
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
Interactive keep-local/use-iCloud resolution is available only when both candidate envelopes decode,
name the same lineage, and the CloudKit candidate includes reusable encoded system fields. A
content-free server conflict, malformed envelope, or physical deletion remains quarantined with no
destructive in-app shortcut; it cannot replace or delete the last valid local fact.
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

An externally deleted or purged private custom zone is destructive remote state, not an empty
server. C4B-02 enters a separate sticky pause and generic disable/re-enable cannot recreate the zone
or repopulate it from the local ledger. The same rule applies when CloudKit reports
`zoneNotFound`: the `CKErrorUserDidResetEncryptedDataKey` flag selects the encrypted-key-reset pause,
and an otherwise missing accepted zone selects the remote-zone-loss pause. Once any account,
encrypted-key-reset, or remote-zone-loss pause is stored, ordinary success/network/quota/service
callbacks cannot overwrite it. C4B-03 owns the explicit recovery or cloud-delete choice; neither
condition may auto-purge or reupload.

The current Delete All action is explicitly local-only: it stops the adapter, removes local facts
and local sync metadata, and does not write cloud tombstones or delete the private zone. Existing
iCloud copies can therefore be imported if sync is enabled again. Settings and both confirmation
steps disclose that boundary. C4B-03 must offer an explicit distinction between local delete,
required cloud-wide delete, and disable while retaining cloud copy. Cloud-wide delete first records
durable local tombstone intent and reports pending completion while offline, but it does not need to
upload every tombstone before deletion: confirmed absence of the entire accepted custom zone is the
final privacy postcondition. Local deletion remains available even if cloud deletion cannot start.
Re-enable after local-only deletion needs confirmation before import, and the retained-copy marker
must remain visible in the same app session rather than waiting for a later scene refresh.

## Environment and deployment boundary

The current C4B-03 source uses the provisioned container `iCloud.com.xdgf558.MindBudget`. Debug
selects the Development CloudKit environment plus development push through
`MindBudgetDebug.entitlements`; Release selects Production plus production push through
`MindBudgetRelease.entitlements`. Both configurations use the checked source plist whose only
background mode is `remote-notification`. An opted-in runtime keeps Apple's `CKSyncEngine`
automatic scheduling enabled so its private-database subscription and silent notification can
schedule remote fetches; explicit start, scene-activation, and Retry passes remain bounded manual
entry points rather than substitutes for background delivery. Automatic scheduling never creates
an adapter before consent, reopens a sticky trust-boundary pause, changes local authority, or
bypasses inbox/quarantine rules. The environments never exchange records, the primary SwiftData
store remains explicitly `.none`, and no public/shared database is permitted. Read-only
Dashboard inspection confirmed the accepted encrypted record shape in Development and no app
record type or deployed schema in Production. Production deployment and distribution remain
separate owner gates.

Historically, C4B-01 added neither entitlement nor schema, and C4B-02 kept the exact identifier as
an unprovisioned source constant. Those phase-scoped facts are retained as entry history, not as a
description of the current C4B-03 branch. Apple documents the entitlement-selected environment and
that deployment copies a tested Development schema to Production without copying records.
Sources: [CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer) and
[Deploying an iCloud Container’s Schema](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema).
C4B-02P passed independent review and merged through PR #58 as `6f5fded`; the owner then explicitly
started C4B-02. At that phase's close, no iCloud entitlement, Dashboard container/schema, or
verified request had been added. Team/roles and account matrix then became C4B-03 operational
inputs. Neutral
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
  `开启后，花有数会将你的收支记录、预算、储蓄目标、愿望清单与冷静期计划、备注和复盘内容存入你的私人
  iCloud 数据库，并在登录同一 Apple 账户的设备间同步。收据图片、OCR 数据、提醒历史、诊断信息和本地恢复文件不会上传。
  同步默认关闭；iCloud 不可用时仍可在本机使用。关闭同步会保留本地数据，也不会删除 iCloud 副本；删除云端数据是另一个需确认的操作。`
- Before any CloudKit import, entitlement, or engine initialization, every production
  `ModelConfiguration` across `MindBudget/**/*.swift` explicitly uses
  `cloudKitDatabase: .none`, and `ModelContainer` construction remains centralized in
  `DataController`. The structural checker tokenizes real Swift code while excluding comments and
  normal/raw single-line or multiline string literal text (but retaining interpolation code). It
  applies Swift's delimiter-specific raw-string escape rules, recognizes direct and selective
  CloudKit imports, and manages every real production `.init(...)` through a path/call-shape/count
  allowance so contextual type inference cannot move construction across files. Unapplied
  initializer function values are separately path/receiver/count-bound. SwiftUI may attach only the
  already-created `environment.dataController.container` through the one reviewed unlabeled
  `.modelContainer(...)` call in `MindBudgetApp`; every `modelContainer(for:)`, additional call, or
  method reference is rejected for both View and Scene syntax. The checker must fail clearly for
  missing/alternate owners, aliases, unapproved initializer calls/references, metatype `.self`
  escapes, nested-code `.none` lookalikes, missing top-level per-call `.none`, and explicit
  `.automatic`/private managed-mirroring selection. Ordinary `ModelContainer` parameter/reference
  types outside `DataController` remain valid; only construction is centralized.

## C4B-02 and C4B-03 handoff

C4B-02 owns explicit `.none` primary-store hardening before entitlement, private-zone
`CKSyncEngine` adapter, envelopes/outbox/staging, local status UI, and diagnostics. It must prove
opt-out, no account, offline, quota, duplicate delivery, account change, and attachment exclusion.
C4B-03 owns physical-device lifecycle, Dashboard evidence, conflict/tombstone/delete retention,
Development/Production isolation, disclosure, and release approval. Deterministic multi-device
lineage/conflict/no-winner behavior remains required. DEC-COM-039, DEC-COM-042, and DEC-COM-043
permanently waive only their named physical observations and never convert them into passes.
Deterministic failure isolation remains required, and Production/distribution proof remains owned
by COM-C6/COM-C12.

C4B-03 local validation includes 33 deterministic sync cases, a 45-test migration/free-
tier regression after entitlement hardening, generated-plist verification for
`remote-notification`, an accepted isolated strict Dashboard benchmark, and an exact-head full run
with 460 unit results, 17/17 UI tests, and the selected coverage gate. The exact-head full run
explicitly skipped the wall-clock benchmark after loaded-host non-passes rather than claiming a new
strict result. A separately owner-authorized compile-time opt-in test adds one real
physical Development private-database lifecycle case: zone create, encrypted record send/fetch,
disable, confirmed reimport, whole-zone delete, and local-fact preservation. That single-device
case is joined by read-only Dashboard evidence that Development contains only the accepted
encrypted envelope field and Production contains no app record type. DEC-COM-043 permanently
waives the physical offline/quota/account observations as non-passes; deterministic coverage
continues to prove their local-first and fail-closed behavior.

Evidence-closure audit found that the merged adapter had explicitly disabled
`CKSyncEngine.Configuration.automaticallySync`, which made its checked background mode and push
entitlement insufficient for real background delivery. DEC-COM-040 corrects production scheduling
to `true` and pins the assignment in the static contract. The focused simulator regression at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused1.xcresult` passed all 38 selected results: 35
deterministic passes and three explicit physical-only skips. This proves the source/configuration
boundary and regression safety; it is not physical background-push evidence.

The corrected configuration also passed 38/38 selected results on an iPhone Air in the Development
environment at `/private/tmp/MindBudget-C4B03-AutomaticSync-Physical2.xcresult`: 36 passes, the two
permanently waived multi-device roles explicitly skipped, and zero failures. The real lifecycle
repeated zone create/send/fetch/disable/confirmed-reimport/whole-zone-delete with local-fact
preservation, and runtime diagnostics showed background-task registration. No independent remote
mutation arrived while the app was backgrounded, so the result does not close silent-push evidence.

The assisted background-delivery probe produced nine inspected result packages from
`MindBudget-C4B03-BackgroundPush6.xcresult` through
`MindBudget-C4B03-BackgroundPush14.xcresult`. None observed an independent Development mutation
arrive while the app remained backgrounded; the evidence count is zero passes. DEC-COM-041 keeps
delegate cancellation outside the serialized callback task, clears only the matching engine, and
allows fixed-zone creation only when no accepted serialization exists. The final focused simulator
run passed 37 tests with four physical-only skips at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused6.xcresult`. DEC-COM-042 permanently waives only
the physical background/silent-push observation from exit evidence, preserves all nine bundles as
non-pass evidence, and leaves the opt-in harness available only as a diagnostic.

The optional two-device harness requires both physical devices to address the same iCloud private
database. The prepared devices were otherwise signed and ready, but irreversible one-way account
fingerprints differed, so their private databases could not exchange the fixed test record. The
owner stopped the attempt without switching accounts. The test is therefore an explicit evidence
gap, not a pass or a product failure. A final 33/33 cleanup run confirms only that the fixed
Development zone is empty after the interrupted attempt. An ordinary simulator run then passed 36
results—33 deterministic passes and three physical-only skips—at
`/private/tmp/MindBudget-C4B03-PostMultiDefault.xcresult`, proving the harness stays opt-in.
DEC-COM-038 initially deferred a same-account rerun. DEC-COM-039 now permanently removes that
physical run from the C4B-03/COM-C4B exit evidence. The waiver does not convert the stopped attempt
into a pass, remove deterministic conflict/no-winner requirements, authorize Production/release,
or waive any other physical evidence item.

## Unknowns and required evidence

- At the C4B-02 handoff, the exact container identifier was present only as an unprovisioned source
  constant; that phase claimed no container, entitlement, Dashboard schema, quota, push, physical
  account transition, request, or multi-device convergence. The current C4B-03 authority is the
  environment boundary above.
- Schema V6 keeps engine state, outbox, inbox, control, and encoded system fields in the same local
  protected store as explicit non-authoritative metadata. Applied inbox content is removed after
  accepted lineage metadata is committed; unresolved/quarantined content remains local for C4B-03
  visibility. None is an exported ledger or attachment channel.
- The owner accepted the exact identifier, disclosure scope/copy, genesis rule, and quarantine
  responsibility split above. Cloud-wide Delete All is required for COM-C4B completion; Dashboard
  roles and test Apple IDs remain C4B-03 operational evidence inputs. Physical same-account
  multi-device evidence is permanently waived under DEC-COM-039 and is not recorded as passed.
- Automatic scheduling remains a required production configuration under DEC-COM-040. The
  physical Development silent-push observation is permanently waived under DEC-COM-042 and is
  explicitly not passed; simulator/static assertions prove only the implementation boundary.
- Physical account-switch/offline/quota observations are permanently waived under DEC-COM-043 and
  explicitly not passed. Their deterministic local-first, sticky-pause, closed-reason, and retry
  coverage remains mandatory.
- Distribution signing and owner-authorized Production schema/deployment/release evidence are not
  waived. DEC-COM-043 assigns them to COM-C6/COM-C12, where they remain mandatory before the
  relevant distribution or formal-release exit.
