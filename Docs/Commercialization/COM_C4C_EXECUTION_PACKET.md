# COM-C4C Execution Packet — Local Pro and Receipt Recognition

## Status

Status: **In Progress — C4C-05 owner entry accepted; local implementation/evaluation candidate is
in progress pending physical acquisition/OCR evidence, independent review, hosted CI, and merge.**

COM-C4B closed through reviewed PR #64 (`4f6d7fe`) and the documentation closeout merged through
PR #65 (`f5ab156`). Reviewed C4C-01 head `d203308` passed GitHub Actions run `32845307426`, and
PR #66 merged it as `8611022`; documentation closeout head `55a321c` passed Actions run
`32850616400`, and PR #67 merged it as `bdb94d9`. The owner then explicitly entered C4C-02.
Reviewed C4C-02 head `43c3a35` passed Actions run `32860643712`, and PR #68 merged it as
`4ca8f1c`. Documentation head `4ab0daf` passed run `32911659905`, and PR #69 merged that closeout
as `3e1c5c9`. C4C-02 is Done. The owner then explicitly entered C4C-03. Reviewed head `92ed3a7`
passed GitHub Actions run `32921913143`, and PR #70 merged the bounded
local OCR/privacy boundary as `d294cfb`. C4C-03 is Done. PR #71 merged its documentation closeout
as `08fb718`, and the owner then explicitly entered C4C-04. Reviewed remediation head `f2d249d`
passed GitHub Actions run `32946104780`, and PR #72 merged the bounded structured-extraction
implementation as `e6316fa`; PR #73 merged its documentation closeout as `2107723`. C4C-04 is
Done. The owner then explicitly entered C4C-05. The current candidate adds only a verified-Pro,
local customer entry and confirmation/evaluation boundary; there is still no iCloud receipt field,
remote model, network channel, Production action, or release authority.

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
- C4C-02 did not enter OCR automatically. The later owner instruction entered C4C-03 only; at that
  decision's time the product flag stayed off and C4C-04/C4C-05 remained blocked. The current
  C4C-04 entry is recorded separately below.

## C4C-03 — OCR and pre-model privacy

Status: **Done after independent review, green GitHub Actions run `32921913143`, and PR #70 merge
`d294cfb`.**

Own local OCR geometry/order/confidence and removal of card numbers, last-four patterns, and
authorization codes before any model boundary.

### Accepted implementation boundary

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
  claim, physical OCR claim, Production action, or distribution authority.
- Independent review found no P1/P2 issue. The one accepted P3 hardening documents and tests the
  complete-card-before-last-four rule order; exact review-fix head `92ed3a7` passed hosted run
  `32921913143`, and PR #70 merged it as `d294cfb` on 2026-08-26 Singapore time.
- The remaining non-blocking observations stay at their later boundaries: 20-plus uninterrupted
  digits are not a 13–19 digit PAN shape; spaced mask formats belong in the C4C-05 fixture matrix;
  regex caching is optional bounded optimization; and an actual C4C-04 caller must execute Vision
  work away from the main actor. None is receipt accuracy or physical evidence.
- The owner separately entered C4C-04 after the reviewed C4C-03 documentation merge. C4C-05 stays
  blocked; the C4C-03 merge itself did not infer that later entry or authorize confirmation/
  evaluation, Production, distribution, or release work.

## C4C-04 — Structured extraction and validation

Status: **Done after independent rereview, green GitHub Actions run `32946104780`, and PR #72
merge `e6316fa`.**

Own deterministic extraction fallback, optional local-model enhancement, core-field generation,
exact amount/date/currency/scale/duplicate validation, and the default-off line-item experiment.

Accepted implementation boundary:

- Deterministic extraction always runs first and remains authoritative. It emits explicit
  missing/rejected states; it never converts an uncertain or absent amount into zero.
- The optional Foundation Models adapter receives only `ReceiptOCRDocument` text that already
  crossed C4C-03 privacy filtering. It may select exact contiguous evidence snippets only.
  Deterministic code verifies snippet provenance and performs all merchant/date/currency/scale/
  minor-unit/range/duplicate decisions. Timeout, unavailability, invalid evidence/output, or model
  failure returns the deterministic result.
- Money parsing uses supported ISO currency exponents and integer minor units only. Dates use the
  supplied `Calendar`, time zone, locale punctuation, and explicit month/day order. Duplicate
  detection requires exact normalized merchant, calendar date, amount, and currency agreement.
- The line-item experiment is structurally present but defaults off. All structured output remains
  ephemeral; there is no UI, confirmation, persistence, logging, iCloud field, or network path.
- The 17-test focused suite covers deterministic core fields, locale punctuation, USD/JPY/KWD
  scale, mismatch/range rejection, missing/ambiguous/invalid values, exact duplicates, model
  provenance/precedence/fallback, same-line mixed-validity failure, deterministic rejection
  authority, default-off line items, and unavailable/invalid contexts.
- The C4C-03 carryover remains: the future C4C-05 integration caller must run Vision recognition
  away from the main actor. C4C-04 begins after an already-safe `ReceiptOCRDocument` and does not
  create a Vision caller.

### Review closeout

- Independent review found no P1 issue and two P2 fail-closed inconsistencies. Same-line amount
  evidence now rejects the field when any numeric token fails parsing, and optional-model
  supplementation now applies only to deterministic `.missing`; deterministic `.accepted` and
  `.rejected` remain final.
- The exact remediation source passed 17/17 focused tests and the complete local validation entry:
  502 unit-test results across 30 suites, 17/17 UI tests, Release compilation, the strict
  Dashboard wall-clock stage, all static contracts, and every selected coverage threshold.
