# Isolated FX CloudKit probe — toolchain-preflight repair, not live acceptance

## Current host-toolchain preflight repair (2026-09-11)

PR #127's reviewed same-run continuation merged as `d47e893`. Its post-merge version-3 request was
independently accepted and owner-authorized once for the selected iPhone Air. That invocation
retained a NON_PASS before any phone access because the process inherited Command Line Tools and
`/usr/bin/xcrun` could not find `devicectl`. The approved file is consumed; its new continuation
claim and result remain immutable. No process query, install, launch/resume, App execution,
CloudKit access or deletion occurred.

The controller now performs a local-only toolchain preflight before it creates a fresh marker,
continuation claim, evidence directory or `Device` adapter. The caller must set an explicit
absolute `DEVELOPER_DIR`. One five-second `/usr/bin/xcrun --find devicectl` lookup must return a
single executable at the resolved `<DEVELOPER_DIR>/usr/bin/devicectl`; missing, relative, linked,
ambiguous or foreign paths fail without consuming live authority. The same sanitized environment
is then supplied to native commands. After preflight succeeds, all existing version-3 checks and
the atomic claim-before-device order remain unchanged.

Local run-level fixtures exercise both ordering boundaries. They are not device/CloudKit evidence.
This changed controller still requires full exact-head validation, independent review and merge.
After merge, prepare a new exact version-3 file and obtain a new explicit owner authorization; no
prior file or connected-phone statement applies to the changed controller. No state reset,
cleanup, D completion or E entry is authorized here.

## Current same-run continuation (2026-09-11)

PR #126 reviewed head `f886b12` passed complete local validation, hosted `34490729945` and
native audit, then merged with owner authorization as `002e3cf`. That repair does not reclassify
run `c251f030-e1da-4de2-bde1-734097ee7123`: it remains NON_PASS before resume/App/CloudKit
execution, and its original host reservation remains immutable.

The owner authorized implementation of one continuation of that same run, not deletion, a new
UUID or a changed state root. `--prepare` with all of `--prior-approval`,
`--prior-controller-result` and `--state-root` produces a version-3 PENDING request only when:

- the old approved request binds the same package, device, run, bundle/container and non-deleting
  six-stage operation;
- the old result is exactly the pre-resume parser NON_PASS with no resume, collection or deletion;
- the retained reservation is the exact same-run `RESERVED` file; and
- the prior controller is a different valid SHA-256.

The new request binds SHA-256 for those three retained files and the prior controller. `--run`
requires the same prior inputs again. Before any device command it verifies the old reservation
without modifying it and creates one new append-only continuation claim with O_EXCL. A repeated
controller call therefore stops before phone access. Missing/changed evidence, another run UUID,
package/device drift, an already-resumed result, deletion permission or an existing continuation
claim all fail closed. Fresh version-2 runs keep the original once-only behavior.

This implementation still needs full exact-head validation, independent review and merge. After
merge, prepare a new exact request and obtain separate owner approval before live execution. No
current PENDING file, environment variable or implementation authorization permits phone launch,
CloudKit access, cleanup, D completion or E entry.

Offline working-source preparation against the retained private evidence passed with controller
SHA-256 `51b0c52729505aba3faf66471ba06521000b28fd42c3384ec5edda9e105187a9` and the unchanged
signed-package SHA-256 `617c2ae9e781bbaa6d336a686b4f2026c797e1d5dfe8307f81d23e4bad1608a4`.
The old reservation SHA remained `51e92acb4c17191fd87b2a9ece2e69e7a6088c7d944c97c8753d88921508089a`
before and after. That generated request is PENDING, expires, and is not the post-merge approval.

## Historical launch argument-order repair (2026-09-10)

#125's selector repair was independently accepted and owner-authorized merged as `93218fb`,
second parent `902875d`, after exact-head complete local and hosted/native acceptance. The owner
then separately approved a new exact signed package/controller/selected-phone bounded run. One
dedicated App installation succeeded. The unchanged controller reserved that attempt, observed
no probe process, and issued one suspended-launch command. devicectl rejected the command as
missing --device before it produced launch JSON or the controller sent resume.

