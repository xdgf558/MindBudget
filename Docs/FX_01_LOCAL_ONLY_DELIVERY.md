# FX-01D local-only delivery candidate

Status: **IMPLEMENTATION_CANDIDATE_PENDING_COMPLETE_VALIDATION_AND_REVIEW**.

Owner approved the ledger-level FX / ordinary-iCloud exclusion on 2026-09-22, following the
physical-probe deferral. This is one implementation batch, not a new physical preparation round.
D remains In Progress; its original four cloud obligations are not marked complete. E and
Insights income/share remain unentered. No device, account query, CloudKit write/delete, install,
uninstall, claim/reservation reset, distribution or merge is authorized by this delivery.

## Product and data boundary

- New FX and ordinary-to-FX conversion require Pro and explicitly disabled ordinary sync.
  An offline or paused but still opted-in ledger is not equivalent to user-disabled sync.
- Existing FX remains locally readable, editable, deletable and CSV-exportable after Pro expires.
  Int64 accounting authority, canonical rates, banker's rounding, dates and exported columns stay
  unchanged. The entry form preserves rejected input and explains the required setting change.
- Existing FX or durable companion history prevents enable/recovery. A legacy opted-in store
  pauses transport without silently revoking its opt-in. Queues, accepted ancestry, encoded system
  fields, engine state, original amounts and saved accounting amounts are retained.
- A separate snapshot flag exposes FX exclusion alongside an existing account/key/zone pause.
  Settings explains both without offering an ineffective rebuild. No-FX ordinary sync retains
  its default-off/Free policy and normal operation.
- Explicitly confirmed cloud erasure remains separate and does not block local recording.
  Its exception cannot apply ordinary remote data, replay tombstones into the local ledger or
  resolve financial conflicts. This code does not itself initiate erasure.

`Docs/FX_01_CONTRACT.json` and `Commercialization/ICLOUD_SYNC_CONTRACT.md` describe the exact
machine-readable and transport contracts. The actor is the final authority; stale UI, foreground
retry, startup, queued delivery, native record providers and callbacks cannot bypass its decision.
The local-only admission check includes malformed/tombstoned companion footprints, not just
currently visible expense details. An account-change disable cannot purge the only surviving FX
copy in transport state.

Ordinary record providers must not repeatedly decode the entire queue. Every admission checks
local FX metadata with a one-row existence query; retained transport uses an actor-owned
unknown/absent/present cache. Its cold scan preserves raw type/name/envelope checks, companion
ingress/projection latches presence before application, and rollback or complete transport erasure
invalidates it. Canonical ordinary writes and acknowledgements do not introduce FX and preserve
known absence. This relies on the existing single production DataActor writer; arbitrary external
ModelContext transport mutations are not an enabled app path. Legacy local metadata is not cached.
Large ordinary-provider regressions count scans/decodes deterministically, not via a new time limit.

## Retained protocol, limited evidence

The thirteenth encrypted companion and frozen `.expense` format remain as protocol implementation.
Old pair/lineage tests explicitly enable a DEBUG-only, all-in-memory fixture. Release has no such
opt-in, no production caller may enable it, and real transport—including cloud deletion—rejects
fixture authority. Synthetic success is not permission to ship FX cloud delivery.

A legacy remote parent arriving before its companion is indistinguishable from an ordinary expense
under the frozen format. The test `legacyParentFirstArrivalRemainsAnExplicitCompatibilityLimit`
records this limitation: later companion arrival pauses and retains bytes without deleting or
revaluing the already accepted local parent. Same-batch/known-companion financial application is
blocked before changes. This is not a claim to have solved mixed-version or real-cloud lifecycle
compatibility; those obligations remain deferred rather than passed.

## Development checks and retained non-passes

### PR #130 review repair (after `92e78d4`)

The independent review found stale disabled-sync Settings policy and a corrupt-outbox/whole-zone
deletion recovery gap. Its narrow isolated programs are not native iOS/SwiftData/CloudKit runs.
The repair adds a settings-entry snapshot-only route and persists whole-zone control intent without
decoding/restaging queues. See the same-date decision and amended current iCloud contract.
Neither change permits ordinary FX transport or initiates a live privacy operation.

