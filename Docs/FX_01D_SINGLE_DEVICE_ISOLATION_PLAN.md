# FX-01D single-device CloudKit isolation proposal

Status: LIFECYCLE CANDIDATE — local preparation only; independent review/full validation and live-run watchdog pending; no installation or live evidence.

## Scope and observed constraints

The owner has one iPhone using a personal iCloud account and authorized isolation preparation.
Do not sign out, replace the everyday app, inspect its store, enable its sync or run the existing
physical probes. D stays In Progress with four unchecked items; E and Insights/share stay unentered.
The proposal now accompanies the separate local implementation branch, not a closeout or a waiver.
`Tools/FXCloudProbe/README.md` describes the new explicit-request lifecycle candidate. It must
not be represented as actual server-round-trip evidence. Ordinary launch remains inert.

Inspected source is reviewed #122 head `161d7f8`, accepted as merge `ba14647`. Existing local
post-merge receipts are preserved. Implementation must start from fetched merged main, not silently
extend the merged feature branch or discard those receipts.

Both current entitlement files permit `iCloud.com.xdgf558.MindBudget`; Debug selects Development
and Release selects Production. Both configurations use the same app Bundle ID. The runtime
also defaults to that container and the `MindBudget.Sync.v1` zone. Renaming the app, changing
only its Bundle ID, or using an in-memory store does not isolate that remote destination.

The current CloudSyncService already accepts an adapterFactory, and CKSyncEngineAdapter accepts
an explicit CKContainer. Prefer those existing injection points; do not change production defaults
or add a production environment-variable override. The current FX UI host is simulator-only and
deliberately has no sync; do not repurpose it. Existing physical CloudSyncTests use ordinary
expenses and include startup/end-of-test whole-zone deletion; they are not safe FX entry points.

## Dedicated identities — registered and development-profile verified 2026-09-09

| Boundary | Proposed isolated value / requirement |
| --- | --- |
| Dedicated host Bundle ID | `com.xdgf558.MindBudgetFXCloudProbe` — registration verified in portal |
| Dedicated CloudKit container | `iCloud.com.xdgf558.MindBudgetFXCloudProbe` — registration verified in portal |
| Environment | Development only, verified in signed entitlements and embedded profile |
| Local data | Explicit test-owned store, preferences and sync-state/retention marker; synthetic records only |
| Production container | Absent from all host/test-runner entitlements and allowed container sets |
| Entry | Dedicated opt-in debug physical test host; no Archive/distribution path; never AppEnvironment.live() |

Use the production wire format/zone name inside the separate container to minimize protocol
divergence. Container identity is the isolation boundary, not merely a different zone name.
No App Group or shared Keychain access with the everyday app. Do not instantiate commerce,
telemetry, AI, indexing, camera, notification-permission or other unrelated app lifecycles.
Any necessary CloudKit/APNs capabilities are limited to this separate test identity.

## Before any phone operation

- Obtain separate approval for the exact new App ID/container registration and provisioning.
  Do not modify the existing App ID or revoke/regenerate its profiles. Do not deploy Production schema.
- Implement the isolated host and closed preflight first. Inspect the actual signed host and
  runner, not just source plist: Bundle ID, Team ID, Development environment, explicit container,
  application identifier, Keychain groups and absence of shared groups/production access.
- Require exact configured container injection with no nil/default fallback, including helper
  account queries. Reject missing, extra, mismatched or everyday identifiers before network work.
  Test those refusals with non-network doubles; avoid even account-status queries before preflight.
- Review the isolated build, synthetic fixture vocabulary and native audit expectations. No automatic
  provisioning updates, install, launch or registration as a side effect of local preparation.
- Ask the owner to connect/unlock/trust the one selected phone only when needed, then confirm its
  supported OS and developer setup. Do not print personal account IDs, record contents or credentials.
- Before installing, disclose the exact separate app and synthetic cloud writes and request approval.
  Registration approval alone is not live-run or deletion approval.

## Minimum first live pass (candidate implemented; execution not authorized)

1. Create a bounded set of synthetic manual-rate/override FX facts through the real DataActor,
   including zero-/three-decimal currencies; retain exact original tuple and locked Int64 amount.
