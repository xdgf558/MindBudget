#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

# COM-C0B accepts an empty app-owned Release HTTP(S) allow-list. Scan the app target rather
# than trusting documentation alone. System-owned transports such as StoreKit and CloudKit are
# not matched here; any future first-party networking adapter requires a phase-scoped, exact
# exception only after NETWORK_EGRESS_POLICY.md moves its channel to Accepted.
network_pattern='(^|[^[:alnum:]_])(URLSession|URLRequest|NSURLConnection|NWConnection|NWListener|NWBrowser|CFHTTPMessage|CFHost|CFSocket|WKWebView)([^[:alnum:]_]|$)|^[[:space:]]*import[[:space:]]+(Network|CFNetwork|WebKit)([[:space:]]|$)|https?://'

required_detection_samples=(
  'let session = URLSession.shared'
  'import Network'
  'let endpoint = "https://example.invalid/v1"'
)
for sample in "${required_detection_samples[@]}"; do
  if ! grep -Eq "${network_pattern}" <<< "${sample}"; then
    echo "Network-egress gate no longer detects required sample: ${sample}" >&2
    exit 1
  fi
done

if grep -Eq "${network_pattern}" <<< 'import StoreKit'; then
  echo "Network-egress gate must not classify StoreKit as app-owned HTTP(S)" >&2
  exit 1
fi

violations="$({
  find MindBudget -type f -name '*.swift' \
    -exec grep -nEH "${network_pattern}" {} +
} 2>/dev/null || true)"

if [[ -n "${violations}" ]]; then
  echo "App-owned network surface found while the current Release allow-list is empty:" >&2
  echo "${violations}" >&2
  echo "Accept the exact channel in Docs/Commercialization/NETWORK_EGRESS_POLICY.md before adding a narrow centralized adapter exception." >&2
  exit 1
fi

echo "Current app-owned Release network egress baseline is empty"
