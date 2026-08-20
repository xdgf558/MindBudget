import Foundation
import SwiftData
import Testing
@testable import MindBudget

struct DataActorTests {
    @Test
    func dataControllerReusesOneActorInstance() throws {
        let controller = try DataController(isStoredInMemoryOnly: true)

        #expect(controller.makeDataActor() === controller.makeDataActor())
    }

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
            let inspector = ExpenseStorageInspector(modelContainer: controller.container)
            #expect(summaries.count == 1)
            #expect(summaries.first?.id == expense.id)
            #expect(summaries.first?.amount.minorUnits == expense.amount.minorUnits)
            #expect(try await inspector.normalizedMerchantName(id: expense.id) == "cafe")
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
                outcome: nil,
                outcomeRecordedAt: nil
            )
        )

        try await actor.deleteWishItem(id: wish.id)
        let counts = try await actor.modelCounts()

        #expect(counts.wishItems == 0)
        #expect(counts.coolingOffPlans == 0)
    }

    @Test
    func completedCoolingOffOutcomeAndRecordedTimeMustAppearTogether() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let wish = makeWish(status: .skipped)
        _ = try await actor.createWishItem(wish)

        for (outcome, outcomeRecordedAt) in [
            (CoolingOffOutcome.skipped, nil),
            (nil, fixedDate.addingTimeInterval(90_000))
        ] {
            await #expect(throws: DataValidationError.invalidCoolingOffPlan) {
                _ = try await actor.createCoolingOffPlan(
                    CoolingOffPlanDraft(
                        id: UUID(),
                        wishItemId: wish.id,
                        startedAt: fixedDate,
                        reviewAt: fixedDate.addingTimeInterval(86_400),
                        durationHours: 24,
                        status: .completed,
                        notificationIdentifier: nil,
                        completedAt: fixedDate.addingTimeInterval(86_400),
                        outcome: outcome,
                        outcomeRecordedAt: outcomeRecordedAt
                    )
                )
            }
        }

        #expect(try await actor.fetchCoolingOffPlanSummaries().isEmpty)
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
                #expect(counts == .zero)
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

    @Test
    func accountingCurrencyIsLockedAfterFinancialDataExists() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.createExpense(makeExpense(currencyCode: "USD"))

        await #expect(
            throws: DataValidationError.accountingCurrencyMismatch(expected: "USD", actual: "CNY")
        ) {
            _ = try await actor.createWishItem(makeWish(status: .active, currencyCode: "CNY"))
        }
    }

    @Test
    func overlappingBudgetPlansAreRejected() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let first = makeBudgetPlan(start: fixedDate, end: fixedDate.addingTimeInterval(86_400 * 30))
        let overlap = makeBudgetPlan(
            start: fixedDate.addingTimeInterval(86_400 * 15),
            end: fixedDate.addingTimeInterval(86_400 * 45)
        )
        _ = try await actor.createBudgetPlan(first)

        await #expect(throws: DataValidationError.overlappingBudgetPlan) {
            _ = try await actor.createBudgetPlan(overlap)
        }
    }

    @Test
    func overcommittedBudgetPlanRemainsValidEngineInput() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let draft = makeBudgetPlan(
            start: fixedDate,
            end: fixedDate.addingTimeInterval(86_400 * 30)
        )

        let plan = try await actor.createBudgetPlan(draft)

        #expect(plan.fixedExpensesMinorUnits + plan.savingGoalMinorUnits > plan.totalBudgetMinorUnits)
    }

    @Test
    func currentBudgetUpdatePreservesIdentityBoundariesAndCategoryBudgets() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let original = BudgetPlanDraft(
            id: UUID(),
            cycleStart: fixedDate.addingTimeInterval(-86_400),
            cycleEnd: fixedDate.addingTimeInterval(86_400 * 29),
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 300_000,
            totalBudgetMinorUnits: 200_000,
            fixedExpensesMinorUnits: 80_000,
            savingGoalMinorUnits: 20_000,
            createdAt: fixedDate.addingTimeInterval(-86_400),
            updatedAt: fixedDate.addingTimeInterval(-86_400),
            categoryBudgets: [
                CategoryBudgetDraft(
                    id: UUID(),
                    category: .food,
                    limitMinorUnits: 40_000,
                    warningThresholdBasisPoints: 8_000,
                    createdAt: fixedDate.addingTimeInterval(-86_400),
                    updatedAt: fixedDate.addingTimeInterval(-86_400)
                )
            ]
        )
        _ = try await actor.createBudgetPlan(original)
        let timestamp = fixedDate.addingTimeInterval(60)

        let updated = try await actor.updateCurrentBudgetPlan(
            CurrentBudgetPlanUpdate(
                id: original.id,
                currencyCode: "USD",
                monthlyIncomeMinorUnits: 350_000,
                totalBudgetMinorUnits: 240_000,
                fixedExpensesMinorUnits: 90_000,
                savingGoalMinorUnits: 30_000,
                referenceDate: fixedDate,
                updatedAt: timestamp
            )
        )

        #expect(try await actor.fetchBudgetPlanSummaries().count == 1)
        #expect(updated.id == original.id)
        #expect(updated.cycleStart == original.cycleStart)
        #expect(updated.cycleEnd == original.cycleEnd)
        #expect(updated.monthlyIncomeMinorUnits == 350_000)
        #expect(updated.totalBudgetMinorUnits == 240_000)
        #expect(updated.fixedExpensesMinorUnits == 90_000)
        #expect(updated.savingGoalMinorUnits == 30_000)
        #expect(updated.categoryBudgets.map(\.id) == original.categoryBudgets.map(\.id))
    }

    @Test
    func historicalBudgetUpdateIsRejectedWithoutChangingStoredAmounts() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let original = makeBudgetPlan(
            start: fixedDate.addingTimeInterval(-86_400 * 30),
            end: fixedDate
        )
        _ = try await actor.createBudgetPlan(original)

        await #expect(throws: DataValidationError.invalidBudgetCycle) {
            _ = try await actor.updateCurrentBudgetPlan(
                CurrentBudgetPlanUpdate(
                    id: original.id,
                    currencyCode: original.currencyCode,
                    monthlyIncomeMinorUnits: 999_999,
                    totalBudgetMinorUnits: 999_999,
                    fixedExpensesMinorUnits: 0,
                    savingGoalMinorUnits: 0,
                    referenceDate: fixedDate,
                    updatedAt: fixedDate
                )
            )
        }

        let stored = try #require(try await actor.fetchBudgetPlanSummaries().first)
        #expect(stored.monthlyIncomeMinorUnits == original.monthlyIncomeMinorUnits)
        #expect(stored.totalBudgetMinorUnits == original.totalBudgetMinorUnits)
    }

    @Test
    func expenseAmountBoundaryAcceptsMaximumAndRejectsOutsideRange() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let maximum = Money.maximumMinorUnits(for: "VND")

        await #expect(throws: DataValidationError.invalidAmount) {
            _ = try await actor.createExpense(
                makeExpense(amountMinorUnits: 0, currencyCode: "VND", merchantName: nil)
            )
        }
        await #expect(throws: DataValidationError.invalidAmount) {
            _ = try await actor.createExpense(
                makeExpense(amountMinorUnits: maximum + 1, currencyCode: "VND", merchantName: nil)
            )
        }
        let accepted = try await actor.createExpense(
            makeExpense(amountMinorUnits: maximum, currencyCode: "VND", merchantName: nil)
        )
        #expect(accepted.amount.minorUnits == maximum)
    }

    @Test
    func corruptedCurrencyThrowsRecoverableProjectionError() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let id = UUID()
        let seeder = CorruptedDataSeeder(modelContainer: controller.container)
        try await seeder.insertExpense(id: id, currencyCode: "ZZZ", sourceRaw: ExpenseSource.manual.rawValue)

        await #expect(
            throws: PersistedModelError.unsupportedCurrency(
                entity: "Expense",
                id: id,
                currencyCode: "ZZZ"
            )
        ) {
            _ = try await controller.makeDataActor().fetchExpenseSummaries()
        }
    }

    @Test
    func corruptedExpenseSourceIsNotSilentlyTreatedAsManual() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let id = UUID()
        let seeder = CorruptedDataSeeder(modelContainer: controller.container)
        try await seeder.insertExpense(id: id, currencyCode: "USD", sourceRaw: "futureSource")

        await #expect(
            throws: PersistedModelError.invalidRawValue(
                entity: "Expense",
                id: id,
                field: "sourceRaw",
                rawValue: "futureSource"
            )
        ) {
            _ = try await controller.makeDataActor().fetchExpenseSummaries()
        }
    }

    @Test
    func corruptedWishStatusIsNotSilentlyReactivated() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let id = UUID()
        let seeder = CorruptedDataSeeder(modelContainer: controller.container)
        try await seeder.insertWishItem(id: id, statusRaw: "futureStatus")

        await #expect(
            throws: PersistedModelError.invalidRawValue(
                entity: "WishItem",
                id: id,
                field: "statusRaw",
                rawValue: "futureStatus"
            )
        ) {
            _ = try await controller.makeDataActor().fetchWishItemSummaries()
        }
    }

    @Test
    func merchantAggregateTracksAllExpensesRegardlessOfIndexingConsent() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let firstID = UUID()
        let secondID = UUID()
        _ = try await actor.createExpense(
            makeExpense(
                id: firstID,
                amountMinorUnits: 100,
                merchantName: " Café! ",
                spentAt: fixedDate
            )
        )
        _ = try await actor.createExpense(
            makeExpense(
                id: secondID,
                amountMinorUnits: 250,
                merchantName: "CAFE",
                spentAt: fixedDate.addingTimeInterval(60),
                allowMerchantIndexing: true
            )
        )

        var merchants = try await actor.fetchMerchantSummaries()
        var merchant = try #require(merchants.first)
        #expect(merchant.normalizedName == "cafe")
        #expect(merchant.visitCount == 2)
        #expect(merchant.totalMinorUnitsAllTime == 350)

        try await actor.deleteExpense(id: secondID)
        merchants = try await actor.fetchMerchantSummaries()
        merchant = try #require(merchants.first)
        #expect(merchant.visitCount == 1)
        #expect(merchant.totalMinorUnitsAllTime == 100)

        try await actor.deleteExpense(id: firstID)
        merchants = try await actor.fetchMerchantSummaries()
        #expect(merchants.isEmpty)
    }

    @Test
    func updatingExpensePersistsEditableFieldsAndRebuildsMerchantAggregates() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let original = makeExpense(merchantName: "Cafe")
        _ = try await actor.createExpense(original)
        let updatedAt = fixedDate.addingTimeInterval(120)
        let update = ExpenseDraft(
            id: original.id,
            amount: Money(minorUnits: 4_500, currencyCode: "USD"),
            category: .transport,
            bucket: .discretionary,
            merchantName: " Metro ",
            note: "Ride home",
            spentAt: fixedDate.addingTimeInterval(60),
            spentTimeZoneIdentifier: "Asia/Singapore",
            createdAt: original.createdAt,
            updatedAt: updatedAt,
            paymentMethod: .cash,
            emotionTag: nil,
            purchaseReason: nil,
            isPlanned: true,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: true
        )

        let result = try await actor.updateExpense(id: original.id, with: update)
        let detail = try #require(try await actor.fetchExpenseDetail(id: original.id))
        let merchants = try await actor.fetchMerchantSummaries()

        #expect(result.amount.minorUnits == 4_500)
        #expect(result.category == .transport)
        #expect(result.merchantName == " Metro ")
        #expect(detail.note == "Ride home")
        #expect(detail.summary == result)
        #expect(result.updatedAt == updatedAt)
        #expect(result.paymentMethod == .cash)
        #expect(result.isPlanned)
        #expect(result.allowMerchantIndexing)
        #expect(merchants.count == 1)
        #expect(merchants.first?.normalizedName == "metro")
        #expect(merchants.first?.totalMinorUnitsAllTime == 4_500)
    }

    @Test
    func rawExpenseNoteStaysBehindTheDetailAndActorSearchBoundary() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let draft = ExpenseDraft(
            id: UUID(),
            amount: Money(minorUnits: 1_234, currencyCode: "USD"),
            category: .coffee,
            bucket: .discretionary,
            merchantName: "Corner Cafe",
            note: "Private train reminder",
            spentAt: fixedDate,
            spentTimeZoneIdentifier: "UTC",
            createdAt: fixedDate,
            updatedAt: fixedDate,
            paymentMethod: nil,
            emotionTag: nil,
            purchaseReason: nil,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
        _ = try await actor.createExpense(draft)

        let summaries = try await actor.fetchExpenseSummaries()
        let detail = try #require(try await actor.fetchExpenseDetail(id: draft.id))
        let matchingIDs = try await actor.fetchExpenseIDsWithNotes(matching: "train")
        let nonmatchingIDs = try await actor.fetchExpenseIDsWithNotes(matching: "flight")

        #expect(summaries.map(\.id) == [draft.id])
        #expect(detail.summary == summaries.first)
        #expect(detail.note == "Private train reminder")
        #expect(matchingIDs == Set([draft.id]))
        #expect(nonmatchingIDs.isEmpty)
    }

    @Test
    func budgetTransitionAndFirstRegularPlanCommitAtomically() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let precedingEnd = fixedDate.addingTimeInterval(86_400 * 30)
        let transitionEnd = precedingEnd.addingTimeInterval(86_400 * 14)
        let regularEnd = transitionEnd.addingTimeInterval(86_400 * 30)
        _ = try await actor.createBudgetPlan(
            makeBudgetPlan(start: fixedDate, end: precedingEnd, totalBudgetMinorUnits: 120_000)
        )
        let transition = makeBudgetPlan(
            start: precedingEnd,
            end: transitionEnd,
            totalBudgetMinorUnits: 21_000
        )
        let firstRegular = makeBudgetPlan(
            start: transitionEnd,
            end: regularEnd,
            totalBudgetMinorUnits: 210_000
        )

        let inserted = try await actor.createBudgetPlanTransition(
            transition: transition,
            firstRegular: firstRegular
        )
        let plans = try await actor.fetchBudgetPlanSummaries()

        #expect(inserted.map(\.totalBudgetMinorUnits) == [21_000, 210_000])
        #expect(plans.count == 3)
        #expect(plans[1].id == transition.id)
        #expect(plans[2].id == firstRegular.id)
    }

    @Test
    func invalidBudgetTransitionDoesNotPartiallyInsertItsFirstPlan() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let precedingEnd = fixedDate.addingTimeInterval(86_400 * 30)
        let transitionEnd = precedingEnd.addingTimeInterval(86_400 * 14)
        _ = try await actor.createBudgetPlan(
            makeBudgetPlan(start: fixedDate, end: precedingEnd)
        )
        let transition = makeBudgetPlan(start: precedingEnd, end: transitionEnd)
        let disconnectedRegular = makeBudgetPlan(
            start: transitionEnd.addingTimeInterval(60),
            end: transitionEnd.addingTimeInterval(86_400 * 30)
        )

        await #expect(throws: DataValidationError.invalidBudgetTransition) {
            _ = try await actor.createBudgetPlanTransition(
                transition: transition,
                firstRegular: disconnectedRegular
            )
        }
        #expect(try await actor.fetchBudgetPlanSummaries().count == 1)
    }

    @Test
    func budgetTransitionRejectsCurrencyAndIdentityConflictsAtomically() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let precedingEnd = fixedDate.addingTimeInterval(86_400 * 30)
        let transitionEnd = precedingEnd.addingTimeInterval(86_400 * 14)
        let regularEnd = transitionEnd.addingTimeInterval(86_400 * 30)
        let preceding = makeBudgetPlan(start: fixedDate, end: precedingEnd)
        _ = try await actor.createBudgetPlan(preceding)

        await #expect(
            throws: DataValidationError.accountingCurrencyMismatch(
                expected: "USD",
                actual: "CNY"
            )
        ) {
            _ = try await actor.createBudgetPlanTransition(
                transition: makeBudgetPlan(
                    start: precedingEnd,
                    end: transitionEnd,
                    currencyCode: "CNY"
                ),
                firstRegular: makeBudgetPlan(
                    start: transitionEnd,
                    end: regularEnd,
                    currencyCode: "CNY"
                )
            )
        }
        await #expect(throws: DataValidationError.identityMismatch) {
            _ = try await actor.createBudgetPlanTransition(
                transition: makeBudgetPlan(
                    id: preceding.id,
                    start: precedingEnd,
                    end: transitionEnd
                ),
                firstRegular: makeBudgetPlan(start: transitionEnd, end: regularEnd)
            )
        }
        #expect(try await actor.fetchBudgetPlanSummaries().map(\.id) == [preceding.id])
    }

    @Test
    func sampleReplacementRollsBackWhenAnyInsertFails() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let original = makeExpense()
        _ = try await actor.createExpense(original)
        let invalidSample = SampleDataBundle(
            expenses: [],
            budgetPlans: [],
            wishItems: [],
            coolingOffPlans: [
                CoolingOffPlanDraft(
                    id: UUID(),
                    wishItemId: UUID(),
                    startedAt: fixedDate,
                    reviewAt: fixedDate.addingTimeInterval(86_400),
                    durationHours: 24,
                    status: .active,
                    notificationIdentifier: nil,
                    completedAt: nil,
                    outcome: nil,
                    outcomeRecordedAt: nil
                )
            ]
        )

        await #expect(throws: DataValidationError.modelNotFound) {
            try await actor.replaceLocalData(with: invalidSample)
        }
        let remaining = try await actor.fetchExpenseSummaries()
        #expect(remaining.map(\.id) == [original.id])
    }

    private var fixedDate: Date {
        TestFixtures.now
    }

    private func makeExpense(
        id: UUID = UUID(),
        amountMinorUnits: Int64 = 1_234,
        currencyCode: String = "USD",
        merchantName: String? = "Cafe",
        spentAt: Date? = nil,
        allowMerchantIndexing: Bool = false
    ) -> ExpenseDraft {
        ExpenseDraft(
            id: id,
            amount: Money(minorUnits: amountMinorUnits, currencyCode: currencyCode),
            category: .food,
            bucket: .discretionary,
            merchantName: merchantName,
            note: nil,
            spentAt: spentAt ?? fixedDate,
            spentTimeZoneIdentifier: "UTC",
            createdAt: fixedDate,
            updatedAt: fixedDate,
            paymentMethod: .mobilePay,
            emotionTag: nil,
            purchaseReason: .need,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: allowMerchantIndexing
        )
    }

    private func makeWish(status: WishItemStatus, currencyCode: String = "USD") -> WishItemDraft {
        WishItemDraft(
            id: UUID(),
            name: "Headphones",
            estimatedPrice: Money(minorUnits: 18_000, currencyCode: currencyCode),
            currencyCode: currencyCode,
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

    private func makeBudgetPlan(
        id: UUID = UUID(),
        start: Date,
        end: Date,
        currencyCode: String = "USD",
        totalBudgetMinorUnits: Int64 = 120_000
    ) -> BudgetPlanDraft {
        BudgetPlanDraft(
            id: id,
            cycleStart: start,
            cycleEnd: end,
            currencyCode: currencyCode,
            monthlyIncomeMinorUnits: 100_000,
            totalBudgetMinorUnits: totalBudgetMinorUnits,
            fixedExpensesMinorUnits: 80_000,
            savingGoalMinorUnits: 50_000,
            createdAt: fixedDate,
            updatedAt: fixedDate,
            categoryBudgets: []
        )
    }
}

@ModelActor
private actor CorruptedDataSeeder {
    func insertExpense(id: UUID, currencyCode: String, sourceRaw: String) throws {
        modelContext.insert(
            Expense(
                id: id,
                amountMinorUnits: 100,
                currencyCode: currencyCode,
                categoryRaw: ExpenseCategory.food.rawValue,
                bucketRaw: BudgetBucket.discretionary.rawValue,
                merchantName: nil,
                normalizedMerchantName: nil,
                note: nil,
                spentAt: TestFixtures.now,
                spentTimeZoneIdentifier: "UTC",
                createdAt: TestFixtures.now,
                updatedAt: TestFixtures.now,
                paymentMethodRaw: nil,
                emotionTagRaw: nil,
                purchaseReasonRaw: nil,
                isPlanned: false,
                isRecurring: false,
                sourceRaw: sourceRaw,
                allowMerchantIndexing: false
            )
        )
        try modelContext.save()
    }

    func insertWishItem(id: UUID, statusRaw: String) throws {
        modelContext.insert(
            WishItem(
                id: id,
                name: "Corrupted fixture",
                estimatedPriceMinorUnits: nil,
                currencyCode: "USD",
                categoryRaw: ExpenseCategory.other.rawValue,
                reasonRaw: nil,
                emotionTagRaw: nil,
                sourceContextLabel: nil,
                createdAt: TestFixtures.now,
                updatedAt: TestFixtures.now,
                coolingOffHours: 24,
                targetReviewDate: nil,
                statusRaw: statusRaw,
                notes: nil,
                purchasedExpenseId: nil,
                coolingOffPlans: []
            )
        )
        try modelContext.save()
    }
}

@ModelActor
private actor ExpenseStorageInspector {
    func normalizedMerchantName(id: UUID) throws -> String? {
        var descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                expense.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.normalizedMerchantName
    }
}

@ModelActor
private actor MerchantInventorySeeder {
    struct Snapshot: Equatable, Sendable {
        let totalMinorUnits: Int64
        let displayName: String
        let primaryCategoryRaw: String?
        let visitCount: Int
        let contextCurrencyCode: String?
    }

    func insertMerchantWithVerifiedExpense(staleTotal: Int64, invalidWishCurrency: String? = nil) throws -> UUID {
        let merchantID = UUID()
        let expense = Expense(
            id: UUID(), amountMinorUnits: 425, currencyCode: "USD",
            categoryRaw: ExpenseCategory.food.rawValue, bucketRaw: BudgetBucket.discretionary.rawValue,
            merchantName: "Corner Market", normalizedMerchantName: "corner market", note: nil,
            spentAt: TestFixtures.now, spentTimeZoneIdentifier: "UTC", createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now, paymentMethodRaw: nil, emotionTagRaw: nil, purchaseReasonRaw: nil,
            isPlanned: false, isRecurring: false, sourceRaw: ExpenseSource.manual.rawValue,
            allowMerchantIndexing: true
        )
        modelContext.insert(expense)
        modelContext.insert(
            Merchant(
                id: merchantID, normalizedName: "corner market", displayName: "Corner Market",
                primaryCategoryRaw: ExpenseCategory.food.rawValue, visitCount: 9,
                lastVisitedAt: TestFixtures.now, totalMinorUnitsAllTime: staleTotal
            )
        )
        if let invalidWishCurrency {
            modelContext.insert(
                WishItem(
                    id: UUID(), name: "Invalid fixture", estimatedPriceMinorUnits: nil,
                    currencyCode: invalidWishCurrency, categoryRaw: ExpenseCategory.other.rawValue,
                    reasonRaw: nil, emotionTagRaw: nil, sourceContextLabel: nil,
                    createdAt: TestFixtures.now, updatedAt: TestFixtures.now, coolingOffHours: 24,
                    targetReviewDate: nil, statusRaw: WishItemStatus.active.rawValue, notes: nil,
                    purchasedExpenseId: nil, coolingOffPlans: []
                )
            )
        }
        try modelContext.save()
        return merchantID
    }

    func snapshot(merchantID: UUID) throws -> Snapshot? {
        var merchantDescriptor = FetchDescriptor<Merchant>(predicate: #Predicate { $0.id == merchantID })
        merchantDescriptor.fetchLimit = 1
        guard let merchant = try modelContext.fetch(merchantDescriptor).first else { return nil }
        var contextDescriptor = FetchDescriptor<MerchantAccountingContext>(predicate: #Predicate { $0.merchantID == merchantID })
        contextDescriptor.fetchLimit = 1
        return Snapshot(
            totalMinorUnits: merchant.totalMinorUnitsAllTime,
            displayName: merchant.displayName,
            primaryCategoryRaw: merchant.primaryCategoryRaw,
            visitCount: merchant.visitCount,
            contextCurrencyCode: try modelContext.fetch(contextDescriptor).first?.currencyCode
        )
    }
}

struct StoreMigrationRecoveryTests {
    @Test
    func firstExistingStoreGetsOneSnapshotThenCommittedMarkerIsCopyFreeAndDeleteAllKeepsMarker() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let storeURL = root.appendingPathComponent("MindBudget.store")
        let original = Data("original-store".utf8)
        try original.write(to: storeURL)
        let coordinator = StoreMigrationRecoveryCoordinator(storeURL: storeURL)

        let preparedAttempt = try coordinator.prepareForOpen()
        let attempt = try #require(preparedAttempt)
        try coordinator.markMigrating(attempt)
        try coordinator.markValidating(attempt)
        try coordinator.commit(attempt)

        #expect(try coordinator.prepareForOpen() == nil)
        try coordinator.deleteRecoveryArtifacts()
        #expect(try coordinator.prepareForOpen() == nil)
        #expect(try Data(contentsOf: storeURL) == original)
    }

    @Test
    func historicalProvenanceAfterNormalExpenseDeletionDoesNotFailThePostOpenInventory() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let storeURL = root.appendingPathComponent("MindBudget.store")
        let expenseID = UUID()
        do {
            let controller = try DataController(storeURL: storeURL)
            let actor = controller.dataActor
            _ = try await actor.createExpense(
                ExpenseDraft(
                    id: expenseID, amount: Money(minorUnits: 100, currencyCode: "USD"),
                    category: .coffee, bucket: .discretionary, merchantName: nil, note: nil,
                    spentAt: TestFixtures.now, spentTimeZoneIdentifier: "UTC", createdAt: TestFixtures.now,
                    updatedAt: TestFixtures.now, paymentMethod: nil, emotionTag: nil, purchaseReason: nil,
                    isPlanned: false, isRecurring: true, source: .manual, allowMerchantIndexing: false
                )
            )
            try await actor.deleteExpense(id: expenseID)
        }
        try FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + ".migration-marker"))
        // End the reopened container's lifetime before the deferred fixture-directory cleanup.
        // Removing SQLite sidecars while the container is alive is itself an API violation and
        // would make this recovery test manufacture the corruption it is supposed to detect.
        do {
            let reopened = try DataController(storeURL: storeURL)
            #expect(try await reopened.dataActor.fetchExpenseSummaries().isEmpty)
            #expect((try await reopened.dataActor.modelCounts()).recurringRules == 1)
        }
    }

    @Test
    func interruptedAttemptRestoresOriginalBytesBeforeCreatingTheNextSnapshot() throws {
        let root = try recoveryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("MindBudget.store")
        let original = Data("before".utf8)
        try original.write(to: storeURL)
        let coordinator = StoreMigrationRecoveryCoordinator(storeURL: storeURL)
        let preparedAttempt = try coordinator.prepareForOpen()
        let attempt = try #require(preparedAttempt)
        try coordinator.markMigrating(attempt)
        try Data("partially-migrated".utf8).write(to: storeURL)

        _ = try StoreMigrationRecoveryCoordinator(storeURL: storeURL).prepareForOpen()
        #expect(try Data(contentsOf: storeURL) == original)
    }

    @Test
    func corruptManifestBackupNeverOverwritesTheLiveStore() throws {
        let root = try recoveryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("MindBudget.store")
        try Data("before".utf8).write(to: storeURL)
        let coordinator = StoreMigrationRecoveryCoordinator(storeURL: storeURL)
        let preparedAttempt = try coordinator.prepareForOpen()
        let attempt = try #require(preparedAttempt)
        try coordinator.markMigrating(attempt)
        let backupStore = try #require(
            FileManager.default.contentsOfDirectory(
                at: root.appendingPathComponent("MindBudgetMigrationRecovery"),
                includingPropertiesForKeys: nil
            ).first(where: { $0.hasDirectoryPath })
        ).appendingPathComponent("store")
        try Data("corrupt-backup".utf8).write(to: backupStore)
        let live = Data("live-after-failure".utf8)
        try live.write(to: storeURL)

        #expect(throws: StoreMigrationRecoveryCoordinator.RecoveryError.backupIntegrityMismatch) {
            try coordinator.restore(attempt, reason: .inventoryRejected)
        }
        #expect(try Data(contentsOf: storeURL) == live)
    }

    @Test
    func uncommittedMarkerNeverSelectsTheFastPath() throws {
        let root = try recoveryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("MindBudget.store")
        try Data("existing".utf8).write(to: storeURL)
        try Data(#"{"formatVersion":1,"state":"prepared","target":"mindbudget-schema-v5"}"#.utf8)
            .write(to: URL(fileURLWithPath: storeURL.path + ".migration-marker"))
        #expect(try StoreMigrationRecoveryCoordinator(storeURL: storeURL).prepareForOpen() != nil)
    }

    @Test
    func journalPathTraversalIsRejectedBeforeAnyLiveStoreMutation() throws {
        let root = try recoveryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("MindBudget.store")
        let original = Data("existing".utf8)
        try original.write(to: storeURL)
        let recovery = root.appendingPathComponent("MindBudgetMigrationRecovery")
        try FileManager.default.createDirectory(at: recovery, withIntermediateDirectories: true)
        let id = UUID()
        let journal = #"{"backupDirectoryName":"../escape","formatVersion":1,"manifestFileName":"manifest.json","migrationID":"\#(id.uuidString)","sourceMarkerTarget":null,"state":"prepared","target":"mindbudget-schema-v5"}"#
        try Data(journal.utf8).write(to: recovery.appendingPathComponent("journal.json"))

        #expect(throws: StoreMigrationRecoveryCoordinator.RecoveryError.unreadableJournal) {
            _ = try StoreMigrationRecoveryCoordinator(storeURL: storeURL).prepareForOpen()
        }
        #expect(try Data(contentsOf: storeURL) == original)
    }

    @Test @MainActor
    func inventoryRepairsOnlyMerchantAggregateAndAddsVerifiedCurrencyContext() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let seeder = MerchantInventorySeeder(modelContainer: controller.container)
        let merchantID = try await seeder.insertMerchantWithVerifiedExpense(staleTotal: 1)

        try MigrationIntegrityInventory.validateAndRepair(in: controller.container)

        let snapshot = try #require(try await seeder.snapshot(merchantID: merchantID))
        #expect(snapshot.totalMinorUnits == 425)
        #expect(snapshot.contextCurrencyCode == "USD")
        #expect(snapshot.displayName == "Corner Market")
        #expect(snapshot.primaryCategoryRaw == ExpenseCategory.food.rawValue)
        #expect(snapshot.visitCount == 9)
    }

    @Test @MainActor
    func inventoryFailureBuildsRepairPlanBeforeMutatingMerchantAggregate() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let seeder = MerchantInventorySeeder(modelContainer: controller.container)
        let merchantID = try await seeder.insertMerchantWithVerifiedExpense(
            staleTotal: 1,
            invalidWishCurrency: "ZZZ"
        )

        #expect(throws: MigrationIntegrityInventory.Error.unsupportedCurrency) {
            try MigrationIntegrityInventory.validateAndRepair(in: controller.container)
        }

        let snapshot = try #require(try await seeder.snapshot(merchantID: merchantID))
        #expect(snapshot.totalMinorUnits == 1)
        #expect(snapshot.contextCurrencyCode == nil)
    }

    private func recoveryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}

