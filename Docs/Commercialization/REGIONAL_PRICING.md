# Regional Pricing Worksheet

## Status

**Formal commercial values are TBD; provisional C3 test terms were accepted on 2026-08-14.**
DEC-COM-092 reopened a one-time-offer hypothesis for G1 analysis on 2026-09-01. The owner entered
G1 on 2026-09-02; DEC-COM-093 records quote-backed planning evidence and the interim result
`INSUFFICIENT_QUOTE_EVIDENCE`. Independent review found no P1/P2 on exact PR #98 head `9226985`;
run `33570570896` passed and PR #98 merged as `6e2d242`. DEC-COM-094 closes only that first evidence
package. This remains an evidence/owner-acceptance surface, not authorization to create formal App
Store Connect products or invent regional conversions. Engineering must render StoreKit values
and must not choose customer-facing regional prices.

The accepted nonpublic test configuration uses US$1.99 Monthly, US$19.99 Annual, and a 7-day free
trial for StoreKit-eligible subscribers. The first test storefront set is HKG, USA, SGP, and TWN.
These values support Configuration/Sandbox/TestFlight validation only and are not final launch
pricing, proceeds, margin, or storefront authorization.

The new working scenario is a US$4.99 one-time local-Pro unlock with finite starter cloud-AI
credits and separately purchased consumable usage cards. It is not an accepted price or product.
`G1_UNIT_ECONOMICS_PACKET.md` derives a provisional 10-use starter grant and 10/25/65-use card
ladder from dated real quotes and deterministic typical/P50 plus peak/P95 planning envelopes. The
envelopes are not measured distributions and remain unaccepted pending the provider Eval, account
privacy/region proof, exact App Store proceeds, final-decision review, and an owner decision.

Accepted technical products:

- `com.xdgf558.mindbudget.pro.monthly`
- `com.xdgf558.mindbudget.pro.annual`

## Evidence required before a price becomes Accepted

- Apple storefront price point and effective date;
- current proceeds rate/program status, taxes and expected refunds;
- weighted storefront mix and currency basis;
- fixed configuration/telemetry/backend/support costs;
- cloud input/output/cache/retry/failover costs at low, expected and P95 use;
- proposed included calls and reset boundary;
- Monthly versus Annual discount and cannibalization assumptions;
- target gross margin and downside scenario;
- quote/source URL, capture date, owner and decision ID.

## Candidate storefront worksheet

Rows are evaluation candidates only; they do not promise launch availability.

| Storefront | Monthly price point | Annual price point | Trial availability/terms | Included cloud calls/reset | Effective date | Net proceeds assumption | Evidence date/source | Status/owner |
|---|---|---|---|---|---|---|---|---|
| Hong Kong (HKG) | StoreKit value; US$1.99 test anchor | StoreKit value; US$19.99 test anchor | 7 days when StoreKit eligible | TBD | Test only | TBD | Owner input, 2026-08-14 | Accepted nonpublic test / owner |
| United States (USA) | StoreKit value; US$1.99 test anchor | StoreKit value; US$19.99 test anchor | 7 days when StoreKit eligible | TBD | Test only | TBD | Owner input, 2026-08-14 | Accepted nonpublic test / owner |
| Singapore (SGP) | StoreKit value; US$1.99 test anchor | StoreKit value; US$19.99 test anchor | 7 days when StoreKit eligible | TBD | Test only | TBD | Owner input, 2026-08-14 | Accepted nonpublic test / owner |
| Taiwan (TWN) | StoreKit value; US$1.99 test anchor | StoreKit value; US$19.99 test anchor | 7 days when StoreKit eligible | TBD | Test only | TBD | Owner input, 2026-08-14 | Accepted nonpublic test / owner |
| China mainland (CHN) | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED | Not in first test set |
| Other launch storefronts | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED | Not selected |

## Unit-economics scenarios

| Scenario | Successful uses/month | Provider attempts per success | Input/output per attempt | Retry/failover | Monthly fixed/reserve | Typical all-in/use | Peak all-in/use | Evidence status |
|---|---:|---:|---|---|---:|---:|---:|---|
| Low volume sensitivity | 100 | Typical 1; peak 2 | Typical 2,000/500; peak 8,000/1,500 | Peak includes one Anthropic failover | US$10.00 | US$0.101330 | US$0.123098 | PROVISIONAL PLANNING, NOT MEASURED |
| Planning floor | 1,000 | Typical 1; peak 2 | Typical 2,000/500; peak 8,000/1,500 | Peak includes one Anthropic failover | US$10.00 | US$0.011330 | US$0.033098 | PROVISIONAL PLANNING, NOT MEASURED |
| High volume sensitivity | 10,000 | Typical 1; peak 2 | Typical 2,000/500; peak 8,000/1,500 | Peak includes one Anthropic failover | US$10.00 | US$0.002330 | US$0.024098 | PROVISIONAL PLANNING, NOT MEASURED |

## One-time unlock and usage-card scenario

| Offer element | Candidate price | Credit count | Net proceeds | Typical fulfillment cost | Peak fulfillment cost | Refund/recovery terms | Evidence status |
|---|---:|---:|---:|---:|---:|---|---|
| One-time local-Pro unlock + starter credits | US$4.99 working assumption | 10 starter uses | US$2.744500 after 30% commission plus 10% tax/FX and 5% refund reserves | US$0.113300 | US$0.330980 | Non-consumable recovery anchor; starter/offer terms unaccepted | PROVISIONAL / `INSUFFICIENT_QUOTE_EVIDENCE` |
| Usage card A | US$0.99 | 10 uses | US$0.544500 | US$0.113300 | US$0.330980 | Idempotent consumable lot; refund removes unused lot or creates a credit deficit | PROVISIONAL / `INSUFFICIENT_QUOTE_EVIDENCE` |
| Usage card B | US$1.99 | 25 uses | US$1.094500 | US$0.283250 | US$0.827450 | Idempotent consumable lot; refund removes unused lot or creates a credit deficit | PROVISIONAL / `INSUFFICIENT_QUOTE_EVIDENCE` |
| Usage card C | US$4.99 | 65 uses | US$2.744500 | US$0.736450 | US$2.151370 | Idempotent consumable lot; refund removes unused lot or creates a credit deficit | PROVISIONAL / `INSUFFICIENT_QUOTE_EVIDENCE` |

## Three-stage acceptance

1. Configuration stage: provisional, nonpublic StoreKit Configuration terms may support COM-C2/3
   tests and create no price promise.
2. Preliminary economics stage: an Accepted dated worksheet is required before formal App Store
   Connect products and COM-C6.
3. G1 stage: DEC-COM-092/093 require final provider, quality, measured typical/P50 and peak/P95
   all-in cost, starter-credit, consumable-card, ledger/recovery, storefront price and margin
   evidence before COM-C7. The 2026-09-02 planning worksheet does not satisfy that gate.

The prior blanket exclusion of Local Lifetime is superseded only for this G1 hypothesis. No
one-time Product ID, entitlement, price, credit count, or UI may be created until the reviewed G1
worksheet is Accepted and a later implementation phase is explicitly entered.