- Independent rereview approved exact remediation head `f2d249d`. GitHub Actions run
  `32946104780` completed successfully on that exact head, and PR #72 merged it to `main` as
  `e6316fa` on 2026-08-26 Singapore time.
- Remaining accuracy-shape observations stay with the C4C-05 fixture matrix: generic three-letter
  uppercase markers and broad `total` label matching must be evaluated against real fixtures;
  physical acquisition/OCR, off-main integration, confirmation-before-persistence, 60-plus
  receipts/non-receipts, and 20-image stability remain unclaimed. No customer or release gate was
  opened by this merge.

## C4C-05 — Mandatory confirmation and evaluation

Status: **In Progress after explicit owner entry; physical acquisition/OCR evidence, independent
review, hosted CI, and merge remain pending.**

Own the no-persistence-before-confirmation proof, 60+ fixed receipts and non-receipts, offline tier
matrix, zero-leak privacy evidence, accuracy gates, and 20-image resource stability.

### Accepted candidate boundary

- Only a verified Pro Commerce snapshot exposes `Scan a Receipt` inside the existing new-expense
  form. Editing an existing expense, wishlist conversion, exact Free, and unavailable StoreKit
  authority do not expose the entry.
- Camera permission is requested only after an explicit camera choice; PHPicker remains one-image
  and does not request broad Photo Library access. DataScanner captures one still image and exports
  no recognized item. Unsupported, denied, temporarily unavailable, corrupt, over-limit, canceled,
  or backgrounded work fails closed with a localized retry/manual-entry path.
- Image preparation, accurate Vision OCR, sensitive-text filtering, and deterministic structured
  extraction execute locally. Vision work runs off the main actor. The optional on-device model is
  selected only when the existing user setting is on and the Apple system model is actually
  available; otherwise the deterministic offline tier remains usable.
- One bounded protected temporary JPEG exists only during processing and is discarded before a
  result is presented. Source bytes, prepared images, raw/filtered OCR, model snippets, line items,
  and duplicate evidence never enter SwiftData, iCloud, logs, telemetry, or a network channel.
- Review may copy only accepted merchant/date/total fields into the editable expense form. This is
  still ephemeral. Only the form's existing explicit Save action creates the `Expense`, preserving
  existing exact-money, budget, duplicate-warning, reminder, and validation paths. Receipt-created
  expenses carry only the non-content provenance value `receiptImport`.

### Deterministic evaluation contract

- A checked-in fixed matrix contains 60 supported receipts: 20 USD, 20 JPY, and 20 KWD examples.
  Every case must exactly match merchant, calendar date, ISO currency, and integer minor units.
  Ten fixed non-receipts—including `Totally`, generic `USA`/`THE`/`IBM`, list/note, subtotal-only,
  and date-only shapes—must not produce an accepted total. These are deterministic contract
  fixtures, not a population-wide OCR accuracy claim.
- The privacy suite includes English/Chinese card, separated/full-width PAN, authorization code,
  labelled last-four, continuous mask, and spaced-mask examples. Zero sensitive digits or codes may
  reach `ReceiptModelSafeText`; any unsafe/unbounded input rejects the whole document.
- The offline matrix keeps product-off and exact Free unavailable, verified Pro deterministic-only
  usable, and verified Pro with an available/user-enabled local model enhanced without weakening
  deterministic authority. Missing model capability never disables the deterministic tier.
- Twenty sequential real JPEG decode/orientation/perspective/downsample/store/cleanup operations
  must remain within the fixed byte/pixel limits, keep at most one artifact, and leave none after
  each cleanup. This proves bounded lifecycle stability, not physical camera or public-receipt
  accuracy.

### Local validation evidence

- `/private/tmp/MindBudget-C4C05-Focused.xcresult` passes 40/40 results across the four receipt
  suites with zero failures or skips. It includes the fixed 60-receipt/10-nonreceipt matrix,
  prefill-before-Save database proof, zero-leak regression, and 20-image lifecycle run.
- `/private/tmp/MindBudget-C4C05-Full.xcresult` passes the complete repository entry: 508 unit-test
  results (497 passed and 11 explicit opt-in/runtime skips), all 17 UI tests, Release compilation,
  the strict 10,000-row Dashboard wall-clock stage, every static contract, and every selected
  coverage threshold. CSVExporter is the minimum selected result at 87.60% against 85%.
- Both are simulator/deterministic evidence only. Neither substitutes for the physical acquisition
  and OCR evidence below.

### Open evidence

- Physical DataScanner capture, PHPicker selection, and resulting local OCR remain mandatory C4C-05
  evidence and are not recorded as passed by the simulator matrix. Until that run, the candidate is
  not ready to be marked implementation-complete or Done.
- Independent review, hosted CI on the exact reviewed head, and merge are still required. C4C-05
  does not deploy Production, authorize Archive/TestFlight/App Store actions, or enter COM-C5.

## Exit and stop conditions

Each subpacket may be marked Done only after independent review, green hosted CI on the reviewed
head, and merge. C4C-02 closes acquisition/lifecycle infrastructure, C4C-03 the local OCR/pre-model
privacy boundary, C4C-04 ephemeral structured extraction, and C4C-05 the reviewed local customer
confirmation/evaluation boundary. C4C-05 is not complete while physical acquisition/OCR evidence
is open. Nothing here enters a successor automatically, closes COM-C4C, unblocks COM-C5, deploys
Production, or authorizes Archive/upload/tester/review/distribution actions.
