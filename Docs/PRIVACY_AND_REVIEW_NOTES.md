# PRIVACY_AND_REVIEW_NOTES

This file is the living source for App Store privacy answers and review notes.
Statements about future features must be revalidated against the shipped binary.

## Data handling

- Collected data: none. V1 financial records remain in the app's local container.
- Data leaving the device automatically or to the developer: none. A user may explicitly
  share an expense/income CSV to a destination they choose. Optional Foundation Models enhancement
  runs on device.
- Tracking: none.
- Third-party sharing: none.
- Accounts: none in V1.
- CloudKit: disabled in V1.
- Third-party SDKs: none.
- Data protection: deliberately rely on the Core Data persistent-store default,
  `NSFileProtectionCompleteUntilFirstUserAuthentication`, which applies to stores
  created by current iOS applications. This includes the SQLite store managed by
  SwiftData; verify the effective class on a release-signed device before shipping.

## Data purpose

Local expense, income, budget, wishlist, cooling-off, and reflection data exists only to
provide the budgeting features initiated by the user. It is not used for ads,
profiling, cross-app tracking, resale, or third-party analytics.

## Export and deletion

V1 exports the user's expense and income ledger as a UTF-8-with-BOM CSV only after the user opens
Export CSV and invokes the system share sheet. It includes exact amount/currency fields,
dates, categories, and the user's optional source/merchant names and raw notes; the
screen discloses those fields before sharing. Formula-like user text is neutralized and
CSV punctuation/newlines are escaped. The export is transferred from memory, so the app
does not retain a second CSV file in its container. It is a ledger export, not a
full internal-database backup.

Delete All is implemented with a confirmation dialog followed by a localized confirmation
word. It performs these steps in order: cancel app notifications, delete and await all
app-owned Spotlight index removal, delete all current SwiftData model types, reset app
preferences while leaving system language untouched, and return to onboarding. Progress
names the current stage. After deletion, the app re-queries every current model count and resets
preferences only when every count is zero. The flow stops and names the failed stage if any
operation or verification fails; a partial failure is never reported as complete deletion.

The unreleased C4B-03 source keeps Delete All explicitly local-only. It stops sync and clears local
facts plus local sync metadata while retaining a device marker that an iCloud copy may exist. A
later Enable requires a separate reimport confirmation. The marker is republished immediately
after local deletion in the same app session, so Settings cannot hide the retained copy or silently
send an unconfirmed enable request. Settings also provides an independent,
destructive “Delete data from iCloud” action: after confirmation it deletes the whole app-owned
private custom zone, preserves local facts, remains durably pending through interruption, and
clears the marker only after CloudKit confirms deletion. It records durable local tombstone intent
before the request, but whole-zone absence is the final postcondition; it does not first upload
every tombstone. Pending deletion names a closed account/network/quota/failure reason and remains
safe to retry without reuploading local facts. Normal sync uses logical tombstones rather than
physically deleting individual records. Conflict review exposes only the fact type and keep/delete
operation, never the amount, merchant, note, reflection, or other record content. Resolution is
offered only for two complete verified candidates; an incomplete candidate stays quarantined.

These statements describe unreleased product capability merged through PR #61 (`0f749ce`) after
reviewed head `f49de94` passed GitHub Actions run `32571676058`, plus deterministic local tests. The
exact Development and Production entitlement files exist, Development provisioning accepted the
exact container, one owner-authorized physical Development lifecycle passed, and read-only
Dashboard inspection confirmed the encrypted Development record shape plus absence of a Production
app schema. DEC-COM-039 permanently waives only the physical same-account two-device evidence item;
the stopped different-account attempt is not a convergence pass, and deterministic conflict/
no-winner behavior remains required. Physical account/quota/offline/background-push evidence, a
distribution-signed binary, Production schema deployment, and release authorization are not
claimed. DEC-COM-042/043 permanently waive the named physical background/account/offline/quota
observations as non-passes; deterministic protections remain required. Reviewed final head
`f1f37db` passed run `32726507493`, and PR #64 merged it as `4f6d7fe`. C4B-03/COM-C4B are Done and
C4C is unblocked, while Distribution and Production/release evidence remain COM-C6/COM-C12 gates.

