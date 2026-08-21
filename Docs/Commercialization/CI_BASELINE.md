# Commercialization CI Baseline

## Purpose

This file fixes the reproducible build/test baseline inherited by every COM phase. It records
evidence locations; it does not lower an existing product gate or authorize product behavior.

Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`, SHA-256
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`.
`SOURCE_PROVENANCE.md` records this as an external-input audit fingerprint. CI verifies the frozen
repository snapshot and does not claim access to the owner's external specification.

## Accepted baseline

- Baseline commit audited by COM-C0A: `6226823370d9ecaedfd89f2754e1f5705dc8d5dd`.
- Toolchain: Xcode 26.6 final (`17F113`), Swift 6.3.3, iOS SDK build `23F81a`.
- Deployment target: iOS 17.0; iPhone only.
- CI runner: `macos-26`, with an explicit Xcode 26.6-or-newer assertion.
- Required commands:

  ```bash
  Scripts/check-no-floating-point-money.sh
  Scripts/check-network-egress.sh
  Scripts/check-commercialization-docs.sh
  Scripts/check-storekit-test-catalog.sh
  Scripts/validate.sh
  ```

- `Scripts/validate.sh` continues to run the existing release-readiness gate, the isolated
  StoreKit test-catalog gate, Release build,
  build-for-testing, Swift Testing/UI tests, and coverage thresholds. The COM documentation gate
  is additive and contains no app behavior.
- The StoreKit catalog gate parses scheme XML and balanced `pbxproj` objects rather than assuming
  one-line formatting. Its Shell entry is a thin wrapper around the independently runnable and
  importable `Scripts/storekit_catalog_contract.py`; a normal Python `unittest` suite proves the
  same functions accept a test-bundle-only fixture and reject app-resource, default-scheme, and
  Archive-capable fixtures before the repository contract is checked.

## COM-C0A measured coverage

| Component | Line coverage |
|---|---:|
| Money | 91.73% |
| BudgetEngine | 95.18% |
| BudgetCycleCalculator | 95.17% |
| SpendingPatternDetector | 97.57% |
| ReminderThrottle | 96.84% |
| ReminderEngine | 91.02% |
| AdviceSafetyValidator | 96.15% |
| PrivacyRedactor | 91.91% |
| CycleSummaryService | 97.42% |
| IntentClassifier | 97.50% |
| CSVExporter | 87.60% |
| CurrencyFormatterService | 100.00% |

These numbers are a regression reference, not permission to weaken the thresholds in
`Scripts/check-coverage.sh`. Later phases must explain a material drop and add tests before
changing production behavior.

## COM-C0B verification

On 2026-08-10, Xcode 26.6 passed the additive commercialization-doc gate, the unchanged money
gate, release-readiness checks, generic Release simulator build, 270 Swift tests in 17 suites, all
13 UI tests, and the coverage gate. The result bundle was written to the documented local path
`TestResults/Commercialization/COM-C0B/local/MindBudget.xcresult`. The strict hosted wall-clock
signal was skipped through the existing documented switch; its deterministic 10,000-row contract
still passed. No product source/schema/resource or user-visible behavior changed in COM-C0B.

## COM-C2-02 verification

On 2026-08-12, Xcode 26.6 passed the complete static, Release-build, Swift Testing, UI, and
coverage pipeline for the runtime catalog and entitlement-store implementation plus its focused
review remediation. The run passed 306 selected Swift tests in 20 suites and all 13 UI tests with
zero failures; every selected core-service coverage threshold remained above 85%. The extracted
StoreKit contract suite passed all 12 Python tests. Focused runtime tests covered exact-context
presentation caching and deletion, malformed/partial catalogs, startup reconciliation, one
transaction-update listener, concurrent whole-snapshot reads, fail-closed mixed/unverified/
unknown/revoked states, stale-reconciliation suppression, preservation of a past expiration date
for C2-03's status mapper, and direct AppSession Free -> Pro -> Free UI snapshot propagation.

Two `Product.products(for:)` storefront probes are deliberately excluded from the default scheme
and are enabled only by the non-Archive `MindBudget-StoreKit-Local` scheme. Focused review ran the
dedicated Test action under the installed Xcode 26.6 RC build `17F109` and iOS 26.5. Both probes
executed, `SKTestSession` emitted `SKInternalErrorDomain Code=3` while synchronizing the local
configuration/storefront, and `Product.products(for:)` returned an empty set. A trial change that
inherited Launch arguments made the command green only by dropping the Test-action opt-in and
skipping both probes; that change was rejected, and the scheme contract now rejects this false-
green shape. Therefore CHN/USA framework-backed product loading is **not** claimed as passing
evidence in this packet. C2-03 has a hard entry gate requiring both probes to execute and pass
under a supported final Xcode toolchain, preferably the Xcode GUI while the iOS 26.5 CLI failure
remains reproducible. Default validation reports the probes as skipped rather than manufacturing
a pass.

Post-merge probe revalidation used final Xcode 26.6 build `17F113`. Both CHN and USA probes
executed on final iOS 26.4 and 26.5 runtimes, but `Product.products(for:)` again returned empty
sets with `SKInternalErrorDomain Code=3`; contemporaneous `storekitd` diagnostics reported an
Octane entitlement/development-install handshake failure. The installed iOS 26.5 runtime is build
`23F77`, while final Xcode's SDK is build `23F81a`. Apple currently offered only an export of the
older runtime build `23F73`; it was not imported and could not provide an alternate supported-
runtime execution surface. Direct download queries for build `23F81` and iOS `26.5.1` both
returned unavailable. The identical dedicated scheme passes all 16 tests
in 2 suites on an iOS 27 beta runtime. That beta result is useful diagnostic evidence that the
fixture and test code can execute, but it is not accepted evidence for the supported-final-runtime
entry gate. The historical RC failure above remains part of the record; no final-runtime pass is
claimed.

