import CloudKit
import Foundation
import SwiftData
import Testing
@testable import MindBudget

private enum CloudSyncDelegateTaskContext {
    @TaskLocal static var isHandlingEvent = false
}

@Suite(.serialized)
@MainActor
struct CloudSyncTests {
    @Test
    func productionCloudSyncKeepsAppleBackgroundSchedulingEnabled() {
        #expect(CKSyncEngineAdapter.automaticallySync)
        #expect(CKSyncEngineAdapter.subscriptionID == "MindBudget.Sync.v1.subscription")
    }

    @Test
    func delegateEngineOperationsDiscardTheSerializedCallbackTaskContext() async {
        let operation = CloudSyncDelegateTaskContext.$isHandlingEvent.withValue(true) {
            CKSyncEngineAdapter.schedulePostDelegateEngineOperation {
                #expect(!CloudSyncDelegateTaskContext.isHandlingEvent)
            }
        }

        await operation.value
    }

    @Test
    func onlyANewTransportGenesisMayCreateThePrivateZone() {
        #expect(CKSyncEngineAdapter.requiresGenesisZoneCreation(hasSerializedState: false))
        #expect(!CKSyncEngineAdapter.requiresGenesisZoneCreation(hasSerializedState: true))
    }

    @Test
    func lineageRevisionAdvancementFailsClosedInsteadOfOverflowing() throws {
        #expect(try CloudSyncCodec.nextRevision(after: 0) == 1)
        #expect(try CloudSyncCodec.nextRevision(after: Int64.max - 1) == Int64.max)
        #expect(throws: CloudSyncValidationError.self) {
            try CloudSyncCodec.nextRevision(after: Int64.max)
        }
    }

    @Test
    func defaultOffDoesNotConstructACloudKitAdapter() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let probe = CloudSyncAdapterProbe()
        let service = CloudSyncService(
            dataActor: actor,
            adapterFactory: { _ in probe.makeAdapter() },
            retentionStore: TestCloudSyncRetentionStore(cloudCopyMayExist: false)
        )

        await service.start()

        #expect(probe.creationCount == 0)
        #expect(service.snapshot == .disabled)

        await service.setEnabled(true)

        #expect(probe.creationCount == 1)
        #expect(probe.adapter.startCount == 1)
    }

    @Test
    func retryRunsOneTransportPassAndPausedAccountChangeRunsNone() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let probe = CloudSyncAdapterProbe()
        let service = CloudSyncService(
            dataActor: actor,
            adapterFactory: { _ in probe.makeAdapter() },
            retentionStore: TestCloudSyncRetentionStore(cloudCopyMayExist: false)
        )
        await service.start()

        await service.retry()
        #expect(probe.adapter.synchronizeCount == 1)

        #expect(try await actor.bindCloudSyncAccount(identifierHash: "account-a", at: fixedDate))
        #expect(!(try await actor.bindCloudSyncAccount(identifierHash: "account-b", at: fixedDate)))
        await service.retry()

        #expect(service.snapshot.status == .pausedAccountChanged)
        #expect(probe.adapter.synchronizeCount == 1)
    }

    @Test
    func schemaV5StoreMigratesToV6WithSyncDisabledAndFactsIntact() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudget-C4B02-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let storeURL = root.appendingPathComponent("MindBudget.store")
        let expenseID = UUID()

        do {
            let schema = Schema(versionedSchema: SchemaV5.self)
            let configuration = ModelConfiguration(
                "MindBudget",
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(
                Expense(
                    id: expenseID,
                    amountMinorUnits: 4_200,
                    currencyCode: "USD",
                    categoryRaw: ExpenseCategory.food.rawValue,
                    bucketRaw: BudgetBucket.discretionary.rawValue,
                    merchantName: nil,
                    normalizedMerchantName: nil,
                    note: "legacy-v5",
                    spentAt: fixedDate,
                    spentTimeZoneIdentifier: "UTC",
                    createdAt: fixedDate,
                    updatedAt: fixedDate,
                    paymentMethodRaw: nil,
                    emotionTagRaw: nil,
                    purchaseReasonRaw: nil,
                    isPlanned: false,
                    isRecurring: false,
                    sourceRaw: ExpenseSource.manual.rawValue,
                    allowMerchantIndexing: false
                )
            )
            try context.save()
        }

        do {
            let controller = try DataController(storeURL: storeURL)
            let summaries = try await controller.dataActor.fetchExpenseSummaries()
            let sync = try await controller.dataActor.cloudSyncSnapshot()
            #expect(summaries.map(\.id) == [expenseID])
            #expect(summaries.first?.amount.minorUnits == 4_200)
            #expect(sync == .disabled)
        }
    }

    @Test
    func recurrenceIdentityAcceptsOnlyTheClosedCanonicalGrammar() throws {
        let id = try #require(UUID(uuidString: "5D8CBF05-7AD2-474E-8867-2938A3697D7A"))
        let key = try RecurringOccurrenceKey(ruleID: id, year: -12, month: 2)

        #expect(key.rawValue == "5d8cbf05-7ad2-474e-8867-2938a3697d7a:-12-02")
        #expect(try RecurringOccurrenceKey(rawValue: key.rawValue) == key)
        #expect(throws: CloudSyncValidationError.invalidIdentity) {
            try RecurringOccurrenceKey(rawValue: "5D8CBF05-7AD2-474E-8867-2938A3697D7A:2026-02")
        }
        #expect(throws: CloudSyncValidationError.invalidIdentity) {
            try RecurringOccurrenceKey(rawValue: "5d8cbf05-7ad2-474e-8867-2938a3697d7a:2026/02")
        }
        #expect(throws: CloudSyncValidationError.invalidIdentity) {
            try RecurringOccurrenceKey(rawValue: "5d8cbf05-7ad2-474e-8867-2938a3697d7a:2026-13")
        }
    }

    @Test
    func recurrenceEngineUsesTheSharedCanonicalOccurrenceFormatter() throws {
        let schedule = MonthlyRecurringSchedule()
        let ruleID = try #require(UUID(uuidString: "5D8CBF05-7AD2-474E-8867-2938A3697D7A"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let scheduledAt = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 15, hour: 12))
        )

        let generated = try schedule.occurrenceKey(
            ruleID: ruleID,
            scheduledAt: scheduledAt,
            timeZoneIdentifier: "America/Los_Angeles",
            calendarIdentifierRaw: Calendar.Identifier.gregorian.mindBudgetPersistedValue,
            calendar: calendar
        )
        let expected = try RecurringOccurrenceKey(ruleID: ruleID, year: 2026, month: 8).rawValue

        #expect(generated == expected)
    }

    @Test
    func transportFailuresMapToClosedLocalOnlyStatuses() {
        let noAccount = CKSyncEngineAdapter.statusResolution(for: .notAuthenticated)
        let offline = CKSyncEngineAdapter.statusResolution(for: .networkUnavailable)
        let quota = CKSyncEngineAdapter.statusResolution(for: .quotaExceeded)

        #expect(noAccount.status == .accountUnavailable)
        #expect(noAccount.reason == .noAccount)
        #expect(offline.status == .waitingForNetwork)
        #expect(offline.reason == .networkUnavailable)
        #expect(quota.status == .quotaExceeded)
        #expect(quota.reason == .quotaExceeded)

        let missingZone = CKSyncEngineAdapter.statusResolution(for: .zoneNotFound)
        let resetZone = CKSyncEngineAdapter.statusResolution(
            for: .zoneNotFound,
            userDidResetEncryptedDataKey: true
        )
        let resetError = CKError(
            _nsError: NSError(
                domain: CKErrorDomain,
                code: CKError.Code.zoneNotFound.rawValue,
                userInfo: [CKErrorUserDidResetEncryptedDataKey: NSNumber(value: true)]
            )
        )
        let resetFromError = CKSyncEngineAdapter.statusResolution(for: resetError)

        #expect(missingZone.status == .pausedRemoteZoneDeleted)
        #expect(missingZone.reason == .remoteZoneDeleted)
        #expect(resetZone.status == .pausedEncryptedDataReset)
        #expect(resetZone.reason == .encryptedDataReset)
        #expect(resetFromError.status == .pausedEncryptedDataReset)
        #expect(resetFromError.reason == .encryptedDataReset)
    }

    @Test
    func databaseDeletionReasonsSelectAStickyFailClosedPause() throws {
        let deleted = try #require(CKSyncEngineAdapter.databaseDeletionPause(for: [.deleted]))
        let purged = try #require(CKSyncEngineAdapter.databaseDeletionPause(for: [.purged]))
        let reset = try #require(
            CKSyncEngineAdapter.databaseDeletionPause(for: [.deleted, .encryptedDataReset])
        )

        #expect(deleted.status == .pausedRemoteZoneDeleted)
        #expect(deleted.reason == .remoteZoneDeleted)
        #expect(purged.status == .pausedRemoteZoneDeleted)
        #expect(purged.reason == .remoteZoneDeleted)
        #expect(reset.status == .pausedEncryptedDataReset)
        #expect(reset.reason == .encryptedDataReset)
    }

    @Test
    func stickyPausesRejectLateTransportAndAccountCallbacks() async throws {
        for (stickyStatus, stickyReason) in [
            (CloudSyncStatus.pausedAccountChanged, CloudSyncReasonCode.accountChanged),
            (.pausedEncryptedDataReset, .encryptedDataReset),
            (.pausedRemoteZoneDeleted, .remoteZoneDeleted)
        ] {
            let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
            _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
            try await actor.updateCloudSyncStatus(stickyStatus, reason: stickyReason, at: fixedDate)

            try await actor.updateCloudSyncStatus(
                .waitingForNetwork,
                reason: .networkUnavailable,
                at: fixedDate.addingTimeInterval(1)
            )
            try await actor.updateCloudSyncStatus(
                .failed,
                reason: .transportFailed,
                at: fixedDate.addingTimeInterval(2)
            )
            let rebound = try await actor.bindCloudSyncAccount(
                identifierHash: "late-account",
                at: fixedDate.addingTimeInterval(3)
            )
            let snapshot = try await actor.cloudSyncSnapshot()

            #expect(!rebound)
            #expect(snapshot.status == stickyStatus)
            #expect(snapshot.reason == stickyReason)
        }
    }

    @Test
    func envelopeRequiresCanonicalBytesAndExactLineage() throws {
        let id = UUID().uuidString.lowercased()
        let payload = CloudSyncPayload(
            entityType: .expense,
            identity: id,
            fields: ["id": .string(id), "amount": .integer(100)]
        )
        let instant = Date(timeIntervalSinceReferenceDate: 1_234)
        let envelope = try CloudSyncCodec.makeEnvelope(
            payload: payload,
            entityType: .expense,
            identity: id,
            operation: .upsert,
            revision: 1,
            parentSemanticDigest: nil,
            modifiedAt: instant
        )
        let encoded = try CloudSyncCodec.encodeEnvelope(envelope)

        #expect(try CloudSyncCodec.decodeEnvelope(encoded) == envelope)
        #expect(envelope.modifiedAt == instant.cloudSyncBits)
        #expect(throws: CloudSyncValidationError.malformedEnvelope) {
            try CloudSyncCodec.decodeEnvelope(encoded + Data("\n".utf8))
        }
        #expect(throws: CloudSyncValidationError.invalidLineage) {
            try CloudSyncCodec.makeEnvelope(
                payload: payload,
                entityType: .expense,
                identity: id,
                operation: .upsert,
                revision: 1,
                parentSemanticDigest: "not-genesis",
                modifiedAt: instant
            )
        }
    }

    @Test
    func enablingAndWritingStagesOnlyAuthoritativeFacts() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234, merchantName: "Cafe")

        _ = try await actor.createExpense(expense)

        let names = try await actor.pendingCloudSyncRecordNames()
        #expect(names == ["expense/\(expense.id.uuidString.lowercased())"])
        #expect(!names.contains(where: { $0.contains("merchant") }))
        let pendingRead = try await actor.pendingCloudSyncRecord(named: names[0])
        let pending = try #require(pendingRead)
        let envelope = try CloudSyncCodec.decodeEnvelope(pending.envelopeData)
        #expect(envelope.payload?.fields["amount"]?.validatedInteger == 1_234)
        // The expense-owned merchant text is an encrypted authoritative field. The derived
        // Merchant cache itself remains local-only and therefore has no separate record.
        #expect(envelope.payload?.fields["merchantName"]?.validatedString == "Cafe")
    }

    @Test
    func everyAllowListedFactProjectsAndAppliesWithoutSyncingLocalOnlyCaches() async throws {
        let sourceController = try DataController(isStoredInMemoryOnly: true)
        let sourceActor = sourceController.makeDataActor()
        let seed = CloudSyncFactSeed()
        try await CloudSyncFactSeeder(modelContainer: sourceController.container)
            .insert(seed: seed, at: fixedDate)
        _ = try await sourceActor.setCloudSyncEnabled(true, at: fixedDate)

        let recordNames = try await sourceActor.pendingCloudSyncRecordNames()
        var remoteRecords: [CloudSyncRemoteRecord] = []
        var projectedTypes: Set<CloudSyncEntityType> = []
        for recordName in recordNames {
            let pendingRead = try await sourceActor.pendingCloudSyncRecord(named: recordName)
            let pending = try #require(pendingRead)
            let envelope = try CloudSyncCodec.decodeEnvelope(pending.envelopeData)
            projectedTypes.insert(envelope.entityType)
            remoteRecords.append(
                CloudSyncRemoteRecord(
                    recordName: recordName,
                    envelopeData: pending.envelopeData,
                    encodedSystemFields: nil,
                    wasPhysicallyDeleted: false
                )
            )
        }

        #expect(recordNames.count == CloudSyncEntityType.allCases.count)
        #expect(projectedTypes == Set(CloudSyncEntityType.allCases))

        let destinationActor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await destinationActor.setCloudSyncEnabled(true, at: fixedDate)
        try await destinationActor.ingestCloudSyncRecords(remoteRecords, receivedAt: fixedDate)

        let counts = try await destinationActor.modelCounts()
        #expect(counts.expenses == 1)
        #expect(counts.incomes == 1)
        #expect(counts.incomeAllocations == 1)
        #expect(counts.savingsGoals == 1)
        #expect(counts.recurringRules == 1)
        #expect(counts.recurringOccurrences == 1)
        #expect(counts.budgetPlans == 1)
        #expect(counts.budgetPlanSemantics == 1)
        #expect(counts.categoryBudgets == 1)
        #expect(counts.wishItems == 1)
        #expect(counts.coolingOffPlans == 1)
        #expect(counts.reflectionLogs == 1)
        #expect(counts.merchants == 0)
        #expect(counts.merchantAccountingContexts == 0)
        #expect(counts.spendingInsights == 0)
        #expect(counts.reminderEvents == 0)
        #expect(try await destinationActor.cloudSyncSnapshot().quarantinedCount == 0)
        #expect(try await destinationActor.pendingCloudSyncRecordNames().isEmpty)
    }

    @Test
    func overAllocatedIncomeIsQuarantinedInsteadOfWaitingForAParent() async throws {
        let sourceController = try DataController(isStoredInMemoryOnly: true)
        let sourceActor = sourceController.makeDataActor()
        let seed = CloudSyncFactSeed()
        try await CloudSyncFactSeeder(modelContainer: sourceController.container)
            .insert(seed: seed, at: fixedDate)
        _ = try await sourceActor.setCloudSyncEnabled(true, at: fixedDate)

        let records = try await pendingRemoteRecords(using: sourceActor).map { record in
            guard let data = record.envelopeData else { return record }
            let envelope = try CloudSyncCodec.decodeEnvelope(data)
            guard envelope.entityType == .incomeAllocation,
                  var fields = envelope.payload?.fields else { return record }
            fields["budgetAmount"] = .integer(10_001)
            fields["savingsAmount"] = .integer(0)
            let invalid = try CloudSyncCodec.makeEnvelope(
                payload: CloudSyncPayload(
                    entityType: .incomeAllocation,
                    identity: envelope.payload?.identity ?? "",
                    fields: fields
                ),
                entityType: .incomeAllocation,
                identity: envelope.payload?.identity ?? "",
                operation: .upsert,
                revision: 1,
                parentSemanticDigest: nil,
                modifiedAt: fixedDate
            )
            return CloudSyncRemoteRecord(
                recordName: invalid.recordName,
                envelopeData: try CloudSyncCodec.encodeEnvelope(invalid),
                encodedSystemFields: nil,
                wasPhysicallyDeleted: false
            )
        }

        let destination = try DataController(isStoredInMemoryOnly: true)
        let destinationActor = destination.makeDataActor()
        _ = try await destinationActor.setCloudSyncEnabled(true, at: fixedDate)
        try await destinationActor.ingestCloudSyncRecords(records, receivedAt: fixedDate)

        #expect(try await destinationActor.modelCounts().incomeAllocations == 0)
        #expect(try await destinationActor.cloudSyncSnapshot().quarantinedCount == 1)
        #expect(try quarantinedReasons(in: destination) == [.localValidationFailed])
    }

    @Test
    func divergentRecurringClaimCannotReplaceTheAcceptedExpenseIdentity() async throws {
        let sourceController = try DataController(isStoredInMemoryOnly: true)
        let sourceActor = sourceController.makeDataActor()
        let seed = CloudSyncFactSeed()
        try await CloudSyncFactSeeder(modelContainer: sourceController.container)
            .insert(seed: seed, at: fixedDate)
        _ = try await sourceActor.setCloudSyncEnabled(true, at: fixedDate)
        let records = try await pendingRemoteRecords(using: sourceActor)
        let occurrenceRecord = try #require(
            records.first(where: { $0.recordName.hasPrefix("recurringOccurrence/") })
        )
        let first = try CloudSyncCodec.decodeEnvelope(try #require(occurrenceRecord.envelopeData))

        let destination = try DataController(isStoredInMemoryOnly: true)
        let destinationActor = destination.makeDataActor()
        _ = try await destinationActor.setCloudSyncEnabled(true, at: fixedDate)
        try await destinationActor.ingestCloudSyncRecords(records, receivedAt: fixedDate)

        let differentExpense = makeExpense(amountMinorUnits: 2_000)
        _ = try await destinationActor.createExpense(differentExpense)
        var changedFields = try #require(first.payload?.fields)
        changedFields["expenseID"] = .string(differentExpense.id.uuidString.lowercased())
        let divergent = try CloudSyncCodec.makeEnvelope(
            payload: CloudSyncPayload(
                entityType: .recurringOccurrence,
                identity: try #require(first.payload?.identity),
                fields: changedFields
            ),
            entityType: .recurringOccurrence,
            identity: try #require(first.payload?.identity),
            operation: .upsert,
            revision: 2,
            parentSemanticDigest: first.semanticDigest,
            modifiedAt: fixedDate.addingTimeInterval(1)
        )
        try await destinationActor.ingestCloudSyncRecords(
            [CloudSyncRemoteRecord(
                recordName: divergent.recordName,
                envelopeData: try CloudSyncCodec.encodeEnvelope(divergent),
                encodedSystemFields: nil,
                wasPhysicallyDeleted: false
            )],
            receivedAt: fixedDate.addingTimeInterval(1)
        )

        let context = ModelContext(destination.container)
        let occurrence = try #require(
            context.fetch(FetchDescriptor<RecurringExpenseOccurrence>()).first
        )
        #expect(occurrence.expenseID == seed.expenseID)
        #expect(try await destinationActor.cloudSyncSnapshot().quarantinedCount == 1)
        #expect(try quarantinedReasons(in: destination) == [.divergentConflict])
    }

    @Test
    func parentOwnedUpsertsRequireTheirParentIdentityField() async throws {
        let sourceController = try DataController(isStoredInMemoryOnly: true)
        let sourceActor = sourceController.makeDataActor()
        let seed = CloudSyncFactSeed()
        try await CloudSyncFactSeeder(modelContainer: sourceController.container)
            .insert(seed: seed, at: fixedDate)
        _ = try await sourceActor.setCloudSyncEnabled(true, at: fixedDate)

        let malformed = try await pendingRemoteRecords(using: sourceActor).compactMap { record -> CloudSyncRemoteRecord? in
            guard let data = record.envelopeData else { return nil }
            let envelope = try CloudSyncCodec.decodeEnvelope(data)
            let removedKey: String
            switch envelope.entityType {
            case .categoryBudget: removedKey = "planID"
            case .coolingOffPlan: removedKey = "wishItemID"
            default: return nil
            }
            var fields = try #require(envelope.payload?.fields)
            fields.removeValue(forKey: removedKey)
            let invalid = try CloudSyncCodec.makeEnvelope(
                payload: CloudSyncPayload(
                    entityType: envelope.entityType,
                    identity: try #require(envelope.payload?.identity),
                    fields: fields
                ),
                entityType: envelope.entityType,
                identity: try #require(envelope.payload?.identity),
                operation: .upsert,
                revision: 1,
                parentSemanticDigest: nil,
                modifiedAt: fixedDate
            )
            return CloudSyncRemoteRecord(
                recordName: invalid.recordName,
                envelopeData: try CloudSyncCodec.encodeEnvelope(invalid),
                encodedSystemFields: nil,
                wasPhysicallyDeleted: false
            )
        }
        #expect(malformed.count == 2)

        let destination = try DataController(isStoredInMemoryOnly: true)
        let destinationActor = destination.makeDataActor()
        _ = try await destinationActor.setCloudSyncEnabled(true, at: fixedDate)
        try await destinationActor.ingestCloudSyncRecords(malformed, receivedAt: fixedDate)

        #expect(try await destinationActor.modelCounts().categoryBudgets == 0)
        #expect(try await destinationActor.modelCounts().coolingOffPlans == 0)
        #expect(try await destinationActor.cloudSyncSnapshot().quarantinedCount == 2)
        #expect(try quarantinedReasons(in: destination) == [.malformedRecord, .malformedRecord])
    }

    @Test
    func duplicateRemoteDeliveryIsIdempotent() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234)
        _ = try await actor.createExpense(expense)
        let recordName = "expense/\(expense.id.uuidString.lowercased())"
        let pendingRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let pending = try #require(pendingRead)
        try await actor.acknowledgeCloudSyncRecord(
            recordName: recordName,
            encodedSystemFields: Data([1]),
            at: fixedDate
        )

        let remote = CloudSyncRemoteRecord(
            recordName: recordName,
            envelopeData: pending.envelopeData,
            encodedSystemFields: Data([2]),
            wasPhysicallyDeleted: false
        )
        try await actor.ingestCloudSyncRecords([remote], receivedAt: fixedDate)
        try await actor.ingestCloudSyncRecords([remote], receivedAt: fixedDate.addingTimeInterval(1))

        let summaries = try await actor.fetchExpenseSummaries()
        let snapshot = try await actor.cloudSyncSnapshot()
        #expect(summaries.count == 1)
        #expect(summaries.first?.amount.minorUnits == 1_234)
        #expect(snapshot.quarantinedCount == 0)
        let remainingPending = try await actor.pendingCloudSyncRecordNames()
        #expect(remainingPending.isEmpty)
    }

    @Test
    func localDeletionStagesALogicalTombstoneOnTheAcceptedLineage() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234)
        _ = try await actor.createExpense(expense)
        let recordName = "expense/\(expense.id.uuidString.lowercased())"
        let firstRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let first = try #require(firstRead)
        let firstEnvelope = try CloudSyncCodec.decodeEnvelope(first.envelopeData)
        try await actor.acknowledgeCloudSyncRecord(
            recordName: recordName,
            encodedSystemFields: Data([1]),
            at: fixedDate
        )

        try await actor.deleteExpense(id: expense.id)

        let tombstoneRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let tombstonePending = try #require(tombstoneRead)
        let tombstone = try CloudSyncCodec.decodeEnvelope(tombstonePending.envelopeData)
        #expect(tombstone.operation == .tombstone)
        #expect(tombstone.payload == nil)
        #expect(tombstone.revision == 2)
        #expect(tombstone.parentSemanticDigest == firstEnvelope.semanticDigest)
    }

    @Test
    func cascadeDeletionStagesAndAppliesChildBeforeParentTombstones() async throws {
        let sourceActor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let wishID = UUID()
        let coolingID = UUID()
        let reviewAt = try #require(
            Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: fixedDate)
        )
        _ = try await sourceActor.createWishItem(
            WishItemDraft(
                id: wishID,
                name: "Private wish",
                estimatedPrice: Money(minorUnits: 5_000, currencyCode: "USD"),
                currencyCode: "USD",
                category: .shopping,
                reason: .convenience,
                emotionTag: nil,
                sourceContextLabel: nil,
                createdAt: fixedDate,
                updatedAt: fixedDate,
                coolingOffHours: 24,
                targetReviewDate: reviewAt,
                status: .coolingOff,
                notes: "private note",
                purchasedExpenseId: nil
            )
        )
        _ = try await sourceActor.createCoolingOffPlan(
            CoolingOffPlanDraft(
                id: coolingID,
                wishItemId: wishID,
                startedAt: fixedDate,
                reviewAt: reviewAt,
                durationHours: 24,
                status: .active,
                notificationIdentifier: "local-only",
                completedAt: nil,
                outcome: nil,
                outcomeRecordedAt: nil
            )
        )
        _ = try await sourceActor.setCloudSyncEnabled(true, at: fixedDate)

        let initialNames = try await sourceActor.pendingCloudSyncRecordNames()
        #expect(initialNames == [
            "coolingOffPlan/\(coolingID.uuidString.lowercased())",
            "wishItem/\(wishID.uuidString.lowercased())"
        ])
        var initialRecords: [CloudSyncRemoteRecord] = []
        for name in initialNames {
            let pending = try #require(try await sourceActor.pendingCloudSyncRecord(named: name))
            initialRecords.append(
                CloudSyncRemoteRecord(
                    recordName: name,
                    envelopeData: pending.envelopeData,
                    encodedSystemFields: nil,
                    wasPhysicallyDeleted: false
                )
            )
            try await sourceActor.acknowledgeCloudSyncRecord(
                recordName: name,
                encodedSystemFields: Data([1]),
                at: fixedDate
            )
        }

        let destinationActor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await destinationActor.setCloudSyncEnabled(true, at: fixedDate)
        try await destinationActor.ingestCloudSyncRecords(initialRecords, receivedAt: fixedDate)
        #expect(try await destinationActor.modelCounts().wishItems == 1)
        #expect(try await destinationActor.modelCounts().coolingOffPlans == 1)

        try await sourceActor.deleteWishItem(id: wishID)
        let tombstoneNames = try await sourceActor.pendingCloudSyncRecordNames()
        #expect(Set(tombstoneNames) == Set(initialNames))
        var tombstones: [CloudSyncRemoteRecord] = []
        for name in tombstoneNames {
            let pending = try #require(try await sourceActor.pendingCloudSyncRecord(named: name))
            #expect(try CloudSyncCodec.decodeEnvelope(pending.envelopeData).operation == .tombstone)
            tombstones.append(
                CloudSyncRemoteRecord(
                    recordName: name,
                    envelopeData: pending.envelopeData,
                    encodedSystemFields: nil,
                    wasPhysicallyDeleted: false
                )
            )
        }
        try await destinationActor.ingestCloudSyncRecords(
            Array(tombstones.reversed()),
            receivedAt: fixedDate.addingTimeInterval(1)
        )

        #expect(try await destinationActor.modelCounts().wishItems == 0)
        #expect(try await destinationActor.modelCounts().coolingOffPlans == 0)
        #expect(try await destinationActor.cloudSyncSnapshot().quarantinedCount == 0)
    }

    @Test
    func divergentRemoteFactIsQuarantinedWithoutReplacingLocalAuthority() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let original = makeExpense(amountMinorUnits: 1_000)
        _ = try await actor.createExpense(original)
        let recordName = "expense/\(original.id.uuidString.lowercased())"
        let firstPendingRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let firstPending = try #require(firstPendingRead)
        let firstEnvelope = try CloudSyncCodec.decodeEnvelope(firstPending.envelopeData)
        try await actor.acknowledgeCloudSyncRecord(
            recordName: recordName,
            encodedSystemFields: Data([1]),
            at: fixedDate
        )

        let localUpdate = makeExpense(
            id: original.id,
            amountMinorUnits: 2_000,
            updatedAt: fixedDate.addingTimeInterval(1)
        )
        _ = try await actor.updateExpense(id: original.id, with: localUpdate)

        var remoteFields = try #require(firstEnvelope.payload?.fields)
        remoteFields["amount"] = .integer(3_000)
        remoteFields["updatedAt"] = .unsigned(fixedDate.addingTimeInterval(2).cloudSyncBits)
        let remotePayload = CloudSyncPayload(
            entityType: .expense,
            identity: original.id.uuidString.lowercased(),
            fields: remoteFields
        )
        let remoteEnvelope = try CloudSyncCodec.makeEnvelope(
            payload: remotePayload,
            entityType: .expense,
            identity: original.id.uuidString.lowercased(),
            operation: .upsert,
            revision: 2,
            parentSemanticDigest: firstEnvelope.semanticDigest,
            modifiedAt: fixedDate.addingTimeInterval(2)
        )
        try await actor.ingestCloudSyncRecords(
            [CloudSyncRemoteRecord(
                recordName: recordName,
                envelopeData: try CloudSyncCodec.encodeEnvelope(remoteEnvelope),
                encodedSystemFields: Data([2]),
                wasPhysicallyDeleted: false
            )],
            receivedAt: fixedDate.addingTimeInterval(2)
        )

        let summaries = try await actor.fetchExpenseSummaries()
        let snapshot = try await actor.cloudSyncSnapshot()
        #expect(summaries.first?.amount.minorUnits == 2_000)
        #expect(snapshot.quarantinedCount == 1)
    }

    @Test
    func malformedAndPhysicalDeletionRecordsNeverMutateLocalFacts() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234)
        _ = try await actor.createExpense(expense)
        let recordName = "expense/\(expense.id.uuidString.lowercased())"

        try await actor.ingestCloudSyncRecords(
            [
                CloudSyncRemoteRecord(
                    recordName: "income/\(UUID().uuidString.lowercased())",
                    envelopeData: Data("{}".utf8),
                    encodedSystemFields: nil,
                    wasPhysicallyDeleted: false
                ),
                CloudSyncRemoteRecord(
                    recordName: recordName,
                    envelopeData: nil,
                    encodedSystemFields: nil,
                    wasPhysicallyDeleted: true
                )
            ],
            receivedAt: fixedDate
        )

        let summaries = try await actor.fetchExpenseSummaries()
        let snapshot = try await actor.cloudSyncSnapshot()
        #expect(summaries.map(\.id) == [expense.id])
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
        #expect(snapshot.quarantinedCount == 2)
    }

    @Test
    func sameFetchBatchAppliesRevisionsInLineageOrder() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234)
        let identity = expense.id.uuidString.lowercased()
        let fields = try await stagedExpenseFields(expense, using: actor)
        let firstPayload = CloudSyncPayload(entityType: .expense, identity: identity, fields: fields)
        let first = try CloudSyncCodec.makeEnvelope(
            payload: firstPayload,
            entityType: .expense,
            identity: identity,
            operation: .upsert,
            revision: 1,
            parentSemanticDigest: nil,
            modifiedAt: fixedDate
        )
        var updatedFields = fields
        updatedFields["amount"] = .integer(2_345)
        updatedFields["updatedAt"] = .unsigned(fixedDate.addingTimeInterval(1).cloudSyncBits)
        let second = try CloudSyncCodec.makeEnvelope(
            payload: CloudSyncPayload(entityType: .expense, identity: identity, fields: updatedFields),
            entityType: .expense,
            identity: identity,
            operation: .upsert,
            revision: 2,
            parentSemanticDigest: first.semanticDigest,
            modifiedAt: fixedDate.addingTimeInterval(1)
        )

        let remoteRecords = try [second, first].map {
                CloudSyncRemoteRecord(
                    recordName: $0.recordName,
                    envelopeData: try CloudSyncCodec.encodeEnvelope($0),
                    encodedSystemFields: nil,
                    wasPhysicallyDeleted: false
                )
            }
        try await actor.ingestCloudSyncRecords(
            remoteRecords,
            receivedAt: fixedDate
        )

        let summaries = try await actor.fetchExpenseSummaries()
        #expect(summaries.first?.amount.minorUnits == 2_345)
        #expect(try await actor.cloudSyncSnapshot().quarantinedCount == 0)
    }

    @Test
    func acceptedTombstoneCannotBeResurrectedByABackgroundDescendant() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234)
        _ = try await actor.createExpense(expense)
        let recordName = "expense/\(expense.id.uuidString.lowercased())"
        let firstRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let first = try #require(firstRead)
        let firstEnvelope = try CloudSyncCodec.decodeEnvelope(first.envelopeData)
        try await actor.acknowledgeCloudSyncRecord(
            recordName: recordName,
            encodedSystemFields: Data([1]),
            at: fixedDate
        )
        try await actor.deleteExpense(id: expense.id)
        let tombstoneRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let tombstonePending = try #require(tombstoneRead)
        let tombstone = try CloudSyncCodec.decodeEnvelope(tombstonePending.envelopeData)
        try await actor.acknowledgeCloudSyncRecord(
            recordName: recordName,
            encodedSystemFields: Data([2]),
            at: fixedDate
        )

        let resurrection = try CloudSyncCodec.makeEnvelope(
            payload: firstEnvelope.payload,
            entityType: .expense,
            identity: expense.id.uuidString.lowercased(),
            operation: .upsert,
            revision: 3,
            parentSemanticDigest: tombstone.semanticDigest,
            modifiedAt: fixedDate.addingTimeInterval(2)
        )
        try await actor.ingestCloudSyncRecords(
            [CloudSyncRemoteRecord(
                recordName: recordName,
                envelopeData: try CloudSyncCodec.encodeEnvelope(resurrection),
                encodedSystemFields: Data([3]),
                wasPhysicallyDeleted: false
            )],
            receivedAt: fixedDate.addingTimeInterval(2)
        )

        #expect(try await actor.fetchExpenseSummaries().isEmpty)
        #expect(try await actor.cloudSyncSnapshot().quarantinedCount == 1)
    }

    @Test
    func accountChangePausesUntilAnExplicitDisableAndReenableConsent() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let acceptedA = try await actor.bindCloudSyncAccount(identifierHash: "account-a", at: fixedDate)
        #expect(acceptedA)
        let expense = makeExpense(amountMinorUnits: 1_234)
        _ = try await actor.createExpense(expense)
        let recordName = "expense/\(expense.id.uuidString.lowercased())"
        let firstRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let first = try #require(firstRead)
        let firstEnvelope = try CloudSyncCodec.decodeEnvelope(first.envelopeData)
        try await actor.acknowledgeCloudSyncRecord(
            recordName: recordName,
            encodedSystemFields: Data([1]),
            at: fixedDate
        )
        _ = try await actor.updateExpense(
            id: expense.id,
            with: makeExpense(
                id: expense.id,
                amountMinorUnits: 2_345,
                updatedAt: fixedDate.addingTimeInterval(1)
            )
        )
        let oldAccountRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let oldAccountPending = try #require(oldAccountRead)
        let oldAccountEnvelope = try CloudSyncCodec.decodeEnvelope(oldAccountPending.envelopeData)
        #expect(oldAccountEnvelope.revision == 2)
        #expect(oldAccountEnvelope.parentSemanticDigest == firstEnvelope.semanticDigest)

        let acceptedBWithoutConsent = try await actor.bindCloudSyncAccount(
            identifierHash: "account-b",
            at: fixedDate
        )
        let pausedSnapshot = try await actor.cloudSyncSnapshot()
        #expect(!acceptedBWithoutConsent)
        #expect(pausedSnapshot.status == .pausedAccountChanged)

        _ = try await actor.setCloudSyncEnabled(false, at: fixedDate)
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let rebasedRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let rebased = try #require(rebasedRead)
        let rebasedEnvelope = try CloudSyncCodec.decodeEnvelope(rebased.envelopeData)
        #expect(rebasedEnvelope.revision == 1)
        #expect(rebasedEnvelope.parentSemanticDigest == nil)
        #expect(rebasedEnvelope.payload?.fields["amount"]?.validatedInteger == 2_345)
        let acceptedBAfterConsent = try await actor.bindCloudSyncAccount(
            identifierHash: "account-b",
            at: fixedDate
        )
        #expect(acceptedBAfterConsent)
    }

    @Test
    func encryptedDataResetCannotBeClearedByTheGenericEnableDisclosure() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234)
        _ = try await actor.createExpense(expense)
        try await actor.updateCloudSyncStatus(
            .pausedEncryptedDataReset,
            reason: .encryptedDataReset,
            at: fixedDate
        )

        let disabled = try await actor.setCloudSyncEnabled(false, at: fixedDate)
        let genericReenable = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let summaries = try await actor.fetchExpenseSummaries()

        #expect(!disabled.isEnabled)
        #expect(disabled.status == .pausedEncryptedDataReset)
        #expect(!genericReenable.isEnabled)
        #expect(genericReenable.status == .pausedEncryptedDataReset)
        #expect(genericReenable.reason == .encryptedDataReset)
        #expect(summaries.map(\.id) == [expense.id])
    }

    @Test
    func deletedRemoteZoneCannotBeRecreatedByGenericDisableAndReenable() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234)
        _ = try await actor.createExpense(expense)
        try await actor.updateCloudSyncStatus(
            .pausedRemoteZoneDeleted,
            reason: .remoteZoneDeleted,
            at: fixedDate
        )

        let disabled = try await actor.setCloudSyncEnabled(false, at: fixedDate)
        let genericReenable = try await actor.setCloudSyncEnabled(true, at: fixedDate)

        #expect(!disabled.isEnabled)
        #expect(disabled.status == .pausedRemoteZoneDeleted)
        #expect(!genericReenable.isEnabled)
        #expect(genericReenable.status == .pausedRemoteZoneDeleted)
        #expect(genericReenable.reason == .remoteZoneDeleted)
        #expect(try await actor.fetchExpenseSummaries().map(\.id) == [expense.id])
    }

    @Test
    func serverSaveConflictLeavesTheOutboxBlockedAndTheRemoteCandidateQuarantined() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 1_234)
        _ = try await actor.createExpense(expense)
        let recordName = "expense/\(expense.id.uuidString.lowercased())"

        try await actor.blockCloudSyncRecordAfterServerConflict(
            recordName: recordName,
            at: fixedDate
        )
        try await actor.ingestCloudSyncRecords(
            [CloudSyncRemoteRecord(
                recordName: recordName,
                envelopeData: nil,
                encodedSystemFields: nil,
                wasPhysicallyDeleted: false
            )],
            receivedAt: fixedDate
        )

        let snapshot = try await actor.cloudSyncSnapshot()
        let summary = try #require(try await actor.cloudSyncConflictSummaries().first)
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
        #expect(snapshot.pendingCount == 0)
        #expect(snapshot.quarantinedCount == 1)
        #expect(!summary.canResolve)
        #expect(summary.localOperation == .upsert)
        #expect(summary.cloudOperation == nil)
        await #expect(throws: CloudSyncApplicationError.self) {
            try await actor.resolveCloudSyncConflict(
                recordName: recordName,
                resolution: .keepLocal,
                at: fixedDate.addingTimeInterval(1)
            )
        }
        #expect(try await actor.cloudSyncSnapshot().quarantinedCount == 1)
        #expect(try await actor.fetchExpenseSummaries().first?.amount.minorUnits == 1_234)
    }

    @Test
    func explicitConflictResolutionAuthorsADescendantOrAcceptsTheCloudCandidate() async throws {
        for resolution in [CloudSyncConflictResolution.keepLocal, .useCloud] {
            let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
            _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
            let original = makeExpense(amountMinorUnits: 1_000)
            _ = try await actor.createExpense(original)
            let recordName = "expense/\(original.id.uuidString.lowercased())"
            let first = try #require(try await actor.pendingCloudSyncRecord(named: recordName))
            let firstEnvelope = try CloudSyncCodec.decodeEnvelope(first.envelopeData)
            try await actor.acknowledgeCloudSyncRecord(
                recordName: recordName,
                encodedSystemFields: Data([1]),
                at: fixedDate
            )
            _ = try await actor.updateExpense(
                id: original.id,
                with: makeExpense(
                    id: original.id,
                    amountMinorUnits: 2_000,
                    updatedAt: fixedDate.addingTimeInterval(1)
                )
            )

            var remoteFields = try #require(firstEnvelope.payload?.fields)
            remoteFields["amount"] = .integer(3_000)
            remoteFields["updatedAt"] = .unsigned(
                fixedDate.addingTimeInterval(2).cloudSyncBits
            )
            let remote = try CloudSyncCodec.makeEnvelope(
                payload: CloudSyncPayload(
                    entityType: .expense,
                    identity: original.id.uuidString.lowercased(),
                    fields: remoteFields
                ),
                entityType: .expense,
                identity: original.id.uuidString.lowercased(),
                operation: .upsert,
                revision: 2,
                parentSemanticDigest: firstEnvelope.semanticDigest,
                modifiedAt: fixedDate.addingTimeInterval(2)
            )
            try await actor.ingestCloudSyncRecords(
                [CloudSyncRemoteRecord(
                    recordName: recordName,
                    envelopeData: try CloudSyncCodec.encodeEnvelope(remote),
                    encodedSystemFields: Data([2]),
                    wasPhysicallyDeleted: false
                )],
                receivedAt: fixedDate.addingTimeInterval(2)
            )

            let summary = try #require(try await actor.cloudSyncConflictSummaries().first)
            #expect(summary.canResolve)
            #expect(summary.localOperation == .upsert)
            #expect(summary.cloudOperation == .upsert)
            try await actor.resolveCloudSyncConflict(
                recordName: recordName,
                resolution: resolution,
                at: fixedDate.addingTimeInterval(3)
            )

            #expect(try await actor.cloudSyncSnapshot().quarantinedCount == 0)
            let amount = try await actor.fetchExpenseSummaries().first?.amount.minorUnits
            if resolution == .keepLocal {
                #expect(amount == 2_000)
                let pending = try #require(
                    try await actor.pendingCloudSyncRecord(named: recordName)
                )
                let descendant = try CloudSyncCodec.decodeEnvelope(pending.envelopeData)
                #expect(descendant.revision == 3)
                #expect(descendant.parentSemanticDigest == remote.semanticDigest)
            } else {
                #expect(amount == 3_000)
                #expect(try await actor.pendingCloudSyncRecord(named: recordName) == nil)
            }
        }
    }

    @Test
    func explicitConflictResolutionNeverSilentlyChoosesBetweenKeepingAndDeleting() async throws {
        for resolution in [CloudSyncConflictResolution.keepLocal, .useCloud] {
            let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
            _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
            let expense = makeExpense(amountMinorUnits: 1_000)
            _ = try await actor.createExpense(expense)
            let recordName = "expense/\(expense.id.uuidString.lowercased())"
            let first = try #require(try await actor.pendingCloudSyncRecord(named: recordName))
            let firstEnvelope = try CloudSyncCodec.decodeEnvelope(first.envelopeData)
            try await actor.acknowledgeCloudSyncRecord(
                recordName: recordName,
                encodedSystemFields: Data([1]),
                at: fixedDate
            )
            _ = try await actor.updateExpense(
                id: expense.id,
                with: makeExpense(
                    id: expense.id,
                    amountMinorUnits: 2_000,
                    updatedAt: fixedDate.addingTimeInterval(1)
                )
            )
            let remoteTombstone = try CloudSyncCodec.makeEnvelope(
                payload: nil,
                entityType: .expense,
                identity: expense.id.uuidString.lowercased(),
                operation: .tombstone,
                revision: 2,
                parentSemanticDigest: firstEnvelope.semanticDigest,
                modifiedAt: fixedDate.addingTimeInterval(2)
            )
            try await actor.ingestCloudSyncRecords(
                [CloudSyncRemoteRecord(
                    recordName: recordName,
                    envelopeData: try CloudSyncCodec.encodeEnvelope(remoteTombstone),
                    encodedSystemFields: Data([2]),
                    wasPhysicallyDeleted: false
                )],
                receivedAt: fixedDate.addingTimeInterval(2)
            )

            let summary = try #require(try await actor.cloudSyncConflictSummaries().first)
            #expect(summary.localOperation == .upsert)
            #expect(summary.cloudOperation == .tombstone)
            try await actor.resolveCloudSyncConflict(
                recordName: recordName,
                resolution: resolution,
                at: fixedDate.addingTimeInterval(3)
            )

            if resolution == .keepLocal {
                #expect(try await actor.fetchExpenseSummaries().map(\.id) == [expense.id])
                let pending = try #require(
                    try await actor.pendingCloudSyncRecord(named: recordName)
                )
                let descendant = try CloudSyncCodec.decodeEnvelope(pending.envelopeData)
                #expect(descendant.operation == .upsert)
                #expect(descendant.revision == 3)
                #expect(descendant.parentSemanticDigest == remoteTombstone.semanticDigest)
            } else {
                #expect(try await actor.fetchExpenseSummaries().isEmpty)
                #expect(try await actor.pendingCloudSyncRecord(named: recordName) == nil)
            }
        }
    }

    @Test
    @MainActor
    func retainedCloudCopyRequiresExplicitReimportConfirmation() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let probe = CloudSyncAdapterProbe()
        let retention = TestCloudSyncRetentionStore(cloudCopyMayExist: true)
        let service = CloudSyncService(
            dataActor: actor,
            adapterFactory: { _ in probe.makeAdapter() },
            retentionStore: retention
        )

        await service.setEnabled(true)
        #expect(!service.snapshot.isEnabled)
        #expect(service.snapshot.cloudCopyMayExist)
        #expect(probe.creationCount == 0)

        await service.setEnabled(true, reimportConfirmed: true)
        #expect(service.snapshot.isEnabled)
        #expect(probe.creationCount == 1)
    }

    @Test
    func cloudDeletionGuidanceExposesClosedRetryReasonsWithoutReuploadPromises() {
        func snapshot(reason: CloudSyncReasonCode?) -> CloudSyncSnapshot {
            CloudSyncSnapshot(
                isEnabled: true,
                status: .deletingCloudData,
                reason: reason,
                pendingCount: 1,
                quarantinedCount: 0,
                cloudCopyMayExist: true
            )
        }

        #expect(CloudSyncSettingsPresentation.cloudDeletionGuidance(
            for: snapshot(reason: nil)
        ) == .pending)
        #expect(CloudSyncSettingsPresentation.cloudDeletionGuidance(
            for: snapshot(reason: .networkUnavailable)
        ) == .network)
        #expect(CloudSyncSettingsPresentation.cloudDeletionGuidance(
            for: snapshot(reason: .noAccount)
        ) == .account)
        #expect(CloudSyncSettingsPresentation.cloudDeletionGuidance(
            for: snapshot(reason: .quotaExceeded)
        ) == .quota)
        #expect(CloudSyncSettingsPresentation.cloudDeletionGuidance(
            for: snapshot(reason: .transportFailed)
        ) == .failed)
        #expect(CloudSyncSettingsPresentation.cloudDeletionGuidance(for: .disabled) == nil)
    }

    @Test
    @MainActor
    func enabledPreMarkerStateConservativelyRecordsThatACloudCopyMayExist() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let retention = TestCloudSyncRetentionStore(cloudCopyMayExist: false)
        let service = CloudSyncService(
            dataActor: actor,
            adapterFactory: { _ in TestCloudSyncAdapter() },
            retentionStore: retention
        )

        await service.start()

        #expect(retention.cloudCopyMayExist)
        #expect(service.snapshot.cloudCopyMayExist)
    }

    @Test
    @MainActor
    func cloudWideDeleteKeepsLocalFactsAndClearsOnlyAfterZoneConfirmation() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 4_200)
        _ = try await actor.createExpense(expense)
        let probe = CloudSyncAdapterProbe()
        let retention = TestCloudSyncRetentionStore(cloudCopyMayExist: true)
        probe.adapter.deleteHandler = {
            try? await actor.completeCloudDeletion()
            return .deleted
        }
        let service = CloudSyncService(
            dataActor: actor,
            adapterFactory: { _ in probe.makeAdapter() },
            retentionStore: retention
        )

        let outcome = await service.deleteCloudData()

        #expect(outcome == .deleted)
        #expect(probe.adapter.deleteCloudDataCount == 1)
        #expect(!retention.cloudCopyMayExist)
        #expect(!service.snapshot.isEnabled)
        #expect(try await actor.fetchExpenseSummaries().map(\.id) == [expense.id])
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
    }

    @Test
    @MainActor
    func offlineCloudDeleteRemainsDurableAndStickyRecoveryRequiresExplicitAction() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 5_500)
        _ = try await actor.createExpense(expense)
        let probe = CloudSyncAdapterProbe()
        probe.adapter.deletionOutcome = .pending(.networkUnavailable)
        let retention = TestCloudSyncRetentionStore(cloudCopyMayExist: true)
        let service = CloudSyncService(
            dataActor: actor,
            adapterFactory: { _ in probe.makeAdapter() },
            retentionStore: retention
        )

        #expect(await service.deleteCloudData() == .pending(.networkUnavailable))
        #expect(service.snapshot.status == .deletingCloudData)
        #expect(service.snapshot.cloudCopyMayExist)
        let pending = try await actor.pendingCloudSyncRecordNames()
        #expect(pending == ["expense/\(expense.id.uuidString.lowercased())"])
        let tombstone = try #require(
            try await actor.pendingCloudSyncRecord(named: pending[0])
        )
        #expect(try CloudSyncCodec.decodeEnvelope(tombstone.envelopeData).operation == .tombstone)

        // A generic enable/disable cannot abandon the pending privacy operation.
        _ = try await actor.setCloudSyncEnabled(false, at: fixedDate.addingTimeInterval(1))
        #expect(try await actor.cloudSyncSnapshot().status == .deletingCloudData)

        // A new service instance resumes the durable privacy operation; it does not recreate the
        // zone or abandon deletion merely because the original process ended while offline.
        await service.stop()
        let resumedProbe = CloudSyncAdapterProbe()
        resumedProbe.adapter.deleteHandler = {
            try? await actor.completeCloudDeletion()
            return .deleted
        }
        let resumedService = CloudSyncService(
            dataActor: actor,
            adapterFactory: { _ in resumedProbe.makeAdapter() },
            retentionStore: retention
        )
        await resumedService.start()
        #expect(resumedProbe.adapter.deleteCloudDataCount == 1)
        #expect(!resumedService.snapshot.isEnabled)
        #expect(!retention.cloudCopyMayExist)
        #expect(try await actor.fetchExpenseSummaries().map(\.id) == [expense.id])
    }

    @Test
    @MainActor
    func stickyPauseRebuildsCloudOnlyAfterTheExplicitRecoveryDecision() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        let expense = makeExpense(amountMinorUnits: 6_600)
        _ = try await actor.createExpense(expense)
        try await actor.updateCloudSyncStatus(
            .pausedEncryptedDataReset,
            reason: .encryptedDataReset,
            at: fixedDate
        )
        let probe = CloudSyncAdapterProbe()
        let service = CloudSyncService(
            dataActor: actor,
            adapterFactory: { _ in probe.makeAdapter() },
            retentionStore: TestCloudSyncRetentionStore(cloudCopyMayExist: true)
        )
        await service.start()
        #expect(probe.creationCount == 0)

        #expect(await service.recoverFromTrustBoundary(.rebuildCloudFromLocal))
        #expect(probe.creationCount == 1)
        #expect(try await actor.pendingCloudSyncRecordNames() == [
            "expense/\(expense.id.uuidString.lowercased())"
        ])
    }

    @Test(.enabled(if: Self.runsPhysicalCloudKitRuntimeTests))
    @MainActor
    func physicalDevelopmentCloudKitRoundTripPreservesLocalFactsAndDeletesTheZone() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let expense = makeExpense(amountMinorUnits: 4_203, merchantName: "C4B03 runtime probe")
        _ = try await actor.createExpense(expense)
        let retention = TestCloudSyncRetentionStore(cloudCopyMayExist: false)
        let service = CloudSyncService(dataActor: actor, retentionStore: retention)

        await service.setEnabled(true)
        #expect(service.snapshot.status == .ready)
        #expect(service.snapshot.isEnabled)
        #expect(retention.cloudCopyMayExist)
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)

        await service.setEnabled(false)
        #expect(!service.snapshot.isEnabled)
        #expect(retention.cloudCopyMayExist)

        await service.setEnabled(true, reimportConfirmed: true)
        #expect(service.snapshot.status == .ready)
        #expect(service.snapshot.isEnabled)

        let deletion = await service.deleteCloudData()
        #expect(deletion == .deleted)
        #expect(!service.snapshot.isEnabled)
        #expect(!retention.cloudCopyMayExist)
        #expect(try await actor.fetchExpenseSummaries().map(\.id) == [expense.id])
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)

        await service.stop()
    }

    @Test(.enabled(if: Self.runsPhysicalCloudKitBackgroundPush))
    @MainActor
    func physicalBackgroundPushFetchesAnExternalDeletionWithoutForegroundRetry() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let retention = TestCloudSyncRetentionStore(cloudCopyMayExist: true)
        let service = CloudSyncService(dataActor: actor, retentionStore: retention)

        // Make a stopped probe repeatable. This removes only the fixed Development test zone; the
        // Production environment and the in-memory local authority are never addressed.
        let initialCleanup = await service.deleteCloudData()
        #expect(initialCleanup == .deleted)
        guard initialCleanup == .deleted else {
            await service.stop()
            return
        }

        let expense = makeExpense(
            id: Self.backgroundPushExpenseID,
            amountMinorUnits: 4_204,
            merchantName: "C4B03 background push probe",
            updatedAt: fixedDate
        )
        _ = try await actor.createExpense(expense)
        await service.setEnabled(true)
        let reachedReady = service.snapshot.status == .ready
        let emptiedOutbox = try await actor.pendingCloudSyncRecordNames().isEmpty
        #expect(reachedReady)
        #expect(emptiedOutbox)
        guard reachedReady, emptiedOutbox else {
            _ = await service.deleteCloudData()
            await service.stop()
            return
        }

        let recordName = "expense/\(Self.backgroundPushExpenseID.uuidString.lowercased())"
        print("C4B03 background-push READY record=\(recordName)")
        print("C4B03 background-push now requires an external Development deletion while the app is backgrounded")

        // Deliberately do not call service.retry(), synchronize(), or sceneDidBecomeActive(). The
        // only accepted success path is CKSyncEngine's subscription/notification scheduler fetching
        // the external physical deletion and quarantining it without mutating the local fact.
        let clock = ContinuousClock()
        // This opt-in proof includes an owner-assisted CloudKit Console deletion. Allow enough
        // time for the Console's separate "Act As iCloud Account" authentication without turning
        // authentication latency into a false background-delivery failure.
        let deadline = clock.now.advanced(by: .seconds(600))
        var observedExternalDeletion = false
        while clock.now < deadline {
            try Task.checkCancellation()
            let snapshot = try await actor.cloudSyncSnapshot()
            if snapshot.quarantinedCount == 1 {
                observedExternalDeletion = true
                break
            }
            try await clock.sleep(for: .seconds(1))
        }

        let localExpense = try await actor.fetchExpenseSummaries().first(where: {
            $0.id == Self.backgroundPushExpenseID
        })
        let cleanup = await service.deleteCloudData()
        await service.stop()

        #expect(observedExternalDeletion)
        #expect(localExpense?.amount.minorUnits == 4_204)
        #expect(cleanup == .deleted)
        #expect(!retention.cloudCopyMayExist)
    }

    @Test(.enabled(if: Self.runsPhysicalCloudKitMultiDevicePrimary))
    @MainActor
    func physicalMultiDevicePrimarySeedsObservesTheRemoteUpdateAndDeletesTheZone() async throws {
        print("C4B03 multi-device primary account fingerprint: \(try await physicalCloudKitAccountFingerprint())")
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let retention = TestCloudSyncRetentionStore(cloudCopyMayExist: true)
        let service = CloudSyncService(dataActor: actor, retentionStore: retention)

        // Make an interrupted evidence run repeatable. Only this accepted fixed Development zone
        // is removed; the local in-memory authority and Production environment are untouched.
        #expect(await service.deleteCloudData() == .deleted)

        let expense = makeExpense(
            id: Self.multiDeviceExpenseID,
            amountMinorUnits: Self.multiDeviceSeedAmount,
            merchantName: "C4B03 primary device",
            updatedAt: fixedDate
        )
        _ = try await actor.createExpense(expense)

        await service.setEnabled(true)
        #expect(service.snapshot.status == .ready)
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)

        let observedSecondaryUpdate = try await waitForPhysicalCloudExpense(
            id: Self.multiDeviceExpenseID,
            amountMinorUnits: Self.multiDeviceUpdatedAmount,
            using: service,
            actor: actor
        )
        let localFactsBeforeDeletion = try await actor.fetchExpenseSummaries()

        // The fixed Development zone is test-owned. The primary device is the sole cleanup owner
        // so the secondary cannot race zone deletion with the primary's final fetch.
        let deletion = await service.deleteCloudData()

        #expect(observedSecondaryUpdate)
        #expect(localFactsBeforeDeletion.first(where: { $0.id == Self.multiDeviceExpenseID })?.amount.minorUnits
            == Self.multiDeviceUpdatedAmount)
        #expect(deletion == .deleted)
        #expect(!retention.cloudCopyMayExist)
        #expect(try await actor.fetchExpenseSummaries().first(where: {
            $0.id == Self.multiDeviceExpenseID
        })?.amount.minorUnits == Self.multiDeviceUpdatedAmount)
        await service.stop()
    }

    @Test(.enabled(if: Self.runsPhysicalCloudKitMultiDeviceSecondary))
    @MainActor
    func physicalMultiDeviceSecondaryImportsTheSeedAndPublishesAnUpdate() async throws {
        print("C4B03 multi-device secondary account fingerprint: \(try await physicalCloudKitAccountFingerprint())")
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let retention = TestCloudSyncRetentionStore(cloudCopyMayExist: false)
        let service = CloudSyncService(dataActor: actor, retentionStore: retention)

        await service.setEnabled(true)
        let importedPrimarySeed = try await waitForPhysicalCloudExpense(
            id: Self.multiDeviceExpenseID,
            amountMinorUnits: Self.multiDeviceSeedAmount,
            using: service,
            actor: actor
        )
        #expect(importedPrimarySeed)

        if importedPrimarySeed {
            let update = makeExpense(
                id: Self.multiDeviceExpenseID,
                amountMinorUnits: Self.multiDeviceUpdatedAmount,
                merchantName: "C4B03 secondary device",
                updatedAt: fixedDate.addingTimeInterval(60)
            )
            _ = try await actor.updateExpense(id: Self.multiDeviceExpenseID, with: update)
            await service.retry()
            let published = try await waitForPhysicalCloudOutboxToDrain(
                using: service,
                actor: actor
            )
            #expect(published)
            #expect(service.snapshot.status == .ready)
        }

        await service.stop()
    }

    private nonisolated static var runsPhysicalCloudKitRuntimeTests: Bool {
#if targetEnvironment(simulator)
        false
#elseif MINDBUDGET_PHYSICAL_CLOUDKIT_TESTS
        true
#else
        false
#endif
    }

    private nonisolated static var runsPhysicalCloudKitMultiDevicePrimary: Bool {
#if targetEnvironment(simulator)
        false
#elseif MINDBUDGET_PHYSICAL_CLOUDKIT_MULTI_DEVICE_PRIMARY
        true
#else
        false
#endif
    }

    private nonisolated static var runsPhysicalCloudKitBackgroundPush: Bool {
#if targetEnvironment(simulator)
        false
#elseif MINDBUDGET_PHYSICAL_CLOUDKIT_BACKGROUND_PUSH
        true
#else
        false
#endif
    }

    private nonisolated static var runsPhysicalCloudKitMultiDeviceSecondary: Bool {
#if targetEnvironment(simulator)
        false
#elseif MINDBUDGET_PHYSICAL_CLOUDKIT_MULTI_DEVICE_SECONDARY
        true
#else
        false
#endif
    }

    private nonisolated static let multiDeviceExpenseID = UUID(
        uuidString: "c4b03000-0000-4000-8000-000000000203"
    )!
    private nonisolated static let backgroundPushExpenseID = UUID(
        uuidString: "c4b03000-0000-4000-8000-000000000204"
    )!
    private nonisolated static let multiDeviceSeedAmount: Int64 = 4_203
    private nonisolated static let multiDeviceUpdatedAmount: Int64 = 8_406

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_784_851_200)
    }

    private func waitForPhysicalCloudExpense(
        id: UUID,
        amountMinorUnits: Int64,
        using service: CloudSyncService,
        actor: DataActor,
        timeout: Duration = .seconds(120)
    ) async throws -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            try Task.checkCancellation()
            await service.retry()
            if try await actor.fetchExpenseSummaries().contains(where: {
                $0.id == id && $0.amount.minorUnits == amountMinorUnits
            }) {
                return true
            }
            try await clock.sleep(for: .seconds(2))
        }
        return false
    }

    private func physicalCloudKitAccountFingerprint() async throws -> String {
        let container = CKContainer(identifier: CKSyncEngineAdapter.containerIdentifier)
        let status = try await container.accountStatus()
        guard status == .available else {
            throw CloudSyncValidationError.invalidIdentity
        }
        let recordID = try await container.userRecordID()
        return String(CloudSyncCodec.digestHex(Data(recordID.recordName.utf8)).prefix(16))
    }

    private func waitForPhysicalCloudOutboxToDrain(
        using service: CloudSyncService,
        actor: DataActor,
        timeout: Duration = .seconds(60)
    ) async throws -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            try Task.checkCancellation()
            await service.retry()
            if try await actor.pendingCloudSyncRecordNames().isEmpty,
               service.snapshot.status == .ready {
                return true
            }
            try await clock.sleep(for: .seconds(1))
        }
        return false
    }

    private func makeExpense(
        id: UUID = UUID(),
        amountMinorUnits: Int64,
        merchantName: String? = nil,
        updatedAt: Date? = nil
    ) -> ExpenseDraft {
        ExpenseDraft(
            id: id,
            amount: Money(minorUnits: amountMinorUnits, currencyCode: "USD"),
            category: .food,
            bucket: .discretionary,
            merchantName: merchantName,
            note: "private note",
            spentAt: fixedDate,
            spentTimeZoneIdentifier: "UTC",
            createdAt: fixedDate,
            updatedAt: updatedAt ?? fixedDate,
            paymentMethod: .mobilePay,
            emotionTag: nil,
            purchaseReason: .need,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )
    }

    private func stagedExpenseFields(
        _ expense: ExpenseDraft,
        using actor: DataActor
    ) async throws -> [String: CloudSyncValue] {
        _ = try await actor.createExpense(expense)
        let recordName = "expense/\(expense.id.uuidString.lowercased())"
        let pendingRead = try await actor.pendingCloudSyncRecord(named: recordName)
        let pending = try #require(pendingRead)
        let envelope = try CloudSyncCodec.decodeEnvelope(pending.envelopeData)
        let fields = try #require(envelope.payload?.fields)
        // Remove the locally seeded fact and sync state so the test starts as a remote-only
        // lineage, while reusing the production projection's exact field vocabulary.
        try await actor.deleteAllUserData()
        _ = try await actor.setCloudSyncEnabled(true, at: fixedDate)
        return fields
    }

    private func pendingRemoteRecords(using actor: DataActor) async throws -> [CloudSyncRemoteRecord] {
        var records: [CloudSyncRemoteRecord] = []
        for name in try await actor.pendingCloudSyncRecordNames() {
            let pending = try #require(try await actor.pendingCloudSyncRecord(named: name))
            records.append(
                CloudSyncRemoteRecord(
                    recordName: name,
                    envelopeData: pending.envelopeData,
                    encodedSystemFields: nil,
                    wasPhysicallyDeleted: false
                )
            )
        }
        return records
    }

    private func quarantinedReasons(in controller: DataController) throws -> [CloudSyncReasonCode] {
        let context = ModelContext(controller.container)
        return try context.fetch(
            FetchDescriptor<CloudSyncInboxItem>(
                predicate: #Predicate { $0.statusRaw == "quarantined" },
                sortBy: [SortDescriptor(\CloudSyncInboxItem.recordName)]
            )
        ).compactMap { $0.reasonRaw.flatMap(CloudSyncReasonCode.init(rawValue:)) }
    }
}

