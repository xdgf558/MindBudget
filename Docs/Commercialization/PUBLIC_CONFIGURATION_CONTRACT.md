# Signed Public Configuration Contract

Status: **Accepted by the owner for COM-C3-03 on 2026-08-14.**

Requirement: `REQ-R1-NET-001`
Decision: `DEC-COM-021`

This contract authorizes implementation in two review packets. C3-03A owns only the signed
document, strict verification, rollback high-water mark, nonexpired cache, and conservative local
resolution. It passed independent review and green GitHub Actions run `31856271268`, then merged
through PR #36 as `1ebb36c` on 2026-08-15. C3-03B implemented the one fixed read-only transport
and presentation integration; its reviewed head `09c382e` passed GitHub Actions run
`31873664396`, and PR #38 merged it as `db7926d` on 2026-08-15. C3-03 is Done, but this remains no
distribution authorization.

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
- C3-03B implements one centralized fixed adapter. Debug selects Development by default and may
  select Staging only through an explicit launch argument; Release is compiled to Production and
  has no path to a caller-provided, Development, or Staging URL. The request is bounded to the
  exact method, path, `Accept`, app-version, and optional last-accepted-version headers above. It
  uses an ephemeral session with no cookies, credentials, or shared cache; rejects redirects;
  limits the response to 16 KiB; and fails conservatively on timeout, cancellation, offline,
  status, MIME, URL, empty-body, or size error.
- The Development Worker deployment is first-party evidence only. Staging and Production remain
  undeployed, and the post-0.9.6 distribution hold means the reviewed Release adapter cannot ship
  until the later release, privacy, final-binary, and captured-traffic gates pass.
- Refresh cancellation is structural: the startup refresh is awaited by its own SwiftUI `.task`,
  while a scene-active refresh is retained by `AppSession` and canceled on replacement,
  inactive/background transition, or Session destruction. Canceling either owner cancels the
  transport/acceptance task. A canceled startup attempt resets its one-time guard so a recreated
  SwiftUI task can retry. Cancellation is checked before request construction, after transport
  completion, before verification/persistence, and before publication, so a canceled refresh
  cannot later publish a presentation. A canceled operation may not be treated as an ordinary
  offline fallback result.

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

An enabled trigger is presentable only when StoreKit has published an actionable whole-snapshot
result whose effective state is exact Free (`.none`). Initial, incomplete, unverified, mixed, or
otherwise unavailable StoreKit authority is not Free for presentation purposes, even when the
fail-closed entitlement set itself is empty. This prevents a temporarily unverifiable paid user
from being shown a Free acquisition entry. Presentation may disappear conservatively; it can
never grant or preserve a paid right.

## Cache, expiry, and rollback

- Accept and publish a remote document only after verification and durable cache/high-water-mark
  persistence succeed.
- Persist only the signed envelope, highest accepted version, and SHA-256 digest of the signed
  payload in one atomic, file-protected record. Readback must match before the value is published.
  These bytes contain no user content or identifier.
- File persistence checks cancellation after actor entry and immediately before the atomic write.
  That final check is the explicit commit point: cancellation observed before it leaves the prior
  cache untouched; once the non-suspending atomic write begins, it may complete, while the
  canceled acceptance still cannot publish its result. This avoids claiming that an already
  committed durable write can be rolled back safely.
- A lower version is rejected. The same version is accepted only with the same payload digest;
  same-version equivocation is rejected.
- Offline/remote/verification failure uses the last verified, digest-matching, nonexpired cache.
  If none exists, use the conservative built-in presentation.
- Remote verification samples the clock after the complete response arrives. A payload that was
  nonexpired when the request began but expires in flight is rejected. Every verified remote/cache
  resolution carries its exact signed `expiresAt`; AppSession schedules independent expiry and
  replaces the presentation with the built-in conservative value at that instant without waiting
  for another foreground transition or network refresh. Replacement cancels the older schedule.
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

C3-03B adds only closed `transport.*` and `resolution.*` reason codes through unified logging.
The vocabulary contains no payload, signature, header value, URL query, IP address, financial/user
content, or stable identifier. The Worker calls no outbound service, has no database, KV, R2,
analytics binding, cookie, or request log in app code, and has Cloudflare Worker observability
disabled. It serves `Cache-Control: no-store` and exact security headers. The Cloudflare edge still
sees ordinary connection metadata and injects ordinary edge response metadata (including
`Report-To`/`NEL` on the tested workers.dev surface); the native app does not send browser NEL
reports, but this provider-level behavior remains part of privacy/release disclosure and final
traffic review.

The Ed25519 private key was generated and is stored only in an owner-controlled protected file
outside the repository. The repository contains the 32-byte public key, a local signing utility,
and pre-signed seven-day envelopes only. Development deployment
`bf6c5049-a389-4ea7-af0a-e8425b8957e2` was created on 2026-08-15 and the dedicated non-Archive
scheme verified the real Development response through the production verifier and embedded public
key with 8 passed, 0 failed, and 0 skipped. Staging and Production were not deployed. Private key
bytes never entered the app, Worker, repository, logs, or test results. PR #38 passed independent
review and green GitHub Actions run `31873664396`, then merged as `db7926d`; Production deployment,
final Release binary/traffic capture, privacy/review approval, Archive/upload, tester assignment,
and distribution remain later gates.
