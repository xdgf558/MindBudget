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

Status: **Blocked pending an explicit owner instruction and an accepted exact first-party
configuration contract.**

## C3-04 — UI and release quality

Status: **Blocked until C3-03 is complete.**

The post-0.9.6 release hold remains active throughout COM-C3. No C3 implementation is a public or
TestFlight distribution authorization by itself.
