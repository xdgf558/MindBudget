#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
DESTINATION="${MINDBUDGET_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}"

cd "${PROJECT_ROOT}"

xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -destination "${DESTINATION}" build

xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -destination "${DESTINATION}" test
