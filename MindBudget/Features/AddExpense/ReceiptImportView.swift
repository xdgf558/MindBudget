import Foundation
import OSLog
import SwiftUI
import UIKit

enum ReceiptImportFailure: Equatable, Sendable {
    case permissionDenied
    case cameraUnsupported
    case cameraTemporarilyUnavailable
    case unreadableImage
    case localDataUnavailable
    case productDisabled
    case requiresPro

    var titleKey: String {
        switch self {
        case .permissionDenied: "receipt.permission.title"
        case .cameraUnsupported: "receipt.error.cameraUnsupported.title"
        case .cameraTemporarilyUnavailable: "receipt.error.cameraUnavailable.title"
        case .unreadableImage: "receipt.failure.inline.title"
        case .localDataUnavailable: "receipt.error.localData.title"
        case .productDisabled: "receipt.error.productDisabled.title"
        case .requiresPro: "receipt.error.requiresPro.title"
        }
    }

    var detailKey: String {
        switch self {
        case .permissionDenied: "receipt.error.cameraPermission"
        case .cameraUnsupported: "receipt.error.cameraUnsupported"
        case .cameraTemporarilyUnavailable: "receipt.error.cameraUnavailable"
        case .unreadableImage: "receipt.failure.inline.detail"
        case .localDataUnavailable: "receipt.error.localData"
        case .productDisabled: "receipt.error.productDisabled.detail"
        case .requiresPro: "receipt.error.requiresPro.detail"
        }
    }

    var allowsCaptureRetry: Bool {
        switch self {
        case .permissionDenied, .cameraUnsupported, .cameraTemporarilyUnavailable,
             .unreadableImage:
            true
        case .localDataUnavailable, .productDisabled, .requiresPro:
            false
        }
    }
}

enum ReceiptRecognitionPhase: Equatable, Sendable {
    case none
    case recognizing
    case review(ReceiptStructuredExtractionResult)
    case failed(ReceiptImportFailure)
}

enum ReceiptImportState: Equatable, Sendable {
    case introduction
    case camera
    case previewing(ReceiptImageInput)
    case failed(ReceiptImportFailure)
}

enum ReceiptImportContextBuilder {
    static func dateOrder(for locale: Locale) -> ReceiptDateOrder {
        locale.region?.identifier == "US" ? .monthDayYear : .dayMonthYear
    }

    static func duplicateReferences(
        from expenses: [ExpenseSummary],
        calendar: Calendar
    ) -> [ReceiptDuplicateReference] {
        expenses.compactMap { expense in
            guard let timeZone = TimeZone(identifier: expense.spentTimeZoneIdentifier) else {
                return nil
            }
            var expenseCalendar = calendar
            expenseCalendar.timeZone = timeZone
            let components = expenseCalendar.dateComponents(
                [.year, .month, .day],
                from: expense.spentAt
            )
            guard let year = components.year,
                  let month = components.month,
                  let day = components.day else {
                return nil
            }
            return ReceiptDuplicateReference(
                id: expense.id,
                merchantName: expense.merchantName,
                purchaseDate: ReceiptCalendarDate(year: year, month: month, day: day),
                total: expense.amount
            )
        }
    }
}

enum ReceiptImportDiagnostics {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MindBudget",
        category: "ReceiptImport"
    )

    static func failure(for error: Error) -> ReceiptImportFailure {
        logger.notice("reason=\(reason(for: error), privacy: .public)")
        if error is PersistedModelError {
            return .localDataUnavailable
        }
        guard let lifecycleError = error as? ReceiptImageLifecycleError else {
            return .unreadableImage
        }
        return switch lifecycleError {
        case .temporarilyUnavailable: .cameraTemporarilyUnavailable
        case .unsupportedImage: .unreadableImage
        case .emptyInput, .sourceTooLarge, .invalidPixelDimensions, .preparedImageTooLarge,
             .encodingFailed, .temporaryStorageFailed, .superseded:
            .unreadableImage
        }
    }

    /// Closed reason codes make physical failures diagnosable without logging receipt content.
    private static func reason(for error: Error) -> String {
        if let lifecycleError = error as? ReceiptImageLifecycleError {
            return switch lifecycleError {
            case .emptyInput: "image.emptyInput"
            case .sourceTooLarge: "image.sourceTooLarge"
            case .unsupportedImage: "image.unsupported"
            case .invalidPixelDimensions: "image.invalidPixelDimensions"
            case .preparedImageTooLarge: "image.preparedImageTooLarge"
            case .encodingFailed: "image.encodingFailed"
            case .temporaryStorageFailed: "image.temporaryStorageFailed"
            case .temporarilyUnavailable: "image.temporarilyUnavailable"
            case .superseded: "image.superseded"
            }
        }
        if let privacyError = error as? ReceiptOCRPrivacyError {
            return switch privacyError {
            case .invalidPolicy: "ocr.invalidPolicy"
            case .tooManyObservations: "ocr.tooManyObservations"
            case .observationTooLarge: "ocr.observationTooLarge"
            case .documentTooLarge: "ocr.documentTooLarge"
            case .invalidGeometry: "ocr.invalidGeometry"
            case .invalidConfidence: "ocr.invalidConfidence"
            case .sensitiveTextRejected: "ocr.sensitiveTextRejected"
            }
        }
        if let extractionError = error as? ReceiptStructuredExtractionError {
            return switch extractionError {
            case .unavailable: "extraction.unavailable"
            case .invalidContext: "extraction.invalidContext"
            case .modelUnavailable: "extraction.modelUnavailable"
            case .timedOut: "extraction.timedOut"
            }
        }
        if error is PersistedModelError {
            return "storage.unavailable"
        }
        return "other.unclassified"
    }
}

