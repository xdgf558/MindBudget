#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
PROJECT_FILE="${PROJECT_ROOT}/MindBudget.xcodeproj/project.pbxproj"
INFO_PLIST_CATALOG="${PROJECT_ROOT}/MindBudget/Resources/InfoPlist.xcstrings"
ICON_DIRECTORY="${PROJECT_ROOT}/MindBudget/Resources/Assets.xcassets/AppIcon.appiconset"
ICON_SOURCE_MANIFEST="${PROJECT_ROOT}/Docs/Brand/AppIconSources.sha256"
CHANGELOG_FILE="${PROJECT_ROOT}/Docs/CHANGELOG.md"
SUBMISSION_NOTES_FILE="${PROJECT_ROOT}/Docs/APP_STORE_SUBMISSION.md"
RELEASE_NOTES_SOURCE="${PROJECT_ROOT}/MindBudget/Features/Settings/SettingsView.swift"
EXPECTED_MARKETING_VERSION="0.9.8"
EXPECTED_BUILD_NUMBER="9"
ICON_FILENAMES=(
  "AppIcon-1024.png"
  "AppIcon-1024-Dark.png"
  "AppIcon-1024-Tinted.png"
)
THEME_BACKGROUND_ENTRIES=(
  "AuroraGlowBackground.imageset/aurora-glow-background.png"
  "WarmBotanicalBackground.imageset/warm-botanical-background.png"
  "NeonPulseBackground.imageset/neon-pulse-background.png"
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

for background_entry in "${THEME_BACKGROUND_ENTRIES[@]}"; do
  background_file="${PROJECT_ROOT}/MindBudget/Resources/Assets.xcassets/${background_entry}"
  background_directory="$(dirname -- "${background_file}")"
  background_filename="$(basename -- "${background_file}")"
  [[ -f "${background_file}" ]] || {
    echo "Missing skin background: ${background_entry}" >&2
    exit 1
  }
  grep -q "\"filename\" : \"${background_filename}\"" "${background_directory}/Contents.json" || {
    echo "Skin asset catalog does not reference ${background_filename}" >&2
    exit 1
  }

  background_metadata="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "${background_file}")"
  background_width="$(awk '/pixelWidth:/ { print $2 }' <<< "${background_metadata}")"
  background_height="$(awk '/pixelHeight:/ { print $2 }' <<< "${background_metadata}")"
  [[ "${background_width}" -ge 800 ]] || {
    echo "Skin background is too narrow: ${background_filename}" >&2
    exit 1
  }
  [[ "${background_height}" -ge 1700 ]] || {
    echo "Skin background is too short: ${background_filename}" >&2
    exit 1
  }
  grep -q 'hasAlpha: no' <<< "${background_metadata}"
done

[[ -f "${ICON_SOURCE_MANIFEST}" ]] || {
  echo "Missing App Icon source/artifact checksum manifest" >&2
  exit 1
}
(
  cd "${PROJECT_ROOT}"
  shasum -a 256 -c "Docs/Brand/AppIconSources.sha256"
)

[[ "$(grep -o "MARKETING_VERSION = ${EXPECTED_MARKETING_VERSION}" "${PROJECT_FILE}" | wc -l | tr -d ' ')" == "2" ]] || {
  echo "MindBudget app target must use marketing version ${EXPECTED_MARKETING_VERSION} in Debug and Release" >&2
  exit 1
}
[[ "$(grep -o "CURRENT_PROJECT_VERSION = ${EXPECTED_BUILD_NUMBER}" "${PROJECT_FILE}" | wc -l | tr -d ' ')" == "2" ]] || {
  echo "MindBudget app target must use build number ${EXPECTED_BUILD_NUMBER} in Debug and Release" >&2
  exit 1
}
grep -Fq "## ${EXPECTED_MARKETING_VERSION} (${EXPECTED_BUILD_NUMBER})" "${CHANGELOG_FILE}" || {
  echo "CHANGELOG must include ${EXPECTED_MARKETING_VERSION} (${EXPECTED_BUILD_NUMBER}) release notes" >&2
  exit 1
}
grep -Fq "### ${EXPECTED_MARKETING_VERSION} (${EXPECTED_BUILD_NUMBER})" "${SUBMISSION_NOTES_FILE}" || {
  echo "TestFlight notes must include ${EXPECTED_MARKETING_VERSION} (${EXPECTED_BUILD_NUMBER})" >&2
  exit 1
}
LATEST_IN_APP_RELEASE_VERSION="$(awk '
  /static let versions: \[ReleaseNotesVersion\] = \[/ { in_catalog = 1; next }
  in_catalog && /version: "/ {
    value = $0
    sub(/^.*version: "/, "", value)
    sub(/".*$/, "", value)
    print value
    exit
  }
' "${RELEASE_NOTES_SOURCE}")"
[[ "${LATEST_IN_APP_RELEASE_VERSION}" == "${EXPECTED_MARKETING_VERSION}" ]] || {
  echo "The newest in-app release-note entry must match ${EXPECTED_MARKETING_VERSION}" >&2
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
[[ "$(grep -o 'INFOPLIST_KEY_NSFaceIDUsageDescription = "Use Face ID to protect your local budget records."' "${PROJECT_FILE}" | wc -l | tr -d ' ')" == "2" ]] || {
  echo "MindBudget app target must include the Face ID purpose string in Debug and Release" >&2
  exit 1
}
for locale in en zh-Hans; do
  face_id_purpose="$(
    plutil -extract "strings.NSFaceIDUsageDescription.localizations.${locale}.stringUnit.value" \
      raw -o - "${INFO_PLIST_CATALOG}"
  )"
  [[ -n "${face_id_purpose}" ]] || {
    echo "Missing localized Face ID purpose for ${locale}" >&2
    exit 1
  }
done
[[ "$(grep -o 'INFOPLIST_KEY_NSCameraUsageDescription = "Use the camera to capture a receipt for local processing."' "${PROJECT_FILE}" | wc -l | tr -d ' ')" == "2" ]] || {
  echo "MindBudget app target must include the camera purpose string in Debug and Release" >&2
  exit 1
}
for locale in en zh-Hans; do
  camera_purpose="$(
    plutil -extract "strings.NSCameraUsageDescription.localizations.${locale}.stringUnit.value" \
      raw -o - "${INFO_PLIST_CATALOG}"
  )"
  [[ -n "${camera_purpose}" ]] || {
    echo "Missing localized camera purpose for ${locale}" >&2
    exit 1
  }
done
if grep -Fq 'NSPhotoLibraryUsageDescription' "${PROJECT_FILE}" "${INFO_PLIST_CATALOG}"; then
  echo "PHPicker must not add broad Photo Library permission" >&2
  exit 1
fi
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
