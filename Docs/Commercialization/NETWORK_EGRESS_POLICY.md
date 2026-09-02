# Release Network Egress Policy

## Default rule

All app-owned Release HTTP(S) egress is denied unless one exact row below is `Accepted` and the
implementing phase has passed its own consent, privacy, deletion, failure, and release gates.
Wildcards, caller-supplied URLs, arbitrary model IDs, and untyped payload dictionaries are
forbidden. Debug/test endpoints never authorize Production behavior.

The uploaded 0.9.8 (9) build has only the exact signed public-configuration row below; its failure
default is conservative and it remains structurally incapable of changing entitlement, StoreKit
terms, or permanent subscription controls. No tester assignment, external Beta review, App Store
submission, or Production configuration deployment followed transport acceptance.

## Allow-list

| Channel | Status | Environment | Domain/transport | Endpoint and method | Allowed outbound fields | Allowed inbound fields | Consent/control | Retention/deletion | Failure default | Requirement/phase |
|---|---|---|---|---|---|---|---|---|---|---|
| Current app-owned HTTP(S) | Accepted empty set | Release | None | None | None | None | Not applicable | Not applicable | Remain fully local | REQ-R1-NET-001 / current baseline |
| StoreKit lifecycle, voluntary C3-01 presentation, and C3-02 trial lifecycle | COM-C2 complete through PR #31 (`a293762`); C3-01 complete through PR #33 (`747b628`); C3-02 complete through PR #34 (`12d9217`); no distribution authorization | Xcode Configuration / Sandbox (including TestFlight) / Production kept distinct by verified StoreKit environment | Apple-managed StoreKit API and local `UNUserNotificationCenter`; no app-owned domain or raw receipt endpoint | `Product.products(for:)`, `AppTransaction.shared`, `Storefront.current`, `Transaction.currentEntitlements`, `Transaction.updates`, `Product.SubscriptionInfo.Status.updates`, `Product.SubscriptionInfo.status(for:)`, `Transaction.subscriptionStatus`, `Transaction.unfinished`, `Transaction.offer`, verified renewal `renewalDate`/`willAutoRenew`, `AppStore.canMakePayments`, explicit `Product.purchase()`, explicit `AppStore.sync()`, `Transaction.finish()` only after authoritative publish, user-initiated `manageSubscriptionsSheet`, notification-settings read, and one app-owned pending trial-reminder add/remove | Accepted Product IDs plus Apple-required app bundle, product, transaction, renewal, ownership, environment, storefront, localized display price, period, and introductory-offer eligibility only; no ledger/note/receipt content | Typed `Product`; verified app transaction/environment; verified status transaction and renewal information; verified current/update/unfinished/purchase transaction facts; transaction/status signals; pending/cancel/error; raw revocation/expiration; environment/storefront; presentation terms/eligibility; verified current trial offer, renewal date, and auto-renew state | One lifecycle authority; each whole read must match the separately verified AppTransaction bundle/environment. TestFlight is verified Sandbox. Settings/value triggers are voluntary; purchase, restore, and management each require an explicit tap; no implicit restore or automatic paywall. Trial reconciliation never requests permission; app notification preference plus system authorization controls the optional local reminder | Apple platform policy; deletable exact environment/storefront presentation cache only, never authority; cached eligibility is stripped; failed finish remains unfinished for retry; trial projection is process-local; one stable pending reminder is removed/replaced on lifecycle change and Delete All | Missing/wrong app bundle, missing/unknown/mismatched environment, product/status/catalog failure, unverified input, incomplete Free authority, and finish failure fail closed; unavailable/cached presentation cannot purchase or promise a trial. Missing/unreliable renewal date, auto-renew off, denial/disablement, or a passed T−5 window schedules no notification and retains only the appropriate in-app state; distribution remains blocked | REQ-STOREKIT-STATE-001, REQ-STOREKIT-LIFECYCLE-001 / COM-C2/C3-01/C3-02; DEC-COM-016/017/018/019/020 |
| Free iCloud sync | COM-C4B Done after reviewed head `f1f37db`, green run `32726507493`, PR #64 merge `4f6d7fe`, and DEC-COM-043; exact entitlements, one verified physical Development lifecycle, and read-only Dashboard evidence present; no distribution authorization | Debug selects Development and Release selects Production through separate exact entitlement files for `iCloud.com.xdgf558.MindBudget`; Development provisioning and one private custom-zone request passed, while Production has no deployed app schema | Apple-managed CloudKit through the centralized `CKSyncEngine` adapter and Remote Notifications entitlement; opted-in production engines keep automatic subscription/push scheduling enabled while explicit foreground retry remains available; no app-owned HTTP(S), public/shared database, per-record physical delete, `CKAsset`, or managed SwiftData mirroring | Private database only; custom zone `MindBudget.Sync.v1`, record type `MindBudgetEnvelopeV1`, one encrypted envelope field; `CKDatabase.deleteRecordZone(withID:)` is allowed only after the separate cloud-wide deletion confirmation | Exactly 12 allow-listed authoritative envelopes; typed content in `CKRecord.encryptedValues`; never receipt image/OCR/local intermediate/recovery artifact/log/StoreKit/config-cache data or the four local-only owners | Typed canonical envelope, logical tombstone, encoded system fields, opaque engine state, closed status/reason code; no raw ledger logging; conflict UI exposes type/operation only | Free default-off explicit opt-in using the accepted bilingual financial-record/notes/reflections disclosure; no adapter before consent; account switch pauses; retained cloud state requires confirmed reimport | Disable retains local and cloud data. Local Delete All keeps a durable cloud-copy marker. Separately confirmed whole-zone deletion keeps local facts and clears that marker only after CloudKit confirms deletion; interrupted deletion remains durable. Normal logical tombstones are retained indefinitely | Local reads/writes remain usable for offline/account/quota/CloudKit/conflict/key-reset/remote-zone-loss failure; unresolved records pause without an automatic winner; trust-boundary pauses require explicit recovery and generic Enable/Retry cannot clear them. DEC-COM-039/042/043 permanently waive physical same-account, background-push, account-switch, offline, and quota observations as non-passes without weakening deterministic conflict/failure behavior. Distribution signing and Production schema/deployment/release proof are not waived and remain COM-C6/COM-C12 gates | REQ-ICLOUD-001 / C4B-01/C4B-02/C4B-03; DEC-COM-006/028/029/031/032/033/034/036/038/039/040/041/042/043 accepted |
| Signed public configuration | C3-03 Done through PR #38 (`db7926d`); Development deployed and verified; Staging/Production undeployed; no distribution authorization | Development / Staging / Production exact and compile-time isolated; Release selects only Production | `mindbudget-public-config-dev.yehao1105.workers.dev`; `mindbudget-public-config-staging.yehao1105.workers.dev`; `mindbudget-public-config.yehao1105.workers.dev`; no wildcard, redirect, or caller URL | Anonymous HTTPS `GET /v1/config` through only `PublicConfigurationTransport.swift`; 8 s request/12 s resource timeout; 16 KiB response bound; ephemeral/no-cookie/no-credential/no-cache session | `Accept: application/json`, bounded `X-MindBudget-App-Version`, and optional positive `X-MindBudget-Config-Version` only; no body, identifier, cookie, auth, locale, storefront, StoreKit, ledger, amount, merchant, note, receipt, prompt, or AI content | Exact Ed25519 envelope and schema-v1 payload; version/issued-at/expiry plus only `proValueTriggersEnabled`; exact status/MIME/response URL required | No personal-data consent because no identifier/content is sent; disclose ordinary first-party edge connection metadata before release; configuration may affect only optional value-trigger presentation | Client persists only signed envelope/high-water/digest as specified; Worker has no storage, outbound fetch, analytics binding, or app logging, observability disabled, response `no-store`; Cloudflare edge still processes ordinary connection metadata and injects platform response metadata | Last verified digest-matching nonexpired cache, then conservative built-in `false`; transport, signature/schema/key/expiry/rollback/equivocation/persistence failures fail closed with closed non-content reason codes | REQ-R1-NET-001 / COM-C3; DEC-COM-021/022 |
| First-party telemetry ingest | C5-01 Done through PR #76 (`68304ad`); C5-02 Done through reviewed head `72abf4b`, green run `33176551566`, and PR #78 merge `4715054`; C5-03 Done through PR #80 (`a587f42`); C5-04 and COM-C5 Done after independent review of exact PR #84 head `84a96bc`, green run `33247176815`, and merge `4194b73` | Exact Development/Staging/Production compile-time contexts; current source `becb020` is deployed/probed only as Development version `003c66fa-a57c-4b6a-a8d7-3f75b14cc716`; Staging D1 isolated but unmigrated/undeployed; Production D1 unprovisioned and Worker undeployed | `mindbudget-telemetry-dev.yehao1105.workers.dev`; `mindbudget-telemetry-staging.yehao1105.workers.dev`; `mindbudget-telemetry.yehao1105.workers.dev`; no wildcard/caller URL/redirect; exactly one reviewed `TelemetryServiceFactory` selects the compile-time fixed host, while missing state remains disabled | Anonymous `POST /v1/events` (max 20 events/32 KiB) and proof-authenticated `POST /v1/delete` (max 4 proofs/2 KiB); exact host/path, empty status-coded responses, fixed `User-Agent: MindBudget`, absent/empty `Accept-Language`, no auth/cookie/query/content encoding | Closed enum event/action/outcome plus schema/environment/validated app version, rotating UUID pseudonym, deletion handle, occurrence time; ordinary uploads contain one generation; complete delete groups retained UUID/32-byte proofs only in request-local memory/SQL parameters; no build/OS/locale metadata, arbitrary map/free text/ledger/merchant/amount/note/receipt/OCR/model evidence/StoreKit ID/CloudKit envelope; exact production capture sites and reasons are frozen in `C5_TELEMETRY_CAPTURE_AUDIT.md` | Upload 202/409/429/5xx mapped to typed acceptance/rejection/retry; fixed 404/405/421 are durable terminal non-retrying states until explicit Retry or Disable; delete 204 only after all proofs validate; identical retries idempotent; same event UUID with changed facts atomically conflicts; late matching upload after deletion is accepted-but-discarded; response body bounded to 1 KiB and must be empty | Missing/repeated Disable remains zero-write. Explicit bilingual confirmation is required before enable; opt-out clears unsent events, retires the identity, then best-effort cancels active upload without claiming to recall an edge-accepted request. Privacy settings show disabled/enabled/backoff/terminal/capacity/corrupt states, explicit Retry, retained-generation guidance, and separately confirmed Delete. App-wide Delete All attempts proof-authenticated telemetry deletion first, but network, endpoint-policy, or unavailable results cannot block the authoritative local financial erase; the app reports a remote-only pending state and retains authenticated proofs for a separate retry | Independent tombstones prevent late resurrection. Events/identities expire by acceptance + 90 x 24 UTC hours; tombstones use an earlier-or-equal UTC-day bucket shared across requests, retaining broad expiry day but no request-unique timestamp/group. Hourly cleanup repeats bounded 1,000-row transactions until drained; confirmed delete precedes local proof destruction. The historical probe ended at 0 events/0 identities/2 tombstones on pre-remediation Worker `1c162a57-8789-4f7f-9fec-f2c484e9f4f2`; it predates DEC-COM-061 and is not current-source probe evidence. Current Development version `003c66fa-a57c-4b6a-a8d7-3f75b14cc716` then passed 202/202/409/204/202/204, exact `7776000000`-millisecond event TTL, UTC-day tombstone, non-resurrection, and exact cleanup; whole-D1 counts were then 0 events/0 identities/2 historical tombstones. PR #84 later exercised the real iOS Simulator `FixedTelemetryTransport`/`URLSession` path, received upload 202 and delete 204, and left 0 events/0 identities/3 tombstones (2 historical plus the expected live-probe tombstone) | Exact JSON keys plus strict JSON-only whitespace, duplicate-key/UTF-8/depth/node/body/batch bounds; D1 uniqueness/transaction authority; fixed metadata headers; edge IP/pseudonym limiters only abuse buffers; invocation logs off; sampled custom logs contain closed component/environment/route/reason only; any failure leaves entitlement/budget/local use unaffected. Product Interaction, the rotating pseudonym as Device ID, and Purchase History for the closed subscription purchase outcome are declared as unlinked, non-tracking Analytics in the source privacy manifest; App Store Connect still requires a separate update before distribution | REQ-R1-TELEMETRY-001 / C5-01/C5-02/C5-03/C5-04; DEC-COM-056/057/058/059/060/061/062/063/064/065/066/067/068/069/070/071 |
| App Attest/current entitlement | Planned, domain UNVERIFIED | Sandbox/Production strictly separated | Exact independent backend domain TBD plus Apple verification APIs server-side | Challenge/attestation and entitlement endpoints TBD | Attestation/JWS/current product/environment identifiers, nonce, request ID; no ledger content | Short-lived signed entitlement result | Required only for explicit cloud request; no account created | Short server cache; deletion/log TTL specified in COM-C7 | Deny cloud request, retain local/template behavior | REQ-CLOUD-AUTH-001 / COM-C7/C10 |
| Cloud Coach | Planned, forbidden; `OPENAI_ACCOUNT_NOT_ADMITTED` and live Eval not run | Dev/staging/prod plus isolated capped Apple Review environment; ordinary TestFlight/Sandbox/test users denied | Client contacts only exact independent backend; server may contact only OpenAI `gpt-5.6-luna`; no backup provider or failover | Versioned analysis endpoint TBD; the synthetic Eval alone is pinned to the Global `https://api.openai.com/v1` base URL | Consented, redacted, bounded schema only; never raw ledger/note/receipt image/OCR/identifier | Valid versioned structured result, usage disposition, request ID; only a valid result ultimately displayed may commit one credit | Explicit first-send consent naming OpenAI/Luna/purpose/fields/Global processing/configured retention; renewal on material policy change; explicit 30-day local trial grants zero cloud credits | No voluntary training; standard abuse-monitoring retention of up to 30 days is accepted for synthetic Eval and must be disclosed before production; ZDR is optional and cannot be claimed unless enabled; first-party deletion, one-user-calendar-year credit lots, and metadata TTL remain later gates | Deny and return deterministic local fallback on consent, auth, quota, account, policy, provider, model, or network failure; no credit commit | REQ-CLOUD-CONSENT-001, REQ-CLOUD-USAGE-001 / COM-C8–C12; DEC-COM-095/096/097 |

