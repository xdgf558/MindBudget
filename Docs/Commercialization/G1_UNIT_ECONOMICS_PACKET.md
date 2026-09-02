# G1 Cloud AI Unit Economics and Credit-Pack Packet

Status: **In Progress after owner acceptance of the Luna-only offer policy.** PR #98 exact head
`9226985` passed GitHub Actions run `33570570896` and merged as `6e2d242`; DEC-COM-094 closed that
first quote/planning package with the historical result `INSUFFICIENT_QUOTE_EVIDENCE`. DEC-COM-095
now accepts the product-policy boundary below. DEC-COM-096 freezes the 24-case bilingual Eval and
accepts the exact 10-credit starter plus three usage-card tiers. DEC-COM-098 records the admitted
synthetic account and attempt 3's 24/24 first-pass automated result after two explicit non-passes.
PR #100 independent review read all 24 outputs with no P1/P2; reviewed head `323d8d7` passed hosted
run `33593253561` and merged as `7a473d2`. DEC-COM-099 closes only that independently reviewed
account/Eval evidence delivery. The current formal state is
`EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`, not
`PROCEED_TO_R2`.

## Accepted owner policy

The owner accepted these launch-policy constraints on 2026-09-02:

- the formal Pro offer is a US$4.99 non-consumable one-time purchase, not a subscription;
- a new user may explicitly start one 30-user-calendar-day local Pro trial; it does not auto-renew,
  does not call OpenAI, and grants zero Luna credits;
- on-device Apple AI is included with local Pro when the device supports it; lack of device support
  uses the deterministic local template and never creates a free cloud substitute;
- only a verified US$4.99 Pro purchase grants the later accepted finite starter-credit lot;
- additional cloud use is sold only through separately confirmed consumable usage cards;
- OpenAI `gpt-5.6-luna` is the only permitted cloud model. There is no second provider, provider
  failover, or direct client-to-provider request; failure falls back locally;
- every buyout/card SKU must preserve at least 50.00% contribution margin under the reviewed peak
  envelope after Apple commission, tax/FX and refund reserves, Luna attempts, backend cost, and the
  provider safety reserve;
- ordinary TestFlight, StoreKit Sandbox, simulator, and UI-test users cannot send real Luna
  traffic. Apple App Review may use one separately reviewed, isolated, hard-capped review path;
- starter and purchased credits expire one user-calendar year after their server-recorded grant;
- Family Sharing and automatic top-up are off; and
- a local-only public build remains a valid release candidate if the cloud gates never pass.

This decision supersedes the launch hypothesis of Monthly/Annual subscriptions, a StoreKit
introductory trial, and a multi-provider cloud router. The completed Monthly/Annual/P1W
Configuration and TestFlight evidence remains historical test evidence only; no sandbox or
TestFlight entitlement is grandfathered into permanent Pro or cloud credits. Because no prior
commercial product launched, later implementation may retire that test catalog and replace it with
new non-consumable/consumable Product IDs after G1 authorizes the work. This packet performs no
production Swift, Product ID, App Store Connect, credential, backend, ledger, or provider mutation.

## Decision and evidence boundary

DEC-COM-092 first authorized the buyout-plus-credits analysis. DEC-COM-093 returned the historical
interim result `INSUFFICIENT_QUOTE_EVIDENCE`; DEC-COM-094 records independent review of that first
arithmetic package. DEC-COM-095 is a later owner decision: it selects product/model/privacy policy
but deliberately does not invent measured token, quality, latency, or failure distributions.

The packet separates:

1. **Accepted product policy**: US$4.99 one-time Pro, local-only 30-day trial, Luna-only paid cloud
   credits, one-year credit validity, no ordinary test traffic, and a 50% downside margin floor.
2. **Quote-backed planning arithmetic**: deterministic integer micro-USD calculations from dated
   supplier rates and explicit planning workloads.
3. **Missing release evidence**: live bilingual Luna results, OpenAI account admission, reviewed
   server/ledger behavior, exact StoreKit price-point configuration, and final-binary/review proof.

Money in the executable worksheet is integer micro-USD. Percentages are integer basis points.
`Scripts/g1_unit_economics.py` contains explicit-failure self-tests that remain effective under
`python3 -O`.

## Frozen planning inputs

