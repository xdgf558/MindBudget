# APP_STORE_SUBMISSION

This is the working V1 submission package. It is a draft until the release archive is
validated under the owner's current China-region Apple Developer account.

## Build identity

- Product/brand: `花有数` in Simplified Chinese; `MindBudget` in English
- Brand line: 温和的预算与消费复盘工具
- Current source and uploaded TestFlight candidate: version 0.9.9, build 10 (transport accepted
  2026-09-01; delivery UUID `1b358d3b-4544-4617-ab47-5be69addc7a8`)
- Previous uploaded TestFlight candidate: version 0.9.8, build 9 (transport accepted 2026-08-17)
- Previous uploaded candidate: version 0.9.7, build 8 (transport accepted 2026-08-17)
- Earlier uploaded candidate: version 0.9.6, build 8 (transport accepted 2026-08-11)
- Earlier uploaded candidate: version 0.9.6, build 7 (transport accepted 2026-08-10)
- Earlier uploaded candidate: version 0.9.5, build 6
- Earlier uploaded candidate: version 0.9.4, build 5
- Earlier uploaded candidate: version 0.9.2, build 3
- Every uploaded build above is immutable. Build 10 is now the current processing replacement.
- Increment the build number after every uploaded replacement.
- Before any later candidate is archived or uploaded, raise both `CURRENT_PROJECT_VERSION` and the
  distribution inspector's expected build above 10; the current source value is not permission to
  reuse immutable `0.9.9 (10)`.
- Build-number uniqueness is scoped to the marketing version, so `0.9.6 (8)` and `0.9.7 (8)` coexist
  legitimately in App Store Connect. Uploading a second `0.9.7 (8)` would be rejected.
- Recorded gap: `0.9.6 (8)` was accepted on 2026-08-11 but never recorded here at the time, and
  `CURRENT_PROJECT_VERSION = 8` did not exist in this repository until `e1f2831` on 2026-08-17.
  That upload therefore did not come from any committed state; the likely cause is an Organizer
  export that left `manageAppVersionAndBuildNumber` enabled, letting Xcode auto-increment the build
  number without writing it back. Keep that option disabled so App Store Connect build numbers stay
  traceable to a commit; the 2026-08-17 export used `manageAppVersionAndBuildNumber: false`.
- Release boundary: the owner authorized Archive and transport upload of 0.9.7 (8) on 2026-08-16
  after COM-C3 passed independent review and green CI, and that upload completed on 2026-08-17.
  The owner then authorized the same narrow action for 0.9.8 (9) on 2026-08-17, a UI-only change
  set carrying no StoreKit, entitlement, pricing, network, or persistence change. Each
  authorization stops at the successful upload: no tester group, external Beta App Review, or App
  Store submission is performed here.
  The Production signed-configuration service remains undeployed, so its optional value trigger
  stays conservatively off on transport/offline failure and is never purchase or entitlement
  authority. The product owner retains all TestFlight assignment and later distribution actions.
- C6-03 owner entry on 2026-09-01 authorizes Archive and transport upload of reviewed build 10
  only after its exact source head passes independent review and hosted CI and merges to `main`.
  The authorization still excludes tester-group assignment, external Beta App Review, App Store
  version submission, public release, G1, and Staging/Production service deployment.
- Independent review approved exact build-10 head `11ab612`, hosted run `33488815168` passed, and
  PR #95 merged it as `d5d0959`. A cloud-managed Apple Distribution export passed the closed
  distribution inspector. App Store Connect accepted `0.9.9 (10)` at
  `2026-09-01 19:27:25 +0800` with delivery UUID
  `1b358d3b-4544-4617-ab47-5be69addc7a8` and began processing. No tester group, external Beta App
  Review, App Store submission, G1 decision, or public release followed; DEC-COM-090 records that
  exact boundary.
