# COM-C3 Execution Packet

## Input gate

Status: **Satisfied for C3-01 test presentation only — 2026-08-14.**

The owner explicitly authorized C3-01 with provisional, nonpublic test terms:

- Monthly test anchor: **US$1.99**.
- Annual test anchor: **US$19.99**.
- Introductory offer: **7-day free trial for StoreKit-eligible subscribers**.
- First test storefront set: **Hong Kong (HKG), United States (USA), Singapore (SGP), and
  Taiwan (TWN)**.

These inputs authorize local Configuration/Sandbox/TestFlight presentation testing. They are not
accepted final regional economics, do not authorize app-owned conversion into local currencies,
and do not authorize formal App Store Connect products, Archive/upload, tester assignment, or
distribution. Every customer-facing amount and eligibility result comes from StoreKit.

## C3-01 — Transparent paywall

Status: **Done after independent review, green CI, and merge through PR #33 (`747b628`).**

### Tasks

- Add a voluntary Settings entry and explicit value-trigger entry; never interrupt launch,
  recording, export, deletion, app lock, or another Free trust path.
- Present the exact Monthly/Annual StoreKit catalog. Display `Product.displayPrice`, subscription
  period, and StoreKit-derived introductory-offer eligibility; never hardcode a customer currency,
  converted regional price, or eligibility promise. The P1W offer is exact only in the isolated
  test fixture; production treats any valid StoreKit introductory offer as optional presentation
  data and never makes paid authority depend on its presence or duration.
- Preserve StoreKit's introductory-offer payment mode and localized offer price. C3-01 supports
  only an eligible `.freeTrial`; an eligible paid installment, paid-up-front, or unknown future
  mode must pause purchase in both the View and source adapter instead of falling back to standard
  renewal disclosure. Offer shape never affects existing entitlement authority.
- Explain the currently delivered Pro value only: Apple on-device wording enhancement,
  non-24-hour cooling-off choices, and advanced Siri actions. Do not advertise cloud AI, quotas,
  Lifetime, Watch, iCloud, receipt capture, telemetry, or another deferred product.
- Route purchase and restore only through the existing typed `AppSession`/`EntitlementStore`
  seams. Pending, cancelled, unavailable, verification, and invalid-state outcomes use neutral
  localized copy and never grant locally.
- Require an actionable entitlement snapshot before purchase at both the View and actor boundary.
  When authority is unavailable, pause purchase and offer an explicit user-initiated recheck;
  never infer confirmed Free from a live catalog.
- Add user-initiated Restore Purchases and Manage Subscription controls, plus accessible local
  subscription/privacy explanations. Never invoke `AppStore.sync()` or a management sheet without
  an explicit tap.
- Keep paywall frequency at zero automatic presentations in C3-01. Settings and explicit Pro value
  triggers are the only entry points; C3-02 owns trial lifecycle reminders.

### Tests

- Exact StoreKit catalog remains Monthly/Annual only, one group, P1M/P1Y, no Family Sharing, no
  Lifetime, with a single P1W free-trial test offer on each product.
- Live presentation uses StoreKit display values and eligibility; cached/unavailable presentation
  never advertises an unverified trial or invents a price.
- Production catalog/authority tests prove that removing or changing the introductory offer does
  not invalidate the stable Monthly/Annual subscription contract. The dedicated fixture/runtime
  tests alone retain the exact P1W assertion.
- Eligible `.payAsYouGo` and `.payUpFront` fixtures retain their StoreKit offer prices/modes and
  disable purchase; an unknown future mode fails the same way, while an ineligible paid offer does
  not block the account's ordinary subscription terms.
- Renewal disclosure follows the injected app locale even when the device/process locale differs.
- Unavailable entitlement authority blocks the purchase surface and the actor before any source
  purchase call; recheck remains explicit.
- Purchase outcome matrix covers success, pending, cancellation, unavailable product, disallowed
  purchases, verification failure, invalid state, and neutral fallback.