C5-03 adds no network row or egress path. Independent review approved dormant-evidence head
`4ea7cd9`; remediation head `0c61427` closed its P2/P3 findings, passed GitHub Actions run
`33211270363`, and PR #80 merged it as `a587f42` without a pre-merge rereview. PR #81's post-merge
closeout review confirmed that exact delta under DEC-COM-065. The read-only aggregate and offline
builder remain unreachable from the live Worker; no real evidence bundle or G1 decision is
inferred. The owner entered C5-04 on 2026-08-29. Independent review approved the deletion-order
remediation on exact head `2c1cebe` within its declared scope; run `33233846430` passed and PR #82
merged as `28d9eae`. The privacy manifest, feature
capture sites, `TelemetryService`, and operations runbook were excluded. Independent review of PR
#83 head `daea2d2` raised two P2 findings and one P3 and retained that exclusion. Remediation head
`e6bbd3f` applied them and recorded the implementation author's supplemental inspection of those
four surfaces; run `33242024609` passed and PR #83 merged as `becb020` without a pre-merge rereview.
Under DEC-COM-069, that exact source was deployed only to Development as version
`003c66fa-a57c-4b6a-a8d7-3f75b14cc716`, where the synthetic TTL/delete/idempotency proof passed
and retained no new row. PR #84 then exercised the actual iOS Simulator
`FixedTelemetryTransport`/`URLSession` path: upload 202 and delete 204 passed the strict header
contract, and final D1 aggregates were 0 events, 0 identities, and 3 tombstones (2 historical plus
the expected live-probe tombstone). Independent review approved exact PR #84 head `84a96bc`,
hosted run `33247176815` passed, and PR #84 merged as `4194b73`; C5-04 and COM-C5 are Done. The
owner entered COM-C6 on 2026-08-29. C6-01 ran only static checks, local Worker tests/dry-runs,
Release simulator build, and named Swift tests; it performed no remote mutation. Independent
rereview approved exact remediation head `f77d2a6`, hosted run `33255898196` passed, and PR #86
merged as `015d00e`; C6-01 is Done. The owner explicitly entered C6-02 on 2026-08-30. On 2026-09-01
DEC-COM-089 records that the owner separately entered C6-03 and authorized only a
reviewed/green/merged `0.9.9 (10)` Archive and
TestFlight transport upload. Staging/Production service or schema deployment, App Store Connect
form writes, tester assignment, G1, distribution, and public release remain unauthorized.
Exact preparation head `11ab612` passed independent review and hosted run `33488815168` before PR
#95 merged as `d5d0959`. The Distribution IPA passed the closed host/privacy/dependency inspector,
and App Store Connect accepted delivery UUID `1b358d3b-4544-4617-ab47-5be69addc7a8` for processing
at `2026-09-01 19:27:25 +0800`. That upload is not a claim that any reviewed Production Worker is
deployed or reachable, and it is not final-binary traffic, customer telemetry, tester assignment,
G1, distribution, or public-release evidence. DEC-COM-090 owns this exact stop boundary.
Independent review approved exact PR #96 head `3ed1357`, hosted run `33508360536` passed, and PR
#96 merged as `246e7c1`; DEC-COM-091 closes C6-03/COM-C6 without authorizing a new egress,
deployment, App Store Connect write, G1 entry, Watch entry, distribution, or release action.

