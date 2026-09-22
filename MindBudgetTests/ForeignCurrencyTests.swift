import Foundation
import SwiftData
import Testing
@testable import MindBudget

private actor FXPrivacySpotlightClient: SpotlightIndexClient {
    func replace(domainIdentifier: String, with documents: [SpotlightDocument]) async throws {}
    func delete(domainIdentifier: String) async throws {}
}

private actor FXPrivacyModelProbe: AIAdviceGenerating {
    enum CaptureComplete: Error { case fallback }
    private(set) var prompts: [String] = []
    func generateReminder(from context: RedactedAdviceContext) async throws -> GeneratedAdvice {
        prompts.append(context.promptData)
        throw CaptureComplete.fallback
    }
    func generateCycleSummary(from context: RedactedSummaryContext) async throws -> GeneratedSummary {
        prompts.append(context.promptData)
        throw CaptureComplete.fallback
    }
    func answerQuestion(intent: AskIntentKey, context: RedactedAskContext) async throws -> GeneratedAnswer {
        prompts.append(context.promptData)
        throw CaptureComplete.fallback
    }
}

@MainActor
struct ForeignCurrencyMigrationTests {
    private let schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self, SchemaV3.self,
        SchemaV4.self, SchemaV5.self, SchemaV6.self]
    private let stamp = Date(timeIntervalSinceReferenceDate: 700_000_000)

    @Test func v1ThroughV6PreserveEverySeededFieldAcrossMigrationAndRestartWithoutInventingFX() async throws {
        for (index, type) in schemas.enumerated() {
            let version = index + 1
            let root = try directory()
            defer { try? FileManager.default.removeItem(at: root) }
            let url = root.appendingPathComponent("MindBudget.store")
            let original: [String: [String]]
            do {
                let schema = Schema(versionedSchema: type)
                let configuration = ModelConfiguration("MindBudget", schema: schema, url: url, cloudKitDatabase: .none)
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = ModelContext(container)
                try seed(context, version: version)
                original = try snapshot(context, version: version)
            }
            // A committed V6 marker must not skip V7 migration/inventory.
            if version == 6 {
                try Data(#"{"formatVersion":1,"state":"committed","target":"mindbudget-schema-v6"}"#.utf8)
                    .write(to: URL(fileURLWithPath: url.path + ".migration-marker"))
            }
            for restart in 0..<2 {
                let controller = try DataController(storeURL: url)
                #expect(try snapshot(ModelContext(controller.container), version: version) == original,
                        "V\(version) restart \(restart): every seeded field is retained")
                #expect(try await controller.dataActor.modelCounts().foreignCurrencyMetadata == 0)
                for summary in try await controller.dataActor.fetchExpenseSummaries() {
                    #expect(try await controller.dataActor.fetchExpenseDetail(id: summary.id)?.foreignCurrency == nil)
                }
            }
        }
    }

    @Test func v7ForeignTupleSurvivesDiskReopenAndDeleteAll() async throws {
        let root = try directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("MindBudget.store")
        var calendar = Calendar(identifier: .buddhist)
        calendar.timeZone = TimeZone(identifier: "Asia/Bangkok")!
        let foreign = try ExpenseForeignCurrency(original: Money(minorUnits: 100, currencyCode: "JPY"),
            rate: ForeignCurrencyRate(numerator: 1, denominator: 100), selectedDate: stamp, calendar: calendar)
        let id = UUID()
        do {
            let controller = try DataController(storeURL: url)
            let draft = ExpenseDraft(id: id, amount: Money(minorUnits: 100, currencyCode: "USD"), category: .food,
                bucket: .discretionary, merchantName: nil, note: "saved FX", spentAt: stamp,
                spentTimeZoneIdentifier: calendar.timeZone.identifier, createdAt: stamp, updatedAt: stamp,
                paymentMethod: nil, emotionTag: nil, purchaseReason: nil, isPlanned: true,
                isRecurring: false, source: .manual, allowMerchantIndexing: false, foreignCurrency: foreign)
            _ = try await controller.dataActor.createExpense(draft, featureAccess: FeatureAccessService(entitlements: .proSubscription))
        }
        do {
            let controller = try DataController(storeURL: url)
            #expect(try await controller.dataActor.fetchExpenseDetail(id: id)?.foreignCurrency == foreign)
            try MigrationIntegrityInventory.validateAndRepair(in: controller.container)
            try await controller.dataActor.deleteAllUserData()
        }
        let empty = try DataController(storeURL: url)
        #expect(try await empty.dataActor.modelCounts().isEmpty)
    }

    @Test func knownLegacyJournalsRestoreBeforeV7AndUnknownTargetsRemainClosed() throws {
        for oldTarget in ["mindbudget-schema-v5", "mindbudget-schema-v6", "mindbudget-schema-v8"] {
            let root = try directory()
            defer { try? FileManager.default.removeItem(at: root) }
            let url = root.appendingPathComponent("MindBudget.store")
            let original = Data("verified source bytes".utf8)
            try original.write(to: url)
            let coordinator = StoreMigrationRecoveryCoordinator(storeURL: url)
            let attempt = try #require(try coordinator.prepareForOpen())
            try coordinator.markMigrating(attempt)
            let journal = root.appendingPathComponent("MindBudgetMigrationRecovery/journal.json")
            var json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: journal)) as? [String: Any])
            json["target"] = oldTarget
            try JSONSerialization.data(withJSONObject: json).write(to: journal)
            let partial = Data("interrupted write".utf8)
            try partial.write(to: url)
            if oldTarget != "mindbudget-schema-v8" {
                #expect(try coordinator.prepareForOpen() != nil)
                #expect(try Data(contentsOf: url) == original)
                let next = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: journal)) as? [String: Any])
                #expect(next["target"] as? String == "mindbudget-schema-v7")
            } else {
                #expect(throws: StoreMigrationRecoveryCoordinator.RecoveryError.unreadableJournal) {
                    try coordinator.prepareForOpen()
                }
                #expect(try Data(contentsOf: url) == partial)
            }
        }
    }

    private func directory() throws -> URL {
        let value = FileManager.default.temporaryDirectory.appendingPathComponent("FX-V7-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: value, withIntermediateDirectories: true)
        return value
    }

    private func seed(_ context: ModelContext, version: Int) throws {
        let expenseID = UUID()
        let merchantID = UUID()
        context.insert(Expense(id: expenseID, amountMinorUnits: 600, currencyCode: "USD", categoryRaw: "food",
            bucketRaw: "discretionary", merchantName: "Cafe", normalizedMerchantName: "cafe", note: "legacy note",
            spentAt: stamp, spentTimeZoneIdentifier: "America/New_York", createdAt: stamp.addingTimeInterval(-1),
            updatedAt: stamp.addingTimeInterval(1), paymentMethodRaw: "creditCard", emotionTagRaw: "neutral",
            purchaseReasonRaw: "need", isPlanned: true, isRecurring: false, sourceRaw: "manual", allowMerchantIndexing: true))
        context.insert(Merchant(id: merchantID, normalizedName: "cafe", displayName: "Cafe", primaryCategoryRaw: "food",
            visitCount: 1, lastVisitedAt: stamp, totalMinorUnitsAllTime: 600))
        let incomeID = UUID()
        if version >= 2 {
            context.insert(Income(id: incomeID, amountMinorUnits: 10_000, currencyCode: "USD", categoryRaw: "salary",
                sourceName: "seed", note: "retained income", receivedAt: stamp, receivedTimeZoneIdentifier: "Asia/Singapore",
                createdAt: stamp.addingTimeInterval(-2), updatedAt: stamp.addingTimeInterval(2)))
        }
        if version >= 3 {
            context.insert(IncomeAllocation(id: UUID(), incomeID: incomeID, budgetPlanID: nil,
                allocatedToBudgetMinorUnits: 0, allocatedToSavingsMinorUnits: 120, createdAt: stamp, updatedAt: stamp))
            context.insert(SavingsGoal(id: UUID(), targetMinorUnits: 2_000, startingBalanceMinorUnits: 20,
                currencyCode: "USD", createdAt: stamp, updatedAt: stamp))
        }
        if version >= 4 {
            let id = UUID()
            context.insert(BudgetPlan(id: id, cycleStart: stamp, cycleEnd: stamp.addingTimeInterval(1), currencyCode: "USD",
                monthlyIncomeMinorUnits: 10_000, totalBudgetMinorUnits: 8_000, fixedExpensesMinorUnits: 1_000,
                savingGoalMinorUnits: 1_000, createdAt: stamp, updatedAt: stamp, categoryBudgets: []))
            context.insert(BudgetPlanSemantics(planID: id, authorityRaw: "incomeBased"))
        }
        if version >= 5 { context.insert(MerchantAccountingContext(merchantID: merchantID, currencyCode: "USD")) }
        if version >= 6 {
            context.insert(CloudSyncControl(id: "primary", isEnabled: false, statusRaw: "disabled",
                accountIdentifierHash: "synthetic", consentVersion: 1, lastReasonRaw: nil, updatedAt: stamp))
            context.insert(CloudSyncRecordMetadata(recordName: "preserve-metadata", entityTypeRaw: "expense",
                acceptedRevision: 7, acceptedSemanticDigest: "digest", acceptedOperationRaw: "upsert",
                encodedSystemFields: Data([1, 2, 3]), stateRaw: "accepted", updatedAt: stamp))
            context.insert(CloudSyncOutboxItem(id: UUID(), recordName: "preserve-outbox", entityTypeRaw: "expense",
                envelopeData: Data([4, 5]), semanticDigest: "pending-digest", statusRaw: "pending",
                createdAt: stamp, updatedAt: stamp, attemptCount: 2))
            context.insert(CloudSyncInboxItem(id: UUID(), recordName: "preserve-inbox", envelopeData: Data([6]),
                encodedSystemFields: Data([7]), statusRaw: "quarantined", reasonRaw: "test", receivedAt: stamp, updatedAt: stamp))
            context.insert(CloudSyncEngineState(id: "private-zone-v1", serializationData: Data([8, 9]), updatedAt: stamp))
        }
        try context.save()
    }

    /// Every scalar field of every seeded row, including raw enums, optional fields, IDs and bytes.
    /// Tables not available in a historical schema are never fetched before migration.
    private func snapshot(_ context: ModelContext, version: Int) throws -> [String: [String]] {
        func values(_ fields: Any...) -> [String] { fields.map { String(reflecting: $0) } }
        let e = try #require(context.fetch(FetchDescriptor<Expense>()).first)
        let m = try #require(context.fetch(FetchDescriptor<Merchant>()).first)
        var result = ["expense": values(e.id, e.amountMinorUnits, e.currencyCode, e.categoryRaw, e.bucketRaw,
            e.merchantName as Any, e.normalizedMerchantName as Any, e.note as Any, e.spentAt, e.spentTimeZoneIdentifier,
            e.createdAt, e.updatedAt, e.paymentMethodRaw as Any, e.emotionTagRaw as Any, e.purchaseReasonRaw as Any,
            e.isPlanned, e.isRecurring, e.sourceRaw, e.allowMerchantIndexing),
            "merchant": values(m.id, m.normalizedName, m.displayName, m.primaryCategoryRaw as Any,
                m.visitCount, m.lastVisitedAt as Any, m.totalMinorUnitsAllTime)]
        if version >= 2 {
            let i = try #require(context.fetch(FetchDescriptor<Income>()).first)
            result["income"] = values(i.id, i.amountMinorUnits, i.currencyCode, i.categoryRaw, i.sourceName as Any,
                i.note as Any, i.receivedAt, i.receivedTimeZoneIdentifier, i.createdAt, i.updatedAt)
        }
        if version >= 3 {
            let a = try #require(context.fetch(FetchDescriptor<IncomeAllocation>()).first)
            result["allocation"] = values(a.id, a.incomeID, a.budgetPlanID as Any, a.allocatedToBudgetMinorUnits,
                a.allocatedToSavingsMinorUnits, a.createdAt, a.updatedAt)
            let g = try #require(context.fetch(FetchDescriptor<SavingsGoal>()).first)
            result["goal"] = values(g.id, g.targetMinorUnits, g.startingBalanceMinorUnits, g.currencyCode, g.createdAt, g.updatedAt)
        }
        if version >= 4 {
            let b = try #require(context.fetch(FetchDescriptor<BudgetPlan>()).first)
            result["budget"] = values(b.id, b.cycleStart, b.cycleEnd, b.currencyCode, b.monthlyIncomeMinorUnits,
                b.totalBudgetMinorUnits, b.fixedExpensesMinorUnits, b.savingGoalMinorUnits, b.createdAt, b.updatedAt,
                b.categoryBudgets.map(\.id))
            let s = try #require(context.fetch(FetchDescriptor<BudgetPlanSemantics>()).first)
            result["semantics"] = values(s.planID, s.authorityRaw)
        }
        if version >= 5 {
            let c = try #require(context.fetch(FetchDescriptor<MerchantAccountingContext>()).first)
            result["merchantCurrency"] = values(c.merchantID, c.currencyCode)
        }
        if version >= 6 {
            let c = try #require(context.fetch(FetchDescriptor<CloudSyncControl>()).first)
            result["control"] = values(c.id, c.isEnabled, c.statusRaw, c.accountIdentifierHash as Any,
                c.consentVersion, c.lastReasonRaw as Any, c.updatedAt)
            let m = try #require(context.fetch(FetchDescriptor<CloudSyncRecordMetadata>()).first)
            result["syncMetadata"] = values(m.recordName, m.entityTypeRaw, m.acceptedRevision, m.acceptedSemanticDigest as Any,
                m.acceptedOperationRaw as Any, m.encodedSystemFields?.base64EncodedString() as Any, m.stateRaw, m.updatedAt)
            let o = try #require(context.fetch(FetchDescriptor<CloudSyncOutboxItem>()).first)
            result["outbox"] = values(o.id, o.recordName, o.entityTypeRaw, o.envelopeData.base64EncodedString(),
                o.semanticDigest, o.statusRaw, o.createdAt, o.updatedAt, o.attemptCount)
            let i = try #require(context.fetch(FetchDescriptor<CloudSyncInboxItem>()).first)
            result["inbox"] = values(i.id, i.recordName, i.envelopeData?.base64EncodedString() as Any,
                i.encodedSystemFields?.base64EncodedString() as Any, i.statusRaw, i.reasonRaw as Any, i.receivedAt, i.updatedAt)
            let s = try #require(context.fetch(FetchDescriptor<CloudSyncEngineState>()).first)
            result["engineState"] = values(s.id, s.serializationData.base64EncodedString(), s.updatedAt)
        }
        return result
    }
}