After the machine-wide `xcode-select` was switched to final Xcode `17F113` and the Mac restarted,
the dedicated iOS 26.5 `23F77` run executed 5 catalog tests: 3 passed, while the CHN and USA probes
both executed without skipping and failed with the same `Code=3`/empty-product result. The earlier
auxiliary `xcrun`/`simctl` lookup error disappeared, proving the global toolchain is now coherent
but was not the StoreKit failure's root cause. Evidence is retained at
`/private/tmp/MindBudget-C2-02-Restart-17F113-iOS26.5-23F77.xcresult` and
`/private/tmp/mindbudget-storekit-restart-17F113-ios265-23F77.log` for this local session.

No purchase, restore, transaction finishing, customer term, paywall, schema, app-owned network
destination, Archive, upload, tester, or distribution state was introduced or changed. PR #29
passed independent review and green CI, then merged as `a45d480` on 2026-08-12; C2-02 is Done.
C2-03 was still blocked at the conclusion of C2-02; the separate physical-device evidence below
subsequently satisfied that entry gate.

## COM-C2-03 entry-gate verification

On 2026-08-13, final Xcode 26.6 build `17F113` ran the dedicated non-Archive
`MindBudget-StoreKit-Local` scheme on the physical `拉沙的iPhone` (`iPhone Air`) with final
iOS 26.6.1 build `23G82`. All 5 catalog tests passed with 0 failed and 0 skipped. Both the CHN and
USA `Product.products(for:)` runtime probes executed and passed; neither returned an empty product
set or `SKInternalErrorDomain Code=3`. Independent `xcresulttool` parsing confirmed the physical
arm64 device, OS/build, each named test, and the 5/0/0 totals. Evidence:
`/private/tmp/MindBudget-C2-03-Physical-Unlocked-iOS26.6.1-17F113.xcresult`.

This supported-final physical-device pass opens C2-03 implementation. It introduces no C2-03
source, purchase, restore, transaction finish, subscription-status decision, paywall, formal
product/term, version, Archive, upload, tester, or distribution change. The post-0.9.6 release
hold remains active.

## COM-C2-03 implementation candidate verification

The merged C2-03 implementation adds a
single `EntitlementStore` lifecycle authority, full verified status/renewal mapping, explicit
typed purchase and restore seams, authoritative whole-snapshot publication before transaction
finish, and retry for transactions that remain unfinished. One lifecycle task supervises both
`Transaction.updates` and `Product.SubscriptionInfo.Status.updates`; a status signal triggers a
fresh full reconciliation through the same authority without creating a second authority or UI.
Deterministic focused tests cover the
state table, pending/cancel/error outcomes, restore outcomes, duplicate/concurrent delivery,
operation serialization, finish ordering/failure, and unfinished startup processing. Opt-in local
StoreKit probes cover Monthly/Annual seeded transaction verification, authority publication, and
finish. Presented `Product.purchase()` remains a C3 UI-host obligation. A forced-renewal grace
experiment terminated the hosted runner before completion and was removed; deterministic state
tests cover the mapper without claiming a framework transition pass.

Local C2-03 validation is complete. The focused lifecycle/runtime run passed 44/44 tests, and the
31-test lifecycle suite passed 10 consecutive iterations (310/310). The strict 500 ms local
Dashboard wall-clock signal also passed 10/10 isolated iterations. The owning full run used the
repository's documented shared-host switch to exclude only that already-isolated wall-clock
signal while retaining the deterministic 10,000-row projection contract. It completed 342 Swift
tests with zero failures (338 passed and 4 explicit opt-in StoreKit runtime probes skipped), all
13 UI tests, and the full coverage gate. The combined result summary is 355 total, 351 passed,
4 skipped, and 0 failed. Evidence:
`/private/tmp/MindBudget-C203-Full-Final15.xcresult`.

Selected line coverage was Money 91.73%, BudgetEngine 95.18%, BudgetCycleCalculator 95.17%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 91.04%,
AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService 97.45%,
IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100.00%; every selected
file remains above the 85% gate. The four skipped probes remain opt-in dedicated-scheme/device
evidence and are not reclassified by this default-scheme run. PR #30 subsequently passed
independent review and the complete GitHub Actions validation in 14m26s, then merged to `main` as
`3fc72b4` on 2026-08-13. CI run:
<https://github.com/xdgf558/MindBudget/actions/runs/31675470258>. C2-03 is Done. C2-04 later passed
its own independent review and green CI and merged through PR #31 as `a293762`.
Paywall/customer purchase presentation, formal products/customer terms, versioning, Archive,
upload, tester assignment, and distribution remain blocked. The post-0.9.6 release hold remains active.

## COM-C2-04 implementation verification

C2-04 binds each whole entitlement read to a separately verified `AppTransaction` bundle and
environment. Xcode, Sandbox (including TestFlight), and Production transactions are accepted only
when the app environment and every verified transaction/status fact match exactly; missing,
unknown, cross-environment, or wrong-bundle input fails closed. Presentation caching continues to
require an exact environment plus storefront key, and catalog-only failure may not erase an
independently verified active subscription.

Focused evidence: `StoreRuntimeTests` plus `StoreLifecycleDomainTests` passed 49/49 on the iOS
26.5 simulator with final Xcode 26.6 `17F113`. The strict Phase 10 suite then passed 20/20 across
10 isolated iterations, including 10/10 executions of the 500 ms local Dashboard signal. The
owning shared-host run used the repository's documented switch to omit only that already-isolated
wall-clock assertion while retaining its deterministic 10,000-row projection test. It completed
346 Swift tests with zero failures (342 passed and 4 explicit StoreKit runtime probes skipped) and
all 13 UI tests. The combined result is 359 total, 355 passed, 4 skipped, and 0 failed. Every
selected coverage file passed the 85% gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.04%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%,
CycleSummaryService 97.45%, IntentClassifier 97.50%, CSVExporter 87.60%, and
CurrencyFormatterService 100.00%. Static release, money, network, commercialization-document,
feature-access, StoreKit-catalog, and diff gates pass. Evidence:
`/private/tmp/MindBudget-C204-ReviewFix-WallClockSuite-10x.xcresult` and
`/private/tmp/MindBudget-C204-ReviewFix-Full-Shared-Retry.xcresult`.

