import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins

/// Normalized Vision-space point. Floating point is limited to this non-money boundary.
struct ReceiptNormalizedPoint: Equatable, Sendable {
    let x: CGFloat
    let y: CGFloat

    var isInsideUnitSquare: Bool {
        (0...1).contains(x) && (0...1).contains(y)
    }
}

/// A closed quadrilateral reported by the rectangle detector.
struct ReceiptQuadrilateral: Equatable, Sendable {
    let topLeft: ReceiptNormalizedPoint
    let topRight: ReceiptNormalizedPoint
    let bottomRight: ReceiptNormalizedPoint
    let bottomLeft: ReceiptNormalizedPoint

    var isNormalized: Bool {
        [topLeft, topRight, bottomRight, bottomLeft].allSatisfy(\.isInsideUnitSquare)
    }
}

/// Normalized Vision-space bounds retained with a privacy-filtered OCR line.
struct ReceiptNormalizedBounds: Equatable, Sendable {
    let minX: CGFloat
    let minY: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(rect: CGRect) {
        minX = rect.minX
        minY = rect.minY
        width = rect.width
        height = rect.height
    }

    init(minX: CGFloat, minY: CGFloat, width: CGFloat, height: CGFloat) {
        self.minX = minX
        self.minY = minY
        self.width = width
        self.height = height
    }

    var maxX: CGFloat { minX + width }
    var maxY: CGFloat { minY + height }
    var midY: CGFloat { minY + height / 2 }

    var isNormalized: Bool {
        minX >= 0
            && minY >= 0
            && width > 0
            && height > 0
            && maxX <= 1
            && maxY <= 1
    }
}

struct ReceiptRectangleDetectionPolicy: Equatable, Sendable {
    let minimumConfidence: Float
    let minimumAspectRatio: Float
    let maximumAspectRatio: Float
    let quadratureTolerance: Float

    static let standard = ReceiptRectangleDetectionPolicy(
        minimumConfidence: 0.72,
        minimumAspectRatio: 0.20,
        maximumAspectRatio: 1.00,
        quadratureTolerance: 20
    )
}

enum ReceiptPerspectiveCorrection {
    static func correctedImage(
        _ source: CGImage,
        quadrilateral: ReceiptQuadrilateral,
        context: CIContext
    ) -> CGImage? {
        guard quadrilateral.isNormalized else { return nil }

        let input = CIImage(cgImage: source)
        let extent = input.extent
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = input
        filter.topLeft = imagePoint(quadrilateral.topLeft, in: extent)
        filter.topRight = imagePoint(quadrilateral.topRight, in: extent)
        filter.bottomRight = imagePoint(quadrilateral.bottomRight, in: extent)
        filter.bottomLeft = imagePoint(quadrilateral.bottomLeft, in: extent)

        guard let output = filter.outputImage,
              !output.extent.isEmpty,
              output.extent.isInfinite == false else {
            return nil
        }
        return context.createCGImage(output, from: output.extent.integral)
    }

    private static func imagePoint(
        _ point: ReceiptNormalizedPoint,
        in extent: CGRect
    ) -> CGPoint {
        CGPoint(
            x: extent.minX + point.x * extent.width,
            y: extent.minY + point.y * extent.height
        )
    }
}
