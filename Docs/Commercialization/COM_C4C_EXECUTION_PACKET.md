# COM-C4C Execution Packet — Local Pro and Receipt Recognition

## Status

Status: **C4C-03 implementation complete pending independent review and hosted CI.**

COM-C4B closed through reviewed PR #64 (`4f6d7fe`) and the documentation closeout merged through
PR #65 (`f5ab156`). Reviewed C4C-01 head `d203308` passed GitHub Actions run `32845307426`, and
PR #66 merged it as `8611022`; documentation closeout head `55a321c` passed Actions run
`32850616400`, and PR #67 merged it as `bdb94d9`. The owner then explicitly entered C4C-02.
Reviewed C4C-02 head `43c3a35` passed Actions run `32860643712`, and PR #68 merged it as
`4ca8f1c`. Documentation head `4ab0daf` passed run `32911659905`, and PR #69 merged that closeout
as `3e1c5c9`. C4C-02 is Done. The owner then explicitly entered C4C-03. The current candidate adds
a bounded local OCR/privacy boundary, but no customer entry, structured receipt field,
persistence, iCloud receipt field, model prompt, network channel, Production action, or release
authority.

## Input gate

- The current entitlement domain already names `advancedLocalInsights`, `purchasePreflight`,
  `postPurchaseReview`, `receiptScan`, and `receiptImport`, and every one requires the accepted
  Pro-subscription right through `FeatureAccessService`.
- DEC-COM-014 remains normative: the existing 30-day Insights screen, basic deterministic spending
  reminders, template fallback, and five-item wishlist remain Free. C4C-01 must add an advanced
  layer; it must not relabel those current features as paid.
- REQ-RECEIPT-PIPELINE-001 and REQ-RECEIPT-PRIVACY-001 remain active and not implemented. The five
  pipeline stages stay split across C4C-02 through C4C-05.
- SPEC-015 permits only normalized Vision geometry/confidence floating point in two exact reviewed
  future files. Amount parsing, currency, price, tax, tip, subtotal, total, and every other money
  path remain exact and outside that exception.

## C4C-01 — Premium seams and evidence

Status: **Done after independent review, green GitHub Actions run `32845307426`, and PR #66 merge
`8611022`.**

### Accepted implementation

- `ExistingPremiumEntryAccess` snapshots the central decisions for advanced local insight
  evidence, purchase-preflight/post-purchase future variants, receipt scan, receipt import, Apple
  on-device AI, the already accepted custom cooling-off choices, and advanced Siri. Feature code
  still never reads entitlement bits, Product IDs, or billing state.
- Existing deterministic insight bodies and reminders remain Free. Pro adds the evidence line only:
  supporting sample count, total sample count, and a confidence value in integer basis points.
- `RuleEvidence.confidenceBasisPoints` is the exact supporting-sample ratio
  `supportingSampleCount / sampleCount`, truncated to basis points. It is reproducible rule evidence,
  not a statistical probability and not a model-generated score. The two counts are retained so the
  displayed value can be recomputed independently.
- New rule evidence reuses the existing insight JSON payload through three reserved typed keys. A
  complete consistent triple is decoded into `SpendingInsightSummary.evidence` and removed from the
  ordinary presentation payload. Missing evidence remains readable for legacy rows; a partial,
  out-of-range, or mathematically inconsistent triple fails closed as invalid stored insight data.
- `LocalReceiptRecognitionBaseline` is a pure future-facing tier resolver: `.unavailable`,
  `.deterministic`, or `.deterministicWithOnDeviceModel`. Both usable tiers include deterministic
  extraction; there is no model-only or remote-model case.
  `FeatureFlags.enableReceiptImport` remains false in C4C-01, so the resolver creates no customer
  entry or image path.

### Free and failure behavior

- Free continues to record expenses, show exact budget impact, generate the existing deterministic
  reminder/review experience, render 30-day summaries/charts, and use local template fallbacks.
- Free does not see the new sample/confidence evidence line. Removing Pro hides that line without
  deleting local insight rows or changing financial facts.
- Missing local-model capability selects the deterministic tier after the later receipt product
  gate opens. Missing product scope or missing central receipt rights selects `.unavailable`.
- No stage may invent zero for missing OCR or receipt data, and nothing may persist before the
  C4C-05 confirmation boundary.

### Verification

- The central access matrix proves exact Free closes every new decision and Pro opens the accepted
  decisions. The receipt resolver proves product-off, Free, deterministic-only, and local-model-
  enhanced outcomes.
- Detector tests prove every newly generated rule carries evidence and verify nontrivial 3/4 and
  2/2 examples. Persistence tests prove round-trip separation from the ordinary payload and reject
  partial or inconsistent stored evidence.
