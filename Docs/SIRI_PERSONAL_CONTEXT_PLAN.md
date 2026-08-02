# SIRI_PERSONAL_CONTEXT_PLAN

## Goal

Expose MindBudget's own actions and data to Siri, Spotlight, Shortcuts, and Apple
Intelligence without reading another app's private data.

## Allowed

1. App Intents for MindBudget actions.
2. App Entities for MindBudget data.
3. Core Spotlight for a redacted, app-owned local index.
4. `IndexedEntity` when the installed SDK and runtime support it.
5. Onscreen awareness through `NSUserActivity` and `.appEntityIdentifier` when available.
6. Structured parameters resolved by the system on the user's behalf.

## Forbidden

1. Direct iMessage, voicemail, or Mail access.
2. Full photo-library scanning.
3. Private APIs.
4. Persisting externally sourced context without explicit confirmation.
5. Exact amounts in entity display representations.
6. Treating Siri-provided strings as trusted input.

## Required intents

`RecordExpenseIntent`, `AddWishlistItemIntent`, `CheckBudgetImpactIntent`,
`AnalyzeEmotionalSpendingIntent`, `CreateCoolingOffReminderIntent`,
`SuggestAlternativeIntent`, `FindRecentSpendingPatternIntent`,
`OpenWishlistItemIntent`, and `OpenBudgetDashboardIntent`.

## Required entities

`ExpenseEntity`, `BudgetSnapshotEntity`, `WishlistItemEntity`,
`CoolingOffPlanEntity`, `MerchantEntity`, `SpendingInsightEntity`, and
`EmotionTagEntity`.

## Release-time question

Review the current App Schema domains before every release. Prefer an official
schema over a custom intent only when the current SDK exposes a suitable,
compilable personal-finance, list, or reminder domain. Record evidence in
`Docs/DECISIONS.md`.