struct ForeignCurrencyTests {
    private let converter = ForeignCurrencyConverter()
    private let english = Locale(identifier: "en_US")

    @Test func decimalInputNormalizesBeforeReductionAndRoundTrips() throws {
        for (text, locale) in [("7.1234", "en_US"), ("7.123400000000", "zh_CN"),
                               ("7,1234", "de_DE"), ("٧٫١٢٣٤", "ar_EG")] {
            let rate = try ForeignCurrencyRate.parse(text, locale: Locale(identifier: locale))
            #expect(rate.numerator == 35_617)
            #expect(rate.denominator == 5_000)
            let display = try rate.display(locale: Locale(identifier: locale))
            #expect(!display.isApproximate)
            #expect(try ForeignCurrencyRate.parse(display.text, locale: Locale(identifier: locale)) == rate)
        }
        for (text, expected) in [("1.000000005", "1"), ("1.000000015", "1.00000002"),
                                 ("1.000000005001", "1.00000001"), ("9.999999995", "10"),
                                 ("9999999999.99999999", "9999999999.99999999")] {
            #expect(try ForeignCurrencyRate.parse(text, locale: english).display(locale: english).text == expected)
        }
    }

    @Test func malformedOrOutOfBoundRateTextFailsClosed() {
        for text in ["", "0", "-1", "+1", "1e2", "NaN", "inf", "1,000", " 1", "1 ",
                     ".5", "1.", "1.2.3", "1/2", "10000000000", "1.0000000000000",
                     "Ⅲ", "²", "0.000000005", "0.000000000001", "$7.12", "9999999999.999999995"] {
            #expect(throws: ForeignCurrencyError.self) { try ForeignCurrencyRate.parse(text, locale: english) }
        }
        for (n, d) in [(Int64(0), 1), (1, 0), (-1, 1), (1, -1), (Int64.min, Int64.min)] {
            #expect(throws: ForeignCurrencyError.invalidRate) { try ForeignCurrencyRate(numerator: n, denominator: d) }
        }
    }

    @Test func exponentsOrientationAndEvenOddTiesAreExact() throws {
        for (minor, original, home, n, d, expected) in [
            (Int64(100), "USD", "CNY", Int64(7), Int64(1), Int64(700)),
            (100, "CNY", "USD", 1, 7, 14),
            (100, "JPY", "USD", 1, 100, 100),
            (100, "USD", "KWD", 1, 2, 500),
            (3_000, "KWD", "JPY", 1, 2, 2),
            (5, "USD", "CNY", 1, 2, 2),
            (7, "USD", "CNY", 1, 2, 4),
            (3, "JPY", "USD", 1, 200, 2),
            (5, "JPY", "USD", 1, 200, 2),
        ] {
            let result = try converter.convert(original: Money(minorUnits: minor, currencyCode: original),
                accountingCurrency: home, rate: ForeignCurrencyRate(numerator: n, denominator: d))
            #expect(result == Money(minorUnits: expected, currencyCode: home))
        }
    }

    @Test func wideProductsLimitsAndUnderflowDoNotTrapOrLosePrecision() throws {
        let maximum = Money.maximumMinorUnits(for: "USD")
        let nearOne = try ForeignCurrencyRate(numerator: Int64.max - 1, denominator: Int64.max)
        #expect(try converter.convert(original: Money(minorUnits: maximum, currencyCode: "USD"),
            accountingCurrency: "KWD", rate: ForeignCurrencyRate(numerator: 1, denominator: 10)).minorUnits == maximum)
        #expect(try converter.convert(original: Money(minorUnits: maximum, currencyCode: "USD"),
            accountingCurrency: "CNY", rate: nearOne).minorUnits == maximum)
        for original in [Money(minorUnits: 0, currencyCode: "USD"), Money(minorUnits: -1, currencyCode: "USD"),
                         Money(minorUnits: maximum + 1, currencyCode: "USD"), Money(minorUnits: Int64.max, currencyCode: "USD")] {
            #expect(throws: ForeignCurrencyError.invalidAmount) {
                try converter.convert(original: original, accountingCurrency: "CNY", rate: nearOne)
            }
        }
        let dollar = Money(minorUnits: 100, currencyCode: "USD")
        for home in ["USD", "XXX"] {
            #expect(throws: ForeignCurrencyError.currencyMismatch) {
                try converter.convert(original: dollar, accountingCurrency: home, rate: nearOne)
            }
        }
        #expect(throws: ForeignCurrencyError.overflow) {
            try converter.convert(original: dollar, accountingCurrency: "KWD",
                                  rate: ForeignCurrencyRate(numerator: Int64.max, denominator: 1))
        }
        #expect(throws: ForeignCurrencyError.invalidAmount) {
            try converter.convert(original: dollar, accountingCurrency: "JPY",
                                  rate: ForeignCurrencyRate(numerator: 1, denominator: Int64.max))
        }
        // Rounding UP beyond the maximum is rejected, not clamped.
        #expect(throws: ForeignCurrencyError.overflow) {
            try converter.convert(original: Money(minorUnits: 1, currencyCode: "USD"), accountingCurrency: "CNY",
                rate: ForeignCurrencyRate(numerator: maximum * 4 + 3, denominator: 4))
        }
        #expect(try converter.convert(original: Money(minorUnits: 1, currencyCode: "USD"), accountingCurrency: "CNY",
            rate: ForeignCurrencyRate(numerator: maximum * 2 + 1, denominator: 2)).minorUnits == maximum)
    }

    @Test func smallIntegerOracleChecksThousandsOfHalfEvenCases() throws {
        for amount in 1...31 {
            for n in 1...13 {
                for d in 1...13 {
                    let product = amount * n
                    let quotient = product / d
                    let remainder = product % d
                    let expected = quotient + (2 * remainder > d || (2 * remainder == d && quotient % 2 == 1) ? 1 : 0)
                    let rate = try ForeignCurrencyRate(numerator: Int64(n), denominator: Int64(d))
                    if expected == 0 {
                        #expect(throws: ForeignCurrencyError.invalidAmount) {
                            try converter.convert(original: Money(minorUnits: Int64(amount), currencyCode: "USD"),
                                                  accountingCurrency: "CNY", rate: rate)
                        }
                    } else {
                        #expect(try converter.convert(original: Money(minorUnits: Int64(amount), currencyCode: "USD"),
                            accountingCurrency: "CNY", rate: rate).minorUnits == Int64(expected))
                    }
                }
            }
        }
    }

    @Test func overridesAreExactAndApproximationIsDisplayOnly() throws {
        let original = Money(minorUnits: 300, currencyCode: "USD")
        let home = Money(minorUnits: 100, currencyCode: "CNY")
        let rate = try converter.effectiveRate(original: original, accounting: home)
        #expect(rate.numerator == 1 && rate.denominator == 3)
        #expect(try rate.display(locale: english) == .init(text: "0.33333333", isApproximate: true))
        #expect(try converter.convert(original: original, accountingCurrency: "CNY", rate: rate) == home)
        #expect(rate.denominator == 3)
        for source in ["JPY", "USD", "KWD"] {
            for target in ["JPY", "USD", "KWD"] where source != target {
                let a = Money(minorUnits: Money.maximumMinorUnits(for: source), currencyCode: source)
                let b = Money(minorUnits: Money.maximumMinorUnits(for: target) - 1, currencyCode: target)
                let exact = try converter.effectiveRate(original: a, accounting: b)
                #expect(try converter.convert(original: a, accountingCurrency: target, rate: exact) == b)
            }
        }
    }
}

