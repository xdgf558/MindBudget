# AGENTS.md

## Project

MindBudget — a local-first iOS budgeting coach.
Authoritative spec: `/Users/shaola/Downloads/开发文档/MindBudget_iOS_Dev_Doc_v3.md`.
Read the full specification before writing code. If code and specification conflict,
the specification wins; correct specification defects first and record the decision.

## Before editing code, read

1. `/Users/shaola/Downloads/开发文档/MindBudget_iOS_Dev_Doc_v3.md`
2. `Docs/PROJECT_MEMORY.md`
3. `Docs/TASKS.md`
4. `Docs/DECISIONS.md`
5. `Docs/SESSION_LOG.md`

Also read when relevant: `Docs/AI_PROMPT_CONTRACT.md`,
`Docs/PRIVACY_AND_REVIEW_NOTES.md`, `Docs/SIRI_PERSONAL_CONTEXT_PLAN.md`,
and `Docs/COPY_GUIDELINES.md`.

## Build and test

Both commands must pass before a phase may be marked Done.

```bash
export DEVELOPER_DIR="/Users/shaola/Downloads/软件/Xcode.app/Contents/Developer"
export MINDBUDGET_TEST_DESTINATION="${MINDBUDGET_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}"
xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -destination "$MINDBUDGET_TEST_DESTINATION" build
xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -destination "$MINDBUDGET_TEST_DESTINATION" test
```

## After each session, update

1. `Docs/SESSION_LOG.md` (always)
2. `Docs/TASKS.md` (if status changed)
3. `Docs/DECISIONS.md` (if a technical decision was made)
4. `Docs/CHANGELOG.md` (if user-visible behavior changed)

## Non-negotiables

1. Work on one phase at a time; do not implement ahead.
2. Store and calculate money as `Int64` minor units. The isolated App Intents transport adapter is the only documented `Double` exception.
3. Date calculations use the user's `Calendar` and `TimeZone`; never hardcode 86400 seconds as a day.
4. Budget, overspend, and pattern decisions are deterministic Swift code. AI only rewrites already-computed facts.
5. Every AI path has a correct template fallback.
6. No bank integration, cloud sync, third-party AI, ads, or third-party analytics.
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
