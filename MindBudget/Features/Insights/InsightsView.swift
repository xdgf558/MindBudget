import Charts
import SwiftUI

struct InsightBreakdown: Identifiable, Equatable, Sendable {
    let id: String
    let labelKey: String
    let amount: Money
}

struct InsightDailyTotal: Identifiable, Equatable, Sendable {
    var id: Date { date }
    let date: Date
    let amount: Money
}

struct InsightDashboardSummary: Equatable, Sendable {
    let lastThirtyDaysTotal: Money
    let lastThirtyDaysCount: Int
    let currentCycleTotal: Money
    let categoryTotals: [InsightBreakdown]
    let emotionTotals: [InsightBreakdown]
    let dailyTotals: [InsightDailyTotal]
}

struct InsightSummaryBuilder: Sendable {
    func build(
        expenses: [ExpenseSummary],
        cycle: DateInterval,
        currencyCode: String,
        now: Date,
        calendar: Calendar
    ) throws -> InsightDashboardSummary {
        let today = calendar.startOfDay(for: now)
        guard let firstDay = calendar.date(byAdding: .day, value: -29, to: today),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            throw DataValidationError.invalidBudgetCycle
        }
        let recentExpenses = expenses.filter {
            firstDay <= $0.spentAt && $0.spentAt < tomorrow
                && $0.amount.currencyCode == currencyCode
        }
        let cycleExpenses = expenses.filter {
            cycle.start <= $0.spentAt && $0.spentAt < cycle.end
                && $0.amount.currencyCode == currencyCode
        }
        let categoryTotals = try Dictionary(grouping: recentExpenses, by: \.category)
            .map { category, values in
                InsightBreakdown(
                    id: category.rawValue,
                    labelKey: category.localizedNameKey,
                    amount: Money(
                        minorUnits: try checkedSum(values.map(\.amount.minorUnits)),
                        currencyCode: currencyCode
                    )
                )
            }
            .sorted { $0.amount.minorUnits > $1.amount.minorUnits }
        let tagged = recentExpenses.compactMap { expense in
            expense.emotionTag.map { ($0, expense) }
        }
        let emotionTotals = try Dictionary(grouping: tagged, by: { $0.0 })
            .map { emotion, values in
                InsightBreakdown(
                    id: emotion.rawValue,
                    labelKey: emotion.localizedNameKey,
                    amount: Money(
                        minorUnits: try checkedSum(values.map(\.1.amount.minorUnits)),
                        currencyCode: currencyCode
                    )
                )
            }
            .sorted { $0.amount.minorUnits > $1.amount.minorUnits }
        let groupedDays = Dictionary(grouping: recentExpenses) {
            calendar.startOfDay(for: $0.spentAt)
        }
        let dailyTotals = try (0..<30).map { offset -> InsightDailyTotal in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else {
                throw DataValidationError.invalidBudgetCycle
            }
            return InsightDailyTotal(
                date: day,
                amount: Money(
                    minorUnits: try checkedSum(
                        groupedDays[day, default: []].map(\.amount.minorUnits)
                    ),
                    currencyCode: currencyCode
                )
            )
        }
        return InsightDashboardSummary(
            lastThirtyDaysTotal: Money(
                minorUnits: try checkedSum(recentExpenses.map(\.amount.minorUnits)),
                currencyCode: currencyCode
            ),
            lastThirtyDaysCount: recentExpenses.count,
            currentCycleTotal: Money(
                minorUnits: try checkedSum(cycleExpenses.map(\.amount.minorUnits)),
                currencyCode: currencyCode
            ),
            categoryTotals: categoryTotals,
            emotionTotals: emotionTotals,
            dailyTotals: dailyTotals
        )
    }

    private func checkedSum(_ values: [Int64]) throws -> Int64 {
        var total: Int64 = 0
        for value in values {
            let (next, overflow) = total.addingReportingOverflow(value)
            guard !overflow else { throw DataValidationError.invalidAmount }
            total = next
        }
        return total
    }
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var summary: InsightDashboardSummary?
    @Published private(set) var savingsGoal: SavingsGoalSummary?
    @Published private(set) var savingsGoalUnavailable = false
    @Published private(set) var insights: [SpendingInsightSummary] = []
    @Published private(set) var cycleNarrative: SourcedSummary?
    @Published private(set) var isLoading = true
    @Published private(set) var failed = false
    @Published private(set) var partialDataUnavailable = false
    private var latestLoadID: UUID?

    func load(
        dataActor: DataActor,
        currencyCode: String,
        cycleStartDay: Int,
        configuration: RuleConfiguration,
        locale: Locale,
        tone: ReminderTone,
        enhancementEnabled: Bool,
        now: Date,
        calendar: Calendar
    ) async {
        let loadID = UUID()
        latestLoadID = loadID
        isLoading = true
        partialDataUnavailable = false
        do {
            async let expenseRequest = dataActor.fetchExpenseSummaries()
            async let planRequest = dataActor.fetchBudgetPlanSummaries()
            let expenses = try await expenseRequest
            let plans = try await planRequest
            guard isCurrent(loadID) else { return }
            let currentPlan = plans.first {
                $0.cycleStart <= now && now < $0.cycleEnd
            }
            let snapshot: BudgetSnapshot
            let categoryBudgets: [CategoryBudgetSummary]
            if let currentPlan {
                snapshot = try BudgetEngine().snapshot(
                    cycle: DateInterval(
                        start: currentPlan.cycleStart,
                        end: currentPlan.cycleEnd
                    ),
                    currencyCode: currentPlan.currencyCode,
                    expenses: expenses,
                    plan: currentPlan,
                    now: now,
                    calendar: calendar
                )
                categoryBudgets = currentPlan.categoryBudgets
            } else {
                let cycle = try BudgetCycleCalculator().interval(
                    containing: now,
                    startDay: cycleStartDay,
                    calendar: calendar
                )
                snapshot = .unconfigured(cycle: cycle, currencyCode: currencyCode)
                categoryBudgets = []
            }
            let dashboardSummary = try InsightSummaryBuilder().build(
                expenses: expenses,
                cycle: snapshot.cycle,
                currencyCode: snapshot.currencyCode,
                now: now,
                calendar: calendar
            )
            guard isCurrent(loadID) else { return }

            // Expense facts are authoritative and must remain visible even if an
            // optional cooling-off projection or derived insight cannot be refreshed.
            summary = dashboardSummary
            cycleNarrative = nil
            insights = []
            failed = false
            partialDataUnavailable = false
            isLoading = false

            do {
                savingsGoal = try await dataActor.fetchSavingsGoalSummary()
                savingsGoalUnavailable = false
            } catch {
                guard isCurrent(loadID) else { return }
                savingsGoal = nil
                savingsGoalUnavailable = true
            }
            guard isCurrent(loadID) else { return }

            let coolingPlans: [CoolingOffPlanSummary]
            do {
                coolingPlans = try await dataActor.fetchCoolingOffPlanSummaries()
            } catch {
                guard isCurrent(loadID) else { return }
                failed = true
                partialDataUnavailable = true
                // A failed projection means the outcome facts are unknown, not zero.
                // Keep the authoritative expense summary, but do not generate wording,
                // detect patterns, persist derived insights, or reload stale insight rows.
                return
            }
            guard isCurrent(loadID) else { return }

            let narrative = await CycleSummaryService().generate(
                snapshot: snapshot,
                expenses: expenses,
                coolingOffPlans: coolingPlans,
                locale: locale,
                calendar: calendar,
                tone: tone,
                enhancementEnabled: enhancementEnabled
            )
            guard isCurrent(loadID) else { return }
            cycleNarrative = narrative

            do {
                let historicalCycles = try CycleAggregateBuilder().build(
                    plans: plans,
                    expenses: expenses,
                    before: snapshot.cycle.start
                )
                let outcomes = coolingPlans.compactMap { plan -> CoolingOffOutcomeSummary? in
                    guard let outcome = plan.outcome,
                          let outcomeRecordedAt = plan.outcomeRecordedAt else { return nil }
                    return CoolingOffOutcomeSummary(
                        outcome: outcome,
                        outcomeRecordedAt: outcomeRecordedAt
                    )
                }
                let drafts = SpendingPatternDetector().detectPatterns(
                    expenses: expenses,
                    snapshot: snapshot,
                    categoryBudgets: categoryBudgets,
                    historicalCycles: historicalCycles,
                    coolingOffOutcomes: outcomes,
                    config: configuration,
                    now: now,
                    calendar: calendar
                )
                _ = try await dataActor.upsertSpendingInsights(drafts, createdAt: now)
                let storedInsights = try await dataActor.fetchSpendingInsightSummaries()
                guard isCurrent(loadID) else { return }
                insights = storedInsights.filter {
                    $0.periodStart == snapshot.cycle.start
                        && $0.periodEnd == snapshot.cycle.end
                }
            } catch {
                guard isCurrent(loadID) else { return }
                insights = []
                failed = true
                partialDataUnavailable = true
            }
        } catch {
            guard isCurrent(loadID) else { return }
            summary = nil
            savingsGoal = nil
            savingsGoalUnavailable = false
            cycleNarrative = nil
            insights = []
            failed = true
            partialDataUnavailable = false
            isLoading = false
        }
    }

    func dismiss(
        _ insight: SpendingInsightSummary,
        dataActor: DataActor,
        at date: Date
    ) async {
        do {
            try await dataActor.dismissSpendingInsight(id: insight.id, at: date)
            insights.removeAll { $0.id == insight.id }
        } catch {
            failed = true
        }
    }

    private func isCurrent(_ loadID: UUID) -> Bool {
        latestLoadID == loadID && !Task.isCancelled
    }
}

