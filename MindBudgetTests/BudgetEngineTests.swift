import Foundation
import Testing
@testable import MindBudget

struct BudgetEngineTests {
    private let engine = BudgetEngine()

    @Test
    func snapshotUsesHalfOpenCycleAndSeparatesBuckets() throws {
        let context = try makeContext()
        let expenses = [
            expense(amount: 80_000, category: .rent, bucket: .fixed, at: context.start),
            expense(amount: 40_000, category: .food, bucket: .discretionary, at: context.day20),
            expense(amount: 20_000, category: .other, bucket: .savings, at: context.day20),
            expense(amount: 90_000, category: .shopping, bucket: .discretionary, at: context.end)
        ]

        let snapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: expenses,
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )

        #expect(snapshot.spentTotal.minorUnits == 140_000)
        #expect(snapshot.fixedSpent.minorUnits == 80_000)
        #expect(snapshot.discretionarySpent.minorUnits == 40_000)
        #expect(snapshot.savedSoFar.minorUnits == 20_000)
        #expect(snapshot.spentByCategory[.shopping] == nil)
    }

    @Test
    func snapshotUsesSavingsReservationAndActualFixedExpenses() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)

        #expect(snapshot.freeBudget.minorUnits == 250_000)
        #expect(snapshot.remainingFree.minorUnits == 130_000)
        #expect(snapshot.pendingFixed.minorUnits == 0)
        #expect(snapshot.pendingSaving.minorUnits == 30_000)
        #expect(snapshot.remainingTotal.minorUnits == 160_000)
        #expect(snapshot.availableRightNow.minorUnits == 130_000)
        #expect(snapshot.daysRemaining == 12)
        #expect(snapshot.safeDailySpend.minorUnits == 10_833)
    }

    @Test
    func allocationExplainsAvailableFullyAllocatedAndOvercommittedPlans() throws {
        let available = try engine.allocation(
            totalBudget: money(600_000),
            fixedForecast: money(300_000),
            savingGoal: money(50_000)
        )
        let fullyAllocated = try engine.allocation(
            totalBudget: money(350_000),
            fixedForecast: money(300_000),
            savingGoal: money(50_000)
        )
        let overcommitted = try engine.allocation(
            totalBudget: money(300_000),
            fixedForecast: money(300_000),
            savingGoal: money(50_000)
        )

        #expect(available.flexibleBudget.minorUnits == 250_000)
        #expect(available.status == .available)
        #expect(fullyAllocated.flexibleBudget.minorUnits == 0)
        #expect(fullyAllocated.status == .fullyAllocated)
        #expect(overcommitted.flexibleBudget.minorUnits == 0)
        #expect(overcommitted.status == .overcommitted)
    }

    @Test
    func configuredBudgetProducesAConcreteRebalancedAmountForToday() throws {
        let calendar = TestFixtures.utcCalendar
        let start = try date(2026, 8, 1, calendar: calendar)
        let end = try date(2026, 9, 1, calendar: calendar)
        let now = try date(2026, 8, 7, calendar: calendar)
        let plan = BudgetPlanSummary(
            id: UUID(),
            cycleStart: start,
            cycleEnd: end,
            currencyCode: "CNY",
            monthlyIncomeMinorUnits: 600_000,
            totalBudgetMinorUnits: 600_000,
            fixedExpensesMinorUnits: 300_000,
            savingGoalMinorUnits: 50_000,
            categoryBudgets: []
        )
        let snapshot = try requireConfigured(
            engine.snapshot(
                cycle: DateInterval(start: start, end: end),
                currencyCode: "CNY",
                expenses: [],
                plan: plan,
                now: now,
                calendar: calendar
            )
        )
        let pace = try engine.pace(
            snapshot: snapshot,
            expenses: [],
            now: now,
            calendar: calendar
        )

        #expect(snapshot.freeBudget.minorUnits == 550_000)
        #expect(snapshot.daysRemaining == 25)
        #expect(pace.startingDailyAllowance.minorUnits == 22_000)
        #expect(pace.leftToSpendToday.minorUnits == 22_000)
        #expect(pace.exceededDailyAllowanceBy.minorUnits == 0)
        #expect(!pace.hasUsedDailyAllowance)
        #expect(!pace.hasNoDailyAllowance)
    }

    @Test
    func zeroFlexibleBudgetExplainsMissingDailyAllowanceBeforeSpendingToday() throws {
        let calendar = TestFixtures.utcCalendar
        let start = try date(2026, 8, 1, calendar: calendar)
        let end = try date(2026, 9, 1, calendar: calendar)
        let now = try date(2026, 8, 7, calendar: calendar)
        let plan = BudgetPlanSummary(
            id: UUID(),
            cycleStart: start,
            cycleEnd: end,
            currencyCode: "CNY",
            monthlyIncomeMinorUnits: 600_000,
            totalBudgetMinorUnits: 250_000,
            fixedExpensesMinorUnits: 200_000,
            savingGoalMinorUnits: 250_000,
            categoryBudgets: []
        )
        let snapshot = try requireConfigured(
            engine.snapshot(
                cycle: DateInterval(start: start, end: end),
                currencyCode: "CNY",
                expenses: [],
                plan: plan,
                now: now,
                calendar: calendar
            )
        )
        let pace = try engine.pace(
            snapshot: snapshot,
            expenses: [],
            now: now,
            calendar: calendar
        )

        #expect(snapshot.remainingFree.minorUnits == 0)
        #expect(pace.startingDailyAllowance.minorUnits == 0)
        #expect(pace.leftToSpendToday.minorUnits == 0)
        #expect(pace.exceededDailyAllowanceBy.minorUnits == 0)
        #expect(pace.hasNoDailyAllowance)
        #expect(!pace.hasUsedDailyAllowance)
        #expect(!pace.hasExceededDailyAllowance)
    }

    @Test
    func actualFixedPaymentReducesDisposableBudgetWithoutASeparateReservation() throws {
        let context = try makeContext()
        let withoutFixedPayment = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [
                    expense(amount: 40_000, category: .food, bucket: .discretionary, at: context.day20),
                    expense(amount: 20_000, category: .other, bucket: .savings, at: context.day20)
                ],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )
        let withFixedPayment = try configuredSnapshot(context: context)

        #expect(withoutFixedPayment.availableRightNow.minorUnits == 210_000)
        #expect(withFixedPayment.availableRightNow.minorUnits == 130_000)
        #expect(withoutFixedPayment.pendingFixed.minorUnits == 0)
        #expect(withFixedPayment.pendingFixed.minorUnits == 0)
    }

    @Test
    func spendingBeyondDisposableBudgetReturnsNegativeAvailability() throws {
        let context = try makeContext(
            totalBudget: 120_000,
            fixedForecast: 80_000,
            savingGoal: 50_000
        )
        let snapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [
                    expense(amount: 80_000, category: .rent, bucket: .fixed, at: context.day20),
                    expense(amount: 10_000, category: .food, bucket: .discretionary, at: context.day20)
                ],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )

        #expect(snapshot.freeBudget.minorUnits == 70_000)
        #expect(snapshot.remainingFree.minorUnits == -20_000)
        #expect(snapshot.availableRightNow.minorUnits == -20_000)
        #expect(snapshot.safeDailySpend.minorUnits == 0)
    }

    @Test
    func unconfiguredSnapshotContainsNoInventedBudgetValues() throws {
        let context = try makeContext()
        let snapshot = try engine.snapshot(
            cycle: context.cycle,
            currencyCode: "CNY",
            expenses: [],
            plan: nil,
            now: context.day20,
            calendar: context.calendar
        )

        guard case let .unconfigured(cycle, currencyCode) = snapshot else {
            Issue.record("Expected an unconfigured snapshot")
            return
        }
        #expect(cycle == context.cycle)
        #expect(currencyCode == "CNY")
    }

    @Test
    func daysRemainingNeverReachesZero() throws {
        let context = try makeContext()
        let finalMinute = try #require(
            context.calendar.date(byAdding: .minute, value: -1, to: context.end)
        )
        let snapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [],
                plan: context.plan,
                now: finalMinute,
                calendar: context.calendar
            )
        )

        #expect(snapshot.daysRemaining == 1)
        #expect(snapshot.safeDailySpend.minorUnits == 250_000)
    }

    @Test
    func referenceDateMustRemainInsideTheHalfOpenCycle() throws {
        let context = try makeContext()
        let beforeStart = try #require(
            context.calendar.date(byAdding: .minute, value: -1, to: context.start)
        )
        let afterEnd = try #require(
            context.calendar.date(byAdding: .minute, value: 1, to: context.end)
        )

        for invalidDate in [beforeStart, context.end, afterEnd] {
            #expect(throws: BudgetEngineError.referenceDateOutsideCycle) {
                _ = try engine.snapshot(
                    cycle: context.cycle,
                    currencyCode: "USD",
                    expenses: [],
                    plan: context.plan,
                    now: invalidDate,
                    calendar: context.calendar
                )
            }
        }
    }

    @Test
    func discretionaryImpactCanExceedFreeBudget() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)
        let impact = try engine.impact(
            of: money(140_000),
            category: .food,
            bucket: .discretionary,
            snapshot: snapshot,
            categoryBudgets: context.plan.categoryBudgets
        )
        #expect(impact.remainingFreeAfter.minorUnits == -10_000)
        #expect(impact.remainingTotalAfter.minorUnits == 20_000)
        #expect(impact.willExceedFreeBudget)
        #expect(!impact.willExceedTotalBudget)
        #expect(impact.impactRatioOfFreeBudget == Decimal(string: "0.56"))
    }

    @Test
    func purchaseImpactWithinBudgetReportsExactRatios() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)
        let impact = try engine.impact(
            of: money(21_666),
            category: .food,
            bucket: .discretionary,
            snapshot: snapshot,
            categoryBudgets: context.plan.categoryBudgets
        )
        #expect(impact.remainingTotalAfter.minorUnits == 138_334)
        #expect(impact.remainingFreeAfter.minorUnits == 108_334)
        #expect(!impact.willExceedTotalBudget)
        #expect(!impact.willExceedFreeBudget)
        #expect(impact.daysOfBudgetConsumed == Decimal(2))
        #expect(impact.impactRatioOfFreeBudget == Decimal(21_666) / Decimal(250_000))
    }

    @Test
    func fixedImpactReducesRemainingDisposableBudget() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)
        let impact = try engine.impact(
            of: money(75_000),
            category: .rent,
            bucket: .fixed,
            snapshot: snapshot,
            categoryBudgets: context.plan.categoryBudgets
        )
        #expect(impact.remainingFreeAfter.minorUnits == 55_000)
        #expect(impact.impactRatioOfFreeBudget == Decimal(string: "0.3"))
        #expect(impact.daysOfBudgetConsumed == Decimal(75_000) / Decimal(10_833))
    }

    @Test
    func paceUsesTodaysFixedAndDiscretionaryEntriesAndExactCycleDays() throws {
        let context = try makeContext()
        let previousDay = try #require(
            context.calendar.date(byAdding: .day, value: -1, to: context.day20)
        )
        let expenses = [
            expense(amount: 20_000, category: .food, bucket: .discretionary, at: previousDay),
            expense(amount: 12_000, category: .coffee, bucket: .discretionary, at: context.day20),
            expense(amount: 30_000, category: .rent, bucket: .fixed, at: context.day20)
        ]
        let snapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: expenses,
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )

        let pace = try engine.pace(
            snapshot: snapshot,
            expenses: expenses,
            now: context.day20,
            calendar: context.calendar
        )

        #expect(pace.spentToday.minorUnits == 42_000)
        #expect(pace.startingDailyAllowance.minorUnits == 19_166)
        #expect(pace.leftToSpendToday.minorUnits == 0)
        #expect(pace.exceededDailyAllowanceBy.minorUnits == 22_834)
        #expect(pace.hasUsedDailyAllowance)
        #expect(pace.hasExceededDailyAllowance)
        #expect(pace.expectedSpentByToday.minorUnits == 161_290)
        #expect(pace.paceDifference.minorUnits == 99_290)
        #expect(!pace.isAheadOfPace)
        #expect(pace.dayNumber == 20)
        #expect(pace.totalDays == 31)
    }

    @Test
    func eachDiscretionaryEntryReducesTodaysAmountOneForOne() throws {
        let context = try makeContext()
        let previousDay = try #require(
            context.calendar.date(byAdding: .day, value: -1, to: context.day20)
        )
        let priorExpenses = [
            expense(
                amount: 20_000,
                category: .food,
                bucket: .discretionary,
                at: previousDay
            )
        ]
        let todaysExpense = expense(
            amount: 5_000,
            category: .coffee,
            bucket: .discretionary,
            at: context.day20
        )
        let exactAllowanceExpense = expense(
            amount: 19_166,
            category: .coffee,
            bucket: .discretionary,
            at: context.day20
        )

        let beforeSnapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: priorExpenses,
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )
        let afterSnapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: priorExpenses + [todaysExpense],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )
        let before = try engine.pace(
            snapshot: beforeSnapshot,
            expenses: priorExpenses,
            now: context.day20,
            calendar: context.calendar
        )
        let after = try engine.pace(
            snapshot: afterSnapshot,
            expenses: priorExpenses + [todaysExpense],
            now: context.day20,
            calendar: context.calendar
        )
        let exactSnapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: priorExpenses + [exactAllowanceExpense],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )
        let exact = try engine.pace(
            snapshot: exactSnapshot,
            expenses: priorExpenses + [exactAllowanceExpense],
            now: context.day20,
            calendar: context.calendar
        )

        #expect(before.startingDailyAllowance == after.startingDailyAllowance)
        #expect(before.leftToSpendToday.minorUnits == 19_166)
        #expect(after.leftToSpendToday.minorUnits == 14_166)
        #expect(
            before.leftToSpendToday.minorUnits - after.leftToSpendToday.minorUnits
                == todaysExpense.amount.minorUnits
        )
        #expect(after.exceededDailyAllowanceBy.minorUnits == 0)
        #expect(exact.startingDailyAllowance.minorUnits == 19_166)
        #expect(exact.leftToSpendToday.minorUnits == 0)
        #expect(exact.exceededDailyAllowanceBy.minorUnits == 0)
        #expect(exact.hasUsedDailyAllowance)
        #expect(!exact.hasExceededDailyAllowance)
    }

    @Test
    func paceUsesTheCompleteBudgetOnTheLastCycleDay() throws {
        let context = try makeContext()
        let lastDay = try #require(
            context.calendar.date(byAdding: .day, value: -1, to: context.end)
        )
        let snapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [],
                plan: context.plan,
                now: lastDay,
                calendar: context.calendar
            )
        )

        let pace = try engine.pace(
            snapshot: snapshot,
            expenses: [],
            now: lastDay,
            calendar: context.calendar
        )

        #expect(pace.dayNumber == 31)
        #expect(pace.totalDays == 31)
        #expect(pace.expectedSpentByToday.minorUnits == 250_000)
        #expect(pace.startingDailyAllowance.minorUnits == 250_000)
        #expect(pace.leftToSpendToday.minorUnits == 250_000)
        #expect(pace.exceededDailyAllowanceBy.minorUnits == 0)
        #expect(pace.paceDifference.minorUnits == 250_000)
        #expect(!pace.isAheadOfPace)
    }

    @Test
    func paceRejectsAReferenceDateOutsideTheSnapshotCycle() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)

        #expect(throws: BudgetEngineError.referenceDateOutsideCycle) {
            _ = try engine.pace(
                snapshot: snapshot,
                expenses: [],
                now: context.end,
                calendar: context.calendar
            )
        }
    }

    @Test
    func categoryRiskUsesProjectedSpend() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)
        let cases: [(Int64, CategoryBudgetRisk.Level)] = [
            (30_000, .ok),
            (40_000, .approaching),
            (60_000, .atLimit),
            (70_000, .over)
        ]

        for (purchaseAmount, expectedLevel) in cases {
            let impact = try engine.impact(
                of: money(purchaseAmount),
                category: .food,
                bucket: .discretionary,
                snapshot: snapshot,
                categoryBudgets: context.plan.categoryBudgets
            )
            #expect(impact.categoryRisk?.level == expectedLevel)
            #expect(impact.categoryRisk?.spent.minorUnits == 40_000)
            #expect(impact.categoryRisk?.projectedAfterPurchase.minorUnits == 40_000 + purchaseAmount)
        }
    }

    @Test
    func zeroFreeBudgetHasNoRatioBaseline() throws {
        let context = try makeContext(
            totalBudget: 120_000,
            fixedForecast: 80_000,
            savingGoal: 120_000
        )
        let snapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )

        let impact = try engine.impact(
            of: money(300),
            category: .coffee,
            bucket: .discretionary,
            snapshot: snapshot,
            categoryBudgets: []
        )

        #expect(impact.impactRatioOfFreeBudget == nil)
        #expect(impact.daysOfBudgetConsumed == nil)
    }

    @Test
    func engineRejectsCrossCurrencyInput() throws {
        let context = try makeContext()

        #expect(throws: BudgetEngineError.currencyMismatch(expected: "USD", actual: "CNY")) {
            _ = try engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [
                    expense(
                        amount: 100,
                        currencyCode: "CNY",
                        category: .food,
                        bucket: .discretionary,
                        at: context.day20
                    )
                ],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        }
    }

    @Test
    func aggregateOverflowThrowsInsteadOfWrapping() throws {
        let context = try makeContext()
        let expenses = [
            expense(amount: Int64.max, category: .food, bucket: .discretionary, at: context.day20),
            expense(amount: 1, category: .food, bucket: .discretionary, at: context.day20)
        ]

        #expect(throws: BudgetEngineError.arithmeticOverflow) {
            _ = try engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: expenses,
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        }
    }

    private func configuredSnapshot(context: Context) throws -> ConfiguredBudgetSnapshot {
        try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [
                    expense(amount: 80_000, category: .rent, bucket: .fixed, at: context.day20),
                    expense(amount: 40_000, category: .food, bucket: .discretionary, at: context.day20),
                    expense(amount: 20_000, category: .other, bucket: .savings, at: context.day20)
                ],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )
    }

    private func requireConfigured(_ snapshot: BudgetSnapshot) throws -> ConfiguredBudgetSnapshot {
        guard case let .configured(configured) = snapshot else {
            throw TestError.expectedConfiguredSnapshot
        }
        return configured
    }

    private func makeContext(
        totalBudget: Int64 = 300_000,
        fixedForecast: Int64 = 100_000,
        savingGoal: Int64 = 50_000
    ) throws -> Context {
        let calendar = TestFixtures.utcCalendar
        let start = try date(2026, 1, 1, calendar: calendar)
        let end = try date(2026, 2, 1, calendar: calendar)
        let day20 = try date(2026, 1, 20, calendar: calendar)
        let categoryBudget = CategoryBudgetSummary(
            id: UUID(),
            category: .food,
            limitMinorUnits: 100_000,
            warningThresholdBasisPoints: 8_000
        )
        let plan = BudgetPlanSummary(
            id: UUID(),
            cycleStart: start,
            cycleEnd: end,
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 400_000,
            totalBudgetMinorUnits: totalBudget,
            fixedExpensesMinorUnits: fixedForecast,
            savingGoalMinorUnits: savingGoal,
            categoryBudgets: [categoryBudget]
        )
        return Context(
            calendar: calendar,
            start: start,
            end: end,
            day20: day20,
            cycle: DateInterval(start: start, end: end),
            plan: plan
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        calendar: Calendar
    ) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func expense(
        amount: Int64,
        currencyCode: String = "USD",
        category: ExpenseCategory,
        bucket: BudgetBucket,
        at date: Date
    ) -> ExpenseSummary {
        ExpenseSummary(
            id: UUID(),
            amount: Money(minorUnits: amount, currencyCode: currencyCode),
            category: category,
            bucket: bucket,
            merchantName: nil,
            spentAt: date,
            spentTimeZoneIdentifier: "UTC",
            createdAt: date,
            updatedAt: date,
            paymentMethod: nil,
            emotionTag: nil,
            purchaseReason: nil,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
    }

    private func money(_ minorUnits: Int64) -> Money {
        Money(minorUnits: minorUnits, currencyCode: "USD")
    }

    private struct Context {
        let calendar: Calendar
        let start: Date
        let end: Date
        let day20: Date
        let cycle: DateInterval
        let plan: BudgetPlanSummary
    }

    private enum TestError: Error {
        case expectedConfiguredSnapshot
    }
}
