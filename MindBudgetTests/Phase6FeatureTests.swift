import Foundation
import SwiftData
import Testing
@testable import MindBudget

@MainActor
struct Phase6FeatureTests {
    @Test
    func emptyCSVHasUTF8BOMAndHeaderOnly() throws {
        let result = CSVExporter().export([])
        let bytes = [UInt8](result.data)
        let text = try #require(String(data: result.data.dropFirst(3), encoding: .utf8))

        #expect(Array(bytes.prefix(3)) == [0xEF, 0xBB, 0xBF])
        #expect(text == CSVExporter.header.joined(separator: ",") + "\r\n")
        #expect(result.rowCount == 0)
    }

    @Test
    func csvEscapesUserTextAndFormatsMinorUnitsExactly() throws {
        let record = expenseExportRecord(
            amount: Money(minorUnits: 123_456, currencyCode: "USD"),
            merchantName: "Cafe, \"East\"",
            note: "first line\nsecond line"
        )
        let result = CSVExporter().export([record])
        let rows = try parseCSV(result.data)

        #expect(rows.count == 2)
        #expect(rows[1][0] == "expense")
        #expect(rows[1][4] == "1234.56")
        #expect(rows[1][5] == "123456")
        #expect(rows[1][9] == "Cafe, \"East\"")
        #expect(rows[1][10] == "first line\nsecond line")
        #expect(rows[1].count == CSVExporter.header.count)
    }

    @Test
    func csvSupportsZeroExponentAndNeutralizesSpreadsheetFormulas() throws {
        let record = expenseExportRecord(
            amount: Money(minorUnits: 123_456, currencyCode: "JPY"),
            merchantName: "=HYPERLINK(\"https://example.invalid\")",
            note: "  +1+1"
        )
        let row = try #require(parseCSV(CSVExporter().export([record]).data).last)

        #expect(row[4] == "123456")
        #expect(row[9].hasPrefix("'="))
        #expect(row[10].hasPrefix("'  +"))
    }

    @Test
    func coolingNotificationUsesQuietHoursAndNeverReceivesMoneyOrNotes() async throws {
        let center = TestLocalNotificationCenter(authorizationState: .authorized)
        let scheduler = NotificationScheduler(center: center)
        let calendar = TestFixtures.utcCalendar
        let now = try date(2026, 7, 24, 20, 0, calendar: calendar)
        let reviewAt = try date(2026, 7, 24, 22, 0, calendar: calendar)
        let candidate = coolingCandidate(reviewAt: reviewAt)

        let result = try await scheduler.reconcile(
            candidates: [candidate],
            preferences: preferences(notificationsEnabled: true),
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
        let request = try #require(await center.requests().first)
        let scheduledDate = try #require(calendar.date(from: request.dateComponents))
        let expectedDate = try date(2026, 7, 25, 9, 0, calendar: calendar)

        #expect(scheduledDate == expectedDate)
        #expect(result.scheduledCount == 1)
        #expect(result.identifierUpdates.first?.identifier == request.identifier)
        #expect(!request.title.contains("123.45"))
        #expect(!request.body.contains("private note"))
        #expect(request.title.contains("AirPods"))

        let chineseCenter = TestLocalNotificationCenter(authorizationState: .authorized)
        _ = try await NotificationScheduler(center: chineseCenter).reconcile(
            candidates: [candidate],
            preferences: preferences(notificationsEnabled: true),
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "zh_CN")
        )
        let chineseRequest = try #require(await chineseCenter.requests().first)
        #expect(chineseRequest.title == "关于 AirPods")
        #expect(chineseRequest.body.contains("24 小时冷静期已结束"))
    }

