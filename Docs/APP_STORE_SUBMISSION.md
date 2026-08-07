# APP_STORE_SUBMISSION

This is the working V1 submission package. It is a draft until the release archive is
validated under the owner's current China-region Apple Developer account.

## Build identity

- Product/brand: `花有数` in Simplified Chinese; `MindBudget` in English
- Brand line: 温和的预算与消费复盘工具
- Next TestFlight candidate: version 0.9.2, build 3
- Previous internal candidate: version 0.9.1, build 2
- Increment the build number after every uploaded replacement.
- Public launch version: reserve 1.0.0 for the first approved App Store release.
- Category: Finance
- Device family: iPhone only
- Minimum OS: iOS 17.0
- Signing: Automatic, with no shared `DEVELOPMENT_TEAM` value. Select the owner's current
  China-region team locally immediately before Archive.
- Bundle ID: confirm the final identifier exists under that same team and matches the App
  Store Connect app record. Do not reuse an identifier owned by the previous account.

## TestFlight build notes

### 0.9.2 (3) — Next internal test candidate

What to test:

- Use the center Add button to record both an expense and an income. Confirm Log merges them in
  chronological order, can filter by All / Expenses / Income, and permits income detail, edit,
  note search, and deletion without changing the configured budget or Today allowance.
- Upgrade over an existing 0.9.1 store and confirm its expenses, budget, wishlist, cooling-off
  history, selected skin, and settings remain intact; the new income ledger should begin empty.
- Add expenses on today, exactly 29 calendar days ago, and 30 days ago. Confirm Insights includes
  the first two, excludes the last, and shows a 30-day total, category/emotion breakdowns, and
  exactly 30 daily positions.
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

Do not show prototype Pro locks, trial language, prices, paywalls, or paid-rule controls; none are
implemented in V1. Use realistic sample data with no real names, notes, merchants, or finances.

## App Review notes draft

MindBudget has no account login, server, or reviewer credentials. Its optional local Face ID app
lock is off by default. Complete onboarding with any supported
currency, enter a budget, and add a manual expense to reach the main flows. All core behavior is
available without Apple Intelligence, Siri, notifications, or Spotlight. Those integrations are
independently off by default and can be enabled in Settings. Apple Intelligence is an optional
on-device wording enhancement; deterministic local templates remain the baseline.

The app stores user data locally and declares no developer data collection or tracking. CSV data
leaves the app only after the user explicitly invokes the system share sheet. Delete All requires
two confirmations, then cancels app notifications, clears the app-owned Spotlight domain, deletes
all local models, verifies the store is empty, and resets preferences. Emotion tags are optional
user-selected spending context, not a mental-health assessment or diagnosis.

## App Privacy draft

- Data collected by the developer: None
- Tracking: No
- Third-party advertising or analytics: None
- Account data: None
- User-initiated export: disclosed in-app and not retained as a second app file

Re-check these answers against the final archive before submission. A future commerce phase,
backend, analytics SDK, crash reporter, or cloud feature would require a new privacy review.
