# Commercialization Session Log

## 2026-08-10 — Session 1 — COM-C0A specification lock and repository audit

Goal: Execute the read-only COM-C0A audit against the owner-approved v1.4 specification, establish
a reproducible repository baseline, map stable requirements and conflicts, and stop before any
commercial product implementation.

What was completed: Locked the v1.4 source at SHA-256
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0` and audited merged `main`
commit `6226823370d9ecaedfd89f2754e1f5705dc8d5dd`. Recorded Xcode/Swift/SDK, bundle, signing,
target, dependency, schema, migration, model, money, StoreKit, CloudKit, network, telemetry,
backend, third-party, receipt/Vision, Foundation Models, privacy, logging, export, deletion,
permission, and Watch baselines. Created `REQUIREMENTS_INDEX.md`, `SPEC_CONFLICTS.md`, and
`COM_C0A_REPORT.md`. Confirmed the existing app has 15 V4 SwiftData models and exact minor-unit
money but no StoreKit catalog/entitlement, CloudKit, business network/telemetry/backend,
third-party model, receipt/Vision pipeline, or Watch target. No product code or schema changed.

What was NOT completed: COM-C0A was not marked Done because SPEC-012 (current local-only rules
versus approved later channels), SPEC-013 (Watch/G1 ordering), and SPEC-014
(price/product/economics phase cycle) require explicit owner decisions. Product IDs remain blocked
by SPEC-017. No COM-C0B memory/decision matrix, product code, formal StoreKit product, CloudKit
container, telemetry receiver, backend resource, Watch target, receipt import, model provider,
version, archive, upload, or tester assignment was created.

Build and test result: pass — with
`DEVELOPER_DIR=/Users/shaola/Downloads/软件/Xcode.app/Contents/Developer`, Xcode 26.6 completed the
generic iOS Simulator Release build and the complete Swift Testing suite with zero functional
failures. All 13 UI tests passed. The shared-host wall-clock benchmark was excluded through the
existing documented switch; its deterministic 10,000-row contract still ran.

Static and coverage result: pass — the no-floating-point-money and release-readiness gates passed.
Every selected service passed the 85% coverage gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.02%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService
97.42%, IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: The owner should explicitly close SPEC-012, SPEC-013, and SPEC-014 and accept
the COM-C0B input assumptions. After those decisions are recorded, begin COM-C0B documentation and
execution controls only; do not begin entitlement or StoreKit product code early.

## 2026-08-10 — Session 2 — COM-C0A owner decision gate

Goal: Record the owner's answers to the COM-C0A P0 conflicts, choose canonical subscription
identifiers, and determine whether COM-C0B is legally ready without starting it.

What was completed: Accepted SPEC-012 with a phase-scoped rule: existing versions remain
unchanged, while later iCloud, first-party telemetry, or multi-provider cloud-AI channels may be
enabled only after user authorization, privacy disclosure, deletion, and release gates pass.
Accepted SPEC-013: Watch development may occur in the intermediate parallel window but does not
block G1, COM-C7, COM-C12, or the formal iPhone 1.0 launch; Watch distribution is a separate
post-iPhone-1.0 milestone. Accepted SPEC-014's configuration → preliminary economics → G1 final
economics sequence. Accepted SPEC-017 with Monthly
`com.xdgf558.mindbudget.pro.monthly`, Annual `com.xdgf558.mindbudget.pro.annual`, subscription
group reference `MindBudget Pro`, and matching internal product reference names. Updated the
Requirement index, audit report, phase map, project memory, and task status. COM-C0A is Done and
COM-C0B is Ready.

What was NOT completed: No COM-C0B artifact, entitlement code, StoreKit configuration/product,
subscription group, price, trial, quota, CloudKit container, telemetry receiver, backend, Watch
target, receipt pipeline, version, Archive, upload, or tester assignment was created. Product IDs
are accepted technical names only; App Store Connect objects remain absent and evidence-gated.

Validation result: Documentation-only decision recording. `git diff --check` and the
documentation-only product-code guard are required before handoff; the full COM-C0A build/test
baseline remains the passing evidence from Session 1.

Next suggested task: On explicit owner instruction, enter COM-C0B and create the durable commercial
memory/decisions plus egress, provider, StoreKit, pricing, and CI control matrices. Keep prices,
trial, included calls, reset rules, and formal products TBD until their accepted evidence gate.

## 2026-08-10 — Session 3 — COM-C0B durable controls and executable baseline

Goal: Complete COM-C0B without implementing paid behavior: promote accepted requirements into
durable commercial memory/decisions, establish security/commercial matrices and reproducible CI
evidence, correct the stale current deletion statement, and prepare independently reviewable
COM-C1 packets.

What was completed: Created commercial `PROJECT_MEMORY.md` and `DECISIONS.md`; recorded accepted
Monthly/Annual Product IDs, deferred Lifetime, three-stage economics, Free iCloud, provider-neutral
consent-bound AI, independent backend, Watch ordering, and no production tester rights. Created
`NETWORK_EGRESS_POLICY.md` with an accepted empty current app-owned Release HTTP(S) set,
`AI_PROVIDER_CONTRACT.md`, `STOREKIT_TEST_MATRIX.md`, `REGIONAL_PRICING.md`, `CI_BASELINE.md`, and
`COM_C1_EXECUTION_PACKET.md`. Added a CI/local documentation gate and optional deterministic
`.xcresult` path without changing default validation cleanup. Resolved SPEC-018 by replacing the
fragile ten-model privacy/test-memory wording with all-current-model verification. Updated root
agent rules with the phase-scoped future-channel contract and main documents with short pointers.

What was NOT completed: No app source, SwiftData schema/resource, user-facing copy, entitlement,
StoreKit import/configuration/product/group, price, trial, paywall, production unlock, CloudKit
container, telemetry, backend, provider/model, receipt/Vision, Watch target, version, Archive,
upload, or tester assignment was created. Commercial prices, trial, cloud calls/reset,
storefronts, providers/contracts, domains, CloudKit architecture, and App Attest remain
TBD/UNVERIFIED. COM-C1 remains unstarted until explicit owner instruction.

Validation result: pass. Static release-readiness, no-floating-point-money, and the new commercial
documentation gate passed. Xcode 26.6 completed the generic iOS Simulator Release build, 270 Swift
tests in 17 suites, all 13 UI tests, and the existing coverage gate. The first sandboxed attempt
could not write Xcode DerivedData/CoreSimulator state; rerunning the identical command with normal
Xcode filesystem access passed. Result bundle:
`TestResults/Commercialization/COM-C0B/local/MindBudget.xcresult` (ignored evidence workspace).
Coverage remained Money 91.73%, BudgetEngine 95.18%, BudgetCycleCalculator 95.17%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 91.02%,
AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService 97.42%,
IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Enter COM-C1 only on explicit owner instruction. Execute C1-01, C1-02, and
C1-03 as separate review units; stop before StoreKit, products, purchase UI, or schema migration.

## 2026-08-10 — Session 4 — COM-C0B executable review-gate closeout

Goal: Close PR #24 review findings by turning the empty current Release network policy and CI
result-bundle promise into executable, reviewable controls without starting COM-C1.

What was completed: Added `Scripts/check-network-egress.sh`, which scans every app Swift source
file and rejects app-owned networking primitives, networking-framework imports, and HTTP(S)
literals while the accepted allow-list is empty. Wired the gate into local validation and CI with
no broad source exception. Added a pinned `upload-artifact` step so the deterministic xcresult is
downloadable after the runner is destroyed. Replaced the repeated unanchored source hash with
`SOURCE_PROVENANCE.md`: the owner-held detailed specification remains outside the public
repository, while its audited fingerprint, byte length, date, derived snapshot, limitation, and
mandatory replacement-source re-audit procedure are explicit. Made the open-P0 check independent
of field order and self-tested it. Added `BudgetPlanSemantics` to the current local-model privacy
inventory and corrected the stale SPEC-015 status in the commercial memory/index. After the first
review-fix push exposed a workflow-loader failure with no jobs/logs, moved `runner.temp` use from
job-level `env` to the Build-and-test step where that context is valid; artifact upload continues
to use the same runner-temporary result bundle. The first successful remote run then exposed only
the old upload action's Node 20 migration warning, so the action was repinned to GitHub's verified
`v7.0.1` commit, which declares the current Node 24 runtime.

What was NOT completed: No app source, schema/resource, entitlement, StoreKit product/group,
price, trial, paywall, CloudKit, telemetry, backend, provider, Watch target, receipt flow, version,
Archive, upload, or tester assignment changed. The lexical source gate remains defense in depth;
binary and captured-traffic verification still belong to the later release gate. COM-C1 remains
unstarted.

Validation result: pass. The no-floating-point-money, release-readiness, source-network, and
commercial-document gates passed. Xcode 26.6 completed the Release build, 270 Swift tests and 13
UI tests with zero failures, plus the existing coverage gate. The shared-host wall-clock signal
was excluded through its documented switch; the deterministic 10,000-row contract still ran.
Result bundle:
`TestResults/Commercialization/COM-C0B/review-fix/MindBudget.xcresult` (ignored evidence
workspace). Coverage remained Money 91.73%, BudgetEngine 95.18%, BudgetCycleCalculator 95.17%,
SpendingPatternDetector 97.57%, ReminderThrottle 96.84%, ReminderEngine 91.02%,
AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%, CycleSummaryService 97.42%,
IntentClassifier 97.50%, CSVExporter 87.60%, and CurrencyFormatterService 100%.

Next suggested task: Confirm the updated PR CI is green. After merge, enter COM-C1 only on a new
explicit owner instruction and follow its three review packets without importing StoreKit early.

## 2026-08-11 — Session 5 — Final COM-C0B gate-hardening review closeout

Goal: Close the remaining PR #24 review notes about lexical false positives, unscanned Release
configuration, and substring conflict matching without expanding beyond COM-C0B.

What was completed: `Scripts/check-network-egress.sh` now ignores full-line Swift/configuration
documentation comments and recognizes quoted HTTP(S) endpoints instead of every prose URL. Its
scan surface now includes app property lists, entitlements, privacy manifests, xcconfig files,
and `MindBudget.xcodeproj/project.pbxproj` generated-Info.plist settings, with explicit detection
for ATS exceptions, networking entitlements, associated domains, and endpoint values. Built-in
positive and negative samples prove the source and configuration detectors before scanning the
repository, including harmless Apple documentation links and the standard plist DTD. The
open-P0 parser now token-matches both `Open` and `P0`, and rejects `Open-ended P01`. DEC-COM-010,
the egress policy, memory, root pointer, and COM-C0B evidence now describe the implemented scope.

What was NOT completed: No accepted allow-list row changed and no exception was added. No app
behavior, source/schema/resource, networking entitlement, URL, StoreKit, CloudKit, telemetry,
backend, provider, receipt, Watch, release version, Archive, upload, or tester state changed.
COM-C1 remains unstarted.

Validation result: pass under Xcode 26.6. Static gates, Release build, 270 deterministic Swift
tests, 13 UI tests, and all service coverage thresholds passed. A first strict run recorded the
known local wall-clock-only dashboard benchmark at 0.752 seconds; the successful rerun used the
documented shared-host skip for that single timing signal while retaining the deterministic
10,000-row projection test.

Next suggested task: Confirm PR #24 CI is green and merge only with owner approval; start COM-C1
only after a separate explicit instruction.

## 2026-08-11 — Session 6 — COM-C1-01 pure entitlement domain

Goal: Start COM-C1 with only the first approved review unit: a pure, deterministic entitlement
domain that cannot unlock deferred commercial surfaces.

What was completed: Added a `Sendable` `EntitlementSet` with exact Free and Pro-subscription
values, deterministic union/removal semantics, and a private raw-bit initializer. The only
Release-reachable paid value is Pro subscription; Local Lifetime, Connect, bank sync, family
collaboration, StoreKit product identifiers, and test/grace-state mapping are not representable
as production entitlements in this packet. Added a closed `PremiumFeature` vocabulary for the
approved Pro seams and a separate `FreeCoreFeature` proof vocabulary so manual records, CSV
export, Delete All, app lock, and opt-in iCloud cannot be reclassified as premium features.
Added an explicit version-1 representation and migrator: unsupported versions and unknown bits
throw at the strict boundary and resolve to exact Free at the fail-closed boundary. Tests cover
Free, subscribed and grace fixtures, union, duplicates, removal, representation round trips,
unknown bits, unsupported versions, the exact premium vocabulary, the sole reachable paid value,
and the Free-core separation. DEC-COM-012 records the boundary and assigns runtime access
decisions to C1-02.

What was NOT completed: No `FeatureAccessService`, environment injection, Debug provider,
StoreKit import/configuration/product/group, product-ID mapping, purchase/restore flow, paywall,
paid UI, cloud/backend/provider, telemetry, schema/resource, release version, Archive, upload, or
tester state was added. C1-02 and C1-03 remain unstarted; no user-visible behavior changed, so no
changelog entry was added.

Validation result: pass under Xcode 26.6. The focused commercialization entitlement suite passed
with zero failures. The full validation then passed the Release build, complete Swift test run,
all 13 UI tests, no-floating-point-money, current empty-egress, commercialization-document, and
release-readiness gates, plus every existing core-service coverage threshold. The documented
shared-host switch excluded only the nondeterministic 500 ms wall-clock signal; the deterministic
10,000-row dashboard projection test remained enabled.

Next suggested task: Open a focused C1-01 review PR. Begin C1-02 only after this packet is reviewed
and merged; do not import StoreKit or add paid UI while reviewing C1-01.

## 2026-08-11 — Session 7 — Close COM-C1-01 entitlement-domain review findings

Goal: Close PR #25's entitlement-domain review findings before any C1-02 consumer is allowed to
depend on the new vocabulary.

What was completed: Renamed the set operation from the ambiguous `contains(_:)` to
`isSuperset(of:)`, documented that every entitlement set is a superset of exact Free, and added a
regression test proving callers must use `isFree` when deciding that no paid right exists. Bound
`reachablePaidEntitlements` structurally to the complete version-1 known-bit mask so a future bit
cannot be added without also extending the reachable-right inventory. Reframed the accepted
subscription fixture as a domain-vocabulary placeholder rather than StoreKit state-mapping proof;
COM-C2 still owns subscribed, grace, retry, expired, revoked, unverified, and pending mapping. The
migrator now switches on the persisted representation version and delegates version 1 to its own
branch, leaving the natural extension point for later versions while all unsupported versions and
unknown bits continue to fail closed. DEC-COM-012 records these contracts.

What was NOT completed: No C1-02 access service or consumer, StoreKit mapping/import/product,
Debug override, paid UI, purchase/restore/paywall, cloud/backend/provider, telemetry, schema,
resource, release version, Archive, upload, or tester state changed. No changelog entry was added
because there is no user-visible behavior change.

Validation result: pass under Xcode 26.6. The focused commercialization entitlement suite passed
11 tests with zero failures. Full validation passed the Release build, 281 Swift tests in 18
suites, all 13 UI tests, no-floating-point-money, empty-egress, commercialization-document, and
release-readiness gates, plus every existing core-service coverage threshold. The documented
shared-host switch excluded only the nondeterministic wall-clock signal; the deterministic
10,000-row projection contract remained enabled.

Next suggested task: Push this closeout to PR #25 and confirm CI is green. Merge only on the
owner's instruction; begin C1-02 only after that merge.

## 2026-08-11 — Session 8 — COM-C1-02 central feature-access boundary

Goal: Implement the second isolated COM-C1 packet after C1-01 review and merge, without adding
StoreKit, paid UI, products, persistence, or feature-entry locks.

What was completed: Added the pure immutable `FeatureAccessService` and
`FeatureAccessChecking` protocol. Every closed `PremiumFeature` now has one exhaustive central
decision against an injected `EntitlementSet`; the production environment and session default to
exact Free. Added a `#if DEBUG`-only arbitrary-combination provider with no UserDefaults, process
argument, model, file, or other persistence path. The full Free/subscription feature matrix,
removal back to exact Free, 128 concurrent immutable snapshots, AppSession ownership/default, and
all currently constructible Debug combinations have focused tests. Added
`Scripts/check-feature-access-boundary.sh` to full validation so raw entitlement-bit reads,
`isSuperset(of: .free)`, duplicate subscription decisions, persisted/manual authority, an
unguarded Debug provider, or a StoreKit import fail closed. DEC-COM-013 and the C1-02 review
checklist record the boundary.

What was NOT completed: No existing feature entry consumes this decision yet; that remains C1-03.
No StoreKit mapping/import/product, purchase/restore/paywall, price/trial/quota, visible Pro lock,
schema/resource, networking/cloud/provider, telemetry, release version, Archive, upload, or tester
state changed. No changelog entry was added because user-visible behavior is unchanged.

Validation result: pass under Xcode 26.6. Focused commercialization entitlement/access tests
passed. Full validation passed the Release build, complete Swift test suite, all 13 UI tests,
no-floating-point-money, empty-egress, commercialization-document, feature-access-boundary, and
release-readiness gates, plus every existing core-service coverage threshold. The documented
shared-host switch excluded only the nondeterministic wall-clock signal while retaining the
deterministic 10,000-row dashboard projection contract.

Next suggested task: Review C1-02 as its own PR. Begin C1-03 only after that packet is reviewed and
merged; do not import StoreKit or add unapproved paid UI while reviewing C1-02.

## 2026-08-11 — Session 9 — Close COM-C1-02 authority-bypass review findings

Goal: Close PR #26's two feature-access gate findings before C1-03 can consume the central
authority.

What was completed: Extended `Scripts/check-feature-access-boundary.sh` so app source outside
`EntitlementDomain.swift` cannot call `EntitlementSetMigrator`; a stored, file, or network
representation therefore cannot silently reconstruct a paid set and become a second Release
authority before COM-C2 explicitly owns and reviews that adapter. Refactored the DEBUG-provider
preprocessor scan into a reusable parser and added built-in fixtures proving that an active
`#if DEBUG` declaration is accepted while an unguarded declaration and a declaration in the
`#else` branch are rejected. The parser also accepts a harmless trailing comment on the DEBUG
directive. Updated DEC-COM-013 and the C1-02 execution/review evidence. No changelog entry was
added because app behavior and user-visible copy are unchanged.

What was NOT completed: No C1-03 feature entry was integrated or locked. No StoreKit mapping,
product/group, persistence authority, purchase/restore/paywall, paid UI, price/trial/quota,
schema/resource, network/cloud/provider, telemetry, version, Archive, upload, or tester state
changed. COM-C2 must later make any migrator allow-list change explicit and independently
reviewable.

Validation result: pass under Xcode 26.6. Shell syntax, the feature-access gate and its built-in
fixtures, and the no-floating-point-money gate passed. Full validation passed the Release build,
286 Swift tests in 18 suites, all 13 UI tests, the static release/network/commercial/access gates,
and every existing core-service coverage threshold. The documented shared-host switch excluded
only the nondeterministic 500 ms wall-clock signal while retaining the deterministic 10,000-row
dashboard projection contract. The first validation invocation stopped before build because the
machine-wide `xcode-select` pointed to Command Line Tools; the identical validation with the
project-recorded Xcode 26.6 `DEVELOPER_DIR` passed.

Next suggested task: Push this focused closeout to PR #26, confirm CI is green, and merge only on
the owner's instruction. Begin C1-03 only after that merge.

## 2026-08-11 — Session 10 — Close COM-C1-02 authority chokepoints

Goal: Close the final feature-access authority bypass before C1-03 begins, without chasing every
individual API capable of returning an entitlement set.

What was completed: Made Commerce the executable authority chokepoint. App source outside
`MindBudget/Commerce/` may construct only the no-argument `FeatureAccessService()` whose snapshot
is exact Free; any parameterized or multiline construction is rejected. Implementations and
refinements of `FeatureAccessChecking` are likewise reserved for Commerce, while ordinary app
consumers may still store the protocol existential. The gate's parsers include same-code-path
fixtures proving the safe cases pass and entitlement injection, provider conformance, and
protocol refinement fail. The earlier `.proSubscription`, migrator, raw-bit, StoreKit,
persistence, and DEBUG-provider checks remain as defense in depth. DEC-COM-013 and the C1-02
review packet now record this boundary. No changelog entry was added because app behavior and
user-visible copy are unchanged.

What was NOT completed: No C1-03 feature entry was integrated or locked. No StoreKit state or
product mapping, persisted entitlement authority, purchase/restore/paywall, paid UI,
price/trial/quota, schema/resource, network/cloud/provider, telemetry, version, Archive, upload,
or tester state changed.

Validation result: pass under Xcode 26.6. Shell syntax and the focused access, money, network,
commercial-document, and release gates passed. Full validation passed the Release build, 286
Swift tests in 18 suites, all 13 UI tests, and every core-service coverage threshold. The
documented shared-host switch excluded only the nondeterministic wall-clock signal while
retaining the deterministic 10,000-row projection contract. A first sandboxed invocation lacked
CoreSimulator and DerivedData access; the same validation under normal Xcode permissions passed.

Next suggested task: Push this focused closeout to PR #26, confirm CI is green, and merge only on
the owner's instruction. Begin C1-03 only after that merge.

## 2026-08-11 — Session 11 — Integrate accepted existing premium entries

Goal: Complete COM-C1-03 by connecting only the three owner-approved existing feature entries to
the central access authority, without introducing StoreKit, products, or purchase surfaces.

What was completed: Added the immutable `ExistingPremiumEntryAccess` projection, whose only
source is `FeatureAccessChecking`, and injected it through `AppEnvironment`/`AppSession` into the
accepted entries: Apple on-device text enhancement, custom cooling-off periods, and advanced
Siri/App Intents. Exact Free remains the production/default snapshot. Free keeps deterministic
Ask/reminder templates, the 24-hour cooling period, basic expense-recording and budget-check Siri,
and every established Free trust capability. Advanced Siri returns a neutral localized
not-yet-available response; custom/72-hour cooling choices are not offered under Free, and the
write boundary also rejects a new or changed non-24-hour duration. Existing legacy durations stay
readable and are not rewritten. The static authority gate now rejects feature-local decision
calls, Pro/premium boolean aliases, manual unlock vocabulary, and commercial product identifiers
outside Commerce. Focused tests cover exact Free and subscribed snapshots, Free/paid cooling
durations, basic-versus-advanced Siri, model-versus-template paths, and the preserved Free
baseline. DEC-COM-014 records the accepted-entry boundary.

What was NOT completed: No StoreKit state or import, product/group, subscription cache,
purchase/restore/paywall, paid marketing UI, price/trial/quota, receipt, schema/resource,
network/cloud/provider, telemetry, Watch release, app version, Archive, upload, or tester state
changed. COM-C2 remains out of scope until C1-03 is independently reviewed and merged.

Validation result: pass under Xcode 26.6. Static money, empty-egress, commercial-document,
feature-access, and release-readiness gates passed. Full validation passed the Release simulator
build, complete Swift test suite, all 13 UI tests, and every core coverage threshold. The focused
C1-03 selection passed 114 tests in five suites. The documented shared-host switch skipped only
the nondeterministic wall-clock signal and retained the deterministic 10,000-row projection test.
A sandboxed validation attempt could not access CoreSimulator/DerivedData; the identical normal
Xcode run passed completely.

Next suggested task: Open/review C1-03 as one focused PR. Merge only with owner approval; begin
COM-C2 only after merge and a fresh explicit instruction.

## 2026-08-11 — Session 12 — Close C1-03 disclosure and passive-query review

Goal: Resolve PR #27's exact-Free disclosure and passive App Entity behavior findings while
preserving the accepted C1 boundary.

What was completed: Passive advanced App Entity providers now return no entities when exact Free
or Siri-unavailable instead of throwing a user-facing error during system-initiated lookup. The
seven covered providers are expense, wishlist, cooling-off, merchant, insight, budget snapshot,
and emotion-tag queries. User-invoked advanced Siri writes still fail closed with neutral
localized copy. The Free cooling-off screen now renders its fixed 24-hour duration as read-only
content rather than a one-choice segmented picker. Updated DEC-COM-014, the C1 packet, commercial
memory, changelog, submission notes, and release checklist to enumerate the removed advanced
surfaces, retained Free capabilities, legacy-record compatibility, passive-versus-active Siri
semantics, and the intentional distribution hold. Added regression tests for passive query
emptiness, active write rejection, and the Free cooling UI.

What was NOT completed: No compatibility entitlement was injected and no feature was temporarily
re-enabled. No StoreKit mapping/import, product/group, persisted entitlement authority,
purchase/restore/paywall, paid marketing UI, price/trial/quota, receipt, schema, network/cloud,
provider AI, telemetry, Watch release, version, Archive, upload, tester, or App Store state
changed. The already-uploaded 0.9.6 binary is unaffected; post-C1 source remains ineligible for
distribution until the accepted commerce and release gates are complete.

Validation result: pass under Xcode 26.6. Static money, empty-egress, commercial-document,
feature-access, release-readiness, and diff gates passed. Full validation passed the Release
build, all Swift tests, all 13 UI tests, and every core coverage threshold. The shared-host option
excluded only the nondeterministic wall-clock signal and retained the deterministic 10,000-row
projection test. An initial invocation used Command Line Tools and stopped before build; the
identical run with the project-recorded Xcode 26.6 developer directory passed fully.

Next suggested task: Push the focused closeout to PR #27, wait for green CI, and merge only after
owner approval. Start COM-C2 only after merge and a new explicit instruction.

## 2026-08-11 — Session 13 — Close COM-C1 and implement COM-C2-01 local catalog

Goal: Record independently reviewed and merged COM-C1 as complete, start COM-C2 only after the
owner's explicit instruction, and implement C2-01 without introducing runtime StoreKit authority
or formal commercial terms.

What was completed: Marked all three COM-C1 packets Done and COM-C2 In Progress at C2-01. Added the
accepted Monthly and Annual identifiers to one Xcode StoreKit Configuration fixture under
`Config/StoreKit/`, with a shared Pro group, equal service level, monthly/annual durations, Family
Sharing off, no Lifetime, and no offer or trial. The fixture is copied only into the test bundle.
A dedicated `MindBudget-StoreKit-Local` Debug scheme activates it but cannot Archive; the default
scheme and app resource phase remain clean. Added StoreKitTest/JSON coverage plus a same-code-path
static gate with positive and negative self-tests, wired that gate into ordinary validation and
CI, recorded DEC-COM-015, and added the bounded C2 execution packet. Synthetic local labels and
prices are explicitly test data rather than customer terms.

What was NOT completed: No App Store Connect product or subscription group was created. No app
target imports StoreKit, loads products, listens for transactions, derives or caches entitlement
authority, purchases, restores, shows a paywall, advertises price/trial/quota, changes schema,
opens network/cloud/provider paths, changes the app version, Archives, uploads, or distributes a
build. C2-02 has not started and remains outside this packet.

Validation result: pass under Xcode 26.6. The money, empty-egress, commercialization-document,
feature-access, StoreKit-catalog, and release-readiness gates passed. The Release build passed,
all 293 Swift tests in 19 suites passed, all 13 UI tests passed, and every selected core-service
coverage threshold remained above 85%. The focused StoreKit catalog suite passed all 3 tests.
The documented shared-host option skipped only the nondeterministic wall-clock assertion while
retaining the deterministic 10,000-row projection contract.

Next suggested task: Review C2-01 as one focused PR and merge only after owner approval. Begin
C2-02 only after that merge and a new explicit instruction.

## 2026-08-12 — Session 14 — Close C2-01 catalog-isolation review

Goal: Resolve PR #28's project-format, self-test, local-copy, and test-environment findings while
remaining inside the configuration-only C2-01 boundary.

What was completed: Reworked `check-storekit-test-catalog.sh` so its project isolation parser reads
balanced PBX objects instead of a single matching line. Same-code-path fixtures prove multiline
test-only placement passes and app-resource placement fails; scheme fixtures likewise prove the
default-scheme and Archive-capability guards. The catalog validator and Swift tests now require
exact local-test display names/disclaimers, fixed synthetic monthly/annual prices and billing
plans, and the CHN/`zh_CN` default environment. Updated DEC-COM-015, the C2 execution packet,
matrix, CI baseline, and project memory. Later runtime tests explicitly own a second non-CHN
storefront and controlled grace-period injection.

What was NOT completed: No formal commercial term was accepted. No runtime StoreKit catalog,
transaction authority, cache, purchase/restore, subscription status mapper, paywall, App Store
Connect product/group, schema, app-bundle resource, network/cloud/provider, version, Archive,
upload, tester, or distribution state changed. C2-02 remains out of scope.

Validation result: pass under Xcode 26.6. The StoreKit gate's internal positive/negative fixtures
and the real repository check passed. The focused catalog suite passed 3 tests. Full validation
passed every static gate, the Release build, 293 Swift tests in 19 suites, all 13 UI tests, and all
selected coverage thresholds. Only the documented nondeterministic wall-clock signal was skipped;
the deterministic 10,000-row projection contract remained active.

Next suggested task: Push the closeout to PR #28, confirm CI is green, and merge only after owner
approval. Start C2-02 only after merge and a new explicit instruction.

## 2026-08-12 — Session 15 — Extract and close the C2-01 StoreKit contract runner

Goal: Apply the final C2-01 maintainability recommendation without changing its accepted
configuration-only scope, then close the packet after owner-approved review.

What was completed: Moved the catalog JSON, PBX resource-isolation, and XML scheme contract into
the importable `Scripts/storekit_catalog_contract.py` module. The Shell gate is now a thin wrapper;
nine standard `unittest` cases cover accepted catalog/project/scheme fixtures plus Lifetime,
Family Sharing, customer-copy, app-resource, default-scheme, and Archive-capability rejections
through the same code paths used against the repository. Updated DEC-COM-015, the C2 execution
packet, CI baseline, project memory, and task status. C2-01 is Done after independent review and
full validation; C2-02 remains unstarted pending a fresh explicit owner instruction.

What was NOT completed: No runtime StoreKit catalog, product loading, transaction observation,
entitlement lifecycle/cache, purchase, restore, grace-state mapping, paywall, formal product,
customer price/trial/quota, schema, network/cloud/provider, version, Archive, upload, tester, or
distribution state changed.

Validation result: pass under Xcode 26.6. The extracted Python contract suite passed 9 tests. All
static gates passed. Full validation passed the Release build, 293 Swift tests in 19 suites, all
13 UI tests with zero failures, and every selected core-service coverage threshold. The documented
shared-host option skipped only the nondeterministic wall-clock assertion and retained the
deterministic 10,000-row projection contract.

Next suggested task: Begin C2-02 only after a fresh explicit owner instruction.

## 2026-08-12 — Session 16 — Implement COM-C2-02 runtime catalog and entitlement store

Goal: Implement the bounded C2-02 StoreKit runtime catalog and verified entitlement authority
without adding purchase, restore, paywall, persistence, formal customer terms, or distribution.

What was completed: Added a typed StoreKit catalog for the accepted Monthly and Annual product
identifiers, exact product-set/type/group/period validation, environment-plus-storefront keyed
presentation-only caching, and cache deletion through Delete All. Added a lock-backed shared
Free-by-default feature-access authority and an actor-isolated entitlement store that derives
authority only from verified `Transaction.currentEntitlements`, owns exactly one
`Transaction.updates` listener, treats listener updates only as a re-read signal, and fails closed
for mixed, unverified, unknown-product, or unknown-environment states. A reconciliation generation
prevents an older suspended read from overwriting newer authority. App UI and App Intents now read
the same live authority. Added focused catalog, concurrency, lifecycle, failure, cache, deletion,
and stale-read tests; expanded the StoreKit catalog contract suite and dedicated local scheme for
opt-in CHN/USA framework-backed product probes. Recorded DEC-COM-016 and updated the C2 packet,
requirements, network policy, matrix, project memory, and task status. C2-02 is implementation-
complete and awaiting focused owner review.

What was NOT completed: No purchase, restore, transaction finishing, subscription-status UI,
paywall, cached authority, StoreKit receipt persistence, formal App Store Connect product/group,
customer price/trial/quota, schema, cloud/provider channel, app-owned network domain, version,
Archive, upload, tester, or distribution state changed. StoreKit presentation cache is never
entitlement authority. The two framework-backed `Product.products(for:)` storefront probes were
not claimed as passed: command-line Xcode did not attach the Run-action StoreKit configuration to
the test process, and Xcode GUI 26.6 crashed in an unrelated `ActivityBarAccessory` assertion
before the dedicated scheme could run. They remain an explicit local-Xcode/focused-review item;
the default suite skips them honestly.

Validation result: pass under Xcode 26.6. All static gates, the Release build, 303 Swift tests in
20 suites, all 13 UI tests, and every selected core-service coverage threshold passed. The Python
StoreKit contract suite passed 11 tests. Focused runtime tests passed for exact-context catalog
fallback, cache deletion, malformed/partial rejection, startup and update reconciliation, one
listener under concurrent starts, whole Free/Pro snapshots, fail-closed authority, and stale-read
suppression. Only the documented nondeterministic wall-clock assertion was skipped; its
deterministic 10,000-row contract remained active.

Next suggested task: Open C2-02 as one focused PR. Mark it Done only after owner review, green CI,
and the remaining dedicated local-StoreKit evidence is either captured or explicitly accepted as
a bounded environment limitation.

## 2026-08-12 — Session 17 — Close C2-02 focused StoreKit review findings

Goal: Resolve PR #29's billing-grace candidate, framework-probe evidence, UI revocation-refresh,
and transaction-finishing review findings without beginning C2-03.