Observed launch mechanism, local Xcode 27 beta 6 / selected phone iOS 26.6.1:

- `device process launch` treats the Bundle ID as positional and all following tokens as App
  command-line arguments. The controller appended common `--device`, `--timeout` and
  `--json-output` options after the Bundle ID, so they were not parsed as devicectl options.
- Run c251f030-e1da-4de2-bde1-734097ee7123 remains NON_PASS. The original result conservatively
  records processStopped=false; a separate later fixed-search process observation was empty.
  No resume/termination/collection followed, and no probe code, account/zone query, upload or
  deletion ran. The dedicated App and immutable host reservation remain; neither is reset here.
- The repair separates native option/subcommand arguments from a positional tail, places the
  unchanged device/15-second timeout/JSON-output options before the sole final Bundle ID, and
  pins the complete argv plus environment binding in an offline test. It adds no App arguments,
  fallback, retry or broader operation. It does not touch the phone.
- Launch-error log SHA-256 is
  `311ff532686c6b1185cb457107314f43f6e23f2b854dbfbe530b5c1bcc46b15c`; separate post-failure
  process JSON is `4c9da579d62d8a15f50442b414e41f0c18c6bf7b193310c50682a80496fd6611`;
  original controller result is `d6efe01192d6539e2e4b205885132c869b6ed77667cc1eae3415c0b92b280976`.
  Raw device/profile/approval data remain private.

Full new-head local validation, hosted/native evidence and independent repair review are required
before merge. The controller hash changes. The consumed reservation cannot be silently bypassed,
and this repair is not authority for a second live attempt or cleanup. D four boxes remain open;
no E/Insights entry.

## Accepted native selector context (2026-09-10)

#123 preparation was independently accepted and owner-authorized merged as `2365526`, second
parent `890fce8`. Complete local exit 0 (222.490542 ms / 500 ms) and exact-head hosted
`34424729493` attempt 1/native audit passed. The owner's first exact-package authorization stopped
before installation at native process filtering. #125 later repaired that selector and merged as
described above.

Observed mechanism, local Xcode 27 beta 6 / selected phone iOS 26.6.1:

- Original `executable CONTAINS 'MindBudgetFXCloudProbe.app/'` failed (CoreDeviceError -1):
  native `executable` is NSURL, not the string later serialized into JSON. Original private
  result SHA-256 `4c0aa231ce340263cc5ca31a4264e76975ab3e119e3acb1e953ae606158e1674`.
- Intermediate `executable.path ENDSWITH ...` passed actual Foundation/NSURL fixtures, but
  devicectl rejected the key path before evaluation (CoreDeviceError 28001). Retained private
  result SHA-256 `f3e2b304392ddd97b7beee0cfb3a08826f38a7dec7d3eb85a59b4722a375b89f`.
  Foundation predicate success alone is therefore not native CLI compatibility evidence.
- The corrected command uses the documented fixed `--search` text
  `/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe`. Returned JSON must still decode to
  unique positive PIDs and absolute paths with exactly that App/executable pair. Any unrelated,
  malformed or duplicate result rejects the whole query; it is not silently ignored.
  Search is case-insensitive/substring matching at the CLI layer, so broader matches are
  fail-closed refusals, never authority to control another process. No unfiltered list or
  alternate query is attempted on failure. Existing five-second command bound is unchanged.
- This corrected command ran once on the selected phone and returned an empty runningProcesses
  array, `outcome=success`. Private result SHA-256
  `625a362db48d736ce22cc26ceff4909b349a32b81d8e47d6fd79f9d6b560455e`.
  This proves only the empty filtered query. No app was installed/launched; no process was
  resumed/killed, no account/zone queried and no CloudKit upload/delete occurred.

`runner.py --self-test` includes a Foundation-only Objective-C executable that reproduces the
original URL exception and contrasts 15 local `.path` fixtures with the CLI's actual rejection.
Python command-boundary tests pin the fixed search and five-second bound, accept empty/one-match
fixtures, and reject 14 malformed/unrelated/error cases before launch, resume or collection,
without retry. The existing 40+ approval/receipt negatives, 11 controller paths and actual local
hung-child watchdog remain. The new `.m` fixture is not part of any app target or source inventory.

