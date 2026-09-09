import CloudKit
import Foundation
import SwiftData

// No AppEnvironment, StoreKit lifecycle, SettingsStore or default-container construction.
// Sources are compiled from the unchanged production files, NOT copied or reimplemented codecs.
@MainActor
final class ProbeLifecycle: ProbeDriving {
    private let cloud: CKContainer
    private let root: URL
    private let calendar: Calendar
    private var expected: [ExpenseDraft] = []
    private var store: ModelContainer?
    private var actor: DataActor?
    private var adapter: CKSyncEngineAdapter?

    init(root: URL, calendar: Calendar) {
        self.root = root
        self.calendar = calendar
        // Constructor is reachable only after local preflight and one-shot reservation.
        cloud = CKContainer(identifier: ProbeRequest.container)
    }

    func perform(_ step: ProbeStep) async throws {
        switch step {
        case .remoteAbsence:
            // No record/content query. Even an empty existing custom zone blocks this first pass.
            let zones = try await cloud.privateCloudDatabase.allRecordZones()
            guard zones.allSatisfy({ $0.zoneID == CKRecordZone.default().zoneID }) else {
                throw ProbeFailure.unexpectedRemoteZone
            }
        case .upload:
            let actor = try await openFreshStore("writer")
            expected = try fixtures()
            let access = FeatureAccessService(entitlements: .proSubscription)
            for draft in expected { _ = try await actor.createExpense(draft, featureAccess: access) }
            _ = try await actor.setCloudSyncEnabled(true)
            let names = try await actor.pendingCloudSyncRecordNames()
            guard Set(names) == expectedNames else { throw ProbeFailure.unexpectedRecords }
            try await recordManifest(actor, name: "initial-fixture.json")
            try await startTransport(actor)
            try await compare(actor)
            await stop()
        case .freshRead:
            let actor = try await openFreshStore("reader")
            _ = try await actor.setCloudSyncEnabled(true)
            guard try await actor.pendingCloudSyncRecordNames().isEmpty else { throw ProbeFailure.localState }
            try await startTransport(actor)
            try await compare(actor)
        case .editUpload:
            guard let actor, let adapter, let original = expected.first,
                  let foreign = original.foreignCurrency else { throw ProbeFailure.localState }
            // Stop background scheduling before changing the local fixture so its intended
            // encrypted-envelope hashes can be recorded before any edit upload starts.
            await adapter.stop()
            self.adapter = nil
            let edited = draft(id: original.id, amount: original.amount,
                               foreign: try foreign.overriding(accounting: original.amount),
                               at: original.spentAt, note: "synthetic-edited")
            expected[0] = edited
            _ = try await actor.updateExpense(id: edited.id, with: edited)
            try await recordManifest(actor, name: "edited-fixture.json")
            try await startTransport(actor)
            try await compare(actor)
            await stop()
        case .originalWriterRead:
            // Resume the original writer's accepted v1 ancestry. A third empty store cannot
            // claim v2 bootstrap support: production deliberately rejects missing lineage.
            let actor = try await openStore("writer", fresh: false)
            guard try await actor.pendingCloudSyncRecordNames().isEmpty else { throw ProbeFailure.localState }
            try await startTransport(actor)
            try await compare(actor)
        case .repeatedRead:
            guard let actor, let adapter else { throw ProbeFailure.localState }
            await adapter.synchronize() // planned duplicate fetch, not a retry of a failed step
            try await requireReady(actor)
            try await compare(actor)
        }
    }

    private var expectedNames: Set<String> {
        Set(expected.flatMap { draft in
            let id = draft.id.uuidString.lowercased()
            return ["expense/" + id, "expenseForeignCurrencyMetadata/" + id]
        })
    }

    private func openFreshStore(_ name: String) async throws -> DataActor {
        try await openStore(name, fresh: true)
    }

