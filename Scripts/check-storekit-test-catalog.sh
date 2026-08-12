#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

CATALOG="Config/StoreKit/MindBudgetPro.storekit"
DEFAULT_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget.xcscheme"
LOCAL_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget-StoreKit-Local.xcscheme"
PROJECT_FILE="MindBudget.xcodeproj/project.pbxproj"
CONTRACT="${SCRIPT_DIRECTORY}/storekit_catalog_contract.py"
CONTRACT_TESTS="${SCRIPT_DIRECTORY}/tests/test_storekit_catalog_contract.py"

for file in \
  "${CATALOG}" \
  "${DEFAULT_SCHEME}" \
  "${LOCAL_SCHEME}" \
  "${PROJECT_FILE}" \
  "${CONTRACT}" \
  "${CONTRACT_TESTS}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing StoreKit catalog control: ${file}" >&2
    exit 1
  fi
done

python3 -B "${CONTRACT_TESTS}"
python3 -B "${CONTRACT}" \
  "${CATALOG}" \
  "${DEFAULT_SCHEME}" \
  "${LOCAL_SCHEME}" \
  "${PROJECT_FILE}"

echo "StoreKit local catalog and environment isolation passed"
