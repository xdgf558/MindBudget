import Foundation
import SwiftData
import Testing
@testable import MindBudget

@MainActor
struct Phase11FreeTierTests {
    @Test
    func incomeCRUDKeepsRawNoteBehindDetailAndDoesNotRewriteBudget() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let plan = try budgetPlan()
        _ = try await actor.createBudgetPlan(plan)
        let original = incomeDraft(
            amountMinorUnits: 350_000,
            category: .salary,
            sourceName: "Studio",
            note: "Private payroll note"
        )

        let created = try await actor.createIncome(original)
        let detail = try #require(try await actor.fetchIncomeDetail(id: original.id))
        let storedPlan = try #require(try await actor.fetchBudgetPlanSummaries().first)

        #expect(created.amount.minorUnits == 350_000)
        #expect(created.category == .salary)
        #expect(detail.note == "Private payroll note")
        #expect(storedPlan.monthlyIncomeMinorUnits == plan.monthlyIncomeMinorUnits)
        #expect(try await actor.fetchExpenseSummaries().isEmpty)

        let updatedDraft = incomeDraft(
            id: original.id,
            amountMinorUnits: 42_500,
            category: .freelance,
            sourceName: "Client",
            note: "Invoice 12",
            createdAt: original.createdAt,
            updatedAt: original.updatedAt.addingTimeInterval(60)
        )
        let updated = try await actor.updateIncome(id: original.id, with: updatedDraft)
        let export = try #require(try await actor.fetchIncomeExportRecords().first)

        #expect(updated.amount.minorUnits == 42_500)
        #expect(updated.category == .freelance)
        #expect(export.note == "Invoice 12")

