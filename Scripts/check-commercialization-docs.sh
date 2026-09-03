#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

SOURCE_PROVENANCE="Docs/Commercialization/SOURCE_PROVENANCE.md"
PHASE_STATE_CHECKER="Scripts/commercialization_phase_states.py"
AUTHORITATIVE_PHASE_IDS="COM-C0A,COM-C0B,COM-C1,COM-C2,COM-C3,COM-C4A,COM-C4B,COM-C4C,COM-C5,COM-C6,COM-C6.5,G1,COM-C7,COM-C8,COM-C9,COM-C10,COM-C11,COM-C12"
MONTHLY_PRODUCT_ID="com.xdgf558.mindbudget.pro.monthly"
ANNUAL_PRODUCT_ID="com.xdgf558.mindbudget.pro.annual"

required_files=(
  AGENTS.md
  Docs/PROJECT_MEMORY.md
  Docs/COMMERCIALIZATION_TASKS.md
  Docs/Commercialization/PROJECT_MEMORY.md
  Docs/Commercialization/DECISIONS.md
  Docs/Commercialization/SESSION_LOG.md
  Docs/Commercialization/REQUIREMENTS_INDEX.md
  Docs/Commercialization/SPEC_CONFLICTS.md
  Docs/Commercialization/SOURCE_PROVENANCE.md
  Docs/PRIVACY_AND_REVIEW_NOTES.md
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md
  Docs/Commercialization/STOREKIT_TEST_MATRIX.md
  Docs/Commercialization/REGIONAL_PRICING.md
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md
  Docs/Commercialization/CI_BASELINE.md
  Docs/Commercialization/COM_C1_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C2_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C3_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md
  Docs/Commercialization/C6_02_PREFLIGHT.md
  Docs/Commercialization/C6_02_ACCEPTANCE_MATRIX.json
  Docs/Commercialization/C6_03_RELEASE_BASELINE.md
  Docs/Commercialization/C6_RELEASE_MATRIX.json
  Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md
  Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md
  Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md
)

for file in "${required_files[@]}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing or empty commercialization artifact: ${file}" >&2
    exit 1
  fi
done

# Phase status is parsed structurally rather than being a growing collection of exact prose
# comparisons below. The checker proves its own missing/duplicate/status-conflict fixtures before
# it reads the durable phase map and execution packets. Require-all detects deletion of a Status
# below a retained heading; the approved top-level phase-ID set separately detects deletion of an
# authoritative phase without coupling the gate to mutable status prose. Newly structured
# subphases are protected automatically by require-all. C1's historical
# subpacket headings are the narrow source-level exception because that packet predates per-packet
# Status records; its top-level COM-C1 state remains mandatory in the authoritative task map.
python3 -B "${PHASE_STATE_CHECKER}" --self-test
python3 -B "${PHASE_STATE_CHECKER}" \
  --require-all-status Docs/COMMERCIALIZATION_TASKS.md \
  --require-all-status Docs/Commercialization/COM_C2_EXECUTION_PACKET.md \
  --require-all-status Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
  --require-all-status Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md \
  --require-all-status Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
  --require-all-status Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
  --require-all-status Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
  --require-all-status Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  --expect-identifiers "Docs/COMMERCIALIZATION_TASKS.md:${AUTHORITATIVE_PHASE_IDS}" \
  --expect-section 'Docs/COMMERCIALIZATION_TASKS.md:C6-01:done:x' \
  --expect-section 'Docs/COMMERCIALIZATION_TASKS.md:C6-02:done:x' \
  --expect-section 'Docs/COMMERCIALIZATION_TASKS.md:C6-03:done:x' \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/Commercialization/COM_C1_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C2_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md

# C4B uses a small structural parser rather than another phase-specific collection of prose
# comparisons. It verifies the required contract declarations and makes a future CloudKit
# import/entitlement fail unless DataController's primary local stores are explicitly `.none`.
python3 -B Scripts/check_icloud_sync_contract.py --self-test
python3 -B Scripts/check_icloud_sync_contract.py

# C6-02's remaining manual rows are closed only as a bounded disposition. The checker proves the
# exact five-row vocabulary, all 23 deterministic runtime bindings, explicit non-pass text, and
# every still-blocked archive/remote/release action. Runtime execution is verified later by the
# full validator against its newly produced xcresult.
python3 -B Scripts/check_c6_02_acceptance.py --self-test
if grep -Fq -- '--schema-version' Scripts/check_c6_02_acceptance.py; then
  echo "C6-02 acceptance must consume the active Xcode toolchain's native xcresult schema" >&2
  exit 1
fi
grep -Fq 'repetition.get("nodeType") == "Repetition"' Scripts/check_c6_02_acceptance.py || {
  echo "C6-02 acceptance lost real xcresult retry-node inspection" >&2
  exit 1
}
grep -Fq 'real failed-then-passed repetition nodes' Scripts/check_c6_02_acceptance.py || {
  echo "C6-02 acceptance must reject a retry that hides an earlier failure" >&2
  exit 1
}

# C4C-01 established premium/evidence seams. C4C-02 owns bounded system image acquisition and
# temporary lifecycle. C4C-03 adds local OCR only through the mandatory sensitive-text boundary.
# C4C-04 may consume only that safe document, keeps deterministic extraction authoritative, and
# confines optional model use to the exact on-device adapter; persistence and customer entry remain
# structurally absent.
for c4c01_contract in \
  'DEC-COM-044' \
  'existing 30-day Insights' \
  'supportingSampleCount / sampleCount' \
  '`LocalReceiptRecognitionBaseline`' \
  '`FeatureFlags.enableReceiptImport` remains false' \
  'Status: **Done after independent review'; do
  if ! grep -Fq "${c4c01_contract}" \
      Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md; then
    echo "C4C-01 premium/evidence contract is missing: ${c4c01_contract}" >&2
    exit 1
  fi
done

for c4c01_source_anchor in \
  'var permitsAdvancedLocalInsights: Bool' \
  'var permitsPurchasePreflight: Bool' \
  'var permitsPostPurchaseReview: Bool' \
  'enum LocalReceiptRecognitionBaseline' \
  'struct RuleEvidence: Equatable, Sendable' \
  'RuleEvidencePayload.persistedPayload(for: draft)' \
  'premiumEntryAccess.permitsAdvancedLocalInsights'; do
  if ! grep -Fq "${c4c01_source_anchor}" \
      MindBudget/Commerce/FeatureAccessService.swift \
      MindBudget/Services/SpendingPatternDetector.swift \
      MindBudget/Data/DataActor.swift \
      MindBudget/Features/Insights/InsightsView.swift; then
    echo "C4C-01 source contract is missing: ${c4c01_source_anchor}" >&2
    exit 1
  fi
done

grep -Fq 'static let enableReceiptImport = true' MindBudget/App/FeatureFlags.swift || {
  echo "C4C-05 must keep the reviewed local receipt entry enabled" >&2
  exit 1
}

for c4c02_source_anchor in \
  'maximumSourcePixels: 64_000_000' \
  'maximumPreparedEdge: 4_096' \
  'maximumPreparedPixels: 12_000_000' \
  'maximumPreparedBytes: 8 * 1_024 * 1_024' \
  'FileProtectionType.complete' \
  'isExcludedFromBackup = true' \
  'func discardTemporaryImage() async' \
  'DataScannerViewController.isSupported' \
  'PHPickerConfiguration(photoLibrary: .shared())' \
  'provider.loadFileRepresentation(' \
  'handle.read(upToCount: readLimit.partialValue)' \
  'requestCameraAuthorization() async'; do
  if ! grep -RFq "${c4c02_source_anchor}" \
      MindBudget/Services/ReceiptRecognition \
      MindBudget/App/AppRouter.swift; then
    echo "C4C-02 bounded acquisition/lifecycle source contract is missing: ${c4c02_source_anchor}" >&2
    exit 1
  fi
done

c4c02_unowned_import="$({
  grep -RInE '^[[:space:]]*(@preconcurrency[[:space:]]+)?import[[:space:]]+(Vision|VisionKit|PhotosUI)([^[:alnum:]_]|$)' MindBudget \
    | grep -vE 'MindBudget/Services/ReceiptRecognition/(ReceiptVisionObservation|ReceiptSystemImageAcquisition)\.swift:'
} 2>/dev/null || true)"
if [[ -n "${c4c02_unowned_import}" ]]; then
  echo "C4C-02 image frameworks escaped their exact reviewed adapter files:" >&2
  echo "${c4c02_unowned_import}" >&2
  exit 1
fi

if grep -RInE 'DataScannerViewControllerDelegate|recognizedItems' \
    MindBudget/Services/ReceiptRecognition; then
  echo "C4C-03 must not consume live DataScanner recognition callbacks" >&2
  exit 1
fi
if grep -RInE '(^|[^[:alnum:]_])(SwiftData|DataActor|ModelContext|CloudSync)([^[:alnum:]_]|$)' \
    MindBudget/Services/ReceiptRecognition; then
  echo "C4C-02 receipt images must not enter persistence or cloud-sync paths" >&2
  exit 1
fi
if grep -Rq 'NSPhotoLibraryUsageDescription' MindBudget Config MindBudget.xcodeproj; then
  echo "C4C-02 uses PHPicker and must not request broad Photo Library permission" >&2
  exit 1
fi
[[ "$(grep -o 'INFOPLIST_KEY_NSCameraUsageDescription = "Use the camera to capture a receipt for local processing."' MindBudget.xcodeproj/project.pbxproj | wc -l | tr -d ' ')" == "2" ]] || {
  echo "C4C-02 camera purpose string must exist in Debug and Release" >&2
  exit 1
}

for c4c03_source_anchor in \
  'let maximumObservationCount: Int' \
  'maximumObservationCount: 256' \
  'maximumObservationBytes: 512' \
  'maximumDocumentBytes: 16 * 1_024' \
  'let text: ReceiptModelSafeText' \
  'fileprivate init(storage:' \
  'static let replacementToken = "[redacted]"' \
  'case paymentCardNumber' \
  'case paymentCardLastFour' \
  'case authorizationCode' \
  'let request = VNRecognizeTextRequest()' \
  'request.automaticallyDetectsLanguage = true' \
  'ReceiptOCRPrivacyPipeline(' \
  'return lhs.stableIndex < rhs.stableIndex'; do
  if ! grep -RFq "${c4c03_source_anchor}" \
      MindBudget/Services/ReceiptRecognition; then
    echo "C4C-03 local OCR/privacy source contract is missing: ${c4c03_source_anchor}" >&2
    exit 1
  fi
done

c4c03_unowned_raw_ocr="$({
  grep -RInE 'VNRecognizeTextRequest|VNRecognizedText|ReceiptVisionTextObservation' MindBudget \
    | grep -vE 'MindBudget/Services/ReceiptRecognition/ReceiptVisionObservation\.swift:'
} 2>/dev/null || true)"
if [[ -n "${c4c03_unowned_raw_ocr}" ]]; then
  echo "C4C-03 raw OCR escaped its exact reviewed Vision adapter:" >&2
  echo "${c4c03_unowned_raw_ocr}" >&2
  exit 1
fi

c4c04_unowned_safe_ocr="$({
  grep -RInE 'ReceiptOCRDocument|ReceiptModelSafeText' MindBudget \
    | grep -vE 'MindBudget/Services/ReceiptRecognition/(ReceiptVisionObservation|ReceiptSensitiveTextFilter|ReceiptStructuredExtraction|ReceiptLocalModelExtractor)\.swift:'
} 2>/dev/null || true)"
if [[ -n "${c4c04_unowned_safe_ocr}" ]]; then
  echo "C4C-04 filtered OCR escaped the exact reviewed extraction/model boundary:" >&2
  echo "${c4c04_unowned_safe_ocr}" >&2
  exit 1
fi

if grep -RInE '(^|[^[:alnum:]_])(URLSession|AIAdviceGenerator|AskMindBudgetService|PublicConfigurationTransport)([^[:alnum:]_]|$)' \
    MindBudget/Services/ReceiptRecognition; then
  echo "C4C-04 local receipt processing must not gain a remote model or network channel" >&2
  exit 1
fi

c4c04_unowned_model_import="$({
  grep -RInE '^[[:space:]]*(@preconcurrency[[:space:]]+)?import[[:space:]]+FoundationModels([^[:alnum:]_]|$)' MindBudget \
    | grep -vE 'MindBudget/Services/(AIAdviceGenerator|ReceiptRecognition/ReceiptLocalModelExtractor)\.swift:'
} 2>/dev/null || true)"
if [[ -n "${c4c04_unowned_model_import}" ]]; then
  echo "C4C-04 FoundationModels escaped its exact reviewed on-device adapter:" >&2
  echo "${c4c04_unowned_model_import}" >&2
  exit 1
fi

for c4c04_source_anchor in \
  'struct ReceiptStructuredExtractionService: Sendable' \
  'let deterministicCandidates = deterministicExtractor.extract(from: document)' \
  'ReceiptModelEvidenceVerifier().isBackedByDocument(' \
  'case deterministicFallback(ReceiptModelFallbackReason)' \
  'static let production = ReceiptLineItemExperiment(isEnabled: false)' \
  'Money.maximumMinorUnits(for: currencyCode)' \
  'struct ReceiptDuplicateDetector: Sendable' \
  'struct FoundationModelsReceiptExtractor: ReceiptLocalModelExtracting, Sendable' \
  'Return only exact, contiguous snippets copied from DATA.'; do
  if ! grep -RFq "${c4c04_source_anchor}" MindBudget/Services/ReceiptRecognition; then
    echo "C4C-04 structured extraction contract is missing: ${c4c04_source_anchor}" >&2
    exit 1
  fi
done

if grep -RInE '(^|[^[:alnum:]_])(SwiftData|DataActor|ModelContext|CloudSync|URLSession)([^[:alnum:]_]|$)' \
    MindBudget/Services/ReceiptRecognition/ReceiptStructuredExtraction.swift \
    MindBudget/Services/ReceiptRecognition/ReceiptLocalModelExtractor.swift; then
  echo "C4C-04 structured extraction must remain local, ephemeral, and persistence-free" >&2
  exit 1
fi

# C4C-01 is closed only by the reviewed exact head, hosted CI, source merge, and documentation
# closeout. Every later subphase additionally requires the owner's explicit entry.
for c4c01_closeout_anchor in \
  'd203308' \
  '32845307426' \
  '8611022' \
  '32850616400' \
  'bdb94d9' \
  'C4C-01 is Done' \
  'owner then explicitly entered C4C-02'; do
  if ! grep -Fq "${c4c01_closeout_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/CI_BASELINE.md; then
    echo "C4C-01 reviewed merge closeout is missing: ${c4c01_closeout_anchor}" >&2
    exit 1
  fi
done

if grep -Eq 'C4C-01 (independent review and hosted CI pending|implementation (is )?pending independent review|remains pending (independent review|hosted CI|merge))' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes C4C-01 as pending review/CI/merge" >&2
  exit 1
fi

if grep -Eq 'C4C-02 (remains |is )?blocked|C4C-02 through C4C-05 remain blocked' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes C4C-02 as blocked after owner entry" >&2
  exit 1
fi