C6-02's first source pass conservatively added Purchase History for the closed subscription
outcome and introduced an exact privacy-manifest validator plus a signed-app inspector. The latter
passed on a development-signed Release app installed on an iPhone Air with iOS 26.6.1, including
the exact six reviewed host literals. It did not observe traffic, establish host reachability,
prove Production deployment, inspect a distribution signature/IPA, or authorize any remote or App
Store Connect mutation. `C6_02_PREFLIGHT.md` owns those evidence boundaries.

PR #91 changes only local SwiftUI appearance ownership, UI-test synchronization, and bounded
signed-device evidence. Independent review accepted exact head `b3ed24d`, hosted run
`33362101536` passed, and PR #91 merged as `4ddabcd` under DEC-COM-082. It adds no host, request,
payload, entitlement, deployment, traffic claim, App Store Connect mutation, Archive/IPA,
distribution, or release authority. Independent final review approved exact PR #93 head
`016dd33`, hosted run `33405016652` passed, and PR #93 merged as `c940e8e`; DEC-COM-088 marks
C6-02 Done. The later C6-03 owner entry is governed by `C6_03_RELEASE_BASELINE.md` and does not
retroactively broaden any C6-02 evidence or network authorization.

DEC-COM-083 adds no egress or remote action. `C6_02_ACCEPTANCE_MATRIX.json` binds 23 exact local
runtime results and records the owner's bounded treatment of remaining C6-02 physical evidence.
No StoreKit transaction, receipt content, financial store, trace payload,
notification/Siri/Spotlight action, Archive, upload, deployment, or App Store Connect write was
sent. Full physical/system and distribution-candidate checks remain explicit C6-03/C12 non-passes
rather than inferred successes.