#125's validation/review and merge are complete. Nonempty native process/launch/exit JSON remains
unverified because the later authorized command failed at argument parsing before JSON output.
Resolve it only after this new controller repair is reviewed and a future attempt is separately
planned/authorized without bypassing retained state. D four boxes remain open; no E/Insights
entry. #118's four non-passes and #123's original 701 ms remain historical non-passes; no unrelated
P3 investigation or product repair is part of this change.

This is not the production app, not the simulator FX UI host and not a completed CloudKit test.
Ordinary launch remains network/store-inert. A separately authorized explicit run request can
enter the six-stage lifecycle. The transparent noninteractive window is a test harness, not a
product UI redesign. One dedicated test App installation has occurred; no probe code or CloudKit
operation has executed.

The standalone target now compiles 32 explicit unchanged production sources (models, real
DataActor/FX codec/remote apply/CKSyncEngineAdapter and their pure dependencies). It does not
compile the ordinary App entry, AppEnvironment, Settings, commerce lifecycle, telemetry, AI,
notification scheduler or AppIntents. Six support declarations required by unreachable DataActor
methods are copied exactly and compared against their production originals by source_contract.py;
they are not replacement money/sync logic. There is no dependency on the everyday app target.

Dedicated identities registered and portal readback verified by the owner-authorized workflow:

- Bundle: `com.xdgf558.MindBudgetFXCloudProbe`
- Container: `iCloud.com.xdgf558.MindBudgetFXCloudProbe`
- Team: `2AM5S7BM2N`
- CloudKit and Push Notifications enabled, only the dedicated container associated. App Groups,
  extended sharing and broadcast remain off; the everyday container is not associated.

The project uses manual signing with no default profile. It has Debug only, a compile-time opt-in,
SKIP_INSTALL, and a scheme with no launch/test/archive actions. These are accidental-use guards,
not a security claim that an operator cannot override Xcode settings or invoke targets directly.
Development must be verified from the signed artifact, not inferred from scheme names.

## Local build only

Use an explicit Xcode and a fresh absolute evidence directory. `CODE_SIGNING_ALLOWED=NO` is
only a compilation check and MUST NOT be reported as a signed-isolation pass. Set
CONFIGURATION_BUILD_DIR, SYMROOT, OBJROOT and CLANG_MODULE_CACHE_PATH inside that evidence
directory. Build target `MindBudgetFXCloudProbe` in `FXCloudProbe.xcodeproj`, Debug, `iphoneos`.
Do not use automatic provisioning updates, install/launch commands, archive/export or TestFlight.

For signed build later, select an existing Apple Development certificate for the exact team and
a newly approved narrow development profile for this Bundle ID, container and owner's selected
phone. Never edit the daily App ID/profiles or use a wildcard/daily app profile. Profile creation
and eligible device selection must be explicit; do not guess from a list of registered devices.

Run `python3 -B Tools/FXCloudProbe/audit.py --self-test` without signing or network access.
After a signed build exists, run `python3 -B Tools/FXCloudProbe/audit.py --app /absolute/Probe.app`.
It verifies the signature, embedded profile, signing-certificate membership, expiry, exact app/
team/container and signed Development environment. Extra signed capabilities, shared Keychain
groups, embedded extension targets, wildcards and the everyday container are rejected. A profile
may permit both CloudKit environments and use `icloud-services = "*"`; the actual signature
must permit Development and exactly `["CloudKit"]` only. These provider profile grants are
not copied into the app. Synthetic tests reject wildcard/additional services in the signature
and profiles that do not authorize CloudKit.
No private-key export is performed; certificate extraction is public DER only.

This audit is not Apple's full install-time trust/revocation evaluation or a check that the
owner's selected device is in the profile. A separate local metadata check on 2026-09-09 verified
exactly one provisioned device, matching the owner-selected iPhone Air. Recheck the actual
profile/device before any separately authorized installation.
It does not prove future runtime injection is correct: the network-capable host must separately
bind its CKContainer explicitly and pass preflight before constructing any cloud service.
Unsigned/missing-profile artifacts are expected to fail. Do not weaken checks to admit them.

