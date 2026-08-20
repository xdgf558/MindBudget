import Foundation
import Testing
@testable import MindBudget

struct Phase8AFeatureTests {
    @Test
    func centralizedIntegrationCapabilitiesRequireEveryGate() {
        let unavailableRuntime = SystemIntegrationCapability(
            siriProductEnabled: true,
            spotlightProductEnabled: true,
            siriRuntimeAvailable: { false },
            spotlightRuntimeAvailable: { false }
        )
        #expect(unavailableRuntime.siriAvailability(userEnabled: true) == .runtimeUnavailable)
        #expect(unavailableRuntime.spotlightAvailability(userEnabled: true) == .runtimeUnavailable)
        #expect(unavailableRuntime.siriAvailability(userEnabled: false) == .userDisabled)
        #expect(unavailableRuntime.spotlightAvailability(userEnabled: false) == .userDisabled)

        let enabledRuntime = availableCapability()
        #expect(enabledRuntime.siriAvailability(userEnabled: false) == .userDisabled)
        #expect(enabledRuntime.spotlightAvailability(userEnabled: false) == .userDisabled)
        #expect(enabledRuntime.siriAvailability(userEnabled: true) == .available)
        #expect(enabledRuntime.spotlightAvailability(userEnabled: true) == .available)

        let outOfScope = SystemIntegrationCapability(
            siriProductEnabled: false,
            spotlightProductEnabled: false,
            siriRuntimeAvailable: { true },
            spotlightRuntimeAvailable: { true }
        )
        #expect(outOfScope.siriAvailability(userEnabled: true) == .productDisabled)
        #expect(outOfScope.spotlightAvailability(userEnabled: true) == .productDisabled)
    }

    @Test
    func appShortcutPhrasesAreLocalizedAndKeepTheApplicationToken() throws {
        let englishPath = try #require(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let chinesePath = try #require(
            Bundle.main.path(forResource: "zh-Hans", ofType: "lproj")
        )
        let english = try #require(Bundle(path: englishPath))
        let chinese = try #require(Bundle(path: chinesePath))
        let key = "Record an expense in ${applicationName}"

