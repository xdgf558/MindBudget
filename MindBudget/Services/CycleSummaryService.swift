import Foundation

struct CycleSummaryService: Sendable {
    private let model: any AIAdviceGenerating
    private let runtimeAvailability: @Sendable (Locale) async -> AIAvailability

    init(
        model: any AIAdviceGenerating = FoundationModelsAdviceGenerator(),
        runtimeAvailability: @escaping @Sendable (Locale) async -> AIAvailability = { locale in
            await FoundationModelsAdviceGenerator.runtimeAvailability(locale: locale)
        }
    ) {
        self.model = model
        self.runtimeAvailability = runtimeAvailability
    }

    func generate(
        snapshot: BudgetSnapshot,
        expenses: [ExpenseSummary],
        coolingOffPlans: [CoolingOffPlanSummary],
        locale: Locale,
        calendar: Calendar,
        tone: ReminderTone,
        enhancementEnabled: Bool
    ) async -> SourcedSummary {
        let cycleExpenses = expenses.filter {
            snapshot.cycle.start <= $0.spentAt && $0.spentAt < snapshot.cycle.end
        }
        let topCategories = topCategories(in: cycleExpenses)
        let leadingCategory = topCategories.first
        let budgetUsage = budgetUsage(snapshot)
        let categoryName = leadingCategory.map {
            LocalizedCatalog.string($0.localizedNameKey, locale: locale)
        } ?? LocalizedCatalog.string("insights.summary.noCategory", locale: locale)
        let templateBody = templateBody(
            budgetUsage: budgetUsage,
            categoryName: categoryName,
            locale: locale
        )
        let fallback = GeneratedSummary(
            title: LocalizedCatalog.string("insights.summary.narrative.title", locale: locale),
            body: templateBody,
            actionIdentifiers: [
                SuggestedAction.reviewRecentSpending.rawValue,
                SuggestedAction.adjustBudget.rawValue
            ]
        )
        let emotionCounts = Dictionary(grouping: cycleExpenses.compactMap(\.emotionTag)) { $0 }
            .mapValues(\.count)
        let currentOutcomes: [CoolingOffOutcome] = coolingOffPlans.compactMap { plan in
            guard let outcome = plan.outcome,
                  let recordedAt = plan.outcomeRecordedAt,
                  snapshot.cycle.start <= recordedAt,
                  recordedAt < snapshot.cycle.end else { return nil }
            return outcome
        }
        let outcomeCounts = Dictionary(grouping: currentOutcomes, by: { $0 }).mapValues(\.count)
        let input = SummaryAggregateInput(
            localeIdentifier: locale.identifier,
            cycleLabel: cycleLabel(for: snapshot.cycle.start, calendar: calendar),
            topCategories: topCategories,
            categoryChangeDirections: categoryChangeDirections(
                expenses: expenses,
                cycle: snapshot.cycle,
                calendar: calendar
            ),
            budgetUsage: budgetUsage,
            emotionCounts: emotionCounts,
            coolingOffSkippedCount: outcomeCounts[.skipped, default: 0],
            coolingOffPurchasedCount: outcomeCounts[.purchased, default: 0],
            tone: tone
        )
        let context = PrivacyRedactor().redactSummary(input)
        return await CompositeAdviceGenerator(
            model: model,
            capability: AIEnhancementCapability(
                userEnabled: enhancementEnabled,
                targetLocale: locale,
                runtimeAvailability: runtimeAvailability
            )
        ).cycleSummary(fallback: fallback, context: context)
    }

    private func topCategories(in expenses: [ExpenseSummary]) -> [ExpenseCategory] {
        var totals: [ExpenseCategory: Int64] = [:]
        for expense in expenses {
            let (sum, overflow) = totals[expense.category, default: 0]
                .addingReportingOverflow(expense.amount.minorUnits)
            guard !overflow else { return [] }
            totals[expense.category] = sum
        }
        return totals.sorted {
            if $0.value == $1.value { return $0.key.rawValue < $1.key.rawValue }
            return $0.value > $1.value
        }.prefix(3).map(\.key)
    }

    private func categoryChangeDirections(
        expenses: [ExpenseSummary],
        cycle: DateInterval,
        calendar: Calendar
    ) -> [ExpenseCategory: String] {
        guard let previousStart = calendar.date(byAdding: .month, value: -1, to: cycle.start) else {
            return [:]
        }
        var current: [ExpenseCategory: Int64] = [:]
        var previous: [ExpenseCategory: Int64] = [:]
        for expense in expenses {
            if cycle.start <= expense.spentAt && expense.spentAt < cycle.end {
                let (sum, overflow) = current[expense.category, default: 0]
                    .addingReportingOverflow(expense.amount.minorUnits)
                guard !overflow else { return [:] }
                current[expense.category] = sum
            } else if previousStart <= expense.spentAt && expense.spentAt < cycle.start {
                let (sum, overflow) = previous[expense.category, default: 0]
                    .addingReportingOverflow(expense.amount.minorUnits)
                guard !overflow else { return [:] }
                previous[expense.category] = sum
            }
        }
        return Dictionary(uniqueKeysWithValues: ExpenseCategory.allCases.compactMap { category in
            let currentValue = current[category, default: 0]
            let previousValue = previous[category, default: 0]
            guard currentValue > 0 || previousValue > 0 else { return nil }
            let direction = currentValue == previousValue
                ? "flat"
                : (currentValue > previousValue ? "up" : "down")
            return (category, direction)
        })
    }

    private func cycleLabel(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else {
            return "currentCycle"
        }
        return String(format: "%04d-%02d", year, month)
    }

    private func budgetUsage(_ snapshot: BudgetSnapshot) -> SummaryBudgetUsage {
        guard case let .configured(configured) = snapshot,
              configured.totalBudget.minorUnits > 0 else { return .unavailable }
        guard configured.spentTotal.minorUnits > 0 else { return .percent(0) }
        let ratio = Decimal(configured.spentTotal.minorUnits)
            * Decimal(100)
            / Decimal(configured.totalBudget.minorUnits)
        let wholePercent = max(0, NSDecimalNumber(decimal: ratio).intValue)
        return wholePercent == 0 ? .lessThanOnePercent : .percent(wholePercent)
    }

    private func templateBody(
        budgetUsage: SummaryBudgetUsage,
        categoryName: String,
        locale: Locale
    ) -> String {
        switch budgetUsage {
        case .unavailable:
            LocalizedCatalog.format(
                "insights.summary.narrative.body.unavailable",
                locale: locale,
                categoryName
            )
        case .lessThanOnePercent:
            LocalizedCatalog.format(
                "insights.summary.narrative.body.lessThanOnePercent",
                locale: locale,
                categoryName
            )
        case let .percent(value):
            LocalizedCatalog.format(
                "insights.summary.narrative.body",
                locale: locale,
                value,
                categoryName
            )
        }
    }
}
