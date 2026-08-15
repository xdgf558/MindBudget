#!/usr/bin/env bash
set -euo pipefail

# These strings are reviewed C3-03B contract anchors. Source, Worker, scheme, or endpoint changes
# must update this gate in the same review rather than broadening an exception silently.

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

SOURCE="MindBudget/Commerce/PublicConfigurationTransport.swift"
TEST_SOURCE="MindBudgetTests/PublicConfigurationTransportTests.swift"
APP_ROUTER="MindBudget/App/AppRouter.swift"
SETTINGS_SOURCE="MindBudget/Features/Settings/SettingsView.swift"
PROJECT_FILE="MindBudget.xcodeproj/project.pbxproj"
DEFAULT_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget.xcscheme"
LIVE_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget-PublicConfig-Live.xcscheme"
WORKER_ROOT="Services/PublicConfigurationWorker"
WORKER_SOURCE="${WORKER_ROOT}/src/index.ts"
WORKER_CONFIG="${WORKER_ROOT}/wrangler.jsonc"
WORKER_TEST="${WORKER_ROOT}/test/index.spec.ts"

required_files=(
  "${SOURCE}"
  "${TEST_SOURCE}"
  "${APP_ROUTER}"
  "${SETTINGS_SOURCE}"
  "${PROJECT_FILE}"
  "${DEFAULT_SCHEME}"
  "${LIVE_SCHEME}"
  "${WORKER_SOURCE}"
  "${WORKER_CONFIG}"
  "${WORKER_TEST}"
  "${WORKER_ROOT}/package.json"
  "${WORKER_ROOT}/package-lock.json"
  "${WORKER_ROOT}/worker-configuration.d.ts"
  "${WORKER_ROOT}/scripts/sign-envelope.swift"
)
for file in "${required_files[@]}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing C3-03B public-configuration artifact: ${file}" >&2
    exit 1
  fi
done

for endpoint in \
  'https://mindbudget-public-config-dev.yehao1105.workers.dev/v1/config' \
  'https://mindbudget-public-config-staging.yehao1105.workers.dev/v1/config' \
  'https://mindbudget-public-config.yehao1105.workers.dev/v1/config'; do
  [[ "$(grep -Fc "${endpoint}" "${SOURCE}")" -eq 1 ]] || {
    echo "Client source must contain exact endpoint once: ${endpoint}" >&2
    exit 1
  }
done

for source_contract in \
  'static let publicKeyBase64 = "1nSPWfbGJuNSLBocaZVhUZj+KFsLxe7U3vl0i9VFFtg="' \
  'URLSessionConfiguration.ephemeral' \
  'configuration.timeoutIntervalForRequest = 8' \
  'configuration.timeoutIntervalForResource = 12' \
  'configuration.waitsForConnectivity = false' \
  'configuration.httpShouldSetCookies = false' \
  'configuration.urlCredentialStorage = nil' \
  'configuration.urlCache = nil' \
  'request.httpMethod = "GET"' \
  'request.httpBody = nil' \
  'logger.notice("reason=transport.\(reason.rawValue, privacy: .public)")' \
  'logger.notice("reason=resolution.\(reason.rawValue, privacy: .public)")'; do
  grep -Fq "${source_contract}" "${SOURCE}" || {
    echo "Public-configuration transport is missing contract: ${source_contract}" >&2
    exit 1
  }
done

if grep -Eq 'URLSession\.shared|forHTTPHeaderField: "(Authorization|Cookie)"|logger\.(debug|info|notice|warning|error|fault)\([^)]*(payload|signature|envelope|data)' "${SOURCE}"; then
  echo "Public-configuration client exposes shared transport, credentials, or content logging" >&2
  exit 1
fi

consumer_files="$({
  grep -Rl --include='*.swift' 'offersAppleOnDeviceAIProValueTrigger' MindBudget || true
} | LC_ALL=C sort)"
expected_consumer_files="$(printf '%s\n' "${APP_ROUTER}" "${SETTINGS_SOURCE}" | LC_ALL=C sort)"
if [[ "${consumer_files}" != "${expected_consumer_files}" ]]; then
  echo "Signed configuration must retain exactly one optional value-trigger consumer" >&2
  printf '%s\n' "${consumer_files}" >&2
  exit 1
fi

presentation_leaks="$({
  find MindBudget -type f -name '*.swift' \
    ! -path 'MindBudget/Commerce/PublicConfiguration.swift' \
    ! -path "${APP_ROUTER}" \
    -exec grep -nH 'proValueTriggersEnabled' {} +
} 2>/dev/null || true)"
if [[ -n "${presentation_leaks}" ]]; then
  echo "Raw signed presentation value escaped its AppSession boundary" >&2
  printf '%s\n' "${presentation_leaks}" >&2
  exit 1
fi

