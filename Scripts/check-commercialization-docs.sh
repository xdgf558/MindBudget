#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

SOURCE_PROVENANCE="Docs/Commercialization/SOURCE_PROVENANCE.md"
MONTHLY_PRODUCT_ID="com.xdgf558.mindbudget.pro.monthly"
ANNUAL_PRODUCT_ID="com.xdgf558.mindbudget.pro.annual"

required_files=(
  AGENTS.md
  Docs/PROJECT_MEMORY.md
  Docs/COMMERCIALIZATION_TASKS.md
  Docs/Commercialization/PROJECT_MEMORY.md
  Docs/Commercialization/DECISIONS.md
  Docs/Commercialization/SESSION_LOG.md
  Docs/Commercialization/REQUIREMENTS_INDEX.md
  Docs/Commercialization/SPEC_CONFLICTS.md
  Docs/Commercialization/SOURCE_PROVENANCE.md
  Docs/PRIVACY_AND_REVIEW_NOTES.md
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md
  Docs/Commercialization/STOREKIT_TEST_MATRIX.md
  Docs/Commercialization/REGIONAL_PRICING.md
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md
  Docs/Commercialization/CI_BASELINE.md
  Docs/Commercialization/COM_C1_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C2_EXECUTION_PACKET.md
)

for file in "${required_files[@]}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing or empty commercialization artifact: ${file}" >&2
    exit 1
  fi
done

