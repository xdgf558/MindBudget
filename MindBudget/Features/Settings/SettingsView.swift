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
                        AppearanceSettingsView()
                    } label: {
                        SettingsDestinationLabel(
                            title: "settings.appearance.title",
                            systemImage: "paintpalette"
                        )
                    }
                    .accessibilityIdentifier("settings.appearance")

                    NavigationLink {
                        BudgetSettingsView(session: session)
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
    @Environment(\.mindBudgetTheme) private var theme

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(theme.accent)
        }
    }
}

private struct AppearanceSettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        List {
            Section {
                ForEach(AppSkin.allCases, id: \.rawValue) { skin in
                    skinButton(skin)
                }
            } header: {
                Text("settings.appearance.section")
            } footer: {
                Text("settings.appearance.included")
            }
        }
        .settingsListPresentation()
        .navigationTitle("settings.appearance.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.appearance.view")
    }

    private func skinButton(_ skin: AppSkin) -> some View {
        let palette = MindBudgetTheme(skin: skin)
        let isSelected = settings.appSkin == skin

        return Button {
            settings.appSkinRaw = skin.rawValue
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(palette.canvas)

                    Image(skin.backgroundAssetName)
                        .resizable()
                        .scaledToFill()
                        .overlay(palette.backgroundReadabilityScrim)

                    Circle()
                        .fill(palette.accentGradient)
                        .frame(width: 30, height: 30)
                    Image(systemName: skin.symbolName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 58, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(palette.hairlineStrong, lineWidth: 1)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(skin.localizedNameKey)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(palette.ink)
                    Text(skin.localizedDescriptionKey)
                        .font(.footnote)
                        .foregroundStyle(palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? Text("settings.appearance.selected") : Text(""))
        .accessibilityIdentifier("settings.appearance.skin.\(skin.rawValue)")
        .listRowBackground(palette.surface)
    }
}

private struct BudgetSettingsView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @State private var plan: BudgetPlanSummary?
    @State private var cycleStartDay = 1
    @State private var monthlyIncomeText = ""
    @State private var totalBudgetText = ""
    @State private var fixedExpensesText = ""
    @State private var savingGoalText = ""
    @State private var errorKey: LocalizedStringKey?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showsSavedConfirmation = false
    @FocusState private var focusedField: AmountField?

    var body: some View {
        List {
            if isLoading {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("settings.budget.loading")
                }
            } else if let plan {
                Section {
                    LabeledContent("settings.currency") {
                        Text(currencyLabel(for: plan.currencyCode))
                    }
                    .accessibilityIdentifier("settings.budget.currency")

                    Stepper(value: $cycleStartDay, in: 1...31) {
                        LabeledContent("settings.cycleStartDay") {
                            Text(cycleStartDay, format: .number)
                        }
                    }
                    .accessibilityIdentifier("settings.budget.cycleStartDay")
                } header: {
                    Text("budget.setup.basics")
                } footer: {
                    Text("settings.budget.basics.footer")
                }

                Section("settings.budget.currentPeriod") {
                    LabeledContent("budget.period.start") {
                        Text(plan.cycleStart, format: .dateTime.year().month().day())
                    }
                    LabeledContent("budget.period.end") {
                        Text(plan.cycleEnd, format: .dateTime.year().month().day())
                    }
                }

                Section("budget.setup.amounts") {
                    amountField(
                        "budget.monthlyIncome",
                        text: $monthlyIncomeText,
                        field: .income,
                        identifier: "settings.budget.monthlyIncome"
                    )
                    amountField(
                        "budget.totalBudget",
                        text: $totalBudgetText,
                        field: .total,
                        identifier: "settings.budget.totalBudget"
                    )
                    amountField(
                        "budget.fixedExpenses",
                        text: $fixedExpensesText,
                        field: .fixed,
                        identifier: "settings.budget.fixedExpenses"
                    )
                    amountField(
                        "budget.savingGoal",
                        text: $savingGoalText,
                        field: .saving,
                        identifier: "settings.budget.savingGoal"
                    )

                    if let allocationPreview {
                        Divider()
                        LabeledContent("settings.budget.flexiblePreview") {
                            MoneyText(
                                money: allocationPreview.flexibleBudget,
                                weight: .semibold
                            )
                        }
                        .accessibilityIdentifier("settings.budget.flexiblePreview")

                        if let warningKey = allocationWarningKey(allocationPreview.status) {
                            Label(warningKey, systemImage: "info.circle")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("settings.budget.allocationWarning")
                        }
                    }
                }

                if let errorKey {
                    Section {
                        Label(errorKey, systemImage: "info.circle")
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("settings.budget.error")
                    }
                }

                Section {
                    Button {
                        focusedField = nil
                        Task { await save(plan: plan) }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("budget.save")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSaving)
                    .buttonStyle(MindBudgetPrimaryButtonStyle())
                    .accessibilityIdentifier("settings.budget.save")

                    if showsSavedConfirmation {
                        Label("settings.budget.saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("settings.budget.saved")
                    }
                }
            } else {
                Section {
                    Label(
                        errorKey ?? "error.data.load",
                        systemImage: "exclamationmark.triangle"
                    )
                    Button("common.retry") {
                        Task { await load() }
                    }
                    .accessibilityIdentifier("settings.budget.retry")
                }
            }
        }
        .settingsListPresentation()
        .navigationTitle("settings.budget.section")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.budget.view")
        .task {
            await load()
        }
        .onChange(of: cycleStartDay) { _, _ in markDraftChanged() }
        .onChange(of: monthlyIncomeText) { _, _ in markDraftChanged() }
        .onChange(of: totalBudgetText) { _, _ in markDraftChanged() }
        .onChange(of: fixedExpensesText) { _, _ in markDraftChanged() }
        .onChange(of: savingGoalText) { _, _ in markDraftChanged() }
    }

    private func amountField(
        _ key: LocalizedStringKey,
        text: Binding<String>,
        field: AmountField,
        identifier: String
    ) -> some View {
        HStack {
            Text(key)
            Spacer()
            TextField("money.amount.placeholder", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
                .accessibilityIdentifier(identifier)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let now = Date()
            let coverage = try await session.dataActor.previewPlanCoverage(
                date: now,
                futureCycleStartDay: settings.budgetCycleStartDay,
                calendar: calendar
            )
            guard case let .covered(loadedPlan) = coverage else {
                plan = nil
                errorKey = "settings.budget.error.notCurrent"
                return
            }
            let parser = MoneyInputParser()
            plan = loadedPlan
            cycleStartDay = settings.budgetCycleStartDay
            monthlyIncomeText = parser.inputText(
                for: Money(
                    minorUnits: loadedPlan.monthlyIncomeMinorUnits,
                    currencyCode: loadedPlan.currencyCode
                ),
                locale: locale
            )
            totalBudgetText = parser.inputText(
                for: Money(
                    minorUnits: loadedPlan.totalBudgetMinorUnits,
                    currencyCode: loadedPlan.currencyCode
                ),
                locale: locale
            )
            fixedExpensesText = parser.inputText(
                for: Money(
                    minorUnits: loadedPlan.fixedExpensesMinorUnits,
                    currencyCode: loadedPlan.currencyCode
                ),
                locale: locale
            )
            savingGoalText = parser.inputText(
                for: Money(
                    minorUnits: loadedPlan.savingGoalMinorUnits,
                    currencyCode: loadedPlan.currencyCode
                ),
                locale: locale
            )
            errorKey = nil
            showsSavedConfirmation = false
        } catch {
            plan = nil
            errorKey = "error.data.load"
        }
    }

    private func save(plan: BudgetPlanSummary) async {
        isSaving = true
        defer { isSaving = false }
        do {
            let now = Date()
            let update = try BudgetPlanDraftBuilder().makeCurrentUpdate(
                planID: plan.id,
                currencyCode: plan.currencyCode,
                monthlyIncomeText: monthlyIncomeText,
                totalBudgetText: totalBudgetText,
                fixedExpensesText: fixedExpensesText,
                savingGoalText: savingGoalText,
                locale: locale,
                referenceDate: now,
                timestamp: now
            )
            let updatedPlan = try await session.dataActor.updateCurrentBudgetPlan(update)
            settings.budgetCycleStartDay = cycleStartDay
            self.plan = updatedPlan
            errorKey = nil
            showsSavedConfirmation = true
            session.dataDidChange()
        } catch let error as BudgetSetupError {
            errorKey = setupErrorKey(error)
            showsSavedConfirmation = false
        } catch let error as DataValidationError {
            switch error {
            case .invalidBudgetCycle, .modelNotFound:
                errorKey = "settings.budget.error.notCurrent"
            case .accountingCurrencyMismatch:
                errorKey = "expense.error.currencyMismatch"
            default:
                errorKey = "error.data.save"
            }
            showsSavedConfirmation = false
        } catch {
            errorKey = "error.data.save"
            showsSavedConfirmation = false
        }
    }

    private func setupErrorKey(_ error: BudgetSetupError) -> LocalizedStringKey {
        switch error {
        case .invalidIncome: "budget.error.income"
        case .invalidTotalBudget: "budget.error.total"
        case .invalidFixedExpenses: "budget.error.fixed"
        case .invalidSavingGoal: "budget.error.saving"
        case .persistence: "error.data.save"
        }
    }

    private func currencyLabel(for currencyCode: String) -> String {
        let name = locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
        return "\(currencyCode) · \(name)"
    }

    private func markDraftChanged() {
        showsSavedConfirmation = false
    }

    private var allocationPreview: BudgetAllocationSummary? {
        guard let plan else { return nil }
        let parser = MoneyInputParser()
        guard let totalBudget = try? parser.money(
            from: totalBudgetText,
            currencyCode: plan.currencyCode,
            locale: locale,
            allowsZero: true
        ), let fixedExpenses = try? parser.money(
            from: fixedExpensesText,
            currencyCode: plan.currencyCode,
            locale: locale,
            allowsZero: true
        ), let savingGoal = try? parser.money(
            from: savingGoalText,
            currencyCode: plan.currencyCode,
            locale: locale,
            allowsZero: true
        ) else {
            return nil
        }
        return try? BudgetEngine().allocation(
            totalBudget: totalBudget,
            fixedForecast: fixedExpenses,
            savingGoal: savingGoal
        )
    }

    private func allocationWarningKey(
        _ status: BudgetAllocationSummary.Status
    ) -> LocalizedStringKey? {
        switch status {
        case .available:
            nil
        case .zeroBudget:
            "settings.budget.allocation.zeroBudget"
        case .fullyAllocated:
            "settings.budget.allocation.fullyAllocated"
        case .overcommitted:
            "settings.budget.allocation.overcommitted"
        }
    }

    private enum AmountField: Hashable {
        case income
        case total
        case fixed
        case saving
    }
}

private struct ReminderSettingsView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.mindBudgetTheme) private var theme
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
            .foregroundStyle(theme.accent)
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

