# Release Network Egress Policy

## Default rule

All app-owned Release HTTP(S) egress is denied unless one exact row below is `Accepted` and the
implementing phase has passed its own consent, privacy, deletion, failure, and release gates.
Wildcards, caller-supplied URLs, arbitrary model IDs, and untyped payload dictionaries are
forbidden. Debug/test endpoints never authorize Production behavior.

The current 0.9.6 app has **no app-owned business-network egress**. This policy creates no URL,
entitlement, container, SDK, or request.

## Allow-list

| Channel | Status | Environment | Domain/transport | Endpoint and method | Allowed outbound fields | Allowed inbound fields | Consent/control | Retention/deletion | Failure default | Requirement/phase |
|---|---|---|---|---|---|---|---|---|---|---|
| Current app-owned HTTP(S) | Accepted empty set | Release | None | None | None | None | Not applicable | Not applicable | Remain fully local | REQ-R1-NET-001 / current baseline |
| StoreKit lifecycle | COM-C2 complete through PR #31 (`a293762`); no customer UI or distribution authorization | Xcode Configuration / Sandbox (including TestFlight) / Production kept distinct by verified StoreKit environment | Apple-managed StoreKit API; no app-owned domain or raw receipt endpoint | `Product.products(for:)`, `AppTransaction.shared`, `Storefront.current`, `Transaction.currentEntitlements`, `Transaction.updates`, `Product.SubscriptionInfo.Status.updates`, `Product.SubscriptionInfo.status(for:)`, `Transaction.subscriptionStatus`, `Transaction.unfinished`, `AppStore.canMakePayments`, explicit `Product.purchase()`, explicit `AppStore.sync()`, and `Transaction.finish()` only after authoritative publish | Accepted Product IDs plus Apple-required app bundle, product, transaction, renewal, ownership, environment, and storefront metadata only; no ledger/note/receipt content | Typed `Product`; verified app transaction/environment; verified status transaction and renewal information; verified current/update/unfinished/purchase transaction facts; transaction/status signals; pending/cancel/error; raw revocation/expiration; environment/storefront | One lifecycle authority; each whole read must match the separately verified AppTransaction bundle/environment. TestFlight is verified Sandbox, not a manual Production flag. No current view invokes purchase/restore and no implicit restore prompt exists | Apple platform policy; deletable exact environment/storefront presentation cache only, never authority; failed finish remains unfinished for retry | Missing/wrong app bundle, missing/unknown/mismatched environment, product/status failure, unverified input, incomplete Free authority, and finish failure fail closed; customer UI and distribution remain blocked | REQ-STOREKIT-STATE-001, REQ-STOREKIT-LIFECYCLE-001 / COM-C2; DEC-COM-016/017/018 |
| Free iCloud sync | Planned, not implemented | Development/Production CloudKit containers separated | Apple-managed CloudKit APIs; container TBD | Architecture/record operations TBD in COM-C4B | Approved sync records only; no receipt image/local intermediate | Versioned records/errors/change tokens | Explicit default-off opt-in and account controls | Local/cloud deletion and tombstones required; platform limits disclosed | Local app stays usable; no destructive conflict guess | REQ-ICLOUD-001 / COM-C4B |
| Signed public configuration | Planned, domain UNVERIFIED | Dev/staging/prod separated | Exact first-party domain TBD; no wildcard | Read-only `GET` path TBD | App/config version and minimum non-content request metadata only | Signed versioned expiry-bound configuration | No personal-data consent required only if request remains nonidentifying/content-free; disclose actual behavior | Bounded cache; no user content | Last verified nonexpired cache, then conservative built-in default | REQ-R1-NET-001 / COM-C3 |
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
transport accepted incrementally by C2-01 through completed C2-04 and merge `a293762`; it
does not permit app-owned HTTP(S), customer-facing purchase UI, or distribution.
