# G1 Cloud AI Unit Economics and Credit-Pack Packet

Status: **Scope accepted under DEC-COM-092; execution not entered.**

## Authorized question

G1 no longer waits for a public App Store observation window. Its next owner-entered task is a
cost-and-offer decision using dated real supplier evidence:

1. obtain current cloud-AI provider and backend/infrastructure rate cards or written quotes;
2. calculate the all-in cost of one successful AI use under typical and peak conditions; and
3. test a **US$4.99 one-time Pro unlock** that includes a finite starter allocation of cloud-AI
   uses, followed by separately purchased consumable usage cards.

US$4.99 is a working scenario, not an accepted customer price. No included-use count, usage-card
size, usage-card price, Product ID, storefront, or public claim is accepted before this packet is
completed and independently reviewed.

## Product hypothesis under evaluation

- The one-time purchase is modelled as a non-consumable local-Pro unlock plus a finite initial
  cloud-credit grant. It must never create unlimited cloud liability.
- A later usage card is modelled as a consumable in-app purchase that adds a fixed integer number
  of server-authoritative cloud credits.
- Failed, cancelled, retried, invalid-output, refunded, restored, deleted, and cross-device cases
  need explicit accounting rules before a consumable product can be created.
- Apple does not provide ordinary restore semantics for consumed consumables. G1 must therefore
  identify the authoritative credit ledger, purchase verification, identity/recovery boundary,
  refund handling, and deletion consequence before recommending this model.
- The current Monthly/Annual TestFlight implementation remains unchanged while this hypothesis is
  evaluated. G1 does not create or modify App Store Connect products or change the shipped paywall.

## Required quote evidence

Every input must name its source, retrieval/quote date, currency, region, tax treatment, and
effective period. Official published rate cards count as real evidence when their exact URL and
date are preserved; remembered prices, search snippets, marketing summaries, and model estimates
do not.

For at least one primary and one independently viable backup AI provider, capture:

- exact provider, model, API tier, processing region, and contract/rate-card version;
- input, output, cached-input, tool, batch, moderation, and any minimum-commit rates;
- retention/training terms and whether the accepted privacy boundary can use the tier;
- rate limits, context/output limits, service credits, and regional availability;
- currency conversion assumption and any quote expiry.

For the first-party backend path, capture fixed and variable costs for request handling,
attestation/authentication, configuration, usage ledger, database operations/storage, monitoring,
deletion, secrets, and expected support/incident reserve. Free allowances may be shown separately
but may not be the only viable cost case.

## Deterministic workload and cost model

The worksheet stores money as `Int64` micro-USD and ratios as integer basis points. It must define
fixed typical/P50 and peak/P95 request profiles before calculations:

- **Typical:** accepted P50 input/output/cache/tool usage for the exact allowed task set.
- **Peak:** accepted P95 input/output limits plus bounded retry, failover, invalid-output, and
  provider-switch costs.

For each provider/profile pair report:

- provider request cost;
- retry/failover and invalid-output reserve;
- allocated backend fixed cost and variable backend cost;
- App Store commission/tax/refund assumptions where offer economics are calculated;
- all-in cost per successful credited use; and
- cost for 10, 25, 50, 100, 250, and 1,000 successful uses.

The worksheet must show both break-even and the owner-selected safety-margin result. It may not
hide peak exposure inside an average or assume every failed provider request is free.

## US$4.99 starter-credit analysis

Starting from conservative net proceeds after App Store commission, applicable tax handling,
refund reserve, and the accepted non-cloud value/reserve for the permanent local-Pro unlock,
calculate:

- the maximum sustainable starter uses at typical cost;
- the maximum sustainable starter uses at peak cost;
- the remaining contribution after each candidate starter allocation;
- the cloud-liability exposure if every buyer consumes every included use; and
- at least three integer starter-allocation candidates with an explicit recommendation.

The recommended count must be derived from the accepted peak envelope and safety margin, not from
a round marketing number. If US$4.99 cannot fund a useful starter allocation without weakening
the local product or cost breaker, the correct result is to revise the offer.

## Usage-card analysis

Produce at least three candidate consumable cards. For each candidate report exact card price,
credit count, effective price per use, net proceeds, typical/peak fulfillment cost, contribution,
refund exposure, and customer-visible expiration/rollover terms. A card cannot be recommended if:

- its peak-cost contribution is negative or depends only on a temporary free allowance;
- retries or provider failover can silently consume extra customer credits;
- the credit ledger cannot survive the accepted device/reinstall/account lifecycle;
- deletion and refund behavior are not explicit; or
- the copy could be understood as unlimited use, a subscription, or a restorable consumable.

## Required output

The independently reviewed decision packet must name:

- accepted primary and backup provider candidates;
- exact dated quote evidence and quote-expiry dates;
- typical and peak all-in cost per successful AI use;
- whether US$4.99 remains viable;
- recommended included starter uses, or an explicit rejection of the scenario;
- recommended usage-card counts/prices and credit-accounting rules, or an explicit rejection;
- the cost circuit-breaker threshold and re-quote trigger; and
- one outcome: `PROCEED_TO_R2`, `REVISE_OFFER`, or `INSUFFICIENT_QUOTE_EVIDENCE`.

Only an owner-accepted `PROCEED_TO_R2` may authorize COM-C7. This packet does not authorize
provider credentials, backend deployment, Product ID creation, App Store Connect mutation,
paywall changes, tester assignment, distribution, or public release.
