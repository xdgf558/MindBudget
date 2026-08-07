import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var session: AppSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        BudgetSettingsView()
                    } label: {
                        SettingsDestinationLabel(
                            title: "settings.budget.section",
                            systemImage: "calendar.badge.clock"
                        )
                    }
                    .accessibilityIdentifier("settings.budget")

                    NavigationLink {
                        ReminderSettingsView(session: session)
                    } label: {
                        SettingsDestinationLabel(
                            title: "settings.remindersAndNotifications.title",
                            systemImage: "bell.badge"
                        )
                    }
                    .accessibilityIdentifier("settings.reminders")

                    NavigationLink {
                        AISettingsView()
                    } label: {
                        SettingsDestinationLabel(
                            title: "settings.ai.section",
                            systemImage: "sparkles"
                        )
                    }
                    .accessibilityIdentifier("settings.ai")

                    NavigationLink {
                        IntegrationsSettingsView(session: session)
                    } label: {
                        SettingsDestinationLabel(
                            title: "settings.integrations.section",
                            systemImage: "point.3.connected.trianglepath.dotted"
                        )
                    }
                    .accessibilityIdentifier("settings.integrations")
                }

                Section {
                    NavigationLink {
                        ExportDataView(dataActor: session.dataActor)
                    } label: {
                        SettingsDestinationLabel(
                            title: "export.title",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .accessibilityIdentifier("settings.export")

                    NavigationLink {
                        PrivacySettingsView(session: session)
                    } label: {
                        SettingsDestinationLabel(
                            title: "privacy.title",
                            systemImage: "hand.raised"
                        )
                    }
                    .accessibilityIdentifier("settings.privacy")
                } header: {
                    Text("settings.privacy.section")
                } footer: {
                    Text("settings.privacy.message")
                }

                Section {
                    NavigationLink {
                        AboutSettingsView()
                    } label: {
                        SettingsDestinationLabel(
                            title: "settings.about.section",
                            systemImage: "info.circle"
                        )
                    }
                    .accessibilityIdentifier("settings.about")
                }
            }
            .settingsListPresentation()
            .navigationTitle("tab.settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .accessibilityIdentifier("settings.view")
        }
    }
}

private struct SettingsDestinationLabel: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.mbAccent)
        }
    }
}

private struct BudgetSettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale

    var body: some View {
        List {
            Section("settings.budget.section") {
                LabeledContent("settings.currency") {
                    Text(currencyLabel)
                }
                LabeledContent("settings.cycleStartDay") {
                    Text(settings.budgetCycleStartDay, format: .number)
                }
            }
        }
        .settingsListPresentation()
        .navigationTitle("settings.budget.section")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.budget.view")
    }

    private var currencyLabel: String {
        let name = locale.localizedString(forCurrencyCode: settings.currencyCode)
            ?? settings.currencyCode
        return "\(settings.currencyCode) · \(name)"
    }
}

private struct ReminderSettingsView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @State private var isChangingNotifications = false
    @State private var presentsCoolingOffRepairConfirmation = false

    var body: some View {
        List {
            Section("settings.reminders.section") {
                Toggle(
                    "settings.reminders.gentle",
                    isOn: $settings.enableGentleReminders
                )
                Picker("settings.reminders.tone", selection: $settings.reminderToneRaw) {
                    ForEach(ReminderTone.allCases, id: \.rawValue) { tone in
                        Text(verbatim: localized("settings.reminders.tone.\(tone.rawValue)"))
                            .tag(tone.rawValue)
                    }
                }
                .accessibilityIdentifier("settings.reminders.tone")
                .accessibilityValue(Text(verbatim: reminderToneLabel))
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

                Label {
                    Text(verbatim: notificationStatusText)
                } icon: {
                    Image(systemName: notificationStatusSymbol)
                }
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
                    Label(
                        "settings.notifications.error",
                        systemImage: "exclamationmark.triangle"
                    )
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
                        LocalizedCatalog.format(
                            "settings.notifications.invalidStoredData.count",
                            locale: locale,
                            session.invalidCoolingOffRecordCount
                        ),
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.orange)
                    Button("settings.notifications.repair.action", role: .destructive) {
                        presentsCoolingOffRepairConfirmation = true
                    }
                    .disabled(session.coolingOffRepairState == .repairing)
                    .accessibilityIdentifier("settings.notifications.repair")
                }

                coolingOffRepairStatus

                Text("settings.notifications.privacy")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .settingsListPresentation()
        .navigationTitle("settings.remindersAndNotifications.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.reminders.view")
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
        .confirmationDialog(
            "settings.notifications.repair.confirm.title",
            isPresented: $presentsCoolingOffRepairConfirmation,
            titleVisibility: .visible
        ) {
            Button("settings.notifications.repair.confirm.action", role: .destructive) {
                Task {
                    _ = await session.repairInvalidCoolingOffRecords(
                        settings: settings,
                        locale: locale,
                        calendar: calendar
                    )
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text(
                LocalizedCatalog.format(
                    "settings.notifications.repair.confirm.message",
                    locale: locale,
                    session.invalidCoolingOffRecordCount
                )
            )
        }
    }

    @ViewBuilder
    private var coolingOffRepairStatus: some View {
        switch session.coolingOffRepairState {
        case .repairing:
            HStack {
                ProgressView()
                Text("settings.notifications.repair.progress")
            }
            .accessibilityElement(children: .combine)
        case let .completed(count):
            Label(
                LocalizedCatalog.format(
                    "settings.notifications.repair.completed",
                    locale: locale,
                    count
                ),
                systemImage: "checkmark.circle"
            )
            .foregroundStyle(Color.mbAccent)
        case .failed:
            Label(
                "settings.notifications.repair.failed",
                systemImage: "exclamationmark.triangle"
            )
            .foregroundStyle(.orange)
        case .idle:
            EmptyView()
        }
    }

    private var reminderToneLabel: String {
        localized("settings.reminders.tone.\(settings.reminderTone.rawValue)")
    }

    private var notificationStatusText: String {
        localized(
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

    private func localized(_ key: String) -> String {
        LocalizedCatalog.string(key, locale: locale)
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
}

private struct AISettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        List {
            Section("settings.ai.section") {
                Toggle("settings.ask.enabled", isOn: $settings.enableAskMindBudget)
                Toggle("settings.ai.enhancement", isOn: $settings.enableAIEnhancement)
                AIStatusView(userEnabled: settings.enableAIEnhancement)
                Text("settings.ai.privacy")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .settingsListPresentation()
        .navigationTitle("settings.ai.section")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.ai.view")
    }
}

private struct IntegrationsSettingsView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    var body: some View {
        List {
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
        }
        .settingsListPresentation()
        .navigationTitle("settings.integrations.section")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.integrations.view")
        .task {
            await reconcileSpotlight()
        }
        .onChange(of: settings.enableSpotlightIndexing) { _, _ in
            Task { await reconcileSpotlight() }
        }
        .onChange(of: settings.indexMerchantNames) { _, _ in
            Task { await reconcileSpotlight() }
        }
    }

    private func reconcileSpotlight() async {
        _ = await session.reconcileSpotlight(
            settings: settings,
            locale: locale,
            calendar: calendar
        )
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        List {
            Section("settings.about.section") {
                LabeledContent("settings.version") {
                    Text(version)
                }
                Text("settings.tracking.none")
                    .foregroundStyle(.secondary)
            }
        }
        .settingsListPresentation()
        .navigationTitle("settings.about.section")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.about.view")
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "—"
    }
}

private extension View {
    func settingsListPresentation() -> some View {
        listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.mbCanvas)
            .tint(Color.mbAccent)
    }
}