SOURCE_SHA="$(
  sed -n 's/^- SHA-256: `\([0-9a-f][0-9a-f]*\)`.*/\1/p' "${SOURCE_PROVENANCE}" |
    head -n 1
)"
if [[ ! "${SOURCE_SHA}" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Commercial source provenance must contain one valid SHA-256 fingerprint" >&2
  exit 1
fi

grep -Fq 'it is not a claim that CI can read or automatically detect changes' \
  "${SOURCE_PROVENANCE}" || {
  echo "Commercial source provenance must state the external-drift limitation" >&2
  exit 1
}

for file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md; do
  grep -Fq "${SOURCE_SHA}" "${file}" || {
    echo "Commercial source snapshot fingerprint is missing from ${file}" >&2
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

contains_open_p0() {
  awk '
  {
    line = tolower($0)
    has_p0 = line ~ /(^|[^[:alnum:]_])p0([^[:alnum:]_]|$)/
    has_open = line ~ /(^|[^[:alnum:]_])open([^[:alnum:]_]|$)/
    if (index(line, "priority/status:") && has_p0 && has_open) {
      found = 1
    }
  }
  END { exit found ? 0 : 1 }
  ' "$@"
}

if ! contains_open_p0 <<< '- Priority/status: **Open (P0)**'; then
  echo "Commercial conflict gate no longer detects order-independent Open P0 status" >&2
  exit 1
fi
if contains_open_p0 <<< '- Priority/status: **P1 — Open**'; then
  echo "Commercial conflict gate incorrectly classifies non-P0 status" >&2
  exit 1
fi
if contains_open_p0 <<< '- Priority/status: **Open-ended P01 review**'; then
  echo "Commercial conflict gate must token-match both Open and P0" >&2
  exit 1
fi

if contains_open_p0 Docs/Commercialization/SPEC_CONFLICTS.md; then
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

for access_boundary_contract in \
  'No feature-access or application path reads `version1Bits` or `version1KnownBits`' \
  'Never use `isSuperset(of: .free)`' \
  'Subscription checks exist only in the central access service'; do
  grep -Fq "${access_boundary_contract}" Docs/Commercialization/COM_C1_EXECUTION_PACKET.md || {
    echo "COM-C1 execution packet is missing access-boundary review contract: ${access_boundary_contract}" >&2
    exit 1
  }
done

grep -Fq '## COM-C1 — Entitlement model and Feature Access' Docs/COMMERCIALIZATION_TASKS.md || {
  echo "COM-C1 task section is missing" >&2
  exit 1
}

grep -Fq 'Status: **Done.** All three packets were independently reviewed and merged' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "COM-C1 must be recorded as completed before COM-C2" >&2
  exit 1
}

grep -Fq 'Status: **In Progress — C2-01 and C2-02 completed; C2-03 is In Progress after its runtime-probe entry gate passed.**' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "COM-C2 must record C2-01/C2-02 complete and C2-03 active after its accepted probe evidence" >&2
  exit 1
}

grep -Fq 'Status: **Done** after independent review and full validation.' \
  Docs/Commercialization/COM_C2_EXECUTION_PACKET.md || {
  echo "COM-C2 execution packet must record C2-01 as Done" >&2
  exit 1
}

grep -Fq 'Status: **Done** after independent review, green CI, and merge through PR #29 (`a45d480`).' \
  Docs/Commercialization/COM_C2_EXECUTION_PACKET.md || {
  echo "COM-C2 execution packet must record C2-02 as reviewed, merged, and Done" >&2
  exit 1
}

grep -Fq 'Status: **In Progress after the runtime-probe entry gate passed on a physical final iPhone.**' \
  Docs/Commercialization/COM_C2_EXECUTION_PACKET.md || {
  echo "COM-C2 execution packet must record C2-03 active after its runtime probes passed" >&2
  exit 1
}

for evidence in \
  'final Xcode 26.6 `17F113`' \
  'iOS 26.6.1 `23G82`' \
  '5 passed, 0 failed, 0 skipped' \
  'both the CHN and USA `Product.products(for:)` probes passed' \
  '/private/tmp/MindBudget-C2-03-Physical-Unlocked-iOS26.6.1-17F113.xcresult'; do
  grep -Fq "${evidence}" Docs/Commercialization/COM_C2_EXECUTION_PACKET.md || {
    echo "COM-C2 execution packet is missing accepted C2-03 entry evidence: ${evidence}" >&2
    exit 1
  }
done

grep -Fq '| Xcode 26.6 final `17F113`, physical `iPhone Air`, final iOS 26.6.1 `23G82` | 5 passed, 0 failed, 0 skipped; CHN Passed; USA Passed | Accepted supported-final physical-device evidence; C2-03 entry gate passed |' \
  Docs/Commercialization/STOREKIT_TEST_MATRIX.md || {
  echo "StoreKit test matrix is missing the accepted C2-03 physical-device evidence" >&2
  exit 1
}

if grep -Fq 'No runtime-probe pass is claimed.' Docs/Commercialization/PROJECT_MEMORY.md; then
  echo "Commercial project memory still contains the superseded pre-C2-03 probe status" >&2
  exit 1
fi

for heading in \
  '## Input gate' \
  '## C2-01 — StoreKit test catalog' \
  '## C2-02 — Runtime catalog and entitlement store' \
  '## C2-03 — Purchase, restore, and status mapping' \
  '## C2-04 — Environment and regression gate'; do
  grep -Fq "${heading}" Docs/Commercialization/COM_C2_EXECUTION_PACKET.md || {
    echo "COM-C2 execution packet is missing ${heading}" >&2
    exit 1
  }
done

if grep -Eq 'all ten (SwiftData|model)|ten SwiftData|all ten model' \
  Docs/PRIVACY_AND_REVIEW_NOTES.md Docs/PROJECT_MEMORY.md Docs/TEST_PLAN.md; then
  echo "Current deletion documentation still contains the stale ten-model count" >&2
  exit 1
fi

grep -Fq 'budget-plan-semantics' Docs/PRIVACY_AND_REVIEW_NOTES.md || {
  echo "Current deletion documentation is missing the BudgetPlanSemantics table" >&2
  exit 1
}

if grep -Eq 'SPEC-015 (open|remains open)' \
  Docs/Commercialization/PROJECT_MEMORY.md Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Commercial memory still describes accepted SPEC-015 as open" >&2
  exit 1
fi

echo "Commercialization documentation gate passed"