@MainActor
final class ReceiptImportViewModel: ObservableObject {
    @Published private(set) var state: ReceiptImportState
    @Published private(set) var capability: ReceiptImageAcquisitionCapability

    let acquisition: any ReceiptSystemImageAcquiring

    init(
        baseline: LocalReceiptRecognitionBaseline,
        showsIntroduction: Bool,
        acquisition: any ReceiptSystemImageAcquiring = ReceiptSystemImageAcquisition()
    ) {
        self.acquisition = acquisition
        let resolvedCapability = acquisition.capability(baseline: baseline)
        capability = resolvedCapability
        if showsIntroduction || resolvedCapability.camera == .permissionNotDetermined {
            state = .introduction
        } else {
            state = Self.destination(for: resolvedCapability.camera)
        }
    }

    func refreshCapability(baseline: LocalReceiptRecognitionBaseline) {
        capability = acquisition.capability(baseline: baseline)
    }

    func openCamera(baseline: LocalReceiptRecognitionBaseline) async {
        refreshCapability(baseline: baseline)
        if capability.camera == .permissionNotDetermined {
            _ = await acquisition.requestCameraAuthorization()
            refreshCapability(baseline: baseline)
        }
        state = Self.destination(for: capability.camera)
    }

    func acceptCapture(_ result: Result<ReceiptImageInput, Error>) {
        switch result {
        case let .success(input):
            state = .previewing(input)
        case let .failure(error):
            state = .failed(ReceiptImportDiagnostics.failure(for: error))
        }
    }

    func retake() {
        state = Self.destination(for: capability.camera)
    }

    static func destination(
        for availability: ReceiptCameraAvailability
    ) -> ReceiptImportState {
        switch availability {
        case .available:
            .camera
        case .permissionDenied:
            .failed(.permissionDenied)
        case .unsupported:
            .failed(.cameraUnsupported)
        case .temporarilyUnavailable:
            .failed(.cameraTemporarilyUnavailable)
        case .permissionNotDetermined:
            .introduction
        case .productDisabled:
            .failed(.productDisabled)
        case .requiresPro:
            .failed(.requiresPro)
        }
    }
}

