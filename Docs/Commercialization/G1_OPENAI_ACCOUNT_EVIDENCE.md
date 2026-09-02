# G1 OpenAI Account, Region, Privacy, Rate, and Billing Evidence

Status: **Fail closed — the standard-controls account is configured, but synthetic Eval admission
still awaits final privacy-setting confirmation and an isolated credential.** Formal outcome:
`OPENAI_ACCOUNT_NOT_ADMITTED`. This packet distinguishes the bounded synthetic Eval from any
future production use of customer data.

## Official OpenAI evidence checked 2026-09-02

| Subject | Official evidence | Accepted boundary |
|---|---|---|
| Luna identity and price | <https://developers.openai.com/api/docs/models/gpt-5.6-luna> | Exact model `gpt-5.6-luna`; published input/output prices remain the planning-rate source |
| Training default | <https://developers.openai.com/api/docs/guides/your-data> | API data is not used for training unless the customer opts in to sharing |
| Standard abuse retention | same data-controls page | Without approved ZDR/MAM, abuse-monitoring logs may retain customer content for up to 30 days |
| Responses behavior | same data-controls page and the Responses reference | The Eval uses `store=false`, no background mode, no tools/files/conversation state, and explicit prompt caching with no breakpoints |
| ZDR | same data-controls page | ZDR requires prior approval; it is an optional future enhancement, not a prerequisite for the synthetic Eval |
| Global processing | same data-controls page | A Global project may use `https://api.openai.com/v1`; this does not claim regional residency |

The product owner explicitly accepted the standard-retention boundary on 2026-09-02 for this
synthetic-only Eval. That acceptance does not authorize customer financial data. Production must
separately disclose OpenAI/Luna, Global processing, the outbound field schema, purpose, and the
up-to-30-day abuse-monitoring boundary before first use; a material policy change requires renewed
consent.

## Owner-observed account matrix — 2026-09-02

Identifiers and payment details are intentionally omitted. Dashboard captures supplied during the
owner session are operational observations rather than durable repository secrets.

| Evidence row | Observed value | Machine result | Consequence |
|---|---|---|---|
| Dedicated project | A separate Luna Eval project exists | `VERIFIED` | Eval traffic is isolated from unrelated projects |
| Model allow-list | Only `gpt-5.6-luna` is allowed | `VERIFIED` | No provider/model substitution |
| Project geography/base URL | Project geography is Global; standard API base URL selected | `VERIFIED` | No regional-residency claim |
| Standard retention | Owner accepted up-to-30-day abuse-monitoring retention for synthetic Eval | `VERIFIED` | ZDR is not claimed |
| Endpoint/features | Responses, `store=false`, `background=false`, strict structured output, explicit cache mode without breakpoints | `VERIFIED` | No persistent conversation/tool/file state is used |
| Usage/rate tier | Usage Tier 1; Luna 500,000 TPM, 500 RPM, 5,000,000 TPD | `VERIFIED` | Capacity is sufficient for 24 bounded cases |
| Billing controls | Pay-as-you-go credit balance US$18.72; auto-reload off; project US$5 soft limit/alert | `VERIFIED` | The Eval is funded and bounded; spend limits are not described as hard caps |
| Voluntary data sharing | All three organization sharing choices must be visibly Disabled after Save | `PENDING_CONFIRMATION` | No request until confirmed |
| API call logging | Organization API call logging must be visibly Disabled after Save | `PENDING_CONFIRMATION` | No request until confirmed |
| Credential isolation | Dedicated project service-account key, stored in macOS Keychain under `MindBudget Luna Eval` and outside Git/chat/screenshots | `PENDING_OWNER_ACTION` | No live Eval until complete |

Current machine evidence deliberately leaves `noDataSharing`, `apiCallLoggingDisabled`, and
`credentialIsolation` false. All other observed rows are true. Partial evidence is allowed to be
recorded, but `evalAdmitted` cannot become true until every synthetic-Eval row is true.

## Synthetic-Eval-only admission

`G1_OPENAI_ACCOUNT_ADMISSION.json` schema version 2 freezes:

- `scope: synthetic_eval_only` and `productionAdmitted: false`;
- exact Global base URL `https://api.openai.com/v1`;
- standard abuse-monitoring retention of up to 30 days, with no ZDR claim;
- `store=false`, `background=false`, and explicit prompt-cache mode with no cache breakpoints; and
- a boolean account-evidence matrix that must be complete before the runner can send.

The live runner rejects any other scope, a production-admitted state, an unknown base URL, changed
retention semantics, missing evidence, or a missing local Keychain credential. The credential is
read only for an explicit `--run-live` invocation and must never enter a repository document, PR,
issue, screenshot, command transcript, environment variable, or chat.

## Production boundary

Passing this account matrix and fixed Eval does **not** admit production traffic. Before a customer
request exists, later COM phases must independently review the consent copy, precise redacted
aggregate schema, processor/subprocessor disclosure, server-held credential, deletion and policy-
change behavior, Apple Privacy answers, final-binary egress, and isolated Apple Review route.
Receipt images, OCR text, merchants, notes, raw transactions, identifiers, and arbitrary user text
remain forbidden. ZDR may be adopted later, but production disclosure must describe the controls
actually configured rather than promising it in advance.

Until the two privacy confirmations and isolated credential are complete, the formal result remains
`OPENAI_ACCOUNT_NOT_ADMITTED`; no Luna request, quality pass, token/latency distribution, G1 pass,
COM-C7 entry, or product activation is claimed.
