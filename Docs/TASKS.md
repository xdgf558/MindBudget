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
Status: Todo
- Add a dismissible, locale-aware amount-reasonableness warning. The currency-neutral
  storage-safety boundary remains the only hard amount limit.

## Phase 4 — Emotion tags, wishlist, cooling-off
Status: Todo

## Phase 5 — Rule engine, reminder throttle, template reminders, insights
Status: Todo

## Phase 6 — Notifications, CSV export, privacy controls
Status: Todo

## Phase 7 — Ask fallback and AI layer
Status: Todo

## Phase 8A — App Intents, App Entities, Spotlight (iOS 17+)
Status: Todo
- Gate merchant-name indexing on the centralized Spotlight capability, the global
  merchant-name opt-in, and at least one eligible expense with the same normalized key.

## Phase 8B — IndexedEntity and onscreen awareness (iOS 26+)
Status: Todo

## Phase 9 — Polish, tests, accessibility, TestFlight readiness
Status: Todo
