import CoreGraphics
import Foundation
import Testing
@testable import MindBudget

struct ReceiptOCRPrivacyTests {
    @Test
    func spacedMaskedCardLastFourIsRedactedBeforeModelSafeTextExists() throws {
        let document = try ReceiptOCRPrivacyPipeline().process([
            observation("CARD * * * * 9876", sourceIndex: 0),
            observation("TOTAL USD 12.34", sourceIndex: 1),
        ])

        #expect(document.lines.first?.text.value == "CARD \(ReceiptSensitiveTextFilter.replacementToken)")
        #expect(document.lines.map(\.text.value).joined(separator: " ").contains("9876") == false)
    }

    @Test
    func filterRemovesCardValuesLastFourAndAuthorizationCodes() throws {
        let filter = ReceiptSensitiveTextFilter()
        let cases: [(String, String, Set<ReceiptSensitiveTextKind>)] = [
            (
                "Visa 4111 1111 1111 1111",
                "Visa [redacted]",
                [.paymentCardNumber]
            ),
            (
                "Card No. 4111 1111 1111 1111",
                "Card No. [redacted]",
                [.paymentCardNumber]
            ),
            (
                "卡号：４１１１-１１１１-１１１１-１１１１",
                "卡号：[redacted]",
                [.paymentCardNumber]
            ),
            (
                "Card ending in 4242",
                "Card [redacted]",
                [.paymentCardLastFour]
            ),
            (
                "末四位：１２３４",
                "[redacted]",
                [.paymentCardLastFour]
            ),
            (
                "•••• 9876",
                "[redacted]",
                [.paymentCardLastFour]
            ),
            (
                "XXXX-9876",
                "[redacted]",
                [.paymentCardLastFour]
            ),
            (
                "Card No. 2468",
                "[redacted]",
                [.paymentCardLastFour]
            ),
            (
                "後四位：１２３４",
                "[redacted]",
                [.paymentCardLastFour]
            ),
            (
                "Authorization code: A1B2C3",
                "[redacted]",
                [.authorizationCode]
            ),
            (
                "授權碼：ZX-9012",
                "[redacted]",
                [.authorizationCode]
            ),
        ]

        for (source, expected, expectedKinds) in cases {
            let result = try filter.filter(source)
            let filtered = try #require(result)
            #expect(filtered.value == expected)
            #expect(filtered.redactedKinds == expectedKinds)
        }
    }

    @Test
    func filterPreservesOrdinaryReceiptTextAndNormalizesControls() throws {
        let filter = ReceiptSensitiveTextFilter()
        let ordinaryResult = try filter.filter("Coffee Shop Order 123456")
        let normalizedResult = try filter.filter("Coffee\u{0000}\tShop\nOrder 42")
        let ordinary = try #require(ordinaryResult)
        let normalized = try #require(normalizedResult)

        #expect(ordinary.value == "Coffee Shop Order 123456")
        #expect(ordinary.redactedKinds.isEmpty)
        #expect(normalized.value == "Coffee Shop Order 42")
        #expect(normalized.redactedKinds.isEmpty)
    }

    @Test
    func pipelineReturnsOnlyFilteredLinesInDeterministicReadingOrder() throws {
        let observations = [
            observation(
                "Authorization code: A1B2C3",
                minX: 0.62,
                minY: 0.84,
                width: 0.28,
                height: 0.08,
                confidence: 0.81,
                sourceIndex: 7
            ),
            observation(
                "Bottom line",
                minX: 0.12,
                minY: 0.22,
                width: 0.50,
                height: 0.08,
                confidence: 0.71,
                sourceIndex: 2
            ),
            observation(
                "Visa 4111 1111 1111 1111",
                minX: 0.08,
                minY: 0.85,
                width: 0.46,
                height: 0.08,
                confidence: 0.91,
                sourceIndex: 9
            ),
        ]

        let document = try ReceiptOCRPrivacyPipeline().process(observations)

        #expect(document.lines.map(\.text.value) == ["Visa [redacted]", "[redacted]", "Bottom line"])
        #expect(document.lines.map(\.confidence) == [0.91, 0.81, 0.71])
        #expect(document.lines[0].bounds.minX == 0.08)
        #expect(document.modelSafeText == "Visa [redacted]\n[redacted]\nBottom line")
        #expect(!document.modelSafeText.contains("4111"))
        #expect(!document.modelSafeText.contains("A1B2C3"))
    }

    @Test
    func pipelineUsesSourceIndexAndInputPositionAsStableTieBreakers() throws {
        let sameBounds = ReceiptNormalizedBounds(minX: 0.1, minY: 0.5, width: 0.4, height: 0.1)
        let observations = [
            ReceiptVisionTextObservation(
                text: "Third",
                bounds: sameBounds,
                confidence: 1,
                sourceIndex: 4
            ),
            ReceiptVisionTextObservation(
                text: "First",
                bounds: sameBounds,
                confidence: 1,
                sourceIndex: 2
            ),
            ReceiptVisionTextObservation(
                text: "Second",
                bounds: sameBounds,
                confidence: 1,
                sourceIndex: 2
            ),
        ]

        let document = try ReceiptOCRPrivacyPipeline().process(observations)

        #expect(document.lines.map(\.text.value) == ["First", "Second", "Third"])
    }