private struct InsightsLoadTrigger: Equatable {
    let revision: Int
    let isSelected: Bool
}

struct InsightsView: View {
    @Environment(\.mindBudgetTheme) private var theme
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .accessibilityLabel("common.loading")
                } else if viewModel.failed, viewModel.summary == nil {
                    ErrorStateView(messageKey: "error.data.load") {
                        Task { await load() }
                    }
                } else {
                    content
                }
            }
            .navigationTitle("tab.insights")
            .navigationBarTitleDisplayMode(.large)
            .task(
                id: InsightsLoadTrigger(
                    revision: session.revision,
                    isSelected: session.selectedTab == .insights
                )
            ) {
                guard session.selectedTab == .insights else { return }
                await load()
            }
        }
        .mindBudgetOnscreenListSelection(
            nil,
            userEnabled: settings.enableSiriIntegration
        )
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if viewModel.partialDataUnavailable {
                    partialDataWarning
                }
                if let summary = viewModel.summary {
                    summaryCards(summary)
                    if let narrative = viewModel.cycleNarrative {
                        cycleNarrativeCard(narrative)
                    }
                    savingsProgressCard
                    spendingCharts(summary)
                }
                insightCards
                Label("insights.disclaimer", systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("insights.disclaimer")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 104)
        }
        .mindBudgetScreenBackground()
        .accessibilityIdentifier("insights.view")
        .refreshable { await load() }
    }

    private var partialDataWarning: some View {
        Label("insights.partialDataUnavailable", systemImage: "exclamationmark.triangle")
            .font(.footnote)
            .foregroundStyle(theme.attentionText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(theme.attentionSoft, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(theme.attentionBorder, lineWidth: 1)
            }
            .accessibilityIdentifier("insights.partialDataWarning")
    }

    private func cycleNarrativeCard(_ narrative: SourcedSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(narrative.summary.title).font(.headline)
                Spacer()
                if narrative.source == .model {
                    Label("ask.answer.enhanced", systemImage: "apple.intelligence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(narrative.summary.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .budgetCard(cornerRadius: 20, contentPadding: 18)
        .accessibilityIdentifier("insights.cycleNarrative")
    }

    private func summaryCards(_ summary: InsightDashboardSummary) -> some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "insights.summary.thirtyDays",
                amount: summary.lastThirtyDaysTotal,
                amountIdentifier: "insights.summary.thirtyDays.amount",
                detail: LocalizedCatalog.format(
                    "insights.summary.records",
                    locale: locale,
                    summary.lastThirtyDaysCount
                )
            )
            summaryCard(
                title: "insights.summary.currentCycle",
                amount: summary.currentCycleTotal,
                amountIdentifier: "insights.summary.currentCycle.amount",
                detail: LocalizedCatalog.string("insights.summary.recorded", locale: locale)
            )
        }
    }

    private var savingsProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("insights.savings.title", systemImage: "target")
                .font(.headline)

            if viewModel.savingsGoalUnavailable {
                Text("insights.savings.unavailable")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let goal = viewModel.savingsGoal {
                VStack(spacing: 10) {
                    savingsAmount(
                        title: "insights.savings.target",
                        amount: goal.target,
                        identifier: "insights.savings.target"
                    )
                    savingsAmount(
                        title: "insights.savings.saved",
                        amount: goal.savedTotal,
                        identifier: "insights.savings.saved"
                    )
                    savingsAmount(
                        title: "insights.savings.remaining",
                        amount: goal.remaining,
                        identifier: "insights.savings.remaining"
                    )
                }

                ProgressView(
                    value: CGFloat(goal.completionBasisPoints),
                    total: 10_000
                )
                .tint(theme.accent)
                .accessibilityLabel("insights.savings.progress")
                .accessibilityValue(
                    LocalizedCatalog.format(
                        "insights.savings.percent",
                        locale: locale,
                        Int(goal.completionPercent)
                    )
                )

                Text(
                    LocalizedCatalog.format(
                        "insights.savings.percent",
                        locale: locale,
                        Int(goal.completionPercent)
                    )
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accent)
                .accessibilityIdentifier("insights.savings.percent")
            } else {
                Text("insights.savings.empty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .budgetCard(cornerRadius: 20, contentPadding: 18)
        .accessibilityIdentifier("insights.savings.card")
    }

    private func savingsAmount(
        title: LocalizedStringKey,
        amount: Money,
        identifier: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            MoneyText(money: amount, weight: .semibold)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier(identifier)
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryCard(
        title: LocalizedStringKey,
        amount: Money,
        amountIdentifier: String,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            MoneyText(money: amount, weight: .semibold)
                .accessibilityIdentifier(amountIdentifier)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .budgetCard(cornerRadius: 18, contentPadding: 16)
    }

    @ViewBuilder
    private func spendingCharts(_ summary: InsightDashboardSummary) -> some View {
        if !summary.categoryTotals.isEmpty {
            chartSection(title: "insights.chart.category") {
                Chart(summary.categoryTotals.prefix(6)) { item in
                    BarMark(
                        x: .value(
                            LocalizedCatalog.string(item.labelKey, locale: locale),
                            item.amount.minorUnits
                        ),
                        y: .value(
                            "insights.chart.category",
                            LocalizedCatalog.string(item.labelKey, locale: locale)
                        )
                    )
                    .foregroundStyle(theme.accent.gradient)
                }
                .frame(height: 180)
                .chartXAxis(.hidden)
            }
        }
        chartSection(title: "insights.chart.thirtyDays") {
            Chart(summary.dailyTotals) { item in
                LineMark(
                    x: .value("insights.chart.date", item.date, unit: .day),
                    y: .value("insights.chart.amount", item.amount.minorUnits)
                )
                .foregroundStyle(theme.accent)
                PointMark(
                    x: .value("insights.chart.date", item.date, unit: .day),
                    y: .value("insights.chart.amount", item.amount.minorUnits)
                )
                .foregroundStyle(theme.accent)
            }
            .frame(height: 170)
            .chartYAxis(.hidden)
        }
        if !summary.emotionTotals.isEmpty {
            chartSection(title: "insights.chart.emotion") {
                Chart(summary.emotionTotals.prefix(6)) { item in
                    BarMark(
                        x: .value(
                            LocalizedCatalog.string(item.labelKey, locale: locale),
                            item.amount.minorUnits
                        ),
                        y: .value(
                            "insights.chart.emotion",
                            LocalizedCatalog.string(item.labelKey, locale: locale)
                        )
                    )
                    .foregroundStyle(theme.attention.gradient)
                }
                .frame(height: 180)
                .chartXAxis(.hidden)
            }
        }
    }

    private func chartSection<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .budgetCard(cornerRadius: 20, contentPadding: 18)
    }

    @ViewBuilder
    private var insightCards: some View {
        if viewModel.insights.isEmpty {
            EmptyStateView(
                symbolName: "chart.xyaxis.line",
                titleKey: "insights.empty.title",
                messageKey: "insights.empty.message"
            )
            .accessibilityIdentifier("insights.empty")
        } else {
            Text("insights.cards.title")
                .font(.title3.bold())
            ForEach(viewModel.insights) { insight in
                let wording = InsightPresentationFormatter().wording(
                    for: insight,
                    locale: locale
                )
                VStack(alignment: .leading, spacing: 10) {
                    Label(wording.title, systemImage: symbol(for: insight.type))
                        .font(.headline)
                    Text(wording.body)
                        .foregroundStyle(.secondary)
                    Button("insights.card.dismiss") {
                        Task {
                            await viewModel.dismiss(
                                insight,
                                dataActor: session.dataActor,
                                at: Date()
                            )
                        }
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(theme.attentionSoft, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.attentionBorder, lineWidth: 1)
                }
            }
        }
    }

    private func symbol(for type: SpendingInsightType) -> String {
        switch type {
        case .highSinglePurchase: "banknote"
        case .categoryBudgetRisk: "chart.bar"
        case .lateNightSpending: "moon.stars"
        case .repeatedStressSpending: "heart.text.square"
        case .imageRelatedIncrease: "person.crop.circle"
        case .impulseCluster: "sparkles"
        case .wishlistCoolingOff: "timer"
        case .coolingOffSuccess: "checkmark.circle"
        case .monthlySummary: "calendar"
        case .safeToProceed: "checkmark.shield"
        }
    }

    private func load() async {
        await viewModel.load(
            dataActor: session.dataActor,
            currencyCode: settings.currencyCode,
            cycleStartDay: settings.budgetCycleStartDay,
            configuration: settings.ruleConfiguration(),
            locale: locale,
            tone: settings.reminderTone,
            enhancementEnabled: settings.enableAIEnhancement,
            now: Date(),
            calendar: calendar
        )
    }
}
