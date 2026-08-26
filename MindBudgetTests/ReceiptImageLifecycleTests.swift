import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import MindBudget

@Suite(.serialized)
struct ReceiptImageLifecycleTests {
    @Test
    func capabilityFailsClosedBeforeProductAndProGates() {
        #expect(
            ReceiptImageAcquisitionCapability.resolve(
                productScopeEnabled: false,
                baseline: .deterministic,
                cameraAuthorization: .authorized,
                dataScannerSupported: true,
                dataScannerAvailable: true
            ) == ReceiptImageAcquisitionCapability(
                camera: .productDisabled,
                photoPickerAvailable: false
            )
        )
        #expect(
            ReceiptImageAcquisitionCapability.resolve(
                productScopeEnabled: true,
                baseline: .unavailable,
                cameraAuthorization: .authorized,
                dataScannerSupported: true,
                dataScannerAvailable: true
            ) == ReceiptImageAcquisitionCapability(
                camera: .requiresPro,
                photoPickerAvailable: false
            )
        )
    }

    @Test
    func capabilityDistinguishesPermissionHardwareAndTemporaryAvailability() {
        let cases: [(ReceiptCameraAuthorization, Bool, Bool, ReceiptCameraAvailability)] = [
            (.authorized, false, false, .unsupported),
            (.notDetermined, true, true, .permissionNotDetermined),
            (.denied, true, true, .permissionDenied),
            (.restricted, true, true, .permissionDenied),
            (.authorized, true, false, .temporarilyUnavailable),
            (.authorized, true, true, .available),
        ]

        for (authorization, supported, available, expected) in cases {
            let capability = ReceiptImageAcquisitionCapability.resolve(
                productScopeEnabled: true,
                baseline: .deterministic,
                cameraAuthorization: authorization,
                dataScannerSupported: supported,
                dataScannerAvailable: available
            )
            #expect(capability.camera == expected)
            #expect(capability.photoPickerAvailable)
        }
    }

    @Test
    func processorRejectsEmptyCorruptAndOversizedEncodedInput() async throws {
        let processor = ReceiptImageProcessor()
        let policy = ReceiptImageLifecyclePolicy(
            maximumSourceBytes: 16,
            maximumSourcePixels: 1_000,
            maximumPreparedEdge: 100,
            maximumPreparedPixels: 1_000,
            maximumPreparedBytes: 1_000
        )

        await expectLifecycleError(.emptyInput) {
            _ = try await processor.prepare(
                ReceiptImageInput(data: Data(), source: .camera),
                policy: policy
            )
        }
        await expectLifecycleError(.unsupportedImage) {
            _ = try await processor.prepare(
                ReceiptImageInput(data: Data([1, 2, 3]), source: .photoPicker),
                policy: policy
            )
        }
        await expectLifecycleError(.sourceTooLarge) {
            _ = try await processor.prepare(
                ReceiptImageInput(data: Data(repeating: 0, count: 17), source: .camera),
                policy: policy
            )
        }
    }

    @Test
    func processorRejectsDecodableImageAboveSourcePixelLimit() async throws {
        let sourceData = try jpeg(width: 80, height: 40, orientation: 1)
        let processor = ReceiptImageProcessor()

        await expectLifecycleError(.sourceTooLarge) {
            _ = try await processor.prepare(
                ReceiptImageInput(data: sourceData, source: .photoPicker),
                policy: ReceiptImageLifecyclePolicy(
                    maximumSourceBytes: 1_000_000,
                    maximumSourcePixels: 3_199,
                    maximumPreparedEdge: 100,
                    maximumPreparedPixels: 10_000,
                    maximumPreparedBytes: 200_000
                )
            )
        }
    }

    @Test
    func imageIOAppliesOrientationAndBoundsPreparedPixels() async throws {
        let sourceData = try jpeg(width: 80, height: 40, orientation: 6)
        let processor = ReceiptImageProcessor()
        let result = try await processor.prepare(
            ReceiptImageInput(data: sourceData, source: .photoPicker),
            policy: ReceiptImageLifecyclePolicy(
                maximumSourceBytes: 1_000_000,
                maximumSourcePixels: 10_000,
                maximumPreparedEdge: 30,
                maximumPreparedPixels: 900,
                maximumPreparedBytes: 200_000
            )
        )

        #expect(result.pixelWidth <= 30)
        #expect(result.pixelHeight <= 30)
        #expect(result.pixelHeight > result.pixelWidth)
        #expect(result.data.count <= 200_000)
    }

    @Test
    func fullResolutionIPhoneCaptureIsDownsampledToThePreparedPixelLimit() async throws {
        let sourceData = try jpeg(width: 4_032, height: 3_024, orientation: 1)
        let policy = ReceiptImageLifecyclePolicy.standard
        let result = try await ReceiptImageProcessor().prepare(
            ReceiptImageInput(data: sourceData, source: .camera),
            policy: policy
        )
        let preparedPixels = result.pixelWidth.multipliedReportingOverflow(
            by: result.pixelHeight
        )

        #expect(result.pixelWidth <= policy.maximumPreparedEdge)
        #expect(result.pixelHeight <= policy.maximumPreparedEdge)
        #expect(!preparedPixels.overflow)
        #expect(
            !preparedPixels.overflow
                && preparedPixels.partialValue <= policy.maximumPreparedPixels
        )
        #expect(result.data.count <= policy.maximumPreparedBytes)
    }

    @Test
    func perspectiveCorrectionRejectsOutOfRangeGeometryAndAcceptsUnitSquare() throws {
        let image = try cgImage(width: 40, height: 20)
        let context = CIContext(options: [.cacheIntermediates: false])
        let valid = ReceiptQuadrilateral(
            topLeft: .init(x: 0, y: 1),
            topRight: .init(x: 1, y: 1),
            bottomRight: .init(x: 1, y: 0),
            bottomLeft: .init(x: 0, y: 0)
        )
        let invalid = ReceiptQuadrilateral(
            topLeft: .init(x: -1, y: 1),
            topRight: .init(x: 1, y: 1),
            bottomRight: .init(x: 1, y: 0),
            bottomLeft: .init(x: 0, y: 0)
        )

        #expect(
            ReceiptPerspectiveCorrection.correctedImage(
                image,
                quadrilateral: valid,
                context: context
            ) != nil
        )
        #expect(
            ReceiptPerspectiveCorrection.correctedImage(
                image,
                quadrilateral: invalid,
                context: context
            ) == nil
        )
    }

    @Test
    func discardCancelsSuspendedProcessingBeforeAnyArtifactCanCommit() async {
        let processor = GatedReceiptImageProcessor()
        let store = ReceiptImageStoreProbe()
        let lifecycle = ReceiptImageLifecycle(processor: processor, store: store)
        let task = Task {
            try await lifecycle.prepare(
                ReceiptImageInput(data: Data([9]), source: .camera)
            )
        }

        await processor.waitUntilEntered()
        await lifecycle.discardTemporaryImage()
        await processor.release()

        do {
            _ = try await task.value
            Issue.record("Canceled processing unexpectedly produced an artifact")
        } catch is CancellationError {
            // Expected: the lifecycle canceled the suspended processing task.
        } catch {
            Issue.record("Unexpected cancellation error: \(error)")
        }
        #expect(await store.replaceCount == 0)
        #expect(await store.removeCount >= 2)
    }

    @Test
    func callerCancellationPropagatesBeforeAnyArtifactCanCommit() async {
        let processor = GatedReceiptImageProcessor()
        let store = ReceiptImageStoreProbe()
        let lifecycle = ReceiptImageLifecycle(processor: processor, store: store)
        let task = Task {
            try await lifecycle.prepare(
                ReceiptImageInput(data: Data([9]), source: .camera)
            )
        }

        await processor.waitUntilEntered()
        task.cancel()
        await processor.release()

        do {
            _ = try await task.value
            Issue.record("Canceled caller unexpectedly produced an artifact")
        } catch is CancellationError {
            // Expected: caller cancellation is forwarded to the processor task.
        } catch {
            Issue.record("Unexpected cancellation error: \(error)")
        }
        #expect(await store.replaceCount == 0)
        #expect(await store.removeCount >= 2)
    }

    @Test
    func startupRemovesCrashOrphanBeforeAcceptingNewWork() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudget-C4C02-Orphan-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: root.appendingPathComponent("prepared-orphan.jpg"))
        let store = ReceiptTemporaryImageStore(directoryURL: root)
        let lifecycle = ReceiptImageLifecycle(
            processor: ImmediateReceiptImageProcessor(),
            store: store
        )
        defer { try? FileManager.default.removeItem(at: root) }

        await lifecycle.start()

        #expect(!FileManager.default.fileExists(atPath: root.path))
    }

    @Test
    func temporaryStoreKeepsOnlyPreparedBytesAcrossRepeatedLifecycleCleanup() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudget-C4C02-\(UUID().uuidString)", isDirectory: true)
        let store = ReceiptTemporaryImageStore(directoryURL: root)
        let processor = ImmediateReceiptImageProcessor()
        let lifecycle = ReceiptImageLifecycle(processor: processor, store: store)
        defer { try? FileManager.default.removeItem(at: root) }

        for index in 0..<12 {
            let source = Data(repeating: UInt8(index), count: 64)
            let artifact = try await lifecycle.prepare(
                ReceiptImageInput(data: source, source: .photoPicker)
            )
            #expect(FileManager.default.fileExists(atPath: artifact.fileURL.path))
            #expect(try Data(contentsOf: artifact.fileURL) == ImmediateReceiptImageProcessor.output)
            #expect(
                try FileManager.default.contentsOfDirectory(
                    at: root,
                    includingPropertiesForKeys: nil
                ).count == 1
            )

            await lifecycle.discardTemporaryImage()
            #expect(!FileManager.default.fileExists(atPath: root.path))
        }
    }

    @Test
    func twentySequentialRealImagesStayBoundedAndLeaveNoTemporaryArtifact() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MindBudget-C4C05-TwentyImages-\(UUID().uuidString)", isDirectory: true)
        let lifecycle = ReceiptImageLifecycle(
            processor: ReceiptImageProcessor(),
            store: ReceiptTemporaryImageStore(directoryURL: root)
        )
        defer { try? FileManager.default.removeItem(at: root) }

        for index in 0..<20 {
            let source = try jpeg(
                width: 320 + index * 3,
                height: 180 + index * 2,
                orientation: index.isMultiple(of: 2) ? 1 : 6
            )
            let artifact = try await lifecycle.prepare(
                ReceiptImageInput(data: source, source: .photoPicker)
            )
            let files = try FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil
            )

            #expect(artifact.pixelWidth <= ReceiptImageLifecyclePolicy.standard.maximumPreparedEdge)
            #expect(artifact.pixelHeight <= ReceiptImageLifecyclePolicy.standard.maximumPreparedEdge)
            #expect(files == [artifact.fileURL])

            await lifecycle.discardTemporaryImage()
            #expect(!FileManager.default.fileExists(atPath: root.path))
        }
    }

    private func expectLifecycleError(
        _ expected: ReceiptImageLifecycleError,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            Issue.record("Expected lifecycle error \(expected)")
        } catch let error as ReceiptImageLifecycleError {
            #expect(error == expected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func jpeg(width: Int, height: Int, orientation: Int) throws -> Data {
        let image = try cgImage(width: width, height: height)
        let data = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImagePropertyOrientation: orientation] as CFDictionary
        )
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    private func cgImage(width: Int, height: Int) throws -> CGImage {
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try #require(context.makeImage())
    }
}

