import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ReceiptImageSource: Equatable, Sendable {
    case camera
    case photoPicker
}

enum ReceiptImageLifecycleError: Error, Equatable, Sendable {
    case emptyInput
    case sourceTooLarge
    case unsupportedImage
    case invalidPixelDimensions
    case preparedImageTooLarge
    case encodingFailed
    case temporaryStorageFailed
    case temporarilyUnavailable
    case superseded
}

struct ReceiptImageLifecyclePolicy: Equatable, Sendable {
    let maximumSourceBytes: Int
    let maximumSourcePixels: Int
    let maximumPreparedEdge: Int
    let maximumPreparedPixels: Int
    let maximumPreparedBytes: Int

    static let standard = ReceiptImageLifecyclePolicy(
        maximumSourceBytes: 48 * 1_024 * 1_024,
        maximumSourcePixels: 64_000_000,
        maximumPreparedEdge: 4_096,
        maximumPreparedPixels: 12_000_000,
        maximumPreparedBytes: 8 * 1_024 * 1_024
    )
}

struct ReceiptImageInput: Equatable, Sendable {
    let data: Data
    let source: ReceiptImageSource
}

struct ReceiptPreparedImageBytes: Equatable, Sendable {
    let data: Data
    let pixelWidth: Int
    let pixelHeight: Int
    let source: ReceiptImageSource
    let correctedPerspective: Bool
}

struct ReceiptTemporaryImageArtifact: Equatable, Sendable {
    let id: UUID
    let fileURL: URL
    let pixelWidth: Int
    let pixelHeight: Int
    let source: ReceiptImageSource
    let correctedPerspective: Bool
}

protocol ReceiptImageProcessing: Sendable {
    func prepare(
        _ input: ReceiptImageInput,
        policy: ReceiptImageLifecyclePolicy
    ) async throws -> ReceiptPreparedImageBytes
}

struct ReceiptImageProcessor: ReceiptImageProcessing, Sendable {
    func prepare(
        _ input: ReceiptImageInput,
        policy: ReceiptImageLifecyclePolicy
    ) async throws -> ReceiptPreparedImageBytes {
        try Task.checkCancellation()
        guard !input.data.isEmpty else { throw ReceiptImageLifecycleError.emptyInput }
        guard input.data.count <= policy.maximumSourceBytes else {
            throw ReceiptImageLifecycleError.sourceTooLarge
        }
        guard let source = CGImageSourceCreateWithData(input.data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else {
            throw ReceiptImageLifecycleError.unsupportedImage
        }

        let sourceDimensions = try imageDimensions(source)
        guard try checkedPixelCount(sourceDimensions) <= policy.maximumSourcePixels else {
            throw ReceiptImageLifecycleError.sourceTooLarge
        }
        try Task.checkCancellation()

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: try maximumThumbnailEdge(
                sourceDimensions,
                policy: policy
            ),
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let normalizedImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            throw ReceiptImageLifecycleError.unsupportedImage
        }
        try validatePreparedDimensions(normalizedImage, policy: policy)
        try Task.checkCancellation()

        let context = CIContext(options: [.cacheIntermediates: false])
        let quadrilateral = try ReceiptVisionObservation.rectangle(in: normalizedImage)
        let correctedImage = quadrilateral.flatMap {
            ReceiptPerspectiveCorrection.correctedImage(
                normalizedImage,
                quadrilateral: $0,
                context: context
            )
        }
        let finalImage = correctedImage ?? normalizedImage
        try validatePreparedDimensions(finalImage, policy: policy)
        try Task.checkCancellation()

        let encoded = try encodeJPEG(finalImage, maximumBytes: policy.maximumPreparedBytes)
        return ReceiptPreparedImageBytes(
            data: encoded,
            pixelWidth: finalImage.width,
            pixelHeight: finalImage.height,
            source: input.source,
            correctedPerspective: correctedImage != nil
        )
    }

