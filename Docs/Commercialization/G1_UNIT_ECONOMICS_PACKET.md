# G1 Cloud AI Unit Economics and Credit-Pack Packet

Status: **In Progress after independently reviewed PR #98 quote/planning evidence. Exact head
`9226985` passed GitHub Actions run `33570570896` and merged as `6e2d242`; the mandatory bounded
provider Eval, account-level region/retention verification, exact App Store proceeds, and final
owner decision remain open.**

DEC-COM-092 and DEC-COM-093 own this G1 scope and entered-G1 interim evidence boundary. DEC-COM-094
records the reviewed first evidence package and why its formal result remains neither an offer nor
provider acceptance.

## Decision boundary

G1 evaluates whether cloud AI can be added without turning the permanent local product into an
unbounded service liability. The working offer is a **US$4.99 one-time local-Pro unlock** with a
finite starter grant, followed by separately purchased consumable usage cards. It does not change
the current Monthly/Annual TestFlight products, create Product IDs, configure credentials, deploy a
backend, call a provider, or authorize COM-C7.

This packet deliberately separates three things:

1. **Supplier quote evidence** is current and primary-source-backed as of 2026-09-02.
2. **Planning workload arithmetic** is deterministic and reproducible, but is not measured P50/P95
   evidence until the bounded bilingual Eval runs.
3. **Offer recommendations** are provisional downside envelopes. They cannot become customer
   prices or credit promises until independent review and an owner-accepted G1 outcome.

Money in the executable worksheet is integer micro-USD. Percentages are integer basis points.
`Scripts/g1_unit_economics.py` contains the closed arithmetic and self-tests.

## Frozen quote and offer assumptions

| Input | Frozen value | Evidence/qualification |
|---|---:|---|
| Quote retrieval date | 2026-09-02 | URLs below were opened directly on this date |
| Quote currency | USD | Every supplier page quotes USD |
| Offer base storefront | USA | Scenario only; no App Store Connect product exists |
| Customer price | US$4.99 | Working hypothesis, not accepted pricing |
| Commission downside | 30% | Used because Small Business Program participation is not verified |
| Small-business sensitivity | 15% | Apple publishes 15% for qualified participants; not used to size credits |
| Tax/FX reserve | 10% of customer price | Planning reserve pending exact App Store price/proceeds export |
| Refund reserve | 5% of customer price | Planning reserve pending actual product evidence |
| Permanent local-Pro reserve | US$2.00 per unlock | Owner-reviewable product/support reserve; not cloud spend |
| Cloud safety hold | 50% of the residual cloud budget | Must remain unspent under the peak envelope |
| Backend planning floor | 1,000 successful uses/month | Sensitivity at 100/500/10,000 is shown below |
| Provider safety reserve | 20% of provider-attempt cost | Engineering reserve, not an observed failure rate |
| Exchange rate | 1 USD = 1 quoted USD | No currency conversion is used in this USA worksheet |

Apple states that proceeds equal customer price minus applicable taxes and commission. Its Small
Business Program publishes a 15% commission for qualified developers, while standard terms can
apply a 30% commission. Exact proceeds are storefront- and agreement-specific, so the calculation
uses the 30% downside plus separate tax/FX and refund reserves rather than assuming qualification.

Primary Apple evidence (retrieved 2026-09-02):

- <https://developer.apple.com/app-store/small-business-program/>
- <https://developer.apple.com/help/app-store-connect/reference/pricing-and-availability/app-pricing-and-availability>
- <https://developer.apple.com/help/app-store-connect/getting-paid/view-payments-and-proceeds>

## Allowed cloud task set

The cost envelope covers only short, structured coaching tasks that consume already-computed,
allow-listed facts:

- explain a deterministic budget status, pattern, or safe-to-spend result in supportive language;
- compare a bounded set of deterministic options without choosing or changing money values;
- rewrite an already-computed plan or reminder in Simplified Chinese or English; and
- return one bounded structured response that Swift validates before display.

It excludes raw transaction rows, notes, merchant lists, receipt images/OCR/line items, original
free-form questions/reasons, stable identifiers, tools, web search, file APIs, provider-managed
conversation state, prompt caching, and model-authoritative financial decisions. The provider
receives no direct client call and no provider credential leaves the future backend.

## Dated AI supplier evidence

These are **cost candidates**, not selected providers. The exact primary/backup acceptance still
requires the versioned Eval and account-level contract checks in `AI_PROVIDER_CONTRACT.md`.

