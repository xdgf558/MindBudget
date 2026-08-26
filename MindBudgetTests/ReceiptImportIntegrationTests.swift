import Foundation
import Testing
@testable import MindBudget

@Suite(.serialized)
struct ReceiptImportIntegrationTests {
    @Test @MainActor
    func recognizedFieldsRemainEphemeralUntilTheExistingSaveAction() async throws {
        let actor = try DataController(isStoredInMemoryOnly: true).makeDataActor()
        let viewModel = ExpenseFormViewModel(existingExpense: nil, now: TestFixtures.now)
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

        viewModel.applyReceiptImport(
            result,
            locale: Locale(identifier: "en_US"),
            calendar: calendar
        )

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
    func rejectedOrMissingReceiptFieldsNeverOverwriteUserInput() {
        let viewModel = ExpenseFormViewModel(existingExpense: nil, now: TestFixtures.now)
        viewModel.amountText = "9.99"
        viewModel.merchantName = "User Entry"
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

        viewModel.applyReceiptImport(
            result,
            locale: Locale(identifier: "en_US"),
            calendar: TestFixtures.utcCalendar
        )

        #expect(viewModel.amountText == "9.99")
        #expect(viewModel.merchantName == "User Entry")
        #expect(!viewModel.hasImportedReceipt)
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
}