struct ReleaseNoteItem: Identifiable, Equatable, Sendable {
    let systemImage: String
    let localizationKey: String

    var id: String { localizationKey }
}

struct ReleaseNotesVersion: Identifiable, Equatable, Sendable {
    let version: String
    let items: [ReleaseNoteItem]

    var id: String { version }
}

struct ReleaseNotesPresentation: Equatable, Sendable {
    let current: ReleaseNotesVersion?
    let history: [ReleaseNotesVersion]
}

enum ReleaseNotesCatalog {
    /// Keep newest first. When a new installed version is inserted at the front, every earlier
    /// entry automatically moves into the collapsed history section on the About screen.
    static let versions: [ReleaseNotesVersion] = [
        ReleaseNotesVersion(
            version: "0.9.2",
            items: [
                ReleaseNoteItem(
                    systemImage: "arrow.up.arrow.down.circle.fill",
                    localizationKey: "settings.releaseNotes.incomeLedger"
                ),
                ReleaseNoteItem(
                    systemImage: "calendar.badge.clock",
                    localizationKey: "settings.releaseNotes.thirtyDayInsights"
                ),
                ReleaseNoteItem(
                    systemImage: "list.number",
                    localizationKey: "settings.releaseNotes.wishlistLimit"
                ),
            ]
        ),
        ReleaseNotesVersion(
            version: "0.9.1",
            items: [
                ReleaseNoteItem(
                    systemImage: "paintpalette.fill",
                    localizationKey: "settings.releaseNotes.skins"
                ),
                ReleaseNoteItem(
                    systemImage: "character.bubble.fill",
                    localizationKey: "settings.releaseNotes.chineseBrand"
                ),
                ReleaseNoteItem(
                    systemImage: "checkmark.seal.fill",
                    localizationKey: "settings.releaseNotes.included"
                ),
                ReleaseNoteItem(
                    systemImage: "play.circle.fill",
                    localizationKey: "settings.releaseNotes.launchAnimation"
                ),
                ReleaseNoteItem(
                    systemImage: "globe.asia.australia.fill",
                    localizationKey: "settings.releaseNotes.askLocalization"
                ),
                ReleaseNoteItem(
                    systemImage: "pencil.and.list.clipboard",
                    localizationKey: "settings.releaseNotes.budgetEditing"
                ),
                ReleaseNoteItem(
                    systemImage: "gauge.with.dots.needle.50percent",
                    localizationKey: "settings.releaseNotes.dailyRebalancing"
                ),
                ReleaseNoteItem(
                    systemImage: "faceid",
                    localizationKey: "settings.releaseNotes.faceIDLock"
                ),
            ]
        ),
        ReleaseNotesVersion(
            version: "0.9.0",
            items: [
                ReleaseNoteItem(
                    systemImage: "chart.pie.fill",
                    localizationKey: "settings.releaseNotes.0_9_0.foundation"
                ),
                ReleaseNoteItem(
                    systemImage: "lock.shield.fill",
                    localizationKey: "settings.releaseNotes.0_9_0.privacy"
                ),
                ReleaseNoteItem(
                    systemImage: "iphone.gen3",
                    localizationKey: "settings.releaseNotes.0_9_0.system"
                ),
            ]
        ),
    ]

