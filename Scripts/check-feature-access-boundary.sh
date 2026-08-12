#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

ACCESS_SOURCE="MindBudget/Commerce/FeatureAccessService.swift"
ENTITLEMENT_SOURCE="MindBudget/Commerce/EntitlementDomain.swift"
STORE_CATALOG_SOURCE="MindBudget/Commerce/StoreCatalog.swift"
ENTITLEMENT_STORE_SOURCE="MindBudget/Commerce/EntitlementStore.swift"

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

parameterized_feature_access_sites() {
  local source_path="${1:-/dev/stdin}"
  awk '
  FNR == 1 {
    awaiting_argument = 0
    start_line = 0
  }
  {
    source = $0
    sub(/\/\/.*$/, "", source)

    if (awaiting_argument) {
      trimmed = source
      sub(/^[[:space:]]*/, "", trimmed)
      if (trimmed == "") {
        next
      }
      if (trimmed ~ /^\)/) {
        source = substr(trimmed, 2)
      } else {
        print FILENAME ":" start_line ": parameterized FeatureAccessService construction"
        source = ""
      }
      awaiting_argument = 0
      start_line = 0
    }

    while (match(source, /FeatureAccessService[[:space:]]*(\.init[[:space:]]*)?\(/)) {
      found_line = FNR
      source = substr(source, RSTART + RLENGTH)
      sub(/^[[:space:]]*/, "", source)
      if (source ~ /^\)/) {
        source = substr(source, 2)
      } else if (source != "") {
        print FILENAME ":" found_line ": parameterized FeatureAccessService construction"
        source = ""
      } else {
        awaiting_argument = 1
        start_line = found_line
      }
    }
  }
  ' "${source_path}"
}

feature_access_conformance_sites() {
  local source_path="${1:-/dev/stdin}"
  awk '
  FNR == 1 {
    collecting = 0
    declaration = ""
    start_line = 0
  }
  {
    source = $0
    sub(/\/\/.*$/, "", source)
    trimmed = source
    sub(/^[[:space:]]*/, "", trimmed)
    if (trimmed == "") {
      next
    }

    if (!collecting) {
      if (source !~ /(^|[[:space:]])(struct|class|actor|enum|protocol|extension)[[:space:]]+[[:alnum:]_]+/) {
        next
      }
      collecting = 1
      declaration = source
      start_line = FNR
    } else {
      declaration = declaration " " source
    }

    if (declaration ~ /\{/) {
      sub(/\{.*/, "", declaration)
      sub(/[[:space:]]+where[[:space:]].*/, "", declaration)
      if (declaration ~ /:[^{}]*FeatureAccessChecking([^[:alnum:]_]|$)/) {
        print FILENAME ":" start_line ": FeatureAccessChecking conformance"
      }
      collecting = 0
      declaration = ""
      start_line = 0
    }
  }
  ' "${source_path}"
}

assert_gate_fixture() {
  local parser="$1"
  local expects_violation="$2"
  local description="$3"
  local fixture="$4"
  local result
  result="$(printf '%s\n' "${fixture}" | "${parser}")"
  if [[ "${expects_violation}" == "yes" && -z "${result}" ]] ||
     [[ "${expects_violation}" == "no" && -n "${result}" ]]; then
    echo "Feature-access authority gate self-test failed: ${description}" >&2
    exit 1
  fi
}

# Prove the authority chokepoints distinguish safe consumers from new paid-authority paths.
assert_gate_fixture \
  parameterized_feature_access_sites \
  "no" \
  "the exact-Free no-argument service must remain available to app consumers" \
  $'let access = FeatureAccessService()'
assert_gate_fixture \
  parameterized_feature_access_sites \
  "yes" \
  "a multiline entitlement-bearing service construction must be rejected" \
  $'let access = FeatureAccessService(\n    entitlements: EntitlementSet.reachablePaidEntitlements[0]\n)'
assert_gate_fixture \
  parameterized_feature_access_sites \
  "yes" \
  "a later parameterized constructor on the same line must not hide behind a Free constructor" \
  $'let free = FeatureAccessService(); let paid = FeatureAccessService.init(entitlements: paidSet)'
assert_gate_fixture \
  feature_access_conformance_sites \
  "no" \
  "a protocol-typed consumer is not a new authority implementation" \
  $'struct FeatureConsumer {\n    let access: any FeatureAccessChecking\n}'
assert_gate_fixture \
  feature_access_conformance_sites \
  "yes" \
  "a multiline FeatureAccessChecking implementation must be rejected" \
  $'struct BypassProvider:\n    FeatureAccessChecking,\n    Sendable {\n}'
assert_gate_fixture \
  feature_access_conformance_sites \
  "yes" \
  "a protocol refinement must not create an indirect authority seam" \
  $'protocol BypassAccess:\n    FeatureAccessChecking {\n}'

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
    ! -path "${STORE_CATALOG_SOURCE}" \
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

parameterized_access_constructors="$({
  while IFS= read -r source_path; do
    parameterized_feature_access_sites "${source_path}"
  done < <(find MindBudget -type f -name '*.swift' ! -path 'MindBudget/Commerce/*')
} || true)"
if [[ -n "${parameterized_access_constructors}" ]]; then
  echo "Only Commerce may construct FeatureAccessService with an entitlement snapshot:" >&2
  echo "${parameterized_access_constructors}" >&2
  exit 1
