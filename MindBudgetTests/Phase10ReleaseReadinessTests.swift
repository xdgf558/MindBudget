import Foundation
import SwiftData
import Testing
@testable import MindBudget

@MainActor
struct Phase10ReleaseReadinessTests {
    @Test
    func dashboardProjectionLoadsTenThousandDiverseCurrentCycleExpenses() async throws {
        let result = try await loadDashboardFixture()

        #expect(result.expenses.count == 10_000)
        #expect(result.wishItems.isEmpty)
        #expect(Set(result.expenses.map(\.category)) == Set(ExpenseCategory.allCases))
        #expect(Set(result.expenses.map { result.calendar.startOfDay(for: $0.spentAt) }).count > 1)
        #expect(result.expenses.filter { $0.merchantName != nil }.count == 2_500)
        #expect(Set(result.expenses.compactMap(\.merchantName)).count == 16)
    }

    /// A wall-clock ceiling is a local release-machine signal, not a hosted-CI gate.
    /// GitHub Actions skips only this test and still runs the deterministic 10,000-row
    /// projection test above; `Scripts/validate.sh` runs both by default everywhere else.
    @Test
    func localDashboardFirstLoadBenchmarkWithTenThousandDiverseExpensesStaysBelowFiveHundredMilliseconds() async throws {
        let result = try await loadDashboardFixture()

        // Emit the same measured interval on success as well as failure; this is outside
        // the timed production load and does not change its strict release threshold.
        print("Dashboard first-load measured interval: \(result.elapsed); limit: 500 ms")
        #expect(
            result.elapsed < .milliseconds(500),
            "Dashboard first load took \(result.elapsed); the local release budget is 500 ms"
        )
    }

    private func loadDashboardFixture() async throws -> DashboardLoadResult {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let calendar = TestFixtures.utcCalendar
        let now = TestFixtures.now
        let interval = try #require(calendar.dateInterval(of: .month, for: now))
        try await Phase10PerformanceSeeder(modelContainer: controller.container).seed(
            expenseCount: 10_000,
            interval: interval,
            now: now,
            calendar: calendar,
            timeZoneIdentifier: calendar.timeZone.identifier
        )
        let viewModel = DashboardViewModel()
        let clock = ContinuousClock()
        let start = clock.now

        await viewModel.load(
            dataActor: controller.dataActor,
            currencyCode: "USD",
            cycleStartDay: 1,
            calendar: calendar,
            now: now
        )

        let elapsed = start.duration(to: clock.now)
        guard case let .configured(_, _, expenses, wishItems) = viewModel.state else {
            Issue.record("Expected configured Dashboard state")
            throw Phase10ReleaseReadinessTestError.unexpectedDashboardState
        }
        return DashboardLoadResult(
            expenses: expenses,
            wishItems: wishItems,
            calendar: calendar,
            elapsed: elapsed
        )
    }
}

private struct DashboardLoadResult {
    let expenses: [ExpenseSummary]
    let wishItems: [WishItemSummary]
    let calendar: Calendar
    let elapsed: Duration
}

private enum Phase10ReleaseReadinessTestError: Error {
    case unexpectedDashboardState
    case invalidFixtureDate
}

@ModelActor
private actor Phase10PerformanceSeeder {
    func seed(
        expenseCount: Int,
        interval: DateInterval,
        now: Date,
        calendar: Calendar,
        timeZoneIdentifier: String
    ) throws {
        modelContext.autosaveEnabled = false
        modelContext.insert(
            BudgetPlan(
                id: UUID(),
                cycleStart: interval.start,
                cycleEnd: interval.end,
                currencyCode: "USD",
                monthlyIncomeMinorUnits: 2_000_000,
                totalBudgetMinorUnits: 1_500_000,
                fixedExpensesMinorUnits: 300_000,
                savingGoalMinorUnits: 200_000,
                createdAt: now,
                updatedAt: now,
                categoryBudgets: []
            )
        )
        let elapsedDayCount = max(
            1,
            (calendar.dateComponents(
                [.day],
                from: interval.start,
                to: calendar.startOfDay(for: now)
            ).day ?? 0) + 1
        )
        let categories = ExpenseCategory.allCases
        for index in 0..<expenseCount {
            guard let spentAt = calendar.date(
                byAdding: .day,
                value: index % elapsedDayCount,
                to: interval.start
            ) else {
                throw Phase10ReleaseReadinessTestError.invalidFixtureDate
            }
            let category = categories[index % categories.count]
            let merchantNumber = (index / 4) % 16
            let merchantName = index.isMultiple(of: 4) ? "Merchant \(merchantNumber)" : nil
            modelContext.insert(
                Expense(
                    id: UUID(),
                    amountMinorUnits: Int64((index % 100) + 1),
                    currencyCode: "USD",
                    categoryRaw: category.rawValue,
                    bucketRaw: category.defaultBucket.rawValue,
                    merchantName: merchantName,
                    normalizedMerchantName: merchantName?.lowercased(),
                    note: nil,
                    spentAt: spentAt,
                    spentTimeZoneIdentifier: timeZoneIdentifier,
                    createdAt: spentAt,
                    updatedAt: spentAt,
                    paymentMethodRaw: nil,
                    emotionTagRaw: nil,
                    purchaseReasonRaw: nil,
                    isPlanned: false,
                    isRecurring: false,
                    sourceRaw: ExpenseSource.manual.rawValue,
                    allowMerchantIndexing: false
                )
            )
        }
        try modelContext.save()
    }
}
