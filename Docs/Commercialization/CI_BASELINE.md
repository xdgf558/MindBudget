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
closing cross-file contextual inference without rejecting the current reviewed initializers.
Initializer function values have a separate exact path/receiver/count allowance, so bare
`ModelConfiguration.init`/`ModelContainer.init` cannot escape into an indirect factory. SwiftUI's
container modifier has one exact allowance: the existing unlabeled attachment of
`environment.dataController.container` in `MindBudgetApp`; View/Scene `modelContainer(for:)`,
implicit-self variants, extra calls, and method references fail. The checker requires top-level
`.none` inside every individual real configuration call, rejects explicit `.automatic`/private
managed CloudKit selection, and centralizes construction without rejecting ordinary
`ModelContainer` parameter/reference types outside `DataController`. Its self-test proves compact
`.none`, partial hardening, `.automatic`, private managed storage, alternate production
construction, direct/same-file/cross-file contextual `.init`, initializer function values,
metatype escape, SwiftUI View/Scene/implicit-self modifier construction, aliases, fake comment/
string or nested-code `.none`, raw trailing-backslash termination, every supported selective import
kind, entitlement-triggered hardening, and missing-owner cases.

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

## COM-C4B-02 custom-record runtime verification

Status: **C4B-02 Done after independent review, hosted CI, and PR #59 merge `211dff2`; C4B-03
evidence remains unclaimed.**

Prerequisite evidence is closed: reviewed C4B-02P head `0fece3a` passed GitHub Actions run
`32454490080`, and PR #58 merged as `6f5fded`. C4B-02 then adds Schema V6's five
non-authoritative local sync metadata models, explicit `.none` on every primary configuration,
transactional local-fact/outbox staging, inbox-first topological remote application, all 12
allow-listed typed envelopes, logical tombstones, closed no-winner quarantine, account and
encrypted-key-reset pauses, default-off localized Settings consent, and the accepted private-
database `CKSyncEngine` adapter.

The final focused C4B-02 suite passed 20 tests in one suite with zero failures on Xcode 26.6
(`17F113`), iOS 26.4.1 simulator `A86B6BE8-D716-4E1D-A731-6F40BAFBB02F`. Result bundle:
`/private/tmp/MindBudget-C4B02-CloudSync-Final.xcresult`. It verifies V5-to-V6 migration,
default-off/no-adapter behavior, exact recurrence/canonical bytes/lineage, each allow-listed fact,
local-only cache exclusion, duplicate delivery, logical and cascade tombstones, reverse-topology
application, malformed/physical deletion isolation, account re-consent, encrypted-key reset, and
server-save conflict quarantine, and sticky fail-closed handling of encrypted-key reset and remote
zone deletion/purge. An earlier 18-test run failed one test-only ordered-array
assertion even though both tombstone identities were correct; the assertion now compares the
identity set, while the same test continues to reverse the inbound tombstones and proves child-
before-parent application.

The iCloud static checker additionally requires the exact 12-case enum and runtime anchors, and
rejects public/shared database, `CKAsset`, physical `deleteRecord`, managed mirroring, unapproved
container construction, or an iCloud entitlement in C4B-02. Final full local/static results are
recorded below. No container was provisioned, no Dashboard schema was deployed, no real CloudKit
request or physical/multi-device convergence was claimed, and C4B-03 remains blocked.

The first default `Scripts/validate.sh` attempt passed the Release build, all 445 correctness tests
except the strict wall-clock benchmark, and all 17 UI tests; that single benchmark was running amid
the other 27 Swift Testing suites and exceeded its local 500 ms signal, so the attempt is retained
as a non-pass rather than evidence. A focused run then passed the two Phase 10 tests, and an
independent iOS 26.4.1 run repeated that suite 10 times: 20/20 passed at
`/private/tmp/MindBudget-C4B02-Performance10-iOS264.xcresult`. The validation runner now executes
the local wall-clock benchmark once with parallel testing disabled, then skips only its duplicate
concurrent invocation in the full correctness/coverage run; hosted CI retains its existing
wall-clock skip and deterministic 10,000-row projection coverage.

The corrected full `Scripts/validate.sh` run passed on Xcode 26.6 (`17F113`) and iOS 26.4.1:
isolated strict benchmark 1/1, remaining unit tests 444/444 across 27 suites, UI tests 17/17, Release
build, all static contracts, and every selected core-service coverage threshold (minimum 87.60%,
required 85%). Result bundle: `/private/tmp/MindBudget-C4B02-Validate.xcresult`.

### Independent-review remediation evidence

The C4B-02 review remediation expanded `CloudSyncTests` from 20 to 25 deterministic tests. All
25 passed in one suite on Xcode 26.6 (`17F113`) and iOS 26.4.1 simulator
`A86B6BE8-D716-4E1D-A731-6F40BAFBB02F`; result bundle:
`/private/tmp/MindBudget-C4B02-ReviewFix2.xcresult`. The new evidence covers actual CKError
`zoneNotFound` mapping with and without `CKErrorUserDidResetEncryptedDataKey`, sticky-pause
protection against delayed transport/account callbacks, the shared recurrence formatter,
over-allocation quarantine, divergent recurring-claim preservation, and required parent identity
in CategoryBudget/CoolingOffPlan upserts. The money, network-egress, commercialization-document,
StoreKit catalog 13/13, iCloud contract self-test/repository, localized-catalog JSON, Python syntax,
and `git diff --check` gates also passed after remediation.

The final owning `Scripts/validate.sh` rerun passed on the same Xcode/runtime surface. Its strict
Dashboard benchmark passed independently 1/1. The combined correctness/UI result bundle contains
466 results: 459 passed and seven explicitly opt-in tests skipped, including all 17/17 UI tests;
Release compilation, every static contract, and all selected coverage thresholds also passed
(minimum 87.60%, required 85%). Result bundle:
`/private/tmp/MindBudget-C4B02-ReviewFix-Validate.xcresult`. This local evidence belongs to reviewed
head `0024507`; the merge closeout below records its satisfied hosted gate.

### C4B-02 merge closeout

Reviewed remediation head `0024507` passed the complete GitHub Actions `Build and test` job in run
`32490174014` (34m30s). PR #59 then merged that exact head to `main` as `211dff2` on 2026-08-21.
This closes C4B-02 source/review/CI/merge only. No iCloud entitlement, provisioned container,
Dashboard schema/environment deployment, verified CloudKit request, physical multi-device/account/
quota evidence, conflict-resolution UI, cloud-wide deletion, Archive, upload, tester, or
distribution evidence is inferred. C4B-03 remains separately gated.

## COM-C4B-03 implementation evidence in progress

Reviewed closeout head `b9944cd` passed every step of GitHub Actions run `32494429474`; PR #60
merged it as `7138a9c` on 2026-08-22, satisfying the owner's formal-entry condition.

The current deterministic `CloudSyncTests` suite passed 32/32 with zero failures or skips at
`/private/tmp/MindBudget-C4B03-Focused3.xcresult`. The added cases prove that explicit keep-local
and use-iCloud resolutions author the accepted result without automatic winner selection; a
tombstone/upsert conflict remains explicit; retained cloud state requires confirmed reimport;
pre-marker enabled state conservatively creates the marker; whole-zone deletion keeps local facts
and clears the marker only after confirmation; interrupted deletion survives process recreation;
and explicit sticky recovery re-stages local authority without generic retry.

Unsigned simulator `build-for-testing` passed after the localized Settings conflict/deletion/
reimport/recovery surface was added. A generic signed Debug device build also succeeded at
`/private/tmp/MindBudget-C4B03-GenericSigned1.xcresult`; its signed app selected the exact
Development CloudKit container and development push entitlement under team `2AM5S7BM2N`. This
initially proved only that Development provisioning accepted the exact container; the later
physical request and read-only Dashboard evidence below close those separate gates.

A local Release archive succeeded at `/private/tmp/MindBudget-C4B03-Release1.xcresult` and
`/private/tmp/MindBudget-C4B03-Release1.xcarchive`. Its requested/signed CloudKit container
environment is Production and exact container/service values match the Release entitlement file.
Automatic signing nevertheless used an Apple Development identity/profile, so the embedded push
entitlement is development and this archive is not distribution-signing or Production-deployment
evidence. A direct physical-device build attempt was not executed because the previously visible
iPhone disconnected from Xcode before destination selection; it is retained as an environment
non-pass at that point, not a source failure. The device later reconnected for the accepted pass
below.

Adding the entitlement exposed six legacy migration fixtures whose local-only
`ModelConfiguration` values had relied on the SDK's `.automatic` default. That first full
validation attempt is retained as a non-pass: the entitled test host made the missing explicit
`.none` observable. All test-store fixtures now state `cloudKitDatabase: .none`, and the iCloud
static gate enforces that boundary across both production and test Swift sources. The corrected
focused migration/free-tier regression passed 45/45 at
`/private/tmp/MindBudget-C4B03-Regression2.xcresult`.

The app now supplies `UIBackgroundModes = [remote-notification]` through the checked source plist
`MindBudget/Resources/MindBudgetInfo.plist`; the generated Debug app plist was read back from a
fresh build and contained that exact array. The repository gate parses the plist, verifies the
Debug/Release build-setting references, rejects alternate background modes, and continues to
require the exact environment-specific entitlement files.

The corrected owning `Scripts/validate.sh` run passed on Xcode 26.6 / iOS 26.4.1 at
`/private/tmp/MindBudget-C4B03-Full1.xcresult`: Release compilation, all static contracts, the
isolated strict 10,000-row Dashboard benchmark, 456/456 unit tests across 27 suites, 17/17 UI tests,
and every selected coverage threshold. The lowest selected coverage was CSVExporter at 87.60%,
above the required 85%. This closes the local full-validation gate only.

The owner explicitly authorized one destructive opt-in test against the app's fixed Development
zone. Final Xcode 26.6 (`17F113`) then ran the complete `CloudSyncTests` suite on the physical
`拉沙的iPhone` (`iPhone Air`) with final iOS 26.6.1 (`23G82`). All 33 tests passed with zero
failures in `/private/tmp/MindBudget-C4B03-PhysicalCloudKit4.xcresult`; the real CloudKit case took
9.358 seconds. It created the custom zone through the production `CKSyncEngine` adapter, sent and
fetched the private encrypted envelope, disabled without forgetting that a cloud copy could exist,
required explicit reimport confirmation, deleted the whole Development zone, and proved the local
expense remained. The destructive test is compile-time opt-in and is skipped by ordinary local,
CI, simulator, and physical-device test runs. The first physical result bundle is retained as a
compiler non-pass; two later function-level filters executed zero Swift Testing cases and are not
counted as evidence.

The ordinary simulator configuration was then rerun without the opt-in compilation condition at
`/private/tmp/MindBudget-C4B03-PostPhysical-Sim.xcresult`: 32 deterministic cases passed, the one
destructive physical case was explicitly skipped, and no failure occurred. This proves the real
probe did not accidentally make the destructive path part of ordinary simulator or CI execution.

Read-only CloudKit Dashboard inspection for team `2AM5S7BM2N` and exact container
`iCloud.com.xdgf558.MindBudget` confirmed that Development has one app record type,
`MindBudgetEnvelopeV1`, with six system metadata fields plus exactly one app field,
`envelope` (`ENCRYPTED BYTES`), and no single-field index. The destructive probe had removed the
custom `MindBudget.Sync.v1` Development zone. Production contains only the system `Users` record
type; `MindBudgetEnvelopeV1` is absent and `Deploy Schema Changes` is disabled. Screenshots:
`/private/tmp/MindBudget-C4B03-Dashboard-Development-Envelope.png` and
`/private/tmp/MindBudget-C4B03-Dashboard-Production-NoTypes.png`. No schema, role, permission,
record, or environment mutation was performed, and Production deployment remains an explicit
owner gate.

A final current-source simulator validation then rebuilt Release, reran every static contract,
and completed all 457 unit-test results without a failure; the 32 deterministic cloud-sync cases
passed and the compile-time physical-zone case remained explicitly skipped. The 17-test UI run
passed 16 test cases, but the pseudo-long-text case failed four downstream reachability assertions
after its budget-save transition did not reach Dashboard. Xcode then hung while finalizing failure
diagnostics/coverage, so `/private/tmp/MindBudget-C4B03-FinalWithoutWallClock.xcresult` is an
incomplete result directory and is **not** accepted as a green bundle. The exact failed case was
immediately rerun alone on the same iOS 26.5 simulator and passed 1/1 in 23.625 seconds with zero
failures at `/private/tmp/MindBudget-C4B03-PseudoLong-Isolated.xcresult`; this supports an
environmental long-run transition miss, but does not erase the integrated non-pass. Two isolated
strict Dashboard attempts under the same loaded host measured 0.870945 and 0.752715 seconds against
the 0.5-second local signal; the latter is retained at
`/private/tmp/MindBudget-C4B03-PerformanceFinal.xcresult`. Neither is claimed as a performance
pass. The earlier accepted `/private/tmp/MindBudget-C4B03-Full1.xcresult` remains prior full-suite
regression context, not an exact-head substitute: it passed the strict benchmark, 456/456 units,
17/17 UI, and coverage before the final lineage-overflow hardening below.

Final source review found that advancing an already accepted or conflicted lineage at `Int64.max`
could trap on integer overflow. DEC-COM-035 centralizes revision advancement as a throwing,
fail-closed operation used by staging, remote acceptance, and explicit conflict resolution. The
exact-head simulator run rebuilt the app and passed 34 `CloudSyncTests` results: 33 deterministic
passes plus the one compile-time physical case explicitly skipped, with zero failures at
`/private/tmp/MindBudget-C4B03-LineageBound.xcresult`. The later exact-head full result below closes
the local UI/coverage gap; hosted CI remains a separate gate.

A separate compile-time opt-in two-device harness was then built and signed for physical
`拉沙的iPhone` (iPhone Air, iOS 26.6.1 `23G82`) and `Xiao li的 iPhone (2)` (iPhone 16, iOS
26.5.2 `23F84`). The second device was paired, registered to team `2AM5S7BM2N`, placed in
Developer Mode, and granted the app's local-network permission. Initial attempts were non-passes
while that permission was denied. After permission was enabled, non-content one-way account
fingerprints proved that the devices were signed into different iCloud Apple Accounts. Because a
private CloudKit database is scoped to its
iCloud account, these devices cannot observe one another's private-zone records. The owner chose
not to switch accounts and explicitly stopped this two-device evidence attempt. No convergence or
conflict pass is claimed, and the compile-time harness remains only a future evidence tool.

The interrupted primary attempt left one Development seed in the fixed test zone. The first
cleanup run imported that seed and therefore failed an older local-only count assertion before its
whole-zone cleanup completed; it is retained as a non-pass at
`/private/tmp/MindBudget-C4B03-PostMultiCleanup.xcresult`. A second cleanup run against the now-empty
zone passed 33/33 with zero failures at
`/private/tmp/MindBudget-C4B03-PostMultiCleanup2.xcresult`, confirming that the fixed Development
zone is clean. This is cleanup evidence only, not two-device convergence evidence.

The ordinary simulator configuration was then rebuilt without any physical-device compilation
condition. Its 36 results contain 33 deterministic passes and three explicit skips for the
single-device, multi-device-primary, and multi-device-secondary physical cases, with zero failures
at `/private/tmp/MindBudget-C4B03-PostMultiDefault.xcresult`. The retained harness therefore cannot
contact CloudKit during ordinary simulator or hosted-CI execution.

The final current-source `Scripts/validate.sh` run passed at
`/private/tmp/MindBudget-C4B03-ExactHeadFull2.xcresult`: every static contract, Release
compilation, 460 unit-test results across 27 suites, 17/17 UI tests, and all selected coverage
thresholds. The three physical CloudKit cases were explicit skips; no remote request occurred. The
minimum selected coverage remained CSVExporter at 87.60% against the required 85%. This run used
the documented `MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1` path after two loaded-host strict attempts
had already been recorded as non-passes. It therefore does not claim a new exact-head wall-clock
result; the earlier accepted strict pass in `MindBudget-C4B03-Full1.xcresult` remains separate
Dashboard regression evidence because the later production changes are confined to CloudSync.

Still pending: physical offline/quota/account transitions;
two-device convergence and conflict resolution (the owner stopped the current different-account
attempt without treating it as passed); push/background-delivery observation; a true
distribution-signed Archive; Production schema deployment; independent review; hosted CI; and
merge. Production schema deployment requires explicit owner acceptance.

### PR #61 review remediation — 2026-08-22

Independent review found that the local Delete All path preserved the UserDefaults retention
marker but replaced the current `AppSession` snapshot with literal `.disabled`, temporarily hiding
both the reimport disclosure and cloud-delete action. The remediation removes that synthetic state:
after the local store is cleared, `CloudSyncService.refreshAfterLocalDataDeletion()` publishes the
disabled local control combined with the retained-copy marker. The AppSession regression verifies
that ordinary Enable remains rejected without constructing an adapter, confirmed reimport enables
transport, and the cloud-delete presentation remains available in the same session.

The same focused run also verifies closed network/account/quota/failure guidance for durable cloud
deletion and that a content-free server conflict cannot expose either resolution action or mutate
the local fact. Cloud-wide deletion documentation now distinguishes durable local tombstone intent
from the stronger final whole-zone absence postcondition, and the environment contract distinguishes
historical C4B-01/C4B-02 no-entitlement state from current C4B-03 entitlements.