# C4C-02 is closed only by independently reviewed source and documentation heads plus their green
# hosted runs and merges. The owner subsequently entered C4C-03; the customer entry stays off.
for c4c02_closeout_anchor in \
  '43c3a35' \
  '32860643712' \
  '4ca8f1c' \
  '4ab0daf' \
  '32911659905' \
  '3e1c5c9' \
  'C4C-02 is Done' \
  'owner explicitly entered C4C-03'; do
  if ! grep -Fq "${c4c02_closeout_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/CI_BASELINE.md; then
    echo "C4C-02 reviewed merge closeout is missing: ${c4c02_closeout_anchor}" >&2
    exit 1
  fi
done

if grep -Eq 'C4C-02 (implementation (is )?complete pending independent review|awaits independent review|pending review/CI/merge|remains pending (independent review|hosted CI|merge))' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes C4C-02 as pending review/CI/merge" >&2
  exit 1
fi

if grep -Eq 'C4C-03 (remains |is )?blocked|C4C-03 through C4C-05 remain blocked|awaiting explicit owner entry for C4C-03' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes C4C-03 as blocked after owner entry" >&2
  exit 1
fi

# C4C-03 is closed only by its reviewed order-regression head, exact green hosted run, and merge.
# The owner subsequently entered C4C-04; receipt import must stay off.
for c4c03_closeout_anchor in \
  '92ed3a7' \
  '32921913143' \
  'd294cfb' \
  'C4C-03 is Done' \
  'owner explicitly entered C4C-04'; do
  if ! grep -Fq "${c4c03_closeout_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/CI_BASELINE.md; then
    echo "C4C-03 reviewed merge closeout is missing: ${c4c03_closeout_anchor}" >&2
    exit 1
  fi
done

if grep -Eq 'C4C-03 (implementation (is )?complete pending independent review|awaits independent review|pending review/CI/merge|remains pending (independent review|hosted CI|merge))' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes C4C-03 as pending review/CI/merge" >&2
  exit 1
fi

if grep -Eq 'C4C-04 (remains |is )?blocked|C4C-04/C4C-05 remain blocked|awaiting explicit owner entry for C4C-04|Blocked pending explicit owner entry after C4C-03' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes C4C-04 as blocked after owner entry" >&2
  exit 1
fi

# C4C-04 is closed only by its reviewed fail-closed remediation head, exact green hosted run, and
# merge. C4C-05 is a separately owner-entered confirmation/evaluation packet.
for c4c04_closeout_anchor in \
  'f2d249d' \
  '32946104780' \
  'e6316fa' \
  'C4C-04 is Done' \
  'DEC-COM-050'; do
  if ! grep -Fq "${c4c04_closeout_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/CI_BASELINE.md; then
    echo "C4C-04 reviewed merge closeout is missing: ${c4c04_closeout_anchor}" >&2
    exit 1
  fi
done

if grep -Eq 'Pending independent review for the C4C-04 candidate|C4C-04 (implementation (is )?complete pending (independent )?review|awaits independent review|pending review/CI/merge|remains pending (independent review|hosted CI|merge))' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes C4C-04 as pending review/CI/merge" >&2
  exit 1
fi

for c4c05_source_anchor in \
  'static let enableReceiptImport = true' \
  'struct ReceiptImportView: View' \
  'struct ReceiptCaptureOverlay: View' \
  'struct ReceiptCapturePreviewView: View' \
  'struct ReceiptReviewCard: View' \
  'case recognizing' \
  'hasCompletedReceiptImport' \
  'Task.detached(priority: .userInitiated)' \
  'the existing explicit Save action remains the sole persistence boundary' \
  'hasImportedReceipt ? .receiptImport : .manual' \
  'fixedReceiptMatrixCoversAtLeastSixtyExactReceiptsAndNonReceipts' \
  'twentySequentialRealImagesStayBoundedAndLeaveNoTemporaryArtifact' \
  'recognizedFieldsRemainEphemeralUntilTheExistingSaveAction' \
  'applyRecognizedReceiptRespectingUserEdits' \
  'editedFieldsDuringReceiptRecognition' \
  '@Published private(set) var amountText' \
  '@Published private(set) var spentAt' \
  '@Published private(set) var merchantName' \
  'updateAmountTextFromUser' \
  'editedFieldsStayUserOwnedEvenWhenChangedBackToTheirStartingValues' \
  'case let .failed(failure):' \
  'receipt.failure.unreadable.title' \
  'receipt.failure.unreadable.detail' \
  'case .productDisabled:' \
  '.failed(.productDisabled)' \
  'case .requiresPro:' \
  '.failed(.requiresPro)' \
  'discardTemporaryImage(matching artifactID: UUID)' \
  'staleArtifactCleanupCannotDeleteANewerGeneration' \
  'phase == .background' \
  'ReceiptInactivePrivacyShield' \
  'fullResolutionIPhoneCaptureIsDownsampledToThePreparedPixelLimit' \
  'pipelineClampsOnlyMinorVisionGeometryDrift'; do
  if ! grep -RFq "${c4c05_source_anchor}" \
      MindBudget/App/FeatureFlags.swift \
      MindBudget/Commerce/FeatureAccessService.swift \
      MindBudget/Features/AddExpense \
      MindBudget/Services/ReceiptRecognition \
      MindBudgetTests; then
    echo "C4C-05 customer confirmation/evaluation source contract is missing: ${c4c05_source_anchor}" >&2
    exit 1
  fi
done

if grep -Fq 'func applyReceiptImport(' \
    MindBudget/Features/AddExpense/AddExpenseView.swift; then
  echo "C4C-05 must not retain a dead unconditional receipt-prefill API beside the production edit-preserving path" >&2
  exit 1
fi

if grep -Fq 'receipt.error.unreadable' \
    MindBudget/Features/AddExpense/ReceiptImportView.swift \
    MindBudget/Resources/Localizable.xcstrings || \
   grep -Fq 'receipt.failure.inline.title' \
    MindBudget/Features/AddExpense/ReceiptImportView.swift \
    MindBudget/Resources/Localizable.xcstrings || \
   grep -Fq 'receipt.failure.inline.detail' \
    MindBudget/Features/AddExpense/ReceiptImportView.swift \
    MindBudget/Resources/Localizable.xcstrings; then
  echo "C4C-05 unreadable-image copy must use the shared non-surface-specific localized keys" >&2
  exit 1
fi

for c4c05_contract_anchor in \
  'C4C-05 implementation/evaluation' \
  'DEC-COM-051' \
  'DEC-COM-052' \
  'DEC-COM-053' \
  'DEC-COM-054' \
  'recommended option A' \
  'existing explicit Save action' \
  'explicit per-generation edit ownership' \
  'inactive scenes mask receipt work while only backgrounding discards it' \
  'artifact-ID cleanup' \
  '60 exact supported receipts' \
  'Physical iOS 26.6.1 DataScanner/PHPicker/OCR'; do
  if ! grep -Fq "${c4c05_contract_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md; then
    echo "C4C-05 customer confirmation/evaluation contract is missing: ${c4c05_contract_anchor}" >&2
    exit 1
  fi
done

# C4C-05 and COM-C4C close on the chronologically exact record: pre-merge review of `8607356`,
# final maintenance head `81cd107`, green hosted run, PR #74 merge without pre-merge rereview, and
# post-merge exact-delta review during PR #75. Require the core provenance and scope boundary in
# every current-state/evidence file rather than accepting an anchor from any one file in the set.
c4c05_closeout_files=(
  Docs/COMMERCIALIZATION_TASKS.md
  Docs/TASKS.md
  Docs/PROJECT_MEMORY.md
  Docs/Commercialization/PROJECT_MEMORY.md
  Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md
  Docs/Commercialization/REQUIREMENTS_INDEX.md
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md
  Docs/Commercialization/CI_BASELINE.md
)

for c4c05_closeout_file in "${c4c05_closeout_files[@]}"; do
  for c4c05_provenance_anchor in '8607356' '81cd107' '33035427257' 'd751ff4'; do
    if ! grep -Fq "${c4c05_provenance_anchor}" "${c4c05_closeout_file}"; then
      echo "C4C-05 provenance is missing ${c4c05_provenance_anchor} in ${c4c05_closeout_file}" >&2
      exit 1
    fi
  done
  for c4c05_scope_anchor in 'manual-review-only' 'explicit owner entry'; do
    if ! grep -Fq "${c4c05_scope_anchor}" "${c4c05_closeout_file}"; then
      echo "C4C-05 scope is missing ${c4c05_scope_anchor} in ${c4c05_closeout_file}" >&2
      exit 1
    fi
  done
done

grep -Fq 'DEC-COM-055' Docs/Commercialization/DECISIONS.md || {
  echo "C4C-05 reviewed merge closeout is missing DEC-COM-055" >&2
  exit 1
}

if grep -Eq 'C4C-05 (implementation/evaluation( plus capture redesign)? (is )?complete pending (independent )?review|remains In Progress|awaits independent review)|C4C-05/COM-C4C remain In Progress' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C4C-05/COM-C4C as pending review/CI/merge" >&2
  exit 1
fi

if grep -Eq 'COM-C5 (is )?(In Progress|entered|Done)|owner explicitly entered COM-C5' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md; then
  echo "C4C-05 closeout must not enter COM-C5 automatically" >&2
  exit 1
fi

if ! grep -Fq 'isGuidanceEnabled: false' \
    MindBudget/Services/ReceiptRecognition/ReceiptSystemImageAcquisition.swift; then
  echo "C4C-05 option A must keep DataScanner system guidance disabled under the custom frame" >&2
  exit 1
fi

if grep -Eq 'DataScannerViewControllerDelegate|VNDetectRectanglesRequest' \
    MindBudget/Features/AddExpense/ReceiptCaptureOverlay.swift \
    MindBudget/Features/AddExpense/ReceiptImportView.swift \
    MindBudget/Services/ReceiptRecognition/ReceiptSystemImageAcquisition.swift; then
  echo "C4C-05 option A must not add an unreviewed live rectangle/frame-detection pipeline" >&2
  exit 1
fi

if grep -Fq 'receipt.camera.guide.aligned' \
    MindBudget/Features/AddExpense/ReceiptCaptureOverlay.swift \
    MindBudget/Features/AddExpense/ReceiptImportView.swift; then
  echo "C4C-05 option A must not present an unsupported aligned camera state" >&2
  exit 1
fi

if grep -Eq 'C4C-05 (remains |is )?blocked|awaiting explicit owner entry for C4C-05|Blocked pending explicit owner entry after C4C-04' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes C4C-05 as blocked after owner entry" >&2
  exit 1
fi

if grep -Eq 'Physical DataScanner capture, PHPicker selection, and resulting local OCR remain|physical acquisition/OCR evidence.*pending' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4C_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Current commercialization state still describes completed C4C-05 physical evidence as pending" >&2
  exit 1
fi

if grep -Eq 'createExpense|updateExpense|ModelContext|URLSession' \
    MindBudget/Features/AddExpense/ReceiptImportView.swift; then
  echo "C4C-05 receipt review must not persist directly or gain a network channel" >&2
  exit 1
fi

