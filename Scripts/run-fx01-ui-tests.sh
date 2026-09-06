#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" != 2 || "$1" != platform=iOS\ Simulator,* || "$2" != *.xcresult ]]; then
  echo "Usage: run-fx01-ui-tests.sh 'platform=iOS Simulator,...' /fresh/result.xcresult" >&2
  exit 1
fi
FX_DESTINATION="$1"
FX_RESULT_BUNDLE="$2"
FX_DERIVED_DATA="${FX_RESULT_BUNDLE%.xcresult}.DerivedData"
if [[ -e "${FX_RESULT_BUNDLE}" || -e "${FX_DERIVED_DATA}" ]]; then
  echo "FX UI result and isolated DerivedData paths must not already exist" >&2
  exit 1
fi
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIRECTORY}/.."

Scripts/fx01_ui_contract.py --self-test
exec python3 -B Scripts/fx01_ui_runner.py "${FX_DESTINATION}" "${FX_RESULT_BUNDLE}"
