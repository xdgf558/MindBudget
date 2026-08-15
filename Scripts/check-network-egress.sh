#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

# COM-C3-03B accepts exactly one app-owned Release HTTP(S) adapter. Scan app source and Release
# configuration rather than trusting documentation alone. System-owned transports such as
# StoreKit and CloudKit are not matched here. The exact source exception below is intentionally
# file-scoped and its host/method/privacy contract is checked independently before any broad scan
# exclusion is applied.
APPROVED_PUBLIC_CONFIGURATION_SOURCE="MindBudget/Commerce/PublicConfigurationTransport.swift"
swift_network_pattern='(^|[^[:alnum:]_])(URLSession|URLRequest|NSURLConnection|NWConnection|NWListener|NWBrowser|CFHTTPMessage|CFHost|CFSocket|WKWebView)([^[:alnum:]_]|$)|^[[:space:]]*import[[:space:]]+(Network|CFNetwork|WebKit)([[:space:]]|$)|"[^"]*https?://'
configuration_network_pattern='NSAppTransportSecurity|NSAllowsArbitraryLoads|NSExceptionDomains|NSAllowsLocalNetworking|com\.apple\.developer\.networking\.|com\.apple\.developer\.associated-domains|<string>[[:space:]]*https?://|^[[:space:]]*[[:alnum:]_.-]+[[:space:]]*=.*https?://'

matches_noncomment_line() {
  local pattern="$1"
  local sample="$2"

  printf '%s\n' "${sample}" | awk -v pattern="${pattern}" '
  {
    candidate = $0
    sub(/^[[:space:]]*/, "", candidate)
    if (candidate ~ /^\/\// || candidate ~ /^<!--/) {
      next
    }
    if ($0 ~ pattern) {
      found = 1
    }
  }
  END { exit found ? 0 : 1 }
  '
}

scan_file() {
  local file="$1"
  local pattern="$2"

  awk -v file="${file}" -v pattern="${pattern}" '
  {
    candidate = $0
    sub(/^[[:space:]]*/, "", candidate)
    if (candidate ~ /^\/\// || candidate ~ /^<!--/) {
      next
    }
    if ($0 ~ pattern) {
      print file ":" FNR ":" $0
    }
  }
  ' "${file}"
}

required_detection_samples=(
  'let session = URLSession.shared'
  'import Network'
  'let endpoint = "https://example.invalid/v1"'
)
for sample in "${required_detection_samples[@]}"; do
  if ! matches_noncomment_line "${swift_network_pattern}" "${sample}"; then
    echo "Network-egress gate no longer detects required sample: ${sample}" >&2
    exit 1
  fi
done

ignored_swift_samples=(
  'import StoreKit'
  '// see https://developer.apple.com/documentation/foundation/urlsession'
  '// let endpoint = "https://example.invalid/v1"'
)
for sample in "${ignored_swift_samples[@]}"; do
  if matches_noncomment_line "${swift_network_pattern}" "${sample}"; then
    echo "Network-egress gate incorrectly classifies harmless Swift sample: ${sample}" >&2
    exit 1
  fi
done

required_configuration_samples=(
  '<key>NSAppTransportSecurity</key>'
  '<key>com.apple.developer.networking.networkextension</key>'
  'INFOPLIST_KEY_NSAppTransportSecurity_NSAllowsArbitraryLoads = YES'
  '<string>https://api.example.invalid/v1</string>'
)
for sample in "${required_configuration_samples[@]}"; do
  if ! matches_noncomment_line "${configuration_network_pattern}" "${sample}"; then
    echo "Network-egress configuration gate no longer detects required sample: ${sample}" >&2
    exit 1
  fi
done

ignored_configuration_samples=(
  '<key>NSFaceIDUsageDescription</key>'
  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  '// Documentation: https://developer.apple.com/documentation/bundleresources/information_property_list'
)
for sample in "${ignored_configuration_samples[@]}"; do
  if matches_noncomment_line "${configuration_network_pattern}" "${sample}"; then
    echo "Network-egress configuration gate incorrectly classifies harmless sample: ${sample}" >&2
    exit 1
  fi
done