SOURCE_SHA="$(
  sed -n 's/^- SHA-256: `\([0-9a-f][0-9a-f]*\)`.*/\1/p' "${SOURCE_PROVENANCE}" |
    head -n 1
)"
if [[ ! "${SOURCE_SHA}" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Commercial source provenance must contain one valid SHA-256 fingerprint" >&2
  exit 1
fi

grep -Fq 'it is not a claim that CI can read or automatically detect changes' \
  "${SOURCE_PROVENANCE}" || {
  echo "Commercial source provenance must state the external-drift limitation" >&2
  exit 1
}

for file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md; do
  grep -Fq "${SOURCE_SHA}" "${file}" || {
    echo "Commercial source snapshot fingerprint is missing from ${file}" >&2
    exit 1
  }
done

requirement_ids=(
  REQ-R1-NET-001
  REQ-R1-TELEMETRY-001
  REQ-ENTITLEMENT-001
  REQ-STOREKIT-STATE-001
  REQ-STOREKIT-LIFECYCLE-001
  REQ-MONEY-001
  REQ-MONEY-MIGRATION-001
  REQ-RECEIPT-PIPELINE-001
  REQ-RECEIPT-PRIVACY-001
  REQ-ICLOUD-001
  REQ-CLOUD-AUTH-001
  REQ-CLOUD-CONSENT-001
  REQ-CLOUD-USAGE-001
  REQ-G1-001
  REQ-WATCH-SCOPE-001
  REQ-WATCH-SYNC-001
  REQ-WATCH-ENTITLEMENT-001
  REQ-WATCH-PRIVACY-001
)

for requirement_id in "${requirement_ids[@]}"; do
  grep -Fq "| ${requirement_id} |" Docs/Commercialization/REQUIREMENTS_INDEX.md || {
    echo "Missing commercialization Requirement ID: ${requirement_id}" >&2
    exit 1
  }
done

contains_open_p0() {
  awk '
  {
    line = tolower($0)
    has_p0 = line ~ /(^|[^[:alnum:]_])p0([^[:alnum:]_]|$)/
    has_open = line ~ /(^|[^[:alnum:]_])open([^[:alnum:]_]|$)/
    if (index(line, "priority/status:") && has_p0 && has_open) {
      found = 1
    }
  }
  END { exit found ? 0 : 1 }
  ' "$@"
}

if ! contains_open_p0 <<< '- Priority/status: **Open (P0)**'; then
  echo "Commercial conflict gate no longer detects order-independent Open P0 status" >&2
  exit 1
fi
if contains_open_p0 <<< '- Priority/status: **P1 — Open**'; then
  echo "Commercial conflict gate incorrectly classifies non-P0 status" >&2
  exit 1
fi
if contains_open_p0 <<< '- Priority/status: **Open-ended P01 review**'; then
  echo "Commercial conflict gate must token-match both Open and P0" >&2
  exit 1
fi

if contains_open_p0 Docs/Commercialization/SPEC_CONFLICTS.md; then
  echo "An unresolved P0 commercialization specification conflict remains" >&2
  exit 1
fi

entitlement_row="$(grep -F '| REQ-ENTITLEMENT-001 |' Docs/Commercialization/REQUIREMENTS_INDEX.md)"
if [[ "${entitlement_row}" != *'Active'* || "${entitlement_row}" == *'BLOCKED_BY_SPEC'* ]]; then
  echo "REQ-ENTITLEMENT-001 is not ready for COM-C1" >&2
  exit 1
fi

for product_id in "${MONTHLY_PRODUCT_ID}" "${ANNUAL_PRODUCT_ID}"; do
  for file in Docs/Commercialization/DECISIONS.md Docs/Commercialization/STOREKIT_TEST_MATRIX.md; do
    grep -Fq "${product_id}" "${file}" || {
      echo "Accepted Product ID ${product_id} is missing from ${file}" >&2
      exit 1
    }
  done
done

grep -Fq 'current Release allow-list is empty' Docs/Commercialization/PROJECT_MEMORY.md || {
  echo "Current empty Release egress baseline is not recorded" >&2
  exit 1
}

grep -Fq 'Current app-owned HTTP(S) | Accepted empty set' \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md || {
  echo "Network policy must contain the accepted empty current allow-list" >&2
  exit 1
}

grep -Fq '**DEC-COM-104 accepts `DEFER_LUNA_CREDITS_KEEP_LOCAL_PRO`; G1 remains In Progress at' Docs/Commercialization/REGIONAL_PRICING.md || {
  echo "Regional pricing must distinguish the active local-only direction from deferred Luna/card planning" >&2
  exit 1
}

for c301_contract in \
  'US$1.99' \
  'US$19.99' \
  '7-day free trial for StoreKit-eligible subscribers' \
  'Hong Kong (HKG)' \
  'Taiwan (TWN)' \
  'zero automatic presentations'; do
  grep -Fq "${c301_contract}" Docs/Commercialization/COM_C3_EXECUTION_PACKET.md || {
    echo "COM-C3 execution packet is missing C3-01 contract: ${c301_contract}" >&2
    exit 1
  }
done

grep -Fq 'actions/runs/31766128587' Docs/Commercialization/CI_BASELINE.md || {
  echo "C3-01 green-CI run is missing from CI baseline" >&2
  exit 1
}

for c302_contract in \
  'verified current transaction must identify an introductory free trial' \
  'actual `renewalDate` and `willAutoRenew` facts' \
  'current trial product' \
  'next-renewal product' \
  '`autoRenewPreference`' \
  'five calendar days' \
  'never requests permission' \
  'Remove the old request before adding a replacement' \
  'trial ends soon' \
  'never promises renewal' \
  'no date, price, amount, product, or remaining-day count' \
  'DEC-COM-020'; do
  if ! grep -Fq "${c302_contract}" \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/STOREKIT_TEST_MATRIX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C3-02 trial-lifecycle contract is missing: ${c302_contract}" >&2
    exit 1
  fi
done

grep -Fq 'actions/runs/31803898776' Docs/Commercialization/CI_BASELINE.md || {
  echo "C3-02 green-CI run is missing from CI baseline" >&2
  exit 1
}

grep -Fq '`12d9217`' Docs/Commercialization/CI_BASELINE.md || {
  echo "C3-02 merge SHA is missing from CI baseline" >&2
  exit 1
}

if grep -Fq 'C3-01 implementation complete pending independent review' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C3-01 as pending review" >&2
  exit 1
fi

if grep -Fq 'C3-02 implementation complete pending' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C3-02 as pending review" >&2
  exit 1
fi

for c303_contract in \
  'Status: **Accepted by the owner for COM-C3-03 on 2026-08-14.**' \
  'mindbudget-public-config-dev.yehao1105.workers.dev' \
  'mindbudget-public-config-staging.yehao1105.workers.dev' \
  'mindbudget-public-config.yehao1105.workers.dev' \
  'anonymous `GET /v1/config`' \
  '"algorithm": "Ed25519"' \
  '`proValueTriggersEnabled` is the only v1 presentation field' \
  '`yyyy-MM-dd'\''T'\''HH:mm:ss'\''Z'\''`' \
  'without duplicate object keys' \
  'no longer than seven 24-hour intervals' \
  'same-version equivocation is rejected' \
  'sticky Release fail-closed' \
  'closed `transport.*` and `resolution.*` reason codes' \
  'DEC-COM-021'; do
  if ! grep -Fq "${c303_contract}" \
      Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C3-03 signed public-configuration contract is missing: ${c303_contract}" >&2
    exit 1
  fi
done

for c303_task_evidence in 'PR #36 (`1ebb36c`)' 'PR #38 (`db7926d`)'; do
  grep -Fq "${c303_task_evidence}" Docs/COMMERCIALIZATION_TASKS.md || {
    echo "COM-C3 task state must retain reviewed C3-03 evidence: ${c303_task_evidence}" >&2
    exit 1
  }
done

grep -Fq 'Signed public configuration | C3-03 Done through PR #38 (`db7926d`); Development deployed and verified; Staging/Production undeployed; no distribution authorization' \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md || {
  echo "Network policy must record completed C3-03 without implying Production deployment or distribution" >&2
  exit 1
}

for c303_completion in \
  'GitHub Actions run `31856271268`' \
  'merged through PR #36 as `1ebb36c`' \
  'C3-03A is Done' \
  'GitHub Actions run `31873664396`' \
  'PR #38' \
  '`db7926d`' \
  'C3-03 is Done'; do
  if ! grep -Fq "${c303_completion}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md; then
    echo "C3-03A closeout evidence is missing: ${c303_completion}" >&2
    exit 1
  fi
done

# These phrases are deliberate cross-file contract anchors, not incidental prose. If C3-04's
# accepted presentation/release boundary changes, update the owning decision and every anchor in
# the same reviewed change instead of weakening this check.
for c304_contract in \
  'C3-04 and COM-C3 are Done' \
  'PR #40' \
  '`9448ca9`' \
  '`31918968478`' \
  'one non-blocking Dashboard navigation card' \
  'Billing grace retains Pro' \
  'Billing retry, expiry, and revocation' \
  'AX5' \
  'Staging/Production'; do
  if ! grep -Fq "${c304_contract}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/STOREKIT_TEST_MATRIX.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/RELEASE_CHECKLIST.md; then
    echo "C3-04 implementation/release contract is missing: ${c304_contract}" >&2
    exit 1
  fi
done

for c303b_evidence in \
  'bf6c5049-a389-4ea7-af0a-e8425b8957e2' \
  '8 passed, 0 failed, 0 skipped' \
  'Worker tests passed 13/13' \
  'Staging and Production were not deployed' \
  'closed non-content reason codes' \
  'no private key, storage, outbound fetch'; do
  if ! grep -Fq "${c303b_evidence}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/COM_C3_EXECUTION_PACKET.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C3-03B implementation evidence is missing: ${c303b_evidence}" >&2
    exit 1
  fi
done

if grep -Eq 'C3-03B (is )?In Progress with no transport yet|C3-03B In Progress, transport not yet implemented|future C3-03B contract' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
    Docs/Commercialization/PUBLIC_CONFIGURATION_CONTRACT.md; then
  echo "Current commercialization state still describes C3-03B transport as unimplemented" >&2
  exit 1
fi

if grep -Fq 'C3-03 has not started and remains blocked' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C3-03 as not started" >&2
  exit 1
fi

for heading in '## Input gate' '### Tasks' '### Tests' '### Stop conditions'; do
  grep -Fq "${heading}" Docs/Commercialization/COM_C1_EXECUTION_PACKET.md || {
    echo "COM-C1 execution packet is missing ${heading}" >&2
    exit 1
  }
done

for access_boundary_contract in \
  'No feature-access or application path reads `version1Bits` or `version1KnownBits`' \
  'Never use `isSuperset(of: .free)`' \
  'Subscription checks exist only in the central access service'; do
  grep -Fq "${access_boundary_contract}" Docs/Commercialization/COM_C1_EXECUTION_PACKET.md || {
    echo "COM-C1 execution packet is missing access-boundary review contract: ${access_boundary_contract}" >&2
    exit 1
  }
done

grep -Fq '## COM-C1 — Entitlement model and Feature Access' Docs/COMMERCIALIZATION_TASKS.md || {
  echo "COM-C1 task section is missing" >&2
  exit 1
}

for c4a01_contract in \
  'The V1–V4 store does not contain a floating-point money representation that needs conversion.' \
  'complete 15-table `ModelCounts` inventory' \
  'no anomaly becomes zero' \
  '`Merchant.totalMinorUnitsAllTime` currency ownership explicit' \
  'idempotent journal transitions' \
  'undocumented persistent-store metadata' \
  'normal cold start never copies the store' \
  'USD, JPY, and KWD' \
  'C4A-03 is Done through PR #55' \
  '32406654986' \
  '77292c6' \
  'DEC-COM-025'; do
  if ! grep -Fqi "${c4a01_contract}" \
      Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md; then
    echo "COM-C4A-01 delta/recovery contract is missing: ${c4a01_contract}" >&2
    exit 1
  fi
done

if grep -Fq 'C4A-03 implementation is complete pending independent review' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/CI_BASELINE.md \
    Docs/Commercialization/COM_C4A_EXECUTION_PACKET.md; then
  echo "Current COM-C4A state still describes C4A-03 as pending review" >&2
  exit 1
fi

for c4b02_closeout_anchor in \
  'C4B-02 is Done through PR #59' \
  '32490174014' \
  '211dff2'; do
  if ! grep -Fq "${c4b02_closeout_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
      Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/DECISIONS.md; then
    echo "C4B-02 reviewed merge closeout evidence is missing: ${c4b02_closeout_anchor}" >&2
    exit 1
  fi
done

for c4b03_entry_anchor in \
  'C4B-03 remains In Progress' \
  '32494429474' \
  '7138a9c' \
  'DEC-COM-032'; do
  if ! grep -Fq "${c4b03_entry_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
      Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/DECISIONS.md; then
    echo "C4B-03 formal-entry evidence is missing: ${c4b03_entry_anchor}" >&2
    exit 1
  fi
done

# PR #64 closes the reviewed C4B runtime correction. DEC-COM-043 closes C4B's evidence scope
# without turning any physical waiver into a pass or weakening the later release gates.
for c4b03_product_merge_anchor in \
  'f49de94' \
  '32571676058' \
  '0f749ce' \
  '0350415' \
  '32573992659' \
  '0128682' \
  '7b23490' \
  '32576885537' \
  '1a14df9' \
  'f1f37db' \
  '32726507493' \
  '4f6d7fe' \
  'C4B-03 and COM-C4B are Done' \
  'COM-C4B is Done' \
  'permanently waive' \
  'not a pass' \
  'DEC-COM-039' \
  'DEC-COM-043'; do
  if ! grep -Fq "${c4b03_product_merge_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
      Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/DECISIONS.md; then
    echo "C4B-03 reviewed merge/permanent evidence waiver is missing: ${c4b03_product_merge_anchor}" >&2
    exit 1
  fi
done

for c4b03_closeout_anchor in \
  'physical account-switch/offline/quota observations' \
  'not passed' \
  'Distribution signing' \
  'Production schema/deployment/release' \
  'COM-C6/COM-C12' \
  'C4C is unblocked'; do
  if ! grep -Fq "${c4b03_closeout_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
      Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
      Docs/Commercialization/DECISIONS.md; then
    echo "C4B-03 final evidence/release disposition is missing: ${c4b03_closeout_anchor}" >&2
    exit 1
  fi
done

for stale_c4b03_waiver_phrase in \
  'temporarily deferred a same-account' \
  'not a pass, permanent waiver' \
  'not counted as a pass or permanent waiver' \
  'not a convergence pass or permanent waiver' \
  'owner-deferred same-account' \
  'no multi-device result or permanent waiver' \
  'temporarily deferred, not passed or permanently waived' \
  'temporary evidence deferral'; do
  if grep -Fq "${stale_c4b03_waiver_phrase}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
      Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "Current C4B-03 state still describes the same-account physical gate as temporary: ${stale_c4b03_waiver_phrase}" >&2
    exit 1
  fi
done

if grep -Eq 'rereview and (the )?current-head CI remain|rereview and the current head.s hosted CI remain|Physical multi-device/account/quota/offline/push, Production deployment, distribution signing, review, hosted CI, and merge remain open|review, hosted CI, and merge remain pending' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
    Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current COM-C4B state still describes the merged PR #61 product head as pending review/CI/merge" >&2
  exit 1
fi

for c4b03_local_evidence_anchor in \
  'DEC-COM-033' \
  '/private/tmp/MindBudget-C4B03-Full1.xcresult' \
  '456/456 unit tests' \
  '17/17 UI tests'; do
  if ! grep -Fq "${c4b03_local_evidence_anchor}" \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/SESSION_LOG.md; then
    echo "C4B-03 local validation evidence is missing: ${c4b03_local_evidence_anchor}" >&2
    exit 1
  fi
done

for c4b03_background_anchor in \
  'MindBudget/Resources/MindBudgetInfo.plist' \
  'UIBackgroundModes = [remote-notification]' \
  'automaticallySync = true' \
  'DEC-COM-040' \
  'DEC-COM-041' \
  'DEC-COM-042' \
  '/private/tmp/MindBudget-C4B03-AutomaticSync-Focused1.xcresult' \
  '/private/tmp/MindBudget-C4B03-AutomaticSync-Physical2.xcresult' \
  '/private/tmp/MindBudget-C4B03-AutomaticSync-Focused6.xcresult' \
  'MindBudget-C4B03-BackgroundPush14.xcresult' \
  'zero physical background-push passes' \
  'not passed'; do
  if ! grep -Fq "${c4b03_background_anchor}" \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/SESSION_LOG.md; then
    echo "C4B-03 background-delivery evidence is missing: ${c4b03_background_anchor}" >&2
    exit 1
  fi
done

# DEC-COM-042 permanently removes only the physical background-push observation from exit
# evidence. Current-state documents must not drift back to describing it as open or passed; the
# source/deterministic boundary remains mandatory, while DEC-COM-043 separately owns final
# account/offline/quota and release-gate disposition.
for stale_c4b03_background_phrase in \
  'physical background-push observation remains open' \
  'silent-push evidence remains open' \
  'Real background-push evidence is still open' \
  'Real background-push delivery is not yet proven' \
  'account/offline/quota/background-push' \
  'offline/quota/account/push'; do
  if grep -Fq "${stale_c4b03_background_phrase}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
      Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "Current C4B-03 state still describes permanently waived physical background-push evidence as open: ${stale_c4b03_background_phrase}" >&2
    exit 1
  fi
done

for c4b03_physical_anchor in \
  'DEC-COM-034' \
  '/private/tmp/MindBudget-C4B03-PhysicalCloudKit4.xcresult' \
  'All 33 tests passed' \
  '9.358 seconds' \
  'MINDBUDGET_PHYSICAL_CLOUDKIT_TESTS'; do
  if ! grep -Fq "${c4b03_physical_anchor}" \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/SESSION_LOG.md; then
    echo "C4B-03 physical Development evidence is missing: ${c4b03_physical_anchor}" >&2
    exit 1
  fi
done

for c4b03_dashboard_anchor in \
  '/private/tmp/MindBudget-C4B03-PostPhysical-Sim.xcresult' \
  '/private/tmp/MindBudget-C4B03-Dashboard-Development-Envelope.png' \
  '/private/tmp/MindBudget-C4B03-Dashboard-Production-NoTypes.png' \
  'MindBudgetEnvelopeV1' \
  'ENCRYPTED BYTES' \
  'Deploy Schema Changes'; do
  if ! grep -Fq "${c4b03_dashboard_anchor}" \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/SESSION_LOG.md; then
    echo "C4B-03 Dashboard/read-back evidence is missing: ${c4b03_dashboard_anchor}" >&2
    exit 1
  fi
done

for c4b03_final_validation_anchor in \
  'DEC-COM-035' \
  '/private/tmp/MindBudget-C4B03-FinalWithoutWallClock.xcresult' \
  '/private/tmp/MindBudget-C4B03-PseudoLong-Isolated.xcresult' \
  '/private/tmp/MindBudget-C4B03-LineageBound.xcresult' \
  'incomplete result directory and is **not** accepted as a green bundle' \
  'passed 1/1 in 23.625 seconds' \
  '33 deterministic'; do
  if ! grep -Fq "${c4b03_final_validation_anchor}" \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/SESSION_LOG.md; then
    echo "C4B-03 final-validation disposition is missing: ${c4b03_final_validation_anchor}" >&2
    exit 1
  fi
done

if grep -Eq 'C4B-03 (remains )?blocked pending (this )?(documentation )?closeout|C4B-03 blocked pending closeout' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
    Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
    Docs/Commercialization/CI_BASELINE.md; then
  echo "Current COM-C4B state still describes C4B-03 as blocked by the merged closeout" >&2
  exit 1
fi

if grep -Eq 'C4B-02 implementation (is )?complete pending independent review|C4B-02 remains pending (final re-review|independent review)|Final re-review, hosted CI, and merge remain required' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C4B_EXECUTION_PACKET.md \
    Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
    Docs/Commercialization/CI_BASELINE.md; then
  echo "Current COM-C4B state still describes C4B-02 as pending review/merge" >&2
  exit 1
fi

for c4a_release_anchor in '0.9.8 (9)' 'dda1eb09-5d8b-43c6-a2fd-ea910fa422ac'; do
  if ! grep -Fq "${c4a_release_anchor}" \
      Docs/TASKS.md Docs/PROJECT_MEMORY.md Docs/Commercialization/PROJECT_MEMORY.md; then
    echo "Current release calibration is missing: ${c4a_release_anchor}" >&2
    exit 1
  fi
done

for c203_contract in \
  'single `EntitlementStore` lifecycle authority' \
  'one lifecycle task supervises both `Transaction.updates` and `Product.SubscriptionInfo.Status.updates`' \
  'status signal triggers a fresh full reconciliation' \
  'publish-before-`Transaction.finish()`' \
  'failed finish remains unfinished' \
  'post-0.9.6 release hold remains active'; do
  if ! grep -Fq "${c203_contract}" \
      Docs/Commercialization/COM_C2_EXECUTION_PACKET.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/CI_BASELINE.md; then
    echo "C2-03 merged lifecycle/release contract is missing: ${c203_contract}" >&2
    exit 1
  fi
done

for c204_contract in \
  'separately verified `AppTransaction` bundle/environment' \
  'TestFlight is modeled as verified Sandbox' \
  'cross-environment/bundle mismatch rejection' \
  'DEC-COM-018' \
  '49/49 focused' \
  '359 total, 355 passed, 4 skipped, and 0 failed' \
  'C2-04 and COM-C2 are Done'; do
  if ! grep -Fq "${c204_contract}" \
      Docs/Commercialization/COM_C2_EXECUTION_PACKET.md \
      Docs/Commercialization/STOREKIT_TEST_MATRIX.md \
      Docs/Commercialization/CI_BASELINE.md \
      Docs/Commercialization/DECISIONS.md; then
    echo "C2-04 environment/release contract is missing: ${c204_contract}" >&2
    exit 1
  fi
done

grep -Fq '`a293762`' Docs/Commercialization/CI_BASELINE.md || {
  echo "C2-04 green-CI merge evidence is missing from CI baseline" >&2
  exit 1
}

grep -Fq 'actions/runs/31701374466' Docs/Commercialization/CI_BASELINE.md || {
  echo "C2-04 green-CI run is missing from CI baseline" >&2
  exit 1
}

grep -Fq '`3fc72b4`' Docs/Commercialization/CI_BASELINE.md || {
  echo "C2-03 green-CI merge evidence is missing from CI baseline" >&2
  exit 1
}

grep -Fq 'actions/runs/31675470258' Docs/Commercialization/CI_BASELINE.md || {
  echo "C2-03 green-CI run is missing from CI baseline" >&2
  exit 1
}

for storekit_api in \
  '`Product.SubscriptionInfo.Status.updates`' \
  '`Product.SubscriptionInfo.status(for:)`' \
  '`Transaction.unfinished`' \
  '`Product.purchase()`' \
  '`AppStore.sync()`' \
  '`Transaction.finish()`'; do
  grep -Fq "${storekit_api}" Docs/Commercialization/NETWORK_EGRESS_POLICY.md || {
    echo "C2-03 Apple-managed StoreKit API is missing from the egress policy: ${storekit_api}" >&2
    exit 1
  }
done

for evidence in \
  'final Xcode 26.6 `17F113`' \
  'iOS 26.6.1 `23G82`' \
  '5 passed, 0 failed, 0 skipped' \
  'both the CHN and USA `Product.products(for:)` probes passed' \
  '/private/tmp/MindBudget-C2-03-Physical-Unlocked-iOS26.6.1-17F113.xcresult'; do
  grep -Fq "${evidence}" Docs/Commercialization/COM_C2_EXECUTION_PACKET.md || {
    echo "COM-C2 execution packet is missing accepted C2-03 entry evidence: ${evidence}" >&2
    exit 1
  }
done

grep -Fq '| Xcode 26.6 final `17F113`, physical `iPhone Air`, final iOS 26.6.1 `23G82` | 5 passed, 0 failed, 0 skipped; CHN Passed; USA Passed | Accepted supported-final physical-device evidence; C2-03 entry gate passed |' \
  Docs/Commercialization/STOREKIT_TEST_MATRIX.md || {
  echo "StoreKit test matrix is missing the accepted C2-03 physical-device evidence" >&2
  exit 1
}

if grep -Fq 'No runtime-probe pass is claimed.' Docs/Commercialization/PROJECT_MEMORY.md; then
  echo "Commercial project memory still contains the superseded pre-C2-03 probe status" >&2
  exit 1
fi

for heading in \
  '## Input gate' \
  '## C2-01 — StoreKit test catalog' \
  '## C2-02 — Runtime catalog and entitlement store' \
  '## C2-03 — Purchase, restore, and status mapping' \
  '## C2-04 — Environment and regression gate'; do
  grep -Fq "${heading}" Docs/Commercialization/COM_C2_EXECUTION_PACKET.md || {
    echo "COM-C2 execution packet is missing ${heading}" >&2
    exit 1
  }
done

if grep -Eq 'all ten (SwiftData|model)|ten SwiftData|all ten model' \
  Docs/PRIVACY_AND_REVIEW_NOTES.md Docs/PROJECT_MEMORY.md Docs/TEST_PLAN.md; then
  echo "Current deletion documentation still contains the stale ten-model count" >&2
  exit 1
fi

grep -Fq 'budget-plan-semantics' Docs/PRIVACY_AND_REVIEW_NOTES.md || {
  echo "Current deletion documentation is missing the BudgetPlanSemantics table" >&2
  exit 1
}

if grep -Eq 'SPEC-015 (open|remains open)' \
  Docs/Commercialization/PROJECT_MEMORY.md Docs/Commercialization/REQUIREMENTS_INDEX.md; then
  echo "Commercial memory still describes accepted SPEC-015 as open" >&2
  exit 1
fi

for c501_review_anchor in \
  'DEC-COM-057' \
  '.deletedLocallyWithoutRemoteProofs' \
  'ordinary upload envelopes' \
  'must not persist, log, or reuse' \
  'in-flight opt-out cancellation' \
  'four-generation re-enable' \
  '17/17'; do
  if ! grep -Fq "${c501_review_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C5-01 review-remediation contract is missing: ${c501_review_anchor}" >&2
    exit 1
  fi
done

for c501_final_review_anchor in \
  'DEC-COM-058' \
  'repeated Disable' \
  'Calendar.autoupdatingCurrent' \
  '.persistenceFailed' \
  'idempotent event acceptance' \
  'proof deletion' \
  '21/21'; do
  if ! grep -Fq "${c501_final_review_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C5-01 final review-remediation contract is missing: ${c501_final_review_anchor}" >&2
    exit 1
  fi
done

# C5-01 closes only on the independently reviewed exact head, its green hosted run, and PR #76
# merge. Require the exact provenance in every current-state/evidence document; this closeout must
# leave the client dormant. C5-02 was later entered separately under DEC-COM-060.
c501_closeout_files=(
  Docs/COMMERCIALIZATION_TASKS.md
  Docs/TASKS.md
  Docs/PROJECT_MEMORY.md
  Docs/Commercialization/PROJECT_MEMORY.md
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md
  Docs/Commercialization/REQUIREMENTS_INDEX.md
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md
  Docs/Commercialization/CI_BASELINE.md
)

for c501_closeout_file in "${c501_closeout_files[@]}"; do
  for c501_provenance_anchor in 'd937dc8' '33085630481' '68304ad'; do
    if ! grep -Fq "${c501_provenance_anchor}" "${c501_closeout_file}"; then
      echo "C5-01 provenance is missing ${c501_provenance_anchor} in ${c501_closeout_file}" >&2
      exit 1
    fi
  done
done

grep -Fq 'DEC-COM-059' Docs/Commercialization/DECISIONS.md || {
  echo "C5-01 reviewed merge closeout is missing DEC-COM-059" >&2
  exit 1
}

if grep -Eq 'C5-01 (implementation (is )?complete pending (independent )?review|remains In Progress|awaits independent review)|C5-01/C5-02 remain blocked|C5-02 through C5-04 remain blocked' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C5-01 as pending or C5-02 as dependency-blocked" >&2
  exit 1
fi

grep -Fq 'Status: **Done after independent review of exact head `72abf4b`, green GitHub Actions run' \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md || {
  echo "C5-02 Done status must retain the reviewed exact head" >&2
  exit 1
}

grep -Fq '`33176551566`, and PR #78 merge `4715054`.**' \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md || {
  echo "C5-02 Done status must retain green CI and merge provenance" >&2
  exit 1
}

grep -Fq 'Status: **Done after pre-merge review of head `4ea7cd9`, post-merge PR #81 verification of' \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md || {
  echo "C5-03 Done status must retain the accurate pre/post-merge review boundary" >&2
  exit 1
}

grep -Fq 'remediation head `0c61427`, green GitHub Actions run `33211270363`, and PR #80 merge `a587f42`.**' \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md || {
  echo "C5-03 Done status must retain green CI and merge provenance" >&2
  exit 1
}

grep -Fq 'Status: **Done after independent review of exact PR #84 head `84a96bc`, green GitHub Actions run' \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md || {
  echo "C5-04/COM-C5 must retain the reviewed PR #84 Done status" >&2
  exit 1
}

grep -Fq '`33247176815`, and PR #84 merge `4194b73`.**' \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md || {
  echo "C5-04/COM-C5 Done status must retain green CI and merge provenance" >&2
  exit 1
}

for c502_contract_anchor in \
  'DEC-COM-060' \
  'mindbudget-telemetry-dev.yehao1105.workers.dev' \
  'mindbudget-telemetry-staging.yehao1105.workers.dev' \
  'mindbudget-telemetry.yehao1105.workers.dev' \
  '1c162a57-8789-4f7f-9fec-f2c484e9f4f2' \
  '0 event rows' \
  '0 identity rows' \
  '2 independent tombstones' \
  'Production has no provisioned D1' \
  'owner entered C5-03'; do
  if ! grep -Fq "${c502_contract_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C5-02 implementation contract is missing: ${c502_contract_anchor}" >&2
    exit 1
  fi
done

for c503_contract_anchor in \
  'DEC-COM-063' \
  'DEC-COM-064' \
  'c5-03-v1' \
  'wilson_score_95_outward_rounded_basis_points' \
  'widestConfidenceIntervalBasisPoints' \
  'no cross-segment roll-up' \
  'source_suppressed' \
  'zero_denominator' \
  'not_collected' \
  'pseudonym generation' \
  'no real evidence bundle or G1 decision'; do
  if ! grep -Fq "${c503_contract_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
      Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C5-03 metrics evidence contract is missing: ${c503_contract_anchor}" >&2
    exit 1
  fi
done

for c502_review_remediation_anchor in \
  'DEC-COM-061' \
  'UTC-day expiration bucket' \
  'User-Agent: MindBudget' \
  'it predates DEC-COM-061 and is not current-source probe evidence' \
  'repeats those bounded transactions until no expired batch remains' \
  'terminal/non-retrying'; do
  if ! grep -Fq "${c502_review_remediation_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/DECISIONS.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C5-02 review remediation contract is missing: ${c502_review_remediation_anchor}" >&2
    exit 1
  fi
done

# C5-02 closes only on the independently reviewed remediation head, its successful hosted run,
# and PR #78 merge. Require every current-state/evidence document to retain those exact facts;
# neither this closeout nor C5-02 itself enters C5-03 or enables telemetry capture.
c502_closeout_files=(
  Docs/COMMERCIALIZATION_TASKS.md
  Docs/TASKS.md
  Docs/PROJECT_MEMORY.md
  Docs/PRIVACY_AND_REVIEW_NOTES.md
  Docs/Commercialization/PROJECT_MEMORY.md
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md
  Docs/Commercialization/REQUIREMENTS_INDEX.md
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md
  Docs/Commercialization/CI_BASELINE.md
)

for c502_closeout_file in "${c502_closeout_files[@]}"; do
  for c502_provenance_anchor in '72abf4b' '33176551566' '4715054'; do
    if ! grep -Fq "${c502_provenance_anchor}" "${c502_closeout_file}"; then
      echo "C5-02 provenance is missing ${c502_provenance_anchor} in ${c502_closeout_file}" >&2
      exit 1
    fi
  done
done

grep -Fq 'DEC-COM-062' Docs/Commercialization/DECISIONS.md || {
  echo "C5-02 reviewed merge closeout is missing DEC-COM-062" >&2
  exit 1
}

if grep -Eq 'C5-02 (implementation (is )?complete pending|implementation pending review/CI/merge|remains pending (re)?review)|C5-03/C5-04 remain blocked|Status: \*\*Blocked by C5-02\.\*\*' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C5-02 as pending or C5-03 as blocked by C5-02" >&2
  exit 1
fi

if grep -Eq 'C5-02 awaits (a )?(separate )?explicit owner entry|C5-02 must remain blocked pending separate explicit owner entry' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C5-02 as awaiting owner entry" >&2
  exit 1
fi

if grep -Eq 'C5-03 (awaits|still requires) (a )?(separate )?explicit owner entry|Status: \*\*Blocked pending explicit owner entry after C5-02 closeout\.\*\*' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C5-03 as awaiting owner entry" >&2
  exit 1
fi

# C5-03's pre-merge review covered 4ea7cd9. The 0c61427 remediation passed hosted CI and merged
# without a pre-merge rereview; PR #81's closeout review then verified that exact delta. Require
# every current-state/evidence document to retain that accurate chronology. C5-04 has since been
# entered, so its current state is guarded separately below rather than frozen into this closeout.
c503_closeout_files=(
  Docs/COMMERCIALIZATION_TASKS.md
  Docs/TASKS.md
  Docs/PROJECT_MEMORY.md
  Docs/PRIVACY_AND_REVIEW_NOTES.md
  Docs/Commercialization/PROJECT_MEMORY.md
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md
  Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md
  Docs/Commercialization/REQUIREMENTS_INDEX.md
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md
  Docs/Commercialization/CI_BASELINE.md
)

for c503_closeout_file in "${c503_closeout_files[@]}"; do
  for c503_provenance_anchor in '4ea7cd9' '0c61427' '33211270363' 'a587f42' 'PR #81'; do
    if ! grep -Fq "${c503_provenance_anchor}" "${c503_closeout_file}"; then
      echo "C5-03 provenance is missing ${c503_provenance_anchor} in ${c503_closeout_file}" >&2
      exit 1
    fi
  done
done

grep -Fq 'DEC-COM-065' Docs/Commercialization/DECISIONS.md || {
  echo "C5-03 reviewed merge closeout is missing DEC-COM-065" >&2
  exit 1
}

# Phase Status lines are already parsed with their heading by commercialization_phase_states.py;
# keep this prose scan phase-qualified so a future C5-04 pending-review Status cannot be mistaken
# for stale C5-03 state.
if grep -Eq 'C5-03 (implementation (is )?complete pending|implementation pending review/CI/merge|remains pending (re)?review|awaits independent review)|Status: \*\*Blocked by C5-03\.\*\*' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C5-03 as pending review or C5-04 as blocked by C5-03" >&2
  exit 1
fi

if grep -Eq 'Independent review approved (exact )?(C5-03 )?(remediation )?head `0c61427`|Exact remediation head `0c61427` passed independent review|reviewed head `0c61427`' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
    Docs/Commercialization/CI_BASELINE.md; then
  echo "C5-03 provenance must not claim that 0c61427 received a pre-merge independent review" >&2
  exit 1
fi

if grep -Eq 'C5-04 awaits explicit owner entry|Status: \*\*Blocked pending explicit owner entry after C5-03 closeout\.\*\*' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C5-04 as awaiting owner entry" >&2
  exit 1
fi

grep -Fq 'DEC-COM-066' Docs/Commercialization/DECISIONS.md || {
  echo "C5-04 controlled activation decision is missing DEC-COM-066" >&2
  exit 1
}

grep -Fq 'DEC-COM-067' Docs/Commercialization/DECISIONS.md || {
  echo "C5-04 local-first Delete All remediation is missing DEC-COM-067" >&2
  exit 1
}

grep -Fq 'DEC-COM-068' Docs/Commercialization/DECISIONS.md || {
  echo "C5-04 reviewed product merge calibration is missing DEC-COM-068" >&2
  exit 1
}

# These are current-state documents, not append-only history. Require every one to retain the
# exact source/run/merge provenance so a partial closeout cannot imply that operational evidence,
# a different source revision, or review coverage beyond the declared scope was established.
for c504_merge_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
  Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
  Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
  Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  for c504_merge_anchor in '2c1cebe' '33233846430' '28d9eae'; do
    grep -Fq "${c504_merge_anchor}" "${c504_merge_file}" || {
      echo "C5-04 current-state file ${c504_merge_file} is missing reviewed merge evidence: ${c504_merge_anchor}" >&2
      exit 1
    }
  done
done

grep -Fq -- '- [x] Complete the Development-only current-source publish readiness, aggregate-only monitoring,' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "C5-04 current-source Development proof must remain a completed standalone work item" >&2
  exit 1
}

for c504_review_scope_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
  Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
  Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  grep -Eiq 'declared scope|scoped (independent )?review|scoped review' "${c504_review_scope_file}" || {
    echo "C5-04 current-state file ${c504_review_scope_file} is missing the PR #82 review-scope qualification" >&2
    exit 1
  }
done

if grep -Fq 'Independent review approved exact remediation head `2c1cebe`' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
    Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "C5-04 current-state documents must not expand PR #82 review beyond its declared scope" >&2
  exit 1
fi

# Keep this scan phase-qualified. Future phases are allowed to await their own review/CI/merge.
if grep -Ei 'C5-04 (implementation candidate|controlled activation candidate).*(pending|awaits).*(review|CI|merge)|C5-04.*(exact-head review|hosted CI|merge) remain(s)? open' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
    Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C5-04 review, hosted CI, or merge as open" >&2
  exit 1
fi

grep -Fq 'DEC-COM-069' Docs/Commercialization/DECISIONS.md || {
  echo "C5-04 current-source Development evidence decision is missing DEC-COM-069" >&2
  exit 1
}

grep -Fq 'DEC-COM-070' Docs/Commercialization/DECISIONS.md || {
  echo "C5-04 native transport and review-provenance decision is missing DEC-COM-070" >&2
  exit 1
}

grep -Fq 'DEC-COM-071' Docs/Commercialization/DECISIONS.md || {
  echo "C5-04/COM-C5 reviewed closeout decision is missing DEC-COM-071" >&2
  exit 1
}

# The operational proof is a real remote Development fact, so every current-state/evidence file
# must name both the exact deployed main source and the resulting Development Worker version.
# PR #84 closed review/CI/merge for C5-04 and COM-C5. The check below pins that exact chain without
# authorizing any later environment, G1, COM-C6 entry, distribution, or release.
for c504_development_evidence_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
  Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
  Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
  Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
  Docs/Commercialization/CI_BASELINE.md; do
  for c504_development_evidence_anchor in \
    'daea2d2' \
    'e6bbd3f' \
    '33242024609' \
    'becb020' \
    '84a96bc' \
    '33247176815' \
    '4194b73' \
    '003c66fa-a57c-4b6a-a8d7-3f75b14cc716'; do
    grep -Fq "${c504_development_evidence_anchor}" "${c504_development_evidence_file}" || {
      echo "C5-04 Development evidence is missing ${c504_development_evidence_anchor} in ${c504_development_evidence_file}" >&2
      exit 1
    }
  done
done

# PR #83's independent review stopped at daea2d2. e6bbd3f applied its findings and recorded an
# implementation-author inspection, but did not receive a pre-merge rereview. Keep that chronology
# distinct from PR #84's separate live-transport evidence.
if grep -Eqi 'PR #83.? supplemental review|supplemental-review head.*e6bbd3f|its supplemental review covered' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
    Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current C5-04 documents still misattribute e6bbd3f as an independent PR #83 rereview" >&2
  exit 1
fi

for c504_native_transport_file in \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
  Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
  Docs/Commercialization/CI_BASELINE.md; do
  for c504_native_transport_anchor in \
    'FixedTelemetryTransport' \
    'URLSession' \
    '0 events' \
    '0 identities' \
    '3 tombstones'; do
    grep -Fq "${c504_native_transport_anchor}" "${c504_native_transport_file}" || {
      echo "C5-04 native transport evidence is missing ${c504_native_transport_anchor} in ${c504_native_transport_file}" >&2
      exit 1
    }
  done
done

grep -Fq 'runtimeStopDoesNotInvalidateExplicitTelemetryDeletionRetry' \
  Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md || {
  echo "C5-04 runbook must retain executable stop-then-delete retry evidence" >&2
  exit 1
}

for c504_probe_detail_file in \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
  Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
  Docs/Commercialization/CI_BASELINE.md; do
  grep -Fq '7776000000' "${c504_probe_detail_file}" || {
    echo "C5-04 Development TTL evidence is missing from ${c504_probe_detail_file}" >&2
    exit 1
  }
done

if grep -Eqi 'current-source Development operational proof is still open|current-source Development deployment/probe remains open|current-source deployment/probe.*remain(s)? open|The C5-04 source has not yet been deployed or probed|only an earlier Development Worker/D1 version is deployed/probed|No current-source deployment/probe' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
    Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes the completed Development proof as open" >&2
  exit 1
fi

for c504_contract_file in \
  Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
  Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md; do
  test -f "${c504_contract_file}" || {
    echo "C5-04 contract file is missing: ${c504_contract_file}" >&2
    exit 1
  }
done

for c504_contract_anchor in \
  'owner entered C5-04 on 2026-08-29' \
  'C5_TELEMETRY_CAPTURE_AUDIT.md' \
  'C5_TELEMETRY_OPERATIONS_RUNBOOK.md' \
  'sticky terminal' \
  'Product Interaction' \
  'Device ID' \
  'remote failure cannot block the local financial erase' \
  'current-source Development' \
  'Staging/Production'; do
  if ! grep -Fq "${c504_contract_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
      Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
      Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C5-04 controlled activation contract is missing: ${c504_contract_anchor}" >&2
    exit 1
  fi
done

for c504_closeout_file in \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
    Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
    Docs/Commercialization/CI_BASELINE.md; do
  for c504_closeout_anchor in '84a96bc' '33247176815' '4194b73'; do
    grep -Fq "${c504_closeout_anchor}" "${c504_closeout_file}" || {
      echo "C5-04/COM-C5 closeout is missing ${c504_closeout_anchor} in ${c504_closeout_file}" >&2
      exit 1
    }
  done
done

for c504_done_anchor in \
  'Status: **Done after independent review of exact PR #84 head `84a96bc`, green GitHub Actions run' \
  'Status: **Done after independent review of exact head `84a96bc`, green GitHub Actions run' \
  'C5-04 and COM-C5 are Done'; do
  if ! grep -Fq "${c504_done_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
      Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
      Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
      Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
    echo "C5-04/COM-C5 Done state is missing contract: ${c504_done_anchor}" >&2
    exit 1
  fi
done

if grep -Eqi 'C5-04 and COM-C5 remain In Progress|C5-04/COM-C5 remain In Progress|C5-04/COM-C5 stay In Progress|C5-04 remains In Progress pending|C5-04 evidence awaits independent review|C5-04 awaits independent review|until this operational evidence branch passes review|C5-04 and COM-C5 are not Done until this evidence branch|C5-04/COM-C5 remain pending independent' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md \
    Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
    Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state regressed C5-04/COM-C5 to pending review" >&2
  exit 1
fi

# C6-01 closed only after exact-head rereview, hosted CI, and merge. Pin that chain while keeping
# C6-02 behind a separate owner entry and preserving the reviewed runtime/static matrix anchors.
for c601_entry_anchor in \
  'owner explicitly entered COM-C6 on 2026-08-29' \
  'f77d2a6' \
  '33255898196' \
  '015d00e' \
  'DEC-COM-074' \
  'DEC-COM-075' \
  'remoteMutationAllowed' \
  'optionalNetworkFailuresCannotChangeTheInjectedLocalProSnapshot' \
  'DEC-COM-073' \
  '--verify-result-bundle' \
  'SPECIAL_CHECK_CLASSIFICATIONS'; do
  if ! grep -Fq -- "${c601_entry_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
      Docs/Commercialization/C6_RELEASE_MATRIX.json \
      Docs/Commercialization/DECISIONS.md \
      MindBudgetTests/CommercializationEntitlementTests.swift \
      Scripts/c6_release_matrix.py \
      Scripts/run-c6-release-matrix.sh; then
    echo "C6-01 entry/matrix contract is missing: ${c601_entry_anchor}" >&2
    exit 1
  fi
done

for c601_closeout_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  for c601_closeout_evidence in 'f77d2a6' '33255898196' '015d00e'; do
    grep -Fq "${c601_closeout_evidence}" "${c601_closeout_file}" || {
      echo "C6-01 closeout is missing ${c601_closeout_evidence} in ${c601_closeout_file}" >&2
      exit 1
    }
  done
done

if grep -Eqi 'C6-01 (is the (sole|only) active|still requires independent review|remains pending)|C6-01 review remediation is complete pending|C6-01[^.]*pending exact-head rereview|Blocked by C6-01 independent review' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state regressed C6-01 to pre-closeout review status" >&2
  exit 1
fi

if grep -Fq 'COM-C6 awaits explicit owner entry' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
    Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes COM-C6 as awaiting owner entry" >&2
  exit 1
fi

# C5's author-side supplemental inspection cannot become the only review of the checked-in source
# privacy declaration. Pin the exact surfaces to COM-C6 before any App Store Connect answer.
for com_c6_privacy_review_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
  Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md \
  Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/DECISIONS.md; do
  for com_c6_privacy_review_anchor in \
    'MindBudget/Resources/PrivacyInfo.xcprivacy' \
    'MindBudget/Services/TelemetryClient.swift' \
    'Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md'; do
    grep -Fq "${com_c6_privacy_review_anchor}" "${com_c6_privacy_review_file}" || {
      echo "COM-C6 source-privacy review is missing ${com_c6_privacy_review_anchor} in ${com_c6_privacy_review_file}" >&2
      exit 1
    }
  done
done

grep -Fq 'MindBudget/Features/AddExpense/AddExpenseView.swift' Docs/COMMERCIALIZATION_TASKS.md || {
  echo "COM-C6 source-privacy review is missing the AddExpense capture site" >&2
  exit 1
}

grep -Fq 'MindBudget/Features/Commerce/ProSubscriptionView.swift' Docs/COMMERCIALIZATION_TASKS.md || {
  echo "COM-C6 source-privacy review is missing the Pro capture site" >&2
  exit 1
}

if grep -Eqi 'implementation-author (supplemental )?inspection (satisfies|closes|completed) (the |this )?(independent )?(privacy|App Store Connect|COM-C6)' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C5_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/DECISIONS.md; then
  echo "C5 implementation-author inspection must not satisfy the COM-C6 independent privacy review" >&2
  exit 1
fi

# C6-02 is reviewed and closed. Pin the privacy correction and signed-device evidence without
# allowing either to impersonate distribution, an App Store Connect write, or C6-03 entry.
for c602_contract_anchor in \
  'owner explicitly entered C6-02 on 2026-08-30' \
  'DEC-COM-076' \
  'DEC-COM-077' \
  'C6_02_PREFLIGHT.md' \
  'NSPrivacyCollectedDataTypePurchaseHistory' \
  'Product Interaction, Device ID, and Purchase History' \
  'Scripts/privacy_manifest_contract.py' \
  'Scripts/check_required_reason_apis.py' \
  'required-reason source' \
  'fileCreationDate' \
  'contentModificationDate' \
  'volumeAvailableCapacity' \
  'fileSystemFreeSize' \
  'literal raw-value keys' \
  'does not replace the distribution privacy report' \
  'Scripts/inspect-c6-release-app.sh' \
  'aps-environment = development' \
  'get-task-allow = true' \
  'iPhone Air' \
  'iOS 26.6.1' \
  'not distribution evidence'; do
  if ! grep -Fq -- "${c602_contract_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/RELEASE_CHECKLIST.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
      Docs/Commercialization/C6_02_PREFLIGHT.md \
      Docs/Commercialization/REQUIREMENTS_INDEX.md \
      Docs/Commercialization/NETWORK_EGRESS_POLICY.md \
      Docs/Commercialization/DECISIONS.md \
      MindBudget/Resources/PrivacyInfo.xcprivacy \
      Scripts/privacy_manifest_contract.py \
      Scripts/inspect-c6-release-app.sh; then
    echo "C6-02 privacy/signed-device contract is missing: ${c602_contract_anchor}" >&2
    exit 1
  fi
done

# PR #91 closes only the reviewed DEC-COM-081 increment. Require its exact head, hosted run,
# merge commit, and closeout decision in every current C6-02 status surface while preserving the
# still-open manual checklist and blocked C6-03 boundary.
for c602_pr91_closeout_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/C6_02_PREFLIGHT.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  for c602_pr91_closeout_evidence in 'b3ed24d' '33362101536' '4ddabcd' 'DEC-COM-082'; do
    grep -Fq "${c602_pr91_closeout_evidence}" "${c602_pr91_closeout_file}" || {
      echo "C6-02 PR #91 closeout is missing ${c602_pr91_closeout_evidence} in ${c602_pr91_closeout_file}" >&2
      exit 1
    }
  done
done

# DEC-COM-083 replaces the ambiguous open-manual list with a machine-readable bounded acceptance
# packet. Require the decision, checker, exact runtime count, and honest physical non-pass boundary
# across the current C6-02 status surfaces while preserving its explicit physical non-passes.
for c602_acceptance_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/RELEASE_CHECKLIST.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/C6_02_PREFLIGHT.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  for c602_acceptance_anchor in \
    'DEC-COM-083' \
    'C6_02_ACCEPTANCE_MATRIX.json' \
    '23 exact' \
    'C6-03'; do
    grep -Fq "${c602_acceptance_anchor}" "${c602_acceptance_file}" || {
      echo "C6-02 bounded acceptance is missing ${c602_acceptance_anchor} in ${c602_acceptance_file}" >&2
      exit 1
    }
  done
done

for c602_nonpass_anchor in \
  'owner-accepted-non-pass' \
  'xctrace' \
  'No financial store was copied off device' \
  'does not claim those physical side effects passed'; do
  if ! grep -Fq "${c602_nonpass_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/PRIVACY_AND_REVIEW_NOTES.md \
      Docs/RELEASE_CHECKLIST.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
      Docs/Commercialization/C6_02_PREFLIGHT.md \
      Docs/Commercialization/C6_02_ACCEPTANCE_MATRIX.json \
      Docs/Commercialization/REQUIREMENTS_INDEX.md; then
    echo "C6-02 bounded acceptance lost its physical non-pass boundary: ${c602_nonpass_anchor}" >&2
    exit 1
  fi
done

if grep -Eqi 'full (signed-phone )?VoiceOver (matrix )?(passed|is Passed)|Instruments (run )?(passed|is Passed)|exact (data-)?protection class (passed|is Passed)|physical system integration (passed|is Passed)' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/RELEASE_CHECKLIST.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/C6_02_PREFLIGHT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "C6-02 closeout must not convert unrun physical checks into passes" >&2
  exit 1
fi

for c602_portability_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/C6_02_PREFLIGHT.md; do
  for c602_portability_anchor in \
    'DEC-COM-085' \
    'DEC-COM-086' \
    'DEC-COM-087' \
    '33370429991' \
    '33384223530' \
    '33391122019' \
    '33398172181' \
    'toolchain-native' \
    'Save-to-Dashboard'; do
    grep -Fq "${c602_portability_anchor}" "${c602_portability_file}" || {
      echo "C6-02 hosted-schema remediation is missing ${c602_portability_anchor} in ${c602_portability_file}" >&2
      exit 1
    }
  done
done

# DEC-COM-088 closes C6-02 only after the exact final review, green hosted run, and reviewed merge.
# Require the complete provenance in every current status surface so summary prose elsewhere cannot
# substitute for the authoritative phase state. C6-03 still needs a distinct owner/archive decision.
for c602_closeout_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/RELEASE_CHECKLIST.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/C6_02_PREFLIGHT.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  for c602_closeout_anchor in '016dd33' '33405016652' 'c940e8e' 'DEC-COM-088'; do
    grep -Fq "${c602_closeout_anchor}" "${c602_closeout_file}" || {
      echo "C6-02 closeout is missing ${c602_closeout_anchor} in ${c602_closeout_file}" >&2
      exit 1
    }
  done
done

if grep -Eqi 'C6-02 (awaits|remains In Progress|is implementation/evidence complete pending|cannot become Done|still requires (rereview|independent review)|new exact(-head)? hosted run remains required)' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/RELEASE_CHECKLIST.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/C6_02_PREFLIGHT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current C6-02 state regressed to a pre-closeout review/CI status" >&2
  exit 1
fi

grep -Fq 'three exact C6 special checks' Docs/Commercialization/COM_C6_EXECUTION_PACKET.md || {
  echo "COM-C6 packet lost the current three-special-check classification" >&2
  exit 1
}

if grep -Eqi 'review the DEC-COM-081|independently review the DEC-COM-081|DEC-COM-081[^.]*pending (independent )?review|physical reinstall and the remaining|this branch.s review/CI/merge' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/C6_02_PREFLIGHT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current C6-02 state regressed PR #91's reviewed DEC-COM-081 increment to pending" >&2
  exit 1
fi

if grep -Eqi 'C6-02 (remains |is )?blocked pending explicit owner entry|C6-02 awaits explicit owner entry' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/C6_02_PREFLIGHT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current commercialization state still describes C6-02 as awaiting owner entry" >&2
  exit 1
fi

if grep -Eqi 'archive (is )?authorized by C6-02|App Store Connect (was|is) updated by C6-02' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/C6_02_PREFLIGHT.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "C6-02 evidence must not enter C6-03 or claim archive/App Store Connect authority" >&2
  exit 1
fi

# DEC-COM-089 is a distinct owner entry, not authority inferred from C6-02. Keep the candidate
# identity and reviewed-before-Archive boundary aligned across every current status surface.
for c603_entry_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/RELEASE_CHECKLIST.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  for c603_entry_anchor in \
    'DEC-COM-089' \
    '0.9.9 (10)' \
    'C6_03_RELEASE_BASELINE.md'; do
    grep -Fq "${c603_entry_anchor}" "${c603_entry_file}" || {
      echo "C6-03 entry is missing ${c603_entry_anchor} in ${c603_entry_file}" >&2
      exit 1
    }
  done
done

grep -Fq 'EXPECTED_BUILD="10"' Scripts/inspect-c6-release-app.sh || {
  echo "C6-03 Distribution inspector must bind the build-10 candidate" >&2
  exit 1
}

# DEC-COM-090 records the exact reviewed merge and bounded TestFlight transport acceptance. Require
# that provenance in every current C6-03 status surface.
for c603_closeout_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/RELEASE_CHECKLIST.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/C6_03_RELEASE_BASELINE.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  for c603_closeout_anchor in \
    '11ab612' \
    '33488815168' \
    'd5d0959' \
    '1b358d3b-4544-4617-ab47-5be69addc7a8' \
    'DEC-COM-090'; do
    grep -Fq "${c603_closeout_anchor}" "${c603_closeout_file}" || {
      echo "C6-03 closeout is missing ${c603_closeout_anchor} in ${c603_closeout_file}" >&2
      exit 1
    }
  done
done

for c603_execution_file in \
  Docs/Commercialization/C6_03_RELEASE_BASELINE.md \
  Docs/Commercialization/DECISIONS.md \
  Docs/Commercialization/SESSION_LOG.md; do
  for c603_execution_anchor in \
    '2026-09-01 19:27:25 +0800' \
    'manageAppVersionAndBuildNumber=false' \
    'Production APS' \
    'get-task-allow=false' \
    'first App Store Connect export is an explicit non-pass'; do
    grep -Fq "${c603_execution_anchor}" "${c603_execution_file}" || {
      echo "C6-03 execution evidence is missing ${c603_execution_anchor} in ${c603_execution_file}" >&2
      exit 1
    }
  done
done

for c603_final_closeout_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/PRIVACY_AND_REVIEW_NOTES.md \
  Docs/RELEASE_CHECKLIST.md \
  Docs/APP_STORE_SUBMISSION.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/C6_03_RELEASE_BASELINE.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/NETWORK_EGRESS_POLICY.md; do
  for c603_final_closeout_anchor in \
    '3ed1357' \
    '33508360536' \
    '246e7c1' \
    'DEC-COM-091'; do
    grep -Fq "${c603_final_closeout_anchor}" "${c603_final_closeout_file}" || {
      echo "C6-03 final closeout is missing ${c603_final_closeout_anchor} in ${c603_final_closeout_file}" >&2
      exit 1
    }
  done
done

for c603_closeout_provenance_file in \
  Docs/Commercialization/DECISIONS.md \
  Docs/Commercialization/SESSION_LOG.md \
  Docs/Commercialization/CI_BASELINE.md; do
  for c603_closeout_provenance_anchor in \
    '3ed1357' \
    '33508360536' \
    '246e7c1' \
    'DEC-COM-091'; do
    grep -Fq "${c603_closeout_provenance_anchor}" "${c603_closeout_provenance_file}" || {
      echo "C6-03 closeout provenance is missing ${c603_closeout_provenance_anchor} in ${c603_closeout_provenance_file}" >&2
      exit 1
    }
  done
done

if grep -Eqi 'C6-03/COM-C6 remain open|C6-03/COM-C6 may be marked Done|documentation closeout (still )?(needs|awaits|pending)|Only this documentation closeout remains open' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/RELEASE_CHECKLIST.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/C6_03_RELEASE_BASELINE.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "Current C6-03 state regressed to a pre-closeout review/CI status" >&2
  exit 1
fi

if grep -Eqi 'tester assignment (is )?(complete|completed)|external Beta App Review (is )?(submitted|complete)|App Store version (is )?submitted|G1 (is )?(passed|approved)|COM-C6\.5 (is )?(In Progress|entered|Done)|public release (is )?(approved|authorized|complete)' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/PRIVACY_AND_REVIEW_NOTES.md \
    Docs/RELEASE_CHECKLIST.md \
    Docs/APP_STORE_SUBMISSION.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/C6_03_RELEASE_BASELINE.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/NETWORK_EGRESS_POLICY.md; then
  echo "C6-03 final closeout overclaims a tester, G1, Watch, distribution, or release gate" >&2
  exit 1
fi

G1_ECONOMICS_PACKET="Docs/Commercialization/G1_UNIT_ECONOMICS_PACKET.md"
G1_LUNA_EVAL_PACKET="Docs/Commercialization/G1_LUNA_EVAL.md"
G1_OPENAI_ACCOUNT_PACKET="Docs/Commercialization/G1_OPENAI_ACCOUNT_EVIDENCE.md"
G1_OPENAI_ADMISSION="Docs/Commercialization/G1_OPENAI_ACCOUNT_ADMISSION.json"
G1_LUNA_EVAL_RESULT="Docs/Commercialization/G1_LUNA_EVAL_RESULT_2026-09-02.json"
G1_LUNA_EVAL_NONPASS1="Docs/Commercialization/G1_LUNA_EVAL_TRANSCRIPT_2026-09-02.jsonl"
G1_LUNA_EVAL_NONPASS2="Docs/Commercialization/G1_LUNA_EVAL_TRANSCRIPT_2026-09-02_ATTEMPT2.jsonl"
G1_LUNA_EVAL_PASS="Docs/Commercialization/G1_LUNA_EVAL_TRANSCRIPT_2026-09-02_ATTEMPT3.jsonl"
G1_THREE_WAY_EVAL_PACKET="Docs/Commercialization/G1_THREE_WAY_EVAL.md"
G1_APPLE_ON_DEVICE_TRANSCRIPT="Docs/Commercialization/G1_APPLE_ON_DEVICE_EVAL_TRANSCRIPT_2026-09-02.jsonl"
G1_THREE_WAY_BLIND_REVIEW="Docs/Commercialization/G1_THREE_WAY_BLIND_REVIEW_2026-09-02.json"
G1_THREE_WAY_REVIEW_SIDECAR="Docs/Commercialization/G1_THREE_WAY_REVIEW_SIDECAR_2026-09-02.json"
G1_THREE_WAY_REVIEW_RESULT="Docs/Commercialization/G1_THREE_WAY_REVIEW_RESULT_2026-09-02.json"
test -f "${G1_ECONOMICS_PACKET}" || {
  echo "Missing G1 quote/economics packet" >&2
  exit 1
}
test -f "${G1_LUNA_EVAL_PACKET}" || {
  echo "Missing frozen Luna Eval packet" >&2
  exit 1
}
test -f "${G1_OPENAI_ACCOUNT_PACKET}" || {
  echo "Missing OpenAI account-evidence packet" >&2
  exit 1
}
test -f "${G1_OPENAI_ADMISSION}" || {
  echo "Missing machine-readable OpenAI account admission" >&2
  exit 1
}
test -f "${G1_LUNA_EVAL_RESULT}" || {
  echo "Missing machine-readable Luna Eval result" >&2
  exit 1
}
test -f "${G1_THREE_WAY_EVAL_PACKET}" || {
  echo "Missing fixed G1 three-way Eval packet" >&2
  exit 1
}
test -f "${G1_APPLE_ON_DEVICE_TRANSCRIPT}" || {
  echo "Missing normalized Apple on-device Eval transcript" >&2
  exit 1
}
test -f "${G1_THREE_WAY_BLIND_REVIEW}" || {
  echo "Missing G1 three-way blind-review packet" >&2
  exit 1
}
test -f "${G1_THREE_WAY_REVIEW_SIDECAR}" || {
  echo "Missing G1 post-score review sidecar: ${G1_THREE_WAY_REVIEW_SIDECAR}" >&2
  exit 1
}
test -f "${G1_THREE_WAY_REVIEW_RESULT}" || {
  echo "Missing G1 three-way review result: ${G1_THREE_WAY_REVIEW_RESULT}" >&2
  exit 1
}

for g1_economics_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
  Docs/Commercialization/REGIONAL_PRICING.md \
  "${G1_ECONOMICS_PACKET}"; do
  for g1_economics_anchor in \
    'DEC-COM-095' \
    'DEC-COM-096' \
    'DEC-COM-097' \
    'DEC-COM-098' \
    'DEC-COM-099' \
    'DEC-COM-100' \
    'DEC-COM-101' \
    'bb939d0' \
    '33628847476' \
    '2254902' \
    'bcbf943ba7d6a1a9d18442efc38e760cc798c30e8674c8d877f9e0cb751ab2a5' \
    'US$4.99' \
    'gpt-5.6-luna' \
    '50%' \
    'typical/P50' \
    'peak/P95' \
    'three-way comparative Eval' \
    'consumable'; do
    grep -Fq "${g1_economics_anchor}" "${g1_economics_file}" || {
      echo "G1 economics scope is missing ${g1_economics_anchor} in ${g1_economics_file}" >&2
      exit 1
    }
  done
done

for g1_comparative_result_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
  Docs/Commercialization/REGIONAL_PRICING.md \
  "${G1_ECONOMICS_PACKET}"; do
  for g1_comparative_result_anchor in \
    'DEC-COM-102' \
    'd2b9310f4471400825e666009f646a190d8ac2819f859c8e38d58ec05cbf040e' \
    'NON_PASS' \
    'COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION'; do
    grep -Fq "${g1_comparative_result_anchor}" "${g1_comparative_result_file}" || {
      echo "G1 comparative non-pass is missing ${g1_comparative_result_anchor} in ${g1_comparative_result_file}" >&2
      exit 1
    }
  done
done

python3 - "${G1_OPENAI_ADMISSION}" <<'PY'
import json
import sys

value = json.load(open(sys.argv[1], encoding="utf-8"))
expected_evidence = {
    "dedicatedProject",
    "noDataSharing",
    "apiCallLoggingDisabled",
    "standardRetentionAcknowledged",
    "globalRegion",
    "lunaOnlyModelAllowlist",
    "endpointCompatibility",
    "rateTier",
    "billingControls",
    "credentialIsolation",
}
if value.get("schemaVersion") != 2 or set(value.get("evidence", {})) != expected_evidence:
    raise SystemExit("G1 account admission schema drifted")
if value.get("scope") != "synthetic_eval_only" or value.get("productionAdmitted") is not False:
    raise SystemExit("G1 may admit only synthetic Eval and never production traffic")
if value.get("retention") != {
    "mode": "standard_up_to_30_days",
    "store": False,
    "background": False,
    "promptCaching": "explicit_no_breakpoints",
}:
    raise SystemExit("G1 standard-retention contract drifted")
if value.get("approvedBaseURL") != "https://api.openai.com/v1":
    raise SystemExit("G1 Global project must use the exact standard API base URL")
if any(type(item) is not bool for item in value["evidence"].values()):
    raise SystemExit("G1 account evidence rows must be exact booleans")
if value.get("evalAdmitted") is True and not all(value["evidence"].values()):
    raise SystemExit("G1 Eval cannot be admitted with an incomplete evidence matrix")
if value.get("evalAdmitted") is not True or not all(value["evidence"].values()):
    raise SystemExit("G1 synthetic Eval admission must remain complete after the live run")
PY

python3 - "${G1_LUNA_EVAL_RESULT}" <<'PY'
import hashlib
import json
import pathlib
import subprocess
import sys

result_path = pathlib.Path(sys.argv[1])
value = json.loads(result_path.read_text(encoding="utf-8"))
if value.get("schemaVersion") != 2:
    raise SystemExit("G1 Luna Eval reviewed-result schema drifted")
if value.get("result") != "AUTOMATED_PASS_INDEPENDENTLY_REVIEWED":
    raise SystemExit("G1 Luna Eval result must preserve the accepted independent review")
if value.get("scope") != "synthetic_eval_only" or value.get("productionAdmitted") is not False:
    raise SystemExit("G1 Luna Eval result cannot admit production")
if value.get("datasetSHA256") != "d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014":
    raise SystemExit("G1 Luna Eval result dataset hash drifted")
if value.get("promptSchemaSHA256") != "c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018":
    raise SystemExit("G1 Luna Eval result prompt/schema hash drifted")
if value.get("caseCount") != 24 or value.get("attemptCount") != 24:
    raise SystemExit("G1 Luna Eval case/attempt count drifted")
if value.get("finalPassCount") != 24 or value.get("firstPassCount") != 24:
    raise SystemExit("G1 Luna Eval pass counts drifted")
if value.get("retryCaseCount") != 0 or value.get("hardFailures") != []:
    raise SystemExit("G1 Luna Eval retry/failure result drifted")
review = value.get("independentReview")
expected_review_keys = {
    "status",
    "reviewDate",
    "reviewedPullRequest",
    "reviewedHead",
    "hostedCIRun",
    "mergeCommit",
    "finalOutputRead",
    "p3Findings",
}
if not isinstance(review, dict) or set(review) != expected_review_keys:
    raise SystemExit("G1 Luna Eval independent-review record drifted")
expected_review_core = {
    "status": "APPROVED_NO_P1_P2",
    "reviewedHead": "323d8d7904cf4d2413efa661b50e7d092a860af0",
    "mergeCommit": "7a473d2f4123bef60615efd9f104cee2e473afd5",
}
if any(review.get(key) != expected for key, expected in expected_review_core.items()):
    raise SystemExit("G1 Luna Eval independent-review provenance drifted")
if not isinstance(review.get("reviewDate"), str) or not review["reviewDate"]:
    raise SystemExit("G1 Luna Eval independent-review date must be recorded")
if type(review.get("reviewedPullRequest")) is not int or review["reviewedPullRequest"] <= 0:
    raise SystemExit("G1 Luna Eval reviewed pull request must be a positive integer")
if type(review.get("hostedCIRun")) is not int or review["hostedCIRun"] <= 0:
    raise SystemExit("G1 Luna Eval hosted CI run must be a positive integer")
if review.get("finalOutputRead") != "24_OF_24":
    raise SystemExit("G1 Luna Eval independent review must cover all final outputs")
if type(review.get("p3Findings")) is not int or review["p3Findings"] < 0:
    raise SystemExit("G1 Luna Eval P3 count must be a non-negative integer")

artifacts = [value["passingTranscript"], *value["nonPassAttempts"]]
for artifact in artifacts:
    path = pathlib.Path(artifact["path"])
    if not path.is_file():
        raise SystemExit(f"missing G1 Luna Eval transcript: {path}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != artifact["sha256"]:
        raise SystemExit(f"G1 Luna Eval transcript hash drifted: {path}")

score = json.loads(
    subprocess.check_output(
        [sys.executable, "Scripts/g1_luna_eval.py", "--score", value["passingTranscript"]["path"]],
        text=True,
    )
)
if score.get("deterministic_result") != "PASS":
    raise SystemExit("G1 Luna Eval passing transcript no longer scores PASS")
result_to_score = {
    "model": "model",
    "datasetSHA256": "dataset_sha256",
    "promptSchemaSHA256": "prompt_sha256",
    "caseCount": "case_count",
    "attemptCount": "attempt_count",
    "finalPassCount": "final_pass_count",
    "firstPassCount": "first_pass_count",
    "firstPassRateBasisPoints": "first_pass_rate_bps",
    "retryCaseCount": "retry_case_count",
    "retryRateBasisPoints": "retry_rate_bps",
    "inputTokensP50": "input_tokens_p50",
    "inputTokensP95": "input_tokens_p95",
    "outputTokensP50": "output_tokens_p50",
    "outputTokensP95": "output_tokens_p95",
    "latencyMillisecondsP50": "latency_ms_p50",
    "latencyMillisecondsP95": "latency_ms_p95",
    "hardFailures": "hard_failures",
}
for result_key, score_key in result_to_score.items():
    if value.get(result_key) != score.get(score_key):
        raise SystemExit(f"G1 Luna Eval result does not match transcript score: {result_key}")
PY

python3 Scripts/g1_luna_eval.py --score "${G1_LUNA_EVAL_PASS}" >/dev/null
if python3 Scripts/g1_luna_eval.py --score "${G1_LUNA_EVAL_NONPASS1}" >/dev/null 2>&1; then
  echo "First Luna Eval non-pass transcript unexpectedly passed" >&2
  exit 1
fi
if python3 Scripts/g1_luna_eval.py --score "${G1_LUNA_EVAL_NONPASS2}" >/dev/null 2>&1; then
  echo "Second Luna Eval non-pass transcript unexpectedly passed" >&2
  exit 1
fi

for g1_decision_file in \
  Docs/DECISIONS.md \
  Docs/SESSION_LOG.md \
  Docs/Commercialization/DECISIONS.md \
  Docs/Commercialization/SESSION_LOG.md \
  Docs/Commercialization/CI_BASELINE.md; do
  grep -Fq 'DEC-COM-092' "${g1_decision_file}" || {
    echo "G1 economics decision is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-093' "${g1_decision_file}" || {
    echo "Entered-G1 interim decision is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-094' "${g1_decision_file}" || {
    echo "Reviewed G1 quote-package closeout is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-095' "${g1_decision_file}" || {
    echo "Accepted G1 product-policy decision is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-096' "${g1_decision_file}" || {
    echo "Frozen Luna Eval/offer decision is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-097' "${g1_decision_file}" || {
    echo "Synthetic-Eval standard-retention decision is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-098' "${g1_decision_file}" || {
    echo "Luna Eval execution decision is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-099' "${g1_decision_file}" || {
    echo "Reviewed Luna Eval delivery closeout is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-100' "${g1_decision_file}" || {
    echo "Three-way Eval harness decision is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-101' "${g1_decision_file}" || {
    echo "Reviewed three-way capture-delivery closeout is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-102' "${g1_decision_file}" || {
    echo "Independent three-way blind-review result is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-103' "${g1_decision_file}" || {
    echo "Reviewed comparative-result delivery closeout is missing from ${g1_decision_file}" >&2
    exit 1
  }
  grep -Fq 'DEC-COM-104' "${g1_decision_file}" || {
    echo "G1 Luna/card owner disposition is missing from ${g1_decision_file}" >&2
    exit 1
  }
done

for g1_owner_disposition_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
  Docs/Commercialization/REGIONAL_PRICING.md \
  "${G1_ECONOMICS_PACKET}" \
  "${G1_THREE_WAY_EVAL_PACKET}"; do
  for g1_owner_disposition_anchor in \
    'DEC-COM-104' \
    'DEFER_LUNA_CREDITS_KEEP_LOCAL_PRO' \
    'LUNA_CREDITS_DEFERRED_PENDING_REVIEW_AND_CLOSEOUT'; do
    grep -Fq "${g1_owner_disposition_anchor}" "${g1_owner_disposition_file}" || {
      echo "G1 owner deferral is missing ${g1_owner_disposition_anchor} in ${g1_owner_disposition_file}" >&2
      exit 1
    }
  done
done

for g1_local_only_egress_anchor in \
  'Deferred by DEC-COM-104; no domain or route' \
  'Deferred by DEC-COM-104; forbidden in the local-only candidate'; do
  grep -Fq "${g1_local_only_egress_anchor}" Docs/Commercialization/NETWORK_EGRESS_POLICY.md || {
    echo "G1 local-only egress boundary is missing ${g1_local_only_egress_anchor}" >&2
    exit 1
  }
done

for g1_result_closeout_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
  Docs/Commercialization/REGIONAL_PRICING.md \
  "${G1_ECONOMICS_PACKET}" \
  "${G1_THREE_WAY_EVAL_PACKET}"; do
  for g1_result_closeout_anchor in \
    'DEC-COM-103' \
    '2fb2b64' \
    '33701018178' \
    'e4b54af' \
    'COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION'; do
    grep -Fq "${g1_result_closeout_anchor}" "${g1_result_closeout_file}" || {
      echo "G1 comparative-result closeout is missing ${g1_result_closeout_anchor} in ${g1_result_closeout_file}" >&2
      exit 1
    }
  done
done

for g1_closeout_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
  Docs/Commercialization/REGIONAL_PRICING.md \
  "${G1_ECONOMICS_PACKET}"; do
  for g1_closeout_anchor in \
    'DEC-COM-094' \
    '9226985' \
    '33570570896' \
    '6e2d242' \
    'INSUFFICIENT_QUOTE_EVIDENCE'; do
    grep -Fq "${g1_closeout_anchor}" "${g1_closeout_file}" || {
      echo "G1 reviewed-package closeout is missing ${g1_closeout_anchor} in ${g1_closeout_file}" >&2
      exit 1
    }
  done
done

for g1_eval_closeout_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
  Docs/Commercialization/REGIONAL_PRICING.md \
  "${G1_ECONOMICS_PACKET}"; do
  for g1_eval_closeout_anchor in \
    'DEC-COM-099' \
    '323d8d7' \
    '33593253561' \
    '7a473d2' \
    'EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE'; do
    grep -Fq "${g1_eval_closeout_anchor}" "${g1_eval_closeout_file}" || {
      echo "Reviewed Luna Eval closeout is missing ${g1_eval_closeout_anchor} in ${g1_eval_closeout_file}" >&2
      exit 1
    }
  done
done

for g1_review_limit_anchor in \
  'owner policy selection' \
  'US$0.033098' \
  'US$0.018986' \
  'US$0.372250' \
  'US$1.372250'; do
  grep -Fq "${g1_review_limit_anchor}" "${G1_ECONOMICS_PACKET}" || {
    echo "G1 economics review clarification is missing ${g1_review_limit_anchor}" >&2
    exit 1
  }
done

for g1_scorer_limit_anchor in \
  'number words' \
  'missing provider usage fields' \
  'MAX_RETRIES_PER_CASE'; do
  grep -Fq "${g1_scorer_limit_anchor}" "${G1_LUNA_EVAL_PACKET}" || {
    echo "G1 scorer review limitation is missing ${g1_scorer_limit_anchor}" >&2
    exit 1
  }
done

for g1_review_followup_anchor in \
  'server-enforced acceptance gate' \
  'optimization-removable' \
  '30-day'; do
  grep -Fq "${g1_review_followup_anchor}" Docs/Commercialization/DECISIONS.md || {
    echo "Historical G1 review follow-up is missing ${g1_review_followup_anchor}" >&2
    exit 1
  }
done

for g1_current_followup_anchor in \
  'server-enforced acceptance gate' \
  'explicit-failure self-tests' \
  '30 days'; do
  grep -Fq "${g1_current_followup_anchor}" "${G1_ECONOMICS_PACKET}" || {
    echo "Current G1 evidence rule is missing ${g1_current_followup_anchor}" >&2
    exit 1
  }
done

python3 - Docs/COMMERCIALIZATION_TASKS.md "${G1_ECONOMICS_PACKET}" <<'PY'
import pathlib
import sys

tasks = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
economics = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")

current_state = tasks.split("## Current state", 1)[1].split("\n## ", 1)[0]
expected_active = (
    "- Active phase: **G1 is In Progress under DEC-COM-104 at\n"
    "  `LUNA_CREDITS_DEFERRED_PENDING_REVIEW_AND_CLOSEOUT`; COM-C7 through COM-C11 are deferred and no\n"
    "  implementation phase is currently entered. After this decision record is independently reviewed,\n"
    "  green, merged, and closed, the next eligible path is a separately owner-entered local-only\n"
    "  COM-C12 release review."
)
if current_state.count(expected_active) != 1:
    raise SystemExit("G1 top-level Active phase must identify the DEC-COM-104 local-only deferral")
if "EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE" in current_state:
    raise SystemExit("G1 top-level Active phase still carries the superseded storefront-only state")
if "COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION" in current_state:
    raise SystemExit("G1 top-level Active phase still claims the owner disposition is pending")

expected_economics_status = (
    "Status: **In Progress at `LUNA_CREDITS_DEFERRED_PENDING_REVIEW_AND_CLOSEOUT` under DEC-COM-104.**"
)
if economics.splitlines()[2] != expected_economics_status:
    raise SystemExit("G1 economics packet status must identify the accepted local-only deferral")
PY

grep -Fq 'Status: **In Progress under DEC-COM-104 at' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "G1 current phase status must record the accepted local-only deferral" >&2
  exit 1
}

grep -Fq 'Status: **Blocked; deferred by DEC-COM-104. Re-entry requires fresh G1 evidence and explicit' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "COM-C7 must remain deferred after the G1 owner disposition" >&2
  exit 1
}

grep -Fq 'Status: **Blocked until the G1 deferral record is reviewed, merged, closed, and followed by a' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "Local-only COM-C12 must remain eligible but unentered" >&2
  exit 1
}

grep -Fq -- '- [x] Independently review and merge the three-way harness and physical-output capture delivery.' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "G1 closeout must mark only the reviewed three-way capture delivery complete" >&2
  exit 1
}
grep -Fq -- '- [x] Complete the fixed bilingual three-way comparative Eval across deterministic template,' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "G1 independent three-way blind score must be recorded complete" >&2
  exit 1
}
grep -Fq -- '- [x] Record the final G1 owner disposition after the comparative non-pass.' \
  Docs/COMMERCIALIZATION_TASKS.md || {
  echo "G1 owner disposition must be recorded complete" >&2
  exit 1
}

python3 - Docs/COMMERCIALIZATION_TASKS.md Docs/Commercialization/REQUIREMENTS_INDEX.md <<'PY'
import pathlib
import sys

tasks = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
requirements = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")

def normalized_section(title: str) -> str:
    section = tasks.split(f"## {title}", 1)[1].split("\n## ", 1)[0]
    return " ".join(section.split())

expected_sections = {
    "COM-C7 — Current entitlement, App Attest, and backend skeleton":
        "Status: **Blocked; deferred by DEC-COM-104. Re-entry requires fresh G1 evidence and explicit `PROCEED_TO_R2`.**",
    "COM-C8 — Cloud Coach consent, redaction, and sole-provider adapter":
        "Status: **Blocked; deferred with COM-C7 by DEC-COM-104.**",
    "COM-C9 — Quota, rate limits, idempotency, and degradation":
        "Status: **Blocked; deferred with COM-C7 by DEC-COM-104.**",
    "COM-C10 — Server notifications and reconciliation":
        "Status: **Blocked; deferred with COM-C7 by DEC-COM-104.**",
    "COM-C11 — Cloud operations, configuration, experiments, and cost dashboard":
        "Status: **Blocked; deferred with COM-C7 by DEC-COM-104.**",
    "COM-C12 — Full-product security, privacy, review, and formal 1.0":
        "Status: **Blocked until the G1 deferral record is reviewed, merged, closed, and followed by a separate local-only owner entry.",
}
for title, expected in expected_sections.items():
    section = normalized_section(title)
    if expected not in section:
        raise SystemExit(f"{title} does not preserve the DEC-COM-104 phase boundary")

for expected_row in (
    "| REQ-CLOUD-AUTH-001 | Deferred by DEC-COM-104; absent from local-only launch |",
    "| REQ-CLOUD-CONSENT-001 | Deferred by DEC-COM-104; production not admitted |",
    "| REQ-CLOUD-USAGE-001 | Deferred by DEC-COM-104; no active credit offer |",
    "| REQ-G1-001 | Active; owner selected `DEFER_LUNA_CREDITS_KEEP_LOCAL_PRO`, pending reviewed record closeout |",
):
    if requirements.count(expected_row) != 1:
        raise SystemExit(f"G1 requirement disposition drifted: {expected_row}")
PY

if grep -Eqi '(^|[.!?][[:space:]])comparative value (is )?(accepted|approved|proven|passed)|three-way comparative Eval (result|is)[: ]+PASS' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
    Docs/Commercialization/REGIONAL_PRICING.md \
    "${G1_ECONOMICS_PACKET}" \
    "${G1_THREE_WAY_EVAL_PACKET}"; then
  echo "G1 record overclaims acceptance despite the comparative non-pass" >&2
  exit 1
fi

python3 Scripts/g1_unit_economics.py --self-test >/dev/null
python3 -O Scripts/g1_unit_economics.py --self-test >/dev/null
python3 Scripts/g1_unit_economics.py --check-document "${G1_ECONOMICS_PACKET}" >/dev/null
python3 Scripts/g1_luna_eval.py --self-test >/dev/null
python3 -O Scripts/g1_luna_eval.py --self-test >/dev/null
python3 Scripts/g1_three_way_eval.py --self-test >/dev/null
python3 -O Scripts/g1_three_way_eval.py --self-test >/dev/null
python3 Scripts/g1_three_way_eval.py \
  --check-review-packet "${G1_THREE_WAY_BLIND_REVIEW}" \
  --on-device-transcript "${G1_APPLE_ON_DEVICE_TRANSCRIPT}" \
  --review-sidecar "${G1_THREE_WAY_REVIEW_SIDECAR}" \
  --require-complete-review >/dev/null

test "$(shasum -a 256 "${G1_APPLE_ON_DEVICE_TRANSCRIPT}" | awk '{print $1}')" = \
  'd6236a29293e0c16068fb24b6b7a6392af9cfedc9dadb9c7cdc06b8fabb5a20b' || {
  echo "Apple on-device Eval transcript hash drifted" >&2
  exit 1
}
test "$(shasum -a 256 "${G1_THREE_WAY_BLIND_REVIEW}" | awk '{print $1}')" = \
  'd2b9310f4471400825e666009f646a190d8ac2819f859c8e38d58ec05cbf040e' || {
  echo "G1 completed blind-review packet hash drifted" >&2
  exit 1
}
test "$(shasum -a 256 "${G1_THREE_WAY_REVIEW_SIDECAR}" | awk '{print $1}')" = \
  'd29fca8246df5641d876be19ea56a936edd975616d2b3101bc18cca9d7bff507' || {
  echo "G1 post-score review sidecar hash drifted" >&2
  exit 1
}
test "$(shasum -a 256 "${G1_THREE_WAY_REVIEW_RESULT}" | awk '{print $1}')" = \
  'bf6b7212cc2ad4139a8e8f9d3eb877a5926ccc53378094dbcb12595f51b6f9f4' || {
  echo "G1 three-way review result hash drifted" >&2
  exit 1
}

g1_review_result_tmp_dir="$(mktemp -d)"
g1_review_result_tmp="${g1_review_result_tmp_dir}/result.json"
python3 Scripts/g1_three_way_eval.py \
  --summarize-review "${G1_THREE_WAY_BLIND_REVIEW}" \
  --on-device-transcript "${G1_APPLE_ON_DEVICE_TRANSCRIPT}" \
  --review-sidecar "${G1_THREE_WAY_REVIEW_SIDECAR}" \
  --output "${g1_review_result_tmp}" >/dev/null
cmp -s "${g1_review_result_tmp}" "${G1_THREE_WAY_REVIEW_RESULT}" || {
  rm -rf -- "${g1_review_result_tmp_dir}"
  echo "G1 three-way review result does not match the sealed score/mapping" >&2
  exit 1
}
rm -rf -- "${g1_review_result_tmp_dir}"

python3 - "${G1_THREE_WAY_REVIEW_RESULT}" <<'PY'
import json
import sys

result = json.load(open(sys.argv[1], encoding="utf-8"))
if result["result"] != "NON_PASS":
    raise SystemExit("G1 three-way review must preserve the computed NON_PASS")
if result["production_admitted"] is not False:
    raise SystemExit("G1 three-way review cannot admit production")
if result["qualifying_bilingual_tasks"] != []:
    raise SystemExit("G1 NON_PASS cannot claim a qualifying bilingual task")
if result["luna_materially_preferred_case_count"] != 0:
    raise SystemExit("G1 NON_PASS cannot claim a materially preferred Luna case")
PY

python3 - "${G1_THREE_WAY_EVAL_PACKET}" <<'PY'
import pathlib
import sys
import xml.etree.ElementTree as ET

root = pathlib.Path.cwd()
packet = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
expected_packet_status = "Status: **LUNA_CREDITS_DEFERRED_PENDING_REVIEW_AND_CLOSEOUT**"
if packet.splitlines()[2] != expected_packet_status or packet.count(expected_packet_status) != 1:
    raise SystemExit("G1 three-way Eval packet must have one exact owner-deferral status at the header")
scheme_path = root / "MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget-G1-OnDevice-Eval.xcscheme"
default_scheme_path = root / "MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget.xcscheme"
test_path = root / "MindBudgetTests/G1ThreeWayOnDeviceEvalTests.swift"
runner_path = root / "Scripts/run-g1-three-way-on-device.sh"
project_path = root / "MindBudget.xcodeproj/project.pbxproj"
for path in (scheme_path, default_scheme_path, test_path, runner_path, project_path):
    if not path.is_file():
        raise SystemExit(f"missing G1 three-way Eval wiring: {path}")

scheme = ET.parse(scheme_path).getroot()
if scheme.find("ArchiveAction") is not None or scheme.find("LaunchAction") is not None:
    raise SystemExit("G1 three-way Eval scheme must not launch or archive")
entries = scheme.findall("./BuildAction/BuildActionEntries/BuildActionEntry")
if len(entries) != 2 or any(
    entry.get("buildForTesting") != "YES"
    or entry.get("buildForRunning") != "NO"
    or entry.get("buildForArchiving") != "NO"
    for entry in entries
):
    raise SystemExit("G1 three-way Eval scheme build boundary drifted")
variables = scheme.findall("./TestAction/EnvironmentVariables/EnvironmentVariable")
if [variable.attrib for variable in variables] != [
    {"key": "MINDBUDGET_G1_ON_DEVICE_EVAL", "value": "1", "isEnabled": "YES"}
]:
    raise SystemExit("G1 three-way Eval opt-in variable drifted")
if "MINDBUDGET_G1_ON_DEVICE_EVAL" in default_scheme_path.read_text(encoding="utf-8"):
    raise SystemExit("ordinary MindBudget scheme must not enable the G1 physical Eval")

test_source = test_path.read_text(encoding="utf-8")
for anchor in (
    'ProcessInfo.processInfo.environment["MINDBUDGET_G1_ON_DEVICE_EVAL"] == "1"',
    "d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014",
    "SystemLanguageModel.default.supportsLocale",
    "successfulModelOutputCount == cases.count",
    "MINDBUDGET_G1_ON_DEVICE_EVAL",
):
    if anchor not in test_source:
        raise SystemExit(f"G1 on-device test is missing {anchor}")
if "OPENAI_API_KEY" in test_source or "api.openai.com" in test_source:
    raise SystemExit("G1 on-device test must never call OpenAI")

runner = runner_path.read_text(encoding="utf-8")
for anchor in ("拉沙的iPhone", "Xiao li的 iPhone (2)", "refusing to overwrite", "-only-testing"):
    if anchor.casefold() not in runner.casefold():
        raise SystemExit(f"G1 physical runner is missing {anchor}")
project = project_path.read_text(encoding="utf-8")
if project.count("G1ThreeWayOnDeviceEvalTests.swift") != 6:
    raise SystemExit("G1 on-device test target wiring drifted")
if project.count("G1_LUNA_EVAL_CASES.json") != 6:
    raise SystemExit("G1 frozen dataset resource wiring drifted")

for anchor in (
    "does not perform or charge",
    "procedural blindness, not cryptographic secrecy",
    "post-score-only",
    "Apple prompt/schema mechanism differs from Luna",
    "DEC-COM-102",
    "d2b9310f4471400825e666009f646a190d8ac2819f859c8e38d58ec05cbf040e",
    "NON_PASS",
):
    if anchor not in packet:
        raise SystemExit(f"G1 three-way Eval packet is missing {anchor}")
PY

for g1_eval_anchor in \
  'd509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014' \
  'c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018' \
  'LIVE_LUNA_EVAL_AUTOMATED_PASS_INDEPENDENTLY_REVIEWED' \
  'three-way comparative Eval' \
  '4800cc6c8458fa39b0bd4419d90fbf7ee4bfa47bc3deffa73475b751e947999e' \
  '24/24' \
  'at least 95.00%' \
  'at most 5.00%'; do
  grep -Fq "${g1_eval_anchor}" "${G1_LUNA_EVAL_PACKET}" || {
    echo "Frozen Luna Eval packet is missing ${g1_eval_anchor}" >&2
    exit 1
  }
done

for g1_account_anchor in \
  'OPENAI_SYNTHETIC_EVAL_ACCOUNT_ADMITTED_PRODUCTION_BLOCKED' \
  'synthetic_eval_only' \
  'standard abuse-monitoring retention of up to 30 days' \
  'productionAdmitted: false' \
  'Usage/rate tier' \
  'Billing controls' \
  'Credential isolation'; do
  grep -Fq "${g1_account_anchor}" "${G1_OPENAI_ACCOUNT_PACKET}" || {
    echo "OpenAI account-evidence packet is missing ${g1_account_anchor}" >&2
    exit 1
  }
done

for g1_interim_anchor in \
  'INSUFFICIENT_QUOTE_EVIDENCE' \
  'EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE' \
  '10 starter uses' \
  '10 uses / US$0.99' \
  '25 uses / US$1.99' \
  '65 uses / US$4.99'; do
  grep -Fq "${g1_interim_anchor}" "${G1_ECONOMICS_PACKET}" || {
    echo "G1 interim packet is missing ${g1_interim_anchor}" >&2
    exit 1
  }
done

for g1_current_state_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/PROJECT_MEMORY.md \
  Docs/Commercialization/PROJECT_MEMORY.md \
  Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
  Docs/Commercialization/REGIONAL_PRICING.md \
  "${G1_ECONOMICS_PACKET}" \
  "${G1_LUNA_EVAL_PACKET}"; do
  if grep -Fq '1d3e1d874ef054e8a41038cea99154a47c484c21658218d4c58809e19820d40b' \
      "${g1_current_state_file}"; then
    echo "Superseded Luna prompt hash reappeared in current state: ${g1_current_state_file}" >&2
    exit 1
  fi
done

if grep -Eqi 'G1 .*frozen observation window|G1 .*actual proceeds|G1 .*customer telemetry|G1 .*public App Store observation.*required' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    "${G1_ECONOMICS_PACKET}"; then
  echo "Current G1 scope regressed to the superseded public-observation prerequisite" >&2
  exit 1
fi

for g1_policy_file in \
  Docs/COMMERCIALIZATION_TASKS.md \
  Docs/TASKS.md \
  Docs/Commercialization/REQUIREMENTS_INDEX.md \
  Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
  Docs/Commercialization/REGIONAL_PRICING.md \
  "${G1_ECONOMICS_PACKET}"; do
  for g1_policy_anchor in \
    'zero Luna credits' \
    'one user-calendar year' \
    'ultimately displayed' \
    'ordinary test' \
    'Apple App Review'; do
    grep -Fiq "${g1_policy_anchor}" "${g1_policy_file}" || {
      echo "G1 accepted policy is missing ${g1_policy_anchor} in ${g1_policy_file}" >&2
      exit 1
    }
  done
done

if grep -Eqi 'G1 (is )?(passed|approved|Done)|COM-C7 (is )?(In Progress|entered|Done)|LIVE_LUNA_EVAL_PASSED|ZDR_VERIFIED|OPENAI_ACCOUNT_ADMITTED' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
    Docs/Commercialization/REGIONAL_PRICING.md \
    "${G1_ECONOMICS_PACKET}"; then
  echo "G1 work overclaims an account/Eval/phase result or downstream phase" >&2
  exit 1
fi

if grep -Eqi 'ordinary (TestFlight|Sandbox|test) users? (can|may|are allowed to) (call|use|reach) Luna|credits? (never|do not) expire|provider failover (is|remains) enabled' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
    Docs/Commercialization/REQUIREMENTS_INDEX.md \
    Docs/Commercialization/AI_PROVIDER_CONTRACT.md \
    Docs/Commercialization/REGIONAL_PRICING.md \
    "${G1_ECONOMICS_PACKET}"; then
  echo "G1 current policy regressed on trial credits, test access, expiry, or provider failover" >&2
  exit 1
fi

echo "Commercialization documentation gate passed"