2. Upload parent and companion through the real CKSyncEngineAdapter to the isolated private database.
3. Stop the first service; use a second fresh test-owned local store/state to fetch from CloudKit.
   Assert both facts and the full FX tuple, not merely the seeded in-memory row or an empty outbox.
4. Verify a bounded edit and repeated fetch preserve the locked accounting amount and pairing.
   Record per-step source/build/toolchain/device/environment and native assertion outcomes.

The implementation uses the original writer store for post-edit propagation, not a third fresh
store. Inspection of CloudSyncRemoteApply's nextRevision/acceptedDigest gate shows the latter
cannot be assumed to bootstrap later revisions. Keep that compatibility/sufficiency question open;
do not seed lineage or change product conflict rules inside this test-host scope. Direct adapter
injection is not CloudSyncService/Settings/retention-marker coverage. A reviewed external hard
watchdog and evidence collector remain prerequisites; internal between-stage deadline checks
do not bound a hung CloudKit await. No live run is requested by the implementation checkbox.

Do not auto-delete the zone before or after this first pass. If unexpected preexisting records
are seen, stop without altering them. Failed or interrupted runs retain artifacts and state;
do not rerun until green or delete state to hide failure. Explicit fixture tombstone and whole-zone
deletion checks require a separate exact-target approval and a cleanup-owner plan. No claim of full
lifecycle acceptance until required deletion/recovery checks actually pass.

Only synthetic fixture hashes, IDs and outcomes belong in public evidence, not the personal account
identifier or unrelated records. Provisioning details and full device identifiers stay local unless
separately approved for publication. Using a separate container still uses the personal iCloud account
and its service/quota; it is not an anonymous account or a promise of zero operational risk.

## Evidence this cannot provide

A second fresh store on one phone demonstrates server round-trip, not simultaneous two-device
delivery. Current builds alone do not demonstrate old/new binaries. A later dedicated old host
on the same phone could provide bounded sequential evidence only after isolation/signing review;
do not label a frozen codec as that host. No system calendar change is authorized; explicit Foundation
calendar calculations remain distinct from an actually configured receiver process. These gaps stay
open to independent sufficiency review and owner decision, not silently waived or moved to E.

## Sources checked 2026-09-09

- Repository: `MindBudget/MindBudgetDebug.entitlements`, `MindBudget/MindBudgetRelease.entitlements`,
  `MindBudget.xcodeproj/project.pbxproj`, `MindBudget/Services/CloudSyncRuntime.swift`,
  `MindBudget/Data/DataController.swift`, `MindBudgetTests/CloudSyncTests.swift`,
  `MindBudget/App/FXUITestHost.swift`, `Docs/PRIVACY_AND_REVIEW_NOTES.md`.
- Apple [Enable app capabilities](https://developer.apple.com/help/account/identifiers/enable-app-capabilities/):
  iCloud containers are assigned to an App ID; changing capabilities affects associated profiles.
- Apple [CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer):
  the signed iCloud environment entitlement selects Development versus Production.

Initial preparation validation was source/document inspection and git diff --check only.
After owner-authorized setup and owner login, both new identifiers were registered in Apple
Developer and verified in their respective lists. At the registration checkpoint the dedicated
App ID showed iCloud and Push Notifications disabled, App Groups disabled; In-App Purchase is an
Apple-default disabled-to-edit checked capability, not a product/catalog creation. No existing
MindBudget identifier/container was edited. Container content was not queried, and no schema,
profile, certificate, signed build, installation or application CloudKit request was created.
Subsequently the owner explicitly confirmed the exact capability grant. Enabled iCloud with
CloudKit support, selected only `iCloud.com.xdgf558.MindBudgetFXCloudProbe`, enabled Push
Notifications and saved/confirmed the test App ID change. Reopened its configuration after
save: iCloud/CloudKit and Push Notifications enabled; App Groups, iCloud Extended Share Access
and Broadcast Capability disabled; Save disabled. Reopened container assignment: one of two
selected, new test container checked, existing `iCloud.com.xdgf558.MindBudget` unchecked.
Cancelled the read-only assignment dialog without changes. This verifies portal configuration
only: no provisioning profile, signed entitlement, Development runtime or successful sync is
proven. Phone installation, data operations and later cleanup still require separate approval.
