import Foundation
import SwiftUI

enum ReceiptImportFailure: Equatable, Sendable {
    case permissionDenied
    case cameraUnsupported
    case cameraTemporarilyUnavailable
    case unreadableImage
    case localDataUnavailable

    var localizedKey: LocalizedStringKey {
        switch self {
        case .permissionDenied: "receipt.error.cameraPermission"
        case .cameraUnsupported: "receipt.error.cameraUnsupported"
        case .cameraTemporarilyUnavailable: "receipt.error.cameraUnavailable"
        case .unreadableImage: "receipt.error.unreadable"
        case .localDataUnavailable: "receipt.error.localData"
        }
    }
}

enum ReceiptImportState: Equatable, Sendable {
    case idle
    case processing
    case reviewing(ReceiptStructuredExtractionResult)
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

@MainActor
final class ReceiptImportViewModel: ObservableObject {
    @Published private(set) var state: ReceiptImportState = .idle
    @Published private(set) var capability: ReceiptImageAcquisitionCapability

    let acquisition: any ReceiptSystemImageAcquiring
    private let dataActor: DataActor
    private let lifecycle: any ReceiptImageLifecycleHandling
    private let processor: any ReceiptLocalProcessing
    private let baseline: LocalReceiptRecognitionBaseline
    private let currencyCode: String
    private var generation = 0
    private var operationTask: Task<Void, Never>?

    init(
        dataActor: DataActor,
        lifecycle: any ReceiptImageLifecycleHandling,
        baseline: LocalReceiptRecognitionBaseline,
        currencyCode: String,
        acquisition: any ReceiptSystemImageAcquiring = ReceiptSystemImageAcquisition(),
        processor: any ReceiptLocalProcessing = ReceiptLocalProcessingService()
    ) {
        self.dataActor = dataActor
        self.lifecycle = lifecycle
        self.baseline = baseline
        self.currencyCode = currencyCode
        self.acquisition = acquisition
        self.processor = processor
        capability = acquisition.capability(baseline: baseline)
    }

    func refreshCapability() {
        capability = acquisition.capability(baseline: baseline)
    }

    func requestCameraAccess() async -> Bool {
        refreshCapability()
        switch capability.camera {
        case .permissionNotDetermined:
            _ = await acquisition.requestCameraAuthorization()
            refreshCapability()
        case .available:
            return true
        case .permissionDenied:
            state = .failed(.permissionDenied)
            return false
        case .unsupported:
            state = .failed(.cameraUnsupported)
            return false
        case .temporarilyUnavailable:
            state = .failed(.cameraTemporarilyUnavailable)
            return false
        case .productDisabled, .requiresPro:
            state = .failed(.localDataUnavailable)
            return false
        }

        guard capability.camera == .available else {
            state = capability.camera == .permissionDenied
                ? .failed(.permissionDenied)
                : .failed(.cameraTemporarilyUnavailable)
            return false
        }
        return true
    }

    func acceptSource(
        _ result: Result<ReceiptImageInput, Error>,
        locale: Locale,
        calendar: Calendar
    ) {
        switch result {
        case let .success(input):
            process(input, locale: locale, calendar: calendar)
        case let .failure(error):
            state = .failed(failure(for: error))
        }
    }

    func retry() {
        guard case .processing = state else {
            state = .idle
            refreshCapability()
            return
        }
    }

    func cancel() {
        generation &+= 1
        operationTask?.cancel()
        operationTask = nil
        state = .idle
        let lifecycle = lifecycle
        Task { await lifecycle.discardTemporaryImage() }
    }