if [[ ! -s "${APPROVED_PUBLIC_CONFIGURATION_SOURCE}" ]]; then
  echo "Missing the one approved app-owned network adapter: ${APPROVED_PUBLIC_CONFIGURATION_SOURCE}" >&2
  exit 1
fi

approved_urls="$({
  grep -Eo 'https://[^"[:space:]]+' "${APPROVED_PUBLIC_CONFIGURATION_SOURCE}" || true
} | LC_ALL=C sort)"
expected_approved_urls="$(printf '%s\n' \
  'https://mindbudget-public-config-dev.yehao1105.workers.dev/v1/config' \
  'https://mindbudget-public-config-staging.yehao1105.workers.dev/v1/config' \
  'https://mindbudget-public-config.yehao1105.workers.dev/v1/config' \
  | LC_ALL=C sort)"
if [[ "${approved_urls}" != "${expected_approved_urls}" ]]; then
  echo "The approved public-configuration adapter must contain exactly the three reviewed URLs" >&2
  printf '%s\n' "${approved_urls}" >&2
  exit 1
fi

for approved_contract in \
  'URLSessionConfiguration.ephemeral' \
  'configuration.httpShouldSetCookies = false' \
  'configuration.urlCredentialStorage = nil' \
  'configuration.urlCache = nil' \
  'PublicConfigurationRedirectRejector()' \
  'request.httpMethod = "GET"' \
  'request.httpBody = nil' \
  'maximumResponseBytes: PublicConfigurationVerificationPolicy.maximumEnvelopeBytes' \
  '#if DEBUG' \
  'arguments.contains("-public-configuration-staging") ? .staging : .development' \
  '#else' \
  '.production'; do
  grep -Fq "${approved_contract}" "${APPROVED_PUBLIC_CONFIGURATION_SOURCE}" || {
    echo "Approved public-configuration adapter is missing contract: ${approved_contract}" >&2
    exit 1
  }
done

for forbidden_approved_shape in \
  'URLSession.shared' \
  'httpShouldSetCookies = true' \
  'httpCookieStorage' \
  'allowsArbitraryLoads' \
  'forHTTPHeaderField: "Authorization"' \
  'forHTTPHeaderField: "Cookie"'; do
  if grep -Fq "${forbidden_approved_shape}" "${APPROVED_PUBLIC_CONFIGURATION_SOURCE}"; then
    echo "Approved public-configuration adapter contains forbidden shape: ${forbidden_approved_shape}" >&2
    exit 1
  fi
done

swift_violations="$({
  while IFS= read -r -d '' file; do
    if [[ "${file}" == "${APPROVED_PUBLIC_CONFIGURATION_SOURCE}" ]]; then
      continue
    fi
    scan_file "${file}" "${swift_network_pattern}"
  done < <(find MindBudget -type f -name '*.swift' -print0)
} 2>/dev/null || true)"

configuration_files=()
while IFS= read -r -d '' file; do
  configuration_files+=("${file}")
done < <(
  find . -type f \
    \( -name '*.plist' -o -name '*.entitlements' -o -name '*.xcprivacy' -o -name '*.xcconfig' \) \
    ! -path './.git/*' \
    ! -path './.build/*' \
    ! -path './DerivedData/*' \
    ! -path './Docs/*' \
    ! -path './TestResults/*' \
    ! -path './MindBudgetTests/*' \
    ! -path './MindBudgetUITests/*' \
    -print0
)
if [[ -f MindBudget.xcodeproj/project.pbxproj ]]; then
  configuration_files+=(MindBudget.xcodeproj/project.pbxproj)
fi

configuration_violations="$({
  for file in "${configuration_files[@]}"; do
    scan_file "${file}" "${configuration_network_pattern}"
  done
} 2>/dev/null || true)"

violations="${swift_violations}"
if [[ -n "${configuration_violations}" ]]; then
  if [[ -n "${violations}" ]]; then
    violations+=$'\n'
  fi
  violations+="${configuration_violations}"
fi

if [[ -n "${violations}" ]]; then
  echo "App-owned network source or Release configuration found outside the one approved adapter:" >&2
  echo "${violations}" >&2
  echo "Accept a new exact channel before adding another centralized adapter exception." >&2
  exit 1
fi

echo "App-owned Release network egress is limited to the exact signed public-configuration adapter"
