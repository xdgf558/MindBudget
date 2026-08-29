#!/usr/bin/env bash
set -euo pipefail

# These strings, construction counts, and exact field lists are reviewed contract anchors.
# C5-04 permits one production factory and only the enumerated content-free capture call sites.

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

DOMAIN_SOURCE="MindBudget/Services/TelemetryDomain.swift"
CLIENT_SOURCE="MindBudget/Services/TelemetryClient.swift"
TRANSPORT_SOURCE="MindBudget/Services/TelemetryTransport.swift"
TEST_SOURCE="MindBudgetTests/TelemetryClientTests.swift"
PHASE6_TEST_SOURCE="MindBudgetTests/Phase6FeatureTests.swift"
PROJECT_FILE="MindBudget.xcodeproj/project.pbxproj"
PRIVACY_MANIFEST="MindBudget/Resources/PrivacyInfo.xcprivacy"
LOCALIZATION_CATALOG="MindBudget/Resources/Localizable.xcstrings"
LIVE_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget-Telemetry-Live.xcscheme"
DEFAULT_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget.xcscheme"

for command_name in awk grep mktemp rm sort tr wc; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "C5-01 telemetry contract requires ${command_name}" >&2
    exit 1
  fi
done

expected_event_cases='    case appSessionStarted
    case proSurface(TelemetryProSurfaceAction)
    case subscription(TelemetryPurchaseAction, TelemetryOutcome)
    case receipt(TelemetryReceiptAction, TelemetryOutcome)
    case cloudSync(TelemetryCloudSyncAction, TelemetryOutcome)'
expected_upload_fields='    let schemaVersion: Int
    let environment: TelemetryEnvironment
    let appVersion: TelemetryAppVersion
    let pseudonymousIdentifier: UUID
    let deletionHandle: String
    let events: [TelemetryQueuedEvent]'

telemetry_event_cases() {
  awk '
    /^enum TelemetryEvent: / { inside = 1; next }
    inside && /^    private enum CodingKeys:/ { exit }
    inside && /^    case / { print }
  ' "$1"
}

telemetry_upload_fields() {
  awk '
    /^struct TelemetryUploadBatch: / { inside = 1; next }
    inside && /^}/ { exit }
    inside && /^    let / { print }
  ' "$1"
}

# Return 0 when a construction is found, 1 when the scan is clean, and 2 when grep could not
# complete. Callers must distinguish 1 from every tool/filesystem failure so dormancy fails closed.
production_client_construction_scan() {
  local source_root="$1"
  local scan_status
  [[ -d "${source_root}" ]] || return 2
  set +e
  grep -REq --include='*.swift' 'TelemetryClient[[:space:]]*\(' "${source_root}" 2>/dev/null
  scan_status=$?
  set -e
  case "${scan_status}" in
    0) return 0 ;;
    1) return 1 ;;
    *) return 2 ;;
  esac
}

production_fixed_transport_construction_scan() {
  local source_root="$1"
  local scan_status
  [[ -d "${source_root}" ]] || return 2
  set +e
  grep -REq --include='*.swift' 'FixedTelemetryTransport[[:space:]]*\(' "${source_root}" 2>/dev/null
  scan_status=$?
  set -e
  case "${scan_status}" in
    0) return 0 ;;
    1) return 1 ;;
    *) return 2 ;;
  esac
}

