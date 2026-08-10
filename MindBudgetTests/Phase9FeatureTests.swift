import AppIntents
import CoreTransferable
import Foundation
import Testing
@testable import MindBudget

struct Phase9FeatureTests {
    @Test
    func onscreenAwarenessRequiresEveryCentralizedGate() {
        let unavailableRuntime = SystemIntegrationCapability(
            siriProductEnabled: true,
            spotlightProductEnabled: true,
            onscreenProductEnabled: true,
            siriRuntimeAvailable: { true },
            spotlightRuntimeAvailable: { true },
            onscreenRuntimeAvailable: { false }
        )
        #expect(
            unavailableRuntime.onscreenAvailability(userEnabled: true)
                == .runtimeUnavailable
        )
        #expect(
            unavailableRuntime.onscreenAvailability(userEnabled: false)
                == .userDisabled
        )

        let available = capability()
        #expect(available.onscreenAvailability(userEnabled: true) == .available)
        #expect(available.onscreenAvailability(userEnabled: false) == .userDisabled)

        let outOfScope = SystemIntegrationCapability(
            siriProductEnabled: true,
            spotlightProductEnabled: true,
            onscreenProductEnabled: false,
            siriRuntimeAvailable: { true },
            spotlightRuntimeAvailable: { true },
            onscreenRuntimeAvailable: { true }
        )
        #expect(outOfScope.onscreenAvailability(userEnabled: true) == .productDisabled)
    }

    @Test
    @available(iOS 18.0, *)
    func allRedactedAppEntitiesConformToIndexedEntity() {
        requireIndexedEntity(ExpenseEntity.self)
        requireIndexedEntity(BudgetSnapshotEntity.self)
        requireIndexedEntity(WishlistItemEntity.self)
        requireIndexedEntity(CoolingOffPlanEntity.self)
        requireIndexedEntity(MerchantEntity.self)
        requireIndexedEntity(SpendingInsightEntity.self)
        requireIndexedEntity(EmotionTagEntity.self)
    }

    @Test
    func onscreenEntitiesExposeOnlyIdentityThroughTransferable() throws {
        requireTransferable(ExpenseEntity.self)
        requireTransferable(BudgetSnapshotEntity.self)
        requireTransferable(WishlistItemEntity.self)

        let expense = ExpenseEntity(summary: expense(at: TestFixtures.now), plan: nil)
        let budget = BudgetSnapshotEntity(snapshot: configuredSnapshot())
        let wish = WishlistItemEntity(summary: wishItem())
        let references = [
            expense.onscreenTransferReference,
            budget.onscreenTransferReference,
            wish.onscreenTransferReference,
        ]

        #expect(references.map(\.entityKind) == [.expense, .budgetSnapshot, .wishlistItem])
        #expect(references[0].identifier == expense.id.uuidString)
        #expect(references[1].identifier == "current")
        #expect(references[2].identifier == wish.id.uuidString)

        for reference in references {
            let data = try reference.encoded()
            let object = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            #expect(Set(object.keys) == ["entityKind", "identifier", "version"])
            #expect(object["version"] as? Int == OnscreenTransferReference.currentVersion)
        }

        let combinedPayload = try references
            .map { String(decoding: try $0.encoded(), as: UTF8.self) }
            .joined(separator: "\n")
        #expect(combinedPayload.contains("Headphones") == false)
        #expect(combinedPayload.contains("electronics") == false)
        #expect(combinedPayload.contains("amount") == false)
        #expect(combinedPayload.contains("note") == false)
    }

    @Test
    @available(iOS 26.0, *)
    func onscreenReferencesResolveOnlyAppOwnedAmountFreeEntityTypes() {
        let expenseID = UUID()
        let wishID = UUID()
        let insightID = UUID()

        #expect(
            OnscreenEntityReference.expense(expenseID).entityIdentifier.identifier
                == expenseID.uuidString
        )
        #expect(
            OnscreenEntityReference.budgetCurrent.entityIdentifier.identifier == "current"
        )
        #expect(
            OnscreenEntityReference.wishlistItem(wishID).entityIdentifier.identifier
                == wishID.uuidString
        )
        #expect(
            OnscreenEntityReference.spendingInsight(insightID).entityIdentifier.identifier
                == insightID.uuidString
        )
    }

    @Test
    func localSearchUsesOnlyIntentRelevantAuthoritativeProjections() throws {
        let snapshot = configuredSnapshot()
        let previousDate = try #require(
            TestFixtures.utcCalendar.date(byAdding: .day, value: -2, to: snapshot.cycle.start)
        )
        let currentDate = try #require(
            TestFixtures.utcCalendar.date(byAdding: .day, value: 2, to: snapshot.cycle.start)
        )
        let futureDate = try #require(
            TestFixtures.utcCalendar.date(byAdding: .day, value: 2, to: snapshot.cycle.end)
        )
        let expenses = [previousDate, currentDate, futureDate].map(expense(at:))
        let wish = wishItem()
        let service = LocalSearchService()

        let stress = service.retrieve(
            intent: .stressPattern,
            snapshot: snapshot,
            expenses: expenses,
            wishItems: [wish],
            calendar: TestFixtures.utcCalendar
        )
        #expect(stress.expenses.map(\.spentAt) == [currentDate])
        #expect(stress.wishItems.isEmpty)

        let category = service.retrieve(
            intent: .categoryChange,
            snapshot: snapshot,
            expenses: expenses,
            wishItems: [wish],
            calendar: TestFixtures.utcCalendar
        )
        #expect(Set(category.expenses.map(\.spentAt)) == [previousDate, currentDate])
        #expect(category.wishItems.isEmpty)

        let wishlist = service.retrieve(
            intent: .wishlistStatus,
            snapshot: snapshot,
            expenses: expenses,
            wishItems: [wish],
            calendar: TestFixtures.utcCalendar
        )
        #expect(wishlist.expenses.isEmpty)
        #expect(wishlist.wishItems == [wish])
    }

    @Test
    func spotlightDocumentsCarryOnlyRedactedTypedEntityPayloads() async {
        let expense = expense(at: TestFixtures.now)
        let indexer = SpotlightIndexingService(
            client: Phase9SpotlightClient(),
            capability: capability()
        )
        let documents = await indexer.makeDocuments(
            expenses: [expense],
            plans: [],
            wishItems: [],
            coolingPlans: [],
            merchants: [],
            eligibleMerchantKeys: [],
            insights: [],
            indexMerchantNames: false,
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )
        let document = documents.first {
            $0.identifier == MindBudgetSearchIdentifier.expense(expense.id)
        }

        guard case let .expense(entity) = document?.appEntity else {
            Issue.record("Expense Spotlight document did not carry its typed entity")
            return
        }
        #expect(entity.id == expense.id)
        #expect(entity.amountBucket == .unavailable)
        #expect(document?.title.contains("123.45") == false)
        #expect(document?.contentDescription.contains("123.45") == false)
    }

    @Test
    func notificationSchedulerCarriesAGatedEntityAssociationToTheSDKBoundary() async throws {
        let center = Phase9NotificationCenter()
        let scheduler = NotificationScheduler(center: center)
        let wishID = UUID()
        let candidate = CoolingNotificationCandidate(
            planID: UUID(),
            wishItemID: wishID,
            itemName: "Headphones",
            reviewAt: TestFixtures.now.addingTimeInterval(3_600),
            durationHours: 24,
            status: .active,
            outcome: nil,
            notificationIdentifier: nil
        )
        _ = try await scheduler.reconcile(
            candidates: [candidate],
            preferences: notificationPreferences(),
            contextualEntitiesEnabled: true,
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )

        let request = try #require(await center.requests().first)
        #expect(request.appEntityReference == .wishlistItem(wishID))

        let disabledCenter = Phase9NotificationCenter()
        _ = try await NotificationScheduler(center: disabledCenter).reconcile(
            candidates: [candidate],
            preferences: notificationPreferences(),
            contextualEntitiesEnabled: false,
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )
        #expect(await disabledCenter.requests().first?.appEntityReference == nil)
        #expect(NotificationEntityAssociationSupport.isAvailableInCurrentSDK == false)
    }

    @available(iOS 18.0, *)
    private func requireIndexedEntity<Entity: IndexedEntity>(_ type: Entity.Type) {}

    private func requireTransferable<Entity: Transferable>(_ type: Entity.Type) {}

    private func capability() -> SystemIntegrationCapability {
        SystemIntegrationCapability(
            siriProductEnabled: true,
            spotlightProductEnabled: true,
            onscreenProductEnabled: true,
            siriRuntimeAvailable: { true },
            spotlightRuntimeAvailable: { true },
            onscreenRuntimeAvailable: { true }
        )
    }

    private func configuredSnapshot() -> ConfiguredBudgetSnapshot {
        let cycle = DateInterval(
            start: Date(timeIntervalSince1970: 1_784_764_800),
            end: Date(timeIntervalSince1970: 1_785_715_200)
        )
        func money(_ minorUnits: Int64) -> Money {
            Money(minorUnits: minorUnits, currencyCode: "USD")
        }
        return ConfiguredBudgetSnapshot(
            cycle: cycle,
            currencyCode: "USD",
            totalBudget: money(300_000),
            expectedExpenses: money(300_000),
            fixedForecast: money(100_000),
            savingGoal: money(50_000),
            freeBudget: money(150_000),
            spentTotal: money(40_000),
            fixedSpent: money(0),
            discretionarySpent: money(40_000),
            savedSoFar: money(0),
            spentByCategory: [:],
            remainingTotal: money(260_000),
            remainingFree: money(110_000),
            pendingFixed: money(100_000),
            pendingSaving: money(50_000),
            availableRightNow: money(110_000),
            safeDailySpend: money(10_000),
            daysRemaining: 11
        )
    }

    private func expense(at date: Date) -> ExpenseSummary {
        ExpenseSummary(
            id: UUID(),
            amount: Money(minorUnits: 12_345, currencyCode: "USD"),
            category: .electronics,
            bucket: .discretionary,
            merchantName: nil,
            spentAt: date,
            spentTimeZoneIdentifier: "UTC",
            createdAt: date,
            updatedAt: date,
            paymentMethod: nil,
            emotionTag: .stressed,
            purchaseReason: .stressRelief,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
    }

    private func wishItem() -> WishItemSummary {
        WishItemSummary(
            id: UUID(),
            name: "Headphones",
            estimatedPrice: nil,
            category: .electronics,
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            coolingOffHours: 24,
            status: .active,
            targetReviewDate: nil,
            purchasedExpenseId: nil
        )
    }

    private func notificationPreferences() -> PreferencesSnapshot {
        PreferencesSnapshot(
            reminderTone: .soft,
            gentleRemindersEnabled: true,
            notificationsEnabled: true,
            quietHours: nil,
            maxDailyInterruptions: 2
        )
    }
}

private actor Phase9NotificationCenter: LocalNotificationCenterClient {
    private var recordedRequests: [LocalNotificationRequest] = []

    func authorizationState() async -> NotificationAuthorizationState { .authorized }
    func requestAuthorization() async throws -> NotificationAuthorizationState { .authorized }
    func pendingRequestIdentifiers() async -> Set<String> { [] }
    func deliveredNotifications() async -> [DeliveredLocalNotification] { [] }
    func add(_ request: LocalNotificationRequest) async throws {
        recordedRequests.append(request)
    }
    func removePendingRequests(withIdentifiers identifiers: [String]) async throws {}
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) async throws {}
    func removeAllNotifications() async throws {}
    func requests() -> [LocalNotificationRequest] { recordedRequests }
}

private actor Phase9SpotlightClient: SpotlightIndexClient {
    func replace(domainIdentifier: String, with documents: [SpotlightDocument]) async throws {}
    func delete(domainIdentifier: String) async throws {}
}
