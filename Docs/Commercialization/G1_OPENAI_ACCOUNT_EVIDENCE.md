# G1 OpenAI Account, Region, Privacy, Rate, and Billing Evidence

Status: **Fail closed — account admission is incomplete.** Formal outcome:
`OPENAI_ACCOUNT_NOT_ADMITTED`. This packet records public facts and the exact missing account
proof; it does not convert a public policy page into organization/project evidence.

## Public OpenAI evidence checked 2026-09-02

| Subject | Public evidence | What it proves | What it does not prove |
|---|---|---|---|
| Luna identity and price | <https://developers.openai.com/api/docs/models/gpt-5.6-luna> | `gpt-5.6-luna`; structured output; US$0.20/M input, US$0.02/M cached input, US$1.20/M output | The MindBudget account's billing tier, credit balance, negotiated price, or regional uplift |
| Published rate tiers | same Luna model page | Public Tier 1–5 RPM/TPM ranges exist | Which tier the MindBudget project currently receives |
| Training default | <https://platform.openai.com/docs/models/default-usage-policies-by-endpoint> | API data is not used for training unless the customer opts in | Whether this organization/project has opted into data sharing |
| Abuse retention | same data-controls page | Default abuse monitoring may retain prompts/responses for up to 30 days | That MindBudget has approved and enabled Zero Data Retention |
| ZDR endpoint behavior | same data-controls page | Responses API can be ZDR eligible with `store=false`; background mode is not ZDR compatible | Organization approval, project configuration, or feature compatibility for this account |
| Regional processing | same data-controls page | `us.api.openai.com` supports US storage and regional processing; other regions have distinct requirements | The selected MindBudget project region or contractual entitlement |

Published Luna rate limits retrieved on that date were Tier 1: 500 RPM/500,000 TPM; Tier 2:
5,000 RPM/2,000,000 TPM; Tier 3: 5,000 RPM/4,000,000 TPM; Tier 4: 10,000 RPM/10,000,000 TPM; and
Tier 5: 30,000 RPM/180,000,000 TPM. These values are supplier documentation, not a claim about the
current account.

## Mandatory account-level matrix

| Evidence row | Required artifact | Current result | Consequence |
|---|---|---|---|
| Dedicated organization/project identity | Non-secret organization/project names or redacted settings capture | `MISSING` | No request may be attributed to a reviewed project |
| Training/data-sharing state | Dated organization Data Controls capture showing no voluntary sharing | `MISSING` | Public default cannot prove current account state |
| Zero Data Retention | Dated approval plus exact project configuration for the Responses endpoint | `MISSING` | Default up-to-30-day abuse retention is unacceptable for this path |
| Project region/base URL | Dated project-region setting and contractual eligibility | `MISSING` | No regional API base URL is admitted |
| Endpoint/features | Evidence that Responses, `store=false`, structured output, and no background mode preserve ZDR | `MISSING` | The fixed request cannot run |
| Subprocessors and terms | Dated accepted DPA/terms and current subprocessor list/change path | `MISSING` | Consent/disclosure cannot name the complete processor chain |
| Usage/rate tier | Dated Limits page or API-account evidence | `MISSING` | Capacity and breaker cannot be sized from account facts |
| Billing/price controls | Dated billing state, hard/soft budget, and effective Luna rate | `MISSING` | A public list price is insufficient account cost proof |
| Credential isolation | Dedicated server-side project key created and stored outside client/repository | `MISSING` | No live Eval or later server call is permitted |

Environment inspection found no `OPENAI_API_KEY`, `OPENAI_ORG_ID`, or `OPENAI_PROJECT_ID`. That is a
safe absence check, not evidence that an account lacks these objects. Secret values must never be
pasted into a repository document, PR, issue, screenshot, or chat transcript.

## Exact evidence needed from the owner account

Before the live Eval, collect dated redacted captures or exports for:

1. the dedicated OpenAI organization/project identity and project region;
2. Organization Data Controls showing no data-sharing opt-in and the approved ZDR state;
3. the exact project ZDR/retention configuration for Responses API, structured output,
   `store=false`, and no background mode;
4. the organization/project Limits page and effective usage tier;
5. Billing/credits, effective Luna price, and a hard or operational budget cap;
6. accepted terms/DPA and the applicable OpenAI subprocessor list/change notice; and
7. creation of a dedicated server-side Eval credential, supplied only through a local environment
   variable for the explicit run.

The evidence may redact names and identifiers that are not needed for review, but it must retain
dates, region, setting values, and the scope (organization versus project). A generic pricing page,
model card, dashboard landing page, remembered setting, or personal account assertion does not
satisfy a row.

## Admission result

Because every mandatory account row is still `MISSING`, the approved base-URL allow-list is empty
for operational purposes even though the Eval runner knows possible public endpoints.
`G1_OPENAI_ACCOUNT_ADMISSION.json` machine-enforces `admitted: false`, a null approved base URL,
and nine false evidence rows; the live runner refuses to send while that reviewed artifact remains
closed. No Luna
request was sent, no token/latency distribution was measured, and no quality pass is claimed.
Cloud AI remains off; the 30-day trial grants zero Luna credits; Pro and local AI/template behavior
remain independent. Completing this matrix requires new owner account evidence, then an independent
review before the fixed live Eval may run.
