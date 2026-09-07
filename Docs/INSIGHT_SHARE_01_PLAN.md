# INSIGHT-SHARE-01 — Current-cycle income and share card

Status: **Queued after FX-01D; requirements captured; implementation unentered.**

## Owner-requested outcome

Add recorded current-cycle income to Insights. Add a previewable image card that the user can
share to WeChat Moments or X. The owner's latest instruction adds income to the earlier
three-field card: the final content is current-cycle dates, total income, total spending and
spending-category totals. Do not include remaining budget, per-entry detail, merchants, income
source names, notes, emotion tags, location, personal identifiers or raw AI output.

This is a separate product task after D, not another FX-01D consumer acceptance requirement.
No share implementation, third-party SDK, service enablement or posting permission is granted
by a planning entry. The user must preview the exact outgoing image and actively choose a
destination; never publish automatically or treat displaying a share sheet as proof of a post.

## Proposed data and privacy contract

- Resolve the same current budget cycle/currency used by Insights: prefer the actual current
  plan's stored interval; otherwise use the existing calendar-aware cycle calculator. Use the
  user's Calendar/TimeZone and half-open interval [start, end), not a fixed number of days.
- "Income" means saved Income records received within that interval, not planned salary,
  allocated spending permission, budget capacity or AI inference. Sum each record once and do
  not add its budget/savings allocations again. Showing income does not increase a budget.
- Sum expense and income Int64 minor units with overflow checks in the selected accounting
  currency. Expense totals and categories use only saved accounting amounts, including FX;
  never sum original foreign amounts or fetch a newer rate. Different currencies must not be
  silently mixed or converted. No foreign-currency income feature is added.
- Current Insights category/daily aggregates are recent-30-day data. Build a separate
  current-cycle category projection for this card; do not reuse that chart under cycle labels.
  The card's category total must close exactly to its displayed spending total.
- Use one immutable period/currency/data snapshot for preview and the exported image. Regenerate
  after changes; do not export stale totals after reload failure or account/currency changes.
  A failed income read is unavailable, not zero: preserve valid on-screen spending but block
  an apparently complete financial card. Empty successful data is different from unreadable data.
- Render on device without uploading a ledger or contacting an AI/provider. Include a neutral
  currency code and localized dates/labels; no shame, score, invented saving or financial advice.
- Limit the share payload to the approved rendered card, not a CSV, ledger object, raw note,
  exact-data URL parameter or extra hidden metadata. Explain that recipients can save/forward
  the financial image and that deleting local records cannot retract published copies.
- Prefer the existing user-invoked system-sharing approach. WeChat Moments and X availability,
  supported image formats and device behavior must be verified separately; do not promise
  direct posting or invent URL schemes. No automatic login, social account connection, SDK,
  new domain, full photo-library read or background transmission is in the proposed scope.

## Implementation and acceptance checklist

- [ ] Use the owner-required Product Design skill for UI design. Ground the income tile/card
  in the existing MindBudget components, themes, localized typography and accessibility rules;
  confirm the visual target before implementation rather than inventing an unrelated style.
- [ ] Confirm Free/Pro access and the image-delivery/fallback UX before implementation; do not
  silently add a paid gate or StoreKit product. Owner-approved content is fixed as above.
- [ ] Add deterministic current-cycle income/category snapshot and tests for actual vs planned
  income, allocations, currency isolation, locked FX amounts, cycle boundaries, time zones/DST,
  overflow, empty data, read failure and reload races.
- [ ] Add the current-cycle income tile to Insights with English/Simplified Chinese labels,
  formatting, accessible order/value and explicit unavailable state.
- [ ] Add a local-only card preview and explicit share action; prove the exported image matches
  the preview snapshot and contains only approved fields, including no hidden financial extras.
- [ ] Verify text fitting, large amounts, long category labels, zero-data cycles, dark/light,
  AX5 and both languages. A raster card needs an accessible textual summary in its preview.
- [ ] Verify actual user-invoked WeChat Moments and X delivery on an owner-authorized device,
  without auto-posting. Retain unavailable/cancelled/unexecuted paths as non-pass, not success.
- [ ] Review privacy/export disclosures and network/telemetry boundaries, then full validation,
  independent PR review, exact-head hosted CI and merge before marking this task complete.

## Boundaries

Do not modify the FX-01D completion criteria to include sharing. Do not enter FX-02, enable Luna,
add social analytics, change subscription/trial clocks, or authorize COM-C12/Archive/upload/release.
Free/Pro policy and exact social-app delivery are outstanding decisions/verification, not implied
by the owner's choice of financial fields. No code, runtime pass or release evidence is claimed.
