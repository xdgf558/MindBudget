import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @State private var isChangingNotifications = false

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

                Section("settings.ai.section") {
                    Toggle("settings.ask.enabled", isOn: $settings.enableAskMindBudget)
                    Toggle("settings.ai.enhancement", isOn: $settings.enableAIEnhancement)
                    AIStatusView(userEnabled: settings.enableAIEnhancement)
                    Text("settings.ai.privacy")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("settings.integrations.section") {
                    Toggle(
                        "settings.integrations.siri",
                        isOn: $settings.enableSiriIntegration
                    )
                    Text("settings.integrations.siri.privacy")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Toggle(
                        "settings.integrations.spotlight",
                        isOn: $settings.enableSpotlightIndexing
                    )
                    if settings.enableSpotlightIndexing {
                        Toggle(
                            "settings.integrations.merchants",
                            isOn: $settings.indexMerchantNames
                        )
                        Text("settings.integrations.merchants.detail")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if session.spotlightResult == .failed {
                        Label(
                            "settings.integrations.spotlight.error",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.orange)
                    } else if session.spotlightResult == .unavailable {
                        Label(
                            "settings.integrations.spotlight.unavailable",
                            systemImage: "magnifyingglass"
                        )
                        .foregroundStyle(.secondary)
                    }
                    Text("settings.integrations.privacy")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("settings.notifications.section") {
                    Toggle(
                        "settings.notifications.enabled",
                        isOn: Binding(
                            get: { settings.enableLocalNotifications },
                            set: { enabled in
                                Task { await setNotifications(enabled) }
                            }
                        )
                    )
                    .disabled(isChangingNotifications)
                    .accessibilityIdentifier("settings.notifications.toggle")

                    Label(
                        notificationStatusKey,
                        systemImage: notificationStatusSymbol
                    )
                    .foregroundStyle(.secondary)

                    if session.notificationAuthorizationState == .denied,
                       let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        Link(destination: settingsURL) {
                            Label("settings.notifications.openSystemSettings", systemImage: "gear")
                        }
                    }

                    if settings.enableLocalNotifications {
                        Toggle(
                            "settings.notifications.quietHours",
                            isOn: $settings.quietHoursEnabled
                        )
                        if settings.quietHoursEnabled {
                            Picker(
                                "settings.notifications.quietStart",
                                selection: $settings.quietHoursStartHour
                            ) {
                                ForEach(
                                    (0..<24).filter { $0 != settings.quietHoursEndHour },
                                    id: \.self
                                ) { hour in
                                    Text(hourLabel(hour)).tag(hour)
                                }
                            }
                            Picker(
                                "settings.notifications.quietEnd",
                                selection: $settings.quietHoursEndHour
                            ) {
                                ForEach(
                                    (0..<24).filter { $0 != settings.quietHoursStartHour },
                                    id: \.self
                                ) { hour in
                                    Text(hourLabel(hour)).tag(hour)
                                }
                            }
                        }
                    }

                    if session.notificationOperationFailed {
                        Label("settings.notifications.error", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Button("common.retry") {
                            Task {
                                await session.reconcileNotifications(
                                    settings: settings,
                                    locale: locale,
                                    calendar: calendar
                                )
                            }
                        }
                    }

                    if session.notificationDataIntegrityWarning {
                        Label(
                            "settings.notifications.invalidStoredData",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.orange)
                    }

                    Text("settings.notifications.privacy")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("settings.privacy.section") {
                    Label("settings.privacy.localOnly", systemImage: "lock.shield")
                    Text("settings.privacy.message")
                        .foregroundStyle(.secondary)
                    NavigationLink {
                        ExportDataView(dataActor: session.dataActor)
                    } label: {
                        Label("export.title", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("settings.export")
                    NavigationLink {
                        PrivacySettingsView(session: session)
                    } label: {
                        Label("privacy.title", systemImage: "hand.raised")
                    }
                    .accessibilityIdentifier("settings.privacy")
                }

                Section("settings.about.section") {
                    LabeledContent("settings.version") {
                        Text(version)
                    }
                    Text("settings.tracking.none")
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.mbCanvas)
            .tint(Color.mbAccent)
            .navigationTitle("tab.settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .accessibilityIdentifier("settings.view")
            .task {
                await session.reconcileNotifications(
                    settings: settings,
                    locale: locale,
                    calendar: calendar
                )
            }
            .onChange(of: settings.quietHoursEnabled) { _, _ in
                rescheduleForQuietHoursChange()
            }
            .onChange(of: settings.quietHoursStartHour) { _, _ in
                rescheduleForQuietHoursChange()
            }
            .onChange(of: settings.quietHoursEndHour) { _, _ in
                rescheduleForQuietHoursChange()
            }
            .onChange(of: settings.enableSpotlightIndexing) { _, _ in
                reconcileSpotlight()
            }
            .onChange(of: settings.indexMerchantNames) { _, _ in
                reconcileSpotlight()
            }
        }
    }

    private var notificationStatusKey: LocalizedStringKey {
        LocalizedStringKey(
            "settings.notifications.status.\(session.notificationAuthorizationState.rawValue)"
        )
    }

    private var notificationStatusSymbol: String {
        switch session.notificationAuthorizationState {
        case .authorized, .provisional, .ephemeral: "checkmark.circle"
        case .notDetermined: "bell"
        case .denied: "bell.slash"
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

    private func hourLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2001
        components.month = 1
        components.day = 1
        components.hour = hour
        guard let date = calendar.date(from: components) else { return String(hour) }
        return date.formatted(
            Date.FormatStyle(
                date: nil,
                time: .shortened,
                locale: locale,
                calendar: calendar,
                timeZone: calendar.timeZone
            )
        )
    }

    private func setNotifications(_ enabled: Bool) async {
        isChangingNotifications = true
        defer { isChangingNotifications = false }
        if enabled {
            _ = await session.requestNotificationAuthorization(
                settings: settings,
                locale: locale,
                calendar: calendar
            )
        } else {
            await session.disableNotifications(
                settings: settings,
                locale: locale,
                calendar: calendar
            )
        }
    }

    private func rescheduleForQuietHoursChange() {
        guard settings.enableLocalNotifications else { return }
        Task {
            await session.reconcileNotifications(
                settings: settings,
                locale: locale,
                calendar: calendar
            )
        }
    }

    private func reconcileSpotlight() {
        Task {
            _ = await session.reconcileSpotlight(
                settings: settings,
                locale: locale,
                calendar: calendar
            )
        }
    }
}
