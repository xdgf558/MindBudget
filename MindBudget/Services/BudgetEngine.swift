import Foundation

enum BudgetEngineError: Error, Equatable, Sendable {
    case invalidCycle
    case invalidPlan
    case planCycleMismatch
    case invalidPurchaseAmount
    case currencyMismatch(expected: String, actual: String)
    case arithmeticOverflow
}

struct CategoryBudgetRisk: Hashable, Sendable {
    enum Level: String, CaseIterable, Hashable, Sendable {
        case ok
        case approaching
        case atLimit
        case over
    }

    let category: ExpenseCategory
    let limit: Money
    let spent: Money
    let projectedAfterPurchase: Money
    let usedRatio: Decimal
    let level: Level
}

struct BudgetSnapshot: Sendable, Equatable {
    let isConfigured: Bool
    let cycleStart: Date
    let cycleEnd: Date
    let currencyCode: String

    let totalBudget: Money?
    let fixedForecast: Money?
    let savingGoal: Money?
    let freeBudget: Money?

    let spentTotal: Money?
    let fixedSpent: Money?
    let discretionarySpent: Money?
    let savedSoFar: Money?
    let spentByCategory: [ExpenseCategory: Money]

    let remainingTotal: Money?
    let remainingFree: Money?
    let pendingFixed: Money?
    let pendingSaving: Money?
    let availableRightNow: Money?
    let safeDailySpend: Money?
    let daysRemaining: Int?

    static func unconfigured(currencyCode: String, cycle: DateInterval) -> BudgetSnapshot {
        BudgetSnapshot(
            isConfigured: false,
            cycleStart: cycle.start,
            cycleEnd: cycle.end,
            currencyCode: currencyCode,
            totalBudget: nil,
            fixedForecast: nil,
            savingGoal: nil,
            freeBudget: nil,
            spentTotal: nil,
            fixedSpent: nil,
            discretionarySpent: nil,
            savedSoFar: nil,
            spentByCategory: [:],
            remainingTotal: nil,
            remainingFree: nil,
            pendingFixed: nil,
            pendingSaving: nil,
            availableRightNow: nil,
            safeDailySpend: nil,
            daysRemaining: nil
        )
    }
}

struct BudgetImpact: Sendable, Equatable {
    let newAmount: Money
    let bucket: BudgetBucket
    let remainingTotalAfter: Money
    let remainingFreeAfter: Money
    let willExceedTotalBudget: Bool
    let willExceedFreeBudget: Bool
    let impactRatioOfFreeBudget: Decimal
    let daysOfBudgetConsumed: Decimal?
    let categoryRisk: CategoryBudgetRisk?
}

protocol BudgetCalculating: Sendable {
    func snapshot(
        cycle: DateInterval,
        currencyCode: String,
        expenses: [ExpenseSummary],
        plan: BudgetPlanSummary?,
        now: Date,
        calendar: Calendar
    ) throws -> BudgetSnapshot

    func impact(
        of amount: Money,
        category: ExpenseCategory,
        bucket: BudgetBucket,
        snapshot: BudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary]
    ) throws -> BudgetImpact?
}

