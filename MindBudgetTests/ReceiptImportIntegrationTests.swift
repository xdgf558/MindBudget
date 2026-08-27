import Foundation
import Testing
@testable import MindBudget

@Suite(.serialized)
struct ReceiptImportIntegrationTests {
    @Test @MainActor
    func cancellingARecognizingGenerationCannotApplyItsLateResult() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let processor = GatedReceiptLocalProcessor(result: acceptedReceiptResult())
        let lifecycle = StubReceiptImageLifecycle()
        let viewModel = ExpenseFormViewModel(
            existingExpense: nil,
            now: TestFixtures.now,
            receiptProcessor: processor
        )
        viewModel.updateAmountTextFromUser("7.00")
        viewModel.updateMerchantNameFromUser("User Value")

        viewModel.startReceiptRecognition(
            ReceiptImageInput(data: Data([1, 2, 3]), source: .camera),
            dataActor: actor,
            lifecycle: lifecycle,
            baseline: .deterministic,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar
        )
        await processor.waitUntilEntered()
        #expect(viewModel.receiptRecognitionPhase == .recognizing)
        #expect(viewModel.blocksSaveForReceiptRecognition)

        viewModel.cancelReceiptRecognition()
        await processor.release()
        await Task.yield()

        #expect(viewModel.receiptRecognitionPhase == .none)
        #expect(viewModel.amountText == "7.00")
        #expect(viewModel.merchantName == "User Value")
        #expect(!viewModel.hasImportedReceipt)
    }

    @Test @MainActor
    func manualAmountEntryUnblocksSaveWhileRecognitionContinues() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let processor = GatedReceiptLocalProcessor(result: acceptedReceiptResult())
        let lifecycle = StubReceiptImageLifecycle()
        let viewModel = ExpenseFormViewModel(
            existingExpense: nil,
            now: TestFixtures.now,
            receiptProcessor: processor
        )

        viewModel.startReceiptRecognition(
            ReceiptImageInput(data: Data([1]), source: .photoPicker),
            dataActor: actor,
            lifecycle: lifecycle,
            baseline: .deterministic,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar
        )
        await processor.waitUntilEntered()
        #expect(viewModel.blocksSaveForReceiptRecognition)

        viewModel.enterKeypad("9", decimalSeparator: ".")

        #expect(!viewModel.blocksSaveForReceiptRecognition)
        await processor.release()
        for _ in 0..<100 where viewModel.receiptRecognitionPhase == .recognizing {
            await Task.yield()
        }
        #expect(viewModel.amountText == "9")
        #expect(viewModel.merchantName == "Late Receipt")
        guard case .review = viewModel.receiptRecognitionPhase else {
            Issue.record("The completed generation should enter inline review")
            return
        }
        viewModel.cancelReceiptRecognition()
    }

    @Test @MainActor
    func lifecycleFailureBecomesAnInlineFailClosedState() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let lifecycle = FailingReceiptImageLifecycle(error: .temporarilyUnavailable)
        let viewModel = ExpenseFormViewModel(
            existingExpense: nil,
            now: TestFixtures.now,
            receiptProcessor: GatedReceiptLocalProcessor(result: acceptedReceiptResult())
        )

        viewModel.startReceiptRecognition(
            ReceiptImageInput(data: Data([1]), source: .camera),
            dataActor: actor,
            lifecycle: lifecycle,
            baseline: .deterministic,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar
        )

        for _ in 0..<100 where viewModel.receiptRecognitionPhase == .recognizing {
            await Task.yield()
        }
        #expect(
            viewModel.receiptRecognitionPhase
                == .failed(.cameraTemporarilyUnavailable)
        )
        #expect(!viewModel.hasImportedReceipt)
    }

    @Test @MainActor
    func recognizedFieldsRemainEphemeralUntilTheExistingSaveAction() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let lifecycle = StubReceiptImageLifecycle()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let duplicateID = UUID()
        let result = ReceiptStructuredExtractionResult(
            fields: ReceiptCoreFields(
                merchantName: .accepted("Local Receipt Cafe", source: .deterministic),
                purchaseDate: .accepted(
                    ReceiptCalendarDate(year: 2026, month: 8, day: 24),
                    source: .deterministic
                ),
                total: .accepted(
                    Money(minorUnits: 1_234, currencyCode: "USD"),
                    source: .deterministic
                )
            ),
            lineItems: [],
            duplicateResolution: .exactMatches([duplicateID]),
            execution: .deterministic
        )
        let processor = GatedReceiptLocalProcessor(result: result)
        let viewModel = ExpenseFormViewModel(
            existingExpense: nil,
            now: TestFixtures.now,
            receiptProcessor: processor
        )

        viewModel.startReceiptRecognition(
            ReceiptImageInput(data: Data([1]), source: .camera),
            dataActor: actor,
            lifecycle: lifecycle,
            baseline: .deterministic,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US"),
            calendar: calendar
        )
        await processor.waitUntilEntered()
        await processor.release()
        await waitForRecognitionToFinish(viewModel)

        #expect(try await actor.fetchExpenseSummaries().isEmpty)
        #expect(viewModel.amountText == "12.34")
        #expect(viewModel.merchantName == "Local Receipt Cafe")
        #expect(viewModel.importedReceiptDuplicateCount == 1)
        #expect(viewModel.hasImportedReceipt)

        let saved = await viewModel.save(
            dataActor: actor,
            currencyCode: "USD",
            bucket: .discretionary,
            locale: Locale(identifier: "en_US"),
            now: TestFixtures.now,
            timeZone: calendar.timeZone,
            cycleStartDay: 1,
            calendar: calendar
        )
        let stored = try #require(try await actor.fetchExpenseSummaries().first)
        let storedDate = calendar.dateComponents([.year, .month, .day], from: stored.spentAt)

        #expect(saved)
        #expect(stored.amount == Money(minorUnits: 1_234, currencyCode: "USD"))
        #expect(stored.merchantName == "Local Receipt Cafe")
        #expect(stored.source == .receiptImport)
        #expect(storedDate.year == 2026)
        #expect(storedDate.month == 8)
        #expect(storedDate.day == 24)
    }

    @Test @MainActor
    func rejectedOrMissingReceiptFieldsNeverOverwriteUserInput() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let lifecycle = StubReceiptImageLifecycle()
        let result = ReceiptStructuredExtractionResult(
            fields: ReceiptCoreFields(
                merchantName: .rejected(.invalidMerchant),
                purchaseDate: .missing,
                total: .rejected(.ambiguousTotal)
            ),
            lineItems: [],
            duplicateResolution: .notEvaluable,
            execution: .deterministic
        )
        let processor = GatedReceiptLocalProcessor(result: result)
        let viewModel = ExpenseFormViewModel(
            existingExpense: nil,
            now: TestFixtures.now,
            receiptProcessor: processor
        )
        viewModel.updateAmountTextFromUser("9.99")
        viewModel.updateMerchantNameFromUser("User Entry")

        viewModel.startReceiptRecognition(
            ReceiptImageInput(data: Data([1]), source: .photoPicker),
            dataActor: actor,
            lifecycle: lifecycle,
            baseline: .deterministic,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar
        )
        await processor.waitUntilEntered()
        await processor.release()
        await waitForRecognitionToFinish(viewModel)

        #expect(viewModel.amountText == "9.99")
        #expect(viewModel.merchantName == "User Entry")
        #expect(!viewModel.hasImportedReceipt)
        guard case .review = viewModel.receiptRecognitionPhase else {
            Issue.record("The production recognition path should expose rejected fields for review")
            return
        }
    }

    @Test @MainActor
    func editedFieldsStayUserOwnedEvenWhenChangedBackToTheirStartingValues() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let processor = GatedReceiptLocalProcessor(result: acceptedReceiptResult())
        let lifecycle = StubReceiptImageLifecycle()
        let originalDate = try #require(
            TestFixtures.utcCalendar.date(
                from: DateComponents(year: 2026, month: 8, day: 20, hour: 12)
            )
        )
        let changedDate = try #require(
            TestFixtures.utcCalendar.date(
                from: DateComponents(year: 2026, month: 8, day: 21, hour: 12)
            )
        )
        let viewModel = ExpenseFormViewModel(
            existingExpense: nil,
            now: originalDate,
            receiptProcessor: processor
        )
        viewModel.updateAmountTextFromUser("5")
        viewModel.updateMerchantNameFromUser("Original Merchant")

        viewModel.startReceiptRecognition(
            ReceiptImageInput(data: Data([1]), source: .camera),
            dataActor: actor,
            lifecycle: lifecycle,
            baseline: .deterministic,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar
        )
        await processor.waitUntilEntered()

        viewModel.deleteKeypadCharacter()
        viewModel.enterKeypad("9", decimalSeparator: ".")
        viewModel.deleteKeypadCharacter()
        viewModel.enterKeypad("5", decimalSeparator: ".")
        viewModel.updateMerchantNameFromUser("Changed Merchant")
        viewModel.updateMerchantNameFromUser("Original Merchant")
        viewModel.updateSpentAtFromUser(changedDate)
        viewModel.updateSpentAtFromUser(originalDate)

        #expect(!viewModel.blocksSaveForReceiptRecognition)
        await processor.release()
        await waitForRecognitionToFinish(viewModel)

        #expect(viewModel.amountText == "5")
        #expect(viewModel.merchantName == "Original Merchant")
        #expect(viewModel.spentAt == originalDate)
        #expect(!viewModel.hasImportedReceipt)

        let saved = await viewModel.save(
            dataActor: actor,
            currencyCode: "USD",
            bucket: .discretionary,
            locale: Locale(identifier: "en_US"),
            now: originalDate,
            timeZone: TestFixtures.utcCalendar.timeZone,
            cycleStartDay: 1,
            calendar: TestFixtures.utcCalendar
        )
        let stored = try #require(try await actor.fetchExpenseSummaries().first)

        #expect(saved)
        #expect(stored.source == .manual)
    }

    @Test @MainActor
    func acquisitionGateFailuresRemainTruthfulAndRecoverySpecific() {
        #expect(
            ReceiptImportViewModel.destination(for: .productDisabled)
                == .failed(.productDisabled)
        )
        #expect(
            ReceiptImportViewModel.destination(for: .requiresPro)
                == .failed(.requiresPro)
        )
        #expect(ReceiptImportFailure.requiresPro.titleKey == "receipt.error.requiresPro.title")
        #expect(ReceiptImportFailure.requiresPro.detailKey == "receipt.error.requiresPro.detail")
        #expect(!ReceiptImportFailure.requiresPro.allowsCaptureRetry)
        #expect(!ReceiptImportFailure.localDataUnavailable.allowsCaptureRetry)
        #expect(ReceiptImportFailure.unreadableImage.allowsCaptureRetry)
    }

    @Test
    func contextUsesAppLocaleAndEachStoredExpenseTimeZone() throws {
        #expect(ReceiptImportContextBuilder.dateOrder(for: Locale(identifier: "en_US")) == .monthDayYear)
        #expect(ReceiptImportContextBuilder.dateOrder(for: Locale(identifier: "en_SG")) == .dayMonthYear)

        let instant = try #require(
            TestFixtures.utcCalendar.date(
                from: DateComponents(year: 2026, month: 8, day: 26, hour: 2)
            )
        )
        let expense = ExpenseSummary(
            id: UUID(),
            amount: Money(minorUnits: 500, currencyCode: "USD"),
            category: .food,
            bucket: .discretionary,
            merchantName: "Time Zone Store",
            spentAt: instant,
            spentTimeZoneIdentifier: "America/Los_Angeles",
            createdAt: instant,
            updatedAt: instant,
            paymentMethod: nil,
            emotionTag: nil,
            purchaseReason: nil,
            isPlanned: false,
            isRecurring: false,
            source: .manual,
            allowMerchantIndexing: false
        )

        let reference = try #require(
            ReceiptImportContextBuilder.duplicateReferences(
                from: [expense],
                calendar: TestFixtures.utcCalendar
            ).first
        )
        #expect(reference.purchaseDate == ReceiptCalendarDate(year: 2026, month: 8, day: 25))
    }

    @Test
    func fixedReceiptMatrixCoversAtLeastSixtyExactReceiptsAndNonReceipts() async throws {
        let fixtures = receiptFixtures()
        #expect(fixtures.count >= 60)

        for fixture in fixtures {
            let result = try await ReceiptStructuredExtractionService(baseline: .deterministic)
                .extract(
                    from: try document(fixture.lines),
                    context: context(currencyCode: fixture.currencyCode)
                )
            #expect(
                result.fields.merchantName
                    == .accepted(fixture.merchantName, source: .deterministic),
                Comment(rawValue: fixture.name)
            )
            #expect(
                result.fields.purchaseDate
                    == .accepted(fixture.date, source: .deterministic),
                Comment(rawValue: fixture.name)
            )
            #expect(
                result.fields.total
                    == .accepted(fixture.total, source: .deterministic),
                Comment(rawValue: fixture.name)
            )
        }

        let nonReceipts = [
            ["Meeting Notes", "Follow up next week"],
            ["Shopping List", "Milk", "Bread"],
            ["Totally Fresh USD 12.34", "Tax USD 1.00"],
            ["USA 12.34", "Reference only"],
            ["THE 12.34", "Reference only"],
            ["IBM 12.34", "Reference only"],
            ["Calendar", "2026-08-26"],
            ["Subtotal USD 12.34", "Tax USD 1.00"],
            ["Draft", "Amount 12.34"],
            ["Reminder", "Call merchant tomorrow"],
        ]
        for lines in nonReceipts {
            let result = try await ReceiptStructuredExtractionService(baseline: .deterministic)
                .extract(from: try document(lines), context: context(currencyCode: "USD"))
            #expect(result.fields.total.acceptedValue == nil, Comment(rawValue: lines.joined(separator: " | ")))
        }
    }

    private struct Fixture {
        let name: String
        let merchantName: String
        let currencyCode: String
        let lines: [String]
        let date: ReceiptCalendarDate
        let total: Money
    }

    private func receiptFixtures() -> [Fixture] {
        let usd = (1...20).map { index in
            let day = (index % 28) + 1
            let merchant = "North Cafe Fixture \(index)"
            let cents = index % 100
            return Fixture(
                name: "USD-\(index)",
                merchantName: merchant,
                currencyCode: "USD",
                lines: [merchant, "2026-08-\(String(format: "%02d", day))", "TOTAL USD \(index).\(String(format: "%02d", cents))"],
                date: ReceiptCalendarDate(year: 2026, month: 8, day: day),
                total: Money(minorUnits: Int64(index * 100 + cents), currencyCode: "USD")
            )
        }
        let jpy = (1...20).map { index in
            let day = (index % 28) + 1
            let merchant = "Tokyo Market Fixture \(index)"
            return Fixture(
                name: "JPY-\(index)",
                merchantName: merchant,
                currencyCode: "JPY",
                lines: [merchant, "2026-07-\(String(format: "%02d", day))", "TOTAL JPY \(1_000 + index)"],
                date: ReceiptCalendarDate(year: 2026, month: 7, day: day),
                total: Money(minorUnits: Int64(1_000 + index), currencyCode: "JPY")
            )
        }
        let kwd = (1...20).map { index in
            let day = (index % 28) + 1
            let merchant = "Kuwait Shop Fixture \(index)"
            return Fixture(
                name: "KWD-\(index)",
                merchantName: merchant,
                currencyCode: "KWD",
                lines: [merchant, "2026-06-\(String(format: "%02d", day))", "TOTAL KWD \(index).\(String(format: "%03d", index))"],
                date: ReceiptCalendarDate(year: 2026, month: 6, day: day),
                total: Money(minorUnits: Int64(index * 1_000 + index), currencyCode: "KWD")
            )
        }
        return usd + jpy + kwd
    }

    private func context(currencyCode: String) -> ReceiptExtractionContext {
        ReceiptExtractionContext(
            expectedCurrencyCode: currencyCode,
            dateOrder: .monthDayYear,
            calendar: TestFixtures.utcCalendar,
            localeIdentifier: "en_US"
        )
    }

    private func document(_ values: [String]) throws -> ReceiptOCRDocument {
        try ReceiptOCRPrivacyPipeline().process(
            values.enumerated().map { index, value in
                ReceiptVisionTextObservation(
                    text: value,
                    bounds: ReceiptNormalizedBounds(
                        minX: 0.05,
                        minY: 0.90 - CGFloat(index) * 0.06,
                        width: 0.85,
                        height: 0.04
                    ),
                    confidence: 0.95,
                    sourceIndex: index
                )
            }
        )
    }

    private func acceptedReceiptResult() -> ReceiptStructuredExtractionResult {
        ReceiptStructuredExtractionResult(
            fields: ReceiptCoreFields(
                merchantName: .accepted("Late Receipt", source: .deterministic),
                purchaseDate: .accepted(
                    ReceiptCalendarDate(year: 2026, month: 8, day: 26),
                    source: .deterministic
                ),
                total: .accepted(
                    Money(minorUnits: 2_500, currencyCode: "USD"),
                    source: .deterministic
                )
            ),
            lineItems: [],
            duplicateResolution: .noMatch,
            execution: .deterministic
        )
    }

    @MainActor
    private func waitForRecognitionToFinish(_ viewModel: ExpenseFormViewModel) async {
        for _ in 0..<200 {
            guard viewModel.receiptRecognitionPhase == .recognizing else { return }
            await Task.yield()
        }
        Issue.record(
            "Receipt recognition did not leave the recognizing phase within the bounded wait"
        )
    }
}