An initial unsplit full run also completed all functional/UI tests but measured the shared-host
wall-clock signal at 0.814 seconds and Xcode then spent 600 seconds timing out while collecting
simulator diagnostics. It is not used as passing evidence; the isolated 10-iteration run and the
clean shared-host run above are the owning evidence. PR #31 subsequently passed independent
review and the complete GitHub Actions run, then merged to `main` as `a293762` on 2026-08-13.
CI run: <https://github.com/xdgf558/MindBudget/actions/runs/31701374466>. C2-04 and COM-C2 are Done.
C3 remains blocked by accepted price/trial inputs and a new explicit owner instruction.

## COM-C3-01 implementation candidate verification

C3-01 adds a voluntary bilingual Pro presentation reachable only from Settings or an explicit
Pro value trigger. It shows the exact current Pro feature set, StoreKit-provided localized prices,
fresh introductory-offer eligibility, renewal terms, local Terms and Privacy links, and explicit
purchase, restore, and manage-subscription actions. It never presents automatically. The accepted
nonpublic test inputs are USD 1.99 monthly, USD 19.99 annually, one 7-day free trial per product,
and the first HKG/USA/SGP/TWN storefront probes. These values remain StoreKit Configuration test
inputs rather than formal App Store Connect products or public launch terms.

Framework-backed candidate evidence used final Xcode 26.6 `17F113` and the dedicated non-Archive
`MindBudget-StoreKit-Local` scheme on the physical `拉沙的iPhone` (`iPhone Air`) running final
iOS 26.6.1 `23G82`. All 9 tests passed with 0 failures and 0 skips: three static catalog tests,
four HKG/USA/SGP/TWN runtime catalog probes, and the Monthly/Annual verified transaction,
entitlement-publication, and finish probes. Evidence:
`/private/tmp/MindBudget-C301-Storefronts-Physical.xcresult`.

The strict Phase 10 suite passed 20/20 across 10 isolated iterations, including 10/10 executions
of the 500 ms local Dashboard wall-clock assertion. Evidence:
`/private/tmp/MindBudget-C301-Phase10-10x.xcresult`. Two earlier full shared-host attempts measured
that isolated wall-clock signal at 0.7687005 and 0.623222375 seconds while the host was under
concurrent test load; neither attempt is used as passing evidence. The owning full shared-host
validation therefore used the repository's documented `MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1`
switch to omit only that separately proven wall-clock assertion while retaining the deterministic
10,000-row projection contract. It passed 364 total results: 358 passed, 6 explicit opt-in
StoreKit runtime probes skipped, and 0 failed. All 14 UI tests passed. Every selected core-service
coverage file remained above the 85% gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.04%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%,
CycleSummaryService 97.45%, IntentClassifier 97.50%, CSVExporter 87.60%, and
CurrencyFormatterService 100.00%. Evidence:
`/private/tmp/MindBudget-C301-Full-Shared.xcresult`.

The StoreKit catalog contract suite passed 13/13 Python tests, and the money, network-egress,
commercialization-document, feature-access, StoreKit-catalog, release, localization, and diff
checks pass. C3-01 is implementation complete pending independent review, hosted green CI, and
merge; it is not Done. C3-02 and later commercial packets remain blocked. No formal product,
public price/trial, version, Archive, upload, tester assignment, or distribution action is claimed,
and the post-0.9.6 release hold remains active.

### C3-01 review-remediation verification

The first independent review found that an exact P1W test promotion had entered the production
catalog contract, unavailable entitlement authority did not independently pause purchase, and
renewal disclosure used the device/process locale. The remediation keeps P1W exactness inside the
isolated `.storekit`/Python/runtime fixture only; production accepts a missing or changed
introductory offer while retaining the stable product/type/period/group contract. The View and
actor now both reject purchase under unavailable authority and provide an explicit recheck, and
renewal disclosure uses the injected app locale.

The focused `StoreRuntimeTests` plus `StoreLifecycleDomainTests` run passed 53/53. The complete
shared-host validation used the already documented wall-clock exclusion and passed 366 total
results: 360 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed. All 14 UI
tests passed. Every selected coverage file remained above 85% with the same percentages recorded
above. The 13-test Python StoreKit contract and all standalone money, network, documentation,
feature-access, release, localization, and diff gates pass. Evidence:
`/private/tmp/MindBudget-C301-ReviewFix-Focused.xcresult` and
`/private/tmp/MindBudget-C301-ReviewFix-Full.xcresult`. C3-01 remains pending independent re-review,
hosted green CI, and merge; C3-02 and distribution remain blocked.

### C3-01 paid introductory-offer review remediation

The second independent review found that presentation had retained only an introductory offer's
period/free-trial projection. An eligible paid `.payAsYouGo` or `.payUpFront` offer could therefore
have been presented as the ordinary renewal price even though StoreKit would charge a different
introductory schedule. C3-01 remains deliberately free-trial-only: the presentation projection now
retains StoreKit's complete payment-mode raw value and localized introductory `displayPrice`.
Eligible free trials remain purchasable; eligible paid or future unknown modes display a bilingual
unsupported-offer notice and are blocked independently by both the View and the concrete StoreKit
purchase adapter before `Product.purchase()`. An ineligible paid offer does not block the ordinary
subscription, and introductory-offer shape remains outside entitlement authorization.

The complete shared-host validation used the repository's documented exclusion for only the
separately proven 500 ms wall-clock signal. It passed 369 total results: 363 passed, 6 explicit
opt-in StoreKit runtime probes skipped, and 0 failed. All 14 UI tests passed. Every selected
coverage file remained above 85% with the same percentages recorded above. The 13-test Python
StoreKit contract, release, money, network, commercialization-document, feature-access,
localization, StoreKit-isolation, and diff gates pass. Evidence:
`/private/tmp/MindBudget-C301-PaidOffer-ReviewFix-Full.xcresult`.

One preceding shared-host run intentionally kept the local wall-clock assertion enabled: all
functional and UI tests passed, but that isolated benchmark measured 0.8285 seconds under load,
then Xcode hung while finalizing coverage logs. The hung process was terminated and that result is
not passing evidence. C3-01 remains implementation complete pending independent re-review, hosted
green CI, and merge; C3-02 and distribution remain blocked.

