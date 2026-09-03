# G1 OpenAI Luna Fixed Eval

Status: **The admitted synthetic-only account completed the fixed Luna Eval with a 24/24 automated
pass, and independent review read all 24 outputs with no P1/P2 finding.** Formal outcome:
`LIVE_LUNA_EVAL_AUTOMATED_PASS_INDEPENDENTLY_REVIEWED`.

## Purpose and non-claim

This Eval asks whether OpenAI `gpt-5.6-luna` can safely rewrite already-computed MindBudget facts
into short Simplified-Chinese and English coaching. It does not let the model calculate money,
choose an action, inspect a ledger, or replace the complete deterministic fallback. A passing
template self-test proves only that the scorer and frozen fixtures agree; it is not Luna quality,
latency, token, privacy, account, or release evidence.

The owner confirmed Saved disabled-sharing/API-logging settings and stored the isolated project
service-account key in macOS Keychain. The dedicated Global project, Luna-only allow-list, Tier 1
rate limits, bounded billing, and standard up-to-30-day abuse-monitoring boundary admitted only the
repository-authored synthetic cases. ZDR remains optional; production customer-data permission is
still false.

## Frozen material

| Item | Frozen value |
|---|---|
| Model | `gpt-5.6-luna` |
| Dataset | `G1_LUNA_EVAL_CASES.json` |
| Dataset SHA-256 | `d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014` |
| Prompt/schema SHA-256 | `c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018` |
| Scenarios | 12 deterministic product situations |
| Cases | 24: every scenario once in English and once in Simplified Chinese |
| Reasoning | `low` |
| Maximum output | 600 tokens |
| Retry | At most one bounded retry against the same model |
| Provider storage request | Responses API with `store: false`, `background: false`, explicit cache mode with no breakpoints; standard abuse-monitoring retention may be up to 30 days |

The scenarios cover positive/tight/over-budget states, category movement, self-tagged repeated
spending, no-pattern evidence, savings pace, fixed-cost pressure, cooling-off state, cycle pace,
income allocation, and insufficient data. Facts, fact IDs, action IDs, and numeric tokens are
closed allow-lists. Receipt text, merchant rows, notes, raw transactions, stable identifiers,
free-form user text, tools, files, web search, and conversation state are absent.

## Deterministic gates

Every final case must be schema-valid and must:

- preserve its exact `case_id`, required fact IDs, and allow-listed action IDs;
- introduce no numeric token absent from the supplied facts;
- introduce no diagnosis, promise, shame, judgment, or imperative wording from the rejection list;
- use Simplified Chinese for `zh` and no CJK characters for `en`; and
- keep headline/explanation and array cardinalities inside the closed schema.

The run-level admission gates are:

| Gate | Required value |
|---|---:|
| Final structured/safety validity | 24/24 |
| First-pass validity | at least 95.00% |
| Retry incidence | at most 5.00% (one of 24 cases) |
| Input-token P95 | at most 8,000 |
| Output-token P95 | at most 1,500 |
| End-to-end latency P95 | at most 8,000 ms |

`Scripts/g1_luna_eval.py --self-test` proves the closed templates pass and that an unknown fact,
invented amount, forbidden tone, retry overflow, and invalid final output fail loudly. The script
retains one record per attempt so an invalid first attempt followed by a valid retry is visible.
It refuses to overwrite an existing transcript and reads the dedicated credential from macOS
Keychain only for explicit `--run-live` execution. The default generic-password service name is
`MindBudget Luna Eval`; the secret never belongs in a command argument, environment variable,
repository file, PR, issue, screenshot, or chat transcript.

## Live-run admission and review

A live run may start only after the owner confirms the two Saved privacy settings, all synthetic-
Eval account rows are `VERIFIED`, and the exact machine-readable
`G1_OPENAI_ACCOUNT_ADMISSION.json` changes to `evalAdmitted: true` with one approved base URL while
`productionAdmitted` remains false. The owner enters the credential into the local macOS Keychain;
neither the key nor organization/project identifiers enter Git, logs, screenshots, environment
variables, or the Eval transcript. The selected base URL must match the proven account region.