private enum C4A03LegacyStore: String, CaseIterable {
    case v1 = "V1"
    case v2 = "V2"
    case v3 = "V3"
    case v4 = "V4"
}

private enum C4A03InjectedRestoreFailure: Error {
    case beforeArtifactCopy
}

@MainActor
struct C4A03RecoveryAndCurrencyMatrixTests {
    @Test
    func everyLegacySchemaUpgradesCleanlyToV5AndRepeatedRestartPreservesItsExactExpense() async throws {
        for legacy in C4A03LegacyStore.allCases {
            let root = try makeRoot()
            defer { try? FileManager.default.removeItem(at: root) }
            let storeURL = root.appendingPathComponent("MindBudget.store")
            let expenseID = try seedLegacyStore(legacy, at: storeURL, amountMinorUnits: 1_234)

            let firstOpen = try await upgradedSnapshot(at: storeURL)
            #expect(firstOpen.ids == [expenseID], "\(legacy.rawValue) clean upgrade")
            #expect(firstOpen.amounts == [1_234])
            #expect(firstOpen.incomeCount == legacy.expectedIncomeCount)
            #expect(firstOpen.incomeAmounts == legacy.expectedIncomeAmounts)
            #expect(firstOpen.savingsGoalCount == legacy.expectedSavingsGoalCount)
            #expect(firstOpen.goalTargetMinorUnits == legacy.expectedGoalTargetMinorUnits)
            #expect(firstOpen.goalStartingBalanceMinorUnits == legacy.expectedGoalStartingBalanceMinorUnits)
            #expect(firstOpen.budgetPlanSemanticsCount == legacy.expectedBudgetPlanSemanticsCount)
            #expect(firstOpen.planMonthlyIncomeMinorUnits == legacy.expectedPlanMonthlyIncomeMinorUnits)
            #expect(firstOpen.planAuthority == legacy.expectedPlanAuthority)

            let restarted = try await upgradedSnapshot(at: storeURL)
            #expect(restarted.ids == [expenseID], "\(legacy.rawValue) repeated restart")
            #expect(restarted.merchantAccountingContexts == 0, "migration must not invent a Merchant companion")
            #expect(restarted.incomeCount == legacy.expectedIncomeCount)
            #expect(restarted.incomeAmounts == legacy.expectedIncomeAmounts)
            #expect(restarted.savingsGoalCount == legacy.expectedSavingsGoalCount)
            #expect(restarted.goalTargetMinorUnits == legacy.expectedGoalTargetMinorUnits)
            #expect(restarted.goalStartingBalanceMinorUnits == legacy.expectedGoalStartingBalanceMinorUnits)
            #expect(restarted.budgetPlanSemanticsCount == legacy.expectedBudgetPlanSemanticsCount)
            #expect(restarted.planMonthlyIncomeMinorUnits == legacy.expectedPlanMonthlyIncomeMinorUnits)
            #expect(restarted.planAuthority == legacy.expectedPlanAuthority)
        }
    }

