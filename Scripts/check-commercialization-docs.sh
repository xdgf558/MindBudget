#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

SOURCE_PROVENANCE="Docs/Commercialization/SOURCE_PROVENANCE.md"
PHASE_STATE_CHECKER="Scripts/commercialization_phase_states.py"
AUTHORITATIVE_PHASE_IDS="COM-C0A,COM-C0B,COM-C1,COM-C2,COM-C3,COM-C4A,COM-C4B,COM-C4C,COM-C5,COM-C6,COM-C6.5,G1,COM-C7,COM-C8,COM-C9,COM-C10,COM-C11,COM-C12"
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
  Docs/Commercialization/COM_C3_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md
  Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md
)

for file in "${required_files[@]}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing or empty commercialization artifact: ${file}" >&2
    exit 1
  fi
done

# Phase status is parsed structurally rather than being a growing collection of exact prose
# comparisons below. The checker proves its own missing/duplicate/status-conflict fixtures before
# it reads the durable phase map and execution packets. Require-all detects deletion of a Status
# below a retained heading; the approved top-level phase-ID set separately detects deletion of an
# authoritative phase without coupling the gate to mutable status prose. Newly structured
# subphases are protected automatically by require-all. C1's historical
# subpacket headings are the narrow source-level exception because that packet predates per-packet
# Status records; its top-level COM-C1 state remains mandatory in the authoritative task map.
python3 -B "${PHASE_STATE_CHECKER}" --self-test
python3 -B "${PHASE_STATE_CHECKER}" \
  --require-all-status Docs/COMMERCIALIZATION_TASKS.md \
  --require-all-status Docs/Commercialization/COM_C2_EXECUTION_PACKET.md \
  --require-all-status Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
  --require-all-status Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md \
  --expect-identifiers "Docs/COMMERCIALIZATION_TASKS.md:${AUTHORITATIVE_PHASE_IDS}" \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/Commercialization/COM_C1_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C2_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md

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

grep -Fq '**Formal commercial values are TBD; provisional C3 test terms were accepted on 2026-08-14.**' Docs/Commercialization/REGIONAL_PRICING.md || {
  echo "Regional pricing must distinguish provisional test terms from formal pricing" >&2
  exit 1
}

for c301_contract in \
  'US$1.99' \
  'US$19.99' \
  '7-day free trial for StoreKit-eligible subscribers' \
  'Hong Kong (HKG)' \
  'Taiwan (TWN)' \
  'zero automatic presentations'; do
  grep -Fq "${c301_contract}" Docs/Commercialization/COM_C3_EXECUTION_PACKET.md || {
    echo "COM-C3 execution packet is missing C3-01 contract: ${c301_contract}" >&2
    exit 1
  }
done

grep -Fq 'actions/runs/31766128587' Docs/Commercialization/CI_BASELINE.md || {
  echo "C3-01 green-CI run is missing from CI baseline" >&2
  exit 1
}

for c302_contract in \
  'verified current transaction must identify an introductory free trial' \
  'actual `renewalDate` and `willAutoRenew` facts' \
  'current trial product' \
  'next-renewal product' \
  '`autoRenewPreference`' \
  'five calendar days' \
  'never requests permission' \
  'Remove the old request before adding a replacement' \
  'trial ends soon' \
  'never promises renewal' \
  'no date, price, amount, product, or remaining-day count' \
  'DEC-COM-020'; do
  if ! grep -Fq "${c302_contract}" \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/STOREKIT_TEST_MATRIX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C3-02 trial-lifecycle contract is missing: ${c302_contract}" >&2
    exit 1
  fi
done

grep -Fq 'actions/runs/31803898776' Docs/Commercialization/CI_BASELINE.md || {
  echo "C3-02 green-CI run is missing from CI baseline" >&2
  exit 1
}

grep -Fq '`12d9217`' Docs/Commercialization/CI_BASELINE.md || {
  echo "C3-02 merge SHA is missing from CI baseline" >&2
  exit 1
}

