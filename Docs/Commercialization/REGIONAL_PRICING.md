# Regional Pricing Worksheet

## Status

**Owner policy, exact cloud-credit counts/consumable card tiers, and the synthetic Luna automated
Eval are accepted; independent review and StoreKit Product IDs/price points remain pending.**

DEC-COM-092 opened the one-time-offer hypothesis. DEC-COM-093 recorded the first quote-backed
planning package and its historical `INSUFFICIENT_QUOTE_EVIDENCE` result. Independent review found
no P1/P2 on exact PR #98 head `9226985`; run `33570570896` passed and PR #98 merged as `6e2d242`.
DEC-COM-094 closed only that evidence package. DEC-COM-095 records the commercial and
usage-accounting policy; DEC-COM-096 accepts 10 starter credits and the three card tiers.
DEC-COM-098 records a 24/24 first-pass automated Luna Eval result after preserving two non-pass
attempts. The current result is `EVAL_PASS_PENDING_REVIEW_AND_STOREFRONT_EVIDENCE`, not completed
G1 or COM-C7 entry.

This worksheet is not authorization to create or modify App Store Connect products, credentials,
backend resources, or customer-facing prices. StoreKit remains the display and transaction
authority. Because the product has not launched, actual United States proceeds do not exist yet;
pre-launch analysis uses the conservative proceeds assumptions below, and post-launch operation
must recalibrate from actual Financial Reports before widening any cloud allocation.

## Accepted owner policy

- Pro is a one-time US$4.99 buyout; the exact StoreKit price point and regional equivalents remain
  App Store Connect inputs for a later authorized phase.
- The 30-day trial begins only after an explicit **Start Trial** action. It exposes local Pro and
  on-device AI only, includes zero Luna credits, and does not auto-renew.
- A completed buyout grants exactly 10 starter Luna credits once.
- Additional cloud use uses three accepted card tiers: 10 uses / US$0.99, 25 uses / US$1.99, and
  65 uses / US$4.99. Product IDs and actual App Store Connect price-point creation remain later.
- Only a user-initiated valid structured Luna result ultimately displayed consumes one credit;
  future cloud-AI features inherit the same rule.
- Starter and purchased lots expire one user-calendar year after grant. No fixed-second
  approximation is allowed.
- Every accepted SKU must preserve at least a 50% contribution margin under the conservative peak
  cost envelope. A server-enforced cost breaker stops new sales/grants when that cannot be proven,
  while already granted credits remain honored.
- The sole provider/model is OpenAI `gpt-5.6-luna`. There is no backup provider or provider
  failover; network, policy, quota, account, or model failure returns the complete local fallback.
- Ordinary TestFlight/Sandbox/test users receive no Luna access. Apple App Review may exercise real
  Luna only through an isolated, capped review environment. That exception is not a customer or G1
  usage sample.

The prior US$1.99 Monthly, US$19.99 Annual, P1W introductory offer, and HKG/USA/SGP/TWN catalog are
historical nonpublic Configuration/Sandbox/TestFlight evidence only. Because no public launch has
occurred, a later authorized catalog migration replaces those products rather than grandfathering
them. This document does not perform that mutation.

## Evidence still required before Luna can be activated

- fixed Simplified-Chinese/English Luna quality and structured-output Eval;
- measured typical/P50 and peak/P95 input/output envelope from that Eval;
- OpenAI account proof for no voluntary training, configured standard retention, Global processing,
  rate limits, price tier, billing controls, model isolation, and the synthetic-Eval credential;
- hard server enforcement of the 1,000-success/50% margin breaker before any grant or sale;
- StoreKit price-point and regional-availability evidence;
- independent exact-head review and final owner decision.

Actual US App Store net proceeds are a mandatory post-launch recalibration input, not a pre-launch
G1 prerequisite. Until then, every candidate uses 30% Apple commission, 10% tax/FX reserve, and 5%
refund reserve in the conservative direction.

## Luna-only planning envelope

All values are integer micro-USD. Token counts are planning inputs, not measured percentiles.
Peak allows two billable attempts against the same Luna model and never a second provider.

| Scenario | Successful uses/month | Provider attempts/success | Input/output per attempt | Monthly backend floor | Typical all-in/use | Peak all-in/use | Evidence status |
|---|---:|---:|---|---:|---:|---:|---|
| Low-volume sensitivity | 100 | Typical 1; peak 2 | Typical 2,000/500; peak 8,000/1,500 | US$10.00 | US$0.101330 | US$0.108986 | PLANNING, NOT MEASURED |
| Planning floor | 1,000 | Typical 1; peak 2 | Typical 2,000/500; peak 8,000/1,500 | US$10.00 | US$0.011330 | US$0.018986 | PLANNING, NOT MEASURED |
| High-volume sensitivity | 10,000 | Typical 1; peak 2 | Typical 2,000/500; peak 8,000/1,500 | US$10.00 | US$0.002330 | US$0.009986 | PLANNING, NOT MEASURED |

The 1,000-success planning case uses US$2.744500 conservative net proceeds for US$4.99. A 50%
minimum contribution margin caps all fulfillment cost at US$1.372250. This supports at most 121
typical-envelope or 72 peak-envelope uses; those maxima are safety ceilings, not recommended grants.

## Accepted credit economics

| Offer element | Accepted price | Accepted credits | Conservative net proceeds | Peak fulfillment cost | Peak contribution margin | Current status |
|---|---:|---:|---:|---:|---:|---|
| One-time Pro starter lot | US$4.99 accepted base price | **10** | US$2.744500 | US$0.189860 | **93.08%** | Accepted commercial allocation |
| Usage card A | **US$0.99** | **10** | US$0.544500 | US$0.189860 | **65.13%** | Accepted tier; Product ID not created |
| Usage card B | **US$1.99** | **25** | US$1.094500 | US$0.474650 | **56.63%** | Accepted tier; Product ID not created |
| Usage card C | **US$4.99** | **65** | US$2.744500 | US$1.234090 | **55.03%** | Accepted tier; Product ID not created |

The accepted commercial tiers pass the arithmetic envelope at 1,000 monthly successes. They are
not yet StoreKit products. At low volume, fixed backend cost can make a card fail the 50% rule;
therefore the trailing-volume, price, and measured-envelope breaker must be server-enforced before
any sale or grant.

## Refund, expiry, and recovery accounting

- Pro refund/revocation removes future Pro/cloud authority but never deletes local financial data.
- Card refund removes unused credits from the matching idempotent lot. If already spent, the cloud
  ledger records a non-monetary credit deficit that future grants satisfy first; no financial debt
  and no local-data effect are created.
- Starter/card expiry is persisted as one user-calendar year from the authoritative grant instant.
- Reinstall/device recovery derives Pro from verified Apple authority and restores cloud lots from
  the server ledger; it never reissues a consumed or expired lot.
- Delete All may erase local data independently. Cloud-credit deletion and service sunset follow
  explicit server/deletion contracts and do not reinterpret local financial facts.

## Acceptance boundary

DEC-COM-095/096 accept the product policy, sole-provider direction, and exact credit/card choices;
DEC-COM-097 accepts standard retention only for the synthetic Eval and keeps production false.
G1 remains In Progress until account admission, the live Luna Eval, StoreKit price-point evidence,
independent review, and the final owner decision are complete. Only the explicit `PROCEED_TO_R2`
result may enter COM-C7. If the cloud path is not ready, the owner may instead authorize a separate
local-only release with Luna absent; that path does not silently satisfy or bypass G1.
