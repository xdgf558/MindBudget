# COM-C5 Execution Packet — First-Party Telemetry, Metrics, and Operations

## Status

Status: **In Progress.**

The owner explicitly entered COM-C5 on 2026-08-27 after C4C-05 and COM-C4C closed through PR #75
(`82ef0fa`). This packet opens only C5-01. It does not accept a domain, create a live transport,
enable collection, add a customer setting, deploy a receiver, change App Privacy answers, enter
C5-02, or authorize Production/distribution.

## Input gate

- SPEC-009 and SPEC-012 accept only an optional, explicit-control, first-party, allow-listed,
  pseudonymous channel whose fixed schema excludes customer content and whose failure cannot alter
  product behavior.
- REQ-R1-TELEMETRY-001 remains Active. C5-01 may establish the typed local client and test seams;
  real TTL, server rejection, deletion, environment isolation, monitoring, cost, capture audit,
  disclosure, and final-binary traffic evidence remain later gates.
- `NETWORK_EGRESS_POLICY.md` still lists the telemetry domain and endpoints as UNVERIFIED/TBD.
  Therefore a URL, `URLSession` adapter, Worker, dashboard, secret, entitlement, or production call
  site is outside this packet.
- Receipt images, prepared pixels, OCR, privacy-filtered receipt text, model evidence, merchant,
  amount, note, category, StoreKit identifiers, CloudKit envelopes, and other business facts must
  remain unrepresentable by the telemetry event type.

## C5-01 — Typed private client

Status: **Implementation complete pending independent review, hosted CI, and merge.**

### Closed schema

- `TelemetryEvent` is the complete R1 event vocabulary: app session start, Pro-surface presentation,
  subscription action, receipt-flow action, and cloud-sync-control action. Associated values are
  closed enums for action and outcome; there is no caller-defined property dictionary or free-text
  field.
- The upload envelope contains exactly schema version, environment, validated numeric/dotted app
  version, one pseudonymous generation ID, its deletion handle, and the bounded typed events. The
  deletion envelope contains only schema version, environment, and the pseudonymous ID/secret
  proofs needed to delete every retained generation.
- This is a schema capability, not a capture decision. C5-01 has no production `TelemetryClient`
  construction or event call site, so the checked-in app collects and transmits zero telemetry.

### Identity, control, and deletion

- Collection is missing-state default-off. Reading that state creates no key, file, identity, or
  write. Capture while disabled returns `.disabled` and never changes persistence.
- Enabling creates a cryptographically random 32-byte deletion secret plus a new UUID pseudonym.
  The deletion handle is SHA-256 of that secret; the raw secret is never part of an upload batch.
- A generation rotates after 30 user-calendar days. Explicit reset also retires the current
  generation. Opt-out immediately clears unsent events, retires the active generation for deletion
  proof only, and a later opt-in must create a different pseudonym. Ordinary upload envelopes never
  reuse or group pseudonyms across that disabled interval; this is the exact C5-01 unlinkability
  boundary.
- Retired proofs have a 90-day local expiration target and are pruned only after their generation
  has no queued event. At most four generations may coexist; capacity failure rejects new capture or
  re-enable instead of discarding a still-required deletion proof. Four rapid opt-out/re-enable
  cycles can therefore leave re-enable unavailable until a proof expires or Delete succeeds; C5-04
  must provide closed, non-blaming guidance for that boundary.
- Delete deliberately groups proofs for every retained generation in one bounded request so the
  future service can delete the complete set without a partial-success state. This operation does
  reveal to the first-party deletion processor that those pseudonyms share one deletion request;
  it is not described as cross-generation unlinkability. C5-02 must process that association only
  for deletion and must not persist, log, or reuse it. Failure keeps every proof and returns a
  closed failure result. Only confirmed remote deletion removes readable retained proofs.
- Corrupt persistence still blocks opt-in, capture, and overwrite, but never blocks local privacy
  deletion. Local deletion removes the unreadable encrypted file and at-rest key, restores an empty
  available state, and returns `.deletedLocallyWithoutRemoteProofs` so no remote deletion is
  implied. A never-enabled/missing state may be deleted locally without a remote claim.

### Queue, persistence, and failure isolation

- The queue contains at most 256 events and drops only the oldest unsent event when full. An upload
  contains at most 20 consecutive events from one identity generation; generations are never mixed
  in one batch.
- The local state is JSON encoded with fixed dates/keys, encrypted using AES-GCM with a 32-byte
  Keychain key, protected until first unlock, excluded from backup, atomically written, and read back
  as the exact state before commit succeeds. The file and plaintext each remain bounded to 256 KiB.