for test_contract in \
  'productionSignerGoldenResponseVerifiesWithTheEmbeddedProductionKey' \
  'liveDevelopmentWorkerResponsePassesTheProductionTrustAndSchemaBoundary' \
  'exactEnvironmentRequestsContainOnlyReviewedMetadataAndNoBody' \
  'redirectWrongURLStatusTypeEmptyAndOversizeResponsesFailClosed' \
  'invalidSignatureAndOfflineTransportRetainOnlyVerifiedCache' \
  'signedPresentationControlsOnlyTheOptionalFreeValueTrigger'; do
  grep -Fq "${test_contract}" "${TEST_SOURCE}" || {
    echo "Public-configuration transport tests are missing: ${test_contract}" >&2
    exit 1
  }
done

if [[ "$(grep -Fc 'PublicConfigurationTransport.swift in Sources' "${PROJECT_FILE}")" -ne 2 ]]; then
  echo "PublicConfigurationTransport.swift must have one build-file and one app source-phase reference" >&2
  exit 1
fi
if [[ "$(grep -Fc 'PublicConfigurationTransportTests.swift in Sources' "${PROJECT_FILE}")" -ne 2 ]]; then
  echo "PublicConfigurationTransportTests.swift must have one build-file and one test source-phase reference" >&2
  exit 1
fi

grep -Fq 'key="MINDBUDGET_LIVE_PUBLIC_CONFIG_TESTS" value="1" isEnabled="YES"' "${LIVE_SCHEME}" || {
  echo "Dedicated live public-configuration scheme must opt in explicitly" >&2
  exit 1
}
if grep -Fq 'buildForArchiving="YES"' "${LIVE_SCHEME}" || grep -Fq '<ArchiveAction' "${LIVE_SCHEME}"; then
  echo "Dedicated live public-configuration scheme must never Archive" >&2
  exit 1
fi
if grep -Fq 'MINDBUDGET_LIVE_PUBLIC_CONFIG_TESTS' "${DEFAULT_SCHEME}"; then
  echo "Default scheme must not opt in to live public-configuration traffic" >&2
  exit 1
fi

for worker_contract in \
  'const CONFIGURATION_PATH = "/v1/config"' \
  'const APP_VERSION_HEADER = "X-MindBudget-App-Version"' \
  'const CONFIG_VERSION_HEADER = "X-MindBudget-Config-Version"' \
  'request.method !== "GET"' \
  'request.body !== null' \
  'request.headers.has("Authorization")' \
  'request.headers.has("Cookie")' \
  'PUBLIC_CONFIG_RATE_LIMITER.limit({ key: abuseKey })' \
  '"Cache-Control": "no-store"' \
  'keyID: "mb-config-2026-01"'; do
  grep -Fq "${worker_contract}" "${WORKER_SOURCE}" || {
    echo "Worker is missing C3-03B contract: ${worker_contract}" >&2
    exit 1
  }
done

if grep -Eq 'console\.|PRIVATE KEY|BEGIN PRIVATE|await[[:space:]]+fetch\(|globalThis\.fetch\(' "${WORKER_SOURCE}"; then
  echo "Worker source contains logging, key material, or an outbound fetch" >&2
  exit 1
fi

for worker_config_contract in \
  '"name": "mindbudget-public-config"' \
  '"compatibility_date": "2026-08-15"' \
  '"preview_urls": false' \
  '"enabled": false' \
  '"name": "mindbudget-public-config-dev"' \
  '"name": "mindbudget-public-config-staging"' \
  '"EXPECTED_HOST": "mindbudget-public-config.yehao1105.workers.dev"' \
  '"EXPECTED_HOST": "mindbudget-public-config-dev.yehao1105.workers.dev"' \
  '"EXPECTED_HOST": "mindbudget-public-config-staging.yehao1105.workers.dev"'; do
  grep -Fq "${worker_config_contract}" "${WORKER_CONFIG}" || {
    echo "Worker configuration is missing contract: ${worker_config_contract}" >&2
    exit 1
  }
done

if [[ "$(grep -Fc '"name": "PUBLIC_CONFIG_RATE_LIMITER"' "${WORKER_CONFIG}")" -ne 3 ]]; then
  echo "Every exact Worker environment must have its own rate limiter" >&2
  exit 1
fi
if grep -Eq '"(kv_namespaces|d1_databases|r2_buckets|analytics_engine_datasets|tail_consumers|services|durable_objects|queues)"' "${WORKER_CONFIG}"; then
  echo "Public-configuration Worker must have no storage, analytics, queue, or service binding" >&2
  exit 1
fi

for worker_test_contract in \
  'returns only the pre-signed envelope on the exact anonymous request' \
  'rejects %s without a response body' \
  'uses the edge address only as an opaque limiter key and returns no content when limited'; do
  grep -Fq "${worker_test_contract}" "${WORKER_TEST}" || {
    echo "Worker tests are missing contract: ${worker_test_contract}" >&2
    exit 1
  }
done

echo "Signed public-configuration transport and Worker contract passed"
