# Regional Pricing Worksheet

## Status

**DEC-COM-105 closes the reviewed DEC-COM-104 disposition and marks G1 Done at
`DEFER_LUNA_CREDITS_KEEP_LOCAL_PRO`. The US$4.99 local-Pro direction remains; Luna
credits/consumable cards and their
StoreKit Product IDs/price points are deferred.**

DEC-COM-092 opened the one-time-offer hypothesis. DEC-COM-093 recorded the first quote-backed
planning package and its historical `INSUFFICIENT_QUOTE_EVIDENCE` result. Independent review found
no P1/P2 on exact PR #98 head `9226985`; run `33570570896` passed and PR #98 merged as `6e2d242`.
DEC-COM-094 closed only that evidence package. DEC-COM-095 records the commercial and
usage-accounting policy; DEC-COM-096 accepts 10 starter credits and the three card tiers.
DEC-COM-098 records a 24/24 first-pass automated Luna Eval result after preserving two non-pass
attempts. Independent review found no P1/P2 on PR #100 head `323d8d7`; run `33593253561` passed and
merge `7a473d2` delivered it. DEC-COM-099 closes only that evidence delivery. The former result was
`EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`, not completed G1 or COM-C7 entry.
The fixed bilingual three-way comparative Eval across deterministic template, supported on-device
output, and Luna remained a separate `PROCEED_TO_R2` prerequisite.
DEC-COM-100 prepares only its Debug harness and reuses the reviewed Luna transcript; physical Apple
output is captured. DEC-COM-101 closes the PR #102 delivery chain—exact reviewed remediation head
`bb939d0`, hosted run `33628847476`, and merge `2254902`—without scoring comparative value. A
different reviewer must score only blind JSON SHA-256
`bcbf943ba7d6a1a9d18442efc38e760cc798c30e8674c8d877f9e0cb751ab2a5` before opening the sidecar;
independent blind review remained open at that delivery checkpoint. DEC-COM-102 records the later
completed review at SHA-256
`d2b9310f4471400825e666009f646a190d8ac2819f859c8e38d58ec05cbf040e` and its deterministic
`NON_PASS`: zero materially preferred Luna cases and no qualifying bilingual task. At that
checkpoint, state was `COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION`; storefront work was not
the sole remaining blocker and awaited the owner's cloud-offer disposition.
DEC-COM-103 closes only that result-recording delivery after PR #104 exact remediation head
`2fb2b64` passed independent rereview and hosted run `33701018178`, then merged as `e4b54af` with
that head as second parent. It does not create or approve a storefront product.
DEC-COM-104 supplies the final G1 owner disposition after that `NON_PASS`: preserve this worksheet
as historical planning evidence, do not create Luna/card products, and continue only the local-Pro
path through a separately authorized local-only COM-C12 review.

This worksheet is not authorization to create or modify App Store Connect products, credentials,
backend resources, or customer-facing prices. StoreKit remains the display and transaction
authority. Because the product has not launched, actual United States proceeds do not exist yet;
pre-launch analysis uses the conservative proceeds assumptions below, and post-launch operation
must recalibrate from actual Financial Reports before widening any cloud allocation.

## Current local-only launch policy

- Pro is a one-time US$4.99 buyout; the exact StoreKit price point and regional equivalents remain
  App Store Connect inputs for a later authorized phase.
- The 30-day trial begins only after an explicit **Start Trial** action. It exposes local Pro and
  on-device AI only, includes zero Luna credits, and does not auto-renew.
- The earlier 10-credit starter and 10/25/65-use card schedule is deferred historical planning; a
  completed local-Pro buyout currently promises and grants no Luna credit.
- No Luna usage-card Product ID or App Store Connect price point may be created on the local-only
  path.
- The local-only candidate has no Luna route, cloud-credit ledger, provider credential, cloud-cost
  breaker, customer cloud quota, or special cloud access for testers or App Review.

## Historical cloud-credit policy evidence — inactive

The following rules preserve the exact DEC-COM-095/096 planning record only. They are not current
policy, are not customer promises, and do not apply to the DEC-COM-104 local-only candidate:

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

## Evidence required only if Luna is re-proposed

- a fresh Simplified-Chinese/English value hypothesis and independently accepted comparison beyond
  the frozen `NON_PASS`;
- measured typical/P50 and peak/P95 input/output envelope for the newly proposed behavior;
- current OpenAI account proof for training, retention, processing region, rate, price, billing,
  model isolation, and a production credential boundary;
- hard server enforcement of a bootstrap-safe 50% margin breaker before any grant or sale; the
  historical below-1,000-success rule cannot be reused unchanged at zero launch traffic;
- StoreKit price-point and regional-availability evidence;
- a new exact-head review and final owner re-entry decision.

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

## Historical accepted credit economics, now deferred

| Offer element | Accepted price | Accepted credits | Conservative net proceeds | Peak fulfillment cost | Peak contribution margin | Current status |
|---|---:|---:|---:|---:|---:|---|
| One-time Pro starter lot | US$4.99 planning base price | **10** | US$2.744500 | US$0.189860 | **93.08%** | Deferred historical allocation |
| Usage card A | **US$0.99** | **10** | US$0.544500 | US$0.189860 | **65.13%** | Deferred; Product ID not created |
| Usage card B | **US$1.99** | **25** | US$1.094500 | US$0.474650 | **56.63%** | Deferred; Product ID not created |
| Usage card C | **US$4.99** | **65** | US$2.744500 | US$1.234090 | **55.03%** | Deferred; Product ID not created |

The accepted commercial tiers pass the arithmetic envelope at 1,000 monthly successes. They are
not yet StoreKit products. At low volume, fixed backend cost can make a card fail the 50% rule;
therefore the trailing-volume, price, and measured-envelope breaker must be server-enforced before
any sale or grant.

## Historical cloud refund, expiry, and recovery design — inactive

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

DEC-COM-095/096 historically accepted the product policy, sole-provider direction, and exact
credit/card choices;
DEC-COM-097 accepts standard retention only for the synthetic Eval and keeps production false.
DEC-COM-104 accepts `DEFER_LUNA_CREDITS_KEEP_LOCAL_PRO`, without `PROCEED_TO_R2`. PR #106 exact
remediation head `961acc0` passed independent rereview and hosted run `33724552517`, then merged as
`fdd511b` with that head as second parent. DEC-COM-105 closes G1 at the deferral outcome. COM-C7
through COM-C11 remain deferred. A future cloud proposal must open fresh G1
value, economics, storefront, privacy, and legal evidence before explicit re-entry. The current
next eligible path is a separately owner-entered local-only COM-C12 review with Luna and all
cloud-credit products absent.
