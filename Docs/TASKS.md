# TASKS

Status values: Todo, In Progress, Blocked, Done.
A phase may only be marked Done after both `xcodebuild build` and `xcodebuild test` pass.

## Phase 0 — Repo and agent memory
Status: Done

## Phase 1 — Money, enums, SwiftData models, DataActor
Status: Done

## Phase 2 — Budget engine and cycle math
Status: Done

## Phase 3 — Onboarding, dashboard, manual expense tracking
Status: Done

## Phase 4 — Emotion tags, wishlist, cooling-off
Status: Done

## Phase 5 — Rule engine, reminder throttle, template reminders, insights
Status: Done
- Attribute cooling-off outcomes with `outcomeRecordedAt` only through deterministic code;
  preserve `completedAt` as the actual cooling-period end.
- Keep insight detection independent from whether reminders are enabled. Record only actual
  reminder presentations, and allow at most one interrupting sheet per purchase flow.
- Keep local template generation mandatory and deterministic. Phase 5 has no notification
  scheduling and no real Foundation Models call.

## Phase 6 — Notifications, CSV export, privacy controls
Status: Done
- Request local-notification permission only from an explicit user action; background and
  foreground reconciliation must never prompt implicitly.
- Schedule only cooling-off review reminders, with stable per-plan identifiers, quiet-hour
  deferral, exact cancellation, documented item-name review copy, and no amount or raw-note
  input; isolate corrupt plans without blocking valid reminders.
- Export the expense ledger as an ephemeral RFC 4180 CSV with exact minor-unit conversion,
  raw-note disclosure, UTF-8 BOM, and spreadsheet-formula neutralization.
- Delete local data through the ordered notification → Spotlight → SwiftData → preferences
  pipeline; verify all model counts are zero before preference reset, stop on the first
  failure, and never report a partial deletion as success.

## Phase 7 — Ask fallback and AI layer
Status: Todo
- Keep `ExpenseDetail` and every raw note outside redactor/model input APIs. Privacy tests
  must prove only allow-listed aggregate contexts can reach a generator.
- Keep raw cooling-off completion/outcome timestamps outside model contexts; expose only
  deterministic aggregate outcome counts.

## Phase 8A — App Intents, App Entities, Spotlight (iOS 17+)
Status: Todo
- Gate merchant-name indexing on the centralized Spotlight capability, the global
  merchant-name opt-in, and at least one eligible expense with the same normalized key.

## Phase 8B — IndexedEntity and onscreen awareness (iOS 26+)
Status: Todo

## Phase 9 — Polish, tests, accessibility, TestFlight readiness
Status: Todo
- Add an explicit, localized repair action for unreadable or orphaned cooling-off records.
  Show the affected count, require confirmation, and never delete those records implicitly.
