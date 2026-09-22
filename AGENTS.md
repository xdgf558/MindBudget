# AGENTS.md

## Project

MindBudget — a local-first iOS budgeting coach.
The detailed product specification is maintained by the project owner outside this
public repository. The files under `Docs/` are the repository's durable implementation
memory. Resolve routine, reversible implementation choices within the accepted scope. Confirm
unresolved choices that materially change product behavior, money/data semantics, permissions,
privacy, pricing, or release scope, and record them before implementation. Group related choices
into one concrete proposal when possible.

## Before editing code, read

1. Read the current-scope sections of `Docs/PROJECT_MEMORY.md`.
2. Read the active phase and its acceptance criteria in `Docs/TASKS.md`.
3. Follow the active phase's contract/evidence pointers. Search `Docs/DECISIONS.md` and
   `Docs/SESSION_LOG.md` by decision ID, phase, or module only when that history is needed.

Do not load whole historical logs or completed phases by default. Reuse context already read
unless the relevant files changed. For read-only questions, inspect only the material needed
to answer. When current and historical statements conflict, check the cited decision and evidence;
do not infer new authority from an old checklist or a passing test.

Also read when relevant: `Docs/AI_PROMPT_CONTRACT.md`,
`Docs/PRIVACY_AND_REVIEW_NOTES.md`, `Docs/SIRI_PERSONAL_CONTEXT_PLAN.md`,
and `Docs/COPY_GUIDELINES.md`.

For COM work, read the current state in `Docs/Commercialization/PROJECT_MEMORY.md` and the
active phase in `Docs/COMMERCIALIZATION_TASKS.md`. Read only the relevant contract and requirement
entries under `Docs/Commercialization/`; consult `NETWORK_EGRESS_POLICY.md` for network changes
and search commercial decisions/logs when their history affects the task.

## Build and test

During implementation, run the checks relevant to the changed behavior. For final code acceptance
or phase completion, run the complete entry below on the final candidate and satisfy the active
phase's independent-review, hosted-CI and artifact requirements. This entry already includes the
money, network, commercialization-document and StoreKit checks, directly or through its wrappers;
do not separately repeat them on the same unchanged candidate.

```bash
Scripts/validate.sh
```

Override `MINDBUDGET_TEST_DESTINATION` when the default simulator is unavailable.
Retain native result bundles when required for review by setting `MINDBUDGET_RESULT_BUNDLE_PATH`
to a fresh `.xcresult` path. Preserve failures and the applicable benchmark and zero-retry gates.
Repeat validation only after a relevant change or to investigate an unresolved failure; a later
pass does not erase an earlier non-pass. Pure prose or instruction edits need diff/format/link
checks and affected document gates, unless the active acceptance contract explicitly requires more.
Local, hosted and independent review evidence serve different requirements and are not substitutes.

## Record material changes

1. `Docs/SESSION_LOG.md` (repository changes, material evidence, or blockers)
2. `Docs/TASKS.md` (if status changed)
3. `Docs/DECISIONS.md` (if a technical decision was made)
4. `Docs/CHANGELOG.md` (if user-visible behavior changed)

Pure queries, read-only reviews and unchanged CI polling do not require a log edit. Record full
details once in the owning track: COM work uses `Docs/Commercialization/SESSION_LOG.md` and
`Docs/Commercialization/DECISIONS.md`. Update `Docs/COMMERCIALIZATION_TASKS.md` only when its status
changes; add a short pointer in the main track only for a cross-track change. Preserve historical
evidence. After a candidate is frozen, use the accepted evidence channel for new validation results
and fold repository status updates into the next planned change instead of creating a documentation
PR merely to repeat a result; follow any explicit phase-specific closeout requirement.

## Scope, skills and authorization

Use the narrowest relevant skill; read only its task-relevant references. Use Product Design for
actual UI-design work, not for unrelated test-harness or CI changes. A skill does not authorize
dependency upgrades, account configuration, network channels or product-policy changes.

Continue low-risk, reversible work within the user's authorized scope without asking per command.
Reuse an existing authorization while its target, scope and validity remain unchanged. Obtain
explicit authorization for sensitive actions such as deployment, publishing/merge, paid calls,
device installation/launch, live cloud writes and destructive cleanup when not already covered.
Preserve exact-package/device/controller bindings and one-use or expiring approvals where required;
never reuse a consumed approval. Present the concrete target and remaining action together before
requesting any new authorization. Platform permission prompts are separate from project approval.

## Non-negotiables

1. Advance one authorized product phase at a time. Necessary regression fixes, test/CI work and
   documentation may be completed together within that phase; do not infer entry into the next
   feature or an exception to an explicit scope boundary. Documented owner-approved parallel phases
   remain exceptions to the default.
2. Store and calculate money as `Int64` minor units. The isolated App Intents transport adapter is the only documented `Double` exception.
3. Date calculations use the user's `Calendar` and `TimeZone`; never hardcode 86400 seconds as a day.
4. Budget, overspend, and pattern decisions are deterministic Swift code. AI only rewrites already-computed facts.
5. Every AI path has a correct template fallback.
6. No bank integration, ads, or third-party analytics. Distinguish accepted repository implementations
   from enabled channels and released binaries. Free iCloud and first-party telemetry have separately
   governed implementations; their presence grants no activation or release authority. Any iCloud,
   telemetry or consented provider-AI channel must satisfy its current authorization, disclosure,
   deletion, network-egress, failure and release gates before the corresponding operation.
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
