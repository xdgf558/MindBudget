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
    let lastSevenDaysTotal: Money
    let lastSevenDaysCount: Int
    let currentCycleTotal: Money
    let categoryTotals: [InsightBreakdown]
    let emotionTotals: [InsightBreakdown]
    let dailyTotals: [InsightDailyTotal]
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var summary: InsightDashboardSummary?
    @Published private(set) var insights: [SpendingInsightSummary] = []
    @Published private(set) var cycleNarrative: SourcedSummary?
    @Published private(set) var isLoading = true
    @Published private(set) var failed = false

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
        isLoading = true
        do {
            async let expenseRequest = dataActor.fetchExpenseSummaries()
            async let planRequest = dataActor.fetchBudgetPlanSummaries()
            async let coolingRequest = dataActor.fetchCoolingOffPlanSummaries()
            let expenses = try await expenseRequest
            let plans = try await planRequest
            let coolingPlans = try await coolingRequest
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
            let dashboardSummary = try makeSummary(
                expenses: expenses,
                cycle: snapshot.cycle,
                currencyCode: snapshot.currencyCode,
                now: now,
                calendar: calendar
            )
            summary = dashboardSummary
            cycleNarrative = await CycleSummaryService().generate(
                snapshot: snapshot,
                expenses: expenses,
                coolingOffPlans: coolingPlans,
                locale: locale,
                calendar: calendar,
                tone: tone,
                enhancementEnabled: enhancementEnabled
            )
            insights = storedInsights.filter {
                $0.periodStart == snapshot.cycle.start
                    && $0.periodEnd == snapshot.cycle.end
            }
            failed = false
        } catch {
            failed = true
        }
        isLoading = false
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

    private func makeSummary(
        expenses: [ExpenseSummary],
        cycle: DateInterval,
        currencyCode: String,
        now: Date,
        calendar: Calendar
    ) throws -> InsightDashboardSummary {
        let today = calendar.startOfDay(for: now)
        let firstDay = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        let sevenDayExpenses = expenses.filter {
            firstDay <= $0.spentAt && $0.spentAt < tomorrow
                && $0.amount.currencyCode == currencyCode
        }
        let cycleExpenses = expenses.filter {
            cycle.start <= $0.spentAt && $0.spentAt < cycle.end
                && $0.amount.currencyCode == currencyCode
        }
        let categoryTotals = try Dictionary(grouping: cycleExpenses, by: \.category)
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
        let tagged = cycleExpenses.compactMap { expense in
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
        let groupedDays = Dictionary(grouping: sevenDayExpenses) {
            calendar.startOfDay(for: $0.spentAt)
        }
        let dailyTotals = try (0..<7).compactMap { offset -> InsightDailyTotal? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else {
                return nil
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
            lastSevenDaysTotal: Money(
                minorUnits: try checkedSum(sevenDayExpenses.map(\.amount.minorUnits)),
                currencyCode: currencyCode
            ),
            lastSevenDaysCount: sevenDayExpenses.count,
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

struct InsightsView: View {
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
            .task(id: session.revision) { await load() }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if let summary = viewModel.summary {
                    summaryCards(summary)
                    if let narrative = viewModel.cycleNarrative {
                        cycleNarrativeCard(narrative)
                    }
                    spendingCharts(summary)
                }
                insightCards
                Label("insights.disclaimer", systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("insights.disclaimer")
            }
            .padding()
        }
        .accessibilityIdentifier("insights.view")
        .refreshable { await load() }
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
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("insights.cycleNarrative")
    }

    private func summaryCards(_ summary: InsightDashboardSummary) -> some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "insights.summary.sevenDays",
                amount: summary.lastSevenDaysTotal,
                detail: LocalizedCatalog.format(
                    "insights.summary.records",
                    locale: locale,
                    summary.lastSevenDaysCount
                )
            )
            summaryCard(
                title: "insights.summary.currentCycle",
                amount: summary.currentCycleTotal,
                detail: LocalizedCatalog.string("insights.summary.recorded", locale: locale)
            )
        }
    }

    private func summaryCard(
        title: LocalizedStringKey,
        amount: Money,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            MoneyText(money: amount, weight: .semibold)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: 180)
                .chartXAxis(.hidden)
            }
        }
        chartSection(title: "insights.chart.sevenDays") {
            Chart(summary.dailyTotals) { item in
                LineMark(
                    x: .value("insights.chart.date", item.date, unit: .day),
                    y: .value("insights.chart.amount", item.amount.minorUnits)
                )
                .foregroundStyle(.teal)
                PointMark(
                    x: .value("insights.chart.date", item.date, unit: .day),
                    y: .value("insights.chart.amount", item.amount.minorUnits)
                )
                .foregroundStyle(.teal)
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
                    .foregroundStyle(.indigo.gradient)
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
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
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
                .padding()
                .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
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
