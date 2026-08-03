import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            List {
                Section("settings.budget.section") {
                    LabeledContent("settings.currency") {
                        Text(currencyLabel)
                    }
                    LabeledContent("settings.cycleStartDay") {
                        Text(settings.budgetCycleStartDay, format: .number)
                    }
                }

                Section("settings.privacy.section") {
                    Label("settings.privacy.localOnly", systemImage: "lock.shield")
                    Text("settings.privacy.message")
                        .foregroundStyle(.secondary)
                }

                Section("settings.about.section") {
                    LabeledContent("settings.version") {
                        Text(version)
                    }
                    Text("settings.tracking.none")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("tab.settings")
            .accessibilityIdentifier("settings.view")
        }
    }

    private var currencyLabel: String {
        let name = locale.localizedString(forCurrencyCode: settings.currencyCode)
            ?? settings.currencyCode
        return "\(settings.currencyCode) · \(name)"
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "—"
    }
}
