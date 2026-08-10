# COM-C0A Specification Lock and Repository Audit

## Result

**COM-C0A: Done. Owner decision gate closed on 2026-08-10.**

COM-C0A inspected the approved commercialization specification and the current repository,
reproduced the release/test baseline, created the requirement and conflict registers, and made no
product-code, schema, StoreKit product, CloudKit container, backend, telemetry, Watch target, or
model-provider change. The owner subsequently accepted SPEC-012, SPEC-013, SPEC-014, and SPEC-017.
COM-C0B is ready but has not started.

## Locked inputs and precedence

- Commercial source: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`.
- Source SHA-256: `290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`.
- `SOURCE_PROVENANCE.md` records the external-file boundary and the manual stop/re-audit procedure;
  this fingerprint identifies the audited input but does not make that external file visible to CI.
- Audited repository baseline: `main` commit
  `6226823370d9ecaedfd89f2754e1f5705dc8d5dd` (PR #23 merge).
- Current repository memory remains authoritative for the behavior of the existing 0.9.x binary.
  The v1.4 specification is authoritative for the new commercialization track only after its
  conflicts are explicitly resolved; it does not retroactively rewrite Phase 0–12 history.
- The stale embedded v1.3/`PHASE_0A_REPORT.md` prompt inside v1.4 is superseded by the current
  top-level COM-C0A contract. See SPEC-016.

## Reproducible baseline

The selected Xcode is not the machine's default `xcode-select` path. Reproduction requires the
explicit developer directory below:

```bash
DEVELOPER_DIR=/Users/shaola/Downloads/软件/Xcode.app/Contents/Developer \
  xcodebuild -version

Scripts/check-no-floating-point-money.sh

DEVELOPER_DIR=/Users/shaola/Downloads/软件/Xcode.app/Contents/Developer \
MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1 \
  Scripts/validate.sh
