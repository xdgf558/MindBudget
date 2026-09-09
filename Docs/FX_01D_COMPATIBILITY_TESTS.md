# FX-01D local compatibility supplement

Status: **In Progress — test implementation; no compatibility acceptance or D completion.**

Owner authorized local frozen-protocol and calendar/time-zone compatibility tests after the
read-only D sufficiency assessment. Base is main merge `237759fa41686ffcbe13d09ef7bfc37f9d885917`
(#118, reviewed `3edffa3` as second parent). That documentation delivery was independently
accepted after exact-head `34306711254` attempt 1 ordinary/FX/join success and reviewer-supplied
native audit. It did not complete D. The four failures in `FX_01D_CLOSEOUT.md` remain non-pass.
This supplement does not rewrite that frozen packet's historical pending status or waive its
unexecuted compatibility obligations. No E, Insights income/share, real account or release entry.

## Frozen old protocol, not a renamed current implementation

`MindBudgetTests/PreDFrozenCloudSyncDomain.swift` is the complete old domain source from
`7e9d69389d88dabb5bfcc5e77709b282801d3df0:MindBudget/Services/CloudSyncDomain.swift` (pre-D).
Its original SHA-256 is `707e153d9fd0973778e9eca722047530de4c7b915e0028e19b461ea6825b0425`.
Only three mechanical text substitutions namespace the code to avoid linking collisions:
`CloudSync` → `PreDFrozenCloudSync`, `RecurringOccurrenceKey` →
`PreDFrozenRecurringOccurrenceKey`, and `cloudSyncBits` → `preDFrozenCloudSyncBits`.
The fixture checker reverses them and requires exact original bytes; it needs neither Git
history nor network during CI. Both new Swift files compile only into MindBudgetTests.
The frozen code does not import or delegate to the current application codec. These substitutions
also namespace the old notification-name string literals; the codec tests never post them.

Five tests compare actual new-parent bytes with the frozen decoder/encoder, assert rejection
of the thirteenth type and stale-digest mutations, author old-format ordinary edits using the
old codec, retain contradictory FX parent edits through disk reopen, and check old-authored
parent tombstone/replay safety. A compatible note-only old edit must apply while keeping FX,
so the tests do not accept simply blocking every old-client update. The starting accounting payload comes from a current actor;
the old field shape is already pinned separately by the existing pre-D projection gate.

**This is codec-level interoperability plus current-actor behavior, not an old application,
old SwiftData store, old inbox loop or CKSyncEngine execution.** In particular, rejecting an
unknown type does not prove how a deployed old client's scheduler handles a mixed batch.
The contradictory old edit is expected to remain pending with the locked amount preserved;
this is safety evidence, NOT successful edit convergence. A pre-D client cannot produce the
missing companion. Any change to that disposition requires a separate explicit decision.

## Calendar and time-zone matrix

Six fixed absolute date expectations cover UTC, New York spring/fall DST, Kathmandu's offset,
Apia's skipped civil day and Sao Paulo's midnight gap. Sixteen Foundation calendar identifiers
produce 96 sender/day combinations and 1,536 sender/receiver/day start-of-day comparisons.
Each receiver comparison also rejects a one-second off-boundary instant. No constant day
duration or money floating-point arithmetic is introduced.

The second test authors all 96 tuples and imports each through the real current DataActor,
checking locked Money, full saved tuple and zero quarantine. A separately encoded, valid-digest
but off-boundary rate date must quarantine both available facts without partial import.
These actual imports use the running process's `Calendar.current`; the 16 receiver identifiers
are explicit Foundation boundary calculations, **not 16 differently configured app processes**.
No product calendar-injection hook or user-default mutation is introduced. The matrix is bounded
to its fixed dates/zones/toolchain; it does not prove every historical calendar/zone combination.

## Verification and acceptance

Seven additional exact-once unit bindings are mandatory (existing 49 retained: total 56).
The fixture gate runs in the existing FX static entry; negative mutations cover changed old
inventory, altered provenance/import, wrong target and redirected source. No runtime skip,
retry, benchmark ceiling, UI timeout, UI query helper, dependency or workflow changes.

- [x] Focused seven-method simulator tests and native result inspection.
- [ ] Existing static/self-test gates and diff checks.
- [ ] Default complete local validation, unchanged 500 ms and isolated FX host.
- [ ] Exact-head hosted ordinary + FX + join, native audits and independent review.

No test execution is accepted merely by adding a binding. Full local and hosted/native results
must be attributed to their actual tested source/head. Do not reuse #118/#121 results here.
Real CloudKit FX lifecycle, an actual old/new binary pair and receiver-device calendar settings
remain unexecuted. Live tests require a separately authorized isolated Development environment;
the existing physical lifecycle test deletes its zone and must not run against user data.
D's four original items stay unchecked until explicit final sufficiency/owner acceptance.

## Preparation observations

The first fixture self-test rejected its own incomplete isolation checker: a negative insertion
into a non-Sources build phase escaped the Sources-only scan. The checker now scans every build
phase; the same negative is rejected. This was a static test-harness defect, not a product or
runtime failure. The first FX static run then caught two current-closeout pointers displaced
below the new log/decision headings. Restored both at the document top without weakening the
pointer gate; FX, commercialization and StoreKit gates subsequently passed. The final added
note-edit binding must also pass the forthcoming default complete validator.

Focused-1 passed the original six methods; focused-2, after adding the note-only control, passed
all seven once with zero skipped/failed. Native tree/detail checks confirmed seven exact-once
bindings, without retry. These are author-local Xcode 27 beta 6 / iOS 26.5 simulator results,
not hosted Xcode 26.6 or independent review. Actual process imports do not establish all possible
receiver device calendars. The original calendar-risk hypothesis was not reproduced in this
bounded matrix; it is not renamed a fixed product bug.

Local artifacts: `/private/tmp/fx-compatibility-evidence.pUbuTI/focused-2.xcresult` and
`focused-2.log` (SHA-256 `9b3752a5ab24b53f15e7f57aaed4f6e27c63612a686d2d170cf4f5740b9d00e4`).
Test source SHA-256: `52a7943c3ac93861f821481bf8cc62f7adc1eef9e971db6708a29c4df78cb73e`;
namespaced frozen source SHA-256: `6f01cfa7259b56bbc381a0b85e6be65c8745cfb932df8c756409ba0a7e47c3f6`.
Native reads first needed sandbox escalation to write xcresult's derived TestReport cache;
that read failure was not a test failure or new execution. No full-local acceptance yet.