The exact focused command completed 52 tests in `CloudSyncTests` and `Phase6FeatureTests` with zero
failures at `/private/tmp/MindBudget-C4B03-ReviewRemediation-Focused1.xcresult`; the three physical-
only CloudKit cases were explicit skips. Static/full validation and hosted CI are recorded
separately and remain required for the new review head.

The first `Scripts/validate.sh` attempt for this head ran inside the filesystem sandbox. Its static
checks passed, but CoreSimulator was unavailable and DerivedData writes were denied, so the Release
build stopped and that attempt is an environment non-pass rather than product evidence.

The accepted rerun outside that sandbox passed every static contract, Release compilation, 461
unit-test results across 27 suites, 17/17 UI tests, and every selected coverage threshold at
`/private/tmp/MindBudget-C4B03-ReviewRemediation-Full2.xcresult`. The three physical CloudKit cases
were explicit skips and made no network request. Minimum selected coverage remained CSVExporter at
87.60% against the required 85%. `MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1` preserved the previously
recorded loaded-host decision and does not manufacture a new strict performance result. Hosted CI
on the pushed remediation head remains a separate merge gate.

### PR #61 reviewed product merge — 2026-08-22

Independent rereview approved exact head `f49de948b88c9fc42aff996b6e90fd835742ca41`. GitHub Actions
run `32571676058` completed successfully on that same head, with `Build and test` green after
19m36s. PR #61 then merged it to `main` as
`0f749ce18b877969248fb3e4e7c0b28df21139af` at 2026-08-22 12:17:31 UTC. This closes the product
code's review, hosted-CI, and merge gates.

C4B-03 is not Done. The owner temporarily deferred a same-iCloud-account two-device rerun because
that test arrangement is currently unavailable. The earlier different-account attempt and this
deferral remain an explicit evidence gap, not a pass, product failure, permanent waiver, or basis
for unblocking C4C. Physical account/offline/quota/background-push, distribution signing, and
owner-authorized Production deployment/release evidence remain open.

The post-merge documentation calibration changes no runtime source. Money, network-egress,
commercialization-document, StoreKit catalog 13/13, iCloud contract self-test/repository, Python
syntax, shell syntax, and diff checks pass locally. A first document-gate run rejected its own old
exact status anchor and a first Python compile-only check hit the host's unwritable default cache;
both passed after the contract phrase was calibrated and bytecode cache was scoped to
`/private/tmp`. No new simulator, physical, CloudKit, Production, Archive, or release evidence is
inferred from this documentation-only validation.

### PR #62 calibration merge and owner evidence waiver — 2026-08-22

Reviewed calibration head `0350415e7d79ef20901a05fcc2424be860ff6f9a` passed GitHub Actions run
`32573992659`; its `Build and test` check completed successfully. PR #62 merged it to `main` as
`0128682838ee9bf89cd071307f8355a97109cb59` at 2026-08-22 13:14:29 UTC.

After that merge, the owner permanently waived the physical same-iCloud-account two-device
convergence/conflict evidence gate. DEC-COM-039 records the scope: the stopped different-account
attempt is still not a pass, deterministic multi-device conflict/no-winner behavior remains
required, and the opt-in harness remains available. The waiver does not close C4B-03; physical
account/offline/quota/background-push, distribution signing, and owner-authorized Production/
release evidence remain open.

The permanent-waiver calibration changes documentation and its static gate only. Money,
network-egress, commercialization-document, StoreKit catalog 13/13, iCloud contract self-test/
repository, Python syntax, shell syntax, and diff checks pass locally. No runtime, simulator,
physical, CloudKit, Production, archive, upload, tester, or release evidence is created.

### PR #63 merge and automatic-scheduling correction candidate — 2026-08-22

Reviewed waiver head `7b2349001b8e1228def6e34211cbf09785977f41` passed GitHub Actions run
`32576885537`; `Build and test` completed successfully. PR #63 merged it to `main` as
`1a14df96d40d3248190d55861f88327407ea8f77` at 2026-08-22 14:20:56 UTC. This closes only the
narrow evidence-scope PR. C4B-03 remains In Progress.

The next evidence audit found `configuration.automaticallySync = false` in the production
`CKSyncEngine` construction path. DEC-COM-040 changes that closed scheduling contract to `true`
while retaining explicit start/foreground Retry. The iCloud contract self-test/repository scan,
Python syntax, and `git diff --check` passed after the source/static-anchor update. The selected
CloudSync suite then passed 38 results at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused1.xcresult`: 35 deterministic passes and three
explicit physical-only skips, zero failures. This proves configuration/regression behavior only;
it does not close physical background-push evidence.

Read-only local signing inventory contains Apple Development identities but no Apple Distribution
identity. No Distribution archive, Production schema deployment, TestFlight upload, or release
action was attempted. Apple documents `CKError.quotaExceeded` as real private-database quota state;
no supported non-destructive Development simulation was identified, so no storage-filling action
is accepted as evidence. The quota gate remains open pending an owner-approved evidence boundary or
a legitimately quota-limited test account.

The exact-head full local validation then passed every static contract, Release compilation, 462
unit-test results across 27 suites, 17/17 UI tests, and every selected core-service coverage
threshold at `/private/tmp/MindBudget-C4B03-AutomaticSync-Full1.xcresult`. `xcresulttool` reports
479 total results, zero failures, 469 passes, and ten explicit skips across the combined unit/UI
bundle. The physical CloudKit cases remained opt-in and made no network request. Minimum selected
coverage remained CSVExporter at 87.60% against the required 85%. The wall-clock benchmark was
explicitly skipped under the previously accepted loaded-host boundary, so this run creates no new
strict performance claim. A physical Development rerun was prepared separately, but Xcode reported
the paired iPhone unavailable while browsing the local network and requested an unlocked attached
device; no physical result, remote mutation, or push claim is inferred from that environment
non-pass.

After the device was reattached and kept unlocked, the exact opt-in Development command passed all
38 selected `CloudSyncTests` at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Physical2.xcresult`: 36 passes, the two permanently
waived multi-device roles explicitly skipped, and zero failures on `拉沙的iPhone` (iPhone Air,
iOS 26.6.1). The real private-database case created the fixed Development zone, sent and fetched
the encrypted envelope, disabled sync, required confirmed reimport, deleted the whole test zone,
and retained the local expense. Runtime diagnostics also showed `CKSyncEngine` background-task
registration after automatic scheduling was enabled. This is renewed Development lifecycle and
scheduler-registration evidence; because no independent remote mutation arrived while the app was
backgrounded, it is not recorded as a silent-push pass. Production remained untouched.

### C4B-03 physical background-push evidence disposition — 2026-08-24

Nine local result packages were inspected:
`/private/tmp/MindBudget-C4B03-BackgroundPush6.xcresult` through
`/private/tmp/MindBudget-C4B03-BackgroundPush14.xcresult`. Their accepted evidence is intentionally
negative: zero packages prove an independently initiated Development mutation reaching the app
while it remained backgrounded.

- Run 6 reached the physical suite but failed in `.pausedRemoteZoneDeleted` before a ready probe.
- Runs 7 and 8 timed out after 180 seconds waiting for `observedExternalDeletion`; no external
  deletion was performed.
- Runs 9 and 10 timed out after 600 seconds while the CloudKit Console account path was being
  corrected; no qualifying external deletion was observed.
- Run 11 failed initial cleanup while the phone still used the broken `127.0.0.1:1082` proxy.
- Run 12 could not launch because the developer certificate was not yet trusted.
- Run 13 selected zero tests because its `-only-testing` filter was wrong.
- Run 14 was the exact single probe and reached its READY marker, but it was canceled after the
  CloudKit Console was found to be acting as the wrong account. No external deletion or silent-push
  observation occurred.

The probe did expose two source defects independently of delivery timing. DEC-COM-041 records their
repair: delegate-triggered cancellation leaves the serialized callback task and clears only the
matching engine, while a restored transport with accepted serialization fetches first and may not
recreate a missing zone. After the final source correction, the simulator CloudSync suite passed
37 tests with four physical-only skips and zero failures at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused6.xcresult`.

DEC-COM-042 permanently removes only the physical background/silent-push observation from
C4B-03/COM-C4B exit evidence. This is not a pass. The nine packages remain non-pass evidence, and
the opt-in probe remains an optional diagnostic. No Production environment was contacted or
modified. Because the final READY probe was interrupted before its ordinary cleanup completed, the
fixed Development test zone/record is conservatively treated as potentially remaining; no cleanup
claim is made and no browser-side deletion was performed. Physical account/offline/quota,
distribution signing, and explicitly authorized Production deployment/release evidence remain
open, so C4B-03 remains In Progress.

### Exact-head waiver/correction validation — 2026-08-24

Validation exposed an XCTest-only accessibility-query instability after the product and contract
changes were complete. SwiftUI alternated the quick-add actions between `Button` and
`DisclosureTriangle`, and in another launch exposed the same identifier on nested nodes. The UI
tests now query the stable identifier across element types and select the first matching node. The
four directly affected flows then passed 4/4 at
`/private/tmp/MindBudget-C4B03-Waiver-UIRerun5.xcresult` (English and Simplified Chinese category
legend, Insights, and the manual expense/income flow).

Earlier full-run attempts in this session are retained as non-green diagnostics: one produced two
transient UI failures that immediately passed 2/2 when focused; a second accumulated simulator
session pollution and its three affected tests passed 3/3 after a cold boot; a third reproduced the
cross-type quick-add query mismatch and motivated the harness hardening above. None is represented
as product evidence or silently promoted to a pass.

After a simulator cold boot, the exact source/document head passed the complete validation entry at
`/private/tmp/MindBudget-C4B03-Waiver-Full4.xcresult`: all static contracts, Release compilation,
465 unit-test results, 17/17 UI tests, and every selected core-service coverage threshold.
`xcresulttool` reports 482 logical results, zero failures, 471 passes, and eleven explicit skips;
the minimum selected coverage remains CSVExporter at 87.60% against the required 85%. The accepted
loaded-host option explicitly skipped the strict wall-clock benchmark, so this run creates no new
strict performance claim.

This green simulator evidence validates the source correction, deterministic contracts, and test
harness only. It does not change DEC-COM-042: physical background/silent-push observation has zero
passes and is permanently waived rather than passed. Physical account/offline/quota, distribution
signing, and explicitly authorized Production deployment/release evidence remain open; C4B-03 and
COM-C4B remain In Progress, and C4C remains blocked.

### C4B-03 final merge and evidence disposition — 2026-08-24

Reviewed correction head `f1f37db` passed every step of GitHub Actions run `32726507493`; PR #64
merged it to `main` as `4f6d7fe`. This is the final runtime source evidence for C4B-03. The
preceding 482-result exact-head validation, one successful physical Development zone lifecycle,
read-only Dashboard environment/shape check, and deterministic account/offline/quota/conflict/
deletion coverage remain the accepted technical evidence.

Closeout inventory found one paired physical iPhone available and no valid local Distribution
codesigning identity. Production still has no deployed app schema, and no Production, Archive,
upload, tester, or release action was attempted. Under owner-approved DEC-COM-043, physical
account-switch/offline/quota observations join the earlier same-account and background-push items
as permanently waived non-passes. Distribution signing and explicitly authorized Production
schema/deployment/release proof move to COM-C6/COM-C12 and remain mandatory there. This evidence
ownership closes C4B-03/COM-C4B and unblocks C4C without creating a physical pass or release claim.

The documentation-only closeout head passed `Scripts/validate.sh` locally after an initial
sandbox-only CoreSimulator/DerivedData access failure was excluded as environment evidence. The
accepted rerun passed every static contract, Release compilation, 465 unit-test results across 27
suites, 17/17 UI tests, and every selected core-service coverage threshold. Four physical-only
CloudSync probes remained explicit skips; the minimum selected coverage was CSVExporter at 87.60%
against the required 85%. The validation script's ephemeral result bundle was
`mindbudget-validation.D9L30N/MindBudget.xcresult` during the run and was removed by its normal
temporary-directory cleanup after success.

### C4C-01 premium seams and rule evidence candidate — 2026-08-25

The final focused entitlement, rule-evidence, persistence, and exact-Free regression matrix passed
92/92. One earlier diagnostic run exposed an overstated test-only inline-card expectation; the
accepted regression proves the existing interrupting reminder, manual save, reminder history, and
durable Insights row without injecting Pro into existing tests.

The complete local validation entry passed at `/private/tmp/MindBudget-C4C01-Full.xcresult`: every
static contract, Release compilation, strict wall-clock stage, 468 unit-test results across 27
suites, 17/17 UI tests, and all selected core-service coverage thresholds passed. `xcresulttool`
reports 485 logical results, zero failures, 474 passes, and eleven explicit skips on iPhone 17 Pro,
iOS 26.5 (`23F77`). The four physical-only CloudKit probes remain intentional skips and create no
C4C-01 physical claim. CSVExporter is the minimum selected coverage result at 87.60% against the
required 85%.

### C4C-01 reviewed merge closeout — 2026-08-25

Independent review found no P1/P2 issue on exact head `d203308`. GitHub Actions run `32845307426`
then completed successfully on that same head, including every static contract and the hosted Xcode
Build and test job. PR #66 merged the reviewed source to `main` as `8611022` at 2026-08-25
12:29:19 UTC.

This closes C4C-01 only. The existing local evidence above remains the owning behavioral proof;
the hosted run provides reviewed-head CI provenance rather than a new physical, Production,
Archive/upload, tester, or release claim. Receipt import remains disabled, and C4C-02 requires an
explicit owner entry before image acquisition work may begin.

The documentation-only closeout branch also passed `Scripts/validate.sh`: every static contract,
Release compilation, the strict Dashboard wall-clock stage, 468 unit-test results across 27
suites, 17/17 UI tests, and every selected core-service coverage threshold passed. CSVExporter was
the minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit probes
remained explicit skips; this validation creates no new physical or release claim.

### C4C-02 bounded image lifecycle candidate — 2026-08-25

The final focused C4C-02 run passed 10/10 at
`/private/tmp/MindBudget-C4C02-Focused5.xcresult` on iPhone 17 Pro, iOS 26.5 (`23F77`). The suite
covers capability fail-closed decisions, encoded-byte and decoded-pixel limits, corrupt input,
EXIF orientation/downsampling, perspective geometry boundaries, lifecycle and caller cancellation,
startup orphan cleanup, and repeated proof that only prepared bytes survive until explicit cleanup.

The complete local `Scripts/validate.sh` entry passed all static contracts, Release compilation,
the strict Dashboard wall-clock stage, 478 unit-test results across 28 suites, 17/17 UI tests, and
every selected core-service coverage threshold. Four physical-only CloudKit probes remained
explicit skips. CSVExporter was the minimum selected coverage result at 87.60% against the required
85%. The full bundle path was
`mindbudget-validation.e1BLKF/MindBudget.xcresult` during execution and was removed by the script's
normal temporary-directory cleanup after success.

This is simulator and deterministic lifecycle evidence only. It makes no OCR/accuracy, 20-image
resource-stability, physical-device, Production, Archive/upload, tester, review, or release claim.
Hosted CI on the reviewed PR head remains the merge gate.

### C4C-02 reviewed merge and documentation closeout — 2026-08-26

Independent review found no P1/P2 issue on exact source head `43c3a35`. GitHub Actions run
`32860643712` completed successfully on that head, and PR #68 merged it to `main` as `4ca8f1c`.
This closes only C4C-02; receipt import stays disabled, and C4C-03 requires separate owner entry.

The documentation-only closeout branch then passed `Scripts/validate.sh`: every static contract,
Release compilation, the strict Dashboard wall-clock stage, 478 unit-test results across 28
suites, 17/17 UI tests, and every selected coverage threshold passed. CSVExporter remained the
minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit probes
remained explicit skips. The result bundle was
`mindbudget-validation.iJejGl/MindBudget.xcresult` during execution and was removed by normal
temporary-directory cleanup. This evidence adds no physical, OCR/accuracy, Production,
Archive/upload, tester, distribution, or release claim.

Documentation head `4ab0daf` subsequently passed GitHub Actions run `32911659905`, and PR #69
merged the C4C-02 closeout to `main` as `3e1c5c9`. That documentation merge is predecessor evidence
only; it did not enter C4C-03 automatically.

### C4C-03 local OCR/privacy candidate — 2026-08-26

After the owner's explicit C4C-03 entry, the first focused attempt at
`/private/tmp/MindBudget-C4C03-Focused1.xcresult` failed at test compilation because a throwing
filter call was placed directly inside a Testing `#require` macro. It executed no C4C-03 test and
is excluded from pass evidence. The test separated the throwing call from the optional requirement
without changing production behavior.

The final focused run at `/private/tmp/MindBudget-C4C03-Focused4.A42MrA/MindBudget.xcresult` passed 7/7 tests in
one suite on iPhone 17 Pro, iOS 26.5. It covers English and Chinese card/last-four/authorization
patterns, full-width digits, ordinary-text preservation, control normalization, deterministic
reading order and tie breaks, geometry/confidence retention, and fail-closed policy/count/line/
document/geometry/confidence limits. This is deterministic privacy-boundary evidence, not receipt-field
accuracy, physical DataScanner/PHPicker/OCR, 60+ fixture, 20-image stability, Production, Archive,
upload, tester, review, distribution, or release evidence.