What was completed: Replaced the premature `expirationDate > now` authority filter with explicit
raw `isRevoked` and `expirationDate` facts. C2-02 still rejects revoked transactions, but an
unrevoked current-entitlement candidate with a past expiration now reaches the future C2-03 status
mapper instead of being discarded first. Added regressions for both directions and a direct
AppSession exact-Free -> Pro -> exact-Free test proving SwiftUI-facing premium snapshots refresh
without relaunch. Reverified the dedicated local StoreKit scheme under Xcode 26.6 RC build
`17F109` and iOS 26.5: both CHN/USA probes executed, but StoreKit configuration/storefront
synchronization failed with `SKInternalErrorDomain Code=3` and product loading returned empty.
A trial Launch-environment inheritance produced a false green by skipping the probes, so the
scheme was restored to its explicit Test-action opt-in and the catalog contract now rejects that
shape. Both probes executing and passing under a supported final Xcode GUI/toolchain are a hard
C2-03 entry gate. Updated the C2 packet, matrices, requirements, decisions, policies, project
memory, task status, and CI evidence accordingly.

What was NOT completed: No purchase, restore, subscription-status mapper, transaction `finish()`,
paywall, persistent authority, formal customer price/trial/quota, App Store Connect product,
schema, cloud/provider channel, app-owned network destination, version, Archive, upload, tester,
or distribution state changed. The failed framework probes are recorded as non-evidence rather
than reported as passing. C2-02 remains implementation-complete and awaiting focused owner review;
C2-03 has not started.

Validation result: pass under Xcode 26.6 with the documented shared-host wall-clock exclusion.
All static gates, the Release build, 306 selected Swift tests in 20 suites, all 13 UI tests, and
every selected coverage threshold passed. The StoreKit Python contract suite passed 12 tests; the
focused StoreRuntime suite passed all 11 tests. A separate strict local run completed all
functional and UI coverage but measured the known 10,000-row wall-clock signal at 0.830 seconds,
so the final shared-host run skipped only that nondeterministic 500 ms assertion while retaining
the deterministic 10,000-row projection contract.

Next suggested task: Push the focused remediation to PR #29, wait for green CI, and request owner
review. Mark C2-02 Done only after approval and merge; do not start C2-03 until its framework-probe
entry gate also passes.

## 2026-08-13 — Session 18 — Close C2-02 and recheck the C2-03 final-runtime gate

Goal: Close the independently reviewed and merged C2-02 packet, then recheck its outstanding
StoreKit product-loading entry gate without beginning C2-03 or manufacturing passing evidence.

What was completed: Recorded PR #29's green CI and merge as `a45d480`, so C2-02 is Done. Re-ran
the dedicated CHN/USA probes with final Xcode 26.6 build `17F113` on final iOS 26.4 and 26.5
runtimes. Both probes executed rather than skipped, but returned `SKInternalErrorDomain Code=3`
and empty product sets; `storekitd` diagnostics reported an Octane entitlement/development-install
handshake failure. Verified that final Xcode's iOS SDK is build `23F81a` and the installed iOS
26.5 runtime is build `23F77`. Apple's currently offered export was the older build `23F73`; it
was not imported and could not replace the installed runtime. The same dedicated code passed all
16 tests in 2 suites on an iOS 27 beta runtime, which isolates useful diagnostic information but does not
satisfy the supported-final-runtime gate. Synchronized project memory, the C2 packet, test matrix,
requirements, DEC-COM-016, CI evidence, and the main decision pointer while preserving the earlier
RC `17F109` failure as historical evidence.

Direct Apple download queries for build `23F81` and iOS `26.5.1` both returned unavailable. The
older exported `23F73` bundle was deleted from temporary storage without being imported; the
installed `23F77` runtime was preserved.

What was NOT completed: C2-03 did not start and remains Blocked. No purchase, restore,
subscription-status mapper, transaction `finish()`, paywall, formal App Store Connect product,
customer price/trial/quota, schema, network/provider channel, version, Archive, upload, tester, or
distribution state changed. Neither the final-runtime failures nor the beta-runtime success are
reported as an accepted storefront-probe pass.

Validation result: pass under final Xcode 26.6 build `17F113` with the documented shared-host
wall-clock exclusion. All static gates, the Release build, 306 selected Swift tests in 20 suites,
all 13 UI tests, and every selected coverage threshold passed. The StoreKit Python contract suite
passed all 12 tests. The closeout also passed `git diff --check`; this session changed no app
source.

Next suggested task: Resolve the Octane/development-install handshake on a supported final iOS
runtime and capture both CHN and USA product probes executing and passing. Only then may C2-03 be
marked In Progress.

## 2026-08-13 — Session 19 — Eliminate global toolchain selection as the probe cause

Goal: Verify the owner-completed machine-wide Xcode switch and restart, then determine whether the
C2-03 storefront gate could advance.

What was completed: Confirmed `xcode-select`, default `xcodebuild`, `xcrun`, and `simctl` all use
final Xcode 26.6 build `17F113`; first-launch setup is complete and simulator services are healthy.
The dedicated non-Archive scheme ran only `StoreKitTestCatalogTests` against iOS 26.5 build
`23F77`. All 5 tests executed: 3 deterministic catalog tests passed, while the CHN and USA
framework probes both executed rather than skipped and failed with `SKInternalErrorDomain Code=3`
and empty product sets. The pre-restart auxiliary `xcrun`/`simctl` lookup noise did not recur.

Decision/effect: Global toolchain inconsistency is closed as a cause. It did not resolve the
StoreKit Octane/runtime behavior, so the supported-final-runtime gate remains fail-closed and
C2-03 is not active. No gate was weakened and beta-runtime diagnostic success remains non-release
evidence only.

Evidence: `/private/tmp/MindBudget-C2-02-Restart-17F113-iOS26.5-23F77.xcresult` and
`/private/tmp/mindbudget-storekit-restart-17F113-ios265-23F77.log`.

What was NOT changed: No app source, purchase/restore/status/finish behavior, paywall, formal
product, customer term, schema, network/provider path, version, Archive, upload, tester, or
distribution state changed.

## 2026-08-13 — Session 20 — Pass the C2-03 runtime entry gate on a physical final iPhone

Goal: Run the committed CHN and USA StoreKit product probes on a supported final physical-device
surface, then open C2-03 only if both probes execute rather than skip and pass without weakening
the gate.

What was completed: After the owner unlocked the connected device, final Xcode 26.6 build
`17F113` ran `StoreKitTestCatalogTests` through the dedicated non-Archive
`MindBudget-StoreKit-Local` scheme on the physical `拉沙的iPhone` (`iPhone Air`) with final
iOS 26.6.1 build `23G82`. All 5 tests passed with 0 failed and 0 skipped. The CHN and USA
`Product.products(for:)` probes both executed and passed; neither produced an empty product set or
`SKInternalErrorDomain Code=3`. Independent `xcresulttool` parsing confirmed the physical arm64
device, OS/build, all five named tests, and the 5/0/0 totals. C2-03 is now In Progress. Historical
iOS 26.4/26.5 simulator failures and the iOS 27 beta diagnostic pass remain recorded and were not
rewritten as accepted evidence.

Evidence: `/private/tmp/MindBudget-C2-03-Physical-Unlocked-iOS26.6.1-17F113.xcresult`.

What was NOT changed: No C2-03 app source, purchase, restore, subscription-status mapping,
transaction `finish()`, paywall, formal product/customer term, schema, network/provider path,
version, Archive, upload, tester, or distribution state changed. The post-0.9.6 release hold and
all C2-04/later gates remain active.

Validation result: pass under final Xcode 26.6 `17F113` with the documented shared-host
wall-clock exclusion. Static money, network, commercialization, StoreKit-catalog, and release
gates passed; the Release build passed; 306 Swift tests in 20 suites and all 13 UI tests passed;
every selected coverage threshold remained above 85%; and `git diff --check` passed.

Next suggested task: Implement C2-03 as its own review unit: verified purchase/finish,
pending/cancel/error, user-triggered restore, and the subscribed/grace/retry/expired/revoked
status mapper. Do not begin C2-04, paywall, formal customer terms, or distribution work.

## 2026-08-13 — Session 21 — Complete the C2-03 implementation candidate for independent review

Goal: Implement only the accepted C2-03 StoreKit lifecycle boundary after its physical-device
entry gate passed, then stop before C2-04, purchase presentation, commercial terms, or release.

What was implemented: Kept one actor-owned `EntitlementStore` as the sole process-local authority.
The StoreKit adapter now supplies verified status transaction and renewal information alongside
ownership, accepted Product ID, environment, revocation, and expiration facts. The mapper grants
Pro only for subscribed and verified billing grace; billing retry, expired, revoked, unknown,
unverified, pending, mixed, and incomplete-free authority fail closed. Explicit typed purchase and
restore seams map success, pending, cancellation, verification failure, unavailable Product,
payments-not-allowed, no-active-subscription, and neutral operation failure. Restore alone calls
`AppStore.sync()` from a user-triggerable seam.

Transaction boundary: A verified handled purchase/update/unfinished transaction is combined with
a fresh current/status read, resolved, and published to the central access authority before
`Transaction.finish()`. Duplicate/concurrent delivery is serialized and deduplicated in process.
A failed finish is not reported as purchase success, is not added to the finished set, remains
unfinished in StoreKit, and may be retried on a later startup/update pass. Deterministic candidate
tests cover the state table, purchase/restore outcomes, publish-before-finish, duplicate delivery,
operation serialization, failed-finish retry, and unfinished startup processing; opt-in local
StoreKit probes cover Monthly/Annual seeded transaction verification and finish. A hosted unit
test cannot present the `Product.purchase()` confirmation sheet, so C3 owns that UI evidence. A
forced-renewal grace experiment terminated the hosted runner and was removed rather than retained
as unstable evidence; the deterministic state matrix remains the claimed mapper proof.

Evidence status: C2-03 implementation is complete and pending independent review. **Final focused
test totals, full validation totals, coverage, CI, and merge evidence are pending the owning run.**
The earlier physical 5/0/0 CHN/USA Product-loading pass remains entry evidence only and is not
reported as execution evidence for the new purchase/restore/finish paths. Historical simulator
`Code=3`/empty-product failures and the iOS 27 beta diagnostic pass remain unchanged in the matrix.

What was NOT implemented: No current view calls purchase or restore. There is no paywall, visible
Pro purchase/restore entry, formal App Store Connect product, customer price/trial/offer, C2-04
environment-isolation completion, schema, app-owned HTTP(S), version, Archive, upload, tester
assignment, or distribution change. The uploaded 0.9.6 binary and post-0.9.6 release hold remain
unchanged. C2-03 is not Done until independent review, full validation, green CI, and merge.

Next suggested task: Independently review and validate only the C2-03 candidate. Do not begin
C2-04 or C3 early.

## 2026-08-13 — Session 22 — Add subscription-status signals to the same C2-03 lifecycle task

Goal: Close the retry/expiry observation gap without adding another entitlement authority,
listener owner, UI, phase, or release permission.

What changed: The review-pending C2-03 candidate's single lifecycle task now supervises both
`Transaction.updates` and `Product.SubscriptionInfo.Status.updates`. A subscription-status signal
carries no grant or revocation decision; it triggers a fresh full current/status reconciliation
through the same actor-owned `EntitlementStore`. Transaction delivery, verified status mapping,
whole-snapshot publication, publish-before-finish, failed-finish retry, and typed purchase/restore
remain owned by that same authority.

Evidence status: This refines the implementation candidate only. Final focused-test totals, full
validation, coverage, CI, independent review, and merge evidence remain pending and are not
claimed by this entry.

What was NOT changed: No second authority or customer UI was introduced. No paywall, formal
product, price/trial/offer, C2-04 proof, app-owned HTTP(S), version, Archive, upload, tester,
distribution, or 0.9.6 state changed. C2-03 remains implementation complete and pending
independent review, not Done.

## 2026-08-13 — Session 23 — Complete local COM-C2-03 validation without advancing its review gate

Goal: Close the C2-03 local verification record after the final lifecycle/concurrency fixes while
keeping independent review, CI, merge, C2-04, customer UI, and distribution gates intact.

What was verified: Independent code and concurrency audits found no remaining P1/P2. The focused
lifecycle/runtime run passed 44/44 tests. The 31-test lifecycle suite then passed 10 consecutive
iterations (310/310), including restore provenance, conflicting same-transaction facts,
publish-before-finish, finish retry, crossgrade acknowledgement, status-only refresh, and
duplicate/concurrent delivery. The strict 500 ms local Dashboard wall-clock signal passed 10/10
isolated iterations. The final full run used the repository's documented shared-host switch to
exclude only that already-isolated wall-clock signal while retaining the deterministic 10,000-row
projection contract.

Full evidence: Release and build-for-testing passed. The default scheme completed 342 Swift tests
with zero failures (338 passed and 4 explicit opt-in StoreKit runtime probes skipped) plus all
13 UI tests. The combined xcresult reports 355 total, 351 passed, 4 skipped, and 0 failed. Every
selected core file remains above the 85% coverage gate: Money 91.73%, BudgetEngine 95.18%,
BudgetCycleCalculator 95.17%, SpendingPatternDetector 97.57%, ReminderThrottle 96.84%,
ReminderEngine 91.04%, AdviceSafetyValidator 96.15%, PrivacyRedactor 91.91%,
CycleSummaryService 97.45%, IntentClassifier 97.50%, CSVExporter 87.60%, and
CurrencyFormatterService 100.00%. Static money, network, commercialization-document,
feature-access, StoreKit-catalog, release-readiness, and diff gates passed. Evidence:
`/private/tmp/MindBudget-C203-Full-Final15.xcresult`.

What was NOT changed: The four dedicated runtime probes remain opt-in device/scheme evidence and
were not relabeled by the default-scheme run. Presented `Product.purchase()` and a stable real
grace transition remain later UI/runtime evidence. No view, paywall, formal product, price, trial,
offer, C2-04 environment gate, version, Archive, upload, tester assignment, app-owned HTTP(S), or
distribution state changed. C2-03 remains implementation complete and pending independent review,
green CI, and merge; it is not Done.

Next suggested task: Open C2-03 for independent review and CI. Do not begin C2-04 or C3 early.

## 2026-08-13 — Session 24 — Clarify C2-03 actionability and retain the restore lifecycle boundary

Goal: Address the first independent review's maintainability concern without deleting the
owner-approved restore path or changing StoreKit behavior.

What changed: Renamed `SubscriptionStatusResolution.isAuthoritative` to `isActionable` and fixed
its semantics in code and tests. The name now states what consumers require: the whole-snapshot
decision is safe to act on. It does not claim every supplemental Product/catalog input was
complete; a separately verified active subscription may remain actionable during catalog failure,
while incomplete Free and unverified inputs still fail closed. Added one consolidated invariant
block beside the actor's coordination state, documenting reconciliation-generation ordering,
single active-batch acknowledgement ownership, restore-provenance sequencing, waiter completion,
and the deterministic publish/finish/sync/batch-wait test seams.

Review disposition: Kept the post-`AppStore.sync()` transaction bridge. C2-03's accepted packet
explicitly owns purchase, restore, and status mapping; C2-04 owns environment isolation. A restored
verified transaction may arrive before `currentEntitlements` catches up, so deleting the bridge
would defer a timing-dependent defect to C3. The retained mechanism accepts only a completed
verified transaction signal, rejects ordinary status/foreground publications as restore evidence,
and cannot reuse a subscribed signal rejected by newer revocation authority. Existing tests open
those exact sync and finish windows with injected gates; the 10 repeated lifecycle iterations are
additional stability evidence rather than the sole concurrency proof.

What was NOT changed: No state-machine behavior, entitlement rule, current View, paywall, formal
product/price/trial, C2-04/C3 scope, version, Archive, upload, tester, or distribution state
changed. C2-03 remains implementation complete pending re-review, green CI, and merge.

Validation result: The renamed focused lifecycle/runtime surface passed 45/45 tests. Money,
network-egress, commercialization-document, StoreKit-catalog/environment-isolation, and diff
gates passed. The earlier owning full-validation evidence remains valid because this review fix
changes naming, comments, tests, and durable documentation without changing runtime behavior.

## 2026-08-13 — Session 25 — Make the C2-03 concurrency and StoreKit evidence traceable

Goal: Answer the second independent review by locating the deterministic concurrency gates and
making the StoreKit verification-derivation evidence boundary explicit.

What changed: The actor invariant comment now points directly to `StoreLifecycleDomainTests` for
the publish, finish, sync, and active-batch wait gates, and to `StoreRuntimeTests` for the separate
out-of-order whole-read seam. The test matrix records that the former contains 31 tests and the
latter 14, matching the focused 45/45 result. It also names representative opt-in Monthly/Annual
tests as the only flows that enter `verifiedRecord(from:status:)` with real StoreKit transaction,
status, and renewal objects.

Evidence boundary: Pure mapper tests start from app-owned `hasVerifiedStatusTransaction` and
`hasVerifiedRenewalInfo` facts. They prove fail-closed policy consumption, not the StoreKit-to-fact
derivation. Default-scheme coverage must not be cited as proof of that private framework bridge,
and real malformed-status/deferred-crossgrade correlation remains a controlled runtime
obligation. The earlier five-test physical entry run covered catalog loading only and was not
reclassified as C2-03 lifecycle evidence.

What was NOT changed: No production state-machine behavior, entitlement rule, customer UI,
paywall, product/price/trial, phase, version, Archive, upload, tester, or distribution state
changed. C2-03 remains implementation complete pending re-review, green CI, and merge.

## 2026-08-13 — Session 26 — Close C2-03 and begin the C2-04 environment gate

Goal: Record the reviewed C2-03 merge before beginning only the next accepted COM-C2 packet.

C2-03 closeout: PR #30 passed independent review and the complete GitHub Actions validation, then
merged to `main` as `3fc72b4` on 2026-08-13. The CI run completed green in 14m26s:
<https://github.com/xdgf558/MindBudget/actions/runs/31675470258>. C2-03 is Done.

C2-04 implementation: Added one separately verified app-environment authority based on
`AppTransaction.shared`. The verified app bundle and Xcode/Sandbox/Production environment must
match every transaction/status fact in a whole entitlement read. TestFlight is treated as Apple's
Sandbox environment rather than a fourth or manually relabeled Production environment. Missing,
unknown, wrong-bundle, or cross-environment authority fails closed. Catalog presentation remains
cached only by exact environment plus storefront; catalog-only failure still cannot erase an
independently verified active entitlement. Static validation keeps the app-transaction reader and
authority-read construction inside their Commerce owners.

Evidence: Production/test compilation and every static gate passed. The focused
`StoreRuntimeTests` plus `StoreLifecycleDomainTests` run passed 48/48 on iOS 26.5 with final Xcode
26.6 `17F113`. The strict Phase 10 suite passed 20/20 across 10 isolated iterations. The owning
shared-host run then completed 345 Swift tests (341 passed and 4 explicit StoreKit runtime probes
skipped), all 13 UI tests, and the complete coverage gate; combined result: 358 total, 354 passed,
4 skipped, 0 failed. Evidence: `/private/tmp/MindBudget-C204-WallClockSuite-10x.xcresult` and
`/private/tmp/MindBudget-C204-Full-Shared.xcresult`. An initial unsplit run measured the
nondeterministic wall-clock signal at 0.814 seconds and then hit Xcode's 600-second diagnostics
timeout; it is recorded but not used as passing evidence. C2-04 is implementation complete
pending independent review, green CI, and merge, not Done.

What was NOT changed: No current View calls purchase or restore. No paywall, customer UI, formal
App Store Connect product, price, trial, offer, version, Archive/upload, tester assignment,
app-owned HTTP(S), C3 work, or distribution state changed. The post-0.9.6 release hold remains.

## 2026-08-13 — Session 27 — Close the C2-04 purchase-preflight self-selection gap

Goal: Resolve the first independent review of PR #31 while keeping C2-04 implementation complete
and awaiting re-review rather than starting a later packet.

What changed: Purchase-result preflight now obtains the app environment through the separately
verified Commerce `AppTransaction` authority. It no longer assigns the transaction's own
environment to the app side of the comparison. A deterministic regression supplies a Sandbox
transaction with independently verified Production app authority and proves exact Free remains,
the result is `invalidStoreState`, and the transaction is not finished. The `Unknown` catalog
context is now explicitly documented as presentation-only metadata partitioning; entitlement
reads, purchase preflight, and access decisions never accept it.

Evidence boundary and validation: The matrix now includes `hasVerifiedAppBundle` alongside the
status-transaction and renewal-info projection flags, and states that pure tests prove their
consumption rather than StoreKit's private derivation. Focused lifecycle/runtime tests passed
49/49. The strict Phase 10 signal passed 10/10 isolated iterations. The clean shared-host run
completed 346 Swift tests (342 passed, 4 opt-in runtime probes skipped), 13/13 UI tests, and every
coverage threshold: 359 total, 355 passed, 4 skipped, 0 failed. Evidence:
`/private/tmp/MindBudget-C204-ReviewFix-Focused.xcresult`,
`/private/tmp/MindBudget-C204-ReviewFix-WallClockSuite-10x.xcresult`, and
`/private/tmp/MindBudget-C204-ReviewFix-Full-Shared-Retry.xcresult`.

What was NOT changed: No purchase/restore UI, paywall, formal App Store Connect product,
price/trial/offer, version, Archive/upload, tester assignment, app-owned HTTP(S), C3 work, or
distribution action was added. C2-04 remains implementation complete pending independent
re-review, green CI, and merge; the release hold remains active.

## 2026-08-13 — Session 28 — Close C2-04 and the COM-C2 StoreKit phase

Goal: Close the final COM-C2 packet after independent review, green CI, and merge while preserving
the later commercial-input and release gates.

Accepted evidence: PR #31 passed independent review and GitHub Actions run
<https://github.com/xdgf558/MindBudget/actions/runs/31701374466>, then merged to `main` as
`a293762` on 2026-08-13. Its owning local evidence remains 49/49 focused tests, 20/20 strict
Phase 10 executions across 10 iterations, and 359 full-validation results: 355 passed, 4 explicit
opt-in StoreKit runtime probes skipped, and 0 failed. The selected coverage, money, network,
commercialization-document, StoreKit-catalog, feature-access-boundary, and release gates passed.

Durable result: C2-04 and COM-C2 are Done. The verified `AppTransaction` bundle/environment is
the independent whole-read authority; Xcode, Sandbox/TestFlight, and Production facts remain
isolated; presentation-only `Unknown` cannot grant access; catalog-only failure cannot erase a
separately verified active subscription. The C2-03 lifecycle authority and typed purchase/restore
seams remain programmatic only and no current View invokes them.

Next boundary: No implementation packet is active. COM-C3 remains blocked until accepted
price/trial inputs and a new explicit owner instruction. Formal App Store Connect products,
paywall/customer purchase presentation, customer-visible restore/manage-subscription paths,
versioning, Archive/upload, tester assignment, and distribution remain outside this closeout.

What was NOT changed: No Swift source, test behavior, schema, product identifier, network
destination, formal commercial term, release artifact, or user entitlement changed. The uploaded
0.9.6 binary and post-0.9.6 distribution hold remain unchanged.

Closeout verification: The money, network-egress, commercialization-document, and StoreKit
catalog commands passed again. The full `Scripts/validate.sh` flow passed with the documented
shared-host wall-clock exclusion: 359 total results, 355 passed, 4 explicit opt-in StoreKit
runtime probes skipped, and 0 failed. Every selected core-service coverage threshold remained at
or above 85%. Result bundle: `/private/tmp/MindBudget-C204-Closeout.xcresult`.

## 2026-08-14 — Session 29 — Tighten the COM-C2 completion assertions before COM-C3

Goal: Make the two intentionally shortened PR #32 documentation checks retain their full release
and completion meaning before any later commercial packet starts.

What changed: `check-commercialization-docs.sh` now requires `post-0.9.6 release hold remains
active` and `C2-04 and COM-C2 are Done` instead of accepting their broad prefixes. The CI baseline
keeps the completed-phase phrase contiguous. The existing StoreKit matrix already states that the
three `hasVerified*` facts have unit-tested consumption but opt-in framework-backed derivation, so
no duplicate coverage note was added.

What was NOT changed: This maintenance work changes no accepted price/trial input, phase state,
app behavior, formal product, StoreKit authority, network policy, release hold, or distribution.

## 2026-08-14 — Session 30 — Implement the C3-01 test paywall contract and voluntary UI

Goal: Enter only C3-01 after the owner accepted provisional, nonpublic test inputs of USD 1.99
monthly, USD 19.99 annually, one 7-day free trial per product, and initial HKG/USA/SGP/TWN
storefront coverage.

Implementation: Added a bilingual Pro presentation reached only from Settings or an explicit Pro
value trigger, with no automatic presentation. The screen lists only current Pro capabilities,
uses StoreKit-localized prices and freshly evaluated introductory-offer eligibility, explains
renewal terms, links local Terms and Privacy, and exposes explicit purchase, restore, and
manage-subscription controls through the existing single lifecycle authority. Stale cached or
unavailable catalog state disables purchase. The StoreKit Configuration, static validator, and
test vocabulary now enforce the two accepted product IDs, P1M/P1Y periods, one P1W free trial per
product, the provisional USD prices, and the four storefront probes.

Evidence: Final Xcode 26.6 `17F113` ran `MindBudget-StoreKit-Local` on the physical
`拉沙的iPhone` (`iPhone Air`) with final iOS 26.6.1 `23G82`: 9 passed, 0 failed, 0 skipped,
including HKG/USA/SGP/TWN runtime catalog probes and Monthly/Annual verified transaction,
publication, and finish. The strict Phase 10 suite passed 20/20 across 10 isolated iterations.
The owning full shared-host validation passed 364 total results: 358 passed, 6 explicit opt-in
StoreKit runtime probes skipped, and 0 failed; all 14 UI tests and every selected coverage gate
passed. The Python StoreKit catalog contract passed 13/13 and all standalone COM gates pass.
Evidence: `/private/tmp/MindBudget-C301-Storefronts-Physical.xcresult`,
`/private/tmp/MindBudget-C301-Phase10-10x.xcresult`, and
`/private/tmp/MindBudget-C301-Full-Shared.xcresult`.

Current state: C3-01 is implementation complete pending independent review, hosted green CI, and
merge; it is not Done. C3-02 and all later commercial packets remain blocked.

What was NOT changed: No formal App Store Connect product or public commercial term was created.
No automatic paywall, receipt import, schema, version, Archive, upload, tester assignment,
app-owned HTTP(S), or distribution action changed. The post-0.9.6 release hold remains active.

## 2026-08-14 — Session 31 — Close the first C3-01 purchase-safety review findings

Goal: Resolve the independent review findings without promoting provisional trial terms into
production authority or advancing C3-01 past review.

What changed: Removed exact P1W offer requirements from the production catalog and entitlement
contract. The local `.storekit` fixture, Python validator, and opt-in probes still require the
owner-approved seven-day test offer, while production treats any valid StoreKit introductory offer
as optional presentation data and renders its actual duration only after fresh eligibility. A
live catalog no longer permits purchase when subscription authority is unavailable: the Pro View
pauses purchase and offers an explicit recheck, and `EntitlementStore.purchase` independently
performs a fresh actionable-authority preflight before calling the source. Renewal disclosure now
selects and formats strings with the SwiftUI app locale rather than `Locale.current` or a global
`NSLocalizedString` lookup. Bilingual copy, the static StoreKit boundary, catalog tests, lifecycle
tests, decisions, matrices, requirements, and memory were updated to preserve these distinctions.

Evidence: The focused Store runtime/lifecycle run passed 53/53. The owning full validation passed
366 total results: 360 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed;
all 14 UI tests and every selected coverage gate passed. The StoreKit Python contract passed
13/13, and the standalone money, network, commercialization-document, feature-access, release,
localization, and diff gates pass. Evidence:
`/private/tmp/MindBudget-C301-ReviewFix-Focused.xcresult` and
`/private/tmp/MindBudget-C301-ReviewFix-Full.xcresult`.

Current state: C3-01 remains implementation complete pending independent re-review, hosted green
CI, and merge. C3-02 and every later packet remain blocked.

What was NOT changed: No formal App Store Connect product, public price/trial/offer, automatic
presentation, schema, app-owned HTTP(S), version, Archive, upload, tester assignment, or
distribution action was added. The post-0.9.6 release hold remains active.

## 2026-08-14 — Session 32 — Fail closed for unsupported paid introductory offers

Goal: Resolve the second C3-01 review finding without silently presenting a paid introductory
offer as an ordinary subscription or broadening the accepted nonpublic seven-day free-trial test
contract.

What changed: The StoreKit presentation model now retains the introductory offer's localized
`displayPrice` and complete payment-mode raw value. C3-01 continues to support only eligible free
trials. Eligible `.payAsYouGo`, `.payUpFront`, or future unknown modes pause purchase and show an
explicit bilingual explanation; the Pro View and the concrete StoreKit source enforce the same
policy independently before any purchase sheet can be requested. Ineligible paid offers still
permit the ordinary subscription. Introductory-offer shape remains optional presentation input
and never enters paid-entitlement authorization. Added direct installment, upfront, ineligible,
and unknown-mode regressions and strengthened the static StoreKit boundary.

Evidence: The full shared-host validation used the documented exclusion for only the separately
proven local wall-clock signal and passed 369 total results: 363 passed, 6 explicit opt-in StoreKit
runtime probes skipped, and 0 failed. All 14 UI tests and every selected coverage gate passed. The
13-test Python StoreKit contract and all standalone release, money, network, commercialization-
document, feature-access, localization, StoreKit-isolation, and diff gates pass. Evidence:
`/private/tmp/MindBudget-C301-PaidOffer-ReviewFix-Full.xcresult`.

Current state: C3-01 remains implementation complete pending independent re-review, hosted green
CI, and merge. C3-02 and every later commercial packet remain blocked.

What was NOT changed: No formal App Store Connect product, public price/trial/offer, automatic
presentation, entitlement rule, schema, app-owned HTTP(S), version, Archive, upload, tester
assignment, or distribution action changed. The post-0.9.6 release hold remains active.

## 2026-08-14 — Session 33 — Implement C3-02 verified trial lifecycle and renewal reminder

Goal: Implement only C3-02 after C3-01 merged, without treating the configured seven-day test
offer as lifecycle authority or advancing signed configuration, formal economics, or release.

What changed: Added a process-local `TrialLifecycleProjection` derived only from an accepted
verified current introductory-free-trial transaction and separately verified renewal facts. The
projection carries Apple's actual renewal date and auto-renew state; no trial length or paid right
is persisted. A single actor reconciles one stable generic local-notification request at calendar
T−5, removes or replaces it on every lifecycle change, never requests permission, and falls back
to a noninterrupting in-app card when notifications or a reliable future trigger are unavailable.
The reminder copy carries no date, price, amount, product, or remaining-day count. The in-app
renewal disclosure combines the verified date only with a current live StoreKit display price;
cached or unavailable price is omitted. App launch, foreground, locale, notification-preference,
and entitlement changes all reconcile through the same scheduler. Added bilingual UI/copy,
deterministic calendar/DST/authorization/replacement/failure tests, production StoreKit derivation
assertions for the opt-in Monthly/Annual paths, and static StoreKit/feature/document gates. The
framework bridge intentionally reads `Transaction.offer` for the current paid period; a nil
`RenewalInfo.offer` does not erase a one-period free trial because it describes the next renewal.

Evidence: The final focused entitlement/lifecycle/runtime run passed 68/68; the dedicated trial
suite passed 12/12. Full validation passed 381 total results: 375 passed, 6 explicit opt-in
StoreKit runtime probes skipped, and 0 failed. All 14 UI tests, Release build, static gates, and
every selected coverage threshold passed. Evidence:
`/private/tmp/MindBudget-C302-Focused.xcresult` and
`/private/tmp/MindBudget-C302-Full-Final2.xcresult`. The final physical iPhone Air/iOS 26.6.1
StoreKit suite passed 9/9 with no failure or skip, including all four storefronts and both
Monthly/Annual trial-lifecycle derivation paths; evidence:
`/private/tmp/MindBudget-C302-Physical4.xcresult`. The first completed physical run exposed an
old cross-storefront test defect: it fixed the localized free-trial zero price to the USA literal.
The runtime test now verifies the P1W/free-trial structure and nonempty StoreKit-localized price,
while the isolated fixture validator remains the owner of the exact provisional USD literal.

Current state: C3-02 is implementation complete pending independent review, hosted green CI, and
merge; it is not Done. C3-03 and C3-04 remain blocked.

What was NOT changed: No signed public configuration, formal App Store Connect product, final
price/trial term, automatic paywall, receipt import, schema, app-owned HTTP(S), version, Archive,
upload, tester assignment, or distribution action was added. The uploaded 0.9.6 build and
post-0.9.6 release hold remain unchanged.

## 2026-08-14 — Session 34 — Correct C3-02 renewal-plan disclosure and state-safe reminder copy

Goal: Resolve the independent C3-02 review findings without broadening entitlement authority or
advancing C3-03.

What changed: `TrialLifecycleProjection` now preserves the verified product carrying the current
trial separately from the verified next-renewal product. A recognized nonnil
`autoRenewPreference` selects the renewal product; absence falls back to the current product, and
an unknown explicit preference produces no lifecycle projection. Renewal price lookup follows the
next-renewal product, so a same-date plan switch changes the projection and disclosure. Pending
English and Simplified-Chinese notification copy now says the trial ends soon and asks the person
to review current status; it no longer promises renewal after the app can be terminated while a
person changes auto-renew externally. Static StoreKit/document gates and durable decisions,
requirements, matrix, memory, and changelog were aligned.

