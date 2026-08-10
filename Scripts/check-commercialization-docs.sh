#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

SOURCE_SHA="290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0"
MONTHLY_PRODUCT_ID="com.xdgf558.mindbudget.pro.monthly"
ANNUAL_PRODUCT_ID="com.xdgf558.mindbudget.pro.annual"

required_files=(
  AGENTS.md
  Docs/PROJECT_MEMORY.md
  Docs/COMMERCIALIZATION_TASKS.md
  Docs/Commercialization/PROJECT_MEMORY.md
  Docs/Commercialization/DECISIONS.md
  Docs/Commercialization/SESSION_LOG.md
  Docs/PRIVACY_AND_REVIEW_NOTES.md
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md
  Docs/Commercialization/STOREKIT_TEST_MATRIX.md
  Docs/Commercialization/REGIONAL_PRICING.md
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md
  Docs/Commercialization/CI_BASELINE.md
  Docs/Commercialization/COM_C1_EXECUTION_PACKET.md
)

for file in "${required_files[@]}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing or empty commercialization artifact: ${file}" >&2
    exit 1
  fi
done

for file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md; do
  grep -Fq "${SOURCE_SHA}" "${file}" || {
    echo "Commercial source SHA is missing from ${file}" >&2
    exit 1
  }
done

requirement_ids=(
  REQ-R1-NET-001
  REQ-R1-TELEMETRY-001
  REQ-ENTITLEMENT-001
  REQ-STOREKIT-STATE-001
  REQ-STOREKIT-LIFECYCLE-001
  REQ-MONEY-001
  REQ-MONEY-MIGRATION-001
  REQ-RECEIPT-PIPELINE-001
  REQ-RECEIPT-PRIVACY-001
  REQ-ICLOUD-001
  REQ-CLOUD-AUTH-001
  REQ-CLOUD-CONSENT-001
  REQ-CLOUD-USAGE-001
  REQ-G1-001
  REQ-WATCH-SCOPE-001
  REQ-WATCH-SYNC-001
  REQ-WATCH-ENTITLEMENT-001
  REQ-WATCH-PRIVACY-001
)

for requirement_id in "${requirement_ids[@]}"; do
  grep -Fq "| ${requirement_id} |" Docs/Commercialization/REQUIREMENTS_INDEX.md || {
    echo "Missing commercialization Requirement ID: ${requirement_id}" >&2
    exit 1
  }
done

if grep -Eq 'Priority/status:.*P0.*Open' Docs/Commercialization/SPEC_CONFLICTS.md; then
  echo "An unresolved P0 commercialization specification conflict remains" >&2
  exit 1
fi

entitlement_row="$(grep -F '| REQ-ENTITLEMENT-001 |' Docs/Commercialization/REQUIREMENTS_INDEX.md)"
if [[ "${entitlement_row}" != *'Active'* || "${entitlement_row}" == *'BLOCKED_BY_SPEC'* ]]; then
  echo "REQ-ENTITLEMENT-001 is not ready for COM-C1" >&2
  exit 1
fi

for product_id in "${MONTHLY_PRODUCT_ID}" "${ANNUAL_PRODUCT_ID}"; do
  for file in Docs/Commercialization/DECISIONS.md Docs/Commercialization/STOREKIT_TEST_MATRIX.md; do
    grep -Fq "${product_id}" "${file}" || {
      echo "Accepted Product ID ${product_id} is missing from ${file}" >&2
      exit 1
    }
  done
done

grep -Fq 'current Release allow-list is empty' Docs/Commercialization/PROJECT_MEMORY.md || {
  echo "Current empty Release egress baseline is not recorded" >&2
  exit 1
}

grep -Fq 'Current app-owned HTTP(S) | Accepted empty set' \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md || {
  echo "Network policy must contain the accepted empty current allow-list" >&2
  exit 1
}

grep -Fq '**All commercial values are TBD.**' Docs/Commercialization/REGIONAL_PRICING.md || {
  echo "Regional pricing must remain explicitly TBD before the evidence gate" >&2
  exit 1
}

for heading in '## Input gate' '### Tasks' '### Tests' '### Stop conditions'; do
  grep -Fq "${heading}" Docs/Commercialization/COM_C1_EXECUTION_PACKET.md || {
    echo "COM-C1 execution packet is missing ${heading}" >&2
    exit 1
  }
done

if grep -Eq 'all ten (SwiftData|model)|ten SwiftData|all ten model' \
  Docs/PRIVACY_AND_REVIEW_NOTES.md Docs/PROJECT_MEMORY.md Docs/TEST_PLAN.md; then
  echo "Current deletion documentation still contains the stale ten-model count" >&2
  exit 1
fi

echo "Commercialization documentation gate passed"