self_test() {
  local fixture_directory fixture_domain fixture_source scan_status
  fixture_directory="$(mktemp -d "${TMPDIR:-/tmp}/mindbudget-telemetry-contract.XXXXXX")"
  fixture_domain="${fixture_directory}/TelemetryDomain.swift"
  fixture_source="${fixture_directory}/Safe.swift"
  trap 'rm -rf "${fixture_directory}"' RETURN

  printf '%s\n' \
    'enum TelemetryEvent: Codable {' \
    '    case appSessionStarted' \
    '    case proSurface(TelemetryProSurfaceAction)' \
    '    case subscription(TelemetryPurchaseAction, TelemetryOutcome)' \
    '    case receipt(TelemetryReceiptAction, TelemetryOutcome)' \
    '    case cloudSync(TelemetryCloudSyncAction, TelemetryOutcome)' \
    '    private enum CodingKeys: String, CodingKey {}' \
    '}' \
    'struct TelemetryUploadBatch: Codable {' \
    '    let schemaVersion: Int' \
    '    let environment: TelemetryEnvironment' \
    '    let appVersion: TelemetryAppVersion' \
    '    let pseudonymousIdentifier: UUID' \
    '    let deletionHandle: String' \
    '    let events: [TelemetryQueuedEvent]' \
    '}' > "${fixture_domain}"
  [[ "$(telemetry_event_cases "${fixture_domain}")" == "${expected_event_cases}" ]] || {
    echo "Telemetry gate self-test rejected the accepted event vocabulary" >&2
    exit 1
  }
  [[ "$(telemetry_upload_fields "${fixture_domain}")" == "${expected_upload_fields}" ]] || {
    echo "Telemetry gate self-test rejected the accepted upload envelope" >&2
    exit 1
  }

  printf '%s\n' \
    'enum TelemetryEvent: Codable {' \
    '    case appSessionStarted' \
    '    case proSurface(TelemetryProSurfaceAction)' \
    '    case subscription(TelemetryPurchaseAction, TelemetryOutcome)' \
    '    case receipt(TelemetryReceiptAction, TelemetryOutcome)' \
    '    case cloudSync(TelemetryCloudSyncAction, TelemetryOutcome)' \
    '    case callerDefined(String)' \
    '    private enum CodingKeys: String, CodingKey {}' \
    '}' \
    'struct TelemetryUploadBatch: Codable {' \
    '    let schemaVersion: Int' \
    '    let environment: TelemetryEnvironment' \
    '    let appVersion: TelemetryAppVersion' \
    '    let pseudonymousIdentifier: UUID' \
    '    let deletionHandle: String' \
    '    let events: [TelemetryQueuedEvent]' \
    '    let freeText: String' \
    '}' > "${fixture_domain}"
  [[ "$(telemetry_event_cases "${fixture_domain}")" != "${expected_event_cases}" ]] || {
    echo "Telemetry gate self-test failed to reject event-schema drift" >&2
    exit 1
  }
  [[ "$(telemetry_upload_fields "${fixture_domain}")" != "${expected_upload_fields}" ]] || {
    echo "Telemetry gate self-test failed to reject upload-envelope drift" >&2
    exit 1
  }

  printf '%s\n' 'struct SafeTelemetryFactory {}' > "${fixture_source}"
  if production_client_construction_scan "${fixture_directory}"; then
    echo "Telemetry gate self-test rejected a clean production tree" >&2
    exit 1
  else
    scan_status=$?
    [[ "${scan_status}" -eq 1 ]] || {
      echo "Telemetry gate self-test could not scan a clean production tree" >&2
      exit 1
    }
  fi
  printf '%s\n' 'let telemetry = TelemetryClient(persistence: persistence)' > "${fixture_source}"
  production_client_construction_scan "${fixture_directory}" || {
    echo "Telemetry gate self-test failed to detect production construction" >&2
    exit 1
  }
  if production_client_construction_scan "${fixture_directory}/missing"; then
    echo "Telemetry gate self-test treated a missing tree as a valid match" >&2
    exit 1
  else
    scan_status=$?
    [[ "${scan_status}" -eq 2 ]] || {
      echo "Telemetry gate self-test allowed an incomplete scan" >&2
      exit 1
    }
  fi
}

self_test

for file in "${DOMAIN_SOURCE}" "${CLIENT_SOURCE}" "${TRANSPORT_SOURCE}" "${TEST_SOURCE}" \
  "${PROJECT_FILE}" "${LIVE_SCHEME}" "${DEFAULT_SCHEME}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing C5-01 telemetry contract artifact: ${file}" >&2
    exit 1
  fi
done

event_cases="$(telemetry_event_cases "${DOMAIN_SOURCE}")"
if [[ "${event_cases}" != "${expected_event_cases}" ]]; then
  echo "TelemetryEvent must retain the exact closed event vocabulary" >&2
  printf '%s\n' "${event_cases}" >&2
  exit 1
fi

fixed_transport_construction_count="$(grep -REh --include='*.swift' \
  'FixedTelemetryTransport[[:space:]]*\(' MindBudget | wc -l | tr -d ' ')"
if [[ "${fixed_transport_construction_count}" -ne 1 ]] \
    || ! grep -Eq 'transport:[[:space:]]*FixedTelemetryTransport\(environment: environment\)' \
      "${CLIENT_SOURCE}"; then
  echo "C5-04 requires exactly one reviewed fixed-transport construction in TelemetryServiceFactory" >&2
  exit 1
fi

# A contextual `.init` still needs a type-bearing declaration somewhere. Keep the concrete client
# type confined to its owning source, and the concrete transport type confined to its definition
# plus that source. This catches type aliases, initializer function values, and cross-file sinks
# that a simple `Type(` construction count would miss.
client_reference_sources="$(grep -RIlE --include='*.swift' \
  '(^|[^[:alnum:]_])TelemetryClient([^[:alnum:]_]|$)' MindBudget | sort)"