    @Test
    func deniedAuthorizationClearsStoredAndPendingIdentifiers() async throws {
        let planID = UUID()
        let identifier = CoolingNotificationIdentifier.requestID(for: planID)
        let center = TestLocalNotificationCenter(
            authorizationState: .denied,
            initialPendingIdentifiers: [identifier]
        )
        let scheduler = NotificationScheduler(center: center)
        let calendar = TestFixtures.utcCalendar
        let candidate = coolingCandidate(
            planID: planID,
            reviewAt: try date(2026, 7, 25, 10, 0, calendar: calendar),
            notificationIdentifier: identifier
        )

        let result = try await scheduler.reconcile(
            candidates: [candidate],
            preferences: preferences(notificationsEnabled: true),
            now: try date(2026, 7, 24, 10, 0, calendar: calendar),
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )

        #expect(result.authorizationState == .denied)
        #expect(result.identifierUpdates == [
            CoolingNotificationIdentifierUpdate(planID: planID, identifier: nil)
        ])
        #expect(await center.pendingIdentifiers().isEmpty)
        #expect(await center.requests().isEmpty)
    }

    @Test
    func backgroundReconciliationNeverRequestsPermissionImplicitly() async throws {
        let center = TestLocalNotificationCenter(authorizationState: .notDetermined)
        let scheduler = NotificationScheduler(center: center)
        let calendar = TestFixtures.utcCalendar
        let now = try date(2026, 7, 24, 10, 0, calendar: calendar)

        let result = try await scheduler.reconcile(
            candidates: [
                coolingCandidate(
                    reviewAt: try date(2026, 7, 25, 10, 0, calendar: calendar)
                )
            ],
            preferences: preferences(notificationsEnabled: true),
            now: now,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )

        #expect(result.authorizationState == .notDetermined)
        #expect(await center.currentAuthorizationState() == .notDetermined)
        #expect(await center.requests().isEmpty)
    }

    @Test
    func deliveredCoolingNotificationIsReturnedOnceForActorHistory() async throws {
        let planID = UUID()
        let identifier = CoolingNotificationIdentifier.requestID(for: planID)
        let deliveredAt = TestFixtures.now
        let center = TestLocalNotificationCenter(
            authorizationState: .authorized,
            delivered: [
                DeliveredLocalNotification(
                    identifier: identifier,
                    deliveredAt: deliveredAt
                )
            ]
        )
        let scheduler = NotificationScheduler(center: center)
        let candidate = coolingCandidate(
            planID: planID,
            reviewAt: deliveredAt,
            notificationIdentifier: identifier
        )

        let result = try await scheduler.reconcile(
            candidates: [candidate],
            preferences: preferences(notificationsEnabled: true),
            now: deliveredAt,
            calendar: TestFixtures.utcCalendar,
            locale: Locale(identifier: "en_US")
        )

        #expect(result.deliveredNotifications == [
            DeliveredCoolingNotification(planID: planID, deliveredAt: deliveredAt)
        ])
        #expect(result.identifierUpdates == [
            CoolingNotificationIdentifierUpdate(planID: planID, identifier: nil)
        ])
        #expect(await center.delivered().isEmpty)
    }

    @Test
    func actorReconciliationPersistsAndThenCancelsExactPlanIdentifier() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.dataActor
        let wishID = UUID()
        _ = try await actor.createWishItem(wishDraft(id: wishID))
        let startedAt = TestFixtures.now
        _ = try await actor.startCoolingOff(
            wishItemId: wishID,
            durationHours: 24,
            startedAt: startedAt,
            calendar: TestFixtures.utcCalendar
        )
        let center = TestLocalNotificationCenter(authorizationState: .authorized)
        let scheduler = NotificationScheduler(center: center)
        let settings = testSettings()
        settings.enableLocalNotifications = true
        let session = AppSession(
            dataActor: actor,
            notificationScheduler: scheduler,
            searchIndexCleaner: TestSearchIndexCleaner()
        )

        #expect(await session.reconcileNotifications(
            settings: settings,
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar,
            now: startedAt
        ))
        let scheduled = try #require(
            try await actor.fetchCoolingOffPlanSummaries().first
        )
        #expect(scheduled.notificationIdentifier != nil)
        #expect(await center.pendingIdentifiers() == [scheduled.notificationIdentifier!])

        _ = try await actor.transitionWishItem(
            id: wishID,
            to: .skipped,
            at: try #require(
                TestFixtures.utcCalendar.date(byAdding: .hour, value: 1, to: startedAt)
            )
        )
        #expect(await session.reconcileNotifications(
            settings: settings,
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar,
            now: startedAt
        ))

        #expect(try await actor.fetchCoolingOffPlanSummaries().first?.notificationIdentifier == nil)
        #expect(await center.pendingIdentifiers().isEmpty)
    }

    @Test
    func invalidCoolingRecordIsIsolatedAndWarningSurvivesLaterOperationFailure() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.dataActor
        let validWishID = UUID()
        _ = try await actor.createWishItem(wishDraft(id: validWishID))
        _ = try await actor.startCoolingOff(
            wishItemId: validWishID,
            durationHours: 24,
            startedAt: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )

        let orphanPlanID = UUID()
        let orphanIdentifier = CoolingNotificationIdentifier.requestID(for: orphanPlanID)
        let seeder = Phase6ModelSeeder(modelContainer: controller.container)
        try await seeder.insertOrphanCoolingOffPlan(
            id: orphanPlanID,
            notificationIdentifier: orphanIdentifier
        )
        let batch = try await actor.fetchCoolingNotificationCandidates()
        #expect(batch.candidates.count == 1)
        #expect(batch.invalidPlanIDs == [orphanPlanID])

        let center = TestLocalNotificationCenter(
            authorizationState: .authorized,
            initialPendingIdentifiers: [orphanIdentifier]
        )
        let settings = testSettings()
        settings.enableLocalNotifications = true
        let session = AppSession(
            dataActor: actor,
            notificationScheduler: NotificationScheduler(center: center),
            searchIndexCleaner: TestSearchIndexCleaner()
        )

        #expect(await session.reconcileNotifications(
            settings: settings,
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar,
            now: TestFixtures.now
        ))
        #expect(session.notificationDataIntegrityWarning)
        #expect(session.invalidCoolingOffRecordCount == 1)
        #expect(!session.notificationOperationFailed)
        #expect(await center.requests().count == 1)
        let pendingIdentifiers = await center.pendingIdentifiers()
        #expect(!pendingIdentifiers.contains(orphanIdentifier))
        #expect(try await seeder.notificationIdentifier(for: orphanPlanID) == nil)

        await center.setAddFailureEnabled(true)
        let failedReconciliation = await session.reconcileNotifications(
            settings: settings,
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar,
            now: TestFixtures.now
        )
        #expect(!failedReconciliation)
        #expect(session.notificationOperationFailed)
        #expect(session.notificationDataIntegrityWarning)
    }

    @Test
    func confirmedCoolingOffRepairDeletesOnlyStillInvalidIdentifiedRecords() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.dataActor
        let validWishID = UUID()
        _ = try await actor.createWishItem(wishDraft(id: validWishID))
        _ = try await actor.startCoolingOff(
            wishItemId: validWishID,
            durationHours: 24,
            startedAt: TestFixtures.now,
            calendar: TestFixtures.utcCalendar
        )

        let orphanPlanID = UUID()
        let orphanIdentifier = CoolingNotificationIdentifier.requestID(for: orphanPlanID)
        let seeder = Phase6ModelSeeder(modelContainer: controller.container)
        try await seeder.insertOrphanCoolingOffPlan(
            id: orphanPlanID,
            notificationIdentifier: orphanIdentifier
        )
        let settings = testSettings()
        settings.enableLocalNotifications = true
        let center = TestLocalNotificationCenter(authorizationState: .authorized)
        let session = AppSession(
            dataActor: actor,
            notificationScheduler: NotificationScheduler(center: center),
            searchIndexCleaner: TestSearchIndexCleaner()
        )

        #expect(await session.reconcileNotifications(
            settings: settings,
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar,
            now: TestFixtures.now
        ))
        #expect(session.invalidCoolingOffRecordCount == 1)
        #expect(try await actor.modelCounts().coolingOffPlans == 2)

        // The repair is authoritative even if the independent notification refresh
        // immediately afterward fails. A deleted row must not leave a stale warning.
        await center.setAddFailureEnabled(true)
        #expect(await session.repairInvalidCoolingOffRecords(
            settings: settings,
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar,
            now: TestFixtures.now
        ))

        #expect(session.coolingOffRepairState == .completed(1))
        #expect(session.invalidCoolingOffRecordCount == 0)
        #expect(!session.notificationDataIntegrityWarning)
        #expect(session.notificationOperationFailed)
        #expect(try await actor.modelCounts().coolingOffPlans == 1)
        #expect(try await actor.fetchCoolingNotificationCandidates().candidates.count == 1)
    }

    @Test
    func deleteAllDataRunsPrivacyStagesThenResetsEveryLocalModelAndPreference() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        try await controller.dataActor.replaceLocalData(
            with: TestFixtures.sample(.threeMonthHistory)
        )
        let periodEnd = try #require(
            TestFixtures.utcCalendar.date(
                byAdding: .hour,
                value: 1,
                to: TestFixtures.now
            )
        )
        _ = try await controller.dataActor.upsertSpendingInsights(
            [
                InsightDraft(
                    type: .safeToProceed,
                    severity: .info,
                    dedupeKey: "phase6-deletion-fixture",
                    payload: [:],
                    throttleMetadata: ReminderThrottleMetadata(
                        scopeKey: "safeToProceed:global",
                        categoryRiskBasisPoints: nil
                    ),
                    relatedCategory: nil,
                    relatedEmotionTag: nil,
                    periodStart: TestFixtures.now,
                    periodEnd: periodEnd
                )
            ],
            createdAt: TestFixtures.now
        )
        _ = try await controller.dataActor.createReminderEvent(
            ReminderEventDraft(
                id: UUID(),
                insightType: .safeToProceed,
                scopeKey: "safeToProceed:global",
                channel: .card,
                shownAt: TestFixtures.now,
                categoryRiskBasisPoints: nil,
                isInterrupting: false,
                response: nil,
                respondedAt: nil
            )
        )
        try await Phase6ModelSeeder(modelContainer: controller.container).insertReflection()
        let populatedCounts = try await controller.dataActor.modelCounts()
        #expect(populatedCounts.expenses > 0)
        #expect(populatedCounts.budgetPlans > 0)
        #expect(populatedCounts.categoryBudgets > 0)
        #expect(populatedCounts.wishItems > 0)
        #expect(populatedCounts.coolingOffPlans > 0)
        #expect(populatedCounts.spendingInsights > 0)
        #expect(populatedCounts.reminderEvents > 0)
        #expect(populatedCounts.merchants > 0)
        #expect(populatedCounts.reflectionLogs > 0)
        let recorder = DeletionStageRecorder()
        let notificationScheduler = TestDeletionNotificationScheduler(recorder: recorder)
        let indexCleaner = TestSearchIndexCleaner(recorder: recorder)
        let settings = testSettings()
        settings.firstLaunchCompleted = true
        settings.currencyCode = "USD"
        settings.enableLocalNotifications = true
        settings.enableAIEnhancement = true
        let session = AppSession(
            dataActor: controller.dataActor,
            notificationScheduler: notificationScheduler,
            searchIndexCleaner: indexCleaner
        )

        #expect(await session.deleteAllData(settings: settings))
        let counts = try await controller.dataActor.modelCounts()

        #expect(await recorder.values() == ["notifications", "searchIndex"])
        #expect(counts.isEmpty)
        #expect(counts == ModelCounts(
            expenses: 0,
            budgetPlans: 0,
            wishItems: 0,
            coolingOffPlans: 0,
            categoryBudgets: 0,
            spendingInsights: 0,
            reminderEvents: 0,
            merchants: 0,
            reflectionLogs: 0
        ))
        #expect(settings.currencyCode.isEmpty)
        #expect(!settings.firstLaunchCompleted)
        #expect(!settings.enableLocalNotifications)
        #expect(!settings.enableAIEnhancement)
        #expect(session.privacyDeletionState == .completed)
    }

    @Test
    func searchIndexFailureStopsBeforeLocalDeletionAndNeverReportsSuccess() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        try await controller.dataActor.replaceLocalData(
            with: TestFixtures.sample(.endOfCycle)
        )
        let before = try await controller.dataActor.modelCounts()
        let recorder = DeletionStageRecorder()
        let settings = testSettings()
        settings.firstLaunchCompleted = true
        settings.currencyCode = "USD"
        let session = AppSession(
            dataActor: controller.dataActor,
            notificationScheduler: TestDeletionNotificationScheduler(recorder: recorder),
            searchIndexCleaner: TestSearchIndexCleaner(
                recorder: recorder,
                shouldFail: true
            )
        )

        #expect(await session.deleteAllData(settings: settings) == false)

        #expect(try await controller.dataActor.modelCounts() == before)
        #expect(settings.firstLaunchCompleted)
        #expect(settings.currencyCode == "USD")
        #expect(session.privacyDeletionState == .failed(.clearingSearchIndex))
        #expect(await recorder.values() == ["notifications", "searchIndex"])
    }

    @Test
    func incompleteDeletionVerificationNeverResetsPreferencesOrReportsSuccess() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        try await controller.dataActor.replaceLocalData(
            with: TestFixtures.sample(.endOfCycle)
        )
        let recorder = DeletionStageRecorder()
        let settings = testSettings()
        settings.firstLaunchCompleted = true
        settings.currencyCode = "USD"
        settings.enableLocalNotifications = true
        let session = AppSession(
            dataActor: controller.dataActor,
            notificationScheduler: TestDeletionNotificationScheduler(recorder: recorder),
            searchIndexCleaner: TestSearchIndexCleaner(recorder: recorder),
            privacyDeletionVerifier: TestPrivacyDeletionVerifier(isComplete: false)
        )

        #expect(await session.deleteAllData(settings: settings) == false)

        #expect(try await controller.dataActor.modelCounts().isEmpty)
        #expect(settings.firstLaunchCompleted)
        #expect(settings.currencyCode == "USD")
        #expect(settings.enableLocalNotifications)
        #expect(session.privacyDeletionState == .failed(.deletingLocalData))
        #expect(await recorder.values() == ["notifications", "searchIndex"])
    }

    @Test
    func privacyConfirmationWordUsesTheRequestedLocale() {
        #expect(
            LocalizedCatalog.string(
                "privacy.delete.confirmationWord",
                locale: Locale(identifier: "en_US")
            ) == "DELETE"
        )
        #expect(
            LocalizedCatalog.string(
                "privacy.delete.confirmationWord",
                locale: Locale(identifier: "zh_CN")
            ) == "删除"
        )
    }

    private func preferences(notificationsEnabled: Bool) -> PreferencesSnapshot {
        PreferencesSnapshot(
            reminderTone: .soft,
            gentleRemindersEnabled: true,
            notificationsEnabled: notificationsEnabled,
            quietHours: try? QuietHours(startHour: 21, endHour: 9),
            maxDailyInterruptions: 2
        )
    }

    private func coolingCandidate(
        planID: UUID = UUID(),
        reviewAt: Date,
        notificationIdentifier: String? = nil
    ) -> CoolingNotificationCandidate {
        CoolingNotificationCandidate(
            planID: planID,
            wishItemID: UUID(),
            itemName: "AirPods",
            reviewAt: reviewAt,
            durationHours: 24,
            status: .active,
            outcome: nil,
            notificationIdentifier: notificationIdentifier
        )
    }

    private func expenseExportRecord(
        amount: Money,
        merchantName: String?,
        note: String?
    ) -> ExpenseExportRecord {
        ExpenseExportRecord(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            amount: amount,
            category: .coffee,
            bucket: .discretionary,
            merchantName: merchantName,
            note: note,
            spentAt: TestFixtures.now,
            spentTimeZoneIdentifier: "Asia/Shanghai",
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            paymentMethod: .mobilePay,
            emotionTag: .neutral,
            purchaseReason: .need,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
    }

    private func wishDraft(id: UUID) -> WishItemDraft {
        WishItemDraft(
            id: id,
            name: "AirPods",
            estimatedPrice: Money(minorUnits: 12_345, currencyCode: "USD"),
            currencyCode: "USD",
            category: .electronics,
            reason: .curiosity,
            emotionTag: nil,
            sourceContextLabel: nil,
            createdAt: TestFixtures.now,
            updatedAt: TestFixtures.now,
            coolingOffHours: 24,
            targetReviewDate: nil,
            status: .active,
            notes: "private note",
            purchasedExpenseId: nil
        )
    }

    private func testSettings() -> SettingsStore {
        let suiteName = "Phase6FeatureTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return SettingsStore(defaults: defaults)
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
                    calendar: calendar,
                    timeZone: calendar.timeZone,
                    year: year,
                    month: month,
                    day: day,
                    hour: hour,
                    minute: minute
                )
            )
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
                case "\r":
                    break
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