private actor GatedReceiptLocalProcessor: ReceiptLocalProcessing {
    private let result: ReceiptStructuredExtractionResult
    private var entered = false
    private var entryWaiters: [CheckedContinuation<Void, Never>] = []
    private var processingContinuation: CheckedContinuation<Void, Never>?

    init(result: ReceiptStructuredExtractionResult) {
        self.result = result
    }

    func process(
        artifact: ReceiptTemporaryImageArtifact,
        baseline: LocalReceiptRecognitionBaseline,
        context: ReceiptExtractionContext
    ) async throws -> ReceiptStructuredExtractionResult {
        entered = true
        let waiters = entryWaiters
        entryWaiters.removeAll()
        waiters.forEach { $0.resume() }
        await withCheckedContinuation { continuation in
            processingContinuation = continuation
        }
        return result
    }

    func waitUntilEntered() async {
        guard !entered else { return }
        await withCheckedContinuation { continuation in
            entryWaiters.append(continuation)
        }
    }

    func release() {
        processingContinuation?.resume()
        processingContinuation = nil
    }
}

private struct StubReceiptImageLifecycle: ReceiptImageLifecycleHandling {
    func start() async {}

    func prepare(_ input: ReceiptImageInput) async throws -> ReceiptTemporaryImageArtifact {
        ReceiptTemporaryImageArtifact(
            id: UUID(),
            fileURL: URL(fileURLWithPath: "/private/tmp/receipt-ui-test.jpg"),
            pixelWidth: 10,
            pixelHeight: 20,
            source: input.source,
            correctedPerspective: false
        )
    }

    func discardTemporaryImage(matching artifactID: UUID) async {}

    func discardTemporaryImage() async {}
}

private struct FailingReceiptImageLifecycle: ReceiptImageLifecycleHandling {
    let error: ReceiptImageLifecycleError

    func start() async {}

    func prepare(_ input: ReceiptImageInput) async throws -> ReceiptTemporaryImageArtifact {
        throw error
    }

    func discardTemporaryImage(matching artifactID: UUID) async {}

    func discardTemporaryImage() async {}
}
