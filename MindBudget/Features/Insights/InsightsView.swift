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
    let categoryChartSegments: [InsightBreakdown]
    let emotionTotals: [InsightBreakdown]
    let dailyTotals: [InsightDailyTotal]
}

enum CategoryChartLayout: Equatable, Sendable {
    case grid(chartHeight: CGFloat)
    case stacked(chartHeight: CGFloat)

    init(dynamicTypeSize: DynamicTypeSize) {
        self = dynamicTypeSize.isAccessibilitySize
            ? .stacked(chartHeight: 180)
            : .grid(chartHeight: 220)
    }

    var chartHeight: CGFloat {
        switch self {
        case let .grid(chartHeight), let .stacked(chartHeight):
            chartHeight
        }
    }
}

struct InsightSummaryBuilder: Sendable {
    private let visibleCategoryCount = 5

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
            .sorted(by: descendingAmountThenID)
        let categoryChartSegments = try categoryChartSegments(
            from: categoryTotals,
            currencyCode: currencyCode
        )
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
            .sorted(by: descendingAmountThenID)
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
            categoryChartSegments: categoryChartSegments,
            emotionTotals: emotionTotals,
            dailyTotals: dailyTotals
        )
    }

    private func categoryChartSegments(
        from totals: [InsightBreakdown],
        currencyCode: String
    ) throws -> [InsightBreakdown] {
        // Six real categories still fit the chart's maximum visible segment count. Only
        // seven or more categories need a fifth-plus-remainder presentation.
        guard totals.count > visibleCategoryCount + 1 else { return totals }
        let leading = Array(totals.prefix(visibleCategoryCount))
        let remainingMinorUnits = try checkedSum(
            totals.dropFirst(visibleCategoryCount).map(\.amount.minorUnits)
        )
        return leading + [
            InsightBreakdown(
                id: "__remaining_categories__",
                labelKey: "insights.chart.category.remaining",
                amount: Money(
                    minorUnits: remainingMinorUnits,
                    currencyCode: currencyCode
                )
            )
        ]
    }

    private func descendingAmountThenID(
        _ lhs: InsightBreakdown,
        _ rhs: InsightBreakdown
    ) -> Bool {
        if lhs.amount.minorUnits == rhs.amount.minorUnits {
            return lhs.id < rhs.id
        }
        return lhs.amount.minorUnits > rhs.amount.minorUnits
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
        premiumEntryAccess: ExistingPremiumEntryAccess,
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
                enhancementEnabled: enhancementEnabled,
                premiumEntryAccess: premiumEntryAccess
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.existingPremiumEntryAccess) private var premiumEntryAccess
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
                    groupHeader("insights.group.currentCycle")
                        .accessibilityIdentifier("insights.group.currentCycle")
                    summaryCards(summary)
                    if let narrative = viewModel.cycleNarrative {
                        cycleNarrativeCard(narrative)
                    }

                    groupHeader("insights.group.longTerm")
                        .accessibilityIdentifier("insights.group.longTerm")
                    savingsProgressCard

                    if !summary.categoryChartSegments.isEmpty {
                        groupHeader("insights.group.composition")
                            .accessibilityIdentifier("insights.group.composition")
                    }
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

    /// Names a group of modules so this screen reads as a small number of themes rather than an
    /// unbroken column of equally weighted cards. A new module joins an existing group instead of
    /// being appended anonymously to the bottom. The group names the theme; each card keeps its own
    /// title for the specific module it shows.
    private func groupHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.title3.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
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
        if !summary.categoryChartSegments.isEmpty {
            chartSection(title: "insights.chart.category") {
                Chart(Array(summary.categoryChartSegments.enumerated()), id: \.element.id) { entry in
                    let index = entry.offset
                    let item = entry.element
                    let label = LocalizedCatalog.string(item.labelKey, locale: locale)
                    SectorMark(
                        angle: .value("insights.chart.amount", item.amount.minorUnits),
                        innerRadius: .ratio(0.52),
                        angularInset: 1.5
                    )
                    .cornerRadius(3)
                    .foregroundStyle(categoryChartColor(at: index))
                    .accessibilityLabel(label)
                    .accessibilityValue(
                        CurrencyFormatterService().string(from: item.amount, locale: locale)
                    )
                }
                .frame(height: CategoryChartLayout(dynamicTypeSize: dynamicTypeSize).chartHeight)
                .chartLegend(.hidden)
                .accessibilityLabel("insights.chart.category")
                .accessibilityIdentifier("insights.chart.category.pie")

                categoryChartLegend(summary.categoryChartSegments)
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

    @ViewBuilder
    private func categoryChartLegend(_ segments: [InsightBreakdown]) -> some View {
        let layout = CategoryChartLayout(dynamicTypeSize: dynamicTypeSize)
        let columns: [GridItem] = switch layout {
        case .grid:
            [
                GridItem(.flexible(minimum: 0), alignment: .leading),
                GridItem(.flexible(minimum: 0), alignment: .leading),
            ]
        case .stacked:
            [GridItem(.flexible(minimum: 0), alignment: .leading)]
        }

        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(Array(segments.enumerated()), id: \.element.id) { entry in
                let index = entry.offset
                let item = entry.element
                let label = LocalizedCatalog.string(item.labelKey, locale: locale)
                let amount = CurrencyFormatterService().string(from: item.amount, locale: locale)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Circle()
                        .fill(categoryChartColor(at: index))
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                        Text(amount)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityValue(amount)
                .accessibilityIdentifier("insights.chart.category.legend.\(item.id)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("insights.chart.category")
        .accessibilityIdentifier("insights.chart.category.legend")
    }

    private func categoryChartColor(at index: Int) -> Color {
        let colors = theme.categoricalChart
        return colors[index % colors.count]
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
            groupHeader("insights.cards.title")
                .accessibilityIdentifier("insights.group.patterns")
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
            premiumEntryAccess: premiumEntryAccess,
            now: Date(),
            calendar: calendar
        )
    }
}