```

Observed on 2026-08-10:

- Xcode 26.6 (`17F109`), Swift 6.3.3, project language mode Swift 6.0.
- iPhoneOS and iPhoneSimulator SDK 26.5; minimum deployment target iOS 17.0.
- Generic iOS Simulator Release build passed.
- Complete Swift Testing suite passed with zero functional failures. The established strict local
  500 ms wall-clock signal was excluded because shared-host load is nondeterministic; its
  deterministic 10,000-row contract still ran.
- All 13 UI tests passed with zero failures.
- Money lexical gate and release-readiness gate passed.
- Selected coverage gate passed at 85% minimum: Money 91.73%, BudgetEngine 95.18%,
  BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
  ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%,
  CycleSummaryService 97.42%, IntentClassifier 97.50%, CSVExporter 87.60%, and
  CurrencyFormatterService 100%.

The default `/Library/Developer/CommandLineTools` selection cannot build this iOS project. CI and
release instructions must therefore continue to select/assert a full supported Xcode rather than
assuming the host default.

## Project, signing, and distribution inventory

| Item | Audited value |
|---|---|
| App bundle identifier | `com.xdgf558.MindBudget` |
| Current source version | 0.9.6 (7) |
| Targets | iPhone app, unit tests, UI tests |
| Device family | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) |
| Signing style | Automatic |
| Developer team | Local ignored override `2AM5S7BM2N`; no team ID committed |
| Package dependencies | None |
| Watch target/extension | None |
| Entitlements file | None |
| CloudKit capability/container | None |

The v1.4 example Product ID domain is not the app's actual namespace. No StoreKit product,
subscription group, or catalog is present, but the owner has accepted the technical identifier
family derived from the app's namespace: `com.xdgf558.mindbudget.pro.monthly` and
`com.xdgf558.mindbudget.pro.annual`, under the internal reference group `MindBudget Pro`.

## Data and migration inventory

The current SwiftData plan is a lightweight, staged V1 → V2 → V3 → V4 migration. V4 contains 15
models:

1. `Expense`
2. `Income`
3. `IncomeAllocation`
4. `SavingsGoal`
5. `RecurringFixedExpenseRule`
6. `RecurringExpenseOccurrence`
7. `BudgetPlan`
8. `BudgetPlanSemantics`
9. `CategoryBudget`
10. `WishItem`
11. `CoolingOffPlan`
12. `SpendingInsight`
13. `ReflectionLog`
14. `Merchant`
15. `ReminderEvent`

V1 contains the original nine models, V2 adds income, V3 adds income allocation, cross-cycle
savings and recurring-expense models, and V4 adds explicit budget-plan semantics. No destructive
migration is currently justified by v1.4: the existing money representation already satisfies the
core exactness invariant. COM-C4A must begin with a delta/rollback audit rather than replacing the
working store.

`SchemaV4.models`, `DataActor.modelCounts()`, and `deleteAllLocalModels()` enumerate the same 15
types. Delete All verifies an observed all-zero result and fails closed. The privacy review notes
still describe ten types and must be corrected in COM-C0B (SPEC-018).

## Money and financial-computation audit

- Money is `Int64` minor units plus a supported ISO currency code.
- The supported currency table covers 0-, 2-, and 3-decimal exponents; amount conversion, parsing,
  aggregation, and budget calculations avoid floating point.
- Cross-currency operations, unsupported precision, invalid persisted values, and overflow fail
  explicitly. The storage-safety ceiling is currency-neutral.
- The only current documented `Double` boundary is the App Intents transport adapter, which
  converts and validates before entering money-domain code.
- Persisted thresholds use integer basis points; deterministic finance/rule code remains
  authoritative and Foundation Models only rewrites allow-listed facts.
- No legacy decimal/double money column requiring a v1.4 conversion was found.

**UNVERIFIED for COM-C4A:** production-store backup/restore and interruption rehearsal for a future
commercial migration. **Blocked before COM-C4C:** the current lexical script rejects all
`Double`/`Float` in app Swift files, while Vision geometry/confidence is legitimately non-money
floating point (SPEC-015).

## StoreKit and entitlement audit

There is no `StoreKit` import, `.storekit` configuration, entitlement domain, paid feature-access
service, purchase/restore UI, transaction listener, receipt/JWS validation, subscription cache,
paywall, trial, quota, or Lifetime product. The current TestFlight population has no production
Pro rights to preserve, matching the owner's rule that test rights do not carry into production.

The future implementation must use one lifecycle owner for
[`Transaction.updates`](https://developer.apple.com/documentation/storekit/transaction/updates),
map only subscribed/grace states to subscription rights, and separate transaction identity from
current server entitlement. Product IDs are accepted, while price, trial, quota, regional
availability, and formal-product creation remain **UNVERIFIED**. SPEC-014's accepted three-stage
economics gate controls when configuration-only versus formal products may be created.

## iCloud and local-data authority audit

The current app has no CloudKit import, entitlement, container, schema, sync engine, tombstone,
cloud deletion, or multi-device conflict implementation. SwiftData/DataActor is the only ledger
authority. This makes the current local-only statements accurate. Under accepted SPEC-012, a later
Free opt-in iCloud channel becomes permissible only after its authorization, disclosure, deletion,
and release gates pass; the existing version remains unchanged.

**UNVERIFIED:** `CKSyncEngine` versus another supported CloudKit architecture, record zones,
stable record identifiers, tombstone/conflict rules, first-enable upload semantics, account/quota
transitions, and local/cloud Delete All behavior. Apple recommends choosing sync architecture from
the app's actual data/control needs; COM-C0B must record the decision before COM-C4B design. No
current iCloud/Watch double-write risk exists because neither channel exists.

## Receipt, camera, Photos, and local-model audit

There is no Vision, VisionKit, DataScanner, camera, PhotosUI/PHPicker, receipt image, OCR pipeline,
or receipt persistence. `FeatureFlags.enableReceiptImport` is false. No camera/photo usage string
or background mode is declared.

Foundation Models is present only behind conditional import, iOS/runtime availability, explicit
default-off user settings, and locale support. Every path has a deterministic localized template
fallback. Typed redacted contexts exclude notes, transaction rows, merchant lists, receipt data,
and raw questions; generated output is checked for allowed language, numbers, percentages, length,
and actions. The release app has no third-party model SDK or provider endpoint.

Receipt recognition, image lifetime, OCR ordering/confidence, sensitive-pattern removal, duplicate
detection, mandatory confirmation, evaluation corpus, and resource limits are all **not
implemented** and belong to COM-C4C only.

## Network, telemetry, backend, and third-party audit

No business `URLSession`/HTTP implementation, third-party SDK/package, analytics SDK, telemetry
event queue, remote config, backend URL, API key, Cloudflare binding, provider routing, or cloud-AI
request exists. Repository and history scans found no high-confidence committed secret or tracked
secret-like configuration; `Config/Local.xcconfig` is ignored.

Current privacy declarations say no tracking and no collected data, and the privacy manifest lists
only the declared UserDefaults required-reason API. Those claims must be revised only when an
approved channel actually ships; they cannot describe future telemetry/iCloud/cloud AI early.
Accepted SPEC-012 establishes that phase-scoped boundary. A future backend must be independent
from the owner's other service and may share patterns, not data, secrets, authorization state, or
deployment state.

## Logging, export, deletion, permissions, and data protection

- No `print`, `debugPrint`, `Logger`, or `os_log` content logging was found in app source.
- Debug AI diagnostics retain counters/reasons only and are excluded from Release UI.
- CSV export is explicit, ephemeral, exact, spreadsheet-injection protected, and openly discloses
  that raw notes/source/merchant fields may be included. It does not enter model context.
- Delete All is ordered, confirmed, fail-closed, and verifies all current model counts.
- Face ID uses LocalAuthentication and has an app-lock purpose string; no biometric material is
  stored.
- No camera/photo/background entitlement currently expands the privacy surface.

**UNVERIFIED:** signed-device file-protection behavior after reboot/lock and whether a future
iCloud/receipt/telemetry implementation preserves the current deletion guarantee. This remains a
manual release/security gate.

## Watch readiness audit

There is no Watch app, extension, WatchConnectivity session, shared package, complication, Watch
privacy surface, Watch outbox, or Watch entitlement mapping. The current iPhone code is organized
for app reuse in places, but it is not yet extracted into a cross-platform target. COM-C6.5 must
explicitly define the reusable exact-money/domain subset and keep iPhone as the single authority.

Apple's [`WCSession`](https://developer.apple.com/documentation/watchconnectivity/wcsession)
delivery modes have different reachability and persistence semantics; the v1.4 outbox,
idempotency, acknowledgement, and conflict rules are therefore necessary rather than optional.
Accepted SPEC-013 permits intermediate/parallel Watch development, makes it nonblocking for G1 and
the iPhone 1.0 launch, and defers Watch distribution to a separate post-iPhone-release milestone.

## Requirement and conflict status

- Stable core Requirement IDs and acceptance evidence are in
  `Docs/Commercialization/REQUIREMENTS_INDEX.md`.
- Historical and open conflicts are in `Docs/Commercialization/SPEC_CONFLICTS.md`.
- Accepted on 2026-08-10: SPEC-012 (phase-scoped data/network policy), SPEC-013 (Watch development
  may be parallel; distribution is post-iPhone 1.0), SPEC-014 (three-stage economics gate), and
  SPEC-017 (canonical Product IDs).
- Open P1 for later phases: SPEC-015 (money lint versus Vision) and SPEC-018 (privacy deletion
  documentation).

## Owner decisions recorded after the audit

1. Existing versions remain unchanged. Later channels may be enabled only after user
   authorization, privacy disclosure, deletion, and release gates pass.
2. Watch development may occur in the middle/parallel phase, does not block G1/cloud/iPhone 1.0,
   and is distributed only as a separate post-iPhone-formal-release milestone.
3. The three-stage product/economics gate is accepted.
4. Product IDs are `com.xdgf558.mindbudget.pro.monthly` and
   `com.xdgf558.mindbudget.pro.annual`; group reference is `MindBudget Pro`.

## Recommended next order

1. On an explicit owner instruction, begin COM-C0B and create commercialization-specific
   memory/decisions and update the root/privacy
   rules only from accepted conflict resolutions.
2. Define the Release egress allow-list, AI provider contract, StoreKit environment matrix,
   pricing/cost worksheet, and accepted CloudKit architecture. Prices and quotas remain TBD.
3. Convert COM-C1 into small PR-ready packets and begin entitlement-domain code only after every
   C1 Requirement is Active and unblocked.

No COM-C0B or product implementation was started by this audit.