struct BudgetEngine: BudgetCalculating, Sendable {
    func snapshot(
        cycle: DateInterval,
        currencyCode: String,
        expenses: [ExpenseSummary],
        plan: BudgetPlanSummary?,
        now: Date,
        calendar: Calendar
    ) throws -> BudgetSnapshot {
        guard cycle.start < cycle.end else {
            throw BudgetEngineError.invalidCycle
        }
        guard Money.isSupported(currencyCode) else {
            throw BudgetEngineError.invalidPlan
        }
        guard let plan else {
            return .unconfigured(currencyCode: currencyCode, cycle: cycle)
        }
        try requireCurrency(plan.currencyCode, matches: currencyCode)
        guard plan.cycleStart == cycle.start, plan.cycleEnd == cycle.end else {
            throw BudgetEngineError.planCycleMismatch
        }
        guard Money.isSupported(plan.currencyCode),
              plan.totalBudgetMinorUnits >= 0,
              plan.fixedExpensesMinorUnits >= 0,
              plan.savingGoalMinorUnits >= 0 else {
            throw BudgetEngineError.invalidPlan
        }

        var spentTotal: Int64 = 0
        var fixedSpent: Int64 = 0
        var discretionarySpent: Int64 = 0
        var savedSoFar: Int64 = 0
        var spentByCategory: [ExpenseCategory: Int64] = [:]

        for expense in expenses where cycle.start <= expense.spentAt && expense.spentAt < cycle.end {
            try requireCurrency(expense.amount.currencyCode, matches: plan.currencyCode)
            guard expense.amount.minorUnits >= 0 else {
                throw BudgetEngineError.invalidPlan
            }
            spentTotal = try checkedAdd(spentTotal, expense.amount.minorUnits)
            spentByCategory[expense.category] = try checkedAdd(
                spentByCategory[expense.category, default: 0],
                expense.amount.minorUnits
            )
            switch expense.bucket {
            case .fixed:
                fixedSpent = try checkedAdd(fixedSpent, expense.amount.minorUnits)
            case .discretionary:
                discretionarySpent = try checkedAdd(discretionarySpent, expense.amount.minorUnits)
            case .savings:
                savedSoFar = try checkedAdd(savedSoFar, expense.amount.minorUnits)
            }
        }

        let totalBudget = plan.totalBudgetMinorUnits
        let fixedForecast = plan.fixedExpensesMinorUnits
        let savingGoal = plan.savingGoalMinorUnits
        let afterFixed = totalBudget > fixedForecast ? totalBudget - fixedForecast : 0
        let freeBudget = afterFixed > savingGoal ? afterFixed - savingGoal : 0
        let remainingFree = try checkedSubtract(freeBudget, discretionarySpent)
        let pendingFixed = fixedForecast > fixedSpent ? fixedForecast - fixedSpent : 0
        let pendingSaving = savingGoal > savedSoFar ? savingGoal - savedSoFar : 0
        let remainingTotal = try checkedSubtract(totalBudget, spentTotal)
        let availableAfterFixed = try checkedSubtract(remainingTotal, pendingFixed)
        let availableRightNow = try checkedSubtract(availableAfterFixed, pendingSaving)
        let startOfToday = calendar.startOfDay(for: now)
        let calendarDays = calendar.dateComponents(
            [.day],
            from: startOfToday,
            to: cycle.end
        ).day ?? 1
        let daysRemaining = max(1, calendarDays)
        let safeDailySpend = max(0, remainingFree) / Int64(daysRemaining)
        return BudgetSnapshot(
            isConfigured: true,
            cycleStart: cycle.start,
            cycleEnd: cycle.end,
            currencyCode: currencyCode,
            totalBudget: money(totalBudget, currencyCode),
            fixedForecast: money(fixedForecast, currencyCode),
            savingGoal: money(savingGoal, currencyCode),
            freeBudget: money(freeBudget, currencyCode),
            spentTotal: money(spentTotal, currencyCode),
            fixedSpent: money(fixedSpent, currencyCode),
            discretionarySpent: money(discretionarySpent, currencyCode),
            savedSoFar: money(savedSoFar, currencyCode),
            spentByCategory: spentByCategory.mapValues { money($0, currencyCode) },
            remainingTotal: money(remainingTotal, currencyCode),
            remainingFree: money(remainingFree, currencyCode),
            pendingFixed: money(pendingFixed, currencyCode),
            pendingSaving: money(pendingSaving, currencyCode),
            availableRightNow: money(availableRightNow, currencyCode),
            safeDailySpend: money(safeDailySpend, currencyCode),
            daysRemaining: daysRemaining
        )
    }

