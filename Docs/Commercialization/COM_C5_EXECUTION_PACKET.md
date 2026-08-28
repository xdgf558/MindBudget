# COM-C5 Execution Packet — First-Party Telemetry, Metrics, and Operations

## Status

Status: **In Progress.**

The owner explicitly entered COM-C5 on 2026-08-27 after C4C-05 and COM-C4C closed through PR #75
(`82ef0fa`). Exact final C5-01 head `d937dc8` passed GitHub Actions run `33085630481`, and PR #76
merged it as `68304ad`. The owner separately entered C5-02 on 2026-08-28. Independent review
approved exact remediation head `72abf4b`, GitHub Actions run `33176551566` passed, and PR #78
merged it as `4715054`; C5-02 is Done. C5-03 still requires explicit owner entry, C5-04 remains
blocked by C5-03, and no collection, customer setting, capture call, App Privacy change,
Staging/Production deployment, distribution, or release is authorized.

## Input gate

- SPEC-009 and SPEC-012 accept only an optional, explicit-control, first-party, allow-listed,
  pseudonymous channel whose fixed schema excludes customer content and whose failure cannot alter
  product behavior.
- REQ-R1-TELEMETRY-001 remains Active. C5-01 established the typed local client and test seams;
  C5-02 now owns the exact receiver, TTL, server rejection, deletion, environment isolation,
  monitoring, cost ceilings, and dormant adapter. Capture audit, disclosure, App Privacy, and
  final-binary traffic remain C5-03/C5-04 and release gates.
- `NETWORK_EGRESS_POLICY.md` accepts only the three exact first-party hosts and two exact POST
  paths. Development alone may be deployed/probed. No production client construction, capture
  call, customer setting, Staging/Production deployment, dashboard product claim, entitlement, or
  release action is inside this packet.
- Receipt images, prepared pixels, OCR, privacy-filtered receipt text, model evidence, merchant,
  amount, note, category, StoreKit identifiers, CloudKit envelopes, and other business facts must
  remain unrepresentable by the telemetry event type.

## C5-01 — Typed private client

Status: **Done after independent review of exact head `d937dc8`, green GitHub Actions run
`33085630481`, and PR #76 merge `68304ad`.**

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
  write. Capture while disabled returns `.disabled` and never changes persistence. Repeating
  `setCollectionEnabled(false)` while already disabled is also a true no-op: it cannot create the
  encrypted file, Keychain key, identity, or a write.
- Enabling creates a cryptographically random 32-byte deletion secret plus a new UUID pseudonym.
  The deletion handle is SHA-256 of that secret; the raw secret is never part of an upload batch.
- A generation rotates after 30 user-calendar days using the injected user calendar/time zone;
  the default is `Calendar.autoupdatingCurrent`, while deterministic tests inject a fixed calendar.
  Explicit reset also retires the current
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
  closed failure result. Only confirmed remote deletion removes readable retained proofs. Because
  a remote delete can succeed before local file/key cleanup fails, C5-02 must make an identical
  deletion request idempotent.
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
  seconds through six hours. A transport failure alone advances transport backoff. If an upload
  resolution arrives but its local acknowledgement/backoff state cannot commit, the client returns
  `.persistenceFailed`, keeps the prior local authority, and does not relabel it as a network
  failure. C5-02 must therefore deduplicate accepted event IDs when an acknowledgement cannot be
  persisted. Disabled, unavailable, rejected, cancellation, persistence, or network
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
  dormant C5-01 client retains deletion proofs but has no live request to cancel. C5-02 requires
  idempotent event acceptance and proof deletion endpoints for exact retries after local commit/cleanup
  failures.

### Verification

- Twenty-one deterministic tests cover default-off zero-write including repeated disable against
  real encrypted persistence, exact event JSON, app-version rejection, injected user-calendar
  behavior across daylight-saving time, upload-envelope pseudonym non-reuse, the four-generation
  re-enable boundary,
  concurrent mutation ordering, queue overflow, manual and automatic rotation, single-generation
  batching, concurrent capture during upload, concurrent-flush transport serialization, bounded
  retry with capture still available during backoff, typed local-persistence failure after a remote
  upload resolution, idempotent delete retry after local cleanup failure, explicit grouped deletion,
  deletion-proof retention/destruction, sticky corrupt persistence, corrupt-state file/key deletion,
  and authenticated-encryption round trip.
- Focused simulator execution passes 21/21. The self-testing static telemetry gate and repository
  diff check pass.
  The owning unrestricted `Scripts/validate.sh` run also passes every static contract, Release
  compilation, the strict 10,000-row Dashboard wall-clock stage, 538 unit tests across 32 suites,
  all 17 UI tests, and every selected coverage threshold; four opt-in physical CloudKit probes are
  reported as skipped, and `CSVExporter.swift` remains the minimum selected coverage result at
  87.60% against 85%. Exact final head `d937dc8` then passed GitHub Actions run `33085630481`, and
  PR #76 merged it as `68304ad`. Neither run nor merge is presented as endpoint, receiver, TTL,
  deletion-service, customer-control, App Privacy, or network evidence.

## C5-02 — Minimal ingest and deletion

Status: **Done after independent review of exact head `72abf4b`, green GitHub Actions run
`33176551566`, and PR #78 merge `4715054`.**

Own the independent serverless receiver, strict request-byte schema, environment separation,
unknown/free-text rejection, real retention and deletion behavior, abuse/cost ceilings, monitoring,
the smallest reviewed client network adapter, non-retention of deletion-request cross-generation
association, and the explicit in-flight opt-out cancellation policy. It may not infer C5-03 metrics
or C5-04 release approval.

