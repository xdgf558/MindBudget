# AI Provider Contract

## Current status

DEC-COM-092/093 and reviewed PR #98 (`9226985`, run `33570570896`, merge `6e2d242`) produced the
historical `INSUFFICIENT_QUOTE_EVIDENCE` quote package closed by DEC-COM-094. DEC-COM-095 now
selects OpenAI `gpt-5.6-luna` as the only permitted future cloud model and records
`EVAL_AND_ACCOUNT_EVIDENCE_PENDING`. DEC-COM-096 subsequently freezes the exact Eval and offer;
DEC-COM-097 accepts standard retention for synthetic Eval only while keeping production false.
DEC-COM-098 records completed synthetic account admission and attempt 3's 24/24 first-pass
automated result after preserving two non-pass attempts. Independent review found no P1/P2 on PR
#100 head `323d8d7`; run `33593253561` passed and merge `7a473d2` delivered it. DEC-COM-099 closes
only that evidence delivery. The G1 state is `EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`.
Selection and a reviewed synthetic Eval pass are not
activation: no server adapter, client route, customer request, or customer promise exists until G1
and later gates pass. The Luna-only scorer result also does not satisfy the still-open fixed
bilingual three-way comparative Eval across deterministic template, supported on-device output,
and Luna.

Existing deterministic templates and optional on-device Foundation Models remain the complete
product. If Luna is unavailable, unsupported, outside the disclosed retention policy, over budget,
or never admitted,
the app stays correct through its deterministic local path. There is no provider failover.
The current quote-backed planning envelope is US$0.011330 typical/P50 and US$0.018986 peak/P95 at
1,000 monthly successes; these are not measured Eval distributions.

## Luna admission matrix

Every field requires dated account-level evidence. Published pricing alone is insufficient.

| Field | Required evidence | Reject when |
|---|---|---|
| Legal model identity | OpenAI contract, exact `gpt-5.6-luna` model ID, policy URL/version, quote date | Identity or material terms are ambiguous |
| Processing and storage regions | Request, log, abuse-monitoring, backup and support-access regions | Accepted storefront/consent cannot lawfully cover them |
| Retention and training | No voluntary training; exact configured retention disclosed and accepted before first production use; `store=false`, no background mode, and no implicit cache breakpoint | Training sharing is enabled, retention is undisclosed, or consent does not match the configured policy |
| Subprocessors | Current list and material-change notification | Hidden/uncontrolled subprocessor path exists |
| Security | Transport, encryption, access controls, incident process, relevant certifications | Evidence cannot support the threat model |
| Structured output | Fixed schema compliance and invalid-output rate | Output cannot be deterministically validated/fail closed |
| Quality/language | Blind fixed Eval for Simplified Chinese and English | No accepted advantage over local/template baseline |
| Latency/availability | P50/P95, timeout, bounded same-model retry and regional availability | Fallback becomes disruptive or SLO fails |
| Cost | Input/output/retry P50/P95 plus backend cost at low/expected/high volume | Any offered SKU cannot preserve the 50% peak margin gate |
| Content controls | Exact allow-listed aggregate schema and output validator | Requires raw ledger, notes, receipt image/OCR, identifiers, or free-form source text |

## Consent-bound single provider

Consent is a versioned tuple of OpenAI/Luna, purpose, outbound field schema, processing/retention
summary, and policy version. A model, region, retention/training behavior, purpose, or material
policy change moves status to `requiresRenewal`; no request is sent until renewed. No runtime router
may substitute another provider. Luna failure returns on-device AI when available or the complete
deterministic template.

## Data contract

Every future schema must satisfy:

- deterministic, typed, bounded, allow-listed aggregate facts only;
- exact money represented as minor units plus currency code when genuinely needed;
- no raw transaction rows, notes, merchant list, receipt image/OCR/line name, original free-form
  question/reason, device contact data, or cross-app data;
- stable identifiers replaced by request-scoped or coarse values unless separately proven needed;
- client redaction before transport and independent server validation/redaction before Luna;
- content-free logs and telemetry; prompts/responses are not admin-viewable; and
- structured, bounded, language/numeric/safety-validated output that never owns money, rules,
  entitlement, quota, diagnosis, financial advice, or an app action.

## Routing, charging, and test boundary

- The server owns the sole exact Luna model allow-list and credential. The client contacts only the
  later accepted first-party backend and never submits a provider/model ID.
- One user-initiated analysis reserves one credit. Exactly one valid structured Luna result
  ultimately displayed commits it. Cancellation, offline state, timeout, denial, provider error,
  and invalid output
  release it. A regeneration is a new analysis and costs another credit.
- Every future cloud-AI feature inherits this same accounting boundary; it cannot invent a hidden
  free call, alternate model, or separate quota.
- The 30-day Pro trial, on-device AI, and deterministic template make no Luna request and grant
  zero Luna credits. Unsupported on-device AI falls back to the template.
- Ordinary test users, including Simulator, UI-test, StoreKit Sandbox, and TestFlight, cannot reach
  Luna. Apple App Review is the sole possible test exception and requires an isolated hard-capped review route,
  separate authorization, and release evidence.

## Evaluation gate

G1 freezes the versioned 24-case Eval in `G1_LUNA_EVAL.md`, scoring Luna against the same closed
facts/actions and deterministic template baseline. Supported on-device output remains a separate
local path and is not misrepresented as a Luna/account run. Dataset SHA-256 is
`d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014`; prompt/schema SHA-256 is
`c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018`. For each task/language it
reports sample size, exclusions,
structured-output validity, safety/numeric failures, input/output token P50/P95, latency P50/P95,
and bounded same-model retry. DEC-COM-092 removed public-customer observation as a prerequisite; it
did not permit invented quality or workload inputs. At least one task must have an owner-accepted
need that Luna satisfies beyond the complete local path.

## Offer and failure contract

- Formal launch policy is a US$4.99 non-consumable Pro buyout with exactly 10 post-purchase Luna
  credits and three separately purchased cards: 10 uses / US$0.99, 25 uses / US$1.99, and 65 uses /
  US$4.99. The old Monthly/Annual/P1W catalog is historical
  nonpublic test evidence and will be replaced only in a later authorized phase.
- The explicitly started 30-user-calendar-day trial is local-only and nonrenewing.
- Starter and purchased lots expire one user-calendar year after grant; expiry is persisted as an
  authoritative instant and is never reconstructed with fixed seconds.
- Per-SKU peak contribution margin must remain at least 50%; below 1,000 trailing-30-day successful
  analyses, or below the recomputed 50% margin, the server stops new card sales and starter grants
  without harming local Pro or unexpired purchased credits.
- Request IDs, grants, reservations, commits, releases, refunds, and deletion are idempotent.
- Exhaustion, denial, offline state, timeout, provider failure, invalid output, a material retention-policy change, and a cost
  breaker all return the complete local path.
- No “unlimited,” “fair use,” provider substitution, or silent automatic top-up is permitted.