    @Test
    func pipelineFailsClosedForCountLineAndDocumentCaps() throws {
        let countPolicy = policy(
            maximumObservationCount: 1,
            maximumObservationBytes: 64,
            maximumDocumentBytes: 64
        )
        expectPrivacyError(.tooManyObservations) {
            _ = try ReceiptOCRPrivacyPipeline(policy: countPolicy).process([
                observation("One", sourceIndex: 0),
                observation("Two", sourceIndex: 1),
            ])
        }

        let linePolicy = policy(
            maximumObservationCount: 2,
            maximumObservationBytes: 3,
            maximumDocumentBytes: 64
        )
        expectPrivacyError(.observationTooLarge(sourceIndex: 8)) {
            _ = try ReceiptOCRPrivacyPipeline(policy: linePolicy).process([
                observation("Four", sourceIndex: 8),
            ])
        }

        let documentPolicy = policy(
            maximumObservationCount: 2,
            maximumObservationBytes: 8,
            maximumDocumentBytes: 7
        )
        expectPrivacyError(.documentTooLarge) {
            _ = try ReceiptOCRPrivacyPipeline(policy: documentPolicy).process([
                observation("Four", sourceIndex: 0),
                observation("Five", sourceIndex: 1),
            ])
        }
    }

    @Test
    func pipelineRejectsAnUnsafeReadingOrderPolicy() throws {
        let invalidPolicy = ReceiptOCRPolicy(
            maximumObservationCount: 1,
            maximumObservationBytes: 64,
            maximumDocumentBytes: 64,
            minimumTextHeight: 0.012,
            readingOrderRowBand: .leastNonzeroMagnitude
        )

        expectPrivacyError(.invalidPolicy) {
            _ = try ReceiptOCRPrivacyPipeline(policy: invalidPolicy).process([
                observation("Line", sourceIndex: 0),
            ])
        }

        let invalidVisionPolicy = ReceiptOCRPolicy(
            maximumObservationCount: 1,
            maximumObservationBytes: 64,
            maximumDocumentBytes: 64,
            minimumTextHeight: .nan,
            readingOrderRowBand: 0.025
        )
        expectPrivacyError(.invalidPolicy) {
            try invalidVisionPolicy.validate()
        }
    }

    @Test
    func pipelineFailsClosedForInvalidGeometryAndConfidence() throws {
        expectPrivacyError(.invalidGeometry(sourceIndex: 5)) {
            _ = try ReceiptOCRPrivacyPipeline().process([
                observation("Outside", minX: -0.1, sourceIndex: 5),
            ])
        }
        expectPrivacyError(.invalidConfidence(sourceIndex: 6)) {
            _ = try ReceiptOCRPrivacyPipeline().process([
                observation("Uncertain", confidence: .nan, sourceIndex: 6),
            ])
        }
        expectPrivacyError(.invalidConfidence(sourceIndex: 7)) {
            _ = try ReceiptOCRPrivacyPipeline().process([
                observation("Impossible", confidence: 1.01, sourceIndex: 7),
            ])
        }
    }

    @Test
    func pipelineClampsOnlyMinorVisionGeometryDrift() throws {
        let document = try ReceiptOCRPrivacyPipeline().process([
            observation(
                "Top edge",
                minX: -0.001,
                minY: 0.95,
                width: 0.4,
                height: 0.052,
                sourceIndex: 3
            ),
        ])
        let bounds = try #require(document.lines.first?.bounds)

        #expect(bounds.minX == 0)
        #expect(bounds.maxY == 1)
        #expect(bounds.isNormalized)

        expectPrivacyError(.invalidGeometry(sourceIndex: 4)) {
            _ = try ReceiptOCRPrivacyPipeline().process([
                observation("Too far outside", minX: -0.006, sourceIndex: 4),
            ])
        }
    }

    private func observation(
        _ text: String,
        minX: CGFloat = 0.1,
        minY: CGFloat = 0.5,
        width: CGFloat = 0.4,
        height: CGFloat = 0.1,
        confidence: Float = 0.9,
        sourceIndex: Int
    ) -> ReceiptVisionTextObservation {
        ReceiptVisionTextObservation(
            text: text,
            bounds: ReceiptNormalizedBounds(
                minX: minX,
                minY: minY,
                width: width,
                height: height
            ),
            confidence: confidence,
            sourceIndex: sourceIndex
        )
    }

    private func policy(
        maximumObservationCount: Int,
        maximumObservationBytes: Int,
        maximumDocumentBytes: Int
    ) -> ReceiptOCRPolicy {
        ReceiptOCRPolicy(
            maximumObservationCount: maximumObservationCount,
            maximumObservationBytes: maximumObservationBytes,
            maximumDocumentBytes: maximumDocumentBytes,
            minimumTextHeight: 0.012,
            readingOrderRowBand: 0.025
        )
    }

    private func expectPrivacyError(
        _ expected: ReceiptOCRPrivacyError,
        operation: () throws -> Void
    ) {
        do {
            try operation()
            Issue.record("Expected privacy error \(expected)")
        } catch let error as ReceiptOCRPrivacyError {
            #expect(error == expected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