Evidence: The dedicated review-remediation trial suite passed 13/13. Full validation produced 382
results: 376 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed. All 14 UI
tests, the Release build, static gates, and selected coverage thresholds passed. Evidence:
`/private/tmp/MindBudget-C302-ReviewFix-Trial2.xcresult` and
`/private/tmp/MindBudget-C302-ReviewFix-Full.xcresult`. The preceding PR head `71d7f54` had green
hosted run `31800476681`; the review-fix commit still requires its own hosted green run.

Current state: C3-02 remains implementation complete pending independent re-review, hosted green
CI, and merge; it is not Done. C3-03 and C3-04 remain blocked.

What was NOT changed: No signed public configuration, formal product or final economics,
automatic paywall, schema, app-owned HTTP(S), version, Archive, upload, tester assignment, or
distribution action changed. The uploaded 0.9.6 build and post-0.9.6 release hold remain unchanged.

## 2026-08-14 — Session 35 — Close C3-02 after reviewed merge and green CI

Goal: Record the accepted C3-02 merge as Done without beginning C3-03 or changing distribution.

What changed: Current commercialization tasks, both project memories, the C3 execution packet,
requirements index, StoreKit matrix, network policy, CI baseline, and decision records now agree
that PR #34 passed independent review and green GitHub Actions run `31803898776`, then merged to
`main` as `12d9217` on 2026-08-14. C3-02 is Done. C3-03 has not started and remains blocked until
the owner explicitly authorizes it and accepts the exact first-party signed-configuration
contract. The commercialization document gate now requires the C3-02 Done status, green run, and
merge SHA and rejects stale current-state wording that still describes C3-02 as pending review.

Evidence: Documentation-closeout validation produced 382 results: 376 passed, 6 explicit opt-in
StoreKit runtime probes skipped, and 0 failed. All 14 UI tests, the Release build, static gates,
and selected coverage thresholds passed. Evidence:
`/private/tmp/MindBudget-C302-Closeout-Full.xcresult`. The previously accepted physical final-
device C3-02 suite remains 9/9 with no failure or skip.

Current state: C3-01 and C3-02 are Done. C3-03 and C3-04 remain blocked. No C3-03 source packet is
active.

What was NOT changed: No Swift/product behavior, signed public configuration, formal App Store
Connect product, final economics, automatic paywall, schema, app-owned HTTP(S), version, Archive,
upload, tester assignment, or distribution action changed. The uploaded 0.9.6 build and post-
0.9.6 release hold remain unchanged.

## 2026-08-14 — Session 36 — Implement the C3-03A signed public-configuration core

Goal: Enter C3-03 under the owner's recommended exact contract, while keeping transport,
application integration, and every later commercialization/release gate out of the first packet.

What changed: Accepted DEC-COM-021 and split C3-03 into two review packets. C3-03A adds a strict
Ed25519 verifier over exact decoded payload bytes; exact envelope, payload, and nested field sets;
schema/version/time/size bounds; a closed presentation vocabulary containing only
`proValueTriggersEnabled`; rollback and same-version-equivocation rejection; and an atomic,
file-protected signed cache whose bytes must read back before presentation is published. Invalid
signature/key/schema/encoding/time/size, corrupt rollback state, or persistence failure resolves
to a verified nonexpired cache and then the conservative built-in `false`. A new static contract
gate runs locally and in CI. Durable tasks, requirements, decisions, network/privacy boundaries,
and both project memories record the accepted future exact hosts and anonymous GET contract while
keeping C3-03B blocked.

Evidence: The final focused configuration suite passed 8/8. The owning full validation produced
390 results: 384 passed, 6 explicit opt-in StoreKit runtime probes skipped, and 0 failed. All 14
UI tests, the Release build, static gates, and every selected coverage threshold passed. The
strict local Dashboard performance suite separately passed 10/10 isolated iterations after one
shared-host integrated measurement reached 0.822698 seconds. Evidence:
`/private/tmp/MindBudget-C303A-Focused3.xcresult`,
`/private/tmp/MindBudget-C303A-Full-Final.xcresult`, and
`/private/tmp/MindBudget-C303A-StrictPerformance.xcresult`.

Current state: C3-03A is implementation complete pending independent review, hosted green CI,
and merge; it is not Done. C3-03B and C3-04 remain blocked.

What was NOT changed: No URL, network adapter/request, Production public key, Worker deployment,
application consumer, entitlement/StoreKit authority, user-visible behavior, formal product or
economics, schema, version, Archive/upload, tester assignment, or distribution action was added.
The Release app-owned HTTP(S) allow-list remains empty and the post-0.9.6 release hold remains
active.

## 2026-08-15 — Session 37 — Close the first C3-03A review findings without opening transport

Goal: Harden the local signed-configuration core after independent review while keeping C3-03B,
application integration, and distribution blocked.

What changed: The rollback/high-water record now has an explicit sticky Release failure contract:
corruption cannot be overwritten or reset by normal Delete All, Offload, or later remote bytes;
current recovery is full app-data deletion and reinstall. Persistence witnesses are explicitly
async. Acceptance is serialized across every persistence suspension and re-reads/re-verifies the
exact snapshot through the protocol before publishing `.remote`. The signed payload contract uses
exact UTC whole seconds and rejects duplicate JSON keys before Foundation can collapse them. A
encoder-independent fixed Ed25519 vector, deterministic concurrent-version inversion, no-op write,
malformed record, zero-validity, duplicate-key, and fractional-timestamp tests were added.

Accepted/non-adopted review guidance: Exact payload bytes remain the signing authority; the client
does not re-encode canonical JSON or require sorted keys. C3-03A has no deployed signer, so real
Worker-produced bytes remain a C3-03B gate. No `os_log` or analytics sink is added before that
operations boundary; C3-03B must add closed reason codes without payload/signature/content. The
controller name and fixed security-policy constants remain unchanged because their current scope
is accurate and no multi-policy requirement exists.

Evidence: Expanded focused validation passed 12/12 at
`/private/tmp/MindBudget-C303A-ReviewFix-Focused.xcresult`. The public-configuration,
commercialization-document, network-egress, shell-syntax, and diff gates pass. Final owning full
validation produced 394 results: 388 passed, 6 explicit opt-in StoreKit runtime probes skipped,
and 0 failed. All 14 UI tests, the Release build, every selected coverage threshold, and the
complete static gate set passed. Evidence:
`/private/tmp/MindBudget-C303A-ReviewFix-Full3.xcresult`. Fresh hosted CI remains pending.

Current state: C3-03A remains implementation complete pending independent re-review, hosted green
CI, and merge; it is not Done. C3-03B/C3-04 and distribution remain blocked.

What was NOT changed: No URL, request, Release egress, Production key, Worker deployment, app
consumer, paid authority, StoreKit behavior, schema, user-facing copy, version, Archive/upload,
tester assignment, or distribution action changed. The post-0.9.6 release hold remains active.

## 2026-08-15 — Session 38 — Close C3-03A and open the C3-03B execution gate

Goal: Close the reviewed verifier/cache packet with exact hosted and merge evidence, then activate
only the accepted fixed transport/presentation packet.

What changed: The C3-03A review-remediation head `3a53107` passed independent review and green
GitHub Actions run `31856271268`. PR #36 merged it to `main` as `1ebb36c` on 2026-08-15. Durable
COM task, memory, requirement, decision, network, CI, contract, and execution-packet state now
marks C3-03A Done and C3-03B In Progress. The C3-03B packet remains limited to the exact
environment host, anonymous `GET /v1/config`, Production-key provenance, closed non-content reason
codes, real Worker/privacy/log/TTL/redirect inspection, captured traffic, final-binary proof, and
the single verified presentation consumer.

Evidence: The closeout branch repeated the full validation with 394 results: 388 passed, 6
explicit opt-in StoreKit runtime probes skipped, and 0 failed. All 14 UI tests, the Release build,
the complete static gate set, and every selected coverage threshold passed. Evidence:
`/private/tmp/MindBudget-C303A-Closeout-Full.xcresult`. GitHub Actions run `31856271268` then
completed successfully before merge `1ebb36c`.

Current state: C3-03A is Done. C3-03B is In Progress. C3-04 and distribution remain blocked.

What was NOT changed: No C3-03B source, URL, network request, allow-list exception, Production
key, Worker deployment, reason-code sink, presentation consumer, paid authority, StoreKit change,
schema, user-facing copy, version, Archive/upload, tester assignment, or distribution action was
added by this closeout. The Release app-owned HTTP(S) allow-list remains empty and the post-0.9.6
release hold remains active.

## 2026-08-15 — Session 39 — Implement and verify the fixed C3-03B configuration path

Goal: Implement only the owner-accepted first-party signed configuration transport and optional
presentation consumer after C3-03A merged, while keeping Production deployment and distribution
closed.

What changed: Added one exact Development/Staging/Production URL vocabulary and a centralized
anonymous GET adapter with bounded metadata, ephemeral no-cookie/no-credential/no-cache transport,
redirect rejection, timeout/cancellation, exact response URL/status/MIME, and 16 KiB streaming
bound. Embedded only the `mb-config-2026-01` Ed25519 public key. Cache and remote acceptance emit
closed non-content reason codes; payload, signature, metadata values, IP addresses, and user or
financial content are never logged. The app resolves cache then refreshes at launch/foreground and
uses the verified flag only for an optional AI Pro-value trigger when the person is not already
Pro. Permanent Settings, Restore, Manage Subscription, subscription status, and StoreKit rights
remain independent.

Worker/key operations: Added an independent Cloudflare Worker, exact request validator,
environment-specific rate-limit namespaces, `no-store`/security headers, disabled observability,
and no private key, storage, analytics binding, cookie, CORS, outbound fetch, or app request log.
The private key remains in an owner-controlled protected file outside the repository. Only
Development version `bf6c5049-a389-4ea7-af0a-e8425b8957e2` was deployed. Staging and Production
were not deployed. Live traffic confirmed the 387-byte signed response and conservative empty-body
400/404 rejection behavior; Cloudflare's ordinary injected edge metadata is recorded for final
privacy/traffic review.

Evidence: The real Development Worker passed the dedicated non-Archive app suite 8/8 with no skip
at `/private/tmp/MindBudget-C303B-LiveWorkerFinal.xcresult`. Worker tests passed 13/13; typecheck,
zero-vulnerability high-severity audit, and Production-config dry-run passed. The owning shared-
host full validation produced 402 results: 395 passed, 7 explicit skips, and 0 failed, including
14/14 UI tests, Release build, all static gates, and every selected coverage threshold. Evidence:
`/private/tmp/MindBudget-C303B-Full-Final.xcresult`. One shared-load 0.850044833-second performance
measurement is retained only as nonpassing diagnostic evidence; the isolated signal passed 10/10
at `/private/tmp/MindBudget-C303B-StrictPerformance.xcresult`.

Current state: C3-03B is implementation complete pending independent review and green hosted CI;
it is not Done. C3-04 remains blocked.

What was NOT changed: No schema/payload expansion, entitlement/StoreKit authority, product/price/
trial, notification, user-content upload, telemetry, Staging/Production deployment, formal
economics/product, version, Archive/upload, tester assignment, or distribution action changed.
The post-0.9.6 release hold remains active.

## 2026-08-15 — Session 40 — Remediate C3-03B runtime lifecycle review findings

Goal: Close the PR #38 findings for in-flight expiry, continuous-foreground expiry, unavailable
StoreKit authority, and detached refresh cancellation while keeping C3-03B within DEC-COM-022.

What changed: The transport service samples the verification clock after response completion and
propagates structured cancellation through network and acceptance tasks. Signed expiry is carried
through every verified resolution and independently scheduled by AppSession, so an enabled
presentation becomes conservative exactly at expiry without another refresh. Presentation of the
optional value trigger additionally requires actionable exact-Free StoreKit authority; an empty
fail-closed entitlement set produced by incomplete/unverified authority is not treated as Free.
Static contract gates now require these runtime and regression seams.

Evidence: Generic simulator test build succeeded. The focused transport/configuration suite passed
11/11, zero failure/skip, at
`/private/tmp/MindBudget-C303B-ReviewFix-Focused.xcresult`. Source contract, transport/Worker,
network-egress, commercialization-document, shell-syntax, and diff checks pass. The final owning
validation, with the shared-load wall-clock signal separated as designed, produced 405 results:
398 passed, 7 explicit opt-in/runtime skips, and 0 failed. The Release build, 14/14 UI tests, all
static gates, and every selected coverage threshold passed at
`/private/tmp/MindBudget-C303B-ReviewFix-FullFinal.xcresult`. The strict local Dashboard signal
separately passed 10/10 isolated iterations at
`/private/tmp/MindBudget-C303B-ReviewFix-StrictPerformance.xcresult`; the preceding shared-load
0.838828417-second miss remains diagnostic-only at
`/private/tmp/MindBudget-C303B-ReviewFix-Full.xcresult`. Hosted CI remains pending.

Current state: C3-03B remains implementation complete pending independent re-review and green
hosted CI; it is not Done. C3-04 remains blocked.

What was NOT changed: No signed vocabulary, paid right, StoreKit fact, product/price/trial,
notification, Worker response/deployment, Staging/Production deployment, content/identifier,
telemetry, version, Archive/upload, tester assignment, or distribution action changed. The
post-0.9.6 release hold remains active.

## 2026-08-15 — Session 42 — Close C3-03B and C3-03 after review, green CI, and merge

Goal: Close the reviewed C3-03B implementation and parent C3-03 packet durably after the exact
follow-up head passed hosted CI and merged, without implicitly starting C3-04 or opening a release
gate.

What changed: Current-state tasks, packet status, requirements, decision pointers, network policy,
public-configuration contract, project memory, and documentation gates now record C3-03A and
C3-03B as Done. The reviewed C3-03B head was `09c382e`; GitHub Actions run `31873664396` completed
successfully; PR #38 merged to `main` as `db7926d`. C3-04 is ready but not started and still requires
an explicit owner instruction.

Evidence: The post-merge CI-style validation produced 410 results: 403 passed, 7 explicit
opt-in/runtime skips, and 0 failed. All 396 unit tests and 14/14 UI tests passed with the Release
build, all static gates, and every selected coverage threshold at
`/private/tmp/MindBudget-C303B-Closeout-FullGreen.xcresult`. A shared-load-only 0.83718875-second
Dashboard wall-clock miss remains diagnostic evidence at
`/private/tmp/MindBudget-C303B-Closeout-Full.xcresult`; the same signal passed 10/10 isolated
iterations at `/private/tmp/MindBudget-C303B-Closeout-StrictPerformance.xcresult`.

Current state: C3-03B and C3-03 are Done. C3-04 is ready but not started pending explicit owner
instruction. Staging and Production remain undeployed, and Development remains the only deployed
signed public-configuration Worker environment.

What was NOT changed: No Swift/runtime behavior, Worker source or deployment, signed payload,
entitlement/StoreKit authority, product/price/trial, notification, user content, telemetry,
Production traffic, privacy approval, version, Archive/upload, tester assignment, or distribution
action changed. The post-0.9.6 release hold remains active.

## 2026-08-15 — Session 41 — Close remaining C3-03B cancellation boundaries

Goal: Resolve the second PR #38 cancellation review without expanding DEC-COM-022 or opening any
later commercialization/release gate.

What changed: Startup refresh is now structurally awaited by a dedicated SwiftUI task. AppSession
retains scene-active refresh and cancels it on replacement, inactive/background transition, or
Session destruction. Cancellation resets the startup one-time guard so a recreated SwiftUI task
can retry. File persistence checks cancellation after actor entry and immediately
before its atomic-write commit point. Cancellation observed before that point leaves the prior
cache untouched; an atomic commit already started may finish, but canceled acceptance cannot
publish its result. Static contract anchors now require the lifecycle and commit-point seams.

Evidence: The combined public-configuration core/transport suites produced 28 results: 27 passed,
the explicit live Development Worker probe skipped, and 0 failed. Tests deterministically gate
AppSession caller/lifecycle destruction and persistence-actor suspension rather than relying on
scheduler timing. Evidence:
`/private/tmp/MindBudget-C303B-CancellationFix-Focused3.xcresult`. The fresh owning validation then
produced 410 results: 403 passed, 7 explicit opt-in/runtime skips, and 0 failed. All 396 unit tests
and 14/14 UI tests passed, together with the Release build, all static gates, and every selected
coverage threshold. Evidence:
`/private/tmp/MindBudget-C303B-CancellationFix-FullFinal2.xcresult`. Hosted CI remains pending.

Current state: C3-03B remains implementation complete pending independent re-review and green
hosted CI; it is not Done. C3-04 remains blocked.

What was NOT changed: No signed vocabulary, paid right, StoreKit fact, product/price/trial,
notification, Worker response/deployment, Staging/Production deployment, content/identifier,
telemetry, version, Archive/upload, tester assignment, or distribution action changed. The
post-0.9.6 release hold remains active.

## 2026-08-15 — Session 43 — Implement C3-04 UI and release quality

Goal: Implement only the owner-authorized C3-04 UI and release-quality packet without changing
StoreKit authority, signed configuration, formal economics, Production, or distribution.

What changed: The Dashboard now offers one non-blocking navigation card for verified exceptional
subscription states. The Pro screen explains grace, retry, expired, and revoked states using the
same StoreKit-derived authority, retains Restore/Manage/Recheck actions, blocks purchase when the
whole subscription state is not safely actionable, and provides bilingual VoiceOver labels and
hints. AX5 layout adapts across Aurora, Warm Botanical, and Neon. Manual screenshot inspection
found and fixed an appearance-transition contrast defect by binding the screen's local system color
scheme to the selected appearance. Review, privacy, release, change-log, matrix, requirement, and
static-contract documents now describe the actual candidate behavior.

Evidence: Focused StoreKit-domain tests passed 24/24 at
`/private/tmp/MindBudget-C304-StoreRuntime.xcresult`. The corrected AX5 visual test passed 1/1 at
`/private/tmp/MindBudget-C304-ProAX5-ColorFix.xcresult`; all three captured appearances were manually
inspected for contrast, bounds, and clipping. The final full validation produced 413 results:
406 passed, 7 explicit opt-in/runtime skips, and 0 failed. All 398 unit tests, 15/15 UI tests, the
Release build, static gates, and selected coverage thresholds passed at
`/private/tmp/MindBudget-C304-Full-Final.xcresult`. Hosted CI remains pending.

Current state: C3-04 implementation is complete pending independent review and green hosted CI; it
is not Done, and COM-C3 is not Done.

What was NOT changed: No entitlement or StoreKit facts, product IDs, formal price/trial terms,
signed-configuration vocabulary, Worker source/deployment, Staging/Production deployment,
content/identifier/telemetry policy, schema, version, Archive/upload, tester assignment, or
distribution action changed. The post-0.9.6 release hold remains active.

## 2026-08-16 — Session 44 — Address C3-04 independent-review presentation findings

Goal: Resolve the actionable C3-04 review feedback while documenting why the unavailable-as-Free
P1 did not match the existing presentation and without expanding the packet or release authority.

What changed: The existing purchase section remains the single unavailable-authority surface: it
shows localized unavailable copy, disables purchase, and exposes Recheck, so exact Free and
StoreKit-unavailable were already distinguishable. A code comment now makes that boundary explicit
instead of adding a duplicate exceptional-state card. The exceptional-state warning tint now uses
the active skin's `attentionText` token. The Pro screen's local preferred-color-scheme binding is
retained with an explicit explanation that the root already supplies the same value, but retained
AX5 evidence showed a pushed List could lag during a rapid appearance transition. The StoreKit
gate pins the theme-token use, and the test matrix now states that AX5 automation proves control
reachability and bounds, not visual contrast.

Evidence: The focused StoreKit-domain run passed 24/24 at
`/private/tmp/MindBudget-C304-ReviewFix-StoreRuntime.xcresult`. The three-appearance AX5 test passed
1/1 at `/private/tmp/MindBudget-C304-ReviewFix-AX5.xcresult`; all three retained captures were
manually inspected for readability, bounds, and clipping. The full validation produced 413
results: 406 passed, 7 explicit opt-in/runtime skips, and 0 failed. All 398 unit tests, 15/15 UI
tests, the Release build, static gates, and selected coverage thresholds passed at
`/private/tmp/MindBudget-C304-ReviewFix-Full.xcresult`. Hosted CI for the follow-up head remains
pending.

Current state: C3-04 remains implementation complete pending independent re-review and green
hosted CI. It is not Done, and COM-C3 is not Done.

What was NOT changed: No unavailable-authority entitlement decision, StoreKit fact, purchase or
restore behavior, product ID, formal price/trial term, signed configuration, Worker/deployment,
Staging/Production state, schema, user content, telemetry, version, Archive/upload, tester
assignment, or distribution action changed. The post-0.9.6 release hold remains active.

## 2026-08-16 — Session 45 — Close remaining C3-04 presentation review notes

Goal: Resolve the three non-blocking follow-up observations without changing commerce authority or
opening a later commercialization or release gate.

What changed: Purchase availability now has one shared `canPurchaseSelectedProduct` predicate used
by both the button's disabled state and the async action guard. Every Pro-screen warning path uses
the active skin's `attentionText` token. The Pro, subscription-terms, and subscription-privacy
screens each retain the selected preferred color scheme, and the AX5 UI flow now opens and captures
all three screens under Aurora, Warm Botanical, and Neon. The static StoreKit contract pins the
shared purchase gate, the theme-token boundary, and all three preferred-color-scheme bindings.

Evidence: The expanded AX5 test passed 1/1 at
`/private/tmp/MindBudget-C304-P3-AX5-Rerun.xcresult`; all nine retained screenshots were manually
inspected for readable contrast, correct appearance, bounds, and clipping. The fresh owning
validation produced 413 results: 406 passed, 7 explicit opt-in/runtime skips, and 0 failed. It
included 398 unit-test results, 15/15 passing UI tests, the Release build, every static gate, and
all selected coverage thresholds at `/private/tmp/MindBudget-C304-P3-Full2.xcresult`. Hosted CI for
the follow-up head remains pending.

Current state: C3-04 remains implementation complete pending independent re-review and green
hosted CI. It is not Done, and COM-C3 is not Done.

What was NOT changed: No StoreKit or entitlement fact, purchase/restore authority, product ID,
formal price/trial term, signed configuration, Worker/deployment, Staging/Production state, schema,
user content, telemetry, version, Archive/upload, tester assignment, or distribution action
changed. The post-0.9.6 release hold remains active.

## 2026-08-16 — Session 46 — Pause commercialization for an independent Insights correction

Goal: Preserve the commercial phase boundary while correcting a reported Free-core Insights
presentation defect on a separate branch.

What changed: No commerce implementation changed. The core fix makes the point-in-time
`safeToProceed` entry check non-durable, hides legacy copies from retrospective reads, and replaces
the 30-day category prefix bar chart with a lossless top-five-plus-remainder donut. Main project
memory owns the detailed calculation and UI decision.

Evidence: Focused Phase 5/11 tests passed 69/69, the legacy insight suite passed 39/39, and the
focused Insights UI flow passed 1/1 with retained visual evidence. The Phase 6/10 regression
rerun passed 16/16, including the strict local 10,000-expense wall-clock benchmark. Final
validation used the repository's explicit wall-clock exclusion for the concurrently loaded full
suite and produced 416 results: 409 passed, 7 explicit opt-in/runtime skips, and 0 failed. It
included 401 unit-test results, 15/15 passing UI tests, the Release build, every static gate, and
all selected coverage thresholds at `/private/tmp/MindBudget-InsightsFix-FullFinalSkip.xcresult`.

Current state: New commercialization development remains paused. This core correction does not
close C3-04 documentation, start a later COM packet, or relax any commercial or release gate.

What was NOT changed: No StoreKit/entitlement authority, product, purchase/restore behavior,
signed-configuration field or transport, Worker/deployment, Staging/Production status, formal
price/trial term, privacy/network allowance, version, Archive/upload, tester assignment, or
distribution action changed. The post-0.9.6 release hold remains active.

## 2026-08-16 — Session 47 — Close COM-C3 and authorize only build 8 transport upload

Goal: Record the already reviewed/merged C3-04 result and the owner's exact post-COM-C3 release
instruction without starting COM-C4A or broadening upload into distribution.

What changed: C3-04 passed independent review and GitHub Actions run `31918968478`; PR #40 merged
it as `9448ca9`, so C3-04 and COM-C3 are Done. DEC-COM-024 authorizes one traceable 0.9.7 (8)
Archive and App Store Connect transport upload. Purchase/restore, verified subscription-state
guidance, and voluntary presentation have passed their owning COM-C3 gates.

Boundary: No tester group may be assigned by this workflow, and no external Beta App Review,
App Store submission, public-launch economics, Production/Staging deployment, or later COM work is
authorized. Production configuration remains undeployed; failure keeps only the optional value
trigger at built-in `false` and never changes StoreKit authority or permanent subscription access.

Evidence: PR #40 merge `9448ca9`, hosted run `31918968478`; PR #41 merge `afddb5c`, hosted run
`31943778984`. The 0.9.7 preparation passed all static release/commercialization/network/StoreKit
gates and the Release build. Its 420-result wall-clock-excluded run recorded 411 passed, 7 explicit
opt-in/runtime skips, and 2 simulator UI failures; both UI cases passed in immediate isolated runs.
The strict 10,000-expense wall-clock signal also passed independently, and the corrected bilingual
release-note brand assertion passed its focused localization run. Hosted release-preparation CI,
signed Archive inspection, and transport acceptance remain pending and will be appended after
completion.

## 2026-08-20 — Session 48 — Enter COM-C4A through the C4A-01 delta packet only

Goal: Calibrate the commercial state after the accepted 0.9.8 (9) transport upload and complete the
read-only money/migration delta audit before any schema or recovery implementation.

What changed: `COM_C4A_EXECUTION_PACKET.md` now inventories every persisted amount owner, currency
ownership, accepted persisted signs, existing V1–V4 migration evidence, and the exact C4A-02/C4A-03
boundaries. DEC-COM-025 rejects a destructive rewrite of already-correct `Int64` minor-unit values.
It assigns C4A-02 only the missing pre-open backup/journal/integrity/rollback envelope and explicit
currency ownership for the rebuildable merchant aggregate cache. It assigns C4A-03 the interrupted
V1–V4 plus USD/JPY/KWD/sign/`Int64`/anomaly matrix. Requirements and current-state documents now
describe C4A-01 as implementation complete pending independent review; later packets stay blocked.

Release calibration: App Store Connect accepted 0.9.8 (9) on 2026-08-17 as delivery
`dda1eb09-5d8b-43c6-a2fd-ea910fa422ac`. No tester group, external Beta review, App Store submission,
or Production configuration deployment followed, and this historical upload grants no C4A or
public-launch authority.

Evidence: All four named static gates passed. The final full validation produced 420 results:
413 passed, 7 explicit runtime/opt-in skips, and 0 failed; 17/17 UI tests, the Release build, and all
selected coverage thresholds passed at `/private/tmp/MindBudget-C4A01-Full.xcresult`. The strict
Phase 10 suite separately executed and passed 2/2 at
`/private/tmp/MindBudget-C4A01-StrictPerformanceSuite-Retry.xcresult`. Independent review and
hosted CI remain pending.

What was NOT changed: No Swift source, model schema, store content, migration execution, amount,
currency, entitlement, StoreKit behavior, signed-configuration field, network channel, version,
Archive/upload, tester assignment, review submission, Production deployment, or distribution
action changed.

## 2026-08-20 — Session 49 — Close C4A-01 review findings before independent re-review

Goal: Make the money-inventory closure, pre-open recovery boundary, and commercialization state
gate independently checkable without implementing C4A-02.

What changed: The C4A inventory now lists all 15 `ModelCounts` tables. Five reviewed tables are
explicitly marked as carrying no persisted monetary amount: `BudgetPlanSemantics`,
`CoolingOffPlan`, `ReminderEvent` (whose basis-points field is a ratio), `ReflectionLog`, and
`RecurringExpenseOccurrence`. The C4A-02 plan now defines its trigger without relying on
undocumented SwiftData/Core Data schema metadata: no store has no backup; a trusted committed
target marker takes the fast path; a missing/untrusted/target-mismatched marker takes one
pre-open snapshot and journal before opening, and only post-open integrity validation commits the
target marker. That recovery path has separate C4A-03 evidence and is outside the normal Dashboard
first-screen budget.

Follow-up verification defines a trusted marker as a supported, parseable app-owned format in
committed state, with an exact target match and no active/nonterminal recovery journal. The phase
parser's actual-source invocation now requires one direct Status for every recognized phase or
subphase in the authoritative map and the C2/C3/C4A packets. A stable approved top-level phase-ID
set detects whole-phase deletion without encoding mutable status prose; nested additions are
covered automatically. C1 remains the one documented source-level exception because its
historical subpacket headings are prose-only.

The documentation gate now runs a reusable structural phase-state parser with self-tests for
heading discovery, missing/duplicate top-level and nested status records, Done-plus-pending
conflict, Done-without-PR/SHA, blocked-plus-In-Progress conflict, and C4A-01 pending-review versus
C4A-02/C4A-03 blocked states. Historical bootstrap exceptions are limited to COM-C0A/COM-C0B;
C1 and the C2 packet status records now retain their correct merge evidence.

Evidence: `python3 -B Scripts/commercialization_phase_states.py --self-test`, the parser over the
phase map and C1/C2/C3/C4A execution packets, `bash -n Scripts/check-commercialization-docs.sh`,
and `Scripts/check-commercialization-docs.sh` passed. No source/schema/runtime behavior changed;
C4A-01 remains pending independent review and C4A-02/C4A-03 remain blocked.

## 2026-08-20 — Session 50 — Generalize phase-status completeness after re-review

Goal: Remove the remaining C4A-specific status registrations from the documentation gate while
making missing status lines and whole-heading deletion fail loudly across the authoritative map.

What changed: `commercialization_phase_states.py` now supports a source-level require-all mode:
every recognized phase/subphase heading in the task map and C2/C3/C4A execution packets must own
exactly one direct `Status`. C1 is the narrow documented source exception because its historical
subpacket headings predate per-packet status records; its top-level COM-C1 status remains covered
by the authoritative task map. The task map also supplies one exact approved phase-ID set,
including G1. This identifier-only set closes require-all's unavoidable blind spot when an entire
top-level phase heading is deleted, without pinning mutable status text or requiring new nested
subphase registrations.

Self-tests now reject a missing or duplicate nested status, a deleted C3-style status, a deleted
approved heading, and an unapproved heading in addition to the existing classification and merge-
evidence cases. The shell gate contains no per-C4A status registration. No product source, schema,
store, phase state, or release authority changed.

Evidence: Python compilation, the parser's self-test and real authoritative-source invocation,
shell syntax, money, network-egress, commercialization-document, StoreKit-catalog, and diff checks
all passed.

## 2026-08-20 — Session 51 — Align the public README with reviewed commercial boundaries

Refreshed the public repository README without entering C4A-02. The status section now states that
0.9.8 (9) was accepted by App Store Connect transport while later repository changes remain
unreleased, and that no external Beta review, public App Store release, Production public
configuration deployment, or final launch pricing is claimed. It distinguishes reviewed
source-level StoreKit/public-configuration support from formal products and identifies fixture
prices/trials as test controls rather than launch economics. The privacy section links to the
network-egress contract and does not claim that the signed public-configuration adapter is absent.

No commercial phase, product, price, trial, entitlement, network allow-list, Worker deployment,
schema, build, upload, tester, review, or distribution state changed.

## 2026-08-20 — Session 52 — Implement C4A-02 recoverable migration envelope

C4A-01 is now Done after PR #51 merge `bcd56a3` and green CI. C4A-02 adds only the accepted
delta: Schema V5's `MerchantAccountingContext` companion, an app-owned pre-open SQLite
store/sidecar recovery snapshot and journal, post-open inventory, checksum-gated restore, closed
reason-code anomaly records, and Delete All cleanup of pending recovery artifacts. V1–V4 amounts
and stable identities remain untouched; merchant repair is limited to rebuilding the existing
derived total and currency companion from validated same-currency expenses. C4A-03 remains blocked
and owns the full interrupted-version/currency/anomaly evidence matrix. Independent review and
green CI remain required before C4A-02 is marked Done.

## 2026-08-20 — Session 53 — Complete C4A-02 safety edges and focused evidence

The recovery coordinator now validates durable journal identifiers, target, fixed manifest name,
and recovery-directory identity before using any persisted path. Its manifest accepts exactly the
known store artifacts, requires the main store, rejects duplicates, verifies every digest before
touching the live store, and restores only a previously trusted committed source marker. A clean
fast path does no copy or inventory scan; no-store creates no backup. Successful commit clears the
backup/journal while retaining an existing closed anomaly report; Delete All alone clears all
recovery artifacts.

The V5 inventory validates all persisted money owners and required live companions before building
one merchant-only repair plan. It never changes Merchant UUID/name/display/category/visit facts,
never invents or drops a merchant, and fails closed on ambiguous currency or malformed data.
Historical recurring and reflection IDs remain valid provenance after ordinary deletion. Focused
tests cover interrupted byte restoration, checksum refusal without live overwrite, uncommitted
marker rejection, journal path traversal rejection, merchant context/aggregate repair, late
inventory failure with no partial repair, ordinary recurring-origin deletion, and Delete All
artifact-cleanup success/failure. The iOS 26.4 targeted suite, build-for-testing, all four static
gates, and diff check passed; C4A-02 awaits independent review and hosted CI, and C4A-03 remains
blocked.

## 2026-08-20 — Session 54 — Independently harden and validate the C4A-02 candidate