- A Free regression proves the existing basic reminder, manual save, reminder history, and durable
  review row remain available.
- `Scripts/check-no-floating-point-money.sh` retains the App Intents transport exception and adds
  only two exact future Vision geometry/observation paths; any money vocabulary in those paths
  fails the gate.
- The final focused entitlement/rule/Free regression run passed 92/92. The full local validation at
  `/private/tmp/MindBudget-C4C01-Full.xcresult` passed Release, the strict wall-clock stage, 468 unit
  results across 27 suites, 17/17 UI tests, and every selected coverage threshold. `xcresulttool`
  reports 485 logical results, zero failures, 474 passes, and eleven explicit skips; the four
  physical-only CloudKit probes remain skips and are unrelated to C4C-01.

### Review closeout

- Independent review found no P1/P2 issue. The non-blocking invariant note remains explicit:
  generation currently uses `RuleEvidence.measured(...) ?? .exact` only after detectors establish
  `supportingSampleCount <= sampleCount`. A future refactor must expose any violation with a debug
  assertion and fail-closed behavior rather than treating an invalid ratio as genuine 1/1 evidence.
- The terms confidence/置信度 remain the approved integer-ratio presentation vocabulary from
  `COPY_GUIDELINES.md`; neither term represents statistical probability or model certainty.

## C4C-02 — Image acquisition and lifecycle

Status: **Done after independent review, green GitHub Actions run `32860643712`, and PR #68 merge
`4ca8f1c`.**

Own camera/DataScanner/photo-picker capability, orientation/perspective/downsampling/pixel limits,
cancellation, memory/background behavior, and temporary-file cleanup. It may not implement OCR or
persistence.

### Accepted implementation

- `ReceiptImageAcquisitionCapability` resolves the product-scope switch, central Pro receipt tier,
  camera authorization, DataScanner support, and current scanner availability before any system
  surface is created. Product scope remains disabled, so the merged app exposes no receipt entry
  and cannot request camera access. The permission request method is reserved for a later explicit
  camera-source action.
- The system adapter limits PHPicker to one image and requires no broad Photo Library permission.
  It reads the provider's temporary file with `FileHandle` only through the source-byte cap plus
  one sentinel byte, so an oversized selection is rejected before the whole representation is
  materialized. DataScanner is configured as a camera surface with no delegate and no recognized
  item crossing the adapter. Its recognized-data placeholder is barcode-only; no text recognition
  request or OCR result consumer exists in C4C-02.
- Source input is capped at 48 MiB and 64,000,000 metadata pixels before decode. ImageIO applies
  EXIF orientation while thumbnail-decoding to a 4,096-pixel maximum edge. A prepared image may
  contain at most 12,000,000 pixels and 8 MiB of JPEG bytes. All multiplications are overflow-
  checked; invalid, corrupt, zero-size, over-limit, or unencodable input fails closed.
- `VNDetectRectanglesRequest` is isolated to `ReceiptVisionObservation.swift`; it emits normalized
  geometry only. Core Image may apply perspective correction, but no text/field is detected. The
  two exact SPEC-015 files contain only non-money geometry/confidence floating point and are still
  rejected by the money gate if money vocabulary appears.
- `ReceiptImageLifecycle` permits only one generation and one prepared artifact. A replacement or
  caller cancellation cancels the older processing task; a generation check prevents late work
  from committing. Only the bounded prepared JPEG reaches the fixed temporary directory—never the
  source bytes. The directory is excluded from backup and uses complete file protection.
- Startup removes crash-orphaned bytes once. Cancel, background/inactive transition, memory
  warning, Delete All, downstream release, and AppSession teardown share the same idempotent
  cleanup boundary. SwiftUI task recreation cannot clear a later active artifact.

### Verification and closeout

- Ten focused tests cover product/Pro/permission/hardware availability, corrupt/byte/pixel-limit
  failures, orientation/downsampling bounds, perspective geometry rejection, deterministic
  lifecycle and caller cancellation while processing is suspended, startup orphan removal, and
  repeated proof that only prepared bytes exist before cleanup.
  `/private/tmp/MindBudget-C4C02-Focused5.xcresult` passed 10/10 on iPhone 17 Pro, iOS 26.5.
- The final complete local validation passed every static contract, Release compilation, the
  strict Dashboard wall-clock stage, 478 unit-test results across 28 suites, 17/17 UI tests, and
  every selected coverage threshold. CSVExporter was the minimum selected result at 87.60%.
- Independent review found no P1/P2 issue. Reviewed head `43c3a35` passed hosted GitHub Actions run
  `32860643712`, and PR #68 merged it to `main` as `4ca8f1c` on 2026-08-26 Singapore time.