if grep -Fq 'C3-01 implementation complete pending independent review' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C3-01 as pending review" >&2
  exit 1
fi

if grep -Fq 'C3-02 implementation complete pending' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C3-02 as pending review" >&2
  exit 1
fi

for c303_contract in \
  'Status: **Accepted by the owner for COM-C3-03 on 2026-08-14.**' \
  'mindbudget-public-config-dev.yehao1105.workers.dev' \
  'mindbudget-public-config-staging.yehao1105.workers.dev' \
  'mindbudget-public-config.yehao1105.workers.dev' \
  'anonymous `GET /v1/config`' \
  '"algorithm": "Ed25519"' \
  '`proValueTriggersEnabled` is the only v1 presentation field' \
  '`yyyy-MM-dd'\''T'\''HH:mm:ss'\''Z'\''`' \
  'without duplicate object keys' \
  'no longer than seven 24-hour intervals' \
  'same-version equivocation is rejected' \
  'sticky Release fail-closed' \
  'closed `transport.*` and `resolution.*` reason codes' \
  'DEC-COM-021'; do
  if ! grep -Fq "${c303_contract}" \
      Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C3-03 signed public-configuration contract is missing: ${c303_contract}" >&2
    exit 1
  fi
done

for c303_task_evidence in 'PR #36 (`1ebb36c`)' 'PR #38 (`db7926d`)'; do
  grep -Fq "${c303_task_evidence}" Docs/COMMERCIALIZATION_TASKS.md || {
    echo "COM-C3 task state must retain reviewed C3-03 evidence: ${c303_task_evidence}" >&2
    exit 1
  }
done

grep -Fq 'Signed public configuration | C3-03 Done through PR #38 (`db7926d`); Development deployed and verified; Staging/Production undeployed; no distribution authorization' \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md || {
  echo "Network policy must record completed C3-03 without implying Production deployment or distribution" >&2
  exit 1
}

for c303_completion in \
  'GitHub Actions run `31856271268`' \
  'merged through PR #36 as `1ebb36c`' \
  'C3-03A is Done' \
  'GitHub Actions run `31873664396`' \
  'PR #38' \
  '`db7926d`' \
  'C3-03 is Done'; do
  if ! grep -Fq "${c303_completion}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md; then
    echo "C3-03A closeout evidence is missing: ${c303_completion}" >&2
    exit 1
  fi
done

# These phrases are deliberate cross-file contract anchors, not incidental prose. If C3-04's
# accepted presentation/release boundary changes, update the owning decision and every anchor in
# the same reviewed change instead of weakening this check.
for c304_contract in \
  'C3-04 and COM-C3 are Done' \
  'PR #40' \
  '`9448ca9`' \
  '`31918968478`' \
  'one non-blocking Dashboard navigation card' \
  'Billing grace retains Pro' \
  'Billing retry, expiry, and revocation' \
  'AX5' \
  'Staging/Production'; do
  if ! grep -Fq "${c304_contract}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/STOREKIT_TEST_MATRIX.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/RELEASE_CHECKLIST.md; then
    echo "C3-04 implementation/release contract is missing: ${c304_contract}" >&2
    exit 1
  fi
done

for c303b_evidence in \
  'bf6c5049-a389-4ea7-af0a-e8425b8957e2' \
  '8 passed, 0 failed, 0 skipped' \
  'Worker tests passed 13/13' \
  'Staging and Production were not deployed' \
  'closed non-content reason codes' \
  'no private key, storage, outbound fetch'; do
  if ! grep -Fq "${c303b_evidence}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C3-03B implementation evidence is missing: ${c303b_evidence}" >&2
    exit 1
  fi
done

if grep -Eq 'C3-03B (is )?In Progress with no transport yet|C3-03B In Progress, transport not yet implemented|future C3-03B contract' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
    Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md; then
  echo "Current commercialization state still describes C3-03B transport as unimplemented" >&2
  exit 1
fi

if grep -Fq 'C3-03 has not started and remains blocked' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C3-03 as not started" >&2
  exit 1
fi

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

for c4a01_contract in \
  'The V1–V4 store does not contain a floating-point money representation that needs conversion.' \
  'complete 15-table `ModelCounts` inventory' \
  'no anomaly becomes zero' \
  '`Merchant.totalMinorUnitsAllTime` currency ownership explicit' \
  'idempotent journal transitions' \
  'undocumented persistent-store metadata' \
  'normal cold start never copies the store' \
  'USD, JPY, and KWD' \
  'C4A-03 remains blocked pending explicit owner instruction' \
  'DEC-COM-025'; do
  if ! grep -Fqi "${c4a01_contract}" \
      Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md; then
    echo "COM-C4A-01 delta/recovery contract is missing: ${c4a01_contract}" >&2
    exit 1
  fi
done

for c4a_release_anchor in '0.9.8 (9)' 'dda1eb09-5d8b-43c6-a2fd-ea910fa422ac'; do
  if ! grep -Fq "${c4a_release_anchor}" \
      Docs/TASKS.md Docs/PROJECT_MEMORY.md Docs/Commercialization/PROJECT_MEMORY.md; then
    echo "Current release calibration is missing: ${c4a_release_anchor}" >&2
    exit 1
  fi
done

for c203_contract in \
  'single `EntitlementStore` lifecycle authority' \
  'one lifecycle task supervises both `Transaction.updates` and `Product.SubscriptionInfo.Status.updates`' \
  'status signal triggers a fresh full reconciliation' \
  'publish-before-`Transaction.finish()`' \
  'failed finish remains unfinished' \
  'post-0.9.6 release hold remains active'; do
  if ! grep -Fq "${c203_contract}" \
      Docs/Commercialization/COM_C2_EXECUTION_PACKET.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/CI_BASELINE.md; then
    echo "C2-03 merged lifecycle/release contract is missing: ${c203_contract}" >&2
    exit 1
  fi
done

for c204_contract in \
  'separately verified `AppTransaction` bundle/environment' \
  'TestFlight is modeled as verified Sandbox' \
  'cross-environment/bundle mismatch rejection' \
  'DEC-COM-018' \
  '49/49 focused' \
  '359 total, 355 passed, 4 skipped, and 0 failed' \
  'C2-04 and COM-C2 are Done'; do
  if ! grep -Fq "${c204_contract}" \
      Docs/Commercialization/COM_C2_EXECUTION_PACKET.md \
      Docs/Commercialization/STOREKIT_TEST_MATRIX.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/DECISIONS.md; then
    echo "C2-04 environment/release contract is missing: ${c204_contract}" >&2
    exit 1
  fi
done

grep -Fq '`a293762`' Docs/Commercialization/CI_BASELINE.md || {
  echo "C2-04 green-CI merge evidence is missing from CI baseline" >&2
  exit 1
}

grep -Fq 'actions/runs/31701374466' Docs/Commercialization/CI_BASELINE.md || {
  echo "C2-04 green-CI run is missing from CI baseline" >&2
  exit 1
}

grep -Fq '`3fc72b4`' Docs/Commercialization/CI_BASELINE.md || {
  echo "C2-03 green-CI merge evidence is missing from CI baseline" >&2
  exit 1
}

grep -Fq 'actions/runs/31675470258' Docs/Commercialization/CI_BASELINE.md || {
  echo "C2-03 green-CI run is missing from CI baseline" >&2
  exit 1
}

for storekit_api in \
  '`Product.SubscriptionInfo.Status.updates`' \
  '`Product.SubscriptionInfo.status(for:)`' \
  '`Transaction.unfinished`' \
  '`Product.purchase()`' \
  '`AppStore.sync()`' \
  '`Transaction.finish()`'; do
  grep -Fq "${storekit_api}" Docs/Commercialization/NETWORK_EGRESS_POLICY.md || {
    echo "C2-03 Apple-managed StoreKit API is missing from the egress policy: ${storekit_api}" >&2
    exit 1
  }
done

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