if [[ "${client_reference_sources}" != "${CLIENT_SOURCE}" ]]; then
  echo "TelemetryClient type reference escaped its reviewed owning source" >&2
  printf '%s\n' "${client_reference_sources}" >&2
  exit 1
fi
expected_transport_reference_sources='MindBudget/Services/TelemetryClient.swift
MindBudget/Services/TelemetryTransport.swift'
transport_reference_sources="$(grep -RIlE --include='*.swift' \
  '(^|[^[:alnum:]_])FixedTelemetryTransport([^[:alnum:]_]|$)' MindBudget | sort)"
if [[ "${transport_reference_sources}" != "${expected_transport_reference_sources}" ]]; then
  echo "FixedTelemetryTransport type reference escaped its reviewed definition/factory sources" >&2
  printf '%s\n' "${transport_reference_sources}" >&2
  exit 1
fi
if grep -REq --include='*.swift' \
    'TelemetryClient[[:space:]]*\.[[:space:]]*init|typealias[^[:cntrl:]]*TelemetryClient|TelemetryClient[^=[:cntrl:]]*=[[:space:]]*\.init' \
    MindBudget; then
  echo "TelemetryClient initializer aliases/function values are forbidden" >&2
  exit 1
fi

upload_fields="$(telemetry_upload_fields "${DOMAIN_SOURCE}")"
if [[ "${upload_fields}" != "${expected_upload_fields}" ]]; then
  echo "Telemetry upload envelope escaped the reviewed closed schema" >&2
  printf '%s\n' "${upload_fields}" >&2
  exit 1
fi

if grep -Eq 'URLSession|URLRequest|NWConnection|https?://|import[[:space:]]+Network|import[[:space:]]+CloudKit' \
    "${DOMAIN_SOURCE}" "${CLIENT_SOURCE}"; then
  echo "C5-01 telemetry source must not contain a live network transport or endpoint" >&2
  exit 1
fi

if grep -Eq '(^|[^[:alnum:]_])(Money|ExpenseSummary|IncomeSummary|ReceiptOCRDocument|ReceiptModelSafeText|StoreProductID|ModelContext|DataActor|CloudSyncEnvelope)([^[:alnum:]_]|$)' \
    "${DOMAIN_SOURCE}" "${CLIENT_SOURCE}"; then
  echo "Telemetry source reached a forbidden financial, receipt-content, StoreKit, or data authority" >&2
  exit 1
fi

client_construction_count="$(grep -REh --include='*.swift' \
  'TelemetryClient[[:space:]]*\(' MindBudget | wc -l | tr -d ' ')"
if [[ "${client_construction_count}" -ne 1 ]] \
    || ! grep -Fq 'let client = TelemetryClient(' "${CLIENT_SOURCE}"; then
  echo "C5-04 requires exactly one reviewed TelemetryClient construction in its fixed factory" >&2
  exit 1
fi

for contract in \
  'static let maximumQueuedEvents = 256' \
  'static let maximumBatchEvents = 20' \
  'static let maximumIdentityGenerations = 4' \
  'static let identityRotationDays = 30' \
  'static let deletionProofRetentionDays = 90' \
  'init(calendar: Calendar = .autoupdatingCurrent)' \
  'struct UnavailableTelemetryTransport: TelemetryTransporting' \
  'case deletedLocallyWithoutRemoteProofs' \
  'case persistenceFailed' \
  'case terminalFailure(TelemetryTerminalFailure)' \
  'var terminalTransportFailure: TelemetryTerminalFailure? = nil' \
  'func retryTerminalTransport(now: Date) async -> TelemetryFlushResult' \
  'private var stateMutationInProgress = false' \
  'private var transportOperationInProgress = false' \
  'try retireCurrentIdentityForOptOut(in: &state, now: now)' \
  'options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]' \
  'values.isExcludedFromBackup = true' \
  'guard case let .valid(readBack) = read(), readBack == state'; do
  grep -Fq "${contract}" "${DOMAIN_SOURCE}" "${CLIENT_SOURCE}" || {
    echo "C5-01 telemetry source is missing contract: ${contract}" >&2
    exit 1
  }
done