- Documentation head `4ab0daf` passed hosted run `32911659905`, and PR #69 merged the closeout as
  `3e1c5c9` before the owner explicitly entered C4C-03.
- The review retained three non-blocking boundaries: scanner temporary-unavailability should gain
  a dedicated error when an actual UI consumes it; the system adapters remain dormant until a
  later packet creates a customer surface and physical evidence remains C4C-05 work; non-money
  image-quality floating-point literals do not widen the money exception.
- C4C-02 did not enter OCR automatically. The later owner instruction entered C4C-03 only; the
  product flag remains off and C4C-04/C4C-05 remain blocked.

## C4C-03 — OCR and pre-model privacy

Status: **Implementation complete pending independent review and hosted CI.**

Own local OCR geometry/order/confidence and removal of card numbers, last-four patterns, and
authorization codes before any model boundary.

### Accepted candidate boundary

- `VNRecognizeTextRequest` remains confined to `ReceiptVisionObservation.swift`, runs locally at
  accurate recognition, and automatically detects language. The adapter converts Vision output
  to normalized bounds, source index, and confidence without logging or publishing raw text.
- A raw observation may exist only inside the exact Vision adapter and the immediately invoked
  privacy pipeline. The only outward line type contains `ReceiptModelSafeText`, whose initializer
  is file-private to `ReceiptSensitiveTextFilter.swift`; another production file cannot construct
  a supposedly safe value from unfiltered text.
- The filter removes 13–19 Unicode-digit card-number shapes with common printed separators,
  explicitly labelled or masked last-four shapes in English and Simplified/Traditional Chinese,
  and labelled authorization/approval codes. Each removed span becomes the stable non-content
  marker `[redacted]`, preserving the line's geometry, order, and confidence without preserving
  the secret value. It intentionally does not require Luhn validity, so an OCR error over-redacts
  rather than allowing a plausible card value through.
- Observations are capped at 256, each input/output line at 512 UTF-8 bytes, and the filtered
  document at 16 KiB. Invalid normalized geometry, non-finite/out-of-range confidence, count/byte
  overflow, or filter failure rejects the complete document instead of emitting partial authority.
  Empty/control-only lines are omitted after control and whitespace normalization.
- Reading order is deterministic: normalized vertical midpoint is placed in a fixed 0.025-height
  band from top to bottom, then horizontal origin, Vision source index, and original array index
  break ties from left to right. No task scheduling or collection instability selects the order.

### Verification and stop conditions

- Seven focused tests at `/private/tmp/MindBudget-C4C03-ReviewFix-Focused5.hKVLun/MindBudget.xcresult` cover English, Simplified/
  Traditional Chinese, full-width digits, separated and masked card forms, authorization codes,
  the full-card-before-last-four ordering regression, ordinary text preservation, control
  normalization, deterministic ordering and tie-breaking, geometry/confidence retention, and
  fail-closed policy/count/line/document/geometry/confidence limits.
- The complete local validation passed every static contract, Release compilation, the strict
  Dashboard wall-clock stage, 485 unit-test results across 29 suites, all 17 UI tests, and every
  selected core-service coverage threshold. CSVExporter was the minimum selected result at 87.60%
  against the required 85%; four physical-only CloudKit probes remained explicit skips.
- Static contracts allow raw Vision OCR symbols only in the exact adapter, allow filtered OCR
  types only inside the dormant receipt-recognition directory, retain the two exact non-money
  floating-point files, and reject any receipt model/network/persistence expansion.
- `FeatureFlags.enableReceiptImport` remains false. This candidate adds no customer surface,
  permission prompt, SwiftData/CloudKit field, model call, HTTP(S), telemetry, receipt accuracy
  claim, physical OCR claim, Production action, or distribution authority. C4C-04 and C4C-05 stay
  blocked until this exact source passes independent review, green hosted CI, and merge.

## C4C-04 — Structured extraction and validation

Status: **Blocked by C4C-03.**

Own deterministic extraction fallback, optional local-model enhancement, core-field generation,
exact amount/date/currency/scale/duplicate validation, and the default-off line-item experiment.

## C4C-05 — Mandatory confirmation and evaluation

Status: **Blocked by C4C-04.**

Own the no-persistence-before-confirmation proof, 60+ fixed receipts and non-receipts, offline tier
matrix, zero-leak privacy evidence, accuracy gates, and 20-image resource stability.

## Exit and stop conditions

Each subpacket may be marked Done only after independent review, green hosted CI on the reviewed
head, and merge. C4C-02 closes only acquisition/lifecycle infrastructure. It does not enable
receipt import, satisfy either receipt Requirement, enter C4C-03 automatically, close COM-C4C,
unblock COM-C5, deploy Production, or authorize Archive/upload/tester/review/distribution actions.
