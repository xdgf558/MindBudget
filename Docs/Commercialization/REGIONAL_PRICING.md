# Regional Pricing Worksheet

## Status

**All commercial values are TBD.** This is an evidence/owner-acceptance surface, not authorization
to create App Store Connect products or display a price. Engineering must render StoreKit values
and must not choose regional prices.

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
| China mainland (CHN) | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED | Proposed / owner |
| United States (USA) | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED | Proposed / owner |
| Singapore (SGP) | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED | Proposed / owner |
| Other launch storefronts | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED | Not selected |

## Unit-economics scenarios

| Scenario | Paid users | Calls/user/period | Input/output distribution | Retry/failover | Fixed cost | Variable cost | Net proceeds | Gross margin | Evidence status |
|---|---:|---:|---|---|---:|---:|---:|---:|---|
| Low usage | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |
| Expected usage | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |
| P95/high usage | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | UNVERIFIED |

## Three-stage acceptance

1. Configuration stage: provisional, nonpublic StoreKit Configuration terms may support COM-C2/3
   tests and create no price promise.
2. Preliminary economics stage: an Accepted dated worksheet is required before formal App Store
   Connect products and COM-C6.
3. G1 stage: final provider, quality, quota/reset, retry/failover cost, storefront price and margin
   evidence is required before COM-C7.

Local Lifetime is excluded from this worksheet until a new Accepted specification explicitly
reopens it.
