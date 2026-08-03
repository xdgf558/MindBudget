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
    func snapshotFollowsAuthoritativeReservationFormula() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)

        #expect(snapshot.freeBudget.minorUnits == 150_000)
        #expect(snapshot.remainingFree.minorUnits == 110_000)
        #expect(snapshot.pendingFixed.minorUnits == 20_000)
        #expect(snapshot.pendingSaving.minorUnits == 30_000)
        #expect(snapshot.remainingTotal.minorUnits == 160_000)
        #expect(snapshot.availableRightNow.minorUnits == 110_000)
        #expect(snapshot.daysRemaining == 12)
        #expect(snapshot.safeDailySpend.minorUnits == 9_166)
    }

    @Test
    func fixedPaymentReducesItsPendingReservationWithoutDoubleCounting() throws {
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

        #expect(withoutFixedPayment.availableRightNow == withFixedPayment.availableRightNow)
        #expect(withoutFixedPayment.pendingFixed.minorUnits == 100_000)
        #expect(withFixedPayment.pendingFixed.minorUnits == 20_000)
    }

    @Test
    func overcommittedPlanReturnsZeroFreeBudgetAndNegativeAvailability() throws {
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
                    expense(amount: 10_000, category: .food, bucket: .discretionary, at: context.day20)
                ],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )

        #expect(snapshot.freeBudget.minorUnits == 0)
        #expect(snapshot.remainingFree.minorUnits == -10_000)
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
        #expect(snapshot.safeDailySpend.minorUnits == 150_000)
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
            of: money(120_000),
            category: .food,
            bucket: .discretionary,
            snapshot: snapshot,
            categoryBudgets: context.plan.categoryBudgets
        )
        #expect(impact.remainingFreeAfter.minorUnits == -10_000)
        #expect(impact.remainingTotalAfter.minorUnits == 40_000)
        #expect(impact.willExceedFreeBudget)
        #expect(!impact.willExceedTotalBudget)
        #expect(impact.impactRatioOfFreeBudget == Decimal(string: "0.8"))
    }

    @Test
    func purchaseImpactWithinBudgetReportsExactRatios() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)
        let impact = try engine.impact(
            of: money(18_332),
            category: .food,
            bucket: .discretionary,
            snapshot: snapshot,
            categoryBudgets: context.plan.categoryBudgets
        )
        #expect(impact.remainingTotalAfter.minorUnits == 141_668)
        #expect(impact.remainingFreeAfter.minorUnits == 91_668)
        #expect(!impact.willExceedTotalBudget)
        #expect(!impact.willExceedFreeBudget)
        #expect(impact.daysOfBudgetConsumed == Decimal(2))
        #expect(impact.impactRatioOfFreeBudget == Decimal(18_332) / Decimal(150_000))
    }

    @Test
    func fixedImpactDoesNotReduceRemainingFree() throws {
        let context = try makeContext()
        let snapshot = try configuredSnapshot(context: context)
        let impact = try engine.impact(
            of: money(75_000),
            category: .rent,
            bucket: .fixed,
            snapshot: snapshot,
            categoryBudgets: context.plan.categoryBudgets
        )
        #expect(impact.remainingFreeAfter == snapshot.remainingFree)
        #expect(impact.impactRatioOfFreeBudget == nil)
        #expect(impact.daysOfBudgetConsumed == nil)
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
            savingGoal: 50_000
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
            emotionTag: nil,
            purchaseReason: nil,
            source: .manual
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