| Input | Frozen value | Evidence/qualification |
|---|---:|---|
| Quote retrieval date | 2026-09-02 | Official pages opened directly; re-quote before implementation if older than 30 days |
| Quote currency/base storefront | USD / USA | USA is the base price; actual realized proceeds require post-launch transactions |
| Accepted Pro base price | US$4.99 | Owner-accepted policy; no formal Product ID exists yet |
| Commission downside | 30% | Small Business Program participation remains account-unverified |
| Tax/FX reserve | 10% of customer price | Conservative pre-launch reserve, not claimed actual tax |
| Refund reserve | 5% of customer price | Conservative pre-launch reserve, recalibrated after real transactions |
| Minimum contribution margin | 50.00% | Applies separately to every offered SKU under the reviewed peak envelope |
| Backend planning floor | 1,000 successful uses/month | 100/500/10,000 sensitivity remains visible |
| Provider safety reserve | 20% of Luna attempt cost | Engineering reserve, not an observed failure rate |
| Trial cloud allocation | 0 | Trial is local Pro plus supported on-device AI only |
| Credit validity | One user-calendar year | Persist an authoritative expiry instant; never use `365 * 86400` |

Apple states that proceeds equal customer price minus applicable taxes and commission. Actual
realized USA proceeds cannot exist before paid transactions and settlement. G1 therefore uses the
30% downside and reserves above; App Store Connect Sales and Trends/financial proceeds become a
post-launch recalibration input rather than an impossible pre-launch exit gate.

Primary evidence retrieved 2026-09-02:

- OpenAI Luna model/pricing: <https://developers.openai.com/api/docs/models/gpt-5.6-luna>
- OpenAI API data controls:
  <https://platform.openai.com/docs/models/default-usage-policies-by-endpoint>
- Apple proceeds and payments:
  <https://developer.apple.com/help/app-store-connect/getting-paid/view-payments-and-proceeds>
- Apple Small Business Program: <https://developer.apple.com/app-store/small-business-program/>
- Cloudflare Workers pricing: <https://developers.cloudflare.com/workers/platform/pricing/>

## Luna-only task and privacy boundary

One credit may fund only an explicit user-initiated, short, structured coaching analysis that
consumes already-computed allow-listed facts. The same rule applies to every future feature that
needs cloud AI:

- explain a deterministic budget status, pattern, or safe-to-spend result in supportive language;
- compare a bounded set of deterministic options without choosing or changing money values;
- rewrite an already-computed plan or reminder in Simplified Chinese or English; and
- return one bounded structured response that Swift validates before display.

Receipt image/OCR/line items, raw transaction rows, notes, merchant lists, original free-form
questions/reasons, stable identifiers, tools, web search, files, provider conversation state, and
model-authoritative money/rules/actions remain forbidden. OpenAI receives no direct client request.
Client and future server redaction must both pass before a request can reach Luna.

The fixed synthetic Luna Eval additionally requires the owner-observed Global project, no voluntary
training/data sharing, disabled API call logging, accepted standard up-to-30-day retention, usable
billing/rate tier, Luna-only allow-list, and an isolated credential. DEC-COM-097 makes ZDR optional
for that synthetic run. Production remains separately blocked until consent, processor terms,
server isolation, and release evidence match the controls actually configured.

## Luna quote and planning workload

The official OpenAI model page quotes `gpt-5.6-luna` at US$0.20/M input, US$0.02/M cached input, and
US$1.20/M output, with structured output support. This worksheet uses US$0.22/M input and
US$1.32/M output after the documented 10% regional-processing planning uplift. It uses no batch,
cache, tool, free-tier, promotional, or service-credit discount.

These workloads are frozen engineering envelopes, not measured distributions:

| Profile | Billed Luna attempts | Input/output per attempt | Outcome |
|---|---:|---:|---|
| typical/P50 planning envelope | 1 | 2,000 / 500 | One schema-valid result |
| peak/P95 planning envelope | 2 | 8,000 / 1,500 each | One unusable attempt plus one bounded same-model retry producing a schema-valid result |

There is no provider failover. A timeout, cancellation, provider rejection, or invalid final output
releases the reserved customer credit and returns the local fallback. One user-initiated analysis
commits one credit only after a valid structured Luna result is ultimately displayed. A user-requested
regeneration is a new analysis and reserves a new credit.

## First-party backend envelope

The planning backend remains one isolated Cloudflare Workers service plus D1. The conservative
model allocates the full US$5 Workers minimum and a separate US$5 monthly incident/support reserve,
plus one request, 20 CPU ms, eight D1 reads, six writes, and one content-free log event per
successful use. At 1,000 successes, backend allocation is US$0.010010 per successful use.