        try await actor.deleteIncome(id: original.id)
        #expect(try await actor.fetchIncomeSummaries().isEmpty)
        #expect(try await actor.fetchBudgetPlanSummaries().first?.monthlyIncomeMinorUnits == plan.monthlyIncomeMinorUnits)
    }

    @Test
    func schemaV1StoreMigratesToV2WithoutLosingExistingExpenses() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudgetV1Migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("MindBudget.store")
        let expenseID = UUID()

        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(
                Expense(
                    id: expenseID,
                    amountMinorUnits: 1_250,
                    currencyCode: "USD",
                    categoryRaw: ExpenseCategory.food.rawValue,
                    bucketRaw: BudgetBucket.discretionary.rawValue,
                    merchantName: "Cafe",
                    normalizedMerchantName: "cafe",
                    note: "Existing V1 note",
                    spentAt: TestFixtures.now,
                    spentTimeZoneIdentifier: "UTC",
                    createdAt: TestFixtures.now,
                    updatedAt: TestFixtures.now,
                    paymentMethodRaw: nil,
                    emotionTagRaw: nil,
                    purchaseReasonRaw: PurchaseReason.need.rawValue,
                    isPlanned: false,
                    isRecurring: false,
                    sourceRaw: ExpenseSource.manual.rawValue,
                    allowMerchantIndexing: false
                )
            )
            try context.save()
        }

        let upgraded = try DataController(storeURL: storeURL).dataActor
        let expenses = try await upgraded.fetchExpenseSummaries()

        #expect(expenses.map(\.id) == [expenseID])
        #expect(expenses.first?.amount.minorUnits == 1_250)
        #expect(try await upgraded.fetchIncomeSummaries().isEmpty)
    }

    @Test
    func sixthOpenWishlistItemIsRejectedAtomicallyAndAClosedSlotCanBeReused() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        var inserted: [WishItemSummary] = []
        for index in 0..<WishlistPolicy.maximumOpenItems {
            inserted.append(
                try await actor.createWishItem(wishDraft(name: "Wish \(index + 1)"))
            )
        }

        await #expect(throws: DataValidationError.wishlistLimitReached(limit: 5)) {
            _ = try await actor.createWishItem(wishDraft(name: "Wish 6"))
        }
        #expect(try await actor.fetchWishItemSummaries().count == 5)

        _ = try await actor.transitionWishItem(
            id: inserted[0].id,
            to: .archived,
            at: TestFixtures.now.addingTimeInterval(60)
        )
        let replacement = try await actor.createWishItem(wishDraft(name: "Replacement"))

        #expect(replacement.status == .active)
        #expect(
            try await actor.fetchWishItemSummaries()
                .filter { $0.status.countsTowardOpenLimit }
                .count == 5
        )
    }

    @Test
    func reopeningAClosedWishAlsoRespectsTheFiveItemLimit() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        for index in 0..<WishlistPolicy.maximumOpenItems {
            _ = try await actor.createWishItem(wishDraft(name: "Open \(index + 1)"))
        }
        let archived = try await actor.createWishItem(
            wishDraft(name: "Archived", status: .archived)
        )

        await #expect(throws: DataValidationError.wishlistLimitReached(limit: 5)) {
            _ = try await actor.transitionWishItem(
                id: archived.id,
                to: .active,
                at: TestFixtures.now.addingTimeInterval(60)
            )
        }
        #expect(try await actor.fetchWishItemDetail(id: archived.id)?.summary.status == .archived)
    }

    @Test
    func recentInsightsUseAnExactThirtyCalendarDayWindow() throws {
        let calendar = TestFixtures.utcCalendar
        let now = TestFixtures.now
        let today = calendar.startOfDay(for: now)
        let day29 = try #require(calendar.date(byAdding: .day, value: -29, to: today))
        let day30 = try #require(calendar.date(byAdding: .day, value: -30, to: today))
        let expenses = [
            expenseSummary(amountMinorUnits: 1_000, category: .food, emotion: .stressed, at: now),
            expenseSummary(amountMinorUnits: 2_000, category: .coffee, emotion: .neutral, at: day29),
            expenseSummary(amountMinorUnits: 4_000, category: .travel, emotion: .excited, at: day30),
        ]
        let cycle = DateInterval(
            start: try #require(calendar.date(byAdding: .day, value: -10, to: today)),
            end: try #require(calendar.date(byAdding: .day, value: 20, to: today))
        )

        let result = try InsightSummaryBuilder().build(
            expenses: expenses,
            cycle: cycle,
            currencyCode: "USD",
            now: now,
            calendar: calendar
        )

        #expect(result.lastThirtyDaysTotal.minorUnits == 3_000)
        #expect(result.lastThirtyDaysCount == 2)
        #expect(result.categoryTotals.map(\.id) == [ExpenseCategory.coffee.rawValue, ExpenseCategory.food.rawValue])
        #expect(result.emotionTotals.count == 2)
        #expect(result.dailyTotals.count == 30)
        #expect(result.dailyTotals.first?.date == day29)
        #expect(result.dailyTotals.last?.date == today)
        #expect(result.currentCycleTotal.minorUnits == 1_000)
    }

    @Test
    func insightsReloadShowsAnExpenseSavedAfterTheInitialEmptyLoad() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await actor.createBudgetPlan(try budgetPlan())
        let viewModel = InsightsViewModel()

        await loadInsights(viewModel, dataActor: actor)
        #expect(viewModel.summary?.lastThirtyDaysTotal.minorUnits == 0)
        #expect(viewModel.summary?.lastThirtyDaysCount == 0)

        _ = try await actor.createExpense(expenseDraft())
        await loadInsights(viewModel, dataActor: actor)

        #expect(viewModel.summary?.lastThirtyDaysTotal.minorUnits == 1_250)
        #expect(viewModel.summary?.lastThirtyDaysCount == 1)
        #expect(viewModel.summary?.currentCycleTotal.minorUnits == 1_250)
        #expect(viewModel.summary?.categoryTotals.first?.id == ExpenseCategory.food.rawValue)
        #expect(viewModel.failed == false)
    }

    @Test
    func insightsLoadShowsAuthoritativeCrossCycleSavingsProgress() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let plan = try budgetPlan()
        _ = try await actor.createBudgetPlan(plan)
        _ = try await actor.createIncome(
            incomeDraft(
                amountMinorUnits: 80_000,
                allocatedToBudgetMinorUnits: 0,
                allocatedToSavingsMinorUnits: 25_000
            )
        )
        _ = try await actor.saveSavingsGoal(
            SavingsGoalDraft(
                id: UUID(),
                target: Money(minorUnits: 500_000, currencyCode: "USD"),
                startingBalance: Money(minorUnits: 100_000, currencyCode: "USD"),
                createdAt: TestFixtures.now,
                updatedAt: TestFixtures.now
            )
        )
        let viewModel = InsightsViewModel()

        await loadInsights(viewModel, dataActor: actor)

        let goal = try #require(viewModel.savingsGoal)
        #expect(goal.target.minorUnits == 500_000)
        #expect(goal.savedTotal.minorUnits == 125_000)
        #expect(goal.remaining.minorUnits == 375_000)
        #expect(goal.completionBasisPoints == 2_500)
        #expect(goal.completionPercent == 25)
        #expect(viewModel.savingsGoalUnavailable == false)
    }

    @Test
    func invalidCoolingProjectionStopsDerivedInsightsWithoutHidingExpenseFacts() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let plan = try budgetPlan()
        _ = try await controller.dataActor.createBudgetPlan(plan)
        _ = try await controller.dataActor.createExpense(expenseDraft())
        _ = try await controller.dataActor.upsertSpendingInsights(
            [
                InsightDraft(
                    type: .coolingOffSuccess,
                    severity: .info,
                    dedupeKey: "stale-cooling-off-success",
                    payload: ["count": .integer(1)],
                    throttleMetadata: ReminderThrottleMetadata(
                        scopeKey: "coolingOffSuccess:global",
                        categoryRiskBasisPoints: nil
                    ),
                    relatedCategory: nil,
                    relatedEmotionTag: nil,
                    periodStart: plan.cycleStart,
                    periodEnd: plan.cycleEnd
                )
            ],
            createdAt: TestFixtures.now
        )
        try await Phase11ModelSeeder(modelContainer: controller.container)
            .insertInvalidCoolingOffPlan()
        let viewModel = InsightsViewModel()

        await loadInsights(viewModel, dataActor: controller.dataActor)

        #expect(viewModel.summary?.lastThirtyDaysTotal.minorUnits == 1_250)
        #expect(viewModel.summary?.lastThirtyDaysCount == 1)
        #expect(viewModel.summary?.currentCycleTotal.minorUnits == 1_250)
        #expect(viewModel.failed)
        #expect(viewModel.partialDataUnavailable)
        #expect(viewModel.cycleNarrative == nil)
        #expect(viewModel.insights.isEmpty)
    }

    @Test
    func unifiedCSVExportsIncomeExactlyAndNeutralizesSpreadsheetFormulas() throws {
        let income = IncomeExportRecord(
            id: UUID(),
            amount: Money(minorUnits: 123_456, currencyCode: "USD"),
            category: .bonus,
            sourceName: "=WEBSERVICE(\"https://example.invalid\")",
            note: "  +1+1",
            allocatedToBudgetMinorUnits: 20_000,
            allocatedToSavingsMinorUnits: 30_000,
            receivedAt: TestFixtures.now,
            receivedTimeZoneIdentifier: "UTC",
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now
        )

        let result = CSVExporter().export(expenses: [], incomes: [income])
        let row = try #require(parseCSV(result.data).last)

        #expect(result.rowCount == 1)
        #expect(row[0] == "income")
        #expect(row[4] == "1234.56")
        #expect(row[5] == "123456")
        #expect(row[7] == IncomeCategory.bonus.rawValue)
        #expect(row[8].isEmpty)
        #expect(row[9].hasPrefix("'="))
        #expect(row[10].hasPrefix("'  +"))
        #expect(row[14].isEmpty)
        #expect(row[15].isEmpty)
        #expect(row[16].isEmpty)
        #expect(row[17].isEmpty)
        #expect(row[20] == "20000")
        #expect(row[21] == "30000")
    }

    @Test
    func deletingAllUserDataIncludesIncomeRecords() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await actor.createIncome(incomeDraft())
        #expect(try await actor.modelCounts().incomes == 1)

        try await actor.deleteAllUserData()

        #expect(try await actor.modelCounts().isEmpty)
    }

    @Test
    func schemaV2IncomeMigratesToV3WithNoInventedAllocation() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudgetV2Migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("MindBudget.store")
        let incomeID = UUID()

        do {
            let schema = Schema(versionedSchema: SchemaV2.self)
            let configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(
                Income(
                    id: incomeID,
                    amountMinorUnits: 88_800,
                    currencyCode: "USD",
                    categoryRaw: IncomeCategory.freelance.rawValue,
                    sourceName: "Existing client",
                    note: "V2 private note",
                    receivedAt: TestFixtures.now,
                    receivedTimeZoneIdentifier: "UTC",
                    createdAt: TestFixtures.now,
                    updatedAt: TestFixtures.now
                )
            )
            try context.save()
        }

        let actor = try DataController(storeURL: storeURL).dataActor
        let migrated = try #require(try await actor.fetchIncomeSummaries().first)

        #expect(migrated.id == incomeID)
        #expect(migrated.amount.minorUnits == 88_800)
        #expect(migrated.allocatedToBudgetMinorUnits == 0)
        #expect(migrated.allocatedToSavingsMinorUnits == 0)
        #expect(try await actor.modelCounts().incomeAllocations == 0)
    }

    @Test
    func incomeAllocationMustBeExplicitAndCannotExceedTheIncome() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let invalid = incomeDraft(
            amountMinorUnits: 10_000,
            allocatedToBudgetMinorUnits: 8_000,
            allocatedToSavingsMinorUnits: 2_001
        )

        await #expect(throws: DataValidationError.invalidIncomeAllocation) {
            _ = try await actor.createIncome(invalid)
        }
        #expect(try await actor.fetchIncomeSummaries().isEmpty)
        #expect(try await actor.modelCounts().incomeAllocations == 0)
    }

    @Test
    func onlyTheConfirmedIncomeAllocationChangesTheCurrentBudget() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let plan = try budgetPlan()
        _ = try await actor.createBudgetPlan(plan)
        let income = incomeDraft(
            amountMinorUnits: 100_000,
            budgetPlanID: plan.id,
            allocatedToBudgetMinorUnits: 25_000,
            allocatedToSavingsMinorUnits: 30_000
        )
        _ = try await actor.createIncome(income)

        var planSummary = try #require(try await actor.fetchBudgetPlanSummaries().first)
        #expect(planSummary.recordedIncomeMinorUnits == 100_000)
        #expect(planSummary.allocatedIncomeMinorUnits == 25_000)
        #expect(planSummary.allocatedSavingsMinorUnits == 30_000)
        let cycle = DateInterval(start: plan.cycleStart, end: plan.cycleEnd)
        let snapshot = try BudgetEngine().snapshot(
            cycle: cycle,
            currencyCode: "USD",
            expenses: [],
            plan: planSummary,
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )
        guard case let .configured(configured) = snapshot else {
            Issue.record("Expected a configured snapshot")
            return
        }
        #expect(configured.totalBudget.minorUnits == plan.totalBudgetMinorUnits + 25_000)
        #expect(configured.freeBudget.minorUnits == 145_000)

        _ = try await actor.updateIncome(
            id: income.id,
            with: incomeDraft(
                id: income.id,
                amountMinorUnits: 100_000,
                allocatedToBudgetMinorUnits: 0,
                allocatedToSavingsMinorUnits: 40_000,
                createdAt: income.createdAt,
                updatedAt: income.updatedAt.addingTimeInterval(60)
            )
        )
        planSummary = try #require(try await actor.fetchBudgetPlanSummaries().first)
        #expect(planSummary.allocatedIncomeMinorUnits == 0)
        #expect(planSummary.allocatedSavingsMinorUnits == 40_000)
    }

    @Test
    func totalSavingsGoalProgressIsCrossCycleAndSeparateFromCycleReservation() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let plan = try budgetPlan()
        _ = try await actor.createBudgetPlan(plan)
        _ = try await actor.createIncome(
            incomeDraft(
                amountMinorUnits: 80_000,
                budgetPlanID: plan.id,
                allocatedToBudgetMinorUnits: 10_000,
                allocatedToSavingsMinorUnits: 25_000
            )
        )
        let draft = SavingsGoalDraft(
            id: UUID(),
            target: Money(minorUnits: 500_000, currencyCode: "USD"),
            startingBalance: Money(minorUnits: 100_000, currencyCode: "USD"),
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now
        )

        let goal = try await actor.saveSavingsGoal(draft)
        let storedPlan = try #require(try await actor.fetchBudgetPlanSummaries().first)

        #expect(goal.savedTotal.minorUnits == 125_000)
        #expect(goal.remaining.minorUnits == 375_000)
        #expect(goal.completionBasisPoints == 2_500)
        #expect(goal.completionPercent == 25)
        #expect(storedPlan.savingGoalMinorUnits == plan.savingGoalMinorUnits)
        #expect(storedPlan.allocatedSavingsMinorUnits == 25_000)
    }

    @Test
    func budgetAllocationRejectsAnIncomeDateOutsideItsExplicitTargetCycle() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let plan = try budgetPlan()
        _ = try await actor.createBudgetPlan(plan)
        let historicalDate = try #require(
            TestFixtures.utcCalendar.date(byAdding: .day, value: -1, to: plan.cycleStart)
        )

        await #expect(throws: DataValidationError.invalidIncomeAllocation) {
            _ = try await actor.createIncome(
                incomeDraft(
                    budgetPlanID: plan.id,
                    allocatedToBudgetMinorUnits: 10_000,
                    receivedAt: historicalDate
                )
            )
        }

        #expect(try await actor.fetchIncomeSummaries().isEmpty)
        #expect(try await actor.fetchBudgetPlanSummaries().first?.allocatedIncomeMinorUnits == 0)
    }

    @Test
    func budgetAllocationRequiresAnExistingExplicitTargetCycle() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor

        await #expect(throws: DataValidationError.invalidIncomeAllocation) {
            _ = try await actor.createIncome(
                incomeDraft(
                    budgetPlanID: nil,
                    allocatedToBudgetMinorUnits: 10_000
                )
            )
        }

        #expect(try await actor.fetchIncomeSummaries().isEmpty)
        #expect(try await actor.modelCounts().incomeAllocations == 0)
    }

    @Test
    func recurringFixedExpenseClampsShortMonthsAndReconciliationIsIdempotent() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.shanghaiCalendar
        let anchor = try date(2026, 1, 31, 9, 30, calendar: calendar)
        let recurring = expenseDraft(
            amountMinorUnits: 9_900,
            category: .rent,
            at: anchor,
            createdAt: anchor,
            isRecurring: true,
            timeZoneIdentifier: calendar.timeZone.identifier
        )
        _ = try await actor.createExpense(recurring)
        let through = try date(2026, 4, 30, 23, 0, calendar: calendar)

        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: through,
                calendar: calendar
            ) == RecurringExpenseReconciliationResult(insertedCount: 3, hasMore: false)
        )
        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: through,
                calendar: calendar
            ) == .empty
        )
        let expenses = try await actor.fetchExpenseSummaries().sorted { $0.spentAt < $1.spentAt }
        let dates = expenses.map { calendar.dateComponents([.month, .day], from: $0.spentAt) }

        #expect(expenses.count == 4)
        #expect(dates.map(\.month) == [1, 2, 3, 4])
        #expect(dates.map(\.day) == [31, 28, 31, 30])
        #expect(expenses.dropFirst().allSatisfy { $0.bucket == .fixed && $0.isRecurring })
        #expect(try await actor.modelCounts().recurringOccurrences == 3)
        #expect(
            try await actor.fetchRecurringFixedExpenseRuleSummaries().first?
                .calendarIdentifierRaw == calendar.identifier.mindBudgetPersistedValue
        )

        let generated = expenses[1]
        _ = try await actor.updateExpense(
            id: generated.id,
            with: ExpenseDraft(
                id: generated.id,
                amount: Money(minorUnits: 10_100, currencyCode: "USD"),
                category: generated.category,
                bucket: .fixed,
                merchantName: generated.merchantName,
                note: nil,
                spentAt: generated.spentAt,
                spentTimeZoneIdentifier: generated.spentTimeZoneIdentifier,
                createdAt: generated.createdAt,
                updatedAt: through,
                paymentMethod: generated.paymentMethod,
                emotionTag: generated.emotionTag,
                purchaseReason: generated.purchaseReason,
                isPlanned: generated.isPlanned,
                isRecurring: true,
                source: generated.source,
                allowMerchantIndexing: generated.allowMerchantIndexing
            )
        )
        #expect(try await actor.fetchRecurringFixedExpenseRuleSummaries().count == 1)
        let rule = try #require(
            try await actor.fetchRecurringFixedExpenseRuleSummaries().first
        )
        try await actor.deleteRecurringFixedExpenseRule(id: rule.id)
        #expect(try await actor.fetchRecurringFixedExpenseRuleSummaries().isEmpty)
        #expect(try await actor.fetchExpenseSummaries().count == 4)
    }

    @Test
    func recurringDay31ClampsToFebruary29InALeapYearWithoutDuplication() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.shanghaiCalendar
        let anchor = try date(2028, 1, 31, 9, 30, calendar: calendar)
        _ = try await actor.createExpense(
            expenseDraft(
                amountMinorUnits: 9_900,
                category: .rent,
                at: anchor,
                createdAt: anchor,
                isRecurring: true,
                timeZoneIdentifier: calendar.timeZone.identifier
            )
        )
        let through = try date(2028, 2, 29, 23, 0, calendar: calendar)

        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: through,
                calendar: calendar
            ) == RecurringExpenseReconciliationResult(insertedCount: 1, hasMore: false)
        )
        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: through,
                calendar: calendar
            ) == .empty
        )
        let expenses = try await actor.fetchExpenseSummaries().sorted { $0.spentAt < $1.spentAt }
        let generated = try #require(expenses.last)

        #expect(expenses.count == 2)
        #expect(calendar.component(.year, from: generated.spentAt) == 2028)
        #expect(calendar.component(.month, from: generated.spentAt) == 2)
        #expect(calendar.component(.day, from: generated.spentAt) == 29)
        #expect(try await actor.modelCounts().recurringOccurrences == 1)
    }

    @Test
    func pausedRecurringMonthsAreNotBackfilledAfterResume() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.utcCalendar
        let anchor = try date(2026, 1, 15, 8, 0, calendar: calendar)
        _ = try await actor.createExpense(
            expenseDraft(at: anchor, createdAt: anchor, isRecurring: true)
        )
        let rule = try #require(
            try await actor.fetchRecurringFixedExpenseRuleSummaries().first
        )
        let februaryEnd = try date(2026, 2, 28, 23, 0, calendar: calendar)
        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: februaryEnd,
                calendar: calendar
            ).insertedCount == 1
        )

        let pausedAt = try date(2026, 3, 1, 9, 0, calendar: calendar)
        _ = try await actor.setRecurringFixedExpenseRuleActive(
            id: rule.id,
            isActive: false,
            at: pausedAt
        )
        let aprilEnd = try date(2026, 4, 30, 23, 0, calendar: calendar)
        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: aprilEnd,
                calendar: calendar
            ) == .empty
        )

        _ = try await actor.setRecurringFixedExpenseRuleActive(
            id: rule.id,
            isActive: true,
            at: aprilEnd
        )
        let mayEnd = try date(2026, 5, 31, 23, 0, calendar: calendar)
        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: mayEnd,
                calendar: calendar
            ).insertedCount == 1
        )
        let months = try await actor.fetchExpenseSummaries().map {
            calendar.component(.month, from: $0.spentAt)
        }.sorted()
        #expect(months == [1, 2, 5])
    }

    @Test
    func singleRuleCatchUpContinuesInBoundedBatches() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.utcCalendar
        let anchor = try date(2026, 1, 1, 8, 0, calendar: calendar)
        _ = try await actor.createExpense(
            expenseDraft(at: anchor, createdAt: anchor, isRecurring: true)
        )
        let farFuture = try date(2036, 3, 1, 8, 0, calendar: calendar)

        let firstBatch = try await actor.reconcileRecurringFixedExpenses(
            through: farFuture,
            calendar: calendar
        )
        #expect(firstBatch.insertedCount == 120)
        #expect(firstBatch.hasMore)
        #expect(try await actor.modelCounts().recurringOccurrences == 120)

        let secondBatch = try await actor.reconcileRecurringFixedExpenses(
            through: farFuture,
            calendar: calendar
        )
        #expect(secondBatch.insertedCount == 2)
        #expect(!secondBatch.hasMore)
        #expect(try await actor.fetchExpenseSummaries().count == 123)
        #expect(try await actor.modelCounts().recurringOccurrences == 122)
        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: farFuture,
                calendar: calendar
            ) == .empty
        )
    }

    @Test
    func appSessionTreatsARemainingRecurringBacklogAsProgressNotFailure() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.utcCalendar
        let anchor = try date(2026, 1, 1, 8, 0, calendar: calendar)
        _ = try await actor.createExpense(
            expenseDraft(at: anchor, createdAt: anchor, isRecurring: true)
        )
        let through = try date(2036, 3, 1, 8, 0, calendar: calendar)
        let session = AppSession(dataActor: actor)

        let firstBatch = await session.reconcileRecurringExpenses(
            calendar: calendar,
            now: through
        )

        #expect(firstBatch.insertedCount == 120)
        #expect(firstBatch.hasMore)
        #expect(session.recurringExpenseReconciliationHasMore)
        #expect(!session.recurringExpenseReconciliationFailed)

        let secondBatch = await session.reconcileRecurringExpenses(
            calendar: calendar,
            now: through
        )
        #expect(secondBatch.insertedCount == 2)
        #expect(!secondBatch.hasMore)
        #expect(!session.recurringExpenseReconciliationHasMore)
        #expect(!session.recurringExpenseReconciliationFailed)
    }

    @Test
    func recurringScheduleFailsClosedAfterItsBoundedMonthScan() throws {
        let schedule = MonthlyRecurringSchedule()
        let calendar = TestFixtures.utcCalendar
        let ruleID = UUID()
        let anchor = try date(2026, 1, 1, 8, 0, calendar: calendar)
        var existingKeys: Set<String> = []
        for offset in 1..<MonthlyRecurringSchedule.maximumScannedMonths {
            let scheduledAt = try #require(
                calendar.date(byAdding: .month, value: offset, to: anchor)
            )
            existingKeys.insert(
                try schedule.occurrenceKey(
                    ruleID: ruleID,
                    scheduledAt: scheduledAt,
                    timeZoneIdentifier: "UTC",
                    calendarIdentifierRaw: Calendar.Identifier.gregorian.mindBudgetPersistedValue,
                    calendar: calendar
                )
            )
        }
        let distantEnd = try #require(
            calendar.date(
                byAdding: .month,
                value: MonthlyRecurringSchedule.maximumScannedMonths + 12,
                to: anchor
            )
        )

        #expect(throws: DataValidationError.invalidRecurringExpenseRule) {
            _ = try schedule.pendingDates(
                ruleID: ruleID,
                anchorDate: anchor,
                initialOccurrenceAt: anchor,
                activatedAt: anchor,
                through: distantEnd,
                timeZoneIdentifier: "UTC",
                calendarIdentifierRaw: Calendar.Identifier.gregorian.mindBudgetPersistedValue,
                calendar: calendar,
                existingOccurrenceKeys: existingKeys
            )
        }
    }

    @Test
    func catchUpLimitAppliesAcrossAllRulesAndResumesOldestFirst() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.utcCalendar
        let firstAnchor = try date(2026, 1, 1, 8, 0, calendar: calendar)
        let secondAnchor = try date(2026, 1, 2, 8, 0, calendar: calendar)
        _ = try await actor.createExpense(
            expenseDraft(at: firstAnchor, createdAt: firstAnchor, isRecurring: true)
        )
        _ = try await actor.createExpense(
            expenseDraft(at: secondAnchor, createdAt: secondAnchor, isRecurring: true)
        )
        let through = try date(2031, 2, 28, 23, 0, calendar: calendar)

        let firstBatch = try await actor.reconcileRecurringFixedExpenses(
            through: through,
            calendar: calendar
        )
        #expect(firstBatch.insertedCount == 120)
        #expect(firstBatch.hasMore)
        #expect(try await actor.modelCounts().recurringOccurrences == 120)
        let firstBatchExpenses = try await actor.fetchExpenseSummaries()
        let finalPendingMonth = try date(2031, 2, 1, 0, 0, calendar: calendar)
        #expect(firstBatchExpenses.allSatisfy { $0.spentAt < finalPendingMonth })

        let secondBatch = try await actor.reconcileRecurringFixedExpenses(
            through: through,
            calendar: calendar
        )
        #expect(secondBatch.insertedCount == 2)
        #expect(!secondBatch.hasMore)
        #expect(try await actor.fetchExpenseSummaries().count == 124)
        #expect(try await actor.modelCounts().recurringOccurrences == 122)
    }

    @Test
    func movingARecurringAnchorIntoANewMonthGeneratesThatMonthsOccurrence() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.utcCalendar
        let januaryAnchor = try date(2026, 1, 15, 8, 0, calendar: calendar)
        _ = try await actor.createExpense(
            expenseDraft(at: januaryAnchor, createdAt: januaryAnchor, isRecurring: true)
        )
        let rule = try #require(
            try await actor.fetchRecurringFixedExpenseRuleSummaries().first
        )
        let editedAt = try date(2026, 2, 1, 8, 0, calendar: calendar)
        let februaryAnchor = try date(2026, 2, 25, 8, 0, calendar: calendar)
        _ = try await actor.updateRecurringFixedExpenseRule(
            RecurringFixedExpenseRuleDraft(
                id: rule.id,
                originExpenseID: rule.originExpenseID,
                amount: rule.amount,
                category: rule.category,
                merchantName: rule.merchantName,
                note: nil,
                initialOccurrenceAt: rule.initialOccurrenceAt,
                anchorDate: februaryAnchor,
                timeZoneIdentifier: rule.timeZoneIdentifier,
                calendarIdentifierRaw: rule.calendarIdentifierRaw,
                isActive: true,
                activeSince: rule.activeSince,
                createdAt: rule.createdAt,
                updatedAt: editedAt
            )
        )

        let through = try date(2026, 2, 26, 8, 0, calendar: calendar)
        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: through,
                calendar: calendar
            ).insertedCount == 1
        )
        let generated = try #require(
            try await actor.fetchExpenseSummaries().first { $0.id != rule.originExpenseID }
        )
        #expect(calendar.component(.month, from: generated.spentAt) == 2)
        #expect(calendar.component(.day, from: generated.spentAt) == 25)
    }

    @Test
    func recurringRuleWithAFutureAnchorDoesNotBreakForegroundReconciliation() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.utcCalendar
        let futureAnchor = try date(2027, 1, 15, 8, 0, calendar: calendar)
        _ = try await actor.createExpense(
            expenseDraft(
                at: futureAnchor,
                createdAt: TestFixtures.now,
                isRecurring: true,
                calendarIdentifier: calendar.identifier
            )
        )

        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: TestFixtures.now,
                calendar: calendar
            ) == .empty
        )
        #expect(try await actor.modelCounts().recurringOccurrences == 0)
    }

    @Test
    func resumingAfterMoreThanTheCatchUpLimitStartsFromTheResumeMonth() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let calendar = TestFixtures.utcCalendar
        let anchor = try date(2026, 1, 15, 8, 0, calendar: calendar)
        _ = try await actor.createExpense(
            expenseDraft(
                at: anchor,
                createdAt: anchor,
                isRecurring: true,
                calendarIdentifier: calendar.identifier
            )
        )
        let rule = try #require(
            try await actor.fetchRecurringFixedExpenseRuleSummaries().first
        )
        _ = try await actor.setRecurringFixedExpenseRuleActive(
            id: rule.id,
            isActive: false,
            at: anchor
        )
        let resumedAt = try date(2040, 1, 20, 8, 0, calendar: calendar)
        _ = try await actor.setRecurringFixedExpenseRuleActive(
            id: rule.id,
            isActive: true,
            at: resumedAt
        )
        let februaryEnd = try date(2040, 2, 29, 23, 0, calendar: calendar)

        #expect(
            try await actor.reconcileRecurringFixedExpenses(
                through: februaryEnd,
                calendar: calendar
            ).insertedCount == 1
        )
        let generated = try await actor.fetchExpenseSummaries()
            .filter { $0.id != rule.originExpenseID }
        let date = try #require(generated.first?.spentAt)
        #expect(calendar.component(.year, from: date) == 2040)
        #expect(calendar.component(.month, from: date) == 2)
        #expect(calendar.component(.day, from: date) == 15)
    }

    @Test
    func incomeModeIgnoresPreservedExpenseOnlyFilters() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await actor.createBudgetPlan(try budgetPlan())
        _ = try await actor.createExpense(expenseDraft())
        _ = try await actor.createIncome(incomeDraft())
        let viewModel = ExpenseListViewModel()
        await viewModel.load(dataActor: actor)

        viewModel.filter.category = .food
        viewModel.filter.bucket = .discretionary
        viewModel.filter.recordType = .expense
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.filteredIncomes.isEmpty)

        viewModel.filter.recordType = .income
        #expect(viewModel.filteredExpenses.isEmpty)
        #expect(viewModel.filteredIncomes.count == 1)

        viewModel.filter.recordType = .all
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.filteredIncomes.isEmpty)

        viewModel.filter.recordType = .expense
        #expect(viewModel.filter.category == .food)
        #expect(viewModel.filter.bucket == .discretionary)
        #expect(viewModel.filteredExpenses.count == 1)
    }

    private func incomeDraft(
        id: UUID = UUID(),
        amountMinorUnits: Int64 = 250_000,
        category: IncomeCategory = .salary,
        sourceName: String? = "Employer",
        note: String? = nil,
        budgetPlanID: UUID? = nil,
        allocatedToBudgetMinorUnits: Int64 = 0,
        allocatedToSavingsMinorUnits: Int64 = 0,
        receivedAt: Date = TestFixtures.now,
        createdAt: Date = TestFixtures.now,
        updatedAt: Date = TestFixtures.now
    ) -> IncomeDraft {
        IncomeDraft(
            id: id,
            amount: Money(minorUnits: amountMinorUnits, currencyCode: "USD"),
            category: category,
            sourceName: sourceName,
            note: note,
            budgetPlanID: budgetPlanID,
            allocatedToBudgetMinorUnits: allocatedToBudgetMinorUnits,
            allocatedToSavingsMinorUnits: allocatedToSavingsMinorUnits,
            receivedAt: receivedAt,
            receivedTimeZoneIdentifier: "UTC",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func expenseDraft(
        amountMinorUnits: Int64 = 1_250,
        category: ExpenseCategory = .food,
        at date: Date = TestFixtures.now,
        createdAt: Date = TestFixtures.now,
        isRecurring: Bool = false,
        timeZoneIdentifier: String = "UTC",
        calendarIdentifier: Calendar.Identifier = .gregorian
    ) -> ExpenseDraft {
        ExpenseDraft(
            id: UUID(),
            amount: Money(minorUnits: amountMinorUnits, currencyCode: "USD"),
            category: category,
            bucket: isRecurring ? .fixed : .discretionary,
            merchantName: "Cafe",
            note: nil,
            spentAt: date,
            spentTimeZoneIdentifier: timeZoneIdentifier,
            createdAt: createdAt,
            updatedAt: createdAt,
            paymentMethod: nil,
            emotionTag: nil,
            purchaseReason: .need,
            isPlanned: false,
            isRecurring: isRecurring,
            source: .manual,
            allowMerchantIndexing: false,
            recurrenceCalendarIdentifier: calendarIdentifier
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        calendar: Calendar
    ) throws -> Date {
        try #require(
            calendar.date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: day,
                    hour: hour,
                    minute: minute
                )
            )
        )
    }

    private func budgetPlan() throws -> BudgetPlanDraft {
        let calendar = TestFixtures.utcCalendar
        return BudgetPlanDraft(
            id: UUID(),
            cycleStart: try #require(
                calendar.date(byAdding: .day, value: -1, to: TestFixtures.now)
            ),
            cycleEnd: try #require(
                calendar.date(byAdding: .day, value: 29, to: TestFixtures.now)
            ),
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 400_000,
            totalBudgetMinorUnits: 240_000,
            fixedExpensesMinorUnits: 80_000,
            savingGoalMinorUnits: 40_000,
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            categoryBudgets: []
        )
    }

    private func loadInsights(
        _ viewModel: InsightsViewModel,
        dataActor: DataActor
    ) async {
        await viewModel.load(
            dataActor: dataActor,
            currencyCode: "USD",
            cycleStartDay: 1,
            configuration: RuleConfiguration.defaults(currencyCode: "USD"),
            locale: Locale(identifier: "en_US"),
            tone: .soft,
            enhancementEnabled: false,
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )
    }

    private func wishDraft(
        name: String,
        status: WishItemStatus = .active
    ) -> WishItemDraft {
        WishItemDraft(
            id: UUID(),
            name: name,
            estimatedPrice: nil,
            currencyCode: "USD",
            category: .other,
            reason: nil,
            emotionTag: nil,
            sourceContextLabel: nil,
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            coolingOffHours: 24,
            targetReviewDate: nil,
            status: status,
            notes: nil,
            purchasedExpenseId: nil
        )
    }

    private func expenseSummary(
        amountMinorUnits: Int64,
        category: ExpenseCategory,
        emotion: EmotionTag,
        at date: Date
    ) -> ExpenseSummary {
        ExpenseSummary(
            id: UUID(),
            amount: Money(minorUnits: amountMinorUnits, currencyCode: "USD"),
            category: category,
            bucket: .discretionary,
            merchantName: nil,
            spentAt: date,
            spentTimeZoneIdentifier: "UTC",
            createdAt: date,
            updatedAt: date,
            paymentMethod: nil,
            emotionTag: emotion,
            purchaseReason: nil,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
    }

    private func parseCSV(_ data: Data) throws -> [[String]] {
        let bytes = [UInt8](data)
        let payload = bytes.starts(with: [0xEF, 0xBB, 0xBF])
            ? Data(bytes.dropFirst(3))
            : data
        let text = try #require(String(data: payload, encoding: .utf8))
            .replacingOccurrences(of: "\r\n", with: "\n")
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            let next = text.index(after: index)
            if isQuoted {
                if character == "\"" {
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = text.index(after: next)
                        continue
                    }
                    isQuoted = false
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"": isQuoted = true
                case ",":
                    row.append(field)
                    field = ""
                case "\n":
                    row.append(field)
                    rows.append(row)
                    row = []
                    field = ""
                default: field.append(character)
                }
            }
            index = next
        }
        return rows
    }
}

@ModelActor
private actor Phase11ModelSeeder {
    func insertInvalidCoolingOffPlan() throws {
        guard let reviewAt = TestFixtures.utcCalendar.date(
            byAdding: .hour,
            value: 24,
            to: TestFixtures.now
        ) else {
            throw DataValidationError.invalidCoolingOffPlan
        }
        modelContext.insert(
            CoolingOffPlan(
                id: UUID(),
                startedAt: TestFixtures.now,
                reviewAt: reviewAt,
                durationHours: 24,
                statusRaw: "futureStatus",
                notificationIdentifier: nil,
                completedAt: nil,
                outcomeRaw: nil,
                outcomeRecordedAt: nil,
                wishItem: nil
            )
        )
        try modelContext.save()
    }
}
