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

            Section("privacy.delete.section") {
                Text("privacy.delete.explanation")
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
