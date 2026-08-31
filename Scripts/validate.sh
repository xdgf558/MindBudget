#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
DESTINATION="${MINDBUDGET_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}"
VALIDATION_TEMP_DIRECTORY=""

cleanup() {
  if [[ -n "${VALIDATION_TEMP_DIRECTORY}" ]]; then
    rm -rf -- "${VALIDATION_TEMP_DIRECTORY}"
  fi
}
trap cleanup EXIT

if [[ -n "${MINDBUDGET_RESULT_BUNDLE_PATH:-}" ]]; then
  RESULT_BUNDLE="${MINDBUDGET_RESULT_BUNDLE_PATH}"
  if [[ -e "${RESULT_BUNDLE}" ]]; then
    echo "MINDBUDGET_RESULT_BUNDLE_PATH must not already exist: ${RESULT_BUNDLE}" >&2
    exit 1
  fi
  mkdir -p -- "$(dirname -- "${RESULT_BUNDLE}")"
else
  VALIDATION_TEMP_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/mindbudget-validation.XXXXXX")"
  RESULT_BUNDLE="${VALIDATION_TEMP_DIRECTORY}/MindBudget.xcresult"
fi
cd "${PROJECT_ROOT}"

Scripts/check-release-readiness.sh
Scripts/check-network-egress.sh
Scripts/check-commercialization-docs.sh
Scripts/check-public-configuration-contract.sh
Scripts/check-telemetry-contract.sh
Scripts/check-telemetry-worker-contract.sh
Scripts/check-telemetry-metrics-contract.sh
Scripts/check-feature-access-boundary.sh
Scripts/check-storekit-test-catalog.sh
Scripts/check-c6-release-matrix.sh
Scripts/check_c6_02_acceptance.py --self-test

build_settings="$(
  xcodebuild -project MindBudget.xcodeproj -target MindBudget \
    -configuration Debug -showBuildSettings
)"
bundle_identifier="$(
  awk -F ' = ' '/^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER = / { print $2; exit }' \
    <<< "${build_settings}"
)"

if [[ ! "${bundle_identifier}" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
  echo "Invalid PRODUCT_BUNDLE_IDENTIFIER: ${bundle_identifier:-<empty>}" >&2
  echo "Set a non-empty MINDBUDGET_BUNDLE_ID_PREFIX in Config/Local.xcconfig." >&2
  exit 1
fi

xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -configuration Release -destination "generic/platform=iOS Simulator" build

xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -destination "${DESTINATION}" -enableCodeCoverage YES build-for-testing

test_arguments=(
  -destination "${DESTINATION}"
  -enableCodeCoverage YES
  -resultBundlePath "${RESULT_BUNDLE}"
)

wall_clock_benchmark="MindBudgetTests/Phase10ReleaseReadinessTests/localDashboardFirstLoadBenchmarkWithTenThousandDiverseExpensesStaysBelowFiveHundredMilliseconds()"

# A wall-clock benchmark is meaningful only without unrelated test-suite CPU contention.
# Run it once, serially, on the local release machine; the full correctness/coverage run
# below skips only the duplicate concurrent invocation. Hosted runners retain their
# existing behavior: they execute the deterministic 10,000-row projection contract but
# skip the strict 500 ms signal because neighboring load is nondeterministic.
if [[ "${MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK:-0}" != "1" ]]; then
  xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
    -destination "${DESTINATION}" -parallel-testing-enabled NO \
    "-only-testing:${wall_clock_benchmark}" test-without-building
fi
test_arguments+=( "-skip-testing:${wall_clock_benchmark}" )

if [[ "${MINDBUDGET_RETRY_TESTS_ON_FAILURE:-0}" == "1" ]]; then
  test_arguments+=( -retry-tests-on-failure -test-iterations 2 )
fi

xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  "${test_arguments[@]}" test-without-building

Scripts/check-coverage.sh "${RESULT_BUNDLE}"
Scripts/check_c6_02_acceptance.py --verify-result-bundle "${RESULT_BUNDLE}"
