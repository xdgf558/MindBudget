# APP_STORE_SUBMISSION

This is the working V1 submission package. It is a draft until the release archive is
validated under the owner's current China-region Apple Developer account.

## Build identity

- Product: MindBudget
- Version: 1.0.0
- Build: 1 for the first TestFlight upload; increment after every uploaded replacement.
- Category: Finance
- Device family: iPhone only
- Minimum OS: iOS 17.0
- Signing: Automatic, with no shared `DEVELOPMENT_TEAM` value. Select the owner's current
  China-region team locally immediately before Archive.
- Bundle ID: confirm the final identifier exists under that same team and matches the App
  Store Connect app record. Do not reuse an identifier owned by the previous account.

## Simplified Chinese metadata draft

Name: MindBudget

Subtitle: 更从容地规划每一笔消费

Description:

MindBudget 是一款以本地隐私为先的个人预算与消费复盘工具。你可以快速记录消费，
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

MindBudget has no login, server, or reviewer credentials. Complete onboarding with any supported
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
