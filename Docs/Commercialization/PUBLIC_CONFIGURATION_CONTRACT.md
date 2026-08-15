# Signed Public Configuration Contract

Status: **Accepted by the owner for COM-C3-03 on 2026-08-14.**

Requirement: `REQ-R1-NET-001`
Decision: `DEC-COM-021`

This contract authorizes implementation in two review packets. C3-03A owns only the signed
document, strict verification, rollback high-water mark, nonexpired cache, and conservative local
resolution. C3-03B may add the one fixed read-only transport and presentation integration only
after C3-03A is independently reviewed. C3-03A contains no `URLSession`, URL, Release endpoint,
embedded production key, or application-network egress.

## Environment and transport

| Environment | Exact host | App acceptance |
|---|---|---|
| Development | `mindbudget-public-config-dev.yehao1105.workers.dev` | Debug/development only |
| Staging | `mindbudget-public-config-staging.yehao1105.workers.dev` | Non-Release validation only |
| Production | `mindbudget-public-config.yehao1105.workers.dev` | The only future Release host |

- Exact method/path: anonymous `GET /v1/config` over HTTPS.
- The future request may send only the app version and last accepted configuration version as
  bounded non-content metadata. It has no request body, authentication, cookie, user/device/
  advertising identifier, StoreKit transaction, locale, storefront, ledger, amount, merchant,
  note, receipt, prompt, or AI content.
- Redirects, caller-provided URLs, alternate hosts, wildcard subdomains, and arbitrary headers are
  rejected. Dev/staging hosts can never be selected by Release code or remote configuration.
- The service is a new independent MindBudget Cloudflare Worker. It does not reuse another
  product's Worker, bindings, secrets, storage, admin session, logs, or data.
- No transport is implemented in C3-03A. The Release app-owned HTTP(S) allow-list remains empty
  until C3-03B moves the exact adapter through review.

## Signed envelope

The response is one JSON object with exactly these fields:

```json
{
  "algorithm": "Ed25519",
  "keyID": "mb-config-2026-01",
  "payloadBase64": "<base64 of exact UTF-8 JSON payload bytes>",
  "signatureBase64": "<base64 Ed25519 signature over those exact payload bytes>"
}
```

- The client verifies the exact decoded payload bytes before decoding the payload. This avoids an
  ad-hoc canonical-JSON signature scheme.
- The signing service must emit UTF-8 JSON without duplicate object keys. Field ordering is not a
  client-side authority: sorted keys are a signer convenience, while the signature always covers
  the exact emitted bytes. The client does not decode and re-encode a purported canonical form.
- Envelope, payload, and nested presentation keys are counted before Foundation decoding so a
  duplicate key cannot be silently collapsed by a parser.
- The app contains public verification keys only. Private signing keys and admin credentials never
  enter the app, repository, fixture bundle, logs, or public configuration.
- Unknown algorithms, key IDs, fields, encodings, signatures, or oversized documents fail closed.
- C3-03 accepts one initial key seam; operational rotation and retained-key procedure belong to
  COM-C5. A later key must be added by an Accepted decision and overlapping verification window.

## Payload schema v1

The verified payload contains exactly:

```json
{
  "schemaVersion": 1,
  "configVersion": 1,
  "issuedAt": "2026-08-14T00:00:00Z",
  "expiresAt": "2026-08-21T00:00:00Z",
  "presentation": {
    "proValueTriggersEnabled": false
  }
}
```

- `configVersion` is a positive monotonic unsigned integer.
- `issuedAt` and `expiresAt` must use the exact UTC grammar `yyyy-MM-dd'T'HH:mm:ss'Z'`: exactly
  four-digit year through whole seconds, uppercase `T`/`Z`, no fractional seconds, and no numeric
  offset. The signed golden vector is fixed independently from the client fixture encoder.
- A document may be at most 16 KiB and its decoded payload at most 8 KiB.
- The validity window must be positive and no longer than seven 24-hour intervals. A signed
  `issuedAt` may be at most five minutes ahead of the device clock. `expiresAt <= now` is expired.
- Unknown or missing envelope, payload, or nested presentation fields fail closed.
- `proValueTriggersEnabled` is the only v1 presentation field. The conservative built-in value is
  `false`.

## Authority and presentation boundary

Configuration may enable or disable only optional explicit Pro value-trigger entry points. It
cannot hide the Settings Pro entry, Restore Purchases, Manage Subscription, or current-subscription
status. It cannot name or change StoreKit products, prices, trial eligibility/duration, renewal,
entitlements, billing state, notifications, Local Lifetime, iCloud, Cloud Coach, provider/model,
quota, Watch, receipt, telemetry, version rollout, or another feature authority. StoreKit remains
the sole paid authority and customer-price source.

## Cache, expiry, and rollback

- Accept and publish a remote document only after verification and durable cache/high-water-mark
  persistence succeed.
- Persist only the signed envelope, highest accepted version, and SHA-256 digest of the signed
  payload in one atomic, file-protected record. Readback must match before the value is published.
  These bytes contain no user content or identifier.
- A lower version is rejected. The same version is accepted only with the same payload digest;
  same-version equivocation is rejected.
- Offline/remote/verification failure uses the last verified, digest-matching, nonexpired cache.
  If none exists, use the conservative built-in presentation.
- An invalid/corrupt rollback record is not silently overwritten because its lost high-water mark
  cannot prove that a remote document is not a rollback. This is a sticky Release fail-closed
  state: later valid remote bytes cannot overwrite it, and the app uses the built-in default.
- Release code has no reset, delete-file, Debug-provider, or user-facing recovery seam for this
  rollback record. Recovery currently requires deleting the app and its data container, then
  reinstalling; iOS Offload is insufficient because it preserves app data. The ordinary in-app
  Delete All User Data workflow must not reset this security high-water mark. A future signed
  recovery protocol or operational reset requires a separate Accepted decision and tests.
- Every accepted write is read again through the persistence abstraction, compared with the exact
  intended snapshot, and re-verified before `.remote` is returned. Concurrent acceptance is
  serialized across read/compare/write/read-back so an older document cannot overwrite a newer
  high-water mark during actor reentrancy.
- Cache or configuration can never grant or preserve paid access.

## Privacy, operations, and release gates

The app deliberately sends no stable identifier or user content. Standard Internet transport
still exposes ordinary connection metadata such as an IP address to the first-party edge service
and its infrastructure provider. Before C3-03B can become distributable, the real Worker must be
inspected for platform analytics/logging, storage, TTL, cache headers, redirect behavior, abuse
limits, and privacy disclosure; captured traffic and the final binary must match the allow-list.
The endpoint and public key must have dated first-party evidence. The post-0.9.6 release hold,
formal-product/economics gates, Archive/upload, tester assignment, and distribution remain active.

C3-03A deliberately does not add `os_log`, analytics, or another diagnostics sink before a real
transport/operations boundary exists. C3-03B must define closed reason-code observability for
verification, rollback/equivocation, persistence, and transport failures; it may never log signed
payload bytes, signatures, financial/user content, or stable identifiers.