| Native simulator check | Evidence and limit |
| --- | --- |
| Before deletion correction | Four methods ran, NON_PASS: empty and `not-json` outboxes blocked the delete adapter and durable intent. The Settings history control also failed because the test seeded external history after an actor had cached absence. Snapshot-only no-start/no-resume passed. |
| First corrected focused run | 104 methods / three suites, NON_PASS: both corrupt-deletion paths passed; the history fixture still reused the singleton from `makeDataActor()`, and one older whole-zone test still expected restaged tombstones. Both test assumptions were corrected; no product cache bypass was added. |
| Corrected fixture and expectations | 104 methods / three suites PASS. Real SwiftData SQLite reopen preserves the deletion intent, accepted account, corrupt bytes/revisions/conflict state and local FX tuple through network failure and wrong-account denial; an explicit adapter double then supplies zone-absent completion and only transport is cleared. No CKContainer/CKSyncEngine/account query or real deletion runs in these tests. |
| Settings route | Real actor + service + AppSession tests execute disabled startup → local last-FX delete → the same method used by the Settings `.task`, without foreground activation/notification. Clear history restores Enable; retained history still blocks. Both remain disabled with zero adapters. Source gates bind the actual view hook; this is not a separately executed SwiftUI end-to-end case. |
| Prior frozen head | `92e78d4` complete-local/native evidence remains in the PR evidence channel. Hosted `35738900173` attempt 1 finished ordinary `106783167156`, FX `106783166955`, join `106803996525` successfully. This repair did not re-audit those hosted bundles and does not reuse them as its acceptance. |
| Repair freeze | Complete default local, own-head hosted/native and independent re-review are pending. Preserve every earlier NON_PASS and the unchanged 500 ms/zero-retry/isolated-FX requirements. |

Four added local-only native bindings raise that group from 25 to 29 (85 total FX unit bindings);
the isolated FX UI inventory remains three methods. The new source/negative gate prevents Settings
from using a transport-start route or deletion preparation from clearing/decoding/restaging history.

### Earlier implementation development (retained)

Development evidence is local Xcode 27 beta 6 / iOS 26.5 simulator evidence, not hosted Xcode 26.6
or phone evidence. Work products are kept outside source discovery while building, then archived
under ignored `TestResults/` so evidence survives temporary-folder cleanup. Native result bundles
and simulator provenance must be retained for complete validation; a text count alone is insufficient.

| Check | Result and interpretation |
| --- | --- |
| Initial sandbox build | CoreSimulator was unavailable to the sandbox; destination resolution failed before tests. The authorized simulator build outside that sandbox passed. Neither is runtime acceptance. |
| Focused 1 | Build failed on a missing `try` in the new conflict guard; corrected explicitly. No test ran. |
| Focused 2 | 121 Swift Testing methods in six selected suites passed; this was before the last review fixes, not final acceptance. |
| Focused 3 | NON_PASS: a new unit test constructed `CKContainer` without a signing entitlement and the process exited before deletion admission. 122 other methods later passed; the overall failed run remains failed. No account/zone operation occurred. |
| Corrective test design | Native deletion begins with a deterministic fixture-admission function. Its unit test checks that function with real actor fixture state without constructing a live SDK object; a source/negative gate pins its position and body. |
| Focused 4 | 123 methods in six selected suites passed after the review/test corrections. This does not replace default complete validation or the compile-isolated FX UI host. |
| Candidate `272e3c8` complete-local attempt | Author stopped the run during ordinary UI after independent review identified repeated full-queue decode complexity. Exit 75; NOT complete PASS. Static gates, Debug/Release compilation and the one-shot 167.774375 ms / 500 ms benchmark had passed; ordinary/FX acceptance was not completed. The following cache correction requires its own candidate validation. |
| Focused 5 / cache correction | 125 methods in six selected suites passed, including the 256-record provider sequence and rollback/whole-clear invalidation. Targeted source-gate self-test rejected 169 negative mutations; 81 unit bindings and the original three isolated UI bindings remain required. These are development checks, not complete-local or hosted acceptance. |
| Final candidate | Full default local validation, isolated FX/native verification, exact-head hosted jobs and independent review remain pending at source freeze. No earlier run substitutes for them. |

Cross-file review during implementation caught account-pause disable data loss, deletion-state
remote-apply bypass, damaged outbox type recognition, stale disable status, fixture deletion
authority and missing dual-pause explanation. Those findings drove code and regression additions;
the collaborators' implementation checks are not a substitute for final independent acceptance.

Original #118 failures `34097606992`, `34108994597`, `34218693463`, `34250759552`, earlier benchmark
non-passes and unproven platform causes remain historical non-passes. This candidate does not
explain, relabel or rerun them to select a green result. The 500 ms benchmark, zero-retry policy,
ordinary suite, isolated FX host, and applicable review/hosted/native gates remain in force.
