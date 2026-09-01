#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
EXPECTED_BUNDLE_ID="com.xdgf558.MindBudget"
EXPECTED_TEAM_ID="2AM5S7BM2N"
EXPECTED_VERSION="0.9.8"
EXPECTED_BUILD="10"
EXPECTED_ICLOUD_CONTAINER="iCloud.com.xdgf558.MindBudget"

usage() {
  echo "Usage: $0 --mode signed-device|distribution /absolute/path/to/MindBudget.app" >&2
  exit 64
}

[[ "${1:-}" == "--mode" ]] || usage
MODE="${2:-}"
APP_PATH="${3:-}"
[[ "${MODE}" == "signed-device" || "${MODE}" == "distribution" ]] || usage
[[ -n "${APP_PATH}" && "${APP_PATH}" == /* && -d "${APP_PATH}" ]] || usage

for command_name in codesign find grep mktemp plutil rm sort strings; do
  command -v "${command_name}" >/dev/null 2>&1 || {
    echo "C6-02 app inspection requires ${command_name}" >&2
    exit 1
  }
done
command -v python3 >/dev/null 2>&1 || {
  echo "C6-02 app inspection requires python3" >&2
  exit 1
}

INFO_PLIST="${APP_PATH}/Info.plist"
PRIVACY_MANIFEST="${APP_PATH}/PrivacyInfo.xcprivacy"
[[ -s "${INFO_PLIST}" ]] || { echo "Signed app is missing Info.plist" >&2; exit 1; }
[[ -s "${PRIVACY_MANIFEST}" ]] || { echo "Signed app is missing PrivacyInfo.xcprivacy" >&2; exit 1; }

EXECUTABLE_NAME="$(plutil -extract CFBundleExecutable raw -o - "${INFO_PLIST}")"
EXECUTABLE="${APP_PATH}/${EXECUTABLE_NAME}"
[[ -x "${EXECUTABLE}" ]] || { echo "Signed app executable is missing" >&2; exit 1; }

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

TEMP_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/mindbudget-c6-app.XXXXXX")"
trap 'rm -rf -- "${TEMP_DIRECTORY}"' EXIT
ENTITLEMENTS="${TEMP_DIRECTORY}/entitlements.plist"
codesign --display --entitlements :- "${APP_PATH}" >"${ENTITLEMENTS}" 2>/dev/null
[[ -s "${ENTITLEMENTS}" ]] || { echo "Unable to extract signed entitlements" >&2; exit 1; }

require_raw_value() {
  local plist="$1" key="$2" expected="$3" actual
  actual="$(plutil -extract "${key}" raw -o - "${plist}")"
  [[ "${actual}" == "${expected}" ]] || {
    echo "Unexpected ${key}: expected ${expected}, found ${actual}" >&2
    exit 1
  }
}

require_json_value() {
  local plist="$1" key="$2" expected="$3" actual
  actual="$(python3 -c '
import json
import plistlib
import sys

with open(sys.argv[1], "rb") as handle:
    value = plistlib.load(handle)[sys.argv[2]]
print(json.dumps(value, separators=(",", ":")))
' "${plist}" "${key}")"
  [[ "${actual}" == "${expected}" ]] || {
    echo "Unexpected ${key}: expected ${expected}, found ${actual}" >&2
    exit 1
  }
}

require_raw_value "${INFO_PLIST}" CFBundleIdentifier "${EXPECTED_BUNDLE_ID}"
require_raw_value "${INFO_PLIST}" CFBundleShortVersionString "${EXPECTED_VERSION}"
require_raw_value "${INFO_PLIST}" CFBundleVersion "${EXPECTED_BUILD}"
require_raw_value "${INFO_PLIST}" MinimumOSVersion "17.0"
[[ "$(plutil -extract UIDeviceFamily json -o - "${INFO_PLIST}")" == '[1]' ]] || {
  echo "Release app must remain iPhone-only" >&2
  exit 1
}
[[ "$(plutil -extract UIBackgroundModes json -o - "${INFO_PLIST}")" == '["remote-notification"]' ]] || {
  echo "Release app must contain only the reviewed remote-notification background mode" >&2
  exit 1
}

require_json_value "${ENTITLEMENTS}" com.apple.developer.team-identifier "\"${EXPECTED_TEAM_ID}\""
require_json_value "${ENTITLEMENTS}" application-identifier "\"${EXPECTED_TEAM_ID}.${EXPECTED_BUNDLE_ID}\""
require_json_value "${ENTITLEMENTS}" com.apple.developer.icloud-container-environment '"Production"'
require_json_value "${ENTITLEMENTS}" com.apple.developer.icloud-container-identifiers "[\"${EXPECTED_ICLOUD_CONTAINER}\"]"
require_json_value "${ENTITLEMENTS}" com.apple.developer.icloud-services '["CloudKit"]'

GET_TASK_ALLOW="$(python3 -c '
import plistlib
import sys

with open(sys.argv[1], "rb") as handle:
    value = plistlib.load(handle).get("get-task-allow")
print("true" if value is True else "false" if value is False else "missing")
' "${ENTITLEMENTS}")"
if [[ "${MODE}" == "signed-device" ]]; then
  # A Release-configuration app installed directly from Xcode is still signed by a
  # development provisioning profile. Provisioning therefore replaces the source
  # aps-environment with development and enables debugging. This mode is useful for
  # physical-device preflight, but it is deliberately not distribution evidence.
  require_json_value "${ENTITLEMENTS}" aps-environment '"development"'
  [[ "${GET_TASK_ALLOW}" == "true" ]] || {
    echo "Signed-device inspection requires get-task-allow=true" >&2
    exit 1
  }
else
  require_json_value "${ENTITLEMENTS}" aps-environment '"production"'
  [[ "${GET_TASK_ALLOW}" == "false" ]] || {
    echo "Distribution inspection requires get-task-allow=false" >&2
    exit 1
  }
fi

if find "${APP_PATH}" -type f \( -name '*.storekit' -o -name '*.xctest' \) -print -quit | grep -q .; then
  echo "Release app contains a StoreKit fixture or test bundle" >&2
  exit 1
fi

python3 -B "${PROJECT_ROOT}/Scripts/privacy_manifest_contract.py" \
  --manifest "${PRIVACY_MANIFEST}"

EXPECTED_HOSTS='mindbudget-public-config-dev.yehao1105.workers.dev
mindbudget-public-config-staging.yehao1105.workers.dev
mindbudget-public-config.yehao1105.workers.dev
mindbudget-telemetry-dev.yehao1105.workers.dev
mindbudget-telemetry-staging.yehao1105.workers.dev
mindbudget-telemetry.yehao1105.workers.dev'
OBSERVED_HOSTS="$(strings -a "${EXECUTABLE}" \
  | grep -Eo '[A-Za-z0-9.-]+\.workers\.dev' \
  | sort -u)"
[[ "${OBSERVED_HOSTS}" == "${EXPECTED_HOSTS}" ]] || {
  echo "Release executable app-owned host literals drifted from the six reviewed endpoints" >&2
  printf 'Observed:\n%s\n' "${OBSERVED_HOSTS}" >&2
  exit 1
}

echo "C6-03 ${MODE} app inspection passed: ${EXPECTED_BUNDLE_ID} ${EXPECTED_VERSION} (${EXPECTED_BUILD})"