App Attest, StoreKit/App Store Server verification, secrets, deletion, configuration, ledger
idempotency, and monitoring are represented inside this envelope. A later implementation quote
must reopen anything not actually covered.

## Reproducible cost result

At 1,000 successful uses/month:

| Component | typical/P50 planning | peak/P95 planning |
|---|---:|---:|
| Luna provider attempts | US$0.001100 | US$0.007480 |
| 20% provider reserve | US$0.000220 | US$0.001496 |
| Backend + incident allocation | US$0.010010 | US$0.010010 |
| **All-in successful use** | **US$0.011330** | **US$0.018986** |

These values are intentionally discontinuous with PR #98's first planning package. The later
owner policy removed a US$2 local-Pro reserve from the cloud budget, removed a separate 50% cloud
safety holdback, and selected Luna without a billed backup provider. That changed peak all-in cost
from US$0.033098 to US$0.018986 and maximum fulfillment cost at the 50% margin floor from
US$0.372250 to US$1.372250. This is a policy/model change, not improved measured performance.

| Successful uses/month | Typical all-in/use | Peak all-in/use |
|---:|---:|---:|
| 100 | US$0.101330 | US$0.108986 |
| 500 | US$0.021330 | US$0.028986 |
| 1,000 | US$0.011330 | US$0.018986 |
| 10,000 | US$0.002330 | US$0.009986 |

The fixed US$10 monthly backend/reserve makes low-volume economics materially worse. Before any
card or starter grant exists, COM-C9/C11 must implement a server-enforced acceptance gate based on
the trailing portfolio contribution margin, not merely token price. A gate trip stops new card
sales and new cloud-enabled offers while honoring unexpired purchased credits and leaving local Pro
untouched. It must also trip when the reviewed peak cost exceeds its accepted envelope, Luna rates
rise at least 20%, quote age exceeds 30 days, or privacy/region terms change.

## US$4.99 starter analysis

The conservative pre-launch proceeds estimate is:

| Item | Micro-USD | USD |
|---|---:|---:|
| Customer price | 4,990,000 | US$4.990000 |
| Less 30% commission | 1,497,000 | US$1.497000 |
| Less 10% tax/FX reserve | 499,000 | US$0.499000 |
| Less 5% refund reserve | 249,500 | US$0.249500 |
| Conservative net | 2,744,500 | US$2.744500 |
| Maximum fulfillment cost at 50% margin | 1,372,250 | **US$1.372250** |

That ceiling funds at most 121 typical-envelope uses or a maximum of 72 peak-envelope starter uses.
This mathematical maximum is not a recommended grant and must never be advertised.

| Starter uses | Typical liability | Peak liability | Peak contribution margin | Margin floor |
|---:|---:|---:|---:|---|
| 5 | US$0.056650 | US$0.094930 | 96.54% | Pass |
| **10 starter uses** | **US$0.113300** | **US$0.189860** | **93.08%** | Pass |
| 15 | US$0.169950 | US$0.284790 | 89.62% | Pass |

**Decision: a verified US$4.99 Pro purchase grants 10 Luna credits exactly once.** Ten is an
explicit owner policy selection constrained by the reviewed envelope; it is not mathematically
derived from the current 72-use peak ceiling and is not presented as an economic optimum. The
93.08% peak planning margin leaves a wide buffer against the 50% floor; any later measured envelope
that invalidates the floor trips the server breaker before new grants or sales.

## Consumable usage-card analysis

All rows apply the same conservative proceeds deductions and the Luna-only peak cost at the
1,000-success planning floor:

| Accepted card | Net proceeds | Typical cost | Peak cost | Peak contribution | Peak margin |
|---|---:|---:|---:|---:|---:|
| **10 uses / US$0.99** | US$0.544500 | US$0.113300 | US$0.189860 | US$0.354640 | **65.13%** |
| **25 uses / US$1.99** | US$1.094500 | US$0.283250 | US$0.474650 | US$0.619850 | **56.63%** |
| **65 uses / US$4.99** | US$2.744500 | US$0.736450 | US$1.234090 | US$1.510410 | **55.03%** |

**Decision: all three rows are the accepted first card tiers.** They exceed 50% only at the stated
1,000-success planning floor. The server must therefore disable new card sales and new starter
grants whenever trailing 30-day successful cloud analyses are below 1,000 or the recomputed peak
margin is below 50%. Already granted unexpired credits remain honored. The tiers are commercial
decisions, not App Store Connect products; Product IDs and Apple price-point availability still
belong to a later authorized implementation phase. Actual USA proceeds after launch recalibrate,
rather than retroactively justify, the pre-launch decision.