Root review refined the recovery transaction boundary after the Terra implementation. A committed
target marker plus committed journal is now the durable success boundary; deletion of terminal
backup/journal artifacts is best effort and retried on the next cold start or Delete All, so a
cleanup failure can never initiate rollback after part of the backup has already disappeared.
Directory digests now hash a canonical sorted manifest of relative path, byte count, and SHA-256
rather than ambiguous concatenated file bytes.

The first full unit run exposed one real V1 compatibility regression. A legacy expense can carry a
normalized merchant name without a separately materialized derived `Merchant` row. Inventory now
requires every existing Merchant cache row to be supported by verified expenses, but treats a
missing cache row as valid and never invents a UUID. The V1 migration regression test explicitly
locks that boundary. The final unit-only result was 413 total, 406 passed, 7 skipped, and 0 failed.

Final Xcode 26.6 (`17F113`) validation on iOS 26.4.1 (`23E254a`) produced 429 results: 422 passed,
7 explicit runtime/opt-in skips, and 0 failed, including 17/17 UI tests, Release, all static gates,
and every selected coverage threshold at
`/private/tmp/MindBudget-C4A02-Validate-Green-Retry-20260820.xcresult`. The strict performance case
passed 10/10 isolated iterations at
`/private/tmp/MindBudget-C4A02-StrictPerformance-10x-20260820.xcresult`. An earlier concurrent run
measured only the known local wall-clock diagnostic at 1.240605666 seconds and is not claimed as a
pass. C4A-02 remains implementation complete pending independent review and hosted green CI;
C4A-03 and distribution remain blocked.

## 2026-08-20 — Session 55 — Accept the C4A-02 recovery UI boundary

After independent PR #53 review, the owner accepted the current fail-closed recovery product
boundary. `StoreRecoveryView` remains retry-only in C4A-02. If neither the live store nor a trusted
backup can be opened, self-recovery currently requires deleting the app data container or
reinstalling; Delete All cannot run before the store opens. This is an explicit accepted limitation,
not an accidental omission.

C4A-03 must either preserve this boundary or obtain a separate Accepted decision and dedicated
tests before adding an in-app destructive reset. No Swift, schema, migration, data, version,
distribution, or network behavior changed. PR #53 remains pending hosted green CI and merge;
C4A-03 remains blocked.

## 2026-08-20 — Session 56 — Close C4A-02 after review, green CI, and merge

Reviewed head `9d2171d` passed every step of GitHub Actions run `32375823770`, including the
complete Build and test job and test-report upload. PR #53 merged C4A-02 to `main` as `c905415` on
2026-08-20. C4A-02 is therefore Done after independent review, local validation, hosted green CI,
and merge.

Current-state tasks, requirements, decisions, execution packet, CI baseline, and both project
memories now record the merge evidence and remove the obsolete pending-review blocker. The
C4A-02 implementation and owner-confirmed retry-only/reinstall recovery boundary are unchanged.
C4A-03 is blocked only pending explicit owner instruction; this closeout does not implement its
recovery/currency matrix or open any distribution gate.

## 2026-08-20 — Session 57 — Start the C4A-03 recovery and currency matrix

The owner explicitly authorized C4A-03 after C4A-02 merged. The sole active packet is now the
deterministic recovery/currency evidence matrix: clean and interrupted V1–V4-to-V5 opens,
repeated restart/restore, backup and journal failure boundaries, USD/JPY/KWD exponents, persisted
money signs and bounds, checked overflow, and closed malformed-store anomalies. It retains the
owner-confirmed retry-only/reinstall recovery surface; no in-app destructive reset is introduced.

Current implementation work is limited to that evidence plus the smallest supporting guards needed
to keep writer and post-open inventory bounds consistent. C4A-03 is not Done: focused and complete
validation, independent review, hosted CI, and merge evidence remain pending. C4B/C4C, iCloud,
network, StoreKit, release, and distribution work remain out of scope.

## 2026-08-20 — Session 58 — Complete the C4A-03 implementation matrix

The C4A-03 implementation adds deterministic clean/interrupted/restart coverage for V1 through
V4, preserving each version's distinct added facts: V2 income, V3 savings goal, and V4 budget-plan
semantics. A default-no-op internal restore-copy fault hook proves the only sensitive mid-restore
window: after live removal but before a backup artifact copy, a failure preserves the journal and
backup; a fresh ordinary coordinator restores and commits idempotently.

The inventory and BudgetPlan write paths now share the inclusive `Money.maximumMinorUnits` bound
for plan/category amounts. Historical zero savings-goal targets remain readable in inventory, while
new goal entry remains positive-only. Signed derived insight aggregates retain their full `Int64`
range because the entry ceiling deliberately leaves aggregation headroom. Independent anomaly fixtures prove allocation overflow, missing live
references, unsupported/mixed currency, duplicate category identity, unreadable payload, and
merchant/context anomalies do not zero or invent facts. No schema hash, recovery UI, network,
StoreKit, iCloud, or distribution behavior changed.

The first focused compile had three test-only throwing-`#require` macro errors and is explicitly
non-evidence. The final corrected focused evidence at
`/private/tmp/MindBudget-C4A03-Focused4.xcresult` passed 20 tests in two suites with zero failures:
12 C4A-03 matrix tests and 8 existing recovery tests. The generic Release build succeeded with
DerivedData at `/private/tmp/MindBudget-C4A03-Release2-DD`.

The first shared-load validation attempt missed only the existing strict 500 ms Phase 10
Dashboard wall-clock signal and is retained as diagnostic-only evidence. Its owning isolated
performance suite then passed 10/10 at
`/private/tmp/MindBudget-C4A03-StrictPerformance-10x.xcresult`. The final wall-clock-excluded full
validation produced 441 results: 434 passed, 7 explicit runtime/opt-in skips, and 0 failed. All
17 UI tests, every static gate, the Release build, and every selected coverage threshold passed at
`/private/tmp/MindBudget-C4A03-FullFinal.xcresult`. C4A-03 is implementation complete pending
independent review, hosted green CI, and merge.

## 2026-08-21 — Session 59 — Close C4A-03 and COM-C4A after PR #55 merge

Reviewed head `138c240` passed every step of GitHub Actions run `32406654986`, including the
complete Build and test job and test-report upload. PR #55 merged C4A-03 to `main` as `77292c6`.
C4A-03 and COM-C4A are therefore Done after independent review, local validation, hosted green CI,
and merge.

Current-state task maps, requirements, CI baseline, execution packet, project memories, and the
append-only DEC-COM-027 closeout evidence now carry the same result. No Swift, schema, data,
migration, network, StoreKit, iCloud, version, Archive/upload, tester, review, or distribution
behavior changed. C4B remains blocked pending an accepted CloudKit architecture and explicit owner
instruction; C4C and later phases remain blocked.

The closeout reran `Scripts/validate.sh` against the merged source with only the separately proven
strict wall-clock benchmark excluded. The host Xcode run produced 441 results: 434 passed, 7
explicit runtime/opt-in skips, and 0 failed; all 17 UI tests, the Release build, every static gate,
and every selected coverage threshold passed at
`/private/tmp/MindBudget-C4A03-Closeout-Full.xcresult`. An earlier sandboxed invocation could not
create Xcode DerivedData and never entered project testing, so it is retained only as an
environment-permission diagnostic and not promoted as test evidence.


## 2026-08-21 — Session 60 — Produce COM-C4B-01 Free iCloud sync design candidate

The owner explicitly started C4B-01 design only. The proposed (not Accepted) DEC-COM-028 selects
custom versioned `CKSyncEngine` records in one private custom zone, not managed SwiftData/Core Data
mirroring. The candidate is Free, default-off, local-first, and never initializes an engine before
consent. It inventories the actual V5 16-table `ModelCounts` set: twelve authoritative sync
envelope owners, including the recurring-occurrence control-plane claim, and four local-only
derived/device-specific owners (Merchant, MerchantAccountingContext, SpendingInsight, ReminderEvent).

The contract pins the primary local `ModelConfiguration` boundary: the current URL initializers
default to `.automatic`, so C4B-02 must explicitly set every one to `.none` before an iCloud
entitlement/import. The new static contract check will reject a future entitlement/import without
that hardening. Remote records enter durable inbox/shadow and only `DataActor` applies validated,
topologically ordered facts; local facts and outbox/tombstones are one transaction. No online lease
can block local budget writes. True divergent record/tombstone conflicts quarantine rather than use
replica-ID/wall-clock LWW, while logical tombstones protect against resurrection.

The uncreated/unaccepted candidate is one `iCloud.com.xdgf558.MindBudget` container with
entitlement-selected Development/Production environments, proposed `MindBudget.Sync.v1` zone, and
proposed `MindBudgetEnvelopeV1` record type. Typed ledger/note/reflection payload and semantic
digest use `CKRecord.encryptedValues`; key reset pauses for explicit recovery, never automatic
purging/reupload. No container, entitlement, CloudKit import, schema, request, Dashboard action,
deployment, test account, release, or distribution action occurred. C4B-02/03 remain blocked pending
owner acceptance and independent review.

The money, network-egress, commercialization-document (including the new contract parser/self-test),
and StoreKit-catalog gates passed, as did Python AST and shell syntax checks and `git diff --check`.

## 2026-08-21 — Session 61 — Close C4B-01 and prepare the C4B-02 contract gate

Reviewed C4B-01 head `093535f` passed every step of GitHub Actions run `32434148439`; PR #57
merged to `main` as `90a1e66`. The owner accepted the reviewed architecture and the review's
precondition decisions, so DEC-COM-028 and C4B-01 are now Accepted/Done. This is architecture
acceptance only: no container, entitlement, CloudKit import, request, schema, engine, Dashboard
action, deployment, or distribution action occurred.

The C4B-02 prerequisite contract now freezes the existing recurring occurrence-key serializer as
canonical lower-case UUID + persisted-calendar year/month and rejects slash/control/caller inputs;
defines genesis as revision 1 with no parent and later revisions as exact descendants of the last
accepted semantic digest; and keeps durable quarantine non-authoritative with user resolution in
C4B-03. It also records the exact future container identifier and bilingual opt-in disclosure.

The static gate now scans every production Swift source, normalizes `.none` spacing, keeps
`ModelContainer` construction centralized, and explicitly tests missing owner, partial hardening,
managed `.automatic`/private storage, alternate construction, and entitlement/import triggers.
Money, network-egress, commercialization-document, StoreKit-catalog 13/13, iCloud contract
self-test/repository check, Python syntax, and `git diff --check` passed. C4B-02 runtime and C4B-03
remain blocked pending independent review/merge of this prerequisite work and explicit owner start.

## 2026-08-21 — Session 62 — Protect the active C4B-02 prerequisite subphase

Independent review found no new P1/P2 design issue and confirmed that the prior occurrence-key,
lineage, quarantine, and SwiftData-gate findings were closed. It correctly noted that the sole
active prerequisite item was only a checklist bullet and therefore had no direct `Status` under
the packet's `--require-all-status` parser.

The item is now the explicit `C4B-02P` packet subphase with a direct implementation-complete/
pending-independent-review Status. The task maps reference the same identifier, while C4B-02
runtime remains separately Blocked. The parser's known whole-nested-heading deletion/format-drift
limit and fail-safe lexical comment/string noise are not expanded in this narrow remediation.
Commercialization-document validation and `git diff --check` passed before the full static rerun.

## 2026-08-21 — Session 63 — Close C4B-02P SwiftData static-gate bypasses

The follow-up independent review found a real P1: counting `ModelConfiguration(` and `.none` text
was vulnerable to direct `.init`, contextual initializer, alias, and comment/string fixtures. The
gate now tokenizes Swift code conservatively, excluding nested comments and normal/raw single-line
or multiline literal text while preserving code in interpolation. It validates `.none` only as a
top-level argument of each real direct `ModelConfiguration` call, rejects aliases, direct or
contextual `.init`, and `Type.self` escapes, and keeps construction centralized without rejecting
the existing legitimate `ModelContainer` parameter reference in the integrity inventory.

The self-test covers direct and contextual configuration/container initializers, return-style
contextual initialization, aliases, metatype indirection, fake `.none` in comments, normal/raw/
multiline strings and nested code, interpolation construction, alternate construction, managed
selection, entitlement/import activation, and missing owner. C4B-02P is mandatory on C4B-02's
critical path, so both task maps now mark it `[ ]` rather than optional/parallel `[~]`; its packet
Status remains implementation complete pending independent review, while C4B-02 runtime remains
Blocked.

The money, network-egress, commercialization-document, StoreKit-catalog 13/13, iCloud contract
self-test/repository check, Python syntax, and `git diff --check` gates passed locally. This is
still documentation/static-gate maintenance only: no runtime Swift, schema, CloudKit container,
entitlement, request, deployment, Archive/upload, tester, review, or distribution behavior changed.

## 2026-08-21 — Session 64 — Make the C4B-02P lexer delimiter- and cross-file-safe

The next independent review reproduced two further P1 lexical escapes and one P2 trigger gap. A
literal trailing backslash in a raw string could consume its closing quote and hide later source;
a contextual `.init` could infer `ModelContainer` from a declaration in another file; and a
selective import such as `import class CloudKit.CKSyncEngine` did not activate hardening.

Raw strings now treat a backslash as an escape only when it carries the exact opening hash count.
Every real production `.init(...)` is inventoried across the repository even before a CloudKit
trigger and checked against a closed path/receiver/top-level-label/count allowance for the 11
reviewed existing calls. This avoids pretending a lexical scanner can infer cross-file types:
another contextual initializer fails regardless of which file declares its expected type. Direct
and every supported selective CloudKit import kind now activate the same SwiftData boundary.

The deterministic fixtures reproduce the raw trailing-backslash case with a later default
configuration/container, a two-file `ModelContainer` sink plus bare `.init`, and class/struct/enum/
protocol/typealias/func/var/let/macro selective imports. Targeted iCloud self-test, repository scan,
and Python syntax passed. Money, network-egress, commercialization-document, StoreKit-catalog
13/13, iCloud self/repository, Python syntax, and `git diff --check` all passed in the final static
rerun. No runtime Swift, schema, container, entitlement, request, deployment, Archive/upload,
tester, review, or distribution behavior changed; C4B-02P remains pending review and C4B-02 remains
Blocked.

## 2026-08-21 — Session 65 — Close initializer-value and SwiftUI container escapes

Independent review found two more valid construction forms outside the earlier call inventory.
Swift permits `ModelConfiguration.init` or `ModelContainer.init` to be retained as a function value
and invoked indirectly, while SwiftUI's `modelContainer(for:)` creates a container without spelling
the SwiftData initializer at the call site.

The checker now inventories unapplied initializer references separately from `.init(...)` calls and
allows only the existing reviewed `Date`, `Set`, `String`, and recovery-deleter references by exact
path, receiver, and maximum count. A bare SwiftData initializer function value therefore fails.
SwiftUI container modifiers are independently closed: only the single unlabeled
`environment.dataController.container` attachment in `MindBudgetApp.swift` is allowed. View, Scene,
implicit-self, extra, `for:`-creating, and method-reference forms fail.

New fixtures retain both SwiftData initializers as function values, exercise View/Scene and
implicit-self `modelContainer(for:)`, reject a modifier function value, and prove the reviewed
existing-container attachment still passes. No runtime Swift, schema, container, entitlement,
request, deployment, Archive/upload, tester, review, or distribution behavior changed. C4B-02P
remains pending review and C4B-02 remains Blocked.

Money, network-egress, commercialization-document, StoreKit-catalog 13/13, iCloud self/repository,
Python syntax, and `git diff --check` all passed in the final local rerun.

## 2026-08-21 — Session 66 — Implement the C4B-02 local-authority custom-record runtime

C4B-02P passed independent review and GitHub Actions run `32454490080`, then merged through PR #58
as `6f5fded`. After the owner's explicit start, C4B-02 implemented only the accepted runtime/local
boundary and combined its documentation closeout in the same branch.

Schema V6 adds five non-authoritative sync metadata models; all primary stores are explicitly
non-mirrored. The app stages each approved fact and its custom envelope/tombstone atomically,
persists remote data in an inbox before `DataActor` validation/topological application, and keeps a
separate durable outbox from opaque engine state. The exact 12-type allow-list is exhaustive and
four local-only owners remain excluded. Canonical bytes, revision/digest ancestry, encoded server
system fields, no-winner quarantine, same-name logical tombstones, account re-consent, sticky
encrypted-key-reset/remote-zone-loss pauses, and local-first closed failure statuses implement
DEC-COM-028/029.
Settings shows the accepted bilingual default-off disclosure and only neutral status/retry/disable
controls.

Focused evidence is 20/20 passing tests at
`/private/tmp/MindBudget-C4B02-CloudSync-Final.xcresult` on Xcode 26.6/iOS 26.4.1. Static source
checks additionally enforce the exact allow-list and adapter anchors while rejecting public/shared
database, attachment, physical record deletion, managed mirroring, unapproved container creation,
and a C4B-02 iCloud entitlement. Full local/static validation and hosted CI are recorded separately.

The exact container identifier remains only an unprovisioned source constant. There is no iCloud
entitlement, Dashboard schema/deployment, real CloudKit request, physical account/multi-device
evidence, conflict-resolution UI, cloud-wide deletion, Archive/upload/tester/review/distribution, or
C4C work. C4B-02 is implementation complete pending independent review; C4B-03 remains blocked.

## 2026-08-21 — Session 67 — Finish C4B-02 full validation without a contended benchmark

The first full validation attempt passed every functional/UI assertion and the Release build but
failed only the strict local Dashboard wall-clock signal while it ran beside 27 concurrent Swift
Testing suites. It is retained as a non-pass. The focused Phase 10 suite passed, followed by 10/10
isolated iterations (20/20 tests) on iOS 26.4.1 at
`/private/tmp/MindBudget-C4B02-Performance10-iOS264.xcresult`.

DEC-COM-030 therefore keeps the exact 500 ms threshold while making the measurement meaningful:
local validation runs that test once with parallel testing disabled, and the full run excludes only
the duplicate concurrent copy. The corrected `Scripts/validate.sh` run passed the isolated
benchmark, 444 remaining unit tests, 17 UI tests, Release build, static contracts, and coverage
gate at `/private/tmp/MindBudget-C4B02-Validate.xcresult`. No C4B-03 environment, deployment,
physical-device, conflict-resolution, cloud-wide deletion, Archive/upload, tester, or distribution
claim was added.

## 2026-08-21 — Session 68 — Close PR #59 destructive-state and remote-apply review findings

Independent review correctly found two paths around the C4B-02 destructive-state boundary and four
remote-application mismatches. `zoneNotFound` now distinguishes encrypted-key reset through
`CKErrorUserDidResetEncryptedDataKey` and otherwise enters the accepted remote-zone-loss pause.
Database deletion and destructive CKError paths cancel and discard the engine. Once account-change,
encrypted-reset, or zone-loss pause is stored, ordinary account/network/service callbacks cannot
replace it; only the future explicit C4B-03 recovery flow may clear it.

The recurrence engine and record-name path now share `RecurringOccurrenceKey`. Allocation with a
missing Income remains pending, while overflow or a total above the verified Income quarantines.
An accepted occurrence claim cannot silently change its identity, rule, or expense. CategoryBudget
and CoolingOffPlan sync upserts require their parent identity and distinguish malformed envelopes
from parents that have not arrived. The existing Delete All flow is explicitly local-only in C4B-02;
bilingual Settings/confirmation copy warns that retained iCloud copies may be imported after a
future re-enable, while confirmed cloud deletion/reimport remains C4B-03 work.

Focused evidence passed 25/25 at `/private/tmp/MindBudget-C4B02-ReviewFix2.xcresult`. The final
`Scripts/validate.sh` run passed the isolated strict benchmark 1/1; 466 combined correctness/UI
results with 459 passed, seven opt-in skips, and UI 17/17; Release compilation; every static gate;
and coverage (minimum 87.60% against 85%) at
`/private/tmp/MindBudget-C4B02-ReviewFix-Validate.xcresult`. No entitlement, live container,
Dashboard deployment, real CloudKit request, physical/multi-device evidence, cloud-wide deletion,
Archive, upload, tester, or distribution action occurred. PR #59 remains pending final re-review,
hosted green CI, and merge; C4B-03 remains blocked.

## 2026-08-21 — Session 69 — Close C4B-02 after reviewed green merge

The owner accepted the final PR #59 re-review and required the hosted `Build and test` gate to pass
before merge. Reviewed head `0024507` passed GitHub Actions run `32490174014` in 34m30s, and PR #59
merged that exact source to `main` as `211dff2`. C4B-02 is therefore Done. The current task maps,
execution packet, sync contract, requirement index, network policy, CI baseline, memories, and
decision pointers now record that evidence without rewriting Sessions 66–68 or the original
decision state at the time it was made.

C4B-03 remains blocked until this documentation-only closeout passes independent review, hosted CI,
and merge. The owner has explicitly authorized formal C4B-03 entry after that condition. C4B-03
still owns the iCloud entitlement, container provisioning, Dashboard Development/Production
deployment, real account/quota/offline evidence, physical multi-device convergence, conflict
resolution, confirmed cloud-wide deletion/reimport, tombstone compaction/retention, privacy/review,
and release gates.

This closeout changes no Swift, Schema, entitlement, container constant, adapter, deployment,
Archive/upload, tester, or distribution behavior. Money, network-egress, commercialization-
documentation, StoreKit catalog 13/13, iCloud self-test/repository scan, shell syntax, and
`git diff --check` passed locally. Hosted CI and merge for this closeout remain required before
C4B-03 starts.

## 2026-08-22 — Session 70 — Formally enter C4B-03 and implement lifecycle/deletion controls

Reviewed closeout head `b9944cd` passed GitHub Actions run `32494429474`; PR #60 merged it as
`7138a9c`, satisfying the owner's formal C4B-03 entry condition. DEC-COM-032 now owns the exact
boundary. The source adds separate Development/Production entitlement files for the one accepted
private container, explicit no-content conflict review, keep-local/use-iCloud resolution, durable
whole-zone cloud deletion that preserves local facts, retained-copy reimport confirmation, and an
explicit sticky trust-recovery flow. Generic Enable is hidden during a trust-boundary pause.

The focused sync suite passed 32/32 at `/private/tmp/MindBudget-C4B03-Focused3.xcresult`. A signed
Debug build proves the exact Development entitlement/profile at
`/private/tmp/MindBudget-C4B03-GenericSigned1.xcresult`. A Release archive succeeded at
`/private/tmp/MindBudget-C4B03-Release1.xcarchive`, but automatic signing used an Apple Development
profile; therefore it proves Production CloudKit configuration selection, not distribution push,
Production schema deployment, or release readiness. The physical iPhone disappeared from Xcode
before the direct-device build could execute, so no physical or real-request claim is made.

No primary SwiftData schema, money model, StoreKit, app-owned HTTP(S), public/shared CloudKit,
receipt/OCR, telemetry, Archive upload, tester, review, or distribution action changed. Full local
validation, real Development request/Dashboard, physical multi-device/account/quota/offline,
distribution signing, Production schema owner confirmation/deployment, review, hosted CI, and merge
remain open.

## 2026-08-22 — Session 71 — Close the C4B-03 local validation and background-delivery boundary

The exact entitlement made six legacy migration fixtures expose an implicit SwiftData
`cloudKitDatabase: .automatic` default inside the entitled test host. That first full run is kept as
a non-pass, not hidden as infrastructure noise. Every local test-store configuration now states
`.none`, and the repository gate scans production plus test Swift sources so a future fixture cannot
accidentally enter managed mirroring.

A build-setting-only background-mode attempt did not materialize in the generated app plist and
was removed. The app now uses the checked source plist `MindBudget/Resources/MindBudgetInfo.plist`
with exactly `UIBackgroundModes = [remote-notification]`; Debug and Release both reference it while
their separate entitlements continue to select Development and Production. A fresh generated Debug
plist was read back with the exact array. DEC-COM-033 records this boundary.

The corrected migration/free-tier regression passed 45/45 at
`/private/tmp/MindBudget-C4B03-Regression2.xcresult`. The final `Scripts/validate.sh` run passed all
static contracts, Release compilation, the isolated strict 10,000-row Dashboard benchmark, 456/456
unit tests across 27 suites, 17/17 UI tests, and all selected coverage thresholds at
`/private/tmp/MindBudget-C4B03-Full1.xcresult` (minimum 87.60%, required 85%). C4B-03 remains In
Progress: no real CloudKit request/Dashboard inspection, physical multi-device/account/quota/offline
matrix, distribution signing, Production schema deployment, review, hosted CI, or merge is claimed.

## 2026-08-22 — Session 72 — Pass the authorized physical Development CloudKit lifecycle probe

The owner connected and unlocked physical `拉沙的iPhone` (`iPhone Air`) running final iOS 26.6.1
(`23G82`) and explicitly accepted irreversible deletion of the fixed Development zone
`MindBudget.Sync.v1`. The signed Debug app was first built and installed without overwriting an
existing MindBudget installation. A direct physical build confirmed Development push/CloudKit,
the exact private container, and team signing at
`/private/tmp/MindBudget-C4B03-Physical1.xcresult`.

The first destructive-test result is retained as a compile non-pass: the suite's `@MainActor`
isolation made its test-condition property unavailable to Swift Testing's generated Sendable
closure. Marking the pure condition `nonisolated` fixed that source issue. Two subsequent exact-
function filtered runs executed zero Swift Testing functions even though the suite was discovered;
they are false-green diagnostics and not evidence. Xcode also did not forward the invoking shell's
environment variable to the device process. DEC-COM-034 therefore requires an explicit Swift
compilation condition and a nonzero result total.

The accepted run used final Xcode 26.6 (`17F113`) with the explicit
`MINDBUDGET_PHYSICAL_CLOUDKIT_TESTS` condition and suite-level filtering. All 33
`CloudSyncTests` passed with zero failures in 10.078 seconds; the real Development case took 9.358
seconds. It used the production `CKSyncEngine` adapter to create the private custom zone, send and
fetch the encrypted envelope, disable while retaining the cloud-copy marker, require confirmed
reimport, delete the whole zone, and prove the local expense remained. Evidence:
`/private/tmp/MindBudget-C4B03-PhysicalCloudKit4.xcresult`.

C4B-03 remains In Progress. Dashboard inspection, physical offline/quota/account transition,
background push, multi-device convergence/conflict, distribution signing, Production schema
deployment, independent review, hosted CI, merge, and release remain open. No Production CloudKit
state, public/shared database, StoreKit, app-owned HTTP(S), receipt/OCR, telemetry, tester, or
distribution action changed.

## 2026-08-22 — Session 73 — Inspect the Development/Production Dashboard boundary read-only

After the physical lifecycle probe, the ordinary simulator configuration was rerun without
`MINDBUDGET_PHYSICAL_CLOUDKIT_TESTS`. It produced 33 results at
`/private/tmp/MindBudget-C4B03-PostPhysical-Sim.xcresult`: all 32 deterministic cases passed, the
one destructive physical case was explicitly skipped, and there were zero failures. The real-zone
test therefore remains opt-in rather than leaking into ordinary simulator or hosted-CI execution.

With the owner signed in, CloudKit Dashboard was inspected read-only for team `2AM5S7BM2N` and
container `iCloud.com.xdgf558.MindBudget`. Development shows `MindBudgetEnvelopeV1` with six system
metadata fields and exactly one app field, `envelope` (`ENCRYPTED BYTES`), with no index. The prior
whole-zone probe left only `_defaultZone`; the fixed custom Development zone was absent as expected.
Production shows only the system `Users` type: `MindBudgetEnvelopeV1` is absent, and
`Deploy Schema Changes` is disabled. Screenshots are
`/private/tmp/MindBudget-C4B03-Dashboard-Development-Envelope.png` and
`/private/tmp/MindBudget-C4B03-Dashboard-Production-NoTypes.png`.

No schema deployment, record/role/permission edit, Production write, reset, or other Dashboard
mutation occurred. C4B-03 remains In Progress. Physical offline/quota/account/background-push,
two-device convergence/conflict, distribution signing, owner-authorized Production deployment,
independent review, hosted CI, merge, and release remain open.

## 2026-08-22 — Session 74 — Revalidate current source and isolate one long-run UI miss

The current source rebuilt Release, passed every static contract, and completed all 457 unit-test
results without a failure in the final simulator validation. The 17-test UI phase passed 16 cases;
the pseudo-long-text case did not transition from budget setup to Dashboard during that long
integrated run, causing four dependent reachability assertions to fail. Xcode subsequently hung
while collecting failure diagnostics and coverage, so the incomplete
`/private/tmp/MindBudget-C4B03-FinalWithoutWallClock.xcresult` is explicitly not green evidence.

The exact pseudo-long case was rerun alone on the same iOS 26.5 simulator and passed 1/1 in 23.625
seconds with zero failures at `/private/tmp/MindBudget-C4B03-PseudoLong-Isolated.xcresult`. Two
current-load strict Dashboard runs measured 0.870945 and 0.752715 seconds rather than the required
0.5-second local signal; they remain diagnostic non-passes, with the latter stored at
`/private/tmp/MindBudget-C4B03-PerformanceFinal.xcresult`. The previously accepted full result
`/private/tmp/MindBudget-C4B03-Full1.xcresult` remains applicable because no production Dashboard
or UI source changed after it passed strict performance, 456/456 units, 17/17 UI, and coverage.
C4B-03 stays In Progress; no external gate was waived.

## 2026-08-22 — Session 75 — Close saturated lineage arithmetic without wrapping

Final source review after Session 74 found three paths that advanced a signed CloudKit revision
with unchecked `+ 1`: staging after accepted metadata, remote descendant acceptance, and explicit
keep-local conflict resolution. A private envelope or persisted metadata row at `Int64.max` could
therefore trap the process rather than fail closed. DEC-COM-035 now requires one throwing revision
helper for all three paths; negative ancestry and advancement beyond `Int64.max` are rejected as
`invalidLineage` without rewriting local facts.

The exact-head simulator run rebuilt the app and passed 34 `CloudSyncTests` results: 33
deterministic passes and the compile-time physical-zone test explicitly skipped, with zero failures
at `/private/tmp/MindBudget-C4B03-LineageBound.xcresult`. Static money, network-egress,
commercialization-document, StoreKit 13/13, iCloud contract self-test/repository, Python syntax,
and diff checks also pass. The earlier full/UI run remains regression context rather than exact-
head completeness; independent review, hosted CI, and all external lifecycle/release gates remain
open.

## 2026-08-22 — Session 76 — Stop the cross-account two-device attempt and clean its zone

The second physical device, `Xiao li的 iPhone (2)` (iPhone 16, iOS 26.5.2 `23F84`), was paired,
registered to team `2AM5S7BM2N`, placed in Developer Mode, and granted local-network permission.
The opt-in primary and secondary convergence variants both compiled and signed. Runs before the
permission change are retained as environment non-passes.

After the permission fix, non-content one-way account fingerprints were different on the two
devices. The devices
therefore address different private CloudKit databases and cannot observe the same custom-zone
record. The owner declined an account switch and explicitly stopped the two-device test. No
convergence/conflict result is claimed. DEC-COM-036 retains the compile-time harness only as a
future same-account evidence tool.

The interrupted primary run left one fixed Development seed. The first cleanup result
`/private/tmp/MindBudget-C4B03-PostMultiCleanup.xcresult` imported it and failed an old local-only
count assertion before its zone deletion completed, so it is a non-pass. Repeating the cleanup
against the empty zone passed 33/33 at
`/private/tmp/MindBudget-C4B03-PostMultiCleanup2.xcresult`. This proves the fixed Development zone
is clean, not two-device convergence. The ordinary simulator build then passed 36 results—33
deterministic passes and three explicit physical-only skips—at
`/private/tmp/MindBudget-C4B03-PostMultiDefault.xcresult`, proving the retained harness stays
disabled in ordinary/CI execution. C4B-03 remains In Progress; no external gate is relabeled or
waived.

The final current-source validation then passed every static contract, Release compilation, all
460 unit-test results across 27 suites, 17/17 UI tests, and every selected coverage threshold at
`/private/tmp/MindBudget-C4B03-ExactHeadFull2.xcresult` (minimum 87.60%, required 85%). Its three
physical CloudKit cases were explicit skips. The wall-clock benchmark was intentionally skipped
after the loaded-host non-passes already recorded in Session 74; no new strict timing result is
claimed, and the earlier accepted strict Dashboard pass remains separate regression evidence.

## 2026-08-22 — Session 77 — Close PR #61 retained-copy review findings

Independent review identified that the local-only Delete All path preserved the durable
`cloudCopyMayExist` retention marker but replaced the current session snapshot with literal
`.disabled`. That temporarily hid the cloud-delete control, selected the ordinary Enable
disclosure, and then let the service silently reject unconfirmed reimport. DEC-COM-037 makes the
service the post-deletion snapshot authority: it republishes disabled local control with retained
cloud-copy knowledge in the same session. The regression proves cloud deletion remains visible,
ordinary Enable constructs no adapter, and explicit reimport confirmation enables transport.

The same remediation adds localized network/account/quota/failure guidance while cloud deletion is
sticky, prevents ordinary Disable during that state, and pins content-free conflict quarantine as
non-resolvable and non-mutating. The current contract now distinguishes durable local tombstone
intent from whole-zone deletion, and time-boxes the old no-entitlement wording to C4B-01/C4B-02.