Future commercialization channels are not part of the currently uploaded 0.9.8 claim. Before the
optional Free iCloud, first-party telemetry, or consented cloud-AI channel can ship, its owning COM phase
must add current bilingual disclosure, App Privacy answers, channel-specific revoke/delete
behavior, and signed release evidence. No forward-looking permission changes the current binary's
local-only data handling.

C5-04 now contains one production construction of the fixed first-party telemetry client/adapter,
but collection remains missing-state default-off and requires explicit bilingual confirmation in
Privacy settings before creating an identity, file, or request. The exhaustive capture inventory is
limited to three reviewed production files and closed product-interaction events. Its vocabulary
cannot represent ledger values, merchant/note/category text, receipt image/OCR/model evidence,
StoreKit identifiers, CloudKit envelopes, locale, device details, or arbitrary strings. Telemetry
failure never changes entitlement, budgets, receipt handling, or local app use.
C5-01 pseudonym separation applies to ordinary upload envelopes: opt-out/re-enable cannot reuse or
group the prior pseudonym there. A future complete-delete request intentionally groups the bounded
retained proof set; C5-02 processes that association only to delete and does not persist, log, or
reuse a request-unique group. Independent tombstones retain only a coarse UTC-day expiry bucket
shared across deletion requests; that broad expiry day is disclosed and is not described as full
cross-request unlinkability. Corrupt encrypted state remains locally deletable together with its key, with a distinct
result that does not claim remote deletion when authenticated proofs cannot be recovered. Reading
or repeatedly disabling never-enabled telemetry creates no file, Keychain key, identity, or write.
C5-02 must make event acceptance and proof deletion idempotent because a remote success can precede
a failed local acknowledgement or cleanup.
Exact final head `d937dc8` passed GitHub Actions run `33085630481`, and PR #76 merged C5-01 as
`68304ad`. That reviewed merge closes only the dormant local client. The owner then entered C5-02.
Its implementation establishes a strict content-free first-party receiver, real 90 x 24-hour UTC
TTL and proof deletion, repeated bounded cleanup, a fixed `MindBudget` user agent with no language
metadata, and a bounded fixed adapter. C5-04 constructs that adapter only through the reviewed sole
factory after the customer enables collection. Only Development has an earlier deployment/probe;
Staging is undeployed and Production has no provisioned D1 resource. The reviewed C5-04 source adds
the explicit control/disclosure, capture audit, conservative App Privacy manifest entries, sticky
endpoint-policy failure, and an operations runbook. Independent review approved the deletion-order
remediation on exact head `2c1cebe` within its declared scope; it did not inspect the privacy
manifest, two feature capture files, `TelemetryService`, or the operations runbook. GitHub Actions
run `33233846430` passed, and PR #82 merged the source as `28d9eae`. Independent review of PR #83
head `daea2d2` raised two P2 findings and one P3 and retained that exclusion. Remediation head
`e6bbd3f` applied them and recorded the implementation author's supplemental inspection of the
four excluded surfaces; it passed green run `33242024609` and merged as `becb020` without a
pre-merge rereview.
Current source `becb020` is deployed only to Development as version
`003c66fa-a57c-4b6a-a8d7-3f75b14cc716`; its content-free synthetic TTL/delete/idempotency probe
passed and retained no new row. PR #84 then used the actual iOS Simulator
`FixedTelemetryTransport`/`URLSession` path against the strict Development Worker: upload returned
202, delete returned 204, and aggregate D1 inspection found 0 events, 0 identities, and 3
tombstones (2 historical plus the expected new UTC-day deletion tombstone). This proves the
adapter's fixed User-Agent and absent/empty language metadata were accepted on the wire, but it is
not final-binary traffic. Final-binary traffic, App Store Connect privacy answers, and
release authorization remain outstanding.

