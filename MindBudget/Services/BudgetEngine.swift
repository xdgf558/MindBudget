import Foundation

enum BudgetEngineError: Error, Equatable, Sendable {
    case invalidCycle
    case referenceDateOutsideCycle
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

struct ConfiguredBudgetSnapshot: Sendable, Equatable {
    let cycle: DateInterval
    let currencyCode: String

    let totalBudget: Money
    let fixedForecast: Money
    let savingGoal: Money
    let freeBudget: Money

    let spentTotal: Money
    let fixedSpent: Money
    let discretionarySpent: Money
    let savedSoFar: Money
    let spentByCategory: [ExpenseCategory: Money]

    let remainingTotal: Money
    let remainingFree: Money
    let pendingFixed: Money
    let pendingSaving: Money
    let availableRightNow: Money
    let safeDailySpend: Money
    let daysRemaining: Int
}

enum BudgetSnapshot: Sendable, Equatable {
    case unconfigured(cycle: DateInterval, currencyCode: String)
    case configured(ConfiguredBudgetSnapshot)

    var cycle: DateInterval {
        switch self {
        case let .unconfigured(cycle, _): cycle
        case let .configured(snapshot): snapshot.cycle
        }
    }

    var currencyCode: String {
        switch self {
        case let .unconfigured(_, currencyCode): currencyCode
        case let .configured(snapshot): snapshot.currencyCode
        }
    }
}

struct BudgetImpact: Sendable, Equatable {
    let newAmount: Money
    let bucket: BudgetBucket
    let remainingTotalAfter: Money
    let remainingFreeAfter: Money
    let willExceedTotalBudget: Bool
    let willExceedFreeBudget: Bool
    let impactRatioOfFreeBudget: Decimal?
    let daysOfBudgetConsumed: Decimal?
    let categoryRisk: CategoryBudgetRisk?
}

/// A presentation-ready, deterministic summary for the Today screen. The view never
/// derives money or calendar pace on its own.
struct BudgetPaceSummary: Sendable, Equatable {
    let spentToday: Money
    let leftToSpendToday: Money
    let expectedSpentByToday: Money
    let paceDifference: Money
    let isAheadOfPace: Bool
    let dayNumber: Int
    let totalDays: Int
    let elapsedRatio: Decimal
    let spentRatio: Decimal
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
        snapshot: ConfiguredBudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary]
    ) throws -> BudgetImpact
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
        guard cycle.start <= now, now < cycle.end else {
            throw BudgetEngineError.referenceDateOutsideCycle
        }
        guard Money.isSupported(currencyCode) else {
            throw BudgetEngineError.invalidPlan
        }
        guard let plan else {
            return .unconfigured(cycle: cycle, currencyCode: currencyCode)
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
        return .configured(
            ConfiguredBudgetSnapshot(
                cycle: cycle,
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
        )
    }

    func impact(
        of amount: Money,
        category: ExpenseCategory,
        bucket: BudgetBucket,
        snapshot: ConfiguredBudgetSnapshot,
        categoryBudgets: [CategoryBudgetSummary]
    ) throws -> BudgetImpact {
        guard amount.minorUnits > 0 else {
            throw BudgetEngineError.invalidPurchaseAmount
        }
        try requireCurrency(amount.currencyCode, matches: snapshot.currencyCode)

        let remainingTotalAfter = try checkedSubtract(
            snapshot.remainingTotal.minorUnits,
            amount.minorUnits
        )
        let freeReduction = bucket == .discretionary ? amount.minorUnits : 0
        let remainingFreeAfter = try checkedSubtract(
            snapshot.remainingFree.minorUnits,
            freeReduction
        )
        let isDiscretionary = bucket == .discretionary
        let impactRatio = isDiscretionary && snapshot.freeBudget.minorUnits > 0
            ? decimalRatio(amount.minorUnits, snapshot.freeBudget.minorUnits)
            : nil
        let daysConsumed = isDiscretionary && snapshot.safeDailySpend.minorUnits > 0
            ? decimalRatio(amount.minorUnits, snapshot.safeDailySpend.minorUnits)
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

    func pace(
        snapshot: ConfiguredBudgetSnapshot,
        expenses: [ExpenseSummary],
        now: Date,
        calendar: Calendar
    ) throws -> BudgetPaceSummary {
        guard snapshot.cycle.start <= now, now < snapshot.cycle.end else {
            throw BudgetEngineError.referenceDateOutsideCycle
        }

        let startOfToday = calendar.startOfDay(for: now)
        guard let today = calendar.dateInterval(of: .day, for: now) else {
            throw BudgetEngineError.invalidCycle
        }
        let totalDays = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: snapshot.cycle.start),
            to: snapshot.cycle.end
        ).day ?? 0
        let elapsedDays = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: snapshot.cycle.start),
            to: startOfToday
        ).day ?? -1
        guard totalDays > 0, elapsedDays >= 0, elapsedDays < totalDays else {
            throw BudgetEngineError.invalidCycle
        }

        var spentToday: Int64 = 0
        for expense in expenses where today.contains(expense.spentAt) && expense.bucket == .discretionary {
            try requireCurrency(expense.amount.currencyCode, matches: snapshot.currencyCode)
            guard expense.amount.minorUnits >= 0 else {
                throw BudgetEngineError.invalidPlan
            }
            spentToday = try checkedAdd(spentToday, expense.amount.minorUnits)
        }

        // Reconstruct the amount available at the start of today so today's entries do
        // not get counted twice when the daily allowance is presented.
        let startOfDayRemaining = try checkedAdd(snapshot.remainingFree.minorUnits, spentToday)
        let dailyAllowance = max(0, startOfDayRemaining) / Int64(snapshot.daysRemaining)
        let leftToday = try checkedSubtract(dailyAllowance, spentToday)
        let dayNumber = elapsedDays + 1
        let expectedSpent = try proratedMinorUnits(
            snapshot.freeBudget.minorUnits,
            numerator: dayNumber,
            denominator: totalDays
        )
        let signedDifference = try checkedSubtract(
            snapshot.discretionarySpent.minorUnits,
            expectedSpent
        )
        let isAhead = signedDifference > 0
        let difference = isAhead ? signedDifference : try checkedSubtract(0, signedDifference)
        let spentRatio = snapshot.freeBudget.minorUnits > 0
            ? decimalRatio(max(0, snapshot.discretionarySpent.minorUnits), snapshot.freeBudget.minorUnits)
            : .zero

        return BudgetPaceSummary(
            spentToday: money(spentToday, snapshot.currencyCode),
            leftToSpendToday: money(leftToday, snapshot.currencyCode),
            expectedSpentByToday: money(expectedSpent, snapshot.currencyCode),
            paceDifference: money(difference, snapshot.currencyCode),
            isAheadOfPace: isAhead,
            dayNumber: dayNumber,
            totalDays: totalDays,
            elapsedRatio: Decimal(dayNumber) / Decimal(totalDays),
            spentRatio: spentRatio
        )
    }

    private func categoryRisk(
        for category: ExpenseCategory,
        amount: Money,
        snapshot: ConfiguredBudgetSnapshot,
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

    private func proratedMinorUnits(
        _ value: Int64,
        numerator: Int,
        denominator: Int
    ) throws -> Int64 {
        guard value >= 0, numerator >= 0, denominator > 0, numerator <= denominator else {
            throw BudgetEngineError.invalidPlan
        }
        let denominator64 = Int64(denominator)
        let numerator64 = Int64(numerator)
        let whole = try checkedMultiply(value / denominator64, numerator64)
        let remainder = try checkedMultiply(value % denominator64, numerator64) / denominator64
        return try checkedAdd(whole, remainder)
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

    private func checkedMultiply(_ lhs: Int64, _ rhs: Int64) throws -> Int64 {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
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
