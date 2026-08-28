#!/usr/bin/env bash
set -euo pipefail

# C5-03 is an offline/read-only evidence package. Keep its metric IDs, source boundaries, aggregate
# receipt semantics, and dormancy assertions synchronized with the execution packet and tests.

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

WORKER_ROOT="Services/TelemetryWorker"
METRICS_SOURCE="${WORKER_ROOT}/src/metrics.ts"
EVIDENCE_TOOL="${WORKER_ROOT}/tools/build-c5-evidence.mjs"
METRICS_TEST="${WORKER_ROOT}/test/metrics.spec.ts"
EVIDENCE_TEST="${WORKER_ROOT}/test/c5-evidence.contract.mjs"
EVIDENCE_TEMPLATE="${WORKER_ROOT}/evidence/c5-evidence-input.template.json"
WORKER_ENTRY="${WORKER_ROOT}/src/index.ts"
WORKER_PACKAGE="${WORKER_ROOT}/package.json"
EVIDENCE_CONTRACT="Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md"

for file in \
  "${METRICS_SOURCE}" \
  "${EVIDENCE_TOOL}" \
  "${METRICS_TEST}" \
  "${EVIDENCE_TEST}" \
  "${EVIDENCE_TEMPLATE}" \
  "${WORKER_ENTRY}" \
  "${WORKER_PACKAGE}" \
  "${EVIDENCE_CONTRACT}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing C5-03 metrics artifact: ${file}" >&2
    exit 1
  fi
done

for metric_identifier in \
  app_store_download_conversion \
  app_store_trial_to_paid \
  app_store_usage_opt_in \
  receipt_acquired_from_opened \
  receipt_reviewed_from_acquired \
  receipt_saved_from_reviewed \
  survey_response_rate \
  survey_pro_value_positive \
  survey_receipt_value_positive; do
  grep -Fq "${metric_identifier}" "${EVIDENCE_TOOL}" || {
    echo "C5-03 evidence vocabulary is missing ${metric_identifier}" >&2
    exit 1
  }
done

for evidence_anchor in \
  'const EVIDENCE_VERSION = "c5-03-v1"' \
  'wilson_score_95_outward_rounded_basis_points' \
  'source_suppressed' \
  'zero_denominator' \
  'not_collected' \
  'metric_artifact_source' \
  'inputStat.size > MAXIMUM_INPUT_BYTES' \
  'await link(temporaryPath, outputPath)' \
  'input and output paths must differ'; do
  grep -Fq "${evidence_anchor}" "${EVIDENCE_TOOL}" || {
    echo "C5-03 evidence tool is missing contract: ${evidence_anchor}" >&2
    exit 1
  }
done

for funnel_anchor in \
  'MAXIMUM_OBSERVATION_WINDOW_MILLISECONDS = 90 * 24 * 60 * 60 * 1000' \
  "event_name = 'receipt_flow'" \
  "outcome = 'completed'" \
  'occurred_at_ms >= ?2' \
  'occurred_at_ms < ?3' \
  "candidate.action = 'acquired'" \
  "candidate.action = 'reviewed'" \
  "candidate.action = 'saved'" \
  'openedGenerations: row.opened_generations' \
  'reviewedGenerations: row.reviewed_generations'; do
  grep -Fq "${funnel_anchor}" "${METRICS_SOURCE}" || {
    echo "C5-03 receipt funnel is missing contract: ${funnel_anchor}" >&2
    exit 1
  }
done

if grep -Eq '\b(INSERT|UPDATE|DELETE|REPLACE)\b' "${METRICS_SOURCE}"; then
  echo "C5-03 receipt metrics query must remain read-only" >&2
  exit 1
fi

if grep -Eq 'from "\./metrics"|from "\./metrics\.ts"|/v1/metrics|/v1/evidence' "${WORKER_ENTRY}"; then
  echo "C5-03 metrics must not create a customer/admin HTTP route or enter the live Worker" >&2
  exit 1
fi

for forbidden_evidence_shape in \
  'fetch(' \
  'https://' \
  'Authorization' \
  'Cookie' \
  'customerID' \
  'deviceID' \
  'emailAddress' \
  'merchantName' \
  'receiptText'; do
  if grep -Fq "${forbidden_evidence_shape}" "${EVIDENCE_TOOL}"; then
    echo "C5-03 offline evidence tool contains forbidden shape: ${forbidden_evidence_shape}" >&2
    exit 1
  fi
done

for package_anchor in \
  '"evidence:build": "node tools/build-c5-evidence.mjs"' \
  '"test:evidence": "node --test test/c5-evidence.contract.mjs"' \
  'npm run test:evidence'; do
  grep -Fq "${package_anchor}" "${WORKER_PACKAGE}" || {
    echo "Telemetry package is missing C5-03 command: ${package_anchor}" >&2
    exit 1
  }
done

for test_anchor in \
  'counts only ordered completed stages in one app-version and half-open window' \
  'accepts a later valid chain without letting a premature stage satisfy it' \
  'rejects malformed, empty, reversed, and over-retention scopes'; do
  grep -Fq "${test_anchor}" "${METRICS_TEST}" || {
    echo "C5-03 receipt tests are missing: ${test_anchor}" >&2
    exit 1
  }
done

for test_anchor in \
  'uses a fixed outward-rounded Wilson 95 percent interval' \
  'distinguishes Apple suppression, a proven zero denominator, and no collection' \
  'rejects missing metrics, impossible counts, and source-digest substitution' \
  'CLI commits canonical evidence once and refuses to overwrite it'; do
  grep -Fq "${test_anchor}" "${EVIDENCE_TEST}" || {
    echo "C5-03 evidence tests are missing: ${test_anchor}" >&2
    exit 1
  }
done

node --check "${EVIDENCE_TOOL}"
validation_directory="$(mktemp -d "${TMPDIR:-/tmp}/mindbudget-c5-evidence-gate.XXXXXX")"
trap 'rm -rf -- "${validation_directory}"' EXIT
node "${EVIDENCE_TOOL}" \
  --input "${EVIDENCE_TEMPLATE}" \
  --output "${validation_directory}/evidence.json"
(
  cd "${WORKER_ROOT}"
  npm run test:evidence
)

echo "C5-03 telemetry metrics evidence contract passed"
