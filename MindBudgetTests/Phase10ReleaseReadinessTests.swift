import Foundation
import SwiftData
import Testing
@testable import MindBudget

@MainActor
struct Phase10ReleaseReadinessTests {
    @Test
    func dashboardFirstLoadWithTenThousandExpensesStaysInsideBudget() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let calendar = TestFixtures.utcCalendar
        let now = TestFixtures.now
        let interval = try #require(calendar.dateInterval(of: .month, for: now))
        try await Phase10PerformanceSeeder(modelContainer: controller.container).seed(
            expenseCount: 10_000,
            interval: interval,
            now: now,
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
            return
        }
        #expect(expenses.count == 10_000)
        #expect(wishItems.isEmpty)
        #expect(
            elapsed < .milliseconds(500),
            "Dashboard first load took \(elapsed); the release budget is 500 ms"
        )
    }
}

@ModelActor
private actor Phase10PerformanceSeeder {
    func seed(
        expenseCount: Int,
        interval: DateInterval,
        now: Date,
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
        for _ in 0..<expenseCount {
            let spentAt = now
            modelContext.insert(
                Expense(
                    id: UUID(),
                    amountMinorUnits: 1,
                    currencyCode: "USD",
                    categoryRaw: ExpenseCategory.food.rawValue,
                    bucketRaw: BudgetBucket.discretionary.rawValue,
                    merchantName: nil,
                    normalizedMerchantName: nil,
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