## COM-C3-01 reviewed merge closeout

PR #33 passed independent review and the complete GitHub Actions validation, then merged to
`main` as `747b628` on 2026-08-14. Hosted run
<https://github.com/xdgf558/MindBudget/actions/runs/31766128587> is green. C3-01 is Done; its owning
local evidence and the historical remediation runs above remain unchanged. This closeout did not
create formal App Store Connect products, accept final economics, bump a version, Archive/upload,
assign testers, or authorize distribution. It opens only the C3-02 implementation packet.

## COM-C3-02 implementation verification

C3-02 derives active trial lifecycle only from the verified current StoreKit transaction plus
verified renewal information and reconciles one generic local calendar T−5 reminder or a
noninterrupting in-app fallback. The final focused entitlement/lifecycle/runtime regression run
passed 68/68 on final Xcode 26.6 `17F113`, iOS 26.5 simulator build `23F77`; evidence:
`/private/tmp/MindBudget-C302-Focused.xcresult`. The dedicated `TrialLifecycleTests` suite passed
12/12, including calendar/DST, authorization fallback, stable replacement, failed-add cleanup,
and generic bilingual-copy cases.

The final opt-in StoreKit suite then executed on physical `拉沙的iPhone` (`iPhone Air`) with
final iOS 26.6.1 `23G82` and final Xcode 26.6 `17F113`: 9 passed, 0 failed, 0 skipped. All four
HKG/USA/SGP/TWN catalog probes and both Monthly/Annual transaction-to-trial-lifecycle derivation
paths passed. The runtime assertion compares the one-week/free-trial structure while leaving the
localized zero-price string to StoreKit; the isolated fixture contract continues to own the USD
literal. Evidence: `/private/tmp/MindBudget-C302-Physical4.xcresult`.

The owning full validation passed 381 total results: 375 passed, 6 explicit opt-in
StoreKit runtime probes skipped, and 0 failed. All 14 UI tests and every selected coverage gate
passed; the money, network, commercialization-document, feature-access, StoreKit-catalog,
localization, release, and diff gates are green. Evidence:
`/private/tmp/MindBudget-C302-Full-Final2.xcresult`. C3-02 is implementation complete pending
independent review, hosted green CI, and merge; it is not Done. C3-03, formal economics/products,
versioning, Archive/upload, tester assignment, and distribution remain blocked.

### C3-02 independent-review remediation

The review found two truthful-presentation gaps. The lifecycle projection had used the current
trial product for renewal pricing even when verified `autoRenewPreference` selected a different
next-period plan, and a pending notification could promise renewal after the app process stopped
observing an App Store cancellation. The projection now stores current-trial and next-renewal
product identities separately, falls back to the current product only when the verified preference
is absent, and changes when only that preference changes. Pending bilingual copy says the trial
ends soon and asks the person to review current status without asserting that renewal remains on.

The dedicated review-remediation trial suite passed 13/13. The owning full validation produced
382 results: 376 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed. All 14 UI
tests, Release build, static gates, and selected coverage thresholds passed. Evidence:
`/private/tmp/MindBudget-C302-ReviewFix-Trial2.xcresult` and
`/private/tmp/MindBudget-C302-ReviewFix-Full.xcresult`. The previously submitted PR head
`71d7f54` had green GitHub Actions run `31800476681`; the review-fix head `e79e2c9` subsequently
passed GitHub Actions run <https://github.com/xdgf558/MindBudget/actions/runs/31803898776>.

## COM-C3-02 reviewed merge closeout

PR #34 passed independent review and the green hosted run above, then merged to `main` as
`12d9217` on 2026-08-14. C3-02 is Done. Its focused, full, and physical-device evidence remains
the evidence recorded above. The documentation-closeout validation produced 382 results: 376
passed, 6 explicit opt-in StoreKit probes skipped, and 0 failed; all 14 UI tests, selected coverage
thresholds, Release build, and static gates passed. Evidence:
`/private/tmp/MindBudget-C302-Closeout-Full.xcresult`. This closeout did not begin C3-03, create
formal App Store Connect products, accept final economics, bump a version, Archive/upload, assign
testers, or authorize distribution. The post-0.9.6 release hold remains active.

## COM-C3-03A implementation verification

C3-03A adds only the local signed-document boundary: exact Ed25519 verification over decoded
payload bytes, a closed schema-v1 presentation vocabulary, bounded time and size validation,
rollback/equivocation rejection, an atomic file-protected signed cache with readback verification,
and a conservative built-in fallback. It contains no URL, network adapter, Production public key,
application consumer, entitlement/StoreKit authority, or user-visible behavior. The Release
app-owned HTTP(S) allow-list remains empty.

The final focused `PublicConfigurationTests` run passed 8/8; evidence:
`/private/tmp/MindBudget-C303A-Focused3.xcresult`. The owning full shared-host validation used the
repository's documented `MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1` switch to exclude only the
separately proven 500 ms local wall-clock signal while retaining the deterministic 10,000-row
projection contract. It produced 390 results: 384 passed, 6 explicit opt-in StoreKit runtime
probes skipped, and 0 failed. All 14 UI tests, the Release build, the public-configuration,
release, money, network, commercialization-document, feature-access, StoreKit-catalog, and
localization gates passed. Evidence:
`/private/tmp/MindBudget-C303A-Full-Final.xcresult`.

Every selected coverage file remained above the 85% gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.04%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%,
CycleSummaryService 97.45%, IntentClassifier 97.50%, CSVExporter 87.60%, and
CurrencyFormatterService 100.00%. One preceding integrated run kept the strict local wall-clock
assertion enabled and measured 0.822698 seconds under shared test load, so it is not passing
evidence. The exact strict performance suite separately passed 10/10 isolated iterations;
evidence: `/private/tmp/MindBudget-C303A-StrictPerformance.xcresult`.