        #expect(
            english.localizedString(forKey: key, value: nil, table: "AppShortcuts")
                == "Record an expense in ${applicationName}"
        )
        #expect(
            chinese.localizedString(forKey: key, value: nil, table: "AppShortcuts")
                == "\u{5728}${applicationName}\u{8bb0}\u{4e00}\u{7b14}"
        )
    }

    @Test
    func unavailableSiriReturnsNoPassiveEntitiesAndRejectsActiveWrites() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let service = intentService(
            actor: actor,
            preferences: preferences(siriEnabled: false)
        )

        #expect(try await service.expenseEntities().isEmpty)
        #expect(try await service.wishlistEntities().isEmpty)
        #expect(try await service.coolingOffEntities().isEmpty)
        #expect(try await service.merchantEntities().isEmpty)
        #expect(try await service.insightEntities().isEmpty)
        #expect(try await service.budgetSnapshotEntities().isEmpty)
        #expect(try await service.emotionTagEntities().isEmpty)
        await #expect(throws: IntentExecutionError.self) {
            _ = try await service.recordExpense(
                amount: Money(minorUnits: 500, currencyCode: "USD"),
                category: .coffee,
                bucket: .discretionary,
                merchantName: nil,
                requestedCurrencyCode: nil,
                now: TestFixtures.now,
                calendar: TestFixtures.utcCalendar
            )
        }
        #expect(try await actor.modelCounts().expenses == 0)
    }

    @Test
    func intentStringsStripControlsAndStopAtFortyCharacters() {
        let value = "  Head\nphones\u{0000}" + String(repeating: "x", count: 80)
        let sanitized = IntentStringSanitizer.sanitize(value)

        #expect(sanitized?.contains("\n") == false)
        #expect(sanitized?.unicodeScalars.contains("\u{0000}") == false)
        #expect(sanitized?.count == IntentStringSanitizer.maximumLength)
        #expect(IntentStringSanitizer.sanitize("\n\t") == nil)
    }

    @Test
    func moneyTransportPreservesMinorUnitsAndKeepsFailuresTyped() throws {
        #expect(try IntentMoneyTransport.money(from: 12.34, currencyCode: "USD").minorUnits == 1_234)
        #expect(try IntentMoneyTransport.money(from: 123, currencyCode: "JPY").minorUnits == 123)
        #expect(throws: IntentMoneyTransportError.unsupportedPrecision) {
            _ = try IntentMoneyTransport.money(from: 12.345, currencyCode: "USD")
        }
        #expect(throws: IntentMoneyTransportError.unsupportedCurrency) {
            _ = try IntentMoneyTransport.money(from: 12.34, currencyCode: "XYZ")
        }
        #expect(throws: IntentMoneyTransportError.amountOutOfRange) {
            _ = try IntentMoneyTransport.money(from: 100_000_000_000, currencyCode: "USD")
        }
        #expect(throws: IntentMoneyTransportError.invalidAmount) {
            _ = try IntentMoneyTransport.money(from: -1, currencyCode: "USD")
        }
    }

    @Test
    func intentMoneyFailureCopyIsLocalizedInEnglishAndChinese() throws {
        let englishPath = try #require(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let chinesePath = try #require(
            Bundle.main.path(forResource: "zh-Hans", ofType: "lproj")
        )
        let english = try #require(Bundle(path: englishPath))
        let chinese = try #require(Bundle(path: chinesePath))
        let keys = [
            "intent.error.invalidAmount",
            "intent.error.amountOutOfRange",
            "intent.error.unsupportedPrecision",
            "intent.error.unsupportedCurrency",
            "intent.error.temporary",
            "intent.error.featureNotYetAvailable",
        ]

        for key in keys {
            #expect(english.localizedString(forKey: key, value: nil, table: nil) != key)
            #expect(chinese.localizedString(forKey: key, value: nil, table: nil) != key)
        }
    }

    @Test
    func exactFreeSiriKeepsBasicRecordingAndBlocksAnAdvancedEntry() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let service = intentService(
            actor: actor,
            preferences: preferences(),
            subscribed: false
        )

        _ = try await service.recordExpense(
            amount: Money(minorUnits: 875, currencyCode: "USD"),
            category: .coffee,
            bucket: .discretionary,
            merchantName: nil,
            requestedCurrencyCode: nil,
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )
        await #expect(throws: IntentExecutionError.featureNotYetAvailable) {
            _ = try await service.addWishlistItem(
                name: "Headphones",
                estimatedPrice: nil,
                category: .electronics,
                requestedCurrencyCode: nil,
                now: TestFixtures.now
            )
        }

        let counts = try await actor.modelCounts()
        #expect(counts.expenses == 1)
        #expect(counts.wishItems == 0)
    }

    @Test
    func exactFreePassiveEntityProvidersReturnEmptyWithoutThrowing() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let service = intentService(
            actor: actor,
            preferences: preferences(merchantNamesEnabled: true),
            subscribed: false
        )

        #expect(try await service.expenseEntities().isEmpty)
        #expect(try await service.wishlistEntities().isEmpty)
        #expect(try await service.coolingOffEntities().isEmpty)
        #expect(try await service.merchantEntities().isEmpty)
        #expect(try await service.insightEntities().isEmpty)
        #expect(try await service.budgetSnapshotEntities().isEmpty)
        #expect(try await service.emotionTagEntities().isEmpty)
    }

    @Test
    func repeatedIntentExecutionWithinFiveSecondsPersistsOnce() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let service = intentService(actor: actor, preferences: preferences())
        let amount = Money(minorUnits: 875, currencyCode: "USD")

        let first = try await service.recordExpense(
            amount: amount,
            category: .coffee,
            bucket: .discretionary,
            merchantName: "  Cafe\nNorth  ",
            requestedCurrencyCode: "usd",
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )
        let second = try await service.recordExpense(
            amount: amount,
            category: .coffee,
            bucket: .discretionary,
            merchantName: "CafeNorth",
            requestedCurrencyCode: "USD",
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )

        #expect(first.wasDuplicate == false)
        #expect(second.wasDuplicate)
        #expect(second.expense.id == first.expense.id)
        #expect(try await actor.modelCounts().expenses == 1)
        let detail = try #require(try await actor.fetchExpenseDetail(id: first.expense.id))
        #expect(detail.note == nil)
    }

    @Test
    func intentCurrencyMismatchIsActionableAndNeverPersists() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let service = intentService(actor: actor, preferences: preferences())

        await #expect(
            throws: IntentExecutionError.accountingCurrencyMismatch(
                expected: "USD",
                actual: "CNY"
            )
        ) {
            _ = try await service.recordExpense(
                amount: Money(minorUnits: 500, currencyCode: "USD"),
                category: .coffee,
                bucket: .discretionary,
                merchantName: nil,
                requestedCurrencyCode: "CNY",
                now: TestFixtures.now,
                calendar: TestFixtures.utcCalendar
            )
        }
        #expect(try await actor.modelCounts().expenses == 0)
    }

    @Test
    func wishlistIntentUsesDefaultCoolingPeriodAndKeepsPrivateFieldsEmpty() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let service = intentService(actor: actor, preferences: preferences())

        let result = try await service.addWishlistItem(
            name: "  Noise\nCancelling Headphones  ",
            estimatedPrice: Money(minorUnits: 20_000, currencyCode: "USD"),
            category: .electronics,
            requestedCurrencyCode: nil,
            now: TestFixtures.now
        )
        let detail = try #require(try await actor.fetchWishItemDetail(id: result.id))

        #expect(result.name == "NoiseCancelling Headphones")
        #expect(result.coolingOffHours == 24)
        #expect(detail.notes == nil)
        #expect(detail.sourceContextLabel == nil)
    }

    @Test
    func budgetImpactCandidateNameIsEphemeral() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let calendar = TestFixtures.utcCalendar
        let start = try #require(calendar.date(byAdding: .day, value: -15, to: TestFixtures.now))
        let end = try #require(calendar.date(byAdding: .day, value: 15, to: TestFixtures.now))
        _ = try await actor.createBudgetPlan(
            budgetPlan(start: start, end: end)
        )
        let service = intentService(actor: actor, preferences: preferences())

        _ = try await service.checkBudgetImpact(
            amount: Money(minorUnits: 4_000, currencyCode: "USD"),
            category: .electronics,
            bucket: .discretionary,
            candidateName: "private candidate name",
            requestedCurrencyCode: nil,
            now: TestFixtures.now,
            calendar: calendar
        )

        let counts = try await actor.modelCounts()
        #expect(counts.expenses == 0)
        #expect(counts.wishItems == 0)
    }

    @Test
    func entityAndSpotlightExpenseViewsExposeBandsInsteadOfExactAmounts() async {
        let expense = expenseSummary(
            amountMinorUnits: 12_345,
            merchantName: "Private Merchant"
        )
        let plan = budgetPlanSummary(totalBudgetMinorUnits: 100_000)
        let entity = ExpenseEntity(summary: expense, plan: plan)
        let indexer = SpotlightIndexingService(
            client: RecordingSpotlightClient(),
            capability: availableCapability()
        )

        let documents = await indexer.makeDocuments(
            expenses: [expense],
            plans: [plan],
            wishItems: [],
            coolingPlans: [],
            merchants: [merchantSummary(name: "Private Merchant")],
            eligibleMerchantKeys: ["private merchant"],
            insights: [],
            indexMerchantNames: false,
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )
        let combinedText = documents.flatMap {
            [$0.title, $0.contentDescription] + $0.keywords
        }.joined(separator: " ")

        #expect(entity.amountBucket == .fiveToFifteenPercent)
        #expect(combinedText.contains("123.45") == false)
        #expect(combinedText.contains("12,345") == false)
        #expect(combinedText.contains("Private Merchant") == false)
    }

    @Test
    func merchantIndexingRequiresGlobalAndPerExpenseConsent() async {
        let indexer = SpotlightIndexingService(
            client: RecordingSpotlightClient(),
            capability: availableCapability()
        )
        let merchant = merchantSummary(name: "North Cafe")

        let globallyDisabled = await indexer.makeDocuments(
            expenses: [], plans: [], wishItems: [], coolingPlans: [],
            merchants: [merchant], eligibleMerchantKeys: [merchant.normalizedName],
            insights: [], indexMerchantNames: false, now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar, locale: Locale(identifier: "en_US")
        )
        let rowDisabled = await indexer.makeDocuments(
            expenses: [], plans: [], wishItems: [], coolingPlans: [],
            merchants: [merchant], eligibleMerchantKeys: [], insights: [],
            indexMerchantNames: true, now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar, locale: Locale(identifier: "en_US")
        )
        let fullyEnabled = await indexer.makeDocuments(
            expenses: [], plans: [], wishItems: [], coolingPlans: [],
            merchants: [merchant], eligibleMerchantKeys: [merchant.normalizedName],
            insights: [], indexMerchantNames: true, now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar, locale: Locale(identifier: "en_US")
        )

        #expect(globallyDisabled.contains { $0.identifier.hasPrefix(MindBudgetSearchIdentifier.merchantPrefix) } == false)
        #expect(rowDisabled.contains { $0.identifier.hasPrefix(MindBudgetSearchIdentifier.merchantPrefix) } == false)
        #expect(fullyEnabled.contains { $0.title == "North Cafe" })
    }

    @Test
    func spotlightReconciliationEnforcesTheMerchantTripleGateEndToEnd() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.createExpense(
            expenseDraft(merchantName: "North Cafe", allowMerchantIndexing: false)
        )

        let unavailableClient = RecordingSpotlightClient()
        let unavailableIndexer = SpotlightIndexingService(
            client: unavailableClient,
            capability: SystemIntegrationCapability(
                siriProductEnabled: true,
                spotlightProductEnabled: false,
                siriRuntimeAvailable: { true },
                spotlightRuntimeAvailable: { true }
            )
        )
        let unavailable = await unavailableIndexer.reconcile(
            dataActor: actor,
            preferences: preferences(merchantNamesEnabled: true),
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )

        #expect(unavailable == .cleared)
        #expect(await unavailableClient.replaceCount() == 0)
        #expect(await unavailableClient.deleteCount() == 1)

        let client = RecordingSpotlightClient()
        let indexer = SpotlightIndexingService(client: client, capability: availableCapability())
        _ = await indexer.reconcile(
            dataActor: actor,
            preferences: preferences(merchantNamesEnabled: true),
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )
        #expect(await client.lastDocuments().contains(where: isMerchantDocument) == false)

        _ = try await actor.createExpense(
            expenseDraft(merchantName: " NORTH  CAFE ", allowMerchantIndexing: true)
        )
        _ = await indexer.reconcile(
            dataActor: actor,
            preferences: preferences(merchantNamesEnabled: false),
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )
        #expect(await client.lastDocuments().contains(where: isMerchantDocument) == false)

        _ = await indexer.reconcile(
            dataActor: actor,
            preferences: preferences(merchantNamesEnabled: true),
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )
        #expect(await client.lastDocuments().contains(where: isMerchantDocument))
    }

    @Test
    func merchantAggregateRemainsCompleteIndependentlyOfIndexingConsent() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.createExpense(
            expenseDraft(merchantName: "North Cafe", allowMerchantIndexing: false)
        )
        let privateAggregate = try #require(try await actor.fetchMerchantSummaries().first)

        #expect(privateAggregate.visitCount == 1)
        #expect(try await actor.fetchMerchantIndexingEligibleNormalizedNames().isEmpty)

        _ = try await actor.createExpense(
            expenseDraft(merchantName: " NORTH  CAFE ", allowMerchantIndexing: true)
        )
        let completeAggregate = try #require(try await actor.fetchMerchantSummaries().first)

        #expect(completeAggregate.visitCount == 2)
        #expect(try await actor.fetchMerchantIndexingEligibleNormalizedNames() == ["northcafe"])
    }

    @Test
    func spotlightDisableClearsAndIndexFailureNeverMutatesLocalData() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let client = RecordingSpotlightClient()
        let indexer = SpotlightIndexingService(client: client, capability: availableCapability())
        let disabled = preferences(spotlightEnabled: false)

        let cleared = await indexer.reconcile(
            dataActor: actor,
            preferences: disabled,
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )
        #expect(cleared == .cleared)
        #expect(await client.deleteCount() == 1)

        await client.setReplaceFailure(true)
        let failed = await indexer.reconcile(
            dataActor: actor,
            preferences: preferences(spotlightEnabled: true),
            now: TestFixtures.now,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )
        #expect(failed == .failed)
        #expect(try await actor.modelCounts().isEmpty)
    }

    @Test
    func spotlightIdentifiersMapOnlyToKnownNavigationDestinations() {
        let wishID = UUID()
        #expect(MindBudgetSearchIdentifier.navigationRequest(for: MindBudgetSearchIdentifier.budget) == .dashboard)
        #expect(MindBudgetSearchIdentifier.navigationRequest(for: MindBudgetSearchIdentifier.expense(UUID())) == .expenses)
        #expect(MindBudgetSearchIdentifier.navigationRequest(for: MindBudgetSearchIdentifier.merchant(UUID())) == .expenses)
        #expect(MindBudgetSearchIdentifier.navigationRequest(for: MindBudgetSearchIdentifier.wishlist(wishID)) == .wishlistItem(wishID))
        #expect(MindBudgetSearchIdentifier.navigationRequest(for: "other-app-item") == nil)
    }

    @Test
    func intentNavigationDeliversBufferedAndLiveRequests() async {
        let store = MindBudgetNavigationRequestStore()
        await store.submit(.dashboard)
        let requests = await store.requests()
        var iterator = requests.makeAsyncIterator()

        #expect(await iterator.next() == .dashboard)
        await store.submit(.insights)
        #expect(await iterator.next() == .insights)
    }

    private func availableCapability() -> SystemIntegrationCapability {
        SystemIntegrationCapability(
            siriProductEnabled: true,
            spotlightProductEnabled: true,
            siriRuntimeAvailable: { true },
            spotlightRuntimeAvailable: { true }
        )
    }

    private func preferences(
        siriEnabled: Bool = true,
        spotlightEnabled: Bool = true,
        merchantNamesEnabled: Bool = false
    ) -> SystemIntegrationPreferencesSnapshot {
        SystemIntegrationPreferencesSnapshot(
            accountingCurrencyCode: "USD",
            budgetCycleStartDay: 1,
            siriEnabled: siriEnabled,
            spotlightEnabled: spotlightEnabled,
            merchantNamesEnabled: merchantNamesEnabled,
            notificationPreferences: PreferencesSnapshot(
                reminderTone: .soft,
                gentleRemindersEnabled: true,
                notificationsEnabled: false,
                quietHours: nil,
                maxDailyInterruptions: 2
            )
        )
    }

    private func intentService(
        actor: DataActor,
        preferences: SystemIntegrationPreferencesSnapshot,
        subscribed: Bool = true
    ) -> MindBudgetIntentService {
        #if DEBUG
        let featureAccessService: any FeatureAccessChecking = DebugFeatureAccessProvider(
            entitlements: subscribed ? .proSubscription : .free
        )
        #else
        let featureAccessService: any FeatureAccessChecking = FeatureAccessService()
        #endif
        return MindBudgetIntentService(
            dataActor: actor,
            preferencesProvider: FixedIntegrationPreferencesProvider(preferences),
            notificationScheduler: NoopIntentNotificationScheduler(),
            capability: availableCapability(),
            featureAccessService: featureAccessService
        )
    }

    private func budgetPlan(start: Date, end: Date) -> BudgetPlanDraft {
        BudgetPlanDraft(
            id: UUID(), cycleStart: start, cycleEnd: end, currencyCode: "USD",
            monthlyIncomeMinorUnits: 400_000, totalBudgetMinorUnits: 300_000,
            fixedExpensesMinorUnits: 100_000, savingGoalMinorUnits: 50_000,
            createdAt: start, updatedAt: start, categoryBudgets: []
        )
    }

    private func budgetPlanSummary(totalBudgetMinorUnits: Int64) -> BudgetPlanSummary {
        BudgetPlanSummary(
            id: UUID(), cycleStart: TestFixtures.now.addingTimeInterval(-86_400),
            cycleEnd: TestFixtures.now.addingTimeInterval(86_400), currencyCode: "USD",
            monthlyIncomeMinorUnits: 200_000,
            totalBudgetMinorUnits: totalBudgetMinorUnits,
            fixedExpensesMinorUnits: 20_000, savingGoalMinorUnits: 10_000,
            authority: .incomeBased,
            categoryBudgets: []
        )
    }

    private func expenseSummary(
        amountMinorUnits: Int64,
        merchantName: String?
    ) -> ExpenseSummary {
        ExpenseSummary(
            id: UUID(), amount: Money(minorUnits: amountMinorUnits, currencyCode: "USD"),
            category: .coffee, bucket: .discretionary, merchantName: merchantName,
            spentAt: TestFixtures.now, spentTimeZoneIdentifier: "UTC",
            createdAt: TestFixtures.now, updatedAt: TestFixtures.now,
            paymentMethod: nil, emotionTag: nil, purchaseReason: nil,
            isPlanned: false, isRecurring: false, source: .manual,
            allowMerchantIndexing: false
        )
    }

    private func expenseDraft(
        merchantName: String,
        allowMerchantIndexing: Bool
    ) -> ExpenseDraft {
        ExpenseDraft(
            id: UUID(), amount: Money(minorUnits: 750, currencyCode: "USD"),
            category: .coffee, bucket: .discretionary, merchantName: merchantName,
            note: "local only", spentAt: TestFixtures.now,
            spentTimeZoneIdentifier: "UTC", createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now, paymentMethod: nil, emotionTag: nil,
            purchaseReason: nil, isPlanned: false, isRecurring: false,
            source: .manual, allowMerchantIndexing: allowMerchantIndexing
        )
    }

    private func merchantSummary(name: String) -> MerchantSummary {
        MerchantSummary(
            id: UUID(), normalizedName: name.lowercased(), displayName: name,
            primaryCategory: .coffee, visitCount: 1, lastVisitedAt: TestFixtures.now,
            totalMinorUnitsAllTime: 12_345, accountingCurrencyCode: "USD"
        )
    }

    private func isMerchantDocument(_ document: SpotlightDocument) -> Bool {
        document.identifier.hasPrefix(MindBudgetSearchIdentifier.merchantPrefix)
    }
}

