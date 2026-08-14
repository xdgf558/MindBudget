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

Status: **Implementation complete pending independent review, green CI, and merge.**

### Tasks

- Add a voluntary Settings entry and explicit value-trigger entry; never interrupt launch,
  recording, export, deletion, app lock, or another Free trust path.
- Present the exact Monthly/Annual StoreKit catalog. Display `Product.displayPrice`, subscription
  period, and StoreKit-derived introductory-offer eligibility; never hardcode a customer currency,
  converted regional price, or eligibility promise.
- Explain the currently delivered Pro value only: Apple on-device wording enhancement,
  non-24-hour cooling-off choices, and advanced Siri actions. Do not advertise cloud AI, quotas,
  Lifetime, Watch, iCloud, receipt capture, telemetry, or another deferred product.
- Route purchase and restore only through the existing typed `AppSession`/`EntitlementStore`
  seams. Pending, cancelled, unavailable, verification, and invalid-state outcomes use neutral
  localized copy and never grant locally.
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

Status: **Blocked until C3-01 is independently reviewed, green, and merged.**

C3-02 owns actual trial activation/renewal reminder scheduling and cancellation/rescheduling. The
7-day test offer in C3-01 is presentation and StoreKit Configuration evidence only.

## C3-03 — Signed public configuration

Status: **Blocked until C3-02 is complete and an exact first-party configuration contract is
accepted.**

## C3-04 — UI and release quality

Status: **Blocked until C3-03 is complete.**

The post-0.9.6 release hold remains active throughout COM-C3. No C3 implementation is a public or
TestFlight distribution authorization by itself.