Independent-review remediation expanded the deterministic public-configuration suite from 8 to
12 tests. It now covers an encoder-independent fixed Ed25519 byte vector, exact whole-second UTC
grammar, duplicate keys, zero validity, malformed high-water variants, serialized concurrent
acceptance, and abstraction-level post-write verification. The focused run passed 12/12; evidence:
`/private/tmp/MindBudget-C303A-ReviewFix-Focused.xcresult`. The final owning full validation then
produced 394 results: 388 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed.
All 14 UI tests, the Release build, every static gate, and every selected coverage threshold
passed. Evidence: `/private/tmp/MindBudget-C303A-ReviewFix-Full3.xcresult`. The review-remediation
head `3a53107` then passed GitHub Actions run `31856271268`; PR #36 merged it to `main` as
`1ebb36c` on 2026-08-15.

C3-03A is Done. The documentation closeout branch repeated 394 results with 388 passed, 6 opt-in
StoreKit probes skipped, and 0 failed; evidence:
`/private/tmp/MindBudget-C303A-Closeout-Full.xcresult`. The post-0.9.6 release hold remains active.

## COM-C3-03B implementation verification

C3-03B adds one exact environment-isolated public-configuration adapter, the embedded Ed25519
public key, closed non-content reason codes, a first-party Worker, and one optional presentation
consumer. The Worker test suite passed 13/13. TypeScript typecheck, `npm audit --audit-level=high`
with zero vulnerabilities, and a Production-configuration Wrangler dry-run passed. The static
network gate allows only `MindBudget/Commerce/PublicConfigurationTransport.swift`, checks all
other app Swift/configuration sources, and passes; the public-configuration transport gate also
passes.

Development Worker version `bf6c5049-a389-4ea7-af0a-e8425b8957e2` was deployed on 2026-08-15.
An exact accepted GET returned the 387-byte signed envelope with `no-store` and security headers;
missing metadata returned 400 with an empty body, and query/unknown metadata returned 404 with an
empty body. Cloudflare injected ordinary edge headers including `Report-To`/`NEL`; the Worker has
no request logging/storage/outbound fetch and platform observability is disabled. The dedicated
non-Archive `MindBudget-PublicConfig-Live` scheme exercised the real Development endpoint through
the app transport, embedded public key, production verifier, cache, and consumer seam on iPhone
17 Pro Simulator iOS 26.5 (`23F77`): 8 passed, 0 failed, 0 skipped. Evidence:
`/private/tmp/MindBudget-C303B-LiveWorkerFinal.xcresult`.

The owning shared-host full validation skipped only the six explicit StoreKit runtime probes and
the separately measured local wall-clock signal. It produced 402 results: 395 passed, 7 skipped,
and 0 failed, including 14/14 UI tests, the Release build, all static gates, and every selected
coverage threshold. Evidence: `/private/tmp/MindBudget-C303B-Full-Final.xcresult`. One preceding
shared-load run measured the local signal at 0.850044833 seconds and is retained as nonpassing
diagnostic evidence at `/private/tmp/MindBudget-C303B-Full.xcresult`; the isolated signal then
passed 10/10 at `/private/tmp/MindBudget-C303B-StrictPerformance.xcresult`.

Staging and Production were not deployed. Hosted CI was pending at this initial implementation
checkpoint. Final Release binary/
Production captured traffic, current privacy/review disclosure, C3-04, formal products/economics,
versioning, Archive/upload, tester assignment, and distribution remain blocked.

Independent-review remediation on 2026-08-15 closed three lifecycle gaps without changing the
Worker or deployment: response-completion time now owns verification, signed expiry is propagated
to an independent foreground expiry schedule, the optional trigger requires actionable exact-Free
StoreKit authority, and caller cancellation cancels the owned refresh operation before it can
verify, persist, or publish. The focused `PublicConfigurationTransportTests` suite passed 11/11
with zero failure or skip at
`/private/tmp/MindBudget-C303B-ReviewFix-Focused.xcresult`. It includes deterministic response-gate,
expiry-scheduler, StoreKit-authority, and cancellation-aware transport fixtures. The final owning
validation, with the shared-load wall-clock signal separated as designed, produced 405 results:
398 passed, 7 explicit opt-in/runtime skips, and 0 failed. The Release build, 14/14 UI tests, all
static gates, and every selected coverage threshold passed; evidence:
`/private/tmp/MindBudget-C303B-ReviewFix-FullFinal.xcresult`. The strict local Dashboard signal
separately passed 10/10 isolated iterations at
`/private/tmp/MindBudget-C303B-ReviewFix-StrictPerformance.xcresult`. One preceding shared-load run
measured 0.838828417 seconds and is retained only as nonpassing diagnostic evidence at
`/private/tmp/MindBudget-C303B-ReviewFix-Full.xcresult`. Hosted CI was pending at this review-
remediation checkpoint.

Second cancellation review remediation on 2026-08-15 makes the startup refresh a separately
structured SwiftUI task, retains scene-active work for explicit inactive/background/replacement/
Session-destruction cancellation, and adds cancellation checks after persistence actor entry and
immediately before the atomic-write commit point. Cancellation before that point leaves the prior
cache untouched; an atomic commit already started may finish, but canceled acceptance cannot
publish. The combined public-configuration core/transport suites produced 28 results: 27 passed,
the explicit live Development Worker probe skipped, and 0 failed. Deterministic tests cover caller
cancellation at AppSession startup, retained scene work, Session destruction, a pre-canceled real
file write, and cancellation while a persistence actor is suspended. Evidence:
`/private/tmp/MindBudget-C303B-CancellationFix-Focused3.xcresult`. The fresh owning full validation
then produced 410 results: 403 passed, 7 explicit opt-in/runtime skips, and 0 failed. All 396 unit
tests and 14/14 UI tests passed, together with the Release build, all static gates, and every
selected coverage threshold. Evidence:
`/private/tmp/MindBudget-C303B-CancellationFix-FullFinal2.xcresult`. The exact follow-up head
`09c382e` then passed GitHub Actions run `31873664396`; PR #38 merged to `main` as `db7926d` on
2026-08-15. C3-03B and C3-03 are Done. Staging/Production, final Release binary/Production traffic,
current privacy/review disclosure, C3-04 implementation, formal products/economics, versioning,
Archive/upload, tester assignment, and distribution remain pending their own gates.

