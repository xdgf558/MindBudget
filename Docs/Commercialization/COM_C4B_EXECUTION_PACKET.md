# COM-C4B Execution Packet — Free iCloud Sync

## Status

Status: **In Progress — PR #61 merged the reviewed C4B-03 product capability; operational and
release evidence remains open, with physical same-account two-device and physical background-push
observations permanently waived but not passed.**

C4B-01 is Done after owner acceptance, independent review, green GitHub Actions run
`32434148439`, and PR #57 merge `90a1e66`. C4B-02P is Done after independent review, green
GitHub Actions run `32454490080`, and PR #58 merge `6f5fded`. C4B-02 is Done after reviewed head
`0024507` passed GitHub Actions run `32490174014` and PR #59 merged as `211dff2`. Reviewed closeout
head `b9944cd` passed GitHub Actions run `32494429474`; PR #60 merged it as `7138a9c`. The owner
then formally entered C4B-03. Reviewed product head `f49de94` passed GitHub Actions run
`32571676058`, and PR #61 merged it as `0f749ce`. That closes product review/CI/merge, not the
phase's remaining physical and release evidence. Reviewed calibration head `0350415` later passed
run `32573992659`, and PR #62 merged it as `0128682`. DEC-COM-039 then permanently waived only the
physical same-account two-device evidence item. Reviewed waiver head `7b23490` passed run
`32576885537`, and PR #63 merged that exact scope decision as `1a14df9`.

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

Status: **Done after independent review, GitHub Actions run `32490174014`, and PR #59 merge
`211dff2`.**

Schema V6 adds five app-owned sync metadata models without changing financial authority. Every
primary `ModelConfiguration` is explicitly `.none`. The implementation stages local fact and
outbox/tombstone in one `ModelContext` transaction, puts fetched records in a durable inbox before
topological `DataActor` application, and exposes only closed local-first status/retry controls.
The C4B-02 adapter used only the accepted private database/custom zone/record type and one encrypted
envelope field; that source phase claimed no entitlement or deployed container.

Independent-review remediation makes all three trust-boundary pauses sticky against delayed
status/account callbacks, maps both database-deletion events and `zoneNotFound` CKErrors to the
correct encrypted-reset or remote-zone-loss pause, and cancels the engine before any zone can be
recreated. The recurrence engine now uses the shared closed occurrence formatter; over-allocation
and divergent occurrence claims quarantine instead of waiting or overwriting. Category-budget and
cooling-off upsert envelopes require their parent identity, while a named parent that has not yet
arrived remains pending. The existing Delete All action is explicitly local-only and its bilingual
UI warns that retained iCloud copies may be imported after a future re-enable; C4B-03 still owns
cloud-wide deletion and confirmed reimport.

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

- The original focused deterministic `CloudSyncTests` suite passed 20/20 on an iOS 26.4 simulator with
  Xcode 26.6 (`17F113`) at
  `/private/tmp/MindBudget-C4B02-CloudSync-Final.xcresult`.
- The independent-review remediation expanded the same suite to 25/25 passing tests at
  `/private/tmp/MindBudget-C4B02-ReviewFix2.xcresult`. The added cases prove that a
  `zoneNotFound` CKError is a sticky encrypted-reset or accepted-zone-loss pause, late transport
  and account callbacks cannot reopen any sticky pause, recurrence generation uses the canonical
  key formatter, invalid over-allocation quarantines, divergent recurring claims preserve the
  accepted expense identity, and parent-owned envelopes reject a missing parent key.
- Tests cover default-off adapter construction, account/retry/failure mapping, V5-to-V6 migration,
  canonical recurrence identity and bytes, all 12 allow-listed fact types, permanent local-only
  cache exclusion, duplicate/replay, logical and cascade tombstones, topology, malformed/physical
  deletion, lineage ordering, resurrection rejection, account re-consent, encrypted-key reset,
  server-save conflict quarantine, and a sticky no-reupload pause after remote zone deletion/purge.
- Static verification enforces the exact 12-type allow-list, runtime anchors, private database,
  no physical `deleteRecord`, no public/shared database, no `CKAsset`, no iCloud entitlement in
  the C4B-02 source phase, repository-wide `.none`, and centralized container construction.
- Reviewed remediation head `0024507` passed every step of GitHub Actions run `32490174014`; PR #59
  merged the accepted C4B-02 source to `main` as `211dff2` on 2026-08-21. C4B-03 evidence cannot
  be inferred from simulator fakes, hosted CI, or this source-only adapter.

## C4B-03 — Lifecycle and deletion

Status: **In Progress after reviewed product merge PR #61 (`0f749ce`); evidence closure pending.**

