import AVFoundation
import Foundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import VisionKit

enum ReceiptCameraAuthorization: Equatable, Sendable {
    case notDetermined
    case denied
    case restricted
    case authorized
}

enum ReceiptCameraAvailability: Equatable, Sendable {
    case productDisabled
    case requiresPro
    case unsupported
    case permissionNotDetermined
    case permissionDenied
    case temporarilyUnavailable
    case available
}

struct ReceiptImageAcquisitionCapability: Equatable, Sendable {
    let camera: ReceiptCameraAvailability
    let photoPickerAvailable: Bool

    static func resolve(
        productScopeEnabled: Bool = FeatureFlags.enableReceiptImport,
        baseline: LocalReceiptRecognitionBaseline,
        cameraAuthorization: ReceiptCameraAuthorization,
        dataScannerSupported: Bool,
        dataScannerAvailable: Bool
    ) -> ReceiptImageAcquisitionCapability {
        guard productScopeEnabled else {
            return ReceiptImageAcquisitionCapability(
                camera: .productDisabled,
                photoPickerAvailable: false
            )
        }
        guard baseline != .unavailable else {
            return ReceiptImageAcquisitionCapability(
                camera: .requiresPro,
                photoPickerAvailable: false
            )
        }

        let camera: ReceiptCameraAvailability
        if !dataScannerSupported {
            camera = .unsupported
        } else {
            camera = switch cameraAuthorization {
            case .notDetermined:
                .permissionNotDetermined
            case .denied, .restricted:
                .permissionDenied
            case .authorized where !dataScannerAvailable:
                .temporarilyUnavailable
            case .authorized:
                .available
            }
        }
        return ReceiptImageAcquisitionCapability(camera: camera, photoPickerAvailable: true)
    }
}

@MainActor
protocol ReceiptSystemImageAcquiring: AnyObject {
    func cameraAuthorization() -> ReceiptCameraAuthorization
    func requestCameraAuthorization() async -> ReceiptCameraAuthorization
    func makePhotoPicker() -> PHPickerViewController
    func makeDataScanner() throws -> DataScannerViewController
    func startScanning(_ scanner: DataScannerViewController) throws
    func stopScanning(_ scanner: DataScannerViewController)
    func captureImage(from scanner: DataScannerViewController) async throws -> ReceiptImageInput
    func loadImage(from result: PHPickerResult) async throws -> ReceiptImageInput
}

@MainActor
final class ReceiptSystemImageAcquisition: ReceiptSystemImageAcquiring {
    func cameraAuthorization() -> ReceiptCameraAuthorization {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            .notDetermined
        case .restricted:
            .restricted
        case .denied:
            .denied
        case .authorized:
            .authorized
        @unknown default:
            .denied
        }
    }

    /// Called only after the owner explicitly selects the camera source.
    func requestCameraAuthorization() async -> ReceiptCameraAuthorization {
        if cameraAuthorization() == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        return cameraAuthorization()
    }

    func makePhotoPicker() -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        return PHPickerViewController(configuration: configuration)
    }

    func makeDataScanner() throws -> DataScannerViewController {
        guard DataScannerViewController.isSupported else {
            throw ReceiptImageLifecycleError.unsupportedImage
        }
        guard DataScannerViewController.isAvailable else {
            throw ReceiptImageLifecycleError.superseded
        }
        // C4C-02 uses DataScanner only as a bounded camera surface. No delegate is installed and
        // no recognized item crosses this adapter; OCR belongs exclusively to C4C-03.
        return DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: false
        )
    }

    func captureImage(from scanner: DataScannerViewController) async throws -> ReceiptImageInput {
        try Task.checkCancellation()
        let image = try await scanner.capturePhoto()
        try Task.checkCancellation()
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw ReceiptImageLifecycleError.encodingFailed
        }
        return ReceiptImageInput(data: data, source: .camera)
    }

    func startScanning(_ scanner: DataScannerViewController) throws {
        try scanner.startScanning()
    }

    func stopScanning(_ scanner: DataScannerViewController) {
        scanner.stopScanning()
    }

    func loadImage(from result: PHPickerResult) async throws -> ReceiptImageInput {
        let provider = result.itemProvider
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
            throw ReceiptImageLifecycleError.unsupportedImage
        }

        let operation = ReceiptItemProviderLoad()
        let data = try await operation.load(
            from: provider,
            typeIdentifier: UTType.image.identifier,
            maximumBytes: ReceiptImageLifecyclePolicy.standard.maximumSourceBytes
        )
        try Task.checkCancellation()
        return ReceiptImageInput(data: data, source: .photoPicker)
    }
}

/// NSItemProvider cancellation has no Sendable async API. This one-shot lock closes both races:
/// cancellation before Progress installation and a provider callback after cancellation.
private final class ReceiptItemProviderLoad: @unchecked Sendable {
    private let lock = NSLock()
    private var progress: Progress?
    private var continuation: CheckedContinuation<Data, Error>?
    private var completed = false

    @MainActor
    func load(
        from provider: NSItemProvider,
        typeIdentifier: String,
        maximumBytes: Int
    ) async throws -> Data {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                install(continuation: continuation)
                let progress = provider.loadFileRepresentation(
                    forTypeIdentifier: typeIdentifier
                ) { [weak self] fileURL, error in
                    self?.finish(
                        fileURL: fileURL,
                        error: error,
                        maximumBytes: maximumBytes
                    )
                }
                install(progress: progress)
            }
        } onCancel: { [weak self] in
            self?.cancel()
        }
    }

    private func install(continuation: CheckedContinuation<Data, Error>) {
        lock.lock()
        if completed {
            lock.unlock()
            continuation.resume(throwing: CancellationError())
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    private func install(progress: Progress) {
        lock.lock()
        if completed {
            lock.unlock()
            progress.cancel()
            return
        }
        self.progress = progress
        lock.unlock()
    }

    private func finish(fileURL: URL?, error: Error?, maximumBytes: Int) {
        let continuation: CheckedContinuation<Data, Error>?
        lock.lock()
        guard !completed else {
            lock.unlock()
            return
        }
        completed = true
        continuation = self.continuation
        self.continuation = nil
        progress = nil
        lock.unlock()

        do {
            if let error { throw error }
            guard let fileURL else { throw ReceiptImageLifecycleError.unsupportedImage }
            let readLimit = maximumBytes.addingReportingOverflow(1)
            guard maximumBytes >= 0, !readLimit.overflow else {
                throw ReceiptImageLifecycleError.sourceTooLarge
            }
            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: readLimit.partialValue) ?? Data()
            guard data.count <= maximumBytes else {
                throw ReceiptImageLifecycleError.sourceTooLarge
            }
            continuation?.resume(returning: data)
        } catch {
            continuation?.resume(throwing: error)
        }
    }

    private func cancel() {
        let continuation: CheckedContinuation<Data, Error>?
        let progress: Progress?
        lock.lock()
        guard !completed else {
            lock.unlock()
            return
        }
        completed = true
        continuation = self.continuation
        self.continuation = nil
        progress = self.progress
        self.progress = nil
        lock.unlock()
        progress?.cancel()
        continuation?.resume(throwing: CancellationError())
    }
}