The focused run passed 52 results at
`/private/tmp/MindBudget-C4B03-ReviewRemediation-Focused1.xcresult`, including three explicit
physical-only skips. An initial sandboxed full run is an environment non-pass because CoreSimulator
was unavailable and DerivedData writes were denied. The accepted full run at
`/private/tmp/MindBudget-C4B03-ReviewRemediation-Full2.xcresult` passed every static gate, Release
compilation, 461 unit-test results across 27 suites, 17/17 UI tests, and all selected coverage
thresholds; minimum selected coverage was 87.60% against 85%. The loaded-host wall-clock skip and
external C4B-03 evidence gaps remain unchanged, so the phase is still In Progress pending hosted
CI, re-review, merge, and the unwaived release gates.

## 2026-08-22 — Session 78 — Record PR #61 product merge and defer unavailable dual-device proof

Exact reviewed head `f49de948b88c9fc42aff996b6e90fd835742ca41` passed GitHub Actions run
`32571676058`; `Build and test` completed successfully after 19m36s. PR #61 merged that head to
`main` as `0f749ce18b877969248fb3e4e7c0b28df21139af` at 2026-08-22 12:17:31 UTC. The C4B-03 product
capability is now merged, so product review, hosted CI, and merge are no longer open evidence.

The connected physical devices use different iCloud Apple Accounts and cannot exercise one private
database. Because a same-account arrangement is not currently available, the owner asked to skip
that rerun for now. DEC-COM-038 preserves this as a temporary evidence deferral. It is not a pass,
product failure, permanent waiver, release authorization, or permission to close C4B-03/COM-C4B.
The opt-in harness remains for a future same-account run. C4C and distribution remain blocked;
physical account/offline/quota/background-push, distribution signing, and owner-authorized
Production deployment/release evidence stay open.

This calibration changes documentation/static gates only. No Swift, Schema, entitlement, container,
CloudKit record, Dashboard environment, Production deployment, Archive, upload, tester, or release
action changed. Final static validation is recorded after the document gate is updated.

Final static validation passes: money, network egress, commercialization documentation, StoreKit
catalog 13/13, iCloud contract self-test/repository, Python syntax, shell syntax, and
`git diff --check`. The first document run failed closed on the superseded exact phrase
`C4B-03 is In Progress`; after updating that contract anchor to `remains In Progress`, it passed.
The first Python compile-only attempt hit Apple's unwritable default bytecode cache, and the same
check passed with a task-specific `/private/tmp` cache. No runtime suite was rerun for this
documentation-only calibration; hosted CI remains the PR merge gate.

Independent review of PR #62 found no P1/P2 issue and recommended approval after hosted CI. The
optional P3 status polish was accepted: the iCloud contract's current Status and introduction now
name PR #61 (`0f749ce`) and use present tense for the merged entitlement/operational surfaces.
Historical evidence sections remain append-only and were not rewritten.

## 2026-08-22 — Session 79 — Permanently waive only same-account physical evidence

The owner superseded DEC-COM-038's temporary deferral and permanently waived the physical
same-iCloud-account two-device convergence/conflict evidence gate. DEC-COM-039 records that this is
not a pass or product-failure finding. The stopped different-account attempt remains historical
non-pass evidence, deterministic lineage/conflict/no-winner coverage remains mandatory, and the
compile-time physical harness remains an optional diagnostic.

The preceding calibration is now independently closed: reviewed head `0350415` passed GitHub
Actions run `32573992659`, and PR #62 merged it as `0128682`. The permanent waiver removes only the
same-account physical run from C4B-03/COM-C4B exit evidence. Physical account/offline/quota/
background-push evidence, distribution signing, Production deployment/release authorization, C4C,
and distribution remain open or blocked exactly as before. This session changes documentation and
its static contract only; it performs no CloudKit, Production, archive, upload, or release action.

Final static validation passes: money, network egress, commercialization documentation, StoreKit
catalog 13/13, iCloud contract self-test/repository, Python syntax, shell syntax, and
`git diff --check`. No runtime suite is rerun for this documentation-only scope; hosted CI remains
the PR merge gate.

Independent review of PR #63 found no P1/P2 issue and recommended approval after hosted CI. The
optional P3 task-history clarification was accepted: `Docs/TASKS.md` now labels PR #62's temporary
deferral text as a time-boxed state superseded by DEC-COM-039. DEC-COM-038 and other historical
decision/evidence entries remain append-only.

## 2026-08-22 — Session 80 — Calibrate PR #63 and unblock real background delivery

GitHub confirms exact waiver head `7b2349001b8e1228def6e34211cbf09785977f41` passed Actions run
`32576885537`, and PR #63 merged it as `1a14df96d40d3248190d55861f88327407ea8f77` at 2026-08-22
14:20:56 UTC. That merge permanently removes only the physical same-account two-device item from
exit evidence. It does not close account/offline/quota/background-push, distribution signing, or
Production/release evidence, so C4B-03 and COM-C4B remain In Progress.

The next evidence audit traced the pending background-push path from entitlements/plist through
`CKSyncEngine` construction. The adapter had `automaticallySync = false`, so scene activation and
explicit Retry were the only actual fetch/send initiators. That contradicts the accepted
Apple-managed scheduling boundary and makes a physical silent-push claim impossible. DEC-COM-040
corrects the opted-in production policy to `true`, retains the fixed private-database subscription
ID, and leaves default-off construction, explicit Retry, local authority, inbox validation,
quarantine, zone deletion, and sticky pauses unchanged. The static iCloud gate now rejects a
regression to manual-only production scheduling.

The selected simulator command completed 38 CloudSync results with 35 deterministic passes, three
explicit physical-only skips, and zero failures at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused1.xcresult`. The iCloud self-test/repository
scan, Python syntax, and diff checks pass. These results prove source configuration and regression
safety only; physical background delivery remains open.

One paired Development iPhone is available. Local keychain inventory has Apple Development
identities but no Apple Distribution identity, so distribution-signing proof cannot be closed from
this machine state. Production still has no deployed app schema and no deployment was attempted.
Apple's quota error describes a real account storage condition; no supported non-destructive
Development simulation was found. Deliberately exhausting personal iCloud storage is rejected, so
physical quota evidence remains open pending owner disposition or a dedicated quota-limited test
account.

Exact-head full local validation now passes at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Full1.xcresult`: all static contracts, Release, 462
unit-test results across 27 suites, 17/17 UI tests, and every selected coverage threshold.
`xcresulttool` reports 479 combined results with zero failures, 469 passes, and ten explicit skips;
minimum selected coverage is CSVExporter at 87.60% against the required 85%. The accepted
loaded-host option skipped the wall-clock benchmark and does not create a new strict performance
claim. A Development physical rerun could not start because Xcode reported the paired iPhone
unavailable while browsing the local network and requested an unlocked attached device. That
environment non-pass creates no CloudKit, push, account, offline, or quota evidence.

## 2026-08-23 — Session 81 — Re-run corrected Development lifecycle on device

After the owner reattached the iPhone, Xcode reported `拉沙的iPhone` available over USB. The exact
opt-in Development command completed the selected `CloudSyncTests` at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Physical2.xcresult`: 38 total, 36 passes, the two
permanently waived multi-device roles explicitly skipped, and zero failures on an iPhone Air with
iOS 26.6.1. The real case created the fixed Development zone, sent and fetched the encrypted
envelope, disabled sync, required confirmed reimport, deleted the whole test zone, and retained the
local expense. Production was not contacted.

Runtime diagnostics showed `CKSyncEngine` background-task registration after DEC-COM-040 enabled
automatic scheduling. In-process disable/re-enable also emitted Apple's duplicate-registration
diagnostic; Apple's sample explicitly supports reinitializing an engine, and the full explicit
lifecycle completed successfully. This run still did not introduce an independent remote mutation
while the app was backgrounded, so it is not recorded as silent-push evidence. Account transition,
offline, quota, distribution signing, and authorized Production/release evidence remain open.

## 2026-08-24 — Permanently waive physical background-push evidence without a pass

The owner permanently waived the C4B-03 physical background/silent-push observation and explicitly
required that it not be recorded as passed. DEC-COM-042 narrows that risk acceptance to the physical
observation only. It does not weaken `automaticallySync = true`, the fixed subscription identifier,
the checked Development/Production capabilities, default-off consent, local authority, durable
inbox/outbox, conflict quarantine, sticky recovery, or deterministic transport coverage.

Nine result packages, `MindBudget-C4B03-BackgroundPush6.xcresult` through
`MindBudget-C4B03-BackgroundPush14.xcresult`, were inspected. None observed an independent
Development mutation reaching the app while it remained backgrounded, so the pass count is zero.
The sequence includes pre-ready trust-boundary failure, timeouts with no external deletion, device
proxy and trust failures, a zero-test filter error, and a final exact probe canceled after the
CloudKit Console was found to be acting as the wrong account. The final probe reached READY but did
not receive an external deletion. No Production action occurred. Because that canceled run did not
reach its ordinary cleanup, the fixed Development test zone/record is treated as potentially
remaining rather than silently claimed clean.

The probe also found two independent runtime defects. DEC-COM-041 moves delegate-triggered engine
cancellation outside the serialized callback task, clears only the matching engine instance, and
allows fixed-zone creation only for transport genesis without accepted serialization. The final
focused simulator run passed 37 tests with four physical-only skips and zero failures at
`/private/tmp/MindBudget-C4B03-AutomaticSync-Focused6.xcresult`.

C4B-03 and COM-C4B remain In Progress. Physical account/offline/quota, distribution signing, and
explicitly authorized Production deployment/release evidence remain open; C4C remains blocked.
Next suggested task: validate this exact source/document head, then review it without relabeling the
waived physical observation as delivery evidence.

Exact-head validation is now complete. A UI-test-only accessibility query had assumed the
quick-add action was always a single `Button`; repeated SwiftUI launches exposed it as a
`DisclosureTriangle` or as nested duplicate identifier nodes. The harness now queries across
element types and selects the first matching identifier. The four directly affected flows passed
4/4 at `/private/tmp/MindBudget-C4B03-Waiver-UIRerun5.xcresult`.

The final cold-boot full run passed at
`/private/tmp/MindBudget-C4B03-Waiver-Full4.xcresult`: Release and all static contracts passed,
465 unit-test results completed, 17/17 UI tests passed, and every selected coverage threshold
remained above 85%. `xcresulttool` reports 482 logical results, zero failures, 471 passes, and eleven
explicit skips. Earlier transient/full-run diagnostics are not promoted to evidence; their affected
UI tests passed focused reruns before the final green run. The wall-clock benchmark was explicitly
skipped, so no new strict performance claim is made.

This validation does not convert the physical background-push waiver into a pass. That pass count
remains zero. C4B-03/COM-C4B remain In Progress with account/offline/quota, distribution signing,
and authorized Production deployment/release evidence open; C4C remains blocked.

## 2026-08-24 — Session 166 — Close C4B-03 with explicit non-pass and release ownership

GitHub confirms reviewed final correction head `f1f37db` passed Actions run `32726507493`; PR #64
merged it to `main` as `4f6d7fe`. Read-only closeout inventory found one paired physical iPhone
available, no valid local Distribution codesigning identity, and no deployed Production app schema.
No Production, Archive/upload, tester, review, or release action was attempted.

The owner accepted DEC-COM-043. Physical account-switch, offline, and quota observations are now
permanently waived and explicitly not passed, alongside the separately scoped same-account and
background-push non-passes. Deterministic local-first/fail-closed account, offline, quota, retry,
sticky-pause, conflict, deletion, and reimport coverage remains required and unchanged. Distribution
signing and explicitly authorized Production schema/deployment/release proof are not waived; they
move to COM-C6/COM-C12 and must close before their respective distribution/formal-release exits.

C4B-03 and COM-C4B are Done, and C4C is unblocked with C4C-01 next. StoreKit authority and local
Pro behavior remain independent of iCloud evidence. This documentation-only closeout adds no
runtime, entitlement, schema, network, version, Archive, upload, tester, or release change.

The complete local validation entry then passed on this documentation-only head: all static
contracts, Release compilation, 465 unit-test results across 27 suites, 17/17 UI tests, and every
selected core-service coverage threshold. CSVExporter was the minimum selected result at 87.60%
against the required 85%. Four physical-only CloudSync probes remained explicit skips, so the run
does not relabel any owner-waived observation as passed. A first sandboxed attempt lacked access to
CoreSimulator/DerivedData and is recorded only as an environment non-pass; the unrestricted rerun
is the accepted local closeout evidence.

## 2026-08-25 — C4C-01 premium seams, deterministic evidence, and receipt baseline

The owner explicitly entered C4C-01. The source audit found no receipt acquisition/OCR/persistence
path and confirmed `FeatureFlags.enableReceiptImport` remains false. It also found DEC-COM-014's
durable boundary: current 30-day Insights and basic deterministic reminder/review behavior are
Free, so C4C-01 cannot monetize them by relabeling the existing UI.

DEC-COM-044 keeps that baseline and makes the advanced increment independently testable. The
Commerce snapshot now covers the accepted advanced local and future receipt seams. New detector
results carry integer supporting/total samples plus a basis-point support ratio; persistence uses
three reserved typed payload keys, strips them from normal presentation payload on read, accepts
legacy absence, and rejects partial or inconsistent evidence. The Insights card shows the evidence
line only when central `advancedLocalInsights` access allows it.

`LocalReceiptRecognitionBaseline` has no model-only case: usable local-model capability always
includes a deterministic fallback, and missing scope/rights returns unavailable. SPEC-015 is
implemented as two exact future Vision path exceptions that reject money vocabulary. C4C-02
through C4C-05 remain blocked, and no image/content/network/release behavior was introduced.

The final focused entitlement/rule/Free matrix passed 92/92. A prior diagnostic run found one
overstated test-only expectation that the same rule used for an interrupting reminder must also
remain as an inline card; the accepted Free regression instead proves reminder presentation,
manual save, reminder history, and the durable review row. Existing tests run under exact Free
without a Pro injection.

The complete validation entry passed at `/private/tmp/MindBudget-C4C01-Full.xcresult`: all static
contracts, Release compilation, the strict wall-clock stage, 468 unit results across 27 suites,
17/17 UI tests, and all selected coverage thresholds passed. `xcresulttool` reports 485 logical
results, zero failures, 474 passes, and eleven explicit skips. The four physical-only CloudKit
probes remain intentional skips and do not belong to this packet. Minimum selected coverage is
CSVExporter at 87.60%. No physical, Production, Archive/upload, tester, or release action occurred.

## 2026-08-25 — Close C4C-01 after reviewed merge

Independent review found no P1/P2 issue on head `d203308`. The review retained one non-blocking
maintenance note: if a future detector refactor violates `supportingSampleCount <= sampleCount`,
the evidence path must expose that invariant failure rather than silently presenting exact 1/1
evidence. The current detector inputs satisfy the invariant, and the accepted integer confidence
wording remains explicitly non-probabilistic.

GitHub Actions run `32845307426` completed successfully on the reviewed head. PR #66 then merged
the C4C-01 source to `main` as `8611022` on 2026-08-25. C4C-01 is Done. C4C-02 is next but remains
blocked until explicit owner entry; C4C-03 through C4C-05 remain blocked by their predecessors.

This documentation-only closeout adds no runtime, image permission, OCR, receipt persistence,
schema, network, Production, Archive/upload, tester, or release change. `enableReceiptImport`
remains false, so no receipt customer entry exists.

The closeout branch passed the complete local validation entry: every static contract, Release
compilation, the strict Dashboard wall-clock stage, 468 unit-test results across 27 suites, 17/17
UI tests, and all selected core-service coverage thresholds passed. CSVExporter was the minimum
selected result at 87.60% against the required 85%. Four physical-only CloudKit probes remained
explicit skips. The validation script's ephemeral result bundle was
`mindbudget-validation.lhbQJj/MindBudget.xcresult` during the run and was removed by normal
temporary-directory cleanup after success.

## 2026-08-25 — C4C-02 bounded acquisition and image-lifecycle candidate

PR #67's reviewed C4C-01 documentation merge `bdb94d9` is the source baseline, and the owner
explicitly entered C4C-02. DEC-COM-045 keeps the receipt product flag off while adding exact
infrastructure for later use: source/Pro/permission/hardware capability, explicit camera permission,
single-image PHPicker, DataScanner without result consumption, bounded ImageIO normalization,
geometry-only rectangle/perspective correction, and a one-generation protected temporary store.

The processor rejects empty, corrupt, overflowed, over-48-MiB, and over-64-million-pixel sources;
normalizes to a 4,096-pixel edge; and rejects prepared output above 12 million pixels or 8 MiB.
Original bytes never reach the temporary store. Generation checks and cancellation handlers prevent
late commits, and startup orphan cleanup plus background/inactive, memory-warning, Delete All, and
session teardown all use the same idempotent removal boundary. English and Simplified Chinese
camera-purpose strings are present, while broad Photos permission is structurally forbidden.

Focused result `/private/tmp/MindBudget-C4C02-Focused5.xcresult` passed 10/10 on iPhone 17 Pro,
iOS 26.5 (`23F77`). Full local validation passed all static contracts, Release compilation, strict
wall-clock testing, 478 unit results across 28 suites, 17/17 UI tests, and every selected coverage
threshold; CSVExporter remained the minimum at 87.60%. Four physical-only CloudKit probes remained
explicit skips. The full result path was ephemeral and removed by `Scripts/validate.sh` cleanup.

No OCR recognized item, receipt field, persistence, schema, iCloud receipt data, content logging,
model prompt, egress, customer entry, Production, distribution, or release action exists in this
candidate. C4C-03 remains blocked pending independent review, green hosted CI, merge, and a separate
owner entry. There is no enabled user-visible behavior change, so no changelog entry is required.

## 2026-08-26 — C4C-02 reviewed merge closeout

Independent review found no P1/P2 issue on exact head `43c3a35`. GitHub Actions run `32860643712`
completed successfully on that head, and PR #68 merged it to `main` as `4ca8f1c`. DEC-COM-046
therefore marks C4C-02 Done without enabling the receipt product flag or entering C4C-03.

The review's three P3 observations remain bounded follow-up rather than source churn after merge:
an actual UI consumer should give DataScanner temporary unavailability its own error; physical
system-adapter behavior and the 20-image resource matrix belong to C4C-05; and compression-quality
floating-point literals are non-money parameters, not a broader SPEC-015 exception. C4C-03 through
C4C-05 remain blocked pending separate owner entry and predecessor completion.

This documentation-only closeout passed the complete local validation entry: all static contracts,
Release compilation, the strict Dashboard wall-clock stage, 478 unit-test results across 28
suites, 17/17 UI tests, and every selected coverage threshold passed. CSVExporter was the minimum
selected result at 87.60%. Four physical-only CloudKit probes remained explicit skips. The
ephemeral bundle `mindbudget-validation.iJejGl/MindBudget.xcresult` was removed by normal cleanup.
No Production, Archive/upload, tester, review, distribution, or release action occurred.

## 2026-08-26 — C4C-03 local OCR and pre-model privacy candidate

Reviewed C4C-02 documentation head `4ab0daf` passed GitHub Actions run `32911659905`, and PR #69
merged it as `3e1c5c9`. The owner explicitly entered C4C-03 afterward. DEC-COM-047 confines raw
`VNRecognizeTextRequest` candidates to `ReceiptVisionObservation.swift` and its immediate privacy
pipeline. Only a `ReceiptModelSafeText` line can emerge; its initializer is file-private to the
mandatory card-number/last-four/authorization-code filter.

The pipeline retains normalized geometry and non-money confidence, orders fixed vertical bands
top-to-bottom and then left-to-right with stable tie breakers, and rejects invalid metadata or
bounded-input overflow. Its 256-observation, 512-byte-line, and 16-KiB-document limits cannot
silently truncate. The customer flag stays false, and no structured receipt field, persistence,
model call, HTTP(S), telemetry, iCloud field, Production, or release action exists.

Focused attempt `/private/tmp/MindBudget-C4C03-Focused1.xcresult` failed at test compilation due to
throwing-expression placement inside `#require`; it ran no test and is excluded. Corrected bundle
`/private/tmp/MindBudget-C4C03-Focused4.A42MrA/MindBudget.xcresult` passed 7/7 across accepted sensitive patterns,
ordinary text, normalization, deterministic order/ties, metadata retention, and failure limits,
including an unsafe reading-band policy.
The complete validation then passed all static contracts, Release compilation, the strict Dashboard
wall-clock stage, 485 unit-test results across 29 suites, 17/17 UI tests, and every selected
core-service coverage threshold. CSVExporter was the minimum selected result at 87.60% against the
required 85%. Four physical-only CloudKit probes remained explicit skips, and the ephemeral
`mindbudget-validation.dcltId/MindBudget.xcresult` bundle was removed by normal cleanup. The
preceding sandboxed invocation could not access CoreSimulator/DerivedData and stopped before an
Xcode test result existed; it is excluded as environment non-pass evidence.
C4C-04/C4C-05, physical OCR/accuracy, 60+ fixtures, 20-image stability, confirmation/persistence,
Production, distribution, and release remain blocked. `CHANGELOG.md` is unchanged because no
enabled customer behavior changed.

Independent review of PR #70 found no P1/P2 issue. Before merge, the owner accepted the optional
P3 ordering hardening: the rule array now states that a complete PAN must be removed before a
labelled last-four rule can consume its first group, and the sensitive-pattern table includes a
labelled, separated sixteen-digit case that fails if reordering leaves a twelve-digit remainder.
The exact review-fix source passed 7/7 at
`/private/tmp/MindBudget-C4C03-ReviewFix-Focused5.hKVLun/MindBudget.xcresult`. No production pattern,
customer surface, model/network boundary, or phase status changed; green hosted CI on the new head
remains required before merge.

## 2026-08-26 — C4C-03 reviewed merge closeout

Independent review found no P1/P2 issue on exact source head `92ed3a7`. The accepted P3 ordering
hardening records that the complete-card rule must precede the labelled-last-four rule and adds a
labelled separated sixteen-digit regression case. GitHub Actions run `32921913143` completed
successfully on that exact head, and PR #70 merged the local OCR/privacy substrate to `main` as
`d294cfb`.

DEC-COM-048 closes C4C-03 only. Receipt import remains disabled; C4C-04/C4C-05 remain blocked until
separate explicit owner entry and predecessor completion. The review's remaining P3 observations
stay bounded: continuous 20-plus-digit strings are outside the accepted 13–19 digit PAN shape,
spaced-mask forms belong in the C4C-05 fixture matrix, regex caching is an optional optimization,
and a future C4C-04 caller must execute Vision away from the main actor. No structured receipt
field, persistence, model/network use, Production, distribution, or release action occurred.

The documentation-only closeout branch passed the complete repository validation entry: every
static contract, Release compilation, the strict Dashboard wall-clock stage, 485 unit-test results
across 29 suites, all 17 UI tests, and every selected core-service coverage threshold passed.
CSVExporter remained the minimum selected coverage result at 87.60% against the required 85%.
Four physical-only CloudKit probes remained explicit skips. Normal cleanup removed the ephemeral
`mindbudget-validation.IyfM8i/MindBudget.xcresult` bundle after success.

PR #71 independent review found no P1/P2 issue and asked that the current-state memory point to the
next forward boundary rather than to this already-open closeout, plus an optional packet exit-text
refresh. Both are addressed: C4C-04 is the next forward packet but remains blocked until explicit
owner entry, and the stop conditions now distinguish C4C-02 acquisition from C4C-03 local OCR/
privacy. The product flag stays false and no phase, Production, distribution, or release authority
changes.

The money, network-egress, commercialization-document, and StoreKit-catalog gates plus
`git diff --check` all passed after the review fix. Hosted CI on the replacement exact head remains
required before merge; no new runtime or physical evidence is claimed.

## 2026-08-26 — C4C-04 deterministic structured extraction candidate

Goal: implement only C4C-04 after explicit owner entry, preserving the C4C-03 privacy type boundary
and stopping before customer wiring, confirmation, persistence, fixture accuracy, resource
stability, Production, or release work.

Completed: added deterministic merchant/date/total extraction and typed rejection states; integer-
only ISO exponent/locale/currency/scale/range validation; exact normalized merchant/date/Money
duplicate detection; and a line-item experiment whose production value is false. Added one optional
Foundation Models adapter that accepts only `ReceiptOCRDocument`, requests exact contiguous source
snippets, and remains subordinate to deterministic provenance and field validation. Deterministic
results survive model absence, timeout, invalid evidence/output, and model errors. No SwiftData,
CloudKit, log, telemetry, URLSession, HTTP(S), remote model, or customer path was added.

Evidence: the pre-review focused C4C-04 suite passed 16/16 at
`/private/tmp/MindBudget-C4C04-FocusedFinal.xcresult` on iPhone 17 Pro, iOS 26.5. It covers core fields,
locale punctuation, USD/JPY/KWD exponents, invalid scale/currency/range/date, missing and ambiguous
states without invented zero, exact duplicate identity, model provenance/precedence/fallback/
timeout, unavailable/invalid contexts, and default-off line items. The money, network-egress,
commercialization-document, and StoreKit-catalog gates plus `git diff --check` passed before the
complete repository validation. Independent review, hosted CI, and merge remain required; C4C-05
stays blocked.

The complete repository entry subsequently passed all static contracts, Release compilation, the
strict Dashboard wall-clock stage, 501 unit-test results across 30 suites, all 17 UI tests, and
every selected core-service coverage threshold. CSVExporter was the minimum selected result at
87.60% against the required 85%. Four physical-only CloudKit probes remained explicit skips. The
ephemeral `mindbudget-validation.hAXTHp/MindBudget.xcresult` bundle was removed by normal cleanup.
This result remains deterministic/simulator evidence and does not claim C4C-05 receipt accuracy,
physical capture/OCR, 20-image stability, confirmation/persistence, Production, distribution, or
release readiness.

PR #72 review requested two P2 corrections without changing the accepted packet. First, numeric
tokens within one total-evidence line now share the same fail-closed rule as separate evidence
lines: any parse failure rejects the field. Second, model supplementation is restricted to a
deterministic `.missing`; an `.accepted` or `.rejected` deterministic resolution is final. The
exact review-fix source passed 17/17 focused tests at
`/private/tmp/MindBudget-C4C04-ReviewFix-Focused.xcresult`. The new fixtures cover a valid and
invalid-scale amount on one line plus an ambiguous deterministic total that a model attempts to
replace. No C4C-05 matcher expansion, customer wiring, persistence, or feature enablement occurred.

The replacement exact source then passed `Scripts/validate.sh`: every static contract, Release
compilation, the strict Dashboard wall-clock stage, 502 unit-test results across 30 suites, all
17 UI tests, and every selected core-service coverage threshold passed. CSVExporter was the
minimum selected result at 87.60% against the required 85%. Four physical-only CloudKit probes
remained explicit skips. The ephemeral `mindbudget-validation.5DL4A2/MindBudget.xcresult` bundle
was removed by normal script cleanup. Hosted CI on the replacement head remains required before
merge; C4C-05 stays blocked and no physical receipt, fixture-accuracy, persistence, Production,
distribution, or release evidence is claimed.

## 2026-08-26 — C4C-04 reviewed remediation merge closeout

Initial PR #72 review found no P1 issue and two P2 fail-closed inconsistencies. Exact remediation
head `f2d249d` rejects a total evidence line if any numeric token fails parsing and permits the
optional on-device model to supplement only deterministic `.missing`; deterministic `.accepted`
and `.rejected` are final. The 17/17 focused suite and complete local validation passed, including
502 unit-test results across 30 suites, 17/17 UI tests, Release compilation, the strict Dashboard
wall-clock stage, all static contracts, and every selected coverage threshold.

Independent rereview approved exact remediation head `f2d249d`. GitHub Actions run `32946104780`
completed successfully on that exact head in 19m39s, and PR #72 merged the bounded ephemeral
structured-extraction implementation to `main` as `e6316fa`. DEC-COM-050 closes C4C-04 only.
`enableReceiptImport` remains false; C4C-05 remains blocked pending separate explicit owner entry;
the receipt Requirements and COM-C4C remain active.

The review's remaining accuracy-shape observations stay bounded to C4C-05: its 60-plus fixture
matrix must evaluate generic three-uppercase-letter currency markers and broad `total` substring
matching, while off-main Vision integration, physical OCR, 20-image stability, confirmation, and
persistence remain unproven. No Production, Archive/upload, tester, distribution, or release
action occurred. The documentation-only closeout source passed `Scripts/validate.sh`: every
static contract, Release compilation, the strict Dashboard wall-clock stage, 502 unit-test
results across 30 suites (491 passed and 11 explicit physical-only skips), all 17 UI tests, and
every selected core-service coverage threshold passed. CSVExporter remained the minimum selected
result at 87.60% against the required 85%. The script's ephemeral
`mindbudget-validation.TbfLO2/MindBudget.xcresult` bundle was removed by normal cleanup; a
read-only mirror at `/private/tmp/MindBudget-C4C04-closeout-final.xcresult` parsed as `Passed`
with zero failures and independently passed the coverage gate. Independent review, green hosted
CI, and merge remain required for the closeout branch.

## 2026-08-26 — C4C-05 verified-Pro local receipt candidate

Goal: after explicit owner entry, connect the reviewed C4C-02/03/04 substrates to one local
customer flow while proving that no unreviewed receipt field or intermediate can become durable.

Completed candidate work: `enableReceiptImport` is true; immutable Commerce access still hides the
entry from exact Free and unavailable authority. The new-expense form opens one local receipt
sheet for explicit PHPicker or camera selection. Image preparation and accurate Vision OCR execute
off-main; mandatory filtering precedes optional Apple on-device evidence selection; deterministic
validation remains authoritative. The bounded temporary JPEG is discarded before review.
Accepted merchant/date/total values only edit the form. The existing Save action alone writes an
ordinary expense with source `receiptImport`; no receipt image/OCR/model/duplicate evidence enters
SwiftData, CloudKit, logs, telemetry, or a network path.

Evidence so far: the four focused receipt suites pass together on iPhone 17 Pro, iOS 26.5. The new
matrix requires 60/60 exact supported USD/JPY/KWD fixtures and ten nonreceipts with zero accepted
totals, includes `Totally` plus generic uppercase-code regressions and spaced-mask privacy, proves
prefill leaves the database empty until Save, and processes 20 real JPEGs sequentially with one-or-
zero protected artifacts and zero cleanup residue. These are deterministic/simulator gates only.
Physical DataScanner capture, PHPicker selection, and resulting local OCR are still unproven, so
C4C-05 remains In Progress. Independent review, hosted CI, and merge remain required;
COM-C4C/receipt Requirements remain active, and Production/distribution remain blocked.

The exact candidate then passed the complete local entry. Focused result
`/private/tmp/MindBudget-C4C05-Focused.xcresult` reports 40/40 passed with no skip. Full result
`/private/tmp/MindBudget-C4C05-Full.xcresult` reports 508 unit results (497 passed and 11 explicit
opt-in/runtime skips), 17/17 UI tests, Release compilation, the strict 10,000-row Dashboard
wall-clock stage, every static contract, and every selected coverage threshold; CSVExporter is the
minimum selected result at 87.60% against 85%. The device inventory showed all three registered
physical iPhones offline, so this run records no physical DataScanner, PHPicker, or OCR pass. That
gate plus independent review, hosted CI, and merge remains open.

## 2026-08-26 — C4C-05 physical acquisition, OCR, and Save-boundary evidence

The owner connected `拉沙的iPhone` running iOS 26.6.1 to Xcode 27 beta 6 (`27A5252f`) and ran the
verified-Pro local receipt flow. Initial paper-invoice capture attempts rejected safely. A closed
`ReceiptImport` diagnostic reason code identified minor Vision geometry drift without logging any
receipt-derived content; the same investigation found that a 4032 x 3024 capture could evade the
edge-only thumbnail request and then exceed the separate prepared-pixel ceiling.

DEC-COM-052 keeps the existing caps and field authority: ImageIO's thumbnail edge is now derived
from both edge and pixel bounds, while only finite positive geometry within 0.005 of the unit square
is clamped. Material drift still rejects. The remediation result
`/private/tmp/MindBudget-C4C05-PhysicalRemediation.xcresult` passes 21/21 image-lifecycle and OCR
privacy tests.

The remediated DataScanner camera flow reached local review on the same device. Merchant/date were
accepted, while the uncertain total remained manual-review-only. Applying and then canceling wrote
no expense. A separate one-image PHPicker flow reached review and produced exactly one `$25.00`
expense only after explicit Save. This closes the mandatory physical DataScanner/PHPicker/local-OCR
and confirmation evidence without claiming population-wide accuracy or a passed automatic amount
for that invoice. Independent review, hosted CI, and merge remain open; C4C-05/COM-C4C and both
receipt Requirements are not Done, and Production/distribution remain blocked.

The same remediated candidate subsequently passed the exact complete repository entry at
`/private/tmp/MindBudget-C4C05-Final.xcresult`: 510 unit-test results across 31 suites (499 passed
and 11 explicit opt-in/runtime skips), 17/17 UI tests, Release compilation, the strict 10,000-row
Dashboard wall-clock stage, every static contract, and every selected coverage threshold. The
result bundle reports 527 total logical results, 516 passed, 11 skipped, and zero failed after UI
and parameterized cases are included. CSVExporter remains the minimum selected coverage result at
87.60% against 85%. A prior sandboxed attempt and transient Simulator Busy preflight remain
environmental non-passes and are not counted as evidence.

## 2026-08-27 — C4C-05 receipt capture and inline-review redesign

After the owner paused PR submission and supplied the authoritative receipt UI handoff,
DEC-COM-053 selected the recommended bounded option A. DataScanner remains the image-acquisition
authority with guidance disabled; a custom black capture surface adds one white shutter, an
always-white breathing frame, local-only badge, three-state torch, generic PHPicker control, and an
honestly disabled long-receipt slot. No green aligned state, automatic-crop promise, live rectangle
detection, AVCapture frame pipeline, or broad Photos permission was added.