The complete validation then passed every static contract, Release compilation, the strict
Dashboard wall-clock stage, 485 unit-test results across 29 suites, all 17 UI tests, and every
selected core-service coverage threshold. CSVExporter was the minimum selected result at 87.60%
against the required 85%. Four physical-only CloudKit probes remained explicit skips. The ephemeral
result bundle `mindbudget-validation.dcltId/MindBudget.xcresult` was removed by normal script cleanup.
Independent review and hosted CI remain merge gates for this candidate.

An immediately preceding sandboxed invocation passed the static contracts but could not access
CoreSimulator or the user DerivedData directory and stopped before an Xcode test result existed. It
is environment non-pass evidence and is excluded; the identical outside-sandbox rerun above is the
accepted complete validation.

Independent review of PR #70 found no P1/P2 issue and identified one optional ordering-regression
hardening item. The review fix documents that the complete-card rule must precede the labelled
last-four rule and adds a labelled, separated sixteen-digit regression case that would expose the
twelve-digit remainder if those rules were reordered. The exact review-fix source passed 7/7 focused
tests at `/private/tmp/MindBudget-C4C03-ReviewFix-Focused5.hKVLun/MindBudget.xcresult`. The production
patterns and phase scope are unchanged; hosted CI on the new exact head remains the merge gate.

### C4C-03 reviewed merge and documentation closeout — 2026-08-26

Exact source head `92ed3a7` passed independent review without a P1/P2 issue. GitHub Actions run
`32921913143` completed successfully on that exact head, and PR #70 merged the bounded local
OCR/privacy substrate to `main` as `d294cfb`. The accepted ordering regression is included in that
reviewed head. This evidence closes C4C-03 only: `enableReceiptImport` remains false, and C4C-04
still requires a separate explicit owner instruction.

The documentation closeout itself adds no physical OCR, receipt-field accuracy, 60-plus-fixture,
20-image resource-stability, confirmation/persistence, Production, Archive/upload, tester,
distribution, or release evidence. Its complete local validation result is recorded below after
the exact closeout source has passed the repository's full validation entry.

That documentation-only source passed `Scripts/validate.sh`: every static contract, Release
compilation, the strict Dashboard wall-clock stage, 485 unit-test results across 29 suites, all
17 UI tests, and every selected core-service coverage threshold passed. CSVExporter was the
minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit probes
remained explicit skips. The ephemeral result bundle
`mindbudget-validation.IyfM8i/MindBudget.xcresult` was removed by normal script cleanup.

### C4C-04 structured extraction candidate — 2026-08-26

After explicit owner entry, the pre-review focused command targeting
`MindBudgetTests/ReceiptStructuredExtractionTests` passed 16/16 at
`/private/tmp/MindBudget-C4C04-FocusedFinal.xcresult` on iPhone 17 Pro, iOS 26.5. The
suite covers deterministic core extraction; locale-aware integer USD/JPY/KWD parsing; typed
date/currency/scale/range/missing/ambiguous failures; exact duplicate matching; on-device-model
evidence provenance, precedence, unavailable/error/timeout fallback; and the production-default-off
line-item experiment. A first compiled run exposed and corrected the JPY grouping/locale branch;
the corrected suite is the accepted focused evidence.

This is deterministic simulator evidence only. It is not the C4C-05 60-plus receipt/non-receipt
accuracy matrix, physical DataScanner/PHPicker/Vision evidence, 20-image resource stability,
confirmation/persistence proof, Production, Archive/upload, tester, distribution, or release
evidence. The complete repository validation and hosted CI on the independently reviewed head
remain merge gates.

The exact candidate passed `Scripts/validate.sh`: all static contracts, Release compilation, the
strict Dashboard wall-clock stage, 501 unit-test results across 30 suites, 17/17 UI tests, and all
selected core-service coverage thresholds passed. CSVExporter was the minimum selected result at
87.60% against the required 85%. Four physical-only CloudKit probes were explicit skips. The
ephemeral bundle was `mindbudget-validation.hAXTHp/MindBudget.xcresult` during execution and was
removed by normal script cleanup. Hosted CI on the independently reviewed head remains the merge
gate; this evidence makes no C4C-05 physical, fixture-accuracy, resource-stability, persistence,
Production, Archive/upload, tester, distribution, or release claim.

PR #72 review remediation added two fail-closed regression shapes without broadening C4C-04. The
focused `ReceiptStructuredExtractionTests` command passed 17/17 at
`/private/tmp/MindBudget-C4C04-ReviewFix-Focused.xcresult` on iPhone 17 Pro, iOS 26.5. It proves
that one invalid numeric token rejects the entire same-line total candidate and that an optional
model cannot replace deterministic `.rejected`, while the existing missing-field supplement path
still passes.

The replacement exact source passed the complete `Scripts/validate.sh` entry: all static
contracts, Release compilation, the strict Dashboard wall-clock stage, 502 unit-test results
across 30 suites, all 17 UI tests, and every selected core-service coverage threshold passed.
CSVExporter remained the minimum selected result at 87.60% against the required 85%. Four
physical-only CloudKit probes were explicit skips. The ephemeral result bundle was
`mindbudget-validation.5DL4A2/MindBudget.xcresult` during execution and was removed by normal
script cleanup. Hosted CI on the replacement exact head remains required before merge; this
review remediation does not advance C4C-05 or any physical, accuracy, persistence, Production,
distribution, or release gate.

### C4C-04 reviewed merge and documentation closeout — 2026-08-26

Independent rereview approved exact remediation head `f2d249d`. GitHub Actions run `32946104780`
completed successfully on that exact head in 19m39s, and PR #72 merged it to `main` as `e6316fa`.
The reviewed head contains the 17/17 focused fail-closed regressions and the complete local
validation result recorded above. This closes C4C-04 implementation/review/CI/merge only.

`enableReceiptImport` remains false, all structured candidates remain ephemeral, and C4C-05
remains blocked pending separate explicit owner entry. This documentation closeout adds no
physical acquisition/OCR, receipt/non-receipt accuracy, 20-image resource stability,
confirmation-before-persistence, Production, Archive/upload, tester, distribution, or release
evidence.

The exact documentation-only closeout source then passed `Scripts/validate.sh`: every static
contract, Release compilation, the strict Dashboard wall-clock stage, 502 unit-test results
across 30 suites (491 passed and 11 explicit physical-only skips), all 17 UI tests, and every
selected core-service coverage threshold passed. CSVExporter remained the minimum selected
result at 87.60% against the required 85%. The original ephemeral bundle was
`mindbudget-validation.TbfLO2/MindBudget.xcresult`; normal script cleanup removed it after the
run. A read-only mirror at `/private/tmp/MindBudget-C4C04-closeout-final.xcresult` parsed as
`Passed` with zero failures and independently passed `Scripts/check-coverage.sh`. This remains
documentation-closeout evidence only; independent review, green hosted CI, and merge are still
required.

### C4C-05 local confirmation/evaluation candidate — 2026-08-26

After explicit owner entry, the local candidate enabled the verified-Pro receipt-import entry in
the existing new-expense form. DataScanner capture and PHPicker selection feed a bounded temporary
image into local Vision recognition and deterministic structured extraction off the main actor.
Only accepted merchant, date, and total values may prefill the editable form; the existing Save
action remains the sole SwiftData persistence boundary. Source/prepared images, OCR text, optional
model evidence, and duplicate evidence remain ephemeral and have no network-egress path.

The exact focused command covering `ReceiptImportIntegrationTests`, `ReceiptImageLifecycleTests`,
`ReceiptOCRPrivacyTests`, and `ReceiptStructuredExtractionTests` passed 40/40 with zero failures
and zero skips at `/private/tmp/MindBudget-C4C05-Focused.xcresult` on iPhone 17 Pro, iOS 26.5. The
matrix includes 60 exact deterministic receipt fixtures (20 USD, 20 JPY, and 20 KWD), 10
nonreceipt fixtures with no accepted total, review-prefill proof that SwiftData remains empty until
the existing explicit Save action, receipt-source persistence after that action, and 20 sequential
real-JPEG processing iterations with bounded pixels, at most one active temporary artifact, and
zero residue after every iteration.

The same local candidate passed the complete `Scripts/validate.sh` entry at
`/private/tmp/MindBudget-C4C05-Full.xcresult`: all static contracts, Release compilation, the
strict 10,000-row Dashboard wall-clock stage, 508 unit-test cases across 31 suites (497 passed and
11 explicit physical-only skips), all 17 UI tests, and every selected core-service coverage
threshold passed. CSVExporter was the minimum selected result at 87.60% against the required 85%.
The result summary contains 525 logical results because parameterized cases are expanded by the
result bundle; 514 passed and 11 were explicit physical-only skips.

No attached physical device was online during this candidate run. DataScanner capture, PHPicker
selection, and their resulting local Vision OCR therefore remain unexecuted physical evidence,
not passes. Independent review, green hosted CI on the exact reviewed head, and merge also remain
open. This entry does not mark C4C-05, COM-C4C, either receipt Requirement, Production,
Archive/upload, tester, distribution, or release evidence Done.

### C4C-05 physical remediation and manual evidence — 2026-08-26

Physical device: `拉沙的iPhone`, iOS 26.6.1. Toolchain: Xcode 27 beta 6 (`27A5252f`). The first
camera attempts failed closed; the non-content diagnostic was `ocr.invalidGeometry`. Remediation
keeps the existing byte/pixel limits, derives a lower ImageIO thumbnail edge when the pixel ceiling
requires it, and clamps only normalized Vision drift within 0.005. The exact focused simulator
result `/private/tmp/MindBudget-C4C05-PhysicalRemediation.xcresult` passed 21/21 across
`ReceiptImageLifecycleTests` and `ReceiptOCRPrivacyTests`, including the 4032 x 3024 capture and
bounded-versus-material geometry cases.

After deployment, a DataScanner paper-invoice capture reached local Vision review. Merchant/date
were accepted; total stayed manual-review-only. Apply followed by cancel created zero expenses. A
separate one-image PHPicker path reached review and explicit Save created exactly one `$25.00`
expense. This is physical acquisition/OCR and persistence-boundary evidence, not a broad accuracy
claim. Independent review, hosted CI, and merge remain required.

After those physical remediations, the exact final repository entry passed at
`/private/tmp/MindBudget-C4C05-Final.xcresult`: 510 unit-test results across 31 suites (499 passed
and 11 explicit physical/runtime skips), 17/17 UI tests, Release compilation, the strict 10,000-row
Dashboard wall-clock stage, all static contracts, and all selected coverage thresholds. The
result-bundle summary contains 527 logical results after the 17 UI cases and parameterized-test
expansion are included: 516 passed, 11 skipped, and zero failed. CSVExporter remained the minimum
selected coverage result at 87.60% against 85%.

### C4C-05 receipt capture redesign candidate — 2026-08-27

DEC-COM-053 implements the owner's redesign through recommended option A. The app target and the
focused receipt-import, image-lifecycle, OCR-privacy, structured-extraction, localization, and
settings suites compile and pass on iPhone 17 Pro simulator under Xcode 27 beta 6. The source uses
DataScanner with guidance disabled and contains no live DataScanner delegate or new rectangle-frame
pipeline; the custom frame remains white and makes no automatic-crop claim.

This focused evidence covers the redesigned acquisition state, generation cancellation, manual
amount Save release, fail-closed inline error mapping, first-use preference persistence/reset, and
the unchanged receipt privacy/extraction boundaries. It is not new physical receipt evidence and
does not supersede the recorded iOS 26.6.1 DataScanner/PHPicker/OCR observations.

The exact redesigned source then passed `Scripts/validate.sh` at
`/private/tmp/MindBudget-C4C05-Redesign-Final2.xcresult`: all static contracts, Release compilation,
the strict 10,000-row Dashboard wall-clock stage, 514 unit-test results across 31 suites, all 17 UI
tests, and every selected coverage threshold. The result summary contains 531 total tests, 520
passed, 11 explicit opt-in/runtime skips, and zero failed; CSVExporter remains the minimum selected
coverage result at 87.60% against 85%. Independent review, hosted CI, and merge remain open.

### C4C-05 independent-review remediation focused evidence — 2026-08-27

Final Xcode 26.6 `build-for-testing` compiles the MindBudget, MindBudgetTests, and MindBudgetUITests
targets after DEC-COM-054. The focused simulator command under Xcode 27 beta 6 on iPhone 17 Pro,
iOS 26.5, executes `ReceiptImportIntegrationTests` and `ReceiptImageLifecycleTests`. Result bundle
`/private/tmp/MindBudget-C4C05-ReviewFix-Focused2.xcresult` passes 22/22 tests with zero failures and
zero skips.

This exact run proves that the production recognition path remains empty before explicit Save,
rejected/missing fields cannot overwrite user input, edit-then-return-to-starting-value protects
amount/merchant/date, product/Pro acquisition gates keep truthful typed failures, and stale
artifact cleanup cannot delete a newer generation. A Designed-for-iPhone-on-Mac attempt was stopped
before test execution by a provisioning-profile mismatch and is not counted.

The exact remediated source then passed `Scripts/validate.sh` at
`/private/tmp/MindBudget-C4C05-ReviewFix-Final.xcresult`: every static contract, Release
compilation, the strict 10,000-row Dashboard wall-clock stage, 522 unit-test results across 31
suites, all 17 UI tests, and every selected coverage threshold passed. The result-bundle metrics
report 539 logical results, 528 passed, 11 explicit opt-in/runtime skips, and zero failed;
CSVExporter remains the minimum selected coverage result at 87.60% against 85%. Independent
rereview, hosted CI, and merge remain open.

### C4C-05 P3 review-maintenance evidence — 2026-08-27

The bounded recognition wait, surface-neutral unreadable-image localization keys, and
compiler-enforced receipt-field mutation boundary compile and pass 76/76 focused tests across
`ReceiptImportIntegrationTests`, `Phase3FeatureTests`, `Phase4FeatureTests`, and
`Phase5FeatureTests` at `/private/tmp/MindBudget-C4C05-P3Fix-Focused2.xcresult`. The preceding
restricted attempt could not connect to CoreSimulator and is an environmental non-pass. No product,
persistence, egress, entitlement, or release boundary changed; hosted CI on the new exact head
remains required.

### C4C-05 merge calibration and post-merge exact-delta closeout — 2026-08-27

Independent review approved remediation head `8607356` and raised three nonblocking P3
observations. Final maintenance head `81cd107` applied them: the recognition wait exits on
completion with an explicit timeout, unreadable-image copy uses the shared surface-neutral keys,
and amount/merchant/date mutation is compiler-enforced through `private(set)` state and explicit
user-input methods. The focused P3 suite passed 76/76 before hosted validation.

GitHub Actions run `33035427257` completed successfully on exact head `81cd107` in 26m06s. PR #74
then merged the C4C-05 implementation/evaluation and capture redesign to `main` as `d751ff4`
without a pre-merge rereview. During PR #75's 2026-08-27 closeout review, the independent reviewer
read that exact maintenance delta and confirmed all three P3 fixes correct. Together with the
already-recorded 60-receipt/10-nonreceipt matrix, 20-image lifecycle,
zero-leak tests, complete 522-unit/17-UI local validation, and physical iOS 26.6.1 acquisition/
confirmation observations, this closes C4C-05 and COM-C4C.

The uncertain total on the physical paper invoice remains a manual-review-only non-pass, not a
population-wide accuracy success. This closeout adds no new physical run, network egress, CloudKit
receipt field, Production deployment, Archive/upload, tester, distribution, or release evidence.
COM-C5 remains unopened pending explicit owner entry and its accepted telemetry conflict
resolution. The documentation-only closeout still requires its own independent review, green
hosted CI, and merge.

The documentation-only closeout branch passed `Scripts/validate.sh` at
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.3SiQ1W/MindBudget.xcresult`.
All static contracts, Release compilation, the strict 10,000-row Dashboard wall-clock stage, the
complete unit-test execution, all 17 UI tests, and every selected coverage threshold passed.
`CSVExporter.swift` remains the minimum selected coverage result at 87.60% against 85%. The
validator removed the temporary result bundle after completion, so this path is an execution
pointer rather than a durable artifact.

### C5-01 dormant typed telemetry candidate — 2026-08-27

The focused simulator command executes `TelemetryClientTests` and passes 13/13 with no failure or
skip. It covers missing-state default-off behavior, exact closed JSON, invalid app-version rejection,
opt-out/re-enable unlinkability, serialized concurrent capture, queue overflow, manual and automatic
rotation, same-generation batching, concurrent capture during upload, a gated transport lane that
prevents concurrent flushes from duplicating one batch, retry/backoff, deletion-proof
retention and confirmed destruction, sticky corruption, and encrypted file round trip.

The first `Scripts/validate.sh` attempt ran in a restricted environment that denied CoreSimulator
access and yielded an empty application bundle identifier. It stopped before trustworthy execution
and is excluded as an environmental non-pass. The unrestricted rerun then passed the telemetry,
money, network, commercialization-document, StoreKit catalog, and all other static contracts;
Release compilation; the strict 10,000-row Dashboard benchmark; 530 unit tests across 32 suites;
all 17 UI tests; and every selected coverage threshold. Four opt-in physical CloudKit probes were
reported as skipped. `CSVExporter.swift` was the minimum selected result at 87.60% against the 85%
floor. The validator removed
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.XVH9gD/MindBudget.xcresult`
after success, so this path is an execution pointer rather than a durable artifact. Hosted CI on
the eventual exact PR head remains required.

### C5-01 independent-review remediation — 2026-08-27