- Public launch version: reserve 1.0.0 for the first approved App Store release.
- Category: Finance
- Device family: iPhone only
- Minimum OS: iOS 17.0
- Signing: Automatic, with no shared `DEVELOPMENT_TEAM` value. Select the owner's current
  China-region team locally immediately before Archive.
- Bundle ID: confirm the final identifier exists under that same team and matches the App
  Store Connect app record. Do not reuse an identifier owned by the previous account.

## TestFlight build notes

### 0.9.9 (10) — Uploaded C6-03 TestFlight baseline; processing

This candidate brings the reviewed C4–C6 local-first work together without making any public-
release claim. Financial records remain authoritative on device; iCloud sync and first-party
analytics are separately disclosed, default off, and optional.

What to test:

- In Settings > Privacy and Security, review the Free iCloud sync and Product Analytics controls.
  Confirm neither starts without explicit consent, local use continues through network/account
  failures, and local Delete All remains available even when an optional remote deletion is
  pending. Cloud-conflict and retained-copy guidance must never expose record content.
- From Add Expense, choose Scan a Receipt. Confirm capture or one-photo selection stays on device,
  accepted merchant/date/total suggestions never overwrite fields edited after recognition began,
  and nothing enters the ledger until the ordinary Save action. Uncertain amounts must require
  manual review rather than being guessed.
- In Insights, confirm the 30-day category donut represents the full total and keeps a readable
  Dynamic Type-aware key. Pattern cards may show supporting/total samples and an integer evidence
  ratio without presenting that ratio as a probability.
- In MindBudget Pro, exercise verified subscription, trial, grace, billing-retry, expiry, restore,
  and unavailable-authority presentation. Purchase must remain disabled unless StoreKit has an
  exact actionable Free result; network/configuration failure must not revoke verified local Pro.
- At AX5 in English and Simplified Chinese, confirm the four-tab chrome remains reachable while
  page content continues to grow, and Pro, Terms, and Privacy keep a visible system back indicator
  in all three skins.
- Enable Product Analytics only after reading its disclosure. Exercise the reviewed closed actions,
  then disable/delete it. No amount, merchant, category, note, receipt text/image, Product ID,
  CloudKit record, locale, or device/advertising identifier should be collected.
- Upgrade an existing store, exercise budget/category upper bounds, then restart. Valid history
  must remain intact; recovery failures must preserve the original store rather than silently
  rewriting invalid money to zero.

Known boundaries: this baseline does not claim same-account two-device iCloud convergence,
background-push delivery, complete physical VoiceOver/Instruments/system-side-effect coverage,
Production Worker or CloudKit-schema deployment, tester assignment, G1 evidence, or public release.

### 0.9.8 (9) — Uploaded internal test candidate

This build changes presentation only. No StoreKit, entitlement, pricing, notification, network,
calculation, or persistence behaviour changed, so anything that looks different in those areas is
a defect worth reporting.

What to test:

- Open Settings. Confirm the destinations are grouped under Budget, Reminders and Intelligence,
  Subscription, General, Privacy, and About, that the Budget group's footer explains how income,
  savings goal, and fixed expenses decide the spendable amount, and that VoiceOver announces each
  group heading before the rows inside it.
- Open Settings > General > Language. Confirm language now has its own entry rather than living
  inside Appearance and skins, that all options appear on one screen without pushing another, and
  that switching language updates the screen you are on, including its navigation bar title,
  without relaunching.
- Confirm MindBudget Pro, Restore Purchases, Manage Subscription, and every previously reachable
  Settings page are still reachable after the regrouping, and that no page lost content.
- In Insights, confirm the screen is grouped into This cycle, Long-term goals, Where money went,
  and the patterns list, and that each group heading is announced by VoiceOver.
- Confirm the category chart's colours match the skin you selected rather than looking like system
  colours, in all three skins, and that the key still names every category. Neighbouring segments
  should be easy to tell apart.
- With no recorded spending in the cycle, confirm the 30-day trend still appears under the
  "Where money went" heading rather than as a card with no group above it.