- Restore covers restored, no active subscription, and neutral failure; no implicit restore runs.
- HKG, USA, SGP, and TWN runtime probes execute rather than skip under the dedicated non-Archive
  StoreKit scheme before this packet can be marked Done.
- Bilingual copy, VoiceOver labels, Dynamic Type, light/dark appearance, and exact Free-to-Pro-to-
  Free snapshot replacement remain regression gates.

Candidate evidence: final Xcode 26.6 `17F113` ran the dedicated non-Archive scheme on the physical
`拉沙的iPhone` (`iPhone Air`) with final iOS 26.6.1 `23G82`. All 9 catalog/lifecycle tests passed
with 0 failures and 0 skips: the HKG, USA, SGP, and TWN product probes each loaded the exact
Monthly/Annual catalog and P1W offers, and the Monthly/Annual transaction probes verified,
granted, and finished through the production authority. Result bundle:
`/private/tmp/MindBudget-C301-Storefronts-Physical.xcresult`.

### Stop conditions

- Stop if a displayed amount is not the StoreKit-provided value for the current storefront.
- Stop if an ineligible or unverified account is promised a trial.
- Stop if purchase, restore, or subscription management can run without an explicit user action.
- Stop if a deferred feature or final-price promise appears in customer-facing copy.
- Stop if any app-owned HTTP(S), raw receipt path, manual entitlement, formal product creation,
  version/archive/upload/tester assignment, or distribution action enters this packet.

## C3-02 — Trial lifecycle

Status: **Done after independent review, green CI, and merge through PR #34 (`12d9217`).**

C3-02 owns actual trial activation/renewal reminder scheduling and cancellation/rescheduling. The
7-day test offer in C3-01 is presentation and StoreKit Configuration evidence only.

### Input gate

- C3-01 passed independent review and green CI and merged through PR #33 as `747b628` on
  2026-08-14. GitHub Actions run `31766128587` is green.
- `EntitlementStore` remains the only StoreKit lifecycle authority. A presentation offer, cached
  catalog, configured P1W fixture, or local flag may never create a trial lifecycle.
- StoreKit's verified current transaction must identify an introductory free trial. Separately
  verified renewal information supplies the actual `renewalDate` and `willAutoRenew` facts, plus
  the current trial product and optional next-period `autoRenewPreference`.

### Tasks

- Publish one process-local `TrialLifecycleProjection` from the existing entitlement snapshot.
  Keep the product carrying the current trial separate from the verified next-renewal product;
  prefer an accepted `autoRenewPreference` for renewal display and fall back to the current
  product only when that preference is absent. Never persist the projection as a commercial right
  or reconstruct it from the seven-day fixture.
- Reconcile one stable local-notification request five calendar days before a reliable future
  renewal date using the person's `Calendar` and `TimeZone`. The notification is generic and
  contains no date, price, amount, product, or remaining-day count. It says the trial ends soon
  and asks the person to review current status; it never claims auto-renew is still enabled because
  the pending request can outlive the app process.
- Remove or replace the stable request when the trial ends, auto-renew is disabled, StoreKit
  authority disappears, a refund/revocation occurs, the product changes, or the renewal date
  changes. Remove the old request before adding a replacement so a failed add cannot leave stale
  billing information scheduled.
- Never request notification authorization from lifecycle reconciliation. Disabled, denied, or
  undetermined notification state and a passed T−5 window use a noninterrupting in-app card.
  A missing/unreliable date schedules nothing.
- Show the verified renewal date in app and combine it only with a current live StoreKit price.
  Missing catalog data must not resurrect cached price in renewal disclosure.

### Tests

- Pure mapping tests prove that only an accepted subscribed transaction may carry a matching trial
  projection and that inconsistent product/state facts fail closed. A regression changes only
  the verified `autoRenewPreference` while keeping the renewal date fixed, then proves the
  projection changes and live price lookup follows the next-renewal product.