| Candidate | Interactive quote used | Limits and rate evidence | Retention/training evidence | Current disposition |
|---|---|---|---|---|
| OpenAI `gpt-5.6-luna` | Standard short-context US$0.20/M input, US$0.02/M cached input, US$1.20/M output; the worksheet adds the published 10% regional-processing uplift, producing US$0.22/M and US$1.32/M. No cache/tool charge is used. | 1,050,000-token context, 128,000 max output; Tier 1 publishes 500 RPM and 500,000 TPM. | API input/output is not used for training by default; default abuse-monitoring retention can be up to 30 days; ZDR requires eligibility/approval. | Provisional primary **cost** candidate; region/ZDR and quality unaccepted |
| Anthropic `claude-haiku-4-5-20251001` | Direct API global US$1/M input, US$1.25/M 5-minute cache write, US$2/M 1-hour cache write, US$0.10/M cache hit, US$5/M output. No cache/tool charge is used. | 200,000-token context, 64,000 max output; published Scale tier is 1,000 RPM, 2,000,000 ITPM, 400,000 OTPM. | Commercial API input/output is not used for training by default and is deleted within 30 days; ZDR is approval-based. | Provisional backup **cost** candidate; processing-region and quality unaccepted |
| Google `gemini-3.7-flash` | Standard promotional US$0.75/M input and US$3.75/M output through 2026-12-31; US$1.50/M and US$7.50/M starting 2027-01-01. The non-promotional price is the only durable comparison. | 1,048,576 input and 65,536 output tokens; paid-tier limits depend on account tier and remain account-unverified. | Paid-tier content is not used to improve products; limited abuse logging remains, and stateful/logging/file/cache features need explicit disabling/avoidance. | Quoted alternate; temporary price is rejected as a liability basis |

Official provider sources (retrieved 2026-09-02):

- OpenAI pricing and model/rate limits:
  <https://developers.openai.com/api/docs/pricing> and
  <https://developers.openai.com/api/docs/models/gpt-5.6-luna>
- OpenAI data controls:
  <https://platform.openai.com/docs/models/default-usage-policies-by-endpoint> and
  <https://openai.com/business-data/>
- Anthropic pricing, rate limits, and retention:
  <https://platform.claude.com/docs/en/about-claude/pricing>,
  <https://platform.claude.com/docs/en/api/rate-limits>, and
  <https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data>
- Anthropic commercial training default:
  <https://privacy.claude.com/en/articles/7996868-is-my-data-used-for-model-training>
- Gemini pricing/model/data controls:
  <https://ai.google.dev/gemini-api/docs/pricing>,
  <https://ai.google.dev/gemini-api/docs/models/gemini-3.7-flash>, and
  <https://ai.google.dev/gemini-api/docs/zdr>

Prices with no explicit expiry must be re-quoted within 30 calendar days before an implementation
decision. Gemini's promotional quote expires on 2026-12-31 and is never used to size permanent
credits. No provider service credit, minimum commitment, batch discount, cached-input discount,
free tier, search allowance, or other promotional credit is used.

## First-party backend quote

The planning backend is one isolated Cloudflare Workers service plus D1. Cloudflare's published
Paid plan has a US$5 monthly account minimum, 10 million included requests, 30 million included CPU
milliseconds, no Worker bandwidth/egress charge, and 20 million included log events with seven-day
retention. D1 includes 25 billion rows read, 50 million rows written, and 5 GB storage monthly;
overage is US$0.001/M reads, US$1/M writes, and US$0.75/GB-month.

Official source, last updated 2026-08-28 and retrieved 2026-09-02:
<https://developers.cloudflare.com/workers/platform/pricing/>.

The conservative per-success model allocates:

- the full US$5 Workers minimum;
- a separate US$5/month support/incident reserve;
- one Worker request, 20 CPU ms, eight D1 reads, six D1 writes, and one content-free log event per
  successful use; and
- the full US$10 monthly fixed/reserve amount across 1,000 successful uses, even though current
  usage would remain inside the included allowances.

At that planning floor the backend allocation is US$0.010010 per successful use. App Attest,
StoreKit/App Store Server verification, secrets, deletion, configuration, ledger idempotency, and
monitoring are represented inside this backend envelope; no separate Apple per-call rate has been
claimed. A later implementation quote must re-open any service not covered by these rates.

## Deterministic planning workloads

These token counts are frozen engineering envelopes for quote arithmetic. They are **not measured
P50/P95 distributions** and cannot satisfy the Eval gate.