The focused iOS 26.5 simulator command executes `TelemetryClientTests` and passes 17/17 with no
failure or skip. Four added tests cover the four-generation re-enable boundary, explicit grouping
of every retained generation in the complete-delete request, deletion of sticky invalid protocol
state without a remote claim, and deletion of both a corrupted encrypted file and its at-rest key.
The existing corruption test continues to prove that opt-in/capture cannot overwrite invalid state.

`Scripts/check-telemetry-contract.sh` passes after replacing the fail-open `rg` construction scan
with a status-aware `grep` scan and adding positive/negative event-vocabulary, upload-envelope,
production-construction, clean-tree, and missing-tree fixtures. The focused run is not endpoint,
receiver, remote deletion, unlinkability beyond ordinary upload envelopes, customer-control,
Production, or release evidence.

The owning unrestricted `Scripts/validate.sh` run then passed every static contract, Release
compilation, the isolated strict 10,000-row Dashboard benchmark, 534 unit tests across 32 suites,
all 17 UI tests, and every selected coverage threshold. Four physical CloudKit probes remained
explicit skips; `CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The
validator removed
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.OzAGSt/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact. The exact
correctness subset was independently re-read from
`/private/tmp/MindBudget-C501-ReviewRemediation-Units-Filtered-20260827.xcresult` as 534 tests in
32 suites with no failure; that local path is likewise not durable release evidence. Exact-head
rereview, hosted CI, and merge remain required.

### C5-01 final default-off remediation — 2026-08-27

The focused iOS 26.5 simulator command executes `TelemetryClientTests` and passes 21/21 with no
failure or skip. The four added tests prove that repeated Disable against never-enabled encrypted
persistence creates no file or key, an injected user calendar preserves civil-day behavior across
daylight saving time, a remote upload response followed by local commit failure is typed as
`.persistenceFailed` without transport backoff, and an identical remote-delete proof set is retried
after local cleanup failure. The existing retry test now also captures and queues a second event
while backoff is active.

`Scripts/check-telemetry-contract.sh` passes with every current telemetry test anchored, including
`resetRotatesPseudonymButRetainsDeletionProof` and
`retryBackoffPreservesQueueAndDoesNotAffectCapture`. The first full-validation attempt could not
access CoreSimulator or DerivedData in the restricted environment and is excluded as an
environmental non-pass. The unrestricted `Scripts/validate.sh` rerun passes every static contract,
Release compilation, the isolated strict 10,000-row Dashboard benchmark, 538 unit tests across 32
suites, all 17 UI tests, and every selected coverage threshold. Four opt-in physical CloudKit
probes are explicit skips; `CSVExporter.swift` is the minimum selected result at 87.60% against the
85% floor. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.g8bqhg/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact. Hosted CI and
merge remain required; this evidence does not authorize an endpoint, receiver, collection,
Production, or distribution.

### C5-01 reviewed merge and documentation closeout — 2026-08-28

Independent review approved exact final PR #76 head `d937dc8`. GitHub Actions run `33085630481`
completed successfully on that head, and PR #76 merged to `main` as `68304ad`. The reviewed source
evidence remains the recorded 21/21 focused telemetry tests plus the exact-source full validation:
every static contract, Release compilation, the strict 10,000-row Dashboard benchmark, 538 unit
tests across 32 suites, all 17 UI tests, and every selected coverage threshold passed; four opt-in
physical CloudKit probes were explicit skips.

This documentation-only closeout marks C5-01 Done without adding or accepting a production client
construction, capture call, endpoint, receiver, transport, collection, customer control, App
Privacy change, or telemetry egress. C5-02 awaits separate explicit owner entry, C5-03/C5-04 remain
blocked, and COM-C5 remains In Progress. The closeout branch still requires its own independent
review, green hosted CI, and merge.

The documentation-only branch passed `Scripts/validate.sh`: every static contract, Release
compilation, the strict 10,000-row Dashboard benchmark, 538 unit tests across 32 suites, all 17 UI
tests, and every selected coverage threshold passed. Four opt-in physical CloudKit probes were
explicit skips; `CSVExporter.swift` remained the minimum selected result at 87.60% against 85%.
The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.k5zkq3/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact. Independent
review, hosted CI, and merge remain required for this closeout.

### C5-02 deletion-safe minimal ingest candidate — 2026-08-28

`Services/TelemetryWorker` passes generated binding types, `tsc --noEmit`, all 26 Vitest cases
against real local D1, Development/Staging/Production Wrangler dry-runs and startup checks, and
`npm audit --audit-level=high` with zero vulnerabilities. The cases cover strict JSON grammar,
closed schemas, exact host/path/method rejection, size/depth/node limits, idempotent retries,
changed-fact conflicts, proof authentication, all-or-none deletion, independent tombstones,
late-upload discard, bounded retention cleanup, and rate-limit non-authority.

The iOS 26.5 simulator focused telemetry suite passes 25/25 with no failure or skip. Four new tests
prove opt-out cancellation reaches the active transport, Development wire encoding is exact,
environment drift/non-empty responses fail closed, and Retry-After plus proof deletion map to the
typed client contract. Generic build-for-testing also passes. The money, network-egress,
commercialization-document, StoreKit-catalog, telemetry-client, and telemetry-Worker static gates,
plus `git diff --check`, pass on the candidate source.

Development D1 `2faff8ac-de17-4fd0-aaa7-546bd1902e74` received migration `0001_initial.sql` and
Worker version `1c162a57-8789-4f7f-9fec-f2c484e9f4f2`. The exact live probe observed upload 202,
identical retry 202, changed-fact conflict 409, authenticated complete deletion 204, and matching
late-upload discard 202. A final remote D1 read returned zero events, zero identities, and two
independent tombstones. This is Development evidence only. Staging D1
`776d171d-ec10-4a90-9235-b537e063e04b` remains unmigrated and undeployed, Production has no
provisioned D1 and no deployment, and no Staging/Production reachability, operational, privacy,
final-binary, or distribution claim is made. Hosted CI on the exact PR head remains required.

The first `Scripts/validate.sh` invocation selected `/Library/Developer/CommandLineTools` and
stopped before Xcode build; it is excluded as an environmental non-pass. The owning rerun used
Xcode 27 beta 6 explicitly and passed every static contract, Release compilation, the isolated
strict 10,000-row Dashboard benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every
selected coverage threshold. Four opt-in physical CloudKit probes were explicit skips.
`CSVExporter.swift` was the minimum selected result at 87.60% against the 85% floor. The validator
deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.1f3FOS/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact. Independent
review, hosted CI on the exact head, and merge remain required.

### C5-02 independent-review remediation — 2026-08-28

`Services/TelemetryWorker` passes generated binding types, `tsc --noEmit`, all 32 Vitest cases
against local D1, Development/Staging/Production Wrangler dry-runs and startup checks, and
`npm audit --audit-level=high` with zero vulnerabilities. New cases prove that separate deletion
requests on the same UTC day share only a coarse tombstone expiry bucket, variable user-agent or
nonempty language metadata is rejected, non-JSON Unicode whitespace is rejected, and one scheduled
operation drains more than one bounded cleanup batch. The focused iOS 26.5 simulator telemetry
suite passes 25/25 and directly asserts the fixed user agent, suppressed language, and explicit
wire contract.

The first owning `Scripts/validate.sh` attempt passed static contracts but stopped at Release link
when Xcode transiently reported `/Applications/Xcode-27-beta-6.app/Contents/Developer/Toolchains/
XcodeDefault.xctoolchain/usr/bin/clang` missing. The file was present on immediate reinspection, so
that attempt is excluded as an environmental non-pass. A clean rerun with explicit Xcode 27 beta 6
passed every static contract, Release compilation, the isolated strict 10,000-row Dashboard
benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every selected coverage threshold.
Four opt-in physical CloudKit probes remained explicit skips. `CSVExporter.swift` remained the
minimum selected result at 87.60% against the 85% floor. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.Qwp8O6/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact.

No remediated Development deployment/probe is claimed yet. The currently recorded Development
version predates DEC-COM-061; Staging remains unmigrated/undeployed and Production remains
unprovisioned/undeployed. The adapter is still unconstructed with zero capture/customer egress.
Exact-head rereview, hosted CI, and merge remain required.

### C5-02 reviewed merge and documentation closeout — 2026-08-28

Independent review approved exact remediation head `72abf4b`. GitHub Actions run `33176551566`
completed successfully on that exact head, and PR #78 merged to `main` as `4715054`. The reviewed
source evidence remains the recorded 32/32 local-D1 Worker tests, generated types/typecheck, three
environment dry-run/startup checks, zero-vulnerability high-severity audit, 25/25 focused iOS
telemetry tests, Release compilation, strict 10,000-row Dashboard benchmark, 542 unit tests across
32 suites, all 17 UI tests, and every selected coverage threshold. Four opt-in physical CloudKit
probes were explicit skips.

This closeout marks C5-02 Done without claiming a remediated Development redeploy/probe, production
client construction, capture, customer telemetry egress, App Privacy change, Staging/Production,
distribution, or release. The recorded Development version remains the earlier candidate. C5-03
awaits explicit owner entry and C5-04 remains blocked by C5-03. On Xcode 27.0 beta 6 (`27A5252f`)
with the iOS 26.5 iPhone 17 Pro simulator, the documentation closeout branch passed every static
contract, Release compilation, the isolated strict 10,000-row Dashboard benchmark, 542 unit tests
across 32 suites, all 17 UI tests, and every selected coverage threshold. Four opt-in physical
CloudKit probes were explicit skips; `CSVExporter.swift` was the minimum selected result at 87.60%
against the 85% floor. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.Bj3fdn/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact. Independent
review, green hosted CI, and merge remain required for this documentation closeout.

### C5-03 metrics/evidence implementation candidate — 2026-08-29

`Services/TelemetryWorker` passes generated binding types, `tsc --noEmit`, 35/35 Vitest cases
against local D1, six Node evidence-contract tests, Development/Staging/Production Wrangler
dry-runs and startup checks, and `npm audit --audit-level=high` with zero vulnerabilities. The D1
cases prove app-version/window isolation, ordered completed receipt funnels, later valid chains,
and malformed/reversed/over-retention rejection. The offline cases prove fixed Wilson vectors,
canonical determinism, explicit unavailable states, source binding and chronology, bounded windows,
and no-overwrite output. The money, network-egress, commercialization-document, StoreKit-catalog,
telemetry-client, telemetry-Worker, and C5 metrics/evidence gates plus `git diff --check` pass.

Full `Scripts/validate.sh` used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
simulator. It passed every static contract, Release compilation, the isolated strict 10,000-row
Dashboard benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every selected coverage
threshold. Four opt-in physical CloudKit probes were explicit skips. `CSVExporter.swift` was the
minimum selected result at 87.60% against the 85% floor. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.0CrPs7/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact.

No live Worker import/route, deployment, probe, production iOS construction/capture, customer
collection, actual survey/App Store export, real evidence bundle, metric result, G1 decision,
App Privacy change, distribution, or release is included. Independent review, hosted CI on the
exact PR head, and merge remain required.

### C5-03 exact-segment coverage remediation — 2026-08-29

After PR #80 review, the evidence builder no longer emits a root coverage roll-up across exact
segments. Eight offline evidence-contract tests now include mixed Development/Production segments,
overlapping `ALL`/`USA` storefronts, a one-of-one metric whose segment reports a 7,935-basis-point
widest Wilson interval, and a segment with no available metric whose width is `null`. The Worker
package passes 35/35 local-D1 tests, all eight evidence tests, generated bindings, TypeScript
checking, all three environment dry-runs/startup checks, and a high-severity dependency audit with
zero vulnerabilities.

Full `Scripts/validate.sh` used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
simulator. It passed every static contract, Release compilation, the isolated strict 10,000-row
Dashboard benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every selected coverage
threshold. Four opt-in physical CloudKit probes remained explicit skips; `CSVExporter.swift` was
the minimum selected result at 87.60% against the 85% floor. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.MjKE14/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact. No deployment,
real evidence collection, G1 decision, App Privacy change, distribution, or release is claimed.
Exact-head rereview, hosted CI, and merge remain required.

### C5-03 reviewed merge and documentation closeout — 2026-08-29

Independent review approved head `4ea7cd9` and raised one P2 cross-segment coverage issue plus one
P3 weak-sample-visibility issue. Remediation head `0c61427` applied both, GitHub Actions run
`33211270363` completed successfully, and PR #80 merged it to `main` as `a587f42` without a
pre-merge rereview. PR #81's post-merge closeout review read that exact remediation delta and
confirmed both fixes. The source evidence remains 35/35 local-D1 Worker tests, eight offline
evidence-contract tests, generated
bindings, TypeScript checking, all three environment dry-runs/startup checks, zero high-severity
dependency vulnerabilities, Release compilation, the strict 10,000-row Dashboard benchmark, 542
unit tests across 32 suites, all 17 UI tests, and every selected coverage threshold. Four opt-in
physical CloudKit probes were explicit skips; `CSVExporter.swift` was the minimum selected result
at 87.60% against the 85% floor.

This closeout records only the reviewed merge. It includes no deployment, probe, production app
construction/capture, customer collection, App Store/survey evidence, real bundle, G1 decision,
App Privacy change, distribution, or release. C5-04 awaits explicit owner entry. The
documentation-only closeout still requires its own independent review, green hosted CI, and merge.

The documentation closeout itself passed `Scripts/validate.sh` with Xcode 27.0 beta 6
(`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator. Release compilation, 35/35 local-D1 Worker
tests, eight C5 evidence-contract tests, 542 unit tests across 32 suites, all 17 UI tests, the
strict 10,000-row Dashboard benchmark, and every selected coverage threshold passed. Four opt-in
physical CloudKit tests were explicit skips. `CSVExporter.swift` was the minimum selected result at
87.60% against the 85% floor. The validator deleted
`mindbudget-validation.1rJYdA/MindBudget.xcresult` after success, making the name an execution
pointer rather than a durable artifact.

### PR #81 closeout review remediation — 2026-08-29

The documentation review corrected the pre/post-merge review chronology and the phase gate without
changing runtime code. Independent review covered `4ea7cd9`; `0c61427` applied its P2/P3 findings,
passed run `33211270363`, and merged as `a587f42` without pre-merge rereview; PR #81 then verified
that exact delta post-merge. The controlled files now require those facts and the C5-04 owner-entry
boundary individually. The structural phase parser self-test explicitly accepts a C5-03 Done state
beside a future C5-04 pending-review state. Static money, egress, commercialization-document,
StoreKit 13/13, C5 evidence 8/8, parser self-test, and `git diff --check` pass. Hosted CI on the new
exact closeout head remains required.

### C5-04 controlled activation candidate — 2026-08-29

The focused telemetry/lifecycle suite was run with Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5
iPhone 17 Pro simulator and passed 47/47 tests. It covered terminal 404/405/421 lifecycle, explicit retry, default-off
zero-write, cancellation/restart, proof-retaining deletion, Delete All ordering, and existing
client/adapter cases with no failure or skip. A preceding sandboxed attempt could not connect to
CoreSimulator and is excluded as an environmental non-pass.

`Services/TelemetryWorker` passed generated bindings, `tsc --noEmit`, 35/35 Vitest cases against
local D1, all eight immutable-evidence tests, Development/Staging/Production dry-runs and startup
checks, and the high-severity audit with zero vulnerabilities. The telemetry static gate and local
artifact syntax checks passed. The current source was not deployed: read-only Wrangler inspection
confirmed the authenticated Development account and existing migrations/deployments, but the
remote source-upload operation lacked explicit authorization. Consequently no current-source
Development endpoint/TTL/delete result is recorded. Full `Scripts/validate.sh`, exact-head
independent review, hosted CI, and merge remain required; Staging/Production, G1, distribution, and
release remain unauthorized.

### C5-04 final local candidate verification — 2026-08-29

The final focused `TelemetryClientTests` and `Phase6FeatureTests` selection passed all 48 declared
tests with Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator. This exact source
also passed `Scripts/validate.sh` with `MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1`: every static
contract, Release compilation, 35/35 local-D1 Worker tests, eight C5 evidence-contract tests, 550
unit tests across 32 suites, all 17 UI tests, and every selected coverage threshold passed. Four
opt-in physical CloudKit tests were explicit skips. `CSVExporter.swift` was the minimum selected
coverage result at 87.60% against the 85% floor. The validator removed
`mindbudget-validation.XKvHyp/MindBudget.xcresult` after success, so this path is an execution
pointer rather than a durable artifact.

The strict wall-clock path was also attempted separately. The isolated 10,000-row Dashboard
benchmark measured 661.598333 milliseconds against the 500-millisecond ceiling and is a recorded
non-pass on this loaded host. No strict-performance pass is claimed by the later correctness run.
One intermediate validation was interrupted after a new UI assertion exceeded XCUITest's
128-character identifier-query limit; the assertion was converted to an exact label predicate,
the affected UI test passed independently, and the complete 17-test UI suite then passed in the
final run.

No current-source Worker deployment or live endpoint/TTL/delete probe is part of this baseline.
Cloudflare Development deployment requires separate owner authorization; Staging and Production
remain untouched. Exact-head review, green hosted CI, merge, and Development operational evidence
remain open.

### C5-04 PR #82 review remediation — 2026-08-29