@MainActor
struct ForeignCurrencyPersistenceTests {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "America/New_York")!
        return value
    }
    private var date: Date { calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 14))! }
    private func facts() throws -> ExpenseForeignCurrency {
        try ExpenseForeignCurrency(original: Money(minorUnits: 300, currencyCode: "EUR"),
            rate: ForeignCurrencyRate(numerator: 2, denominator: 1), selectedDate: date, calendar: calendar)
    }
    private func draft(id: UUID = UUID(), amount: Int64 = 600, currency: String = "USD",
                       foreign: ExpenseForeignCurrency? = nil, note: String? = "trip",
                       source: ExpenseSource = .manual, recurring: Bool = false) -> ExpenseDraft {
        ExpenseDraft(id: id, amount: Money(minorUnits: amount, currencyCode: currency), category: .food,
            bucket: .discretionary, merchantName: "Cafe", note: note, spentAt: date,
            spentTimeZoneIdentifier: calendar.timeZone.identifier, createdAt: date, updatedAt: date,
            paymentMethod: nil, emotionTag: nil, purchaseReason: nil, isPlanned: false,
            isRecurring: recurring, source: source, allowMerchantIndexing: false, foreignCurrency: foreign)
    }

    private func seedSyncControl(in context: ModelContext, enabled: Bool,
                                 status: CloudSyncStatus = .ready, reason: CloudSyncReasonCode? = nil) {
        context.insert(CloudSyncControl(id: "primary", isEnabled: enabled,
            statusRaw: status.rawValue, accountIdentifierHash: "synthetic-retained-account",
            consentVersion: 1, lastReasonRaw: reason?.rawValue, updatedAt: date))
    }

    @Test func ordinaryRecordProviderDoesNotRescanTransportPerRecord() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.dataActor
        var expectedAmounts: [String: Int64] = [:]
        var firstID: UUID?
        for index in 1...256 {
            let id = UUID()
            if firstID == nil { firstID = id }
            let amount = Int64(index)
            _ = try await actor.createExpense(draft(id: id, amount: amount))
            expectedAmounts["expense/\(id.uuidString.lowercased())"] = amount
        }
        _ = try await actor.setCloudSyncEnabled(true)
        let names = try await actor.pendingCloudSyncRecordNames()
        #expect(names.count == 256 && Set(names) == Set(expectedAmounts.keys))
        let baseline = await actor.foreignCurrencyTransportScanCount
        let decodeBaseline = await actor.foreignCurrencyFootprintEnvelopeDecodeCount
        #expect(baseline > 0)
        let systemFields = Data("synthetic-provider-system-fields".utf8)
        let serialization = Data("synthetic-provider-engine-state".utf8)
        for name in names {
            // Mirrors the adapter's permission/provider/permission/send-ack sequence without
            // a wall-clock threshold or a real CloudKit record/account operation.
            #expect(try await actor.permitsOrdinaryCloudTransport())
            let pending = try #require(try await actor.pendingCloudSyncRecord(named: name))
            #expect(try await actor.permitsOrdinaryCloudTransport())
            let envelope = try CloudSyncCodec.decodeEnvelope(pending.envelopeData)
            #expect(envelope.entityType == .expense && envelope.operation == .upsert)
            #expect(envelope.payload?.fields["amount"]?.integerValue == expectedAmounts[name])
            #expect(envelope.payload?.fields["currency"]?.stringValue == "USD")
            try await actor.acknowledgeCloudSyncRecord(recordName: name,
                encodedSystemFields: systemFields, at: date)
            try await actor.saveCloudSyncEngineState(serialization, at: date)
            #expect(await actor.foreignCurrencyTransportScanCount == baseline)
            #expect(await actor.foreignCurrencyFootprintEnvelopeDecodeCount == decodeBaseline)
        }
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
        #expect(try await actor.cloudSyncEngineStateData() == serialization)
        let summaries = try await actor.fetchExpenseSummaries()
        #expect(summaries.count == 256)
        #expect(summaries.reduce(Int64(0)) { $0 + $1.amount.minorUnits } == 32_896)
        let metadata = try ModelContext(controller.container).fetch(FetchDescriptor<CloudSyncRecordMetadata>())
        #expect(metadata.count == 256)
        #expect(metadata.allSatisfy {
            $0.acceptedRevision == 1 && $0.stateRaw == "accepted"
                && $0.encodedSystemFields == systemFields
        })
        // A validated ordinary projection after an accepted queue must not invalidate absence.
        let id = try #require(firstID)
        _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 1_000))
        let name = "expense/\(id.uuidString.lowercased())"
        #expect(try await actor.pendingCloudSyncRecordNames() == [name])
        let updated = try #require(try await actor.pendingCloudSyncRecord(named: name))
        let envelope = try CloudSyncCodec.decodeEnvelope(updated.envelopeData)
        #expect(envelope.revision == 2 && envelope.payload?.fields["amount"]?.integerValue == 1_000)
        #expect(try await actor.permitsOrdinaryCloudTransport())
        try await actor.acknowledgeCloudSyncRecord(recordName: name, encodedSystemFields: systemFields, at: date)
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
        #expect(try await actor.fetchExpenseDetail(id: id)?.summary.amount.minorUnits == 1_000)
        #expect(await actor.foreignCurrencyTransportScanCount == baseline)
        #expect(await actor.foreignCurrencyFootprintEnvelopeDecodeCount == decodeBaseline)
    }

    @Test func transportFootprintCacheRechecksAfterRollbackAndWholeTransportErasure() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.dataActor
        let id = UUID()
        _ = try await actor.createExpense(draft(id: id, amount: 700))
        _ = try await actor.setCloudSyncEnabled(true)
        #expect(try await actor.permitsOrdinaryCloudTransport())
        let baseline = await actor.foreignCurrencyTransportScanCount
        let before = try await actor.fetchExpenseDetail(id: id)
        let beforeQueue = try await fxRemoteRecords(actor)
        await #expect(throws: (any Error).self) {
            _ = try await actor.createExpense(draft(amount: 0))
        }
        #expect(try await actor.permitsOrdinaryCloudTransport())
        let afterRollback = await actor.foreignCurrencyTransportScanCount
        #expect(afterRollback == baseline + 1)
        #expect(try await actor.fetchExpenseDetail(id: id) == before)
        let afterQueue = try await fxRemoteRecords(actor)
        #expect(afterQueue.map(\.recordName) == beforeQueue.map(\.recordName))
        #expect(afterQueue.map(\.envelopeData) == beforeQueue.map(\.envelopeData))
        #expect(await actor.foreignCurrencyTransportScanCount == afterRollback)

        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let incoming = try await fxRemoteRecords(source)
        try await actor.ingestCloudSyncRecords(incoming, receivedAt: date)
        #expect(try await !actor.permitsOrdinaryCloudTransport())
        #expect(try await actor.cloudSyncSnapshot().status == .pausedForeignCurrency)
        #expect(await actor.foreignCurrencyTransportScanCount == afterRollback)
        #expect(try await actor.modelCounts().expenses == 1)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 0)
        let beforeErasure = await actor.foreignCurrencyTransportScanCount
        _ = try await actor.beginCloudDeletion(at: date)
        // Actor-only completion models an independently confirmed delete; no adapter is used.
        try await actor.completeCloudDeletion(at: date)
        #expect(try await actor.fetchExpenseDetail(id: id) == before)
        let cleared = ModelContext(controller.container)
        #expect(try cleared.fetchCount(FetchDescriptor<CloudSyncInboxItem>()) == 0)
        #expect(try cleared.fetchCount(FetchDescriptor<CloudSyncRecordMetadata>()) == 0)
        #expect(try await actor.cloudSyncEngineStateData() == nil)
        _ = try await actor.setCloudSyncEnabled(true)
        #expect(try await actor.permitsOrdinaryCloudTransport())
        let afterErasure = await actor.foreignCurrencyTransportScanCount
        #expect(afterErasure == beforeErasure + 1)
        #expect(try await actor.pendingCloudSyncRecordNames().count == 1)
        let context = ModelContext(controller.container)
        #expect(try context.fetchCount(FetchDescriptor<CloudSyncInboxItem>()) == 0)
        let restaged = try context.fetch(FetchDescriptor<CloudSyncRecordMetadata>())
        #expect(restaged.count == 1 && restaged.first?.acceptedRevision == 0)
        #expect(restaged.first?.recordName == "expense/\(id.uuidString.lowercased())")
        #expect(await actor.foreignCurrencyTransportScanCount == afterErasure)
    }

    @Test func localOnlySyncRejectsFXCreationAndConversionAtomically() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.dataActor
        let id = UUID()
        let pro = FeatureAccessService(entitlements: .proSubscription)
        _ = try await actor.setCloudSyncEnabled(true)
        _ = try await actor.createExpense(draft(id: id))
        let before = try await actor.fetchExpenseDetail(id: id)
        let pending = try await fxRemoteRecords(actor)
        await #expect(throws: ForeignCurrencyError.syncRequiresCompanionProtocol) {
            _ = try await actor.createExpense(draft(foreign: facts()), featureAccess: pro)
        }
        await #expect(throws: ForeignCurrencyError.syncRequiresCompanionProtocol) {
            _ = try await actor.updateExpense(id: id,
                with: draft(id: id, foreign: facts()), featureAccess: pro)
        }
        #expect(try await actor.fetchExpenseDetail(id: id) == before)
        #expect(try await actor.modelCounts().expenses == 1)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 0)
        let after = try await fxRemoteRecords(actor)
        #expect(after.map(\.recordName) == pending.map(\.recordName))
        #expect(after.map(\.envelopeData) == pending.map(\.envelopeData))
        #expect(try await actor.permitsOrdinaryCloudTransport())
    }

    @Test func localFXBlocksEnableAndRecoveryWithoutDiscardingTransportState() async throws {
        for priorStatus in [CloudSyncStatus.disabled, .pausedRemoteZoneDeleted] {
            let controller = try DataController(isStoredInMemoryOnly: true)
            let id = UUID()
            _ = try await controller.dataActor.createExpense(draft(id: id, foreign: facts()),
                featureAccess: FeatureAccessService(entitlements: .proSubscription))
            let context = ModelContext(controller.container)
            seedSyncControl(in: context, enabled: false, status: priorStatus,
                reason: priorStatus == .disabled ? nil : .remoteZoneDeleted)
            let bytes = Data("synthetic-retained-ancestry".utf8)
            context.insert(CloudSyncEngineState(id: "private-zone-v1", serializationData: bytes, updatedAt: date))
            let name = "expense/\(id.uuidString.lowercased())"
            context.insert(CloudSyncRecordMetadata(recordName: name, entityTypeRaw: "expense",
                acceptedRevision: 3, acceptedSemanticDigest: "retained", acceptedOperationRaw: "upsert",
                encodedSystemFields: bytes, stateRaw: "accepted", updatedAt: date))
            try context.save()
            let actor = DataActor(modelContainer: controller.container)
            let before = try await actor.fetchExpenseDetail(id: id)
            for snapshot in [try await actor.setCloudSyncEnabled(true),
                             try await actor.recoverCloudSyncFromLocalAuthority(at: date)] {
                #expect(!snapshot.isEnabled)
                #expect(snapshot.status == (priorStatus == .disabled ? .pausedForeignCurrency : priorStatus))
                #expect(snapshot.reason == (priorStatus == .disabled ? .foreignCurrencyLocalOnly : .remoteZoneDeleted))
            }
            #expect(try await actor.fetchExpenseDetail(id: id) == before)
            #expect(try await actor.cloudSyncEngineStateData() == bytes)
            #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
            #expect(try await !actor.permitsOrdinaryCloudTransport())
            let retained = ModelContext(controller.container)
            let metadata = try #require(retained.fetch(FetchDescriptor<CloudSyncRecordMetadata>()).first)
            #expect(metadata.acceptedRevision == 3 && metadata.acceptedSemanticDigest == "retained")
            #expect(metadata.encodedSystemFields == bytes)
            #expect(try retained.fetch(FetchDescriptor<CloudSyncControl>()).first?.accountIdentifierHash
                == "synthetic-retained-account")
        }
    }

    @Test func legacyCoexistencePausesWithoutRevokingOptInAndStewardshipSurvivesProExpiry() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let id = UUID()
        let pro = FeatureAccessService(entitlements: .proSubscription)
        let expired = FeatureAccessService(entitlements: .free)
        _ = try await controller.dataActor.createExpense(draft(id: id, foreign: facts()), featureAccess: pro)
        let context = ModelContext(controller.container)
        seedSyncControl(in: context, enabled: true)
        try context.save()
        let actor = DataActor(modelContainer: controller.container)
        let snapshot = try await actor.cloudSyncSnapshot()
        #expect(snapshot.isEnabled)
        #expect(snapshot.status == .pausedForeignCurrency && snapshot.reason == .foreignCurrencyLocalOnly)
        #expect(try await !actor.permitsOrdinaryCloudTransport())
        await #expect(throws: ForeignCurrencyError.syncRequiresCompanionProtocol) {
            _ = try await actor.createExpense(draft(foreign: facts()), featureAccess: pro)
        }
        // Loss of Pro does not prevent maintenance, exact accounting overrides or CSV access.
        _ = try await actor.updateExpense(id: id,
            with: draft(id: id, amount: 100, note: "retained after Pro expiry"), featureAccess: expired)
        let detail = try #require(try await actor.fetchExpenseDetail(id: id))
        #expect(detail.summary.amount.minorUnits == 100)
        #expect(detail.foreignCurrency?.source == .manualHomeAmountOverride)
        #expect(detail.foreignCurrency?.rate.denominator == 3)
        let export = try await actor.fetchExpenseExportRecords()
        #expect(export.first?.foreignCurrency == detail.foreignCurrency)
        #expect(!(try CSVExporter().export(export)).data.isEmpty)
        #expect(try await actor.cloudSyncSnapshot().isEnabled)
        _ = try await actor.setCloudSyncEnabled(false)
        #expect(try await !actor.cloudSyncSnapshot().isEnabled)
        _ = try await actor.createExpense(draft(foreign: facts()), featureAccess: pro)
        try await actor.deleteExpense(id: id)
        #expect(try await actor.fetchExpenseDetail(id: id) == nil)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 1)
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
    }

    @Test func legacyCoexistenceCanBeDisabledBeforeFirstSnapshot() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        _ = try await controller.dataActor.createExpense(draft(foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let context = ModelContext(controller.container)
        seedSyncControl(in: context, enabled: true, status: .syncing)
        try context.save()
        let actor = DataActor(modelContainer: controller.container)
        let disabled = try await actor.setCloudSyncEnabled(false)
        #expect(!disabled.isEnabled && disabled.status == .disabled && disabled.reason == nil)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 1)
        #expect(try await !actor.permitsOrdinaryCloudTransport())
    }

    @Test func retainedCompanionFootprintsPauseDeliveryWithoutDroppingBytes() async throws {
        for kind in ["metadata", "outbox", "outboxRawOnly", "inbox"] {
            let controller = try DataController(isStoredInMemoryOnly: true)
            let context = ModelContext(controller.container)
            seedSyncControl(in: context, enabled: true)
            let name = kind == "outboxRawOnly" ? "broken-companion-name"
                : "expenseForeignCurrencyMetadata/\(UUID().uuidString.lowercased())"
            let ordinaryName = "expense/\(UUID().uuidString.lowercased())"
            let bytes = Data("synthetic-opaque-retained-\(kind)".utf8)
            context.insert(CloudSyncOutboxItem(id: UUID(), recordName: ordinaryName,
                entityTypeRaw: "expense", envelopeData: bytes, semanticDigest: "retained-parent",
                statusRaw: "pending", createdAt: date, updatedAt: date, attemptCount: 2))
            if kind == "metadata" {
                context.insert(CloudSyncRecordMetadata(recordName: name,
                    entityTypeRaw: "expenseForeignCurrencyMetadata", acceptedRevision: 2,
                    acceptedSemanticDigest: "retained-child", acceptedOperationRaw: "tombstone",
                    encodedSystemFields: bytes, stateRaw: "accepted", updatedAt: date))
            } else if kind == "outbox" || kind == "outboxRawOnly" {
                context.insert(CloudSyncOutboxItem(id: UUID(), recordName: name,
                    entityTypeRaw: "expenseForeignCurrencyMetadata", envelopeData: bytes,
                    semanticDigest: "retained-child", statusRaw: "blockedByConflict",
                    createdAt: date, updatedAt: date, attemptCount: 4))
            } else {
                context.insert(CloudSyncInboxItem(id: UUID(), recordName: name, envelopeData: bytes,
                    encodedSystemFields: bytes, statusRaw: "quarantined", reasonRaw: "malformedRecord",
                    receivedAt: date, updatedAt: date))
            }
            try context.save()
            let actor = DataActor(modelContainer: controller.container)
            #expect(try await !actor.permitsOrdinaryCloudTransport())
            let snapshot = try await actor.cloudSyncSnapshot()
            #expect(snapshot.isEnabled && snapshot.status == .pausedForeignCurrency)
            #expect(snapshot.reason == .foreignCurrencyLocalOnly)
            #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
            #expect(try await actor.pendingCloudSyncRecord(named: ordinaryName) == nil)
            #expect(try await actor.pendingCloudSyncRecord(named: name) == nil)
            let retained = ModelContext(controller.container)
            let outbox = try retained.fetch(FetchDescriptor<CloudSyncOutboxItem>())
            #expect(outbox.count == (kind == "outbox" || kind == "outboxRawOnly" ? 2 : 1))
            #expect(outbox.allSatisfy { $0.envelopeData == bytes })
            #expect(outbox.first { $0.recordName == ordinaryName }?.attemptCount == 2)
            if kind == "metadata" {
                let metadata = try #require(retained.fetch(FetchDescriptor<CloudSyncRecordMetadata>()).first)
                #expect(metadata.encodedSystemFields == bytes && metadata.acceptedRevision == 2)
                #expect(metadata.acceptedOperationRaw == "tombstone")
            } else if kind == "inbox" {
                let inbox = try #require(retained.fetch(FetchDescriptor<CloudSyncInboxItem>()).first)
                #expect(inbox.envelopeData == bytes && inbox.encodedSystemFields == bytes)
                #expect(inbox.statusRaw == "quarantined" && inbox.reasonRaw == "malformedRecord")
            }
        }
    }

    @Test func incomingCompanionBatchIsDurableBeforeAnyFinancialApplication() async throws {
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await source.createExpense(draft())
        let records = try await fxRemoteRecords(source)
        #expect(records.count == 3)
        for batch in [records, Array(records.reversed())] {
            let controller = try DataController(isStoredInMemoryOnly: true)
            let receiver = controller.dataActor
            _ = try await receiver.setCloudSyncEnabled(true)
            #expect(try await receiver.permitsOrdinaryCloudTransport())
            let absentCacheScans = await receiver.foreignCurrencyTransportScanCount
            try await receiver.ingestCloudSyncRecords(batch, receivedAt: date)
            #expect(try await receiver.modelCounts().expenses == 0)
            #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
            let snapshot = try await receiver.cloudSyncSnapshot()
            #expect(snapshot.isEnabled && snapshot.status == .pausedForeignCurrency)
            #expect(snapshot.reason == .foreignCurrencyLocalOnly)
            #expect(try await !receiver.permitsOrdinaryCloudTransport())
            #expect(await receiver.foreignCurrencyTransportScanCount == absentCacheScans)
            let reopened = DataActor(modelContainer: controller.container)
            try await reopened.applyPendingCloudSyncInbox(at: date)
            #expect(try await reopened.modelCounts().expenses == 0)
            let inbox = try ModelContext(controller.container).fetch(FetchDescriptor<CloudSyncInboxItem>())
            #expect(inbox.count == batch.count)
            for record in batch {
                let retained = try #require(inbox.first { $0.recordName == record.recordName })
                #expect(retained.envelopeData == record.envelopeData)
                #expect(retained.encodedSystemFields == record.encodedSystemFields)
                #expect(retained.statusRaw != "applied")
            }
            #expect(try await reopened.pendingCloudSyncRecordNames().isEmpty)
            #expect(try await !reopened.permitsOrdinaryCloudTransport())
        }
    }

    @Test func legacyParentFirstArrivalRemainsAnExplicitCompatibilityLimit() async throws {
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        let id = UUID()
        _ = try await source.createExpense(draft(id: id, foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let records = try await fxRemoteRecords(source)
        let parent = try #require(records.first { $0.recordName.hasPrefix("expense/") })
        let child = try #require(records.first { $0.recordName.hasPrefix("expenseForeignCurrencyMetadata/") })
        let controller = try DataController(isStoredInMemoryOnly: true)
        let receiver = controller.dataActor
        _ = try await receiver.setCloudSyncEnabled(true)
        try await receiver.ingestCloudSyncRecords([parent], receivedAt: date)
        // The frozen parent carries no FX discriminator. Do not claim deferred mixed-peer
        // compatibility is solved, or retroactively delete/revalue the accepted local fact.
        let before = try #require(try await receiver.fetchExpenseDetail(id: id))
        #expect(before.foreignCurrency == nil && before.summary.amount.minorUnits == 600)
        try await receiver.ingestCloudSyncRecords([child], receivedAt: date)
        #expect(try await receiver.fetchExpenseDetail(id: id) == before)
        #expect(try await receiver.cloudSyncSnapshot().status == .pausedForeignCurrency)
        #expect(try await !receiver.permitsOrdinaryCloudTransport())
        let inbox = try ModelContext(controller.container).fetch(FetchDescriptor<CloudSyncInboxItem>())
        #expect(inbox.contains { $0.recordName == child.recordName && $0.envelopeData == child.envelopeData })
    }

    @Test func ordinarySyncRemainsAvailableButDisabledStickyAndFixtureModesCannotTransport() async throws {
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        #expect(try await !source.permitsOrdinaryCloudTransport())
        _ = try await source.setCloudSyncEnabled(true)
        #expect(try await source.permitsOrdinaryCloudTransport())
        let id = UUID()
        _ = try await source.createExpense(draft(id: id))
        let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await receiver.setCloudSyncEnabled(true)
        let ordinaryRecords = try await fxRemoteRecords(source)
        try await receiver.ingestCloudSyncRecords(ordinaryRecords, receivedAt: date)
        #expect(try await receiver.fetchExpenseDetail(id: id)?.summary.amount.minorUnits == 600)
        #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
        #expect(try await receiver.permitsOrdinaryCloudTransport())
        _ = try await source.setCloudSyncEnabled(false)
        #expect(try await !source.permitsOrdinaryCloudTransport())
        for status in [CloudSyncStatus.pausedAccountChanged, .pausedEncryptedDataReset,
                       .pausedRemoteZoneDeleted, .pausedForeignCurrency] {
            let controller = try DataController(isStoredInMemoryOnly: true)
            let context = ModelContext(controller.container)
            seedSyncControl(in: context, enabled: true, status: status)
            try context.save()
            #expect(try await !controller.dataActor.permitsOrdinaryCloudTransport())
        }
        let fixture = try DataController(isStoredInMemoryOnly: true).dataActor
        try await fixture.enableForeignCurrencyProtocolFixtures()
        _ = try await fixture.setCloudSyncEnabled(true)
        #expect(try await !fixture.permitsOrdinaryCloudTransport())
    }

    @Test func defaultReplayAndConflictResolutionCannotBypassLocalOnlyPause() async throws {
        let id = UUID()
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(id: id, foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        for record in try await fxRemoteRecords(source) {
            try await source.acknowledgeCloudSyncRecord(recordName: record.recordName,
                encodedSystemFields: Data("synthetic-ancestry".utf8), at: date)
        }
        _ = try await source.updateExpense(id: id, with: draft(id: id, amount: 100))
        let records = try await fxRemoteRecords(source)
        let controller = try DataController(isStoredInMemoryOnly: true)
        _ = try await controller.dataActor.createExpense(draft(id: id, foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let context = ModelContext(controller.container)
        seedSyncControl(in: context, enabled: true)
        for record in records {
            context.insert(CloudSyncInboxItem(id: UUID(), recordName: record.recordName,
                envelopeData: record.envelopeData, encodedSystemFields: record.encodedSystemFields,
                statusRaw: "quarantined", reasonRaw: "divergentConflict", receivedAt: date, updatedAt: date))
        }
        // A retained parent tombstone must not bypass the same pause through pending replay.
        let tombstone = try CloudSyncCodec.makeEnvelope(payload: nil, entityType: .expense,
            identity: id.uuidString.lowercased(), operation: .tombstone, revision: 1,
            parentSemanticDigest: nil, modifiedAt: date)
        let tombstoneBytes = try CloudSyncCodec.encodeEnvelope(tombstone)
        context.insert(CloudSyncInboxItem(id: UUID(), recordName: tombstone.recordName,
            envelopeData: tombstoneBytes, encodedSystemFields: nil,
            statusRaw: "pending", reasonRaw: nil, receivedAt: date, updatedAt: date))
        try context.save()
        let actor = DataActor(modelContainer: controller.container)
        let before = try await actor.fetchExpenseDetail(id: id)
        try await actor.applyPendingCloudSyncInbox(at: date)
        for resolution in [CloudSyncConflictResolution.keepLocal, .useCloud] {
            for record in records {
                await #expect(throws: ForeignCurrencyError.syncRequiresCompanionProtocol) {
                    try await actor.resolveCloudSyncConflict(recordName: record.recordName,
                        resolution: resolution, at: date)
                }
            }
        }
        #expect(try await actor.fetchExpenseDetail(id: id) == before)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 1)
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
        let retained = try ModelContext(controller.container).fetch(FetchDescriptor<CloudSyncInboxItem>())
        #expect(retained.count == records.count + 1)
        for record in records {
            let row = try #require(retained.first { $0.envelopeData == record.envelopeData })
            #expect(row.statusRaw == "quarantined" && row.reasonRaw == "divergentConflict")
            #expect(row.encodedSystemFields == record.encodedSystemFields)
        }
        #expect(retained.first { $0.envelopeData == tombstoneBytes }?.statusRaw == "pending")
        #expect(try await actor.cloudSyncSnapshot().status == .pausedForeignCurrency)
        #expect(try await !actor.permitsOrdinaryCloudTransport())
    }

    @Test func foreignTransportFootprintSurvivesAccountPauseDisableWithoutPurgingAncestry() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let context = ModelContext(controller.container)
        seedSyncControl(in: context, enabled: true, status: .pausedAccountChanged, reason: .accountChanged)
        let name = "expenseForeignCurrencyMetadata/\(UUID().uuidString.lowercased())"
        let bytes = Data("synthetic-account-pause-retained-bytes".utf8)
        context.insert(CloudSyncEngineState(id: "private-zone-v1", serializationData: bytes, updatedAt: date))
        context.insert(CloudSyncRecordMetadata(recordName: name,
            entityTypeRaw: "expenseForeignCurrencyMetadata", acceptedRevision: 4,
            acceptedSemanticDigest: "retained-accepted", acceptedOperationRaw: "upsert",
            encodedSystemFields: bytes, stateRaw: "accepted", updatedAt: date))
        context.insert(CloudSyncOutboxItem(id: UUID(), recordName: name,
            entityTypeRaw: "expenseForeignCurrencyMetadata", envelopeData: bytes,
            semanticDigest: "retained-outgoing", statusRaw: "pending", createdAt: date,
            updatedAt: date, attemptCount: 3))
        context.insert(CloudSyncInboxItem(id: UUID(), recordName: name, envelopeData: bytes,
            encodedSystemFields: bytes, statusRaw: "quarantined", reasonRaw: "divergentConflict",
            receivedAt: date, updatedAt: date))
        try context.save()
        let actor = DataActor(modelContainer: controller.container)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 0)
        #expect(try await !actor.permitsOrdinaryCloudTransport())
        let snapshot = try await actor.setCloudSyncEnabled(false)
        #expect(!snapshot.isEnabled)
        #expect(try await actor.cloudSyncEngineStateData() == bytes)
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
        let retained = ModelContext(controller.container)
        let controls = try retained.fetch(FetchDescriptor<CloudSyncControl>())
        #expect(controls.count == 1)
        #expect(controls.first?.accountIdentifierHash == "synthetic-retained-account")
        let metadata = try retained.fetch(FetchDescriptor<CloudSyncRecordMetadata>())
        #expect(metadata.count == 1 && metadata.first?.encodedSystemFields == bytes)
        #expect(metadata.first?.acceptedRevision == 4 && metadata.first?.acceptedSemanticDigest == "retained-accepted")
        let outbox = try retained.fetch(FetchDescriptor<CloudSyncOutboxItem>())
        #expect(outbox.count == 1 && outbox.first?.envelopeData == bytes)
        #expect(outbox.first?.attemptCount == 3 && outbox.first?.statusRaw == "pending")
        let inbox = try retained.fetch(FetchDescriptor<CloudSyncInboxItem>())
        #expect(inbox.count == 1 && inbox.first?.envelopeData == bytes)
        #expect(inbox.first?.encodedSystemFields == bytes && inbox.first?.statusRaw == "quarantined")
        #expect(inbox.first?.reasonRaw == "divergentConflict")
    }

    @Test func explicitCloudErasureStillAllowsLocalFXWithoutOrdinaryTransport() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.dataActor
        _ = try await actor.setCloudSyncEnabled(true)
        _ = try await actor.createExpense(draft())
        let originalRecords = try await fxRemoteRecords(actor)
        let deleting = try await actor.beginCloudDeletion(at: date)
        #expect(deleting.status == .deletingCloudData)
        let deletionRecords = try await fxRemoteRecords(actor)
        #expect(!deletionRecords.isEmpty)
        #expect(deletionRecords.map(\.envelopeData) == originalRecords.map(\.envelopeData))
        let id = UUID()
        _ = try await actor.createExpense(draft(id: id, foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 100),
            featureAccess: FeatureAccessService(entitlements: .free))
        _ = try await actor.createExpense(draft())
        #expect(try await actor.modelCounts().expenses == 3)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 1)
        #expect(try await actor.fetchExpenseDetail(id: id)?.summary.amount.minorUnits == 100)
        #expect(try await actor.cloudSyncSnapshot().status == .deletingCloudData)
        #expect(try await !actor.permitsOrdinaryCloudTransport())
        let retainedDeletionRecords = try await fxRemoteRecords(actor)
        #expect(retainedDeletionRecords.map(\.recordName) == deletionRecords.map(\.recordName))
        #expect(retainedDeletionRecords.map(\.envelopeData) == deletionRecords.map(\.envelopeData))
        for record in retainedDeletionRecords {
            #expect(try CloudSyncCodec.decodeEnvelope(#require(record.envelopeData)).operation == .upsert)
        }

        // The privacy erase exception admits local stewardship and the dedicated delete path,
        // never ordinary incoming financial changes, pending replay or conflict resolution.
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        let remoteID = UUID()
        for fixtureID in [id, remoteID] {
            _ = try await source.createExpense(draft(id: fixtureID, foreign: facts()),
                featureAccess: FeatureAccessService(entitlements: .proSubscription))
        }
        let records = try await fxRemoteRecords(source)
        let newPair = records.filter { $0.recordName.hasSuffix(remoteID.uuidString.lowercased()) }
        #expect(newPair.count == 2)
        try await actor.ingestCloudSyncRecords(newPair, receivedAt: date)
        #expect(try await actor.fetchExpenseDetail(id: remoteID) == nil)
        #expect(try await actor.modelCounts().expenses == 3)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 1)
        let context = ModelContext(controller.container)
        let tombstone = try CloudSyncCodec.makeEnvelope(payload: nil, entityType: .expense,
            identity: id.uuidString.lowercased(), operation: .tombstone, revision: 1,
            parentSemanticDigest: nil, modifiedAt: date)
        let tombstoneBytes = try CloudSyncCodec.encodeEnvelope(tombstone)
        context.insert(CloudSyncInboxItem(id: UUID(), recordName: tombstone.recordName,
            envelopeData: tombstoneBytes, encodedSystemFields: nil, statusRaw: "pending",
            reasonRaw: nil, receivedAt: date, updatedAt: date))
        let conflictPair = records.filter { $0.recordName.hasSuffix(id.uuidString.lowercased()) }
        #expect(conflictPair.count == 2)
        for record in conflictPair {
            context.insert(CloudSyncInboxItem(id: UUID(), recordName: record.recordName,
                envelopeData: record.envelopeData, encodedSystemFields: record.encodedSystemFields,
                statusRaw: "quarantined", reasonRaw: "divergentConflict", receivedAt: date, updatedAt: date))
        }
        try context.save()
        let reopened = DataActor(modelContainer: controller.container)
        let before = try await reopened.fetchExpenseDetail(id: id)
        try await reopened.applyPendingCloudSyncInbox(at: date)
        for resolution in [CloudSyncConflictResolution.keepLocal, .useCloud] {
            for record in conflictPair {
                await #expect(throws: ForeignCurrencyError.syncRequiresCompanionProtocol) {
                    try await reopened.resolveCloudSyncConflict(recordName: record.recordName,
                        resolution: resolution, at: date)
                }
            }
        }
        #expect(try await reopened.fetchExpenseDetail(id: id) == before)
        #expect(try await reopened.fetchExpenseDetail(id: remoteID) == nil)
        #expect(try await reopened.modelCounts().expenses == 3)
        #expect(try await reopened.modelCounts().foreignCurrencyMetadata == 1)
        #expect(try await reopened.cloudSyncSnapshot().status == .deletingCloudData)
        #expect(try await !reopened.permitsOrdinaryCloudTransport())
        let retainedInbox = try ModelContext(controller.container).fetch(FetchDescriptor<CloudSyncInboxItem>())
        #expect(retainedInbox.first { $0.envelopeData == tombstoneBytes }?.statusRaw == "pending")
        for record in conflictPair {
            let retained = try #require(retainedInbox.first { $0.envelopeData == record.envelopeData })
            #expect(retained.statusRaw == "quarantined" && retained.reasonRaw == "divergentConflict")
        }
    }

    @Test func createEditOverrideAndDeleteAreAtomicAndRetainTheSavedCurrency() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let id = UUID()
        let value = try facts()
        #expect(value.rateDate == calendar.startOfDay(for: date))
        _ = try await actor.createExpense(draft(id: id, foreign: value), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 1)
        #expect(try await actor.fetchExpenseDetail(id: id)?.foreignCurrency == value)
        _ = try await actor.updateExpense(id: id, with: draft(id: id, note: "edited"))
        #expect(try await actor.fetchExpenseDetail(id: id)?.foreignCurrency == value)
        _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 100))
        let detail = try #require(try await actor.fetchExpenseDetail(id: id))
        #expect(detail.summary.amount == Money(minorUnits: 100, currencyCode: "USD"))
        #expect(detail.foreignCurrency?.source == .manualHomeAmountOverride)
        #expect(detail.foreignCurrency?.rate.denominator == 3)
        #expect(detail.foreignCurrency?.rateDate == value.rateDate)
        // A draft made from newly changed Settings cannot revalue a previously saved row.
        await #expect(throws: (any Error).self) {
            _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 100, currency: "JPY"))
        }
        #expect(try await actor.fetchExpenseDetail(id: id) == detail)
        await #expect(throws: ForeignCurrencyError.self) {
            _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 101, foreign: value))
        }
        #expect(try await actor.fetchExpenseDetail(id: id) == detail)
        // Switching back to a manual rate restores its provenance explicitly.
        _ = try await actor.updateExpense(id: id, with: draft(id: id, foreign: value))
        #expect(try await actor.fetchExpenseDetail(id: id)?.foreignCurrency?.source == .manualRate)
        try await actor.deleteExpense(id: id)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 0)
        #expect(try await actor.modelCounts().expenses == 0)
    }

    @Test func formEntryUsesSettingsForNewRowsButTheSavedCurrencyForEdits() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let id = UUID()
        let value = try facts()
        _ = try await actor.createExpense(draft(id: id, foreign: value), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let detail = try #require(try await actor.fetchExpenseDetail(id: id))
        let changedSettingsCurrency = "JPY"
        let newForm = AddExpenseView(dataActor: actor, accountingCurrencyCode: changedSettingsCurrency,
                                    existingExpense: nil, completed: {})
        #expect(newForm.accountingCurrencyCode == "JPY")
        let editForm = AddExpenseView(dataActor: actor, accountingCurrencyCode: changedSettingsCurrency,
                                     existingExpense: detail, completed: {})
        #expect(editForm.accountingCurrencyCode == "USD")
        let model = ExpenseFormViewModel(existingExpense: detail, now: date)
        model.prepareInput(locale: Locale(identifier: "en_US"))
        model.note = "edit after Settings changed"
        let result = await model.submit(dataActor: actor, currencyCode: editForm.accountingCurrencyCode,
            bucket: .discretionary, locale: Locale(identifier: "en_US"), now: date,
            timeZone: calendar.timeZone, cycleStartDay: 1, calendar: calendar)
        guard case .saved = result else { Issue.record("Existing FX form did not save"); return }
        let saved = try #require(try await actor.fetchExpenseDetail(id: id))
        #expect(saved.summary.amount == detail.summary.amount)
        #expect(saved.foreignCurrency == value)
        #expect(saved.note == model.note)
    }

    @Test func failedCreatesUnsupportedSourcesAndDuplicateIDsLeaveNoPartialRows() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        let value = try facts()
        for source in ExpenseSource.allCases where source != .manual {
            await #expect(throws: ForeignCurrencyError.unsupportedSource) {
                _ = try await actor.createExpense(draft(foreign: value, source: source), featureAccess: FeatureAccessService(entitlements: .proSubscription))
            }
        }
        await #expect(throws: ForeignCurrencyError.unsupportedSource) {
            _ = try await actor.createExpense(draft(foreign: value, recurring: true), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        }
        await #expect(throws: ForeignCurrencyError.invalidRate) {
            _ = try await actor.createExpense(draft(amount: 601, foreign: value), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        }
        await #expect(throws: DataValidationError.invalidIntentExpense) {
            _ = try await actor.createIntentExpense(draft(foreign: value, source: .siriIntent), dedupeSince: date)
        }
        #expect(try await actor.modelCounts().isEmpty)
        let id = UUID()
        _ = try await actor.createExpense(draft(id: id, foreign: value), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        await #expect(throws: DataValidationError.identityMismatch) {
            _ = try await actor.createExpense(draft(id: id), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        }
        #expect(try await actor.fetchExpenseDetail(id: id)?.foreignCurrency == value)
        try await actor.deleteAllUserData()
        #expect(try await actor.modelCounts().isEmpty)
    }

    @Test func foreignExportIsAnImmutableValidatedSnapshotAndCorruptionFailsClosed() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let actor = controller.dataActor
        let id = UUID()
        let value = try facts()
        _ = try await actor.createExpense(draft(id: id, foreign: value),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await actor.createExpense(draft())
        let records = try await actor.fetchExpenseExportRecords()
        #expect(records.count == 2)
        #expect(records.first { $0.id == id }?.foreignCurrency == value)
        #expect(records.first { $0.id != id }?.foreignCurrency == nil)
        let frozenCSV = try CSVExporter().export(records)

        // Stewardship after Pro loss changes the current row, not an already captured export.
        _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 100))
        #expect(try CSVExporter().export(records) == frozenCSV)
        let edited = try await actor.fetchExpenseExportRecords()
        #expect(edited.first { $0.id == id }?.amount.minorUnits == 100)
        #expect(edited.first { $0.id == id }?.foreignCurrency?.source == .manualHomeAmountOverride)
        #expect(try CSVExporter().export(edited) != frozenCSV)

        let context = ModelContext(controller.container)
        let metadata = try #require(context.fetch(FetchDescriptor<ExpenseForeignCurrencyMetadata>()).first)
        metadata.rateSourceRaw = "unknown-source"
        try context.save()
        let reopened = DataActor(modelContainer: controller.container)
        await #expect(throws: ForeignCurrencyError.unreadableMetadata) {
            _ = try await reopened.fetchExpenseExportRecords()
        }
        // A failed export neither strips the damaged tuple nor guesses/revalues the home amount.
        #expect(try await reopened.modelCounts().foreignCurrencyMetadata == 1)
        #expect(try await reopened.fetchExpenseSummaries().first { $0.id == id }?.amount.minorUnits == 100)
    }

    @Test func lockedAccountingConsumersMatchOrdinaryRowsAcrossForeignMetadataVariants() async throws {
        let id = UUID()
        let cycle = try BudgetCycleCalculator().interval(containing: date, startDay: 1, calendar: calendar)
        let plan = BudgetPlanDraft(id: UUID(), cycleStart: cycle.start, cycleEnd: cycle.end,
            currencyCode: "USD", monthlyIncomeMinorUnits: 100_000, totalBudgetMinorUnits: 90_000,
            fixedExpensesMinorUnits: 10_000, savingGoalMinorUnits: 5_000,
            createdAt: date, updatedAt: date, categoryBudgets: [])
        let ordinaryActor = try DataController(isStoredInMemoryOnly: true).dataActor
        _ = try await ordinaryActor.createBudgetPlan(plan)
        _ = try await ordinaryActor.createExpense(draft(id: id))
        let ordinary = try await ordinaryActor.fetchExpenseSummaries()
        let ordinaryDashboard = DashboardViewModel()
        await ordinaryDashboard.load(dataActor: ordinaryActor, currencyCode: "USD",
            cycleStartDay: 1, calendar: calendar, now: date)
        guard case let .configured(expectedBudget, expectedPace, _, _) = ordinaryDashboard.state else {
            Issue.record("Expected configured ordinary baseline"); return
        }
        #expect(expectedBudget.spentTotal == Money(minorUnits: 600, currencyCode: "USD"))
        let expectedInsights = try InsightSummaryBuilder().build(expenses: ordinary, cycle: cycle,
            currencyCode: "USD", now: date, calendar: calendar)
        let purchase = Money(minorUnits: 500, currencyCode: "USD")
        let expectedImpact = try BudgetEngine().impact(of: purchase, category: .food,
            bucket: .discretionary, snapshot: expectedBudget, categoryBudgets: [])

        let original = Money(minorUnits: 999_999, currencyCode: "JPY")
        let override = try ExpenseForeignCurrency(original: original,
            rate: ForeignCurrencyConverter().effectiveRate(original: original,
                accounting: Money(minorUnits: 600, currencyCode: "USD")),
            selectedDate: calendar.date(byAdding: .month, value: -1, to: date)!,
            calendar: calendar, source: .manualHomeAmountOverride)
        for value in [try facts(), override] {
            let actor = try DataController(isStoredInMemoryOnly: true).dataActor
            _ = try await actor.createBudgetPlan(plan)
            _ = try await actor.createExpense(draft(id: id, foreign: value),
                featureAccess: FeatureAccessService(entitlements: .proSubscription))
            let summaries = try await actor.fetchExpenseSummaries()
            #expect(summaries == ordinary)
            let dashboard = DashboardViewModel()
            // Changed Settings currency cannot override the saved plan/expense authority.
            await dashboard.load(dataActor: actor, currencyCode: "JPY", cycleStartDay: 1,
                calendar: calendar, now: date)
            guard case let .configured(budget, pace, _, _) = dashboard.state else {
                Issue.record("Expected configured FX Dashboard"); continue
            }
            #expect(budget == expectedBudget)
            #expect(pace == expectedPace)
            #expect(try BudgetEngine().impact(of: purchase, category: .food,
                bucket: .discretionary, snapshot: budget, categoryBudgets: []) == expectedImpact)
            let insights = try InsightSummaryBuilder().build(expenses: summaries, cycle: cycle,
                currencyCode: "USD", now: date, calendar: calendar)
            #expect(insights == expectedInsights)
            #expect(insights.currentCycleTotal.minorUnits == 600)
            #expect(insights.categoryTotals.first?.amount.minorUnits == 600)
            let log = ExpenseListViewModel()
            await log.load(dataActor: actor)
            #expect(!log.failed)
            #expect(log.filteredExpenses == ordinary)
            let indexer = SpotlightIndexingService(client: FXPrivacySpotlightClient(),
                capability: SystemIntegrationCapability(siriProductEnabled: true,
                    spotlightProductEnabled: true, siriRuntimeAvailable: { true },
                    spotlightRuntimeAvailable: { true }))

            for locale in [Locale(identifier: "en_US"), Locale(identifier: "zh_Hans_CN")] {
                func documents(_ rows: [ExpenseSummary]) async -> [SpotlightDocument] {
                    await indexer.makeDocuments(expenses: rows, plans: [], wishItems: [],
                        coolingPlans: [], merchants: [], eligibleMerchantKeys: [], insights: [],
                        indexMerchantNames: false, now: date, calendar: calendar, locale: locale)
                }
                let indexed = await documents(summaries)
                let expectedIndexed = await documents(ordinary)
                #expect(indexed == expectedIndexed)
                #expect(indexed.filter { $0.identifier == MindBudgetSearchIdentifier.expense(id) }.count == 1)
                let text = indexed.flatMap { [$0.title, $0.contentDescription] + $0.keywords }.joined(separator: " ")
                for secret in ["EUR", "JPY", "999999", "America/New_York", "manualHomeAmountOverride", "trip", "Cafe"] {
                    #expect(!text.contains(secret))
                }
                func request(_ rows: [ExpenseSummary], _ snapshot: ConfiguredBudgetSnapshot) -> AskMindBudgetRequest {
                    AskMindBudgetRequest(question: locale.language.languageCode?.identifier == "zh"
                        ? "这个周期还剩多少？" : "How much is left?",
                        purchaseAmount: nil, purchaseCategory: nil, purchaseBucket: nil,
                        snapshot: snapshot, expenses: rows, wishItems: [], locale: locale,
                        calendar: calendar, tone: .soft, enhancementEnabled: false,
                        premiumEntryAccess: ExistingPremiumEntryAccess())
                }
                let expectedAnswer = await AskMindBudgetService().answer(request(ordinary, expectedBudget))
                let answer = await AskMindBudgetService().answer(request(summaries, budget))
                #expect(answer == expectedAnswer)
                let expectedReport = await CycleSummaryService().generate(snapshot: .configured(expectedBudget),
                    expenses: ordinary, coolingOffPlans: [], locale: locale, calendar: calendar,
                    tone: .soft, enhancementEnabled: false, premiumEntryAccess: ExistingPremiumEntryAccess())
                let report = await CycleSummaryService().generate(snapshot: .configured(budget),
                    expenses: summaries, coolingOffPlans: [], locale: locale, calendar: calendar,
                    tone: .soft, enhancementEnabled: false, premiumEntryAccess: ExistingPremiumEntryAccess())
                #expect(report == expectedReport)

                // Capture the real redaction seam with a local test double, never a model/API.
                // Enabling the injected capability proves that the context was actually built.
                let probe = FXPrivacyModelProbe()
                let access = ExistingPremiumEntryAccess(featureAccess: DebugFeatureAccessProvider(entitlements: .proSubscription))
                for rows in [ordinary, summaries] {
                    _ = await CycleSummaryService(model: probe, runtimeAvailability: { _ in .available }).generate(
                        snapshot: .configured(budget), expenses: rows, coolingOffPlans: [],
                        locale: locale, calendar: calendar, tone: .soft, enhancementEnabled: true,
                        premiumEntryAccess: access)
                    _ = await AskMindBudgetService(modelFactory: { _ in probe }, runtimeAvailability: { _ in .available }).answer(
                        AskMindBudgetRequest(question: "How much is left?", purchaseAmount: nil,
                            purchaseCategory: nil, purchaseBucket: nil, snapshot: budget, expenses: rows,
                            wishItems: [], locale: locale, calendar: calendar, tone: .soft,
                            enhancementEnabled: true, premiumEntryAccess: access))
                }
                let prompts = await probe.prompts
                #expect(prompts.count == 4)
                #expect(Array(prompts.prefix(2)) == Array(prompts.suffix(2)))
                for secret in ["EUR", "JPY", "999999", "America/New_York", "rateNumerator", "rateSourceRaw", "trip", "Cafe"] {
                    #expect(!prompts.joined().contains(secret))
                }
            }
        }
    }

    @Test func lockedAccountingReminderMessagesAndRedactedPromptsMatchOrdinaryRows() async throws {
        let id = UUID()
        let cycle = try BudgetCycleCalculator().interval(containing: date, startDay: 1, calendar: calendar)
        let plan = BudgetPlanDraft(id: UUID(), cycleStart: cycle.start, cycleEnd: cycle.end,
            currencyCode: "USD", monthlyIncomeMinorUnits: 10_000, totalBudgetMinorUnits: 1_000,
            fixedExpensesMinorUnits: 100, savingGoalMinorUnits: 100,
            createdAt: date, updatedAt: date, categoryBudgets: [])
        let original = Money(minorUnits: 999_999, currencyCode: "JPY")
        let override = try ExpenseForeignCurrency(original: original,
            rate: ForeignCurrencyConverter().effectiveRate(original: original,
                accounting: Money(minorUnits: 600, currencyCode: "USD")),
            selectedDate: date, calendar: calendar, source: .manualHomeAmountOverride)
        func bytes(_ message: ReminderMessage) throws -> Data {
            try JSONSerialization.data(withJSONObject: [
                "title": message.title, "body": message.body,
                "details": message.supportingDetails, "actions": message.actions.map(\.rawValue),
                "severity": message.severity.rawValue, "channel": message.channel.rawValue,
                "source": message.source.rawValue
            ], options: [.sortedKeys])
        }
        let access = ExistingPremiumEntryAccess(featureAccess: DebugFeatureAccessProvider(entitlements: .proSubscription))
        for locale in [Locale(identifier: "en_US"), Locale(identifier: "zh_Hans_CN")] {
            for tone in [ReminderTone.soft, .direct, .minimal] {
                var templateBytes: [Data] = []
                var fallbackBytes: [Data] = []
                var capturedPrompts: [[String]] = []
                // First result is the ordinary reference; the same accounting row receives
                // either complete FX variant. The potential purchase uses only that summary.
                for foreign in [nil, try facts(), override] as [ExpenseForeignCurrency?] {
                    let actor = try DataController(isStoredInMemoryOnly: true).dataActor
                    _ = try await actor.createBudgetPlan(plan)
                    _ = try await actor.createExpense(draft(id: id, foreign: foreign),
                        featureAccess: FeatureAccessService(entitlements: .proSubscription))
                    let rows = try await actor.fetchExpenseSummaries()
                    let row = try #require(rows.first)
                    let dashboard = DashboardViewModel()
                    await dashboard.load(dataActor: actor, currencyCode: "JPY", cycleStartDay: 1,
                        calendar: calendar, now: date)
                    guard case let .configured(snapshot, _, _, _) = dashboard.state else {
                        Issue.record("Expected configured reminder fixture"); return
                    }
                    let candidate = PurchaseCandidate(name: nil, amount: row.amount, category: row.category,
                        bucket: row.bucket, reason: row.purchaseReason, emotionTag: row.emotionTag)
                    let impact = try BudgetEngine().impact(of: candidate.amount, category: candidate.category,
                        bucket: candidate.bucket, snapshot: snapshot, categoryBudgets: [])
                    let drafts = SpendingPatternDetector().evaluatePotentialPurchase(candidate: candidate,
                        expenses: rows, snapshot: .configured(snapshot), categoryBudgets: [], historicalCycles: [],
                        config: .defaults(currencyCode: "USD"), now: date, calendar: calendar)
                    #expect(!drafts.isEmpty, "Do not compare two absent reminders")
                    let engine = ReminderEngine()
                    let context = engine.buildContext(candidate: candidate, impact: impact,
                        snapshot: .configured(snapshot), drafts: drafts, tone: tone)
                    let template = try #require(await engine.generateReminder(context: context, channel: .sheet, locale: locale))
                    #expect(template.source == .template)
                    #expect((2...4).contains(template.actions.count))
                    #expect(template.actions.contains(.continuePurchase))
                    templateBytes.append(try bytes(template))

                    let probe = FXPrivacyModelProbe()
                    let modelEngine = ReminderEngine(aiEnhancementEnabled: true, premiumEntryAccess: access,
                        aiGenerator: probe, aiRuntimeAvailability: { _ in .available })
                    let fallback = try #require(await modelEngine.generateReminder(context: context, channel: .sheet, locale: locale))
                    #expect(fallback.source == .modelErrorFallback)
                    fallbackBytes.append(try bytes(fallback))
                    let prompts = await probe.prompts
                    #expect(prompts.count == 1, "The actual reminder redaction seam must execute")
                    capturedPrompts.append(prompts)
                    for secret in ["EUR", "JPY", "999999", "America/New_York", "rateNumerator", "manualRate", "manualHomeAmountOverride", "trip", "Cafe"] {
                        #expect(!prompts.joined().contains(secret))
                    }
                }
                #expect(templateBytes.count == 3 && Set(templateBytes).count == 1)
                #expect(fallbackBytes.count == 3 && Set(fallbackBytes).count == 1)
                let first = try #require(capturedPrompts.first?.first)
                #expect(capturedPrompts.allSatisfy { $0.count == 1 && Array($0[0].utf8) == Array(first.utf8) })
            }
        }
    }

    @Test func foreignSyncStagesSeparateFactsAndDisabledWritesStayLocal() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
        try await actor.enableForeignCurrencyProtocolFixtures()
        let id = UUID()
        _ = try await actor.createExpense(draft(id: id, foreign: facts()), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        #expect(try await actor.pendingCloudSyncRecordNames().isEmpty)
        _ = try await actor.setCloudSyncEnabled(true)
        #expect(try await actor.pendingCloudSyncRecordNames().count == 2)
        _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 100))
        #expect(try await actor.pendingCloudSyncRecordNames().count == 2)
        _ = try await actor.setCloudSyncEnabled(false)
        _ = try await actor.createExpense(draft(foreign: facts()), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await actor.setCloudSyncEnabled(true)
        #expect(try await actor.pendingCloudSyncRecordNames().count == 4)
        try await actor.deleteAllUserData()
        _ = try await actor.setCloudSyncEnabled(true)
        #expect(try await actor.cloudSyncSnapshot().isEnabled)
    }

    private func fxRemoteRecords(_ actor: DataActor) async throws -> [CloudSyncRemoteRecord] {
        var records: [CloudSyncRemoteRecord] = []
        for name in try await actor.pendingCloudSyncRecordNames() {
            let pending = try #require(try await actor.pendingCloudSyncRecord(named: name))
            records.append(CloudSyncRemoteRecord(recordName: name, envelopeData: pending.envelopeData,
                encodedSystemFields: Data("synthetic-system-fields".utf8), wasPhysicallyDeleted: false))
        }
        return records
    }

    @Test func foreignSyncFrozenParentAndCompleteCompanionRoundTripInAnyArrivalOrder() async throws {
        let id = UUID()
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        let ordinary = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await ordinary.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(id: id, foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await ordinary.createExpense(draft(id: id))
        let records = try await fxRemoteRecords(source)
        let parent = try #require(records.first { $0.recordName.hasPrefix("expense/") })
        let child = try #require(records.first { $0.recordName.hasPrefix("expenseForeignCurrencyMetadata/") })
        let oldParent = try #require(try await fxRemoteRecords(ordinary).first)
        let parentEnvelope = try CloudSyncCodec.decodeEnvelope(try #require(parent.envelopeData))
        let oldEnvelope = try CloudSyncCodec.decodeEnvelope(try #require(oldParent.envelopeData))
        // Informational envelope modifiedAt is staging time, not frozen ledger content.
        #expect(parentEnvelope.payload == oldEnvelope.payload)
        #expect(parentEnvelope.semanticDigest == oldEnvelope.semanticDigest)
        #expect(parentEnvelope.schemaVersion == oldEnvelope.schemaVersion)
        #expect(parentEnvelope.revision == oldEnvelope.revision)
        #expect(parentEnvelope.parentSemanticDigest == oldEnvelope.parentSemanticDigest)
        let envelope = try CloudSyncCodec.decodeEnvelope(try #require(child.envelopeData))
        #expect(envelope.schemaVersion == 1)
        #expect(envelope.payload?.identity == id.uuidString.lowercased())
        #expect(Set(envelope.payload?.fields.keys.map { $0 } ?? []) == Set([
            "expenseID", "originalAmountMinorUnits", "originalCurrencyCode", "rateNumerator",
            "rateDenominator", "rateDate", "rateTimeZoneIdentifier", "rateSourceRaw"]))
        #expect(CloudSyncEntityType.allCases.count == 13)
        let parentIndex = try #require(CloudSyncEntityType.applicationOrder.firstIndex(of: .expense))
        #expect(CloudSyncEntityType.applicationOrder[parentIndex + 1] == .expenseForeignCurrencyMetadata)

        for batches in [[[child, parent]], [[child], [parent]], [[parent], [child]],
                        [[parent, child, parent, child]], [[child, child], [parent]]] {
            let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
            try await receiver.enableForeignCurrencyProtocolFixtures()
            _ = try await receiver.setCloudSyncEnabled(true)
            for batch in batches { try await receiver.ingestCloudSyncRecords(batch, receivedAt: date) }
            let result = try #require(try await receiver.fetchExpenseDetail(id: id))
            #expect(try result.foreignCurrency == facts())
            #expect(result.summary.amount.minorUnits == 600)
            #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 0)
            #expect(try await receiver.pendingCloudSyncRecordNames().isEmpty)
            try await receiver.ingestCloudSyncRecords(records, receivedAt: date)
            #expect(try await receiver.modelCounts().expenses == 1)
            #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 1)
        }
    }

    @Test func foreignSyncUpdatesWaitForMatchingParentAndCommitBothOrNeither() async throws {
        for childFirst in [false, true] {
            let id = UUID()
            let source = try DataController(isStoredInMemoryOnly: true).dataActor
            let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
            try await source.enableForeignCurrencyProtocolFixtures()
            try await receiver.enableForeignCurrencyProtocolFixtures()
            _ = try await source.setCloudSyncEnabled(true)
            _ = try await receiver.setCloudSyncEnabled(true)
            _ = try await source.createExpense(draft(id: id, foreign: facts()),
                featureAccess: FeatureAccessService(entitlements: .proSubscription))
            let first = try await fxRemoteRecords(source)
            try await receiver.ingestCloudSyncRecords(first, receivedAt: date)
            for record in first {
                try await source.acknowledgeCloudSyncRecord(recordName: record.recordName,
                    encodedSystemFields: Data(), at: date)
            }
            let before = try await receiver.fetchExpenseDetail(id: id)
            _ = try await source.updateExpense(id: id, with: draft(id: id, amount: 100))
            let edited = try await fxRemoteRecords(source)
            let parent = try #require(edited.first { $0.recordName.hasPrefix("expense/") })
            let child = try #require(edited.first { !$0.recordName.hasPrefix("expense/") })
            try await receiver.ingestCloudSyncRecords([childFirst ? child : parent], receivedAt: date)
            #expect(try await receiver.fetchExpenseDetail(id: id) == before)
            try await receiver.ingestCloudSyncRecords([childFirst ? parent : child], receivedAt: date)
            #expect(try await receiver.fetchExpenseDetail(id: id)?.summary.amount.minorUnits == 100)
            #expect(try await receiver.fetchExpenseDetail(id: id)?.foreignCurrency?.source == .manualHomeAmountOverride)
            #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 0)
            try await receiver.ingestCloudSyncRecords(edited, receivedAt: date)
            #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 1)
        }
    }

    @Test func foreignSyncMalformedCohortsQuarantineWithoutChangingAccountingOrCreatingOrphans() async throws {
        let id = UUID()
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(id: id, foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let records = try await fxRemoteRecords(source)
        let parent = try #require(records.first { $0.recordName.hasPrefix("expense/") })
        let child = try #require(records.first { !$0.recordName.hasPrefix("expense/") })
        let envelope = try CloudSyncCodec.decodeEnvelope(try #require(child.envelopeData))
        let original = try #require(envelope.payload)
        let corruptions: [(inout [String: CloudSyncValue]) -> Void] = [
            { $0.removeValue(forKey: "rateDenominator") },
            { $0["extra"] = .string("not-allowed") },
            { $0["rateDenominator"] = .integer(0) },
            { $0["rateNumerator"] = .integer(3) },
            { $0["rateSourceRaw"] = .string("automatic") },
            { $0["rateTimeZoneIdentifier"] = .string("not/a-zone") },
            { $0["originalCurrencyCode"] = .string("USD") },
            { $0["expenseID"] = .string(UUID().uuidString.lowercased()) }
        ]
        for corrupt in corruptions {
            let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
            try await receiver.enableForeignCurrencyProtocolFixtures()
            _ = try await receiver.setCloudSyncEnabled(true)
            var fields = original.fields
            corrupt(&fields)
            let bad = try CloudSyncCodec.makeEnvelope(payload: CloudSyncPayload(entityType: .expenseForeignCurrencyMetadata,
                identity: original.identity, fields: fields), entityType: .expenseForeignCurrencyMetadata,
                identity: original.identity, operation: .upsert, revision: 1, parentSemanticDigest: nil, modifiedAt: date)
            let malformed = CloudSyncRemoteRecord(recordName: child.recordName,
                envelopeData: try CloudSyncCodec.encodeEnvelope(bad), encodedSystemFields: nil, wasPhysicallyDeleted: false)
            try await receiver.ingestCloudSyncRecords([parent, malformed], receivedAt: date)
            #expect(try await receiver.modelCounts().expenses == 0)
            #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
            #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 2)
            // Quarantined remote data does not block unrelated local recording.
            _ = try await receiver.createExpense(draft())
            #expect(try await receiver.modelCounts().expenses == 1)
        }
    }

    @Test func foreignSyncUndecodableCompanionCannotBecomeAParentOnlyImport() async throws {
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let records = try await fxRemoteRecords(source)
        let parent = try #require(records.first { $0.recordName.hasPrefix("expense/") })
        let child = try #require(records.first { !$0.recordName.hasPrefix("expense/") })
        for data in [Data("not-json".utf8), Data()] {
            let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
            try await receiver.enableForeignCurrencyProtocolFixtures()
            _ = try await receiver.setCloudSyncEnabled(true)
            try await receiver.ingestCloudSyncRecords([parent, CloudSyncRemoteRecord(
                recordName: child.recordName, envelopeData: data, encodedSystemFields: nil,
                wasPhysicallyDeleted: false)], receivedAt: date)
            #expect(try await receiver.modelCounts().expenses == 0)
            #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
            #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 2)
        }
    }

    @Test func foreignSyncSecondLineageFailureRollsBackTheWholeCohort() async throws {
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let records = try await fxRemoteRecords(source)
        let parent = try #require(records.first { $0.recordName.hasPrefix("expense/") })
        let child = try #require(records.first { !$0.recordName.hasPrefix("expense/") })
        let original = try CloudSyncCodec.decodeEnvelope(try #require(child.envelopeData))
        let bad = try CloudSyncCodec.makeEnvelope(payload: original.payload,
            entityType: original.entityType, identity: CloudSyncCodec.identity(from: child.recordName),
            operation: .upsert, revision: 2, parentSemanticDigest: original.semanticDigest, modifiedAt: date)
        let controller = try DataController(isStoredInMemoryOnly: true)
        let receiver = controller.dataActor
        try await receiver.enableForeignCurrencyProtocolFixtures()
        _ = try await receiver.setCloudSyncEnabled(true)
        try await receiver.ingestCloudSyncRecords([parent, CloudSyncRemoteRecord(recordName: child.recordName,
            envelopeData: CloudSyncCodec.encodeEnvelope(bad), encodedSystemFields: Data([1]),
            wasPhysicallyDeleted: false)], receivedAt: date)
        let reopened = DataActor(modelContainer: controller.container)
        try await reopened.enableForeignCurrencyProtocolFixtures()
        #expect(try await reopened.modelCounts().expenses == 0)
        #expect(try await reopened.modelCounts().foreignCurrencyMetadata == 0)
        #expect(try await reopened.cloudSyncSnapshot().quarantinedCount == 2)
        #expect(try await reopened.pendingCloudSyncRecordNames().isEmpty)
        #expect(try ModelContext(controller.container).fetchCount(FetchDescriptor<CloudSyncRecordMetadata>()) == 0)
    }

    @Test func foreignSyncConflictsRequireOneExplicitAtomicFinancialChoice() async throws {
        for localAmount: Int64 in [200, 600] {
        for resolution in [CloudSyncConflictResolution.keepLocal, .useCloud] {
            let id = UUID()
            let source = try DataController(isStoredInMemoryOnly: true).dataActor
            let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
            try await source.enableForeignCurrencyProtocolFixtures()
            try await receiver.enableForeignCurrencyProtocolFixtures()
            _ = try await source.setCloudSyncEnabled(true)
            _ = try await receiver.setCloudSyncEnabled(true)
            _ = try await source.createExpense(draft(id: id, foreign: facts()),
                featureAccess: FeatureAccessService(entitlements: .proSubscription))
            let first = try await fxRemoteRecords(source)
            try await receiver.ingestCloudSyncRecords(first, receivedAt: date)
            for record in first {
                try await source.acknowledgeCloudSyncRecord(recordName: record.recordName,
                    encodedSystemFields: Data([1]), at: date)
            }
            _ = try await source.updateExpense(id: id, with: draft(id: id, amount: 100))
            _ = try await receiver.updateExpense(id: id, with: draft(id: id, amount: localAmount, note: "local edit"))
            let before = try await receiver.fetchExpenseDetail(id: id)
            let remote = try await fxRemoteRecords(source)
            try await receiver.ingestCloudSyncRecords(remote, receivedAt: date)
            #expect(try await receiver.fetchExpenseDetail(id: id) == before)
            #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 2)
            let conflicts = try await receiver.cloudSyncConflictSummaries()
            #expect(conflicts.count == 2)
            #expect(conflicts.contains { $0.canResolve })
            // Choosing either row resolves the financial pair, never one half of it.
            try await receiver.resolveCloudSyncConflict(
                recordName: "expenseForeignCurrencyMetadata/\(id.uuidString.lowercased())",
                resolution: resolution, at: date)
            let detail = try #require(try await receiver.fetchExpenseDetail(id: id))
            #expect(detail.summary.amount.minorUnits == (resolution == .keepLocal ? localAmount : 100))
            try #require(detail.foreignCurrency).validate(accounting: detail.summary.amount)
            #expect(try await receiver.cloudSyncSnapshot().quarantinedCount == 0)
            let outgoing = try await fxRemoteRecords(receiver)
            #expect(outgoing.count == (resolution == .keepLocal ? 2 : 0))
            for record in outgoing {
                let result = try CloudSyncCodec.decodeEnvelope(try #require(record.envelopeData))
                let previous = try #require(remote.first { $0.recordName == record.recordName })
                let accepted = try CloudSyncCodec.decodeEnvelope(try #require(previous.envelopeData))
                #expect(result.revision == 3)
                #expect(result.parentSemanticDigest == accepted.semanticDigest)
            }
        }
        }
    }

    @Test func foreignSyncDeletionIsScopedAndParentTombstonesPreventResurrection() async throws {
        let id = UUID()
        let source = try DataController(isStoredInMemoryOnly: true).dataActor
        try await source.enableForeignCurrencyProtocolFixtures()
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(id: id, foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let first = try await fxRemoteRecords(source)
        for record in first {
            try await source.acknowledgeCloudSyncRecord(recordName: record.recordName,
                encodedSystemFields: Data([1]), at: date)
        }
        try await source.deleteExpense(id: id)
        let deleted = try await fxRemoteRecords(source)
        #expect(deleted.count == 2)
        for record in deleted {
            #expect(try CloudSyncCodec.decodeEnvelope(try #require(record.envelopeData)).operation == .tombstone)
        }
        let parent = try #require(deleted.first { $0.recordName.hasPrefix("expense/") })
        let child = try #require(deleted.first { !$0.recordName.hasPrefix("expense/") })
        for childOnly in [true, false] {
            let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
            try await receiver.enableForeignCurrencyProtocolFixtures()
            _ = try await receiver.setCloudSyncEnabled(true)
            try await receiver.ingestCloudSyncRecords(first, receivedAt: date)
            try await receiver.ingestCloudSyncRecords(childOnly ? [child] : [parent], receivedAt: date)
            #expect(try await receiver.modelCounts().expenses == (childOnly ? 1 : 0))
            #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
            try await receiver.ingestCloudSyncRecords(first, receivedAt: date)
            #expect(try await receiver.modelCounts().expenses == (childOnly ? 1 : 0))
            #expect(try await receiver.modelCounts().foreignCurrencyMetadata == 0)
        }
        let disabled = try DataController(isStoredInMemoryOnly: true).dataActor
        try await disabled.ingestCloudSyncRecords(first, receivedAt: date)
        #expect(try await disabled.modelCounts().isEmpty)
    }

    @Test func downstreamFailureRollsBackBothTheExpenseAndCompanion() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let id = UUID()
        let otherID = UUID()
        let value = try facts()
        _ = try await controller.dataActor.createExpense(draft(id: id, foreign: value), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await controller.dataActor.createExpense(draft(id: otherID), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        // A corrupt adjacent legacy row forces merchant rebuilding to fail AFTER both the
        // expense and its companion have been mutated, not merely during input validation.
        let context = ModelContext(controller.container)
        let other = try #require(context.fetch(FetchDescriptor<Expense>()).first { $0.id == otherID })
        other.categoryRaw = "invalid-category"
        try context.save()
        let actor = DataActor(modelContainer: controller.container)
        let before = try #require(try await actor.fetchExpenseDetail(id: id))
        await #expect(throws: (any Error).self) {
            _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 100, note: "must roll back"))
        }
        #expect(try await actor.fetchExpenseDetail(id: id) == before)
        await #expect(throws: (any Error).self) {
            _ = try await actor.createExpense(draft(foreign: value), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        }
        #expect(try await actor.modelCounts().expenses == 2)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 1)
        let reopened = DataActor(modelContainer: controller.container)
        #expect(try await reopened.fetchExpenseDetail(id: id) == before)
        try await reopened.deleteAllUserData()
    }

    @Test func explicitFXRecoveryStagesBothFactsAndCloudErasureNeverBlocksLocalRecording() async throws {
        let controller = try DataController(isStoredInMemoryOnly: true)
        let id = UUID()
        _ = try await controller.dataActor.createExpense(draft(id: id, foreign: facts()), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let context = ModelContext(controller.container)
        context.insert(CloudSyncControl(id: "primary", isEnabled: false,
            statusRaw: CloudSyncStatus.pausedRemoteZoneDeleted.rawValue, accountIdentifierHash: "test",
            consentVersion: 1, lastReasonRaw: CloudSyncReasonCode.remoteZoneDeleted.rawValue, updatedAt: date))
        try context.save()
        let actor = DataActor(modelContainer: controller.container)
        try await actor.enableForeignCurrencyProtocolFixtures()
        try await actor.recoverCloudSyncFromLocalAuthority(at: date)
        #expect(try await actor.pendingCloudSyncRecordNames().count == 2)
        let beforeDeletion = try await fxRemoteRecords(actor)
        // This flag enables the DELETE operation, not normal sync. Local recording stays usable.
        _ = try await actor.beginCloudDeletion(at: date)
        _ = try await actor.createExpense(draft(foreign: facts()), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await actor.createExpense(draft(), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 100))
        #expect(try await actor.modelCounts().expenses == 3)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 2)
        let retained = try await fxRemoteRecords(actor)
        #expect(retained.map(\.recordName) == beforeDeletion.map(\.recordName))
        #expect(retained.map(\.envelopeData) == beforeDeletion.map(\.envelopeData))
        try await actor.completeCloudDeletion(at: date)
        #expect(try await !actor.cloudSyncSnapshot().isEnabled)
        #expect(try await actor.modelCounts().expenses == 3)
        try await actor.deleteAllUserData()
        #expect(try await actor.modelCounts().isEmpty)
    }

    @Test func pendingLegacyParentReplayCannotOverwriteFXButTombstoneCascades() async throws {
        for tombstone in [false, true] {
            let controller = try DataController(isStoredInMemoryOnly: true)
            let id = UUID()
            let value = try facts()
            _ = try await controller.dataActor.createExpense(draft(id: id, foreign: value), featureAccess: FeatureAccessService(entitlements: .proSubscription))
            let envelope: CloudSyncEnvelope
            if tombstone {
                envelope = try CloudSyncCodec.makeEnvelope(payload: nil, entityType: .expense,
                    identity: id.uuidString.lowercased(), operation: .tombstone, revision: 1,
                    parentSemanticDigest: nil, modifiedAt: date)
            } else {
                let source = try DataController(isStoredInMemoryOnly: true).dataActor
                _ = try await source.setCloudSyncEnabled(true)
                _ = try await source.createExpense(draft(id: id, amount: 900), featureAccess: FeatureAccessService(entitlements: .proSubscription))
                let name = try CloudSyncCodec.canonicalRecordName(entityType: .expense, identity: id.uuidString.lowercased())
                let pending = try #require(try await source.pendingCloudSyncRecord(named: name))
                envelope = try CloudSyncCodec.decodeEnvelope(pending.envelopeData)
            }
            // Simulate a durable inbox surviving a disable/restart, without authorizing a wire
            // format for FX. This exercises the existing remote application transaction itself.
            let context = ModelContext(controller.container)
            context.insert(CloudSyncInboxItem(id: UUID(), recordName: envelope.recordName,
                envelopeData: try CloudSyncCodec.encodeEnvelope(envelope), encodedSystemFields: nil,
                statusRaw: "pending", reasonRaw: nil, receivedAt: date, updatedAt: date))
            try context.save()
            let actor = DataActor(modelContainer: controller.container)
            try await actor.enableForeignCurrencyProtocolFixtures()
            try await actor.applyPendingCloudSyncInbox(at: date)
            if tombstone {
                #expect(try await actor.modelCounts().expenses == 0)
                #expect(try await actor.modelCounts().foreignCurrencyMetadata == 0)
            } else {
                #expect(try await actor.fetchExpenseDetail(id: id)?.foreignCurrency == value)
                #expect(try await actor.fetchExpenseDetail(id: id)?.summary.amount.minorUnits == 600)
                #expect(try await actor.cloudSyncSnapshot().quarantinedCount == 0)
                let retainedInbox = ModelContext(controller.container)
                #expect(try retainedInbox.fetch(FetchDescriptor<CloudSyncInboxItem>()).first?.reasonRaw == "missingParent")
            }
        }
    }

    @Test func unreadableTupleIsRejectedButStewardshipDeletionStillWorks() async throws {
        for corrupt in [
            { (row: ExpenseForeignCurrencyMetadata) in row.rateDenominator = 0 },
            { $0.rateNumerator = -1 }, { $0.originalAmountMinorUnits = 0 },
            { $0.originalCurrencyCode = "XXX" }, { $0.originalCurrencyCode = "USD" },
            { $0.rateSourceRaw = "automatic" }, { $0.rateTimeZoneIdentifier = "invalid/zone" },
            { $0.rateDate = $0.rateDate.addingTimeInterval(1) },
            { $0.rateNumerator = 4; $0.rateDenominator = 2 },
            { $0.rateSourceRaw = "manualHomeAmountOverride"; $0.rateNumerator = 20_001; $0.rateDenominator = 10_000 },
            { $0.originalAmountMinorUnits = Int64.max },
            { $0.rateDate = Date(timeIntervalSinceReferenceDate: .infinity) },
            { $0.rateNumerator = Int64.max }, { $0.expenseID = UUID() },
        ] {
            let controller = try DataController(isStoredInMemoryOnly: true)
            let id = UUID()
            _ = try await controller.dataActor.createExpense(draft(id: id, foreign: facts()), featureAccess: FeatureAccessService(entitlements: .proSubscription))
            let context = ModelContext(controller.container)
            let row = try #require(context.fetch(FetchDescriptor<ExpenseForeignCurrencyMetadata>()).first)
            corrupt(row)
            try context.save()
            #expect(throws: MigrationIntegrityInventory.Error.invalidForeignCurrencyMetadata) {
                try MigrationIntegrityInventory.validateAndRepair(in: controller.container)
            }
            let freshActor = DataActor(modelContainer: controller.container)
            if row.expenseID == id {
                await #expect(throws: (any Error).self) { try await freshActor.fetchExpenseDetail(id: id) }
                try await freshActor.deleteExpense(id: id)
            } else {
                try await freshActor.deleteAllUserData()
            }
            #expect(try await freshActor.modelCounts().foreignCurrencyMetadata == 0)
        }
    }
}
