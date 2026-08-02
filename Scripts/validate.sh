#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
DESTINATION="${MINDBUDGET_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}"
TEST_ARGUMENTS=()

if [[ "${MINDBUDGET_RETRY_TESTS_ON_FAILURE:-0}" == "1" ]]; then
  TEST_ARGUMENTS=(-retry-tests-on-failure -test-iterations 2)
fi

cd "${PROJECT_ROOT}"

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
  -destination "${DESTINATION}" build-for-testing

xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -destination "${DESTINATION}" "${TEST_ARGUMENTS[@]}" test-without-building
