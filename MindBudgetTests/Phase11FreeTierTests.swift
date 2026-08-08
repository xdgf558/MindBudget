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
    func invalidCoolingProjectionDoesNotHideRecordedExpenseFacts() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        _ = try await controller.dataActor.createBudgetPlan(try budgetPlan())
        _ = try await controller.dataActor.createExpense(expenseDraft())
        try await Phase11ModelSeeder(modelContainer: controller.container)
            .insertInvalidCoolingOffPlan()
        let viewModel = InsightsViewModel()

        await loadInsights(viewModel, dataActor: controller.dataActor)

        #expect(viewModel.summary?.lastThirtyDaysTotal.minorUnits == 1_250)
        #expect(viewModel.summary?.lastThirtyDaysCount == 1)
        #expect(viewModel.summary?.currentCycleTotal.minorUnits == 1_250)
        #expect(viewModel.failed)
    }

    @Test
    func unifiedCSVExportsIncomeExactlyAndNeutralizesSpreadsheetFormulas() throws {
        let income = IncomeExportRecord(
            id: UUID(),
            amount: Money(minorUnits: 123_456, currencyCode: "USD"),
            category: .bonus,
            sourceName: "=WEBSERVICE(\"https://example.invalid\")",
            note: "  +1+1",
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
        createdAt: Date = TestFixtures.now,
        updatedAt: Date = TestFixtures.now
    ) -> IncomeDraft {
        IncomeDraft(
            id: id,
            amount: Money(minorUnits: amountMinorUnits, currencyCode: "USD"),
            category: category,
            sourceName: sourceName,
            note: note,
            receivedAt: TestFixtures.now,
            receivedTimeZoneIdentifier: "UTC",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func expenseDraft() -> ExpenseDraft {
        ExpenseDraft(
            id: UUID(),
            amount: Money(minorUnits: 1_250, currencyCode: "USD"),
            category: .food,
            bucket: .discretionary,
            merchantName: "Cafe",
            note: nil,
            spentAt: TestFixtures.now,
            spentTimeZoneIdentifier: "UTC",
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            paymentMethod: nil,
            emotionTag: nil,
            purchaseReason: .need,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
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
