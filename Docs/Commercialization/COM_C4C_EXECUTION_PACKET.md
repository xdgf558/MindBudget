# COM-C4C Execution Packet — Local Pro and Receipt Recognition

## Status

Status: **In Progress — C4C-01 closed through PR #66 (`8611022`); explicit owner entry is required
before C4C-02 begins.**

COM-C4B closed through reviewed PR #64 (`4f6d7fe`) and the documentation closeout merged through
PR #65 (`f5ab156`). Reviewed C4C-01 head `d203308` passed GitHub Actions run `32845307426`, and
PR #66 merged it as `8611022`. This merged packet adds no camera/photo permission,
Vision/VisionKit/PhotosUI import, receipt image, OCR, temporary image file, receipt persistence,
iCloud receipt field, model prompt, network channel, Production action, or release authority.

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

Status: **Blocked pending explicit owner entry after the reviewed C4C-01 merge.**

Own camera/DataScanner/photo-picker capability, orientation/perspective/downsampling/pixel limits,
cancellation, memory/background behavior, and temporary-file cleanup. It may not implement OCR or
persistence.

## C4C-03 — OCR and pre-model privacy

Status: **Blocked by C4C-02.**

Own local OCR geometry/order/confidence and removal of card numbers, last-four patterns, and
authorization codes before any model boundary.

## C4C-04 — Structured extraction and validation

Status: **Blocked by C4C-03.**

Own deterministic extraction fallback, optional local-model enhancement, core-field generation,
exact amount/date/currency/scale/duplicate validation, and the default-off line-item experiment.

## C4C-05 — Mandatory confirmation and evaluation

Status: **Blocked by C4C-04.**

Own the no-persistence-before-confirmation proof, 60+ fixed receipts and non-receipts, offline tier
matrix, zero-leak privacy evidence, accuracy gates, and 20-image resource stability.

## Exit and stop conditions

C4C-01 may be marked Done only after independent review, green hosted CI on the reviewed head, and
merge. That closes only premium seams/evidence. It does not enable receipt import, satisfy either
receipt Requirement, enter C4C-02 automatically, close COM-C4C, unblock COM-C5, deploy Production,
or authorize Archive/upload/tester/review/distribution actions.
