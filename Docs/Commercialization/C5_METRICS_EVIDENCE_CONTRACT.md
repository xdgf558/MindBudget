# C5 Metrics and Evidence Contract

Status: **C5-03 Done after pre-merge review of head `4ea7cd9`, post-merge PR #81 verification of
remediation head `0c61427`, green GitHub Actions run `33211270363`, and PR #80 merge `a587f42`.**
C5-04 entered on 2026-08-29 and remains In Progress; its runtime activation cannot change this
immutable evidence format or manufacture a G1 result.

## Purpose and non-goals

C5-03 defines a reproducible evidence shape for later R1/G1 observation. Its implementation did not
collect customer data, construct `TelemetryClient` or `FixedTelemetryTransport`, add an app capture
call, add a Worker route, deploy Staging/Production, change App Privacy answers, or decide G1.
C5-04's reviewed PR #82 merge `28d9eae` adds an optional default-off live client and closed capture
sites from exact remediation head `2c1cebe` after green run `33233846430`, but that separate runtime
cannot change evidence inputs, thresholds, or the absence of a current G1 decision.

The checked-in evidence builder consumes only manually supplied aggregate counts and SHA-256
digests of source exports. It never accepts receipt text, merchant, amount, budget, note, account,
device, email, advertising identifier, or arbitrary metric names. Raw App Store reports and raw
survey responses are not committed to this repository.

## Fixed observation scope

Every evidence bundle records:

- evidence schema `1` and evidence vocabulary `c5-03-v1`;
- the evaluated app version and telemetry schema version `1`;
- one UTC half-open observation window `[start, end)` no longer than 90 days;
- one or more exact `environment / appVersion / storefront / deviceFamily` segments;
- coverage only inside each exact segment, with no root-level or cross-segment roll-up;
- source-export timestamps and lowercase SHA-256 digests; and
- all nine required metric IDs, including explicit unavailable states.

The generator requires `generatedAt >= observationWindow.end`, rejects duplicate segments,
unknown keys, normalized-invalid timestamps, unsafe integers, inconsistent source kinds, missing
metrics, and replacement of an existing output path. Output JSON is canonicalized and committed
once with a read-back check.

## Metric definitions

Every available proportion reports the exact integer numerator, denominator, and sample size. The
estimate is integer basis points. Its confidence interval is a two-sided 95% Wilson score interval,
rounded outwards to integer basis points (`floor` lower, `ceil` upper), recorded as method
`wilson_score_95_outward_rounded_basis_points`. A denominator of zero is
not 0%: it is the distinct `zero_denominator` status with no estimate or confidence interval.

| Metric ID | Numerator | Denominator | Sample size | Source |
|---|---|---|---|---|
| `app_store_download_conversion` | Total downloads plus pre-orders | Unique device impressions | Unique device impressions | App Store Connect Analytics |
| `app_store_trial_to_paid` | Completed free trials that converted to paid | Completed free trials | Completed free trials | App Store Connect Analytics |
| `app_store_usage_opt_in` | Devices included in Apple's usage reporting | Eligible devices reported by Apple | Apple's reported eligible devices | App Store Connect Analytics |
| `receipt_acquired_from_opened` | Ordered generations reaching acquired | Generations reaching opened | Generations reaching opened | First-party aggregate |
| `receipt_reviewed_from_acquired` | Ordered generations reaching reviewed | Generations reaching acquired | Generations reaching opened | First-party aggregate |
| `receipt_saved_from_reviewed` | Ordered generations reaching saved | Generations reaching reviewed | Generations reaching opened | First-party aggregate |
| `survey_response_rate` | Completed fixed-form surveys | Confirmed delivered invitations | Confirmed delivered invitations | Voluntary survey aggregate |
| `survey_pro_value_positive` | `yes` answers to question Q1 | `yes + no` answers to Q1 | Completed fixed-form surveys | Voluntary survey aggregate |
| `survey_receipt_value_positive` | `yes` answers to question Q2 | `yes + no` answers to Q2 | Completed fixed-form surveys | Voluntary survey aggregate |

Apple currently defines App Store conversion as total downloads and pre-orders divided by unique
device impressions, and says usage metrics come only from users who opted to share diagnostics and
usage data. Analytics reports may suppress low-volume rows and add privacy-preserving noise. The
workflow therefore accepts source integers only when an official report exposes them. It never
reverse-engineers a numerator from a displayed percentage and never treats a suppressed row as
zero. References:

- <https://developer.apple.com/help/app-store-connect-analytics/reference/metrics-definitions>
- <https://developer.apple.com/help/app-store-connect-analytics/overview/analytics-reports-api>

## Source status and coverage

Each metric has exactly one of four statuses:

- `available`: exact counts exist, the denominator is positive, and a matching source digest is
  present;
- `zero_denominator`: the source proves `0 / 0 / 0` and supplies a matching digest;
- `source_suppressed`: the source exists but withholds the counts, so all count fields stay null;
- `not_collected`: no source evidence exists, so counts and digest all stay null.