    private func process(
        _ input: ReceiptImageInput,
        locale: Locale,
        calendar: Calendar
    ) {
        guard state != .processing else { return }
        generation &+= 1
        let acceptedGeneration = generation
        state = .processing
        let dataActor = dataActor
        let lifecycle = lifecycle
        let processor = processor
        let baseline = baseline
        let currencyCode = currencyCode
        operationTask = Task { [weak self] in
            do {
                let expenses = try await dataActor.fetchExpenseSummaries()
                try Task.checkCancellation()
                let artifact = try await lifecycle.prepare(input)
                let context = ReceiptExtractionContext(
                    expectedCurrencyCode: currencyCode,
                    dateOrder: ReceiptImportContextBuilder.dateOrder(for: locale),
                    calendar: calendar,
                    localeIdentifier: locale.identifier,
                    duplicateReferences: ReceiptImportContextBuilder.duplicateReferences(
                        from: expenses,
                        calendar: calendar
                    )
                )
                let result = try await processor.process(
                    artifact: artifact,
                    baseline: baseline,
                    context: context
                )
                await lifecycle.discardTemporaryImage()
                try Task.checkCancellation()
                guard let self, acceptedGeneration == self.generation else { return }
                self.operationTask = nil
                self.state = .reviewing(result)
            } catch is CancellationError {
                await lifecycle.discardTemporaryImage()
            } catch {
                await lifecycle.discardTemporaryImage()
                guard let self, acceptedGeneration == self.generation else { return }
                self.operationTask = nil
                self.state = .failed(self.failure(for: error))
            }
        }
    }