    static func presentation(
        installedVersion: String,
        versions: [ReleaseNotesVersion] = versions
    ) -> ReleaseNotesPresentation {
        guard let currentIndex = versions.firstIndex(where: { $0.version == installedVersion }) else {
            return ReleaseNotesPresentation(current: nil, history: [])
        }
        return ReleaseNotesPresentation(
            current: versions[currentIndex],
            history: Array(versions.dropFirst(currentIndex + 1))
        )
    }
}

private struct AboutSettingsView: View {
    @Environment(\.locale) private var locale
    @Environment(\.mindBudgetTheme) private var theme
    @State private var showsReleaseHistory = false

    var body: some View {
        List {
            Section("settings.about.section") {
                LabeledContent("settings.version") {
                    Text(version)
                        .accessibilityIdentifier("settings.version.value")
                }
                Text("settings.tracking.none")
                    .foregroundStyle(.secondary)
            }

            if let currentRelease = releaseNotes.current {
                Section {
                    releaseNotesList(currentRelease)
                        .accessibilityIdentifier("settings.releaseNotes")
                } header: {
                    Text(
                        LocalizedCatalog.format(
                            "settings.releaseNotes.version",
                            locale: locale,
                            currentRelease.version
                        )
                    )
                }
            } else {
                Section("settings.releaseNotes.title") {
                    Text("settings.releaseNotes.unavailable")
                        .foregroundStyle(.secondary)
                }
            }

            if !releaseNotes.history.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $showsReleaseHistory) {
                        ForEach(releaseNotes.history) { release in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(release.version)
                                    .font(.headline)
                                    .accessibilityIdentifier(
                                        "settings.releaseNotes.history.\(release.version)"
                                    )
                                ForEach(release.items) { releaseNote($0) }
                            }
                            .padding(.vertical, 8)
                            .accessibilityElement(children: .contain)
                        }
                    } label: {
                        Label("settings.releaseNotes.history", systemImage: "clock.arrow.circlepath")
                    }
                    .tint(theme.accent)
                    .accessibilityIdentifier("settings.releaseNotes.history")
                } footer: {
                    Text("settings.releaseNotes.history.footer")
                }
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

    private var releaseNotes: ReleaseNotesPresentation {
        ReleaseNotesCatalog.presentation(installedVersion: version)
    }

    private func releaseNotesList(_ release: ReleaseNotesVersion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(release.items) { releaseNote($0) }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }

    private func releaseNote(_ item: ReleaseNoteItem) -> some View {
        Label {
            Text(LocalizedStringKey(item.localizationKey))
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundStyle(theme.accent)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    func settingsListPresentation() -> some View {
        listStyle(.insetGrouped)
            .mindBudgetScreenBackground()
    }
}
