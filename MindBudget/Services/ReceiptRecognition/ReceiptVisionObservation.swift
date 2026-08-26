import CoreGraphics
import ImageIO
@preconcurrency import Vision

enum ReceiptOCRPrivacyError: Error, Equatable, Sendable {
    case invalidPolicy
    case tooManyObservations
    case observationTooLarge(sourceIndex: Int)
    case documentTooLarge
    case invalidGeometry(sourceIndex: Int)
    case invalidConfidence(sourceIndex: Int)
    case sensitiveTextRejected(sourceIndex: Int)
}

struct ReceiptOCRPolicy: Equatable, Sendable {
    let maximumObservationCount: Int
    let maximumObservationBytes: Int
    let maximumDocumentBytes: Int
    let minimumTextHeight: Float
    let readingOrderRowBand: CGFloat

    static let standard = ReceiptOCRPolicy(
        maximumObservationCount: 256,
        maximumObservationBytes: 512,
        maximumDocumentBytes: 16 * 1_024,
        minimumTextHeight: 0.012,
        readingOrderRowBand: 0.025
    )

    func validate() throws {
        guard maximumObservationCount > 0,
              maximumObservationBytes > 0,
              maximumDocumentBytes > 0,
              minimumTextHeight.isFinite,
              (0...1).contains(minimumTextHeight),
              readingOrderRowBand.isFinite,
              (0.001...1).contains(readingOrderRowBand) else {
            throw ReceiptOCRPrivacyError.invalidPolicy
        }
    }
}

/// Raw Vision text is confined to this exact non-money adapter file and the privacy pipeline.
/// Only `ReceiptOCRDocument`, whose lines carry `ReceiptModelSafeText`, may leave this boundary.
struct ReceiptVisionTextObservation: Equatable, Sendable {
    let text: String
    let bounds: ReceiptNormalizedBounds
    let confidence: Float
    let sourceIndex: Int
}

struct ReceiptOCRLine: Equatable, Sendable {
    let text: ReceiptModelSafeText
    let bounds: ReceiptNormalizedBounds
    let confidence: Float
}

struct ReceiptOCRDocument: Equatable, Sendable {
    let lines: [ReceiptOCRLine]

    var modelSafeText: String {
        lines.map(\.text.value).joined(separator: "\n")
    }
}

struct ReceiptOCRPrivacyPipeline {
    private struct Candidate {
        let line: ReceiptOCRLine
        let sourceIndex: Int
        let stableIndex: Int
    }

    let policy: ReceiptOCRPolicy
    let sensitiveTextFilter: ReceiptSensitiveTextFilter

    init(
        policy: ReceiptOCRPolicy = .standard,
        sensitiveTextFilter: ReceiptSensitiveTextFilter = ReceiptSensitiveTextFilter()
    ) {
        self.policy = policy
        self.sensitiveTextFilter = sensitiveTextFilter
    }

    func process(_ observations: [ReceiptVisionTextObservation]) throws -> ReceiptOCRDocument {
        try policy.validate()
        guard observations.count <= policy.maximumObservationCount else {
            throw ReceiptOCRPrivacyError.tooManyObservations
        }

        var documentBytes = 0
        var candidates: [Candidate] = []
        candidates.reserveCapacity(observations.count)

        for (stableIndex, observation) in observations.enumerated() {
            guard observation.bounds.isNormalized else {
                throw ReceiptOCRPrivacyError.invalidGeometry(sourceIndex: observation.sourceIndex)
            }
            guard observation.confidence.isFinite,
                  (0...1).contains(observation.confidence) else {
                throw ReceiptOCRPrivacyError.invalidConfidence(sourceIndex: observation.sourceIndex)
            }
            guard observation.text.utf8.count <= policy.maximumObservationBytes else {
                throw ReceiptOCRPrivacyError.observationTooLarge(sourceIndex: observation.sourceIndex)
            }

            let filtered: ReceiptModelSafeText?
            do {
                filtered = try sensitiveTextFilter.filter(observation.text)
            } catch {
                throw ReceiptOCRPrivacyError.sensitiveTextRejected(sourceIndex: observation.sourceIndex)
            }
            guard let filtered else { continue }
            guard filtered.value.utf8.count <= policy.maximumObservationBytes else {
                throw ReceiptOCRPrivacyError.observationTooLarge(sourceIndex: observation.sourceIndex)
            }

            let separatorBytes = candidates.isEmpty ? 0 : 1
            let (withSeparator, separatorOverflow) = documentBytes.addingReportingOverflow(separatorBytes)
            let (nextDocumentBytes, contentOverflow) = withSeparator.addingReportingOverflow(
                filtered.value.utf8.count
            )
            guard !separatorOverflow,
                  !contentOverflow,
                  nextDocumentBytes <= policy.maximumDocumentBytes else {
                throw ReceiptOCRPrivacyError.documentTooLarge
            }
            documentBytes = nextDocumentBytes
            candidates.append(
                Candidate(
                    line: ReceiptOCRLine(
                        text: filtered,
                        bounds: observation.bounds,
                        confidence: observation.confidence
                    ),
                    sourceIndex: observation.sourceIndex,
                    stableIndex: stableIndex
                )
            )
        }

        candidates.sort { lhs, rhs in
            let lhsRow = readingRow(for: lhs.line.bounds)
            let rhsRow = readingRow(for: rhs.line.bounds)
            if lhsRow != rhsRow { return lhsRow > rhsRow }
            if lhs.line.bounds.minX != rhs.line.bounds.minX {
                return lhs.line.bounds.minX < rhs.line.bounds.minX
            }
            if lhs.sourceIndex != rhs.sourceIndex { return lhs.sourceIndex < rhs.sourceIndex }
            return lhs.stableIndex < rhs.stableIndex
        }
        return ReceiptOCRDocument(lines: candidates.map(\.line))
    }