- Confirm amounts, totals, category shares, savings progress, and the 30-day figures are unchanged
  from build 8 for the same data.

### 0.9.7 (8) — Uploaded internal test candidate

What to test:

- Open Settings > MindBudget Pro. Confirm Monthly and Annual rows use current StoreKit prices and
  terms, purchase begins only after an explicit tap, and Restore Purchases plus Manage Subscription
  remain available. An unavailable or unverified StoreKit state must pause purchase and offer a
  recheck instead of being described as Free.
- For an eligible introductory trial, confirm the Pro and Dashboard surfaces use StoreKit's actual
  renewal date and verified next-renewal product. If notifications are already allowed, at most one
  generic local reminder may be scheduled; the app must never request permission automatically or
  put a date, price, amount, product, or remaining-day count in notification copy.
- Exercise verified billing grace, billing retry, expiry, and revocation. Grace retains Pro. The
  other states keep local data and Free capabilities, show calm bilingual guidance, and provide
  Manage Subscription/Recheck without opening an automatic paywall or a second purchase in retry.
- Disable networking or leave the Production configuration endpoint unavailable. Confirm the
  optional Pro value trigger stays hidden while the permanent Settings Pro entry, restore/manage
  controls, StoreKit authority, and every Free trust capability continue to work.
- In Insights, confirm an older stored “budget still has a buffer” entry is not shown as a current
  balance. The current cycle's recorded spending must remain authoritative. Confirm the 30-day
  category donut and its Dynamic Type-aware key represent the entire 30-day total; six categories
  keep all six names, while seven or more combine only the remainder.
- Repeat the upgrade, export, Delete All, Face ID, Siri, notification, localization, three-skin,
  VoiceOver, and AX5 checks from the prior candidates because build 8 replaces build 7.

### 0.9.6 (7) — Uploaded internal test candidate

What to test:

- Open initial budget setup and Settings > Budget. Confirm the fields read Income this month,
  Expected expenses, and Savings goal, with no manual fixed-expense field. With income 20,000,
  Expected expenses 8,000, and savings 2,000, both the preview and Today must use 18,000 as the
  starting disposable amount. Allocate extra income to the spending budget and confirm it appears
  in both places; merely recording income must not change either amount.
- Upgrade a real Schema V3 store through the lightweight Schema V3-to-V4 migration whose current
  plan has income 8,000 / Expected expenses 6,000 and another whose plan has income 0 / Expected
  expenses 6,000. Confirm both keep the old Expected expenses funding base for the current cycle,
  Settings previews the same amount and explains the next-cycle switch, and saving another budget
  field preserves the plan's legacy authority for this cycle. Record or reconcile an actual fixed
  expense within that amount and confirm availability does not fall a second time; only an excess
  above the reservation is an additional deduction. Confirm the next automatically copied cycle
  retires the legacy value and switches to the income basis. Confirm a genuinely new zero-income
  plan remains at zero instead of borrowing Expected expenses. For a new plan, confirm an actual
  fixed expense reduces the cycle balance once while today's reference amount is rebalanced across
  the remaining days.

### 0.9.5 (6) — Uploaded internal test candidate

What to test:

- In Insights, create a total savings goal with a starting balance, then allocate part of an income
  to savings. Confirm the separate Savings Progress module shows the exact target, confirmed saved
  total, remaining amount, and completion percentage. Exceeding the target must show 100% and zero
  remaining rather than a negative amount; an unreadable goal must not hide spending insights.
- Switch the app language between Follow System, Simplified Chinese, and English, then check the
  Apple Intelligence status and try Ask, reminder, and cycle-summary wording. The support check and
  generated answer must follow the selected app language immediately. An unsupported selection
  must be described as a language issue with a suggestion to choose Follow System or another
  supported language, never as a region issue.
- In Debug on a compatible iOS 26 device, confirm wrong-language model output still falls back to
  the matching deterministic template. No raw question, note, transaction row, or savings-goal row
  may enter the model context. In Settings > About, confirm `0.9.5` is expanded while `0.9.4` and
  earlier versions remain collapsed in history.