## Release enforcement contract

1. `Scripts/check-network-egress.sh` scans every app-target Swift file plus checked-in app property
   lists, entitlements, privacy manifests, xcconfig files, and the project file's generated
   Info.plist settings. While the current set is empty, any app-owned networking primitive,
   Network/CFNetwork/WebKit import, quoted HTTP(S) literal, ATS exception, network entitlement,
   associated domain, or configured HTTP(S) endpoint fails local validation and CI. Full-line
   documentation comments are ignored. A later phase may add only one exact centralized adapter
   exception after its row and decision become Accepted; broad path or module exclusions remain
   forbidden.
2. A new Release network import, URL, domain, entitlement, or endpoint must add/update one row and
   cite an Accepted decision before code review.
3. Every request has one typed owner, fixed method/path, bounded body, bounded response, timeout,
   cancellation, environment isolation, and conservative failure default.
4. Secrets, provider credentials, App Store server keys, signing keys, and admin tokens never ship
   in the client.
5. Logs and telemetry never contain request/response bodies, prompts, ledger values, merchant
   names, notes, receipt text/images, or stable cross-product identifiers.
6. Production cannot accept a Debug/Sandbox host, product, JWS, container, key, or config.
7. Unknown domains/endpoints/fields/providers/models fail closed and emit only allow-listed,
   content-free diagnostics when that channel is itself permitted.
