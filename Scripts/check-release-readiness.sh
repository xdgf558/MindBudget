#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
PROJECT_FILE="${PROJECT_ROOT}/MindBudget.xcodeproj/project.pbxproj"
INFO_PLIST_CATALOG="${PROJECT_ROOT}/MindBudget/Resources/InfoPlist.xcstrings"
ICON_DIRECTORY="${PROJECT_ROOT}/MindBudget/Resources/Assets.xcassets/AppIcon.appiconset"
ICON_SOURCE_MANIFEST="${PROJECT_ROOT}/Docs/Brand/AppIconSources.sha256"
ICON_FILENAMES=(
  "AppIcon-1024.png"
  "AppIcon-1024-Dark.png"
  "AppIcon-1024-Tinted.png"
)

for icon_filename in "${ICON_FILENAMES[@]}"; do
  icon_file="${ICON_DIRECTORY}/${icon_filename}"
  [[ -f "${icon_file}" ]] || { echo "Missing 1024px app icon: ${icon_filename}" >&2; exit 1; }
  grep -q "\"filename\" : \"${icon_filename}\"" "${ICON_DIRECTORY}/Contents.json" || {
    echo "AppIcon asset catalog does not reference ${icon_filename}" >&2
    exit 1
  }

  icon_metadata="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "${icon_file}")"
  grep -q 'pixelWidth: 1024' <<< "${icon_metadata}"
  grep -q 'pixelHeight: 1024' <<< "${icon_metadata}"
  grep -q 'hasAlpha: no' <<< "${icon_metadata}"
done

grep -q '"value" : "dark"' "${ICON_DIRECTORY}/Contents.json"
grep -q '"value" : "tinted"' "${ICON_DIRECTORY}/Contents.json"

[[ -f "${ICON_SOURCE_MANIFEST}" ]] || {
  echo "Missing App Icon source/artifact checksum manifest" >&2
  exit 1
}
(
  cd "${PROJECT_ROOT}"
  shasum -a 256 -c "Docs/Brand/AppIconSources.sha256"
)

[[ "$(grep -o 'MARKETING_VERSION = 1.0.0' "${PROJECT_FILE}" | wc -l | tr -d ' ')" == "2" ]] || {
  echo "MindBudget app target must use marketing version 1.0.0 in Debug and Release" >&2
  exit 1
}
[[ "$(grep -o 'INFOPLIST_KEY_CFBundleDisplayName = MindBudget' "${PROJECT_FILE}" | wc -l | tr -d ' ')" == "2" ]] || {
  echo "MindBudget app target must use the English fallback display name in Debug and Release" >&2
  exit 1
}
[[ "$(plutil -extract strings.CFBundleDisplayName.localizations.en.stringUnit.value raw -o - "${INFO_PLIST_CATALOG}")" == "MindBudget" ]] || {
  echo "English Home Screen name must be MindBudget" >&2
  exit 1
}
[[ "$(plutil -extract strings.CFBundleDisplayName.localizations.zh-Hans.stringUnit.value raw -o - "${INFO_PLIST_CATALOG}")" == "花有数" ]] || {
  echo "Simplified Chinese Home Screen name must be 花有数" >&2
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