struct ReceiptImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.mindBudgetTheme) private var theme
    @StateObject private var viewModel: ReceiptImportViewModel
    @State private var presentsPhotoPicker = false
    @State private var didHandOffImage = false
    @State private var captureRequestID = 0
    @State private var isCapturing = false
    @State private var flashMode: ReceiptCameraFlashMode = .automatic
    @State private var isOpeningSettings = false

    private let baseline: LocalReceiptRecognitionBaseline
    let acquired: (ReceiptImageInput) -> Void

    init(
        baseline: LocalReceiptRecognitionBaseline,
        showsIntroduction: Bool,
        acquired: @escaping (ReceiptImageInput) -> Void
    ) {
        self.baseline = baseline
        self.acquired = acquired
        _viewModel = StateObject(
            wrappedValue: ReceiptImportViewModel(
                baseline: baseline,
                showsIntroduction: showsIntroduction
            )
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .introduction:
                introduction
            case .camera:
                camera
            case let .previewing(input):
                ReceiptCapturePreviewView(
                    input: input,
                    usePhoto: { handOff(input) },
                    retake: { viewModel.retake() },
                    cancel: dismissFlow
                )
            case let .failed(failure):
                unavailableCamera(failure)
            }
        }
        .sheet(isPresented: $presentsPhotoPicker) {
            ReceiptPhotoPickerView(
                acquisition: viewModel.acquisition,
                selected: { result in
                    presentsPhotoPicker = false
                    viewModel.acceptCapture(result)
                },
                cancelled: { presentsPhotoPicker = false }
            )
            .ignoresSafeArea()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else {
                if isOpeningSettings {
                    isOpeningSettings = false
                    Task { await viewModel.openCamera(baseline: baseline) }
                } else {
                    viewModel.refreshCapability(baseline: baseline)
                }
                return
            }
            guard phase == .background else { return }
            guard !isOpeningSettings else { return }
            guard !didHandOffImage else { return }
            presentsPhotoPicker = false
            dismissFlow()
        }
        .overlay {
            if scenePhase == .inactive {
                ReceiptInactivePrivacyShield()
            }
        }
        .accessibilityIdentifier("receipt.import.view")
    }

    private var introduction: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer(minLength: 12)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(theme.accentDeep)
                    .frame(width: 56, height: 56)
                    .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 18))
                Text("receipt.localOnly.title")
                    .font(.title.bold())
                    .foregroundStyle(theme.ink)
                Text("receipt.localOnly.detail")
                    .font(.body)
                    .foregroundStyle(theme.inkSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 16) {
                    introductionBullet("receipt.source.bullet.fields")
                    introductionBullet("receipt.source.bullet.blank")
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(theme.hairlineStrong, lineWidth: 1)
                }

                Spacer()
                Button {
                    Task { await viewModel.openCamera(baseline: baseline) }
                } label: {
                    Label("receipt.source.openCamera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MindBudgetPrimaryButtonStyle())
                .accessibilityIdentifier("receipt.source.camera")

                if viewModel.capability.photoPickerAvailable {
                    Button {
                        presentsPhotoPicker = true
                    } label: {
                        Label("receipt.source.photos", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MindBudgetSecondaryButtonStyle())
                    .accessibilityIdentifier("receipt.source.photos")
                }

                Text("receipt.confirmation.detail")
                    .font(.footnote)
                    .foregroundStyle(theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .mindBudgetScreenBackground()
            .navigationTitle("receipt.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel", action: dismissFlow)
                }
            }
        }
    }

    private func introductionBullet(_ key: LocalizedStringKey) -> some View {
        Label {
            Text(key)
                .font(.subheadline)
                .foregroundStyle(theme.ink)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(theme.accentDeep)
        }
    }

    private var camera: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ReceiptCameraCaptureView(
                acquisition: viewModel.acquisition,
                flashMode: flashMode,
                captureRequestID: captureRequestID,
                capturingChanged: { isCapturing = $0 },
                captured: viewModel.acceptCapture
            )
            .ignoresSafeArea()

            ReceiptCaptureOverlay(
                flashMode: $flashMode,
                isCapturing: isCapturing,
                capture: { captureRequestID &+= 1 },
                choosePhoto: { presentsPhotoPicker = true },
                cancel: dismissFlow
            )
        }
        .accessibilityIdentifier("receipt.camera.view")
    }

    private func unavailableCamera(_ failure: ReceiptImportFailure) -> some View {
        ZStack {
            Color(red: 0.047, green: 0.047, blue: 0.055).ignoresSafeArea()
            VStack(spacing: 18) {
                HStack {
                    Button(action: dismissFlow) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .foregroundStyle(.white)
                    .accessibilityLabel("common.close")
                    Spacer()
                }
                Spacer()
                Image(systemName: "camera.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(width: 76, height: 76)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "slash.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                Text(LocalizedStringKey(failure.titleKey))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(LocalizedStringKey(failure.detailKey))
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                Spacer()

                if failure == .permissionDenied {
                    Button {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        isOpeningSettings = true
                        UIApplication.shared.open(url)
                    } label: {
                        Text("receipt.permission.openSettings")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MindBudgetPrimaryButtonStyle())
                }

                if viewModel.capability.photoPickerAvailable {
                    Button {
                        presentsPhotoPicker = true
                    } label: {
                        Text(photoActionKey(for: failure))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MindBudgetSecondaryButtonStyle())
                }
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("receipt.camera.failure")
    }

    private func handOff(_ input: ReceiptImageInput) {
        didHandOffImage = true
        acquired(input)
        dismiss()
    }

    private func photoActionKey(for failure: ReceiptImportFailure) -> LocalizedStringKey {
        failure == .permissionDenied
            ? "receipt.permission.usePhotos"
            : "receipt.source.photos"
    }

    private func dismissFlow() {
        dismiss()
    }
}

struct ReceiptInactivePrivacyShield: View {
    var body: some View {
        ZStack {
            Color(red: 0.047, green: 0.047, blue: 0.055)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                Text("receipt.privacy.inactive.title")
                    .font(.headline)
                Text("receipt.privacy.inactive.detail")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.68))
            }
            .foregroundStyle(.white)
            .padding(28)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("receipt.privacy.inactive")
    }
}