- A present but missing-key, malformed, oversized, unauthenticated, or structurally invalid file is
  sticky invalid for collection and mutation. It cannot be overwritten by opt-in or capture, while
  the explicit local deletion path remains available.
- Local read/modify/write transactions are explicitly serialized across actor suspension points.
  Upload releases that local mutation slot during transport, then removes only the exact submitted
  event IDs; a concurrent capture cannot be lost. Delete retains the slot until its destructive
  result is known so another operation cannot create a generation that the deletion request omitted.
- Retry is bounded exponential backoff with a six-hour ceiling; a server delay is clamped to 60
  seconds through six hours. Disabled, unavailable, rejected, cancellation, persistence, or network
  outcomes never unlock/lock Pro, alter a budget, block expense entry, or become entitlement
  authority.

### Deliberately unavailable transport

- `UnavailableTelemetryTransport` is the only production default. It returns a closed
  `noAcceptedEndpoint` failure and contains no URL or network framework.
- `Scripts/check-telemetry-contract.sh` rejects a live endpoint/transport, a production client
  construction, event-schema drift, upload-envelope drift, selected financial/receipt/StoreKit/data
  authority types, missing encryption/queue/rotation anchors, or missing lifecycle tests. Its
  event/envelope/construction scans execute positive and negative fixtures first; missing tools,
  missing source roots, or incomplete scans fail closed.
- C5-02 must not replace the unavailable transport until its exact dev/staging/production domains,
  paths, methods, request and response bytes, unknown-field rejection, authentication/abuse limit,
  real 90-day server TTL, proof deletion, monitoring, cost ceiling, and owner-reviewed disclosure are
  recorded together. It must also decide and test whether opt-out cancels an in-flight upload; the
  dormant C5-01 client retains deletion proofs but has no live request to cancel.

### Verification

- Seventeen deterministic tests cover default-off zero-write, exact event JSON, app-version
  rejection, upload-envelope pseudonym non-reuse, the four-generation re-enable boundary,
  concurrent mutation ordering, queue overflow, manual and automatic rotation, single-generation
  batching, concurrent capture during upload, concurrent-flush transport serialization, bounded
  retry, explicit grouped deletion, deletion-proof retention/destruction, sticky corrupt
  persistence, corrupt-state file/key deletion, and authenticated-encryption round trip.
- Focused simulator execution passes 17/17. The self-testing static telemetry gate and repository
  diff check pass.
  The owning unrestricted `Scripts/validate.sh` run also passes every static contract, Release
  compilation, the strict 10,000-row Dashboard wall-clock stage, 534 unit tests across 32 suites,
  all 17 UI tests, and every selected coverage threshold; four opt-in physical CloudKit probes are
  reported as skipped, and `CSVExporter.swift` remains the minimum selected coverage result at
  87.60% against 85%. Hosted CI remains a merge gate. Neither run is presented as endpoint,
  receiver, TTL, deletion-service, customer-control, App Privacy, or network evidence.

## C5-02 — Minimal ingest and deletion

Status: **Blocked by C5-01.**

Own the independent serverless receiver, strict request-byte schema, environment separation,
unknown/free-text rejection, real retention and deletion behavior, abuse/cost ceilings, monitoring,
the smallest reviewed client network adapter, non-retention of deletion-request cross-generation
association, and the explicit in-flight opt-out cancellation policy. It may not infer C5-03 metrics
or C5-04 release approval.

## C5-03 — Metrics and G1 evidence

Status: **Blocked by C5-02.**

Own exact App Store and voluntary telemetry numerators/denominators, confidence intervals, coverage
reporting, survey workflow, and the receipt funnel without expanding captured fields.

## C5-04 — Operations and disclosures

Status: **Blocked by C5-03.**

Own the publish/rollback/key-rotation runbook, customer control and bilingual disclosure, privacy
policy/App Privacy/data-flow updates, capture audit, and actual TTL/deletion verification.

## Exit and stop conditions

C5-01 may be Done only after exact-head independent review, green hosted CI, and merge. COM-C5 is
not Done until C5-02 through C5-04 prove a content-free, optional, deletable, observable, and
cost-bounded real channel. Stop on any content-bearing field, arbitrary dictionary/string, implicit
collection, identifier reuse across opt-out, lost deletion proof, unencrypted/unbounded queue,
an unqualified claim that deletion requests are unlinkable, unaccepted domain, environment mixing,
product-behavior dependency, or release claim.