The local-deletion remediation passed all 16 declared focused Phase 6 tests under Xcode 27.0 beta 6
(`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator. The parameterized telemetry case exercised
`.failed`, `.terminalFailure(.endpointNotFound)`, and `.unavailable`; each result still completed
the authoritative local erase with zero model counts and reset preferences while retaining a
remote-deletion proof and publishing the distinct pending-telemetry completion state.

The previously recorded 661.598333-millisecond strict Dashboard result remains a non-pass. Its
cause is not inferred. A controlled same-machine comparison used identical Xcode, simulator,
parallel-disabled, and three-repetition commands for the remediation branch and detached
`origin/main`; both passed the 500-millisecond assertion 3/3. This closes the requested performance
evidence gap without rewriting or dismissing the earlier result.

Exact-source `Scripts/validate.sh` then ran with no wall-clock exclusion. It passed every static
contract, Release compilation, 35/35 local-D1 Worker tests, eight immutable-evidence tests, the
strict 10,000-row Dashboard benchmark, 550 unit tests across 32 suites, all 17 UI tests, and every
selected coverage threshold. Four opt-in physical CloudKit tests were explicit skips;
`CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The validator removed
`mindbudget-validation.LO2cps/MindBudget.xcresult` after success; the name is an execution pointer,
not a durable artifact. No Worker deployment, current-source live probe, G1, Staging/Production,
distribution, or release evidence is claimed. Hosted CI and exact-head rereview remain open.

### C5-04 reviewed product merge — 2026-08-29

Independent review approved the deletion-order remediation on exact head `2c1cebe` within its
declared scope. It did not inspect the privacy manifest, the AddExpense and Pro capture files,
`TelemetryService`, or the operations runbook. GitHub Actions run `33233846430` completed
successfully on that head, and PR #82 merged it to `main` as `28d9eae`. The source evidence remains
the 16-test focused Phase 6 remediation run, 35/35 local-D1 Worker tests,
eight immutable-evidence tests, strict 10,000-row Dashboard benchmark, 550 unit tests across 32
suites, 17/17 UI tests, Release compilation, and every selected coverage threshold. Four opt-in
physical CloudKit tests were explicit skips; `CSVExporter.swift` remained the minimum selected
coverage result at 87.60% against the 85% floor.

The earlier 661.598333-millisecond strict benchmark remains a recorded non-pass. Under the
controlled same-machine comparison, both the remediation branch and detached `origin/main`
passed the 500-millisecond assertion 3/3; the exact-source validator then also passed the strict
benchmark. No current-source Development deployment or endpoint/TTL/delete-idempotency probe is
part of this merge evidence, so C5-04 and COM-C5 remain In Progress. This post-merge calibration
adds no Worker/D1 mutation, App Store Connect update, G1 decision, Staging/Production action,
distribution, or release evidence.

The documentation-and-gate closeout itself passed `Scripts/validate.sh` with Xcode 27.0 beta 6
(`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator. Release compilation, 35/35 local-D1 Worker
tests, eight C5 evidence-contract tests, the strict 10,000-row Dashboard benchmark, 550 unit tests
across 32 suites, all 17 UI tests, and every selected coverage threshold passed. Four opt-in
physical CloudKit tests were explicit skips. `CSVExporter.swift` was the minimum selected result
at 87.60% against the 85% floor. The validator removed
`mindbudget-validation.bKKG10/MindBudget.xcresult` after success, making that name an execution
pointer rather than a durable artifact.

PR #83 closeout review is explicitly asked to supplement the four source/declaration surfaces that
were excluded from PR #82's review scope. Repository inspection confirms that `TelemetryService`
is defined in `MindBudget/Services/TelemetryClient.swift`; its `stop()` cancels only task handles,
so the same service still exposes explicit proof-authenticated deletion. Delete All resets setup,
therefore a pending retry becomes manually reachable only after onboarding is completed again.

### C5-04 current-source Development operational evidence — 2026-08-29

PR #83 exact head `e6bbd3f` passed GitHub Actions run `33242024609` and merged as `becb020`; its
supplemental review covered the privacy manifest, two capture files, `TelemetryService`, and the
operations runbook. On that exact main source, `npm ci` reported zero vulnerabilities and
`npm run check` passed generated bindings, TypeScript, 35/35 local-D1 Worker tests, 8/8 evidence
tests, three environment dry-runs, and three startup checks with Wrangler 4.127.0.

Read-only preflight matched the recorded Cloudflare account, Development Worker/D1, prior version,
and no-pending-migration state. The authorized Development publish created version
`003c66fa-a57c-4b6a-a8d7-3f75b14cc716` / deployment
`4e18af19-a98a-4a6d-bf4c-38e587a1b754`. The bounded synthetic probe returned
202/202/409/204/202/204 with empty bodies, proved exact `7776000000`-millisecond event TTL,
UTC-day tombstone bucketing, idempotency/conflict, proof deletion, and non-resurrection, then
removed only its exact tombstone. Synthetic final counts were 0 events/0 identities/0 tombstones;
whole-D1 counts were 0 events/0 identities/2 historical pre-remediation tombstones. No rollback
was needed.

This is Development-only synthetic operational evidence, not customer participation,
Production/final-binary traffic, a G1 result, App Store Connect evidence, distribution, or release.
The documentation/evidence candidate still requires its own independent review, hosted CI, and
merge before C5-04 or COM-C5 can be marked Done.

The exact evidence branch passed `Scripts/validate.sh` under Xcode 27.0 beta 6 (`27A5252f`) on the
iOS 26.5 (`23F77`) iPhone 17 Pro simulator. Every static contract, Release compilation, 35/35
local-D1 Worker tests, all eight C5 evidence-contract tests, the complete unit-test run, 17/17 UI
tests, and every selected coverage threshold passed. `CSVExporter.swift` was the minimum selected
coverage result at 87.60% against the 85% floor. The validator removed
`mindbudget-validation.wnudAw/MindBudget.xcresult` after success; the name is an execution pointer,
not a durable artifact. An immediately preceding invocation inherited
`/Library/Developer/CommandLineTools` and stopped before Xcode execution, so it is retained only as
an environmental non-pass and not as product evidence.

### C5-04 native transport and deletion-retry review remediation — 2026-08-29

PR #84 review corrected the PR #83 provenance: independent review covered `daea2d2`, raised two
P2 findings and one P3, and excluded four privacy-critical surfaces. Remediation head `e6bbd3f`
applied those findings and recorded the implementation author's supplemental inspection, passed
GitHub Actions run `33242024609`, and merged as `becb020` without a pre-merge rereview.

With Xcode 27.0 beta 6 (`27A5252f`) and the iOS 26.5 (`23F77`) iPhone 17 Pro simulator, the default
focused `TelemetryClientTests` run passed 34/34; the live test was an explicit skip. A first
exact-method-filter invocation under `MindBudget-Telemetry-Live` discovered zero tests and is
recorded only as a non-pass. The corrected suite-level run explicitly started
`liveDevelopmentFixedTransportUsesAcceptedURLSessionHeadersAndDeletesSyntheticIdentity` and used
the real `FixedTelemetryTransport`, `BoundedTelemetryHTTPLoader`, and `URLSession`. The strict
Development Worker accepted upload 202 (`.accepted`) and authenticated delete 204. A read-only D1
aggregate query after the run found 0 events, 0 identities, and 3 tombstones: 2 historical
pre-remediation rows plus the expected UTC-day tombstone from this live deletion. No row contents,
identifier, secret, request body, or IP were read or logged.

The default-focused run also passed
`runtimeStopDoesNotInvalidateExplicitTelemetryDeletionRetry`, proving the same service remains
able to perform proof-authenticated deletion after `stop()`, removes local encrypted persistence,
and clears retained identity state. The dedicated scheme is not enabled from the default scheme
and cannot archive. These are Debug simulator and deterministic unit-test facts, not final-binary,
customer, G1, Staging/Production, distribution, or release evidence. Exact-head hosted CI and
rereview remain required.

The remediated branch then passed `Scripts/validate.sh` under Xcode 27.0 beta 6 (`27A5252f`) on
the iOS 26.5 (`23F77`) iPhone 17 Pro simulator: every static contract and Release compilation
passed, all 35 local-D1 Worker tests and 8 C5 evidence-contract tests passed, 552 unit tests in 32
suites passed, and all 17 UI tests passed. Every selected coverage threshold passed;
`CSVExporter.swift` was the minimum at 87.60% against the 85% floor. The validator removed
`mindbudget-validation.ceXEOC/MindBudget.xcresult` after success, so that name is an execution
pointer rather than a durable artifact.

### C5-04/COM-C5 reviewed evidence merge — 2026-08-29

Independent review approved exact PR #84 head `84a96bc` after confirming both P2 findings and the
P3 regression were closed. GitHub Actions run `33247176815` started at 2026-08-29T10:10:02Z,
completed successfully at 2026-08-29T10:36:34Z, and ran the complete hosted `Build and test`
workflow on that exact head. PR #84 then merged as `4194b73` at 2026-08-29T10:37:40Z.

DEC-COM-071 uses this exact review/CI/merge chain to close C5-04 and COM-C5. The closeout does not
reinterpret the Debug simulator 202/204 observation as final-binary traffic, remove or hide the
expected third UTC-day tombstone, decide G1, update App Store Connect, deploy Staging/Production,
or authorize distribution/release. This documentation-only branch still requires its own review,
green hosted CI, and merge.

The closeout branch passed `Scripts/validate.sh` under Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 (`23F77`) iPhone 17 Pro simulator. Every static contract and Release compilation passed;
35/35 local-D1 Worker tests, 8/8 C5 evidence-contract tests, 552 unit tests in 32 suites, and
17/17 UI tests passed. Every selected coverage threshold passed, with `CSVExporter.swift` lowest
at 87.60% against the 85% floor. The validator removed
`mindbudget-validation.g93SCp/MindBudget.xcresult` after success, so that name is an execution
pointer rather than a durable artifact.

### PR #85 source-privacy handoff remediation — 2026-08-29

PR #85 review found that C5 Done would otherwise leave no future independent-review owner for the
checked-in privacy manifest and its capture/service/runbook basis. The remediation pins those
five exact surfaces to COM-C6 before any App Store Connect privacy answer and prevents the C5
implementation-author supplemental inspection from satisfying that independent gate. It does not
reopen C5, enter COM-C6, or modify runtime, manifest, capture, service, Worker, deployment, D1,
App Store Connect, distribution, release, or customer data.

The remediated closeout branch passed `Scripts/validate.sh` under Xcode 27.0 beta 6 (`27A5252f`)
on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator. Every static contract and Release compilation
passed; 35/35 local-D1 Worker tests, 8/8 C5 evidence-contract tests, 552 unit tests in 32 suites,
17/17 UI tests, and every selected coverage threshold passed. `CSVExporter.swift` was lowest at
87.60% against the 85% floor. The validator removed
`mindbudget-validation.lolUt1/MindBudget.xcresult` after success; it is an execution pointer, not a
durable artifact. The new exact head still requires rereview, hosted CI, and merge.

### C6-01 automated release matrix — 2026-08-29

The owner explicitly entered COM-C6 after PR #85 merged as `008b674`. The new C6-01 matrix ran on
Xcode 27.0 beta 6 (`27A5252f`) with the iOS 26.5 (`23F77`) iPhone 17 Pro simulator. Every reviewed
static gate passed. Public Configuration Worker tests passed 13/13; Telemetry Worker tests passed
35/35 plus 8/8 evidence-contract tests; typechecks, local deployment dry-runs, and telemetry startup
checks passed. Release simulator build and test build passed. The selected 16 Swift test suites
then passed 285 tests; the explicit live Development telemetry probe was skipped by default as
required.

The retained local result bundle is `/private/tmp/MindBudget-C6-01.xcresult`. It is an execution
artifact, not hosted CI, signed-device, final-binary, App Store Connect, deployment, G1, or release
evidence. C6-01 still requires independent review, green hosted CI, and merge; C6-02/C6-03 remain
blocked.

The final branch also passed `Scripts/validate.sh` on that exact local toolchain and simulator:
every static contract, Release compilation, the strict 10,000-row Dashboard benchmark, 553 unit
tests in 32 suites, 17/17 UI tests, and every selected coverage threshold passed.
`CSVExporter.swift` was lowest at 87.60% against the 85% floor. The validator deleted its
temporary xcresult after success, so that path is an execution pointer rather than a durable
artifact. This does not replace independent review, hosted CI, or any C6-02/C6-03 evidence.

### C6-01 review-remediation preflight — 2026-08-29

PR #86 review found that named methods were not tied to runtime results and that future check
scripts could drift outside the manual allow-list. The remediated validator's negative self-tests
reject skipped, missing, and duplicate required cases plus an unclassified future check script.
Read-only parsing of the retained earlier `/private/tmp/MindBudget-C6-01.xcresult` found all 33
matrix bindings exactly once with result Passed, including the parameterized Phase 6 local Delete
All test. This is a parser/remediation preflight against an earlier bundle, not exact-head evidence.
The subsequent remediated matrix passed every static and Worker check, Release/test builds, 285
tests in 16 suites, and the new post-run verifier for all 33 bindings. Its retained bundle is
`/private/tmp/MindBudget-C6-01-Remediation.xcresult`; this path is local execution evidence rather
than hosted, signed-device, final-binary, or release evidence. The subsequent full validation
passed the strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32 suites, and 17/17 UI
tests. The result summary contained 558 passes, 12 explicit opt-in skips, and zero failures; every
selected coverage threshold passed, with `CSVExporter.swift` lowest at 87.60% against the 85%
floor. Its retained full bundle is `/private/tmp/MindBudget-C6-01-Remediation-Full.xcresult`.
Rereview, hosted CI, and merge remain required; no C6-02/C6-03 or remote action is implied.

### C6-01 reviewed merge and documentation closeout — 2026-08-29

Independent rereview approved exact PR #86 remediation head `f77d2a6`. GitHub Actions run
`33255898196` started at 2026-08-29T13:47:11Z and completed successfully at
2026-08-29T14:18:21Z on that exact head. PR #86 then merged as `015d00e` at
2026-08-29T14:55:16Z.

DEC-COM-074 uses this exact review/CI/merge chain to close only C6-01. The matrix and full local
validation evidence remain implementation evidence; they do not satisfy C6-02's five-source
independent privacy inspection, signed-device/App Review checks, final-binary/IPA traffic evidence,
or any App Store Connect, Staging/Production, G1, archive/upload, distribution, or release gate.
C6-02 awaits a separate explicit owner entry and C6-03 remains blocked. This documentation-only
closeout still requires its own independent review, green hosted CI, and merge.

The first sandboxed closeout validation attempt could not access CoreSimulator and stopped before
building; it is an environmental non-pass and is not evidence. The subsequent unrestricted
`Scripts/validate.sh` run passed under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`)
iPhone 17 Pro simulator. Every static contract, Release compilation, and the strict serial
10,000-row Dashboard benchmark passed; 553 unit tests in 32 suites and 17/17 UI tests passed, while
four explicitly opt-in physical CloudKit probes remained skipped. Every selected coverage threshold
passed, with `CSVExporter.swift` lowest at 87.60% against the 85% floor. The retained result bundle
is `/private/tmp/MindBudget-C6-01-Closeout.xcresult`; it is a local execution artifact rather than
hosted, signed-device, final-binary, App Store Connect, G1, or release evidence.

### C6-01 closeout authorization-gate remediation — 2026-08-29

Author-side supplemental inspection of initial closeout head `4545e88` reproduced a summary-prose
bypass for C6-01 and a next-line Status bypass for C6-02/C6-03. DEC-COM-075 replaces those controls
with section-bound expectations in the structural phase checker. The self-test accepts the exact
C6-01 Done/[x], C6-02 Blocked/[B], C6-03 Blocked/[B] map and rejects all three state changes plus
all three task-marker changes. The standalone checker, repository gates, Shell syntax, and diff
checks passed. A default-cache `py_compile` attempt was denied by the sandbox while creating the
system user cache path; the rerun with `PYTHONPYCACHEPREFIX` confined to `/private/tmp` passed and
is the owning syntax result.

The exact remediated branch passed `Scripts/validate.sh` under Xcode 27.0 beta 6 (`27A5252f`) on
the iOS 26.5 (`23F77`) iPhone 17 Pro simulator. Every static contract, Release compilation, and the
strict serial 10,000-row Dashboard benchmark passed; 553 unit tests in 32 suites and all 17 UI tests
passed, while four accepted opt-in physical CloudKit probes remained skipped. Every selected
coverage threshold passed, with `CSVExporter.swift` lowest at 87.60% against the 85% floor. The
retained result is `/private/tmp/MindBudget-C6-01-Closeout-Remediation-Final.xcresult`; it is a
local execution artifact rather than hosted, signed-device, final-binary, App Store Connect, G1,
or release evidence. Exact-head rereview, hosted CI, and merge remain required.

### C6-02 source/privacy and development-signed Release preflight — 2026-08-30

The owner explicitly entered C6-02. The mandatory five-surface implementation pass found and
corrected the missing Purchase History declaration for the closed subscription outcome. The new
privacy validator and all seven negative mutations passed against source; the same validator then
passed against the manifest embedded in a Release-configuration app.

Xcode 27.0 beta 6 (`27A5252f`) built Release 0.9.8 (9) for `拉沙的iPhone`, an iPhone Air
(`iPhone18,4`) running iOS 26.6.1 (`23G83`). The app signature/designated requirement, exact bundle/
team/application IDs, minimum OS, iPhone family, background mode, private CloudKit entitlement,
embedded manifest, six reviewed host literals, and no-fixture/no-test shape passed
`inspect-c6-release-app.sh --mode signed-device`. Installation and launch succeeded. Development
APS plus `get-task-allow=true` is expected from direct provisioning and is not distribution,
Archive/IPA, final-traffic, or TestFlight evidence.

All standalone static, syntax, plist, and diff checks passed. The full `Scripts/validate.sh` run
passed under the same Xcode with the iOS 26.5 (`23F77`) iPhone 17 Pro simulator: Release
compilation, the strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32 suites, and all
17 UI tests passed. Four accepted opt-in physical CloudKit probes remained skipped. Every selected
coverage threshold passed; `CSVExporter.swift` was lowest at 87.60% against the 85% floor. The
validator removed its temporary xcresult, so its path is an execution pointer rather than a
durable artifact. Independent review, hosted CI, and the manual C6-02 checklist remain open;
C6-03 and all remote/release actions remain blocked or unauthorized.

### C6-02 required-reason source-inventory remediation — 2026-08-30

PR #88 independent review accepted exact head `0ac0500`; GitHub Actions run `33283398690` passed,
and PR #88 merged as `6c2a051`. The review left one non-blocking P2 before C6-02 Done: the manifest
validator pinned UserDefaults `CA92.1` but did not derive the category set from production App
source. DEC-COM-077 adds a source/manifest equality gate for Apple's five current required-reason
categories and records its source-only evidence boundary.

The new scanner self-test and ordinary repository scan passed. All standalone money,
network-egress, commercialization-document, StoreKit 13/13, telemetry/privacy, C6 matrix, Shell,
Python, plist, and diff checks passed. The full C6 matrix passed 285 selected tests in 16 suites and
verified all 33 required bindings exactly once as Passed.

The first sandboxed full-validation rerun could not access CoreSimulator and is an environmental
non-pass. The unrestricted `Scripts/validate.sh` run passed under Xcode 27.0 beta 6 (`27A5252f`)
on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator. Release compilation, the strict serial
10,000-row Dashboard benchmark, 553 unit tests in 32 suites, and all 17 UI tests passed. Four
accepted opt-in physical CloudKit probes remained skipped. Every selected coverage threshold
passed; `CSVExporter.swift` was lowest at 87.60% against the 85% floor. The temporary xcresult was
removed by the validator and is not a durable artifact. Exact-head independent review, hosted CI,
and the remaining C6-02 manual evidence are still required; this result does not authorize C6-03,
Archive/IPA, upload, App Store Connect, G1, distribution, or release.

### C6-02 required-reason Swift overlay remediation — 2026-08-30

PR #89 independent review accepted the lexical scanner and matrix wiring but reproduced missing
Foundation overlay spellings. The remediation added exact file-timestamp and disk-space overlay
mappings, one negative source/manifest test per spelling, and a multi-category mutation proving
that UserDefaults reason `CA92.1` cannot be bypassed by adding another declared category. Dynamic
raw-value keys are explicitly outside lexical proof and remain assigned to C6-03 distribution
privacy-report and compiled-artifact inspection.

`Scripts/run-c6-release-matrix.sh` passed under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5
(`23F77`) iPhone 17 Pro simulator. Every static and Worker contract, Release/test build, 285 tests
in 16 suites, and all 33 required method bindings passed. Its result-bundle path was temporary
local execution evidence only.

The independent full `Scripts/validate.sh` run passed under the same toolchain and destination:
Release compilation, the strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32 suites,
and all 17 UI tests passed. Four accepted opt-in physical CloudKit probes remained skipped. Every
selected coverage threshold passed, with `CSVExporter.swift` lowest at 87.60% against the 85%
floor. The validator removed its temporary xcresult. Exact-head rereview, hosted CI, and the open
manual C6-02 checklist remain required; no C6-03 or remote/release authorization follows.

### C6-02 required-reason reviewed merge and continuation — 2026-08-30

Independent rereview accepted exact PR #89 remediation head `6ffc6fa`. GitHub Actions run
`33287620965` completed successfully on that exact head in 22m59s, and PR #89 merged it as
`72f016e`. The merged source gate now closes the reviewed Swift-overlay and multi-category
`CA92.1` gaps; literal raw-value keys and compiled dependencies remain assigned to C6-03's
distribution privacy report and artifact inspection.

On the continuation branch, the required-reason self-test and App scan, commercialization
document gate, and telemetry/privacy gate passed. The retained development-signed Release 0.9.8
(9) app at `/private/tmp/MindBudget-C6-02-Release-20260830/Build/Products/Release-iphoneos/`
`MindBudget.app` passed `inspect-c6-release-app.sh --mode signed-device` when run with access to the
signing trust state. The path is an execution pointer rather than a durable artifact. A first
sandboxed attempt returned `CSSMERR_TP_NOT_TRUSTED` and is excluded as an environmental non-pass.
CoreDevice listed `拉沙的iPhone` as paired but unavailable, so no new physical manual-checklist
evidence is claimed. C6-02 remains In Progress and C6-03 remains blocked.

### C6-02 physical evidence and focused AX5 navigation regression — 2026-08-30

The installed development-signed Release 0.9.8 (9) supplied partial physical evidence for live
bilingual StoreKit/renewal/legal presentation, offline verified-local-Pro retention, privacy/
analytics/receipt/iCloud/export copy, and receipt cancellation without a ledger write. Paths under
`/private/tmp/MindBudget-C6-02-physical-20260830/` are local execution pointers, not durable,
distribution, final-binary, App Store Connect, G1, or release artifacts.

The physical AX5 run found a persistent-tab-bar content obstruction and is retained as a non-pass.
After DEC-COM-078 remediation, the focused
`MindBudgetPhase3UITests/testAccessibilityExtraLargeKeepsPrimaryActionsAndNavigationReachable`
run under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator passed
1 test with 0 failures at `/private/tmp/C6-02-AX5-TabBar-retry.xcresult`. A first sandboxed attempt
could not access CoreSimulator and is excluded as an environmental non-pass. This focused result
does not replace physical reinstall or the rest of the C6-02 manual checklist. Exact-head full
validation, independent review, hosted CI, and merge remain required.

### C6-02 complete validation after AX5 navigation remediation — 2026-08-30

The first complete `Scripts/validate.sh` run after the DEC-COM-078 production change passed
Release, the strict serial 10,000-row Dashboard benchmark, and all 553 unit tests, but retained
three UI non-passes. A focused rerun passed the language-switch and onboarding/manual-flow cases
and reproduced only the Pro AX5 test's immediate Warm Botanical selected-state assertion. That
assertion now waits at most two seconds for SwiftUI selection state to settle. The focused rerun
then passed one test with zero failures at
`/private/tmp/C6-02-Pro-AX5-Selection-Retry.xcresult`.

The final owning `Scripts/validate.sh` run passed under Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 (`23F77`) iPhone 17 Pro simulator: Release compilation, the strict Dashboard benchmark, 553
tests in 32 unit suites, and all 17 UI tests passed. Four accepted opt-in physical CloudKit probes
remained skipped. Every selected coverage threshold passed; `CSVExporter.swift` was lowest at
87.60% against the 85% floor. The validator removed its temporary xcresult; all paths in this
section are local execution pointers rather than durable, hosted, signed-device, distribution, or
release artifacts. The pre-remediation physical AX5 observation remains a non-pass, and physical
reinstall plus the remaining manual C6-02 evidence are still open.

The exact-source C6 matrix rerun passed every static and Worker check, Release/test build, 285 tests
in 16 suites, and all 33 required method bindings exactly once as Passed. A first sandboxed attempt
could not write Wrangler logs or bind its local test server and is an environmental non-pass; the
unrestricted rerun is the owning result. The matrix removed its temporary xcresult, so that path
was also an execution pointer rather than a durable artifact.

### C6-02 PR #90 review remediation with canonical AX5 values — 2026-08-30

PR #90 review found that the navigation test protected only the capped chrome and did not prove
that selected-page content remained uncapped. It also rejected the unexplained `transient` label
for two interaction failures. Author-side investigation found a deeper evidence error: the prior
launch string `UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge` is not a UIKit content-
size raw value and was ignored. Those earlier simulator bundles remain ordinary UI execution
pointers but are not AX5 evidence. The physical AX5 obstruction remains a valid non-pass.

The remediation uses UIKit's canonical `UICTContentSizeCategoryAccessibilityM` and
`UICTContentSizeCategoryAccessibilityXXXL` values. The Dashboard date supplies a nonvisual
content-side anchor; the AX5 run must render it taller than AX1 while all four persistent tabs
remain present, hittable, and within the reviewed 96-point chrome bound. Language labels,
Dashboard-tab selection, expense-category selection, and appearance selection now use bounded
predicate waits. True AX5 setup and Pro navigation scroll their own content rather than assuming
ordinary-size geometry.

The focused content comparison passed 1/1 at
`/private/tmp/C6-02-ReviewFix-TrueAX5-setup-rerun.xcresult`, and the corrected three-appearance Pro
AX5 regression passed 1/1 at `/private/tmp/C6-02-ReviewFix-TrueAX5-Pro.xcresult`. The new owning
`Scripts/validate.sh` run under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17
Pro simulator passed Release, the strict Dashboard benchmark, 553 tests in 32 unit suites, all 17
UI tests with the canonical content-size values, and every selected coverage threshold. Four
accepted opt-in physical CloudKit probes remained skipped; `CSVExporter.swift` was lowest at
87.60% against the 85% floor. These are local execution pointers, not durable or physical evidence.
The remediated app still requires physical reinstall; C6-02 remains In Progress and C6-03 remains
blocked. The exact-source C6 matrix also passed every static and Worker check, Release/test build,
285 tests in 16 suites, and all 33 required method bindings exactly once as Passed.

### C6-02 hosted AX5 Pro navigation non-pass and geometric remediation — 2026-08-30

Hosted Actions run `33312286576` on head `6908f6c` passed the static and unit portions but failed
the three-appearance Pro AX5 UI test. The failure is retained as a real test non-pass. The result
bundle showed that after returning from Appearance, `settings.pro` could remain partially behind
the Settings navigation bar while XCUITest reported it hittable. Two synthesized taps left the
Settings page visible, after which the old test emitted cascading missing-control assertions.

An initial bounded tap-to-destination handshake did not close the mechanism: a two-iteration
diagnostic passed 1/2 at
`/private/tmp/C6-02-ReviewFix-TrueAX5-Pro-NavigationHandshake-TwoIterations.xcresult`. The corrected
regression first requires the Pro row midpoint to be below the live navigation-bar frame. It then
asserts the geometry, waits boundedly for the destination, and terminates the test path if
navigation fails. That version passed 2/2 at
`/private/tmp/C6-02-ReviewFix-TrueAX5-Pro-SafeHitPoint-TwoIterations.xcresult`.

A fresh complete `Scripts/validate.sh` run under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5
(`23F77`) iPhone 17 Pro simulator passed Release, the strict Dashboard benchmark, 553 unit tests in
32 suites, all 17 UI tests, and every selected coverage threshold. Four accepted opt-in physical
CloudKit probes remained skipped and `CSVExporter.swift` was lowest at 87.60%. These paths are
temporary local execution pointers, not hosted, physical, distribution, or release artifacts.
The exact-source C6 matrix then passed every static and Worker check, Release/test build, 285 tests
in 16 suites, and all 33 required method bindings exactly once as Passed. C6-02 remains In
Progress; C6-03 and all remote/release actions remain blocked.

### C6-02 bounded physical AX5 reinstall and first-push navigation remediation — 2026-08-31

Only `拉沙的iPhone` (iPhone Air/iPhone18,4, iOS 26.6.1 `23G83`) was used. The owner explicitly
excluded `Xiao li的 iPhone (2)`. This is development-signed physical preflight evidence, not
distribution, Archive/IPA, final-binary, TestFlight, or release evidence.

The canonical true-AX5 content run passed. The bilingual physical run passed 1/1 at
`/private/tmp/MindBudget-C6-02-Physical-AX5-Bilingual-Light-Dark-Lasha-Geometry.xcresult`; manual
inspection covered English light/dark and Simplified Chinese light/dark Pro screens. An exact
physical Pro/legal regression later passed at the hierarchy level but retained screenshots exposed
an invisible first-push back indicator across appearance transitions. That green bundle is a
visual non-pass.

DEC-COM-081 binds `.toolbarColorScheme` to the Pro presentation boundary and removes competing
child scheme declarations. The owning physical three-skin run passed 1/1 at
`/private/tmp/MindBudget-C6-02-Physical-AX5-ToolbarScheme-Retry-Lasha.xcresult`. All nine retained
Pro/Terms/Privacy captures were inspected and showed the system back indicator. A prior locked-
device/developer-certificate attempt and the pre-fix visual bundles remain non-passes. The owner
stopped a later duplicate combined run after the first content case passed; the interrupted bundle
is not counted as a pass. These `/private/tmp` paths are local execution pointers, not durable
artifacts. C6-02 remains In Progress for the other manual rows, and C6-03 plus every remote/release
action remains blocked.

### C6-02 DEC-COM-081 final local validation — 2026-08-31

The first retained complete run at
`/private/tmp/MindBudget-C6-02-DEC-COM-081-Full-Final.xcresult` was a non-pass: the AX5/AX1 UI test
reported one primary failure while subsequent assertions cascaded. Result-bundle inspection proved
that the full-screen setup helper alternated `budget.totalBudget` from below the keyboard to behind
the navigation bar for all eight attempts. This was not a product or money-calculation failure.

The helper now derives its lower interaction boundary from the live keyboard and uses small drags
inside the budget form. The exact focused regression passed two consecutive iterations at
`/private/tmp/MindBudget-C6-02-AX5-Budget-Scroll-Remediation.xcresult`. A fresh complete
`Scripts/validate.sh` run then passed at
`/private/tmp/MindBudget-C6-02-DEC-COM-081-Full-Validated.xcresult`: the result summary records 571
total executions, 558 passed, 13 intentionally skipped, and zero failed; the UI target specifically
ran 18 tests with 17 passed, one physical-only test skipped, and zero failures. Release build,
strict wall-clock run, all unit/UI suites, and every selected service coverage threshold passed.

The exact-source C6 matrix was also repeated after the final helper change at
`/private/tmp/MindBudget-C6-02-DEC-COM-081-C6-Matrix-Final.xcresult`; all static/Worker checks,
Release/test build, 285 tests in 16 suites, and all 33 required bindings passed. These temporary
paths are execution pointers, not durable artifacts. No additional physical run was performed after
the owner stopped redundant testing, and no C6-02, C6-03, distribution, or release completion is
claimed.

### C6-02 PR #91 reviewed merge calibration — 2026-08-31

Independent review accepted exact head `b3ed24d` with no P1/P2 findings. Its P3 observations did
not broaden the evidence: the automation verifies navigation geometry rather than visual contrast;
the nine reviewed screenshots remain the contrast evidence; legal destinations inherit the single
Pro color-scheme boundary; and the XCUITest helpers retain their reviewed structural assumptions.

GitHub Actions run `33362101536` completed successfully on exact head `b3ed24d`. The `Build and
test` job passed in 27m16s after every static, Worker, StoreKit, deployment-target, Release, unit,
UI, coverage, and report step completed. PR #91 then merged that head to `main` as `4ddabcd`; the
merge commit's second parent is `b3ed24d`.

This closes only PR #91's bounded DEC-COM-081 implementation and local-regression evidence. No
additional physical run occurred, and the prior owner-stopped duplicate remains a non-pass.
Transaction-error, receipt-acquisition, complete signed-phone VoiceOver/accessibility,
Instruments/data-protection, and system-integration evidence remain open. C6-02 is not Done, and
C6-03 plus every Archive/IPA, upload, deployment, App Store Connect, G1, distribution, and release
action remain blocked or unauthorized.

### C6-02 bounded acceptance preflight — 2026-08-31

`check_c6_02_acceptance.py --self-test` passed. Read-only `xcresulttool` verification of
`/private/tmp/MindBudget-C6-02-DEC-COM-081-Full-Validated.xcresult` then confirmed all 23 exact
StoreKit, receipt, accessibility-regression, and system-integration bindings executed once as
Passed. That retained bundle remains a local execution pointer rather than hosted, signed-device,
distribution, or release evidence.

Read-only `devicectl` inspection used only `拉沙的iPhone` and found the expected SwiftData store,
WAL/SHM, migration marker, signed configuration, and containermanagerd data-protection policy
attributes. No financial store was copied off device: a proposed export was rejected by the safety
boundary and was not retried or bypassed. `xctrace` classified the same phone as Offline while
`devicectl` saw it connected; the attempted Activity Monitor recording produced no trace and is a
non-pass. No exact protection class or Instruments metric is inferred from that attempt.

DEC-COM-083 accepts only the matrix's bounded dispositions. Full signed-phone VoiceOver,
Instruments, exact data-protection class, and physical notification/Siri/Spotlight/Face ID/share/
Delete All effects were not run and are not Passed. Fresh repository validation, exact-head
independent review, hosted CI, and merge remain required. C6-02 stays In Progress; C6-03 and every
Archive/IPA, upload, deployment, App Store Connect, tester assignment, G1, distribution, and
release action remain blocked.

The fresh exact-source validation then completed on Xcode 27.0 beta 6 (`27A5252f`) with the iOS
26.5 (`23F77`) iPhone 17 Pro simulator. Release compilation, the strict serial 10,000-row
Dashboard benchmark, 553 unit tests in 32 suites, 18 UI tests with 17 passed and the one
physical-only case skipped, every selected coverage threshold, and all static/Worker contracts
passed. The new verifier confirmed all 23 C6-02 bindings executed exactly once as Passed. Its
temporary `mindbudget-validation.*` result path was deleted by the validator and is an execution
pointer rather than a durable artifact.

The exact-source C6 release matrix then passed at
`/private/tmp/MindBudget-C6-02-DEC-COM-083-C6-Matrix.xcresult`: all static and Worker checks,
Release/test builds, 285 tests in 16 suites, and all 33 C6-01 runtime bindings passed. That local
path is also an execution pointer, not hosted or distribution evidence. These green deterministic
runs do not change any DEC-COM-083 non-pass disposition; exact-head review, hosted CI, and merge
remain required before C6-02 can close.

### C6-02 PR #93 hosted-schema non-pass and remediation — 2026-08-31

GitHub Actions run `33370429991` executed exact PR #93 head `9f69f1a` on hosted Xcode 26.6. Every
static/Worker preflight passed; Release, 553 unit tests, 18 UI tests with one physical-only skip,
and coverage also passed. The job nevertheless ended red when the final C6-02 verifier requested
`xcresulttool` schema `0.4.0`; Xcode 26.6 returned `Unknown schema version provided`. That run is a
non-pass and is not hosted evidence that the 23 bindings passed.

The uploaded artifact `MindBudget-xcresult-33370429991-1` was downloaded read-only. DEC-COM-084
changes the C6-02 reader to explicit schema `0.3.0`, which is supported by both Xcode 26.6 and
Xcode 27. The remediated verifier read the downloaded hosted artifact and the local Xcode 27 full
bundle and found all 23 exact bindings once as Passed in each. Its self-test now also rejects a
failed-then-passed retry, making `-retry-tests-on-failure` a deliberate evidence non-pass rather
than a hidden success. This is local remediation proof only; a new exact-head hosted run must turn
green before merge or C6-02 Done.

### C6-02 PR #93 second hosted-schema non-pass and native remediation — 2026-08-31

GitHub Actions run `33384223530` executed exact head `bf83faf` on hosted Xcode 26.6. All preflight
checks passed; Release, unit, UI, and coverage execution completed. The run is nevertheless a
non-pass because the final verifier failed with `Unknown schema version provided: 0.3.0`. It also
retained one pseudo-long-text UI first-attempt failure followed by a retry pass. The failure frame
showed the expected `500` rendered in the active saving-goal field, identifying an accessibility-
snapshot lag rather than missing input.

DEC-COM-085 removes forced schema selection and reads the active toolchain-native JSON. The
validator now collects real Failed/Passed `Repetition` children so a required binding cannot hide
an earlier failure behind aggregate Passed. The pseudo-long-text helper waits for the bounded
Dashboard transition after Save, which is the end-to-end persistence authority. A two-iteration
focused run passed with zero failures/skips at
`/private/tmp/MindBudget-C6-02-Native-Schema-Focus2.xcresult`. That path is a local execution
pointer. Runs `33370429991` and `33384223530` remain non-passes; a new exact head still requires
independent rereview, green hosted CI, and merge.

A subsequent complete local `Scripts/validate.sh` run under Xcode 27.0 beta 6 on the iOS 26.5
iPhone 17 Pro simulator passed Release, the strict Dashboard benchmark, 553 unit tests, all 18 UI
tests with 17 passed and the single physical-only case skipped, every selected coverage gate, and
all 23 C6-02 runtime bindings. No test retried. The temporary
`mindbudget-validation.JZRFiN/MindBudget.xcresult` path was removed by the validator and is an
execution pointer rather than a durable artifact. This local result does not replace the required
new Xcode 26.6 hosted run.

### C6-02 PR #93 third hosted non-pass and Save interaction remediation — 2026-08-31

Independent rereview accepted exact head `44c53a5` contingent on green hosted CI. GitHub Actions
run `33391122019` executed that head on hosted Xcode 26.6. All static/Worker preflight checks and
Release/unit/coverage work completed. The native `xcresulttool` read also succeeded, closing the
schema-portability question. The run nevertheless remains a non-pass: the AX1 half of
`testAccessibilityExtraLargeKeepsPrimaryActionsAndNavigationReachable` failed before its runner
retry passed, and the 23-binding gate rejected observed aggregate Passed plus concrete
Failed/Passed `Repetition` nodes.

The failure hierarchy retained valid `3000`, `2500`, and `500` fields plus the matching flexible
preview while Save and the decimal keyboard remained onscreen. DEC-COM-086 therefore uses the
existing bounded Save-to-Dashboard interaction handshake instead of retrying the workflow or
weakening evidence. It also treats direct Repetition children as the concrete attempts without
double-counting their aggregate parent; exactly one concrete Passed is valid, while Failed→Passed
remains rejected. The focused regression passed 2/2 without test-runner retry at
`/private/tmp/MindBudget-C6-02-Save-Handshake-Focus2.xcresult` under Xcode 27.0 beta 6 on the iOS
26.5 iPhone 17 Pro simulator. A subsequent complete `Scripts/validate.sh` run on the same local
toolchain passed Release, the strict Dashboard benchmark, 553 unit tests, all 18 UI tests with 17
passed and one expected physical-only skip, every selected coverage threshold, and all 23 C6-02
runtime bindings. No UI test retried, including the remediated AX1/AX5 case. The validator removed
its temporary `mindbudget-validation.U87fhN/MindBudget.xcresult`; both paths are local execution
pointers rather than durable artifacts. A new exact head still needs independent rereview, green
hosted CI, and merge.

### C6-02 PR #93 fourth hosted non-pass and visible-geometry remediation — 2026-08-31

Independent rereview accepted exact head `c05860f` contingent on green hosted CI. GitHub Actions
run `33398172181` executed that head on hosted Xcode 26.6. Static/Worker preflight passed and the
workflow reached UI execution without a schema-version failure, but it did not produce green
23-binding evidence because the required AX1/AX5 test remained a non-pass. The first iteration
timed out on two back-button navigation-container-frame predicates;
the screenshots were retained and both back buttons were subsequently tapped successfully. A later
runner repetition retained valid budget fields and a focused decimal keyboard covering Save even
though XCTest reported the control hittable, and neither bounded activation reached Dashboard.

DEC-COM-087 replaces the delayed container-frame dependency with a nonempty back-button midpoint
inside the App window. The budget helper now performs bounded Form drags until Save's complete frame
is below the navigation bar and above the keyboard before using the unchanged at-most-two
Save-to-Dashboard handshake. The first local focused attempt is a non-pass because the initial
helper queried Save's frame before it existed. After adding that existence boundary, the focused
test passed 2/2 with zero failures/skips and no test-runner retry at
`/private/tmp/MindBudget-C6-02-Hosted-UI-Focus5.xcresult` under Xcode 27.0 beta 6 on the iOS 26.5
iPhone 17 Pro simulator. The path is a local execution pointer. Run `33398172181` and the prior
three hosted runs remain non-passes. The first complete-validator launch was an environmental
non-pass before build/test execution because the restricted environment could not connect to
CoreSimulator or read the local signing prefix. The identical unrestricted command then passed
Release, the strict Dashboard benchmark, all unit tests, all 18 UI tests with 17 passed and one
expected physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime bindings.
The UI summary contains exactly 18 executions, so no test-runner retry occurred. The validator
deleted its temporary xcresult, which is an execution pointer rather than a durable artifact. A
new exact-head hosted run must turn green before merge or C6-02 Done.

### C6-02 exact-head hosted pass and reviewed merge — 2026-09-01

Independent final review approved exact PR #93 head `016dd33` with no P1/P2 findings. GitHub
Actions run `33405016652` completed successfully on that exact head, and PR #93 merged it as
`c940e8e`. The accepted head preserves toolchain-native xcresult parsing, rejects Failed→Passed
`Repetition` history, passes the complete suite and all 23 C6-02 runtime bindings, and contains no
product Swift change beyond the already reviewed PR #93 scope.

Runs `33370429991`, `33384223530`, `33391122019`, and `33398172181` remain non-passes and are not
superseded into green evidence. Final review retained two non-blocking harness notes for C6-03/C12:
the back-button helper selects `buttons.element(boundBy: 0)` and proves App-window rather than
navigation-container geometry, and the budget Save helper performs only bounded upward Form drags.
DEC-COM-088 marks C6-02 Done while C6-03, Archive/IPA, upload, App Store Connect mutation, G1,
distribution, and release remain blocked or unauthorized.

The documentation closeout was then verified locally with Xcode 27.0 beta 6 (`27A5252f`). An
initial invocation without `DEVELOPER_DIR` selected CommandLineTools and did not enter the build;
a second sandboxed invocation reached Xcode but could not access CoreSimulator. Both are
environmental non-passes, not product evidence. The identical unrestricted validator completed
successfully: Release build and strict Dashboard benchmark passed, 553 unit tests passed across 32
suites with the four expected opt-in CloudKit physical probes skipped, all 18 UI tests executed
with 17 passed and one expected physical-only skip, every selected coverage threshold passed, and
the C6-02 evidence reader confirmed 23 exact runtime bindings. The UI summary contains exactly 18
executions, so no test-runner retry occurred. The validator deleted its temporary xcresult; its
printed path was an execution pointer rather than a durable artifact.

### C6-03 build-10 preparation baseline — 2026-09-01

The owner entered C6-03 under DEC-COM-089 and authorized one reviewed/green/merged `0.9.9 (10)`
Archive plus TestFlight transport upload. This preparation branch performed no Archive, IPA,
upload, deployment, App Store Connect mutation, tester assignment, G1, distribution, or release.

The owner corrected the candidate marketing version from the initially prepared `0.9.8` to
`0.9.9`, retaining build 10. The earlier successful validator and C6 matrix predate the correction
and are not exact `0.9.9 (10)` evidence. The first complete corrected-version validator is retained
as a non-pass: the build and unit layers succeeded, but the localization release-note test and the
Settings UI test still asserted `0.9.8`. Remediation preserved `0.9.8` as historical release notes,
added a new localized `0.9.9` entry, and updated current/history/future localization checks plus the
UI version assertion.

Fresh exact-candidate validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
simulator. All static and Worker gates passed. `Scripts/validate.sh` passed Release, the strict
Dashboard benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit physical
skips, all 18 UI tests with 17 passed and one expected physical-only skip, every selected coverage
threshold, and 23 exact C6-02 runtime bindings; no UI test-runner retry occurred. The validator
deleted its temporary result bundle, so its printed path is an execution pointer rather than a
durable artifact.

The fresh C6 release matrix passed 285 tests across 16 suites and all 33 required runtime bindings.
Its result bundle is `/private/tmp/MindBudget-C6-03-0.9.9-Build10-Matrix-20260901.xcresult`; this is
a local execution pointer, not hosted, signed Archive, IPA, final-binary, App Store Connect, G1,
distribution, or release evidence. Independent review, green hosted CI, and merge remain required
before Archive.

### C6-03 reviewed merge, Distribution inspection, and upload — 2026-09-01

- Independent review approved exact PR #95 head `11ab612`; GitHub Actions run `33488815168`
  completed successfully; PR #95 merged it as `d5d0959`.
- Release Archive from exact merged `main` completed with Xcode 27.0 beta 6 (`27A5252f`). The
  archive's development signature is not accepted as Distribution evidence.
- First App Store Connect export: **non-pass** before package acceptance because the current Xcode
  account/distribution certificate/entitlement-compatible Store profile were unavailable.
- Later cloud-managed Apple Distribution export: **pass**. The distribution inspector passed
  `0.9.9 (10)`, bundle/team, Production APS/CloudKit, `get-task-allow=false`,
  `beta-reports-active=true`, reviewed privacy-manifest and host inventory, with no StoreKit
  fixture, test bundle, extension, framework, or extra manifest.
- Owner-authorized upload: **transport accepted** at `2026-09-01 19:27:25 +0800`, delivery UUID
  `1b358d3b-4544-4617-ab47-5be69addc7a8`, status Processing.
- This does not prove tester assignment, Production endpoint traffic/deployment, G1, distribution,
  or public release. DEC-COM-090 records that stop boundary. The documentation-only closeout still
  needs independent review, hosted CI, and merge.

The documentation closeout was then validated locally with Xcode 27.0 beta 6 (`27A5252f`) on the
iOS 26.5 iPhone 17 Pro simulator. `Scripts/validate.sh` passed Release, the strict Dashboard
benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit physical skips, all
18 UI tests with 17 passed and one expected physical-only skip, every selected coverage threshold,
and 23 exact C6-02 runtime bindings. The UI summary contains exactly 18 executions, so no
test-runner retry occurred. The validator deleted its temporary xcresult and that printed path is
only an execution pointer.

The separate closeout C6 release matrix passed 285 tests across 16 suites and all 33 required
runtime bindings. Its result bundle is
`/private/tmp/MindBudget-C6-03-Upload-Closeout-20260901.xcresult`; this local execution pointer is
not hosted, Archive, IPA, final-binary, App Store Connect, G1, distribution, or release evidence.
The closeout still needs independent review, a green hosted run on its exact head, and merge.

### C6-03 / COM-C6 reviewed-product closeout — 2026-09-01

- PR #96 final head `3ed1357` completed GitHub Actions run `33508360536` successfully and merged
  to `main` as `246e7c1`.
- DEC-COM-091 closes C6-03 and COM-C6 from that exact reviewed product-delivery chain while
  preserving the upload as transport evidence only. It does not claim tester assignment,
  external Beta review, App Store submission, privacy-form acceptance, Production traffic, G1,
  distribution, release, or Active Requirement completion.
- G1 remains eligible but unentered pending explicit owner entry, a frozen observation window,
  and accepted real supplier quotes. COM-C6.5 remains blocked pending the post-COM-C6 14-day
  no-P0/P1 gate plus explicit owner entry; `2026-09-15` is the earliest possible entry date.
- Local documentation validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17
  Pro simulator. `Scripts/validate.sh` passed Release, the strict Dashboard benchmark, 553 unit
  tests across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with
  17 passed and one expected physical-only skip, every selected coverage threshold, and all 23
  C6-02 runtime bindings. The 18-execution UI summary proves no test-runner retry occurred.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.XehnXC/MindBudget.xcresult`;
  this path is an execution pointer, not a durable artifact.
- This documentation-only closeout still requires independent review, a green hosted run on its
  exact head, and merge. No later phase or external action is authorized by the local pass.

### G1 quote/economics scope replacement — 2026-09-01

- DEC-COM-092 changes planning and evidence scope only. G1 remains unentered.
- `G1_UNIT_ECONOMICS_PACKET.md` replaces the public-observation prerequisite with dated real
  primary/backup AI and backend quotes, deterministic typical/P50 and peak/P95 cost, a US$4.99
  one-time local-Pro starter-credit scenario, and at least three consumable usage-card options.
- This record contains no supplier quote, cost result, accepted price/count/card/provider,
  Product ID, backend/provider connection, App Store Connect mutation, G1 entry, distribution, or
  release evidence.
- Exact-scope local validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
  simulator. `Scripts/validate.sh` passed Release, the strict Dashboard benchmark, 553 unit tests
  across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17
  passed and one expected physical-only skip, every selected coverage threshold, and all 23
  C6-02 runtime bindings. No UI test-runner retry occurred.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.UjGKJy/MindBudget.xcresult`;
  this path is an execution pointer rather than a durable artifact. The exact updated PR head
  still requires independent review and green hosted CI.

### G1 quote-backed interim economics — 2026-09-02

- The owner explicitly entered G1. DEC-COM-093 records official dated supplier/backend/Apple
  evidence, integer-micro-USD arithmetic, and the interim `INSUFFICIENT_QUOTE_EVIDENCE` result.
- `Scripts/g1_unit_economics.py --self-test` and its packet cross-check pass. The reported planning
  outputs are US$0.011330 typical, US$0.033098 peak, a derived maximum of 11 peak-envelope starter
  uses, provisional 10 starter uses, and 10/25/65-use card candidates.
- These are quote-backed planning estimates, not measured P50/P95 Eval evidence. No credential,
  provider/backend connection, Product ID, App Store Connect mutation, G1 pass, or COM-C7 entry is
  claimed.
- The first full-validator invocation used the default Command Line Tools and stopped after every
  static gate passed because that selection has no `xcodebuild`; it is an environment non-pass.
- The explicit Xcode 27.0 beta 6 (`27A5252f`) rerun on the iOS 26.5 iPhone 17 Pro simulator passed
  Release, the strict Dashboard benchmark, 553 unit tests across 32 suites with four expected
  opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one expected physical-only
  skip, every selected coverage threshold, and all 23 C6-02 runtime bindings.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.AOYlWw/MindBudget.xcresult`;
  this is an execution pointer, not a durable artifact. Independent review, exact-head hosted CI,
  and merge remain required.

### G1 first quote/planning package reviewed merge — 2026-09-02

- Independent review found no P1/P2 on exact PR #98 head `9226985`, manually reproduced its
  arithmetic and conservative rounding, and approved merge after hosted CI.
- GitHub Actions run `33570570896` passed on that exact head. PR #98 merged to `main` as
  `6e2d242`; its second parent is `9226985`.
- DEC-COM-094 closes only the first quote-backed planning evidence package and preserves
  `INSUFFICIENT_QUOTE_EVIDENCE`. It carries the review's low-volume breaker, explicit-self-test,
  and 30-day re-quote observations forward as named obligations.
- G1 remains In Progress. No provider Eval, account-level privacy/region/rate evidence, exact App
  Store proceeds, final owner decision, credential, backend, product, ledger, App Store Connect
  mutation, G1 pass, or COM-C7 entry is claimed.
- Local closeout validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
  simulator. `Scripts/validate.sh` passed Release, the strict Dashboard benchmark, 553 unit tests
  across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17
  passed and one expected physical-only skip, every selected coverage threshold, and all 23 C6-02
  runtime bindings. The 18-execution UI summary proves no test-runner retry occurred.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.aBMHd9/MindBudget.xcresult`;
  this path is an execution pointer, not a durable artifact.
- This documentation-only closeout still requires its own independent review, green hosted CI on
  its exact head, and merge. No later phase or external action is authorized by the recorded PR #98
  merge.

### G1 owner-policy lock and Luna-only recalculation — 2026-09-02

- DEC-COM-095 accepts US$4.99 one-time Pro, an explicitly started 30-day local-only trial with zero
  Luna credits, sole OpenAI `gpt-5.6-luna`, starter/card lots valid for one user-calendar year,
  displayed-valid-result credit accounting, >=50% conservative peak contribution margin,
  refund-without-local-deletion, ordinary-test-user denial, isolated capped Apple App Review
  access, and a separately reviewable local-only release path.
- The integer worksheet now uses one Luna attempt typically and at most one bounded same-model
  retry at peak. At 1,000 successful uses/month it reports US$0.011330 typical/P50 and US$0.018986
  peak/P95. The conservative US$4.99 fulfillment ceiling at 50% margin is US$1.372250.
- The reviewed PR #98 history remains exact head `9226985`, run `33570570896`, merge `6e2d242`, and
  historical result `INSUFFICIENT_QUOTE_EVIDENCE`. The current result is
  `EVAL_AND_ACCOUNT_EVIDENCE_PENDING`; exact counts/SKUs and Luna Eval/account evidence are not
  claimed.
- No Swift product code, provider credential/request, backend, Product ID, App Store Connect
  mutation, COM-C7 entry, distribution, or release action is evidence in this entry.
- `Scripts/g1_unit_economics.py --self-test`, `python3 -O Scripts/g1_unit_economics.py
  --self-test`, and the worksheet/document cross-check passed. The optimized run proves that the
  failure self-tests no longer disappear when Python assertions are removed.
- The first full-validator invocation completed the static gates but inherited Command Line Tools
  and had no full `xcodebuild`; a second invocation selected Xcode 27.0 beta 6 (`27A5252f`) inside
  the restricted sandbox but could not access CoreSimulator or local build state. Both are
  environmental non-passes, not product evidence.
- The identical unrestricted Xcode invocation on the iOS 26.5 iPhone 17 Pro simulator passed
  Release, the strict Dashboard benchmark, 553 unit tests across 32 suites with four expected
  opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one expected physical-only
  skip, every selected coverage threshold, and all 23 C6-02 runtime bindings. The UI summary has
  exactly 18 executions, proving no test-runner retry occurred.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.G71eft/MindBudget.xcresult`;
  this path is an execution pointer, not a durable artifact. Exact-head independent review, hosted
  CI, and merge remain required.

### G1 frozen Luna Eval and exact offer — 2026-09-02

- DEC-COM-096 freezes 24 exact bilingual cases, dataset SHA-256
  `d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014`, and prompt/schema SHA-256
  `1d3e1d874ef054e8a41038cea99154a47c484c21658218d4c58809e19820d40b`.
- `Scripts/g1_luna_eval.py --self-test` and its optimized `python3 -O` form are required. Passing
  deterministic fixtures is not a live model or account pass.
- Exact offer evidence is 10 starter credits plus 10/25/65-use cards at
  US$0.99/US$1.99/US$4.99. The later hard server gate is 1,000 trailing-30-day successful analyses
  and at least 50% recomputed conservative peak margin.
- Account result is `OPENAI_ACCOUNT_NOT_ADMITTED`; live Eval result is
  `LIVE_LUNA_EVAL_NOT_RUN_NO_ADMITTED_ACCOUNT`; current G1 state is
  `ACCOUNT_ADMISSION_AND_LIVE_EVAL_BLOCKED`.
- Normal and optimized (`python3 -O`) Eval self-tests passed, the runner emitted all 24 frozen
  request fixtures, the Luna-only worksheet/document cross-check passed, and the explicit live-run
  negative check stopped before network access while admission remained false.
- The first full-validator attempt passed every static gate but could not access CoreSimulator or
  local build state inside the restricted sandbox; this is an environment non-pass.
- The identical unrestricted Xcode 27.0 beta 6 (`27A5252f`) run on the iOS 26.5 iPhone 17 Pro
  simulator passed Release, the strict Dashboard benchmark, 553 unit tests across 32 suites with
  four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one expected
  physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime bindings. The UI
  summary contains exactly 18 executions, proving no test-runner retry occurred.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.hu81QC/MindBudget.xcresult`;
  this path is an execution pointer rather than a durable artifact.
- No provider request, credential, Product ID, backend, ledger, App Store Connect mutation, or
  product runtime change is evidence in this entry. Exact-head independent review, hosted CI, and
  merge remain required.

### G1 standard-controls synthetic-Eval admission — 2026-09-02

- DEC-COM-097 supersedes only the earlier ZDR-as-fixed-Eval-prerequisite. ZDR is not claimed.
- Owner-observed account evidence records the dedicated Global project, Luna-only allow-list,
  Tier 1 500,000 TPM/500 RPM/5,000,000 TPD, US$5 project soft limit/alert, US$18.72 Pay-as-you-go
  balance, and auto-reload off. No secret/account/payment identifier is durable evidence.
- Machine admission schema version 2 pins `synthetic_eval_only`, standard abuse-monitoring
  retention up to 30 days, `store=false`, `background=false`, explicit cache mode without
  breakpoints, the exact Global base URL, and `productionAdmitted: false`.
- Sharing/logging Saved-state confirmation and credential isolation remain false; therefore
  `OPENAI_ACCOUNT_NOT_ADMITTED`, `LIVE_LUNA_EVAL_NOT_RUN_NO_ADMITTED_ACCOUNT`, and
  `ACCOUNT_ADMISSION_AND_LIVE_EVAL_BLOCKED` remain current. No live request is evidence here.
- `Scripts/g1_luna_eval.py --self-test` and its optimized `python3 -O` form pass. The
  commercialization document gate validates the exact schema/retention/scope/base-URL
  relationships and rejects production admission or incomplete Eval admission.

### G1 Luna live Eval execution — 2026-09-02

- DEC-COM-098 records two explicit non-passes and one automated pass; none is independent review.
- Attempt 1: 48 zero-token undifferentiated HTTP failures, transcript SHA-256
  `f879f0752c525e6c3abae5791de5e524fdba7390b6af2ed24eb32b209618ddd4`.
- Attempt 2: one fail-fast `HTTP_400:invalid_json_schema:text.format.schema`, transcript SHA-256
  `5e7728f42c2145d6765c6f4d0efada050ffe30e8dc7211ba7a6c0df88be055a3`.
- Attempt 3: 24/24 first-pass valid, zero retries/hard failures; input tokens P50 296/P95 301,
  output tokens P50 128/P95 203, latency P50 3,614/P95 5,389 ms. Passing transcript SHA-256
  `4800cc6c8458fa39b0bd4419d90fbf7ee4bfa47bc3deffa73475b751e947999e`.
- Dataset SHA-256 remains `d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014`;
  provider-compatible prompt/schema SHA-256 is
  `c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018`.
- Normal/optimized self-tests and transcript re-scoring pass. The first full-validator invocation
  selected `/Library/Developer/CommandLineTools` and stopped before Xcode execution; a second
  invocation referenced the no-longer-present `/Users/shaola/Downloads/软件/Xcode.app`. Both are
  retained as environment non-passes.
- The exact unrestricted run with Xcode 27.0 beta 6 (`27A5252f`) from
  `/Applications/Xcode-27-beta-6.app` on the iOS 26.5 iPhone 17 Pro simulator passed Release, the
  strict Dashboard benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit
  physical skips, all 18 UI tests with 17 passed and one expected physical-only skip, every
  selected coverage threshold, and all 23 C6-02 runtime bindings. The UI summary contains exactly
  18 executions, so no test-runner retry occurred.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.vnH8ya/MindBudget.xcresult`;
  the path is an execution pointer rather than a durable artifact. Exact-head independent review,
  hosted CI, and merge remain open. G1 stays In Progress and production false.

### G1 Luna Eval reviewed-delivery closeout — 2026-09-02

- Independent review read all 24 final outputs and exact PR #100 head `323d8d7`, found no P1/P2,
  and accepted the automated result. Four P3 groups remain maintenance obligations rather than
  blockers or completed fixes.
- GitHub Actions run `33593253561` completed successfully on exact head
  `323d8d7904cf4d2413efa661b50e7d092a860af0`. PR #100 merged that head as
  `7a473d2f4123bef60615efd9f104cee2e473afd5`.
- The machine result now records schema version 2 and exact review provenance. Transcript hashes,
  the 24/24 first-pass result, zero retries/hard failures, token/latency statistics, and the two
  earlier non-passes are unchanged.
- A first closeout validation attempt in the restricted execution sandbox stopped before Xcode
  testing because CoreSimulatorService was unavailable; it is a local environment non-pass. The
  exact unrestricted Xcode 27.0 beta 6 (`27A5252f`) run on the iOS 26.5 iPhone 17 Pro simulator
  then passed Release, the strict Dashboard benchmark, 553 unit tests across 32 suites with four
  expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one expected
  physical-only skip, every selected coverage threshold, and all 23 C6-02 runtime bindings. The UI
  summary contains exactly 18 executions, so no test-runner retry occurred.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.lbMNy3/MindBudget.xcresult`;
  this is an execution pointer rather than a durable artifact.
- PR #101 review found that the closeout had silently removed the still-unfulfilled three-way
  template/on-device/Luna comparison from the `PROCEED_TO_R2` list. The remediation restores that
  prerequisite, restores the historical DEC-COM-098 pointer text instead of rewriting it, and
  validates the P3 count by type/range rather than freezing the entire review object. Exact-head
  rereview and a new hosted run remain required.
- DEC-COM-099 advances only to `EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`. G1 stays In Progress,
  `productionAdmitted` stays false, and COM-C7 stays blocked. This documentation closeout still
  requires its own exact-head independent review, hosted CI, and merge.

## 2026-09-02 — G1 three-way Eval harness and physical-output checkpoint

- DEC-COM-100 freezes the harness boundary without claiming physical or comparative evidence.
- Xcode 27.0 beta 6 (`27A5252f`) completed a generic iOS Debug `build-for-testing` for the dedicated
  `MindBudget-G1-OnDevice-Eval` scheme with code signing disabled. This proves compilation only; it
  is not Apple on-device output or comparative-value evidence.
- A prior restricted build could not execute Swift macro plugins under the sandbox and is a local
  environment non-pass. Direct destination inspection then found no available physical iPhone.
- `拉沙的iPhone` remains the only authorized device; `Xiao li的 iPhone (2)` remains excluded. At
  that compile-only checkpoint, no test had run on either device, no Luna request occurred, and no
  three-way result was claimed.
- After the owner connected the authorized phone, the exact selected physical test passed 1/1 and
  emitted structured Apple output for 24/24 cases in 29.579 seconds. This is physical synthetic Eval
  output, not final-binary/customer/production evidence; comparative value awaits independent
  blind review. No OpenAI request occurred during this run.
- `/private/tmp/mindbudget-g1-three-way-eval/on-device-eval.xcresult` and its Xcode log are local
  execution pointers, not durable repository artifacts. The normalized JSONL transcript proves
  only the exact Xcode destination string plus privacy-reduced iPhone/iOS metadata; it does not
  durably prove a marketing name or hardware identifier. The still-unfilled blind packet and
  post-score-only sidecar are separately pinned by exact hashes in DEC-COM-100.
- PR #102 review reproduced source/count/error leakage in the first scoring packet. The remediated
  scoring surface omits those fields; the sealed sidecar retains them and the A/B/C mapping for
  post-score use. Duplicate candidate bodies are mechanically ineligible to prove cloud value.
- GitHub Actions run `33623886226` on original head `9f04cee` is retained as a hosted non-pass.
  The AX5 multi-appearance UI case first failed on unsettled legal navigation and later geometry/
  reachability assertions, then passed under the configured retry. The C6-02 verifier correctly
  rejected `Repetition:Failed` followed by `Repetition:Passed`; neither the retry nor the eventual
  pass is accepted as green evidence for that head.
- The complete local validation run then exited 0 under Xcode 27.0 beta 6: all static gates passed,
  the simulator UI suite executed 18 tests with 1 expected physical-only skip and 0 failures, every
  selected core file remained above the 85% coverage floor, and the C6-02 verifier found all 23
  exact runtime bindings. This validates the repository change; it is not the independent blind
  comparison and does not advance G1.

### G1 three-way capture reviewed-delivery closeout — 2026-09-02

- Independent PR #102 review accepted exact remediation head
  `bb939d035ab11bd7845edd30363e19631f5fce1a`. That review covered the implementation, captured
  evidence, scoring-surface isolation, duplicate-candidate fail-close, and remediation; it was not
  the later blind-value score.
- GitHub Actions run `33628847476` completed successfully on that exact head. PR #102 merged it as
  `225490286a544bdb6141d47546ba7666185756fd`, whose second parent is the reviewed head.
- DEC-COM-101 closes only the delivery chain. The unfilled blind JSON remains SHA-256
  `bcbf943ba7d6a1a9d18442efc38e760cc798c30e8674c8d877f9e0cb751ab2a5`; the sidecar must remain
  unopened by the different eligible reviewer until every review field is complete using only that
  scoring surface.
- G1 remains In Progress at `EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE`; production remains false
  and COM-C7 remains blocked. This closeout branch still requires its own exact-head review, hosted
  CI, and merge and cannot supply the pending subjective score.
- The first closeout `Scripts/validate.sh` invocation selected
  `/Library/Developer/CommandLineTools` and stopped before Xcode execution because it is not a full
  Xcode developer directory. This is a local environment non-pass; corrected validation explicitly
  selects Xcode 27 beta 6. The second restricted attempt reached Xcode but could not access
  CoreSimulatorService or the local bundle-ID configuration; it is another local environment
  non-pass. Final validation must run outside that restricted sandbox.
- The identical unrestricted validation exited 0 under Xcode 27.0 beta 6 (`27A5252f`) on the iOS
  26.5 iPhone 17 Pro simulator: Release and the strict Dashboard benchmark passed; 554 unit tests
  across 33 suites passed with four expected physical CloudKit skips; exactly 18 UI tests executed
  with 17 passed, one expected physical-only skip, zero failures, and no retry; every selected core
  file exceeded the 85% coverage floor; and all 23 C6-02 runtime bindings passed.
- The validator deleted
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.upf8G2/MindBudget.xcresult`;
  this path is an execution pointer, not a durable artifact. Exact-head independent review, hosted
  CI, and merge remain open; the blind comparative score remains unperformed.

### G1 independent three-way blind-review result — 2026-09-02

- The reviewer completed the exact blind packet from merge
  `f73881f209054068520e3c736f9e312fe22869e8` before the sidecar was opened. The score lock is
  commit `cd579be`; completed packet SHA-256 is
  `d2b9310f4471400825e666009f646a190d8ac2819f859c8e38d58ec05cbf040e`.
- `Scripts/g1_three_way_eval.py --check-review-packet ... --require-complete-review` validates all
  24 reviews and re-derives the unchanged frozen inputs and sidecar from the physical transcript.
- The post-lock summarizer reproduces
  `G1_THREE_WAY_REVIEW_RESULT_2026-09-02.json`: `NON_PASS`, zero materially preferred Luna cases,
  no qualifying bilingual task, `production_admitted: false`.
- No second eligible blind score exists; earlier delivery reviewers were mapping/source-aware.
  Inter-rater overlap is unavailable and is not treated as zero agreement or estimated evidence.
- DEC-COM-102 advances only to `COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION`. G1 remains In
  Progress and COM-C7 remains blocked. This branch's exact-head independent review, hosted CI, and
  merge remain required.
- The first validation attempt selected the now-absent
  `/Users/shaola/Downloads/软件/Xcode.app` path and stopped before tests; the second reached the
  correct Xcode under the restricted sandbox but could not access CoreSimulatorService or the
  local bundle-ID configuration. Both are environment non-passes.
- The identical unrestricted validator then exited 0 under Xcode 27.0 beta 6 (`27A5252f`) on the
  iOS 26.5 iPhone 17 Pro simulator. Release and the strict Dashboard benchmark passed; 554 unit
  tests across 33 suites passed with four expected physical CloudKit skips; exactly 18 UI tests
  executed with 17 passed, one expected physical-only skip, zero failures, and no retry; every
  selected core file exceeded the 85% coverage floor; and all 23 C6-02 runtime bindings passed.
- The deleted temporary bundle
  `/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.ntEklp/MindBudget.xcresult`
  is an execution pointer only. No hosted result or independent review is claimed for this branch.
- PR #104 review reproduced the two-commit lock/unseal chain and deterministic `NON_PASS`, then
  found stale pending-review wording in three current-state surfaces. The remediation preserves
  historical pending evidence while requiring exact current headers and the top-level Active phase
  to identify DEC-COM-102 plus `COMPARATIVE_EVAL_NON_PASS_PENDING_OWNER_DECISION`. A new exact-head
  hosted run and rereview remain required; the prior green run `33645828051` belongs to head
  `a4b5d19` and does not validate this remediation.
