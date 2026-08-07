#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
PROJECT_FILE="${PROJECT_ROOT}/MindBudget.xcodeproj/project.pbxproj"
ICON_DIRECTORY="${PROJECT_ROOT}/MindBudget/Resources/Assets.xcassets/AppIcon.appiconset"
ICON_FILE="${ICON_DIRECTORY}/AppIcon-1024.png"

[[ -f "${ICON_FILE}" ]] || { echo "Missing 1024px app icon" >&2; exit 1; }
grep -q '"filename" : "AppIcon-1024.png"' "${ICON_DIRECTORY}/Contents.json" || {
  echo "AppIcon asset catalog does not reference AppIcon-1024.png" >&2
  exit 1
}

icon_metadata="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "${ICON_FILE}")"
grep -q 'pixelWidth: 1024' <<< "${icon_metadata}"
grep -q 'pixelHeight: 1024' <<< "${icon_metadata}"
grep -q 'hasAlpha: no' <<< "${icon_metadata}"

[[ "$(grep -o 'MARKETING_VERSION = 1.0.0' "${PROJECT_FILE}" | wc -l | tr -d ' ')" == "2" ]] || {
  echo "MindBudget app target must use marketing version 1.0.0 in Debug and Release" >&2
  exit 1
}
if grep -q 'DEVELOPMENT_TEAM' "${PROJECT_FILE}"; then
  echo "Do not hardcode an Apple Developer team in the shared project" >&2
  exit 1
fi

[[ -f "${PROJECT_ROOT}/MindBudget/Resources/PrivacyInfo.xcprivacy" ]] || {
  echo "Missing privacy manifest" >&2
  exit 1
}

if find "${PROJECT_ROOT}/MindBudget" -type f -name '*.swift' -exec grep -nEH '\b(TODO|FIXME)\b' {} +; then
  echo "Unresolved TODO/FIXME found in shipping Swift sources" >&2
  exit 1
fi

echo "Static release-readiness checks passed."
