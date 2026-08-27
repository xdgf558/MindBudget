#!/usr/bin/env bash
set -euo pipefail

# These strings and exact field lists are reviewed contract anchors. C5-02 must change them only
# together with the accepted endpoint, server schema, disclosure, deletion, and retention packet.

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

DOMAIN_SOURCE="MindBudget/Services/TelemetryDomain.swift"
CLIENT_SOURCE="MindBudget/Services/TelemetryClient.swift"
TEST_SOURCE="MindBudgetTests/TelemetryClientTests.swift"
PROJECT_FILE="MindBudget.xcodeproj/project.pbxproj"

for command_name in awk grep mktemp rm; do
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

for file in "${DOMAIN_SOURCE}" "${CLIENT_SOURCE}" "${TEST_SOURCE}" "${PROJECT_FILE}"; do
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

if production_client_construction_scan MindBudget; then
  echo "C5-01 must remain dormant: production code instantiated TelemetryClient" >&2
  exit 1
else
  construction_scan_status=$?
  if [[ "${construction_scan_status}" -ne 1 ]]; then
    echo "C5-01 dormancy scan could not complete" >&2
    exit 1
  fi
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

for source_name in TelemetryDomain.swift TelemetryClient.swift TelemetryClientTests.swift; do
  if [[ "$(grep -Fc "${source_name} in Sources" "${PROJECT_FILE}")" -ne 2 ]]; then
    echo "${source_name} must have one build-file and one source-phase reference" >&2
    exit 1
  fi
done

echo "C5-01 dormant telemetry client contract passed"