fi

feature_access_conformances="$({
  while IFS= read -r source_path; do
    feature_access_conformance_sites "${source_path}"
  done < <(find MindBudget -type f -name '*.swift' ! -path 'MindBudget/Commerce/*')
} || true)"
if [[ -n "${feature_access_conformances}" ]]; then
  echo "FeatureAccessChecking implementations must remain inside Commerce:" >&2
  echo "${feature_access_conformances}" >&2
  exit 1
fi

direct_feature_decisions="$({
  find MindBudget -type f -name '*.swift' \
    ! -path "${ACCESS_SOURCE}" \
    -exec grep -nEH '\.decision\(for:[[:space:]]*\.' {} + |
    grep -Ev '^[^:]+:[0-9]+:[[:space:]]*//'
} 2>/dev/null || true)"
if [[ -n "${direct_feature_decisions}" ]]; then
  echo "Existing feature entries must consume the Commerce-owned access snapshot:" >&2
  echo "${direct_feature_decisions}" >&2
  exit 1
fi

feature_local_paid_state="$({
  find MindBudget -type f -name '*.swift' \
    ! -path 'MindBudget/Commerce/*' \
    -exec grep -nEH '(^|[^[:alnum:]_])(isPro|hasPro|isPremium|hasPremium|manual[A-Za-z0-9_]*Unlock|unlock[A-Za-z0-9_]*(Pro|Premium)|productID|productIdentifier)([^[:alnum:]_]|$)' {} + |
    grep -Ev '^[^:]+:[0-9]+:[[:space:]]*//'
} 2>/dev/null || true)"
if [[ -n "${feature_local_paid_state}" ]]; then
  echo "Feature code must not add local paid-state, product-ID, or manual-unlock checks:" >&2
  echo "${feature_local_paid_state}" >&2
  exit 1
fi

commercial_product_literals="$({
  find MindBudget -type f -name '*.swift' \
    ! -path "${STORE_CATALOG_SOURCE}" \
    -exec grep -nEH 'com\.xdgf558\.mindbudget\.pro\.(monthly|annual|lifetime)' {} + |
    grep -Ev '^[^:]+:[0-9]+:[[:space:]]*//'
} 2>/dev/null || true)"
if [[ -n "${commercial_product_literals}" ]]; then
  echo "StoreKit product identifiers must remain centralized in StoreCatalog:" >&2
  echo "${commercial_product_literals}" >&2
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

storekit_imports="$({
  find MindBudget -type f -name '*.swift' \
    ! -path "${STORE_CATALOG_SOURCE}" \
    ! -path "${ENTITLEMENT_STORE_SOURCE}" \
    -exec grep -nEH '^[[:space:]]*(import|@preconcurrency[[:space:]]+import)[[:space:]]+StoreKit' {} +
} 2>/dev/null || true)"
if [[ -n "${storekit_imports}" ]]; then
  echo "StoreKit imports must remain inside the Commerce runtime adapters:" >&2
  echo "${storekit_imports}" >&2
  exit 1
fi

echo "Central feature-access and DEBUG/Release boundaries passed"