Independent review approved exact C5-02 remediation head `72abf4b`, GitHub Actions run
`33176551566` passed, and PR #78 merged it as `4715054`. DEC-COM-062 closes only the dormant
receiver/adapter package: collection, capture, customer telemetry egress, and App Privacy answers
remain unchanged. The owner entered C5-03 on 2026-08-29. Independent review approved head
`4ea7cd9`; remediation head `0c61427` closed its P2/P3 findings, passed GitHub Actions run
`33211270363`, and PR #80 merged it as `a587f42` without a pre-merge rereview. PR #81's post-merge
closeout review confirmed that exact delta. DEC-COM-065 closes only dormant aggregate evidence
computation: no route, real evidence result, or G1 decision exists. The owner entered C5-04 on
2026-08-29. Its product capability is merged through PR #82 (`28d9eae`) after green run
`33233846430` on exact remediation head `2c1cebe`; the independent review covered the
deletion-order remediation but excluded the manifest, capture sites, service, and runbook now
named for PR #83 supplemental inspection. That author-side inspection and merge are now recorded through `becb020`,
and the separately authorized current-source Development probe passed on version
`003c66fa-a57c-4b6a-a8d7-3f75b14cc716`. Independent review approved exact PR #84 head `84a96bc`,
hosted run `33247176815` passed, and PR #84 merged as `4194b73`; C5-04 and COM-C5 are Done. The
owner explicitly entered COM-C6 on 2026-08-29. Independent rereview approved exact PR #86
remediation head `f77d2a6`, hosted run `33255898196` passed, and PR #86 merged as `015d00e`;
C6-01 is Done. The owner explicitly entered C6-02 on 2026-08-30. Independent review accepted exact
PR #88 head `0ac0500`, hosted run `33283398690` passed, and PR #88 merged as `6c2a051`; C6-02
remains In Progress for required-reason source-gate and manual evidence. PR #89 review found
missing Foundation Swift overlay aliases in that source gate. Independent rereview accepted exact
remediation head `6ffc6fa`, hosted run `33287620965` passed, and PR #89 merged it as `72f016e`.
C6-02's bounded evidence packet received independent final review on exact PR #93 head `016dd33`
with no P1/P2 findings; hosted run `33405016652` passed and PR #93 merged as `c940e8e`.
DEC-COM-088 marks C6-02 Done without turning its accepted physical non-passes into successes. The
owner explicitly entered C6-03 on 2026-09-01 under DEC-COM-089 and
`C6_03_RELEASE_BASELINE.md`, authorizing a reviewed/green/merged `0.9.8 (10)` Archive and TestFlight
transport upload only. This does not authorize copying App Privacy answers into App
Store Connect, tester assignment, service/schema deployment, G1, App Store submission,
distribution, or public release; those gates remain open.
Final review retained two non-blocking C6-03/C12 harness notes: the back-button helper identifies
`buttons.element(boundBy: 0)` and proves App-window geometry rather than navigation-container
geometry, and the budget Save helper moves the Form only upward.

Before any App Store Connect privacy answer is copied or accepted, C6-02 must independently
inspect `MindBudget/Resources/PrivacyInfo.xcprivacy`, the capture calls in
`MindBudget/Features/AddExpense/AddExpenseView.swift` and
`MindBudget/Features/Commerce/ProSubscriptionView.swift`, the `TelemetryService` wiring in
`MindBudget/Services/TelemetryClient.swift`, and
`Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md`. The implementation author's C5
supplemental inspection is retained as provenance but does not satisfy this independent gate;
C6-01 automation also does not satisfy it.

For App Privacy, the checked manifest declares Product Interaction, the rotating pseudonym as a
conservative Device ID, and Purchase History because the closed subscription event includes a
purchase outcome. All three are used only for Analytics, linked to no user identity, and not used
for tracking. No product, price, transaction, storefront, or subscription date is transmitted.
This source declaration does not update App Store Connect by itself. The rotating UUID is not an
account, hardware, advertising, StoreKit, or CloudKit identifier. A complete authenticated
delete deliberately groups the bounded retained generations in request-local memory so the first-
party service can delete them; that association is not claimed to be unlinkable. Disable clears
unsent events and stops capture. App-wide Delete All first requests deletion for every recoverable
remote proof, but an optional telemetry network/endpoint failure cannot block the authoritative
local financial erase. The app reports that remote-only remainder separately and keeps any
authenticated proof for an explicit Privacy-settings retry. Corrupt local telemetry remains
locally deletable without a false remote-deletion claim.

