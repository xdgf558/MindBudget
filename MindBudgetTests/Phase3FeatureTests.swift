import Foundation
import Testing
@testable import MindBudget

@MainActor
struct Phase3FeatureTests {
    @Test
    func appTabPositionsFollowTheDeclaredNavigationOrder() {
        #expect(AppTab.allCases == [.dashboard, .list, .insights, .wishlist])
        #expect(AppTab.allCases.map(\.accessibilityPosition) == [1, 2, 3, 4])
    }

    @Test
    func moneyInputParserUsesLocaleAndRejectsSilentRounding() throws {
        let parser = MoneyInputParser()

        let dollars = try parser.money(
            from: "1,234.56",
            currencyCode: "USD",
            locale: Locale(identifier: "en_US")
        )
        let euros = try parser.money(
            from: "1.234,56",
            currencyCode: "EUR",
            locale: Locale(identifier: "de_DE")
        )
        let localizedDigits = try parser.money(
            from: "١٢٫٣٤",
            currencyCode: "USD",
            locale: Locale(identifier: "ar_EG")
        )

        #expect(dollars.minorUnits == 123_456)
        #expect(euros.minorUnits == 123_456)
        #expect(localizedDigits.minorUnits == 1_234)
        #expect(throws: MoneyInputError.tooManyFractionDigits) {
            try parser.money(
                from: "12.5",
                currencyCode: "JPY",
                locale: Locale(identifier: "en_US")
            )
        }
        #expect(throws: MoneyInputError.tooManyFractionDigits) {
            try parser.money(
                from: "12.345",
                currencyCode: "USD",
                locale: Locale(identifier: "en_US")
            )
        }
        #expect(throws: MoneyInputError.nonPositive) {
            try parser.money(
                from: "0",
                currencyCode: "USD",
                locale: Locale(identifier: "en_US")
            )
        }
        #expect(throws: MoneyInputError.negative) {
            try parser.money(
                from: "-1",
                currencyCode: "USD",
                locale: Locale(identifier: "en_US")
            )
        }
        #expect(throws: MoneyInputError.invalid) {
            try parser.money(
                from: "12,34",
                currencyCode: "USD",
                locale: Locale(identifier: "en_US")
            )
        }
        #expect(throws: MoneyInputError.invalid) {
            try parser.money(
                from: "12x",
                currencyCode: "USD",
                locale: Locale(identifier: "en_US")
            )
        }
    }

    @Test
    func budgetDraftBuilderRetiresNewForecastsButPreservesTheCurrentLegacyCycle() throws {
        let cycle = DateInterval(
            start: TestFixtures.now,
            end: TestFixtures.now.addingTimeInterval(86_400 * 14)
        )

        let draft = try BudgetPlanDraftBuilder().makeDraft(
            currencyCode: "USD",
            cycle: cycle,
            monthlyIncomeText: "2,000.00",
            totalBudgetText: "1,500.00",
            savingGoalText: "250.00",
            locale: Locale(identifier: "en_US"),
            timestamp: TestFixtures.now
        )

        #expect(draft.monthlyIncomeMinorUnits == 200_000)
        #expect(draft.totalBudgetMinorUnits == 150_000)
        #expect(draft.fixedExpensesMinorUnits == 0)
        #expect(draft.savingGoalMinorUnits == 25_000)
        #expect(draft.cycleStart == cycle.start)
        #expect(draft.cycleEnd == cycle.end)

        let update = try BudgetPlanDraftBuilder().makeCurrentUpdate(
            planID: draft.id,
            currencyCode: "USD",
            monthlyIncomeText: "2,100.00",
            totalBudgetText: "1,600.00",
            legacyFixedExpensesMinorUnits: 42_000,
            savingGoalText: "300.00",
            locale: Locale(identifier: "en_US"),
            referenceDate: TestFixtures.now,
            timestamp: TestFixtures.now
        )
        #expect(update.fixedExpensesMinorUnits == 42_000)
    }

    @Test
    func initialBudgetSetupDoesNotMirrorIncomeIntoSpendingBudget() {
        let viewModel = BudgetSetupViewModel(currencyCode: "CNY", cycleStartDay: 1)

        viewModel.monthlyIncomeText = "6000"
        #expect(viewModel.totalBudgetText.isEmpty)

        viewModel.totalBudgetText = "4800"
        viewModel.monthlyIncomeText = "7000"
        #expect(viewModel.totalBudgetText == "4800")
    }

    @Test
    func expenseFormShowsDismissibleContextualWarningAndExactImpact() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let now = TestFixtures.now
        _ = try await actor.createBudgetPlan(
            BudgetPlanDraft(
                id: UUID(),
                cycleStart: now.addingTimeInterval(-86_400),
                cycleEnd: now.addingTimeInterval(86_400 * 29),
                currencyCode: "USD",
                monthlyIncomeMinorUnits: 200_000,
                totalBudgetMinorUnits: 100_000,
                fixedExpensesMinorUnits: 0,
                savingGoalMinorUnits: 10_000,
                createdAt: now,
                updatedAt: now,
                categoryBudgets: []
            )
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let viewModel = ExpenseFormViewModel(existingExpense: nil, now: now)
        viewModel.updateAmountTextFromUser("1200")

        await viewModel.loadContext(
            dataActor: actor,
            currencyCode: "USD",
            cycleStartDay: 1,
            calendar: calendar,
            referenceDate: now,
            locale: Locale(identifier: "en_US")
        )

        #expect(viewModel.budgetContext == .configured)
        #expect(viewModel.inlineImpact?.remainingTotalAfter.minorUnits == 80_000)
        #expect(viewModel.inlineImpact?.willExceedTotalBudget == false)
        #expect(viewModel.showsReasonablenessWarning)

        viewModel.dismissReasonablenessWarning(
            currencyCode: "USD",
            locale: Locale(identifier: "en_US")
        )
        #expect(viewModel.showsReasonablenessWarning == false)
    }

    @Test
    func manualExpenseSaveTrimsOptionalTextAndPersistsThroughDataActor() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let viewModel = ExpenseFormViewModel(existingExpense: nil, now: TestFixtures.now)
        viewModel.updateAmountTextFromUser("12.34")
        viewModel.category = .coffee
        viewModel.updateMerchantNameFromUser("  Corner Cafe  ")
        viewModel.note = "  Morning coffee  "
        viewModel.isPlanned = true

        let saved = await viewModel.save(
            dataActor: actor,
            currencyCode: "USD",
            bucket: .discretionary,
            locale: Locale(identifier: "en_US"),
            now: TestFixtures.now,
            timeZone: TimeZone(identifier: "UTC")!,
            cycleStartDay: 1,
            calendar: Calendar(identifier: .gregorian)
        )
        let expense = try #require(try await actor.fetchExpenseSummaries().first)
        let detail = try #require(try await actor.fetchExpenseDetail(id: expense.id))

        #expect(saved)
        #expect(expense.amount.minorUnits == 1_234)
        #expect(expense.category == .coffee)
        #expect(expense.merchantName == "Corner Cafe")
        #expect(detail.note == "Morning coffee")
        #expect(expense.isPlanned)
        #expect(expense.source == .manual)
    }

    @Test
    func expenseImpactUsesTheSelectedExpenseDateBudget() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let firstStart = TestFixtures.now.addingTimeInterval(-86_400)
        let secondStart = TestFixtures.now.addingTimeInterval(86_400)
        let secondEnd = secondStart.addingTimeInterval(86_400 * 30)
        _ = try await actor.createBudgetPlan(
            budgetPlan(start: firstStart, end: secondStart, totalMinorUnits: 100_000)
        )
        _ = try await actor.createBudgetPlan(
            budgetPlan(start: secondStart, end: secondEnd, totalMinorUnits: 50_000)
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let viewModel = ExpenseFormViewModel(existingExpense: nil, now: TestFixtures.now)
        viewModel.updateAmountTextFromUser("600")

        await viewModel.loadContext(
            dataActor: actor,
            currencyCode: "USD",
            cycleStartDay: 1,
            calendar: calendar,
            referenceDate: secondStart.addingTimeInterval(60),
            locale: Locale(identifier: "en_US")
        )

        #expect(viewModel.inlineImpact?.remainingTotalAfter.minorUnits == -10_000)
        #expect(viewModel.showsReasonablenessWarning)
    }

    @Test
    func datePreviewDoesNotPersistPlansAndPendingTransitionStillAllowsRecording() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let calendar = TestFixtures.utcCalendar
        let currentCycle = try BudgetCycleCalculator().interval(
            containing: TestFixtures.now,
            startDay: 1,
            calendar: calendar
        )
        _ = try await actor.createBudgetPlan(
            budgetPlan(
                start: currentCycle.start,
                end: currentCycle.end,
                totalMinorUnits: 100_000
            )
        )
        let transitionDate = currentCycle.end.addingTimeInterval(86_400 * 10)
        let viewModel = ExpenseFormViewModel(existingExpense: nil, now: transitionDate)
        viewModel.updateAmountTextFromUser("12.34")

        await viewModel.loadContext(
            dataActor: actor,
            currencyCode: "USD",
            cycleStartDay: 15,
            calendar: calendar,
            referenceDate: transitionDate,
            locale: Locale(identifier: "en_US")
        )

        #expect(viewModel.budgetContext == .transitionPlanRequired)
        #expect(viewModel.inlineImpact == nil)
        #expect(try await actor.fetchBudgetPlanSummaries().count == 1)

        let saved = await viewModel.save(
            dataActor: actor,
            currencyCode: "USD",
            bucket: .discretionary,
            locale: Locale(identifier: "en_US"),
            now: transitionDate,
            timeZone: TimeZone(identifier: "UTC")!,
            cycleStartDay: 15,
            calendar: calendar
        )

        #expect(saved)
        #expect(viewModel.budgetContext == .transitionPlanRequired)
        #expect(try await actor.fetchBudgetPlanSummaries().count == 1)
        #expect(try await actor.fetchExpenseSummaries().count == 1)
    }

    @Test
    func expenseSavePreservesAccountingCurrencyMismatchAsActionableError() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let now = TestFixtures.now
        _ = try await actor.createBudgetPlan(
            budgetPlan(
                start: now.addingTimeInterval(-86_400),
                end: now.addingTimeInterval(86_400),
                totalMinorUnits: 100_000
            )
        )
        let viewModel = ExpenseFormViewModel(existingExpense: nil, now: now)
        viewModel.updateAmountTextFromUser("12.34")

        let saved = await viewModel.save(
            dataActor: actor,
            currencyCode: "CNY",
            bucket: .discretionary,
            locale: Locale(identifier: "en_US"),
            now: now,
            timeZone: TimeZone(identifier: "UTC")!,
            cycleStartDay: 1,
            calendar: TestFixtures.utcCalendar
        )

        #expect(saved == false)
        #expect(viewModel.error == .accountingCurrencyMismatch)
        #expect(try await actor.fetchExpenseSummaries().isEmpty)
    }

    @Test
    func appSessionRecoversTheAuthoritativeCurrencyFromAnExistingPlan() async throws {
        let suiteName = "MindBudget.Phase3SessionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = SettingsStore(defaults: defaults)
        settings.currencyCode = "CNY"
        settings.firstLaunchCompleted = true
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.createBudgetPlan(
            budgetPlan(
                start: TestFixtures.now,
                end: TestFixtures.now.addingTimeInterval(86_400),
                totalMinorUnits: 100_000
            )
        )
        let session = AppSession(dataActor: actor)

        await session.prepare(settings: settings)

        #expect(session.isPrepared)
        #expect(session.preparationFailed == false)
        #expect(settings.currencyCode == "USD")
        #expect(settings.firstLaunchCompleted)
    }

    private func budgetPlan(
        start: Date,
        end: Date,
        totalMinorUnits: Int64
    ) -> BudgetPlanDraft {
        BudgetPlanDraft(
            id: UUID(),
            cycleStart: start,
            cycleEnd: end,
            currencyCode: "USD",
            monthlyIncomeMinorUnits: totalMinorUnits,
            totalBudgetMinorUnits: totalMinorUnits,
            fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 0,
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            categoryBudgets: []
        )
    }
}