| Profile | Provider attempts | Input/output per attempt | Cache/tools | Failure rule |
|---|---:|---:|---|---|
| typical/P50 planning envelope | 1 primary | 2,000 / 500 | 0 / none | One schema-valid OpenAI Luna result |
| peak/P95 planning envelope | 1 primary + 1 backup | 8,000 / 1,500 each | 0 / none | Primary attempt is unusable; consented Anthropic backup returns one schema-valid result |

One customer credit is committed only after one schema-valid result. Cancellation, timeout,
transport failure, provider rejection, or invalid output releases the reservation. Retry/failover
may increase our cost but never consumes another customer credit. Both profiles add a 20% provider
cost reserve after billed attempts.

## Reproducible cost result

At the 1,000-success/month planning floor:

| Component | typical/P50 planning | peak/P95 planning |
|---|---:|---:|
| Primary provider attempt | US$0.001100 | US$0.003740 |
| Backup provider attempt | — | US$0.015500 |
| 20% provider reserve | US$0.000220 | US$0.003848 |
| Backend + incident allocation | US$0.010010 | US$0.010010 |
| **All-in successful use** | **US$0.011330** | **US$0.033098** |

| Successful uses | Typical cost | Peak cost |
|---:|---:|---:|
| 10 | US$0.113300 | US$0.330980 |
| 25 | US$0.283250 | US$0.827450 |
| 50 | US$0.566500 | US$1.654900 |
| 100 | US$1.133000 | US$3.309800 |
| 250 | US$2.832500 | US$8.274500 |
| 1,000 | US$11.330000 | US$33.098000 |

Fixed-cost sensitivity is material and prevents a low-volume launch from being justified by cheap
tokens alone:

| Successful uses/month | Typical all-in/use | Peak all-in/use |
|---:|---:|---:|
| 100 | US$0.101330 | US$0.123098 |
| 500 | US$0.021330 | US$0.043098 |
| 1,000 | US$0.011330 | US$0.033098 |
| 10,000 | US$0.002330 | US$0.024098 |

The provisional circuit breaker therefore requires a fresh quote and offer review when any of
these occurs: trailing 30-day successful volume falls below 1,000 after launch, peak all-in cost
exceeds US$0.033098, either accepted model rate rises 20% or more, backup failover exceeds the Eval
envelope, the 30-day quote age expires, or provider retention/region terms change. It suspends new
cloud grants and card sales; it never disables local Pro or local fallback.

## US$4.99 starter analysis

The downside calculation is:

| Item | Micro-USD | USD |
|---|---:|---:|
| Customer price | 4,990,000 | US$4.990000 |
| Less 30% commission | 1,497,000 | US$1.497000 |
| Less 10% tax/FX reserve | 499,000 | US$0.499000 |
| Less 5% refund reserve | 249,500 | US$0.249500 |
| Conservative net | 2,744,500 | US$2.744500 |
| Less permanent local-Pro reserve | 2,000,000 | US$2.000000 |
| Cloud budget before safety hold | 744,500 | US$0.744500 |
| **Spendable after 50% cloud safety hold** | **372,250** | **US$0.372250** |

That spendable amount funds at most 32 typical-envelope uses or a
**maximum of 11 peak-envelope starter uses**. Candidate comparison:

| Starter uses | Typical liability | Peak liability | Cloud budget remaining after peak | 50% hold preserved? |
|---:|---:|---:|---:|---|
| 5 | US$0.056650 | US$0.165490 | US$0.579010 | Yes |
| **10** | **US$0.113300** | **US$0.330980** | **US$0.413520** | **Yes** |
| 15 | US$0.169950 | US$0.496470 | US$0.248030 | No |

The provisional recommendation is **10 starter uses**. It is the largest round count below the
derived 11-use peak maximum while retaining slightly more than half the pre-hold cloud budget.
It remains unaccepted until measured Eval tokens/failures, exact proceeds, and privacy admission
confirm the envelope.

## Consumable usage-card analysis

All three rows use the same 30% commission, 10% tax/FX, and 5% refund reserves. They are candidate
price/count pairs only; App Store price-point availability has not been exported.

| Candidate | Net proceeds | Typical cost | Peak cost | Peak contribution | Peak margin | Customer price/use |
|---|---:|---:|---:|---:|---:|---:|
| **10 uses / US$0.99** | US$0.544500 | US$0.113300 | US$0.330980 | US$0.213520 | 39.21% | US$0.099000 |
| **25 uses / US$1.99** | US$1.094500 | US$0.283250 | US$0.827450 | US$0.267050 | 24.39% | US$0.079600 |
| **65 uses / US$4.99** | US$2.744500 | US$0.736450 | US$2.151370 | US$0.593130 | 21.61% | US$0.076769 |

