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

    @Test func foreignSyncStagesSeparateFactsAndDisabledWritesStayLocal() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).dataActor
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
        _ = try await source.setCloudSyncEnabled(true)
        _ = try await source.createExpense(draft(foreign: facts()),
            featureAccess: FeatureAccessService(entitlements: .proSubscription))
        let records = try await fxRemoteRecords(source)
        let parent = try #require(records.first { $0.recordName.hasPrefix("expense/") })
        let child = try #require(records.first { !$0.recordName.hasPrefix("expense/") })
        for data in [Data("not-json".utf8), Data()] {
            let receiver = try DataController(isStoredInMemoryOnly: true).dataActor
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
        _ = try await receiver.setCloudSyncEnabled(true)
        try await receiver.ingestCloudSyncRecords([parent, CloudSyncRemoteRecord(recordName: child.recordName,
            envelopeData: CloudSyncCodec.encodeEnvelope(bad), encodedSystemFields: Data([1]),
            wasPhysicallyDeleted: false)], receivedAt: date)
        let reopened = DataActor(modelContainer: controller.container)
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
        try await actor.recoverCloudSyncFromLocalAuthority(at: date)
        #expect(try await actor.pendingCloudSyncRecordNames().count == 2)
        // This flag enables the DELETE operation, not normal sync. Local recording stays usable.
        _ = try await actor.beginCloudDeletion(at: date)
        _ = try await actor.createExpense(draft(foreign: facts()), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await actor.createExpense(draft(), featureAccess: FeatureAccessService(entitlements: .proSubscription))
        _ = try await actor.updateExpense(id: id, with: draft(id: id, amount: 100))
        #expect(try await actor.modelCounts().expenses == 3)
        #expect(try await actor.modelCounts().foreignCurrencyMetadata == 2)
        for name in try await actor.pendingCloudSyncRecordNames() {
            let pending = try #require(try await actor.pendingCloudSyncRecord(named: name))
            #expect(try CloudSyncCodec.decodeEnvelope(pending.envelopeData).operation == .tombstone)
        }
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
