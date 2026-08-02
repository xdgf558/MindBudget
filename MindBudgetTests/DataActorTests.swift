import Foundation
import Testing
@testable import MindBudget

struct DataActorTests {
    @Test
    func expensePersistsWhenTheContainerIsReopened() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudgetPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("MindBudget.store")
        let expense = makeExpense()

        do {
            let controller = try DataController(storeURL: storeURL)
            _ = try await controller.makeDataActor().createExpense(expense)
        }

        do {
            let controller = try DataController(storeURL: storeURL)
            let summaries = try await controller.makeDataActor().fetchExpenseSummaries()
            #expect(summaries.count == 1)
            #expect(summaries.first?.id == expense.id)
            #expect(summaries.first?.amount.minorUnits == expense.amount.minorUnits)
        }
    }

    @Test
    func deletingWishItemCascadesToCoolingOffPlans() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let now = fixedDate
        let wish = makeWish(status: .coolingOff)
        _ = try await actor.createWishItem(wish)
        _ = try await actor.createCoolingOffPlan(
            CoolingOffPlanDraft(
                id: UUID(),
                wishItemId: wish.id,
                startedAt: now,
                reviewAt: now.addingTimeInterval(86_400),
                durationHours: 24,
                status: .active,
                notificationIdentifier: nil,
                completedAt: nil,
                outcome: nil
            )
        )

        try await actor.deleteWishItem(id: wish.id)
        let counts = try await actor.modelCounts()

        #expect(counts.wishItems == 0)
        #expect(counts.coolingOffPlans == 0)
    }

    @Test
    func deletingLinkedExpenseClearsWeakLinkWithoutChangingPurchasedStatus() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let expense = makeExpense()
        let wish = makeWish(status: .active)
        _ = try await actor.createExpense(expense)
        _ = try await actor.createWishItem(wish)
        _ = try await actor.linkPurchasedExpense(
            wishItemId: wish.id,
            expenseId: expense.id,
            at: fixedDate
        )

        try await actor.deleteExpense(id: expense.id)
        let result = try await actor.fetchWishItemSummaries().first

        #expect(result?.status == .purchased)
        #expect(result?.purchasedExpenseId == nil)
    }

    @Test
    func actorRejectsIllegalPersistedWishTransition() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let wish = makeWish(status: .purchased)
        _ = try await actor.createWishItem(wish)

        await #expect(throws: WishItemTransitionError.self) {
            _ = try await actor.transitionWishItem(id: wish.id, to: .active, at: fixedDate)
        }
    }

    @Test
    func allSampleScenariosCanBeCreatedAndRead() async throws {
        for scenario in SampleDataScenario.allCases {
            let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
            let sample = try TestFixtures.sample(scenario)
            try await actor.replaceLocalData(with: sample)
            let counts = try await actor.modelCounts()

            switch scenario {
            case .newUser:
                #expect(counts == ModelCounts(expenses: 0, budgetPlans: 0, wishItems: 0, coolingOffPlans: 0))
            case .threeMonthHistory:
                #expect(counts.expenses == 6)
                #expect(counts.budgetPlans == 3)
                #expect(counts.wishItems == 1)
                #expect(counts.coolingOffPlans == 1)
            case .endOfCycle:
                #expect(counts.expenses == 1)
                #expect(counts.budgetPlans == 1)
            case .overspent:
                #expect(counts.expenses == 2)
                #expect(counts.budgetPlans == 1)
            }
        }
    }

    @Test
    func reminderEventKeepsScopeRiskThresholdAndResponseInItsProjection() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let event = ReminderEventDraft(
            id: UUID(),
            insightType: .categoryBudgetRisk,
            scopeKey: "categoryBudgetRisk:food",
            channel: .sheet,
            shownAt: fixedDate,
            categoryRiskBasisPoints: 10_250,
            isInterrupting: true,
            response: .acted,
            respondedAt: fixedDate
        )

        _ = try await actor.createReminderEvent(event)
        let result = try await actor.fetchReminderEventSummaries().first

        #expect(result?.scopeKey == event.scopeKey)
        #expect(result?.categoryRiskBasisPoints == 10_250)
        #expect(result?.response == .acted)
    }

    private var fixedDate: Date {
        TestFixtures.now
    }

    private func makeExpense() -> ExpenseDraft {
        ExpenseDraft(
            id: UUID(),
            amount: Money(minorUnits: 1_234, currencyCode: "USD"),
            category: .food,
            bucket: .discretionary,
            merchantName: "Cafe",
            note: nil,
            spentAt: fixedDate,
            spentTimeZoneIdentifier: "UTC",
            createdAt: fixedDate,
            updatedAt: fixedDate,
            paymentMethod: .mobilePay,
            emotionTag: nil,
            purchaseReason: .need,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
    }

    private func makeWish(status: WishItemStatus) -> WishItemDraft {
        WishItemDraft(
            id: UUID(),
            name: "Headphones",
            estimatedPrice: Money(minorUnits: 18_000, currencyCode: "USD"),
            currencyCode: "USD",
            category: .electronics,
            reason: .convenience,
            emotionTag: nil,
            sourceContextLabel: nil,
            createdAt: fixedDate,
            updatedAt: fixedDate,
            coolingOffHours: 24,
            targetReviewDate: nil,
            status: status,
            notes: nil,
            purchasedExpenseId: nil
        )
    }
}
