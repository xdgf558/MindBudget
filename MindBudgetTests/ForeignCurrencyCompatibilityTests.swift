import Foundation
import SwiftData
import Testing
@testable import MindBudget

/// Codec compatibility is not execution of an old app, CKSyncEngine or a real account.
/// The frozen codec is independently hashed back to the pre-D source by the static gate.
@MainActor
struct ForeignCurrencyCompatibilityTests {
    private let stamp = Date(timeIntervalSinceReferenceDate: 810_000_000)
    private let access = FeatureAccessService(entitlements: .proSubscription)

    private func draft(id: UUID, foreign: ExpenseForeignCurrency? = nil) -> ExpenseDraft {
        ExpenseDraft(id: id, amount: Money(minorUnits: 600, currencyCode: "USD"), category: .food,
            bucket: .discretionary, merchantName: nil, note: "synthetic compatibility fixture",
            spentAt: stamp, spentTimeZoneIdentifier: "UTC", createdAt: stamp, updatedAt: stamp,
            paymentMethod: nil, emotionTag: nil, purchaseReason: nil, isPlanned: true,
            isRecurring: false, source: .manual, allowMerchantIndexing: false, foreignCurrency: foreign)
    }

    private func foreign(calendar: Calendar = Calendar(identifier: .gregorian),
                         date: Date? = nil) throws -> ExpenseForeignCurrency {
        try ExpenseForeignCurrency(original: Money(minorUnits: 300, currencyCode: "EUR"),
            rate: ForeignCurrencyRate(numerator: 2, denominator: 1),
            selectedDate: date ?? stamp, calendar: calendar)
    }

    private func records(_ actor: DataActor) async throws -> [CloudSyncRemoteRecord] {
        var result: [CloudSyncRemoteRecord] = []
        for name in try await actor.pendingCloudSyncRecordNames() {
            let row = try #require(try await actor.pendingCloudSyncRecord(named: name))
            result.append(.init(recordName: name, envelopeData: row.envelopeData,
                encodedSystemFields: nil, wasPhysicallyDeleted: false))
        }
        return result
    }