## Prepared controller — separate live approval still required

The lifecycle uses explicit CKContainer injection into the unchanged production adapter. It does
not exercise CloudSyncService/Settings opt-in or the UserDefaults retention marker. Each test
store owns its persistent sync state. Its once-only reservation and retained files prevent an
unconfirmed second run; there is no reset switch. No default CloudKit container is constructed
by probe code and the source entitlement remains test-container-only.

Run request: exactly four MINDBUDGET_FX_PROBE_ environment keys: ACTION with the documented
OWNER_APPROVED_SYNTHETIC_ROUND_TRIP value, RUN with a canonical lower-case UUID,
EXECUTABLE_SHA256 and ARTIFACT_SHA256 with lowercase SHA-256 digests. These are
accidental-use guards, not a security credential or owner approval. Wrong bundle, simulator,
partial/extra keys, reused app installation or local evidence write failures stop execution.
The signed artifact must be externally audited and the owner must explicitly authorize its
installation/run first. Do not import or run the destructive existing physical CloudSyncTests.

Planned stages (not executed on a phone):

1. Query zone metadata in the dedicated private database; any existing non-default zone stops
   the probe, including an empty one. No record-content query or deletion in this preflight.
2. Create four synthetic USD-accounting expenses in a new explicit writer.store: JPY and KWD,
   each manual-rate and manual-home-override. Record eight envelope IDs/digests before upload;
   send through the real adapter and require ready/no quarantine/no pending records.
3. Stop that adapter; create a distinct empty reader.store with no serialized sync state, fetch
   the initial records from the server, compare all FX fields and locked Int64 Money, notes,
   category/bucket/source/date plus exact 4 expense/4 companion/zero other business-model counts.
4. Stop the reader adapter before editing; change the first synthetic note/rate-source without
   changing its locked home amount, save intended-envelope digests, then start transport once.
5. Reopen the ORIGINAL writer.store and its accepted ancestry; fetch and compare the edit.
6. Perform one planned repeated fetch there and compare again; stop and retain all evidence.

The source requires nextRevision/acceptedDigest in CloudSyncRemoteApply. Therefore step 5 is
NOT a third fresh-store bootstrap of revision > 1. That remains an explicit compatibility gap,
not a runtime finding or silently bypassed guard. The first empty-reader check covers initial
genesis only. Do not seed accepted metadata to manufacture a fresh-store pass.

The version-2 journal binds a run UUID, executable and signed-package SHA-256, completed stages, planned count and
liveDeletionTested=false. RUNNING/interrupted/missing receipts are not passes. Public console
output contains only closed outcomes; retain raw store/profile/device artifacts locally.
No delete, zone reset, automatic recovery or application-level retry loop is provided. The
unchanged CKSyncEngine still owns its normal automatic scheduling/internal transport behavior;
this is not a claim of exactly one underlying network request. The cooperative between-stage
180-second checks are now supplemented by the two independent controls described below.

Run local-only `python3 -B Tools/FXCloudProbe/audit.py --protocol-tests` for the Foundation-only
executable (no CloudKit/SwiftData source): invalid requests, wrong identity/device class, reuse,
step failures, journal failure, deadline checks and cancellation. This and signed compilation
do not execute the DataActor/CloudKit lifecycle or substitute for complete validation/review.
Installation, synthetic writes and later exact-target cleanup remain separate approvals.

### Controller and hard deadline

`runner.py --prepare --app <signed-app> --device-udid <selected-UDID> --out <new-private-file>`
is **offline only**. It repeats the signed audit, requires the profile's device list to equal
the selected UDID alone, hashes all regular package files (including embedded profile/signature),
and writes a PENDING request expiring in 24 hours. No approval is inferred or generated. The
controller's own code/audit hash is bound too. Raw request/profile/device paths must stay private.

Only after independent review AND explicit owner approval of that exact package/phone/operation,
an operator may use `runner.py --run --app <same-app> --approval <approved-private-file>
--state-root <persistent-private-reservations> --out <new-private-evidence-directory>`.
The file must record `APPROVED_FOR_THIS_ONE_RUN` and a review reference. These strings do not
authorize an agent to execute it; the human authorization boundary still applies. Installation
is separate and intentionally absent from this tool. Do not run it during preparation/review.