    private func openStore(_ name: String, fresh: Bool) async throws -> DataActor {
        guard adapter == nil else { throw ProbeFailure.localState }
        let url = root.appendingPathComponent(name + ".store")
        guard FileManager.default.fileExists(atPath: url.path) != fresh,
              fresh || name == "writer" else { throw ProbeFailure.localState }
        // Explicit test-owned URL. SwiftData's own CloudKit integration is disabled.
        let schema = Schema(versionedSchema: SchemaV7.self)
        let configuration = ModelConfiguration(name, schema: schema, url: url,
                                               allowsSave: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let actor = DataActor(modelContainer: container)
        if fresh {
            guard try await actor.modelCounts().isEmpty,
                  try await actor.cloudSyncEngineStateData() == nil else { throw ProbeFailure.localState }
        } else {
            guard try await actor.cloudSyncEngineStateData() != nil else { throw ProbeFailure.localState }
        }
        self.store = container
        self.actor = actor
        return actor
    }

    private func startTransport(_ actor: DataActor) async throws {
        guard cloud.containerIdentifier == ProbeRequest.container else { throw ProbeFailure.wrongIdentity }
        let adapter = CKSyncEngineAdapter(dataActor: actor, container: cloud)
        self.adapter = adapter
        await adapter.start()
        try await requireReady(actor)
    }

    private func requireReady(_ actor: DataActor) async throws {
        let snapshot = try await actor.cloudSyncSnapshot()
        guard snapshot.isEnabled, snapshot.status == .ready, snapshot.reason == nil,
              snapshot.pendingCount == 0, snapshot.quarantinedCount == 0 else { throw ProbeFailure.transport }
    }

    private func recordManifest(_ actor: DataActor, name: String) async throws {
        let names = try await actor.pendingCloudSyncRecordNames()
        guard !names.isEmpty, Set(names).isSubset(of: expectedNames) else { throw ProbeFailure.unexpectedRecords }
        var hashes: [String: String] = [:]
        for name in names {
            guard let record = try await actor.pendingCloudSyncRecord(named: name) else { throw ProbeFailure.localState }
            hashes[name] = CloudSyncCodec.digestHex(record.envelopeData)
        }
        // Only synthetic IDs and envelope digests; no account fingerprint or raw payload.
        let data = try JSONEncoder().encode(hashes)
        try data.write(to: root.appendingPathComponent(name), options: .withoutOverwriting)
    }

    private func compare(_ actor: DataActor) async throws {
        let counts = try await actor.modelCounts()
        guard counts == ModelCounts(expenses: 4, incomes: 0, budgetPlans: 0, budgetPlanSemantics: 0,
                                    wishItems: 0, coolingOffPlans: 0, categoryBudgets: 0,
                                    spendingInsights: 0, reminderEvents: 0, merchants: 0,
                                    reflectionLogs: 0, savingsGoals: 0, recurringRules: 0,
                                    recurringOccurrences: 0, incomeAllocations: 0,
                                    merchantAccountingContexts: 0, foreignCurrencyMetadata: 4) else {
            throw ProbeFailure.unexpectedRecords
        }
        let summaries = try await actor.fetchExpenseSummaries()
        guard Set(summaries.map(\.id)) == Set(expected.map(\.id)),
              summaries.count == expected.count else { throw ProbeFailure.unexpectedRecords }
        for draft in expected {
            guard let detail = try await actor.fetchExpenseDetail(id: draft.id),
                  detail.summary.amount == draft.amount, detail.note == draft.note,
                  detail.summary.category == draft.category,
                  detail.summary.bucket == draft.bucket,
                  detail.summary.spentAt == draft.spentAt,
                  detail.summary.spentTimeZoneIdentifier == draft.spentTimeZoneIdentifier,
                  detail.summary.source == .manual, detail.summary.merchantName == nil,
                  !detail.summary.isRecurring, detail.summary.isPlanned,
                  !detail.summary.allowMerchantIndexing,
                  detail.foreignCurrency == draft.foreignCurrency else { throw ProbeFailure.comparison }
        }
        // A server fetch must not manufacture any outbound echo.
        guard try await actor.pendingCloudSyncRecordNames().isEmpty else { throw ProbeFailure.transport }
    }

    func stop() async {
        await adapter?.stop()
        adapter = nil
        actor = nil
        store = nil
        // Preserve every local file and the remote zone, including failures. No deletion API.
    }

    private func fixtures() throws -> [ExpenseDraft] {
        let date = calendar.startOfDay(for: Date())
        let converter = ForeignCurrencyConverter()
        return try [("JPY", Int64(1_001), Int64(7), Int64(1_000)),
                    ("KWD", Int64(1_234), Int64(13), Int64(4))].flatMap { code, units, n, d in
            let original = Money(minorUnits: units, currencyCode: code)
            let rate = try ForeignCurrencyRate(numerator: n, denominator: d)
            let home = try converter.convert(original: original, accountingCurrency: "USD", rate: rate)
            let manual = try ExpenseForeignCurrency(original: original, rate: rate,
                                                    selectedDate: date, calendar: calendar)
            let overriddenHome = Money(minorUnits: home.minorUnits + 1, currencyCode: "USD")
            return [draft(id: UUID(), amount: home, foreign: manual, at: date, note: "synthetic-manual"),
                    draft(id: UUID(), amount: overriddenHome,
                          foreign: try manual.overriding(accounting: overriddenHome),
                          at: date, note: "synthetic-override")]
        }
    }

    private func draft(id: UUID, amount: Money, foreign: ExpenseForeignCurrency,
                       at date: Date, note: String) -> ExpenseDraft {
        ExpenseDraft(id: id, amount: amount, category: .other, bucket: .discretionary,
                     merchantName: nil, note: note, spentAt: date,
                     spentTimeZoneIdentifier: calendar.timeZone.identifier, createdAt: date,
                     updatedAt: Date(), paymentMethod: nil, emotionTag: nil, purchaseReason: nil,
                     isPlanned: true, isRecurring: false, source: .manual,
                     allowMerchantIndexing: false, foreignCurrency: foreign)
    }
}