- Deterministic scheduler tests cover exact calendar T−5 calculation, notification disabled/
  denied/not-yet-authorized fallback, missing/past dates, auto-renew off, revoke/absence, product
  and renewal-date replacement, failed replacement cleanup, stable identifiers, and generic
  bilingual copy without private or commercial details.
- The opt-in local StoreKit Monthly/Annual flows are the only framework-backed evidence that real
  `Transaction.offer`, verified renewal information, `renewalDate`, and `willAutoRenew` derive the
  production projection. Construction-based unit tests prove consumption, not that private bridge.
- Final Xcode 26.6 `17F113` on physical `iPhone Air`, final iOS 26.6.1 `23G82`, passed the full
  dedicated suite 9/9 with no failure or skip, including HKG/USA/SGP/TWN and both Monthly/Annual
  trial-lifecycle derivation paths. Evidence: `/private/tmp/MindBudget-C302-Physical4.xcresult`.
- Run every repository gate and the default Swift/UI/coverage validation before requesting review.
  A skipped, hung, simulator-only verification failure, or empty xcresult is non-evidence.
- Review remediation evidence: the dedicated trial suite passed 13/13 and the owning full run
  produced 382 results (376 passed, 6 explicit opt-in StoreKit runtime probes skipped, 0 failed),
  including all 14 UI tests and every selected coverage threshold. Evidence:
  `/private/tmp/MindBudget-C302-ReviewFix-Trial2.xcresult` and
  `/private/tmp/MindBudget-C302-ReviewFix-Full.xcresult`.

### Stop conditions

- Stop if a configured duration, presentation eligibility, cached offer, or hardcoded seven-day
  value can create or preserve an active-trial projection.
- Stop if a reminder can expose date, price, amount, product, note, ledger content, or a fixed day
  count; assert that a trial will renew after the app process can no longer observe cancellation;
  prompt for permission automatically; survive cancellation/revocation/date change; or use fixed
  seconds instead of calendar arithmetic.
- Stop if a scheduled plan switch displays the current trial product's price instead of the
  accepted next-renewal product.
- Stop if an unavailable StoreKit fact is treated as a reliable date, if cached price appears in
  renewal disclosure, or if C3-03/config, formal products/economics, versioning, Archive/upload,
  tester assignment, or distribution enters this packet.

## C3-03 — Signed public configuration

Status: **Done after independent review, green CI, and merge through PR #38 (`db7926d`).**

Owner instruction: on 2026-08-14 the owner accepted the recommended exact contract in
`PUBLIC_CONFIGURATION_CONTRACT.md` and authorized C3-03. DEC-COM-021 owns this boundary.

### Input gate

- C3-01 and C3-02 are Done through PRs #33 and #34.
- The exact Development, Staging, and Production hosts; anonymous `GET /v1/config`; outbound
  metadata; Ed25519 envelope; seven-day maximum validity; conservative fallback; and closed
  presentation vocabulary are Accepted in DEC-COM-021.
- The post-0.9.6 release hold remains active. This packet does not accept final economics,
  formal products, Archive/upload, tester assignment, or distribution.

### C3-03A — Signed document, verification, and local resolution

Status: **Done after independent review, green CI, and merge through PR #36 (`1ebb36c`).**

Completion evidence: the review-remediation head `3a53107` passed GitHub Actions run
`31856271268`; PR #36 merged to `main` as `1ebb36c` on 2026-08-15. The final owning local run
produced 394 results: 388 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed.

#### Tasks

- Define an exact JSON envelope whose Ed25519 signature covers the exact decoded payload bytes.
- Reject unknown/missing fields, algorithm/key/schema/version errors, invalid encoding/signature,
  oversized documents, future issuance beyond bounded skew, expired payloads, and validity windows
  longer than seven 24-hour intervals.
- Keep the v1 payload vocabulary closed to the single optional-presentation field
  `proValueTriggersEnabled`, whose built-in conservative value is `false`.
