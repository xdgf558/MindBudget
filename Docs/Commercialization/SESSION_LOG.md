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
