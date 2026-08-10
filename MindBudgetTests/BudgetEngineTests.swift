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

        #expect(snapshot.totalBudget.minorUnits == 400_000)
        #expect(snapshot.expectedExpenses.minorUnits == 300_000)
        #expect(snapshot.freeBudget.minorUnits == 350_000)
        #expect(snapshot.remainingFree.minorUnits == 230_000)
        #expect(snapshot.pendingFixed.minorUnits == 0)
        #expect(snapshot.pendingSaving.minorUnits == 30_000)
        #expect(snapshot.remainingTotal.minorUnits == 260_000)
        #expect(snapshot.availableRightNow.minorUnits == 230_000)
        #expect(snapshot.daysRemaining == 12)
        #expect(snapshot.safeDailySpend.minorUnits == 19_166)
    }

    @Test
    func previewAndSnapshotUseTheSameIncomeMinusSavingsBaseline() throws {
        let context = try makeContext(
            monthlyIncome: 2_000_000,
            totalBudget: 800_000,
            fixedForecast: 0,
            savingGoal: 200_000
        )
        let preview = try engine.allocation(
            baseTotalBudget: money(2_000_000),
            additionalBudget: money(0),
            fixedForecast: money(0),
            savingGoal: money(200_000)
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

        #expect(preview.flexibleBudget.minorUnits == 1_800_000)
        #expect(snapshot.freeBudget == preview.flexibleBudget)
        #expect(snapshot.availableRightNow == preview.flexibleBudget)
        #expect(snapshot.expectedExpenses.minorUnits == 800_000)
    }

    @Test
    func legacyFixedForecastPreservesUpgradeBalanceWithoutDoubleChargingActuals() throws {
        let context = try makeContext(fixedForecast: 0)
        let legacyPlan = BudgetPlanSummary(
            id: context.plan.id,
            cycleStart: context.plan.cycleStart,
            cycleEnd: context.plan.cycleEnd,
            currencyCode: context.plan.currencyCode,
            monthlyIncomeMinorUnits: context.plan.monthlyIncomeMinorUnits,
            totalBudgetMinorUnits: context.plan.totalBudgetMinorUnits,
            fixedExpensesMinorUnits: 100_000,
            savingGoalMinorUnits: context.plan.savingGoalMinorUnits,
            recordedIncomeMinorUnits: context.plan.recordedIncomeMinorUnits,
            allocatedIncomeMinorUnits: context.plan.allocatedIncomeMinorUnits,
            allocatedSavingsMinorUnits: context.plan.allocatedSavingsMinorUnits,
            authority: .legacyExpectedExpenses,
            categoryBudgets: context.plan.categoryBudgets
        )
        let beforePayment = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [],
                plan: legacyPlan,
                now: context.day20,
                calendar: context.calendar
            )
        )
        let withinForecast = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [
                    expense(
                        amount: 80_000,
                        category: .rent,
                        bucket: .fixed,
                        at: context.day20
                    )
                ],
                plan: legacyPlan,
                now: context.day20,
                calendar: context.calendar
            )
        )
        let aboveForecast = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [
                    expense(
                        amount: 120_000,
                        category: .rent,
                        bucket: .fixed,
                        at: context.day20
                    )
                ],
                plan: legacyPlan,
                now: context.day20,
                calendar: context.calendar
            )
        )

        #expect(beforePayment.fixedForecast.minorUnits == 100_000)
        #expect(beforePayment.pendingFixed.minorUnits == 100_000)
        #expect(beforePayment.totalBudget.minorUnits == 300_000)
        #expect(beforePayment.availableRightNow.minorUnits == 150_000)
        #expect(withinForecast.pendingFixed.minorUnits == 20_000)
        #expect(withinForecast.availableRightNow == beforePayment.availableRightNow)
        #expect(aboveForecast.pendingFixed.minorUnits == 0)
        #expect(aboveForecast.availableRightNow.minorUnits == 130_000)
    }

    @Test
    func legacyZeroIncomePlanKeepsItsExpectedExpenseFundingBase() throws {
        let context = try makeContext(
            monthlyIncome: 0,
            totalBudget: 600_000,
            fixedForecast: 100_000,
            savingGoal: 50_000,
            authority: .legacyExpectedExpenses
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

        #expect(snapshot.totalBudget.minorUnits == 600_000)
        #expect(snapshot.expectedExpenses.minorUnits == 600_000)
        #expect(snapshot.freeBudget.minorUnits == 450_000)
        #expect(snapshot.availableRightNow.minorUnits == 450_000)
    }

    @Test
    func newZeroIncomePlanDoesNotBorrowTheExpectedExpenseForecast() throws {
        let context = try makeContext(
            monthlyIncome: 0,
            totalBudget: 600_000,
            fixedForecast: 0,
            savingGoal: 0,
            authority: .incomeBased
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

        #expect(snapshot.totalBudget.minorUnits == 0)
        #expect(snapshot.expectedExpenses.minorUnits == 600_000)
        #expect(snapshot.freeBudget.minorUnits == 0)
        #expect(snapshot.availableRightNow.minorUnits == 0)
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
            fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 50_000,
            authority: .incomeBased,
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
            monthlyIncomeMinorUnits: 250_000,
            totalBudgetMinorUnits: 250_000,
            fixedExpensesMinorUnits: 200_000,
            savingGoalMinorUnits: 250_000,
            authority: .incomeBased,
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

        #expect(withoutFixedPayment.availableRightNow.minorUnits == 310_000)
        #expect(withFixedPayment.availableRightNow.minorUnits == 230_000)
        #expect(withoutFixedPayment.pendingFixed.minorUnits == 0)
        #expect(withFixedPayment.pendingFixed.minorUnits == 0)
    }

    @Test
    func spendingBeyondDisposableBudgetReturnsNegativeAvailability() throws {
        let context = try makeContext(
            monthlyIncome: 120_000,
            totalBudget: 120_000,
            fixedForecast: 0,
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
        #expect(snapshot.safeDailySpend.minorUnits == 350_000)
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
            of: money(240_000),
            category: .food,
            bucket: .discretionary,
            snapshot: snapshot,
            categoryBudgets: context.plan.categoryBudgets
        )
        #expect(impact.remainingFreeAfter.minorUnits == -10_000)
        #expect(impact.remainingTotalAfter.minorUnits == 20_000)
        #expect(impact.willExceedFreeBudget)
        #expect(!impact.willExceedTotalBudget)
        #expect(impact.impactRatioOfFreeBudget == Decimal(240_000) / Decimal(350_000))
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
        #expect(impact.remainingTotalAfter.minorUnits == 238_334)
        #expect(impact.remainingFreeAfter.minorUnits == 208_334)
        #expect(!impact.willExceedTotalBudget)
        #expect(!impact.willExceedFreeBudget)
        #expect(impact.daysOfBudgetConsumed == Decimal(21_666) / Decimal(19_166))
        #expect(impact.impactRatioOfFreeBudget == Decimal(21_666) / Decimal(350_000))
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
        #expect(impact.remainingFreeAfter.minorUnits == 155_000)
        #expect(impact.impactRatioOfFreeBudget == Decimal(75_000) / Decimal(350_000))
        #expect(impact.daysOfBudgetConsumed == Decimal(75_000) / Decimal(19_166))
    }

    @Test
    func paceChargesOnlyTodaysDiscretionaryEntriesToTheDailyReference() throws {
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

        #expect(pace.spentToday.minorUnits == 12_000)
        #expect(pace.startingDailyAllowance.minorUnits == 25_000)
        #expect(pace.leftToSpendToday.minorUnits == 13_000)
        #expect(pace.exceededDailyAllowanceBy.minorUnits == 0)
        #expect(!pace.hasUsedDailyAllowance)
        #expect(!pace.hasExceededDailyAllowance)
        #expect(pace.expectedSpentByToday.minorUnits == 193_548)
        #expect(pace.paceDifference.minorUnits == 131_548)
        #expect(!pace.isAheadOfPace)
        #expect(pace.dayNumber == 20)
        #expect(pace.totalDays == 31)
    }

    @Test
    func fixedExpenseRebalancesRemainingDaysWithoutASecondSameDayCharge() throws {
        let context = try makeContext()
        let previousDay = try #require(
            context.calendar.date(byAdding: .day, value: -1, to: context.day20)
        )
        let priorExpense = expense(
            amount: 20_000,
            category: .food,
            bucket: .discretionary,
            at: previousDay
        )
        let fixedExpense = expense(
            amount: 30_000,
            category: .rent,
            bucket: .fixed,
            at: context.day20
        )
        let beforeSnapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [priorExpense],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )
        let afterSnapshot = try requireConfigured(
            engine.snapshot(
                cycle: context.cycle,
                currencyCode: "USD",
                expenses: [priorExpense, fixedExpense],
                plan: context.plan,
                now: context.day20,
                calendar: context.calendar
            )
        )
        let before = try engine.pace(
            snapshot: beforeSnapshot,
            expenses: [priorExpense],
            now: context.day20,
            calendar: context.calendar
        )
        let after = try engine.pace(
            snapshot: afterSnapshot,
            expenses: [priorExpense, fixedExpense],
            now: context.day20,
            calendar: context.calendar
        )

        #expect(
            beforeSnapshot.remainingFree.minorUnits - afterSnapshot.remainingFree.minorUnits
                == fixedExpense.amount.minorUnits
        )
        #expect(before.startingDailyAllowance.minorUnits == 27_500)
        #expect(after.startingDailyAllowance.minorUnits == 25_000)
        #expect(after.spentToday.minorUnits == 0)
        #expect(after.leftToSpendToday == after.startingDailyAllowance)
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
            amount: 27_500,
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
        #expect(before.leftToSpendToday.minorUnits == 27_500)
        #expect(after.leftToSpendToday.minorUnits == 22_500)
        #expect(
            before.leftToSpendToday.minorUnits - after.leftToSpendToday.minorUnits
                == todaysExpense.amount.minorUnits
        )
        #expect(after.exceededDailyAllowanceBy.minorUnits == 0)
        #expect(exact.startingDailyAllowance.minorUnits == 27_500)
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
        #expect(pace.expectedSpentByToday.minorUnits == 300_000)
        #expect(pace.startingDailyAllowance.minorUnits == 350_000)
        #expect(pace.leftToSpendToday.minorUnits == 350_000)
        #expect(pace.exceededDailyAllowanceBy.minorUnits == 0)
        #expect(pace.paceDifference.minorUnits == 300_000)
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
            monthlyIncome: 120_000,
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
        monthlyIncome: Int64 = 400_000,
        totalBudget: Int64 = 300_000,
        fixedForecast: Int64 = 0,
        savingGoal: Int64 = 50_000,
        authority: BudgetPlanAuthority = .incomeBased
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
            monthlyIncomeMinorUnits: monthlyIncome,
            totalBudgetMinorUnits: totalBudget,
            fixedExpensesMinorUnits: fixedForecast,
            savingGoalMinorUnits: savingGoal,
            authority: authority,
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