C6-02's first five-surface pass found the Purchase History omission and added a fail-closed
manifest validator with negative tests. The same validator passed against the manifest embedded in
a development-signed Release app installed and launched on an iPhone Air with iOS 26.6.1. This is
independently reviewed source and signed-device preflight, not an App Store Connect update,
distribution signature, exported IPA, final-binary traffic result, or release claim. The exact
review and manual boundaries are recorded in `Commercialization/C6_02_PREFLIGHT.md`.

Independent review accepted exact PR #88 head `0ac0500`, hosted run `33283398690` passed, and PR
#88 merged as `6c2a051`. The review's one non-blocking privacy P2 correctly distinguished a pinned
UserDefaults declaration from a source-derived required-reason inventory. The follow-up
`Scripts/check_required_reason_apis.py` scans production App sources against Apple's five current
categories, requires exact equality with the manifest, and fails closed on ambiguous file-metadata
APIs. Its Swift-overlay remediation passed independent rereview and merged through PR #89
(`72f016e`). It does not replace the C6-03 distribution privacy report or compiled-dependency
inspection.

The continuing physical C6-02 pass observed live bilingual StoreKit renewal/legal presentation,
offline retention of a previously verified local-Pro snapshot, truthful privacy/analytics/
receipt/iCloud/export copy, and receipt cancellation without a ledger write. It did not execute a
new purchase/restore, expose unrelated private photos, create an exported file, or inspect a
distribution binary. Physical AX5 testing also found that uncapped custom-tab labels obscured page
content. DEC-COM-078 caps only that persistent navigation chrome while leaving page content at the
user's full Dynamic Type size. DEC-COM-079 replaces the ignored noncanonical simulator launch
value with canonical AX1/AX5 values and proves a dynamic content element grows while chrome remains
bounded. DEC-COM-081 then binds Pro navigation chrome to the selected skin after manual capture
review found a first-push back-indicator contrast defect that a green hierarchy result missed.
Independent review accepted exact PR #91 head `b3ed24d` with no P1/P2 findings, hosted run
`33362101536` passed, and PR #91 merged the bounded remediation as `4ddabcd` under DEC-COM-082.
Automated geometry is not visual-contrast proof; the inspected captures own that evidence.
DEC-COM-083 makes `C6_02_ACCEPTANCE_MATRIX.json` require 23 exact runtime bindings and explicitly
distinguishes deterministic results from unperformed physical work. Existing C4C-05 receipt and
PR #91 accessibility evidence is
accepted without a redundant device rerun. Complete VoiceOver, Instruments/exact data-protection
class, and physical notification/Siri/Spotlight/Face ID/share/Delete All side effects remain
non-passes for C6-03/C12. A read-only container listing found containermanagerd protection metadata
for the SwiftData artifacts on only `拉沙的iPhone`; no financial data was copied. `xctrace`
listed the same phone Offline and produced no trace, so no Instruments pass is claimed.

Delete All also resets setup state and returns to onboarding. A retained telemetry-deletion proof
remains valid, but the person must complete setup again before Privacy & Security > Product
Analytics becomes reachable. Stopping the telemetry service does not invalidate that retry:
`TelemetryService.stop()` cancels lifecycle tasks only, while the same service and persisted client
continue to expose the explicit delete operation.