Capture now enters an explicit local preview and then returns to the expense form. Recognition owns
a generation-protected form task; backgrounding, rescan, cancel, form dismissal, and replacement
invalidate it and discard temporary image state. Accepted fields apply only when the corresponding
form value is unchanged from recognition start. Progress, review, and failure are inline; manual
amount entry releases the temporary recognition Save gate; explicit Save remains the only durable
write. The first-use marker is local preference state and Delete All resets it.

The app target and focused receipt/settings suites compile and pass on the iOS simulator. The exact
redesigned source subsequently passed `Scripts/validate.sh` at
`/private/tmp/MindBudget-C4C05-Redesign-Final2.xcresult`: all static contracts, Release compilation,
the strict 10,000-row Dashboard wall-clock stage, 514 unit-test results across 31 suites, all 17 UI
tests, and every selected coverage threshold. The result summary contains 531 total tests, 520
passed, 11 explicit opt-in/runtime skips, and zero failed; CSVExporter remains the minimum selected
coverage result at 87.60% against 85%. No reviewed merge, C4C-05 Done, Production, distribution,
or release claim is made here.

## 2026-08-27 — C4C-05 production-path review remediation

PR #74 independent review exposed a real test-boundary defect: two central invariants were proved
through an unreachable unconditional prefill helper, not the method invoked after local recognition.
It also demonstrated that value equality loses user intent after edit-then-return-to-starting-value,
and found collapsed failure reasons, access gates reported as storage faults, destructive inactive
handling, and unscoped late temporary-image cleanup.

DEC-COM-054 deletes the dead helper and makes the live generation the only tested application path.
Amount, merchant, and date retain edit ownership for the entire generation. Failure presentation is
typed and recovery-specific. Inactive scenes mask without cleanup, true background cancels and
discards, and artifact identity prevents stale cleanup from deleting a replacement. The suggested
change to record `receiptImport` when all accepted fields remain user-owned is rejected: provenance
describes a recognized field contribution to the stored expense, so no contribution remains
truthfully `.manual`.

`xcodebuild build-for-testing` succeeds for the app, unit-test, and UI-test targets under final
Xcode 26.6. The focused iOS 26.5 simulator bundle
`/private/tmp/MindBudget-C4C05-ReviewFix-Focused2.xcresult` passes 22/22 tests across
`ReceiptImportIntegrationTests` and `ReceiptImageLifecycleTests`, with no failure or skip. The prior
Designed-for-iPhone-on-Mac test attempt stopped at provisioning and is excluded from evidence.
The exact remediated source then passed `Scripts/validate.sh` at
`/private/tmp/MindBudget-C4C05-ReviewFix-Final.xcresult`: every static contract, Release
compilation, the strict 10,000-row Dashboard wall-clock stage, 522 unit-test results across 31
suites, all 17 UI tests, and every selected coverage threshold passed. The bundle reports 539
logical results, 528 passed, 11 explicit opt-in/runtime skips, and zero failed; CSVExporter remains
the minimum selected coverage result at 87.60% against 85%. Independent rereview, hosted CI, and
merge remain required; C4C-05/COM-C4C and both receipt Requirements remain In Progress, and
Production/distribution remain blocked.

## 2026-08-27 — C4C-05 P3 review-maintenance follow-up

The rereview's three P3 observations are closed without changing product scope. The recognition
test helper now returns immediately on completion and reports a bounded timeout explicitly. The
orphaned `receipt.error.unreadable` key is removed; both full-screen and inline presentation share
surface-neutral `receipt.failure.unreadable.*` keys. The three receipt-prefill fields are
`private(set)`, with amount, merchant, and date user-input methods forming the compiler-enforced
mutation boundary for edit ownership.

A restricted CoreSimulator attempt failed before execution and is excluded. The unrestricted iOS
26.5 simulator rerun passes 76/76 tests across the receipt integration and Phase 3/4/5 suites at
`/private/tmp/MindBudget-C4C05-P3Fix-Focused2.xcresult`. C4C-05/COM-C4C remain In Progress pending
rereview, hosted CI, and merge; Production/distribution remain blocked.

## 2026-08-27 — C4C-05 merge calibration and post-merge exact-delta closeout

Independent review approved remediation head `8607356`, including DEC-COM-054's production-path
changes, and raised three nonblocking P3 observations. Final maintenance head `81cd107` applied
those observations and passed GitHub Actions run `33035427257` in 26m06s; PR #74 merged the
verified-Pro local receipt flow to `main` as `d751ff4` without a pre-merge rereview. During PR #75's
2026-08-27 closeout review, the independent reviewer read that exact maintenance delta and
confirmed all three P3 fixes correct.

DEC-COM-055 marks C4C-05 and COM-C4C Done on the reviewed merge, the recorded deterministic
60-receipt/10-nonreceipt and 20-image matrices, zero-leak coverage, complete local validation, and
physical iOS 26.6.1 DataScanner/PHPicker/local-OCR plus cancel-versus-Save evidence. The uncertain
paper-invoice total remains manual-review-only and is not rewritten as an automatic-recognition or
population-accuracy pass.

This documentation-only closeout changes no Swift, schema, entitlement, egress, persistence, or
customer behavior. COM-C5 remains unopened pending explicit owner entry and accepted first-party
telemetry conflict resolution. Production, Archive/upload, tester, distribution, and release remain
unauthorized. Independent review, green hosted CI, and merge remain required for this closeout
branch.

The closeout branch then passed `Scripts/validate.sh` at
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.3SiQ1W/MindBudget.xcresult`:
every static contract, Release compilation, the strict 10,000-row Dashboard wall-clock stage, the
complete unit-test execution, all 17 UI tests, and all selected coverage thresholds passed.
`CSVExporter.swift` remains the minimum selected coverage result at 87.60% against 85%. The
validator removed its temporary result bundle after the successful run.

## 2026-08-27 — C5-01 dormant typed telemetry client candidate

The owner explicitly entered COM-C5 after the reviewed C4C-05 closeout merged through PR #75 as
`82ef0fa`. DEC-COM-056 opens only C5-01. The implementation adds a closed `TelemetryEvent` enum and
exact upload/delete envelopes, default-off state, cryptographically random rotating pseudonyms,
opt-out unlinkability, retained deletion proofs, a four-generation ceiling, a 256-event encrypted
queue, 20-event same-generation batches, serialized local mutation across actor suspension, bounded
backoff, and sticky corrupt-state failure. AES-GCM state uses a device-only Keychain key, atomic
read-back-verified persistence, file protection, backup exclusion, and a 256 KiB bound.

The production tree intentionally contains no `TelemetryClient` construction, capture call, URL,
receiver, or real transport. `UnavailableTelemetryTransport` is the only default, and the new
static contract rejects schema drift, selected content/financial authority types, live egress, and
production construction. Current collection and transmission therefore remain zero; no customer
setting, App Privacy answer, endpoint, server TTL, or deletion-service claim is made. C5-02 through
C5-04, Production, and distribution remain blocked.

Focused simulator execution passes 13/13 deterministic telemetry tests, including a gated
transport-lane regression that proves concurrent flushes cannot upload the same batch twice. The first owning
validation attempt was sandbox-blocked from CoreSimulator before trustworthy execution and is an
environmental non-pass. The unrestricted `Scripts/validate.sh` rerun passes all static contracts,
Release compilation, the strict 10,000-row Dashboard wall-clock stage, 530 unit tests across 32
suites, all 17 UI tests, and every selected coverage threshold. Four opt-in physical CloudKit
probes are explicit skips; `CSVExporter.swift` remains the minimum selected coverage result at
87.60% against 85%. The validator deleted its temporary result bundle after completion.
Independent review, hosted CI, and merge remain required.

## 2026-08-27 — PR #76 C5-01 deletion and gate remediation

Independent review correctly identified that corrupt persistence made the encrypted file and
device-only key impossible to clear, and that a grouped deletion request contradicted an
unqualified unlinkability claim. DEC-COM-057 keeps corruption sticky for collection/overwrite but
allows local file/key deletion without authenticated parsing, returning
`.deletedLocallyWithoutRemoteProofs` rather than claiming remote deletion. Upload-envelope
pseudonyms remain non-reused and ungrouped across opt-out/re-enable; complete deletion deliberately
groups the retained proof set so C5-02 can avoid partial deletion, with a new prohibition on
persisting, logging, or reusing that association.

Identity retirement no longer performs the unrelated capacity check; creation alone owns it. The
four-generation re-enable failure is recorded for C5-04 customer guidance, and in-flight upload
cancellation remains an explicit C5-02 transport decision. `check-telemetry-contract.sh` replaces
the fail-open `rg` conditional with a status-aware `grep` scan, verifies required tools/source roots,
and runs positive/negative schema, envelope, construction, and incomplete-scan fixtures. Focused
iOS 26.5 simulator execution passes 17/17 with no failure or skip, including an encrypted corrupt
file plus at-rest-key deletion test. The owning unrestricted `Scripts/validate.sh` run then passed
every static contract, Release compilation, the isolated strict 10,000-row Dashboard benchmark,
534 unit tests across 32 suites, all 17 UI tests, and every selected coverage threshold. Four
physical CloudKit probes remained explicit skips; `CSVExporter.swift` was the minimum selected
result at 87.60% against 85%. The validator removed
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.OzAGSt/MindBudget.xcresult`
after success, so the path is an execution pointer rather than a durable artifact. Exact-head
rereview, hosted CI, and merge remain required. C5-02 through C5-04 and all Production/distribution
actions remain blocked.

## 2026-08-27 — PR #76 final default-off and failure-classification remediation

Final review found that calling `setCollectionEnabled(false)` on missing state still wrote an
encrypted `.disabled` state and created the device-only key. DEC-COM-058 makes repeated Disable a
true zero-write no-op, changes the default policy calendar from UTC to the user's
`Calendar.autoupdatingCurrent`, returns `.persistenceFailed` when a remote upload resolution cannot
be committed locally, and records the C5-02 requirement for idempotent event acceptance and proof
deletion after local acknowledgement/cleanup failure.

The retry test now captures successfully while transport backoff is active, and the telemetry gate
anchors every current test including the two previously omitted names. Focused iOS 26.5 simulator
execution passes 21/21 with no failure or skip. The restricted full-validation attempt lost
CoreSimulator/DerivedData access before trustworthy execution and is an environmental non-pass.
The unrestricted rerun passed every static contract, Release compilation, the isolated strict
10,000-row Dashboard benchmark, 538 unit tests across 32 suites, all 17 UI tests, and every selected
coverage threshold. Four physical CloudKit probes were explicit skips; `CSVExporter.swift` remained
the minimum selected result at 87.60% against 85%. The validator removed its temporary
`mindbudget-validation.g8bqhg/MindBudget.xcresult` bundle after success. Hosted CI and merge remain
required. No production construction, call site, endpoint, transport, telemetry collection, or
egress was added; C5-02 through C5-04 and Production/distribution remain blocked.

## 2026-08-28 — C5-01 reviewed-merge documentation closeout

Independent review approved exact final PR #76 head `d937dc8`. GitHub Actions run `33085630481`
completed successfully on that head, and PR #76 merged to `main` as `68304ad`. DEC-COM-059 marks
C5-01 Done while keeping COM-C5 In Progress.

The closeout records only the dormant local capability. No production `TelemetryClient`
construction, capture call, URL, endpoint, receiver, transport, customer setting, App Privacy
answer, collection, or egress was added. C5-02 awaits separate explicit owner entry; C5-03/C5-04,
Production, distribution, and release remain blocked. This branch changes documentation and the
commercialization state gate only and still requires its own independent review, green hosted CI,
and merge.

The closeout branch then passed `Scripts/validate.sh`: every static contract, Release compilation,
the strict 10,000-row Dashboard benchmark, 538 unit tests across 32 suites, all 17 UI tests, and
every selected coverage threshold passed. Four opt-in physical CloudKit probes were explicit
skips; `CSVExporter.swift` remained the minimum selected result at 87.60% against 85%. The
validator removed its temporary `mindbudget-validation.k5zkq3/MindBudget.xcresult` bundle after
success, so the name is an execution pointer rather than a durable artifact.

## 2026-08-28 — C5-02 deletion-safe minimal ingest candidate

The owner explicitly entered C5-02. DEC-COM-060 accepts three exact compile-time environment hosts
and a first-party Worker/D1 receiver while preserving the C5-01 default-off boundary. The Worker
rejects unknown hosts, paths, methods, query strings, credentials, cookies, content encodings,
duplicate JSON keys, malformed UTF-8, unknown schema/environment/event/action/outcome values,
oversized bodies, oversized batches, invalid UUIDs, and unbounded timestamps. Upload accepts at
most 20 events/32 KiB and complete deletion accepts at most four proofs/2 KiB. Responses are empty
and status-coded; no content or supplied diagnostic text is reflected.

D1 uniqueness and transactions, rather than edge rate limiting, are acceptance authority. An
identical event retry is idempotent; reuse of an event UUID with any changed fact is atomically
rejected. A valid complete-delete request verifies all proofs before deleting events/identities and
writing independent tombstones, never persists the request grouping, and makes a later matching
upload accepted-but-discarded. Events, identities, and tombstones have an indexed maximum
90 x 24-hour UTC lifetime, with bounded 1,000-row hourly cleanup. Invocation logs are disabled;
sampled custom logs contain only closed component/environment/route/reason codes. IP/pseudonym
limiters are transient abuse buffers and are not correctness authority.

The iOS adapter uses an ephemeral session, no cookies/credentials/cache, exact host/path matching,
redirect rejection, bounded streaming bodies, checked integer date components, and typed empty
response handling. Opt-out best-effort cancels the active upload before identity retirement and
local commit; an edge-accepted request is not falsely claimed recalled. Four added deterministic
tests cover cancellation, exact Development encoding, environment/response fail-closed behavior,
and Retry-After plus proof deletion. The focused telemetry suite passes 25/25. Worker verification
passes 26/26 against real local D1; type generation, TypeScript checking, three environment
dry-runs/startup checks, and `npm audit --audit-level=high` (zero vulnerabilities) pass.

Development D1 `2faff8ac-de17-4fd0-aaa7-546bd1902e74` was migrated and Worker version
`1c162a57-8789-4f7f-9fec-f2c484e9f4f2` deployed at the exact Development host. The live probe
returned 202 for an upload, 202 for its identical retry, 409 for the same event ID with changed
`appVersion`, 204 for complete deletion, and 202 for a matching late upload that was discarded.
The final read is zero events, zero identities, and two independent tombstones. Staging D1
`776d171d-ec10-4a90-9235-b537e063e04b` is isolated but intentionally unmigrated and undeployed.
Production has no provisioned D1 and no Worker deployment. No customer setting, construction,
capture, App Privacy change, Production, distribution, or release is authorized; C5-03/C5-04,
independent review, hosted CI, and merge remain open.

The first full-validation invocation stopped before Xcode build because the system developer
directory selected Command Line Tools; it is an environmental non-pass. Rerunning with explicit
Xcode 27 beta 6 passed every static contract, Release compilation, the strict 10,000-row Dashboard
benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every selected coverage threshold.
Four opt-in physical CloudKit probes remained explicit skips. `CSVExporter.swift` was the minimum
selected result at 87.60% against 85%. The validator removed the temporary
`mindbudget-validation.1f3FOS/MindBudget.xcresult` bundle after success, so it is an execution
pointer rather than a durable artifact. No CHANGELOG entry is added because the transport stays
unconstructed and there is no customer-visible behavior.

## 2026-08-28 — PR #78 deletion timing, HTTP metadata, and cleanup remediation

Independent review identified three contract gaps in the dormant C5-02 candidate. Exact
millisecond tombstone expiry shared by proofs in one delete request preserved a recoverable
request association; URLSession could add build/OS/locale metadata outside the closed wire schema;
and one bounded cleanup batch per hour did not prove the stated maximum retention under backlog.
DEC-COM-061 uses an earlier-or-equal UTC-day tombstone bucket shared across independent requests,
fixes `User-Agent: MindBudget`, suppresses `Accept-Language`, rejects variable values server-side,
and repeats bounded 1,000-row cleanup transactions until drained. The strict parser now accepts
only JSON whitespace, Swift explicitly encodes deletion secrets as base64, and the dead event-shape
precheck is removed. HTTP 404/405/421 remain typed failures while the adapter is dormant; C5-04
must make them terminal before constructing a production transport.

The Worker suite passes 32/32 against local D1; generated types, `tsc --noEmit`, three environment
dry-runs/startup checks, and high-severity audit all pass with zero vulnerabilities. Focused iOS
telemetry execution passes 25/25 with no failure or skip. The first full-validation attempt passed
static gates but stopped at Release link when Xcode transiently reported its own `clang` executable
missing; immediate reinspection found the executable, so that attempt is an environmental non-pass.
The clean Xcode 27 beta 6 rerun passed every static contract, Release compilation, the strict
10,000-row Dashboard benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every selected
coverage threshold. Four opt-in physical CloudKit probes remained explicit skips;
`CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The validator deleted
its temporary `mindbudget-validation.Qwp8O6/MindBudget.xcresult` bundle after success.

The currently deployed Development version remains the pre-remediation candidate until the owner
explicitly authorizes a Development-only redeploy and live probe. The adapter remains unconstructed,
collection/capture and customer egress remain zero, and C5-02 stays pending that exact-source probe,
rereview, hosted CI, and merge. Staging/Production, C5-03/C5-04, App Privacy, distribution, and
release remain blocked.

## 2026-08-28 — C5-02 reviewed-merge documentation closeout

Independent review approved exact PR #78 remediation head `72abf4b` and confirmed both P1, both P2,
and two of three P3 findings were closed with targeted regressions. The fixed-endpoint 404/405/421
terminal-failure P3 remains deferred to C5-04. GitHub Actions run `33176551566` completed
successfully on that head, and PR #78 merged it to `main` as `4715054`. DEC-COM-062 closes only
C5-02 on this evidence.

The closeout preserves the dormant boundary. `UnavailableTelemetryTransport` remains the default,
no production `TelemetryClient` is constructed, no capture call exists, and customer telemetry
collection/egress remain zero. The earlier Development deployment/probe is not relabeled as exact
DEC-COM-061 source evidence; Staging remains unmigrated/undeployed and Production remains
unprovisioned/undeployed. C5-03 now awaits a separate explicit owner entry, while C5-04, App Privacy
changes, Production, distribution, and release remain blocked.

This documentation-only branch changes no Swift, Worker, schema, endpoint, entitlement,
persistence, control, or customer-visible behavior and therefore adds no CHANGELOG entry. It
passed every static contract, Release compilation, the isolated strict 10,000-row Dashboard
benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every selected coverage threshold.
Four opt-in physical CloudKit probes were explicit skips; `CSVExporter.swift` was the minimum
selected result at 87.60% against the 85% floor. The validator deleted its temporary
`mindbudget-validation.Bj3fdn/MindBudget.xcresult` bundle after success. Independent review, green
hosted CI, and merge remain required for this documentation closeout.

PR #79 independent review corrected two evidence-boundary details. The network-egress matrix now
labels the 0-event/0-identity/2-tombstone Development probe as evidence from pre-remediation Worker
`1c162a57-8789-4f7f-9fec-f2c484e9f4f2`, not a probe of DEC-COM-061 source. DEC-COM-062 and both
session tracks now record two closed P3 findings and the third, fixed 404/405/421 terminal handling,
as deferred to C5-04. CI_BASELINE now records Xcode 27.0 beta 6 (`27A5252f`) and the iOS 26.5
iPhone 17 Pro simulator for the closeout validation. No runtime or deployment action occurred.

## 2026-08-29 — C5-03 deterministic metrics and immutable evidence candidate

The owner explicitly entered C5-03. DEC-COM-063 accepts a read-only D1 receipt-funnel query and an
offline evidence-bundle builder while retaining the C5-01/C5-02 dormancy boundary. The query is
not imported by `src/index.ts`, has no HTTP route, performs no write, and returns only four aggregate
counts for one exact app version and a bounded half-open UTC window. A pseudonym generation counts
once per ordered completed receipt step, so the unit is neither a customer nor a device and cannot
be combined with an App Store denominator as a participation rate.

The builder's nine metric identifiers and three source families are closed. App Store Analytics
inputs remain owner-supplied exports; telemetry inputs are aggregate-only; the voluntary
`c5-survey-v1` instrument has two fixed bilingual questions, closed answers, and no free text or
product data. Every row carries exact numerator/denominator/sample size, explicit availability,
one source-export SHA-256 digest where evidence exists, and a 95% Wilson interval rounded outward
to integer basis points. Unknown keys, duplicate metrics, missing source artifacts, impossible
counts, invalid timestamps, excessive windows, source substitution, and output overwrite all fail
closed. Canonical output uses sorted keys, a same-directory `0600` temporary file, an atomic
no-overwrite hard link, and read-back verification.

The Worker suite passes 35/35 cases against local D1. Six separate Node contract tests prove fixed
Wilson vectors, deterministic sorted output, availability semantics, source binding, chronology,
window limits, and immutable CLI output. Generated types, `tsc --noEmit`, Development/Staging/
Production dry-runs and startup checks, and `npm audit --audit-level=high` with zero vulnerabilities
also pass. The dedicated static gate proves the query/evidence code remains absent from the live
Worker entry and rejects network, identifier, content, and write-capable shapes.

The owning full validation used Xcode 27.0 beta 6 (`27A5252f`) with the iOS 26.5 iPhone 17 Pro
simulator and passed every static contract, Release compilation, the isolated strict 10,000-row
Dashboard benchmark, 542 unit tests across 32 suites, all 17 UI tests, and every selected coverage
threshold. Four opt-in physical CloudKit probes were explicit skips; `CSVExporter.swift` remained
the minimum selected result at 87.60% against the 85% floor. The validator deleted
`mindbudget-validation.0CrPs7/MindBudget.xcresult` after success.

No Development redeploy or probe occurred. No customer telemetry, survey responses, App Store
exports, real metric values, representative sample, threshold pass, G1 decision, Production,
App Privacy update, distribution, or release is claimed. `UnavailableTelemetryTransport` remains
the app default with zero production construction/capture call sites. C5-03 awaits independent
review, hosted CI, and merge; C5-04 remains blocked.

## 2026-08-29 — Remediate C5-03 exact-segment coverage review

PR #80 independent review correctly identified that root coverage summed exact segments across
Development/Staging/Production and could double-count overlapping `ALL` and specific storefront
populations. DEC-COM-064 adopts the stronger resolution: the evidence bundle has no root or
cross-segment coverage roll-up. Completeness is reported only inside one exact environment,
app-version, storefront, and device-family segment, and any later G1 citation must name that segment.

The non-blocking weak-sample observation is also made visible without inventing an owner threshold.
Every segment now reports `widestConfidenceIntervalBasisPoints`, or `null` when no metric is
available. A one-of-one sample therefore remains `available` under the existing computation
contract while visibly carrying the 7,935-basis-point 95% Wilson interval width. Eight offline
contract tests cover mixed environments, overlapping `ALL`/`USA` storefronts, one-of-one evidence,
and no-available evidence in addition to the original canonicalization and fail-closed cases.

The remediated Worker package passes 35/35 Vitest cases against local D1, eight evidence-contract
tests, generated bindings, TypeScript checking, Development/Staging/Production dry-runs and startup
checks, and the high-severity audit with zero vulnerabilities. Full validation used Xcode 27.0 beta
6 (`27A5252f`) with the iOS 26.5 iPhone 17 Pro simulator and passed every static contract, Release
compilation, the strict 10,000-row Dashboard benchmark, 542 unit tests across 32 suites, all 17 UI
tests, and every selected coverage threshold. Four opt-in physical CloudKit probes remained
explicit skips; `CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The
validator deleted `mindbudget-validation.MjKE14/MindBudget.xcresult` after success. No deployment,
probe, actual evidence bundle, metric conclusion, G1 decision, App Privacy change, distribution, or
release is claimed. C5-03 remains pending exact-head rereview, hosted CI, and merge; C5-04 remains
blocked.

## 2026-08-29 — C5-03 reviewed merge and documentation closeout

Independent review approved head `4ea7cd9` and raised one P2 cross-segment coverage issue plus one
P3 weak-sample-visibility issue. Remediation head `0c61427` applied both by removing root
cross-environment/storefront coverage and adding the exact-segment widest-interval
evidence-strength field. GitHub Actions run `33211270363` completed successfully, and PR #80
merged it to `main` as `a587f42` without a pre-merge rereview. PR #81's post-merge closeout review
read that exact remediation delta and confirmed both fixes. DEC-COM-065 closes C5-03 on that
evidence.

The closeout does not convert dormant computation into collected evidence. The read-only D1
aggregate remains unexposed, the immutable builder remains offline, the production app still uses
`UnavailableTelemetryTransport`, and there are zero production client constructions/capture calls
and zero customer telemetry egress. No App Store export, voluntary survey response, production
funnel sample, real evidence bundle, metric result, threshold pass, or G1 decision is claimed.
C5-04 now awaits a separate explicit owner entry and still owns control/disclosure, capture audit,
App Privacy, terminal fixed-endpoint behavior, operational TTL/delete proof, final-binary traffic,
and activation. COM-C5 remains In Progress; Staging/Production, distribution, and release remain
unauthorized.

This documentation-only branch changes no Swift, Worker, D1 schema, route, persistence,
entitlement, network behavior, or customer-visible behavior and therefore adds no CHANGELOG entry.
Its own independent review, green hosted CI, and merge remain required.

The closeout branch passed `Scripts/validate.sh` with Xcode 27.0 beta 6 (`27A5252f`) on the iOS
26.5 iPhone 17 Pro simulator. Release compilation, 35/35 local-D1 Worker tests, eight C5
evidence-contract tests, 542 unit tests across 32 suites, all 17 UI tests, the strict 10,000-row
Dashboard benchmark, and every selected coverage threshold passed. Four opt-in physical CloudKit
tests were explicit skips. `CSVExporter.swift` remained the minimum selected coverage result at
87.60% against the 85% floor. The validator removed
`mindbudget-validation.1rJYdA/MindBudget.xcresult` after success; the name is only an execution
pointer, not a durable artifact or new release proof.

## 2026-08-29 — Remediate PR #81 closeout provenance and phase-gate review

PR #81 review found the closeout chronology inaccurate: independent review covered implementation
head `4ea7cd9`, not remediation head `0c61427`. The former review raised one P2 cross-segment
coverage issue and one P3 weak-sample-visibility issue; `0c61427` applied both, passed run
`33211270363`, and merged through PR #80 as `a587f42` without pre-merge rereview. PR #81's
post-merge review read the exact remediation delta and confirmed both fixes.

All ten current-state/evidence documents now retain that chronology and the exact C5-04 explicit
owner-entry boundary individually. The gate rejects future claims that `0c61427` received
pre-merge review. The phase-unqualified `Status: **Implementation complete pending independent
review.**` grep is removed because `commercialization_phase_states.py` already associates Status
with its heading; its self-test now explicitly accepts C5-03 Done alongside a future C5-04 pending
review state. Static money, egress, commercialization-document, StoreKit 13/13, C5 evidence 8/8,
parser self-test, and `git diff --check` pass. No runtime, evidence, G1, deployment, or release
boundary changed; hosted CI and exact-head rereview remain required.

## 2026-08-29 — C5-04 controlled telemetry activation candidate

The owner explicitly entered C5-04. DEC-COM-066 authorizes only one fixed, compile-time isolated
client/transport factory behind a bilingual default-off Privacy control. Collection creates no
state before confirmation, remains unable to affect product behavior, and captures only the closed
events audited in `C5_TELEMETRY_CAPTURE_AUDIT.md` from three named production files. No amount,
merchant/category/note text, receipt/OCR/model evidence, StoreKit/CloudKit identifier, locale,
device/advertising identifier, or caller-defined string can enter the schema.

The implementation adds bounded foreground lifecycle, explicit Retry, durable non-retrying
404/405/421 policy failures, disable/delete guidance, and proof-authenticated remote deletion before
app-wide financial deletion proceeds. App Privacy declares Product Interaction and a conservative
rotating Device ID as unlinked, non-tracking Analytics. The separate operations runbook limits
publish/probe/rollback and closed monitoring to Development; Staging/Production and release remain
unauthorized.

The focused simulator suite passed 47/47 tests with Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5
iPhone 17 Pro simulator, and the Worker passed 35/35 local-D1 tests, eight evidence tests, generated bindings,
TypeScript, all three dry-runs/startup checks, and the high-severity audit. The first sandboxed
simulator attempt failed CoreSimulator access and is not evidence. No current-source Worker deploy
or live probe occurred because uploading source to Cloudflare Development still requires explicit
authorization in this run. C5-04/COM-C5 remain In Progress pending that evidence, exact-head review,
green hosted CI, and merge; no G1 or distribution claim is made.

## 2026-08-29 — C5-04 final local verification and self-review hardening

Final self-review made the activation boundary more explicit before independent review. Pro
presentation telemetry is paired per visible interval. Telemetry deletion commits opt-out, queue
removal, identity retirement, and retry-state clearing before the remote request; a remote failure
retains proofs and prevents re-enablement until the user explicitly retries Delete. The live
factory is nonthrowing at the application boundary: missing application-support storage or an
invalid app-version string resolves to an unavailable service, so telemetry cannot block local
budgeting, while app-wide Delete All still fails closed rather than falsely claiming telemetry
cleanup. The bilingual Privacy surface remains default off and its UI test now asserts the exact
never-collected disclosure through a label predicate within XCUITest's query limits.