8. Release validation must inventory the final binary and captured traffic against this table;
   the lexical source gate is an early control, not a replacement for binary/traffic evidence.

## Change gate

Any row moving from Planned to Accepted requires the named phase's dated first-party evidence,
privacy/deletion review, environment matrix, and an Accepted entry in `DECISIONS.md`. At COM-C0B,
only the empty app-owned HTTP(S) baseline was Accepted. The StoreKit row is an Apple-managed
transport accepted incrementally by C2-01 through completed C2-04, merged C3-01, and merged C3-02;
it does not permit app-owned HTTP(S), automatic presentation, formal
product creation, Archive/upload, tester assignment, or distribution.
DEC-COM-021 accepts the signed-public-configuration contract. C3-03A is Done through PR #36
(`1ebb36c`); C3-03B passed independent review and GitHub Actions run `31873664396`, then merged
through PR #38 as `db7926d`. The Development Worker and real adapter/verifier path have dated
evidence; Staging and Production remain undeployed. The owner separately authorized 0.9.7 (8) and
later 0.9.8 (9) Archive and transport uploads after COM-C3 closed. App Store Connect accepted
build 9 on 2026-08-17 as delivery `dda1eb09-5d8b-43c6-a2fd-ea910fa422ac`. Those narrow actions do
not deploy Production, assign TestFlight users, submit Beta App Review, or authorize App Store release. With
Production undeployed, the optional trigger resolves to the conservative built-in `false`;
permanent subscription controls and StoreKit authority do not depend on this row.
The C4C-02 implementation merged through PR #68 (`4ca8f1c`) adds Apple
camera/DataScanner/PHPicker and local
Vision/Core Image processing only. It creates no URLSession/HTTP(S), endpoint, prompt, model,
telemetry, iCloud receipt field, or other app-owned egress; receipt product scope remains disabled.
After PR #69 merged the C4C-02 closeout as `3e1c5c9`, the owner explicitly entered C4C-03. Its
reviewed implementation adds only a local `VNRecognizeTextRequest` and mandatory in-process
sensitive-text filter. Exact head `92ed3a7` passed Actions run `32921913143`, and PR #70 merged it
as `d294cfb`. Raw OCR cannot leave the exact adapter/privacy pipeline, and even the filtered
document has no model, persistence, CloudKit, telemetry, URLSession, HTTP(S), endpoint, or other
egress consumer. Receipt product scope remains disabled. After PR #71 merged the C4C-03 closeout as
`08fb718`, the owner explicitly entered C4C-04. Its optional Foundation Models adapter is strictly
on-device, receives only the already privacy-filtered `ReceiptOCRDocument`, and has no URLSession,
HTTP(S), endpoint, telemetry, CloudKit, or remote-model path. Structured results remain ephemeral;
reviewed remediation head `f2d249d` passed Actions run `32946104780`, and PR #72 merged it as
`e6316fa`; PR #73 merged its closeout as `2107723`. The owner explicitly entered C4C-05. Its
candidate enables only local verified-Pro acquisition, OCR, optional Apple on-device-model evidence
selection, editable prefill, and the existing explicit local Save boundary. Receipt images/OCR/
model evidence never enter CloudKit, URLSession, HTTP(S), telemetry, logs, or a remote model. The
current accepted app-owned HTTP(S) set is unchanged. Physical iOS 26.6.1 DataScanner/PHPicker/OCR
and confirmation-boundary evidence passed without adding egress. Independent review approved
remediation head `8607356`; final maintenance head `81cd107` then passed GitHub Actions run
`33035427257` and PR #74 merged it as `d751ff4` without pre-merge rereview. PR #75's post-merge
closeout review accepted that exact delta. C4C-05 and COM-C4C are Done without changing the accepted
app-owned HTTP(S) set, while COM-C5 still requires explicit owner entry and every Production/
distribution/release action remains blocked. The uncertain physical amount remains
manual-review-only rather than an automatic-recognition claim. DEC-COM-053 changes
only the local capture/review presentation: DataScanner remains bounded, the generic PHPicker icon
does not request a recent-photo thumbnail or broad library access, recognition returns to the local
expense form, and no live-frame detector, receipt content channel, telemetry, or endpoint is added.
DEC-COM-054 changes only local ownership, failure presentation, scene handling, and artifact-scoped
cleanup; it adds no destination, payload, identifier, log content, telemetry, or remote model.
The owner explicitly entered COM-C5 on 2026-08-27. DEC-COM-056/057/058 and C5-01 add only a dormant,
default-off typed client plus encrypted local persistence and deterministic tests. The owner then
entered C5-02 under DEC-COM-060. A fixed, directly tested adapter now contains only the three exact
first-party hosts; at C5-01 close the app target still had no `TelemetryClient` construction or
capture call, and `UnavailableTelemetryTransport` was the default. Review remediation makes corrupt local file/key
deletion available without a remote claim, limits pseudonym non-linkage to ordinary upload
envelopes, and records the grouped complete-delete association as data C5-02 must never retain,
log, or reuse. C5-02 implements event-ID and identical proof-deletion idempotency, late-upload
tombstones with only a coarse UTC-day expiry bucket, a 90 x 24-hour maximum server TTL, repeated
bounded cleanup, fixed non-identifying request metadata, closed monitoring, and best-effort
in-flight upload cancellation. Only Development version `1c162a57-8789-4f7f-9fec-f2c484e9f4f2` is deployed and
probed; Staging is undeployed and Production has no provisioned D1 resource.
Exact final head `d937dc8` passed GitHub Actions run `33085630481`, and PR #76 merged C5-01 as
`68304ad`. The C5-02 source increment itself accepted no production client construction, capture
call, customer control, App Privacy change, Staging/Production deployment, distribution, or release.
Independent review approved exact C5-02 remediation head `72abf4b`, GitHub Actions run
`33176551566` passed, and PR #78 merged it as `4715054`. Current customer telemetry egress remains
zero. The owner entered C5-03 on 2026-08-29. Independent review approved head `4ea7cd9`;
remediation head `0c61427` closed its P2/P3 findings, passed run `33211270363`, and PR #80 merged it
as `a587f42` without a pre-merge rereview. PR #81's post-merge closeout review confirmed that exact
delta. Its evidence builder is offline and its D1 receipt funnel is an unexposed read-only
aggregate: it added no host, path, request, client construction, or capture. The owner entered
C5-04 on 2026-08-29; its separately gated candidate and remaining evidence boundaries are recorded
in the accepted telemetry row above.