private actor GatedReceiptImageProcessor: ReceiptImageProcessing {
    private var entered = false
    private var entryWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func prepare(
        _ input: ReceiptImageInput,
        policy: ReceiptImageLifecyclePolicy
    ) async throws -> ReceiptPreparedImageBytes {
        entered = true
        let waiters = entryWaiters
        entryWaiters.removeAll()
        waiters.forEach { $0.resume() }
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
        try Task.checkCancellation()
        return ImmediateReceiptImageProcessor.prepared(source: input.source)
    }

    func waitUntilEntered() async {
        guard !entered else { return }
        await withCheckedContinuation { continuation in
            entryWaiters.append(continuation)
        }
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

private struct ImmediateReceiptImageProcessor: ReceiptImageProcessing, Sendable {
    static let output = Data([7, 8, 9, 10])

    static func prepared(source: ReceiptImageSource) -> ReceiptPreparedImageBytes {
        ReceiptPreparedImageBytes(
            data: output,
            pixelWidth: 2,
            pixelHeight: 2,
            source: source,
            correctedPerspective: false
        )
    }

    func prepare(
        _ input: ReceiptImageInput,
        policy: ReceiptImageLifecyclePolicy
    ) async throws -> ReceiptPreparedImageBytes {
        Self.prepared(source: input.source)
    }
}

private actor ReceiptImageStoreProbe: ReceiptTemporaryImageStoring {
    private(set) var replaceCount = 0
    private(set) var removeCount = 0

    func replace(with image: ReceiptPreparedImageBytes) async throws -> ReceiptTemporaryImageArtifact {
        replaceCount += 1
        return ReceiptTemporaryImageArtifact(
            id: UUID(),
            fileURL: URL(fileURLWithPath: "/private/tmp/receipt-probe.jpg"),
            pixelWidth: image.pixelWidth,
            pixelHeight: image.pixelHeight,
            source: image.source,
            correctedPerspective: image.correctedPerspective
        )
    }

    func removeAll() async {
        removeCount += 1
    }
}
