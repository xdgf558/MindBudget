# SESSION_LOG

## 2026-08-02 — Session 1 — Phase 0

Goal: Initialize the repository, Xcode targets, project constraints, and durable agent memory.

Files changed: `.gitignore`, `README.md`, `AGENTS.md`, `MindBudget.xcodeproj`,
`MindBudget/App`, `MindBudget/Resources`, placeholder tests, and all files under `Docs/`.

What was completed: The workspace and installed simulator environment were inspected;
the repository and Phase 0 project skeleton were created. The initial missing
Preview Content path was removed, the simulator was returned to a clean state,
and the full build/test acceptance sequence passed.

What was NOT completed: Phase 1 models and persistence were intentionally not started.

Build result: pass — iPhone 17 Pro, iOS 26.5

Test result: pass — 2 tests, 0 failures, 0 skipped

Known issues: A machine whose active developer directory points to Command Line
Tools must select its installed Xcode or set `DEVELOPER_DIR` before validation.

Next suggested task: Begin Phase 1 with `Money`, enums, VersionedSchema models, and `DataActor`.

## 2026-08-02 — Session 2 — Phase 0 review remediation

Goal: Address accepted PR feedback without changing the v3.1 capability-flag contract.

Files changed: feature flags, Xcode project/configuration, asset catalog, scripts,
GitHub Actions workflow, smoke tests, repository licensing, and project memory.

What was completed: Capability/user-setting semantics were clarified; V1 became
iPhone-only; build identity became locally overridable; CI and meaningful localization
smoke tests were added; Package.resolved is no longer ignored; project-generator
migration triggers and proprietary repository terms were recorded. The hosted CI
simulator is created explicitly, and the money-path check uses macOS system tools.

What was NOT completed: A real App Icon and iOS 17 hosted runtime test remain deferred.

Build result: pass — iPhone 17 Pro, iOS 26.5

Test result: pass — 2 tests, 0 failures, 0 skipped

GitHub Actions result: pass — Xcode 16.4, iPhone 16 simulator, iOS 18.5

Known issues: Current GitHub-hosted macOS images do not include an iOS 17 runtime.

Next suggested task: Review and merge PR #2, then begin Phase 1 on a new branch.

## 2026-08-02 — Session 3 — Phase 0 final review hardening

Goal: Close the final PR review gaps and align hosted validation with the declared
Xcode 26.6 development environment.

Files changed: source policy and validation scripts, GitHub Actions, localization
smoke tests, shared configuration guidance, capability-gate documentation, and
project memory.

What was completed: The floating-point guard now scans the entire app source tree
except the single documented transport adapter. CI pins checkout, verifies Xcode
26.6+, checks the app target's deployment value, dynamically selects a compatible
iOS 26 runtime and iPhone type, validates the final bundle identifier, and uses
build-for-testing/test-without-building. English and Simplified Chinese rendered
labels are covered. Raw FeatureFlags are prohibited at Phase 7/8 call sites in favor
of tested centralized gates.

What was NOT completed: A real App Icon and real iOS 17 runtime validation remain
deferred to later release preparation.

Local build result: pass — Xcode 26.6, iPhone 17 Pro, iOS 26.5

Local test result: pass — 1 unit test and 2 UI tests, 0 failures

GitHub Actions result: pass — Xcode 26.6, iOS 26.5, 6m44s; all tests passed on
their first iteration. Hosted CI retains one assertion-preserving retry for a
confirmed cold-simulator launch timeout.

Known issues: GitHub-hosted images still do not provide the required iOS 17 runtime.

Next suggested task: Review and merge PR #2, then begin Phase 1 on a new branch.