The final focused `TelemetryClientTests` plus `Phase6FeatureTests` command passed all 48 declared
tests. The exact current-source full validation used Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5
iPhone 17 Pro simulator and passed every static contract, Release compilation, 35/35 local-D1
Worker tests, all eight immutable-evidence tests, 550 unit tests across 32 suites, all 17 UI tests,
and every selected coverage threshold. Four opt-in physical CloudKit probes were explicit skips;
`CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The validator deleted
`mindbudget-validation.XKvHyp/MindBudget.xcresult` after success, making the name an execution
pointer rather than a durable artifact.

The first strict wall-clock attempt measured 661.598333 milliseconds for the isolated 10,000-row
Dashboard benchmark against the 500-millisecond ceiling on this loaded host. That result remains a
performance non-pass. The final correctness run explicitly used
`MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK=1`; it is not represented as a strict performance pass. An
intermediate full run stopped after identifying the overlong UI-test query and is excluded from
evidence.

No current-source Cloudflare Development deployment/probe occurred because remote source upload
still requires separate explicit authorization. Staging and Production remain untouched.
C5-04/COM-C5 therefore remain In Progress pending Development endpoint/TTL/delete evidence,
exact-head independent review, green hosted CI, and merge. No G1, distribution, or release claim is
made.

## 2026-08-29 — PR #82 review remediation: local-first deletion and controlled performance evidence

Independent review identified a local-first contract violation: optional telemetry remote deletion
could return before `DataActor.deleteAllUserData()`, leaving the customer's local financial records
intact during ordinary network, endpoint-policy, or unavailable-service failure. DEC-COM-067
supersedes that part of DEC-COM-066. App-wide Delete All still stops capture, commits opt-out/queue
removal, and attempts authenticated telemetry deletion first, but `.failed`, `.terminalFailure`,
and `.unavailable` results now preserve proofs for the separate Privacy retry and continue the
authoritative local erase. A distinct completed-with-pending-telemetry state and bilingual copy
report the remaining remote uncertainty without misrepresenting the local result.

The parameterized regression covers all three failure classes and confirms zero local model counts,
reset preferences, a retained identity proof, and exact notification/search/telemetry ordering. The
focused Phase 6 suite passed all 16 declared tests. Static money, egress, commercialization,
StoreKit 13/13, telemetry, and diff checks passed.

The earlier 661.598333-millisecond strict Dashboard attempt remains a non-pass, but the review's
request for evidence replaced its unsupported loaded-host attribution. With Xcode 27.0 beta 6
(`27A5252f`), the iOS 26.5 iPhone 17 Pro simulator, parallel testing disabled, and identical
three-repetition commands, both this remediation branch and detached `origin/main` passed the
500-millisecond assertion 3/3. The exact-source full validator also ran without the wall-clock skip
and passed every static contract, Release, 35/35 Worker tests, eight evidence tests, the strict
benchmark, 550 unit tests across 32 suites, 17/17 UI tests, and all selected coverage thresholds.
Four physical CloudKit probes were explicit skips; minimum selected coverage remained
`CSVExporter.swift` at 87.60% against 85%. The validator removed
`mindbudget-validation.LO2cps/MindBudget.xcresult` after success. No remote deploy/probe, G1,
Staging/Production action, distribution, or release claim changes; exact-head rereview, hosted CI,
and merge remain required.

### C5-04 reviewed product merge calibration — 2026-08-29

Independent review approved the deletion-order remediation on exact head `2c1cebe` within its
declared scope; GitHub Actions run `33233846430` completed successfully on that exact head; and PR
#82 merged the product capability to `main` as `28d9eae`. The review excluded the privacy
manifest, AddExpense/Pro capture sites, `TelemetryService`, and operations runbook. DEC-COM-068
records the exact source/run/merge facts without expanding that review scope or treating a source
merge as operational evidence; PR #83 closeout review is explicitly asked to inspect those four
surfaces.

The closeout updates only documentation and the commercialization-document gate. C5-04 and
COM-C5 remain In Progress solely because the current source has not been published to the
Development Worker and the endpoint/monitoring/TTL/delete-idempotency sequence has not been run.
The earlier Worker `1c162a57-8789-4f7f-9fec-f2c484e9f4f2` evidence remains explicitly historical.
No remote deployment, D1 mutation, customer collection, App Store Connect answer, evidence bundle,
G1 decision, Staging/Production action, distribution, or release is claimed.

This exact closeout source passed `Scripts/validate.sh` with Xcode 27.0 beta 6 (`27A5252f`) on the
iOS 26.5 iPhone 17 Pro simulator. Release compilation, 35/35 local-D1 Worker tests, all eight C5
evidence tests, the strict 10,000-row Dashboard benchmark, 550 unit tests across 32 suites, 17/17
UI tests, and every selected coverage threshold passed. Four opt-in physical CloudKit probes were
explicit skips; `CSVExporter.swift` was the minimum selected result at 87.60% against 85%. The
validator deleted `mindbudget-validation.bKKG10/MindBudget.xcresult` after success; it is an
execution pointer, not a durable artifact.

### C5-04 closeout review-scope and retry-boundary correction — 2026-08-29

PR #83 review found that the first closeout draft overstated PR #82's independent-review coverage
and that one checklist line could be read as if the still-open TTL/delete/idempotency probe were
complete. The task list now keeps source merge facts separate from the unchecked Development
probe, and every current-state description scopes review to the deletion-order remediation. PR
#83's reviewer is explicitly asked to inspect `PrivacyInfo.xcprivacy`, the AddExpense and Pro
capture sites, `TelemetryService` in `TelemetryClient.swift`, and the operations runbook.

The same review carried forward two nonblocking retry questions. Source inspection confirms that
`TelemetryService.stop()` cancels only drain/retry task handles and does not destroy the client or
its retained proofs, so `deleteAllTelemetry()` remains callable on the same service. Delete All
does reset `firstLaunchCompleted`; a person with a pending remote telemetry deletion must complete
onboarding again before Privacy & Security > Product Analytics is reachable. The runbook and
privacy notes now state that manual reachability boundary rather than implying an immediate retry
surface.

## 2026-08-29 — Session 177 — Run the current-source Development telemetry proof

Goal: Close only C5-04's authorized Development operational-evidence gap without touching
Staging/Production, customer data, G1, App Store Connect, final-binary traffic, distribution, or
release.

Actions: Synced `main` through PR #83 merge `becb020`, whose exact head `e6bbd3f` passed run
`33242024609`. Read the Cloudflare/Wrangler deployment guidance and C5 runbook. `npm ci` found zero
vulnerabilities; `npm run check` passed generated bindings, typecheck, 35/35 Worker tests, 8/8
evidence-contract tests, all three dry-runs, and all three startup checks under Wrangler 4.127.0.
Read-only preflight confirmed account `3f5394e0ef5a531c63c0ceaa74262e0d`, the exact Development
Worker/D1, prior version `1c162a57-8789-4f7f-9fec-f2c484e9f4f2`, and no pending migration. After
the owner's explicit confirmation, published source `becb020` as Development version
`003c66fa-a57c-4b6a-a8d7-3f75b14cc716` / deployment
`4e18af19-a98a-4a6d-bf4c-38e587a1b754`.

Evidence: A disposable synthetic identity/event/32-byte secret produced only the bounded
transcript 202/0, 202/0, 409/0, 204/0, 202/0, 204/0. Aggregate D1 checks proved one event and
identity with exact `7776000000`-millisecond TTL, one earlier-or-equal UTC-day deletion tombstone,
no late-upload resurrection, and exact removal of the probe tombstone. The synthetic final counts
were 0/0/0; whole-D1 final counts were 0 events, 0 identities, and the same 2 historical
pre-remediation tombstones. No secret, request body, row, customer identifier, or IP was recorded.
No rollback was needed.

Result: DEC-COM-069 records a truthful Development-only operational-evidence candidate. C5-04 and
COM-C5 remain In Progress pending independent review, hosted CI, and merge. Every later environment,
G1, App Store Connect, final-binary, distribution, and release gate remains open.

Validation: `Scripts/validate.sh` passed under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5
iPhone 17 Pro simulator. It passed every static contract, Release compilation, 35/35 local-D1
Worker tests, 8/8 evidence tests, the complete unit-test run, 17/17 UI tests, and every selected
coverage threshold; minimum selected coverage was `CSVExporter.swift` at 87.60% against 85%. The
validator deleted `mindbudget-validation.wnudAw/MindBudget.xcresult` after success, so the path is
only an execution pointer. A prior invocation inherited Command Line Tools instead of full Xcode
and stopped before Xcode execution; it is an environmental non-pass, not product evidence.

## 2026-08-29 — Session 178 — Correct review provenance and exercise native URLSession

Goal: Close PR #84 review findings without expanding Development authority or marking C5-04 Done.

Actions: Corrected the PR #83 chronology: independent review covered `daea2d2`, raised two P2
findings and one P3, and excluded four privacy-critical surfaces; `e6bbd3f` applied the findings
and recorded the implementation author's supplemental inspection, passed run `33242024609`, and
merged as `becb020` without pre-merge rereview. Added DEC-COM-070, updated current-state evidence,
and kept historical entries append-only. Added a default-disabled/non-archiving
`MindBudget-Telemetry-Live` scheme, a real Development `FixedTelemetryTransport` test, and a
deterministic `TelemetryService.stop()`-then-delete retry test.

Evidence: The default focused `TelemetryClientTests` run passed 34/34 and explicitly skipped the
live test. An exact-method-filter live attempt discovered zero tests and is a non-pass. The
corrected suite-level live run on Xcode 27.0 beta 6 / iOS 26.5 explicitly started the test and used
the production `BoundedTelemetryHTTPLoader`/`URLSession`; the strict Worker returned upload 202
(`.accepted`) and delete 204. A read-only remote D1 aggregate query then returned 0 events,
0 identities, and 3 tombstones: 2 historical pre-remediation rows plus this run's expected
UTC-day deletion tombstone. It read no row bodies or identifiers and wrote nothing.

Result: The known native-header uncertainty and prose-only post-`stop()` retry boundary are now
executable evidence. The live scheme is absent from the default scheme and cannot archive. This
remains Debug simulator Development evidence only; final-binary traffic, App Store Connect, G1,
Staging/Production, distribution, and release remain unauthorized. C5-04/COM-C5 remain In
Progress pending exact-head rereview, hosted CI, and merge.

Validation: `Scripts/validate.sh` passed on the same Xcode 27.0 beta 6 / iOS 26.5 simulator
toolchain. It passed every static contract, Release compilation, 35/35 local-D1 Worker tests,
8/8 evidence-contract tests, 552 unit tests in 32 suites, 17/17 UI tests, and every selected
coverage threshold. Minimum selected coverage was `CSVExporter.swift` at 87.60% against 85%.
The validator removed `mindbudget-validation.ceXEOC/MindBudget.xcresult` after success; it is an
execution pointer, not a durable artifact.

## 2026-08-29 — Session 179 — Close C5-04 and COM-C5 after PR #84

Goal: Calibrate the durable C5 state after the reviewed Development evidence merged, without
entering COM-C6 or broadening release authority.

Actions: Verified PR #84 exact head `84a96bc`, successful hosted run `33247176815`, and merge
`4194b73`. Added DEC-COM-071; marked C5-04/COM-C5 Done across task, memory, requirement, privacy,
egress, capture, metrics, runbook, and CI evidence documents; kept REQ-R1-TELEMETRY-001 Active for
COM-C6/C12; and changed COM-C6 from dependency-blocked to awaiting explicit owner entry. Updated
the commercialization-document gate to require the exact closeout chain and reject stale C5-04
pending-review state or automatic COM-C6 entry.

Result: C5-04 and COM-C5 are Done. Development remains the only deployed telemetry environment.
G1, App Store Connect, Staging/Production, final-binary traffic, distribution, and release remain
open. No Swift, Worker, entitlement, manifest, endpoint, deployment, D1, or customer-data change
was made; CHANGELOG is unchanged because there is no user-visible behavior change. This closeout
branch still requires independent review, hosted CI, and merge.

Validation: `Scripts/validate.sh` passed under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5
(`23F77`) iPhone 17 Pro simulator. Every static contract and Release compilation passed; 35/35
local-D1 Worker tests, 8/8 C5 evidence-contract tests, 552 unit tests in 32 suites, 17/17 UI tests,
and every selected coverage threshold passed. `CSVExporter.swift` was lowest at 87.60% against
the 85% floor. The validator removed `mindbudget-validation.g93SCp/MindBudget.xcresult` after
success; it is an execution pointer, not a durable artifact.

## 2026-08-29 — Session 180 — Preserve independent source-privacy review after C5 closeout

Goal: Close PR #85's P2 without reopening C5 or treating implementation-author inspection as
independent review.

Actions: Added an explicit COM-C6 preflight requiring independent inspection of
`MindBudget/Resources/PrivacyInfo.xcprivacy`, the AddExpense and Pro telemetry capture sites, the
`TelemetryService` wiring in `MindBudget/Services/TelemetryClient.swift`, and
`Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md` before any App Store Connect privacy
answer is copied or accepted. Updated DEC-COM-071, the requirement index, task/memory/privacy
records, the capture-audit checklist, and the runbook. Extended the commercialization-document
gate so these exact surfaces cannot disappear from the handoff and author-side inspection cannot
be promoted into the independent gate.

Result: C5-04/COM-C5 remain Done on their existing reviewed evidence, while the only checked-in
source privacy declaration and its capture/service/runbook basis retain a named independent
review owner in COM-C6. COM-C6 is not entered. No runtime, manifest, capture, service, Worker,
deployment, D1, App Store Connect, distribution, release, or customer-data change was made.

Validation: The remediated branch passed `Scripts/validate.sh` under Xcode 27.0 beta 6
(`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator. Every static contract and Release
compilation passed; 35/35 local-D1 Worker tests, 8/8 C5 evidence-contract tests, 552 unit tests in
32 suites, 17/17 UI tests, and every selected coverage threshold passed. `CSVExporter.swift` was
lowest at 87.60% against the 85% floor. The validator removed
`mindbudget-validation.lolUt1/MindBudget.xcresult` after success; it is an execution pointer, not a
durable artifact. Exact-head rereview, hosted CI, and merge remain required.

## 2026-08-29 — Session 181 — Enter COM-C6 and implement only C6-01

Goal: Convert the broad C6 automated-preflight promise into one closed, reviewable, non-mutating
matrix without entering signed-device or TestFlight work.

Actions: Synced `main` through PR #85 merge `008b674`, recorded explicit owner entry, added
DEC-COM-072 and `COM_C6_EXECUTION_PACKET.md`, froze seven rows in `C6_RELEASE_MATRIX.json`, and
added a self-testing strict validator plus the complete runner. The matrix binds all reviewed
static gates, both Worker local `check` scripts, Release simulator build, and 16 named Swift test
containers. Added the cross-domain offline local-Pro authority regression and integrated the C6
contract into ordinary validation.

Result: The local C6-01 matrix passed 285 tests in 16 suites; Public Configuration Worker 13/13,
Telemetry Worker 35/35, and telemetry evidence 8/8 passed with typechecks/dry-runs/startup checks.
The live telemetry probe stayed skipped by default. No remote state changed. C6-01 remains pending
independent review, hosted CI, and merge; C6-02/C6-03 and the PR #85 five-source privacy review
remain blocked. No G1 or release claim follows.

Validation: Xcode 27.0 beta 6 (`27A5252f`), iOS 26.5 (`23F77`) iPhone 17 Pro simulator. The local
result bundle is `/private/tmp/MindBudget-C6-01.xcresult`; it is an execution artifact rather than
hosted or durable release evidence. The final branch also passed `Scripts/validate.sh`: every
static contract, Release compilation, the strict 10,000-row Dashboard benchmark, 553 unit tests
in 32 suites, 17/17 UI tests, and every selected coverage threshold passed. `CSVExporter.swift`
was lowest at 87.60% against the 85% floor. The validator removed its temporary xcresult after
success, so the deleted path is only an execution pointer.

## 2026-08-29 — Session 182 — Bind C6 rows to executed passed methods

Goal: Close PR #86's P1 execution-evidence gap and P3 static-check discovery gap without widening
C6-01 or entering C6-02.

Actions: Added xcresult schema 0.4.0 parsing after the matrix test run. Every declared test
type/method binding must occur exactly once as a Test Case and must report Passed. Added negative
self-tests for skipped, missing, and duplicate evidence. Added direct repository check-script
discovery and an unclassified-future-gate self-test; the only non-row roles are the C6 bootstrap
and the full-suite coverage consumer.

Result: The retained earlier C6 bundle verified all 33 bindings and revealed that the Phase 6 local
Delete All regression is parameterized, so binding deliberately uses exact type plus method
basename while still requiring the one aggregate Test Case to pass. That retained bundle is only
a parser/remediation check, not exact-head evidence. No remote state changed and C6-02/C6-03 remain
blocked.

Validation: `python3 -B Scripts/c6_release_matrix.py --self-test` passed, including the new
result-evidence and discovery negatives. The remediated C6 matrix then passed all static checks,
Public Configuration Worker 13/13, Telemetry Worker 35/35 plus evidence 8/8, Worker
typechecks/dry-runs/startup checks, Release/test builds, 285 tests in 16 suites, and all 33 required
bindings exactly once as Passed. The retained local bundle is
`/private/tmp/MindBudget-C6-01-Remediation.xcresult`. The subsequent full validation passed the
strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32 suites, and 17/17 UI tests. Its
result summary contained 558 passes, 12 explicit opt-in skips, and zero failures; every selected
coverage threshold passed, with `CSVExporter.swift` lowest at 87.60% against the 85% floor. The
retained full bundle is `/private/tmp/MindBudget-C6-01-Remediation-Full.xcresult`. Rereview, hosted
CI, and merge remain required.

## 2026-08-29 — Session 183 — Close C6-01 after reviewed PR #86 merge

Goal: Record the exact C6-01 review/CI/merge chain without entering C6-02 or widening release
authority.

Evidence: Independent rereview approved exact remediation head `f77d2a6`. GitHub Actions run
`33255898196` completed successfully on that head, and PR #86 merged it as `015d00e`. The accepted
matrix evidence remains 285 selected tests in 16 suites plus all 33 required bindings exactly once
as Passed; the owning full validation remains 553 unit tests in 32 suites, 17/17 UI tests, zero
failures, and every selected coverage threshold passing.

Result: C6-01 is Done under DEC-COM-074. C6-02 remains blocked pending a separate explicit owner
entry, and the five-source privacy inspection preserved by PR #85 remains mandatory there. C6-03,
App Store Connect, final-binary/IPA evidence, Staging/Production, G1, archive/upload, distribution,
and release remain blocked or unauthorized. No product, remote, deployment, or customer-data action
occurred.

Validation: The initial sandboxed `Scripts/validate.sh` attempt could not access CoreSimulator and
stopped before any build; it is recorded as an environmental non-pass and excluded from evidence.
The unrestricted rerun passed under Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`)
iPhone 17 Pro simulator: every static contract, Release compilation, the strict serial 10,000-row
Dashboard benchmark, 553 unit tests in 32 suites, and 17/17 UI tests passed. Four accepted opt-in
physical CloudKit probes remained skipped. Every selected coverage threshold passed, with
`CSVExporter.swift` lowest at 87.60% against the 85% floor. The retained result bundle is
`/private/tmp/MindBudget-C6-01-Closeout.xcresult`; it is local execution evidence only and does not
satisfy any C6-02/C6-03 or remote/release gate.

## 2026-08-29 — Session 184 — Make C6 phase authorization section-bound

Goal: Close two phase-gate bypasses found by author-side supplemental inspection of initial
closeout head `4545e88` without changing C6 status or entering C6-02.

Actions: Extended the existing structural phase-state checker with exact section expectations. The
authoritative task map now requires unique bindings of C6-01 to Done plus `[x]`, C6-02 to Blocked
plus `[B]`, and C6-03 to Blocked plus `[B]`. Removed the weak global status anchors and the
line-oriented C6-02/C6-03 state regex from the shell gate. Added six negative self-tests covering
all three Status mutations and all three task-marker mutations, including the reviewed next-line
`Status: **In Progress.**` shape.

Result: Summary text can no longer satisfy a subphase's formal authorization record, and a future
C6 section transition must change the exact accepted state/task binding. C6-01 remains Done;
C6-02/C6-03 remain blocked. No product, remote, archive/upload, App Store Connect, G1,
distribution, or release action occurred. Exact-head validation, rereview, hosted CI, and merge
remain required.

Validation: The structural phase-checker self-test and all six C6 mutations passed their expected
accept/reject outcomes. Bytecode compilation passed with its cache confined to `/private/tmp`;
the first default-cache attempt was an excluded filesystem-permission refusal rather than a code
failure. All standalone money, network, commercialization, StoreKit 13/13, C6 matrix, Shell syntax,
and diff checks passed. The exact remediated head then passed `Scripts/validate.sh` under Xcode
27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator: Release compilation,
the strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32 suites, and 17/17 UI tests
passed. Four accepted opt-in physical CloudKit probes remained skipped. Every selected coverage
threshold passed; `CSVExporter.swift` was lowest at 87.60% against the 85% floor. The retained
bundle is `/private/tmp/MindBudget-C6-01-Closeout-Remediation-Final.xcresult`; it does not satisfy
any C6-02/C6-03, hosted, signed-device, final-binary, remote, or release gate.

## 2026-08-30 — Session 185 — Correct C6 gate-finding attribution

Goal: Correct the provenance of the two section-gate findings without changing their remediation,
validation, or any C6 authorization state.

Actions: Replaced the inaccurate “PR #87 review” attribution in the main and commercialization
decision, session, and CI records. The record now states that author-side supplemental inspection
of initial closeout head `4545e88` found the bypasses. The first independent PR #87 review instead
identified that attribution mismatch after remediation head `ba11fde` already existed.

Result: DEC-COM-075, the structural checker, and its six mutation tests remain unchanged. C6-01
remains Done; C6-02 and C6-03 remain blocked. No product, Worker, remote, archive/upload, App Store
Connect, G1, distribution, release, or user-visible change occurred.

## 2026-08-30 — Session 186 — Enter C6-02 and correct the signed privacy declaration

Goal: Execute only the owner-entered C6-02 source/privacy and signed-device preflight without
archiving, uploading, deploying, writing App Store Connect, entering C6-03, or making a release
claim.

Actions: Re-read the mandatory privacy manifest, AddExpense and Pro telemetry capture sites,
`TelemetryService`, and C5 operations runbook against Apple's current App Privacy definitions.
Found that the closed subscription purchase outcome must be classified as Purchase History even
though it contains no product, price, transaction, storefront, subscription date, or financial
content. Added that declaration, an exact privacy-manifest validator with seven negative
mutations, and a signed-app inspector with separate development-signed and distribution modes.
Recorded the complete review/result boundary in `C6_02_PREFLIGHT.md` and DEC-COM-076.

Signed-device evidence: Xcode 27.0 beta 6 (`27A5252f`) built Release 0.9.8 (9) for
`拉沙的iPhone`, an iPhone Air (`iPhone18,4`) on iOS 26.6.1 (`23G83`). The app passed signature,
bundle/team/application ID, minimum OS, iPhone family, background mode, private CloudKit,
embedded-manifest, exact-host, and no-fixture checks, then installed and launched successfully.
The development provisioning profile supplied development APS and `get-task-allow=true`; this is
explicitly not distribution/Archive/IPA/final-traffic evidence.

Result: The automated/source candidate is ready for independent review, but C6-02 remains In
Progress. The signed-device purchase/restore/manage/legal, localization/accessibility,
camera/photo-picker, data-protection/Instruments, and system-integration checklist remains open.
C6-03 and every archive/upload/deployment/App Store Connect/G1/distribution/release action remain
blocked or unauthorized.

Validation: All standalone money, network-egress, commercialization-document, StoreKit 13/13, C6
matrix, Shell syntax, Python syntax, plist, and diff checks passed. `Scripts/validate.sh` passed
under Xcode 27.0 beta 6 on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator: Release compilation,
the strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32 suites, and 17/17 UI tests
passed. Four accepted opt-in physical CloudKit probes remained skipped. Every selected coverage
threshold passed; `CSVExporter.swift` was lowest at 87.60% against the 85% floor. The temporary
xcresult was removed by the validator and is an execution pointer, not a durable artifact. Exact-
head independent review, hosted CI, and the manual C6-02 evidence remain required.

## 2026-08-30 — Session 187 — Derive the required-reason manifest from App source

Goal: Close the required-reason API source-inventory P2 left by PR #88 review without marking
C6-02 Done or entering C6-03.

Actions: Added `Scripts/check_required_reason_apis.py` using Apple's current five-category list.
The scanner covers production Swift, Objective-C, Objective-C++, C, C++, and headers under
`MindBudget/`; removes nested comments and ordinary/multiline/raw literal strings; retains actual
Swift interpolation code; and maps source symbols to UserDefaults, file timestamps, system boot
time, disk space, or active keyboards. It requires exact equality with
`NSPrivacyAccessedAPITypes`, enforces UserDefaults reason `CA92.1`, and fails ambiguous
`getattrlist*` calls pending explicit review. Self-tests cover every non-UserDefaults category,
comments and string decoys, Swift interpolation, raw-string trailing backslashes, C `stat`, extra
manifest declarations, wrong reasons, and ambiguous metadata calls. Classified the new check in
the C6 release matrix and wired it into the telemetry/privacy gate. Recorded DEC-COM-077 and the
source-only boundary in the C6-02 packet, task, privacy, release, requirement, and memory records.

Result: The current production inventory is exactly UserDefaults/`@AppStorage`; the checked-in
manifest remains exactly UserDefaults with App-only reason `CA92.1`. Source scanning does not
replace the C6-03 distribution privacy report or compiled dependency/IPA review. C6-02 remains In
Progress pending exact-head independent review and the open manual checklist. C6-03 and all
Archive/IPA, upload, App Store Connect, G1, distribution, and release actions remain blocked or
unauthorized.

Validation: All standalone money, network-egress, commercialization-document, StoreKit 13/13,
required-reason, telemetry, C6 matrix, Shell, Python, plist, and diff checks passed. The full C6
matrix passed 285 selected tests in 16 suites and verified all 33 required method bindings exactly
once as Passed. The first sandboxed `Scripts/validate.sh` rerun could not access CoreSimulator and
is an environmental non-pass. The unrestricted run passed under Xcode 27.0 beta 6 (`27A5252f`)
on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator: Release compilation, the strict serial
10,000-row Dashboard benchmark, 553 unit tests in 32 suites, and 17/17 UI tests passed. Four
accepted opt-in physical CloudKit probes remained skipped. Every selected coverage threshold
passed; `CSVExporter.swift` was lowest at 87.60% against the 85% floor. The validator removed its
temporary xcresult; the path was an execution pointer, not a durable, hosted, signed-device,
distribution, or release artifact.

## 2026-08-30 — Session 188 — Close PR #89 required-reason Swift overlay gaps

Goal: Remediate the required-reason source scanner fail-open cases found by PR #89 independent
review without marking C6-02 Done, entering C6-03, or authorizing any remote or release action.

Actions: Added explicit file-timestamp mappings for Foundation's `fileCreationDate` and
`contentModificationDate` overlays. Added disk-space mappings for `volumeAvailableCapacity`,
`volumeAvailableCapacityForImportantUsage`, `volumeAvailableCapacityForOpportunisticUsage`,
`volumeTotalCapacity`, `fileSystemFreeSize`, and `fileSystemSize`. Each spelling has a targeted
undeclared-category self-test. UserDefaults `CA92.1` validation now remains active whenever the
category is present, and a two-category wrong-reason mutation proves another declaration cannot
disable it. Recorded that literal strings and dynamically constructed raw-value keys are outside
the lexical proof and remain a C6-03 distribution privacy-report and compiled-artifact boundary.

Result: The production source/manifest contract still resolves to exactly UserDefaults/
`@AppStorage` with App-only reason `CA92.1`. The review's blocking inventory gap is closed in code
and tests. Broad fail-safe symbol matching remains intentionally conservative, while raw-value
construction is not misrepresented as covered. C6-02 remains In Progress pending exact-head
rereview, hosted CI, and its open manual checklist. C6-03 and all Archive/IPA, upload, App Store
Connect, G1, distribution, and release actions remain blocked or unauthorized.

Validation: The required-reason self-test and App scan passed. The full C6 matrix passed every
static and Worker check, Release/test builds, 285 tests in 16 suites, and the post-run verifier for
all 33 required bindings. The separate `Scripts/validate.sh` run under Xcode 27.0 beta 6
(`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator passed Release compilation, the
strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32 suites, all 17 UI tests, and
every selected coverage threshold. Four accepted opt-in physical CloudKit probes remained skipped;
`CSVExporter.swift` was lowest at 87.60% against the 85% floor. Both result-bundle paths were
temporary execution pointers rather than durable, hosted, signed-device, final-binary, or release
evidence.

## 2026-08-30 — Session 189 — Continue C6-02 after PR #89 merge

Goal: Calibrate the accepted required-reason remediation and continue only the remaining C6-02
manual signed-device preflight without entering C6-03 or authorizing a remote/release action.

Actions: Recorded that independent rereview accepted exact PR #89 remediation head `6ffc6fa`,
hosted run `33287620965` passed, and PR #89 merged as `72f016e`. Removed current-state claims that
the source gate remained pending rereview while preserving the historical implementation-session
records. Re-ran the required-reason negative suite and production scan, commercialization document
gate, and telemetry/privacy gate. Re-ran the signed-device inspector against the retained Release
0.9.8 (9) app from the accepted C6-02 build.

Result: The source/manifest inventory remains exactly UserDefaults/`@AppStorage` with reason
`CA92.1`, and the retained app passed signature, designated requirement, exact entitlements,
embedded privacy manifest, reviewed host literals, and no-test-fixture checks. A sandboxed
signature attempt returned `CSSMERR_TP_NOT_TRUSTED` because it could not consult the signing trust
state; the unrestricted rerun passed and is the owning result. CoreDevice reported the paired
physical `拉沙的iPhone` as unavailable, so no new StoreKit, localization/accessibility, receipt,
Instruments/data-protection, or system-integration observation is claimed. C6-02 stays In Progress
for those manual items. C6-03 and Archive/IPA, upload, App Store Connect, G1, distribution, and
release remain blocked or unauthorized.

## 2026-08-30 — Session 190 — Partial physical preflight and AX5 remediation

Goal: Continue only C6-02 signed-device evidence, record non-passes honestly, and remediate any
customer-visible issue without entering C6-03 or performing a remote/release action.

Actions: Inspected the installed development-signed Release 0.9.8 (9) in English and Simplified
Chinese. Live StoreKit showed monthly `$1.99`, annual `$19.99`, the active seven-day trial and
renewal date/price, already-entitled state, and Restore/Manage/Terms/Privacy controls. Airplane-mode
cold launch retained the verified local Pro snapshot. Inspected privacy/analytics, receipt, iCloud,
and export disclosures. Cancelled receipt review and Add Expense and confirmed Today's spending
remained `$0.00` and the existing `$25.00` expense was unchanged. Did not open the private photo
library or claim a camera path through iPhone Mirroring.

Result: Physical AX5 with Increase Contrast and Reduce Motion found a real navigation obstruction.
DEC-COM-078 caps only the persistent four-tab bar at Accessibility 1, not selected-page content.
Extended the AX5 UI regression to require all tab controls present, hittable, and no taller than
the reviewed bound. The unrestricted focused test passed one result with zero failures at
`/private/tmp/C6-02-AX5-TabBar-retry.xcresult`; an earlier sandboxed CoreSimulator attempt is an
environmental non-pass. The remediated build still needs physical reinstall. Transaction-error,
receipt-acquisition, full accessibility/appearance, Instruments/data-protection, and system-
integration evidence remain open. C6-02 is In Progress; C6-03 and all archive/upload/deployment/
App Store Connect/G1/distribution/release actions remain blocked or unauthorized.

## 2026-08-30 — Session 191 — Stabilize AX5 evidence and complete local validation

Goal: Close the local automated evidence for DEC-COM-078 without converting simulator results into
physical or release evidence and without entering C6-03.

Actions: Retained the first complete validation's three UI non-passes. Re-ran those cases in
isolation: language switching and onboarding/manual entry passed, while the Pro AX5 case reproduced
only an immediate Warm Botanical selected-state assertion race. Replaced the immediate read with a
bounded predicate wait and reran the focused Pro test successfully. Then reran the entire ordinary
validation pipeline.

Result: The focused Pro AX5 run passed one test with zero failures at
`/private/tmp/C6-02-Pro-AX5-Selection-Retry.xcresult`. The final complete validation under Xcode
27.0 beta 6 (`27A5252f`) on the iOS 26.5 (`23F77`) iPhone 17 Pro simulator passed Release, the
strict serial 10,000-row Dashboard benchmark, 553 tests in 32 unit suites, all 17 UI tests, and all
selected coverage gates. Four accepted opt-in physical CloudKit probes remained skipped;
`CSVExporter.swift` was lowest at 87.60% against the 85% floor. The result bundle was temporary
execution evidence only. The exact-source C6 matrix then passed every static and Worker check,
Release/test build, 285 tests in 16 suites, and all 33 required method bindings. Its first sandboxed
attempt could not write Wrangler logs or bind its local test server and is an environmental
non-pass; the unrestricted rerun is the owning result. C6-02 remains In Progress for physical
reinstall and every other open manual item; C6-03 and all remote/release actions remain blocked or
unauthorized.

## 2026-08-30 — Session 192 — Replace asserted AX5 evidence with canonical runtime evidence

Goal: Address PR #90's two P2 findings without claiming the physical remediation passed or
advancing C6-02/C6-03.

Actions: Confirmed that the previous
`UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge` argument is not a supported UIKit raw
value and was ignored. Replaced all four occurrences with canonical AX5
`UICTContentSizeCategoryAccessibilityXXXL`, and used
`UICTContentSizeCategoryAccessibilityM` for an AX1 baseline. Added a Dashboard content anchor and
required its AX5 height to exceed AX1 while the four-tab chrome remains bounded. Updated true-AX5
setup/Settings navigation to scroll. Replaced immediate reads after language, tab, category, and
appearance interactions with bounded predicate waits; removed the unsupported transient
classification from current evidence.

Result: The focused true-AX5 content comparison passed 1/1 at
`/private/tmp/C6-02-ReviewFix-TrueAX5-setup-rerun.xcresult`; the corrected three-appearance Pro AX5
test passed 1/1 at `/private/tmp/C6-02-ReviewFix-TrueAX5-Pro.xcresult`. The new complete validator
passed Release, the strict Dashboard benchmark, 553 unit tests in 32 suites, all 17 UI tests, and
all selected coverage gates under Xcode 27.0 beta 6/iOS 26.5. Four accepted physical-only
CloudKit probes remained skipped and `CSVExporter.swift` was lowest at 87.60%. Earlier simulator
bundles remain ordinary UI execution pointers, not AX5 evidence. Physical reinstall is still open;
C6-02 remains In Progress and C6-03 plus every remote/release action remain blocked. The exact-
source C6 matrix also passed all static and Worker checks, Release/test build, 285 tests in 16
suites, and all 33 required method bindings exactly once as Passed.

## 2026-08-30 — Session 193 — Diagnose and close the obscured AX5 Pro-row race

Goal: Treat the exact-head hosted failure as a product-test non-pass, identify its mechanism, and
verify a mechanism-specific correction without advancing C6-02/C6-03.

Actions: Inspected hosted Actions run `33312286576` and its xcresult for head `6908f6c`. Added an
initial bounded tap-to-destination handshake, then rejected its one-pass result when a two-
iteration run reproduced the failure in repetition two. Exported the result attachments and UI
hierarchy; they showed `settings.pro` with its frame center behind the Settings navigation bar even
though XCUITest reported it hittable. Updated the regression to scroll until the row midpoint is
below the live navigation-bar frame, assert that geometry, retain the bounded destination wait,
and stop after a failed navigation so missing controls cannot cascade.

Result: The pre-geometric-fix diagnostic passed 1/2 at
`/private/tmp/C6-02-ReviewFix-TrueAX5-Pro-NavigationHandshake-TwoIterations.xcresult`. The safe-hit-
point regression passed 2/2 at
`/private/tmp/C6-02-ReviewFix-TrueAX5-Pro-SafeHitPoint-TwoIterations.xcresult`. A fresh complete
`Scripts/validate.sh` run under Xcode 27.0 beta 6/iOS 26.5 passed Release, the strict Dashboard
benchmark, 553 unit tests in 32 suites, all 17 UI tests, and every selected coverage threshold;
four accepted physical-only CloudKit probes remained skipped and `CSVExporter.swift` was lowest
at 87.60%. Run `33312286576` remains a real non-pass, not a transient label. Physical reinstall and
the other manual evidence remain open; C6-02 stays In Progress, while C6-03 and every remote or
release action remain blocked. The exact-source C6 matrix also passed every static and Worker
check, Release/test build, 285 tests in 16 suites, and all 33 required method bindings exactly once
as Passed.

## 2026-08-31 — Session 194 — Reinstall and close the bounded physical AX5 appearance item

Goal: Repeat only the DEC-COM-078/079 physical AX5 plus bilingual appearance item on
`拉沙的iPhone`, explicitly excluding `Xiao li的 iPhone (2)`, and preserve all other C6-02/C6-03
and release boundaries.

