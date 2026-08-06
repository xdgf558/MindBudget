import Foundation
import Testing
@testable import MindBudget

@MainActor
struct Phase4FeatureTests {
    @Test
    func expenseContextIsOptionalAndPersistsWhenSelected() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let viewModel = ExpenseFormViewModel(existingExpense: nil, now: TestFixtures.now)
        viewModel.amountText = "12.34"
        viewModel.category = .coffee
        viewModel.emotionTag = .stressed
        viewModel.purchaseReason = .stressRelief

        let saved = await viewModel.save(
            dataActor: actor,
            currencyCode: "USD",
            bucket: .discretionary,
            locale: Locale(identifier: "en_US"),
            now: TestFixtures.now,
            timeZone: TimeZone(identifier: "UTC")!,
            cycleStartDay: 1,
            calendar: TestFixtures.utcCalendar
        )
        let expense = try #require(try await actor.fetchExpenseSummaries().first)

        #expect(saved)
        #expect(expense.emotionTag == .stressed)
        #expect(expense.purchaseReason == .stressRelief)
    }

    @Test
    func wishlistFormAllowsNoPriceAndKeepsNotesInDetailProjection() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let viewModel = WishItemFormViewModel(existingItem: nil, seed: nil)
        viewModel.name = "  A book  "
        viewModel.category = .education
        viewModel.reason = .curiosity
        viewModel.emotionTag = .neutral
        viewModel.notes = "  Check the library first  "

        let saved = await viewModel.save(
            dataActor: actor,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US"),
            now: TestFixtures.now
        )
        let summary = try #require(try await actor.fetchWishItemSummaries().first)
        let detail = try #require(try await actor.fetchWishItemDetail(id: summary.id))

        #expect(saved)
        #expect(summary.name == "A book")
        #expect(summary.estimatedPrice == nil)
        #expect(summary.status == .active)
        #expect(detail.reason == .curiosity)
        #expect(detail.emotionTag == .neutral)
        #expect(detail.notes == "Check the library first")
    }

    @Test
    func expenseDraftCanSeedWishlistWithoutInventingContext() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let viewModel = WishItemFormViewModel(
            existingItem: nil,
            seed: WishItemFormSeed(
                name: "Laptop stand",
                estimatedPriceText: "123.45",
                category: .electronics,
                reason: .convenience,
                emotionTag: .impulse
            )
        )

        let saved = await viewModel.save(
            dataActor: actor,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US"),
            now: TestFixtures.now
        )
        let summary = try #require(try await actor.fetchWishItemSummaries().first)
        let detail = try #require(try await actor.fetchWishItemDetail(id: summary.id))

        #expect(saved)
        #expect(detail.summary.name == "Laptop stand")
        #expect(detail.summary.estimatedPrice?.minorUnits == 12_345)
        #expect(detail.summary.category == .electronics)
        #expect(detail.reason == .convenience)
        #expect(detail.emotionTag == .impulse)
        #expect(detail.sourceContextLabel == nil)
    }

    @Test
    func coolingOffCountdownUsesElapsedHoursAcrossDST() throws {
        let calendar = TestFixtures.losAngelesCalendar
        let springStart = try #require(
            calendar.date(from: DateComponents(year: 2024, month: 3, day: 9, hour: 12))
        )
        let springReview = try #require(
            calendar.date(byAdding: .hour, value: 24, to: springStart)
        )
        let fallStart = try #require(
            calendar.date(from: DateComponents(year: 2024, month: 11, day: 2, hour: 12))
        )
        let fallReview = try #require(
            calendar.date(byAdding: .hour, value: 24, to: fallStart)
        )

        let spring = CoolingOffCountdown.remaining(
            from: springStart,
            until: springReview,
            calendar: calendar
        )
        let fall = CoolingOffCountdown.remaining(
            from: fallStart,
            until: fallReview,
            calendar: calendar
        )

        #expect(spring == CoolingOffCountdown(days: 1, hours: 0, minutes: 0, isComplete: false))
        #expect(fall == CoolingOffCountdown(days: 1, hours: 0, minutes: 0, isComplete: false))
        #expect(calendar.component(.hour, from: springReview) == 13)
        #expect(calendar.component(.hour, from: fallReview) == 11)
    }

    @Test
    func coolingOffCountdownTextUsesTheRequestedLocale() {
        let countdown = CoolingOffCountdown(
            days: 1,
            hours: 2,
            minutes: 3,
            isComplete: false
        )

        #expect(
            CoolingOffCountdownText.string(
                for: countdown,
                locale: Locale(identifier: "en")
            ) == "1d 2h remaining"
        )
        #expect(
            CoolingOffCountdownText.string(
                for: countdown,
                locale: Locale(identifier: "zh-Hans")
            ) == "还剩 1 天 2 小时"
        )
    }

    @Test
    func phaseFourActionErrorsPreserveRecoverableMeaning() {
        let corruptData = PersistedModelError.invalidRawValue(
            entity: "WishItem",
            id: UUID(),
            field: "statusRaw",
            rawValue: "future-value"
        )
        let transition = WishItemTransitionError.invalidTransition(
            from: .purchased,
            to: .coolingOff
        )

        #expect(
            CoolingOffStartError.mapped(from: DataValidationError.invalidCoolingOffPlan)
                == .stateChanged
        )
        #expect(CoolingOffStartError.mapped(from: corruptData) == .invalidStoredData)
        #expect(CoolingOffStartError.mapped(from: DataValidationError.invalidAmount) == .persistence)
        #expect(WishlistActionError.mapped(from: transition) == .stateChanged)
        #expect(WishlistActionError.mapped(from: corruptData) == .invalidStoredData)
        #expect(WishlistActionError.mapped(from: DataValidationError.invalidAmount) == .persistence)
    }

    @Test
    func coolingOffLifecycleIsAtomicAndSupportsAnotherRound() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let wish = makeWish()
        _ = try await actor.createWishItem(wish)

        let cooling = try await actor.startCoolingOff(
            wishItemId: wish.id,
            durationHours: 24,
            startedAt: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )
        #expect(cooling.summary.status == .coolingOff)
        #expect(cooling.coolingOffPlans.count == 1)
        #expect(cooling.coolingOffPlans.first?.status == .active)

        await #expect(throws: DataValidationError.invalidCoolingOffPlan) {
            _ = try await actor.startCoolingOff(
                wishItemId: wish.id,
                durationHours: 72,
                startedAt: TestFixtures.now,
                calendar: TestFixtures.utcCalendar
            )
        }
        #expect(try await actor.fetchCoolingOffPlanSummaries().count == 1)

        let reviewAt = try #require(cooling.summary.targetReviewDate)
        #expect(try await actor.refreshExpiredCoolingOffPlans(at: reviewAt) == 1)
        let ready = try #require(try await actor.fetchWishItemDetail(id: wish.id))
        #expect(ready.summary.status == .readyToReview)
        #expect(ready.coolingOffPlans.first?.status == .completed)
        #expect(ready.coolingOffPlans.first?.outcome == nil)
        #expect(ready.coolingOffPlans.first?.outcomeRecordedAt == nil)

        let secondRound = try await actor.startCoolingOff(
            wishItemId: wish.id,
            durationHours: 72,
            startedAt: reviewAt,
            calendar: TestFixtures.utcCalendar
        )
        #expect(secondRound.summary.status == .coolingOff)
        #expect(secondRound.coolingOffPlans.count == 2)
        #expect(secondRound.coolingOffPlans.filter { $0.status == .active }.count == 1)
        #expect(secondRound.coolingOffPlans.contains { $0.outcome == .extended })
        #expect(
            secondRound.coolingOffPlans.first { $0.outcome == .extended }?.completedAt
                == reviewAt
        )
        #expect(
            secondRound.coolingOffPlans.first { $0.outcome == .extended }?.outcomeRecordedAt
                == reviewAt
        )
    }

    @Test
    func outcomeTimeDoesNotOverwriteCoolingOffCompletionTime() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let wish = makeWish()
        _ = try await actor.createWishItem(wish)
        let cooling = try await actor.startCoolingOff(
            wishItemId: wish.id,
            durationHours: 24,
            startedAt: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )
        let reviewAt = try #require(cooling.summary.targetReviewDate)
        _ = try await actor.refreshExpiredCoolingOffPlans(at: reviewAt)
        let outcomeRecordedAt = try #require(
            TestFixtures.utcCalendar.date(byAdding: .day, value: 3, to: reviewAt)
        )

        let decided = try await actor.decideWishItem(
            id: wish.id,
            outcome: .skipped,
            at: outcomeRecordedAt
        )
        let plan = try #require(decided.coolingOffPlans.first)

        #expect(plan.status == .completed)
        #expect(plan.outcome == .skipped)
        #expect(plan.completedAt == reviewAt)
        #expect(plan.outcomeRecordedAt == outcomeRecordedAt)
    }

    @Test
    func skippedAndArchivedCoolingOffResultsStayNeutralAndConsistent() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let wish = makeWish()
        _ = try await actor.createWishItem(wish)
        _ = try await actor.startCoolingOff(
            wishItemId: wish.id,
            durationHours: 24,
            startedAt: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )

        let skipped = try await actor.decideWishItem(
            id: wish.id,
            outcome: .skipped,
            at: TestFixtures.now.addingTimeInterval(60)
        )
        #expect(skipped.summary.status == .skipped)
        #expect(skipped.summary.targetReviewDate == nil)
        #expect(skipped.coolingOffPlans.first?.status == .completed)
        #expect(skipped.coolingOffPlans.first?.outcome == .skipped)

        _ = try await actor.transitionWishItem(
            id: wish.id,
            to: .active,
            at: TestFixtures.now.addingTimeInterval(120)
        )
        _ = try await actor.startCoolingOff(
            wishItemId: wish.id,
            durationHours: 72,
            startedAt: TestFixtures.now.addingTimeInterval(180),
            calendar: TestFixtures.utcCalendar
        )
        let archived = try await actor.archiveWishItem(
            id: wish.id,
            at: TestFixtures.now.addingTimeInterval(240)
        )
        #expect(archived.summary.status == .archived)
        #expect(archived.coolingOffPlans.first?.status == .cancelled)
        #expect(archived.coolingOffPlans.first?.outcome == nil)
    }

    @Test
    func wishlistConversionCreatesOnePlannedExpenseAndWeakLinkAtomically() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let wish = makeWish()
        _ = try await actor.createWishItem(wish)
        _ = try await actor.startCoolingOff(
            wishItemId: wish.id,
            durationHours: 24,
            startedAt: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )
        let expenseID = UUID()

        let expense = try await actor.convertWishItemToExpense(
            wishItemId: wish.id,
            expense: makeExpense(id: expenseID),
            at: TestFixtures.now.addingTimeInterval(300)
        )
        let detail = try #require(try await actor.fetchWishItemDetail(id: wish.id))

        #expect(expense.id == expenseID)
        #expect(expense.source == .wishlistConversion)
        #expect(expense.isPlanned)
        #expect(expense.emotionTag == wish.emotionTag)
        #expect(expense.purchaseReason == wish.reason)
        #expect(detail.summary.status == .purchased)
        #expect(detail.summary.purchasedExpenseId == expenseID)
        #expect(detail.coolingOffPlans.first?.outcome == .purchased)
    }

    @Test
    func invalidWishlistConversionRollsBackBothSides() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let wish = makeWish()
        _ = try await actor.createWishItem(wish)
        let invalid = makeExpense(id: UUID(), source: .manual)

        await #expect(throws: DataValidationError.invalidWishItem) {
            _ = try await actor.convertWishItemToExpense(
                wishItemId: wish.id,
                expense: invalid,
                at: TestFixtures.now
            )
        }
        #expect(try await actor.fetchExpenseSummaries().isEmpty)
        #expect(try await actor.fetchWishItemSummaries().first?.status == .active)
    }

    @Test
    func wishlistBudgetPreviewUsesConfiguredBudgetFacts() async throws {
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
                fixedExpensesMinorUnits: 20_000,
                savingGoalMinorUnits: 10_000,
                createdAt: now,
                updatedAt: now,
                categoryBudgets: []
            )
        )
        let wish = makeWish(priceMinorUnits: 80_000)
        _ = try await actor.createWishItem(wish)
        let viewModel = WishlistDetailViewModel()

        await viewModel.load(
            id: wish.id,
            dataActor: actor,
            cycleStartDay: 1,
            calendar: TestFixtures.utcCalendar,
            bucketMapping: [.electronics: .discretionary],
            now: now
        )

        #expect(viewModel.budgetImpact?.remainingTotalAfter.minorUnits == 20_000)
        #expect(viewModel.budgetImpact?.remainingFreeAfter.minorUnits == -10_000)
        #expect(viewModel.budgetImpact?.willExceedFreeBudget == true)
        #expect(viewModel.budgetImpact?.willExceedTotalBudget == false)
    }

    @Test
    func dashboardProjectionIncludesPendingCoolingOffItems() async throws {
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
                fixedExpensesMinorUnits: 20_000,
                savingGoalMinorUnits: 10_000,
                createdAt: now,
                updatedAt: now,
                categoryBudgets: []
            )
        )
        let wish = makeWish()
        _ = try await actor.createWishItem(wish)
        _ = try await actor.startCoolingOff(
            wishItemId: wish.id,
            durationHours: 24,
            startedAt: now,
            calendar: TestFixtures.utcCalendar
        )
        let viewModel = DashboardViewModel()

        await viewModel.load(
            dataActor: actor,
            currencyCode: "USD",
            cycleStartDay: 1,
            calendar: TestFixtures.utcCalendar,
            now: now
        )

        guard case let .configured(_, _, _, wishItems) = viewModel.state else {
            Issue.record("Expected configured Dashboard state")
            return
        }
        #expect(wishItems.map(\.id) == [wish.id])
        #expect(wishItems.first?.status == .coolingOff)
    }

    @Test
    func emotionCopyMatchesTheApprovedEnglishAndChineseLabels() throws {
        let english = try localizedBundle(language: "en")
        let chinese = try localizedBundle(language: "zh-Hans")
        let expected: [(EmotionTag, String, String)] = [
            (.imageBoost, "Wanted to feel put-together", "想让状态更好"),
            (.socialPressure, "Social occasion", "社交场合"),
            (.impulse, "Spur of the moment", "临时起意"),
            (.stressed, "Under pressure", "压力大的时候"),
            (.anxious, "Feeling worried", "担心的时候"),
            (.lonely, "On my own", "一个人的时候")
        ]

        for (tag, englishValue, chineseValue) in expected {
            #expect(
                english.localizedString(forKey: tag.localizedNameKey, value: nil, table: nil)
                    == englishValue
            )
            #expect(
                chinese.localizedString(forKey: tag.localizedNameKey, value: nil, table: nil)
                    == chineseValue
            )
        }
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path))
    }

    private func makeWish(priceMinorUnits: Int64 = 18_000) -> WishItemDraft {
        WishItemDraft(
            id: UUID(),
            name: "Headphones",
            estimatedPrice: Money(minorUnits: priceMinorUnits, currencyCode: "USD"),
            currencyCode: "USD",
            category: .electronics,
            reason: .convenience,
            emotionTag: .imageBoost,
            sourceContextLabel: nil,
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            coolingOffHours: 24,
            targetReviewDate: nil,
            status: .active,
            notes: nil,
            purchasedExpenseId: nil
        )
    }

    private func makeExpense(
        id: UUID,
        source: ExpenseSource = .wishlistConversion
    ) -> ExpenseDraft {
        ExpenseDraft(
            id: id,
            amount: Money(minorUnits: 18_000, currencyCode: "USD"),
            category: .electronics,
            bucket: .discretionary,
            merchantName: "Headphones",
            note: nil,
            spentAt: TestFixtures.now,
            spentTimeZoneIdentifier: "UTC",
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            paymentMethod: nil,
            emotionTag: .imageBoost,
            purchaseReason: .convenience,
            isPlanned: true,
            isRecurring: false,
            source: source,
            allowMerchantIndexing: false
        )
    }
}