### Accepted C5-02 boundary

- The exact first-party hosts are `mindbudget-telemetry-dev.yehao1105.workers.dev`,
  `mindbudget-telemetry-staging.yehao1105.workers.dev`, and
  `mindbudget-telemetry.yehao1105.workers.dev`. Each environment owns a distinct Worker, D1
  database, and rate-limit namespaces. Development may be deployed and probed in this package;
  Staging and Production remain configuration-only until their later owner gates.
- Upload is anonymous `POST /v1/events`; deletion is proof-authenticated `POST /v1/delete`.
  Requests are bounded JSON with exact keys and duplicate-key rejection, no cookies, authorization header, query,
  redirect, caller URL, arbitrary property map, or free text. The client sends the fixed
  `User-Agent: MindBudget`, explicitly suppresses `Accept-Language`, and the receiver rejects any
  variable user-agent or nonempty language value so build, OS, and locale do not enter this
  channel. Success/rejection/retry responses are empty and status-coded; the client buffers at
  most 1 KiB of response data.
- An upload contains at most 20 events and 32 KiB. D1 enforces one deletion handle per pseudonym
  and one exact row per event UUID. An identical accepted event is idempotent; the same UUID with
  different facts rejects the whole batch. A previously deleted pseudonym/handle pair accepts but
  discards a late identical upload so deletion cannot be undone by an older in-flight request.
- A delete request contains at most four UUID/32-byte-secret proofs and 2 KiB. SHA-256 proof
  comparison authorizes deletion. All proof pairs pass or none mutate. The grouped association
  exists only in request-local memory/SQL parameters: storage contains independent per-generation
  tombstones and never a deletion request, group ID, proof list, IP, exact acceptance timestamp, or
  association row. Tombstones retain only a coarse UTC-day expiration bucket shared by every
  delete accepted that day; this can reveal the broad expiry day but cannot preserve a
  request-unique grouping key. Identical retries are successful.
- Events and identities expire no later than `acceptedAt + 90 * 24 hours`; deletion tombstones use
  the earlier-or-equal UTC-day bucket for the same maximum. This is a server maximum-duration
  privacy bound, not a user-calendar UI date. Each hourly UTC Cron transaction deletes at most
  1,000 rows per table and repeats those bounded transactions until no expired batch remains, so
  the maximum does not depend on the backlog fitting in one hourly batch. Request paths also prune
  the addressed expired identity.
- Edge-derived IP and pseudonym rate limits are permissive abuse buffers, not accounting or delete
  authority. Every request has fixed body, batch, D1-statement, and CPU ceilings. Persistent Worker
  logs disable invocation metadata and contain only sampled closed route/reason/environment codes;
  request bodies, IPs, pseudonyms, event IDs, app versions, handles, secrets, and grouped proofs are
  never logged.
- Opt-out makes local state disabled and clears unsent events, then best-effort cancels the active
  upload transport. It cannot truthfully revoke a response already accepted at the edge; a raced
  accepted event remains subject to the real TTL and explicit delete. Server tombstones make a
  later in-flight upload non-resurrecting. C5-04 owns the customer-facing wording.
- `FixedTelemetryTransport` is compiled and directly testable but is not constructed by production
  app code. `UnavailableTelemetryTransport` remains the `TelemetryClient` default, and there are
  still zero capture call sites and zero customer telemetry egress until C5-04 accepts controls and
  disclosure.
- Only Development is deployed: `mindbudget-telemetry-dev` version
  `1c162a57-8789-4f7f-9fec-f2c484e9f4f2` owns D1
  `2faff8ac-de17-4fd0-aaa7-546bd1902e74`. Its exact live probe accepted one upload and an identical
  retry, atomically rejected a changed `appVersion` under the same event UUID, authenticated a
  proof delete, accepted-but-discarded a late matching upload, and ended with 0 event rows,
  0 identity rows, and 2 independent tombstones. Staging has only the isolated, unmigrated,
  undeployed D1 resource `776d171d-ec10-4a90-9235-b537e063e04b`; Production has no provisioned D1
  resource and the checked-in UUID is an intentionally invalid placeholder. Neither environment
  has a deployed Worker or probe evidence.
- Fixed endpoint-policy failures such as HTTP 404, 405, and 421 still surface as typed rejected
  statuses in the dormant adapter. C5-04 must make them terminal/non-retrying before constructing
  the transport; C5-02 does not enlarge the local lifecycle state machine while no call site exists.

## C5-03 — Metrics and G1 evidence

Status: **Blocked pending explicit owner entry after C5-02 closeout.**

Own exact App Store and voluntary telemetry numerators/denominators, confidence intervals, coverage
reporting, survey workflow, and the receipt funnel without expanding captured fields.

## C5-04 — Operations and disclosures

Status: **Blocked by C5-03.**

Own the publish/rollback/key-rotation runbook, customer control and bilingual disclosure, privacy
policy/App Privacy/data-flow updates, capture audit, and actual TTL/deletion verification.

## Exit and stop conditions

C5-01 and C5-02 may be Done only after exact-head independent review, green hosted CI, and merge.
COM-C5 is not Done until C5-03 and C5-04 prove a content-free, optional, deletable, observable, and
cost-bounded real channel. Stop on any content-bearing field, arbitrary dictionary/string, implicit
collection, identifier reuse across opt-out, lost deletion proof, unencrypted/unbounded queue,
an unqualified claim that deletion requests are unlinkable, unaccepted domain, environment mixing,
product-behavior dependency, or release claim.
