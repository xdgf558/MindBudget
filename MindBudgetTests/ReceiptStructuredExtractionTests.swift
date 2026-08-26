import CoreGraphics
import Foundation
import Testing
@testable import MindBudget

struct ReceiptStructuredExtractionTests {
    @Test
    func deterministicFallbackExtractsCoreFieldsExactly() async throws {
        let result = try await service().extract(
            from: document([
                "Blue Bottle Coffee",
                "2026-08-26 14:42",
                "Subtotal USD 10.00",
                "Tax USD 2.34",
                "TOTAL USD 12.34",
            ]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(result.fields.merchantName == .accepted("Blue Bottle Coffee", source: .deterministic))
        #expect(
            result.fields.purchaseDate
                == .accepted(
                    ReceiptCalendarDate(year: 2026, month: 8, day: 26),
                    source: .deterministic
                )
        )
        #expect(
            result.fields.total
                == .accepted(Money(minorUnits: 1_234, currencyCode: "USD"), source: .deterministic)
        )
        #expect(result.lineItems.isEmpty)
        #expect(result.duplicateResolution == .noMatch)
        #expect(result.execution == .deterministic)
    }

    @Test
    func parserUsesExplicitLocalePunctuationWithoutBinaryMoney() async throws {
        let result = try await service().extract(
            from: document([
                "Marché Local",
                "26/08/2026",
                "TOTAL EUR 1.234,56",
            ]),
            context: context(currency: "EUR", locale: "de_DE", order: .dayMonthYear)
        )

        #expect(
            result.fields.total
                == .accepted(
                    Money(minorUnits: 123_456, currencyCode: "EUR"),
                    source: .deterministic
                )
        )
    }

    @Test
    func currencyExponentMatrixAcceptsJpyAndKwd() async throws {
        let jpy = try await service().extract(
            from: document(["Tokyo Store", "2026-08-26", "TOTAL JPY 1,234"]),
            context: context(currency: "JPY", locale: "en_US", order: .monthDayYear)
        )
        let kwd = try await service().extract(
            from: document(["Kuwait Store", "2026-08-26", "TOTAL KWD 1.234"]),
            context: context(currency: "KWD", locale: "en_US", order: .monthDayYear)
        )

        #expect(
            jpy.fields.total
                == .accepted(Money(minorUnits: 1_234, currencyCode: "JPY"), source: .deterministic)
        )
        #expect(
            kwd.fields.total
                == .accepted(Money(minorUnits: 1_234, currencyCode: "KWD"), source: .deterministic)
        )
    }

    @Test
    func amountScaleCurrencyAndRangeFailuresStayExplicit() async throws {
        let scale = try await service().extract(
            from: document(["Store", "2026-08-26", "TOTAL USD 12.345"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )
        let mismatch = try await service().extract(
            from: document(["Store", "2026-08-26", "TOTAL EUR 12.34"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )
        let unsupported = try await service().extract(
            from: document(["Store", "2026-08-26", "TOTAL XYZ 12.34"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )
        let range = try await service().extract(
            from: document(["Store", "2026-08-26", "TOTAL USD 99999999999.99"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )
        let mixedValidity = try await service().extract(
            from: document([
                "Store", "2026-08-26", "TOTAL USD 12.34", "AMOUNT DUE USD 12.345",
            ]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(scale.fields.total == .rejected(.unsupportedScale))
        #expect(mismatch.fields.total == .rejected(.currencyMismatch))
        #expect(unsupported.fields.total == .rejected(.unsupportedCurrency))
        #expect(range.fields.total == .rejected(.amountOutOfRange))
        #expect(mixedValidity.fields.total == .rejected(.unsupportedScale))
    }

    @Test
    func missingAndAmbiguousFieldsNeverInventZero() async throws {
        let missing = try await service().extract(
            from: document(["Corner Shop", "Thank you"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )
        let ambiguous = try await service().extract(
            from: document([
                "Corner Shop",
                "08/09/2026",
                "09/10/2026",
                "TOTAL USD 5.00",
                "AMOUNT DUE USD 6.00",
            ]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(missing.fields.purchaseDate == .missing)
        #expect(missing.fields.total == .missing)
        #expect(missing.fields.total.acceptedValue == nil)
        #expect(ambiguous.fields.purchaseDate == .rejected(.ambiguousDate))
        #expect(ambiguous.fields.total == .rejected(.ambiguousTotal))
    }

    @Test
    func invalidCalendarDateFailsClosed() async throws {
        let result = try await service().extract(
            from: document([
                "Calendar Shop", "2026-08-26", "2026-02-30", "TOTAL USD 5.00",
            ]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(result.fields.purchaseDate == .rejected(.invalidDate))
    }

    @Test
    func duplicateRequiresExactMerchantDateAmountAndCurrency() async throws {
        let exactID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let references = [
            ReceiptDuplicateReference(
                id: exactID,
                merchantName: "BLUE-BOTTLE coffee",
                purchaseDate: ReceiptCalendarDate(year: 2026, month: 8, day: 26),
                total: Money(minorUnits: 1_234, currencyCode: "USD")
            ),
            ReceiptDuplicateReference(
                id: otherID,
                merchantName: "Blue Bottle Coffee",
                purchaseDate: ReceiptCalendarDate(year: 2026, month: 8, day: 25),
                total: Money(minorUnits: 1_234, currencyCode: "USD")
            ),
        ]
        let result = try await service().extract(
            from: document(["Blue Bottle Coffee", "2026-08-26", "TOTAL USD 12.34"]),
            context: context(
                currency: "USD",
                locale: "en_US",
                order: .monthDayYear,
                duplicates: references
            )
        )

        #expect(result.duplicateResolution == .exactMatches([exactID]))
    }

    @Test
    func duplicateIsNotEvaluableWhenAnyCoreFieldIsMissing() async throws {
        let result = try await service().extract(
            from: document(["Blue Bottle Coffee", "TOTAL USD 12.34"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(result.duplicateResolution == .notEvaluable)
    }

    @Test
    func modelMayFillMissingFieldButCannotOverrideDeterministicAuthority() async throws {
        let model = FixedReceiptModel(
            candidates: ReceiptRawCandidates(
                merchantEvidence: ["Wrong Merchant"],
                dateEvidence: ["2026-08-26"],
                totalEvidence: ["12.34"],
                lineItemEvidence: []
            )
        )
        let source = try document([
            "Blue Bottle Coffee",
            "Wrong Merchant",
            "2026-08-26",
            "Payment 12.34",
        ])
        let result = try await service(baseline: .deterministicWithOnDeviceModel, model: model)
            .extract(
                from: source,
                context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
            )

        #expect(result.fields.merchantName == .accepted("Blue Bottle Coffee", source: .deterministic))
        #expect(
            result.fields.total
                == .accepted(Money(minorUnits: 1_234, currencyCode: "USD"), source: .onDeviceModel)
        )
        #expect(result.execution == .deterministicWithOnDeviceModel)
    }

    @Test
    func modelFillsAFieldOnlyFromVerifiedDocumentEvidence() async throws {
        let model = FixedReceiptModel(
            candidates: ReceiptRawCandidates(
                merchantEvidence: [],
                dateEvidence: [],
                totalEvidence: ["12.34"],
                lineItemEvidence: []
            )
        )
        let result = try await service(baseline: .deterministicWithOnDeviceModel, model: model)
            .extract(
                from: document(["Blue Bottle Coffee", "Date 2026-08-26", "Payment 12.34"]),
                context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
            )

        #expect(
            result.fields.total
                == .accepted(
                    Money(minorUnits: 1_234, currencyCode: "USD"),
                    source: .onDeviceModel
                )
        )
        #expect(result.execution == .deterministicWithOnDeviceModel)
    }

    @Test
    func inventedModelEvidenceFallsBackWithoutInterpretation() async throws {
        let model = FixedReceiptModel(
            candidates: ReceiptRawCandidates(
                merchantEvidence: [],
                dateEvidence: [],
                totalEvidence: ["TOTAL USD 0.01"],
                lineItemEvidence: []
            )
        )
        let result = try await service(baseline: .deterministicWithOnDeviceModel, model: model)
            .extract(
                from: document(["Blue Bottle Coffee", "2026-08-26"]),
                context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
            )

        #expect(result.fields.total == .missing)
        #expect(result.execution == .deterministicFallback(.invalidEvidence))

        let differentlyCased = try await service(
            baseline: .deterministicWithOnDeviceModel,
            model: FixedReceiptModel(
                candidates: ReceiptRawCandidates(
                    merchantEvidence: [],
                    dateEvidence: [],
                    totalEvidence: ["Payment USD 12.34"],
                    lineItemEvidence: []
                )
            )
        ).extract(
            from: document(["Blue Bottle Coffee", "2026-08-26", "Payment usd 12.34"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(differentlyCased.fields.total == .missing)
        #expect(differentlyCased.execution == .deterministicFallback(.invalidEvidence))
    }

    @Test
    func modelFailureKeepsDeterministicResult() async throws {
        let result = try await service(
            baseline: .deterministicWithOnDeviceModel,
            model: ThrowingReceiptModel()
        ).extract(
            from: document(["Blue Bottle Coffee", "2026-08-26", "Payment 12.34"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(result.fields.total == .missing)
        #expect(result.execution == .deterministicFallback(.modelError))
    }

    @Test
    func completeDeterministicResultDoesNotInvokeTheOptionalModel() async throws {
        let result = try await service(
            baseline: .deterministicWithOnDeviceModel,
            model: ThrowingReceiptModel()
        ).extract(
            from: document(["Blue Bottle Coffee", "2026-08-26", "TOTAL USD 12.34"]),
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(result.execution == .deterministic)
    }

    @Test
    func unavailableAndTimedOutModelsKeepDeterministicResult() async throws {
        let source = try document(["Blue Bottle Coffee", "2026-08-26", "Payment 12.34"])
        let extractionContext = context(
            currency: "USD",
            locale: "en_US",
            order: .monthDayYear
        )
        let unavailable = try await service(
            baseline: .deterministicWithOnDeviceModel
        ).extract(from: source, context: extractionContext)
        let timedOut = try await service(
            baseline: .deterministicWithOnDeviceModel,
            model: HangingReceiptModel(),
            timeoutNanoseconds: 1_000_000
        ).extract(from: source, context: extractionContext)

        #expect(unavailable.execution == .deterministicFallback(.unavailable))
        #expect(timedOut.execution == .deterministicFallback(.timedOut))
        #expect(timedOut.fields.total == .missing)
    }

    @Test
    func lineItemExperimentDefaultsOffAndCanBeInjectedForTests() async throws {
        let candidates = ReceiptRawCandidates(
            merchantEvidence: [],
            dateEvidence: [],
            totalEvidence: [],
            lineItemEvidence: [
                ReceiptRawLineItemCandidate(nameEvidence: "Coffee", amountEvidence: "USD 4.50"),
            ]
        )
        let model = FixedReceiptModel(candidates: candidates)
        let source = try document(["Coffee", "USD 4.50"])
        let disabled = try await service(
            baseline: .deterministicWithOnDeviceModel,
            model: model
        ).extract(
            from: source,
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )
        let enabled = try await service(
            baseline: .deterministicWithOnDeviceModel,
            model: model,
            lineItems: ReceiptLineItemExperiment(isEnabled: true)
        ).extract(
            from: source,
            context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
        )

        #expect(ReceiptLineItemExperiment.production.isEnabled == false)
        #expect(disabled.lineItems.isEmpty)
        #expect(
            enabled.lineItems
                == [ReceiptLineItem(
                    name: "Coffee",
                    amount: Money(minorUnits: 450, currencyCode: "USD")
                )]
        )
        #expect(enabled.execution == .deterministicWithOnDeviceModel)
    }

    @Test
    func unavailableBaselineAndInvalidContextFailBeforeModelUse() async throws {
        await #expect(throws: ReceiptStructuredExtractionError.unavailable) {
            _ = try await service(baseline: .unavailable).extract(
                from: document(["Store"]),
                context: context(currency: "USD", locale: "en_US", order: .monthDayYear)
            )
        }
        await #expect(throws: ReceiptStructuredExtractionError.invalidContext) {
            _ = try await service().extract(
                from: document(["Store"]),
                context: context(currency: "XYZ", locale: "en_US", order: .monthDayYear)
            )
        }
    }

    private func service(
        baseline: LocalReceiptRecognitionBaseline = .deterministic,
        model: any ReceiptLocalModelExtracting = UnavailableReceiptLocalModelExtractor(),
        lineItems: ReceiptLineItemExperiment = .production,
        timeoutNanoseconds: UInt64 = 1_000_000_000
    ) -> ReceiptStructuredExtractionService {
        ReceiptStructuredExtractionService(
            baseline: baseline,
            localModel: model,
            lineItemExperiment: lineItems,
            modelTimeoutNanoseconds: timeoutNanoseconds
        )
    }

    private func context(
        currency: String,
        locale: String,
        order: ReceiptDateOrder,
        duplicates: [ReceiptDuplicateReference] = []
    ) -> ReceiptExtractionContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return ReceiptExtractionContext(
            expectedCurrencyCode: currency,
            dateOrder: order,
            calendar: calendar,
            localeIdentifier: locale,
            duplicateReferences: duplicates
        )
    }

    private func document(_ values: [String]) throws -> ReceiptOCRDocument {
        let observations = values.enumerated().map { index, value in
            ReceiptVisionTextObservation(
                text: value,
                bounds: ReceiptNormalizedBounds(
                    minX: 0.05,
                    minY: 0.90 - CGFloat(index) * 0.06,
                    width: 0.80,
                    height: 0.04
                ),
                confidence: 0.95,
                sourceIndex: index
            )
        }
        return try ReceiptOCRPrivacyPipeline().process(observations)
    }
}

private struct FixedReceiptModel: ReceiptLocalModelExtracting, Sendable {
    let candidates: ReceiptRawCandidates

    func extract(
        from document: ReceiptOCRDocument,
        context: ReceiptExtractionContext,
        lineItemsEnabled: Bool
    ) async throws -> ReceiptRawCandidates {
        candidates
    }
}

private struct ThrowingReceiptModel: ReceiptLocalModelExtracting, Sendable {
    func extract(
        from document: ReceiptOCRDocument,
        context: ReceiptExtractionContext,
        lineItemsEnabled: Bool
    ) async throws -> ReceiptRawCandidates {
        struct Failure: Error {}
        throw Failure()
    }
}

private struct HangingReceiptModel: ReceiptLocalModelExtracting, Sendable {
    func extract(
        from document: ReceiptOCRDocument,
        context: ReceiptExtractionContext,
        lineItemsEnabled: Bool
    ) async throws -> ReceiptRawCandidates {
        try await Task.sleep(nanoseconds: 60_000_000_000)
        return .empty
    }
}
