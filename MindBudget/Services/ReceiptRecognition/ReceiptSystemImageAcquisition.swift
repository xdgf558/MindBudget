import AVFoundation
import Foundation
import PhotosUI
import SwiftUI
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
    func capability(baseline: LocalReceiptRecognitionBaseline) -> ReceiptImageAcquisitionCapability
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
    func capability(
        baseline: LocalReceiptRecognitionBaseline
    ) -> ReceiptImageAcquisitionCapability {
        ReceiptImageAcquisitionCapability.resolve(
            baseline: baseline,
            cameraAuthorization: cameraAuthorization(),
            dataScannerSupported: DataScannerViewController.isSupported,
            dataScannerAvailable: DataScannerViewController.isAvailable
        )
    }

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
            throw ReceiptImageLifecycleError.temporarilyUnavailable
        }
        // C4C-02 uses DataScanner only as a bounded camera surface. No delegate is installed and
        // no recognized item crosses this adapter; OCR belongs exclusively to C4C-03.
        return DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
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

/// The picker stays inside the one reviewed PhotosUI adapter. It returns one bounded source to
/// the local lifecycle and never requests broad Photo Library permission.
struct ReceiptPhotoPickerView: UIViewControllerRepresentable {
    let acquisition: any ReceiptSystemImageAcquiring
    let selected: @MainActor (Result<ReceiptImageInput, Error>) -> Void
    let cancelled: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(acquisition: acquisition, selected: selected, cancelled: cancelled)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let picker = acquisition.makePhotoPicker()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let acquisition: any ReceiptSystemImageAcquiring
        private let selected: @MainActor (Result<ReceiptImageInput, Error>) -> Void
        private let cancelled: @MainActor () -> Void

        init(
            acquisition: any ReceiptSystemImageAcquiring,
            selected: @escaping @MainActor (Result<ReceiptImageInput, Error>) -> Void,
            cancelled: @escaping @MainActor () -> Void
        ) {
            self.acquisition = acquisition
            self.selected = selected
            self.cancelled = cancelled
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                cancelled()
                return
            }
            Task {
                do {
                    selected(.success(try await acquisition.loadImage(from: result)))
                } catch {
                    selected(.failure(error))
                }
            }
        }
    }
}

/// The camera surface confines every VisionKit type to this adapter. The scanner performs no live
/// recognition; an explicit shutter action captures one image for the same bounded local pipeline.
struct ReceiptCameraCaptureView: UIViewControllerRepresentable {
    let acquisition: any ReceiptSystemImageAcquiring
    let flashMode: ReceiptCameraFlashMode
    let captureRequestID: Int
    let capturingChanged: @MainActor (Bool) -> Void
    let captured: @MainActor (Result<ReceiptImageInput, Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> ReceiptCameraCaptureController {
        ReceiptCameraCaptureController(
            acquisition: acquisition,
            capturingChanged: capturingChanged,
            captured: captured
        )
    }

    func updateUIViewController(
        _ uiViewController: ReceiptCameraCaptureController,
        context: Context
    ) {
        uiViewController.setFlashMode(flashMode)
        guard captureRequestID != context.coordinator.lastCaptureRequestID else { return }
        context.coordinator.lastCaptureRequestID = captureRequestID
        guard captureRequestID > 0 else { return }
        uiViewController.capture()
    }

    final class Coordinator {
        var lastCaptureRequestID = 0
    }
}

@MainActor
final class ReceiptCameraCaptureController: UIViewController {
    private let acquisition: any ReceiptSystemImageAcquiring
    private let capturingChanged: @MainActor (Bool) -> Void
    private let captured: @MainActor (Result<ReceiptImageInput, Error>) -> Void
    private var scanner: DataScannerViewController?
    private var isCapturing = false

    init(
        acquisition: any ReceiptSystemImageAcquiring,
        capturingChanged: @escaping @MainActor (Bool) -> Void,
        captured: @escaping @MainActor (Result<ReceiptImageInput, Error>) -> Void
    ) {
        self.acquisition = acquisition
        self.capturingChanged = capturingChanged
        self.captured = captured
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        do {
            let scanner = try acquisition.makeDataScanner()
            self.scanner = scanner
            addChild(scanner)
            scanner.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scanner.view)
            scanner.didMove(toParent: self)

            NSLayoutConstraint.activate([
                scanner.view.topAnchor.constraint(equalTo: view.topAnchor),
                scanner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scanner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scanner.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        } catch {
            captured(.failure(error))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let scanner else { return }
        do {
            try acquisition.startScanning(scanner)
        } catch {
            captured(.failure(error))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let scanner { acquisition.stopScanning(scanner) }
        super.viewWillDisappear(animated)
    }

    func capture() {
        guard !isCapturing, let scanner else { return }
        isCapturing = true
        capturingChanged(true)
        Task {
            do {
                captured(.success(try await acquisition.captureImage(from: scanner)))
            } catch {
                captured(.failure(error))
            }
            isCapturing = false
            capturingChanged(false)
        }
    }

    func setFlashMode(_ mode: ReceiptCameraFlashMode) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        let requestedMode: AVCaptureDevice.TorchMode = switch mode {
        case .automatic: .auto
        case .on: .on
        case .off: .off
        }
        guard device.isTorchModeSupported(requestedMode) else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = requestedMode
            device.unlockForConfiguration()
        } catch {
            // The camera remains usable without torch changes; no receipt content is involved.
        }
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