for transport_contract in \
  'mindbudget-telemetry-dev.yehao1105.workers.dev' \
  'mindbudget-telemetry-staging.yehao1105.workers.dev' \
  'mindbudget-telemetry.yehao1105.workers.dev' \
  'URLSessionConfiguration.ephemeral' \
  'configuration.httpShouldSetCookies = false' \
  'configuration.urlCredentialStorage = nil' \
  'configuration.urlCache = nil' \
  'TelemetryRedirectRejector()' \
  'request.httpMethod = "POST"' \
  'request.setValue("MindBudget", forHTTPHeaderField: "User-Agent")' \
  'request.setValue("", forHTTPHeaderField: "Accept-Language")' \
  'encoder.dataEncodingStrategy = .base64' \
  'maximumUploadBytes = 32 * 1_024' \
  'maximumDeleteBytes = 2 * 1_024' \
  'maximumResponseBytes = 1_024' \
  'actor FixedTelemetryTransport: TelemetryTransporting' \
  'case 404: .endpointNotFound' \
  'case 405: .methodNotAllowed' \
  'case 421: .misdirectedRequest'; do
  grep -Fq "${transport_contract}" "${TRANSPORT_SOURCE}" || {
    echo "C5-02 telemetry transport is missing contract: ${transport_contract}" >&2
    exit 1
  }
done

for forbidden_transport_shape in \
  'URLSession.shared' \
  'httpShouldSetCookies = true' \
  'httpCookieStorage' \
  'forHTTPHeaderField: "Authorization"' \
  'forHTTPHeaderField: "Cookie"'; do
  if grep -Fq "${forbidden_transport_shape}" "${TRANSPORT_SOURCE}"; then
    echo "C5-02 telemetry transport contains forbidden shape: ${forbidden_transport_shape}" >&2
    exit 1
  fi
done

for test_contract in \
  'collectionIsDefaultOffAndDoesNotCreatePersistence' \
  'disablingANeverEnabledEncryptedClientCreatesNoFileOrKey' \
  'fixedVocabularyEncodesOnlyClosedKeysAndValues' \
  'policyUsesTheInjectedUserCalendarAcrossDaylightSavingTime' \
  'optOutClearsUnsentEventsAndReenableCannotReuseThePriorPseudonym' \
  'identityCapacityFailsClosedWithoutDiscardingDeletionProofs' \
  'concurrentCapturesSerializeReadModifyWriteWithoutLosingAnEvent' \
  'boundedQueueDropsOnlyTheOldestUnsentEvent' \
  'resetRotatesPseudonymButRetainsDeletionProof' \
  'automaticRotationUsesCalendarDaysAndPreservesQueuedGeneration' \
  'uploadIsBoundedAndAcceptedIDsDoNotRemoveConcurrentCapture' \
  'concurrentFlushesShareOneTransportLaneAndCannotDuplicateABatch' \
  'retryBackoffPreservesQueueAndDoesNotAffectCapture' \
  'acceptedUploadWithLocalCommitFailureIsNotClassifiedAsTransportFailure' \
  'remoteDeleteFailureRetainsProofsAndSuccessDestroysLocalState' \
  'remoteDeleteCanRetryTheSameProofAfterLocalCleanupFails' \
  'deletionRequestExplicitlyGroupsEveryRetainedGenerationForCompleteDeletion' \
  'corruptPersistenceIsStickyAndNeverOverwritten' \
  'corruptPersistenceCanBeDeletedLocallyWithoutClaimingRemoteDeletion' \
  'encryptedCorruptPersistenceDeletesFileAndKeyWithoutRemoteClaim' \
  'encryptedFileRoundTripsWithoutPlaintextAndCorruptionFailsClosed'; do
  grep -Fq "${test_contract}" "${TEST_SOURCE}" || {
    echo "C5-01 telemetry tests are missing contract: ${test_contract}" >&2
    exit 1
  }
done

for c504_test_contract in \
  'fixedEndpointPolicyFailuresAreStickyAndNeverRetryAutomatically' \
  'terminalDeletionFailureStopsCollectionAndRetainsEveryProofForExplicitRetry' \
  'terminalDeletionIsNotAttemptedWhenDisabledStateCannotBePersisted' \
  'persistedStateWithoutTerminalFailureFieldRemainsReadable' \
  'runtimeStartWhileDefaultOffCreatesNoPersistenceOrIdentity' \
  'unavailableRuntimeCannotBlockLocalUseOrClaimCollection' \
  'cancelledRuntimeStartCanBeRetriedWithoutLosingTheLifecycleEvent' \
  'runtimeStopDoesNotInvalidateExplicitTelemetryDeletionRetry' \
  'liveDevelopmentFixedTransportUsesAcceptedURLSessionHeadersAndDeletesSyntheticIdentity'; do
  grep -Fq "${c504_test_contract}" "${TEST_SOURCE}" || {
    echo "C5-04 telemetry tests are missing contract: ${c504_test_contract}" >&2
    exit 1
  }