C3-03B now implements one anonymous fixed-host configuration GET carrying only bounded app/config
versions. It sends no app/user/device/advertising identifier, cookie, authentication, locale,
storefront, StoreKit fact, or financial/content field. The independent MindBudget Worker stores no
request data, has no database or analytics binding, calls no outbound service, disables Worker
observability, and serves only a pre-signed seven-day envelope with `no-store`. The app logs only a
closed non-content reason code and never logs request/response bytes or metadata values. Even
without an identifier or content, ordinary HTTPS exposes connection metadata such as an IP
address to Cloudflare's first-party edge. The tested workers.dev surface also injects ordinary
edge response metadata such as `Report-To`/`NEL`; native `URLSession` does not execute browser NEL
reporting, but provider-level metadata remains part of final review disclosure.

Only Development was deployed and exercised in C3-03B. Staging and Production remain undeployed,
and the exact adapter remains behind the final binary/traffic/App Privacy release gates. This
unreleased source does not change the privacy statement for the currently uploaded 0.9.6 binary.

## Commerce and subscription review disclosure

The voluntary MindBudget Pro screen uses Apple StoreKit for localized products, price/period,
introductory-offer eligibility, purchase confirmation, Restore Purchases, Manage Subscription,
and verified subscription state. MindBudget receives no payment-card details. No budget, expense,
income, wishlist, note, merchant, or stable app/user/device identifier enters the StoreKit catalog
or purchase request.

Billing grace retains Pro. Billing retry, expiry, and revocation remove Pro while preserving the
person's local records and every Free capability. These exceptional verified states appear as one
non-blocking bilingual Dashboard card and an explanatory Pro-screen section with explicit Manage
Subscription and Recheck actions; they never trigger an automatic modal paywall. An unavailable
or unverified StoreKit authority is not described as Free and cannot enable purchase or a signed-
configuration value trigger.

Product presentation may partition a cache under an `Unknown` environment so it can safely show
non-authoritative StoreKit metadata while the app identity is temporarily unavailable. Paid access
and purchase preflight never accept `Unknown`: they require independently verified AppTransaction
bundle/environment authority. Prices and trial eligibility are display-only StoreKit facts, never
entitlement authority. The exact seven-day offer and USD values in the local test fixture are not
customer terms.

Unreadable or orphaned cooling-off records are isolated from valid reminder reconciliation and
are never deleted automatically. Settings shows the exact affected count and offers a separate
destructive repair action with explicit confirmation. At commit time the actor revalidates every
previously identified record, deleting only rows that are still unreadable and preserving any row
that became valid. A later notification-operation failure does not resurrect a stale data-warning
state; it remains visible as the independent notification error.

## AI disclosure

AI enhancement is implemented and off by default. When enabled on a supported device,
language, region, and runtime, it receives only redacted aggregate facts and runs through
Apple's on-device Foundation Models. If it is disabled or unavailable, the same feature
returns a complete local template answer.
Raw notes, transaction rows, merchant lists, and raw Ask questions never enter
the model context. Ask facts cross the redactor only through a closed per-intent typed payload;
there is no generic fact dictionary or caller-provided template body. Deterministic Swift code
computes all financial conclusions.
`FeatureFlags.enableFoundationModels` is a product-scope gate, not proof of an
implementation or the user's preference; the user setting defaults to off and remains
mandatory through a centralized availability gate. Generated wording is validated and is
not persisted as a conversation or profile.

## Siri and Spotlight disclosure

Siri integration and Spotlight indexing are off by default and independently
controlled by the user. Settings must explain what is indexed. Disabling indexing
or deleting data removes the app-owned index. Exact amounts, notes, and merchant
names are excluded by default from display representations and index content.
The corresponding FeatureFlags only permit planned product capabilities and never
bypass centralized availability checks or the independent default-off user settings.
Local merchant aggregates include all expenses and remain private inside SwiftData;
they do not imply indexing consent. A merchant name is eligible for Spotlight only
after the global merchant-name opt-in and at least one matching expense's explicit
`allowMerchantIndexing` value are both true.