@MainActor
final class CloudSyncAdapterProbe {
    let adapter = TestCloudSyncAdapter()
    private(set) var creationCount = 0

    func makeAdapter() -> any CloudSyncEngineAdapting {
        creationCount += 1
        return adapter
    }
}

@MainActor
final class TestCloudSyncAdapter: CloudSyncEngineAdapting {
    var onStatusChange: (@MainActor @Sendable () async -> Void)?
    private(set) var startCount = 0
    private(set) var synchronizeCount = 0
    private(set) var deleteCloudDataCount = 0
    var deletionOutcome = CloudSyncCloudDeletionOutcome.deleted
    var deleteHandler: (@MainActor () async -> CloudSyncCloudDeletionOutcome)?

    func start() async { startCount += 1 }
    func synchronize() async { synchronizeCount += 1 }
    func deleteCloudData() async -> CloudSyncCloudDeletionOutcome {
        deleteCloudDataCount += 1
        if let deleteHandler { return await deleteHandler() }
        return deletionOutcome
    }
    func stop() async {}
}

@MainActor
final class TestCloudSyncRetentionStore: CloudSyncRetentionPersisting {
    var cloudCopyMayExist: Bool

    init(cloudCopyMayExist: Bool) {
        self.cloudCopyMayExist = cloudCopyMayExist
    }
}

