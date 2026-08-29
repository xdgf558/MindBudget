#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
DESTINATION="${MINDBUDGET_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}"
MATRIX_TEMP_DIRECTORY=""

cleanup() {
  if [[ -n "${MATRIX_TEMP_DIRECTORY}" ]]; then
    rm -rf -- "${MATRIX_TEMP_DIRECTORY}"
  fi
}
trap cleanup EXIT

if [[ -n "${MINDBUDGET_C6_RESULT_BUNDLE_PATH:-}" ]]; then
  RESULT_BUNDLE="${MINDBUDGET_C6_RESULT_BUNDLE_PATH}"
  if [[ -e "${RESULT_BUNDLE}" ]]; then
    echo "MINDBUDGET_C6_RESULT_BUNDLE_PATH must not already exist: ${RESULT_BUNDLE}" >&2
    exit 1
  fi
  mkdir -p -- "$(dirname -- "${RESULT_BUNDLE}")"
else
  MATRIX_TEMP_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/mindbudget-c6-matrix.XXXXXX")"
  RESULT_BUNDLE="${MATRIX_TEMP_DIRECTORY}/C6ReleaseMatrix.xcresult"
fi

cd "${PROJECT_ROOT}"
Scripts/check-c6-release-matrix.sh

while IFS= read -r static_check; do
  [[ -n "${static_check}" ]] || continue
  if [[ "${static_check}" == *.py ]]; then
    python3 -B "${static_check}" --self-test
    python3 -B "${static_check}"
  else
    "${static_check}"
  fi
done < <(python3 -B Scripts/c6_release_matrix.py --list-static-checks)

while IFS='|' read -r worker_directory worker_script; do
  [[ -n "${worker_directory}" && -n "${worker_script}" ]] || continue
  npm --prefix "${worker_directory}" run "${worker_script}"
done < <(python3 -B Scripts/c6_release_matrix.py --list-worker-checks)

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
  -destination "${DESTINATION}" build-for-testing

test_arguments=(
  -destination "${DESTINATION}"
  -parallel-testing-enabled NO
  -resultBundlePath "${RESULT_BUNDLE}"
)
while IFS= read -r test_filter; do
  [[ -n "${test_filter}" ]] || continue
  test_arguments+=("-only-testing:${test_filter}")
done < <(python3 -B Scripts/c6_release_matrix.py --list-test-filters)

xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  "${test_arguments[@]}" test-without-building

echo "C6-01 automated release matrix passed."
echo "Result bundle: ${RESULT_BUNDLE}"
