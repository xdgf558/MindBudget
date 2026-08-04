import SwiftUI

struct PrivacySettingsView: View {
    @ObservedObject var session: AppSession

    @State private var presentsFirstConfirmation = false
    @State private var presentsFinalConfirmation = false

    var body: some View {
        List {
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
}

private struct PrivacyDeletionConfirmationView: View {
    @ObservedObject var session: AppSession

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
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
        Bundle.main.localizedString(
            forKey: "privacy.delete.confirmationWord",
            value: nil,
            table: nil
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