Phase 8A implements that disclosure with one app-owned Spotlight domain. Expense search
content uses a category and budget-relative amount band, never an exact amount; raw expense
and wishlist notes are not accepted by the index builder. Wishlist item names may appear
because the user explicitly created them as searchable app data. Merchant names remain
excluded until both consent layers are true. Turning Spotlight off awaits domain deletion;
an indexing failure is shown as an integration error and never changes local financial data.
Siri queries and writes similarly fail closed until the independent Siri setting and every
capability gate are available. Siri strings are sanitized and truncated, candidate names
used for impact previews are not stored, and five-second duplicate execution protection
prevents one spoken/shortcut action from creating repeated expenses. Passive system output
continues to exclude exact amounts. When the user explicitly invokes the authenticated budget-
impact intent, its result may speak the exact deterministic flexible-budget value; Settings
discloses this in a separate scalable paragraph because authentication does not guarantee a
private listening environment. Spotlight and merchant-indexing privacy remain in their own
paragraph.

Phase 9 associates those same redacted documents with amount-free `IndexedEntity` values only
on iOS 26; it does not create another index or widen the indexed fields. Onscreen awareness is
also off with Siri by default and publishes only an app-owned entity identifier through an
`NSUserActivity`; those activities are not separately searchable, predictable, or eligible for
Handoff. Dashboard, expense detail, and wishlist detail are the supported single-subject
screens. List pages fail closed without an explicit selected row. The installed Xcode 26.6 /
iOS 26.5 SDK has no public notification entity-annotation property, so cooling-off
notifications retain their existing amount-free content and app-local `userInfo` navigation;
no private runtime workaround is used. Ask still derives every model fact from SwiftData and
deterministic engines, never from Spotlight text.

Disabling the onscreen gate passes a nil SwiftUI activity element, which stops advertising the
activity instead of relying on removal of a conditional modifier. The three single-subject
entities satisfy the public `Transferable` contract with an identity-only JSON reference:
version, entity kind, and stable identifier. That representation cannot contain a wishlist
name, date, category, amount band, exact amount, or note. `NSUserActivityTypes` is not declared
because these activities explicitly prohibit Handoff and are not continuation inputs; verify
same-device Siri resolution on a signed iOS 26 device before release. Emotion-tag index/entity
documents remain a fixed app vocabulary and carry no user selection, count, or transaction.

## Emotion-tag review explanation

Chinese: 情绪标签只是用户主动选择的消费背景记录，用于回顾自己的消费情境；
MindBudget 不提供心理测评、评分、诊断或治疗建议，也不会据此给用户贴标签。

English: Emotion tags are optional, user-selected context for reviewing spending.
MindBudget does not assess, score, diagnose, or treat mental-health conditions and
does not label a person based on those tags.

## Permission timing

- Notifications are requested only after the user creates a cooling-off reminder
  or explicitly enables reminders, never on first launch.
- Background reconciliation reads authorization without prompting. Denial preserves the
  local cooling-off countdown and presents a System Settings link instead of retrying the
  permission dialog.
- Cooling-off lock-screen content contains the user-entered wishlist item name and neutral
  review copy, but never its amount or notes. Quiet hours defer rather than discard it.
- The original V1 baseline had no receipt, photo, or document import and requested no photo-library
  access. The later C4C-05 local Pro path uses one-image PHPicker without broad-library permission.
- C4C-01 adds only local integer rule evidence and closed future receipt capability tiers. The
  sample/confidence line is computed from local counts, and `enableReceiptImport` remains false;
  there is still no receipt image, OCR, temporary receipt file, prompt, cloud field, or egress.
- C4C-02 adds a dormant, centrally gated system-image adapter while the customer entry remains
  disabled. PHPicker uses one-image selection and does not request broad Photo Library access.
  Camera permission can be requested only after a future explicit camera-source action. Source
  bytes are never written; one bounded prepared JPEG may exist in a completely protected,
  non-backed-up temporary directory and is removed on startup, cancellation, a true background
  transition, memory warning, Delete All, or teardown. C4C-05 later supersedes the inactive rule:
  inactive scenes mask the receipt UI but preserve in-progress work. C4C-02 does not expose OCR
  results or persist receipt content.