Actions: Installed the corrected development-signed build and ran canonical true-AX5 content plus
English/Simplified Chinese light/dark Pro variants. Exported a failing setup hierarchy and replaced
`isHittable`-only budget entry with a safe live-midpoint lane. Inspected every retained physical
capture. A separate exact Pro/legal regression passed automation but showed a missing first-push
back indicator in screenshots, proving hierarchy success was not contrast evidence. Removed pushed-
view scheme duplication, made the Pro boundary own the navigation-bar toolbar scheme, and required
settled back-button geometry plus one discarded compositor frame before retained evidence. Updated
the StoreKit gate to require that single parent owner and reject child legal-page scheme overrides.

Result: The bilingual run passed 1/1 at
`/private/tmp/MindBudget-C6-02-Physical-AX5-Bilingual-Light-Dark-Lasha-Geometry.xcresult`, with four
captures manually inspected. The owning three-skin legal run passed 1/1 at
`/private/tmp/MindBudget-C6-02-Physical-AX5-ToolbarScheme-Retry-Lasha.xcresult`; all nine
Pro/Terms/Privacy captures showed a visible back indicator. Pre-fix visually wrong bundles, a
device-lock/certificate-trust attempt, and one later owner-stopped duplicate combined run remain
non-passes and are not counted. DEC-COM-081 closes only this bounded reinstall/appearance item.
C6-02 remains In Progress for transaction-error paths, receipt acquisition, full VoiceOver and
accessibility coverage, Instruments/data protection, and system integration. C6-03 and all archive,
upload, deployment, App Store Connect, G1, distribution, and release actions remain blocked or
unauthorized.

## 2026-08-31 — Session 195 — Close the DEC-COM-081 local validation loop

Goal: Verify the final physical-appearance remediation through the repository's complete local
gates without repeating owner-stopped device work or broadening the bounded C6-02 evidence.

Actions: Read the retained failed full validator with `xcresulttool`. It contained one primary
failure in `testAccessibilityExtraLargeKeepsPrimaryActionsAndNavigationReachable`: after the first
AX5 amount was entered, full-screen swipes moved `budget.totalBudget` from under the keyboard to
behind the navigation bar and back for every attempt. Replaced those swipes with small drags on the
budget form, recomputed the safe lower boundary from the live keyboard, and retained the existing
navigation-bar upper bound. Re-ran the four required static gates, two focused iterations, the full
validator, and the exact-source C6 matrix. No physical test was repeated, and `Xiao li的 iPhone (2)`
was not used.

Result: The focused regression passed 2/2 at
`/private/tmp/MindBudget-C6-02-AX5-Budget-Scroll-Remediation.xcresult`. The fresh complete validator
passed at `/private/tmp/MindBudget-C6-02-DEC-COM-081-Full-Validated.xcresult` with 558 passed, 13
intentionally skipped, and zero failed tests; all coverage thresholds passed. The final C6 matrix at
`/private/tmp/MindBudget-C6-02-DEC-COM-081-C6-Matrix-Final.xcresult` passed 285 tests in 16 suites
and all 33 runtime bindings. The earlier full bundle remains a non-pass and is not superseded into a
pass. C6-02 remains In Progress for the still-open manual rows, while C6-03 and all remote/release
actions remain blocked.

## 2026-08-31 — Session 196 — Close PR #91's reviewed partial C6-02 merge evidence

Goal: Calibrate the DEC-COM-081 product merge without closing C6-02 or changing the C6-03 archive
boundary.

Actions: Synchronized `main` to PR #91 merge `4ddabcd`. Reconciled exact reviewed head `b3ed24d`,
green hosted run `33362101536`, and the merge parent chain. Recorded the review's no-P1/P2 result
and retained its P3 boundaries: automated navigation geometry is not contrast proof, legal pages
inherit the Pro owner, the physical harness identifies the first navigation-bar button as Back,
and the budget helper remains intentionally scoped to the reviewed form. Updated the two memory
tracks, packet/preflight, tasks, requirements/privacy/egress records, decisions, CI baseline, and
the exact-evidence documentation gate.

Result: DEC-COM-082 accepts PR #91 only as partial C6-02 evidence. The remaining manual rows are
transaction-error behavior, receipt acquisition, full signed-phone VoiceOver/accessibility,
Instruments/data protection, and system integration. No additional physical test, Archive, IPA,
upload, deployment, App Store Connect write, tester assignment, G1, distribution, or release
action occurred. C6-02 stays In Progress and C6-03 stays blocked.

## 2026-08-31 — Session 197 — Bound the remaining C6-02 evidence without inventing passes

Goal: Apply the owner's instruction not to repeat already sufficient device work, disposition the
remaining C6-02 checklist honestly, and keep C6-03 plus every remote/release action blocked.

Actions: Added `C6_02_ACCEPTANCE_MATRIX.json` and a fail-closed/self-testing validator. The matrix
binds 23 exact StoreKit, receipt, accessibility-regression, and system-integration test methods to
five closed rows, requires each deterministic binding to execute exactly once as Passed, and keeps
Archive/IPA, upload, deployment, App Store Connect writes, tester assignment, G1, distribution,
and release blocked. Re-read the retained complete xcresult and confirmed every binding Passed.
Used read-only `devicectl` inspection on `拉沙的iPhone` only; the data container showed the expected
SwiftData artifacts and containermanagerd protection-policy attributes. A proposed export of the
financial store was rejected by the safety boundary and was not retried or worked around. `xctrace`
classified the phone as Offline while `devicectl` still saw it connected and produced no trace.

Result: DEC-COM-083 records deterministic evidence as passable only where exact runtime results
exist. Receipt acquisition continuity is bounded rather than redundantly rerun. The complete
signed-phone VoiceOver matrix, Instruments run, exact protection class, and physical notification/
Siri/Spotlight/Face ID/share/Delete All effects remain explicit non-passes or final-candidate
responsibilities; none is relabeled as Passed. No financial store was copied off device. C6-02
remains In Progress pending exact-head independent review, hosted CI, and merge. C6-03 and every
archive, upload, deployment, App Store Connect, G1, distribution, and release action remain blocked.

Validation: A fresh `Scripts/validate.sh` run on Xcode 27.0 beta 6 and the iOS 26.5 iPhone 17 Pro
simulator passed Release, the strict serial 10,000-row Dashboard benchmark, 553 unit tests in 32
suites, 18 UI tests with 17 passed and the single physical-only case skipped, every selected
coverage threshold, and the new 23-binding C6-02 result-bundle check. The exact-source C6 matrix
then passed 285 tests in 16 suites and all 33 release-matrix bindings at
`/private/tmp/MindBudget-C6-02-DEC-COM-083-C6-Matrix.xcresult`. Both result paths are local execution
pointers, not release evidence; the completed runs do not upgrade any physical non-pass.

## 2026-08-31 — Session 198 — Make PR #93 evidence portable to hosted Xcode 26.6

Goal: Close the review P2 without weakening the 23 exact runtime bindings, hiding a retried test,
or changing any product/C6-03 boundary.

Actions: Read Actions run `33370429991` and confirmed every test/coverage stage completed before
the new verifier alone failed on unknown schema `0.4.0`. Downloaded the run's Xcode 26.6 xcresult
artifact. Changed only the C6-02 reader to common schema `0.3.0`, replaced the schema-assuming split
with a closed identifier grammar that accepts the Xcode 26/27 shapes, and added a negative
failed-then-passed retry self-test. Corrected the current three-special-check description and the
preflight's stale `still-open` wording. Recorded DEC-COM-084 and kept C6-03 blocked.

Result: The remediated checker verifies all 23 bindings exactly once as Passed in both the
downloaded hosted Xcode 26.6 artifact and the existing local Xcode 27 full bundle. The first hosted
run remains red/non-pass, and no hosted evidence is inferred from the local artifact read. The new
exact head still requires rereview, green hosted CI, and merge. No Swift product code, physical
test, archive, upload, deployment, App Store Connect write, G1, distribution, or release action
occurred.

## 2026-08-31 — Session 199 — Replace the failed common-schema assumption

Goal: Diagnose Actions run `33384223530` without relabeling either hosted failure, hiding a UI
retry, or weakening the 23 exact C6-02 bindings.

Actions: Confirmed hosted Xcode 26.6 also rejects explicit schema `0.3.0`. Downloaded and inspected
the second xcresult, which showed real retry history as `Repetition` children under one `Test Case`.
Removed forced schema selection, taught the verifier to retain those child results, and updated its
negative self-test to the observed shape. Exported the pseudo-long-text failure attachment: the
expected `500` was visibly rendered while the active field's accessibility value lagged. Replaced
that immediate value predicate with the bounded post-Save Dashboard transition and ran the focused
test twice without retry. Recorded DEC-COM-085 and corrected the packet's three-special-check text.

Result: `/private/tmp/MindBudget-C6-02-Native-Schema-Focus2.xcresult` reports two passes, zero
failures, and zero skips. Runs `33370429991` and `33384223530` remain non-passes. The new exact head
still needs rereview, green hosted CI, and merge. No product behavior, physical test, archive,
upload, deployment, App Store Connect write, G1, distribution, or release action occurred; C6-02
remains In Progress and C6-03 remains blocked.

Validation: A fresh complete `Scripts/validate.sh` run passed Release, the strict Dashboard
benchmark, 553 unit tests, 18 UI tests with 17 passed and one expected physical-only skip, every
selected coverage threshold, and all 23 C6-02 bindings. No UI test retried. The validator removed
its temporary result bundle, so the printed path is an execution pointer rather than a durable
artifact. This is local evidence only; hosted Xcode 26.6 still owns the portability result.

## 2026-08-31 — Session 200 — Preserve the third PR #93 hosted non-pass

Goal: Diagnose run `33391122019` without calling a runner retry green, weakening the 23-binding
gate, or entering C6-03.

Actions: Confirmed the native xcresult reader reached hosted Xcode 26.6 successfully. Read the
failed test log and hierarchy rather than rerunning blindly. AX1 retained valid
`3000`/`2500`/`500` values and the matching flexible preview while Save and the focused decimal
keyboard remained onscreen; the first synthesized Save activation had not reached Dashboard. The
runner retry passed, and the acceptance gate correctly rejected the Failed/Passed `Repetition`
history. Changed the shared setup helper to use the existing bounded source-to-Dashboard
activation handshake. Changed result normalization to count concrete Repetition children instead
of double-counting their aggregate parent, with self-tests for one Passed repetition and the
observed Failed→Passed shape. Recorded DEC-COM-086.

Result: Run `33391122019` remains a non-pass. The focused AX1/AX5 test passed 2/2 with zero failures
and no test-runner retry at `/private/tmp/MindBudget-C6-02-Save-Handshake-Focus2.xcresult` under
Xcode 27.0 beta 6 on the iOS 26.5 iPhone 17 Pro simulator. A subsequent complete validator passed
Release, the strict Dashboard benchmark, 553 unit tests, all 18 UI tests with 17 passed and one
expected physical-only skip, every selected coverage threshold, and 23/23 C6-02 runtime bindings.
No UI test retried. The validator removed its temporary
`mindbudget-validation.U87fhN/MindBudget.xcresult`; both paths are local execution pointers, not
hosted or distribution evidence. A new exact head requires independent rereview, green hosted CI,
and merge. No product behavior, physical test, archive, upload, deployment, App Store Connect
write, G1, distribution, or release action occurred; C6-02 remains In Progress and C6-03 remains
blocked.

## 2026-08-31 — Session 201 — Preserve the fourth PR #93 hosted non-pass

Goal: Diagnose Actions run `33398172181` without calling retained screenshots or a runner retry
green, weakening the 23-binding acceptance gate, or entering C6-03.

Actions: Confirmed the workflow reached UI execution without a schema-version failure and read the
failing UI logs; no green 23-binding result is inferred from the red run. In the first iteration,
the Terms and Privacy back buttons existed, retained screenshots, and were tapped successfully
after the helper timed out against the navigation bar's delayed container frame. In a
later repetition, the budget fields remained valid while the decimal keyboard covered Save even
though XCTest reported it hittable. Removed the navigation-container dependency and required a
nonempty back-button midpoint inside the App window. Added a budget-specific bounded Form drag that
requires Save's complete frame below the navigation bar and above the keyboard before activation.
Recorded DEC-COM-087.

Result: Run `33398172181` remains a non-pass. The first local focused attempt is also a non-pass
because the new helper initially queried Save's frame before the control existed. After adding the
existence boundary, the exact AX1/AX5 test passed 2/2 with zero failures and no test-runner retry at
`/private/tmp/MindBudget-C6-02-Hosted-UI-Focus5.xcresult` under Xcode 27.0 beta 6 on the iOS 26.5
iPhone 17 Pro simulator. That path is a local execution pointer, not hosted or distribution
evidence. All four hosted runs remain non-passes. A new exact head requires independent rereview,
green hosted CI, and merge. No product behavior, physical test, archive, upload, deployment, App
Store Connect write, G1, distribution, or release action occurred; C6-02 remains In Progress and
C6-03 remains blocked.

Validation: The first complete-validator launch is an environmental non-pass before build/test
execution because the restricted environment could not connect to CoreSimulator or read the local
signing prefix. The identical unrestricted command then passed Release, the strict Dashboard
benchmark, all unit tests, all 18 UI tests with 17 passed and one expected physical-only skip,
every selected coverage threshold, and all 23 C6-02 runtime bindings. The UI summary contains
exactly 18 executions, so no test-runner retry occurred. The validator removed its temporary
xcresult; its printed path is an execution pointer rather than a durable artifact.

## 2026-09-01 — Session 202 — Close C6-02 after exact reviewed merge

Goal: Record PR #93's exact independent-review, hosted-CI, and merge chain, mark only C6-02 Done,
and keep C6-03 plus every Archive/upload/remote/release action blocked.

Actions: Verified that independent final review approved exact head `016dd33` with no P1/P2
findings, GitHub Actions run `33405016652` passed on that exact head, and PR #93 merged as
`c940e8e`. Updated the task map, execution packet, preflight, requirement/privacy/egress/release
surfaces, memories, decision logs, and structural commercialization gate. Preserved all four
earlier hosted runs as non-passes and carried the review's two non-blocking harness notes forward.

Result: DEC-COM-088 marks C6-02 Done. C6-03 remains blocked pending explicit owner entry and
separate Archive/upload authority. No Swift product code, physical test, Archive, IPA, upload,
deployment, App Store Connect mutation, tester assignment, G1 decision, distribution, release, or
Active Requirement completion occurred.

Validation: All four static gates, Shell syntax, and `git diff --check` passed. The first complete-
validator attempt selected CommandLineTools because `DEVELOPER_DIR` was absent and did not build;
the second used Xcode 27.0 beta 6 (`27A5252f`) but the sandbox denied CoreSimulator access. Both are
environmental non-passes. The identical unrestricted validator then passed Release, the strict
Dashboard benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit physical
skips, all 18 UI tests with 17 passed and one expected physical-only skip, selected coverage, and
23/23 C6-02 runtime bindings. The 18-case UI summary proves that no test-runner retry occurred.

## 2026-09-01 — Session 203 — Enter C6-03 and prepare build 10

Goal: Enter only C6-03, prepare a traceable `0.9.9 (10)` candidate, and establish the exact gates
that must pass before the owner-authorized Archive and TestFlight transport upload.

Actions: Recorded DEC-COM-089 and added `C6_03_RELEASE_BASELINE.md`. Bumped both app configurations
from `0.9.8 (9)` to `0.9.9 (10)` and aligned the newest in-app release-note version; added matching
dated changelog and TestFlight notes; updated the release-readiness and distribution-inspector
version/build expectations; and moved the structural C6-03 state from Blocked to In Progress. The packet requires exact-head
independent review, hosted CI, and merge before Archive, then Distribution inspection and upload
with `manageAppVersionAndBuildNumber: false` from exact merged `main`.

Result: Preparation is complete pending independent review, hosted CI, and merge. No Archive, IPA,
upload, deployment, App Store Connect mutation, tester assignment, external Beta App Review, G1,
distribution, public release, or Active Requirement completion occurred. The owner-waived CloudKit
physical observations and remaining C12-only physical matrices remain explicit non-passes.

Validation: The owner corrected the initially prepared marketing version to `0.9.9` while retaining
build 10. The earlier successful validator and C6 matrix predate that correction and are not exact
`0.9.9 (10)` evidence. The first complete corrected-version validator is retained as a non-pass:
the product and unit layers built, but one localization test and one UI test still expected
`0.9.8`. Remediation preserved the `0.9.8` historical release-note entry, added a new localized
`0.9.9` entry, and updated the current/history/future localization checks plus the UI version
assertion.

Fresh exact-candidate validation with Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
simulator passed all static and Worker gates. The full validator passed Release, the strict
Dashboard benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit physical
skips, all 18 UI tests with 17 passed and one expected physical-only skip, selected coverage, and
all 23 C6-02 runtime bindings, with no UI retry. Its deleted temporary xcresult is only an execution
pointer. The fresh C6 release matrix passed 285 tests across 16 suites and all 33 required runtime
bindings at `/private/tmp/MindBudget-C6-03-0.9.9-Build10-Matrix-20260901.xcresult`; that local path
is not hosted, Archive, or distribution evidence.

## 2026-09-01 — Session 204 — Upload the reviewed C6-03 build-10 baseline

Exact preparation head `11ab612` passed independent review and GitHub Actions run `33488815168`;
PR #95 merged it as `d5d0959`. Created the Release archive at
`/private/tmp/MindBudget-C6-03-0.9.9-zv9Qeg/MindBudget.xcarchive` from that exact merge using Xcode
27.0 beta 6 (`27A5252f`). Its development signature is not Distribution evidence.

The first App Store Connect export is an explicit non-pass because the current account,
distribution certificate, and Store profile were unavailable or incompatible with the APS/
CloudKit entitlements. After the owner restored the current account, automatic export with
`manageAppVersionAndBuildNumber=false` produced
`/private/tmp/MindBudget-C6-03-0.9.9-zv9Qeg/Exported/MindBudget.ipa`. Distribution inspection passed
the cloud-managed Apple Distribution certificate SHA-1
`772445FF75853BB4E4D8145E13D5AE0730F97D72`, profile UUID
`b2a9f8d1-2e48-41bf-84fd-48a9922ce82b`, Production APS/CloudKit, private container
`iCloud.com.xdgf558.MindBudget`, `get-task-allow=false`, `beta-reports-active=true`, exact six host
literals, the reviewed privacy manifest, and no StoreKit/test/extension/framework payloads.

After explicit owner authorization, App Store Connect accepted `0.9.9 (10)` at
`2026-09-01 19:27:25 +0800`, delivery UUID
`1b358d3b-4544-4617-ab47-5be69addc7a8`, with processing status. DEC-COM-090 closes only execution
through transport acceptance. Tester assignment, external Beta review, App Store submission,
privacy-form acceptance, service/schema deployment, final-binary Production traffic, G1,
distribution, and public release remain open or unauthorized. The closeout branch still requires
independent review, hosted CI, and merge.

Review of PR #96 found that the first closeout gate checked execution anchors with multi-file OR
semantics and that three DEC-COM-089 criteria had been edited in place while being checked. The
remediation requires every exact execution anchor in each of the baseline, decision, and session
records; restores the original criteria; leaves the archive-level Distribution criterion visibly
unchecked; and records the exported-IPA inspection as an explicit DEC-COM-090 deviation. It also
records that the `11ab612` approval came through the owner's external review workflow rather than
a GitHub Review/comment object.

Closeout validation then passed with Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro
simulator. The complete validator passed Release, the strict Dashboard benchmark, 553 unit tests
across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed
and one expected physical-only skip, selected coverage, and all 23 C6-02 runtime bindings; the UI
summary proves that no test-runner retry occurred. The validator's deleted temporary xcresult is
only an execution pointer. The independent C6 matrix passed 285 tests across 16 suites and all 33
required runtime bindings at
`/private/tmp/MindBudget-C6-03-Upload-Closeout-20260901.xcresult`; that local result bundle does not
replace hosted closeout CI or signed Distribution/transport evidence.

## 2026-09-01 — Session 205 — Close C6-03 and COM-C6 after reviewed transport

Goal: Calibrate the durable record after PR #96's reviewed, green merge; close only C6-03 and
COM-C6; and leave every later commercial phase behind its own explicit entry and evidence gates.

Actions: Verified PR #96 final head `3ed1357`, successful GitHub Actions run `33508360536`, and
merge commit `246e7c1`. Added DEC-COM-091, marked C6-03 and COM-C6 Done, preserved build 10's
Distribution/transport evidence and explicit non-passes, and strengthened the current-state gate
with per-file exact provenance plus structural phase-state checks. Moved G1 to an eligible but
unentered state requiring explicit owner entry, a frozen observation window, and accepted real
supplier quotes. Kept COM-C6.5 blocked behind the post-COM-C6 14-day no-P0/P1 gate and separate
owner entry; the earliest possible entry date is `2026-09-15`.

Result: The repository now records the end of COM-C6 without claiming tester assignment,
external Beta App Review, App Store version submission, App Privacy-form acceptance, service or
schema deployment, final-binary Production traffic, G1, distribution, public release, or Active
Requirement completion. Any later upload requires a build number greater than 10. No Swift,
Archive, IPA, upload, App Store Connect mutation, deployment, tester, distribution, or release
action occurred in this session.

Validation: Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator passed the full
validator: Release build, strict Dashboard benchmark, 553 unit tests across 32 suites with four
expected opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one expected
physical-only skip, selected coverage, and all 23 C6-02 runtime bindings. No UI test-runner retry
occurred. The validator deleted its temporary
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.XehnXC/MindBudget.xcresult`;
the path is an execution pointer. This closeout head still needs independent review, green hosted
CI, and merge before DEC-COM-091 becomes merged current state.

## 2026-09-01 — Session 206 — Rescope the unentered G1 task

Goal: Replace the planned public-observation prerequisite with the owner's requested real-quote
unit-economics task while leaving G1 and every implementation/external action unentered.

Actions: Recorded DEC-COM-092 and created `G1_UNIT_ECONOMICS_PACKET.md`. The packet requires dated
official or written quotes for at least one primary and one viable backup AI provider plus the
first-party backend; fixed typical/P50 and peak/P95 request profiles; integer-micro-USD all-in
costs; and explicit commission, tax/refund, retry/failover, invalid-output, backend, ledger,
deletion and recovery assumptions. It evaluates US$4.99 only as a working one-time local-Pro
scenario with finite starter credits and at least three consumable usage-card candidates.

Result: Public App Store release, proceeds, customer telemetry, surveys and an observation window
are no longer G1 entry prerequisites. No quote, provider, backend, price, starter count, card tier,
Product ID, quota, credit ledger, or commercial term was accepted. The existing Monthly/Annual
TestFlight implementation remains unchanged. G1 and COM-C7 remain blocked pending explicit owner
entry and a reviewed `PROCEED_TO_R2` decision; no App Store Connect, deployment, product-code,
distribution, or release action occurred.

Validation: Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator passed the full
validator on the updated quote/economics scope: Release, the strict Dashboard benchmark, 553 unit
tests across 32 suites with four expected opt-in CloudKit physical skips, all 18 UI tests with 17
passed and one expected physical-only skip, selected coverage, and all 23 C6-02 runtime bindings.
No UI test-runner retry occurred. The validator deleted its temporary
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.UjGKJy/MindBudget.xcresult`;
the path is an execution pointer, not a durable artifact. The updated exact head still requires
independent review, green hosted CI, and merge.

## 2026-09-02 — Session 207 — Enter G1 and capture quote-backed unit economics

Goal: Execute the owner's explicit G1 entry without treating published prices as measured model
quality or authorizing a provider/backend/product implementation.

Actions: Retrieved official 2026-09-02 OpenAI, Anthropic, Google, Cloudflare, and Apple rate,
limit, retention/training, and proceeds evidence. Added `Scripts/g1_unit_economics.py` with
integer-micro-USD self-tests and expanded `G1_UNIT_ECONOMICS_PACKET.md` with the closed task set,
typical/P50 and peak/P95 planning profiles, retry/failover and backend allocation, commission/tax/
refund reserves, circuit breaker, offer candidates, and credit-ledger/refund/delete/recovery
proposal. Synchronized DEC-COM-093, regional pricing, requirements, tasks, provider contract, and
both project memories.

Result: At 1,000 monthly successes the planning envelope is US$0.011330 typical and US$0.033098
peak per successful use. The US$4.99 downside budget supports at most 11 peak-envelope starter
uses; 10 starter uses and cards of 10/25/65 uses at US$0.99/US$1.99/US$4.99 are provisional. The
formal result is `INSUFFICIENT_QUOTE_EVIDENCE`: the bilingual Eval, measured distributions,
account privacy/region/rate proof, exact App Store proceeds, independent review, and owner decision
remain open. No credentials, egress, backend, product, UI, App Store Connect, or COM-C7 action
occurred.

Validation: The worksheet self-test and documentation cross-check pass. The initial default-
toolchain invocation stopped after successful static gates because `xcodebuild` resolved only to
Command Line Tools; that environment non-pass is excluded as product evidence. The explicit Xcode
27.0 beta 6 (`27A5252f`) rerun on the iOS 26.5 iPhone 17 Pro simulator passed Release, the strict
Dashboard benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit physical
skips, all 18 UI tests with 17 passed and one expected physical-only skip, selected coverage, and
all 23 C6-02 runtime bindings. The validator removed its temporary xcresult. Exact-head independent
review, hosted CI, and merge remain required.

## 2026-09-02 — Session 208 — Close reviewed PR #98 quote evidence without passing G1

Goal: Record the exact PR #98 review/CI/merge chain while preserving the difference between a
reviewed planning envelope and an accepted G1 provider/offer decision.

Actions: Verified that merge commit `6e2d242` has exact reviewed head `9226985` as its second
parent and that GitHub Actions run `33570570896` passed on that head. Added DEC-COM-094 and aligned
the G1 packet, task/status surfaces, requirements, project memories, main/commercial decision and
session logs, CI baseline, and commercialization-document gate. Carried the review's low-volume
breaker, optimization-removable `assert`, and 30-day URL-only quote observations forward.

Validation: Xcode 27.0 beta 6 (`27A5252f`) on the iOS 26.5 iPhone 17 Pro simulator passed Release,
the strict Dashboard benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit
physical skips, all 18 UI tests with 17 passed and one expected physical-only skip, every selected
coverage threshold, and all 23 C6-02 runtime bindings. The 18-execution UI summary proves no
test-runner retry occurred. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.aBMHd9/MindBudget.xcresult`;
this is an execution pointer, not a durable artifact.

Result: The first quote/planning package is reviewed and merged, but its formal result remains
`INSUFFICIENT_QUOTE_EVIDENCE`. G1 remains In Progress and COM-C7 remains blocked. No provider,
price, starter count, card, credential, backend, Product ID, ledger, UI, App Store Connect, remote,
distribution, or release action occurred. This closeout still requires independent review, green
hosted CI, and merge on its own exact head.

## 2026-09-02 — Session 209 — Lock the one-time Pro and sole-Luna owner policy

Goal: Apply the owner's remaining G1 product decisions without inventing exact credit/card values,
creating StoreKit products, enabling cloud traffic, or entering COM-C7.

Actions: Added DEC-COM-095. Selected OpenAI `gpt-5.6-luna` as the sole future cloud model and
recalculated the integer-micro-USD worksheet without a backup provider. Recorded US$4.99 one-time
Pro; an explicitly started 30-day local Pro/on-device-AI trial with zero Luna credits; finite
starter and consumable lots valid for one user-calendar year; one-credit commit only for a
user-initiated valid structured Luna result ultimately displayed; >=50% conservative peak
contribution margin; refund without local-data deletion; ordinary-test-user denial; isolated
capped Apple App Review access; replacement rather than grandfathering of the nonpublic
Monthly/Annual/P1W catalog; and a separately reviewable local-only release path. Synchronized the
G1 packet, provider/privacy/pricing contracts, downstream C7–C12 phase graph, requirements, tasks,
project memories, SPEC-014 override, and commercialization-document gate.

Result: The recalculated 1,000-success planning envelope is US$0.011330 typical/P50 and
US$0.018986 peak/P95. Candidate 5/10/15 starter lots and 10/25/65 cards remain evaluation rows,
not accepted counts/SKUs. Exact Luna Eval/account no-training/ZDR/region/subprocessor/rate/billing
proof, StoreKit price-point evidence, exact choices, final review, and owner `PROCEED_TO_R2` remain
open. The current result is `EVAL_AND_ACCOUNT_EVIDENCE_PENDING`; G1 stays In Progress and COM-C7
stays blocked. No Swift product behavior, credential, request, backend, Product ID, App Store
Connect state, distribution, or release changed.

Validation: The first `Scripts/validate.sh` invocation completed every static gate but inherited
the system Command Line Tools selection and stopped before build because it had no full
`xcodebuild`; this is an environment non-pass. A second invocation selected Xcode 27.0 beta 6
(`27A5252f`) inside the restricted sandbox, completed the static gates, then stopped because the
sandbox could not access CoreSimulator or its local build state; this is also an environment
non-pass. The identical unrestricted Xcode invocation on the iOS 26.5 iPhone 17 Pro simulator
passed Release, the strict Dashboard benchmark, 553 unit tests across 32 suites with four expected
opt-in CloudKit physical skips, all 18 UI tests with 17 passed and one expected physical-only skip,
every selected coverage threshold, and all 23 C6-02 runtime bindings. The UI summary contains
exactly 18 executions, so no test-runner retry occurred. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.G71eft/MindBudget.xcresult`;
that path is an execution pointer, not a durable artifact. Exact-head independent review, hosted
CI, and merge remain required.

## 2026-09-02 — Session 210 — Freeze the Luna Eval and exact credit offer

Goal: Complete every credential-independent part of the owner's Luna Eval/account-proof/offer
request without converting public policy into account evidence or sending traffic through an
unreviewed retention/region configuration.

Actions: Added DEC-COM-096, `G1_LUNA_EVAL_CASES.json`, `G1_LUNA_EVAL.md`,
`G1_OPENAI_ACCOUNT_EVIDENCE.md`, and `Scripts/g1_luna_eval.py`. Frozen 12 deterministic scenarios
into 24 English/Simplified-Chinese cases with closed facts/actions/numbers, strict structured
output, safety/language gates, bounded retry, immutable dataset/prompt hashes, and explicit live-
run credential/base-URL requirements. Re-ran integer economics and accepted 10 post-buyout
starter credits plus 10/25/65-use cards at US$0.99/US$1.99/US$4.99. Added the mandatory server
breaker below 1,000 trailing-30-day successes or 50% peak margin.

Result: The deterministic Eval self-test is tooling evidence only. The dedicated OpenAI account
identity, sharing state, ZDR approval/configuration, region, subprocessors/terms, actual rate tier,
billing controls, and isolated credential are absent. No live request ran. Results are
`OPENAI_ACCOUNT_NOT_ADMITTED`, `LIVE_LUNA_EVAL_NOT_RUN_NO_ADMITTED_ACCOUNT`, and
`ACCOUNT_ADMISSION_AND_LIVE_EVAL_BLOCKED`; G1 remains In Progress and COM-C7 remains blocked. No
Swift product code, remote request, credential, backend, Product ID, ledger, App Store Connect
mutation, distribution, or release action occurred.

Validation: Normal and optimized (`python3 -O`) Eval self-tests passed, 24 request fixtures were
emitted, the Luna-only integer worksheet and document cross-check passed, and an explicit live-run
attempt stopped before network access because the machine-readable account gate is not admitted.
The first full-validator attempt passed the static gates but the restricted sandbox could not
access CoreSimulator/build state; it is an environment non-pass. The identical unrestricted Xcode
27.0 beta 6 (`27A5252f`) run on the iOS 26.5 iPhone 17 Pro simulator passed Release, the strict
Dashboard benchmark, 553 unit tests across 32 suites with four expected opt-in CloudKit physical
skips, all 18 UI tests with 17 passed and one expected physical-only skip, every selected coverage
threshold, and all 23 C6-02 runtime bindings. The UI summary contains exactly 18 executions, so no
test-runner retry occurred. The validator deleted
`/var/folders/53/qdndcwrn6q1cw10rq6yl35xr0000gn/T/mindbudget-validation.hu81QC/MindBudget.xcresult`;
this path is an execution pointer rather than a durable artifact. Exact-head independent review,
hosted CI, and merge remain required.

## 2026-09-02 — Session 211 — Configure standard-controls synthetic Luna Eval admission

Goal: Incorporate the owner's real OpenAI project/privacy/rate/billing observations without
claiming ZDR or admitting production customer traffic.

Actions: Added DEC-COM-097 and changed the machine account artifact to schema version 2. Recorded
the dedicated Global project, sole Luna allow-list, Tier 1 500,000 TPM/500 RPM/5,000,000 TPD,
US$5 project soft limit/alert, US$18.72 Pay-as-you-go balance, and auto-reload off without storing
identifiers or payment details. The owner accepted standard abuse-monitoring retention up to 30
days for the synthetic Eval. The runner now pins `store=false`, `background=false`, explicit cache
mode with no breakpoints, `scope: synthetic_eval_only`, and `productionAdmitted: false`.

Result: ZDR remains an optional future enhancement rather than a fixed-Eval prerequisite. Final
Saved sharing/logging confirmation and the isolated service-account credential remain false, so
the live runner is still blocked and no provider request occurred. Passing the later Eval cannot
activate production; customer consent, processor terms, server isolation, App Privacy, final-
binary traffic, and release proof remain downstream gates. G1 stays In Progress and COM-C7 stays
blocked.

Validation: Normal and optimized Eval self-tests pass with exact standard-retention and no-
production assertions. Full static/document validation is recorded separately in
`CI_BASELINE.md`; no Xcode product validation is required for this product-code-free interim delta.