    private func readingRow(for bounds: ReceiptNormalizedBounds) -> Int {
        Int((bounds.midY / policy.readingOrderRowBand).rounded(.toNearestOrAwayFromZero))
    }
}

/// The only Vision observation boundary for the C4C receipt pipeline.
enum ReceiptVisionObservation {
    static func rectangle(
        in image: CGImage,
        policy: ReceiptRectangleDetectionPolicy = .standard
    ) throws -> ReceiptQuadrilateral? {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = policy.minimumConfidence
        request.minimumAspectRatio = policy.minimumAspectRatio
        request.maximumAspectRatio = policy.maximumAspectRatio
        request.quadratureTolerance = policy.quadratureTolerance

        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
        try handler.perform([request])
        guard let observation = request.results?.first else { return nil }

        return ReceiptQuadrilateral(
            topLeft: normalized(observation.topLeft),
            topRight: normalized(observation.topRight),
            bottomRight: normalized(observation.bottomRight),
            bottomLeft: normalized(observation.bottomLeft)
        )
    }

    static func recognizedDocument(
        in image: CGImage,
        policy: ReceiptOCRPolicy = .standard,
        sensitiveTextFilter: ReceiptSensitiveTextFilter = ReceiptSensitiveTextFilter()
    ) throws -> ReceiptOCRDocument {
        // Validate before any policy value is handed to Vision. The pipeline validates again so
        // direct deterministic callers cannot bypass the same fail-closed contract.
        try policy.validate()
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        request.minimumTextHeight = policy.minimumTextHeight

        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
        try handler.perform([request])

        let results = request.results ?? []
        guard results.count <= policy.maximumObservationCount else {
            throw ReceiptOCRPrivacyError.tooManyObservations
        }
        let observations = results.enumerated().compactMap {
            sourceIndex, observation -> ReceiptVisionTextObservation? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return ReceiptVisionTextObservation(
                text: candidate.string,
                bounds: ReceiptNormalizedBounds(rect: observation.boundingBox),
                confidence: candidate.confidence,
                sourceIndex: sourceIndex
            )
        }
        return try ReceiptOCRPrivacyPipeline(
            policy: policy,
            sensitiveTextFilter: sensitiveTextFilter
        ).process(observations)
    }

    private static func normalized(_ point: CGPoint) -> ReceiptNormalizedPoint {
        ReceiptNormalizedPoint(x: point.x, y: point.y)
    }
}

/// Executes the complete image-to-fields handoff away from the main actor. The prepared file is
/// read locally, raw Vision text remains inside this adapter, and only privacy-filtered structured
/// fields return to the customer surface.
protocol ReceiptLocalProcessing: Sendable {
    func process(
        artifact: ReceiptTemporaryImageArtifact,
        baseline: LocalReceiptRecognitionBaseline,
        context: ReceiptExtractionContext
    ) async throws -> ReceiptStructuredExtractionResult
}

struct ReceiptLocalProcessingService: ReceiptLocalProcessing, Sendable {
    func process(
        artifact: ReceiptTemporaryImageArtifact,
        baseline: LocalReceiptRecognitionBaseline,
        context: ReceiptExtractionContext
    ) async throws -> ReceiptStructuredExtractionResult {
        let document = try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            guard let source = CGImageSourceCreateWithURL(artifact.fileURL as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw ReceiptImageLifecycleError.unsupportedImage
            }
            let document = try ReceiptVisionObservation.recognizedDocument(in: image)
            try Task.checkCancellation()
            return document
        }.value
        try Task.checkCancellation()
        return try await ReceiptStructuredExtractionService(baseline: baseline).extract(
            from: document,
            context: context
        )
    }
}
