# MindBudget（花有数）

> 温和的预算与消费复盘工具

MindBudget is an iPhone-only, local-first budgeting coach built with SwiftUI and SwiftData. It
helps people record spending, understand pressure inside the current budget cycle, notice possible
patterns, and pause before a regretted purchase—without turning budgeting into judgement or
financial advice.

## What it does

- Records expenses and income with exact currency-aware amounts.
- Builds user-defined budget cycles with fixed, discretionary, and savings allocations.
- Tracks a cross-cycle savings goal and reconciles recurring fixed expenses.
- Produces deterministic budget pressure, spending-pattern, and retrospective Insights.
- Supports wishlists, cooling-off periods, and throttled local reminders.
- Answers supported budgeting questions with deterministic facts and a complete local fallback.
- Offers optional Siri, App Intents, Shortcuts, and Spotlight integration behind explicit settings.
- Exports a unified expense/income CSV and provides a verified Delete All flow.
- Supports English, Simplified Chinese, multiple visual skins, Dynamic Type, and VoiceOver.
- Provides an optional Face ID/device-authentication app lock.

Apple's on-device Foundation Models may improve wording on supported devices and languages, but
they never own money, budget, pattern, entitlement, or action decisions. Every enhanced path keeps
the deterministic template fallback.

## Privacy and product boundaries

Budget records, notes, merchant names, reflections, and savings data stay in the local SwiftData
store. MindBudget has no bank integration, ads, third-party analytics, third-party AI, or current
iCloud synchronization. Siri and Spotlight are independently off by default. CSV export happens
only through the system share sheet after an explicit user action.

The source includes a narrowly allow-listed anonymous signed-public-configuration reader. Its
document cannot carry ledger content or grant StoreKit entitlement, and Production deployment is
not implied by source-level support. See
[`Docs/PRIVACY_AND_REVIEW_NOTES.md`](Docs/PRIVACY_AND_REVIEW_NOTES.md) and
[`Docs/Commercialization/NETWORK_EGRESS_POLICY.md`](Docs/Commercialization/NETWORK_EGRESS_POLICY.md)
for the reviewed boundaries.

## Project status

MindBudget is pre-1.0. The project version fields currently read **0.9.8 (9)**. Build 9 was accepted
by App Store Connect transport, but later repository changes are unreleased; the next Archive must
use a higher build number. No public App Store release, external Beta App Review, Production public
configuration deployment, or final launch pricing is claimed here.

The Free product and the reviewed StoreKit purchase/restore architecture are implemented in
source, while later migration, sync, receipt, telemetry, cloud, Watch-distribution, and formal
release work remains governed by explicit phase gates. StoreKit fixture prices and trial terms are
test controls, not final customer economics. The durable status is maintained in
[`Docs/TASKS.md`](Docs/TASKS.md) and
[`Docs/COMMERCIALIZATION_TASKS.md`](Docs/COMMERCIALIZATION_TASKS.md).

## Architecture

- SwiftUI + SwiftData with versioned V1 → V4 migrations.
- MVVM-style composition with protocol-based services.
- Swift 6 strict concurrency and an `@ModelActor`-based `DataActor` for persistence writes.
- `Int64` minor units plus ISO currency codes for authoritative money; no floating-point money
  calculations in app source.
- Pure deterministic engines for budgets, patterns, reminders, safety validation, and summaries.
- Capability, availability, runtime, user-setting, and entitlement gates around optional SDK
  integrations.
- iPhone-only V1, deployment target iOS 17.0+.

## Requirements

- Xcode 26.6 or a newer compatible toolchain
- iOS 17.0+
- iPhone target or simulator
- Swift 6 strict concurrency support

## Build and test

Run the repository gates from the project root:

```bash
Scripts/check-no-floating-point-money.sh
Scripts/check-network-egress.sh
Scripts/check-commercialization-docs.sh
Scripts/check-storekit-test-catalog.sh
Scripts/validate.sh
```

Set `MINDBUDGET_TEST_DESTINATION` to override the default simulator. A fork can create an ignored
`Config/Local.xcconfig` and override `MINDBUDGET_BUNDLE_ID_PREFIX` for local signing.

The dedicated `MindBudget-StoreKit-Local` scheme owns opt-in local StoreKit tests. Its synthetic
catalog is test-bundle-only and is excluded from the app resources and normal Archive path.

## Repository guide

Read these before making changes:

- [`AGENTS.md`](AGENTS.md) — working rules, non-negotiables, and validation commands.
- [`Docs/PROJECT_MEMORY.md`](Docs/PROJECT_MEMORY.md) — durable implementation memory.
- [`Docs/TASKS.md`](Docs/TASKS.md) — current product work and phase status.
- [`Docs/DECISIONS.md`](Docs/DECISIONS.md) — accepted technical and product decisions.
- [`Docs/TEST_PLAN.md`](Docs/TEST_PLAN.md) — test ownership and release evidence.
- [`Docs/PRIVACY_AND_REVIEW_NOTES.md`](Docs/PRIVACY_AND_REVIEW_NOTES.md) — privacy and review
  disclosures.
- [`Docs/COMMERCIALIZATION_TASKS.md`](Docs/COMMERCIALIZATION_TASKS.md) — separately gated Pro and
  commercialization roadmap.

The project is developed one accepted phase at a time. Do not implement ahead of the active phase.

## License

This repository is publicly visible for review, but MindBudget is not open-source software. All
rights are reserved; see [`LICENSE`](LICENSE).