    private func failure(for error: Error) -> ReceiptImportFailure {
        guard let lifecycleError = error as? ReceiptImageLifecycleError else {
            return error is PersistedModelError
                ? .localDataUnavailable
                : .unreadableImage
        }
        return switch lifecycleError {
        case .temporarilyUnavailable: .cameraTemporarilyUnavailable
        case .unsupportedImage: .unreadableImage
        case .emptyInput, .sourceTooLarge, .invalidPixelDimensions, .preparedImageTooLarge,
             .encodingFailed, .temporaryStorageFailed, .superseded:
            .unreadableImage
        }
    }
}

struct ReceiptImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.mindBudgetTheme) private var theme
    @StateObject private var viewModel: ReceiptImportViewModel
    @State private var presentsPhotoPicker = false
    @State private var presentsCamera = false
    let completed: (ReceiptStructuredExtractionResult) -> Void

    init(
        dataActor: DataActor,
        lifecycle: any ReceiptImageLifecycleHandling,
        baseline: LocalReceiptRecognitionBaseline,
        currencyCode: String,
        completed: @escaping (ReceiptStructuredExtractionResult) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: ReceiptImportViewModel(
                dataActor: dataActor,
                lifecycle: lifecycle,
                baseline: baseline,
                currencyCode: currencyCode
            )
        )
        self.completed = completed
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    sourceSelection
                case .processing:
                    processingView
                case let .reviewing(result):
                    review(result)
                case let .failed(failure):
                    failureView(failure)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .mindBudgetScreenBackground()
            .navigationTitle("receipt.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        viewModel.cancel()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $presentsPhotoPicker) {
            ReceiptPhotoPickerView(
                acquisition: viewModel.acquisition,
                selected: { result in
                    presentsPhotoPicker = false
                    viewModel.acceptSource(result, locale: locale, calendar: calendar)
                },
                cancelled: { presentsPhotoPicker = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $presentsCamera) {
            ReceiptCameraCaptureView(
                acquisition: viewModel.acquisition,
                locale: locale,
                captured: { result in
                    presentsCamera = false
                    viewModel.acceptSource(result, locale: locale, calendar: calendar)
                },
                cancelled: { presentsCamera = false }
            )
            .ignoresSafeArea()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else {
                viewModel.refreshCapability()
                return
            }
            presentsCamera = false
            presentsPhotoPicker = false
            viewModel.cancel()
        }
        .onDisappear { viewModel.cancel() }
        .accessibilityIdentifier("receipt.import.view")
    }

    private var sourceSelection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("receipt.localOnly.title", systemImage: "lock.shield")
                .font(.headline)
                .foregroundStyle(theme.accentDeep)
            Text("receipt.localOnly.detail")
                .font(.subheadline)
                .foregroundStyle(theme.inkSecondary)

            if viewModel.capability.photoPickerAvailable {
                Button {
                    presentsPhotoPicker = true
                } label: {
                    Label("receipt.source.photos", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MindBudgetPrimaryButtonStyle())
                .accessibilityIdentifier("receipt.source.photos")
            }

            Button {
                Task {
                    if await viewModel.requestCameraAccess() {
                        presentsCamera = true
                    }
                }
            } label: {
                Label("receipt.source.camera", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(MindBudgetSecondaryButtonStyle())
            .accessibilityIdentifier("receipt.source.camera")

            cameraGuidance

            Text("receipt.confirmation.detail")
                .font(.footnote)
                .foregroundStyle(theme.inkSecondary)
        }
    }

    @ViewBuilder
    private var cameraGuidance: some View {
        switch viewModel.capability.camera {
        case .permissionDenied:
            Text("receipt.error.cameraPermission")
        case .unsupported:
            Text("receipt.error.cameraUnsupported")
        case .temporarilyUnavailable:
            Text("receipt.error.cameraUnavailable")
        case .productDisabled, .requiresPro, .permissionNotDetermined, .available:
            EmptyView()
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("receipt.processing")
                .font(.headline)
            Text("receipt.processing.detail")
                .font(.subheadline)
                .foregroundStyle(theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("receipt.processing")
    }

    private func failureView(_ failure: ReceiptImportFailure) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(theme.attentionText)
            Text(failure.localizedKey)
                .font(.headline)
                .multilineTextAlignment(.center)
            Button("common.tryAgain") { viewModel.retry() }
                .buttonStyle(MindBudgetPrimaryButtonStyle())
                .accessibilityIdentifier("receipt.retry")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("receipt.failure")
    }

    private func review(_ result: ReceiptStructuredExtractionResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("receipt.review.title", systemImage: "checkmark.seal")
                    .font(.headline)
                    .foregroundStyle(theme.accentDeep)
                Text("receipt.review.detail")
                    .font(.subheadline)
                    .foregroundStyle(theme.inkSecondary)

                VStack(spacing: 12) {
                    reviewRow("receipt.field.merchant", value: merchantText(result.fields.merchantName))
                    reviewRow("receipt.field.date", value: dateText(result.fields.purchaseDate))
                    reviewRow("receipt.field.total", value: totalText(result.fields.total))
                }
                .budgetCard(cornerRadius: 18, contentPadding: 16)

                if case let .exactMatches(ids) = result.duplicateResolution {
                    Label(
                        String.localizedStringWithFormat(
                            LocalizedCatalog.string("receipt.duplicate.warning", locale: locale),
                            ids.count
                        ),
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.subheadline)
                    .foregroundStyle(theme.attentionText)
                    .padding(14)
                    .background(theme.attentionSoft, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityIdentifier("receipt.duplicate.warning")
                }

                Text("receipt.confirmation.detail")
                    .font(.footnote)
                    .foregroundStyle(theme.inkSecondary)

                Button("receipt.useDetails") {
                    completed(result)
                    dismiss()
                }
                .buttonStyle(MindBudgetPrimaryButtonStyle())
                .disabled(!hasAnyAcceptedField(result.fields))
                .accessibilityIdentifier("receipt.useDetails")

                Button("receipt.scanAnother") { viewModel.retry() }
                    .buttonStyle(MindBudgetSecondaryButtonStyle())
            }
        }
        .accessibilityIdentifier("receipt.review")
    }

    private func reviewRow(_ title: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(theme.inkSecondary)
            Spacer(minLength: 16)
            Text(verbatim: value)
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.trailing)
        }
    }

    private func merchantText(_ field: ReceiptFieldResolution<String>) -> String {
        field.acceptedValue ?? localizedUnavailable(field)
    }

    private func dateText(_ field: ReceiptFieldResolution<ReceiptCalendarDate>) -> String {
        guard let value = field.acceptedValue else { return localizedUnavailable(field) }
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = value.year
        components.month = value.month
        components.day = value.day
        components.hour = 12
        guard let date = calendar.date(from: components) else {
            return LocalizedCatalog.string("receipt.field.needsReview", locale: locale)
        }
        return date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale, calendar: calendar)
        )
    }

    private func totalText(_ field: ReceiptFieldResolution<Money>) -> String {
        guard let value = field.acceptedValue else { return localizedUnavailable(field) }
        return CurrencyFormatterService().string(from: value, locale: locale)
    }

    private func localizedUnavailable<Value>(_ field: ReceiptFieldResolution<Value>) -> String {
        switch field {
        case .missing:
            LocalizedCatalog.string("receipt.field.missing", locale: locale)
        case .rejected:
            LocalizedCatalog.string("receipt.field.needsReview", locale: locale)
        case .accepted:
            preconditionFailure("Accepted fields are formatted by their typed caller")
        }
    }

    private func hasAnyAcceptedField(_ fields: ReceiptCoreFields) -> Bool {
        fields.merchantName.acceptedValue != nil
            || fields.purchaseDate.acceptedValue != nil
            || fields.total.acceptedValue != nil
    }
}