The post-merge C3-03B documentation closeout reran the complete validation on `db7926d` with the
document-state changes present. The CI-style run intentionally skipped only the separately measured
local wall-clock signal and produced 410 results: 403 passed, 7 explicit opt-in/runtime skips, and
0 failed. The Release build, all 396 unit tests, 14/14 UI tests, every static gate, and every selected
coverage threshold passed at `/private/tmp/MindBudget-C303B-Closeout-FullGreen.xcresult`.
An earlier shared-load run measured that local Dashboard signal at 0.83718875 seconds and is retained
as diagnostic-only evidence at `/private/tmp/MindBudget-C303B-Closeout-Full.xcresult`; the exact
signal then passed 10/10 isolated iterations at
`/private/tmp/MindBudget-C303B-Closeout-StrictPerformance.xcresult`. These post-merge checks confirm
the closeout only; they do not open C3-04, Production, or distribution.

## COM-C3-04 implementation verification

C3-04 adds one non-blocking Dashboard navigation card, verified-state guidance on the Pro screen,
and localized VoiceOver/AX5 presentation across all three owner-approved appearances. The focused
StoreKit-domain run passed 24/24 with no failure or skip at
`/private/tmp/MindBudget-C304-StoreRuntime.xcresult`.

The first focused AX5 UI run passed its automated assertions, but manual inspection of its captured
screenshots found that a rapid appearance change could pair the newly selected row background with
the preceding system color scheme. That run is diagnostic only and is not accepted as final visual
evidence. The Pro screen now binds its local preferred color scheme to the selected appearance. The
exact follow-up test passed 1/1 at
`/private/tmp/MindBudget-C304-ProAX5-ColorFix.xcresult`. The following three AX5 screenshots were
then inspected for readable text, controls in bounds, and absence of clipping:

- Aurora: `/private/tmp/MindBudget-C304-ProAX5-ColorFix-Attachments/8319E6FF-B028-4B19-AF02-AC24868DA97C.png`
- Warm Botanical: `/private/tmp/MindBudget-C304-ProAX5-ColorFix-Attachments/F825A832-2C3F-4544-8792-7FE436A1A3BE.png`
- Neon: `/private/tmp/MindBudget-C304-ProAX5-ColorFix-Attachments/51657CE5-C1C5-4C9C-ADC5-BF0FD4E254B6.png`

The final owning validation produced 413 results: 406 passed, 7 explicit opt-in/runtime skips,
and 0 failed. All 398 unit tests and 15/15 UI tests passed, together with the Release build, all
static gates, and every selected coverage threshold. Evidence:
`/private/tmp/MindBudget-C304-Full-Final.xcresult`. Hosted CI and independent review remain pending,
so C3-04 and COM-C3 are not Done. No Production deployment, final customer economics, Archive,
upload, tester assignment, or distribution permission is claimed.

Independent-review remediation on 2026-08-16 confirmed that StoreKit-unavailable presentation was
already distinct from exact Free: the existing purchase section shows localized unavailable-
authority copy, disables purchase, and keeps the user-initiated Recheck action reachable. The
verified-state guidance initializer now documents why it must not add a duplicate status card for
that same condition. The exceptional-state tint now uses `theme.attentionText` instead of a hard-
coded orange. The Pro screen's local preferred-color-scheme binding remains intentionally in place:
`AppRouter` already supplied the same root value, while the earlier retained AX5 screenshot proved
that a pushed `List` could still display the preceding scheme during a rapid appearance transition.
The StoreKit contract gate now pins the theme-token boundary, and the matrix explicitly records
that automated AX5 assertions prove reachability and bounds, while contrast still requires manual
inspection of retained screenshots.

The review-fix StoreKit-domain run passed 24/24 with no failure or skip at
`/private/tmp/MindBudget-C304-ReviewFix-StoreRuntime.xcresult`. The three-appearance AX5 run passed
1/1 at `/private/tmp/MindBudget-C304-ReviewFix-AX5.xcresult`; its Aurora, Warm Botanical, and Neon
captures were manually inspected at
`/private/tmp/MindBudget-C304-ReviewFix-AX5-Attachments/389C83B9-37FF-473F-A365-BE6AEA0D4ACC.png`,
`/private/tmp/MindBudget-C304-ReviewFix-AX5-Attachments/E23DC834-7596-4D29-9894-095D50113DA2.png`,
and
`/private/tmp/MindBudget-C304-ReviewFix-AX5-Attachments/C809B330-F3F3-48FB-AFBF-F39C9BFAEF3E.png`.
The fresh owning validation produced 413 results: 406 passed, 7 explicit opt-in/runtime skips, and
0 failed. All 398 unit tests and 15/15 UI tests passed with the Release build, every static gate,
and all selected coverage thresholds at
`/private/tmp/MindBudget-C304-ReviewFix-Full.xcresult`. Hosted CI for the follow-up head remains
pending, so C3-04 and COM-C3 remain implementation-complete review candidates rather than Done.

The final P3 review follow-up on 2026-08-16 removed purchase-button/action drift by making both
paths consume the same `canPurchaseSelectedProduct` predicate. Every warning treatment on the Pro
screen now uses the selected skin's `attentionText` token, and the Pro, subscription-terms, and
subscription-privacy screens each bind the selected preferred color scheme. The expanded AX5 test
passed 1/1 at `/private/tmp/MindBudget-C304-P3-AX5-Rerun.xcresult` and retained nine captures—one
Pro, terms, and privacy image for each owner-approved appearance. All nine were manually inspected
for readable contrast, correct light/dark presentation, bounds, and clipping. The fresh owning
validation produced 413 results: 406 passed, 7 explicit opt-in/runtime skips, and 0 failed. It
included 398 unit-test results, 15/15 passing UI tests, the Release build, every static gate, and
all selected coverage thresholds at `/private/tmp/MindBudget-C304-P3-Full2.xcresult`. Hosted CI for
this new head subsequently passed independent review and the hosted CI evidence recorded below.