private enum Phase6TestError: Error {
    case forcedFailure
    case invalidDate
}

private actor TestLocalNotificationCenter: LocalNotificationCenterClient {
    private var state: NotificationAuthorizationState
    private var scheduledRequests: [String: LocalNotificationRequest] = [:]
    private var pending: Set<String>
    private var deliveredValues: [DeliveredLocalNotification]
    private var shouldFailAdd = false

    init(
        authorizationState: NotificationAuthorizationState,
        initialPendingIdentifiers: Set<String> = [],
        delivered: [DeliveredLocalNotification] = []
    ) {
        state = authorizationState
        pending = initialPendingIdentifiers
        deliveredValues = delivered
    }

    func authorizationState() async -> NotificationAuthorizationState { state }

    func requestAuthorization() async throws -> NotificationAuthorizationState {
        if state == .notDetermined { state = .authorized }
        return state
    }

    func pendingRequestIdentifiers() async -> Set<String> {
        pending.union(scheduledRequests.keys)
    }

    func deliveredNotifications() async -> [DeliveredLocalNotification] {
        deliveredValues
    }

    func add(_ request: LocalNotificationRequest) async throws {
        guard !shouldFailAdd else { throw Phase6TestError.forcedFailure }
        scheduledRequests[request.identifier] = request
        pending.insert(request.identifier)
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) async throws {
        for identifier in identifiers {
            scheduledRequests[identifier] = nil
            pending.remove(identifier)
        }
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) async throws {
        deliveredValues.removeAll { identifiers.contains($0.identifier) }
    }

    func removeAllNotifications() async throws {
        scheduledRequests = [:]
        pending = []
        deliveredValues = []
    }

    func requests() -> [LocalNotificationRequest] {
        scheduledRequests.values.sorted { $0.identifier < $1.identifier }
    }

    func pendingIdentifiers() -> Set<String> {
        pending.union(scheduledRequests.keys)
    }

    func delivered() -> [DeliveredLocalNotification] {
        deliveredValues
    }

    func currentAuthorizationState() -> NotificationAuthorizationState {
        state
    }

    func setAddFailureEnabled(_ isEnabled: Bool) {
        shouldFailAdd = isEnabled
    }
}