    private func imageDimensions(_ source: CGImageSource) throws -> (width: Int, height: Int) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
            as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0,
              height > 0 else {
            throw ReceiptImageLifecycleError.invalidPixelDimensions
        }
        return (width, height)
    }

    private func checkedPixelCount(_ dimensions: (width: Int, height: Int)) throws -> Int {
        let result = dimensions.width.multipliedReportingOverflow(by: dimensions.height)
        guard !result.overflow else { throw ReceiptImageLifecycleError.invalidPixelDimensions }
        return result.partialValue
    }

    /// ImageIO accepts only a longest-edge thumbnail bound. Derive that edge from both reviewed
    /// limits so a common full-resolution iPhone capture (for example 4032 x 3024) is reduced
    /// before the prepared-pixel check instead of being rejected for narrowly exceeding it.
    private func maximumThumbnailEdge(
        _ dimensions: (width: Int, height: Int),
        policy: ReceiptImageLifecyclePolicy
    ) throws -> Int {
        guard policy.maximumPreparedEdge > 0,
              policy.maximumPreparedPixels > 0 else {
            throw ReceiptImageLifecycleError.invalidPixelDimensions
        }

        let longEdge = max(dimensions.width, dimensions.height)
        let shortEdge = min(dimensions.width, dimensions.height)
        var lowerBound = 1
        var upperBound = min(longEdge, policy.maximumPreparedEdge)
        var acceptedEdge = 0

        while lowerBound <= upperBound {
            let candidate = lowerBound + (upperBound - lowerBound) / 2
            let scaledShortNumerator = candidate.multipliedReportingOverflow(by: shortEdge)
            guard !scaledShortNumerator.overflow else {
                throw ReceiptImageLifecycleError.invalidPixelDimensions
            }
            let roundedNumerator = scaledShortNumerator.partialValue.addingReportingOverflow(
                longEdge - 1
            )
            guard !roundedNumerator.overflow else {
                throw ReceiptImageLifecycleError.invalidPixelDimensions
            }
            let scaledShortEdge = roundedNumerator.partialValue / longEdge
            let pixels = candidate.multipliedReportingOverflow(by: scaledShortEdge)
            guard !pixels.overflow else {
                throw ReceiptImageLifecycleError.invalidPixelDimensions
            }

            if pixels.partialValue <= policy.maximumPreparedPixels {
                acceptedEdge = candidate
                lowerBound = candidate + 1
            } else {
                upperBound = candidate - 1
            }
        }

        guard acceptedEdge > 0 else {
            throw ReceiptImageLifecycleError.preparedImageTooLarge
        }
        return acceptedEdge
    }

    private func validatePreparedDimensions(
        _ image: CGImage,
        policy: ReceiptImageLifecyclePolicy
    ) throws {
        guard image.width > 0,
              image.height > 0,
              image.width <= policy.maximumPreparedEdge,
              image.height <= policy.maximumPreparedEdge,
              try checkedPixelCount((image.width, image.height)) <= policy.maximumPreparedPixels else {
            throw ReceiptImageLifecycleError.preparedImageTooLarge
        }
    }

    private func encodeJPEG(_ image: CGImage, maximumBytes: Int) throws -> Data {
        for quality in [0.88, 0.76, 0.64] {
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else {
                throw ReceiptImageLifecycleError.encodingFailed
            }
            CGImageDestinationAddImage(
                destination,
                image,
                [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
            )
            guard CGImageDestinationFinalize(destination) else {
                throw ReceiptImageLifecycleError.encodingFailed
            }
            if data.length <= maximumBytes {
                return data as Data
            }
        }
        throw ReceiptImageLifecycleError.preparedImageTooLarge
    }
}

protocol ReceiptTemporaryImageStoring: Sendable {
    func replace(with image: ReceiptPreparedImageBytes) async throws -> ReceiptTemporaryImageArtifact
    func removeAll() async
}