    private func pair(id: UUID, value: ExpenseForeignCurrency) async throws -> [CloudSyncRemoteRecord] {
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(id: id, foreign: value), featureAccess: access)
        let result = try await records(source)
        #expect(result.count == 2)
        return result
    }

    private func oldParent(_ records: [CloudSyncRemoteRecord]) throws -> PreDFrozenCloudSyncEnvelope {
        let record = try #require(records.first { $0.recordName.hasPrefix("expense/") })
        return try PreDFrozenCloudSyncCodec.decodeEnvelope(try #require(record.envelopeData))
    }

    private func remote(_ envelope: PreDFrozenCloudSyncEnvelope) throws -> CloudSyncRemoteRecord {
        .init(recordName: envelope.recordName,
            envelopeData: try PreDFrozenCloudSyncCodec.encodeEnvelope(envelope),
            encodedSystemFields: nil, wasPhysicallyDeleted: false)
    }

    @Test func frozenTwelveTypeCodecAcceptsUnchangedParentAndRejectsCompanion() async throws {
        #expect(PreDFrozenCloudSyncEntityType.allCases.map(\.rawValue) == [
            "expense", "income", "incomeAllocation", "savingsGoal", "recurringRule",
            "recurringOccurrence", "budgetPlan", "budgetPlanSemantics", "categoryBudget",
            "wishItem", "coolingOffPlan", "reflectionLog"])
        let rows = try await pair(id: UUID(), value: foreign())
        let old = try oldParent(rows)
        let bytes = try PreDFrozenCloudSyncCodec.encodeEnvelope(old)
        #expect(bytes == rows.first { $0.recordName == old.recordName }?.envelopeData)
        let current = try CloudSyncCodec.decodeEnvelope(bytes)
        #expect(current.semanticDigest == old.semanticDigest)
        #expect(old.payload?.fields["amount"]?.integerValue == 600)
        #expect(old.payload?.fields["currency"]?.stringValue == "USD")
        let child = try #require(rows.first { $0.recordName.hasPrefix("expenseForeignCurrencyMetadata/") })
        let childBytes = try #require(child.envelopeData)
        #expect(throws: DecodingError.self) { try PreDFrozenCloudSyncCodec.decodeEnvelope(childBytes) }
        // Negative control: neither codec may accept tampered, stale-digest accounting data.
        let altered = Data(String(decoding: bytes, as: UTF8.self).replacingOccurrences(
            of: "\"integerValue\":600", with: "\"integerValue\":900").utf8)
        #expect(altered != bytes)
        #expect(throws: (any Error).self) { try PreDFrozenCloudSyncCodec.decodeEnvelope(altered) }
        #expect(throws: (any Error).self) { try CloudSyncCodec.decodeEnvelope(altered) }
    }

    @Test func oldCodecAuthoredOrdinaryEditImportsWithoutInventingFX() async throws {
        let id = UUID()
        let rows = try await pair(id: id, value: foreign())
        let old = try oldParent(rows)
        let payload = try #require(old.payload)
        var fields = payload.fields
        fields["amount"] = .integer(900)
        // A new old-format record, authored/digested/encoded by the frozen implementation.
        let authored = try PreDFrozenCloudSyncCodec.makeEnvelope(
            payload: .init(entityType: .expense, identity: payload.identity, fields: fields),
            entityType: .expense, identity: payload.identity, operation: .upsert,
            revision: 1, parentSemanticDigest: nil, modifiedAt: stamp)
        let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await receiver.setCloudSyncEnabled(true)
        let record = try remote(authored)
        try await receiver.ingestCloudSyncRecords([record, record])
        let detail = try #require(try await receiver.fetchExpenseDetail(id: id))
        #expect(detail.summary.amount == Money(minorUnits: 900, currencyCode: "USD"))
        #expect(detail.foreignCurrency == nil)
        #expect(try await receiver.modelCounts().expenses == 1)
        #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
        #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 0)
    }

    @Test func oldCodecContradictoryEditStaysPendingAcrossReopenWithoutRevaluation() async throws {
        let id = UUID()
        let value = try foreign()
        let rows = try await pair(id: id, value: value)
        let old = try oldParent(rows)
        let payload = try #require(old.payload)
        var fields = payload.fields
        fields["amount"] = .integer(900)
        let edit = try PreDFrozenCloudSyncCodec.makeEnvelope(
            payload: .init(entityType: .expense, identity: payload.identity, fields: fields),
            entityType: .expense, identity: payload.identity, operation: .upsert,
            revision: 2, parentSemanticDigest: old.semanticDigest, modifiedAt: stamp)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("FX-Compatibility-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("store.sqlite")
        do {
            let controller = try DataController(storeURL: url)
            let actor = controller.dataActor
            _ = try await actor.setCloudSyncEnabled(true)
            try await actor.ingestCloudSyncRecords(rows)
            try await actor.ingestCloudSyncRecords([remote(edit)])
            #expect(try await actor.fetchExpenseDetail(id: id)?.foreignCurrency == value)
            #expect(try await actor.fetchExpenseDetail(id: id)?.summary.amount.minorUnits == 600)
        }
        let reopened = try DataController(storeURL: url)
        try await reopened.dataActor.applyPendingCloudSyncInbox(at: stamp)
        #expect(try await reopened.dataActor.fetchExpenseDetail(id: id)?.summary.amount.minorUnits == 600)
        #expect(try await reopened.dataActor.fetchExpenseDetail(id: id)?.foreignCurrency == value)
        let inbox = try ModelContext(reopened.container).fetch(FetchDescriptor<CloudSyncInboxItem>())
        let editBytes = try PreDFrozenCloudSyncCodec.encodeEnvelope(edit)
        let retained = try #require(inbox.first { $0.envelopeData == editBytes })
        #expect(retained.statusRaw == "pending" && retained.reasonRaw == "missingParent")
        #expect(try await reopened.dataActor.cloudSyncSnapshot().quarantinedCount == 0)
        // Safety only: a pre-D client cannot author the absent companion. Do not call this convergence.
    }

    @Test func oldCodecParentTombstoneDeletesBothFactsAndReplayCannotResurrectThem() async throws {
        let id = UUID()
        let rows = try await pair(id: id, value: foreign())
        let old = try oldParent(rows)
        let tombstone = try PreDFrozenCloudSyncCodec.makeEnvelope(payload: nil, entityType: .expense,
            identity: try #require(old.payload?.identity), operation: .tombstone,
            revision: 2, parentSemanticDigest: old.semanticDigest, modifiedAt: stamp)
        let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await receiver.setCloudSyncEnabled(true)
        try await receiver.ingestCloudSyncRecords(rows)
        let deletion = try remote(tombstone)
        try await receiver.ingestCloudSyncRecords([deletion, deletion])
        #expect(try await receiver.modelCounts().expenses == 0)
        #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
        try await receiver.ingestCloudSyncRecords(rows)
        #expect(try await receiver.modelCounts().expenses == 0)
        #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
    }

    @Test func oldCodecCompatibleNoteEditAppliesWithoutDroppingRetainedFX() async throws {
        let id = UUID()
        let value = try foreign()
        let rows = try await pair(id: id, value: value)
        let old = try oldParent(rows)
        let payload = try #require(old.payload)
        var fields = payload.fields
        fields["note"] = .string("old client note edit")
        let edit = try PreDFrozenCloudSyncCodec.makeEnvelope(
            payload: .init(entityType: .expense, identity: payload.identity, fields: fields),
            entityType: .expense, identity: payload.identity, operation: .upsert,
            revision: 2, parentSemanticDigest: old.semanticDigest, modifiedAt: stamp)
        let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await receiver.setCloudSyncEnabled(true)
        try await receiver.ingestCloudSyncRecords(rows)
        try await receiver.ingestCloudSyncRecords([remote(edit)])
        let detail = try #require(try await receiver.fetchExpenseDetail(id: id))
        #expect(detail.note == "old client note edit")
        #expect(detail.summary.amount == Money(minorUnits: 600, currencyCode: "USD"))
        #expect(detail.foreignCurrency == value)
        #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 1)
        #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 0)
    }

    private var calendars: [Calendar.Identifier] {
        [.gregorian, .buddhist, .chinese, .coptic, .ethiopicAmeteMihret, .ethiopicAmeteAlem,
         .hebrew, .iso8601, .indian, .islamic, .islamicCivil, .japanese, .persian,
         .republicOfChina, .islamicTabular, .islamicUmmAlQura]
    }

    // Fixed absolute expectations, not values generated by the implementation under test.
    // Includes spring/fall DST, a skipped civil day, a midnight gap and a quarter-hour zone.
    private var days: [(zone: String, selected: String, start: String)] {
        [("UTC", "2026-09-09T12:00:00Z", "2026-09-09T00:00:00Z"),
         ("America/New_York", "2026-03-08T18:00:00Z", "2026-03-08T05:00:00Z"),
         ("America/New_York", "2026-11-01T18:00:00Z", "2026-11-01T04:00:00Z"),
         ("Asia/Kathmandu", "2026-09-09T12:00:00Z", "2026-09-08T18:15:00Z"),
         ("Pacific/Apia", "2011-12-30T12:00:00Z", "2011-12-30T10:00:00Z"),
         ("America/Sao_Paulo", "2018-11-04T12:00:00Z", "2018-11-04T03:00:00Z")]
    }

    @Test func savedDayHasExactCrossCalendarBoundariesWithoutAssumingFixedDayLength() throws {
        let parser = ISO8601DateFormatter()
        for day in days {
            let date = try #require(parser.date(from: day.selected))
            let expected = try #require(parser.date(from: day.start))
            let zone = try #require(TimeZone(identifier: day.zone))
            for senderID in calendars {
                var sender = Calendar(identifier: senderID)
                sender.timeZone = zone
                let value = try foreign(calendar: sender, date: date)
                #expect(value.rateDate == expected, "\(senderID) / \(day.zone) / \(day.selected)")
                try value.validate(accounting: Money(minorUnits: 600, currencyCode: "USD"))
                for receiverID in calendars {
                    var receiver = Calendar(identifier: receiverID)
                    receiver.timeZone = zone
                    #expect(receiver.startOfDay(for: value.rateDate) == value.rateDate,
                        "\(senderID) → \(receiverID) / \(day.zone)")
                    // Off-boundary input must not become silently normalized stored evidence.
                    let invalid = value.rateDate.addingTimeInterval(1)
                    #expect(receiver.startOfDay(for: invalid) != invalid)
                }
            }
        }
    }

    @Test func everySenderCalendarRoundTripsThroughActualCurrentReaderAndCorruptDateQuarantines() async throws {
        let parser = ISO8601DateFormatter()
        for day in days {
            for calendarID in calendars {
                var calendar = Calendar(identifier: calendarID)
                calendar.timeZone = try #require(TimeZone(identifier: day.zone))
                let value = try foreign(calendar: calendar, date: #require(parser.date(from: day.selected)))
                let id = UUID()
                let rows = try await pair(id: id, value: value)
                let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
                _ = try await receiver.setCloudSyncEnabled(true)
                try await receiver.ingestCloudSyncRecords(rows.reversed())
                let detail = try #require(try await receiver.fetchExpenseDetail(id: id))
                #expect(detail.foreignCurrency == value)
                #expect(detail.summary.amount == Money(minorUnits: 600, currencyCode: "USD"))
                #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 0)
            }
        }
        // This is the actual reader under this process's Calendar.current, not 16 receiver processes.
        let rows = try await pair(id: UUID(), value: foreign())
        let child = try #require(rows.first { $0.recordName.hasPrefix("expenseForeignCurrencyMetadata/") })
        let envelope = try CloudSyncCodec.decodeEnvelope(try #require(child.envelopeData))
        let payload = try #require(envelope.payload)
        var fields = payload.fields
        let bits = try #require(fields["rateDate"]?.unsignedValue)
        fields["rateDate"] = .unsigned(Date(cloudSyncBits: bits).addingTimeInterval(1).cloudSyncBits)
        let damaged = try CloudSyncCodec.makeEnvelope(
            payload: .init(entityType: envelope.entityType, identity: payload.identity, fields: fields),
            entityType: envelope.entityType, identity: payload.identity, operation: .upsert,
            revision: 1, parentSemanticDigest: nil, modifiedAt: stamp)
        let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await receiver.setCloudSyncEnabled(true)
        let parent = try #require(rows.first { $0.recordName.hasPrefix("expense/") })
        try await receiver.ingestCloudSyncRecords([parent, .init(recordName: child.recordName,
            envelopeData: CloudSyncCodec.encodeEnvelope(damaged), encodedSystemFields: nil,
            wasPhysicallyDeleted: false)])
        #expect(try await receiver.modelCounts().expenses == 0)
        #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
        #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 2)
    }
}
