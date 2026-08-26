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
| First-party telemetry ingest | Planned, domain UNVERIFIED | Dev/staging/prod separated | Exact first-party domain TBD; no wildcard | Batched `POST` and deletion endpoint paths TBD | Fixed event/property schema, rotating pseudonymous ID, environment/app/schema versions; no free text/content | Acceptance/deletion status only | Explicit control; default policy and UI finalized in COM-C5 | 90-day maximum target subject to real verification; opt-out/reset/delete | Drop/defer bounded queue; never alter product behavior | REQ-R1-TELEMETRY-001 / COM-C5 |
| App Attest/current entitlement | Planned, domain UNVERIFIED | Sandbox/Production strictly separated | Exact independent backend domain TBD plus Apple verification APIs server-side | Challenge/attestation and entitlement endpoints TBD | Attestation/JWS/current product/environment identifiers, nonce, request ID; no ledger content | Short-lived signed entitlement result | Required only for explicit cloud request; no account created | Short server cache; deletion/log TTL specified in COM-C7 | Deny cloud request, retain local/template behavior | REQ-CLOUD-AUTH-001 / COM-C7/C10 |
| Cloud Coach | Planned, forbidden before G1/C8 | Dev/staging/prod separated | Client contacts only exact independent backend; provider domains are server-only allow-list | Versioned analysis endpoint TBD | Consented, redacted, bounded schema only; never raw ledger/note/receipt image/OCR/identifier | Versioned structured facts/wording, usage result, request ID | Explicit first-send consent naming provider set/purpose/fields; renewal on material change | Provider/first-party retention and deletion must be accepted and disclosed | Deny/fallback locally on consent, auth, quota, policy, provider, or network failure | REQ-CLOUD-CONSENT-001, REQ-CLOUD-USAGE-001 / COM-C8–C12 |

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
candidate adds only a local `VNRecognizeTextRequest` and mandatory in-process sensitive-text
filter. Raw OCR cannot leave the exact adapter/privacy pipeline, and even the filtered document has
no model, persistence, CloudKit, telemetry, URLSession, HTTP(S), endpoint, or other egress consumer.
Receipt product scope remains disabled.