- Record an expense that is positive but uses less than 1% of the cycle budget and confirm Cycle
  Overview says “less than 1%” rather than `0%`. With a positive budget and no spending, confirm it
  says exactly `0%`; with no usable budget baseline, confirm it does not invent a percentage.
- Exercise Ask with enhancement disabled or unavailable, a forced timeout, a rejected model
  proposal, and a model error. Confirm the complete deterministic answer remains available and its
  localized source detail accurately distinguishes each local-template fallback reason. App-owned
  suggested actions must remain localized and must never render internal identifiers.
### 0.9.4 (5) — Internal test candidate

What to test:

- In Settings > Appearance, switch among Follow System, Simplified Chinese, and English without
  changing the iPhone language. Confirm visible copy, currency/date formatting, Ask templates,
  app-owned notifications, Spotlight copy, Log category search, and the CSV filename follow the
  selected app language immediately without relaunching. Return to Follow System and confirm normal
  system-language behavior.
- Record several incomes and leave allocation empty on one. On others, allocate exact portions to
  this cycle's spending budget and to savings. Confirm the unallocated income changes no budget,
  spending allocation changes only the containing cycle's budget, savings allocation changes only
  total-goal progress, and the form rejects a combined allocation above the income amount. Change
  an income to a historical date and confirm the exact containing cycle is shown; when no saved
  cycle exists, spending allocation is refused rather than silently targeting the current cycle.
- Edit and delete those incomes and confirm the current budget and total savings progress update
  from the authoritative remaining allocations rather than retaining stale amounts.
- Create a total savings goal with an existing saved balance. Confirm it continues across budget
  cycles and remains distinct from the savings amount reserved inside an individual budget cycle.
- Record an expense with “Repeat monthly as a fixed expense.” Confirm the original entry is saved
  once, the next monthly entry appears at the same local day/time, a day 29/30/31 rule clamps to the
  last valid day of a shorter month, and reopening the app never creates a duplicate occurrence.
- In Settings > Recurring fixed expenses, edit a rule and confirm only future entries use the new
  values. Pause it across a due month and resume it; confirm paused months are not backfilled.
  Move a rule's date into the current month before its new due day and confirm that occurrence is
  still generated. Delete the rule and confirm generated history stays in Log. A combined catch-up
  above 120 occurrences must save only the globally oldest 120 in one foreground transaction,
  show a neutral pending-work notice in Settings without a failure warning, and continue the next
  oldest batch on a later foreground activation without duplicates.
- Upgrade an existing 0.9.2 installation and confirm prior income, expenses, budget, wishes,
  cooling-off records, settings, and skin remain intact. Existing income must show zero allocation
  until the owner explicitly changes it.
- Export CSV and confirm version 0.9.4 appends exact spending/savings allocation minor-unit columns
  after the existing unified-ledger columns; update any saved import/formula template for the
  extended header. Income rows must leave expense-only fields empty. Run Delete All and confirm
  the app reports completion only after allocations, savings goal, recurring rules, occurrences,
  and all previous models are observed empty.
- Check the enlarged budget-pace App Icon on the Home Screen in standard, dark, and tinted
  appearances. Confirm the filled track and marker stay distinct, no transparent fringe or double
  corner appears, and the language-specific app name remains unchanged.
- Open Settings > About and confirm version `0.9.4` is expanded while `0.9.2`, `0.9.1`, and `0.9.0`
  remain inside collapsed history.

### 0.9.2 (4) — Replacement internal test candidate

What to test:

- Save several discretionary expenses today and confirm each one reduces “Left to spend today” by
  the same amount. Confirm fixed and savings entries do not consume the discretionary daily amount.
- Spend exactly the remaining daily amount and confirm Today displays zero in red with a localized
  “fully used” explanation. Spend beyond it and confirm the value stays at zero while a separate
  localized line shows the exact amount above today's reference; no negative amount may appear.
