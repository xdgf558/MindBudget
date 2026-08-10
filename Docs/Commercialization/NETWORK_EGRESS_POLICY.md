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
| StoreKit lifecycle | Planned, not implemented | Configuration/Sandbox/TestFlight/Production isolated | Apple-managed StoreKit API; no app-owned domain or raw receipt endpoint | StoreKit 2 typed APIs only; exact call set frozen in COM-C2 | Apple-required purchase/product context only; no ledger/note/receipt content | Typed `Product`/verified transaction/subscription status | Explicit purchase/restore; system account controls | Apple platform policy; app cache deletable and never permanent authority | Product load failure preserves verified entitlement and Free usability; unverified state grants no rights | REQ-STOREKIT-STATE-001, REQ-STOREKIT-LIFECYCLE-001 / COM-C2 |
| Free iCloud sync | Planned, not implemented | Development/Production CloudKit containers separated | Apple-managed CloudKit APIs; container TBD | Architecture/record operations TBD in COM-C4B | Approved sync records only; no receipt image/local intermediate | Versioned records/errors/change tokens | Explicit default-off opt-in and account controls | Local/cloud deletion and tombstones required; platform limits disclosed | Local app stays usable; no destructive conflict guess | REQ-ICLOUD-001 / COM-C4B |
| Signed public configuration | Planned, domain UNVERIFIED | Dev/staging/prod separated | Exact first-party domain TBD; no wildcard | Read-only `GET` path TBD | App/config version and minimum non-content request metadata only | Signed versioned expiry-bound configuration | No personal-data consent required only if request remains nonidentifying/content-free; disclose actual behavior | Bounded cache; no user content | Last verified nonexpired cache, then conservative built-in default | REQ-R1-NET-001 / COM-C3 |
| First-party telemetry ingest | Planned, domain UNVERIFIED | Dev/staging/prod separated | Exact first-party domain TBD; no wildcard | Batched `POST` and deletion endpoint paths TBD | Fixed event/property schema, rotating pseudonymous ID, environment/app/schema versions; no free text/content | Acceptance/deletion status only | Explicit control; default policy and UI finalized in COM-C5 | 90-day maximum target subject to real verification; opt-out/reset/delete | Drop/defer bounded queue; never alter product behavior | REQ-R1-TELEMETRY-001 / COM-C5 |
| App Attest/current entitlement | Planned, domain UNVERIFIED | Sandbox/Production strictly separated | Exact independent backend domain TBD plus Apple verification APIs server-side | Challenge/attestation and entitlement endpoints TBD | Attestation/JWS/current product/environment identifiers, nonce, request ID; no ledger content | Short-lived signed entitlement result | Required only for explicit cloud request; no account created | Short server cache; deletion/log TTL specified in COM-C7 | Deny cloud request, retain local/template behavior | REQ-CLOUD-AUTH-001 / COM-C7/C10 |
| Cloud Coach | Planned, forbidden before G1/C8 | Dev/staging/prod separated | Client contacts only exact independent backend; provider domains are server-only allow-list | Versioned analysis endpoint TBD | Consented, redacted, bounded schema only; never raw ledger/note/receipt image/OCR/identifier | Versioned structured facts/wording, usage result, request ID | Explicit first-send consent naming provider set/purpose/fields; renewal on material change | Provider/first-party retention and deletion must be accepted and disclosed | Deny/fallback locally on consent, auth, quota, policy, provider, or network failure | REQ-CLOUD-CONSENT-001, REQ-CLOUD-USAGE-001 / COM-C8–C12 |

## Release enforcement contract

1. A new Release network import, URL, domain, entitlement, or endpoint must add/update one row and
   cite an Accepted decision before code review.
2. Every request has one typed owner, fixed method/path, bounded body, bounded response, timeout,
   cancellation, environment isolation, and conservative failure default.
3. Secrets, provider credentials, App Store server keys, signing keys, and admin tokens never ship
   in the client.
4. Logs and telemetry never contain request/response bodies, prompts, ledger values, merchant
   names, notes, receipt text/images, or stable cross-product identifiers.
5. Production cannot accept a Debug/Sandbox host, product, JWS, container, key, or config.
6. Unknown domains/endpoints/fields/providers/models fail closed and emit only allow-listed,
   content-free diagnostics when that channel is itself permitted.
7. Release validation must inventory the final binary and captured traffic against this table.

## Change gate

Any row moving from Planned to Accepted requires the named phase's dated first-party evidence,
privacy/deletion review, environment matrix, and an Accepted entry in `DECISIONS.md`. At COM-C0B,
only the empty current baseline is Accepted.
