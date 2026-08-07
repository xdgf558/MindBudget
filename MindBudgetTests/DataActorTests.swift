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