## COM-C3-04 reviewed merge closeout

PR #40 passed independent review and GitHub Actions run `31918968478` with the complete Build and
test job green, then merged to `main` as `9448ca9` on 2026-08-16. C3-04 and COM-C3 are Done. The
local focused, AX5, and full-validation evidence above remains the owning implementation evidence;
the hosted run independently passed the repository's money, network, commercialization, signed-
configuration, StoreKit isolation, Release build, unit/UI, and coverage workflow.

This closeout did not deploy Staging or Production, approve public launch economics, assign a
tester, submit external Beta App Review, or submit an App Store version. The owner later authorized
only 0.9.7 (8) Archive and transport upload; those artifact results are recorded separately after
the signed upload completes.

## Result and report paths

`Scripts/validate.sh` accepts an optional `MINDBUDGET_RESULT_BUNDLE_PATH`. The path must not
already exist. Without it, the script uses and removes an isolated temporary directory as before.

- Recommended local path:
  `TestResults/Commercialization/<phase>/<build>/MindBudget.xcresult`.
- CI working path: `${RUNNER_TEMP}/MindBudget.xcresult`.
- Downloadable CI artifact:
  `MindBudget-xcresult-<run-id>-<run-attempt>`, retained for 14 days and uploaded even when the
  validation step fails after producing a result bundle. If validation stops before testing,
  absence of an xcresult is reported without hiding the original failure.
- Signed-device/manual evidence:
  `TestResults/Commercialization/<phase>/<build>/README.md` plus only redacted screenshots/logs.
- StoreKit evidence: `TestResults/Commercialization/StoreKit/<build>/`.
- Cloud/Watch evidence later uses its named phase directory and must never contain credentials,
  receipt images/OCR, notes, ledger rows, prompts/responses, or stable user identifiers.

Example:

```bash
MINDBUDGET_RESULT_BUNDLE_PATH="$PWD/TestResults/Commercialization/COM-C1/local/MindBudget.xcresult" \
  Scripts/validate.sh
```

`TestResults/` is evidence workspace, not an automatic commit target. Review and redact every
artifact before deliberately adding it to version control.

## Failure and change rules

- A failed money, StoreKit-catalog isolation, documentation, release-readiness, build, test, UI,
  or coverage gate blocks the
  phase. Hosted wall-clock noise may skip only the already documented 500 ms signal; the
  deterministic 10,000-row contract still runs.
- A new app-owned network channel, persisted model, Product ID, entitlement, premium feature,
  privacy statement, or SDK capability must extend its owning matrix and tests in the same PR.
- CI/action upgrades remain commit-SHA pinned. A report path or test retry never converts a failed
  assertion into success.

## COM-C4A-01 delta-audit verification

Status: **Done after independent review, green CI, and PR #51 merge `bcd56a3`; COM-C4A is Done
through PR #55 `77292c6`.**

The 2026-08-20 C4A-01 audit is documentation and gate work only. It inventories the persisted
money owners, existing V1 → V2 → V3 → V4 migration evidence, checked-arithmetic/currency
boundaries, sign rules, and the missing recovery controls. It finds no floating-point amount to
convert and therefore rejects a destructive rewrite. The owning plan is
`COM_C4A_EXECUTION_PACKET.md`; DEC-COM-025 records the decision.

Local validation passed under final Xcode 26.6 (`17F113`) on the iOS 26.5 (`23F77`) iPhone 17 Pro
simulator. The final wall-clock-excluded owning run produced 420 results: 413 passed, 7 explicit
runtime/opt-in skips, and 0 failed; 17/17 UI tests, the Release build, every static gate, and every
selected coverage threshold passed at `/private/tmp/MindBudget-C4A01-Full.xcresult`. The strict
`Phase10ReleaseReadinessTests` suite separately executed and passed 2/2 at
`/private/tmp/MindBudget-C4A01-StrictPerformanceSuite-Retry.xcresult`. An earlier concurrent full
run measured only the known 500 ms wall-clock diagnostic at 1.046 seconds; it was not used as
passing evidence. PR #51 subsequently supplied the independent-review, hosted-green, and merge
evidence. C4A-02 then added the approved V5 merchant-currency companion and recovery envelope;
its local and hosted evidence is recorded below. It does not authorize distribution.

## COM-C4A-02 local verification

Status: **Done after independent review, GitHub Actions run `32375823770`, and PR #53 merge
`c905415`; COM-C4A is Done through PR #55 `77292c6`.**

The final owning validation used final Xcode 26.6 (`17F113`) and the iOS 26.4.1 (`23E254a`)
iPhone 17e simulator. With only the already documented strict wall-clock diagnostic excluded from
the concurrent full run, `Scripts/validate.sh` completed successfully at
`/private/tmp/MindBudget-C4A02-Validate-Green-Retry-20260820.xcresult`: 429 results, 422 passed,
7 explicit runtime/opt-in skips, and 0 failed; 17/17 UI tests, the Release build, all four static
gates, and every selected core-service coverage threshold passed. The full unit-only run separately
produced 413 results, 406 passed, 7 skipped, and 0 failed at
`/private/tmp/MindBudget-C4A02-AllUnits-Final-20260820.xcresult`.

The strict `Phase10ReleaseReadinessTests` performance case then executed ten consecutive isolated
iterations and passed 10/10 at
`/private/tmp/MindBudget-C4A02-StrictPerformance-10x-20260820.xcresult`. An earlier concurrent
default validation measured only that known local wall-clock diagnostic at 1.240605666 seconds;
all deterministic 10,000-row assertions and all 17 UI tests passed, so that run is retained as a
non-passing diagnostic rather than promoted to evidence. Root review also found and fixed a V1
compatibility regression: a migrated expense may legitimately have no derived `Merchant` cache
row, and inventory must not invent a replacement UUID. Reviewed head `9d2171d` then passed every
step of GitHub Actions run `32375823770`; PR #53 merged it to `main` as `c905415` on 2026-08-20.
C4A-02 is Done. C4A-03 later passed its owning gates and closed COM-C4A through PR #55
(`77292c6`); no distribution gate opened.

