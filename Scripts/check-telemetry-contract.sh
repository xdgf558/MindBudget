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

for file in "${DOMAIN_SOURCE}" "${CLIENT_SOURCE}" "${TEST_SOURCE}" "${PROJECT_FILE}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing C5-01 telemetry contract artifact: ${file}" >&2
    exit 1
  fi
done

event_cases="$(awk '
  /^enum TelemetryEvent: / { inside = 1; next }
  inside && /^    private enum CodingKeys:/ { exit }
  inside && /^    case / { print }
' "${DOMAIN_SOURCE}")"
expected_event_cases='    case appSessionStarted
    case proSurface(TelemetryProSurfaceAction)
    case subscription(TelemetryPurchaseAction, TelemetryOutcome)
    case receipt(TelemetryReceiptAction, TelemetryOutcome)
    case cloudSync(TelemetryCloudSyncAction, TelemetryOutcome)'
if [[ "${event_cases}" != "${expected_event_cases}" ]]; then
  echo "TelemetryEvent must retain the exact closed event vocabulary" >&2
  printf '%s\n' "${event_cases}" >&2
  exit 1
fi

upload_fields="$(awk '
  /^struct TelemetryUploadBatch: / { inside = 1; next }
  inside && /^}/ { exit }
  inside && /^    let / { print }
' "${DOMAIN_SOURCE}")"
expected_upload_fields='    let schemaVersion: Int
    let environment: TelemetryEnvironment
    let appVersion: TelemetryAppVersion
    let pseudonymousIdentifier: UUID
    let deletionHandle: String
    let events: [TelemetryQueuedEvent]'
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

if rg -n 'TelemetryClient[[:space:]]*\(' MindBudget --glob '*.swift' >/dev/null; then
  echo "C5-01 must remain dormant: production code instantiated TelemetryClient" >&2
  exit 1
fi

for contract in \
  'static let maximumQueuedEvents = 256' \
  'static let maximumBatchEvents = 20' \
  'static let maximumIdentityGenerations = 4' \
  'static let identityRotationDays = 30' \
  'static let deletionProofRetentionDays = 90' \
  'struct UnavailableTelemetryTransport: TelemetryTransporting' \
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
  'fixedVocabularyEncodesOnlyClosedKeysAndValues' \
  'optOutClearsUnsentEventsAndReenableCannotReuseThePriorPseudonym' \
  'concurrentCapturesSerializeReadModifyWriteWithoutLosingAnEvent' \
  'boundedQueueDropsOnlyTheOldestUnsentEvent' \
  'automaticRotationUsesCalendarDaysAndPreservesQueuedGeneration' \
  'uploadIsBoundedAndAcceptedIDsDoNotRemoveConcurrentCapture' \
  'concurrentFlushesShareOneTransportLaneAndCannotDuplicateABatch' \
  'remoteDeleteFailureRetainsProofsAndSuccessDestroysLocalState' \
  'corruptPersistenceIsStickyAndNeverOverwritten' \
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