The controller reserves one attempt for this device/bundle, refuses an already running probe,
and launches only this bundle **suspended**. It validates a new PID and exact executable path
before resume. There is no terminate-existing, launch retry, second tap, account switch,
zone/store reset, installation or deletion command. Keep the selected phone and probe exclusive
to this controller during an approved run; do not concurrently launch it or use another debugger.
Process queries are filtered to the dedicated executable, not a phone-wide application inventory.

From resume, the host permits at most 180 seconds of active execution. Each native command has
both a native timeout and an external process-group watchdog. On uncertainty it makes one
bounded termination attempt on its owned PID/path, then verifies disappearance. It never kills
an existing or mismatched process. Unknown launch JSON cannot trigger resume. If termination
cannot be verified, status is STOP_UNCONFIRMED, never PASS. A suspended launch with missing
identity is retained as unconfirmed, not silently replaced or resumed.

The Debug app independently arms a Dispatch timer **before hashing/filesystem/CloudKit work**;
after 180 seconds its non-MainActor queue calls `_exit(124)`. Tests block the main thread in a
real local child process to prove the timer is not another between-await check. Normal complete
and failed runs exit after saving their receipt; a timeout leaves RUNNING/missing evidence.
Neither process termination nor USB disconnection can recall writes already submitted to the
server. OS scheduling is not a real-time guarantee; a disconnected/suspended device is not
accepted as stopped without external evidence. No automatic cloud cleanup follows a timeout.

After confirmed termination, collect exactly four files from the dedicated app container:
used-run.txt, receipt.json, initial-fixture.json and edited-fixture.json. Each copy has a five-
second external bound; partial failure evidence is retained, not retried. No database, account
fingerprint, unrelated app container or crash-log domain is copied. Active-execution deadline
and bounded post-stop collection/termination are separate clocks; a receipt cannot override a
timeout/native failure. Receipt and four parent/companion pairs, changed digests, exact ordered
stages and artifact/run binding are checked before a bounded PASS. Such a PASS is still not D Done.

Native devicectl **nonempty** process JSON (including the explicit terminationResult.exitCode
adapter contract) remains fixture-tested, not observed on the selected phone. The fixed-search
empty-list observation and two retained selector failures are detailed above; they do not prove
nonempty process identity or exit handling. Unknown/missing fields fail closed. The install-time full-package hash
must also match the offline signed package; installation differences are a refusal, not a reason
to weaken binding. Verify these boundaries under separately authorized preflight/live work;
local doubles and a signed build do not establish native device or CloudKit success.

Run `python3 -B Tools/FXCloudProbe/runner.py --self-test` for approval/receipt negatives, owned
process/connection/collection/deadline scenarios and a real hung local subprocess. It invokes
no devicectl, CloudKit or physical-device command. All three probe check entries are pinned in
the C6 wrapper inventory; ordinary project/scheme/config sources cannot enable the probe flag.

### Historical #123 source-freeze delivery and remaining limits

The pending validation wording in this subsection records #123 before its accepted merge above,
not the current #123 status and not preapproval of the native-selector repair.

This #123 package imports accepted #124 (`cfee88b`, reviewed c478912) unchanged and consolidates
implementation, evidence synchronization and preparation review. That optimization's local
469.826917 ms and hosted 34371706895 do not preapprove this new head. Old #123 local 701.230625 ms
exit 65 and old hosted 34357148406 remain separate results. Full new-head local (500 ms, zero
retry, ordinary plus isolated FX), hosted/native and independent review remain required.
Historical source-freeze checklists are not another requirement to publish a documentation-only
head after every run; frozen-head results belong in the existing PR body and retained artifacts.

One phone cannot demonstrate simultaneous two-peer delivery. A frozen old codec is not an old
binary; explicit calendar calculations are not an actually configured receiver. D stays In Progress,
four boxes open, E/Insights sharing unentered.

Signing reference checked 2026-09-09: Apple
[TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles).
