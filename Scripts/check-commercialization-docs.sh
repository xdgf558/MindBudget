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

grep -Fq '**Formal commercial values are TBD; provisional C3 test terms were accepted on 2026-08-14.**' Docs/Commercialization/REGIONAL_PRICING.md || {
  echo "Regional pricing must distinguish provisional test terms from formal pricing" >&2
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

# The owner entered COM-C6 only after the reviewed C5 closeout. Pin the current C6-01-only state
# without rewriting the historical C5 packet that recorded the earlier wait boundary.
for c601_entry_anchor in \
  'owner explicitly entered COM-C6 on 2026-08-29' \
  'C6-01 implementation is complete pending independent review' \
  'C6-02 and C6-03 remain blocked' \
  'remoteMutationAllowed' \
  'optionalNetworkFailuresCannotChangeTheInjectedLocalProSnapshot'; do
  if ! grep -Fq "${c601_entry_anchor}" \
      Docs/COMMERCIALIZATION_TASKS.md \
      Docs/TASKS.md \
      Docs/PROJECT_MEMORY.md \
      Docs/Commercialization/PROJECT_MEMORY.md \
      Docs/Commercialization/COM_C6_EXECUTION_PACKET.md \
      Docs/Commercialization/C6_RELEASE_MATRIX.json \
      MindBudgetTests/CommercializationEntitlementTests.swift; then
    echo "C6-01 entry/matrix contract is missing: ${c601_entry_anchor}" >&2
    exit 1
  fi
done

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

if grep -Eqi 'C6-02 (is )?(In Progress|entered|Done)|C6-03 (is )?(In Progress|entered|Done)' \
    Docs/COMMERCIALIZATION_TASKS.md \
    Docs/TASKS.md \
    Docs/PROJECT_MEMORY.md \
    Docs/Commercialization/PROJECT_MEMORY.md \
    Docs/Commercialization/COM_C6_EXECUTION_PACKET.md; then
  echo "C6-01 must not auto-enter or complete C6-02/C6-03" >&2
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

echo "Commercialization documentation gate passed"