- Configure a cycle whose flexible budget is fully reserved before recording anything today.
  Confirm Today displays zero in the attention color together with the localized explanation that
  no daily amount is currently available; the zero must never appear without context.
- Open Add Expense and swipe the category selector from the first category through the final
  category. Select an offscreen category, confirm it receives the selected appearance and VoiceOver
  state, save, and confirm the chosen category appears in Today and Log.
- With the app in Simplified Chinese, open Log > Filters and confirm the record types read
  `全部` / `支出` / `收入` and the budget types read `固定` / `灵活` / `储蓄`; no
  `ledger.type.*` or `bucket.*` catalog key may appear.
- Repeat the core `0.9.2 (3)` income, 30-day Insights, wishlist-limit, migration, CSV, and Delete All
  checks below because build 4 replaces that uploaded candidate.

### 0.9.2 (3) — Previous uploaded internal candidate

What to test:

- Use both the Today empty-state Add entry action and the center Add button; confirm each first
  asks Expense or Income. Record one of each and confirm Log merges them in
  chronological order, can filter by All / Expenses / Income, and permits income detail, edit,
  note search, and deletion without changing the configured budget or Today allowance.
- While an expense category or budget-bucket filter is active, switch to Income and confirm saved
  income remains visible; switch back to Expenses and confirm the expense-only filters are kept.
- On a fresh setup, type a monthly income and confirm the spending-budget field remains untouched;
  enter the intended spending budget separately, save, and confirm Today uses that amount.
- Upgrade over an existing 0.9.1 store and confirm its expenses, budget, wishlist, cooling-off
  history, selected skin, and settings remain intact; the new income ledger should begin empty.
- Add expenses on today, exactly 29 calendar days ago, and 30 days ago. Confirm Insights includes
  the first two, excludes the last, and shows a 30-day total, category/emotion breakdowns, and
  exactly 30 daily positions.
- From another tab, save an expense and then open Insights. Confirm its amount, count, current-cycle
  total, category breakdown, and daily point refresh immediately rather than retaining an old zero.
- With the unreadable-cooling-record test fixture, confirm Insights still shows the exact expense
  totals plus a partial-data notice, but shows no cycle narrative or old cooling-success card and
  does not invoke the optional wording enhancement.
- Add five open wishlist items. Confirm the sixth is rejected with a clear message in both the app
  and Siri, then archive or finish one and confirm a replacement can be added. Historical
  purchased, skipped, and archived items must not consume an open slot.
- Export CSV and confirm both `expense` and `income` rows appear with exact amount and minor-unit
  columns. Confirm the export disclosure names raw notes/source or merchant fields, and Delete All
  removes both record types before reporting completion.
- Open Settings > About and confirm version `0.9.2` is expanded while `0.9.1` and `0.9.0` remain
  inside collapsed history.

### 0.9.1 (2) — Previous internal test candidate

What to test:

- Confirm Simplified Chinese consistently shows the product name `花有数`, including Ask,
  Settings, Siri/App Shortcuts, errors, privacy copy, and exported filenames; English continues
  to show `MindBudget`.
- Open Settings > Appearance and Skins, switch among Aurora Glow, Warm Botanical, and Neon Pulse,
  then relaunch the app and confirm the selected skin persists across Today, Log, Add Expense,
  Insights, Wishlist, Ask, onboarding, and Settings. Confirm that Aurora visibly includes teal
  aurora, stars, and lower waves; Warm Botanical includes ivory paper, leaves, and natural shadows;
  Neon Pulse includes purple/cyan grid and light-trail motifs. None of the backgrounds should
  contain baked-in text, controls, status bars, or screenshots.
- Confirm all three initial skins are included without a lock, price, paywall, or PRO message.
- With larger text and VoiceOver, verify every skin preserves readable contrast, selected-state
  announcements, touch targets, and the custom bottom-navigation order.
