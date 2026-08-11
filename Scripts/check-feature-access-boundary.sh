#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

ACCESS_SOURCE="MindBudget/Commerce/FeatureAccessService.swift"
ENTITLEMENT_SOURCE="MindBudget/Commerce/EntitlementDomain.swift"

if [[ ! -s "${ACCESS_SOURCE}" || ! -s "${ENTITLEMENT_SOURCE}" ]]; then
  echo "Feature-access and entitlement sources must both exist" >&2
  exit 1
fi

debug_provider_status() {
  local source_path="${1:-/dev/stdin}"
  awk '
  /^[[:space:]]*#if[[:space:]]+DEBUG([[:space:]]*(\/\/.*)?)?$/ {
    depth += 1
    debug_guard[depth] = 1
    debug_branch[depth] = 1
    next
  }
  /^[[:space:]]*#if([[:space:]]|$)/ {
    depth += 1
    next
  }
  /^[[:space:]]*#(else|elseif)([[:space:]]|$)/ {
    if (debug_guard[depth]) {
      debug_branch[depth] = 0
    }
    next
  }
  /^[[:space:]]*#endif([[:space:]]|$)/ {
    delete debug_guard[depth]
    delete debug_branch[depth]
    depth -= 1
    next
  }
  /struct[[:space:]]+DebugFeatureAccessProvider/ {
    found += 1
    protected = 0
    for (level = 1; level <= depth; level += 1) {
      if (debug_guard[level] && debug_branch[level]) {
        protected = 1
      }
    }
    if (!protected) {
      unguarded += 1
    }
  }
  END {
    printf "%d:%d\n", found, unguarded
  }
  ' "${source_path}"
}

assert_debug_provider_fixture() {
  local expected="$1"
  local description="$2"
  local fixture="$3"
  local actual
  actual="$(printf '%s\n' "${fixture}" | debug_provider_status)"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "Feature-access DEBUG parser self-test failed: ${description}" >&2
    exit 1
  fi
}

# Prove the parser rejects unguarded and inactive-branch providers before trusting it on source.
assert_debug_provider_fixture \
  "1:0" \
  "active DEBUG branch should be accepted" \
  $'#if DEBUG // fixture comment\nstruct DebugFeatureAccessProvider {}\n#endif'
assert_debug_provider_fixture \
  "1:1" \
  "unguarded provider should be rejected" \
  $'struct DebugFeatureAccessProvider {}'
assert_debug_provider_fixture \
  "1:1" \
  "provider in the DEBUG else branch should be rejected" \
  $'#if DEBUG\n#else\nstruct DebugFeatureAccessProvider {}\n#endif'

# Prove the arbitrary-combination provider's declaration is inside an active #if DEBUG region.
# The app's existing Release build then proves that the guarded source compiles without it.
debug_provider_status="$(debug_provider_status "${ACCESS_SOURCE}" || true)"

if [[ "${debug_provider_status}" != "1:0" ]]; then
  echo "DebugFeatureAccessProvider must have exactly one DEBUG-guarded declaration" >&2
  exit 1
fi

raw_bit_reads="$({
  find MindBudget -type f -name '*.swift' \
    ! -path "${ENTITLEMENT_SOURCE}" \
    -exec grep -nEH 'version1(Bits|KnownBits)' {} + |
    grep -Ev '^[^:]+:[0-9]+:[[:space:]]*//'
} 2>/dev/null || true)"
if [[ -n "${raw_bit_reads}" ]]; then
  echo "Feature/application code must not read raw entitlement bits:" >&2
  echo "${raw_bit_reads}" >&2
  exit 1
fi

free_superset_checks="$({
  find MindBudget -type f -name '*.swift' \
    -exec grep -nEH 'isSuperset\(of:[[:space:]]*\.free\)' {} + |
    grep -Ev '^[^:]+:[0-9]+:[[:space:]]*//'
} 2>/dev/null || true)"
if [[ -n "${free_superset_checks}" ]]; then
  echo "Free checks must use isFree, never isSuperset(of: .free):" >&2
  echo "${free_superset_checks}" >&2
  exit 1
fi

duplicate_subscription_checks="$({
  find MindBudget -type f -name '*.swift' \
    ! -path "${ACCESS_SOURCE}" \
    ! -path "${ENTITLEMENT_SOURCE}" \
    -exec grep -nEH '\.proSubscription([^[:alnum:]_]|$)' {} + |
    grep -Ev '^[^:]+:[0-9]+:[[:space:]]*//'
} 2>/dev/null || true)"
if [[ -n "${duplicate_subscription_checks}" ]]; then
  echo "Paid feature checks must remain centralized in FeatureAccessService:" >&2
  echo "${duplicate_subscription_checks}" >&2
  exit 1
fi

migrator_call_sites="$({
  find MindBudget -type f -name '*.swift' \
    ! -path "${ENTITLEMENT_SOURCE}" \
    -exec grep -nEH '(^|[^[:alnum:]_])EntitlementSetMigrator([^[:alnum:]_]|$)' {} + |
    grep -Ev '^[^:]+:[0-9]+:[[:space:]]*//'
} 2>/dev/null || true)"
if [[ -n "${migrator_call_sites}" ]]; then
  echo "Entitlement migration may not become a second paid-authority path:" >&2
  echo "${migrator_call_sites}" >&2
  exit 1
fi

authority_storage_reads="$({
  awk '
  {
    candidate = $0
    sub(/^[[:space:]]*/, "", candidate)
    if (candidate ~ /^\/\//) {
      next
    }
    if ($0 ~ /UserDefaults|@AppStorage|FileManager|@Model|ModelContext|ProcessInfo\.processInfo\.arguments/) {
      print FNR ":" $0
    }
  }
  ' "${ACCESS_SOURCE}"
} || true)"
if [[ -n "${authority_storage_reads}" ]]; then
  echo "Feature-access authority must not use persisted or process-argument state:" >&2
  echo "${ACCESS_SOURCE}:${authority_storage_reads}" >&2
  exit 1
fi

if grep -R -nE '^[[:space:]]*(import|@preconcurrency[[:space:]]+import)[[:space:]]+StoreKit' \
  MindBudget --include='*.swift'; then
  echo "COM-C1 must not import StoreKit" >&2
  exit 1
fi

echo "Central feature-access and DEBUG/Release boundaries passed"
