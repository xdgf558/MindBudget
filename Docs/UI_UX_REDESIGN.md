# UI/UX redesign handoff

This interlude applies the owner's `MindBudget UIUX重新设计` handoff before Phase 10.
It changes presentation and navigation only; SwiftData models, calculation rules,
privacy boundaries, reminder throttling, and system-integration gates remain authoritative.

## Shipped surface

- Four destinations are real tabs: Today, Log, Insights, and Wishlist.
- The center add control is a separate, accessible action rather than a fake tab.
- Settings opens from Today.
- Existing free flows use the shared Canvas/Surface/Ink/Accent/Attention tokens, rounded
  cards, consistent primary and secondary actions, and localized copy.
- Today receives its money and pace facts from `BudgetEngine`; views format facts but do
  not calculate financial values.
- Add Expense uses an app-owned, locale-aware keypad. Behavioral reminders use a
  full-screen pause surface with the existing 2–4-action safety contract.

## Reserved commerce seams

Paid capabilities from the design handoff are deliberately not user-visible in this
interlude. There is no StoreKit product, entitlement state, quota counter, locked chart,
paywall, trial message, or paid custom-rule editor.

If commercialization is approved later, integrate it as a separate phase at these
existing composition boundaries:

- Insights: between the local summary/charts and insight cards.
- Ask: between question input and the answer surface; the template fallback remains
  available independently of any entitlement.
- Settings: as its own section, not mixed into privacy or system-integration controls.
- Reminder rules: as a destination backed by a real rule model, never as a dead row.

Until those capabilities exist end to end, each seam renders nothing. Free behavior must
not be degraded in preparation for a future paid tier.

## Visual verification

The supplied handoff is light-mode-first. Semantic asset colors include conservative dark
variants so screens remain readable, but Phase 10 must still perform signed-device checks
for light/dark mode, Dynamic Type through AX5, VoiceOver order, Reduce Motion, narrow
iPhone widths, and keyboard avoidance.