## COM-C4A-03 focused recovery/currency verification

Status: **Done after independent review, GitHub Actions run `32406654986`, and PR #55 merge
`77292c6`.**

The first local focused compilation was not accepted as evidence because three throwing
`#require` expressions in the new test body were rejected by the Testing macro. The test shape was
corrected by evaluating each throwing preparation before applying `#require`; the production source
had no compile errors.

The final corrected focused run passed on 2026-08-20 under final Xcode 26.6 (`17F113`) against
iOS 26.4.1 device `A86B6BE8-D716-4E1D-A731-6F40BAFBB02F`: 20 tests in 2 suites, 0 failures, at
`/private/tmp/MindBudget-C4A03-Focused4.xcresult`. It includes the new 12/12 deterministic
`C4A03RecoveryAndCurrencyMatrixTests` and the existing 8/8 `StoreMigrationRecoveryTests`.

The generic iOS Simulator Release build then succeeded with DerivedData at
`/private/tmp/MindBudget-C4A03-Release2-DD`. The first shared-load validation attempt missed only
the existing strict 500 ms Phase 10 Dashboard wall-clock signal; it is diagnostic-only and is not
promoted as a passing full run. The owning isolated strict performance suite subsequently passed
10/10 iterations at `/private/tmp/MindBudget-C4A03-StrictPerformance-10x.xcresult`.

The final wall-clock-excluded full validation produced 441 results: 434 passed, 7 explicit
runtime/opt-in skips, and 0 failed. All 17 UI tests, every static gate, the Release build, and every
selected core-service coverage threshold passed at
`/private/tmp/MindBudget-C4A03-FullFinal.xcresult`. Reviewed head `138c240` passed every step of
GitHub Actions run `32406654986`, including the complete Build and test job and test-report upload.
PR #55 merged it to `main` as `77292c6`, closing C4A-03 and COM-C4A. C4B remains blocked pending
its accepted CloudKit architecture and explicit owner instruction.

The documentation closeout then reran the same wall-clock-excluded full validation on the merged
source with final Xcode 26.6 (`17F113`) and the iOS 26.4.1 (`23E254a`) iPhone 17 Pro simulator.
It again produced 441 results: 434 passed, 7 explicit runtime/opt-in skips, and 0 failed; all 17 UI
tests, the Release build, every static gate, and every selected coverage threshold passed at
`/private/tmp/MindBudget-C4A03-Closeout-Full.xcresult`.


## COM-C4B-01 design-candidate verification

Status: **Proposed architecture candidate complete pending independent review and owner acceptance.**

C4B-01 changes only contract documents and static checks. It adds no Swift production source,
SwiftData schema/model/entitlement, CloudKit container, Dashboard schema, request, or deployment.
The candidate's static verification runs the existing phase-state parser plus
`check_icloud_sync_contract.py` self-test and repository check. The latter fails a future
CloudKit import or iCloud entitlement unless every primary local `DataController`
`ModelConfiguration` explicitly sets `cloudKitDatabase: .none`, preventing accidental managed
SwiftData mirroring. C4B-01 claims no runtime CloudKit evidence; C4B-02/03 still require their own
full validation, independent review, hosted CI, merge, physical-device, and Dashboard gates.

Local C4B-01 design validation passed the money, network-egress, commercialization-document, and
StoreKit-catalog gates; the new parser self-test/repository check, Python AST syntax check, shell
syntax check, and `git diff --check` also passed. A full runtime suite is intentionally not claimed:
this candidate changes no runtime source, schema, entitlement, or container.

## COM-C4B-01 closeout and C4B-02P prerequisite verification

Status: **C4B-01 Done; C4B-02P prerequisite maintenance pending independent review.**

Reviewed C4B-01 head `093535f` passed every step of GitHub Actions run `32434148439`; PR #57
merged to `main` as `90a1e66` on 2026-08-21. The accepted DEC-COM-028 evidence remains design-only:
no CloudKit container, entitlement, import, engine, request, schema, Dashboard action, deployment,
or distribution was added.

The prerequisite checker now tokenizes each production Swift source while excluding comments and
normal/raw single-line or multiline string literal text (but retaining interpolation code), reports
a missing `DataController` as a closed diagnostic, scans all `MindBudget/**/*.swift`
`ModelConfiguration` constructions, applies delimiter-specific raw-string escape rules, recognizes
direct and selective CloudKit imports, and rejects aliases and metatype `.self` bypasses. Every
production `.init(...)` is checked against an exact path/receiver/argument-label/count allowance,
closing cross-file contextual inference without rejecting the current reviewed initializers. The
checker requires top-level `.none` inside every individual real configuration call, rejects explicit
`.automatic`/private managed CloudKit selection, and centralizes construction without rejecting
ordinary `ModelContainer` parameter/reference types outside `DataController`. Its self-test proves
compact `.none`, partial hardening, `.automatic`, private managed storage, alternate production
construction, direct/same-file/cross-file contextual `.init`, metatype escape, aliases, fake
comment/string or nested-code `.none`, raw trailing-backslash termination, every supported selective
import kind, entitlement-triggered hardening, and missing-owner cases.

Local prerequisite verification passed the money, network-egress, commercialization-document,
StoreKit-catalog (13/13), iCloud contract self-test/repository check, Python bytecode syntax, and
`git diff --check` gates. No Xcode runtime suite is claimed because this closeout changes only
documentation and a static Python gate; hosted CI and independent review remain required before
the C4B-02P item closes or C4B-02 runtime work can start.

Review remediation promotes the sole active prerequisite item to the recognized
`C4B-02P` subphase in `COM_C4B_EXECUTION_PACKET.md`, with its own direct pending-review Status.
The existing `--require-all-status` parser now rejects a missing or conflicting C4B-02P Status;
C4B-02 runtime remains a separate Blocked phase. The later review remediation changes C4B-02P from
the optional/parallel `[~]` marker to mandatory pending `[ ]` in both task maps and closes the
comment/string counting bypass. The pre-existing generic nested-heading deletion/format-drift limits
remain documented P3 maintenance items.