The provisional card ladder is 10/25/65 uses at US$0.99/US$1.99/US$4.99. Larger cards reduce the
customer price per use but preserve positive peak contribution. No card is accepted before exact
StoreKit price/proceeds evidence and the credit lifecycle below pass independent review.

## Credit-accounting contract required by this offer

- The permanent Pro purchase is a non-consumable. Its verified original transaction identity is
  the recovery anchor for a server-side opaque credit account; raw StoreKit identifiers are never
  sent to a model or telemetry.
- Usage cards are verified consumable transactions. Each verified transaction grants exactly once
  through an idempotency key and a server-authoritative integer lot.
- A request reserves one credit. Exactly one validated successful response commits it. Cancelled,
  denied, offline, timed-out, provider-failed, or invalid-output attempts release it. Retry and
  failover never charge another credit.
- Reinstall or another device first restores/verifies the non-consumable Pro transaction, derives
  the same server subject, then reads the server ledger. Ordinary StoreKit consumable restoration
  is never claimed.
- A card refund removes unused credits from that purchase lot. If its lot has already been spent,
  the account receives a non-monetary credit deficit and only future cloud use pauses until the
  deficit is cleared; local Pro and local budgeting remain usable.
- A Pro refund/revocation pauses cloud use without erasing remaining lots. If valid Pro authority
  returns, the same ledger can resume.
- Credits roll over and do not expire in the current candidate. Confirmed cloud-account deletion
  permanently erases the ledger and unspent credits after explicit destructive disclosure; local
  data deletion alone does not silently erase purchased credits. A service sunset must provide an
  owner/legal-approved remedy for unspent paid lots rather than silently discarding them.
- Family Sharing is not assumed. Any future sharing behavior needs a separate ledger and StoreKit
  decision before product creation.

These rules are a design proposal, not proof that the recovery identity works. COM-C7/C9 must
prove transaction verification, original-transaction recovery, App Attest, idempotency, refunds,
deletion, reinstall/device/account changes, and concurrency before a consumable can exist.

## Open evidence and current outcome

### Reviewed first evidence package

Independent review found no P1/P2 in exact PR #98 head `9226985`, manually reproduced the integer
arithmetic and conservative rounding, and approved merge after hosted CI. GitHub Actions run
`33570570896` passed on that exact head, and PR #98 merged to `main` as `6e2d242`.

DEC-COM-094 closes only this quote/planning evidence package. It carries three implementation and
evidence obligations forward: the low-volume/cost circuit breaker must become a
server-enforced acceptance gate before any card exists; the worksheet must replace
optimization-removable Python `assert` checks before it is implementation or release evidence;
and every URL-only supplier rate must be re-quoted within the existing 30-day window. None of these
notes changes the arithmetic or promotes a provisional offer.

The following mandatory G1 evidence is still missing:

- a versioned fixed Eval of deterministic template, on-device model, OpenAI Luna, and Anthropic
  Haiku across the accepted tasks in Simplified Chinese and English;
- measured structured-output validity, quality/safety/numeric failures, input/output token P50/P95,
  latency P50/P95, retry/failover rate, and dataset/rubric hashes;
- account-level proof of usable processing region, rate tier, ZDR/retention setting, subprocessor
  acceptance, and credentials/billing availability for both candidates;
- exact App Store Connect US price-point proceeds (including taxes) and confirmation of the
  account's commission program; and
- legal/product acceptance of non-expiring credits, deletion loss disclosure, refunds, and
  service-sunset remedy.

Therefore the current formal outcome is **`INSUFFICIENT_QUOTE_EVIDENCE`**: published quotes make
the 10-starter-use and 10/25/65-card envelopes economically plausible, but quotes alone cannot
turn invented token/failure/quality inputs into accepted P50/P95 evidence. G1 remains In Progress.
No primary/backup provider, US$4.99 price, starter count, card, circuit breaker, ledger, or COM-C7
entry is accepted by this interim result.

The next authorized G1 action requires separate owner authorization to obtain/configure candidate
API credentials and run the bounded non-production Eval. Only a later independently reviewed,
owner-accepted `PROCEED_TO_R2` can authorize COM-C7.