private actor DeletionStageRecorder {
    private var stages: [String] = []

    func append(_ stage: String) {
        stages.append(stage)
    }

    func values() -> [String] { stages }
}

private actor TestDeletionNotificationScheduler: NotificationScheduling {
    let recorder: DeletionStageRecorder?
    let shouldFail: Bool

    init(recorder: DeletionStageRecorder? = nil, shouldFail: Bool = false) {
        self.recorder = recorder
        self.shouldFail = shouldFail
    }

    func authorizationState() async -> NotificationAuthorizationState { .authorized }
    func requestAuthorization() async throws -> NotificationAuthorizationState { .authorized }

    func reconcile(
        candidates: [CoolingNotificationCandidate],
        preferences: PreferencesSnapshot,
        contextualEntitiesEnabled: Bool,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) async throws -> NotificationReconciliation {
        NotificationReconciliation(
            authorizationState: .authorized,
            identifierUpdates: [],
            deliveredNotifications: [],
            scheduledCount: 0
        )
    }

    func cancelAll() async throws {
        await recorder?.append("notifications")
        if shouldFail { throw Phase6TestError.forcedFailure }
    }
}

private actor TestSearchIndexCleaner: SearchIndexDeleting {
    let recorder: DeletionStageRecorder?
    let shouldFail: Bool

    init(recorder: DeletionStageRecorder? = nil, shouldFail: Bool = false) {
        self.recorder = recorder
        self.shouldFail = shouldFail
    }

    func deleteAll() async throws {
        await recorder?.append("searchIndex")
        if shouldFail { throw Phase6TestError.forcedFailure }
    }
}