private struct CloudSyncFactSeed: Sendable {
    let expenseID = UUID()
    let incomeID = UUID()
    let allocationID = UUID()
    let savingsGoalID = UUID()
    let recurringRuleID = UUID()
    let recurringOccurrenceID = UUID()
    let budgetPlanID = UUID()
    let categoryBudgetID = UUID()
    let wishItemID = UUID()
    let coolingOffPlanID = UUID()
    let reflectionLogID = UUID()
}

@ModelActor
private actor CloudSyncFactSeeder {
    func insert(seed: CloudSyncFactSeed, at date: Date) throws {
        let cycleEnd = try #require(Calendar(identifier: .gregorian).date(byAdding: .month, value: 1, to: date))
        let reviewAt = try #require(Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: date))
        let categoryBudget = CategoryBudget(
            id: seed.categoryBudgetID,
            categoryRaw: ExpenseCategory.food.rawValue,
            limitMinorUnits: 5_000,
            warningThresholdBasisPoints: 8_000,
            createdAt: date,
            updatedAt: date,
            plan: nil
        )
        let budgetPlan = BudgetPlan(
            id: seed.budgetPlanID,
            cycleStart: date,
            cycleEnd: cycleEnd,
            currencyCode: "USD",
            monthlyIncomeMinorUnits: 20_000,
            totalBudgetMinorUnits: 15_000,
            fixedExpensesMinorUnits: 4_000,
            savingGoalMinorUnits: 3_000,
            createdAt: date,
            updatedAt: date,
            categoryBudgets: [categoryBudget]
        )
        categoryBudget.plan = budgetPlan
        let expense = Expense(
            id: seed.expenseID,
            amountMinorUnits: 1_234,
            currencyCode: "USD",
            categoryRaw: ExpenseCategory.food.rawValue,
            bucketRaw: BudgetBucket.discretionary.rawValue,
            merchantName: nil,
            normalizedMerchantName: nil,
            note: "private expense note",
            spentAt: date,
            spentTimeZoneIdentifier: "UTC",
            createdAt: date,
            updatedAt: date,
            paymentMethodRaw: PaymentMethod.mobilePay.rawValue,
            emotionTagRaw: nil,
            purchaseReasonRaw: PurchaseReason.need.rawValue,
            isPlanned: false,
            isRecurring: true,
            sourceRaw: ExpenseSource.manual.rawValue,
            allowMerchantIndexing: false
        )
        let income = Income(
            id: seed.incomeID,
            amountMinorUnits: 10_000,
            currencyCode: "USD",
            categoryRaw: IncomeCategory.salary.rawValue,
            sourceName: "Salary",
            note: "private income note",
            receivedAt: date,
            receivedTimeZoneIdentifier: "UTC",
            createdAt: date,
            updatedAt: date
        )
        let allocation = IncomeAllocation(
            id: seed.allocationID,
            incomeID: seed.incomeID,
            budgetPlanID: seed.budgetPlanID,
            allocatedToBudgetMinorUnits: 2_000,
            allocatedToSavingsMinorUnits: 1_000,
            createdAt: date,
            updatedAt: date
        )
        let savingsGoal = SavingsGoal(
            id: seed.savingsGoalID,
            targetMinorUnits: 50_000,
            startingBalanceMinorUnits: 5_000,
            currencyCode: "USD",
            createdAt: date,
            updatedAt: date
        )
        let recurringRule = RecurringFixedExpenseRule(
            id: seed.recurringRuleID,
            originExpenseID: seed.expenseID,
            amountMinorUnits: 1_234,
            currencyCode: "USD",
            categoryRaw: ExpenseCategory.food.rawValue,
            merchantName: nil,
            note: "private recurring note",
            initialOccurrenceAt: date,
            anchorDate: date,
            timeZoneIdentifier: "UTC",
            calendarIdentifierRaw: Calendar.Identifier.gregorian.mindBudgetPersistedValue,
            isActive: true,
            activeSince: date,
            createdAt: date,
            updatedAt: date
        )
        let occurrenceKey = try RecurringOccurrenceKey(
            ruleID: seed.recurringRuleID,
            year: 2026,
            month: 8
        ).rawValue
        let occurrence = RecurringExpenseOccurrence(
            id: seed.recurringOccurrenceID,
            occurrenceKey: occurrenceKey,
            ruleID: seed.recurringRuleID,
            expenseID: seed.expenseID,
            scheduledAt: date,
            createdAt: date
        )
        let semantics = BudgetPlanSemantics(
            planID: seed.budgetPlanID,
            authorityRaw: BudgetPlanAuthority.incomeBased.rawValue
        )
        let wishItem = WishItem(
            id: seed.wishItemID,
            name: "Private wish",
            estimatedPriceMinorUnits: 8_000,
            currencyCode: "USD",
            categoryRaw: ExpenseCategory.shopping.rawValue,
            reasonRaw: PurchaseReason.convenience.rawValue,
            emotionTagRaw: nil,
            sourceContextLabel: "private source",
            createdAt: date,
            updatedAt: date,
            coolingOffHours: 24,
            targetReviewDate: reviewAt,
            statusRaw: WishItemStatus.coolingOff.rawValue,
            notes: "private wish note",
            purchasedExpenseId: nil,
            coolingOffPlans: []
        )
        let coolingOffPlan = CoolingOffPlan(
            id: seed.coolingOffPlanID,
            startedAt: date,
            reviewAt: reviewAt,
            durationHours: 24,
            statusRaw: CoolingOffStatus.active.rawValue,
            notificationIdentifier: "local-only-notification-id",
            completedAt: nil,
            outcomeRaw: nil,
            outcomeRecordedAt: nil,
            wishItem: wishItem
        )
        wishItem.coolingOffPlans = [coolingOffPlan]
        let reflection = ReflectionLog(
            id: seed.reflectionLogID,
            createdAt: date,
            contextRaw: ReflectionContext.manual.rawValue,
            selectedEmotionTagRaw: nil,
            selectedReasonRaw: PurchaseReason.need.rawValue,
            note: "private reflection",
            relatedExpenseId: seed.expenseID,
            relatedWishItemId: seed.wishItemID
        )

        modelContext.insert(expense)
        modelContext.insert(income)
        modelContext.insert(allocation)
        modelContext.insert(savingsGoal)
        modelContext.insert(recurringRule)
        modelContext.insert(occurrence)
        modelContext.insert(budgetPlan)
        modelContext.insert(semantics)
        modelContext.insert(categoryBudget)
        modelContext.insert(wishItem)
        modelContext.insert(coolingOffPlan)
        modelContext.insert(reflection)
        try modelContext.save()
    }
}
