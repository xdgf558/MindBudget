# Regional Pricing Worksheet

## Status

**Formal commercial values are TBD; provisional C3 test terms were accepted on 2026-08-14.**
DEC-COM-092 reopened a one-time-offer hypothesis for G1 analysis on 2026-09-01. This is an
evidence/owner-acceptance surface, not authorization to create formal App Store Connect products
or invent regional conversions. Engineering must render StoreKit values and must not choose
customer-facing regional prices.

The accepted nonpublic test configuration uses US$1.99 Monthly, US$19.99 Annual, and a 7-day free
trial for StoreKit-eligible subscribers. The first test storefront set is HKG, USA, SGP, and TWN.
These values support Configuration/Sandbox/TestFlight validation only and are not final launch
pricing, proceeds, margin, or storefront authorization.

The new working scenario is a US$4.99 one-time local-Pro unlock with finite starter cloud-AI
credits and separately purchased consumable usage cards. It is not an accepted price or product.
`G1_UNIT_ECONOMICS_PACKET.md` must derive the starter count and card options from dated real quotes
and typical/P50 plus peak/P95 all-in costs before this worksheet can accept them.

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

| Scenario | Paid users | Calls/user/period | Input/output distribution | Retry/failover | Fixed cost | Variable cost | Net proceeds | Gross margin | Evidence status |
|---|---:|---:|---|---|---:|---:|---:|---:|---|
| Low usage | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |
| Expected usage | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |
| P95/high usage | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |

## One-time unlock and usage-card scenario

| Offer element | Candidate price | Credit count | Net proceeds | Typical fulfillment cost | Peak fulfillment cost | Refund/recovery terms | Evidence status |
|---|---:|---:|---:|---:|---:|---|---|
| One-time local-Pro unlock + starter credits | US$4.99 working assumption | TBD by G1 | TBD | TBD | TBD | TBD | UNVERIFIED |
| Usage card A | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |
| Usage card B | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |
| Usage card C | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |

## Three-stage acceptance

1. Configuration stage: provisional, nonpublic StoreKit Configuration terms may support COM-C2/3
   tests and create no price promise.
2. Preliminary economics stage: an Accepted dated worksheet is required before formal App Store
   Connect products and COM-C6.
3. G1 stage: DEC-COM-092 requires final provider, quality, typical/P50 and peak/P95 all-in cost,
   starter-credit, consumable-card, ledger/recovery, storefront price and margin evidence before
   COM-C7.

The prior blanket exclusion of Local Lifetime is superseded only for this G1 hypothesis. No
one-time Product ID, entitlement, price, credit count, or UI may be created until the reviewed G1
worksheet is Accepted and a later implementation phase is explicitly entered.