- Open Settings > About and confirm the installed version is `0.9.1` and its localized update
  summary describes the three skins, complete background artwork, Chinese product-name update,
  and cold-launch animation.
- Force-quit and cold-launch once in Simplified Chinese and once in English. Confirm the selected
  skin appears behind the short budget-track animation and the name is respectively `花有数` or
  `MindBudget`. Returning from the background must not replay it. With Reduce Motion enabled, the
  same brand layer must use a brief fade only, without translation or scale motion.
- In Simplified Chinese, enable on-device enhancement and ask how much budget remains. Confirm the
  answer title, body, and both actions remain Chinese; an English model proposal must silently use
  the complete Chinese template rather than appear as mixed-language output or raw catalog keys.
- Open Settings > Budget, change the current period's income or spending budget, and save. Confirm
  the updated Dashboard reflects the value, the period boundaries and accounting currency do not
  change, and a revised cycle start day is described as a future-period setting.
- With spending budget CNY 6,000, fixed expenses CNY 3,000, and savings goal CNY 500, confirm the
  flexible preview is CNY 2,500 and Today shows the recalculated per-day amount. Record an expense
  and confirm the Today amount rebalances without becoming a double-subtracted negative value.
- Under Settings > Privacy controls, enable the optional Face ID app lock. Confirm enabling and
  disabling both require authentication, cancellation stays locked, cold launch and foreground
  return are covered, device passcode is offered as recovery, and the app-switcher snapshot never
  shows financial content.
- Open Settings > About. Confirm only 0.9.1 is expanded and 0.9.0 remains inside collapsed history.

### 0.9.0 (1) — Internal test candidate

What to test:

- Complete onboarding and save a first budget, then record and edit a manual expense.
- Check the standard, dark, and tinted icon plus the language-specific Home Screen name.
- Verify Today, Log, Insights, Wishlist, the center Add action, and the compact empty-state actions.
- Open Settings from Today. Confirm the first-level directory opens focused second-level pages,
  Simplified Chinese shows `柔和` for reminder tone, and no local Debug diagnostics appear.
- Exercise a wishlist cooling-off flow, notification controls, CSV export, and the two-step local
  deletion flow using synthetic data only.

For every replacement upload, increment the build number and copy its user-visible changes from
`Docs/CHANGELOG.md` into a new dated entry here before assigning internal testers.

## Simplified Chinese metadata draft

Name: 花有数

Subtitle: 温和的预算与消费复盘工具

Description:

花有数是一款以本地隐私为先的个人预算与消费复盘工具。你可以快速记录消费，
查看当前预算压力，并通过心愿单和冷静期，在购买前给自己一点思考空间。

所有预算、模式判断和金额计算都由确定性的本地代码完成。应用会帮助你回顾分类、
情绪背景与近期消费变化，但不会评价、羞辱或诊断你。Ask 功能始终提供本地模板回答；
在支持的设备上，你也可以自愿开启 Apple Intelligence，对已经计算好的事实进行
更自然的本机改写。

主要功能：

- 手动记账与周期预算
- 今日可用额度和消费节奏
- 情绪标签、心愿单与冷静期
- 本地规则洞察和温和提醒
- 可选的 Siri、快捷指令与 Spotlight 集成
- CSV 导出和完整的本地数据删除

V1 无需注册账号，不含广告、第三方分析、银行连接或云同步。财务记录保存在设备的
应用容器内；只有当你主动使用系统分享面板导出 CSV 时，数据才会发送到你选择的目的地。

Keywords: 预算,记账,消费,心愿单,冷静期,本地,隐私,账本

## English metadata draft

Name: MindBudget

Subtitle: A calmer way to plan spending

Description:

MindBudget is a local-first budgeting and spending-reflection tool. Record an expense quickly,
understand pressure in the current budget cycle, and use a wishlist or cooling-off period to
create a little space before a purchase.