private struct TestPrivacyDeletionVerifier: PrivacyDeletionVerifying {
    let isComplete: Bool

    func isDeletionComplete(in dataActor: DataActor) async throws -> Bool {
        isComplete
    }
}

@ModelActor
private actor Phase6ModelSeeder {
    func insertReflection() throws {
        modelContext.insert(
            ReflectionLog(
                id: UUID(),
                createdAt: TestFixtures.now,
                contextRaw: ReflectionContext.manual.rawValue,
                selectedEmotionTagRaw: EmotionTag.neutral.rawValue,
                selectedReasonRaw: PurchaseReason.need.rawValue,
                note: "private reflection",
                relatedExpenseId: nil,
                relatedWishItemId: nil
            )
        )
        try modelContext.save()
    }

    func insertOrphanCoolingOffPlan(
        id: UUID,
        notificationIdentifier: String
    ) throws {
        guard let reviewAt = TestFixtures.utcCalendar.date(
            byAdding: .hour,
            value: 24,
            to: TestFixtures.now
        ) else {
            throw Phase6TestError.invalidDate
        }
        modelContext.insert(
            CoolingOffPlan(
                id: id,
                startedAt: TestFixtures.now,
                reviewAt: reviewAt,
                durationHours: 24,
                statusRaw: CoolingOffStatus.active.rawValue,
                notificationIdentifier: notificationIdentifier,
                completedAt: nil,
                outcomeRaw: nil,
                outcomeRecordedAt: nil,
                wishItem: nil
            )
        )
        try modelContext.save()
    }

    func notificationIdentifier(for id: UUID) throws -> String? {
        let descriptor = FetchDescriptor<CoolingOffPlan>(
            predicate: #Predicate { plan in plan.id == id }
        )
        return try modelContext.fetch(descriptor).first?.notificationIdentifier
    }
}