    @Test
    func everyLegacySchemaInterruptedBeforeOpenRestoresThenUpgradesAndRestarts() async throws {
        for legacy in C4A03LegacyStore.allCases {
            let root = try makeRoot()
            defer { try? FileManager.default.removeItem(at: root) }
            let storeURL = root.appendingPathComponent("MindBudget.store")
            let expenseID = try seedLegacyStore(legacy, at: storeURL, amountMinorUnits: 4_250)

            let coordinator = StoreMigrationRecoveryCoordinator(storeURL: storeURL)
            let prepared = try coordinator.prepareForOpen()
            let attempt = try #require(prepared)
            try coordinator.markMigrating(attempt)
            try Data("interrupted-open".utf8).write(to: storeURL)

            let recovered = try await upgradedSnapshot(at: storeURL)
            #expect(recovered.ids == [expenseID], "\(legacy.rawValue) interrupted upgrade")
            #expect(recovered.amounts == [4_250])
            #expect(recovered.incomeCount == legacy.expectedIncomeCount)
            #expect(recovered.incomeAmounts == legacy.expectedIncomeAmounts)
            #expect(recovered.savingsGoalCount == legacy.expectedSavingsGoalCount)
            #expect(recovered.goalTargetMinorUnits == legacy.expectedGoalTargetMinorUnits)
            #expect(recovered.goalStartingBalanceMinorUnits == legacy.expectedGoalStartingBalanceMinorUnits)
            #expect(recovered.budgetPlanSemanticsCount == legacy.expectedBudgetPlanSemanticsCount)
            #expect(recovered.planMonthlyIncomeMinorUnits == legacy.expectedPlanMonthlyIncomeMinorUnits)
            #expect(recovered.planAuthority == legacy.expectedPlanAuthority)

            let restarted = try await upgradedSnapshot(at: storeURL)
            #expect(restarted.ids == [expenseID], "\(legacy.rawValue) restart after restore")
            #expect(restarted.incomeCount == legacy.expectedIncomeCount)
            #expect(restarted.incomeAmounts == legacy.expectedIncomeAmounts)
            #expect(restarted.savingsGoalCount == legacy.expectedSavingsGoalCount)
            #expect(restarted.goalTargetMinorUnits == legacy.expectedGoalTargetMinorUnits)
            #expect(restarted.goalStartingBalanceMinorUnits == legacy.expectedGoalStartingBalanceMinorUnits)
            #expect(restarted.budgetPlanSemanticsCount == legacy.expectedBudgetPlanSemanticsCount)
            #expect(restarted.planMonthlyIncomeMinorUnits == legacy.expectedPlanMonthlyIncomeMinorUnits)
            #expect(restarted.planAuthority == legacy.expectedPlanAuthority)
        }
    }

