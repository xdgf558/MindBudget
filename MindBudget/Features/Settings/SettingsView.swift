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

                Section("settings.reminders.section") {
                    Toggle(
                        "settings.reminders.gentle",
                        isOn: $settings.enableGentleReminders
                    )
                    Picker("settings.reminders.tone", selection: $settings.reminderToneRaw) {
                        ForEach(ReminderTone.allCases, id: \.rawValue) { tone in
                            Text(LocalizedStringKey("settings.reminders.tone.\(tone.rawValue)"))
                                .tag(tone.rawValue)
                        }
                    }
                    Stepper(
                        value: Binding(
                            get: { settings.maxDailyInterruptions },
                            set: { settings.maxDailyInterruptions = $0 }
                        ),
                        in: 0...SettingsStore.maximumDailyInterruptions
                    ) {
                        LabeledContent("settings.reminders.dailyLimit") {
                            Text(settings.maxDailyInterruptions, format: .number)
                        }
                    }
                    Text("settings.reminders.localOnly")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
