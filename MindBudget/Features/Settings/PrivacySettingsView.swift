import SwiftUI

struct PrivacySettingsView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale

    @State private var presentsFirstConfirmation = false
    @State private var presentsFinalConfirmation = false
    @State private var faceIDAvailability: FaceIDAvailability = .unavailable
    @State private var isChangingAppLock = false

    var body: some View {
        List {
            Section {
                Toggle(
                    "privacy.appLock.toggle",
                    isOn: Binding(
                        get: { settings.requireFaceID },
                        set: { enabled in
                            Task { await changeAppLockProtection(enabled: enabled) }
                        }
                    )
                )
                .disabled(
                    isChangingAppLock
                        || (!settings.requireFaceID && faceIDAvailability != .available)
                )
                .accessibilityIdentifier("settings.privacy.appLock")

                if isChangingAppLock {
                    HStack {
                        ProgressView()
                        Text("privacy.appLock.authenticating")
                    }
                    .accessibilityElement(children: .combine)
                }

                if let errorKey = appLockErrorKey {
                    Label(errorKey, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("settings.privacy.appLock.error")
                }
            } header: {
                Text("privacy.appLock.section")
            } footer: {
                if faceIDAvailability == .available || settings.requireFaceID {
                    Text("privacy.appLock.footer")
                } else {
                    Text("privacy.appLock.unavailable")
                }
            }

            Section("privacy.summary.section") {
                Label("privacy.summary.deviceOnly", systemImage: "iphone")
                Label("privacy.summary.noTracking", systemImage: "hand.raised")
                Label("privacy.summary.noAccount", systemImage: "person.crop.circle.badge.xmark")
                Text("privacy.summary.detail")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink {
                    TelemetrySettingsView(session: session)
                } label: {
                    Label("telemetry.settings.title", systemImage: "chart.bar.xaxis")
                }
                .accessibilityIdentifier("settings.privacy.telemetry")
            } header: {
                Text("telemetry.settings.section")
            } footer: {
                Text("telemetry.settings.summary")
            }

            Section("privacy.delete.section") {
                Text("privacy.delete.explanation")
                    .foregroundStyle(.secondary)
                Text("privacy.delete.cloudBoundary")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("privacy.delete.start", role: .destructive) {
                    presentsFirstConfirmation = true
                }
                .accessibilityIdentifier("settings.privacy.delete")
            }
        }
        .navigationTitle("privacy.title")
        .task {
            faceIDAvailability = session.faceIDAvailability()
        }
        .confirmationDialog(
            "privacy.delete.first.title",
            isPresented: $presentsFirstConfirmation,
            titleVisibility: .visible
        ) {
            Button("privacy.delete.first.continue", role: .destructive) {
                session.clearPrivacyDeletionFailure()
                presentsFinalConfirmation = true
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("privacy.delete.first.message")
        }
        .sheet(isPresented: $presentsFinalConfirmation) {
            NavigationStack {
                PrivacyDeletionConfirmationView(session: session)
            }
        }
    }

    private var appLockErrorKey: LocalizedStringKey? {
        switch session.appLockOperationError {
        case .faceIDUnavailable:
            "privacy.appLock.unavailable"
        case .authenticationFailed:
            "privacy.appLock.authenticationFailed"
        case nil:
            nil
        }
    }

    private func changeAppLockProtection(enabled: Bool) async {
        isChangingAppLock = true
        defer { isChangingAppLock = false }
        _ = await session.setAppLockProtection(
            enabled: enabled,
            settings: settings,
            localizedReason: LocalizedCatalog.string(
                enabled
                    ? "privacy.appLock.enable.reason"
                    : "privacy.appLock.disable.reason",
                locale: locale
            )
        )
        faceIDAvailability = session.faceIDAvailability()
    }
}

private struct TelemetrySettingsView: View {
    @ObservedObject var session: AppSession
    @Environment(\.mindBudgetTheme) private var theme

    @State private var presentsEnableConfirmation = false
    @State private var presentsDeleteConfirmation = false
    @State private var isWorking = false
    @State private var operationFailed = false

    var body: some View {
        List {
            Section {
                Toggle(
                    "telemetry.settings.toggle",
                    isOn: Binding(
                        get: { session.telemetrySnapshot.collectionEnabled },
                        set: { enabled in
                            if enabled {
                                presentsEnableConfirmation = true
                            } else {
                                Task { await setCollectionEnabled(false) }
                            }
                        }
                    )
                )
                .disabled(isWorking || session.telemetrySnapshot.availability != .available)
                .accessibilityIdentifier("settings.telemetry.toggle")
            } header: {
                Text("telemetry.settings.section")
            } footer: {
                Text("telemetry.settings.defaultOff")
            }

            Section("telemetry.settings.collects.title") {
                Text("telemetry.settings.collects.detail")
                Text("telemetry.settings.neverCollects")
                    .foregroundStyle(.secondary)
            }

            Section("telemetry.settings.identity.title") {
                Text("telemetry.settings.identity.detail")
                Text("telemetry.settings.retention.detail")
                    .foregroundStyle(.secondary)
            }

            Section("telemetry.settings.status.title") {
                LabeledContent(
                    "telemetry.settings.status.queue",
                    value: String(session.telemetrySnapshot.queuedEventCount)
                )
                LabeledContent(
                    "telemetry.settings.status.identities",
                    value: String(session.telemetrySnapshot.retainedIdentityCount)
                )

                if session.telemetrySnapshot.availability == .corruptPersistence {
                    Label("telemetry.settings.corrupt", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(theme.attentionText)
                }

                if session.telemetrySnapshot.availability == .unavailable {
                    Label("telemetry.settings.unavailable", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(theme.attentionText)
                }

                if session.telemetrySnapshot.terminalTransportFailure != nil {
                    Label("telemetry.settings.endpointFailure", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(theme.attentionText)
                    if session.telemetrySnapshot.collectionEnabled {
                        Button("telemetry.settings.retry") {
                            Task {
                                isWorking = true
                                await session.retryTelemetryTransport()
                                isWorking = false
                            }
                        }
                        .disabled(isWorking)
                    }
                }

                if session.telemetrySnapshot.retainedIdentityCount
                    >= TelemetryPolicy.maximumIdentityGenerations {
                    Text("telemetry.settings.identityCapacity")
                        .font(.footnote)
                        .foregroundStyle(theme.attentionText)
                }
            }

            Section {
                Button("telemetry.settings.delete", role: .destructive) {
                    presentsDeleteConfirmation = true
                }
                .disabled(isWorking)
                .accessibilityIdentifier("settings.telemetry.delete")

                if operationFailed {
                    Text("telemetry.settings.operationFailed")
                        .font(.footnote)
                        .foregroundStyle(theme.attentionText)
                }
            } footer: {
                Text("telemetry.settings.delete.detail")
            }
        }
        .navigationTitle("telemetry.settings.title")
        .confirmationDialog(
            "telemetry.settings.enable.title",
            isPresented: $presentsEnableConfirmation,
            titleVisibility: .visible
        ) {
            Button("telemetry.settings.enable.confirm") {
                Task { await setCollectionEnabled(true) }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("telemetry.settings.enable.message")
        }
        .confirmationDialog(
            "telemetry.settings.delete.title",
            isPresented: $presentsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("telemetry.settings.delete.confirm", role: .destructive) {
                Task { await deleteTelemetry() }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("telemetry.settings.delete.message")
        }
    }

    private func setCollectionEnabled(_ enabled: Bool) async {
        isWorking = true
        operationFailed = !(await session.setTelemetryCollectionEnabled(enabled))
        isWorking = false
    }

    private func deleteTelemetry() async {
        isWorking = true
        let result = await session.deleteTelemetryData()
        switch result {
        case .deletedLocally, .deletedLocallyWithoutRemoteProofs, .deletedRemotely:
            operationFailed = false
        case .failed, .terminalFailure, .unavailable:
            operationFailed = true
        }
        isWorking = false
    }
}

private struct PrivacyDeletionConfirmationView: View {
    @ObservedObject var session: AppSession

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var confirmationText = ""

    var body: some View {
        Form {
            Section {
                Text("privacy.delete.final.message")
                    .foregroundStyle(.secondary)
                TextField("privacy.delete.final.placeholder", text: $confirmationText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("settings.privacy.confirmation")
            } header: {
                Text("privacy.delete.final.title")
            } footer: {
                Text("privacy.delete.final.hint")
            }

            if case let .inProgress(stage) = session.privacyDeletionState {
                Section("privacy.delete.progress.section") {
                    HStack {
                        ProgressView()
                        Text(stage.localizedKey)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            if case let .failed(stage) = session.privacyDeletionState {
                Section {
                    Label(stage.failureKey, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("privacy.delete.failure.incomplete")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("common.retry") {
                        Task { await deleteAllData() }
                    }
                }
            }

            if session.privacyDeletionState == .completedWithPendingTelemetryDeletion {
                Section {
                    Label(
                        "privacy.delete.telemetryPending.title",
                        systemImage: "checkmark.circle"
                    )
                    Text("privacy.delete.telemetryPending.detail")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("privacy.delete.final.action", role: .destructive) {
                    Task { await deleteAllData() }
                }
                .disabled(!confirmationMatches || isDeleting)
                .accessibilityIdentifier("settings.privacy.delete.final")
            }
        }
        .navigationTitle("privacy.delete.final.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
                    .disabled(isDeleting)
            }
        }
        .interactiveDismissDisabled(isDeleting)
    }

    private var confirmationMatches: Bool {
        confirmationText.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare(confirmationWord) == .orderedSame
    }

    private var confirmationWord: String {
        LocalizedCatalog.string(
            "privacy.delete.confirmationWord",
            locale: locale
        )
    }

    private var isDeleting: Bool {
        if case .inProgress = session.privacyDeletionState { return true }
        return false
    }

    private func deleteAllData() async {
        _ = await session.deleteAllData(settings: settings)
    }
}

private extension PrivacyDeletionStage {
    var localizedKey: LocalizedStringKey {
        LocalizedStringKey("privacy.delete.stage.\(rawValue)")
    }

    var failureKey: LocalizedStringKey {
        LocalizedStringKey("privacy.delete.failure.\(rawValue)")
    }
}