actor ReceiptTemporaryImageStore: ReceiptTemporaryImageStoring {
    private let fileManager: FileManager
    private let directoryURL: URL

    init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL ?? fileManager.temporaryDirectory
            .appendingPathComponent("MindBudgetReceiptImport", isDirectory: true)
    }

    func replace(with image: ReceiptPreparedImageBytes) async throws -> ReceiptTemporaryImageArtifact {
        try Task.checkCancellation()
        do {
            try removeDirectoryIfPresent()
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
            var protectedDirectory = directoryURL
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try protectedDirectory.setResourceValues(values)

            let id = UUID()
            let fileURL = directoryURL.appendingPathComponent("prepared-\(id.uuidString).jpg")
            try Task.checkCancellation()
            try image.data.write(to: fileURL, options: .atomic)
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: fileURL.path
            )
            try Task.checkCancellation()
            return ReceiptTemporaryImageArtifact(
                id: id,
                fileURL: fileURL,
                pixelWidth: image.pixelWidth,
                pixelHeight: image.pixelHeight,
                source: image.source,
                correctedPerspective: image.correctedPerspective
            )
        } catch is CancellationError {
            try? removeDirectoryIfPresent()
            throw CancellationError()
        } catch {
            try? removeDirectoryIfPresent()
            throw ReceiptImageLifecycleError.temporaryStorageFailed
        }
    }

    func removeAll() async {
        try? removeDirectoryIfPresent()
    }

    private func removeDirectoryIfPresent() throws {
        if fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.removeItem(at: directoryURL)
        }
    }
}

protocol ReceiptImageLifecycleHandling: Sendable {
    func start() async
    func prepare(_ input: ReceiptImageInput) async throws -> ReceiptTemporaryImageArtifact
    func discardTemporaryImage(matching artifactID: UUID) async
    func discardTemporaryImage() async
}

actor ReceiptImageLifecycle: ReceiptImageLifecycleHandling {
    private let processor: any ReceiptImageProcessing
    private let store: any ReceiptTemporaryImageStoring
    private let policy: ReceiptImageLifecyclePolicy
    private var hasStarted = false
    private var generation = 0
    private var processingTask: Task<ReceiptPreparedImageBytes, Error>?
    private var currentArtifactID: UUID?

    init(
        processor: any ReceiptImageProcessing = ReceiptImageProcessor(),
        store: any ReceiptTemporaryImageStoring = ReceiptTemporaryImageStore(),
        policy: ReceiptImageLifecyclePolicy = .standard
    ) {
        self.processor = processor
        self.store = store
        self.policy = policy
    }

    /// Clears any crash-orphaned artifact once per process lifecycle without allowing a later
    /// SwiftUI task recreation to erase an active import.
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        currentArtifactID = nil
        await store.removeAll()
    }

    func prepare(_ input: ReceiptImageInput) async throws -> ReceiptTemporaryImageArtifact {
        await start()
        generation += 1
        let acceptedGeneration = generation
        processingTask?.cancel()
        currentArtifactID = nil
        await store.removeAll()

        let processor = processor
        let policy = policy
        let task = Task {
            try await processor.prepare(input, policy: policy)
        }
        processingTask = task

        do {
            let prepared = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            guard acceptedGeneration == generation, !Task.isCancelled else {
                throw ReceiptImageLifecycleError.superseded
            }
            let artifact = try await store.replace(with: prepared)
            guard acceptedGeneration == generation, !Task.isCancelled else {
                throw ReceiptImageLifecycleError.superseded
            }
            currentArtifactID = artifact.id
            processingTask = nil
            return artifact
        } catch {
            if acceptedGeneration == generation {
                processingTask = nil
                currentArtifactID = nil
                await store.removeAll()
            }
            throw error
        }
    }

    /// A completed recognition generation may clean up only the artifact it received. A late
    /// cancellation or processor completion must never remove a newer generation's image.
    func discardTemporaryImage(matching artifactID: UUID) async {
        guard currentArtifactID == artifactID else { return }
        generation += 1
        processingTask?.cancel()
        processingTask = nil
        currentArtifactID = nil
        await store.removeAll()
    }

    /// Cancellation, backgrounding, memory pressure, and successful downstream handoff all use
    /// this same idempotent boundary. Neither source bytes nor a prepared artifact may survive it.
    func discardTemporaryImage() async {
        generation += 1
        processingTask?.cancel()
        processingTask = nil
        currentArtifactID = nil
        await store.removeAll()
    }
}

struct NoopReceiptImageLifecycle: ReceiptImageLifecycleHandling, Sendable {
    func start() async {}

    func prepare(_ input: ReceiptImageInput) async throws -> ReceiptTemporaryImageArtifact {
        throw ReceiptImageLifecycleError.superseded
    }

    func discardTemporaryImage(matching artifactID: UUID) async {}

    func discardTemporaryImage() async {}
}
