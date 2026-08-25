import CoreGraphics
@preconcurrency import Vision

/// The only Vision observation boundary in C4C-02.
///
/// It detects document geometry only. It does not create, consume, or expose recognized text.
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

    private static func normalized(_ point: CGPoint) -> ReceiptNormalizedPoint {
        ReceiptNormalizedPoint(x: point.x, y: point.y)
    }
}
