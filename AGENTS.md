# AGENTS.md

## Project

MindBudget — a local-first iOS budgeting coach.
The detailed product specification is maintained by the project owner outside this
public repository. The files under `Docs/` are the repository's durable implementation
memory. Confirm uncovered product decisions and record them before implementation.

## Before editing code, read

1. `Docs/PROJECT_MEMORY.md`
2. `Docs/TASKS.md`
3. `Docs/DECISIONS.md`
4. `Docs/SESSION_LOG.md`

Also read when relevant: `Docs/AI_PROMPT_CONTRACT.md`,
`Docs/PRIVACY_AND_REVIEW_NOTES.md`, `Docs/SIRI_PERSONAL_CONTEXT_PLAN.md`,
and `Docs/COPY_GUIDELINES.md`.

For any COM phase, also read `Docs/COMMERCIALIZATION_TASKS.md` and the current files under
`Docs/Commercialization/`, especially `PROJECT_MEMORY.md`, `DECISIONS.md`,
`REQUIREMENTS_INDEX.md`, `NETWORK_EGRESS_POLICY.md`, and `SESSION_LOG.md`.

## Build and test

All commands must pass before a COM phase may be marked Done. The commercialization-doc check is
also run by `Scripts/validate.sh` so ordinary product phases retain one complete validation entry.

```bash
Scripts/check-no-floating-point-money.sh
Scripts/check-commercialization-docs.sh
Scripts/validate.sh
```

Override `MINDBUDGET_TEST_DESTINATION` when the default simulator is unavailable.

## After each session, update

1. `Docs/SESSION_LOG.md` (always)
2. `Docs/TASKS.md` (if status changed)
3. `Docs/DECISIONS.md` (if a technical decision was made)
4. `Docs/CHANGELOG.md` (if user-visible behavior changed)

During a COM phase, also update `Docs/Commercialization/SESSION_LOG.md` always,
`Docs/COMMERCIALIZATION_TASKS.md` when status changes, and
`Docs/Commercialization/DECISIONS.md` for a commercial decision. Keep the main decision log to a
short pointer when the detailed decision belongs to the separate COM track.

## Non-negotiables

1. Work on one phase at a time; do not implement ahead.
2. Store and calculate money as `Int64` minor units. The isolated App Intents transport adapter is the only documented `Double` exception.
3. Date calculations use the user's `Calendar` and `TimeZone`; never hardcode 86400 seconds as a day.
4. Budget, overspend, and pattern decisions are deterministic Swift code. AI only rewrites already-computed facts.
5. Every AI path has a correct template fallback.
6. No bank integration, ads, or third-party analytics. The current shipped baseline has no cloud
   sync, app-owned telemetry, or third-party AI. A future Free iCloud, first-party telemetry, or
   consented provider-AI channel is permitted only in its accepted COM phase after the exact
   authorization, disclosure, deletion, network-egress, failure, and release gates pass.
7. Do not directly access iMessage, voicemail, Mail, Photos, or another app's private data.
8. No private APIs.
9. No shame, judgement, or diagnosis in user-facing text.
10. Every purchase reminder has 2–4 allowed actions, including continuing the purchase.
11. Reminders are throttled; a flow shows at most one interrupting reminder.
12. Localize all user-facing strings.
13. Gate new SDK capabilities with conditional import, availability checks, runtime checks, and user settings.

## Architecture

SwiftUI + SwiftData (`VersionedSchema`) + MVVM + protocol-based services.
`BudgetEngine`, `SpendingPatternDetector`, and `ReminderThrottle` are pure,
stateless, `Sendable` value-type services and never access `ModelContext`.
SwiftData writes go through the `@ModelActor`-based `DataActor`.