private actor FixedIntegrationPreferencesProvider: SystemIntegrationPreferencesProviding {
    private let value: SystemIntegrationPreferencesSnapshot

    init(_ value: SystemIntegrationPreferencesSnapshot) {
        self.value = value
    }

    func snapshot() -> SystemIntegrationPreferencesSnapshot { value }
}

private struct NoopIntentNotificationScheduler: NotificationScheduling {
    func authorizationState() async -> NotificationAuthorizationState { .denied }
    func requestAuthorization() async throws -> NotificationAuthorizationState { .denied }
    func reconcile(
        candidates: [CoolingNotificationCandidate],
        preferences: PreferencesSnapshot,
        contextualEntitiesEnabled: Bool,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> NotificationReconciliation {
        NotificationReconciliation(
            authorizationState: .denied,
            identifierUpdates: [],
            deliveredNotifications: [],
            scheduledCount: 0
        )
    }
    func cancelAll() async throws {}
}

private enum RecordingSpotlightError: Error { case replaceFailed }

private actor RecordingSpotlightClient: SpotlightIndexClient {
    private var deletes = 0
    private var replacements: [[SpotlightDocument]] = []
    private var shouldFailReplace = false

    func replace(domainIdentifier: String, with documents: [SpotlightDocument]) async throws {
        if shouldFailReplace { throw RecordingSpotlightError.replaceFailed }
        replacements.append(documents)
    }

    func delete(domainIdentifier: String) async throws {
        deletes += 1
    }

    func setReplaceFailure(_ enabled: Bool) {
        shouldFailReplace = enabled
    }

    func deleteCount() -> Int { deletes }
    func replaceCount() -> Int { replacements.count }
    func lastDocuments() -> [SpotlightDocument] { replacements.last ?? [] }
}
