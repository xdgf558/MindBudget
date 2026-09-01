# AI Provider Contract

## Current status

No cloud provider or model is selected, configured, called, or promised. All provider names,
model IDs, prices, token limits, processing regions, retention terms, subprocessors, and service
levels are `UNVERIFIED`. Cloud Coach is forbidden before G1 authorizes COM-C7 and the later
entitlement, consent, quota, redaction, backend, and release gates pass.

Existing deterministic templates and optional on-device Foundation Models remain the complete
product. If an acceptable cloud option is never proven, the app remains correct without one.

## Candidate admission matrix

Each primary and backup candidate must receive dated evidence for every field; a cheaper domestic
or international model receives no exception.

| Field | Required evidence | Reject when |
|---|---|---|
| Legal provider/model identity | Contract, API/model identifier, policy URL/version, quote date | Identity or material terms are ambiguous |
| Processing and storage regions | Request, log, abuse-monitoring, backup and support-access regions | Required storefront/consent cannot lawfully cover them |
| Retention and training | Explicit API retention, training/default opt-out, deletion and abuse-review terms | Consumer content may train models or retention is undisclosed/unbounded |
| Subprocessors | Current list and material-change notification | Hidden/uncontrolled subprocessor path exists |
| Security | Transport, encryption, access control, incident process, certifications where relevant | Evidence cannot support the threat model |
| Structured output | Fixed schema compliance and invalid-output rate | Output cannot be deterministically validated/fail closed |
| Quality | Blind fixed Eval by task/language/skin-independent content | No accepted advantage over local/template baseline |
| Language | Simplified Chinese and English; additional languages only when app supports them | Required language repeatedly drifts or mixes scripts |
| Latency/availability | P50/P95, timeout, retry and regional availability | Fails accepted SLO or makes fallback disruptive |
| Cost | Input/output/cache/tool/retry/failover P50/P95 cost at three usage intensities | Margin/quota/circuit-breaker target cannot be met |
| Content controls | Exact accepted field schema and output validator compatibility | Requires raw ledger, notes, receipt image/OCR, or identifiers |

## Consent-bound provider set

Consent is a versioned tuple of provider set, purpose, outbound field schema, processing/retention
summary, and policy version. The router may choose only among that exact accepted set. If the set,
processing region, retention/training behavior, purpose, or material policy changes, status becomes
`requiresRenewal` and no cloud request is sent until renewed.

Failover never expands consent. When every consented provider is unavailable, the request falls
back to on-device AI or the deterministic template.

## Data contract

The exact cloud schema is not frozen in COM-C0B. Every later schema must satisfy:

- deterministic, typed, bounded, allow-listed aggregate facts only;
- exact money represented as minor units plus currency code when a task genuinely needs it;
- no raw transaction rows, notes, merchant list, receipt image/OCR/line name, original free-form
  question/reason, device contact data, or cross-app data;
- stable identifiers replaced by request-scoped or coarse values unless an accepted purpose proves
  necessity;
- client redaction before transport and independent server validation/redaction before provider;
- content-free logs and telemetry; prompts/responses are not admin-viewable;
- output is structured, bounded, numerically/language/safety validated, and never authoritative for
  money, rules, entitlement, quota, diagnosis, or financial advice.

## Routing and configuration

- Provider/model IDs are server-side allow-lists; the client never submits arbitrary IDs or calls
  provider domains directly.
- Routing considers consent, region, quality, availability, latency, cost and circuit-breaker state.
- Signed public/client configuration may describe currently consentable processors, but cannot
  grant entitlement, change StoreKit price, widen fields, or override server allow-lists.
- Unknown/stale configuration fails closed. Provider credentials and admin secrets remain
  server-side and environment-separated.

## Evaluation gate

G1 requires a versioned bounded Eval comparing deterministic template, on-device model, primary
candidate and at least one backup candidate so the quoted workload and acceptable task set are
real. For each task/language report dataset hash, rubric, sample size, exclusions, structured-output
validity, safety/numeric failures, typical/P50 and peak/P95 latency, retry/failover and token
distribution. DEC-COM-092
removes public-customer observation as a G1 prerequisite, but it does not permit invented quality
or workload inputs. A cloud path proceeds only when at least one core task has a product-owner-
accepted need that the local path cannot meet and `G1_UNIT_ECONOMICS_PACKET.md` accepts its cost.

## Quota and failure contract

- The current Monthly/Annual TestFlight path remains unchanged during G1. The owner-directed G1
  hypothesis instead evaluates a US$4.99 one-time local-Pro unlock with finite starter credits and
  separately purchased consumable usage cards. No count, price, reset/expiry, or product shape is
  accepted until G1; no option may create unlimited cloud liability.
- Request IDs and usage accounting are idempotent. Cancelled/failed attempts follow the later
  accepted charging rule; retries cannot multiply-charge silently.
- Per-tier rate, body, token, concurrency, daily/monthly and cost caps are mandatory.
- Exhaustion, denial, offline state, timeout, provider failure, invalid output and cost breaker all
  return the complete local path without affecting local Pro or Free features.
- No “unlimited,” “fair use” substitute, or provider-specific promise appears before terms are
  measured and accepted.