## Credit, refund, deletion, expiry, and recovery contract

- The Pro purchase is a non-consumable. Its verified original transaction is the server-side opaque
  recovery anchor; no raw StoreKit identifier reaches OpenAI or telemetry.
- Starter credits are granted exactly once only after verified permanent Pro purchase. Trial,
  Sandbox, TestFlight, UI tests, and an unsupported local-AI device grant none.
- Usage cards are consumables. Each verified transaction grants one server-authoritative integer
  lot exactly once. Balances stack and never auto-refill.
- Each starter or purchased lot expires one user-calendar year after grant. The server persists the
  calculated expiry instant using the accepted Calendar/TimeZone contract; it never reconstructs
  expiry with fixed seconds. User copy must show the date before purchase/use.
- A request reserves one credit; one validated displayed result commits it. Cancellation, denial,
  offline state, timeout, provider failure, or invalid output releases it.
- Reinstall or another device restores/verifies Pro, derives the same subject, and reads the server
  ledger. Ordinary StoreKit restoration of consumed consumables is never claimed.
- Family Sharing is off for the first offer. Only the verified Pro owner can buy/use cards.
- A card refund removes unused credits from its lot. If already spent, a non-monetary cloud-credit
  deficit pauses only future cloud use until cleared; it never creates monetary debt or affects
  local data, Free, or local Pro.
- A Pro refund/revocation removes Pro/cloud access but never deletes local financial data or credit
  records. Valid authority may later resume the same unexpired ledger.
- Local Delete All does not silently erase purchased credits. Separately confirmed cloud-account
  deletion permanently erases the ledger and unused credits after explicit destructive warning.
- A service sunset first stops sales and must provide an owner/legal-approved use window or
  equivalent remedy for remaining unexpired paid lots; it may not silently zero them.

COM-C7/C9 must prove transaction verification, original-transaction recovery, App Attest,
idempotency, refund, deletion, expiry, reinstall/device/account changes, concurrency, and the
margin breaker before a consumable exists.

## Trial, storefront, test, and release behavior

- Trial starts only after an explicit user action and lasts 30 user-calendar days using the user's
  Calendar and TimeZone, never `30 * 86400`. It is best-effort local and creates no account or cloud
  liability. Expiry locks Pro surfaces but preserves user data.
- USA US$4.99 is the accepted base price. Apple-equivalent regional pricing may make local Pro
  available elsewhere, while Luna/cards remain disabled outside independently admitted regions.
- Ordinary TestFlight/Sandbox/test builds use local templates or deterministic fixtures and cannot
  reach Luna. Apple App Review may use one isolated, capped route only after its own disclosure,
  test, review, and owner authorization.
- If G1 or later cloud phases do not pass, the app may still pursue a separately reviewed local-only
  public release. No cloud promise may appear in that build.

## Open evidence and current outcome

The following remains mandatory before `PROCEED_TO_R2`:

- a fixed bilingual three-way comparative Eval of the deterministic template, supported on-device
  output, and OpenAI Luna, using one frozen dataset and review criteria to establish the incremental
  user value of paid cloud credits;
- implementation and independent review of the hard 1,000-success/50% server breaker before any
  starter grant or usage-card sale;
- StoreKit configuration evidence for the US$4.99 price point and later post-launch recalibration
  from actual USA proceeds; and
- legal/product review of one-year credit expiry, destructive cloud deletion, refunds, Apple-review
  access, and service-sunset remedy.

The fixed Eval protocol is recorded in `G1_LUNA_EVAL.md`; its dataset and prompt hashes are
`d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014` and
`c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018`. DEC-COM-098 records
confirmed synthetic-only account admission and attempt 3's 24/24 first-pass automated result;
attempts 1 and 2 remain explicit non-passes. Independent review accepted the account/Eval evidence
on exact PR #100 head `323d8d7`; hosted run `33593253561` passed and merge `7a473d2` delivered it.

The current formal state is **`EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`**. The provider/model and
exact offer counts are owner-selected and the fixed synthetic run has reviewed evidence, but no
backend, Product ID, ledger, UI, App Store Connect product, cloud grant, COM-C7 entry, production
request, or public release is authorized here. Only a later owner-accepted `PROCEED_TO_R2` after
the remaining evidence may enter COM-C7.