The merged product capability owns explicit keep-local/use-iCloud conflict resolution without exposing
record content, durable whole-zone cloud deletion while preserving local facts, retained-copy
reimport confirmation, and explicit sticky trust recovery. Debug selects Development while Release
selects Production for the exact container; both use the checked source-plist
`remote-notification` background mode. DEC-COM-040 additionally requires the opted-in production
engine to keep Apple's automatic scheduling enabled; explicit foreground retry remains separate.
Deterministic local tests and signed configuration evidence
are supplemented by one owner-authorized physical Development private-database lifecycle pass.
Read-only Dashboard inspection confirms the Development encrypted-envelope shape and that
Production has no app record type or deployed schema. Physical account/quota/offline evidence,
distribution signing, Production deployment, and Production-release claims remain open. A signed
two-device harness was prepared, but the connected devices use
different iCloud Apple Accounts and therefore different private databases. The owner stopped that
attempt rather than changing accounts. DEC-COM-039 permanently waives a same-account physical rerun
as an exit-evidence item. The stopped attempt is still not a pass or product-failure finding, and
the waiver does not weaken deterministic multi-device conflict/no-winner behavior.
DEC-COM-042 likewise permanently waives only the physical background/silent-push observation after
nine inspected probe bundles produced zero delivery passes. Those attempts remain non-pass evidence;
automatic scheduling, the fixed subscription, checked capabilities, and deterministic transport
boundaries remain required.
Local Delete All now republishes the retained-copy marker immediately in the same app session, so
Settings continues to show cloud deletion and requires the reimport disclosure before Enable can
start transport. Cloud-wide deletion stages durable local tombstone intent, then treats whole-zone
absence as the final privacy boundary without first uploading each tombstone. An incomplete cloud
conflict candidate remains visible but has no unsafe resolution action.

## Tests

C4B-01 ran documentation and static-boundary checks only. C4B-02 adds deterministic envelope,
outbox, conflict, malformed-record, local-failure-isolation, account, and full allow-list tests
without enabling Development.
C4B-03 first passed the 32-test focused sync suite and now passes 33 deterministic sync cases after
adding the saturated-lineage failure boundary, plus the corrected 45-test migration/free-tier
regression, generated-plist verification, an accepted earlier strict Dashboard result, and the
exact-head `Scripts/validate.sh` run (461 unit results, 17/17 UI, Release, and coverage; wall-clock
benchmark explicitly skipped after loaded-host non-passes), signed Development configuration, and
a local Release archive. The owner-authorized physical suite then passed 33/33 on a final iPhone, including
real Development zone create, private encrypted send/fetch, disable, confirmed reimport, whole-zone
delete, and local-fact preservation. Read-only Dashboard checks then confirmed the single encrypted
Development app field and the absence of the app record type in Production. It must still add
account/offline/quota evidence. The current two-device attempt was explicitly
stopped after distinct iCloud-account fingerprints proved the private databases could not
converge; the harness remains opt-in and no multi-device result is claimed. DEC-COM-039 permanently
waives that physical evidence item without weakening deterministic coverage. Independent rereview
approved head `f49de94`, GitHub Actions run `32571676058` passed, and PR #61 merged the product
capability as `0f749ce`. Reviewed calibration head `0350415` passed run `32573992659`, and PR #62
merged it as `0128682`.
Evidence-closure audit then found that the merged adapter had disabled automatic engine scheduling,
so the checked push/background capabilities alone could not satisfy the pending background-delivery
gate. The corrected configuration and static anchor passed 38 focused results (35 deterministic,
three physical-only skips) at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused1.xcresult`. This is configuration/regression
evidence only and is not a physical background-push pass.
The corrected configuration then passed the opt-in Development physical suite at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Physical2.xcresult`: 36 passes, the two permanently
waived multi-device roles skipped, and zero failures. The real lifecycle again deleted its fixed
Development zone and preserved the local fact. Background-task registration was visible, but no
independent mutation arrived while the app was backgrounded, so it is not a silent-push pass.
Subsequent assisted attempts produced nine result packages from
`MindBudget-C4B03-BackgroundPush6.xcresult` through
`MindBudget-C4B03-BackgroundPush14.xcresult`; none observed a qualifying external Development
mutation while the app remained backgrounded. DEC-COM-041 records the delegate-reentrancy and
genesis-only zone corrections exposed by those attempts, with the final 37-test simulator run green
at `/private/tmp/MindBudget-C4B03-AutomaticSync-Focused6.xcresult`. DEC-COM-042 permanently waives
only the physical observation, records zero passes, and retains the harness as optional diagnostic
evidence.
Production schema deployment is an explicit owner gate and is not inferred from a Release archive.

## Stop conditions

Stop and return to the owner if the requested solution needs managed SwiftData mirroring, implicit
enablement, a Pro gate, public/shared database, generated CloudKit identity, automatic destructive
conflict resolution, attachment/OCR transfer, or Production deployment without acceptance. C4B-02
review/CI/merge is satisfied through PR #59 (`211dff2`); no entitlement, deployed environment,
cloud-delete, or multi-device claim is valid before C4B-03 evidence.
PR #61 (`0f749ce`) satisfies product review/CI/merge only. C4B-03 remains In Progress, C4C remains
blocked, and the permanently waived same-account physical run cannot be cited as convergence
evidence. The separately waived physical background-push observation cannot be cited as a pass.
Neither waiver extends to account/offline/quota, distribution signing, Production deployment, or
release.