- C4C-03 adds dormant local Vision OCR infrastructure without enabling the receipt entry. Raw
  recognized text is confined to one adapter and cannot be returned as a model-safe value. Before
  any line may leave the privacy pipeline, the app removes card-number shapes, labelled/masked
  last-four shapes, and labelled authorization codes and replaces each sensitive span with a
  non-content marker. Invalid geometry/confidence, filter failure, or count/byte overflow rejects
  the document. No receipt text is logged, persisted, synced, sent to a model, or sent over a
  network; structured extraction and confirmation remain later phases.
- C4C-04 adds dormant structured extraction without enabling receipt entry. Deterministic parsing
  always runs first. The optional Foundation Models adapter runs on device and receives only the
  already-filtered `ReceiptOCRDocument`; its exact-snippet output is untrusted until deterministic
  provenance and field validation pass. Missing/uncertain values never become zero, model failure
  falls back to deterministic output, and line items remain default-off. No receipt field is shown,
  persisted, synced, logged, or sent over a network; confirmation/evaluation remains C4C-05.
- C4C-05 enables the entry only for verified Pro access inside the existing new-expense form.
  Camera permission follows an explicit camera choice; PHPicker remains one-image and requests no
  broad library permission. One bounded protected prepared JPEG exists only while local Vision,
  privacy filtering, and deterministic extraction run; it is deleted before review appears.
  Source/prepared images, raw or filtered OCR, model snippets, and duplicate evidence are never
  persisted, synced, logged, telemetered, or sent over a network. Applying accepted merchant/date/
  total values only edits fields that were not user-edited during that recognition generation;
  changing a value back does not surrender user ownership. Typed failures retain truthful
  reason-specific guidance. Inactive scenes cover the receipt UI without discarding the photo or
  recognition, while a real background transition cancels and removes only the matching artifact.
  Nothing is stored until the owner reviews those fields and taps the form's existing Save action.
  Physical acquisition/OCR and cancel-versus-Save evidence passed on iOS 26.6.1. Independent
  review approved remediation head `8607356` and raised three nonblocking P3 observations. Final
  maintenance head `81cd107` applied them, Actions run `33035427257` passed, and PR #74 merged it as
  `d751ff4` without pre-merge rereview; PR #75's closeout review later accepted that exact delta.
  The pipeline is still not public-release authority: COM-C5 requires explicit owner entry, while
  Production/final-binary privacy, distribution, tester, and App Store gates remain later work.
- Siri and Spotlight integration require explicit opt-in.
- The optional app lock is off by default. It checks Face ID availability before enabling, asks
  the owner to authenticate before either enabling or disabling, and locks on launch and
  foreground return. Authentication is performed entirely by `LocalAuthentication`; MindBudget
  receives only success/failure and never receives or stores face data. Device passcode remains
  the recovery path so a biometric enrollment change cannot permanently trap the owner outside
  local records. While locked, an opaque app-owned surface covers financial content, including
  the app-switcher transition.

## Privacy manifest baseline

`PrivacyInfo.xcprivacy` declares no tracking or tracking domains. Its first-party optional
telemetry declarations are Product Interaction, a conservative rotating Device ID, and Purchase
History, all unlinked, non-tracking, and Analytics-only; the manifest also declares UserDefaults
reason `CA92.1`. Add File Timestamp reasons only if a shipped implementation actually uses the
covered API.

## Current local planning data

The in-app language selection is a local UserDefaults preference and does not change device
language or contact a translation service. Budget-plan-semantics markers, income allocation, the
total savings goal, recurring fixed-expense rules, and generated occurrence identities are local
SwiftData records. Recurring rule notes remain behind the actor/detail boundary and are never
notification, Spotlight, Siri entity, or model context. App lifecycle reconciliation uses no
background server and makes no claim that an entry will be created while the app is not running.

CSV remains an explicit user export and now includes the exact income portions allocated to the
current spending budget and savings as minor-unit columns. Delete All removes and verifies the
budget-plan-semantics, allocation, savings-goal, recurring-rule, and occurrence tables before
reporting completion.