    func impact(
        of amount: Money,
        category: ExpenseCategory,
        bucket: BudgetBucket,
        snapshot: BudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary]
    ) throws -> BudgetImpact? {
        guard snapshot.isConfigured else { return nil }
        guard amount.minorUnits > 0 else {
            throw BudgetEngineError.invalidPurchaseAmount
        }
        try requireCurrency(amount.currencyCode, matches: snapshot.currencyCode)
        guard let remainingTotal = snapshot.remainingTotal,
              let remainingFree = snapshot.remainingFree,
              let freeBudget = snapshot.freeBudget,
              let safeDailySpend = snapshot.safeDailySpend else {
            throw BudgetEngineError.invalidPlan
        }

        let remainingTotalAfter = try checkedSubtract(
            remainingTotal.minorUnits,
            amount.minorUnits
        )
        let freeReduction = bucket == .discretionary ? amount.minorUnits : 0
        let remainingFreeAfter = try checkedSubtract(
            remainingFree.minorUnits,
            freeReduction
        )
        let impactRatio = freeBudget.minorUnits > 0
            ? decimalRatio(amount.minorUnits, freeBudget.minorUnits)
            : Decimal(1)
        let daysConsumed = safeDailySpend.minorUnits > 0
            ? decimalRatio(amount.minorUnits, safeDailySpend.minorUnits)
            : nil
        let categoryRisk = try categoryRisk(
            for: category,
            amount: amount,
            snapshot: snapshot,
            categoryBudgets: categoryBudgets
        )

        return BudgetImpact(
            newAmount: amount,
            bucket: bucket,
            remainingTotalAfter: money(remainingTotalAfter, snapshot.currencyCode),
            remainingFreeAfter: money(remainingFreeAfter, snapshot.currencyCode),
            willExceedTotalBudget: remainingTotalAfter < 0,
            willExceedFreeBudget: remainingFreeAfter < 0,
            impactRatioOfFreeBudget: impactRatio,
            daysOfBudgetConsumed: daysConsumed,
            categoryRisk: categoryRisk
        )
    }

    private func categoryRisk(
        for category: ExpenseCategory,
        amount: Money,
        snapshot: BudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary]
    ) throws -> CategoryBudgetRisk? {
        guard let budget = categoryBudgets.first(where: { $0.category == category }) else {
            return nil
        }
        guard budget.limitMinorUnits >= 0,
              (1...10_000).contains(budget.warningThresholdBasisPoints) else {
            throw BudgetEngineError.invalidPlan
        }

        let spent = snapshot.spentByCategory[category]
            ?? money(0, snapshot.currencyCode)
        let projected = try checkedAdd(spent.minorUnits, amount.minorUnits)
        let usedRatio: Decimal
        if budget.limitMinorUnits > 0 {
            usedRatio = decimalRatio(projected, budget.limitMinorUnits)
        } else {
            usedRatio = projected > 0 ? Decimal(1) : Decimal.zero
        }

        let level: CategoryBudgetRisk.Level
        if projected > budget.limitMinorUnits {
            level = .over
        } else if projected == budget.limitMinorUnits {
            level = .atLimit
        } else {
            let warningRatio = Decimal(budget.warningThresholdBasisPoints) / Decimal(10_000)
            level = usedRatio >= warningRatio ? .approaching : .ok
        }

        return CategoryBudgetRisk(
            category: category,
            limit: money(budget.limitMinorUnits, snapshot.currencyCode),
            spent: spent,
            projectedAfterPurchase: money(projected, snapshot.currencyCode),
            usedRatio: usedRatio,
            level: level
        )
    }

    private func decimalRatio(_ numerator: Int64, _ denominator: Int64) -> Decimal {
        Decimal(numerator) / Decimal(denominator)
    }

    private func checkedAdd(_ lhs: Int64, _ rhs: Int64) throws -> Int64 {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        guard !overflow else { throw BudgetEngineError.arithmeticOverflow }
        return result
    }

    private func checkedSubtract(_ lhs: Int64, _ rhs: Int64) throws -> Int64 {
        let (result, overflow) = lhs.subtractingReportingOverflow(rhs)
        guard !overflow else { throw BudgetEngineError.arithmeticOverflow }
        return result
    }

    private func requireCurrency(_ actual: String, matches expected: String) throws {
        guard actual == expected else {
            throw BudgetEngineError.currencyMismatch(expected: expected, actual: actual)
        }
    }

    private func money(_ minorUnits: Int64, _ currencyCode: String) -> Money {
        Money(minorUnits: minorUnits, currencyCode: currencyCode)
    }
}