    @Test
    func restoreFailureAfterLiveRemovalLeavesTheJournalAndBackupForARepeatableRecovery() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("MindBudget.store")
        let original = Data("recoverable-original".utf8)
        try original.write(to: storeURL)

        let failing = StoreMigrationRecoveryCoordinator(
            storeURL: storeURL,
            beforeRestoreArtifactCopy: { _ in throw C4A03InjectedRestoreFailure.beforeArtifactCopy }
        )
        let prepared = try failing.prepareForOpen()
        let attempt = try #require(prepared)
        try failing.markMigrating(attempt)
        try Data("mutated-live-store".utf8).write(to: storeURL)

        #expect(throws: C4A03InjectedRestoreFailure.self) {
            try failing.restore(attempt, reason: .inventoryRejected)
        }
        let recoveryRoot = root.appendingPathComponent("MindBudgetMigrationRecovery", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: recoveryRoot.appendingPathComponent("journal.json").path))
        #expect(!FileManager.default.fileExists(atPath: storeURL.path), "fault occurs after live bytes are removed")

        let resumed = StoreMigrationRecoveryCoordinator(storeURL: storeURL)
        let resumedPrepared = try resumed.prepareForOpen()
        let resumedAttempt = try #require(resumedPrepared)
        #expect(try Data(contentsOf: storeURL) == original)
        try resumed.markMigrating(resumedAttempt)
        try resumed.markValidating(resumedAttempt)
        try resumed.commit(resumedAttempt)
        #expect(try resumed.prepareForOpen() == nil)
        #expect(try resumed.prepareForOpen() == nil, "terminal committed recovery is idempotent")
    }

    @Test
    func failedValidationRestoresTheLegacyStoreWithoutZeroingItsInvalidFact() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("MindBudget.store")
        let expenseID = try seedLegacyStore(.v4, at: storeURL, amountMinorUnits: -1)

        #expect(throws: (any Error).self) {
            _ = try DataController(storeURL: storeURL)
        }

        let schema = Schema(versionedSchema: SchemaV4.self)
        let configuration = ModelConfiguration("MindBudget", schema: schema, url: storeURL, allowsSave: true)
        let legacyContainer = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(legacyContainer)
        let recovered = try #require(try context.fetch(FetchDescriptor<Expense>()).first { $0.id == expenseID })
        #expect(recovered.amountMinorUnits == -1)
        #expect(recovered.currencyCode == "USD")
    }

    @Test
    func inventoryAcceptsUSDJPYAndKWDWithZeroGoalAndSignedDerivedDeltaBeyondTheEntryBound() throws {
        for fixture in [("USD", 2), ("JPY", 0), ("KWD", 3)] {
            let controller = try DataController(isStoredInMemoryOnly: true)
            let context = ModelContext(controller.container)
            let amount = Money(decimal: Decimal(string: "1.234", locale: Locale(identifier: "en_US_POSIX"))!, currencyCode: fixture.0)
            #expect(amount.exponent == fixture.1)
            context.insert(makeExpense(amountMinorUnits: max(1, amount.minorUnits), currencyCode: fixture.0))
            context.insert(
                SavingsGoal(
                    id: UUID(), targetMinorUnits: 0, startingBalanceMinorUnits: 0, currencyCode: fixture.0,
                    createdAt: TestFixtures.now, updatedAt: TestFixtures.now
                )
            )
            let maximum = Money.maximumMinorUnits(for: fixture.0)
            let plan = BudgetPlan(
                id: UUID(), cycleStart: TestFixtures.now, cycleEnd: TestFixtures.now.addingTimeInterval(1), currencyCode: fixture.0,
                monthlyIncomeMinorUnits: maximum, totalBudgetMinorUnits: maximum, fixedExpensesMinorUnits: 0,
                savingGoalMinorUnits: 0, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, categoryBudgets: []
            )
            context.insert(plan)
            context.insert(
                CategoryBudget(
                    id: UUID(), categoryRaw: ExpenseCategory.food.rawValue, limitMinorUnits: maximum,
                    warningThresholdBasisPoints: 8_000, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, plan: plan
                )
            )
            context.insert(makeInsight(payload: try payloadJSON(.money(Money(minorUnits: -(maximum + 1), currencyCode: fixture.0)))))
            try context.save()
            try MigrationIntegrityInventory.validateAndRepair(in: controller.container)
        }
    }

    @Test
    func inventoryRejectsOutOfBoundBudgetPlanWithoutRepairingIt() throws {
        let maximum = Money.maximumMinorUnits(for: "USD")
        let controller = try DataController(isStoredInMemoryOnly: true)
        let context = ModelContext(controller.container)
        let plan = BudgetPlan(
            id: UUID(), cycleStart: TestFixtures.now, cycleEnd: TestFixtures.now.addingTimeInterval(1), currencyCode: "USD",
            monthlyIncomeMinorUnits: maximum + 1, totalBudgetMinorUnits: 0, fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 0, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, categoryBudgets: []
        )
        context.insert(plan)
        try context.save()

        #expect(throws: MigrationIntegrityInventory.Error.invalidPersistedAmount) {
            try MigrationIntegrityInventory.validateAndRepair(in: controller.container)
        }
        #expect(plan.monthlyIncomeMinorUnits == maximum + 1)
    }

    @Test
    func inventoryRejectsOutOfBoundCategoryWithoutRepairingIt() throws {
        let maximum = Money.maximumMinorUnits(for: "USD")
        let categoryController = try DataController(isStoredInMemoryOnly: true)
        let categoryContext = ModelContext(categoryController.container)
        let plan = BudgetPlan(
            id: UUID(), cycleStart: TestFixtures.now, cycleEnd: TestFixtures.now.addingTimeInterval(1), currencyCode: "USD",
            monthlyIncomeMinorUnits: 0, totalBudgetMinorUnits: 0, fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 0, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, categoryBudgets: []
        )
        let category = CategoryBudget(
            id: UUID(), categoryRaw: ExpenseCategory.food.rawValue, limitMinorUnits: maximum + 1,
            warningThresholdBasisPoints: 8_000, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, plan: plan
        )
        categoryContext.insert(plan)
        categoryContext.insert(category)
        try categoryContext.save()
        #expect(throws: MigrationIntegrityInventory.Error.invalidPersistedAmount) {
            try MigrationIntegrityInventory.validateAndRepair(in: categoryController.container)
        }
        #expect(category.limitMinorUnits == maximum + 1)

    }

    @Test
    func writerAndInventoryBothRejectBudgetAmountsAboveTheAcceptedMaximum() async throws {
        let maximum = Money.maximumMinorUnits(for: "USD")
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let accepted = BudgetPlanDraft(
            id: UUID(), cycleStart: TestFixtures.now, cycleEnd: TestFixtures.now.addingTimeInterval(1), currencyCode: "USD",
            monthlyIncomeMinorUnits: maximum, totalBudgetMinorUnits: 0, fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 0, createdAt: TestFixtures.now, updatedAt: TestFixtures.now,
            categoryBudgets: [
                CategoryBudgetDraft(
                    id: UUID(), category: .food, limitMinorUnits: maximum, warningThresholdBasisPoints: 8_000,
                    createdAt: TestFixtures.now, updatedAt: TestFixtures.now
                )
            ]
        )
        let stored = try await actor.createBudgetPlan(accepted)
        #expect(stored.monthlyIncomeMinorUnits == maximum)
        #expect(stored.categoryBudgets.first?.limitMinorUnits == maximum)
        let plan = BudgetPlanDraft(
            id: UUID(), cycleStart: TestFixtures.now, cycleEnd: TestFixtures.now.addingTimeInterval(1), currencyCode: "USD",
            monthlyIncomeMinorUnits: maximum + 1, totalBudgetMinorUnits: 0, fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 0, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, categoryBudgets: []
        )
        await #expect(throws: DataValidationError.invalidBudgetAmount) {
            _ = try await actor.createBudgetPlan(plan)
        }
    }

    @Test
    func allocationOverflowAndBrokenReferenceFailClosedWithoutInventingZeros() throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let context = ModelContext(controller.container)
        let income = Income(
            id: UUID(), amountMinorUnits: 100, currencyCode: "USD", categoryRaw: IncomeCategory.salary.rawValue,
            sourceName: nil, note: nil, receivedAt: TestFixtures.now, receivedTimeZoneIdentifier: "UTC",
            createdAt: TestFixtures.now, updatedAt: TestFixtures.now
        )
        context.insert(income)
        context.insert(
            IncomeAllocation(
                id: UUID(), incomeID: income.id, budgetPlanID: nil, allocatedToBudgetMinorUnits: Int64.max,
                allocatedToSavingsMinorUnits: 1, createdAt: TestFixtures.now, updatedAt: TestFixtures.now
            )
        )
        try context.save()

        #expect(throws: MigrationIntegrityInventory.Error.invalidPersistedAmount) {
            try MigrationIntegrityInventory.validateAndRepair(in: controller.container)
        }
    }

    @Test
    func brokenReferenceUnsupportedCurrencyAndMerchantContextAnomaliesPreserveExistingNonzeroFacts() throws {
        let brokenReference = try DataController(isStoredInMemoryOnly: true)
        let brokenContext = ModelContext(brokenReference.container)
        let income = Income(
            id: UUID(), amountMinorUnits: 100, currencyCode: "USD", categoryRaw: IncomeCategory.salary.rawValue,
            sourceName: nil, note: nil, receivedAt: TestFixtures.now, receivedTimeZoneIdentifier: "UTC",
            createdAt: TestFixtures.now, updatedAt: TestFixtures.now
        )
        brokenContext.insert(income)
        brokenContext.insert(
            IncomeAllocation(
                id: UUID(), incomeID: income.id, budgetPlanID: UUID(), allocatedToBudgetMinorUnits: 10,
                allocatedToSavingsMinorUnits: 0, createdAt: TestFixtures.now, updatedAt: TestFixtures.now
            )
        )
        try brokenContext.save()
        #expect(throws: MigrationIntegrityInventory.Error.invalidPersistedAmount) {
            try MigrationIntegrityInventory.validateAndRepair(in: brokenReference.container)
        }
        #expect(income.amountMinorUnits == 100)

        let unsupported = try DataController(isStoredInMemoryOnly: true)
        let unsupportedContext = ModelContext(unsupported.container)
        let invalidExpense = makeExpense(amountMinorUnits: 99, currencyCode: "ZZZ")
        unsupportedContext.insert(invalidExpense)
        try unsupportedContext.save()
        #expect(throws: MigrationIntegrityInventory.Error.unsupportedCurrency) {
            try MigrationIntegrityInventory.validateAndRepair(in: unsupported.container)
        }
        #expect(invalidExpense.amountMinorUnits == 99)

        let merchantController = try DataController(isStoredInMemoryOnly: true)
        let merchantContext = ModelContext(merchantController.container)
        let merchant = Merchant(
            id: UUID(), normalizedName: "orphan", displayName: "Orphan", primaryCategoryRaw: nil,
            visitCount: 1, lastVisitedAt: nil, totalMinorUnitsAllTime: 777
        )
        merchantContext.insert(merchant)
        try merchantContext.save()
        #expect(throws: MigrationIntegrityInventory.Error.invalidMerchantAggregate) {
            try MigrationIntegrityInventory.validateAndRepair(in: merchantController.container)
        }
        #expect(merchant.totalMinorUnitsAllTime == 777)

        let orphanContextController = try DataController(isStoredInMemoryOnly: true)
        let orphanContext = ModelContext(orphanContextController.container)
        let accountingContext = MerchantAccountingContext(merchantID: UUID(), currencyCode: "USD")
        orphanContext.insert(accountingContext)
        try orphanContext.save()
        #expect(throws: MigrationIntegrityInventory.Error.invalidMerchantAggregate) {
            try MigrationIntegrityInventory.validateAndRepair(in: orphanContextController.container)
        }
        #expect(accountingContext.currencyCode == "USD")
    }

    @Test
    func duplicateCategoryIdentityIsRejectedWithoutDiscardingEitherLimit() throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let context = ModelContext(controller.container)
        let plan = BudgetPlan(
            id: UUID(), cycleStart: TestFixtures.now, cycleEnd: TestFixtures.now.addingTimeInterval(1), currencyCode: "USD",
            monthlyIncomeMinorUnits: 0, totalBudgetMinorUnits: 0, fixedExpensesMinorUnits: 0,
            savingGoalMinorUnits: 0, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, categoryBudgets: []
        )
        let first = CategoryBudget(
            id: UUID(), categoryRaw: ExpenseCategory.food.rawValue, limitMinorUnits: 100,
            warningThresholdBasisPoints: 8_000, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, plan: plan
        )
        let second = CategoryBudget(
            id: UUID(), categoryRaw: ExpenseCategory.food.rawValue, limitMinorUnits: 200,
            warningThresholdBasisPoints: 8_000, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, plan: plan
        )
        context.insert(plan)
        context.insert(first)
        context.insert(second)
        try context.save()
        #expect(throws: MigrationIntegrityInventory.Error.duplicateIdentity) {
            try MigrationIntegrityInventory.validateAndRepair(in: controller.container)
        }
        #expect(first.limitMinorUnits == 100)
        #expect(second.limitMinorUnits == 200)
    }

    @Test
    func crossCurrencyAndUnreadablePayloadAreIndependentClosedAnomalies() throws {
        let crossCurrency = try DataController(isStoredInMemoryOnly: true)
        let crossContext = ModelContext(crossCurrency.container)
        let expense = makeExpense(amountMinorUnits: 100, currencyCode: "USD")
        let income = Income(
            id: UUID(), amountMinorUnits: 100, currencyCode: "JPY", categoryRaw: IncomeCategory.salary.rawValue,
            sourceName: nil, note: nil, receivedAt: TestFixtures.now, receivedTimeZoneIdentifier: "UTC",
            createdAt: TestFixtures.now, updatedAt: TestFixtures.now
        )
        crossContext.insert(expense)
        crossContext.insert(income)
        try crossContext.save()
        #expect(throws: MigrationIntegrityInventory.Error.mixedAccountingCurrency) {
            try MigrationIntegrityInventory.validateAndRepair(in: crossCurrency.container)
        }
        #expect(expense.amountMinorUnits == 100)
        #expect(income.amountMinorUnits == 100)

        let unreadable = try DataController(isStoredInMemoryOnly: true)
        let unreadableContext = ModelContext(unreadable.container)
        let malformedInsight = makeInsight(payload: "{not-json")
        unreadableContext.insert(malformedInsight)
        try unreadableContext.save()
        #expect(throws: MigrationIntegrityInventory.Error.invalidPersistedAmount) {
            try MigrationIntegrityInventory.validateAndRepair(in: unreadable.container)
        }
        #expect(malformedInsight.payloadJSON == "{not-json")
    }

    private func makeRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func seedLegacyStore(_ legacy: C4A03LegacyStore, at storeURL: URL, amountMinorUnits: Int64) throws -> UUID {
        let schema: Schema
        switch legacy {
        case .v1: schema = Schema(versionedSchema: SchemaV1.self)
        case .v2: schema = Schema(versionedSchema: SchemaV2.self)
        case .v3: schema = Schema(versionedSchema: SchemaV3.self)
        case .v4: schema = Schema(versionedSchema: SchemaV4.self)
        }
        let configuration = ModelConfiguration("MindBudget", schema: schema, url: storeURL, allowsSave: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let expenseID = UUID()
        context.insert(makeExpense(id: expenseID, amountMinorUnits: amountMinorUnits, currencyCode: "USD"))
        switch legacy {
        case .v1:
            break
        case .v2:
            context.insert(legacyIncome())
        case .v3:
            context.insert(legacyIncome())
            context.insert(
                SavingsGoal(
                    id: UUID(), targetMinorUnits: 1_000, startingBalanceMinorUnits: 0, currencyCode: "USD",
                    createdAt: TestFixtures.now, updatedAt: TestFixtures.now
                )
            )
        case .v4:
            context.insert(legacyIncome())
            context.insert(
                SavingsGoal(
                    id: UUID(), targetMinorUnits: 1_000, startingBalanceMinorUnits: 0, currencyCode: "USD",
                    createdAt: TestFixtures.now, updatedAt: TestFixtures.now
                )
            )
            let planID = UUID()
            context.insert(
                BudgetPlan(
                    id: planID, cycleStart: TestFixtures.now, cycleEnd: TestFixtures.now.addingTimeInterval(1), currencyCode: "USD",
                    monthlyIncomeMinorUnits: 100, totalBudgetMinorUnits: 100, fixedExpensesMinorUnits: 0,
                    savingGoalMinorUnits: 0, createdAt: TestFixtures.now, updatedAt: TestFixtures.now, categoryBudgets: []
                )
            )
            context.insert(BudgetPlanSemantics(planID: planID, authorityRaw: BudgetPlanAuthority.incomeBased.rawValue))
        }
        try context.save()
        return expenseID
    }

    private func upgradedSnapshot(at storeURL: URL) async throws -> (
        ids: [UUID],
        amounts: [Int64],
        merchantAccountingContexts: Int,
        incomeCount: Int,
        incomeAmounts: [Int64],
        savingsGoalCount: Int,
        goalTargetMinorUnits: Int64?,
        goalStartingBalanceMinorUnits: Int64?,
        budgetPlanSemanticsCount: Int,
        planMonthlyIncomeMinorUnits: Int64?,
        planAuthority: BudgetPlanAuthority?
    ) {
        let controller = try DataController(storeURL: storeURL)
        let summaries = try await controller.dataActor.fetchExpenseSummaries()
        let incomes = try await controller.dataActor.fetchIncomeSummaries()
        let goal = try await controller.dataActor.fetchSavingsGoalSummary()
        let plan = try await controller.dataActor.fetchBudgetPlanSummaries().first
        let counts = try await controller.dataActor.modelCounts()
        return (
            summaries.map(\.id), summaries.map { $0.amount.minorUnits }, counts.merchantAccountingContexts,
            counts.incomes, incomes.map { $0.amount.minorUnits }, counts.savingsGoals,
            goal?.target.minorUnits, goal?.startingBalance.minorUnits, counts.budgetPlanSemantics,
            plan?.monthlyIncomeMinorUnits, plan?.authority
        )
    }

    private func legacyIncome() -> Income {
        Income(
            id: UUID(), amountMinorUnits: 100, currencyCode: "USD", categoryRaw: IncomeCategory.salary.rawValue,
            sourceName: nil, note: nil, receivedAt: TestFixtures.now, receivedTimeZoneIdentifier: "UTC",
            createdAt: TestFixtures.now, updatedAt: TestFixtures.now
        )
    }

    private func makeExpense(id: UUID = UUID(), amountMinorUnits: Int64, currencyCode: String) -> Expense {
        Expense(
            id: id, amountMinorUnits: amountMinorUnits, currencyCode: currencyCode,
            categoryRaw: ExpenseCategory.food.rawValue, bucketRaw: BudgetBucket.discretionary.rawValue,
            merchantName: nil, normalizedMerchantName: nil, note: nil, spentAt: TestFixtures.now,
            spentTimeZoneIdentifier: "UTC", createdAt: TestFixtures.now, updatedAt: TestFixtures.now,
            paymentMethodRaw: nil, emotionTagRaw: nil, purchaseReasonRaw: nil, isPlanned: false,
            isRecurring: false, sourceRaw: ExpenseSource.manual.rawValue, allowMerchantIndexing: false
        )
    }

    private func makeInsight(payload: String) -> SpendingInsight {
        SpendingInsight(
            id: UUID(), dedupeKey: UUID().uuidString, typeRaw: SpendingInsightType.safeToProceed.rawValue,
            severityRaw: InsightSeverity.info.rawValue, titleKey: "test", bodyKey: "test", payloadJSON: payload,
            relatedCategoryRaw: nil, relatedEmotionTagRaw: nil, createdAt: TestFixtures.now,
            periodStart: TestFixtures.now, periodEnd: TestFixtures.now.addingTimeInterval(1),
            isDismissed: false, dismissedAt: nil
        )
    }

    private func payloadJSON(_ value: InsightValue) throws -> String {
        let data = try SettingsCodec.encode(["value": value])
        return try #require(String(data: data, encoding: .utf8))
    }
}

private extension C4A03LegacyStore {
    var expectedIncomeCount: Int { self == .v1 ? 0 : 1 }
    var expectedIncomeAmounts: [Int64] { self == .v1 ? [] : [100] }
    var expectedSavingsGoalCount: Int { self == .v3 || self == .v4 ? 1 : 0 }
    var expectedGoalTargetMinorUnits: Int64? { self == .v3 || self == .v4 ? 1_000 : nil }
    var expectedGoalStartingBalanceMinorUnits: Int64? { self == .v3 || self == .v4 ? 0 : nil }
    var expectedBudgetPlanSemanticsCount: Int { self == .v4 ? 1 : 0 }
    var expectedPlanMonthlyIncomeMinorUnits: Int64? { self == .v4 ? 100 : nil }
    var expectedPlanAuthority: BudgetPlanAuthority? { self == .v4 ? .incomeBased : nil }
}