- Persist only the signed envelope, highest accepted version, and SHA-256 payload digest. Publish a
  remote value only after durable persistence succeeds. Reject lower versions and same-version
  equivocation; corrupted rollback state cannot be overwritten silently and remains a sticky
  Release fail-closed state until the app data container is deleted and the app is reinstalled.
- Require exact whole-second UTC timestamps and no duplicate JSON keys while continuing to verify
  exact signer bytes rather than defining a client-side canonical JSON encoder.
- Serialize concurrent remote acceptance across read/compare/write/read-back, then re-read and
  re-verify the exact intended snapshot through the persistence abstraction before returning a
  remote resolution.
- Add a standalone static contract gate and run it in local validation and CI. C3-03A contains no
  `URLSession`, URL, endpoint, embedded Production public key, entitlement/StoreKit authority, or
  application integration.

#### Tests

- Valid Ed25519 envelope and closed payload decoding.
- Invalid signature/key/algorithm/encoding and unknown envelope/payload/nested fields.
- Schema/version/clock/expiry/validity/size boundaries.
- Fixed-timestamp golden bytes, fractional-timestamp rejection, duplicate envelope/payload keys,
  and zero-length validity windows.
- Rollback, same-version equivocation, cache expiry, cache digest mismatch, corrupt persistence,
  malformed high-water records, concurrent high-water ordering, no-op persistence, and save-before-
  publish failure.
- Atomic file-protected persistence round trip, readback verification, and conservative built-in
  fallback.

#### Stop conditions

- Stop if configuration can name a product, price, trial, entitlement, notification, Lifetime,
  iCloud, cloud AI/provider/model/quota, receipt, telemetry, Watch, or arbitrary feature.
- Stop if a cache can grant paid access, an invalid/expired/rolled-back document can activate a
  value, persistence failure can publish, concurrent acceptance can lower the high-water mark,
  duplicate/unknown JSON is ignored, or Release code can reset corrupt rollback state.
- Stop if a URL, transport, Production public key, Worker deployment, Release egress exception, or
  presentation consumer enters C3-03A.

### C3-03B — Fixed transport and presentation integration

Status: **Done after independent review, green CI, and merge through PR #38 (`db7926d`).**

C3-03B may add only the exact anonymous environment-isolated transport and the
single verified presentation consumer accepted in `PUBLIC_CONFIGURATION_CONTRACT.md`. It must
inspect the real Worker, platform logs/analytics and TTL, redirects/cache headers, request and
response bounds, public key provenance/rotation boundary, captured traffic, final binary, privacy
copy, timeout/cancellation, and offline/invalid-signature behavior. It must not expand the payload
vocabulary or make configuration an entitlement, price, trial, or release authority.
It also owns closed non-content reason codes for rejected configuration operations; payload and
signature bytes are never logged. C3-03A intentionally adds no logging sink before that real
transport/operations boundary exists.

Implementation evidence on 2026-08-15:

- One centralized adapter contains the exact three HTTPS URLs; Release selects only Production,
  Debug defaults to Development, and a Debug-only launch argument selects Staging. The session is
  ephemeral, cookie/credential/cache-free, redirect rejecting, time/size bounded, and accepts only
  the exact URL, status, MIME, signed-envelope size, method, and bounded metadata headers.
- Review remediation samples verification time only after the response completes, propagates
  caller cancellation into the owned transport/acceptance task, and carries the signed expiry into
  AppSession so an enabled presentation clears at expiry even while continuously foregrounded.
- Follow-up cancellation remediation makes startup refresh a separately structured SwiftUI task,
  retains scene-active refresh for explicit replacement/background/Session-destruction
  cancellation, resets canceled startup attempts so recreated SwiftUI tasks can retry, and defines
  the last pre-atomic-write cancellation check as the persistence
  commit point. Cancellation before that point cannot change the cache; a commit already in
  progress may finish but can never publish a canceled acceptance result.