Budget math, pattern detection, and financial conclusions are calculated by deterministic code
on your device. MindBudget can help you review categories, optional emotional context, and
recent changes without judging, shaming, or diagnosing you. Ask always has complete local
template answers; on supported devices, you may optionally enable Apple Intelligence to rewrite
already-computed facts more naturally on device.

Features include manual expense tracking, cycle budgets, a daily spending pace, wishlists,
cooling-off periods, local insights, gentle reminder controls, optional Siri/Shortcuts/Spotlight
integration, CSV export, and complete local deletion.

V1 requires no account and includes no ads, third-party analytics, bank connection, or cloud
sync. Financial records stay inside the app container unless you explicitly export a CSV through
the system share sheet to a destination you choose.

Keywords: budget,expenses,spending,wishlist,cooling off,local,privacy,tracker

## Screenshot story

Capture the currently required iPhone display sizes from the release build, in both Simplified
Chinese and English where App Store Connect requests localization:

1. Today — daily allowance and cycle pace without invented or judgmental claims.
2. Add Expense — fast exact entry with optional context.
3. Purchase Pause — a calm reminder with Continue Purchase available.
4. Insights — deterministic category and pattern summaries.
5. Wishlist — cooling-off status and review choices.
6. Privacy — local-only explanation, CSV export, integrations, and Delete All.

For the final commercialization listing, show the voluntary Pro screen only with terms loaded by
StoreKit from the release account. Do not show local-fixture prices or trial duration, Lifetime,
cloud-AI quotas, deferred receipt/iCloud/Watch capabilities, or any other incomplete product.
Do not capture final commerce screenshots until the owner has approved the formal products and
economics and the Production configuration/final Release binary gates have passed. Use realistic
synthetic data with no real names, notes, merchants, or finances.

## App Review notes draft

MindBudget has no account login or reviewer credentials. Its optional local Face ID app lock is
off by default. Complete onboarding with any supported
currency, enter a budget, and add a manual expense to reach the main flows. All core behavior is
available without Apple Intelligence, Siri, notifications, or Spotlight. Those integrations are
independently off by default and can be enabled in Settings. Apple Intelligence is an optional
on-device wording enhancement; deterministic local templates remain the baseline.

The app stores user data locally and declares no developer data collection or tracking. CSV data
leaves the app only after the user explicitly invokes the system share sheet. Delete All requires
two confirmations, then cancels app notifications, clears the app-owned Spotlight domain, deletes
all local models, verifies the store is empty, and resets preferences. Emotion tags are optional
user-selected spending context, not a mental-health assessment or diagnosis.

Draft commercialization review path: Settings > MindBudget Pro is voluntary; there is no
automatic blocking paywall. Apple StoreKit supplies product names, localized price/period,
introductory-offer eligibility, purchase confirmation, Restore Purchases, Manage Subscription,
and verified subscription state. Billing grace retains Pro. Billing retry, expiry, and revocation
return to Free while preserving local data and show a non-blocking localized status card with
Manage Subscription and Recheck actions. The app receives no card details. A local test fixture's
price and seven-day offer are not customer terms and must not appear in the final submission.

The only app-owned network request currently implemented is a first-party anonymous signed public-
configuration `GET /v1/config`. It sends bounded app/config-version headers and no account, device,
advertising, locale, storefront, StoreKit, ledger, note, or other user-content field. Cloudflare's
edge necessarily receives ordinary connection metadata such as an IP address. Development is the
only deployed environment today; this paragraph is a draft, not Production evidence. Revalidate
the exact Production host/key, captured final-binary traffic, Worker logging/storage settings,
App Privacy answers, and all wording before submission.

## App Privacy draft

- Data collected by the developer: None
- Tracking: No
- Third-party advertising or analytics: None
- Account data: None
- User-initiated export: disclosed in-app and not retained as a second app file

Re-check these answers against the final archive before submission. A future commerce phase,
backend, analytics SDK, crash reporter, or cloud feature would require a new privacy review.