Coverage is evidence completeness, not a claim about the customer population. `available` coverage
counts only rows with computable estimates. Evidence-bearing coverage also counts proven-zero and
source-suppressed rows, while excluding `not_collected`. The current closed telemetry schema cannot
measure the share of all customers who enabled telemetry: opt-out devices send nothing, and Apple
usage opt-in describes a different population. C5-03 therefore forbids dividing telemetry
pseudonyms by Apple Active Devices and calling that a participation rate.

Coverage is emitted only inside an exact `environment / appVersion / storefront / deviceFamily`
segment. The bundle has no root coverage because Development cannot support a Production decision,
and `ALL` may overlap a specific storefront while device-family segments may describe different
populations. A later G1 decision must cite its exact segment and may not average, add, or otherwise
roll coverage across segments.

`available` means the source exposes a computable proportion; it does not mean the sample is
adequate. Every segment therefore reports `widestConfidenceIntervalBasisPoints`, the widest upper
minus lower 95% Wilson interval among its available metrics, or `null` when none are available. A
`1 / 1` metric remains truthfully available but makes weak evidence visible through its 7,935-basis-
point interval width. C5-03 invents no minimum denominator or G1 acceptance threshold.

## Receipt funnel

`receiptFunnelCounts` is a read-only D1 aggregation with no HTTP route. It returns four integers and
never returns an event row or pseudonym. A funnel member is one telemetry pseudonym generation,
not a person, device, Apple Account, or durable user. The query is scoped to one exact app version
and a half-open window of at most 90 days.

Only `receipt_flow` events with `outcome = completed` participate. A generation counts as acquired
only after a completed open, reviewed only after a qualifying acquire, and saved only after a
qualifying review. Premature, cancelled, failed, unavailable, other-version, and end-boundary
events do not advance the funnel. Identity rotation, opt-out/re-enable, or deletion may split one
person across generations; the report must retain the generation label and must not relabel it as
unique users.

## App Store workflow

1. Freeze the app version, UTC observation window, storefront, device family, and report date.
2. Export the official App Store Connect Analytics source report. Keep credentials and raw exports
   outside the repository and record the export's SHA-256 digest.
3. Copy only the aggregate integers defined above. If Apple omits or threshold-suppresses a row,
   record `source_suppressed`; if the report is absent, record `not_collected`.
4. Do not combine filters with different populations, observation windows, opt-in semantics,
   environments, storefront scopes, or device families. Keep every comparison on its exact segment.
5. Generate an immutable evidence bundle with:

   ```bash
   cd Services/TelemetryWorker
   npm run evidence:build -- --input INPUT.json --output OUTPUT.json
   ```

6. Independently compare the canonical output to the source aggregates before any later G1 owner
   decision. C5-03 produces no acceptance threshold and no `PROCEED_TO_R2` result.

## Voluntary survey workflow

The survey is optional, independent of purchase/entitlement, and may not request budget, income,
expense, receipt, merchant, note, account, contact, or device data. It has no hidden response ID and
no free-text field in the C5 evidence bundle. An invitation count is recorded only when delivery is
confirmed; duplicate submissions are removed by the survey operator before aggregate counts enter
the bundle. `prefer not to answer` stays in sample size but outside a yes/no denominator.

Fixed questionnaire `c5-survey-v1`:

- Q1 English: “After trying MindBudget Pro, did its local tools provide useful value?” Choices:
  `yes`, `no`, `prefer not to answer`.
- Q1 Simplified Chinese: “试用花有数 Pro 后，这些本地工具是否为你带来了有用价值？” Choices:
  `是`, `否`, `不愿回答`.
- Q2 English: “If you tried receipt import, did it save time compared with entering the expense
  manually?” Choices: `yes`, `no`, `did not use`, `prefer not to answer`.
- Q2 Simplified Chinese: “如果你试用了收据导入，与手动填写支出相比，它是否节省了时间？”
  Choices: `是`, `否`, `未使用`, `不愿回答`.

The survey operator records the questionnaire version, invitation method/date, delivered count,
completed count, per-question eligible denominator, and aggregate yes/no counts. Quotes or raw
answers are separate qualitative evidence and must not be inserted into telemetry or this bundle.

## Current evidence state and exit boundary

No customer telemetry, App Store observation window, or survey sample has been collected under
this contract. The implementation proves the schema, validation, interval math, aggregation, and
failure states only. It does not claim metric success, funnel accuracy on production traffic, G1
readiness, or release approval.

C5-03 is Done through reviewed PR #80 merge `a587f42` without claiming collected evidence or G1
success. The owner entered C5-04 on 2026-08-29. Reviewed PR #82 merge `28d9eae` supplies customer
control/disclosure, capture-site audit, terminal endpoint-policy behavior, source App Privacy/data-
flow updates, and a Development operations runbook after exact head `2c1cebe` passed run
`33233846430`. Current-source operational evidence, App Store
Connect answers, Staging/Production deployment, final-binary traffic, and every G1/release decision
remain open.