- The follow-up owning validation produced 410 results: 403 passed, 7 explicit opt-in/runtime
  skips, and 0 failed. All 396 unit tests and 14/14 UI tests passed, together with the Release
  build, static gates, and selected coverage thresholds. Evidence:
  `/private/tmp/MindBudget-C303B-CancellationFix-FullFinal2.xcresult`.
- The app embeds only public key `mb-config-2026-01`. The protected private key remains outside the
  repository and is used only by the local signing utility. The single consumer can expose an
  optional AI Pro-value trigger only when the signed flag is true and StoreKit has published an
  actionable exact-Free whole snapshot. Initial, incomplete, unverified, mixed, unavailable, and
  previously-paid-then-unverifiable authority cannot expose it; permanent Settings, restore,
  manage, and subscription-status entry points remain.
- The independent Worker has exact Development/Staging/Production configuration, per-environment
  60-request/60-second rate-limit namespaces, `no-store`, no redirects, no outbound fetch, no
  private key, no storage or analytics binding, and disabled platform observability. Closed client
  diagnostics contain only typed reason codes.
- Development version `bf6c5049-a389-4ea7-af0a-e8425b8957e2` was deployed. The dedicated
  non-Archive `MindBudget-PublicConfig-Live` scheme exercised the real Development endpoint through
  the app transport, embedded key, verifier, cache, and consumer seam: 8 passed, 0 failed, 0
  skipped at `/private/tmp/MindBudget-C303B-LiveWorkerFinal.xcresult`. Worker tests passed 13/13;
  typecheck, high-severity dependency audit, and Production-config dry-run passed.
- The reviewed head `09c382e` passed GitHub Actions run `31873664396`; PR #38 merged to `main` as
  `db7926d` on 2026-08-15. Staging and Production were not deployed. Final Release binary/
  Production traffic, current privacy/review disclosure, Archive/upload, tester assignment, and
  distribution remain pending; closing C3-03B moves none of those gates.

## C3-04 — UI and release quality

Status: **Implementation complete pending independent review and green CI.**

The post-0.9.6 release hold remains active throughout COM-C3. No C3 implementation is a public or
TestFlight distribution authorization by itself.

### Tasks

- [x] Map only verified billing-grace/retry/expired/revoked states into bilingual presentation;
  never infer a state from price, trial, cached presentation, or signed configuration.
- [x] Keep the soft landing non-blocking: one Dashboard navigation card and one Pro-screen status
  section with explicit Manage Subscription and Recheck actions; never present an automatic modal.
- [x] Preserve Pro in grace, exact Free/local data in retry/expired/revoked, and block a second
  purchase during grace/retry or any unavailable authority.
- [x] Reflow plan rows at accessibility text sizes and provide explicit localized VoiceOver
  labels, selected state, hints, and non-color-only status across all three appearances. The Pro
  surface applies the currently selected skin's light/dark preference locally so a rapid skin
  change cannot pair new row backgrounds with stale system text colors.
- [x] Remove fixture-only trial duration from customer terms and align privacy, App Review,
  screenshot, and Archive checks with the implemented StoreKit and signed-config boundaries.

### Tests

- Pure presentation tests cover every exceptional state, purchase gating, bilingual status copy,
  and app-locale VoiceOver labels containing StoreKit-supplied prices.
- The dedicated AX5 UI test selects Aurora Glow, Warm Botanical, and Neon Pulse, captures each Pro
  surface, and verifies purchase/restore/manage controls stay inside the visible screen. A disabled
  purchase button must remain visible and legible; Restore and Manage remain actionable. The three
  retained captures also require manual contrast inspection rather than treating element existence
  as visual evidence.
- Full validation must pass localization parity, Release build, unit/UI suites, coverage, StoreKit
  isolation, signed-config/network, documentation, and money gates before this candidate can be
  called implementation complete.

### Stop conditions

Stop on an automatic blocking paywall, unavailable-as-Free presentation, local-data removal,
fixture price/trial customer copy, color-only state, clipped AX5 action, deferred product claim,
Production/Staging deployment, or any Archive/upload/tester/distribution action.
