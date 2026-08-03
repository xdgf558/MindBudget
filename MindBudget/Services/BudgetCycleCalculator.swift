import Foundation

enum BudgetCycleError: Error, Equatable, Sendable {
    case invalidStartDay(Int)
    case invalidInterval
    case dateCalculationFailed
    case invalidTimeZone(String)
    case overlappingPlans
}

struct BudgetCycleCalculator: Sendable {
    func interval(
        containing date: Date,
        startDay: Int,
        calendar: Calendar
    ) throws -> DateInterval {
        try validate(startDay: startDay)
        let monthAnchor = try startOfMonth(containing: date, calendar: calendar)
        let boundaryThisMonth = try boundary(
            inMonthContaining: monthAnchor,
            startDay: startDay,
            calendar: calendar
        )

        if date < boundaryThisMonth {
            guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: monthAnchor) else {
                throw BudgetCycleError.dateCalculationFailed
            }
            let start = try boundary(
                inMonthContaining: previousMonth,
                startDay: startDay,
                calendar: calendar
            )
            return try makeInterval(start: start, end: boundaryThisMonth)
        }

        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthAnchor) else {
            throw BudgetCycleError.dateCalculationFailed
        }
        let end = try boundary(
            inMonthContaining: nextMonth,
            startDay: startDay,
            calendar: calendar
        )
        return try makeInterval(start: boundaryThisMonth, end: end)
    }

    func nextInterval(
        after existing: DateInterval,
        startDay: Int,
        calendar: Calendar
    ) throws -> DateInterval {
        guard existing.start < existing.end else {
            throw BudgetCycleError.invalidInterval
        }
        let canonical = try interval(
            containing: existing.end,
            startDay: startDay,
            calendar: calendar
        )
        guard canonical.end > existing.end else {
            throw BudgetCycleError.dateCalculationFailed
        }
        return try makeInterval(start: existing.end, end: canonical.end)
    }

    func validateNonOverlapping(_ plans: [BudgetPlanSummary]) throws {
        let sorted = plans.sorted { lhs, rhs in
            lhs.cycleStart == rhs.cycleStart
                ? lhs.cycleEnd < rhs.cycleEnd
                : lhs.cycleStart < rhs.cycleStart
        }
        for plan in sorted where plan.cycleStart >= plan.cycleEnd {
            throw BudgetCycleError.invalidInterval
        }
        for (earlier, later) in zip(sorted, sorted.dropFirst())
        where later.cycleStart < earlier.cycleEnd {
            throw BudgetCycleError.overlappingPlans
        }
    }

    func recordedLocalHour(
        at date: Date,
        timeZoneIdentifier: String,
        calendar: Calendar
    ) throws -> Int {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            throw BudgetCycleError.invalidTimeZone(timeZoneIdentifier)
        }
        var recordedCalendar = calendar
        recordedCalendar.timeZone = timeZone
        return recordedCalendar.component(.hour, from: date)
    }

    private func validate(startDay: Int) throws {
        guard (1...31).contains(startDay) else {
            throw BudgetCycleError.invalidStartDay(startDay)
        }
    }

    private func startOfMonth(containing date: Date, calendar: Calendar) throws -> Date {
        var components = calendar.dateComponents([.era, .year, .month], from: date)
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.day = 1
        guard let firstDay = calendar.date(from: components) else {
            throw BudgetCycleError.dateCalculationFailed
        }
        return calendar.startOfDay(for: firstDay)
    }

    private func boundary(
        inMonthContaining month: Date,
        startDay: Int,
        calendar: Calendar
    ) throws -> Date {
        let monthStart = try startOfMonth(containing: month, calendar: calendar)
        guard let days = calendar.range(of: .day, in: .month, for: monthStart) else {
            throw BudgetCycleError.dateCalculationFailed
        }
        var components = calendar.dateComponents([.era, .year, .month], from: monthStart)
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.day = min(startDay, days.count)
        guard let date = calendar.date(from: components) else {
            throw BudgetCycleError.dateCalculationFailed
        }
        return calendar.startOfDay(for: date)
    }

    private func makeInterval(start: Date, end: Date) throws -> DateInterval {
        guard start < end else {
            throw BudgetCycleError.invalidInterval
        }
        return DateInterval(start: start, end: end)
    }
}

enum BudgetPlanFactoryError: Error, Equatable, Sendable {
    case noncontiguousInterval
    case categoryIdentityCountMismatch
    case duplicateIdentity
}

struct BudgetPlanFactory: Sendable {
    func makePlan(
        copying previous: BudgetPlanSummary,
        interval: DateInterval,
        planID: UUID,
        categoryBudgetIDs: [UUID],
        timestamp: Date
    ) throws -> BudgetPlanDraft {
        guard interval.start == previous.cycleEnd, interval.start < interval.end else {
            throw BudgetPlanFactoryError.noncontiguousInterval
        }
        guard categoryBudgetIDs.count == previous.categoryBudgets.count else {
            throw BudgetPlanFactoryError.categoryIdentityCountMismatch
        }
        let previousIDs = Set(
            [previous.id] + previous.categoryBudgets.map(\.id)
        )
        guard Set(categoryBudgetIDs).count == categoryBudgetIDs.count,
              !categoryBudgetIDs.contains(planID),
              !previousIDs.contains(planID),
              previousIDs.isDisjoint(with: categoryBudgetIDs) else {
            throw BudgetPlanFactoryError.duplicateIdentity
        }

        let categoryBudgets = zip(previous.categoryBudgets, categoryBudgetIDs).map {
            category, id in
            CategoryBudgetDraft(
                id: id,
                category: category.category,
                limitMinorUnits: category.limitMinorUnits,
                warningThresholdBasisPoints: category.warningThresholdBasisPoints,
                createdAt: timestamp,
                updatedAt: timestamp
            )
        }

        return BudgetPlanDraft(
            id: planID,
            cycleStart: interval.start,
            cycleEnd: interval.end,
            currencyCode: previous.currencyCode,
            monthlyIncomeMinorUnits: previous.monthlyIncomeMinorUnits,
            totalBudgetMinorUnits: previous.totalBudgetMinorUnits,
            fixedExpensesMinorUnits: previous.fixedExpensesMinorUnits,
            savingGoalMinorUnits: previous.savingGoalMinorUnits,
            createdAt: timestamp,
            updatedAt: timestamp,
            categoryBudgets: categoryBudgets
        )
    }
}
