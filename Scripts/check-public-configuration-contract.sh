#!/usr/bin/env bash
set -euo pipefail

# The exact strings below are contract anchors, not prose search conveniences. Any source/test
# rename or contract wording change must update this gate in the same reviewed commit.

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

SOURCE="MindBudget/Commerce/PublicConfiguration.swift"
TEST_SOURCE="MindBudgetTests/PublicConfigurationTests.swift"
PROJECT_FILE="MindBudget.xcodeproj/project.pbxproj"

for file in "${SOURCE}" "${TEST_SOURCE}" "${PROJECT_FILE}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing public-configuration contract artifact: ${file}" >&2
    exit 1
  fi
done

noncomment_source() {
  awk '
  {
    candidate = $0
    sub(/^[[:space:]]*/, "", candidate)
    if (candidate ~ /^\/\//) {
      next
    }
    print
  }
  ' "${SOURCE}"
}

contains_forbidden_authority() {
  grep -Eq '(^|[^[:alnum:]_])(EntitlementSet|StoreProductID|URLSession|URLRequest|NotificationScheduler|TrialLifecycleProjection)([^[:alnum:]_]|$)|Product\.|https?://|US\$|\$[0-9]'
}

if ! printf '%s\n' 'let rights = EntitlementSet.proSubscription' | contains_forbidden_authority; then
  echo "Public-configuration gate no longer detects an entitlement authority sample" >&2
  exit 1
fi
if ! printf '%s\n' 'let task = URLSession.shared.data(from: endpoint)' | contains_forbidden_authority; then
  echo "Public-configuration gate no longer detects an embedded transport sample" >&2
  exit 1
fi
if printf '%s\n' 'let proValueTriggersEnabled: Bool' | contains_forbidden_authority; then
  echo "Public-configuration gate rejects its accepted presentation field" >&2
  exit 1
fi

if noncomment_source | contains_forbidden_authority; then
  echo "Signed public configuration reached price, trial, entitlement, notification, Product, or network authority" >&2
  exit 1
fi

presentation_fields="$({
  awk '
  /^struct PublicConfigurationPresentation: / { inside = 1; next }
  inside && /^}/ { exit }
  inside && /^[[:space:]]+let[[:space:]]+/ { print }
  ' "${SOURCE}"
} || true)"
if [[ "${presentation_fields}" != '    let proValueTriggersEnabled: Bool' ]]; then
  echo "Public configuration must retain exactly one closed presentation field" >&2
  printf '%s\n' "${presentation_fields}" >&2
  exit 1
fi

for contract in \
  'static let conservativeDefault = PublicConfigurationPresentation(' \
  'proValueTriggersEnabled: false' \
  'static let algorithm = "Ed25519"' \
  'static let schemaVersion = 1' \
  'static let maximumValidityInterval: TimeInterval = 7 * 24 * 60 * 60' \
  'static let grammar = "yyyy-MM-dd'\''T'\''HH:mm:ss'\''Z'\''"' \
  'case invalidSignature' \
  'case expired' \
  'case invalidValidityWindow' \
  'verified.payload.configVersion >= snapshot.highestAcceptedVersion' \
  'verified.payloadDigest != snapshot.highestAcceptedPayloadDigest' \
  'private var acceptanceTail: Task<PublicConfigurationResolutionResult, Never>?' \
  'try requireExactKeyOccurrences(' \
  'let matchesExpectedSnapshot = expectedSnapshot.map { expected in' \
  'options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]' \
  'guard (try? Data(contentsOf: fileURL)) == data else'; do
  grep -Fq "${contract}" "${SOURCE}" || {
    echo "Public-configuration source is missing contract: ${contract}" >&2
    exit 1
  }
done

for test_contract in \
  'invalidEnvelopeSignatureKeyAndUnknownFieldsFailClosed' \
  'fixedGoldenEnvelopeUsesTheFixedTimestampByteContract' \
  'concurrentAcceptanceCannotLowerThePersistedHighWaterMark' \
  'persistenceReadBackMustConfirmTheExactAcceptedSnapshot' \
  'filePersistenceTreatsMalformedRollbackRecordsAsStickyInvalidState' \
  'remoteRollbackAndSameVersionEquivocationKeepTheVerifiedCache' \
  'offlineUsesOnlyANonexpiredVerifiedCacheThenFallsBackBuiltIn' \
  'invalidPersistenceCannotBeOverwrittenAndNeverEnablesPresentation' \
  'persistenceFailureDoesNotActivateAnUnstoredConfiguration' \
  'atomicFilePersistenceRoundTripsOnlySignedPublicState' \
  'envelopeDataWithOversizedSignedPayload' \
  'envelopeDataWithUnknownPresentationField'; do
  grep -Fq "${test_contract}" "${TEST_SOURCE}" || {
    echo "Public-configuration tests are missing contract: ${test_contract}" >&2
    exit 1
  }
done

if [[ "$(grep -Fc 'PublicConfiguration.swift in Sources' "${PROJECT_FILE}")" -ne 2 ]]; then
  echo "PublicConfiguration.swift must have one build-file and one source-phase reference" >&2
  exit 1
fi
if [[ "$(grep -Fc 'PublicConfigurationTests.swift in Sources' "${PROJECT_FILE}")" -ne 2 ]]; then
  echo "PublicConfigurationTests.swift must have one build-file and one test source-phase reference" >&2
  exit 1
fi

echo "Signed public configuration core contract passed"
Scripts/check-public-configuration-transport.sh