done

grep -Fq 'key="MINDBUDGET_LIVE_TELEMETRY_TESTS" value="1" isEnabled="YES"' "${LIVE_SCHEME}" || {
  echo "C5-04 live telemetry scheme must explicitly enable its opt-in environment" >&2
  exit 1
}
if grep -Fq 'buildForArchiving="YES"' "${LIVE_SCHEME}" \
    || grep -Fq '<ArchiveAction' "${LIVE_SCHEME}"; then
  echo "C5-04 live telemetry probe scheme must never archive" >&2
  exit 1
fi
if grep -Fq 'MINDBUDGET_LIVE_TELEMETRY_TESTS' "${DEFAULT_SCHEME}"; then
  echo "Default MindBudget scheme must not enable the live telemetry probe" >&2
  exit 1
fi

grep -Fq 'telemetryDeletionFailureNeverBlocksLocalFinancialDeletion' "${PHASE6_TEST_SOURCE}" || {
  echo "C5-04 app-wide deletion must prove optional telemetry cannot block the local erase" >&2
  exit 1
}

capture_sources="$(grep -RIlE --include='*.swift' \
  'recordTelemetry\(|telemetryEventRecorder\.capture\(' MindBudget | sort)"
expected_capture_sources='MindBudget/App/AppRouter.swift
MindBudget/Features/AddExpense/AddExpenseView.swift
MindBudget/Features/Commerce/ProSubscriptionView.swift'
if [[ "${capture_sources}" != "${expected_capture_sources}" ]]; then
  echo "C5-04 telemetry capture escaped the reviewed production call-site list" >&2
  printf '%s\n' "${capture_sources}" >&2
  exit 1
fi

for activation_contract in \
  'let telemetryService: any TelemetryServicing' \
  'let telemetryService = TelemetryServiceFactory.live()' \
  'return UnavailableTelemetryService()' \
  'await session.startTelemetryLifecycle()' \
  'case deletingTelemetry' \
  'case completedWithPendingTelemetryDeletion' \
  'telemetryDeletionRemainsPending = true'; do
  grep -RFq "${activation_contract}" MindBudget || {
    echo "C5-04 production activation is missing contract: ${activation_contract}" >&2
    exit 1
  }
done

for privacy_contract in \
  'NSPrivacyCollectedDataTypeProductInteraction' \
  'NSPrivacyCollectedDataTypeDeviceID' \
  'NSPrivacyCollectedDataTypePurposeAnalytics'; do
  grep -Fq "${privacy_contract}" "${PRIVACY_MANIFEST}" || {
    echo "C5-04 privacy manifest is missing contract: ${privacy_contract}" >&2
    exit 1
  }
done

for disclosure_contract in \
  'telemetry.settings.defaultOff' \
  'telemetry.settings.neverCollects' \
  'telemetry.settings.retention.detail' \
  'telemetry.settings.delete.message' \
  'privacy.delete.telemetryPending.title' \
  'privacy.delete.telemetryPending.detail'; do
  grep -Fq "${disclosure_contract}" "${LOCALIZATION_CATALOG}" || {
    echo "C5-04 bilingual disclosure is missing contract: ${disclosure_contract}" >&2
    exit 1
  }
done

if grep -Fq 'telemetryDeletionFailureStopsBeforeFinancialRecordsAreRemoved' "${PHASE6_TEST_SOURCE}"; then
  echo "C5-04 must not retain the former test contract that optional telemetry blocks local Delete All" >&2
  exit 1
fi

for c502_test_contract in \
  'optOutCancelsTheInFlightUploadBeforeCommittingDisabledState' \
  'fixedTransportPostsOnlyTheReviewedDevelopmentUploadEnvelope' \
  'fixedTransportFailsClosedForEnvironmentDriftAndUnexpectedResponseContent' \
  'fixedTransportMapsRetryAfterAndUsesProofAuthenticatedDelete'; do
  grep -Fq "${c502_test_contract}" "${TEST_SOURCE}" || {
    echo "C5-02 telemetry tests are missing contract: ${c502_test_contract}" >&2
    exit 1
  }
done

for source_name in TelemetryDomain.swift TelemetryClient.swift TelemetryTransport.swift TelemetryClientTests.swift; do
  if [[ "$(grep -Fc "${source_name} in Sources" "${PROJECT_FILE}")" -ne 2 ]]; then
    echo "${source_name} must have one build-file and one source-phase reference" >&2
    exit 1
  fi
done

echo "C5-04 activated first-party telemetry contract passed"