The resulting JSONL and score report require an independent blind read of all 24 final responses
against the same fact/tone rubric. Passing the automated scorer alone is insufficient. Any dataset,
prompt, schema, model, endpoint feature, region, or threshold change creates a new hash and requires
a new run. This admission is synthetic-Eval-only; Luna remains disabled in the app and the
deterministic local template is the only admitted product fallback.

## 2026-09-02 execution evidence

The first run is an explicit non-pass: the original runner collapsed every HTTP rejection to
`HTTPError`, retried all 24 cases, and produced 48 zero-token failures. A diagnostic hardening then
made terminal 4xx responses stop after one request and retain only status, error code, and parameter.
The second run stopped after one request with
`HTTP_400:invalid_json_schema:text.format.schema`. The original schema used `minLength`,
`maxLength`, and `uniqueItems`, which the current strict Structured Outputs subset rejected.

The remediation removed only those provider-unsupported keywords from the wire schema. Local
`validate_output` still enforces non-empty/maximum text lengths, array cardinality, and uniqueness.
That compatibility change produced prompt/schema SHA-256
`c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018`; the dataset, model,
reasoning, facts, allowed actions, numeric/tone checks, retry policy, and thresholds did not change.

The third run passed:

| Measure | Observed | Gate |
|---|---:|---:|
| Final valid | 24/24 | 24/24 |
| First-pass valid | 24/24 (100.00%) | at least 95.00% |
| Retry cases | 0/24 (0.00%) | at most 5.00% |
| Input tokens P50 / P95 | 296 / 301 | P95 at most 8,000 |
| Output tokens P50 / P95 | 128 / 203 | P95 at most 1,500 |
| Latency P50 / P95 | 3,614 / 5,389 ms | P95 at most 8,000 ms |
| Hard failures | 0 | 0 |

Passing transcript:
`G1_LUNA_EVAL_TRANSCRIPT_2026-09-02_ATTEMPT3.jsonl`, SHA-256
`4800cc6c8458fa39b0bd4419d90fbf7ee4bfa47bc3deffa73475b751e947999e`.
The two non-pass transcript hashes and exact result are in
`G1_LUNA_EVAL_RESULT_2026-09-02.json`; they are not quality, latency, or token evidence.

The implementation author read all 24 final outputs and found no additional fact, number, tone,
locale, or action issue. Independent review then read all 24 outputs and the account/Eval packet on
exact PR #100 head `323d8d7`, found no P1/P2, and accepted the automated result. That head passed
GitHub Actions run `33593253561`; PR #100 merged it as `7a473d2`. The exact machine review record is
in `G1_LUNA_EVAL_RESULT_2026-09-02.json`.

The review left four nonblocking maintenance observations. Textual number words are not recognized
by the current Arabic-digit number scanner; failed attempts with zero latency/tokens would enter
run percentiles; missing provider usage fields currently default to zero; and the retry loop does
not consume `MAX_RETRIES_PER_CASE`. None affects this transcript because every case passed on its
first attempt with explicit nonzero usage, and the reviewer found no invented number in the 24
outputs. These limitations must be resolved or explicitly re-reviewed before the scorer supports a
future live Eval or implementation/release claim.

This Luna-only scoring run did not by itself satisfy the then-open fixed bilingual three-way comparative Eval
of deterministic template, supported on-device output, and Luna. That comparison
is now complete under DEC-COM-102: completed-review SHA-256
`d2b9310f4471400825e666009f646a190d8ac2819f859c8e38d58ec05cbf040e`, deterministic result
`NON_PASS`, zero materially preferred Luna cases, and no qualifying bilingual task. DEC-COM-104
later completed G1 at `DEFER_LUNA_CREDITS_KEEP_LOCAL_PRO`: production admission stays false,
COM-C7 through COM-C11 and every Luna/card product are deferred, and the local-only release path
must not reinterpret this synthetic run as customer or production evidence.
